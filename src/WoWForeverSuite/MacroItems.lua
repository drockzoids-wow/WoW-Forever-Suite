local _, Suite = ...
local Items = { requested = {} }
Suite.MacroItems = Items

local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and value >= 0 and value < math.huge
end
local function Text(value)
    return Suite.IsReadable(value) and type(value) == "string"
end
Items.Number, Items.Text = Number, Text

-- Ordinary stone tiers and weapon subclass IDs are game data, not localized names.
local stones = {
    [2862] = { "sharp", 1 }, [2863] = { "sharp", 2 }, [2871] = { "sharp", 3 },
    [7964] = { "sharp", 4 }, [12404] = { "sharp", 5 },
    [3239] = { "blunt", 1 }, [3240] = { "blunt", 2 }, [3241] = { "blunt", 3 },
    [7965] = { "blunt", 4 }, [12643] = { "blunt", 5 },
}
local families = { [0] = "sharp", [1] = "sharp", [6] = "sharp", [7] = "sharp", [8] = "sharp", [15] = "sharp",
    [4] = "blunt", [5] = "blunt", [10] = "blunt", [13] = "blunt" }
local healthstones = { [5512] = true, [5511] = true, [5509] = true, [5510] = true, [9421] = true,
    [19004] = true, [19005] = true, [19006] = true, [19007] = true, [19008] = true, [19009] = true,
    [19010] = true, [19011] = true, [19012] = true, [19013] = true, [22103] = true, [22104] = true,
    [22105] = true, [224464] = true }

-- Seasonal recovery supplies from client item data. Some use subclass 8 instead
-- of Food & Drink (5); still require a readable restorative tooltip and no buff.
local eventFoods = {
    [20388] = true, [20389] = true, [20390] = true, -- Hallow's End candy
    [19696] = true, [19994] = true, [19995] = true, [19996] = true, [19997] = true, -- Harvest Festival
    [17344] = true, [17404] = true, [17406] = true, [17407] = true, [17408] = true, -- Winter Veil
    [21215] = true, [21235] = true, [21241] = true,
    [21537] = true, -- Lunar Festival dumplings
}

local function Read(callback, ...)
    if type(callback) ~= "function" then return nil end
    local ok, value = pcall(callback, ...)
    if ok and Suite.IsReadable(value) then return value end
end

function Items:Request(id)
    if self.requested[id] or not C_Item or type(C_Item.RequestLoadItemDataByID) ~= "function" then return end
    self.requested[id] = true
    pcall(C_Item.RequestLoadItemDataByID, id)
end

local function Tooltip(id, bag, slot)
    local api = C_TooltipInfo or {}
    local data = bag ~= nil and Read(api.GetBagItem, bag, slot) or Read(api.GetItemByID, id)
    if type(data) ~= "table" or not Suite.IsReadable(data.lines) or type(data.lines) ~= "table" then return nil end
    local words = {}
    for _, line in ipairs(data.lines) do
        if not Suite.IsReadable(line) or type(line) ~= "table" then return nil end
        for _, field in ipairs({ "leftText", "rightText" }) do
            local value = line[field]
            if not Suite.IsReadable(value) then return nil end
            if Text(value) then words[#words + 1] = value end
        end
    end
    if #words == 0 then return nil end
    return table.concat(words, " "):lower()
end

local function Restoration(description, resource)
    local result = 0
    local function Value(value) return tonumber((value:gsub(",", ""))) or 0 end
    for low, high in description:gmatch("restores?%s+([%d,]+)%s+to%s+([%d,]+)%s+" .. resource) do
        result = math.max(result, (Value(low) + Value(high)) / 2)
    end
    for amount in description:gmatch("restores?%s+([%d,]+)%s+" .. resource) do result = math.max(result, Value(amount)) end
    for amount in description:gmatch("and%s+([%d,]+)%s+" .. resource) do result = math.max(result, Value(amount)) end
    -- Percentage items are classified, but never converted using restricted player health/power.
    return result
end

function Items:Read(id, bag, slot, level, english)
    if not Number(id) or id < 1 or id > 10000000 or id % 1 ~= 0 then return nil, true end
    if not C_Item or type(C_Item.GetItemInfo) ~= "function" then return nil, true end
    local ok, name, _, quality, itemLevel, required, _, _, _, _, _, _, class, subclass = pcall(C_Item.GetItemInfo, id)
    if not ok or not Text(name) or not Number(required) or not Number(class) or not Number(subclass) then
        self:Request(id)
        return nil, true, class, subclass
    end
    if not Number(level) then return nil, true, class, subclass end
    if required > level or class == 9 then return nil end
    if type(C_Item.GetItemSpell) ~= "function" then return nil, true, class, subclass end
    local spellOK, spell = pcall(C_Item.GetItemSpell, id)
    if not spellOK or not Suite.IsReadable(spell) then return nil, true, class, subclass end
    if not Text(spell) or spell == "" then return nil end
    local item = { id = id, name = name, class = class, subclass = subclass, quality = Number(quality) and quality or 0,
        level = Number(itemLevel) and itemLevel or required, eventFood = eventFoods[id] == true,
        flags = {}, health = 0, mana = 0 }
    if stones[id] then item.family, item.tier = unpack(stones[id]) end
    if healthstones[id] then item.flags.healthstone = true end
    if class == 0 and subclass == 7 then item.flags.bandage = true end
    local description = Tooltip(id, bag, slot)
    if english and description then
        local lower = name:lower()
        item.conjured = lower:find("conjured", 1, true) ~= nil
        item.health, item.mana = Restoration(description, "health"), Restoration(description, "mana")
        local restoresHealth = item.health > 0 or description:find("%% of your health") ~= nil
        local restoresMana = item.mana > 0 or description:find("%% of your mana") ~= nil
            or description:find("%% of your health and mana") ~= nil
        if class == 0 and (subclass == 5 or item.eventFood) then
            local buff = description:find("well fed", 1, true) or description:find("increases", 1, true)
                or description:find("gain .- for ")
            if not buff then item.flags.food, item.flags.water = restoresHealth, restoresMana end
        elseif class == 0 and subclass == 1 then
            local special = lower:find("sleep", 1, true) or lower:find("wildvine", 1, true)
                or description:find("asleep", 1, true)
            if not special then item.flags.healing, item.flags.mana = restoresHealth, restoresMana end
        end
    elseif english and class == 0 and (subclass == 5 or subclass == 1 or item.eventFood) then
        return item, true, class, subclass -- Keep actions that depend on this incomplete tooltip.
    end
    return item
end

local function Better(candidate, current, kind)
    if not current then return true end
    if kind == "food" or kind == "water" then
        if candidate.conjured ~= current.conjured then return candidate.conjured == true end
        if candidate.eventFood ~= current.eventFood then return candidate.eventFood == true end
    end
    local resource = (kind == "water" or kind == "mana") and "mana" or "health"
    if candidate[resource] ~= current[resource] then return candidate[resource] > current[resource] end
    if candidate.level ~= current.level then return candidate.level > current.level end
    if candidate.quality ~= current.quality then return candidate.quality > current.quality end
    return candidate.id > current.id
end

local function Pending(snapshot, id, class, subclass)
    snapshot.pendingByID[id] = true
    -- A readable ID identifies ordinary stones/Healthstones without guessing from names.
    if stones[id] then snapshot.pending[stones[id][1]] = true end
    if healthstones[id] then snapshot.pending.healthstone = true end
    if not Suite.IsReadable(class) or not Suite.IsReadable(subclass) then
        snapshot.incomplete = true
        return
    end
    if (not Number(class) or not Number(subclass)) and C_Item and type(C_Item.GetItemInfoInstant) == "function" then
        local ok, _, _, _, _, _, instantClass, instantSubclass = pcall(C_Item.GetItemInfoInstant, id)
        if not ok or not Suite.IsReadable(instantClass) or not Suite.IsReadable(instantSubclass) then
            snapshot.incomplete = true
            return
        end
        class, subclass = instantClass, instantSubclass
    end
    -- Missing full metadata for gear/reagents must not freeze unrelated recipes.
    -- Unknown classes still pause recovery choices that could depend on this item.
    if not Number(class) or class == 0 then
        if not Number(class) or not Number(subclass) or subclass == 5 or eventFoods[id] then
            snapshot.pending.food, snapshot.pending.water = true, true
        end
        if not Number(class) or not Number(subclass) or subclass == 1 then
            snapshot.pending.healing, snapshot.pending.mana = true, true
        end
        if not Number(class) or not Number(subclass) or subclass == 7 then snapshot.pending.bandage = true end
    end
end

function Items:Scan()
    local snapshot = { list = {}, byID = {}, best = {}, pending = {}, pendingByID = {}, incomplete = false,
        carried = {}, carriedByID = {}, carriedIncomplete = false }
    if InCombatLockdown() then snapshot.incomplete = true; return snapshot end
    local level = Read(UnitLevel, "player")
    local locale = Read(GetLocale)
    snapshot.english = locale == "enUS" or locale == "enGB"
    local api = C_Container or {}
    local maximum = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS
    if not Number(maximum) then maximum = 4 end
    for bag = 0, math.min(5, maximum) do
        local slots = Read(api.GetContainerNumSlots, bag)
        if not Number(slots) then snapshot.incomplete = true; slots = 0 end
        for slot = 1, math.min(200, slots) do
            local ok, info = false, nil
            if type(api.GetContainerItemInfo) == "function" then ok, info = pcall(api.GetContainerItemInfo, bag, slot) end
            if not ok or not Suite.IsReadable(info) then snapshot.incomplete = true
            elseif info == nil then
                local read, id = false, nil
                if type(api.GetContainerItemID) == "function" then read, id = pcall(api.GetContainerItemID, bag, slot) end
                -- Missing item information is not proof that an occupied slot is empty.
                if not read or not Suite.IsReadable(id) or id ~= nil then
                    snapshot.incomplete = true
                    if read and Number(id) and id > 0 then self:Request(id) end
                end
            else
                if type(info) ~= "table" or not Number(info.itemID) or not Number(info.stackCount) then snapshot.incomplete = true
                elseif info.stackCount > 0 then
                    -- Feeding may use ingredients without their own use spell. This explicit
                    -- picker lists carried items; the player chooses food for their pet's diet.
                    local choice = snapshot.carriedByID[info.itemID]
                    if choice then choice.count = choice.count + info.stackCount
                    else
                        local name = C_Item and Read(C_Item.GetItemInfo, info.itemID)
                        if Text(name) and #name > 0 and #name <= 128 and not name:find("[%c|]") then
                            choice = { id = info.itemID, name = name, count = info.stackCount }
                            snapshot.carriedByID[info.itemID] = choice
                            snapshot.carried[#snapshot.carried + 1] = choice
                        else snapshot.carriedIncomplete = true; self:Request(info.itemID) end
                    end
                    local item = snapshot.byID[info.itemID]
                    if item then item.count = item.count + info.stackCount
                    else
                        local pending, class, subclass
                        item, pending, class, subclass = self:Read(info.itemID, bag, slot, level, snapshot.english)
                        if pending then Pending(snapshot, info.itemID, class, subclass) end
                        if item then
                            item.count = info.stackCount
                            snapshot.list[#snapshot.list + 1], snapshot.byID[item.id] = item, item
                            for kind, usable in pairs(item.flags) do
                                if usable and Better(item, snapshot.best[kind], kind) then snapshot.best[kind] = item end
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(snapshot.list, function(a, b) return a.name:lower() < b.name:lower() end)
    table.sort(snapshot.carried, function(a, b) return a.name:lower() < b.name:lower() end)
    return snapshot
end

function Items:WeaponStone(snapshot, slot)
    if type(GetInventoryItemID) ~= "function" or not C_Item or type(C_Item.GetItemInfoInstant) ~= "function" then
        return nil, "Weapon data is unavailable.", true
    end
    local ok, id = pcall(GetInventoryItemID, "player", slot)
    if not ok or not Suite.IsReadable(id) then return nil, "Weapon data is unavailable.", true end
    if id == nil then return nil, "No weapon equipped in this hand." end
    if not Number(id) or id < 1 then return nil, "Weapon data is unavailable.", true end
    local read, _, _, _, _, _, class, subclass = pcall(C_Item.GetItemInfoInstant, id)
    if not read or not Number(class) or not Number(subclass) then return nil, "Weapon data is loading.", true end
    local family = class == 2 and families[subclass]
    if not family then return nil, "This hand has no weapon that takes an ordinary stone." end
    if snapshot.pending and snapshot.pending[family] then return nil, "Matching stone data is loading. Existing text is kept.", true end
    local chosen
    for _, item in ipairs(snapshot.list) do
        if item.family == family and (not chosen or item.tier > chosen.tier) then chosen = item end
    end
    return chosen, chosen and (chosen.name .. " matches this weapon.")
        or (family == "sharp" and "Carry a sharpening stone, or choose an oil or poison." or "Carry a weightstone, or choose an oil or poison.")
end

function Items:PetCanEat(id)
    if InCombatLockdown() then return nil, "Choose pet food after combat." end
    if not Number(id) or id < 1 or id > 10000000 or id % 1 ~= 0 then return nil, "Food item information is unavailable." end
    local exists = Read(UnitExists, "pet")
    if exists == false then return nil, "Call your pet to choose food it can eat." end
    if exists ~= true then return nil, "Active pet information is unavailable." end
    if not C_PetInfo or type(C_PetInfo.CanPetEatItem) ~= "function" then
        return nil, "Pet food filtering is unavailable in this client."
    end
    local result = Read(C_PetInfo.CanPetEatItem, id)
    if result == true or result == false then return result end
    return nil, "Pet food information is loading or unavailable."
end

function Items:PetFoodChoices(snapshot)
    local choices, note = {}, nil
    if InCombatLockdown() then return choices, "Choose pet food after combat." end
    -- Establish availability even with empty bags, without passing a dummy item
    -- to the native predicate. Neither unknown identity nor missing APIs permits
    -- an unfiltered fallback.
    local exists = Read(UnitExists, "pet")
    if exists == false then return choices, "Call your pet to choose food it can eat." end
    if exists ~= true then return choices, "Active pet information is unavailable." end
    if not C_PetInfo or type(C_PetInfo.CanPetEatItem) ~= "function" then
        return choices, "Pet food filtering is unavailable in this client."
    end
    for _, item in ipairs(snapshot.carried or {}) do
        local accepted, problem = self:PetCanEat(item.id)
        if accepted == true then choices[#choices + 1] = item
        elseif accepted == nil then note = problem end
    end
    if snapshot.incomplete or snapshot.carriedIncomplete then note = "Some carried item data is loading or unavailable." end
    return choices, note or (#choices == 0 and "No carried food matches your active pet." or nil)
end

function Items:Choices(snapshot, recipe)
    if recipe == "hunterPet" then return self:PetFoodChoices(snapshot) end
    local choices = {}
    for _, item in ipairs(snapshot.list) do
        local recovery = recipe == "food" or recipe == "water"
        local weapon = recipe == "mainhand" or recipe == "offhand"
        local lower = item.name:lower()
        if recipe == "item" or recovery and item.class == 0 and (item.subclass == 5 or item.eventFood)
            or recipe == "bandage" and item.flags.bandage
            or weapon and (item.family or item.class == 0 and item.subclass == 6
                or lower:find("poison", 1, true) or lower:find("oil", 1, true)) then
            choices[#choices + 1] = item
        end
    end
    return choices
end
