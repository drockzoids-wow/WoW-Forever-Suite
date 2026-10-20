local _, Suite = ...
local View = { page=1 }
Suite.ProfileSettings = View
local Profiles,GUI = Suite.Profiles,Suite.GUI
local colors = {text={0.88,0.91,0.93},muted={0.55,0.65,0.7},teal={0.41,0.84,0.75},gold={0.9,0.72,0.4}}
local function Label(parent,text,x,y,width,size,color)
    local f=parent:CreateFontString(nil,"OVERLAY")
    f:SetFont("Fonts\\FRIZQT__.TTF",size or 12,"");f:SetPoint("TOPLEFT",x,y);f:SetWidth(width)
    f:SetWordWrap(true);f:SetJustifyH("LEFT");f:SetTextColor(unpack(color or colors.text));f:SetText(text)
    return f
end
local function Button(parent,text,x,y,width,callback)
    local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
    b:SetPoint("TOPLEFT",x,y);b:SetSize(width,30)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    b:SetBackdropColor(0.07,0.095,0.11,1);Suite.Theme:Backdrop(b, 1)
    b.label=Label(b,text,10,-9,width-20,11,colors.teal);b.label:SetWordWrap(false)
    local nativeEnable=b.SetEnabled
    b.SetEnabled=function(self,enabled)
        nativeEnable(self,enabled)
        self.label:SetTextColor(unpack(enabled and colors.teal or colors.muted))
    end
    b:SetScript("OnClick",function() if not InCombatLockdown() then callback() end end)
    b:SetScript("OnEnter",function() b:SetBackdropColor(0.09,0.13,0.145,1) end)
    b:SetScript("OnLeave",function() b:SetBackdropColor(0.07,0.095,0.11,1) end)
    return b
end
function View:Dismiss()
    self.review,self.removing,self.message=nil,nil,nil
    Suite.pending.profilesBuild=nil
    if self.name then self.name:ClearFocus() end
    if self.sourcePopup then self.sourcePopup:Hide() end
end
function View:Message(ok,message)
    self.message=message or (ok and "Saved." or "Unable to save this change.")
    self:Refresh()
end
function View:Build()
    if self.panel then return end
    if InCombatLockdown() then
        Suite.AfterCombat("profilesBuild",function()
            if GUI.page=="profiles" and GUI.frame and GUI.frame:IsShown() then self:Build();self:Refresh() end
        end)
        return
    end
    Suite.pending.profilesBuild=nil
    local panel=CreateFrame("Frame",nil,GUI.content)
    panel:SetSize(780,680);self.panel,GUI.profilePanel=panel,panel
    self.active=Label(panel,"",0,0,780,16,colors.teal)
    self.scope=Label(panel,"",0,-27,780,11,colors.muted)
    self.shared=Button(panel,"Use shared settings",0,-66,176,function() self:Review(Profiles.activeID,false) end)
    self.personal=Button(panel,"Only this character",188,-66,190,function() self:Review(Profiles.activeID,true) end)
    Label(panel,"SAVED PROFILES",0,-122,236,11,colors.muted)
    self.rows={}
    for i=1,6 do
        local row=Button(panel,"",0,-148-(i-1)*46,236,function()
            local entry=Profiles.store and Profiles.store.entries[(self.page-1)*6+i]
            if entry then self.selected=entry.id;self.review,self.removing,self.message=nil,nil,nil;self:Refresh(true) end
        end)
        row:SetHeight(38);self.rows[i]=row
    end
    self.prev=Button(panel,"Previous",0,-434,112,function() self.page=math.max(1,self.page-1);self:Refresh() end)
    self.next=Button(panel,"Next",124,-434,112,function() self.page=math.min(math.ceil(#Profiles.store.entries/6),self.page+1);self:Refresh() end)
    self.count=Label(panel,"",0,-480,236,11,colors.muted)
    self.detail=Label(panel,"",264,-122,516,16,colors.teal)
    self.summary=Label(panel,"",264,-151,516,11,colors.muted);self.summary:SetHeight(42)
    self.use=Button(panel,"Review switch",264,-202,188,function() self:Review(self.selected,Profiles.activePersonal) end)
    self.delete=Button(panel,"Delete profile",464,-202,156,function()
        self.removing=self.selected;self.review=nil;self:Refresh()
    end)
    Label(panel,"Profile name",264,-254,516,11,colors.muted)
    local name=CreateFrame("EditBox",nil,panel,"BackdropTemplate")
    name:SetPoint("TOPLEFT",264,-278);name:SetSize(326,30);name:SetAutoFocus(false);name:SetMaxLetters(40)
    name:SetFont("Fonts\\FRIZQT__.TTF",12,"");name:SetTextInsets(8,8,0,0)
    name:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    name:SetBackdropColor(0.035,0.05,0.065,1);Suite.Theme:Backdrop(name, 1)
    name:SetScript("OnEnterPressed",function() name:ClearFocus() end)
    name:SetScript("OnEscapePressed",function() name:ClearFocus() end);self.name=name
    self.rename=Button(panel,"Rename",602,-278,178,function()
        local ok,err=Profiles:Rename(self.selected,name:GetText());self:Message(ok,err)
    end)
    Label(panel,"COPY A SETUP",264,-337,516,11,colors.muted)
    self.source=Button(panel,"",264,-362,516,function()
        GUI:ScrollTo(0);self.sourcePage=math.ceil((self.sourceIndex or 1)/6);self.sourcePopup:SetShown(not self.sourcePopup:IsShown());self:RefreshSources()
    end)
    local popup=CreateFrame("Frame",nil,panel,"BackdropTemplate")
    popup:SetPoint("TOPLEFT",264,-114);popup:SetSize(516,284)
    popup:SetFrameLevel(panel:GetFrameLevel()+10);popup:EnableMouse(true)
    popup:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    popup:SetBackdropColor(0.035,0.05,0.065,1);Suite.Theme:Backdrop(popup, 1)
    Label(popup,"COPY FROM",12,-12,492,11,colors.muted)
    self.sourcePopup,self.sourceRows=popup,{}
    for i=1,6 do
        self.sourceRows[i]=Button(popup,"",12,-36-(i-1)*32,492,function()
            self.sourceIndex=((self.sourcePage or 1)-1)*6+i;popup:Hide();self:Refresh()
        end)
        self.sourceRows[i]:SetHeight(28)
    end
    self.sourcePrev=Button(popup,"Previous",12,-242,140,function() self.sourcePage=self.sourcePage-1;self:RefreshSources() end)
    self.sourceNext=Button(popup,"Next",164,-242,140,function() self.sourcePage=self.sourcePage+1;self:RefreshSources() end)
    Button(popup,"Close",316,-242,188,function() popup:Hide() end)
    popup:Hide()
    self.copy=Button(panel,"Save as new profile",264,-404,228,function()
        local source=self.sources[self.sourceIndex or 1]
        local id,err=Profiles:Create(name:GetText(),source and source.guid)
        if id then self.selected=id;self.page=math.ceil(#Profiles.store.entries/6);self:Message(true,"Copy saved. Review switch to use it.")
        else self:Message(false,err) end
    end)
    Label(panel,"Choose the source above; enter a new name in Profile name. Character sources use their last saved setup.",264,-450,516,11,colors.muted)
    self.status=Label(panel,"",0,-520,780,11,colors.gold);self.status:SetHeight(30)
    self.reviewText=Label(panel,"",0,-562,780,11);self.reviewText:SetHeight(62)
    self.confirm=Button(panel,"Use & reload",0,-638,188,function()
        if self.removing then
            local ok,err=Profiles:Delete(self.removing)
            self.removing=nil;if ok then self.selected=Profiles.activeID;self.page=1 end
            self:Message(ok,err)
        elseif self.review then
            local ok,err=Profiles:Activate(self.review);self.review=nil
            self:Message(ok,err or "Reload requested. If it does not start, type /reload.")
        end
    end)
    self.cancel=Button(panel,"Cancel",200,-638,112,function() self.review,self.removing=nil,nil;self:Refresh() end)
    panel:SetScript("OnHide",function() self:Dismiss() end)
    panel:RegisterEvent("PLAYER_REGEN_DISABLED");panel:RegisterEvent("PLAYER_REGEN_ENABLED")
    panel:SetScript("OnEvent",function() if GUI.page=="profiles" and panel:IsShown() then self:Refresh() end end)
end
function View:RefreshCaption()
    if not GUI.profileSubtitle then return end
    local active=Profiles:Find(Profiles.activeID)
    GUI.profileSubtitle:SetText(active and ("Profile: "..active.name..(Profiles.activePersonal and "  /  Personal" or "  /  Shared"))
        or "A setup that feels like yours.")
end
function View:RefreshSources()
    if not self.sources or not self.sourcePopup then return end
    self.sourcePage=math.max(1,math.min(self.sourcePage or 1,math.ceil(#self.sources/6)))
    for i,row in ipairs(self.sourceRows) do
        local source=self.sources[(self.sourcePage-1)*6+i]
        row:SetShown(source~=nil)
        if source then row.label:SetText(source.label);row:SetEnabled(not InCombatLockdown()) end
    end
    self.sourcePrev:SetEnabled(self.sourcePage>1 and not InCombatLockdown())
    self.sourceNext:SetEnabled(self.sourcePage*6<#self.sources and not InCombatLockdown())
end
function View:Review(id,personal)
    self.removing=nil;self.review=Profiles:Review(id,personal);self.message=nil;self:Refresh()
    GUI:LayoutPage("profiles");GUI:ScrollTo(200)
end
function View:Refresh(resetName)
    if not self.panel then return end
    if not Profiles.store or not Profiles.state then
        self.active:SetText("Profiles will be ready after /reload.")
        return
    end
    Profiles:SaveActive()
    self:RefreshCaption()
    local current=Profiles:Find(Profiles.activeID)
    local entry=Profiles:Find(self.selected) or current;self.selected=entry.id
    self.page=math.max(1,math.min(self.page,math.ceil(#Profiles.store.entries/6)))
    local ready=not InCombatLockdown() and not Profiles.reloadPending
    self.active:SetText("Active: "..current.name)
    self.scope:SetText(Profiles.activePersonal
        and "Personal changes are saved for this character. Unchanged settings follow the shared profile."
        or "Shared changes are saved to this profile for every character using it. Default preserves your existing setup.")
    self.shared:SetEnabled(ready and Profiles.activePersonal);self.personal:SetEnabled(ready and not Profiles.activePersonal)
    self.shared.label:SetText(Profiles.activePersonal and "Use shared settings" or "Shared profile active")
    self.personal.label:SetText(Profiles.activePersonal and "Personal changes active" or "Only this character")
    for i,row in ipairs(self.rows) do
        local item=Profiles.store.entries[(self.page-1)*6+i]
        row:SetShown(item~=nil)
        if item then
            row.label:SetText((item.id==Profiles.activeID and "* " or "")..item.name)
            Suite.Theme:Backdrop(row, item.id == entry.id and 1 or 0.35)
            row:SetEnabled(ready)
        end
    end
    self.prev:SetEnabled(ready and self.page>1);self.next:SetEnabled(ready and self.page*6<#Profiles.store.entries)
    self.count:SetText(#Profiles.store.entries.." / 12 profiles  |  Page "..self.page)
    self.detail:SetText(entry.name)
    local users=0;for _,r in pairs(Profiles.store.characters) do if r.id==entry.id then users=users+1 end end
    self.summary:SetText((entry.id==Profiles.activeID and "Currently active. " or "Available to every character. ")
        ..users.." recorded character(s).\nCopies include Suite feature choices and Suite window layouts.")
    self.use:SetEnabled(ready and entry.id~=Profiles.activeID)
    self.rename:SetEnabled(ready and entry.id~="default")
    self.delete:SetEnabled(ready and entry.id~="default" and entry.id~=Profiles.activeID and users==0)
    if resetName or self.inputID~=entry.id then self.name:SetText(entry.name);self.inputID=entry.id end
    self.sources={{label="Current setup"}}
    local characters={}
    for guid,record in pairs(Profiles.store.characters) do
        if guid~=Profiles.guid then characters[#characters+1]={guid=guid,label=record.name..(record.realm~="" and " - "..record.realm or "")} end
    end
    table.sort(characters,function(a,b) if a.label==b.label then return a.guid<b.guid end;return a.label<b.label end)
    for _,source in ipairs(characters) do self.sources[#self.sources+1]=source end
    self.sourceIndex=math.min(self.sourceIndex or 1,#self.sources)
    self.source.label:SetText("Source: "..self.sources[self.sourceIndex].label..(#self.sources>1 and "  (choose)" or ""))
    if InCombatLockdown() then self.sourcePopup:Hide() end
    self:RefreshSources()
    self.source:SetEnabled(ready and #self.sources>1);self.copy:SetEnabled(ready and #Profiles.store.entries<Profiles.limit)
    self.status:SetText(InCombatLockdown() and "Profile actions are available after combat."
        or Profiles.reloadPending and "Profile selection saved. Type /reload to finish switching." or self.message or "")
    local review=self.review
    if self.removing then
        local target=Profiles:Find(self.removing)
        self.reviewText:SetText("Delete "..(target and target.name or "profile").."? This removes the saved setup. Your active setup stays in place.")
        self.confirm.label:SetText("Confirm delete")
    elseif review then
        local target=Profiles:Find(review.id)
        local text="Use "..target.name..(review.personal and " with personal changes" or " as a shared profile").."? "..#review.changes.." setting(s) will change."
        if #review.enabled>0 then text=text.."\nTurns on: "..table.concat(review.enabled,", ").."." end
        if #review.changes>0 then text=text.."\n"..table.concat(review.changes,"; ") end
        text=text.."\nThe UI will reload. Your current settings are saved first."
        self.reviewText:SetText(text);self.confirm.label:SetText("Use & reload")
        if not InCombatLockdown() then
            self.reviewText:SetHeight(0)
            self.reviewText:SetHeight(math.max(62,self.reviewText:GetStringHeight()+8))
        end
    else self.reviewText:SetText("") end
    local showing=self.removing~=nil or review~=nil
    self.confirm:SetShown(showing);self.cancel:SetShown(showing)
    self.confirm:SetEnabled(ready);self.cancel:SetEnabled(ready)
    if not InCombatLockdown() then
        local bottom=math.max(638,562+self.reviewText:GetHeight()+12)
        self.confirm:ClearAllPoints();self.confirm:SetPoint("TOPLEFT",0,-bottom)
        self.cancel:ClearAllPoints();self.cancel:SetPoint("TOPLEFT",200,-bottom)
        self.panel:SetHeight(showing and bottom+42 or 550)
        if GUI.page=="profiles" then GUI:LayoutPage("profiles") end
    end
end
