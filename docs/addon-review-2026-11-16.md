# Forever Suite review and improvement priorities

November 16, 2026. Reviewed the canonical C: working tree at version 1.0.20, including the pending character-owned window storage and nearby profession trainer changes.

The largest opportunity is to make the Suite's existing tools work together: turn profession shortages into a checklist, show where supplies are recorded, and prepare a shopping list for what remains. Follow that with shared item protections, clearer gear comparisons, and better coexistence with other addons. Native reliability verification remains the first priority before expanding bag and combat interactions.

This is a whole-addon product and architecture review with focused source inspection and automated checks across all runtime Lua files. It is not a line-by-line security audit or an in-game compatibility certification. Recommendations below are proposals, not newly implemented features. Existing uncommitted work was preserved; no runtime code, game files, junctions, SavedVariables, version or release configuration was changed for this review.

## Current strengths and gaps

The addon has 94 runtime Lua files and approximately 37,725 lines, including generated/reference data. All are included in the current syntax checks. Existing functionality already addresses most basic requests associated with Leatrix Plus, Bagnon, Pawn, Prat and What's Training: automation switches, window movement, minimap cleanup, inventory records, gear hints, chat copying/history, training information and original styling. A second implementation of those same basics would add little value.

| Area | Existing foundation | Best next improvement |
| --- | --- | --- |
| Setup and settings | Optional modules, setup drafts, searchable settings, shared/personal profiles, support reports | Explain overlapping addon features and let users inspect all enabled features in one place. |
| Bags and bank | Native bag sorting, bag order, saved bank views, inventory search, reagent deposits, low-space suggestions | Shared keep rules and richer saved searches, while retaining native bag interactions. |
| Professions | Remaining material estimates, intermediate reuse, stock allocation, recipe source hints and trainer destinations | Turn the material plan into an actionable supply workflow; add a bounded missing-recipe browser later. |
| Characters | Recorded level, money, professions, inventory dates and mail deadlines | A concise attention list with optional saved lockouts and profession cooldown observations. |
| Gear | Character-owned weights, 29 spec starters, stat extraction, ring/hand comparisons and item-level overlays | Explain why a comparison wins or is unavailable; validate a richer model separately. |
| Vendors and mail | Repairs, junk sales, known-item marks, contacts/groups and recipient persistence | Keep rules, merchant restocking and carefully scoped collection of inbox attachments. |
| Quests and leveling | Safe quest handling, tracker styling/state, nearby quest-item action, journal and leveling tracker | Dungeon preparation and better journal filtering; keep location guidance with Questie. |
| Combat | Native-data meters, threat display, range colors, proc popups, buff reminders, castbar sizing | Native reliability and clearer capability feedback before more combat features. |
| Maps and interface | Square minimap, stats/coordinates, drawer, map reveal, native window adapters and skins | Saved destinations and consistent waypoint handoff, with narrow ownership. |
| Chat, audio and utility tools | Chat styling/history/copy, audio device sync, macros, talent drafts and camping | Optional chat filtering and easier reuse/export of existing user-created settings. |

Several connections already exist and should be reused. In particular, `ProfessionLeveling:Stock` already uses `Inventory:Summary`, which includes recorded alt bags, personal banks and the shared bank. The missing work is a clearer distinction between carried and recorded stock, explicit checklist transfer and a purchasing handoff. It is not a missing account-wide stock counter. The Supply Checklist currently tracks up to 32 manually entered targets and counts carried bags independently.

## Popular addons and what their demand means

The following are selected reference projects, not an exhaustive ranking. Approximate lifetime project downloads were read from CurseForge on November 16. These totals combine supported game versions and repeated updates; they are neither unique users nor Forever-only downloads. The [directory sorted by total downloads](https://www.curseforge.com/wow/search?class=addons&page=1&pageSize=20&sortBy=total+downloads) was also checked. Author-listed Forever support does not prove compatibility with this user's running client.

| Reference | Approximate downloads | Implication for Forever Suite |
| --- | ---: | --- |
| [DBM](https://www.curseforge.com/wow/addons/deadly-boss-mods) | 643M | Group preparation matters, but building a boss-mod engine is a poor fit. |
| [Details](https://www.curseforge.com/wow/addons/details) | 377M | Make existing meters understandable and dependable; preserve native data boundaries. |
| [Questie](https://www.curseforge.com/wow/addons/questie) | 224M | Preserve coexistence and the explicit decision to remove Suite quest-location guidance. |
| [Auctionator](https://www.curseforge.com/wow/addons/auctionator) | 213M | Export material needs or offer an optional adapter instead of building an auction engine. |
| [Bagnon](https://www.curseforge.com/wow/addons/bagnon) | 172M | Inventory access across characters is valuable; the Suite already has that foundation. |
| [Pawn](https://www.curseforge.com/wow/addons/pawn) | 132M | Improve the explanation and portability of gear preferences. |
| [TomTom](https://www.curseforge.com/wow/addons/tomtom) | 93M | Reuse navigation providers for explicit destinations. |
| [Leatrix Plus](https://www.curseforge.com/wow/addons/leatrix-plus) | 78M | Modular, discoverable everyday conveniences fit well; many basics already exist here. |
| [Baganator](https://www.curseforge.com/wow/addons/baganator) | 44M | Saved filters and item organization are worth adopting as concepts. |
| [Postal](https://www.curseforge.com/wow/addons/postal) | 36M | Selective mail collection can save repetitive work. Its page does not currently list Forever as a flavor. |
| [Altoholic](https://www.curseforge.com/wow/addons/altoholic) | 27M | Turn recorded alt information into decisions and reminders. |
| [Nova Instance Tracker](https://www.curseforge.com/wow/addons/nova-instance-tracker) | 19M | Instance observations and lockout visibility could complement the journal. |
| [Attune](https://www.curseforge.com/wow/addons/attune) | 14M | Dungeon requirements are useful, but maintaining an accurate content database is substantial work. |

Newer Forever-specific projects reveal useful ideas even when their lifetime downloads are much smaller. [ForeverRecipes](https://www.curseforge.com/wow/addons/forever-recipes) emphasizes missing recipes, acquisition sources and crafting estimates. [ItemTree](https://www.curseforge.com/wow/addons/itemtree) emphasizes what an item is used for and how materials connect. These support a focused profession workflow here, without requiring a complete crafting economy or item-source database.

### Community requests

Two player discussions repeatedly mention training information, dungeon quests/prerequisites, useful profession information, and readable maps. Players also describe frustration with overlapping QoL suites. Individual comments ask for class identification without replacing reaction colors and better target information. These are qualitative signals from self-selected discussions, not a representative survey or evidence that any particular API is usable. See the [Forever QoL discussion](https://www.reddit.com/r/wowaddons/comments/1xt6ye4/which_quality_of_life_addon_are_yall_using_in_wow/) and [addon experiences discussion](https://www.reddit.com/r/classicwow/comments/1xteqvx/megathread_time_has_passed_what_are_the_addons/).

The [Blizzard forum discussion](https://us.forums.blizzard.com/en/wow/t/wow-forever-addons/2362999) includes author descriptions of dungeon preparation, item protection and consumable tools. Treat those as author claims and examples of requested workflows, not independently verified feature quality. A [specific reagent-navigation request](https://www.reddit.com/r/wowforever/comments/1xrqzso/anyone_know_an_addon_that_lets_me_left_click_on/) also illustrates the value of jumping from a required intermediate material to its recipe.

## Work to prioritize before expansion

### Resolve native verification gaps

The documented `UseContainerItem` bag-use investigation remains open. Earlier map/tracker taint reports were explicitly deferred; this review records them and does not restart those investigations. Passing substitutes cannot identify the native originating taint or prove the latest fixes resolved it.

Run the existing focused native checks with the actual running build/Interface recorded: ordinary bag right-click after Suite interactions, combat entry/exit with prepared quest items and buffs, action-bar/form changes, profile changes, two-character window persistence and logout money persistence. Check with overlapping addons disabled, then the normal addon set. Retain the first error and the relevant preceding interactions. Do not expand transfer or secure-action automation on an unresolved interaction path.

### Correct stale user documentation

`README.md` still tells users to expect footer version 1.0.17, although Core and both TOCs declare 1.0.20. It also describes closed-guide recipe following, superseded by the current visible-guide-only policy, and broadly says profiles include supported window layouts, superseded by the pending character-owned storage change. These are concrete documentation inconsistencies. Update current instructions together when the pending changes are finalized; historical release records should retain their original meaning.

### Make validation results easier to use

The existing test suite is extensive, but `testing.md` is approximately 932 KB and `forever-development.md` approximately 953 KB. Keep the historical record while adding a short current-build verification matrix: feature, source version, actual client build, result, overlapping addons and remaining issue. Link to detailed procedures. This should distinguish implemented, substitute-tested and native-confirmed behavior without putting research details into normal gameplay screens.

## Highest benefit improvements

Priority reflects benefit to this personal modular suite, reuse of existing systems, maintenance cost and API risk. Effort is relative: Small is a narrow change, Medium spans several existing modules, Large needs a new data model, UI or substantial maintained data. These are not calendar estimates. Every new feature remains separately optional and off by default.

| Order | Improvement | Benefit | Effort | Main dependency |
| --- | --- | --- | --- | --- |
| 1 | Profession materials to checklist and shopping export | Very high | Medium | Existing material plan and stock records |
| 2 | Shared keep rules and reagent reserves | Very high | Medium to Large | Define action-specific protection and native sorting limits |
| 3 | Explain gear comparisons | High | Medium | Existing scoring and item data |
| 4 | Addon overlap guidance and enabled-feature view | High | Medium | Settings catalog, setup and diagnostics |
| 5 | Structured inventory filters and saved categories | High | Medium | Existing search/index and saved views |
| 6 | Merchant restocking from supply targets | High | Medium | Checklist integration and merchant API validation |
| 7 | Character attention list | High | Medium | Existing timestamps and mail records |
| 8 | Missing-recipe and intermediate navigation | High | Large | Validated Forever recipe/source coverage |
| 9 | Selected mail attachment collection | High | Medium to Large | Exact-client mail permissions and native bag validation |
| 10 | Dungeon preparation notebook | High for group play | Large | Accurate Forever content and quest completion semantics |

### 1 Profession materials to checklist and shopping export

Add **Track this section** and **Track remaining materials** to the profession guide. Preview the proposed targets, merge or replace explicitly, and offer plain-text shopping export. Label carried stock separately from recorded bank/alt stock, with owner and age available from the material row. An optional Auctionator adapter can follow after verifying its public interface and supported import format; plain text must work without another addon.

Reuse `RemainingShopping`, `MaterialPlan`, `Inventory:Summary` and `SupplyChecklist`. Preserve intermediate reuse and the existing once-only allocation of stock. Store required totals and derive shortages; do not turn a shortage into a target and then subtract stock again. Handle the checklist's 32-item limit explicitly. Do not overwrite a manual target silently or promise that recorded possessions are accessible now.

Acceptance example: a section needs 100 cloth, with 20 carried and 30 recorded on an alt. Show 80 to bring into carried stock and 50 additional to obtain if the recorded alt stock is still available. Shared bank contents count once. Unknown or stale records remain visible as such. Exported quantities must identify the chosen stock policy.

### 2 Shared keep rules and reagent reserves

Provide one item-rule editor with separate **Never sell**, **Never suggest deleting**, **Keep carried quantity** and, where support permits, **Ignore during cleanup** behaviors. Existing `BagSpace` blacklist protection is not a unified policy: vendor sales respect native bag exclusions, and reagent deposit does not currently offer per-item reserves. Reuse protections across Suite-owned actions and show why an item was skipped.

Do not claim that a Suite favorite prevents arbitrary native sorting. Use supported native exclusion mechanisms where possible; otherwise disable or explain the unsupported sorting interaction. A bulk native junk-sale API may be unable to respect item-level keep rules; choose a compliant path or block that mode for affected rules. Scope preferences intentionally so one character's reagent reserve does not unexpectedly govern every alt.

Acceptance: a protected gray item survives both Suite sale modes; a protected cheap item is not offered by the low-space alert; depositing 60 reagents with a reserve of 20 leaves 20 carried or explicitly reports that partial-stack handling is unsupported. Revalidate after bag movement and stop on combat/context changes.

### 3 Explain gear comparisons

Add a compact **Why this is an upgrade** view: compared slot/loadout, stat differences, active weights, weighted contributions and omitted effects. Explain unavailable comparisons in ordinary terms, such as loading item data, unsupported weapon assumptions or an unreadable stat. Preserve existing ring and hand-set logic.

Runtime scoring is currently an additive preference model; the separate gear-baseline test tool includes richer scenarios that are not all runtime features. Do not present passing baseline tests as implemented caps, set bonuses or proc modeling. Add optional weight import/export only after a strict bounded format and unit mapping are defined. Pawn strings are a candidate adapter, not an automatically interchangeable model.

Acceptance: displayed contributions reconcile with the actual runtime delta; the comparison identifies the replaced ring or full hand configuration; unsupported proc/set effects never become an unconditional recommendation. Language remains “improvement under these weights,” with no claim of simulated DPS or definitive best in slot.

### 4 Addon overlap guidance and enabled-feature view

Extend Setup with optional notices when known addon families also offer bag movement, minimap drawers, vendor automation, chat history, tracker skins or profession companions. Add **Enabled features** with direct settings links and the shared/personal scope. Current setup checks Suite settings and capabilities; it does not provide a comprehensive overlap review.

Presence alone is only a possible overlap, not proof that the other addon's corresponding feature is enabled. Let the user choose ownership. Never disable another addon, rewrite its settings or infer a taint cause from its name. Keep the existing setup review and off defaults.

Acceptance: discovering an installed addon changes no saved choices; choosing Suite ownership affects only Suite settings; support reports retain their current privacy boundaries.

### 5 Structured inventory filters and saved categories

Add visible filters for quality, equipment/reagents/consumables, recorded ownership and record age, followed by a small bounded query syntax if useful. Extend existing saved views rather than adding a second inventory browser. Current search already supports names, types/subtypes, exact IDs, owner and location; those are not missing features.

Show categories as result views first. A replacement live categorized bag UI has much greater input, compatibility and taint risk and should not be the initial implementation.

Acceptance: an “uncommon equipment in my bank” saved view restores exactly, missing item metadata is not mistaken for no matches, and shared quantities remain deduplicated.

### 6 Merchant restocking from supply targets

Show which checklist deficits the current merchant sells, with price and a reviewed **Buy selected** action. Start with carried supplies such as reagents, food and drink; respect stack size, purchase quantity, stock limits, free space and a user spending limit. Unknown cost or extended-currency requirements stay manual until modeled.

Reuse the checklist rather than creating another target database. Purchasing always begins with a user action and never sends mail, spends currency or buys training just because the user opens a window.

Acceptance: buying toward a target stops at the target, merchant closure, insufficient funds, full bags or combat, and success follows observed inventory/purchase feedback rather than assuming the request succeeded.

Implementation update, November 16: recommendation 6 is implemented for carried checklist targets as optional Merchant restocking (off by default), with reviewed selections, whole-gold limit, guarded sequential purchases and observed feedback. Profession plans remain in the all-character Shopping List. Offline checks pass; native purchase/layout/taint testing is pending.

### 7 Character attention list

User decision, November 16: skip this recommendation for now.

Add a compact view of recorded mail deadlines, stale/unvisited banks, supply targets and useful training pins. Offer separate optional saved instance-lockout and profession-cooldown recording later. The current dashboard already has profession levels, money and dates, so those should remain its foundation.

Store observations with source times. Do not simulate offline progress or authoritative cooldown readiness until exact-client behavior is validated. Mail expiration estimates mean “check this mailbox,” not proof that mail was lost. Rested XP is a possible later addition with explicit prediction limits.

Acceptance: every alert identifies its character and observation age; disabling recording leaves historical records readable; unknown state is never a red failure or assumed zero.

### 8 Missing recipes and intermediate navigation

Start with missing recipes used by the selected leveling route, their skill requirements and documented acquisition methods. Clicking a craftable intermediate can open its learned recipe, with a Back action to return. Keep vendor/manual/quest/specialist sources distinct and preserve manual crafting. Expand to a collection browser only when source coverage and update ownership are sustainable.

Reuse `ProfessionRecipeSources`, guide data and the existing native recipe selection guards. Recent trainer selection and output icons are already pending work, not new recommendations here. Avoid wholesale copying of another addon's recipe database; record source provenance and license obligations for any imported data.

Acceptance: “unknown source” is distinct from “trainer”; a nearby trainer is offered only for the correct teaching tier; navigating an intermediate does not craft, buy or undo an active manual batch.

Implementation update, November 16: recommendation 8 is implemented within the profession Leveling guide: Route recipes review, explicit missing/unknown states and sources/requirements, selected-route intermediate navigation and guarded native Back history. Offline checks pass; in-game layout, requirement fidelity and batch/taint tests remain pending.

### 9 Selected mail attachment collection

Add selected-message or selected-sender collection and a clear stop control. Exclude COD and leave sending, returning and deletion manual in the first version. Respect free bag slots, partial inbox loading, server throttles and shifting message indices. Validate supported actions against matching client source and then in game; Postal's popularity does not establish its approach is permitted here.

Acceptance: an inbox update cannot cause the next index to refer to the wrong message; a full bag stops promptly; mailbox closure cancels all work; a failed request remains retryable. Gate this behind the unresolved native bag interaction checks.

### 10 Dungeon preparation notebook

Start with user-pinned dungeon plans: required supplies, saved notes and explicitly recorded quest/prerequisite status. Link to an installed specialist where a supported integration exists. A curated Forever dungeon quest/key list can follow as a separate maintained dataset.

Keep this distinct from restoring the removed Suite quest map, mob nameplates, broad loot catalog or route engine. Avoid promising current completion when only a saved observation exists. If the value depends on recreating Attune or a full dungeon journal, prefer a specialist addon and a small Suite handoff.

Acceptance: preparation works without a live combat feed; unknown prerequisite data is disclosed; content is checked against Forever rather than assuming Era quest IDs and requirements.

## Additional worthwhile improvements

| Order | Proposal | Scope and benefit | Effort |
| --- | --- | --- | --- |
| 11 | Saved destinations | Favorites for explicit trainer, vendor and personal destinations; reuse the current native waypoint path and optional navigation providers. No new quest database or travel-time claim. | Medium |
| 12 | Pinned supply display | A small click-through checklist for carried consumables/reagents with one optional reminder on entering a chosen context. It should reuse targets and buff systems, not duplicate aura detection. | Medium |
| 13 | Optional chat noise filters | Hide repeated text or selected terms locally, with a temporary bypass and visible filter state. Keep URL copying and history semantics intact; never auto-report or message players. | Medium |
| 14 | Readability controls | A shared text-size preference for Suite windows, stronger focus/selection indicators and small-screen checks. Avoid a blanket scale change to protected native frames. | Medium |
| 15 | Manual profile export and import | Share bounded, reviewed Suite configuration while excluding inventory, contacts, chat, macro ownership and character positions. Talent-plan sharing already exists; settings sharing is a separate task. | Medium to Large |
| 16 | Class icons and target details | A passive optional class marker that preserves native reaction colors, plus readable public target metadata. Avoid nameplate replacement and secret-derived classification. | Small to Medium |
| 17 | Instance journal filtering | Group existing journey observations into explicitly detected dungeon visits and filter XP/gold/loot/deaths by visit. Report net money separately from loot value; do not reconstruct unavailable combat events. | Medium |
| 18 | Scoped cosmetic fading | Fade only Suite-owned passive displays outside chosen contexts, with predictable hover/combat behavior. Native protected HUD fading requires separate validation and should not be part of the first version. | Medium |

## Engineering improvements that support the roadmap

1. **Measure before changing refresh behavior.** `Suite.Set` calls `Suite.Apply`, which visits every registered module. Consider declaring each module's relevant settings and applying only affected modules. First measure settings changes, bag updates and guide rendering; this is an optimization candidate, not a demonstrated frame-rate defect. Preserve dependency refreshes and deferred combat cleanup.
2. **Keep shared inventory and observation semantics consistent.** Inventory search, material planning and supply tracking have different purposes. Share bounded count/freshness helpers where appropriate, while retaining carried versus recorded scope and incomplete-data handling.
3. **Split large UI files along existing module boundaries.** `GUI.lua` is about 2,785 lines and `Mail.lua` about 1,732. Move page construction and contact editor surfaces incrementally into focused components when touching those areas. File length alone does not justify an unrelated rewrite.
4. **Separate maintained facts from presentation.** Trainer, recipe, map and training data need provenance, build dates and focused update checks. Keep cache/reference sources out of packages, and do not infer live availability from a community signature export.
5. **Offer optional performance diagnostics for developers.** Bounded counters for refresh jobs, cancelled timers and index rebuilds would make profiling actionable. Keep inventory, chat and character names out of support exports; do not run a permanent idle profiler.
6. **Keep the current modular behavior.** Static review finds `OnUpdate` assignments only in GUI scrollbar dragging, meter dragging/resizing and minimap launcher/drawer gestures. These are appropriate gesture paths; there is no basis here for a sweeping polling rewrite.

## Features to leave with specialist addons

- A boss-mod engine or general WeakAuras replacement: high maintenance and restricted-combat complexity.
- A full auction-house, crafting-profit or market-history engine: use an optional shopping/value provider, with price age and missing prices disclosed.
- Questie-style quest-location guidance and quest-mob nameplate marks: intentionally removed from Suite in 0.2.97.
- A complete GatherMate-style resource database or minimap node-identification workaround: large data burden and fragile interaction assumptions.
- A complete AtlasLoot/Attune/ItemTree database: consider handoffs and a narrow preparation view before duplicating maintained content.
- A full unit-frame, action-bar or live bag replacement: the current goal is selected optional QoL and original Suite tools around native systems.
- Voice packs, automatic combat decisions, auto-roll/equip recommendations or automatic player messaging: poor fit for this roadmap.

Use popular addons as behavior references only. Preserve Forever Suite's original slate-and-teal GUI. Do not copy Enhance QoL or other restricted projects' implementation, artwork, layout or visual identity.

## Recommended delivery sequence

**First pass:** focused native verification, current documentation corrections, overlap guidance and clearer gear explanations. These improve confidence in the existing Suite without broadening its protected-action surface.

**First feature package:** profession-to-checklist transfer, carried versus recorded stock, plain-text shopping export and richer inventory filters. This offers the strongest distinctive workflow using data the Suite already owns.

**Second feature package:** shared item protections, reagent reserves and reviewed merchant restocking. Add transfer/purchase behavior only after the relevant native interaction checks pass.

**Later:** character attention list, missing-recipe navigation and selected mail collection. Prototype dungeon preparation only after agreeing on a sustainable Forever content scope. Pick one package at a time; the ranking is a recommendation, not authorization to implement all of it.

## Coverage and validation

The inventory below accounts for all 94 runtime Lua files. All receive Lua 5.1 syntax and TOC/package checks; focused manual review covered defaults and lifecycle, setup/profile scope, inventory and material flow, item actions, scoring and documentation mismatches. Other groups were assessed through their current interfaces, registered behavior coverage and previous review records. This distinction avoids implying equal line-by-line inspection of every file.

| Group | Runtime files |
| --- | --- |
| Core and settings | Core, VersionCheck, Shortcuts, WindowPlacement, Theme, Menus, Profiles, Bindings, Diagnostics, Setup, SettingsCatalog, GUI, ProfileSettings |
| Maps and windows | Minimap, MinimapButton, MinimapDrawer, MapRevealData, WorldMap, Windows |
| Bags and inventory | BagSort, BankDeposit, CombinedBags, AutoOpen, BagSpace, Inventory, CharacterDashboard, BagMoney, InventorySearch, InventoryBrowser, OfflineBank, InventorySelectors |
| Action and unit presentation | ActionBars, ActionBarSkin, HUDSkin, BuffBorders, Keybinds, UnitFrames, TargetThreat, CombatIndicator, ProcAlerts, Castbars |
| Vendors and quest tools | Vendor, MerchantKnown, Quests, QuestItem, QuestTrackerSkin, QuestTrackerState, Loot, ZoneReputation |
| Professions and training | ProfessionHelper, ProfessionGuideData, ProfessionRecipeSources, ProfessionLeveling, TrainingCatalogData, TrainingCatalog, TrainingWeapons, Training, ReleaseTools |
| Talent plans | TalentPlanner, TalentPlannerRules, TalentPlannerOrder, TalentPlannerSharing, TalentPlannerStarterData, TalentPlannerStarters, TalentPlannerUI |
| Mail and chat | Mail, ChatCopy, Chat, ChatHistory, Audio |
| Gear and tooltips | Scoring, GearStats, GearSpecs, Items, Character, EquipmentSets, Tooltips, GearSettings |
| Macros and camping | MacroFoodData, MacroItems, Macros, CampingItems, Camping |
| Leveling and journal | Journey, Leveling |
| Buffs and meters | BuffCatalog, MissingBuffs, BuffReminders, CombatBuffs, BuffSettings, DamageMeters, MeterParity, DamageMeterMenus, DamageMeterDetails |

Both TOCs, XML inputs, media/package declarations, check scripts and existing research/review documents were included in the scope assessment. No third-party implementation was imported.

Current working-tree validation:

- `node scripts/check-addon.cjs`: 94 Lua files parse as Lua 5.1; 50,828 behavior assertions pass; 2,416 profession skill states and 1,240,360 material invariants pass; TOC checks pass.
- `node --test tests/gear_baseline.test.cjs`: 11 tests pass. These test the separate baseline model; they do not establish full runtime feature parity.
- `git diff --check`: passes; Git reports existing LF-to-CRLF conversion notices.
- No new running-client build, rendering, input, actual purchase/transfer, combat or taint result was obtained. The last documented installed executable observation is 1.60.1.70862; that is not a fresh observation of the running game.
