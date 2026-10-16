local Suite, equal, Frame, SetCombat = ...
local sorter = Suite.BagSort
local names = { "CreateFrame", "C_Timer", "C_Container", "EventRegistry", "CursorHasItem",
    "NUM_TOTAL_EQUIPPED_BAG_SLOTS", "NUM_CONTAINER_FRAMES", "ContainerFrameCombinedBags" }
for index = 1, 6 do names[#names + 1] = "ContainerFrame" .. index end
local saved = {}
for _, name in ipairs(names) do saved[name] = _G[name] end
local oldDB, oldPending, oldApply = Suite.db, Suite.pending, Suite.Apply
local timers, callbacks, requests, constructed, held = {}, {}, 0, 0, false
local duringSort, duringCursor
local function Secret() return { secret = true } end
local function Bag(id)
    local frame = Frame()
    frame.bagID, frame.shown = id, false
    frame.GetBagID = function(self) return self.bagID end
    return frame
end
local bags = {}
for index = 1, 6 do bags[index] = Bag(index - 1); _G["ContainerFrame" .. index] = bags[index] end
ContainerFrameCombinedBags = Bag(0)
NUM_CONTAINER_FRAMES, NUM_TOTAL_EQUIPPED_BAG_SLOTS = 6, 5
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
equal(Suite.db.sortBagsOnOpen, false, "bag sorting starts off")
equal(Suite.InitializeDB({ sortBagsOnOpen = true }).sortBagsOnOpen, true, "sort preference persists")
CreateFrame = function(...)
    assert(not InCombatLockdown(), "bag-sort event frame must be constructed outside combat")
    constructed = constructed + 1
    local frame = saved.CreateFrame(...)
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    return frame
end
EventRegistry = {
    RegisterCallback = function(_, event, callback, owner)
        assert(not InCombatLockdown(), "first bag callback registration waits through combat")
        callbacks[event] = { callback = callback, owner = owner }
    end,
    UnregisterCallback = function(_, event, owner)
        if callbacks[event] and callbacks[event].owner == owner then callbacks[event] = nil end
    end,
}
C_Timer = { NewTimer = function(delay, callback)
    equal(delay, 0, "bag sort waits only for the current native opening pass")
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end, After = function() error("bag sorting requires cancellable work") end }
C_Container = { SortBags = function()
    assert(not InCombatLockdown(), "bag sorting waits through combat")
    requests = requests + 1
    if duringSort then duringSort() end
end, SortBankBags = function() error("carried bag sorting must not sort bank bags") end,
    SortAccountBankBags = function() error("carried bag sorting must not sort account bank") end,
    SetBagSlotFlag = function() error("native bag exclusions must stay unchanged") end,
    SetSortBagsRightToLeft = function() error("native sort direction must stay unchanged") end }
CursorHasItem = function() if duringCursor then duringCursor() end; return held end
local function Native(event, frame)
    local entry = callbacks[event]
    if entry then entry.callback(entry.owner, frame) end
end
local function Open(frame) frame.shown = true; Native("ContainerFrame.OpenBag", frame) end
local function Close(frame) frame.shown = false; Native("ContainerFrame.CloseBag", frame) end
local function Fire(event)
    if sorter.events and sorter.events.registered[event] then sorter.events.OnEvent(sorter.events, event) end
end
local function Flush()
    local pending = timers; timers = {}
    for _, timer in ipairs(pending) do if not timer.cancelled then timer.callback() end end
end
local function Fresh()
    Suite.db.sortBagsOnOpen = false; sorter:Apply()
    for _, bag in ipairs(bags) do bag.shown = false end
    ContainerFrameCombinedBags.shown = false
    requests, timers, held, duringSort, duringCursor = 0, {}, false, nil, nil
    Suite.db.sortBagsOnOpen = true; sorter:Apply()
end

sorter:Apply(); equal(constructed, 0, "disabled bag sorting creates no event frame")
equal(next(callbacks), nil, "disabled bag sorting registers no native callbacks")
SetCombat(true); Suite.db.sortBagsOnOpen = true; sorter:Apply()
equal(constructed, 0, "enable in combat defers event-frame construction")
equal(type(Suite.pending.bagSort), "function", "combat enable queues activation")
Suite.db.sortBagsOnOpen = false; sorter:Apply()
equal(Suite.pending.bagSort, nil, "disable cancels combat activation")
SetCombat(false); Fresh(); equal(constructed, 1, "bag sorting uses one anonymous event frame")
Open(bags[1]); Open(bags[2]); Open(bags[6])
equal(#timers, 1, "numbered and reagent bags opening together coalesce")
equal(requests, 0, "sort waits until the native opening pass finishes")
Flush(); equal(requests, 1, "all carried bags get one native sort request")
Native("ContainerFrame.OpenBag", bags[1]); sorter:Apply(); Fire("BAG_UPDATE"); Flush()
equal(requests, 1, "duplicate opens, unrelated settings and bag updates do not sort again")
equal(sorter.events.registered.BAG_UPDATE, nil, "sorting does not subscribe to its own bag updates")
equal(sorter.events.OnUpdate, nil, "bag sorting has no idle updater")
Close(bags[1]); Close(bags[2]); equal(sorter.visit ~= nil, true, "remaining reagent bag retains the visit")
Close(bags[6]); equal(sorter.visit, nil, "last carried bag closing clears the visit")
Open(bags[1]); Flush(); equal(requests, 2, "reopening starts a new sort pass")
Fresh(); Open(ContainerFrameCombinedBags); Flush()
equal(requests, 1, "combined bag opening uses the same native sort")
Close(ContainerFrameCombinedBags); Open(ContainerFrameCombinedBags); Flush()
equal(requests, 2, "combined bag reopens get a new pass")
Fresh(); local bank = Bag(6); local keyring = Bag(-2)
Open(bank); Open(keyring); Flush(); equal(requests, 0, "bank and keyring-only opening does not sort carried bags")
equal(sorter.visit, nil, "bank and keyring create no carried-bag visit")
Open(bags[3]); Flush(); equal(requests, 1, "an individual carried bag opening sorts once")
Fresh(); Open(bags[1]); local stale = timers[1]; Close(bags[1])
equal(stale.cancelled, true, "close before work cancels the pending sort")
Open(bags[1]); stale.callback(); equal(requests, 0, "stale cancelled callback cannot sort the reopened visit")
Flush(); equal(requests, 1, "reopened visit keeps its own queued pass")
Fresh(); Open(bags[1]); Suite.db.sortBagsOnOpen = false; sorter:Apply(); Flush()
equal(requests, 0, "disable cancels pending sort")
equal(next(callbacks), nil, "disable removes both native callbacks")
equal(next(sorter.events.registered), nil, "disable unregisters engine events")
Fresh(); Open(bags[1]); Fire("PLAYER_ENTERING_WORLD"); Flush()
equal(requests, 0, "world change cancels stale work")
equal(sorter.visit, nil, "world change releases frame records")
Fresh(); SetCombat(true); Fire("PLAYER_REGEN_DISABLED"); Open(bags[1])
equal(#timers, 0, "combat opening schedules no sort timer")
SetCombat(false); Fire("PLAYER_REGEN_ENABLED"); Flush()
equal(requests, 1, "still-open bags sort once when combat ends")
Fresh(); Open(bags[1]); SetCombat(true); Fire("PLAYER_REGEN_DISABLED"); Flush()
equal(requests, 0, "entering combat cancels an already queued sort")
Close(bags[1]); SetCombat(false); Fire("PLAYER_REGEN_ENABLED"); Flush()
equal(requests, 0, "closed combat bags never replay")
Fresh(); Open(bags[1]); SetCombat(true); Flush(); equal(requests, 0, "worker also checks combat before sorting")
SetCombat(false); Fire("PLAYER_REGEN_ENABLED"); Flush(); equal(requests, 1, "combat worker retains one pending visit")
for _, value in ipairs({ true, Secret(), 1 }) do
    Fresh(); held = value; Open(bags[1]); Flush(); equal(requests, 0, "held or unknown cursor item skips sorting")
    held = false; Native("ContainerFrame.OpenBag", bags[1]); Flush()
    equal(requests, 0, "cursor skip is not retried during the same opening")
    Close(bags[1]); Open(bags[1]); Flush(); equal(requests, 1, "next opening after cursor clears can sort")
end
Fresh(); held = nil; Open(bags[1]); Flush(); equal(requests, 0, "missing cursor result leaves items alone")
Fresh(); duringSort = function() Native("ContainerFrame.OpenBag", bags[1]); Fire("BAG_UPDATE") end
Open(bags[1]); Flush(); Flush(); equal(requests, 1, "synchronous native sort callbacks cannot repeat a pass")
Fresh(); duringCursor = function() Close(bags[1]) end; Open(bags[1]); Flush()
equal(requests, 0, "close during cursor query prevents a stale action")
Fresh(); duringCursor = function() Suite.db.sortBagsOnOpen = false; sorter:Apply() end; Open(bags[1]); Flush()
equal(requests, 0, "disable during cursor query prevents a stale action")
Fresh(); Open(bags[1]); Suite.db.sortBagsOnOpen = Secret(); Flush()
equal(requests, 0, "restricted saved preference cannot trigger sorting")
Fresh(); bags[1].bagID = Secret(); Open(bags[1]); Flush(); equal(requests, 0, "restricted bag ID is not compared")
bags[1].bagID = 0
Fresh(); bags[1].IsShown = function() return Secret() end; Open(bags[1]); Flush()
equal(requests, 0, "restricted visibility cannot trigger a sort")
bags[1].IsShown = function(self) return self.shown end
Fresh(); bags[1].IsForbidden = function() return true end; Open(bags[1]); Flush()
equal(requests, 0, "forbidden bag frame is left alone")
bags[1].IsForbidden = function() return false end
Fresh(); Native("ContainerFrame.OpenBag", Secret()); Native("ContainerFrame.CloseBag", Secret()); Flush()
equal(requests, 0, "restricted frame records are never used as keys")
Fresh(); NUM_TOTAL_EQUIPPED_BAG_SLOTS = Secret(); Open(bags[2]); Flush()
equal(requests, 0, "restricted bag limit cannot admit a carried ID")
Open(bags[1]); Flush(); equal(requests, 1, "known backpack remains independently available")
NUM_TOTAL_EQUIPPED_BAG_SLOTS = 5
Fresh(); local nativeSort = C_Container.SortBags; C_Container.SortBags = nil; Open(bags[1]); Flush()
equal(requests, 0, "missing native sort API fails safely")
C_Container.SortBags = nativeSort
Fresh(); CursorHasItem = nil; Open(bags[1]); Flush(); equal(requests, 0, "missing cursor predicate leaves items alone")
CursorHasItem = function() return held end
Suite.db.sortBagsOnOpen = false; sorter:Apply(); bags[1].shown = true
Suite.db.sortBagsOnOpen = true; sorter:Apply(); Open(bags[2]); Flush()
equal(requests, 0, "enable with already-open bags waits for a fresh opening")
Close(bags[1]); Close(bags[2]); Open(bags[1]); Flush(); equal(requests, 1, "closing preexisting bags arms the next opening")
equal(constructed, 1, "all enable cycles reuse one event frame")

Fresh(); Suite.GUI:OpenPage("bags")
equal(Suite.GUI.page, "bags", "bags shortcut opens the dedicated Bags & bank settings")
equal(Suite.GUI.rows[1].label.text, "Sort bags on opening", "bag sorting has a clear independent switch")
equal(Suite.db.windowTools, false, "sorting works with window movement disabled")
Suite.Apply = function() sorter:Apply() end
Suite.GUI.rows[1].OnClick(); equal(Suite.db.sortBagsOnOpen, false, "bag-sort toggle saves disabling")
equal(Suite.db.windowTools, false, "bag-sort toggle leaves window movement unchanged")
equal(Suite.db.offlineBank, false, "bag-sort toggle leaves bank snapshots unchanged")
SlashCmdList.WOWFOREVERSUITE("bags"); equal(Suite.GUI.page, "bags", "slash bags opens the correct settings page")
Suite.Apply = oldApply
Suite.db.sortBagsOnOpen = false; sorter:Apply()
Suite.db, Suite.pending = oldDB, oldPending
for _, name in ipairs(names) do _G[name] = saved[name] end
SetCombat(false)
