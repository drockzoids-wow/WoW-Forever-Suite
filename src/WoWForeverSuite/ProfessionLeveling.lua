local _, Suite = ...
local Leveling = {}
Suite.ProfessionLeveling = Leveling
table.insert(Suite.modules, Leveling)
local guides = Suite.ProfessionGuides
local WIDTH, CONTENT_WIDTH = 460, 410
local function Read(value, kind) return Suite.IsReadable(value) and type(value) == kind end
local function Number(value) return Read(value, "number") and value == value and value >= 0 and value < math.huge end
local function Text(value) return Read(value, "string") and #value > 0 and #value <= 160 and not value:find("[%c|]") end
local function Field(object, key)
    if not Suite.IsReadable(object) or (type(object) ~= "table" and type(object) ~= "userdata") then return end
    local ok, value = pcall(function() return object[key] end)
    if ok and Suite.IsReadable(value) then return value end
end
local function Call(fn, ...)
    if not Read(fn, "function") then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Safe(frame)
    if not Suite.IsReadable(frame) or not frame then return false end
    local forbidden = Field(frame, "IsForbidden")
    return Read(Field(frame, "GetObjectType"), "function")
        and (not forbidden or Call(forbidden, frame) == false)
end
local function Shown(frame) return Safe(frame) and Call(Field(frame, "IsShown"), frame) == true end
local function Label(parent, size, x, y, width)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", size, "")
    label:SetTextColor(0.88, 0.91, 0.93); label:SetJustifyH("LEFT")
    label:SetPoint("TOPLEFT", x, y); label:SetWidth(width); label:SetWordWrap(true)
    return label
end
local function Surface(frame)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.035, 0.05, 0.065, 0.98); Suite.Theme:Backdrop(frame, 0.85)
end
local function Button(parent, text, width, callback)
    return Suite.Theme:ActionButton(parent, text, width, 23, function() if not InCombatLockdown() then callback() end end)
end
local function GuideDropdown(parent, callback)
    local button = Button(parent, "Choose profession", 188, callback)
    Suite.Theme:DropdownIndicator(button)
    return button
end
function Leveling:Enabled() return Suite.db and Read(Suite.db.professionLeveling, "boolean") and Suite.db.professionLeveling == true end
function Leveling:Resolve(info)
    if not Read(info, "table") then return end
    local profession, name = Field(info, "profession"), Field(info, "professionName")
    local enums = Field(Enum, "Profession")
    for index, guide in ipairs(guides) do
        local enum = guide.enum and Field(enums, guide.enum)
        if Number(profession) and Number(enum) and profession == enum then return index end
    end
    -- English fallback for clients lacking the enum, including the Lockpicking entry.
    if Text(name) then for index, guide in ipairs(guides) do if name == guide.name then return index end end end
end
local function ValidSkill(rank, maximum)
    return Number(rank) and Number(maximum) and rank % 1 == 0 and maximum % 1 == 0
        and rank <= maximum and maximum > 0 and maximum <= 10000
end
function Leveling:InitializeCharacter(saved)
    local result = {}
    for _, guide in ipairs(guides) do
        local record = Field(saved, guide.name)
        local rank, maximum = Field(record, "rank"), Field(record, "maximum")
        if ValidSkill(rank, maximum) then result[guide.name] = { rank = rank, maximum = maximum } end
    end
    self.skills = result
    return result
end
function Leveling:RememberSkill(index, rank, maximum)
    if self.skills and guides[index] and ValidSkill(rank, maximum) then
        local previous = self.skills[guides[index].name]
        self.skills[guides[index].name] = { rank = rank, maximum = maximum }
        if Suite.ShoppingList and (not previous or previous.rank ~= rank) then Suite.ShoppingList:Changed() end
    end
end
function Leveling:CaptureSkills()
    if not self.skills or not Read(GetProfessions, "function") or not Read(GetProfessionInfo, "function") then return end
    -- Same roster and return positions as the native Camelot profession book.
    local roster = { pcall(GetProfessions) }
    if roster[1] ~= true then return end
    for slot = 2, 9 do
        local id = roster[slot]
        if Number(id) and id > 0 and id <= 2147483647 and id % 1 == 0 then
            local ok, name, _, rank, maximum, _, _, skillLine = pcall(GetProfessionInfo, id)
            if ok and Number(skillLine) and skillLine > 0 and skillLine <= 2147483647 and skillLine % 1 == 0 then
                local info = Call(Field(C_TradeSkillUI, "GetProfessionInfoBySkillLineID"), skillLine)
                local index = self:Resolve(info) or self:Resolve({ professionName = name })
                self:RememberSkill(index, rank, maximum)
            end
        end
    end
end
function Leveling:GuideSkill()
    -- Do not mask unreadable live data with an older snapshot of the same book.
    if self.selected == self.current then return self.rank, self.maximum, false end
    local guide = guides[self.selected]
    local record = guide and self.skills and self.skills[guide.name]
    if record and ValidSkill(record.rank, record.maximum) then return record.rank, record.maximum, true end
end
function Leveling:Context()
    if not Safe(self.owner) or not Shown(Field(self.owner, "CraftingPage")) then return end
    local info = Call(Field(C_TradeSkillUI, "GetBaseProfessionInfo"))
    if not Read(info, "table") then return nil, nil, "unavailable" end
    local index = self:Resolve(info)
    local rank, maximum = Field(info, "skillLevel"), Field(info, "maxSkillLevel")
    if not Number(rank) or not Number(maximum) or rank % 1 ~= 0 or maximum % 1 ~= 0
        or rank > maximum or maximum > 10000 then rank, maximum = nil, nil end
    local name = Field(info, "professionName")
    local id = Field(info, "professionID")
    local key = Number(id) and tostring(id) or Text(name) and name or "unavailable"
    return index, rank, key, maximum
end
function Leveling:ViewOption(key)
    local value = Suite.db and Suite.db[key]
    return Read(value, "boolean") and value == true
end
function Leveling:ToggleView(key)
    if not self:Enabled() or InCombatLockdown() or not self.open then return end
    if key ~= "professionLevelingHideDone" and key ~= "professionLevelingAutoSteps" and key ~= "professionLevelingHideStocked"
        and key ~= "professionLevelingMaterialsCollapsed" and key ~= "professionLevelingStepsCollapsed" then return end
    Suite.db[key] = not self:ViewOption(key)
    if key == "professionLevelingAutoSteps" then self.stepOverrides = {} end
    self:Render(true)
end
local function CurrentSection(section, rank)
    return Number(rank) and rank >= section[1] and (rank < section[2] or rank == 300 and section[2] == 300)
end
function Leveling:Faction()
    local faction = Call(UnitFactionGroup, "player")
    if Read(faction, "string") and (faction == "Alliance" or faction == "Horde") then return faction end
end
function Leveling:StepDetail(section)
    local detail = section[4]
    if section[5] then detail = detail .. "\n|cffe6bf7a" .. section[5] .. "|r" end
    if section[6] then detail = detail .. "\n|cffffbd70" .. section[6] .. "|r" end
    if section.locations then
        local faction = self:Faction()
        local location = faction and section.locations[faction]
        detail = detail .. "\n|cffe6bf7a" .. (location or "See source for faction-specific locations.") .. "|r"
    end
    return detail
end
function Leveling:StepEstimates(guide, section, rank)
    local results = {}
    for _, recipe in ipairs(guide.estimates or {}) do
        if recipe[1] >= section[1] and recipe[1] < section[2] then
            local done = Number(rank) and rank >= recipe[2]
            if not done or not self:ViewOption("professionLevelingHideDone") then
                local crafts = recipe[3]
                if Number(rank) and rank >= recipe[1] and rank < recipe[2] then
                    crafts = math.ceil(recipe[3] * (recipe[2] - rank) / (recipe[2] - recipe[1]))
                end
                local estimate = { recipe = recipe[4], crafts = crafts, target = recipe[2], done = done,
                    produced = crafts * (recipe[6] or 1), recipeID = recipe.recipeID, materials = {} }
                for _, reagent in ipairs(recipe[5]) do
                    local name = reagent[2]
                    local id = Suite.ProfessionMaterialIDs[name] or Call(Field(C_Item, "GetItemInfoInstant"), name)
                    if not Number(id) or id % 1 ~= 0 or id <= 0 or id > 2147483647 then id = nil end
                    estimate.materials[#estimate.materials + 1] = { count = reagent[1] * crafts, id = id, name = name }
                end
                results[#results + 1] = estimate
            end
        end
    end
    return results
end
function Leveling:RecipeMessage(message)
    if self.frame and not InCombatLockdown() then self.frame.status:SetText(message) end
    return false
end
function Leveling:RecipeTraining(id)
    if not Number(id) then return end
    local current = self:Context()
    if current ~= self.selected then return end
    local changing = Field(C_TradeSkillUI, "IsDataSourceChanging")
    if Read(changing, "function") and Call(changing) ~= false then return end
    for _, name in ipairs({ "IsTradeSkillLinked", "IsTradeSkillGuild", "IsTradeSkillGuildMember", "IsNPCCrafting" }) do
        local fn = Field(C_TradeSkillUI, name)
        if Read(fn, "function") and Call(fn) ~= false then return end
    end
    local info = Call(Field(C_TradeSkillUI, "GetRecipeInfo"), id)
    local nativeID = Field(info, "recipeID")
    local profession = Call(Field(C_TradeSkillUI, "GetBaseProfessionInfo"))
    local skillLine = Field(profession, "professionID")
    if not Number(nativeID) or nativeID ~= id or not Number(skillLine)
        or Call(Field(C_TradeSkillUI, "IsRecipeInSkillLine"), id, skillLine) ~= true then return end
    return Field(info, "learned")
end
local function Coordinate(value) return Read(value, "number") and value == value and math.abs(value) < 10000000 end
local function Vector(position, normalized)
    local x = Call(Field(position, "GetX"), position) or Field(position, "x")
    local y = Call(Field(position, "GetY"), position) or Field(position, "y")
    if not Coordinate(x) or not Coordinate(y) then
        local get = Field(position, "GetXY")
        if not Read(get, "function") then return end
        local ok
        ok, x, y = pcall(get, position)
        if not ok then return end
    end
    if not Coordinate(x) or not Coordinate(y) then return end
    if normalized and (x < 0 or x > 1 or y < 0 or y > 1 or x == 0 and y == 0) then return end
    return x, y
end
local function WorldPosition(map, position)
    local fn = Field(C_Map, "GetWorldPosFromMapPos")
    if not Read(fn, "function") then return end
    local ok, continent, vector = pcall(fn, map, position)
    if not ok or not Number(continent) then return end
    local x, y = Vector(vector)
    if x then return continent, x, y end
end
function Leveling:NearestTrainer(id)
    local reference = Suite.ProfessionRecipeSources[id]
    local faction = self:Faction()
    local candidates = reference and reference.kind == "Trainer" and reference.trainers
    candidates = candidates and faction and candidates[faction]
    if not candidates then return end
    local map = Call(Field(C_Map, "GetBestMapForUnit"), "player")
    if not Number(map) or map <= 0 or map % 1 ~= 0 then return end
    local position = Call(Field(C_Map, "GetPlayerMapPosition"), map, "player")
    local px, py = Vector(position, true)
    if not px then return end
    local continent, wx, wy = WorldPosition(map, position)
    local nearest, distance, localNearest, localDistance
    for _, point in ipairs(candidates) do
        -- Coordinates from different zone maps are comparable only after native
        -- conversion into a shared continent/world space. Never compare percentages.
        if continent then
            local vector = Call(CreateVector2D, point.x, point.y)
            local other, x, y = WorldPosition(point.map, vector)
            if other and other == continent then
                local squared = (x - wx) ^ 2 + (y - wy) ^ 2
                if not distance or squared < distance then nearest, distance = point, squared end
            end
        end
        if point.map == map then
            local squared = (point.x - px) ^ 2 + (point.y - py) ^ 2
            if not localDistance or squared < localDistance then localNearest, localDistance = point, squared end
        end
    end
    -- Maps/instances without comparable positions retain the existing source.
    return nearest or localNearest
end
function Leveling:RecipeSource(id)
    local trainer = self:NearestTrainer(id)
    if trainer then
        local reference = Suite.ProfessionRecipeSources[id]
        return "Trainer: " .. trainer.name .. (reference.note and "\n" .. reference.note or "")
    end
    -- Native source text includes trainer/vendor names and locations where provided.
    local source = Call(Field(C_TradeSkillUI, "GetRecipeSourceText"), id)
    if Read(source, "string") and #source > 0 and #source <= 4096 then return source end
    local reference = Suite.ProfessionRecipeSources[id]
    if reference then
        local faction = self:Faction()
        local point = reference.neutral or faction and reference[faction]
        return reference.kind .. ": " .. (point and point.name or "See the guide source for learning details.")
            .. (reference.note and "\n" .. reference.note or "")
    end
    return "Source unavailable. Check the guide's source link for how to learn it."
end
function Leveling:RecipeLocation(id, source)
    local trainer = self:NearestTrainer(id)
    if trainer then return trainer end
    -- A single valid native location takes precedence over reference coordinates.
    -- Multiple native links can list factions in any order; use the catalog then.
    local map, x, y, name = source:match("|Hworldmap:(%d+):([%d%.]+):([%d%.]+)|h%[?(.-)%]?|h")
    local _, links = source:gsub("|Hworldmap:", "")
    map, x, y = tonumber(map), tonumber(x), tonumber(y)
    if links == 1 and Number(map) and map > 0 and map % 1 == 0 and Number(x) and x <= 10000 and Number(y) and y <= 10000 and Text(name) then
        return { map = map, x = x / 10000, y = y / 10000, name = name }
    end
    local reference = Suite.ProfessionRecipeSources[id]
    if reference then
        local faction = self:Faction()
        return reference.neutral or faction and reference[faction] or nil
    end
end
local waypointVerbs = { Trainer = "Train", Vendor = "Buy recipe for", Quest = "Learn",
    Manual = "Find manual for", Specialist = "Learn" }

local function AngleDelta(angle)
    return (angle + math.pi) % (2 * math.pi) - math.pi
end

local function RotateWaypointArrow(frame, elapsed)
    local facing = Call(GetPlayerFacing)
    if not Coordinate(facing) then frame.arrow:Hide(); return end

    -- Smooth course changes from sampled positions, then apply live facing
    -- directly so turning the character does not wait for the next sample.
    local bearing = frame.renderedBearing or frame.bearing
    local drift = AngleDelta(frame.bearing - bearing)
    if math.abs(drift) <= 0.0005 then
        bearing = frame.bearing
    elseif elapsed > 0 then
        bearing = bearing + drift * (1 - math.exp(-math.min(elapsed, 0.1) / 0.075))
    end
    frame.renderedBearing = bearing
    local rotation = AngleDelta(bearing - facing)
    if frame.rotation == nil or math.abs(AngleDelta(rotation - frame.rotation)) >= 0.0005 then
        frame.arrow:SetRotation(rotation)
        frame.rotation = rotation
    end
    if not frame.arrow:IsShown() then frame.arrow:Show() end
end

local function ClearWaypointBearing(frame)
    if frame.bearing then frame:SetScript("OnUpdate", nil) end
    frame.bearing, frame.renderedBearing, frame.rotation = nil, nil, nil
    frame.arrow:Hide()
end

function Leveling:StopWaypointArrow()
    self.waypoint = nil
    if self.waypointTimer then self.waypointTimer:Cancel(); self.waypointTimer = nil end
    if self.waypointFrame then
        ClearWaypointBearing(self.waypointFrame)
        self.waypointFrame:Hide()
    end
end

function Leveling:CreateWaypointArrow()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(340, 96); frame:SetPoint("TOP", UIParent, "TOP", 0, -116)
    frame:SetFrameStrata("HIGH")
    frame.title = Label(frame, 14, 0, -52, 340)
    frame.title:SetJustifyH("CENTER"); frame.title:SetWordWrap(false)
    frame.title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    frame.title:SetTextColor(1, 0.79, 0.28)
    frame.detail = Label(frame, 12, 0, -73, 340)
    frame.detail:SetJustifyH("CENTER")
    frame.detail:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    frame.arrow = frame:CreateTexture(nil, "ARTWORK")
    frame.arrow:SetSize(52, 52); frame.arrow:SetPoint("TOP")
    frame.arrow:SetTexture("Interface\\AddOns\\WoWForeverSuite\\Media\\ProfessionWaypointArrow.tga")
    self.waypointFrame = frame
end

local function WaypointOffset(waypoint)
    if not waypoint.world then
        waypoint.world, waypoint.north, waypoint.west = WorldPosition(waypoint.map, waypoint.position)
    end
    if waypoint.world and type(UnitPosition) == "function" then
        local ok, north, west, _, world = pcall(UnitPosition, "player")
        if ok and Coordinate(north) and Coordinate(west) and Number(world) and world == waypoint.world then
            return waypoint.north - north, waypoint.west - west
        end
    end
    if InCombatLockdown() then return end

    -- A native map projection keeps player and pin in the same coordinate space.
    local map = Call(Field(C_Map, "GetBestMapForUnit"), "player")
    if not Number(map) then return end
    local position = Call(Field(C_Map, "GetPlayerMapPosition"), map, "player")
    local x, y = Vector(position, true)
    if not x then return end
    if waypoint.world then
        local world, north, west = WorldPosition(map, position)
        if world == waypoint.world then return waypoint.north - north, waypoint.west - west end
    end
    local mapSize = Field(C_Map, "GetMapWorldSize")
    if not Read(mapSize, "function") then return end
    local targetX, targetY = waypoint.x, waypoint.y
    if map ~= waypoint.map then
        targetX, targetY = Vector(Call(Field(C_Map, "GetUserWaypointPositionForMap"), map), true)
        if not targetX then return end
    end
    local ok, width, height = pcall(mapSize, map)
    if ok and Coordinate(width) and width > 0 and Coordinate(height) and height > 0 then
        return (y - targetY) * height, (x - targetX) * width
    end
end

function Leveling:UpdateWaypointArrow(pinChanged)
    local waypoint, frame = self.waypoint, self.waypointFrame
    if not waypoint then return end
    if not self:Enabled() then self:StopWaypointArrow(); return end
    local pin = Call(Field(C_Map, "GetUserWaypoint"))
    local x, y = Vector(Field(pin, "position"))
    local matches = Field(pin, "uiMapID") == waypoint.map and x
        and math.abs(x - waypoint.x) <= 0.00015 and math.abs(y - waypoint.y) <= 0.00015
    if not matches then
        if waypoint.pending and waypoint.pending > 0 and not pinChanged then
            -- The native waypoint can become readable after the setter returns.
            waypoint.pending = waypoint.pending - 1
            return
        end
        self:StopWaypointArrow(); return
    end
    waypoint.pending = nil

    local north, west = WaypointOffset(waypoint)
    if not north then
        ClearWaypointBearing(frame)
        frame.detail:SetText("Direction and ETA unavailable")
        return
    end
    local yards = math.sqrt(north * north + west * west)
    if yards <= 5 then self:StopWaypointArrow(); return end

    local speed
    if type(GetUnitSpeed) == "function" then
        local read, current, run = pcall(GetUnitSpeed, "player")
        if read then speed = Number(current) and current > 0 and current or Number(run) and run end
    end
    local seconds = speed and speed >= 0.01 and math.ceil(yards / speed)
    local eta = seconds and string.format("~%d:%02d", math.floor(seconds / 60), seconds % 60) or "—"
    local detail = string.format("%.0f yd  ·  ETA %s", yards, eta)
    if frame.detail:GetText() ~= detail then frame.detail:SetText(detail) end

    local bearing = math.acos(math.max(-1, math.min(1, north / yards)))
    local wasTracking = frame.bearing ~= nil
    frame.bearing = west < 0 and -bearing or bearing
    if not wasTracking then frame:SetScript("OnUpdate", RotateWaypointArrow) end
    RotateWaypointArrow(frame, 0)
end

function Leveling:StartWaypointArrow(location, point, label)
    self:StopWaypointArrow()
    if type(Field(C_Map, "GetUserWaypoint")) ~= "function" or type(Field(C_Timer, "NewTicker")) ~= "function" then return end
    if not self.waypointFrame then self:CreateWaypointArrow() end
    local frame = self.waypointFrame
    self.waypoint = { map = location.map, x = location.x, y = location.y, pending = 7,
        position = Field(point, "position") or Call(CreateVector2D, location.x, location.y) }
    frame.title:SetText(label)
    frame.detail:SetText("Locating waypoint…")
    frame.arrow:Hide()
    frame:Show()
    self:UpdateWaypointArrow()
    if not self.waypoint then return end
    self.waypointTimer = C_Timer.NewTicker(0.15, function() self:UpdateWaypointArrow() end)
end

function Leveling:RecipeWaypoint(button)
    local row = Field(button, "recipeRow")
    if InCombatLockdown() or not self:Enabled() or not self.open or not Shown(self.owner) or not Shown(self.frame)
        or not Shown(button) or not Shown(row) or Field(row, "expanded") ~= true
        or Field(button, "guideIndex") ~= self.selected or self:RecipeTraining(Field(button, "recipeID")) ~= false then return end
    local location = self:RecipeLocation(button.recipeID, self:RecipeSource(button.recipeID))
    if not location or Call(Field(C_Map, "CanSetUserWaypointOnMap"), location.map) ~= true then
        return self:RecipeMessage("Waypoint unavailable for this recipe's source.")
    end
    local point = Call(Field(UiMapPoint, "CreateFromCoordinates"), location.map, location.x, location.y)
    local set = Field(C_Map, "SetUserWaypoint")
    if not point or not Read(set, "function") then return self:RecipeMessage("Waypoints are unavailable in this client.") end
    local ok, result = pcall(set, point)
    if not ok or not Suite.IsReadable(result) or result == false then return self:RecipeMessage("Could not set the recipe waypoint.") end
    Call(Field(C_SuperTrack, "SetSuperTrackedUserWaypoint"), true)
    local reference = Suite.ProfessionRecipeSources[button.recipeID]
    local verb = reference and waypointVerbs[reference.kind] or "Learn"
    local name = Field(button, "recipeName")
    self:StartWaypointArrow(location, point, Text(name) and verb .. " " .. name or location.name)
    self:RecipeMessage("Waypoint: " .. location.name)
end
function Leveling:SelectGuideRecipe(button)
    if InCombatLockdown() or not self:Enabled() or not self.open or not Shown(self.owner)
        or not Shown(self.frame) or not Shown(button) then return false end
    local recipeRow = Field(button, "recipeRow")
    if not Shown(recipeRow) or Field(recipeRow, "expanded") ~= true then return false end
    local id, guideIndex = Field(button, "recipeID"), Field(button, "guideIndex")
    if not Number(id) or id <= 0 or id % 1 ~= 0 or id > 2147483647
        or not Number(guideIndex) or guideIndex % 1 ~= 0 or not guides[guideIndex] then return false end
    local current, _, context = self:Context()
    if current ~= guideIndex or self.selected ~= guideIndex then return self:RecipeMessage("Open this profession before selecting its recipes.") end
    local requested = self:RequestRecipe(id, guideIndex, context, false)
    if requested then Suite.ProfessionRoutes:Reset(); Suite.ProfessionRoutes:UpdateBack() end
    return requested
end
function Leveling:RequestRecipe(id, guideIndex, context, automatic, expectedRank)
    if self:RecipeBusy() then return self:RecipeMessage("Finish or stop the current crafting batch before selecting another recipe.") end
    for _, name in ipairs({ "IsTradeSkillLinked", "IsTradeSkillGuild", "IsTradeSkillGuildMember", "IsNPCCrafting" }) do
        local fn = Field(C_TradeSkillUI, name)
        if Read(fn, "function") and Call(fn) ~= false then return self:RecipeMessage("Open your own profession before selecting recipes.") end
    end
    if automatic and (not self.open or not Shown(self.frame) or self.selected ~= guideIndex) then return false end
    local _, initialRank = self:Context()
    if automatic and initialRank ~= expectedRank then return false end
    local getInfo, inSkill, openRecipe = Field(C_TradeSkillUI, "GetRecipeInfo"),
        Field(C_TradeSkillUI, "IsRecipeInSkillLine"), Field(C_TradeSkillUI, "OpenRecipe")
    if not Read(getInfo, "function") or not Read(inSkill, "function") or not Read(openRecipe, "function") then
        return self:RecipeMessage("Recipe selection is unavailable in this client.")
    end
    local changing = Field(C_TradeSkillUI, "IsDataSourceChanging")
    if Read(changing, "function") and Call(changing) ~= false then
        return self:RecipeMessage("Profession data is loading. Try again shortly.")
    end
    local profession = Call(Field(C_TradeSkillUI, "GetBaseProfessionInfo"))
    local skillLine = Field(profession, "professionID")
    local info = Call(getInfo, id)
    local nativeID = Field(info, "recipeID")
    if not Number(skillLine) or skillLine % 1 ~= 0 or skillLine <= 0 or skillLine > 2147483647 or not Number(nativeID)
        or nativeID ~= id or Call(inSkill, id, skillLine) ~= true then
        return self:RecipeMessage("Recipe unavailable in the open profession.")
    end
    local learned = Field(info, "learned")
    if learned == false then return self:RecipeMessage("|cffff6666Not trained yet. See the source below the recipe.|r") end
    if learned ~= true then return self:RecipeMessage("Recipe training data unavailable. Try again shortly.") end
    if automatic and Field(info, "canSkillUp") ~= true then return false end
    -- Revalidate after native reads; never replay a click after combat/context changes.
    local fresh, freshRank, freshContext = self:Context()
    if InCombatLockdown() or not self:Enabled() or not Shown(self.owner)
        or fresh ~= guideIndex or freshContext ~= context then return false end
    if automatic then
        if not self:ViewOption("professionLevelingAutoRecipe") or not self.open or not Shown(self.frame)
            or self.selected ~= guideIndex or self.autoBlocked or self.autoCrafting or freshRank ~= initialRank then return false end
        -- Set before OpenRecipe: native responses may immediately cause another refresh.
        self.autoAttempt = context .. ":" .. tostring(id)
    elseif not self.open or not Shown(self.frame) or self.selected ~= guideIndex then return false end
    local ok, result = pcall(openRecipe, id)
    if not ok or not Suite.IsReadable(result) or result == false then
        return self:RecipeMessage("Recipe unavailable. Select it in the profession window.")
    end
    if not InCombatLockdown() and self.open then self.frame.status:SetText("Recipe requested. Crafting stays manual.") end
    return true
end
function Leveling:RecipeBusy()
    if self.autoCrafting then return true end
    local page = Field(self.owner, "CraftingPage")
    if page then
        local ok, value = pcall(function() return page.isOverrideCastBarActive end)
        if not ok or not Suite.IsReadable(value) or value ~= nil and not Read(value, "boolean") or value == true then return true end
    end
    for _, fn in ipairs({ UnitCastingInfo or false, UnitChannelInfo or false }) do
        if Read(fn, "function") then
            local ok, name = pcall(fn, "player")
            if not ok or not Suite.IsReadable(name) or name ~= nil then return true end
        end
    end
    return false
end
function Leveling:AutoSelectRecipe()
    if not self:ViewOption("professionLevelingAutoRecipe") then self.autoAttempt = nil; return end
    if InCombatLockdown() or not self:Enabled() or not self.open or not Shown(self.frame)
        or self.autoBlocked or self.autoCrafting or self.routeHold or not Shown(self.owner) then return end
    local index, rank, context = self:Context()
    if not index or self.selected ~= index or not Number(rank) then return end
    -- Never drive a linked, guild or NPC profession rather than this character's book.
    for _, name in ipairs({ "IsTradeSkillLinked", "IsTradeSkillGuild", "IsTradeSkillGuildMember", "IsNPCCrafting" }) do
        local fn = Field(C_TradeSkillUI, name)
        if Read(fn, "function") and Call(fn) ~= false then return end
    end
    for _, name in ipairs({ "UnitCastingInfo", "UnitChannelInfo" }) do
        local fn = name == "UnitCastingInfo" and UnitCastingInfo or UnitChannelInfo
        if Read(fn, "function") then
            local ok, cast = pcall(fn, "player")
            if not ok or not Suite.IsReadable(cast) or cast ~= nil then return end
        end
    end
    local target
    for _, recipe in ipairs(guides[index].estimates or {}) do
        if rank >= recipe[1] and rank < recipe[2] and Number(recipe.recipeID) then target = recipe.recipeID; break end
    end
    local token = target and context .. ":" .. tostring(target)
    if token ~= self.autoTarget then self.autoTarget, self.autoAttempt = token, nil end
    if target and self.autoAttempt ~= token then self:RequestRecipe(target, index, context, true, rank) end
end
function Leveling:RecipeIcon(id)
    if not Number(id) or id <= 0 or id % 1 ~= 0 then return 134400 end
    local output = Call(Field(C_TradeSkillUI, "GetRecipeOutputItemData"), id)
    local icon = Field(output, "icon")
    if Number(icon) and icon > 0 and icon % 1 == 0 then return icon end
    local info = Call(Field(C_TradeSkillUI, "GetRecipeInfo"), id)
    local nativeID = Field(info, "recipeID")
    icon = Field(info, "icon")
    if Number(nativeID) and nativeID == id and Number(icon) and icon > 0 and icon % 1 == 0 then return icon end
    -- Spell textures also resolve recipes while browsing another profession.
    icon = Call(Field(C_Spell, "GetSpellTexture"), id)
    return Number(icon) and icon > 0 and icon % 1 == 0 and icon or 134400
end
function Leveling:StepMaterials(row, estimates, y, expanded)
    row.estimateLabels, row.estimateItems, row.recipeButtons = row.estimateLabels or {}, row.estimateItems or {}, row.recipeButtons or {}
    row.trainingButtons = row.trainingButtons or {}
    for _, label in ipairs(row.estimateLabels) do label:Hide() end
    for _, item in ipairs(row.estimateItems) do item.materialID = nil; item:Hide() end
    for _, button in ipairs(row.recipeButtons) do button.recipeID, button.guideIndex = nil, nil; button:Hide() end
    for _, button in ipairs(row.trainingButtons) do button.recipeID, button.guideIndex = nil, nil; button:Hide() end
    if row.estimateColumns then row.estimateColumns:Hide() end
    if not expanded or #estimates == 0 then return y end
    local labelIndex, itemIndex = 0, 0
    local function Note(text)
        labelIndex = labelIndex + 1
        local label = row.estimateLabels[labelIndex]
        if not label then label = Label(row, 12, 0, 0, CONTENT_WIDTH); row.estimateLabels[labelIndex] = label end
        label:ClearAllPoints(); label:SetPoint("TOPLEFT", 0, -y); label:SetText(text); label:Show()
        y = y + label:GetStringHeight() + 8
    end
    Note("Click a recipe to select it or a craftable material to open its recipe. Shift-click items for auction search or chat. Crafting stays manual. Estimates may vary; keep intermediate supplies.")
    if not row.estimateColumns then
        row.estimateColumns = CreateFrame("Frame", nil, row); row.estimateColumns:SetSize(CONTENT_WIDTH, 22)
        Label(row.estimateColumns, 11, 0, -3, 252):SetText("Required for this step")
        Label(row.estimateColumns, 11, 264, -3, 68):SetText("Have")
        Label(row.estimateColumns, 11, 340, -3, 70):SetText("Need")
    end
    row.estimateColumns:ClearAllPoints(); row.estimateColumns:SetPoint("TOPLEFT", 0, -y); row.estimateColumns:Show()
    y = y + 22
    for recipeIndex, estimate in ipairs(estimates) do
        local button = row.recipeButtons[recipeIndex]
        if not button then
            button = CreateFrame("Button", nil, row); button:EnableMouse(true); button:RegisterForClicks("LeftButtonUp")
            button.icon = button:CreateTexture(nil, "ARTWORK")
            button.icon:SetSize(20, 20); button.icon:SetPoint("TOPLEFT", 0, -2)
            button.label = Label(button, 12, 26, -3, CONTENT_WIDTH - 26)
            local highlight = button:CreateTexture(nil, "HIGHLIGHT"); highlight:SetAllPoints()
            highlight:SetColorTexture(0.41, 0.84, 0.75, 0.12)
            button:SetScript("OnClick", function(_, mouseButton)
                if InCombatLockdown() then return end
                if mouseButton == "LeftButton" and Call(IsModifiedClick, "CHATLINK") == true then
                    Suite.Items:ModifiedClick(button.outputItemID, mouseButton); return
                end
                if mouseButton == nil or mouseButton == "LeftButton" then self:SelectGuideRecipe(button) end
            end)
            row.recipeButtons[recipeIndex] = button
        end
        button.recipeID, button.guideIndex, button.recipeRow = estimate.recipeID, self.selected, row
        local output = Number(estimate.recipeID) and estimate.recipeID > 0 and estimate.recipeID % 1 == 0
            and Call(Field(C_TradeSkillUI, "GetRecipeOutputItemData"), estimate.recipeID)
        local outputID = Field(output, "itemID") or Suite.ProfessionMaterialIDs[estimate.recipe]
        button.outputItemID = Number(outputID) and outputID > 0 and outputID <= 2147483647 and outputID % 1 == 0 and outputID or nil
        button.icon:SetTexture(self:RecipeIcon(estimate.recipeID))
        button.label:SetText(estimate.recipe .. " · " .. (estimate.done and "Done · full-band reference" or "estimated " .. estimate.crafts .. " crafts to " .. estimate.target))
        local available = self.selected == self.current and Number(estimate.recipeID)
            and Read(Field(C_TradeSkillUI, "GetRecipeInfo"), "function")
            and Read(Field(C_TradeSkillUI, "IsRecipeInSkillLine"), "function") and Read(Field(C_TradeSkillUI, "OpenRecipe"), "function")
        button:SetEnabled(available == true or button.outputItemID ~= nil)
        button.label:SetTextColor(unpack(available and {0.41,0.84,0.75} or {0.55,0.65,0.7}))
        local recipeHeight = math.max(24, button.label:GetStringHeight() + 6)
        button:SetSize(CONTENT_WIDTH, recipeHeight); button:ClearAllPoints(); button:SetPoint("TOPLEFT", 0, -y); button:Show()
        y = y + recipeHeight + 8
        if self:RecipeTraining(estimate.recipeID) == false then
            local training = row.trainingButtons[recipeIndex]
            if not training then
                training = CreateFrame("Button", nil, row); training:EnableMouse(true); training:RegisterForClicks("LeftButtonUp")
                training.label = Label(training, 11, 0, 0, CONTENT_WIDTH)
                training.label:SetTextColor(0.9, 0.42, 0.42)
                training:SetScript("OnClick", function(_, mouseButton)
                    if mouseButton == nil or mouseButton == "LeftButton" then self:RecipeWaypoint(training) end
                end)
                training:SetScript("OnEnter", function()
                    if InCombatLockdown() or not Shown(training) or not Safe(GameTooltip) then return end
                    for _, method in ipairs({ "SetOwner", "SetText", "Show", "Hide" }) do
                        if not Read(Field(GameTooltip, method), "function") then return end
                    end
                    self:HideTooltip()
                    GameTooltip:SetOwner(training, "ANCHOR_RIGHT"); self.hovered, self.tooltip = training, GameTooltip
                    local detail = training.location and training.location.name .. "\n" .. training.source or training.source
                    GameTooltip:SetText(detail, 0.88, 0.91, 0.93, 1, true)
                    if training.location and Read(Field(GameTooltip, "AddLine"), "function") then GameTooltip:AddLine("Click to add a waypoint.", 0.41, 0.84, 0.75) end
                    GameTooltip:Show()
                end)
                local function Leave() if self.hovered == training then self:HideTooltip() end end
                training:SetScript("OnLeave", Leave); training:SetScript("OnHide", Leave)
                row.trainingButtons[recipeIndex] = training
            end
            training.recipeID, training.guideIndex, training.recipeRow = estimate.recipeID, self.selected, row
            training.recipeName = estimate.recipe
            training.source = self:RecipeSource(estimate.recipeID)
            training.location = self:RecipeLocation(estimate.recipeID, training.source)
            local reference = Suite.ProfessionRecipeSources[estimate.recipeID]
            local kind = reference and reference.kind .. ": " or ""
            training.label:SetText("Not trained · " .. (training.location and kind .. training.location.name .. " >"
                or "Source details"))
            local height = math.max(16, training.label:GetStringHeight() + 2)
            training:SetSize(CONTENT_WIDTH, height); training:ClearAllPoints(); training:SetPoint("TOPLEFT", 0, -y); training:Show()
            y = y + height + 4
        end
        for _, material in ipairs(estimate.materials) do
            itemIndex = itemIndex + 1
            local item = row.estimateItems[itemIndex]
            if not item then
                item = CreateFrame("Button", nil, row); item:EnableMouse(true)
                item.icon = Suite.Items:CreateListIcon(item, 18, 0, -2)
                item.label = Label(item, 13, 24, -3, 228)
                item.have = Label(item, 11, 264, -4, 68)
                item.need = Label(item, 11, 358, -4, 52)
                item.check = item:CreateTexture(nil, "OVERLAY")
                item.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready"); item.check:SetSize(14, 14)
                item.check:SetPoint("TOPLEFT", 340, -3)
                item:RegisterForClicks("LeftButtonUp")
                item:SetScript("OnClick", function(_, button) Suite.ProfessionRoutes:MaterialClick(item, button) end)
                item:SetScript("OnEnter", function() self:ItemTooltip(item) end)
                local function Leave() if self.hovered == item then self:HideTooltip() end end
                item:SetScript("OnLeave", Leave); item:SetScript("OnHide", Leave)
                row.estimateItems[itemIndex] = item
            end
            item.materialID = material.id
            Suite.Items:SetListIcon(item.icon, material.id)
            item.label:SetText("|cffe6bf7a" .. material.count .. " x|r " .. material.name)
            local have, need, sufficient = self:Stock(material.id, material.count)
            item.have:SetText(have); item.need:SetText(estimate.done and "Done" or need)
            item.check:SetShown(sufficient and not estimate.done)
            item.need:SetTextColor(unpack(sufficient and {0.41,0.84,0.75} or {1,0.74,0.44}))
            local height = math.max(24, item.label:GetStringHeight() + 6, item.have:GetStringHeight() + 8, item.need:GetStringHeight() + 8)
            item:SetSize(CONTENT_WIDTH, height); item:ClearAllPoints(); item:SetPoint("TOPLEFT", 0, -y); item:Show()
            y = y + height
        end
        y = y + 8
    end
    return y
end
function Leveling:ToggleStep(index)
    if not self:Enabled() or InCombatLockdown() or not self.open then return end
    local row = self.frame and self.frame.stepRows and self.frame.stepRows[index]
    if not row or not Shown(row) or not row.sectionIndex then return end
    self.stepOverrides = self.stepOverrides or {}
    self.stepOverrides[index] = not row.expanded
    self:Render(false)
end
function Leveling:Steps(guide, rank, offset)
    local frame = self.frame
    frame.stepRows = frame.stepRows or {}
    for _, row in ipairs(frame.stepRows) do
        row.sectionIndex, row.expanded = nil, false; row:Hide()
        self:StepMaterials(row, {}, 0, false)
    end
    frame.text:Hide()
    if self:ViewOption("professionLevelingStepsCollapsed") then return offset end
    frame.text:Show()
    local active = 0
    if guide then
        for index, section in ipairs(guide.sections) do if CurrentSection(section, rank) then active = index; break end end
    end
    local context = tostring(self.selected or 0) .. ":" .. active
    if self.stepContext ~= context then self.stepContext, self.stepOverrides = context, {} end
    frame.text:ClearAllPoints(); frame.text:SetPoint("TOPLEFT", 0, -offset)
    frame.text:SetText(guide and guide.note or "No summary for this profession. Choose a guide above to browse the library.")
    local y = offset + frame.text:GetStringHeight() + 14
    if not guide then return y end
    for index, section in ipairs(guide.sections) do
        local row = frame.stepRows[index]
        if not row then
            row = CreateFrame("Frame", nil, frame.body); row:SetWidth(CONTENT_WIDTH)
            row.header = CreateFrame("Button", nil, row); row.header:SetSize(CONTENT_WIDTH, 26)
            row.header:SetPoint("TOPLEFT"); row.header:EnableMouse(true)
            row.marker = Label(row.header, 13, 0, -4, 16)
            row.heading = Label(row.header, 13, 20, -4, CONTENT_WIDTH - 20)
            row.detail = Label(row, 13, 0, -32, CONTENT_WIDTH); row.detail:SetSpacing(4)
            row.header:SetScript("OnClick", function() self:ToggleStep(index) end)
            frame.stepRows[index] = row
        end
        local current = CurrentSection(section, rank)
        local done = Number(rank) and rank >= section[2] and not current
        if not done or not self:ViewOption("professionLevelingHideDone") then
            local expanded = not Number(rank) or not self:ViewOption("professionLevelingAutoSteps") or current
            if self.stepOverrides[index] ~= nil then expanded = self.stepOverrides[index] end
            row.sectionIndex, row.expanded = index, expanded
            local title = guide.name == "Camping" and section[3] or section[1] .. "-" .. section[2] .. "  " .. section[3]
            row.heading:SetText((current and "Current range  |  " or done and "Done · " or "") .. title)
            row.heading:SetTextColor(unpack(done and {0.4,0.46,0.49} or {0.41,0.84,0.75}))
            row.marker:SetText(expanded and "−" or "+")
            local detail = self:StepDetail(section)
            row.detail:SetText(detail); row.detail:SetShown(expanded)
            local headerHeight = math.max(26, row.heading:GetStringHeight() + 8)
            row.header:SetHeight(headerHeight)
            row.detail:ClearAllPoints(); row.detail:SetPoint("TOPLEFT", 0, -headerHeight - 6)
            local height = headerHeight + (expanded and row.detail:GetStringHeight() + 18 or 4)
            local estimates = expanded and self:StepEstimates(guide, section, rank) or {}
            height = self:StepMaterials(row, estimates, height, expanded)
            row:SetHeight(height); row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y); row:Show()
            y = y + height + 4
        else
            row:Hide()
        end
    end
    return y
end
local function OwnsTooltip(tip, row)
    if not row or not Safe(tip) then return false end
    local owned = Field(tip, "IsOwned")
    if Read(owned, "function") then return Call(owned, tip, row) == true end
    return Call(Field(tip, "GetOwner"), tip) == row
end
function Leveling:HideTooltip()
    local tip, row = self.tooltip, self.hovered
    self.tooltip, self.hovered = nil, nil
    if OwnsTooltip(tip, row) then pcall(Field(tip, "Hide"), tip) end
end
function Leveling:CompletedTooltip(button)
    self:HideTooltip()
    local tip = GameTooltip
    if InCombatLockdown() or not self.open or not self:Enabled() or not Shown(button) or not Safe(tip) then return end
    for _, method in ipairs({ "SetOwner", "SetText", "Show", "Hide" }) do
        if not Read(Field(tip, method), "function") then return end
    end
    self.tooltip, self.hovered = tip, button
    if not pcall(tip.SetOwner, tip, button, "ANCHOR_RIGHT") or not OwnsTooltip(tip, button)
        or not pcall(tip.SetText, tip, "Show or hide completed steps and their materials.\nYour current range and future steps stay visible.", 0.88, 0.91, 0.93, 1, true)
        or not pcall(tip.Show, tip) then self:HideTooltip() end
end
function Leveling:CloseGuideMenu()
    if self.guideMenu then self.guideMenu:Hide() end
end
function Leveling:GuideMenu()
    if InCombatLockdown() or not self:Enabled() or not self.open or not Shown(self.frame) or not Shown(self.owner) then return end
    if Shown(self.guideMenu) then self:CloseGuideMenu(); return end
    self:HideTooltip()
    if not self.guideMenu then
        local menu = CreateFrame("Button", nil, self.frame); self.guideMenu = menu
        menu:Hide(); menu:SetAllPoints(UIParent); menu:SetFrameStrata("DIALOG"); menu:SetFrameLevel(530)
        menu:EnableMouse(true); menu:EnableKeyboard(true)
        menu:SetScript("OnClick", function() self:CloseGuideMenu() end)
        menu:SetScript("OnKeyDown", function(control, key)
            if InCombatLockdown() then return end
            control:SetPropagateKeyboardInput(key ~= "ESCAPE")
            if key == "ESCAPE" then self:CloseGuideMenu() end
        end)
        menu.list = CreateFrame("Frame", nil, menu, "BackdropTemplate")
        menu.list:SetSize(188, #guides * 23 + 8); menu.list:SetFrameLevel(531); menu.list:EnableMouse(true)
        menu.list:SetPoint("TOPLEFT", self.frame.guideDropdown, "BOTTOMLEFT", 0, -3)
        menu.list:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        menu.list:SetBackdropColor(0.035, 0.05, 0.065, 1); Suite.Theme:Backdrop(menu.list, 0.85)
        menu.rows = {}
        for index, guide in ipairs(guides) do
            local choice = index
            local row = Button(menu.list, guide.name, 180, function()
                if not self.open or not self:Enabled() or not Shown(menu) or self.menuContext ~= self.context
                    or not Shown(self.frame) or not Shown(self.owner) then return end
                self:CloseGuideMenu()
                self:Select(choice)
            end)
            row:SetPoint("TOPLEFT", 4, -4 - (index - 1) * 23)
            row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
            row.label:SetJustifyH("LEFT")
            row.marker = row:CreateTexture(nil, "OVERLAY"); row.marker:SetSize(2, 13)
            row.marker:SetPoint("LEFT", 2, 0); Suite.Theme:Texture(row.marker, 1)
            menu.rows[index] = row
        end
    end
    self.menuContext = self.context
    for index, row in ipairs(self.guideMenu.rows) do
        row.selected = index == self.selected; row.marker:SetShown(row.selected); row.paint()
    end
    self.guideMenu:SetPropagateKeyboardInput(true); self.guideMenu:Show()
end
function Leveling:ItemTooltip(row)
    self:HideTooltip()
    if InCombatLockdown() or not self:Enabled() or not self.open or not Shown(self.owner)
        or not Shown(self.frame) or not Shown(row) then return end
    local id = Field(row, "materialID")
    if not Number(id) or id <= 0 or id % 1 ~= 0 or id > 2147483647 then return end
    local tip = GameTooltip
    if not Safe(tip) then return end
    for _, method in ipairs({ "SetOwner", "SetItemByID", "Show", "Hide" }) do
        if not Read(Field(tip, method), "function") then return end
    end
    if not Read(Field(tip, "IsOwned"), "function") and not Read(Field(tip, "GetOwner"), "function") then return end
    self.tooltip, self.hovered = tip, row
    if not pcall(tip.SetOwner, tip, row, "ANCHOR_RIGHT") or not OwnsTooltip(tip, row)
        or not pcall(tip.SetItemByID, tip, id) or not OwnsTooltip(tip, row)
        or not pcall(tip.Show, tip) then self:HideTooltip() end
    -- Native item data and the existing tooltip post-call add recorded inventory.
    -- Do not scan possessions, enable tracking or append a second inventory block.
end
function Leveling:Stock(id, required, usedBefore)
    local summary = Call(Suite.Inventory.Summary, Suite.Inventory, id, true)
    if not Read(summary, "table") or Field(summary, "observed") ~= true then return "?", "?", false end
    local total, incomplete = Field(summary, "total"), Field(summary, "incomplete")
    if not Number(total) or total % 1 ~= 0 or total > 1000000000000 or not Read(incomplete, "boolean") then return "?", "?", false end
    local need = math.min(required, math.max(0, required + (usedBefore or 0) - total))
    local have = string.format("%d", total) .. (incomplete and "+" or "")
    return have, (incomplete and need > 0 and "≤" or "") .. string.format("%d", need), need == 0
end
function Leveling:InventoryChanged()
    if self:Enabled() and self.open and Shown(self.frame) then self:Queue() end
end
local function MaterialKey(item) return item[2] or item[3] end
function Leveling:RemainingShopping(guide, rank)
    if not guide or not guide.estimates then return end
    local shopping, produced = {}, {}
    shopping.note = "Uses the primary recipes below and reuses intermediate items made by earlier remaining steps. Recipe quests and optional alternatives are not included. Click a craftable material to open its recipe; Shift-click for auction search or chat."
    for _, section in ipairs(guide.sections) do
        local group, merged, target = { rows = {}, endSkill = section[2] }, {}, section[1]
        for _, estimate in ipairs(self:StepEstimates(guide, section, rank)) do
            target = math.max(target, estimate.target)
            for _, material in ipairs(estimate.materials) do
                local required = material.count
                if not estimate.done then
                    local reused = math.min(produced[material.name] or 0, required)
                    produced[material.name] = (produced[material.name] or 0) - reused
                    required = required - reused
                end
                if required > 0 then
                    local key = (estimate.done and "done:" or "next:") .. (material.id or material.name)
                    local row = merged[key]
                    if not row then
                        row = { {0, material.id, material.name, Suite.ProfessionMaterialVendors[material.name]}, completed = estimate.done == true }
                        merged[key] = row; group.rows[#group.rows + 1] = row
                    end
                    row[1][1] = row[1][1] + required
                end
            end
            if not estimate.done then produced[estimate.recipe] = (produced[estimate.recipe] or 0) + estimate.produced end
        end
        if #group.rows > 0 then
            group.title = section[1] .. "-" .. math.min(section[2], target)
            shopping[#shopping + 1] = group
        end
    end
    return shopping
end
function Leveling:MaterialPlan(guide, rank)
    local plan, totals = {}, {}
    local shopping = self:RemainingShopping(guide, rank)
    if not shopping then return plan, totals end
    for _, group in ipairs(shopping) do
        for _, row in ipairs(group.rows) do
            local done = row.completed
            plan[row] = done
            if not done then
                for _, item in ipairs(row) do
                    local key = MaterialKey(item)
                    totals[key] = (totals[key] or 0) + item[1]
                end
            end
        end
    end
    return plan, totals, shopping
end
function Leveling:Materials(guide, offset)
    local frame, y, rowIndex, labelIndex = self.frame, offset or 0, 0, 0
    local rank = self:GuideSkill()
    local doneRows, totals, shopping = self:MaterialPlan(guide, rank)
    local stock = {}
    local function Counts(item, total, usedBefore)
        local key = MaterialKey(item) .. ":" .. total .. ":" .. (usedBefore or 0)
        if not stock[key] then stock[key] = { self:Stock(item[2], total, usedBefore) } end
        return stock[key]
    end
    local function Visible(row)
        if doneRows[row] then return not self:ViewOption("professionLevelingHideDone") end
        if not self:ViewOption("professionLevelingHideStocked") then return true end
        for _, item in ipairs(row) do if not Counts(item, totals[MaterialKey(item)] or 0)[3] then return true end end
        return false
    end
    self:HideTooltip()
    frame.materialRows, frame.materialLabels = frame.materialRows or {}, frame.materialLabels or {}
    for _, row in ipairs(frame.materialRows) do row.materialID = nil; row:Hide() end
    for _, label in ipairs(frame.materialLabels) do label:Hide() end
    if self:ViewOption("professionLevelingMaterialsCollapsed") then return y end
    local function Paragraph(text, color, x, width)
        labelIndex = labelIndex + 1
        local label = frame.materialLabels[labelIndex]
        if not label then label = Label(frame.body, 13, 0, 0, CONTENT_WIDTH); frame.materialLabels[labelIndex] = label end
        label:ClearAllPoints(); label:SetPoint("TOPLEFT", x or 0, -y); label:SetWidth(width or CONTENT_WIDTH)
        label:SetText(text); label:SetTextColor(unpack(color or {0.6, 0.68, 0.71})); label:Show()
        y = y + label:GetStringHeight() + 10
    end
    local function Item(item, done, total, sectionTotal, usedBefore)
        local counts = not done and Counts(item, total)
        local here = not done and Counts(item, sectionTotal, usedBefore)
        if counts and counts[3] and self:ViewOption("professionLevelingHideStocked") then return end
        rowIndex = rowIndex + 1
        local row = frame.materialRows[rowIndex]
        if not row then
            row = CreateFrame("Button", nil, frame.body)
            row:EnableMouse(true)
            row.icon = Suite.Items:CreateListIcon(row, 18, 0, -2)
            row.quantity = Label(row, 13, 24, -3, 54)
            row.name = Label(row, 13, 78, -3, 178)
            row.have = Label(row, 11, 264, -4, 68)
            row.need = Label(row, 11, 358, -4, 52)
            row.sectionNeed = Label(row, 11, 358, -4, 52)
            row.totalSummary = Label(row, 11, 0, 0, 334)
            row.totalSummary:SetTextColor(0.6,0.72,0.76)
            row.check = row:CreateTexture(nil, "OVERLAY")
            row.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready"); row.check:SetSize(14, 14)
            row.check:SetPoint("TOPLEFT", 340, -3)
            local highlight = row:CreateTexture(nil, "HIGHLIGHT"); highlight:SetAllPoints()
            highlight:SetColorTexture(0.41, 0.84, 0.75, 0.12)
            row:RegisterForClicks("LeftButtonUp")
            row:SetScript("OnClick", function(_, button) Suite.ProfessionRoutes:MaterialClick(row, button) end)
            row:SetScript("OnEnter", function() self:ItemTooltip(row) end)
            local function Leave() if self.hovered == row then self:HideTooltip() end end
            row:SetScript("OnLeave", Leave); row:SetScript("OnHide", Leave)
            frame.materialRows[rowIndex] = row
        end
        row.materialID = item[2]
        Suite.Items:SetListIcon(row.icon, item[2])
        row.done = done == true
        row.check:SetShown(counts and counts[3] == true or false)
        row.quantity:SetText(item[1] .. " x"); row.quantity:SetTextColor(unpack(done and {0.4,0.46,0.49} or {0.9,0.75,0.48}))
        row.name:SetText(item[3] .. (item[4] and "  |cff9aaeb6(vendor)|r" or ""))
        row.name:SetTextColor(unpack(done and {0.4,0.46,0.49} or {0.88,0.91,0.93}))
        if done then
            row.have:SetText("—"); row.need:SetText("Done"); row.need:SetTextColor(0.4,0.46,0.49)
            row.sectionNeed:Hide(); row.totalSummary:Hide()
        else
            row.have:SetText(counts[1]); row.need:SetText(counts[2])
            row.need:SetTextColor(unpack(counts[3] and {0.41,0.84,0.75} or {1,0.74,0.44}))
            row.sectionNeed:SetText(here[2]); row.sectionNeed:Show()
            row.sectionNeed:SetTextColor(unpack(here[3] and {0.41,0.84,0.75} or {1,0.74,0.44}))
            row.totalSummary:SetText("All remaining: " .. total .. " required · Still need")
            row.totalSummary:Show()
        end
        row.have:SetTextColor(0.6,0.72,0.76)
        local height = math.max(24, row.name:GetStringHeight() + 6, row.have:GetStringHeight() + 8, row.sectionNeed:GetStringHeight() + 8)
        local summaryY = done and 4 or height
        row.need:ClearAllPoints(); row.need:SetPoint("TOPLEFT", 358, -summaryY)
        row.check:ClearAllPoints(); row.check:SetPoint("TOPLEFT", 340, -summaryY)
        row.totalSummary:ClearAllPoints(); row.totalSummary:SetPoint("TOPLEFT", 0, -summaryY)
        if not done then height = height + math.max(22, row.totalSummary:GetStringHeight() + 8, row.need:GetStringHeight() + 8) end
        row:SetSize(CONTENT_WIDTH, height); row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y); row:Show()
        y = y + height
    end
    if not shopping then Paragraph("No materials list for this guide."); return y end
    Paragraph("Saved character bags/banks + shared bank. + = incomplete; ≤ = upper estimate; ? = unknown.")
    Paragraph("Required here estimates this section's remaining inputs. Need here uses stock left after earlier sections. All remaining combines every unfinished section, subtracting stock once. Actual crafts may vary.")
    if shopping.note then Paragraph(shopping.note) end
    if #shopping == 0 then Paragraph("No unfinished recipe inputs in the available plan.") end
    local anyGroup = false
    local usedBefore = {}
    for _, group in ipairs(shopping) do
        local sectionTotals = {}
        local usedHere = {}
        for _, row in ipairs(group.rows) do
            if not doneRows[row] then
                for _, item in ipairs(row) do
                    local key = MaterialKey(item)
                    sectionTotals[key] = (sectionTotals[key] or 0) + item[1]
                end
            end
        end
        local visible = false
        for _, row in ipairs(group.rows) do
            if Visible(row) then visible = true; break end
        end
        if visible then
            anyGroup = true
            Paragraph(group.title, {0.41, 0.84, 0.75})
            local headerY = y
            Paragraph("Required here"); local headerEnd = y
            y = headerY; Paragraph("Have", nil, 264, 68)
            y = headerY; Paragraph("Need here", nil, 340, 70)
            y = math.max(y, headerEnd)
            for _, row in ipairs(group.rows) do
                local done = doneRows[row]
                if Visible(row) then
                    for _, item in ipairs(row) do
                        local key = MaterialKey(item)
                        Item(item, done, totals[key] or 0, item[1], (usedBefore[key] or 0) + (usedHere[key] or 0))
                    end
                end
                if not done then
                    for _, item in ipairs(row) do
                        local key = MaterialKey(item); usedHere[key] = (usedHere[key] or 0) + item[1]
                    end
                end
            end
            y = y + 14
        end
        for key, count in pairs(sectionTotals) do usedBefore[key] = (usedBefore[key] or 0) + count end
    end
    if #shopping > 0 and not anyGroup then Paragraph("No materials to get in the current view.", {0.41,0.84,0.75}) end
    return y
end
function Leveling:SectionHeader(field, title, key, offset)
    local frame = self.frame
    local header = frame[field]
    if not header then
        header = CreateFrame("Button", nil, frame.body, "BackdropTemplate")
        header:SetSize(CONTENT_WIDTH, 32); header:EnableMouse(true)
        Surface(header); header:SetBackdropColor(0.06, 0.15, 0.17, 1)
        header.label = Label(header, 14, 10, -8, CONTENT_WIDTH - 20)
        header.label:SetTextColor(0.41, 0.84, 0.75)
        header:SetScript("OnClick", function() self:ToggleView(key) end)
        frame[field] = header
    end
    header:ClearAllPoints(); header:SetPoint("TOPLEFT", 0, -offset)
    header.label:SetText((self:ViewOption(key) and "+  " or "−  ") .. title)
    return offset + 42
end
function Leveling:Cancel()
    if self.timer then self.timer:Cancel(); self.timer = nil end
    Suite.pending.professionLevelingRefresh = nil
end
function Leveling:Close()
    Suite.ProfessionRoutes:Reset()
    self.open = nil
    self.autoAttempt, self.autoTarget = nil, nil
    self:CloseGuideMenu()
    self:HideTooltip()
    if InCombatLockdown() then
        Suite.AfterCombat("professionLevelingRefresh", function() self:Close() end); return
    end
    if self.frame then self.frame.source:ClearFocus(); self.frame:Hide() end
end
function Leveling:Place()
    if InCombatLockdown() or not self:Enabled() or not Safe(self.owner) then return end
    local owner, frame = self.owner, self.frame
    local page = Field(owner, "CraftingPage")
    local link = Safe(page) and Field(page, "LinkButton")
    self.button:ClearAllPoints()
    if Shown(page) and Safe(link) then self.button:SetPoint("LEFT", link, "RIGHT", 10, 0)
    else self.button:SetPoint("TOPRIGHT", owner, "TOPRIGHT", -14, -40) end
    if not frame then return end
    local side, gap = "RIGHT", 58 -- Clear the native profession tabs.
    local right, left = Call(Field(owner, "GetRight"), owner), Call(Field(owner, "GetLeft"), owner)
    local scale, uiScale = Call(Field(owner, "GetEffectiveScale"), owner), Call(Field(UIParent, "GetEffectiveScale"), UIParent)
    local screen = Call(Field(UIParent, "GetWidth"), UIParent)
    if Number(right) and Number(left) and Number(scale) and scale > 0 and Number(uiScale) and uiScale > 0 and Number(screen) then
        local ratio = scale / uiScale
        local width = frame:GetWidth()
        if (right + gap + width) * ratio > screen and (left - 8 - width) * ratio >= 0 then side, gap = "LEFT", 8 end
    end
    frame:ClearAllPoints()
    if side == "LEFT" then frame:SetPoint("TOPRIGHT", owner, "TOPLEFT", -gap, 0)
    else frame:SetPoint("TOPLEFT", owner, "TOPRIGHT", gap, 0) end
end
function Leveling:TrackMaterials(sectionOnly)
    if not self:Enabled() or InCombatLockdown() or not self.open then return end
    local guide, rank = guides[self.selected], self:GuideSkill()
    if not guide or not guide.estimates or not Number(rank) then Suite.Print("Choose a modeled guide with a known skill level first."); return end
    local limit
    if sectionOnly then
        for _, section in ipairs(guide.sections) do
            if rank >= section[1] and rank < section[2] then limit = section[2]; break end
        end
        if not limit then Suite.Print("There is no unfinished section at this skill level."); return end
    end
    Suite.ShoppingList:ToggleReview(guide.name, rank, limit, self.frame)
end
function Leveling:CreatePanel()
    if self.frame or InCombatLockdown() then return end
    local frame = CreateFrame("Frame", nil, self.owner, "BackdropTemplate"); self.frame = frame
    frame:Hide(); frame:SetSize(WIDTH, 585); frame:SetClampedToScreen(true); frame:EnableMouse(true)
    frame:SetFrameStrata("HIGH"); frame:SetFrameLevel(520); Surface(frame)
    frame.title = Label(frame, 16, 14, -14, WIDTH - 62)
    frame.status = Label(frame, 11, 14, -40, WIDTH - 30)
    local close = Button(frame, "", 24, function() self:Close() end); close:SetPoint("TOPRIGHT", -8, -8)
    -- The compact text area can ellipsize an X; use font-independent strokes.
    for index = 1, 2 do
        local stroke = close:CreateLine(nil, "OVERLAY")
        local y = index == 1 and 4 or -4
        stroke:SetThickness(1.5); stroke:SetColorTexture(0.88, 0.91, 0.93, 1)
        stroke:SetStartPoint("CENTER", close, -4, y)
        stroke:SetEndPoint("CENTER", close, 4, -y)
    end
    frame.guideDropdown = GuideDropdown(frame, function() self:GuideMenu() end)
    frame.guideDropdown:SetPoint("TOPLEFT", 14, -64)
    local follow = Button(frame, "Current", 80, function() self:Refresh(true) end)
    follow:SetPoint("LEFT", frame.guideDropdown, "RIGHT", 8, 0)
    frame.hideDone = Button(frame, "Hide completed", 136, function() self:ToggleView("professionLevelingHideDone") end)
    frame.hideDone:SetPoint("LEFT", follow, "RIGHT", 8, 0)
    frame.hideDone:HookScript("OnEnter", function(button) self:CompletedTooltip(button) end)
    local function LeaveCompleted(button) if self.hovered == button then self:HideTooltip() end end
    frame.hideDone:HookScript("OnLeave", LeaveCompleted); frame.hideDone:HookScript("OnHide", LeaveCompleted)
    frame.scroll = Suite.GUI:CreateSuiteScrollFrame(frame)
    frame.scroll:SetPoint("TOPLEFT", 14, -98); frame.scroll:SetSize(CONTENT_WIDTH, 350)
    frame.scroll:HookScript("OnVerticalScroll", function() self:HideTooltip() end)
    frame:HookScript("OnHide", function() self:HideTooltip(); self:CloseGuideMenu() end)
    frame.body = CreateFrame("Frame", nil, frame.scroll); frame.body:SetWidth(CONTENT_WIDTH)
    frame.text = Label(frame.body, 13, 0, 0, CONTENT_WIDTH); frame.text:SetSpacing(4)
    frame.scroll:SetScrollChild(frame.body)
    frame.credit = Label(frame, 10, 14, -460, WIDTH - 28)
    frame.credit:SetWidth(286)
    frame.recipeBack = Button(frame, "Back to recipe", 134, function() Suite.ProfessionRoutes:Back() end)
    frame.recipeBack:SetPoint("TOPRIGHT", -14, -460); frame.recipeBack:Hide()
    local function CopyLink(url)
        if not url then return end
        self.url = url
        frame.source:SetText(url)
        frame.source:SetFocus(); frame.source:HighlightText()
    end
    local sourceButton = Button(frame, "Source link · Ctrl+C", 132, function()
        local guide = guides[self.selected]
        CopyLink(guide and guide.url)
    end)
    sourceButton:SetPoint("TOPLEFT", 14, -493)
    frame.autoSteps = Button(frame, "Auto steps: On", 144, function() self:ToggleView("professionLevelingAutoSteps") end)
    frame.autoSteps:SetPoint("LEFT", sourceButton, "RIGHT", 8, 0)
    frame.hideStocked = Button(frame, "Show Stocked", 134, function() self:ToggleView("professionLevelingHideStocked") end)
    frame.hideStocked:SetPoint("LEFT", frame.autoSteps, "RIGHT", 8, 0)
    frame.source = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    frame.source:SetAutoFocus(false); frame.source:SetSize(WIDTH - 40, 20); frame.source:SetPoint("TOPLEFT", 20, -522)
    frame.relatedSource = Button(frame, "Fishing + Cooking", 134, function()
        local guide = guides[self.selected]
        CopyLink(guide and guide.relatedURL)
    end)
    frame.relatedSource:SetPoint("TOPRIGHT", -14, -519)
    frame.source:SetFont("Fonts\\FRIZQT__.TTF", 10, ""); frame.source:SetMaxLetters(240)
    frame.source:SetScript("OnTextChanged", function(input)
        local expected = self.url or ""
        if Call(input.GetText, input) ~= expected then input:SetText(expected) end
    end)
    frame.source:SetScript("OnEscapePressed", function() self:Close() end)
    frame.source:SetScript("OnEnterPressed", function(input) input:ClearFocus() end)
    frame.source:SetScript("OnEditFocusGained", function(input) input:HighlightText() end)
    frame.sourceButton = sourceButton
    frame.trackSection = Button(frame, "Track section", 132, function() self:TrackMaterials(true) end)
    frame.trackSection:SetPoint("TOPLEFT", 14, -552)
    frame.trackRemaining = Button(frame, "Track remaining", 144, function() self:TrackMaterials(false) end)
    frame.trackRemaining:SetPoint("LEFT", frame.trackSection, "RIGHT", 8, 0)
    frame.shopping = Button(frame, "Shopping list", 134, function() Suite.ToggleWindow(Suite.ShoppingList, frame) end)
    frame.shopping:SetPoint("LEFT", frame.trackRemaining, "RIGHT", 8, 0)
    frame.follow, frame.close = follow, close
end
function Leveling:Render(reset)
    local frame = self.frame
    if not frame or InCombatLockdown() then return end
    self:CloseGuideMenu()
    local guide = guides[self.selected]
    local rank, maximum, snapshot = self:GuideSkill()
    frame.title:SetText(guide and guide.name .. " · Leveling" or "Profession Leveling")
    frame.status:SetText(rank and string.format(snapshot and "Saved skill: %d / %d · last recorded" or "Your skill: %d / %d", rank, maximum)
        or self.context == "unavailable" and "Profession data unavailable · browse a guide"
        or "Browse guides · choose Current to follow your profession")
    local offset = self:SectionHeader("materialsHeader", "Required materials", "professionLevelingMaterialsCollapsed", 0)
    offset = self:Materials(guide, offset)
    offset = Suite.ProfessionRoutes:Render(guide, rank, offset + 12)
    offset = self:SectionHeader("stepsHeader", "Leveling steps", "professionLevelingStepsCollapsed", offset + 12)
    local height = math.max(350, self:Steps(guide, rank, offset) + 12)
    frame.body:SetHeight(height)
    if reset then frame.scroll.suiteOffset = 0; frame.scroll:SetVerticalScroll(0) end
    Suite.GUI:SyncScrollBar(frame.scroll, math.max(0, height - 350))
    frame.scroll:SetVerticalScroll(frame.scroll.suiteOffset)
    Suite.ProfessionRoutes:AfterRender()
    frame.guideDropdown:SetText(guide and guide.name or "Choose profession")
    local canTrack = guide and guide.estimates ~= nil and Number(rank)
    frame.trackSection:SetEnabled(canTrack == true and rank < 300)
    frame.trackRemaining:SetEnabled(canTrack == true)
    frame.hideDone:SetText(self:ViewOption("professionLevelingHideDone") and "Show completed" or "Hide completed")
    frame.autoSteps:SetText(self:ViewOption("professionLevelingAutoSteps") and "Auto steps: On" or "Auto steps: Off")
    frame.hideStocked:SetText(self:ViewOption("professionLevelingHideStocked") and "Show Stocked" or "Hide Stocked")
    self.url = guide and guide.url or nil
    frame.source:ClearFocus(); frame.source:SetText(self.url or "")
    frame.sourceButton:SetEnabled(self.url ~= nil)
    local related = guide and guide.relatedURL ~= nil
    frame.relatedSource:SetShown(related == true)
    frame.source:SetWidth(related and WIDTH - 180 or WIDTH - 40)
    frame.credit:SetText("Original summary · WoW-Professions reference"
        .. (guide and "\nReviewed " .. guide.reviewed .. " · English" or ""))
end
function Leveling:Select(index)
    if not self:Enabled() or InCombatLockdown() or not self.open then return end
    self.selected = (index - 1) % #guides + 1
    Suite.ProfessionRoutes:Reset()
    self.stepContext, self.stepOverrides = nil, {}
    self:Render(true)
end
function Leveling:Refresh(follow)
    if not self:Enabled() or InCombatLockdown() or not Safe(self.owner) then return end
    local current, rank, context, maximum = self:Context()
    self:CaptureSkills()
    local own = true
    for _, name in ipairs({ "IsDataSourceChanging", "IsTradeSkillLinked", "IsTradeSkillGuild", "IsTradeSkillGuildMember", "IsNPCCrafting" }) do
        local fn = Field(C_TradeSkillUI, name)
        if Read(fn, "function") and Call(fn) ~= false then own = false end
    end
    if own then self:RememberSkill(current, rank, maximum) end
    local changed = context ~= self.context
    self.current, self.rank, self.maximum, self.context = current, rank, maximum, context
    if changed or follow then
        Suite.ProfessionRoutes:Reset()
        self.stepContext, self.stepOverrides = nil, {}
        if context then self.selected = current else self.selected = self.selected or 1 end
    end
    self:Place(); self.button:Show()
    if self.open then self:Render(changed or follow) end
    self:AutoSelectRecipe()
end
function Leveling:Queue()
    if not self:Enabled() then return end
    if InCombatLockdown() then
        Suite.AfterCombat("professionLevelingRefresh", function() self:Discover() end); return
    end
    if not self.timer and Read(Field(C_Timer, "NewTimer"), "function") then
        self.timer = C_Timer.NewTimer(0, function() self.timer = nil; self:Discover() end)
    end
end
function Leveling:Toggle()
    if not self:Enabled() or InCombatLockdown() or not Shown(self.owner) then return end
    if self.open then self:Close(); return end
    self:CreatePanel(); self.open = true; self:Refresh(true); self.frame:Show(); self:AutoSelectRecipe()
end
function Leveling:Discover()
    if not self:Enabled() or InCombatLockdown() then return end
    if not Safe(ProfessionsFrame) then self:CaptureSkills(); return end
    if self.owner ~= ProfessionsFrame then
        -- The native frame is a singleton. Never replace its scripts or stored profession data.
        self.owner = ProfessionsFrame
        self.button = Button(self.owner, "Leveling", 68, function() self:Toggle() end)
        self.button:SetFrameStrata("HIGH"); self.button:SetFrameLevel(520)
        self.owner:HookScript("OnShow", function() self.autoBlocked, self.autoAttempt, self.autoTarget = nil, nil, nil; self:Queue() end)
        self.owner:HookScript("OnHide", function()
            self:Cancel(); self.open, self.context = nil, nil
            self.autoAttempt, self.autoTarget, self.autoBlocked = nil, nil, nil
            Suite.AfterCombat("professionLevelingRefresh", function() self:Close() end)
        end)
        self.owner:HookScript("OnSizeChanged", function() if self:Enabled() then self:Queue() end end)
        if Read(hooksecurefunc, "function") then
            local page = Field(self.owner, "CraftingPage")
            if Read(Field(page, "CreateInternal"), "function") then
                hooksecurefunc(page, "CreateInternal", function() if self:Enabled() then self.autoCrafting = true end end)
            end
            for _, method in ipairs({ "SetProfessionInfo", "SelectBookPage" }) do
                if Read(Field(self.owner, method), "function") then hooksecurefunc(self.owner, method, function() self:Queue() end) end
            end
        end
    end
    if not self.open and self.frame then self:Close() end
    if Shown(self.owner) then self:Refresh() else self:CaptureSkills() end
end
function Leveling:Apply()
    if not self:Enabled() then
        self:Cancel(); self:StopWaypointArrow(); self.open = nil
        self.autoAttempt, self.autoTarget, self.autoBlocked, self.autoCrafting = nil, nil, nil, nil
        if self.events then self.events:UnregisterAllEvents() end
        self.active = nil
    end
    Suite.AfterCombat("professionLevelingApply", function()
        if not self:Enabled() then
            if self.button then self.button:Hide() end
            self:Close(); return
        end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event, unit)
                if event == "USER_WAYPOINT_UPDATED" then self:UpdateWaypointArrow(true); return end
                if (event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS"
                    or event == "PLAYER_STOPPED_MOVING") and not self.open then return end
                if event == "PLAYER_REGEN_DISABLED" then self:Cancel(); self:HideTooltip(); self:CloseGuideMenu(); self.open = nil; self.autoBlocked = true
                else
                    if event == "UPDATE_TRADESKILL_CAST_STOPPED" or ((event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED")
                        and Read(unit, "string") and unit == "player") then self.autoCrafting = nil end
                    self:Queue()
                end
            end)
        end
        if not self.active then
            for _, event in ipairs({ "ADDON_LOADED", "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE",
                "NEW_RECIPE_LEARNED", "TRADE_SKILL_DETAILS_UPDATE",
                "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "PLAYER_STOPPED_MOVING", "USER_WAYPOINT_UPDATED",
                "TRADE_SKILL_DATA_SOURCE_CHANGED", "SKILL_LINES_CHANGED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
                "UPDATE_TRADESKILL_CAST_STOPPED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_FAILED" }) do
                self.events:RegisterEvent(event)
            end
            self.active = true
        end
        -- Combat cancels an open flyout; it does not reopen automatically afterward.
        if not self.open then self:Close() end
        self:Discover()
    end)
end
