local _,Suite=...
local View={page=1,spellPage=1,filter="mine",controls={}}
Suite.BuffSettings=View
local GUI,Buffs=Suite.GUI,Suite.MissingBuffs
local classLabels={MAGE="Mage",PRIEST="Priest",WARLOCK="Warlock",DRUID="Druid",HUNTER="Hunter",
    PALADIN="Paladin",SHAMAN="Shaman",ROGUE="Rogue",WARRIOR="Warrior"}
local colors={text={0.88,0.91,0.93},muted={0.55,0.65,0.7},teal={0.41,0.84,0.75},gold={0.9,0.72,0.4}}
local function Text(value) return Suite.IsReadable(value) and type(value)=="string" end
local function Label(parent,text,x,y,width,size,color)
    local f=parent:CreateFontString(nil,"OVERLAY");f:SetFont("Fonts\\FRIZQT__.TTF",size or 11,"")
    f:SetPoint("TOPLEFT",x,y);f:SetWidth(width);f:SetJustifyH("LEFT");f:SetWordWrap(true)
    f:SetTextColor(unpack(color or colors.text));f:SetText(text);return f
end
local function Button(parent,text,x,y,width,callback)
    local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
    Suite.Theme:ButtonFeedback(b)
    b:SetPoint("TOPLEFT",x,y);b:SetSize(width,28)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    b:SetBackdropColor(0.07,0.095,0.11,1);Suite.Theme:Backdrop(b, 1)
    b.label=Label(b,text,9,-8,width-18,11,colors.teal);b.label:SetWordWrap(false)
    local enable=b.SetEnabled
    b.SetEnabled=function(self,enabled) enable(self,enabled);self.label:SetTextColor(unpack(enabled and colors.teal or colors.muted)) end
    b:SetScript("OnClick",function() if not InCombatLockdown() then callback() end end)
    b:SetScript("OnEnter",function() b:SetBackdropColor(0.09,0.13,0.145,1) end)
    b:SetScript("OnLeave",function() b:SetBackdropColor(0.07,0.095,0.11,1) end)
    View.controls[#View.controls+1]=b;return b
end
local function Input(parent,x,y,width,callback)
    local f=CreateFrame("EditBox",nil,parent,"BackdropTemplate")
    f:SetPoint("TOPLEFT",x,y);f:SetSize(width,28);f:SetAutoFocus(false);f:SetMaxLetters(80)
    f:SetFont("Fonts\\FRIZQT__.TTF",12,"");f:SetTextInsets(8,8,0,0)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:SetBackdropColor(0.035,0.05,0.065,1);Suite.Theme:Backdrop(f, 1)
    f:SetScript("OnTextChanged",function()
        if f.hint then f.hint:SetShown(f:GetText()=="") end
        if not InCombatLockdown() then callback(f:GetText()) end
    end)
    f:SetScript("OnEnterPressed",function() f:ClearFocus() end)
    f:SetScript("OnEscapePressed",function() f:ClearFocus() end)
    View.controls[#View.controls+1]=f
    return f
end
local function Check(parent,text,x,y,width,callback)
    local b=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate")
    b:SetPoint("TOPLEFT",x,y);b:SetSize(24,24)
    b.label=Label(b,text,28,-6,width-28,11);b.label:SetWordWrap(false)
    b:SetHitRectInsets(0,-(width-24),0,0)
    b:SetScript("OnClick",function() if not InCombatLockdown() then callback() end end)
    View.controls[#View.controls+1]=b;return b
end
local function Icon(parent,x,y)
    local icon=parent:CreateTexture(nil,"ARTWORK");icon:SetSize(26,26);icon:SetPoint("TOPLEFT",x,y);return icon
end
local function Slider(parent,x,y,width,low,high,callback)
    local slider=CreateFrame("Slider",nil,parent)
    slider:SetPoint("TOPLEFT",x,y);slider:SetSize(width,20);slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(low,high);slider:SetValueStep(1);slider:SetObeyStepOnDrag(true);slider:EnableMouse(true)
    slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    slider:GetThumbTexture():SetSize(10,18);slider:GetThumbTexture():SetColorTexture(unpack(colors.teal))
    local track=slider:CreateTexture(nil,"BACKGROUND");track:SetHeight(4)
    track:SetPoint("LEFT",5,0);track:SetPoint("RIGHT",-5,0);track:SetColorTexture(0.17,0.25,0.29,1)
    slider.label=Label(slider,"",0,22,width,11,colors.teal)
    Label(slider,tostring(low),0,-24,60,9,colors.muted)
    Label(slider,tostring(high),width-40,-24,40,9,colors.muted)
    slider:SetScript("OnValueChanged",function(_,value)
        if View.syncing or InCombatLockdown() or not Suite.IsReadable(value) or type(value)~="number"
            or value~=value or math.abs(value)==math.huge then return end
        callback(math.max(low,math.min(high,math.floor(value+0.5))))
    end)
    slider:SetScript("OnMouseDown",function() if not InCombatLockdown() then View.sliding=true end end)
    slider:SetScript("OnMouseUp",function() View.sliding=nil;Buffs:Queue() end)
    slider:SetScript("OnHide",function()
        if View.sliding then View.sliding=nil;Buffs:Queue() end
    end)
    View.controls[#View.controls+1]=slider
    return slider
end
function View:Cancel()
    self.work=nil
    if self.timer then self.timer:Cancel();self.timer=nil end
end
function View:Queue()
    if not self.mode or GUI.page~="buffs" or not GUI.frame or not GUI.frame:IsShown() or InCombatLockdown() or self.timer then return end
    if not C_Timer or type(C_Timer.NewTimer)~="function" then self:Refresh();return end
    local work={};self.work=work
    self.timer=C_Timer.NewTimer(0.1,function()
        if self.work~=work then return end
        self.timer,self.work=nil,nil
        if self.mode and GUI.page=="buffs" and GUI.frame:IsShown() then self:Refresh() end
    end)
end
function View:Dismiss()
    self:Cancel()
    local sliding=self.sliding
    self.sliding=nil
    if sliding then Buffs:Queue() end
    if Suite.CombatBuffs then Suite.CombatBuffs:SetPreview(false) end
    Buffs:SetPreview(false)
    self.mode,self.message=nil,nil;Suite.pending.buffManager=nil
    if self.panel then self.panel:Hide();self.search:ClearFocus();self.choiceSearch:ClearFocus() end
end
function View:Open(mode)
    if InCombatLockdown() then
        Suite.AfterCombat("buffManager",function() if GUI.page=="buffs" and GUI.frame and GUI.frame:IsShown() then self:Open(mode) end end)
        return
    end
    self.cachedLearned=nil
    self.mode,self.message=mode or "choices",nil
    if mode=="display" then self.appearanceOpen=true end
    if mode=="visibility" or mode=="spells" then self.advancedOpen=true end
    GUI:OpenPage("buffs");self:Build();self:Refresh();GUI:Select("buffs")
    local target=mode=="display" and self.display or mode=="visibility" and self.visibility or mode=="spells" and self.spells or self.choices
    local _,offset=Suite.SettingsCatalog:Target(GUI,{owner="BuffSettings",target=mode=="display" and "display" or mode=="visibility" and "visibility" or mode=="spells" and "spells" or "choices"})
    if target then GUI:ScrollTo(offset or 0) end
end
function View:Changed()
    Buffs.bookDirty=true;Buffs:Queue();self:Refresh()
end
function View:Reveal(target)
    if InCombatLockdown() then return end
    local advanced={rested=true,campfire=true,warning=true,spells=true,
        ["settings.missingBuffIncoming"]=true,["settings.missingBuffSmart"]=true,["settings.missingBuffWeapons"]=true}
    if advanced[target] then self.advancedOpen=true end
    if target=="display" or target=="scale" or target=="size" or target=="normalPreview" or target=="resetPosition" then self.appearanceOpen=true end
    self:Refresh()
end
function View:Display(key,value)
    if InCombatLockdown() then return end
    Suite.db[key]=value
    if Buffs.bar then Buffs:Place(Buffs.bar) end
    if Buffs.preview then Buffs:Place(Buffs.preview) end
    if Buffs.preview and Buffs.preview:IsShown() then Buffs:SetPreview(true) end
    if Suite.CombatBuffs then Suite.CombatBuffs:UpdatePreview() end
    Suite.BuffReminders:PlaceCombat();Buffs:Queue();self:Refresh()
end
function View:Build()
    if self.panel or InCombatLockdown() then return end
    local panel=CreateFrame("Frame",nil,GUI.content);panel:SetSize(780,340);self.panel,GUI.buffPanel=panel,panel
    self.status=Label(panel,"",0,0,780,11,colors.gold);self.status:SetHeight(30)
    self.settings={}
    local general=CreateFrame("Frame",nil,panel);self.general=general
    general:SetPoint("TOPLEFT",0,-32);general:SetSize(780,168)
    local function Setting(parent,key,label,x,y,inverted)
        local control=Check(parent,label,x,y,380,function()
            Suite.Set(key,not Suite.db[key]);self:Refresh()
        end)
        control.settingKey,control.inverted=key,inverted;self.settings[key]=control
        return control
    end
    Setting(general,"missingBuffs","Enable buff reminders",0,0)
    Label(general,"When to show reminders",0,-38,780,13,colors.teal)
    Setting(general,"missingBuffCombat","Also show during combat",0,-64)
    Setting(general,"missingBuffExpiry","Warn before buffs expire",396,-64)
    Setting(general,"missingBuffSelf","My buffs",0,-100)
    Setting(general,"missingBuffOutgoing","Party / raid buffs I can cast",396,-100)
    Setting(general,"missingBuffClass","Self upkeep (armor, shields, tracking)",0,-136)
    self.appearanceToggle=Button(panel,"Appearance",0,0,780,function()
        self.appearanceOpen=not self.appearanceOpen
        if not self.appearanceOpen then Buffs:SetPreview(false);if Suite.CombatBuffs then Suite.CombatBuffs:SetPreview(false) end end
        self:Refresh()
    end)
    self.advancedToggle=Button(panel,"Advanced",0,0,780,function()
        self.advancedOpen=not self.advancedOpen;if not self.advancedOpen then self.search:ClearFocus() end;self:Refresh()
    end)
    local display=CreateFrame("Frame",nil,panel);self.display=display
    display:SetPoint("TOPLEFT",0,-40);display:SetSize(780,264)
    Label(display,"Make the reminders comfortable to read.",0,0,780,14,colors.teal)
    Label(display,"Normal and combat icons share these size and scale settings.\nPreviews are visual only; combat reminders are refreshed from your action bar.",0,-30,780,11,colors.muted)
    self.scale=Slider(display,0,-108,252,70,150,function(value) self:Display("missingBuffScale",value/100) end)
    self.size=Slider(display,264,-108,252,24,64,function(value) self:Display("missingBuffIconSize",value) end)
    local visibility=CreateFrame("Frame",nil,panel);self.visibility=visibility
    visibility:SetPoint("TOPLEFT",0,-40);visibility:SetSize(780,214)
    Setting(visibility,"missingBuffIncoming","Buffs my group can give me",0,0)
    Setting(visibility,"missingBuffSmart","Match buffs to recipient classes",396,0)
    Setting(visibility,"missingBuffWeapons","Weapon coating reminders",0,-36)
    self.rested=Setting(visibility,"missingBuffRested","Hide normal reminders in rested areas",0,-72,true)
    self.campfire=Setting(visibility,"missingBuffCampfire","Hide normal reminders near a campfire",396,-72)
    self.warning=CreateFrame("Frame",nil,visibility);self.warning:SetPoint("TOPLEFT",0,-114);self.warning:SetSize(780,68)
    Label(self.warning,"Long-buff and coating warning",0,0,780,11,colors.muted)
    self.warningChoices={}
    for i,seconds in ipairs({30,60,120}) do
        self.warningChoices[i]=Check(self.warning,seconds.." seconds",(i-1)*180,-26,170,function() self:Display("missingBuffWarning",seconds) end)
        self.warningChoices[i].seconds=seconds
    end
    Label(visibility,"Short buffs warn at 15 seconds. Battle Shout and Commanding Shout appear only in combat.",0,-190,780,11,colors.muted)
    self.normalPreview=Button(display,"Preview normal bar",0,-176,252,function()
        Buffs:SetPreview(not (Buffs.preview and Buffs.preview:IsShown()));self:Refresh()
    end)
    self.combatPreview=Button(display,"Preview combat icons",264,-176,252,function()
        if Suite.CombatBuffs then Suite.CombatBuffs:SetPreview(not Suite.CombatBuffs.previewActive) end;self:Refresh()
    end)
    Button(display,"Reset appearance",528,-176,252,function()
        self:Display("missingBuffScale",1);self:Display("missingBuffIconSize",34)
    end)
    Label(display,"Drag the normal preview header to move both versions. Previews stop when you leave these controls or enter combat.",0,-220,516,11,colors.muted)
    self.resetPosition=Button(display,"Reset position",528,-220,252,function() Buffs:ResetPosition() end)
    local choices=CreateFrame("Frame",nil,panel);self.choices=choices
    choices:SetPoint("TOPLEFT",0,-40);choices:SetSize(780,490)
    Label(choices,"Buffs to track",0,0,780,14,colors.teal)
    self.choiceSearch=Input(choices,0,-34,384,function(value) self.choiceQuery=value;self.page=1;self:Refresh() end)
    self.choiceSearch.hint=Label(self.choiceSearch,"Search by spell or class",8,-7,368,11,colors.muted)
    self.filters={}
    for i,option in ipairs({{"mine","My class"},{"all","All classes"},{"hidden","Hidden"}}) do
        self.filters[option[1]]=Button(choices,option[2],396+(i-1)*130,-34,124,function() self.filter=option[1];self.page=1;self:Refresh() end)
    end
    self.choiceFilter=self.filters.all
    self.choiceEmpty=Label(choices,"",0,-82,780,11,colors.muted)
    self.choiceRows={}
    for i=1,8 do
        local row=CreateFrame("Frame",nil,choices);row:SetPoint("TOPLEFT",0,-80-(i-1)*44);row:SetSize(780,40)
        row.icon=Icon(row,0,-2);row.label=Label(row,"",36,-2,360,11);row.detail=Label(row,"",36,-20,360,10,colors.muted)
        row.label:SetWordWrap(false);row.detail:SetWordWrap(false)
        row.visible=Check(row,"Track",410,0,170,function()
            local record=row.record;if not record then return end
            if Suite.db.missingBuffChoices[record.key]==0 then Suite.db.missingBuffChoices[record.key]=nil
            else Suite.db.missingBuffChoices[record.key]=0 end
            self:Changed()
        end)
        row.alternative=Button(row,"Choose buff",592,0,188,function()
            local record=row.record;if not record then return end
            if not MenuUtil or type(MenuUtil.CreateContextMenu)~="function" then self.message="Buff selection is unavailable on this client.";self:Refresh();return end
            MenuUtil.CreateContextMenu(row.alternative,function(_,root)
                local function Option(name,id)
                    root:CreateRadio(name,function() return Suite.db.missingBuffChoices[record.key]==id end,function()
                        if InCombatLockdown() or not self.mode or GUI.page~="buffs" or not GUI.frame:IsShown() or row.record~=record then return end
                        Suite.db.missingBuffChoices[record.key]=id;self:Changed()
                    end)
                end
                Option("Automatic",nil)
                for _,spell in ipairs(record.family.choices) do Option(spell.name,spell.id) end
            end)
        end)
        self.choiceRows[i]=row
    end
    self.choicePrev=Button(choices,"Previous",0,-442,160,function() self.page=math.max(1,self.page-1);self:Refresh() end)
    self.choiceNext=Button(choices,"Next",172,-442,160,function() self.page=self.page+1;self:Refresh() end)
    self.choiceCount=Label(choices,"",356,-450,424,11,colors.muted)
    local spells=CreateFrame("Frame",nil,panel);self.spells=spells
    spells:SetPoint("TOPLEFT",0,-80);spells:SetSize(780,650)
    Label(spells,"Choose a learned spell by name or icon.",0,0,780,14,colors.teal)
    Label(spells,"Choose a buff you can cast; adding a reminder never casts it. Combat reminders use your combat setting.",0,-28,780,11,colors.muted)
    self.search=Input(spells,0,-60,580,function(value) self.query=value;self.spellPage=1;self:Refresh() end)
    self.search.hint=Label(self.search,"Search your learned spells",8,-7,564,11,colors.muted)
    Button(spells,"Clear search",592,-60,188,function() self.query="";self.search:SetText("");self.spellPage=1;self:Refresh() end)
    self.spellEmpty=Label(spells,"",0,-108,780,11,colors.muted)
    self.results={}
    for i=1,5 do
        local row=CreateFrame("Frame",nil,spells);row:SetPoint("TOPLEFT",0,-106-(i-1)*36);row:SetSize(780,32)
        row.icon=Icon(row,0,0);row.label=Label(row,"",36,-7,540,11);row.label:SetWordWrap(false)
        row.add=Button(row,"Add reminder",592,0,188,function()
            if not row.spell then return end
            if row.builtIn then
                self.mode="choices";self.filter="all";self.choiceQuery=row.spell.name;self.page=1
                self.choiceSearch:SetText(row.spell.name);GUI:Select("buffs");self:Refresh()
                local _,offset=Suite.SettingsCatalog:Target(GUI,{owner="BuffSettings",target="choices"});GUI:ScrollTo(offset or 0);return
            end
            local ok=Suite.BuffReminders:AddCustom(tostring(row.spell.id),false)
            self.message=ok and "Reminder added. Choose Self or Party / raid below." or "Already saved, or all eight custom slots are in use."
            self:Changed()
        end)
        self.results[i]=row
    end
    self.spellPrev=Button(spells,"Previous",0,-300,160,function() self.spellPage=math.max(1,self.spellPage-1);self:Refresh() end)
    self.spellNext=Button(spells,"Next",172,-300,160,function() self.spellPage=self.spellPage+1;self:Refresh() end)
    self.spellCount=Label(spells,"",356,-308,424,11,colors.muted)
    self.savedTitle=Label(spells,"",0,-352,780,12,colors.teal);self.saved={}
    self.savedEmpty=Label(spells,"No custom reminders yet. Built-in class reminders work without adding anything here.",0,-384,780,11,colors.muted)
    for i=1,8 do
        local row=CreateFrame("Frame",nil,spells);row:SetPoint("TOPLEFT",((i-1)%2)*396,-384-math.floor((i-1)/2)*60);row:SetSize(384,54)
        row.icon=Icon(row,0,0);row.label=Label(row,"",34,-3,350,11);row.label:SetWordWrap(false)
        row.scope=Button(row,"",34,-25,166,function()
            local record=Suite.db.missingBuffCustom[i];if record then record.group=not record.group;self:Changed() end
        end)
        row.remove=Button(row,"Remove",212,-25,172,function()
            local record=Suite.db.missingBuffCustom[i]
            if record then Suite.db.missingBuffChoices["CUSTOM:"..record.id]=nil;table.remove(Suite.db.missingBuffCustom,i);self:Changed() end
        end)
        self.saved[i]=row
    end
    for _,event in ipairs({"SPELLS_CHANGED","SPELL_DATA_LOAD_RESULT","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED"}) do
        pcall(panel.RegisterEvent,panel,event)
    end
    panel:SetScript("OnEvent",function(_,event)
        if event=="SPELLS_CHANGED" or event=="SPELL_DATA_LOAD_RESULT" then self.cachedLearned=nil;self:Queue()
        elseif self.mode and GUI.page=="buffs" and GUI.frame and GUI.frame:IsShown() then
            self:Cancel();self:Refresh()
        end
    end)
end
function View:Learned()
    if self.cachedLearned then return self.cachedLearned.list,self.cachedLearned.book,self.cachedLearned.complete end
    local book,complete=Buffs:Learned();local list={}
    for _,spell in pairs(book) do list[#list+1]=spell end
    table.sort(list,function(a,b) if a.name==b.name then return a.id<b.id end;return a.name<b.name end)
    self.cachedLearned={list=list,book=book,complete=complete}
    return list,book,complete
end
function View:FamilyRows(book)
    local rows,class={},nil
    if type(UnitClass)=="function" then local ok,_,token=pcall(UnitClass,"player");if ok and Text(token) then class=token end end
    local byKey={}
    local classes={};for _,catalog in ipairs(Suite.BuffCatalog) do classes[catalog.class]=true end
    for token in pairs(classes) do for _,family in ipairs(Buffs:Families(token,token==class and book or {})) do byKey[family.key]=family end end
    for _,catalog in ipairs(Suite.BuffCatalog) do
        local key=catalog.class..":"..catalog.key;local family=byKey[key]
        local spell=Buffs:Spell(catalog.roots[1]);local name=spell and spell.name or (classLabels[catalog.class] or "Class").." buff (loading)"
        local haystack=name.." "..catalog.class.." "..catalog.key
        if family then for alternative in pairs(family.names) do haystack=haystack.." "..alternative end end
        local hidden=Suite.db.missingBuffChoices[key]==0
        local query=Text(self.choiceQuery) and self.choiceQuery:lower() or ""
        if family and (self.filter~="hidden" or hidden) and (self.filter~="mine" or catalog.class==class)
            and haystack:lower():find(query,1,true) then
            rows[#rows+1]={key=key,name=name,icon=spell and spell.icon or 134400,hidden=hidden,family=family,class=catalog.class,mine=catalog.class==class}
        end
    end
    for _,family in ipairs(Buffs:TrackingFamilies(book)) do
        local spell=family.choices[1]
        local hidden=Suite.db.missingBuffChoices[family.key]==0
        if (self.filter~="hidden" or hidden) and spell.name:lower():find((self.choiceQuery or ""):lower(),1,true) then
            rows[#rows+1]={key=family.key,name=spell.name,icon=spell.icon,hidden=hidden,
                family=family,class="Tracking",mine=true}
        end
    end
    for _,record in ipairs(Suite.db.missingBuffCustom) do
        local key="CUSTOM:"..record.id;local spell=Buffs:Spell(record.id)
        if spell and (self.filter~="hidden" or Suite.db.missingBuffChoices[key]==0)
            and spell.name:lower():find((self.choiceQuery or ""):lower(),1,true) then
            rows[#rows+1]={key=key,name=spell.name,icon=spell.icon,hidden=Suite.db.missingBuffChoices[key]==0,
                family={choices={}},class="Custom"}
        end
    end
    table.sort(rows,function(a,b)
        if (a.mine==true)~=(b.mine==true) then return a.mine==true end
        if a.name~=b.name then return a.name<b.name end
        return a.key<b.key
    end)
    return rows
end
function View:Refresh()
    if not self.panel or not self.mode then return end
    local ready=not InCombatLockdown()
    for _,control in ipairs(self.controls) do control:SetEnabled(ready) end
    self.status:SetText(not ready and "Controls are available after combat." or self.message
        or not Suite.db.missingBuffs and "Reminders are off. Your buff selections are kept."
        or not Suite.db.missingBuffCombat and "Combat reminders are off. Only normal reminders will appear."
        or "Checked buffs are tracked. Uncheck a buff to hide its reminder.")
    if not ready then
        self.sliding=nil;Buffs:SetPreview(false)
        return
    end
    if not self.appearanceOpen then Buffs:SetPreview(false) end
    self.search.hint:SetShown(not self.query or self.query=="")
    self.choiceSearch.hint:SetShown(not self.choiceQuery or self.choiceQuery=="")
    local scale,size=Buffs:DisplayOptions()
    self.scale.label:SetText("Bar scale: "..math.floor(scale*100+0.5).."%")
    self.size.label:SetText("Icon size: "..size.." px")
    self.syncing=true;self.scale:SetValue(math.floor(scale*100+0.5));self.size:SetValue(size);self.syncing=nil
    self.normalPreview.label:SetText(Buffs.preview and Buffs.preview:IsShown() and "Stop normal preview" or "Preview normal bar")
    self.combatPreview.label:SetText(Suite.CombatBuffs and Suite.CombatBuffs.previewActive and "Stop combat preview" or "Preview combat icons")
    for key,control in pairs(self.settings) do
        control:SetChecked(control.inverted and not Suite.db[key] or not control.inverted and Suite.db[key]==true)
    end
    for _,control in ipairs(self.warningChoices) do control:SetChecked(Suite.db.missingBuffWarning==control.seconds) end
    self.display:SetShown(self.appearanceOpen==true);self.choices:Show()
    self.spells:SetShown(self.advancedOpen==true)
    self.visibility:SetShown(self.advancedOpen==true)
    do
        local learned,book,complete=self:Learned()
        if not complete then self.status:SetText("Some learned spell information is unavailable. The list will update when it arrives.") end
        do
            local records=self:FamilyRows(book);self.page=math.max(1,math.min(self.page,math.max(1,math.ceil(#records/8))))
            for key,button in pairs(self.filters) do Suite.Theme:Backdrop(button,key==self.filter and 1 or 0.35) end
            for i,row in ipairs(self.choiceRows) do
                local record=records[(self.page-1)*8+i];row.record=record;row:SetShown(record~=nil)
                if record then
                    row.icon:SetTexture(record.icon);row.label:SetText(record.name)
                    local catalog=record.family.catalog
                    local reason="Tracked"
                    if record.mine and catalog then
                        if not record.family.spell then reason="Not learned"
                        elseif (not catalog.group or catalog.upkeep) and not Suite.db.missingBuffClass then reason="Self upkeep is off"
                        elseif catalog.group and not catalog.upkeep and not Suite.db.missingBuffSelf then
                            reason=Suite.db.missingBuffOutgoing and "Party / raid only" or "My buffs and party / raid are off"
                        elseif catalog.combatOnly then reason="Combat only"
                        elseif catalog.outOfCombatOnly then reason="Out of combat only" end
                    end
                    if catalog and catalog.combatOnly and not Suite.db.missingBuffCombat then reason="Combat reminders off" end
                    if not Suite.db.missingBuffs then reason="Reminders off" end
                    if record.hidden then reason="Hidden" end
                    row.detail:SetText(reason.." / "..(classLabels[record.class] or record.class))
                    row.visible:SetChecked(not record.hidden);row.visible.label:SetText("Track")
                    row.alternative.label:SetText(record.family.spell and record.family.spell.name or "Automatic")
                    row.alternative:SetShown(#record.family.choices>1)
                    row.alternative:SetEnabled(not record.hidden)
                end
            end
            self.choiceEmpty:SetShown(#records==0)
            self.choiceEmpty:SetText(self.filter=="hidden" and "No hidden buffs match." or "No buffs match. Try another name or select All classes.")
            local visible=math.min(8,math.max(1,#records-(self.page-1)*8))
            local nav=80+visible*44+10
            self.choicePrev:ClearAllPoints();self.choicePrev:SetPoint("TOPLEFT",0,-nav)
            self.choiceNext:ClearAllPoints();self.choiceNext:SetPoint("TOPLEFT",172,-nav)
            self.choiceCount:ClearAllPoints();self.choiceCount:SetPoint("TOPLEFT",356,-nav-8)
            self.choiceHeight=nav+48;self.choices:SetHeight(self.choiceHeight)
            self.choicePrev:SetEnabled(self.page>1);self.choiceNext:SetEnabled(self.page*8<#records)
            local paged=#records>8
            self.choicePrev:SetShown(paged);self.choiceNext:SetShown(paged)
            self.choiceCount:SetShown(paged)
            self.choiceCount:SetText(paged and #records.." buffs / Page "..self.page or #records.." buffs")
            if not paged then self.choiceHeight=nav;self.choices:SetHeight(self.choiceHeight);self.choiceCount:Hide() end
        end
        if self.advancedOpen then
            local list,existing,builtIn,existingNames={},{},{},{}
            for _,catalog in ipairs(Suite.BuffCatalog) do for _,id in ipairs(catalog.roots) do
                local spell=Buffs:Spell(id);if spell then builtIn[spell.name]=true end
            end end
            for _,record in ipairs(Suite.db.missingBuffCustom) do
                existing[record.id]=true
                local spell=Buffs:Spell(record.id);if spell then existingNames[spell.name]=true end
            end
            local query=Text(self.query) and self.query:lower() or ""
            for _,spell in ipairs(learned) do if spell.name:lower():find(query,1,true) or tostring(spell.id)==query then list[#list+1]=spell end end
            self.spellPage=math.max(1,math.min(self.spellPage,math.max(1,math.ceil(#list/5))))
            for i,row in ipairs(self.results) do
                local spell=list[(self.spellPage-1)*5+i];row.spell=spell;row:SetShown(spell~=nil)
                if spell then
                    row.icon:SetTexture(spell.icon);row.label:SetText(spell.name)
                    row.builtIn=builtIn[spell.name]
                    row.add.label:SetText(builtIn[spell.name] and "Manage built-in" or (existing[spell.id] or existingNames[spell.name]) and "Already added" or "Add reminder")
                    row.add:SetEnabled(builtIn[spell.name] or not existing[spell.id] and not existingNames[spell.name] and #Suite.db.missingBuffCustom<8)
                end
            end
            self.spellEmpty:SetShown(#list==0)
            self.spellEmpty:SetText(complete and "No learned spells match. Try another name or clear the search." or "Learned spells are loading. Available spells will appear here.")
            local visible=math.min(5,math.max(1,#list-(self.spellPage-1)*5))
            local nav=106+visible*36+14
            self.spellPrev:ClearAllPoints();self.spellPrev:SetPoint("TOPLEFT",0,-nav)
            self.spellNext:ClearAllPoints();self.spellNext:SetPoint("TOPLEFT",172,-nav)
            self.spellCount:ClearAllPoints();self.spellCount:SetPoint("TOPLEFT",356,-nav-8)
            self.savedTitle:ClearAllPoints();self.savedTitle:SetPoint("TOPLEFT",0,-nav-52)
            local start=nav+84
            for i,row in ipairs(self.saved) do row:ClearAllPoints();row:SetPoint("TOPLEFT",((i-1)%2)*396,-start-math.floor((i-1)/2)*60) end
            self.savedEmpty:SetShown(#Suite.db.missingBuffCustom==0)
            self.savedEmpty:ClearAllPoints();self.savedEmpty:SetPoint("TOPLEFT",0,-start)
            self.spellsHeight=start+math.max(1,math.ceil(#Suite.db.missingBuffCustom/2))*60+22
            self.spells:SetHeight(self.spellsHeight)
            self.spellPrev:SetEnabled(self.spellPage>1);self.spellNext:SetEnabled(self.spellPage*5<#list)
            self.spellCount:SetText(#list==0 and "No learned spells match your search." or #list.." learned spells / Page "..self.spellPage)
            self.savedTitle:SetText("Your custom reminders ("..#Suite.db.missingBuffCustom.." / 8)")
            for i,row in ipairs(self.saved) do
                local record=Suite.db.missingBuffCustom[i];row:SetShown(record~=nil)
                if record then
                    local spell=Buffs:Spell(record.id);row.icon:SetTexture(spell and spell.icon or 134400)
                    row.label:SetText(spell and spell.name or "Spell information loading")
                    row.scope.label:SetText(record.group and "Party / raid" or "Self only")
                end
            end
        end
    end
    local function Place(frame,y) frame:ClearAllPoints();frame:SetPoint("TOPLEFT",0,-y) end
    Place(self.choices,208)
    local y=208+(self.choiceHeight or 490)+12
    Place(self.appearanceToggle,y);self.appearanceToggle.label:SetText((self.appearanceOpen and "- " or "+ ").."Appearance")
    y=y+38
    if self.appearanceOpen then Place(self.display,y);y=y+276 end
    Place(self.advancedToggle,y);self.advancedToggle.label:SetText((self.advancedOpen and "- " or "+ ").."Advanced")
    y=y+38
    if self.advancedOpen then
        Place(self.visibility,y);y=y+224
        Place(self.spells,y);y=y+(self.spellsHeight or 650)
    end
    self.panel:SetHeight(y+12)
    if GUI.page=="buffs" then GUI:LayoutPage("buffs") end
end
