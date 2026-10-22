local Suite, equal, Frame, SetCombat = ...
local inventory, tips = Suite.Inventory, Suite.Tooltips
local old = { CreateFrame = CreateFrame, C_Timer = C_Timer, C_Container = C_Container, C_Bank = C_Bank,
    UnitGUID = UnitGUID, UnitName = UnitName, UnitClass = UnitClass, GetNormalizedRealmName = GetNormalizedRealmName,
    GetRealmName = GetRealmName, GetCurrentRegion = GetCurrentRegion, GetServerTime = GetServerTime,
    NUM_TOTAL_EQUIPPED_BAG_SLOTS = NUM_TOTAL_EQUIPPED_BAG_SLOTS, NUM_BAG_SLOTS = NUM_BAG_SLOTS,
    BankFrame = BankFrame, Enum = Enum, RAID_CLASS_COLORS = RAID_CLASS_COLORS, CLASS_ICON_TCOORDS = CLASS_ICON_TCOORDS }
local oldDB, oldPending = Suite.db, Suite.pending
local bags, timers, calls, frames = {}, {}, 0, 0
local identity = { guid = "Player-1-1", name = "First", realm = "RealmA", class = "MAGE", region = 110 }
local viewable, tabIDs, purchased = {}, { [0] = { 6, 7 }, [2] = { 13 } }, { [0] = 2, [2] = 1 }
local now = 100
local function Item(id, count) return { itemID = id, stackCount = count } end
local function Flush()
    local queued = timers; timers = {}
    for _, timer in ipairs(queued) do if not timer.cancelled then timer.callback() end end
end
local function TimerCount()
    local count = 0
    for _, timer in ipairs(timers) do if not timer.cancelled then count = count + 1 end end
    return count
end
local function Fire(event) inventory.events.OnEvent(inventory.events, event) end
local function Hover(data, tooltip)
    tooltip = tooltip or Frame()
    tips:Item(tooltip, data)
    return tooltip
end
local function HasLine(tooltip, label)
    for _, line in ipairs(tooltip.lines) do
        if line[1]:gsub("|T.-|t%s*", "") == label then return line end
    end
end
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
inventory.active, inventory.events, inventory.timer, inventory.guid, inventory.bankOpen = nil, nil, nil, nil, nil
CreateFrame = function(...)
    assert(not InCombatLockdown(), "inventory frame creation must defer during combat")
    frames = frames + 1
    local frame = old.CreateFrame(...)
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    return frame
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
UnitGUID = function() return identity.guid end
UnitName = function() return identity.name end
UnitClass = function() return identity.class, identity.class end
GetNormalizedRealmName = function() return identity.realm end
GetCurrentRegion = function() return identity.region end
GetServerTime = function() return now end
NUM_TOTAL_EQUIPPED_BAG_SLOTS, NUM_BAG_SLOTS = 5, 4
Enum = { BankType = { Character = 0, Account = 2 }, TooltipDataType = old.Enum.TooltipDataType }
RAID_CLASS_COLORS = { MAGE = { r = 0.4, g = 0.8, b = 1 } }
CLASS_ICON_TCOORDS = { MAGE = { 0.25, 0.49609375, 0, 0.25 } }
BankFrame = Frame(); BankFrame:Hide()
C_Container = {
    GetContainerNumSlots = function(bag) calls = calls + 1; return bags[bag] and bags[bag].slots or 0 end,
    GetContainerItemInfo = function(bag, slot) return bags[bag] and bags[bag][slot] end,
    GetContainerItemID = function(bag, slot) return bags[bag] and bags[bag].pending and bags[bag].pending[slot] end,
}
C_Bank = {
    CanViewBank = function(kind) return viewable[kind] or false end,
    FetchPurchasedBankTabIDs = function(kind) return tabIDs[kind] end,
    FetchNumPurchasedBankTabs = function(kind) return purchased[kind] end,
}
bags[0] = { slots = 3, Item(6948, 1), Item(100, 7), Item(100, 5) }
bags[5] = { slots = 1, Item(100, 3) }
bags[6] = { slots = 2, Item(100, 10), Item(6948, 1) }
bags[7] = { slots = 1, Item(100, 20) }
bags[13] = { slots = 1, Item(100, 50) }
equal(Suite.db.itemInventory, false, "inventory starts off independently")
inventory:Apply()
equal(frames, 0, "disabled inventory constructs no frames")
equal(calls, 0, "disabled inventory does not scan bags")
equal(Hover({ id = 100 }).lines[1], nil, "disabled inventory adds no tooltip lines")

Suite.db.itemInventory = true
for _, region in ipairs({ 0, -1, 110.5, math.huge, { secret = true } }) do
    identity.region = region; inventory:Refresh()
    equal(next(Suite.db.inventory.characters), nil, "invalid or restricted region cannot become a saved inventory scope")
end
identity.region = nil; inventory:Refresh()
equal(next(Suite.db.inventory.characters), nil, "missing region remains unavailable without inventing a scope")
identity.region = 110
SetCombat(true); inventory:Apply()
equal(frames, 0, "first enable defers construction during combat")
equal(type(Suite.pending.inventory), "function", "first combat enable queues one initializer")
Suite.db.itemInventory = false; inventory:Apply()
equal(Suite.pending.inventory, nil, "disable cancels deferred enable")
Suite.db.itemInventory = true
SetCombat(false); inventory:Apply()
local first = Suite.db.inventory.characters[identity.guid]
equal(type(first), "table", "live beta region 110 must not prevent recording the current character")
equal(first.region, 110, "preserve the actual beta region rather than mapping it to a guessed region")
equal(first.bags.items[100], 15, "duplicate stacks and reagent bag combine actual item quantities")
equal(first.bags.items[6948], 1, "all item types including hearthstones are tracked")
equal(first.bank, nil, "unvisited banks remain unknown")
equal(first.bags.at, now, "snapshots record a readable server timestamp")
equal(inventory.events.registered.PLAYER_LOGOUT, true, "logout flushes the current character")
local initial = Hover({ id = 100 })
equal(HasLine(initial, "Inventory")[2], "|cff80bfffKnown total:|r 15", "unknown bank gives a known subtotal with blue label and white value")
equal(HasLine(initial, "First")[2], "|cff80bfffBags:|r 15", "unvisited bank is hidden without a question mark or trailing comma")
equal(HasLine(initial, "First")[1]:find("UI-CharacterCreate-Classes:16:16:0:0:256:256:64:127:0:64", 1, true) ~= nil,
    true, "character icon uses the native class texture and coordinates")
equal(#initial.lines, 3, "single-character inventory stays compact without explanatory footer lines")
local recordedBags = first.bags
first.bags, first.bank = nil, { items = { [100] = 12 } }
local bankOnly = Hover({ id = 100 })
equal(HasLine(bankOnly, "First")[2], "|cff80bfffBank:|r 12", "recorded bank remains visible when bags have not been recorded")
equal(HasLine(bankOnly, "Inventory")[2], "|cff80bfffKnown total:|r 12", "hidden unknown bags still keep the total incomplete")
first.bags = recordedBags
for _, invalidBank in ipairs({ { secret = true }, {}, { items = { [100] = { secret = true } } } }) do
    first.bank = invalidBank
    equal(HasLine(Hover({ id = 100 }), "First")[2], "|cff80bfffBags:|r 15", "unreadable or incomplete bank data stays hidden")
end
first.bank = nil
local lineCount = #initial.lines
Hover({ id = 100 }, initial)
equal(#initial.lines, lineCount, "repeated tooltip post-calls add inventory only once")
initial.OnTooltipCleared(initial); initial.lines = {}
Hover({ hyperlink = "|Hitem:6948:0|h[Hearthstone]|h" }, initial)
equal(HasLine(initial, "First")[2], "|cff80bfffBags:|r 1", "tooltip reuse resolves hyperlink IDs and keeps an unvisited bank hidden")
local shopping = Frame(); shopping.GetItem = nil
Hover({ id = 100 }, shopping)
equal(HasLine(shopping, "Inventory") ~= nil, true, "comparison tooltip needs no GetItem method")
equal(#Hover({ id = 9999 }).lines, 0, "unowned items do not add an empty inventory section")
equal(#Hover({ id = { secret = true } }).lines, 0, "restricted tooltip IDs are ignored")
equal(#Hover({ secret = true }).lines, 0, "restricted tooltip records are ignored")
equal(#Hover(123).lines, 0, "malformed tooltip data is ignored")
equal(#Hover({ hyperlink = "spell:100" }).lines, 0, "non-item links do not masquerade as an inventory item")
local colored = Frame()
colored.AddDoubleLine = function(self, left, right, r, g, b, rr, rg, rb)
    self.lines[#self.lines + 1] = { left, right, r, g, b, rr, rg, rb }
end
Hover({ id = 100 }, colored)
equal(HasLine(colored, "First")[3], 0.4, "character row uses native class color")
equal(HasLine(colored, "First")[6], 1, "quantity text uses a white base color")
equal(HasLine(colored, "Inventory")[3], 1, "inventory heading uses gold red component")
equal(HasLine(colored, "Inventory")[4], 0.82, "inventory heading uses gold green component")
local coords = CLASS_ICON_TCOORDS.MAGE
for _, invalid in ipairs({ { secret = true }, { 0, { secret = true }, 0, 1 }, { 0, math.huge, 0, 1 }, { -1, 1, 0, 1 } }) do
    CLASS_ICON_TCOORDS.MAGE = invalid
    equal(HasLine(Hover({ id = 100 }), "First")[1], "First", "unavailable or restricted icon coordinates fall back to a readable name")
end
CLASS_ICON_TCOORDS.MAGE = coords
local classColor = RAID_CLASS_COLORS.MAGE
RAID_CLASS_COLORS.MAGE = { r = { secret = true }, g = 0.8, b = 1 }
colored.OnTooltipCleared(colored); colored.lines = {}; Hover({ id = 100 }, colored)
equal(HasLine(colored, "First")[3], 1, "restricted class color falls back to native gold")
RAID_CLASS_COLORS.MAGE = classColor
local getInfo, upgradeDelta = Suite.Items.GetInfo, Suite.Items.UpgradeDelta
Suite.Items.GetInfo = function() return { equipLoc = "INVTYPE_HEAD", level = 20, classID = 4, subclassID = 1 } end
Suite.Items.UpgradeDelta = function() return 2, { preference = "stats" } end
Suite.db.itemTooltipLevels, Suite.db.upgradeHints = true, true
local gear = Hover({ id = 100 })
equal(gear.lines[1][1], "Item Level 20", "equipment annotations precede inventory footer")
equal(gear.lines[2][1]:find("Possible stat upgrade", 1, true) ~= nil, true, "inventory preserves independent upgrade hints")
local inventoryIndex
for index, line in ipairs(gear.lines) do if line[1] == "Inventory" then inventoryIndex = index end end
equal(inventoryIndex ~= nil and inventoryIndex > 2, true, "inventory footer follows the complete comparison explanation")
Suite.Items.GetInfo, Suite.Items.UpgradeDelta = getInfo, upgradeDelta
Suite.db.itemTooltipLevels, Suite.db.upgradeHints = false, false
local initialized = tips.initialized
tips.initialized = nil
SetCombat(true); tips:Apply()
equal(type(Suite.pending.tooltipInitialize), "function", "first tooltip hooks defer during combat")
local beforeTooltipFrames = frames
Suite.db.itemInventory = false; tips:Apply()
equal(Suite.pending.tooltipInitialize, nil, "disable cancels deferred inventory tooltip hooks")
equal(frames, beforeTooltipFrames, "combat initialization creates no tooltip event frame")
tips.initialized, Suite.db.itemInventory = initialized, true
SetCombat(false)

viewable[0], viewable[2] = true, true
Fire("BANKFRAME_OPENED"); Flush()
equal(first.bank.items[100], 30, "all purchased character bank tabs combine")
equal(Suite.db.inventory.accountBanks[110].items[100], 50, "shared bank is stored once per region")
equal(inventory:Summary(100).total, 95, "bags character bank and account bank sum once")
equal(HasLine(Hover({ id = 100 }), "First")[2], "|cff80bfffBags:|r 15, |cff80bfffBank:|r 30", "visiting the bank reveals its recorded positive count")
equal(HasLine(Hover({ id = 100 }), "Warband")[2], "|cff80bfffBank:|r 50", "shared bank has a separate ZoidsTools-style row")
equal(HasLine(Hover({ id = 100 }), "Inventory")[2], "|cff80bfffTotal:|r 95", "complete sampled character data gets a total")
local recordedAccount = Suite.db.inventory.accountBanks[110]
Suite.db.inventory.accountBanks[110] = nil
equal(inventory:Summary(100).incomplete, true, "unrecorded shared bank keeps the inventory total incomplete")
equal(HasLine(Hover({ id = 100 }), "Inventory")[2], "|cff80bfffKnown total:|r 45", "unknown shared bank is disclosed beside the known inventory count")
equal(HasLine(Hover({ id = 100 }), "Warband"), nil, "unrecorded shared bank has no placeholder row")
Suite.db.inventory.accountBanks[110] = { items = {} }
equal(inventory:Summary(100).incomplete, false, "recorded empty shared bank is distinct from an unknown bank")
equal(HasLine(Hover({ id = 100 }), "Inventory")[2], "|cff80bfffTotal:|r 45", "recorded empty shared bank allows a complete total")
Suite.db.inventory.accountBanks[110] = recordedAccount
local lastBank, lastAccount = first.bank, Suite.db.inventory.accountBanks[110]
Fire("BANKFRAME_CLOSED")
bags[6], bags[7], bags[13] = nil, nil, nil
Flush()
equal(first.bank, lastBank, "closing bank cannot erase its last snapshot")
equal(Suite.db.inventory.accountBanks[110], lastAccount, "closing bank retains the shared snapshot")
for _ = 1, 500 do Fire("BAG_UPDATE_DELAYED") end
equal(TimerCount(), 1, "inventory event bursts share one cancellable timer")
bags[0][2].stackCount = 2; bags[0][3] = nil
Flush()
equal(first.bags.items[100], 5, "consuming and removing stacks replaces rather than accumulates counts")
equal(TimerCount(), 0, "inventory has no idle rescan timer")
SetCombat(true)
local beforeCombatFrames = frames
Fire("BAG_UPDATE_DELAYED"); Flush()
equal(first.bags.items[100], 5, "readable inventory refreshes during combat")
equal(frames, beforeCombatFrames, "combat inventory refresh creates no frames")
SetCombat(false)
local lastBags = first.bags
bags[0].pending = { [3] = 888 }
Fire("BAG_UPDATE_DELAYED"); Flush()
equal(first.bags, lastBags, "occupied slot with loading data preserves complete previous bags")
bags[0].pending = nil
bags[0][3] = Item(888, 4)
Fire("ITEM_DATA_LOAD_RESULT"); Flush()
equal(first.bags.items[888], 4, "later item data refresh completes the snapshot")
for _, invalid in ipairs({ { secret = true }, Item({ secret = true }, 1), Item(100, { secret = true }),
    Item(100, 0), Item(100, 1.5), Item(100, math.huge), Item(0, 1), "invalid" }) do
    lastBags = first.bags; bags[0][1] = invalid
    Fire("BAG_UPDATE_DELAYED"); Flush()
    equal(first.bags, lastBags, "invalid or restricted container data never saves partial counts")
end
bags[0][1] = Item(6948, 1)
local slotFunction = C_Container.GetContainerNumSlots
C_Container.GetContainerNumSlots = function() return { secret = true } end
Fire("BAG_UPDATE_DELAYED"); Flush()
equal(first.bags, lastBags, "restricted slot count retains the complete snapshot")
C_Container.GetContainerNumSlots = slotFunction

bags[6] = { slots = 1, Item(100, 9) }; bags[7] = { slots = 1 }; bags[13] = { slots = 1, Item(100, 50) }
Fire("BANKFRAME_OPENED"); Flush()
lastBank = first.bank
for _, invalidIDs in ipairs({ { 6 }, { 6, 6 }, { 0, 7 }, { { secret = true }, 7 }, { secret = true } }) do
    tabIDs[0] = invalidIDs; Fire("BANK_TABS_CHANGED"); Flush()
    equal(first.bank, lastBank, "incomplete duplicate invalid or restricted bank tab list retains snapshot")
end
tabIDs[0] = { 6, 7 }
bags[7].slots = 0; Fire("BANK_TABS_CHANGED"); Flush()
equal(first.bank, lastBank, "unloaded purchased bank tab cannot erase bank contents")
bags[7].slots = 1
viewable[0] = { secret = true }; Fire("BANK_TABS_CHANGED"); Flush()
equal(first.bank, lastBank, "restricted bank view permission prevents scanning")
viewable[0] = true
bags[6][1] = nil; Fire("PLAYERBANKSLOTS_CHANGED"); Flush()
equal(first.bank.items[100], nil, "confirmed empty bank clears previous item counts")
equal(HasLine(Hover({ id = 100 }), "First")[2], "|cff80bfffBags:|r 5", "confirmed zero bank quantity is omitted from the compact row")
equal(HasLine(Hover({ id = 100 }), "Warband")[1]:find("Spell_Fire_Fire:16:16", 1, true) ~= nil,
    true, "shared bank retains the reference's native fire icon")
Fire("BANKFRAME_CLOSED"); Flush()

identity = { guid = "Player-2-2", name = "First", realm = "RealmB", class = "MAGE", region = 110 }
bags[0] = { slots = 1, Item(100, 2) }; bags[5] = nil
Fire("PLAYER_ENTERING_WORLD"); Flush()
equal(inventory:Summary(100).total, 57, "alt bags add to saved first-character bags and one shared bank")
local altTip = Hover({ id = 100 })
equal(altTip.lines[3], HasLine(altTip, "First-RealmB"), "current character appears first")
equal(HasLine(altTip, "First-RealmA") ~= nil, true, "same character names on different realms remain distinct")
identity.name = "Renamed"; inventory:Refresh()
equal(Suite.db.inventory.characters[identity.guid].name, "Renamed", "stable GUID updates metadata after rename")
equal(HasLine(Hover({ id = 100 }), "First") ~= nil, true, "realm suffix disappears when character names are unique")
equal(HasLine(Hover({ id = 100 }), "Renamed") ~= nil, true, "unique current character also uses a short name")
local snapshot = Suite.Copy(Suite.db.inventory)
Suite.db = Suite.InitializeDB({ itemInventory = true, inventory = snapshot })
equal(inventory:Summary(100).total, 57, "plain saved snapshots survive database initialization")
identity.region = 2; inventory:Refresh()
equal(inventory:Summary(100).total, 2, "other-region characters and shared banks do not enter this region's total")
identity.guid = { secret = true }
local charactersBefore = Suite.db.inventory.characters
Fire("PLAYER_ENTERING_WORLD"); Flush()
equal(Suite.db.inventory.characters, charactersBefore, "restricted identity does not become a saved key")
equal(TimerCount(), 0, "inaccessible identity does not leave a retry loop")
identity.guid = "Player-2-2"
Fire("BAG_UPDATE_DELAYED")
bags[0][1].stackCount = 3
Fire("PLAYER_LOGOUT")
equal(Suite.db.inventory.characters[identity.guid].bags.items[100], 3, "logout flushes pending carried counts before serialization")
equal(TimerCount(), 0, "logout cancels the queued worker")
Fire("BAG_UPDATE_DELAYED")
Suite.db.itemInventory = false; inventory:Apply()
equal(TimerCount(), 0, "disable cancels pending work")
equal(next(inventory.events.registered), nil, "disable removes every feature event")
local callsBefore = calls
Fire("BAG_UPDATE_DELAYED"); Flush()
equal(calls, callsBefore, "disabled retained callbacks do not query inventory")
equal(Suite.db.inventory.characters[identity.guid].bags.items[100], 3, "disable retains saved inventories for reenable")

Suite.db.itemInventory = true
C_Container.GetContainerItemInfo = nil
inventory:Apply()
equal(TimerCount(), 0, "missing container capabilities do not start a retry loop")
Suite.db.itemInventory = false; inventory:Apply()
for key, value in pairs(old) do _G[key] = value end
-- Restore globals that were nil before the test as well.
for _, key in ipairs({ "C_Bank", "UnitName", "GetNormalizedRealmName", "GetRealmName", "GetCurrentRegion",
    "GetServerTime", "NUM_TOTAL_EQUIPPED_BAG_SLOTS", "NUM_BAG_SLOTS", "BankFrame", "RAID_CLASS_COLORS", "CLASS_ICON_TCOORDS" }) do _G[key] = old[key] end
Suite.db, Suite.pending = oldDB, oldPending
inventory.active, inventory.events, inventory.timer, inventory.guid, inventory.bankOpen = nil, nil, nil, nil, nil
SetCombat(false)
