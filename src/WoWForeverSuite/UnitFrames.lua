local _, Suite = ...
local UnitFrames = { records = {} }
Suite.UnitFrames = UnitFrames
table.insert(Suite.modules, UnitFrames)

local NEUTRAL_FILL = "Interface\\Buttons\\WHITE8X8"
local CLASS_BRIGHTNESS = 0.75
local frameNames = { "PlayerFrame", "TargetFrame", "TargetFrameToT", "FocusFrame" }

local function Enabled()
    return Suite.db and Suite.db.classHealthBars
end

local function Usable(object)
    if not Suite.IsReadable(object) or not object then return false end
    if object.IsForbidden then
        local forbidden = object:IsForbidden()
        return Suite.IsReadable(forbidden) and forbidden == false
    end
    return true
end

local function Color(r, g, b, a)
    if not Suite.IsReadable(r) or not Suite.IsReadable(g) or not Suite.IsReadable(b) or not Suite.IsReadable(a) then return end
    if a == nil then a = 1 end
    if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" or type(a) ~= "number" then return end
    for _, value in ipairs({ r, g, b, a }) do
        if value ~= value or value < 0 or value > 1 then return end
    end
    return { r, g, b, a }
end

local function Atlas(value)
    if Suite.IsReadable(value) and type(value) == "string" and value ~= "" then return value end
end

local layers = { BACKGROUND = true, BORDER = true, ARTWORK = true, OVERLAY = true, HIGHLIGHT = true }
local function Layer(layer, sublevel)
    if not Suite.IsReadable(layer) or not Suite.IsReadable(sublevel) or type(layer) ~= "string"
        or not layers[layer] or type(sublevel) ~= "number" or sublevel ~= sublevel
        or sublevel < -8 or sublevel > 7 or sublevel ~= math.floor(sublevel) then return end
    return { layer, sublevel }
end

local function TextureLayer(texture)
    if Usable(texture) and type(texture.GetDrawLayer) == "function" then return Layer(texture:GetDrawLayer()) end
end

local function HealthBar(frame)
    if not Usable(frame) then return end
    if Usable(frame.HealthBar) then return frame.HealthBar end
    local content = frame.PlayerFrameContent
    if not Suite.IsReadable(content) then return end
    if content == nil then content = frame.TargetFrameContent end
    if not Usable(content) then return end
    local main = content.PlayerFrameContentMain
    if not Suite.IsReadable(main) then return end
    if main == nil then main = content.TargetFrameContentMain end
    if not Usable(main) or not Usable(main.HealthBarsContainer) then return end
    return main.HealthBarsContainer.HealthBar
end

local function ClassColor(record)
    local unit = record.bar.unit
    if not Suite.IsReadable(unit) or type(unit) ~= "string" or unit == ""
        or type(UnitIsPlayer) ~= "function" or type(UnitClass) ~= "function"
        or type(UnitIsConnected) ~= "function" then return end
    local player, connected = UnitIsPlayer(unit), UnitIsConnected(unit)
    if not Suite.IsReadable(player) or player ~= true
        or not Suite.IsReadable(connected) or connected ~= true then return end
    local _, class = UnitClass(unit)
    if not Suite.IsReadable(class) or type(class) ~= "string" or not Suite.IsReadable(RAID_CLASS_COLORS)
        or type(RAID_CLASS_COLORS) ~= "table" then return end
    local color = RAID_CLASS_COLORS[class]
    if not Suite.IsReadable(color) or type(color) ~= "table" then return end
    local tint = Color(color.r, color.g, color.b, 1)
    if not tint then return end
    -- Dim validated channels equally to preserve the class hue and keep an opaque fill.
    for channel = 1, 3 do tint[channel] = tint[channel] * CLASS_BRIGHTNESS end
    return tint
end

function UnitFrames:RestoreLoss(record)
    local loss = record.loss
    if not loss or not loss.adjusted or not loss.nativeLayer or not Usable(loss.bar) or not Usable(loss.texture) then return end
    loss.texture:SetDrawLayer(unpack(loss.nativeLayer))
    loss.adjusted = nil
end

function UnitFrames:PaintLoss(record)
    local loss = record.loss
    if not loss or not loss.nativeLayer or not Usable(loss.bar) or not Usable(loss.texture) then return end
    local layer = TextureLayer(record.texture)
    if not layer or layer[2] <= -8 then self:RestoreLoss(record); return end
    -- These native sibling bars share a frame level and BACKGROUND layer. Keep the
    -- red animated loss behind current health without raising prediction/absorb layers.
    loss.texture:SetDrawLayer(layer[1], layer[2] - 1)
    loss.adjusted = true
end

function UnitFrames:TrackLoss(record)
    if InCombatLockdown() or record.loss or record.frame ~= PlayerFrame then return end
    local bar = record.bar.AnimatedLossBar
    if not Usable(bar) or type(bar.GetStatusBarTexture) ~= "function" or type(bar.HookScript) ~= "function" then return end
    local texture = bar:GetStatusBarTexture()
    if not Usable(texture) or type(texture.SetDrawLayer) ~= "function" then return end
    local layer = TextureLayer(texture)
    if not layer then return end
    local loss = { bar = bar, texture = texture, nativeLayer = layer }
    record.loss = loss
    hooksecurefunc(texture, "SetDrawLayer", function(_, drawLayer, sublevel)
        if record.painting or not Enabled() then return end
        loss.nativeLayer, loss.adjusted = Layer(drawLayer, sublevel), nil
        self:RefreshRecord(record)
    end)
    bar:HookScript("OnShow", function()
        if Enabled() and not record.painting then self:RefreshRecord(record) end
    end)
    -- Native animation ticks update this sibling's value independently of current
    -- health. Ignore that value too and settle the existing texture's ordering.
    bar:HookScript("OnValueChanged", function()
        if Enabled() and not record.painting then self:RefreshRecord(record) end
    end)
end

function UnitFrames:Restore(record)
    if not Usable(record.frame) or not Usable(record.bar) or not Usable(record.texture) then return end
    record.painting = true
    self:RestoreLoss(record)
    if record.fillReplaced and record.nativeAtlas then
        -- Never apply atlas dimensions: native layout and masks still own the existing texture.
        record.texture:SetAtlas(record.nativeAtlas, false)
    end
    if record.tinted and record.nativeColor then record.bar:SetStatusBarColor(unpack(record.nativeColor)) end
    record.painting = nil
    record.fillReplaced, record.tinted = nil, nil
end

function UnitFrames:RefreshRecord(record)
    if not Enabled() or not Usable(record.frame) or not Usable(record.bar) or not Usable(record.texture) then return end
    local color = ClassColor(record)
    if not color or not record.nativeAtlas or not record.nativeColor then self:Restore(record); return end
    record.painting = true
    if not record.fillReplaced then
        -- Tinting Blizzard's colored health atlas multiplies its green into the class color.
        -- Replace the pixels on the same masked texture; do not add a second bar/overlay.
        record.texture:SetTexture(NEUTRAL_FILL)
        record.texture:SetTexCoord(0, 1, 0, 1)
        record.fillReplaced = true
    end
    record.bar:SetStatusBarColor(unpack(color))
    self:PaintLoss(record)
    record.tinted = true
    record.painting = nil
end

function UnitFrames:Track(frame)
    if InCombatLockdown() then return end
    local bar = HealthBar(frame)
    if not Usable(bar) then return end
    if self.records[bar] then self:TrackLoss(self.records[bar]); return end
    if type(bar.GetStatusBarTexture) ~= "function"
        or type(bar.GetStatusBarColor) ~= "function" or type(bar.SetStatusBarColor) ~= "function" then return end
    local texture = bar:GetStatusBarTexture()
    if not Usable(texture) or type(texture.GetAtlas) ~= "function" or type(texture.SetAtlas) ~= "function"
        or type(texture.SetTexture) ~= "function" or type(texture.SetTexCoord) ~= "function" then return end
    local atlas, color = Atlas(texture:GetAtlas()), Color(bar:GetStatusBarColor())
    if not atlas or not color then return end
    local record = { frame = frame, bar = bar, texture = texture, nativeAtlas = atlas, nativeColor = color }
    self.records[bar] = record
    self:TrackLoss(record)
    hooksecurefunc(bar, "SetStatusBarColor", function(_, r, g, b, a)
        if record.painting or not Enabled() then return end
        record.nativeColor = Color(r, g, b, a)
        record.tinted = nil -- The native setter just replaced our color.
        self:RefreshRecord(record)
    end)
    hooksecurefunc(texture, "SetAtlas", function(_, value)
        if record.painting or not Enabled() then return end
        record.nativeAtlas, record.fillReplaced = Atlas(value), nil
        self:RefreshRecord(record)
    end)
    hooksecurefunc(texture, "SetTexture", function()
        if record.painting or not Enabled() then return end
        -- A replacement texture owns its new pixels; do not restore a stale native atlas over it.
        record.nativeAtlas, record.fillReplaced = nil, nil
        self:Restore(record)
    end)
    frame:HookScript("OnShow", function() if Enabled() then self:RefreshRecord(record) end end)
    -- Ignore the supplied value entirely: native text/animation callbacks retain it.
    -- Repaint after their work, using only readable unit/class identity and cosmetic state.
    bar:HookScript("OnValueChanged", function()
        if Enabled() and not record.painting then self:RefreshRecord(record) end
    end)
end

function UnitFrames:Refresh()
    if not Enabled() then return end
    if InCombatLockdown() then
        Suite.AfterCombat("unitFrames", function() self:Refresh() end)
    else
        if not self.unitHook and type(UnitFrameHealthBar_SetUnit) == "function" then
            self.unitHook = true
            hooksecurefunc("UnitFrameHealthBar_SetUnit", function(bar)
                if not Enabled() or not Suite.IsReadable(bar) then return end
                local record = self.records[bar]
                if record then self:RefreshRecord(record) end
            end)
        end
        for _, name in ipairs(frameNames) do self:Track(_G[name]) end
    end
    for _, record in pairs(self.records) do self:RefreshRecord(record) end
end

function UnitFrames:CancelRefresh()
    if self.refreshTimer then self.refreshTimer:Cancel(); self.refreshTimer = nil end
end

function UnitFrames:QueueRefresh()
    if not Enabled() then return end
    if InCombatLockdown() then self:Refresh(); return end
    if self.refreshTimer then return end
    self.refreshTimer = C_Timer.NewTimer(0.05, function()
        self.refreshTimer = nil
        self:Refresh()
    end)
end

function UnitFrames:Apply()
    self:CancelRefresh()
    Suite.pending.unitFrames = nil
    if self.events then self.events:UnregisterAllEvents() end
    if not Enabled() then
        for _, record in pairs(self.records) do self:Restore(record) end
        return
    end
    Suite.AfterCombat("unitFrames", function()
        if not Enabled() then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event)
                if event == "PLAYER_REGEN_DISABLED" then self:CancelRefresh(); self:Refresh()
                else self:QueueRefresh() end
            end)
        end
        for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED",
            "UNIT_TARGET", "UNIT_NAME_UPDATE", "UNIT_CONNECTION", "UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE", "PLAYER_REGEN_DISABLED" }) do
            self.events:RegisterEvent(event)
        end
        -- Re-enable captures the current native state, including changes made while disabled.
        for _, record in pairs(self.records) do
            if not record.fillReplaced and not record.tinted and Usable(record.bar) and Usable(record.texture) then
                record.nativeAtlas = Atlas(record.texture:GetAtlas())
                record.nativeColor = Color(record.bar:GetStatusBarColor())
            end
            local loss = record.loss
            if loss and not loss.adjusted then loss.nativeLayer = TextureLayer(loss.texture) end
        end
        self:Refresh()
    end)
end
