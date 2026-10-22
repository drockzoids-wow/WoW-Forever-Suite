local _, Suite = ...
local Known = { records = {}, hooked = {} }
Suite.MerchantKnown = Known
table.insert(Suite.modules, Known)

local function Read(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Kind(value, kind) return Suite.IsReadable(value) and type(value) == kind end
local function Integer(value, low, high)
    return Kind(value, "number") and value == value and value >= low and value <= high and value == math.floor(value)
end
local function Accessible(frame)
    return Kind(frame, "table") or Kind(frame, "userdata")
end
local function Usable(frame)
    if not Accessible(frame) then return false end
    if frame.IsForbidden and Read(frame.IsForbidden, frame) ~= false then return false end
    return true
end
function Known:Enabled() return Suite.db and Suite.IsReadable(Suite.db.vendorKnownItems) and Suite.db.vendorKnownItems == true end
function Known:Open()
    return Usable(MerchantFrame) and Read(MerchantFrame.IsShown, MerchantFrame) == true
end
local function Normalize(text)
    if not Kind(text, "string") then return end
    return text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):match("^%s*(.-)%s*$")
end
function Known:KnownText(text)
    local value = Normalize(text)
    if not value or value == "" then return false end
    for _, label in ipairs({ "ITEM_SPELL_KNOWN", "ERR_COSMETIC_KNOWN" }) do
        local expected = Normalize(_G[label])
        if expected and expected ~= "" and value == expected then return true end
    end
    return false
end
function Known:TooltipKnown(data)
    if not Kind(data, "table") or not Kind(data.lines, "table") then return false end
    for index, line in ipairs(data.lines) do
        if index > 100 then break end
        if Kind(line, "table") and (self:KnownText(line.leftText) or self:KnownText(line.rightText)) then return true end
    end
    return false
end
function Known:CollectedPet(index)
    local id = Read(GetMerchantItemID, index)
    if not Integer(id, 1, 2147483647) or not C_PetJournal or type(C_PetJournal.GetPetInfoByItemID) ~= "function" then return false end
    -- Legacy pet-journal query returns speciesID in position 13. Only plain
    -- positive identifiers/counts may establish ownership; no journal filters change.
    local ok, species = pcall(function() return select(13, C_PetJournal.GetPetInfoByItemID(id)) end)
    if not ok or not Integer(species, 1, 2147483647) then return false end
    local count = Read(C_PetJournal.GetNumCollectedInfo, species)
    return Integer(count, 1, 2147483647)
end
function Known:IsKnown(index, link)
    if InCombatLockdown() then return false end
    local api = C_TooltipInfo or {}
    if self:TooltipKnown(Read(api.GetMerchantItem, index)) then return true end
    if self:TooltipKnown(Read(api.GetHyperlink, link)) then return true end
    return self:CollectedPet(index)
end
function Known:Hide()
    for _, record in pairs(self.records) do
        local frame = record.frame
        if Usable(frame) then
            if not InCombatLockdown() or Read(frame.IsProtected, frame) == false then frame:Hide()
            else Suite.AfterCombat("merchantKnownRefresh", function() self:Refresh() end) end
        end
    end
end
function Known:Cancel()
    if self.work then self.work:Cancel(); self.work = nil end
    Suite.pending.merchantKnownRefresh = nil
end
function Known:Record(button, row)
    if self.records[button] and self.records[button].row == row then return self.records[button] end
    if InCombatLockdown() then return end
    local frame = CreateFrame("Frame", nil, row)
    frame:Hide(); frame:SetAllPoints(row); frame:EnableMouse(false)
    local level = Read(row.GetFrameLevel, row)
    if Integer(level, 0, 10000) then frame:SetFrameLevel(level + 1) end
    local wash = frame:CreateTexture(nil, "BACKGROUND")
    wash:SetAllPoints(frame); wash:SetColorTexture(0.15, 0.85, 0.2, 0.14)
    local icon = frame:CreateTexture(nil, "OVERLAY", nil, 6)
    icon:SetAllPoints(button); icon:SetColorTexture(0.15, 0.85, 0.2, 0.30)
    local check = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    check:SetSize(18, 18); check:SetPoint("TOPRIGHT", button, "TOPRIGHT", 2, 2)
    check:SetVertexColor(0.3, 1, 0.3, 1)
    local record = { frame = frame, row = row, wash = wash, icon = icon, check = check }
    self.records[button] = record
    return record
end
function Known:Refresh()
    self:Hide()
    if not self:Enabled() or not self:Open() then return end
    if InCombatLockdown() then
        Suite.AfterCombat("merchantKnownRefresh", function() self:Refresh() end); return
    end
    if not Suite.IsReadable(MerchantFrame.selectedTab) or MerchantFrame.selectedTab ~= 1 then return end
    local page, perPage = MerchantFrame.page, MERCHANT_ITEMS_PER_PAGE
    local count = Read(GetMerchantNumItems)
    if not Integer(page, 1, 100000) or not Integer(perPage, 1, 40) or not Integer(count, 0, 1000000) then return end
    for slot = 1, perPage do
        local index = (page - 1) * perPage + slot
        local row, button = _G["MerchantItem" .. slot], _G["MerchantItem" .. slot .. "ItemButton"]
        if index <= count and Usable(row) and Usable(button) and Read(button.IsShown, button) == true
            and Read(button.GetParent, button) == row and Read(button.GetID, button) == index then
            local link = Read(GetMerchantItemLink, index)
            if Kind(link, "string") and link ~= "" and self:IsKnown(index, link) then
                local record = self:Record(button, row)
                if record then record.frame:Show() end
            end
        end
    end
end
function Known:Queue()
    if not self:Enabled() then return end
    if InCombatLockdown() then
        self:Hide()
        Suite.AfterCombat("merchantKnownRefresh", function() self:Refresh() end); return
    end
    if not self:Open() or self.work then return end
    if not C_Timer or type(C_Timer.NewTimer) ~= "function" then return end
    local work
    work = C_Timer.NewTimer(0.05, function()
        if self.work ~= work then return end
        self.work = nil; self:Refresh()
    end)
    self.work = work
end
function Known:InstallHooks()
    if type(hooksecurefunc) ~= "function" then return end
    for _, name in ipairs({ "MerchantFrame_UpdateMerchantInfo", "MerchantFrame_UpdateBuybackInfo" }) do
        if not self.hooked[name] and type(_G[name]) == "function" then
            hooksecurefunc(name, function() self:Queue() end)
            self.hooked[name] = true
        end
    end
end
function Known:Apply()
    if not self:Enabled() then
        self:Cancel(); self:Hide(); Suite.pending.merchantKnownApply = nil
        if self.events then self.events:UnregisterAllEvents() end
        return
    end
    Suite.AfterCombat("merchantKnownApply", function()
        if not self:Enabled() then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event)
                if not self:Enabled() then return end
                if event == "MERCHANT_CLOSED" or event == "PLAYER_ENTERING_WORLD" then self:Cancel(); self:Hide()
                elseif event == "PLAYER_REGEN_DISABLED" then self:Cancel(); self:Hide()
                else
                    if event == "ADDON_LOADED" then self:InstallHooks() end
                    self:Queue()
                end
            end)
        end
        self.events:UnregisterAllEvents()
        for _, event in ipairs({ "ADDON_LOADED", "MERCHANT_SHOW", "MERCHANT_UPDATE", "MERCHANT_CLOSED", "GET_ITEM_INFO_RECEIVED",
            "SPELLS_CHANGED", "PET_JOURNAL_LIST_UPDATE", "TOOLTIP_DATA_UPDATE", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD" }) do
            pcall(self.events.RegisterEvent, self.events, event)
        end
        self:InstallHooks(); self:Queue()
    end)
end
