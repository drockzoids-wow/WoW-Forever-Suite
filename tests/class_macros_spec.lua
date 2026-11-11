local Suite, equal, SetCombat, SetClass, spells, native = ...
local macros, gui = Suite.Macros, Suite.GUI
local saved = { db = Suite.macroDB, ownership = Suite.db.macroOwnership, updates = Suite.db.macroUpdates,
    api = C_Spell, selected = gui.macroSelected, collapsed = gui.macroCollapsed, snapshot = macros.snapshot }
local originalSpells = {};for id, value in pairs(spells) do originalSpells[id] = value end
local cases = {
    { "DRUID", "druidTouch", 5185, "Healing Touch", "[@mouseover,help,nodead][help,nodead][@player]" },
    { "DRUID", "druidMark", 1126, "Mark of the Wild", "[@mouseover,help,nodead][help,nodead][@player]" },
    { "DRUID", "druidHibernate", 2637, "Hibernate", "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]", "stopattack" },
    { "HUNTER", "hunterMark", 1130, "Hunter's Mark", "[harm,nodead]", "petattack" },
    { "HUNTER", "hunterRaptor", 2973, "Raptor Strike", "[harm,nodead]", "start" },
    { "HUNTER", "hunterWingClip", 2974, "Wing Clip", "[@mouseover,harm,nodead][harm,nodead]" },
    { "MAGE", "mageIntellect", 1459, "Arcane Intellect", "[@mouseover,help,nodead][help,nodead][@player]" },
    { "MAGE", "mageMissiles", 5143, "Arcane Missiles", "[nochanneling,harm,nodead]" },
    { "MAGE", "mageNova", 122, "Frost Nova", "[@player]", "stop" },
    { "PALADIN", "paladinMight", 19740, "Blessing of Might", "[@mouseover,help,nodead][help,nodead][@player]" },
    { "PALADIN", "paladinHolyLight", 635, "Holy Light", "[@mouseover,help,nodead][help,nodead][@player]" },
    { "PALADIN", "paladinRepentance", 20066, "Repentance", "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]" },
    { "PRIEST", "priestRenew", 139, "Renew", "[@mouseover,help,nodead][help,nodead][@player]" },
    { "PRIEST", "priestPain", 589, "Shadow Word: Pain", "[@mouseover,harm,nodead][harm,nodead]" },
    { "PRIEST", "priestScream", 8122, "Psychic Scream", "[@player]", "stop" },
    { "ROGUE", "rogueSinister", 1752, "Sinister Strike", "[nostealth,harm,nodead]", "startUnstealthed" },
    { "ROGUE", "rogueEviscerate", 2098, "Eviscerate", "[harm,nodead]", "start" },
    { "ROGUE", "rogueGouge", 1776, "Gouge", "[@mouseover,harm,nodead][harm,nodead]", "stopattack" },
    { "SHAMAN", "shamanBolt", 403, "Lightning Bolt", "[nochanneling,harm,nodead]" },
    { "SHAMAN", "shamanShield", 324, "Lightning Shield", "[@player]" },
    { "SHAMAN", "shamanFrostShock", 8056, "Frost Shock", "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]" },
    { "WARLOCK", "warlockCorruption", 172, "Corruption", "[@mouseover,harm,nodead][harm,nodead]" },
    { "WARLOCK", "warlockSoul", 1120, "Drain Soul", "[nochanneling,harm,nodead]" },
    { "WARLOCK", "warlockSpellLock", 19647, "Spell Lock", "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]" },
    { "WARRIOR", "warriorRend", 772, "Rend", "[harm,nodead]", "start" },
    { "WARRIOR", "warriorHamstring", 1715, "Hamstring", "[harm,nodead]", "start" },
    { "WARRIOR", "warriorDisarm", 676, "Disarm", "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]" },
    { "DRUID", "druidRejuvenation", 774, "Rejuvenation", "[@mouseover,help,nodead][help,nodead][@player]" },
    { "DRUID", "druidRoots", 339, "Entangling Roots", "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]" },
    { "HUNTER", "hunterConcussive", 5116, "Concussive Shot", "[@mouseover,harm,nodead][harm,nodead]" },
    { "HUNTER", "hunterAutoShot", 75, "Auto Shot", "[harm,nodead]", "toggle" },
    { "MAGE", "mageBlink", 1953, "Blink", "[@player]", "stop" },
    { "MAGE", "mageCurse", 475, "Remove Lesser Curse", "[@mouseover,help,nodead][help,nodead][@player]" },
    { "PALADIN", "paladinFlash", 19750, "Flash of Light", "[@mouseover,help,nodead][help,nodead][@player]" },
    { "PALADIN", "paladinProtection", 1022, "Blessing of Protection", "[@mouseover,help,nodead][help,nodead][@player]" },
    { "PRIEST", "priestFlash", 2061, "Flash Heal", "[@mouseover,help,nodead][help,nodead][@player]" },
    { "PRIEST", "priestShackle", 9484, "Shackle Undead", "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]" },
    { "ROGUE", "rogueSap", 677, "Sap", "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]" },
    { "ROGUE", "rogueVanish", 1856, "Vanish", "[@player]", "stopattack" },
    { "SHAMAN", "shamanWave", 331, "Healing Wave", "[@mouseover,help,nodead][help,nodead][@player]" },
    { "SHAMAN", "shamanPurge", 370, "Purge", "[@mouseover,harm,nodead][@focus,harm,nodead][harm,nodead]" },
    { "WARLOCK", "warlockFear", 5782, "Fear", "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]" },
    { "WARLOCK", "warlockBanish", 710, "Banish", "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]" },
    { "WARRIOR", "warriorPummel", 6552, "Pummel", "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]", "stop" },
    { "WARRIOR", "warriorSunder", 7386, "Sunder Armor", "[harm,nodead]", "start" },
    { "DRUID", "druidProwl", nil, nil, nil, "prowl" },
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
    { "WARRIOR", "warriorCharge", nil, nil, nil, "static", "#showtooltip\n/cast [stance:1/2,combat]Berserker Stance\n/cast [stance:3,combat]Intercept\n/cast [stance:2/3,nocombat]Battle Stance\n/cast [stance:1,nocombat]Charge" },
    { "WARRIOR", "warriorInterrupt", nil, nil, nil, "static", "#showtooltip [stance:1/3] Pummel;[stance:2]Shield Bash\n/cast [stance:1]Berserker Stance\n/cast [stance:2]Shield Bash\n/cast [stance:3]Pummel" },
    { "WARRIOR", "warriorOverpower", nil, nil, nil, "static", "#showtooltip Overpower\n/cast [stance:2] Battle Stance\n/cast [stance:1] Overpower" },
    { "WARRIOR", "warriorStrike", 78, "Heroic Strike", "[harm,nodead]", "attack" },
    { "WARRIOR", "warriorTaunt", 355, "Taunt", "[@mouseover,harm,nodead][harm,nodead]" },
}
for _, entry in ipairs(cases) do if entry[3] then spells[entry[3]] = entry[4] end end
SetCombat(false);Suite.db.macroUpdates = false;gui.macroCollapsed = {}
equal(Suite.SettingsCatalog:Search("counterspell")[1].page, "macros", "class spells are discoverable through settings search")
for _, word in ipairs({ "leveling", "pvp", "hibernate", "repentance", "spell lock", "gouge" }) do
    local found = false
    for _, result in ipairs(Suite.SettingsCatalog:Search(word)) do
        if result.page == "macros" then found = true end
    end
    equal(found, true, "leveling and PvP utilities are discoverable: " .. word)
end
equal(macros:VisibleCapacity(), 26, "visible row capacity includes ten Warrior recipes and ten item choices")
local classes, names = {}, {}
for _, case in ipairs(cases) do
    SetClass(case[1])
    if not classes[case[1]] then
        SetClass(case[1]);Suite.db.macroOwnership = {}
        for index in pairs(native) do native[index] = nil end
        macros:Initialize(nil)
        equal(#macros:Entries(), case[1] == "WARRIOR" and 16 or (case[1] == "DRUID" and 14 or 13), "each supported class receives its recipes plus six shared recipes")
        equal(next(native), nil, "listing class recipes never creates a game macro")
        macros:EnsureClassRecipes();macros:EnsureClassRecipes()
        equal(#Suite.macroDB.entries, case[1] == "WARRIOR" and 16 or (case[1] == "DRUID" and 14 or 13), "repeated discovery never duplicates class recipes")
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
    if case[6] == "static" then expected = case[7]
    elseif case[6] == "recall" then expected = "/petpassive\n/petfollow"
    elseif case[6] == "prowl" then expected = "#showtooltip prowl\n/cast [noform:2] !cat form\n/cast [form:2] prowl"
    else
        expected = "#showtooltip " .. case[4]
        if case[6] == "stop" then expected = expected .. "\n/stopcasting" end
        if case[6] == "stopattack" then expected = expected .. "\n/stopattack" end
        if case[6] == "petattack" then expected = expected .. "\n/petattack " .. case[5] end
        expected = expected .. "\n/cast " .. case[5] .. " " .. ((case[6] == "attack" or case[6] == "toggle") and "!" or "") .. case[4]
        if case[6] == "attack" or case[6] == "start" then expected = expected .. "\n/startattack [harm,nodead]" end
        if case[6] == "startUnstealthed" then expected = expected .. "\n/startattack [nostealth,harm,nodead]" end
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
    equal(#macros:Entries(), case[1] == "WARRIOR" and 16 or (case[1] == "DRUID" and 14 or 13), "reload exposes current-class recipes while retaining inactive records")
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
        equal(macros:Generate(entry, { incomplete = true }), body, "static class recipe requires no spell lookup or bag data")
        C_Spell = saved.api
    end
    native[index].body = "/say manually edited"
    equal(macros:Save(entry, true), false, "non-replacing saves retain manual macro edit protection")
    equal(native[index].body, "/say manually edited", "non-replacing saves preserve manual body")
    equal(macros:Save(entry), true, "explicit Update can restore the class recipe preview")
    equal(native[index].body, body, "explicit Update restores the generated class body")
    native[index].body = body
    SetCombat(true)
    equal(macros:Save(entry), false, "class macro writes defer during combat")
    SetCombat(false)
    local class = case[1];SetClass(class == "HUNTER" and "MAGE" or "HUNTER")
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
equal(#macros:Entries(), 13, "Hunter retains seven class recipes")
SetClass({ secret = true })
equal(#macros:Entries(), 6, "restricted class exposes only shared recipes")
SetClass("UNKNOWN")
equal(#macros:Entries(), 6, "unsupported classes receive no invented recipes")
SetClass("WARRIOR");macros:Initialize(nil)
local lastItem
for index = 1, 10 do
    lastItem = macros:AddItem()
    equal(lastItem ~= nil, true, "largest class retains every custom-item slot")
end
equal(#macros:Entries(), 26, "largest class plus ten custom items fills the bounded row pool")
gui.macroCollapsed = {};gui:Select("macros");gui.macroSelected = lastItem;gui:RefreshMacros()
equal(gui.macroRows[26].entry, lastItem, "last custom item has a real row in the largest class list")
equal(gui.macroRows[26]:IsShown(), true, "last row remains available in the expanded list")
equal(macros:AddItem(), nil, "larger class library retains the ten-item limit")
for id in pairs(spells) do spells[id] = nil end
for id, value in pairs(originalSpells) do spells[id] = value end
SetClass("HUNTER")
Suite.macroDB, Suite.db.macroOwnership, Suite.db.macroUpdates = saved.db, saved.ownership, saved.updates
gui.macroSelected, gui.macroCollapsed, macros.snapshot = saved.selected, saved.collapsed, saved.snapshot
C_Spell = saved.api
