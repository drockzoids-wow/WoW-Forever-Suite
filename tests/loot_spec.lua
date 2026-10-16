local Suite, equal, Frame, SetCombat = ...
local loot = Suite.Loot
local names = { "CreateFrame", "C_Timer", "Enum", "C_LootFrame", "GetNumLootItems", "GetLootSlotType", "LootSlot",
    "SetCVar", "CloseLoot", "ConfirmLootSlot", "RollOnLoot", "GiveMasterLoot" }
local saved = {}
for _, name in ipairs(names) do saved[name] = _G[name] end
local oldDB, oldPending, oldApply = Suite.db, Suite.pending, Suite.Apply
local slots, sent, count, constructed, bulk = {}, {}, nil, 0, 0
local queryEvent, actionEvent
local function Secret() return { secret = true } end
local function Fire(event, ...)
    if loot.events and loot.events.registered[event] then loot.events.OnEvent(loot.events, event, ...) end
end
local function Fresh()
    loot.visit = nil; slots, sent, count, bulk = { 1, 2, 3, 0 }, {}, nil, 0
    queryEvent, actionEvent = nil, nil
    Suite.db.quickLoot = true; loot:Apply()
end
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
equal(Suite.db.quickLoot, false, "quick loot starts off independently")
local persisted = Suite.InitializeDB({ quickLoot = true, autoQuestPickup = false })
equal(persisted.quickLoot, true, "quick-loot preference survives initialization")
equal(persisted.autoQuestPickup, false, "quick loot does not enable quest pickup")
CreateFrame = function(...)
    assert(not InCombatLockdown(), "loot event-frame construction must defer through combat")
    constructed = constructed + 1
    local frame = saved.CreateFrame(...)
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    return frame
end
C_Timer = { NewTimer = function() error("quick loot must not schedule pacing or idle timers") end,
    After = function() error("quick loot must not schedule uncancellable timers") end }
local function Unowned() error("quick loot must preserve native settings, closing, confirmations and distribution") end
SetCVar, CloseLoot, ConfirmLootSlot, RollOnLoot, GiveMasterLoot = Unowned, Unowned, Unowned, Unowned, Unowned
Enum = { LootSlotType = { None = 0, Item = 1, Money = 2, Currency = 3 } }
GetNumLootItems = function() if count ~= nil then return count else return #slots end end
GetLootSlotType = function(slot)
    if queryEvent then queryEvent(slot) end
    return slots[slot]
end
LootSlot = function(slot)
    sent[#sent + 1] = slot
    if actionEvent then actionEvent(slot) end
end
C_LootFrame = { TryAutoLoot = function() bulk = bulk + 1 end }
loot:Apply(); equal(constructed, 0, "disabled loot module creates no frame")
Fire("LOOT_READY", true); equal(#sent, 0, "disabled loot module takes no loot")
SetCombat(true); Suite.db.quickLoot = true; loot:Apply()
equal(constructed, 0, "combat enable creates no loot frame")
equal(type(Suite.pending.loot), "function", "loot activation waits for combat")
Suite.db.quickLoot = false; loot:Apply(); equal(Suite.pending.loot, nil, "disable cancels deferred activation")
SetCombat(false); Fresh(); equal(constructed, 1, "loot uses one anonymous event frame")
equal(#sent, 0, "enabling does not sweep an existing loot window")
Fire("LOOT_READY", true)
equal(#sent, 3, "ready auto-loot requests items, money and currency synchronously")
equal(sent[1], 3, "quick-loot burst begins with highest occupied slot")
equal(sent[2], 2, "quick-loot burst includes money")
equal(sent[3], 1, "quick-loot burst finishes with lowest occupied slot")
equal(bulk, 0, "slot and bulk paths never both run")
Fire("LOOT_READY", true); Fire("LOOT_OPENED", true); Fire("LOOT_SLOT_CHANGED", 1)
equal(#sent, 3, "duplicate ready/open/change events do not repeat the pass")
equal(loot.events.registered.LOOT_OPENED, nil, "quick loot acts before window presentation")
equal(loot.events.registered.START_LOOT_ROLL, nil, "quick loot leaves group rolls native")
equal(loot.events.OnUpdate, nil, "loot module has no per-frame updater")
Fire("LOOT_CLOSED"); Fire("LOOT_READY", true); equal(#sent, 6, "new loot session gets a fresh pass")
Fresh(); Fire("LOOT_READY", false); equal(#sent, 0, "manual loot and auto-loot bypass remain manual")
Fire("LOOT_READY", true); equal(#sent, 0, "later ready event cannot defeat manual choice for this session")
Fire("LOOT_CLOSED"); Fire("LOOT_READY", true); equal(#sent, 3, "effective auto-loot modifier can enable the next session")
for _, autoLoot in ipairs({ Secret(), 1, "true" }) do
    Fresh(); Fire("LOOT_READY", autoLoot); equal(#sent, 0, "unknown/restricted auto-loot state stays native")
end
Fresh(); Fire("LOOT_READY", nil); equal(#sent, 0, "missing auto-loot state stays native")
for _, value in ipairs({ Secret(), -1, 0/0, math.huge, 0.5, 1001 }) do
    Fresh(); count = value; Fire("LOOT_READY", true); equal(#sent, 0, "invalid/restricted loot counts are never iterated")
end
Fresh(); slots = {}; Fire("LOOT_READY", true); equal(#sent, 0, "empty loot needs no requests")
slots = { 1 }; Fire("LOOT_READY", true); equal(#sent, 1, "later ready data can supply a previously empty session")
Fresh(); slots = { Secret(), 4, 0, 1 }; Fire("LOOT_READY", true)
equal(#sent, 1, "restricted, unsupported and empty slot types are skipped")
equal(sent[1], 4, "readable permitted slot remains lootable independently")
Fresh(); Enum.LootSlotType.Item = Secret(); Fire("LOOT_READY", true)
equal(#sent, 0, "restricted slot-type constants are not compared")
Enum.LootSlotType.Item = 1
Fresh(); actionEvent = function(slot) table.remove(slots, slot) end
slots = { 1, 1, 1 }; Fire("LOOT_READY", true)
equal(#sent, 3, "reverse traversal handles synchronous shrinking slot lists")
equal(sent[3], 1, "shrinking list reaches its original first slot")
Fresh(); actionEvent = function() count = Secret() end; Fire("LOOT_READY", true)
equal(#sent, 1, "restricted mid-pass count stops remaining requests")
Fresh(); actionEvent = function() Fire("LOOT_CLOSED") end; Fire("LOOT_READY", true)
equal(#sent, 1, "synchronous loot close stops the burst immediately")
equal(loot.visit, nil, "closed loot keeps no active session")
Fresh(); actionEvent = function() Fire("LOOT_BIND_CONFIRM", 3) end; Fire("LOOT_READY", true)
equal(#sent, 1, "bind confirmation pauses the remaining burst")
Fire("LOOT_READY", true); equal(#sent, 1, "bind confirmation is never retried or accepted automatically")
Fresh(); Fire("LOOT_BIND_CONFIRM", 1); Fire("LOOT_READY", true)
equal(#sent, 0, "an already-pending bind confirmation prevents a pass")
Fresh(); queryEvent = function() Fire("LOOT_CLOSED") end; Fire("LOOT_READY", true)
equal(#sent, 0, "closing during a slot query cannot loot a stale slot")
Fresh(); actionEvent = function() Suite.db.quickLoot = false; loot:Apply() end; Fire("LOOT_READY", true)
equal(#sent, 1, "disable during the burst stops remaining requests")
equal(next(loot.events.registered), nil, "disable unregisters loot events")
Fresh(); actionEvent = function() Suite.db.quickLoot = false end; Fire("LOOT_READY", true)
equal(#sent, 1, "current preference is rechecked for every request")
Fresh(); actionEvent = function() Fire("PLAYER_ENTERING_WORLD") end; Fire("LOOT_READY", true)
equal(#sent, 1, "world changes cancel a running pass")
Fresh(); SetCombat(true); Fire("LOOT_READY", true)
equal(#sent, 3, "existing event frame can request ordinary auto-loot in combat without layout changes")
equal(constructed, 1, "combat loot constructs no extra frame")
SetCombat(false); Fire("LOOT_CLOSED"); loot:Apply()
equal(constructed, 1, "settings reapply reuses the existing event frame")
Fresh(); Suite.db.quickLoot = Secret(); Fire("LOOT_READY", true)
equal(#sent, 0, "restricted saved preference cannot enable a loot request")

local nativeLootSlot = LootSlot
Fresh(); LootSlot = nil; Fire("LOOT_READY", true)
equal(bulk, 1, "missing slot primitive uses the modern native loot-all service")
Fire("LOOT_READY", true); equal(bulk, 1, "native bulk fallback also requests once per session")
Fire("LOOT_CLOSED"); Fire("LOOT_READY", false); equal(bulk, 1, "bulk fallback respects manual loot")
LootSlot = nativeLootSlot
local nativeCount = GetNumLootItems
Fresh(); GetNumLootItems = nil; Fire("LOOT_READY", true)
equal(bulk, 1, "missing slot count uses native fallback without guessing a count")
GetNumLootItems = nativeCount
local nativeKind = GetLootSlotType
Fresh(); GetLootSlotType = nil; C_LootFrame = nil; Fire("LOOT_READY", true)
equal(#sent, 0, "missing slot and bulk APIs fail safely")
GetLootSlotType = nativeKind
Fire("LOOT_READY", true); equal(#sent, 3, "capabilities becoming available before a later ready event can act")

Fresh(); Suite.GUI:OpenPage("quests")
equal(Suite.GUI.tabs.quests.label.text, "Quests & Loot", "loot shares the journey settings group")
equal(Suite.GUI.rows[4].label.text, "Quick loot", "quick loot has a plainly named independent toggle")
equal(Suite.GUI.rows[4].help.text:find("modifier key", 1, true) ~= nil, true, "help explains native auto-loot modifier")
Suite.Apply = function() loot:Apply() end
Suite.GUI.rows[4].OnClick(); equal(Suite.db.quickLoot, false, "quick-loot switch saves the preference")
equal(Suite.db.autoQuestPickup, false, "loot switch leaves quest pickup off")
equal(Suite.db.autoQuestTurnIn, false, "loot switch leaves quest turn-in off")
equal(Suite.db.autoGossip, false, "loot switch leaves gossip off")
SlashCmdList.WOWFOREVERSUITE("loot"); equal(Suite.GUI.page, "quests", "loot shortcut opens the shared settings page")
equal(loot.visit, nil, "fully disabled loot retains no active session")
Suite.Apply = oldApply
Suite.db, Suite.pending = oldDB, oldPending
for _, name in ipairs(names) do _G[name] = saved[name] end
SetCombat(false)
