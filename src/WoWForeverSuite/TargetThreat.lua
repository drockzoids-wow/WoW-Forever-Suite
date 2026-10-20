local _, Suite = ...
local Threat = {}
Suite.TargetThreat = Threat
table.insert(Suite.modules, Threat)

local function Enabled()
    return Suite.db and Suite.IsReadable(Suite.db.targetThreat) and Suite.db.targetThreat == true
end

local function Read(fn, ...)
    if type(fn) ~= "function" then return end
    local success, value = pcall(fn, ...)
    if success and Suite.IsReadable(value) then return value end
end

local function Accessible(object)
    return Suite.IsReadable(object) and (type(object) == "table" or type(object) == "userdata")
        and Read(object.IsForbidden, object) == false
end

local function Number(value, minimum, maximum)
    return Suite.IsReadable(value) and type(value) == "number" and value >= minimum and value <= maximum
end

local function Main(owner)
    if not Accessible(owner) then return end
    local content = owner.TargetFrameContent
    if not Accessible(content) then return end
    local main = content.TargetFrameContentMain
    if Accessible(main) then return main end
end

function Threat:VisualAllowed()
    return Accessible(self.square) and (not InCombatLockdown() or Read(self.square.IsProtected, self.square) == false)
end

function Threat:Hide()
    if not Accessible(self.square) then return end
    if self:VisualAllowed() then self.square:Hide()
    else Suite.AfterCombat("targetThreatHide", function() if not Enabled() then self:Hide() else self:Update() end end) end
end

function Threat:Percentage()
    -- Check this function's predicate for the exact player/target pair. Do not query hidden values elsewhere.
    if not C_Secrets or Read(C_Secrets.ShouldUnitThreatValuesBeSecret, "player", "target") ~= false
        or type(UnitDetailedThreatSituation) ~= "function" then return end
    local success, _, _, percentage = pcall(UnitDetailedThreatSituation, "player", "target")
    if success and Number(percentage, 0, 100) then return percentage end
end

function Threat:Update()
    if not self.active or not Enabled() or not self.positioned or not Accessible(self.owner)
        or Read(self.owner.IsVisible, self.owner) ~= true or Read(UnitExists, "target") ~= true
        or Read(UnitCanAttack, "player", "target") ~= true or Read(UnitIsPlayer, "target") ~= false
        or Read(UnitIsDeadOrGhost, "target") ~= false then self:Hide(); return end
    local top = self.owner.buffsOnTop
    if not Suite.IsReadable(top) or (top ~= nil and type(top) ~= "boolean") or (top == true) ~= self.below then
        self:Hide(); return
    end
    if not self:VisualAllowed() then return end
    local percentage = self:Percentage()
    local r, g, b, alpha = 0.32, 0.34, 0.37, 0.20
    if percentage == nil then self.square.text:SetText("--")
    else
        -- Arithmetic/formatting use only validated ordinary values, never secret threat results.
        local progress = math.min(percentage, 100) / 100
        alpha = 0.40 + 0.40 * progress
        if progress <= 0.7 then
            local blend = progress / 0.7
            r, g, b = 0.32 + 0.60 * blend, 0.34 + 0.20 * blend, 0.37 - 0.27 * blend
        else
            local blend = (progress - 0.7) / 0.3
            r, g, b = 0.92, 0.54 - 0.43 * blend, 0.10
        end
        self.square.text:SetText(string.format("%.0f%%", percentage))
    end
    self.square.fill:SetColorTexture(r, g, b, alpha)
    self.square:Show()
end

function Threat:Cancel()
    self.work = nil
    if self.timer then self.timer:Cancel(); self.timer = nil end
end

function Threat:Queue(layout)
    if not self.active or not Enabled() then return end
    if layout then self.layoutWanted = true end
    if self.work or not C_Timer or type(C_Timer.NewTimer) ~= "function" then return end
    local work = {}; self.work = work
    self.timer = C_Timer.NewTimer(0.05, function()
        if self.work ~= work then return end
        self.work, self.timer = nil, nil
        if not self.active or not Enabled() then return end
        if self.layoutWanted then self:Prepare() else self:Update() end
    end)
end

function Threat:CreateSquare()
    if self.square then return true end
    local borders = NineSliceUtil
    if not borders or type(borders.GetLayout) ~= "function" or type(borders.ApplyLayoutByName) ~= "function"
        or type(Read(borders.GetLayout, "TooltipDefaultLayout")) ~= "table" then return false end
    -- UIParent ownership keeps the passive indicator out of the secure target button's child hierarchy.
    local square = CreateFrame("Frame", nil, UIParent)
    square:Hide(); square:SetSize(60, 24); square:EnableMouse(false)
    square:SetFrameStrata("LOW")
    borders.ApplyLayoutByName(square, "TooltipDefaultLayout")
    -- Keep Blizzard's border art, but replace its solid center with chat translucency.
    if square.Center then square.Center:Hide() end
    for _, name in ipairs({ "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
        "TopEdge", "BottomEdge", "LeftEdge", "RightEdge" }) do
        local piece = square[name]
        if piece then
            -- Fit native pieces to this compact height without overlapping corners.
            if name:find("Corner", 1, true) then piece:SetSize(10, 10)
            elseif name == "TopEdge" or name == "BottomEdge" then piece:SetHeight(10)
            else piece:SetWidth(10) end
            Suite.Theme:Vertex(piece, 0.95)
        end
    end
    square.background = square:CreateTexture(nil, "BACKGROUND", nil, 0)
    square.background:SetPoint("TOPLEFT", square, "TOPLEFT", 3, -3)
    square.background:SetPoint("BOTTOMRIGHT", square, "BOTTOMRIGHT", -3, 3)
    square.background:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    square.background:SetVertexColor(0, 0, 0, 0.32)
    square.fill = square:CreateTexture(nil, "BACKGROUND", nil, 1)
    square.fill:SetPoint("TOPLEFT", square, "TOPLEFT", 3, -3)
    square.fill:SetPoint("BOTTOMRIGHT", square, "BOTTOMRIGHT", -3, 3)
    square.fill:SetColorTexture(0.32, 0.34, 0.37, 0.20)
    square.link = square:CreateTexture(nil, "BORDER")
    square.link:SetAtlas("_Tooltip-NineSlice-EdgeTop")
    square.link:SetSize(7, 2)
    Suite.Theme:Vertex(square.link, 0.95)
    square.text = square:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    square.text:SetPoint("CENTER", square, "CENTER", 0, 0)
    square.text:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    square.text:SetTextColor(1, 1, 1, 1)
    square.text:SetText("--")
    self.square = square
    return true
end

function Threat:Layout(main)
    if InCombatLockdown() then return end
    local owner, square = self.owner, self.square
    local top = owner.buffsOnTop
    if not Suite.IsReadable(top) or (top ~= nil and type(top) ~= "boolean") then self.positioned = nil; return end
    top = top == true
    local anchor
    if top then anchor = main.ManaBar else anchor = main.ReputationColor end
    if not Accessible(anchor) then self.positioned = nil; return end
    local nativeScale, parentScale = Read(owner.GetEffectiveScale, owner), Read(UIParent.GetEffectiveScale, UIParent)
    if not Number(nativeScale, 0.01, 100) or not Number(parentScale, 0.01, 100) then self.positioned = nil; return end
    local scale = nativeScale / parentScale
    if self.positioned and self.anchor == anchor and self.below == top and self.scale == scale then return end
    local level = Read(owner.GetFrameLevel, owner)
    if Number(level, 0, 10000) then square:SetFrameLevel(math.floor(level) + 4) end
    square:SetScale(scale); square:ClearAllPoints()
    square.link:ClearAllPoints()
    if top then
        -- Offset outside the left edge to leave the native cast bar and target-of-target clear.
        square:SetPoint("TOPRIGHT", anchor, "BOTTOMLEFT", -6, -1)
        square.link:SetPoint("TOPLEFT", square, "TOPRIGHT", 0, 1)
    else
        -- The name-strip texture extends left of the visible frame trim.
        square:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 3, 1)
        square.link:SetPoint("TOPLEFT", square, "BOTTOMLEFT", 0, 0)
    end
    self.positioned, self.anchor, self.below, self.scale = true, anchor, top, scale
end

function Threat:Prepare()
    if not self.active or not Enabled() then return end
    if InCombatLockdown() then
        Suite.AfterCombat("targetThreatLayout", function() self:Prepare() end)
        self:Update(); return
    end
    Suite.pending.targetThreatLayout = nil
    self.layoutWanted = nil
    local owner = TargetFrame
    local main = Main(owner)
    if not main or type(owner.HookScript) ~= "function" or type(hooksecurefunc) ~= "function" then
        self.positioned = nil; self:Hide(); return
    end
    if not self:CreateSquare() then self.positioned = nil; self:Hide(); return end
    if owner ~= self.owner then
        self.owner, self.positioned = owner, nil
        owner:HookScript("OnShow", function() if self.active then self:Queue(true) end end)
        owner:HookScript("OnHide", function() if self.active then self:Hide() end end)
        owner:HookScript("OnSizeChanged", function() self:Queue(true) end)
        for _, method in ipairs({ "ConfigureAuraContainer", "UpdateSystemSettingBuffsOnTop", "SetScale" }) do
            if type(owner[method]) == "function" then hooksecurefunc(owner, method, function() self:Queue(true) end) end
        end
    end
    if self.events and type(self.events.UnregisterEvent) == "function" then self.events:UnregisterEvent("ADDON_LOADED") end
    self:Layout(main)
    self:Update()
end

function Threat:OnEvent(event, unit)
    if not self.active or not Enabled() then return end
    if event == "PLAYER_LOGOUT" then
        self.active = nil; self:Cancel()
        Suite.pending.targetThreat, Suite.pending.targetThreatLayout = nil, nil
        if self.events then self.events:UnregisterAllEvents() end
        self:Hide(); return
    end
    if event == "ADDON_LOADED" then if not self.owner then self:Queue(true) end; return end
    if event == "PLAYER_REGEN_ENABLED" then self:Cancel(); self:Prepare(); return end
    if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_REGEN_DISABLED" then
        self:Cancel(); self:Update()
        if not self.positioned then self:Queue(true) end
        return
    end
    if event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_THREAT_SITUATION_UPDATE"
        or event == "UNIT_FACTION" or event == "UNIT_FLAGS" or event == "UNIT_HEALTH" then
        if not Suite.IsReadable(unit) or type(unit) ~= "string" then return end
        local threatEvent = event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_THREAT_SITUATION_UPDATE"
        if unit ~= "target" and (not threatEvent or unit ~= "player") then return end
    end
    self:Queue(event == "PLAYER_ENTERING_WORLD")
end

function Threat:Apply()
    if not Enabled() then
        Suite.pending.targetThreat, Suite.pending.targetThreatLayout = nil, nil
        self.active, self.layoutWanted = nil, nil
        self:Cancel()
        if self.events then self.events:UnregisterAllEvents() end
        self:Hide(); return
    end
    if self.active then return end
    Suite.AfterCombat("targetThreat", function()
        if not Enabled() then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event, ...) self:OnEvent(event, ...) end)
        end
        self.active = true
        for _, event in ipairs({ "PLAYER_TARGET_CHANGED", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
            "UNIT_THREAT_LIST_UPDATE", "UNIT_THREAT_SITUATION_UPDATE", "UNIT_FACTION", "UNIT_FLAGS", "UNIT_HEALTH", "ADDON_LOADED", "PLAYER_LOGOUT" }) do
            self.events:RegisterEvent(event)
        end
        self:Prepare()
    end)
end
