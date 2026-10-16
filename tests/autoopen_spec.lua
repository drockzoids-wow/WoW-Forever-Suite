local Suite,equal,Frame,SetCombat=...
local open=Suite.AutoOpen
local names={"CreateFrame","C_Container","C_Item","ItemLocation","C_Timer","UnitIsDeadOrGhost","GetCursorInfo",
    "UnitCastingInfo","UnitChannelInfo","SpellIsTargeting","GetNumLootItems","NUM_TOTAL_EQUIPPED_BAG_SLOTS",
    "MerchantFrame","BankFrame","BankPanel","GuildBankFrame","MailFrame","TradeFrame","AuctionHouseFrame","AuctionFrame",
    "ItemInteractionFrame","ScrappingMachineFrame","ItemUpgradeFrame","LootFrame","C_TooltipInfo","ITEM_OPENABLE"}
local saved,state={},{}
for _,key in ipairs(names)do saved[key]=_G[key]end
for key,value in pairs(open)do state[key]=value end
local oldDB,oldPending=Suite.db,Suite.pending
Suite.db,Suite.pending=Suite.InitializeDB(nil),{}
local timers,made,calls={},0,{}
C_Timer={NewTimer=function(delay,callback)local t={delay=delay,callback=callback,Cancel=function(self)self.cancelled=true end};timers[#timers+1]=t;return t end}
local function Drain()local work=timers;timers={};for _,t in ipairs(work)do if not t.cancelled then t.callback()end end end
local function Pending()local n=0;for _,t in ipairs(timers)do if not t.cancelled then n=n+1 end end;return n end
CreateFrame=function()assert(not InCombatLockdown());made=made+1;return Frame()end
for i=14,#names do _G[names[i]]=nil end
local free,family,dead,cursor,casting,targeting,loot=1,0,false,nil,nil,false,0
NUM_TOTAL_EQUIPPED_BAG_SLOTS=1
UnitIsDeadOrGhost=function()return dead end;GetCursorInfo=function()return cursor end
UnitCastingInfo=function()return casting end;UnitChannelInfo=function()end
SpellIsTargeting=function()return targeting end;GetNumLootItems=function()return loot end
local items={[1]={itemID=100,stackCount=1,hasLoot=true,isLocked=false,guid="first"},[2]={itemID=101,stackCount=1,hasLoot=true,isLocked=false,guid="second"}}
local reject,recycle=false,false
local reads=0
C_Container={GetContainerNumSlots=function(bag)return bag==0 and 4 or 0 end,
    GetContainerNumFreeSlots=function()return free,family end,
    GetContainerItemInfo=function(_,slot)
        reads=reads+1
        if recycle and reads==2 then items[slot].guid="replaced"end
        return items[slot]
    end,
    UseContainerItem=function(bag,slot)
        assert(not InCombatLockdown());calls[#calls+1]={bag,slot}
        if reject then error("native request rejected")end
    end}
ItemLocation={CreateFromBagAndSlot=function(_,bag,slot)return {bag=bag,slot=slot}end}
C_Item={GetItemGUID=function(location)return items[location.slot] and items[location.slot].guid end}
local tooltips,tipReads,tipReject,tipChange={},0,false,false
ITEM_OPENABLE="<Right Click to Open>"
C_TooltipInfo={GetBagItem=function(bag,slot)
    tipReads=tipReads+1
    assert(bag==0,"native opening tooltip must use the carried bag")
    if tipReject then error("tooltip unavailable")end
    local data=tooltips[slot]
    if tipChange then tooltips[slot]=nil end
    return data
end}
-- A clam's explicit native opening prompt is sufficient even without hasLoot.
items[3]={itemID=5523,stackCount=1,hasLoot=false,isLocked=false,guid="clam"}
tooltips[3]={id=5523,lines={{leftText="Small Barnacled Clam"},{leftText=ITEM_OPENABLE}}}
equal(open:Candidate(0,3).id,5523,"native openable clam is recognized without the loot flag")
local english=ITEM_OPENABLE
ITEM_OPENABLE="<Zum Öffnen rechtsklicken>";tooltips[3].lines[2].leftText=ITEM_OPENABLE
equal(open:Candidate(0,3).id,5523,"opening prompt comparison uses the client's localized text")
ITEM_OPENABLE=english;tooltips[3].lines[2].leftText=ITEM_OPENABLE
tooltips[3].id=100
equal(open:Candidate(0,3),nil,"a tooltip for a different item cannot authorize opening")
tooltips[3].id=5523;tooltips[3].lines[2].leftText="Use: Restore health"
equal(open:Candidate(0,3),nil,"generic use text never qualifies as an opening prompt")
tooltips[3].lines[2].leftText={secret=true}
equal(open:Candidate(0,3),nil,"restricted tooltip text is not compared or used")
tooltips[3].lines={secret=true}
equal(open:Candidate(0,3),nil,"restricted tooltip lines cannot authorize opening")
tooltips[3]={secret=true}
equal(open:Candidate(0,3),nil,"restricted tooltip data cannot authorize opening")
tooltips[3]={id=5523,lines={{leftText=ITEM_OPENABLE}}}
items[3].hasLoot={secret=true}
local readCount=tipReads
equal(open:Candidate(0,3),nil,"restricted loot flags cannot be bypassed by tooltip scanning")
equal(tipReads,readCount,"restricted loot flags do not query an alternate signal")
items[3].hasLoot=false;items[3].isLocked=true
equal(open:Candidate(0,3),nil,"a locked clam is never opened through the fallback")
items[3].isLocked=false;tipReject=true
equal(open:Candidate(0,3),nil,"rejected native tooltip queries are contained")
tipReject=false
local nativeTooltip=C_TooltipInfo.GetBagItem;C_TooltipInfo.GetBagItem=nil
equal(open:Candidate(0,3),nil,"missing tooltip API leaves unknown clams alone")
equal(open:Candidate(0,1).id,100,"native loot flag remains sufficient without tooltip API")
C_TooltipInfo.GetBagItem=nativeTooltip;items[3],tooltips[3]=nil,nil;tipReads=0
SetCombat(false);open:Apply()
equal(made,0,"auto-open default off constructs nothing");equal(Pending(),0,"auto-open default off queues nothing")
Suite.db.autoOpenContainers=true;SetCombat(true);open:Apply()
equal(made,0,"auto-open construction defers during combat")
SetCombat(false);Suite.pending.autoOpen();Suite.pending.autoOpen=nil
free=0;Drain();equal(#calls,0,"full regular bags do not open containers")
free=1;family=32;open:Queue();Drain();equal(#calls,0,"specialty-only free slots do not permit opening")
family=0;free={secret=true};open:Queue();Drain();equal(#calls,0,"restricted free counts do not authorize opening")
free=1
items[1].hasLoot=false;items[2].isLocked=true;open:Queue();Drain();equal(#calls,0,"ordinary items and locked containers are skipped")
items[1].hasLoot=true;items[2].isLocked=false
items[1].itemID={secret=true};items[2].hasLoot=false;open:Queue();Drain();equal(#calls,0,"restricted item identity is skipped")
items[1].itemID=100;items[1].guid=nil;open:Queue();Drain();equal(#calls,0,"unknown physical item identity is skipped")
items[1].guid="first"
for _,context in ipairs({"MerchantFrame","BankFrame","MailFrame","TradeFrame","AuctionHouseFrame"})do
    _G[context]={IsShown=function()return true end};open:Queue();Drain()
    equal(#calls,0,context.." prevents context-sensitive item use");_G[context]=nil
end
-- Native BankPanel is locally shown even while its parent bank is hidden.
local bankOpen=false
_G.BankFrame={IsShown=function()return bankOpen end}
_G.BankPanel={IsShown=function()return true end,IsVisible=function()return bankOpen end}
equal(open:Idle(),true,"a locally shown bank child under a closed bank cannot block opening")
bankOpen=true;local idle,bankReason=open:Idle()
equal(idle,false,"the actual open bank still blocks item use")
equal(bankReason,"BankFrame open or state unavailable","the bank root remains the authoritative context guard")
_G.BankPanel.IsVisible=function()return false end
equal(open:Idle(),false,"an open bank root still blocks when its child is not visible")
bankOpen=false;_G.BankPanel.IsVisible=function()return true end
equal(open:Idle(),false,"a genuinely visible bank child still blocks")
_G.BankPanel.IsVisible=function()return {secret=true}end
equal(open:Idle(),false,"unknown effective bank visibility remains conservative")
_G.BankPanel.IsShown=function()return false end;_G.BankPanel.IsVisible=nil
equal(open:Idle(),false,"a missing effective-visibility method cannot fall back to an unrelated local flag")
_G.BankPanel.IsShown=function()return true end
_G.BankPanel.IsVisible=function()return false end
dead=true;open:Queue();Drain();equal(#calls,0,"dead player cannot auto-open");dead=false
cursor="item";open:Queue();Drain();equal(#calls,0,"held cursor item prevents opening");cursor=nil
casting="cast";open:Queue();Drain();equal(#calls,0,"player cast prevents opening");casting=nil
targeting=true;open:Queue();Drain();equal(#calls,0,"spell targeting prevents opening");targeting=false
targeting=nil;equal(open:Idle(),true,"successful nil targeting result means no active targeting")
local nativeTargeting=SpellIsTargeting;SpellIsTargeting=nil
equal(open:Idle(),false,"missing targeting API must not be confused with a successful nil")
SpellIsTargeting=function()error("targeting unavailable")end
equal(open:Idle(),false,"rejected targeting API still prevents item use")
SpellIsTargeting=function()return {secret=true}end
equal(open:Idle(),false,"restricted targeting result cannot be treated as nil")
SpellIsTargeting=nativeTargeting;targeting=false
loot=1;open:Queue();Drain();equal(#calls,0,"existing loot prevents another container use");loot=0
reads=0;recycle=true;open:Queue();Drain();equal(#calls,0,"recycled slot identity is rechecked before native use");recycle=false
items[1].guid="first";items[2].hasLoot=true
open:Queue();Drain();equal(#calls,1,"exactly one container is opened at a time")
equal(calls[1][1],0,"auto-open uses carried bags only");equal(calls[1][2],1,"auto-open uses revalidated slot")
open:OnEvent("LOOT_OPENED");open:OnEvent("BAG_UPDATE_DELAYED");Drain();Drain()
equal(#calls,1,"loot window pauses serial opening")
free=0;open:OnEvent("LOOT_CLOSED");Drain();equal(#calls,1,"free space is rechecked after each container")
free=1;open:OnEvent("BAG_UPDATE_DELAYED");Drain();equal(#calls,2,"next eligible container opens after loot closes")
equal(calls[2][2],2,"unchanged first stack is not retried")
Drain();Drain();equal(#calls,2,"settling timer cannot retry failed unchanged containers")
equal(Pending(),0,"finished scan leaves no idle polling timers")
items[1].stackCount=2;open:OnEvent("BAG_UPDATE_DELAYED");Drain();equal(#calls,3,"changed stack count can be opened again")
open:OnEvent("LOOT_CLOSED");items[1].stackCount=3;free=1;reject=true;Drain()
equal(#calls,4,"native rejection is contained after one attempt")
open:Queue();Drain();equal(#calls,4,"rejected unchanged item is not retried on bag events");reject=false
items[1].stackCount=4;open:Queue();SetCombat(true);Drain();equal(#calls,4,"combat beginning before worker prevents opening")
SetCombat(false);open:OnEvent("PLAYER_REGEN_ENABLED");Drain();equal(#calls,5,"combat exit resumes eligible work")
open:OnEvent("LOOT_CLOSED");Suite.db.autoOpenContainers=false;open:Apply();Drain();Drain()
equal(#calls,5,"disabling cancels queued and settling work");equal(Pending(),0,"disable leaves no timers")
Suite.db.autoOpenContainers=true;SetCombat(true);open:Apply();Suite.db.autoOpenContainers=false;open:Apply()
equal(Suite.pending.autoOpen,nil,"disable cancels deferred activation");SetCombat(false)
Suite.db.autoOpenContainers=true;open:Apply();open:OnEvent("PLAYER_LOGOUT");Drain()
equal(#calls,5,"logout cancels pending work")
equal(Suite.SettingsCatalog:Search("auto open bag containers")[1].key,"autoOpenContainers","auto-open setting is searchable")
equal(Suite.SettingsCatalog:Search("clams")[1].key,"autoOpenContainers","clam opening is discoverable in settings")
-- Exercise the actual serial worker with native tooltip-only clams.
items={ [1]={itemID=5523,stackCount=2,hasLoot=false,isLocked=false,guid="clam-stack"},
    [2]={itemID=5523,stackCount=1,hasLoot=false,isLocked=false,guid="second-clam"} }
tooltips={ [1]={id=5523,dataInstanceID=71,lines={}}, [2]={id=5523,lines={}} }
open:Apply();local used=#calls
Drain();equal(#calls,used,"sparse clam tooltip waits without marking an attempt")
equal(Pending(),0,"waiting for tooltip data has no idle polling timer")
open.events.OnEvent(open.events,"TOOLTIP_DATA_UPDATE",999)
equal(Pending(),0,"unrelated tooltip updates cannot rescan containers")
open.events.OnEvent(open.events,"TOOLTIP_DATA_UPDATE",{secret=true})
equal(Pending(),0,"restricted tooltip instance IDs cannot schedule work")
open.events.OnEvent(open.events,"TOOLTIP_DATA_UPDATE")
equal(Pending(),1,"native all-tooltip updates can wake an outstanding sparse lookup")
Drain();equal(#calls,used,"an unresolved tooltip still makes no item attempt")
tooltips[1].lines={{leftText=ITEM_OPENABLE}}
open.events.OnEvent(open.events,"TOOLTIP_DATA_UPDATE",71)
equal(Pending(),1,"the pending clam's native tooltip update wakes its scan")
tipChange=true;Drain();tipChange=false
equal(#calls,used,"clam opening prompt is rechecked immediately before item use")
equal(open.attempted and open.attempted["clam-stack"],nil,"changed tooltip does not spend the stack's attempt")
tooltips[1]={id=5523,lines={{leftText=ITEM_OPENABLE}}}
tooltips[2].lines={{leftText=ITEM_OPENABLE}}
open.events.OnEvent(open.events,"ITEM_DATA_LOAD_RESULT",5523,true);Drain()
equal(#calls,used+1,"a completed native item load resumes tooltip-only clam opening")
equal(calls[#calls][2],1,"first eligible clam stack opens first")
open:OnEvent("LOOT_OPENED");Drain();Drain()
equal(#calls,used+1,"clam loot pauses the next automatic opening")
items[1].stackCount=1;open:OnEvent("LOOT_CLOSED");Drain()
equal(#calls,used+2,"remaining clams in a changed stack continue serially")
items[1]=nil;open:OnEvent("LOOT_CLOSED");Drain()
equal(#calls,used+3,"a separate clam of the same item type opens next")
open:OnEvent("LOOT_CLOSED");Drain();Drain()
equal(#calls,used+3,"an unchanged rejected clam cannot loop")
equal(Pending(),0,"finished clam pass leaves no idle worker")
-- Status uses the same gating reasons without attempting/queuing item use.
local printed,originalPrint={},Suite.Print
Suite.Print=function(message)printed[#printed+1]=message end
local function Contains(fragment)for _,line in ipairs(printed)do if line:find(fragment,1,true)then return true end end;return false end
local function Status(id)printed={};open:Status(id)end
targeting=nil;Status(5523)
equal(Contains("Context: ready"),true,"diagnostic no longer reports a hidden locally shown BankPanel as open")
equal(Contains("SpellIsTargeting: readable, value=nil"),true,"status distinguishes an ordinary nil targeting return")
equal(Contains("unchanged stack already attempted"),true,"status identifies the attempt deduplication gate")
equal(Contains("request sent; loot not confirmed"),true,"status never claims the native request actually opened loot")
equal(#calls,used+3,"diagnostic does not use the inspected clam")
equal(Pending(),0,"diagnostic does not queue item-opening work")
items[2].guid=nil;Status(5523)
equal(Contains("item GUID missing"),true,"diagnostic exposes missing physical identity")
items[2].guid="new-physical-clam";Status(5523)
equal(Contains("eligible"),true,"status can identify an eligible tooltip-only clam")
equal(Contains("new-physical-clam"),false,"diagnostic never prints physical GUID strings")
items[2].hasLoot={secret=true};Status(5523)
equal(Contains("loot=restricted"),true,"diagnostic describes restricted flags without inspecting them")
items[2].hasLoot=false;tooltips[2]={id=5523,dataInstanceID=812,lines={}}
open.tooltipWait=nil;Status(5523)
equal(open.tooltipWait,nil,"read-only inspection does not register pending tooltip work")
equal(Contains("opening prompt absent"),true,"status explains a missing or incomplete native prompt")
tooltips[2].lines={{leftText=ITEM_OPENABLE}};free=0;Status(5523)
equal(Contains("no free regular bag slot"),true,"status identifies inventory-space pauses")
free=1;_G.MerchantFrame={IsShown=function()return true end};Status(5523)
equal(Contains("MerchantFrame open"),true,"status identifies the exact blocking interaction frame")
_G.MerchantFrame=nil;SetCombat(true);Status(5523)
equal(Contains("Context: combat"),true,"combat diagnostic stops before reading item details")
SetCombat(false);Status({secret=true})
equal(Contains("Usage:"),true,"restricted diagnostic filters are rejected before comparison")
local statusCalls,filtered={},open.Status
open.Status=function(_,id)statusCalls[#statusCalls+1]={id=id}end
SlashCmdList.WOWFOREVERSUITE("containerstatus 5523")
equal(statusCalls[1].id,5523,"slash command forwards the requested readable item ID")
SlashCmdList.WOWFOREVERSUITE("containerstatus")
equal(#statusCalls,2,"slash command also supports general container status")
SlashCmdList.WOWFOREVERSUITE("containerstatus bad")
equal(#statusCalls,2,"invalid command text does not inspect or use items")
open.Status=filtered
open.attempted["new-physical-clam"]=nil;open:Queue();Drain()
equal(#calls,used+4,"the full worker opens a clam when the targeting API returns ordinary nil")
open:OnEvent("LOOT_CLOSED");reject=true;items[2].stackCount=2;Drain();reject=false
equal(open.lastAttempt.result,"native request rejected","status records a rejected native request without raw error text")
open:OnEvent("LOOT_CLOSED");Drain();Suite.Print=originalPrint;targeting=false
local beforePause=#calls
items[2].stackCount=3;open:Queue();SetCombat(true);Drain()
equal(#calls,beforePause,"tooltip-only clams keep the combat pause")
SetCombat(false);_G.MerchantFrame={IsShown=function()return true end};open:Queue();Drain()
equal(#calls,beforePause,"tooltip-only clams keep the vendor pause")
_G.MerchantFrame=nil;open:Queue();Suite.db.autoOpenContainers=false;open:Apply();Drain()
equal(#calls,beforePause,"disable cancels a queued clam opening")
equal(open.tooltipWait,nil,"disable drops pending native tooltip identities")
open:Cancel();for key in pairs(open)do open[key]=nil end;for key,value in pairs(state)do open[key]=value end
for _,key in ipairs(names)do _G[key]=saved[key]end
Suite.db,Suite.pending=oldDB,oldPending;SetCombat(false)
