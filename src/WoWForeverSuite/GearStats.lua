local _, Suite = ...
local Stats = {}
Suite.GearStats = Stats

local function Table(value) return Suite.IsReadable(value) and type(value) == "table" end
local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and math.abs(value) < math.huge
end
local schools = { HOLY = 1, FIRE = 2, NATURE = 3, FROST = 4, SHADOW = 5, ARCANE = 6 }
local aliases = {
    ARMOR = { "RESISTANCE0_NAME", "ITEM_MOD_ARMOR_SHORT" },
    HIT_RATING = { "ITEM_MOD_HIT_RATING_SHORT", "ITEM_MOD_HIT_MELEE_RATING_SHORT" },
    CRIT_RATING = { "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_CRIT_MELEE_RATING_SHORT" },
    HASTE_RATING = { "ITEM_MOD_HASTE_RATING_SHORT", "ITEM_MOD_HASTE_MELEE_RATING_SHORT" },
    HIT_SPELL_RATING = { "ITEM_MOD_HIT_SPELL_RATING_SHORT", "ITEM_MOD_HIT_RATING_SHORT" },
    CRIT_SPELL_RATING = { "ITEM_MOD_CRIT_SPELL_RATING_SHORT", "ITEM_MOD_CRIT_RATING_SHORT" },
    HASTE_SPELL_RATING = { "ITEM_MOD_HASTE_SPELL_RATING_SHORT", "ITEM_MOD_HASTE_RATING_SHORT" },
    RANGED_HIT_RATING = { "ITEM_MOD_HIT_RANGED_RATING_SHORT", "ITEM_MOD_HIT_RATING_SHORT" },
    RANGED_CRIT_RATING = { "ITEM_MOD_CRIT_RANGED_RATING_SHORT", "ITEM_MOD_CRIT_RATING_SHORT" },
    RANGED_HASTE_RATING = { "ITEM_MOD_HASTE_RANGED_RATING_SHORT", "ITEM_MOD_HASTE_RATING_SHORT" },
    -- Ordered alternatives, never an addition of potentially overlapping fields.
    SPELL_DAMAGE_TOTAL = { "ITEM_MOD_SPELL_POWER_SHORT", "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT" },
    HEALING_TOTAL = { "ITEM_MOD_SPELL_HEALING_DONE_SHORT", "ITEM_MOD_SPELL_POWER_SHORT" },
}

function Stats:Value(stats, key)
    if not Table(stats) then return end
    local damageSchool = key:match("^(%u+)_DAMAGE$")
    if damageSchool and schools[damageSchool] then
        if not Table(stats.foreverSuiteSchools) then return end
        local value = stats.foreverSuiteSchools[damageSchool]
        return Number(value) and value or nil
    end
    local native = stats.foreverSuiteNative
    if not Suite.IsReadable(native) then return end
    if native ~= nil then if not Table(native) then return end; stats = native end
    local school = key:match("^(%u+)_RESISTANCE$")
    local names = aliases[key]
    if school and schools[school] then names = { "RESISTANCE" .. schools[school] .. "_NAME" } end
    names = names or { "ITEM_MOD_" .. key .. "_SHORT" }
    local first
    for _, name in ipairs(names) do
        local value = stats[name]
        if not Suite.IsReadable(value) or value ~= nil and not Number(value) then return end
        -- Without native evidence, unequal alternatives could be additive or
        -- overlapping totals. Do not guess. Preserve legacy armor precedence.
        if aliases[key] and key ~= "ARMOR" and first ~= nil and value ~= nil and first ~= value then return end
        if first == nil and value ~= nil then first = value end
    end
    return first or 0
end

function Stats:Read(link, profile)
    if not Suite.IsReadable(link) or type(link) ~= "string" or not Table(profile) or not Table(profile.weights)
        or not C_Item or type(C_Item.GetItemStats) ~= "function" then return end
    local ok, raw = pcall(C_Item.GetItemStats, link)
    if not ok or not Table(raw) then return end
    local needed = false
    for school in pairs(schools) do
        local weight = profile.weights[school .. "_DAMAGE"]
        if not Suite.IsReadable(weight) then return end
        if Number(weight) and weight > 0 then needed = true end
    end
    if not needed then return raw end
    -- School-specific static equip bonuses are not documented GetItemStats fields.
    -- Parse only complete, exact English static lines, never Use/proc/set text.
    local localeOK, locale = false, nil
    if type(GetLocale) == "function" then localeOK, locale = pcall(GetLocale) end
    if not localeOK or not Suite.IsReadable(locale) or (locale ~= "enUS" and locale ~= "enGB")
        or not C_TooltipInfo or type(C_TooltipInfo.GetHyperlink) ~= "function" then return end
    local success, data = pcall(C_TooltipInfo.GetHyperlink, link)
    if not success or not Table(data) or not Table(data.lines) or #data.lines == 0 or #data.lines > 256 then return end
    local values = {}
    for school in pairs(schools) do values[school] = 0 end
    for _, line in ipairs(data.lines) do
        if not Table(line) then return end
        for _, field in ipairs({ "leftText", "rightText" }) do
            local text = line[field]
            if not Suite.IsReadable(text) or text ~= nil and type(text) ~= "string" then return end
            if text then
                text = text:gsub("|cn[%w_]+:", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                    :gsub("%s+", " "):match("^%s*(.-)%s*$")
                local school, amount = text:match("^Equip: Increases damage done by (%a+) spells and effects by up to (%d+)%.?$")
                if not school then school, amount = text:match("^Equip: Increases damage done by (%a+) spells and effects by (%d+)%.?$") end
                if school then
                    school, amount = school:upper(), tonumber(amount)
                    if schools[school] and Number(amount) then values[school] = values[school] + amount end
                elseif text:match("^Equip:") and text:lower():find("damage", 1, true) then
                    -- An unfamiliar school-damage sentence is unknown, not zero.
                    local lower = text:lower()
                    for name in pairs(schools) do if lower:find("%f[%a]" .. name:lower() .. "%f[%A]") then return end end
                end
            end
        end
    end
    return { foreverSuiteNative = raw, foreverSuiteSchools = values }
end
