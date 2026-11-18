local _, Suite = ...
local Planner = Suite.TalentPlanner
-- Game spell IDs and ordered selections from 54 Icy Veins Forever guides.
-- Reviewed November 16, 2026; calculator revision 70755. No guide prose/assets/code.
local spells = {
    DRUID = { ["0"]=16814,["1"]=1223081,["2"]=16845,["3"]=16821,["4"]=1223082,["5"]=16819,["6"]=16918,["7"]=1223083,["8"]=5570,["9"]=16909,["A"]=17063,["B"]=17003,["C"]=17069,["D"]=17106,["E"]=16833,["F"]=17118,["G"]=17104,["H"]=1328621,["I"]=24968,["J"]=17111,["K"]=18562,["L"]=17116,["M"]=1309631,["N"]=17123,["O"]=17074,["P"]=408120,["a"]=16850,["b"]=17245,["c"]=16880,["d"]=408248,["e"]=16896,["f"]=24858,["g"]=16934,["h"]=17056,["i"]=17002,["j"]=16947,["k"]=16940,["l"]=16929,["m"]=16966,["n"]=16998,["o"]=1238122,["p"]=16942,["q"]=1328613,["r"]=1328617,["s"]=16972,["t"]=16958,["u"]=1322605,["v"]=17007,["w"]=1223242,["x"]=417051,["y"]=1223246,["z"]=407995 },
    HUNTER = { ["0"]=19552,["1"]=19583,["2"]=1223755,["3"]=19549,["4"]=19559,["5"]=24443,["6"]=19596,["7"]=19616,["8"]=19572,["9"]=19598,["A"]=19255,["B"]=19228,["C"]=19239,["D"]=19290,["E"]=19263,["F"]=19376,["G"]=1310627,["H"]=19306,["I"]=440529,["J"]=1310532,["K"]=1310496,["L"]=1317257,["M"]=19168,["N"]=1310533,["a"]=1293241,["b"]=19578,["c"]=19577,["d"]=19590,["e"]=19621,["f"]=19574,["g"]=19498,["h"]=19407,["i"]=19426,["j"]=1310661,["k"]=19416,["l"]=1223984,["m"]=415405,["n"]=19454,["o"]=415370,["p"]=1299346,["q"]=19485,["r"]=1223987,["s"]=19461,["t"]=19503,["u"]=19507,["v"]=1310687,["w"]=24293,["x"]=19295,["y"]=19184,["z"]=19159 },
    MAGE = { ["0"]=6057,["2"]=11237,["3"]=28574,["4"]=11210,["5"]=29441,["6"]=11213,["7"]=400588,["8"]=11247,["9"]=11242,["A"]=11189,["B"]=11070,["C"]=29438,["D"]=11207,["E"]=11071,["F"]=11165,["G"]=11175,["H"]=11160,["I"]=11185,["J"]=1312002,["K"]=16757,["L"]=11958,["M"]=11170,["N"]=11190,["O"]=12472,["P"]=400647,["Q"]=11180,["R"]=11426,["a"]=400574,["b"]=11252,["c"]=11255,["d"]=18462,["e"]=1326079,["f"]=12043,["g"]=11232,["h"]=15058,["i"]=12042,["j"]=11078,["k"]=18459,["l"]=11069,["m"]=11119,["n"]=11100,["o"]=11103,["p"]=11083,["q"]=11108,["r"]=11366,["s"]=11095,["t"]=11094,["u"]=400624,["v"]=29074,["w"]=11115,["x"]=11113,["y"]=11124,["z"]=11129 },
    PALADIN = { ["0"]=1328546,["1"]=20257,["2"]=20237,["3"]=20205,["4"]=20224,["5"]=9453,["6"]=1328548,["7"]=1310899,["8"]=429144,["9"]=426065,["A"]=1237268,["B"]=20117,["C"]=9452,["D"]=1311074,["E"]=20375,["F"]=26022,["G"]=9799,["H"]=1311087,["I"]=20111,["J"]=20049,["K"]=20066,["L"]=1311084,["N"]=1310735,["O"]=20262,["P"]=1328550,["Q"]=1328370,["a"]=20210,["b"]=20216,["c"]=1310904,["d"]=1311606,["e"]=1310905,["f"]=5923,["g"]=1310911,["h"]=20143,["i"]=20127,["j"]=20189,["k"]=20174,["l"]=20096,["m"]=1328544,["n"]=20468,["o"]=20150,["p"]=1224697,["q"]=1310994,["s"]=20487,["t"]=1311015,["u"]=20177,["v"]=1311034,["w"]=20925,["x"]=20060,["y"]=20101,["z"]=25956 },
    PRIEST = { ["0"]=1309969,["1"]=14524,["2"]=1225132,["3"]=14523,["4"]=1309957,["5"]=18551,["6"]=14531,["7"]=14520,["8"]=14751,["9"]=14748,["A"]=15326,["B"]=15270,["C"]=15273,["D"]=15275,["E"]=17322,["F"]=15392,["G"]=15407,["H"]=1225139,["I"]=1326159,["J"]=15286,["K"]=15257,["L"]=15487,["M"]=1309950,["N"]=1310076,["O"]=15259,["P"]=15473,["a"]=14521,["b"]=14747,["c"]=14750,["d"]=402000,["e"]=402174,["f"]=425280,["g"]=431622,["h"]=10060,["i"]=14913,["j"]=14908,["k"]=14889,["l"]=27900,["m"]=18530,["n"]=15237,["o"]=27811,["p"]=14892,["q"]=27789,["r"]=14912,["s"]=14909,["t"]=1328569,["u"]=1317006,["v"]=20711,["w"]=14901,["x"]=14898,["y"]=401859,["z"]=15260 },
    ROGUE = { ["0"]=13741,["1"]=14144,["2"]=14138,["3"]=14156,["4"]=14983,["5"]=14165,["6"]=1329265,["7"]=14168,["8"]=14128,["9"]=16513,["A"]=14057,["B"]=13983,["C"]=13981,["D"]=1224782,["E"]=14079,["F"]=13976,["G"]=14278,["I"]=30894,["J"]=14183,["K"]=14171,["L"]=14082,["M"]=14185,["N"]=16511,["O"]=1310728,["P"]=1329286,["Q"]=1316709,["R"]=14179,["S"]=13715,["a"]=14177,["b"]=14113,["c"]=1329256,["d"]=399956,["e"]=14174,["f"]=14186,["g"]=1329328,["h"]=14162,["i"]=13732,["j"]=13712,["k"]=1224716,["l"]=13713,["m"]=13705,["n"]=13742,["o"]=14251,["p"]=13743,["q"]=13754,["r"]=1310711,["s"]=1329284,["t"]=13877,["u"]=13960,["v"]=30919,["w"]=18427,["x"]=13750,["y"]=13975,["z"]=13958 },
    SHAMAN = { ["0"]=16039,["1"]=16035,["2"]=30160,["3"]=16040,["4"]=16578,["5"]=16038,["6"]=16164,["7"]=28996,["8"]=16086,["9"]=29062,["A"]=1223033,["B"]=29187,["C"]=16173,["D"]=16184,["E"]=16176,["F"]=16181,["G"]=408510,["H"]=16194,["I"]=16187,["J"]=16190,["K"]=29206,["L"]=16188,["M"]=16178,["N"]=408521,["a"]=1222988,["b"]=28999,["c"]=16120,["d"]=408438,["e"]=16089,["f"]=16166,["g"]=16043,["h"]=16255,["i"]=17485,["j"]=16258,["k"]=415140,["l"]=16262,["m"]=16261,["n"]=16266,["o"]=1223030,["p"]=16254,["q"]=16252,["r"]=16256,["s"]=17364,["t"]=16268,["u"]=30812,["v"]=1223031,["w"]=408498,["x"]=425336,["y"]=16182,["z"]=16179 },
    WARLOCK = { ["0"]=18182,["1"]=18174,["2"]=17810,["3"]=18218,["4"]=437032,["5"]=403511,["6"]=18827,["7"]=17783,["8"]=18288,["9"]=427712,["A"]=17917,["B"]=17793,["C"]=17788,["D"]=1225220,["E"]=17778,["F"]=18119,["G"]=17959,["H"]=17877,["I"]=18135,["J"]=17927,["K"]=1293817,["L"]=18073,["M"]=1225228,["N"]=412751,["O"]=426316,["P"]=412758,["a"]=1310949,["b"]=18094,["c"]=18223,["d"]=18265,["e"]=17804,["f"]=18271,["g"]=1316697,["h"]=18703,["i"]=18694,["j"]=18697,["k"]=18769,["l"]=1235316,["m"]=18705,["n"]=18731,["o"]=1225214,["p"]=18754,["q"]=18788,["r"]=18709,["s"]=440870,["t"]=18708,["u"]=1293695,["v"]=1225217,["w"]=19028,["x"]=412732,["y"]=23785,["z"]=425464 },
    WARRIOR = { ["0"]=12282,["1"]=16462,["2"]=12286,["3"]=12285,["4"]=12295,["5"]=12290,["6"]=12296,["7"]=12834,["8"]=1310222,["9"]=12163,["A"]=12962,["B"]=12297,["C"]=12797,["D"]=12287,["E"]=12975,["F"]=1310316,["G"]=12313,["H"]=12792,["I"]=12308,["J"]=1310317,["K"]=12311,["L"]=12312,["M"]=12809,["N"]=29787,["O"]=16538,["P"]=23922,["Q"]=1329555,["a"]=16493,["b"]=1289682,["c"]=12292,["d"]=1290261,["e"]=12862,["f"]=12289,["g"]=12294,["h"]=12321,["i"]=12320,["j"]=1323964,["k"]=12322,["l"]=1323963,["m"]=12323,["n"]=16487,["o"]=23584,["p"]=1310315,["q"]=12317,["r"]=20502,["s"]=20500,["t"]=12328,["u"]=20504,["v"]=12319,["w"]=1323967,["x"]=23881,["y"]=12301,["z"]=12298 },
}
Planner.presets, Planner.starters = {}, {}
local function Add(class, spec, kind, variant, name, slug, order)
    local data = { id = slug .. ":" .. variant, spec = spec, kind = kind, name = name,
        source = "https://www.icy-veins.com/wow-forever/" .. slug, reviewed = "2026-11-16",
        order = order, spells = spells[class],
        tip = kind == "World" and "Full allocation for open-world and PvP play; not a level-by-level schedule."
            or kind == "Leveling" and "Level-by-level reference; bonus talent points may change your timing."
            or "Endgame PvE allocation. The displayed point order is a reference, not a leveling recommendation." }
    Planner.presets[class] = Planner.presets[class] or {}
    table.insert(Planner.presets[class], data)
    return data
end
Add("DRUID", "Balance", "Leveling", "1", "Balance Leveling Build", "balance-druid-leveling", "00000AAAAADDD554427223381111c1CCCCCdddeeeeefaaaaa99")
Planner.starters.DRUID = Add("DRUID", "Feral", "Leveling", "1", "Feral Leveling Build", "feral-druid-leveling", "gggggjjjiionnpprttqsvwwssyyyyyzuBBBBBCCCCC111115544")
Add("DRUID", "Restoration", "Leveling", "1", "Restoration Leveling Build", "restoration-druid-leveling", "00000AAAAADDD55442722118CCHCCCGKGGGGLMMMJJJOOOOOP11")
Add("DRUID", "Balance", "PvE", "1", "Balance PvE Build", "balance-druid-ranged-dps-pve-spec-builds-talents", "000001111122233447999998aaaaacdddeeeeefAAAAACCCCC55")
Add("DRUID", "Feral", "PvE", "1", "Feral Hybrid PvE", "feral-druid-melee-dps-and-tank-pve-spec-builds-talents", "gggggjjjiionnpprqsvwwssyyyyyzBBBBBCCCCC11111455ulll")
Add("DRUID", "Feral", "PvE", "2", "Feral Tank PvE", "feral-druid-melee-dps-and-tank-pve-spec-builds-talents", "gggggjjjiionnpprsvwwssyyyyyzBBBBBCCCCC11111455lll4t")
Add("DRUID", "Feral", "PvE", "3", "Feral Cat PvE", "feral-druid-melee-dps-and-tank-pve-spec-builds-talents", "gggggiionnppsvwwssyyyyyBBBBBCCCCC11111454tthhhmmmqu")
Add("DRUID", "Restoration", "PvE", "1", "Restoration PvE Build", "restoration-druid-healer-pve-spec-builds-talents", "0000055BBBBBCCCCCDDDGGGGGHJJJKMMMLOOOOOP11111447228")
Planner.starters.HUNTER = Add("HUNTER", "Beast Mastery", "Leveling", "1", "Beast Mastery Leveling Build", "beast-mastery-hunter-leveling", "000002255144677a7779dd9999ceeefeiiiiilllllmmwwwwwjj")
Add("HUNTER", "Marksmanship", "Leveling", "1", "Marksmanship Leveling Build", "marksmanship-hunter-leveling", "iiiiilllllmmjjjpqqqqrrqssuuuuuv0000022551446s77a777")
Add("HUNTER", "Survival", "Leveling", "1", "Survival Leveling Build", "survival-hunter-leveling", "iiiiiwwwwwzzAAADDDCCGGGGGLJJKKMMMMMNIFFlllllojjjkqq")
Add("HUNTER", "Beast Mastery", "PvE", "1", "Beast Mastery PvE Build", "beast-mastery-hunter-ranged-dps-pve-spec-builds-talents", "0000022551677777a99999cddeeeeefiiiiillllljjjmmqqqqq")
Add("HUNTER", "Beast Mastery", "World", "2", "Beast Mastery World Build", "beast-mastery-hunter-ranged-dps-pve-spec-builds-talents", "000002255144677777a99999cddeeefwwwwwyyyyyDDDCFgggEF")
Add("HUNTER", "Marksmanship", "PvE", "1", "Marksmanship Lone Wolf", "marksmanship-hunter-ranged-dps-pve-spec-builds-talents", "iiiiillllljjjmmqqqqqprrsssuuuuuvwwwww00000kkkkgggko")
Add("HUNTER", "Marksmanship", "PvE", "2", "Marksmanship Pet PvE", "marksmanship-hunter-ranged-dps-pve-spec-builds-talents", "iiiiillllljjjmmqqqqqprrssuuuuuv00000225517777a6wwww")
Add("HUNTER", "Marksmanship", "World", "3", "Marksmanship World Build", "marksmanship-hunter-ranged-dps-pve-spec-builds-talents", "iiiiillllljmmqqqqqprrssuuuuuv00000225517777a644tggg")
Add("HUNTER", "Survival", "PvE", "1", "Survival Melee PvE", "survival-hunter-melee-dps-pve-spec-builds-talents", "iiiiiwwwwwzzAAADDDCCGGGGGJJKKLlll000002211177777a99")
Add("HUNTER", "Survival", "PvE", "2", "Survival Weave PvE", "survival-hunter-melee-dps-pve-spec-builds-talents", "iiiiiwwwwwzzAAADDDCCGGGGGJJIILMMMMMllllljjjonpqqqqq")
Add("HUNTER", "Survival", "PvE", "3", "Survival Ranged PvE", "survival-hunter-melee-dps-pve-spec-builds-talents", "iiiiiwwwwwzzAAADDDCCAAFFxIIJJxMMMMMllllljjjkopqqqq0")
Add("MAGE", "Arcane", "Leveling", "1", "Arcane Leveling Build", "arcane-mage-leveling", "0022277666aCC2266eddd4fggggghhh4ikkkkkllllljjmmrumC")
Add("MAGE", "Fire", "Leveling", "1", "Fire Leveling Build", "fire-mage-leveling", "0022277666aCC2266dddkkkkkllllljjmmrummmsxwwwsyyysvz")
Planner.starters.MAGE = Add("MAGE", "Frost", "Leveling", "1", "Frost Leveling Build", "frost-mage-leveling", "CCBBBEEEBBJDDDDMMMDLPPONNNHHHIRCQQQQQKKGGIIA3330044")
Add("MAGE", "Arcane", "PvE", "1", "Arcane PvE Build", "arcane-mage-ranged-dps-pve-spec-builds-talents", "22222446666677999adddegggggfhhhillkkkkCCCmmmmmkrjju")
Add("MAGE", "Fire", "PvE", "1", "Fire Frostfire PvE", "fire-mage-ranged-dps-pve-spec-builds-talents", "CCCAADDDDDFHHHJMMMLEPPlllllkkkkkmmmmmrjjuvssswwwyyy")
Add("MAGE", "Fire", "PvE", "2", "Fire Arcane PvE", "fire-mage-ranged-dps-pve-spec-builds-talents", "22222446666677adkkkkklllllmmmmmrjjvvvussswwwyyyzCCC")
Add("MAGE", "Frost", "PvE", "1", "Frost Deep PvE", "frost-mage-ranged-dps-pve-spec-builds-talents", "CCBBBBBJDDDDMMMDLPPONNNHHHIRCQQQQQKKGGIIA3330044FFG")
Add("MAGE", "Frost", "PvE", "2", "Frost Raid Mana", "frost-mage-ranged-dps-pve-spec-builds-talents", "003334466666558ddBBBBBCCCDDDDDJKKMMMPPONNNQQQQQLRId")
Add("MAGE", "Frost", "PvE", "3", "Frost Raid Damage", "frost-mage-ranged-dps-pve-spec-builds-talents", "0033344666BBBBBCCCDDDDDJKKMMMPPONNNQQQQQLRIkkkkkHHH")
Add("MAGE", "Frost", "PvE", "4", "Frost AoE Build", "frost-mage-ranged-dps-pve-spec-builds-talents", "AACCCGGGFFDDDDDJIIIHHHMMMPPNNNOR333006666644999dddL")
Add("PALADIN", "Holy", "Leveling", "1", "Holy Leveling Build", "holy-paladin-leveling", "yyyyyBBBzzFF3333377222aaaaa699AAdPPbefffffg11111e44")
Add("PALADIN", "Protection", "Leveling", "1", "Protection Leveling Build", "protection-paladin-leveling", "yyyyyBBBzzFFiiiiijjjppoothhqnnnlwuuuuuvvvlmlllDDDHh")
Planner.starters.PALADIN = Add("PALADIN", "Retribution", "Leveling", "1", "Retribution Leveling Build", "retribution-paladin-leveling", "xxxxxzzBBBFFEDDHIIIDJJJKCLLLLLNOOOOO77444AA4488ccCC")
Add("PALADIN", "Holy", "PvE", "1", "Holy PvE Build", "holy-paladin-healer-pve-spec-builds-talents", "3333322277aaaaab99688dPPAfffffgyyyyyzz11111ppkBBBFF")
Add("PALADIN", "Protection", "PvE", "1", "Protection Deep PvE", "protection-paladin-tank-pve-spec-builds-talents", "iiiiijjjppoothhnnnqlllllwuuuuuvvvmyyyyyBBBzzFFDDHDh")
Add("PALADIN", "Protection", "PvE", "2", "Protection Holy PvE", "protection-paladin-tank-pve-spec-builds-talents", "iiiiijjjppoothhnnnqlwllllvvvOOOOO44444AA7788cc6bdee")
Add("PALADIN", "Retribution", "PvE", "1", "Retribution Wrath PvE", "retribution-paladin-melee-dps-pve-spec-builds-talents", "yyyyyzzBBBDDDEFFIIIH5JJJKLLLLLN11111jjjOOOOO44444AA")
Add("PALADIN", "Retribution", "PvE", "2", "Retribution Shockadin PvE", "retribution-paladin-melee-dps-pve-spec-builds-talents", "yyyyyzzBBBDDDEFFIIIH5JJJKLLLLLOOOOO44444AA877bcc86d")
Add("PRIEST", "Discipline", "Leveling", "1", "Discipline Leveling Build", "discipline-priest-leveling", "11BBBBBiii00000555aaa55999d7effffgfgg7hkkkkkmmmmm78")
Add("PRIEST", "Holy", "Leveling", "1", "Holy Leveling Build", "holy-priest-leveling", "11BBBBBiiijjj22255555aaammmmnpmkkssrrrvuuwwxxxwwyw8")
Planner.starters.PRIEST = Add("PRIEST", "Shadow", "Leveling", "1", "Shadow Leveling Build", "shadow-priest-leveling", "11BBBBBDDCCCGHHCEJIIIIIMMLKOOOOOP22255555aaaiiiKKzz")
Add("PRIEST", "Discipline", "PvE", "1", "Discipline PvE Build", "discipline-priest-healer-pve-spec-builds-talents", "22222555558777aaa999dfffffeggghkkkkkmmmmmiiinpppssq")
Add("PRIEST", "Holy", "PvE", "1", "Holy PvE Build", "holy-priest-healer-pve-spec-builds-talents", "jjjkkkkkmmmmmnpppssrrruuvwwwwwyxxx2222255555aaa8333")
Add("PRIEST", "Shadow", "PvE", "1", "Shadow PvE Build", "shadow-priest-ranged-dps-pve-spec-builds-talents", "zzzzzDDCCCCEGHHJIIIIIKKKMMLOOOOOPiii2222233355aaa55")
Add("ROGUE", "Assassination", "Leveling", "1", "Assassination Leveling Build", "assassination-rogue-leveling", "1122233322c8855a9999gRRRRfffR9dAAAAAhhhjjmmmkkk66nn")
Planner.starters.ROGUE = Add("ROGUE", "Combat", "Leveling", "1", "Combat Leveling Build", "combat-rogue-leveling", "iihhhmmlllom66nrvvwwtuuuusssssxuwSS1122233322c8855a")
Add("ROGUE", "Subtlety", "Leveling", "1", "Subtlety Leveling Build", "subtlety-rogue-leveling", "AAAAAEEEBBKKKJLGByyyNiiMFFFPPPPPQhhh1122233322c8855")
Add("ROGUE", "Assassination", "PvE", "1", "Assassination PvE Build", "assassination-rogue-melee-dps-pve-spec-builds-talents", "2222233355c7788a99999RRRRRgfffdhhhjjmmmkkk66b5nnrvv")
Add("ROGUE", "Combat", "PvE", "1", "Combat Strike PvE", "combat-rogue-melee-dps-pve-spec-builds-talents", "iihhhmmmpp66nnjrvvwwwSStuuuuusssssx2222233377555c8a")
Add("ROGUE", "Combat", "PvE", "2", "Combat Dagger PvE", "combat-rogue-melee-dps-pve-spec-builds-talents", "iihhhkkkmmmnn66wwvvwrSStuuuuusssssx2222233377555c8a")
Add("ROGUE", "Subtlety", "PvE", "1", "Subtlety PvE Build", "subtlety-rogue-melee-dps-pve-spec-builds-talents", "AAAAAEEEBBKKKJLGByyNiiMFFFPPPPPQhhh1122233322c855L8")
Add("SHAMAN", "Elemental", "Leveling", "1", "Elemental Leveling Build", "elemental-shaman-leveling", "111114445565000a8899cddd9eeeeefzzzzzAAADDGhhhhh00ii")
Planner.starters.SHAMAN = Add("SHAMAN", "Enhancement", "Leveling", "1", "Enhancement Leveling Build", "enhancement-shaman-leveling", "hhhhhkkkiionnnisllrrvvtzzzzzAAAuuwCCG11111222556rrr")
Add("SHAMAN", "Restoration", "Leveling", "1", "Restoration Leveling Build", "restoration-shaman-leveling", "zzzzzAAAyyGyyyFJHHHHLKKKHMMMMMNFFEEEhhhhhIIIIIiiiii")
Add("SHAMAN", "Elemental", "PvE", "1", "Elemental Support PvE", "elemental-shaman-ranged-dps-pve-spec-builds-talents", "11111444000055568899dddceeeeef9hhhhzzzzzAAAGCCCCCBJ")
Add("SHAMAN", "Elemental", "PvE", "2", "Elemental Damage PvE", "elemental-shaman-ranged-dps-pve-spec-builds-talents", "11111444000055568899dddceeeeef9hhhhzzzzzAAACCGh0iii")
Add("SHAMAN", "Elemental", "World", "3", "Elemental World Build", "elemental-shaman-ranged-dps-pve-spec-builds-talents", "111114445565000a9998dddc8eeeeefzzzzzAAADDGhhhhh00ii")
Add("SHAMAN", "Enhancement", "PvE", "1", "Enhancement Raid PvE", "enhancement-shaman-melee-dps-pve-spec-builds-talents", "hhhhhkkkiiinnnorrrrrsvvuutllwwwwwx11111555222336388")
Add("SHAMAN", "Enhancement", "PvE", "2", "Enhancement Solo PvE", "enhancement-shaman-melee-dps-pve-spec-builds-talents", "hhhhhiiikkknnnosrrvvuutzzzzzAAA11111222555633388llw")
Add("SHAMAN", "Restoration", "PvE", "1", "Restoration PvE Build", "restoration-shaman-healer-pve-spec-builds-talents", "zzzzzAAAyyGyyyFJHHHHLKKKHMMMMMNFFEEEhhhhhIIIIIiiiii")
Planner.starters.WARLOCK = Add("WARLOCK", "Affliction", "Leveling", "1", "Affliction Leveling Build", "affliction-warlock-leveling", "111122222366999bbaaadjjjjjllnnnqaa30fffffg0eee55577")
Add("WARLOCK", "Demonology", "Leveling", "1", "Demonology Leveling Build", "demonology-warlock-leveling", "kkkkkoonnnrrmmmuuutqwxxxlyyyyyz111122222066999aaaaa")
Add("WARLOCK", "Destruction", "Leveling", "1", "Destruction Leveling Build", "destruction-warlock-leveling", "CCCCCFFFFFHAAGGKIIIJNNNMJOOOOOPJ1111jjjjjllnnnq00GG")
Add("WARLOCK", "Affliction", "PvE", "1", "Affliction PvE Build", "affliction-warlock-ranged-dps-pve-spec-builds-talents", "111112222999aaaaadbb00fffffCCCCCBBBBBGGGGGJJJgeee28")
Add("WARLOCK", "Demonology", "PvE", "1", "Demonology PvE Build", "demonology-warlock-ranged-dps-pve-spec-builds-talents", "CCCCCBBBBBGGGGGJJJ22kkkkkoonnnqppprruuuswxxxyyyyysz")
Add("WARLOCK", "Destruction", "PvE", "1", "Destruction PvE Build", "destruction-warlock-ranged-dps-pve-spec-builds-talents", "1111122jjjjjllnnnqCCCCCFFFFFEEEGGGGGHJJJKMNNNOOOOOP")
Add("WARRIOR", "Arms", "Leveling", "1", "Arms Leveling Build", "arms-warrior-leveling", "22211553344467789997cbbddeedddgiiiiijjjjjqqqqqQyyaa")
Planner.starters.WARRIOR = Add("WARRIOR", "Fury", "Leveling", "1", "Fury Leveling Build", "fury-warrior-leveling", "iiiiikkkkklllqqoooootQssqppvvvx2221133554446yyqq777")
Add("WARRIOR", "Protection", "Leveling", "1", "Protection Leveling Build", "protection-warrior-leveling", "zzzzzCCCDDFFDEHJIIIHNNNMHOOOOOP222iiiiikkkkkqqqqqQ1")
Add("WARRIOR", "Arms", "PvE", "1", "Arms PvE Build", "arms-warrior-melee-dps-pve-spec-builds-talents", "0002224445567778999aabbcdddddeegiiiiikkkkkqqqqqQryy")
Add("WARRIOR", "Fury", "PvE", "1", "Fury PvE Build", "fury-warrior-melee-dps-pve-spec-builds-talents", "0002224445567778aaiiiiikkkkklllqqqqqoooooQsstppvvvx")
Add("WARRIOR", "Protection", "PvE", "1", "Protection PvE Build", "protection-warrior-tank-pve-spec-builds-talents", "zzzzzBBBBBEFFCCCHHHJLLMNNOOOOOP11111iiiiijjjjjqqqqq")
