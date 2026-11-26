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
local function Button(parent, text, x, y, width, callback)
    local button = Suite.Theme:ActionButton(parent, text, width, 30, function() if not InCombatLockdown() then callback() end end)
    button:SetPoint("TOPLEFT", x, y)

    return button
end
local function NameField(parent, x, y)
    local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    box:SetPoint("TOPLEFT", x, y); box:SetSize(326, 30)
    box:SetAutoFocus(false); box:SetMaxLetters(40)
    box:SetFont("Fonts\\FRIZQT__.TTF",12,""); box:SetTextInsets(8,8,0,0)
    box:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    box:SetBackdropColor(0.035,0.05,0.065,1); Suite.Theme:Backdrop(box, 1)
    box:SetScript("OnEnterPressed",function() box:ClearFocus() end)
    box:SetScript("OnEscapePressed",function() box:ClearFocus() end)
    return box
end
function View:Dismiss()
    self.review,self.removing,self.message=nil,nil,nil
    Suite.pending.profilesBuild=nil
    if self.name then self.name:ClearFocus() end
    if self.copyName then self.copyName:ClearFocus() end
    self.copyMessage=nil
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
            if entry then
                self.selected=entry.id
                self.review,self.removing,self.message,self.copyMessage=nil,nil,nil,nil
                self:Refresh(true)
            end
        end)
        row:SetHeight(38);self.rows[i]=row
    end
    self.prev=Button(panel,"Previous",0,-434,112,function() self.page=math.max(1,self.page-1);self:Refresh() end)
    self.next=Button(panel,"Next",124,-434,112,function() self.page=math.min(math.ceil(#Profiles.store.entries/6),self.page+1);self:Refresh() end)
    self.wheelArea=Suite.Theme:PageWheel(panel,self.rows,self.prev,self.next,self.next)
    self.count=Label(panel,"",0,-480,236,11,colors.muted)
    Label(panel,"Copy settings from",264,-122,516,16,colors.teal)
    self.source=Button(panel,"",264,-148,516,function()
        GUI:ScrollTo(0);self.sourcePage=math.ceil((self.sourceIndex or 1)/6);self.sourcePopup:SetShown(not self.sourcePopup:IsShown());self:RefreshSources()
    end)
    local popup=CreateFrame("Frame",nil,panel,"BackdropTemplate")
    local rowCount,rowTop,rowSpacing=6,36,34
    local footerTop=rowTop+(rowCount-1)*rowSpacing+30+20
    popup:SetPoint("TOPLEFT",264,-114);popup:SetSize(516,footerTop+30+14)
    popup:SetFrameLevel(panel:GetFrameLevel()+10);popup:EnableMouse(true)
    popup:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    popup:SetBackdropColor(0.035,0.05,0.065,1);Suite.Theme:Backdrop(popup, 1)
    Label(popup,"Choose a character",12,-12,492,13,colors.text)
    self.sourcePopup,self.sourceRows=popup,{}
    for i=1,rowCount do
        self.sourceRows[i]=Button(popup,"",12,-rowTop-(i-1)*rowSpacing,492,function()
            local source=self.sources[(self.sourcePage-1)*6+i]
            if source then
                self.sourceGUID,self.copyMessage=source.guid,nil
                popup:Hide()
                self:Refresh()
            end
        end)
    end
    self.sourcePrev=Button(popup,"Previous",12,-footerTop,140,function() self.sourcePage=self.sourcePage-1;self:RefreshSources() end)
    self.sourceNext=Button(popup,"Next",164,-footerTop,140,function() self.sourcePage=self.sourcePage+1;self:RefreshSources() end)
    Button(popup,"Close",316,-footerTop,188,function() popup:Hide() end)
    local wheelArea=Suite.Theme:PageWheel(popup,self.sourceRows,self.sourcePrev,self.sourceNext,self.sourceNext)
    -- The dropdown pages independently of the settings scroll frame.
    popup.suiteOwnsWheel=true
    popup:SetScript("OnMouseWheel",wheelArea:GetScript("OnMouseWheel"))
    Suite.Theme:RouteWheel(popup)
    popup:Hide()
    Label(panel,"New profile name",264,-191,326,11,colors.muted)
    self.copyName=NameField(panel,264,-209)
    self.copy=Button(panel,"Create copy",602,-209,178,function()
        local name=self.copyName:GetText() or ""
        if name:match("^%s*$") then
            self.copyMessage="Enter a name for the new profile."
            self:Refresh()
            return
        end
        local id,err=Profiles:Create(name,self.sourceGUID)
        if id then
            self.selected=id
            self.page=math.ceil(#Profiles.store.entries/6)
            self.review,self.removing,self.message=nil,nil,nil
            self.copyName:SetText("")
            self.copyName:ClearFocus()
            self.copyMessage="Created "..Profiles:Find(id).name..". Click Switch profile below to use it."
        else
            self.copyMessage=err
        end
        self:Refresh()
    end)
    Label(panel,"Other characters use the settings saved when they last played.",264,-249,516,11,colors.muted)
    self.copyStatus=Label(panel,"",264,-273,516,11,colors.gold);self.copyStatus:SetHeight(34)

    self.detail=Label(panel,"",264,-322,516,16,colors.teal)
    self.summary=Label(panel,"",264,-350,516,11,colors.muted);self.summary:SetHeight(34)
    self.use=Button(panel,"Switch profile",264,-387,188,function() self:Review(self.selected,Profiles.activePersonal) end)
    self.delete=Button(panel,"Delete profile",464,-387,156,function()
        self.removing=self.selected;self.review=nil;self:Refresh()
    end)
    Label(panel,"Selected profile name",264,-430,326,11,colors.muted)
    self.name=NameField(panel,264,-448)
    self.rename=Button(panel,"Rename",602,-448,178,function()
        local ok,err=Profiles:Rename(self.selected,self.name:GetText());self:Message(ok,err)
    end)
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
        and "Your changes apply to this character. Other settings follow the shared profile."
        or "Your changes apply to every character using this profile.")
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
    self.summary:SetText((entry.id==Profiles.activeID and "Currently active. " or "")
        ..users..(users==1 and " character uses this profile." or " characters use this profile."))
    self.use:SetEnabled(ready and entry.id~=Profiles.activeID)
    self.rename:SetEnabled(ready and entry.id~="default")
    self.delete:SetEnabled(ready and entry.id~="default" and entry.id~=Profiles.activeID and users==0)
    if resetName or self.inputID~=entry.id then self.name:SetText(entry.name);self.inputID=entry.id end
    self.sources={{label="This character (current settings)"}}
    local characters={}
    for guid,record in pairs(Profiles.store.characters) do
        if guid~=Profiles.guid then characters[#characters+1]={guid=guid,label=record.name..(record.realm~="" and " - "..record.realm or "")} end
    end
    table.sort(characters,function(a,b) if a.label==b.label then return a.guid<b.guid end;return a.label<b.label end)
    self.sourceIndex=1
    for _,source in ipairs(characters) do
        self.sources[#self.sources+1]=source
        if source.guid==self.sourceGUID then self.sourceIndex=#self.sources end
    end
    local source=self.sources[self.sourceIndex]
    self.source.label:SetText(self.sourceGUID and not source.guid and "Character unavailable"
        or source.label..(#self.sources>1 and "  (choose)" or ""))
    self.copyStatus:SetText(self.copyMessage or "")
    if InCombatLockdown() then self.sourcePopup:Hide() end
    self:RefreshSources()
    self.source:SetEnabled(ready and (#self.sources>1 or self.sourceGUID~=nil))
    self.copy:SetEnabled(ready and #Profiles.store.entries<Profiles.limit)
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
