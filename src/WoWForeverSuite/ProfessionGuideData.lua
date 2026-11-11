local _, Suite = ...
-- Original short summaries, not copies of the articles. Sources reviewed 2026-11-11.
-- Route prose is concise; shopping data below preserves sourced item/count facts.
local root = "https://www.wow-professions.com/forever/"
local guides = {}
Suite.ProfessionGuides = guides
local function Add(name, enum, path, note, sections)
    guides[#guides + 1] = { name = name, enum = enum, url = root .. path,
        reviewed = "November 11, 2026", note = note, sections = sections }
end
-- Sections use half-open skill intervals; the final section also includes 300.
Add("Alchemy", "Alchemy", "alchemy-leveling-guide",
    "Healing potions belong to First Aid in Forever. The source's 225+ route is untested; quantities and prices vary.", {
    { 1, 55, "Getting started", "1-10: Minor Arcane Elixir or Elixir of Minor Force. Then Elixir of Minor Defense to 55.", "Peacebloom, Silverleaf and Empty Vials." },
    { 55, 150, "Early potions and oils", "Minor Mana Potion to 65; Elixir of Minor Fortitude to 90; Elixir of Wisdom to 120; Lesser Mana Potion to 130; Fire Oil to 150. Save 30 Fire Oil." },
    { 150, 225, "Expert", "Elixir of Fire Power to 165, Mana Potion to 195, then Nature Protection Potion. Buy the protection recipe with your alchemist.", "Stranglekelp, Kingsblood, Liferoot and Leaded Vials." },
    { 225, 300, "Artisan", "Nature Protection Potion to 230; Elixir of Greater Intellect to 265; Superior Mana Potion to 275. Compare late elixir costs; the final route remains unsettled.", nil, "Untested source route. Artisan requires skill 200 and level 35.", locations = { Alliance = "Artisan: Kylanna Windwhisper in Feathermoon.", Horde = "Artisan: Rogvar in Stonard." } },
})
Add("Blacksmithing", "Blacksmithing", "blacksmithing-leveling-guide",
    "Carry a Blacksmith Hammer. Save intermediate grinding stones. Craft totals are estimates; 225+ is untested in the source.", {
    { 1, 75, "Stonework", "Rough Sharpening Stone to 25; Rough Grinding Stone to 50; Coarse Grinding Stone to 67; Runed Copper Gauntlets to 75." },
    { 75, 125, "Copper and bronze", "Runed Copper Belt to 95; Patterned Bronze Bracers to 100; Heavy Grinding Stone to 112; Patterned Bronze Bracers to 125." },
    { 125, 170, "Bronze weapons", "Bronze Shortsword to 140, then Bronze Warhammer to 170." },
    { 170, 175, "Green Iron Bracers", "Make Green Iron Bracers for this range.", nil, nil, locations = { Alliance = "Green Dye: Bombus Finespindle in Ironforge.", Horde = "Green Dye: Tamar in Orgrimmar." } },
    { 175, 195, "Stone and steel", "Solid Grinding Stone to 180; Golden Scale Bracers to 195." },
    { 195, 225, "Mithril", "Heavy Mithril Gauntlet to 210; Heavy Mithril Axe to 215; Heavy Mithril Breastplate to 225." },
    { 225, 300, "Late route", "Dense Sharpening Stone, Heavy Mithril Boots, then Imperial Plate pieces.", nil, "Untested; quest requirements uncertain. Artisan: Brikk Keencraft, Booty Bay; skill 200, level 35." },
})
Add("Enchanting", "Enchanting", "enchanting-leveling-guide",
    "Forever adds cheaper early enchants. Compare dust and essence costs. Enchants replace existing effects; choose the target yourself.", {
    { 1, 70, "First rod and enchants", "Make a Runed Copper Rod. Use Inferior Stamina on bracers to 20, then Inferior Stamina on chest or Minor Deflect on bracers to 70.", "Copper Rod and Mote of Magic are vendor supplies." },
    { 70, 150, "Dust or essence", "Dust path: Minor Stamina on bracers to 100; Minor Protection on cloak to 109; Runed Silver Rod; Minor Protection to 130; Minor Stamina on boots to 150." },
    { 150, 225, "Oils and rods", "Runed Golden Rod, Minor Mana Oil to 165, Lesser Agility on boots to 200, Runed Truesilver Rod, Lesser Wizard Oil to 220, Greater Defense on cloak to 225.", "Buy oil formulas from enchanting suppliers." },
    { 225, 300, "Annora", "Artisan training is in Uldaman with Annora; bring materials and learn the higher recipes before leaving.", nil, "The source marks this route untested. Artisan needs skill 200 and level 35." },
})
Add("Engineering", "Engineering", "engineering-leveling-guide",
    "Keep your components and tools. Gnomes no longer receive the Classic +15 leveling bonus. The source's route after 225 is untested.", {
    { 1, 75, "Basic components", "Rough Blasting Powder to 30, Copper Bolts to 50, Arclight Spanner, then Rough Copper Bombs to 75.", "Save 60 powder and 30 bolts for the bombs." },
    { 75, 150, "Bronze components", "Coarse Blasting Powder to 90; Coarse Dynamite to 100; Silver Contact to 105; Bronze Tube to 125; Standard Scope to 135; Heavy Blasting Powder and Whirring Bronze Gizmo to 150." },
    { 150, 200, "Mechanical parts", "Bronze Framework to 160; Explosive Sheep to 175; Solid Blasting Powder to 194; Gyromatic Micro-Adjustor; Mithril Tube to 200." },
    { 200, 300, "Artisan", "Unstable Trigger to 215; Mithril Casing to 238; Hi-Explosive Bomb to 250; Dense Blasting Powder to 260; Thorium Widget to 285; Thorium Tube to 300.", nil, "Artisan: Buzzek Bracketswing, Gadgetzan; skill 200, level 35. Keep triggers and casings for bombs." },
})
Add("Leatherworking", "Leatherworking", "leatherworking-leveling-guide",
    "Use Forever ranges: later recipes can grey earlier than Classic. Compare hide and leather alternatives before buying.", {
    { 1, 75, "Light leather", "Convert scraps or make Light Armor Kits to 30; kits to 45; Embossed Leather Gloves to 75.", "Light Leather and Coarse Thread." },
    { 75, 130, "Medium leather", "Medium Leather to 80; Cured Medium Hide to 90; Fine Leather Belt to 100; Dark Leather Cloak to 115; Dark Leather Belt to 125; Heavy Leather to 130.", "Keep ten Fine Leather Belts and the cured hides." },
    { 130, 195, "Heavy leather", "Hide route: Cured Heavy Hide to 140; Hillman's Leather Gloves to 155; Barbaric Shoulders to 165; Guardian Gloves to 195." },
    { 195, 225, "Thick leather", "Nightscape Headband to 210; Nightscape Pants to 225. Artisan requires skill 200 and level 35.", locations = { Alliance = "Artisan: Drakk Stonehand in The Hinterlands.", Horde = "Artisan: Hahrana Ironhide in Feralas." } },
    { 225, 300, "Rugged leather", "Nightscape Boots to 235; Wicked Leather Gauntlets to 265; Runic Leather Headband toward 300.", nil, "Untested source route. Runic pattern: Jase Farlane at Light's Hope Chapel." },
})
Add("Tailoring", "Tailoring", "tailoring-leveling-guide",
    "Save cloth bolts for later steps. Train before reaching a skill cap. The source's late route is provisional and incomplete after 265.", {
    { 1, 55, "Linen", "Bolt of Linen Cloth to 30; Linen Belt to 55.", "60 Linen Cloth makes the first 30 bolts." },
    { 55, 125, "Wool and silk", "Wool bolts to 80; Woolen Cape to 95; Double-stitched Woolen Shoulders to 100; silk bolts to 120; Gloves of Meditation to 125." },
    { 125, 190, "Silk clothing", "Gloves of Meditation to 140; mageweave bolts to 150; Crimson Silk Vest to 170; Crimson Silk Pantaloons to 190.", "The gloves need Elixir of Wisdom." },
    { 190, 225, "Mageweave", "Black Mageweave Shoulders to 215, then Mageweave Bag to 225." },
    { 225, 265, "Runecloth", "Runecloth Belt to 240; Runecloth Gloves to 265. Qia in Winterspring sells the glove pattern.", nil, "Untested. Artisan requires skill 200 and level 35.", locations = { Alliance = "Artisan: Timothy Worthington in Theramore.", Horde = "Artisan: Daryl Stack in Tarren Mill." } },
    { 265, 300, "Route not finalized", "The source suggests world-drop Runecloth Shoulders or Wizardweave Turban as candidates; check recipe access and costs first.", nil, "No finalized 265-300 route in the source." },
})
Add("Mining", "Mining", "mining-leveling-guide",
    "Carry a Mining Pick and turn on Find Minerals. Higher routes from 125 follow Classic assumptions not fully tested in Forever.", {
    { 1, 65, "Copper", "Gather in starting zones or smelt Copper Ore. Keep 70 Copper Bars if you plan to make bronze." },
    { 65, 125, "Tin and silver", "Train Journeyman. Tin needs 65, Silver 75. Bronze smelting can carry you to about 105. Wetlands, Silverpine or Hillsbrad offer gathering options." },
    { 125, 175, "Iron and gold", "Train Expert. Iron needs 125, Gold 155. Try Thousand Needles or Arathi Highlands." },
    { 175, 245, "Mithril and truesilver", "Try The Hinterlands or Tanaris. Mithril needs 175, Truesilver 230. Train Artisan at 200 before capping at 225." },
    { 245, 300, "Thorium", "Use the source's late-route maps and check your native node requirements before traveling.", nil, "Later routes are provisional; maps remain on the source website." },
})
Add("Herbalism", "Herbalism", "herbalism-leveling-guide",
    "Enable Find Herbs again after death. Route maps stay on the website. Routes from 170 are not yet tested by the source in Forever.", {
    { 1, 70, "Starting herbs", "Gather Peacebloom, Silverleaf and Earthroot in starting zones. Earthroot needs skill 15." },
    { 70, 115, "Briarthorn and kelp", "Train Journeyman at 50. Try Silverpine, Loch Modan or Darkshore. Stranglekelp needs 85." },
    { 115, 170, "Kingsblood and liferoot", "Try Hillsbrad or Stonetalon. Train Expert at 125. Kingsblood needs 125; Liferoot 150." },
    { 170, 205, "Goldthorn", "Stranglethorn Vale or Arathi Highlands. Khadgar's Whisker needs 185." },
    { 205, 230, "Firebloom", "Train Artisan at 200, then try Tanaris or Searing Gorge for Firebloom and Purple Lotus." },
    { 230, 270, "Sungrass", "Try The Hinterlands; Ghost Mushroom needs 245." },
    { 270, 300, "Late herbs", "Felwood offers Gromsblood, Dreamfoil and other higher herbs. Check each herb's requirements." },
})
Add("Skinning", "Skinning", "skinning-leveling-guide",
    "Keep a Skinning Knife in your bags. For creatures level 20+, required skill is five times creature level; lower levels use different thresholds.", {
    { 1, 75, "Starting beasts", "Forever's starting-area beasts can give points to 75.", locations = { Alliance = "Skin wolves in Northshire.", Horde = "Skin boars in the Valley of Trials." } },
    { 75, 150, "Growing beasts", "Train Journeyman at 50 and Expert at 125.", locations = { Alliance = "Loch Modan to 125, then Wetlands raptors.", Horde = "Skin beasts west of Northwatch Hold." } },
    { 150, 225, "Yetis or worgen", "Try Foothill Caverns in Hillsbrad or the worgen around Roland's Doom and Rotting Orchard in Duskwood." },
    { 225, 280, "Feralas", "Train Artisan at 200. Feral Scar Vale's yetis are the suggested next stop." },
    { 280, 300, "Un'Goro", "Skin dinosaurs in western Un'Goro Crater. Match targets to your current skill and ability to fight them." },
})
Add("Cooking", "Cooking", "cooking-leveling-guide",
    "Choose recipes around ingredients you can obtain cheaply. Buy spices from suppliers. The source has not tested Artisan progression in Forever.", {
    { 1, 50, "Simple meals", "Use Brilliant Smallfish, Slitherskin Mackerel, Charred Wolf Meat, Roasted Boar Meat or Herb Baked Egg." },
    { 50, 100, "Journeyman meals", "Train Journeyman at 50. Options include Longjaw Mud Snapper, Rainbow Fin Albacore, Boiled Clams and Coyote Steak." },
    { 100, 175, "Fish, ribs and eggs", "Catfish or meat recipes to 130; omelets or clams to 150; omelets or lion chops to 175. Expert Cookbook requires skill 125.", locations = { Alliance = "Expert Cookbook: Shandrina in Ashenvale.", Horde = "Expert Cookbook: Wulan in Desolace." } },
    { 175, 225, "Larger meals", "Mithril Headed Trout, Roast Raptor or Soothing Turtle Bisque." },
    { 225, 275, "Artisan", "Clamlette Surprise at level 35 and skill 225 unlocks Artisan. Try Spotted Yellowtail, Filet of Redgill or Monster Omelet.", "Quest: 12 Giant Egg, 10 Zesty Clam Meat, 20 Alterac Swiss.", "Untested source route." },
    { 275, 300, "Final meals", "Poached Sunscale Salmon or Nightfin Soup. Gikkix in Tanaris sells both recipes." },
})
Add("First Aid", "FirstAid", "first-aid-leveling-guide",
    "Forever also places healing potions in First Aid. This summary follows bandages; the website includes a potion alternative. Artisan is untested in the source.", {
    { 1, 80, "Linen", "Linen Bandage to 40; Heavy Linen Bandage to 80. Train Journeyman at skill 50 to pass 75." },
    { 80, 150, "Wool", "Wool Bandage to 115, then Heavy Wool Bandage to 150. Yellow recipes need extra cloth." },
    { 150, 180, "Silk", "Learn Silk Bandage before leaving your trainer. Expert First Aid - Under Wraps requires skill 125.", "Buy the Heavy Silk and Mageweave manuals on that trip.", locations = { Alliance = "Expert book: Deneb Walker in Arathi Highlands.", Horde = "Expert book: Balai Lok'Wein in Dustwallow Marsh." } },
    { 180, 225, "Heavy silk and mageweave", "Use the manuals: Heavy Silk Bandage to 210, Mageweave Bandage to 225." },
    { 225, 300, "Triage", "The Triage quest unlocks Artisan at skill 225 and level 35. Consult the full guide for subsequent training and bandages.", nil, "Confirm late progression in game; the source could not test it during beta." },
})
Add("Fishing", "Fishing", "fishing-leveling-guide",
    "Equip a Fishing Pole and apply lures. Select Fishing from the profession overview to put the action on your bar.", {
    { 1, 75, "Starting waters", "Fish in starting-zone lakes, ponds or rivers. Use Shiny Baubles. Starting-zone advice excludes capital cities." },
    { 75, 150, "City waters", "Train Journeyman at skill 50 and level 10. Fish in capital cities or nearby zones. Nightcrawlers help when fish escape." },
    { 150, 225, "Expert book", "Old Man Heming in Booty Bay sells Expert Fishing - The Bass and You; requires skill 125 and level 20. Bring Bright Baubles to Dustwallow Marsh." },
    { 225, 300, "Nat Pagle", "At level 35 and skill 225, complete Nat Pagle, Angler Extreme in Dustwallow. Its four fish come from Feralas, Swamp of Sorrows, Desolace and Stranglethorn.", "Afterward fish in Feralas, Tanaris, The Hinterlands, Felwood, Un'Goro or Western Plaguelands with Bright Baubles." },
})
Add("Lockpicking", nil, "lockpicking-leveling-guide",
    "Rogue skill cap is five times character level. The source confirms Horde 1-100; later recommendations assume Classic behavior and need Forever confirmation.", {
    { 1, 100, "Practice locks", "Use the practice locks for your faction.", nil, "Avoid The Jewel of the Southsea at low level; opening it summons an enemy.", locations = { Alliance = "Practice Lockboxes north of Lake Everstill in Redridge.", Horde = "Buccaneer's Strongboxes aboard the ship near Ratchet." } },
    { 100, 150, "Zoram Strand", "Search the shore in Ashenvale for Waterlogged Footlockers." },
    { 150, 200, "Angor Fortress", "Badlands: upstairs Battered Footlockers need 150; downstairs Dented Footlockers need 175." },
    { 200, 250, "The Slag Pit", "Searing Gorge: stay in the lower area until 225. Pickpocketing can also supply Sturdy Junkboxes." },
    { 250, 300, "Blackrock Depths", "Pick locks on dungeon doors and collect Heavy Junkboxes. Use Pick Lock instead of letting a key open the door. Observe native instance limits." },
})
Add("Camping", nil, "camping-guide",
    "Camping is tied to your professions, rather than a separate leveling route. Higher-tier blueprint sources and some station behavior remain uncertain.", {
    { 1, 300, "Prepare a fire", "Cooking teaches Basic Campfire Kit at skill 1. Craft it from one Simple Wood, then place it from your bags.", "Basic, Journeyman and Expert fires hold 3, 5 and 10 camp items." },
    { 1, 300, "Rest together", "Place a profession camp item and sit near the fire for a minute. Camp Benefits lasts an hour. Each player's camp items share an hour cooldown." },
    { 1, 300, "Profession items", "Most professions add camp tiers at skill 20, 140 and 300. Early items give buffs; later blueprints add stations or other services.", nil, "Camp buffs do not stack with their stronger class equivalents. Some higher-tier sources are unknown." },
})

-- Full published shopping tables. A row's alternative replaces that whole row,
-- not other rows or the whole bracket. Repeated ingredients stay separate.
-- Item IDs come from the articles' /forever/item= links, not recipe spell links.
local shopping = {
    Alchemy = {
        note = "Source totals omit vial quantities. The later list only reaches 290; the last ten points are undecided.",
        { title = "1-225", rows = {
            { {91,2447,"Peacebloom"} }, { {45,765,"Silverleaf"} }, { {50,785,"Mageroyal"} },
            { {54,2449,"Earthroot"} }, { {60,2450,"Briarthorn"} }, { {82,3820,"Stranglekelp"} },
            { {40,6359,"Firefin Snapper"}, {15,3356,"Kingsblood"}, alternative = { {42,785,"Mageroyal"}, {42,3820,"Stranglekelp"} } },
            { {36,3356,"Kingsblood"} }, { {36,3357,"Liferoot"} },
        } },
        { title = "225-290", note = "Provisional; the source labels this 225-300 but excludes 290-300.", rows = {
            { {12,3357,"Liferoot"} }, { {12,3820,"Stranglekelp"} }, { {41,3358,"Khadgar's Whisker"} },
            { {60,8838,"Sungrass"} }, { {101,8839,"Blindweed"} },
        } },
    },
    Blacksmithing = {
        note = "Bring a Blacksmith Hammer. Steel may be smelted from equal amounts of Iron Bar and Coal at Mining 165.",
        { title = "1-150", rows = {
            { {90,2835,"Rough Stone"} }, { {294,2840,"Copper Bar"} }, { {72,2836,"Coarse Stone"} },
            { {290,2841,"Bronze Bar"} }, { {60,2838,"Heavy Stone"} }, { {58,2319,"Medium Leather"} },
            { {96,2880,"Weak Flux",true} }, { {10,3466,"Strong Flux",true} },
        } },
        { title = "150-225", rows = {
            { {232,2841,"Bronze Bar"} }, { {29,3466,"Strong Flux",true} }, { {29,2319,"Medium Leather"} },
            { {54,3575,"Iron Bar"} }, { {9,2605,"Green Dye",true} }, { {32,7912,"Solid Stone"} },
            { {100,3859,"Steel Bar"} }, { {60,2838,"Heavy Stone"} }, { {358,3860,"Mithril Bar"} },
            { {84,4338,"Mageweave Cloth"} }, { {24,4234,"Heavy Leather"} }, { {12,3864,"Citrine"} },
        } },
        { title = "225-300", note = "Provisional. Thorium includes 140 bars for the four recipe quests.", rows = {
            { {5,12365,"Dense Stone"} }, { {224,3860,"Mithril Bar"} }, { {64,4304,"Thick Leather"} },
            { {1910,12359,"Thorium Bar"} }, { {30,8170,"Rugged Leather"} },
            { {67,7910,"Star Ruby"} }, { {25,7909,"Aquamarine"} },
        } },
    },
    Enchanting = {
        { title = "1-225", rows = {
            { {19,247786,"Mote of Magic",true} }, { {1,6217,"Copper Rod",true} },
            { {272,10940,"Strange Dust"}, alternative = { {309,10938,"Lesser Magic Essence"} } },
            { {1,6338,"Silver Rod"} }, { {1,1210,"Shadowgem"} }, { {4,10938,"Lesser Magic Essence"} },
            { {3,10940,"Strange Dust"} },
            { {64,11083,"Soul Dust"}, alternative = { {39,11083,"Soul Dust"}, {15,11137,"Vision Dust"} } },
            { {1,11128,"Golden Rod"} }, { {1,5500,"Iridescent Pearl"} }, { {1,11082,"Greater Astral Essence"} },
            { {32,17034,"Maple Seed",true} }, { {41,3372,"Leaded Vial",true} }, { {31,11137,"Vision Dust"} },
            { {1,11144,"Truesilver Rod"} }, { {1,7971,"Black Pearl"} }, { {1,11135,"Greater Mystic Essence"} },
            { {50,17035,"Stranglethorn Seed",true} },
        } },
        { title = "225-300", note = "Provisional source totals.", rows = {
            { {37,11137,"Vision Dust"} }, { {212,11176,"Dream Dust"} }, { {20,8831,"Purple Lotus"} },
            { {20,8925,"Crystal Vial",true} }, { {1,16206,"Arcanite Rod"} }, { {1,13926,"Golden Pearl"} },
            { {50,16204,"Illusion Dust"} }, { {4,16203,"Greater Eternal Essence"} },
            { {4,14343,"Small Brilliant Shard"} }, { {2,14344,"Large Brilliant Shard"} },
        } },
    },
    Engineering = {
        { title = "1-225", rows = {
            { {60,2835,"Rough Stone"} }, { {66,2840,"Copper Bar"} }, { {50,2589,"Linen Cloth"} },
            { {60,2836,"Coarse Stone"} },
            { {5,2842,"Silver Bar"}, alternative = { {30,2318,"Light Leather"}, {10,818,"Tigerseye"} } },
            { {110,2841,"Bronze Bar"} }, { {25,2880,"Weak Flux",true} }, { {10,1206,"Moss Agate"} },
            { {30,2838,"Heavy Stone"} }, { {60,2592,"Wool Cloth"} }, { {15,2319,"Medium Leather"} },
            { {4,3859,"Steel Bar"} }, { {120,7912,"Solid Stone"} }, { {74,3860,"Mithril Bar"} },
            { {20,4338,"Mageweave Cloth"} },
        } },
        { title = "225-300", note = "Provisional source totals.", rows = {
            { {84,3860,"Mithril Bar"} }, { {60,12365,"Dense Stone"} },
            { {225,12359,"Thorium Bar"} }, { {35,14047,"Runecloth"} },
        } },
    },
    Leatherworking = {
        note = "Source totals exclude thread, dyes and salt. Add these as recipes require them.",
        { title = "1-225", rows = {
            { {100,2934,"Ruined Leather Scraps"}, alternative = { {60,2318,"Light Leather"} } },
            { {230,2318,"Light Leather"} },
            { {128,2319,"Medium Leather"}, alternative = { {27,783,"Light Hide"}, {186,2318,"Light Leather"} } },
            { {307,2319,"Medium Leather"} },
            { {10,4232,"Medium Hide"}, alternative = { {66,2318,"Light Leather"}, {142,2319,"Medium Leather"} } },
            { {20,4235,"Heavy Hide"}, {120,4234,"Heavy Leather"}, alternative = {
                {240,4234,"Heavy Leather"}, {140,2319,"Medium Leather"}, {17,1206,"Moss Agate"}, {5,7071,"Iron Buckle"} } },
            { {97,4234,"Heavy Leather"} },
            { {26,4236,"Cured Heavy Hide"}, alternative = { {26,4235,"Heavy Hide"} } },
            { {315,4304,"Thick Leather"} },
        } },
        { title = "225-300", note = "Provisional source totals.", rows = {
            { {192,4304,"Thick Leather"} }, { {1030,8170,"Rugged Leather"} }, { {530,14047,"Runecloth"} },
        } },
    },
    Tailoring = {
        note = "Source totals exclude thread and dyes. No finalized shopping list exists after 265.",
        { title = "1-150", rows = {
            { {60,2589,"Linen Cloth"} }, { {459,2592,"Wool Cloth"} }, { {29,3383,"Elixir of Wisdom"} },
            { {216,4306,"Silk Cloth"} }, { {115,4338,"Mageweave Cloth"} },
        } },
        { title = "150-225", rows = {
            { {520,4306,"Silk Cloth"} },
            { {840,4338,"Mageweave Cloth"}, alternative = { {168,4339,"Bolt of Mageweave"} } },
        } },
        { title = "225-265", note = "Provisional; 265-300 materials are not published yet.", rows = {
            { {1220,14047,"Runecloth"} }, { {172,8170,"Rugged Leather"} },
        } },
    },
    ["First Aid"] = {
        note = "The herb alternative also needs Mild Spices and Empty Vials; the source does not total those here.",
        { title = "1-225", rows = {
            { {130,2589,"Linen Cloth"}, alternative = { {81,2447,"Peacebloom"} } },
            { {24,2589,"Linen Cloth"} }, { {150,2592,"Wool Cloth"} },
            { {134,4306,"Silk Cloth"} }, { {19,4338,"Mageweave Cloth"} },
        } },
        { title = "225-300", note = "Provisional source totals; includes the late healing-potion step.", rows = {
            { {89,4338,"Mageweave Cloth"} }, { {20,14047,"Runecloth"} }, { {30,13464,"Golden Sansam"} },
        } },
    },
}
for _, guide in ipairs(guides) do
    guide.shopping = shopping[guide.name]
end

-- Last use of each published shopping row. Completed preparation brackets stay
-- done even when their crafted intermediates are consumed by a later recipe.
-- Unfinished rows retain the full source estimate; do not imply exact skill-up odds.
local lastUse = {
    Alchemy = { {90,55,130,90,120,225,165,195,225}, {230,230,265,290,290} },
    Blacksmithing = { {75,95,125,150,112,150,140,150},
        {170,170,170,175,175,215,195,195,225,210,215,215}, {230,240,240,300,245,300,290} },
    Enchanting = { {20,2,150,110,110,110,110,200,151,151,151,165,220,225,201,201,201,220},
        {250,294,265,265,295,295,300,295,295,295} },
    Engineering = { {75,75,100,100,105,175,125,135,175,175,175,195,225,225,215}, {238,260,300,285} },
    Leatherworking = { {30,100,115,155,125,175,195,195,225}, {235,300,300} },
    Tailoring = { {55,140,140,120,150}, {190,225}, {265,265} },
    ["First Aid"] = { {75,80,150,210,225}, {260,275,300} },
}
for _, guide in ipairs(guides) do
    if guide.shopping then
        for groupIndex, group in ipairs(guide.shopping) do
            group.endSkill = tonumber(group.title:match("%-(%d+)$"))
            for rowIndex, row in ipairs(group.rows) do row.endSkill = lastUse[guide.name][groupIndex][rowIndex] end
        end
    end
end

-- Primary recipe examples: start, target, estimated crafts for the full band,
-- recipe name, and actual reagent quantities per craft. Counts are planning
-- estimates, not a skill-up probability model. Unsettled endgame routes stay absent.
local estimates = {
    Blacksmithing = {
        {1,25,30,"Rough Sharpening Stone",{{1,"Rough Stone"}}},
        {25,50,30,"Rough Grinding Stone",{{2,"Rough Stone"}}},
        {50,67,36,"Coarse Grinding Stone",{{2,"Coarse Stone"}}},
        {67,75,8,"Runed Copper Gauntlets",{{8,"Copper Bar"},{2,"Rough Grinding Stone"}}},
        {75,80,5,"Runed Copper Belt",{{10,"Copper Bar"}}},
        {80,95,18,"Runed Copper Belt",{{10,"Copper Bar"}}},
        {95,100,5,"Patterned Bronze Bracers",{{5,"Bronze Bar"},{2,"Coarse Grinding Stone"}}},
        {100,112,20,"Heavy Grinding Stone",{{3,"Heavy Stone"}}},
        {112,125,13,"Patterned Bronze Bracers",{{5,"Bronze Bar"},{2,"Coarse Grinding Stone"}}},
        {125,140,24,"Bronze Shortsword",{{5,"Bronze Bar"},{4,"Weak Flux"},{2,"Medium Leather"}}},
        {140,150,10,"Bronze Warhammer",{{8,"Bronze Bar"},{1,"Strong Flux"},{1,"Medium Leather"}}},
        {150,170,29,"Bronze Warhammer",{{8,"Bronze Bar"},{1,"Strong Flux"},{1,"Medium Leather"}}},
        {170,175,9,"Green Iron Bracers",{{6,"Iron Bar"},{1,"Green Dye"}}},
        {175,180,8,"Solid Grinding Stone",{{4,"Solid Stone"}}},
        {180,195,20,"Golden Scale Bracers",{{5,"Steel Bar"},{2,"Heavy Grinding Stone"}}},
        {195,210,21,"Heavy Mithril Gauntlet",{{6,"Mithril Bar"},{4,"Mageweave Cloth"}}},
        {210,215,6,"Heavy Mithril Axe",{{12,"Mithril Bar"},{2,"Citrine"},{1,"Solid Grinding Stone"},{4,"Heavy Leather"}}},
        {215,225,10,"Heavy Mithril Breastplate",{{16,"Mithril Bar"}}},
        {225,230,5,"Dense Sharpening Stone",{{1,"Dense Stone"}}},
        {230,240,16,"Heavy Mithril Boots",{{14,"Mithril Bar"},{4,"Thick Leather"}}},
        {240,245,5,"Imperial Plate Belt",{{22,"Thorium Bar"},{6,"Rugged Leather"},{1,"Aquamarine"}}},
        {245,270,27,"Imperial Plate Bracers",{{20,"Thorium Bar"},{1,"Star Ruby"}}},
        {270,290,20,"Imperial Plate Boots",{{34,"Thorium Bar"},{1,"Star Ruby"},{1,"Aquamarine"}}},
        {290,300,10,"Imperial Plate Leggings",{{44,"Thorium Bar"},{2,"Star Ruby"}}},
    },
    Alchemy = {
        {1,10,9,"Minor Arcane Elixir",{{1,"Peacebloom"},{1,"Empty Vial"}}},
        {10,55,45,"Elixir of Minor Defense",{{1,"Silverleaf"},{1,"Peacebloom"},{1,"Empty Vial"}}},
        {55,65,10,"Minor Mana Potion",{{1,"Mageroyal"},{1,"Peacebloom"},{1,"Empty Vial"}}},
        {65,90,27,"Elixir of Minor Fortitude",{{2,"Earthroot"},{1,"Peacebloom"},{1,"Empty Vial"}}},
        {90,120,30,"Elixir of Wisdom",{{1,"Mageroyal"},{2,"Briarthorn"},{1,"Empty Vial"}}},
        {120,130,10,"Lesser Mana Potion",{{1,"Mageroyal"},{1,"Stranglekelp"},{1,"Empty Vial"}}},
        {130,150,20,"Fire Oil",{{2,"Firefin Snapper"},{1,"Empty Vial"}},2},
        {150,165,15,"Elixir of Fire Power",{{2,"Fire Oil"},{1,"Kingsblood"},{1,"Leaded Vial"}}},
        {165,195,36,"Mana Potion",{{1,"Stranglekelp"},{1,"Kingsblood"},{1,"Leaded Vial"}}},
        {195,225,36,"Nature Protection Potion",{{1,"Liferoot"},{1,"Stranglekelp"},{1,"Leaded Vial"}}},
        {225,230,12,"Nature Protection Potion",{{1,"Liferoot"},{1,"Stranglekelp"},{1,"Leaded Vial"}}},
        {230,265,41,"Elixir of Greater Intellect",{{1,"Blindweed"},{1,"Khadgar's Whisker"},{1,"Crystal Vial"}}},
        {265,275,10,"Superior Mana Potion",{{2,"Sungrass"},{2,"Blindweed"},{1,"Crystal Vial"}}},
        {275,290,20,"Superior Mana Potion",{{2,"Sungrass"},{2,"Blindweed"},{1,"Crystal Vial"}}},
    },
    Engineering = {
        {1,30,60,"Rough Blasting Powder",{{1,"Rough Stone"}}},
        {30,50,30,"Handful of Copper Bolts",{{1,"Copper Bar"}}},
        {50,51,1,"Arclight Spanner",{{6,"Copper Bar"}}},
        {51,75,30,"Rough Copper Bomb",{{1,"Copper Bar"},{1,"Handful of Copper Bolts"},{2,"Rough Blasting Powder"},{1,"Linen Cloth"}}},
        {75,90,60,"Coarse Blasting Powder",{{1,"Coarse Stone"}}},
        {90,100,20,"Coarse Dynamite",{{3,"Coarse Blasting Powder"},{1,"Linen Cloth"}}},
        {100,105,5,"Silver Contact",{{1,"Silver Bar"}}},
        {105,125,25,"Bronze Tube",{{2,"Bronze Bar"},{1,"Weak Flux"}}},
        {125,135,10,"Standard Scope",{{1,"Bronze Tube"},{1,"Moss Agate"}}},
        {135,150,30,"Heavy Blasting Powder",{{1,"Heavy Stone"}}},
        {135,150,15,"Whirring Bronze Gizmo",{{2,"Bronze Bar"},{1,"Wool Cloth"}}},
        {150,160,15,"Bronze Framework",{{2,"Bronze Bar"},{1,"Medium Leather"},{1,"Wool Cloth"}}},
        {160,175,15,"Explosive Sheep",{{2,"Heavy Blasting Powder"},{1,"Whirring Bronze Gizmo"},{1,"Bronze Framework"},{2,"Wool Cloth"}}},
        {175,194,60,"Solid Blasting Powder",{{2,"Solid Stone"}}},
        {194,195,1,"Gyromatic Micro-Adjustor",{{4,"Steel Bar"}}},
        {195,200,6,"Mithril Tube",{{3,"Mithril Bar"}}},
        {200,215,20,"Unstable Trigger",{{1,"Mithril Bar"},{1,"Mageweave Cloth"},{1,"Solid Blasting Powder"}}},
        {215,238,40,"Mithril Casing",{{3,"Mithril Bar"}}},
        {238,250,20,"Hi-Explosive Bomb",{{2,"Mithril Casing"},{1,"Unstable Trigger"},{2,"Solid Blasting Powder"}}},
        {250,260,30,"Dense Blasting Powder",{{2,"Dense Stone"}}},
        {260,285,35,"Thorium Widget",{{3,"Thorium Bar"},{1,"Runecloth"}}},
        {285,300,20,"Thorium Tube",{{6,"Thorium Bar"}}},
    },
    Leatherworking = {
        {1,30,33,"Light Leather",{{3,"Ruined Leather Scraps"}}},
        {30,45,24,"Light Armor Kit",{{1,"Light Leather"}}},
        {45,55,10,"Embossed Leather Gloves",{{3,"Light Leather"},{2,"Coarse Thread"}}},
        {55,75,21,"Embossed Leather Gloves",{{3,"Light Leather"},{2,"Coarse Thread"}}},
        {75,80,8,"Medium Leather",{{4,"Light Leather"}}},
        {80,90,10,"Cured Medium Hide",{{1,"Medium Hide"},{1,"Salt"}}},
        {90,100,19,"Fine Leather Belt",{{6,"Light Leather"},{2,"Coarse Thread"}}},
        {100,115,16,"Dark Leather Cloak",{{8,"Medium Leather"},{1,"Fine Thread"},{1,"Gray Dye"}}},
        {115,125,10,"Dark Leather Belt",{{1,"Fine Leather Belt"},{1,"Cured Medium Hide"},{2,"Fine Thread"},{1,"Gray Dye"}}},
        {125,130,7,"Heavy Leather",{{5,"Medium Leather"}}},
        {130,140,20,"Cured Heavy Hide",{{1,"Heavy Hide"},{3,"Salt"}}},
        {140,155,20,"Hillman's Leather Gloves",{{14,"Medium Leather"},{4,"Fine Thread"}}},
        {155,165,10,"Barbaric Shoulders",{{8,"Heavy Leather"},{1,"Cured Heavy Hide"},{2,"Fine Thread"}}},
        {165,175,10,"Guardian Gloves",{{4,"Heavy Leather"},{1,"Cured Heavy Hide"},{1,"Silken Thread"}}},
        {175,195,26,"Guardian Gloves",{{4,"Heavy Leather"},{1,"Cured Heavy Hide"},{1,"Silken Thread"}}},
        {195,210,21,"Nightscape Headband",{{5,"Thick Leather"},{2,"Silken Thread"}}},
        {210,225,15,"Nightscape Pants",{{14,"Thick Leather"},{4,"Silken Thread"}}},
        {225,235,12,"Nightscape Boots",{{16,"Thick Leather"},{2,"Heavy Silken Thread"}}},
        {235,250,15,"Wicked Leather Gauntlets",{{8,"Rugged Leather"},{1,"Black Dye"},{1,"Rune Thread"}}},
        {250,265,21,"Wicked Leather Gauntlets",{{8,"Rugged Leather"},{1,"Black Dye"},{1,"Rune Thread"}}},
        {265,285,20,"Runic Leather Headband",{{14,"Rugged Leather"},{10,"Runecloth"},{1,"Rune Thread"}}},
        {285,300,33,"Runic Leather Headband",{{14,"Rugged Leather"},{10,"Runecloth"},{1,"Rune Thread"}}},
    },
    Tailoring = {
        {1,30,30,"Bolt of Linen Cloth",{{2,"Linen Cloth"}}},
        {30,55,28,"Linen Belt",{{1,"Bolt of Linen Cloth"},{1,"Coarse Thread"}}},
        {55,80,45,"Bolt of Woolen Cloth",{{3,"Wool Cloth"}}},
        {80,95,22,"Woolen Cape",{{1,"Bolt of Woolen Cloth"},{1,"Fine Thread"}}},
        {95,100,5,"Double-stitched Woolen Shoulders",{{3,"Bolt of Woolen Cloth"},{2,"Fine Thread"}}},
        {100,120,54,"Bolt of Silk Cloth",{{4,"Silk Cloth"}}},
        {120,125,5,"Gloves of Meditation",{{4,"Bolt of Woolen Cloth"},{3,"Fine Thread"},{1,"Elixir of Wisdom"}}},
        {125,140,24,"Gloves of Meditation",{{4,"Bolt of Woolen Cloth"},{3,"Fine Thread"},{1,"Elixir of Wisdom"}}},
        {140,150,23,"Bolt of Mageweave",{{5,"Mageweave Cloth"}}},
        {150,170,20,"Crimson Silk Vest",{{4,"Bolt of Silk Cloth"},{2,"Red Dye"},{2,"Fine Thread"}}},
        {170,190,26,"Crimson Silk Pantaloons",{{4,"Bolt of Silk Cloth"},{2,"Red Dye"},{2,"Silken Thread"}}},
        {190,215,29,"Black Mageweave Shoulders",{{3,"Bolt of Mageweave"},{2,"Heavy Silken Thread"}}},
        {215,225,26,"Mageweave Bag",{{4,"Bolt of Mageweave"},{2,"Silken Thread"}}},
        {225,240,24,"Runecloth Belt",{{3,"Bolt of Runecloth"},{1,"Rune Thread"}}},
        {240,265,43,"Runecloth Gloves",{{4,"Bolt of Runecloth"},{4,"Rugged Leather"},{1,"Rune Thread"}}},
    },
    Enchanting = {
        {1,2,1,"Runed Copper Rod",{{1,"Copper Rod"},{1,"Mote of Magic"}}},
        {2,20,18,"Enchant Bracer - Inferior Stamina",{{1,"Mote of Magic"}}},
        {20,70,50,"Enchant Chest - Inferior Stamina",{{1,"Strange Dust"}}},
        {70,100,30,"Enchant Bracer - Minor Stamina",{{2,"Strange Dust"}}},
        {100,109,9,"Enchant Cloak - Minor Protection",{{2,"Strange Dust"}}},
        {109,110,1,"Runed Silver Rod",{{1,"Silver Rod"},{3,"Strange Dust"},{4,"Lesser Magic Essence"},{1,"Shadowgem"}}},
        {110,130,32,"Enchant Cloak - Minor Protection",{{2,"Strange Dust"}}},
        {130,150,20,"Enchant Boots - Minor Stamina",{{4,"Strange Dust"}}},
        {150,151,1,"Runed Golden Rod",{{1,"Golden Rod"},{1,"Iridescent Pearl"},{1,"Greater Astral Essence"},{1,"Soul Dust"}}},
        {151,165,16,"Minor Mana Oil",{{1,"Soul Dust"},{2,"Maple Seed"},{1,"Leaded Vial"}}},
        {165,200,47,"Enchant Boots - Lesser Agility",{{1,"Soul Dust"}}},
        {200,201,1,"Runed Truesilver Rod",{{1,"Truesilver Rod"},{1,"Black Pearl"},{1,"Greater Mystic Essence"},{1,"Vision Dust"}}},
        {201,220,25,"Lesser Wizard Oil",{{1,"Vision Dust"},{2,"Stranglethorn Seed"},{1,"Leaded Vial"}}},
        {220,225,5,"Enchant Cloak - Greater Defense",{{1,"Vision Dust"}}},
        {225,250,37,"Enchant Gloves - Agility",{{1,"Vision Dust"}}},
        {250,265,20,"Lesser Mana Oil",{{1,"Dream Dust"},{1,"Purple Lotus"},{1,"Crystal Vial"}}},
        {265,294,32,"Enchant Shield - Greater Stamina",{{6,"Dream Dust"}}},
        {294,295,1,"Runed Arcanite Rod",{{1,"Arcanite Rod"},{1,"Golden Pearl"},{10,"Illusion Dust"},{4,"Greater Eternal Essence"},{4,"Small Brilliant Shard"},{2,"Large Brilliant Shard"}}},
        {295,300,5,"Enchant Cloak - Superior Defense",{{8,"Illusion Dust"}}},
    },
    ["First Aid"] = {
        {1,40,50,"Linen Bandage",{{1,"Linen Cloth"}}},
        {40,75,40,"Heavy Linen Bandage",{{2,"Linen Cloth"}}},
        {75,80,12,"Heavy Linen Bandage",{{2,"Linen Cloth"}}},
        {80,115,50,"Wool Bandage",{{1,"Wool Cloth"}}},
        {115,150,50,"Heavy Wool Bandage",{{2,"Wool Cloth"}}},
        {150,180,42,"Silk Bandage",{{1,"Silk Cloth"}}},
        {180,210,46,"Heavy Silk Bandage",{{2,"Silk Cloth"}}},
        {210,225,19,"Mageweave Bandage",{{1,"Mageweave Cloth"}}},
        {225,240,29,"Mageweave Bandage",{{1,"Mageweave Cloth"}}},
        {240,260,30,"Heavy Mageweave Bandage",{{2,"Mageweave Cloth"}}},
        {260,275,20,"Runecloth Bandage",{{1,"Runecloth"}}},
        {275,300,30,"Major Healing Potion",{{1,"Golden Sansam"},{3,"Soothing Spices"},{1,"Crystal Vial"}}},
    },
    Cooking = {
        {1,50,55,"Brilliant Smallfish",{{1,"Raw Brilliant Smallfish"}}},
        {50,100,55,"Longjaw Mud Snapper",{{1,"Raw Longjaw Mud Snapper"}}},
        {100,130,30,"Bristle Whisker Catfish",{{1,"Raw Bristle Whisker Catfish"}}},
        {130,150,25,"Bristle Whisker Catfish",{{1,"Raw Bristle Whisker Catfish"}}},
        {150,175,25,"Curiously Tasty Omelet",{{1,"Raptor Egg"},{1,"Hot Spices"}}},
        {175,225,50,"Mithril Headed Trout",{{1,"Raw Mithril Head Trout"}}},
        {225,275,65,"Spotted Yellowtail",{{1,"Raw Spotted Yellowtail"}}},
        {275,300,35,"Poached Sunscale Salmon",{{1,"Raw Sunscale Salmon"}}},
    },
}
local itemIDs, itemVendors = {}, {}
for _, groups in pairs(shopping) do
    for _, group in ipairs(groups) do
        for _, row in ipairs(group.rows) do
            for _, choice in ipairs({row, row.alternative or {}}) do
                for _, item in ipairs(choice) do
                    itemIDs[item[3]] = item[2]
                    if item[4] then itemVendors[item[3]] = true end
                end
            end
        end
    end
end
Suite.ProfessionMaterialIDs = itemIDs
Suite.ProfessionMaterialVendors = itemVendors
for _, guide in ipairs(guides) do guide.estimates = estimates[guide.name] end

-- Exact /forever/spell= recipe links from the same eight source guides, reviewed
-- November 11, 2026. Native recipe metadata and profession membership are still
-- validated on each click; a source link alone is not proof of client availability.
local recipeIDs = {
    ["Arclight Spanner"] = 7430, ["Barbaric Shoulders"] = 7151,
    ["Black Mageweave Shoulders"] = 12074, ["Bolt of Linen Cloth"] = 2963,
    ["Bolt of Mageweave"] = 3865, ["Bolt of Silk Cloth"] = 3839, ["Bolt of Woolen Cloth"] = 2964,
    ["Brilliant Smallfish"] = 7751, ["Bristle Whisker Catfish"] = 7755,
    ["Bronze Framework"] = 3953, ["Bronze Shortsword"] = 2742, ["Bronze Tube"] = 3938, ["Bronze Warhammer"] = 9985,
    ["Coarse Blasting Powder"] = 3929, ["Coarse Dynamite"] = 3931, ["Coarse Grinding Stone"] = 3326,
    ["Crimson Silk Pantaloons"] = 8799, ["Crimson Silk Vest"] = 8791,
    ["Cured Heavy Hide"] = 3818, ["Cured Medium Hide"] = 3817, ["Curiously Tasty Omelet"] = 3376,
    ["Dark Leather Belt"] = 3766, ["Dark Leather Cloak"] = 2168,
    ["Dense Blasting Powder"] = 19788, ["Dense Sharpening Stone"] = 16641,
    ["Double-stitched Woolen Shoulders"] = 3848,
    ["Elixir of Fire Power"] = 7845, ["Elixir of Greater Intellect"] = 11465,
    ["Elixir of Minor Defense"] = 7183, ["Elixir of Minor Fortitude"] = 2334, ["Elixir of Wisdom"] = 3171,
    ["Embossed Leather Gloves"] = 3756,
    ["Enchant Boots - Lesser Agility"] = 13637, ["Enchant Boots - Minor Stamina"] = 7863,
    ["Enchant Bracer - Inferior Stamina"] = 7418, ["Enchant Bracer - Minor Stamina"] = 7457,
    ["Enchant Chest - Inferior Stamina"] = 7420, ["Enchant Cloak - Greater Defense"] = 13746,
    ["Enchant Cloak - Minor Protection"] = 7771, ["Enchant Cloak - Superior Defense"] = 20015,
    ["Enchant Gloves - Agility"] = 13815, ["Enchant Shield - Greater Stamina"] = 20017,
    ["Explosive Sheep"] = 3955, ["Fine Leather Belt"] = 3763, ["Fire Oil"] = 7837,
    ["Gloves of Meditation"] = 3852, ["Golden Scale Bracers"] = 7223, ["Green Iron Bracers"] = 3501,
    ["Guardian Gloves"] = 7156, ["Gyromatic Micro-Adjustor"] = 12590, ["Handful of Copper Bolts"] = 3922,
    ["Heavy Blasting Powder"] = 3945, ["Heavy Grinding Stone"] = 3337, ["Heavy Leather"] = 20649,
    ["Heavy Linen Bandage"] = 3276, ["Heavy Mageweave Bandage"] = 10841,
    ["Heavy Mithril Axe"] = 9993, ["Heavy Mithril Boots"] = 9968,
    ["Heavy Mithril Breastplate"] = 9959, ["Heavy Mithril Gauntlet"] = 9928,
    ["Heavy Silk Bandage"] = 7929, ["Heavy Wool Bandage"] = 3278,
    ["Hi-Explosive Bomb"] = 12619, ["Hillman's Leather Gloves"] = 3764,
    ["Imperial Plate Belt"] = 16647, ["Imperial Plate Boots"] = 16657,
    ["Imperial Plate Bracers"] = 16649, ["Imperial Plate Leggings"] = 16730,
    ["Lesser Mana Oil"] = 25127, ["Lesser Mana Potion"] = 3173, ["Lesser Wizard Oil"] = 25126,
    ["Light Armor Kit"] = 2152, ["Light Leather"] = 2881, ["Linen Bandage"] = 3275, ["Linen Belt"] = 8776,
    ["Longjaw Mud Snapper"] = 7753, ["Mageweave Bag"] = 12065, ["Mageweave Bandage"] = 10840,
    ["Major Healing Potion"] = 1244436, ["Mana Potion"] = 3452, ["Medium Leather"] = 20648,
    ["Minor Arcane Elixir"] = 1245246, ["Minor Mana Oil"] = 25125, ["Minor Mana Potion"] = 2331,
    ["Mithril Casing"] = 12599, ["Mithril Headed Trout"] = 20916, ["Mithril Tube"] = 12589,
    ["Nature Protection Potion"] = 7259, ["Nightscape Boots"] = 10558,
    ["Nightscape Headband"] = 10507, ["Nightscape Pants"] = 10548,
    ["Patterned Bronze Bracers"] = 2672, ["Poached Sunscale Salmon"] = 18244,
    ["Rough Blasting Powder"] = 3918, ["Rough Copper Bomb"] = 3923,
    ["Rough Grinding Stone"] = 3320, ["Rough Sharpening Stone"] = 2660,
    ["Runecloth Bandage"] = 18629, ["Runecloth Belt"] = 18402, ["Runecloth Gloves"] = 18417,
    ["Runed Arcanite Rod"] = 20051, ["Runed Copper Belt"] = 2666, ["Runed Copper Gauntlets"] = 3323,
    ["Runed Copper Rod"] = 7421, ["Runed Golden Rod"] = 13628, ["Runed Silver Rod"] = 7795,
    ["Runed Truesilver Rod"] = 13702, ["Runic Leather Headband"] = 19082,
    ["Silk Bandage"] = 7928, ["Silver Contact"] = 3973,
    ["Solid Blasting Powder"] = 12585, ["Solid Grinding Stone"] = 9920,
    ["Spotted Yellowtail"] = 18238, ["Standard Scope"] = 3978, ["Superior Mana Potion"] = 17553,
    ["Thorium Tube"] = 19795, ["Thorium Widget"] = 19791, ["Unstable Trigger"] = 12591,
    ["Whirring Bronze Gizmo"] = 3942, ["Wicked Leather Gauntlets"] = 19049,
    ["Wool Bandage"] = 3277, ["Woolen Cape"] = 2402,
}
for _, guide in ipairs(guides) do
    for _, recipe in ipairs(guide.estimates or {}) do recipe.recipeID = recipeIDs[recipe[4]] end
end
