local Suite,equal,Frame,Combat = ...
local restock,supplies=Suite.MerchantRestock,Suite.SupplyChecklist
local state={};for k,v in pairs(restock)do state[k]=v end
local oldDB,oldSupplies,oldOpen,oldPending=Suite.db,supplies.db,Suite.Vendor.MerchantOpen,Suite.pending
local globals={};local names={"CreateFrame","C_Timer","C_Item","C_MerchantFrame","C_Container","GetMerchantItemID","GetMerchantNumItems","GetMerchantItemMaxStack","BuyMerchantItem","GetMoney","UnitGUID","MerchantFrame","NUM_TOTAL_EQUIPPED_BAG_SLOTS","GetCursorInfo","ClearCursor"}
for _,k in ipairs(names)do globals[k]=_G[k]end
local timers,requests,counts,offers,money,visiting,guid,bagSize,family,locked,unreadable = {},{}, {},{},100000,true,"merchant-A",4,0,false,false
local made=0
Combat(false);Suite.db=Suite.InitializeDB(nil);Suite.pending={};supplies.db={entries={{id=100,wanted=25}}}
for k,v in pairs(restock)do if type(v)~="function"then restock[k]=nil end end
restock.page,restock.selected=1,{}
CreateFrame=function(_,name,parent)
    assert(not InCombatLockdown(),"restocking creates no frames in combat")
    made=made+1;local frame=Frame(name);frame.parent=parent;frame.registered={}
    frame.RegisterEvent=function(self,event)self.registered[event]=true end
    frame.UnregisterAllEvents=function(self)self.registered={}end
    frame.Show=function(self)self.shown=true;if self.OnShow then self:OnShow()end end
    frame.Hide=function(self)local shown=self.shown;self.shown=false;if shown and self.OnHide then self:OnHide()end end
    return frame
end
C_Timer={NewTimer=function(delay,callback)local timer={delay=delay,callback=callback,Cancel=function(self)self.cancelled=true end};timers[#timers+1]=timer;return timer end}
local function Flush()
    local work=timers;timers={}
    for _,timer in ipairs(work)do if not timer.cancelled then if timer.delay<1 then timer.callback()else timers[#timers+1]=timer end end end
end
MerchantFrame=Frame();MerchantFrame:Show();MerchantFrame.selectedTab=1
Suite.Vendor.MerchantOpen=function()return visiting end
UnitGUID=function(unit)equal(unit,"npc","restock uses current merchant identity");return guid end
GetMoney=function()return money end
GetMerchantNumItems=function()return #offers end
GetMerchantItemID=function(index)return offers[index]and offers[index].id end
GetMerchantItemMaxStack=function(index)return offers[index]and offers[index].maximum or 20 end
C_MerchantFrame={GetItemInfo=function(index)return offers[index]end}
C_Item={GetItemInfo=function(id)return "Item "..id,"|Hitem:"..id..":0|h[Item]|h",1,1,1,"Consumable","Food",20 end,GetItemIconByID=function(id)return 1000+id end}
local function Slots()
    local list={};local ids={};for id in pairs(counts)do ids[#ids+1]=id end;table.sort(ids)
    for _,id in ipairs(ids)do local amount=counts[id];while amount>0 do local n=math.min(amount,20);list[#list+1]={itemID=id,stackCount=n,isLocked=locked};amount=amount-n end end
    return list
end
NUM_TOTAL_EQUIPPED_BAG_SLOTS=0
C_Container={GetContainerNumSlots=function()return bagSize end,
    GetContainerNumFreeSlots=function()return math.max(0,bagSize-#Slots()),family end,
    GetContainerItemInfo=function(_,slot)if unreadable then return {secret=true}end;return Slots()[slot]end,
    GetContainerItemID=function(_,slot)local item=Slots()[slot];return item and item.itemID end}
BuyMerchantItem=function(index,quantity)requests[#requests+1]={index=index,quantity=quantity}end
local function Offer(id,bundle,price,stock,maximum)return{id=id,name="Item "..id,stackCount=bundle or 1,price=price or 10,numAvailable=stock or -1,isPurchasable=true,hasExtendedCost=false,maximum=maximum or 5}end
local function Review(target,carry)
    restock:Stop();restock.unconfirmed=nil;timers={};requests={};counts={[100]=carry or 3};offers={Offer(100)};money=100000;visiting=true;guid="merchant-A";bagSize=4;family=0;locked=false;unreadable=false
    supplies.db.entries={{id=100,wanted=target or 25}};restock.merchant=guid
    SlashCmdList.WOWFOREVERSUITE("restock");restock:Refresh()
end
local function Select()restock.selected[100]=true;restock:Refresh()end
local function Confirm()
    local pending=restock.job and restock.job.pending
    if pending then counts[pending.id]=(counts[pending.id]or 0)+pending.quantity;money=money-pending.cost end
    restock:OnEvent("BAG_UPDATE_DELAYED");restock:OnEvent("PLAYER_MONEY");Flush()
end
restock:Apply();equal(made,0,"restocking starts off without frames or merchant hooks")
equal(Suite.db.merchantRestock,false,"merchant restocking default is independently off")
Suite.db.merchantRestock=true;restock:Apply();Review()
assert(loadfile("tests/window_drag_fixture.lua"))(restock.frame,equal,"Restock")
equal(#requests,0,"opening a merchant/restock window never purchases")
equal(Suite.db.supplyChecklist,false,"restocking does not enable checklist recording")
equal(Suite.db.professionShopping,false,"restocking does not enable profession inventory recording")
equal(restock.rows[1].quantity,22,"carried deficit determines quantity")
equal(restock.rows[1].cost,220,"price is per merchant purchase bundle")
equal(restock.frame:GetNumPoints()>0,true,"standalone restock review is anchored")
counts={};supplies.db.entries={}
offers={Offer(100,1),Offer(777,5,100,-1,20)};offers[2].name="Homemade Cherry Pie"
local cursorKind,cursorValue,clears="merchant",2,0
GetCursorInfo=function()return cursorKind,cursorValue end
ClearCursor=function()clears=clears+1;cursorKind,cursorValue=nil,nil end
restock.frame.dropTarget.OnReceiveDrag()
equal(clears,1,"merchant drop clears the accepted cursor")
equal(supplies.db.entries[1].id,777,"merchant cursor index is resolved to the item ID")
equal(supplies.db.entries[1].wanted,5,"first vendor target defaults to one purchase bundle")
equal(restock.frame.rows[1].name:GetText():find("Homemade Cherry Pie",1,true)~=nil,true,"merchant drop shows the offer name")
equal(restock.rows[1].carried,0,"target is available with no copies carried")
equal(restock.rows[1].quantity,5,"saved vendor drop enters the current purchase review")
equal(#requests,0,"saving a drop does not buy or select a purchase")
local inlineTarget=restock.frame.rows[1].target
inlineTarget:SetText("10");inlineTarget.OnEnterPressed(inlineTarget)
equal(restock.rows[1].quantity,10,"edited target quantity refreshes the vendor review")
cursorKind,cursorValue="merchant",2;restock.frame.dropTarget.OnClick()
equal(inlineTarget:GetText(),"10","dropping an existing offer preserves its saved quantity")
equal(#supplies.db.entries,1,"dropping an existing offer cannot duplicate its target")
cursorKind,cursorValue="merchant",3;restock.frame.dropTarget.OnReceiveDrag()
equal(clears,2,"an invalid merchant slot leaves the cursor untouched")
Combat(true);cursorValue=2;restock.frame.dropTarget.OnReceiveDrag();Combat(false)
equal(clears,2,"combat blocks merchant drop processing")
cursorKind,cursorValue="item",888;restock.frame.dropTarget.OnReceiveDrag()
equal(supplies.db.entries[2].id,888,"any item cursor can save a target for a future merchant")
equal(supplies.db.entries[2].wanted,1,"an ordinary item starts with a target of one")
equal(#requests,0,"dropping an unsold item still sends no purchases")
restock.selected[777]=true;restock:Refresh();equal(restock:Start(),true,"explicit purchase works for a dropped vendor target")
Confirm()
equal(counts[777],10,"restocking buys the saved quantity from zero stock")
visiting=false;restock:OnEvent("MERCHANT_CLOSED")
SlashCmdList.WOWFOREVERSUITE("restock")
equal(restock.frame:IsShown(),true,"the saved list opens away from the vendor")
equal(restock.frame.buy:IsShown(),false,"standalone list hides purchase controls")
equal(restock.frame.rows[2].entry.id,888,"standalone list includes targets from other vendors")
local savedRow=restock.frame.rows[2]
savedRow.target:SetText("12");savedRow.target.OnEnterPressed(savedRow.target)
equal(supplies.db.entries[2].wanted,12,"standalone edits update the carried target")
savedRow.automatic:SetChecked(true);savedRow.automatic.OnClick(savedRow.automatic)
equal(supplies.db.entries[2].automatic,true,"standalone list can change per-item purchase mode")
savedRow.remove.OnClick()
equal(#supplies.db.entries,2,"removing a target requires confirmation")
savedRow.remove.OnClick()
equal(#supplies.db.entries,1,"confirmed removal updates the shared saved targets")
equal(#requests,1,"standalone editing sends no purchase requests")
Review()
equal(restock:Start(),false,"no items selected means no purchase")
Select();equal(restock:Start(),true,"explicit approval starts a purchase without a spending-limit field")
equal(#requests,1,"only one purchase may await confirmation")
equal(requests[1].quantity,5,"native purchase maximum limits a single request")
restock:Schedule();Flush();equal(#requests,1,"no bag feedback means no blind retry")
Confirm();equal(#requests,2,"confirmed bag and money changes permit the next batch")
while restock.job do Confirm()end
equal(counts[100],25,"purchasing stops exactly at carried target")
equal(#requests,5,"final purchase only fills remaining deficit")
equal(money,99780,"confirmed purchases respect reviewed total")
Review(12,3);offers[1]=Offer(100,5,100,-1,20);restock:Refresh()
equal(restock.rows[1].quantity,5,"bundle rounds down rather than exceeding target")
equal(restock.rows[1].cost,100,"bundle pricing is not multiplied as a per-item price")
Select();restock:Start();Confirm();equal(counts[100],8,"bundle remainder is left for manual choice")
equal(restock.job,nil,"bundle-limited reviewed quantity completes without overbuying")
Review();local nativeInfo=C_Item.GetItemInfo;local metadataRequests=0
C_Item.GetItemInfo=function()return nil end;C_Item.RequestLoadItemDataByID=function()metadataRequests=metadataRequests+1 end
restock:Refresh();restock:Refresh()
equal(restock.rows[1].quantity,0,"missing stack metadata cannot create a purchase plan")
equal(metadataRequests,1,"missing target metadata is requested once per review")
C_Item.GetItemInfo=nativeInfo;restock:OnEvent("ITEM_DATA_LOAD_RESULT");Flush()
equal(restock.rows[1].quantity,22,"item-data completion refreshes the visible offer")
Review();offers[1].numAvailable=4;restock:Refresh();equal(restock.rows[1].quantity,4,"limited merchant stock bounds purchase review")
Review();offers[1].hasExtendedCost=true;restock:Refresh();equal(restock.rows[1].quantity,0,"extended currency requirements remain manual")
Review();offers[1].price={secret=true};restock:Refresh();equal(restock.rows[1].quantity,0,"unreadable prices never enter cost arithmetic")
Review();offers[1].currencyID=123;restock:Refresh();equal(restock.rows[1].quantity,0,"currency products remain manual even without extended flag")
Review();offers[2]=Offer(100);restock:Refresh();equal(restock.rows[1].quantity,0,"ambiguous duplicate merchant offers remain manual")
Review();Select();offers[1].price=11;equal(restock:Start(),false,"changed price invalidates reviewed purchase")
equal(#requests,0,"price changes cannot silently spend more gold")
Review();Select();supplies.db.entries[1].wanted=30;equal(restock:Start(),false,"changed target requires another review")
Review();Select();money=1;equal(restock:Start(),false,"insufficient funds prevent first request")
Review(25,20);bagSize=1;restock:Refresh();equal(restock.rows[1].quantity,0,"full bags block a purchase")
Review(25,3);bagSize=1;restock:Refresh();equal(restock.rows[1].quantity,17,"partial stack space remains usable without empty slots")
Review();family=32;restock:Refresh();equal(restock.rows[1].quantity,17,"specialty empty slots are excluded conservatively")
Review();unreadable=true;restock:Refresh();equal(restock.rows[1].quantity,0,"unreadable bag contents never become zero carried stock")
Review();locked=true;restock:Refresh();equal(restock.rows[1].quantity,0,"locked bag contents pause purchasing")
Review();offers[1].price=10000;restock:Refresh();Select();equal(restock:Start(),false,"reviewed total cannot exceed available gold")
equal(#requests,0,"insufficient gold sends no purchases")
Review();Select();offers[1].price=11;restock:Refresh();equal(restock.selected[100],nil,"changed preview clears previous selection")
Review();Select();restock:Start();offers[1].numAvailable=0;Confirm();equal(restock.job,nil,"stock exhaustion stops next batch")
equal(#requests,1,"stock exhaustion cannot trigger blind reordering")
Review();Select();restock:Start();money=0;Confirm();equal(restock.job,nil,"money depletion during batch stops subsequent purchases")
equal(#requests,1,"money depletion sends no follow-up purchase")
Review();Select();restock:Start();bagSize=1
while restock.job do Confirm()end
equal(counts[100],20,"lost empty bag space still permits only remaining partial-stack room")
equal(#requests,4,"full bags stop remaining reviewed deficit")
Review();Select();restock:Start();local deadline=restock.deadline;deadline.callback()
equal(restock.job,nil,"unconfirmed request expires without retry")
equal(#requests,1,"timeout never sends another purchase")
local receipt = restock.unconfirmed
restock:OnEvent("MERCHANT_CLOSED");guid="merchant-B";restock:OnEvent("MERCHANT_SHOW")
restock:Open(MerchantFrame);Select()
equal(restock.unconfirmed,receipt,"opening a different merchant preserves the unresolved receipt")
equal(restock:Start(),false,"another merchant cannot purchase while the receipt is unresolved")
restock.frame.clearPending.OnClick()
equal(restock.unconfirmed,receipt,"clearing an unresolved receipt requires confirmation")
restock.frame.clearPending.OnClick()
equal(restock.unconfirmed,nil,"explicit confirmation clears the pending purchase")
equal(next(restock.selected),nil,"manual clearing requires a new purchase selection")
equal(restock:Start(),false,"clearing a receipt cannot purchase")
equal(#requests,1,"manual clearing sends no new request")
Review();Select();restock:Start();guid="merchant-B";Confirm();equal(restock.job,nil,"merchant identity change cancels remaining purchases")
equal(#requests,1,"another merchant cannot receive the next request")
Review(8,3);Select();restock:Start()
local pending = restock.job.pending
restock:OnEvent("MERCHANT_CLOSED");Flush()
equal(restock.job,nil,"merchant closure cancels job")
equal(restock.frame:IsShown(),false,"merchant closure dismisses review")
equal(#requests,1,"merchant closure cancels pending continuation")
restock:OnEvent("MERCHANT_SHOW");restock:Open(MerchantFrame);Select()
equal(restock.unconfirmed,pending,"reopening the same merchant preserves the unresolved request")
equal(restock.frame.buy:IsEnabled(),false,"reopening does not re-enable the Buy button")
equal(restock:Start(),false,"reopening does not permit sending the pending quantity again")
counts[100]=pending.before+pending.quantity;restock:OnEvent("BAG_UPDATE_DELAYED");Flush()
equal(restock.unconfirmed,pending,"late bag feedback alone does not clear a paid purchase")
money=pending.money-pending.cost;restock:OnEvent("PLAYER_MONEY");Flush()
equal(restock.unconfirmed,nil,"late bag and money feedback clear the receipt across visits")
equal(restock.rows[1].quantity,0,"late purchase stock satisfies the target")
equal(#requests,1,"late settlement never resumes the cancelled batch")
Review();Select();restock:Start();local before=made;Combat(true);restock:OnEvent("PLAYER_REGEN_DISABLED");Flush()
equal(restock.job,nil,"combat stops restocking")
equal(made,before,"combat creates no review or merchant widgets")
Combat(false)
Review();Select();restock:Start();local sent=restock.job.pending;restock:Stop()
equal(restock:Start(),false,"stopping an in-flight request cannot immediately send a duplicate")
equal(#requests,1,"unconfirmed prior purchase blocks another request")
counts[100]=sent.before+sent.quantity;money=sent.money-sent.cost;restock:Refresh()
equal(restock.unconfirmed,nil,"late observed bag and money feedback clears uncertainty")
Review();Select();restock:Start();restock:OnEvent("UI_ERROR_MESSAGE");Confirm();equal(#requests,1,"native purchase errors stop without retry")
Review();Select();restock:Start();restock.frame:Hide();Confirm();equal(#requests,1,"closing review stops remaining purchases")
Review();Select();restock:Start();Confirm();offers[1].price=50;Confirm();equal(restock.job,nil,"price change during batch stops the next purchase")
Review();Select();restock:Start();counts[100]=8;restock:OnEvent("BAG_UPDATE_DELAYED");Flush();equal(#requests,1,"inventory-only feedback cannot confirm a paid purchase")
restock:Stop()
local function Visit()
    restock:OnEvent("MERCHANT_CLOSED")
    restock:OnEvent("MERCHANT_SHOW")
    Flush()
end
Review(20);counts={};offers={Offer(100,5,3600,-1,20)};offers[1].name="Homemade Cherry Pie"
Visit()
equal(restock.frame:IsShown(),true,"vendor visit opens the default shortage confirmation")
equal(restock.frame.buy:GetText(),"Buy 20 items","confirmation names the actual missing quantity")
equal(restock.frame.total:GetText():find("1g 44s 0c",1,true)~=nil,true,"confirmation shows the exact total")
equal(#requests,0,"an unchecked target never purchases on opening")
restock.frame:Hide();restock:OnEvent("MERCHANT_UPDATE");Flush()
equal(restock.frame:IsShown(),false,"a merchant update cannot reopen a skipped confirmation")
equal(#requests,0,"skipping a confirmation never purchases")
Visit()
restock.frame.buy.OnClick();Confirm()
equal(counts[100],20,"confirming buys the target quantity")
Visit()
equal(restock.frame:IsShown(),false,"a stocked visit does not prompt")
equal(#requests,1,"a stocked visit sends no further purchases")
Review(20);counts={};offers={Offer(100,5,3600,-1,20),Offer(777,1,20,-1,20)}
supplies:Save(777,2);restock:Refresh()
local automatic=restock.frame.rows[1].automatic
automatic:SetChecked(true);automatic.OnClick(automatic)
equal(supplies.db.entries[1].automatic,true,"the checkbox saves per-item opt-in")
equal(#requests,0,"checking a target waits for a future visit")
supplies:InitializeCharacter(supplies.db);supplies:Save(100,20)
equal(supplies.db.entries[1].automatic,true,"loading and editing a target preserve automatic purchase")
Visit()
equal(#requests,1,"checked target purchases on vendor open")
equal(requests[1].index,1,"only the checked offer can purchase automatically")
equal(requests[1].quantity,20,"automatic purchase fills the checked deficit")
Confirm()
equal(#requests,1,"unchecked target waits after the automatic purchase")
equal(restock.selected[777],true,"unchecked shortage is selected for confirmation")
restock.frame.buy.OnClick();Confirm()
equal(counts[777],2,"confirming the remaining unchecked target purchases it")
Review(20);counts={};offers={Offer(100,5,3600,-1,20)};supplies.db.entries[1].automatic=true
restock:OnEvent("MERCHANT_CLOSED");restock:OnEvent("MERCHANT_SHOW");restock:OnEvent("MERCHANT_CLOSED");Flush()
equal(#requests,0,"merchant closure cancels an automatic purchase before dispatch")
money=100;Visit()
equal(#requests,0,"automatic purchasing respects available gold")
equal(restock.frame.buy:IsEnabled(),false,"an unaffordable review leaves purchase disabled")
money=100000;Visit()
equal(#requests,1,"new visit can send the affordable automatic purchase")
Visit()
equal(#requests,1,"an unresolved automatic purchase survives reopening without another request")
equal(restock.frame.buy:IsEnabled(),false,"an unresolved automatic purchase blocks confirmation too")
Suite.db.merchantRestock=false;restock:Apply();equal(next(restock.events.registered),nil,"disabling feature releases all merchant events")
equal(restock.launcher:IsShown(),false,"disabling feature hides merchant launcher")
for k in pairs(restock)do restock[k]=nil end;for k,v in pairs(state)do restock[k]=v end
Suite.db,supplies.db,Suite.Vendor.MerchantOpen,Suite.pending=oldDB,oldSupplies,oldOpen,oldPending
for _,k in ipairs(names)do _G[k]=globals[k]end
Combat(false)
