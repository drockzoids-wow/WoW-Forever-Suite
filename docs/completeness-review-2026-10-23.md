# Canonical addon completeness review — October 23, 2026

Canonical source: P:/GitHub Repos/WoW Forever Suite, version 1.0.0. No additional missing runtime implementation was found in the available update evidence. Existing pending changes were preserved. No other checkout, game installation, junction or SavedVariables was changed.

## Scope and evidence

Reviewed 163 feature-plan sections, the latest turns of 45 available project chats, canonical Git/file history, prior reconciliation records and the current addon integration. All 67 Lua files are in the TOC; all 58 test files are reachable from tests/addon_spec.lua. A static named-module call scan found no unresolved direct calls in its supported patterns. All 23,342 behavior assertions pass; the suite exercises all 28 settings pages and indexed controls. Both TOCs match. These checks establish source integration, not native permission/taint/visual correctness.

## Feature reconciliation

| Update area | Canonical implementation / focused checks | Result |
| --- | --- | --- |
| Seasonal food/water | MacroItems.lua, Macros.lua / macros_spec.lua | Present, including subclass-8 percentage candy |
| Combat indicator | CombatIndicator.lua / combat_indicator_spec.lua | Present with settings, setup, preview and lock |
| Current/Previous/Overall session journal | Leveling.lua, Journey.lua, GUI.lua / leveling_spec.lua, journey_spec.lua | Present with permanent history and detail views |
| Default class and weapon training | TrainingCatalogData.lua, TrainingCatalog.lua, TrainingWeapons.lua, Training.lua / training_catalog_spec.lua, training_spec.lua | Present with bundled data/license, prices, ranks, prerequisites, faction references |
| Training presentation and docking | Training.lua / training_spellbook_spec.lua, window_layers_spec.lua | Present with icons/colors, trainer/spellbook companion, fixed headers |
| Preferred armor and equipped markers | Items.lua, Scoring.lua, Tooltips.lua / armor_upgrade_spec.lua, upgrade_spec.lua, items_spec.lua | Present, including equipped-origin suppression and hand comparisons |
| Explained gear and profiles | GearSettings.lua, Profiles.lua, ProfileSettings.lua / gear_profiles_spec.lua, settings_profiles_spec.lua | Present |
| Known vendor items and shop interaction | MerchantKnown.lua, Vendor.lua, Quests.lua / merchant_known_spec.lua, vendor_spec.lua, quests_spec.lua | Present |
| Repair and junk confirmation rules | Vendor.lua / vendor_spec.lua | Present |
| Dark typing box, channel/bright border and history | Chat.lua, ChatHistory.lua / chat_spec.lua, chat_history_spec.lua | Present |
| Shared border colors | Theme.lua and themed consumers / theme_spec.lua | Present |
| Setup guide and settings navigation | Setup.lua, SettingsCatalog.lua, GUI.lua / setup_spec.lua, gui_spec.lua, workspace_layout_spec.lua | Present with new Combat page |
| Quest tracker layering and data-ready pickup | QuestTrackerSkin.lua, Quests.lua / quest_tracker_skin_spec.lua, quests_spec.lua | Present |
| Native windows, bags, clock/stopwatch movement | Windows.lua / windows_spec.lua | Present |
| Combined bag order and container continuation | CombinedBags.lua, AutoOpen.lua / combinedbags_spec.lua, autoopen_spec.lua | Present |
| Low bag-space discard UI | BagSpace.lua / bagspace_spec.lua | Present |
| Minimap square/header/quest ring and drawer | Minimap.lua, MinimapButton.lua, MinimapDrawer.lua / minimap_spec.lua, minimapdrawer_spec.lua | Present |
| World map reveal | WorldMap.lua, MapRevealData.lua / worldmap_spec.lua | Present |
| Action range, pet selection, cooldown and progress skins | ActionBars.lua, ActionBarSkin.lua, HUDSkin.lua, BuffBorders.lua / actionbars_spec.lua, actionbar_skin_spec.lua, hud_skin_spec.lua, buff_borders_spec.lua | Present |
| Class health/threat and character item level | UnitFrames.lua, TargetThreat.lua, Character.lua / unitframes_spec.lua, targetthreat_spec.lua, character_spec.lua | Present |
| Mail rulesets and surname fallback | Mail.lua / mail_spec.lua | Present |
| Inventory, bank, dashboard and search | Inventory.lua, InventoryBrowser.lua, InventorySearch.lua, OfflineBank.lua, CharacterDashboard.lua / respective inventory/dashboard/bank checks | Present |
| Camping, buff requests/reminders and class macros | Camping.lua, CampingItems.lua, MissingBuffs.lua, BuffReminders.lua, Macros.lua / camping_spec.lua, missing_buffs_spec.lua, class_macros_spec.lua | Present |
| Audio, castbars, disenchant and zone reputation | Audio.lua, Castbars.lua, ProfessionHelper.lua, ZoneReputation.lua / audio_spec.lua, qol_trio_spec.lua | Present |
| Icon/logo and attribution assets | Media/ and NOTICE.txt plus TrainingCatalog-LICENSE.txt | Included in the source archive |

Standalone quest pins, quest-mob nameplate markers, their catalog and updater were intentionally removed at the user's request in 0.2.97. They must not be restored as missing features. Names such as QuestAutomation.lua, AudioSync.lua, ModernWindow.lua and PrepMacros.lua in the feature notes are external/native behavior references, not missing Suite files.

## Corrections made

The README did not mention the newly added combat indicator or seasonal macro priority; those sections are now included. The existing .sha256 sidecar still contained the earlier 1.0.0 archive hash; it now matches the current ZIP. No runtime code correction was required by this audit. Original README/checksum are backed up in .cache/completeness-audit-20261023/before.

## Remaining configuration issue

The app's saved project folder and existing chats still open outside the canonical checkout. The available project tools can read this configuration but cannot change its folder. Point the saved project at P:/GitHub Repos/WoW Forever Suite to prevent new chats starting elsewhere. Project instructions already require P: for all actual work. No app database or project settings were edited.

## Limits

This review covers the available recorded evidence and latest chat turns, not a claim that every turn of every archived chat was exhaustively reconstructed. Full tests and source/package hashes cannot verify live rendering, taint safety, server catalog correctness or SavedVariables disk persistence. Use docs/testing.md and record the active client build/Interface for those results.
