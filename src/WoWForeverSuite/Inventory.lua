local _, Suite = ...
local Inventory = {}
Suite.Inventory = Inventory
table.insert(Suite.modules, Inventory)

local function Integer(value, minimum, maximum)
    return Suite.IsReadable(value) and type(value) == "number" and value >= minimum
        and value <= maximum and value == math.floor(value)
end

local function Text(value)
    return Suite.IsReadable(value) and type(value) == "string" and value ~= ""
end

local function RegionID(value)
    -- Beta region IDs are not limited to the normal live-region range (Forever uses 110).
    return Suite.IsReadable(value) and type(value) == "number" and value > 0
        and value < math.huge and value == math.floor(value)
end

local function Region()
    local region = GetCurrentRegion and GetCurrentRegion()
    if RegionID(region) then return region end
end

local function Timestamp()
    local value = GetServerTime and GetServerTime()
    if Integer(value, 1, 10000000000) then return value end
end

local function BagLimit()
    if Integer(NUM_TOTAL_EQUIPPED_BAG_SLOTS, 0, 5) then return NUM_TOTAL_EQUIPPED_BAG_SLOTS end
    if Integer(NUM_BAG_SLOTS, 0, 5) then return NUM_BAG_SLOTS end
end

function Inventory:Database()
    local db = Suite.db.inventory
    if not Suite.IsReadable(db) or type(db) ~= "table" or not Suite.IsReadable(db.schema) or db.schema ~= 1 then
        db = { schema = 1, characters = {}, accountBanks = {} }
        Suite.db.inventory = db
    end
    if not Suite.IsReadable(db.characters) or type(db.characters) ~= "table" then db.characters = {} end
    if not Suite.IsReadable(db.accountBanks) or type(db.accountBanks) ~= "table" then db.accountBanks = {} end
    return db
end

function Inventory:Character()
    local guid = UnitGUID and UnitGUID("player")
    local name, surname
    if UnitName then name, surname = UnitName("player") end
    local realm = GetNormalizedRealmName and GetNormalizedRealmName()
    if not Text(realm) then realm = GetRealmName and GetRealmName() end
    local region = Region()
    if not Text(guid) or not Text(name) or not Text(realm) or not region then return end
    local db = self:Database()
    local character = db.characters[guid]
    if not Suite.IsReadable(character) or type(character) ~= "table" then character = {}; db.characters[guid] = character end
    local previousName = character.name
    character.name, character.realm, character.region = name, realm, region
    -- Forever's second UnitName return is a surname. Keep the old name field for existing consumers.
    if #name <= 77 and not name:find("[%c|]") then
        if name:find("%s") then character.fullName = name
        elseif Text(surname) and #surname <= 48 and not surname:find("[%c|]") then
            character.fullName = name .. " " .. surname
        elseif not Suite.IsReadable(previousName) or previousName ~= name then
            character.fullName = nil
        end
    end
    local _, class = UnitClass("player")
    character.class = Text(class) and class or nil
    self.guid = guid
    return character, region
end

function Inventory:Enabled()
    return Suite.db and (Suite.db.itemInventory or Suite.db.inventorySearch or Suite.db.characterDashboard)
end

function Inventory:ScanContainers(ids, bank)
    if not C_Container or not C_Container.GetContainerNumSlots or not C_Container.GetContainerItemInfo
        or not C_Container.GetContainerItemID then return end
    local counts, seen = {}, {}
    for _, bag in ipairs(ids) do
        if not Integer(bag, 0, 1000) or seen[bag] then return end
        seen[bag] = true
        local slots = C_Container.GetContainerNumSlots(bag)
        -- A purchased bank tab with zero slots is not ready, even if the tab list is.
        if not Integer(slots, bank and 1 or 0, 1000) then return end
        for slot = 1, slots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if not Suite.IsReadable(info) then return end
            if info == nil then
                local id = C_Container.GetContainerItemID(bag, slot)
                -- Distinguish an empty slot from an occupied slot whose record is loading.
                if not Suite.IsReadable(id) or id ~= nil then return end
            else
                if type(info) ~= "table" or not Integer(info.itemID, 1, 2147483647)
                    or not Integer(info.stackCount, 1, 1000000000) then return end
                local count = (counts[info.itemID] or 0) + info.stackCount
                if count > 1000000000 then return end
                counts[info.itemID] = count
            end
        end
    end
    return { items = counts, at = Timestamp() }
end

function Inventory:ScanBank(bankType)
    if not self.bankOpen or not Integer(bankType, 0, 2) or not C_Bank or not C_Bank.CanViewBank
        or not C_Bank.FetchPurchasedBankTabIDs or not C_Bank.FetchNumPurchasedBankTabs then return end
    local viewable = C_Bank.CanViewBank(bankType)
    if not Suite.IsReadable(viewable) or viewable ~= true then return end
    local ids = C_Bank.FetchPurchasedBankTabIDs(bankType)
    local purchased = C_Bank.FetchNumPurchasedBankTabs(bankType)
    if not Suite.IsReadable(ids) or type(ids) ~= "table" or not Integer(purchased, 0, 100)
        or #ids ~= purchased then return end
    local limit = BagLimit()
    if not limit then return end
    for _, id in ipairs(ids) do if not Integer(id, limit + 1, 1000) then return end end
    return self:ScanContainers(ids, true)
end

function Inventory:Refresh()
    if not self:Enabled() then return end
    local character, region = self:Character()
    if not character then return end
    local limit = BagLimit()
    if limit then
        local ids = {}
        for bag = 0, limit do ids[#ids + 1] = bag end
        local snapshot = self:ScanContainers(ids)
        if snapshot then character.bags = snapshot end
    end
    local types = Enum and Enum.BankType
    if types then
        local bank = self:ScanBank(types.Character)
        if bank then character.bank = bank end
        local account = self:ScanBank(types.Account)
        if account then self:Database().accountBanks[region] = account end
    end
    if Suite.InventorySearch then Suite.InventorySearch:InventoryChanged() end
    if Suite.CharacterDashboard then Suite.CharacterDashboard:RefreshView() end
end

function Inventory:Cancel()
    if self.timer then self.timer:Cancel(); self.timer = nil end
end

function Inventory:Schedule()
    if not self:Enabled() or self.timer or not C_Timer or not C_Timer.NewTimer then return end
    self.timer = C_Timer.NewTimer(0.15, function() self.timer = nil; self:Refresh() end)
end

function Inventory:OnEvent(event)
    if not self:Enabled() then return end
    if event == "BANKFRAME_OPENED" then self.bankOpen = true
    elseif event == "BANKFRAME_CLOSED" then
        -- Never read empty/inaccessible bank containers after leaving the bank.
        self.bankOpen = false
    elseif event == "PLAYER_LOGOUT" then
        self:Cancel(); self:Refresh(); return
    end
    self:Schedule()
end

function Inventory:Apply()
    if not self:Enabled() then
        self:Cancel()
        Suite.pending.inventory = nil
        if self.events then self.events:UnregisterAllEvents() end
        self.active, self.bankOpen = nil, nil
        return
    end
    Suite.AfterCombat("inventory", function()
        if not self:Enabled() or self.active then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event) self:OnEvent(event) end)
        end
        self.active = true
        local shown = BankFrame and BankFrame.IsShown and BankFrame:IsShown()
        self.bankOpen = Suite.IsReadable(shown) and shown == true
        for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED", "BANKFRAME_OPENED",
            "BANKFRAME_CLOSED", "PLAYERBANKSLOTS_CHANGED", "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED",
            "BANK_TABS_CHANGED", "ITEM_DATA_LOAD_RESULT", "PLAYER_LOGOUT" }) do self.events:RegisterEvent(event) end
        self:Refresh()
    end)
end

local function Count(snapshot, id)
    if not Suite.IsReadable(snapshot) or type(snapshot) ~= "table"
        or not Suite.IsReadable(snapshot.items) or type(snapshot.items) ~= "table" then return end
    local value = snapshot.items[id]
    if not Suite.IsReadable(value) then return end
    if value == nil then return 0 end
    if Integer(value, 0, 1000000000) then return value end
end

function Inventory:Summary(id)
    if not Integer(id, 1, 2147483647) then return end
    local region = Region()
    if not region then return end
    local db, rows, total, incomplete = self:Database(), {}, 0, false
    for guid, character in pairs(db.characters) do
        if Text(guid) and type(character) == "table" and Text(character.name) and Text(character.realm)
            and RegionID(character.region) and character.region == region then
            local bags, bank = Count(character.bags, id), Count(character.bank, id)
            if bags == nil or bank == nil then incomplete = true end
            local amount = (bags or 0) + (bank or 0)
            if amount > 0 then
                rows[#rows + 1] = { name = character.name, realm = character.realm, guid = guid, class = character.class,
                    bags = bags, bank = bank, current = guid == self.guid }
                total = total + amount
            end
        end
    end
    table.sort(rows, function(a, b)
        if a.current ~= b.current then return a.current end
        if a.name ~= b.name then return a.name < b.name end
        if a.realm ~= b.realm then return a.realm < b.realm end
        return a.guid < b.guid
    end)
    local account = Count(db.accountBanks[region], id)
    if account == nil then incomplete = true end
    total = total + (account or 0)
    if total == 0 then return end
    return { rows = rows, total = total, account = account, incomplete = incomplete }
end

local function Component(value)
    return Suite.IsReadable(value) and type(value) == "number" and value >= 0 and value <= 1
end

local function CharacterStyle(class)
    local icon, r, g, b = "", 1, 0.82, 0
    if not Text(class) then return icon, r, g, b end
    local color = Suite.IsReadable(RAID_CLASS_COLORS) and type(RAID_CLASS_COLORS) == "table" and RAID_CLASS_COLORS[class]
    if Suite.IsReadable(color) and type(color) == "table"
        and Component(color.r) and Component(color.g) and Component(color.b) then
        r, g, b = color.r, color.g, color.b
    end
    local coords = Suite.IsReadable(CLASS_ICON_TCOORDS) and type(CLASS_ICON_TCOORDS) == "table" and CLASS_ICON_TCOORDS[class]
    if Suite.IsReadable(coords) and type(coords) == "table" and Component(coords[1]) and Component(coords[2])
        and Component(coords[3]) and Component(coords[4]) then
        -- Native class artwork, cropped with Blizzard's shared class coordinates.
        icon = string.format("|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:16:16:0:0:256:256:%d:%d:%d:%d|t ",
            coords[1] * 256, coords[2] * 256, coords[3] * 256, coords[4] * 256)
    end
    return icon, r, g, b
end

local function CountLabel(label, amount)
    return "|cff80bfff" .. label .. ":|r " .. string.format("%d", amount)
end

function Inventory:AddTooltip(tooltip, item, record)
    if not Suite.db.itemInventory or record.inventoryDone then return end
    if not Suite.IsReadable(item) then return end
    local id = item
    if type(item) == "string" then
        id = tonumber(item:match("item:(%d+)"))
        if not id and C_Item and C_Item.GetItemInfoInstant then id = C_Item.GetItemInfoInstant(item) end
    end
    local summary = self:Summary(id)
    if not summary then return end
    record.inventoryDone = true
    tooltip:AddLine(" ")
    tooltip:AddDoubleLine("Inventory", CountLabel(summary.incomplete and "Known total" or "Total", summary.total),
        1, 0.82, 0, 1, 1, 1)
    local names = {}
    for _, row in ipairs(summary.rows) do names[row.name] = (names[row.name] or 0) + 1 end
    for _, row in ipairs(summary.rows) do
        local icon, r, g, b = CharacterStyle(row.class)
        local label = names[row.name] > 1 and row.name .. "-" .. row.realm or row.name
        local counts = {}
        if row.bags and row.bags > 0 then counts[#counts + 1] = CountLabel("Bags", row.bags) end
        if row.bank and row.bank > 0 then counts[#counts + 1] = CountLabel("Bank", row.bank) end
        tooltip:AddDoubleLine(icon .. label, table.concat(counts, ", "), r, g, b, 1, 1, 1)
    end
    if summary.account and summary.account > 0 then
        tooltip:AddDoubleLine("|TInterface\\Icons\\Spell_Fire_Fire:16:16|t Warband", CountLabel("Bank", summary.account),
            1, 0.82, 0, 1, 1, 1)
    end
end
