local _, Suite = ...
local Scoring = Suite.Scoring
Scoring.specs, Scoring.maxSpecs = {}, 4

-- Original preference starters, derived from Suite's existing roles. These are
-- editable through a custom copy, not simulation-calibrated optimal weights.
local function Add(class, slug, label, role, changes, melee, ranged, note)
    local profile = Suite.Copy(Scoring.presets[role])
    profile.id, profile.class, profile.label = "spec_" .. class:lower() .. "_" .. slug, class, label
    profile.help = note or "Spec starter · manual choice · customize a copy"
    local weights = profile.weights
    if role == "physical" then
        weights.HIT_RATING, weights.CRIT_RATING, weights.HASTE_RATING, weights.EXPERTISE_RATING = 1, 0.5, 0.5, 0.5
    elseif role == "caster" or role == "healer" then
        weights.SPELL_POWER, weights.SPELL_DAMAGE_DONE, weights.SPELL_HEALING_DONE = nil, nil, nil
        weights[role == "caster" and "SPELL_DAMAGE_TOTAL" or "HEALING_TOTAL"] = 1
        weights.CRIT_SPELL_RATING, weights.HASTE_SPELL_RATING = 0.5, 0.5
        if role == "caster" then weights.HIT_SPELL_RATING = 1 end
    elseif role == "tank" then
        weights.DODGE_RATING, weights.PARRY_RATING, weights.BLOCK_RATING, weights.BLOCK_VALUE, weights.HEALTH = 1, 1, 0.5, 0.25, 0.02
    end
    for key, value in pairs(changes or {}) do weights[key] = value end
    profile.meleeDPS, profile.rangedDPS = melee or 0, ranged or 0
    Scoring.specs[#Scoring.specs + 1] = profile
    return profile
end

Add("WARRIOR", "arms", "Arms", "physical", { STRENGTH = 1.25 }, 7)
Add("WARRIOR", "fury", "Fury", "physical", { HIT_RATING = 1.25 }, 7)
Add("WARRIOR", "protection", "Protection", "tank", { STRENGTH = 0.75 }, 1)
Add("PALADIN", "holy", "Holy", "healer", { INTELLECT = 1.25 })
Add("PALADIN", "protection", "Protection", "tank", { SPELL_DAMAGE_TOTAL = 0.5, HOLY_DAMAGE = 0.5 }, 1)
Add("PALADIN", "retribution", "Retribution", "physical", { STRENGTH = 1.25, SPELL_DAMAGE_TOTAL = 0.25, HOLY_DAMAGE = 0.25 }, 7)
local function Hunter(slug, label, changes)
    local profile = Add("HUNTER", slug, label, "physical", changes, 0, 7,
        "Ranged build · pet/talent scaling is not modeled")
    profile.weights.HIT_RATING, profile.weights.CRIT_RATING, profile.weights.HASTE_RATING, profile.weights.EXPERTISE_RATING = nil, nil, nil, nil
    profile.weights.RANGED_HIT_RATING, profile.weights.RANGED_CRIT_RATING, profile.weights.RANGED_HASTE_RATING = 1, 0.5, 0.5
end
Hunter("beastmastery", "Beast Mastery", { STRENGTH = 0, AGILITY = 1 })
Hunter("marksmanship", "Marksmanship", { STRENGTH = 0, AGILITY = 1.25 })
Hunter("survival", "Survival (ranged)", { STRENGTH = 0, AGILITY = 1.5 })
Add("ROGUE", "assassination", "Assassination", "physical", { STRENGTH = 0.5, AGILITY = 1.25 }, 7)
Add("ROGUE", "combat", "Combat", "physical", { STRENGTH = 0.5, HIT_RATING = 1.25 }, 7)
local daggers = Add("ROGUE", "daggers", "Combat Daggers", "physical", { STRENGTH = 0.5, AGILITY = 1.25 }, 7, 0,
    "Dagger main hand required · speed/poisons are not modeled")
daggers.mainHandSubclass = 15
Add("ROGUE", "subtlety", "Subtlety", "physical", { STRENGTH = 0.5, AGILITY = 1.5 }, 7)
Add("PRIEST", "discipline", "Discipline", "healer", { INTELLECT = 1.25, SPIRIT = 0.5 })
Add("PRIEST", "holy", "Holy", "healer", { SPIRIT = 1 })
Add("PRIEST", "shadow", "Shadow", "caster", { SHADOW_DAMAGE = 1, CRIT_SPELL_RATING = 0.25 }, 0, 1)
Add("SHAMAN", "elemental", "Elemental", "caster", { NATURE_DAMAGE = 1 })
Add("SHAMAN", "enhancement", "Enhancement", "physical", { STRENGTH = 1.25, SPELL_DAMAGE_TOTAL = 0.25, NATURE_DAMAGE = 0.25 }, 7)
Add("SHAMAN", "restoration", "Restoration", "healer", { MANA_REGENERATION = 1.25 })
Add("MAGE", "arcane", "Arcane", "caster", { ARCANE_DAMAGE = 1, INTELLECT = 1.25 })
Add("MAGE", "fire", "Fire", "caster", { FIRE_DAMAGE = 1, CRIT_SPELL_RATING = 0.75 })
Add("MAGE", "frost", "Frost", "caster", { FROST_DAMAGE = 1, CRIT_SPELL_RATING = 0.25 })
Add("WARLOCK", "affliction", "Affliction", "caster", { SHADOW_DAMAGE = 1, CRIT_SPELL_RATING = 0.25 })
Add("WARLOCK", "demonology", "Demonology", "caster", { SHADOW_DAMAGE = 0.5, FIRE_DAMAGE = 0.5, STAMINA = 0.5 })
Add("WARLOCK", "destruction", "Destruction", "caster", { SHADOW_DAMAGE = 0.5, FIRE_DAMAGE = 0.5, CRIT_SPELL_RATING = 0.75 })
Add("DRUID", "balance", "Balance", "caster", { ARCANE_DAMAGE = 0.5, NATURE_DAMAGE = 0.5 })
Add("DRUID", "feralcat", "Feral Cat", "physical", { AGILITY = 1.5 }, 0, 0,
    "Cat role · raw weapon DPS/form mechanics are not scored")
Add("DRUID", "feralbear", "Feral Bear", "tank", { AGILITY = 1, PARRY_RATING = 0, BLOCK_RATING = 0, BLOCK_VALUE = 0 }, 0, 0,
    "Bear role · raw weapon DPS/form mechanics are not scored")
Add("DRUID", "restoration", "Restoration", "healer", { SPIRIT = 1 })

function Scoring:Spec(id)
    if not Suite.IsReadable(id) or type(id) ~= "string" then return end
    for _, profile in ipairs(self.specs) do if profile.id == id and profile.class == self.class then return profile end end
end
