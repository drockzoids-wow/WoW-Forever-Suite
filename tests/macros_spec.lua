local Suite, equal, Frame, SetCombat = ...
local macros, supplies = Suite.Macros, Suite.MacroItems
SetCombat(false)
local data = {
    [100] = { name = "Vendor Bread", sub = 5, description = "Restores 2600 health over 30 seconds." },
    [101] = { name = "Conjured Bread", sub = 5, description = "Restores 600 health over 24 seconds." },
    [102] = { name = "Buff Steak", sub = 5, description = "Restores 4000 health. You become well fed." },
    [103] = { name = "Conjured Water", sub = 5, description = "Restores 800 mana over 24 seconds." },
    [104] = { name = "Milk", sub = 5, description = "Restores 2400 mana over 24 seconds." },
    [105] = { name = "Healing Potion", sub = 1, description = "Restores 70 to 90 health." },
    [106] = { name = "Mana Potion", sub = 1, description = "Restores 400 mana." },
    [107] = { name = "Bandage", sub = 7, description = "Heals 200 damage over 8 seconds." },
    [108] = { name = "Shadow Oil", sub = 6, description = "Coats your weapon." },
    [109] = { name = "Recipe", class = 9, description = "Teaches a recipe." },
    [110] = { name = "Future Potion", sub = 1, required = 60, description = "Restores 9000 health." },
    [111] = { name = "Thistle Tea", sub = 5, description = "Restores 100 energy." },
    [112] = { name = "Dreamless Sleep Potion", sub = 1, description = "Restores 900 health and 900 mana while asleep." },
    [113] = { name = "Crafting Oil", noUse = true },
    [114] = { name = "Percent Food", sub = 5, description = "Restores 20% of your health over 20 seconds." },
    [115] = { name = "Uncached Reagent", class = 7, noUse = true },
    [116] = { name = "Stronger Bandage", sub = 7, required = 20, description = "Heals 400 damage over 8 seconds." },
    [4544] = { name = "Mulgore Spice Bread", sub = 5, required = 25,
        description = "Use: Restores 841 health over 27 sec.\nMust remain seated while eating." },
    [4593] = { name = "Bristle Whisker Catfish", sub = 5, required = 15,
        description = "Use: Restores 530 health over 24 sec.\nMust remain seated while eating. If you spend at least 10 sec eating, you will become well fed and gain 8 Fishing Skill for 15 min. Additionally, experience gained from kills is increased by 5%. (1 Sec Cooldown)" },
    [4603] = { name = "Raw Spotted Yellowtail", class = 7, sub = 8, required = 35,
        description = "Use: Restores 841 health over 27 sec.\nMust remain seated while eating.\nCrafting Reagent" },
    [6290] = { name = "Brilliant Smallfish", sub = 5,
        description = "Use: Restores 58 health over 18 sec. Must remain seated while eating. If you spend at least 10 sec eating, you will become well fed and gain 2 Attack Power for 15 min. Additionally, experience gained from kills is increased by 5%. (1 Sec Cooldown)" },
    [20388] = { name = "Lollipop", sub = 8, description = "Restores 3% of your health and mana per second for 25 sec. Must remain seated while eating." },
    [20389] = { name = "Candy Corn", sub = 8, description = "Restores 3% of your health and mana per second for 25 sec. Must remain seated while eating." },
    [20390] = { name = "Candy Bar", sub = 8, description = "Restores 3% of your health and mana per second for 25 sec. Must remain seated while eating." },
    [17344] = { name = "Candy Cane", sub = 5, description = "Restores 61 health over 18 sec." },
    [19997] = { name = "Harvest Nectar", sub = 8, description = "Restores 2% of your mana per second for 30 sec." },
    [21537] = { name = "Festival Dumplings", sub = 8, description = "Restores 4% of your health and mana per second for 25 sec." },
    [7807] = { name = "Candy Bar", sub = 5, description = "Restores 61 health over 18 sec." },
    [20516] = { name = "Bobbing Apple", sub = 5, description = "Restores 2% of your health per second for 24 sec. You become well fed and gain Stamina and Spirit." },
    [20557] = { name = "Hallow's End Pumpkin Treat", sub = 8, description = "Enjoy a tasty Hallow's End treat! Better eat it quick before they go bad..." },
    [5512] = { name = "Healthstone", description = "Restores 100 health." },
    [2862] = { name = "Rough Sharpening Stone", sub = 6 },
    [12404] = { name = "Dense Sharpening Stone", sub = 6, required = 50 },
    [3239] = { name = "Rough Weightstone", sub = 6 },
    [12643] = { name = "Dense Weightstone", sub = 6, required = 50 },
}
local bags = { 100, 101, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 5512, 2862, 12404, 3239, 12643 }
local locale, level = "enUS", 30
local unavailable, restrictedTooltip, restrictedBag, restrictedWeapon, loadingBag
local requests = {}
local weapon = { [16] = 201, [17] = 202 }
local classes = { [201] = 7, [202] = 4, [203] = 6, [204] = 10, [205] = 13, [206] = 14 }
UnitLevel = function() return level end
GetLocale = function() return locale end
UnitHealthMax = function() error("Macro selection must not read player health") end
UnitPowerMax = function() error("Macro selection must not read player power") end
C_Item = {
    GetItemInfo = function(id)
        if id == unavailable then return nil end
        local item = data[id]; if not item then return nil end
        return item.name, "item:" .. id, 1, item.required or 10, item.required or 0, "Consumable", "",
            20, "", 134400, 0, item.class or 0, item.sub or 0
    end,
    GetItemSpell = function(id) return data[id] and not data[id].noUse and "Use" or nil end,
    RequestLoadItemDataByID = function(id) requests[id] = (requests[id] or 0) + 1 end,
    GetItemInfoInstant = function(id)
        local item = data[id]
        if item then return id, "", "", "", 1, item.class or 0, item.sub or 0 end
        if classes[id] then return id, "Weapon", "", "", 1, id == 206 and 4 or 2, classes[id] end
    end,
}
C_Container = {
    GetContainerNumSlots = function(bag) return bag == 0 and #bags or 0 end,
    GetContainerItemInfo = function(bag, slot)
        if loadingBag then return nil end
        if restrictedBag then return { itemID = { secret = true }, stackCount = 1 } end
        if bag == 0 and bags[slot] then return { itemID = bags[slot], stackCount = 2 } end
    end,
    GetContainerItemID = function(bag, slot) if bag == 0 then return bags[slot] end end,
}
C_TooltipInfo = {
    GetItemByID = function(id)
        if id == restrictedTooltip then return { lines = { { leftText = { secret = true } } } } end
        return data[id] and { lines = { { leftText = data[id].description or "Applies an effect." } } }
    end,
}
C_TooltipInfo.GetBagItem = function(_, slot) return C_TooltipInfo.GetItemByID(bags[slot]) end
GetInventoryItemID = function(_, slot) return restrictedWeapon and { secret = true } or weapon[slot] end

Suite.db = Suite.InitializeDB(nil)
local char = macros:Initialize(nil)
local food, water, bandage, mainhand, offhand = unpack(char.entries)
equal(Suite.db.macroUpdates, false, "macro updates default off")
equal(food.created, false, "starter recipes create nothing")
equal(food.combat, false, "combat supplies require an explicit choice")
local snapshot = supplies:Scan()
do
    local items={
        {id=91001,name="Heavy Armor Kit",class=0,subclass=6,flags={}},
        {id=91002,name="Unrecognized Enhancement",class=0,subclass=6,flags={}},
        {id=91003,name="Crafting Oil",class=7,subclass=0,flags={}},
        {id=91004,name="Shadow Oil",class=0,subclass=6,flags={}},
        {id=91005,name="Instant Poison IV",class=0,subclass=6,flags={}},
        {id=91006,name="Weapon Treatment",class=0,subclass=6,flags={weaponCoating=true}},
    }
    for _,recipe in ipairs({"mainhand","offhand"}) do
        local choices=supplies:Choices({list=items},recipe)
        equal(#choices,3,"weapon choices require a recognized coating rather than the enhancement category")
        equal(choices[1].id,91004,"weapon oils remain available")
        equal(choices[2].id,91005,"ranked poisons remain available")
        equal(choices[3].id,91006,"readable weapon-use tooltip permits an additional coating")
    end
    equal(#supplies:Choices({list=items},"item"),6,"generic item recipes still allow armor kits")
end
equal(snapshot.best.food.id, 101, "prefer conjured food to higher restoration vendor food")
equal(snapshot.best.water.id, 103, "prefer conjured drink")
equal(snapshot.byID[101].count, 4, "combine identical carried stacks")
equal(snapshot.best.healing.id, 105, "sleep potions are excluded from automatic healing")
equal(snapshot.best.mana.id, 106, "sleep potions are excluded from automatic mana")
equal(snapshot.byID[102].flags.food, true, "health-restoring buff food is eligible for automatic food selection")
equal(snapshot.byID[111].flags.water, false, "energy supplies are excluded from drinking")
equal(snapshot.byID[109], nil, "recipes cannot be picked as consumables")
equal(snapshot.byID[110], nil, "exclude supplies above player level")
equal(snapshot.byID[113], nil, "exclude crafting items with no use action")
equal(snapshot.best.food.health, 600, "restoration is read from item text")
equal(snapshot.best.healing.health, 80, "range restoration uses its midpoint")
local body = macros:Generate(food, snapshot)
equal(body, "#showtooltip [nocombat] item:101\n/use [nocombat] item:101", "food stays outside combat by default")
assert(loadfile("tests/food_audit_spec.lua"))(Suite, equal, data, food, water, function(items, playerLevel)
    local oldBags, oldLevel = bags, level
    bags, level = items, playerLevel
    return oldBags, oldLevel
end)
do
    local savedBags, savedLevel = bags, level
    local fish = data[4603]
    local description = fish.description
    bags, level = { 4603 }, 39
    local raw = supplies:Scan()
    equal(raw.best.food and raw.best.food.id, 4603, "live class-7 subclass-8 Yellowtail is restorative food")
    equal(raw.best.food.health, 841, "live Yellowtail restoration matches the tooltip")
    equal(#supplies:Choices(raw, "food"), 1, "edible cooking reagent appears in food choices")
    equal(#supplies:Choices(raw, "water"), 0, "edible cooking reagent does not broaden drink choices")
    fish.description = "Restores 841 health over 27 sec."
    equal(supplies:Scan().best.food, nil, "restoration alone does not turn a cooking reagent into eating food")
    fish.description = "Must remain seated while eating."
    equal(supplies:Scan().best.food, nil, "eating instruction without health restoration is insufficient")
    fish.description, fish.noUse = description, true
    equal(supplies:Scan().best.food, nil, "cooking ingredients without a use spell remain excluded")
    fish.noUse, restrictedTooltip = nil, 4603
    raw = supplies:Scan()
    equal(raw.pending.food, true, "unreadable cooking food tooltip pauses automatic food decisions")
    equal(macros:Generate(food, raw), nil, "unreadable raw food cannot clear the current macro")
    restrictedTooltip, unavailable = nil, 4603
    equal(supplies:Scan().pending.food, true, "uncached cooking food metadata pauses food decisions")
    unavailable = nil
    fish.class, fish.sub = 7, 0
    equal(supplies:Scan().best.food.id, 4603, "reviewed edible fish remains eligible if the client changes its trade-goods subclass")
    fish.class, fish.sub = 7, 8
    bags, level = savedBags, savedLevel
end

do
    local savedBags, description = bags, data[4593].description
    data[4606] = { name = "Spongy Morel", sub = 5, required = 15,
        description = "Use: Restores 530 health over 24 sec. Must remain seated while eating." }
    bags = { 4606, 100, 102, 101, 20390, 4593, 6290 }
    local experience = supplies:Scan()
    equal(experience.best.food.id, 4593, "XP Catfish outranks ordinary, non-XP buff, mage and event food")
    equal(experience.byID[4593].experienceBonus, 5, "read the Catfish's kill-experience percentage")
    equal(experience.byID[4606].experienceBonus, 0, "screenshot Morel grants no experience bonus")
    equal(experience.byID[102].experienceBonus, 0, "Well Fed alone is not evidence of an XP bonus")
    equal(macros:Generate(food, experience, 4606), "#showtooltip [nocombat] item:4593\n/use [nocombat] item:4593",
        "new XP food replaces a still-carried automatic ordinary choice")
    food.item = 4606
    equal(macros:Generate(food, experience, 101), "#showtooltip [nocombat] item:4606\n/use [nocombat] item:4606",
        "an explicit ordinary food choice still overrides XP priority")
    food.item = nil
    equal(macros:Generate(food, experience, 6290), "#showtooltip [nocombat] item:6290\n/use [nocombat] item:6290",
        "an automatic XP choice stays carried when its bonus matches the best")
    data[4593].description = description:gsub("5%%", "10%%")
    experience = supplies:Scan()
    equal(experience.best.food.id, 4593, "larger disclosed XP bonuses rank first")
    equal(macros:Generate(food, experience, 6290):find("item:4593", 1, true) ~= nil, true,
        "a larger XP bonus promotes over a still-carried lower bonus")
    for _, text in ipairs({ description:gsub("5%%", "|cffffffff5|r%%"),
        description:gsub("experience gained", "experience|ngained"),
        (description:gsub("kills is increased", "kills increased")) }) do
        data[4593].description = text
        equal(supplies:Scan().best.food.id, 4593, "XP detection tolerates color markup, wrapping and buff wording")
    end
    data[4593].description = description:gsub("5%%", "0%%")
    equal(supplies:Scan().best.food.id, 6290, "zero bonus is not preferred XP food")
    data[4593].description, restrictedTooltip = description, 4593
    experience = supplies:Scan()
    equal(macros:Generate(food, experience, 4606), nil, "unreadable candidate tooltip preserves current automatic food")
    restrictedTooltip, unavailable = nil, 4593
    equal(macros:Generate(food, supplies:Scan(), 4606), nil, "loading candidate metadata preserves current automatic food")
    unavailable = nil
    local required = data[4593].required
    data[4593].required, bags = 60, { 4593, 4606 }
    equal(supplies:Scan().best.food.id, 4606, "above-level XP food cannot displace usable ordinary food")
    data[4593].required, bags = required, { 4593 }
    data[4593].description = "Additionally, experience gained from kills is increased by 5%."
    equal(supplies:Scan().best.food, nil, "XP text without health restoration cannot create recovery food")
    data[4593].description, bags = description, savedBags
end
do
    local savedBags, description = bags, data[6290].description
    bags = { 6290 }
    for _, text in ipairs({ description,
        description:gsub("58", "|cffffffff58|r"),
        description:gsub("58", "|cnNORMAL_FONT_COLOR:58|r"),
        description:gsub("58 health", "58|nhealth"),
        (description:gsub("58 health", "58\nhealth")) }) do
        data[6290].description = text
        local fish = supplies:Scan()
        equal(fish.best.food and fish.best.food.id, 6290, "Smallfish buff-food tooltip is recognized with inline colors and wrapping")
        equal(fish.byID[6290].health, 58, "visible Smallfish restoration is parsed without markup")
        equal(macros:Generate(food, fish), "#showtooltip [nocombat] item:6290\n/use [nocombat] item:6290",
            "Smallfish alone produces an automatic food macro")
    end
    bags, data[6290].description = savedBags, description
end
do
    local savedBags = bags
    bags = { 100, 102 }
    local buffFood = supplies:Scan()
    equal(buffFood.best.food.id, 102, "stronger buff food outranks ordinary food in the same tier")
    equal(macros:Generate(food, buffFood), "#showtooltip [nocombat] item:102\n/use [nocombat] item:102",
        "automatic food macro uses carried buff food outside combat")
    food.item = 102
    equal(macros:Generate(food, snapshot):find("item:102", 1, true) ~= nil, true,
        "explicit buff food overrides automatic mage priority")
    food.item = nil
    bags = { 20516 }
    equal(supplies:Scan().best.food.id, 20516, "percentage-restoring buff food works as the only food")
    local description = data[102].description
    data[102].description = "Increases your Stamina for 15 minutes."
    equal(supplies:Read(102, nil, nil, level, true).flags.food, false,
        "a buff without health restoration is not automatic recovery food")
    data[102].description, bags = description, savedBags
end
do
    local savedBags = bags
    for _, id in ipairs({ 20388, 20389, 20390 }) do
        bags = { 100, 104, id }
        local seasonal = supplies:Scan()
        equal(seasonal.best.food.id, id, "Hallow's End candy outranks stronger ordinary food")
        equal(seasonal.best.water.id, id, "combined percentage candy also outranks ordinary water")
        equal(macros:Generate(food, seasonal), "#showtooltip [nocombat] item:" .. id .. "\n/use [nocombat] item:" .. id,
            "the food macro uses the candy's item ID despite its non-food subclass")
        equal(macros:Generate(water, seasonal), "#showtooltip [nocombat] item:" .. id .. "\n/use [nocombat] item:" .. id,
            "the drink macro uses the same health-and-mana candy")
        local choices, found = supplies:Choices(seasonal, "water"), false
        for _, choice in ipairs(choices) do if choice.id == id then found = true end end
        equal(found, true, "holiday candy remains available as an explicit food/drink choice")
        bags = { id, 101, 103, 100, 104 }
        seasonal = supplies:Scan()
        equal(seasonal.best.food.id, 101, "mage food retains priority over event candy")
        equal(seasonal.best.water.id, 103, "mage water retains priority over event candy")
    end
    bags = { 100, 104, 17344, 19997 }
    local seasonal = supplies:Scan()
    equal(seasonal.best.food.id, 17344, "Winter Veil recovery outranks ordinary food")
    equal(seasonal.best.water.id, 19997, "Harvest Festival recovery outranks ordinary water")
    equal(seasonal.byID[17344].flags.water, false, "health-only event food is never selected as water")
    equal(seasonal.byID[19997].flags.food, false, "mana-only event drink is never selected as food")
    bags = { 100, 104, 21537 }
    seasonal = supplies:Scan()
    equal(seasonal.best.food.id, 21537, "Lunar Festival dumplings receive event-food priority")
    equal(seasonal.best.water.id, 21537, "Lunar Festival dumplings restore both resources")
    bags = { 100, 104, 7807, 20516, 20557 }
    seasonal = supplies:Scan()
    equal(seasonal.best.food.id, 100, "ordinary candy names and percentage buff food retain existing restoration ranking")
    equal(seasonal.best.water.id, 104, "non-restoring event treats cannot displace water")
    local candyDescription = data[20390].description
    data[20390].description = candyDescription .. " You become well fed."
    bags = { 100, 104, 20390 }; seasonal = supplies:Scan()
    equal(seasonal.best.food.id, 20390, "seasonal health-restoring buff food retains event priority")
    equal(seasonal.best.water.id, 20390, "a restorative event drink remains eligible with a Well Fed buff")
    data[20390].description = candyDescription
    bags, unavailable = { 100, 104, 20390 }, 20390
    seasonal = supplies:Scan()
    equal(seasonal.pending.food, true, "uncached event candy pauses food selection despite subclass 8")
    equal(seasonal.pending.water, true, "uncached event candy pauses water selection despite subclass 8")
    equal(macros:Generate(food, seasonal), nil, "loading event metadata cannot silently replace an existing action")
    unavailable, restrictedTooltip = nil, 20390
    seasonal = supplies:Scan()
    equal(seasonal.pending.food, true, "restricted event tooltip preserves food selection")
    equal(seasonal.pending.water, true, "restricted event tooltip preserves drink selection")
    restrictedTooltip, locale = nil, "deDE"
    seasonal = supplies:Scan()
    equal(macros:Generate(food, seasonal), nil, "a known holiday ID does not bypass the English tooltip requirement")
    food.item = 20390
    equal(macros:Generate(food, seasonal), "#showtooltip [nocombat] item:20390\n/use [nocombat] item:20390",
        "explicit event candy works for other locales")
    food.item, locale, bags = nil, "enUS", savedBags
end
food.combat, water.combat = true, true
body = macros:Generate(food, snapshot)
equal(body:find("/use [combat] item:5512", 1, true) ~= nil, true, "health recipe includes the carried Healthstone")
equal(body:find("/use [combat] item:105", 1, true) ~= nil, true, "health recipe also attempts the carried potion")
equal(#body <= 255, true, "combined recovery fits the native text limit")
local function Actions(text, inCombat)
    local actions = {}
    for condition, id in text:gmatch("/use %[(%a+)%] item:(%d+)") do
        if (condition == "combat") == inCombat then actions[#actions + 1] = id end
    end
    return table.concat(actions, ",")
end
equal(Actions(body, false), "101", "out-of-combat health recipe only eats")
equal(Actions(body, true), "5512,105", "combat health recipe attempts both supplies in order")
equal(Actions(macros:Generate(water, snapshot), true), "106", "combat mana recipe drinks no water")
do
    -- Synthetic ID: the screenshot establishes the tooltip, not the native item ID.
    local savedBags, savedLevel = bags, level
    local tonic = { name = "Tessa's Tonic", sub = 1, required = 35,
        description = "Use: Restores 720 to 880 mana and health." }
    data[117], bags, level = tonic, { 105, 106, 117 }, 39
    local recovery = supplies:Scan()
    equal(recovery.byID[117].health, 800, "Tessa's shared range supplies its health midpoint")
    equal(recovery.byID[117].mana, 800, "Tessa's shared range supplies its mana midpoint")
    equal(recovery.best.healing.id, 117, "Tessa's Tonic outranks weaker healing potions")
    equal(recovery.best.mana.id, 117, "Tessa's Tonic outranks weaker mana potions")
    equal(Actions(macros:Generate(food, recovery), true), "117", "health macro includes the shared-resource tonic")
    equal(Actions(macros:Generate(water, recovery), true), "117", "mana macro includes the shared-resource tonic")
    for _, description in ipairs({
        "Use: Restores 720 to 880 health and mana.",
        "Use: Restores 800 mana and health.",
        "Use: Restores 800 health and mana.",
        "Use: Restores |cff00ff00720 to 880|r mana\nand health.",
    }) do
        tonic.description = description
        recovery = supplies:Scan()
        equal(recovery.byID[117].health, 800, "shared restoration supports either resource order and formatted text")
        equal(recovery.byID[117].mana, 800, "shared restoration retains both resource amounts")
    end
    tonic.description = "Use: Restores 720 to 880 mana and 100 health."
    recovery = supplies:Scan()
    equal(recovery.byID[117].health, 100, "separate amounts do not inherit the first resource range")
    equal(recovery.byID[117].mana, 800, "separate amounts retain the first resource range")
    tonic.description = "Use: Restores 720 to 880 mana and increases health by 100."
    equal(supplies:Scan().byID[117].flags.healing, false, "a health buff is not shared health restoration")
    tonic.description = "Use: Restores 720 to 880 mana and health."
    level = 34
    equal(supplies:Scan().byID[117], nil, "Tessa's required level still gates both recovery macros")
    level, restrictedTooltip = 39, 117
    recovery = supplies:Scan()
    equal(recovery.pending.healing, true, "restricted tonic tooltip pauses healing selection")
    equal(recovery.pending.mana, true, "restricted tonic tooltip pauses mana selection")
    restrictedTooltip = nil
    data[117], bags, level = nil, savedBags, savedLevel
end
equal(macros:Generate(bandage, snapshot), "#showtooltip item:107\n/use item:107", "automatic bandage preserves native item targeting")
bandage.item = 107
equal(macros:Generate(bandage, snapshot), "#showtooltip item:107\n/use item:107", "explicit bandage choice preserves native item targeting")
bandage.item = nil
equal(macros:Generate(mainhand, snapshot), "#showtooltip [nocombat] item:2862\n/use [nocombat] item:2862\n/use [nocombat] 16", "sword matches sharpening stone and main hand")
equal(macros:Generate(offhand, snapshot):find("item:3239", 1, true) ~= nil, true, "mace matches weightstone")
weapon[16] = 204
equal(macros:Generate(mainhand, snapshot):find("item:3239", 1, true) ~= nil, true, "staff swap changes the stone family")
weapon[16] = 205
equal(macros:Generate(mainhand, snapshot):find("item:3239", 1, true) ~= nil, true, "fist weapon matches weightstone")
weapon[16] = 203
equal(macros:Generate(mainhand, snapshot):find("item:2862", 1, true) ~= nil, true, "polearm matches sharpening stone")
level = 60; snapshot = supplies:Scan()
equal(macros:Generate(mainhand, snapshot):find("item:12404", 1, true) ~= nil, true, "highest ordinary usable stone tier wins")
level = 30; snapshot = supplies:Scan()
weapon[16] = 206
equal(macros:Generate(mainhand, snapshot), "#showtooltip", "shield never receives an automatic stone action")
weapon[16] = nil
equal(macros:Generate(mainhand, snapshot), "#showtooltip", "empty weapon slot has no action")
weapon[16] = 201
mainhand.item = 108
equal(macros:Generate(mainhand, snapshot):find("item:108", 1, true) ~= nil, true, "chosen coating overrides automatic stone")
mainhand.item = nil
locale = "deDE"; snapshot = supplies:Scan()
local _, _, pending = macros:Generate(food, snapshot)
equal(pending, true, "localized automatic food is never guessed")
food.item = 100
equal(macros:Generate(food, snapshot):find("item:100", 1, true) ~= nil, true, "explicit food supports another locale")
food.item, locale = nil, "enUS"
snapshot = supplies:Scan()

local native, created, edited = {}, 0, 0
Constants = { MacroConsts = { MAX_ACCOUNT_MACROS = 120, MAX_CHARACTER_MACROS = 30 } }
GetMacroInfo = function(index)
    local macro = native[index]
    if macro then return macro.name, 134400, macro.body end
end
local full = false
GetNumMacros = function()
    if full then return 120, 0 end
    local count = 0; for index in pairs(native) do if index <= 120 then count = count + 1 end end
    return count, 0
end
CreateMacro = function(name, _, text, perCharacter)
    assert(not InCombatLockdown() and not perCharacter)
    created = created + 1
    for i = 1, 120 do
        if not native[i] then native[i] = { name = name, body = text }; return i end
    end
end
EditMacro = function(index, name, icon, text)
    assert(not InCombatLockdown() and index <= 120)
    edited = edited + 1
    if name then native[index].name = name end
    native[index].body = text
    if macros.events then macros.events.OnEvent(macros.events, "UPDATE_MACROS") end
    return index
end
equal(macros:Save(food), true, "explicit create saves a General recipe")
equal(created, 1, "explicit create uses one slot")
equal(food.created, true, "confirmed save marks this character's recipe managed")
equal(macros:Save(food), true, "unchanged save is accepted")
equal(edited, 0, "unchanged macro causes no edit")
local original = native[1].body
local originalBags = bags
bags = { 100, 105 }
macros:Refresh()
equal(native[1].body, original, "disabled automatic updates keep created text unchanged")
Suite.db.macroUpdates = true
macros:Refresh()
equal(native[1].body:find("item:100", 1, true) ~= nil, true, "enabled updates follow current carried food")
equal(created, 1, "events never create unchecked or uncreated recipes")
bags = { 100, 104, 20390 }; macros:Refresh()
equal(native[1].body:find("[nocombat] item:20390", 1, true) ~= nil, true, "restocking event candy updates the owned food macro")
bags = { 100, 104, 20390, 101 }; macros:Refresh()
equal(native[1].body:find("[nocombat] item:101", 1, true) ~= nil, true, "restocking mage food takes priority over carried event candy")
food.item = 100; macros:Refresh()
equal(native[1].body:find("[nocombat] item:100", 1, true) ~= nil, true, "an explicit food choice overrides mage and event priority")
food.item, bags = nil, { 100, 105 }; macros:Refresh()
equal(native[1].body:find("[nocombat] item:100", 1, true) ~= nil, true, "depleted event and mage food fall back to ordinary supplies")
local current = native[1].body
local unchangedEdits = edited
native[1].body = current:gsub("\n", "\r\n") .. "\r\n"
equal(macros:Save(food), true, "line-ending differences do not revoke confirmed macro ownership")
equal(edited, unchangedEdits, "equivalent native line endings cause no unnecessary edit")
bags = { 101, 105 }
macros:Refresh()
equal(native[1].body:find("item:101", 1, true) ~= nil, true, "a macro with normalized native line endings can still update")
bags = { 100, 105 }
macros:Refresh()
current = native[1].body
local getSpell = C_Item.GetItemSpell
C_Item.GetItemSpell = function() return { secret = true } end
macros:Refresh()
equal(native[1].body, current, "restricted item-use data retains existing actions")
C_Item.GetItemSpell = nil
macros:Refresh()
equal(native[1].body, current, "missing item-use API cannot clear owned actions")
C_Item.GetItemSpell = getSpell
unavailable = 100
macros:Refresh(); macros:Refresh()
equal(native[1].body, current, "uncached data preserves existing text")
equal(requests[100], 1, "uncached item data is requested once")
unavailable, restrictedTooltip = nil, 100
macros:Refresh()
equal(native[1].body, current, "secret tooltip text preserves the old action")
restrictedTooltip, restrictedBag = nil, true
macros:Refresh()
equal(native[1].body, current, "secret container fields never become macro keys or text")
restrictedBag = nil
loadingBag, bags = true, { 101, 105 }
macros:Refresh()
equal(native[1].body, current, "occupied slot with missing item information preserves the previous macro")
equal(requests[101], 1, "readable occupied ID requests its missing data once")
macros:Refresh()
equal(requests[101], 1, "repeated loading scans coalesce item data requests")
local getContainerID = C_Container.GetContainerItemID
C_Container.GetContainerItemID = function() return { secret = true } end
macros:Refresh()
equal(native[1].body, current, "restricted slot occupancy cannot clear an owned macro")
C_Container.GetContainerItemID = function() error("slot unavailable") end
macros:Refresh()
equal(native[1].body, current, "failed occupancy query cannot clear an owned macro")
C_Container.GetContainerItemID = nil
macros:Refresh()
equal(native[1].body, current, "missing occupancy API cannot turn loading slots into empty supplies")
C_Container.GetContainerItemID, loadingBag = getContainerID, nil
macros:Refresh()
equal(native[1].body:find("item:101", 1, true) ~= nil, true, "ready slot information resumes automatic macro updates")
loadingBag = true
C_Container.GetContainerItemID = function() return nil end
macros:Refresh()
equal(native[1].body, "#showtooltip", "explicitly empty slots clear obsolete actions even when their item information is nil")
C_Container.GetContainerItemID, loadingBag = getContainerID, nil
bags = {}
macros:Refresh()
equal(native[1].body, "#showtooltip", "confirmed empty supplies clear obsolete automatic actions")
bags = originalBags
macros:Refresh()
equal(native[1].body:find("item:101", 1, true) ~= nil, true, "supplies returning restore owned automatic action")
native[1].body = "/say My edited macro"
current = native[1].body
macros:Refresh()
equal(native[1].body, current, "manual text edits pause updates")
equal(macros:Save(food), true, "deliberate Update replaces edited text in a previously owned macro")
equal(native[1].body, macros:Generate(food, supplies:Scan()), "explicit Update writes the generated preview")
equal(Suite.db.macroOwnership[food.name], native[1].body, "confirmed Update refreshes ownership for subsequent automatic changes")
native[1] = nil
macros:Refresh()
equal(native[1], nil, "deleted macros are not recreated by events")
equal(macros:Save(food), true, "explicit create can restore a deleted owned macro")
native[2] = { name = water.name, body = "/say Existing user macro" }
equal(macros:Save(water), false, "same-name user macro is never overwritten")
equal(native[2].body, "/say Existing user macro", "conflict preserves user's text")
native[2] = nil
full = true
equal(macros:Save(water), false, "full General slots produce a safe failure")
full = false
MacroFrame = Frame("MacroFrame")
MacroFrame:Show()
equal(macros:Save(water), false, "open native macro editor cannot lose unsaved edits")
MacroFrame:Hide()
native[121] = { name = water.name, body = "/say Character macro" }
equal(macros:Save(water), true, "character-scope names do not block General creation")
equal(native[121].body, "/say Character macro", "existing character macro is preserved")
native[3] = { name = food.name, body = native[1].body }
equal(macros:Save(food), false, "duplicate General names cannot be selected ambiguously")
native[3] = nil
local firstCharacter = Suite.macroDB
local beforeAltCreates = created
local secondCharacter = macros:Initialize(nil)
equal(secondCharacter.entries[1].created, true, "another character recognizes the shared owned food macro")
equal(secondCharacter.entries[2].created, true, "another character recognizes the shared owned drink macro")
equal(secondCharacter.entries[3].created, false, "a missing General recipe remains uncreated on an alt")
equal(secondCharacter.entries[1].combat, false, "shared recognition keeps the alt's default combat choice")
bags = { 100 }
macros:Refresh()
equal(native[1].body, "#showtooltip [nocombat] item:100\n/use [nocombat] item:100", "shared food refreshes to alt supplies without another Create")
equal(native[2].body, "#showtooltip", "shared drink clears unavailable alt supplies automatically")
equal(created, beforeAltCreates, "recognizing and refreshing shared macros allocates no new General slots")
Suite.macroDB = firstCharacter
bags = originalBags

weapon[17] = nil
equal(macros:Save(offhand), true, "empty off hand can explicitly create a placeholder")
local offhandIndex = macros:Find(offhand.name)
equal(native[offhandIndex].body, "#showtooltip", "empty off-hand placeholder contains no use action")
equal(offhand.created, true, "placeholder is managed like a created recipe")
local placeholderCreates = created
weapon[17] = 202
macros:Refresh()
equal(native[offhandIndex].body, "#showtooltip [nocombat] item:3239\n/use [nocombat] item:3239\n/use [nocombat] 17", "equipping a suitable off hand fills its existing placeholder")
equal(created, placeholderCreates, "filling a placeholder reuses its General slot")
weapon[17] = 206
macros:Refresh()
equal(native[offhandIndex].body, "#showtooltip", "equipping a shield clears the automatic off-hand action")
weapon[17] = 202
macros:Refresh()
local offhandBody = native[offhandIndex].body
restrictedWeapon = true
macros:Refresh()
equal(native[offhandIndex].body, offhandBody, "unreadable weapon data cannot empty an active coating macro")
restrictedWeapon = nil
SetCombat(true)
weapon[17] = nil
macros:Refresh()
equal(native[offhandIndex].body, offhandBody, "removing a weapon in combat defers changes to its macro")
SetCombat(false)
macros:Refresh()
equal(native[offhandIndex].body, "#showtooltip", "leaving combat clears the now-empty hand")

bags = {}
Suite.db.macroUpdates = false
equal(macros:Save(mainhand), true, "missing carried coating permits an explicit main-hand placeholder")
local mainhandIndex = macros:Find(mainhand.name)
equal(native[mainhandIndex].body, "#showtooltip", "main-hand placeholder contains no stale action")
equal(Suite.db.macroUpdates, false, "creating a placeholder preserves the automatic-update preference")
bags = originalBags
macros:Refresh()
equal(native[mainhandIndex].body, "#showtooltip", "updates off keeps a placeholder inert when supplies arrive")
Suite.db.macroUpdates = true
macros:Refresh()
equal(native[mainhandIndex].body, "#showtooltip [nocombat] item:2862\n/use [nocombat] item:2862\n/use [nocombat] 16", "returning supplies fill the existing main-hand placeholder")
weapon[17] = 202
local _, _, awaitingData = macros:Generate(offhand, { incomplete = true })
equal(awaitingData, true, "placeholder support keeps incomplete-data safeguards")
equal(macros:CanSave(offhand, nil, true, false), false, "unreadable data does not allow an empty overwrite")
equal(macros:CanSave({ recipe = "food", created = false }, "#showtooltip", false, false), false, "empty non-weapon starter retains its existing creation rule")

local timers = {}
C_Timer.NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end
local function Flush()
    local batch = timers; timers = {}
    for _, timer in ipairs(batch) do if not timer.cancelled then timer.callback() end end
end
Suite.db.macroUpdates = true
macros:Apply(); Flush()
equal(macros:Save(bandage), true, "create bandage for event-driven update regressions")
local bandageIndex = macros:Find(bandage.name)
local function UseSupplies()
    for _, entry in ipairs(Suite.macroDB.entries) do
        if entry.created and macros:ItemRecipe(entry) then macros:Used(entry.name) end
    end
end
local function SupplyEvent(event, ...)
    macros.events.OnEvent(macros.events, event, ...)
    if macros.useEvents and macros.useEvents.OnEvent then macros.useEvents.OnEvent(macros.useEvents, event, ...) end
end
-- An existing owned macro from before the fix must update in place, including on the bar.
local oldBandageBody = "#showtooltip item:107\n/use [@player] item:107"
native[bandageIndex].body, Suite.db.macroOwnership[bandage.name] = oldBandageBody, oldBandageBody
SetCombat(true)
macros:Refresh()
equal(native[bandageIndex].body, oldBandageBody, "old owned bandage is not rewritten in combat")
SetCombat(false)
macros:Refresh()
equal(macros:Find(bandage.name), bandageIndex, "bandage targeting correction retains the existing macro index")
equal(native[bandageIndex].body, "#showtooltip item:107\n/use item:107", "old owned self-bandage updates to native targeting")
equal(Suite.db.macroOwnership[bandage.name], native[bandageIndex].body, "corrected bandage remains managed")
bags, unavailable, weapon[16], weapon[17] = { 100, 104, 116, 3239, 115 }, 115, 204, nil
UseSupplies(); SupplyEvent("BAG_UPDATE_DELAYED")
macros.events.OnEvent(macros.events, "PLAYER_EQUIPMENT_CHANGED", 16)
Flush()
equal(native[1].body:find("item:100", 1, true) ~= nil, true, "bag events update food despite an uncached unrelated reagent")
equal(native[2].body:find("item:104", 1, true) ~= nil, true, "bag events update drink despite an uncached unrelated reagent")
equal(native[bandageIndex].body, "#showtooltip item:116\n/use item:116", "bag events change bandage supplies while preserving native targeting despite an uncached unrelated reagent")
equal(native[mainhandIndex].body:find("item:3239", 1, true) ~= nil, true, "equipment events update coatings despite an uncached unrelated reagent")
equal(native[offhandIndex].body, "#showtooltip", "empty hand clears its coating despite an uncached unrelated reagent")
equal(requests[115], 1, "unrelated uncached data is still requested once")

bags, unavailable, weapon[16] = { 101, 107, 2862, 3239 }, 101, 201
local pendingFood = native[1].body
UseSupplies(); SupplyEvent("BAG_UPDATE_DELAYED"); Flush()
equal(native[1].body, pendingFood, "pending relevant food retains its previous action")
equal(native[2].body:find("item:104", 1, true) ~= nil, true, "unknown recovery item also preserves drink until classified")
equal(native[bandageIndex].body, "#showtooltip item:107\n/use item:107", "ready bandage updates retain native targeting while food is pending")
equal(native[mainhandIndex].body:find("item:2862", 1, true) ~= nil, true, "pending food does not pause ready coating updates")
unavailable = nil
SupplyEvent("GET_ITEM_INFO_RECEIVED", 101, true); Flush()
equal(native[1].body:find("item:101", 1, true) ~= nil, true, "item data completion fills the previously pending food recipe")
equal(native[2].body, "#showtooltip", "complete recovery data can clear now-missing water")

bags, unavailable, food.combat = { 100, 105, 107, 2862, 3239 }, 105, false
UseSupplies(); SupplyEvent("BAG_UPDATE_DELAYED"); Flush()
equal(native[1].body:find("item:100", 1, true) ~= nil, true, "pending potion cannot pause food with combat additions off")
food.combat, bags = true, { 101, 105, 107, 2862, 3239 }
pendingFood = native[1].body
UseSupplies(); SupplyEvent("BAG_UPDATE_DELAYED"); Flush()
equal(native[1].body, pendingFood, "enabled combat addition waits for its pending potion")
unavailable = nil
SupplyEvent("GET_ITEM_INFO_RECEIVED", 105, true); Flush()
equal(native[1].body:find("item:105", 1, true) ~= nil, true, "completed potion data resumes the combat food recipe")

weapon[16], weapon[17] = 204, 202
UseSupplies(); SupplyEvent("PLAYER_EQUIPMENT_CHANGED", 17); Flush()
local pendingMainhand, pendingOffhand = native[mainhandIndex].body, native[offhandIndex].body
bags, unavailable, weapon[16] = { 100, 107, 2862, 3239 }, 3239, 204
UseSupplies(); SupplyEvent("BAG_UPDATE_DELAYED"); Flush()
equal(native[offhandIndex].body, pendingOffhand, "pending matching weightstone preserves the off-hand action")
equal(native[mainhandIndex].body, pendingMainhand, "pending matching weightstone preserves the previous main-hand action")
weapon[16] = 201
UseSupplies(); SupplyEvent("PLAYER_EQUIPMENT_CHANGED", 16); Flush()
equal(native[mainhandIndex].body:find("item:2862", 1, true) ~= nil, true, "pending weightstone does not pause a ready sharpening recipe")
equal(native[1].body:find("item:100", 1, true) ~= nil, true, "pending stone does not pause recovery updates")

local diagnostics, printMessage = {}, Suite.Print
Suite.Print = function(message) diagnostics[#diagnostics + 1] = message end
local diagnosticWrites = created + edited
SlashCmdList.WOWFOREVERSUITE("macrostatus")
equal(diagnostics[1]:find("On", 1, true) ~= nil, true, "macro status reports the enabled update preference")
equal(table.concat(diagnostics, "\n"):find("Matching stone data is loading", 1, true) ~= nil, true, "macro status exposes the actual pending recipe")
equal(created + edited, diagnosticWrites, "macro status performs no native macro writes")
Suite.Print = printMessage
macros:FinishUsed(); Flush()
bags, unavailable, weapon[16], weapon[17] = originalBags, nil, 201, 202
macros:Apply(); macros:Queue(); macros:Queue()
equal(#timers, 1, "event bursts coalesce into one cancellable timer")
MacroFrame:Show()
local editorBody = native[1].body
Flush()
equal(native[1].body, editorBody, "automatic updates pause while native editor is open")
MacroFrame:Hide(); MacroFrame.OnHide(MacroFrame)
equal(macros.timer ~= nil, true, "closing the native editor queues a refresh")
SetCombat(true)
macros.events.OnEvent(macros.events, "PLAYER_REGEN_DISABLED")
equal(macros.timer, nil, "combat cancels pending update")
local writes = edited + created
equal(macros:Save(mainhand), false, "combat cannot create a macro")
Flush()
equal(edited + created, writes, "cancelled timer performs no combat writes")
SetCombat(false)
macros.events.OnEvent(macros.events, "PLAYER_REGEN_ENABLED")
Flush()
equal(macros.timer, nil, "post-combat refresh leaves no idle timer")
Suite.db.macroUpdates = false
macros:Queue(); macros:Apply(); Flush()
equal(macros.timer, nil, "disabled hidden module leaves no timer")
restrictedWeapon = true
local _, _, weaponPending = macros:Generate(mainhand, supplies:Scan())
equal(weaponPending, true, "secret equipped weapon data retains the owned action")
restrictedWeapon = nil

local gui = Suite.GUI
gui:Select("macros")
macros:Refresh()
equal(gui.macroPanel:IsShown(), true, "Macros opens as a sidebar page")
-- The 240px copy box extends past its 93px viewport over both actions.
-- Model overlapping input priority rather than invoking a covered button directly.
local function MacroActionReceiver(button)
    return button:GetFrameLevel() > gui.macroPreview:GetFrameLevel() and button or gui.macroPreview
end
equal(MacroActionReceiver(gui.macroSave), gui.macroSave, "save receives input above the overflowing preview")
equal(MacroActionReceiver(gui.macroUpdates), gui.macroUpdates, "automatic-update toggle receives input above the overflowing preview")
equal(gui.macroRows[1].entry, food, "recipe selection uses persistent character choices")
offhand.created = false
weapon[17] = nil
macros.snapshot = supplies:Scan()
gui.macroRows[5].OnClick()
equal(gui.macroSave.enabled, true, "empty hand leaves the GUI Create button enabled")
equal(gui.macroSave.label.text, "Create placeholder", "GUI explains blank weapon macro creation")
MacroActionReceiver(gui.macroSave).OnClick()
equal(gui.macroStatus.text:find("Placeholder saved", 1, true) ~= nil, true, "GUI save immediately displays the write result")
equal(offhand.created, true, "GUI can save the empty-hand placeholder")
equal(native[offhandIndex].body, "#showtooltip", "GUI placeholder cannot apply a coating to an empty hand")
weapon[17] = 202
gui.macroRows[2].OnClick()
equal(gui.macroSelected, water, "recipe click changes the preview")
local menuChoices = {}
MenuUtil = { CreateContextMenu = function(_, build)
    build(nil, { CreateButton = function(_, label, callback) menuChoices[#menuChoices + 1] = { label, callback } end,
        CreateTitle = function() end })
end }
gui.macroRows[4].OnClick(); gui:ChooseMacroItem()
equal(menuChoices[1][1], "Select automatically", "item picker offers automatic reset for coatings")
for _, choice in ipairs(menuChoices) do if choice[1]:find("Shadow Oil", 1, true) then choice[2]() end end
equal(mainhand.item, 108, "picker chooses a carried coating without using it")
gui.macroPreview.text = "/say altered"
gui.macroPreview.OnTextChanged(gui.macroPreview, true)
equal(gui.macroPreview.text, gui.macroPreviewBody, "copyable preview cannot silently change the recipe")
SetCombat(true)
gui:RefreshMacros()
equal(gui.macroSave.enabled, false, "create button is disabled in combat")
equal(gui.macroChoose.enabled, false, "item choices are disabled in combat")
SetCombat(false)
gui:Select("overview")
equal(gui.macroPanel:IsShown(), false, "leaving Macros hides its controls")
equal(macros.visible, false, "leaving Macros stops preview subscriptions")
local extra = macros:AddItem()
equal(extra.name, "FS Item 1", "item variants have stable generated names")
local restored = macros:Initialize(Suite.macroDB)
equal(restored.entries[4].item, 108, "chosen coating survives character settings reload")
equal(restored.entries[7].name, "FS Item 1", "item variant survives character settings reload")
equal(macros:RemoveItem(restored.entries[7]), true, "remove an item choice independently of its game macro")
equal(#Suite.macroDB.entries, 6, "removing a choice stops its future updates")
equal(macros:AddItem().name, "FS Item 2", "removed names are not reused for unrelated items")
local generic = Suite.macroDB.entries[7]
generic.item = 108
equal(macros:Save(generic), true, "chosen item variant can be created")
local genericIndex = macros:Find(generic.name)
local keptBody = native[genericIndex].body
equal(macros:RemoveItem(generic), true, "created item option can stop updates")
equal(native[genericIndex].body, keptBody, "removing a choice leaves its game macro intact")
local readMacro = GetMacroInfo
GetMacroInfo = function(index) if index == 1 then return { secret = true } end; return readMacro(index) end
equal(macros:Save(food), false, "unreadable macro names cannot select a write target")
GetMacroInfo = readMacro
local writeMacro = EditMacro
EditMacro = function() error("Client refused edit") end
food.combat = true
equal(macros:Write(food, "#showtooltip\n/use [nocombat] item:100", true), false, "native API failure leaves ownership unchanged")
EditMacro = writeMacro
local bad = macros:Initialize({ entries = { { recipe = "item", serial = 1, item = -4 },
    { recipe = "item", serial = 1 }, { recipe = "unknown" }, { recipe = "food", item = "invalid", created = true } } })
equal(#bad.entries, 8, "corrupt saved choices are repaired while existing shared item macros are recognized")
equal(bad.entries[1].item, nil, "invalid saved item IDs do not enter macro text")

-- Exercise shared enrollment through real saves and the normal event lifecycle.
macros:Cancel(); Flush()
local previousNative, previousDB, previousCharacter = native, Suite.db, Suite.macroDB
local registered = {}
local eventRegister, eventUnregister = macros.events.RegisterEvent, macros.events.UnregisterAllEvents
macros.events.RegisterEvent = function(_, event) registered[event] = true end
macros.events.UnregisterAllEvents = function() registered = {} end
native = {}
Suite.db = Suite.InitializeDB(nil)
local owner = macros:Initialize(nil)
bags, weapon[16], weapon[17] = originalBags, 201, 202
owner.entries[1].combat, owner.entries[4].item = true, 108
for _, entry in ipairs(owner.entries) do equal(macros:Save(entry), true, "create a fixed recipe for cross-character recognition") end
local chosen = macros:AddItem(); chosen.item = 108
equal(macros:Save(chosen), true, "save first shared chosen-item recipe")
local secondItem = macros:AddItem(); secondItem.item = 107
equal(macros:Save(secondItem), true, "save second shared chosen-item recipe")
local shareCreates, shareWrites, ownerFood = created, edited, native[1].body
local alt = macros:Initialize(nil)
for index = 1, 5 do equal(alt.entries[index].created, true, "every existing fixed General macro is recognized on a fresh alt") end
equal(#alt.entries, 8, "shared chosen-item recipes appear without adding them on the alt")
equal(alt.entries[7].name, "FS Item 1", "shared item imports retain stable sorted names")
equal(alt.entries[7].item, 108, "shared item import recovers its confirmed chosen item")
equal(alt.entries[8].item, 107, "shared item variants retain independent choices")
equal(alt.nextSerial, 3, "new item names advance beyond existing shared names")
equal(created, shareCreates, "login recognition never creates game macros")
equal(edited, shareWrites, "login recognition never edits game macros")
equal(Suite.db.macroUpdates, false, "recognition preserves the disabled automatic-update preference")
macros:Refresh()
equal(native[1].body, ownerFood, "updates off keeps the owner's shared text unchanged on the alt")
equal(alt.entries[1].combat, false, "recognition preserves fresh character combat defaults")
equal(alt.entries[4].item, nil, "fixed recipes retain per-character item choices")
local existingAlt = macros:Initialize({ schema = 1, entries = {
    { recipe = "food", created = false, combat = true, item = 100 },
    { recipe = "item", serial = 1, created = false, item = 107 },
    { recipe = "item", serial = 2, created = false },
} })
equal(existingAlt.schema, 2, "older character settings migrate to shared discovery with removal memory")
equal(existingAlt.entries[1].created, true, "previously visited alts recognize General macros despite old false flags")
equal(existingAlt.entries[1].combat, true, "recognition retains the alt's saved combat choice")
equal(existingAlt.entries[1].item, 100, "recognition retains the alt's saved food override")
equal(existingAlt.entries[7].created, true, "a saved item choice becomes active without another Create")
equal(existingAlt.entries[7].item, 107, "existing alt item choices are preserved during recognition")
equal(existingAlt.entries[8].item, 107, "an unfinished alt item choice recovers the existing shared macro's item")
alt = macros:Initialize(nil)
Suite.db.macroUpdates = true
bags = { 100, 104, 107, 108, 2862, 3239 }
macros:Apply(); Flush()
equal(native[1].body, ownerFood, "login alone does not recheck unused shared item macros")
UseSupplies(); Flush()
equal(native[1].body, "#showtooltip [nocombat] item:100\n/use [nocombat] item:100", "using shared food updates it for the alt's current supplies")
equal(native[2].body:find("item:104", 1, true) ~= nil, true, "shared drink follows alt supplies through normal queued work")
equal(native[4].body:find("item:2862", 1, true) ~= nil, true, "shared coating follows the alt's weapon and own recipe choice")
equal(created, shareCreates, "automatic alt updates reuse existing General slots")
local altItem = alt.entries[7]
equal(macros:RemoveItem(altItem), true, "an alt can still remove a shared item choice locally")
local keptItem = native[7].body
macros:Refresh()
equal(#alt.entries, 7, "refresh does not re-import a deliberately removed item choice")
equal(native[7].body, keptItem, "local removal keeps the General macro unchanged")
alt = macros:Initialize(alt)
equal(#alt.entries, 7, "reload retains local removal of a shared item choice")
equal(alt.ignoredItems[1], true, "removed item serial is remembered on this character")
local otherAlt = macros:Initialize(nil)
equal(#otherAlt.entries, 8, "local removal does not hide the shared item from another character")
local newItem = macros:AddItem()
equal(newItem.name, "FS Item 3", "adding on another character cannot reuse an existing shared item name")
equal(newItem.created, false, "adding a new item choice still requires explicit creation")
equal(created, shareCreates, "adding a choice cannot create a General macro automatically")
local baselineNative, baselineOwnership = Suite.Copy(native), Suite.Copy(Suite.db.macroOwnership)
local function ResetShared()
    macros:Cancel(); Flush()
    native, Suite.db.macroOwnership = Suite.Copy(baselineNative), Suite.Copy(baselineOwnership)
end

ResetShared()
native[119] = Suite.Copy(native[1])
alt = macros:Initialize(nil)
equal(alt.entries[1].created, false, "duplicate General names are not automatically adopted")
equal(alt.entries[2].created, true, "duplicate names do not block independent shared recipes")
local duplicateBody = native[1].body
macros:Refresh()
equal(native[1].body, duplicateBody, "ambiguous shared names cannot be rewritten")
native[119] = nil
macros.events.OnEvent(macros.events, "UPDATE_MACROS"); Flush()
equal(alt.entries[1].created, true, "a later macro event recognizes a now-unambiguous shared recipe")

ResetShared()
native[1].body = "/say My edited shared macro"
alt = macros:Initialize(nil)
equal(alt.entries[1].created, false, "a fresh alt does not adopt an externally edited shared macro")
macros:Refresh()
equal(native[1].body, "/say My edited shared macro", "automatic alt refresh preserves an external text edit")
ResetShared()
Suite.db.macroOwnership["FS Food"] = nil
alt = macros:Initialize(nil)
equal(alt.entries[1].created, false, "matching Suite names and generated text alone cannot establish ownership")
ResetShared()
native[121], native[1] = native[1], nil
alt = macros:Initialize(nil)
equal(alt.entries[1].created, false, "character-only macros cannot activate a General recipe")
equal(native[121].name, "FS Food", "shared discovery preserves character macros")
ResetShared()
native[1].body = native[1].body:gsub("\n", "\r\n") .. "\r\n"
alt = macros:Initialize(nil)
equal(alt.entries[1].created, true, "shared recognition accepts the same native line-ending normalization as updates")

ResetShared()
GetMacroInfo = nil
alt = macros:Initialize(nil)
equal(alt.entries[1].created, false, "missing macro APIs cannot falsely recognize ownership")
equal(#alt.entries, 6, "missing macro APIs cannot import item choices")
GetMacroInfo = readMacro
macros:Apply(); Flush()
equal(alt.entries[1].created, true, "late macro API availability recognizes fixed recipes without another Create")
equal(#alt.entries, 8, "late macro API availability imports shared chosen-item recipes")
for _, restriction in ipairs({ "name", "body", "error" }) do
    ResetShared()
    GetMacroInfo = function(index)
        if index == 120 then
            if restriction == "name" then return { secret = true }, 134400, "#showtooltip" end
            if restriction == "body" then return "Other", 134400, { secret = true } end
            error("Macro information unavailable")
        end
        return readMacro(index)
    end
    alt = macros:Initialize(nil)
    equal(alt.entries[1].created, false, "unreadable General listings defer all new ownership recognition")
    equal(#alt.entries, 6, "unreadable General listings cannot import item recipes")
    GetMacroInfo = readMacro
    macros.events.OnEvent(macros.events, "UPDATE_MACROS"); Flush()
    equal(alt.entries[1].created, true, "a readable later macro event resumes deferred recognition")
end

ResetShared()
MacroFrame:Show()
alt = macros:Initialize(nil)
equal(alt.entries[1].created, true, "read-only shared recognition is allowed while the native editor is open")
local editorWrites = edited
bags = { 101, 107, 108, 2862, 3239 }
UseSupplies()
macros:Refresh()
equal(edited, editorWrites, "shared enrollment cannot discard open native editor text")
MacroFrame:Hide(); MacroFrame.OnHide(MacroFrame); Flush()
equal(native[1].body:find("item:101", 1, true) ~= nil, true, "closing the editor refreshes the alt's recognized shared recipe")

ResetShared()
SetCombat(true)
alt = macros:Initialize(nil)
equal(alt.entries[1].created, false, "first shared discovery defers in combat")
equal(#alt.entries, 6, "combat cannot import shared item choices")
local combatWrites = created + edited
macros:Apply()
macros.events.OnEvent(macros.events, "UPDATE_MACROS")
equal(macros.timer, nil, "combat leaves no pending discovery worker")
equal(created + edited, combatWrites, "combat discovery attempts never create or edit a game macro")
SetCombat(false)
macros.events.OnEvent(macros.events, "PLAYER_REGEN_ENABLED"); Flush()
equal(alt.entries[1].created, true, "post-combat work recognizes the shared fixed recipe")
equal(#alt.entries, 8, "post-combat work imports shared item choices")

ResetShared()
native[9] = { name = "FS Item 3", body = "#showtooltip item:108\n/use item:108" }
alt = macros:Initialize(nil)
equal(#alt.entries, 8, "unowned item macro names are never imported")
for _, text in ipairs({ "#showtooltip item:108\n/use item:107", "#showtooltip item:108\n/use item:108\n/say extra", "#showtooltip item:10000001\n/use item:10000001" }) do
    ResetShared()
    native[7].body, Suite.db.macroOwnership["FS Item 1"] = text, text
    alt = macros:Initialize(nil)
    equal(#alt.entries, 7, "item import requires the exact confirmed generated single-item shape and a valid ID")
end
ResetShared()
native[7].body = "/say Custom item"
alt = macros:Initialize(nil)
equal(#alt.entries, 7, "externally edited chosen-item macros are not imported")
ResetShared()
native = {}
alt = macros:Initialize(nil)
equal(#alt.entries, 6, "ownership history without existing General macros cannot import item choices")
macros:Refresh()
equal(created, shareCreates, "deleted shared macros are never recreated by login or events")
Suite.db.macroUpdates = false
macros:Apply()
equal(macros.timer, nil, "updates off and hidden sharing retain no timer")
equal(next(registered), nil, "updates off and hidden sharing retain no feature events")

native, Suite.db.macroOwnership = {}, {}
for serial = 12, 1, -1 do
    local name, text = "FS Item " .. serial, "#showtooltip item:108\n/use item:108"
    native[serial] = { name = name, body = text }
    Suite.db.macroOwnership[name] = text
end
alt = macros:Initialize(nil)
equal(#alt.entries, 16, "shared item discovery retains the ten-choice limit")
equal(alt.entries[7].serial, 1, "bounded item imports choose the earliest serial first")
equal(alt.entries[16].serial, 10, "bounded item imports are stable despite ownership table order")
equal(alt.nextSerial, 13, "name allocation accounts for shared items beyond the local choice limit")
equal(macros:AddItem(), nil, "full shared item choices keep the existing add limit")
equal(macros:RemoveItem(alt.entries[7]), true, "shared item removal remains available at the limit")
alt = macros:Initialize(alt)
equal(alt.entries[16].serial, 11, "the next available shared item can fill space after a local removal")
equal(alt.ignoredItems[1], true, "bounded imports preserve deliberate local removals")
-- Class recipes share the existing ownership rules, but never appear or update on other classes.
local oldUnitClass, oldSpellAPI, oldPetAPI, oldUnitExists = UnitClass, C_Spell, C_PetInfo, UnitExists
local playerClass = "HUNTER"
UnitClass = function() return "Hunter", playerClass end
local petExists, petFoods = true, { [100] = true, [113] = true }
UnitExists = function(unit) return unit == "pet" and petExists or false end
C_PetInfo = { CanPetEatItem = function(id) return petFoods[id] == true end }
local spells = { [34477] = "Misdirection", [982] = "Revive Pet", [136] = "Mend Pet", [6991] = "Feed Pet" }
C_Spell = { GetSpellInfo = function(id) return spells[id] and { name = spells[id] } end }
native, Suite.db.macroOwnership = {}, {}
Suite.db.macroUpdates = false
alt = macros:Initialize(nil)
equal(#macros:Entries(), 13, "hunter sees seven class recipes alongside shared recipes")
local redirect, pet = alt.entries[7], alt.entries[8]
equal(redirect.recipe, "hunterMisdirection", "hunter recipes precede arbitrary item choices")
equal(macros:Generate(redirect, { incomplete = true }), "#showtooltip Misdirection\n/cast [@focus,help][@target,help][@pet,exists] Misdirection", "misdirection exactly preserves requested friendly target precedence without bag dependencies")
equal(macros:Save(redirect), true, "hunter can explicitly create misdirection")
local redirectIndex = macros:Find(redirect.name)
local savedRedirect = native[redirectIndex].body
local blankBody, _, blankPending = macros:Generate(pet, supplies:Scan())
equal(blankBody, nil, "pet care needs a deliberate food choice")
equal(blankPending, true, "unselected pet food cannot create a misleading macro")
bags = { 100, 100, 113, 105, 109 }
data[113].name = "Raw Pet Food"
macros.snapshot = supplies:Scan()
equal(macros.snapshot.carriedByID[100].count, 4, "explicit picker counts duplicate stacks")
equal(macros.snapshot.carriedByID[113].name, "Raw Pet Food", "explicit picker includes ingredients without a use spell")
gui.macroSelected = pet
gui:RefreshMacros()
equal(gui.macroRows[8].entry, pet, "all hunter recipes occupy the scroll child without paging")
equal(gui.macroRows[8]:GetParent(), gui.macroListContent, "recipe rows belong to the independent list viewport")
equal(gui.macroListHeadings[1].label.text, "− General", "ordinary recipes have their own heading")
equal(gui.macroListHeadings[2].label.text, "− Hunter Macros", "hunter recipes have a separate heading")
local outerOffset = gui.scrollOffset
gui.macroListScroll.suiteScrollBar.OnMouseWheel(gui.macroListScroll.suiteScrollBar, -1000)
equal(gui.macroListScroll.suiteOffset, gui.macroListScroll.suiteMaximum, "list thumb reaches the last hunter recipe")
equal(gui.scrollOffset, outerOffset, "list thumb scrolling leaves the surrounding page unchanged")
gui.macroRows[8].OnClick()
equal(gui.macroSelected, pet, "a scrolled hunter row selects its matching detail view")
gui.macroRows[8].OnMouseWheel(gui.macroRows[8], 1)
equal(gui.macroListScroll.suiteOffset, gui.macroListScroll.suiteMaximum - 40, "wheel over a recipe scrolls its own list")
equal(gui.scrollOffset, outerOffset, "row wheel input does not scroll the outer page")
equal(gui.macroChoose:IsShown(), true, "hunter pet care exposes a food picker")
menuChoices = {}; gui:ChooseMacroItem()
equal(menuChoices[1][1] ~= "Select automatically", true, "pet food never offers an automatic replacement")
for _, choice in ipairs(menuChoices) do if choice[1]:find("Raw Pet Food", 1, true) then choice[2]() end end
equal(pet.item, 113, "pet food picker records the player's explicit ingredient choice")
local petBody = macros:Generate(pet, macros.snapshot)
equal(petBody, "#showtooltip\n/cast [@pet,dead][nopet,mod:shift] Revive Pet\n/cast [combat,@pet,exists,nodead] Mend Pet; [nocombat,@pet,exists,nodead] Feed Pet\n/stopmacro [combat][nopet][@pet,dead]\n/use Raw Pet Food", "pet macro guards feeding against combat, dead and absent pets")
equal(#petBody <= 255, true, "English pet care fits the native body limit")
equal(macros:Save(pet), true, "selected pet food allows explicit creation")
local petIndex = macros:Find(pet.name)

-- Feed Pet consumes an item target, not a unit target. Model the generated
-- command contract separately from ordinary item-ID use macros.
local function FeedingTarget(text, combatState, petState)
    local blocked = combatState or petState == "absent" or petState == "dead"
    for line in text:gmatch("[^\n]+") do
        if line == "/stopmacro [combat][nopet][@pet,dead]" and blocked then return nil end
        if line:sub(1, 5) == "/use " then return line:sub(6) end
    end
end
equal(FeedingTarget(petBody, false, "alive"), "Raw Pet Food", "feeding supplies an exact item name to the pending food cursor")
equal(FeedingTarget(petBody, true, "alive"), nil, "combat stops before the ingredient use line")
equal(FeedingTarget(petBody, false, "dead"), nil, "dead pets stop before the ingredient use line")
equal(FeedingTarget(petBody, false, "absent"), nil, "absent pets stop before the ingredient use line")
equal(petBody:find("/use [", 1, true), nil, "food use does not pass a unit target to item targeting")


-- Deliberate pet food changes update an existing owned macro even when automatic
-- bag/equipment updates are off, including a raw ingredient in reagent bag 5.
Suite.db.macroUpdates = false
menuChoices = {}; gui:ChooseMacroItem()
for _, choice in ipairs(menuChoices) do if choice[1]:find("Vendor Bread", 1, true) then choice[2]() end end
equal(pet.item, 100, "manual pet food selection changes the stored choice")
equal(native[petIndex].body:find("/use Vendor Bread", 1, true) ~= nil, true, "manual pet food selection updates the saved macro with automatic updates off")
equal(Suite.db.macroUpdates, false, "manual pet food selection preserves the automatic-update preference")
local bagSlots, bagInfo, bagID, bagMaximum = C_Container.GetContainerNumSlots, C_Container.GetContainerItemInfo, C_Container.GetContainerItemID, NUM_TOTAL_EQUIPPED_BAG_SLOTS
local rawName, rawBags = data[113].name, bags
bags, data[113].name, NUM_TOTAL_EQUIPPED_BAG_SLOTS = { 100 }, "Raw Bristle Whisker Catfish", 5
C_Container.GetContainerNumSlots = function(bag) return bag == 5 and 1 or bagSlots(bag) end
C_Container.GetContainerItemInfo = function(bag, slot) if bag == 5 and slot == 1 then return { itemID = 113, stackCount = 3 } end; return bagInfo(bag, slot) end
C_Container.GetContainerItemID = function(bag, slot) if bag == 5 and slot == 1 then return 113 end; return bagID(bag, slot) end
menuChoices = {}; gui:ChooseMacroItem()
for _, choice in ipairs(menuChoices) do if choice[1]:find("Raw Bristle Whisker Catfish", 1, true) then choice[2]() end end
equal(pet.item, 113, "raw food in reagent bag 5 can be explicitly selected")
equal(native[petIndex].body, petBody:gsub("Raw Pet Food", "Raw Bristle Whisker Catfish"), "reagent-bag raw food uses its exact localized name without requiring an item-use spell")
equal(macros.snapshot.carriedByID[113].count, 3, "reagent bag food count reaches the picker")
C_Container.GetContainerNumSlots, C_Container.GetContainerItemInfo, C_Container.GetContainerItemID, NUM_TOTAL_EQUIPPED_BAG_SLOTS = bagSlots, bagInfo, bagID, bagMaximum
bags, data[113].name = rawBags, rawName
macros:Save(pet, true)
local petNative, petCreates = native[petIndex], created
native[petIndex] = nil
equal(macros:Save(pet, true), false, "existing-only food update never recreates a deleted macro")
equal(created, petCreates, "existing-only food update allocates no General slot")
native[petIndex] = petNative
petNative.body = "/say Keep my custom pet macro"
equal(macros:Save(pet, true), false, "manual food change preserves externally edited macros")
equal(petNative.body, "/say Keep my custom pet macro", "manual food choice cannot overwrite custom text")
-- Reproduce the recording: the owned macro has older/manual text; the visible
-- Update action must save the preview even though picker/background writes pause.
gui:Select("macros"); gui.macroSelected = pet; gui:RefreshMacros()
equal(macros:Save(pet, true), false, "existing-only picker cannot approve replacement")
Suite.db.macroUpdates = true; macros:Refresh()
equal(petNative.body, "/say Keep my custom pet macro", "automatic updates continue preserving edited pet text")
equal(macros.statuses[pet]:find("Click Update macro", 1, true) ~= nil, true, "paused status explains the explicit replacement action")
equal(gui.macroStatus.textColor[1], 1, "blocked automatic update status is red")
equal(gui.macroStatus.textColor[2], 0.3, "blocked status uses a readable red tone")
gui.macroSave.OnClick()
equal(gui.macroStatus.textColor[1], 0.41, "confirmed save clears red and uses Suite teal")
equal(petNative.body, petBody, "GUI Update replaces the old pet text with the food-name preview")
equal(Suite.db.macroOwnership[pet.name], petBody, "GUI replacement records only confirmed saved text")
equal(gui.macroStatus.text:find("Saved in General macros", 1, true) ~= nil, true, "GUI replacement reports a visible save result")
local confirmedPet = Suite.db.macroOwnership[pet.name]
petNative.body = "/say Unsaved editor work"; MacroFrame:Show()
equal(macros:Save(pet), false, "explicit replacement still pauses for the open native editor")
equal(gui.macroStatus.textColor[1], 1, "open-editor failure is red")
equal(petNative.body, "/say Unsaved editor work", "open-editor text survives explicit replacement attempt")
MacroFrame:Hide(); SetCombat(true)
equal(macros:Save(pet), false, "explicit replacement still pauses in combat")
equal(gui.macroStatus.textColor[1], 1, "combat pause is red")
SetCombat(false)
Suite.db.macroOwnership[pet.name] = nil
equal(macros:Save(pet), false, "explicit replacement cannot take over an unowned same-name macro")
equal(petNative.body, "/say Unsaved editor work", "unowned General macro remains intact")
Suite.db.macroOwnership[pet.name], petNative.body = confirmedPet, petBody
gui:Select("overview")

bags = {}; Suite.db.macroUpdates = true; macros:Refresh()
equal(native[petIndex].body:find("/use ", 1, true), nil, "depleted pet food removes its item-use action while retaining care spells")
equal(macros.statuses[pet]:find("not carried", 1, true) ~= nil, true, "depleted food remains visible as a reminder after automatic refresh")
bags = { 113 }; macros:Refresh()
equal(macros.statuses[pet]:find("2 carried", 1, true) ~= nil, true, "restocking clears the depletion message through ordinary bag refresh")
local foodName = data[113].name; data[113].name = { secret = true }; macros:Refresh()
equal(native[petIndex].body, petBody, "unreadable carried names preserve pet text")
equal(macros:Generate(pet, macros.snapshot), nil, "unreadable carried metadata cannot establish depletion")
data[113].name = foodName
-- Use the game's per-item predicate, including ingredients; never infer diet
-- from an English food name or fall back to all carried items on unknown data.
bags = { 100, 100, 113, 105, 109 }
local dietSnapshot = supplies:Scan()
local dietChoices, dietNote = supplies:Choices(dietSnapshot, "hunterPet")
equal(#dietChoices, 2, "active pet food predicate removes potions and recipes from the picker")
equal(dietNote, nil, "complete accepted food data needs no diagnostic")
equal(dietChoices[1].id, 113, "no-use-spell ingredients remain eligible when the active pet accepts them")
equal(dietChoices[2].count, 4, "filtered choices preserve combined carried stack counts")
petFoods = { [100] = true }
equal(#supplies:Choices(dietSnapshot, "hunterPet"), 1, "switching pets immediately changes the allowed list")
local preservedPetText, incompatibleNote = macros:Generate(pet, dietSnapshot)
equal(preservedPetText, petBody, "switching to an incompatible diet retains the selected macro item")
equal(incompatibleNote:find("cannot eat", 1, true) ~= nil, true, "incompatible selected food gets a change-food reminder")
petFoods = { [113] = true }; gui.macroSelected = pet; menuChoices = {}; gui:ChooseMacroItem()
equal(#menuChoices, 1, "native menu contains only current-pet-compatible food")
local previousFood = pet.item
petFoods = { [100] = true }; menuChoices[1][2]()
equal(pet.item, previousFood, "stale menu selection cannot accept food after changing pets")
equal(macros.statuses[pet]:find("cannot eat", 1, true) ~= nil, true, "stale diet selection explains why it was rejected")
petExists = false
local noPetChoices, noPetNote = supplies:Choices(dietSnapshot, "hunterPet")
equal(#noPetChoices, 0, "no active pet produces no unfiltered fallback")
equal(noPetNote, "Call your pet to choose food it can eat.", "no-pet picker asks the player to summon a pet")
petExists = { secret = true }
equal(#supplies:Choices(dietSnapshot, "hunterPet"), 0, "secret pet identity suppresses food choices")
petExists = true
local nativeCanEat = C_PetInfo.CanPetEatItem
C_PetInfo.CanPetEatItem = nil
local unsupported, unsupportedNote = supplies:Choices(dietSnapshot, "hunterPet")
equal(#unsupported, 0, "missing pet food predicate never exposes all bag items")
equal(unsupportedNote:find("unavailable", 1, true) ~= nil, true, "missing native predicate explains unavailable filtering")
C_PetInfo.CanPetEatItem = function(id) return id == 113 and true or { secret = true } end
local partialChoices, partialNote = supplies:Choices(dietSnapshot, "hunterPet")
equal(#partialChoices, 1, "restricted predicate results omit only unconfirmed candidates")
equal(partialChoices[1].id, 113, "readable accepted food can remain visible amid unknown candidates")
equal(partialNote:find("unavailable", 1, true) ~= nil, true, "unknown candidate results disclose partial information")
C_PetInfo.CanPetEatItem = function() error("unavailable") end
equal(#supplies:Choices(dietSnapshot, "hunterPet"), 0, "native predicate failures never become accepted foods")
C_PetInfo.CanPetEatItem = function() return nil end
equal(#supplies:Choices(dietSnapshot, "hunterPet"), 0, "nil native predicate results are unknown")
C_PetInfo.CanPetEatItem, petFoods = nativeCanEat, {}
local emptyFoods, emptyFoodNote = supplies:Choices(dietSnapshot, "hunterPet")
equal(#emptyFoods, 0, "known mismatches produce an empty food list")
equal(emptyFoodNote, "No carried food matches your active pet.", "known empty diet choices are clearly distinguished from unavailable data")
equal(supplies:PetCanEat({ secret = true }), nil, "unreadable item IDs cannot reach the pet API")
equal(supplies:PetCanEat(-1), nil, "invalid item IDs cannot reach the pet API")
petFoods = { [100] = true, [113] = true }
SetCombat(true)
equal(supplies:PetCanEat(113), nil, "pet food selection stays paused in combat")
equal(#supplies:Choices(dietSnapshot, "hunterPet"), 0, "combat produces no actionable pet-food menu choices")
SetCombat(false)
macros:Cancel(); macros.events.OnEvent(macros.events, "UNIT_PET", "target")
equal(macros.timer, nil, "unrelated units do not queue pet-food refresh")
macros.statuses[pet] = "Suitable for the previous pet."
macros.events.OnEvent(macros.events, "UNIT_PET", "player")
equal(macros.timer ~= nil, true, "own pet changes queue a coalesced refresh")
equal(macros.statuses[pet], nil, "changing pets clears outdated suitability feedback even with automatic writes disabled")
macros:Cancel(); macros.events.OnEvent(macros.events, "UNIT_LEVEL", "pet")
equal(macros.timer ~= nil, true, "pet level changes refresh native food eligibility")
macros:Cancel()
spells[136] = { secret = true }
equal(macros:Generate(pet, supplies:Scan()), nil, "secret spell names never enter macro text")
spells[136] = string.rep("M", 100)
equal(macros:Generate(pet, supplies:Scan()), nil, "long localized spell names fail safely at the body limit")
spells[136] = "Heilendes Tier"
equal(macros:Generate(pet, supplies:Scan()):find("Heilendes Tier", 1, true) ~= nil, true, "generated spells use the client's localized names")
spells[136], spells[34477] = "Mend Pet", nil
equal(macros:Save(redirect), false, "missing spell metadata does not replace a saved macro")
equal(native[redirectIndex].body, savedRedirect, "missing spell lookup preserves old misdirection text")
spells[34477] = "Misdirection"
playerClass = "MAGE"; macros:Refresh(); gui:RefreshMacros()
equal(#macros:Entries(), 13, "Mage shows its own seven recipes while hiding retained Hunter recipes")
equal(gui.macroListScroll.suiteScrollBar:IsShown(), true, "Mage class recipes extend its list beyond the viewport")
equal(gui.macroListScroll.suiteOffset <= gui.macroListScroll.suiteMaximum, true, "class changes clamp the position to the new visible list")
equal(gui.macroListHeadings[2].label.text, "− Mage Macros", "class-filtered heading follows the current class")
equal(gui.macroSelected, alt.entries[1], "GUI selection cannot stay on an excluded class recipe")
equal(macros:Save(pet), false, "another class cannot explicitly rewrite a hunter macro")
equal(macros:Write(redirect, "/say changed", true), false, "write boundary rejects hidden class recipes")
equal(native[petIndex].body, petBody, "other-class refresh leaves the shared hunter macro unchanged")
playerClass = { secret = true }
equal(#macros:Entries(), 6, "unreadable class never exposes class-only entries")
local deferredClass = macros:Initialize(nil)
equal(#deferredClass.entries, 6, "unknown startup class creates only ordinary recipes")
playerClass = "HUNTER"; macros:SyncGeneral(); macros:SyncGeneral()
equal(#deferredClass.entries, 13, "late class availability adds each class recipe exactly once")
SetCombat(true)
equal(macros:Save(pet), false, "combat still blocks explicit class macro changes")
equal(native[petIndex].body, petBody, "combat cannot rewrite pet-care text")
SetCombat(false)
local limited = macros:Initialize(nil)
for i = 1, 9 do equal(macros:AddItem() ~= nil, true, "hunter retains each of the ten arbitrary item slots") end
gui.macroCollapsed["Item Macros"] = true; gui:RefreshMacros()
gui.macroAdd.OnClick()
equal(gui.macroCollapsed["Item Macros"], nil, "adding an item expands its collapsed category before revealing it")
equal(gui.macroSelected, limited.entries[23], "adding a custom item selects the new scroll-list entry")
equal(gui.macroListScroll.suiteOffset, gui.macroListScroll.suiteMaximum, "newly added items are revealed at the list bottom")
equal(gui.macroListHeadings[3].label.text, "− Item Macros", "custom item choices are grouped separately")
local selectedAtBottom = gui.macroSelected
gui:RefreshMacros()
equal(gui.macroSelected, selectedAtBottom, "ordinary refresh preserves the selected custom entry")
equal(gui.macroListScroll.suiteScrollBar.thumbTop, gui.macroListScroll.suiteScrollBar.travel, "ordinary refresh preserves the list bottom position")
local listHeight = gui.macroListContent.height
SetCombat(true); gui:RefreshMacros()
equal(gui.macroListContent.height, listHeight, "combat does not relayout list geometry")
equal(type(Suite.pending.macroListLayout), "function", "combat defers list layout through the existing queue")
SetCombat(false); Suite.pending.macroListLayout()
equal(Suite.pending.macroListLayout, nil, "deferred layout settles after combat")
equal(#limited.entries, 23, "class recipes do not reduce arbitrary item capacity")
equal(macros:AddItem(), nil, "hunter still enforces the ten-item cap")
gui.macroSelected = limited.entries[7]; gui:RefreshMacros()
equal(gui.macroChoose:IsShown(), false, "misdirection hides irrelevant item controls")
local fullListHeight, keptSelection, keptPreview = gui.macroListContent.height, gui.macroSelected, gui.macroPreviewBody
gui.macroListHeadings[1].OnClick()
equal(gui.macroListHeadings[1].label.text, "+ General", "collapsed category offers a visible expand indicator")
equal(gui.macroRows[1]:IsShown(), false, "collapsing General hides its recipe rows")
equal(gui.macroRows[7]:IsShown(), true, "collapsing General keeps Hunter recipes expanded")
equal(gui.macroListContent.height, fullListHeight - 312, "collapsed General removes its row space from the scroll range")
gui.macroListHeadings[2].OnClick()
equal(gui.macroRows[7]:IsShown(), false, "Hunter recipes collapse independently")
equal(gui.macroRows[14]:IsShown(), true, "custom items remain visible when other categories collapse")
equal(gui.macroSelected, keptSelection, "collapsing the selected category preserves the detail selection")
equal(gui.macroPreviewBody, keptPreview, "collapse does not change the generated macro preview")
equal(#limited.entries, 23, "collapse does not remove or change saved recipes")
gui.macroListHeadings[3].OnClick()
equal(gui.macroListScroll.suiteMaximum, 0, "collapsing all categories eliminates list overflow")
equal(gui.macroListScroll.suiteOffset, 0, "collapsing categories clamps obsolete scroll positions")
equal(gui.macroListScroll.suiteScrollBar:IsShown(), false, "all-collapsed categories hide the scrollbar")
equal(gui.macroListContent.height, 78, "the final collapsed header is fully included in the scroll child")
gui:RefreshMacros()
equal(gui.macroRows[1]:IsShown(), false, "ordinary refresh retains category collapse choices")
local collapsedHeight = gui.macroListContent.height
SetCombat(true); gui.macroListHeadings[1].OnClick()
equal(gui.macroListContent.height, collapsedHeight, "combat category clicks defer geometry changes")
SetCombat(false); Suite.pending.macroListLayout()
equal(gui.macroRows[1]:IsShown(), true, "deferred category expansion settles after combat")
equal(gui.macroRows[7]:IsShown(), false, "expanding General preserves the other category's collapsed state")
gui:Select("overview"); gui:Select("macros")
equal(gui.macroRows[7]:IsShown(), false, "category choices survive navigation within the login session")
gui.macroListHeadings[2].OnClick(); gui.macroListHeadings[3].OnClick()
equal(gui.macroListContent.height, fullListHeight, "expanding every category restores the full list range")
assert(loadfile("tests/class_macros_spec.lua"))(Suite, equal, SetCombat, function(value) playerClass = value end, spells, native)
assert(loadfile("tests/macro_use_spec.lua"))(Suite, equal, SetCombat, {
    native = function(value) if value then native = value end; return native end,
    bags = function(value) if value then bags = value end; return bags end,
    unavailable = function(value) unavailable = value end,
    loading = function(value) loadingBag = value end,
    level = function(value) local previous = level; if value then level = value end; return previous end,
    weapon = function(value, replace) if value or replace then weapon[16] = value end; return weapon[16] end,
})
assert(loadfile("tests/random_mount_spec.lua"))(Suite, equal, SetCombat, function() return native end)
-- Discard the unfinished choice directly from the list, before any native macro exists.
do
    local keptDB, keptOwnership = Suite.macroDB, Suite.db.macroOwnership
    Suite.db.macroOwnership = {}
    macros:Initialize(nil)
    local beforeCreate, beforeEdit = created, edited
    local recipeCount = #Suite.macroDB.entries
    local draft = macros:AddItem()
    gui.macroSelected = draft; gui:RefreshMacros()
    local row
    for _, candidate in ipairs(gui.macroRows) do if candidate.entry == draft then row = candidate; break end end
    equal(row.discard:IsShown(), true, "unfinished item macro has a visible list Discard action")
    equal(row.discard:GetParent(), row, "Discard stays inside the clipped item row")
    equal(row.discard:GetFrameLevel() > row:GetFrameLevel(), true, "Discard receives clicks above the selection row")
    equal(gui.macroRemove.label.text, "Discard draft", "draft detail action clearly explains removal")
    local serial = draft.serial
    SetCombat(true); gui:RefreshMacros()
    equal(row.discard:IsEnabled(), false, "discard action is disabled in combat")
    row.discard.OnClick()
    equal(gui.macroSelected, draft, "combat prevents draft removal even through the callback")
    SetCombat(false); gui:RefreshMacros()
    macros.statuses[draft], macros.statusErrors[draft] = "Choose an item", true
    row.discard.OnClick()
    equal(#Suite.macroDB.entries, recipeCount, "discard removes exactly the unfinished item choice")
    equal(gui.macroSelected.recipe, "food", "discarding selected draft returns to the first recipe")
    equal(Suite.macroDB.ignoredItems[serial], true, "discarded draft remains removed across reload initialization")
    equal(macros.statuses[draft], nil, "discard clears draft status")
    equal(macros.statusErrors[draft], nil, "discard clears draft error status")
    local restoredDrafts = macros:Initialize(Suite.macroDB)
    local found = false
    for _, record in ipairs(restoredDrafts.entries) do if record.serial == serial then found = true end end
    equal(found, false, "discarded draft does not return on reload")
    equal(created, beforeCreate, "discarding a draft never creates a game macro")
    equal(edited, beforeEdit, "discarding a draft never edits a game macro")
    draft = macros:AddItem(); gui.macroSelected = draft; gui:RefreshMacros()
    gui.macroRemove.OnClick()
    equal(gui.macroSelected.recipe, "food", "detail Discard draft uses the same removal action")
    draft = macros:AddItem(); gui.macroSelected = draft; gui:RefreshMacros()
    for _, candidate in ipairs(gui.macroRows) do if candidate.entry == draft then row = candidate; break end end
    gui.macroSelected = macros:Entries()[1]; gui:RefreshMacros()
    row.discard.OnClick()
    equal(gui.macroSelected.recipe, "food", "discarding another row preserves current selection")
    Suite.macroDB, Suite.db.macroOwnership = keptDB, keptOwnership
end
UnitClass, C_Spell, C_PetInfo, UnitExists, bags = oldUnitClass, oldSpellAPI, oldPetAPI, oldUnitExists, originalBags
native, Suite.db, Suite.macroDB = previousNative, previousDB, previousCharacter
macros.events.RegisterEvent, macros.events.UnregisterAllEvents = eventRegister, eventUnregister
macros:Cancel(); Flush()

