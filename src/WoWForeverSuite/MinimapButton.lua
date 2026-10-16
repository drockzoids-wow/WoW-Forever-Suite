local addonName, Suite = ...
local Launcher = {}
Suite.MinimapButton = Launcher
table.insert(Suite.modules, Launcher)
local BUTTON_SIZE = 26
local ICON_TEXTURE = "Interface\\AddOns\\" .. addonName .. "\\Media\\ForeverSuiteIcon.tga"

local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function EdgeRadii()
    local width, height = Minimap:GetWidth(), Minimap:GetHeight()
    if not Number(width) or not Number(height) or width <= 0 or height <= 0 then return end
    local shape = GetMinimapShape and GetMinimapShape()
    local square = Suite.db.squareMinimap or (Suite.IsReadable(shape) and shape == "SQUARE")
    -- Put the button's inner edge against the square map's one-unit outer border.
    local padding = square and BUTTON_SIZE / 2 + 1 or 1
    local x, y = width / 2 + padding, height / 2 + padding
    if x <= 0 or y <= 0 then return end
    return x, y, square
end

function Launcher:PlaceButton(button, angle, bottomLeft)
    if not button or not Minimap or InCombatLockdown() then return end
    local radiusX, radiusY, square = EdgeRadii()
    if not radiusX then return end
    local strata, level = Minimap:GetFrameStrata(), Minimap:GetFrameLevel()
    if not Suite.IsReadable(strata) or type(strata) ~= "string" or not Number(level) then return end
    if not Number(angle) then angle = 225 end
    angle = angle % 360
    local radians = angle * math.pi / 180
    local x, y = math.cos(radians), math.sin(radians)
    if square then
        -- Project the ray onto the rectangle, including all four corners.
        local edge = math.max(math.abs(x), math.abs(y))
        x, y = x / edge, y / edge
    else
        -- Keep the whole square button outside the tangent of the round/elliptical map.
        local distance = 1 + BUTTON_SIZE / 2 * (math.abs(x) / radiusX + math.abs(y) / radiusY)
        x, y = x * distance, y * distance
    end
    button:ClearAllPoints()
    if square and bottomLeft then button:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMLEFT", -1, 0)
    else button:SetPoint("CENTER", Minimap, "CENTER", x * radiusX, y * radiusY) end
    button:SetFrameStrata(strata)
    button:SetFrameLevel(level + 20)
end

function Launcher:OnMinimap()
    if not self.button then return false end
    local parent = self.button:GetParent()
    return Suite.IsReadable(parent) and parent == Minimap
end

function Launcher:Position()
    -- Collectors own the button's layout until they return it to its original parent.
    if Suite.db.minimapButton and self:OnMinimap() then self:PlaceButton(self.button, Suite.db.minimapButtonAngle) end
end

function Launcher:CursorAngle()
    if not Minimap or InCombatLockdown() then return end
    local x, y = GetCursorPosition()
    local cx, cy = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    if not Number(x) or not Number(y) or not Number(cx) or not Number(cy) or not Number(scale) or scale <= 0 then return end
    x, y = x / scale - cx, y / scale - cy
    local radiusX, radiusY = EdgeRadii()
    if not radiusX then return end
    x, y = x / radiusX, y / radiusY
    if x == 0 and y == 0 then return end
    local angle
    if x == 0 then angle = y > 0 and math.pi / 2 or -math.pi / 2
    else
        angle = math.atan(y / x)
        if x < 0 then angle = angle + math.pi end
    end
    return (angle * 180 / math.pi) % 360
end

function Launcher:Drag()
    if InCombatLockdown() or not Suite.db.minimapButton or not self:OnMinimap() then self:StopDrag(); return end
    local angle = self:CursorAngle()
    if not angle then return end
    Suite.db.minimapButtonAngle = angle
    self:Position()
end

function Launcher:HideTooltip()
    if self.button and GameTooltip and GameTooltip:IsOwned(self.button) then GameTooltip:Hide() end
end

function Launcher:StopDrag()
    self.dragging = false
    if self.button then self.button:SetScript("OnUpdate", nil) end
end

function Launcher:Initialize()
    if self.button or not Minimap then return end
    local button = CreateFrame("Button", nil, Minimap)
    self.button = button
    button.ignoreInLayout = true
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    -- Native AssignedSpec uses an 18-unit circular icon and a 38-unit padded ring on a 22-unit frame.
    local ringScale = BUTTON_SIZE / 22
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(18 * ringScale, 18 * ringScale)
    button.icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.icon:SetTexture(ICON_TEXTURE)
    button.iconMask = button:CreateMaskTexture(nil, "ARTWORK")
    button.iconMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    button.iconMask:SetPoint("TOPLEFT", button.icon, "TOPLEFT", 0, 0)
    button.iconMask:SetPoint("BOTTOMRIGHT", button.icon, "BOTTOMRIGHT", 0, 0)
    button.icon:AddMaskTexture(button.iconMask)
    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetSize(38 * ringScale, 38 * ringScale)
    button.border:SetPoint("TOPLEFT", button, "TOPLEFT", -ringScale, 0)
    button.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button:SetScript("OnMouseDown", function() self.suppressClick = false end)
    button:SetScript("OnClick", function()
        if self.suppressClick then self.suppressClick = false; return end
        if Suite.db.minimapButton then Suite.GUI:Toggle() end
    end)
    button:SetScript("OnDragStart", function()
        self.suppressClick = true
        self:HideTooltip()
        if InCombatLockdown() or not Suite.db.minimapButton or not self:OnMinimap() then return end
        self.dragging = true
        self:Drag()
        if self.dragging then button:SetScript("OnUpdate", function() self:Drag() end) end
    end)
    button:SetScript("OnDragStop", function() self:StopDrag() end)
    button:SetScript("OnHide", function() self:StopDrag(); self:HideTooltip() end)
    button:SetScript("OnEnter", function()
        if not GameTooltip or self.dragging or not Suite.db.minimapButton then return end
        GameTooltip:SetOwner(button, "ANCHOR_LEFT")
        GameTooltip:AddLine("Forever Suite", 0.41, 0.84, 0.75)
        GameTooltip:AddLine(self:OnMinimap() and "Click to open settings. Drag to reposition." or "Click to open settings.", 0.85, 0.9, 0.92)
        GameTooltip:AddLine("Hide this button in Minimap settings.", 0.55, 0.65, 0.7)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() self:HideTooltip() end)
    Minimap:HookScript("OnSizeChanged", function() self:Apply() end)
    self.events = CreateFrame("Frame")
    self.events:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then self:StopDrag(); self:HideTooltip(); return end
        self:Apply()
    end)
    button:Hide()
    if Suite.MinimapDrawer then Suite.MinimapDrawer:Schedule() end
end

function Launcher:Apply()
    if not Suite.db.minimapButton then
        self:StopDrag()
        self:HideTooltip()
    end
    Suite.AfterCombat("minimapButton", function()
        if Suite.db.minimapButton and not self.button then self:Initialize() end
        if not self.button then return end
        self.events:UnregisterAllEvents()
        if Suite.db.minimapButton then
            self.events:RegisterEvent("CVAR_UPDATE")
            self.events:RegisterEvent("ADDON_LOADED")
            self.events:RegisterEvent("PLAYER_REGEN_DISABLED")
            self:Position()
        end
        self.button:SetShown(Suite.db.minimapButton)
    end)
end
