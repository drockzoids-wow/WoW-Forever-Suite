local Suite, equal, Frame, SetCombat = ...
local reveal, gui = Suite.WorldMap, Suite.GUI
local saved = { db = Suite.db, pending = Suite.pending, timer = C_Timer, create = CreateFrame, hook = hooksecurefunc,
    mapAPI = C_Map, explorationAPI = C_MapExplorationInfo, map = WorldMapFrame, page = gui.page, shown = gui.frame:IsShown(), apply = Suite.Apply }
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
local combat, hooks, textures, controllers, queries, geometry = false, 0, 0, 0, 0, 0
local timers, secret = {}, { secret = true }
local function Combat(value) combat = value; SetCombat(value) end
local function LeaveCombat()
    Combat(false)
    local pending = Suite.pending; Suite.pending = {}
    for _, callback in pairs(pending) do callback() end
end
local function Flush()
    local ready = timers; timers = {}
    for _, timer in ipairs(ready) do if not timer.cancelled then timer.callback() end end
end
local function TimerCount()
    local count = 0; for _, timer in ipairs(timers) do if not timer.cancelled then count = count + 1 end end; return count
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
hooksecurefunc = function(...)
    assert(not combat, "map hooks must install outside combat")
    hooks = hooks + 1; return saved.hook(...)
end
CreateFrame = function(...)
    assert(not combat, "map controller construction must wait for combat")
    controllers = controllers + 1
    local frame = saved.create(...)
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    return frame
end
local function Widget()
    local object = Frame()
    object.shown, object.alpha = true, 1
    object.IsForbidden = function(self) return self.forbidden or false end
    object.IsAnchoringRestricted = function(self) return self.restricted or false end
    object.IsProtected = function(self) return self.protected or false end
    object.Show = function(self) self.shown = true end
    object.Hide = function(self) self.shown = false end
    object.SetAlpha = function(self, value) self.alpha = value end
    object.GetAlpha = function(self) return self.alpha end
    object.SetTexCoord = function(self, ...) self.texCoords = { ... } end
    object.SetAllPoints = function() error("area covers must never fill the entire map") end
    object.vertex = { 1, 1, 1, 1 }
    object.GetVertexColor = function(self) return unpack(self.vertex) end
    object.SetVertexColor = function(self, ...)
        assert(not combat or (self:IsProtected() == false and self:IsAnchoringRestricted() == false), "cover never changes protected widgets in combat")
        self.vertex = { ... }
    end
    object.SetColorTexture = function(self, ...) assert(not combat, "cover construction defers combat"); self.fill = { ... } end
    for _, method in ipairs({ "SetPoint", "SetSize", "ClearAllPoints", "SetTexture" }) do
        local base = object[method]
        object[method] = function(self, ...)
            assert(not combat or (self:IsProtected() == false and self:IsAnchoringRestricted() == false), "protected reveal geometry/assets defer combat")
            geometry = geometry + 1
            return base(self, ...)
        end
    end
    return object
end

local artID, layerIndex, mapID, explored = 1194, 1, 37, nil
local data = Suite.MapRevealData[1194]
local layer = { layerWidth = data.width, layerHeight = data.height, tileWidth = data.tileWidth, tileHeight = data.tileHeight }
local map, container, pin, nativeTexture = Widget(), Widget(), Widget(), Widget()
map.GetMapID = function() return mapID end
container.GetCurrentLayerIndex = function() return layerIndex end
map.GetCanvasContainer = function() return container end
local canvas, fogLayer, fogTile, secondFog, filler, overscroll = Widget(), Widget(), Widget(), Widget(), Widget(), Widget()
canvas.TiledBackground = filler
map.GetCanvas = function() return canvas end
map.OverscrollBG = { Texture = overscroll }
local fogTiles = { fogTile, secondFog }
local function Pool(objects)
    return { EnumerateActive = function()
        local i = 0; return function() i = i + 1; return objects[i] end
    end }
end
fogLayer.GetLayerIndex = function() return 1 end
fogLayer.detailTilePool = Pool(fogTiles)
map.detailLayerPool = Pool({ fogLayer })
map.RefreshDetailLayers = function() end
-- These tiles include sea, tree silhouette and decorative corners in the supplied Teldrassil screenshot.
-- Any addon read/write/observer on these shared resources is a regression, even outside combat.
for _, object in ipairs({ canvas, fogLayer, fogTile, secondFog, filler, overscroll }) do
    object.GetVertexColor = function() error("map reveal must not inspect shared background cosmetics") end
    for _, method in ipairs({ "SetVertexColor", "SetColorTexture", "SetTexture", "SetTexCoord", "SetAlpha", "SetPoint", "SetSize", "ClearAllPoints", "SetAllPoints", "Show", "Hide" }) do
        object[method] = function() error("map reveal must not modify shared background art") end
    end
end
map.GetCanvas = function() error("area rendering must not traverse shared canvas/background resources") end
map.detailLayerPool.EnumerateActive = function() error("area rendering must not traverse native base tile pools") end
local active = { pin }
map.EnumeratePinsByTemplate = function(_, template)
    equal(template, "MapExplorationPinTemplate", "only world-map exploration pins are inspected")
    local i = 0; return function() i = i + 1; return active[i] end
end
local masks, acquired, nativeRefresh = 0, 0, 0
map.AddMaskableTexture = function(_, texture)
    assert(not combat, "new masking dependencies wait through combat")
    masks = masks + 1; texture.masked = true
end
map.AcquirePin = function() acquired = acquired + 1; return pin end
pin.GetMap = function() return map end
pin.CreateTexture = function(owner, name, drawLayer, _, sublevel)
    assert(not combat, "reveal texture creation must wait for combat")
    equal(name, nil, "reveal textures have no global names")
    local texture = Widget()
    texture.parent, texture.drawLayer, texture.sublevel = owner, drawLayer, sublevel
    textures = textures + 1
    return texture
end
pin.RemoveAllData = function() nativeTexture:Hide() end
pin.RefreshOverlays = function()
    nativeRefresh = nativeRefresh + 1
    pin:RemoveAllData()
    nativeTexture.texture, nativeTexture.alpha, nativeTexture.drawLayer = 777, 1, "ARTWORK"
    nativeTexture:Show()
end
WorldMapFrame = map
C_Map = {
    GetMapArtID = function(id) queries = queries + 1; equal(id, mapID, "current native map ID goes to C_Map"); return artID end,
    GetMapArtLayers = function() return { layer } end,
}
C_MapExplorationInfo = { GetExploredMapTextures = function() queries = queries + 1; return explored end }
local function Shown()
    local count = 0
    for _, record in pairs(reveal.pins) do for _, texture in ipairs(record.textures) do if texture.shown then count = count + 1 end end end
    return count
end
local function Covered()
    local count = 0
    for _, record in pairs(reveal.pins) do for _, texture in ipairs(record.coverTextures) do if texture.shown then count = count + 1 end end end
    return count
end
local function AllHidden(message) equal(Shown(), 0, message); equal(Covered(), 0, message .. " (area cover)") end

equal(Suite.db.revealWorldMap, false, "map reveal starts off")
equal(Suite.db.mapRevealOpacity, 0.6, "revealed terrain starts at sixty percent")
reveal:Apply()
equal(hooks, 0, "disabled map feature installs no hooks")
equal(controllers, 0, "disabled map feature creates no controller")
equal(queries, 0, "disabled map feature queries no map data")
equal(textures, 0, "disabled map feature creates no textures")
local artCount, overlayCount, fileCount = 0, 0, 0
for id, source in pairs(Suite.MapRevealData) do
    assert(id > 0 and id % 1 == 0)
    artCount = artCount + 1
    for _, overlay in ipairs(source.overlays) do
        assert(overlay[1] > 0 and overlay[2] > 0)
        assert(#overlay[5] == math.ceil(overlay[1] / source.tileWidth) * math.ceil(overlay[2] / source.tileHeight))
        overlayCount, fileCount = overlayCount + 1, fileCount + #overlay[5]
    end
end
equal(artCount, 84, "exact-build export covers all eighty-four art IDs with usable overlays")
equal(overlayCount, 1073, "only complete terrain records are shipped")
equal(fileCount, 1739, "all exported usable terrain file IDs are represented")
for _, value in ipairs({ secret, "0.4", math.huge, -math.huge, 0/0 }) do
    equal(reveal:Opacity({ mapRevealOpacity = value }), 0.6, "invalid opacity uses the default")
end
equal(reveal:Opacity({ mapRevealOpacity = -2 }), 0, "negative opacity clamps to transparent")
equal(reveal:Opacity({ mapRevealOpacity = 3 }), 1, "high opacity clamps to opaque")
equal(reveal:Opacity({ mapRevealOpacity = 0.456 }), 0.46, "opacity rounds to a whole percent")
equal(Suite.InitializeDB({ revealWorldMap = secret, mapRevealOpacity = secret }).revealWorldMap, false, "restricted saved toggle is disabled")
equal(Suite.InitializeDB({ mapRevealOpacity = 0/0 }).mapRevealOpacity, 0.6, "nonfinite saved opacity is normalized")

Suite.db.revealWorldMap = true
reveal:Apply()
equal(controllers, 1, "enable creates one event controller")
equal(hooks, 3, "only pin acquisition and exploration refresh/removal receive observers")
equal(Shown() > 0, true, "readable nil exploration still reveals an entirely unexplored map")
equal(masks, textures, "new owned textures join native masking once")
local record, firstCount, preparedCount = reveal.pins[pin], Shown(), textures
equal(#record.textures, reveal.capacity, "terrain pool prepares every supported map outside combat")
equal(#record.coverTextures, reveal.capacity, "each terrain tile has one prepared area-shaped underlay")
equal(record.background, nil, "area reveal creates no full-canvas cover")
equal(record.coverTextures[1].drawLayer, "BACKGROUND", "area cover sits beneath native explored artwork")
equal(record.coverTextures[1].sublevel, -2, "area cover sits beneath faded reveal terrain")
equal(record.coverTextures[1].vertex[1], 0, "cover uses a dark tooltip-like tint")
equal(record.coverTextures[1].vertex[4], 1, "cover tint retains the source texture's alpha silhouette")
equal(record.coverTextures[1].alpha, 0.65, "area cover is translucent")
equal(Covered(), firstCount, "only missing areas receive a cover")
equal(fogTile.vertex[4], 1, "parchment base retains sea and coastline artwork")
equal(filler.vertex[4], 1, "native canvas filler retains its appearance")
equal(overscroll.vertex[4], 1, "native overscroll filler retains its appearance")
equal(record.textures[1].texture, 271443, "first known terrain file renders from exact-build data")
equal(record.textures[1].width, 215, "partial tile uses its visible pixel width")
equal(record.textures[1].height, 215, "partial tile uses its visible pixel height")
equal(record.textures[1].texCoords[2], 215 / 256, "partial texture crops its padded file width")
equal(record.textures[1].texCoords[4], 215 / 256, "partial texture crops its padded file height")
equal(record.textures[1].point[4], 355, "terrain x offset anchors to the native pin")
equal(record.textures[1].point[5], -320, "terrain y offset uses map's downward axis")
local final = record.textures[firstCount]
equal(final.texture, 271442, "wide overlay renders its second terrain file")
equal(final.width, 189, "last wide tile crops its partial width")
equal(final.point[4], 500, "wide overlay's second tile begins one tile after its origin")
equal(final.texCoords[2], 189 / 256, "partial column's file padding is removed")
for _, texture in ipairs(record.textures) do
    if texture.shown then equal(texture.alpha, 0.6, "only owned reveal terrain receives the chosen opacity") end
    equal(texture.parent, pin, "owned terrain inherits native map transform and loading alpha")
    equal(texture.drawLayer, "BACKGROUND", "revealed terrain stays below native explored artwork")
end
for i, cover in ipairs(record.coverTextures) do
    equal(cover.parent, pin, "area cover shares the native pin transform and loading fade")
    if cover.shown then
        local terrain = record.textures[i]
        equal(cover.texture, terrain.texture, "cover inherits each area's irregular asset alpha instead of filling its rectangle")
        equal(cover.width, terrain.width, "area cover matches the cropped terrain width")
        equal(cover.height, terrain.height, "area cover matches the cropped terrain height")
        equal(cover.point[4], terrain.point[4], "cover uses the terrain's exact x offset")
        equal(cover.point[5], terrain.point[5], "cover uses the terrain's exact y offset")
        equal(cover.texCoords[2], terrain.texCoords[2], "cover retains partial tile padding crop")
        equal(cover.texCoords[4], terrain.texCoords[4], "cover retains partial row padding crop")
    end
end
pin:RefreshOverlays()
equal(nativeRefresh, 1, "native exploration refresh executes normally")
equal(nativeTexture.texture, 777, "native explored file is retained")
equal(nativeTexture.alpha, 1, "native explored terrain retains full opacity")
equal(textures, preparedCount, "refresh reuses owned terrain textures")

local first = data.overlays[1]
explored = { { textureWidth = first[1], textureHeight = first[2], offsetX = first[3], offsetY = first[4], fileDataIDs = first[5] } }
pin:RefreshOverlays()
equal(Shown(), firstCount - #first[5], "newly explored overlay loses its Suite reveal textures")
equal(Covered(), Shown(), "newly explored areas also lose their owned dark cover")
local changed = Suite.Copy(explored); changed[1].fileDataIDs[1] = 123456789
explored = changed; pin:RefreshOverlays()
equal(Shown(), firstCount, "matching geometry with different phased file IDs is not mistaken for the same terrain")
explored = {}
for _, overlay in ipairs(data.overlays) do
    explored[#explored + 1] = { textureWidth = overlay[1], textureHeight = overlay[2], offsetX = overlay[3], offsetY = overlay[4], fileDataIDs = overlay[5] }
end
pin:RefreshOverlays(); AllHidden("fully explored map needs no additional terrain")
explored = nil
Suite.Apply = function() reveal:Apply() end
reveal:SetOpacity(0.2)
equal(Suite.db.mapRevealOpacity, 0.2, "opacity change is saved")
for _, texture in ipairs(record.textures) do if texture.shown then equal(texture.alpha, 0.2, "current map responds to opacity changes") end end
reveal:SetOpacity(0); equal(Shown(), 0, "zero opacity hides missing terrain above its area cover")
equal(Covered(), firstCount, "zero terrain opacity retains only the area-shaped covers")
reveal:SetOpacity(1)
for _, texture in ipairs(record.textures) do if texture.shown then equal(texture.alpha, 1, "one hundred percent fully reveals terrain") end end
reveal:SetOpacity(secret); equal(Suite.db.mapRevealOpacity, 1, "secret opacity cannot change settings")

for _, bad in ipairs({ secret, false, "missing" }) do
    explored = bad; pin:RefreshOverlays(); AllHidden("unreadable or invalid exploration cannot reveal terrain")
end
explored = { { textureWidth = first[1], textureHeight = first[2], offsetX = secret, offsetY = first[4], fileDataIDs = first[5] } }
pin:RefreshOverlays(); AllHidden("secret explored geometry is never formatted or compared")
explored[1].offsetX, explored[1].fileDataIDs = first[3], { secret }
pin:RefreshOverlays(); AllHidden("secret explored file IDs are never used as keys")
explored[1].fileDataIDs = { 0 }
pin:RefreshOverlays(); AllHidden("invalid exploration file ID is not treated as unexplored")
explored[1].offsetY = nil
pin:RefreshOverlays(); AllHidden("missing explored geometry is guarded")
explored = nil
for _, bad in ipairs({ secret, -1, 0, 1.5, math.huge, 0/0 }) do
    mapID = bad; pin:RefreshOverlays(); AllHidden("invalid or secret map ID hides stale terrain")
end
mapID = 37
for _, bad in ipairs({ secret, 999999, 0, 1.5 }) do
    artID = bad; pin:RefreshOverlays(); AllHidden("unknown or secret map art cannot reuse previous terrain")
end
artID = 1194
for _, bad in ipairs({ secret, 0, 2, 1.5 }) do
    layerIndex = bad; pin:RefreshOverlays(); AllHidden("alternate or unreadable art layer never gets first-layer tiles")
end
layerIndex = 1
local originalWidth = layer.layerWidth
layer.layerWidth = secret; pin:RefreshOverlays(); AllHidden("secret art dimensions are guarded")
layer.layerWidth = originalWidth + 1; pin:RefreshOverlays(); AllHidden("changed map layer geometry fails closed")
layer.layerWidth = originalWidth
local api = C_MapExplorationInfo
C_MapExplorationInfo = nil; pin:RefreshOverlays(); AllHidden("missing exploration API clears terrain")
C_MapExplorationInfo = api
container.restricted = true; pin:RefreshOverlays(); AllHidden("restricted canvas is skipped")
container.restricted = false
map.forbidden = true; reveal:Refresh(); AllHidden("forbidden native map clears previously visible terrain")
map.forbidden = false; reveal:Refresh()
map.GetMapID = function() return secret end; pin:RefreshOverlays(); AllHidden("restricted native map return is guarded")
map.GetMapID = function() return mapID end
local mapShown = map.IsShown
map.IsShown = function() return secret end; pin:RefreshOverlays(); AllHidden("secret native visibility is not used as a condition")
map.IsShown = mapShown
pin:RefreshOverlays()
equal(Shown(), firstCount, "readable map data recovers after temporary restrictions")

reveal:Schedule(); reveal:Schedule()
equal(TimerCount(), 1, "map discovery work coalesces")
map.OnHide(map); equal(TimerCount(), 0, "map hide cancels queued work")
AllHidden("map hide clears owned terrain")
map.shown = false; Flush(); reveal:Apply(); AllHidden("closed map stays idle")
map.shown = true; map.OnShow(map); Flush()
equal(Shown(), firstCount, "reopening restores current terrain")
equal(TimerCount(), 0, "map reveal retains no idle timer")
pin:RemoveAllData(); AllHidden("native provider removal also removes owned terrain")
pin:RefreshOverlays(); equal(Shown(), firstCount, "native refresh restores only current terrain")
map:AcquirePin("MapExplorationPinTemplate"); Flush()
equal(acquired, 1, "native pin acquisition retains its return path")
equal(hooks, 3, "repeated discovery installs no duplicate hooks")

reveal:Schedule(); local stale = timers[#timers].callback
Combat(true); reveal.events.OnEvent(reveal.events, "PLAYER_REGEN_DISABLED")
equal(TimerCount(), 0, "combat cancels pending discovery")
artID = 1200; pin:RefreshOverlays()
equal(Shown() > 0, true, "prepared map reveal refreshes immediately on combat map changes")
equal(record.textures[1].texture, Suite.MapRevealData[1200].overlays[1][5][1], "combat navigation uses the new map's terrain")
equal(textures, preparedCount, "combat creates no terrain")
equal(Covered(), Shown(), "prepared area cover follows current combat terrain")
Suite.db.mapRevealOpacity = 0.35
reveal:Apply()
for _, texture in ipairs(record.textures) do if texture.shown then equal(texture.alpha, 0.35, "opacity changes apply immediately during combat") end end
LeaveCombat()
equal(Shown() > 0, true, "new map terrain appears after combat")
for _, texture in ipairs(record.textures) do if texture.shown then equal(texture.alpha, 0.35, "combat applies latest opacity") end end
stale(); equal(TimerCount(), 0, "stale callbacks cannot restart work")
reveal:Schedule()
Suite.db.revealWorldMap = false; reveal:Apply(); Flush()
AllHidden("disable restores the native fog immediately")
equal(next(reveal.events.registered), nil, "disabled module removes all feature event subscriptions")
equal(Suite.pending.worldMap, nil, "disable clears deferred map work")
local beforeQueries = queries
pin:RefreshOverlays(); map:AcquirePin("MapExplorationPinTemplate"); map.OnShow(map)
equal(queries, beforeQueries, "disabled hooks stay inert")
equal(TimerCount(), 0, "disabled hooks cannot schedule work")

-- Combat-first enable and missing/late native maps must not create protected dependencies.
Combat(true); Suite.db.revealWorldMap = true; reveal:Apply()
equal(Shown() > 0, true, "previously prepared reveal can be re-enabled in combat")
Suite.db.revealWorldMap = false; reveal:Apply(); LeaveCombat()
AllHidden("disable before combat ends cancels enable")
WorldMapFrame = nil; Suite.db.revealWorldMap = true; reveal:Apply()
AllHidden("missing load-on-demand world map is tolerated")
WorldMapFrame = map; artID = 1194
reveal.events.OnEvent(reveal.events, "ADDON_LOADED", "Blizzard_WorldMap"); Flush()
equal(Shown(), firstCount, "late native world-map loading reveals current terrain")
active = {}; reveal:Refresh(); AllHidden("released exploration pins do not retain visible owned textures")
active = { pin }; reveal:Refresh()
equal(textures >= firstCount, true, "native pin reappearance reuses its previous owned textures")
equal(pin.OnUpdate, nil, "Suite installs no per-frame map updater")

-- Shared base art is never suppressed or inspected. Native changes and loading remain untouched.
fogTile.texture, secondFog.texture = 1001, 1002
fogLayer.alpha, pin.alpha = 0.4, 0.7
fogTile.vertex = { 0.2, 0.3, 0.4, 0.5 }; reveal:Refresh()
equal(fogTile.vertex[4], 0.5, "native background opacity remains unchanged while reveal is active")
equal(fogTile.texture, 1001, "cover retains native tile file IDs")
equal(fogLayer.alpha, 0.4, "cover retains native detail loading/fade alpha")
equal(pin.alpha, 0.7, "owned textures inherit the existing exploration fade")
Suite.db.revealWorldMap = false; reveal:Apply()
equal(fogTile.vertex[1], 0.2, "disable does not rewrite native colors")
equal(fogTile.vertex[4], 0.5, "disable does not rewrite native opacity")
equal(secondFog.vertex[4], 1, "other parchment tiles never lose their original opacity")
equal(filler.vertex[4], 1, "native canvas filler is never suppressed")
equal(overscroll.vertex[4], 1, "native overscroll filler is never suppressed")
equal(Covered(), 0, "disable removes all owned area covers")
Suite.db.revealWorldMap = true; reveal:Apply()
artID = 999999; pin:RefreshOverlays()
equal(Covered(), 0, "unknown maps show no owned cover")
equal(fogTile.vertex[4], 0.5, "unknown art leaves current native parchment unchanged")
artID = 1194; pin:RefreshOverlays()
fogTile.vertex = { secret, 1, 1, 1 }; reveal:Refresh()
equal(Shown(), firstCount, "unrelated native secret cosmetics do not block owned area rendering")
equal(fogTile.vertex[1], secret, "native secret color is neither inspected nor replaced")
Suite.db.revealWorldMap = false; reveal:Apply()
equal(fogTile.vertex[1], secret, "disable does not replay old shared background values")
fogTile.vertex = { 0.2, 0.3, 0.4, 0.5 }
Suite.db.revealWorldMap = true; reveal:Apply()

-- Recheck protection of every affected widget, including the area-shaped covers.
for _, object in ipairs({ map, container, pin, record.textures[1], record.coverTextures[1] }) do
    Combat(true)
    object.protected = true
    local beforeGeometry, beforeHooks, beforeTextures = geometry, hooks, textures
    reveal:Refresh()
    equal(geometry, beforeGeometry, "protected dependency prevents combat terrain writes")
    equal(hooks, beforeHooks, "combat protection never installs extra hooks")
    equal(textures, beforeTextures, "combat protection never creates extra textures")
    equal(type(Suite.pending.worldMap), "function", "protected combat dependency defers the current map")
    object.protected = false; LeaveCombat()
    equal(Shown(), firstCount, "protection clearing renders the current map after combat")
end
for _, unavailable in ipairs({ secret, "missing" }) do
    Combat(true)
    local cover = record.coverTextures[1]
    local predicate = cover.IsProtected
    if unavailable == "missing" then cover.IsProtected = nil else cover.protected = unavailable end
    local beforeGeometry = geometry
    reveal:Refresh()
    equal(geometry, beforeGeometry, "missing/secret protection prevents combat geometry")
    equal(Shown(), 0, "unknown owned protection prevents new terrain rendering")
    cover.IsProtected, cover.protected = predicate, false; LeaveCombat()
end
Combat(true); record.coverTextures[1].protected = true
Suite.db.revealWorldMap = false; reveal:Apply()
equal(type(Suite.pending.worldMap), "function", "newly protected owned cover cleanup is deferred")
record.coverTextures[1].protected = false; LeaveCombat()
equal(Covered(), 0, "deferred disable removes every owned area cover")
Suite.db.revealWorldMap = true; reveal:Apply()

-- Unrelated shared art can be protected, secret or replaced without being part of the combat path.
Combat(true)
for _, object in ipairs({ canvas, fogLayer, fogTile, secondFog, filler, overscroll }) do
    object.protected, object.vertex = secret, { secret, secret, secret, secret }
end
local newFog = Widget(); fogTiles[#fogTiles + 1] = newFog
local beforeHooks, beforeTextures = hooks, textures
pin:RefreshOverlays()
equal(Shown(), firstCount, "secret/protected shared art does not prevent prepared combat reveal")
equal(Covered(), firstCount, "secret/protected shared art does not prevent prepared combat area cover")
equal(hooks, beforeHooks, "new native base tiles receive no addon observers")
equal(textures, beforeTextures, "new native tile does not create owned combat textures")
for _, object in ipairs({ canvas, fogLayer, fogTile, secondFog, filler, overscroll }) do
    equal(object.vertex[4], secret, "area rendering never overwrites secret native cosmetics")
    object.protected, object.vertex = false, { 1, 1, 1, 1 }
end
LeaveCombat()
equal(newFog.vertex[4], 1, "new native base tiles retain their original appearance")
equal(Shown(), firstCount, "prepared area rendering remains current after combat")
local replacementMap = Widget()
replacementMap.EnumeratePinsByTemplate = map.EnumeratePinsByTemplate
Combat(true); WorldMapFrame = replacementMap
beforeHooks, beforeTextures = hooks, textures
reveal:Refresh()
AllHidden("unprepared combat map replacement clears previous terrain")
equal(reveal.watchedMaps[replacementMap], nil, "new map visibility observers defer combat")
equal(hooks, beforeHooks, "new map replacement installs no combat hooks")
equal(textures, beforeTextures, "new map replacement constructs no combat textures")
WorldMapFrame = map; LeaveCombat()
equal(Shown(), firstCount, "prepared map resumes after a cancelled map replacement")
local freshPin = Widget()
freshPin.GetMap, freshPin.CreateTexture = pin.GetMap, pin.CreateTexture
freshPin.RefreshOverlays, freshPin.RemoveAllData = function() end, function() end
Combat(true); active = { freshPin }
beforeHooks, beforeTextures = hooks, textures
reveal:Refresh()
AllHidden("first-time combat pin discovery leaves stale terrain hidden")
equal(hooks, beforeHooks, "new pin hooks defer combat")
equal(textures, beforeTextures, "new pin construction defers combat")
Suite.db.revealWorldMap = false; reveal:Apply(); LeaveCombat()
equal(reveal.pins[freshPin], nil, "disable cancels pending first-time pin setup")
active = { pin }; Suite.db.revealWorldMap = true; reveal:Apply()
Combat(true); map.OnHide(map)
equal(Covered(), 0, "map hide clears prepared area cover during combat")
equal(fogTile.vertex[4], 1, "combat map hide never changes native parchment")
map.OnShow(map); Flush()
equal(Shown(), firstCount, "combat map reopening uses cached reveal")
equal(TimerCount(), 0, "combat reveal has no idle timer")
LeaveCombat()

gui:OpenPage("worldmap")
equal(gui.rows[1].label.text, "Reveal unexplored areas", "world-map page exposes the reveal toggle")
equal(gui.mapOpacityValue.text, "35%", "world-map slider displays saved opacity")
equal(gui.mapOpacitySlider.low, 0, "opacity slider reaches transparent")
equal(gui.mapOpacitySlider.high, 100, "opacity slider reaches fully opaque")
gui.mapOpacitySlider:SetValue(47)
equal(Suite.db.mapRevealOpacity, 0.47, "slider commits an exact percent")
gui.mapOpacitySlider.OnMouseWheel(gui.mapOpacitySlider, 1)
equal(Suite.db.mapRevealOpacity, 0.48, "mouse wheel adjusts opacity by one percent")
gui.mapOpacitySlider:SetValue(secret)
equal(Suite.db.mapRevealOpacity, 0.48, "secret slider input cannot be saved")
gui.mapOpacitySlider.OnMouseWheel(gui.mapOpacitySlider, math.huge)
equal(Suite.db.mapRevealOpacity, 0.48, "nonfinite wheel input is ignored")
local enabled = Suite.db.revealWorldMap
gui:RefreshWorldMap(); equal(Suite.db.revealWorldMap, enabled, "slider refresh never changes the reveal toggle")
gui.rows[1].OnClick(); equal(Suite.db.revealWorldMap, false, "page toggle disables reveal")
gui.mapOpacitySlider:SetValue(55)
equal(Suite.db.revealWorldMap, false, "opacity adjustment does not implicitly enable reveal")
equal(Suite.db.mapRevealOpacity, 0.55, "opacity can be chosen before enabling")
SlashCmdList.WOWFOREVERSUITE("map"); equal(gui.page, "worldmap", "map slash command opens its settings")
local panel = gui.mapPanel
gui:Select("overview"); equal(panel:IsShown(), false, "map controls hide on other pages")
gui:Select("worldmap"); equal(gui.mapPanel, panel, "map page reuses its controls")
equal(-gui.tabs.chat.point[3] + gui.tabs.chat.height <= gui.frame.height - 77 - 44, true, "all sixteen sidebar tabs clear the version stamp")
equal(-panel.point[3] + panel.height < gui.content.height - 35, true, "map controls clear the footer")

Suite.db.revealWorldMap = false; reveal:Apply()
Suite.db, Suite.pending, Suite.Apply = saved.db, saved.pending, saved.apply
C_Timer, CreateFrame, hooksecurefunc = saved.timer, saved.create, saved.hook
C_Map, C_MapExplorationInfo, WorldMapFrame = saved.mapAPI, saved.explorationAPI, saved.map
gui:Select(saved.page); gui.frame:SetShown(saved.shown)
Combat(false)
