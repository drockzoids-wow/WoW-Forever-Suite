local Suite, equal, SetCombat, SetClass, spells, native = ...
local macros, gui = Suite.Macros, Suite.GUI
local saved = { db = Suite.macroDB, ownership = Suite.db.macroOwnership, updates = Suite.db.macroUpdates,
    api = C_Spell, selected = gui.macroSelected, collapsed = gui.macroCollapsed, snapshot = macros.snapshot }
local originalSpells = {};for id, value in pairs(spells) do originalSpells[id] = value end
local cases = {
    { "DRUID", "druidInnervate", 29166, "Innervate", "[@mouseover,help,nodead][help,nodead][@player]" },
    { "DRUID", "druidRebirth", 20484, "Rebirth", "[@mouseover,help,dead][help,dead]" },
    { "MAGE", "mageCounterspell", 2139, "Counterspell", "[@mouseover,harm,nodead][harm,nodead]", "stop" },
    { "MAGE", "magePolymorph", 118, "Polymorph", "[@mouseover,harm,nodead][harm,nodead]" },
    { "PALADIN", "paladinJustice", 853, "Hammer of Justice", "[harm,nodead]", "stop" },
    { "PALADIN", "paladinFreedom", 1044, "Blessing of Freedom", "[@mouseover,help,nodead][help,nodead][@player]" },
    { "PRIEST", "priestShield", 17, "Power Word: Shield", "[@mouseover,help,nodead][help,nodead][@player]" },
    { "PRIEST", "priestDispel", 527, "Dispel Magic", "[@mouseover,help,nodead][@mouseover,harm,nodead][help,nodead][harm,nodead][@player]" },
    { "ROGUE", "rogueKick", 1766, "Kick", "[@mouseover,harm,nodead][harm,nodead]" },
    { "ROGUE", "rogueBlind", 2094, "Blind", "[@mouseover,harm,nodead][harm,nodead]" },
    { "SHAMAN", "shamanShock", 8042, "Earth Shock", "[@mouseover,harm,nodead][harm,nodead]", "stop" },
    { "SHAMAN", "shamanChainHeal", 1064, "Chain Heal", "[@mouseover,help,nodead][help,nodead][@player]" },
    { "WARLOCK", "warlockRecall", nil, nil, nil, "recall" },
    { "WARLOCK", "warlockDrain", 689, "Drain Life", "[nochanneling,harm,nodead]" },
    { "WARRIOR", "warriorStrike", 78, "Heroic Strike", "[harm,nodead]", "attack" },
    { "WARRIOR", "warriorTaunt", 355, "Taunt", "[@mouseover,harm,nodead][harm,nodead]" },
}
for _, entry in ipairs(cases) do if entry[3] then spells[entry[3]] = entry[4] end end
SetCombat(false);Suite.db.macroUpdates = false;gui.macroCollapsed = {}
equal(Suite.SettingsCatalog:Search("counterspell")[1].page, "macros", "class spells are discoverable through settings search")
equal(macros:VisibleCapacity(), 17, "class expansion keeps the existing bounded visible row capacity")
local classes, names = {}, {}
for _, case in ipairs(cases) do
    if not classes[case[1]] then
        SetClass(case[1]);Suite.db.macroOwnership = {}
        for index in pairs(native) do native[index] = nil end
        macros:Initialize(nil)
        equal(#macros:Entries(), 7, "each supported class receives two recipes plus five shared recipes")
        equal(next(native), nil, "listing class recipes never creates a game macro")
        macros:EnsureClassRecipes();macros:EnsureClassRecipes()
        equal(#Suite.macroDB.entries, 7, "repeated discovery never duplicates class recipes")
        for _, entry in ipairs(macros:Entries()) do
            local recipe = macros.byRecipe[entry.recipe]
            equal(not recipe.class or recipe.class == case[1], true, "class list excludes foreign recipes")
        end
        classes[case[1]] = true
    end
    local entry
    for _, candidate in ipairs(macros:Entries()) do if candidate.recipe == case[2] then entry = candidate end end
    equal(entry ~= nil, true, "researched recipe is present for its class")
    equal(#entry.name <= 16, true, "class macro name stays within native limit")
    equal(names[entry.name], nil, "class macro names remain unique in account-wide General storage")
    names[entry.name] = true
    local body, note, pending, ready = macros:Generate(entry, { incomplete = true })
    local expected
    if case[6] == "recall" then expected = "/petpassive\n/petfollow"
    else
        expected = "#showtooltip " .. case[4]
        if case[6] == "stop" then expected = expected .. "\n/stopcasting" end
        expected = expected .. "\n/cast " .. case[5] .. " " .. (case[6] == "attack" and "!" or "") .. case[4]
        if case[6] == "attack" then expected = expected .. "\n/startattack [harm,nodead]" end
    end
    equal(body, expected, "generated targeting and command order match reviewed behavior")
    equal(pending, false, "class utility does not depend on loading bags")
    equal(ready, true, "complete class utility can be explicitly created")
    equal(#body <= 255, true, "generated macro stays within native body limit")
    equal(body:find("/run", 1, true), nil, "class recipes contain no Lua execution")
    equal(body:find("/equip", 1, true), nil, "class recipes require no equipment-name edits")
    equal(macros:Save(entry), true, "explicit Create uses existing ownership-safe writer")
    local index = macros:Find(entry.name)
    equal(native[index].body, body, "client substitute confirms the exact written body")
    equal(Suite.db.macroOwnership[entry.name], body, "only confirmed text establishes macro ownership")
    local retained = macros:Initialize(Suite.macroDB)
    equal(#macros:Entries(), 7, "reload exposes exactly two current-class recipes while retaining inactive records")
    for _, candidate in ipairs(retained.entries) do if candidate.recipe == case[2] then entry = candidate end end
    gui:Select("macros");gui.macroSelected = entry;gui:RefreshMacros()
    equal(gui.macroChoose:IsShown(), false, "spell/static class recipes hide unrelated item picker")
    equal(gui.macroCombat:IsShown(), false, "class recipes hide supply-in-combat controls")
    equal(gui.macroPreviewBody, body, "real detail pane previews generated class text")
    equal(gui.macroListHeadings[2].label.text, "− " .. case[1]:sub(1,1) .. case[1]:sub(2):lower() .. " Macros", "each class receives its own visible group")
    if case[3] then
        spells[case[3]] = "Localized " .. case[4]
        local localized = macros:Generate(entry, {})
        equal(localized:find("Localized " .. case[4], 1, true) ~= nil, true, "spell text uses client-localized names")
        for _, invalid in ipairs({ { secret = true }, "Invalid;Spell", "Invalid\nSpell", string.rep("X",101) }) do
            spells[case[3]] = invalid
            equal(macros:Save(entry), false, "unusable spell metadata cannot replace an owned macro")
            equal(native[index].body, body, "metadata failure preserves existing native text")
        end
        spells[case[3]] = nil
        equal(macros:Generate(entry, {}), nil, "missing client spell stays unavailable")
        spells[case[3]] = case[4]
    else
        C_Spell = nil
        equal(macros:Generate(entry, { incomplete = true }), body, "pet recall requires no spell lookup or bag data")
        C_Spell = saved.api
    end
    native[index].body = "/say manually edited"
    equal(macros:Save(entry), false, "manual macro edits retain ownership protection")
    equal(native[index].body, "/say manually edited", "manual body is never overwritten")
    native[index].body = body
    SetCombat(true)
    equal(macros:Save(entry), false, "class macro writes defer during combat")
    SetCombat(false)
    local class = case[1];SetClass("HUNTER")
    equal(macros:Save(entry), false, "another class cannot rewrite this macro")
    SetClass(class)
end
SetClass("PRIEST")
spells[527] = string.rep("M", 100)
equal(macros:Generate({ recipe = "priestDispel" }, {}), nil, "valid-sized localized name cannot overflow total macro limit")
SetClass("MAGE")
local getter = C_Spell.GetSpellInfo
C_Spell.GetSpellInfo = function() error("unavailable") end
equal(macros:Generate({ recipe = "mageCounterspell" }, {}), nil, "failed spell API cannot produce partial macro text")
C_Spell.GetSpellInfo = getter
SetClass("HUNTER");macros:Initialize(nil)
equal(#macros:Entries(), 7, "existing Hunter selections remain two recipes")
SetClass({ secret = true })
equal(#macros:Entries(), 5, "restricted class exposes only shared recipes")
SetClass("UNKNOWN")
equal(#macros:Entries(), 5, "unsupported classes receive no invented recipes")
for id in pairs(spells) do spells[id] = nil end
for id, value in pairs(originalSpells) do spells[id] = value end
SetClass("HUNTER")
Suite.macroDB, Suite.db.macroOwnership, Suite.db.macroUpdates = saved.db, saved.ownership, saved.updates
gui.macroSelected, gui.macroCollapsed, macros.snapshot = saved.selected, saved.collapsed, saved.snapshot
C_Spell = saved.api
