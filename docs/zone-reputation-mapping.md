# Zone reputation mapping — November 11, 2026

`ZoneReputation.lua` selects these primary outdoor quest/reputation factions on world entry and zone/subzone changes. These are curated defaults for the main local questing faction, not claims that every quest awards that reputation. Known local overrides take priority; a subsequent native standing change can select any readable faction. Unknown/mixed areas preserve the current watch until a standing change. Instances preserve the watch. Native faction lookup must succeed before selection.

## Region defaults

| Region (native area ID) | Alliance | Horde |
| --- | --- | --- |
| Dun Morogh (1), Loch Modan (38), Wetlands (11), Ironforge (1537) | Ironforge 47 | — |
| Elwynn (12), Westfall (40), Redridge (44), Duskwood (10), Stormwind (1519) | Stormwind 72 | — |
| Teldrassil (141), Darkshore (148), Darnassus (1657) | Darnassus 69 | — |
| Durotar (14), Barrens (17), Orgrimmar (1637) | — | Orgrimmar 76 |
| Mulgore (215), Thunder Bluff (1638) | — | Thunder Bluff 81 |
| Tirisfal (85), Silverpine (130), Undercity (1497) | — | Undercity 68 |
| Ashenvale (331), Stonetalon Mountains (406) | Darnassus 69 | Orgrimmar 76 |
| Feralas (357) | Darnassus 69 | Thunder Bluff 81 |
| Hillsbrad Foothills (267) | Stormwind 72 | Undercity 68 |
| Dustwallow Marsh (15) | Stormwind 72 | Orgrimmar 76 |
| Blasted Lands (4), Burning Steppes (46) | Stormwind 72 | — |
| Hinterlands (47) | Wildhammer Clan 471 | — |
| Badlands (3), Swamp of Sorrows (8) | — | Orgrimmar 76 |
| Thousand Needles (400) | — | Thunder Bluff 81 |
| Riverglades (16591) | Brotherhood of the Horse 2826 | Bolder'ok Clan 2782 |
| Zephras Isle (16593) | High Order 2779 | Windshapers 2778 |
| Western Plaguelands (28), Eastern Plaguelands (139) | Argent Dawn 529 | Argent Dawn 529 |
| Searing Gorge (51) | Thorium Brotherhood 59 | Thorium Brotherhood 59 |
| Moonglade (493), Silithus (1377) | Cenarion Circle 609 | Cenarion Circle 609 |
| Tanaris (440) | Gadgetzan 369 | Gadgetzan 369 |
| Mount Hyjal (616) | Guardians of Hyjal 2765 | Guardians of Hyjal 2765 |

An em dash means no region default for that side. It does not mean the faction cannot exist in that character's reputation list. In particular, city/faction allegiance alone does not justify assigning the other side's quests to that faction.

## Local overrides (both sides)

| Area | Native area ID | Faction ID |
| --- | --- | --- |
| Booty Bay | 35 | 21 |
| Ratchet | 392 | 470 |
| Gadgetzan | 976 | 369 |
| Everlook | 2255 | 577 |
| Powderfuse Port | 16727 | 2827 |
| Shadowgale Forest | 16631 | 2758 (Nightclaw Druids) |

Do not assign a blanket region default to Desolace (competing centaurs and faction hubs), Felwood (multiple quest/grind factions), Stranglethorn, Azshara, Un'Goro, Winterspring (Everlook, Timbermaw and Wintersaber activities), or unestablished Shen'dralas questing. Known local town overrides and actual standing changes still work there. Battleground factions and dungeon-only associations are excluded from outdoor selection.

## Evidence and limits

Area/faction numeric metadata is corroborated read-only against the installed QuestieDB `src/corrections/enum/zones.lua`, `src/corrections/enum/factions.lua` and `support/Forever/Zones` mappings. This is development reference data, not a dependency and not native test evidence. In particular, area 16591 maps to Riverglades UI map 2548, area 16593 to Zephras Isle, and area 616 is the Forever outdoor Hyjal area. The runtime uses native localized `C_Map.GetAreaInfo` names rather than copied English labels.

Primary publisher references checked November 11:

- [Questie's own Forever compatibility notes](https://github.com/Questie/Questie/blob/master/docs/forever-development.md): Riverglades/Zephras area-map relationships.
- [Wowhead Riverglades overview](https://www.wowhead.com/forever/guide/riverglades-zone-overview): Alliance Brotherhood, Horde Bolder'ok and the local Powderfuse settlement. [Brotherhood 2826](https://www.wowhead.com/forever/faction=2826/brotherhood-of-the-horse) and [Bolder'ok 2782](https://www.wowhead.com/forever/faction=2782/bolderok-clan) corroborate faction identities.
- [High Order 2779](https://www.wowhead.com/forever/faction=2779/high-order), [Windshapers 2778](https://www.wowhead.com/forever/faction=2778/windshapers) and [Nightclaw Druids 2758](https://www.wowhead.com/forever/faction=2758/nightclaw-druids): Forever-specific Skyborne factions. The Nightclaw native description identifies Shadowgale Forest.
- [Forever Guardians of Hyjal 2765](https://www.wowhead.com/forever/faction=2765/guardians-of-hyjal): native description explicitly identifies Mount Hyjal. Do not substitute Cataclysm's 1158.
- [Cenarion Circle 609](https://www.wowhead.com/forever/faction=609/cenarion-circle), [Argent Dawn 529](https://www.wowhead.com/forever/faction=529/argent-dawn), [Thorium Brotherhood 59](https://www.wowhead.com/forever/faction=59/thorium-brotherhood): faction identity references. Old user comments on these pages are not current Forever behavior proof. Regional priorities remain curated questing defaults and need native checks.

The direct Powderfuse Wowhead faction-page fetch returned 403; no successful page inspection is claimed for that ID. Its 2827 client record was corroborated by the [client-table publisher](https://wowcampfire.com/factions) and its Riverglades settlement by the overview above. No third-party implementation, assets or layout were copied.

Full automated validation checks mapping decisions, native localized-name matching, both sides, local override entry/exit, unknown regions, unchanged manual selections, world entry, combat deferral and event-based tracking. Actual running build/Interface, all mapped-zone native results, visuals and taint remain unreported/pending.
