local Suite, equal, Frame, SetCombat = ...
local indicator = Suite.CombatIndicator
local oldDB, oldPending = Suite.db, Suite.pending
local oldCreate, oldTimer, oldParent, oldControl = CreateFrame, C_Timer, UIParent, IsControlKeyDown
SetCombat(false)
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
local created, geometry, timers, control = 0, 0, {}, false
UIParent = Frame(); UIParent:SetSize(1200, 800)
IsControlKeyDown = function() return control end
CreateFrame = function(kind, name, parent)
    assert(not InCombatLockdown(), "indicator creation must wait outside combat")
    created = created + 1
    local frame = Frame(name); frame.parent, frame.objectType = parent, kind
    frame.IsForbidden = function(self) return self.forbidden or false end
    frame.IsProtected = function(self) return self.protected or false end
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    for _, method in ipairs({ "SetPoint", "ClearAllPoints", "SetSize", "SetFrameStrata", "SetMovable", "EnableMouse", "StartMoving" }) do
        local original = frame[method]
        frame[method] = function(self, ...)
            assert(not InCombatLockdown(), "indicator geometry and input wait outside combat")
            geometry = geometry + 1; return original(self, ...)
        end
    end
    local show, hide, stop = frame.Show, frame.Hide, frame.StopMovingOrSizing
    frame.Show = function(self) assert(not InCombatLockdown() or self.protected == nil); return show(self) end
    frame.Hide = function(self) assert(not InCombatLockdown() or self.protected == nil); hide(self); if self.OnHide then self.OnHide(self) end end
    frame.StopMovingOrSizing = function(self) assert(not InCombatLockdown() or self.protected == nil); return stop(self) end
    return frame
end
C_Timer = { NewTimer = function(delay, callback)
    equal(delay, 4, "combat messages use four-second one-shot timers")
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
local function Expire()
    local timer = indicator.timer
    if timer then timer.callback() end
end
local function Resume()
    SetCombat(false)
    local pending = Suite.pending; Suite.pending = {}
    for _, callback in pairs(pending) do callback() end
end
local function Event(event) indicator.frame.OnEvent(indicator.frame, event) end

equal(Suite.db.combatIndicator, false, "combat indicator defaults off")
equal(Suite.db.combatIndicatorPersistent, false, "continuous combat display defaults off")
equal(Suite.db.combatIndicatorLocked, false, "indicator can be positioned before locking")
indicator:Apply()
equal(created, 0, "disabled indicator creates no frame")
equal(#timers, 0, "disabled indicator starts no worker")
SetCombat(true); Suite.db.combatIndicator = true; indicator:Apply()
equal(created, 0, "first enable during combat defers construction")
equal(type(Suite.pending.combatIndicator), "function", "first enable uses the core combat queue")
Suite.db.combatIndicator = false; indicator:Apply(); Resume()
equal(created, 0, "disable cancels deferred creation")
Suite.db.combatIndicator = true; indicator:Apply()
local frame = indicator.frame
equal(created, 1, "indicator uses one owned event/display frame")
equal(frame:GetParent(), UIParent, "indicator stays outside native secure HUD hierarchies")
equal(frame.name, nil, "indicator does not write a named global frame")
equal(frame:IsShown(), false, "enabling while idle does not invent a combat transition")
equal(frame.registered.PLAYER_REGEN_DISABLED, true, "enabled indicator watches combat entry")
equal(frame.OnUpdate, nil, "indicator has no per-frame worker")
equal(indicator.timer, nil, "idle indicator has no timer")
local geometryBefore = geometry
SetCombat(true); Event("PLAYER_REGEN_DISABLED")
equal(frame.title.text, "IN COMBAT", "combat entry displays the start message")
equal(frame.title.textColor[1], 1, "combat entry has gold text")
equal(frame:IsShown(), true, "prepared unprotected indicator can appear in combat")
equal(geometry, geometryBefore, "combat entry changes no geometry or input")
local first = indicator.timer
Event("PLAYER_REGEN_DISABLED")
equal(indicator.timer, first, "duplicate entry does not extend or cancel the alert")
Expire()
equal(frame:IsShown(), false, "brief entry alert expires during combat")
equal(indicator.timer, nil, "an expired entry retains no idle worker")
Resume(); Event("PLAYER_REGEN_ENABLED")
equal(frame.title.text, "COMBAT ENDED", "combat exit displays the end message")
equal(frame.title.textColor[2], 1, "combat exit has green text")
equal(frame:IsShown(), true, "exit notification appears after entry timeout")
local ended = indicator.timer
SetCombat(true); Event("PLAYER_REGEN_DISABLED")
ended.callback()
equal(frame.title.text, "IN COMBAT", "stale exit timer cannot erase a newer entry")
equal(frame:IsShown(), true, "rapid combat re-entry keeps the latest message")
Suite.db.combatIndicatorPersistent = true; indicator:Apply()
equal(indicator.timer, nil, "persistent mode removes the entry timeout")
equal(frame:IsShown(), true, "persistent mode stays visible during combat")
Suite.db.combatIndicatorPersistent = false; indicator:Apply()
equal(indicator.timer ~= nil, true, "turning persistence off restores a bounded entry alert")
Suite.db.combatIndicator = false; indicator:Apply()
equal(frame:IsShown(), false, "disable hides a prepared indicator even in combat")
equal(indicator.timer, nil, "disable cancels the alert timer")
equal(next(frame.registered), nil, "disabled indicator releases all events")
Resume()
Suite.db.combatIndicator = true; indicator:Apply()
Event("PLAYER_REGEN_ENABLED")
equal(frame:IsShown(), false, "fresh enable does not manufacture an exit message")
indicator:Preview()
equal(frame:IsShown(), true, "manual preview shows a movable sample")
equal(Suite.db.combatIndicator, true, "preview does not change enable preference")
frame.OnDragStart(frame)
equal(indicator.moving, true, "unlocked indicator drags outside combat")
equal(indicator.timer, nil, "dragging holds the short preview")
frame.centerX, frame.centerY = 900, 200
frame.OnDragStop(frame)
equal(Suite.db.combatIndicatorPosition.x, 0.25, "drag saves normalized horizontal position")
equal(Suite.db.combatIndicatorPosition.y, -0.25, "drag saves normalized vertical position")
equal(frame.point[4], 300, "saved position restores relative to the screen center")
equal(frame.point[5], -200, "saved position restores vertical placement")
frame.OnMouseUp(frame, "RightButton")
equal(Suite.db.combatIndicatorPosition.x, 0.25, "plain right-click preserves placement")
control = true; frame.OnMouseUp(frame, "RightButton"); control = false
equal(next(Suite.db.combatIndicatorPosition), nil, "Ctrl-right-click resets only indicator placement")
equal(frame.point[5], 220, "reset restores the above-center default")
frame.OnDragStart(frame)
Suite.db.combatIndicatorLocked = true; indicator:Apply(); indicator:Preview()
equal(frame.mouseEnabled, false, "lock makes the indicator click-through")
frame.OnDragStart(frame)
equal(indicator.moving, nil, "lock prevents movement")
equal(indicator.timer ~= nil, true, "locking after a drag leaves a bounded preview")
Suite.db.combatIndicatorLocked = false; indicator:Apply(); indicator:Preview()
Suite.db.combatIndicatorPosition = { x = 0.1, y = 0.2 }; indicator:Place()
frame.OnDragStart(frame)
geometryBefore = geometry
SetCombat(true); Event("PLAYER_REGEN_DISABLED")
equal(indicator.moving, nil, "combat interrupts an ordinary owned-frame drag immediately")
equal(Suite.db.combatIndicatorPosition.x, 0.1, "interrupted drag does not overwrite saved placement")
equal(geometry, geometryBefore, "interrupted drag restores no anchors during combat")
Resume(); Event("PLAYER_REGEN_ENABLED")
equal(frame.point[4], 120, "interrupted drag restores its saved anchor after combat")
Expire()
Suite.db.combatIndicatorPersistent = true; indicator:Apply()
SetCombat(true); Event("PLAYER_REGEN_DISABLED")
equal(indicator.timer, nil, "persistent entry has no recurring or expiry worker")
Resume(); Event("PLAYER_REGEN_ENABLED"); Expire()
equal(frame:IsShown(), false, "persistent mode still gives a bounded exit notification")
Event("PLAYER_LEAVING_WORLD"); Event("PLAYER_ENTERING_WORLD")
equal(frame:IsShown(), false, "ordinary zoning never invents combat notifications")
indicator:Preview(); Event("PLAYER_LEAVING_WORLD")
equal(indicator.preview, nil, "leaving the world cancels previews")
Event("PLAYER_ENTERING_WORLD")
SetCombat(true); Event("PLAYER_ENTERING_WORLD")
equal(frame.title.text, "IN COMBAT", "world entry in combat synchronizes current status")
Resume(); Event("PLAYER_REGEN_ENABLED"); Expire()
indicator:Preview(); indicator:StopPreview()
equal(frame:IsShown(), false, "leaving settings cancels its sample")
Suite.db.combatIndicator = false; indicator:Apply(); indicator:Preview()
equal(frame:IsShown(), true, "preview is available with the live feature disabled")
Expire()
equal(next(frame.registered), nil, "disabled preview releases temporary events on expiry")
equal(Suite.db.combatIndicator, false, "disabled preview never enables live notifications")
Suite.db.combatIndicator = true; indicator:Apply()
SetCombat(true); frame.protected = { secret = true }; Event("PLAYER_REGEN_DISABLED")
equal(frame:IsShown(), false, "unknown protection suppresses in-combat presentation")
frame.protected = nil; Resume()
Event("PLAYER_REGEN_ENABLED"); Expire()
local savedTimerAPI = C_Timer; C_Timer = nil
SetCombat(true); Event("PLAYER_REGEN_DISABLED")
Resume(); Event("PLAYER_REGEN_ENABLED")
equal(frame:IsShown(), false, "missing timer support cannot leave an unbounded brief alert")
C_Timer = savedTimerAPI
indicator:Preview(); Event("PLAYER_LOGOUT")
equal(indicator.timer, nil, "logout cancels pending display work")
equal(next(frame.registered), nil, "logout releases all feature events")
for _, saved in ipairs({ { x = math.huge, y = 0 }, { x = 0/0, y = 0 }, { x = 0.6, y = 0 },
    { x = { secret = true }, y = 0 }, { secret = true } }) do
    equal(next(indicator:InitializePosition(saved)), nil, "malformed or restricted saved placement is rejected")
end
local clean = indicator:InitializePosition({ x = 0.2, y = -0.1, extra = "discard" })
equal(clean.x, 0.2, "valid normalized placement survives initialization")
equal(clean.extra, nil, "placement initialization strips unrelated fields")
Suite.db.combatIndicator = false; indicator:Apply()
local gui = Suite.GUI
local oldPage, oldShown = gui.page, gui.frame:IsShown()
gui.frame:Show(); gui:Select("combat")
equal(gui.page, "combat", "Combat settings are directly accessible")
equal(Suite.SettingsCatalog:Search("entering leaving combat")[1].key, "combatIndicator", "search discovers combat transition alerts")
gui.rows[4].OnClick()
equal(indicator.preview, true, "settings preview action reaches the indicator")
gui:Select("overview")
equal(indicator.preview, nil, "page navigation ends the preview")
gui:Select("combat"); gui.rows[4].OnClick()
gui.frame.OnHide(gui.frame)
equal(indicator.preview, nil, "closing settings ends the preview")
gui:Select(oldPage); gui.frame:SetShown(oldShown)
Suite.db, Suite.pending = oldDB, oldPending
CreateFrame, C_Timer, UIParent, IsControlKeyDown = oldCreate, oldTimer, oldParent, oldControl
SetCombat(false)
