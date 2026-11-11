local _, Suite = ...
local Macros = { statuses = {}, statusErrors = {} }
Suite.Macros = Macros
table.insert(Suite.modules, Macros)
local Items = Suite.MacroItems
local Number, Text = Items.Number, Items.Text

Macros.recipes = {
    { key = "food", name = "FS Food", title = "Food / Health", help = "Eat outside combat: experience-bonus food first, then mage food, event food and regular food. Your selected food takes priority. Optional combat Healthstone and healing potion." },
    { key = "water", name = "FS Drink", title = "Drink / Mana", help = "Drink outside combat: mage water, then event drinks, then regular water. Optional combat mana potion." },
    { key = "bandage", name = "FS Bandage", title = "Bandage", help = "Use your strongest carried bandage with normal item targeting. Choose someone to bandage as usual; native targeting and self-cast settings apply." },
    { key = "mainhand", name = "FS Main Hand", title = "Main-hand coating", slot = 16,
        help = "Match an ordinary stone to your weapon, or choose an oil or poison. Apply outside combat." },
    { key = "offhand", name = "FS Off Hand", title = "Off-hand coating", slot = 17,
        help = "Match an ordinary stone to your weapon, or choose an oil or poison. Apply outside combat." },
    { key = "randomMount", name = "FS Random Mount", title = "Random mount", body = "#showtooltip\n/stopmacro [combat]\n/wfs randommount",
        help = "Dismount if mounted; otherwise choose a random collected mount. The icon shows the chosen mount. Requires riding; use outside combat with Blizzard's Macros window closed. Random choices may repeat." },
    { key = "hunterMisdirection", name = "FS Misdirection", title = "Hunter · Misdirection", class = "HUNTER", spell = 34477,
        help = "Cast on a friendly focus, then a friendly target, then your pet. Requires Misdirection to be learned." },
    { key = "hunterPet", name = "FS Pet Care", title = "Hunter · Pet care", class = "HUNTER", foodChoice = true,
        help = "Revive a dead pet; Shift with no pet. Mend in combat; feed outside combat. Choose food your pet can eat." },
    { key = "hunterConcussive", name = "FS Concussive", title = "Hunter · Concussive Shot", class = "HUNTER", spell = 5116,
        conditions = "[@mouseover,harm,nodead][harm,nodead]",
        help = "Slow a living enemy mouseover, otherwise your enemy target, without changing targets." },
    { key = "hunterAutoShot", name = "FS Auto Shot", title = "Hunter · Auto Shot", class = "HUNTER", spell = 75, nonToggle = true,
        conditions = "[harm,nodead]",
        help = "Start Auto Shot on your living enemy target. Repeated presses do not deliberately toggle shooting off; ranged weapon and range rules apply." },
    { key = "hunterMark", name = "FS Mark Pet", title = "Hunter · Hunter's Mark & pet", class = "HUNTER", spell = 1130, petattack = true,
        conditions = "[harm,nodead]",
        help = "Leveling / pull: send your pet at your living enemy target, then attempt Hunter's Mark. The pet attacks even if marking fails; this begins a pull. Requires an active pet for the pet command." },
    { key = "hunterRaptor", name = "FS Raptor Strike", title = "Hunter · Raptor Strike & attack", class = "HUNTER", spell = 2973, startattack = true,
        conditions = "[harm,nodead]",
        help = "Leveling / melee: attempt Raptor Strike and start melee attacks against your living enemy target. Native melee weapon, range and resource rules apply." },
    { key = "hunterWingClip", name = "FS Wing Clip", title = "Hunter · Wing Clip", class = "HUNTER", spell = 2974,
        conditions = "[@mouseover,harm,nodead][harm,nodead]",
        help = "PvP / kiting: slow a living enemy mouseover, otherwise your enemy target. Requires melee range; does not change your selected target." },
    { key = "druidProwl", name = "FS Prowl", title = "Druid · Prowl", class = "DRUID",
        body = "#showtooltip prowl\n/cast [noform:2] !cat form\n/cast [form:2] prowl",
        help = "Enter Cat Form when outside form 2, then attempt Prowl in form 2. Uses English spell names; native form, combat and cooldown rules apply." },
    { key = "druidInnervate", name = "FS Innervate", title = "Druid · Innervate", class = "DRUID", spell = 29166,
        conditions = "[@mouseover,help,nodead][help,nodead][@player]",
        help = "Restore mana to a living friendly mouseover, then friendly target, otherwise yourself. No form is cancelled." },
    { key = "druidRebirth", name = "FS Rebirth", title = "Druid · Rebirth", class = "DRUID", spell = 20484,
        conditions = "[@mouseover,help,dead][help,dead]",
        help = "Battle-resurrect a dead friendly mouseover, otherwise your dead friendly target. Reagents and form rules still apply." },
    { key = "druidRejuvenation", name = "FS Rejuvenation", title = "Druid · Rejuvenation", class = "DRUID", spell = 774,
        conditions = "[@mouseover,help,nodead][help,nodead][@player]",
        help = "Heal a living friendly mouseover over time, then friendly target, otherwise yourself. No form is cancelled." },
    { key = "druidRoots", name = "FS Roots", title = "Druid · Entangling Roots", class = "DRUID", spell = 339,
        conditions = "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]",
        help = "Root a living enemy focus, then enemy mouseover, then enemy target. Damage and native creature/location rules can limit the root; no form is cancelled." },
    { key = "druidTouch", name = "FS Healing Touch", title = "Druid · Healing Touch", class = "DRUID", spell = 5185,
        conditions = "[@mouseover,help,nodead][help,nodead][@player]",
        help = "Leveling: heal a living friendly mouseover, then friendly target, otherwise yourself. Leave any form that blocks healing yourself; this macro does not cancel forms." },
    { key = "druidMark", name = "FS Mark Wild", title = "Druid · Mark of the Wild", class = "DRUID", spell = 1126,
        conditions = "[@mouseover,help,nodead][help,nodead][@player]",
        help = "Leveling: buff a living friendly mouseover, then friendly target, otherwise yourself. Uses your highest learned rank; no form is cancelled." },
    { key = "druidHibernate", name = "FS Hibernate", title = "Druid · Hibernate", class = "DRUID", spell = 2637, stopattack = true,
        conditions = "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]",
        help = "PvP / control: stop auto-attacking and Hibernate a living enemy focus, then enemy mouseover, then enemy target. Requires an eligible Beast or Dragonkin; damage can break it. No form is cancelled." },
    { key = "mageCounterspell", name = "FS Counterspell", title = "Mage · Counterspell", class = "MAGE", spell = 2139, stopcasting = true,
        conditions = "[@mouseover,harm,nodead][harm,nodead]",
        help = "Stop your current cast and interrupt a living enemy mouseover, otherwise your enemy target." },
    { key = "magePolymorph", name = "FS Polymorph", title = "Mage · Polymorph", class = "MAGE", spell = 118,
        conditions = "[@mouseover,harm,nodead][harm,nodead]",
        help = "Polymorph a living enemy mouseover, otherwise your enemy target, without changing your selected target. Creature restrictions apply." },
    { key = "mageBlink", name = "FS Blink", title = "Mage · Blink", class = "MAGE", spell = 1953, stopcasting = true,
        conditions = "[@player]",
        help = "Stop your current cast and attempt Blink immediately. Terrain, cooldown and native movement restrictions still apply." },
    { key = "mageCurse", name = "FS Remove Curse", title = "Mage · Remove Lesser Curse", class = "MAGE", spell = 475,
        conditions = "[@mouseover,help,nodead][help,nodead][@player]",
        help = "Remove a curse from a living friendly mouseover, then friendly target, otherwise yourself. The spell determines which effects can be removed." },
    { key = "mageIntellect", name = "FS Intellect", title = "Mage · Arcane Intellect", class = "MAGE", spell = 1459,
        conditions = "[@mouseover,help,nodead][help,nodead][@player]",
        help = "Leveling: buff a living friendly mouseover, then friendly target, otherwise yourself, while keeping your selected target." },
    { key = "mageMissiles", name = "FS Missiles", title = "Mage · Arcane Missiles", class = "MAGE", spell = 5143,
        conditions = "[nochanneling,harm,nodead]",
        help = "Leveling: channel Arcane Missiles at your living enemy target without restarting any channel already in progress. Repeated presses wait until that channel ends." },
    { key = "mageNova", name = "FS Frost Nova", title = "Mage · Frost Nova", class = "MAGE", spell = 122, stopcasting = true,
        conditions = "[@player]",
        help = "PvP / escape: stop your current cast and attempt Frost Nova around yourself, even without an enemy selected. This does not automatically Blink or choose a destination." },
    { key = "paladinJustice", name = "FS Justice", title = "Paladin · Hammer of Justice", class = "PALADIN", spell = 853, stopcasting = true,
        conditions = "[harm,nodead]",
        help = "Stop your current cast and stun your living enemy target immediately. Range and immunity rules still apply." },
    { key = "paladinFreedom", name = "FS Freedom", title = "Paladin · Blessing of Freedom", class = "PALADIN", spell = 1044,
        conditions = "[@mouseover,help,nodead][help,nodead][@player]",
        help = "Free a living friendly mouseover from movement effects, then friendly target, otherwise yourself." },
    { key = "paladinFlash", name = "FS Flash Light", title = "Paladin · Flash of Light", class = "PALADIN", spell = 19750,
        conditions = "[@mouseover,help,nodead][help,nodead][@player]",
        help = "Heal a living friendly mouseover, then friendly target, otherwise yourself, without changing your selected target." },
    { key = "paladinProtection", name = "FS Protection", title = "Paladin · Blessing of Protection", class = "PALADIN", spell = 1022,
        conditions = "[@mouseover,help,nodead][help,nodead][@player]",
        help = "Protect a living friendly mouseover, then friendly target, otherwise yourself. This can prevent physical attacks by the recipient; Forbearance and native restrictions apply." },
    { key = "paladinMight", name = "FS Might", title = "Paladin · Blessing of Might", class = "PALADIN", spell = 19740,
        conditions = "[@mouseover,help,nodead][help,nodead][@player]",
        help = "Leveling: buff a living friendly mouseover, then friendly target, otherwise yourself. Native blessing replacement and duration rules apply." },
    { key = "paladinHolyLight", name = "FS Holy Light", title = "Paladin · Holy Light", class = "PALADIN", spell = 635,
        conditions = "[@mouseover,help,nodead][help,nodead][@player]",
        help = "Leveling: heal a living friendly mouseover, then friendly target, otherwise yourself. Uses your highest learned rank, with its normal mana cost and cast time." },
    { key = "paladinRepentance", name = "FS Repentance", title = "Paladin · Repentance", class = "PALADIN", spell = 20066,
        conditions = "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]",
        help = "PvP / control: Repentance a living enemy focus, then enemy mouseover, then enemy target. Requires the learned talent and an eligible creature type; damage can break it." },
    { key = "priestShield", name = "FS Shield", title = "Priest · Power Word: Shield", class = "PRIEST", spell = 17,
        conditions = "[@mouseover,help,nodead][help,nodead][@player]",
        help = "Shield a living friendly mouseover, then friendly target, otherwise yourself. Weakened Soul and other spell rules still apply." },
    { key = "priestDispel", name = "FS Dispel", title = "Priest · Dispel Magic", class = "PRIEST", spell = 527,
        conditions = "[@mouseover,help,nodead][@mouseover,harm,nodead][help,nodead][harm,nodead][@player]",
        help = "Dispel a living friendly or enemy mouseover, then your living target, otherwise yourself. The spell decides which magic can be removed." },
    { key = "priestFlash", name = "FS Flash Heal", title = "Priest · Flash Heal", class = "PRIEST", spell = 2061,
        conditions = "[@mouseover,help,nodead][help,nodead][@player]",
        help = "Heal a living friendly mouseover, then friendly target, otherwise yourself, while keeping your selected target." },
    { key = "priestShackle", name = "FS Shackle", title = "Priest · Shackle Undead", class = "PRIEST", spell = 9484,
        conditions = "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]",
        help = "Shackle a living enemy focus, then enemy mouseover, then enemy target. Requires an eligible undead enemy; damage can break the effect." },
    { key = "priestRenew", name = "FS Renew", title = "Priest · Renew", class = "PRIEST", spell = 139,
        conditions = "[@mouseover,help,nodead][help,nodead][@player]",
        help = "Leveling: heal a living friendly mouseover over time, then friendly target, otherwise yourself, without changing your selected target." },
    { key = "priestPain", name = "FS Shadow Pain", title = "Priest · Shadow Word: Pain", class = "PRIEST", spell = 589,
        conditions = "[@mouseover,harm,nodead][harm,nodead]",
        help = "Leveling / multidot: apply Shadow Word: Pain to a living enemy mouseover, otherwise your enemy target. Keep your selected target; each press attempts one cast." },
    { key = "priestScream", name = "FS Scream", title = "Priest · Psychic Scream", class = "PRIEST", spell = 8122, stopcasting = true,
        conditions = "[@player]",
        help = "PvP / escape: stop your current cast and attempt Psychic Scream around yourself, even with no enemy selected. Fleeing enemies can pull additional enemies." },
    { key = "rogueKick", name = "FS Kick", title = "Rogue · Kick", class = "ROGUE", spell = 1766,
        conditions = "[@mouseover,harm,nodead][harm,nodead]",
        help = "Interrupt a living enemy mouseover, otherwise your enemy target. Your selected target stays unchanged; melee range is required." },
    { key = "rogueBlind", name = "FS Blind", title = "Rogue · Blind", class = "ROGUE", spell = 2094,
        conditions = "[@mouseover,harm,nodead][harm,nodead]",
        help = "Blind a living enemy mouseover, otherwise your enemy target, without changing your selected target. Native reagent rules apply." },
    { key = "rogueSap", name = "FS Sap", title = "Rogue · Sap", class = "ROGUE", spell = 677,
        conditions = "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]",
        help = "Sap a living enemy focus, then enemy mouseover, then enemy target. Does not enter Stealth; native stealth, combat and creature restrictions apply." },
    { key = "rogueVanish", name = "FS Vanish", title = "Rogue · Vanish", class = "ROGUE", spell = 1856, stopattack = true,
        conditions = "[@player]",
        help = "Stop auto-attacking before attempting Vanish. Native reagents and cooldowns still apply; incoming damage may reveal you." },
    { key = "rogueSinister", name = "FS Sinister", title = "Rogue · Sinister Strike & attack", class = "ROGUE", spell = 1752, startattack = true, attackConditions = "[nostealth,harm,nodead]",
        conditions = "[nostealth,harm,nodead]",
        help = "Leveling: outside Stealth, attempt Sinister Strike and start melee on your living enemy target. In Stealth neither command runs, preserving your opener." },
    { key = "rogueEviscerate", name = "FS Eviscerate", title = "Rogue · Eviscerate & attack", class = "ROGUE", spell = 2098, startattack = true,
        conditions = "[harm,nodead]",
        help = "Leveling / finisher: attempt Eviscerate and start melee on your living enemy target. You must supply the required combo points and Energy; the macro does not choose a finisher for you." },
    { key = "rogueGouge", name = "FS Gouge", title = "Rogue · Gouge", class = "ROGUE", spell = 1776, stopattack = true,
        conditions = "[@mouseover,harm,nodead][harm,nodead]",
        help = "PvP / control: stop auto-attacking and Gouge a living enemy mouseover, otherwise your enemy target. Native facing and melee-range rules apply; damage can break it." },
    { key = "shamanShock", name = "FS Earth Shock", title = "Shaman · Earth Shock", class = "SHAMAN", spell = 8042, stopcasting = true,
        conditions = "[@mouseover,harm,nodead][harm,nodead]",
        help = "Stop your current cast and Earth Shock a living enemy mouseover, otherwise your enemy target. Uses the highest learned rank." },
    { key = "shamanChainHeal", name = "FS Chain Heal", title = "Shaman · Chain Heal", class = "SHAMAN", spell = 1064,
        conditions = "[@mouseover,help,nodead][help,nodead][@player]",
        help = "Chain Heal a living friendly mouseover, then friendly target, otherwise yourself, while keeping your selected target." },
    { key = "shamanWave", name = "FS Healing Wave", title = "Shaman · Healing Wave", class = "SHAMAN", spell = 331,
        conditions = "[@mouseover,help,nodead][help,nodead][@player]",
        help = "Heal a living friendly mouseover, then friendly target, otherwise yourself, without changing your selected target." },
    { key = "shamanPurge", name = "FS Purge", title = "Shaman · Purge", class = "SHAMAN", spell = 370,
        conditions = "[@mouseover,harm,nodead][@focus,harm,nodead][harm,nodead]",
        help = "Purge a living enemy mouseover, then enemy focus, then enemy target. Only effects permitted by the native spell can be removed." },
    { key = "shamanBolt", name = "FS Lightning", title = "Shaman · Lightning Bolt", class = "SHAMAN", spell = 403,
        conditions = "[nochanneling,harm,nodead]",
        help = "Leveling: cast Lightning Bolt on your living enemy target while preserving any channel already in progress. Uses your highest learned rank." },
    { key = "shamanShield", name = "FS Lightning Sh", title = "Shaman · Lightning Shield", class = "SHAMAN", spell = 324,
        conditions = "[@player]",
        help = "Leveling: apply Lightning Shield to yourself without changing your target. Repeated presses can refresh it and spend mana; native shield replacement rules apply." },
    { key = "shamanFrostShock", name = "FS Frost Shock", title = "Shaman · Frost Shock", class = "SHAMAN", spell = 8056,
        conditions = "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]",
        help = "PvP / kiting: slow a living enemy focus, then enemy mouseover, then enemy target. Shares native shock cooldown restrictions; this does not interrupt as Earth Shock does." },
    { key = "warlockRecall", name = "FS Pet Recall", title = "Warlock · Pet recall", class = "WARLOCK", body = "/petpassive\n/petfollow",
        help = "Put your pet on Passive and call it back to follow you. It stays Passive afterward; choose its next attack or stance yourself." },
    { key = "warlockDrain", name = "FS Drain Life", title = "Warlock · Drain Life", class = "WARLOCK", spell = 689,
        conditions = "[nochanneling,harm,nodead]",
        help = "Drain Life from your living enemy target without restarting an active channel. This preserves any channel already in progress." },
    { key = "warlockFear", name = "FS Fear", title = "Warlock · Fear", class = "WARLOCK", spell = 5782,
        conditions = "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]",
        help = "Fear a living enemy focus, then enemy mouseover, then enemy target. Feared enemies can run into additional enemies." },
    { key = "warlockBanish", name = "FS Banish", title = "Warlock · Banish", class = "WARLOCK", spell = 710,
        conditions = "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]",
        help = "Banish a living enemy focus, then enemy mouseover, then enemy target. Only native eligible creature types can be banished." },
    { key = "warlockCorruption", name = "FS Corruption", title = "Warlock · Corruption", class = "WARLOCK", spell = 172,
        conditions = "[@mouseover,harm,nodead][harm,nodead]",
        help = "Leveling / multidot: apply Corruption to a living enemy mouseover, otherwise your enemy target. Each press attempts one cast without changing your selected target." },
    { key = "warlockSoul", name = "FS Drain Soul", title = "Warlock · Drain Soul", class = "WARLOCK", spell = 1120,
        conditions = "[nochanneling,harm,nodead]",
        help = "Leveling / shards: channel your highest learned Drain Soul on your living enemy target, preserving any active channel. Native kill, inventory and shard requirements decide the result." },
    { key = "warlockSpellLock", name = "FS Spell Lock", title = "Warlock · Spell Lock", class = "WARLOCK", spell = 19647,
        conditions = "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]",
        help = "PvP / interrupt: have your Felhunter Spell Lock a living enemy focus, then enemy mouseover, then enemy target. Requires the active pet to know the ability; does not summon or switch pets." },
    { key = "warriorCharge", name = "FS Charge", title = "Warrior · Charge / Intercept", class = "WARRIOR",
        body = "#showtooltip\n/cast [stance:1/2,combat]Berserker Stance\n/cast [stance:3,combat]Intercept\n/cast [stance:2/3,nocombat]Battle Stance\n/cast [stance:1,nocombat]Charge",
        help = "Switch to Battle Stance outside combat for Charge, or Berserker Stance in combat for Intercept. Intercept is attempted only in combat. Uses English spell names; stance changes may require another press. Native range, Rage and cooldown rules apply." },
    { key = "warriorInterrupt", name = "FS Interrupt", title = "Warrior · Stance interrupt", class = "WARRIOR",
        body = "#showtooltip [stance:1/3] Pummel;[stance:2]Shield Bash\n/cast [stance:1]Berserker Stance\n/cast [stance:2]Shield Bash\n/cast [stance:3]Pummel",
        help = "From Battle Stance, switch to Berserker Stance for Pummel; in Defensive Stance, use Shield Bash. Uses English spell names; stance changes may require another press. Shield Bash requires a shield. Native Rage, range and cooldown rules apply." },
    { key = "warriorOverpower", name = "FS Overpower", title = "Warrior · Overpower", class = "WARRIOR",
        body = "#showtooltip Overpower\n/cast [stance:2] Battle Stance\n/cast [stance:1] Overpower",
        help = "Switch from Defensive Stance to Battle Stance, then attempt Overpower. Does not switch from Berserker Stance. Uses English spell names; stance changes may require another press. Requires the native Overpower opportunity and enough Rage." },
    { key = "warriorStrike", name = "FS Heroic Strike", title = "Warrior · Heroic Strike & attack", class = "WARRIOR", spell = 78, nonToggle = true, startattack = true,
        conditions = "[harm,nodead]",
        help = "Queue Heroic Strike and start melee attacks against your living enemy target. Repeated presses do not deliberately unqueue it. Costs Rage." },
    { key = "warriorTaunt", name = "FS Taunt", title = "Warrior · Taunt", class = "WARRIOR", spell = 355,
        conditions = "[@mouseover,harm,nodead][harm,nodead]",
        help = "Taunt a living enemy mouseover, otherwise your enemy target. This does not change your stance; native stance requirements apply." },
    { key = "warriorPummel", name = "FS Pummel", title = "Warrior · Pummel", class = "WARRIOR", spell = 6552, stopcasting = true,
        conditions = "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]",
        help = "Stop your current cast and Pummel a living enemy focus, then enemy mouseover, then enemy target. Does not change stance; native stance and melee-range rules apply." },
    { key = "warriorSunder", name = "FS Sunder", title = "Warrior · Sunder Armor & attack", class = "WARRIOR", spell = 7386, startattack = true,
        conditions = "[harm,nodead]",
        help = "Sunder Armor and start melee attacks against your living enemy target. Does not choose a new target or change your stance; native Rage rules apply." },
    { key = "warriorRend", name = "FS Rend", title = "Warrior · Rend & attack", class = "WARRIOR", spell = 772, startattack = true,
        conditions = "[harm,nodead]",
        help = "Leveling: attempt Rend and start melee against your living enemy target. Does not change stance; native stance and Rage requirements apply." },
    { key = "warriorHamstring", name = "FS Hamstring", title = "Warrior · Hamstring & attack", class = "WARRIOR", spell = 1715, startattack = true,
        conditions = "[harm,nodead]",
        help = "Leveling / PvP: attempt Hamstring and start melee against your living enemy target to slow a runner. Does not change stance; native stance and Rage rules apply." },
    { key = "warriorDisarm", name = "FS Disarm", title = "Warrior · Disarm", class = "WARRIOR", spell = 676,
        conditions = "[@focus,harm,nodead][@mouseover,harm,nodead][harm,nodead]",
        help = "PvP / defense: Disarm a living enemy focus, then enemy mouseover, then enemy target. Does not change stance; native stance, Rage, weapon and immunity rules apply." },
}
Macros.byRecipe = { item = { key = "item", title = "Item macro", help = "Use the item you choose. The item keeps its normal targeting and confirmation prompts." } }
for _, recipe in ipairs(Macros.recipes) do Macros.byRecipe[recipe.key] = recipe end

function Macros:VisibleCapacity()
    local shared, largest, classes = 0, 0, {}
    for _, recipe in ipairs(self.recipes) do
        if recipe.class then classes[recipe.class] = (classes[recipe.class] or 0) + 1
        else shared = shared + 1 end
    end
    for _, count in pairs(classes) do largest = math.max(largest, count) end
    return shared + largest + 10
end

function Macros:PlayerClass()
    if type(UnitClass) ~= "function" then return end
    local ok, _, class = pcall(UnitClass, "player")
    if ok and Text(class) and #class <= 32 then return class end
end
function Macros:Applicable(entry)
    local recipe = self.byRecipe[entry.recipe]
    return recipe and (not recipe.class or self:PlayerClass() == recipe.class) or false
end
function Macros:Entries()
    self:EnsureClassRecipes()
    local entries = {}
    for _, entry in ipairs(Suite.macroDB.entries) do
        if self:Applicable(entry) then entries[#entries + 1] = entry end
    end
    return entries
end
function Macros:EnsureClassRecipes()
    if InCombatLockdown() or not Suite.macroDB then return end
    local class, existing = self:PlayerClass(), {}
    for _, entry in ipairs(Suite.macroDB.entries) do existing[entry.recipe] = true end
    for _, recipe in ipairs(self.recipes) do
        if recipe.class and recipe.class == class and not existing[recipe.key] then
            local position = #Suite.macroDB.entries + 1
            for index, entry in ipairs(Suite.macroDB.entries) do
                if entry.recipe == "item" then position = index; break end
            end
            table.insert(Suite.macroDB.entries, position, { recipe = recipe.key, name = recipe.name, created = false, combat = false })
        end
    end
end
local function ItemCount(entries)
    local count = 0
    for _, entry in ipairs(entries) do if entry.recipe == "item" then count = count + 1 end end
    return count
end
local function SpellName(id)
    if not C_Spell or type(C_Spell.GetSpellInfo) ~= "function" then return end
    local ok, info = pcall(C_Spell.GetSpellInfo, id)
    if not ok or not Suite.IsReadable(info) or type(info) ~= "table" then return end
    local name = info.name
    if Text(name) and #name > 0 and #name <= 100 and not name:find("[%c|;]") then return name end
end

local function ValidBody(value) return Text(value) and #value > 0 and #value <= 255 and not value:find("%z") end
local function ValidName(value) return Text(value) and #value > 0 and #value <= 16 and not value:find('[%c|";]') end
local function ItemID(value) return Number(value) and value > 0 and value % 1 == 0 and value <= 10000000 end
local function Serial(value) return Number(value) and value >= 1 and value <= 9999 and value % 1 == 0 end
local function ItemSerial(name)
    if not Text(name) then return nil end
    local serial = tonumber(name:match("^FS Item (%d+)$"))
    return Serial(serial) and name == "FS Item " .. serial and serial or nil
end
local function Lines(value) return (value:gsub("\r\n", "\n"):gsub("\n+$", "")) end
local function SameBody(first, second)
    if not Text(first) or not Text(second) then return false end
    return Lines(first) == Lines(second)
end
local function SharedItem(body)
    if not Text(body) then return nil end
    local tooltip, action = Lines(body):match("^#showtooltip item:(%d+)\n/use item:(%d+)$")
    local id = tonumber(action)
    return tooltip == action and ItemID(id) and id or nil
end

function Macros:Initialize(saved)
    saved = type(saved) == "table" and saved or {}
    local previous = type(saved.entries) == "table" and saved.entries or {}
    local entries, fixed, serials, ignoredItems = {}, {}, {}, {}
    for serial, ignored in pairs(type(saved.ignoredItems) == "table" and saved.ignoredItems or {}) do
        if Serial(serial) and Suite.IsReadable(ignored) and ignored == true then ignoredItems[serial] = true end
    end
    local function Settings(record, recipe, name, serial)
        local id = record.item
        return { recipe = recipe, name = name, serial = serial, created = record.created == true,
            combat = record.combat == true, item = ItemID(id) and id or nil }
    end
    for _, record in ipairs(previous) do
        if type(record) == "table" and self.byRecipe[record.recipe] then
            if record.recipe ~= "item" then fixed[record.recipe] = record
            elseif Serial(record.serial) and not ignoredItems[record.serial] and not serials[record.serial] and #entries < 10 then
                serials[record.serial] = true
                entries[#entries + 1] = Settings(record, "item", "FS Item " .. record.serial, record.serial)
            end
        end
    end
    local custom = entries
    entries = {}
    local class = self:PlayerClass()
    for _, recipe in ipairs(self.recipes) do
        if not recipe.class or recipe.class == class or fixed[recipe.key] then
            entries[#entries + 1] = Settings(fixed[recipe.key] or {}, recipe.key, recipe.name)
        end
    end
    for _, record in ipairs(custom) do entries[#entries + 1] = record end
    local nextSerial = 1
    for serial in pairs(serials) do nextSerial = math.max(nextSerial, serial + 1) end
    for serial in pairs(ignoredItems) do nextSerial = math.max(nextSerial, serial + 1) end
    if Number(saved.nextSerial) and saved.nextSerial % 1 == 0 then nextSerial = math.max(nextSerial, math.min(10000, saved.nextSerial)) end
    Suite.macroDB = { schema = 2, entries = entries, nextSerial = nextSerial, ignoredItems = ignoredItems }
    local ownership = {}
    for name, body in pairs(Suite.db.macroOwnership) do
        if ValidName(name) and ValidBody(body) then
            ownership[name] = body
            local serial = ItemSerial(name)
            if serial then Suite.macroDB.nextSerial = math.max(Suite.macroDB.nextSerial, serial + 1) end
        end
    end
    Suite.db.macroOwnership = ownership
    self:SyncGeneral()
    return Suite.macroDB
end

function Macros:AddItem()
    local db = Suite.macroDB
    if InCombatLockdown() then return nil, "Add item macros after combat." end
    self:SyncGeneral()
    if ItemCount(db.entries) >= 10 or db.nextSerial > 9999 then return nil, "Up to ten item macros can be kept here." end
    local serial = db.nextSerial
    db.nextSerial = serial + 1
    local entry = { recipe = "item", serial = serial, name = "FS Item " .. serial, created = false, combat = false }
    db.entries[#db.entries + 1] = entry
    return entry
end

function Macros:RemoveItem(entry)
    if InCombatLockdown() or entry.recipe ~= "item" then return false end
    for index, record in ipairs(Suite.macroDB.entries) do
        if record == entry then
            table.remove(Suite.macroDB.entries, index)
            Suite.macroDB.ignoredItems[entry.serial] = true
            self.statuses[entry] = nil
            self.statusErrors[entry] = nil
            return true -- Removing a choice never deletes or changes its game macro.
        end
    end
    return false
end

function Macros:Generate(entry, snapshot, currentItem)
    if InCombatLockdown() then return nil, "Macro changes wait until combat ends.", true end
    local recipe = self.byRecipe[entry.recipe]
    if not self:Applicable(entry) then return nil, "This recipe is for another class.", true end
    if recipe.body then
        if not ValidBody(recipe.body) then return nil, "This recipe exceeds the game's macro text limit.", true end
        return recipe.body, recipe.help, false, true
    end
    if recipe.spell then
        local spell = SpellName(recipe.spell)
        if not spell then return nil, "Spell information is unavailable in this client.", true end
        local conditions = recipe.conditions or "[@focus,help][@target,help][@pet,exists]"
        local body = "#showtooltip " .. spell
        if recipe.stopcasting then body = body .. "\n/stopcasting" end
        if recipe.stopattack then body = body .. "\n/stopattack" end
        if recipe.petattack then body = body .. "\n/petattack " .. conditions end
        body = body .. "\n/cast " .. conditions .. " " .. (recipe.nonToggle and "!" or "") .. spell
        if recipe.startattack then body = body .. "\n/startattack " .. (recipe.attackConditions or "[harm,nodead]") end
        if not ValidBody(body) then return nil, "This spell name exceeds the game's macro text limit.", true end
        return body, recipe.conditions and (recipe.help .. " Requires the learned spell; native restrictions still apply.")
            or "Friendly focus → friendly target → pet. Requires the learned spell.", false, true
    end
    if snapshot.incomplete then return nil, "Bag data is loading or unavailable. Existing text is kept.", true end
    if recipe.foodChoice then
        if not ItemID(entry.item) then return nil, "Choose food from your bags that your pet eats.", true end
        if snapshot.carriedIncomplete then return nil, "Carried item names are loading. Existing text is kept.", true end
        local revive, mend, feed = SpellName(982), SpellName(136), SpellName(6991)
        if not revive or not mend or not feed then return nil, "Pet spell information is unavailable in this client.", true end
        local food = snapshot.carriedByID and snapshot.carriedByID[entry.item]
        if not food then
            local choices, problem = Items:PetFoodChoices(snapshot)
            food = choices[1]
            if not food and #(snapshot.carried or {}) > 0 and problem ~= "No carried food matches your active pet." then
                return nil, problem, true
            end
        end
        if not food then
            return "#showtooltip\n/cast [@pet,dead][nopet,mod:shift] " .. revive
                .. "\n/cast [combat,@pet,exists,nodead] " .. mend,
                "Chosen food is not carried. No suitable carried pet food; feeding is paused until restocked.", false, true
        end
        local foodName = food and food.name
        if not Text(foodName) or #foodName == 0 or #foodName > 128 or foodName:find("[%c|;%[%]]") then
            return nil, "Food name is loading or unavailable. Existing text is kept.", true
        end
        local body = "#showtooltip\n/cast [@pet,dead][nopet,mod:shift] " .. revive
            .. "\n/cast [combat,@pet,exists,nodead] " .. mend .. "; [nocombat,@pet,exists,nodead] " .. feed
            .. "\n/stopmacro [combat][nopet][@pet,dead]\n/use " .. foodName
        if not ValidBody(body) then return nil, "These spell names exceed the game's macro text limit.", true end
        local accepted, problem = Items:PetCanEat(food.id)
        if accepted ~= true then
            return body, problem or "Your active pet cannot eat the chosen food. Choose another food; the macro keeps your choice.", false, true, food
        end
        return body, "Food: " .. food.name .. " (" .. food.count .. " carried). Suitable for your active pet.", false, true, food
    end
    local waiting = snapshot.pending or {}
    if entry.combat and (entry.recipe == "food" and (waiting.healthstone or waiting.healing)
        or entry.recipe == "water" and waiting.mana) then
        return nil, "Combat supply data is loading. Existing text is kept.", true
    end
    local item, note, pending
    local preferred = entry.item or not recipe.slot and currentItem
    if preferred then
        if snapshot.pendingByID and snapshot.pendingByID[preferred] then
            return nil, "Chosen item data is loading. Existing text is kept.", true
        end
        item = snapshot.byID[preferred]
    end
    if entry.recipe == "food" and not entry.item and snapshot.english then
        -- A still-carried automatic choice must not hide newly stocked XP food.
        -- Wait for relevant tooltips before deciding whether to promote it.
        if waiting.food then return nil, "Recovery supply data is loading. Existing text is kept.", true end
        local best = snapshot.best.food
        if best and (best.experienceBonus or 0) > (item and item.experienceBonus or 0) then item = best end
    end
    if not item and recipe.slot then item, note, pending = Items:WeaponStone(snapshot, recipe.slot)
    elseif not item and entry.recipe == "item" then
        if not entry.item then return nil, "Choose a carried item first.", true end
        note = "Chosen item is not carried. Restock it or choose another item."
    elseif not item and (entry.recipe == "food" or entry.recipe == "water") and not snapshot.english then
        return nil, "Choose food or drink for this language.", true
    elseif not item then
        if waiting[entry.recipe] then return nil, "Recovery supply data is loading. Existing text is kept.", true end
        item = snapshot.best[entry.recipe]
    end
    if pending then return nil, note, true end
    local tooltip, commands, details = {}, {}, {}
    local function Use(candidate, condition)
        if not candidate then return end
        local qualifier = condition and "[" .. condition .. "] " or ""
        tooltip[#tooltip + 1] = qualifier .. "item:" .. candidate.id
        -- Supply updates choose the item; the game retains normal unit targeting.
        commands[#commands + 1] = "/use " .. qualifier .. "item:" .. candidate.id
        details[#details + 1] = candidate.name
    end
    if entry.combat and (entry.recipe == "food" or entry.recipe == "water") then
        if entry.recipe == "food" then
            -- Both lines are attempted on a press; this is not a cooldown-based fallback.
            Use(snapshot.best.healthstone, "combat")
            Use(snapshot.best.healing, "combat")
            if snapshot.best.healthstone and snapshot.best.healing then table.remove(tooltip, #tooltip) end
        else Use(snapshot.best.mana, "combat") end
    end
    local rest = entry.recipe == "food" or entry.recipe == "water" or recipe.slot ~= nil
    Use(item, rest and "nocombat" or nil)
    if recipe.slot and item then commands[#commands + 1] = "/use [nocombat] " .. recipe.slot end
    if #commands == 0 then return "#showtooltip", note or "Carry suitable supplies, or choose an item.", false, false end
    table.insert(commands, 1, "#showtooltip " .. table.concat(tooltip, "; "))
    return table.concat(commands, "\n"), table.concat(details, ", "), false, true, item
end

local function Limit()
    local constants = Constants and Constants.MacroConsts
    local value = constants and constants.MAX_ACCOUNT_MACROS
    return Number(value) and value > 0 and value % 1 == 0 and value or 120
end
local function ReadMacro(index)
    local ok, name, _, body = pcall(GetMacroInfo, index)
    if not ok or not Suite.IsReadable(name) or not Suite.IsReadable(body) then return nil, nil, false end
    if name ~= nil and (not Text(name) or not Text(body)) then return nil, nil, false end
    return name, body, true
end

function Macros:SyncGeneral()
    self:EnsureClassRecipes()
    if InCombatLockdown() or not Suite.macroDB or type(GetMacroInfo) ~= "function" then return end
    local general = {}
    for index = 1, Limit() do
        local name, body, readable = ReadMacro(index)
        if not readable then return end -- An incomplete list cannot establish shared ownership.
        if name then
            if general[name] then general[name].duplicate = true
            else general[name] = { body = body } end
        end
    end
    local function Shared(name)
        local macro, owned = general[name], Suite.db.macroOwnership[name]
        return macro and not macro.duplicate and owned and SameBody(macro.body, owned)
    end
    local db, existing, imports = Suite.macroDB, {}, {}
    for _, entry in ipairs(db.entries) do
        existing[entry.name] = true
        if Shared(entry.name) then
            entry.created = true
            if entry.recipe == "item" and not entry.item then entry.item = SharedItem(Suite.db.macroOwnership[entry.name]) end
        end
    end
    for name, owned in pairs(Suite.db.macroOwnership) do
        local serial = ItemSerial(name)
        if serial then
            db.nextSerial = math.max(db.nextSerial, serial + 1)
            if not existing[name] and not db.ignoredItems[serial] and Shared(name) then
                -- Chosen-item recipes have one exact generated action. Require confirmed
                -- account ownership as well as this shape; an FS prefix alone is insufficient.
                local id = SharedItem(owned)
                if id then
                    imports[#imports + 1] = { recipe = "item", name = name, serial = serial,
                        item = id, created = true, combat = false }
                end
            end
        end
    end
    table.sort(imports, function(first, second) return first.serial < second.serial end)
    for _, entry in ipairs(imports) do
        if ItemCount(db.entries) >= 10 then break end
        db.entries[#db.entries + 1] = entry
    end
end

function Macros:CanSave(entry, body, pending, ready)
    if InCombatLockdown() or pending or not body or not ValidBody(body) or not self:Applicable(entry) then return false end
    local recipe = self.byRecipe[entry.recipe]
    return ready == true or entry.created == true or recipe.slot ~= nil and entry.item == nil
end
function Macros:Find(name)
    if type(GetMacroInfo) ~= "function" then return nil, "Macro information is unavailable." end
    local found, saved
    for index = 1, Limit() do
        local current, body, readable = ReadMacro(index)
        if not readable then return nil, "Macro information is unavailable. Existing macros are kept." end
        if current == name then
            if found then return nil, "Duplicate names in General macros. Rename one in Blizzard's Macros window." end
            found, saved = index, body
        end
    end
    return found, nil, saved
end

local function EditorOpen()
    if MacroFrame and type(MacroFrame.IsShown) == "function" then
        local ok, shown = pcall(MacroFrame.IsShown, MacroFrame)
        return not ok or not Suite.IsReadable(shown) or shown
    end
    return false
end
function Macros:Owned(entry, replaceEdited)
    local index, problem, old = self:Find(entry.name)
    if problem then return nil, problem end
    if index then
        local owned = Suite.db.macroOwnership[entry.name]
        if not owned then return nil, "That General macro name is already in use. Rename it in Blizzard's Macros window." end
        if not SameBody(old, owned) and replaceEdited ~= true then
            return nil, "Edited outside Suite. Automatic updates paused. Click Update macro to replace it with the preview."
        end
    end
    return index, nil, old
end
function Macros:Write(entry, body, explicit, replaceEdited)
    if InCombatLockdown() then return false, "Create or update after combat." end
    if not self:Applicable(entry) then return false, "This recipe is for another class." end
    if EditorOpen() then return false, "Close Blizzard's Macros window before updating." end
    if not ValidName(entry.name) or not ValidBody(body) then return false, "This macro exceeds the game's name or text limit." end
    if type(CreateMacro) ~= "function" or type(EditMacro) ~= "function" or type(GetNumMacros) ~= "function" then
        return false, "Macro creation is unavailable in this client."
    end
    local index, problem, old = self:Owned(entry, replaceEdited)
    if problem then return false, problem end
    if not index and not explicit then return false, "Macro missing. Click Create to make it again." end
    if index and SameBody(old, body) then
        entry.created = true; self:WatchUses(); return true, "Current in General macros."
    end
    self.writing = true
    local ok, result
    if index then ok, result = pcall(EditMacro, index, nil, nil, body)
    else
        local read, count = pcall(GetNumMacros)
        if not read or not Number(count) or count >= Limit() then self.writing = nil; return false, "General macro slots are full or unavailable." end
        ok, result = pcall(CreateMacro, entry.name, 134400, body, false)
    end
    self.writing = nil
    if not ok or not Number(result) or result < 1 or result % 1 ~= 0 or result > Limit() then
        return false, "The client could not save this General macro."
    end
    local name, saved, readable = ReadMacro(result)
    if not readable or name ~= entry.name or not SameBody(saved, body) then return false, "The client did not confirm the saved macro." end
    Suite.db.macroOwnership[name], entry.created = saved, true
    self:WatchUses()
    return true, "Saved in General macros. Drag it from Blizzard's Macros window to an action bar."
end

function Macros:Notify()
    if self.visible and Suite.GUI.RefreshMacros then Suite.GUI:RefreshMacros() end
end

-- Called only by the explicit slash command in the user's action-bar macro.
-- Keep its text stable; changing only the native icon retains ownership and slot.
function Macros:RandomMount()
    if InCombatLockdown() then return end
    local entry
    for _, record in ipairs(Suite.macroDB and Suite.macroDB.entries or {}) do
        if record.recipe == "randomMount" and record.created then entry = record; break end
    end
    if not entry then return end
    local function Problem(message)
        self.statuses[entry], self.statusErrors[entry] = message, true
        Suite.Print(message)
        self:Notify()
    end
    if EditorOpen() then Problem("Close Blizzard's Macros window before using Random mount."); return end
    local index, problem, body = self:Owned(entry)
    if problem or not index then Problem(problem or "Create the Random mount macro again."); return end
    if type(IsMounted) ~= "function" then Problem("Mounted status is unavailable in this client."); return end
    local checked, mounted = pcall(IsMounted)
    if not checked or not Suite.IsReadable(mounted) or type(mounted) ~= "boolean" then
        Problem("Mounted status is unavailable. Try again shortly."); return
    end
    if mounted then
        if type(Dismount) ~= "function" or not pcall(Dismount) then
            Problem("The client could not dismount."); return
        end
        self.statuses[entry], self.statusErrors[entry] = "Dismount requested.", false
        self:Notify()
        return -- Never choose, update the icon or summon again on this press.
    end
    local journal = C_MountJournal
    if not journal or type(journal.GetMountIDs) ~= "function" or type(journal.GetMountInfoByID) ~= "function"
        or type(journal.GetMountUsabilityByID) ~= "function" or type(journal.SummonByID) ~= "function"
        or type(EditMacro) ~= "function" then
        Problem("Mount information is unavailable in this client."); return
    end
    local ok, ids = pcall(journal.GetMountIDs)
    if not ok or not Suite.IsReadable(ids) or type(ids) ~= "table" then
        Problem("Mount information is loading or unavailable."); return
    end
    local choices, seen = {}, {}
    for _, id in ipairs(ids) do
        if ItemID(id) and not seen[id] then
            seen[id] = true
            local read, name, _, icon, _, usable, _, _, _, _, hidden, collected = pcall(journal.GetMountInfoByID, id)
            if read and Suite.IsReadable(usable) and Suite.IsReadable(hidden) and Suite.IsReadable(collected)
                and usable == true and collected == true and hidden == false
                and Number(icon) and icon > 0 and icon % 1 == 0 then
                local checked, available = pcall(journal.GetMountUsabilityByID, id, true)
                if checked and Suite.IsReadable(available) and available == true then
                    choices[#choices + 1] = { id = id, icon = icon, name = Text(name) and name or "Mount" }
                end
            end
        end
    end
    if #choices == 0 then Problem("No collected mounts can be used here yet. Check riding requirements and your location."); return end
    local selected = choices[math.random(#choices)]
    self.writing = true
    local changed, result = pcall(EditMacro, index, nil, selected.icon, body)
    self.writing = nil
    if not changed or not Number(result) or result ~= index then Problem("The client could not update the mount icon."); return end
    local name, saved, readable = ReadMacro(index)
    if not readable or name ~= entry.name or not SameBody(saved, body) then
        Problem("The client did not confirm the mount macro."); return
    end
    local summoned = pcall(journal.SummonByID, selected.id)
    if not summoned then Problem("The client could not summon the selected mount."); return end
    -- Selection is not proof of a successful cast; native riding/location rules apply.
    self.statuses[entry], self.statusErrors[entry] = "Selected: " .. selected.name, false
    self:Notify()
end
function Macros:Refresh(refreshItems)
    if InCombatLockdown() then self.dirty = true; self:Notify(); return end
    self:SyncGeneral()
    self.refreshes = (self.refreshes or 0) + 1
    local includeItems = refreshItems ~= false or self.visible
    if includeItems then self.snapshot = Items:Scan() end
    if Suite.db.macroUpdates then
        for _, entry in ipairs(Suite.macroDB.entries) do
            if entry.created and self:Applicable(entry) and (refreshItems ~= false or not self:ItemRecipe(entry)) then
                local body, note, pending, ready = self:Generate(entry, self.snapshot)
                self.statusErrors[entry] = pending == true
                if not pending and body then
                    local detail = note
                    local ok, status = self:Write(entry, body, false)
                    self.statusErrors[entry] = not ok
                    note = ok and self.byRecipe[entry.recipe].foodChoice and detail or ok and not ready and self.byRecipe[entry.recipe].slot
                        and "Waiting for a suitable weapon and carried coating." or status
                end
                self.statuses[entry] = note
            end
        end
    end
    self.dirty = false
    self:Notify()
end
function Macros:Status()
    self:SyncGeneral()
    Suite.Print("Class spell updates: " .. (Suite.db.macroUpdates and "On" or "Off") .. " · item macros: login/reload and after use"
        .. " · completed refreshes: " .. (self.refreshes or 0) .. " · item checks: " .. (self.useChecks or 0))
    Suite.Print("Last macro event: " .. (self.lastEvent or "none since reload")
        .. (self.timer and " · refresh queued" or " · no refresh queued"))
    local snapshot, count = Items:Scan(), 0
    for _, entry in ipairs(Suite.macroDB.entries) do
        if entry.created and self:Applicable(entry) then
            count = count + 1
            local body, note, pending = self:Generate(entry, snapshot)
            local detail = note
            if not pending and body then
                if EditorOpen() then note = "Close Blizzard's Macros window before updating."
                else
                    local index, problem, old = self:Owned(entry)
                    if problem then note = problem
                    elseif not index then note = "Macro missing. Click Create to make it again."
                    elseif SameBody(old, body) then note = "Current in General macros."
                    elseif self:ItemRecipe(entry) then note = "Item macros are checked after use."
                    elseif not Suite.db.macroUpdates then note = "Class spell updates are Off."
                    else note = "Supplies changed. Last update: " .. (self.statuses[entry] or "awaiting an event.") end
                end
                if self.byRecipe[entry.recipe].foodChoice then note = note .. " " .. detail end
            end
            Suite.Print(entry.name .. ": " .. (note or "Waiting for supplies."))
        end
    end
    if count == 0 then Suite.Print("No created macros are tracked on this character.") end
end
function Macros:Save(entry, existingOnly)
    if InCombatLockdown() then self.statusErrors[entry] = true; self.statuses[entry] = "Click Create / update after combat."; self:Notify(); return false end
    self.snapshot = Items:Scan()
    local body, note, pending, ready = self:Generate(entry, self.snapshot)
    local detail = note
    local ok = false
    if self:CanSave(entry, body, pending, ready) then
        -- Only Create/Update explicitly approves replacing previously owned text.
        -- Food-picker saves and background work retain external-edit protection.
        ok, note = self:Write(entry, body, existingOnly ~= true, existingOnly ~= true)
        if ok and self.byRecipe[entry.recipe].foodChoice then note = note .. " " .. detail end
        if ok and not ready then
            if self.byRecipe[entry.recipe].slot then
                note = "Placeholder saved. Use this macro again after equipping a suitable weapon and carrying its coating."
            else note = "No suitable supplies. The old automatic action was cleared." end
        end
    end
    self.statuses[entry] = note
    self.statusErrors[entry] = not ok
    self:Notify()
    return ok
end
function Macros:Cancel()
    if self.timer then self.timer:Cancel(); self.timer = nil end
end
function Macros:Queue()
    self.dirty = true
    if InCombatLockdown() or self.timer or not (Suite.db.macroUpdates or self.visible) then return end
    if C_Timer and type(C_Timer.NewTimer) == "function" then
        self.timer = C_Timer.NewTimer(0.15, function() self.timer = nil; self:Refresh(false) end)
    end
end
function Macros:SetVisible(visible)
    self.visible = visible == true
    self:Apply()
end
function Macros:WatchEditor()
    local frame = MacroFrame
    if not frame or frame == self.editor or type(frame.HookScript) ~= "function" then return end
    self.editor = frame
    frame:HookScript("OnHide", function()
        if Suite.db.macroUpdates or self.visible then self:Queue() end
        if self.used then self:QueueUsed(0.15) end
    end)
end

-- Passive native execution post-hooks identify only public macro names/indices.
-- They never change secure buttons, native text, action slots or macro execution.
function Macros:ItemRecipe(entry)
    local recipe = self.byRecipe[entry.recipe]
    return recipe and not recipe.spell and not recipe.body and self:Applicable(entry)
end
function Macros:QueueUsed(delay)
    if self.useTimer then self.useTimer:Cancel(); self.useTimer = nil end
    if self.useExpiry then self.useExpiry:Cancel(); self.useExpiry = nil end
    if not self.used or InCombatLockdown() or EditorOpen() then return end
    if not C_Timer or type(C_Timer.NewTimer) ~= "function" then return end
    self.useTimer = C_Timer.NewTimer(delay, function() self.useTimer = nil; self:CheckUsed() end)
end
function Macros:FinishUsed()
    if self.useTimer then self.useTimer:Cancel(); self.useTimer = nil end
    if self.useExpiry then self.useExpiry:Cancel(); self.useExpiry = nil end
    self.used, self.useWaiting, self.useBagWaiting = nil, nil, nil
    if self.useEvents then self.useEvents:UnregisterAllEvents() end
end
function Macros:CheckUsed()
    if not self.used or InCombatLockdown() then return end
    self:WatchEditor()
    if EditorOpen() then return end
    self.useChecks = (self.useChecks or 0) + 1
    local snapshot = Items:Scan()
    self.useWaiting = {}
    self.useBagWaiting = snapshot.incomplete == true
    for entry in pairs(self.used) do
        local present = false
        for _, record in ipairs(Suite.macroDB.entries) do if record == entry then present = true; break end end
        if present and entry.created and self:ItemRecipe(entry) then
            local owned = Suite.db.macroOwnership[entry.name]
            local id = Text(owned) and (owned:match("\n/use item:(%d+)") or owned:match("\n/use %[%s*nocombat%s*%] item:(%d+)"))
            local body, note, pending = self:Generate(entry, snapshot, id and tonumber(id))
            if not pending then
                local ok
                if body then ok, note = self:Write(entry, body, false) end
                self.statuses[entry], self.statusErrors[entry] = note, not ok
                self.used[entry] = nil
            else
                self.statuses[entry], self.statusErrors[entry] = note, true
                for id in pairs(snapshot.pendingByID or {}) do self.useWaiting[id] = true end
                -- Await only this scan's requested metadata, with a bounded cleanup
                -- timer that performs no further scan. No bag/event polling.
                if not self.useExpiry then
                    self.useExpiry = C_Timer.NewTimer(2, function() self:FinishUsed() end)
                end
            end
        else self.used[entry] = nil end
    end
    if not next(self.used) then self:FinishUsed() end
    self:Notify()
end
function Macros:Used(macro)
    if not Suite.IsReadable(macro) then return end
    local name = macro
    if Number(macro) and macro >= 1 and macro % 1 == 0 and macro <= Limit() then
        name = ReadMacro(macro)
    end
    if not ValidName(name) then return end
    for _, entry in ipairs(Suite.macroDB and Suite.macroDB.entries or {}) do
        if entry.name == name and entry.created and self:ItemRecipe(entry) then
            if not self.useEvents then return end -- Prepared outside combat by WatchUses.
            self.used = self.used or {}; self.used[entry] = true
            self.lastEvent = "Item macro: " .. name
            self.useWaiting = nil
            self.useBagWaiting = nil
            if self.useExpiry then self.useExpiry:Cancel(); self.useExpiry = nil end
            for _, event in ipairs({ "BAG_UPDATE_DELAYED", "GET_ITEM_INFO_RECEIVED", "ITEM_DATA_LOAD_RESULT",
                "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_LOGOUT" }) do self.useEvents:RegisterEvent(event) end
            self:QueueUsed(1) -- One fallback check if an attempted use produces no bag event.
            return
        end
    end
end
function Macros:CheckFood(reason)
    for _, entry in ipairs(Suite.macroDB and Suite.macroDB.entries or {}) do
        if entry.recipe == "food" and entry.created then
            self:Used(entry.name)
            self.lastEvent = reason
            self:QueueUsed(0.15)
            return
        end
    end
end
function Macros:WatchUses()
    if InCombatLockdown() then Suite.AfterCombat("macroUseWatch", function() self:WatchUses() end); return end
    Suite.pending.macroUseWatch = nil
    if not Suite.macroDB or type(hooksecurefunc) ~= "function" then return end
    local needed = false
    for _, entry in ipairs(Suite.macroDB.entries) do
        if entry.created and self:ItemRecipe(entry) then needed = true; break end
    end
    if not needed then return end
    -- Native combined and individual bag opens both show these frames. BAG_OPEN
    -- alone does not cover the ordinary Lua toggle paths on build 70862.
    self.bagWatch = self.bagWatch or {}
    local function Watch(frame)
        if not frame or self.bagWatch[frame] or type(frame.HookScript) ~= "function" then return end
        self.bagWatch[frame] = true
        frame:HookScript("OnShow", function(owner)
            local id = owner.GetID and owner:GetID()
            if not Number(id) or id < 0 or id > 5 or id % 1 ~= 0 then return end
            self:CheckFood("Bags opened")
        end)
    end
    Watch(ContainerFrameCombinedBags)
    local count = Number(NUM_CONTAINER_FRAMES) and math.min(20, NUM_CONTAINER_FRAMES) or 7
    for index = 1, count do Watch(_G["ContainerFrame" .. index]) end
    if not self.useEvents then
        self.useEvents = CreateFrame("Frame")
        self.useEvents:SetScript("OnEvent", function(_, event, id)
            if event == "PLAYER_LOGOUT" then self:FinishUsed(); return end
            if not self.used then return end
            if event == "PLAYER_REGEN_DISABLED" then
                if self.useTimer then self.useTimer:Cancel(); self.useTimer = nil end
                if self.useExpiry then self.useExpiry:Cancel(); self.useExpiry = nil end
            elseif event == "GET_ITEM_INFO_RECEIVED" or event == "ITEM_DATA_LOAD_RESULT" then
                if ItemID(id) and self.useWaiting and self.useWaiting[id] then self:QueueUsed(0.15) end
            elseif not self.useWaiting or self.useBagWaiting or event == "PLAYER_REGEN_ENABLED" then self:QueueUsed(0.15) end
        end)
    end
    -- Keep food inventory observation separate from the temporary data/use wait:
    -- FinishUsed releases that wait, but new stock must still prepare FS Food.
    if not self.foodEvents then
        self.foodEvents = CreateFrame("Frame")
        self.foodEvents:SetScript("OnEvent", function(_, event) self:CheckFood(event) end)
        self.foodEvents:RegisterEvent("BAG_UPDATE_DELAYED")
        self.foodEvents:RegisterEvent("PLAYER_LEVEL_UP")
    end
    if not self.runHook and type(RunMacro) == "function" then
        hooksecurefunc("RunMacro", function(macro) self:Used(macro) end); self.runHook = true
    end
    if not self.actionHook and type(UseAction) == "function" then
        hooksecurefunc("UseAction", function(action)
            if not Number(action) or action < 1 or action % 1 ~= 0 or not C_ActionBar
                or type(C_ActionBar.GetActionText) ~= "function" then return end
            -- Generated Suite macros all have #showtooltip. Use the native
            -- predicate rather than assuming a resolved legacy action tuple.
            if type(C_ActionBar.IsMacroActionWithShowTooltip) == "function" then
                local read, macro = pcall(C_ActionBar.IsMacroActionWithShowTooltip, action)
                if not read or not Suite.IsReadable(macro) or macro ~= true then return end
            else
                if type(GetActionInfo) ~= "function" then return end
                local read, kind = pcall(GetActionInfo, action)
                if not read or not Text(kind) or kind ~= "macro" then return end
            end
            local ok, name = pcall(C_ActionBar.GetActionText, action)
            if ok and Suite.IsReadable(name) then self:Used(name) end
        end)
        self.actionHook = true
    end
    self:WatchEditor()
end
function Macros:CheckAtLogin()
    if self.loginChecked or not Suite.macroDB then return end
    self.loginChecked = true
    Suite.AfterCombat("macroLogin", function()
        Suite.pending.macroLogin = nil
        self:SyncGeneral(); self:WatchUses()
        for _, entry in ipairs(Suite.macroDB.entries) do
            if entry.created and self:ItemRecipe(entry) then self:Used(entry.name) end
        end
    end)
end
function Macros:Apply()
    if not Suite.macroDB then return end
    self:SyncGeneral()
    self:WatchUses()
    local active = Suite.db.macroUpdates or self.visible
    if not active then
        self:Cancel()
        if self.events then self.events:UnregisterAllEvents() end
        return
    end
    if not self.events then
        self.events = CreateFrame("Frame")
        self.events:SetScript("OnEvent", function(_, event, id)
            if event == "UNIT_PET" and (not Text(id) or id ~= "player") then return end
            if event == "UNIT_LEVEL" and (not Text(id) or id ~= "pet") then return end
            if event == "UNIT_PET" or event == "UNIT_LEVEL" then
                for _, entry in ipairs(Suite.macroDB.entries) do
                    if self.byRecipe[entry.recipe].foodChoice then self.statuses[entry] = nil end
                end
            end
            if event == "UPDATE_MACROS" and self.writing then return end
            if event == "PLAYER_REGEN_DISABLED" then self:Cancel(); self.dirty = true; self:Notify(); return end
            if event == "GET_ITEM_INFO_RECEIVED" then
                if not Number(id) or not Items.requested[id] then return end
                -- Keep the request marker even on failure; do not loop on failed data loads.
            end
            if event == "ADDON_LOADED" then
                if not Text(id) or id ~= "Blizzard_MacroUI" then return end
                self:WatchEditor()
            end
            self.lastEvent = event
            self:Queue()
        end)
    end
    self.events:UnregisterAllEvents()
    for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP", "SPELLS_CHANGED",
        "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "UPDATE_MACROS", "ADDON_LOADED" }) do self.events:RegisterEvent(event) end
    if self.visible then
        for _, event in ipairs({ "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "GET_ITEM_INFO_RECEIVED", "UNIT_PET", "UNIT_LEVEL" }) do
            self.events:RegisterEvent(event)
        end
    end
    self:WatchEditor()
    self:Queue()
end
