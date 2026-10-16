local Suite, equal, Frame, SetCombat = ...
local helper, bars, rep = Suite.ProfessionHelper, Suite.Castbars, Suite.ZoneReputation
local names = { "CreateFrame", "C_Timer", "RegisterStateDriver", "C_SpellBook", "C_Container", "C_Item", "C_Map", "C_Reputation", "GetMouseFoci",
    "UnitCastingInfo", "UnitChannelInfo", "UnitIsDeadOrGhost", "GetCursorInfo", "IsAltKeyDown", "IsControlKeyDown", "IsShiftKeyDown", "IsInInstance",
    "UnitFactionGroup", "GetRealZoneText", "GetSubZoneText", "PlayerCastingBarFrame", "TargetFrame", "FocusFrame", "EditModeManagerFrame", "TooltipDataProcessor", "Enum", "UIParent" }
local old, states, oldDB, oldPending = {}, {}, Suite.db, Suite.pending
for _, name in ipairs(names) do old[name] = _G[name] end
for _, module in ipairs({helper,bars,rep}) do states[module]={}; for key,value in pairs(module) do states[module][key]=value end end
bars.records, bars.hooked = {}, {}
Suite.db, Suite.pending = Suite.Copy(Suite.defaults), {}
local timers, made = {}, 0
local function Drain()
    local pending = timers; timers={}
    for _, timer in ipairs(pending) do if not timer.cancelled then timer.callback() end end
end
local function Pending() local n=0; for _,t in ipairs(timers) do if not t.cancelled then n=n+1 end end; return n end
C_Timer = { NewTimer=function(_,callback) local t={callback=callback,Cancel=function(self)self.cancelled=true end}; timers[#timers+1]=t; return t end }
CreateFrame=function(kind,name,parent,template)
    assert(not InCombatLockdown(),"new feature construction waits for combat")
    made=made+1; local f=old.CreateFrame(kind,name,parent,template); f.attributes={}; f.registered={}
    f.SetAttribute=function(self,key,value) assert(not InCombatLockdown()); self.attributes[key]=value end
    f.SetFrameRef=function()end
    f.RegisterEvent=function(self,event)self.registered[event]=true end; f.UnregisterAllEvents=function(self)self.registered={} end
    return f
end
local function Native(width,height)
    local f=Frame(); f.width,f.height,f.shown=width,height,true
    f.IsForbidden=function()return false end; f.IsProtected=function()return false end
    f.SetSize=function(self,w,h)assert(not InCombatLockdown()); self.width,self.height=w,h end
    f.UpdateShownState=function(self)assert(not InCombatLockdown());self.shown=self.isInEditMode==true end
    return f
end
UIParent=Native(1000,800)
PlayerCastingBarFrame=Native(260,21); TargetFrame=Native(100,100); FocusFrame=Native(100,100)
TargetFrame.spellbar=Native(150,15); FocusFrame.spellbar=Native(160,16)
EditModeManagerFrame=Native(1,1); EditModeManagerFrame.shown=false
local alt,ctrl,shift,learned,locked,quality,class,cursor,cast,dead=true,false,false,true,false,2,4,nil,nil,false
local owner=Native(32,32); owner.GetBagID=function()return 0 end; owner.GetID=function()return 1 end
owner.GetLeft=function()return 100 end; owner.GetBottom=function()return 100 end
local foci={owner}; GetMouseFoci=function()return foci end
UnitCastingInfo=function()return cast end; UnitChannelInfo=function()end; UnitIsDeadOrGhost=function()return dead end
GetCursorInfo=function()return cursor end
IsAltKeyDown=function()return alt end; IsControlKeyDown=function()return ctrl end; IsShiftKeyDown=function()return shift end
C_SpellBook={IsSpellKnown=function()return learned end}
local itemID=100
C_Container={GetContainerItemInfo=function()return {itemID=itemID,isLocked=locked,stackCount=1}end}
C_Item={GetItemInfo=function()return "Item","item:100",quality,20,0,nil,nil,nil,"INVTYPE_HEAD",nil,nil,class end}
RegisterStateDriver=function(controller,key,condition)controller.condition=condition end
TooltipDataProcessor={AddTooltipPostCall=function()end}; Enum={TooltipDataType={Item=1}}
local instance,side,zone,subzone=false,"Alliance","Dun Morogh",""
IsInInstance=function()return instance end; UnitFactionGroup=function()return side end
GetRealZoneText=function()return zone end; GetSubZoneText=function()return subzone end
local areas={[1]="Dun Morogh",[12]="Elwynn",[392]="Ratchet",[14]="Durotar"}
C_Map={GetAreaInfo=function(id)return areas[id]end}
local writes,watched=0,72
C_Reputation={GetFactionDataByID=function(id)return {name="Faction "..id,isHeader=false,isHeaderWithRep=false}end,
    GetWatchedFactionData=function()return {factionID=watched}end,
    SetWatchedFactionByID=function(id)writes=writes+1;watched=id;if rep.events then rep.events.OnEvent(rep.events,"UPDATE_FACTION")end end}
SetCombat(false); helper:Apply();bars:Apply();rep:Apply()
equal(made,0,"three optional modules construct nothing by default")
equal(writes,0,"reputation stays unchanged by default")
Suite.db.modifierDisenchant=true; SetCombat(true);helper:Apply()
equal(made,0,"profession overlay creation defers in combat")
SetCombat(false);Suite.pending.professions();Suite.pending.professions=nil
equal(helper.item,100,"learned modifier Disenchant offers eligible carried gear")
equal(helper.button.attributes["alt-type1"],"spell","only deliberate modifier-left action is prepared")
equal(helper.button.attributes["target-bag"],0,"secure spell targets the exact bag")
equal(helper.button.attributes["target-slot"],1,"secure spell targets the exact slot")
equal(helper.controller.condition:find("nomod:ctrl",1,true)~=nil,true,"secure activation excludes extra modifiers")
ctrl=true;equal(helper:Eligible(0,1),nil,"multiple modifiers suppress destructive action");ctrl=false
locked=true;equal(helper:Eligible(0,1),nil,"locked items cannot be offered");locked=false
learned=false;equal(helper:Eligible(0,1),nil,"unknown Disenchant does not prepare action");learned=true
quality=1;equal(helper:Eligible(0,1),nil,"common items are excluded");quality=2
class=7;equal(helper:Eligible(0,1),nil,"reagents are excluded");class=4
cursor="item";equal(helper:Eligible(0,1),nil,"occupied cursor blocks Disenchant");cursor=nil
cast="spell";equal(helper:Eligible(0,1),nil,"casting blocks Disenchant");cast=nil
equal(helper:Eligible(-1,1),nil,"bank bags are excluded")
itemID={secret=true};equal(helper:Eligible(0,1),nil,"secret item identity never reaches native metadata");itemID=100
itemID=101;helper.button.PreClick(helper.button,"LeftButton",false)
equal(helper.button.attributes["alt-type1"],nil,"changed bag item invalidates an already prepared click")
itemID=100;helper:Refresh();helper.button.PostClick(helper.button,"LeftButton",false)
equal(helper.button:IsShown(),false,"post-click hides stale action until fresh work")
Drain();equal(helper.item,100,"fresh event work can revalidate the remaining slot")
owner.GetID=function()return 2 end
helper.button.PreClick(helper.button,"LeftButton",false)
equal(helper.button.attributes["alt-type1"],nil,"recycled bag button cannot target its old slot")
equal(helper.button.attributes["target-slot"],nil,"recycled target clears pending item targeting too")
owner.GetID=function()return 1 end;helper:Refresh()
Suite.db.modifierDisenchant=false;SetCombat(true);helper:Apply();Suite.db.modifierDisenchant=true;helper:Apply()
equal(Suite.pending.professionHide,nil,"reenabling cancels a deferred disable")
SetCombat(false);Suite.pending.professions();Suite.pending.professions=nil
Suite.db.modifierDisenchant=false;helper:Apply()
equal(helper.button:IsShown(),false,"disable hides the helper")
equal(helper.button.attributes["target-slot"],nil,"disable clears targeting attributes")
bars:Set("player","width",400)
equal(PlayerCastingBarFrame.width,260,"size preferences alone do not enable a native override")
bars:Set("player","enabled",true)
equal(PlayerCastingBarFrame.width,400,"enabled player override applies the chosen width")
equal(TargetFrame.spellbar.width,150,"player settings do not change target castbar")
-- Native target/focus size accessors can depend on their aura anchor. A resolved
-- rectangle must not be required when the configured dimensions are readable.
TargetFrame.spellbar.GetWidth=function(self,ignoreRect)return ignoreRect and self.width or {secret=true} end
TargetFrame.spellbar.GetHeight=function(self,ignoreRect)return ignoreRect and self.height or {secret=true} end
bars:Set("target","width",300);bars:Set("target","enabled",true)
equal(TargetFrame.spellbar.width,300,"target has independent sizing")
bars:Set("target","height",36)
equal(TargetFrame.spellbar.height,36,"target height applies despite restricted resolved aura geometry")
equal(bars.records[TargetFrame.spellbar].height,15,"target captures configured native height for restoration")
equal(bars:SizeStatus("target"),nil,"successful target size is not reported unavailable")
local targetHeight=TargetFrame.spellbar.GetHeight
TargetFrame.spellbar.GetHeight=function()return {secret=true}end
bars:Set("target","enabled",false)
equal(TargetFrame.spellbar.height,15,"target disabling restores the captured native height")
bars:Set("target","enabled",true)
equal(TargetFrame.spellbar.height,15,"restricted configured dimensions never authorize a guessed override")
equal(bars:SizeStatus("target"),"Native size is unavailable; custom size has not been applied.","unavailable dimensions explain why size is not applied")
TargetFrame.spellbar.GetHeight=targetHeight;bars:Apply()
equal(TargetFrame.spellbar.height,36,"target override resumes when configured size is readable")
bars:Set("focus","height",30);bars:Set("focus","enabled",true)
equal(FocusFrame.spellbar.height,30,"focus has independent sizing")
bars:Set("player","width",{secret=true});equal(PlayerCastingBarFrame.width,400,"restricted size input is ignored")
equal(bars:Preview("target"),true,"native target preview is available while idle and visible")
equal(TargetFrame.spellbar.isInEditMode,true,"preview uses native castbar visibility state")
bars:StopPreview();equal(TargetFrame.spellbar.isInEditMode,nil,"preview restores its captured state")
TargetFrame.shown=false;equal(bars:Preview("target"),false,"hidden target parent prevents a misleading preview");TargetFrame.shown=true
cast="spell";equal(bars:Preview("player"),false,"real casts prevent preview takeover");cast=nil
equal(bars:Preview("player"),true,"player preview starts outside combat")
SetCombat(true);bars:StopPreview()
equal(bars.preview~=nil,true,"combat defers native preview cleanup")
SetCombat(false);Suite.pending.castbarPreview();equal(bars.preview,nil,"preview cleanup completes after combat")
EditModeManagerFrame.shown=true;bars:Refresh()
equal(PlayerCastingBarFrame.width,260,"Edit Mode releases custom dimensions to native management")
EditModeManagerFrame.shown=false;bars:Refresh()
equal(PlayerCastingBarFrame.width,400,"custom dimensions return after Edit Mode")
SetCombat(true);bars:Set("player","enabled",false)
equal(PlayerCastingBarFrame.width,400,"disabling in combat does not mutate protected geometry")
SetCombat(false);Suite.pending.castbars();Suite.pending.castbars=nil
equal(PlayerCastingBarFrame.width,260,"disable restores original player width")
equal(PlayerCastingBarFrame.height,21,"disable restores original player height")
bars:Set("target","enabled",false);bars:Set("focus","enabled",false)
equal(TargetFrame.spellbar.width,150,"target restoration keeps native dimensions")
equal(FocusFrame.spellbar.height,16,"focus restoration keeps native dimensions")
equal(rep:Desired(),47,"localized native zone identifies Ironforge reputation")
subzone="Ratchet";equal(rep:Desired(),470,"town reputation takes priority over the larger zone");subzone=""
side="Horde";zone="Durotar";equal(rep:Desired(),76,"Horde zone maps to its own home faction")
zone="Unknown";equal(rep:Desired(),nil,"unmapped zones preserve user choice")
zone="Durotar";instance=true;equal(rep:Desired(),nil,"instances do not choose an outdoor reputation");instance=false
side={secret=true};equal(rep:Desired(),nil,"restricted faction identity prevents guessing");side="Alliance";zone="Dun Morogh"
Suite.db.zoneReputation=true;rep:Apply()
equal(watched,47,"enabling watches the zone's known faction")
equal(writes,1,"native reputation feedback cannot recurse into repeated writes")
watched=72;rep:Queue();Drain();equal(watched,72,"manual watched faction is respected until another zone event")
rep.events.OnEvent(rep.events,"ZONE_CHANGED");Drain();equal(watched,47,"new zone event reconciles tracking")
zone="Unknown";rep.events.OnEvent(rep.events,"ZONE_CHANGED");Drain();equal(watched,47,"unmapped area retains watched faction")
zone="Elwynn";SetCombat(true);rep.events.OnEvent(rep.events,"ZONE_CHANGED")
equal(watched,47,"combat defers reputation changes")
SetCombat(false);Suite.pending.zoneReputation();Suite.pending.zoneReputation=nil
equal(watched,72,"post-combat uses the current zone")
Suite.db.zoneReputation=false;rep:Apply();local previous=writes;rep:Queue();Drain()
equal(writes,previous,"disabled reputation tracking stays inert")
equal(Suite.SettingsCatalog:Search("disenchant")[1].page,"professions","profession tools are searchable")
equal(Suite.SettingsCatalog:Search("castbar sizes")[1].page,"castbars","castbar controls are searchable")
local gui=Suite.GUI
gui:BuildCastbars()
local oldKey,oldMessage=gui.castbarKey,gui.castbarMessage
gui.castbarKey="target";gui:RefreshCastbars();bars:Set("target","enabled",true)
local heightField=gui.castbarFields.height
heightField.input:SetText("42");heightField.input.OnTextChanged(heightField.input,true)
equal(TargetFrame.spellbar.height,42,"typed target height applies immediately without Enter")
equal(heightField.slider.value,42,"live numeric input synchronizes its slider")
heightField.input:SetText("4");heightField.input.OnTextChanged(heightField.input,true)
equal(TargetFrame.spellbar.height,42,"partial out-of-range input does not clamp while typing")
heightField.input:SetText("31");heightField.input.OnTextChanged(heightField.input,false)
equal(TargetFrame.spellbar.height,42,"programmatic field refresh does not apply dimensions")
heightField.input.OnEditFocusLost(heightField.input)
equal(TargetFrame.spellbar.height,31,"leaving the size field commits its valid number")
bars:Set("target","enabled",false);gui.castbarKey,gui.castbarMessage=oldKey,oldMessage;gui:RefreshCastbars()
for _,module in ipairs({helper,bars,rep}) do
    if module.timer then module.timer:Cancel() end
    for key in pairs(module)do module[key]=nil end;for key,value in pairs(states[module])do module[key]=value end
end
for _,name in ipairs(names)do _G[name]=old[name]end
Suite.db,Suite.pending=oldDB,oldPending;SetCombat(false)
