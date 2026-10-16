-- Re-enable must capture the current native layout; disabled hooks stay idle.
local Suite, equal, Frame, SetCombat = ...
local map, zone, clock = Suite.Minimap, MinimapCluster.ZoneTextButton, TimeManagerClockTicker
local oldTimers, oldShape, oldHook = C_Timer, GetMinimapShape, hooksecurefunc
local timers, scheduled = {}, 0
local addedHooks = 0
hooksecurefunc = function(...)
    addedHooks = addedHooks + 1
    oldHook(...)
end
C_Timer = { NewTimer = function(_, callback)
    scheduled = scheduled + 1
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
C_Timer.After = function(delay, callback) C_Timer.NewTimer(delay, callback) end
local function Flush()
    local current = timers; timers = {}
    for _, timer in ipairs(current) do if not timer.cancelled then timer.callback() end end
end
local nativeShape = function() return "ROUND" end
GetMinimapShape = nativeShape
local disabledScheduled = scheduled
zone:SetSize(133, 15); zone:SetScale(0.9)
zone:SetPoint("BOTTOMLEFT", MinimapCluster, "BOTTOMLEFT", 5, -7)
clock:SetFont("Fonts\\ARIALN.TTF", 13, "OUTLINE")
MinimapCluster:SetClampedToScreen(false)
MinimapCluster.BorderTop:Hide()
for _ = 1, 100 do zone:SetPoint("BOTTOMLEFT", MinimapCluster, "BOTTOMLEFT", 5, -7) end
equal(scheduled, disabledScheduled, "disabled minimap hooks do not queue layout work")
Suite.db.squareMinimap = true; map:Apply()
Suite.db.squareMinimap = false; map:Apply()
equal(zone.width, 133, "minimap re-enable restores the latest native width")
equal(zone.height, 15, "minimap re-enable restores the latest native height")
equal(zone.scale, 0.9, "minimap re-enable restores the latest native scale")
equal(zone.point[1], "BOTTOMLEFT", "minimap re-enable restores the latest native anchor")
equal(zone.point[4], 5, "minimap re-enable restores the latest native offset")
equal(clock.fontSize, 13, "minimap re-enable restores the latest native clock font")
equal(clock.fontFlags, "OUTLINE", "minimap re-enable restores the latest native font flags")
equal(MinimapCluster:IsClampedToScreen(), false, "minimap re-enable restores current native clamping")
equal(MinimapCluster.BorderTop:IsShown(), false, "minimap re-enable retains native hidden artwork")
equal(GetMinimapShape, nativeShape, "minimap re-enable restores the current shape provider")
equal(next(map.widgets), nil, "restored header releases old geometry snapshots")
equal(addedHooks, 0, "minimap re-enable reuses existing native hooks")

-- Build 70425 puts zone-button state art in its own BACKGROUND layer and adds
-- a separately scaled day/night frame. Native hover and cycle events retain ownership.
do
    local oldBorder, oldContainer = MinimapCluster.BorderTop, MinimapCluster.MinimapContainer
    local oldState, oldAdd = zone.StateTexture, zone.AddTexture
    local oldEnabled, oldDisable, oldEnable = zone.IsDrawLayerEnabled, zone.DisableDrawLayer, zone.EnableDrawLayer
    local oldButtonState = zone.OnButtonStateChanged
    local backgroundEnabled, layerWrites = true, 0
    zone.IsDrawLayerEnabled = function(_, layer) assert(layer == "BACKGROUND"); return backgroundEnabled end
    zone.DisableDrawLayer = function()
        assert(not InCombatLockdown(), "zone layer changes must defer through combat")
        backgroundEnabled = false; layerWrites = layerWrites + 1
    end
    zone.EnableDrawLayer = function()
        assert(not InCombatLockdown(), "zone layer restoration must defer through combat")
        backgroundEnabled = true; layerWrites = layerWrites + 1
    end
    local function Art(shown)
        local art = Frame()
        art.parent = zone; art:SetShown(shown)
        art.GetDrawLayer = function() return "BACKGROUND", 0 end
        return art
    end
    zone.StateTexture, zone.AddTexture = Art(true), Art(false)
    zone.OnButtonStateChanged = function(self, active)
        self.StateTexture.atlas = "ui-hud-minimap-header-button"
        self.AddTexture:SetShown(active)
    end
    local click, stateHandler = zone:GetScript("OnClick"), zone.OnButtonStateChanged
    local container = CreateFrame("Frame", nil, MinimapCluster)
    container:SetScale(1.4); container.PlayerCoords = oldContainer.PlayerCoords
    local diel = CreateFrame("Frame", nil, container)
    diel:SetSize(42, 42); diel:SetScale(1 / 1.4)
    diel:SetPoint("CENTER", container, "CENTER", 55, 86); diel:Show()
    local nativePoint, nativeScale, nativeLevel = diel.point, diel:GetScale(), diel:GetFrameLevel()
    diel.Background = Frame(); diel.Background.parent = diel; diel.Background:SetSize(38, 38)
    diel:SetScript("OnEvent", function(self, _, day)
        self.Background.atlas = day and "day" or "night"
        self.Background:SetSize(day and 38 or 40, day and 38 or 40)
    end)
    local cycleHandler = diel:GetScript("OnEvent")
    local originalSize = diel.SetSize
    local sizeWrites = 0
    diel.SetSize = function(...) sizeWrites = sizeWrites + 1; originalSize(...) end
    MinimapCluster.BorderTop, MinimapCluster.MinimapContainer, MinimapCluster.DielFrame = nil, container, diel
    Suite.db.squareMinimap = true; map:Apply()
    equal(backgroundEnabled, false, "new native gold zone panel is suppressed")
    equal(zone.StateTexture:IsShown(), true, "zone art visibility remains owned by the native button")
    equal(zone.AddTexture:IsShown(), false, "native additive hover state is retained")
    equal(zone:GetParent(), MinimapCluster, "new zone button retains its native parent")
    equal(zone:GetScript("OnClick"), click, "new zone art styling preserves native map clicks")
    equal(zone.OnButtonStateChanged, stateHandler, "native button-state method is not replaced")
    equal(diel:GetParent(), container, "day/night frame retains its native parent")
    equal(diel.point[2], map.header.daySlot, "day/night art anchors in the header instead of over the map")
    equal(map.header.daySlot:GetParent(), map.header, "day/night slot belongs to the header")
    equal(map.header.daySlot.point[4], 30, "day/night slot leaves room for the tracking button")
    equal(math.abs(diel:GetEffectiveScale() * diel:GetWidth() / Minimap:GetEffectiveScale() - 20) < 0.0001, true,
        "whole native day/night art fits twenty map units across different parent scales")
    equal(sizeWrites, 0, "day/night fitting does not distort the native frame or its atlas sizes")
    equal(map.header.area.width, 154, "labels reserve separate tracking, day/night and calendar space")
    equal(map.header.area.point[2], 13, "labels center in the remaining header space")
    equal(zone.point[4], 13, "native zone click target follows the label space")
    for _, active in ipairs({ true, false, true }) do zone:OnButtonStateChanged(active) end
    equal(backgroundEnabled, false, "native hover and pressed art cannot cover the custom labels")
    local before = scheduled
    diel.OnEvent(diel, "DIEL_CYCLE_CHANGED", false)
    equal(diel.Background.atlas, "night", "native day/night event still switches the atlas")
    equal(diel.Background.width, 40, "native cycle event retains dynamic atlas sizing")
    equal(diel:GetScript("OnEvent"), cycleHandler, "day/night event script is preserved")
    equal(scheduled, before, "native cycle changes need no Suite polling or layout worker")
    before = scheduled
    for _ = 1, 100 do diel:SetScale(1); diel:SetPoint("CENTER", container, "CENTER", 55, 86) end
    equal(scheduled - before, 1, "native day/night transform bursts share the existing coalescer")
    Flush()
    equal(diel.point[2], map.header.daySlot, "native transform refresh returns day/night art to the header")
    equal(map.timer, nil, "day/night reconciliation does not schedule itself again")
    SetCombat(true)
    local writes, combatPoint = layerWrites, diel.point
    zone:OnButtonStateChanged(true)
    Suite.db.squareMinimap = false; map:Apply()
    equal(layerWrites, writes, "combat toggles defer native layer restoration")
    equal(backgroundEnabled, false, "native combat hover cannot reintroduce the gold panel")
    equal(diel.point, combatPoint, "combat toggles defer day/night geometry changes")
    SetCombat(false)
    local reconcile = Suite.pending.minimap; Suite.pending.minimap = nil
    if reconcile then reconcile() end
    equal(backgroundEnabled, true, "disabling square mode restores the native background layer")
    equal(zone.AddTexture:IsShown(), true, "restoration preserves the current native hover state")
    equal(diel.point[2], nativePoint[2], "native day/night anchor target restores")
    equal(diel.point[4], 55, "native day/night horizontal offset restores")
    equal(diel.point[5], 86, "native day/night vertical offset restores")
    equal(diel:GetScale(), nativeScale, "native day/night inverse scale restores")
    equal(diel:GetFrameLevel(), nativeLevel, "native day/night layer restores")
    equal(diel.Background.atlas, "night", "restoration does not overwrite the latest native cycle")
    zone:DisableDrawLayer("BACKGROUND")
    Suite.db.squareMinimap = true; map:Apply()
    Suite.db.squareMinimap = false; map:Apply()
    equal(backgroundEnabled, false, "an originally disabled native art layer stays disabled")
    zone:EnableDrawLayer("BACKGROUND")
    local drawLayer = zone.StateTexture.GetDrawLayer
    zone.StateTexture.GetDrawLayer = function() return { secret = true } end
    Suite.db.squareMinimap = true; map:Apply()
    equal(backgroundEnabled, true, "unknown native texture layers are not hidden by guesswork")
    Suite.db.squareMinimap = false; map:Apply()
    zone.StateTexture.GetDrawLayer = drawLayer
    local enabled = zone.IsDrawLayerEnabled
    zone.IsDrawLayerEnabled = function() return { secret = true } end
    Suite.db.squareMinimap = true; map:Apply()
    equal(backgroundEnabled, true, "restricted native layer state cannot become a restore baseline")
    Suite.db.squareMinimap = false; map:Apply()
    zone.IsDrawLayerEnabled = enabled
    local width = diel.GetWidth
    diel.GetWidth = function() return { secret = true } end
    Suite.db.squareMinimap = true; map:Apply()
    equal(diel.point[2], container, "restricted day/night geometry is untouched")
    equal(map.header.area.width, 180, "skipped day/night geometry does not consume label space")
    Suite.db.squareMinimap = false; map:Apply()
    diel.GetWidth = width
    MinimapCluster.BorderTop, MinimapCluster.MinimapContainer, MinimapCluster.DielFrame = oldBorder, oldContainer, nil
    zone.StateTexture, zone.AddTexture, zone.OnButtonStateChanged = oldState, oldAdd, oldButtonState
    zone.IsDrawLayerEnabled, zone.DisableDrawLayer, zone.EnableDrawLayer = oldEnabled, oldDisable, oldEnable
    Suite.db.squareMinimap = true; map:Apply()
    equal(map.header.area.width, 180, "older minimaps retain their full label space")
    equal(map.header.area.point[2], 0, "older minimap labels remain centered")
    Suite.db.squareMinimap = false; map:Apply()
end

-- Native clock text has an implicit size. GetWidth/GetHeight normally report its
-- rendered extent, while ignoreRect=true retains the explicitly assigned size.
-- Freezing that extent on restore clips the larger font on the next enable.
do
    local oldWidth, oldHeight, oldSize = clock.GetWidth, clock.GetHeight, clock.SetSize
    local oldText, oldFont = clock.text, { clock:GetFont() }
    local oldDimensions, oldPoints = { clock.width, clock.height }, clock.point
    local reads = 0
    clock.GetWidth = function(self, ignoreRect)
        assert(not InCombatLockdown(), "clock dimensions must defer through combat")
        reads = reads + 1
        if ignoreRect or self.width > 0 then return self.width end
        return #(self.text or "") * self.fontSize * 0.65
    end
    clock.GetHeight = function(self, ignoreRect)
        assert(not InCombatLockdown(), "clock dimensions must defer through combat")
        if ignoreRect or self.height > 0 then return self.height end
        return self.fontSize + 2
    end
    clock.SetSize = function(self, width, height)
        assert(not InCombatLockdown(), "clock sizing must defer through combat")
        oldSize(self, width, height)
    end
    local function RenderedText()
        local extent = #clock.text * clock.fontSize * 0.65
        return clock.width > 0 and clock.width < extent and "1..." or clock.text
    end
    clock:SetSize(0, 0); clock:SetFont("Fonts\\ARIALN.TTF", 11, ""); clock:SetText("17:39")
    local parent, buttonClick = clock:GetParent(), TimeManagerClockButton:GetScript("OnClick")
    Suite.db.squareMinimap = true; map:Apply()
    equal(RenderedText(), "17:39", "first square enable keeps the complete native time")
    Suite.db.squareMinimap = false; map:Apply()
    equal(clock.width, 0, "clock restore retains implicit width rather than freezing text extent")
    equal(clock.height, 0, "clock restore retains implicit height")
    for _, text in ipairs({ "17:39", "11:59 AM", "1:00 PM", "23:59" }) do
        clock:SetText(text)
        Suite.db.squareMinimap = true; map:Apply()
        equal(RenderedText(), text, "re-enabled square clock fits the current native format")
        equal(clock.width, 0, "square clock uses automatic text width")
        Suite.db.squareMinimap = false; map:Apply()
        equal(RenderedText(), text, "disabled native clock remains complete after repeated cycles")
        equal(clock.width, 0, "repeat restoration does not accumulate fixed text bounds")
    end
    equal(clock:GetParent(), parent, "clock sizing preserves its native parent")
    equal(TimeManagerClockButton:GetScript("OnClick"), buttonClick, "clock sizing preserves native click behavior")
    clock:SetSize(72, 18)
    Suite.db.squareMinimap = true; map:Apply()
    equal(clock.width, 0, "square clock releases a previous explicit width while styled")
    Suite.db.squareMinimap = false; map:Apply()
    equal(clock.width, 72, "restore preserves an explicit native or external clock width")
    equal(clock.height, 18, "restore preserves an explicit native or external clock height")
    clock:SetSize(0, 0)
    Suite.db.squareMinimap = true; map:Apply()
    SetCombat(true)
    local before = reads
    Suite.db.squareMinimap = false; map:Apply()
    Suite.db.squareMinimap = true; map:Apply()
    equal(reads, before, "combat toggle bursts cannot read clock layout")
    SetCombat(false)
    local pending = Suite.pending.minimap; Suite.pending.minimap = nil
    if pending then pending() end
    equal(RenderedText(), "23:59", "latest square choice fits after deferred combat reconciliation")
    Suite.db.squareMinimap = false; map:Apply()
    local readableWidth = clock.GetWidth
    clock.GetWidth = function(self, ignoreRect)
        if ignoreRect then return { secret = true } end
        return readableWidth(self, ignoreRect)
    end
    Suite.db.squareMinimap = true; map:Apply()
    equal(map.widgets[clock], nil, "restricted explicit clock dimensions cannot enter restore snapshots")
    equal(clock.fontSize, 11, "unknown explicit clock dimensions leave its font untouched")
    Suite.db.squareMinimap = false; map:Apply()
    clock.GetWidth, clock.GetHeight, clock.SetSize = oldWidth, oldHeight, oldSize
    clock:SetSize(unpack(oldDimensions)); clock:SetFont(unpack(oldFont)); clock:SetText(oldText)
    clock.point = oldPoints
end

-- Only the decorative quest ring changes. Boundary/fill/marker configuration
-- stays with the native renderer, and owner scalar requests remain reversible.
do
    local setter = Minimap.SetQuestBlobRingScalar
    local ownerCalls = 0
    local untouched = { "SetQuestBlobInsideAlpha", "SetQuestBlobOutsideAlpha", "SetQuestBlobRingAlpha",
        "SetQuestBlobInsideTexture", "SetQuestBlobOutsideTexture", "SetQuestBlobRingTexture", "SetZoom" }
    local previous = {}
    for _, method in ipairs(untouched) do
        previous[method] = Minimap[method]
        Minimap[method] = function() ownerCalls = ownerCalls + 1 end
    end
    Suite.db.squareMinimap = true; map:Apply()
    equal(Minimap.questRingScalar, 0, "square minimap hides the decorative quest ring")
    equal(map.timer, nil, "own quest ring setter does not schedule recursive work")
    Suite.db.squareMinimap = false; map:Apply()
    equal(Minimap.questRingScalar, 1, "round minimap restores normal native ring scale")
    local before = scheduled
    Minimap:SetQuestBlobRingScalar(0.75)
    equal(scheduled, before, "disabled quest ring observer stays idle")
    Suite.db.squareMinimap = true; map:Apply()
    equal(Minimap.questRingScalar, 0, "square re-enable hides an owner's ring scale")
    before = scheduled
    for _ = 1, 100 do Minimap:SetQuestBlobRingScalar(0.6) end
    equal(scheduled - before, 1, "quest ring owner changes share one cancellable worker")
    Flush()
    equal(Minimap.questRingScalar, 0, "native ring refresh re-hides the checkered ring")
    Suite.db.squareMinimap = false; map:Apply()
    equal(Minimap.questRingScalar, 0.6, "disable restores the owner's latest ring request")
    Minimap:SetQuestBlobRingScalar(0)
    Suite.db.squareMinimap = true; map:Apply()
    Suite.db.squareMinimap = false; map:Apply()
    equal(Minimap.questRingScalar, 0, "disable retains an observed owner preference to hide the ring")
    Minimap:SetQuestBlobRingScalar(1)
    Suite.db.squareMinimap = true; map:Apply()
    SetCombat(true)
    Suite.db.squareMinimap = false; map:Apply()
    equal(Minimap.questRingScalar, 0, "ring restoration waits for combat exit")
    SetCombat(false)
    local reconcile = Suite.pending.minimap; Suite.pending.minimap = nil
    if reconcile then reconcile() end
    equal(Minimap.questRingScalar, 1, "combat exit restores the ring for the latest shape choice")
    Suite.db.squareMinimap = true; map:Apply()
    local unknown = { secret = true }
    Minimap:SetQuestBlobRingScalar(unknown)
    Flush()
    equal(Minimap.questRingScalar, unknown, "unreadable owner scalar is not replaced or guessed")
    Suite.db.squareMinimap = false; map:Apply()
    equal(Minimap.questRingScalar, unknown, "disable does not restore an unknown scalar")
    Minimap:SetQuestBlobRingScalar(1)
    Minimap.SetQuestBlobRingScalar = nil
    Suite.db.squareMinimap = true; map:Apply()
    equal(map.header:IsShown(), true, "missing optional ring capability does not break square styling")
    Suite.db.squareMinimap = false; map:Apply()
    Minimap.SetQuestBlobRingScalar = function() error("native ring permission rejected") end
    Suite.db.squareMinimap = true; map:Apply()
    equal(map.changingQuestRing, false, "native ring rejection releases the mutation guard")
    equal(map.questRing.applied, false, "rejected ring writes do not claim an applied override")
    equal(map.header:IsShown(), true, "native ring rejection leaves other map styling available")
    Suite.db.squareMinimap = false; map:Apply()
    Minimap.SetQuestBlobRingScalar = setter
    Suite.db.squareMinimap = true; map:Apply()
    Suite.db.squareMinimap = false; map:Apply()
    equal(Minimap.questRingScalar, 1, "ring capability recovery remains reversible")
    equal(ownerCalls, 0, "ring styling preserves native boundary, fill, textures and zoom APIs")
    for _, method in ipairs(untouched) do Minimap[method] = previous[method] end
end

local restricted = Frame()
restricted.GetWidth = function() return { secret = true } end
equal(map:Remember(restricted), false, "restricted widget dimensions cannot enter a layout snapshot")
equal(map.widgets[restricted], nil, "restricted widget layout is left untouched")
restricted.GetWidth = function() return 20 end
restricted.IsForbidden = function() return { secret = true } end
equal(map:Remember(restricted), false, "restricted forbidden predicate prevents minimap layout")
restricted.IsForbidden = nil
restricted.GetWidth = function() return math.huge end
equal(map:Remember(restricted), false, "nonfinite widget dimensions are rejected")
Suite.db.squareMinimap = true; map:Apply()
local before = scheduled
for _ = 1, 500 do zone:SetPoint("TOPRIGHT", MinimapCluster, "TOPRIGHT", -4, -4) end
equal(scheduled - before, 1, "minimap layout bursts use one cancellable worker")
local pending = map.timer
Suite.db.squareMinimap = false; map:Apply()
equal(pending and pending.cancelled, true, "disabling minimap cancels pending work immediately")
Flush()
equal(zone.point[1], "BOTTOMLEFT", "cancelled work cannot reapply old header geometry")
Suite.db.squareMinimap = true; map:Apply()
map:Schedule(); pending = map.timer
SetCombat(true); map.events.OnEvent(map.events, "PLAYER_REGEN_DISABLED")
equal(pending.cancelled, true, "combat entry cancels pending minimap work")
equal(Suite.pending.minimap ~= nil, true, "combat keeps one deferred minimap reconciliation")
Suite.db.squareMinimap = false; map:Apply()
SetCombat(false)
local reconcile = Suite.pending.minimap; Suite.pending.minimap = nil
if reconcile then reconcile() end
Flush()
equal(map.header:IsShown(), false, "disable during combat wins over queued enable")
equal(map.timer, nil, "disabled minimap has no idle layout worker")
-- Leave the native baseline expected by the following combat smoke substitute.
C_Timer, GetMinimapShape, hooksecurefunc = oldTimers, oldShape, oldHook
MinimapCluster:SetClampedToScreen(true)
MinimapCluster.BorderTop:Show()
