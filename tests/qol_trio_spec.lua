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
    local text=Frame();f.Text=text
    text.width,text.height,text.fontPath,text.fontSize,text.fontFlags=width-10,16,"Fonts\\FRIZQT__.TTF",10,"OUTLINE"
    text.horizontal,text.vertical="LEFT","TOP"
    text.IsForbidden=function()return false end
    text.GetText=function()error("castbar sizing must never inspect native spell text")end
    text.GetFont=function(self)return self.fontPath,self.fontSize,self.fontFlags end
    text.GetJustifyH=function(self)return self.horizontal end;text.GetJustifyV=function(self)return self.vertical end
    text.SetJustifyH=function(self,v)assert(not InCombatLockdown());self.horizontal=v end
    text.SetJustifyV=function(self,v)assert(not InCombatLockdown());self.vertical=v end
    text.SetFont=function(self,path,size,flags)assert(not InCombatLockdown());self.fontPath,self.fontSize,self.fontFlags=path,size,flags end
    local point,size,clear=text.SetPoint,text.SetSize,text.ClearAllPoints
    text.SetPoint=function(self,...)assert(not InCombatLockdown());point(self,...)end
    text.SetSize=function(self,...)assert(not InCombatLockdown());size(self,...)end
    text.ClearAllPoints=function(self)assert(not InCombatLockdown());clear(self)end
    text:SetPoint("TOP",f,"TOP",0,-10)
    local spark=Frame();f.Spark=spark;spark.height,spark.width=20,8
    spark.IsForbidden=function()return false end
    spark:SetPoint("CENTER",f,"LEFT",{secret=true},0)
    spark.GetPoint=function()error("spark progress anchors must remain opaque")end
    spark.GetWidth=function()error("spark thickness must remain native")end
    spark.SetWidth=function()error("custom height must not widen the progress marker")end
    spark.SetHeight=function(self,h)assert(not InCombatLockdown());self.height=h end
    for key, height in pairs({ StandardGlow=12, CraftGlow=12, ChannelShadow=11, BorderMask=13 }) do
        local effect=Frame();f[key]=effect;effect.width,effect.height=37,height
        effect.IsForbidden=function()return false end
        effect.GetPoint=function()error("cast effect progress anchors must remain opaque")end
        effect.SetHeight=function(self,h)assert(not InCombatLockdown());self.height=h end
    end
    f.SetLook=function(self)
        self.Text:ClearAllPoints();self.Text:SetPoint("TOP",self,"TOP",0,-10)
        self.Text:SetFont("Fonts\\FRIZQT__.TTF",10,"OUTLINE")
        self.Spark:SetHeight(20)
        self.StandardGlow:SetHeight(12);self.CraftGlow:SetHeight(12)
        self.ChannelShadow:SetHeight(11);self.BorderMask:SetHeight(13)
    end
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
local areas={[1]="Dun Morogh",[12]="Elwynn",[392]="Ratchet",[14]="Durotar",[16591]="Riverglades"}
C_Map={GetAreaInfo=function(id)return areas[id]end}
local writes,watched=0,72
C_Reputation={GetFactionDataByID=function(id)return {name="Faction "..id,isHeader=false,isHeaderWithRep=false}end,
    GetWatchedFactionData=function()return {factionID=watched}end,
    SetWatchedFactionByID=function(id)writes=writes+1;watched=id;if rep.events then rep.events.OnEvent(rep.events,"UPDATE_FACTION")end end}
SetCombat(false); helper:Apply();bars:Apply();rep:Apply()
equal(made,0,"three optional modules construct nothing by default")
equal(writes,0,"reputation stays unchanged by default")
do
    local oldHook, oldShow, oldFind = hooksecurefunc, StaticPopup_Show, StaticPopup_FindVisible
    local oldReplace, oldTrade = C_Item.ReplaceEnchant, C_Item.ReplaceTradeEnchant
    local callback, hooks, replacements, trades = nil, 0, 0, 0
    local popup = Native(100, 100); popup.which = "REPLACE_ENCHANT"
    StaticPopup_Show = function() end
    StaticPopup_FindVisible = function(which) if popup.which == which and popup.shown then return popup end end
    hooksecurefunc = function(name, fn) equal(name,"StaticPopup_Show","only observes native popup display"); callback=fn; hooks=hooks+1 end
    C_Item.ReplaceEnchant = function() replacements=replacements+1 end
    C_Item.ReplaceTradeEnchant = function() trades=trades+1 end
    helper:Apply(); equal(hooks,0,"disabled enchant option installs no hook")
    Suite.db.autoReplaceEnchant=true; SetCombat(true); helper:Apply()
    equal(hooks,0,"enchant hook installation defers in combat")
    SetCombat(false); Suite.pending.enchantReplacement(); Suite.pending.enchantReplacement=nil
    equal(hooks,1,"enchant option installs independently of disenchant shortcut")
    helper:Apply(); equal(hooks,1,"reapply does not duplicate enchant hook")
    callback("DELETE_ITEM"); callback("REPLACE_TRADESKILL_ENCHANT"); callback({secret=true})
    equal(replacements,0,"unrelated and restricted popup types remain manual")
    learned=false; callback("REPLACE_ENCHANT"); learned=true
    equal(replacements,0,"non-enchanter confirmation remains manual")
    SetCombat(true); callback("REPLACE_ENCHANT"); SetCombat(false)
    equal(replacements,0,"combat confirmation is not accepted or replayed")
    Suite.db.autoReplaceEnchant=false; callback("REPLACE_ENCHANT")
    equal(replacements,0,"disabling makes installed hook inert immediately")
    Suite.db.autoReplaceEnchant={secret=true}; callback("REPLACE_ENCHANT")
    equal(replacements,0,"restricted preference never authorizes replacement")
    Suite.db.autoReplaceEnchant=true; popup.shown=false; callback("REPLACE_ENCHANT")
    equal(replacements,0,"absent confirmation cannot trigger replacement")
    popup.shown=true; popup.IsProtected=function() return true end; callback("REPLACE_ENCHANT")
    equal(replacements,0,"protected confirmation is left native")
    popup.IsProtected=function() return false end
    C_Item.ReplaceEnchant=nil; callback("REPLACE_ENCHANT")
    equal(popup.shown,true,"missing replacement capability preserves confirmation")
    C_Item.ReplaceEnchant=function() error("unavailable") end; callback("REPLACE_ENCHANT")
    equal(popup.shown,true,"replacement API errors preserve manual confirmation")
    C_Item.ReplaceEnchant=function() return false end; callback("REPLACE_ENCHANT")
    equal(popup.shown,true,"explicit native failure preserves manual confirmation")
    C_Item.ReplaceEnchant=function() replacements=replacements+1; callback("REPLACE_ENCHANT") end
    callback("REPLACE_ENCHANT")
    equal(replacements,1,"own-item replacement is requested once despite reentrancy")
    equal(popup.shown,false,"successful replacement dismisses its confirmation")
    popup.which="TRADE_REPLACE_ENCHANT"; popup.shown=true; callback("TRADE_REPLACE_ENCHANT")
    equal(trades,1,"trade replacement uses its distinct native API")
    equal(popup.shown,false,"trade confirmation dismisses after replacement")
    equal(replacements,1,"trade never calls own-item replacement")
    Suite.db.autoReplaceEnchant=false
    helper.replacementHooked=nil
    C_Item.ReplaceEnchant, C_Item.ReplaceTradeEnchant = oldReplace, oldTrade
    hooksecurefunc, StaticPopup_Show, StaticPopup_FindVisible = oldHook, oldShow, oldFind
end
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
local sparkPoint=PlayerCastingBarFrame.Spark.point
local sparkHeightGetter=PlayerCastingBarFrame.Spark.GetHeight
local incompleteSparkRecord={height=21}
PlayerCastingBarFrame.Spark.GetHeight=function()return {secret=true}end
bars:LayoutSpark(PlayerCastingBarFrame,incompleteSparkRecord,{height=40})
equal(incompleteSparkRecord.spark,nil,"restricted native spark height cannot enter resize arithmetic")
equal(PlayerCastingBarFrame.Spark.height,20,"unavailable spark dimensions leave the native marker untouched")
PlayerCastingBarFrame.Spark.GetHeight=sparkHeightGetter
do
    local shadow=PlayerCastingBarFrame.ChannelShadow
    local getter,record=shadow.GetHeight,{height=21}
    shadow.GetHeight=function()return {secret=true}end
    bars:LayoutEffects(PlayerCastingBarFrame,record,{height=40})
    equal(record.effects.ChannelShadow,nil,"restricted shadow height cannot enter resize arithmetic")
    equal(shadow.height,11,"unreadable shadow remains native")
    shadow.GetHeight=getter
    local before=PlayerCastingBarFrame.BorderMask.height
    SetCombat(true);bars:LayoutEffects(PlayerCastingBarFrame,{height=21},{height=60});SetCombat(false)
    equal(PlayerCastingBarFrame.BorderMask.height,before,"effect layout defers all combat mutations")
    -- Return the other effect fixtures to their native baselines after the isolated call.
    PlayerCastingBarFrame:SetLook()
end
Drain()
equal(PlayerCastingBarFrame.width,400,"editing a dimension automatically applies the native override")
equal(bars:Options("player").enabled,true,"dimension edits activate sizing without a separate toggle")
bars:Set("player","enabled",true)
equal(PlayerCastingBarFrame.width,400,"enabled player override applies the chosen width")
equal(PlayerCastingBarFrame.Text.point[1],"CENTER","resized spell label anchors at the bar center")
equal(PlayerCastingBarFrame.Text.point[3],"CENTER","resized spell label follows the bar's center as height changes")
equal(PlayerCastingBarFrame.Text.vertical,"MIDDLE","spell text is vertically centered within its full-height bounds")
equal(PlayerCastingBarFrame.Text.horizontal,"CENTER","spell text remains horizontally centered")
bars:Set("player","height",40)
equal(PlayerCastingBarFrame.Text.fontSize,20,"a thicker castbar grows the spell font proportionally")
equal(PlayerCastingBarFrame.Text.height,40,"spell label bounds follow the complete configured bar height")
equal(PlayerCastingBarFrame.Spark.height,39,"progress spark grows with the bar while retaining native vertical clearance")
equal(PlayerCastingBarFrame.ChannelShadow.height,30,"channel shadow grows with configured bar height")
equal(PlayerCastingBarFrame.StandardGlow.height,31,"ordinary cast edge highlight grows with configured bar height")
equal(PlayerCastingBarFrame.CraftGlow.height,31,"craft edge highlight grows with configured bar height")
equal(PlayerCastingBarFrame.BorderMask.height,32,"effect clipping mask grows along with the visible effect")
equal(PlayerCastingBarFrame.BorderMask.width,37,"effect mask retains its native width")
equal(PlayerCastingBarFrame.Spark.width,8,"resizing keeps the progress marker thin")
equal(PlayerCastingBarFrame.Spark.point,sparkPoint,"resizing preserves opaque engine-controlled spark position")
equal(PlayerCastingBarFrame.Text.width,388,"spell label width follows the resized bar with side clearance")
equal(PlayerCastingBarFrame.Text.fontFlags,"OUTLINE","text resizing retains native font flags")
bars:Set("player","height",60)
equal(PlayerCastingBarFrame.Text.fontSize,28,"very thick bars cap the font at a readable size")
bars:Set("player","height",8)
equal(PlayerCastingBarFrame.Text.fontSize,8,"thin bars retain a legible minimum font")
bars:Set("player","height",40)
PlayerCastingBarFrame:SetLook();Drain()
equal(PlayerCastingBarFrame.Text.fontSize,20,"native look changes reapply the custom font through the existing worker")
equal(PlayerCastingBarFrame.Spark.height,39,"native look changes reapply the spark height through the existing worker")
equal(PlayerCastingBarFrame.ChannelShadow.height,30,"native look reset reapplies shadow height")
equal(PlayerCastingBarFrame.BorderMask.height,32,"native look reset reapplies clipping height")
equal(PlayerCastingBarFrame.Text.point[1],"CENTER","native look resets cannot leave thick-bar text at its old top offset")
equal(TargetFrame.spellbar.width,150,"player settings do not change target castbar")
-- Native target/focus size accessors can depend on their aura anchor. A resolved
-- rectangle must not be required when the configured dimensions are readable.
TargetFrame.spellbar.GetWidth=function(self,ignoreRect)return ignoreRect and self.width or {secret=true} end
TargetFrame.spellbar.GetHeight=function(self,ignoreRect)return ignoreRect and self.height or {secret=true} end
bars:Set("target","width",300);bars:Set("target","enabled",true)
equal(TargetFrame.spellbar.width,300,"target has independent sizing")
bars:Set("target","height",36)
equal(TargetFrame.spellbar.height,36,"target height applies despite restricted resolved aura geometry")
equal(TargetFrame.spellbar.Text.fontSize,18,"target text follows its own configured height")
equal(TargetFrame.spellbar.Spark.height,41,"target spark follows its independent configured height and native overhang")
equal(bars.records[TargetFrame.spellbar].height,15,"target captures configured native height for restoration")
equal(bars:SizeStatus("target"),nil,"successful target size is not reported unavailable")
local targetHeight=TargetFrame.spellbar.GetHeight
TargetFrame.spellbar.GetHeight=function()return {secret=true}end
bars:Set("target","enabled",false)
equal(TargetFrame.spellbar.height,15,"target disabling restores the captured native height")
equal(TargetFrame.spellbar.Text.fontSize,10,"target disable restores the original spell font")
equal(TargetFrame.spellbar.Spark.height,20,"target disable restores original spark height")
equal(TargetFrame.spellbar.Text.point[1],"TOP","target disable restores native text anchors")
equal(TargetFrame.spellbar.Text.point[5],-10,"target disable restores the native top offset")
equal(TargetFrame.spellbar.Text.vertical,"TOP","target disable restores original vertical justification")
equal(TargetFrame.spellbar.Text.width,140,"target disable restores original label dimensions")
bars:Set("target","enabled",true)
equal(TargetFrame.spellbar.height,15,"restricted configured dimensions never authorize a guessed override")
equal(bars:SizeStatus("target"),"Native size is unavailable; custom size has not been applied.","unavailable dimensions explain why size is not applied")
TargetFrame.spellbar.GetHeight=targetHeight;bars:Apply()
equal(TargetFrame.spellbar.height,36,"target override resumes when configured size is readable")
local focusFont={path="Fonts\\FRIZQT__.TTF",size=10,flags="OUTLINE"}
FocusFrame.spellbar.Text.GetFontObject=function()return focusFont end
FocusFrame.spellbar.Text.SetFontObject=function(self,object)
    assert(not InCombatLockdown());self.restoredFontObject=object
    self.fontPath,self.fontSize,self.fontFlags=object.path,object.size,object.flags
end
local playerFontGetter=PlayerCastingBarFrame.Text.GetFont
PlayerCastingBarFrame.Text.GetFont=function()return {secret=true},10,""end
equal(bars:CaptureText(PlayerCastingBarFrame.Text),nil,"unreadable font metadata cannot create a text restoration record")
PlayerCastingBarFrame.Text.GetFont=playerFontGetter
local playerPointGetter=PlayerCastingBarFrame.Text.GetPoint
PlayerCastingBarFrame.Text.GetPoint=function()return "CENTER",PlayerCastingBarFrame,"CENTER",{secret=true},0 end
equal(bars:CaptureText(PlayerCastingBarFrame.Text),nil,"restricted anchor offsets cannot be cached or used in layout")
PlayerCastingBarFrame.Text.GetPoint=playerPointGetter
bars:Set("focus","height",30);bars:Set("focus","enabled",true)
equal(FocusFrame.spellbar.height,30,"focus has independent sizing")
equal(FocusFrame.spellbar.Text.fontSize,15,"focus text has independent sizing")
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
equal(PlayerCastingBarFrame.Text.point[1],"TOP","Edit Mode restores the native spell-text layout")
equal(PlayerCastingBarFrame.Text.fontSize,10,"Edit Mode restores the native spell font")
equal(PlayerCastingBarFrame.Spark.height,20,"Edit Mode restores original spark height")
equal(PlayerCastingBarFrame.ChannelShadow.height,11,"Edit Mode restores original shadow height")
equal(PlayerCastingBarFrame.BorderMask.height,13,"Edit Mode restores original clipping mask height")
EditModeManagerFrame.shown=false;bars:Refresh()
equal(PlayerCastingBarFrame.width,400,"custom dimensions return after Edit Mode")
equal(PlayerCastingBarFrame.Text.fontSize,20,"custom text size returns after Edit Mode")
equal(PlayerCastingBarFrame.Spark.height,39,"custom spark height returns after Edit Mode")
equal(PlayerCastingBarFrame.BorderMask.height,32,"effect mask custom height returns after Edit Mode")
SetCombat(true);bars:Set("player","enabled",false)
equal(PlayerCastingBarFrame.width,400,"disabling in combat does not mutate protected geometry")
equal(PlayerCastingBarFrame.Text.fontSize,20,"combat disable defers font and anchor restoration too")
equal(PlayerCastingBarFrame.Spark.height,39,"combat disable also defers spark geometry changes")
equal(PlayerCastingBarFrame.ChannelShadow.height,30,"combat disable defers shadow restoration")
SetCombat(false);Suite.pending.castbars();Suite.pending.castbars=nil
equal(PlayerCastingBarFrame.width,260,"disable restores original player width")
equal(PlayerCastingBarFrame.height,21,"disable restores original player height")
equal(PlayerCastingBarFrame.Text.fontSize,10,"disable restores original player spell font")
equal(PlayerCastingBarFrame.Spark.height,20,"disable restores original player spark height")
equal(PlayerCastingBarFrame.ChannelShadow.height,11,"disable restores original channel shadow height")
equal(PlayerCastingBarFrame.StandardGlow.height,12,"disable restores ordinary edge highlight height")
equal(PlayerCastingBarFrame.CraftGlow.height,12,"disable restores craft edge highlight height")
equal(PlayerCastingBarFrame.BorderMask.height,13,"disable restores original effect clipping height")
equal(PlayerCastingBarFrame.Text.point[1],"TOP","disable restores original player text anchor")
equal(PlayerCastingBarFrame.Text.height,16,"disable restores original native label height")
bars:Set("target","enabled",false);bars:Set("focus","enabled",false)
equal(TargetFrame.spellbar.width,150,"target restoration keeps native dimensions")
equal(FocusFrame.spellbar.height,16,"focus restoration keeps native dimensions")
equal(FocusFrame.spellbar.Text.restoredFontObject,focusFont,"disable restores native font-object inheritance when available")
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
zone="Riverglades";rep.events.OnEvent(rep.events,"ZONE_CHANGED_NEW_AREA");Drain()
equal(watched,2826,"arriving in Riverglades selects Brotherhood without a reputation change")
zone="Les Clairieres";areas[16591]=zone
equal(rep:Desired(),2826,"Riverglades mapping uses the native localized area name")
areas[16591]="Riverglades";zone="Riverglades"
side="Horde";equal(rep:Desired(),2782,"Horde Riverglades selects Bolder'ok rather than Brotherhood");side="Alliance"
instance=true;equal(rep:Desired(),nil,"Riverglades mapping does not apply inside an instance");instance=false
watched=72;rep.events.OnEvent(rep.events,"UPDATE_FACTION");Drain()
equal(watched,72,"manual watch remains after the Riverglades arrival selection")
rep.events.OnEvent(rep.events,"PLAYER_ENTERING_WORLD");Drain()
equal(watched,2826,"world entry in Riverglades selects Brotherhood without questing")
zone="Elwynn";SetCombat(true);rep.events.OnEvent(rep.events,"ZONE_CHANGED_NEW_AREA")
zone="Riverglades";rep.events.OnEvent(rep.events,"ZONE_CHANGED_NEW_AREA")
watched=72
SetCombat(false);Suite.pending.zoneReputation();Suite.pending.zoneReputation=nil
equal(watched,2826,"combat recovery selects the final Riverglades zone without a standing event")
local regionalCases={
    {331,69,76},{406,69,76},{357,69,81},{267,72,68},{15,72,76},
    {4,72,nil},{46,72,nil},{47,471,nil},{3,nil,76},{8,nil,76},{400,nil,81},
    {16593,2779,2778},{28,529,529},{139,529,529},{51,59,59},
    {493,609,609},{1377,609,609},{440,369,369},{616,2765,2765},
}
for _,row in ipairs(regionalCases)do
    areas[row[1]]="Localized area "..row[1];zone=areas[row[1]];subzone=""
    for index,factionSide in ipairs({"Alliance","Horde"})do
        side=factionSide
        equal(rep:Desired(),row[index+1],"regional primary reputation: "..factionSide.." area "..row[1])
        if row[index+1] then
            watched=72;rep.events.OnEvent(rep.events,"ZONE_CHANGED_NEW_AREA");Drain()
            equal(watched,row[index+1],"region entry selects its primary faction without reputation events")
        end
    end
end
areas[16727]="Localized Powderfuse";areas[16631]="Localized Shadowgale"
for _,factionSide in ipairs({"Alliance","Horde"})do
    side=factionSide;zone="Riverglades";subzone=areas[16727]
    rep.events.OnEvent(rep.events,"ZONE_CHANGED");Drain()
    equal(watched,2827,"Powderfuse Port overrides either Riverglades primary faction")
    subzone="";rep.events.OnEvent(rep.events,"ZONE_CHANGED");Drain()
    equal(watched,factionSide=="Alliance" and 2826 or 2782,"leaving Powderfuse restores the regional primary faction")
    zone=areas[16593];subzone=areas[16631]
    equal(rep:Desired(),2758,"Shadowgale Forest selects Nightclaw Druids for either side")
end
for _,unmapped in ipairs({"Desolace","Felwood","Un'Goro Crater","Azshara","Winterspring","Shen'dralas"})do
    zone=unmapped;subzone=""
    equal(rep:Desired(),nil,"mixed or unestablished zones do not guess a primary faction")
end
side="Alliance";zone="Riverglades";subzone=""
equal(rep.events.registered.FACTION_STANDING_CHANGED,true,"tracking observes native faction IDs for Other factions")
zone="Riverglades";rep.events.OnEvent(rep.events,"ZONE_CHANGED");Drain()
local factionGetter=C_Reputation.GetFactionDataByID
-- Synthetic ID: the screenshot establishes the name, not the native faction ID.
C_Reputation.GetFactionDataByID=function(id)
    if id==9001 then return {name="Brotherhood of the Horse",isHeader=false,isHeaderWithRep=false} end
    if id==9002 then return {name="Other",isHeader=true,isHeaderWithRep=false} end
    if id==9003 then return {name="Restricted",isHeader={secret=true},isHeaderWithRep=false} end
    if id==9004 then return nil end
    return factionGetter(id)
end
C_Reputation.GetNumFactions=function()error("tracking must not enumerate visible reputation headers")end
C_Reputation.ExpandFactionHeader=function()error("tracking must not expand collapsed Other headers")end
rep.events.OnEvent(rep.events,"FACTION_STANDING_CHANGED",9001,3371);Drain()
equal(watched,9001,"Riverglades faction changes select Brotherhood beneath a collapsed Other header")
local beforeFeedback=writes
rep.events.OnEvent(rep.events,"UPDATE_FACTION");Drain()
equal(writes,beforeFeedback,"generic faction feedback does not repeat the write")
watched=47;rep.events.OnEvent(rep.events,"UPDATE_FACTION");Drain()
equal(watched,47,"manual choice survives generic faction updates after an Other faction change")
rep.events.OnEvent(rep.events,"FACTION_STANDING_CHANGED",9001,3372);Drain()
equal(watched,9001,"the next standing change resumes tracking even for the same faction")
zone="Elwynn";rep.events.OnEvent(rep.events,"ZONE_CHANGED");Drain()
equal(watched,72,"zone arrival clears the changed-faction override")
rep.events.OnEvent(rep.events,"FACTION_STANDING_CHANGED",9001,3373);Drain()
equal(watched,9001,"changed faction takes priority over a mapped city region")
for _,payload in ipairs({{0,1},{1.5,1},{2147483648,1},{{secret=true},1},{72,{secret=true}},{72,"100"}})do
    rep.events.OnEvent(rep.events,"FACTION_STANDING_CHANGED",payload[1],payload[2]);Drain()
    equal(watched,9001,"invalid or restricted event fields cannot change watched faction")
end
for _,id in ipairs({9002,9003,9004})do
    rep.events.OnEvent(rep.events,"FACTION_STANDING_CHANGED",id,1);Drain()
    equal(watched,9001,"plain headers, restricted flags and missing faction data cannot be selected")
end
instance=true;rep.events.OnEvent(rep.events,"FACTION_STANDING_CHANGED",47,10);Drain()
equal(watched,9001,"instance standing changes preserve the watched faction");instance=false
SetCombat(true)
rep.events.OnEvent(rep.events,"FACTION_STANDING_CHANGED",47,10)
rep.events.OnEvent(rep.events,"FACTION_STANDING_CHANGED",9001,3374)
equal(watched,9001,"combat events cannot write the native watch")
watched=72;SetCombat(false);Suite.pending.zoneReputation();Suite.pending.zoneReputation=nil
equal(watched,9001,"combat recovery uses the latest changed faction")
rep.events.OnEvent(rep.events,"FACTION_STANDING_CHANGED",47,11)
rep.events.OnEvent(rep.events,"FACTION_STANDING_CHANGED",9001,3375)
local beforeBurst=writes;Drain()
equal(writes,beforeBurst,"coalesced updates already watching the latest faction do not write")
rep.events.OnEvent(rep.events,"FACTION_STANDING_CHANGED",47,12)
Suite.db.zoneReputation=false;rep:Apply();local previous=writes;rep:Queue();Drain()
equal(writes,previous,"disabled reputation tracking stays inert")
equal(rep.changedFaction,nil,"disable forgets the last faction change")
equal(rep.events.registered.FACTION_STANDING_CHANGED,nil,"disable unregisters standing events")
rep.events.OnEvent(rep.events,"FACTION_STANDING_CHANGED",47,13);Drain()
equal(writes,previous,"stale standing callbacks cannot switch tracking after disable")
C_Reputation.GetFactionDataByID=factionGetter
equal(Suite.SettingsCatalog:Search("disenchant")[1].page,"professions","profession tools are searchable")
equal(Suite.SettingsCatalog:Search("castbar sizes")[1].page,"castbars","castbar controls are searchable")
local gui=Suite.GUI
gui:BuildCastbars()
local oldKey,oldMessage=gui.castbarKey,gui.castbarMessage
bars:Reset("target")
gui.castbarKey="target";gui:RefreshCastbars()
equal(gui.castbarEnable,nil,"castbar settings have no separate custom-size toggle")
equal(gui.castbarFields.height.input:GetText(),"15","native mode displays actual target height")
local heightField=gui.castbarFields.height
heightField.input.OnEditFocusLost(heightField.input)
equal(bars:Options("target").enabled,false,"leaving an untouched field keeps native sizing")
heightField.input:SetText("42");heightField.input.OnTextChanged(heightField.input,true)
equal(bars:Options("target").enabled,true,"typing a target dimension activates sizing")
equal(TargetFrame.spellbar.height,42,"typed target height applies immediately without Enter")
equal(heightField.slider.value,42,"live numeric input synchronizes its slider")
heightField.input:SetText("4");heightField.input.OnTextChanged(heightField.input,true)
equal(TargetFrame.spellbar.height,42,"partial out-of-range input does not clamp while typing")
heightField.input:SetText("31");heightField.input.OnTextChanged(heightField.input,false)
equal(TargetFrame.spellbar.height,42,"programmatic field refresh does not apply dimensions")
heightField.input.OnEditFocusLost(heightField.input)
equal(TargetFrame.spellbar.height,31,"leaving the size field commits its valid number")
gui.castbarReset.OnClick()
equal(TargetFrame.spellbar.height,15,"Reset restores the native target height")
equal(TargetFrame.spellbar.width,150,"Reset restores the native target width")
equal(Suite.db.castbars.target.height,nil,"Reset clears obsolete custom dimensions")
equal(gui.castbarFields.height.input:GetText(),"15","Reset refreshes controls with native dimensions")
heightField.input.OnEditFocusLost(heightField.input)
equal(bars:Options("target").enabled,false,"late focus loss cannot reactivate a reset bar")
gui.castbarKey="focus";bars:Reset("focus");gui:RefreshCastbars()
gui.castbarFields.width.slider.OnValueChanged(gui.castbarFields.width.slider,275)
equal(FocusFrame.spellbar.width,275,"slider edits apply focus sizing without a toggle")
equal(FocusFrame.spellbar.height,16,"first width edit preserves the actual native height")
SetCombat(true)
heightField.input:SetText("44");heightField.input.OnTextChanged(heightField.input,true)
gui.castbarReset.OnClick()
equal(FocusFrame.spellbar.width,275,"combat callbacks cannot reset native geometry")
equal(bars:Options("focus").height,16,"combat callbacks cannot change saved dimensions")
SetCombat(false)
gui.castbarReset.OnClick()
equal(FocusFrame.spellbar.width,160,"focus Reset restores its own native width")
bars:Set("player","width",320);bars:Set("player","height",28)
equal(bars:SetMatch("target","player"),true,"target can follow player sizing")
equal(bars:SetMatch("focus","player"),true,"focus can follow player sizing")
equal(TargetFrame.spellbar.width,320,"matching applies the source width immediately")
equal(FocusFrame.spellbar.height,28,"matching applies the source height immediately")
bars:Set("player","width",365)
equal(TargetFrame.spellbar.width,365,"target follows subsequent source edits")
equal(FocusFrame.spellbar.width,365,"focus follows subsequent source edits")
equal(bars:SetMatch("player","target"),false,"direct matching cycles are rejected")
equal(bars:SetMatch("focus","target"),true,"matching chains are supported")
equal(bars:SetMatch("player","focus"),false,"indirect matching cycles are rejected")
equal(bars:SetMatch("player","player"),false,"a bar cannot match itself")
local savedCastbars=Suite.Copy(Suite.db.castbars)
Suite.db.castbars=Suite.Copy(savedCastbars);bars:Apply()
equal(bars:Options("focus").match,"target","saved matching choices survive a settings round trip")
bars:Set("target","height",34)
equal(bars:Options("target").match,"manual","manual dimension editing detaches the selected bar")
equal(TargetFrame.spellbar.width,365,"manual edit retains the other matched dimension")
equal(FocusFrame.spellbar.height,34,"followers track a source that switches to manual")
equal(PlayerCastingBarFrame.height,28,"manual follower edits leave its former source unchanged")
bars:Reset("target")
equal(bars:Options("target").match,"manual","Reset clears the selected match link")
equal(FocusFrame.spellbar.width,150,"followers track a reset source's native width")
TargetFrame.spellbar:SetSize(175,18);Drain()
equal(FocusFrame.spellbar.width,175,"native source size changes refresh followers")
equal(FocusFrame.spellbar.height,18,"native source height changes refresh followers")
local nativeWidth=TargetFrame.spellbar.GetWidth
TargetFrame.spellbar.GetWidth=function()return {secret=true}end
bars:Refresh()
equal(FocusFrame.spellbar.width,160,"unavailable source dimensions restore follower native geometry")
equal(bars:SizeStatus("focus"),"The source castbar's native size is unavailable.","unavailable source is disclosed")
TargetFrame.spellbar.GetWidth=nativeWidth;bars:Refresh()
equal(FocusFrame.spellbar.width,175,"matching recovers when source metadata is readable")
Suite.db.castbars.target={enabled=true,match="focus"};bars:Refresh()
equal(bars:ResolvedOptions("focus"),nil,"malformed saved cycles terminate without guessing dimensions")
bars:Reset("target");bars:SetMatch("focus","player")
SetCombat(true);bars:Set("player","height",32)
equal(FocusFrame.spellbar.height,28,"source changes defer follower geometry in combat")
equal(bars:SetMatch("target","player"),false,"matching menu writes are rejected in combat")
SetCombat(false);Suite.pending.castbars();Suite.pending.castbars=nil
equal(FocusFrame.spellbar.height,32,"deferred source changes update followers after combat")
gui.page="castbars";gui.frame:Show();gui.castbarKey="target";gui:RefreshCastbars()
local menu, choices=MenuUtil,{}
MenuUtil={CreateContextMenu=function(_,generate)
    generate(nil,{CreateRadio=function(_,label,selected,callback) choices[label]=callback end})
end}
gui.castbarMatch.OnClick()
equal(choices.Target,nil,"matching dropdown excludes the selected bar")
equal(type(choices.Player),"function","target dropdown offers Player")
equal(type(choices.Focus),"function","target dropdown offers Focus")
gui.castbarKey="focus";choices.Player()
equal(bars:Options("target").match,"manual","stale menus cannot change the previously selected bar")
gui.castbarKey="target";gui.castbarMatch.OnClick();choices.Player()
equal(bars:Options("target").match,"player","matching dropdown saves the explicit selection")
gui:RefreshCastbars()
equal(bars:Options("target").match,"player","refreshing matched sliders does not detach sizing")
gui.castbarFields.width.slider.OnValueChanged(gui.castbarFields.width.slider,350)
equal(bars:Options("target").match,"manual","moving a matched slider switches its choice to Manual")
equal(gui.castbarMatch.label.text,"Match size to: Manual","slider edits immediately update the matching dropdown label")
equal(TargetFrame.spellbar.height,32,"slider edits preserve the other matched dimension")
bars:Set("player","width",390)
equal(TargetFrame.spellbar.width,350,"detached slider size stops following source changes")
gui.castbarMatch.OnClick();choices.Player()
gui.castbarFields.height.input:SetText("38");gui.castbarFields.height.input.OnTextChanged(gui.castbarFields.height.input,true)
equal(bars:Options("target").match,"manual","typing a matched size switches its choice to Manual")
equal(gui.castbarMatch.label.text,"Match size to: Manual","live typed edits immediately update the matching label")
gui.castbarMatch.OnClick();choices.Player()
gui.castbarMatch.OnClick();choices.Manual()
equal(bars:Options("target").match,"manual","Manual detaches without resetting the copied size")
equal(TargetFrame.spellbar.width,390,"Manual retains the current matched dimensions")
MenuUtil=menu
gui.castbarKey,gui.castbarMessage=oldKey,oldMessage;gui:RefreshCastbars()
for _,module in ipairs({helper,bars,rep}) do
    if module.timer then module.timer:Cancel() end
    for key in pairs(module)do module[key]=nil end;for key,value in pairs(states[module])do module[key]=value end
end
for _,name in ipairs(names)do _G[name]=old[name]end
Suite.db,Suite.pending=oldDB,oldPending;SetCombat(false)
