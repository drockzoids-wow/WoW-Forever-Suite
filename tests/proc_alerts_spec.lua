local Suite, equal, Frame, SetCombat = ...
local alerts = Suite.ProcAlerts
local oldDB, oldPending = Suite.db, Suite.pending
local oldCreate, oldSpell, oldBook, oldOverlay, oldTimer = CreateFrame, C_Spell, C_SpellBook, C_SpellActivationOverlay, C_Timer
local oldSecret = issecretvalue
local oldAuras, oldSecrets, oldStance = C_UnitAuras, C_Secrets, GetShapeshiftForm
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
    if kind == "Cooldown" then
        frame.SetHideCountdownNumbers = function(self, value) self.hideNumbers = value end
        frame.SetCooldown = function(self, start, duration, rate)
            self.timing = { start, duration, rate }
        end
    end
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
equal(alerts.cells[1].countdown.text, "5", "a newly confirmed Overpower shows the estimated window")
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
cooldowns[11585] = { duration = 5, startTime = now, isOnGCD = false }
alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Flush()
equal(alerts.frame:IsShown(), true, "a true cooldown can show an icon even with insufficient rage")
equal(alerts.cells[1].cooldownSwipe:IsShown(), true, "low rage does not hide the cooldown swipe")
equal(alerts.cells[1].countdown.text, "5", "a confirmed low-rage opening keeps its own timer during recharge")
equal(alerts.cells[1].glow:IsShown(), false, "a recharging spell does not glow as usable")
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
usable[11585] = false
alerts:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 11585)
alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Flush()
equal(alerts.frame:IsShown(), false, "used reaction hides on cooldown")
equal(glow.playing, false, "consumed reaction stops its border animation")
equal(alerts.cells[1].glow:IsShown(), false, "consumed reaction hides the glow artwork")
cooldowns[11585] = { duration = 1.5, startTime = 10, isOnGCD = true }
usable[11585] = true
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
equal(#alerts:Entries(true), 1, "repeated glow events do not duplicate icons")
alerts:OnEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", secret)
equal(#alerts:Entries(true), 1, "restricted event IDs are ignored")
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
alerts:Entries(true); alerts:Entries(true)
equal(requests, 1, "uncached proc data is requested once without a polling loop")
infos[999] = { name = "Loaded proc", iconID = 123 }
equal(alerts:Entries(true)[1].name, "Loaded proc", "asynchronously available spell data becomes displayable")
local gui = Suite.GUI
local oldPage, oldShown = gui.page, gui.frame:IsShown()
gui.frame:Show(); gui:Select("actionbars", "feedback"); gui.rows[5].OnClick()
equal(alerts.preview, true, "settings action opens the proc preview")
gui:Select("overview")
equal(alerts.preview, nil, "navigation stops proc preview")
gui:Select("actionbars", "feedback"); gui.rows[5].OnClick()
equal(gui.frame:IsShown(), false, "proc preview hides settings")
gui.previewReturn.OnHide(gui.previewReturn)
equal(alerts.preview, nil, "Escape closes the standalone proc preview")
equal(gui.frame:IsShown(), true, "Escape restores the settings window")
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
equal(alerts.nextWakeCooldown, nil, "a ready skill's countdown does not schedule cooldown retries")

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
alerts:ClearOverpower(); usable[11585] = false
local expiry = now + 0.6
cooldowns[11585] = function()
    if now >= expiry then return { isEnabled = true, isActive = false, duration = secret } end
    return { isEnabled = true, isActive = true, duration = 0.6, startTime = 300, modRate = 1, isOnGCD = false }
end
alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Advance(0.04)
equal(alerts.frame:IsShown(), false, "a real cooldown alone never shows the Overpower icon")
usable[11585] = true
alerts:OnEvent("SPELL_UPDATE_USABLE"); Advance(0.04)
equal(alerts.frame:IsShown(), true, "a new opening shows the charging icon immediately")
equal(alerts.cells[1].cooldownSwipe:IsShown(), true, "readable cooldown displays its own swipe")
equal(alerts.cells[1].countdown.text, "5", "the new opening keeps its own expiry alongside the swipe")
equal(alerts.cooldownTimer ~= nil, true, "known cooldown expiry schedules one precise wakeup")
Advance(0.7)
equal(alerts.frame:IsShown(), true, "cooldown expiry wakes without another usable or cooldown event")
equal(alerts.cells[1].cooldownSwipe:IsShown(), false, "the finished recharge clears its swipe")
equal(alerts.nextWakeCooldown, nil, "the expiry wakeup switches from cooldown to countdown")

-- GCD classification is sampled during its authoritative event, before times.
cooldowns[11585] = { isEnabled = true, isActive = true, duration = secret, startTime = secret, isOnGCD = true }
alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Advance(0.04)
equal(alerts.frame:IsShown(), true, "public GCD-only update keeps procced ability visible despite restricted times")
cooldowns[11585].isOnGCD = false
alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Advance(0.04)
equal(alerts.frame:IsShown(), true, "a confirmed opening stays visible with private cooldown timing")
cooldowns[11585].isOnGCD = true
equal(alerts:Ready(11585), false, "GCD field outside a cooldown event is not trusted")
cooldowns[11585] = { isEnabled = true, isActive = true, duration = 1, startTime = now, modRate = secret }
alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Advance(0.04)
equal(alerts.nextWakeCooldown, nil, "restricted cooldown rates never schedule a cooldown-end retry")

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
do
    local stance, auras, restrictions = 2, {}, {}
    GetShapeshiftForm = function() return stance end
    C_Secrets = { ShouldSpellAuraBeSecret = function(id) return restrictions[id] or false end }
    C_UnitAuras = { GetPlayerAuraBySpellID = function(id)
        assert(not restrictions[id], "proc alerts must skip restricted aura lookups")
        return auras[id]
    end }
    known[402927], infos[402927] = true, { name = "Victory Rush", iconID = 132342 }
    cooldowns[402927] = { isActive = false, duration = secret }
    usable[11585], power[11585], cooldowns[11585] = false, false, { duration = 0 }
    glows[999] = false
    alerts:Apply()
    equal(alerts.events.registered.UNIT_AURA, true, "known Warrior proc spells watch player aura changes")
    SetCombat(true); alerts:OnEvent("PLAYER_REGEN_DISABLED")
    auras[1282733] = { expirationTime = now + 2.8 }
    alerts:OnEvent("UNIT_AURA", "player"); Flush()
    equal(alerts.cells[1].name.text, "Overpower", "readable proc aura shows Overpower in Defensive Stance")
    equal(alerts.cells[1].countdown.text, "3", "Overpower uses the native remaining time")
    stance = 3; alerts:OnEvent("UPDATE_SHAPESHIFT_FORM"); Flush()
    auras[1282733] = nil
    alerts:OnEvent("UNIT_AURA", "player"); Flush()
    Advance(1)
    equal(alerts.cells[1].countdown.text, "2", "Berserker keeps the native deadline if the aura stops being readable")
    Advance(2)
    equal(alerts.frame:IsShown(), false, "expired aura hides without a new combat event")

    stance, usable[11585] = 1, true
    auras[1282733] = { expirationTime = now + 3 }
    glows[7384] = true
    alerts:OnEvent("UNIT_AURA", "player"); Flush()
    equal(alerts.cells[1].countdown.text, "3", "Overpower starts with its readable proc expiry")
    equal(alerts.cells[1].cooldownSwipe:IsShown(), false, "an off-cooldown proc shows its expiry alone")
    cooldowns[11585] = { isOnGCD = false, duration = 5, startTime = now }
    alerts:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 11585)
    alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Flush()
    equal(alerts.frame:IsShown(), false, "cast clears Overpower even while old aura, glow and usable flags linger")
    auras[1282733].expirationTime = now + 5
    alerts:OnEvent("UNIT_AURA", "player"); Flush()
    equal(alerts.cells[1].countdown.text, "5", "a newer aura restores the proc with its own expiry")
    equal(alerts.cells[1].cooldownSwipe:IsShown(), true, "a new proc can display both timers")
    auras[1282733], glows[7384], usable[11585], cooldowns[11585] = nil, false, false, { duration = 0 }
    stance = 3; alerts:OnEvent("PLAYER_TARGET_CHANGED"); Flush()

    known[11601], infos[11601], usable[11601] = true, { name = "Revenge", iconID = 132353 }, false
    cooldowns[11601] = { isOnGCD = false, duration = 5, startTime = now }
    alerts:OnEvent("SPELLS_CHANGED"); Flush()
    glows[11601] = true
    alerts:OnEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", 11601)
    alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Flush()
    equal(alerts.frame:IsShown(), false, "Berserker hides Revenge despite its native glow and real cooldown")
    stance = 2; alerts:OnEvent("UPDATE_SHAPESHIFT_FORM"); Flush()
    equal(alerts.cells[1].name.text, "Revenge", "Defensive Stance shows recharging Revenge")
    equal(alerts.cells[1].cooldownSwipe:IsShown(), true, "Revenge shows its swipe in Defensive Stance")
    stance = 1; alerts:OnEvent("UPDATE_SHAPESHIFT_FORM"); Flush()
    equal(alerts.frame:IsShown(), false, "switching to Battle Stance immediately hides Revenge")
    known[11601], infos[11601], usable[11601], cooldowns[11601], glows[11601] = nil, nil, nil, nil, nil
    alerts:OnEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", 11601)
    alerts:OnEvent("SPELLS_CHANGED"); Flush()

    for _, spell in ipairs({ {11601, "Revenge"}, {14251, "Riposte"}, {14271, "Mongoose Bite"}, {20910, "Counterattack"} }) do
        local id, spellName = spell[1], spell[2]
        stance, known[id], infos[id], usable[id] = 2, true, { name = spellName, iconID = 132353 }, false
        cooldowns[id] = { isOnGCD = false, duration = 5, startTime = now }
        alerts:OnEvent("SPELLS_CHANGED")
        alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Flush()
        equal(alerts.frame:IsShown(), false, spellName .. " hides during cooldown alone")
        usable[id] = true
        alerts:OnEvent("SPELL_UPDATE_USABLE"); Flush()
        equal(alerts.cells[1].name.text, spellName, "a confirmed reactive ability shows")
        equal(alerts.cells[1].countdown.text, "5", "the estimated reaction window starts on the public signal")
        equal(alerts.cells[1].cooldownSwipe:IsShown(), true, "an overlapping cooldown supplies the swipe")
        alerts:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", id); Flush()
        equal(alerts.frame:IsShown(), false, "a cast clears the reminder despite stale usability")
        auras[id] = { expirationTime = now + 3 }
        cooldowns[id] = { isActive = false, duration = secret }
        alerts:OnEvent("UNIT_AURA", "player"); Flush()
        equal(alerts.cells[1].countdown.text, "3", "a new readable aura uses its own expiration")
        equal(alerts.cells[1].cooldownSwipe:IsShown(), false, "a ready reaction has only its proc timer")
        known[id], infos[id], usable[id], cooldowns[id], auras[id] = nil, nil, nil, nil, nil
        alerts:OnEvent("SPELLS_CHANGED"); Flush()
    end
    known[686], infos[686], usable[686] = true, { name = "Shadow Bolt", iconID = 136197 }, true
    cooldowns[686] = { isActive = false, duration = secret }
    alerts:OnEvent("SPELLS_CHANGED"); Flush()
    equal(alerts.frame:IsShown(), false, "ordinary Shadow Bolt usability does not imply Nightfall")
    auras[17941] = { expirationTime = now + 8 }
    alerts:OnEvent("UNIT_AURA", "player"); Flush()
    equal(alerts.cells[1].name.text, "Shadow Bolt", "Nightfall shows the spell to cast")
    equal(alerts.cells[1].countdown.text, "8", "Shadow Bolt uses the Shadow Trance timer")
    auras[17941] = nil
    alerts:OnEvent("UNIT_AURA", "player"); Flush()
    equal(alerts.frame:IsShown(), false, "the Nightfall reminder clears when Shadow Trance is consumed")
    known[686], infos[686], usable[686], cooldowns[686] = nil, nil, nil, nil
    alerts:OnEvent("SPELLS_CHANGED"); Flush()

    auras[1282733] = nil
    stance, usable[11585] = 1, true
    alerts:OnEvent("SPELL_UPDATE_USABLE"); Flush()
    equal(alerts.cells[1].countdown.text, "5", "readable spell usability starts the fallback countdown")
    Advance(1.1)
    stance, usable[11585] = 2, false
    alerts:OnEvent("UPDATE_SHAPESHIFT_FORM"); Flush()
    equal(alerts.cells[1].countdown.text, "4", "switching away from Battle keeps the same confirmed window")
    alerts:OnEvent("PLAYER_TARGET_CHANGED"); Flush()
    equal(alerts.frame:IsShown(), false, "target change clears the estimated Overpower window")
    glows[7384] = true
    alerts:OnEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", 7384); Flush()
    equal(alerts.cells[1].countdown.text, "5", "a base-rank glow confirms a timed opening in Defensive Stance")
    glows[7384] = false
    alerts:OnEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", 7384); Flush()
    alerts:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 7384); Flush()
    equal(alerts.frame:IsShown(), false, "casting a lower rank clears the carried window")
    stance, glows[7384] = 3, true
    alerts:OnEvent("SPELL_UPDATE_USABLE"); Flush()
    equal(alerts.cells[1].countdown.text, "5", "Berserker Stance can pick up a readable native glow without its show event")
    glows[7384] = false
    alerts:OnEvent("PLAYER_TARGET_CHANGED"); Flush()
    equal(alerts.frame:IsShown(), false, "target change clears the glow-derived estimate")
    do
        local originalFormID = GetShapeshiftFormID
        GetShapeshiftFormID = function() return 19 end
        stance, usable[11585] = 1, true
        cooldowns[11585] = { isActive = true, isOnGCD = true, duration = secret }
        alerts:OnEvent("SPELL_UPDATE_COOLDOWN")
        usable[11585] = false
        alerts:OnEvent("SPELL_UPDATE_USABLE"); Flush()
        equal(alerts.cells[1].countdown.text, "5", "a brief GCD readiness signal survives until paint in Berserker")
        equal(alerts.lastChecks[11585], "opening shown [Berserker]", "stable form ID wins over the stance-bar slot")
        Advance(1.1)
        equal(alerts.cells[1].countdown.text, "4", "later readiness changes do not restart the timer")
        alerts:OnEvent("PLAYER_TARGET_CHANGED"); Flush()
        equal(alerts.frame:IsShown(), false, "a target switch clears the captured readiness window")
        GetShapeshiftFormID = originalFormID
        stance, cooldowns[11585] = 3, { duration = 0 }
        alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Flush()
    end
    do
        local originalCombatText = C_CombatText
        local watched, notice = "player", secret
        C_CombatText = {
            GetActiveUnit = function() return watched end,
            GetCurrentEventInfo = function() return notice end,
        }
        alerts:Watch()
        equal(alerts.events.registered.COMBAT_TEXT_UPDATE, true, "known Overpower watches native activation text")
        alerts:OnEvent("COMBAT_TEXT_UPDATE", "SPELL_ACTIVE"); Flush()
        equal(alerts.frame:IsShown(), false, "restricted combat text cannot start a proc")
        watched, notice = "vehicle", "Overpower"
        alerts:OnEvent("COMBAT_TEXT_UPDATE", "SPELL_ACTIVE"); Flush()
        equal(alerts.frame:IsShown(), false, "activation text for another unit is ignored")
        watched, notice = "player", "Revenge"
        alerts:OnEvent("COMBAT_TEXT_UPDATE", "SPELL_ACTIVE"); Flush()
        equal(alerts.frame:IsShown(), false, "another spell's activation cannot start Overpower")
        infos[11585].name, notice = "Überwältigen", "Überwältigen"
        alerts:OnEvent("COMBAT_TEXT_UPDATE", "SPELL_ACTIVE"); Flush()
        equal(alerts.cells[1].name.text, "Überwältigen", "localized player activation shows in Berserker without aura, glow or usability")
        equal(alerts.cells[1].countdown.text, "5", "activation text starts a timed opening")
        Advance(1.1)
        equal(alerts.cells[1].countdown.text, "4", "a repeated paint follows the original opening")
        stance = 2
        alerts:OnEvent("UPDATE_SHAPESHIFT_FORM"); Flush()
        equal(alerts.cells[1].countdown.text, "4", "a text-confirmed opening survives stance changes")
        alerts:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 11585); Flush()
        equal(alerts.frame:IsShown(), false, "casting clears the text-confirmed opening")
        infos[11585].name, C_CombatText = "Overpower", originalCombatText
        alerts:Watch()
    end

    auras[402975] = { expirationTime = now + 5 }
    usable[402927] = true
    cooldowns[402927] = { isActive = true, duration = 10, startTime = now }
    alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Flush()
    equal(alerts.frame:IsShown(), true, "a confirmed Victorious opening can display during a real cooldown")
    equal(alerts.cells[1].countdown.text, "5", "Victorious expiry is independent of the spell cooldown")
    local swipe = alerts.cells[1].cooldownSwipe
    equal(swipe:IsShown(), true, "Victory Rush displays its own cooldown swipe")
    equal(swipe.timing[2], 10, "the swipe uses the spell cooldown duration")
    equal(swipe.hideNumbers, true, "the native cooldown cannot draw a second counter")
    cooldowns[402927] = { isActive = true, isOnGCD = true, duration = secret }
    alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Flush()
    alerts:OnEvent("UNIT_AURA", "player"); Flush()
    equal(alerts.cells[1].name.text, "Victory Rush", "Victorious shows the Victory Rush spell in combat")
    equal(alerts.cells[1].countdown.text, "5", "Victory Rush shows remaining native aura seconds")
    equal(swipe:IsShown(), false, "GCD-only timings remove the spell cooldown swipe")
    local object, objectCalls = {}, 0
    C_Spell.GetSpellCooldownDuration = function(id, ignoreGCD)
        equal(id, 402927, "opaque cooldown belongs to the proc spell")
        equal(ignoreGCD, true, "native duration explicitly excludes the GCD")
        return object
    end
    swipe.SetCooldownFromDurationObject = function(_, duration, clearIfZero)
        equal(duration, object, "pass the native duration through without reading its timing")
        equal(clearIfZero, true, "native widget clears a zero duration")
        objectCalls = objectCalls + 1
    end
    alerts:Paint(); alerts:Paint()
    equal(objectCalls, 1, "ordinary countdown refreshes do not restart the native swipe")
    equal(alerts.cells[1].countdown.text, "5", "native swipe binding leaves the proc number independent")
    C_Spell.GetSpellCooldownDuration, swipe.SetCooldownFromDurationObject = nil, nil
    do
        local opaque = {
            HasSecretValues = function() return true end,
            IsActive = function() error("must not inspect secret duration state") end,
        }
        C_Spell.GetSpellCooldownDuration = function(_, ignoreGCD)
            equal(ignoreGCD, true, "the opaque swipe excludes GCD")
            return opaque
        end
        swipe.SetCooldownFromDurationObject = function(_, duration)
            equal(duration, opaque, "engine receives the opaque cooldown unchanged")
        end
        usable[402927] = false
        cooldowns[402927] = { isEnabled = true, isActive = true, isOnGCD = false, duration = secret, startTime = secret }
        alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Flush()
        equal(alerts.frame:IsShown(), true, "public non-GCD flags show Victory Rush before it becomes usable")
        equal(swipe:IsShown(), true, "restricted spell time still draws the native swipe")
        equal(alerts.cells[1].countdown.text, "5", "a confirmed proc keeps its independent expiry")
        equal(alerts.cells[1].glow:IsShown(), false, "the ability stays visually on cooldown")
        usable[402927] = true
        alerts:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 402927); Flush()
        equal(alerts.frame:IsShown(), false, "a cast closes Victory Rush despite the previous aura and usability lingering")
        auras[402975].expirationTime = now + 8
        usable[402927] = false
        alerts:OnEvent("SPELL_UPDATE_COOLDOWN")
        alerts:OnEvent("UNIT_AURA", "player"); Flush()
        equal(alerts.cells[1].countdown.text, "8", "a fresh Victorious aura reopens the popup")
        equal(swipe:IsShown(), true, "a fresh proc shows its timer alongside the recharge")
        auras[402975] = nil
        alerts:OnEvent("UNIT_AURA", "player"); Flush()
        equal(alerts.frame:IsShown(), false, "an ongoing cooldown alone cannot keep the consumed popup visible")
        equal(swipe:IsShown(), false, "losing the proc also clears its swipe")
        cooldowns[402927] = { isActive = true, isOnGCD = true, duration = secret }
        alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Flush()
        equal(alerts.frame:IsShown(), false, "a GCD-only notification cannot create a recharge icon")
        equal(swipe:IsShown(), false, "the disappearing icon clears its native swipe")
        C_Spell.GetSpellCooldownDuration, swipe.SetCooldownFromDurationObject = nil, nil
        auras[402975], usable[402927] = { expirationTime = now + 5 }, true
    end
    SetCombat(false); alerts:OnEvent("PLAYER_REGEN_ENABLED")
    equal(alerts.frame:IsShown(), true, "Victory Rush stays visible after combat ends")
    Advance(1.1)
    equal(alerts.cells[1].countdown.text, "4", "Victory Rush keeps counting outside combat")
    do
        local originalDead, originalExists = UnitIsDeadOrGhost, UnitExists
        local deadTarget = true
        UnitIsDeadOrGhost = function(unit) return unit == "target" and deadTarget end
        UnitExists = function(unit) return unit == "target" end
        usable[402927] = false
        local started = now
        cooldowns[402927] = function()
            if now >= started + 0.5 then return { isActive = false, duration = secret } end
            return { isActive = true, duration = 0.5, startTime = started }
        end
        auras[402975] = { expirationTime = now + 20 }
        alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Flush()
        equal(alerts.frame:IsShown(), true, "Victorious can show the open window while the real cooldown runs")
        equal(swipe:IsShown(), true, "the cooldown swipe appears while the defeated target stays selected")
        Advance(0.6)
        equal(alerts.frame:IsShown(), true, "a clear cooldown displays the proc while the defeated target stays selected")
        equal(swipe:IsShown(), false, "cooldown expiry clears only the swipe")
        equal(alerts.cells[1].countdown.text, "20", "the popup uses the current Victorious expiry as soon as the cooldown clears")
        deadTarget = false
        alerts:OnEvent("PLAYER_TARGET_CHANGED"); Flush()
        equal(alerts.frame:IsShown(), true, "a confirmed Victorious window stays visible with an unusable living target")
        equal(alerts.cells[1].glow:IsShown(), false, "unusable Victory Rush has no availability glow")
        UnitIsDeadOrGhost, UnitExists = originalDead, originalExists
    end
    do
        local originalActionBar = C_ActionBar
        local originalGCD = cooldowns[61304]
        local actionDuration = { HasSecretValues = function() return true end }
        local bound, slot, calls = nil, 70, 0
        C_ActionBar = {
            FindSpellActionButtons = function(id)
                equal(id, 402927, "look up only the known Victory Rush spell")
                return { slot }
            end,
            GetActionCooldownDuration = function(action, ignoreGCD)
                equal(action, slot, "read the cooldown from the current action slot")
                equal(ignoreGCD, true, "action cooldown explicitly ignores the GCD")
                return actionDuration
            end,
        }
        swipe.SetCooldownFromDurationObject = function(_, duration)
            bound, calls = duration, calls + 1
        end
        auras[402975] = { expirationTime = now + 12 }
        cooldowns[402927] = { isActive = true, duration = secret, startTime = secret }
        alerts:OnEvent("ACTIONBAR_SLOT_CHANGED"); Flush()
        equal(alerts.frame:IsShown(), true, "a confirmed Victorious aura shows even without readable cooldown classification")
        equal(alerts.cells[1].countdown.text, "12", "the aura window keeps its own number")
        equal(alerts.cells[1].glow:IsShown(), false, "a blocked activation cannot glow")
        equal(bound, actionDuration, "the swipe receives the same opaque duration as the action slot")
        equal(swipe:IsShown(), true, "the action-slot swipe is visible while spell timing is restricted")
        equal(calls, 1, "the action slot binds once per refresh event")
        slot = 71
        alerts:OnEvent("ACTIONBAR_SLOT_CHANGED"); Flush()
        equal(swipe.actionSlot, 71, "moving Victory Rush refreshes the swipe source")
        equal(calls, 2, "the action slot change rebinds the cooldown")
        C_ActionBar.GetActionCooldown = function()
            return { isEnabled = true, isActive = true, duration = secret, startTime = secret }
        end
        cooldowns[61304] = { isActive = false, duration = secret }
        alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Flush()
        equal(alerts.victoryCooldownConfirmed, true, "an inactive global cooldown confirms the own recharge")
        equal(alerts.cells[1].countdown.text, "12", "the action cooldown still uses the real proc window")
        auras[402975] = nil
        alerts:OnEvent("UNIT_AURA", "player"); Flush()
        equal(alerts.frame:IsShown(), false, "even confirmed action cooldown cannot imply a proc window")
        cooldowns[61304].isActive = true
        alerts:OnEvent("SPELL_UPDATE_COOLDOWN"); Flush()
        equal(alerts.frame:IsShown(), false, "an ambiguous active GCD cannot authorize the recharge icon")
        cooldowns[61304] = originalGCD
        C_ActionBar, swipe.SetCooldownFromDurationObject = originalActionBar, nil
        cooldowns[402927] = { isActive = false, duration = secret }
        alerts:OnEvent("ACTIONBAR_SLOT_CHANGED"); Flush()
    end
    auras[402975], usable[402927] = nil, false
    alerts:OnEvent("UNIT_AURA", "player"); Flush()
    equal(alerts.frame:IsShown(), false, "consumed Victorious hides out of combat")
    auras[402975] = { expirationTime = now + 2 }
    usable[402927], cooldowns[402927] = true, { isActive = false, duration = secret }
    alerts:OnEvent("UNIT_AURA", "player"); Flush()
    equal(alerts.frame:IsShown(), true, "Victory Rush can first appear out of combat")
    Advance(2.1)
    equal(alerts.frame:IsShown(), false, "Victory Rush expires out of combat without an aura event")
    restrictions[402975], auras[402975] = true, { expirationTime = secret }
    usable[402927] = false
    alerts:OnEvent("UNIT_AURA", "player"); Flush()
    equal(alerts.frame:IsShown(), false, "restricted aura cannot invent an unavailable Victory Rush")
    SetCombat(true); alerts:OnEvent("PLAYER_REGEN_DISABLED")
    usable[402927] = true
    cooldowns[402927] = { isActive = true, duration = secret, startTime = secret }
    local restrictedDuration, applied = {}, nil
    C_Spell.GetSpellCooldownDuration = function() return restrictedDuration end
    swipe.SetCooldownFromDurationObject = function(_, duration) applied = duration end
    alerts:OnEvent("SPELL_UPDATE_USABLE"); Flush()
    equal(alerts.frame:IsShown(), true, "public usability can open Victory Rush with aura and cooldown timing restricted")
    equal(applied, restrictedDuration, "restricted timing still reaches the native swipe")
    equal(alerts.cells[1].glow:IsShown(), false, "the popup avoids a ready glow when the cooldown status is unclear")
    equal(alerts.cells[1].name.text, "Victory Rush", "native readiness can show Victory Rush with a restricted combat aura")
    equal(alerts.cells[1].countdown.text, "20", "restricted combat timing shows estimated seconds without a prefix")
    usable[402927] = false
    alerts:OnEvent("SPELL_UPDATE_USABLE"); Flush()
    equal(alerts.frame:IsShown(), false, "loss of castability ends the fallback")
    C_Spell.GetSpellCooldownDuration, swipe.SetCooldownFromDurationObject = nil, nil
    SetCombat(false); alerts:OnEvent("PLAYER_REGEN_ENABLED")
    do
        local create, addons = CreateFrame, C_AddOns
        local policy, sort, direction = CustomAuraContainerAuraProcessingPolicy, AuraContainerSortMethod, AuraContainerSortDirection
        local nativeContainer, durationText
        C_AddOns = { LoadAddOn = function() return true end }
        CustomAuraContainerAuraProcessingPolicy, AuraContainerSortMethod, AuraContainerSortDirection =
            { None = 0 }, { ExpirationOnly = 1 }, { Reverse = 1 }
        CreateFrame = function(kind, name, parent, template)
            local widget = create(kind, name, parent, template)
            widget.SetClipsChildren = function() end
            if kind == "AuraContainer" then
                nativeContainer = widget
                widget.SetEnabled = function(self, enabled) self.enabled = enabled end
                widget.SetEditModePreviewEnabled = function() end
                widget.SetAuraProcessingPolicy = function() end
                widget.SetUnit = function(self, unit) self.unit = unit end
                widget.AddAuraGroup = function(_, _, filter, options)
                    equal(filter, "HELPFUL", "native Victory Rush only accepts helpful auras")
                    equal(options.candidateFilters.includeSpellIDs[1], 402975, "the engine filters for Victorious")
                    local button = create("Button", nil, widget)
                    button.SetDurationText = function(_, label) durationText = label end
                    options.initializeFrame(button)
                end
                widget.IsShown = function() error("must never inspect native aura visibility") end
            end
            return widget
        end
        alerts:PrepareVictoryAura()
        equal(nativeContainer.unit, "player", "native fallback observes only the player")
        equal(nativeContainer.enabled and durationText ~= nil, true, "native container renders its own expiry text")
        local host, plate = alerts.victoryAura.host, alerts.victoryAura.plate
        local _, anchor, corner, x, y = plate.parent:GetPoint()
        equal(anchor, nativeContainer, "the cooldown mask follows native aura layout")
        equal(corner, "BOTTOMRIGHT", "the mask collapses in both dimensions when the aura is absent")
        equal((x or 0) == 0 and (y or 0) == 0, true, "the empty mask leaves no fixed-size strip")
        local _, _, _, insetX, insetY = plate:GetPoint()
        equal(insetX > 0 and insetY < 0, true, "the icon border stays inside the mask")
        local duration, applied = {}, nil
        C_Spell.GetSpellCooldownDuration = function(id, ignoreGCD)
            equal(id, 402927, "native fallback binds the spell cooldown separately")
            equal(ignoreGCD, true, "native fallback swipe excludes GCD")
            return duration
        end
        plate.cooldownSwipe.SetCooldownFromDurationObject = function(_, timing) applied = timing end
        cooldowns[402927] = { isActive = true, duration = secret }
        SetCombat(true); local count = created; alerts:OnEvent("PLAYER_REGEN_DISABLED")
        equal(host:IsShown(), true, "the engine can render Victorious even without a public opening")
        equal(applied, duration, "the masked icon uses the native spell swipe")
        equal(created, count, "combat creates no fallback widgets")
        SetCombat(false); alerts:OnEvent("PLAYER_REGEN_ENABLED")
        equal(host:IsShown(), false, "combat exit hands the display back to the regular popup")
        alerts.victoryAura, C_Spell.GetSpellCooldownDuration = nil, nil
        CreateFrame, C_AddOns = create, addons
        CustomAuraContainerAuraProcessingPolicy, AuraContainerSortMethod, AuraContainerSortDirection = policy, sort, direction
    end
    known[402927], infos[402927], cooldowns[402927] = nil, nil, nil
    C_UnitAuras, C_Secrets, GetShapeshiftForm = oldAuras, oldSecrets, oldStance
    alerts:Scan()
end
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
