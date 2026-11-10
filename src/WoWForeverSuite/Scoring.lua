local _, Suite = ...
local Scoring = {}
Suite.Scoring = Scoring

local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and math.abs(value) < math.huge
end

-- These are deliberately simple, disclosed stat preferences, not class simulations.
-- Every starter values armor: 100 armor = 1 point (Tank retains 2 points).
-- Armor type remains hint-color guidance rather than an unconditional score bonus.
Scoring.order = { "balanced", "physical", "caster", "healer", "tank" }
Scoring.presets = {
    balanced = { label = "Balanced", meleeDPS = 1, rangedDPS = 1, weights = { STRENGTH = 1, AGILITY = 1, INTELLECT = 1, STAMINA = 0.5, SPIRIT = 0.25, ARMOR = 0.01 } },
    physical = { label = "Physical", meleeDPS = 7, rangedDPS = 7, weights = { STRENGTH = 1, AGILITY = 1, STAMINA = 0.25, ATTACK_POWER = 0.5, RANGED_ATTACK_POWER = 0.5, ARMOR = 0.01 } },
    caster = { label = "Caster", meleeDPS = 0, rangedDPS = 1, weights = { INTELLECT = 1, STAMINA = 0.25, SPIRIT = 0.25, SPELL_POWER = 1, SPELL_DAMAGE_DONE = 1, ARMOR = 0.01 } },
    healer = { label = "Healer", meleeDPS = 0, rangedDPS = 1, weights = { INTELLECT = 1, SPIRIT = 0.75, STAMINA = 0.25, SPELL_POWER = 1, SPELL_HEALING_DONE = 0.5, MANA_REGENERATION = 1, ARMOR = 0.01 } },
    tank = { label = "Tank", meleeDPS = 1, rangedDPS = 1, weights = { STAMINA = 1, STRENGTH = 0.5, AGILITY = 0.5, ARMOR = 0.02, DEFENSE_SKILL_RATING = 1 } },
}

-- Character-local scoring preferences and optional custom profiles.
Scoring.stats = {
    { key = "STRENGTH", label = "Strength" }, { key = "AGILITY", label = "Agility" },
    { key = "INTELLECT", label = "Intellect" }, { key = "STAMINA", label = "Stamina" },
    { key = "SPIRIT", label = "Spirit" }, { key = "ARMOR", label = "Armor" },
    { key = "ATTACK_POWER", label = "Attack power" }, { key = "RANGED_ATTACK_POWER", label = "Ranged attack power" },
    { key = "SPELL_POWER", label = "Spell power" }, { key = "SPELL_DAMAGE_DONE", label = "Spell damage" },
    { key = "SPELL_HEALING_DONE", label = "Healing power" }, { key = "MANA_REGENERATION", label = "Mana per 5 seconds" },
    { key = "DEFENSE_SKILL_RATING", label = "Defense rating" },
    { key = "HIT_RATING", label = "Physical hit rating" }, { key = "HIT_SPELL_RATING", label = "Spell hit rating" },
    { key = "CRIT_RATING", label = "Physical crit rating" }, { key = "CRIT_SPELL_RATING", label = "Spell crit rating" },
    { key = "HASTE_RATING", label = "Physical haste rating" }, { key = "HASTE_SPELL_RATING", label = "Spell haste rating" },
    { key = "RANGED_HIT_RATING", label = "Ranged hit rating" }, { key = "RANGED_CRIT_RATING", label = "Ranged crit rating" },
    { key = "RANGED_HASTE_RATING", label = "Ranged haste rating" },
    { key = "EXPERTISE_RATING", label = "Expertise rating" }, { key = "DODGE_RATING", label = "Dodge rating" },
    { key = "PARRY_RATING", label = "Parry rating" }, { key = "BLOCK_RATING", label = "Block rating" },
    { key = "BLOCK_VALUE", label = "Block value" }, { key = "ARMOR_PENETRATION_RATING", label = "Armor penetration rating" },
    { key = "SPELL_PENETRATION", label = "Spell penetration" }, { key = "HEALTH", label = "Health" },
    { key = "MANA", label = "Mana" }, { key = "HEALTH_REGEN", label = "Health per 5 seconds" },
    { key = "SPELL_DAMAGE_TOTAL", label = "Effective spell damage" }, { key = "HEALING_TOTAL", label = "Effective healing" },
    { key = "HOLY_DAMAGE", label = "Holy-only spell damage" }, { key = "FIRE_DAMAGE", label = "Fire-only spell damage" },
    { key = "NATURE_DAMAGE", label = "Nature-only spell damage" }, { key = "FROST_DAMAGE", label = "Frost-only spell damage" },
    { key = "SHADOW_DAMAGE", label = "Shadow-only spell damage" }, { key = "ARCANE_DAMAGE", label = "Arcane-only spell damage" },
    { key = "HOLY_RESISTANCE", label = "Holy resistance" }, { key = "FIRE_RESISTANCE", label = "Fire resistance" },
    { key = "NATURE_RESISTANCE", label = "Nature resistance" }, { key = "FROST_RESISTANCE", label = "Frost resistance" },
    { key = "SHADOW_RESISTANCE", label = "Shadow resistance" }, { key = "ARCANE_RESISTANCE", label = "Arcane resistance" },
}
Scoring.maxProfiles = 8
local function Table(value) return Suite.IsReadable(value) and type(value) == "table" end
local function Text(value, maximum)
    return Suite.IsReadable(value) and type(value) == "string" and #value > 0 and #value <= maximum
        and not value:find("[%c|]")
end
local function Weight(value) return Number(value) and value >= 0 and value <= 1000 end
local function ProfileID(value)
    return Text(value, 24) and value:match("^custom%d+$") ~= nil
end

function Scoring:ValidateProfile(value)
    if not Table(value) or not Text(value.label, 48) or not Table(value.weights)
        or not Weight(value.meleeDPS) or not Weight(value.rangedDPS) then return end
    local label = value.label:match("^%s*(.-)%s*$")
    if label == "" then return end
    local profile = { label = label, meleeDPS = value.meleeDPS, rangedDPS = value.rangedDPS, weights = {} }
    if Suite.IsReadable(value.mainHandSubclass) and value.mainHandSubclass == 15 then profile.mainHandSubclass = 15 end
    local positive = profile.meleeDPS > 0 or profile.rangedDPS > 0
    for _, stat in ipairs(self.stats) do
        local weight = value.weights[stat.key]
        if not Suite.IsReadable(weight) or weight ~= nil and not Weight(weight) then return end
        if weight ~= nil then profile.weights[stat.key] = weight end
        if weight and weight > 0 then positive = true end
    end
    -- Effective totals are alternatives to the old independent spell fields.
    -- Old profiles have no total weights and keep their exact arithmetic.
    local weights = profile.weights
    if (weights.SPELL_DAMAGE_TOTAL or 0) > 0 and ((weights.SPELL_POWER or 0) > 0 or (weights.SPELL_DAMAGE_DONE or 0) > 0)
        or (weights.HEALING_TOTAL or 0) > 0 and ((weights.SPELL_POWER or 0) > 0 or (weights.SPELL_HEALING_DONE or 0) > 0) then
        return nil, "Use effective spell/healing totals or the overlapping legacy spell fields, not both."
    end
    if not positive then return end
    return profile
end

function Scoring:InitializeCharacter(saved, legacy)
    self:Automatic()
    saved = Table(saved) and saved or {}
    local state = { schema = 1, active = "automatic", preference = "stats", details = false, profiles = {}, nextID = 1 }
    local active = Suite.IsReadable(saved.active) and saved.active or nil
    if Text(active, 32) and (active == "automatic" or self.presets[active] or self:Spec(active) or ProfileID(active)) then state.active = active end
    if Suite.IsReadable(saved.preference) and saved.preference == "ilevel" then state.preference = "ilevel" end
    if Suite.IsReadable(saved.details) and saved.details == true then state.details = true end
    if Suite.IsReadable(saved.schema) and saved.schema == nil and Table(legacy) then
        if Text(legacy.scorePreset, 24) and self.presets[legacy.scorePreset] then state.active = legacy.scorePreset end
        if Suite.IsReadable(legacy.upgradePreference) and legacy.upgradePreference == "ilevel" then state.preference = "ilevel" end
    end
    if Table(saved.profiles) then
        for index = 1, self.maxProfiles do
            local entry = saved.profiles[index]
            if Table(entry) and ProfileID(entry.id) then
                local profile = self:ValidateProfile(entry)
                local serial = tonumber(entry.id:match("^custom(%d+)$"))
                if profile and Number(serial) and serial >= 1 and serial <= 1000000 and serial == math.floor(serial) then
                    local duplicate = false
                    for _, other in ipairs(state.profiles) do
                        if other.id == entry.id or other.label:lower() == profile.label:lower() then duplicate = true end
                    end
                    if not duplicate then
                        profile.id = entry.id
                        state.profiles[#state.profiles + 1] = profile
                        state.nextID = math.max(state.nextID, serial + 1)
                    end
                end
            end
        end
    end
    if Number(saved.nextID) and saved.nextID >= 1 and saved.nextID <= 1000001 and saved.nextID == math.floor(saved.nextID) then
        state.nextID = math.max(state.nextID, saved.nextID)
    end
    local found = state.active == "automatic" or self.presets[state.active] ~= nil or self:Spec(state.active) ~= nil
    for _, profile in ipairs(state.profiles) do if profile.id == state.active then found = true end end
    if not found then state.active = "automatic" end
    self.character, self.owner = state, Suite.db
    self:Automatic()
    return state
end

function Scoring:State()
    if Suite.db and self.owner == Suite.db then return self.character end
end

function Scoring:Automatic()
    if not self.class and not InCombatLockdown() and type(UnitClass) == "function" then
        local ok, _, class = pcall(UnitClass, "player")
        if ok and Text(class, 24) then self.class = class end
    end
    local class = self.class
    if self.automaticProfile and self.automaticClass == class then return self.automaticProfile end
    local starter = ({ MAGE = "caster", WARLOCK = "caster", PRIEST = "caster", HUNTER = "physical",
        ROGUE = "physical", WARRIOR = "physical" })[class] or "balanced"
    local profile = Suite.Copy(self.presets[starter])
    profile.label = "Automatic · " .. profile.label
    -- Hunters value the ranged weapon's DPS; melee classes use ranged items for bonuses.
    if class == "HUNTER" then profile.meleeDPS = 0
    elseif class == "ROGUE" or class == "WARRIOR" then profile.rangedDPS = 0 end
    self.automaticProfile, self.automaticClass = profile, class
    return profile
end

function Scoring:ActiveID()
    local state = self:State()
    return state and state.active or Suite.db and Suite.db.scorePreset or "balanced"
end

function Scoring:Resolve(value)
    if Table(value) and Table(value.weights) then return value end
    if not Text(value, 32) then return end
    if value == "automatic" then return self:Automatic() end
    if self.presets[value] then return self.presets[value] end
    if self:Spec(value) then return self:Spec(value) end
    local state = self:State()
    if state then for _, profile in ipairs(state.profiles) do if profile.id == value then return profile end end end
end

function Scoring:Profile() return self:Resolve(self:ActiveID()) or self.presets.balanced end

function Scoring:List()
    local list = { { id = "automatic", label = "Automatic", help = "Class-aware leveling starter. No editing required." } }
    self:Automatic()
    for _, profile in ipairs(self.specs or {}) do
        if profile.class == self.class then list[#list + 1] = { id = profile.id, label = profile.label, help = profile.help } end
    end
    local descriptions = { balanced = "A general mix of primary attributes and survivability.",
        physical = "Physical damage: attributes, attack power and weapon DPS.", caster = "Spell damage: intellect, spell bonuses and some recovery.",
        healer = "Healing: intellect, spirit, healing bonuses and mana recovery.", tank = "Survivability: stamina, armor, defense and attributes." }
    for _, id in ipairs(self.order) do list[#list + 1] = { id = id, label = self.presets[id].label, help = descriptions[id] } end
    local state = self:State()
    if state then for _, profile in ipairs(state.profiles) do
        list[#list + 1] = { id = profile.id, label = profile.label, help = "Custom weights · this character only" }
    end end
    return list
end

function Scoring:Changed()
    if Suite.Items and Suite.db then Suite.Items:Refresh() end
end

function Scoring:SetProfile(id)
    if InCombatLockdown() or not Text(id, 32) or not self:Resolve(id) then return false end
    local state = self:State()
    if state then state.active = id
    elseif self.presets[id] then Suite.db.scorePreset = id
    else return false end
    self:Changed()
    return true
end

function Scoring:SetPreference(value)
    if not Suite.IsReadable(value) or (value ~= "stats" and value ~= "ilevel") then return false end
    local state = self:State()
    if state then state.preference = value else Suite.db.upgradePreference = value end
    self:Changed()
    return true
end

function Scoring:SaveProfile(value, id)
    local state = self:State()
    if not state then return nil, "Character settings are not ready." end
    local profile, message = self:ValidateProfile(value)
    if not profile then return nil, message or "Use a name and weights from 0 to 1000, with at least one positive weight." end
    local replace
    if id ~= nil then
        if not ProfileID(id) then return nil, "Built-in presets cannot be overwritten. Create a custom copy." end
        for index, other in ipairs(state.profiles) do if other.id == id then replace = index end end
        if not replace then return nil, "That custom profile is no longer available." end
    end
    local unchangedName = replace and state.profiles[replace].label:lower() == profile.label:lower()
    for _, entry in ipairs(self:List()) do
        if not unchangedName and entry.id ~= id and entry.label:lower() == profile.label:lower() then return nil, "Choose a different profile name." end
    end
    if not replace and (#state.profiles >= self.maxProfiles or state.nextID > 1000000) then
        return nil, "This character already has eight custom profiles. Edit or remove one first."
    end
    profile.id = id or ("custom" .. state.nextID)
    if not replace then state.nextID = state.nextID + 1 end
    state.profiles[replace or #state.profiles + 1] = profile
    state.active = profile.id
    self:Changed()
    return profile.id
end

function Scoring:DeleteProfile(id)
    local state = self:State()
    if not state or not ProfileID(id) then return false end
    for index, profile in ipairs(state.profiles) do if profile.id == id then
        table.remove(state.profiles, index)
        if state.active == id then state.active = "automatic" end
        self:Changed()
        return true
    end end
    return false
end

function Scoring:Value(stats, key)
    if not Table(stats) then return end
    if Suite.GearStats then return Suite.GearStats:Value(stats, key) end
    local value = stats["ITEM_MOD_" .. key .. "_SHORT"]
    if key == "ARMOR" then
        value = stats.RESISTANCE0_NAME
        if not Suite.IsReadable(value) then return end
        if value == nil then value = stats.ITEM_MOD_ARMOR_SHORT end
    end
    if not Suite.IsReadable(value) or value ~= nil and not Number(value) then return end
    return value or 0
end

function Scoring:Terms(stats, selected, info, slot)
    local profile = self:Resolve(selected)
    if not profile or not Table(stats) then return end
    local rows = {}
    for _, stat in ipairs(self.stats) do
        local weight = profile.weights[stat.key]
        if not Suite.IsReadable(weight) or weight ~= nil and not Weight(weight) then return end
        if weight and weight > 0 then
            local value = self:Value(stats, stat.key)
            if value == nil or not Number(value * weight) then return end
            rows[stat.key] = { label = stat.label, value = value, weight = weight, points = value * weight }
        end
    end
    local kind = info and self.WeaponKind(info.equipLoc)
    if kind == "melee" or kind == "ranged" then
        local weight = kind == "ranged" and profile.rangedDPS or profile.meleeDPS
        if not Weight(weight) then return end
        if weight > 0 then
            local dps = self:Value(stats, "DAMAGE_PER_SECOND")
            if not Number(dps) or dps <= 0 then return end
            local effective = dps * (slot == 17 and 0.5 or 1)
            rows.weaponDPS = { label = kind == "ranged" and "Ranged DPS" or "Weapon DPS", value = effective,
                weight = weight, points = effective * weight }
        end
    end
    return rows
end

function Scoring:Breakdown(candidate, removed)
    local result, rows = {}, {}
    for key, term in pairs(candidate or {}) do
        rows[key] = { key = key, label = term.label, value = term.value, weight = term.weight, points = term.points }
    end
    for _, terms in ipairs(removed or {}) do for key, term in pairs(terms) do
        local row = rows[key] or { key = key, label = term.label, value = 0, weight = term.weight, points = 0 }
        rows[key] = row
        row.value, row.points = row.value - term.value, row.points - term.points
    end end
    for _, row in pairs(rows) do if math.abs(row.points) > 0.000001 then result[#result + 1] = row end end
    table.sort(result, function(a, b)
        if math.abs(a.points) ~= math.abs(b.points) then return math.abs(a.points) > math.abs(b.points) end
        return a.key < b.key
    end)
    return result
end

function Scoring.FormatUpgrade(delta, baseline)
    if not Number(delta) then return "--" end
    if Number(baseline) and baseline > 0 then
        local percent = delta / baseline * 100
        if Number(percent) then
            if percent > 0 and percent < 0.1 then return "+<0.1%" end
            return string.format(math.abs(percent) < 1 and "%+.1f%%" or "%+.0f%%", percent)
        end
    end
    return Scoring.Format(delta, true) .. " pts"
end

function Scoring.Format(value, signed)
    if not Number(value) then return "--" end
    local magnitude = math.abs(value)
    local decimals = magnitude ~= 0 and magnitude < 0.001 and 6 or 3
    local text = string.format((signed and "%+." or "%.") .. decimals .. "f", value)
    return (text:gsub("(%..-)0+$", "%1"):gsub("%.$", ".0"))
end

local melee = { INVTYPE_WEAPON = true, INVTYPE_WEAPONMAINHAND = true, INVTYPE_WEAPONOFFHAND = true, INVTYPE_2HWEAPON = true }
local ranged = { INVTYPE_RANGED = true, INVTYPE_RANGEDRIGHT = true, INVTYPE_THROWN = true }

function Scoring.Preference(db, legacyOnly)
    if not Suite.IsReadable(db) or type(db) ~= "table" then return "stats" end
    local state = not legacyOnly and db == Suite.db and Scoring:State() or nil
    local value = state and state.preference or db.upgradePreference
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
    local profile = Scoring:Resolve(presetName)
    if not profile then return nil end
    if not Suite.IsReadable(profile.mainHandSubclass) then return nil end
    if profile.mainHandSubclass and slot == 16 then
        if not Number(info.subclassID) or info.subclassID ~= profile.mainHandSubclass then return nil end
    end
    local score = Scoring.Score(stats, presetName)
    if not Number(score) then return nil end
    if kind == "melee" or kind == "ranged" then
        local preset = profile
        local weight = kind == "ranged" and preset.rangedDPS or preset.meleeDPS
        if not Weight(weight) then return nil end
        -- Unknown/restricted DPS must never become an assumed zero. Caster/healer
        -- melee preferences intentionally assign it zero and only score bonuses.
        if weight > 0 then
            local dps = Scoring:Value(stats, "DAMAGE_PER_SECOND")
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

function Scoring.Score(stats, selected)
    if not Table(stats) then return nil end
    local profile = Scoring:Resolve(selected)
    if not profile then return nil end
    local score = 0
    for _, stat in ipairs(Scoring.stats) do
        local weight = profile.weights[stat.key]
        if not Suite.IsReadable(weight) or weight ~= nil and not Weight(weight) then return nil end
        if weight and weight > 0 then
            local value = Scoring:Value(stats, stat.key)
            if value == nil then return nil end
            score = score + value * weight
        end
    end
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
