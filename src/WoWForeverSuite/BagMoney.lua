local _, Suite = ...
local Money = { hooked = {} }
Suite.BagMoney = Money
table.insert(Suite.modules, Money)

local function Table(value) return Suite.IsReadable(value) and type(value) == "table" end
local function Text(value)
    return Suite.IsReadable(value) and type(value) == "string" and #value > 0 and #value <= 128
        and not value:find("[%c|]")
end
local function Integer(value, maximum)
    return Suite.IsReadable(value) and type(value) == "number" and value >= 0
        and value <= maximum and value == math.floor(value)
end
local function Call(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Accessible(frame)
    return Suite.IsReadable(frame) and frame and Call(frame.IsForbidden, frame) == false
        and Call(frame.IsProtected, frame) == false
end
function Money:Enabled()
    return Suite.db and Suite.IsReadable(Suite.db.bagMoney) and Suite.db.bagMoney == true
end
function Money:Capture()
    if not self:Enabled() then return end
    if InCombatLockdown() then
        Suite.AfterCombat("bagMoneyCapture", function() self:Capture() end); return
    end
    local amount, at = Call(GetMoney), Call(GetServerTime)
    if not Integer(amount, 1000000000000) or not Integer(at, 10000000000) or at == 0 then return end
    local character = Suite.Inventory:Character()
    if not character then return end
    local profile = Table(character.profile) and character.profile or {}
    character.profile = profile
    profile.money, profile.moneyAt = amount, at
    local ruleset = Suite.Mail:CurrentRuleset()
    if Text(ruleset) then profile.ruleset = ruleset end
end
function Money:Summary()
    local region, current = Call(GetCurrentRegion), Call(UnitGUID, "player")
    local ruleset = Suite.Mail:CurrentRuleset()
    if not Integer(region, 1000000) or region == 0 or not Text(current) or not Text(ruleset) then return end
    local rows, total, missing = {}, 0, 0
    for guid, character in pairs(Suite.Inventory:Database().characters) do
        if Text(guid) and Table(character) and Text(character.name)
            and Integer(character.region, 1000000) and character.region == region then
            local profile = Table(character.profile) and character.profile or {}
            local recorded = Suite.Mail:RecordedRuleset({ realm = character.realm, ruleset = profile.ruleset })
            if recorded == ruleset then
                local amount
                if guid == current then amount = Call(GetMoney) else amount = profile.money end
                if Integer(amount, 1000000000000) then
                    rows[#rows + 1] = { guid = guid, name = Text(character.fullName) and character.fullName or character.name,
                        money = amount, current = guid == current }
                    total = total + amount
                else missing = missing + 1 end
            end
        end
    end
    table.sort(rows, function(a, b)
        if a.current ~= b.current then return a.current end
        if a.name ~= b.name then return a.name < b.name end
        return a.guid < b.guid
    end)
    return { rows = rows, total = total, missing = missing, ruleset = ruleset }
end
function Money:Format(amount)
    local value = Call(GetCoinTextureString, amount)
    if type(value) == "string" then return value end
    return Suite.CharacterDashboard:Money(amount)
end
function Money:Hide()
    if self.owner and Accessible(GameTooltip) and Call(GameTooltip.GetOwner, GameTooltip) == self.owner then
        GameTooltip:Hide()
    end
    self.owner = nil
end
function Money:Tooltip(owner)
    if not self:Enabled() or InCombatLockdown() or not Accessible(owner) or not Accessible(GameTooltip) then return end
    self:Capture()
    local summary = self:Summary()
    if not summary then return end
    self.owner = owner
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:AddLine("Account money · " .. summary.ruleset, 0.41, 0.84, 0.75)
    for _, row in ipairs(summary.rows) do
        GameTooltip:AddDoubleLine(row.name .. (row.current and " (You)" or ""), self:Format(row.money), 0.88, 0.91, 0.93, 1, 1, 1)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("Recorded total", self:Format(summary.total), 0.41, 0.84, 0.75, 1, 1, 1)
    if summary.missing > 0 then GameTooltip:AddLine(summary.missing .. " character(s) without a recorded balance.", 0.55, 0.65, 0.7) end
    GameTooltip:AddLine("Log into each alt with this option enabled to update its balance.", 0.55, 0.65, 0.7)
    GameTooltip:Show()
end
function Money:Attach(frame)
    if InCombatLockdown() or not Accessible(frame) or self.hooked[frame] or not frame.HookScript then return end
    self.hooked[frame] = true
    frame:HookScript("OnEnter", function(owner) self:Tooltip(owner) end)
    frame:HookScript("OnLeave", function() self:Hide() end)
    frame:HookScript("OnHide", function() self:Hide() end)
end
function Money:Discover()
    if not self:Enabled() or InCombatLockdown() then return end
    local function AttachBag(bag)
        if not Accessible(bag) then return end
        local frame = bag.MoneyFrame
        if not Accessible(frame) then return end
        self:Attach(frame)
        for _, key in ipairs({ "GoldButton", "SilverButton", "CopperButton" }) do self:Attach(frame[key]) end
    end
    AttachBag(ContainerFrameCombinedBags)
    -- The native container pool includes anonymous frames; avoid assuming numbered globals.
    if Accessible(ContainerFrameContainer) and Table(ContainerFrameContainer.ContainerFrames) then
        for _, bag in ipairs(ContainerFrameContainer.ContainerFrames) do AttachBag(bag) end
    end
    AttachBag(ContainerFrame1)
end
function Money:OnEvent(event)
    if not self:Enabled() then return end
    if event == "PLAYER_REGEN_DISABLED" then self:Hide(); return end
    if event ~= "ADDON_LOADED" then self:Capture() end
    if event ~= "PLAYER_MONEY" and event ~= "PLAYER_LOGOUT" then
        Suite.AfterCombat("bagMoneyDiscover", function() self:Discover() end)
    end
    if self.owner and event == "PLAYER_MONEY" then self:Tooltip(self.owner) end
end
function Money:Apply()
    self:Hide()
    Suite.pending.bagMoneyCapture, Suite.pending.bagMoneyDiscover = nil, nil
    if self.events then self.events:UnregisterAllEvents() end
    Suite.AfterCombat("bagMoneyApply", function()
        if not self:Enabled() then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event) self:OnEvent(event) end)
        end
        for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_MONEY", "PLAYER_LOGOUT", "PLAYER_REGEN_DISABLED" }) do
            self.events:RegisterEvent(event)
        end
        self:Capture(); self:Discover()
    end)
end
