local Suite, equal, Frame, SetCombat = ...
local module = Suite.ActionBars
local oldCreate, oldTimers, oldHook = CreateFrame, C_Timer, hooksecurefunc
local oldActionAPI, oldRange, oldPetInfo, oldSet = C_ActionBar, ActionButton_UpdateRangeIndicator, GetPetActionInfo, Suite.Set
local oldPending, oldPreference = Suite.pending, Suite.db.fullButtonRange
local names = { "ActionButton1", "ActionButton2", "MultiBar7Button12", "PetActionButton1", "ExtraActionButton1", "OverrideActionBarButton6" }
local previous = {}
for _, name in ipairs(names) do previous[name] = _G[name]; _G[name] = nil end
local timers, constructed, hooks, queries, nativeRanges, inCombat = {}, 0, 0, 0, 0, false
local secret = { secret = true }
local slots = { [1] = { range = false }, [2] = { range = true }, [3] = { range = false } }
local petChecks, petRange = true, false
local function Combat(value) inCombat = value; SetCombat(value) end
local function Flush()
    local ready = timers; timers = {}
    for _, timer in ipairs(ready) do if not timer.cancelled then timer.callback() end end
end
local function LeaveCombat()
    Combat(false)
    local pending = Suite.pending; Suite.pending = {}
    for _, callback in pairs(pending) do callback() end
end
local function TimerCount()
    local count = 0
    for _, timer in ipairs(timers) do if not timer.cancelled then count = count + 1 end end
    return count
end
CreateFrame = function(...)
    assert(not inCombat, "range indicator must not create frames in combat")
    constructed = constructed + 1
    local frame = oldCreate(...)
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    return frame
end
hooksecurefunc = function(...)
    assert(not inCombat, "range hooks install outside combat")
    hooks = hooks + 1
    return oldHook(...)
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
C_ActionBar = {
    HasAction = function(slot)
        assert(type(slot) == "number" and slots[slot], "query only a valid readable action slot")
        queries = queries + 1
        return slots[slot].hasAction == nil and true or slots[slot].hasAction
    end,
    IsActionInRange = function(slot)
        queries = queries + 1
        return slots[slot].range
    end,
    EnableActionRangeCheck = function() error("Suite must not take ownership of Blizzard's range service") end,
}
ActionButton_UpdateRangeIndicator = function(button, checksRange, inRange)
    nativeRanges = nativeRanges + 1
    button.nativeRange = { checksRange, inRange }
end
GetPetActionInfo = function(slot)
    equal(slot, 1, "pet range uses the native pet slot")
    return "Bite", 123, false, false, true, false, 100, petChecks, petRange
end
local function Button(action, base)
    local button = Frame()
    button.action, button.shown = action, true
    button.icon = Frame()
    button.icon.vertex = base or { 1, 1, 1, 1 }
    button.icon.GetVertexColor = function(self) return unpack(self.vertex) end
    button.icon.SetVertexColor = function(self, r, g, b, a) self.vertex = { r, g, b, a or 1 } end
    button.Update = function(self) self.icon:SetVertexColor(unpack(self.nativeColor or { 1, 1, 1, 1 })) end
    button.UpdateButtonState = button.Update
    button.IsForbidden = function(self) return self.forbidden == true end
    for _, name in ipairs({ "SetPoint", "SetScale", "SetAttribute", "SetParent", "SetSize" }) do
        button[name] = function() error("range presentation must not mutate protected button configuration") end
    end
    return button
end
local function Color(button, r, g, b, label, a)
    equal(button.icon.vertex[1], r, label .. " red")
    equal(button.icon.vertex[2], g, label .. " green")
    equal(button.icon.vertex[3], b, label .. " blue")
    equal(button.icon.vertex[4], a or 1, label .. " alpha")
end
Suite.pending = {}
Combat(false)
equal(Suite.db.fullButtonRange, false, "full button range starts off")
module:Apply()
equal(constructed, 0, "disabled range feature creates no frames")
equal(hooks, 0, "disabled range feature installs no hooks")
equal(TimerCount(), 0, "disabled range feature creates no timers")

ActionButton1 = Button(1, { 0.4, 0.4, 0.4, 0.8 })
ActionButton2 = Button(2)
MultiBar7Button12 = Button(1)
PetActionButton1 = Button(nil)
OverrideActionBarButton6 = Button(1)
Suite.db.fullButtonRange = true
Combat(true)
module:Apply()
equal(hooks, 0, "first enable in combat defers native hook installation")
equal(constructed, 0, "first enable in combat defers event-frame creation")
Suite.db.fullButtonRange = false
module:Apply()
LeaveCombat()
equal(hooks, 0, "disable cancels the deferred enable")
Suite.db.fullButtonRange = true
module:Apply()
equal(constructed, 1, "enabled range feature creates only one event frame")
equal(module.events.registered.ADDON_LOADED, true, "late native action bars can be discovered")
Color(ActionButton1, 1, 0.15, 0.15, "initial out-of-range icon", 0.8)
Color(ActionButton2, 1, 1, 1, "in-range icon stays native")
Color(MultiBar7Button12, 1, 0.15, 0.15, "last extra bar button supported")
Color(PetActionButton1, 1, 0.15, 0.15, "native pet range supported")
Color(OverrideActionBarButton6, 1, 0.15, 0.15, "override bar supported")
equal(ActionButton1.OnUpdate, nil, "action buttons acquire no polling updater")
equal(module.events.OnUpdate, nil, "range controller has no polling updater")
equal(TimerCount(), 0, "initial range refresh leaves no timer")
local beforeHooks = hooks
module:Apply()
equal(hooks, beforeHooks, "reapplying settings never duplicates hooks")

ActionButton1.icon:SetVertexColor(0.5, 0.5, 1)
Color(ActionButton1, 1, 0.15, 0.15, "out-of-range survives native mana recolor")
ActionButton_UpdateRangeIndicator(ActionButton1, true, true)
Color(ActionButton1, 0.5, 0.5, 1, "returning in range restores latest mana color")
equal(nativeRanges, 1, "range callback preserves Blizzard's original handler")
ActionButton_UpdateRangeIndicator(ActionButton1, true, false)
ActionButton_UpdateRangeIndicator(ActionButton1, false, false)
Color(ActionButton1, 0.5, 0.5, 1, "unchecked range restores native color")
ActionButton_UpdateRangeIndicator(ActionButton1, true, false)
ActionButton_UpdateRangeIndicator(ActionButton1, true, nil)
Color(ActionButton1, 0.5, 0.5, 1, "unknown range never counts as out of range")
ActionButton_UpdateRangeIndicator(ActionButton1, true, false)
ActionButton_UpdateRangeIndicator(ActionButton1, secret, false)
Color(ActionButton1, 0.5, 0.5, 1, "secret range applicability clears tint")
ActionButton_UpdateRangeIndicator(ActionButton1, true, false)
ActionButton_UpdateRangeIndicator(ActionButton1, true, secret)
Color(ActionButton1, 0.5, 0.5, 1, "secret range result clears tint")
ActionButton_UpdateRangeIndicator(secret, true, false)
equal(module.records[secret], nil, "secret button handle is never used as a key")

slots[2].range = false
ActionButton1.action, ActionButton1.nativeColor = 2, { 0.4, 0.4, 0.4, 1 }
ActionButton1:Update()
Color(ActionButton1, 1, 0.15, 0.15, "button update queries current paged slot")
slots[2].range = true
ActionButton1:Update()
Color(ActionButton1, 0.4, 0.4, 0.4, "new in-range action restores unusable color")
slots[2].range = nil
ActionButton1:Update()
Color(ActionButton1, 0.4, 0.4, 0.4, "no target leaves native usability color")
slots[2].range = false
slots[2].hasAction = false
ActionButton1:Update()
Color(ActionButton1, 0.4, 0.4, 0.4, "empty slot clears old tint")
slots[2].hasAction = secret
local beforeQueries = queries
ActionButton1:Update()
equal(queries, beforeQueries + 1, "secret action presence never reaches range query")
slots[2].hasAction = true
ActionButton1.action = secret
beforeQueries = queries
ActionButton1:Update()
equal(queries, beforeQueries, "secret action index never reaches API query")
for _, invalid in ipairs({ 0, -1, 1.5, math.huge, 0 / 0 }) do
    ActionButton1.action = invalid
    ActionButton1:Update()
end
equal(queries, beforeQueries, "invalid and nonfinite action indices never reach API query")
ActionButton1.action = 1

ActionButton_UpdateRangeIndicator(ActionButton1, true, false)
ActionButton1:Hide(); ActionButton1.OnHide(ActionButton1)
Color(ActionButton1, 0.4, 0.4, 0.4, "hidden button clears tint")
ActionButton_UpdateRangeIndicator(ActionButton1, true, false)
Color(ActionButton1, 0.4, 0.4, 0.4, "range callback does not retint hidden buttons")
ActionButton1:Show(); ActionButton1.OnShow(ActionButton1)
Color(ActionButton1, 1, 0.15, 0.15, "reshown button reads current range")
ActionButton1.forbidden = true
beforeQueries = queries
ActionButton1:Update()
equal(queries, beforeQueries, "forbidden button is not queried")
ActionButton1.forbidden = false
ActionButton1:Update()

ActionButton1.icon:SetVertexColor(secret, 0.5, 1)
equal(ActionButton1.icon.vertex[1], secret, "secret native color remains on its native path")
equal(module.records[ActionButton1].tinted, nil, "restricted color is never overridden or cached")
ActionButton_UpdateRangeIndicator(ActionButton1, true, false)
equal(ActionButton1.icon.vertex[1], secret, "secret color readback cannot be used to build a tint")
ActionButton1.icon:SetVertexColor(0.5, 0.5, 1)
Color(ActionButton1, 1, 0.15, 0.15, "readable native color resumes tint")

Combat(true)
beforeHooks = hooks
ActionButton_UpdateRangeIndicator(ActionButton1, true, true)
Color(ActionButton1, 0.5, 0.5, 1, "combat range clears through cosmetic setter")
ActionButton_UpdateRangeIndicator(ActionButton1, true, false)
Color(ActionButton1, 1, 0.15, 0.15, "combat range paints full icon")
ActionButton1.icon:SetVertexColor(0.4, 0.4, 0.4)
Color(ActionButton1, 1, 0.15, 0.15, "combat usability update keeps range red")
Suite.db.fullButtonRange = false
module:Apply()
Color(ActionButton1, 0.4, 0.4, 0.4, "disable in combat immediately restores native color")
equal(next(module.events.registered), nil, "disable unregisters all feature events")
equal(TimerCount(), 0, "disable leaves no timer")
beforeQueries = queries
ActionButton1:Update()
ActionButton_UpdateRangeIndicator(ActionButton1, true, false)
equal(queries, beforeQueries, "disabled retained hooks perform no range queries")
Color(ActionButton1, 0.4, 0.4, 0.4, "disabled retained hooks never tint")
equal(hooks, beforeHooks, "combat changes install no new hooks")
LeaveCombat()

Suite.db.fullButtonRange = true
module:Apply()
ExtraActionButton1 = Button(3)
for _ = 1, 200 do module.events.OnEvent(module.events, "ADDON_LOADED") end
equal(TimerCount(), 1, "addon discovery bursts coalesce to one timer")
Combat(true)
module.events.OnEvent(module.events, "PLAYER_REGEN_DISABLED")
equal(TimerCount(), 0, "combat entry cancels pending discovery timer")
equal(type(Suite.pending.actionBars), "function", "combat discovery uses one deferred callback")
for _ = 1, 200 do module.events.OnEvent(module.events, "ADDON_LOADED") end
equal(TimerCount(), 0, "combat discovery bursts create no timers")
LeaveCombat()
Color(ExtraActionButton1, 1, 0.15, 0.15, "late extra action discovered after combat")
equal(TimerCount(), 0, "deferred discovery creates no recurring timer")
module.events.OnEvent(module.events, "ADDON_LOADED")
Suite.db.fullButtonRange = false
module:Apply(); Flush()
Color(ExtraActionButton1, 1, 1, 1, "disable cancels pending work and restores late buttons")
equal(Suite.pending.actionBars, nil, "disable clears deferred discovery")

Suite.db.fullButtonRange = true
local savedQuery = C_ActionBar.IsActionInRange
C_ActionBar.IsActionInRange = nil
module:Apply()
Color(ActionButton1, 0.4, 0.4, 0.4, "missing range capability leaves native action colors")
C_ActionBar.IsActionInRange = savedQuery
petChecks, petRange = false, false
PetActionButton1:UpdateButtonState()
Color(PetActionButton1, 1, 1, 1, "pet action without range stays native")
petChecks, petRange = true, secret
PetActionButton1:UpdateButtonState()
Color(PetActionButton1, 1, 1, 1, "secret pet range stays native")
petRange = false
PetActionButton1:UpdateButtonState()
Color(PetActionButton1, 1, 0.15, 0.15, "pet update follows native range tuple")

Suite.Set = function(key, value)
    equal(key, "fullButtonRange", "GUI control edits only the independent range preference")
    Suite.db[key] = value
    module:Apply()
end
Suite.GUI:OpenPage("actionbars")
equal(Suite.GUI.page, "actionbars", "direct shortcut opens action bar settings")
equal(Suite.GUI.tabs.actionbars.label.text, "Action Bars", "new sidebar entry is visible")
equal(Suite.GUI.rows[1].label.text, "Full button range indicator", "range control has clear wording")
Suite.GUI.rows[1].OnClick()
equal(Suite.db.fullButtonRange, false, "range settings switch disables feature")
Color(PetActionButton1, 1, 1, 1, "GUI disable restores pet icon")
Suite.GUI.rows[1].OnClick()
equal(Suite.db.fullButtonRange, true, "range settings switch enables feature")

Suite.db.fullButtonRange = false
module:Apply()
CreateFrame, C_Timer, hooksecurefunc = oldCreate, oldTimers, oldHook
C_ActionBar, ActionButton_UpdateRangeIndicator, GetPetActionInfo, Suite.Set = oldActionAPI, oldRange, oldPetInfo, oldSet
Suite.pending, Suite.db.fullButtonRange = oldPending, oldPreference
for _, name in ipairs(names) do _G[name] = previous[name] end
Combat(false)
