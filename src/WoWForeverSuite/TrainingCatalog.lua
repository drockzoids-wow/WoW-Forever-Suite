local _, Suite = ...
local Catalog = {}
Suite.TrainingCatalog = Catalog

local function Read(value, kind) return Suite.IsReadable(value) and type(value) == kind end
local function Call(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Text(value) return Read(value, "string") and #value > 0 and not value:find("[%c|]") end
function Catalog:Class()
    if type(UnitClass) ~= "function" then return end
    local ok, _, token = pcall(UnitClass, "player")
    if ok and Read(token, "string") and Suite.TrainingCatalogData[token] then return token end
end
function Catalog:Race()
    if type(UnitRace) ~= "function" then return end
    local ok, _, _, id = pcall(UnitRace, "player")
    if ok and Read(id, "number") and id > 0 and id % 1 == 0 then return id end
end
function Catalog:Known(id)
    local result = Call(C_SpellBook and C_SpellBook.IsSpellKnown, id)
    if Read(result, "boolean") then return result end
end
function Catalog:WeaponState(id)
    local token = self:Class()
    local classes = Suite.TrainingWeaponClasses[id]
    if not token or not classes then return "Eligibility unknown" end
    if not classes[token] then return "Not for your class" end
    local known = self:Known(id)
    if known == true then return "Already trained" end
    if known == false then return "Class eligible" end
    return "Known skills unavailable"
end
function Catalog:Matches(entry, faction, race)
    if entry.faction and entry.faction ~= faction then return false end
    if entry.race and entry.race ~= race then return false end
    if entry.races then
        for _, id in ipairs(entry.races) do if id == race then return true end end
        return false
    end
    return true
end
local function Key(name, rank) return name .. "\031" .. (rank or "") end
function Catalog:Snapshot(saved, level, recorded)
    local token = self:Class()
    if not token then return saved end
    local faction, race = Call(UnitFactionGroup, "player"), self:Race()
    local result = { catalog = true, rows = {}, partial = false, at = saved and saved.at,
        trainer = saved and saved.trainer, level = level }
    local knownIDs, entries, names = {}, {}, {}
    for _, entry in ipairs(Suite.TrainingCatalogData[token]) do
        entries[entry.id] = entry
        names[entry.name] = (names[entry.name] or 0) + 1
        if not entry.pet then knownIDs[entry.id] = self:Known(entry.id) end
    end
    -- Higher learned ranks replace earlier spellbook entries on some clients.
    local function Earlier(entry)
        for _, id in ipairs(entry.requiredIds or {}) do
            local previous = entries[id]
            if previous and previous.name == entry.name and knownIDs[id] ~= true then
                knownIDs[id] = true; Earlier(previous)
            end
        end
    end
    for id, known in pairs(knownIDs) do if known then Earlier(entries[id]) end end
    local function Knows(id)
        if knownIDs[id] ~= nil then return knownIDs[id] end
        return self:Known(id)
    end
    local observations, seen = {}, {}
    for _, row in ipairs(saved and saved.rows or {}) do observations[Key(row.name, row.rank)] = row end
    for _, entry in ipairs(Suite.TrainingCatalogData[token]) do
        if self:Matches(entry, faction, race) then
            local name = Call(C_Spell and C_Spell.GetSpellName, entry.id)
            local rank = Call(C_Spell and C_Spell.GetSpellSubtext, entry.id)
            name = Text(name) and name or entry.name
            rank = Text(rank) and rank or entry.rank
            local key = Key(name, rank)
            local observed = observations[key]
            if not observed and names[entry.name] == 1 then observed = observations[Key(name, nil)] end
            seen[key] = true
            if observed then seen[Key(observed.name, observed.rank)] = true end
            local known = not entry.pet and Knows(entry.id)
            local requirement, ready = nil, true
            if entry.skills then
                requirement, ready = "Skill requirement", false
            elseif entry.pet then
                requirement, ready = "Pet trainer", false
            elseif entry.requiredTalentId and Knows(entry.requiredTalentId) ~= true then
                requirement, ready = "Requires talent", false
            end
            for _, id in ipairs(entry.requiredIds or {}) do
                if Knows(id) ~= true then requirement, ready = requirement or "Requires earlier skill", false end
            end
            local state = known == true and "used" or "unavailable"
            if known == false and ready and Read(level, "number") and entry.level <= level then state = "available" end
            local price = recorded and observed and observed.cost or entry.cost
            result.rows[#result.rows + 1] = { spellID = entry.id, name = name, rank = rank, level = entry.level,
                baseCost = entry.cost, cost = price, state = state, otherReady = ready,
                requirement = requirement, priceLabel = recorded and observed and observed.cost and "Recorded price" or "Base price",
                catalog = true, requirements = entry, knownUnknown = known == nil, icon = observed and observed.icon }
        end
    end
    -- A trainer can add hotfixed offerings without replacing the rest of the catalog.
    for key, observed in pairs(observations) do
        if not seen[key] then
            local row = {}; for field, value in pairs(observed) do row[field] = value end
            row.cost = recorded and observed.cost or nil
            row.priceLabel = recorded and "Recorded price" or "Base price unknown"
            row.catalog = true
            result.rows[#result.rows + 1] = row
        end
    end
    table.sort(result.rows, function(a, b)
        if (a.level or 1000) ~= (b.level or 1000) then return (a.level or 1000) < (b.level or 1000) end
        if a.name ~= b.name then return a.name < b.name end
        return (a.rank or "") < (b.rank or "")
    end)
    return result
end
function Catalog:Details(row)
    local lines, entry = {}, row.requirements
    if row.baseCost then lines[#lines + 1] = string.format("Base cost: %dg %ds %dc", math.floor(row.baseCost / 10000), math.floor(row.baseCost / 100) % 100, row.baseCost % 100) end
    if row.level then lines[#lines + 1] = "Required level: " .. row.level end
    local function Name(id)
        local name = Call(C_Spell and C_Spell.GetSpellName, id)
        for _, entries in pairs(Suite.TrainingCatalogData) do
            for _, spell in ipairs(entries) do if spell.id == id then return (Text(name) and name or spell.name) .. (spell.rank and " · " .. spell.rank or "") end end
        end
        if Text(name) then return name end
        return "Spell " .. id
    end
    if entry then
        if entry.pet then lines[#lines + 1] = "Learn this pet skill from a pet trainer." end
        if entry.requiredTalentId then lines[#lines + 1] = "Talent: " .. Name(entry.requiredTalentId) end
        for _, id in ipairs(entry.requiredIds or {}) do lines[#lines + 1] = "Earlier skill: " .. Name(id) end
        for _, skill in ipairs(entry.skills or {}) do lines[#lines + 1] = (skill.skill == 40 and "Poisons" or "Skill " .. skill.skill) .. ": " .. skill.level end
    end
    lines[#lines + 1] = "Catalog prices exclude discounts. Confirm current availability at the trainer."
    return lines
end
function Catalog:WeaponGroups(training, recorded)
    local faction = training:PlayerFaction()
    if not faction then return { { title = "Weapon trainers", rows = {}, snapshot = { unavailable = true } } } end
    local names = training:WeaponNames()
    for _, skill in ipairs(Suite.WeaponTraining.skills) do
        if not names[skill[2]] then names[skill[2]] = skill[1] end
    end
    local labels = {}; for _, skill in ipairs(Suite.WeaponTraining.skills) do labels[skill[1]] = skill[2] end
    local groups, seen = {}, {}
    for _, trainer in ipairs(Suite.WeaponTraining.trainers) do
        if trainer.faction == faction then
            local saved
            for _, visit in ipairs(training.db and training.db.weapons or {}) do
                if visit.trainer == trainer.name and training:WeaponFaction(visit) == faction then saved = visit end
            end
            local offers = {}; for _, row in ipairs(saved and saved.rows or {}) do
                local id = names[row.name]; if id then offers[id] = row end
            end
            local group = { title = trainer.name, rows = {}, snapshot = { trainer = trainer.name, place = trainer.place,
                faction = faction, reference = true, catalogWeapons = true } }
            local included = {}
            local function Add(id)
                if included[id] then return end
                included[id] = true
                local observed, base = offers[id], id == 200 and 10000 or 1000
                local state = self:WeaponState(id)
                group.rows[#group.rows + 1] = { name = observed and observed.name or labels[id], weaponID = id,
                    level = id == 200 and 20 or 1, cost = recorded and observed and observed.cost or base,
                    baseCost = base, priceLabel = recorded and observed and observed.cost and "Recorded price" or "Base price",
                    state = state == "Already trained" and "used" or "reference" }
            end
            for _, id in ipairs(trainer.skills) do Add(id) end
            for id in pairs(offers) do Add(id) end
            groups[#groups + 1], seen[trainer.name] = group, true
        end
    end
    for _, saved in ipairs(training.db and training.db.weapons or {}) do
        if not seen[saved.trainer] and training:WeaponFaction(saved) == faction then
            local rows = {}
            for _, observed in ipairs(saved.rows) do
                local row = {}; for field, value in pairs(observed) do row[field] = value end
                row.cost = recorded and observed.cost or nil
                row.priceLabel = recorded and "Recorded price" or "Base price unknown"
                rows[#rows + 1] = row
            end
            local snapshot = {}; for field, value in pairs(saved) do snapshot[field] = value end
            snapshot.partial = not recorded or saved.partial
            groups[#groups + 1] = { title = saved.trainer, rows = rows, snapshot = snapshot }
        end
    end
    return groups
end
function Catalog:Groups(snapshot, level, allLevels)
    if allLevels then return { { title = "All training · Levels 1–60", rows = snapshot.rows } } end
    local groups = { { title = "Ready to review", rows = {} } }
    local levels, other, known = {}, { title = "Other requirements", rows = {} }, { title = "Already trained", rows = {} }
    for _, row in ipairs(snapshot.rows) do
        local group
        if row.state == "used" then group = known
        elseif row.level and row.level > (level or 0) then
            levels[row.level] = levels[row.level] or { title = "Level " .. row.level, rows = {} }
            group = levels[row.level]
        elseif row.state == "available" then group = groups[1]
        else group = other end
        group.rows[#group.rows + 1] = row
    end
    for required = 1, 60 do if levels[required] then groups[#groups + 1] = levels[required] end end
    -- Preserve newly observed levels outside the bundled 1–60 catalog as requirements.
    for required, group in pairs(levels) do if required > 60 then for _, row in ipairs(group.rows) do other.rows[#other.rows + 1] = row end end end
    if #other.rows > 0 then groups[#groups + 1] = other end
    if #known.rows > 0 then groups[#groups + 1] = known end
    return groups
end
