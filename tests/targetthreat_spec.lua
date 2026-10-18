local Suite, equal, Frame, SetCombat = ...
local feature = Suite.TargetThreat
local names = { "TargetFrame", "UnitExists", "UnitCanAttack", "UnitIsPlayer", "UnitIsDeadOrGhost",
    "UnitDetailedThreatSituation", "C_Secrets", "CreateFrame", "C_Timer", "hooksecurefunc", "STANDARD_TEXT_FONT", "NineSliceUtil" }
local saved = {}; for _, name in ipairs(names) do saved[name] = _G[name] end
local oldDB, oldPending, oldApply = Suite.db, Suite.pending, Suite.Apply
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
local timers, constructed, hooks, queries, percentage = {}, 0, 0, 0, 0
local exists, hostile, player, dead, restricted, noRecord, reject = true, true, false, false, false, false, false
local function Secret()
    return setmetatable({ secret = true }, { __lt = function() error("secret comparison") end,
        __div = function() error("secret arithmetic") end, __tostring = function() error("secret formatting") end })
end
local function AccessibleFrame()
    local frame = Frame()
    frame.IsForbidden = function(self) return self.forbidden or false end
    frame.IsProtected = function(self) return self.protected or false end
    return frame
end
local owner = AccessibleFrame()
owner.shown, owner.protected, owner.buffsOnTop = true, true, false
local content, main = AccessibleFrame(), AccessibleFrame()
owner.TargetFrameContent, content.TargetFrameContentMain = content, main
main.ReputationColor, main.ManaBar = AccessibleFrame(), AccessibleFrame()
owner.nativeConfigure, owner.nativeBuffChanges, owner.nativeShows, owner.nativeHides = 0, 0, 0, 0
owner.ConfigureAuraContainer = function(self) self.nativeConfigure = self.nativeConfigure + 1 end
owner.UpdateSystemSettingBuffsOnTop = function(self) self.buffsOnTop = self.buffPreference; self.nativeBuffChanges = self.nativeBuffChanges + 1 end
owner.OnShow = function(self) self.nativeShows = self.nativeShows + 1 end
owner.OnHide = function(self) self.nativeHides = self.nativeHides + 1 end
for _, object in ipairs({ owner, content, main, main.ReputationColor, main.ManaBar }) do
    for _, method in ipairs({ "SetPoint", "ClearAllPoints", "SetParent", "SetSize", "SetWidth", "SetHeight" }) do
        object[method] = function() error("threat display must not change native frame geometry or ownership") end
    end
end
CreateFrame = function(...)
    assert(not InCombatLockdown(), "threat construction must wait outside combat")
    constructed = constructed + 1
    local frame = saved.CreateFrame(...)
    frame.IsForbidden = function(self) return self.forbidden or false end
    frame.IsProtected = function(self) return self.protected or false end
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterEvent = function(self, event) self.registered[event] = nil end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    for _, method in ipairs({ "SetPoint", "ClearAllPoints", "SetScale", "SetFrameLevel", "SetSize" }) do
        local original = frame[method]
        frame[method] = function(self, ...)
            assert(not InCombatLockdown(), "threat geometry must not change during combat")
            return original(self, ...)
        end
    end
    frame.CreateTexture = function()
        local texture = Frame()
        texture.SetColorTexture = function(self, ...) self.color = { ... } end
        texture.SetVertexColor = function(self, ...) self.vertexColor = { ... } end
        texture.SetAtlas = function(self, atlas) self.atlas = atlas end
        return texture
    end
    frame.CreateFontString = function() return Frame() end
    return frame
end
NineSliceUtil = {
    GetLayout = function(name) return name == "TooltipDefaultLayout" and {} or nil end,
    ApplyLayoutByName = function(frame, name)
        frame.nativeBorderLayout = name
        frame.Center = frame:CreateTexture(); frame.Center:Show()
        for _, piece in ipairs({ "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
            "TopEdge", "BottomEdge", "LeftEdge", "RightEdge" }) do frame[piece] = frame:CreateTexture() end
    end,
}
hooksecurefunc = function(...)
    assert(not InCombatLockdown(), "threat hooks install outside combat")
    hooks = hooks + 1; return saved.hooksecurefunc(...)
end
C_Timer = { NewTimer = function(delay, callback)
    equal(delay, 0.05, "threat changes coalesce over one short event window")
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
UnitExists = function(unit) equal(unit, "target", "threat checks only the current target"); return exists end
UnitCanAttack = function(a, b) equal(a .. ":" .. b, "player:target", "threat eligibility uses the current target"); return hostile end
UnitIsPlayer = function() return player end
UnitIsDeadOrGhost = function() return dead end
C_Secrets = { ShouldUnitThreatValuesBeSecret = function(a, b)
    equal(a .. ":" .. b, "player:target", "restriction predicate checks the exact threat pair")
    return restricted
end }
UnitDetailedThreatSituation = function(a, b)
    queries = queries + 1
    equal(a .. ":" .. b, "player:target", "threat values use only the current player and target tokens")
    if reject then error("native threat unavailable") end
    if noRecord then return end
    return Secret(), Secret(), percentage, Secret(), Secret()
end
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
local function Flush()
    local ready = timers; timers = {}
    for _, timer in ipairs(ready) do if not timer.cancelled then timer.callback() end end
end
local function LeaveCombat()
    SetCombat(false)
    local pending = Suite.pending; Suite.pending = {}
    for _, callback in pairs(pending) do callback() end
end
local function Fire(event, unit) feature:OnEvent(event, unit) end
TargetFrame = nil
equal(Suite.db.targetThreat, false, "target threat begins independently off")
feature:Apply(); equal(constructed, 0, "disabled threat creates no frames")
equal(queries, 0, "disabled threat makes no data queries")
Suite.db.targetThreat = true; SetCombat(true); feature:Apply()
equal(constructed, 0, "first combat enable defers construction")
equal(type(Suite.pending.targetThreat), "function", "first enable uses the core combat queue")
Suite.db.targetThreat = false; feature:Apply(); LeaveCombat()
equal(constructed, 0, "disable cancels pending first activation")
Suite.db.targetThreat = true; feature:Apply()
equal(constructed, 1, "missing native target frame needs only the discovery controller")
TargetFrame = owner; Fire("ADDON_LOADED", "Blizzard_UnitFrame"); Flush()
equal(constructed, 2, "late target discovery creates one passive square")
equal(hooks, 3, "native aura preference and scale use narrow post-hooks")
equal(feature.events.registered.ADDON_LOADED, nil, "late-load watcher retires after attachment")
equal(feature.square:GetParent(), UIParent, "indicator remains outside the protected target child hierarchy")
equal(feature.square.width, 60, "indicator is a compact horizontal rectangle")
equal(feature.square.height, 24, "indicator is shorter than the former square")
equal(feature.square.nativeBorderLayout, "TooltipDefaultLayout", "indicator uses Blizzard's native tooltip border")
equal(feature.square.Center:IsShown(), false, "native solid center cannot cover the translucent background")
equal(feature.square.background.texture, "Interface\\ChatFrame\\ChatFrameBackground", "indicator uses native chat background art")
equal(feature.square.background.vertexColor[4] < 0.5, true, "chat background stays translucent")
equal(feature.square.text.textColor[4], 1, "translucency does not fade the percentage text")
equal(feature.square.mouseEnabled, false, "indicator preserves native click input")
equal(feature.square.text.text, "0%", "ordinary zero threat displays explicitly")
equal(feature.square.fill.color[1], 0.32, "zero threat begins grey")
equal(feature.square.point[1], "BOTTOMLEFT", "normal auras leave the indicator above the frame")
equal(feature.square.point[2], main.ReputationColor, "upper attachment uses the native name strip")
equal(feature.square.OnUpdate, nil, "indicator has no idle update script")
local previous = feature.square.fill.color[1]
for _, value in ipairs({ 25, 50, 70, 85, 100 }) do
    percentage = value; Fire("UNIT_THREAT_LIST_UPDATE", "target"); Flush()
    equal(feature.square.text.text, value .. "%", "live scaled threat percentage updates")
    equal(feature.square.fill.color[1] >= previous, true, "increasing threat warms the square")
    previous = feature.square.fill.color[1]
end
equal(feature.square.fill.color[1], 0.92, "full threat reaches red")
equal(feature.square.fill.color[2] < 0.12, true, "full threat has a low green channel")
equal(feature.square.fill.color[4] >= 0.75 and feature.square.fill.color[4] < 1, true, "full-threat red is prominent while still translucent")
percentage = 49.6; Fire("UNIT_THREAT_SITUATION_UPDATE", "player"); Flush()
equal(feature.square.text.text, "50%", "readable percentages round to whole numbers")
for _ = 1, 50 do Fire("UNIT_THREAT_LIST_UPDATE", "target") end
equal(#timers, 1, "threat event bursts share one worker"); Flush()
local count = queries
Fire("UNIT_THREAT_LIST_UPDATE", Secret()); Fire("UNIT_THREAT_LIST_UPDATE", "party1"); Flush()
equal(queries, count, "unreadable and unrelated event units do not trigger work")
Fire("UNIT_HEALTH", "player"); Flush()
equal(queries, count, "player health changes do not create unrelated threat work")
restricted = true; count = queries; feature:Update()
equal(queries, count, "restricted threat predicate prevents querying hidden values")
equal(feature.square.text.text, "--", "restricted data displays neutral unknown rather than zero")
equal(feature.square.fill.color[1], 0.32, "restricted data clears stale threat color")
restricted = Secret(); feature:Update(); equal(queries, count, "unreadable predicate also prevents querying")
restricted = false
for _, invalid in ipairs({ Secret(), -1, 101, math.huge, 0 / 0, "90" }) do
    percentage = invalid; feature:Update()
    equal(feature.square.text.text, "--", "restricted or invalid threat never reaches arithmetic or formatting")
end
noRecord = true; feature:Update(); equal(feature.square.text.text, "--", "no native threat record is not a fake zero")
noRecord, reject = false, true; feature:Update(); equal(feature.square.text.text, "--", "rejected native threat query is contained")
reject, percentage = false, 80
local predicate = C_Secrets.ShouldUnitThreatValuesBeSecret; C_Secrets.ShouldUnitThreatValuesBeSecret = nil
count = queries; feature:Update(); equal(queries, count, "missing predicate cannot authorize a query")
C_Secrets.ShouldUnitThreatValuesBeSecret = predicate
for _, state in ipairs({ "friendly", "player", "dead", "missing", "hidden" }) do
    hostile, player, dead, exists, owner.shown = state ~= "friendly", state == "player", state == "dead", state ~= "missing", state ~= "hidden"
    feature:Update(); equal(feature.square:IsShown(), false, "ineligible target hides threat: " .. state)
end
hostile, player, dead, exists, owner.shown = true, false, false, true, true
for _, state in ipairs({ "exists", "hostile", "player", "dead" }) do
    exists, hostile, player, dead = true, true, false, false
    if state == "exists" then exists = Secret()
    elseif state == "hostile" then hostile = Secret()
    elseif state == "player" then player = Secret()
    else dead = Secret() end
    count = queries; feature:Update()
    equal(feature.square:IsShown(), false, "unreadable target eligibility hides the display")
    equal(queries, count, "unreadable eligibility never permits a threat query")
end
hostile, player, dead, exists = true, false, false, true
feature:Update()
owner.buffPreference = true; owner:UpdateSystemSettingBuffsOnTop(); Flush()
equal(owner.nativeBuffChanges, 1, "native buffs-on-top handler retains ownership")
equal(feature.square.point[1], "TOPRIGHT", "buffs on top moves the indicator below and outside the left edge")
equal(feature.square.point[2], main.ManaBar, "lower square clears the native health and power bars")
equal(feature.square.point[4], -6, "lower square stays outward from the native cast bar")
equal(feature.square:IsShown(), true, "lower square still displays current threat")
owner.scale = 1.5; owner:SetScale(1.5); Flush()
equal(feature.square.scale, 1.5 / UIParent:GetEffectiveScale(), "indicator follows native target scale")
SetCombat(true); percentage = 95; Fire("UNIT_THREAT_LIST_UPDATE", "target"); Flush()
equal(feature.square.text.text, "95%", "prepared unprotected indicator updates during combat")
owner.buffPreference = false; owner:UpdateSystemSettingBuffsOnTop(); Flush()
equal(feature.square.point[1], "TOPRIGHT", "combat aura changes do not reanchor")
equal(feature.square:IsShown(), false, "square hides while its old position would overlap moved auras")
equal(type(Suite.pending.targetThreatLayout), "function", "combat layout waits in core queue")
LeaveCombat(); equal(feature.square.point[1], "BOTTOMLEFT", "combat exit applies current aura-side preference")
equal(feature.square:IsShown(), true, "square returns after its safe layout")
SetCombat(true); feature.square.protected = true; exists = false; feature:Update()
equal(type(Suite.pending.targetThreatHide), "function", "unexpected protected widget visibility waits through combat")
LeaveCombat(); equal(feature.square:IsShown(), false, "deferred protected visibility clears on combat exit")
feature.square.protected, exists = false, true; feature:Update()
percentage = 5; Fire("PLAYER_TARGET_CHANGED")
equal(feature.square.text.text, "5%", "target changes replace old percentage immediately")
owner.buffsOnTop = Secret(); owner:ConfigureAuraContainer(); Flush()
equal(feature.square:IsShown(), false, "unreadable aura placement hides rather than guesses")
owner.buffsOnTop = false; owner:ConfigureAuraContainer(); Flush()
owner.shown = false; owner.OnHide(owner)
equal(owner.nativeHides, 1, "original native hide handler remains intact")
equal(feature.square:IsShown(), false, "native frame hide immediately hides the square")
owner.shown = true; owner.OnShow(owner); Flush()
equal(owner.nativeShows, 1, "original native show handler remains intact")
equal(feature.square:IsShown(), true, "native show restores the current threat display")
percentage = 10; Fire("UNIT_THREAT_LIST_UPDATE", "target"); local stale = timers[1]
Suite.db.targetThreat = false; feature:Apply(); stale.callback(); Flush()
equal(feature.square:IsShown(), false, "disable cancels stale threat display work")
equal(next(feature.events.registered), nil, "disable unregisters all feature events")
count = queries; owner:ConfigureAuraContainer(); Fire("UNIT_THREAT_LIST_UPDATE", "target"); Flush()
equal(queries, count, "disabled hooks and events are idle")
Suite.db.targetThreat = true; feature:Apply()
equal(constructed, 2, "reenabling reuses its two owned frames")
equal(hooks, 3, "reenabling never duplicates native hooks")
Suite.GUI:OpenPage("unitframes")
equal(Suite.GUI.rows[2].label.text, "Target threat indicator", "threat has an independent unit-frame setting")
equal(Suite.SettingsCatalog:Search("target aggro percent")[1].key, "targetThreat", "threat percentage is searchable")
Suite.Apply = function() feature:Apply() end
Suite.GUI.rows[2].OnClick(); equal(Suite.db.targetThreat, false, "GUI saves independent threat disabling")
equal(Suite.db.classHealthBars, false, "threat toggle preserves class health colors")
Suite.db.targetThreat = true; feature:Apply(); Fire("UNIT_THREAT_LIST_UPDATE", "target"); Fire("PLAYER_LOGOUT"); Flush()
equal(feature.square:IsShown(), false, "logout cancels work and hides the display")
equal(next(feature.events.registered), nil, "logout releases engine event subscriptions")
Suite.db.targetThreat = false; feature:Apply()
Suite.db, Suite.pending, Suite.Apply = oldDB, oldPending, oldApply
for _, name in ipairs(names) do _G[name] = saved[name] end
SetCombat(false)
