# Forever Suite quality and feature review

## Whole-addon follow-up — November 10, 2026

Reviewed the current 1.0.9 working tree, including the pending gear/spec, support-report and checklist-input changes. Preserve those changes; the assessment below remains the historical November 9 snapshot.

**One reproducible correction:** `Inventory:ScanContainers` accepted a zero-capacity backpack as a complete observation. When another equipped bag was readable, it saved partial totals over the previous complete snapshot; when all bags reported zero it could save an empty inventory. Supply Checklist shares this reader and could consequently show false shortages. Require positive capacity for backpack 0, matching the existing slot-view rule. Optional unequipped bags still accept zero slots and empty purchased-bank lists retain their existing semantics. No retry timer, setting or schema change. A new regression fails before the fix; six added assertions cover saved-snapshot preservation, partial-scan rejection, checklist unknown/recovery, optional empty bags and resumed capture. This is an offline reproduction, not a report of observed native occurrence.

| Check | November 10 result |
| --- | --- |
| Full addon checker | 85 Lua 5.1 files, identical TOCs/Core 1.0.9, 34,089 substitute behavior assertions pass |
| Static API scan against pinned build 70862 | 5,144 documented functions; 157 distinct C_* references; no missing required arguments, unknown literal registered events or duplicate literal table keys. The same two guarded legacy pet-journal fallbacks remain qualified below. Dynamic calls and ordinary-addon permissions are not established. |
| Scope and input inventory | No unused-local, unreferenced-method or unreachable-statement candidates; 94 expected shipped files and 72 registered Lua spec files. Write-only candidates were inspected as dynamic exports/widget/deferred fields, not removed. |
| Archive validation | Local cache-only ZIP uses Package.ps1's Compress-Archive operation; exactly 94 addon-only entries, each SHA256 matching source, no duplicate/extra/missing inputs. Existing dist/release archives were not overwritten. |
| Release configuration | Three embedded JavaScript checks parse; release asset acceptance/rejection probes pass. No remote workflow or upload was started. |
| Separate gear research tests | All 11 Node tests pass; research effects/caps/set models are not claims about the runtime scoring model. |
| Client/source drift | Installed executable remains 1.60.1.70862; the public Forever version.txt still reports 70862. Current What's Training Camelot directory has the same 14 file blob hashes as pinned dd425647. No source/catalog update indicated by these checks. |

All runtime files received syntax/static/reference/input checks and the registered regression suite. Focused source inspection covered initialization/profiles and saved-data boundaries, inventory snapshots/selectors, checklist input/refresh, tooltip/scoring readers, vendor/loot/container action guards, optional timers, launcher gestures, diagnostics and packaging. This is not exhaustive execution of every branch. Audit evidence is under `.cache/review-20261110`; the backpack failure and final checker output are retained there.

The support report, manual spec/stat expansion and checklist ergonomics recommended below are now implemented in the working tree, with native validation pending. Remaining priorities are:

1. Run the focused native regressions in testing.md: running build/Interface, combat and bag right-click/taint, contact persistence/scoping, meter/buff controls, gear alias examples, support copying and checklist input. Earlier map/tracker investigation stays deferred.
2. Calibrate the gear starters with native samples before expanding effects/caps/set advice. Current starters and percentages remain weighted preferences, not predicted output.
3. Consider full talent-plan sharing (point order/notes with backward-compatible import), then sourced profession planning as separate feature work.
4. Measure native CPU/memory and bag-event bursts before broader optimization; extract GUI controllers incrementally when changing those pages.

No other concrete runtime defect was established in this pass. No native compatibility, visual, performance or taint verification is claimed. Version/defaults and real SavedVariables remain unchanged; no release, deployment or junction action was performed.

Sources rechecked: [Forever UI version](https://github.com/Gethe/wow-ui-source/blob/forever/version.txt), [current training directory](https://github.com/fusionpit/WhatsTraining/tree/forever/Classes/Camelot), [pinned training directory](https://github.com/fusionpit/WhatsTraining/tree/dd4256471d65149ad6e8d00ad1f18fa7c31e7a6e/Classes/Camelot).

## Original November 9 assessment

Follow-up: the user's next requested [gear-modeling step](gear-modeling.md) adds 46 supported stat weights and 29 manual spec/role choices with preserved custom profiles. The 82-file/13-stat assessment below records the pre-step review snapshot; native calibration and effect/cap coverage remain outstanding.

November 9, 2026. Canonical source: `C:\Games\Development\GitHub Repos\WoW Forever Suite`, version 1.0.9 with pending working changes.

Suite has a useful integrated feature set, particularly training planning, editable contact records, character records and consistent settings. Its everyday QoL coverage is competitive with general utility suites. Gear advice is the largest functional gap against specialist addons. Reliability in the actual client is the largest unresolved quality question: passing substitute tests cannot establish combat input, taint safety or visual correctness.

The next investment should deepen existing features and close native regressions before adding more unrelated modules. No blanket claim that Suite is better or faster than the alternatives is supported.

## Corrections made in this review

| Area | Problem | Result |
| --- | --- | --- |
| Supply Checklist | Every item-data result, including unrelated items, immediately rescanned all carried bags. Relevant event bursts repeated that work. Opening an enabled checklist also refreshed twice. | Ignore unrelated metadata; coalesce relevant metadata/bag events into one cancellable refresh; scan once when opening. Combat, closing, disabling and an explicit refresh cancel pending work. Counts still require a complete carried-bag scan. |
| Mail Deadlines | A window left open retained its old countdown without a calculation timestamp or manual refresh action. | Add **Refresh times** and **Countdowns updated**. Refresh recomputes saved deadlines without querying a mailbox or changing the original observation/check time. No periodic timer is added. |
| Upgrade tooltip | Rounded percentages can be mistaken for predicted damage or healing improvements; item-level mode also showed a weighted-estimate footer. | Explain that percentages are weighted score gains. Item-level comparisons receive their own appropriate explanation. The requested whole/sub-one-percent formatting remains intact. |

The checklist regression was reproduced before the fix: an unrelated metadata event increased the scan count. Regression coverage now includes burst coalescing, restricted IDs, combat, hide, disable, explicit refresh and a single opening scan. Mail coverage checks time advancement, unchanged observations, no inbox query, combat and unavailable server time. Native appearance and input checks remain pending.

## Comparison with similar addons

These are feature-scope assessments against the maintainers' public descriptions, not side-by-side gameplay or performance benchmarks. General descriptions can include features unavailable on a particular flavor; a Forever download alone does not establish every feature's availability there. No third-party implementation, artwork or layout was copied.

| Area | Reference | Suite assessment | Best improvement |
| --- | --- | --- | --- |
| General QoL | [Leatrix Plus](https://www.curseforge.com/wow/addons/leatrix-plus), [Enhance QoL](https://www.curseforge.com/wow/addons/eqol) | Competitive core coverage: independent automation, minimap tools, window tools, searchable settings, profiles and chat conveniences. Feature count alone does not establish reliability or ease of use. | Keep opt-ins and restoration. Add clearer capability/paused-state diagnostics and focused native coexistence checks. |
| Gear advice | [Pawn](https://www.curseforge.com/wow/addons/pawn) | Behind in stat and spec coverage. Suite has five broad role presets and 13 editable stat keys. Automatic selection is class-based; hybrid classes default to Balanced. | Validate additional stat aliases/units, add explicit spec/role selection, then editable spec profiles. Preserve custom weights. |
| Bags and inventory | [Baganator](https://www.curseforge.com/wow/addons/baganator) | Useful saved bags/banks, cross-character search, favorites and stock tooltips. Behind the specialist's categories, advanced query syntax and broader storage-source coverage. | Improve search/filter discoverability and freshness. Add categories or new storage sources only if they serve the user's workflow; disclose snapshots. |
| Class training | [What's Training?](https://www.curseforge.com/wow/addons/whats-training) | Useful comparable class-training coverage with Suite-specific pins, wishlist costs and recorded-price mode. The specialist also advertises profession recipe planning, a real Suite gap. | Extend planning to professions as separate sourced product work; retain class/rank/prerequisite and live-price validation. |
| Mail | [Postal](https://www.curseforge.com/wow/addons/postal) | Strong personal contact editing through notes/categories, standalone access, Alts/Guild/Other and server-type scoping. Narrower mail-processing scope than Postal's selective/open-all and attachment workflows. | Prioritize contact persistence and correct recipient scope. Bulk mail actions are optional future work, not a requirement for contact-book quality. Postal feature descriptions do not prove Forever compatibility. |
| Talent planning | Suite's existing native-tree model and `TalentPlanner.lua` export | Drafts, ordered leveling plans, undo/redo and notes are useful integrated tools. Current WFS1 sharing exports ranks only, so it loses the custom point order and notes. | Versioned full-plan export/import with bounded validation and backward-compatible WFS1 support. |
| Meters and combat reminders | Matching build's native damage/aura APIs | Suite offers original presentation, shared meter locking, details and placement. No evidence supports claiming analytical parity with specialist meters across restricted combat data. | Improve visible unavailable states and native tests; use only information the client permits. |

Pawn advertises customizable weights and spec-aware advice; that supports the coverage comparison, not a claim that any default weight set is optimal. Baganator advertises categories, advanced searches and additional inventory sources; its performance claims have not been reproduced for Suite. Leatrix and Enhance QoL advertise modular behavior, which is a relevant design comparison rather than proof of their correctness on this installation.

## Recommended order of work

### High priority: native reliability and gear relevance

1. **Complete a short native regression pass.** Record the running build/Interface, enabled overlapping addons and the first actual error. Exercise shortened keybinds through combat/forms/action updates; native bag right-click after ordinary Suite interactions; contact persistence and server-type groups; buff and meter controls through combat; and the new mount/draft flows. The crate worked after reload, but that does not establish its originating taint. Earlier map/tracker taint remains open and deferred as previously requested; this review does not restart that investigation or claim it fixed.
2. **Improve the gear model before adding confidence to the wording.** Missing hit/crit/haste/expertise, defenses and school-specific spell stats can materially change recommendations. The fixed 50% off-hand factor and absent proc/set/cap models remain approximations. Start with public, matching-client stat aliases and units; add an explicit spec selector; preserve current custom profiles exactly; add actual equipped-set breakpoints only after a validated effect model. The existing [offline baseline research](gear-upgrade-baseline.md) is a starting point, not production proof or an instruction to adopt third-party numeric weights unchanged.

Acceptance for gear work should include all classes, manually selected hybrid roles, paired accessories, one-/two-hand transitions, random suffix links, asynchronous/unreadable data, old custom-profile migration and agreement between icon and tooltip explanations. A +2% score gain must never imply +2% DPS.

### Medium priority: make existing features easier to trust

3. **Provide a copyable support report and capability states.** Current `/wfs status` prints build and top-level namespace presence. It does not explain which configured feature lacks a required function or is deferred in combat. Report version/build/locale, enabled feature keys, comparison mode and unavailable/paused reasons using public configuration only. Exclude contact names/notes, chat contents and inventory contents. Avoid collecting combat secrets or dumping SavedVariables.
4. **Finish Supply Checklist input ergonomics.** Item drag-and-drop and guarded row item tooltips would remove ID lookup and ambiguous item-name steps. Keep pasted IDs/links and explicit Save; an item drop should fill the editor without buying, using or deleting anything. Counts remain carried-only unless a separately disclosed bank scope is added.
5. **Share complete talent plans.** A new versioned code should include point order and optional notes, validate limits/tree revision/class, preserve legacy rank codes and preview before replacing anything. Importing a plan must never spend native talent points.
6. **Plan professions.** Add a sourced recipe/training cost view after validating source license, current facts and native APIs. Do not hide missing prices or silently treat old observations as current. Automatic purchases/crafting are separate decisions.

### Lower priority: maintenance and measured performance

7. **Keep settings discoverable as the Suite grows.** Search and setup already exist. Improve synonyms, direct links and useful paused/unavailable explanations before adding another navigation layer. Verify small screens, long names, nested scrolling, keyboard focus and Escape in the client.
8. **Split GUI responsibilities when touching those areas.** `GUI.lua` is about 180 KB, while profiles/buffs/gear already have separate settings files. Extract cohesive page/controller code incrementally with existing interaction coverage, rather than rewriting the UI during bug fixes.
9. **Measure native cost before optimizing broadly.** Optional features are off, but all TOC code/data still loads. Measure idle, bag-event bursts, settings open/closed and live meters with a recorded configuration. Event/timer design is encouraging; it is not an FPS, CPU or memory benchmark. Use results to choose lazy construction, cache work or data splitting.

## Coverage and evidence

All 82 runtime Lua files were included in Lua 5.1 parsing, scope/reference and packaging-input scans. API checks used the pinned build-70862 Blizzard-source export. Source inspection focused on lifecycle/cleanup, saved-data boundaries, protected work, comparison semantics and the user flows below; this is not a claim that every runtime path or visual state has been exercised.

| Runtime files | Review outcome and remaining work |
| --- | --- |
| Core.lua, Profiles.lua, Bindings.lua, Shortcuts.lua | Initialization/deferred work, scoped settings and command ownership checked. Contact/inventory/history data remain separate from ordinary settings profiles. Improve diagnostic specificity; native profile/save/reload checks remain necessary. |
| Theme.lua, GUI.lua, Setup.lua, SettingsCatalog.lua, ProfileSettings.lua, BuffSettings.lua, GearSettings.lua, WindowPlacement.lua | Search/setup/routing, owned controls and original appearance reviewed. Existing keyboard, wheel and scope tests retained. Long-term GUI size is a maintenance concern; visual/input correctness needs native checks. |
| Minimap.lua, MinimapButton.lua, MinimapDrawer.lua, WorldMap.lua, MapRevealData.lua, ZoneReputation.lua | Optional layouts, native ownership and gesture/timer paths checked against existing coverage. Preserve original parents/scripts and native coordinates. Round/square, third-party buttons and localized zone behavior remain native checks; map taint stays deferred. |
| Windows.lua, BagSort.lua, CombinedBags.lua, AutoOpen.lua, BagSpace.lua | Native header routing, cancellation, bag visit/context guards and destructive-action boundaries reviewed. Keep Ctrl-wheel native resizing and explicit deletion confirmation. Crate taint origin remains unresolved. |
| ActionBars.lua, ActionBarSkin.lua, HUDSkin.lua, Keybinds.lua, UnitFrames.lua, TargetThreat.lua, CombatIndicator.lua, Castbars.lua, ProcAlerts.lua, BuffBorders.lua | Presentation restoration, coalesced refreshes, active-only gestures and public/restricted data handling reviewed with existing specs. Short-label, reactive-proc and native combat rendering need focused checks. |
| Vendor.lua, MerchantKnown.lua, Loot.lua, Quests.lua, QuestItem.lua, QuestTrackerSkin.lua, QuestTrackerState.lua, ProfessionHelper.lua, Audio.lua | Context revalidation, opt-ins, native action/confirmation boundaries and disable paths checked. Preserve Shift conversation bypass and independent automation. Native purchases/use/taint and audio-device changes remain environment-dependent. |
| TrainingCatalogData.lua, TrainingCatalog.lua, TrainingWeapons.lua, Training.lua | Current upstream class-directory blob hashes match the pinned revision. Pins/recorded prices/class filters remain covered. No class data refresh required from this comparison; profession planning is separate. |
| TalentPlanner.lua, TalentPlannerRules.lua, TalentPlannerOrder.lua, TalentPlannerStarterData.lua, TalentPlannerStarters.lua, TalentPlannerUI.lua | Bounded drafts/import validation, manual learning and ordered plan behavior retained. WFS1 does not preserve order/notes; full-plan sharing is recommended. |
| Scoring.lua, Items.lua, Character.lua, EquipmentSets.lua, Tooltips.lua | Rounded weighted-score percentages retained and explanation corrected. Exact breakdowns, legal hand comparisons and item-level mode remain intact. Spec/stat/effect coverage is the largest functional shortfall. |
| Inventory.lua, CharacterDashboard.lua, InventorySearch.lua, InventoryBrowser.lua, OfflineBank.lua, InventorySelectors.lua | Complete-scan preservation, saved/live distinctions, source identity and visible refresh paths reviewed. Specialist categories/query/storage breadth are missing; never imply a stale bank view is live. |
| Mail.lua, ReleaseTools.lua | Preserve contact recovery/scoping and complete carried counts. Checklist event issue fixed; deadline recalculation/freshness added. Native persistence and realm/server-type behavior remain priority checks. |
| Chat.lua, ChatCopy.lua, ChatHistory.lua | Bounded character history, readable copying and reversible styling retained. Native clipboard/focus and link rendering still need client checks. |
| MacroItems.lua, Macros.lua | Explicit ownership-safe creation, native editor pause, item supply maintenance, draft discard and mount/dismount flow remain covered. Native selected-icon/action/taint checks are still pending. |
| Camping.lua, CampingItems.lua | Secure native item actions, proximity scope and combat/disable cleanup retained. Native proximity, benefit/item behavior and English discovery are explicit limits. |
| Leveling.lua, Journey.lua | Character-owned history and partial observations retained; confirmed sales/repairs stay distinguished from requests. Native event ordering, reload checkpoints and long sessions need observation. |
| BuffCatalog.lua, MissingBuffs.lua, BuffReminders.lua, CombatBuffs.lua | Optional class/group/expiry scope and native restricted-aura composition retained. Pending user-requested catalog removal is preserved. Native group/privacy/anchor transitions remain unverified. |
| DamageMeters.lua, MeterParity.lua, DamageMeterMenus.lua, DamageMeterDetails.lua | Secret values remain on supported widget paths; readable-only analysis and shared lock/corners retained. Native live history/death/detail/control behavior must determine practical parity. |

Installed executable observation remains **1.60.1.70862**, matching the pinned source revision `9dc84f0d3bbae1768ac3405b3716000bd93eda06`. This observation does not substitute for an actual running build/Interface report.

The API scan indexes 5,144 documented functions and resolves 157 distinct `C_*` references. It reports no missing required arguments, unknown literal registered events or duplicate literal table keys. The two undocumented legacy pet-journal members remain capability-checked fallbacks with native references documented in the November 7 review. Indirect/dynamic calls and native permissions are outside this scan's guarantees. Detailed output: `.cache/review-20261109/api-audit.json`.

The cleanup/inventory scan finds 82 Lua files, 91 expected package inputs and 69 registered Lua spec files, with no unused-local, unreferenced-method or unreachable-statement candidates. Write-only candidates include dynamic deferred-work keys, namespace exports, native widget fields and input-region handles; they are not deletion instructions. Cache/reference material remains outside shipped inputs.

Live GitHub comparison of [the upstream class directory](https://github.com/fusionpit/WhatsTraining/tree/forever/Classes/Camelot) with [Suite's pinned revision](https://github.com/fusionpit/WhatsTraining/tree/dd4256471d65149ad6e8d00ad1f18fa7c31e7a6e/Classes/Camelot) found identical file blob hashes. This checks upstream drift, not current server trainer prices or profession-catalog completeness.

## Validation and delivery

Final checker results are recorded in `docs/testing.md`. The runtime changes are limited to checklist refresh scheduling, deadline freshness/recalculation controls and tooltip explanation. Existing working changes and offline scoring research remain intact. Core and both TOCs retain 1.0.9. No release, deployment, junction or real SavedVariables change is part of this review.
