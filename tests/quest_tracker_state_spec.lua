local Suite, equal, Frame, SetCombat = ...
local state = Suite.QuestTrackerState
local saved = { db = Suite.db, char = WoWForeverSuiteCharDB, tracker = ObjectiveTrackerFrame,
    timer = C_Timer, pending = Suite.pending }
local timers, writes = {}, 0
Suite.db, Suite.pending, WoWForeverSuiteCharDB = Suite.InitializeDB(nil), {}, {}
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
local function Flush()
    local work = timers; timers = {}
    for _, timer in ipairs(work) do if not timer.cancelled then timer.callback() end end
end
local combat = false
local function Combat(value) combat = value; SetCombat(value) end
local function LeaveCombat()
    Combat(false)
    local pending = Suite.pending; Suite.pending = {}
    for _, callback in pairs(pending) do callback() end
end
local function Tracker(collapsed)
    local tracker = Frame()
    tracker.collapsed = collapsed
    tracker.IsForbidden = function(self) return self.forbidden or false end
    tracker.IsCollapsed = function(self) return self.collapsed end
    tracker.Update = function() end
    tracker.SetCollapsed = function(self, value)
        assert(not combat, "restoration must wait for combat")
        writes = writes + 1; self.collapsed = value; self:Update()
    end
    tracker.Header = Frame()
    tracker.Header.MinimizeButton = Frame()
    tracker.Header.MinimizeButton:SetScript("OnClick", function()
        tracker.collapsed = not tracker.collapsed
        tracker:Update()
    end)
    return tracker
end
ObjectiveTrackerFrame = Tracker(false)
state:Apply()
equal(state.events, nil, "disabled persistence creates no controller")
equal(WoWForeverSuiteCharDB.questTrackerCollapsed, nil, "disabled persistence does not save")
Suite.db.questTrackerRemember = true
state:Apply()
equal(WoWForeverSuiteCharDB.questTrackerCollapsed, false, "first enable retains expanded state")
local tracker = ObjectiveTrackerFrame
local button = tracker.Header.MinimizeButton
button:OnClick()
equal(WoWForeverSuiteCharDB.questTrackerCollapsed, true, "native minimize click saves immediately")
tracker:SetCollapsed(false)
tracker:SetCollapsed(false)
Flush()
equal(tracker.collapsed, true, "automatic expansion restores saved collapse")
equal(WoWForeverSuiteCharDB.questTrackerCollapsed, true, "automatic expansion never overwrites choice")
equal(#timers, 0, "restoring state does not start a timer loop")
button:OnClick()
equal(WoWForeverSuiteCharDB.questTrackerCollapsed, false, "deliberate expansion saves false")
tracker:SetCollapsed(true); Flush()
equal(tracker.collapsed, false, "expanded choice is restored too")
button:OnClick()
tracker:SetCollapsed(false)
button:OnClick() -- Deliberately collapse the currently expanded tracker.
Flush()
equal(tracker.collapsed, true, "new click wins over queued restoration")
-- A reload creates new native frames; character SavedVariables survive.
ObjectiveTrackerFrame = Tracker(false)
state:Apply()
equal(ObjectiveTrackerFrame.collapsed, true, "reload restores per-character collapse")
tracker = ObjectiveTrackerFrame
tracker.collapsed = false
state.events:OnEvent("PLAYER_ENTERING_WORLD"); Flush()
equal(tracker.collapsed, true, "loading-screen event repairs reset state")
tracker.collapsed = false; tracker:Update(); Flush()
equal(tracker.collapsed, true, "later native update repairs direct reset")
Combat(true)
tracker.collapsed = false; tracker:Update(); Flush()
equal(tracker.collapsed, false, "combat leaves native layout alone")
equal(type(Suite.pending.questTrackerState), "function", "combat queues one restoration")
LeaveCombat()
equal(tracker.collapsed, true, "combat end restores latest choice")
Combat(true)
tracker.collapsed = false; tracker:Update()
Suite.db.questTrackerRemember = false; state:Apply()
equal(Suite.pending.questTrackerState, nil, "disable clears deferred work")
LeaveCombat(); Flush()
equal(tracker.collapsed, false, "disabled restoration stays inactive")
tracker.Header.MinimizeButton:OnClick()
equal(WoWForeverSuiteCharDB.questTrackerCollapsed, true, "disabled click does not change saved state")
tracker.Header.MinimizeButton:OnClick()
equal(WoWForeverSuiteCharDB.questTrackerCollapsed, true, "disabled expansion does not replace saved collapse")
WoWForeverSuiteCharDB = { questTrackerCollapsed = false }
Suite.db.questTrackerRemember = true; state:Apply()
equal(tracker.collapsed, false, "another character restores its own expanded choice")
local secret = { secret = true }
WoWForeverSuiteCharDB.questTrackerCollapsed = secret
tracker.collapsed = true
state:Refresh()
equal(WoWForeverSuiteCharDB.questTrackerCollapsed, true, "unreadable saved choice initializes from readable native state")
WoWForeverSuiteCharDB.questTrackerCollapsed = false
tracker.collapsed = secret
local before = writes
state:Refresh()
equal(writes, before, "secret collapse state is never compared or restored")
tracker.collapsed, tracker.forbidden = true, true
state:Refresh()
equal(writes, before, "forbidden tracker is untouched")
tracker.forbidden = false
ObjectiveTrackerFrame = nil
state:Refresh()
ObjectiveTrackerFrame = Tracker(true)
state.events:OnEvent("ADDON_LOADED"); Flush()
equal(ObjectiveTrackerFrame.collapsed, false, "late tracker availability restores choice")
Suite.db.questTrackerRemember = false; state:Apply()
Combat(true)
Suite.db.questTrackerRemember = true; state:Apply()
equal(type(Suite.pending.questTrackerState), "function", "enabling in combat defers setup")
LeaveCombat()
equal(ObjectiveTrackerFrame.collapsed, false, "combat-deferred enable preserves choice")
Suite.db.questTrackerRemember = false; state:Apply(); Flush()
Suite.db, Suite.pending, WoWForeverSuiteCharDB = saved.db, saved.pending, saved.char
ObjectiveTrackerFrame, C_Timer = saved.tracker, saved.timer
Combat(false)
