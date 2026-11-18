local Suite, equal, Frame, Combat = ...
local shopping, supplies, leveling, inventory = Suite.ShoppingList, Suite.SupplyChecklist, Suite.ProfessionLeveling, Suite.Inventory
local saved = { db = Suite.db, supplies = supplies.db, skills = leveling.skills, material = leveling.MaterialPlan,
    scan = inventory.ScanContainers, guid = inventory.guid, set = Suite.Set, capture = leveling.CaptureSkills,
    refresh = supplies.Refresh, frame = supplies.frame, print = Suite.Print }
local state = {}; for key, value in pairs(shopping) do state[key] = value end
local names = { "CreateFrame", "UnitGUID", "GetCurrentRegion", "C_Item", "C_Timer", "NUM_TOTAL_EQUIPPED_BAG_SLOTS", "AuctionHouseFrame", "GameTooltip", "MouseIsOver" }
local globals = {}; for _, name in ipairs(names) do globals[name] = _G[name] end
local timers, made, scans = {}, 0, 0
Combat(false); Suite.db = Suite.InitializeDB(nil); supplies.db = { entries = { { id = 777, wanted = 3 } }, professionPlans = {} }
supplies.frame = nil; supplies.Refresh = function() end; Suite.Print = function() end
for key in pairs(shopping) do if type(shopping[key]) ~= "function" then shopping[key] = nil end end
shopping.page, shopping.requested = 1, {}
CreateFrame = function(_, name, parent, template)
    assert(not InCombatLockdown(), "shopping never creates frames in combat")
    made = made + 1
    local frame = Frame(name); frame.parent = parent; frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    frame.Show = function(self) self.shown = true; if self.OnShow then self:OnShow() end end
    frame.Hide = function(self) local shown = self.shown; self.shown = false; if shown and self.OnHide then self:OnHide() end end
    if template == "InputScrollFrameTemplate" then
        frame.EditBox = Frame(); frame.EditBox.parent = frame
        frame.EditBox.SetFocus = function(self) self.focused = true end
        frame.EditBox.HighlightText = function(self) self.highlighted = true end
    end
    return frame
end
UnitGUID = function() return "current" end; GetCurrentRegion = function() return 110 end
NUM_TOTAL_EQUIPPED_BAG_SLOTS = 4
C_Item = { GetItemNameByID = function(id) return id == 100 and "Cloth" or nil end, RequestLoadItemDataByID = function() end }
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
local function Flush()
    local work = timers; timers = {}
    for _, timer in ipairs(work) do if not timer.cancelled then timer.callback() end end
end
local guideA = { name = "Shopping test A", estimates = true, sections = { { 0, 50 }, { 50, 100 } } }
local guideB = { name = "Shopping test B", estimates = true, sections = { { 0, 50 } } }
Suite.ProfessionGuides[#Suite.ProfessionGuides + 1] = guideA
Suite.ProfessionGuides[#Suite.ProfessionGuides + 1] = guideB
leveling.skills = {}
leveling.CaptureSkills = function() end
local malformed = false
leveling.MaterialPlan = function(_, guide, rank)
    local id = 100; if malformed then id = nil end
    local row = { { guide == guideA and 100 or 40, id, "Cloth" } }
    return { [row] = rank >= 50 }, {}, { { endSkill = 50, rows = { row } } }
end
local function Snapshot(amount, at) return { items = { [100] = amount }, at = at or 1000 } end
Suite.db.inventory = { schema = 1, characters = {
    current = { name = "Current", realm = "Realm", region = 110, bags = Snapshot(99), bank = Snapshot(10) },
    alt = { name = "Alt", realm = "Realm", region = 110, bags = Snapshot(20), bank = Snapshot(30) },
    foreign = { name = "Foreign", realm = "Realm", region = 1, bags = Snapshot(999), bank = Snapshot(999) },
}, accountBanks = { [110] = Snapshot(5) } }
inventory.guid = "current"
inventory.ScanContainers = function(_, ids, bank)
    scans = scans + 1; equal(#ids, 5, "shopping scans all carried containers")
    equal(bank, false, "shopping never reads inaccessible live bank containers")
    return Snapshot(15, 2000)
end
Suite.Set = function(key, value) Suite.db[key] = value end
equal(shopping:Enabled(), false, "shopping recording starts off independently")
AuctionHouseFrame = Frame(); AuctionHouseFrame.IsForbidden = function() return false end; AuctionHouseFrame:Show()
local before = made; shopping:Apply()
equal(made, before, "disabled shopping creates no event frame or auction launcher")
equal(shopping:Review("Shopping test A", 0), true, "modeled guide can be reviewed")
equal(shopping.pending.name, "Shopping test A", "first window construction retains review")
equal(shopping.frame:GetNumPoints(),1,"standalone shopping preview has an initial screen position")
equal(next(shopping:Plans()), nil, "preview does not save plans")
equal(scans, 0, "preview with tracking off uses only saved records")
equal(Suite.db.professionShopping, false, "review does not enable recording")
equal(shopping:SavePlan(), true, "explicit save commits and enables recording")
equal(supplies.db.entries[1].wanted, 3, "profession plans preserve manual targets")
equal(Suite.db.professionShopping, true, "Save & track opts into stock recording")
equal(inventory:Enabled(), true, "shopping enables stock capture on characters without inventory tooltips")
local rows = shopping:Rows()
equal(#rows, 1, "one material target is available")
equal(rows[1].wanted, 100, "stores full requirements rather than a pre-subtracted deficit")
equal(rows[1].count, 80, "fresh 15 bags plus 10 bank plus alt 20/30 plus shared 5")
equal(rows[1].need, 20, "all character and bank materials subtract once")
equal(rows[1].incomplete, false, "all recorded locations make a complete observed count")
equal(rows[1].oldestAt, 1000, "fresh current bags do not hide older bank and alt dates")
equal(Suite.db.inventory.characters.current.bags.items[100], 99, "preview count override never mutates saved inventory")
shopping:Review("Shopping test A", 0); shopping:SavePlan()
equal(shopping:Rows()[1].wanted, 100, "tracking the same guide updates instead of duplicating")
shopping:Review("Shopping test B", 0); shopping:SavePlan()
rows = shopping:Rows(); equal(rows[1].wanted, 140, "different profession requirements merge by item ID")
equal(rows[1].need, 60, "shared stock subtracts once after combining requirements")
shopping:Refresh()
equal(shopping.frame.rows[1].title.text, "Cloth", "shopping item column contains only the item name")
equal(shopping.frame.rows[1].required.text, "140", "shopping requirement has its own column")
equal(shopping.frame.rows[1].stock.text, "80", "shopping stock has its own column")
equal(shopping.frame.rows[1].buy.text, "60", "shopping purchase quantity has its own column")
equal(shopping.frame.rows[1].icon.texture, 134400, "uncached shopping icon has a visible placeholder")
local required, stock, buy = shopping:QuantityCells({ wanted=96, count=20, need=76, incomplete=true })
equal(required,"96","required quantity remains explicit with partial stock")
equal(stock,"20+","partial stock is visibly a lower bound")
equal(buy,"Up to 76","partial purchase is visibly an upper bound")
required,stock,buy = shopping:QuantityCells({wanted=96})
equal(stock,"Unknown","missing records never display zero stock")
equal(buy,"Check stock","missing records never display a definite purchase")
required,stock,buy = shopping:QuantityCells({wanted=96,count=96,need=0})
equal(buy,"0 · Stocked","covered requirement has a written status as well as color")
local clickHandler, clickedID, clickedButton = Suite.Items.ModifiedClick
Suite.Items.ModifiedClick = function(_, id, button) clickedID, clickedButton = id, button; return true end
shopping.frame.rows[1].OnClick(shopping.frame.rows[1], "LeftButton")
equal(clickedID,100,"shopping row links its own material item")
equal(clickedButton,"LeftButton","shopping row preserves native mouse-button semantics")
Suite.Items.ModifiedClick = clickHandler
local tip = Frame(); tip.IsForbidden = function() return false end
local tooltipID, tooltipOwner, hides = nil, nil, 0
tip.SetOwner = function(_, owner) tooltipOwner = owner end
tip.GetOwner = function() return tooltipOwner end
tip.SetItemByID = function(_, id) tooltipID = id end
tip.Hide = function(self) self.shown = false; hides = hides + 1 end
GameTooltip = tip
local hoveredRow = shopping.frame.rows[1]
hoveredRow.OnEnter()
equal(tooltipID,100,"hovering shopping row opens the native item tooltip")
equal(tooltipOwner,hoveredRow,"shopping tooltip belongs to the hovered row")
equal(tip:IsShown(),true,"shopping item tooltip is shown")
hoveredRow.OnLeave()
equal(tip:IsShown(),false,"leaving shopping item clears its tooltip")
hoveredRow.OnEnter(); MouseIsOver = function(row) return row == hoveredRow end
shopping:Refresh()
equal(shopping.hovered,hoveredRow,"metadata refresh restores the same item under the pointer")
MouseIsOver = function() return false end
shopping:Refresh()
equal(shopping.hovered,nil,"refresh without pointer clears shopping tooltip")
hoveredRow.OnEnter(); local beforeHides = hides; tooltipOwner = Frame()
shopping:HideTooltip()
equal(hides,beforeHides,"shopping cleanup preserves another window's tooltip")
local nativeSetter = tip.SetItemByID; tip.SetItemByID = nil
hoveredRow.OnEnter()
equal(shopping.hovered,nil,"missing native item setter safely suppresses shopping tooltip")
tip.SetItemByID = function() error("unavailable item") end
hoveredRow.OnEnter()
equal(shopping.hovered,nil,"failed native item lookup clears owned tooltip")
tip.SetItemByID = nativeSetter
Combat(true); tooltipID = nil; hoveredRow.OnEnter()
equal(tooltipID,nil,"shopping never opens an item tooltip in combat")
Combat(false)
hoveredRow.OnEnter(); hoveredRow:Hide()
equal(shopping.hovered,nil,"hidden shopping row clears tooltip ownership")
shopping:Refresh()
leveling.skills[guideA.name] = { rank = 50, maximum = 300 }
equal(shopping:Rows()[1].wanted, 40, "completed profession steps stop requesting materials")
leveling.skills = {}
Suite.db.inventory.characters.alt.bank = nil
rows = shopping:Rows()
equal(rows[1].count, 50, "missing bank record does not invent its contents")
equal(rows[1].need, 90, "partial records produce a bounded estimate")
equal(rows[1].incomplete, true, "missing bank is explicitly incomplete")
inventory.ScanContainers = function() return nil end
rows = shopping:Rows()
equal(rows[1].count, 35, "failed fresh scan excludes stale current bags instead of treating them as current")
equal(rows[1].incomplete, true, "failed bag scan retains incomplete state")
Suite.db.inventory = { schema = 1, characters = {}, accountBanks = {} }
rows = shopping:Rows()
equal(rows[1].need, nil, "no readable observation produces unknown shortage")
inventory.ScanContainers = function() return Snapshot(7) end
rows = shopping:Rows()
equal(rows[1].count, 7, "unrecorded current character contributes fresh bags once")
equal(rows[1].incomplete, true, "fresh bags cannot prove an unrecorded bank empty")
local plans = shopping:Normalize({ [guideA.name] = { rank = 0, endSkill = 50 }, [guideB.name] = { rank = {secret=true} } })
equal(plans[guideA.name].endSkill, 50, "section choice survives normalization")
equal(plans[guideB.name], nil, "restricted skill cannot become a saved plan")
plans = shopping:Normalize({ [guideA.name] = { rank = 0, endSkill = 13 }, unknown = { rank = 0 } })
equal(next(plans), nil, "unknown sections and guide names cannot persist")
plans = shopping:Normalize(supplies.db.professionPlans)
plans[guideA.name].rank = 3
equal(supplies.db.professionPlans[guideA.name].rank, 0, "normalized plans are independent copies")
malformed = true
local targets, missing = shopping:Targets(supplies.db.professionPlans)
equal(#targets, 0, "unresolved item IDs cannot become arbitrary shopping entries")
equal(missing, true, "unexportable material is disclosed")
malformed = false
local fixtureMaterial = leveling.MaterialPlan
leveling.MaterialPlan = saved.material
for _, guide in ipairs(Suite.ProfessionGuides) do
    if guide ~= guideA and guide ~= guideB and guide.estimates then
        local _, totals = leveling:MaterialPlan(guide, 125)
        local projected = shopping:Targets({ [guide.name] = { rank = 125 } })
        local actual = {}; for _, target in ipairs(projected) do actual[target.id] = target.wanted end
        for id, amount in pairs(totals) do
            if type(id) == "number" then equal(actual[id], amount, "shopping preserves actual guide totals for " .. guide.name .. " item " .. id) end
        end
    end
end
leveling.MaterialPlan = function()
    local row = {}; for id = 1, 40 do row[#row + 1] = { 1, id, "Material " .. id } end
    return { [row] = false }, {}, { { endSkill = 50, rows = { row } } }
end
equal(#shopping:Targets({ [guideA.name] = { rank = 0 } }), 40, "profession plans do not inherit the manual checklist's 32-item limit")
leveling.MaterialPlan = fixtureMaterial
equal(shopping.frame.export,nil,"shopping no longer creates an export text field")
equal(shopping.frame.copy,nil,"shopping no longer creates an export copy button")
shopping:Apply(); equal(shopping.auctionButton.parent, AuctionHouseFrame, "small launcher belongs to auction window")
equal(shopping.auctionButton:IsShown(), true, "tracking exposes auction launcher")
shopping.auctionButton.OnClick(); equal(shopping.frame:IsShown(), true, "auction launcher opens saved shopping list")
equal(shopping.pending, nil, "auction launcher never uses an unsaved preview")
local oldMenu, menuButtons = Suite.Menus.CreateContextMenu
Suite.Menus.CreateContextMenu = function(_, callback)
    menuButtons = {}
    callback(nil, { CreateTitle = function() end, CreateButton = function(_, text, callback) menuButtons[#menuButtons + 1] = { text = text, callback = callback } end })
end
shopping:Manage(shopping.frame.manage); menuButtons[1].callback()
equal(shopping:Plans()[guideA.name] ~= nil, true, "first remove action only stages confirmation")
menuButtons[1].callback()
equal(shopping:Plans()[guideA.name], nil, "confirmed removal affects the selected profession")
equal(shopping:Plans()[guideB.name] ~= nil, true, "removing one profession preserves the other plan")
equal(supplies.db.entries[1].wanted, 3, "removing a profession preserves manual supplies")
Suite.Menus.CreateContextMenu = oldMenu
shopping.frame.header.OnDragStart()
equal(shopping.moving, true, "owned shopping header supports outside-combat movement")
shopping:Queue(); local timer = shopping.timer
Combat(true); before = made
shopping.events.OnEvent(shopping.events, "PLAYER_REGEN_DISABLED"); Flush()
equal(timer.cancelled, true, "combat cancels queued shopping refresh")
equal(shopping.moving, nil, "combat ends shopping header movement")
equal(shopping:Review(guideA.name, 0), false, "combat cannot stage a plan")
equal(shopping:SavePlan(), false, "combat cannot commit plans")
shopping:AuctionButton(); equal(made, before, "combat never creates an auction child")
equal(shopping.frame.manage:IsEnabled(), false, "combat disables shopping interactions")
Combat(false); shopping.events.OnEvent(shopping.events, "PLAYER_REGEN_ENABLED"); Flush()
equal(shopping.frame.manage:IsEnabled(), true, "combat exit restores ordinary shopping input")
shopping.frame.rows[1].OnEnter()
shopping:Queue(); timer = shopping.timer; shopping.frame:Hide(); Flush()
equal(shopping.hovered,nil,"closing shopping clears the current item tooltip")
equal(timer.cancelled, true, "closing shopping cancels its deferred refresh")
Suite.db.professionShopping = false; shopping:Apply()
equal(shopping.auctionButton:IsShown(), false, "opt-out hides auction launcher")
equal(next(shopping.events.registered), nil, "disabled hidden shopping retains no feature events")
local persisted = supplies:InitializeCharacter({ entries = {}, professionPlans = { [guideA.name] = { rank = 4 } } })
equal(persisted.professionPlans[guideA.name].rank, 4, "plan persists in the character supply store")
table.remove(Suite.ProfessionGuides); table.remove(Suite.ProfessionGuides)
shopping:Cancel()
for key in pairs(shopping) do shopping[key] = nil end; for key, value in pairs(state) do shopping[key] = value end
Suite.db, Suite.Set, Suite.Print = saved.db, saved.set, saved.print
supplies.db, supplies.Refresh, supplies.frame = saved.supplies, saved.refresh, saved.frame
leveling.skills, leveling.MaterialPlan, leveling.CaptureSkills = saved.skills, saved.material, saved.capture
inventory.ScanContainers, inventory.guid = saved.scan, saved.guid
for _, name in ipairs(names) do _G[name] = globals[name] end
Combat(false)
