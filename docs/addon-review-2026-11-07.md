# Full addon review — November 7, 2026

Reviewed the canonical checkout at `C:\Games\Development\GitHub Repos\WoW Forever Suite`, including existing uncommitted work on top of `5a0a35b`. This is a source, API, behavior-substitute and packaging review. It is not a claim that every module works in the running game.

Subsequent November 7 work changes item macro maintenance to one-shot checks after use. See the newest entries in `forever-development.md` and `testing.md`; the archive hash and 30,654-assertion result below describe the earlier review snapshot, not that later patch. A new release package must be built from the final versioned tree.

## Release assessment

The reviewed candidate passes offline validation. A real stale training-data problem was corrected; unused bookkeeping and outdated contact-book help were cleaned up. No additional confirmed API-signature blocker, orphaned runtime file or unreachable named implementation was identified by the checks described below.

**Do not treat this as unconditional CurseForge clearance.** The pending keybind change addresses a reported protected-action block and needs its focused native retest. Contact scoping/recovery and new placement behavior also need their documented native checks. Previously reported world-map/tracker taint remains open and deferred by the user's earlier decision; this review does not call it fixed or restart that investigation.

[v1.0.5 is already published](https://github.com/drockzoids-wow/WoW-Forever-Suite/releases/tag/v1.0.5), observed through GitHub's releases API on November 7. Core/both TOCs intentionally remain at 1.0.5 during review. Before publishing, select a fresh available version (1.0.6 if still unused), rename the Unreleased changelog heading, align Core/both TOCs, rebuild and recheck the final committed tree. Preserve the existing release/tag. No commit, push, tag, upload, deployment, junction or on-disk SavedVariables change was performed.

## Current source evidence

- Installed `C:\Games\World of Warcraft\_forever_\Wow.exe` reports **1.60.1.70862**. This is an executable observation, not a running-client build/Interface report.
- The public Blizzard UI-source mirror's Forever branch now identifies **1.60.1 (70862)** at [9dc84f0d3bbae1768ac3405b3716000bd93eda06](https://github.com/Gethe/wow-ui-source/commit/9dc84f0d3bbae1768ac3405b3716000bd93eda06), dated November 7 UTC. This supersedes the older source-lag qualification for this review. The mirror is an export of Blizzard source, not an official compatibility certification.
- Downloaded that entire pinned source into `.cache/review-20261107/`. Archive SHA256: `63EBDFD6C2D64DBAEB40BA50C9180553CB4CCB7166F31D004C2F7DB6F0FF8506`. Earlier caches/history were retained.
- Indexed 642 generated Lua documentation files containing 5,144 API function declarations. Cross-referenced 146 distinct `C_*` member names resolved from direct references and simple local aliases, and inspected higher-risk native-widget and table-indirection paths separately. No missing-required-argument finding in the statically resolvable documented calls. This scan is not a complete dynamic-call verifier.
- The only two referenced namespace members absent from generated docs were `C_PetJournal.GetPetInfoByItemID` and `GetNumCollectedInfo`. Current native [DressUpFrames.lua](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/DressUpFrames.lua) and [Blizzard_PetBattleUI.lua](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_PetBattleUI/Shared/Blizzard_PetBattleUI.lua) still reference these legacy calls. Suite checks availability and readable IDs/counts; keep the conditional fallback. Native references alone do not guarantee those APIs on every game type.
- The current [ActionButton.lua](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_ActionBar/Shared/ActionButton.lua) still reads native HotKey text before later native action/bar updates. The existing Suite-owned short-label overlay remains a reasonable response to the reported taint path; its success is still unverified in game.
- Checked the current [damage-meter declarations](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/DamageMeterDocumentation.lua), [container declarations](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua), [spell declarations](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua), [aura-container implementation](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua) and relevant item/trait/secret predicates. Secret amounts remain restricted; passing an opaque value to a permitted widget is not permission to compare, sort, format through ordinary Lua, or serialize it.

## Findings and corrections

| Priority | Finding | Result |
| --- | --- | --- |
| P1 before release | The reported short-keybind action-bar block has a pending source fix, with no native resolution recorded. | Preserve the overlay fix and require its focused reload/combat/action-update retest. No new taint-safety claim. |
| P1 release process | Reusing v1.0.5 would conflict with the existing publication and tag. | Added Unreleased notes for the current batch; retained the current version for review. Fresh version/tag required at release. |
| P2 fixed | Class training data still pinned October 22 upstream facts; the current upstream contains corrections and an extra rank. | Regenerated only the changed factual records; details below. |
| P2 fixed | README still described an editable contact ruleset after current code made server type automatic. | Updated help for automatic region/server-type scope and the category chooser. |
| P3 fixed | One unused numeric-loop binding and four retained fields had no consumers. | Removed `depth`, starter-cache `missingSpell`, planner `starterButton`/`import` handles and GUI `breadcrumbHome` handle. Buttons and callbacks remain. |

Training facts now pin [WhatsTraining Forever dd4256471d65149ad6e8d00ad1f18fa7c31e7a6e](https://github.com/fusionpit/WhatsTraining/tree/dd4256471d65149ad6e8d00ad1f18fa7c31e7a6e/Classes/Camelot). The [upstream comparison](https://github.com/fusionpit/WhatsTraining/compare/e0d52183bac0581464d91b3b859528d53afd4a0d...dd4256471d65149ad6e8d00ad1f18fa7c31e7a6e) changes only Paladin and Shaman class data. No upstream UI/runtime implementation was imported.

| Spell | Previous catalog | Updated catalog |
| --- | --- | --- |
| Paladin Righteous Fury, 25780 | Level 16, 30s | Level 10, 3s |
| Paladin Retribution Aura rank 1, 7294 | 30s | 15s |
| Shaman Call of the Elements, 66842 | 70s | 22s |
| Shaman Call of the Spirits, 66844 | 70s | 1g 20s |
| Shaman Lava Burst rank 2, 1238299 | 2g 40s | 1g 20s |
| Shaman Lava Burst rank 3, 1238300 | Missing | Level 50, 2g 40s; requires rank 2 and talent 408490 |

There are now 1,410 class/pet training records. Names/ranks continue to use the existing 70532 client exports; they are not relabelled as 70862 exports. Base prices are community facts, not newly measured server prices. Recorded-price mode, native learned-state checks, talent/rank prerequisites and server-hotfix offering extensions remain intact. The regression test failed against the previous data before regeneration, then passed with explicit price/level/prerequisite and recorded-price preservation checks. The full MIT notice is unchanged and included; the generator and NOTICE revision were updated.

## Dormant-code and packaging audit

All 81 shipped Lua files parse as Lua 5.1 and are loaded by both identical TOCs. The scope-aware audit found no remaining unused local-binding candidates, statements following unconditional return/break, unreferenced named-method candidates or duplicate table keys. All 67 spec files are reached through direct/nested test registration. All three shipped textures have references; no unexpected shipped input was found.

Reference counts were interpreted, not used as automatic deletion rules. Namespace module exports are intentional; `Suite.pending` keys are read dynamically by Core; native options such as aura `maxDuration` and layout `ignoreInLayout` are consumed by Blizzard; widget handles used by tests support observable interaction checks. Saved-data migrations and restoration snapshots remain necessary when upgrading old installations or disabling a feature. Retired quest location/nameplate runtime files remain absent, with only their saved-field cleanup retained.

Static global assignment findings are declared SavedVariables, binding/slash declarations and the documented minimap-shape compatibility hook. Dynamic shortcut globals and named frame/binding targets are intentional. No new global API replacement was added. Suite-owned `OnUpdate` handlers remain confined to active drag/resize/scroll gestures; enabled minimap statistics, leveling time and combat meter duration use their existing bounded-purpose timers rather than new per-frame polling.

## Module-by-module assessment

Every Lua file is listed below. “Reviewed” means source/automated evidence; the final column identifies native validation or a material limitation, not a failed check.

| Files | Review focus/result | Native check / limitation |
| --- | --- | --- |
| Core.lua, Profiles.lua, Bindings.lua, Shortcuts.lua | Load order, initialization/migrations, per-character versus profile data, deferred work, alias ownership and binding targets reviewed. | Reload/relog, profile switches, alias conflicts and native save/cancel behavior. |
| Theme.lua, Setup.lua, SettingsCatalog.lua, GUI.lua, GearSettings.lua, ProfileSettings.lua, BuffSettings.lua, WindowPlacement.lua | Route/search wiring, staged setup, original styling, combat deferral and launcher geometry reviewed; unused handles removed. | Small screens, multiple UI scales, focus/Escape, cross-opening tools and settings. |
| Minimap.lua, MinimapButton.lua, MinimapDrawer.lua | Native coordinate/header ownership, reversible square sizing, original-button collection/restoration, drag cancellation and optional launcher behavior reviewed. | Round/square toggles, native Edit Mode, third-party buttons and changed scale. |
| WorldMap.lua, MapRevealData.lua | Art/layer guards, optional overlays, retained native map management and data provenance reviewed. | Earlier taint report remains deferred/open; generated terrain data is older than current client. |
| Windows.lua | Header hit regions, native controls, bag title forwarding, Ctrl-wheel scaling/reset, original restoration and combat deferral reviewed. | Native window/bag variants and other addons can alter frame structure; support is deliberately limited. |
| BagSort.lua, CombinedBags.lua, AutoOpen.lua, BagSpace.lua | One-shot bag visits, reversible slot order, context/GUID revalidation, bounded opening attempts and explicit native deletion confirmation reviewed. | Item operations, native restrictions, partial bag data, interrupted gestures and ordinary cursor use. |
| ActionBars.lua, ActionBarSkin.lua, HUDSkin.lua, Keybinds.lua | Readable range state, restored art/CVars, native value rendering and separate abbreviated labels reviewed. | Short-label taint retest is a release priority; verify empty slots, forms, macros and extra bars. |
| UnitFrames.lua, TargetThreat.lua, CombatIndicator.lua, Castbars.lua, ProcAlerts.lua, BuffBorders.lua | Public identity/secret predicates, native cosmetic restoration, click-through alerts, castbar geometry and event/timer cleanup reviewed. | Actual class/reactive-spell availability, native aura privacy, Edit Mode and combat appearance. |
| Vendor.lua, MerchantKnown.lua, Loot.lua | Merchant/context checks, revalidated junk stacks, buyback limits, native purchase/confirmation ownership and quick-loot visit guards reviewed. | Vendor failures, protected requests, modifier/manual loot and collected-pet capability differences. |
| Quests.lua, QuestItem.lua, QuestTrackerSkin.lua, QuestTrackerState.lua, ZoneReputation.lua | Quest readiness, Shift bypass, bounded requests, native secure item actions, tracker state and localized area matching reviewed. | Tracker taint remains deferred/open; unknown quest/service combinations and zone coverage stay native/limited. |
| ProfessionHelper.lua, Audio.lua | Secure modifier Disenchant, independent optional enchant confirmations, event capability checks, media-aware/throttled audio refresh reviewed. | Destructive actions require their documented deliberate click/prompt workflow; device changes and replacement APIs need native checks. |
| TrainingCatalogData.lua, TrainingCatalog.lua, TrainingWeapons.lua, Training.lua | Current upstream class facts corrected; price modes, rank/talent/class/race filters, pins and contextual/native companion placement reviewed. | Visit Paladin/Shaman trainers; verify recorded costs, wishlist totals and new rank visibility. |
| TalentPlanner.lua, TalentPlannerRules.lua, TalentPlannerOrder.lua, TalentPlannerStarterData.lua, TalentPlannerStarters.lua, TalentPlannerUI.lua | Native read-only model, budget/prerequisites, independent drafts, starter mapping, manual learning guidance and import validation reviewed. | User's production acceptance retained; detailed all-class/starter/bonus-point coverage is not newly established. |
| Items.lua, Scoring.lua, Character.lua, EquipmentSets.lua, Tooltips.lua | Async item data, disclosed weighted estimates, complete hand combinations, ignored-slot scope and tooltip-data/inspection lifecycle reviewed. | Stat weights do not model all effects/set bonuses; no definitive BiS claim. Native comparisons/inspect timing and manual set saving. |
| Inventory.lua, CharacterDashboard.lua, InventorySearch.lua, InventoryBrowser.lua, OfflineBank.lua | Complete-scan preservation, region/GUID identity, saved/live distinctions, search indexing, snapshot-only bank display and browser handoff reviewed. | Alt records may be stale; native bank tabs, partial loading, item metadata and launcher placement. |
| Mail.lua, ReleaseTools.lua | Same-ruleset scoping, CAMWOW recovery, category editing, tombstones, supply targets and partial inbox/deadline recording reviewed. | Priority native PvE/PvP/Hardcore switching, retained metadata, inbox timing and interrupted UI work. |
| Chat.lua, ChatCopy.lua, ChatHistory.lua | Reversible presentation, readable snapshot copying, Refresh placement, bounded saved history and hidden-message rejection reviewed. | Actual Ctrl+C, chat tabs, mouse/focus layering, combat clearing and history replay. |
| MacroItems.lua, Macros.lua | Explicit ownership-safe writes, external edits/conflicts, async supplies, native targeting and combat deferral reviewed. | Execute representative class/supply/pet/coating recipes; native item/form/stance rules remain authoritative. |
| Camping.lua, CampingItems.lua | Secure controller/pose handling, public proximity, carried object discovery, fresh-data/combat hiding and bounded timers reviewed. | Native proximity, camp objects/benefits and English tooltip discovery; no new exact-build gameplay proof. |
| Leveling.lua, Journey.lua | Character-owned sessions/history, reload checkpoints, partial observations, journal attribution and optional tracking reviewed. | XP/money/reputation event ordering, reload/combat transitions and saved recap accuracy. |
| BuffCatalog.lua, MissingBuffs.lua, BuffReminders.lua, CombatBuffs.lua | Rank/recipient choices, optional expiry/weapon reminders, native opaque aura composition, secure actions and preview cleanup reviewed. | Raid/dungeon privacy, pooled aura expiry, group changes, masking/spacing and previous anchor-error retest. |
| DamageMeters.lua, MeterParity.lua, DamageMeterMenus.lua, DamageMeterDetails.lua | Secret data goes to supported widgets; readable-only percentages, history/detail guards, shared lock, corners, visibility and timer cleanup reviewed. | Live combat/reload, secret amounts, session changes, death recap, scrolling, lock and geometry. |

## Functionality recommendations

These are proposals, not newly enabled features or silently expanded scope.

1. **Before release: prioritize the focused native pass over adding more modules.** Exercise keybinds/action updates, contact server-type switching, companion placement, reminders/meters, then disable/re-enable/reload/profile transitions. Capture `/wfs status` and the actual first error/taint chain if anything fails. Keep the earlier deferred map/tracker reports honestly open.
2. **Add a compact support/capability report in a later patch.** Extend existing status reporting with enabled modules and explicit unavailable-capability reasons, using public build/configuration data only. This would make future source/build drift and “enabled but unavailable” reports easier to diagnose.
3. **Improve Supply Checklist input and event handling.** Offer item drag-and-drop plus an item tooltip for rows; keep pasted IDs/links and complete carried-bag scans. Coalesce metadata-result bursts before rescanning bags. Bank inclusion should be a separate disclosed optional scope because snapshots can be stale.
4. **Improve Mail Deadlines review freshness.** Add a manual Refresh control and a time-as-of label. Refresh may recompute the remaining time from saved observations, but must not imply an inbox was queried away from a mailbox. Avoid a new idle ticker.
5. **Share full talent plans.** A future versioned export can include validated leveling order and optional notes, with backward-compatible WFS1 rank imports. Current WFS1 export carries ranks only, so recipients reconstruct point order.
6. **Consider profession-training planning after this release.** The current upstream now has factual profession data, making an optional trainer-cost/reagent reference possible. Treat this as new product work with independent source/license/API validation; do not import its UI or automatically craft/buy anything.

## Validation and release handoff

- `node scripts/check-addon.cjs`: **81 Lua 5.1 files; identical TOCs/Core version; 30,654 behavior assertions pass**. Baseline was 30,637. The increase includes explicit training regressions and the extra catalog row's generic validation.
- Scope-aware cleanup audit and package/reference inventory: **81 Lua files, 90 expected shipped inputs, 67 registered spec files**. No remaining unused-binding/unreferenced-named-method/unreachable-statement candidates; no duplicate table keys.
- `git diff --check`: clean. Current source metadata JSON parses.
- Ran `scripts/Package.ps1` locally and compared **all 90 archived files** with source by SHA256, with no extras, missing files or duplicates. Caches/tests/scripts/research remain excluded. Archive SHA256: `27E1BBB49DDF9A1E83A39394011B0205654BC9CF37D8B888B2D1A89C0FDBE4B0`.
- This rebuilt `dist/WoWForeverSuite-1.0.5.zip` is a **local review candidate**, not the already-published 1.0.5 bytes and not a release artifact to upload as 1.0.5. The pre-review local archive was preserved in `.cache/review-20261107/`. Rebuild after the fresh release-version change.
- Detailed temporary scan outputs, pinned sources and package hash receipt are under `.cache/review-20261107/`; required new training inputs are under `.cache/training-catalog-20261107/`. They are development-only and intentionally untracked/unshipped.
- Include intended untracked `WindowPlacement.lua` and its spec when preparing the release commit. Local checks/package creation can see untracked files that GitHub Actions will not receive until committed. Run the final checks again on the intended release tree and inspect the tag-triggered publishing result separately.

No new in-game results were recorded. Follow the new review smoke checklist at the top of `docs/testing.md` before deciding the candidate is ready to publish.
