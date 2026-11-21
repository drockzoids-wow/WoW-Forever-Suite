local Suite, equal, SetProfession, Flush = ...
local leveling = Suite.ProfessionLeveling
local oldMap, oldVector, oldFaction = C_Map, CreateVector2D, UnitFactionGroup
local oldReadable, oldSource = Suite.IsReadable, C_TradeSkillUI.GetRecipeSourceText
local oldOutput, oldInfo, oldSpell = C_TradeSkillUI.GetRecipeOutputItemData, C_TradeSkillUI.GetRecipeInfo, C_Spell
local side, playerMap, playerX, playerY = "Alliance", 1455, 0.5, 0.5
local secret = {}
Suite.IsReadable = function(value) return value ~= secret and oldReadable(value) end
local function Vector(x, y)
    return { GetX = function() return x end, GetY = function() return y end }
end
CreateVector2D = Vector
UnitFactionGroup = function() return side end
local pins = {}
C_Map = {
    GetBestMapForUnit = function() return playerMap end,
    GetPlayerMapPosition = function() return Vector(playerX, playerY) end,
    -- Synthetic world-space fixtures: each ordinary map occupies its own region.
    GetWorldPosFromMapPos = function(map, point)
        return 1, Vector(map * 100000 + point:GetX() * 10000, point:GetY() * 10000)
    end,
    CanSetUserWaypointOnMap = function() return true end,
    SetUserWaypoint = function(point) pins[#pins + 1] = point; return true end,
}
local convert = C_Map.GetWorldPosFromMapPos
local covered = {}
for id, reference in pairs(Suite.ProfessionRecipeSources) do
    if reference.kind == "Trainer" then
        equal(type(reference.trainers), "table", "every trainer recipe has eligible alternatives")
        covered[reference.profession] = true
        for _, faction in ipairs({ "Alliance", "Horde" }) do
            side = faction
            equal(#reference.trainers[side] > 0, true, "every trainer tier covers both factions")
            for _, point in ipairs(reference.trainers[side]) do
                playerMap, playerX, playerY = point.map, point.x, point.y
                equal(leveling:NearestTrainer(id).name, point.name, "standing at an eligible trainer selects that trainer")
                equal(leveling:RecipeLocation(id, "").name, point.name, "location follows nearest eligible trainer")
                equal(leveling:RecipeSource(id):find(point.name, 1, true) ~= nil, true, "source text follows selected trainer")
            end
        end
    else
        equal(reference.trainers, nil, "vendor/manual/quest sources never receive generic trainers")
    end
end
for _, name in ipairs({ "Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Leatherworking", "Tailoring", "First Aid" }) do
    equal(covered[name], true, "location selection covers " .. name)
end
side, playerMap, playerX, playerY = "Alliance", 1455, 0.43, 0.28
equal(leveling:RecipeLocation(8776, "").name, "Uthrar Threx, Ironforge", "Ironforge linen belt no longer defaults to Stormwind")
equal(leveling:RecipeLocation(2964, "").name, "Jormund Stonebrow, Ironforge", "wool recipe selects the suitable Ironforge tier")
equal(leveling:RecipeLocation(3865, "").name ~= "Jormund Stonebrow, Ironforge", true, "expert recipe cannot use the nearby lower-tier trainer")
equal(leveling:RecipeLocation(18417, "").name, "Qia, Winterspring", "nearby trainer cannot replace a pattern vendor")
equal(leveling:RecipeLocation(7929, "").name, "Deneb Walker, Arathi Highlands", "nearby trainer cannot replace a manual seller")
equal(leveling:RecipeLocation(16647, "").name, "Derotain Mudsipper, Tanaris", "nearby trainer cannot replace a quest")
equal(leveling:RecipeLocation(7751, "").name, "Catherine Leland, Stormwind City", "cooking recipe retains its actual vendor")

-- Cross-zone tests deliberately use world distances that disagree with map IDs
-- and local percentages. These validate selection, not real game geography.
local origins = { [1455] = 0, [1453] = 100000, [1457] = 200000,
    [1437] = 1000, [1436] = 99000, [1440] = 199000 }
C_Map.GetWorldPosFromMapPos = function(map, point)
    if not origins[map] then return 2, Vector(0, 0) end
    return 1, Vector(origins[map] + point:GetX() * 100, point:GetY() * 100)
end
playerX, playerY = 0.5, 0.5
for _, case in ipairs({ {1437,1455}, {1436,1453}, {1440,1457} }) do
    playerMap = case[1]
    equal(leveling:RecipeLocation(8776, "").map, case[2], "cross-zone nearest trainer follows shared world position")
end
side = "Horde"
equal(leveling:NearestTrainer(8776), nil, "opposing-faction trainers never enter the nearest pool")
side = nil
equal(leveling:RecipeLocation(8776, ""), nil, "unknown faction does not guess from position")
side, playerMap = "Alliance", 1455
local native = "Trainer: |Hworldmap:1453:5350:8170|h[Lawrence Schneider, Stormwind City]|h"
equal(leveling:RecipeLocation(8776, native).map, 1455, "static native example cannot override a nearer eligible trainer")
C_TradeSkillUI.GetRecipeSourceText = function() return native end
equal(leveling:RecipeSource(8776):find("Uthrar", 1, true) ~= nil, true, "tooltip does not contradict selected destination")
playerMap = secret
equal(leveling:NearestTrainer(8776), nil, "restricted map is not used in comparisons")
playerMap, playerX = 1455, secret
equal(leveling:NearestTrainer(8776), nil, "restricted position is not used in arithmetic")
playerX, playerY = 0, 0
equal(leveling:NearestTrainer(8776), nil, "unavailable zero player position does not pick a trainer")
playerX, playerY = 0.5, 0.5
C_Map.GetWorldPosFromMapPos = function() return secret, secret end
equal(leveling:NearestTrainer(8776).map, 1455, "restricted world coordinates can still use readable same-map position")
playerMap = 1437
equal(leveling:NearestTrainer(8776), nil, "restricted world data cannot compare different zone percentages")
C_Map.GetWorldPosFromMapPos = function() error("not available") end
equal(leveling:NearestTrainer(8776), nil, "failed world conversion safely retains reference source")
C_Map.GetBestMapForUnit = nil
equal(leveling:RecipeLocation(8776, "").map, 1453, "missing player location retains documented fallback")
C_Map.GetBestMapForUnit = function() return playerMap end
C_Map.GetWorldPosFromMapPos = convert
playerMap, playerX, playerY = 1455, 0.43, 0.28

-- Exercise the visible warning, event refresh and actual waypoint callback.
SetProfession("Tailoring")
Suite.db.professionLevelingAutoRecipe = false
Suite.db.professionLevelingHideDone, Suite.db.professionLevelingAutoSteps = false, false
leveling.open = true; leveling:Refresh(true); leveling.frame:Show()
local function Warning(id)
    for _, row in ipairs(leveling.frame.stepRows) do
        for _, warning in ipairs(row.trainingButtons or {}) do
            if warning.recipeID == id and warning:IsShown() then return warning end
        end
    end
end
local warning = Warning(8776)
equal(warning.label.text:find("Uthrar", 1, true) ~= nil, true, "visible Ironforge belt warning uses local trainer")
local outputIcon = 132493
C_TradeSkillUI.GetRecipeOutputItemData = function() return { icon = outputIcon } end
equal(leveling:RecipeIcon(8776), outputIcon, "recipe uses its output item's native icon")
C_TradeSkillUI.GetRecipeOutputItemData = function() return { icon = secret } end
C_TradeSkillUI.GetRecipeInfo = function(id) return { recipeID = id, icon = 132491, learned = false } end
equal(leveling:RecipeIcon(8776), 132491, "restricted output falls back to readable recipe icon")
C_TradeSkillUI.GetRecipeInfo = function() return { recipeID = 123, icon = 132491 } end
C_Spell = { GetSpellTexture = function() return 133995 end }
equal(leveling:RecipeIcon(8776), 133995, "mismatched recipe metadata uses spell texture")
C_Spell.GetSpellTexture = function() return secret end
equal(leveling:RecipeIcon(8776), 134400, "missing or restricted icon uses a neutral placeholder")
equal(leveling:RecipeIcon(secret), 134400, "restricted recipe ID is never used for icon lookup")
C_TradeSkillUI.GetRecipeInfo = oldInfo
C_TradeSkillUI.GetRecipeOutputItemData = function() return { icon = outputIcon } end
for index, guide in ipairs(Suite.ProfessionGuides) do
    if guide.estimates then
        SetProfession(guide.name); leveling:Refresh(true)
        for _, row in ipairs(leveling.frame.stepRows) do
            for _, button in ipairs(row.recipeButtons or {}) do
                if button:IsShown() and button.recipeID then
                    equal(button.icon.texture, outputIcon, "every profession's step recipes display output icons")
                    equal(button.icon.width, 20, "step icons reserve a compact size")
                    equal(button.label.width, 384, "step text reserves space for the icon")
                end
            end
        end
    end
end
SetProfession("Tailoring"); leveling:Refresh(true)
warning = Warning(8776)
warning:OnClick("LeftButton")
equal(pins[#pins].map, 1455, "click pins the selected Ironforge trainer")
playerMap, playerX, playerY = 1453, 0.535, 0.817
equal(leveling.events.registered.ZONE_CHANGED_NEW_AREA, true, "zone changes refresh an open guide")
leveling.events:OnEvent("ZONE_CHANGED_NEW_AREA"); Flush()
warning = Warning(8776)
equal(warning.label.text:find("Lawrence", 1, true) ~= nil, true, "moving cities updates the rendered warning")
playerMap, playerX, playerY = 1455, 0.43, 0.28
warning:OnClick("LeftButton")
equal(pins[#pins].map, 1455, "waypoint rechecks current position even before the next render")
leveling.events:OnEvent("PLAYER_STOPPED_MOVING"); Flush()
equal(Warning(8776).location.map, 1455, "stopping movement refreshes the selected source")
-- The actual trainer click starts the independent HUD with a verified native pin.
local savedPoint, savedPosition, savedFacing, savedSpeed = UiMapPoint, UnitPosition, GetPlayerFacing, GetUnitSpeed
local savedTicker = C_Timer.NewTicker
local pin, ticker, north, west, world, facing = nil, nil, nil, nil, 1, 0
UiMapPoint = { CreateFromCoordinates = function(map, x, y) return { uiMapID = map, position = Vector(x, y) } end }
C_Map.GetUserWaypoint = function() return pin end
C_Map.SetUserWaypoint = function(point) pin = point; return true end
UnitPosition = function() return north, west, 0, world end
GetPlayerFacing = function() return facing end
GetUnitSpeed = function() return 0, 10 end
C_Timer.NewTicker = function(_, tick)
    ticker = { tick = tick, Cancel = function(self) self.cancelled = true end }
    return ticker
end
C_Map.GetWorldPosFromMapPos = function(_, point) return 1, Vector(point:GetX() * 1000, point:GetY() * 1000) end
local location = Warning(8776).location
local _, worldPosition = C_Map.GetWorldPosFromMapPos(location.map, Vector(location.x, location.y))
north, west = worldPosition:GetX() - 100, worldPosition:GetY()
Warning(8776):OnClick("LeftButton")
local hud = leveling.waypointFrame
equal(hud.title.text, "Train Linen Belt", "trainer shortcut names the recipe")
equal(hud.detail.text, "100 yd  ·  ETA ~0:10", "stationary ETA uses run speed in world yards")
equal(hud.arrow.texture:match("ProfessionWaypointArrow%.tga$"), "ProfessionWaypointArrow.tga", "HUD uses the packaged gold pointer")
equal(hud.arrow.rotation, 0, "a waypoint forward points up")
local readPin = C_Map.GetUserWaypoint
C_Map.GetUserWaypoint = function() error("rotation must not poll the native pin") end
for _, nextFacing in ipairs({ math.pi / 4, math.pi / 2, 2 * math.pi - 0.1 }) do
    facing = nextFacing
    hud:OnUpdate(1 / 60)
    equal(math.abs(math.sin(hud.arrow.rotation) + math.sin(facing)) < 0.00001, true,
        "live facing rotates the arrow between position samples, including across north")
end
C_Map.GetUserWaypoint = readPin
local mapPosition = C_Map.GetPlayerMapPosition
world = 2; C_Map.GetPlayerMapPosition = function() end; ticker.tick()
equal(hud.arrow:IsShown(), false, "different world space hides the direction")
equal(hud:GetScript("OnUpdate"), nil, "unavailable direction leaves no animation handler")
world = 1; C_Map.GetPlayerMapPosition = mapPosition; ticker.tick()
equal(hud.arrow:IsShown(), true, "returning to the same world restores direction")
leveling:Close()
equal(hud:IsShown(), true, "navigation remains on screen after the guide closes")
pin = { uiMapID = location.map, position = Vector(0.2, 0.2) }; ticker.tick()
equal(ticker.cancelled, true, "replacing the native waypoint stops the HUD ticker")
equal(hud:IsShown(), false, "replacement waypoint hides profession navigation")
pin = UiMapPoint.CreateFromCoordinates(location.map, location.x, location.y)
leveling:StartWaypointArrow(location, pin, "Train Linen Belt")
equal(leveling.events.registered.USER_WAYPOINT_UPDATED, true, "profession navigation listens for native pin changes")
pin = nil
leveling.events:OnEvent("USER_WAYPOINT_UPDATED")
equal(ticker.cancelled, true, "clearing the native pin stops navigation without waiting for a tick")
equal(hud:IsShown(), false, "clearing the native pin hides the HUD")
equal(hud:GetScript("OnUpdate"), nil, "clearing the pin stops per-frame rotation")
pin = UiMapPoint.CreateFromCoordinates(location.map, location.x, location.y)
leveling:StartWaypointArrow(location, pin, "Train Linen Belt")
north = worldPosition:GetX() - 4; ticker.tick()
equal(ticker.cancelled, true, "arriving within five yards stops navigation updates")
equal(C_Map.GetUserWaypoint(), pin, "arrival preserves the native map pin")
-- A real client can report the pin a tick later and return a plain coordinate pair.
pin = nil
leveling:StartWaypointArrow(location, UiMapPoint.CreateFromCoordinates(location.map, location.x, location.y), "Train Linen Belt")
equal(hud:IsShown(), true, "an unconfirmed native pin does not hide the new HUD on the first tick")
equal(hud.arrow:IsShown(), false, "pending confirmation does not show a stale bearing")
pin = { uiMapID = location.map, position = {x = location.x + 0.00005, y = location.y} }
UnitPosition = function() return secret, secret, nil, secret end
C_Map.GetPlayerMapPosition = function() return { GetXY = function() return location.x, location.y + 0.1 end } end
C_Map.GetWorldPosFromMapPos = function() return nil end
C_Map.GetMapWorldSize = function() return 1000, 1000 end
facing = 0
ticker.tick()
equal(hud.arrow:IsShown(), true, "native map coordinates provide a direction without readable world position")
equal(hud.detail.text:find("100 yd", 1, true) == 1, true, "map dimensions convert normalized offsets to yards")
equal(hud.arrow.rotation, 0, "the map fallback uses north-up orientation")
pin = nil
leveling.events:OnEvent("USER_WAYPOINT_UPDATED")
equal(hud:IsShown(), false, "clearing a late-confirmed pin still dismisses the arrow")
leveling:StartWaypointArrow(location, UiMapPoint.CreateFromCoordinates(location.map, location.x, location.y), "Train Linen Belt")
for _ = 1, 8 do ticker.tick() end
equal(ticker.cancelled, true, "a rejected or missing pin cannot leave an active timer")
UiMapPoint, UnitPosition, GetPlayerFacing, GetUnitSpeed = savedPoint, savedPosition, savedFacing, savedSpeed
C_Timer.NewTicker = savedTicker
leveling:Close(); leveling:Cancel()
leveling.events:OnEvent("PLAYER_STOPPED_MOVING")
equal(leveling.timer, nil, "closed guides do no movement refresh work")
C_Map, CreateVector2D, UnitFactionGroup = oldMap, oldVector, oldFaction
Suite.IsReadable, C_TradeSkillUI.GetRecipeSourceText = oldReadable, oldSource
C_TradeSkillUI.GetRecipeOutputItemData, C_TradeSkillUI.GetRecipeInfo, C_Spell = oldOutput, oldInfo, oldSpell
