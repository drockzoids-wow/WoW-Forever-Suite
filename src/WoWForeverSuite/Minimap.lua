local _, Suite = ...
local Map = { widgets = {}, hidden = {}, clamps = {}, watched = {}, artWatched = {}, clampWatched = {} }
Suite.Minimap = Map
table.insert(Suite.modules, Map)

local function Available(frame)
    if not Suite.IsReadable(frame) or not frame then return false end
    if frame.IsForbidden then
        local forbidden = frame:IsForbidden()
        return Suite.IsReadable(forbidden) and forbidden == false
    end
    return true
end

local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function Dimension(value)
    return Number(value) and value > 0 and value <= 4096
end

function Map:ApplySize(enabled)
    if InCombatLockdown() or not Available(Minimap) or type(Minimap.SetSize) ~= "function" then return end
    local width, height = Minimap:GetWidth(), Minimap:GetHeight()
    if not Dimension(width) or not Dimension(height) then
        if not enabled then self.mapSize = nil end
        return
    end
    local original = self.mapSize
    if enabled and not original then
        original = { width = width, height = height }
        self.mapSize = original
    end
    if not original then return end
    if Dimension(original.width) and Dimension(original.height) then
        local targetWidth, targetHeight = original.width, original.height
        if enabled then
            -- Expand the shorter side in map units; Edit Mode still owns scale and anchors.
            local side = math.max(original.width, original.height)
            targetWidth, targetHeight = side, side
        end
        if width ~= targetWidth or height ~= targetHeight then
            self.changingSize = true
            Minimap:SetSize(targetWidth, targetHeight)
            self.changingSize = false
        end
    end
    if not enabled then self.mapSize = nil end
end

function Map:WatchSize()
    for _, method in ipairs({ "SetSize", "SetWidth", "SetHeight" }) do
        if type(Minimap[method]) == "function" then
            hooksecurefunc(Minimap, method, function(_, width, height)
                local original = self.mapSize
                if self.changingSize or not original then return end
                -- Retain native/owner requests, not our temporary square dimensions.
                -- Unreadable requests invalidate restoration rather than restoring stale geometry.
                if method == "SetHeight" then original.height = Dimension(width) and width or nil
                else
                    original.width = Dimension(width) and width or nil
                    if method == "SetSize" then original.height = Dimension(height) and height or nil end
                end
                self:Schedule()
            end)
        end
    end
end

function Map:ApplyQuestRing(enabled)
    if not Available(Minimap) or type(Minimap.SetQuestBlobRingScalar) ~= "function" then return end
    if not self.questRing then
        if not enabled then return end
        -- There is no native getter. One is the native ring's normal scale;
        -- remember later owner requests so disabling restores their preference.
        self.questRing = { scalar = 1 }
        hooksecurefunc(Minimap, "SetQuestBlobRingScalar", function(_, scalar)
            if self.changingQuestRing then return end
            local record = self.questRing
            if Number(scalar) and scalar >= 0 then
                record.scalar = scalar
            else
                -- An unknown owner value must not become a restoration guess.
                record.scalar, record.applied = nil, false
            end
            if Suite.db.squareMinimap then self:Schedule() end
        end)
    end
    local record = self.questRing
    if record.scalar == nil or not (enabled or record.applied) then return end
    self.changingQuestRing = true
    local ok = pcall(Minimap.SetQuestBlobRingScalar, Minimap, enabled and 0 or record.scalar)
    self.changingQuestRing = false
    if ok then record.applied = enabled end
end

function Map:ApplyClamping(enabled)
    Suite.AfterCombat("minimapClamping", function()
        self.changingClamp = true
        for _, frame in pairs({ MinimapCluster, Minimap, MinimapBackdrop }) do
            if Available(frame) and frame.IsClampedToScreen and frame.SetClampedToScreen then
                local original = self.clamps[frame]
                if enabled and not original then
                    local clamped = frame:IsClampedToScreen()
                    if Suite.IsReadable(clamped) and type(clamped) == "boolean" then
                        original = { clamped = clamped }
                        self.clamps[frame] = original
                        if not self.clampWatched[frame] then
                            self.clampWatched[frame] = true
                            hooksecurefunc(frame, "SetClampedToScreen", function()
                                if Suite.db.squareMinimap and not self.changingClamp then self:ApplyClamping(true) end
                            end)
                        end
                    end
                end
                if original then
                    if enabled then frame:SetClampedToScreen(false)
                    else frame:SetClampedToScreen(original.clamped); self.clamps[frame] = nil end
                end
            end
        end
        self.changingClamp = false
    end)
end

function Map:CancelTimer()
    if self.timer then self.timer:Cancel(); self.timer = nil end
end

function Map:Schedule()
    if self.changing or self.timer or not (Suite.db.squareMinimap or Suite.db.minimapStats) then return end
    if InCombatLockdown() then Suite.AfterCombat("minimap", function() self:Apply() end); return end
    self.timer = C_Timer.NewTimer(0, function()
        self.timer = nil
        self:Apply()
    end)
end

function Map:Remember(frame)
    if not Available(frame) then return false end
    if self.widgets[frame] then return true end
    -- The native clock FontString has no explicit size. Its rendered text extent
    -- must not become a fixed width/height when restoring the smaller font.
    local explicitClockSize = frame == TimeManagerClockTicker
    local original = { points = {}, width = frame:GetWidth(explicitClockSize), height = frame:GetHeight(explicitClockSize) }
    local count = frame:GetNumPoints()
    if not Number(original.width) or not Number(original.height) or original.width < 0 or original.height < 0 or not Number(count)
        or count < 0 or count > 8 or count ~= math.floor(count) then return false end
    if frame.GetFont then
        original.font = { frame:GetFont() }
        for _, value in pairs(original.font) do if not Suite.IsReadable(value) then return false end end
    end
    for i = 1, count do
        local point = { frame:GetPoint(i) }
        for _, value in pairs(point) do if not Suite.IsReadable(value) then return false end end
        original.points[i] = point
    end
    if frame.GetFrameLevel then
        original.scale, original.level, original.strata = frame:GetScale(), frame:GetFrameLevel(), frame:GetFrameStrata()
        if not Number(original.scale) or original.scale <= 0 or not Number(original.level)
            or not Suite.IsReadable(original.strata) or type(original.strata) ~= "string" then return false end
    end
    self.widgets[frame] = original
    if not self.watched[frame] then
        self.watched[frame] = true
        if frame.GetFrameLevel then
            hooksecurefunc(frame, "SetScale", function() self:Schedule() end)
            frame:HookScript("OnShow", function() self:Schedule() end)
            frame:HookScript("OnHide", function() self:Schedule() end)
        end
        hooksecurefunc(frame, "SetPoint", function() self:Schedule() end)
    end
    return true
end

function Map:Place(frame, point, relative, relativePoint, x, y, diameter)
    if not self:Remember(frame) then return false end
    local parent = frame:GetParent()
    local scale = parent and parent:GetEffectiveScale() or 1
    local mapScale = Minimap:GetEffectiveScale()
    if not Number(scale) or not Number(mapScale) or scale <= 0 or mapScale <= 0 then return false end
    -- Keep native ownership and scripts; match the map's units without reparenting.
    local widgetScale = mapScale / scale
    if diameter then
        local original = self.widgets[frame]
        local extent = math.max(original.width, original.height)
        if extent <= 0 then return false end
        -- Scale the entire native day/night atlas, including its dynamic background.
        widgetScale = widgetScale * diameter / extent
    end
    frame:SetScale(widgetScale)
    frame:SetFrameStrata(Minimap:GetFrameStrata())
    frame:SetFrameLevel(self.header:GetFrameLevel() + 1)
    frame:ClearAllPoints()
    frame:SetPoint(point, relative, relativePoint, x, y)
    return true
end

function Map:HideZoneArt(zone)
    if not Available(zone) or not Available(zone.StateTexture) or not Available(zone.AddTexture)
        or type(zone.StateTexture.GetDrawLayer) ~= "function" or type(zone.AddTexture.GetDrawLayer) ~= "function"
        or type(zone.IsDrawLayerEnabled) ~= "function" or type(zone.DisableDrawLayer) ~= "function"
        or type(zone.EnableDrawLayer) ~= "function" then return end
    local stateLayer, addLayer = zone.StateTexture:GetDrawLayer(), zone.AddTexture:GetDrawLayer()
    if not Suite.IsReadable(stateLayer) or not Suite.IsReadable(addLayer)
        or stateLayer ~= "BACKGROUND" or addLayer ~= "BACKGROUND" or not self:Remember(zone) then return end
    local original = self.widgets[zone]
    if original.backgroundLayer == nil then
        local enabled = zone:IsDrawLayerEnabled("BACKGROUND")
        if not Suite.IsReadable(enabled) or type(enabled) ~= "boolean" then return end
        original.backgroundLayer = enabled
    end
    -- This build keeps both decorative state textures here. Disabling their layer
    -- survives native hover/press SetShown calls without replacing button behavior.
    zone:DisableDrawLayer("BACKGROUND")
end

function Map:HideHeaderArt(frame)
    if not Available(frame) then return end
    if not self.hidden[frame] then
        local shown = frame:IsShown()
        if not Suite.IsReadable(shown) or type(shown) ~= "boolean" then return end
        self.hidden[frame] = { shown = shown }
        if not self.artWatched[frame] then
            self.artWatched[frame] = true
            hooksecurefunc(frame, "Show", function() self:Schedule() end)
        end
    end
    frame:Hide()
end

function Map:RestoreHeader()
    for frame, original in pairs(self.widgets) do
        if Available(frame) then
            frame:ClearAllPoints()
            for _, point in ipairs(original.points) do frame:SetPoint(unpack(point)) end
            frame:SetSize(original.width, original.height)
            if original.font and original.font[1] then frame:SetFont(unpack(original.font)) end
            if original.scale then
                frame:SetScale(original.scale)
                frame:SetFrameLevel(original.level)
                frame:SetFrameStrata(original.strata)
            end
            if original.backgroundLayer ~= nil then
                if original.backgroundLayer then frame:EnableDrawLayer("BACKGROUND")
                else frame:DisableDrawLayer("BACKGROUND") end
            end
            self.widgets[frame] = nil
        end
    end
    for frame, original in pairs(self.hidden) do
        if Available(frame) then frame:SetShown(original.shown); self.hidden[frame] = nil end
    end
    self.header:Hide()
end

function Map:LayoutHeader()
    local cluster = MinimapCluster
    self.header:SetFrameStrata(Minimap:GetFrameStrata())
    self.header:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    local zone = cluster and cluster.ZoneTextButton or MinimapZoneTextButton
    local tracking = cluster and cluster.Tracking
    local calendar, clock = GameTimeFrame, TimeManagerClockButton
    local left, right = 8, 8
    if Available(tracking) and self:Place(tracking, "LEFT", self.header, "LEFT", 6, 0) then
        tracking:SetSize(20, 20)
        if Available(tracking.Button) and self:Remember(tracking.Button) then tracking.Button:SetSize(18, 18) end
        left = 30
    end
    if Available(calendar) and self:Place(calendar, "RIGHT", self.header, "RIGHT", -6, 0) then
        calendar:SetSize(20, 20)
        right = 30
    end
    local diel = cluster and cluster.DielFrame
    local hasDiel = Available(diel) and self:Place(diel, "CENTER", self.header.daySlot, "CENTER", 0, 0, 20)
    self.header.daySlot:SetShown(hasDiel)
    if hasDiel then left = 56 end
    if Available(clock) and clock:IsShown() and self:Place(clock, "BOTTOM", Minimap, "BOTTOM", 0, 8) then
        clock:SetSize(64, 24)
        if Available(TimeManagerClockTicker) and self:Remember(TimeManagerClockTicker) then
            local original = self.widgets[TimeManagerClockTicker].font
            if original and original[1] then TimeManagerClockTicker:SetFont(original[1], 14, "OUTLINE") end
            TimeManagerClockTicker:SetSize(0, 0)
            TimeManagerClockTicker:ClearAllPoints()
            TimeManagerClockTicker:SetPoint("CENTER", clock, "CENTER", 0, 0)
        end
    end
    local labelWidth = math.max(24, Minimap:GetWidth() - left - right)
    local labelOffset = (left - right) / 2
    self.header.zone = zone
    if Available(zone) and self:Place(zone, "CENTER", self.header, "CENTER", labelOffset, 0) then
        zone:SetSize(labelWidth, 32)
    end
    self.header.area:ClearAllPoints()
    self.header.area:SetPoint("TOP", labelOffset, -4)
    self.header.subzone:ClearAllPoints()
    self.header.subzone:SetPoint("BOTTOM", labelOffset, 5)
    self.header.area:SetWidth(labelWidth)
    self.header.subzone:SetWidth(labelWidth)
    self:HideHeaderArt(MinimapZoneText)
    self:HideZoneArt(zone)
    self:UpdateZone()
    if cluster then
        self:HideHeaderArt(cluster.BorderTop)
        if Available(cluster.InstanceDifficulty) then
            self:Place(cluster.InstanceDifficulty, "TOPRIGHT", Minimap, "TOPRIGHT", -4, -4)
        end
        if Available(cluster.IndicatorFrame) then
            self:Place(cluster.IndicatorFrame, "TOPLEFT", Minimap, "TOPLEFT", 4, -4)
        end
    end
    self:HideHeaderArt(MinimapBorderTop)
    self.header:Show()
end

local function FitLabel(label, text, size, minimum)
    label:SetText(text)
    label:SetWordWrap(false)
    label:SetFont("Fonts\\FRIZQT__.TTF", size)
    local width = label.GetUnboundedStringWidth and label:GetUnboundedStringWidth()
    local available = label:GetWidth()
    while Number(width) and width > available and size > minimum do
        size = size - 1
        label:SetFont("Fonts\\FRIZQT__.TTF", size)
        width = label:GetUnboundedStringWidth()
    end
    label:SetWordWrap(Number(width) and width > available)
    label:SetNonSpaceWrap(true)
    local height = label.GetStringHeight and label:GetStringHeight()
    height = Number(height) and math.max(size + 2, height) or size + 2
    label:SetHeight(height)
    return height
end

function Map:UpdateZone()
    if not self.header or not Suite.db.squareMinimap then return end
    local function ReadText(callback)
        local text = callback and callback()
        if Suite.IsReadable(text) and type(text) == "string" then return text end
        return ""
    end
    local area = ReadText(GetRealZoneText)
    if area == "" then area = ReadText(GetZoneText) end
    local subzone = ReadText(GetSubZoneText)
    if subzone == "" then subzone = ReadText(GetMinimapZoneText) end
    local areaHeight = FitLabel(self.header.area, area, 12, 10)
    local subzoneHeight = FitLabel(self.header.subzone, subzone, 10, 9)
    local height = math.max(36, areaHeight + subzoneHeight + 10)
    Suite.AfterCombat("minimapZoneLayout", function()
        if not Suite.db.squareMinimap then return end
        self.header:SetHeight(height)
        if Available(self.header.zone) then self.header.zone:SetHeight(height - 4) end
    end)
end

function Map:LayoutStats()
    local container = MinimapCluster and MinimapCluster.MinimapContainer
    local coords = container and container.PlayerCoords
    self.panel:ClearAllPoints()
    self.coordinates:ClearAllPoints()
    self.coordinates:SetPoint("TOP", Minimap, "BOTTOM", 0, -6)
    self.coordinates:SetWidth(Minimap:GetWidth())
    if Suite.db.minimapStats and Suite.db.showCoordinates then
        self.panel:SetPoint("TOP", self.coordinates, "BOTTOM", 0, -4)
    elseif Available(coords) then
        -- Blizzard owns this coordinate band even while its text is empty.
        self.panel:SetPoint("TOP", coords, "BOTTOM", 0, -6)
    else
        self.panel:SetPoint("TOP", Minimap, "BOTTOM", 0, -6)
    end
    self.panel:SetWidth(Minimap:GetWidth())
end

function Map:ReadCoordinates()
    if not C_Map or type(C_Map.GetBestMapForUnit) ~= "function" or type(C_Map.GetPlayerMapPosition) ~= "function" then return end
    local mapID = C_Map.GetBestMapForUnit("player")
    if not Number(mapID) or mapID <= 0 or mapID ~= math.floor(mapID) then return end
    local position = C_Map.GetPlayerMapPosition(mapID, "player")
    if not Suite.IsReadable(position) or not position or type(position.GetXY) ~= "function" then return end
    local x, y = position:GetXY()
    if not Number(x) or not Number(y) or x < 0 or x > 1 or y < 0 or y > 1 or (x == 0 and y == 0) then return end
    return { mapID = mapID, x = x, y = y }
end

function Map:ApplyCoordinates()
    local container = MinimapCluster and MinimapCluster.MinimapContainer
    local native = container and container.PlayerCoords
    local enabled = Suite.db.minimapStats and Suite.db.showCoordinates
    -- Preserve native scripts, layout and CVar; restore its original opacity on opt-out.
    if self.nativeCoordinates and (not enabled or self.nativeCoordinates.frame ~= native) then
        self.nativeCoordinates.frame:SetAlpha(self.nativeCoordinates.alpha)
        self.nativeCoordinates = nil
    end
    if enabled and Available(native) and native.GetAlpha and native.SetAlpha then
        local alpha = native:GetAlpha()
        if not self.nativeCoordinates and Number(alpha) then self.nativeCoordinates = { frame = native, alpha = alpha } end
        if self.nativeCoordinates then native:SetAlpha(0) end
    end
    self.coordinates:SetShown(enabled)
    if not enabled and self.tell then self.tell:Hide() end
end

function Map:CoordinateMessage(location)
    local text = string.format("%.1f, %.1f", location.x * 100, location.y * 100)
    if C_Map.GetMapInfo then
        local info = C_Map.GetMapInfo(location.mapID)
        if Suite.IsReadable(info) and info and Suite.IsReadable(info.name) and type(info.name) == "string" then
            text = info.name .. " " .. text
        end
    end
    -- Native map pins use the same public link as the world map's Share action.
    -- Only place a pin after an explicit destination click, never while opening the menu.
    if C_Map.CanSetUserWaypointOnMap and C_Map.SetUserWaypoint and C_Map.GetUserWaypointHyperlink
        and UiMapPoint and UiMapPoint.CreateFromCoordinates then
        local allowed = C_Map.CanSetUserWaypointOnMap(location.mapID)
        if Suite.IsReadable(allowed) and allowed == true then
            local ok, wasSet = pcall(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(location.mapID, location.x, location.y))
            if ok and Suite.IsReadable(wasSet) and wasSet == true then
                local link = C_Map.GetUserWaypointHyperlink()
                if Suite.IsReadable(link) and type(link) == "string" and link ~= "" then text = text .. " " .. link end
            end
        end
    end
    return text
end

function Map:SendCoordinates(location, channel, target)
    if InCombatLockdown() or not Suite.db.minimapStats or not Suite.db.showCoordinates or not location then return false end
    local chat = C_ChatInfo
    local locked
    if chat and type(chat.InChatMessagingLockdown) == "function" then locked = chat.InChatMessagingLockdown() end
    if not chat or type(chat.SendChatMessage) ~= "function" or not Suite.IsReadable(locked) or locked ~= false then
        Suite.Print("Coordinate sharing is restricted or unavailable right now.")
        return false
    end
    local ok = pcall(chat.SendChatMessage, self:CoordinateMessage(location), channel, nil, target)
    if not ok then Suite.Print("The game could not send your coordinates. Please try again.") end
    -- Native chat has no delivery result; this reports an attempted send only.
    return ok
end

local function CoordinateRecipient(name)
    if not Suite.IsReadable(name) or type(name) ~= "string" or #name > 100 or name:find("[%z\1-\31\127/|]") then return end
    name = name:match("^%s*(.-)%s*$"):gsub(" +", " ")
    if name:match("^%S+ %S+$") then return name end
end

function Map:CoordinateRecipients(saved)
    local names, seen = {}, {}
    if not Suite.IsReadable(saved) or type(saved) ~= "table" then return names end
    for i = 1, 5 do
        local name = CoordinateRecipient(saved[i])
        if name and not seen[name:lower()] then
            names[#names + 1], seen[name:lower()] = name, true
        end
    end
    return names
end

function Map:RememberCoordinateRecipient(name)
    local names = { name }
    for _, previous in ipairs(self:CoordinateRecipients(Suite.db.coordinateTellHistory)) do
        if previous:lower() ~= name:lower() and #names < 5 then names[#names + 1] = previous end
    end
    Suite.db.coordinateTellHistory = names
end

function Map:OpenCoordinateRecipients()
    if InCombatLockdown() or not self.tell or not self.tell:IsShown() or not Suite.db.minimapStats
        or not Suite.db.showCoordinates or not Suite.Menus or type(Suite.Menus.CreateContextMenu) ~= "function" then return end
    Suite.Menus.CreateContextMenu(self.tell.recent, function(_, root)
        root:CreateTitle("Recent recipients")
        for _, name in ipairs(self:CoordinateRecipients(Suite.db.coordinateTellHistory)) do
            root:CreateButton(name, function()
                if InCombatLockdown() or not self.tell:IsShown() or not Suite.db.minimapStats or not Suite.db.showCoordinates then return end
                self.tell.input:SetText(name)
                self.tell.input:SetFocus()
            end)
        end
    end)
end

function Map:AskCoordinateRecipient(location)
    if InCombatLockdown() or not Suite.db.minimapStats or not Suite.db.showCoordinates then return end
    if not self.tell then
        local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        self.tell = frame
        frame:SetSize(290, 100)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        frame:SetBackdropColor(0.055, 0.075, 0.085, 1)
        Suite.Theme:Backdrop(frame, 1)
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        title:SetPoint("TOP", 0, -10)
        title:SetText("Tell: first and last name")
        frame.input = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        frame.input:SetSize(166, 22)
        frame.input:SetPoint("TOPLEFT", 20, -30)
        frame.input:SetAutoFocus(false)
        frame.input:SetMaxLetters(100)
        local function Send()
            local name = CoordinateRecipient(frame.input:GetText())
            if not name then
                Suite.Print("Enter the player's first and last name, for example Jawn Online.")
                return
            end
            -- Pass the complete Forever name as the native whisper target, not slash text.
            if self:SendCoordinates(frame.location, "WHISPER", name) then
                self:RememberCoordinateRecipient(name)
                frame:Hide()
            end
        end
        frame.input:SetScript("OnEnterPressed", Send)
        frame.input:SetScript("OnEscapePressed", function() frame:Hide() end)
        frame:SetScript("OnHide", function() frame.input:ClearFocus(); frame.location = nil end)
        frame.recent = Suite.Theme:ActionButton(frame, "Recent", 80, 22)
        frame.recent:SetSize(80, 22)
        frame.recent:SetPoint("TOPRIGHT", -12, -30)
        frame.recent:SetText("Recent")
        frame.recent:SetScript("OnClick", function() self:OpenCoordinateRecipients() end)
        local ready = Suite.Theme:ActionButton(frame, "Send coordinates", 130, 22)
        ready:SetSize(130, 22); ready:SetPoint("BOTTOMLEFT", 12, 10); ready:SetText("Send coordinates")
        ready:SetScript("OnClick", Send)
        local cancel = Suite.Theme:ActionButton(frame, "Cancel", 110, 22)
        cancel:SetSize(110, 22); cancel:SetPoint("BOTTOMRIGHT", -12, 10); cancel:SetText("Cancel")
        cancel:SetScript("OnClick", function() frame:Hide() end)
    end
    self.tell.location = location
    self.tell.input:SetText("")
    self.tell.recent:SetEnabled(#self:CoordinateRecipients(Suite.db.coordinateTellHistory) > 0)
    self.tell:Show()
    self.tell.input:SetFocus()
end

function Map:OpenCoordinateMenu()
    if InCombatLockdown() or not Suite.db.minimapStats or not Suite.db.showCoordinates
        or not Suite.Menus or type(Suite.Menus.CreateContextMenu) ~= "function" then return end
    local location = self:ReadCoordinates()
    Suite.Menus.CreateContextMenu(self.coordinates, function(_, root)
        root:CreateTitle(location and string.format("Share %.1f, %.1f", location.x * 100, location.y * 100) or "Coordinates unavailable")
        if not location then return end
        local function Add(label, channel, target)
            root:CreateButton(label, function() self:SendCoordinates(location, channel, target) end)
        end
        Add("Say", "SAY")
        Add("Yell", "YELL")
        root:CreateButton("Tell...", function() self:AskCoordinateRecipient(location) end)
        local function Active(callback, ...)
            if type(callback) ~= "function" then return false end
            local value = callback(...)
            return Suite.IsReadable(value) and value == true
        end
        if Active(IsInGuild) then Add("Guild", "GUILD") end
        if Active(IsInGroup) then Add("Party", "PARTY") end
        if Active(IsInRaid) then Add("Raid", "RAID") end
        if LE_PARTY_CATEGORY_INSTANCE and Active(IsInGroup, LE_PARTY_CATEGORY_INSTANCE) then Add("Instance", "INSTANCE_CHAT") end
        if type(GetChannelList) == "function" then
            local channels = { GetChannelList() }
            for i = 1, #channels, 3 do
                local id, name, disabled = channels[i], channels[i + 1], channels[i + 2]
                if Number(id) and id > 0 and id == math.floor(id) and Suite.IsReadable(name) and type(name) == "string"
                    and Suite.IsReadable(disabled) and (disabled == false or disabled == nil) then
                    local regional = C_ChatInfo and Active(C_ChatInfo.IsChannelRegional, id)
                    if not regional or Active(C_ChatInfo.IsRegionalServiceAvailable) then
                        Add(string.format("%d. %s", id, name), "CHANNEL", tostring(id))
                    end
                end
            end
        end
    end)
end

local function CreateInfoBar()
    local bar = CreateFrame("Button", nil, Minimap, "BackdropTemplate")
    bar:SetHeight(20)
    bar.ignoreInLayout = true
    bar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    bar:SetBackdropColor(0.055, 0.075, 0.085, 0.65)
    Suite.Theme:Backdrop(bar, 1)
    bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.text:SetPoint("CENTER")
    bar.text:SetPoint("LEFT", 8, 0)
    bar.text:SetPoint("RIGHT", -8, 0)
    bar.text:SetTextColor(0.8, 0.88, 0.9)
    bar.text:SetWordWrap(false)
    bar:Hide()
    return bar
end

function Map:Initialize()
    if self.initialized or not Available(Minimap) then return end
    self.initialized = true
    self:WatchSize()
    self.border = CreateFrame("Frame", nil, Minimap, "BackdropTemplate")
    self.border.ignoreInLayout = true
    self.border:SetPoint("TOPLEFT", -1, 1)
    self.border:SetPoint("BOTTOMRIGHT", 1, -1)
    self.border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    Suite.Theme:Backdrop(self.border, 1)
    self.border:Hide()
    self.coordinates = CreateInfoBar()
    self.coordinates:SetScript("OnClick", function() self:OpenCoordinateMenu() end)
    self.coordinates:SetScript("OnEnter", function(button)
        if not GameTooltip or not GameTooltip.SetOwner then return end
        GameTooltip:SetOwner(button, "ANCHOR_LEFT")
        GameTooltip:AddLine("Share coordinates")
        GameTooltip:AddLine("Choose a channel to send immediately. Includes a map pin where available.", 0.8, 0.88, 0.9, true)
        GameTooltip:Show()
    end)
    self.coordinates:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    self.panel = CreateInfoBar()
    self.panel:SetScript("OnClick", function() Suite.GUI:Toggle() end)
    self.panel:Hide()
    self.header = CreateFrame("Frame", nil, Minimap, "BackdropTemplate")
    self.header.ignoreInLayout = true
    self.header:SetPoint("BOTTOMLEFT", self.border, "TOPLEFT", 0, 2)
    self.header:SetPoint("BOTTOMRIGHT", self.border, "TOPRIGHT", 0, 2)
    self.header:SetHeight(36)
    self.header:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    self.header:SetBackdropColor(0.055, 0.075, 0.09, 0.65)
    Suite.Theme:Backdrop(self.header, 1)
    self.header.daySlot = CreateFrame("Frame", nil, self.header)
    self.header.daySlot.ignoreInLayout = true
    self.header.daySlot:SetSize(20, 20)
    self.header.daySlot:SetPoint("LEFT", self.header, "LEFT", 30, 0)
    self.header.daySlot:Hide()
    self.header.area = self.header:CreateFontString(nil, "OVERLAY")
    self.header.area:SetFont("Fonts\\FRIZQT__.TTF", 12)
    self.header.area:SetPoint("TOP", 0, -4)
    self.header.area:SetHeight(14)
    self.header.area:SetTextColor(0.9, 0.72, 0.4)
    self.header.subzone = self.header:CreateFontString(nil, "OVERLAY")
    self.header.subzone:SetFont("Fonts\\FRIZQT__.TTF", 10)
    self.header.subzone:SetPoint("BOTTOM", 0, 5)
    self.header.subzone:SetHeight(12)
    self.header.subzone:SetTextColor(0.55, 0.65, 0.7)
    for _, label in ipairs({ self.header.area, self.header.subzone }) do
        label:SetJustifyH("CENTER")
        label:SetWordWrap(false)
    end
    self.header:Hide()
    self.events = CreateFrame("Frame")
    self.events:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            if self.tell then self.tell:Hide() end
            self:CancelTimer()
            Suite.AfterCombat("minimap", function() self:Apply() end)
        elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" then
            self:UpdateZone()
        else
            self:Schedule()
        end
    end)
    Minimap:HookScript("OnSizeChanged", function() self:Schedule() end)
    self.decorations = {}
    for _, name in ipairs({ "MinimapBorder", "MinimapBorderTop", "MinimapCompassTexture", "MinimapCompassTextureUnderlay" }) do
        local region = _G[name]
        if region then
            self.decorations[region] = { shown = region:IsShown() }
            hooksecurefunc(region, "Show", function()
                if Suite.db and Suite.db.squareMinimap and not self.changing then
                    Suite.AfterCombat("minimap", function() self:Apply() end)
                end
            end)
        end
    end
    self.originalShape = GetMinimapShape
    self.shape = function()
        if Suite.db.squareMinimap then return "SQUARE" end
        return self.originalShape and self.originalShape() or "ROUND"
    end
    hooksecurefunc(Minimap, "SetMaskTexture", function()
        if Suite.db and Suite.db.squareMinimap and not self.changing then self:Apply() end
    end)
end

function Map:UpdateStats()
    if not self.panel or not Suite.db.minimapStats then return end
    local db, values = Suite.db, {}
    local location = db.showCoordinates and self:ReadCoordinates()
    self.coordinates.text:SetText(location and string.format("%.1f, %.1f", location.x * 100, location.y * 100) or "--, --")
    if db.showFPS then
        local fps = GetFramerate()
        if Number(fps) then values[#values + 1] = string.format("%d |cff8ca6b3FPS|r", math.floor(fps)) end
    end
    if db.showLatency then
        local _, _, home, world = GetNetStats()
        local latencies = {}
        if Number(home) then latencies[#latencies + 1] = string.format("|cff8ca6b3H:|r %d |cff8ca6b3ms|r", home) end
        if Number(world) then latencies[#latencies + 1] = string.format("|cff8ca6b3W:|r %d |cff8ca6b3ms|r", world) end
        if #latencies > 0 then values[#values + 1] = table.concat(latencies, " ") end
    end
    if db.showClock and not (Available(TimeManagerClockButton) and TimeManagerClockButton:IsVisible()) then
        values[#values + 1] = date("%H:%M")
    end
    self.panel.text:SetText(table.concat(values, " |cff42605f/|r "))
    self.panel:SetShown(#values > 0)
end

function Map:Apply()
    self:CancelTimer()
    if not Suite.db.squareMinimap then Suite.pending.minimapZoneLayout = nil end
    Suite.AfterCombat("minimap", function()
        if not self.initialized and (Suite.db.squareMinimap or Suite.db.minimapStats) then self:Initialize() end
        if not self.initialized then return end
        self.changing = true
        self:ApplySize(Suite.db.squareMinimap)
        self:ApplyClamping(Suite.db.squareMinimap)
        self:ApplyQuestRing(Suite.db.squareMinimap)
        self:ApplyCoordinates()
        self.events:UnregisterAllEvents()
        if Suite.db.squareMinimap or Suite.db.minimapStats then
            self.events:RegisterEvent("ADDON_LOADED")
            self.events:RegisterEvent("CVAR_UPDATE")
            self.events:RegisterEvent("PLAYER_REGEN_DISABLED")
            self:LayoutStats()
        end
        if Suite.db.squareMinimap then
            -- Re-enable takes a new native baseline without attaching duplicate hooks.
            if not self.wasSquare then
                if GetMinimapShape ~= self.shape then self.originalShape = GetMinimapShape end
                for region, original in pairs(self.decorations) do
                    if Available(region) then
                        local shown = region:IsShown()
                        if Suite.IsReadable(shown) and type(shown) == "boolean" then original.shown = shown end
                    end
                end
            end
            self.events:RegisterEvent("ZONE_CHANGED")
            self.events:RegisterEvent("ZONE_CHANGED_INDOORS")
            self.events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
            Minimap:SetMaskTexture("Interface\\AddOns\\" .. Suite.name .. "\\Media\\SquareMask")
            for region in pairs(self.decorations) do region:Hide() end
            GetMinimapShape = self.shape
            self.border:Show()
            self:LayoutHeader()
            self.wasSquare = true
        elseif self.wasSquare then
            self:RestoreHeader()
            Minimap:SetMaskTexture("ui-hud-minimap-frame-generic-mask")
            for region, original in pairs(self.decorations) do region:SetShown(original.shown) end
            if GetMinimapShape == self.shape then GetMinimapShape = self.originalShape end
            self.border:Hide()
            self.wasSquare = false
        end
        self.panel:SetShown(Suite.db.minimapStats)
        if Suite.db.minimapStats and not self.ticker then
            self.ticker = C_Timer.NewTicker(1, function() self:UpdateStats() end)
        elseif not Suite.db.minimapStats and self.ticker then
            self.ticker:Cancel()
            self.ticker = nil
        end
        self.changing = false
        self:UpdateStats()
    end)
end
