local _, Suite = ...
local Theme = { borders = setmetatable({}, { __mode = "k" }) }
Suite.Theme = Theme
Suite.modules[#Suite.modules + 1] = Theme

local teal = { r = 0.41, g = 0.84, b = 0.75 }
local function Channel(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and value >= 0 and value <= 1
end
local function Color(value)
    return Suite.IsReadable(value) and type(value) == "table" and Channel(value.r) and Channel(value.g) and Channel(value.b)
end
local function Mode(value)
    return Suite.IsReadable(value) and type(value) == "string" and (value == "default" or value == "class" or value == "custom")
end

function Theme:Initialize(db)
    if not Mode(db.borderColorMode) then db.borderColorMode = "default" end
    local color = Color(db.customBorderColor) and db.customBorderColor or teal
    -- Store only ordinary RGB channels; discard unrelated or malformed saved fields.
    db.customBorderColor = { r = color.r, g = color.g, b = color.b }
end

function Theme:RGB(mode)
    local db = Suite.db or Suite.defaults
    if not Mode(mode) then mode = Mode(db.borderColorMode) and db.borderColorMode or "default" end
    local color
    if mode == "custom" then
        color = db.customBorderColor
    elseif mode == "class" and type(UnitClass) == "function" then
        local ok, _, token = pcall(UnitClass, "player")
        if ok and Suite.IsReadable(token) and type(token) == "string" then
            if Suite.IsReadable(C_ClassColor) and type(C_ClassColor) == "table" and type(C_ClassColor.GetClassColor) == "function" then
                local success, result = pcall(C_ClassColor.GetClassColor, token)
                if success and Color(result) then color = result end
            end
            if not color and Suite.IsReadable(RAID_CLASS_COLORS) and type(RAID_CLASS_COLORS) == "table" then
                color = RAID_CLASS_COLORS[token]
            end
        end
    end
    if not Color(color) then color = teal end
    return color.r, color.g, color.b
end

local function Writable(object)
    if not Suite.IsReadable(object) or not object or (type(object) ~= "table" and type(object) ~= "userdata") then return false end
    if type(object.IsForbidden) == "function" then
        local ok, forbidden = pcall(object.IsForbidden, object)
        if not ok or not Suite.IsReadable(forbidden) or forbidden ~= false then return false end
    end
    return true
end

function Theme:Paint(object, style, feedback)
    if not Writable(object) or type(object[style.method]) ~= "function" then return end
    local r, g, b
    if InCombatLockdown() then
        -- Existing flat textures already support cosmetic hover feedback in combat.
        -- Retain their last applied RGB until the queued theme change is safe.
        if not feedback or style.r == nil then return end
        r, g, b = style.r, style.g, style.b
    elseif Color(style.color) then
        r, g, b = style.color.r, style.color.g, style.color.b
    else r, g, b = self:RGB() end
    object[style.method](object, r, g, b, style.alpha)
    style.r, style.g, style.b = r, g, b
end

function Theme:Register(object, method, alpha, color)
    if not Writable(object) or type(object[method]) ~= "function" then return end
    local style = self.borders[object]
    if not style then style = {}; self.borders[object] = style end
    style.method, style.alpha = method, Channel(alpha) and alpha or 1
    -- Semantic borders can retain a validated display color through shared theme refreshes.
    style.color = Color(color) and { r = color.r, g = color.g, b = color.b } or nil
    if InCombatLockdown() then
        if method == "SetColorTexture" then self:Paint(object, style, true) end
        Suite.AfterCombat("borderTheme", function() self:Refresh() end)
    else self:Paint(object, style) end
end

function Theme:Backdrop(object, alpha, color) self:Register(object, "SetBackdropBorderColor", alpha, color) end
function Theme:Texture(object, alpha) self:Register(object, "SetColorTexture", alpha) end
function Theme:Vertex(object, alpha) self:Register(object, "SetVertexColor", alpha) end

function Theme:Refresh()
    Suite.AfterCombat("borderTheme", function()
        for object, style in pairs(self.borders) do self:Paint(object, style) end
    end)
    if Suite.GUI and Suite.GUI.RefreshAppearance then Suite.GUI:RefreshAppearance() end
end

function Theme:Apply()
    local r, g, b = self:RGB()
    if self.r ~= r or self.g ~= g or self.b ~= b then
        self.r, self.g, self.b = r, g, b
        self:Refresh()
    end
end

function Theme:SetMode(mode)
    if not Suite.db or not Mode(mode) then return end
    Suite.db.borderColorMode = mode
    self:Apply()
    if Suite.GUI then Suite.GUI:RefreshAppearance() end
end

function Theme:SetCustom(r, g, b)
    if not Suite.db or not Channel(r) or not Channel(g) or not Channel(b) then return end
    Suite.db.customBorderColor = { r = r, g = g, b = b }
    self:SetMode("custom")
end

function Theme:OpenPicker()
    if not Suite.db then return end
    if InCombatLockdown() then Suite.Print("Choose a custom border color outside combat."); return end
    local picker = ColorPickerFrame
    if not Writable(picker) or type(picker.SetupColorPickerAndShow) ~= "function" or type(picker.GetColorRGB) ~= "function" then
        Suite.Print("The color picker is unavailable on this client."); return
    end
    if type(picker.IsShown) == "function" then
        local ok, shown = pcall(picker.IsShown, picker)
        if not ok or not Suite.IsReadable(shown) or shown ~= false then
            Suite.Print("Finish the open color selection first."); return
        end
    end
    local previousMode, previousColor = Suite.db.borderColorMode, Suite.Copy(Suite.db.customBorderColor)
    local r, g, b = self:RGB()
    local swatch, cancel
    swatch = function()
        if picker.swatchFunc ~= swatch or picker.cancelFunc ~= cancel then return end
        local ok, red, green, blue = pcall(picker.GetColorRGB, picker)
        if ok then self:SetCustom(red, green, blue) end
    end
    cancel = function()
        if picker.swatchFunc ~= swatch or picker.cancelFunc ~= cancel then return end
        Suite.db.customBorderColor = previousColor
        self:SetMode(previousMode)
    end
    picker:SetupColorPickerAndShow({ r = r, g = g, b = b, hasOpacity = false,
        swatchFunc = swatch, cancelFunc = cancel })
end
