local _, Suite = ...
local Theme = { borders = setmetatable({}, { __mode = "k" }) }
Suite.Theme = Theme
Suite.modules[#Suite.modules + 1] = Theme

local teal = { r = 0.41, g = 0.84, b = 0.75 }

-- Route wheel input on Suite-owned frames, retaining nested controls' own
-- scrolling/resizing behavior. Leave click and keyboard input unchanged.
function Theme:RouteWheel(frame, inherited)
    if InCombatLockdown() or not frame or not frame.GetScript then return end
    local handler = frame:GetScript("OnMouseWheel") or inherited
    if handler and frame.EnableMouseWheel then
        frame:EnableMouseWheel(true)
        if not frame:GetScript("OnMouseWheel") then frame:SetScript("OnMouseWheel", handler) end
    end
    if frame.GetChildren then
        local forward = handler and function(_, ...) handler(frame, ...) end or nil
        for _, child in ipairs({ frame:GetChildren() }) do self:RouteWheel(child, forward) end
    end
end

function Theme:PageWheel(parent, rows, previous, following, bottom)
    if InCombatLockdown() or not rows[1] then return end
    local function Wheel(_, delta)
        if InCombatLockdown() or not Suite.IsReadable(delta) or type(delta) ~= "number"
            or delta ~= delta or delta == 0 or math.abs(delta) == math.huge then return end
        local button = delta > 0 and previous or following
        if not button:IsShown() or not button:IsEnabled() then return end
        local click = button:GetScript("OnClick")
        if click then click(button, "LeftButton") end
    end
    local area = CreateFrame("Frame", nil, parent)
    area:SetFrameLevel(parent:GetFrameLevel())
    area:SetPoint("TOPLEFT", rows[1], "TOPLEFT")
    area:SetPoint("TOPRIGHT", rows[1], "TOPRIGHT")
    area:SetPoint("BOTTOMLEFT", bottom or rows[#rows], "BOTTOMLEFT")
    area:EnableMouse(false); area:SetScript("OnMouseWheel", Wheel)
    self:RouteWheel(area, Wheel)
    for _, row in ipairs(rows) do self:RouteWheel(row, Wheel) end
    self:RouteWheel(previous, Wheel); self:RouteWheel(following, Wheel)
    return area
end
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

-- Native button states handle hover, press, release and disabling without Lua
-- mouse handlers. Keep existing selection colors, labels and tooltip scripts.
function Theme:ButtonFeedback(button)
    if button.suiteButtonFeedback then return end
    button.suiteButtonFeedback = true
    local hover = button:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints(); self:Texture(hover, 0.13)
    button:SetHighlightTexture(hover, "BLEND")
    local pressed = button:CreateTexture(nil, "ARTWORK")
    pressed:SetAllPoints(); self:Texture(pressed, 0.24)
    button:SetPushedTexture(pressed, "BLEND")
end

-- Suite-owned dismiss/remove controls: a font-independent cross with a quiet,
-- borderless hit target. Callers retain their own placement and action guards.
function Theme:IconButton(parent, caption, callback, destructive)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(24, 24)
    button:EnableMouse(true); button:RegisterForClicks("LeftButtonUp")
    local wash = button:CreateTexture(nil, "BACKGROUND")
    wash:SetAllPoints(); wash:SetColorTexture(0.41, 0.84, 0.75, 0)
    local strokes = {}
    for index = 1, 2 do
        local stroke = button:CreateLine(nil, "ARTWORK")
        local y = index == 1 and 4 or -4
        stroke:SetThickness(1.5)
        stroke:SetStartPoint("CENTER", button, -4, y)
        stroke:SetEndPoint("CENTER", button, 4, -y)
        strokes[index] = stroke
    end
    local hovered, pressed = false, false
    local function Enabled()
        return not button.IsEnabled or button:IsEnabled()
    end
    local function Paint()
        local active = hovered and Enabled()
        local r, g, b = 0.55, 0.65, 0.7
        if active then
            if destructive then r, g, b = 1, 0.48, 0.44
            else r, g, b = self:RGB() end
        end
        wash:SetColorTexture(r, g, b, active and (pressed and 0.25 or 0.13) or 0)
        for _, stroke in ipairs(strokes) do
            stroke:SetColorTexture(r, g, b, Enabled() and 1 or 0.35)
        end
    end
    local function HideTooltip()
        if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(button) then GameTooltip:Hide() end
    end
    button:SetScript("OnEnter", function()
        hovered = true; Paint()
        if Enabled() and GameTooltip and GameTooltip.SetOwner and GameTooltip.SetText then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT"); GameTooltip:SetText(caption); GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function() hovered, pressed = false, false; Paint(); HideTooltip() end)
    button:SetScript("OnMouseDown", function(_, mouse) if mouse == "LeftButton" then pressed = true; Paint() end end)
    button:SetScript("OnMouseUp", function() pressed = false; Paint() end)
    button:SetScript("OnHide", function() hovered, pressed = false, false; Paint(); HideTooltip() end)
    button:SetScript("OnDisable", function() hovered, pressed = false, false; Paint(); HideTooltip() end)
    button:SetScript("OnEnable", Paint)
    button:SetScript("OnClick", callback)
    button.RefreshIcon = Paint
    Paint()
    return button
end

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
