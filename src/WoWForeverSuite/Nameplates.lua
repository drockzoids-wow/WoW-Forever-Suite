local _, Suite = ...
local Nameplates = { active = {}, views = setmetatable({}, { __mode = "k" }) }
Suite.Nameplates = Nameplates
Suite.modules[#Suite.modules + 1] = Nameplates

Nameplates.debuffChoices = {
    {value="all",label="All"}, {value="mine",label="Mine only"},
    {value="larger",label="Mine larger"}, {value="hide",label="Hide"},
}
Nameplates.castChoices = {
    {value=8,label="8 px"}, {value=12,label="12 px"}, {value=16,label="16 px"}, {value=20,label="20 px"},
}
local auraLimit = 6
local regularFilter = "HARMFUL|INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL"
local ownFilter = regularFilter .. "|PLAYER"
local manaHeight = 10

local function SafeCall(func, ...)
    if type(func) ~= "function" then return end
    local ok, value = pcall(func, ...)
    if ok then return value end
end

local function Usable(widget)
    if not Suite.IsReadable(widget) or not widget then return false end
    local forbidden=SafeCall(widget.IsForbidden,widget)
    return Suite.IsReadable(forbidden) and forbidden == false
end

local function CanMeasure(widget)
    if not Usable(widget) then return false end
    local restricted=SafeCall(widget.IsAnchoringRestricted,widget)
    return Suite.IsReadable(restricted) and restricted == false
end

local function UnitToken(unit)
    return Suite.IsReadable(unit) and type(unit) == "string" and unit:match("^nameplate%d+$")
end

local function IsNumber(value)
    return Suite.IsReadable(value) and type(value) == "number"
end

function Nameplates:Option(key)
    local choices = key == "nameplateDebuffs" and self.debuffChoices or self.castChoices
    local current = Suite.db[key]
    if Suite.IsReadable(current) then
        for _, choice in ipairs(choices) do if choice.value == current then return choice end end
    end
    return key == "nameplateDebuffs" and choices[1] or choices[2]
end

local function Label(parent, side, x, width)
    local text = parent:CreateFontString(nil,"OVERLAY","SystemFont_NamePlate_Outlined")
    text:SetFont("Fonts\\FRIZQT__.TTF",9,"OUTLINE")
    text:SetPoint(side,parent,side,x,0)
    text:SetWidth(width)
    text:SetJustifyH(side)
    text:SetWordWrap(false)
    return text
end

local function MakeView(native, health)
    local view = CreateFrame("Frame",nil,health)
    view:SetAllPoints(health)
    view:SetFrameLevel(health:GetFrameLevel()+3)
    view:EnableMouse(false)
    view.level = Label(view,"LEFT",6,27)
    view.levelSkull = view:CreateTexture(nil,"OVERLAY")
    view.levelSkull:SetPoint("LEFT",view,"LEFT",6,0)
    view.levelSkull:SetSize(12,12)
    view.levelSkull:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
    view.healthValue = Label(view,"CENTER",0,76)
    view.healthPercent = Label(view,"RIGHT",-5,36)

    local mana = CreateFrame("StatusBar",nil,view)
    mana:SetHeight(manaHeight)
    mana:EnableMouse(false)
    mana:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    local color = PowerBarColor and PowerBarColor.MANA
    if color then mana:SetStatusBarColor(color.r,color.g,color.b) else mana:SetStatusBarColor(0,0.4,1) end
    local background = mana:CreateTexture(nil,"BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.04,0.07,0.12,0.9)
    mana.amount = Label(mana,"CENTER",0,76)
    mana.percent = Label(mana,"RIGHT",-5,36)
    view.mana = mana

    local rare = CreateFrame("Frame",nil,view)
    rare:EnableMouse(false)
    rare:SetPoint("TOPRIGHT",view,"TOPLEFT",-2,2)
    rare:SetPoint("BOTTOMRIGHT",view,"BOTTOMLEFT",-2,-2)
    rare:SetWidth(9)
    for _, edge in ipairs({"LEFT","TOP","BOTTOM"}) do
        local line = rare:CreateTexture(nil,"OVERLAY")
        line:SetColorTexture(0.68,0.79,0.9,1)
        if edge == "LEFT" then
            line:SetPoint("TOPLEFT")
            line:SetPoint("BOTTOMLEFT")
            line:SetWidth(2)
        else
            line:SetPoint(edge.."LEFT")
            line:SetPoint(edge.."RIGHT")
            line:SetHeight(2)
        end
    end
    view.rare = rare

    local auras = CreateFrame("Frame",nil,native)
    auras:SetPoint("BOTTOM",native.name,"TOP",0,3)
    auras:SetSize(auraLimit*24,24)
    auras:SetFrameLevel(native:GetFrameLevel()+4)
    auras:EnableMouse(false)
    auras.icons = {}
    for i=1,auraLimit do
        local icon = auras:CreateTexture(nil,"ARTWORK")
        icon:SetPoint("BOTTOMLEFT",auras,"BOTTOMLEFT",(i-1)*24,0)
        auras.icons[i] = icon
    end
    view.auras = auras
    return view
end

-- Snapshot cosmetic positions only. The driver retains ownership of unit assignment,
-- clicks, health fills, native cast state, visibility, and all nameplate hit rectangles.
local function Points(widget)
    if not CanMeasure(widget) then return end
    local points={}
    for i=1,widget:GetNumPoints() do
        local point,relative,relativePoint,x,y=widget:GetPoint(i)
        if not Suite.IsReadable(point) or not Suite.IsReadable(relative)
            or not Suite.IsReadable(relativePoint) or not IsNumber(x) or not IsNumber(y) then return end
        points[i]={point,relative,relativePoint,x,y}
    end
    return points
end

local function Matches(widget, points)
    local current=Points(widget)
    if not current or #current ~= #points then return false end
    for i, point in ipairs(points) do
        for j=1,5 do if current[i][j] ~= point[j] then return false end end
    end
    return true
end

local function Move(view, widget, anchor, relative, point, x, y, opposite, height)
    if not CanMeasure(widget) or not CanMeasure(relative) then return false end
    local points, oldHeight = Points(widget), height and widget:GetHeight()
    if not points or height and not IsNumber(oldHeight) then return end
    widget:ClearAllPoints()
    widget:SetPoint(anchor,relative,point,x,y)
    if opposite then widget:SetPoint(opposite[1],relative,opposite[2],opposite[3],y) end
    if height then widget:SetHeight(height) end
    view.layout[#view.layout+1]={widget=widget,points=points,applied=Points(widget),
        originalHeight=oldHeight,appliedHeight=height}
    return true
end

local function Suppress(view, region)
    if Usable(region) and type(region.GetAlpha) == "function" then
        local alpha = region:GetAlpha()
        if Suite.IsReadable(alpha) and type(alpha) == "number" then
            if view.faded[region] == nil then view.faded[region] = alpha end
            region:SetAlpha(0)
            return true
        end
    end
end

local function Shown(region)
    if not Usable(region) then return false end
    local shown=SafeCall(region.IsShown,region)
    return Suite.IsReadable(shown) and shown == true
end

local function RestoreRegionAlpha(region, alpha)
    local current = Usable(region) and region:GetAlpha()
    if Suite.IsReadable(current) and current == 0 then region:SetAlpha(alpha) end
end

function Nameplates:UpdateLevel(view)
    local native=view.native
    local previous=view.levelBadge
    if previous then
        RestoreRegionAlpha(previous,view.faded[previous])
        view.faded[previous],view.levelBadge=nil,nil
    end
    local badge=native.PlayerLevelDiffFrame
    if not Shown(badge) then badge=native.LevelFrame end
    view.level:Hide()
    view.levelSkull:Hide()
    if not Shown(badge) then return end
    local skull=badge.highLevelTexture or badge.HighLevelTexture
    if Shown(skull) then
        if Suppress(view,badge) then
            view.levelBadge=badge
            view.levelSkull:Show()
        end
        return
    end
    local source=badge.playerLevelDiffText or badge.LevelText
    if not Shown(source) then return end
    local text=SafeCall(source.GetText,source)
    if Suite.IsReadable(text) and (type(text) ~= "string" or text == "") then return end
    if not Suppress(view,badge) then return end
    view.levelBadge=badge
    view.level:SetText(text)
    local ok,r,g,b,a=pcall(source.GetTextColor,source)
    if ok and IsNumber(r) and IsNumber(g) and IsNumber(b) and IsNumber(a) then
        view.level:SetTextColor(r,g,b,a)
    else
        view.level:SetTextColor(1,1,1,1)
    end
    view.level:Show()
end

local function RestoreAlpha(view)
    for region, alpha in pairs(view.faded or {}) do RestoreRegionAlpha(region,alpha) end
    view.faded,view.levelBadge=nil,nil
end

local function Restore(view)
    for _, original in ipairs(view.layout or {}) do
        local widget=original.widget
        if Usable(widget) and original.applied and Matches(widget,original.applied) then
            widget:ClearAllPoints()
            for _, point in ipairs(original.points) do widget:SetPoint(unpack(point,1,5)) end
            local height=original.appliedHeight and widget:GetHeight()
            if IsNumber(height) and height == original.appliedHeight then widget:SetHeight(original.originalHeight) end
        end
    end
    RestoreAlpha(view)
    if view.justify and Usable(view.native.name) then view.native.name:SetJustifyH(view.justify) end
    view.layout,view.faded,view.justify=nil,nil,nil
    view.auras:Hide()
    view:Hide()
end

local function SetNumberText(text, format, ...)
    -- The client authorizes secret numbers as display arguments to SetFormattedText.
    -- Keep them out of Lua formatting, comparisons and arithmetic.
    for i=1,select("#",...) do
        local value=select(i,...)
        if Suite.IsReadable(value) and type(value) ~= "number" then
            text:SetText("")
            return
        end
    end
    if text.SetFormattedText then text:SetFormattedText(format,...) end
end

function Nameplates:UpdateHealth(view, unit)
    local current,maximum=SafeCall(UnitHealth,unit),SafeCall(UnitHealthMax,unit)
    SetNumberText(view.healthValue,"%d / %d",current,maximum)
    local curve = CurveConstants and CurveConstants.ScaleTo100
    local percent = curve and SafeCall(UnitHealthPercent,unit,true,curve)
    if Suite.IsReadable(percent) and not IsNumber(percent) and IsNumber(current) and IsNumber(maximum) and maximum > 0 then
        percent=100*current/maximum
    end
    SetNumberText(view.healthPercent,"%.0f%%",percent)
end

function Nameplates:UpdateMana(view, unit)
    local kind = SafeCall(UnitPowerType,unit)
    local maximum = SafeCall(UnitPowerMax,unit,0)
    local value = SafeCall(UnitPower,unit,0)
    local show = Suite.IsReadable(kind) and kind == 0 and Suite.IsReadable(maximum)
        and type(maximum) == "number" and maximum > 0 and Suite.IsReadable(value) and type(value) == "number"
    view.mana:SetShown(show)
    if show then
        view.mana:SetMinMaxValues(0,maximum)
        view.mana:SetValue(value)
        SetNumberText(view.mana.amount,"%d / %d",value,maximum)
        SetNumberText(view.mana.percent,"%.0f%%",100*value/maximum)
    end
end

function Nameplates:UpdateAuras(view, unit)
    local mode=self.debuffMode
    local auras
    if mode ~= "hide" and C_UnitAuras then
        auras=SafeCall(C_UnitAuras.GetUnitAuras,unit,mode == "mine" and ownFilter or regularFilter,auraLimit)
    end
    local valid=Suite.IsReadable(auras) and type(auras) == "table"
    for i, icon in ipairs(view.auras.icons) do
        local data=valid and auras[i]
        if Suite.IsReadable(data) and type(data) == "table" then
            local own=Suite.IsReadable(data.isFromPlayerOrPlayerPet) and data.isFromPlayerOrPlayerPet == true
            local size=mode == "larger" and own and 22 or 16
            icon:SetSize(size,size)
            -- SetTexture accepts the native icon directly, even when its identity is restricted.
            local texture = data.icon
            local display = not Suite.IsReadable(texture) or type(texture) == "number" or type(texture) == "string"
            if display then icon:SetTexture(texture) end
            icon:SetShown(display)
        else
            icon:Hide()
        end
    end
    view.auras:SetShown(view:IsShown() and valid)
end

function Nameplates:Bind(unit, plate)
    if InCombatLockdown() or not UnitToken(unit) or not Usable(plate) then return end
    local native=plate.UnitFrame
    if not Usable(native) or not Usable(native.name) or not Usable(native.healthBar) then return end
    local health=native.healthBar
    if not health:IsShown() then return end

    local view=self.views[native]
    if not view then
        view=MakeView(native,health)
        view.native=native
        self.views[native]=view
    end
    -- Start with Blizzard's current layout if this pooled frame has been reused.
    if view.layout then return end
    self.active[unit]=view
    view.layout,view.faded={},{}
    if Move(view,native.name,"BOTTOMLEFT",health,"TOPLEFT",2,2,{"BOTTOMRIGHT","TOPRIGHT",-2}) then
        view.justify=native.name:GetJustifyH()
        native.name:SetJustifyH("CENTER")
    end
    self:UpdateLevel(view)
    for _, field in ipairs({"Text","LeftText","RightText"}) do Suppress(view,health[field]) end
    local castContainer=native.CastBarsContainer
    local cast=Usable(castContainer) and castContainer.castBar
    local oldHeight=CanMeasure(cast) and cast:GetHeight()
    local movedCast=Move(view,cast,"TOPLEFT",health,"BOTTOMLEFT",0,-manaHeight-5,{"TOPRIGHT","BOTTOMRIGHT",0},self.castHeight)
    if movedCast and CanMeasure(cast.Border) then
        local borderHeight=cast.Border:GetHeight()
        local newHeight=IsNumber(oldHeight) and IsNumber(borderHeight) and borderHeight > 0
            and math.max(1,borderHeight+self.castHeight-oldHeight) or nil
        Move(view,cast.Border,"CENTER",cast,"CENTER",0,0,nil,newHeight)
    end
    -- Restricted native regions keep their layout. Anchor the Suite mana bar
    -- below the native cast container in that case so the two cannot overlap.
    local manaAnchor=not movedCast and Usable(castContainer) and castContainer or view
    view.mana:ClearAllPoints()
    view.mana:SetPoint("TOPLEFT",view,"BOTTOMLEFT",0,-2)
    view.mana:SetPoint("TOPRIGHT",view,"BOTTOMRIGHT",0,-2)
    if manaAnchor ~= view then
        view.mana:ClearAllPoints()
        view.mana:SetPoint("TOP",manaAnchor,"BOTTOM",0,-2)
        view.mana:SetPoint("LEFT",view,"LEFT",0,0)
        view.mana:SetPoint("RIGHT",view,"RIGHT",0,0)
    end
    local nativeAuras=native.AurasFrame
    if Usable(nativeAuras) then
        if self.debuffMode == "hide" or C_UnitAuras and type(C_UnitAuras.GetUnitAuras) == "function" then
            Suppress(view,nativeAuras.DebuffListFrame)
        end
        for _, field in ipairs({"CrowdControlListFrame","LossOfControlFrame"}) do
            Move(view,nativeAuras[field],"LEFT",health,"RIGHT",6,0)
        end
    end
    local kind=SafeCall(UnitClassification,unit)
    view.rare:SetShown(Suite.IsReadable(kind) and (kind == "rare" or kind == "rareelite"))
    view:Show()
    self:UpdateHealth(view,unit)
    self:UpdateMana(view,unit)
    self:UpdateAuras(view,unit)
end

local events = CreateFrame("Frame")
Nameplates.events=events
local function FindPlate(unit)
    return C_NamePlate and SafeCall(C_NamePlate.GetNamePlateForUnit,unit)
end

function Nameplates:Refresh()
    for _, view in pairs(self.views) do if view.layout then Restore(view) end end
    self.active={}
    if not self.enabled then return end
    local plates = C_NamePlate and SafeCall(C_NamePlate.GetNamePlates)
    if not Suite.IsReadable(plates) or type(plates) ~= "table" then return end
    for _, plate in ipairs(plates) do
        if Usable(plate) then self:Bind(SafeCall(plate.GetUnit,plate),plate) end
    end
end

events:SetScript("OnEvent",function(_,event,unit)
    if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ENTERING_WORLD" then
        if not InCombatLockdown() then Nameplates:Refresh() end
    elseif not UnitToken(unit) then return
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local view=Nameplates.active[unit]
        if view then
            Nameplates.active[unit]=nil
            view.auras:Hide()
            view:Hide()
            RestoreAlpha(view)
            if not InCombatLockdown() then Restore(view) end
        end
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        if not InCombatLockdown() then Nameplates:Bind(unit,FindPlate(unit)) end
    else
        local view=Nameplates.active[unit]
        if not view then return end
        if event == "UNIT_AURA" then Nameplates:UpdateAuras(view,unit)
        elseif event == "UNIT_LEVEL" then Nameplates:UpdateLevel(view)
        elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then Nameplates:UpdateHealth(view,unit)
        else Nameplates:UpdateMana(view,unit) end
    end
end)

function Nameplates:Apply()
    local enabled=Suite.db.customNameplates == true
    local debuffMode=self:Option("nameplateDebuffs").value
    local castHeight=self:Option("nameplateCastHeight").value
    if self.enabled == enabled and self.debuffMode == debuffMode and self.castHeight == castHeight then
        Suite.pending.nameplates=nil
        return
    end
    Suite.AfterCombat("nameplates",function()
        self.enabled,self.debuffMode,self.castHeight=enabled,debuffMode,castHeight
        if enabled then
            for _, event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","NAME_PLATE_UNIT_ADDED",
                "NAME_PLATE_UNIT_REMOVED","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_POWER_UPDATE","UNIT_MAXPOWER",
                "UNIT_DISPLAYPOWER","UNIT_AURA","UNIT_LEVEL"}) do events:RegisterEvent(event) end
        else events:UnregisterAllEvents() end
        self:Refresh()
    end)
end
