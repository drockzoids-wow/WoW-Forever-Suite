local _, Suite = ...
-- Recipe-specific acquisition references, reviewed November 12, 2026.
-- See docs/forever-development.md for sources and native-test qualifications.
-- No profession-wide trainer default: vendors, manuals and quests stay distinct.
local points = {
    ["aayndia-floralwind"] = { map = 1440, x = 0.36, y = 0.521, name = "Aayndia Floralwind, Ashenvale" },
    ["adele-fielder"] = { map = 1429, x = 0.464, y = 0.621, name = "Adele Fielder, Elwynn Forest" },
    ["aedi-thriceforged"] = { map = 2521, x = 0.449, y = 0.443, name = "Aedi Thriceforged, Zephras Isle" },
    ["alanna-raveneye"] = { map = 1438, x = 0.368, y = 0.342, name = "Alanna Raveneye, Teldrassil" },
    ["alard-schmied"] = { map = 1416, x = 0.197, y = 0.634, name = "Alard Schmied, Alterac Mountains" },
    ["alchemist-mallory"] = { map = 1429, x = 0.399, y = 0.483, name = "Alchemist Mallory, Elwynn Forest" },
    ["alchemist-narett"] = { map = 1445, x = 0.64, y = 0.477, name = "Alchemist Narett, Dustwallow Marsh" },
    ["alphonse-dumas"] = { map = 2548, x = 0.645, y = 0.82, name = "Alphonse Dumas, Riverglades" },
    ["angelique-butler"] = { map = 1416, x = 0.172, y = 0.611, name = "Angelique Butler, Alterac Mountains" },
    ["angus-hammerhand"] = { map = 1420, x = 0.211, y = 0.458, name = "Angus Hammerhand, Tirisfal Glades" },
    ["arthur-moore"] = { map = 1458, x = 0.702, y = 0.576, name = "Arthur Moore, Undercity" },
    ["basil-frye"] = { map = 1458, x = 0.6, y = 0.289, name = "Basil Frye, Undercity" },
    ["bena-winterhoof"] = { map = 1456, x = 0.466, y = 0.332, name = "Bena Winterhoof, Thunder Bluff" },
    ["bowen-brisboise"] = { map = 1420, x = 0.526, y = 0.556, name = "Bowen Brisboise, Tirisfal Glades" },
    ["brawn"] = { map = 1434, x = 0.318, y = 0.289, name = "Brawn, Stranglethorn Vale" },
    ["bronk-guzzlegear"] = { map = 1426, x = 0.502, y = 0.504, name = "Bronk Guzzlegear, Dun Morogh" },
    ["byancie"] = { map = 1438, x = 0.553, y = 0.568, name = "Byancie, Teldrassil" },
    ["carolai-anise"] = { map = 1420, x = 0.595, y = 0.522, name = "Carolai Anise, Tirisfal Glades" },
    ["charles-worth"] = { map = 1416, x = 0.177, y = 0.602, name = "Charles Worth, Alterac Mountains" },
    ["chaw-stronghide"] = { map = 1412, x = 0.45, y = 0.615, name = "Chaw Stronghide, Mulgore" },
    ["clarise-gnarltree"] = { map = 1431, x = 0.74, y = 0.485, name = "Clarise Gnarltree, Duskwood" },
    ["cyndra-kindwhisper"] = { map = 1438, x = 0.576, y = 0.607, name = "Cyndra Kindwhisper, Teldrassil" },
    ["daeann-steelwind"] = { map = 2521, x = 0.654, y = 0.801, name = "Daeann Steelwind, Zephras Isle" },
    ["dan-golthas"] = { map = 1458, x = 0.708, y = 0.586, name = "Dan Golthas, Undercity" },
    ["dane-lindgren"] = { map = 1453, x = 0.641, y = 0.371, name = "Dane Lindgren, Stormwind City" },
    ["dannelor"] = { map = 1457, x = 0.517, y = 0.125, name = "Dannelor, Darnassus" },
    ["darianna"] = { map = 1457, x = 0.645, y = 0.21, name = "Darianna, Darnassus" },
    ["deek-fizzlebizz"] = { map = 1432, x = 0.458, y = 0.135, name = "Deek Fizzlebizz, Loch Modan" },
    ["delfrum-flintbeard"] = { map = 1439, x = 0.382, y = 0.41, name = "Delfrum Flintbeard, Darkshore" },
    ["doctor-marsh"] = { map = 1458, x = 0.513, y = 0.742, name = "Doctor Marsh, Undercity" },
    ["doctor-martin-felben"] = { map = 1458, x = 0.464, y = 0.741, name = "Doctor Martin Felben, Undercity" },
    ["dwukk"] = { map = 1411, x = 0.521, y = 0.407, name = "Dwukk, Durotar" },
    ["eaysaa-brightgust"] = { map = 2521, x = 0.592, y = 0.763, name = "Eaysaa Brightgust, Zephras Isle" },
    ["eldrin"] = { map = 1429, x = 0.793, y = 0.69, name = "Eldrin, Elwynn Forest" },
    ["emerii-tallgust"] = { map = 2521, x = 0.638, y = 0.806, name = "Emerii Tallgust, Zephras Isle" },
    ["faldron"] = { map = 1457, x = 0.649, y = 0.216, name = "Faldron, Darnassus" },
    ["fimble-finespindle"] = { map = 1455, x = 0.402, y = 0.337, name = "Fimble Finespindle, Ironforge" },
    ["finbus-geargrind"] = { map = 1431, x = 0.774, y = 0.485, name = "Finbus Geargrind, Duskwood" },
    ["franklin-lloyd"] = { map = 1458, x = 0.763, y = 0.733, name = "Franklin Lloyd, Undercity" },
    ["fremal-doohickey"] = { map = 1437, x = 0.108, y = 0.613, name = "Fremal Doohickey, Wetlands" },
    ["ghak-healtouch"] = { map = 1432, x = 0.37, y = 0.493, name = "Ghak Healtouch, Loch Modan" },
    ["gimble-thistlefuzz"] = { map = 1455, x = 0.598, y = 0.455, name = "Gimble Thistlefuzz, Ironforge" },
    ["graham-van-talen"] = { map = 1458, x = 0.753, y = 0.727, name = "Graham Van Talen, Undercity" },
    ["grarnik-goodstitch"] = { map = 1434, x = 0.287, y = 0.768, name = "Grarnik Goodstitch, Stranglethorn Vale" },
    ["gretta-finespindle"] = { map = 1455, x = 0.39, y = 0.327, name = "Gretta Finespindle, Ironforge" },
    ["grondal-moonbreeze"] = { map = 1439, x = 0.382, y = 0.405, name = "Grondal Moonbreeze, Darkshore" },
    ["guillaume-sorouy"] = { map = 1421, x = 0.432, y = 0.41, name = "Guillaume Sorouy, Silverpine Forest" },
    ["gurdok"] = { map = 2548, x = 0.6, y = 0.463, name = "Gur'dok, Riverglades" },
    ["iaadaria-bitterwind"] = { map = 2521, x = 0.663, y = 0.795, name = "Iaadaria Bitterwind, Zephras Isle" },
    ["indari-sunseam"] = { map = 2521, x = 0.447, y = 0.445, name = "Indari Sunseam, Zephras Isle" },
    ["james-van-brunt"] = { map = 1458, x = 0.615, y = 0.303, name = "James Van Brunt, Undercity" },
    ["jaxin-chong"] = { map = 1434, x = 0.281, y = 0.78, name = "Jaxin Chong, Stranglethorn Vale" },
    ["jenna-lemkenilli"] = { map = 1439, x = 0.383, y = 0.411, name = "Jenna Lemkenilli, Darkshore" },
    ["jormund-stonebrow"] = { map = 1455, x = 0.433, y = 0.289, name = "Jormund Stonebrow, Ironforge" },
    ["karn-stonehoof"] = { map = 1456, x = 0.392, y = 0.554, name = "Karn Stonehoof, Thunder Bluff" },
    ["kilhala"] = { map = 1413, x = 0.522, y = 0.317, name = "Kil'hala, The Barrens" },
    ["kray"] = { map = 1456, x = 0.468, y = 0.344, name = "Kray, Thunder Bluff" },
    ["krulmoo-fullmoon"] = { map = 1413, x = 0.448, y = 0.594, name = "Krulmoo Fullmoon, The Barrens" },
    ["kylanna"] = { map = 1440, x = 0.508, y = 0.671, name = "Kylanna, Ashenvale" },
    ["lalina-summermoon"] = { map = 1457, x = 0.589, y = 0.128, name = "Lalina Summermoon, Darnassus" },
    ["lavinia-crowe"] = { map = 1458, x = 0.624, y = 0.616, name = "Lavinia Crowe, Undercity" },
    ["lilliam-sparkspindle"] = { map = 1453, x = 0.622, y = 0.304, name = "Lilliam Sparkspindle, Stormwind City" },
    ["linzy-blackbolt"] = { map = 1416, x = 0.185, y = 0.624, name = "Linzy Blackbolt, Alterac Mountains" },
    ["mahani"] = { map = 1413, x = 0.449, y = 0.594, name = "Mahani, The Barrens" },
    ["mak"] = { map = 1456, x = 0.422, y = 0.431, name = "Mak, Thunder Bluff" },
    ["malcomb-wynn"] = { map = 1458, x = 0.624, y = 0.608, name = "Malcomb Wynn, Undercity" },
    ["mary-edras"] = { map = 1458, x = 0.734, y = 0.557, name = "Mary Edras, Undercity" },
    ["melasa-fairmend"] = { map = 2521, x = 0.631, y = 0.726, name = "Melasa Fairmend, Zephras Isle" },
    ["melynn"] = { map = 1457, x = 0.632, y = 0.223, name = "Me'lynn, Darnassus" },
    ["miaozan"] = { map = 1411, x = 0.554, y = 0.74, name = "Miao'zan, Durotar" },
    ["michelle-belle"] = { map = 1429, x = 0.434, y = 0.656, name = "Michelle Belle, Elwynn Forest" },
    ["milla-fairancora"] = { map = 1457, x = 0.553, y = 0.228, name = "Milla Fairancora, Darnassus" },
    ["mot-dawnstrider"] = { map = 1456, x = 0.449, y = 0.39, name = "Mot Dawnstrider, Thunder Bluff" },
    ["mukdrak"] = { map = 1411, x = 0.522, y = 0.408, name = "Mukdrak, Durotar" },
    ["nadyia-maneweaver"] = { map = 1438, x = 0.418, y = 0.494, name = "Nadyia Maneweaver, Teldrassil" },
    ["naleeia-tattermend"] = { map = 2521, x = 0.431, y = 0.463, name = "Naleeia Tattermend, Zephras Isle" },
    ["nasalanna-windsinger"] = { map = 2521, x = 0.432, y = 0.432, name = "Nasalanna Windsinger, Zephras Isle" },
    ["nurse-neela"] = { map = 1420, x = 0.618, y = 0.528, name = "Nurse Neela, Tirisfal Glades" },
    ["nyassa-swiftdraught"] = { map = 2521, x = 0.437, y = 0.434, name = "Nyassa Swiftdraught, Zephras Isle" },
    ["othesia-evengale"] = { map = 2521, x = 0.643, y = 0.811, name = "Othesia Evengale, Zephras Isle" },
    ["pand-stonebinder"] = { map = 1456, x = 0.296, y = 0.211, name = "Pand Stonebinder, Thunder Bluff" },
    ["pazula"] = { map = 1411, x = 0.567, y = 0.737, name = "Pa'zula, Durotar" },
    ["rawrk"] = { map = 1411, x = 0.542, y = 0.42, name = "Rawrk, Durotar" },
    ["rhiannon-davis"] = { map = 1458, x = 0.701, y = 0.301, name = "Rhiannon Davis, Undercity" },
    ["serge-hinott"] = { map = 1424, x = 0.616, y = 0.192, name = "Serge Hinott, Hillsbrad Foothills" },
    ["shaina-fuller"] = { map = 1453, x = 0.53, y = 0.447, name = "Shaina Fuller, Stormwind City" },
    ["shelene-rhobart"] = { map = 1420, x = 0.654, y = 0.601, name = "Shelene Rhobart, Tirisfal Glades" },
    ["smith-argus"] = { map = 1429, x = 0.417, y = 0.656, name = "Smith Argus, Elwynn Forest" },
    ["sprite-jumpsprocket"] = { map = 1453, x = 0.619, y = 0.307, name = "Sprite Jumpsprocket, Stormwind City" },
    ["strange-hermit"] = { map = 2521, x = 0.54, y = 0.389, name = "Strange Hermit, Zephras Isle" },
    ["sylvanna-forestmoon"] = { map = 1457, x = 0.561, y = 0.241, name = "Sylvanna Forestmoon, Darnassus" },
    ["taladan"] = { map = 1457, x = 0.586, y = 0.132, name = "Taladan, Darnassus" },
    ["taleen-shimmerthread"] = { map = 2521, x = 0.449, y = 0.442, name = "Taleen Shimmerthread, Zephras Isle" },
    ["tally-berryfizz"] = { map = 1455, x = 0.666, y = 0.553, name = "Tally Berryfizz, Ironforge" },
    ["tarn"] = { map = 1456, x = 0.425, y = 0.429, name = "Tarn, Thunder Bluff" },
    ["teg-dawnstrider"] = { map = 1456, x = 0.449, y = 0.377, name = "Teg Dawnstrider, Thunder Bluff" },
    ["tepa"] = { map = 1456, x = 0.444, y = 0.451, name = "Tepa, Thunder Bluff" },
    ["thamner-pol"] = { map = 1426, x = 0.472, y = 0.525, name = "Thamner Pol, Dun Morogh" },
    ["therum-deepforge"] = { map = 1453, x = 0.636, y = 0.368, name = "Therum Deepforge, Stormwind City" },
    ["thonys-pillarstone"] = { map = 1455, x = 0.604, y = 0.449, name = "Thonys Pillarstone, Ironforge" },
    ["thrag-stonehoof"] = { map = 1456, x = 0.392, y = 0.564, name = "Thrag Stonehoof, Thunder Bluff" },
    ["tinkerwiz"] = { map = 1413, x = 0.627, y = 0.363, name = "Tinkerwiz, The Barrens" },
    ["tognus-flintfire"] = { map = 1426, x = 0.453, y = 0.52, name = "Tognus Flintfire, Dun Morogh" },
    ["traugh"] = { map = 1413, x = 0.513, y = 0.289, name = "Traugh, The Barrens" },
    ["trianna"] = { map = 1457, x = 0.636, y = 0.213, name = "Trianna, Darnassus" },
    ["twizwick-sprocketgrind"] = { map = 1412, x = 0.587, y = 0.395, name = "Twizwick Sprocketgrind, Mulgore" },
    ["uthrar-threx"] = { map = 1455, x = 0.437, y = 0.282, name = "Uthrar Threx, Ironforge" },
    ["valiena-swiftgale"] = { map = 2521, x = 0.592, y = 0.762, name = "Valiena Swiftgale, Zephras Isle" },
    ["vance-undergloom"] = { map = 1420, x = 0.618, y = 0.516, name = "Vance Undergloom, Tirisfal Glades" },
    ["vanessa-sellers"] = { map = 1416, x = 0.168, y = 0.622, name = "Vanessa Sellers, Alterac Mountains" },
    ["vhan"] = { map = 1456, x = 0.44, y = 0.446, name = "Vhan, Thunder Bluff" },
    ["victor-ward"] = { map = 1458, x = 0.702, y = 0.297, name = "Victor Ward, Undercity" },
    ["vira-younghoof"] = { map = 1412, x = 0.461, y = 0.639, name = "Vira Younghoof, Mulgore" },
    ["vosur-brakthel"] = { map = 1455, x = 0.665, y = 0.554, name = "Vosur Brakthel, Ironforge" },
    ["waldor"] = { map = 1413, x = 0.46, y = 0.359, name = "Waldor, The Barrens" },
    ["xylinnia-starshine"] = { map = 1444, x = 0.315, y = 0.442, name = "Xylinnia Starshine, Feralas" },
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

-- Same-tier alternatives from the Forever trainer directories, reviewed November 16, 2026.
-- These are recipe-tier pools, never a replacement for vendor/manual/quest sources.
local function Trainers(ids, alliance, horde)
    local pool = { Alliance = {}, Horde = {} }
    for _, key in ipairs(alliance) do pool.Alliance[#pool.Alliance + 1] = points[key] end
    for _, key in ipairs(horde) do pool.Horde[#pool.Horde + 1] = points[key] end
    for _, id in ipairs(ids) do sources[id].trainers = pool end
end
Trainers({2660, 3320, 3323},
    { "aedi-thriceforged", "daeann-steelwind", "groum-stonebeard", "dane-lindgren", "alard-schmied", "delfrum-flintbeard", "tognus-flintfire", "smith-argus", "alphonse-dumas" },
    { "ugthok", "thrag-stonehoof", "basil-frye", "dwukk", "gurdok", "guillaume-sorouy", "angus-hammerhand", "aedi-thriceforged", "daeann-steelwind" })
Trainers({3326, 2666, 2672, 3337},
    { "daeann-steelwind", "rotgath-stonebeard", "therum-deepforge", "alard-schmied", "clarise-gnarltree" },
    { "snarl", "karn-stonehoof", "james-van-brunt", "traugh", "angus-hammerhand", "daeann-steelwind" })
Trainers({2742, 9985, 3501, 9920, 7223, 9928, 9993},
    { "bengus-deepforge", "alard-schmied" },
    { "saru-steelfury" })
Trainers({9959, 16641, 9968},
    { "brikk-keencraft" },
    { "brikk-keencraft" })
Trainers({1245246, 7183, 2331},
    { "iaadaria-bitterwind", "nyassa-swiftdraught", "valiena-swiftgale", "milla-fairancora", "vosur-brakthel", "telathir", "linzy-blackbolt", "alchemist-mallory", "ghak-healtouch", "cyndra-kindwhisper" },
    { "whuut", "kray", "doctor-martin-felben", "miaozan", "carolai-anise", "iaadaria-bitterwind", "nyassa-swiftdraught", "valiena-swiftgale" })
Trainers({2334, 3171, 3173, 7837},
    { "jaxin-chong", "sylvanna-forestmoon", "tally-berryfizz", "lilyssia-nightbreeze", "kylanna", "linzy-blackbolt", "alchemist-narett" },
    { "yelmak", "bena-winterhoof", "doctor-marsh", "serge-hinott", "jaxin-chong" })
Trainers({7845, 3452},
    { "ainethil", "linzy-blackbolt" },
    { "doctor-herbert-halsey" })
Trainers({11465},
    { "kylanna-windwhisper" },
    { "rogvar" })
Trainers({3918, 3922, 3923},
    { "twizwick-sprocketgrind", "tinkerwiz", "strange-hermit", "jemma-quikswitch", "sprite-jumpsprocket", "jenna-lemkenilli", "bronk-guzzlegear", "deek-fizzlebizz" },
    { "thund", "graham-van-talen", "mukdrak", "twizwick-sprocketgrind", "tinkerwiz", "strange-hermit" })
Trainers({7430, 3929, 3931, 3973, 3938, 3978},
    { "trixie-quikswitch", "lilliam-sparkspindle", "finbus-geargrind" },
    { "nogg", "franklin-lloyd" })
Trainers({3945, 3942, 3953, 3955, 12585, 12590, 12589},
    { "springspindle-fizzlegear" },
    { "roxxik" })
Trainers({12591, 12599, 12619, 19788},
    { "buzzek-bracketswing" },
    { "buzzek-bracketswing" })
Trainers({2881, 2152, 3756},
    { "waldor", "emerii-tallgust", "indari-sunseam", "darianna", "gretta-finespindle", "randal-worth", "adele-fielder", "nadyia-maneweaver" },
    { "kamari", "mak", "dan-golthas", "chaw-stronghide", "waldor", "shelene-rhobart", "emerii-tallgust", "indari-sunseam" })
Trainers({20648, 3817, 3763, 2168, 3766},
    { "emerii-tallgust", "faldron", "fimble-finespindle", "simon-tanner", "aayndia-floralwind" },
    { "karolek", "tarn", "arthur-moore", "brawn", "krulmoo-fullmoon", "emerii-tallgust" })
Trainers({20649, 3818, 3764, 7151, 7156, 10507},
    { "telonis" },
    { "una" })
Trainers({10548, 10558},
    { "drakk-stonehand" },
    { "hahrana-ironhide" })
Trainers({2963, 8776},
    { "othesia-evengale", "taleen-shimmerthread", "trianna", "uthrar-threx", "lawrence-schneider", "charles-worth", "grondal-moonbreeze", "eldrin" },
    { "snang", "vhan", "victor-ward", "kilhala", "bowen-brisboise", "othesia-evengale", "taleen-shimmerthread" })
Trainers({2964, 2402, 3848, 3839, 3852},
    { "grarnik-goodstitch", "othesia-evengale", "taleen-shimmerthread", "melynn", "jormund-stonebrow", "sellandus", "charles-worth" },
    { "magar", "tepa", "rhiannon-davis", "grarnik-goodstitch", "mahani", "othesia-evengale", "taleen-shimmerthread" })
Trainers({3865, 8791, 8799, 12074, 12065},
    { "georgio-bolero", "charles-worth" },
    { "josef-gregorian" })
Trainers({18402},
    { "timothy-worthington" },
    { "daryl-stack" })
Trainers({7421, 7418, 7420},
    { "eaysaa-brightgust", "nasalanna-windsinger", "lalina-summermoon", "thonys-pillarstone", "betty-quin", "vanessa-sellers", "alanna-raveneye" },
    { "jhag", "mot-dawnstrider", "malcomb-wynn", "pazula", "vance-undergloom", "eaysaa-brightgust", "nasalanna-windsinger" })
Trainers({7457, 7771, 7795},
    { "taladan", "gimble-thistlefuzz", "lucan-cordell", "vanessa-sellers", "xylinnia-starshine" },
    { "godan", "teg-dawnstrider", "lavinia-crowe" })
Trainers({7863, 13628, 13637, 13702, 13746, 13815},
    { "vanessa-sellers", "kitta-firewind" },
    { "hgarth" })
Trainers({3275, 3276, 3277, 3278, 7928},
    { "melasa-fairmend", "naleeia-tattermend", "dannelor", "nissa-firestone", "shaina-fuller", "angelique-butler", "thamner-pol", "michelle-belle", "byancie", "fremal-doohickey" },
    { "arnok", "pand-stonebinder", "mary-edras", "rawrk", "vira-younghoof", "nurse-neela", "melasa-fairmend", "naleeia-tattermend" })
Trainers({10841, 18629},
    { "doctor-gustaf-vanhowzen" },
    { "doctor-gregory-victor" })
