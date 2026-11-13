local Suite, equal, data, food, water, SetInventory = ...
local supplies, macros = Suite.MacroItems, Suite.Macros
-- Fact groups are public Wowhead observations, not native API class claims.
local audit = assert(loadfile("tests/fixtures/forever_food_audit.lua"))()
local savedBags, savedLevel = SetInventory({}, 60)
local candidates, seen, count = {}, {}, 0
for _, id in ipairs(Suite.MacroFoodCandidates) do
    equal(candidates[id], nil, "food candidate IDs are unique")
    candidates[id] = true
end
equal(#Suite.MacroFoodCandidates, 345, "ship all 317 listed and 28 direct-use supplemental candidates")
local excluded = { [238641] = true, [238642] = true, [273137] = true }
for _, group in ipairs(audit) do
    for _, id in ipairs(group.ids) do
        count = count + 1
        equal(seen[id], nil, "review facts contain no duplicate IDs")
        seen[id] = true
        equal(candidates[id] == true, not excluded[id], "register every reviewed direct-use candidate")
        local previous = data[id]
        local health, mana, syntax = group.health, group.mana, group.syntax
        local description = "Use: "
        if syntax == "special" then description = description .. "Eat me."
        elseif syntax == "noUse" then description = "No item use effect."
        elseif syntax == "percent" then
            description = description .. "Restores " .. health .. "% of your health"
                .. (mana > 0 and " and mana" or "") .. " per second for 25 sec."
        elseif syntax == "directPercent" then
            description = description .. "Restores 100% health and 100% Mana over 20 sec."
        elseif syntax == "range" then
            local amount = health > 0 and health or mana
            description = description .. "Restores " .. (amount * 0.875) .. " to " .. (amount * 1.125)
                .. (health > 0 and " health." or " mana.")
        else
            if health > 0 then
                description = description .. (syntax == "heal" and "Heals " or "Restores ") .. health
                    .. (syntax == "heal" and " damage." or " health")
            end
            if mana > 0 then description = description .. (health > 0 and " and " or "Restores ") .. mana .. " mana" end
            description = description .. " over 30 sec."
        end
        if group.seated then description = description .. " Must remain seated while " .. (health > 0 and "eating." or "drinking.") end
        if group.xp > 0 then description = description .. " You become well fed. Additionally, experience gained from kills is increased by " .. group.xp .. "%." end
        if id == 238641 or id == 238642 then description = "Use: Serve a delicious feast. Food " .. description end
        data[id] = { name = "Audit item " .. id, class = id == 273137 and 4 or 0,
            sub = 5, required = group.required,
            description = description, noUse = syntax == "noUse" }
        SetInventory({ id }, 60)
        local checked = supplies:Scan()
        local isFood = health > 0 and not excluded[id]
        local isWater = mana > 0 and not excluded[id]
        equal(checked.best.food ~= nil, isFood, "reviewed food eligibility: " .. id)
        equal(checked.best.water ~= nil, isWater, "reviewed drink eligibility: " .. id)
        if excluded[id] then
            equal(#supplies:Choices(checked, "food"), 0, "indirect food effects stay out of recovery picker")
            equal(#supplies:Choices(checked, "water"), 0, "equipped gear and deployed feasts stay out of drink picker")
            equal(#supplies:Choices(checked, "item"), 1, "explicit general item recipes retain indirect use actions")
        end
        if isFood then
            equal(macros:Generate(food, checked), "#showtooltip [nocombat] item:" .. id .. "\n/use [nocombat] item:" .. id,
                "reviewed restorative food generates its own action: " .. id)
        end
        if isWater then
            equal(macros:Generate(water, checked), "#showtooltip [nocombat] item:" .. id .. "\n/use [nocombat] item:" .. id,
                "reviewed restorative drink generates its own action: " .. id)
        end
        if checked.byID[id] then
            equal(checked.byID[id].health, (syntax == "percent" or syntax == "directPercent") and 0 or health,
                "parse observed health without reading player health: " .. id)
            equal(checked.byID[id].mana, (syntax == "percent" or syntax == "directPercent") and 0 or mana,
                "preserve observed decimal mana: " .. id)
        end
        -- Deliberate category drift is a substitute scenario, not observed API data.
        if group.seated and not excluded[id] then
            data[id].sub = 8
            checked = supplies:Scan()
            equal(checked.best.food ~= nil, isFood, "listed food category drift: " .. id)
            equal(checked.best.water ~= nil, isWater, "listed drink category drift: " .. id)
            equal(#supplies:Choices(checked, isFood and "food" or "water"), 1, "listed category fallback reaches picker: " .. id)
        end
        if group.required > 0 then
            SetInventory({ id }, group.required - 1)
            equal(supplies:Scan().best.food, nil, "reviewed food respects level requirement: " .. id)
            equal(supplies:Scan().best.water, nil, "reviewed drink respects level requirement: " .. id)
        end
        data[id] = previous
    end
end
equal(count, 348, "exercise all listing and supplemental tooltip facts")

-- Wording and rejection cases independent of the grouped fact fixtures.
local id, old = 282018, data[282018]
data[id] = { name = "Restorative Bread", sub = 8, description = "" }
SetInventory({ id }, 60)
for _, text in ipairs({
    "Restores 100% health and 100% Mana over 20 sec. Must remain seated while drinking.",
    "Restores 3% of your maximum health and mana per second. Must remain seated while eating.",
    "Restores 3% of your mana and health per second. Must remain seated while eating.",
}) do
    data[id].description = text
    local checked = supplies:Scan()
    equal(checked.best.food.id, id, "percentage variants identify health restoration")
    equal(checked.best.water.id, id, "percentage variants identify mana restoration")
    equal(checked.best.food.health, 0, "percentages never become absolute player-health estimates")
end
for _, text in ipairs({
    "Restores 0% health and 0% mana. Must remain seated while eating.",
    "Increases health by 10% of your health. Must remain seated while eating.",
    "Must remain seated while eating. You become well fed.",
    "Restores 100 health.", -- A changed subclass needs the native eating instruction.
}) do
    data[id].description = text
    local checked = supplies:Scan()
    equal(checked.best.food, nil, "candidate ID cannot manufacture recovery from unrelated text")
    equal(checked.best.water, nil, "candidate ID cannot manufacture mana restoration")
end
data[id].description = "Restores 100 health. Must remain seated while eating."
data[id].class = 4
equal(supplies:Scan().best.food, nil, "known ID cannot classify equipped gear as automatic food")
data[id].class, data[id].noUse = 0, true
equal(supplies:Scan().best.food, nil, "known ID still requires a native item-use action")
data[id] = old
SetInventory(savedBags, savedLevel)
