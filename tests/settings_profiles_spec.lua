local Suite,equal,Frame,Combat,events = ...
local p,view,gui=Suite.Profiles,Suite.ProfileSettings,Suite.GUI
local old={db=Suite.db,account=WoWForeverSuiteDB,character=WoWForeverSuiteCharDB,store=p.store,state=p.state,
    id=p.activeID,personal=p.activePersonal,guid=p.guid,pending=p.reloadPending,unit=UnitGUID,name=UnitName,
    realm=GetNormalizedRealmName,reload=ReloadUI,apply=Suite.Apply,page=gui.page,shown=gui.frame:IsShown(),
    leveling=Suite.Leveling.db,training=Suite.Training.db,macros=Suite.macroDB,
    scoring=Suite.Scoring.character,scoreOwner=Suite.Scoring.owner,loaded=Suite.loadedSavedVariables}
local reloads,applied=0,0
ReloadUI=function() reloads=reloads+1 end
Suite.Apply=function() applied=applied+1 end
UnitGUID=function() return "Profile-A" end
UnitName=function() return "Alice" end
GetNormalizedRealmName=function() return "Realm" end
Combat(false)
local function Load(db,char,guid,name)
    UnitGUID=function() return guid or "Profile-A" end
    UnitName=function() return name or "Alice" end
    WoWForeverSuiteDB,WoWForeverSuiteCharDB=db,char
    events.OnEvent(events,"ADDON_LOADED","WoWForeverSuite")
    p:RegisterCharacter()
    return WoWForeverSuiteDB,WoWForeverSuiteCharDB
end
local db,char=Load({quickLoot=true,windowTools=true,windowPositions={Bag={x=0.2,scale=1.2}},
    meterWindows={{width=360}},inventory={schema=1,characters={keep={money=42}},accountBanks={}},
    macroOwnership={keep="manual"},mailContacts={schema=2,entries={},removed={}},
    bagSpaceBlacklist={[123]=true}}, {scoring={schema=1,active="healer",preference="stats",profiles={}},entries={}})
equal(#p.store.entries,1,"migration creates only Default")
equal(p.activeID,"default","existing characters automatically use Default")
equal(p.activePersonal,false,"existing shared behavior is preserved")
equal(Suite.db.quickLoot,true,"migration preserves existing feature choices")
equal(Suite.db.minimapButton,true,"launcher default stays visible")
equal(Suite.db.windowPositions.Bag.scale,1.2,"migration preserves native window layouts")
equal(char.suiteProfile,p.state,"character assignment survives macro root reconstruction")
equal(Suite.Scoring:State().active,"healer","settings profiles do not replace character gear preference")
local inventory,ownership,contacts,blacklist=db.inventory,db.macroOwnership,db.mailContacts,db.bagSpaceBlacklist
local default=p:Find("default")
equal(default.values.inventory,nil,"inventory snapshots excluded")
equal(default.values.mailContacts,nil,"mail contacts excluded")
equal(default.values.macroOwnership,nil,"macro ownership excluded")
equal(default.values.bagSpaceBlacklist,nil,"item protection rules excluded")
equal(default.values.scorePreset,nil,"legacy scoring preference excluded")
equal(default.values.setupGuide,nil,"guide completion excluded")
equal(default.values.settingsProfiles,nil,"no recursive profile snapshots")
Suite.db.progressBarTextRestore="0";Suite.db.bagSortDirectionRestore=false
local copy=p:Create("Quiet")
equal(copy,"p1","new profiles use stable IDs")
equal(p.activeID,"default","saving a copy never changes active settings")
equal(p:Find(copy).values.quickLoot,true,"copies capture current choices")
equal(p:Find(copy).values.progressBarTextRestore,nil,"native text restoration state excluded")
equal(p:Find(copy).values.bagSortDirectionRestore,nil,"native bag restoration state excluded")
p:Find(copy).values.quickLoot=false
p:Find(copy).values.autoQuestPickup=true
p:Find(copy).values.windowPositions.Bag.x=-0.3
equal(db.windowPositions.Bag.x,0.2,"copies do not alias live layouts")
equal(p:Create("quiet"),nil,"duplicate names ignore case")
equal(p:Create("|cff00ff00bad"),nil,"formatting cannot enter profile labels")
equal(p:Create(" \n "),nil,"control characters rejected")
equal(p:Rename("default","Other"),false,"Default remains recognizable")
local review=p:Review(copy,false)
equal(#review.enabled,1,"review explicitly lists newly enabled optional features")
equal(review.enabled[1],"Automatically pick up quests","review uses user-facing feature labels")
equal(#review.changes>=3,true,"review includes settings and layout changes")
local changed=false
for _,line in ipairs(review.changes) do if line=="Window positions and sizes" then changed=true end end
equal(changed,true,"layout changes have readable labels")
Combat(true)
equal(p:Activate(review),false,"combat cannot queue a later profile switch")
equal(p:Create("Combat"),nil,"combat cannot create profiles")
equal(p:Rename(copy,"Combat"),false,"combat cannot rename profiles")
equal(p:Delete(copy),false,"combat cannot delete profiles")
equal(reloads,0,"combat never requests a reload")
equal(char.suiteProfile.id,"default","blocked switch keeps assignment")
Combat(false)
p:Find(copy).values.chatFontSize=18
equal(p:Activate(review),false,"stale review cannot apply changed target")
review=p:Review(copy,false)
equal(p:Activate(review),true,"reviewed switch is accepted")
equal(reloads,1,"explicit switch requests exactly one native reload")
equal(applied,0,"switch never hot-applies modules or protected layouts")
equal(p.activeID,"default","runtime still represents outgoing profile until reload")
equal(char.suiteProfile.id,copy,"next-login selection is persisted separately")
equal(db.quickLoot,true,"outgoing live settings stay coherent until reload")
equal(p:Create("Pending"),nil,"pending switch blocks competing mutations")
p:SaveActive()
db,char=Load(Suite.Copy(db),Suite.Copy(char))
equal(p.activeID,copy,"reload resolves selected named profile")
equal(db.quickLoot,false,"reload installs target settings")
equal(db.autoQuestPickup,true,"explicitly reviewed feature activation persists")
equal(db.windowPositions.Bag.x,-0.3,"reload installs the target layout")
equal(db.inventory.characters.keep.money,42,"inventory retained across reload")
equal(db.macroOwnership.keep,"manual","macro ownership retained across reload")
equal(db.progressBarTextRestore,"0","native restoration value survives profile switch")
equal(db.bagSortDirectionRestore,false,"native false restoration survives profile switch")
-- Personal differences inherit unchanged shared keys, and remain private to this character.
equal(p:Activate(p:Review(copy,true)),true,"personal scope is an explicit reload operation")
db,char=Load(Suite.Copy(db),Suite.Copy(char))
db.quickLoot=true;db.windowPositions.Bag.x=0.4;p:SaveActive()
equal(p.state.overrides[copy].quickLoot,true,"changed boolean becomes a personal override")
equal(p.state.overrides[copy].chatFontSize,nil,"unchanged keys are inherited")
equal(p:Find(copy).values.quickLoot,false,"personal choice does not change shared profile")
equal(p:Find(copy).values.windowPositions.Bag.x,-0.3,"personal drag does not change shared layout")
local alice=Suite.Copy(char)
local bob={suiteProfile={id=copy,personal=false,overrides={}}}
db,bob=Load(Suite.Copy(db),bob,"Profile-B","Bob")
equal(db.quickLoot,false,"second character sees shared setting")
equal(db.windowPositions.Bag.x,-0.3,"second character sees shared layout")
db.chatFontSize=20;p:SaveActive()
db,char=Load(Suite.Copy(db),alice)
equal(db.quickLoot,true,"personal override survives character round trip")
equal(db.windowPositions.Bag.x,0.4,"personal layout survives character round trip")
equal(db.chatFontSize,20,"untouched keys inherit another character's shared edit")
equal(p:Delete(copy),false,"active and assigned profiles cannot be deleted")
local fromBob=p:Create("Bob's setup","Profile-B")
equal(p:Find(fromBob).values.quickLoot,false,"copy-from-character uses that character's recorded effective setup")
equal(p:Find(fromBob).values.chatFontSize,20,"recorded source captures latest saved settings")
db.chatFontSize=22
equal(p:Find(fromBob).values.chatFontSize,20,"character copies are independent")
equal(p:Create("Missing","none"),nil,"missing source never silently copies current character")
local disposable=p:Create("Disposable")
equal(p:Rename(disposable,"Renamed"),true,"inactive profile can be renamed")
equal(p:Delete(disposable),true,"unused profile can be deleted")
equal(p:Find(disposable),nil,"deleted profile is removed")
-- Disabling personal scope keeps private changes available without publishing them.
equal(p:Activate(p:Review(copy,false)),true,"return to shared settings can be reviewed")
db,char=Load(Suite.Copy(db),Suite.Copy(char))
equal(db.quickLoot,false,"shared scope restores shared setting")
equal(char.suiteProfile.overrides[copy].quickLoot,true,"personal override remains saved")
equal(p:Activate(p:Review(copy,true)),true,"personal scope can resume")
db,char=Load(Suite.Copy(db),Suite.Copy(char))
equal(db.quickLoot,true,"resuming personal scope restores private setting")
-- Corruption, cycles and restricted values are filtered without serializing them.
local secret={secret=true}
local cyclic={};cyclic.loop=cyclic
db.meterWindows=cyclic;db.castbars={player={width=0/0,height=secret},target={enabled=true}}
p:SaveActive()
equal(p.state.overrides[copy].meterWindows.loop,nil,"cycles cannot enter a snapshot")
equal(p.state.overrides[copy].castbars.player.width,nil,"nonfinite nested numbers are discarded")
equal(p.state.overrides[copy].castbars.player.height,nil,"restricted nested values are discarded")
equal(p.state.overrides[copy].castbars.target.enabled,true,"readable nested preferences are retained")
local corrupt=Suite.InitializeDB(nil)
corrupt.settingsProfiles={entries={{id="p9",name="Default",values={quickLoot=true}},
    {id="p2",name="Good",values={quickLoot=secret,chatFontSize=secret}},
    {id="p2",name="Duplicate",values={}}},characters={bad=secret}}
Suite.db=corrupt;p:Initialize(corrupt,{id=secret,personal=secret,overrides=secret})
equal(p.activeID,"default","restricted assignment falls back safely")
equal(p.activePersonal,false,"restricted personal flag never used as truth")
equal(p:Find("p9"),nil,"Default name is reserved")
equal(p:Find("p2").values.quickLoot,false,"restricted top-level preference uses safe default")
equal(#p.store.entries,2,"duplicate IDs discarded")
for i=#p.store.entries+1,p.limit do equal(p:Create("Profile "..i)~=nil,true,"bounded profile slots available") end
equal(p:Create("Overflow"),nil,"profile count is bounded")
-- Default and selected assignments also survive absent/corrupt character records.
Suite.db=Suite.InitializeDB(nil)
p:Initialize(Suite.db,{id="removed-profile",personal=false,overrides={}})
equal(p.activeID,"default","missing profile selection safely returns to Default")
equal(Suite.db.quickLoot,false,"fresh default keeps optional features off")
equal(Suite.db.minimapButton,true,"fresh default retains launcher")
local preservedInventory=Suite.db.inventory
Suite.db.progressBarTextRestore="1"
p:Initialize(Suite.db,p.state)
equal(Suite.db.inventory,preservedInventory,"profile projection preserves recorded-data identity")
equal(Suite.db.progressBarTextRestore,"1","projection preserves native restoration identity")
local orphaned=Suite.InitializeDB(nil)
orphaned.settingsProfiles={entries={}}
for i=1,12 do orphaned.settingsProfiles.entries[i]={id="p"..i,name="Stored "..i,values={}} end
Suite.db=orphaned
p:Initialize(orphaned,{id="p12",personal=false,overrides={}})
equal(#p.store.entries,12,"repair reserves one of the bounded slots for Default")
equal(p.activeID,"default","repair cannot select a profile dropped to make room for Default")
-- Actual UI handlers: navigation, naming, copy source, review, cancellation and combat state.
db,char=Load(Suite.InitializeDB(nil),nil)
gui.frame:Show();gui:Select("profiles")
equal(view.panel:GetWidth(),780,"profile form uses the shared wide details area")
equal(view.active:GetText(),"Active: Default","active profile is prominent")
equal(gui.profileSubtitle:GetText(),"Profile: Default  /  Shared","every page identifies the current editing scope")
equal(view.shared.enabled,false,"active scope is visibly disabled")
equal(view.shared.label.textColor[1],0.55,"disabled actions have muted labels")
equal(view.personal.label.textColor[1],0.41,"available actions retain teal labels")
equal(view.personal.enabled,true,"character scope is available")
view.name:SetText("UI copy");view.copy.OnClick(view.copy)
equal(view.selected,"p1","GUI copy selects its new saved profile")
equal(p.activeID,"default","GUI copy does not activate automatically")
view.use.OnClick(view.use)
equal(view.review.id,"p1","GUI switch is staged for review")
equal(view.confirm:IsShown(),true,"final reload action appears only after review")
view.cancel.OnClick(view.cancel)
equal(view.review,nil,"cancel does not change saved selection")
equal(p.state.id,"default","cancel retains current assignment")
view.personal.OnClick(view.personal)
equal(view.review.personal,true,"personal scope uses same review path")
Combat(true);view.panel.OnEvent(view.panel,"PLAYER_REGEN_DISABLED")
equal(view.confirm.enabled,false,"review action disables in combat")
local before=reloads;view.confirm.OnClick(view.confirm)
equal(reloads,before,"UI combat guard prevents invoking switch")
Combat(false);view.panel.OnEvent(view.panel,"PLAYER_REGEN_ENABLED")
equal(view.confirm.enabled,true,"action re-enables after combat without auto-activation")
gui:Select("overview")
equal(view.review,nil,"leaving page discards unconfirmed review")
equal(p.state.id,"default","navigation never changes profile")
equal(Suite.SettingsCatalog:Search("settings profiles")[1].page,"profiles","profile controls are searchable")
SlashCmdList.WOWFOREVERSUITE("profiles")
equal(gui.page,"profiles","dedicated slash shortcut reaches Profiles")
for _,control in ipairs({view.shared,view.personal,view.use,view.delete,view.rename,view.source,view.copy,view.name}) do
    local point=control.point
    equal(point[2]>=0 and point[2]+control:GetWidth()<=780,true,"profile controls remain inside content width")
end
equal(gui.contentHeight>=view.panel:GetHeight()+36,true,"full profile form scrolls above footer")
-- Source picker is paged rather than requiring a long cycle through alts.
for i=1,14 do p.store.characters["Other-"..i]={name="Alt "..i,realm="Realm",id="default",personal=false,values=p:Settings(db)} end
view:Refresh();view.source.OnClick(view.source)
equal(view.sourcePopup:IsShown(),true,"source picker opens without changing settings")
equal(gui.scrollOffset,0,"source popup opens fully inside the viewport")
equal(view.sourceRows[1].label:GetText(),"Current setup","current setup is always first source")
view.sourceNext.OnClick(view.sourceNext)
equal(view.sourcePage,2,"many character sources are paged")
view.sourceRows[3].OnClick(view.sourceRows[3])
equal(view.sourceIndex,9,"source choice selects exact paged character")
equal(view.sourcePopup:IsShown(),false,"source picker closes after choosing")
view.name:SetText("Selected alt copy");view.copy.OnClick(view.copy)
equal(p:Find(view.selected)~=nil,true,"selected character source saves a named copy")
view.source.OnClick(view.source);gui:Select("overview")
equal(view.sourcePopup:IsShown(),false,"navigation dismisses the source popup")
gui:Select("profiles")
for i=3,8 do p:Create("Extra "..i) end
view:Refresh();view.next.OnClick(view.next)
equal(view.page,2,"saved profile list supports a second page")
view.rows[1].OnClick(view.rows[1])
equal(view.selected,p.store.entries[7].id,"paged profile row selects correct saved ID")
view.delete.OnClick(view.delete)
equal(view.removing,view.selected,"deletion requires explicit review")
local retained=view.selected;view.cancel.OnClick(view.cancel)
equal(p:Find(retained)~=nil,true,"cancelling deletion preserves profile")
view.delete.OnClick(view.delete);view.confirm.OnClick(view.confirm)
equal(p:Find(retained),nil,"confirmed deletion removes only selected unused profile")
equal(p:Review("default",secret),nil,"restricted scope cannot be used in a condition")
equal(p:Activate({id="default",personal=secret,values={}}),false,"restricted activation scope rejected")
equal(p:Activate({id="default",personal="yes",values={}}),false,"nonboolean activation scope rejected")
-- Review text and every action remain reachable even for a large settings change.
local many=p:Create("Review many")
for key,value in pairs(p:Find(many).values) do if type(value)=="boolean" then p:Find(many).values[key]=not value end end
view:Review(many,false)
equal(view.reviewText:GetHeight()>62,true,"review expands to disclose a large change set")
equal(-view.confirm.point[3]>=562+view.reviewText:GetHeight(),true,"confirmation follows all review text")
equal(view.panel:GetHeight()>=-view.confirm.point[3]+view.confirm:GetHeight(),true,"expanded form includes final action")
equal(gui.contentHeight>=view.panel:GetHeight()+36,true,"expanded review can scroll above footer")
view.cancel.OnClick(view.cancel)
-- First construction in combat is deferred and cancelled by navigation.
local builtPanel=view.panel
view.panel=nil;Combat(true);view:Build()
equal(type(Suite.pending.profilesBuild),"function","first profile panel construction defers in combat")
view:Dismiss()
equal(Suite.pending.profilesBuild,nil,"navigation cancels deferred construction")
view.panel=builtPanel;Combat(false)
-- Missing native reload function retains the chosen assignment and gives an actionable fallback.
ReloadUI=nil
local ok,message=p:Activate(p:Review("p1",false))
equal(ok,true,"selection persists if reload helper is unavailable")
equal(message,"Selection saved. Type /reload to apply it.","reload fallback is explicit")
equal(db.quickLoot,false,"fallback does not partially hot-apply settings")
Suite.db,WoWForeverSuiteDB,WoWForeverSuiteCharDB=old.db,old.account,old.character
p.store,p.state,p.activeID,p.activePersonal,p.guid,p.reloadPending=old.store,old.state,old.id,old.personal,old.guid,old.pending
UnitGUID,UnitName,GetNormalizedRealmName,ReloadUI=old.unit,old.name,old.realm,old.reload
Suite.Apply,Suite.loadedSavedVariables=old.apply,old.loaded
Suite.Leveling.db,Suite.Training.db,Suite.macroDB=old.leveling,old.training,old.macros
Suite.Scoring.character,Suite.Scoring.owner=old.scoring,old.scoreOwner
Combat(false);gui:Select(old.page or "overview");gui.frame:SetShown(old.shown)
