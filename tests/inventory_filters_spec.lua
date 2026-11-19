local Suite, equal = ...
local search, browser = Suite.InventorySearch, Suite.CharacterBrowser
local oldDB, oldTime, oldRegion, oldGUID, oldItem = Suite.db, GetServerTime, GetCurrentRegion, UnitGUID, C_Item
local function Save(object) local saved = {}; for k,v in pairs(object) do saved[k]=v end; return saved end
local function Restore(object, saved) for k in pairs(object) do object[k]=nil end; for k,v in pairs(saved) do object[k]=v end end
local savedSearch, savedBrowser = Save(search), Save(browser)
GetServerTime = function() return 200000 end
GetCurrentRegion = function() return 110 end
UnitGUID = function() return "main" end
Suite.db = { inventory = {} }
local oldDatabase = Suite.Inventory.Database
Suite.Inventory.Database = function() return { characters = {
    main = { name="Main",realm="Realm",region=110,bags={at=199999,items={[1]=2,[2]=1,[3]=1,[4]=1}},bank={at=100000,items={[1]=3}} },
    alt = { name="Alt",realm="Realm",region=110,bags={at=200001,items={[1]=7}} },
},accountBanks={ [110]={at=113600,items={[1]=5}} } } end
C_Item = { GetItemInfo = function(id)
    if id == 4 then return "Incomplete" end
    return "Item " .. id,nil,id == 1 and 2 or 3,1,1,"Type","Subtype",20,id == 2 and "INVTYPE_HEAD" or "",123,0,id == 3 and 0 or 7,0,0,0,nil,id == 1
end, RequestLoadItemDataByID = function() end }
search.index, search.metadata, search.requested = nil, {}, {}
local function Query(filters) return search:Query("",{browse=true,filters=filters}) end
local rows = Query({age="recent"})
equal(#rows,4,"recent source filter retains current bags")
equal(rows[1].bank,nil,"old bank excluded independently from same owner's fresh bags")
rows = Query({age="stale"})
equal(#rows,2,"stale source filter includes personal and shared banks")
equal(rows[1].bank,3,"stale filter uses only old source counts")
equal(rows[1].bags,nil,"fresh bags not added to stale bank")
equal(rows[2].account,5,"shared bank counts once and the exact 24h boundary is stale")
rows = Query({age="unknown"})
equal(#rows,1,"future timestamps are unknown rather than recent")
equal(rows[1].owner.guid,"alt","unknown age points to actual source")
rows = Query({kind="reagents"})
equal(#rows,3,"reagent filter uses native boolean and preserves owners")
rows = Query({kind="equipment"})
equal(#rows,1,"equipment filter uses equip location")
equal(rows[1].id,2,"equipment category does not infer from localized names")
rows = Query({kind="consumables",quality="3"})
equal(#rows,1,"quality and type filters intersect")
equal(rows[1].id,3,"consumable class identified")
local pending
rows,pending = Query({quality="unknown"})
equal(#rows,1,"unknown quality explicitly browsable")
equal(rows[1].id,4,"partial metadata is retained in unknown quality")
rows,pending = Query({kind="quest"})
equal(#rows,0,"missing type never guessed to match quest category")
equal(pending,1,"partial metadata reported while filtering")
equal(search.requested[4],true,"partial metadata receives finite async request")
equal(#Query({kind=false}),0,"malformed filter rejects rather than widens results")
equal(search:NormalizeFilters({age="future"}),nil,"unknown enum is rejected")
local migrated = browser:InitializeOptions({favorites={
    {name="My Ore",query="Ore",owner="main",location="bags"},
    {name="Alt Ore",query="Ore",owner="alt",location="bank"},
}})
equal(migrated.favorites[1].filters.kind,"all","old saved searches migrate to unrestricted categories")
equal(migrated.favorites[1].name,"My Ore","the first saved name survives when two categories become equivalent")
equal(#migrated.favorites,1,"obsolete scopes no longer distinguish identical categories")
equal(migrated.favorites[1].owner,nil,"old saved owner is removed")
equal(migrated.favorites[1].location,nil,"old saved location is removed")
local normalized = browser:InitializeOptions({favorites={{name="Metals",query="",location="bank",filters={kind="reagents",quality="2",age="stale"}}}})
equal(normalized.favorites[1].name,"Metals","custom category names retained")
equal(normalized.favorites[1].filters.age,"stale","category source age retained")
equal(#browser:InitializeOptions({favorites={{query="",location="all",filters={kind=false}}}}).favorites,0,"malformed saved rules never become broader categories")
Suite.db.inventoryBrowser = normalized
browser.visible, browser.categoryName = false, nil
browser:LoadView(1)
equal(browser.filters.kind,"reagents","loading category restores item type")
browser.filters.kind="equipment"
equal(normalized.favorites[1].filters.kind,"reagents","active filters do not alias saved category rules")
browser.query = ""
browser:SaveView()
equal(#normalized.favorites,2,"different filters distinguish saved categories with same query")
Restore(search,savedSearch); Restore(browser,savedBrowser)
Suite.Inventory.Database = oldDatabase
Suite.db,GetServerTime,GetCurrentRegion,UnitGUID,C_Item = oldDB,oldTime,oldRegion,oldGUID,oldItem
