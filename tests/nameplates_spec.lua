local Suite,equal,SetCombat=...
local plates=Suite.Nameplates
local oldCreate,oldPlates,oldAuras=CreateFrame,C_NamePlate,C_UnitAuras
local oldHealth,oldHealthMax,oldHealthPercent=UnitHealth,UnitHealthMax,UnitHealthPercent
local oldPower,oldPowerMax,oldPowerType=UnitPower,UnitPowerMax,UnitPowerType
local oldClassification,oldEnabled=UnitClassification,Suite.db.customNameplates
local oldMode,oldHeight=Suite.db.nameplateDebuffs,Suite.db.nameplateCastHeight
local oldCurve=CurveConstants

local function Widget(kind,parent)
    local widget=oldCreate(kind,nil,parent)
    widget.points={}
    widget.SetPoint=function(self,point,relative,relativePoint,x,y)
        self.points[#self.points+1]={point,relative,relativePoint or point,x or 0,y or 0}
    end
    widget.ClearAllPoints=function(self) self.points={} end
    widget.GetNumPoints=function(self) return #self.points end
    widget.GetPoint=function(self,index)
        assert(not self.anchorRestricted,"cannot measure restricted anchors")
        return unpack(self.points[index],1,5)
    end
    widget.IsForbidden=function(self) return self.forbidden == true end
    widget.IsAnchoringRestricted=function(self) return self.anchorRestricted == true end
    widget.GetJustifyH=function(self) return self.justifyH or "LEFT" end
    widget.GetAlpha=function(self) return self.alpha or 1 end
    widget.SetStatusBarTexture=function(self,texture) self.fill=texture end
    widget.SetStatusBarColor=function(self,...) self.color={...} end
    widget.CreateFontString=function(self) return Widget("FontString",self) end
    widget.SetFormattedText=function(self,format,...)
        local first=...
        self.text=issecretvalue(first) and "[client displays secret]" or string.format(format,...)
    end
    return widget
end
CreateFrame=function(kind,_,parent) return Widget(kind,parent) end

local plate=Widget("Frame")
local native=Widget("Button",plate)
plate.UnitFrame=native
plate.GetUnit=function() return "nameplate1" end
native.name=Widget("FontString",native)
native.name:SetFont("NativeFont",12,"THICKOUTLINE")
native.name:SetPoint("BOTTOM",native,"TOP",0,2)
native.LevelFrame=Widget("Frame",native)
native.PlayerLevelDiffFrame=Widget("Frame",native)
local badge=native.PlayerLevelDiffFrame
badge.playerLevelDiffText=Widget("FontString",badge)
badge.playerLevelDiffText:SetText("7")
badge.playerLevelDiffText.GetTextColor=function() return 1,0.82,0,1 end
badge.highLevelTexture=Widget("Texture",badge)
badge:Show();badge.playerLevelDiffText:Show()
native.healthBar=Widget("StatusBar",native)
local health=native.healthBar
health:Show()
health.Text=Widget("FontString",health)
native.CastBarsContainer=Widget("Frame",native)
local cast=Widget("StatusBar",native.CastBarsContainer)
cast:SetPoint("CENTER",native.CastBarsContainer,"CENTER",0,0)
cast:SetHeight(9)
native.CastBarsContainer.castBar=cast
native.AurasFrame=Widget("Frame",native)
local auras=native.AurasFrame
auras.DebuffListFrame=Widget("Frame",auras)
auras.CrowdControlListFrame=Widget("Frame",auras)
auras.CrowdControlListFrame:EnableMouse(false)
auras.LossOfControlFrame=Widget("Frame",auras)

C_NamePlate={GetNamePlates=function() return {plate} end,GetNamePlateForUnit=function() return plate end}
local filter
C_UnitAuras={GetUnitAuras=function(_,selected,limit)
    filter=selected
    equal(limit,6,"regular aura work stays bounded")
    return {{icon=100,isFromPlayerOrPlayerPet=false},{icon=200,isFromPlayerOrPlayerPet=true}}
end}
UnitHealth=function() return 24 end
UnitHealthMax=function() return 60 end
UnitHealthPercent=function() return 40 end
UnitPower=function() return 12 end
UnitPowerMax=function() return 24 end
UnitPowerType=function() return 0 end
UnitClassification=function() return "rareelite" end
CurveConstants={ScaleTo100={}}

SetCombat(false)
Suite.db.customNameplates,Suite.db.nameplateDebuffs,Suite.db.nameplateCastHeight=true,"larger",16
plates:Apply()
local view=plates.active.nameplate1
equal(view.healthValue:GetText(),"24 / 60","current and max health appear together")
equal(view.healthPercent:GetText(),"40%","health percentage uses the client-scale curve")
equal(view.mana.amount:GetText(),"12 / 24","mana has its own current and max value")
equal(view.mana.percent:GetText(),"50%","mana percentage is separate")
equal(view.rare:IsShown(),true,"rare elites get a bracket")
equal(native.name.fontFlags,"THICKOUTLINE","preserves the native outline")
equal(native.name:GetJustifyH(),"CENTER","centers native name")
equal(view.level.points[1][1],"LEFT","Suite displays the level inside the left edge")
equal(view.level:GetText(),"7","Suite uses Blizzard's displayed level")
equal(view.level.textColor[2],0.82,"Suite uses Blizzard's displayed difficulty color")
equal(badge:GetAlpha(),0,"the native level badge is hidden")
equal(cast:GetHeight(),16,"cast height follows the chosen size")
equal(cast.points[1][2],health,"cast is anchored below native health")
equal(auras.CrowdControlListFrame.points[1][3],"RIGHT","native large debuffs anchor to the right")
equal(auras.CrowdControlListFrame.mouseEnabled,false,"large debuffs retain native click-through")
equal(view.auras.mouseEnabled,false,"Suite's regular debuffs are click-through")
equal(view.auras.icons[1]:GetWidth(),16,"other player's debuff stays small")
equal(view.auras.icons[2]:GetWidth(),22,"only your debuff gets bigger")

Suite.db.nameplateDebuffs="mine";plates:Apply()
equal(filter:find("|PLAYER",1,true)~=nil,true,"Mine only uses Blizzard's source filter")
Suite.db.nameplateDebuffs="hide";plates:Apply()
equal(view.auras:IsShown(),false,"Hide removes the regular debuff row")
equal(auras.DebuffListFrame:GetAlpha(),0,"Hide suppresses the native regular row too")
equal(auras.CrowdControlListFrame:GetAlpha(),1,"Hide leaves big debuffs visible")

UnitHealth=function() return {secret=true} end
SetCombat(true)
plates.events:OnEvent("UNIT_HEALTH","nameplate1")
equal(view.healthValue:GetText(),"[client displays secret]","restricted health is sent directly to the text widget")
plates.events:OnEvent("NAME_PLATE_UNIT_REMOVED","nameplate1")
equal(view:IsShown(),false,"removal during combat clears the owned display")
equal(health.Text:GetAlpha(),1,"removed plate returns native text before recycling")
plates.events:OnEvent("NAME_PLATE_UNIT_ADDED","nameplate1")
equal(plates.active.nameplate1,nil,"protected layout waits for combat to end")
SetCombat(false)
plates.events:OnEvent("PLAYER_REGEN_ENABLED")
equal(plates.active.nameplate1,view,"rebind uses the pooled decoration")
Suite.db.customNameplates=false;plates:Apply()
equal(native.name:GetJustifyH(),"LEFT","disabling restores native name justification")
equal(cast:GetHeight(),9,"disabling restores native cast height")
equal(auras.DebuffListFrame:GetAlpha(),1,"disabling restores the native debuff display")
equal(view.auras:IsShown(),false,"disabling hides the custom aura display")

-- Native NPC nameplates can be anchor restricted outside combat.
native.name.anchorRestricted=true
native.LevelFrame.anchorRestricted=true
native.PlayerLevelDiffFrame.anchorRestricted=true
cast.anchorRestricted=true
cast.GetHeight=function() error("cannot measure restricted cast height") end
auras.CrowdControlListFrame.anchorRestricted=true
auras.LossOfControlFrame.anchorRestricted=true
UnitHealth=function() return 24 end
Suite.db.customNameplates=true;plates:Apply()
equal(native.name.points[1][2],native,"restricted name stays on its native anchor")
equal(native.name:GetJustifyH(),"LEFT","restricted name keeps native alignment")
equal(cast.points[1][2],native.CastBarsContainer,"restricted cast bar keeps its native anchor")
equal(view.mana.points[1][2],native.CastBarsContainer,"mana clears the native cast bar in the restricted layout")
equal(view.healthValue:GetText(),"24 / 60","passive health text still works on a restricted plate")
equal(view.level:IsShown(),true,"restricted plate still shows the Suite level")
equal(badge:GetAlpha(),0,"restricted plate hides the badge without measuring it")
badge.highLevelTexture:Show()
plates.events:OnEvent("UNIT_LEVEL","nameplate1")
equal(view.levelSkull:IsShown(),true,"a native skull replaces the number on the left")
equal(view.level:IsShown(),false,"the skull has no overlapping level text")
Suite.db.customNameplates=false;plates:Apply()
equal(view:IsShown(),false,"disabling safely hides the restricted plate's decoration")
equal(badge:GetAlpha(),1,"disabling restores the original level badge")

CreateFrame,C_NamePlate,C_UnitAuras=oldCreate,oldPlates,oldAuras
UnitHealth,UnitHealthMax,UnitHealthPercent=oldHealth,oldHealthMax,oldHealthPercent
UnitPower,UnitPowerMax,UnitPowerType=oldPower,oldPowerMax,oldPowerType
UnitClassification,CurveConstants=oldClassification,oldCurve
Suite.db.customNameplates,Suite.db.nameplateDebuffs,Suite.db.nameplateCastHeight=oldEnabled,oldMode,oldHeight
plates:Apply()
