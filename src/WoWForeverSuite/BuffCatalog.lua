local _, Suite = ...
-- Spell IDs identify localized upkeep families, not a copied spell implementation.
-- The live learned spellbook chooses actual actions/ranks; talent spells are never inferred for teammates.
Suite.BuffCatalog = {
    { key = "intellect", class = "MAGE", roots = { 1459, 23028 }, group = true, incoming = true },
    { key = "armor", class = "MAGE", roots = { 6117, 7302, 168, 30482 } },
    { key = "magic", class = "MAGE", roots = { 604, 1008 }, group = true },
    { key = "fortitude", class = "PRIEST", roots = { 1243, 21562 }, group = true, incoming = true },
    { key = "spirit", class = "PRIEST", roots = { 14752, 27681 }, group = true },
    { key = "shadow", class = "PRIEST", roots = { 976, 27683 }, group = true, incoming = true },
    { key = "inner", class = "PRIEST", roots = { 588, 73413 } },
    { key = "form", class = "PRIEST", roots = { 15473 }, toggle = true },
    { key = "racial", class = "PRIEST", roots = { 2652, 18137 } },
    { key = "ward", class = "PRIEST", roots = { 6346 }, group = true },
    { key = "mark", class = "DRUID", roots = { 1126, 21849 }, group = true, incoming = true },
    { key = "thorns", class = "DRUID", combat = true, roots = { 467 }, group = true, incoming = true },
    { key = "omen", class = "DRUID", roots = { 16864 } },
    { key = "aspect", class = "HUNTER", roots = { 13165, 13163, 13161, 13159, 5118, 20043 } },
    { key = "trueshot", class = "HUNTER", roots = { 19506 }, group = true, party = true, upkeep = true, toggle = true },
    { key = "armor", class = "WARLOCK", roots = { 706, 687, 28176 } },
    { key = "breathing", class = "WARLOCK", roots = { 5697 }, group = true, incoming = true },
    { key = "detection", class = "WARLOCK", roots = { 132 }, group = true, incoming = true },
    { key = "blessing", class = "PALADIN", roots = { 19740, 19742, 20217, 20911, 19977, 1038,
        25782, 25894, 25898, 25899, 25890, 25895 }, group = true, incoming = true },
    { key = "fury", class = "PALADIN", roots = { 25780 }, combat = true, extra = true },
    { key = "aura", class = "PALADIN", roots = { 465, 7294, 19746, 19891, 19888, 19876, 20218 }, group = true, party = true, upkeep = true, toggle = true, incoming = true },
    { key = "shield", class = "SHAMAN", combat = true, roots = { 324, 24398 } },
    { key = "earth", class = "SHAMAN", roots = { 8075, 8071 }, auras = { 8076, 8072 }, group = true, party = true, upkeep = true, incoming = true },
    { key = "water", class = "SHAMAN", roots = { 5675, 5394 }, auras = { 5677, 5395 }, group = true, party = true, upkeep = true, incoming = true },
    -- These Forever effects conflict; accepting any avoids demanding all alternatives.
    { key = "meleetotem", class = "SHAMAN", roots = { 8512, 8835, 8227 }, auras = { 8515, 8836, 8228 }, group = true, party = true, upkeep = true, incoming = true },
    { key = "imbue", class = "SHAMAN", roots = { 8232, 8024, 8017, 8033 }, weapon = true },
    { key = "shout", class = "WARRIOR", combat = true, roots = { 6673, 469 }, group = true, party = true, incoming = true },
}
