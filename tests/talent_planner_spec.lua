local Suite, equal, Frame, SetCombat = ...
local planner = Suite.TalentPlanner
local globals = { "C_Traits", "C_ClassTalents", "C_Spell", "UnitClass", "PlayerSpellsFrame", "PlayerSpellsUtil", "RegisterStateDriver", "UnregisterStateDriver",
    "CreateFrame", "C_Timer", "hooksecurefunc", "IsShiftKeyDown", "GameTooltip", "UnitLevel" }
local old, state, db, pending = {}, {}, Suite.db, Suite.pending
for _, name in ipairs(globals) do old[name] = _G[name] end
for key, value in pairs(planner) do state[key] = value end
Suite.db, Suite.pending = Suite.Copy(Suite.defaults), {}
planner.guideDB={}
SetCombat(false)
local made, timers, registrations, writes = 0, {}, {}, 0
local function Drain()
    local work = timers; timers = {}
    for _, timer in ipairs(work) do if not timer.cancelled then timer.callback() end end
end
CreateFrame = function(...)
    assert(not InCombatLockdown(), "planner must not construct during combat")
    made = made + 1
    local frame = old.CreateFrame(...)
    frame.IsForbidden = function() return false end
    frame.SetDesaturated = function(self, value) self.desaturated = value end
    frame.SetFocus = function(self) self.focused = true end
    frame.HighlightText = function(self) self.highlighted = true end
    frame.RegisterEvent = function(self, event) self.registered = self.registered or {}; self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    if select(4, ...) == "InputScrollFrameTemplate" then
        frame.EditBox = CreateFrame("EditBox", nil, frame); frame.CharCount = Frame()
    end
    local texture = frame.CreateTexture
    frame.CreateTexture = function(...)
        local result = texture(...); result.SetDesaturated = function(self, value) self.desaturated = value end; return result
    end
    return frame
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
RegisterStateDriver = function(frame, key, value) registrations[#registrations + 1] = { frame, key, value } end
UnregisterStateDriver = function() end
hooksecurefunc = function(object, key, callback)
    local original = object[key]; object[key] = function(...) local result = original(...); callback(...); return result end
end
local class, inspecting, config, tree, hashByte, staged = "MAGE", false, 7, 11, 1, false
local level, unspent, spent, excludeStaged = 14, 3, 2, nil
UnitLevel = function() return level end
UnitClass = function() return "Mage", class end
local native = {}
for _, id in ipairs({101,102}) do native[id] = Frame(); native[id].IsForbidden = function() return false end; native[id]:Show() end
local host = Frame(); host:Show(); host.IsForbidden = function() return false end
host.ClassBackground, host.ApplyButton = Frame(), Frame()
local treeHeader=Frame();treeHeader.IsForbidden=function()return false end;treeHeader.displayInfo={groupID=1};treeHeader.Text=Frame();treeHeader.Text:SetText("2")
host.treeHeaders={treeHeader}
host.IsInspecting = function() return inspecting end
host.GetConfigID = function() return config end
host.GetTalentTreeID = function() return tree end
host.GetTalentButtonByNodeID = function(_, id) return native[id] end
host.SetConfigID = function(_, value) config = value end
PlayerSpellsFrame = { TalentsFrame = host }
PlayerSpellsUtil = { OpenToClassTalentsTab = function() host:Show() end }
local nodes = {
    [101] = { isVisible = true, maxRanks = 5, ranksPurchased = 2, entryIDs = {201}, activeEntry = {entryID=201},
        flags=0,type=0,activeRank=2,ranksIncreased=0,groupIDs={1},conditionIDs={},posX=0,posY=0,
        visibleEdges={{targetNode=102,type=3}} },
    [102] = { isVisible = true, maxRanks = 1, ranksPurchased = 0, entryIDs = {202,203},
        flags=0,type=2,activeRank=0,ranksIncreased=0,groupIDs={1},conditionIDs={301},posX=400,posY=400,visibleEdges={} },
}
C_Traits = {
    GetTreeHash = function() local h={}; for i=1,16 do h[i]=hashByte end; return h end,
    GetTreeNodes = function() return {102,101} end,
    GetNodeInfo = function(_, id) return nodes[id] end,
    GetEntryInfo = function(_, id) return {maxRanks=id==201 and 5 or 1,definitionID=id+1000,conditionIDs={}} end,
    GetDefinitionInfo = function(id) return {spellID=id+1000} end,
    GetGroupDisplayInfoByTreeID = function() return {{groupID=1,displayName="Arcane"},{groupID=2,displayName="Fire"},{groupID=3,displayName="Frost"}} end,
    GetNodeCost=function()return {{ID=1,amount=1}}end,
    GetConditionInfo=function()return {type=0,isAlwaysMet=false,isSufficient=false,isGate=true,spentAmountRequired=5,traitCurrencyID=1}end,
    ConfigHasStagedChanges = function() return staged end,
    GetTreeCurrencyInfo = function(_, _, exclude)
        excludeStaged = exclude; return {{quantity=unspent,spent=spent},{quantity=999,spent=999}}
    end,
}
for _, method in ipairs({"PurchaseRank","RefundRank","SetSelection","StageConfig","CommitConfig","RollbackConfig","ResetTree"}) do
    C_Traits[method] = function() writes=writes+1; error("planner must never mutate native talents") end
end
C_Spell = { GetSpellInfo = function(id) return {name="Spell "..id,iconID=134400} end }
IsShiftKeyDown = function() return false end
GameTooltip = Frame(); GameTooltip.SetOwner = function() end; GameTooltip.SetSpellByID = function() end
local before = made
planner:Apply(); equal(made, before, "default-off planner creates nothing")
equal(planner:Snapshot(), nil, "disabled planner never reads a tree")
Suite.db.talentPlanner = true; planner:Apply()
equal(planner.model.class, "MAGE", "modern Forever trait tree loads by class")
equal(planner.model.order[1], 101, "node order is deterministic")
equal(#planner.model.groups, 3, "sidebar knows the three native tree names")
equal(registrations[1][3], "[combat] hide; show", "secure driver hides all owned input in combat")
equal(planner.overlay:IsShown(), false, "opening native talents never starts editing")
planner:Open()
equal(planner.panel:IsShown(), true, "slash opens right-side build panel")
planner:New("Leveling")
equal(planner.budgetText:GetText(),"At level 14 you have 5 talent points to spend with |cff66dd775|r remaining.","empty draft uses full earned budget in green")
equal(planner.headers[1].text:GetText(),"0","draft replaces visible tree count with its own empty allocation")
equal(planner.headers[1]:GetWidth(),300,"draft heading reserves space for its tree name and adjacent total")
equal(planner.headers[1]:GetHeight(),56,"draft heading covers the dim native portrait counter and name")
equal(planner.headers[1].text.fontSize,16,"draft total uses a larger font")
equal(planner.headers[1].text.fontFlags,"OUTLINE","draft total stays readable over native artwork")
equal(treeHeader.Text:GetText(),"2","native tree count is never changed")
equal(planner.edgeFrames[1]~=nil,true,"draft creates owned connection graphics")
equal(excludeStaged,true,"budget excludes native staged changes")
equal(planner.overlay:IsShown(), true, "new draft activates preview overlay")
equal(planner.footer:IsShown(), true, "draft overlays native apply footer")
equal(planner.buildLevelText:GetText(),"No talent points selected.","empty draft has no invented minimum level")
equal(planner.resetButton.enabled,false,"empty draft disables the reset action")
equal(planner.resetButton.point[2],planner.rulesButton,"reset draft sits beside the current-level toggle")
equal(planner.resetButton.point[3],"TOPLEFT","reset draft anchors immediately to the toggle's left edge")
equal(planner:BaselineLevelText(31),"Without bonus talent points: level 40 for 31 planned points.","31 points use the level-10 first-point baseline, not level 41")
equal(planner:BaselineLevelText(51),"Without bonus talent points: level 60 for 51 planned points.","full ordinary baseline stops at level 60")
equal(planner:BaselineLevelText(52),"More than 51 points: bonus talent points required at level 60.","over-baseline drafts do not invent a level beyond 60")
equal(planner:BaselineLevelText({secret=true}),"Point baseline unavailable.","restricted point totals are never formatted")
equal(planner.buttons[101].allPoints, native[101], "draft input follows exact native button geometry")
equal(planner:Current().ranks[101], nil, "new empty draft has no native points")
equal(planner.buttons[101].icon.desaturated,true,"unspent first-tier talent stays grey despite native ranks")
equal(planner.buttons[101].borderColor[1],1,"available first-tier talent has an orange outline")
equal(planner.buttons[101].borderColor[2],0.62,"available outline uses the draft availability color")
equal(planner.buttons[102].icon.desaturated,true,"locked next-row talent stays grey")
equal(planner.buttons[102].borderColor[1],0.55,"locked next-row talent has a neutral outline")
nodes[102].ranksPurchased,nodes[102].activeRank,nodes[102].activeEntry=1,1,{entryID=202}
planner:Refresh()
equal(planner.buttons[102].icon.desaturated,true,"native spending cannot color a talent in an empty draft")
equal(planner.buttons[102].borderColor[1],0.55,"native spending cannot orange-outline a draft-locked talent")
nodes[102].ranksPurchased,nodes[102].activeRank,nodes[102].activeEntry=0,0,nil
planner:Refresh()
planner:Change(101,1)
equal(planner.budgetText:GetText():find("|cff66dd774|r remaining.",1,true)~=nil,true,"adding a draft rank immediately decreases remaining points")
equal(planner:Current().ranks[101].rank, 1, "left click adds a draft rank")
equal(planner.buildLevelText:GetText(),"Without bonus talent points: level 10 for 1 planned point.","draft edits immediately refresh the level line beneath the real budget")
equal(planner.resetButton.enabled,true,"allocating a draft rank enables reset")
equal(planner.buttons[101].icon.desaturated,false,"spending a draft point colors its icon")
equal(planner.buttons[101].borderColor[1],1,"partially filled talent outlines an available next rank")
equal(planner.buttons[102].borderColor[1],0.55,"one draft point cannot color a locked tier")
equal(nodes[101].ranksPurchased, 2, "editing leaves native ranks alone")
for i=1,10 do planner:Change(101,1) end
equal(planner:Current().ranks[101].rank,5,"draft ranks stop at max")
equal(planner.buttons[101].borderColor[1],0.41,"maxed draft talent loses its available outline")
equal(planner.buttons[102].icon.desaturated,true,"newly unlocked tier keeps grey icons until selected")
equal(planner.buttons[102].borderColor[1],1,"five draft points outline the newly unlocked next tier")
Suite.db.talentPlannerRules=true;planner:Render()
equal(planner.buttons[102].borderColor[1],0.55,"exhausted current-level budget removes availability outlines")
Suite.db.talentPlannerRules=false;planner:Render()
equal(planner.buttons[102].borderColor[1],1,"planning ahead restores structurally available outlines")
equal(planner.headers[1].text:GetText(),"5","draft header tracks its full group allocation")
equal(planner.budgetText:GetText():find("|cffffd24d0|r remaining.",1,true)~=nil,true,"exactly allocated budget is yellow")
planner:History(false); equal(planner:Current().ranks[101].rank,4,"undo restores previous draft")
equal(planner.buttons[102].borderColor[1],0.55,"undo below a tier threshold removes its available outline")
equal(planner.budgetText:GetText():find("|cff66dd771|r remaining.",1,true)~=nil,true,"undo restores positive green balance")
planner:History(true); equal(planner:Current().ranks[101].rank,5,"redo restores draft edit")
equal(planner.buttons[102].borderColor[1],1,"redo restores availability for the unlocked tier")
local resetBuild,resetHistory=planner:Current(),#planner.undo
local resetSequence=Suite.Copy(resetBuild.sequence)
planner.resetButton.OnClick()
equal(planner:Current(),resetBuild,"reset preserves the selected draft identity")
equal(next(resetBuild.ranks),nil,"reset clears all selected draft ranks")
equal(#resetBuild.sequence,0,"reset clears the saved draft point order")
equal(#planner.undo,resetHistory+1,"reset is one undoable operation")
equal(nodes[101].ranksPurchased,2,"reset never refunds native learned talents")
equal(planner.buildLevelText:GetText(),"No talent points selected.","reset updates the level footer immediately")
local emptyHistory=#planner.undo
planner:ResetDraft()
equal(#planner.undo,emptyHistory,"resetting an empty draft adds no empty history entry")
planner:History(false)
equal(resetBuild.ranks[101].rank,5,"Undo restores all ranks cleared by reset")
equal(#resetBuild.sequence,#resetSequence,"Undo restores the draft's saved point order")
planner:History(true)
equal(next(resetBuild.ranks),nil,"Redo clears the draft again")
planner:History(false)
planner:Change(102,1,true)
equal(planner.budgetText:GetText():find("|cffff5555-1|r remaining.",1,true)~=nil,true,"overspending remains permitted and displays a negative red balance")
equal(planner:Current().ranks[102].entry,203,"shift click cycles choice without native selection writes")
planner:Change(102,-1)
equal(planner:Current().ranks[102],nil,"right click removes final draft rank")
equal(planner.budgetText:GetText():find("|cffffd24d0|r remaining.",1,true)~=nil,true,"refunding restores zero yellow balance")
level,unspent=15,4
planner.events.OnEvent(planner.events,"PLAYER_LEVEL_UP"); Drain()
equal(planner.budgetText:GetText(),"At level 15 you have 6 talent points to spend with |cff66dd771|r remaining.","level-up refresh keeps draft and updates earned budget")
unspent={secret=true}; planner:Render()
equal(planner.budgetText:GetText(),"At level 15, your talent-point budget is unavailable.","secret budget is not compared or formatted")
unspent=4; spent=-1; planner:Render()
equal(planner.budgetText:GetText():find("unavailable",1,true)~=nil,true,"invalid native spending does not invent a budget")
spent=2; level={secret=true}; planner:Render()
equal(planner.budgetText:GetText(),"Your level and talent-point budget are unavailable.","secret level is not compared or formatted")
level=9;unspent=0;spent=0;planner:Render()
equal(planner.budgetText:GetText(),"At level 9 you have 0 talent points to spend with |cffff5555-5|r remaining.","zero earned budget remains valid for a below-talent-level draft")
level=14;unspent=3;spent=2;planner:Render()
equal(planner:Rename("Raid |cffffff"),nil,"build names reject formatting")
planner:Rename("Raid")
equal(planner:Current().name,"Raid","rename persists")
local code = planner:Export()
equal(type(code),"string","export returns copyable Suite code")
planner:Import(code)
equal(#planner:Library(),2,"valid build code creates a separate draft")
equal(planner:Current().ranks[101].rank,5,"import preserves ranks")
local count = #planner:Library()
planner:Import(code..",")
planner:Import(code:gsub("101%.201%.5","101.201.6"))
planner:Import(code..",101.201.1")
planner:Import(code:gsub("MAGE","DRUID"))
planner:Import(code:gsub("101%.201%.5","101.999.1"))
planner:Import(string.rep("x",16385))
equal(#planner:Library(),count,"malformed, duplicate, wrong-class and oversized imports are atomic")
planner:Store({[101]={entry=201,rank=0}},true)
equal(planner:Current().ranks[101].rank,5,"malformed rank records cannot overwrite drafts")
equal(planner:Validate({[101]={entry={secret=true},rank=1}}),nil,"secret choice IDs are rejected before key lookup")
equal(planner:Validate({[{secret=true}]={entry=201,rank=1}}),nil,"secret node keys are rejected")
nodes[101].maxRanks={secret=true}
equal(planner:Snapshot(),nil,"unreadable rank bounds reject entire snapshot")
nodes[101].maxRanks=5
nodes[101].activeEntry.entryID={secret=true}
equal(planner:Snapshot(),nil,"unreadable active entries reject snapshot")
nodes[101].activeEntry.entryID=201
staged=true; planner:Refresh()
equal(planner.status:GetText():find("uncommitted",1,true)~=nil,true,"native staged ranks are disclosed")
staged=false
hashByte=2; planner:Refresh()
equal(planner.selected,nil,"tree revision change clears selected draft")
planner:Select(1)
equal(planner.selected,nil,"old revision is retained but cannot be loaded")
equal(#planner:Library(),count,"tree revision changes preserve saved builds")
hashByte=1; planner:Refresh(); planner:Select(1)
local ranks=Suite.Copy(planner:Current().ranks)
inspecting=true
planner:Change(101,-1)
equal(planner:Current().ranks[101].rank,ranks[101].rank,"inspection transition blocks stale preview input immediately")
planner:Refresh()
equal(planner.panel:IsShown(),false,"inspect mode suppresses companion")
equal(planner.overlay:IsShown(),false,"inspect mode suppresses draft")
inspecting=false; planner:Refresh(); planner:Select(1)
config=8
planner:Change(101,-1)
equal(planner:Current().ranks[101].rank,ranks[101].rank,"spec transition blocks stale edits before queued refresh")
planner:Refresh(); equal(planner.selected,nil,"spec transition returns to native talents")
planner:New("Other spec",planner.model.native)
equal(planner:Current().ranks[101].rank,2,"copy native uses current shown ranks")
class="DRUID"; planner:Refresh()
equal(#planner:Library(),0,"class libraries stay separate")
class="MAGE"; planner:Refresh(); equal(#planner:Library(),count+1,"class library survives revisiting")
planner:Select(1)
for i=1,60 do planner:Change(101, i%2==0 and 1 or -1) end
equal(#planner.undo,50,"undo history is bounded")
before=made
local combatResetRanks=planner:Current().ranks
SetCombat(true)
planner:ResetDraft()
equal(planner:Current().ranks,combatResetRanks,"combat reset cannot replace draft allocations")
planner:New("Combat"); planner:Change(101,-1); planner:Delete(); planner:Import(code); planner:Refresh(); planner:Open()
equal(made,before,"combat callbacks cannot create frames")
equal(#planner:Library(),count+1,"combat callbacks cannot modify saved builds")
Suite.db.talentPlanner=false; planner:Apply()
equal(type(Suite.pending.talentPlanner),"function","disable defers protected visibility until after combat")
SetCombat(false); Suite.pending.talentPlanner(); Suite.pending.talentPlanner=nil
equal(planner.root:IsShown(),false,"deferred disable hides owned root")
equal(planner.driver,nil,"disable releases driver so later combat cannot resurrect disabled UI")
equal(next(planner.events.registered),nil,"disable removes all feature events")
Suite.db.talentPlanner=true; planner:Apply(); planner:Select(1)
planner:Queue(); planner:Queue()
equal(planner.timer~=nil,true,"refreshes coalesce")
Suite.db.talentPlanner=false; planner:Apply(); Drain()
equal(planner.timer,nil,"disable cancels queued refresh")
equal(planner.root:IsShown(),false,"cancelled refresh cannot reopen disabled planner")
Suite.db.talentPlanner=true; planner:Apply(); planner:Select(1); planner:Delete()
equal(#planner:Library(),count,"delete removes only selected draft")
equal(planner.preview,false,"delete returns to native view")
planner:Select(1);planner:Store({},true)
Suite.db.talentPlannerRules=true
planner:Change(102,1)
equal(planner:Current().ranks[102],nil,"rules mode rejects a missing prerequisite")
equal(planner.status:GetText():find("Requires 5/5",1,true)~=nil,true,"rejected purchase names the prerequisite rank requirement")
for i=1,5 do planner:Change(101,1) end
planner:Change(102,1)
equal(planner:Current().ranks[102],nil,"rules mode rejects overspending current budget")
unspent=4;planner:Change(102,1)
equal(planner:Current().ranks[102].rank,1,"known prerequisite and gate allow purchase when budget permits")
local beforeUndo=#planner.undo
planner:Change(101,-1)
equal(planner:Current().ranks[101].rank,5,"rules mode refuses a refund that breaks a purchased descendant")
equal(#planner.undo,beforeUndo,"rejected edits leave history unchanged")
Suite.db.talentPlannerRules=false;planner:Change(101,-1)
equal(planner:Current().ranks[101].rank,5,"planning ahead still refuses a refund that breaks prerequisites")
equal(planner.analysis.blocked[102],nil,"rejected planning edit leaves the tree valid")
-- Preserve and repair invalid drafts saved by the earlier unrestricted planner.
planner:Current().ranks[101].rank=4;planner:Render()
equal(planner.analysis.blocked[102]~=nil,true,"older invalid drafts are retained and marked for repair")
Suite.db.talentPlannerRules=true;planner:Change(102,-1)
equal(planner:Current().ranks[102],nil,"rules mode can repair an existing invalid draft")
Suite.db.talentPlannerRules=false;planner:Current().ranks={[102]={entry=202,rank=1}};planner:Render();Suite.db.talentPlannerRules=true
planner:Change(101,1)
equal(planner:Current().ranks[101].rank,1,"rules mode permits incremental valid prerequisite repairs")
for i=1,4 do planner:Change(101,1) end
equal(planner:Analyze(planner:Current().ranks,true).valid,true,"incremental repairs can restore a complete legal draft")
local rules=planner.model.rules
local oldIncoming=rules[102].incoming
rules[102].incoming={};rules[102].conditions={{type=0,spent=5,currency=1,group=1}}
local analysis=planner:Analyze({[102]={entry=202,rank=1}},false)
equal(analysis.valid,false,"a gated talent cannot count its own point toward its unlock")
rules[102].conditions={{type=0,spent=1,currency=1,group=2}}
analysis=planner:Analyze({[101]={entry=201,rank=5},[102]={entry=202,rank=1}},false)
equal(analysis.valid,false,"spending in another group cannot satisfy a tree gate")
rules[102].conditions={{type=0,spent=1,currency=1,group=1}}
analysis=planner:Analyze({[101]={entry=201,rank=1},[102]={entry=202,rank=1}},false)
equal(analysis.valid,true,"native gate threshold is honored without a hardcoded tier formula")
rules[102].incoming={{from=101,to=102,type=2}}
analysis=planner:Analyze({[101]={entry=201,rank=1},[102]={entry=202,rank=1}},false)
equal(analysis.valid,false,"sufficient connection requires max rank by default")
rules[101].firstRank=true
analysis=planner:Analyze({[101]={entry=201,rank=1},[102]={entry=202,rank=1}},false)
equal(analysis.valid,true,"ActiveAtFirstRank nodes unlock a sufficient connection at one rank")
rules[102].incoming={{from=101,to=102,type=4}}
analysis=planner:Analyze({[101]={entry=201,rank=1},[102]={entry=202,rank=1}},false)
equal(analysis.valid,false,"mutually exclusive nodes cannot both be purchased")
rules[102].incoming=oldIncoming;rules[101].firstRank=false
rules[102].conditions={{type=0,always=true,sufficient=true},{type=0,spent=100,currency=1,group=1}}
analysis=planner:Analyze({[101]={entry=201,rank=5},[102]={entry=202,rank=1}},false)
equal(analysis.valid,true,"a sufficient condition satisfies conditions of the same type")
rules[102].conditions={{type=5,level=20}}
analysis=planner:Analyze({[101]={entry=201,rank=5},[102]={entry=202,rank=1}},true)
equal(analysis.valid,false,"explicit level requirements use player level")
analysis=planner:Analyze({[101]={entry=201,rank=5},[102]={entry=202,rank=1}},false)
equal(analysis.valid,true,"planning ahead ignores current level while retaining prerequisites")
rules[102].conditions={{type=0,unknown=true}}
analysis=planner:Analyze({[101]={entry=201,rank=5},[102]={entry=202,rank=1}},false)
equal(analysis.valid,false,"unknown conditions fail closed")
planner:Store({[101]={entry=201,rank=5}},false)
planner.undo={ {[102]={entry=202,rank=1}} };planner.redo={}
planner:History(false)
equal(#planner.undo,1,"rejected undo retains its source history entry")
equal(#planner.redo,0,"rejected undo does not add a redo entry")
equal(planner:Current().ranks[101].rank,5,"rejected undo leaves saved ranks unchanged")
nodes[101].flags={secret=true};planner:Refresh()
equal(planner.model.rules[101].unknown,true,"unreadable flags cannot enable validated editing")
nodes[101].flags=0;planner:Refresh()
local conditionGetter=C_Traits.GetConditionInfo
C_Traits.GetConditionInfo=function()return {type={secret=true}}end
planner:Refresh()
equal(planner.model.rules[102].unknown,true,"secret condition types are rejected before comparison")
C_Traits.GetConditionInfo=conditionGetter
local groupGetter=C_Traits.GetGroupCurrencyInfo
C_Traits.GetGroupCurrencyInfo=function()return {{traitNodeGroupID=1,currencyInfos={{traitCurrencyID=1}}}}end
C_Traits.GetConditionInfo=function()return {type=0,isAlwaysMet=false,isSufficient=false,isGate=true,spentAmountRequired=5}end
planner:Refresh()
equal(planner.model.rules[102].conditions[1].currency,1,"group-specific gate resolves its currency from native group metadata")
C_Traits.GetConditionInfo=conditionGetter;C_Traits.GetGroupCurrencyInfo=groupGetter
nodes[101].visibleEdges={{targetNode=102,type=3},{targetNode=102,type=2}}
planner:Refresh()
equal(planner.model.rules[102].unknown,true,"mixed incoming edge policies are not guessed")
nodes[101].visibleEdges={{targetNode={secret=true},type=3}}
planner:Refresh()
equal(planner.model.rules[101].unknown,true,"secret edge targets never enter lookup tables")
nodes[101].visibleEdges={{targetNode=102,type=3}};planner:Refresh()
planner.model.rules[102].unknown=true
planner:Select(1)
beforeUndo=#planner.undo
planner:History(true)
equal(#planner.undo,beforeUndo,"empty redo stays atomic in rules mode")
planner.preview=false;planner:Render()
equal(planner.headers[1]:IsShown(),false,"returning to native hides all owned header overlays")
equal(planner.edgeFrames[1]:IsShown(),false,"returning to native hides owned connections")
equal(treeHeader.Text:GetText(),"2","native header content survives draft editing unchanged")
-- Forever per-row spending conditions need not be marked as visual tree gates.
local savedEntryGetter=C_Traits.GetEntryInfo
local savedConditionGetter=C_Traits.GetConditionInfo
C_Traits.GetConditionInfo=function()return {type=0,isAlwaysMet=false,isSufficient=false,isGate=false,spentAmountRequired=5,traitCurrencyID=1}end
C_Traits.GetEntryInfo=function(_,id)return {maxRanks=5,definitionID=id+1000,conditionIDs={}}end
nodes[102].maxRanks=5;nodes[102].type=0;nodes[102].entryIDs={202}
nodes[101].visibleEdges={}
planner:Refresh();planner.expanded=true;planner:Select(1)
Suite.db.talentPlannerRules=false;planner:Store({},false);Suite.db.talentPlannerRules=true
planner:Change(102,1)
equal(planner:Current().ranks[102],nil,"row two stays locked before five points in its tree")
for i=1,5 do planner:Change(101,1) end
planner:Change(102,1)
equal(planner:Current().ranks[102] and planner:Current().ranks[102].rank,1,"five first-row points unlock a multi-rank non-visual spending condition")
unspent=5
C_Traits.GetConditionInfo=function()return {type=5,isAlwaysMet=false,isSufficient=false,isGate=false,playerLevel=10}end
planner:Refresh();planner:Change(102,1)
equal(planner:Current().ranks[102].rank,2,"a simple minimum level does not disable all ranks of a multi-rank talent")
C_Traits.GetConditionInfo=function()return {type=5,isAlwaysMet=false,isSufficient=false,isGate=false,playerLevel=20}end
planner:Refresh();planner:Change(102,1)
equal(planner:Current().ranks[102].rank,2,"multi-rank talents still enforce an unmet minimum level")
equal(planner.buttons[102].borderColor[2],0.33,"unmet level on an allocated draft shows a warning rather than availability")
C_Traits.GetConditionInfo=function()return {type=5,isAlwaysMet=false,isSufficient=false,isGate=false,playerLevel=10,ranksGranted=1}end
planner:Refresh()
equal(planner.model.rules[102].conditions[1].unknown,true,"an explicit partial rank cap is not treated as an unrestricted level gate")
equal(planner.buttons[102].borderColor[1],1,"invalid allocated draft talent retains a warning outline")
equal(planner.buttons[102].borderColor[2],0.33,"unknown allocated requirements use red rather than orange availability")
-- A support report must expose the actual native rule rather than guess why a
-- screenshot's generic unavailable message appeared.
local oldPrint, report = Suite.Print, {}
Suite.Print=function(message) report[#report+1]=message end
local reportModel, reportBuild = planner.model, planner:Current()
local reportRank = reportBuild.ranks[102].rank
planner:Status(2202)
local reportText=table.concat(report,"\n")
equal(reportText:find("spell=2202 node=102 entry=202",1,true)~=nil,true,"talent report resolves the exact requested spell")
equal(reportText:find("ranksGranted=1",1,true)~=nil,true,"talent report includes partial-rank metadata")
equal(reportText:find("playerLevel=10",1,true)~=nil,true,"talent report includes actual native level metadata")
equal(planner.model,reportModel,"talent report does not replace the editing model")
equal(planner:Current(),reportBuild,"talent report preserves the selected saved draft")
equal(reportBuild.ranks[102].rank,reportRank,"talent report never rewrites saved ranks")
C_Traits.GetConditionInfo=function()return {type=5,isAlwaysMet=false,isSufficient=false,isGate=false,playerLevel={secret=true},ranksGranted={secret=true}}end
report={};planner:Status(2202)
reportText=table.concat(report,"\n")
equal(reportText:find("playerLevel=unreadable",1,true)~=nil,true,"talent report never formats restricted level data")
equal(reportText:find("ranksGranted=unreadable",1,true)~=nil,true,"talent report never formats restricted rank data")
local reportGetter=C_Traits.GetNodeInfo
C_Traits.GetNodeInfo=function()error("combat report must not read talent nodes")end
SetCombat(true);report={};planner:Status(2202);SetCombat(false)
equal(#report,1,"combat talent report returns a single outside-combat instruction")
C_Traits.GetNodeInfo=reportGetter
Suite.Print=oldPrint
C_Traits.GetConditionInfo=function()return {type=0,isAlwaysMet=false,isSufficient=false,isGate=false,spentAmountRequired=5,traitCurrencyID=1,playerLevel=20}end
planner:Refresh()
equal(planner:Analyze(planner:Current().ranks,true).blocked[102],"Requires level 20.","current-level mode retains a simultaneous level requirement")
Suite.db.talentPlannerRules=false;planner:Change(102,1)
equal(planner:Current().ranks[102].rank,3,"planning ahead allows future-level ranks beyond the current budget")
planner:Store({},false)
planner:Change(102,1)
equal(planner:Current().ranks[102],nil,"planning ahead cannot skip a tree tier")
local buildCount=#planner:Library()
planner:New("Invalid capstone",{[102]={entry=202,rank=1}})
equal(#planner:Library(),buildCount,"new drafts cannot bypass structural requirements")
local emptyCode=planner:Export()
planner:Import(emptyCode.."102.202.1")
equal(#planner:Library(),buildCount,"imports cannot bypass structural requirements")
C_Traits.GetEntryInfo=savedEntryGetter;C_Traits.GetConditionInfo=savedConditionGetter
-- Turning the level limit back on repairs only the selected draft in one step.
C_Traits.GetEntryInfo=function(_,id)return {maxRanks=5,definitionID=id+1000,conditionIDs={}}end
C_Traits.GetConditionInfo=function()return {type=0,isAlwaysMet=false,isSufficient=false,isGate=false,spentAmountRequired=5,traitCurrencyID=1}end
level,unspent,spent=14,1,2
Suite.db.talentPlannerRules=false;planner:Apply()
local futureRanks={[101]={entry=201,rank=5},[102]={entry=202,rank=3}}
planner:New("Future draft",futureRanks)
local futureIndex=planner.selected
local selectedBuild=planner:Current()
planner:New("Keep other draft",futureRanks)
local otherBuild=planner:Current()
planner:Select(futureIndex)
Suite.db.talentPlannerRules=true;planner:Apply()
equal(selectedBuild.ranks[101].rank,3,"enabling limit keeps lower-tier ranks up to earned budget")
equal(selectedBuild.ranks[102],nil,"enabling limit removes unsupported descendants")
equal(planner:Analyze(selectedBuild.ranks,true).valid,true,"trimmed draft obeys structure and level budget")
equal(otherBuild.ranks[102].rank,3,"limit transition only changes the selected draft")
equal(#planner.undo,1,"automatic trimming creates one undo step")
planner:History(false)
equal(selectedBuild.ranks[101].rank,3,"undo cannot restore over-budget ranks with limit on")
equal(#planner.undo,1,"rejected restoration preserves the trim undo step")
Suite.db.talentPlannerRules=false;planner:Apply();planner:History(false)
equal(selectedBuild.ranks[101].rank,5,"turning limit off allows undoing trim")
equal(selectedBuild.ranks[102].rank,3,"undo restores original future choices and ranks")
equal(#planner.redo,1,"undo of automatic trim remains redoable")
planner:History(true)
equal(selectedBuild.ranks[101].rank,3,"redo reapplies the single trim operation")
planner:History(false)
unspent=8
C_Traits.GetConditionInfo=function()return {type=0,isAlwaysMet=false,isSufficient=false,isGate=false,spentAmountRequired=5,traitCurrencyID=1,playerLevel=20}end
Suite.db.talentPlannerRules=true;planner:Apply()
equal(selectedBuild.ranks[101].rank,5,"trim preserves legal allocation with spare budget")
equal(selectedBuild.ranks[102],nil,"trim removes future-level talents even with spare points")
equal(planner:Analyze(selectedBuild.ranks,true).valid,true,"level trim does not strand prerequisites")
Suite.db.talentPlannerRules=false;planner:Apply();planner:History(false)
equal(selectedBuild.ranks[102].rank,3,"undo preserves the original future-level build")
local undoCount=#planner.undo
unspent={secret=true};Suite.db.talentPlannerRules=true;planner:Apply()
equal(selectedBuild.ranks[102].rank,3,"unreadable budget never erases planned ranks")
equal(#planner.undo,undoCount,"unreadable budget adds no destructive history entry")
equal(planner.status:GetText():find("unavailable",1,true)~=nil,true,"unavailable trim explains draft retention")
unspent=1;Suite.db.talentPlannerRules=false;planner:Apply()
Suite.db.talentPlannerRules=true;SetCombat(true);planner:Apply()
equal(selectedBuild.ranks[102].rank,3,"combat defers draft trim and layout")
SetCombat(false);Suite.pending.talentPlanner();Suite.pending.talentPlanner=nil
equal(selectedBuild.ranks[101].rank,3,"deferred limit enable trims after combat")
equal(selectedBuild.ranks[102],nil,"deferred trim removes invalid descendants")
Suite.db.talentPlannerRules=false;planner:Apply();planner:History(false)
unspent,spent=0,0;Suite.db.talentPlannerRules=true;planner:Apply()
equal(next(selectedBuild.ranks),nil,"zero earned budget clears the selected draft safely")
Suite.db.talentPlannerRules=false;planner:Apply();planner:History(false)
equal(selectedBuild.ranks[102].rank,3,"zero-budget clearing is undoable with limit off")
C_Traits.GetEntryInfo=savedEntryGetter;C_Traits.GetConditionInfo=savedConditionGetter
-- Build metadata stays attached to records while favorites reorder only the view.
planner.notice=nil;planner:Render()
equal(planner.status:GetText():find("6 ranks added · 0 ranks removed",1,true)~=nil,true,"comparison explains additions and removals in words")
planner:Message("Requires 3/3 Test.");planner:Render()
equal(planner.status:GetText():find("Requires 3/3 Test.",1,true)~=nil,true,"rejection messages survive queued renders")
-- Fengari accepts embedded NUL pattern bytes that the client's Lua 5.1
-- pattern parser truncates. Model that boundary for saved empty notes too.
local nativeFind=string.find
string.find=function(body,pattern,start,plain)
    if not plain and nativeFind(pattern,string.char(0),1,true) then error("malformed pattern (missing ']')") end
    return nativeFind(body,pattern,start,plain)
end
planner:SetNotes("")
equal(selectedBuild.notes,"","empty notes validate without embedding a NUL in a Lua 5.1 pattern")
planner:SetNotes("Leveling\nUse in dungeons.")
for _,byte in ipairs({0,1,8,11,12,14,31,127})do
    planner:SetNotes("Invalid"..string.char(byte))
    equal(selectedBuild.notes,"Leveling\nUse in dungeons.","control-byte notes are rejected without pattern errors")
end
string.find=nativeFind
equal(selectedBuild.notes,"Leveling\nUse in dungeons.","notes persist with the selected saved build")
equal(planner:Library()[futureIndex].notes,selectedBuild.notes,"normalizing saved library preserves notes")
planner:SetNotes("|cff00ff00bad");planner:SetNotes(string.rep("a",513));planner:SetNotes({secret=true})
equal(selectedBuild.notes,"Leveling\nUse in dungeons.","invalid, oversized and restricted notes cannot overwrite existing notes")
planner:ToggleFavorite()
equal(selectedBuild.favorite,true,"favorite preference is saved on its build")
equal(planner.visibleBuilds[1],futureIndex,"favorites appear before older ordinary builds")
local otherIndex
for index,build in ipairs(planner:Library())do if build==otherBuild then otherIndex=index end end
planner:Select(otherIndex);planner:ToggleFavorite()
equal(planner.visibleBuilds[1],futureIndex,"favorite ties retain stable original order")
planner.rows[1].OnClick()
equal(planner:Current(),selectedBuild,"reordered build rows select the displayed build rather than its old slot")
planner:OpenNotes();planner.notesEdit:SetText("Saved through the notes editor.")
planner.notesSave.OnClick()
equal(selectedBuild.notes,"Saved through the notes editor.","notes editor save writes only its selected build")
equal(planner.notesFrame:IsShown(),false,"successful note save closes the editor")
planner:OpenNotes();planner.notesEdit:SetText("Discard this.");planner.notesCancel.OnClick()
equal(selectedBuild.notes,"Saved through the notes editor.","cancel leaves saved notes intact")
planner:OpenNotes();planner.notesEdit:SetText("Wrong build.");planner:Select(otherIndex)
planner.notesSave.OnClick()
equal(otherBuild.notes,"","stale note editor cannot overwrite a newly selected build")
equal(planner.notesFrame:IsShown(),false,"switching builds dismisses the note editor")
planner:Select(futureIndex);planner.duplicate.OnClick()
local duplicate=planner:Current()
equal(duplicate.notes,selectedBuild.notes,"duplicate copies build notes")
equal(duplicate.favorite,false,"duplicate begins unfavorited")
planner:SetNotes("Independent duplicate.")
equal(selectedBuild.notes,"Saved through the notes editor.","editing duplicate notes leaves original notes intact")
duplicate.notes,duplicate.favorite={secret=true},{secret=true};planner:Library()
equal(duplicate.notes,"","restricted saved notes normalize without formatting")
equal(duplicate.favorite,false,"restricted saved favorite state cannot reorder the library")
planner:Select(futureIndex)
local oldName,oldMax=planner.model.nodes[101].entries[201].name,planner.model.nodes[101].max
planner.model.nodes[101].entries[201].name="Improved Rend";planner.model.nodes[101].max=3
planner.model.rules[102].incoming={{from=101,to=102,type=3}}
local requirement=planner:Analyze({[101]={entry=201,rank=1},[102]={entry=202,rank=1}},false)
equal(requirement.blocked[102],"Requires 3/3 Improved Rend (1/3 planned).","prerequisite message includes name and required/current ranks")
planner.model.nodes[101].entries[201].name=oldName;planner.model.nodes[101].max=oldMax
planner.model.rules[102].incoming={};planner.model.rules[102].conditions={{type=0,spent=5,currency=1,group=1}}
requirement=planner:Analyze({[101]={entry=201,rank=3},[102]={entry=202,rank=1}},false)
equal(requirement.blocked[102],"Spend 2 more points in Arcane.","gate tooltip reports remaining points and the affected tree")
local descriptions={}
C_Traits.GetTraitDescription=function(entry,rank)descriptions[#descriptions+1]={entry,rank};return "Effect at rank "..rank end
GameTooltip.SetText=function(self,text)self.text=text;self.lines={}end
GameTooltip.SetSpellByID=function()error("draft tooltip must not substitute native-rank effects")end
planner:Tooltip(planner.buttons[102])
equal(descriptions[1][1],202,"description request uses selected talent entry")
equal(descriptions[1][2],3,"description request uses actual draft rank")
equal(descriptions[2][2],4,"tooltip requests the next rank separately")
local function HasLine(text)for _,line in ipairs(GameTooltip.lines)do if line[1]==text then return true end end;return false end
equal(HasLine("Effect at rank 3"),true,"tooltip displays client-supplied draft-rank effects")
equal(HasLine("Effect at rank 4"),true,"tooltip displays client-supplied next-rank effects")
local requests=#descriptions
equal(planner:RankDescription(202,0),nil,"rank zero never asks client for misleading zero-rank effects")
equal(planner:RankDescription({secret=true},1),nil,"secret entry ID never reaches description getter")
equal(#descriptions,requests,"invalid description requests never call the API")
C_Traits.GetTraitDescription=function()return {secret=true}end
planner:Tooltip(planner.buttons[102])
equal(HasLine("Description unavailable for this rank."),true,"unreadable rank text has an explicit unavailable fallback")
C_Traits.GetTraitDescription=function()error("not ready")end
equal(planner:RankDescription(202,3),nil,"throwing description getter is contained")
C_Traits.GetTraitDescription=nil
equal(planner:RankDescription(202,3),nil,"missing description API does not invent effects")
local notesBefore=selectedBuild.notes;local favoriteBefore=selectedBuild.favorite
before=made;SetCombat(true)
planner:SetNotes("Combat write");planner:ToggleFavorite();planner:OpenNotes()
equal(selectedBuild.notes,notesBefore,"combat blocks notes edits")
equal(selectedBuild.favorite,favoriteBefore,"combat blocks favorite edits")
equal(made,before,"combat never constructs a notes editor")
SetCombat(false);planner:CloseNotes()

-- Per-point plans, custom order, history and read-only native guidance.
nodes[101].visibleEdges={{targetNode=102,type=3}}
nodes[101].ranksPurchased,nodes[101].activeRank=0,0
nodes[102].type=2;nodes[102].entryIDs={202,203};nodes[102].ranksPurchased,nodes[102].activeRank=0,0
nodes[103]={isVisible=true,maxRanks=2,ranksPurchased=0,entryIDs={204},flags=0,type=0,activeRank=0,ranksIncreased=0,
    groupIDs={2},conditionIDs={},posX=800,posY=0,visibleEdges={}}
native[103]=Frame();native[103].IsForbidden=function()return false end;native[103]:Show()
C_Traits.GetTreeNodes=function()return {101,102,103}end
C_Traits.GetEntryInfo=function(_,id)return {maxRanks=id==204 and 2 or 5,definitionID=id+1000,conditionIDs={}}end
C_Traits.GetConditionInfo=function()return {type=0,isAlwaysMet=false,isSufficient=false,isGate=false,spentAmountRequired=5,traitCurrencyID=1}end
local activeConfig,canPurchase=config,true
C_ClassTalents={GetActiveConfigID=function()return activeConfig end}
C_Traits.CanPurchaseRank=function()return canPurchase end
staged=false;level,unspent,spent=18,9,0
Suite.db.talentPlannerRules=false;planner:Apply();planner:New("Point order")
planner:Change(103,1);planner:Change(101,1);planner:Change(103,1)
for i=1,4 do planner:Change(101,1) end
planner:Change(102,1);planner:Change(102,1)
local orderedBuild=planner:Current()
equal(#orderedBuild.sequence,9,"leveling plan stores one step per allocated rank")
equal(orderedBuild.sequence[1].node,103,"new points preserve player allocation order")
equal(orderedBuild.sequence[2].node,101,"different talents retain their allocation sequence")
equal(orderedBuild.sequence[3].node,103,"later ranks are recorded at their actual sequence position")
local invalid=Suite.Copy(orderedBuild.sequence);invalid[1],invalid[8]=invalid[8],invalid[1]
equal(planner:ValidateOrder(orderedBuild.ranks,invalid),nil,"order cannot move a dependent talent ahead of its prerequisite")
invalid=Suite.Copy(orderedBuild.sequence);invalid[1].node={secret=true}
equal(planner:ValidateOrder(orderedBuild.ranks,invalid),nil,"secret sequence identifiers never reach table lookups")
invalid=Suite.Copy(orderedBuild.sequence);table.remove(invalid)
equal(planner:ValidateOrder(orderedBuild.ranks,invalid),nil,"order must account for all planned ranks")
planner:OpenOrder();planner.orderSelected=1;planner:MoveOrder(1)
equal(planner.orderDraft[1].node,101,"independent step can be moved earlier")
planner:MoveOrder(1)
equal(planner.orderDraft[2].rank,1,"later rank cannot precede the same talent's earlier rank")
planner.orderCancel.OnClick()
equal(orderedBuild.sequence[1].node,103,"cancel discards unsaved order edits")
planner:OpenOrder();planner.orderSelected=1;planner:MoveOrder(1);planner.orderSave.OnClick()
equal(orderedBuild.sequence[1].node,101,"save persists a valid custom order")
planner:History(false)
equal(orderedBuild.sequence[1].node,103,"undo restores the prior leveling sequence")
planner:History(true)
equal(orderedBuild.sequence[1].node,101,"redo restores the custom leveling sequence")
local historyCount=#planner.undo
planner:SaveOrder(orderedBuild.sequence)
equal(#planner.undo,historyCount,"saving an unchanged order adds no history entry")
planner:Change(102,-1)
equal(#orderedBuild.sequence,8,"rank refunds reconcile the leveling plan")
planner:History(false)
equal(#orderedBuild.sequence,9,"undo restores removed rank and its order")
planner:Change(102,1,true)
equal(orderedBuild.sequence[#orderedBuild.sequence].entry,203,"choice changes reconcile sequence entries")
planner:History(false)
equal(orderedBuild.sequence[#orderedBuild.sequence].entry,202,"undo restores the original choice sequence")
assert(loadfile("tests/talent_sharing_spec.lua"))(Suite, equal, Frame, SetCombat)
local nativeClick=function()end;native[101].OnClick=nativeClick
planner:InitializeGuide(nil);planner:StartGuide()
local first=orderedBuild.sequence[1]
local step,message=planner:GuideStep()
equal(step.node,first.node,"guide identifies the first planned native talent")
equal(step.rank,first.rank,"guide identifies the exact next rank")
equal(planner.preview,false,"starting guide exposes the actual native talent tree")
equal(planner.guideHighlight:IsShown(),true,"available next point has a native-position marker")
equal(planner.guideHighlight.mouseEnabled,false,"guide marker passes clicks through to native input")
equal(native[101].OnClick,nativeClick,"guide preserves native talent click script")
equal(planner.guideDB.buildID,orderedBuild.id,"followed build persists by stable saved ID")
equal(planner.guideButton.caption:GetText(),"Stop learning guide","learning action clearly reflects active mode")
equal(planner.guideInstruction.caption:GetText():find("Click the gold-outlined talent",1,true)~=nil,true,"instruction names the real talent click action")
equal(planner.guideInstruction.mouseEnabled,false,"learning instructions do not intercept native input")
equal(planner.guideMarks[101].caption:GetText(),"+5","whole-tree guide shows all remaining ranks")
equal(planner.guideMarks[102].caption:GetText(),"+2","future gated talents retain plan badges")
equal(planner.guideMarks[101].mouseEnabled,false,"comparison badge preserves native click input")
local function Live(id,rank,entry)
    nodes[id].ranksPurchased,nodes[id].activeRank=rank,rank
    nodes[id].activeEntry=rank>0 and {entryID=entry or nodes[id].entryIDs[1]} or nil
end
nodes[first.node].ranksPurchased=1;nodes[first.node].activeRank=0;staged=true
planner:Refresh();step,message=planner:GuideStep()
equal(step,nil,"guide never advances on uncommitted native changes")
equal(message:find("pending",1,true)~=nil,true,"staged native changes get a review message")
equal(planner.guideHighlight:IsShown(),false,"pending native changes suppress the next marker")
equal(planner.guideInstruction.caption:GetText():find("Click Apply Changes below",1,true)~=nil,true,"pending selection explains how to confirm real talents")
equal(planner.guideMarks[102]:IsShown(),true,"pending edits keep the full-plan comparison visible")
staged=false;Live(first.node,0);planner:Refresh()
equal(planner:GuideStep().node,first.node,"cancelling native changes restores original next point")
Live(first.node,1);unspent,spent=8,1;planner:Refresh()
local nextPlanned=orderedBuild.sequence[2]
step=planner:GuideStep()
equal(step.node,nextPlanned.node,"committed native allocation advances guide to next planned point")
equal(step.rank,nextPlanned.rank,"guide advances rank without editing the draft")
equal(#orderedBuild.sequence,9,"live progress does not consume the saved leveling plan")
Live(102,1,203);planner:Refresh();step,message=planner:GuideStep()
equal(step,nil,"live choice outside the plan pauses guidance")
equal(message:find("differ",1,true)~=nil,true,"guide explains live-build mismatches")
equal(planner.guideMarks[102].caption:GetText(),"X","wrong live choice identifies the conflicting talent")
equal(planner.guideMarks[101]:IsShown(),true,"a mismatch does not hide other planned talents")
Live(102,0);activeConfig=999;planner:Refresh();step,message=planner:GuideStep()
equal(step,nil,"inactive spec cannot receive guide highlights")
equal(message:find("active spec",1,true)~=nil,true,"inactive spec pause is explained")
activeConfig=config;canPurchase={secret=true};planner:Refresh()
equal(planner:GuideStep(),nil,"restricted purchase permission never becomes a guide action")
equal(planner.guideHighlight:IsShown(),false,"unavailable native permission hides the guide marker")
canPurchase=true;unspent,spent=0,1;planner:Refresh();step,message=planner:GuideStep()
equal(step,nil,"guide waits when no native talent points remain")
equal(message:find("Earn another",1,true)~=nil,true,"point shortage is explained without guessing future levels")
Live(101,5);Live(102,2,202);Live(103,2);unspent,spent=0,9;planner:Refresh();step,message=planner:GuideStep()
equal(step,nil,"completed build has no extra proposed point")
equal(message:find("All 9",1,true)~=nil,true,"guide reports matching live completion")
equal(planner.guideMarks[101].caption:GetText(),"OK","completed talent gets a matching badge")
Live(101,4);orderedBuild.ranks[101].rank=3;planner:Refresh()
equal(planner.guideMarks[101].caption:GetText(),"X","extra live ranks are marked as conflicts")
orderedBuild.ranks[101].rank=5;Live(101,5);planner:Refresh()
local savedGuide=Suite.Copy(planner.guideDB)
planner:Rename("Follow this renamed build");planner:ToggleFavorite()
equal(planner.guideDB.buildID,savedGuide.buildID,"rename and favorite changes preserve guide identity")
planner:StopGuide();planner:InitializeGuide(savedGuide);planner.model=nil;planner:Refresh()
equal(planner:Current(),orderedBuild,"simulated reload restores character's exact guided build")
equal(planner.guiding,true,"saved character guide resumes after context restoration")
equal(planner.preview,false,"restored guide remains on native tree")
inspecting=true;planner:Refresh()
equal(planner.guideHighlight:IsShown(),false,"inspection cannot retain a stale native marker")
equal(planner.guideMarks[101]:IsShown(),false,"inspection clears whole-tree comparison badges")
inspecting=false;planner:Refresh()
planner:InitializeGuide(nil);planner.guiding=false;planner.model=nil;planner:Refresh()
equal(planner.guiding,false,"another character without a guide does not inherit follow selection")
equal(next(planner:InitializeGuide({class={secret=true},buildID=1})),nil,"secret saved guide class is discarded safely")
planner:Select(planner:BuildOrder()[1])
before=made;SetCombat(true)
planner:OpenOrder();planner:StartGuide()
equal(made,before,"combat cannot construct order or guide widgets")
SetCombat(false);planner:CloseOrder();planner:StopGuide()
planner.preview=false;planner:Render()
equal(planner.guideButton.caption:GetText(),"Learn this build","idle action explains its purpose")
equal(planner.status:GetText():find("Selected:",1,true)~=nil,true,"selected live build is acknowledged without asking for another selection")
equal(planner.guideInstruction:IsShown(),false,"stop clears the real-talent instruction banner")
equal(planner.guideMarks[101]:IsShown(),false,"stopping guide clears comparison badges")
local metadataBuild=planner:Current()
metadataBuild.sequence={{node={secret=true},entry=201,rank=1}}
planner:Library()
equal(metadataBuild.sequence,nil,"restricted saved order metadata is discarded before any history copy")
equal(Suite.Profiles.excluded.talentBuilds,true,"settings profiles cannot roll back saved builds")
equal(writes,0,"entire planner lifecycle never invokes a native talent mutation")

-- Starter fixtures exercise resolution against changing client identifiers and
-- rules. They do not stand in for native class-tree verification.
local previousModel, previousClass = planner.model, class
local fixtureCount = 0
for token, data in pairs(planner.starters) do
    fixtureCount = fixtureCount + 1
    class = token
    local model = {host=host,config=config,tree=tree,class=token,hash=string.rep("a",32),
        nodes={},order={},native={},rules={},edges={},groups={},groupInfo={},staged=false}
    local occurrences, spellNodes = {}, {}
    for key in data.order:gmatch(".") do
        equal(type(data.spells[key]),"number",token.." every reference step has a spell ID")
        occurrences[data.spells[key]] = (occurrences[data.spells[key]] or 0) + 1
    end
    local id = 5000
    for spell, count in pairs(occurrences) do
        id = id + 1;local entry=id+1000
        model.order[#model.order+1]=id;spellNodes[spell]=id
        native[id]=Frame();native[id].IsForbidden=function()return false end;native[id]:Show()
        model.nodes[id]={max=count,order={entry},entries={[entry]={spell=spell,max=count,name="Talent "..spell,icon=134400}}}
        model.rules[id]={incoming={},conditions={},[entry]={},groups={1},costs={[1]=1},y=id}
    end
    planner.model,planner.starterCache,planner.starter,planner.guiding=model,nil,false,false
    local full,why=planner:ResolveStarter()
    equal(full~=nil,true,token.." starter resolves all client spell identities: "..tostring(why))
    equal(#full.sequence,51,token.." source path covers all 51 reference levels")
    equal(full.sequence[1].node,spellNodes[data.spells[data.order:sub(1,1)]],token.." first source choice stays first")
    equal(#planner:StarterBuild(9).sequence,0,token.." pre-talent preview is empty")
    equal(#planner:StarterBuild(10).sequence,1,token.." level ten previews first rank")
    equal(#planner:StarterBuild(30).sequence,21,token.." level thirty previews twenty-one baseline points")
    equal(#planner:StarterBuild(60).sequence,51,token.." full preview retains future points")
    local amountBefore=#planner:Library()
    planner:OpenStarterPanel()
    equal(planner.starterPanel:IsShown(),true,token.." automatic starter entry opens level browser")
    equal(#planner:Library(),amountBefore,token.." browsing does not create a saved draft")
    planner:ChooseStarterLevel(25)
    equal(#planner:Current().sequence,16,token.." level changes show the correct prefix")
    equal(planner.starterSchedule:GetText():find("Level 25:",1,true)~=nil,true,token.." schedule names the selected level")
    equal(planner.footer:IsShown(),false,token.." automatic helper leaves native Apply controls visible")
    equal(planner.resetButton:IsShown(),false,token.." source starter never exposes a draft-reset button")
    local starterBeforeReset=planner:Current()
    planner:ResetDraft()
    equal(planner:Current(),starterBeforeReset,token.." reset cannot replace the read-only source starter")
    equal(#planner:Current().sequence,16,token.." reset cannot clear a source starter's points")
    equal(planner.overlay:IsShown(),false,token.." automatic helper compares on the real talent tree")
    equal(planner.guideInstruction.caption:GetText():find("Level 25 reference plan",1,true)~=nil,true,token.." opening level helper requires no Learn click")
    equal(planner.guideHighlight.label:GetText(),"LEVEL 25",token.." reference level marker is distinct from a purchasable NEXT rank")
    equal(planner.guideMarks[full.sequence[16].node]:IsShown(),true,token.." selected level shows its planned rank badge")
    planner:ChooseStarterLevel(26)
    equal(planner.guideHighlight.label:GetText(),"LEVEL 26",token.." paging advances the selected-level marker")
    equal(planner.guideHighlight.point[2],native[full.sequence[17].node],token.." paging anchors the highlight to the new level talent")
    planner:ChooseStarterLevel(25)
    model.native=Suite.Copy(planner:Current().ranks);planner:Render()
    equal(planner.guideInstruction.caption:GetText():find("0 ranks to add • 0 talents differ",1,true)~=nil,true,token.." matching live allocation is explicitly recognized")
    planner:ChooseStarterLevel(26)
    local scheduled=full.sequence[17]
    equal(planner:GuideComparison()[scheduled.node].text,"+1",token.." next level identifies exactly one additional rank")
    model.staged=true;planner:Render()
    equal(planner.guideInstruction.caption:GetText():find("Pending native changes",1,true)~=nil,true,token.." pending allocations are not presented as confirmed learning")
    model.staged=false;model.native={};planner:ChooseStarterLevel(25)
    local originalName=planner:Current().name
    planner:Rename("Changed");planner:Delete();planner:ToggleFavorite();planner:SetNotes("Changed")
    planner:Change(full.sequence[1].node,-1,false);planner:SaveOrder({})
    equal(planner:Current().name,originalName,token.." draft mutation actions cannot rewrite the starter")
    equal(#planner:Current().sequence,16,token.." read-only starter survives attempted edits")
    equal(#planner:Library(),amountBefore,token.." attempted delete preserves personal builds")
    unspent,spent=21,0;level=30;activeConfig=config;canPurchase=true
    planner:StartGuide()
    equal(planner.preview,false,token.." learning starter returns to live talents")
    equal(#planner:Current().sequence,51,token.." learning uses full path rather than preview cutoff")
    equal(planner:GuideStep().node,full.sequence[1].node,token.." starter guide starts at first unlearned choice")
    equal(planner.guideHighlight.label:GetText(),"NEXT",token.." real guide restores NEXT label after level browsing")
    local saved=Suite.Copy(planner.guideDB)
    equal(saved.starter,true,token.." character guide persists starter identity separately from saved build IDs")
    planner:StopGuide();planner:InitializeGuide(saved);planner.starter=false;planner:RestoreGuide()
    equal(planner.starter,true,token.." character guide restores starter selection")
    planner:StopGuide();planner.starter=true
    Suite.db.talentPlannerRules=false
    local copy=planner:CustomizeStarter()
    equal(copy~=nil,true,token.." customization creates a personal build")
    equal(#copy.sequence,51,token.." unrestricted personal copy keeps full source order")
    equal(copy.starter,nil,token.." personal copy is editable")
    copy.name="Personal change"
    equal(full.name,originalName,token.." personal rename does not alter built-in plan")
    -- Missing, ambiguous and changed-cap clients must never get a partial plan.
    local first=full.sequence[1];local entry=model.nodes[first.node].entries[first.entry]
    local spell=entry.spell;entry.spell=nil;planner.starterCache=nil
    equal(planner:ResolveStarter(),nil,token.." missing spell rejects the complete starter")
    entry.spell=spell;local cap=entry.max;entry.max=0;planner.starterCache=nil
    equal(planner:ResolveStarter(),nil,token.." changed rank cap rejects starter without truncation")
    entry.max=cap;local rule=model.rules[first.node];rule.unknown=true;planner.starterCache=nil
    local reference=planner:ResolveStarter()
    equal(reference.verified,false,token.." unavailable prerequisites retain only a reference comparison")
    planner:OpenStarterPanel()
    equal(planner.starterSchedule:GetText():find("Level ",1,true)~=nil,true,token.." unavailable requirements no longer erase the level schedule")
    equal(planner.starterLearn.enabled,false,token.." unverified reference cannot start real learning")
    local referenceLevel=planner.starterLevel
    planner:StartGuide()
    equal(planner.guiding,false,token.." learning method independently rejects unverified reference")
    equal(planner.starterLevel,referenceLevel,token.." rejected learning preserves selected reference level")
    planner:InitializeGuide({class=token,starter=true});planner.starter=false;planner:RestoreGuide()
    equal(planner.guiding,false,token.." saved guide cannot resume an unverified starter")
    planner.starter=true;planner:Render()
    equal(planner:CustomizeStarter(),nil,token.." unverified reference cannot create an unchecked draft")
    equal(planner.guideInstruction.caption:GetText():find("Reference comparison only",1,true)~=nil,true,token.." unverified comparison is explicitly disclosed")
    rule.unknown=nil;planner.starterCache=nil
    local other=model.order[1]==first.node and model.order[2] or model.order[1]
    local otherEntry=model.nodes[other].entries[model.nodes[other].order[1]];local otherSpell=otherEntry.spell
    otherEntry.spell=spell
    equal(planner:ResolveStarter(),nil,token.." ambiguous spell mapping is rejected")
    otherEntry.spell=otherSpell;planner.starterCache=nil
    -- Current-level customization uses existing policy without trimming the source.
    Suite.db.talentPlannerRules=true;planner.starter=true;planner.starterLevel=60
    local limited=planner:CustomizeStarter()
    equal(#limited.sequence,21,token.." limited personal copy uses native earned budget")
    equal(#planner:StarterBuild(60).sequence,51,token.." limiting a personal copy preserves full starter")
    local safeLevel=planner.starterLevel
    planner:ChooseStarterLevel({secret=true})
    equal(planner.starterLevel,safeLevel,token.." restricted preview level is ignored")
end
equal(fixtureCount,9,"all nine Forever classes have a starter path")
local fullLibrary=planner:Library()
while #fullLibrary < planner.limit do
    fullLibrary[#fullLibrary+1]={name="Library filler",tree=tree,hash=planner.model.hash,ranks={}}
end
planner.starter=true
equal(planner:CustomizeStarter(),nil,"full personal library rejects customization without replacing a draft")
equal(#planner:Library(),planner.limit,"full library keeps every existing build")
equal(#planner:StarterBuild(60).sequence,51,"full library does not consume or alter the built-in starter")
local fullBefore=planner:StarterBuild(60)
local firstStep=fullBefore.sequence[1]
local restrictedEntry=planner.model.nodes[firstStep.node].entries[firstStep.entry]
local readableSpell=restrictedEntry.spell
restrictedEntry.spell={secret=true};planner.starterCache=nil
equal(planner:ResolveStarter(),nil,"restricted native spell identity cannot become a starter lookup key")
restrictedEntry.spell=readableSpell;planner.starterCache=nil
equal(planner:ResolveStarter()~=nil,true,"a refreshed readable identity recovers the full starter")
planner:CloseStarterPanel();planner.model, class = previousModel,previousClass
planner.starter=false;planner.starterCache=nil
before=made;SetCombat(true);planner:OpenStarterPanel();planner:ChooseStarterLevel(20);planner:CustomizeStarter()
equal(made,before,"starter UI and copying defer in combat")
SetCombat(false)
equal(writes,0,"starter previews and learning never spend real talents")

-- User's build 70790 report: Furious Precision has a zero-spending
-- availability condition and belongs to five groups, not one.
do
    local savedPlanner, savedAPI = {}, {}
    for key,value in pairs(planner) do savedPlanner[key]=value end
    for key,value in pairs(C_Traits) do savedAPI[key]=value end
    local savedLimit,savedLevel=Suite.db.talentPlannerRules,level
    local condition={type=0,isAlwaysMet=false,isMet=true,isGate=false,isSufficient=false,
        spentAmountRequired=0,traitCurrencyID=3820}
    local raw={type=0,flags=0,maxRanks=3,activeRank=3,ranksPurchased=3,ranksIncreased=0,
        groupIDs={11662,12826,12827,12828,11657},conditionIDs={43531},visibleEdges={},posX=0,posY=0}
    C_Traits.GetNodeInfo=function(_,id)if id==105953 then return raw end end
    C_Traits.GetNodeCost=function()return {{ID=3820,amount=1}}end
    C_Traits.GetEntryInfo=function()return {maxRanks=3,definitionID=135484,conditionIDs={}}end
    C_Traits.GetConditionInfo=function(_,id)if id==43531 then return condition end end
    C_Traits.GetGroupDisplayInfoByTreeID=function()
        return {{groupID=11662,displayName="Fury"}}
    end
    C_Traits.GetTreeCurrencyInfo=function()return {{quantity=10,spent=3}}end
    local model={host=previousModel.host,config=previousModel.config,tree=previousModel.tree,
        class=previousModel.class,hash=previousModel.hash}
    model.order={105953};model.nodes={[105953]={id=105953,max=3,order={130683},
        entries={[130683]={max=3,name="Furious Precision",spell=1323963}}}}
    model.native={[105953]={entry=130683,rank=3}}
    local draft={ranks={[105953]={entry=130683,rank=1}},sequence={{node=105953,entry=130683,rank=1}}}
    planner.model,planner.starter,planner.preview=model,false,true
    planner.Current=function()return draft end
    planner.Render=function()end
    planner.undo,planner.redo={},{}
    level=22;Suite.db.talentPlannerRules=false
    planner:CaptureRules(model)
    equal(#raw.groupIDs,5,"reported Fury fixture retains all five raw native groups")
    equal(#model.rules[105953].groups,1,"only the display tree contributes to per-tree spending")
    equal(planner:Analyze(draft.ranks,false).valid,true,"zero spending is satisfied despite ambiguous group membership")
    planner:Change(105953,1)
    equal(draft.ranks[105953].rank,2,"reported Furious Precision draft advances from one to two")
    Suite.db.talentPlannerRules=true
    planner:Change(105953,1)
    equal(draft.ranks[105953].rank,3,"reported Furious Precision advances to three with current-level limit on")
    planner:Change(105953,1)
    equal(draft.ranks[105953].rank,3,"zero spending never bypasses the three-rank cap")
    planner:History(false)
    equal(draft.ranks[105953].rank,2,"reported Fury rank addition remains undoable")
    planner:History(true)
    equal(draft.ranks[105953].rank,3,"reported Fury rank addition remains redoable")
    equal(raw.ranksPurchased,3,"draft editing leaves the reported native rank unchanged")
    condition.spentAmountRequired=5;planner:CaptureRules(model)
    equal(planner:Analyze(draft.ranks,false).valid,false,"positive multi-group requirements remain unavailable rather than guessed")
    condition.spentAmountRequired={secret=true};planner:CaptureRules(model)
    equal(planner:Analyze(draft.ranks,false).valid,false,"restricted zero-spending metadata cannot enable editing")
    condition.spentAmountRequired=0;condition.questID=123;condition.isMet=false;planner:CaptureRules(model)
    equal(planner:Analyze(draft.ranks,false).valid,false,"zero spending cannot waive an unmet quest requirement")
    condition.questID=nil;condition.traitCondAccountElementID=123;planner:CaptureRules(model)
    equal(planner:Analyze(draft.ranks,false).valid,false,"zero spending cannot waive an unsupported account requirement")
    condition.traitCondAccountElementID=nil;condition.playerLevel=23;planner:CaptureRules(model)
    equal(planner:Analyze(draft.ranks,true).valid,false,"zero spending cannot waive an unmet current-level requirement")
    equal(planner:Analyze(draft.ranks,false).valid,true,"planning ahead still permits a disclosed future level")
    for key in pairs(planner)do planner[key]=nil end
    for key,value in pairs(savedPlanner)do planner[key]=value end
    for key in pairs(C_Traits)do C_Traits[key]=nil end
    for key,value in pairs(savedAPI)do C_Traits[key]=value end
    Suite.db.talentPlannerRules,level=savedLimit,savedLevel
end

-- Three complete native-shaped trees with zero Available conditions even on
-- learned lower Fury rows: availability must be rebuilt from the empty draft.
do
    local savedPlanner,savedAPI={},{}
    for key,value in pairs(planner)do savedPlanner[key]=value end
    for key,value in pairs(C_Traits)do savedAPI[key]=value end
    local savedButtonGetter=host.GetTalentButtonByNodeID
    local savedLimit=Suite.db.talentPlannerRules
    local rawNodes,nativeButtons,displays={},{},{}
    local model={host=previousModel.host,config=previousModel.config,tree=previousModel.tree,
        class=previousModel.class,hash=previousModel.hash,nodes={},order={},native={}}
    for group=1,3 do
        displays[group]={groupID=group,displayName=({"Arms","Fury","Protection"})[group]}
        for row=1,7 do
            local id=group*100+row
            rawNodes[id]={type=0,flags=0,maxRanks=5,activeRank=group==2 and row<=3 and 5 or 0,
                ranksPurchased=group==2 and row<=3 and 5 or 0,ranksIncreased=0,
                groupIDs={group,800,801,802,803},conditionIDs={43500+row},visibleEdges={},posX=group*400,posY=(row-1)*100}
            model.nodes[id]={id=id,max=5,order={id+1000},entries={[id+1000]={max=5,name="Talent "..id,icon=134400}}}
            model.order[#model.order+1]=id
            if group==2 and row<=3 then model.native[id]={entry=id+1000,rank=5}end
            nativeButtons[id]=Frame();nativeButtons[id].IsForbidden=function()return false end;nativeButtons[id]:Show()
        end
    end
    C_Traits.GetNodeInfo=function(_,id)return rawNodes[id]end
    C_Traits.GetNodeCost=function()return {{ID=3820,amount=1}}end
    C_Traits.GetEntryInfo=function()return {maxRanks=5,definitionID=135484,conditionIDs={}}end
    C_Traits.GetConditionInfo=function(_,id)return {type=0,isAlwaysMet=false,isMet=true,isGate=false,
        isSufficient=false,spentAmountRequired=id-43500<=3 and 0 or 5,traitCurrencyID=3820}end
    C_Traits.GetGroupDisplayInfoByTreeID=function()return displays end
    host.GetTalentButtonByNodeID=function(_,id)return nativeButtons[id]end
    local draft={ranks={},sequence={}}
    planner.model,planner.starter,planner.preview=model,false,true
    planner.Current=function()return draft end
    planner.buttons,planner.undo,planner.redo={},{},{}
    planner.Render=function(self)
        self.analysis=self:Analyze(draft.ranks,self:RulesEnabled())
        for _,id in ipairs(model.order)do self:RenderNode(id,model.nodes[id],draft.ranks[id],22,51)end
    end
    Suite.db.talentPlannerRules=false
    planner:CaptureRules(model);planner:Render()
    for group=1,3 do for row=1,7 do
        local button=planner.buttons[group*100+row]
        equal(button.borderColor[1],row==1 and 1 or 0.55,"empty draft outlines only top row: tree "..group.." row "..row)
        equal(button.icon.desaturated,true,"empty draft icons stay grey regardless of live Fury spending")
    end end
    planner:Change(203,1)
    equal(draft.ranks[203],nil,"empty Fury draft cannot buy an already learned third-row talent")
    for point=1,4 do planner:Change(201,1)end
    equal(planner.buttons[202].borderColor[1],0.55,"four Fury points leave row two locked")
    planner:Change(201,1)
    equal(planner.buttons[202].borderColor[1],1,"five draft Fury points unlock row two")
    equal(planner.buttons[203].borderColor[1],0.55,"five draft Fury points leave row three locked")
    equal(planner.buttons[204].borderColor[1],0.55,"a positive live condition cannot prematurely unlock row four")
    equal(planner.buttons[102].borderColor[1],0.55,"Fury spending cannot unlock Arms row two")
    equal(planner.buttons[302].borderColor[1],0.55,"Fury spending cannot unlock Protection row two")
    planner:History(false)
    equal(planner.buttons[202].borderColor[1],0.55,"Undo below five Fury points relocks row two")
    planner:History(true)
    for point=1,5 do planner:Change(202,1)end
    equal(planner.buttons[203].borderColor[1],1,"ten draft Fury points unlock row three")
    equal(planner.buttons[204].borderColor[1],0.55,"ten draft Fury points leave row four locked")
    planner:Change(203,1)
    equal(draft.ranks[203].rank,1,"row-three draft purchase succeeds after ten Fury points")
    planner:Change(204,1)
    equal(draft.ranks[204],nil,"row four cannot be bought before fifteen points despite its smaller reported condition")
    equal(rawNodes[203].ranksPurchased,5,"tier validation never rewrites learned native Fury ranks")
    local sequence=planner:ValidateOrder(draft.ranks,draft.sequence)
    equal(#sequence,11,"saved point order respects the reconstructed five-point row gates")
    local illegal={{node=203,entry=1203,rank=1}}
    equal(planner:ValidateOrder({[203]={entry=1203,rank=1}},illegal),nil,"point orders cannot bypass row gates")
    for point=1,4 do planner:Change(203,1)end
    equal(planner.buttons[204].borderColor[1],1,"fifteen draft points unlock row four")
    for key in pairs(planner)do planner[key]=nil end
    for key,value in pairs(savedPlanner)do planner[key]=value end
    for key in pairs(C_Traits)do C_Traits[key]=nil end
    for key,value in pairs(savedAPI)do C_Traits[key]=value end
    host.GetTalentButtonByNodeID=savedButtonGetter
    Suite.db.talentPlannerRules=savedLimit
end

if planner.timer then planner.timer:Cancel() end
for key in pairs(planner) do planner[key]=nil end
for key,value in pairs(state) do planner[key]=value end
for _,name in ipairs(globals) do _G[name]=old[name] end
Suite.db,Suite.pending=db,pending
SetCombat(false)
