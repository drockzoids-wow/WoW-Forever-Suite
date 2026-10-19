local _,Suite=...
local View={page=1,spellPage=1,filter="all",controls={}}
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
    b:SetPoint("TOPLEFT",x,y);b:SetSize(width,28)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    b:SetBackdropColor(0.07,0.095,0.11,1);b:SetBackdropBorderColor(0.17,0.25,0.29)
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
    f:SetBackdropColor(0.035,0.05,0.065,1);f:SetBackdropBorderColor(0.17,0.25,0.29)
    f:SetScript("OnTextChanged",function()
        if f.hint then f.hint:SetShown(f:GetText()=="") end
        if not InCombatLockdown() then callback(f:GetText()) end
    end)
    f:SetScript("OnEnterPressed",function() f:ClearFocus() end)
    f:SetScript("OnEscapePressed",function() View:Dismiss();GUI:Select("buffs") end)
    return f
end
local function Icon(parent,x,y)
    local icon=parent:CreateTexture(nil,"ARTWORK");icon:SetSize(26,26);icon:SetPoint("TOPLEFT",x,y);return icon
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
    self.mode,self.message=nil,nil;Suite.pending.buffManager=nil
    if self.panel then self.panel:Hide();self.search:ClearFocus();self.choiceSearch:ClearFocus() end
end
function View:Open(mode)
    if InCombatLockdown() then
        Suite.AfterCombat("buffManager",function() if GUI.page=="buffs" and GUI.frame and GUI.frame:IsShown() then self:Open(mode) end end)
        return
    end
    self.cachedLearned=nil
    self.mode,self.message=mode or "display",nil
    GUI:OpenPage("buffs");self:Build();self:Refresh();GUI:Select("buffs");GUI:ScrollTo(GUI.controlsOffset)
end
function View:Changed()
    Buffs.bookDirty=true;Buffs:Queue();self:Refresh()
end
function View:Display(key,value)
    if InCombatLockdown() then return end
    if key=="missingBuffLocked" then
        if Buffs.bar then Buffs:StopMoving(Buffs.bar) end
        if Buffs.preview then Buffs:StopMoving(Buffs.preview) end
    end
    Suite.db[key]=value
    if Buffs.bar then Buffs:Place(Buffs.bar) end
    if Buffs.preview then Buffs:Place(Buffs.preview) end
    Suite.BuffReminders:PlaceCombat();Buffs:Queue();self:Refresh()
end
function View:Build()
    if self.panel or InCombatLockdown() then return end
    local panel=CreateFrame("Frame",nil,GUI.content);panel:SetSize(780,340);self.panel,GUI.buffPanel=panel,panel
    self.tabs={}
    local modes={{"display","Bar appearance"},{"choices","Buff list"},{"spells","Custom spells"}}
    for i,entry in ipairs(modes) do self.tabs[entry[1]]=Button(panel,entry[2],(i-1)*264,0,252,function() self.mode,self.message=entry[1],nil;self:Refresh() end) end
    self.status=Label(panel,"",0,-40,780,11,colors.gold);self.status:SetHeight(30)
    local display=CreateFrame("Frame",nil,panel);self.display=display
    display:SetPoint("TOPLEFT",0,-80);display:SetSize(780,300)
    Label(display,"Make the reminders comfortable to read.",0,0,780,14,colors.teal)
    Label(display,"Teal icons cast your learned spells. Gold Group icons request a teammate's buff when clicked.\nThe action bar pauses in combat; passive combat reminders use their own option.",0,-30,780,11,colors.muted)
    self.scale=Button(display,"",0,-90,252,function()
        local current=Buffs:DisplayOptions();local list={0.8,1,1.2,1.4};local nextValue=list[1]
        for i,value in ipairs(list) do if math.abs(current-value)<0.001 then nextValue=list[i%#list+1];break end end
        self:Display("missingBuffScale",nextValue)
    end)
    self.size=Button(display,"",264,-90,252,function()
        local _,current=Buffs:DisplayOptions();local list={28,34,40,48};local nextValue=list[1]
        for i,value in ipairs(list) do if current==value then nextValue=list[i%#list+1];break end end
        self:Display("missingBuffIconSize",nextValue)
    end)
    self.lock=Button(display,"",528,-90,252,function() self:Display("missingBuffLocked",not Suite.db.missingBuffLocked) end)
    self.rested=Button(display,"",0,-138,384,function() self:Display("missingBuffRested",not Suite.db.missingBuffRested) end)
    self.smart=Button(display,"",396,-138,384,function() self:Display("missingBuffSmart",not Suite.db.missingBuffSmart) end)
    Label(display,"Class-aware targets include Intellect and mana recovery for all Forever mana classes, including Hunters and Druids in any form. Turn this off if you prefer reminders for every class.",0,-184,780,11,colors.muted)
    Button(display,"Preview bar position",0,-242,252,function() Buffs:SetPreview(true) end)
    Button(display,"Reset appearance",264,-242,252,function()
        self:Display("missingBuffScale",1);self:Display("missingBuffIconSize",34);self:Display("missingBuffLocked",false)
    end)
    Button(display,"Close these controls",528,-242,252,function() self:Dismiss();GUI:Select("buffs") end)
    local choices=CreateFrame("Frame",nil,panel);self.choices=choices
    choices:SetPoint("TOPLEFT",0,-80);choices:SetSize(780,490)
    Label(choices,"Find a hidden reminder or choose a learned alternative.",0,0,780,14,colors.teal)
    self.choiceSearch=Input(choices,0,-34,384,function(value) self.choiceQuery=value;self.page=1;self:Refresh() end)
    self.choiceSearch.hint=Label(self.choiceSearch,"Search by spell or class",8,-7,368,11,colors.muted)
    self.choiceFilter=Button(choices,"All families",396,-34,384,function()
        self.filter=({all="hidden",hidden="mine",mine="all"})[self.filter];self.page=1;self:Refresh()
    end)
    self.choiceEmpty=Label(choices,"",0,-82,780,11,colors.muted)
    self.choiceRows={}
    for i=1,8 do
        local row=CreateFrame("Frame",nil,choices);row:SetPoint("TOPLEFT",0,-80-(i-1)*44);row:SetSize(780,40)
        row.icon=Icon(row,0,-2);row.label=Label(row,"",36,-2,360,11);row.detail=Label(row,"",36,-20,360,10,colors.muted)
        row.label:SetWordWrap(false);row.detail:SetWordWrap(false)
        row.visible=Button(row,"",410,0,170,function()
            local record=row.record;if not record then return end
            if Suite.db.missingBuffChoices[record.key]==0 then Suite.db.missingBuffChoices[record.key]=nil
            else Suite.db.missingBuffChoices[record.key]=0 end
            self:Changed()
        end)
        row.alternative=Button(row,"Change alternative",592,0,188,function()
            local record=row.record;if not record then return end
            local current=Suite.db.missingBuffChoices[record.key];local nextValue=record.family.choices[1] and record.family.choices[1].id
            for index,spell in ipairs(record.family.choices) do if current==spell.id or current==spell.root then nextValue=record.family.choices[index+1] and record.family.choices[index+1].id;break end end
            Suite.db.missingBuffChoices[record.key]=nextValue;self:Changed()
        end)
        self.choiceRows[i]=row
    end
    self.choicePrev=Button(choices,"Previous",0,-442,160,function() self.page=math.max(1,self.page-1);self:Refresh() end)
    self.choiceNext=Button(choices,"Next",172,-442,160,function() self.page=self.page+1;self:Refresh() end)
    self.choiceCount=Label(choices,"",356,-450,424,11,colors.muted)
    local spells=CreateFrame("Frame",nil,panel);self.spells=spells
    spells:SetPoint("TOPLEFT",0,-80);spells:SetSize(780,650)
    Label(spells,"Choose a learned spell by name or icon.",0,0,780,14,colors.teal)
    Label(spells,"Custom reminders are optional and stay outside combat. Choose a buff you can cast; adding a spell never casts it.",0,-28,780,11,colors.muted)
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
                self.choiceSearch:SetText(row.spell.name);self:Refresh();return
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
            rows[#rows+1]={key=key,name=name,icon=spell and spell.icon or 134400,hidden=hidden,family=family,class=catalog.class}
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
    return rows
end
function View:Refresh()
    if not self.panel or not self.mode then return end
    local ready=not InCombatLockdown()
    for _,control in ipairs(self.controls) do control:SetEnabled(ready) end
    self.status:SetText(not ready and "Controls are available after combat." or self.message or "")
    if not ready then return end
    for mode,tab in pairs(self.tabs) do
        tab:SetBackdropBorderColor(unpack(mode==self.mode and colors.teal or colors.muted))
    end
    self.search.hint:SetShown(not self.query or self.query=="")
    self.choiceSearch.hint:SetShown(not self.choiceQuery or self.choiceQuery=="")
    local scale,size=Buffs:DisplayOptions()
    self.scale.label:SetText("Bar scale: "..math.floor(scale*100+0.5).."%")
    self.size.label:SetText("Icon size: "..size)
    self.lock.label:SetText(Suite.db.missingBuffLocked and "Movement: locked" or "Movement: unlocked")
    self.rested.label:SetText(Suite.db.missingBuffRested and "Rested areas: show reminders" or "Rested areas: pause reminders")
    self.smart.label:SetText(Suite.db.missingBuffSmart and "Class-aware targets: on" or "Class-aware targets: off")
    self.display:SetShown(self.mode=="display");self.choices:SetShown(self.mode=="choices");self.spells:SetShown(self.mode=="spells")
    if self.mode=="choices" or self.mode=="spells" then
        local learned,book,complete=self:Learned()
        if not complete then self.status:SetText("Some learned spell information is unavailable. The list will update when it arrives.") end
        if self.mode=="choices" then
            local records=self:FamilyRows(book);self.page=math.max(1,math.min(self.page,math.max(1,math.ceil(#records/8))))
            self.choiceFilter.label:SetText(({all="All families",hidden="Hidden families",mine="My class"})[self.filter])
            for i,row in ipairs(self.choiceRows) do
                local record=records[(self.page-1)*8+i];row.record=record;row:SetShown(record~=nil)
                if record then
                    row.icon:SetTexture(record.icon);row.label:SetText(record.name)
                    row.detail:SetText((classLabels[record.class] or record.class).." / "..(record.hidden and "Hidden" or record.family.spell and record.family.spell.name or "Automatic"))
                    row.visible.label:SetText(record.hidden and "Show reminder" or "Hide reminder")
                    row.alternative:SetEnabled(not record.hidden and #record.family.choices>1)
                end
            end
            self.choiceEmpty:SetShown(#records==0)
            self.choiceEmpty:SetText(self.filter=="hidden" and "No hidden families match this view." or "No buff families match. Try another spell or class name.")
            local visible=math.min(8,math.max(1,#records-(self.page-1)*8))
            local nav=80+visible*44+10
            self.choicePrev:ClearAllPoints();self.choicePrev:SetPoint("TOPLEFT",0,-nav)
            self.choiceNext:ClearAllPoints();self.choiceNext:SetPoint("TOPLEFT",172,-nav)
            self.choiceCount:ClearAllPoints();self.choiceCount:SetPoint("TOPLEFT",356,-nav-8)
            self.choiceHeight=nav+48;self.choices:SetHeight(self.choiceHeight)
            self.choicePrev:SetEnabled(self.page>1);self.choiceNext:SetEnabled(self.page*8<#records)
            self.choiceCount:SetText(#records.." families / Page "..self.page.." · Search by spell or class")
        else
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
    self.panel:SetHeight(self.mode=="display" and 380 or self.mode=="choices" and 80+(self.choiceHeight or 490) or 80+(self.spellsHeight or 650))
    if GUI.page=="buffs" then GUI:LayoutPage("buffs") end
end
