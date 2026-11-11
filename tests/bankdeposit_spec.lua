local Suite, equal, Frame, SetCombat = ...
local deposit = Suite.BankDeposit
local names = { "CreateFrame", "BankFrame", "C_Container", "C_Item", "C_Bank", "C_Timer", "Enum",
    "NUM_TOTAL_EQUIPPED_BAG_SLOTS", "CursorHasItem", "GetCursorInfo", "SpellIsTargeting" }
local old, state = {}, {}
for _, name in ipairs(names) do old[name] = _G[name] end
for key, value in pairs(deposit) do state[key] = value end
local oldDB, oldPending, oldPrint = Suite.db, Suite.pending, Suite.Print
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
local timers, calls, loads, messages = {}, {}, {}, {}
local kind, held, cursor, targeting, allowed, throw, full = 0, false, nil, false, true, false, false
local capacity
local items, reagents = {}, { [100] = true, [200] = false, [300] = true }
local function Item(id, count)
    return { itemID = id, stackCount = count or 1, hyperlink = "item:" .. id, isLocked = false }
end
local function ResetItems()
    items = { [0] = { Item(100, 20), Item(200), Item(300) }, [1] = { Item(100, 7) } }
end
local function Widget()
    local frame = Frame()
    frame.IsForbidden = function(self) return self.forbidden or false end
    frame.SetEnabled = function(self, enabled) self.enabled = enabled end
    return frame
end
CreateFrame = function(_, _, parent)
    assert(not InCombatLockdown(), "deposit does not construct in combat")
    local frame = Widget(); frame.parent = parent
    return frame
end
BankFrame = Widget(); BankFrame:Show()
BankFrame.GetActiveBankType = function() return kind end
BankFrame.SetTab = function(_, nextKind) kind = nextKind end
BankFrame.BankPanel = Widget(); BankFrame.BankPanel.PurchaseButton = Widget()
BankFrame.BankPanel.PurchaseButton:Show()
Enum = { BankType = { Character = 0, Account = 2 } }
NUM_TOTAL_EQUIPPED_BAG_SLOTS = 1
CursorHasItem = function() return held end
GetCursorInfo = function() return cursor end
SpellIsTargeting = function() return targeting end
C_Bank = { CanViewBank = function() return allowed end }
C_Item = { GetItemInfo = function(id)
    if reagents[id] == nil then return end
    return "Item " .. id, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, reagents[id]
end, RequestLoadItemDataByID = function(id) loads[id] = (loads[id] or 0) + 1 end }
C_Container = {
    GetContainerNumSlots = function(bag) return bag == 0 and 3 or 1 end,
    GetContainerItemInfo = function(bag, slot) return items[bag] and items[bag][slot] end,
    UseContainerItem = function(bag, slot, unit, bankType, reagentBank)
        assert(not InCombatLockdown(), "deposit never transfers in combat")
        assert(BankFrame:IsShown() and deposit.bankOpen and allowed == true, "deposit requires live bank")
        assert(kind == 0 and bankType == 0 and unit == nil and reagentBank == false, "explicit personal bank transfer")
        assert(reagents[items[bag][slot].itemID] == true, "only native-confirmed reagents transfer")
        if throw then error("request rejected") end
        calls[#calls + 1] = { bag = bag, slot = slot, count = items[bag][slot].stackCount }
        if capacity then
            local id, stack = items[bag][slot].itemID, items[bag][slot].stackCount
            local moved = math.min(capacity[id] or 0, stack)
            capacity[id] = (capacity[id] or 0) - moved
            if moved == stack then items[bag][slot] = nil else items[bag][slot].stackCount = stack - moved end
        elseif not full then items[bag][slot] = nil end
    end,
}
C_Timer = { NewTimer = function(delay, callback)
    local timer = { delay = delay, callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
Suite.Print = function(message) messages[#messages + 1] = message end
local function Flush(delay)
    local batch = timers; timers = {}
    for _, timer in ipairs(batch) do
        if not timer.cancelled then
            if not delay or timer.delay == delay then timer.callback() else timers[#timers + 1] = timer end
        end
    end
end
local function Finish()
    for _ = 1, 8 do Flush() end
end
ResetItems()
equal(Suite.db.bankDepositReagents, false, "deposit button starts independently off")
equal(Suite.InitializeDB({ bankDepositReagents = { secret = true } }).bankDepositReagents, false, "restricted preference is sanitized")
local found = Suite.SettingsCatalog:Search("deposit reagents")
equal(found[1].key, "bankDepositReagents", "settings search finds reagent deposit control")
deposit:Apply()
equal(deposit.button, nil, "disabled deposit creates no bank button")
Suite.db.bankDepositReagents = true
SetCombat(true); deposit:Apply()
equal(deposit.button, nil, "first enable defers combat construction")
SetCombat(false); deposit:Apply()
equal(deposit.button:GetText(), "Deposit Reagents", "native-style bank button has requested label")
equal(deposit.button.point[2], BankFrame.BankPanel.PurchaseButton, "button sits beside Purchase")
equal(deposit.button.point[4], 8, "button leaves a gap beside Purchase")
equal(deposit.button:IsShown(), true, "enabling at live personal bank shows button")
equal(Suite.db.offlineBank, false, "deposit does not require bank recording")
equal(#calls, 0, "enabling never deposits automatically")
deposit.button.OnClick(); deposit.button.OnClick()
equal(#calls, 1, "click starts one finite batch and repeat click cannot duplicate it")
equal(deposit.button.enabled, false, "button is disabled while batch runs")
Finish()
equal(#calls, 3, "all carried reagent stacks across equipped bags are requested")
equal(items[0][2].itemID, 200, "ordinary usable item stays in bags")
equal(deposit.job, nil, "completed batch has no job")
equal(deposit.button.enabled, true, "button becomes available after completion")
local count = #calls
ResetItems(); held = true; deposit:Start(); held = false
cursor = "spell"; deposit:Start(); cursor = nil
targeting = true; deposit:Start(); targeting = false
allowed = { secret = true }; deposit:Start(); allowed = true
kind = 2; deposit:Start(); kind = 0
equal(#calls, count, "cursor, targeting, restricted access and account bank block transfers")
BankFrame:Hide(); deposit:Start(); BankFrame:Show()
equal(#calls, count, "saved-view-only context cannot transfer")
ResetItems(); deposit:Start()
items[0][3] = Item(200) -- slot recycled while the batch is settling
Finish()
equal(#calls, count + 2, "recycled slots are revalidated before every transfer")
count = #calls
ResetItems(); deposit:Start(); SetCombat(true); deposit:OnEvent("PLAYER_REGEN_DISABLED")
Finish(); SetCombat(false); deposit:OnEvent("PLAYER_REGEN_ENABLED"); Finish()
equal(#calls, count + 1, "combat cancels queued transfers without automatic replay")
ResetItems(); deposit:Start(); deposit:OnEvent("BANKFRAME_CLOSED"); Finish()
equal(#calls, count + 2, "bank closure cancels queued transfers")
deposit:OnEvent("BANKFRAME_OPENED")
ResetItems(); deposit:Start(); BankFrame:SetTab(2); Finish()
equal(#calls, count + 3, "bank-type switch cancels the batch")
equal(deposit.button:IsShown(), false, "button is hidden on account bank")
BankFrame:SetTab(0)
ResetItems(); full = true; deposit:Start(); Finish(); full = false
equal(#calls, count + 6, "full bank attempts each reagent once without infinite retries")
count = #calls
ResetItems(); items[0][1].isLocked = true; items[0][3].itemID = { secret = true }
deposit:Start(); Finish()
equal(#calls, count + 1, "locked and restricted items never transfer")
ResetItems(); reagents[300] = nil; deposit:Start()
equal(#calls, count + 1, "batch waits for missing item metadata")
equal(loads[300], 1, "missing reagent metadata requests native loading")
reagents[300] = true; deposit:OnEvent("ITEM_DATA_LOAD_RESULT"); Flush(0.2); Finish()
equal(#calls, count + 4, "native metadata completion resumes clicked batch")
ResetItems(); reagents[300] = nil; deposit:Start(); Flush(5); Finish()
equal(#calls, count + 6, "metadata timeout skips unknown items while depositing known reagents")
equal(#messages, 1, "metadata timeout explains how to retry unavailable data")
reagents[300] = true
ResetItems(); throw = true; deposit:Start(); Finish(); throw = false
equal(deposit.job, nil, "native transfer rejection cancels whole batch")
equal(#messages, 2, "native transfer rejection is disclosed")
ResetItems(); deposit:Start(); Suite.db.bankDepositReagents = false; deposit:Apply(); Finish()
equal(deposit.job, nil, "disable cancels batch and timers")
equal(deposit.button:IsShown(), false, "disable hides button")
Suite.db.bankDepositReagents = true; deposit:Apply()
BankFrame.BankPanel.PurchaseButton:Hide(); deposit:Discover()
equal(deposit.button.point[1], "BOTTOMRIGHT", "all-bank-slots-owned layout retains the deposit button")
equal(deposit.button.point[2], BankFrame, "hidden Purchase fallback anchors to live bank")
ResetItems(); capacity = { [100] = 23, [300] = 0 }
deposit:Start(); Finish()
equal(items[0][1], nil, "native capacity can accept a whole stack")
equal(items[1][1].stackCount, 4, "native capacity can merge part of a remaining stack")
equal(items[0][3].itemID, 300, "reagent with no compatible capacity remains carried")
equal(items[0][2].itemID, 200, "capacity-limited batch still leaves nonreagents alone")
capacity = nil
count = #calls
ResetItems(); deposit:Start(); cursor = "item"; Finish(); cursor = nil
equal(#calls, count + 1, "picking up an item during the batch stops subsequent requests")
ResetItems(); deposit:Start(); items[0][3].stackCount = 99; Finish()
equal(#calls, count + 3, "stack-count changes invalidate the original slot snapshot")
ResetItems(); reagents[300] = { secret = true }; deposit:Start()
equal(deposit.job.loading, true, "restricted reagent classification waits rather than authorizing a transfer")
deposit:OnEvent("BANKFRAME_CLOSED"); reagents[300] = true
deposit:OnEvent("ITEM_DATA_LOAD_RESULT"); Finish()
equal(deposit.job, nil, "metadata completion after bank closure cannot revive the batch")
deposit:Cancel()
for key in pairs(deposit) do deposit[key] = nil end
for key, value in pairs(state) do deposit[key] = value end
for _, name in ipairs(names) do _G[name] = old[name] end
Suite.db, Suite.pending, Suite.Print = oldDB, oldPending, oldPrint
SetCombat(false)
