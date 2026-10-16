local Suite, equal, Frame, SetCombat = ...
local vendor = Suite.Vendor
local old = { CreateFrame = CreateFrame, C_Timer = C_Timer, C_Container = C_Container,
    C_MerchantFrame = C_MerchantFrame, MerchantFrame = MerchantFrame, Enum = Enum,
    C_PlayerInteractionManager = C_PlayerInteractionManager,
    NUM_TOTAL_EQUIPPED_BAG_SLOTS = NUM_TOTAL_EQUIPPED_BAG_SLOTS, NUM_BAG_SLOTS = NUM_BAG_SLOTS,
    CanMerchantRepair = CanMerchantRepair, GetRepairAllCost = GetRepairAllCost, RepairAllItems = RepairAllItems,
    CanGuildBankRepair = CanGuildBankRepair, GetGuildBankMoney = GetGuildBankMoney,
    GetGuildBankWithdrawMoney = GetGuildBankWithdrawMoney, GetMoney = GetMoney,
    CursorHasItem = CursorHasItem, InRepairMode = InRepairMode,
    StaticPopup_ShowCustomGenericConfirmation = StaticPopup_ShowCustomGenericConfirmation, StaticPopup_Hide = StaticPopup_Hide }
old.MerchantFrame_OnSellAllJunkButtonConfirmed = MerchantFrame_OnSellAllJunkButtonConfirmed
local oldDB, oldPending, oldPrint = Suite.db, Suite.pending, Suite.Print
local timers, sales, repairs, messages, prompts, hidden = {}, {}, {}, {}, {}, {}
local bags, excluded, clock, inCombat, constructed, bulkCalls = {}, {}, 0, false, 0, 0
local money, cost, canRepair, permission, guildFunds, allowance = 1000, 100, true, true, 1000, 1000
local cursor, repairMode, instantEnabled, junkCount, saleDelay = false, false, true, 1, false
local interacting = false
local nativeAccepts = 0
local function Combat(value) inCombat = value; SetCombat(value) end
local function Fire(event) if vendor.events and vendor.events.OnEvent then vendor.events.OnEvent(vendor.events, event) end end
local function Advance(seconds)
    local target = clock + seconds
    for _ = 1, 200 do
        local index, nextTimer
        for i, timer in ipairs(timers) do
            if not timer.cancelled and timer.at <= target and (not nextTimer or timer.at < nextTimer.at) then index, nextTimer = i, timer end
        end
        if not nextTimer then clock = target; return end
        table.remove(timers, index); clock = nextTimer.at; nextTimer.callback()
    end
    error("vendor timer did not settle")
end
local function TimerCount()
    local count = 0
    for _, timer in ipairs(timers) do if not timer.cancelled then count = count + 1 end end
    return count
end
local function Junk(id, count)
    return { itemID = id, stackCount = count or 1, quality = 0, isLocked = false, hasNoValue = false }
end
local function Open()
    interacting = true; MerchantFrame:Show(); Fire("MERCHANT_SHOW")
end
local function Close()
    interacting = false; MerchantFrame:Hide(); Fire("MERCHANT_CLOSED")
end
Suite.db = Suite.InitializeDB(nil)
Suite.pending = {}
Suite.Print = function(text) messages[#messages + 1] = text end
CreateFrame = function(...)
    assert(not inCombat, "vendor event-frame construction must defer in combat")
    constructed = constructed + 1
    local frame = old.CreateFrame(...)
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    return frame
end
C_Timer = { NewTimer = function(delay, callback)
    local timer = { at = clock + delay, callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
MerchantFrame = Frame(); MerchantFrame:Hide()
Enum = { BagSlotFlags = { ExcludeJunkSell = 64 }, PlayerInteractionType = { Merchant = 5 } }
C_PlayerInteractionManager = { IsInteractingWithNpcOfType = function(kind)
    equal(kind, 5, "vendor checks only the native Merchant interaction")
    return interacting
end }
NUM_TOTAL_EQUIPPED_BAG_SLOTS, NUM_BAG_SLOTS = 5, 4
C_Container = {
    GetBackpackSellJunkDisabled = function() return excluded[0] or false end,
    GetBagSlotFlag = function(bag, flag) equal(flag, 64, "slow sale uses native junk exclusion flag"); return excluded[bag] or false end,
    GetContainerNumSlots = function(bag) return bags[bag] and bags[bag].slots or 0 end,
    GetContainerItemInfo = function(bag, slot) return bags[bag] and bags[bag][slot] end,
    UseContainerItem = function(bag, slot)
        assert(not inCombat and MerchantFrame:IsShown(), "bag item can only be sold at an open vendor outside combat")
        assert(not cursor and not repairMode, "sale must not use a cursor-held item or repair cursor")
        sales[#sales + 1] = { bag = bag, slot = slot, id = bags[bag][slot].itemID, at = clock }
        if not saleDelay then bags[bag][slot] = nil end
        money = money + 1
        Fire("BAG_UPDATE_DELAYED"); Fire("PLAYER_MONEY"); Fire("MERCHANT_UPDATE")
    end,
}
C_MerchantFrame = {
    IsSellAllJunkEnabled = function() return instantEnabled end,
    GetNumJunkItems = function() return junkCount end,
    SellAllJunkItems = function() assert(not inCombat and MerchantFrame:IsShown()); bulkCalls = bulkCalls + 1 end,
}
CanMerchantRepair = function() return canRepair end
GetRepairAllCost = function() return cost, canRepair end
RepairAllItems = function(guild)
    assert(not inCombat and MerchantFrame:IsShown(), "repair only at an open vendor outside combat")
    repairs[#repairs + 1] = guild
    cost = 0
    Fire("MERCHANT_UPDATE")
end
CanGuildBankRepair = function() return permission end
GetGuildBankMoney = function() return guildFunds end
GetGuildBankWithdrawMoney = function() return allowance end
GetMoney = function() return money end
CursorHasItem = function() return cursor end
InRepairMode = function() return repairMode end
StaticPopup_ShowCustomGenericConfirmation = function(data) prompts[#prompts + 1] = data end
MerchantFrame_OnSellAllJunkButtonConfirmed = function()
    nativeAccepts = nativeAccepts + 1
    C_MerchantFrame.SellAllJunkItems()
end
StaticPopup_Hide = function(which, data)
    equal(which, "GENERIC_CONFIRMATION", "only generic sale confirmation is cancelled")
    hidden[#hidden + 1] = data
    if data.cancelCallback then data.cancelCallback() end
end

equal(Suite.db.autoRepair, false, "automatic repair starts off")
equal(Suite.db.autoSellJunk, false, "automatic junk selling starts off")
equal(Suite.db.repairSource, "personal", "repair defaults to personal funding")
equal(Suite.db.junkMode, "slow", "junk sale defaults to recoverable slow mode")
vendor:Apply()
equal(constructed, 0, "disabled vendor module constructs no frames")
equal(vendor.popupHooked, nil, "disabled vendor module installs no popup hook")
equal(TimerCount(), 0, "disabled vendor module schedules no work")
Suite.db.repairSource, Suite.db.junkMode = "invalid", "invalid"
vendor:Apply()
equal(Suite.db.repairSource, "personal", "invalid repair funding resets conservatively")
equal(Suite.db.junkMode, "slow", "invalid sale mode resets conservatively")

Suite.db.autoRepair = true
Combat(true); vendor:Apply()
equal(constructed, 0, "enabling vendor tools in combat defers frame creation")
Suite.db.autoRepair = false; vendor:Apply()
Combat(false)
for _, callback in pairs(Suite.pending) do callback() end
Suite.pending = {}
equal(constructed, 0, "disable cancels pending vendor enable")
Suite.db.autoRepair = true; vendor:Apply()
equal(vendor.events.registered.MERCHANT_SHOW, true, "enabled module observes merchant visits")
Open(); Advance(0.11)
equal(#repairs, 1, "personal gold repairs once on visit")
equal(repairs[1], false, "personal repair passes no guild funding")
for _ = 1, 10 do Fire("MERCHANT_UPDATE"); Fire("PLAYER_MONEY") end
equal(TimerCount(), 1, "merchant event burst coalesces work")
Advance(0.1)
equal(#repairs, 1, "merchant refreshes do not repeat a repair request")
equal(TimerCount(), 0, "idle vendor has no timer")
Close()

Suite.db.repairSource = "guild"; vendor:Apply(); cost = 100
Open(); Advance(0.11)
equal(repairs[2], true, "guild selection uses native guild repair")
Close()
local before = #repairs
for _, case in ipairs({ { false, 1000, 1000 }, { true, 99, 1000 }, { true, 1000, 99 },
    { { secret = true }, 1000, 1000 }, { true, { secret = true }, 1000 }, { true, 1000, { secret = true } } }) do
    permission, guildFunds, allowance = case[1], case[2], case[3]; cost = 100
    Open(); Advance(0.11); Close()
end
equal(#repairs, before, "unavailable guild permission/funds never fall back to personal gold")
permission, guildFunds, allowance, cost = true, 1000, -1, 100
Open(); Advance(0.11)
equal(#repairs, before + 1, "guild leader unlimited allowance uses full bank balance")
Close()
guildFunds, cost = 99, 100
Open(); Advance(0.11)
equal(#repairs, before + 1, "unlimited allowance still requires enough guild money")
Close()
permission, guildFunds, allowance, cost = true, 0, 1000, 100
Open(); Advance(0.11)
local beforeGuildRefresh = #repairs
guildFunds = 1000; Fire("GUILDBANK_UPDATE_MONEY"); Advance(0.1)
equal(#repairs, beforeGuildRefresh + 1, "late guild balance data retries repair through the native guild event")
Close()
Suite.db.repairSource = "personal"; vendor:Apply()
money, cost = 99, 100
Open(); Advance(0.11)
equal(#repairs, beforeGuildRefresh + 1, "insufficient personal funds skip repair")
money = 100; Fire("PLAYER_MONEY"); Advance(0.1)
equal(#repairs, beforeGuildRefresh + 2, "new vendor proceeds can fund an initially unaffordable repair")
Close()
cost, money = { secret = true }, 1000
Open(); Advance(0.11); Close()
equal(#repairs, beforeGuildRefresh + 2, "restricted repair cost is never compared or sent")
cost, canRepair = 100, { secret = true }
Open(); Advance(0.11); Close()
equal(#repairs, beforeGuildRefresh + 2, "restricted repair predicate is not treated as permission")
canRepair, cost = true, 0

Suite.db.autoRepair, Suite.db.autoSellJunk = false, true; vendor:Apply()
bags = { [0] = { slots = 1, [1] = Junk(100) } }
interacting = true
Fire("MERCHANT_SHOW") -- The interaction event can arrive before the native frame is shown.
equal(TimerCount(), 1, "merchant event ordering still queues one initial worker")
MerchantFrame:Show(); Advance(0.11)
equal(#sales, 1, "native merchant frame showing after the event does not lose the automatic sale")
Close(); sales = {}
bags = { [0] = { slots = 1, [1] = Junk(100) } }
MerchantFrame:Show(); Fire("MERCHANT_SHOW"); Advance(0.11)
equal(#sales, 0, "a stale shown merchant frame cannot turn selling into ordinary item use")
interacting = { secret = true }; Fire("MERCHANT_UPDATE"); Advance(0.1)
equal(#sales, 0, "restricted merchant interaction is never treated as an active vendor")
C_PlayerInteractionManager.IsInteractingWithNpcOfType = nil
Fire("MERCHANT_UPDATE"); Advance(0.1)
equal(#sales, 0, "missing merchant interaction predicate fails closed")
C_PlayerInteractionManager.IsInteractingWithNpcOfType = function() return interacting end
Close()
bags = { [0] = { slots = 16 } }
for i = 1, 16 do bags[0][i] = Junk(100 + i) end
Open(); Advance(0.11)
equal(#sales, 1, "slow mode starts with one stack")
Advance(3)
equal(#sales, 12, "slow mode stops at twelve stacks per vendor visit")
equal(bags[0][13].itemID, 113, "overflow stays in bags instead of evicting early buybacks")
for i = 2, #sales do equal(sales[i].at - sales[i - 1].at >= 0.199, true, "event bursts do not accelerate paced selling") end
Fire("BAG_UPDATE_DELAYED"); Advance(0.1)
equal(#sales, 12, "bag changes cannot bypass per-visit buyback limit")
vendor:Apply(); Advance(0.1)
equal(#sales, 12, "unrelated settings apply does not reset sale budget")
bags[0][1] = Junk(101); Fire("BAG_UPDATE_DELAYED"); Advance(0.1)
equal(#sales, 12, "completed sale does not resell bought-back junk")
Close(); Open(); Advance(2)
equal(#sales, 17, "a new visit can sell the remaining stacks")
Close()

sales = {}
bags = { [0] = { slots = 2, [1] = Junk(201), [2] = Junk(202) },
    [1] = { slots = 1, [1] = Junk(203) }, [5] = { slots = 1, [1] = Junk(204) } }
excluded[1] = true
Open(); Advance(0.11)
bags[0][2] = Junk(999) -- A different gray item in the same queued slot.
Advance(1)
equal(#sales, 2, "changed queued slot is skipped while carried reagent-bag junk can sell")
equal(sales[2].id, 204, "carried fifth bag is scanned; bank is outside scope")
equal(bags[0][2].itemID, 999, "queued replacement item remains untouched")
equal(bags[1][1].itemID, 203, "native excluded bag remains untouched")
Close()
excluded = { [0] = true }; bags = { [0] = { slots = 1, [1] = Junk(205) } }
Open(); Advance(1); Close()
equal(#sales, 2, "native backpack junk exclusion is respected")
excluded = { [0] = { secret = true } }
Open(); Advance(1); Close()
equal(#sales, 2, "restricted exclusion fails closed")
excluded = {}
bags = { [0] = { slots = 8 } }
for i = 1, 8 do bags[0][i] = Junk(300 + i) end
bags[0][1].quality = 1; bags[0][2].quality = { secret = true }
bags[0][3].isLocked = true; bags[0][4].hasNoValue = true
bags[0][5].itemID = { secret = true }; bags[0][6].stackCount = { secret = true }
bags[0][7].hasNoValue = { secret = true }; bags[0][8].isLocked = { secret = true }
Open(); Advance(1); Close()
equal(#sales, 2, "only readable, unlocked, sellable gray stacks qualify")

bags = { [0] = { slots = 2, [1] = Junk(401), [2] = Junk(402) } }
saleDelay = true
Open(); Advance(0.11); Advance(0.6)
equal(#sales, 3, "pending sale is never repeated while waiting for bag acknowledgement")
bags[0][1] = nil; Advance(0.3)
equal(#sales, 4, "next stack waits for previous sale acknowledgement")
Advance(3)
equal(TimerCount(), 0, "failed sale stops after a bounded wait")
equal(bags[0][2].itemID, 402, "failed sale is not retried indefinitely")
Close(); saleDelay = false

bags = { [0] = { slots = 2, [1] = Junk(501), [2] = Junk(502) } }; sales = {}
Open(); Advance(0.11); Close(); Advance(1)
equal(#sales, 1, "closing vendor immediately cancels remaining sales")
equal(TimerCount(), 0, "closed vendor has no pending timer")
Open(); Combat(true); Fire("PLAYER_REGEN_DISABLED"); Advance(1)
equal(#sales, 1, "combat prevents all queued bag uses")
equal(TimerCount(), 0, "combat retains no sale timer")
Combat(false); Fire("PLAYER_REGEN_ENABLED"); Advance(1)
equal(#sales, 2, "same merchant visit resumes after combat")
Close()
cursor = true; bags[0][1] = Junk(503)
Open(); Advance(0.11)
equal(#sales, 2, "cursor-held item blocks the slow use path")
cursor = false; Fire("BAG_UPDATE_DELAYED"); Advance(1)
equal(#sales, 3, "bag change resumes sale after cursor clears")
Close()
repairMode = true; bags[0][1] = Junk(504)
Open(); Advance(0.11); Close()
equal(#sales, 3, "manual repair cursor cannot turn selling into a repair")
repairMode = false

local popupShow = StaticPopup_ShowCustomGenericConfirmation
StaticPopup_ShowCustomGenericConfirmation = nil
Suite.db.junkMode = "instant"; vendor:Apply()
Open(); Advance(0.11)
equal(bulkCalls, 1, "enabled permanent mode sells automatically without a confirmation")
equal(#prompts, 0, "automatic permanent sale creates no Suite popup")
equal(vendor.popupHooked, nil, "unavailable native popup helper installs no hook")
StaticPopup_ShowCustomGenericConfirmation = popupShow
Fire("ADDON_LOADED"); Advance(0.1)
equal(vendor.popupHooked, true, "late native popup helper gets one observer outside combat")
for _ = 1, 10 do Fire("MERCHANT_UPDATE"); Fire("PLAYER_MONEY") end
vendor:Apply(); Advance(0.2)
equal(bulkCalls, 1, "events and unrelated settings do not repeat the automatic permanent sale")
equal(#sales, 3, "instant mode does not imitate a series of bag uses")
equal(TimerCount(), 0, "finished permanent sale leaves no idle timer")

local function NativePopup()
    return { text = "Native localized junk warning", callback = MerchantFrame_OnSellAllJunkButtonConfirmed }
end
local native = NativePopup()
StaticPopup_ShowCustomGenericConfirmation(native)
equal(nativeAccepts, 1, "native Sell Junk popup callback is automatically accepted in enabled permanent mode")
equal(bulkCalls, 2, "accepted native popup invokes the native sale once")
equal(hidden[#hidden], native, "auto acceptance hides only the exact native junk popup data")
local nativeHidden = #hidden
local unrelatedCalls = 0
local unrelated = { text = native.text, callback = function() unrelatedCalls = unrelatedCalls + 1 end }
StaticPopup_ShowCustomGenericConfirmation(unrelated)
equal(unrelatedCalls, 0, "matching warning text cannot auto accept an unrelated callback")
equal(#hidden, nativeHidden, "other generic confirmations remain open")
StaticPopup_ShowCustomGenericConfirmation({ secret = true })
StaticPopup_ShowCustomGenericConfirmation({ callback = { secret = true } })
StaticPopup_ShowCustomGenericConfirmation({})
equal(bulkCalls, 2, "secret/missing popup identity never authorizes a sale")
Suite.db.autoSellJunk = false; vendor:Apply()
StaticPopup_ShowCustomGenericConfirmation(NativePopup())
equal(bulkCalls, 2, "disabled junk selling leaves the native warning under native control")
equal(next(vendor.events.registered), nil, "disabled module unregisters all feature events")
equal(TimerCount(), 0, "disabled module cancels all sale timers")
Suite.db.autoRepair = true; vendor:Apply()
StaticPopup_ShowCustomGenericConfirmation(NativePopup())
equal(bulkCalls, 2, "repair-only mode cannot auto accept a permanent sale")
Suite.db.autoRepair, Suite.db.autoSellJunk, Suite.db.junkMode = false, true, "slow"; vendor:Apply()
StaticPopup_ShowCustomGenericConfirmation(NativePopup())
equal(bulkCalls, 2, "slow mode cannot auto accept a permanent sale")
Suite.db.junkMode = "instant"; vendor:Apply()
Combat(true); Fire("PLAYER_REGEN_DISABLED")
StaticPopup_ShowCustomGenericConfirmation(NativePopup()); Advance(1)
equal(bulkCalls, 2, "combat prevents native popup acceptance and queued automatic sales")
Combat(false); Fire("PLAYER_REGEN_ENABLED"); Advance(0.2)
equal(bulkCalls, 3, "unsold visit resumes automatic permanent selling after combat")
Combat(true); Fire("PLAYER_REGEN_DISABLED")
Combat(false); Fire("PLAYER_REGEN_ENABLED"); Advance(0.2)
equal(bulkCalls, 3, "completed permanent sale is not repeated after combat")
Close()
StaticPopup_ShowCustomGenericConfirmation(NativePopup())
equal(bulkCalls, 3, "closed merchant cannot auto accept a stale native junk warning")
Open(); Close(); Advance(1)
equal(bulkCalls, 3, "closing before initial worker prevents permanent sale")
Open(); Suite.db.autoSellJunk = false; vendor:Apply(); Advance(1)
equal(bulkCalls, 3, "disabling before initial worker prevents permanent sale")
instantEnabled = { secret = true }; Suite.db.autoSellJunk = true; vendor:Apply(); Advance(0.2)
StaticPopup_ShowCustomGenericConfirmation(NativePopup())
equal(bulkCalls, 3, "restricted bulk predicate prevents automatic and popup-triggered sales")
Close()
instantEnabled, junkCount = true, { secret = true }
Open(); Advance(0.11)
StaticPopup_ShowCustomGenericConfirmation(NativePopup())
equal(bulkCalls, 3, "restricted junk count prevents automatic and popup-triggered sales")
Close()
junkCount = 1; C_MerchantFrame.SellAllJunkItems = nil
Open(); Advance(0.11)
StaticPopup_ShowCustomGenericConfirmation(NativePopup())
equal(bulkCalls, 3, "missing bulk sale never falls back to unsafe item uses")
equal(#hidden, nativeHidden, "blocked native junk warnings remain open for the user")
Close()

Suite.db.autoSellJunk = false; vendor:Apply()
-- GUI rows must expose both funding choices, both modes and the recovery limit.
Suite.db.junkMode = "slow"
Suite.GUI:OpenPage("vendor")
equal(Suite.GUI.page, "vendor", "vendor slash destination opens its own settings page")
equal(Suite.GUI.tabs.vendor.label.text, "Vendor", "tenth sidebar page has a plain name")
equal(Suite.GUI.rows[2].value.text, "Personal gold", "repair funding is visible in settings")
equal(Suite.GUI.rows[4].value.text, "Slow", "slow sale mode is visible in settings")
equal(Suite.GUI.rows[5].help.text:find("12 stacks", 1, true) ~= nil, true, "slow settings disclose buyback capacity")
Suite.GUI:Action("junkMode")
equal(Suite.GUI.rows[4].value.text, "Instant", "mode control flips to instant")
equal(Suite.GUI.rows[5].help.text:find("aren't recoverable", 1, true) ~= nil, true, "instant settings show the recovery warning")
equal(Suite.GUI.rows[5].help.text:find("need no confirmation", 1, true) ~= nil, true, "permanent settings explain automatic popup acceptance")
equal(Suite.GUI.rows[5].OnClick, nil, "recovery explanation has no misleading action")
Suite.GUI:Action("repairSource")
equal(Suite.GUI.rows[2].value.text, "Guild gold", "funding control flips to guild")
Suite.GUI:Select("overview")
equal(type(Suite.GUI.rows[5].OnClick), "function", "reused passive row regains its normal action on another page")

vendor:EndVisit()
for name, value in pairs(old) do _G[name] = value end
-- Nil globals are absent from a Lua table; explicitly restore those capability omissions.
for _, name in ipairs({ "C_MerchantFrame", "MerchantFrame", "CanMerchantRepair", "GetRepairAllCost", "RepairAllItems",
    "C_PlayerInteractionManager",
    "CanGuildBankRepair", "GetGuildBankMoney", "GetGuildBankWithdrawMoney", "GetMoney", "CursorHasItem", "InRepairMode",
    "StaticPopup_ShowCustomGenericConfirmation", "StaticPopup_Hide" }) do if old[name] == nil then _G[name] = nil end end
MerchantFrame_OnSellAllJunkButtonConfirmed = old.MerchantFrame_OnSellAllJunkButtonConfirmed
Suite.db, Suite.pending, Suite.Print = oldDB, oldPending, oldPrint
Combat(false)
