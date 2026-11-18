local Suite, equal, Frame, Combat = ...
local items = Suite.Items
local oldItem, oldCreate, oldPending = C_Item, CreateFrame, Suite.pending
local saved = {}; for k,v in pairs(items) do saved[k]=v end
items.listIcons,items.listIconEvents,items.listIconRequested = nil,nil,nil
Suite.pending = {}; Combat(false)
local created, requested, ready = 0, {}, { [1]=12345 }
CreateFrame = function()
    assert(not InCombatLockdown(), "list icons never create event frames in combat")
    created=created+1
    local frame=Frame(); frame.registered={}
    frame.RegisterEvent=function(self,event) self.registered[event]=true end
    frame.UnregisterAllEvents=function(self) self.registered={} end
    return frame
end
C_Item = { GetItemIconByID=function(id) return ready[id] end,
    RequestLoadItemDataByID=function(id) requested[id]=(requested[id] or 0)+1 end }
local function Owner()
    local frame=Frame(); frame:Show()
    frame.IsVisible=function(self) return self.shown end
    return frame
end
local parent=Owner()
local icon=items:CreateListIcon(parent,26,0,0)
items:SetListIcon(icon,1)
equal(icon.texture,12345,"item list uses native icon independent of item-level toggle")
equal(created,0,"cached icons need no event frame")
items:SetListIcon(icon,2)
equal(icon.texture,134400,"missing icon gets question mark rather than blank space")
equal(requested[2],1,"uncached icon gets one request")
items:SetListIcon(icon,2)
equal(requested[2],1,"repeated rendering never polls missing icons")
equal(items.listIconEvents.registered.ITEM_DATA_LOAD_RESULT,true,"pending visible icon listens for data completion")
ready[2]=23456
items.listIconEvents.OnEvent(items.listIconEvents,"ITEM_DATA_LOAD_RESULT",3)
equal(icon.texture,134400,"unrelated item event cannot replace current row icon")
items.listIconEvents.OnEvent(items.listIconEvents,"ITEM_DATA_LOAD_RESULT",2)
equal(icon.texture,23456,"completion replaces placeholder without reopening")
equal(next(items.listIconEvents.registered),nil,"resolved icons release metadata events")
items:SetListIcon(icon,3); items:SetListIcon(icon,1)
ready[3]=34567
items.listIconEvents.OnEvent(items.listIconEvents,"ITEM_DATA_LOAD_RESULT",3)
equal(icon.texture,12345,"recycled row never receives the previous item's icon")
items:SetListIcon(icon,4)
parent:Hide(); if parent.OnHide then parent.OnHide(parent) end
equal(next(items.listIcons),nil,"hidden rows release pending icon references")
equal(next(items.listIconEvents.registered),nil,"closing last pending list releases events")
parent:Show(); if parent.OnShow then parent.OnShow(parent) end
equal(items.listIcons[icon],4,"reopening an unresolved row restores its metadata listener")
equal(requested[4],1,"reopening never retries unresolved icon indefinitely")
equal(items:Icon({secret=true}),134400,"restricted item IDs cannot reach native icon API")
ready[5]={secret=true}
equal(items:Icon(5),134400,"restricted icon output cannot enter texture arithmetic or markup")
equal(items:IconText(1,"Ore"),"|T12345:16:16:0:0|t Ore","menu item labels include bounded native texture markup")
items.listIcons,items.listIconEvents = nil,nil
Combat(true)
local before=created
items:SetListIcon(icon,6)
equal(created,before,"combat never creates lazy icon event frame")
equal(requested[6],nil,"combat does not request item icon data")
equal(type(Suite.pending.listIcons),"function","first combat placeholder defers initialization")
parent:Hide(); if parent.OnHide then parent.OnHide(parent) end
equal(Suite.pending.listIcons,nil,"hidden row cancels deferred combat icon work")
Combat(false)
for k in pairs(items) do items[k]=nil end; for k,v in pairs(saved) do items[k]=v end
C_Item,CreateFrame,Suite.pending = oldItem,oldCreate,oldPending
