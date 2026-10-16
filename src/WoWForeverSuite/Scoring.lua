local _, Suite = ...
local Scoring = {}
Suite.Scoring = Scoring

local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and math.abs(value) < math.huge
end

-- These are deliberately simple, disclosed stat preferences, not class simulations.
Scoring.order = { "balanced", "physical", "caster", "healer", "tank" }
Scoring.presets = {
    balanced = { label = "Balanced", meleeDPS = 1, rangedDPS = 1, weights = { STRENGTH = 1, AGILITY = 1, INTELLECT = 1, STAMINA = 0.5, SPIRIT = 0.25 } },
    physical = { label = "Physical", meleeDPS = 7, rangedDPS = 7, weights = { STRENGTH = 1, AGILITY = 1, STAMINA = 0.25, ATTACK_POWER = 0.5, RANGED_ATTACK_POWER = 0.5 } },
    caster = { label = "Caster", meleeDPS = 0, rangedDPS = 1, weights = { INTELLECT = 1, STAMINA = 0.25, SPIRIT = 0.25, SPELL_POWER = 1, SPELL_DAMAGE_DONE = 1 } },
    healer = { label = "Healer", meleeDPS = 0, rangedDPS = 1, weights = { INTELLECT = 1, SPIRIT = 0.75, STAMINA = 0.25, SPELL_POWER = 1, SPELL_HEALING_DONE = 0.5, MANA_REGENERATION = 1 } },
    tank = { label = "Tank", meleeDPS = 1, rangedDPS = 1, weights = { STAMINA = 1, STRENGTH = 0.5, AGILITY = 0.5, ARMOR = 0.02, DEFENSE_SKILL_RATING = 1 } },
}

local melee = { INVTYPE_WEAPON = true, INVTYPE_WEAPONMAINHAND = true, INVTYPE_WEAPONOFFHAND = true, INVTYPE_2HWEAPON = true }
local ranged = { INVTYPE_RANGED = true, INVTYPE_RANGEDRIGHT = true, INVTYPE_THROWN = true }

function Scoring.Preference(db)
    if not Suite.IsReadable(db) or type(db) ~= "table" then return "stats" end
    local value = db.upgradePreference
    return Suite.IsReadable(value) and value == "ilevel" and "ilevel" or "stats"
end

function Scoring.WeaponKind(equipLoc)
    if not Suite.IsReadable(equipLoc) or type(equipLoc) ~= "string" then return nil end
    if melee[equipLoc] then return "melee" end
    if ranged[equipLoc] then return "ranged" end
    if equipLoc == "INVTYPE_SHIELD" or equipLoc == "INVTYPE_HOLDABLE" then return "offhand" end
    if equipLoc == "INVTYPE_RELIC" then return "relic" end
end

-- Compare complete occupied-hand contributions. A two-hander contributes to both
-- level slots, but its stats/DPS only once. Off-hand base DPS has a disclosed 0.5
-- factor; procs, speed-specific abilities, talents and hit penalties are unmodeled.
function Scoring.WeaponScore(info, stats, presetName, preference, slot)
    if not Suite.IsReadable(info) or type(info) ~= "table" then return nil end
    if not Suite.IsReadable(preference) or (preference ~= "stats" and preference ~= "ilevel")
        or not Number(slot) or (slot ~= 16 and slot ~= 17 and slot ~= 18) then return nil end
    local kind = Scoring.WeaponKind(info.equipLoc)
    if not kind then return nil end
    if preference == "ilevel" then
        if not Number(info.level) or info.level <= 0 then return nil end
        return (slot == 18 or info.equipLoc == "INVTYPE_2HWEAPON") and info.level or info.level / 2
    end
    if not Suite.IsReadable(presetName) or type(presetName) ~= "string" then return nil end
    local score = Scoring.Score(stats, presetName)
    if not Number(score) then return nil end
    if kind == "melee" or kind == "ranged" then
        local preset = Scoring.presets[presetName] or Scoring.presets.balanced
        local weight = kind == "ranged" and preset.rangedDPS or preset.meleeDPS
        -- Unknown/restricted DPS must never become an assumed zero. Caster/healer
        -- melee preferences intentionally assign it zero and only score bonuses.
        local dps = stats.ITEM_MOD_DAMAGE_PER_SECOND_SHORT
        if not Suite.IsReadable(dps) then return nil end
        if weight > 0 then
            if not Number(dps) or dps <= 0 then return nil end
            score = score + dps * weight * (slot == 17 and 0.5 or 1)
        end
    end
    return Number(score) and score or nil
end
Scoring.slots = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 },
    INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 },
    INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 },
    INVTYPE_HAND = { 10 }, INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 },
    INVTYPE_CLOAK = { 15 },
}

function Scoring.Score(stats, presetName)
    if not Suite.IsReadable(stats) or type(stats) ~= "table" or not Suite.IsReadable(presetName) then return nil end
    local preset = Scoring.presets[presetName] or Scoring.presets.balanced
    local score = 0
    for name, weight in pairs(preset.weights) do
        local value = stats["ITEM_MOD_" .. name .. "_SHORT"]
        if name == "ARMOR" then
            value = stats.RESISTANCE0_NAME
            if not Suite.IsReadable(value) then return nil end
            if value == nil then value = stats.ITEM_MOD_ARMOR_SHORT end
        end
        if not Suite.IsReadable(value) or value ~= nil and not Number(value) then return nil end
        if Number(value) then
            score = score + value * weight
        end
    end
    -- Only the listed stats contribute. A loaded item with none of them scores zero.
    return Number(score) and score or nil
end

function Scoring.Compare(candidate, equippedScores)
    if not Number(candidate) or not Suite.IsReadable(equippedScores) or type(equippedScores) ~= "table"
        or #equippedScores == 0 then return nil end
    local lowest
    for _, score in ipairs(equippedScores) do
        if not Number(score) then return nil end
        lowest = lowest and math.min(lowest, score) or score
    end
    if candidate <= lowest + 0.001 then return nil end
    local delta = candidate - lowest
    return Number(delta) and delta or nil
end
