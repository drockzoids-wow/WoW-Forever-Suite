-- Native fill pixels and tint multiply. Check the rendered color, lifecycle and protected boundaries.
local Suite, equal, Frame, SetCombat = ...
local module = Suite.UnitFrames
local names = { "PlayerFrame", "TargetFrame", "TargetFrameToT", "FocusFrame", "FocusFrameToT", "PartyFrame", "CompactRaidFrame1", "PetFrame" }
local saved = {}
for _, name in ipairs(names) do saved[name] = _G[name]; _G[name] = nil end
local oldCreate, oldTimer, oldHook = CreateFrame, C_Timer, hooksecurefunc
local oldPlayer, oldClass, oldConnected = UnitIsPlayer, UnitClass, UnitIsConnected
local oldSetUnit, oldColors = UnitFrameHealthBar_SetUnit, RAID_CLASS_COLORS
local oldPending, oldSetting, oldSet = Suite.pending, Suite.db.classHealthBars, Suite.Set
local timers, constructed, hooks, queries, inCombat = {}, 0, 0, 0, false
local secret = { secret = true }
local units = {
    player = { class = "MAGE" }, target = { class = "PALADIN" }, targettarget = { class = "PRIEST" },
    focus = { class = "WARRIOR" }, npc = { player = false, class = "WARRIOR" }, vehicle = { player = false },
}
RAID_CLASS_COLORS = {
    MAGE = { r = 0.25, g = 0.78, b = 0.92 }, PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
    PRIEST = { r = 1, g = 1, b = 1 }, WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
}
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
    assert(not inCombat, "unit frame feature must not create frames in combat")
    constructed = constructed + 1
    local frame = oldCreate(...)
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    return frame
end
hooksecurefunc = function(...)
    assert(not inCombat, "unit frame hooks install outside combat")
    hooks = hooks + 1
    return oldHook(...)
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
UnitIsPlayer = function(unit)
    assert(type(unit) == "string", "only query readable unit tokens")
    queries = queries + 1
    local data = units[unit]
    if not data then return false end
    if data.player == nil then return true end
    return data.player
end
UnitIsConnected = function(unit)
    local data = units[unit]
    if not data then return false end
    if data.connected == nil then return true end
    return data.connected
end
UnitClass = function(unit) return secret, units[unit] and units[unit].class end
UnitFrameHealthBar_SetUnit = function(bar, unit) bar.unit = unit end
local function NativeFrame(unit, atlas)
    local frame, bar, texture = Frame(), Frame(), Frame()
    frame.shown, bar.unit, bar.lockColor = true, unit, true
    frame.nativeShows = 0
    frame.OnShow = function(self) self.nativeShows = self.nativeShows + 1 end
    frame.IsForbidden = function(self) return self.forbidden or false end
    bar.color = { 1, 1, 1, 1 }
    bar.GetStatusBarColor = function(self) return unpack(self.color) end
    bar.GetStatusBarTexture = function() return texture end
    bar.SetStatusBarColor = function(self, r, g, b, a)
        self.color = { r, g, b, a or 1 }
        texture.vertex = self.color
    end
    texture.atlas, texture.pixels, texture.mask = atlas, { 0.2, 0.8, 0.3 }, {}
    texture.drawLayer, texture.drawSublevel = "BACKGROUND", 0
    texture.GetDrawLayer = function(self) return self.drawLayer, self.drawSublevel end
    texture.GetAtlas = function(self) return self.atlas end
    texture.SetAtlas = function(self, value, useSize)
        assert(useSize ~= true, "Suite must never change native texture dimensions")
        self.atlas, self.asset, self.pixels, self.coords = value, nil, { 0.2, 0.8, 0.3 }, { 0.2, 0.8, 0.3, 0.7 }
    end
    texture.SetTexture = function(self, value)
        self.atlas, self.asset = nil, value
        self.pixels = value == "Interface\\Buttons\\WHITE8X8" and { 1, 1, 1 } or { 0.2, 0.8, 0.3 }
    end
    texture.SetTexCoord = function(self, ...) self.coords = { ... } end
    texture.IsForbidden = frame.IsForbidden
    for _, object in ipairs({ frame, bar, texture }) do
        for _, method in ipairs({ "SetPoint", "ClearAllPoints", "SetSize", "SetWidth", "SetHeight", "SetScale", "SetParent", "SetAttribute", "SetStatusBarTexture" }) do
            object[method] = function() error("class colors must not alter native geometry, parents or secure configuration") end
        end
    end
    bar.GetValue = function() error("Suite must not read health values") end
    bar.GetMinMaxValues = bar.GetValue
    bar.nativeValueChanges = 0
    bar.OnValueChanged = function(self) self.nativeValueChanges = self.nativeValueChanges + 1 end
    return frame, bar, texture
end
local player, playerBar, playerTexture = NativeFrame("player", "native-player")
PlayerFrame = player
player.PlayerFrameContent = { PlayerFrameContentMain = { HealthBarsContainer = { HealthBar = playerBar } } }
local lossFrame, lossBar, lossTexture = NativeFrame("player", "native-loss")
playerBar.AnimatedLossBar = lossBar
lossBar.shown = false
lossBar:SetStatusBarColor(1, 0, 0, 1)
local lossMask, lossAtlas = lossTexture.mask, lossTexture.atlas
local predictionLayer = { "BACKGROUND", 1 }
playerBar.MyHealPredictionBar = { Fill = { GetDrawLayer = function() return unpack(predictionLayer) end } }
local target, targetBar, targetTexture = NativeFrame("target", "native-target")
TargetFrame = target
target.TargetFrameContent = { TargetFrameContentMain = { HealthBarsContainer = { HealthBar = targetBar } } }
local tot, totBar, totTexture = NativeFrame("targettarget", "native-tot")
TargetFrameToT, tot.HealthBar = tot, totBar
local focus, focusBar, focusTexture = NativeFrame("focus", "native-focus")
FocusFrame = focus
focus.TargetFrameContent = { TargetFrameContentMain = { HealthBarsContainer = { HealthBar = focusBar } } }
local excluded = {}
for _, name in ipairs({ "FocusFrameToT", "PartyFrame", "CompactRaidFrame1", "PetFrame" }) do
    local frame, bar, texture = NativeFrame("player", "native-excluded")
    frame.HealthBar = bar; _G[name] = frame; excluded[#excluded + 1] = texture
end
local originalMask = playerTexture.mask
local function ExactColor(bar, texture, class, label)
    local expected = RAID_CLASS_COLORS[class]
    for i, channel in ipairs({ "r", "g", "b" }) do
        equal(bar.color[i] * texture.pixels[i], expected[channel] * 0.75, label .. " rendered " .. channel .. " uses softened class color without native color multiplication")
    end
    equal(bar.color[4], 1, label .. " opaque fill prevents underlying color blend")
end
Suite.pending, Suite.db.classHealthBars = {}, false
module:Apply()
equal(constructed, 0, "disabled health colors construct nothing")
equal(hooks, 0, "disabled health colors install no hooks")
equal(queries, 0, "disabled health colors make no unit queries")
equal(Suite.defaults.classHealthBars, false, "health colors start off independently")
Suite.db.classHealthBars = true
Combat(true); module:Apply()
equal(constructed, 0, "first combat enable defers construction")
equal(hooks, 0, "first combat enable defers hooks")
Suite.db.classHealthBars = false; module:Apply(); LeaveCombat()
equal(constructed, 0, "disable cancels deferred first enable")
Suite.db.classHealthBars = true; module:Apply()
equal(constructed, 1, "enabled feature owns only its event controller")
ExactColor(playerBar, playerTexture, "MAGE", "player")
ExactColor(targetBar, targetTexture, "PALADIN", "target")
ExactColor(totBar, totTexture, "PRIEST", "target of target")
ExactColor(focusBar, focusTexture, "WARRIOR", "focus")
equal(playerTexture.mask, originalMask, "native fill texture retains its original mask")
equal(playerTexture.coords[1], 0, "neutral fill resets atlas crop")
equal(playerTexture.coords[2], 1, "neutral fill uses full texture")
equal(playerBar.lockColor, true, "native lockColor field is unchanged")
equal(player.OnUpdate, nil, "Suite adds no frame polling")
-- Model a visible loss texture winning a same-layer tie when damage starts.
-- No health values are read: native callbacks receive an opaque value unchanged.
Combat(true)
lossBar:Show()
if lossBar.OnShow then lossBar.OnShow(lossBar) end
playerBar.OnValueChanged(playerBar, secret)
local visibleTexture = lossTexture.drawLayer == playerTexture.drawLayer
    and lossTexture.drawSublevel >= playerTexture.drawSublevel and lossTexture or playerTexture
equal(visibleTexture, playerTexture, "damage-loss animation cannot cover current class-colored health")
equal(lossTexture.mask, lossMask, "loss animation retains its native mask")
equal(lossTexture.atlas, lossAtlas, "loss animation retains its native artwork")
equal(lossBar.color[1], 1, "damage-loss trail retains red tint")
equal(playerTexture.drawSublevel, 0, "primary fill retains native draw sublevel")
equal(predictionLayer[2], 1, "prediction overlay keeps its native layer above the primary fill")
equal(playerBar.nativeValueChanges, 1, "original native value callback still runs with opaque values")
units.player.class = "WARRIOR"
for _ = 1, 50 do
    lossTexture:SetDrawLayer("BACKGROUND", 0)
    playerBar.OnValueChanged(playerBar, secret)
end
ExactColor(playerBar, playerTexture, "WARRIOR", "repeated opaque combat health updates")
equal(lossTexture.drawSublevel, -1, "native loss-layer resets settle behind current fill in the same callback")
equal(playerBar.nativeValueChanges, 51, "native value updates are never suppressed")
equal(lossBar.OnUpdate, nil, "loss layering adds no animation polling")
lossTexture:SetDrawLayer(secret, secret)
equal(lossTexture.drawLayer, secret, "secret native loss layer is left untouched")
lossTexture:SetDrawLayer("ARTWORK", 2)
equal(lossTexture.drawLayer, "BACKGROUND", "readable native loss layer resumes safe ordering")
local primaryLayer = playerTexture.GetDrawLayer
playerTexture.GetDrawLayer = function() return "BACKGROUND", secret end
module:RefreshRecord(module.records[playerBar])
equal(lossTexture.drawLayer, "ARTWORK", "unknown primary layer restores the known native loss layer")
equal(lossTexture.drawSublevel, 2, "unknown primary layer never participates in sublevel arithmetic")
playerTexture.GetDrawLayer = function() return "BACKGROUND", -8 end
module:RefreshRecord(module.records[playerBar])
equal(lossTexture.drawSublevel, 2, "lower sublevel bound never wraps or alters the primary fill")
playerTexture.GetDrawLayer = primaryLayer
module:RefreshRecord(module.records[playerBar])
equal(lossTexture.drawSublevel, -1, "readable primary layering resumes correction")
lossTexture.drawLayer, lossTexture.drawSublevel = "BACKGROUND", 0 -- Native renderer update, bypassing Lua texture setters.
lossBar.OnValueChanged(lossBar, secret)
equal(lossTexture.drawSublevel, -1, "independent native loss-value callbacks also settle texture order")
equal(lossBar.nativeValueChanges, 1, "native loss-value callback retains its opaque value path")
units.player.class = "MAGE"; module:RefreshRecord(module.records[playerBar])
Combat(false); lossBar:Hide()
player.OnShow(player)
equal(player.nativeShows, 1, "native show script remains intact")
for _, texture in ipairs(excluded) do equal(texture.atlas, "native-excluded", "party raid pets and focus target remain native") end
targetBar:SetStatusBarColor(0, 1, 0, 0.5)
ExactColor(targetBar, targetTexture, "PALADIN", "native recolor overridden")
targetTexture:SetAtlas("native-target-new", false)
ExactColor(targetBar, targetTexture, "PALADIN", "native atlas replacement overridden")
units.target.class = "WARRIOR"
module.events.OnEvent(module.events, "PLAYER_TARGET_CHANGED")
for _ = 1, 500 do module.events.OnEvent(module.events, "UNIT_NAME_UPDATE", "target") end
equal(TimerCount(), 1, "identity event bursts share one cancellable refresh")
Flush(); ExactColor(targetBar, targetTexture, "WARRIOR", "new target class")
units.targettarget.class = "MAGE"
module.events.OnEvent(module.events, "UNIT_TARGET", "target"); Flush()
ExactColor(totBar, totTexture, "MAGE", "new target of target")
UnitFrameHealthBar_SetUnit(targetBar, "npc")
equal(targetTexture.atlas, "native-target-new", "NPC restores latest native artwork")
equal(targetBar.color[1], 0, "NPC restores latest native tint red")
equal(targetBar.color[2], 1, "NPC restores latest native tint green")
equal(targetBar.color[4], 0.5, "NPC restores native alpha")
UnitFrameHealthBar_SetUnit(targetBar, "target")
ExactColor(targetBar, targetTexture, "WARRIOR", "return to player")
UnitFrameHealthBar_SetUnit(playerBar, "vehicle")
equal(playerTexture.atlas, "native-player", "vehicle bar uses native fill")
equal(lossTexture.drawLayer, "ARTWORK", "vehicle restores latest native loss layer")
equal(lossTexture.drawSublevel, 2, "vehicle restores latest native loss sublevel")
UnitFrameHealthBar_SetUnit(playerBar, "player")
units.focus.connected = false; module:Refresh()
equal(focusTexture.atlas, "native-focus", "offline unit returns to native appearance")
units.focus.connected = true; module:Refresh()
ExactColor(focusBar, focusTexture, "WARRIOR", "reconnected focus")
for _, change in ipairs({ "class", "player", "connected" }) do
    local old = units.focus[change]; units.focus[change] = secret; module:Refresh()
    equal(focusTexture.atlas, "native-focus", "restricted " .. change .. " does not retain previous class fill")
    units.focus[change] = old; module:Refresh()
end
local oldUnit = focusBar.unit; focusBar.unit = secret; module:Refresh()
equal(focusTexture.atlas, "native-focus", "restricted token is never queried")
focusBar.unit = oldUnit; module:Refresh()
units.focus.class = "UNKNOWN"; module:Refresh()
equal(focusTexture.atlas, "native-focus", "unknown class does not retain previous fill")
units.focus.class = "WARRIOR"; module:Refresh()
local oldGreen = RAID_CLASS_COLORS.WARRIOR.g
RAID_CLASS_COLORS.WARRIOR.g = secret; module:Refresh()
equal(focusTexture.atlas, "native-focus", "restricted color channel is never multiplied")
RAID_CLASS_COLORS.WARRIOR.g = oldGreen; module:Refresh()
targetBar:SetStatusBarColor(secret, secret, secret, secret)
equal(targetTexture.atlas, "native-target-new", "secret native color stays on native texture path")
equal(targetBar.color[1], secret, "secret native tint is preserved without stale restoration")
targetBar:SetStatusBarColor(1, 1, 1, 1)
ExactColor(targetBar, targetTexture, "WARRIOR", "readable native color resumes class fill")
targetTexture:SetTexture("custom-texture")
equal(targetTexture.asset, "custom-texture", "external texture replacement is not overwritten by stale artwork")
equal(targetBar.color[1], 1, "external texture replacement restores native tint")
targetTexture:SetAtlas("native-target-final", false)
ExactColor(targetBar, targetTexture, "WARRIOR", "native atlas returns")
Combat(true)
local beforeFrames, beforeHooks = constructed, hooks
units.focus.class = "PRIEST"
module.events.OnEvent(module.events, "PLAYER_FOCUS_CHANGED")
ExactColor(focusBar, focusTexture, "PRIEST", "combat identity refresh")
targetBar:SetStatusBarColor(0, 1, 0)
ExactColor(targetBar, targetTexture, "WARRIOR", "combat native color overridden")
equal(constructed, beforeFrames, "combat colors create no frames")
equal(hooks, beforeHooks, "combat colors install no hooks")
equal(TimerCount(), 0, "combat colors schedule no timers")
Suite.db.classHealthBars = false; module:Apply()
equal(playerTexture.atlas, "native-player", "combat disable restores player artwork")
equal(lossTexture.drawLayer, "ARTWORK", "combat disable restores loss layer without changing animation")
equal(lossTexture.drawSublevel, 2, "combat disable restores latest native loss sublevel")
equal(targetTexture.atlas, "native-target-final", "combat disable restores latest target artwork")
equal(targetBar.color[2], 1, "combat disable restores native tint")
equal(next(module.events.registered), nil, "disable removes feature event registrations")
equal(Suite.pending.unitFrames, nil, "disable removes deferred discovery")
local beforeDisabledQueries = queries
lossTexture:SetDrawLayer("BACKGROUND", 3)
playerBar.OnValueChanged(playerBar, secret)
targetBar:SetStatusBarColor(0.4, 0.5, 0.6, 0.7)
targetTexture:SetAtlas("native-disabled-change", false)
UnitFrameHealthBar_SetUnit(targetBar, "target")
equal(queries, beforeDisabledQueries, "retained disabled hooks make no unit queries")
LeaveCombat(); Suite.db.classHealthBars = true; module:Apply()
ExactColor(targetBar, targetTexture, "WARRIOR", "re-enable after native changes")
Suite.db.classHealthBars = false; module:Apply()
equal(lossTexture.drawSublevel, 3, "re-enable captures loss-layer changes made while disabled")
equal(targetTexture.atlas, "native-disabled-change", "re-enable captures current native atlas")
equal(targetBar.color[1], 0.4, "re-enable captures current native tint")
equal(targetBar.color[4], 0.7, "re-enable captures current native alpha")
Suite.db.classHealthBars = true; module:Apply()
module.events.OnEvent(module.events, "PLAYER_TARGET_CHANGED")
Suite.db.classHealthBars = false; module:Apply(); Flush()
equal(targetTexture.atlas, "native-disabled-change", "disable cancels queued recolor")
equal(TimerCount(), 0, "disabled feature retains no timer")
Suite.Set = function(key, value)
    equal(key, "classHealthBars", "GUI changes only the health bar preference")
    Suite.db[key] = value
    module:Apply()
end
Suite.GUI:OpenPage("unitframes")
equal(Suite.GUI.page, "unitframes", "unit frames settings open directly")
equal(Suite.GUI.rows[1].label.text, "Class colored health bars", "unit frame setting has clear wording")
equal(Suite.GUI.tabs.unitframes.label.text, "Unit Frames", "unit frames have a named sidebar page")
equal(-Suite.GUI.tabs.unitframes.point[3] + Suite.GUI.tabs.unitframes.height < Suite.GUI.frame.height - 77, true, "all eleven sidebar entries fit")
Suite.GUI.rows[1].OnClick()
ExactColor(playerBar, playerTexture, "MAGE", "settings enable")
Suite.GUI.rows[1].OnClick()
equal(playerTexture.atlas, "native-player", "settings disable restores native fill")
local late, lateBar, lateTexture = NativeFrame("focus", "native-late-focus")
late.TargetFrameContent = { TargetFrameContentMain = { HealthBarsContainer = { HealthBar = lateBar } } }
late.forbidden = true; FocusFrame = late
Suite.db.classHealthBars = true; module:Apply()
equal(module.records[lateBar], nil, "forbidden native frames are not probed or hooked")
late.forbidden = false
Combat(true); module.events.OnEvent(module.events, "ADDON_LOADED", "Blizzard_UnitFrame")
equal(module.records[lateBar], nil, "late combat discovery defers hooks")
equal(lateTexture.atlas, "native-late-focus", "untracked combat frame retains native appearance")
LeaveCombat()
ExactColor(lateBar, lateTexture, "PRIEST", "late frame discovered after combat")
Suite.db.classHealthBars = false; module:Apply()
equal(lateTexture.atlas, "native-late-focus", "late frame restores native appearance")
Suite.GUI.frame:Hide()
CreateFrame, C_Timer, hooksecurefunc = oldCreate, oldTimer, oldHook
UnitIsPlayer, UnitClass, UnitIsConnected = oldPlayer, oldClass, oldConnected
UnitFrameHealthBar_SetUnit, RAID_CLASS_COLORS = oldSetUnit, oldColors
Suite.pending, Suite.db.classHealthBars, Suite.Set = oldPending, oldSetting, oldSet
for _, name in ipairs(names) do _G[name] = saved[name] end
Combat(false)
