local Suite,equal,Frame,Combat=...
local routes,leveling=Suite.ProfessionRoutes,Suite.ProfessionLeveling
local savedRoutes,savedLeveling={},{};for k,v in pairs(routes)do savedRoutes[k]=v end;for k,v in pairs(leveling)do savedLeveling[k]=v end
local oldDB,oldAPI,oldCast,oldChannel,oldCreate,oldModified,oldClick = Suite.db,C_TradeSkillUI,UnitCastingInfo,UnitChannelInfo,CreateFrame,IsModifiedClick,Suite.Items.ModifiedClick
local oldSources=Suite.ProfessionRecipeSources
local guide={name="Route test",estimates={
    {1,20,4,"Intermediate",{{2,"Ore"}},recipeID=10},
    {20,40,6,"Finished item",{{2,"Intermediate"}},recipeID=20},
    {40,60,6,"Vendor recipe",{{1,"Ore"}},recipeID=30},
    {60,80,6,"Unknown recipe",{{1,"Ore"}},recipeID=40},
}}
Suite.ProfessionGuides[#Suite.ProfessionGuides+1]=guide
local index=#Suite.ProfessionGuides
Suite.db=Suite.InitializeDB(nil);Suite.db.professionLeveling=true;Suite.db.professionLevelingAutoRecipe=true
local function Widget(parent)local frame=Frame();frame.parent=parent;frame.IsForbidden=function()return false end;frame:Show();return frame end
CreateFrame=function(_,_,parent)assert(not InCombatLockdown(),"route UI never constructs in combat");return Widget(parent)end
leveling.owner=Widget();leveling.owner.CraftingPage=Widget(leveling.owner)
leveling.frame=Widget();leveling.frame.body=Widget(leveling.frame);leveling.frame.body:SetHeight(1200)
leveling.frame.scroll=Widget(leveling.frame);leveling.frame.scroll.suiteOffset=120
leveling.frame.status=Frame();leveling.frame.recipeBack=Widget(leveling.frame)
leveling.selected,leveling.current,leveling.rank,leveling.open,leveling.autoCrafting=index,index,25,true,nil
local context,selected,opened,linked,busy="route-own",20,{},false,false
leveling.Context=function()return index,25,context,300 end
local render=leveling.Render
leveling.Render=function(self)routes:Render(guide,25,0);routes:AfterRender()end
local learned={[10]=true,[20]=false,[30]=false}
C_TradeSkillUI={
    GetBaseProfessionInfo=function()return{professionID=164}end,
    GetRecipeInfo=function(id)if learned[id]~=nil then return{recipeID=id,learned=learned[id],canSkillUp=true}end end,
    IsRecipeInSkillLine=function(id,skill)return skill==164 and id>=10 and id<=40 end,
    IsTradeSkillLinked=function()return linked end,
    OpenRecipe=function(id)opened[#opened+1]=id;selected=id;return true end,
    GetRecipeOutputItemData=function(id)return{itemID=id+100,icon=id+200}end,
    GetRecipeRequirements=function(id)if id==30 then return{{name="Engineering (40)",met=false},{name="Level 10",met=true}}end;return{}end,
    GetRecipeSourceText=function()return nil end,
    CraftRecipe=function()error("navigation must never craft")end,
}
leveling.owner.CraftingPage.SchematicForm=Widget()
leveling.owner.CraftingPage.SchematicForm.GetRecipeInfo=function()return selected and{recipeID=selected}end
UnitCastingInfo=function()if busy then return"Crafting"end end;UnitChannelInfo=function()return nil end
Suite.ProfessionRecipeSources={ [10]={profession=guide.name,kind="Trainer",note="Known tier only."},[30]={profession=guide.name,kind="Vendor",note="Limited stock."},[20]={profession=guide.name,kind="Quest",note="Complete the recipe quest."}}
routes:Reset();routes.expanded=false;routes.body=nil
local rows,missing,unknown=routes:Missing(guide,25)
equal(missing,2,"missing list counts only explicitly unlearned remaining recipes")
equal(unknown,1,"unknown training data remains separate from missing")
local byID={};for _,row in ipairs(rows)do byID[row.id]=row end
equal(byID[10],nil,"learned early intermediate is omitted from missing list")
equal(byID[30].kind,"Vendor","vendor acquisition remains distinct")
equal(byID[20].kind,"Quest","quest recipe is not relabelled trainer")
equal(byID[40].kind,"Source unavailable","no source stays unknown")
equal(byID[30].requirements:find("Needed: Engineering (40)",1,true)~=nil,true,"native requirement text and unmet state remain visible")
equal(byID[30].first,40,"route skill starts stay separate from learning requirements")
learned[10]=false
rows=routes:Missing(guide,25);byID={};for _,row in ipairs(rows)do byID[row.id]=row end
equal(byID[10]~=nil,true,"still-needed intermediate recipe is included even below current route skill")
learned[10]=true
local height=routes:Render(guide,25,0)
equal(height,42,"missing section starts collapsed for a compact guide")
equal(routes.header:IsShown(),true,"route recipe summary is discoverable")
routes.header.OnClick()
equal(routes.expanded,true,"actual header expands recipe source review")
equal(routes.widgets[1]:IsShown(),true,"expanded view renders missing recipe details")
equal(routes.widgets[1].detail.text:find("Guide skill",1,true)~=nil,true,"recipe details disclose guide skill rather than inventing learning minimum")
IsModifiedClick=function()return false end
learned[20]=true
local material=Widget();material.materialID=110
local calls=0;Suite.Items.ModifiedClick=function(_,id,button)calls=calls+1;return false end
routes:MaterialClick(material,"LeftButton")
equal(opened[#opened],10,"ordinary intermediate click opens its learned recipe")
equal(leveling.routeHold,true,"manual intermediate selection pauses automatic route selection")
equal(routes.history[1].id,20,"history captures actual native previous recipe")
equal(leveling.frame.recipeBack:IsShown(),true,"Back action is visible during intermediate navigation")
local count=#opened;leveling:AutoSelectRecipe();equal(#opened,count,"automatic recipe following cannot undo intermediate choice")
learned[20]=true
routes:Back()
equal(opened[#opened],20,"Back restores actual original recipe")
equal(leveling.frame.scroll.suiteOffset,120,"Back retains guide scroll position")
equal(leveling.routeHold,nil,"Back to original route releases navigation hold")
local openNative=C_TradeSkillUI.OpenRecipe
C_TradeSkillUI.OpenRecipe=function(id)
    opened[#opened+1]=id;selected=id
    leveling:AutoSelectRecipe()
    leveling.frame.scroll.suiteOffset=500
    return true
end
routes:Navigate(10);routes:Back()
equal(selected,20,"synchronous native refresh cannot override intermediate or Back destination")
equal(leveling.frame.scroll.suiteOffset,120,"Back captures scroll before a synchronous native refresh")
C_TradeSkillUI.OpenRecipe=openNative
learned[30]=true;routes:Navigate(10);routes:Navigate(30)
equal(#routes.history,2,"nested intermediates retain a bounded Back chain")
routes:Back();equal(selected,10,"nested Back returns to previous intermediate")
routes:Back();equal(selected,20,"second Back returns to original route recipe")
learned[30]=false
Suite.Items.ModifiedClick=function()return true end
count=#opened;routes:MaterialClick(material,"LeftButton");equal(#opened,count,"Shift-link consumption prevents intermediate navigation")
Suite.Items.ModifiedClick=function()return false end
busy=true;equal(routes:Navigate(10),false,"active native casting prevents navigation")
equal(#opened,count,"busy navigation never changes recipe or cancels batch")
busy=false;leveling.autoCrafting=true;equal(routes:Navigate(10),false,"known manual crafting batch blocks intermediate navigation")
leveling.autoCrafting=nil
leveling.owner.CraftingPage.isOverrideCastBarActive=true;equal(routes:Navigate(10),false,"native crafting presentation flag blocks recipe replacement")
leveling.owner.CraftingPage.isOverrideCastBarActive=false
linked=true;equal(routes:Navigate(10),false,"linked profession cannot be navigated as own recipe book")
equal(leveling.routeHold,nil,"failed linked-book navigation restores previous hold")
linked=false
learned[10]=false;equal(routes:Navigate(10),false,"unlearned intermediate never calls native OpenRecipe")
learned[10]=true
selected=nil;equal(routes:Navigate(10),false,"unknown original selection cannot create a misleading Back destination")
selected=20;learned[20]=false;equal(routes:Navigate(10),false,"unlearned original recipe cannot become an invalid Back destination")
learned[20]=true
selected=20;routes:Navigate(10);local historyCount=#routes.history
busy=true;equal(routes:Back(),false,"Back cannot interrupt an active batch")
equal(#routes.history,historyCount,"blocked Back preserves history")
busy=false
context="different-book";count=#opened;equal(routes:Back(),false,"context change invalidates previous recipe history")
equal(#opened,count,"context change never replays old selection")
equal(#routes.history,0,"stale navigation history clears")
context="route-own";selected=20;routes:Navigate(10)
Combat(true);count=#opened;equal(routes:Back(),false,"combat cannot navigate Back")
equal(#opened,count,"combat creates no native recipe writes")
Combat(false);routes:Reset();equal(leveling.routeHold,nil,"closing or switching guide releases navigation state")
learned[10]=false;routes.expanded=false
routes:MaterialClick(material,"LeftButton")
equal(routes.expanded,true,"unlearned material opens source guidance instead of crafting")
equal(#opened,count,"source guidance never learns or buys a recipe")
C_TradeSkillUI.GetRecipeRequirements=function()return{{name={secret=true},met=false},{name="Hidden",met={secret=true}}}end
equal(routes:Requirements(10):find("unavailable",1,true)~=nil,true,"restricted requirement data cannot be formatted")
C_TradeSkillUI.GetRecipeInfo=function(id)return{recipeID=id,learned={secret=true}}end
rows,missing,unknown=routes:Missing(guide,25)
equal(missing,0,"restricted training state is never missing/false")
equal(unknown,4,"restricted training leaves each route dependency unknown")
routes:Reset();for k in pairs(routes)do routes[k]=nil end;for k,v in pairs(savedRoutes)do routes[k]=v end
for k in pairs(leveling)do leveling[k]=nil end;for k,v in pairs(savedLeveling)do leveling[k]=v end
table.remove(Suite.ProfessionGuides)
Suite.db,C_TradeSkillUI,UnitCastingInfo,UnitChannelInfo,CreateFrame,IsModifiedClick,Suite.Items.ModifiedClick=oldDB,oldAPI,oldCast,oldChannel,oldCreate,oldModified,oldClick
Suite.ProfessionRecipeSources=oldSources;Combat(false)
