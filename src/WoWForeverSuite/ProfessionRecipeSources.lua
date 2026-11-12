local _, Suite = ...
-- Recipe-specific acquisition references, reviewed November 12, 2026.
-- See docs/forever-development.md for sources and native-test qualifications.
-- No profession-wide trainer default: vendors, manuals and quests stay distinct.
local points = {
    ["ainethil"] = { map = 1457, x = 0.549, y = 0.24, name = "Ainethil, Darnassus" },
    ["alchemist-pestlezugg"] = { map = 1446, x = 0.509, y = 0.27, name = "Alchemist Pestlezugg, Tanaris" },
    ["algernon"] = { map = 1458, x = 0.517, y = 0.747, name = "Algernon, Undercity" },
    ["arnok"] = { map = 1454, x = 0.342, y = 0.845, name = "Arnok, Orgrimmar" },
    ["balai-lokwein"] = { map = 1445, x = 0.365, y = 0.304, name = "Balai Lok'Wein, Dustwallow Marsh" },
    ["bengus-deepforge"] = { map = 1455, x = 0.524, y = 0.412, name = "Bengus Deepforge, Ironforge" },
    ["betty-quin"] = { map = 1453, x = 0.531, y = 0.738, name = "Betty Quin, Stormwind City" },
    ["brikk-keencraft"] = { map = 1434, x = 0.29, y = 0.755, name = "Brikk Keencraft, Stranglethorn Vale" },
    ["buzzek-bracketswing"] = { map = 1446, x = 0.523, y = 0.277, name = "Buzzek Bracketswing, Tanaris" },
    ["catherine-leland"] = { map = 1453, x = 0.55, y = 0.696, name = "Catherine Leland, Stormwind City" },
    ["daniel-bartlett"] = { map = 1458, x = 0.642, y = 0.376, name = "Daniel Bartlett, Undercity" },
    ["daryl-stack"] = { map = 1424, x = 0.637, y = 0.208, name = "Daryl Stack, Hillsbrad Foothills" },
    ["deneb-walker"] = { map = 1417, x = 0.271, y = 0.588, name = "Deneb Walker, Arathi Highlands" },
    ["derotain"] = { map = 1446, x = 0.514, y = 0.287, name = "Derotain Mudsipper, Tanaris" },
    ["doctor-gregory-victor"] = { map = 1417, x = 0.734, y = 0.368, name = "Doctor Gregory Victor, Arathi Highlands" },
    ["doctor-gustaf-vanhowzen"] = { map = 1445, x = 0.678, y = 0.49, name = "Doctor Gustaf VanHowzen, Dustwallow Marsh" },
    ["doctor-herbert-halsey"] = { map = 1458, x = 0.478, y = 0.732, name = "Doctor Herbert Halsey, Undercity" },
    ["drakk-stonehand"] = { map = 1425, x = 0.134, y = 0.433, name = "Drakk Stonehand, The Hinterlands" },
    ["gearcutter-cogspinner"] = { map = 1455, x = 0.676, y = 0.43, name = "Gearcutter Cogspinner, Ironforge" },
    ["georgio-bolero"] = { map = 1453, x = 0.533, y = 0.815, name = "Georgio Bolero, Stormwind City" },
    ["gikkix"] = { map = 1446, x = 0.667, y = 0.222, name = "Gikkix, Tanaris" },
    ["godan"] = { map = 1454, x = 0.538, y = 0.385, name = "Godan, Orgrimmar" },
    ["groum-stonebeard"] = { map = 1455, x = 0.521, y = 0.419, name = "Groum Stonebeard, Ironforge" },
    ["hahrana-ironhide"] = { map = 1444, x = 0.744, y = 0.431, name = "Hahrana Ironhide, Feralas" },
    ["hgarth"] = { map = 1442, x = 0.492, y = 0.571, name = "Hgarth, Stonetalon Mountains" },
    ["jase-farlane"] = { map = 1423, x = 0.708, y = 0.481, name = "Jase Farlane, Eastern Plaguelands" },
    ["jemma-quikswitch"] = { map = 1455, x = 0.678, y = 0.442, name = "Jemma Quikswitch, Ironforge" },
    ["jhag"] = { map = 1454, x = 0.535, y = 0.384, name = "Jhag, Orgrimmar" },
    ["josef-gregorian"] = { map = 1458, x = 0.706, y = 0.304, name = "Josef Gregorian, Undercity" },
    ["kamari"] = { map = 1454, x = 0.632, y = 0.446, name = "Kamari, Orgrimmar" },
    ["kania"] = { map = 1451, x = 0.52, y = 0.396, name = "Kania, Silithus" },
    ["karolek"] = { map = 1454, x = 0.627, y = 0.444, name = "Karolek, Orgrimmar" },
    ["keena"] = { map = 1417, x = 0.74, y = 0.328, name = "Keena, Arathi Highlands" },
    ["kelsey-yance"] = { map = 1434, x = 0.282, y = 0.744, name = "Kelsey Yance, Stranglethorn Vale" },
    ["kendor-kabonka"] = { map = 1453, x = 0.773, y = 0.529, name = "Kendor Kabonka, Stormwind City" },
    ["kithas"] = { map = 1454, x = 0.537, y = 0.381, name = "Kithas, Orgrimmar" },
    ["kitta-firewind"] = { map = 1429, x = 0.649, y = 0.706, name = "Kitta Firewind, Elwynn Forest" },
    ["kylanna-windwhisper"] = { map = 1444, x = 0.326, y = 0.438, name = "Kylanna Windwhisper, Feralas" },
    ["lawrence-schneider"] = { map = 1453, x = 0.535, y = 0.817, name = "Lawrence Schneider, Stormwind City" },
    ["leonard-porter"] = { map = 1422, x = 0.431, y = 0.843, name = "Leonard Porter, Western Plaguelands" },
    ["lilyssia-nightbreeze"] = { map = 1453, x = 0.557, y = 0.861, name = "Lilyssia Nightbreeze, Stormwind City" },
    ["lizbeth-cromwell"] = { map = 1458, x = 0.811, y = 0.309, name = "Lizbeth Cromwell, Undercity" },
    ["lorelae-wintersong"] = { map = 1450, x = 0.483, y = 0.401, name = "Lorelae Wintersong, Moonglade" },
    ["lucan-cordell"] = { map = 1453, x = 0.531, y = 0.743, name = "Lucan Cordell, Stormwind City" },
    ["magar"] = { map = 1454, x = 0.635, y = 0.5, name = "Magar, Orgrimmar" },
    ["mythrindir"] = { map = 1457, x = 0.61, y = 0.182, name = "Mythrin'dir, Darnassus" },
    ["naal-mistrunner"] = { map = 1456, x = 0.514, y = 0.527, name = "Naal Mistrunner, Thunder Bluff" },
    ["nissa-firestone"] = { map = 1455, x = 0.549, y = 0.585, name = "Nissa Firestone, Ironforge" },
    ["nogg"] = { map = 1454, x = 0.758, y = 0.254, name = "Nogg, Orgrimmar" },
    ["qia"] = { map = 1452, x = 0.612, y = 0.372, name = "Qia, Winterspring" },
    ["randal-worth"] = { map = 1453, x = 0.722, y = 0.628, name = "Randal Worth, Stormwind City" },
    ["rogvar"] = { map = 1435, x = 0.485, y = 0.558, name = "Rogvar, Swamp of Sorrows" },
    ["rotgath-stonebeard"] = { map = 1455, x = 0.519, y = 0.424, name = "Rotgath Stonebeard, Ironforge" },
    ["roxxik"] = { map = 1454, x = 0.76, y = 0.251, name = "Roxxik, Orgrimmar" },
    ["saru-steelfury"] = { map = 1454, x = 0.822, y = 0.23, name = "Saru Steelfury, Orgrimmar" },
    ["sellandus"] = { map = 1453, x = 0.523, y = 0.834, name = "Sellandus, Stormwind City" },
    ["simon-tanner"] = { map = 1453, x = 0.717, y = 0.629, name = "Simon Tanner, Stormwind City" },
    ["snang"] = { map = 1454, x = 0.629, y = 0.494, name = "Snang, Orgrimmar" },
    ["snarl"] = { map = 1454, x = 0.797, y = 0.234, name = "Snarl, Orgrimmar" },
    ["sovik"] = { map = 1454, x = 0.756, y = 0.252, name = "Sovik, Orgrimmar" },
    ["springspindle-fizzlegear"] = { map = 1455, x = 0.685, y = 0.435, name = "Springspindle Fizzlegear, Ironforge" },
    ["tansy-puddlefizz"] = { map = 1455, x = 0.479, y = 0.056, name = "Tansy Puddlefizz, Ironforge" },
    ["telathir"] = { map = 1453, x = 0.556, y = 0.857, name = "Tel'Athir, Stormwind City" },
    ["telonis"] = { map = 1457, x = 0.644, y = 0.215, name = "Telonis, Darnassus" },
    ["thund"] = { map = 1454, x = 0.758, y = 0.244, name = "Thund, Orgrimmar" },
    ["tilli-thistlefuzz"] = { map = 1455, x = 0.608, y = 0.441, name = "Tilli Thistlefuzz, Ironforge" },
    ["timothy-worthington"] = { map = 1445, x = 0.662, y = 0.518, name = "Timothy Worthington, Dustwallow Marsh" },
    ["trixie-quikswitch"] = { map = 1455, x = 0.676, y = 0.431, name = "Trixie Quikswitch, Ironforge" },
    ["ugthok"] = { map = 1454, x = 0.807, y = 0.236, name = "Ug'thok, Orgrimmar" },
    ["ulthir"] = { map = 1457, x = 0.56, y = 0.245, name = "Ulthir, Darnassus" },
    ["una"] = { map = 1456, x = 0.417, y = 0.427, name = "Una, Thunder Bluff" },
    ["werg-thickblade"] = { map = 1420, x = 0.832, y = 0.697, name = "Werg Thickblade, Tirisfal Glades" },
    ["whuut"] = { map = 1454, x = 0.559, y = 0.331, name = "Whuut, Orgrimmar" },
    ["xizzer-fizzbolt"] = { map = 1452, x = 0.608, y = 0.386, name = "Xizzer Fizzbolt, Winterspring" },
    ["yelmak"] = { map = 1454, x = 0.567, y = 0.332, name = "Yelmak, Orgrimmar" },
}
local sources = {}
Suite.ProfessionRecipeSources = sources
local function Add(profession, ids, kind, alliance, horde, note)
    local source = { profession = profession, kind = kind, note = note }
    if horde then source.Alliance, source.Horde = points[alliance], points[horde]
    elseif alliance then source.neutral = points[alliance] end
    for _, id in ipairs(ids) do sources[id] = source end
end

-- Blacksmithing
Add("Blacksmithing", {2660, 3320, 3323}, "Trainer", "groum-stonebeard", "ugthok", nil)
Add("Blacksmithing", {3326, 2666, 2672, 3337}, "Trainer", "rotgath-stonebeard", "snarl", nil)
Add("Blacksmithing", {2742, 9985, 3501, 9920, 7223, 9928, 9993}, "Trainer", "bengus-deepforge", "saru-steelfury", nil)
Add("Blacksmithing", {9959, 16641, 9968}, "Trainer", "brikk-keencraft", nil, "Train Artisan Blacksmithing if required.")
Add("Blacksmithing", {16647, 16649, 16657, 16730}, "Quest", "derotain", nil, "Imperial Plate plan quests require Thorium Bars. Check native level and skill prerequisites.")

-- Alchemy
Add("Alchemy", {1245246, 7183, 2331}, "Trainer", "telathir", "whuut", nil)
Add("Alchemy", {2334, 3171, 3173, 7837}, "Trainer", "lilyssia-nightbreeze", "yelmak", nil)
Add("Alchemy", {7845, 3452}, "Trainer", "ainethil", "doctor-herbert-halsey", nil)
Add("Alchemy", {11465}, "Trainer", "kylanna-windwhisper", "rogvar", "Train Artisan Alchemy if required.")
Add("Alchemy", {7259}, "Vendor", "alchemist-pestlezugg", nil, "Buy Recipe: Nature Protection Potion on this alchemist; it binds on pickup.")
Add("Alchemy", {17553}, "Vendor", "ulthir", "algernon", "Buy and learn Recipe: Superior Mana Potion.")

-- Engineering
Add("Engineering", {3918, 3922, 3923}, "Trainer", "jemma-quikswitch", "thund", nil)
Add("Engineering", {7430, 3929, 3931, 3973, 3938, 3978}, "Trainer", "trixie-quikswitch", "nogg", nil)
Add("Engineering", {3945, 3942, 3953, 3955, 12585, 12590, 12589}, "Trainer", "springspindle-fizzlegear", "roxxik", nil)
Add("Engineering", {12591, 12599, 12619, 19788}, "Trainer", "buzzek-bracketswing", nil, "Train Artisan Engineering if required.")
Add("Engineering", {19791}, "Vendor", "gearcutter-cogspinner", "sovik", "Buy and learn Schematic: Thorium Widget. Limited stock may need time to replenish.")
Add("Engineering", {19795}, "Vendor", "xizzer-fizzbolt", nil, "Buy Schematic: Thorium Tube on this engineer; it binds on pickup.")

-- Leatherworking
Add("Leatherworking", {2881, 2152, 3756}, "Trainer", "randal-worth", "kamari", nil)
Add("Leatherworking", {20648, 3817, 3763, 2168, 3766}, "Trainer", "simon-tanner", "karolek", nil)
Add("Leatherworking", {20649, 3818, 3764, 7151, 7156, 10507}, "Trainer", "telonis", "una", nil)
Add("Leatherworking", {10548, 10558}, "Trainer", "drakk-stonehand", "hahrana-ironhide", "Train Artisan Leatherworking if required.")
Add("Leatherworking", {19049}, "Vendor", "leonard-porter", "werg-thickblade", "Buy and learn Pattern: Wicked Leather Gauntlets.")
Add("Leatherworking", {19082}, "Vendor", "jase-farlane", nil, "Buy and learn Pattern: Runic Leather Headband.")

-- Tailoring
Add("Tailoring", {2963, 8776}, "Trainer", "lawrence-schneider", "snang", nil)
Add("Tailoring", {2964, 2402, 3848, 3839, 3852}, "Trainer", "sellandus", "magar", nil)
Add("Tailoring", {3865, 8791, 8799, 12074, 12065}, "Trainer", "georgio-bolero", "josef-gregorian", nil)
Add("Tailoring", {18402}, "Trainer", "timothy-worthington", "daryl-stack", "Train Artisan Tailoring if required.")
Add("Tailoring", {18417}, "Vendor", "qia", nil, "Buy and learn Pattern: Runecloth Gloves. Limited stock may need time to replenish.")

-- Enchanting
Add("Enchanting", {7421, 7418, 7420}, "Trainer", "betty-quin", "jhag", nil)
Add("Enchanting", {7457, 7771, 7795}, "Trainer", "lucan-cordell", "godan", nil)
Add("Enchanting", {7863, 13628, 13637, 13702, 13746, 13815}, "Trainer", "kitta-firewind", "hgarth", nil)
Add("Enchanting", {25125, 25126}, "Vendor", "tilli-thistlefuzz", "kithas", "Buy and learn the matching oil formula.")
Add("Enchanting", {25127}, "Vendor", "kania", nil, "Buy and learn Formula: Lesser Mana Oil. Kania is upstairs in the inn.")
Add("Enchanting", {20017}, "Vendor", "mythrindir", "daniel-bartlett", "Buy Formula: Enchant Shield - Greater Stamina on this enchanter; it binds on pickup.")
Add("Enchanting", {20051, 20015}, "Vendor", "lorelae-wintersong", nil, "Buy and learn the matching formula; get both the rod and cloak formulas before leaving.")

-- First Aid
Add("First Aid", {3275, 3276, 3277, 3278, 7928}, "Trainer", "nissa-firestone", "arnok", nil)
Add("First Aid", {7929, 10840}, "Manual", "deneb-walker", "balai-lokwein", "Buy and use the matching Heavy Silk or Mageweave Bandage manual. Expert First Aid is learned from a book.")
Add("First Aid", {10841, 18629}, "Trainer", "doctor-gustaf-vanhowzen", "doctor-gregory-victor", "Complete Triage first; return to the doctor at skill 240 for Heavy Mageweave or 260 for Runecloth Bandage.")
Add("First Aid", {1244436}, "Manual", nil, nil, "Manual: Major Healing Potion has no known vendor in the reviewed source. Check drops or the Auction House; no fixed waypoint.")

-- Cooking
Add("Cooking", {7751}, "Vendor", "catherine-leland", "lizbeth-cromwell", "Buy and learn Recipe: Brilliant Smallfish.")
Add("Cooking", {7753}, "Vendor", "tansy-puddlefizz", "lizbeth-cromwell", "Buy and learn Recipe: Longjaw Mud Snapper.")
Add("Cooking", {7755}, "Vendor", "catherine-leland", "naal-mistrunner", "Buy and learn Recipe: Bristle Whisker Catfish.")
Add("Cooking", {3376}, "Vendor", "kendor-kabonka", "keena", "Buy and learn Recipe: Curiously Tasty Omelet.")
Add("Cooking", {20916}, "Vendor", "kelsey-yance", nil, "Buy and learn Recipe: Mithril Head Trout.")
Add("Cooking", {18238, 18244}, "Vendor", "gikkix", nil, "Buy and learn the matching fish recipe.")
