local Suite, equal, Frame, Combat, events = ...
local scoring, adapter, gear, gui = Suite.Scoring, Suite.GearStats, Suite.GearSettings, Suite.GUI
local saved = { db = Suite.db, character = scoring.character, owner = scoring.owner, class = scoring.class,
    automatic = scoring.automaticProfile, automaticClass = scoring.automaticClass, page = gui.page, shown = gui.frame:IsShown(), pending = Suite.pending }
local names = { "C_Item", "C_TooltipInfo", "C_PlayerInfo", "GetLocale", "UnitClass", "UnitLevel", "GetInventoryItemLink", "CanDualWield", "WoWForeverSuiteDB", "WoWForeverSuiteCharDB" }
local globals = {}; for _, name in ipairs(names) do globals[name] = _G[name] end
Combat(false); Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
UnitClass = function() return "Warrior", "WARRIOR" end
scoring.class, scoring.automaticProfile = "WARRIOR", nil

-- A populated legacy character survives migration and repeated reloads exactly.
local legacy = { schema = 1, active = "custom7", preference = "ilevel", details = true, nextID = 42, profiles = {} }
for index = 1, 8 do
    local profile = { id = "custom" .. index, label = index == 7 and "Fury" or "Kept " .. index,
        meleeDPS = index / 10000000, rangedDPS = index / 1000, weights = {} }
    for position = 1, 13 do profile.weights[scoring.stats[position].key] = (index + position) / 10000000 end
    profile.weights.ARMOR = 0
    legacy.profiles[index] = profile
end
for cycle = 1, 3 do
    local state = scoring:InitializeCharacter(Suite.Copy(legacy))
    equal(state.active, "custom7", "migration keeps active custom identity")
    equal(state.preference, "ilevel", "migration preserves item-level preference")
    equal(state.details, true, "migration preserves tooltip detail preference")
    equal(state.nextID, 42, "migration preserves the next custom identity")
    equal(#state.profiles, 8, "migration preserves all eight custom profiles")
    for index, profile in ipairs(state.profiles) do
        local original = legacy.profiles[index]
        equal(profile.id, original.id, "migration keeps stable custom IDs")
        equal(profile.label, original.label, "new spec names never rename existing custom profiles")
        equal(profile.meleeDPS, original.meleeDPS, "migration retains exact melee coefficients")
        equal(profile.rangedDPS, original.rangedDPS, "migration retains exact ranged coefficients")
        for key, value in pairs(original.weights) do equal(profile.weights[key], value, "migration retains every legacy coefficient including zero") end
        for key in pairs(profile.weights) do equal(original.weights[key] ~= nil, true, "migration never inserts new positive weights") end
    end
    legacy = Suite.Copy(state)
end
gui.frame:Show(); gui:Select("items"); gear:Open("editor"); gear:Edit()
equal(gear:Save(), true, "unchanged high-precision legacy coefficients remain editable")
for key, value in pairs(legacy.profiles[7].weights) do equal(scoring:Profile().weights[key], value, "no-op editor save preserves exact custom weights") end
equal(scoring:Profile().meleeDPS, legacy.profiles[7].meleeDPS, "editor preserves a sub-three-decimal DPS coefficient")
gear:Dismiss()

-- Expanded editor controls remain reachable in the actual settings viewport.
gui:Select("items"); gear:Open("editor"); gear:Edit(); gui:ScrollTo(0)
local lastField = gear.fields[#gear.fields]
lastField.input.OnEditFocusGained()
equal(gui.scrollOffset > 0, true, "focusing a lower weight scrolls it into view")
local focusedOffset = gui.scrollOffset
Combat(true); gear.fields[1].input.OnEditFocusGained()
equal(gui.scrollOffset, focusedOffset, "combat focus cannot move the settings viewport")
Combat(false); gear:Dismiss()

-- Every explicit spec is selectable only for its class and survives initialization.
local counts = {}; equal(#scoring.specs, 29, "all nine classes have their 29 explicit spec/role choices")
for _, spec in ipairs(scoring.specs) do
    scoring.class, scoring.automaticProfile = spec.class, nil
    local state = scoring:InitializeCharacter(nil)
    counts[spec.class] = (counts[spec.class] or 0) + 1
    equal(scoring:ValidateProfile(spec) ~= nil, true, "spec starter has bounded valid weights")
    equal(scoring:SetProfile(spec.id), true, "matching class can select its intended spec")
    equal(scoring:Profile(), spec, "selection resolves the named spec rather than a broad role")
    state = scoring:InitializeCharacter(Suite.Copy(state))
    equal(state.active, spec.id, "explicit spec survives reload")
    local offered = false
    for _, entry in ipairs(scoring:List()) do if entry.id == spec.id then offered = true end end
    equal(offered, true, "class spec appears in the actual picker list")
    Combat(true); equal(scoring:SetProfile("tank"), false, "combat cannot change active comparisons"); Combat(false)
    equal(state.active, spec.id, "refused combat choice preserves the spec")
end
equal(counts.DRUID, 4, "Cat and Bear are independent manual roles")
equal(counts.ROGUE, 4, "Combat Daggers remains a distinct choice")
scoring.class, scoring.automaticProfile = "MAGE", nil
scoring:InitializeCharacter(nil)
equal(scoring:SetProfile("spec_warrior_fury"), false, "another class's spec cannot be selected")
equal(scoring:InitializeCharacter({ schema = 1, active = "spec_warrior_fury" }).active, "automatic", "foreign-class saved spec falls back safely")
equal(scoring:InitializeCharacter({ schema = 1, active = { secret = true } }).active, "automatic", "restricted spec identities cannot become lookup keys")

local hidden = setmetatable({ secret = true }, { __index = function() error("restricted stat indexed") end })
local function Profile(weights) return { label = "Stat probe", weights = weights, meleeDPS = 0, rangedDPS = 0 } end
for _, case in ipairs({
    { "HIT_RATING", "ITEM_MOD_HIT_RATING_SHORT" }, { "HIT_SPELL_RATING", "ITEM_MOD_HIT_SPELL_RATING_SHORT" },
    { "CRIT_RATING", "ITEM_MOD_CRIT_RATING_SHORT" }, { "CRIT_SPELL_RATING", "ITEM_MOD_CRIT_SPELL_RATING_SHORT" },
    { "HASTE_RATING", "ITEM_MOD_HASTE_RATING_SHORT" }, { "HASTE_SPELL_RATING", "ITEM_MOD_HASTE_SPELL_RATING_SHORT" },
    { "RANGED_HIT_RATING", "ITEM_MOD_HIT_RANGED_RATING_SHORT" }, { "RANGED_CRIT_RATING", "ITEM_MOD_CRIT_RANGED_RATING_SHORT" },
    { "RANGED_HASTE_RATING", "ITEM_MOD_HASTE_RANGED_RATING_SHORT" }, { "EXPERTISE_RATING", "ITEM_MOD_EXPERTISE_RATING_SHORT" },
    { "DODGE_RATING", "ITEM_MOD_DODGE_RATING_SHORT" }, { "PARRY_RATING", "ITEM_MOD_PARRY_RATING_SHORT" },
    { "BLOCK_RATING", "ITEM_MOD_BLOCK_RATING_SHORT" }, { "BLOCK_VALUE", "ITEM_MOD_BLOCK_VALUE_SHORT" },
    { "ARMOR_PENETRATION_RATING", "ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT" }, { "SPELL_PENETRATION", "ITEM_MOD_SPELL_PENETRATION_SHORT" },
    { "HEALTH", "ITEM_MOD_HEALTH_SHORT" }, { "MANA", "ITEM_MOD_MANA_SHORT" }, { "HEALTH_REGEN", "ITEM_MOD_HEALTH_REGEN_SHORT" },
    { "HOLY_RESISTANCE", "RESISTANCE1_NAME" }, { "FIRE_RESISTANCE", "RESISTANCE2_NAME" }, { "NATURE_RESISTANCE", "RESISTANCE3_NAME" },
    { "FROST_RESISTANCE", "RESISTANCE4_NAME" }, { "SHADOW_RESISTANCE", "RESISTANCE5_NAME" }, { "ARCANE_RESISTANCE", "RESISTANCE6_NAME" },
}) do
    local profile = Profile({ [case[1]] = 2 })
    equal(scoring.Score({ [case[2]] = 7 }, profile), 14, "new stat uses its raw native units")
    equal(scoring.Score({}, profile), 0, "absent optional stat remains zero")
    equal(scoring.Score({ [case[2]] = hidden }, profile), nil, "unreadable new stat suppresses scoring")
end
equal(scoring.Score({ ITEM_MOD_HIT_RATING_SHORT = 7, ITEM_MOD_HIT_MELEE_RATING_SHORT = 7 }, Profile({ HIT_RATING = 2 })), 14, "generic and melee aliases are not added twice")
equal(scoring.Score({ ITEM_MOD_HIT_RATING_SHORT = 7 }, Profile({ HIT_SPELL_RATING = 2 })), 14, "spell hit can use a generic rating field")
equal(scoring.Score({ ITEM_MOD_CRIT_RATING_SHORT = 7, ITEM_MOD_CRIT_SPELL_RATING_SHORT = hidden }, Profile({ CRIT_SPELL_RATING = 2 })), nil, "readable generic fallback never bypasses a hidden spell rating")
equal(scoring.Score({ ITEM_MOD_SPELL_POWER_SHORT = 10, ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 10 }, Profile({ SPELL_DAMAGE_TOTAL = 1 })), 10, "effective spell damage does not duplicate shared fields")
equal(scoring.Score({ ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 10 }, Profile({ SPELL_DAMAGE_TOTAL = 1 })), 10, "effective damage accepts the legacy native shape")
equal(scoring.Score({ ITEM_MOD_SPELL_HEALING_DONE_SHORT = 20 }, Profile({ HEALING_TOTAL = 1 })), 20, "effective healing accepts a healing-specific amount")
equal(scoring.Score({ ITEM_MOD_SPELL_POWER_SHORT = 10, ITEM_MOD_SPELL_HEALING_DONE_SHORT = 20 }, Profile({ HEALING_TOTAL = 1 })), nil, "unequal spell/heal alternatives cannot be guessed as additive or overlapping totals")
equal(scoring.Score({ ITEM_MOD_HIT_RATING_SHORT = 7, ITEM_MOD_HIT_MELEE_RATING_SHORT = 9 }, Profile({ HIT_RATING = 2 })), nil, "ambiguous rating alternatives suppress partial scores")
equal(scoring.Score({ ITEM_MOD_SPELL_POWER_SHORT = 10, ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 10 }, Profile({ SPELL_POWER = 2, SPELL_DAMAGE_DONE = 3 })), 50, "legacy custom spell fields retain their exact independent arithmetic")
equal(scoring:ValidateProfile(Profile({ SPELL_DAMAGE_TOTAL = 1, SPELL_POWER = 1 })), nil, "new profiles cannot mix effective and overlapping legacy damage weights")

-- School bonuses come from static item tooltip data, not invented API fields.
local raw, tooltip, calls = { ITEM_MOD_SPELL_POWER_SHORT = 10, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 5 }, { lines = {} }, 0
C_Item = { GetItemStats = function() return raw end }
GetLocale = function() return "enUS" end
C_TooltipInfo = { GetHyperlink = function() calls = calls + 1; return tooltip end }
for _, school in ipairs({ "Holy", "Fire", "Nature", "Frost", "Shadow", "Arcane" }) do
    local profile = Profile({ [school:upper() .. "_DAMAGE"] = 2, SPELL_DAMAGE_TOTAL = 1 })
    tooltip.lines = { { leftText = "Test item" }, { leftText = "|cff00ff00Equip: Increases damage done by " .. school .. " spells and effects by up to 7.|r" },
        { leftText = "Use: Increases damage done by " .. school .. " spells and effects by up to 99." },
        { leftText = "(2) Set: Increases damage done by " .. school .. " spells and effects by up to 99." } }
    local stats = adapter:Read("item:1", profile)
    equal(scoring.Score(stats, profile), 24, "static school damage is independent of generic spell damage")
    local terms = scoring:Terms(stats, profile)
    equal(terms[school:upper() .. "_DAMAGE"].points, 14, "school breakdown reconciles with score")
    profile.meleeDPS = 2
    equal(scoring.WeaponScore({ equipLoc = "INVTYPE_WEAPON" }, stats, profile, "stats", 16), 34, "school adapter preserves native weapon DPS")
end
local fire = Profile({ FIRE_DAMAGE = 1 })
tooltip.lines = { { leftText = "No school bonus" } }
equal(scoring.Score(adapter:Read("item:1", fire), fire), 0, "complete tooltip without school bonuses records zero")
tooltip.lines = { { leftText = "Equip: Increases your Fire damage by 7." } }
equal(adapter:Read("item:1", fire), nil, "unrecognized school damage wording is unknown rather than zero")
tooltip.lines = {}; equal(adapter:Read("item:1", fire), nil, "empty async tooltip is unavailable rather than zero")
tooltip.lines = { { leftText = hidden } }; equal(adapter:Read("item:1", fire), nil, "secret tooltip text is never parsed")
tooltip = hidden; equal(adapter:Read("item:1", fire), nil, "restricted tooltip root is not indexed")
GetLocale = function() return "deDE" end; equal(adapter:Read("item:1", fire), nil, "unsupported school language never fabricates a bonus")
local beforeCalls = calls
equal(adapter:Read("item:1", Profile({ HIT_RATING = 1 })), raw, "ordinary rating profiles do not need English tooltip parsing")
equal(calls, beforeCalls, "ordinary/legacy profiles do not request extra tooltips")
raw = hidden; equal(adapter:Read("item:1", fire), nil, "restricted native stats cannot be recovered through tooltip text")

-- Exercise icon, tooltip and breakdown consumers against the same native adapter.
local equipment = { [1] = "old" }
local records = {
    old = { stats = { ITEM_MOD_STRENGTH_SHORT = 10 }, school = 0 },
    new = { stats = { ITEM_MOD_STRENGTH_SHORT = 10, ITEM_MOD_HIT_RATING_SHORT = 5 }, school = 3 },
}
C_Item = {
    GetItemInfo = function(link) if records[link] then return link, link, 2, 20, 1, "Armor", "", 1, "INVTYPE_HEAD", 1, 0, 4, 4 end end,
    GetDetailedItemLevelInfo = function() return 20 end,
    IsUsableItem = function() return true end,
    GetItemStats = function(link) return records[link] and records[link].stats end,
}
C_PlayerInfo = nil; UnitLevel = function() return 60 end
GetInventoryItemLink = function(_, slot) return equipment[slot] end
GetLocale = function() return "enUS" end
UnitClass = function() return "Warrior", "WARRIOR" end
scoring.class, scoring.automaticProfile = "WARRIOR", nil; scoring:InitializeCharacter(nil)
scoring:SetProfile("spec_warrior_fury"); Suite.db.upgradeHints = true
local delta, detail = Suite.Items:UpgradeDelta("new", true)
equal(delta, 6.25, "real gear comparison includes the selected spec's hit weight")
equal(detail.breakdown[1].key, "HIT_RATING", "tooltip explains the new weighted stat")
local sum = 0; for _, row in ipairs(detail.breakdown) do sum = sum + row.points end
equal(sum, delta, "new stat breakdown reconciles with the real upgrade delta")
local button, record = Frame(), {}; button.GetItemLink = function() return "new" end
Suite.Items:Update(button, record); equal(record.arrow.text, "+", "new stat improvements reach real bag markers")
local tip = Frame(); Suite.Tooltips:Item(tip, { hyperlink = "new" })
equal(tip.lines[1][1], "Possible stat upgrade · +63% (Fury)", "tooltip percentage uses the same spec and rating score as the marker")

UnitClass = function() return "Mage", "MAGE" end
scoring.class, scoring.automaticProfile = "MAGE", nil; scoring:InitializeCharacter(nil); scoring:SetProfile("spec_mage_fire")
records.old.stats, records.new.stats = { ITEM_MOD_SPELL_POWER_SHORT = 10 }, { ITEM_MOD_SPELL_POWER_SHORT = 10 }
C_TooltipInfo = { GetHyperlink = function(link)
    return { lines = { { leftText = "Test item" }, { leftText = "Equip: Increases damage done by Fire spells and effects by up to " .. records[link].school .. "." } } }
end }
delta, detail = Suite.Items:UpgradeDelta("new", true)
equal(delta, 3, "real spec comparison includes static school damage")
equal(detail.breakdown[1].key, "FIRE_DAMAGE", "real school tooltip explains its contribution")
C_TooltipInfo.GetHyperlink = function() return nil end
equal(Suite.Items:UpgradeDelta("new", true), nil, "unavailable school data suppresses partial real gear advice")
Suite.Items:Update(button, record); equal(record.arrow.text, "", "async school data clears a stale upgrade marker")
scoring:SetPreference("ilevel")
C_Item.GetDetailedItemLevelInfo = function(link) return link == "new" and 21 or 20 end
equal(Suite.Items:UpgradeDelta("new", true), 1, "item-level mode remains independent of unavailable school data")

scoring.class, scoring.automaticProfile = "ROGUE", nil; scoring:InitializeCharacter(nil)
local daggers = scoring:Spec("spec_rogue_daggers")
equal(scoring.WeaponScore({ equipLoc = "INVTYPE_WEAPON", subclassID = 7 }, { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 5 }, daggers, "stats", 16), nil, "dagger spec never treats a sword main hand as a modeled upgrade")
equal(scoring.WeaponScore({ equipLoc = "INVTYPE_WEAPON", subclassID = 15 }, { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 5 }, daggers, "stats", 16) ~= nil, true, "dagger spec accepts a dagger main hand")
scoring:SetProfile(daggers.id); gui:Select("items"); gear:Open("editor"); gear:Copy()
equal(gear:Save(), true, "spec starter can be copied into independent custom weights")
equal(scoring:Profile().mainHandSubclass, 15, "saving a dagger copy preserves its weapon restriction")
gear:Dismiss()

-- Actual SavedVariables startup retains the custom root when other modules initialize.
local runtime = { leveling = Suite.Leveling.db, training = Suite.Training.db, supplies = Suite.SupplyChecklist.db,
    history = Suite.ChatHistory.db, guide = Suite.TalentPlanner.guideDB, macros = Suite.macroDB, loaded = Suite.loadedSavedVariables }
WoWForeverSuiteDB = {}; WoWForeverSuiteCharDB = { scoring = Suite.Copy(legacy) }
events.OnEvent(events, "ADDON_LOADED", "WoWForeverSuite")
equal(WoWForeverSuiteCharDB.scoring.active, "custom7", "real startup keeps the active legacy custom profile")
equal(WoWForeverSuiteCharDB.scoring.profiles[7].weights.INTELLECT, legacy.profiles[7].weights.INTELLECT, "real startup keeps precise saved weights")
Suite.Leveling.db, Suite.Training.db, Suite.SupplyChecklist.db = runtime.leveling, runtime.training, runtime.supplies
Suite.ChatHistory.db, Suite.TalentPlanner.guideDB, Suite.macroDB, Suite.loadedSavedVariables = runtime.history, runtime.guide, runtime.macros, runtime.loaded
for _, name in ipairs(names) do _G[name] = globals[name] end
Suite.db, Suite.pending = saved.db, saved.pending
scoring.character, scoring.owner, scoring.class = saved.character, saved.owner, saved.class
scoring.automaticProfile, scoring.automaticClass = saved.automatic, saved.automaticClass
gear:Dismiss(); gui:Select(saved.page or "overview"); gui.frame:SetShown(saved.shown)
