local Suite, equal, Frame, SetCombat = ...
local alerts = Suite.ProcAlerts
local oldDB, oldPending = Suite.db, Suite.pending
local oldCreate, oldSpell, oldBook, oldOverlay, oldTimer = CreateFrame, C_Spell, C_SpellBook, C_SpellActivationOverlay, C_Timer
local oldSecret = issecretvalue
local oldGetTime = GetTime
local now = 100
GetTime = function() return now end
local oldTexture = C_Texture
C_Texture = { GetAtlasInfo = function() return { width = 512, height = 512 } end }
local secret = {}; issecretvalue = function(value) return value == secret end
local known, usable, cooldowns, glows, infos, timers, power = {}, {}, {}, {}, {}, {}, {}
local created = 0
SetCombat(false); Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
CreateFrame = function(kind, name, parent)
    assert(not InCombatLockdown(), "proc widgets must be created before combat")
    created = created + 1
    local frame = Frame(name); frame.parent = parent
    local createTexture = frame.CreateTexture
    frame.CreateTexture = function(self, ...)
        local texture = createTexture(self, ...)
        texture.SetTexCoord = function() end
        texture.SetAtlas = function(self, atlas) self.atlas = atlas end
        texture.SetVertexColor = function(self, r, g, b) self.tint = { r, g, b } end
        texture.CreateAnimationGroup = function()
            assert(not InCombatLockdown(), "glow animations must be prepared outside combat")
            local group = {
                plays = 0, stops = 0,
                SetLooping = function(self, value) self.looping = value end,
                Play = function(self) self.plays = self.plays + 1; self.playing = true end,
                Stop = function(self) self.stops = self.stops + 1; self.playing = false end,
            }
            group.CreateAnimation = function(self, kind)
                local animation = { kind = kind }
                for _, key in ipairs({ "Order", "Duration", "FlipBookRows", "FlipBookColumns", "FlipBookFrames", "FlipBookFrameWidth", "FlipBookFrameHeight" }) do
                    local field = key
                    animation["Set" .. field] = function(target, value) target[field] = value end
                end
                self.animation = animation; return animation
            end
            return group
        end
        return texture
    end
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    return frame
end
C_Spell = {
    IsSpellUsable = function(id) return usable[id], power[id] end,
    GetSpellCooldown = function(id)
        local value = cooldowns[id]
        if type(value) == "function" then return value() end
        return value
    end,
    GetSpellInfo = function(id) return infos[id] end,
}
C_SpellBook = { IsSpellKnown = function(id) return known[id] end }
C_SpellActivationOverlay = { IsSpellOverlayed = function(id) return glows[id] end }
C_Timer = { NewTimer = function(delay, callback)
    local timer = { at = now + delay, callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
local function Flush()
    local timer = alerts.timer
    if timer then timer.fired = true; timer.callback() end
end
local function Advance(seconds)
    local finish, iterations = now + seconds, 0
    while true do
        local nextTimer
        for _, timer in ipairs(timers) do
            if not timer.cancelled and not timer.fired and timer.at <= finish
                and (not nextTimer or timer.at < nextTimer.at) then nextTimer = timer end
        end
        if not nextTimer then break end
        iterations = iterations + 1; assert(iterations < 100, "proc retries must be bounded")
        now = math.max(now, nextTimer.at); nextTimer.fired = true; nextTimer.callback()
    end
    now = finish
end
local function Resume()
    SetCombat(false); local pending = Suite.pending; Suite.pending = {}
    for _, callback in pairs(pending) do callback() end
end
equal(Suite.db.procAlerts, false, "proc alerts default off")
equal(Suite.db.procAlertIconSize, 42, "proc icons retain their original default size")
equal(alerts:IconSize({ procAlertIconSize = 9 }), 24, "proc icon size has a usable minimum")
equal(alerts:IconSize({ procAlertIconSize = 999 }), 128, "proc icon size has a bounded maximum")
equal(alerts:IconSize({ procAlertIconSize = 75.6 }), 76, "proc icon size rounds to whole pixels")
for _, invalid in ipairs({ secret, math.huge, 0 / 0, "80" }) do
    equal(alerts:IconSize({ procAlertIconSize = invalid }), 42, "invalid or restricted icon sizes use the default")
end
alerts:Apply(); equal(created, 0, "disabled alerts have no widgets or events")
Suite.db.procAlerts = true; SetCombat(true); alerts:Apply()
equal(created, 0, "first combat enable defers creation")
Suite.db.procAlerts = false; alerts:Apply(); Resume()
equal(created, 0, "disable cancels deferred enable")
known[7384], known[11585] = true, true
infos[11585] = { name = "Overpower", iconID = 132223 }
usable[11585], cooldowns[11585] = false, { duration = 0 }
Suite.db.procAlerts = true; alerts:Apply()
equal(#alerts.learned, 1, "learned reactive ranks collapse to highest known")
equal(alerts.learned[1], 11585, "highest Overpower rank selected")
equal(alerts.events.registered.SPELL_UPDATE_USABLE, true, "reactive availability is event driven")
equal(alerts.frame:IsShown(), false, "normal combat-only alerts start hidden")
equal(#alerts.cells, 8, "all glow cells are prepared before combat")
local glow = alerts.cells[1].glowAnimation
equal(glow.looping, "REPEAT", "sparkly proc border loops through the native animation engine")
equal(glow.animation.kind, "FlipBook", "border animates the native proc artwork")
equal(glow.animation.FlipBookRows, 6, "proc sheet has six rows")
equal(glow.animation.FlipBookColumns, 5, "proc sheet has five columns")
equal(glow.animation.FlipBookFrames, 30, "proc sheet has thirty animation frames")
equal(glow.animation.Duration, 1, "border completes one cycle per second")
equal(glow.playing, false, "hidden proc cells do not animate")
local before = created
SetCombat(true); alerts:OnEvent("PLAYER_REGEN_DISABLED")
equal(alerts.frame:IsShown(), false, "no proc means no alert")
usable[11585] = true; alerts:OnEvent("SPELL_UPDATE_USABLE"); Flush()
equal(alerts.frame:IsShown(), true, "available Overpower appears in combat")
equal(alerts.cells[1].name.text, "Overpower", "reaction uses localized spell name")
equal(alerts.cells[1].icon.texture, 132223, "reaction displays spell icon")
equal(glow.playing, true, "available ability starts the border animation")
equal(alerts.cells[1].glow:IsShown(), true, "available ability shows the sparkly border")
local plays = glow.plays
alerts:Paint()
equal(glow.plays, plays, "refreshing an existing proc does not restart the animation")
equal(alerts.cells[1].OnUpdate, nil, "border needs no Lua frame polling")
equal(created, before, "combat proc creates no frames")
usable[11585], power[11585] = false, true
alerts:OnEvent("UNIT_POWER_UPDATE", "player"); Flush()
equal(alerts.frame:IsShown(), true, "low rage keeps an available Overpower visible")
equal(alerts.cells[1].icon.tint[1], 0.5, "low rage uses native action-bar red tint")
equal(alerts.cells[1].icon.tint[2], 0.5, "low rage uses native action-bar green tint")
equal(alerts.cells[1].icon.tint[3], 1, "low rage uses native action-bar blue tint")
equal(glow.playing, true, "low rage preserves the active proc border")
cooldowns[11585] = { duration = 5, startTime = now }
alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Flush()
equal(alerts.frame:IsShown(), false, "insufficient rage cannot bypass a real cooldown")
cooldowns[11585] = { isActive = false, duration = secret }
alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Flush()
equal(alerts.frame:IsShown(), true, "low-rage proc can first appear with public inactive cooldown")
cooldowns[11585].isEnabled = false; alerts:Paint()
equal(alerts.frame:IsShown(), false, "low rage cannot bypass a disabled cooldown")
cooldowns[11585] = { isEnabled = true, isActive = true, isOnGCD = true, duration = secret }
alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Flush()
equal(alerts.frame:IsShown(), true, "GCD keeps a low-resource proc visible with restricted times")
cooldowns[11585] = { isActive = false, duration = secret }
alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Flush()
power[11585] = false; alerts:OnEvent("SPELL_UPDATE_USABLE"); Flush()
equal(alerts.frame:IsShown(), false, "proc expiry still hides while rage remains low")
for _, unreadable in ipairs({ secret, "true" }) do
    power[11585] = unreadable; alerts:Paint()
    equal(alerts.frame:IsShown(), false, "unreadable or invalid resource flag cannot establish a proc")
end
power[11585], usable[11585] = true, secret; alerts:Paint()
equal(alerts.frame:IsShown(), false, "resource flag cannot bypass restricted usability")
local usableAPI = C_Spell.IsSpellUsable
C_Spell.IsSpellUsable = function() error("unavailable") end
alerts:Paint(); equal(alerts.frame:IsShown(), false, "rejected usability query hides safely")
C_Spell.IsSpellUsable = usableAPI
usable[11585], power[11585] = true, false
alerts:OnEvent("UNIT_POWER_UPDATE", "player"); Flush()
equal(alerts.frame:IsShown(), true, "regaining rage restores the available proc")
equal(alerts.cells[1].icon.tint[1], 1, "regaining rage restores full icon brightness")
equal(alerts.cells[1].icon.tint[2], 1, "regaining rage clears the resource tint")
equal(alerts.frame.mouseEnabled, false, "live proc frame is click through")
equal(alerts.frame.wheelEnabled, false, "live popup also passes mouse-wheel input through")
for _, cell in ipairs(alerts.cells) do
    equal(cell.mouseEnabled, false, "every proc icon stays passive")
    equal(cell.wheelEnabled, false, "proc icons cannot capture mouse-wheel input")
end
cooldowns[11585] = { duration = 5, startTime = 10 }
alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Flush()
equal(alerts.frame:IsShown(), false, "used reaction hides on cooldown")
equal(glow.playing, false, "consumed reaction stops its border animation")
equal(alerts.cells[1].glow:IsShown(), false, "consumed reaction hides the glow artwork")
cooldowns[11585] = { duration = 1.5, startTime = 10, isOnGCD = true }
alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Flush()
equal(alerts:Ready(11585), true, "GCD does not suppress reaction")
cooldowns[11585] = { duration = 1.5, startTime = 10 }
alerts:CaptureCooldownFlags()
cooldowns[61304] = { duration = 1.5, startTime = 10 }
equal(alerts:Ready(11585), true, "matching public GCD is supported on older return shapes")
cooldowns[11585] = secret
equal(alerts:Ready(11585), false, "secret cooldown table cannot establish readiness")
cooldowns[11585] = { duration = secret }
equal(alerts:Ready(11585), false, "secret cooldown fields cannot establish readiness")
cooldowns[11585] = { duration = secret, startTime = secret, isActive = false, isEnabled = true }
equal(alerts:Ready(11585), true, "public inactive cooldown establishes readiness without secret times")
alerts:Paint()
equal(alerts.frame:IsShown(), true, "usable Overpower appears with public inactive cooldown and restricted times")
cooldowns[11585].isActive = true
equal(alerts:Ready(11585), false, "active cooldown with restricted times remains unavailable")
cooldowns[11585].isActive = false; cooldowns[11585].isEnabled = false
equal(alerts:Ready(11585), false, "cooldown on hold does not become ready through inactive flag")
cooldowns[11585].isEnabled = true; cooldowns[11585].isActive = secret
equal(alerts:Ready(11585), false, "restricted active flag cannot establish readiness")
usable[11585] = secret
equal(alerts:Ready(11585), false, "secret usability cannot establish readiness")
usable[11585] = false
infos[999] = { name = "Another class proc", iconID = 123 }
glows[999] = true
alerts:OnEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", 999); Flush()
equal(alerts.cells[1].name.text, "Another class proc", "native glows support arbitrary class spells")
usable[999], power[999] = false, true; alerts:OnEvent("UNIT_POWER_UPDATE", "player"); Flush()
equal(alerts.frame:IsShown(), true, "native highlighted proc remains visible with insufficient power")
equal(alerts.cells[1].icon.tint[1], 0.5, "native highlighted proc also receives resource tint")
usable[999], power[999] = true, false; alerts:OnEvent("UNIT_POWER_UPDATE", "player"); Flush()
equal(alerts.cells[1].icon.tint[1], 1, "native highlighted proc brightens when resources recover")
alerts:OnEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", 999); Flush()
equal(#alerts:Entries(), 1, "repeated glow events do not duplicate icons")
alerts:OnEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", secret)
equal(#alerts:Entries(), 1, "restricted event IDs are ignored")
glows[999] = secret; alerts:Paint()
equal(alerts.frame:IsShown(), false, "restricted overlay result hides without branching on it")
glows[999] = true; infos[999].name = secret; alerts:Paint()
equal(alerts.frame:IsShown(), false, "restricted spell name cannot become a key or label")
infos[999].name = "Another class proc"
alerts:OnEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", 999); Flush()
equal(alerts.frame:IsShown(), false, "native glow hide clears popup")
alerts:OnEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", 999); Flush()
SetCombat(false); alerts:OnEvent("PLAYER_REGEN_ENABLED")
equal(alerts.frame:IsShown(), false, "combat exit hides popups")
SetCombat(true); alerts:OnEvent("PLAYER_REGEN_DISABLED")
equal(alerts.frame:IsShown(), true, "ongoing native glow survives combat reentry")
alerts:OnEvent("PLAYER_LEAVING_WORLD")
equal(alerts.frame:IsShown(), false, "world exit hides alerts even during combat")
SetCombat(false); alerts:OnEvent("PLAYER_ENTERING_WORLD")
alerts:SetPreview(true)
equal(alerts.preview, true, "preview can show outside combat")
equal(glow.playing, true, "preview includes the same sparkly border")
equal(alerts.frame.mouseEnabled, true, "only preview accepts dragging")
equal(alerts.frame.wheelEnabled, false, "preview movement does not capture mouse-wheel input")
SetCombat(true); alerts:Paint()
equal(alerts.frame.mouseEnabled, false, "combat forces click through even before preview event cleanup")
equal(alerts.frame:IsShown(), false, "stale preview state cannot show a placement preview in combat")
SetCombat(true); alerts:OnEvent("PLAYER_REGEN_DISABLED")
equal(alerts.preview, nil, "combat cancels preview")
equal(alerts.frame.mouseEnabled, false, "combat restores click through input")
alerts:Queue(); local stale = alerts.timer
Suite.db.procAlerts = false; alerts:Apply()
equal(stale.cancelled, true, "disable cancels queued work")
equal(next(alerts.events.registered), nil, "disable unregisters every feature event")
equal(glow.playing, false, "disable leaves no running border animation")
stale.callback(); equal(alerts.frame:IsShown(), false, "cancelled callback cannot revive popup")
Resume(); alerts:SetPreview(true)
equal(alerts.active, nil, "preview does not enable alerts")
equal(alerts.events.registered.PLAYER_REGEN_DISABLED, true, "disabled preview still watches combat")
alerts:SetPreview(false)
equal(next(alerts.events.registered), nil, "ending disabled preview removes its events")
equal(alerts.frame.mouseEnabled, false, "ending preview always removes mouse capture")
local oldBank = Enum.SpellBookSpellBank
Enum.SpellBookSpellBank = { Player = 0 }
C_SpellBook.GetNumSpellBookSkillLines = function() return 1 end
C_SpellBook.GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = 1 } end
C_SpellBook.GetSpellBookItemInfo = function() return { spellID = 999 } end
alerts:Scan()
equal(alerts.glows[999], true, "spellbook scan recovers an already active native proc")
Enum.SpellBookSpellBank = oldBank
local requests = 0
C_Spell.RequestLoadSpellData = function() requests = requests + 1 end
infos[999] = nil
alerts:Entries(); alerts:Entries()
equal(requests, 1, "uncached proc data is requested once without a polling loop")
infos[999] = { name = "Loaded proc", iconID = 123 }
equal(alerts:Entries()[1].name, "Loaded proc", "asynchronously available spell data becomes displayable")
local gui = Suite.GUI
local oldPage, oldShown = gui.page, gui.frame:IsShown()
gui.frame:Show(); gui:Select("actionbars", "feedback"); gui.rows[4].OnClick()
equal(alerts.preview, true, "settings action opens the proc preview")
gui:Select("overview")
equal(alerts.preview, nil, "navigation stops proc preview")
gui:Select("actionbars", "feedback"); gui.rows[4].OnClick(); gui.frame.OnHide(gui.frame)
equal(alerts.preview, nil, "closing settings stops proc preview")
gui:Select(oldPage); gui.frame:SetShown(oldShown)

-- Reproduce late server availability: one 30ms check was insufficient.
alerts:Cancel(); alerts.glows = {}; timers = {}; now = 200
C_SpellBook.GetNumSpellBookSkillLines = nil
Suite.db.procAlerts = true; alerts:Apply()
usable[11585], cooldowns[11585] = false, { isEnabled = true, isActive = false, duration = 0 }
SetCombat(true); alerts:OnEvent("PLAYER_REGEN_DISABLED")
Advance(2)
equal(alerts.followTimer, nil, "event follow-ups finish instead of polling idle combat")
alerts:OnEvent("SPELL_UPDATE_USABLE")
Advance(0.04)
equal(alerts.frame:IsShown(), false, "initial event can precede server readiness")
usable[11585] = true
Advance(0.05)
equal(alerts.frame:IsShown(), true, "follow-up catches late readiness without another event")
Advance(2)
equal(alerts.followTimer, nil, "successful detection leaves no endless retry")
equal(alerts.cooldownTimer, nil, "ready skills need no cooldown worker")

usable[11585] = false
alerts:OnEvent("UNIT_COMBAT", "target", secret, secret, secret, secret)
local burst = alerts.followTimer
alerts:OnEvent("UNIT_COMBAT", "target", secret, secret, secret, secret)
equal(alerts.followTimer, burst, "frequent combat events cannot postpone the existing burst")
Advance(0.04)
equal(alerts.frame:IsShown(), false, "target combat activity alone never invents an Overpower proc")
usable[11585] = true; Advance(0.05)
equal(alerts.frame:IsShown(), true, "target activity can catch readiness without spell-usable events")
Advance(2)
alerts:OnEvent("UNIT_COMBAT", "party1")
equal(alerts.followTimer, nil, "unrelated units cannot start combat retries")
alerts:OnEvent("UNIT_COMBAT", secret)
equal(alerts.followTimer, nil, "restricted unit tokens cannot start combat retries")

usable[11585] = false; alerts:Paint()
alerts:OnEvent("ACTION_USABLE_CHANGED", secret)
Advance(0.04); usable[11585] = true; Advance(0.05)
equal(alerts.frame:IsShown(), true, "action usability notification refreshes without inspecting its payload")
usable[11585] = false; glows[999] = false
alerts:OnEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", 999); Advance(0.04)
equal(alerts.frame:IsShown(), false, "native glow event can precede readable overlay state")
glows[999] = true; Advance(0.05)
equal(alerts.frame:IsShown(), true, "native glow candidate survives until delayed query readiness")
alerts:OnEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", 999); Advance(0.04)
equal(alerts.frame:IsShown(), false, "native glow hide removes the delayed candidate")
usable[11585] = false; alerts:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", secret, secret)
Advance(0.04)
equal(alerts.frame:IsShown(), false, "successful player casts promptly refresh consumed reactions")
usable[11585] = true; alerts:OnEvent("UNIT_POWER_UPDATE", "player", secret)
Advance(0.04)
equal(alerts.frame:IsShown(), true, "resource changes recheck ability availability")

-- A readable cooldown expiry schedules its own refresh even with no later event.
alerts:Cancel(); timers = {}; now = 300
local expiry = now + 0.6
cooldowns[11585] = function()
    if now >= expiry then return { isEnabled = true, isActive = false, duration = secret } end
    return { isEnabled = true, isActive = true, duration = 0.6, startTime = 300, modRate = 1, isOnGCD = false }
end
alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Advance(0.04)
equal(alerts.frame:IsShown(), false, "real cooldown suppresses an otherwise usable reaction")
equal(alerts.cooldownTimer ~= nil, true, "known cooldown expiry schedules one precise wakeup")
Advance(0.7)
equal(alerts.frame:IsShown(), true, "cooldown expiry wakes without another usable or cooldown event")
equal(alerts.cooldownTimer, nil, "expired cooldown worker is released")

-- GCD classification is sampled during its authoritative event, before times.
cooldowns[11585] = { isEnabled = true, isActive = true, duration = secret, startTime = secret, isOnGCD = true }
alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Advance(0.04)
equal(alerts.frame:IsShown(), true, "public GCD-only update keeps procced ability visible despite restricted times")
cooldowns[11585].isOnGCD = false
alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Advance(0.04)
equal(alerts.frame:IsShown(), false, "next real-cooldown update clears cached GCD classification")
cooldowns[11585].isOnGCD = true
equal(alerts:Ready(11585), false, "GCD field outside a cooldown event is not trusted")
cooldowns[11585] = { isEnabled = true, isActive = true, duration = 1, startTime = now, modRate = secret }
alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Advance(0.04)
equal(alerts.cooldownTimer, nil, "restricted cooldown rates never enter timing arithmetic")

-- Disable must invalidate both new kinds of work, including stale callbacks.
cooldowns[11585] = { isEnabled = true, isActive = true, duration = 5, startTime = now }
alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Advance(0.04)
local staleFollow, staleCooldown = alerts.followTimer, alerts.cooldownTimer
equal(staleFollow ~= nil and staleCooldown ~= nil, true, "both retry workers can be pending together")
Suite.db.procAlerts = false; alerts:Apply()
equal(staleFollow.cancelled, true, "disable cancels event follow-ups")
equal(staleCooldown.cancelled, true, "disable cancels cooldown wakeup")
staleFollow.callback(); staleCooldown.callback()
equal(alerts.frame:IsShown(), false, "stale retry callbacks cannot revive disabled icons")
Advance(10)
equal(alerts.followTimer, nil, "disabled feature leaves no event retry worker")
equal(alerts.cooldownTimer, nil, "disabled feature leaves no cooldown worker")
Suite.db.procAlerts = true; alerts.active = true; alerts.learned = {}; alerts.glows = {}; glows[999] = false
alerts:OnEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", 999); Advance(0.04)
equal(alerts.frame:IsShown(), false, "other classes wait for native highlight state")
glows[999] = true; Advance(0.05)
equal(alerts.frame:IsShown(), true, "classes without legacy reactive skills also receive bounded retries")
SetCombat(false); alerts:OnEvent("PLAYER_REGEN_ENABLED")
equal(alerts.followTimer, nil, "combat exit cancels generic-proc retries")
equal(alerts.frame:IsShown(), false, "combat exit removes generic-proc popup")
Suite.db.procAlerts = false; alerts:Apply(); alerts.learned = { 11585 }
local oldPrint, output = Suite.Print, {}
Suite.Print = function(message) output[#output + 1] = message end
SlashCmdList.WOWFOREVERSUITE("procstatus")
equal(output[1]:find("disabled", 1, true) ~= nil, true, "diagnostic slash command reports enabled state")
equal(output[2]:find("11585", 1, true) ~= nil, true, "diagnostic identifies the learned Overpower rank")
equal(#alerts.history <= 24, true, "diagnostic availability history is bounded")
Suite.Print = oldPrint
alerts:Cancel()

-- Size control updates the real preview without enabling the proc feature.
SetCombat(false)
gui.frame:Show(); gui:Select("actionbars", "feedback")
equal(alerts.preview, nil, "synchronizing size slider does not open a preview")
equal(gui.procSizeLabel.text, "42 px", "size slider displays current pixels")
Suite.db.procAlertPosition = { x = 0.12, y = -0.08 }; alerts:Place()
local beforeX, beforeY = alerts.frame.point[4], alerts.frame.point[5]
gui.procSizeSlider:SetValue(80)
equal(Suite.db.procAlertIconSize, 80, "slider saves the selected icon size")
equal(Suite.db.procAlerts, false, "resizing a preview does not enable proc detection")
equal(alerts.preview, true, "moving the size slider opens a live preview")
equal(alerts.cells[1]:GetWidth(), 80, "preview icon uses selected size")
equal(math.abs(alerts.cells[1].glow:GetWidth() - 112) < 0.00001, true, "sparkly border follows the icon size")
equal(alerts.frame.point[4], beforeX, "size change preserves saved horizontal placement")
equal(alerts.frame.point[5], beforeY, "size change preserves saved vertical placement")
gui.procSizeSlider:SetValue(128)
equal(alerts.cells[1]:GetHeight(), 128, "slider reaches the larger icon limit")
equal(alerts.stride > 128 * 1.4, true, "spacing clears enlarged sparkle borders")
gui.procSizeSlider.OnMouseWheel(gui.procSizeSlider, -1)
equal(Suite.db.procAlertIconSize, 127, "mouse wheel makes one-pixel size adjustments")
alerts:SetIconSize(secret)
equal(Suite.db.procAlertIconSize, 127, "restricted size input cannot change the saved value")
SetCombat(true); alerts:OnEvent("PLAYER_REGEN_DISABLED")
gui.frame.OnEvent(gui.frame, "PLAYER_REGEN_DISABLED")
equal(gui.procSizeSlider.enabled, false, "size slider disables during combat")
gui.procSizeSlider:SetValue(60)
equal(Suite.db.procAlertIconSize, 127, "combat callbacks cannot resize icons or change the preference")
Suite.db.procAlerts, Suite.db.procAlertIconSize = true, 96; alerts:Apply()
equal(alerts.cells[1]:GetWidth(), 127, "external combat size changes wait for the safe apply queue")
Resume(); gui.frame.OnEvent(gui.frame, "PLAYER_REGEN_ENABLED")
equal(alerts.cells[1]:GetWidth(), 96, "deferred size is applied after combat")
equal(gui.procSizeSlider.enabled, true, "size slider re-enables after combat")
equal(gui.procSizeLabel.text, "96 px", "size slider resynchronizes deferred settings")
equal(Suite.Profiles:Settings(Suite.db).procAlertIconSize, 96, "size follows saved settings profiles")
equal(Suite.SettingsCatalog:Search("Proc popup icon size")[1].key, "procAlertIconSize", "settings search discovers the size slider")
infos[1000], glows[999], glows[1000] = { name = "Second proc", iconID = 124 }, true, true
alerts.glows = { [999] = true, [1000] = true }; usable[11585] = false
SetCombat(true); alerts:OnEvent("PLAYER_REGEN_DISABLED")
equal(alerts.cells[1].point[4] + alerts.cells[2].point[4], 0, "resized simultaneous procs stay centered")
equal(alerts.cells[2].point[4] - alerts.cells[1].point[4], alerts.stride, "resized procs use the new spacing")
Suite.db.procAlerts = false; alerts:Apply(); Resume()
gui:Select(oldPage); gui.frame:SetShown(oldShown)
Suite.db, Suite.pending = oldDB, oldPending
CreateFrame, C_Spell, C_SpellBook, C_SpellActivationOverlay, C_Timer = oldCreate, oldSpell, oldBook, oldOverlay, oldTimer
issecretvalue = oldSecret; SetCombat(false)
C_Texture = oldTexture
GetTime = oldGetTime
