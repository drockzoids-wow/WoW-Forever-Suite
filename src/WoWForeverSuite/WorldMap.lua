local _, Suite = ...
local Map = { pins = {}, watchedMaps = {} }
Suite.WorldMap = Map
table.insert(Suite.modules, Map)

local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function ID(value)
    return Number(value) and value > 0 and value % 1 == 0
end
local function Table(value)
    return Suite.IsReadable(value) and type(value) == "table"
end
local function Widget(value)
    if not Suite.IsReadable(value) or (type(value) ~= "table" and type(value) ~= "userdata") then return false end
    for _, method in ipairs({ "IsForbidden", "IsAnchoringRestricted" }) do
        if value[method] then
            local restricted = value[method](value)
            if not Suite.IsReadable(restricted) or restricted ~= false then return false end
        end
    end
    return true
end
local function Writable(value)
    if not Widget(value) then return false end
    if not InCombatLockdown() then return true end
    if type(value.IsProtected) ~= "function" then return false end
    local protected = value:IsProtected()
    return Suite.IsReadable(protected) and protected == false
end

function Map:Enabled()
    return Suite.db and Suite.IsReadable(Suite.db.revealWorldMap) and Suite.db.revealWorldMap == true
end

function Map:Opacity(db)
    local value = (db or Suite.db or {}).mapRevealOpacity
    if not Number(value) then return 0.6 end
    return math.floor(math.max(0, math.min(1, value)) * 100 + 0.5) / 100
end

function Map:SetOpacity(value)
    if not Suite.db or not Number(value) then return end
    Suite.Set("mapRevealOpacity", self:Opacity({ mapRevealOpacity = value }))
end

function Map:Hide(pin)
    if not Widget(pin) then return end
    local record = self.pins[pin]
    if not record then return end
    local deferred = false
    for _, pool in ipairs({ record.textures, record.coverTextures }) do
        for _, texture in ipairs(pool) do
            if Writable(texture) then texture:Hide() else deferred = true end
        end
    end
    if deferred and InCombatLockdown() then Suite.AfterCombat("worldMap", function() self:Apply() end) end
end

function Map:Prepare(pin, map, record)
    if InCombatLockdown() then return end
    if not self.capacity then
        self.capacity = 0
        for _, data in pairs(Suite.MapRevealData) do
            local count = 0
            for _, overlay in ipairs(data.overlays) do count = count + #overlay[5] end
            self.capacity = math.max(self.capacity, count)
        end
    end
    -- Prepare a bounded pool for every supported zone so map navigation needs no combat construction/masking.
    for i = #record.textures + 1, self.capacity do
        for _, layer in ipairs({ { record.textures, -1 }, { record.coverTextures, -2 } }) do
            local texture = pin:CreateTexture(nil, "BACKGROUND", nil, layer[2])
            layer[1][i] = texture
            if layer[2] == -2 then texture:SetVertexColor(0, 0, 0, 1) end
            texture:Hide()
            map:AddMaskableTexture(texture)
        end
    end
end

local function ExplorationKey(info)
    if not Table(info) or not Table(info.fileDataIDs) then return end
    local values = { info.textureWidth, info.textureHeight, info.offsetX, info.offsetY }
    -- Validate all four positions, including nil fields which ipairs would skip.
    for i = 1, 4 do if not Number(values[i]) then return end end
    local count = #info.fileDataIDs
    if count > 128 then return end
    for i = 1, count do
        local file = info.fileDataIDs[i]
        if not ID(file) then return end
        values[#values + 1] = file
    end
    return table.concat(values, ":")
end

local function FileSize(pixels, tileSize)
    if pixels == tileSize then return tileSize end
    local size = 16
    while size < pixels do size = size * 2 end
    return size
end

function Map:Render(pin)
    self:Hide(pin)
    if not self:Enabled() then return end
    if InCombatLockdown() then Suite.AfterCombat("worldMap", function() self:Apply() end) end
    if not Widget(pin) or not pin.GetMap or not pin.CreateTexture or not C_Map
        or not C_Map.GetMapArtID or not C_Map.GetMapArtLayers or not C_MapExplorationInfo
        or not C_MapExplorationInfo.GetExploredMapTextures then return end
    local map = pin:GetMap()
    if not Widget(map) or map ~= self.map or not map.GetMapID or not map.GetCanvasContainer or not map.IsShown
        or not map.AddMaskableTexture then return end
    if not Writable(pin) or not Writable(map) then
        Suite.AfterCombat("worldMap", function() self:Apply() end); return
    end
    local shown = map:IsShown()
    if not Suite.IsReadable(shown) or shown ~= true then return end
    local mapID = map:GetMapID()
    if not ID(mapID) then return end
    local artID = C_Map.GetMapArtID(mapID)
    if not ID(artID) then return end
    local data = Suite.MapRevealData[artID]
    if not data then return end
    local container = map:GetCanvasContainer()
    if not Writable(container) or not container.GetCurrentLayerIndex then return end
    local index = container:GetCurrentLayerIndex()
    -- This build's overlay tiles all belong to its first art layer. Never reuse them on another layer.
    if not ID(index) or index ~= 1 then return end
    local layers = C_Map.GetMapArtLayers(mapID)
    if not Table(layers) then return end
    local layer = layers[index]
    if not Table(layer) then return end
    for _, key in ipairs({ "layerWidth", "layerHeight", "tileWidth", "tileHeight" }) do
        if not Number(layer[key]) then return end
    end
    if layer.layerWidth ~= data.width or layer.layerHeight ~= data.height
        or layer.tileWidth ~= data.tileWidth or layer.tileHeight ~= data.tileHeight then return end

    local explored = C_MapExplorationInfo.GetExploredMapTextures(mapID)
    if not Suite.IsReadable(explored) then return end
    -- With a valid art ID/layer, a readable nil also occurs before any area has been explored.
    if explored == nil then explored = {} end
    if not Table(explored) or #explored > 512 then return end
    local existing = {}
    for i = 1, #explored do
        local key = ExplorationKey(explored[i])
        if not key then return end -- A partially unreadable result must not be interpreted as unexplored terrain.
        existing[key] = true
    end
    local record = self.pins[pin]
    if not record then return end
    self:Prepare(pin, map, record)
    -- Each underlay uses the same asset alpha as its area, including holes and feathered edges.
    -- No canvas-sized rectangle or native base-tile suppression: sea, coast art and parchment stay native.
    for _, pool in ipairs({ record.textures, record.coverTextures }) do
        if #pool ~= self.capacity then return end
        for _, texture in ipairs(pool) do
            if not Writable(texture) then Suite.AfterCombat("worldMap", function() self:Apply() end); return end
        end
    end
    local opacity = self:Opacity()
    local used = 0
    for _, overlay in ipairs(data.overlays) do
        local width, height, x, y, files = unpack(overlay)
        local key = ExplorationKey({ textureWidth = width, textureHeight = height, offsetX = x, offsetY = y, fileDataIDs = files })
        if not existing[key] then
            local columns = math.ceil(width / data.tileWidth)
            for i, file in ipairs(files) do
                local column, row = (i - 1) % columns, math.floor((i - 1) / columns)
                local pixelWidth = math.min(data.tileWidth, width - column * data.tileWidth)
                local pixelHeight = math.min(data.tileHeight, height - row * data.tileHeight)
                used = used + 1
                for _, layer in ipairs({ { record.coverTextures[used], 0.65 }, { record.textures[used], opacity } }) do
                    local texture, alpha = layer[1], layer[2]
                    if alpha > 0 then
                        texture:ClearAllPoints()
                        texture:SetPoint("TOPLEFT", pin, "TOPLEFT", x + column * data.tileWidth, -(y + row * data.tileHeight))
                        texture:SetSize(pixelWidth, pixelHeight)
                        texture:SetTexCoord(0, pixelWidth / FileSize(pixelWidth, data.tileWidth), 0, pixelHeight / FileSize(pixelHeight, data.tileHeight))
                        texture:SetTexture(file, nil, nil, "TRILINEAR")
                        texture:SetAlpha(alpha)
                        texture:Show()
                    end
                end
            end
        end
    end
end

function Map:Cancel()
    self.token = (self.token or 0) + 1
    if self.timer and self.timer.Cancel then self.timer:Cancel() end
    self.timer = nil
end

function Map:Schedule()
    if not self:Enabled() then return end
    if self.timer then return end
    if not C_Timer or not C_Timer.NewTimer then self:Refresh(); return end
    local token = self.token
    self.timer = C_Timer.NewTimer(0.05, function()
        if self.token ~= token then return end
        self.timer = nil
        if self:Enabled() then self:Refresh() end
    end)
end

function Map:Refresh()
    local map = WorldMapFrame
    if not Widget(map) or not map.EnumeratePinsByTemplate or not map.HookScript then
        for pin in pairs(self.pins) do self:Hide(pin) end
        self.map = nil
        return
    end
    self.map = map
    if not self.watchedMaps[map] then
        if InCombatLockdown() then
            for pin in pairs(self.pins) do self:Hide(pin) end
            Suite.AfterCombat("worldMap", function() self:Apply() end)
            return
        end
        self.watchedMaps[map] = true
        map:HookScript("OnShow", function() self:Schedule() end)
        map:HookScript("OnHide", function()
            if self.map == map then
                self:Cancel()
                for pin in pairs(self.pins) do self:Hide(pin) end
            end
        end)
        if map.AcquirePin then
            hooksecurefunc(map, "AcquirePin", function(_, template)
                if Suite.IsReadable(template) and template == "MapExplorationPinTemplate" then self:Schedule() end
            end)
        end
    end
    local active, count = {}, 0
    for pin in map:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
        count = count + 1
        if count > 16 then break end
        if Widget(pin) and pin.RefreshOverlays then
            active[pin] = true
            if not self.pins[pin] then
                if InCombatLockdown() then Suite.AfterCombat("worldMap", function() self:Apply() end); break end
                self.pins[pin] = { textures = {}, coverTextures = {} }
                hooksecurefunc(pin, "RefreshOverlays", function()
                    if self:Enabled() then self:Render(pin) end
                end)
                if pin.RemoveAllData then
                    hooksecurefunc(pin, "RemoveAllData", function()
                        if self:Enabled() then self:Hide(pin) end
                    end)
                end
            end
            self:Render(pin)
        end
    end
    for pin in pairs(self.pins) do if not active[pin] then self:Hide(pin) end end
end

function Map:Apply()
    self:Cancel()
    Suite.pending.worldMap = nil
    if not self:Enabled() then
        for pin in pairs(self.pins) do self:Hide(pin) end
        if self.events then self.events:UnregisterAllEvents() end
        return
    end
    if InCombatLockdown() then
        self:Refresh()
        Suite.AfterCombat("worldMap", function() self:Apply() end)
        return
    end
    Suite.AfterCombat("worldMap", function()
        if not self:Enabled() then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event)
                if event == "PLAYER_REGEN_DISABLED" then
                    self:Cancel()
                    self:Refresh()
                    Suite.AfterCombat("worldMap", function() self:Apply() end)
                else self:Schedule() end
            end)
        end
        for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED" }) do self.events:RegisterEvent(event) end
        self:Refresh()
    end)
end
