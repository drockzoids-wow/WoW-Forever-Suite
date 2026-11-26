local _, Suite = ...
local Deposit = {}
Suite.BankDeposit = Deposit
table.insert(Suite.modules, Deposit)

local function Read(fn, ...)
    if not Suite.IsReadable(fn) or type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Int(value, low, high)
    return Suite.IsReadable(value) and type(value) == "number" and value >= low
        and value <= high and value == math.floor(value)
end
local function Safe(frame)
    return Suite.IsReadable(frame) and (type(frame) == "table" or type(frame) == "userdata")
        and Read(frame.IsForbidden, frame) == false
end
function Deposit:Enabled()
    return Suite.db and Suite.IsReadable(Suite.db.bankDepositReagents) and Suite.db.bankDepositReagents == true
end
function Deposit:Ready()
    if not self:Enabled() or not self.bankOpen or InCombatLockdown() or not Safe(BankFrame)
        or not Suite.LiveBankReady() or Read(BankFrame.IsShown, BankFrame) ~= true then return false end
    local kind = Enum and Enum.BankType and Enum.BankType.Character
    if not Int(kind, 0, 10) or Read(BankFrame.GetActiveBankType, BankFrame) ~= kind
        or Read(C_Bank and C_Bank.CanViewBank, kind) ~= true then return false end
    if Read(CursorHasItem) ~= false then return false end
    local ok, cursor = false, nil
    if type(GetCursorInfo) == "function" then ok, cursor = pcall(GetCursorInfo) end
    if not ok or not Suite.IsReadable(cursor) or cursor ~= nil then return false end
    local queried, targeting = false, nil
    if type(SpellIsTargeting) == "function" then queried, targeting = pcall(SpellIsTargeting) end
    if not queried or not Suite.IsReadable(targeting) or (targeting ~= nil and targeting ~= false) then return false end
    return C_Container and type(C_Container.UseContainerItem) == "function"
        and type(C_Container.GetContainerItemInfo) == "function"
        and C_Item and type(C_Item.GetItemInfo) == "function"
        and C_Timer and type(C_Timer.NewTimer) == "function"
end
function Deposit:Cancel()
    if self.timer then self.timer:Cancel(); self.timer = nil end
    -- Cancelling a batch does not cancel the sent native request.
    if self.deadline and not self.transfer then self.deadline:Cancel(); self.deadline = nil end
    self.job = nil
    if self.button and not InCombatLockdown() then self.button:SetEnabled(true); self.button:SetText("Deposit Reagents") end
end
local function Reagent(id)
    if not C_Item or type(C_Item.GetItemInfo) ~= "function" then return end
    local ok, name, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, reagent = pcall(C_Item.GetItemInfo, id)
    if ok and Suite.IsReadable(name) and type(name) == "string" and name ~= ""
        and Suite.IsReadable(reagent) and type(reagent) == "boolean" then return reagent end
end
function Deposit:Current(entry)
    local item = Read(C_Container and C_Container.GetContainerItemInfo, entry.bag, entry.slot)
    return type(item) == "table" and Suite.IsReadable(item.itemID) and item.itemID == entry.id
        and Suite.IsReadable(item.hyperlink) and item.hyperlink == entry.link
        and Suite.IsReadable(item.stackCount) and item.stackCount == entry.count
        and Suite.IsReadable(item.isLocked) and item.isLocked == false
end
function Deposit:Queue()
    if not self.job or self.timer then return end
    self.timer = C_Timer.NewTimer(0.2, function() self.timer = nil; self:Step() end)
end
function Deposit:TransferSettled()
    local transfer = self.transfer
    if not transfer then return true end
    local counts = Suite.ItemRules:Counts()
    if not counts or (counts[transfer.id] or 0) >= transfer.before then return false end
    self.transfer = nil
    self.deadline:Cancel(); self.deadline = nil
    return true
end
function Deposit:Step()
    if not self.job then return end
    if not self:Ready() then self:Cancel(); return end
    local job = self.job
    if job.loading then
        local pending = false
        for _, entry in ipairs(job.entries) do
            if Reagent(entry.id) == nil then pending = true end
        end
        if pending then return end
        job.loading = nil
        if self.deadline then self.deadline:Cancel(); self.deadline = nil end
    end
    if not self:TransferSettled() then return end
    while job.index <= #job.entries do
        local entry = job.entries[job.index]; job.index = job.index + 1
        local reagent = Reagent(entry.id)
        if reagent == nil then job.unavailable = true end
        if reagent == true and self:Current(entry) then
            if not self:Ready() then self:Cancel(); return end
            local allowed, reason = Suite.ItemRules:CanRemove(entry.id, "deposit", entry.count)
            if not allowed then
                if reason == "reserve" then job.reserved = true else job.unavailable = true end
            else
                local counts = Suite.ItemRules:Counts()
                local before = counts and counts[entry.id]
                if not Int(before, entry.count, 1000000000) then
                    self:Cancel(); Suite.Print("Reagent deposit stopped: carried bag data is unavailable."); return
                end
                -- A request is not a transfer. Wait for the carried total to fall before
                -- authorizing another stack, including when the bank only took part of it.
                self.transfer = { id = entry.id, before = before }
                self.deadline = C_Timer.NewTimer(4, function()
                    self.transfer, self.deadline = nil, nil
                    if self.job == job then
                        self:Cancel()
                        Suite.Print("Reagent deposit stopped: the last transfer was unconfirmed. Check bags and bank space before trying again.")
                    end
                end)
                -- Same explicit personal-bank destination as the native bag right-click.
                -- Native storage rules handle partial stacks, specialty bags and full banks.
                local ok = pcall(C_Container.UseContainerItem, entry.bag, entry.slot, nil, Enum.BankType.Character, false)
                if not ok then
                    self.transfer = nil
                    self:Cancel(); Suite.Print("Reagent deposit stopped: the game rejected a transfer."); return
                end
                self:Queue(); return
            end
        end
    end
    local unavailable = job.unavailable
    local reserved = job.reserved
    self:Cancel()
    if unavailable then Suite.Print("Some item data was unavailable. Click Deposit Reagents again after it loads.") end
    if reserved then Suite.Print("Reserved stacks kept in your bags. Split off excess manually, then deposit again.") end
end
function Deposit:Start()
    if self.job or not self:Ready() then return end
    if not self:TransferSettled() then
        Suite.Print("The previous reagent transfer is still unconfirmed. Wait for your bags to update before trying again.")
        return
    end
    local last = NUM_TOTAL_EQUIPPED_BAG_SLOTS
    if not Int(last, 0, 32) then return end
    local entries, pending = {}, {}
    for bag = 0, last do
        local size = Read(C_Container.GetContainerNumSlots, bag)
        if not Int(size, bag == 0 and 1 or 0, 200) then return end
        for slot = 1, size do
            local item = Read(C_Container.GetContainerItemInfo, bag, slot)
            if type(item) == "table" and Int(item.itemID, 1, 2147483647)
                and Suite.IsReadable(item.hyperlink) and type(item.hyperlink) == "string"
                and #item.hyperlink <= 4096 and Int(item.stackCount, 1, 1000000000)
                and Suite.IsReadable(item.isLocked) and item.isLocked == false then
                local reagent = Reagent(item.itemID)
                if reagent ~= false then
                    entries[#entries + 1] = { bag = bag, slot = slot, id = item.itemID, link = item.hyperlink, count = item.stackCount }
                    if reagent == nil then pending[item.itemID] = true end
                end
            end
        end
    end
    if not self:Ready() then return end
    self.job = { entries = entries, index = 1, loading = next(pending) ~= nil }
    if self.button then self.button:SetEnabled(false); self.button:SetText("Depositing...") end
    if self.job.loading then
        self.deadline = C_Timer.NewTimer(5, function()
            self.deadline = nil
            if self.job then self.job.loading = nil; self:Step() end
        end)
        for id in pairs(pending) do Read(C_Item.RequestLoadItemDataByID, id) end
    end
    self:Step()
end
function Deposit:Discover()
    if not self:Enabled() or InCombatLockdown() or not Safe(BankFrame) or not Suite.LiveBankReady() then return end
    local kind = Enum and Enum.BankType and Enum.BankType.Character
    if not Int(kind, 0, 10) then return end
    local panel = BankFrame.BankPanel
    local purchase = Safe(panel) and panel.PurchaseButton
    if not Safe(purchase) then return end
    -- SetTab includes the protected, automatic first-slot purchase on Camelot.
    -- Observe the native layout notification instead of wrapping that method.
    if not self.layoutRegistered and EventRegistry and type(EventRegistry.RegisterCallback) == "function" then
        EventRegistry:RegisterCallback("BankPanelMixin.ShowOrHideBagCost", self.OnBankLayout, self)
        self.layoutRegistered = true
    end
    if not self.button then
        self.button = Suite.Theme:ActionButton(BankFrame, "Deposit Reagents", 140, 21)
        self.button:SetSize(140, 21); self.button:SetText("Deposit Reagents")
        self.button:RegisterForClicks("LeftButtonUp")
        self.button:SetScript("OnClick", function() self:Start() end)
    end
    self.button:ClearAllPoints()
    if Read(purchase.IsShown, purchase) == true then
        self.button:SetPoint("LEFT", purchase, "RIGHT", 8, 0)
    else self.button:SetPoint("BOTTOMRIGHT", BankFrame, "BOTTOMRIGHT", -18, 37) end
    self.button:SetShown(self.bankOpen == true and Read(BankFrame.GetActiveBankType, BankFrame) == kind)
    self.button:SetEnabled(self.job == nil)
    self.button:SetText(self.job and "Depositing..." or "Deposit Reagents")
end
function Deposit:OnBankLayout()
    if not self:Enabled() then return end
    -- Check immediately so switching away and back cannot resume an old batch.
    if self.job and not self:Ready() then self:Cancel() end
    if self.layoutTimer or InCombatLockdown() or not C_Timer or type(C_Timer.NewTimer) ~= "function" then return end
    -- Let the native tab selection/purchase finish before changing owned UI.
    self.layoutTimer = C_Timer.NewTimer(0, function()
        self.layoutTimer = nil
        if self:Enabled() then self:Discover() end
    end)
end
function Deposit:OnEvent(event)
    if event == "BANKFRAME_CLOSED" or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_LOGOUT" then
        if self.layoutTimer then self.layoutTimer:Cancel(); self.layoutTimer = nil end
        if event ~= "PLAYER_REGEN_DISABLED" then self.bankOpen = nil end
        self:Cancel()
    elseif event == "BANKFRAME_OPENED" then self.bankOpen = true
    elseif event == "ITEM_DATA_LOAD_RESULT" and self.job and self.job.loading then self:Queue()
    elseif event == "BAG_UPDATE_DELAYED" then
        if self.job and self.transfer then self:Queue() end
        return
    end
    if self.job and not self:Ready() then self:Cancel() end
    if (event == "BANKFRAME_OPENED" or event == "BANK_TABS_CHANGED") and BankFrame
        and type(BankFrame.PurchaseFirstSlot) == "function" then
        self:OnBankLayout()
        return
    end
    self:Discover()
end
function Deposit:Apply()
    if not self:Enabled() then
        if self.layoutTimer then self.layoutTimer:Cancel(); self.layoutTimer = nil end
        if self.layoutRegistered and EventRegistry and type(EventRegistry.UnregisterCallback) == "function" then
            EventRegistry:UnregisterCallback("BankPanelMixin.ShowOrHideBagCost", self)
            self.layoutRegistered = nil
        end
        self:Cancel(); self.bankOpen = nil
        Suite.pending.bankDepositEnable = nil
        if self.events then self.events:UnregisterAllEvents() end
        Suite.AfterCombat("bankDepositHide", function() if self.button and not self:Enabled() then self.button:Hide() end end)
        self.active = nil; return
    end
    Suite.AfterCombat("bankDepositEnable", function()
        if not self:Enabled() then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event) self:OnEvent(event) end)
        end
        if not self.active then
            for _, event in ipairs({ "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "ADDON_LOADED", "BANK_TABS_CHANGED",
                "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "ITEM_DATA_LOAD_RESULT", "BAG_UPDATE_DELAYED", "PLAYER_LOGOUT" }) do
                self.events:RegisterEvent(event)
            end
            self.bankOpen = Safe(BankFrame) and Read(BankFrame.IsShown, BankFrame) == true
            self.active = true
        end
        self:Discover()
    end)
end
