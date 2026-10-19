local _, Suite = ...
-- Reference stock/base prices, reviewed October 18, 2026; see docs/sources.json.
-- Current trainer offerings, class eligibility and discounted prices remain authoritative.
Suite.WeaponTraining = {
    skills = {
        { 196, "One-Handed Axes" }, { 197, "Two-Handed Axes" },
        { 198, "One-Handed Maces" }, { 199, "Two-Handed Maces" },
        { 200, "Polearms" }, { 201, "One-Handed Swords" }, { 202, "Two-Handed Swords" },
        { 227, "Staves" }, { 264, "Bows" }, { 266, "Guns" }, { 1180, "Daggers" },
        { 2567, "Thrown" }, { 5011, "Crossbows" }, { 15590, "Fist Weapons" },
        { 5009, "Wands" }, { 203, "Unarmed" }, { 204, "Defense" },
    },
    trainers = {
        { name = "Woo Ping", place = "Stormwind · Trade District, Weller's Arsenal", faction = "Alliance", skills = { 5011, 1180, 201, 202, 227, 200 } },
        { name = "Buliwyf Stonehand", place = "Ironforge · Military Ward, Timberline Arms", faction = "Alliance", skills = { 15590, 266, 196, 197, 198, 199 } },
        { name = "Bixi Wobblebonk", place = "Ironforge · Military Ward, Timberline Arms", faction = "Alliance", skills = { 5011, 1180, 2567 } },
        { name = "Ilyenia Moonfire", place = "Darnassus · Warrior's Terrace", faction = "Alliance", skills = { 264, 1180, 15590, 227, 2567 } },
        { name = "Sayoc", place = "Orgrimmar · Valley of Honor, Arms of Legend", faction = "Horde", skills = { 264, 1180, 15590, 196, 197, 227, 2567 } },
        { name = "Hanashi", place = "Orgrimmar · Valley of Honor, Arms of Legend", faction = "Horde", skills = { 264, 196, 197, 227, 2567 } },
        { name = "Ansekhwa", place = "Thunder Bluff · Lower Rise, weapons tent", faction = "Horde", skills = { 266, 198, 199, 227 } },
        { name = "Archibald", place = "Undercity · War Quarter", faction = "Horde", skills = { 5011, 1180, 201, 202, 200 } },
    },
}
