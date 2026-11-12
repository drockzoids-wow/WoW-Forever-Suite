# Forever Suite feature plan

## Final publication review — November 12, 2026

Published v1.0.14 from 718884ee166208d1c76c69b24c9332a68e681e95: main and release CI pass, CurseForge accepts the upload, and GitHub assets are verified. [Receipts](release-1.0.14.md#publication-verified). Native smoke tests remain pending.

The user authorizes a final full review and release, superseding the earlier holds. The complete current tree passes 90 Lua 5.1 files, matching Core/TOCs at 1.0.14, 41,967 substitute behavior assertions, all 11 gear-baseline tests and git diff --check. Repeated pinned-70862 AST/API/global-write scans and focused review of all pending runtime changes identify no new concrete release blocker. This includes the optional persistent talent-build comparison and its character-owned reference, linked castbar sizes with immediate Manual state after direct edits, settings simplification, Contacts/groups/multiline notes, profession learning-source hints, combat reminder identity handling and native tooltip difficulty colors. Native permissions, layout, input and combat/taint smoke tests remain pending; the existing bag-use taint investigation is not claimed fixed. No game deployment, junction or real SavedVariables edits.

The source-only 99-file archive is verified by SHA256. Publication receipts are recorded in [release-1.0.14.md](release-1.0.14.md). Earlier held-release entries below describe historical preparation.

## Persistent full talent-build comparison — November 12, 2026

Add Tools → Talent Builds → Always show full build information, default off and requiring the planner. Remember the chosen leveling or personal build per character; show its passive comparison markers whenever native Talents opens, even with Builds/Levels closed. Leveling references use the full level-60 plan. Preserve deliberate level browsing, draft editing and active learning-guide displays. Do not spend points, auto-open Builds or change saved drafts. Reject unavailable/outdated remembered builds. Regression passes; native smoke pending. User holds the prepared release before push for this addition.

## Final review and authorized 1.0.14 release — November 12, 2026

User requests another full review and authorizes publication if checks pass, superseding the earlier release hold. Repeated whole-tree Lua 5.1/TOC/behavior checks, pinned-70862 AST/API/global-write scans, all 11 gear-baseline tests and review of all pending runtime changes identify no new concrete release blocker. The 41,843 substitute assertions pass. Include the linked castbar dropdown and immediate Manual state after slider/typed edits, simplified settings, scoped Contacts/groups/multiline notes, recipe learning-source hints, combat reminder identity handling and native tooltip difficulty colors. Core and identical TOCs advance to 1.0.14. Only addon source ships; package/CI/upload receipts are recorded in release-1.0.14.md. Native permission/layout/input/taint smoke tests and the existing bag-use taint investigation remain pending. No game deployment, junction or real SavedVariables edits.

## Linked castbar sizes — November 12, 2026

Each Player/Target/Focus bar offers Match size to: Manual or either other bar. Matches follow width/height changes and native source resets; cycles are rejected. Direct slider or text edits switch to Manual immediately, retaining the other dimension; Reset restores native size and clears the match. Keep settings/profile persistence, source-unavailable feedback and existing combat/Edit Mode restrictions. Native rendering/input/taint verification pending; release remains held.

## Castbar adjustment and Reset — November 12, 2026

Remove the separate custom-size switch for Player/Target/Focus. Editing a dimension applies sizing automatically; Reset restores native size and displays native dimensions. Preserve independent bars, old saved choices until an explicit edit, profile behavior, native layout and combat/Edit Mode deferral. Browsing or leaving untouched fields must not enable resizing. Regression passes; native verification pending. Release remains held.

## Reviewed unpublished changes — November 12, 2026

Release is held at the user's request after the full offline review. Preserve both corrected UI behaviors: paginated buff lists restore their count after a short filter, and creating a contact in a custom group immediately marks preselected membership as an unsaved draft with Cancel available. Regression and addon-wide checks pass; native validation remains pending. [Review](addon-review-2026-11-12.md). No version or publication change.

## Page wheel and remaining settings cleanup — November 12, 2026

User authorizes the wider pass after adding page wheel scrolling. Buff-list wheel gestures now scroll the whole page, including while hovering Track/search/appearance controls. Genuine nested scrolling views and sliders with explicit adjustment gestures retain their own input. Remove the remaining Bags, Upgrades and Action Bars subpage tabs; use one settings column and labeled sections across leaf pages, retaining search, direct links and saved preferences. Keep proc/keybind controls together. Choose comparison profiles directly, expand advanced weights inline, and replace repeated-click enum choices across professions, vendor, camping, fonts, progress bars, meters and setup with explicit menus. Preserve optional defaults, draft protection and native/manual actions. Native input/layout/taint validation pending; standalone tool editing workflows retain their existing purpose-specific controls.

## Simplified buff settings — November 12, 2026

User confirms Battle Shout works and approves beginning UI simplification with Buff Reminders. Replace Reminders/Visibility/Appearance/Buff choices/Custom spells navigation with one form: main switches, My class buff list with Track checkboxes and inline hidden/combat-off reasons, plus expandable Appearance and Advanced sections. Show explicit alternative spells and warning intervals; keep class/all/hidden filters directly selectable. Advanced contains custom spell add/scope/remove controls in place. Search reveals the specific control. Preserve settings/defaults, per-buff Off choices and combat behavior. Regression passes; native UI smoke pending. Follow with bags/inventory/upgrades, other combat/interface pages and tools in later passes.

## Missing combat Battle Shout follow-up — November 12, 2026

Retain combat reminders across harmless roster/connection notifications when all prepared public unit identities still match. Suspend on changed/unknown identities, world entry or combat option reconfiguration until safe preparation. User's last disk-saved Warrior shout family remains explicitly hidden; restore through Battle Shout → Show reminder without silently overriding Off. Automated regression passes; native omission/root cause and combat visuals remain pending.

## Untrained leveling recipes — November 12, 2026

Live-learning follow-up: learning at a trainer or from a recipe/manual must remove the warning while the guide remains open, without reload or reopening. Listen for native recipe-learned and detail-update events through the existing next-turn coalesced refresh. Preserve browsing/scroll and wait for authoritative metadata if the learning notification arrives first. Native timing verification pending.

Show a subtle red 11px acquisition line immediately beneath each unlearned recipe. Expand the initial two-recipe fallback to all 122 distinct recipes used by the eight crafting guides: Alchemy, Blacksmithing, Cooking, Enchanting, Engineering, First Aid, Leatherworking and Tailoring. Use 75 reviewed faction-specific or neutral learning locations, distinguish Trainer/Vendor/Manual/Quest in the compact label, and place/track a native waypoint on click. Keep longer learning instructions on hover. Recipes with no known fixed source (Major Healing Potion manual) disclose the limitation without a fabricated pin. Gathering and Lockpicking guides have no modeled craft recipe rows; do not invent recipes or untrained states for those routes.

Require readable learned=false for a warning and learned=true for selection; loading/unknown/linked/guild/NPC data must not imply untrained. Preserve manual crafting, combat/stale-row guards and no automatic training/navigation. Native UI, availability, recipe teaching and waypoint verification pending.

## Multiline contact notes — November 12, 2026

User requests a proper readable multiline Notes box instead of a thin line. Add a fixed-height bordered notes panel with padded scrolling input, larger note font, native Enter/newline behavior, blank-area focus and cursor/wheel scrolling. Preserve multiline text during saving, automatic contact updates, reload and search; retain the existing 240-character limit. Keep the narrow shell and existing contact workflow. Native visual/input validation pending.

## Narrower Contacts layout — November 12, 2026

User requests a narrower window after annotating empty space in each column. Set the shared Contacts/Groups/Preferences shell to 740×650 instead of 900×650 (about 18% narrower), reducing column widths/gaps and reflowing controls while retaining fonts, eight contact rows and existing behavior. Native layout/readability retest pending.

## Contact row click-to-fill — November 12, 2026

User expects clicking a displayed contact beside Send Mail to fill To. Restore this behavior for saved and roster-only contacts across the shared directory filters. Keep the explicit recipient button as an alternate action. Preserve genuine editor drafts while addressing saved rows; keep standalone and unassigned recovery clicks edit-only. Compare actual editor values and staged groups to the selection baseline so blank/unchanged programmatic notifications do not block selection with a false unsaved flag. Preserve native send guards and manual sending. Native screenshot establishes the reported problem; build/Interface and fix verification remain pending.

## Unified Contacts workspace — November 12, 2026

User authorizes combining Mail contacts and Contact book into one tabbed window, immediate recipient use after saving, and simpler groups. Implement Contacts/Groups/Preferences, shared by settings, /wfs contacts and Send Mail. Contacts provides group navigation, search/sort, eight readable rows, details, explicit Use as recipient, Save/Cancel and Save current To. Save selects the contact without a transfer step and preserves filters/drafts. New contacts in a custom group preselect membership. Preserve scope isolation, native sending, current-character exclusion beside mail and independent feature switches.

Groups provides visible contact/source lists, direct/inherited markers, source explanations, deduplicated totals, search, create/rename/delete and sidebar visibility/order. Immediate membership changes retain cycle/combat/stale-context guards. Preferences contains row details and unassigned recovery; sorting persists. Fit small viewports. Standalone/mailbox openings reuse one shell with appropriate closing behavior; respect explicit dismissal during queued refreshes. Native rendering/input/taint validation pending; no release/deployment/live-data changes. Supersedes older companion-only sizing and wrapped mailbox tabs.

## Custom mail groups and parents — November 11, 2026

Unified names follow-up: user requests one system instead of separate categories and groups. Call everything Groups, remove the contact category field/chooser, and use the exact same plain group names for contact membership and Custom filtering. Adopt old category assignments into ordinary custom groups across all regions/server types, including unassigned recovery records. Merge matching names ignoring case/outer whitespace, preserving existing members, parent links, order and visibility. Reuse a group when Create receives its existing name; reject rename collisions. Preserve old category metadata/aliases internally for migration/recovery, with per-assignment adoption markers so removed/deleted memberships do not return. Keep parent groups and multi-membership Save behavior. Native migration/menu/layout/taint retest pending; no release or deployment change. Earlier category/group distinctions below are superseded.

Contact assignment/filter follow-up: user finds created groups missing from contact selection/filtering and requests All, Alts, Guild plus a custom-name dropdown. Remove the Contact book's Other tab and replace the old cycling filter with Custom beside those three buttons. List existing categories and all created custom groups, including empty ones; show the selected name above the list. Group filters include nested/inherited members and combine with search. Add a multi-select Groups chooser on each contact; stage direct membership changes until Save, preserving draft choices across editor tabs and unrelated memberships when saving. List direct saved group names in contact row details. Existing category editing remains supported. Combat, hidden-pane, changed-contact and changed-region/server-type menus fail closed. Native rendering/input/taint retest pending.

Shared-window follow-up: user requests Contacts and Groups tabs instead of two windows. Supersede the sibling-placement/stacking approach below with one Contact book shell, one close/Escape action and two mutually exclusive child panes. Both mailbox entry points select the matching tab; switching or reopening an already-visible shell keeps its position and unsaved drafts. Retain eight compact contact rows within the original 670×602 outer dimensions. Groups-first opening also works with mailbox integrations off, using the shared book roster lifecycle. Native visual/input retest pending.

Opening-order correction: screenshots show Groups/Contact book overlapping and drawing controls through one another in either order. Place the second editor beside its visible sibling when possible; when the screen forces overlap, raise its complete backdrop/controls above the other window. Native top-level behavior and background clicks allow foreground switching. Preserve unsaved edits and combat guards. Native retest pending.

User requests Send Mail categories that can replace Alts/Guild/Other, arbitrary visible groups/order, resizing and vertical overflow; confirms parent groups should support both child categories/groups and individual contacts. Add Mail groups from the companion and standalone Contact book. Custom groups union selected automatic groups, existing contact categories, other custom groups and explicit people, deduplicating names. Reject parent cycles; saved malformed cycles terminate. Show/hide and reorder all groups, with an All fallback when every group is hidden. Default visible tabs remain Alts/Guild/Other. Wrap tabs into rows with bounded vertical scrolling; Wider/Narrower and Taller/Shorter controls save companion dimensions. Explicit membership uses scoped addresses, survives book rename and guild-to-saved transitions, and is cleared on contact removal. Deleting a parent retains children/contacts. Store definitions/layout inside the existing profile-excluded contact book; retain server-type/region/current-character filtering and native explicit sending. Native layout/input/persistence/taint checks pending; no release or deployment change.

## Authorized 1.0.13 release — November 11, 2026

Publication verified: release run 43106059568/job 130809567145 succeeds, including CurseForge project 1749120 upload and GitHub asset verification. [Receipts](release-1.0.13.md#publication-verified). Native verification and public moderation availability remain separate.

User requests addon-wide review and CurseForge publication if the code looks good. Offline review identifies no new concrete blocker; 89 Lua files, 37,439 assertions, 11 gear-baseline tests and an exact 98-file source/hash archive comparison pass. Prepare 1.0.13 for the existing Forever-flavor/project-1749120 tag workflow. [Review](addon-review-2026-11-11.md) and [release receipts](release-1.0.13.md) retain unverified native selection/batch/deposit/rendering/taint limits.

## Profession Leveling flyout — November 11, 2026

Existing-settings follow-up: adopt automatic recipe selection once for existing account settings, full settings profiles and personal overrides using professionLevelingAutoRecipeVersion = 1. Later Off choices survive reloads and profile switches; personal opt-outs retain their marker when stored as differences. The main guide enablement and manual crafting behavior remain unchanged. Native reload/profile smoke test pending.

Automatic-selection follow-up: add an independent, default-on “Select current leveling recipe” setting under Bags & Gear → Professions. With guides enabled, follow the first primary modeled recipe covering the active native rank on profession open and recipe-boundary changes, including with the flyout closed or browsing another guide. Require learned/canSkillUp native metadata and skill-line membership; leave unavailable/unlearned/grey/unmodeled steps alone. Preserve manual selection within a step, deduplicate native feedback and rejected requests, and wait for manually started batches to stop. Crafting always remains manual. Combat cancels automatic following until the profession is reopened. No version, release, deployment or real SavedVariables changes; native smoke tests pending.

Recipe-selection follow-up: make each primary recipe name inside expanded steps a clickable, highlighted button. Attach exact recipe spell IDs from the eight Forever source guides, then validate native metadata, the currently open profession and native skill-line membership on each explicit left-click. Use C_TradeSkillUI.OpenRecipe, the client path used by tracked recipes, to request native selection. Keep accordion headers for expand/collapse and material rows for item tooltips. Disable recipe buttons when the matching profession/capabilities are unavailable; never switch to a different browsed profession, queue combat clicks, learn, craft or press Create. Recycled/collapsed rows clear bindings; compact status messages explain loading/unavailable/rejected requests. Native selection/filter/taint smoke tests remain pending; no setting/default/version/release/deployment changes.

Stocked-material follow-up: default a saved Hide Stocked preference on, with Show Stocked / Hide Stocked beside the lower flyout controls. The top list hides materials only when recorded stock covers their entire unfinished-plan requirement; do not hide unknown stock or a repeated material merely because one row is affordable. Remove empty group headers and explain a fully covered view. Show Stocked restores covered materials with native green check icons; individual recipe inputs also show checks when that step is covered. Keep Show Done references independent. Reuse existing stock/cache/refresh/tooltip/combat behavior and normal profiles/search. No new scans, version or deployment.

Remaining top-list follow-up: replace full-band shopping quantities with the same per-recipe remaining-craft projections used below. The projected top plan follows the primary recipe examples, merges repeated ingredients within sections and combines unfinished totals before subtracting stock. Reuse intermediate outputs from earlier remaining recipes so they are not also requested as purchases; respect recipe yields (Fire Oil produces two). Do not assume completed crafts remain in inventory. Keep Show Done reference rows, vendor markers, normal hover/stock handling, matching-rank rules and incomplete-route caveats. At Blacksmithing 173 top Iron/Green Dye becomes 24/4, at 174 it becomes 12/2. Cooking also gets a projected top list. Caption explicitly excludes recipe quests and optional alternatives, whose source facts remain available in the guide data/source link. No new setting, version or deployment.

Default/step/faction follow-up: user requests Hide Done on by default, specific-step material estimates and only their faction's directions. Default Hide Done to true and adopt it once in existing account/settings profiles through a view-version marker; preserve subsequent saved Show Done choices. Keep the main feature default-off. Expanded crafting steps show primary example recipes, estimated whole crafts for remaining points, and per-step Required/Have/Need item rows with normal tooltips where IDs resolve. This is a proportional planning estimate from published full-band craft counts, not a skill-up probability guarantee. At Blacksmithing 173, Green Iron Bracers projects four crafts, 24 Iron Bars and four Green Dye. Keep top shopping totals and unresolved endgame caveats separate. Select structured faction-specific vendor/trainer/route text with guarded UnitFactionGroup; shared neutral directions remain, unknown faction gets a source reference rather than a guessed side. No version/release/deployment or real SavedVariables edits.

Clutter follow-up: add saved Hide Done / Show Done directly beside guide navigation. It starts with completed references visible and removes completed material rows, alternatives and empty brackets when selected, preserving Have/Need totals and tooltips. Add saved Auto steps beside the source-link control, initially On: only the active profession's current skill-range detail expands automatically; all other step headers remain clickable. Manual expansion survives stock refreshes, resets on a new range/guide or Current, and Auto steps Off expands everything. Unknown/unrelated ranks keep all details available. Both preferences participate in normal settings profiles and defer all UI changes in combat. No feature enable/default change, version or release/deployment.

Have/Need/current-skill follow-up: show aligned Required, Have and Need total columns beside every material. Use recorded characters' bags/banks and the shared bank once, independently of the tooltip-count preference, without enabling recording. Aggregate repeated unfinished main-route ingredients before subtracting stock; alternatives substitute their entire row. Dim completed material uses/brackets and mark Done rather than deleting them; Blacksmithing 173 must retire Rough Stone and bronze supplies while retaining the current iron band. Apply the native rank only to its own guide. Unfinished rows retain full source estimates rather than pretending to simulate remaining random skill-ups. Mark incomplete storage with + / ≤ and absent usable records with ?. Refresh from existing inventory notifications only while open, preserving scroll and normal hover tooltips. Native fit/count-refresh/Done rendering remains pending; no new preference, version or deployment.

Follow-up: widen the companion from 360 to 460 pixels (410px reading area), and put complete published material shopping tables before the route summaries. Include all seven source tables with skill brackets, per-row alternatives, vendor marks, and explicit provisional/omitted-supply/unfinished-range notes. Gathering, Cooking, Lockpicking and Camping sources do not offer universal shopping tables; do not invent totals. Each material and alternative has an exact sourced item ID and a native hover tooltip, reusing the existing Inventory in tooltips setting and recorded character bags/bank counts. Do not auto-enable tracking or duplicate inventory blocks. Reuse material widgets, clear hover on navigation/scroll/hide/combat, and use the expanded width for docking. Native visual/hover checks remain pending; no release/deployment changes.

Load-warning follow-up: the recorded TOC warning predates ProfessionLeveling.lua creation by thirteen seconds during implementation. The existing game junction now exposes the completed file at the correct path. Retry after a fresh launch; completed-module native loading/rendering remains unconfirmed. No speculative runtime correction or deployment change.

User requests a Leveling button in the marked native profession header and an attached colorful guide. User chooses original summaries and source links instead of reproducing full website articles. Add independent/default-off Bags & Gear → Professions → Profession leveling guides. The shared native profession window gets a Leveling button beside its link control; the overview keeps a launcher for non-crafting skills. A slate/teal, scrollable companion follows its owner, clears right-side profession tabs, prefers the left when needed, and closes with the owner. Current selects the active guide; Previous/Next browse all 14 entries, including gathering, Lockpicking and Camping. Show readable native rank and mark its skill band; omit unavailable ranks. No automatic crafting or purchases.

Bundle original English summaries and selectable source URLs from the site's **Forever** guides, reviewed November 11. No website runtime fetching or copied articles/images/maps/macros. Preserve source qualifications: high-level routes remain untested or incomplete, notably Tailoring after 265. The source link selects native text for Ctrl+C, not an automatic browser launch. Include ordinary settings profiles/search and support capabilities. Offline validation passes; native placement/rendering, input, build/Interface and taint remain pending. No version, publication, deployment, junction or real SavedVariables edits.

## Buff icon corner specks — November 11, 2026

Investigate reported bright corner dots on weapon-coating reminders, sometimes the only visible remnants in combat. Replace the likely sliced-border artifact source with four flat colored edges across normal, preview and combat buff icons. Preserve theme colors, sizing, actions and native aura visibility/masking. The screenshot establishes the marks; the exact native combat-remnant cause is unconfirmed. Native retest pending; no release/deployment or preference changes.

## Personal-bank Deposit Reagents button — November 11, 2026

Add independently optional/default-off Deposit Reagents button under Bags & Gear → Bags & Bank. At the live personal bank, place the native-style button beside Purchase, retaining a lower-bank placement when Purchase is hidden after all bag purchases. One click requests transfers of native-classified carried crafting reagents that fit; native storage rules decide full/partial stacks and specialty capacity. Search filters do not limit the batch. Never transfer on opening or from saved/account views. Revalidate each source, wait finitely for unloaded metadata and cancel on context loss, combat, cursor/targeting changes, bank/tab closure, disable or logout. No idle work or automatic resume. Offline checks pass; native transfer/visual/taint tests pending. No version, release, deployment or real SavedVariables edits.

## Shared saved-bank and live-bag search — November 11, 2026

Native follow-up: user reports, "Yeah it seemed to work." Screenshot shows `coar` in the bank and combined-backpack fields, matching stones bright and nonmatching slots dimmed in both, with ownership results visible. Shared search/dimming is user-confirmed for the shown interaction; the bank appears live (Purchase controls), so this screenshot alone does not establish saved-bank coverage. Actual build/Interface, both-direction clearing, saved-view reopening, other layouts and combat/taint checks remain unreported. This supersedes the general pending visual note below only for the observed result.

Searching the saved bank also filters live bags, and live bag/native-bank edits update the visible saved view. Clearing either clears both; reopening a saved view adopts the current native search. Applies to saved bag views too, independently of the cross-character ownership popup. Preserve native filtering/scripts, guard restricted input and defer combat writes. Offline checks pass; native visuals/input/taint pending. No new preference, version or release/deployment action.

## Authorized 1.0.12 release — November 11, 2026

Publication verified: v1.0.12 passes release run 43060483233/job 130661389504, including successful CurseForge project 1749120 upload and GitHub asset checks. [Receipts](release-1.0.12.md#publication-verified). Public availability and native test limits remain separate.

Publish the pending reputation/primary-region tracking, None / 10% / 5% progress lines, shared tonic restoration and combat-only Warrior shout changes as user-authorized 1.0.12. Preserve old settings and existing native confirmations; remaining native checks and bag-use taint investigation stay qualified. [Release checks and receipts](release-1.0.12.md). No game deployment, junction or real SavedVariables edits.

## Progress bar line spacing — November 11, 2026

User confirms the progress-bar appearance looks great in game. Individual mode/bar-type coverage, build/Interface, persistence and combat/taint checks remain unreported.

Other bars → Progress bar options offers one Lines control cycling None → 10% → 5% → None. Ten-percent spacing gives ten sections; five-percent spacing gives twenty. Keep existing enabled users at 10%, disabled/fresh settings at None, and the original skin dependency. Retain the optional boolean plus a validated saved 5/10 interval, shared through existing profiles. Reuse divider textures and defer combat layout; preserve native fill/rested/text behavior. Full offline checks pass; native visuals/persistence/taint pending. No version/release/deployment or real SavedVariables edits.

## Primary faction selection across outdoor zones — November 11, 2026

User confirms reputation switching works and clarifies the full addon, rather than test addon, was installed. Treat the reported switching failure as resolved; loaded revision, exact trigger, running build/Interface and remaining per-zone checks are unreported.

User clarifies that Riverglades must select Brotherhood on arrival and requests the same rule across zones with one primary faction. Expand the optional zone reputation map across faction quest regions and neutral reputation zones. Riverglades selects Brotherhood for Alliance and Bolder'ok for Horde; Zephras selects High Order/Windshapers; Hyjal, Plaguelands, Silithus/Moonglade, Searing Gorge and Tanaris select their primary local reputations. Powderfuse Port and Shadowgale Forest override their parent regions. [Complete mapping and research limits](zone-reputation-mapping.md). Mixed/unestablished regions keep current tracking until a standing change. Existing any-faction event tracking and lifecycle guards remain. Supersedes the previous no-Riverglades-arrival limitation. Full offline checks pass; native arrival/rendering/taint tests pending. No default/version/release/deployment or SavedVariables change.

## Recurring native bag-use taint — November 11, 2026

Four more native right-click UseContainerItem blocks reported, increasingly frequent. Reopen the November 8 investigation: reload success was temporary recovery, not resolution. Existing disk taint log remains November 5. No originating write established by native dependency/Suite bag-interaction review; retain native input and capture a fresh detailed taintLog 2 chain before choosing a runtime correction. Actual build/Interface, item and preceding interactions remain unreported. No runtime or release/deployment change.

## Reputation tracking includes Other factions — November 11, 2026

Extend Track reputation for this zone to follow native standing changes for any readable, watchable faction, including Brotherhood of the Horse and factions beneath collapsed Other headers. The prior short zone/town mapping omitted Riverglades; retain that mapping on arrival while allowing subsequent standing changes (gains or losses) to take priority. Keep manual choices until another standing or zone change, preserve tracking in instances, coalesce events, defer combat writes and cancel on disable. Use native event faction IDs and direct lookup; no custom faction-ID guesses, UI header expansion or new setting/default. This supersedes the earlier limited-map contract. Full offline checks pass; native Riverglades/event/rendering/taint retest remains pending. No release/deployment or SavedVariables edits.

## Combat-only short shout upkeep — November 11, 2026

Battle Shout and Commanding Shout reminders now appear only in combat, retaining existing native missing/expiry rendering, learned ranks, recipient scopes and optional combat switch. Hide their out-of-combat personal, outgoing and incoming reminders. Keep longer-lasting buffs unchanged; `combat` alone does not mean short duration. Last disk-saved Warrior shout choice is explicitly Off (`0`); preserve it and use Buff choices → Battle Shout → Show reminder to restore. Automated regressions pass; native retest pending. No settings migration, version/release/deployment/junction or real SavedVariables edits.

## Shared health/mana tonic restoration — November 11, 2026

Recognize shared restoration text such as Tessa's Tonic's “720 to 880 mana and health” for both combat recovery macros. Rank the shared amount independently against each resource's other carried potions, preserving requirements, existing potion categories, optional combat additions and macro ownership/write guards. No name/ID exception or Warrior-specific behavior. Screenshot confirms wording, not native category/ID; regression uses a synthetic potion fixture. Health failure reproduced offline; native health retest and mana-character test remain pending.

## Authorized 1.0.11 release — November 10, 2026

Publication verified: v1.0.11 passes release run 42955499218/job 130309497219, including successful CurseForge project 1749120 upload and GitHub asset checks. [Receipts](release-1.0.11.md#publication-verified). Moderation/public availability and pending native tests remain separate.

User authorizes publishing the Warrior stance macros, food inventory refresh and edible cooking reagent correction as 1.0.11 to CurseForge. Core and both TOCs advance together; existing native confirmations and pending smoke tests retain their scope. [Release checks and receipts](release-1.0.11.md). No game deployment, junction or real SavedVariables changes.

## Edible cooking reagents — November 10, 2026

User confirms FS Food automatically picked up Yellowtail after reloading. The reported reload-selection failure is resolved; broader native checks remain separate.

User's runtime item query identifies Yellowtail as class 7 / subclass 8 with a Food use spell, rather than the class 0 / subclass 5 assumed in the previous regression fixture. Correct the fixture and allow cooking reagents in automatic food and the food picker when their live English tooltip confirms health restoration and seated eating. Keep required-level/use/data checks, ranking, explicit preferences, drink scope and existing-only macro writes. Category-correct regression fails before this fix and passes afterward, including reload from the user's potion-only body. Offline checks pass; native retest pending. This supersedes the unresolved-classification notes below.

## Food follows inventory changes — November 10, 2026

Follow-up: user reports reload still leaves FS Food stale with Yellowtail carried. Keep this issue unresolved; canonical game junction and matching last-saved ownership/body are confirmed read-only. Need runtime macrostatus evidence before attributing the remaining failure or claiming another correction.

Carried Raw Spotted Yellowtail still requires GUI Update according to the user. Refresh created FS Food on coalesced bag changes and level-up, independently of the GUI and class-update preference. Preserve existing selection/ranking, metadata, ownership, combat and editor guards; never create missing macros. Keep bag-open/startup/use checks and use no polling. This supersedes earlier instructions that ordinary inventory changes must never refresh idle food; other item recipes retain their existing triggers. Offline checks pass; native retest pending.

## Warrior stance macros — November 10, 2026

Offline checks pass: 86 Lua 5.1 files, matching TOCs and 34,620 substitute assertions; git diff --check is clean.

Add Warrior-only Charge / Intercept, Stance interrupt and Overpower recipes using the supplied English macro bodies. Charge follows the revised exact order: combat Berserker Stance, combat Intercept, out-of-combat Battle Stance, then out-of-combat Charge. Keep the separate existing Pummel recipe. Preserve Overpower switching only from Defensive Stance. Reuse explicit Create / update and existing ownership/combat guards. Ten Warrior recipes plus six shared and ten item slots fit the computed 26-row pool. No automatic creation or new setting is needed. Native stance timing, tooltip selection, casts and taint require in-game results.

## Final review and authorized 1.0.10 release — November 10, 2026

User authorizes a final whole-addon code review and CurseForge publication if no release blocker is found. Reviewed the current 86-file runtime tree with full Lua 5.1/behavior checks, pinned build-70862 API/event/signature/global-write/literal-key scans, lifecycle/action-boundary inspection and release-workflow probes. No new concrete release blocker was established. Two optional guarded legacy pet-journal fallbacks retain their prior qualification. All 34,529 substitute assertions and 11 separate gear research tests pass; 95 addon package inputs and 73 registered Lua specs are accounted for. Core and both TOCs advance to 1.0.10. Include all pending feature/fix work and its research/tests/documentation; cache references never ship. User-confirmed tooltip colors are recorded separately from pending native build/Interface, gear calibration, input/layout/performance and taint results, including the previously deferred map/tracker investigation. Publication does not mark those tests verified. No game deployment, junction or real SavedVariables changes. Final package and remote CI/upload evidence are recorded separately.

## Tooltip level difficulty colors — November 10, 2026

November 11 palette correction: Burning Exile's level 39 is green in native displays but yellow in the tooltip. Prefer the client's creature-content difficulty and native palette, matching the target-frame source, over generic level-difference thresholds. Keep relative-color fallback only for absent native capabilities; restricted/invalid native results stay untouched. Preserve default-off settings, number-only coloring, red ?? and disable restoration. Native parity retest pending; no version/release/deployment change.

User confirms the fallback fix works in game and tooltip colors now change. This resolves the reported white-level failure. Running build/Interface and separate red ??/persistence/combat checks remain unreported; earlier pending notes below describe the pre-confirmation state.

Follow-up: enabled option still shows a white Level 32 in the user's Sparkleshell Borer screenshot. Support absent/generic row metadata by matching the localized native level label in bounded rendered rows; retain metadata as the preferred route and avoid coloring unrelated numbers. Substitute regressions pass; native retest pending.

Add independent default-off Bags & Gear → Tooltips → Level difficulty colors. Color only the readable level number in the native unit-level row using Blizzard's relative difficulty palette; the requested level-33 creature at player level 38 should be green. Preserve surrounding native text; the public unknown-level sentinel (-1) colors a plain ?? display with Blizzard's impossible (red) palette. Skull textures remain native. Use supplied tooltip data and its rendered line index, validate levels/text/colors before operations, restore owned text on disable, and add no inspection, polling or events. Native appearance/nameplate comparison remains pending; no version, release or deployment change.

## Full talent-plan sharing — November 10, 2026

Export saved plans as WFS2 with the name, final ranks/choices, exact per-point leveling order and notes. Keep WFS1 imports working with their original Imported build name, empty notes and a generated legal order. Do not share local favorites, build IDs, undo history or learning-guide state. Existing notes limits and SavedVariables shapes remain unchanged.

Replace the immediate UI import with Review import, showing the name, full scrollable notes/order, point count and legacy limitations. Import as new explicitly creates a separate saved draft; Cancel/Escape/hide/combat/disable/context changes discard the pending review. Revalidate the originally reviewed code, tree/class, structure, point order, library capacity and current-level limits at confirmation. Refuse an over-budget plan instead of truncating it; the user can turn off Limit to current level to import a future plan. Never learn native talent points or overwrite a saved build.

Bound WFS2 input at 32,768 ASCII bytes and 512 final records/point steps; encode name/notes text bytes without delimiter ambiguity or executable payloads. Preserve the WFS1 16,384-byte limit. Verify Unicode/multiline notes, custom orders, malformed/secret data, atomic failures and native-input-script preservation. Native clipboard, scrolling, layout and taint remain pending; no release/deployment change.

## Whole-addon follow-up — November 10, 2026

Reject zero-capacity backpack observations in the shared aggregate reader so transient unavailable data cannot overwrite complete inventory counts or invent Supply Checklist shortages. Keep zero-slot unequipped bags valid, retain last complete records and resume on existing events; add no setting, schema or polling. Regression coverage passes; native occurrence/recovery remains unverified.

The previous review's gear/spec expansion, capability report and checklist input recommendations are implemented in the pending working tree. Next priorities are focused native regressions and gear calibration, followed by full talent-plan sharing and sourced profession planning as separately scoped features. Measure native cost before broader optimization. [Updated whole-addon review](addon-review-2026-11-09.md#whole-addon-follow-up--november-10-2026).

## Supply Checklist item drops and tooltips — November 9, 2026

Accept an item dropped/click-placed into the existing item editor, using the readable native cursor item ID. Keep pasted IDs/links. Validate before cancelling cursor placement; preserve quantity and saved targets until explicit Save target, cancel stale removal confirmation and focus quantity. Reject non-item, invalid/restricted, failed/unavailable and combat/hidden input without clearing the cursor or changing the draft. No item use, purchase, deletion or transfer is added.

Give checklist rows native item-ID tooltips independently of carried tracking. Bind IDs to the current page, refresh a stationary hover after recycling/metadata loading, and clear stale/hidden/closed/combat tooltips. Hide only a tooltip still owned by the checklist row; guard forbidden widgets, missing methods, native errors and ownership changes during callbacks. Keep row clicks, wheel paging, coalesced scans, ID-based counts, per-character targets and SavedVariables shape unchanged. Native input/rendering/taint results remain pending; no new setting/version/release/deployment action.

## Copyable support report and capability reasons — November 9, 2026

Implement Suite Settings → Support plus `/wfs support` / `/wfs diagnostics`. Expand existing `/wfs status` with function-level capability problems and paused/unknown reasons. Report Off/Unavailable/Paused/Waiting/Ready/Unknown with conservative scope: Ready is listed capabilities/component presence, not gameplay or taint proof. Respect parent switches and actual deferred keys; explain combat action pauses, native editor/movie pauses, missing context, school-parser locale, native meter availability and audio output permission flags.

Capture requested combat snapshots without creating UI or scheduling an automatic window. Explicit opening after combat copies the original filtered text; Refresh captures current state. Use native selectable text/Ctrl+C, bounded static data and privacy allowlists; no error/settings dumps, personal records, device IDs, custom names/weights, scans/actions/retries/polling, upload, setting changes or SavedVariables. [Report behavior and coverage](support-report.md). Native layout/clipboard/input/taint checks remain pending; no version/release/deployment action.

## Gear modeling first step — November 9, 2026

Implement manual character-only spec selection alongside Automatic, the five broad roles and saved custom profiles. Provide 29 class-filtered spec/role choices, explicitly distinguishing Cat/Bear and ranged Survival and enforcing the Combat Daggers main-hand constraint in stat mode. Spec coefficients are original editable preference starters, not copied external maps or calibrated output predictions. Automatic/old roles remain unchanged.

Expand the editor to 46 stat weights: ratings by physical/spell/ranged usage, expertise, defenses/block, penetration, health/mana/recovery, effective spell/healing totals, schools and resistances. Share guarded raw-stat/English-static-school parsing between markers and explanations. Suppress unavailable/secret/ambiguous sources; never convert rating points into percentage points or add overlapping aliases. Preserve all existing custom coefficients/names/IDs/selection/preferences, including precise unchanged values when editing. Resize the scrollable editor below all inputs and reveal keyboard-focused fields. See [model contract](gear-modeling.md).

Remaining work: native item-stat/tooltip samples and role calibration; validated effects/set thresholds, caps, weapon-family skill and Feral mechanics remain outside this step. No new defaults, automatic spec inference, release or deployment action.

## Addon quality improvements — November 9, 2026

Following the whole-addon comparison, prioritize existing-feature depth and native reliability. Implement checklist event coalescing/requested-metadata filtering and single opening scan; add Mail Deadlines manual countdown refresh plus calculation freshness; clarify weighted-score percentage versus damage/healing and item-level comparison wording. Preserve all defaults and saved-data semantics. Offline checks pass; native controls/appearance remain pending.

Next work, in order: focused native regression results; validated gear stat/spec coverage preserving custom profiles; copyable capability diagnostics; checklist drop input/item tooltips; full talent-plan export with order/notes; sourced profession planning. Measure performance before broad optimization and extract GUI responsibilities incrementally. Detailed comparisons, all-file coverage and acceptance criteria: [November 9 quality review](addon-review-2026-11-09.md). These larger items are recommendations, not newly implemented features or release authorization.

## Rounded upgrade percentages — November 9, 2026

Show stat/weapon upgrade headlines as score gain divided by the positive equipped score: nearest whole percent from 1% upward, one decimal below 1%, and +<0.1% for tiny positive gains. Zero/negative baselines retain explicitly labeled score points. Keep detailed score/stat contributions and item-level comparisons unchanged. No new setting or release/deployment action.

## Authorized 1.0.9 release — November 9, 2026

User authorizes version bump and CurseForge publication for Random mount (selected icon and mounted dismount) plus item-macro draft discard. Align Core/both TOCs, README and changelog at 1.0.9. Keep pending buff-catalog removal and scoring research outside this release, preserving their working files. Check the isolated committed release tree/package, push main, wait for its checks, then publish through a fresh v1.0.9 tag. Prior 32,456 substitute assertions pass in the working tree; final release-tree results and remote upload evidence are recorded separately. Native mount/dismount/icon/draft-button/taint checks remain pending; authorization does not mark them verified. No game deployment, junction or real SavedVariables edits.

## Random mount also dismounts — November 9, 2026

Extend the Suite recipe: outside combat, an unmounted press randomly selects a usable mount; a mounted press requests dismount only and retains the last selected icon. No collection query, reroll, icon write or summon on the dismount press. Keep ownership/editor/combat guards and guard native mounted-state access; unavailable state/dismount never falls through to mounting. Existing macro text stays unchanged, so reload suffices. No release/deployment change; native dismount validation pending.

## Make unfinished item macros removable — November 9, 2026

Show Discard directly beside uncreated item-macro rows and Discard draft in their selected details. Both remove the unfinished Suite choice immediately outside combat, preserve unrelated selection and remain absent after reload. Created choices retain the existing remove-from-Suite action and keep their game macro. Keep list scrolling/clipping and native macro ownership intact. No native macro deletion, version, release or deployment change; native appearance/input pending.

## Create Random mount through Macros — November 9, 2026

Extend the initial standalone macro with a shared Random mount recipe creating FS Random Mount only on explicit Create. On every press, choose uniformly from collected, usable, character-visible mounts allowed at the current location; update that General macro's native icon while retaining command text, ownership and slot. New mounts require no edits and choices may repeat. Use existing /wfs dispatch, ownership and native-editor guards; combat performs no query/write/summon. No item picker, automatic dismount, favorite-only restriction, extra setting, polling or dynamic tooltip promise. Icon shows the selected attempt; native riding rules determine success. Offline checks pass; native icon/summon/taint remain pending. No release or deployment action.

## Random mount macro — November 9, 2026

Supply a standalone macro at docs/macros/random-mount.txt that reads the full Mounts collection on every press and randomly chooses a collected, usable, character-visible mount. New acquisitions enter automatically; UI search/filter state is untouched. Keep secret-value eligibility guards, combat stop and empty-list handling within 255 characters. Random choices may repeat; riding/location restrictions remain native. This first test does not add a Suite recipe or changing tooltip; no runtime/version/release/deployment changes. Native validation pending.

## Waylaid crate right-click taint investigation — November 8, 2026

User's native UseContainerItem blocked-action report clears after reload: user confirms the crate works on retry. Earlier taint origin remains unidentified; retain existing native item input rather than introduce a speculative replacement. Capture a fresh taint log and preceding interactions if it recurs. No runtime or release change; actual running build/Interface remains unreported.

## Remove situational warlock buff reminders — November 8, 2026

Remove Detect Invisibility and Unending Breath (water breathing) from the built-in Missing Buffs catalog at the user's request. Neither produces self, outgoing group or incoming reminders, and neither appears among built-in buff choices. Explicit custom spell reminders remain available.

## Publish 1.0.8 with persistent contacts — November 8, 2026

User authorizes CurseForge 1.0.8 with the latest contact groups/recovery/class colors, Suite-wide wheel navigation and pending XP-food changes. Preserve twelve explicit player-created contacts/notes through repeated saved-data initialization, disabled mail features and server filtering; profiles exclude the book. Retain the original readable legacy/unfamiliar book during migration/recovery. Keep persistent recipients separate from session-only guild members. Align Core/both TOCs, changelog and README; run final offline/package checks, push main and wait for checks before tagging. User reports a game crash and expects colors to work; this is neither color verification nor an established Suite crash cause. Native wheel/color/taint checks remain pending. No deployment/junction or real SavedVariables edits.

## Mouse-wheel navigation throughout Suite — November 8, 2026

User requests wheel paging across addon pages, including Contact book rows/gaps/footer. Wheel down advances one list page; up returns one, bounded by existing navigation buttons. Cover Contact book (all groups/recovery), mailbox contacts, training, character dashboard/inventory, profile lists/source chooser, buff choices/spell search, talent builds/point order, leveling journal, supply checklist and mail deadlines. Saved bag/bank slots also wheel-page their current snapshot. Settings search and inventory-result popups route wheel over child rows. General settings content and nested text/list panes retain normal scrolling; sliders retain their own wheel actions. No binding changes, new preference, timer, SavedVariables or release/deployment change. Native wheel capture/visual/taint results remain pending.

## Class colors across mail groups — November 8, 2026

Fix Guild names remaining neutral: translate readable native roster class IDs through capability-checked C_CreatureInfo.GetClassInfo and carry class tokens into both contact lists. Enrich matching saved recipients with observed class data, preserving notes/categories and identity; save newly added guild recipients with that class so Other remains colored after departure/reload. Unknown manual-contact classes remain neutral rather than guessed. No new setting, schema, polling or release/deployment change. Native color verification pending.

## Contact book group tabs — November 8, 2026

Add All, Alts, Guild and Other above Contact book search, sharing the mailbox grouping logic. All preserves the complete book view; account identities take priority over guild membership, while the book retains its existing current-character visibility. Keep custom category filtering/notes, class colors and explicit unassigned recovery. Live guild rows can be saved as ordinary contacts, never account alts; unsaved roster rows cannot be removed. Standalone guild browsing works with mailbox switches off, using visible-only event listeners and coalesced/combat-deferred refresh. Closing cancels work/listeners. No new setting, schema, release or deployment change. Native appearance/taint tests pending.

## Recover unassigned mail contacts and color book names — November 8, 2026

Older Contact book allowed blank server types; automatic same-type filtering later hid those saved names. Add an explicit Recover unassigned contacts view in Contact book, restricted to the current region. Select and Save to assign a contact to the current server type while retaining notes/categories. Do not guess a scope or automatically expose unassigned names to Send Mail. Preserve known other-type isolation, duplicate checks, removal markers and combat guards. Color Contact book names using recorded class data, with normal text for unknown/restricted colors. Offline regression reproduces twelve saved/three visible; actual affected data and native recovery/layout results remain pending. No release/deployment changes.

## Mail contact tabs — November 8, 2026

Widen the Send Mail companion from 288 to 336 units and add Alts, Guild and Other above search. Known account characters on the current server type belong in Alts, with the active character hidden. Alts take priority over guild membership. Guild uses the current native guild roster, including available offline members, without saving members as account characters. Manually saved non-alt/non-guild recipients belong in Other. Saved recipients who leave the guild move to Other; unsaved former members disappear. Preserve Contact book categories, notes, server-type/regional scope, search/sort/paging and explicit native sending. Guild entries have no remove-from-roster button. No new setting, schema, version, package or deployment change. Native validation remains pending.

## Prefer experience-bonus food — November 8, 2026

Automatic FS Food prefers the highest disclosed positive kill-XP percentage, followed by existing mage/event/ordinary-food ranking. Stronger restoration breaks ties within those tiers. Promote newly carried XP food over a still-carried automatic non-XP selection during existing checks; retain an equal-bonus current XP choice. Explicit carried preferences override automatic ranking. Use readable live English food tooltips to cover all qualifying IDs, including future discoveries; do not infer XP from Cooking or Well Fed alone. The [100-ID research candidate catalog](research/food-experience-candidates.json) is reference-only, includes drinks and is not exhaustive native verification. No new switch, polling or release action. Native checks are recorded in testing.md.

## Publish latest fixes as 1.0.7 — November 8, 2026

User explicitly authorizes 1.0.7 publication to CurseForge. Include the corrected bag/bank selectors, saved bag capture, server-type scoping/reset, food bag-opening recheck, low-resource proc tint, Shift bypass and chat input/reload corrections. Retain independent switches/defaults, existing release tags and native-verification qualifications. Separate scoring research is outside this release commit and addon package. Core/both TOCs and release notes advance together; final local package and main CI checks precede the new release tag. No game deployment or junction action.

## Selector release-review corrections — November 8, 2026

Both recorded selector defects are corrected offline: label refresh respects native gamepad exclusion, and turning bank snapshots off preserves independently enabled saved bags through settings changes and queued combat rendering. Bank-specific listeners/work still stop; disabling bag recording still closes saved bags. Defaults and visibility of Suite-owned saved-view selectors remain unchanged. New regressions fail before their respective corrections; full checks pass with 32,010 assertions. Native retests and a fresh version/final release-tree validation remain required. This supersedes the uncorrected status in the initial review below.

## Release gate for the current fixes — November 8, 2026

[Readiness review](release-readiness-2026-11-08.md) passes whole-addon offline/package validation but identifies two remaining selector interactions: shared label refresh must preserve gamepad exclusion, and disabling bank snapshots must preserve a still-enabled saved-bag view through unrelated settings changes. Keep the independent recording switches and current defaults. No runtime correction or new feature was implemented during review. Complete the relevant native retests and prepare a fresh version after already-tagged 1.0.6 before release; earlier user confirmations retain their stated scope.

## Establish all-class upgrade assessment baseline — November 7, 2026

User requests evaluation across all classes and a baseline algorithm. Deliver [all-class evidence, policies and executable reference](gear-upgrade-baseline.md), including all 29 observed spec weight maps, arithmetic/coverage audit and meaningful offline comparisons. Keep current runtime scoring unchanged in this research step. Future runtime integration should preserve custom profiles/independent settings, support broader validated stats and explicit spec choice, compare legal complete equipment changes, count actual set breakpoints, and disclose caps/effect/build uncertainty. Do not adopt speculative per-piece set value as an immediate upgrade benefit. API arithmetic agreement is not class-weight calibration or native verification.

## Food refresh when bags open — November 7, 2026

User reports stale FS Food despite carried Mulgore Spice Bread and requests a bag-opening check. Check the created food macro once on native combined/individual bag OnShow, independent of background class updates and macro-use detection. Coalesce multiple bags into existing deferred item work; retain stock selection, ownership, manual-edit and combat/editor/data safeguards. This adds bag opening to the accepted startup/use triggers and supersedes earlier blanket instructions that unused food must never refresh on bag opening. Ordinary looting with bags already open still adds no idle supply updater. Offline: 31,990 assertions pass, including the screenshot's bread tooltip; native refresh/execution/taint verification pending.

## Character selectors in bags and bank — November 7, 2026

Latest user correction supersedes raw realm labels and region-only filtering below: show the canonical server type (for example Name · PvE) and restrict bag/bank dropdowns to the current region and known server type, matching Contact Book. Share its server-label parser/current-scope detection, including normalized CAMWOW names; keep PvE/PvP/Hardcore/RP variants separate and unknown types hidden. Revalidate scope on selection, including stale menu callbacks. Contact categories/removal decisions do not delete inventory records or determine inventory ownership.

Follow-up: add a 20×20 native refresh-icon reset immediately right of each character dropdown, narrowing the dropdown by 24 units to preserve the original group width/search spacing. Reset bags to the live current character and saved banks to the current character's personal record (or its unrecorded empty view); native-bank reset leaves the current live bank open. Reset follows selector visibility and combat guards.

User requests dropdowns in the marked bank/combined-bag space and an individual-backpack layout, clarifying that selection should show that character's saved inventory snapshot. Place bank selectors left of search; shorten/reanchor combined search on the right with the selector on the left. Move individual backpack search slightly up and fit a second selector row in existing header space, preserving the native item grid, sort button and portrait/title input. Leave gamepad prompts under native ownership.

Bag selectors follow existing inventory recording switches; bank selectors follow Bank snapshots. Defaults remain off. Save complete bag slots separately from aggregate counts; loading/restricted data retains the last complete view. Older count-only records require logging into each alt after updating before slot browsing is available. List same-region characters with realm labels and disable missing snapshots. Alt selection opens the Suite-owned view-only slot renderer beside bags, with owner, source, recording time, search and pagination; choosing the current bag character returns to live bags. Bank selection closes a live bank through its normal panel lifecycle before showing saved contents. No saved contents in native actionable buttons, native item transactions, polling, deployment or junction changes. Native layout/taint verification remains pending.

## Keep low-resource proc popups visible — November 7, 2026

User confirms “Yes that works” after the fix: requested low-resource proc visibility/dimming is user-confirmed in game. Actual running build/Interface and broader class/expiry/taint coverage were not supplied; the remaining checklist stays open.

User requests Overpower stay visible and darken when rage is insufficient. Treat a readable IsSpellUsable insufficientPower result as resource-limited availability for learned reactive skills, retaining existing cooldown/GCD checks. Apply the native action-bar low-resource tint (0.5, 0.5, 1) to reactive and native-highlight icons; restore white on resource recovery and preview/cell reuse. Proc expiry, consumption, combat exit and disable still hide through existing public availability/highlight rules. Keep click-through and event-driven updates without new settings or polling. Substitute regression passes; native rendering/expiry/taint retest remains pending.

## Keep open chat input stable — November 7, 2026

Fix confirmed redundant font/anchor writes on chat refresh. Following the user's white-panel reload regression, use guarded keyboard focus rather than visibility: native IM input remains shown while inactive. Initialize message fonts, backgrounds, tabs and controls normally; defer only focused input font/anchors and linked bounds, and defer native restoration while focused. Hide newly created panes until painted. Replay pending work once from focus loss or hide, honoring combat and disabled-module restoration. Queue native font observations instead of changing fonts synchronously, and avoid matching font/anchor setters entirely. Preserve native typing, drafts and cursor ownership without reading text or polling. This supersedes whole-record deferral until input hide. Both the post-flight caret gap and reload appearance correction need native retesting. No release or deployment change.

## Publish the accepted fixes as 1.0.6 — November 7, 2026

User confirms automatic food is fixed and authorizes publishing the latest changes to CurseForge under a fresh version. Release 1.0.6 includes item-macro use/startup checks, native macro detection, contact scoping/recovery/categories, companion placement, keybind overlays, training-data corrections and cleanup/review work. Retain optional defaults, ownership/data safeguards and prior release tags. User food confirmation does not establish all native/taint checks.

## Automatic food correction and startup checks — November 7, 2026

User confirms manual Update recognizes Catfish while automatic use does not. Keep the existing restorative buff-food classifier and correct native macro detection using IsMacroActionWithShowTooltip, retaining guarded legacy fallback only where needed. Add the requested one-time login/reload check for created item-use macros independently of background class updates. Coalesce stock work, defer combat/editor writes and let incomplete bags complete through bounded events; no idle polling or zoning/settings-triggered startup repeats. Regression covers stale 4592→4593 food and the supplied tooltip. Offline checks pass; native automatic-use/startup/taint retest pending. Supersedes the preceding decision to omit startup checks.

## Item-use macro validation follows actual use — November 7, 2026

Always check created item-use macros once after native macro/action use, independently of the default-off class-spell update preference. No idle polling or login/bag-only supply updates. Retain carried current choices; depleted preferences fall back to suitable carried food, drink, bandages or weapon-matched coatings. Keep saved preferences for restocking. Custom-item actions clear when unavailable; pet feeding can choose another natively accepted food while retaining revive/mend. A stale/placeholder press prepares the next press. Coalesce settling events, defer combat/editor writes and bound metadata waiting; preserve ownership/external edits. This explicitly supersedes earlier opted-in background supply maintenance and absent explicit-item retention. Offline regressions pass; native input/execution/taint test pending.

## Full review and release priorities — November 7, 2026

Completed [the full source/API review](addon-review-2026-11-07.md), with all 81 Lua files assessed, current pinned 70862 Blizzard source, no remaining confirmed unused local/unreferenced named-method candidates, and 90 clean package inputs. Correct stale Paladin/Shaman training facts from current pinned MIT upstream, retain recorded prices and add the missing level-50 Lava Burst rank. Remove unused bookkeeping and update automatic contact-scope help. Offline checks pass; native verification remains separate.

Prioritize native keybind/taint, contact and window-placement checks before a fresh release version (v1.0.5 is already published). Preserve the user's deferral of older map/tracker taint investigation. Support diagnostics, checklist drag-and-drop/coalescing, manual deadline refresh, ordered talent-plan sharing and optional profession planning are recommendations for later decisions, not authorized/enabled new features. See the review for limits and evidence.

## Suite tools open beside their launcher — November 7, 2026

Use shared opening-time placement for Training Planner, Supply Checklist, Mail Deadlines, Contact Book, saved-bank browsing, Chat Copy and tool-to-Settings links (including meter settings and leveling bar context). Prefer right, left, below or above; keep windows on screen and minimize launcher overlap when space is insufficient. Retain the browser when it opens a saved bank. Resolve positions against UIParent so reopening Settings from a child cannot create circular anchors. Manual movement and standalone saved/default placement remain supported; chat Refresh preserves placement. Internal pages and established native companion layouts remain in place. No new preference or protected Blizzard panel changes. Offline checks pass; native smoke test pending.

## Recover current mail lists and control book placement — November 7, 2026

Recognize the locally observed CAMWOW US2 Realm 1 PvE server-label format, including normalized spacing, and repair previously missing contact rulesets from GUID-matched recorded inventory realms. Preserve contact metadata/removal decisions and recover recorded full names where safe. This corrects the empty-list failure introduced by filtering unrecognized server labels; retain automatic same-ruleset isolation.

Opening Contact book from Send Mail aligns it beside Mail contacts: right, left if needed, then below on narrow screens, with screen clamping. Standalone/settings openings center. No global window-layout redesign or protected Blizzard panel changes. Offline checks pass; live mailbox list and placement retest pending.

## Keep shortened keybinds out of native text — November 7, 2026

User reports MultiBarLeftButton1:SetShown blocked under Suite attribution with Short keybind labels enabled. Replace native HotKey text rewrites with separate Suite-owned labels, preserving Blizzard's original text for its later update decisions. Retain native layout/visibility, latest opacity/color/font presentation, independent font settings, range indicators and safe capability/restricted-data fallback. Create and lay out overlays only outside combat; no bar/action visibility override. Offline checks pass; the identified text-read path is a likely cause, with actual incident build, originating taint and in-game resolution still pending. No release or deployment changes.

## Choose or create contact categories — November 7, 2026

Contact book Category retains typing for a new category and adds Choose for existing categories, New category and Uncategorized. Existing choices come only from contacts in the current region/ruleset, independent of search/filter. Selection waits for Save. Keep the separate list category filter. Offline checks pass; native menu/layout check pending.

## Automatic same-ruleset mail contacts — November 7, 2026

Send Mail and Contact book show only contacts matching the current region and known server type. PvE, PvP, Hardcore and RP variants stay separate automatically, with no preference or sync switch. New contacts inherit the active server type; remove manual ruleset entry and redundant mailbox ruleset sorting/labels. Keep custom categories and notes within the scoped list. Other types remain saved for matching characters; unknown types stay hidden until identified rather than guessed. This supersedes the earlier cross-ruleset/informational-only mail decision. Offline checks pass; native smoke test pending.

## Release 1.0.5 authorized — November 6, 2026

User approves publishing the current additions as 1.0.5 because v1.0.4 is already published from an older commit. Preserve the published tag; align Core/both TOCs and release notes at 1.0.5. World-map/tracker taint investigation is deferred at the user's request after no recent recurrence; no fix or new native verification is claimed. Existing optional defaults and accepted talent workflow remain unchanged.

## Readable training Unpin button — November 6, 2026

User screenshot shows Unpin truncated to Un.... Widen training row Pin/Unpin buttons from 48 to 64 units; shift the price column right and narrow it while retaining its right edge and an eight-unit gap. Skill text remains unchanged. Native appearance retest pending.

## Four next-release companion tools — November 6, 2026

User approves all four recommendations. Implement per-character class-rank pins in Training Planner (up to 200), a searchable/paginated wishlist and estimated outstanding cost using Base/Recorded prices. Retain learned pins but exclude their costs; disclose missing prices. No weapon-trainer pinning. `/wfs wishlist` opens the class wishlist.

Tools → Supply Checklist saves up to 32 per-character item-ID/link targets with quantities, editing, confirmed removal and pagination. Independently default-off carried-item tracking uses complete bag scans only while open. Unavailable scans show unknown rather than shortages. Bank stock is excluded; metadata requests are bounded. No purchases, item use, macro edits or polling. `/wfs supplies` opens settings; `/wfs checklist` opens the editor.

Independent default-off Mail → Record mail deadlines and remind at login captures loaded count, reported total, earliest observed deadline and checked time during mailbox visits. Partial inbox coverage is explicit. Initial empty/unreadable/error data preserves prior observations; confirmed empty inbox updates clear them. `/wfs maildeadlines` reviews regional records even with recording off. Selected-character dashboard details/tooltip show summary/check time; one login reminder flags deadlines within three days or already passed. Past observations never claim mail was actually lost. No inbox refresh or mail transactions.

Suite Settings → What's New (`/wfs whatsnew`, `/wfs news`) links to these additions and recent talent/contact/macro/shortcut work. Browsing enables nothing. Native smoke tests remain pending. No version/package/deployment/junction or disk SavedVariables changes; unrelated work retained.

## Readable meter Overall selector — November 6, 2026

Widen the compact session selector from 24 to 30 units so O fits beside its dropdown arrow instead of truncating to an ellipsis. Preserve C, session choices and full-label tooltips. User confirms the fix works in game on November 6; actual build/Interface not supplied.

## Bandage macros retain native targeting — November 6, 2026

Correct FS Bandage to plain `/use item:ID` instead of forcing `[@player]`. Both strongest-carried and explicit choices leave targeting to the item/game settings. Supply updates change the item, preserving the existing owned macro/action-bar reference. Other supply recipes already omit unit targets; coatings keep their explicit hand slots, and class/pet utilities retain their described targeting. Update help and the obsolete self-bandage smoke expectation. Offline: 79 Lua 5.1 files, matching TOCs and 30,131 assertions pass, including existing-owned-body correction and supply-change targeting regressions. Actual friendly-target/cursor/self-cast behavior needs a live test.

## Common chat shortcuts — November 6, 2026

Implemented default-off Tools → Chat Shortcuts with `/kb`, `/edit`, `/binds`, `/macros`, `/cal`, `/settings`, `/addons` and `/rl` for Blizzard's binding/layout/settings and common UI tools. `/wfs shortcuts` opens the switch and reference; `/wfs commands` prints help. Preserve existing alias owners, offer namespaced fallbacks and release owned aliases on disable. `/wfs macros` still opens the Suite builder; `/wfs mac` opens Blizzard macros. Commands require out-of-combat use and never replay later. Native save/cancel controls retain ownership of binding/layout changes. Offline: 79 Lua 5.1 files, identical TOCs and 30,126 assertions pass. Live behavior, visuals and taint remain pending.

## Optional automatic enchant replacement — November 6, 2026

Add **Bags & Gear → Professions → Automatically replace existing enchants**, off by default. On an enchanter, accept only the normal own-item and trade enchant replacement prompts outside combat, after the player chooses an enchant and item. Old enchants are lost, as disclosed in help. Keep modifier Disenchant independent, other confirmations manual, and missing/failed capabilities on native confirmation. Search includes override/overwrite/replace/confirmation. Rename the Disenchant navigation entry to Professions. Pinned 70532 dialog source supports the API mapping; live 70790 compatibility, protection/taint and visuals remain pending. Offline Lua 5.1, TOCs and 29,916 substitute assertions pass; no deployment or release changes.

## Contact book away from the mailbox — November 6, 2026

Add a shared Contact book through Mail settings, `/wfs contacts` (`/wfs addressbook`), and the Send Mail helper. Use the original slate-and-teal style with a searchable, paginated list on the left and full-name/ruleset/category/notes editing on the right. Type custom categories; cycle the category filter to narrow the list. Add, rename, edit and confirm removal without a mailbox, even with mailbox features disabled. Keep existing regional scope, GUID identities, removed-contact markers and active-character exclusion from the Send Mail list. Existing records need no schema reset; automatic identity refresh preserves category/notes. Mail delivery and optional mailbox behavior remain native. Native layout/input/persistence and combat smoke tests remain pending.

## Leveling and PvP macro additions — November 6, 2026

Add three more recipes per class (27 total), with purpose-labelled help in the existing class sections. Selection follows authored Forever recommendations; native execution remains unverified.

| Class | Leveling additions | PvP / control addition |
| --- | --- | --- |
| Druid | Healing Touch; Mark of the Wild | Hibernate |
| Hunter | Hunter's Mark & pet; Raptor Strike & attack | Wing Clip |
| Mage | Arcane Intellect; Arcane Missiles | Frost Nova |
| Paladin | Blessing of Might; Holy Light | Repentance |
| Priest | Renew; Shadow Word: Pain | Psychic Scream |
| Rogue | Sinister Strike & attack; Eviscerate & attack | Gouge |
| Shaman | Lightning Bolt; Lightning Shield | Frost Shock |
| Warlock | Corruption; Drain Soul | Spell Lock |
| Warrior | Rend & attack; Hamstring & attack | Disarm |

Retain localized names and explicit ownership-safe Create / update. Hunter Mark sends the pet even if the mark fails; Sinister Strike protects Stealth in both commands. Nova/Scream stop casts, Hibernate/Gouge stop attacks, and channel guards preserve active channels. Talent/pet/form/stance restrictions stay native and are disclosed. Seven class recipes, eight for Druid; ten custom-item slots remain. Offline: 78 Lua 5.1 files, identical TOCs, 29,726 assertions pass.

## More Forever class macros — November 6, 2026

Add two researched utility recipes per class to the existing class-specific sections, alongside the exact requested Druid Prowl macro. Selection reflects recurring authored-library recommendations, not measured popularity.

| Class | Additional recipes |
| --- | --- |
| Druid | Rejuvenation; Entangling Roots |
| Hunter | Concussive Shot; Auto Shot |
| Mage | Blink; Remove Lesser Curse |
| Paladin | Flash of Light; Blessing of Protection |
| Priest | Flash Heal; Shackle Undead |
| Rogue | Sap; Vanish |
| Shaman | Healing Wave; Purge |
| Warlock | Fear; Banish |
| Warrior | Pummel; Sunder Armor & attack |

Keep localized spell lookup, explicit Create / update, General-tab ownership checks, class filtering and combat deferral. Vanish adds a trusted stopattack option; all other new recipes reuse existing generation options. Settings search includes the new names. Four recipes per class, five for Druid; ten independent item choices remain available. All 28,776 offline checks pass; native execution/layout/taint remain pending. Research links and adaptations are in sources.json.

## Custom Druid Prowl recipe — November 6, 2026

Add the requested exact three-line English Prowl/Cat Form macro as Druid · Prowl, creating FS Prowl through the existing Macros page. Keep `[noform:2] !cat form` followed by `[form:2] prowl`; use existing class filtering, preview and explicit ownership-safe creation/update. Offline checks pass; native form mapping and execution need a Druid smoke test.

## Talent planner production acceptance — November 6, 2026

User accepts the current talent planner for production after the final draft level-reference and reset additions. Treat the reported talent workflow as accepted for release. Latest offline checks: 78 Lua 5.1 files, matching 1.0.4 TOCs, 28,117 assertions. Keep unreported detailed/native coverage separate; acceptance does not claim all classes, starters or combat/taint cases were tested. No whole-Suite publication was requested.

## Build level reference and draft reset — November 6, 2026

Add a second footer line below the actual earned-point balance with the no-bonus point baseline, updated on draft edits: 31 points correspond to level 40, starting with one at level 10. Empty and above-51-point drafts have explicit messages. This does not change actual bonus-aware native budgets or imply every non-point requirement is satisfied. Add Reset draft immediately left of Limit to current level; clear only the selected editable draft's ranks/order, retain its identity/metadata and support Undo/Redo. Hide from starter/native/guide views and block combat use. All 28,117 offline checks pass; native layout/input/persistence retest pending.

## Correct empty-draft tier availability — November 6, 2026

Second user screenshot shows lower Fury rows orange at zero draft points, despite the preceding availability-color patch. Supplement per-node conditions with Forever's per-tree five-point row policy, using native display groups and row positions. Only top rows may be available in an empty draft; five/ten/fifteen points in one draft tree unlock its next rows without advancing the others. Apply the same rule to draft purchases and purchase-order validation, not only borders. Captured positive conditions, prerequisites, caps and earned budgets remain enforced. Three-tree regression reproduces the previous failure; all 28,069 offline checks pass. Actual post-fix rendering/input and build compatibility remain pending reload/retest.

## Native-like talent draft feedback — November 6, 2026

Replace orange native-removal borders with draft availability. Unspent icons stay grey; spending draft points colors the icon; orange outlines indicate an available next rank, including newly unlocked tiers. Maxed/locked nodes lose that outline; invalid allocated drafts use red warnings. Use draft prerequisites and the current-level/budget preference, independent of live spending. Keep actual talent learning and its comparison markers intact. All 28,010 offline checks pass; native visual/input retest pending.

## Fix blocked Furious Precision rank — November 6, 2026

User report identifies build 70790/Interface 16001 and Furious Precision's explicit zero-spending Available condition on a five-group node. Recognize that zero-only form as satisfied without inferring a currency group or using native isMet. Preserve real thresholds, additional requirements, restricted-data rejection and rank caps. Exact-shape regression reproduces the old failure and passes draft 1→2→3, limit OFF/ON and undo/redo after the fix. All 27,990 offline assertions pass; post-fix in-game retest remains pending. Retain `/wfs talentstatus` for other unsupported metadata.

## Move buff reminders through preview — November 6, 2026

Remove the distracting missing-buff lock and its setting. The live title/bar stay fixed and click-through; use Buff bar appearance → Preview normal bar to drag the shared normal/combat position. Preserve saved placement and reset controls, and ignore retired lock values. Offline checks pass; native retest pending. Supersedes earlier live dragging/lock behavior.

## Armor kits are not missing buffs — November 6, 2026

Exclude armor kits and unidentified enhancement-category items from weapon-coating choices and missing-buff prompts, including previously selected kits. Keep recognized oils, poisons and compatible stones available, and generic item macros independent. Fix the shared classifier instead of hiding only the reported icon. Offline regressions pass; native retest pending.

## Automatic starter level helper — November 6, 2026

Opening the starter level browser now automatically compares learned talents with the selected level: OK matches, +N missing ranks, X differences, and a LEVEL N outline marks that level's exact planned pick. Keep native ranks and Apply visible and show a comparison summary above the tree. Paging updates immediately without Learn this build. Unverified structural requirements no longer erase a safely mapped reference schedule; disclose reference-only status and block learning/customization. Missing identities/caps/choices remain hard failures. Native retest pending; the screenshot's specific unsupported requirement record is not yet diagnosed.

## Built-in class leveling plans — November 5, 2026

Implemented the approved starter library: Feral Druid, Beast Mastery Hunter, Frost Mage, Retribution Paladin, Shadow Priest, Combat Rogue, Enhancement Shaman, Affliction Warlock and Fury Warrior, researched from the attributed Icy Veins Forever calculators. Each contains 51 ordered points. Automatically offer the current class's starter separately from personal drafts, with a read-only reference-level preview, surrounding choices, next milestone, source guide, Learn this build and Customize a copy. Keep source recommendations and Suite styling distinct; these are starter paths, not best-build claims.

Resolve and structurally validate the entire path against native spell identities/caps/rules before use; incompatible client data disables the starter with an explanation. Actual learning retains native budget/level/purchase checks and manual selection/Apply. Per-character guide restoration supports starter identity; customization preserves source and respects current-level trimming on the new copy. Offline tests cover nine-class fixtures and lifecycle; native class compatibility/layout/taint still need verification. Restart required for two new files. Additional spec variants and respec-transition paths remain future work.

## Approved GUI structure implemented — 1.0.4, November 5, 2026

User approves the navigation concept. Implement eight fixed sidebar destinations, category directories listing all 29 original routes, Home/category breadcrumbs and direct Home tool shortcuts. Give Bags & Bank, Item Levels & Upgrades, Action Bars and Buff Reminders compact one-column settings with named views. Keep advanced editors and existing feature behavior; no optional module is enabled by browsing. Existing settings, route/slash compatibility, original styling and scrollbar behavior remain intact.

Buff Reminders exposes Reminders / Visibility / Appearance; location hiding now belongs to Visibility, and size/lock/previews/reset to Appearance. Buff choices/custom spells remain explicit secondary views. Action Bars separates proc/range feedback from keybind text. Search covers talent rows and individually named nested buff controls, selects their views and defers full reveals in combat. Per-view scrolling is remembered for this login only. Remaining feature pages use their established detailed forms within the new navigation shell; this is the approved pilot, not a rewrite of every editor.

Offline checks pass in the combined shared checkout: 78 Lua 5.1 files, matching 1.0.4 TOCs, 27,057 substitute assertions. Concurrent talent-starter files are preserved; the GUI adds no Lua files. Four approximate source-layout previews inspected. Actual WoW rendering, input/taint and no-search task success remain pending the new smoke test. No deployment or junction changes.

## Simpler GUI discovery — November 5, 2026

User requests a deep review of layout and navigation, especially finding features without search. Source audit and a clickable concept completed; addon redesign is proposed, not implemented. See the detailed audit and full 29-route mapping in docs/forever-development.md. Preserve existing settings, optional feature flags, records, routes, shortcut compatibility, original slate/teal styling and the user-confirmed scrollbar behavior.

Recommended first implementation: replace moving active-only navigation with a fixed sidebar and visible category directories; use specific labels (Disenchant, Window Movement, Item Levels & Upgrades, Buff Reminders); provide direct tool launchers; use one-column related controls with named secondary groups. Keep enable switches distinct from Open tool actions. Do not add a category-wide switch that changes multiple independent modules. Consolidate setting metadata so browse and search both cover nested controls, including talent settings and rested/campfire hiding. Duplicate discovery links must lead to the same setting, not create competing values.

Pilot Buff Reminders first: Reminders / Visibility / Appearance, clear out-of-combat qualifiers for location hiding, visible entry to buff choices/custom spells, and colocated size/lock/preview. Then migrate bags/gear and action bars before remaining pages. Prefer measured task success over a target category count; the concept has eight fixed destinations, versus the current seven expanding groups. No favorites, command palette, first-run redesign or broad feature refactoring is needed for the initial pass.

Next acceptance gate: run the no-search tasks in docs/testing.md against the current UI and concept, then implement and smoke-test the selected structure. The concept contains sample local values and basic rows; dedicated editors and advanced controls are not fully simulated. Do not call the proposed GUI implemented or verified from the current baseline checks.

## Pause normal buff reminders at rest — November 5, 2026

User subsequently confirms “That worked.” The requested hiding behavior has successful user feedback; detailed transition/combat coverage and actual running build/Interface remain unreported.

Implemented independent **Hide in rested areas** and **Hide near a campfire** toggles in Buff bar appearance, affecting only the out-of-combat Missing Buffs bar. Preserve existing rested settings; new campfire hiding starts off and follows the established Campfire Nearby aura, independent of the Camping bar. Resting/campfire filters never suppress enabled combat reminders, including the secondary weapon/class display. Existing event-driven updates restore normal reminders on leaving rest or losing the campfire aura. Additional speculative low-priority contexts are outside this change. Offline checks pass; native smoke test pending.

Talent badge alignment (November 5): move comparison badges five units right of native talent icons, with top edges aligned, as requested to reduce native tooltip overlap. Preserve outline layering. Native appearance retest pending.

Talent guide visual refinement (November 6): draw the yellow next-talent outline beneath +N comparison badges so overlapping corners do not obscure ranks. Implemented; native retest pending.

## Make talent learning discoverable — November 6, 2026

Rename Follow build to Learn this build, distinguish Edit draft, shorten Point order to fit, and remove the contradictory unselected status for selected live builds. Show explicit click-talent then native Apply Changes instructions above the tree, including confirmation/pause states. Manual learning remains unchanged; no automatic allocation. Implemented; native clarity and placement retest pending.

## Investigate combat tracker aura taint — November 5, 2026

Additional open regression on 1.0.3 / 70790 / Interface 16001: leveling in combat causes native scenario tracker ShouldShowMawBuffs to reject secret aura reads under Suite taint. User confirms tracker skin and collapse persistence enabled. Audit persistence's native SetCollapsed/state/layout entry point; establish causality with fresh log and a persistence-off/reload isolation trial. Preserve native aura restrictions and scenario updates; no resolution claimed or code change made.

## Investigate combat world-map taint — November 5, 2026

User confirms loaded Suite 1.0.3 on client 1.60.1 (70790), Interface 16001, with both reveal and window tools enabled; likely earlier map opening/movement. Fresh incident log still needed to distinguish the originating interaction.

Open regression: native quest-pin SetPassThroughButtons is blocked with Suite attribution when the world map toggles in combat. Capture the originating taint with a fresh game log; the supplied failure stack and older existing log do not establish the cause. Preserve native map input and combat restrictions. No implementation change or resolution claimed. See the focused capture in docs/testing.md.

## Show the whole followed build on live talents — November 6, 2026

User prefers the supplied Zygor comparison behavior. Follow build now shows original click-through +N / OK / X badges across the native tree, including future ranks and conflicts while next-step guidance is paused. Keep the next eligible gold outline, explicit pending-change pause and native manual Apply workflow. Name conflicting live/planned talents in the sidebar. Installed Zygor inspected as a behavioral reference; no code/assets copied. Offline checks pass (27,053 assertions); live appearance and coexistence remain pending. Supersedes the single-marker-only presentation.

## Leveling order and Follow build — November 5, 2026

Implemented the approved next phase: editable one-point leveling steps with legal reordering, automatic generation, Save/Cancel and Undo/Redo. Draft edits and current-level trimming reconcile the order. Follow build opens live talents with a click-through NEXT marker; the player selects and applies native talents. Pause on staged changes, allocation mismatch, inactive spec or unavailable/insufficient points rather than advancing from unconfirmed choices. Remember the followed build per character using stable IDs. WFS1 still shares allocations only; imported plans receive a generated order. Restart required for the new file. Offline checks pass; native layout, client permissions and taint remain pending. Automated spending/commit and sharing custom order remain outside this phase.

## Quest tracker persistence user confirmation — November 5, 2026

User confirms the tracker collapse persistence fix works. The reported unwanted expansion is resolved in their test; exact transition coverage and actual running build/Interface remain unreported. Broader smoke tests remain in docs/testing.md.

## Talent notes validation is Lua 5.1 compatible — November 5, 2026

Fix the user-reported malformed-pattern error when validating empty notes. Detect NUL with `%z` separately from the non-NUL control-byte class, preserving existing notes/builds and input bounds. A stricter compatibility regression reproduces the previous failure and passes after the correction. Native retest pending.

## Explain and organize talent drafts — November 5, 2026

Add all four authorized improvements: named prerequisite and remaining-tree-point explanations, client-supplied draft/next-rank descriptions where available, per-build notes/favorites, and clear ranks-added/ranks-removed comparisons. Persist rejection messages through refreshes. Sort favorites first without changing saved record identity; notes support Save/Cancel, copy independently on duplication and remain personal rather than joining WFS1 sharing codes. Guard unavailable descriptions and avoid native-rank substitutions. Preserve accepted planner behavior and layout; current combined checks pass (75 Lua files, 26,983 assertions). New native UI/data/persistence tests remain pending.

## Quest tracker collapse persistence — November 5, 2026

Implemented **Remember tracker collapse** on Quests & Loot, independently optional and default off. Save the player's latest main tracker minimize/expand click per character, retaining both states across reloads, login, loading screens and observed automatic native resets. Automatic expansions do not replace the saved choice. Uses native controls/setter, coalesced work and combat deferral; skin remains independent. Settings profiles carry the enable toggle, while character state stays outside profile snapshots. This concerns the main tracker's expanded/minimized state; individual section states and screen placement are outside this change. Offline checks pass: 75 Lua 5.1 files, identical TOCs and 26,948 assertions. Native smoke tests/build/Interface pending; no package/deployment change.

## Trim future drafts when limiting to current level — November 5, 2026

Turning the level limit ON automatically trims the selected draft to a reachable current-level build within earned points. Keep existing lower-tier choices first, remove unsupported higher-tier/future-level ranks and make the operation one undo step. OFF plus Undo restores the future plan; other saved builds remain intact. Also trim when selecting an oversized saved draft with the limit ON. Preserve data and explain unavailable metadata rather than wiping it speculatively. Implemented with passing regressions; native retest pending.

## Center draft heading text — November 5, 2026

Center each tree name and draft total together inside the accepted header box, keeping its icon at the left. Use measured text widths so different names and point totals stay centered. Implemented; native appearance retest pending.

## Center draft tree headings — November 5, 2026

Retain the accepted heading appearance; center each 300-unit box inside its 400-unit native talent section, leaving 50 units before either boundary. Replace the portrait-relative left alignment that pushed the right borders against section edges. Implemented; native retest pending.

## Clearer talent headings, sidebar and mode label — November 5, 2026

Keep accepted planner behavior. Present bright tree names with totals beside them in owned heading panels, make the right sidebar fully opaque, and rename Follow talent rules to Limit to current level in the draft and settings. Retain approved ON/OFF emphasis and orange/green fills. Both modes still enforce tree structure; ON additionally limits current level/points. Implemented with passing existing checks; new native appearance retest pending. Comparison wording and draft-rank tooltip enhancements remain separate follow-ups.

## Both talent modes enforce tree structure — November 5, 2026

User confirms talents work and clarifies the toggle: OFF plans past current level/points, while ON also enforces current character level and earned budget. Both modes must enforce tiers, prerequisites, rank caps and exclusivity. Apply the same policy to edits, history and creation/import; preserve older invalid drafts for repair. Update help/tooltips while retaining accepted button styling and remaining-point colors. Implemented with substitute regressions; native retest pending. Earlier unrestricted-free-planning decisions are superseded.

## Talent rules button colors — November 5, 2026

Keep the approved fills; emphasize only ON/OFF with uppercase, thicker white lettering and an outline. The prefix retains its existing style.

Follow talent rules uses a muted orange button background when On and green when Off, as requested. Keep the existing label, border and input feedback. Implemented; native appearance retest pending.

## Correct talent row conditions and count clipping — November 5, 2026

User reports second-row Fury blocked despite 5/5 Cruelty and four points remaining; tooltip confirms unavailable requirements. Evaluate positive native spending thresholds even without isGate, and support an ordinary minimum-level condition on multi-rank talents while preserving unknown/partial-rank safeguards. Keep group scoping, prerequisites, current budget and simultaneous level requirements. Give draft header totals independent 40x26 badges and outlined 16px white text instead of inheriting tiny native digit bounds. Substitute regressions pass; actual Fury condition records and native success remain unverified until retest.

## Weapon search matching priority — November 5, 2026

Fix bow selecting Crossbows on the current trainer page. Weapon search now prefers exact weapon names, then word prefixes, then embedded partial matches across the directory; equal matches retain trainer order. Bow selects Bows while crossbow still selects Crossbows. Class filtering is unchanged. Regression reproduced before the fix; offline checks pass and native retest is pending.

## Draft-aware tree counts, connections and talent rules — November 5, 2026

Implement the first two recommended priorities. During preview, owned overlays show draft per-tree totals over native header counts, with draft-aware prerequisite connection arrows and sidebar totals. Preserve original Blizzard labels, scripts and state; all overlays disappear on returning to live talents. Add optional Follow talent rules, default off to preserve free planning. Rules mode checks supported native prerequisite/first-rank/sufficient/exclusive connections, group-scoped spent-point gates, known level/character requirements and current earned budget. Explain rejected edits and refuse unknown requirements; support valid incremental repairs to existing invalid free/imported drafts. No game talent changes occur. Future-level exact requirements, notes/favorites and website imports remain follow-ups.

74 Lua files and 26,867 substitute assertions pass, including state/history preservation and native-view cleanup. New visuals, actual client rule coverage and taint remain pending the live checklist. This supersedes earlier notes that all tier/prerequisite checks were outside scope: supported checks are now optional, with unknown cases explicitly unavailable.

## Talent draft remaining-point counter — November 5, 2026

Display current level, full earned talent budget and remaining draft points in the draft footer. Remaining is green above zero, yellow at zero and red when negative; edits/refunds/history and level/currency updates refresh it. Use native committed class-currency unspent plus spent, not a level formula or only currently unspent live points. Keep overspending available for future-level planning; tier/prerequisite validation remains outside scope. Unavailable inputs must not invent a numeric balance. Implemented; 26,825 substitute assertions pass, native appearance/budget retest pending.

## Talent Builds launcher refinement — November 5, 2026

Replace the external text launcher with a compact gold cog near the native talent window X, at the user's circled header location. Hover says Expand talent builds or Collapse talent builds; it remains available in both states. Preserve the native X, existing popout and draft behavior. Implemented; native appearance retest pending.

## Talent Builds first iteration — November 5, 2026

Add an independently optional, default-off native talent overlay with a slate/teal right-side build library. Research across Retail, Classic/TBC, Wrath and MoP families and Forever favors native positioning, saved named builds and a separate editable preview; links/download evidence and source qualification are recorded in forever-development.md. Support empty/native-copy drafts, duplication, rename/delete, autosave, bounded undo/redo, native-rank comparisons, choices and class/tree-revision-checked Suite sharing codes. Share 30 builds per class across the account, outside settings-profile rollback. `/wfs talents` or `/wfs builds` opens it after enabling Home → Talent Builds.

This first iteration is free planning with native rank limits. Disclose that tier/prerequisite/point-budget rules are not checked. Website/native export compatibility, leveling sequence, offline cross-class catalogs and explicit application remain follow-ups, not implemented features. No actual talent spending/staging/reset occurs. Return to live talents or close the popout to use normal native input. Inspect/spec transitions invalidate stale input; combat hides owned input through a secure visibility driver and defers layout/disable work. 73 Lua files and 26,813 substitute assertions pass; native visuals/taint and actual build remain unverified. Existing release package has not been refreshed.

## Totems excluded from missing buffs — November 5, 2026

Do not automatically remind or request totems for any class. Temporary area effects no longer belong in the shared missing-buff catalog; Shaman shields and weapon imbues remain. This supersedes historical totem-reminder requirements below. Implemented with substitute checks; native retest pending.

## Final review preserves the accepted feature set — November 5, 2026

No new functional blocker identified. Remove the resolved castbarstatus diagnostic and unused proc-size cache; retain accepted chat/castbar behavior and existing optional features. Static references, Lua 5.1, 26,561 substitute assertions and 80-file archive/source integrity pass. Latest casual proc/dungeon feedback is positive, while focused verification and actual running build remain unreported. Local candidate is prepared for final smoke and subsequent release preparation; no commit/tag/upload performed. Current assessment: release-review-1.0.3.md.


## Resized castbar appearance accepted — November 5, 2026

User confirms the original-height strip is resolved in Fishing screenshots and accepts the slight apparent edge overhang. Keep the current text, spark, edge-effect and clipping-mask sizing as-is. Broader native smoke coverage remains tracked in testing; no additional castbar styling change requested.


## Cast-edge shadow/highlight and mask follow custom height — November 5, 2026

Live report is 206 x 30 with original height about 11; the three original artwork layers have zero configured sizes and native atlases. Full native XML reveals a separate 11px ChannelShadow, 12px StandardGlow/CraftGlow and shared 13px BorderMask. Resize these heights with the bar-height delta while retaining native movement, animation and widths; restore on disable/Edit Mode and defer combat. This supersedes the pending fixed-border investigation below. Source implementation and 26,565 substitute assertions pass; Fishing/Hearthstone appearance and native build confirmation remain pending.

## Diagnose remaining fixed-height castbar shading — November 5, 2026

User accepts the larger spark but identifies a remaining original-height dark strip. Compare live static Border/Background/TextBorder geometry with configured bar size through `/wfs castbarstatus` outside combat before changing another layer. Preserve the accepted text/spark fixes and native progress ownership. Diagnostic implemented with restricted-value/combat guards; visual correction remains pending live layer evidence.

## Cast-progress marker follows resized height — November 5, 2026

User accepts the improved cast text and requests the circled native progress marker grow with the thicker bar. Apply the configured bar-height delta to the native spark's captured height, preserving width, progress movement and original clearance. Restore on disable/Edit Mode and defer in combat; skip unreadable/missing spark metadata. No extra preference or polling. Substitute checks pass; native Fishing appearance retest pending.

## Resized castbar text alignment and scale — November 5, 2026

Center native spell names vertically/horizontally inside custom-sized player/target/focus castbars, with proportional 8–28px font sizing as height changes. Preserve native font family/flags, restore original font/anchors on disabling or Edit Mode, and defer changes in combat. Use existing native look/size/show refresh paths; no extra setting or updater. Implemented with substitute regressions; Fishing/native appearance retest pending.

## Copy-window footer Refresh and matching Suite style — November 5, 2026

User confirms colored copying works and requests a bottom-right Refresh button plus consistent GUI styling. Add manual same-tab refresh with shared button feedback and preserved dragged position. Match slate header/body/footer, title/status hierarchy, themed rules/viewport and native scrollbar artwork while retaining the working native edit/scroll handlers. Keep message colors and guarded snapshots; no automatic refresh or new preference. Closed/combat callbacks are inert. Native appearance/Refresh retest pending.

## Native chat colors in the copy window — November 5, 2026

User confirms the new copy workflow works and requests matching colors. Retain supplied class/item inline colors and native message/channel RGB, resetting to the channel color after colored spans and ending each line cleanly. Guard unavailable/malformed RGB and preserve the existing restricted-message omissions. No identity lookup, new preference or copy-mechanism change. Substitute tests pass; native color/paste retest pending.

## ChatCopyPaste-style copy window replaces direct selection — November 5, 2026

User changes direction: abandon direct copying from the chat window and follow the installed working ChatCopyPaste workflow. Implement an original Suite copy window for up to 500 recent readable messages, plain link labels, selected/focused text, scrolling, Ctrl+C/Ctrl+A and close/Escape. Paper button opens its own tab; /wfs copychat opens the selected tab. Skip unavailable and hidden-name messages; no identity recovery, clipboard calls, native selection mutation, persistent recording or new saved preference. Close/release snapshot on hide/combat. Retire direct selection, all copytest modes and standalone probe tooling. Prior troubleshooting entries below are historical. Substitute checks pass; Suite-native paste/visual/scroll/input tests remain pending.

## QuestieTrace uses an export EditBox, not chat selection — November 5, 2026

Installed QuestieTrace's copy UI highlights its own generated export string in an ordinary EditBox for Ctrl+C; it does not implement native chat copying. This review does not supply a direct-selection fix. User's latest plain `/wfs copytest` also failed, so the font-only comparison has no successful current baseline. Preserve the prior direct-selection preference; no copy-window implementation or further mitigation added.

## Isolate native message-font changes after lifecycle failure — November 5, 2026

User confirms the native lifecycle candidate still fails copying. Add `/wfs copytest font` as a clean-session diagnostic that only adds the configured native message-font size to plain native selection, preserving no-hook/no-widget/no-callback behavior and restoring original font/input on exit. Compare actual plain and font-only paste results within one clean session. No confirmed clipboard fix; no further speculative runtime mitigation.

## Leave native chat lifecycle scripts untouched — November 5, 2026

Suite attribution returns after QuestieTrace loader isolation instructions; the clipboard failure remains unresolved. Remove native chat OnShow/OnHide observers before intrinsic text refresh/selection reset. Queue new/reopened-window appearance through existing window/tab notifications, retaining owned paper-button hiding cleanup and saved settings. Exact native lifecycle identities and queued appearance pass substitutes; same styled-copy native retest remains pending. No confirmed fix claimed.

## QuestieTrace attribution in styled-copy failure — November 5, 2026

Copying still fails at native CopyToClipboard, now with QuestieTrace attribution. Do not equate attribution with a proven initiating cause. Read-only inspection finds item-data hooks and chat reminder output but no direct chat-copy hook. Compare `/wfs copytest styled` after disabling only QuestieTrace and reloading, with Suite styling retained and history off. Preserve Questie, installed files and saved data. No further runtime change before that comparison.

## Failed paper-button retest and styled isolation — November 5, 2026

User confirms the remaining-input-setter candidate still blocks CopyToClipboard twice on ordinary player/game chat. Add session-only `/wfs copytest styled` to retain styling while using the successful minimal selection setup without normal paper-mode ownership/result callback. Keep history off across reload, saved appearance unchanged and plain copytest's original isolation guard. Native comparison pending; no copy fix claimed.

## Successful `/wfs copytest` baseline — November 5, 2026

User confirms actual ordinary-chat clipboard capture and pastes the result after activating `/wfs copytest`. Use that successful native path as the baseline. Remove normal Chat's remaining click/hyperlink setter wrappers; check external input ownership on ordinary refresh/exit instead. Preserve appearance, history, result callbacks and native selection. Substitute checks pass; normal paper-button retest with history off across reload is pending, followed by a separate history/addon-message test. Do not call this a confirmed fix or a standalone-probe result.

## Distinguish silent and erroring chat-copy failures — November 5, 2026

Ordinary chat silently fails to reach the clipboard; addon-generated text can also produce an error, per user clarification. Capture the tested entry point before attributing this to Suite or the standalone native path. Native selection cleanup is not copy confirmation. Both symptoms remain unresolved.

## Candidate feedback and remaining chat failure — November 5, 2026

User reports the candidate looks good overall, with definite continuing chat-copy problems. Keep chat copying open; seek the current symptom and standalone probe result with Suite disabled. General feedback does not supply a running build/Interface or certify each pending feature test. No further runtime mitigation without new evidence.

## Release cleanup and review — 1.0.3, November 5, 2026

Prepare version 1.0.3 without reusing local v1.0.1/v1.0.2 tags. Remove the superseded session-only Battle Shout prototype and `/wfs bufftest`, permanently empty buff captions/preview metadata, unused alternate placement branch, duplicate inventory hover layer and redundant close callback. Retain optional features, native restoration/migration paths and diagnostics supporting unresolved issues. Consolidate release notes around final behavior. Offline checks and ZIP/source integrity pass; native chat copying, combat-buff dungeon behavior, proc reliability and recent UI changes still require the smoke tests in docs/testing.md. See [release review](release-review-1.0.3.md). Historical prototype instructions below are superseded.

## GUI button hover and press feedback — November 5, 2026

Extend consistent feedback to Training Planner tabs, Costs, Previous/Next, All levels/By level and Settings, plus custom controls throughout settings, setup, profiles, gear/buff configuration, journal, character/inventory browsers, mail and meter menus. Use theme-colored native hover and pressed textures; preserve selected backgrounds, labels, tooltips and callbacks. Training pagination dims when disabled. Native button state management adds no timers, polling or Lua mouse handlers. Native visual/input checks pending.

## Consistent GUI dismiss controls — November 5, 2026

Use one compact, font-independent cross for settings/Training Planner close and search-clear controls, inventory results dismissal, damage detail closure and saved mail recipient removal. Borderless at rest, with a tinted hover surface, accent cross, pressed feedback and action tooltip. Removal uses warm coral feedback and retains its confirmation and disabled-current-character behavior. Preserve existing click targets, layout, search handling and combat guards. Native-style bank portrait controls and the equipment manager's semantic Ignore/Include toggle retain their existing visual systems. Native appearance/input retest pending.

## Integrated search clear X — November 5, 2026

Remove the search clear X's background and border so it sits directly inside the search bar in Class and Weapons. Preserve the existing click target and clear behavior. User approves the previous placeholder correction; this visual refinement needs native retest.

## Training search placeholder correction — November 5, 2026

Correct reported placeholder/input overlap: hide the hint on focus and any nonempty raw input, updating cosmetic visibility even while combat pauses navigation. Restore only when empty and unfocused; refresh preserves that rule. Substitute regressions pass; native input retest pending.

## Training Planner centered text and quick clear — November 5, 2026

Center planner button text vertically as well as horizontally, including header/footer/close controls. Center search hint/input and provide an inset right-side X in both Class and Weapons. Clear restores full Class results and retains Weapons navigation; reserve text space for X. Combat clicks are ignored. Offline checks pass; native appearance/input retest pending.

## Always-passive live proc popups — November 5, 2026

Make click-through a fixed behavior, not a preference. Only the outside-combat placement preview accepts mouse dragging; live root, icons, labels, glow and empty space pass input through. Wheel input stays passive in both contexts. Enforce this during every paint, including before combat preview cleanup. Implemented with substitute coverage; native input smoke test pending.

## Proc popup size slider — November 5, 2026

Add the requested adjustable icon size under Combat → Action Bars: 24–128 px, default 42. Adjusting opens a live preview without enabling procs, while the sparkle border, labels and centered spacing follow the chosen size. Preserve saved position and animation progress. Save with settings profiles, support wheel nudges and settings search, and defer external changes/reject slider input during combat. Implemented with substitute checks; native appearance, persistence and combat verification pending.

## Dungeon combat-buff forbidden title anchors — November 5, 2026

Fix the reported CombatBuffs:Place ClearAllPoints failure by establishing native title-mask anchors during initialization, before button descendants become forbidden. Reuse unchanged layouts and rebuild affected records for public slot/size changes; exclude failed native groups before final layout. Preserve native missing/expiry masking without inspecting restricted state. A stricter native-access fixture reproduces the previous failure; offline checks pass. Dungeon, layout/tooltip and taint retests remain pending.

## Training Planner Class search — November 5, 2026

The same header search is now visible in Class as Search spells. Typing filters to matching spell ranks; each result shows its level requirement and original full-list page. All levels and By level retain pagination through matches. Empty results are explicit; clearing restores the full list, and tab changes clear query/focus. Weapon search behavior is preserved. Supersedes weapon-only visibility below. Offline checks pass; native rendering/input verification pending.

## Equipment toggle selected-set visibility correction — November 5, 2026

User reports the enabled button missing. Correct its draw level above the native character model/equipment layers, retaining the lower-right anchor. Per clarification, show it only for an existing selected set; no selection and the unselected New Set editor hide it completely. This supersedes initial new-set-editor support below. Offline regressions pass; native visibility and saved-set behavior require retest.

## Training Planner compact controls and weapon search — November 5, 2026

Implemented compact Class/Weapons tabs with centered labels, a compact Costs button fitting its Recorded label, and a weapon search box filling the rest of that row. Typing a partial weapon name such as `axe` jumps to the first matching faction trainer page and reveals the matching row, including recorded visits. Search preserves full trainer context; clearing or no match leaves the page in place, with amber text for no match. Class hides weapon search. Offline checks pass; native layout/input smoke test pending.

## Equipment manager bulk ignore/include — November 5, 2026

Implemented independent default-off **Equipment set slot toggle** in Bags & Gear → Gear Details. A small button at the lower-right of the native character equipment area toggles slots 1–15 plus tabard between Ignore and Include, preserving main hand, offhand, ranged and ammo exactly. Mixed state goes to all ignored first; next click includes all eligible slots. Works with a selected set or new-set editor, updates native slot markers and enables Save without automatically saving/equipping. Combat clicks are rejected. Offline checks pass; native placement, set persistence and taint smoke test pending.

## Consistent reactive availability refresh — November 5, 2026

User reports intermittent Overpower after the prior correction and asks for comparison with successful addons. Add finite event follow-ups and public cooldown-end wakeups, informed by primary proc-addon research, while retaining independent Suite implementation and server-confirmed availability. Refresh from combat activity, action usability, spell uses and player power/casts without reconstructing dodge windows. Sample public GCD classification only during its cooldown event; retain native highlight candidates through delayed query readiness. Add bounded `/wfs procstatus` observations for any remaining live miss. Substitute regressions pass; native consistency remains unverified and prior live failure is not closed.

## Overpower native failure follow-up — November 5, 2026

User reports missing Overpower after a dodge and confirms the enemy dodged their attack while they were in Battle Stance with at least 5 rage. Correct the reactive readiness gate to honor public inactive cooldown status before requiring potentially restricted numeric durations, while rejecting disabled/on-hold cooldowns. Covered with substitute regressions. Native root cause and successful Overpower detection remain unconfirmed; retest after reload is pending. Do not report class coverage as verified.

## Animated proc borders — November 5, 2026

Add the requested sparkly animation to active ability popup borders, also visible in Preview proc popups. Use built-in Blizzard proc artwork with the native animation engine, independently of WeakAuras and native action-button management. Hidden icons stop animating; repeated availability refreshes retain loop progress. Plain icons remain if the atlas is unavailable. Implemented with substitute checks; native appearance and combat verification pending.

## Unrestricted settings window dragging — November 5, 2026

Let the Suite GUI slide beyond screen edges so it can be moved away from preview boxes. Preserve saved partial-screen placement and automatic scale fitting. Add the requested right-click on the Suite minimap icon to center and open settings, with combat deferral and tooltip help. Recover an inaccessible header by centering on reopening; Escape then `/wfs` remains another recovery route. Implemented; native drag, reset and preview smoke test pending.

## Ability proc popups — November 5, 2026

Implement the requested combat ability reminders as an independent default-off switch in Combat → Action Bars. Passive teal-bordered spell icons and names support native class proc highlights, supplemented by readable availability for learned Overpower, Revenge, Riposte, Mongoose Bite and Counterattack ranks. Show up to eight distinct names; hide on consumption/expiry or combat exit. Separate draggable preview/reset saves position without altering the missing-buff bar. Class procs lacking native highlights need explicit future support; do not claim universal aura/proc detection. Event-driven implementation and substitute tests complete; native dodge-to-Overpower, other-class coverage, appearance and taint checks pending.

## Standalone native clipboard reproduction — November 5, 2026

Minimal-addon `/wfs copytest` still reports Suite-attributed failure. Other third-party addons are not required, but other Suite code remains loaded. Prepare a separately packaged two-file native probe outside release inputs so user can test with Suite completely disabled. Matching installed-build 70790 source is now available at eac30af597e5aaa43a60f6675ef5fdcea100375f; scrolling implementation is unchanged from prior cache. No client-level diagnosis or direct-copy fix confirmed; standalone native result pending.

## Minimal direct-copy failure with changing attribution — November 5, 2026

User's next error names QuestieTrace at the same native clipboard call. This does not establish its causal responsibility or a Suite fix. No direct chat-selection hook found in read-only installed QuestieTrace review. Next isolate `/wfs copytest` with only Suite and optional error reporters enabled, styling/history off across reload. Result pending; no new runtime change.

## Continue direct selection; minimal native copy diagnostic — November 5, 2026

User rejects a Ctrl+C window and requests continued direct-selection investigation. Font-hook mitigation still fails; highlight cleanup is not clipboard confirmation. Paper mode now exits after confirmed native copying. Add temporary `/wfs copytest`, available only after disabling styling/history and reloading, to enable native selection without Suite Chat hooks/callbacks/UI. Repeat or reload restores normal input. Offline checks pass; isolated native result and direct-copy fix remain unresolved.

## History-independent clipboard failure; font-hook mitigation — November 5, 2026

Native copying still fails after disabling history and reloading. Leave the native message-frame SetFont/SetFontObject methods unwrapped as a further mitigation candidate; observe font resets at ordinary refresh/restore and retain original font restoration. Input/tab observers remain. Offline checks pass; causal diagnosis and native clipboard resolution remain unverified.

## Clipboard trace attributes failure to Suite — November 5, 2026

Captured native taint log places ChatFrame1:IsSelectingText immediately before the Suite-attributed CopyToClipboard block. Initiating mutation/module is not shown. Preserve trace in ignored cache and isolate history off across reload while retaining Suite styling/copy input. No additional runtime fix or native success is claimed; isolation pending.

## Chat clipboard retest still blocked — November 5, 2026

User confirms clean reload, Suite paper button and fresh text beneath the session boundary. Normal Suite copying still fails after the mitigation; native taint trace remains needed.

Follow-up report reaches the same native CopyToClipboard call with `*** ForceTaint_Strong ***` attribution. Previous mitigation is not a confirmed fix. Clean-reload procedure, selected text origin and initiating taint remain unknown; gather native reproduction/taint evidence before further implementation changes.

## Normalize recovery tooltip formatting — November 5, 2026

Strip inline hexadecimal/named color codes and normalize text wrapping before automatic food/drink/potion restoration classification. Cover the user's Brilliant Smallfish buff-food wording without a name-based exception. Preserve current tier ranking, explicit choices, language and safety guards. Implemented with substitute regressions; native empty-macro report still requires retest.

## Chat clipboard taint mitigation candidate — November 5, 2026

Follow up the reported native CopyToClipboard blocked action by leaving secure copy-setting entry points unwrapped. Move ownership-change detection to ordinary UI refresh/exit, preserving direct selection, callback restoration and input behavior. Implemented with substitute coverage; the cause and native fix remain unverified until reload/copy testing. No new setting or saved data.

## Separate centered combat weapon row — November 5, 2026

User approves replacing the shared combat aura/weapon row with independently centered rows. Native aura placement ignores weapon capacity; ordinary weapon/fallback icons appear below the prepared native rows, centered by current readable entry count. Preserve shared title axis, saved placement, size/scale and independent UIParent anchors. With only Battle Shout, a hidden sharpening-stone reminder can no longer shift it sideways. Multiple healthy native families can still leave native gaps. Implemented with substitute regressions; native retest pending. Supersedes earlier shared-row decisions below.

## Remaining combat centering diagnosis — November 5, 2026

User's follow-up screenshot still fails centering after impossible-coating-slot removal. Add prepared aura/fallback slot names to `/wfs buffstatus` to identify the live layout without restricted visibility reads. No further layout offset adjustment; live diagnostic output pending. Full visible-icon combat centering remains outstanding.

## Exclude impossible combat coating slots — November 5, 2026

Reserve combat coating space only for selected carried items. Unavailable supplies and outside-combat alternative-selection prompts cannot appear in combat and must not push native icons off-center. Implemented with substitute regressions; native screenshot retest pending. This fixes one source of empty space; automatic compaction of healthy native reminders remains outstanding.

## Food macro includes buff food — November 5, 2026

Include health-restoring buff food in automatic FS Food selection. Keep mage/conjured, seasonal and ordinary tiers and existing restoration/level/quality ranking within each tier; specific buff foods remain available through Choose item. Buff-only items without health restoration are not automatic recovery food. FS Drink retains its buff exclusion. This supersedes earlier food-macro buff exclusions below. Implemented with substitute checks; native execution retest pending.

## Buff title center correction — November 5, 2026

Follow-up screenshots: user accepts outside-combat alignment and confirms combat remains off-center. Visible combat-icon centering remains outstanding; the title-axis correction did not satisfy that requirement.

Align title text directly to the shared row center in normal, previews, native combat and weapon fallback; retain the passive lock to the side. Implemented with substitute checks. Always centering only visible combat icons remains unresolved: native healthy slots are reserved and their restricted visibility must not be queried to compact the row. Native visual verification pending.

## Match combat weapon reminders to the shared bar — November 4, 2026

Remove the leftover BUFF REMINDERS box and MH/OH/Missing/Soon labels from the ordinary combat fallback. Reserve public precombat slots alongside native aura icons, with identical icon dimensions, saved root placement, passive floating title and below-icon tooltips. Keep independent UIParent anchors and native masking safeguards. This supersedes the earlier separate-below-native weapon row. Substitute checks pass; native visual/taint verification pending.

## Unified missing-buff icons and floating title — November 4, 2026

Combine self/party recipients of the same spell in one tooltip and icon, advancing the actionable target as recipients are covered. Remove all captions beneath icons. Restore small floating Missing Buffs words without an outer panel; unlocked normal title supports movement, locked title/empty space pass input through. Combat title uses the native missing/expiry masks and stays hidden when healthy; combat hover is confined to icons. This supersedes the icon-only/title removal and earlier group/hand-label decisions below. Implemented with substitute coverage; native smoke tests pending.

## Icon-only live buff reminders — November 4, 2026

Remove the normal live bar's outer panel/title and Self captions in both contexts, preserving icon coordinates, sizing and actions. Keep group/hand information and tooltip names. Move the shared bar through the normal settings preview header; live empty space stays click-through in either lock state. This supersedes the live header/lock artwork request below. Implemented with substitute checks; native appearance/input retest pending.

## Buff lock placement, click-through and subtle icon — November 4, 2026

Preserve the user's dragged position when locking at custom scale by applying the inverse scale conversion during placement. Keep MISSING BUFFS wording/width stable and show a passive superscript open/closed lock mark. Locked header and empty border pass mouse input through; buff icons retain their actions. Apply the same lock behavior to the normal preview. Implemented with a failing-before scaled placement regression; native placement/input/artwork retest pending.

## Buff size/scale sliders and paired previews — November 4, 2026

User wants larger icons and adjustment without fighting. Add shared 24–64 px icon-size and 70–150% scale sliders in Buff bar appearance. Provide mutually exclusive normal/combat previews outside combat, using the real icon dimensions/style and shared saved placement. Keep previews non-actionable, stop them on close/navigation/combat, and defer native aura reconstruction during slider drags. Existing preferences/defaults remain. Implemented with substitute checks; native appearance/input/scroll and combat application pending.

## Native buff visibility-handler correction — November 4, 2026

Fix the user-reported blocked OnHide assignment during aura button batch creation. Native descendants retain their secret visibility without visibility scripts; the ordinary Suite family cell owns context-hide tooltip cleanup. Preserve native masking and hover behavior. Implemented with an inherited-secret-aspect regression; live retest pending.

## Secret-safe item widget discovery — November 4, 2026

Fix the user-reported ScanVisible secret-boolean error on a native aura button. Check item-specific capabilities before visibility and guard access/visibility predicates across discovery, refresh and hook/container entry points. Leave restricted widgets alone while continuing to find ordinary item buttons. Implemented with a failing-before regression; native scan/overlay retest pending.

## Independent combat reminder anchors — November 4, 2026

Fix the user-reported UntrustedLayoutScriptExecution SetPoint rejection. Position the ordinary weapon-reminder panel below native aura slots through shared public saved-position/layout arithmetic, with each frame independently anchored to UIParent. Preserve native masking restrictions and layout spacing. Regression reproduced before the correction; native reload/scale retest pending.

## Damage meter reload restoration — November 4, 2026

Reapply enabled meter layouts on world entry using saved positions and current screen geometry, without requiring Test both windows. Reuse existing combat deferral and retain visibility, lock and docking preferences. Implemented with a failing-before/passing-after startup geometry regression; native reload/relog confirmation remains pending.

## Matching combat buff placement and compact tooltips — November 4, 2026

User requests similar icon position/size between normal and combat bars, with subtle tooltips underneath. Share the existing normal bar dimensions, header spacing, centered rows and icon insets/crop. Match full-color artwork and Self/Group scope labels while retaining invisible healthy slots. Center the tooltip below each icon and fit its backdrop to known text rather than the native masking plane. Implemented with layout regression coverage; native visual/hover/expiry checks pending.

## Armor in every starter gear profile — November 4, 2026

User's Loose Chain Boots (62 armor, item level 9) versus equipped Recruit's Boots (2 armor, item level 1) exposed armor being unweighted by all built-ins except Tank. Count armor across all classes: Balanced, Physical, Caster and Healer assign 0.01 points per armor; Tank retains 0.02. Automatic inherits its class starter. Preserve saved custom models, native equip/level eligibility and the existing green preferred/yellow other-usable armor hints. Armor type alone does not force an upgrade. Implemented with regression coverage; native boot-marker/tooltip retest pending.

## Shared missing/expiring combat buffs — November 4, 2026

User approved the working native Battle Shout display and requested broader coverage with healthy buffs hidden. Extend the regular combat reminder area to learned class/custom buffs on self and eligible party/raid members, honoring scope/relevance/party-only choices. One visible slot per family; tooltip lists affected names through native display masking, without exposing combat presence to Lua. No persistent active icon or empty backdrop. Optional expiry warnings use native formatting; known long buffs use the configured interval, short/unknown buffs 15 seconds. Guarded poison/imbue/coating checks remain separate from aura filtering. Implemented with substitute coverage; native shared/tooltip/expiry/performance checks remain pending. The /wfs bufftest card remains an explicit diagnostic only and is not required for normal reminders.

## Innkeeper gossip service choice — November 4, 2026

November 7 follow-up: user confirms correct selection but reports Shift bypass failure. Strengthen the conversation-wide bypass with physical left/right Shift checks independent of binding state and event-latched Shift presses between queued stages. Preserve missing-capability fallback, conservative restricted-state handling, new-visit reset and manual confirmation. Regression coverage passes offline; native retest and actual running build/Interface remain pending. Blizzard's independent sole-option selection is unchanged.

User requests a service-aware gossip shortcut. Informational chat does not count toward the service count. Shopping plus home-binding (or any second non-chat service) waits for player choice; either supported service alone can advance under its applicable preference. AutoVendor stays shop-only; autoGossip covers the sole binder prompt as well, retaining manual confirmation. Implemented locally with regression coverage; native retest pending.

## Saved Training Planner grouping — November 4, 2026

Persist the existing By level / All levels toggle in character training data. Restore either choice on initialization; older and fresh records retain the all-levels default. Reopening, automatic opening and switching Class/Weapons must preserve the choice. Grouping, costs and manual purchases retain their existing behavior. Implemented locally; native persistence smoke test pending.

## Battle Shout native display experiment — November 4, 2026

User requested a working trial. Add `/wfs bufftest` as an explicit session-only experiment with no saved preference: native player helpful-aura rendering overlays a red CHECK fallback with an ACTIVE icon/timer. Preserve the normal bar, defer setup/stop through combat, and disable native processing on stop. No polling or hidden-state inspection. Implemented and substitute-tested; live widget support/rendering and frame-time behavior remain unverified. Gate any permanent bar integration on the focused native smoke test.

## Native combat buff presentation research — November 4, 2026

Other Forever addons demonstrate native aura rendering layered with reminder art, so Lua need not identify secret buff presence. Investigate an original Suite-owned passive display configured outside combat; verify current-client native APIs and learned-rank coverage first. This is a potential improvement over the current permission-gated panel, not implemented or verified. Avoid icon/visibility polling, cached-state inference and third-party code copying. See the combat display research in forever-development.md for primary references and limits.

## Quest timer fill overlap — November 4, 2026

Keep the tracker fill below the native All Objectives header rather than relying on frame order to render beneath timers. Retain the NineSlice content bottom, native timer layout/input and existing outline. Implemented locally; regression and existing checks pass, with native retest pending. Recorded as Unreleased after v1.0.1.

## Battle Shout combat limitation — November 4, 2026

User's combat checks report both shout auras secret. Preserve the clickable bar's combat hiding and per-spell checks on the independent passive panel; missing-shout detection remains available outside combat. No workaround based on hidden or cached aura state. An unconditional combat reminder is a separate possible behavior, not currently requested or implemented.

## ForeverWoWBiS drawer compatibility — November 4, 2026

Collect the confirmed `ForeverWoWBiSMinimapButton` despite its private icon texture. Use a narrow exact-name compatibility entry instead of accepting arbitrary iconless minimap controls. Keep the original button, native click/tooltip behavior, safety guards and disable restoration. Implemented locally with a failing-before/passing-after regression; native smoke test remains pending.

## Square minimap dimensions — 1.0.1, October 31, 2026

Extend the existing default-off Square minimap option to make the actual map width and height equal by expanding the shorter side. Use the Retail attachment only for shape; add no icons, artwork or controls. Keep native placement and Edit Mode scale, reuse the current coalesced layout worker and restore the latest native dimensions when disabled. Protected resizing waits through combat. Version 1.0.1 prepares this change locally; the earlier publishing-workflow correction remains separate and uncommitted. See the new minimap smoke test for native validation still required.

## GitHub release publishing — October 29, 2026

Correct the packager's GitHub token mapping and fail the tagged workflow if the expected public release assets are missing. Preserve successful CurseForge upload behavior and default non-publishing manual runs. Existing v1.0.0 reached GitHub and CurseForge upload acceptance; public availability is separate. See [publishing](publishing.md).

## Pre-release code cleanup — October 28, 2026

Complete a behavior-preserving cleanup in the canonical C: checkout: remove unused layout/profile/widget state, callback arguments and duplicate buff/chat bookkeeping. Keep all features, migrations, compatibility checks and version 1.0.0. Preserve earlier uncommitted feature changes. No deployment or junction changes. See [the cleanup review](cleanup-review-2026-10-28.md) for scope and validation.

## Primary development location — October 25, 2026

The user selected `C:\Games\Development\GitHub Repos\WoW Forever Suite` as the primary checkout for all future development and testing, superseding the earlier P: requirement. Standalone Lua 5.5 tools remain available at `P:\lua-5.5.0_Win64_bin`; preserve Lua 5.1 compatibility validation. Older P: references below describe historical work. No feature behavior or deployment changes are part of this update.

## Macro status colors — October 23, 2026

Make blocked/failed macro saves and combat/data-loading pauses red so the reason for an unchanged macro is visible. Track write outcomes separately from status wording; confirmed current/saved outcomes use Suite teal and ordinary recipe guidance stays muted. Reapply the color on every refresh to clear previous errors when a save succeeds or another recipe is selected. Food picker changes clear the previous outcome. Preserve all existing save/ownership behavior.

Canonical P: source and local 1.0.0 package only. Substitute checks cover red external-edit/editor/combat failures and clearing red on a successful GUI save. Native visual check remains pending: reload, provoke an editor-open or external-edit block, confirm readable red text, then complete Update and verify teal; switch recipes and confirm normal guidance is muted. Record actual build/Interface. Evidence: .cache/macro-status-color-20261023.


## Explicit macro Update replaces owned edits — October 23, 2026

Reviewed the user's 35-second recording (2026-10-23 10-22-07.mp4). At approximately 10 seconds, the visible status reads: Edited in Blizzard's Macros window. Automatic changes are paused for this macro. User reports manually replacing the macro text in Blizzard's editor works. The external-edit guard, rather than the previously suspected preview overlap, explains why repeated explicit Update clicks do not save the generated preview. This recording does not establish which original edit caused the ownership mismatch.

Separate deliberate Create/Update from existing-only picker saves and background work. Explicit Update may replace edited text only when the unique General macro has a prior Suite ownership record; a same-name unowned macro remains protected. Only confirmed native readback updates ownership. Background updates, item selection, class availability, combat, duplicate names, editor-open checks, metadata/body limits and failed-write protections remain. Clarify the paused status with Click Update macro to replace it with the preview. The existing button's preview is the text the user chooses to apply; no additional confirmation is needed.

A regression first failed against the old guard. All 67 Lua files and 23,405 substitute checks now pass, including the visible GUI Update of edited pet text to the exact food-name preview, continued picker/background protection, visible saved status, class recipe replacement and ownership/editor/combat boundaries. Source/package changes stay exclusively in P:/GitHub Repos/WoW Forever Suite. The user manages the game junction. Rebuild and verify the local 1.0.0 package; native validation of the corrected button remains pending. Evidence: .cache/macro-video-20261023.

In-game smoke: load this P: source and reload; close Blizzard's macro editor; select Pet care and click Update. Confirm Saved in General macros, then reopen FS Pet Care to inspect the exact /use food-name line. Test feeding a living pet outside combat and record consumption/cursor/error and actual build/Interface. Repeat after a manual edit: background changes must pause, explicit Update must apply the preview, and open editor/combat/unowned or ambiguous names must still block writing. The user's manually edited feeding workaround is reported working; it does not certify the revised Suite save path.


## Macro action input correction — October 23, 2026

User reports Update macro produces no visible response while the saved FS Pet Care retains its old item-ID body. Source layout reveals the 240px multiline preview extends below its 93px scroll viewport across both action rows. Raise Create/Update and the automatic-update toggle above the preview's input frame, preserving selection/copy/scroll and all existing ownership, editor, combat and readback safeguards. No macro is executed by clicking these controls.

Substitute regression models the overlapping frames' input priority for both controls and checks that GUI saving displays its result. Native hit testing and pet feeding remain unverified. In game: reload this P: source, close Blizzard's macro editor, click Update, and record the status above the preview. Reopen FS Pet Care and confirm the exact food-name /use line; then test feeding a living pet outside combat, including raw fish in the reagent bag. Record actual build/Interface and any error or ownership-block status. Evidence: .cache/macro-button-input-20261023.


## Feed Pet item targeting correction — October 23, 2026

User screenshot after the earlier save fix still shows the Feed Pet cursor waiting for a bag item. The prior change fixed selected-versus-saved text but did not establish live feeding success. Generate the chosen item's validated exact localized name on a plain /use line, rather than item:ID with an explicit pet unit target. Precede it with /stopmacro [combat][nopet][@pet,dead], preserving combat, absent/dead-pet guards while leaving the final use command to satisfy the item-targeting cursor. Revive and Mend branches stay unchanged. No bag-slot macro, direct protected API call, automatic feed, insecure execution or alternate food selection is added. Reagent bag remains included in carried discovery.

Resolve names from guarded carried metadata, or guarded cached C_Item.GetItemInfo for a depleted choice. Missing/restricted or unsafe names pause generation and preserve existing text; validate byte limit after constructing the localized body. Item IDs remain saved choices. Deliberate picker changes still update only existing confirmed owned macros even with automatic updates off; editor, external edit, missing macro and combat protections remain.

Native exact-build SecureTemplates.lua and earlier cached SlashCommands.lua show /use passes its parsed target to item use; they do not expose the engine internals that failed here. A publisher's Forever release notes independently report changing Feed Pet to exact item names; no third-party implementation was read or copied. The name/target correction is a source-informed compatibility fix and still needs the user's live retest.

All 67 Lua files and 23,357 substitute checks pass. New command-contract tests check plain food-name use and combat/dead/absent stop guards; existing reagent-bag and explicit-choice regressions remain. They do not prove the native item cursor resolves. Version stays 1.0.0; only P: source/local package changes. Load that source, /reload, pick food again or click Update macro. Verify the saved FS Pet Care ends with the stopmacro guard and /use followed by the exact food name, then press outside combat with a living pet. Record consumption, cursor disappearance, errors and actual build/Interface. Recheck raw fish in reagent versus ordinary bags, Revive/Mend, depletion, localization and user edits. Earlier full-feed success remains unverified. Evidence: .cache/pet-targeting-20261023.


## Pet food selection refresh — October 23, 2026

User reports newly chosen Raw Bristle Whisker Catfish in the reagent bag would not feed. Reproduced a separate selection/write gap: with macroUpdates off, the picker changed the chosen item and preview without rewriting the existing General macro. Deliberate pet-food changes now call the existing Save path in existing-only mode. Preserve default-off automatic updates, class/combat/editor guards, confirmed ownership and externally edited text. Missing macros are not recreated; first-time choices explicitly ask the user to Create. No item/spell use or native macro execution is added.

The carried-item scan already includes reagent bag 5 and ingredients without use spells. New substitutes exercise raw fish there, combined carried counts, immediate saved-text refresh with automatic updates off, missing macros and custom edits. They do not prove native Feed Pet targeting or establish a reagent-bag engine bug. The generated pet-care commands remain unchanged. Exact-build SecureTemplates.lua is cached as reference only; no protected calls are invoked directly.

All 67 Lua 5.1 files and 23,352 substitute checks pass; TOCs remain identical and version stays 1.0.0. Only the canonical P: checkout and its local package are updated; the user manages the game junction. After loading this source, /reload, choose the fish again, confirm the saved FS Pet Care item ID matches the preview, and test a living summoned pet outside combat. Repeat raw fish in reagent bag versus ordinary bag, combat Mend, dead/absent pet, editor-open/custom-edited/missing macro safeguards and reload persistence. Record actual build/Interface, feeding cursor/error and consumption before calling the live feeding issue verified. Evidence: .cache/pet-food-20261023.


## Canonical completeness review — October 23, 2026

Reviewed recorded feature history, available project-chat latest turns, Git/module/test integration and source packaging. No additional missing runtime implementation found: 67 loaded Lua modules, all 58 registered test files, 28 settings pages and 23,342 passing assertions. Corrected the README omissions for the newest features and the stale ZIP checksum sidecar. Saved app project still opens outside P: and needs its folder corrected in the app; actual edits remain P:-only. Native smoke results remain pending. See [the completeness report](completeness-review-2026-10-23.md) and .cache/completeness-audit-20261023.

## Food/water and combat indicator in canonical 1.0.0 — October 23, 2026

Bring both requested changes into P:/GitHub Repos/WoW Forever Suite, preserving the accepted newer 1.0.0 source and profiles. Automatic recovery ranks mage, known event, then regular supplies; Hallow's End percentage candy works for both food and water despite subclass 8. Preserve explicit choices, level/no-buff/metadata guards and existing update/ownership/combat rules.

Add the original Suite Combat Indicator with four-second gold entry and green exit messages, optional full-fight visibility, lock, movable placement, preview/reset, searchable settings and a default-off setup choice. All new toggles start off. Use one event/display frame and cancellable timers, with combat-safe owned presentation and deferred layout/input.

Earlier changes missed P:; this correction updates only the canonical checkout and its local 1.0.0 package. Leave the user-managed game junction alone. All 67 Lua files and 23,342 substitute assertions pass, covering all 28 settings pages; TOCs are identical. Before-files, source provenance and package hashes are in .cache/canonical-food-combat-20261023. Native transition/consumption/input/persistence/taint tests remain pending.

## Initial launch release baseline - 1.0.0, October 22, 2026

The user reports that everything appears to be working and designates the current build as the expected initial release for the user-provided November 4, 2026 launch target. Promote accepted 0.2.104 to planned 1.0.0 in canonical P:/GitHub Repos/WoW Forever Suite. Only Core/TOC version metadata changes in addon code. Preserve all features, defaults, SavedVariables schemas/history and prior pending source changes. Build and retain the matching local package and SHA256 file manifest. Do not publish, push a release tag, schedule publication, deploy or change the game junction as part of this preparation.

General user acceptance is recorded as broad working feedback, not an exhaustive feature/build/taint certification. Existing focused in-game checklists remain applicable. Confirm the launch client build/Interface and matching catalog/API behavior before actual publication; no future client compatibility is inferred from the earlier 70532 executable or build-70450 source references.

See [the planned release notes](release-1.0.0.md). Validation/package hashes are recorded under .cache/launch-100.


## Equipped upgrade markers - 0.2.104, October 22, 2026

User screenshot shows a green plus on an equipped weapon because the scorer can compare it with the other compatible slot. Add a dynamic equipped-origin flag from the existing guarded ItemLocation equipmentSlotIndex in Items:Resolve/Update. Equipped buttons clear and skip upgrade markers while retaining item-level labels. The flag is recomputed each update, so recycled buttons and moved items recover correctly. Bag origins explicitly remain candidates. Do not suppress by item ID or identical hyperlink: a separate bag copy may legitimately improve the other ring/trinket/weapon slot. Scoring weights, preferred-armor colors, complete-hand comparisons, tooltip comparisons and all other behavior remain unchanged.

Canonical source only: P:/GitHub Repos/WoW Forever Suite. Core and identical TOCs advance to 0.2.104. No deployment, junction or SavedVariables changes. 66 Lua 5.1 files parse and 23,006 behavior checks pass. New regressions exercise rings/trinkets/one-handed weapons in Stats and Item level modes, existing plus clearing, retained item levels, reused bag buttons and restricted location fields. No new native API, event, hook or timer. Native rendering/input/combat/persistence remain pending.


## Readable journal and default training catalog - 0.2.103, October 22, 2026

Canonical P:/GitHub Repos/WoW Forever Suite advances from 0.2.102 to 0.2.103. The user screenshot shows 0.2.102 with the old compact journal. Earlier changes went into alternate C: copies and had not reached P:. This reconciliation preserves all existing uncommitted work, including known-vendor highlights, chat, profiles, setup and quest changes. No game folder, junction, other addon or SavedVariables is changed; user manages the game junction.

The original Suite journal now has six labeled statistic cards and Summary/Loot/Reputation/Levels/History under Current/Previous/Overall. Enabled future tracking collects guarded self loot/value estimates, ordinary reputation changes, deaths/last death, cross-session level milestones and Suite-confirmed sales/personal/guild repairs through existing Leveling/Vendor work. No independent idle worker or game action. Keep all prior XP/gold/time and permanent history; missing new detail stays Not recorded. Do not import EverCore SavedVariables or invent earlier details.

The bundled default catalog supplies 1,409 class/pet training ranks across nine classes through level 60 without a trainer visit or recording. All levels uses six-row paging; By level groups requirements/levels/known skills. Base and Recorded costs remain distinct. Visits supplement unseen catalog ranks/master offerings, with unknown server-only base costs left unknown. Show prior-skill, talent, poison and pet requirements; filter faction/race; account for replaced lower ranks and reject unknown/restricted availability claims. Weapons retain full faction master references, locations, eligibility and known markers. Recording starts off; purchases remain manual.

Bring earlier gear-editor button spacing and unused-helper/local fixes into P:. Full canonical tests exposed an ordering issue in the old duplicate-dispatch cleanup: schedule combat reminders once after preview cancellation, preserving visible native reminders. Add a one-dispatch regression check. Other event ordering is preserved.

Baseline: 63 Lua files / 17,326 checks. Reconciled: 66 Lua files / 22,963 checks; 22,964 with --journey-preview. All 27 settings pages remain covered. Approximate sample-data previews come from canonical source and Summary/Training were inspected. Screenshot establishes Suite 0.2.102 only; running build/Interface remain unreported, with earlier executable observation 1.60.1.70532. Live rendering/input, persistence, exact server catalog and combat/taint remain pending. Restart after loading 0.2.103 for the three new Lua TOC entries. Backups/models/manifest: .cache/reconcile-02103.


## Known vendor items - 0.2.102

Bring ZoidsTools Retail's known/collected vendor recognition into original Suite controls. Add default-off Vendor > Known Items > Highlight already-known vendor items, searchable by green/owned/recipe/pet and optional in setup. Mark positively learned recipes/known collectible tooltips and pets with at least one readable owned copy using a green row/icon wash plus checkmark. Ordinary bag possession is not collection. Missing/restricted information remains unmarked; no native purchase, sale, repair or collection state changes.

Reuse a bounded set of passive owned row widgets and a single cancellable event-driven refresh. Native absolute row indices/page/tab checks prevent stock reuse and Buyback mislabeling. Learning, metadata and pet-journal updates refresh a shown shop. No idle polling or combat ownership queries; first construction/layout and protected cleanup defer. Leave all native row input/art/tooltips intact and keep this choice independent of automation and shared border color.

Canonical source is P:/GitHub Repos/WoW Forever Suite; version 0.2.102 with identical TOCs. All 63 Lua files and 17,326 checks pass. Earlier build-70450 source is qualified against executable 70532; legacy optional pet query availability/permissions and live visual/persistence/taint results remain pending. No deployment/junction change.

## Canonical reconciliation - 0.2.101, October 21, 2026

All updates from this chat now belong to P:/GitHub Repos/WoW Forever Suite. Merge the leveling session journal, expanded first-use setup, preferred-armor upgrade colors and fixed quest-tracker background into the newer 0.2.100 source, releasing local metadata as 0.2.101. Preserve newer chat styling, vendor auto-talk, profiles, custom scoring, the removed quest-guidance state and all other canonical features. Retain code, tests, source provenance and smoke instructions in this checkout. No deployment or game-junction change is part of this reconciliation.

The default-off Leveling tracker records every future captured session per character, with Current/Previous/Overall and permanent six-row paging. Show dates, level endpoints, time, XP, net gold, rates and honest partial markers. Reload continues Current; login/restart/disable archive exactly once without offline changes. History remains readable with collection off. The five-step setup now scrolls all 73 supported choices and opens after first world entry; seen/completed markers and staged/profile behavior survive. Preferred armor changes only hint color/explanation, following the disclosed class/level rules. Fixed-layer tracker background keeps native text/controls/timers visible while retaining native ownership and combat deferral.

Full canonical checks pass: 62 Lua files, identical TOCs and 17,249 assertions. Client 70532 actual runtime build/Interface, native appearance, persistence and combat/taint remain pending. User manages the game junction. This source supersedes the older alternate-workspace delivery for future development.

## Brighter typing border - 0.2.100

The user confirms the preceding channel-color behavior works nicely and clarifies the desired refinement as brighter. Increase only input-border opacity to 130% of the message-border formula: (0.4 + chatOpacity * 0.2) * 1.3, a 30% increase from 0.2.99 (bounded to 0.52-0.78 by the existing opacity normalization). Preserve native channel RGB, the 90% minimum dark fill, visible three-unit gap, aligned edges and all existing input/theme/combat/restoration behavior. No new API, hook, timer, setting or saved field. Actual running build/Interface are not supplied; the new brightness needs in-game review.

This supersedes the 0.2.99 plan to use exactly the message panel's border opacity. All other channel-color choices and behavior remain current.

Validation: 62 Lua 5.1 files, identical 0.2.100 TOCs and 16,021 substitute checks pass. The existing opacity checks now require the brighter input border; native RGB, gap, fill, input and combat regressions still pass. Package dist/WoWForeverSuite-0.2.100.zip contains 70 source-identical addon files, SHA256 1ca882e5750313e2e2c664619dd76cbd9a18f42784296dd2f9e76a138e0daadc. Revised native brightness remains pending; no deployment or junction change.

## Channel-colored typing border - 0.2.99

Match the typing-box border opacity to the message panel, while retaining its dark fill and visible three-unit gap. Use the native active typing color: Say white, Guild green, whispers purple, plus native Party/Raid/Yell/Battle.net/numbered-channel colors and user-customized chat colors. Each input follows its own native display state. Preserve native text, commands, recipients, header, sending, scripts and geometry; no new setting or saved field.

The input's channel tint survives shared class/custom border-theme changes; unreadable/unavailable native RGB falls back to that selected theme. Changes in combat defer through the existing worker and use the final native color afterward. Disable hides the owned pane and leaves retained hooks inert. All 62 Lua 5.1 files, identical 0.2.99 TOCs and 16,021 substitute checks pass. Canonical P: source only; no deployment/junction change. Native rendering, channel switching and combat/taint still need the focused smoke test.

Delivery: dist/WoWForeverSuite-0.2.99.zip contains 70 source-identical addon files, SHA256 61ff97042793d85225f88752a7e41143147c565fda13c6f5804599727c5e2ea1. No deployment or game-junction change; native checks remain pending.

## Darker chat typing box - 0.2.98

Give the existing Suite typing box a 90% minimum slate fill, rising to full opacity if the saved chat opacity is higher. Keep message/tab transparency under the existing setting and use the current shared input border color. Preserve the visible three-unit gap, matching edges, native typing height and behavior. Clarify the existing opacity helper text; no additional control or saved preference. Restore Blizzard chat removes the Suite input pane as before. Canonical P: source only; no deployment or junction change. In-game contrast, gap and input validation remain pending.

Offline validation: **62 Lua 5.1 files, identical 0.2.98 TOCs and 15,927 substitute checks pass**. Existing chat alignment/input/restoration/combat checks pass. Package dist/WoWForeverSuite-0.2.98.zip contains 70 source-identical addon files, SHA256 9f5b1cc2a2f6285d78b8bd6540f2ee0f4baeb47b828f46584104b2e476037350. The existing game junction exposes this source; no deployment or junction change. Native appearance/input/taint remain pending.

## Remove standalone quest guidance — 0.2.97

The user rejects the new quest guidance experiment and will use Questie. Remove all 0.2.95/0.2.96 standalone map/nameplate/location-recording modules, the data catalog, updater/localtools, GUI page/actions, search entries, command aliases and their dedicated tests. No new Questie dependency or integration is added. Earlier quest pickup/turn-in/gossip, tracker styling, nearby quest-item tools and 0.2.94 vendor auto-talk remain.

Retire the five experimental saved fields through Suite.InitializeDB; existing profile whitelists discard their obsolete settings and overrides. Do not edit installed SavedVariables, other addons or the game junction. Preserve development provenance as historical only. Canonical P: checkout, matching Core/TOCs 0.2.97. **62 Lua 5.1 files and 15,927 substitute checks pass**, including retired-data migration and retained preferences. Native reload/coexistence checks remain pending.

## Vendor shop conversation — 0.2.94

Add **Everyday → Vendor → Vendor Conversation → Automatically open vendor shops**, reachable through /wfs vendor or search for auto talk. The default-off preference follows the active shared/personal settings profile. After enabled ready quest turn-ins/pickup, select a unique available shop option even when quests, other services or a forced menu are present. General Automatically advance gossip keeps its previous single-option/no-quest rules.

Identify the shop from its base icon resolved through the native vendor texture path, using a stable option ID. Localized names and decorative override icons never determine the choice. Unknown/restricted data, multiple shops, locked/unavailable entries and native confirmation/code prompts remain manual. Hold Shift while opening or before execution to pause the current conversation. Reuse the bounded, cancellable quest worker and clear its visit when the merchant closes. Shop opening does not enable repairs, sales or quest settings.

Canonical P: checkout only: port the focused changes onto 0.2.93, preserving later quest-data readiness, Training Planner, chat, theme and profiles. Core and both identical TOCs are 0.2.94. Before-file snapshots and three exact 70450 references are retained under .cache/vendor-talk-0294. No further installed-addon or game-junction changes. All **62 Lua 5.1 files and 15,907 substitute checks pass**; native opening, icon lookup, persistence and taint remain pending.

## Shared border color — 0.2.93

October 19: implement profile-aware **Interface → Appearance** with **Default teal**, **My class**, **Custom**, and Blizzard's native color wheel. Include current swatch/hex preview, live border updates and Cancel restoring prior mode/custom RGB. `/wfs colors`, `/wfs appearance` and settings search reach these controls. Class mode follows each character, with teal fallback when unavailable. Switching modes remembers custom RGB; changing color enables no optional feature.

Route all Suite-styled backdrop, flat-texture and native-art borders through Theme.lua, including settings, minimap/header/stats/drawer/launcher ring, native bar/buff skins, quest tracker, chat, Suite windows/buttons/controls/popups. Keep each border's alpha/hover behavior. Informational fills, text, tab background accents and logo artwork retain their meanings. Existing and later-created borders inherit the choice. Recolor coalesces until combat ends; supported combat texture hover uses the previously applied RGB. No layout, native input, asset replacement or idle worker is added.

Installed executable is **1.60.1.70450**. Seven exact API/picker references are cached from matching commit 172a387e3ab85b26e6640d3058d5ec1e6ccd4c63. **62 Lua 5.1 files, identical TOCs and 15,822 substitute checks pass**. Native visuals, wheel input, persistence and taint remain pending the focused smoke test.


## Class training icons and colors — 0.2.92

October 19: user accepts the prior weapon presentation and requests class ability icons plus more distinct text, particularly levels matching the teal weapon trainer names. Capture each readable native trainer offering's exact icon and show it in the existing 30-unit icon area. Use the same 36-unit text inset in both tabs, preserving the fixed 500×528 window, footer and price column. Class names become soft gold; group headings and required-level numbers teal; availability green and other requirements or projected confirmation amber. Projected saved levels remain explicitly unconfirmed.

Save an optional validated icon with each offering. Older lists first try the readable native spell-name texture lookup, then use a question mark if unresolved; a class-trainer visit with recording enabled refreshes exact icons. Matching public metadata events can refresh visible unresolved names through the existing cancellable coalescer. No guesses about learned spells, automatic purchases, new preference, shipped artwork or worker. All 14,416 substitute checks pass; native appearance remains pending.

## Consistent headers for every weapon master — 0.2.91

October 19: user supplies saved Bixi Wobblebonk and Buliwyf Stonehand pages with the old context/details/duplicate-name header, and requests the Woo Ping design for every trainer, including Horde. The previous compact condition covered reference pages only. Extend it to all usable Weapons pages, whether recorded, current or reference, for both factions. Keep Class and unavailable-faction explanations separate.

Use teal trainer - gold city, then a muted district - building subtitle without repeating the city. Hide the former saved/current context row and recorded-price explanation. Match known master name plus faction to existing directory location details, covering all eight masters, so both Ironforge visits show Military Ward - Timberline Arms. Unknown or mismatched identities use their actual recorded location; do not rewrite snapshots. Keep captured stock/prices separate from references, and label historical totals Saved total. Preserve the common 500×528 root, fixed footer, icons and combat deferral. All 14,401 checks pass, including all sixteen recorded/reference master combinations. Native appearance remains pending.

## Consistent Training Planner size — 0.2.90

October 19: user supplies Class and Weapons screenshots and reports that the same window has two sizes. The 0.2.89 reference-only height reduction caused this. Use one fixed **500×528** owned root for all views. Keep the compact color-coded reference header and raised weapon rows, while totals, page controls and Settings stay in the same footer positions across views. This supersedes the 0.2.89 decision to shorten the reference window.

Remove mode-specific root resizing and footer offsets; keep existing header/row combat deferral, class/weapon data, icons and saved placement. All 14,344 substitute checks pass. The screenshots show native weapon icons and the color-coded header in use, but the corrected fixed-size result still needs an in-game check.

## Compact weapon reference header — 0.2.89

October 19: user requests clearer color and less header space, then clarifies that the city must appear only in the main heading. Reference pages use a larger **Woo Ping - Stormwind** heading: teal trainer, muted separator and gold city. The smaller muted second line is **Trade District - Weller's Arsenal**, without repeating Stormwind. Apply the same city/district/building arrangement across the capital directory. Hide the separate Reference/faction/trainer row and remove the header's base-price explanation. Keep the footer's reference-price qualification and existing per-row labels.

Move reference rows/footer up 36 units and reduce only the reference window height from 528 to 492. Class, recorded and current-visit headers retain their details and original geometry. Reuse existing owned labels and source place strings; no setting, saved data, asset or new game API. Geometry changes defer through combat and restore when switching views. All 14,344 substitute checks pass; native appearance remains pending.

## Training Planner weapon icons — 0.2.88

October 19: user supplies the Alliance/Woo Ping Weapons page and requests each weapon's default icon to the left of its name, explaining that the uniformly white text is hard to scan. Add 30-unit native proficiency icons in a 36-unit gutter on weapon rows, mute secondary requirements, retain the existing six-row spacing and right-aligned costs. Apply the same presentation to reference and recorded visits. Class rows retain their full text area and clear recycled weapon art.

Use public catalog proficiency IDs for reference entries and exact readable client-localized names for recorded rows. Resolve icons with capability-checked C_Spell.GetSpellTexture; unavailable/restricted data uses a question mark for a known proficiency. Request missing public data at most once per catalog ID per Lua session; coalesce successful completion events, defer through combat and cancel work on hide. No new preference, asset, training record field or purchase behavior. All 14,344 substitute checks pass; actual native appearance remains pending.

## Training Planner GUI and spellbook companion — 0.2.87

October 19: user requests GUI discovery beyond /wfs training and automatic opening with the spellbook. Give the planner a dedicated **Home → Training Planner** destination with Open first, recording and all three automatic-opening choices. Move existing controls out of Professions without changing their saved keys; index both pages for search and route the planner Settings button to its own page. Opening settings does not enable recording.

Add trainingSpellbook=true as a subordinate automatic-opening preference, like existing trainer/level choices; the independent trainingPlanner master remains false on a fresh setup. When enabled, show the saved Class / Available now view beside the actual visible spellbook. Do not open for the Talents tab alone, read live trainer offers, learn spells or alter native scripts/layout. Use the exact 70450 public spellbook Show/Hide callbacks rather than a function replacement or idle polling.

Closing the spellbook hides only its automatically opened companion. Keep manually opened views and selections independent; dismissal lasts for that opening. Native trainer visits take over their existing lifecycle. Defer construction/show/placement in combat; closing the book, disabling either relevant choice, world entry or a later manual opening invalidates pending automatic work. Preserve standalone coordinates and existing class/weapon records. Offline checks pass; native visual/event/taint testing remains pending.

## Persistent chat history — 0.2.86

October 19: user requests seeing chat after reload/login, referencing their ZoidsTools retail and EverCore experience. Review ZoidsTools/Modules/ChatHistory.lua as the behavior reference; no history implementation was found in the current EverCore checkout. Implement a small independent Suite module, optional and off by default like other tools. A single enable action uses fixed useful bounds; no editing or tuning is required.

Remember the latest 250 readable rendered main-chat messages, maximum 4096 bytes each, in character SavedVariables. Keep the preference in settings profiles, and records outside profile copies. Retain native filtering and exclude other tabs/combat log/temporary windows. Backfill older messages in reverse insertion order before current-login messages; preserve hyperlink markup, mute embedded colors, and show a session boundary. Replay once per Lua session, including across repeated world transitions and option applies. Clear saved records independently of live chat. No chat sends, clipboard extraction, native message getters or history-buffer inspection.

Offline: 61 Lua files and 14,116 substitute checks pass; TOCs identical at 0.2.86. Native persistence, display, links and taint checks remain pending.

## Clicked group buff requests — 0.2.85

October 19: user reports clicking Arcane Intellect did not announce the missing buff. This authorizes deliberate incoming-icon chat requests, replacing the reminder-only left-click behavior from 0.2.84. No automatic announcements or live messages are sent by development tools.

Left-button release on a gold incoming icon requests the current missing buff in instance chat, home raid or home party, in that order. Use a bounded native localized spell name: “Could I get Arcane Intellect, please?”; a due expiry asks for a refresh. Right-click still hides the family. Casting own spells, browsing, timers and aura updates do not send requests. No new setting or editing is required.

Recheck enabled/context state, readable native chat permission, group channel and live incoming-family/provider/absence before sending. Keep 30 seconds per family and 3 seconds globally, including rejected send attempts. Native rejection/unavailability produces local feedback without retries, whispers, public-channel or alternate-API fallback. Native API success has no documented delivery result. Combat remains blocked; no protected cast attributes are added.

## Class-aware buff reminders and controls — 0.2.84

October 19: user requests recommendation #8 and reports missing Arcane Intellect never appeared on a Hunter grouped with a Mage. Previous routing deliberately sent incoming families only to local chat; a positive-only spell-level predicate also rejected legal zero values, and resting suppressed the whole ordinary bar. These are identified suppression paths; no native trace establishes which affected the reported encounter.

Make incoming buffs persist as gold **Group** icons, with provider names and a reminder-only tooltip. Keep secure left-click attributes empty; right-click hides the family. Preserve existing local notice throttling and never send a party message. Unknown aura/identity/spell information stays quiet; a group class/level indicates a possible provider, not proof of its learned spellbook.

Use automatic class-aware recipients: Intellect and Mana recovery include Hunter, Druid, Mage, Priest, Warlock, Paladin and Shaman regardless of temporary form/power. Physical-only choices target broadly physical-capable classes; universal buffs retain broad coverage. Filter equivalence by relevant roots so Wisdom on a Rogue or Might on a Mage cannot hide a useful missing blessing. Automatic outgoing alternatives choose actual learned spells per recipient; explicit choices stay explicit. A relevant alternative satisfies a family, rather than demanding conflicting blessings/totems. Hybrid defaults are broad, not role-optimal assignments. Optional Class-aware targets off restores all-class targeting.

Update Forever baseline coverage: Divine Spirit at 30 and Fear Ward at 20; resistance auras may cover other raid subgroups while ordinary Paladin auras remain party-scoped. Keep unknown talent abilities un-inferred and do not implement the announced but explicitly not-yet-live Salvation change. Retain native learned/range/reagent and click-time checks.

Add a three-tab inline manager: **Bar appearance**, **Buff list**, **Custom spells**. Search localized learned names/icons, page results, add up to eight self/group custom families, manage existing built-ins instead of duplicating them, and prevent duplicate ranks. Search all/hidden/my-class family views, restore a single hidden family and choose learned alternatives without a right-click guessing cycle. Preserve existing custom IDs and hidden choices.

Default bar scale 100%, icons 34, movement unlocked, class-aware targeting on. Show enabled reminders in rested areas by default to avoid an invisible in-town state; this can be paused. Expose scale/icon-size cycles, a header movement lock, position preview and appearance reset. Master feature remains off by default; existing independent self/outgoing/incoming/upkeep/expiry/combat/coating choices are preserved. New preferences participate in settings profiles without manual editing or a new SavedVariables declaration.

Combat continues to hide the ordinary secure bar, including incoming icons. Optional passive combat reminders retain their separate predicates and cannot read hidden information. No automatic casting, messages, item actions, third-party code or idle polling. Native class/raid coverage, casting, rendering, persistence and taint checks remain pending.

## Standalone Profiles navigation — 0.2.83

October 19: user requests Profiles as a standalone sidebar section. Move the existing page from Home into a sixth primary workspace, before Setup Guide. A single-page workspace uses its primary button directly; do not build or expand a duplicate child. Keep all 25 page routes, profile storage/behavior and /wfs profiles. No new API, feature enablement, layout migration or profile switch.

## Settings and layout profiles — 0.2.82

Implement recommendation #3. Existing choices migrate automatically to a shared **Default** profile; no setup, editing or feature enablement is required. Add Home → Profiles and /wfs profiles, with an active profile/scope caption on every page. Preserve the approved wider workspace and cursor-driven scrollbars.

Provide up to twelve named profiles including Default, explicit rename and confirmed removal of unused profiles, current-setup copies, and paged copy-from-character selection. Character sources are their last saved effective settings after this update, independent of inventory recording. New copies do not activate automatically. Default, the active profile and profiles assigned to recorded characters cannot be removed.

Shared settings save to the named profile. Optional personal scope stores differences per character and per named profile, inheriting untouched top-level settings; a changed nested layout/choice table is overridden as a unit. Returning to shared settings preserves the private overrides for reuse. It does not publish private choices to the shared profile. Switching profiles or scope requires a review and an explicit UI reload, with automatic saving of the outgoing setup. Review discloses all changed settings and newly enabled optional features; long reviews expand within the existing scroll system. Block mutations/reloads in combat and while a switch awaits reload; never queue a switch for later combat completion.

Include Suite feature switches, appearance, reminder choices, supported native-window positions/sizes and Suite-owned meter/bar positions. Preserve separately: inventory/character/bank records, saved searches, contacts, item protection blacklist, macro ownership/recipes, character gear weights and preferences, training records, leveling session/position/lock, guide completion and native restoration markers. Native Edit Mode layouts, keybindings, arbitrary CVars and third-party layouts are outside scope.

Use bounded, readable-only snapshots with finite numeric values and cycle/depth/entry guards. Validate names, IDs, duplicate names, missing assignments and Default recovery. Keep all current SavedVariables declarations; character assignment/overrides survive the macro-owned character-root reconstruction. Save direct setting/layout edits on logout, before copying/switching and when refreshing the profile page. No import/export, automatic role switching or idle worker is added. Native reload/layout/persistence and taint checks remain pending.

## Upgrade tooltip glyphs — 0.2.81

User screenshot shows missing-character boxes exactly where equipped/candidate arrows are emitted. Replace the owned comparison arrow with ASCII -> in both label and values, and replace the full-breakdown multiplication sign with ASCII x. Preserve supported middle-dot separators, localized item/profile names and scoring behavior. No blanket Unicode filtering or font changes.

## Classic class macro recipes — 0.2.80

User approves the redesigned GUI and requests one or two commonly used Classic macros per class, researched on the internet rather than invented to fill slots. Review authored Classic guides and firsthand macro examples; select two for each remaining class and retain Hunter's existing pair.

| Class | Recipes |
| --- | --- |
| Druid | Innervate; Rebirth |
| Mage | Counterspell; Polymorph |
| Paladin | Hammer of Justice; Blessing of Freedom |
| Priest | Power Word: Shield; Dispel Magic |
| Rogue | Kick; Blind |
| Shaman | Earth Shock; Chain Heal |
| Warlock | Pet recall; Drain Life |
| Warrior | Heroic Strike & attack; Taunt |
| Hunter | Existing Misdirection and Pet care retained |

Adapt the patterns into compact templates with explicit living/dead and friendly/hostile targeting, localized C_Spell names and native rank selection. Preserve exact Hunter behavior. New spell/static utilities generate before bag-data checks and never require an item override. No name/rank/equipment configuration is needed; no automatic casting, target changes, messages, rotation logic or stance/form changes are added.

Reuse explicit creation, current-class visibility, account-wide confirmed ownership, foreign/manual-conflict protection and combat deferral. Retain inactive-class records. Keep the GUI at five shared + two current-class + ten item rows and three headings, rather than allocating every class's widgets. Add recipe names to settings-search keywords.

**57 Lua 5.1 files, identical 0.2.80 TOCs and 13,517 substitute checks pass** (574 above 0.2.79). Native spell availability, secure macro execution/targeting, localization, persistence and taint remain pending in-game tests.

## Workspace redesign — 0.2.79

User confirms 0.2.78 scrollbars feel exactly right, then requests an overall professional layout review: less crowding, fewer categories and a wider rectangle that shows more content. Preserve the gesture controller and existing feature behavior.

Implement 1120×760 with automatic shrink-to-fit using UIParent dimensions and 48 units of screen allowance. Do not enlarge beyond native design scale. Coalesce screen-fit geometry during combat and react to display/UI-scale changes and opening. No manual size setting is required.

Use five primary workspaces (Home, Bags & Gear, Combat, Interface, Everyday), showing only the active workspace's child pages in the sidebar. Setup Guide is a separate bottom utility. Keep all 24 route keys, search targets, feature flags, character records and shortcuts. Move bars/buttons into Interface and keep Macros in Everyday. Replace duplicate Home switches with six navigation cards; dedicated settings retain the switches.

Remove top page tabs to provide a 500-unit content viewport, previously 368 on most pages. Related settings form paired 400-unit cards with 16-unit gutters, matched heights, measured titles/descriptions and full-width odd rows. Sections remain collapsible and search-revealable. Widen character/inventory tables and macro/setup panes to 780; three-column gear profiles/weights reduce the editor from 730 to 586 units. Center the remaining compact forms at a readable width.

**57 Lua 5.1 files, identical 0.2.79 TOCs and 12,943 substitute checks pass** (2,077 above 0.2.78). Native fonts, scale fitting, input layering, persistence and taint remain pending the redesigned-layout smoke test.

## Scrollbar gesture control — 0.2.78

User supplies a 27-second recording of 0.2.77: Action Bars/Other Bars show large thumbs jumping between positions during cursor gestures; Gear Details is reported improved. Preserve the corrected top-to-bottom content direction, but replace the raw Slider thumb gesture entirely. The video establishes visible jumping, not its precise engine-internal cause.

Use one shared Frame track and owned Button thumb for the main viewport, macro list, macro preview and setup review. Store initial cursor position and content offset on press; map cursor delta in effective-scale UI units across height minus thumb height. Preserve the grab point at either edge or center. Track clicks page 90% of the viewport; wheel remains 40 units. Keep proportional thumb size and hide nonoverflowing tracks.

Track only during a held gesture and cancel on release, hide, page/range/size change, invalid cursor or combat. Combat defers thumb anchor/size changes; wheel can move content and deferred geometry catches up afterward. No idle worker, persistence schema or native UI modification is added.

**57 Lua 5.1 files, identical 0.2.78 TOCs and 10,866 substitute checks pass** (net 300 assertions above 0.2.77 after replacing the slider-value fixtures). Native cursor capture, track input, rendering and taint still require an in-game retest.

## GUI scrollbar consistency — 0.2.77

User supplies Gear Details screenshot: content is at the bottom while thumb is at the top, and dragging down returns content to the top. Audit all Suite-owned GUI scrolling: the main viewport, macro recipe list, macro preview and setup review share one factory. Horizontal numeric sliders are separate controls.

Remove the erroneous 0.2.66 inversion. Map zero to top and one to bottom consistently in both directions, retaining proportional thumb sizing, 40-unit wheel steps, finite/readable guards, hidden zero-range bars and combat-deferred geometry. Explicitly update nested offsets on range shrink instead of relying on a native follow-up callback. Preserve content positions during same-page refresh and nested scrolling; page changes still begin at top.

**57 Lua 5.1 files, identical 0.2.77 TOCs and 10,566 substitute checks pass** (359 additional assertions over 0.2.76). Corrected native drag/track behavior, rendering and taint remain pending an in-game retest.

## Character inventory workspace — 0.2.76

Implement recommendation #2 as Characters/Inventory tabs within the existing Characters page. Default browsing immediately shows same-region saved items without configuring a query. Preserve independently optional recording switches and all existing records; viewing does not enable recording. Owner/location filters and eight account-wide saved views are optional refinements.

Unify inventory counts and snapshot access through the existing index and bank renderer. Count shared stock once; retain the saved owner when opening an alt's slot layout. Display per-source capture ages, known-empty versus unknown locations, partial-record warnings and pending item metadata. No live scan, bank transaction or cross-region fallback is introduced. Native comparison tooltips still concern the logged-in character, with that limit disclosed.

Use paged slate/teal item rows, scoped empty states, lazy owned widgets, visibility-bound events, coalesced cancellable refreshes and finite 32-ID metadata batches. Ordinary wheel scrolls the page; Shift-wheel pages results. Combat defers presentation and cancellation prevents hidden work from reopening.

**57 Lua 5.1 files, identical 0.2.76 TOCs and 10,207 substitute checks pass** (121 above the 0.2.75 baseline). Native rendering, persistence, API behavior and combat/taint safety remain pending.

## Character upgrade profiles and explained scores — 0.2.75

Implement the user's selected gear-comparison upgrade with editing entirely optional. New characters get Automatic/Stats; existing characters keep their previous role and comparison mode on first migration. Automatic selects a conservative class leveling starter, with Hunter ranged-DPS versus Rogue/Warrior melee-DPS handling. Five immutable role presets remain ready to use. Class starters do not infer talents, combat roles or definitive best gear.

Add eight character-local custom profiles, an explicit chooser, optional draft-based weight editor, Save/Cancel, guarded deletion and Summary/Full breakdown tooltip choices. Keep built-in weights independent, reject unusable custom inputs, preserve stable IDs and restore Automatic if an active custom profile is unavailable or removed. No new feature enablement is required beyond the existing independently optional Possible upgrades. Add /wfs gear and /wfs items.

Explain each positive hint using the exact icon-scoring model: equipped/candidate totals, largest signed stat changes in Summary, all weighted changes/multipliers in Full breakdown, actual paired-accessory replacement and complete hand-set accounting. Empty-slot hints do not invent numerical gains. State unmodeled effects and preserve strict unknown/restricted-data handling. Picker/editor construction is lazy; no idle worker or native equipment action is added.

**56 Lua 5.1 files, identical 0.2.75 TOCs and 10,086 substitute checks pass**. Native preset usefulness, tooltip/GUI layout, persistence, API data and combat/taint await the focused checklist. Canonical P-drive changes only; the game junction is unchanged.

## Faction-specific weapon trainers — 0.2.74

Restrict the Weapons tab to the current character's faction. Alliance sees its four capital-city reference masters; Horde sees its four. Apply the same rule to captured visits and their actual prices. Preserve all stored history, but hide old unidentified records until revisited. A known old master name can establish its faction. Unknown/restricted player faction produces an empty explanation rather than mixed recommendations. Automatically opened visits use the filtered page index. Class recording and level-up reminders remain separate.

**55 Lua 5.1 files, identical 0.2.74 TOCs and 9,947 substitute checks pass**. Native faction delivery, both characters' rendered lists, persistence, trainer stock/prices and combat/taint remain pending the focused test.


## Separate class and weapon training — 0.2.73

Level-up reminders must show only the class record; weapon visits must never replace it. Store typed class and weapon histories separately. Exclude pet/profession contexts, distinguish General trainer offers with client-localized proficiency names, and keep incomplete/mixed data from replacing class history. Quarantine old untyped snapshots; the user must revisit a class trainer once because earlier overwritten data cannot be reconstructed. Preserve existing trainer docking and independent recording/auto-open preferences.

User selects the full Weapons directory. Add Class/Weapons tabs to the owned planner, listing eight capital-city weapon masters with named locations, stock and clearly labeled reference base prices. Keep actual visit prices separately recorded; no class eligibility or live availability is inferred from the reference. Automatic Wands/Unarmed/Defense and class-trainer Dual Wield are explained. Beta prices/stock need native confirmation.

**55 Lua 5.1 files, matching 0.2.73 TOCs and 9,922 substitute checks pass**. Native localized classifier behavior, directory accuracy, UI fit, persistence and combat/taint remain pending the focused test.

## Quest timer backdrop order — 0.2.72

Keep Blizzard's quest timer above the Suite tracker skin by lowering only the Suite fill onto a mouse-disabled BACKGROUND layer. Preserve the existing fill opacity/bounds and teal outline. Keep native timer ownership, layout, countdown, clicks and scripts, and all existing tracker collapse/disable/combat behavior. Source review shows the fill's higher frame strata can cover the timer; no native timer modification is needed.

**54 Lua 5.1 files, matching 0.2.72 TOCs and 9,884 substitute checks pass**. The new frame-order regression fails before the change. Actual timer readability, input, countdown/completion and taint remain pending the focused in-game test.

## Bag skin icon bounds — 0.2.71

Correct the user's enabled/native comparison by fitting the Suite bag skin's background and teal outline to each native icon instead of the entire button. Keep the native button size/hit area, icon/mask/tint, counts, highlights and clicks. Replacement icon regions retarget existing artwork; unreadable, restricted or unlaid-out icons retain native chrome until usable. Preserve one-physical-pixel borders and existing combat deferral. This replaces the earlier full-button bag plate choice; no new preference or native geometry change.

**54 Lua 5.1 files, identical 0.2.71 TOCs and 9,876 substitute checks pass**. The new representative inset-icon regression fails the previous implementation. Actual corrected appearance, native input, restoration and taint remain pending the focused test.

## Training Planner window layers — 0.2.70

Fix the October 18 screenshot's mixed layering between the Training Planner and Suite settings. Give both owned roots native top-level focus and explicitly raise the whole window when opened or reopened, including the planner Settings button. Use an opaque planner background. Keep trainer docking, standalone movement and saved positions as documented; level changes remain behind the existing combat deferral. No new option, worker or native-window mutation.

**54 Lua 5.1 files, matching 0.2.70 TOCs and 9,834 substitute checks pass**. The new overlap model fails before the fix and passes afterward. Actual window focus, overlapping visuals, docking and combat/taint remain pending the focused native test.

## Quest pickup waits for loaded data — 0.2.69

October 18: user reports roughly one failed pickup in five, requiring leaving and returning to an NPC, and asks to compare Retail ZoidsTools. Read its QuestAutomation.lua and MIT license without changing that repository. ZoidsTools requests C_QuestLog.RequestLoadQuestByID on QUEST_DETAIL and accepts from QUEST_DATA_LOAD_RESULT; Suite previously submitted on the next frame with once-per-visit deduplication. There is no comparable data-ready wait in the prior Suite implementation. Early submission is a plausible cause, not a confirmed native diagnosis.

Use the same event-driven readiness principle in the original Suite stage/visit controller. Request each valid visible offer's data once; accept only after matching readable success, through the existing next-frame worker and all current NPC/quest/panel/option/Shift/combat checks. A failed/rejected load does not spin on metadata updates; a newly opened detail event may retry that load. Clients without the loading API retain capability-checked native acceptance. Reward/gossip policies, confirmations, repeatable deduplication and the twenty-action cap stay as documented. Native full-log/server rejection remains manual; the readiness event is not evidence that acceptance succeeded.

54 Lua 5.1 files, identical 0.2.69 TOCs and 9,819 substitute checks pass. Native pickup rate, event delivery and taint remain pending.

## Actionable buff bar and local reminders — 0.2.68

October 18 user supplies a single MH question-mark reminder and requests chat-only notices when no compatible buff/item can be applied, visual reminders when supplies exist, and a default near breath/fatigue bars. This supersedes the earlier gold Ask/group-message design. Interpret chat window as the player's local chat; do not broadcast requests.

Keep the complete candidate model separate from displayed actions and local notices. Learned buffs and carried selected items remain on the bar. Carried poisons without a selection retain deliberate right-click choice and use a real candidate icon. If another eligible coating is carried while the selected/automatic coating is unavailable, show a choice with its real icon; clicking opens the matching hand's Macros selection without applying or changing an item automatically. Reuse the existing weapon-item rules and reject ordinary stones that do not match the weapon. Only known lack of a compatible source produces a local notice. An owned weapon spell or available poison choice prevents a redundant missing-item fallback. Preserve class/group scope, hidden-family choices, native click revalidation and restricted-data guards.

Group-only incoming buffs and unavailable supplies are summarized locally, once per observed missing episode, with a 60-second per-buff/hand minimum for reappearing deficits and no idle repeat timer. Unknown learned/inventory/aura data does not authorize a no-source notice. Combat suppresses coatings with no prepared item or invalidated bag availability, without scanning bags. Remove outgoing request/channel code and Ask icons. Preserve existing native actions and optional passive combat behavior.

Default and reset anchor is TOP/UIParent/TOP, 0,-140; preview and passive combat panel share it. Saved dragged positions remain unchanged. **54 Lua 5.1 files, identical 0.2.68 TOCs and 9,789 substitute checks pass**. Tests now replace obsolete outgoing-request scenarios with local-notice behavior; the assertion count is not directly comparable with 0.2.67. Native chat appearance, item actions/selection, placement and taint remain pending.

## Pinned meter row backdrop construction — 0.2.67

October 18 user reports three DamageMeters.lua:79 nil-method errors from Backdrop during EnsureRows/Layout. The newly pinned source rows were plain Buttons, so they lacked the backdrop mixin. Fix their construction with BackdropTemplate; keep ordinary source rows plain and preserve pin layering, opacity, clicks, data and out-of-combat preparation. Correct the meter substitute factory to withhold backdrop methods from untemplated frames/buttons. It reproduces the exact line-79 failure before the code fix. **54 Lua 5.1 files, matching 0.2.67 TOCs and 10,030 substitute checks pass** under the stricter model. Corrected native results remain pending.

## GUI scrollbar drag direction — 0.2.66

October 18 user reports grabbing the GUI scrollbar moves in the opposite direction. Correct the shared vertical-slider translation: slider top=1/bottom=0 maps to content top=0/bottom=maximum, in both SyncScrollBar and OnValueChanged. Apply through the existing factory to outer settings, macro list/preview and setup review; preserve wheel stepping, clamping, thumb geometry, numeric horizontal sliders and combat layout deferral. No new control, saved schema, input hook or updater. Existing direction/end-point assertions are corrected to native slider coordinates. **54 Lua 5.1 files, matching 0.2.66 TOCs and 10,030 substitute checks pass**. Actual native thumb/cursor behavior remains pending the focused drag test.

## Meter startup layout readiness — 0.2.65

October 18 user reports a 0.2.64 RefreshWindow error at DamageMeters.lua:431: visibleRows is nil in the healing window, with no meter rectangles and an empty five-second native session. Reproduce the exact arithmetic failure before fixing it by running first activation while UIParent dimensions are unavailable. The supplied trace proves missing viewport initialization; its actual native geometry values were not recorded.

Initialize new windows with visibleRows=0 and layoutReady=false. A completed layout, including row preparation and positioning of every window, alone permits visibility and native-data refresh. Preserve legitimate minimized zero-row windows. Record pending layout when geometry/combat defers it and retry on existing coalesced events outside combat; no idle poll or fabricated viewport. Keep prepared windows usable while an optional new third window waits. Unprepared windows do not query sessions or run the combat clock. **54 Lua 5.1 files, matching 0.2.65 TOCs and 10,030 substitute checks pass** (25 added). Native reload/combat rendering and taint remain pending.

## Trainer attachment and level-up planner — 0.2.64

October 18: user requests the planner alongside the open trainer and an Available now popup on every player level. Keep the Training Planner optional through Record trainer offerings. Add a separate default-on Show Training Planner on level up preference, independent of trainer auto-opening.

Anchor the Suite-owned root to the visible native ClassTrainerFrame's right edge, or left when readable scaled screen geometry shows that side fits. Relative anchors follow native movement/scale without polling, native hooks, parent changes or UIPanelWindows edits. The attached header cannot detach itself; away views retain saved standalone placement and dragging. Trainer closure still hides the companion and restores its standalone anchor. Combat defers construction/anchors and interrupted movement cleanup.

PLAYER_LEVEL_UP supplies the new level before a potentially stale UnitLevel. Each valid event opens page 1/offset 0, even with no saved offerings; combat coalesces to the latest notice. Manual opening, disabling reminders/module and world entry invalidate superseded automatic callbacks. Saved future-level rows can join Available now as explicit Level met · confirm at trainer estimates. Snapshot capture level and readable skill/ability prerequisite status are sanitized; known unmet nonlevel prerequisites remain separate, and native availability is never rewritten. Legacy snapshots support an estimated exact-level match. Trainer queries occur only during a visit; prices/eligibility remain historical away.

Exact 70450 trainer layout/lifecycle, requirement getters and Unit PLAYER_LEVEL_UP payload reviewed at revision 172a387e3ab85b26e6640d3058d5ec1e6ccd4c63. **54 Lua 5.1 files, matching 0.2.64 TOCs and 10,005 substitute checks pass**, 78 additional assertions. Native attachment, visibility, level delivery, saved eligibility and taint remain pending the focused smoke test.

## Native meter parity audit — 0.2.63

October 18: user requests the built-in meter's capabilities and questions deliberately ignored information. Compare the full Blizzard_DamageMeter implementation, Camelot override, native death recap and generated contracts at exact installed **1.60.1.70450 / revision 172a387e3ab85b26e6640d3058d5ec1e6ccd4c63**. No Suite player, spell or amount filter exists; aggregation, ranking, pet attribution and retained sessions belong to the native service. The exact picker also omits the Absorbs enum, correcting the earlier EverCore comparison's suggested gap. The Camelot override suppresses classification stars by design.

Close supported gaps: spec-before-class icons, native enemy-icon suppression and readable enemy faction markers, pinned offscreen local-player rows in the same native categories, death timestamps/full bars/native recap delegation, pet-before-unit labels and unit/spec icons in breakdowns, Shift-click sticky details and right-click source selection. A cancellable one-second combat clock reads only the duration API; it does not allocate session snapshots or run idle. Keep the 0.20-second native-data coalescer.

Preserve existing Standard numbers and add native Primary, Total + rate and Total/rate/share choices, independently of numeric abbreviation. Percentages require readable finite totals. Add per-window icons, pin preference, Always/In combat/In a group visibility, header-only minimization and mouse pass-through restored through /wfs. Add optional Window 3 (initially hidden, prepared only outside combat); original pair snapping and shared lock remain. Suite's original styling, contiguous bars, shared lock, pair docking and one compact detail popup remain user-selected presentation differences.

Hidden GUID/creature-ID source queries and percentage arithmetic remain unavailable to ordinary addon code. Show permitted hidden values through native widgets; don't derive or recover hidden identities. Suite conservatively opens the native recap helper outside combat only, with no retained recap ID. **54 Lua 5.1 files and 9,927 substitute checks pass**; full native comparison, appearance, input permission and taint remain pending. See meter-parity.md and testing.md.

## Training Planner and extended buff reminders — 0.2.62

The user selects these additions from the EverCore comparison. Add a default-off Training Planner under Professions and /wfs training: save visible unlearned offerings per character, separate Available now/future levels/Other requirements, total costs across scrolling, show savings gaps and label saved/partial data. Initial empty or failed/restricted reads cannot auto-open stale data; pet training points are excluded. Recording and auto-opening are independent; all purchases remain manual.

Extend Missing Buffs with optional expiry warnings (15 seconds for short spells, configurable 30/60/120 for long spells/coatings), eight learned custom spell IDs with self/group scope, and main/off-hand macro-choice coating reminders. Preserve existing self/outgoing/incoming/class filters, native clicks and explicit missing-only Ask actions. Add opt-in passive combat reminders for selected useful class buffs and prepared coatings; no combat casting buttons, secure geometry changes or hidden-data inference. Reuse the saved buff position and standard family choices. New options start off; existing selections remain. Exact 70450 source reviewed and **9,832 substitute checks pass**. Native data delivery, visuals, secure clicks and taint remain pending; no other EverCore modules are added.

## Meter class-color RGB correction — 0.2.61

Fix the 0.2.60 error when class colors are enabled: the allocation optimization returned a native r/g/b record, but both player and spell bars read numeric array indexes. Share three validated RGB scalar returns across both renderers, preserving native class colors, Suite teal fallback, alpha and the allocation reduction. No new option or saved schema. October 18 checks pass **51 Lua files, identical TOCs and 9,623 substitute assertions**, including the named-field Hunter regression and combat/fallback coverage. Installed executable is 1.60.1.70450; actual running build/Interface and corrected in-game rendering remain pending the focused test. All edits stay in the canonical P-drive checkout.

## Serial bag-container continuation — 0.2.60

October 17 user reports intermittent auto-open failures, particularly after acquiring several openable items. Preserve existing autoOpenContainers choice and all eligibility/space/context rules. Correct the reproduced synchronous fast-loot sequence in which LOOT_CLOSED happens before AutoOpen sees an older READY/OPENED notification: current readable zero loot cannot restore a stale waiting flag. Positive/unknown/restricted loot remains blocked.

Resume from the native LootFrame.Hide callback when closing presentation outlasts the first scan, using a single removable EventRegistry observer and the existing quarter-second coalescer. Continue past a rejected physical item without retrying its unchanged GUID/count; reconcile stale loot on world entry and ignore inactive events. Keep serial native item use, existing direct-reward settling, Auto Loot/Quick loot/manual confirmations and combat/regular-space checks. No polling, UI script changes, extra setting or saved schema. **9,601 substitute checks pass** against exact 70450 source; the actual multi-container native result remains pending.

## Lower allocation overhead — 0.2.59

October 17: investigate the user's approximately 21 MB during play and later automatic drop to 6 MB. Treat this as evidence consistent with temporary allocation/collection, without labeling it a proven leak or attributing the measured peak to a module. Preserve every feature, default and saved preference.

Prepare damage-meter player rows to the viewport outside combat: default **16 total instead of 96**, with reusable growth capped at 48 per window. Keep combat menus/details ready, scrolling unchanged and native data unsaved. Release hidden player references and avoid per-row color copies. Batch event-driven native session reads at **0.20 seconds**, with one cancellable worker and no idle updater. Query fight history during visible historical selection or menu opening, skipping it for Current/Overall and hidden windows.

Create the main settings panel only on first use; retain native Settings registration, the first-login welcome and all launchers/shortcuts. Public opens defer/coalesce through combat. No forced collection, saved-data trimming or feature setting. All work is in the canonical P-drive checkout. **9,575 substitute checks pass**; actual MB/CPU improvement and native combat/input remain pending the focused test.

## Threat alignment and contrast — 0.2.58

October 17 user feedback requests a flush left edge and more obvious threat color during combat. Shift the upper attachment right by three native UI units and raise the existing grey-to-red overlay to 40–80% opacity, with neutral unknowns at 20%. Retain the compact Blizzard border, transparency, bright text, native scale following, aura-aware lower placement, guarded threat data and combat layout deferral. Work only in the canonical P-drive checkout. Installed executable is 1.60.1.70450; exact matching frame/border references are unchanged from the preceding review. Actual corrected visual/combat results remain pending.

## GitHub and CurseForge release setup — October 16, 2026

Match ZoidsTools Retail: ordinary pushes back up source and run checks; a pushed matching version tag approves automatic packaging/upload. User selects public `drockzoids-wow/WoWForeverSuite` and CurseForge project **1749120**. Prepare independent repository credentials, explicit Forever game flavor, source-only packaging and a manual setup check without uploading. Remote setup and first release remain to be verified; do not imply commit-only publication or automatic moderation approval. See `publishing.md`.

## Hidden bank panel and native chat copy — 0.2.57

Native follow-up, October 16: user confirms the clam opened immediately after reload and Copy Chat copied the Clam Meat loot message. The two reported cases are confirmed for that session; broader smoke checks remain separate.

The user's 0.2.56 report confirms an eligible Small Barnacled Clam, four free regular slots and readable false targeting, stopped only by BankPanel despite being away from a bank. Correct that child guard to effective IsVisible while retaining root BankFrame IsShown and conservative missing/restricted visibility handling. Keep every free-space, physical identity, serial loot, context and combat rule; the earlier detector/targeting hypotheses are not the actual reported cause.

Address the supplied native CopyToClipboard protected-action error by removing Suite's native-chat press/release hooks, cursor inspection and gesture timer. Native handlers own the entire selection/release action. Keep the accepted paper control, direct native selection and result callback, original owner chaining/restoration, appearance/drafts/input and combat cleanup. Detect replacement callback ownership at registration instead of mouse press. No inferred result without a native callback. Exact matching bank/chat/clipboard sources reviewed; **51 Lua files, identical TOCs and 9,542 substitute checks pass**. Actual corrected opening, clipboard copying and error/taint absence remain pending. Evidence is under bankPanelAndChatCopy in sources.json and `.cache/bank-chat-0257`.

## Container targeting check and status — 0.2.56

User reports the 0.2.55 clam retest still fails. Keep that negative result explicit. Correct the targeting guard to follow native truthiness: a successful readable nil/false means no targeting, while missing/rejected/restricted API results still block. Preserve the independent option, all other context/free-space/GUID/attempt/loot rules and default-off behavior. The saved Suite option is enabled; runtime targeting returns remain unreported.

Add read-only `/wfs containerstatus [itemID]` for concrete runtime blockers (`5523` for Small Barnacled Clam): enabled/active/context, targeting outcome/value, regular space, last request outcome and up to five matching/openable item slots. Keep raw GUIDs, secret values and raw errors out; no item use, retry, option write or pending-tooltip mutation. Add worker sent/rejected bookkeeping without claiming loot succeeded. **51 Lua files, identical TOCs and 9,531 substitute checks pass**; actual corrected opening and taint remain unverified. Evidence is under containerOpeningStatus in sources.json and `.cache/container-status-0256`.

## Clam opening detection — 0.2.55

Address the reported **Small Barnacled Clam** failure by expanding Auto-open bag containers detection: retain `hasLoot=true`, and accept the exact native localized opening prompt from the current bag-slot tooltip when hasLoot is ordinary false. No English item-name or generic-use matching and no clam allowlist. Keep required physical GUID/count identity, one-attempt deduplication and full revalidation immediately before use. Wait for sparse native tooltip/item data through events, filtering tooltip instance IDs and supporting the native all-tooltip update; no idle polling or hidden tooltip frame.

All original free-regular-slot, serial loot, native preference/confirmation, vendor/bank/mail/cast/cursor/combat and disable/logout behavior remains. Existing independent option/default and enabled choice persist. Installed executable **1.60.1.70425**, exact container/item/tooltip API files reviewed. **51 Lua files, identical TOCs and 9,507 substitute checks pass**. The screenshot confirms the native opening prompt, not actual hasLoot/GUID values or the corrected result; native clam opening/loot/taint still needs the focused test. Evidence is under clamOpening in sources.json and `.cache/clam-opening-0255`.

## Vertical leveling tracker — 0.2.54

Replace the horizontal bar with a **224×142** vertical tracker, default **top left**, with a small **Leveling** header and five caption/value rows. Add a padlock toggle and ASCII `-`/`+` minimize/expand button. Lock disables root/header clicks and movement while keeping hover information available outside combat; child controls stay clickable. Minimize hides all rows and leaves only the 24-unit header while tracking continues. Drag only the unlocked header. Keep position, locked and minimized states per character, default unlocked/expanded, and retain existing moved positions. Reset position now returns top left. Keep the header fixed when collapsing/expanding or saving a minimized drag.

Keep `levelingBar` enable choice/default-off behavior and all XP/gold/session semantics. Add settings recovery controls and search terms; no other EverCore tools or new recurring worker. Defer input/layout changes through combat with final-choice coalescing, cancel interrupted drags, and clear pending presentation on disable. Exact installed-build separate click/motion API declarations reviewed. **51 Lua files, identical TOCs and 9,473 substitute checks pass**; real input routing, hover, visuals, persistence and combat/taint still require the native smoke test. Evidence is under levelingTracker in sources.json and `.cache/leveling-tracker-0254`. This replaces the 0.2.52 presentation plan below.

## Blizzard-style threat rectangle — 0.2.53

User dislikes the opaque square and requests Blizzard assets, rectangular proportions and chat-like transparency. Replace its presentation with a passive **60×24** rectangle using Blizzard TooltipDefaultLayout border art, warm trim, a translucent native chat background and a light grey-to-red threat tint. Keep bright outlined text and a matching native edge connector. Hide the native border's opaque center; never fade the whole widget or mutate native target/chat frames or global layouts.

Existing default-off setting, readable percentage/unknown semantics, aura-aware above/below placement, native scaling/input, event coalescing and combat restrictions remain. No new option, asset file or saved schema. Exact current-build art/layout sources reviewed; **51 Lua files, identical TOCs and 9,405 substitute checks pass**. Corrected native appearance/clearance/taint are pending the focused test. Evidence is under targetThreatStyle in sources.json and `.cache/threat-style-0253`.

## Leveling session bar — 0.2.52

User requests only EverCore's XP/gold/leveling behavior in a movable top-center bar. Add independent default-off **Everyday Tools → Leveling → Leveling bar** (`levelingBar`), with `/wfs leveling` / `/wfs xp`. Show level/XP progress, XP/hour, net gold/hour, next-level ETA and session elapsed time; hover for totals/remaining XP. Use original Suite styling, plain dragging and per-character position memory, right-click settings and Ctrl-right-click/default-position reset. A separate settings action resets session counters. No other EverCore tools or history are added; its project is read-only reference material.

Match session semantics: one-minute rate warmup, idle time included, gold explicitly net including spending/transfers, reload continuation with guarded loading time, fresh-login reset and no offline accumulation. Keep ordinary single-level rollovers accurate, mark missing intervals/multi-level jumps partial, and suppress uncertain/paused estimates. Existing per-character SavedVariables retain validated numeric checkpoint/position beside macro data. Combat defers creation/layout; safe owned text can update, interrupted movement rolls back, and a reload during combat retains its checkpoint until setup is allowed. Active-only one-second display ticker plus one short level-transition coalescer; no per-frame/native hooks or disabled polling.

Installed executable **1.60.1.70425** and exact pinned UI/API sources reviewed; actual native result remains pending. **51 Lua files, identical TOCs and 9,399 substitute checks pass**, including all new metric/accounting/lifecycle/input/restriction and generic settings checks. Evidence is under levelingSessionBar in sources.json and `.cache/leveling-bar-0252`. User also confirms 0.2.51 corrected the Mail heading's missing glyph.

## Mail sort-direction font fallback — 0.2.51

October 16 screenshot's square after Name corresponds to the Suite's Unicode sort arrow failing to render in the header font. Use basic `^` / `v` direction markers on the active Name, Ruleset or Level heading. Preserve sorting, contact data and native mail behavior; no new preference or asset. **50 Lua files, identical TOCs and 9,244 existing substitute checks pass**. Corrected glyph appearance remains pending the focused native check in testing.md; source/screenshot/package evidence is under mailSortMarker in sources.json.

## Current minimap header and day/night art — 0.2.50

October 16 supplied screenshot shows current native gold zone-button art covering Suite labels and the separate sun floating over the square map. Match the installed **1.60.1.70425** source: hide only the recognized ZoneTextButton decorative BACKGROUND layer, preserving the native button's hover/pressed state machine, tooltip and map click. Retain the legacy header-art path. Restore the original layer-enabled state when square mode is disabled.

Fit the existing native day/night frame to a passive twenty-unit slot beside tracking in the header, with calendar on the right. Reserve label/click-target space between those controls, keeping full-name wrapping. Uniform scaling retains native atlas geometry and day/night updates. Keep native parents/scripts, coordinate band and clock ownership; restore captured native placement/scale/layer on disable. No new setting, asset, saved schema, event subscription or idle worker. Construction/layout/restoration defer through combat; existing event coalescing handles native transform resets.

**50 Lua files, identical 0.2.50 TOCs and 9,244 substitute checks pass**, 41 more than the prior version. New tests reproduce the old gold-panel regression and cover scaling/layout, native art/state/event ownership, combat deferral, native restoration and restricted values. Actual in-game appearance/input/taint remain pending the new smoke test. Exact source and package evidence is under minimapCurrentHeader in sources.json and `.cache/minimap-header-0250`.

## Preserve combined bag order during combat — 0.2.49

October 16 user screenshots show the chosen out-of-combat layout reverting in combat. Correct the addon's blanket combat skip: after a completed native layout, retain the previously prepared section/slot order only when the native combined container, anchor and every current slot explicitly report readable unprotected, unrestricted and nonsecret anchoring. Preflight the whole current grid before any write. Protected/unknown layouts still defer; new settings/setup and native window movement rules retain their existing combat limits.

Keep the Hearthstone's existing physical bag/slot and prepared bottom-right display through ordinary combat redraws/reopens. Read fresh native pooled buttons and current safety predicates each pass. Do not call the native full layout or prompt-anchor writer from Suite during combat; the native prompt's relative anchor follows its slot. No native method replacement, item sorting/movement, new worker, setting or SavedVariables schema. Deferred refresh also commits the final chosen mode for later combat passes.

Installed executable remains **1.60.1.70425**; matching protection/anchor API source is pinned to `b401e0332adfbf0460d319b06d8ea29279a941f1`. **50 Lua files, identical TOCs and 9,203 substitute checks pass**, including 72 additional assertions for reported combat retention, fresh slots/reopening, whole-grid unsafe rejection and deferred mode commitment. Native retention/input/taint require the new focused test; evidence is under combinedBagCombat in sources.json.

## Target threat square — 0.2.48

October 16: add an independent default-off **Combat & Bars → Unit Frames → Target Threat → Target threat indicator**. A passive 34×34 percentage square attaches above the native target's left name-strip edge when auras are below. With **Buffs on top**, it moves below/outside the left power-bar edge, with a short connecting tab, to leave native auras, bars and target-of-target space clear. Follow native movement/scale; preserve native controls, scripts/parents, art and numeric-threat preferences. No new asset or target UI replacement.

Display the client's readable scaled player-versus-current-target threat percentage for a living hostile NPC. Fade grey at 0 through orange to red at 100. Check the exact threat restriction predicate before querying and guard all results; unknown/unavailable/restricted values show neutral **--**, never guessed zero or stale color. Enemy players/friendly/dead/hidden targets hide it. No hidden-value recovery, alternate identities or saved threat data.

Use relevant events and one cancellable 0.05-second coalescer. No idle polling. Construction, anchoring and scale changes defer through combat; prepared explicitly unprotected visuals may update. A combat aura-side change hides the indicator until safe layout. Disable/logout cancel pending work and release events, while installed native hooks remain inert. The current native target frame is the supported scope.

Installed executable remains **1.60.1.70425**; exact APIs/layout/setting sources are pinned to `b401e0332adfbf0460d319b06d8ea29279a941f1`. **50 Lua files, identical TOCs and 9,131 substitute checks pass**. Native percentage access, appearance, aura/cast-bar clearance, persistence and combat/taint remain pending the new focused testing.md checklist. Evidence is under targetThreat in sources.json.

## Reverse slots inside each bag — 0.2.47

October 16 clarification: keep the Hearthstone in the backpack and display it at the combined window's bottom-right corner. User screenshots/report confirm the previous native direction option moves it into a different physical bag. Retire that control and its active native override. Replace it with independent default-off **Bag Order → Reverse slots within each bag**. Combine it with **Reverse combined bag order** to place backpack slot 1 at the overall bottom-right cell. The option changes displayed button order within each bag, preserving physical bag/slot identity, native cleanup allocation, exclusions and item behavior. It has no Hearthstone special case. Native cleanup is needed once to undo physical item placement left by the old direction setting.

Migrate the previous enabled reverse-sort choice into the new display option unless the new choice is already explicit. Restore the old captured native direction outside combat, retaining its backup on unavailable/rejected restoration. Thereafter no native direction override/query/write remains. All four section/slot display combinations work independently through the existing post-hook; active mode changes refresh, both off restore native layout, and setup/anchoring defer through combat. Controller headers/collapse, individual bags and banks remain native. No new frame, hook, timer, event or worker.

Installed executable remains **1.60.1.70425**; actual running build/Interface unreported. Matching pinned references are reused from 0.2.45/46. **49 Lua files, identical TOCs and 8,888 checks pass**; migration, restoration, all modes, exact backpack-slot corner geometry, physical identity, guards, GUI/search and combat are covered with substitutes. The corrected native appearance, allocation after cleanup, input and taint require testing.md. Evidence is under bagSlotOrder in sources.json.

## Reverse native bag sort direction — 0.2.46

**Superseded by 0.2.47:** this native control changes bag allocation. The user instead wants reversed display inside the same bag.

October 16 follow-up: add default-off **Bag Order → Reverse bag sort direction** to Bags & Bank. Native bag cleanup uses the opposite captured direction for both its cleanup button and Sort bags on opening. The combined-bag display option and automatic sorting remain independent. Toggling changes only the native direction preference; sort afterward to move items. Native category ordering, specialty-bag rules and exclusions retain ownership, with no insertion-direction change or custom sorting algorithm.

Capture and persist the original native boolean, restore it on disabling, and confirm writes using the getter. This prevents inversion on every reload and preserves false backups. Invalid/restricted/missing APIs/results skip work; rejected restoration retains its backup. Defer preference writes through combat using the existing core queue, with final-toggle cancellation. Default-off without a backup is idle. No new frame/event/timer/hook or worker; the existing BagSort module applies this preference independently of sorting on opening.

Installed executable is **1.60.1.70425**; exact container API declarations are pinned to `b401e0332adfbf0460d319b06d8ea29279a941f1`. **49 Lua files, identical TOCs and 8,886 substitute checks pass**. Native cleanup direction/access, actual persistence and taint require the focused testing.md checklist. Sources/evidence are under bagSortDirection in sources.json.

## Reverse combined bag order — 0.2.45

October 16: add an independent default-off **Bags & Gear → Bags & Bank → Bag Order → Reverse combined bag order** switch. The user's requested combined-bag sequence is **ammo (746) → red → blue → backpack**, reading top-to-bottom. Change only native slot-button placement, retaining normal order inside each bag and physical bag/slot identity. Native sorting, inventory contents, hover highlighting, search, item controls, currencies and Window tools stay under their existing ownership. Individual bags, banks and controller bag headers/collapse remain native. Disabling restores native order.

Use a narrow singleton layout post-hook and the client's current anchor/grid, preserving native spacing, column count, partial rows and the separate locked-extension prompt. Defer all Suite slot anchoring/setup through combat. Native combat relayout may show normal order until combat ends; pending reversal is keyed/cancellable. Watch missing native frames only until first attachment, and never force layout on an uninitialized hidden bag. No item sorting/movement, CVar changes, timer or idle worker.

Installed executable is **1.60.1.70425**; running build/Interface not captured. Seven matching Blizzard references are pinned to `b401e0332adfbf0460d319b06d8ea29279a941f1`; do not use the stale base cache for the current ordering. **49 Lua files, identical TOCs and 8,827 substitute checks pass**. New requested-order/lifecycle/guards plus existing GUI-fit checks pass; native appearance, input, persistence and taint require the focused smoke test. Sources/evidence are under combinedBagOrder in sources.json.

## Clock and stopwatch window placement — 0.2.44

October 15: include the clock/alarm panel and compact stopwatch in existing Window tools. Drag native empty title space to move and remember each window independently. The stopwatch uses its narrow title strip, preserving close/start/reset controls and digits; native body drags also update Suite placement. Retain Ctrl-wheel resizing, Ctrl-right-click reset, native-layout restoration and combat deferral. Watch the load-on-demand frames before their first show without forcing a load. No new toggle, asset, saved schema or idle worker; native timer/fade scripts and Blizzard stopwatch options remain under native ownership.

Installed executable is 1.60.1.70374; actual running build/Interface not captured. **48 Lua files, identical TOCs and 8,773 substitute checks pass** (41 new assertions). The focused clock/stopwatch reload, drag, actual session persistence and control/combat smoke test remains pending. Sources/evidence are under stopwatchWindows in sources.json.

## Wrapped native chat callback ownership — 0.2.43

The 0.2.42 native retest deactivates copy mode on the first press in chat. Correct ownership checks to compare with the callback actually stored by the native setter/getter, since secure mixin barriers wrap function arguments. Preserve prior callback behavior and newer owner identity. Keep restored native selection/release-copy, original appearance and result feedback; no editor or direct clipboard call returns. The wrapped-callback regression reproduces the reported early exit and passes with the correction. **48 Lua files, identical TOCs and 8,732 checks pass**. The user completes the 0.2.43 retest and confirms **selection and pasting work**. This establishes targeted native success for the requested workflow; running build/Interface, broader markup/windows and combat/taint remain unreported. Release evidence is under chatReleaseCopy in sources.json.

## Restore native chat release-to-copy — 0.2.42

October 15: the user dislikes the 0.2.40 copy view and explicitly requests the previous native chat appearance and highlight/release copying. Remove the snapshot editor and restore native selection through the existing paper button. Add result feedback from the public native copy callback, preserving its prior/newer owner and native input flag restoration. Only a valid positive copied count reports success; a failed/unknown result or absent callback reports inability to confirm. A bounded mouse-release check never reads text/clipboard or attempts copying from a timer. Keep the module optional with no new setting or saved chat.

**48 Lua 5.1 files, identical TOCs and 8,730 substitute checks pass**; installed executable remains 1.60.1.70374. Original clipboard-write failure is not yet established as fixed: the native reload/select/release/paste result has been requested. Record actual pasted contents and reported result using testing.md. Source/evidence is under chatReleaseCopy in sources.json. The persistent-selection overlay entry below is superseded.

## Trash button identification banner — 0.2.41

October 15: identify the discard suggestion with a slim **Trash** banner across its bottom. Keep the 48×48 footprint, icon, existing teal border, lower layering, dragging, click confirmation and right-click blacklist. The 12-unit dark strip and centered small label stay inside the existing border; item details and instructions remain on hover. No new preference or behavior change. Native appearance remains pending the small testing.md reload check.

## Persistent chat selection and Ctrl+C — 0.2.40

October 15: automatic chat copying leaves the previous clipboard contents without a new error. The user chooses persistent highlighting with **Ctrl+C**, instead of copying/deselecting on release or opening a field below chat. Copy mode now presents the currently visible readable text in a temporary selectable layer within the existing message area. Keep the accepted paper button; Escape or another click returns to native chat. Native EditBox owns selection/keyboard copying, so Suite never calls the restricted clipboard API or resets selection on release.

Read only public rendered-line callbacks once per activation, strip ordinary markup while preserving labels/Unicode/line breaks, and reject restricted/unavailable/oversized data. Never read private buffers or saved history. Freeze the view during incoming chat/settings refreshes; clear it on exit, switching, native typing/hide/input changes, resizing, combat or disable. Preserve the unsent draft, native input/link/copy flags, sending behavior and original Suite appearance controls. No popup, new preference, persistent chat data or idle scanner is added. The prior native release-copy implementation below is superseded.

Installed executable is 1.60.1.70374; actual running build/Interface and corrected clipboard result are not captured. The regression fails against packaged 0.2.39 Chat; **48 Lua 5.1 files, identical TOCs and 8,752 checks pass** with the replacement. Native Ctrl+C, selection/scroll rendering, coexistence and combat/taint remain pending the testing.md checklist. References/evidence are under chatCopySelection in sources.json.

## Trash button protected confirmation fix — 0.2.39

October 15: the user supplies ADDON_ACTION_BLOCKED at BagSpace.lua:371 plus the failed-confirmation chat message. Replace the denied C_Item.ConfirmDeleteItem request with the existing native DELETE_ITEM cursor dialog, supplying a unique cleanup token without itemGUID. Its native Accept uses DeleteCursorItem on the user's confirmation click. Suite never invokes deletion or accepts a dialog. Preserve exact minimum/instance and cursor validation, native cancellation, ownership cleanup, gray/white eligibility, right-click blacklist, 48×48 dragging and LOW layering.

Installed executable is 1.60.1.70374; running build/Interface not captured. The protected-call substitute reproduces failure before the fix; **48 Lua 5.1 files, identical TOCs and 8,696 checks pass** afterward. Confirm the corrected native click, cancel/accept, ownership and combat behavior using testing.md before calling it verified. Details and native source continuity are under bagSpaceClickFix in sources.json.

## Square minimap quest ring — 0.2.38

October 15: the user identifies quest-area clipping in the supplied minimap screenshots and selects **Hide the checkered ring; keep the blue quest boundary**. Tie this behavior to the existing independent, default-off square minimap switch. Keep native terrain coverage, blue quest-area outline, fill, markers and zoom. Round mode restores the ring; stats alone do not request its suppression. The settings help explains the ring behavior.

Use the native quest-ring scalar setter through the existing combat-deferred layout worker, with a single idle-when-disabled observer and contained optional-API failures. Restore the latest readable observed owner scalar or the normal scalar 1. There is no native getter, so custom values set before observation cannot be recovered. Unknown owner values relinquish the override without a guessed restore. No other blob types, extra setting, asset or gameplay action is included.

Installed executable is 1.60.1.70374; actual running build/Interface and corrected native rendering are not captured. **48 Lua 5.1 files, identical TOCs and 8,685 substitute checks pass**, with twenty new ring assertions. Native visuals, boundary/marker preservation, coexistence, rotation/zoom and combat/taint require the new testing.md checklist.

## Automatic bag-container opening — 0.2.37

October 15: user requests an option to open openable items in carried bags with at least one available bag slot. Add independent default-off autoOpenContainers and original namespace-only AutoOpen.lua. Find **Bags & Gear → Bags & Bank → Container Opening → Auto-open bag containers**; search includes its label/help. Existing settings and setup suggestions remain unchanged.

Scan native carried bags for known hasLoot=true, unlocked stacks with positive readable item/count and physical GUID. Count only family-zero regular free slots; specialty/reagent and bank space cannot satisfy the one-free-slot requirement. Recheck identity, GUID/count, free space and context immediately before C_Container.UseContainerItem. Open one item at a time, waiting for loot closure or a bounded two-second settle callback for direct rewards. Native Auto Loot and Quick loot preferences remain in control, and native confirmations are never accepted automatically. A one-slot threshold cannot guarantee all contents fit; leave overflow/manual choices to the native loot flow.

Pause for combat, death, casts/channels, cursor-held items, spell targeting, existing loot and merchant/bank/guild-bank/mail/trade/auction/item-interaction/scrapping/upgrade windows. This avoids context-sensitive selling/deposit/attachment. Coalesce event bursts with one cancellable quarter-second worker; no idle OnUpdate or periodic scan. Defer initial event-frame creation through the combat queue. Disable/logout cancel work; combat stops pending attempts and exit events reconcile. Contain unavailable/rejected APIs and secret values. Attempt a physical GUID/stack-count combination once per activation so an unchanged lockbox/rejected request cannot loop when moved/sorted. Native key/skill/confirmation requirements remain; manually retry an unchanged failed item or toggle the setting to start a fresh pass.

Installed executable re-read October 15: 1.60.1.70374; running build/Interface not supplied. Exact API source continuity and hashes are in sources.json and .cache/auto-open-0237. UseContainerItem declarations and pcall do not prove ordinary-addon permission for every container. **48 Lua 5.1 files, identical 0.2.37 TOCs and 8,665 substitute checks pass**, including 39 new auto-open assertions plus catalog/default coverage. Native actual opening, loot completion/overflow, permissions/taint, rendering and persistence remain pending the focused smoke test.

Prior feature confirmation: the user reports the 0.2.36 upgrade eligibility correction is now working. Record this as targeted native confirmation for the reported empty gloves/teal + case, not exhaustive scoring, native API return or combat/taint verification. Actual running build was not supplied.

## Player eligibility for wearable upgrade hints — 0.2.36

October 14 follow-up screenshots show Rabbit Handler Gloves (item level 5, cloth, 6 armor) on a level-2 Warlock, an empty gloves slot, Possible upgrades enabled and Prefer: Item level. The tooltip has inventory counts but no empty-slot hint. This rules out the selected stat preset as a prerequisite for this report; actual native API values/build were not captured.

Upgrade eligibility previously required C_Item.IsUsableItem, the action-use predicate with usable/noMana results. Exact native gear tutorial code resolves C_Item.GetItemInfoInstant(itemLink) and calls C_PlayerInfo.CanUseItem(itemID) for player gear eligibility. Add Items:CanEquip using that player predicate and a validated positive integer item ID. Use the same gate for icon and tooltip comparisons. False, secret, missing IDs, rejected or unknown modern answers suppress hints; never fall back after a modern rejection. Only when the modern capability is absent retain the older conservative IsUsableItem check. Keep independent level, loaded metadata, empty-slot and weapon-configuration guards.

The regression now reproduces the predicate mismatch: loaded passive gear with action-use=false and player eligibility=true receives the icon + and empty-slot tooltip; player eligibility=false clears it. Eleven new assertions include numeric ID validation, restricted/rejected responses and real icon/tooltip coverage. **47 Lua 5.1 files, identical 0.2.36 TOCs and 8,624 substitute checks pass**. These fixtures support the correction but do not establish which native return rejected these exact gloves. Native permission, actual eligibility, rendering and combat/taint need the focused reload test.

## Empty-slot gloves without a stat table — 0.2.35

October 14 screenshot/report: level-5 bag gloves have an item-level number but no teal + while the character has no gloves equipped. This establishes continued native failure after the previous change; it does not establish the exact returned stat/usability values, feature state or running build.

Correct a remaining implementation dependency: 0.2.34 still fetched and scored candidate stats before checking an empty armor/accessory slot. Exact pinned 70374 C_Item.GetItemStats documentation declares MayReturnNothing. Move the confirmed-empty-slot decision ahead of all stat queries/capability requirements. Keep loaded item identity/type, required/player levels, known native usability and readable inventory links as prerequisites. No empty-slot score arithmetic is needed; return the existing positive marker signal and explicit emptySlot metadata. Occupied slots retain strict stat-data checks, and weapons retain their complete-hand model.

Raise the teal + to OVERLAY sublevel 7, matching the level number, and use a fourteen-point outlined font for contrast. No protected frame layout is added. Extend the regression through actual Items:Update and Tooltips:Item using loaded gloves with GetItemStats returning nil: the icon shows +, hover explains the empty slot, and equipping clears it. Also test throwing and missing stat capabilities; empty armor slots do not call them. The stat-data dependency is reproduced offline; its role in this specific native screenshot still requires the reload check.

47 Lua 5.1 files, identical 0.2.35 TOCs and 8,613 substitute checks pass. Six new assertions cover icon/tooltip/clear/layer and missing/rejected-stat paths. Existing usability, level, restricted equipment links, occupied-slot metadata and hand-model tests remain passing. Native marker rendering, actual glove usability/API values and combat/taint remain pending.

## Upgrade hints for empty equipment slots — 0.2.34

October 14: the user requests a teal + on usable gear for a slot with no equipped item, such as gloves on a new character. Empty slots already contributed zero to ordinary comparisons, but a candidate with no weighted bonuses also scored zero and was omitted. Accept a loaded usable candidate with known readable stats even when its score is zero, when the inventory API confirms an eligible empty slot. Preserve native usability and level checks, missing/restricted-data guards, feature switch and Stats/Item level preferences.

For rings/trinkets, recognize a confirmed empty member before loading the occupied member's stats. Unknown/restricted links do not count as empty. Weapon candidates retain the existing hand/configuration model; a two-hander's unavailable offhand is not a free slot, and offhand weapons still require dual-wield permission. A zero-score candidate may qualify only for a legal empty destination, without assuming another unowned item or losing existing hand contributions.

Tooltip text says **Fills an empty equipment slot**, with the hand label for weapons. The positive return used to trigger a marker in this case is not displayed as a fabricated stat/level gain. Occupied-slot comparisons retain their scoring behavior. The setting help now mentions empty slots.

47 Lua 5.1 files, identical 0.2.34 TOCs and 8,607 substitute checks pass. Fourteen added assertions cover plain zero-weight gear, occupied-slot exclusion, actual gloves and paired rings in both modes, usability, empty caster weapons, tooltip reason metadata and two-hander exclusions. Existing missing/secret metadata and weapon tests still pass. No new APIs or external source imports; existing item/weapon provenance applies. Actual native marker/tooltip appearance, equipment refresh and combat/taint remain pending.

## Target castbar sizing and live numeric input — 0.2.33

October 14 user screenshot: Target custom size is enabled with height 36 in the numeric field, but the visible target Hearthstone bar appears unchanged. This establishes the reported visual/input problem; it does not establish the actual running build, stored height or exact native cause. Installed executable re-read as 1.60.1.70374.

Fix two paths: numeric dimensions now apply valid user edits immediately and synchronize the slider without rewriting partial input. Enter and focus loss also commit; programmatic refreshes stay inert. Previously typing alone left the old dimension active until Enter, which could leave the displayed field and slider disagreeing.

Snapshot configured dimensions through GetWidth(true)/GetHeight(true), using the documented ignoreRect argument, rather than depending on resolved aura-anchored geometry. TargetSpellBarMixin:AdjustPosition anchors below native aura layout; size accessors declare SecretWhenAnchoringSecret. Continue validating returned values and skip an override if configured dimensions remain unavailable; never recover restricted layout/cast information or assume default dimensions. Show an explicit settings message when native size cannot be captured, or changes await combat/Edit Mode. Reapply through coalesced native show/look/position hooks, preserving anchors/scale/parents and original size restoration. The layout restriction is a source-supported failure path covered by substitutes, not a confirmed native diagnosis.

47 Lua 5.1 files, identical 0.2.33 TOCs and 8,593 behavior checks pass. New regressions cover restricted resolved versus readable configured target sizes, height/restoration, fully restricted dimensions, unavailable-state feedback, live typed height, slider synchronization, partial input, programmatic refresh and focus-loss commit. Native target/focus appearance and secure layout permission remain pending. Source continuity and release evidence are recorded in sources.json and .cache/castbar-sizing-0233.

## Modifier Disenchant, castbar sizes and zone reputation — 0.2.32

October 14: implement the selected recommendations #2, #3 and #4 as independent, default-off features. **Bags & Gear → Professions** offers modifier-click Disenchant with an Alt/Ctrl/Shift choice. Only learned Disenchant, a living idle player, an empty cursor and known unlocked carried uncommon/rare/epic equipment can prepare the secure action. Require exactly the selected modifier, validate the current owner/bag/slot/item again before clicking, and let the native spell enforce remaining skill/item requirements. The tooltip warns that Disenchant destroys the item. No automatic profession processing or bank support is added.

**Combat & Bars → Castbars** offers independent player/target/focus width and height, numeric entry/sliders, native previews and restoration. Preserve native anchors, parents and scale; release dimensions while native Edit Mode owns them and reapply afterward. Preview uses the native casting bar's public edit-preview state without synthetic spell/timing data. Stop on navigation, actual casting, target/focus changes or combat; protected cleanup/layout waits until combat ends. First widget construction is also deferred.

**Everyday Tools → Quests & Loot → Zone reputation tracking** selects known home-city outdoor factions and Booty Bay, Ratchet, Gadgetzan or Everlook using localized native area names. Unmapped areas and instances preserve the current watch. Change once per zone context, respect a later manual selection until the next zone event, coalesce updates and defer combat writes. Disabling cancels pending work. This is a deliberately limited initial mapping, not every quest faction.

Installed executable: 1.60.1.70374; actual running build/Interface not supplied. Exact-source continuity is recorded in .cache/qol-trio-0232/evidence.json and sources.json. Earlier ZoidsTools behavior review informs the feature choices; P: is unavailable this session and was not freshly reread. Implementations and GUI are original Suite code. **47 Lua 5.1 files, identical 0.2.32 TOCs and 8,581 substitute checks pass**. Substitutes cover secure-action preparation/stale slots, modifier exclusions, combat deferral, restoration/preview cleanup, reputation mapping/manual changes and GUI/search. Native spell permission, rendering, Edit Mode coexistence, combat/taint and persistence remain pending the focused smoke tests.

## Follow Windows audio device — 0.2.31

October 14: the user requests the final audio-sync feature before considering GitHub/CurseForge publication, referencing their Retail ZoidsTools and the advertised behavior of Enhance QoL/Leatrix Plus. Add an independently default-off **Everyday Tools → Audio → Follow Windows audio device** toggle, **Sync now** action, `/wfs audio` shortcut and searchable Windows/headphones/output/sound terms. This task implements/packages the feature; publishing remains a later task.

Original Audio.lua selects native Sound_OutputDriverIndex=0 (System Default) on activation and requests a game sound-system refresh after public VOICE_CHAT_OUTPUT_DEVICES_UPDATED/SOUND_DEVICE_UPDATE events. Coalesce bursts for 0.2 seconds and bound restarts to one per two seconds, ignoring immediate and short delayed restart feedback. No polling, OS helper or DLL is added. Validate modern CVar availability/public/writable flags and confirmed writes before invoking the optional native restart function. Preserve volume/mute/background sound, microphone and voice-chat preferences. Disabling unregisters/cancels work and leaves output selection available in native settings; do not restore an obsolete hardware index.

Defer first event-frame construction in combat; existing enabled audio refreshes perform no protected UI work. Hold device/manual updates while a movie/cinematic is active or its state is unknown, then reconcile after stop events settle. Disable/logout cancels pending work. Contain missing/rejected APIs/event registrations with local feedback and no automatic retry loop. Retail ZoidsTools v4.12.30 AudioSync.lua is a read-only behavior reference; no Enhance QoL or Leatrix implementation/assets are imported.

Installed executable re-read October 14: 1.60.1.70374. Exact pinned 70374 sound/voice/CVar/cinematic/event definitions and native audio settings are cached under .cache/audio-sync-0231. The native restart global lacks a generated declaration; the older export identifies it only as a secondary signature reference. Runtime capability checks/pcall and the in-game test remain necessary, rather than claiming ordinary-addon permission from that export. **44 Lua 5.1 files, identical 0.2.31 TOCs and 8,489 substitute checks pass**, including new audio lifecycle/API/feedback/media/combat/GUI coverage. Native OS event delivery, sound routing, permissions, brief interruption, mute preservation and persistence remain pending the focused smoke test.

## Clock sizing across square minimap toggles — 0.2.30

Fix the October 14 native screenshot report: disabling and re-enabling square mode truncates the clock until reload. Preserve the native clock ticker's explicit sizing (including automatic zero dimensions) rather than restoring a measured text rectangle as a fixed box. Clear its dimensions for natural text sizing while using the enlarged square-mode font; restore genuine external/native explicit sizes, font and anchors when disabled. Keep native ownership, clock settings/updater and combat deferral.

The new substitute reproduces the original fixed-width restoration error before correction; 43 Lua 5.1 files, identical TOCs and 8,379 checks pass with 28 added assertions. Installed executable remains 1.60.1.70374, with exact pinned clock/sizing definitions reviewed. User screenshots establish the failure; actual running build/Interface and corrected in-game visuals/taint remain pending the focused test in testing.md.

## Weapon hints and comparison preference — 0.2.29

October 14: the user reports casual testing looks okay, with the missing teal + on weapons their only stated concern. They request a choice between preferring higher item level and higher stats. Add account-wide **Bags & Gear → Gear Details → Upgrade Comparisons → Prefer**, cycling **Stats / Item level**; defaults remain Stats and Possible upgrades remains independently optional. Apply the choice to all supported upgrade hints rather than giving weapons an undisclosed separate rule. Preserve the selected stat preset. Search includes higher ilevel/stats/weapon/DPS terms.

Stats retains existing armor weights and adds an explicit weapon-set model: sum both hands' weighted bonuses, add main-hand base DPS at the preset's weight and off-hand base DPS at half that weight; ranged DPS uses slot 18 independently. Melee/ranged DPS weights are Balanced 1/1, Physical 7/7, Caster 0/1, Healer 0/1 and Tank 1/1. View stat weights discloses these preferences and omitted weapon-speed abilities, procs, talents and hit penalties. Caster/healer melee weapons are scored as stat sticks. Numeric DPS is accepted only from a readable native ITEM_MOD_DAMAGE_PER_SECOND_SHORT value; missing required DPS omits the hint.

Item level compares ordinary slot levels, including the weaker ring/trinket slot. Melee sets use the two-hand average, with an empty hand worth zero and a two-hander occupying both level slots. An incoming two-hander removes both equipped contributions; a one-hander preserves the other existing hand and never assumes an unowned companion. Flexible one-handed candidates consider the off hand only with public CanDualWield=true and an existing one-handed main weapon. Shields/holdables require room beside that main hand; ranged weapons and relics compare within their own kind. Two-handed dual wield is unmodeled and omitted. Tooltip wording identifies Stats versus Item level and the best valid hand replacement; level preference does not claim better performance.

Installed executable re-read October 14: **1.60.1.70374**. Its pinned mirror revision 735496de78ebd30ce816a0637982c556987f258c differs from 70338 only in version.txt; exact item/dual-wield declarations are cached under .cache/weapon-hints-70374. No native build/Interface capture or thorough feature verification was supplied. **43 Lua 5.1 files, identical 0.2.29 TOCs and 8,351 substitute checks pass**, including fifty added assertions for preference migration/UI/search, conflicting stats/levels, complete hands/DPS, native item markers/tooltips, unknown/restricted data and rejected API calls. Native DPS return shape, weapon placement/usability, GUI fit, combat/taint and persistence require the focused test in testing.md.

## Minimap drawer library render compatibility — 0.2.28

The user's screenshot after adding addons shows dim/obscured middle launcher icons in the open drawer. Installed BugSack's LibDBIcon minor 57 creates fixed frame strata/levels, and both installed library versions implement showOnMouseover fade groups controlled by ShowOnEnter. The previous collector only changed strata/level, without releasing fixed flags, and inherited minimap-only mouseover fading when icons moved into the drawer. This source evidence supports the suspected rendering interactions; corrected native visuals remain pending.

Snapshot readable HasFixedFrameStrata/Level when collecting supported movable buttons; skip unknown results. Temporarily clear known fixed flags before collection layout so original buttons render at DIALOG above the owned panel. Secure post-hooks retain latest owner SetFixedFrame requests without a feedback loop; restoration releases flags for original geometry then restores owner flags. Protected/restricted/foreign-collector guards and combat deferral remain.

Verify the current runtime LibDBIcon GetMinimapButton identity before changing ShowOnEnter. Remember the owner's showOnMouseover preference, suspend enabled fading while collected and restore only the override Suite actually applied. Capture subsequent owner requests through the library's own setter, including nil treated as false by the library. Leave ordinary alpha and explicit hidden state intact, preserve original click/tooltip handlers, avoid SavedVariables/library edits and retain cancellable event-based discovery with no polling. Newly created icons and library refreshes reuse existing work.

43 Lua 5.1 files, identical 0.2.28 TOCs, unique binding headers and 8,301 substitute checks pass, with sixteen additional assertions for fixed-layer promotion, temporary flags, library fade suppression, latest owner requests, feedback settling and restoration. Installed executable re-read October 13: 1.60.1.70338; running build/Interface not supplied. Source/screenshot/package evidence is under minimapDrawerLayers in sources.json and .cache/minimap-drawer-layers-0228. Native rendering, hover/coexistence, restoration and combat/taint remain pending.

## Duplicate binding header correction — 0.2.27

The user's October 13, 17:48:27 client error reports WOWFOREVERSUITE loaded more than once from Bindings.xml. The quest-item addition repeated the existing bank binding's header attribute. Keep the header declaration on the first entry only; both action names, category, labels and execution bodies stay intact. No saved binding or setting is changed.

The addon checker now rejects repeated header attributes in its declared binding XML. It reproduces Duplicate binding header: WOWFOREVERSUITE before the XML fix and passes afterward. 43 Lua 5.1 files, identical 0.2.27 TOCs, unique binding-header validation and 8,285 substitute behavior checks pass. The reported native failure is established; corrected native loading and both binding actions still need the user's reload check. The last installed-executable observation was 1.60.1.70338; actual running build/Interface remains unreported.

## Compact nearby quest-item button — 0.2.26

Implement the selected quest-item recommendation with the Suite low-bag-space button's appearance rather than ZoidsTools' presentation: 48 × 48 slate surface, fine teal border/hover, 44 × 44 item icon and native cooldown swipe, LOW strata/level 1 below ordinary windows, no always-visible label. Item tooltip adds quest title, carried count and use/move/reset hints. Left-drag saves normalized placement; Ctrl-right-click resets only this button. Default placement is 58 units right of screen center, beside the trash button's default. Add Nearby quest-item button under Everyday Tools → Quests & Loot and existing settings search, default off. Native Keybindings → Forever Suite includes Use nearby quest item through a narrowly documented named CLICK target.

QuestItem.lua selects native quest-log special items with a readable carried-only C_Item.GetItemCount. Only incomplete quests, or completed quests whose native special item explicitly permits showing, qualify. Require known active quest blob or readable same-continent squared distance ≤ 250². Inside area outranks mere proximity; then prefer the supertracked quest, nearest objective and deterministic quest ID. Header/hidden/unknown identity/completion/item/count/location data cannot authorize a candidate. Native target range tints known out-of-range icons; guarded C_Item cooldown timing drives a native widget. No hardcoded quest/item catalog or broad zone fallback is added; unsupported supplied items and missing objective location data remain outside this first version.

The action is a native secure /use [nocombat,nodead] item:ID, avoiding mutable bag/log indices and gating even bindings to hidden buttons. PreClick outside combat rechecks exact selected quest/item and cursor state; a stale completion, changed item, disabled feature or drag release clears the action instead of retargeting during a click. No Lua item-use call or event-driven use occurs. A secure controller clears the action and hides button/parent for combat/death, then shows only the parent; fresh public out-of-combat work decides whether to show the button again. Protected creation, anchors, movement/drag interruption and attributes defer in combat. Disable cancels queued enable/work, unregisters events and clears/hides the action after combat.

Quest/bag/target/blob/cooldown/zone/world events coalesce through a cancellable 0.12-second timer. Public movement starts cancellable half-second proximity checks; stopping movement, unknown/zero public speed, combat, disable and logout end repeated work. There is no addon OnUpdate or stationary polling. Validate optional event availability and contain registration failures. Persistent additions are only an off-by-default feature flag and normalized position, sanitized with the existing common icon-position validator.

Installed executable re-read October 13: 1.60.1.70338. Thirteen unchanged pinned native/API references support the narrow implementation; ZoidsTools_F QuestItemButton is a read-only behavior reference with existing MIT notice. 43 Lua 5.1 files, identical 0.2.26 TOCs and 8,285 substitute checks pass, with 57 new assertions for optional/default/combat lifecycle, selection and unknown data, carried-only scope, stale clicks/cursor/drag, icon geometry, range/cooldown/tooltip, placement/reset, event coalescing, movement-only work and disable/logout. Native APIs, visual/input/secure driver/keybind action, persistence and taint remain pending. Evidence is under questItemButton in sources.json and .cache/quest-item-button-70338.

## ZoidsTools feature comparison — October 13, 2026

Read-only comparison of current Retail ZoidsTools and ZoidsTools_F module manifests, READMEs and relevant implementations against Suite 0.2.25. Both reference projects retain the user's MIT license. These are recommendations awaiting feature selection, not approved implementations or verified client capabilities.

Suggested order: (1) nearby quest-item action button, (2) modifier-click profession actions, starting with learned Disenchant, (3) player/target/focus castbar dimensions and native preview, (4) zone-based watched reputation, optionally merchant reputation detail, (5) custom learned buff reminders plus reminder-bar scale/lock, (6) searchable chat viewer and opt-in bounded history, (7) recorded raid/instance saves and reset dates within Characters, (8) optional Completionist search/discovery/completion view. Smaller candidates are movement speed in existing minimap stats, spell-flyout directions, optional cinematic skipping and developer diagnostics.

QuestItemButton, ProfessionHelper, Castbars, ZoneReputation, MissingBuffs and Completionist are present in ZoidsTools_F. Retail supplies ChatEnhancements/ChatHistory, VendorReputation, InstanceLockouts, FlyoutDirection, CinematicSkip and Diagnostics references. Suite already supplies basic native chat copying and minimized tracker styling, so those are not new gaps. Existing meters, inventory, macros, camping, vendor/quest automation, minimap, movement, item levels and range coloring substantially overlap both projects.

Use current Forever capability checks and matching source before implementing. Cached native objective-tracker quest-item callers, C_QuestLog distance declarations, C_Reputation watched-faction setter and Vanilla-style group-finder lockout callers support further investigation, not ordinary-addon permissions or live behavior. Castbar previews must respect native management and defer protected geometry. Chat extraction/history needs a separate access/privacy review because current Suite deliberately uses native rendered-text copying without collecting messages. Completionist's provisional quest/pickup database requires fresh provenance and must distinguish unavailable completion data from incomplete quests. Retail Mythic+/Vault, Midnight profession weeklies, expansion filters, talent/BiS data and mount/toy collections should not be imported wholesale. Container opening should start with explicit native clicks unless automatic item-use access is independently established.

## Active-pet food filtering — 0.2.25

The user's native Feed Pet screenshot highlights acceptable bag items, while Suite's earlier generic picker includes thread, recipes, equipment and other unusable items. Matching native ItemUtil.lua's FeedPet context and exact 70338 ContainerFrame.lua both use C_PetInfo.CanPetEatItem(itemID). PetInfoDocumentation declares a boolean result and AllowedWhenUntainted secret arguments; pass only validated ordinary item IDs. Use this runtime active-pet predicate instead of hardcoded family/diet tables, item classes or localized tooltip guesses. Retain the independent carried-item snapshot so acceptable ingredients without their own use spell remain eligible.

Require readable UnitExists(pet) and native predicate availability. A candidate appears only on readable true; false excludes it, while nil/error/restricted results omit it and explain partial/unavailable data. No active pet prompts calling one, complete mismatches say no carried food matches, and missing capability never falls back to all bag items. Check eligibility again when the native menu callback selects a food, preventing stale choices after switching pets. Combat pauses selection. The existing GUI uses explanatory menu titles and the capability fallback cycles only confirmed choices.

Preserve the selected item ID and generated pet-care macro when food becomes incompatible, runs out or no active pet is available; show appropriate restock/change/call-pet feedback rather than replacing food. Scoped UNIT_PET(player) and UNIT_LEVEL(pet) events use existing coalesced work, invalidate stale suitability feedback even when automatic writes are off, and ignore other units. No new watcher/timer/setting/SavedVariables or gameplay action is introduced. Native feeding still requires learned spells and ordinary native cast rules.

Installed executable re-read October 13: 1.60.1.70338. Three unchanged native/API references plus the exact pinned ContainerFrame overlay support this narrow change. 42 Lua 5.1 files, identical 0.2.25 TOCs and 8,228 substitute checks pass, with thirty added assertions for allowed/denied/no-use ingredients, counts, changing pets, stale menu rejection, no/unknown pet, missing/error/nil/secret native results, partial data, invalid IDs, combat and scoped pet events. Source/screenshot/package evidence is under petFoodFilter in sources.json and .cache/pet-food-filter-70338. Corrected native permission, list agreement, feeding and combat/taint remain pending; the supplied screenshots prove the earlier overbroad menu and native highlighting only.

## Collapsible macro categories — 0.2.24

Make the scrolling macro list's General, Hunter Macros (matching class only) and Item Macros headings clickable owned buttons. A minus marks expanded; a plus marks collapsed. Every category starts expanded after reload, and runtime-only state survives ordinary refresh, page navigation and panel reopening during the login session. Categories collapse independently; no new SavedVariables or preference is added. The existing bounded row/header capacity, Suite scrollbar and independent wheel routing remain.

Exclude collapsed rows from scroll-child geometry, clamp the offset and hide the scrollbar when the shorter list fits. Keep the final collapsed header's full 22-unit height included, avoiding clipping from the ordinary six-unit row gap. Preserve all recipe records, creation state, food choices, automatic updates and the selected detail/preview even if its category is hidden. Adding a custom item explicitly expands Item Macros and reveals the new entry. Click state/owned row visibility can update in combat, while geometry uses the existing replaceable post-combat list-layout callback.

42 Lua 5.1 files, identical 0.2.24 TOCs and 8,198 substitute checks pass, with twenty added assertions covering independent collapse/expand, indicators, reduced range, hidden selected rows with preserved details/records, all-collapsed endpoint/header fit, refresh/navigation state, add/reveal and deferred combat geometry. Reuse the previously reviewed scrollbar/button widget sources; source/package evidence is under macroCategoryCollapse in sources.json and .cache/macro-category-collapse-70338. Native clicking, clipped input, font fit and combat/taint remain pending on the installed 1.60.1.70338 executable; running build/Interface were not collected.

## Grouped scrolling macro list — 0.2.23

The user wants all recipes accessible by scrolling within the red-outlined left column, removing Previous/Next, with General and Hunter Macros headings. Add a 164 × 346 owned ScrollFrame/scroll child plus the shared fourteen-unit Suite slider and six-unit gap, fitting the existing 184-unit list column. The detail column, Add item macro, Create/Update and automatic-update controls retain their positions. Precreate the bounded fixed-recipe plus ten-item capacity outside combat; native scroll-child clipping keeps rows within this viewport. Wheel on a row explicitly routes to its own list; thumb/track/wheel reuse the guarded proportional scrollbar. No idle updater, saved preference or new API is introduced.

Lay out General, matching class Macros and Item Macros headers together with their rows in the scroll child. Class row titles omit a redundant class prefix while the detail title retains it. Preserve selection and offset across ordinary refreshes; adding an item reveals the new selection, and shrinking/filtering clamps obsolete offsets and hides unused headers/short-list scrollbars. Geometry and header placement use one replaceable post-combat callback. All class filtering, recipe generation, food choices, ownership protections and macro creation behavior remain intact.

Installed executable re-read October 13: 1.60.1.70338; actual running build/Interface unreported. Reused scrollbar source references retain their reviewed hashes. 42 Lua 5.1 files, identical 0.2.23 TOCs and 8,178 substitute checks pass, with nineteen net additional assertions for complete list access, grouping, independent row/thumb scrolling, selection, add/reveal, short-list clamp/hide and combat layout deferral. Source/screenshot/package evidence is under macroListScroll in sources.json and .cache/macro-list-scroll-70338. Native clipping, input, fonts/fit and taint remain pending.

## Class macro starters — 0.2.22

Start the class-filtered recipe catalogue with the user's two Hunter examples. Misdirection (FS Misdirection) keeps friendly focus → friendly target → existing pet precedence. Pet care (FS Pet Care) revives a dead pet or Shift with no pet; Mend Pet runs in combat, Feed Pet and the selected item outside combat with an existing living pet. The extra live-pet guards prevent the feed/use branches from attempting to run on dead/absent pets. Runtime C_Spell.GetSpellInfo resolves localized spell names for IDs 34477/982/136/6991; nil, failure, restricted names and bodies above 255 bytes prevent writes and preserve previous text. A displayed recipe does not establish that its spells are learned or castable.

Only the matching public UnitClass token reveals a class recipe. Filter UI/pagination/status/automatic refresh, and enforce applicability again at generation, CanSave and Write. Add recipes once when class identity becomes available outside combat; keep saved choices during temporary identity loss. Reuse per-character schema 2 recipe choices and account General-macro ownership checks. Generic recipe order and the ten arbitrary item choices remain intact; class starters do not count against that cap. General game macros remain shared across characters, while other classes cannot automatically rewrite these Hunter starters.

Pet food requires explicit selection. A separate name/count snapshot offers carried items, including ingredients without an item-use spell or player-level qualification; the player picks suitable food rather than inferring pet diet from localized text. This generic selector lists carried items and does not promise that every choice is edible. The macro stores item:ID, retains it when depleted and shows a restock/change reminder in the panel and macro status. Unknown carried names cannot establish depletion. There is no automatic substitution, cast-time popup, new pet watcher or idle polling. SPELLS_CHANGED joins the existing cancellable event work; updates remain independently off by default. The panel reuses existing controls and native creation actions.

Installed executable re-read October 13: 1.60.1.70338. Seven API references are unchanged in the pinned complete source comparison. 42 Lua 5.1 files, identical 0.2.22 TOCs and 8,159 substitute checks pass, with 47 added assertions for class filtering/late identity, native target text, localization/unknown/secret/limit handling, picker/no-use ingredients, depletion/restock, ownership preservation, combat and independent item capacity. Native cast execution, pet feeding cursor/diet/level, UI/input and taint remain pending the testing checklist; no new native outcome is claimed.

Version 0.2.21 improves character dashboard readability using the user-owned ZoidsTools Retail roster as a reference.

## Character dashboard readability — 0.2.21

Reviewed the user's MIT-licensed ZoidsTools UI/ModernWindow.lua warband roster (column definitions and CreateWarbandPage). Forever now uses aligned Character/Level/Gold columns, 14px names and levels, readable guarded class colors and accent strips. Five compact two-line rows retain pagination/search/sorting. Clicking a row selects a separate two-column profession panel with names and ranks; selection stays on the visible page, resets after empty filters and hides unavailable detail. Full identity, profession list and individual record dates remain in hover details. No Retail weekly/vault APIs or data capture code were imported. The shared 0.2.20 custom scrollbars remain in use.

The recording backend and SavedVariables schema are unchanged. Defaults remain off; unknown fields remain explicit and gold totals still omit unknown balances. References, hashes and substitute-font layout evidence are under characterDashboardReadability in sources.json. Checks: 42 Lua 5.1 files, identical 0.2.21 TOCs, 8,112 behavior checks. Native rendering, clipping, selection gestures and combat/taint remain pending on the installed 1.60.1.70338 executable; actual running build/Interface were not supplied.

Build one personal addon containing only the tools the user chooses. Its implementation and GUI must be original, including layout, controls, assets and visual identity. The user explicitly requested Blizzard's meter font and bar artwork on October 7, and their own ZoidsTools inventory tooltip styling on October 8; Suite's settings and window/menu implementation remain original.

## Suite scrollbars — 0.2.20

Replace the mismatched legacy scrollbar in the user's 0.2.19 Overview screenshot with a slim slate track and a proportional teal thumb. Apply the reusable owned control to settings, setup review and macro preview. Keep content geometry, clipping, settings and existing previews intact. Use normalized 0…1 slider input and one guarded actual range/offset controller; reaching the current content maximum must reach the thumb's bottom endpoint. Support native dragging/track clicks and wheel scrolling; hide on pages that fit.

No arrows/Blizzard art, polling, new option, saved data or native scrollbar replacement. Cosmetic layout waits through combat while private scroll/value updates remain usable. **42 Lua 5.1 files, identical 0.2.20 TOCs and 8,105 substitute checks pass**, including fifteen new synchronization/range/input assertions. Installed executable remains **1.60.1.70338**. Native visual endpoint alignment, nested inputs, clipping, combat and taint require the new testing.md checklist; source/screenshot/package evidence is under suiteScrollbars in sources.json.

## Recorded character dashboard — 0.2.19

Implement recommendation six as **Overview → Characters**, retaining the eight sidebar groups and all existing pages. Add `/wfs characters` and `/wfs dashboard`. Show full character names, rulesets, class/level, copper-accurate gold, professions with ranks and profile/bag/bank snapshot dates. Hover retains full text and each field's own capture date. Search identity, realm/ruleset, class or professions with literal AND words; sort by name, gold, level or update, and page five compact cards through the common scroll area.

Independent default-off recording reuses GUID/region-scoped inventory records and their existing complete bag/bank capture. Add profile metadata without replacing old snapshots or enabling search, tooltip counts, the mail helper or bank viewer. Only playing a character can update its stats; unknown fields stay unrecorded and incomplete reads preserve their old values/dates. View existing records with recording off. Gold totals sum known character balances in the current region and show coverage, including when filtering the list. Unknown region cannot expose another scope or imply a zero balance. Keep query/sort/page runtime-only, bounded data, validated event capture, coalescing/cancellation, combat deferral and no idle polling or native frame/action replacement.

Installed executable **1.60.1.70338**; **42 Lua 5.1 files, identical 0.2.19 TOCs and 8,090 substitute checks pass**. Coverage includes 78 new dashboard assertions and expanded existing navigation checks. Source-matched Camelot profession tuple review, widget/event/API hashes, a substitute panel preview and exact package verification are recorded under characterDashboard in sources.json. Native collection, profession availability/ranks, text fit, input, combat/taint and persistence remain pending the new checklist. Inbox/mail-expiration capture remains a separate future feature.

## Whole-addon review — 0.2.18

The October 13 request reviews the entire addon for compatibility, placement and unnecessary duplication. Preserve the current feature set and GUI. Centralize readability/type/default validation in Core instead of maintaining a second partial preference list. Keep valid saved settings and each preference's original default. A restricted root or top-level value cannot reach module lookups or nested access.

Make the low-space discard suggestion follow the existing inventory occupancy rule: missing slot information alone cannot establish an empty slot or a cheapest stack. Require readable nil from the modern occupancy API; otherwise withhold actions until complete event-driven data arrives. Preserve ranking, gray/white scope, blacklisting, native confirmation and drag behavior.

**41 Lua 5.1 files, identical 0.2.18 TOCs and 8,002 behavior checks pass**, including 19 additional boundary assertions. Load order, module calls, events, XML/assets and package inputs are reviewed; lexical heuristics find no unused locals, unreferenced named methods or substantial exact duplicate functions. Existing independent modules and shared helpers remain appropriate. No feature, setting, event, timer, global or saved schema is added. Full native compatibility still requires the combined in-game checklist.

## Action-bar-style player buff icons — 0.2.17

The user's two images request removing the gray inset/bevel and filling the Suite outline like its action-bar icons. Use the same 0.06…0.94 crop on the existing native buff Icon, without resizing or moving its rectangle. Keep the **Player buff borders** switch and existing player-only main-HUD scope. Native timers, counts, assets/opacity, tooltips, right-click behavior and excluded aura displays remain authoritative. Capture readable original UV corners outside combat and restore them exactly whenever the style releases a slot or is disabled, including combat reuse; unknown snapshots stay native. No extra setting, asset, hook or worker. **41 Lua 5.1 files, identical 0.2.17 TOCs and 7,983 substitute checks pass**; corrected native rendering/taint remains pending testing.md.

## Header search and close alignment — 0.2.16

Align the X and Search settings on one horizontal centerline. Both remain 30 units tall. Lower X by eight units and attach the search field to its left edge with the existing 12-unit gap. Preserve all styling, input and search/close behavior. **41 Lua 5.1 files, identical 0.2.16 TOCs and 7,964 existing substitute checks pass**. Native fit remains pending the testing.md checklist.

## Discard button layering — 0.2.15

Lower the discard button from DIALOG to **LOW**, at **frame level 1**, following the user's bank screenshot. Ordinary windows should cover it, including their input areas. Preserve its 48 × 48 size, movement, saved placement and item actions. Change no other UI layer or preference. **41 Lua 5.1 files, identical 0.2.15 TOCs and 7,964 existing substitute checks pass**. Native overlap/input remains pending testing.md.

## Player HUD buff borders — 0.2.14

The October 12 request applies only to the character's main top-right beneficial aura icons. Add a fine teal outline around the existing native icon rectangle, with no crop, size change or extra input layer. Keep native durations, stacks, fading, tooltips, right-click cancellation, positioning and Edit Mode behavior. Debuffs, weapon enchant borders, private aura anchors, consolidated controls and player/target-frame aura displays stay native. Native buff Edit Mode examples may show the outline; another unit/vehicle or unreadable classification cannot receive it.

Use a separate default-off **Player buff borders** switch under **Combat & Bars → Other Bars**, discover only BuffFrame's own ordinary slots and draw Suite-owned edge textures. Observe the completed native UpdateAuraButtons method without reading aura payloads or querying auras. Prepare slots outside combat; existing edge visibility follows combat fills/reuse and new construction waits. Disable cancels work/events and hides only owned edges. Add no polling, asset, CVar or secure input change. **41 Lua 5.1 files, identical 0.2.14 TOCs and 7,964 substitute checks pass**; native appearance, input, visibility access and taint remain pending testing.md.

## Draggable bag space button — 0.2.13

Increase the icon button to **48 × 48**, with a **44 × 44** icon, and allow ordinary left-drag anywhere on it. First use defaults to the screen center. Save completed placement across reloads/characters as guarded normalized coordinates, keeping the button clamped on screen and restoring its center-relative anchor after release or screen/UI-scale changes. A drag release must not discard or blacklist an item; a fresh press restores the original left/right click actions. Keep all instructions in the tooltip. No separate header, unlock mode, resize control or per-frame updater.

Add only the account-wide bagSpacePosition field and two layout events to the existing optional controller. Preserve the last completed position when a drag is interrupted, and defer movement/anchor rollback until combat ends. **40 Lua 5.1 files, identical 0.2.13 TOCs and 7,896 substitute checks pass**, including 48 new safety/placement assertions. Native movement, actual mouse-event ordering, appearance, taint and persistence remain pending testing.md.

## Compact bag space button — 0.2.12

The user rejects the large alert card shown in their October 12 screenshot. Use one centered **36 × 36** action-bar-style button with the offered item's **32 × 32** icon and a fine teal border. Show no slot count, name, price, count or instructions on the face. Put all details and left/right-click guidance in the normal item tooltip. A backpack icon represents loading/unavailable/no-eligible states; disclose those states only on hover. Keep the existing gray/white selection, two-slot threshold, native confirmation and shared blacklist. Refresh the currently owned tooltip through existing events and preserve another tooltip owner. No new preferences, assets or workers. **40 Lua 5.1 files, identical 0.2.12 TOCs and 7,848 existing substitute checks pass**; native compact rendering/hover remains pending testing.md.

## Settings close button border and hover — 0.2.11

The October 12 screenshot and request add a thin border to the main settings X. Keep the existing compact square hit area and position; use a slate resting fill with muted outline/text, then a brighter fill and teal outline/X on hover. Reset the style on mouse leave and hide. Closing and header dragging retain their existing actions. No setting or other UI feature changes. **40 Lua 5.1 files, identical 0.2.11 TOCs and 7,848 existing substitute checks pass**. Native border fit, hover/reopen and close input remain pending the small testing.md checklist.

## Low bag space discard suggestion — 0.2.10

The October 12 request adds an original slate/teal button centered on screen whenever regular carried bags have **two free slots or fewer**. The user clarifies **gray or white items only**. Display the cheapest complete eligible stack by total vendor sale value, with its icon, name/count, value and tooltip. Skip quest items, locked stacks, no-vendor-value items and blacklisted item IDs. Specialized/reagent slots and banks are outside the general-slot count. A low-space message remains visible when no eligible stack exists; unresolved data must not produce a misleading cheapest offer.

**Left-click** rechecks the exact current instance and opens the game's deletion confirmation. Only the user's native Accept can delete; Suite never deletes automatically or accepts the popup. **Right-click** saves an account-wide item-type blacklist and immediately offers the next eligible stack. All existing cursor payloads and other dialogs block preparation. Changed instances/minima, native rejection and combat must keep items safe; cleanup must preserve unrelated cursor items and dialogs. Add **Low bag space alert** and **Clear trash blacklist** under **Bags & Gear → Bags & Bank → Low Bag Space**, searchable through the existing settings index. The toggle starts off and vendor selling remains independent.

Use coalesced cancellable event work, bounded once-per-ID asynchronous metadata requests, readable-value guards and combat-deferred private construction. Add no idle updater, dependency, asset, named global or native handler replacement. Installed executable is **1.60.1.70338**; matching references and package evidence are under bagSpaceAlert in sources.json. **40 Lua 5.1 files, identical 0.2.10 TOCs and 7,848 substitute checks pass**. Native confirmation API permissions, central rendering/input, taint and saved blacklist persistence require the new testing.md checklist before verification.

## Collapsible settings sections — 0.2.9

The October 12 request makes existing settings categories independently collapsible. Click anywhere on a teal heading to hide/show its settings; use a small plus/minus and slate hover feedback. Close gaps between remaining categories and clamp scrolling. Include the final section's detailed controls on meters, action bars and progress pages. Start expanded and remember choices only for the login session; feature preferences stay independent. Search automatically expands its target section, including detailed controls, while unrelated sections retain their state. Existing generation cancellation prevents a deferred outline from returning after collapse/navigation.

Use title case for sidebar, tab and section names, including **Maps & Layout**, **Launcher & Addon Buttons** and **Map Appearance**. Keep the original GUI palette, control labels, feature defaults, actions and page identities. Add no saved state, timer/event, asset, named global or dependency.

**39 Lua 5.1 files, identical 0.2.9 TOCs and 7,707 substitute checks pass**, including 22 focused integration assertions. Expanded/collapsed previews were inspected using substitute fonts; installed executable remains **1.60.1.70338**. Source/screenshot/preview/package evidence is under settingsSections in sources.json. Native behavior needs the new smoke test before verification.

## Compact inventory results — 0.2.8

The October 12 screenshot and feedback request a slender, less invasive cross-character results popup. Remove the heading and persistent record/date footer. Use 300-unit-wide results, 28-unit rows, 20-unit icons and four rows per page. Show item name and character owner/You; full context, bag/bank quantities, recording dates and disclosures remain on hover. Soften the border and keep the X outside row hit areas.

Fit the popup to visible results, including the final page: ordinary no-match state is a 180 × 28 strip, one result is 300 × 36, four are 300 × 120 and a full paged result is 300 × 140. Loading names get a short wider strip; necessary incomplete-result warnings and paging alone may add a bottom strip. Retain independent defaults, existing side-placement behavior, native search/input, item metadata handling and combat guards without new settings or saved data.

**39 Lua 5.1 files, identical 0.2.8 TOCs and the existing 7,685 substitute checks pass**. No new low-impact layout tests are introduced; two old presentation/paging expectations are updated. A schematic preview from source dimensions was inspected with substitute fonts/icons. Installed executable remains **1.60.1.70338**; API/source, screenshot, preview and package evidence are under inventorySearchCompact in sources.json. Native size, text fit, paging, input and taint still require the new checklist.

## Inventory results beside bags and banks — 0.2.7

Move cross-character search results from below the field to a popup beside its owning bag or bank, following the user's October 12 request. A saved right-half position puts results on the left; a saved left-half position puts them on the right. Use active Window tools placement when valid, otherwise guarded live geometry with effective-scale conversion. Top-align the outer edges with a small gap and retain the existing screen clamp. Treat the native shared field's current parent as authoritative for backpack/combined-bag ownership; extend the same behavior to real and saved banks.

Keep the existing independent option, six-row pages, native search/filter behavior, counts, dates, modified links and X/outside/empty/hide/combat dismissal. Window save/restore/reset notifications only reposition a matching visible popup; no idle updater, new timer, saved preference, global, asset or dependency is added. If geometry is unavailable, dismiss the popup. The settings search remains unchanged.

Installed executable is **1.60.1.70338**. **39 Lua 5.1 files, identical 0.2.7 TOCs and 7,685 substitute checks pass** with 28 additional assertions. Current documentation and package/source evidence are under inventorySearchSide in sources.json. Verify actual side spacing, large/scaled bags, screen clamping, native input and combat/taint through the new live checklist before calling it verified.

## Organized settings and search — 0.2.6

The October 12 screenshot shows the eighteen-link sidebar and Windows page's seventh control extending below the panel. The user requests professional cleanup, combining related features and a settings search. Retain the original slate/teal visual identity, branding, existing preferences, independent modules and actions. Replace the flat navigation with eight destinations: **Overview**, **Maps & layout**, **Bags & gear**, **Combat & bars**, **Everyday tools**, **Mail & chat**, **Macros** and **Setup guide**. Related leaf pages are tabs within their group; last-tab selection is runtime-only. All eighteen former destinations remain, plus **Bags & bank**. Move bank recording/view/keybind, sorting and cross-character search out of Windows and group them with inventory tooltip counts. Windows now contains only movement and reset.

Use concise page titles, section captions, measured/wrapped help, a slightly wider 800 × 680 panel, and a clipped common scroll area with fixed header/navigation/footer. Reuse and center existing detailed controls after the page's ordinary rows. Short pages hide their unused native scrollbar. The five-step setup retains its independent layout, staged choices and discard/apply behavior; browsing/searching never applies its draft. Existing feature defaults, native layouts, macros and SavedVariables schema remain unchanged.

Header search indexes dedicated-page switches/actions and detailed font, progress, map, chat, macro and meter controls. Deduplicate repeated switches, match bounded literal case-insensitive AND words with context/synonyms, paginate results, and support click/Enter navigation. A result scrolls to and outlines its actual control without pressing it or assigning keyboard focus. Empty/Escape/clear/navigation/hide dismiss results. Highlight construction/anchors defer in combat and stale reveals cancel on navigation/closing. No search timer, idle updater, external data lookup or new global is added. `/wfs bags` now opens Bags & bank; other feature shortcuts retain their leaf targets.

Installed executable remains **1.60.1.70338**. **39 Lua 5.1 files, identical 0.2.6 TOCs and 7,657 substitute checks pass**. The new GUI coverage adds 264 assertions; ten obsolete per-sidebar-link assertions are replaced by group navigation coverage. Layout previews from actual substitute UI definitions were rendered and inspected for Windows, Bags & bank, Missing buffs and Minimap. They validate development layout intent with substitute fonts, not native rendering. Reference/screenshot/package evidence is under settingsCleanup in sources.json; use the new live checklist before claiming native appearance/input/taint verified.

## Cross-character bag and bank search — 0.2.5

The October 12 user chooses account-wide item search primarily through the existing bag and bank search fields, with an ownership dropdown rather than a separate search GUI. Add **Windows → Search across characters**, independently default off. `/wfs bags` opens that page. Support native BagItemSearchBox, BankItemSearchBox / BankFrame.BankItemSearchBox, and the existing Suite saved-bank search. Keep native text synchronization, filtering, focus, scripts, anchors, letters limit and clear-button behavior. One slate/teal dropdown follows the active field; use six rows per page, arrows/wheel, item icons, owner full name/context, current-character label and separate bag/bank counts. Hover shows public base-item information and per-location recording dates. Native modified item-link clicks are optional; plain clicks perform no item operation.

Search localized item names/types/subtypes and equipment-slot labels with literal case-insensitive AND words; exact numeric item IDs also work. Native slot-filter syntax stays native, so its advanced filters need not match the dropdown's simpler search. Index complete recorded inventories in the current region by item ID and GUID, with shared banks counted once. Reuse known GUID mail identities for legacy names; fresh native full names remain authoritative. Unknown locations and inaccessible counts are omitted, and variants are combined. No equipped-item, guild-bank, mail-item or auction inventory is claimed. No standalone search page, new sidebar category, automatic transfer or third-party bag adapter is added.

Enable shared Inventory recording when either search or tooltip counts is on; turning one off does not disable the other. Reuse complete bank snapshots without duplicate counting. Keep metadata/indexes/request flags runtime-only, resolve public item data asynchronously in finite 32-request batches, and show unavailable/loading names without retry polling. Debounce into one cancellable worker; defer discovery/construction/anchoring outside combat and dismiss on combat entry, empty input, Enter/Escape, X, outside click, hide, disable and logout. HookScript success must be readable true; restricted/unknown outcomes cannot activate callbacks. Preserve native tooltip ownership during cleanup. Setup-guide suggestions remain unchanged.

Installed executable re-read October 12: **1.60.1.70338**; running build/Interface remain uncollected. **38 Lua 5.1 files, identical 0.2.5 TOCs and 7,403 substitute checks pass**, with 93 new assertions. Reference hashes, scoped matching-build evidence and package verification are under inventorySearch in sources.json. Native field discovery, rendering, item permissions, inputs, taint and disk persistence require the new testing.md checklist.

## Pet bar selected icon — 0.2.4

The October 11 paired pet-bar screenshots expose a selected command obscured by a solid teal tile while custom bars are enabled. Keep the existing independent action-bar skin and native pet state behavior. Move the soft hover/pressed/checked color into each existing state texture's intrinsic fill, preserving native vertex opacity. Native command selection and Attack opacity changes must leave icons visible, including in combat without a queued reskin. Restore original state RGB with the latest native opacity when disabling. Missing initial color-fill/alpha capability keeps the whole button native; later restricted opacity is never guessed or overwritten.

No new control, asset, hook, event, timer or polling is added. The strict shared-alpha regression fails against the previous skin. **37 Lua 5.1 files, identical 0.2.4 TOCs and 7,310 substitute checks pass**, including 27 new assertions. Installed executable is **1.60.1.70338**; exact source and screenshot evidence are recorded in sources.json. Actual corrected appearance, pet commands/autocast, normal active-action feedback and combat taint require the new testing.md retest. The original native-alpha preservation requirement remains; its implementation now accounts for the shared vertex alpha channel.

## Clicked missing buff requests — 0.2.3

The user explicitly chooses a request **only on clicking the missing buff icon**. Left-click release on a gold incoming Ask icon sends `Missing [spell link]` to instance group chat, otherwise raid, otherwise party. Right-click continues hiding the family; normal self/group/poison buttons retain their actions. Never send on appearance, events, refreshes or timers, and never queue a retry after failed/loading/restricted data.

Recheck current missing auras, eligible providers and a complete freshly learned spellbook. Own learned families cannot become incoming requests merely because their personal display filter is disabled. Require readable native group membership, an unrestricted chat predicate and a bounded matching native spell hyperlink. Limit requests to thirty seconds per family and three seconds globally, including failed native send attempts. Local feedback handles unavailable chat, stale entries, missing links and throttling. Keep the module default off; add no independent setting, event, timer, asset or global.

The user reports the compact bar looks much better. Installed executable remains **1.60.1.70338**; running build/Interface and native chat delivery/taint remain unreported. **37 Lua 5.1 files, identical 0.2.3 TOCs and 7,283 checks pass**, including click-only capture, routing priority, throttling, stale/secret/missing data, learned-own suppression and native rejection containment. Source/package evidence is under missingBuffRequests in sources.json. Follow the new click-request smoke test; the earlier 0.2.0 reminder-only behavior is superseded for gold left-clicks.

## Compact missing buff bar — 0.2.2

The user requests a content-sized box with a centered single buff/title and a wider centered layout for two or more buffs. Remove the fixed 186-unit minimum, fit the measured title/current icon row with padding, and expand/shrink as reminders change. Keep each row centered, including an incomplete final row after the eight-icon wrap. Preserve the existing icon size, caption room, saved placement, drag/reset, secure combat deferral and native actions.

The supplied screenshot establishes visible native rendering of the prior one-buff bar; corrected layout, casts and taint are not yet observed. **37 Lua 5.1 files, identical 0.2.2 TOCs and 6,900 existing checks pass**. No new preference/event/timer/asset/global or test is added. Installed executable: **1.60.1.70338**; source/screenshot/package evidence is under missingBuffLayout in sources.json. Use the new compact layout smoke test.

## Missing buff activation event fix — 0.2.1

The October 11 live activation error rejects obsolete **LEARNED_SPELL_IN_TAB**. Remove it and retain modern SPELLS_CHANGED/spell-data completion for learned-cache refresh. Audit the remaining twenty-one events, gate registration on readable true C_EventUtils.IsEventValid when available, and contain optional registration failures when the query is missing. Preserve enabled state, family choices, positioning, secure combat handling and all buff behavior.

The original error is reproduced by a strict substitute before the correction. **37 Lua 5.1 files, identical 0.2.1 TOCs and 6,900 behavior checks pass**, including rejected/unknown validity and continuing subscriptions/activation. Installed executable: **1.60.1.70338**; source evidence is under missingBuffEventFix in sources.json. Corrected live activation and the original casting/rendering/taint checklist remain pending.

## Missing buff bar — 0.2.0

The October 11 request adds an independent, default-off **Missing buffs** page and slate/teal upkeep bar. `/wfs buffs` opens its settings. Show readable missing self buffs outside rested areas, missing buffs the player can supply to eligible party/raid members, class maintenance such as aspects/armor/auras/totems/shields/imbues/poisons, and gold reminders for buffs present teammates can supply. The user chooses usual class-and-level inference for incoming reminders; disclose it and infer no talent/racial spellbook. Never send messages automatically.

Four filters separate self group buffs, outgoing group buffs, incoming suggestions and class upkeep. Choose actual own ranks from the learned native spellbook. Group alternatives into upkeep families, accept any active alternative, and let right-click cycle learned actions then hide a family. Incoming right-click hides the family. Outgoing direct casts target the first listed missing member; party-wide actions self-cast and remain in the raid subgroup. Active toggle auras offer passive coverage reminders so a click cannot turn them off. Rogue reminders cover equipped weapon hands, require a chosen carried poison, and distinguish native Imbue from oils/permanent enchants.

Hide the bar in rested areas, combat, death or when nothing readable is missing. Unknown/restricted/incomplete data never establishes absence. Native secure buttons own hardware casting; revalidate stale targets, auras, coatings and subgroups before a click. Save header placement and provide preview/reset; defer all protected construction/movement/layout/attributes through combat. Use native events and one cancellable coalesced worker, with no idle polling. Spell and item loading retry through their native completion events.

The initial maintained catalogue covers long-lived class upkeep and group buffs; temporary combat procs/cooldowns and hidden talent knowledge are outside it. Ordinary poisons use localized native spell names; extra Forever poisons retain an English-name fallback. Installed executable: **1.60.1.70338**. **37 Lua 5.1 files, identical 0.2.0 TOCs and 6,865 substitute checks pass**. Native coverage, cast permissions, poison/imbue classification, rendering, taint and persistence remain pending the testing.md checklist. No Enhance QoL implementation, data table, assets or layout was copied.

## Action-button cooldown fit — 0.1.99

The October 11 cooldown screenshot prompts a fit correction within the existing optional **Suite action bar skin**. Normal, charge and loss-of-control widgets cover the complete cropped native icon instead of retaining another native artwork inset. Capture and restore readable original geometry; unsupported/restricted snapshots keep the whole button native, while absent optional layers are allowed. Preserve native timing, swipe/edge artwork and colors, countdown visibility and input. No new preference or cooldown data reader is added.

Reuse existing native art hooks, cancellable discovery and combat deferral. Active records reapply geometry after deferred small-button art updates; all fitting/restoration occurs outside combat. Installed executable: **1.60.1.70338**; reference provenance is recorded in sources.json. **35 Lua 5.1 files, identical 0.1.99 TOCs and 6,646 substitute checks pass**, with 291 new assertions. Native visual fit, action permissions and combat taint require the new testing.md checklist; the supplied screenshot establishes the prior issue only.

## First-login setup guide — 0.1.98

The October 11 request adds five pages in the original Suite panel, informed by a read-only review of ElvUI 15.26's installation flow. Keep Suite's own wording, controls, styling and implementation. Place **Setup guide** immediately below Overview and support `/wfs setup`. Offer it once at the account's first login after adoption, including existing installs; existing preferences remain the starting point. Closing or choosing Later dismisses that welcome without applying anything and the guide stays available to rerun.

| Step | Main choices and guidance |
| --- | --- |
| Everyday | Native Auto Loot and modifier explanation; Quick loot; repair/funding; gray junk and Slow/Instant consequences; quest pickup/turn-in/gossip and Shift bypass; native bag sorting |
| Bars & HUD | Action/progress/bag/micro skins, range color, short bindings, class health colors, tracker and meters; arrange native HUD in Edit Mode; meter movement/lock guidance |
| Map & windows | Square minimap, stats, drawer, launcher, world-map reveal and supported window movement; empty header dragging, Ctrl-scroll resizing and Ctrl-right-click reset outside combat |
| Items & social | Gear icon/tooltip/character/player levels, recorded inventory and bank snapshots, mail/recipient memory, chat and camping; alt logins/bank visits and explicit macro creation |
| Review | Scrollable actual changes by step, Back, Later and explicit Apply setup; further controls remain in the sidebar |

All 36 choices are independent and staged until the review is applied. Page-local suggestions are optional; original addon defaults remain unchanged. Suggested junk selling, instant sales, gossip, bag sorting, map reveal, drawer, meters, player inspections, recipient memory, chat and camping stay off. Suggested Slow sales and Personal funding disclose consequences without enabling junk sales. Native Auto Loot is an explicit one-time setting, with metadata checks and confirmation; it is never forced at login. Unavailable game settings can be left unchanged while completing the rest. Only edited preferences commit, followed by one Suite.Apply; advanced choices and saved layouts remain intact.

Native bar positioning, extra bar visibility/bindings, font details, meter appearance, stat comparisons and macro recipes use their existing dedicated/native controls rather than inventing role presets or replacing secure layout management. First guide creation waits outside combat; applying never queues itself through combat. No new timer/hook/global is added. Account welcome/completion state is sanitized and drafts are never serialized. **35 Lua 5.1 files, identical TOCs and 6,355 substitute checks pass**; in-game appearance, action permissions, taint, coexistence and persistence require the new checklist.

## Rested XP layering — October 11

The paired user screenshots show rested XP coloration missing from Suite's bar while the native endpoint marker remains. Place the slate background below Blizzard's prediction on the native bar wrapper, anchored to the visible fill bounds. Retain native earned/rested colors and geometry; keep Suite's teal border and optional sections above the fill. Capability failures preserve native presentation, and existing combat deferral, custom dimensions and values continue unchanged. Add no setting or additional rested-data reader.

The previous implementation fails the new native frame/layer regression; the correction passes the full addon checks. This is a rendering-order repair. In-game rested/no-rested/overflow, resizing, native updates and combat retests remain required before calling the corrected appearance verified.

## Mail alt surname backfill and active-character filter — 0.1.97

The October 11 follow-up asks for previously logged-in alts' missing surnames and omission of the active character. Fill incomplete recorded GUID contacts automatically from native account-character autocomplete on opening/refreshing Send Mail. Require a known matching ruleset, same-server account priority, exact first-name match and a unique readable full name not already associated with another recorded identity. Exclude Battle.net/friend/other-server matches; ambiguous/unavailable/restricted/truncated responses keep the explicit save/login fallback. Preserve original metadata and removal markers. This supplements the earlier current-player recording fix rather than inventing surnames from historical login records.

Use bounded event-driven lookups and one attempt per contact per refresh generation through existing mail work, with no idle updater, new preference or remote roster search. Combat and helper-off/memory-only defer or skip lookup. Native user input, autocomplete UI, compose fields, manual delivery and recipient memory retain their behavior.

Hide the active toon from displayed rows, literal search, sorting/paging and contact counts while retaining its account record for other characters. Match by current GUID and protect current-name manual aliases. This supersedes the earlier visible You-row decision; switching to an alt should reveal the previous character with its captured surname.

Validation: **34 Lua 5.1 files, identical 0.1.97 TOCs and 5,885 substitute checks pass**, including 239 additional assertions for the screenshot roster, conservative matching, response limits/retries/errors/secrets, active filtering/switching/removal/persistence and combat/disabled behavior. Native account autocomplete permissions/data, actual corrected list/delivery and taint remain pending in the [new checklist](testing.md#mail-alt-surname-backfill-and-active-character-filter--0197).

## Mail full names and rulesets — 0.1.96

The October 11 user test/screenshot shows this client's native two-part recipient names and Suite's incorrect first-name/realm model. Mail contacts now display and fill **First Last** with no realm suffix. Search both name parts and Ruleset; sort Name, Ruleset or Level. Current characters capture UnitName's surname return, while already combined names remain intact. New manual saves require a full name. The optional recipient-memory path restores that full name after a successful native reset.

Schema 2 migrates existing contacts and removal markers. Preserve account-character identity by regional GUID; manual contacts use full-name/ruleset keys. Keep incomplete old records visibly marked Add last name. Clicking one focuses To with its first-name prefix for native autocomplete; explicitly saving the chosen full name completes that selected record and retains metadata. Logging into an alt also completes it. Removed contacts remain absent during stale inventory seeding and reload, unless deliberately saved or logged in again.

Rulesets are informational, derived from the client's Hardcore flag or recognized public server labels. PvE, PvP, Hardcore, RP and combined RP variants have concise labels when identified; unrecognized variants show Unknown ruleset. The observed ClassicBetaPvE label maps to PvE, while other released variants and delivery boundaries remain untested. Manually saving a new recipient records the current context; saving a selected contact retains its own known ruleset. Do not display an invented server catalog or block cross-ruleset mail. Native delivery rules, autocomplete, focus, compose controls and manual sending remain native. No new preference, polling or foreign saved-data access is added.

Exact-build Camelot name handling and native mail/API references were reviewed. **34 Lua 5.1 files, identical 0.1.96 TOCs and 5,646 substitute checks pass**, including 61 additional assertions. Corrected live name filling/rendering, permissions, disk persistence, combat taint and cross-ruleset delivery need the [new mail checklist](testing.md#mail-full-names-and-rulesets--0196). This supersedes the earlier Name-Realm/Realm-search identity decisions.

## Hide unrecorded inventory locations — 0.1.95

The October 11 request replaces Bank: ? with an omitted bank label until a complete snapshot is recorded. Apply the same rule to unrecorded bags: character rows show only positive recorded locations, with commas only between visible counts. Keep Known total for incomplete inventories, including an unrecorded shared bank, and keep confirmed-empty locations omitted. A bank visit reveals its recorded positive count. Settings help explains the hidden locations and recorded subtotal; no toggle, saved-data migration or tracking change is needed. This supersedes earlier question-mark guidance.

Validation: **34 Lua 5.1 files, identical 0.1.95 TOCs and 5,585 behavior checks pass**. Covers unknown/unreadable bank data, bank-only recorded holdings, later bank visits and shared-bank placeholders. The screenshot's running build/Interface were not supplied; corrected live appearance and counts remain pending.

## Native progress values in combat — 0.1.94

The user's repeat combat failure supersedes the earlier visibility-only implementation. With the progress skin and Always show values enabled, use Blizzard's native always-show progress preference so native hover/combat handlers retain the text even when Suite cannot change the bar frames. Keep counters, formatting, hover input, tooltips and bar layout native. This preference also covers other native progress types when displayed.

Capture the previous native preference, retain it across reload/reinitialization, observe later native setting requests and restore it on either option's disable or logout. Use validated 0/1 values and native CVar permission metadata; check write success. Prepare observers outside combat; existing prepared nonsecure setting changes can run in combat. New setup, restricted settings and layout still defer. Cancel logout work and never reapply the temporary preference during shutdown. No new user option or idle updater is added; the saved restoration field is internal.

The prior ancestor-predicate gap is reproduced offline. **34 Lua 5.1 files, identical 0.1.94 TOCs and 5,578 checks pass**, covering native combat visibility, safe preference ownership/restoration, missing/secret/restricted capabilities, failed writes, reload and logout. On October 11, after the update, the user confirms the stats now stay visible in combat and work correctly. Combat text visibility is user-confirmed; running build/Interface, current-number updates, preference restoration, persistence and a dedicated combat taint/error audit remain unreported.

## Area-only map cover — 0.1.93

The October 11 Teldrassil screenshots confirm the desired zone treatment but show missing sea/tree/parchment art outside the zone. Limit the tooltip-like dark cover to the alpha silhouette of each missing area. Draw owned black-tinted copies of its terrain tiles at 65% opacity beneath the revealed terrain, using the same file IDs, offsets, padded UV crops and source transparency. Native discovered art remains above both owned layers. Zero terrain opacity retains only the shaped cover; fully explored maps have no owned cover. Keep the existing independent toggle and saved terrain opacity.

Remove the whole-canvas cover and all shared base-tile/canvas/overscroll suppression, color tracking/restoration and related observers. Preserve surrounding native art without guessing zone rectangles or artwork boundaries. Prepare matching bounded 47-texture terrain and cover pools outside combat; retain native pin transforms/loading/fade and one-time masks. Existing unprotected resources update in combat, while new/restricted affected setup waits. Unrelated protected/secret native background art remains untouched and does not block reveal.

All 34 Lua files, identical TOCs and **5,508 combined checks pass**, preserving the concurrent shared-macro change. Regression fixtures forbid shared-background reads/writes and canvas-sized covers, and verify area tile alignment, native cosmetics, exploration/zero/unknown maps, combat reuse and cleanup. The user screenshots are live evidence of the prior regression; the corrected appearance, edge coverage/loading, controls, permissions and taint require the new smoke test. This supersedes the 0.1.91 whole-base fog replacement.

## Shared General macro recognition — 0.1.92

The user requests that macros created on one character automatically be active on their other characters because they already exist in General. Recognize all five fixed Suite recipes and up to ten existing chosen-item recipes at initialization, login/application and coalesced macro refreshes. A unique General name must match Suite's confirmed account ownership body, using the existing line-ending normalization. Recognition itself creates or edits no game macro; with the shared **Keep created macros current** preference on, the existing updater immediately uses the current character's supplies and choices without another Create click. Updates off retains shared text while still recognizing the recipe.

Retain each character's saved item/combat choices and fresh fixed-recipe defaults. Newly imported chosen-item variants and unfinished item choices without a selected item use the item in their confirmed single-action generated body. Imports retain their shared serial/name and appear in serial order. Advance new names past all recorded shared item serials, including missing or locally omitted macros. Character schema 2 remembers deliberate local item-choice removals across reloads; the General macro and other characters' choices remain available. Keep the ten-item limit and explicit creation for absent/new macros.

Unowned names, external edits, duplicates, character-only/missing macros and unreadable/incomplete lists cannot establish new ownership. Combat defers discovery; native editor visibility continues pausing writes. GUI wording explains create-once recognition. Initial macro validation passed all 34 Lua files, identical 0.1.92 TOCs and 5,310 substitute checks. The final combined workspace recheck, including the unfinished-item regression and concurrent map correction, passes 5,508 checks. Character switching, native persistence, item execution and combat taint remain pending live tests.

## Map combat and tooltip cover — 0.1.91

The October 11 follow-up requests combat map reveal and confirms a dark translucent cover for unexplored-area fog. Keep the existing independent toggle, saved 0–100% terrain opacity and initial 60%. Replace supported parchment with a tooltip-like slate surface beneath revealed terrain; native discovered ARTWORK stays above it. At 0%, show the cover alone. Disable restores native fog; whole-window opacity is unchanged.

Prepare the maximum supported map's terrain texture count and slate surface outside combat. Reuse native pin transform/loading/fade and one-time masks. Combat navigation, exploration refresh, opacity and re-enabling can use existing resources only with readable unprotected widget predicates. Defer new setup, native resources/observers and restricted operations; keep current preferences for post-combat refresh. Native geometry, masks, parentage, scripts, data/discovery and controls remain native.

Suppress guarded base-tile/canvas/overscroll vertex alpha, capture native changes and restore latest readable colors on disable/hide/removal or unsupported map data. Preserve restoration through temporary protection, invalidate hidden snapshots and defer newly protected owned cleanup. Coalesce detail/exploration refresh with the existing cancellable worker, without an idle updater or new assets/settings/globals. All 34 Lua files, identical 0.1.91 TOCs and **5,216 substitute checks pass**. The bounded pool contains 47 terrain textures plus one background per pin. Matching source hashes are rechecked; appearance, loading, combat permissions/taint, controls and persistence require live smoke tests.

## Combat values and minimap drawer — 0.1.90

The October 11 combat report requests continued passive UI access. Keep **Always show values** active through native XP/reputation/honor hide requests using only existing readable, unprotected labels and their native text. Capture explicit native visibility requests so immediate corrections preserve restoration through nested setters. Previously prepared labels can toggle visibility in combat; new setup, protected/unknown widgets, native formatting and bar layout remain deferred.

Allow the already prepared addon drawer to open/close and stay open in combat without recollecting or moving buttons. Keep original click/menu/tooltip dispatch, outside-click/Escape and left-click dismissal. Check the panel and collected descendants' protection/ownership; unsafe visibility changes wait until combat ends. Stop the drag updater at combat entry, retain cached layout and defer creation/collection/reparenting/resize/restoration. Buttons remain subject to their owner's combat permissions. No new toggle or broad guard removal is needed.

All 34 Lua 5.1 files, identical 0.1.90 TOCs and 4,936 substitute checks pass. Native combat access, visual updates, ordinary-addon permissions, protected-descendant propagation and taint require the new smoke test. This supersedes earlier blanket combat deferral for progress visibility and forced drawer closing.

## World map reveal — 0.1.89

The October 11 request adds **World map**, `/wfs map` and `/wfs worldmap`, an independent default-off **Reveal unexplored areas** toggle and **Unexplored area opacity**. The account-wide slider ranges from 0% (native fog) to 100% (fully visible), initially 60%, in one-percent steps. Revealed unexplored terrain fades; explored regions keep their normal appearance. Opacity can be chosen while off without enabling reveal. Exploration credit still requires visiting areas. Sixteen 32-unit tabs with 33-unit spacing clear the stamp; controls clear the footer.

Use original Suite rendering and generated Blizzard build-70338 terrain, without copying Leatrix/Enhance QoL code, data or assets. Reusable anonymous BACKGROUND textures share the native exploration pin's zoom, loading, fade and masking beneath explored ARTWORK. Match art IDs/exact first-layer geometry and omit explored overlays using readable geometry/file IDs. Unknown/restricted/mismatched maps retain native terrain. The build supplies 1,073 complete overlays / 1,739 files across 84 art IDs; eight tileless records are omitted and documented. Construction/layout/assets defer combat; own cosmetic hiding removes obsolete terrain on combat map changes. Observe native refresh/removal/acquisition and visibility with cancellable discovery; disabled callbacks stay inert, without idle updates.

All 34 Lua 5.1 files, identical 0.1.89 TOCs and 4,884 substitute checks pass. In-game coverage, rendering/controls, combat taint and reload/relog/restart persistence require the new map smoke test.

## Bag bar pixel borders — 0.1.88

Extend the same border correction to the bag bar after the user reports matching fading there. Share physical-pixel sizing and owned pixel-layout/raster configuration between both button skins, keeping their existing insets and independent toggles. Preserve native bag icons/masks, counts, highlights, click/menu/drag behavior, assets, scale, geometry and Edit Mode. Native bar/button scale hooks and shared conditional display/UI-scale events refresh existing textures through the cancellable worker, with combat deferral and guarded geometry. No new setting, duplicated implementation, dependency, global or idle scanner.

All 32 Lua files, identical TOCs and **4,621 checks** pass, including 315 new bag-border assertions. All 50 matching source references are rechecked; audit finds no unused locals/methods or added globals. Revised bag/micro visuals, native inputs/Edit Mode, combat taint and persistence remain pending.

## Microbar pixel borders — 0.1.87

Correct the user's reported micro menu outline fading after movement. Keep the existing skin toggle, slate/teal palette and three-unit inset. Use one physical pixel for each owned edge and native pixel-aligned layout with independent texture snapping/bias disabled, where supported. Preserve native button assets/rendering, inputs, geometry, scale and Edit Mode management. Owned artwork follows native movement without an idle scanner; coalesced native scale/layout and conditional display/UI-scale events refresh thickness.

Retain the last readable thickness for missing/secret/invalid geometry, tolerate optional raster methods, reuse textures/hooks, keep disabled hooks/subscriptions inert and defer changes in combat. No new controls, dependencies or globals. All 32 Lua files, identical TOCs and **4,306 checks** pass, including 204 new scale/movement/raster assertions. The 50 matching source references are verified. Actual corrected rendering, native inputs/Edit Mode, combat taint and persistence require the new in-game checklist.

## Progress bar options — 0.1.86

The October 10 screenshots confirm the 0.1.85 XP/reputation skin and native hover labels; the user requests always-visible values, narrower precise sizing, increased thickness and optional 10% sections. Add three default-off options under **Other bars** (`/wfs bars`): **Always show values**, **Custom size** and **10% sections**, dependent on the existing progress skin. Shared visible width (120–1600) and thickness (6–40) use one-unit sliders, mouse wheel and exact numeric entry. Both native progress slots use the same dimensions. **Use Edit Mode size** removes the override and retains the chosen custom numbers. Dimension controls do not enable either toggle automatically.

Use the native labels and honor formatter, with current native visibility restored when disabling always-show. Resize supported active progress containers and their native children through the existing resize routine; update rested prediction dimensions and the native rested tick. Preserve native anchors, parents, scale, position management, fill/data/formatting, hover tooltips and inputs. Track each axis's latest native size separately from Suite's override. Restore container/child sizes before laying out dividers when custom sizing ends or the active bar is unsupported. Nine subtle teal boundaries mark ten sections; reuse their artwork and hide them independently.

Preflight optional/restricted native widgets, guard secret geometry/visibility, use cancellable coalesced work, and defer all changes/restoration during combat. Add no assets, libraries, global writes or idle updates. All 32 Lua files, identical TOCs and **4,102 checks** pass, including 311 new progress-option assertions. The matching source review covers 45 references. Revised live values/sizing/sections, honor, Edit Mode, combat taint and persistence remain pending.

## Progress, bag and micro bar skins — 0.1.85

Complete the requested Suite styling with three independent default-off toggles on **Other bars** (`/wfs bars`): XP/honor/reputation, the main bag bar and the micro menu. Use slate surfaces and thin teal edges, brighter hover borders and the meter's pressed fill. Keep existing panel size and action-bar/keybind controls; slightly tighter sidebar spacing fits the fifteenth tab above the stamp.

Remove ornamental progress backgrounds/frames/segments while preserving native colored fills, rested XP, animations, values, text, tooltips and native bar selection. Skin both manager-owned progress containers, and keep shared chrome native for other progress types. Skin supported main backpack/equipped/reagent/keyring controls while preserving icons/masks, counts, open/slot-match feedback, click/menu/drag input and native expand behavior. Skin native micro-menu backgrounds while retaining glyphs/portrait, disabled states, alerts, notifications, tooltips, keybinds and clicks. Preserve all native positioning, scale, orientation and Edit Mode management. Separate gamepad bag windows/replacement addons are outside this main-bar skin's scope.

Capture/restore current readable native cosmetics, guard secret values and missing/restricted components, reuse owned textures and observe late/removed/replaced native art. Disabled group hooks are inert; coalesced work is cancellable, and construction/geometry/cosmetics/restoration defer combat. No assets, libraries, idle updates or native data queries are added. All 32 Lua files, identical TOCs and 3,791 checks pass. Live rendering, input, Edit Mode, taint and persistence remain pending.

## Quest tracker compact collapse — 0.1.84

The user confirms the outline/controls are nearly right and provides expanded/collapsed screenshots showing a leftover All Objectives header and tall native background. Full-tracker minimize must leave only the existing small teal + button, including its compact slate face. Hide the main title, underline, filter input and all Suite body/section artwork while keeping native NineSlice suppressed. Expand through the native button to restore the full skin and latest native label alpha/filter visibility. Individual section collapse and empty expanded tracker styling retain their behavior.

Use the existing independent default-off skin setting and preserve native button geometry, scripts and collapse dispatch. Reuse existing artwork, observe native visibility changes, guard secret state, restore current native preferences on disable and defer cosmetics during combat. All 31 Lua files, identical TOCs and 3,640 checks pass. The user's 0.1.83 screenshots/click are recorded; 0.1.84 rendering, input, taint and persistence await the new smoke test.

## Quest tracker outline and controls — 0.1.83

The October 10 tracker screenshot confirms the first skin's appearance and requests Suite-style minimize controls, one outer outline and underlined section headers. Refine the existing toggle without adding preferences. Replace individual header boxes with teal underlines, outline the whole slate tracker, and reuse that outline around the main header when collapsed or empty.

Keep the native main/section minimize buttons, clicks, sounds, geometry and collapse behavior. Anonymous slate/teal artwork supplies centered minus/plus marks, muted borders and clear hover/pressed feedback. Capture/restore the latest readable native texture colors; missing/restricted button states stay native and recover on later readable updates. Retain quest links, status colors, item buttons, native fonts, effects, filters, Edit Mode and combat deferral. All 31 Lua files, identical TOCs and 3,611 checks pass; revised live visuals, collapse/expand, input and taint require the new smoke test.

## Suite quest tracker skin — 0.1.82

The October 10 request extends the Suite's slate/teal style to the native quest tracker. Add a default-off **Suite quest tracker skin** toggle under Quests & loot, independent of pickup, turn-in, gossip and quick loot. Use translucent slate surfaces, thin teal borders and teal main/section labels. Apply the shared section treatment to quests and available achievements/scenarios without changing what Blizzard tracks. The body follows actual content height, disappears when collapsed/empty, and respects native header visibility.

Keep native quest/difficulty/hover and objective status colors, added-objective effects, item buttons, bars, quest links/menus, collapse/filter inputs, localized fonts and text-size settings. Native parenting, position/width/scale, Edit Mode and quest automation remain unchanged. No new assets or libraries. Suite's fixed panel opacity belongs to this skin; native opacity preferences are never written and are restored on disable. Capture latest readable cosmetic values, guard missing/restricted widgets, restore removed sections and defer all work during combat. Use coalesced event/native-update hooks with no idle scanner or pooled quest-data traversal.

All 31 Lua files, identical TOCs and 3,512 substitute checks pass. The matching 70338 tracker changes and API declarations were verified against the pinned source comparison. Live appearance, input, native text size, Edit Mode, ordinary-addon permissions, combat taint and persistence require the new checklist.

## Short keybinds and fonts — 0.1.81

The October 10 request adds shortened action keybind labels and configurable fonts, with ZoidsTools as the user-authorized behavioral reference. Add independent default-off **Short keybinds** and **Custom font** controls under Action bars; neither depends on the skin or range indicator. Examples include Shift-Ctrl-Mouse4 → SCM4, Mouse4 → M4, Mouse Wheel Up → MWU and Num Pad 1 → N1. Retain literal punctuation, unknown labels, unbound range indicators and gamepad icon markup.

Offer Native, Friz Quadrata, Arial Narrow, Morpheus, Skurri and Damage fonts, size 8–24, Native/None/Outline/Thick outlines and **Bold treatment**. Bold follows ZoidsTools' extra size unit and stronger shadow; disclose this beside the preview. Click compact font/outline controls to cycle choices and use the slider for size. Preview choices before enabling Custom font. Keep native key assignments, text/range color, visibility, layout, button inputs and other action feedback.

Observe existing native HotKey FontStrings and restore the latest readable label/font/shadow values when disabled; unsupported/restricted data stays on its native path. Defer construction, hooks and font/shadow changes/restoration during combat, retaining permitted text-only native updates. Use events and cancellable coalesced work, with no idle scanner or new font assets/libraries. User-owned ZoidsTools remains unchanged and its MIT notice is retained. All 30 Lua files, identical TOCs and 3,327 substitute checks pass; live assets, visuals, input, Edit Mode, combat taint and persistence require the new checklist.

## Native settings close fix — 0.1.80

The October 10 follow-up reports that closing Options also closes the launched Suite GUI. Change the native launcher to close Options first, then show Suite on the last-used page. Keep normal Suite X/Escape behavior and use the native Close(true) path to skip returning to the game menu. With unapplied native changes, retain Blizzard's Apply/Discard/Cancel dialog; open Suite after Apply/Discard and all native cleanup finish, and cancel the launch on Cancel/Escape. Defer the complete operation during combat.

The user's 0.1.79 screenshot/report confirms initial native launcher access and reproduces the close issue; the running build was not provided. Source review identifies native menu cleanup hiding Escape-registered addon windows. All 29 Lua files, identical TOCs and 3,228 substitute behavior checks pass. The revised 0.1.80 close/open, confirmation and combat behavior requires live testing.

## Native settings launcher — 0.1.79

The October 10 request adds **Options → AddOns → Forever Suite** with a single **Open Forever Suite** button, a brief description and /wfs reminder. Keep the existing original GUI as the feature configuration surface. The native page uses Blizzard's fonts and button template; opening it preserves the last Suite page and never toggles an already visible GUI closed. It remains accessible with optional features and the minimap launcher disabled, without adding a preference or duplicating feature controls.

Use the client's modern Settings canvas/category registration APIs with capability checks, saved-variable readiness, late-addon retry, one-time registration and combat deferral. Native Settings manages the canvas layout and keeps its current unapplied choices. Source review is grounded in unchanged exact-70338 references from the complete pinned comparison. All 29 Lua files, identical TOCs and 3,203 substitute behavior checks pass; native list visibility, layout, button input and taint require the new live checklist.

## Suite action bar skin — 0.1.78

The October 10 request starts reskinning native UI to match Suite's damage meters and minimap, beginning with action bars. Add an independent default-off **Action bars → Suite action bar skin** toggle beside the existing range indicator. Use slate backgrounds, square cropped icons, one-unit teal edges, brighter hover edges, a dark pressed fill and a light teal checked/hover fill. Keep native font labels and bar dimensions/positions; users arrange the bars in Edit Mode.

Support known main/multibar/pet/stance/possess buttons and available extra/override buttons using the confirmed native template. Share bounded button enumeration with range feedback without making either feature depend on the other's setting or hooks. Hide only the main bar's ornamental border, end-cap textures and active dividers through alpha, preserving native visibility/input/layout and current Edit Mode art preferences. Other special-bar container artwork, gamepad controls and third-party replacement bars remain native.

Retain secure attributes, parents, bar/container layout, click/drag scripts, labels, cooldown widgets, flyout controls, spell/proc/autocast/quality feedback and native checked-state alpha. Snapshot readable icon/state presentation before changing it; skip buttons whose restore data or known mask cannot be captured. Restore original coordinates/anchors/assets/blend/tints and the known mask once, then let native UpdateButtonArt reapply the current Edit Mode choice. Suppression records follow readable native alpha writes, and restricted writes stay on their native path. Runtime snapshots never enter SavedVariables.

Construct textures/controller and install hooks outside combat; initial activation, deactivation/restoration and geometry/mask changes wait for combat to end. Existing hover/state cosmetic feedback may continue without Suite geometry changes. Coalesce discovery via cancellable token-guarded timers, including native art/divider/show hooks and late addon/world events; no added OnUpdate. Combat deferred show callbacks must retain complete enable/event registration. Disabled hooks remain inert.

Installed executable is 1.60.1.70338. Exact changed Shared/MainActionBar.lua was fetched; the other listed action/template/texture/region references are unchanged in the complete pinned 70245–70338 comparison. All 29 Lua 5.1 files, identical TOCs and 3,176 substitute behavior checks pass, including 112 added skin assertions. Native visuals, action access, restricted widgets, Edit Mode/input, combat taint and persistence require the new live checklist in testing.md.

## Whole-addon review — 0.1.77

The October 10 follow-up requests a complete code review and removal of unnecessary or redundant code. Review all shipped modules and their settings/load/package relationships without adding features. Preserve independent defaults and native ownership rules.

Keep automatic macros unchanged while an occupied bag slot's item information is unavailable; an explicit readable empty occupancy query is required before clearing an action. Inventory's combined count remains Known total until the shared bank has a snapshot, including a valid empty snapshot. Consolidate generic settings-page navigation and repeated bag-header hook registration. Generate numbered bag names once. Remove unused locals, an unused meter-menu scroll-height setting, identical duration branches and repeated meter cleanup/position saves. Keep per-action revalidation, independent scan rules and the special meter input/index path.

Tests load Lua modules from the real TOC. Check Core/TOC version agreement, duplicate/outside-source entries, actual files and unloaded Lua files. All 28 Lua 5.1 files and 3,064 substitute behavior checks pass; seven manifest-rejection fixtures pass. Source and package consistency is checked separately. Running-client UI, native actions, taint, overlapping addons and persistence remain pending under the 0.1.77 checklist in testing.md.

## Sort bags on opening — 0.1.76

The October 10 request adds **Windows → Sort bags on opening**, reached directly through `/wfs bags`. Its saved preference starts off and works independently of Window tools and Bank snapshots. Reuse the sixth row of Windows; keep fourteen sidebar tabs and existing native header/title/sort-button behavior.

Listen to Blizzard's ContainerFrame.OpenBag/CloseBag callbacks for numbered and combined bags. Use a single cancellable next-frame worker to coalesce all carried bags opened together into one `C_Container.SortBags()` request. No new item-sorting algorithm, item scans, bag-flag/direction changes or bank sorting. The native action owns sorting rules and exclusions. A visit lasts until all carried bags close; opening another bag or receiving BAG_UPDATE during that visit must not repeat the request. Enable with bags already shown arms the next visit rather than rearranging the current one. Missing/unreadable/forbidden frame data or missing sort/cursor capabilities skip work safely; a held or unreadable cursor item skips that opening without clearing the cursor.

Active combat openings wait until combat ends and only run while carried bags remain open. Close, disable and world change cancel pending work; stale timer callbacks cannot target a later visit. First event-frame construction and callback registration wait outside combat. No idle updater, permanent native hooks, protected widget mutation or native function replacement.

Installed executable remains 1.60.1.70338. Exact ContainerFrame.lua was fetched from the pinned matching commit; six other listed references are unchanged in the complete cached comparison. All 28 Lua 5.1 files, identical TOCs and 3,034 behavior checks pass, including 96 added assertions. Native sort access, ordering/exclusions, combined/numbered presentation, combat taint and persistence remain pending in testing.md.

## Quick loot — 0.1.75

The October 10 follow-up adds **Quests & loot → Quick loot**, also reached through `/wfs loot`. This preference starts off independently of all three quest options. Reuse the existing journey page with a fourth row and rename its sidebar entry; fourteen tabs retain their current size and footer clearance.

For an effective automatic `LOOT_READY` event, request each readable Item/Money/Currency slot in one immediate reverse-order pass. The native event includes the player's Auto Loot setting and configured modifier; false, unknown or restricted flags leave that session manual. Revalidate the current slot count and module/session state before each request. One pass per loot session prevents duplicate requests; close, world change, disable and a bind-confirm event stop the remaining burst. Empty/unknown/restricted slot data stays native. If the legacy slot primitives are absent, request the documented `C_LootFrame.TryAutoLoot` service once instead; never use both paths. No pacing/retry timers, item metadata scans, idle updater, CVar changes, native loot-window replacement/visibility changes, confirmation acceptance, rolls or master-loot assignment. Existing enabled event handling can serve ordinary auto-loot in combat without widget mutation; event-frame creation waits outside combat.

Installed WowB.exe remains 1.60.1.70338. Exact changed LootFrame.lua was fetched from the pinned matching commit; the five other loot/binding references are unchanged in the complete cached comparison. All 27 Lua 5.1 files, identical TOCs and 2,938 behavior checks pass, including 70 added assertions. Native timing/speed, ordinary-addon action access, loot/confirmation presentation, combat taint and persistence require the new smoke test in testing.md.

## Quest pickup, turn-in and gossip — 0.1.74

The October 10 request adds **Quests → Automatically pick up quests**, **Automatically turn in quests** and **Automatically advance gossip**, also reachable through `/wfs quests` or `/wfs gossip`. All three preferences start off independently. Available quests, including trivial quests, are opened and accepted; ignored modern gossip quests stay manual. Ready turn-ins take priority over available quests. Support both modern `C_GossipInfo` quest lists using quest IDs and the native `QUEST_GREETING` list using row indices.

Automatically finish only ready quests with zero or one reward choice. Multiple rewards, turn-ins costing gold, PvP acceptance confirmations, shared quest confirmations and gossip confirmation/code prompts remain native manual choices. A native auto-accepted offer uses acknowledgment rather than another acceptance. Only a single available gossip option with no active or available quest entries is advanced; multiple options, unknown/unavailable data and native ForceGossip remain manual. Shift sampled at opening or before execution pauses the entire current conversation, including later quest/gossip pages, until it ends. Repeatable quest entries and individual quest steps/options are requested once per conversation, with a twenty-action bound for long dialogue chains.

`Quests.lua` owns one anonymous event frame and one cancellable next-frame worker. Events settle after native dialog handlers; stage, shown panels, NPC/quest identity, current settings, modifiers and readable data are rechecked before actions. Mark requests before native calls because transitions can be synchronous. Cancel stale work on close, confirmations, combat entry, world changes and disable. Combat dialogs do not replay afterward. No idle updater, popup acceptance, CVar change, native button/script replacement or extra globals. Fourteen sidebar entries use 35-unit buttons and a 39-unit pitch to retain footer clearance in the existing panel.

Installed WowB.exe was re-read October 10 as 1.60.1.70338. Twelve relevant quest/gossip/input/unit reference files are unchanged in the complete pinned 70245–70338 comparison; legacy quest globals still require capability checks and native testing. All 26 Lua 5.1 files, identical TOCs and 2,868 behavior checks pass, including 158 added assertions. Actual running build/Interface, native interactions, taint and persistence require the new smoke test in testing.md.

## Whole-addon review — 0.1.73

The user requested a complete scan informed by the recent timing, sizing and control-overlap fixes. Preserve the accepted theme and existing feature/settings scope. Review all modules for layout before show, native input clearance, current restore baselines, event cancellation and combat/data boundaries. The user's "Perfect" accepts the preceding bag fix without supplying a running build/Interface.

Correct saved opening/reflow for supported non-bag windows after native panel calculations finish; immediately style native new/reopened chat outside combat; position both meters before showing; recapture native minimap defaults each enable with one-time hooks and cancellable work; and suppress hints for incomplete/restricted item data. Retain the separate completed bag pass, native parents/scripts/registration, active drag and combat guards, original input/menu controls and exactly the two existing chat defaults. No new settings, features or saved schema.

The source/substitute audit covers all 25 Lua files plus TOCs/XML; other modules retain their existing suitable layout, restoration and lifecycle behavior. All 2,710 checks pass. Installed executable is 1.60.1.70334; matching unchanged references and the existing exact overlay were reviewed. New first-render/input/taint results still require the combined smoke test in testing.md.

## Immediate bag opening — 0.1.72

The user reports bags opening briefly at Blizzard's default location, then snapping to Suite's saved location. Ordinary native bag layout must restore shown saved combined/numbered containers synchronously after the complete Blizzard anchor pass, as the existing guarded combat path already does. First/late ordinary openings capture native reset anchors/scale before applying saved geometry. Preserve coalesced later headers, active drags, default placement for unsaved/hidden bags, protected-combat deferral, title menus, Ctrl-wheel sizing, reset and disable behavior. No extra setting, saved schema, native function replacement, reparenting or per-frame position updater. The pre-timer regression reproduces the old snap; all 25 Lua files, identical TOCs and 2,642 checks pass with the correction. Exact installed 1.60.1.70334 bag/frame source was reviewed; native first-frame appearance, input and taint require the new smoke test.

## Meter selector styling — 0.1.71

The October 9 request replaces the native gold metric dropdown artwork with the accepted chat copy control's original slate/teal style. Keep both meter headers compact, with the same 22-unit arrow hit target and passive gold metric title. Use one thin teal border, dark slate fill and a centered original teal downward triangle; hover/press and open-menu tint give clear feedback. Preserve the current expandable private picker, metric choices, dismissals, title dragging, session/reset/lock/options controls and combat behavior. No new settings, saved values, timers or packaged assets. The optional meter module remains independent. All 25 Lua 5.1 files, matching TOCs and 2,622 substitute checks pass; native visuals and input remain pending in testing.md.

## Chat — 0.1.70

The user requested an original chat treatment in the style category of Chattynator, copying straight from chat and only account-wide text size/background opacity in this first pass. Use Suite's flat slate/teal native-window treatment, selected tab underline and typing background. Preserve native messages, filters, links, input, controls and the built-in scroll-to-current action. Chattynator's published gallery/descriptions are a reference only; no source, layouts, assets or SavedVariables are imported.

The October 9 follow-up requests sleek, text-fitting tabs with different colors. Version 0.1.66 replaces full native-button boxes with label-centered chrome: eight units of horizontal padding and a height equal to the readable native font size plus eight units. Each of the ten native window slots has a stable accent, with General teal and Combat Log amber; further temporary slots cycle the palette. Selected and hovered tabs brighten subtly, with a thin matching selected underline. Preserve native label fonts/colors, button dimensions, docking/overflow, input scripts and alert artwork; no added settings or text/geometry measurements.

The user confirmed those tabs are much better and requested a more visible chat-box border without making it strong. Version 0.1.67 gives the chat and typing panes a clearer muted teal edge, retaining the thin one-unit border. Border opacity has a subtle baseline so low background opacity does not erase the outline. Keep the same two appearance controls and existing native geometry/restoration.

Version 0.1.68 fulfills the follow-up request to move the typing box slightly down and match the chat panel's width. Anchor the existing input just below the visible chat background with a three-unit gap and flush left/right edges. Width follows chat movement/resize automatically. Preserve native height, parent, text insets/headers, drafts, focus, autocomplete and sending. Restore readable original input anchors/width on disable, recapturing current layout on re-enable. Skip restricted geometry and defer changes through combat; no extra settings or saved positions.

The user confirmed alignment looks great but reported the input barely clips off screen after placing chat at the bottom left in Blizzard Edit Mode. Version 0.1.69 extends the existing native selection and bottom screen boundary to include the input and a tiny margin (normally 43 units below the message frame instead of 32). Follow readable height/scale changes, preserve native drag/resize/save behavior and other selection edges, and restore original boundary values on disable. Use guarded widget operations outside combat, with no screen rectangle reads, native position writers or added settings.

After accepting those boundaries, the user reported the tiny copy button obstructs the scrollbar up arrow and requested a larger toolbar-sized control in a clear spot. Version 0.1.70 uses a dedicated slot below the native chat bubble, beside the typing box, leaving the existing native toolbar/accessibility icons available. Match the native 27×26 voice-button face and enlarge the paper glyph. Follow each window's native toolbar side and visibility through parenting/anchors; disappearance ends copying. Keep native controls, scripts and copy delegation intact, with no extra settings or layout worker.

Chat has two sliders: Default text size (10–24) and Background opacity (0–100%). The default-off Use Suite chat / Restore Blizzard chat action keeps this module optional and retains those defaults when disabled. Account-wide values apply on login and to late windows/new characters; `/wfs chat` opens the page. Preserve native font family/flags. Font selection, timestamp settings, filters, URL transforms, saved chat history and extra preferences are outside this pass.

A small paper glyph beside chat toggles the client's own rendered-text selection. Drag and release to copy through its native intrinsic, without a popup/editor, extracted messages or direct restricted clipboard call. Restore prior/current mouse/link flags when exiting, hiding, switching copy windows, typing, native input changes, combat or disable. Preserve native scripts and mouse motion/wheel state. Theme construction/layout/restoration defer through combat; event work coalesces and disabled hooks are inert. Restoring returns original/current native font and decoration state.

Installed 1.60.1.70291 and matching unchanged/exact-overlay sources were reviewed, including the exact Edit Mode overlay and unchanged native toolbar sources. The user confirmed compact tabs, aligned typing-box appearance and expanded Edit Mode footprint look great. Native rendering/click targets of the relocated copy control, layout saving, copying, taint and account persistence remain pending in the chat smoke test. Current offline results are recorded in testing.md.

## Mail contacts — 0.1.62

The user's follow-up limits contacts to Send Mail. Inbox opening, returning to Inbox, queued refresh and combat exit on Inbox must keep the helper hidden. Switching tabs preserves the mailbox visit, search and optional recipient memory; closing still clears that session. Native compose subframe visibility controls the helper through retained hooks with no new polling.

The October 9 request adds a character-list helper whenever the mailbox is visited, using Enhance QoL's advertised behavior and original professional Suite styling. **Mail → Mail contacts** and **Remember recipient** start off independently; `/wfs mail` opens their settings. The anonymous 288×474 slate/teal companion follows native mailbox movement/scale, docks on the available side and appears only while Send Mail is selected. Six reusable rows offer class-colored names, separate realm/faction/level details, literal name/realm search, name/realm/level sorting and paging/wheel navigation. Clicking another character fills full Name-Realm; actual sending remains manual. You marks the current character, which cannot be selected or removed.

Record logged-in characters while enabled and seed existing readable Suite inventory identities without inventory scans/settings dependencies. A separate schema-1 account-wide database scopes contacts by actual region (including beta 110) and address, deduplicates explicit typed saves and replaces obsolete regional GUID addresses. Save recipient uses the native To field and normalizes realm spaces. The x beside another character opens inline Remove contact / Cancel controls; removals survive reload and inventory reseeding. Logging into the removed character or explicitly saving it adds it again. No contact import from other addons or automatic account enumeration is included.

Recipient memory observes manually initiated native sends and restores only after the native successful-send reset, into an empty field during the same mailbox visit. Failed sends, newer input, disabled settings and subsequent visits cannot receive stale restoration. Combat defers writes/layout; closing or disabling cancels timers, deferred work and session state. Preserve native autocomplete/focus, fields, mail restrictions, sending/confirmation behavior, movement and panel management. There is no Suite mail transaction or idle updater.

Installed executable 1.60.1.70291 and relevant unchanged/exact-overlay contracts were reviewed. All 24 Lua 5.1 files, identical TOCs and 2,416 substitute checks pass; the browser layout specimen was visually reviewed. Native rendering/input, ordinary-addon access, combat taint and disk persistence remain pending in the [mail smoke test](testing.md#mail-contacts--0162).

## Combat class-health color correction — 0.1.59

The October 9 screenshots show the Warrior player bar alternating between its softened brown class fill and red during combat. Native PlayerFrame.xml places the main fill and red AnimatedLossBar on the same BACKGROUND layer/frame level. A render-order substitute reproduces the complaint when a visible damage-loss texture wins that tie; the screenshots do not prove the exact live render order or rule out another color writer.

Explicitly draw the existing player loss texture one sublevel behind the main fill while class coloring is active. Retain its red tint, mask, artwork, values and animation so the loss trail remains outside current health. Preserve the main fill and prediction/absorb drawing layers. Reapply existing class styling after native OnValueChanged callbacks, ignoring their health-value argument entirely. Remember current readable native loss layers for reversible disable/vehicle/unknown-identity restoration; guard layer/sublevel data and bounds. Install hooks/discover late animation bars outside combat, with no new setting, health reads, idle polling, geometry writes or native script replacement.

Version 0.1.59 passes 23 Lua 5.1 files, identical TOCs and all 2,239 behavior checks, including the previously failing visible-loss regression, 50 repeated opaque combat updates, native callback retention, red-trail/mask/artwork preservation, restricted/bounded layers and current native restoration. Native combat rendering/taint and running build/Interface still need the retest in testing.md.

## Circular Suite minimap launcher — 0.1.64

October 9 follow-up: after confirming the compact drawer looks much better, the user requested that Suite's settings button match the other circular gold-bordered addon launchers. Preserve the infinity artwork and use Blizzard's portrait circle mask with its gold tracking-border texture. Keep the existing 26-unit standalone frame and 24-unit drawer normalization, original handlers, visibility preference, saved angle and combat/collector behavior. The grid launcher remains the separate drawer control. No asset regeneration, new setting or addon-list icon change is needed. Native masked-icon/ring proportions come from the matching AssignedSpec presentation. All 24 Lua 5.1 files, identical TOCs and 2,416 substitute checks pass; circular rendering and native input still need an in-game look.

## Minimap addon-button drawer — 0.1.63

October 9 compacting follow-up: the supplied one- and three-button screenshots show excess border space and enlarged icons. Normalize collected button frames to 24 UI units instead of 32, preserving aspect ratio and native dimensions. Use 4-unit inter-button gaps and border padding, with 4 units between panel and grid launcher. Occupied-grid sizing yields a 32×32 single-button panel and an 88×32 three-button panel; wrapping remains four columns. Map scale, original handlers, independent visibility, saved docking, combat deferral and native restoration continue through the existing implementation. All 24 Lua 5.1 files, identical TOCs and 2,416 substitute behavior checks pass. Corrected native rendering still needs the drawer smoke test.

The user selected the minimap drawer next and authorized ZoidsTools as a reference. Add an independent default-off **Minimap → Addon button drawer** preference. A separate draggable teal grid launcher opens an original slate/teal panel of the actual addon buttons, retaining their clicks, right-click menus and tooltips. Collect the Suite settings launcher as an ordinary addon button; native map controls and pins remain in place. Escape, outside clicks and completed left clicks dismiss the panel; it starts collapsed, reports an empty drawer and follows round/square map edges with its own saved angle. Disable restores original parents, anchors, scale, layers and current owner drag scripts; owners retain hidden/alpha preferences. Respect another collector's acquired ownership.

October 9 refinement: default to the bottom-left edge shown in the user's screenshot. In square/rectangular mode, align the launcher's bottom-right with the map's bottom-left, one unit outside the border; round mode uses the lower-left angle. Remember whether the drawer was dragged so the default dock survives resizing and shape changes while intentional positions keep normal edge projection. Migrate the old untracked 315-degree default, preserving other saved angles and later recorded drags. The known anonymous Suite launcher uses an internal sort key; unrelated anonymous controls and Suite HUD widgets stay excluded. Suite positioning yields while a collector owns its parent, creation queues discovery, and its existing visibility, click/tooltip, combat deferral and restoration behavior remain intact. Remove drag instructions from its tooltip while collected.

Use optional LibDBIcon public discovery/callbacks without bundling it, plus named icon-bearing custom minimap launchers. Skip protected, forbidden, restricted and active-gesture candidates. Creation, geometry and restoration wait until combat ends; combat closes the panel and cancels its drag updater. Use coalesced cancellable events/hooks with no idle polling. Compact existing Minimap rows so all eight controls fit above the footer. Read-only MIT ZoidsTools reference is acknowledged in the shipped notice. Native compatibility, layout, input, combat/taint and saved-angle persistence need the new smoke test; offline checks do not verify them.

October 9 validation: 23 Lua 5.1 files, identical TOCs and 2,286 behavior checks pass. New coverage uses the actual anonymous Suite launcher and includes default/upgrade/custom docking, rectangular resizing, retained settings actions/tooltips, independent visibility, stable owner refreshes, late creation after combat and native restoration. Delivery is `dist/WoWForeverSuite-0.1.60.zip`, with all 31 packaged addon files matching source by SHA256; XML and provenance JSON parse. The installed junction is unchanged. The supplied screenshot confirms a visible grid launcher and an uncollected Suite button before this correction; corrected native placement/collection and broader smoke results remain pending.

## Bank snapshots — 0.1.57

October 9 screenshot retest still shows different native/snapshot placement. Preserve the actual bank's last visible top-left/scale as the authoritative default after closing. Capture shown movement/resize immediately with read-only hooks, independently of inventory timers; never replace it with hidden native anchors at close. Use generic native mover data only when no visible layout has been recorded. Keep separate intentional snapshot positioning and the existing same-call opening restoration. No new setting, polling, transaction or bank-data scan is introduced.

Version 0.1.57 validation: closing-geometry regression reproduces the previous failure; all 2,107 offline checks pass, with 22 Lua 5.1 files and identical TOCs. Physical alignment checks include non-default UI/bank scales and different page heights, plus immediate movement, hidden/secret/disabled layout exclusion and saved-center precedence. Package: `dist/WoWForeverSuite-0.1.57.zip`, 30 source addon files. On October 9, the user confirmed the positioning fix works. Running build/Interface and broader combat, taint and persistence results remain pending.

October 9 opening refinement: the user reports 0.1.55 works but the bank visibly jumps from Blizzard's default location to the saved one. Restore saved placement synchronously within first/repeat/late bank opening and native anchor/scale/size changes, for both native BankFrame and the Suite viewer. This belongs to the existing Window tools preference and introduces no new option. Capture original native geometry before first restoration, retain drag/reset/disable behavior and defer all addon bank geometry during combat. Keep subsequent header work coalesced. Use supported hooks and existing saved-position application; leave panel-manager tables/attributes and secure functions under Blizzard's ownership.

Version 0.1.56 validation: a pre-timer first-open regression reproduces the old behavior and all 2,095 offline checks pass with the fix; 22 Lua 5.1 files and identical TOCs. Package: `dist/WoWForeverSuite-0.1.56.zip`, 30 source addon files. No live first-frame/taint result has been obtained.

October 9 follow-up corrects the user's screenshot regressions. Use native XML normal-texture overrides instead of the intrinsic padded QuickSlot geometry. Default placement matches the actual bank's top-left and scale, with guarded last-visit persistence and support for the native bank's saved mover position. Preserve separately saved snapshot placements; individual/reset-all controls return to the current native-bank default. Personal data must never fall back into a missing account-bank lookup, and shared side tabs require recorded positive capacity. Existing bank records and keybind assignments remain intact. The user confirms working item tooltips; corrected visuals/position and broader live smoke results are still pending.

Version 0.1.55 validation: 22 Lua 5.1 files, identical TOCs and 2,067 behavior checks pass, including account absence/removal, native XML selection, scale/top-edge placement, persistence/reset/drag behavior and restricted/combat geometry. Package: `dist/WoWForeverSuite-0.1.55.zip`, 30 source addon files.

The October 9 request adds a keybind to view the bank away from a banker, with the actual Forever bank appearance and working item tooltips. Interpret the requested bank image as a structured slot snapshot: a bitmap cannot supply native item details or multiple pages. Use original snapshot/view code and Blizzard-provided portrait framing, bank background/shadows, character slot atlases and large side tabs. Keep the native eight-column, 88-slot pages, empty positions, per-stack counts, bag icons and source-based variable height. Do not inherit BankFrameTemplate/BankPanelTemplate or their bank action/callback mixins; the real BankFrame remains under native ownership.

**Windows → Bank snapshots** starts off independently of inventory tooltips. Record full instance links, icon IDs, counts, rarity, item/bag names, bank bag links when readable and recording time only during genuine bank access. Require complete, distinct purchased-tab lists/metadata and fully loaded occupied slots; replace each bank type atomically. Preserve previous complete snapshots on missing/restricted/malformed data and never scan on BANKFRAME_CLOSED. Save personal pages under the existing GUID character record and shared account pages once per region in the inventory database, as additive schema-1 fields. Offline content is last recorded, not live. No alt browser or guild-bank cache is included in this request.

The user's follow-up authorizes a read-only review of `P:\GitHub Repos\ZoidsTools\Bindings.lua`, `Bindings.xml` and MIT license. Use the same standard native CLICK binding registration pattern: **Keybindings → Forever Suite → Open bank view**, with a named nonsecure click target and no automatic assignment or override. `/wfs bank` and an Open bank view settings action also work. The settings shortcut opens the native keybinding category. Binding-label globals, the click target and the Escape-compatible viewer name are narrowly documented compatibility globals; feature code remains in the addon namespace. The existing MIT notice remains included.

Native hyperlink tooltips preserve enchants/gems/random properties, Shift comparisons refresh on modifier events, and only native chat-link/dress-up modified clicks are forwarded. There are no bank pickup/use/split/receive-drag handlers or purchase/money/settings actions. Search is literal and dims saved slots without changing order. The real bank dismisses the viewer on opening; pressing the key while the real bank is open closes it through HideUIPanel. Combat defers UI creation/layout and key toggles; a second press cancels a queued toggle. Disabling cancels timers/events/deferred work and hides the viewer without clearing saved data. One cancellable 0.15-second worker coalesces active-bank/data events, with no idle updater or recurring failed-data requests. General window tools optionally provide their existing movement/resize/reset controls without a new lock or grips.

Installed WowB.exe was re-read October 9 as 1.60.1.70291. The existing exact 70291 bank overlay and pinned comparison establish the reviewed bank logic; the relevant XML, ItemButton, portrait, side-tab, search, bank/container documentation and keybinding settings files are unchanged from the 70245 cache. Twenty-two Lua 5.1 files, identical TOCs and 2,037 behavior checks pass, including native-look component choices, isolated keybinds, complete slots/links, personal/account paging, literal search, tooltip ownership/comparison/refresh, modified-click transaction exclusions, asynchronous/secret/corrupt data, event coalescing, region/character isolation, replay, logout and combat/disable cleanup. No running-client keybinding, visual, count, taint or persistence test has been performed.

Completed snapshots also refresh the existing aggregate personal/shared bank quantities, so enabling inventory tooltips later does not show older bank totals beside the newer saved view. Neither optional toggle enables the other, and unrecorded carried inventories remain unknown.

Delivery: `dist/WoWForeverSuite-0.1.54.zip` contains 29 addon files matching current source by SHA256, including Bindings.xml and the existing MIT notice. Provenance JSON and binding XML parse. The installed WoWForeverSuite junction still targets this workspace; restart the client to load the new native binding entry. Other addons and external SavedVariables were not modified.

## Softer class health bars — 0.1.53

The user reports the new class health bars look too bright and asks to tone them down. Scale all three validated class RGB channels to 75% of their original values, preserving class hue while lowering intensity. Keep the opaque neutral fill and existing native restoration so the result stays consistent across frames and native recolors. This refinement applies to the same player/target/target-of-target/focus scope and requires no new preference or API.

Twenty Lua 5.1 files, identical TOCs and all 1,934 behavior checks pass with the softer rendered-color expectations, including native recolors, identity changes, combat updates and disable restoration. The user's report establishes visible bars but supplies no running build/Interface or taint result; softer native appearance requires a retest.

Delivery: `dist/WoWForeverSuite-0.1.53.zip` contains 26 addon files matching current source by SHA256. Provenance JSON parses and the installed junction remains linked to this workspace, so `/reload` loads the softer colors without changing the saved toggle.

## Class colored health bars — 0.1.52

The October 8 request adds **Unit frames → Class colored health bars**, also reachable with `/wfs unitframes`, independently off by default. The user's clarification limits this to player, target, target of target and focus. Party/raid retain their built-in class color option; nameplates, pets and focus's target are outside this module. NPCs, vehicles, disconnected units and unavailable/restricted class information retain native appearance.

The health fill's atlas contains color, so changing only its tint multiplies the native pixels into the class color. Replace the pixels on the existing masked fill texture with opaque neutral white, reset its texture crop and apply the full class RGB/alpha. No second bar or translucent colored overlay is added. Observe native tint/atlas updates and remember their latest readable appearance for restoration on disable or a non-player target. Keep native health values, text, masks, animation, prediction/absorb bars, frame layout and input. Hooks install outside combat; permitted cosmetic setters update existing textures in combat. Identity/discovery events share one cancellable refresh, with combat discovery deferred and no new OnUpdate.

Installed WowB.exe was re-read as 1.60.1.70291. The exact pinned comparison leaves the relevant unit/texture/status-bar API contracts and native health layouts unchanged; changed PlayerFrame/Camelot target files were reviewed and cached in `.cache/unitframe-ui-source-70291`. Twenty Lua 5.1 files, identical TOCs and 1,934 behavior checks pass, including rendered-color multiplication, all four frames, current native restoration, NPC/vehicle/class transitions, secret inputs, combat deferral/painting/disable, late/forbidden frames, scope isolation and GUI controls. Running build/Interface, native appearance, taint and persistence require the new smoke test.

Delivery: `dist/WoWForeverSuite-0.1.52.zip` contains 26 addon files, each matching source by SHA256, excluding development caches/tests/docs. Source-provenance JSON parses and the existing installed junction still points to this workspace, so `/reload` loads the update.

## ZoidsTools inventory tooltip styling — 0.1.51

The user requested a read-only review of their Retail ZoidsTools addon and prefers its inventory presentation. `P:\GitHub Repos\ZoidsTools\Modules\WarbandItems.lua` supplies the requested gold Inventory heading, blue labels with white quantities, class-colored names with native 16-pixel class icons, comma-separated location counts and short names with realms only when names overlap. The shared bank appears last as a gold Warband row with the native fire icon. Its MIT notice is included in the shipped `NOTICE.txt`; ZoidsTools itself was not modified.

Adapt that presentation to Forever Suite's existing guarded snapshots and tooltip bookkeeping. Omit confirmed-zero locations and the two explanatory footer lines. As of 0.1.95, also hide unrecorded locations while retaining Known total for incomplete recorded character inventories; settings help explains recorded counts and hidden locations. Preserve the region-110 fix, current-character-first ordering, shared-bank deduplication, independent optional toggle and existing bag/bank scope. No equipped-item tracking is added by this styling request. Native icon coordinates and colors are guarded, with text/gold fallbacks when unavailable or restricted.

Validation: nineteen Lua 5.1 files, identical TOCs and 1,806 behavior checks pass, including region 110, duplicate-name disambiguation, compact rows, native icon crops, restricted icon/color fallback and tooltip reuse. Native appearance/counts, actual running build/Interface, combat taint and persistence remain pending the 0.1.51 smoke test.

Delivery: `dist/WoWForeverSuite-0.1.51.zip` contains 25 addon files, including the MIT notice, all matching source by SHA256. Provenance JSON parses and the existing installed junction targets the source folder, so `/reload` picks up this update.

## Beta inventory region correction — 0.1.50

The October 8 follow-up reports no Inventory footer despite tracking being enabled and bandages present in both bags and bank. The user's running diagnostic supplies NUM_TOTAL_EQUIPPED_BAG_SLOTS 5, NUM_BAG_SLOTS 4, GetCurrentRegion 110 and itemInventory true, with no recorded character returned. Version 0.1.49 incorrectly restricted both region resolution and saved-character filtering to 1–100, so it stopped before recording any inventory. The generated GetCurrentRegion declaration returns a number with no such maximum.

Accept every readable positive finite integer region ID and retain the exact returned ID as the character/shared-bank scope. Do not map the beta to a guessed live region. Missing/restricted/zero/negative/fractional/infinite regions still skip recording. No saved-data migration or preference change is needed because the failed beta cache never recorded a character. The 110-based regression reproduces the old failure; the corrected version passes nineteen Lua 5.1 files, identical TOCs and all 1,792 behavior checks. The user's actual running build/Interface and corrected in-game counts remain unreported. Reload and reopen the bank for the retest.

Delivery: the 0.1.50 ZIP contains 24 addon files matching source by SHA256. Provenance JSON and the existing workspace junction are verified; the corrected in-game retest remains pending.

## Item inventory in tooltips — 0.1.49

The October 8 request adds **Tooltips → Item inventory**, independently off by default. Item tooltips show an Inventory footer, total and class-colored Name-Realm rows with separate Bags/Bank quantities. The current character appears first; other recorded characters sort by name. This applies to all item types, including hearthstones, consumables and materials, independently of equipment-only levels and stat hints. Match by base item ID and combine stack quantities, including the carried reagent bag; equipped items, mail, auctions and guild banks are outside this count. Show nothing for items with no recorded holdings.

Account-wide SavedVariables retain each observed character under its GUID, with region/realm/name/class and complete bags/bank snapshots. Visit each character with the toggle on to record its bags, and visit its bank to record all purchased character tabs. As of 0.1.95, unknown locations are hidden and the header uses Known total when a recorded character or shared bank has an unknown location. Settings help explains that counts come from recorded inventories; offline characters and closed banks cannot be kept live. Shared account-bank contents have one row and one snapshot per region, counted once rather than on every character. Characters and banks in other regions stay outside the active region's total.

`Inventory.lua` scans only on enabling, inventory/world/bank/item-data events and logout, coalescing bursts through one cancellable 0.15-second worker without idle polling. Missing/restricted/incomplete records retain the previous complete location snapshot instead of saving partial totals. Purchased bank lists must match the native purchased count, tab IDs must be distinct and outside carried bags, and purchased tabs must have loaded positive slot counts. Closing a bank never clears its snapshot. Disabling removes events/timers and retains saved data; first construction defers during combat. Tooltip callbacks use supplied item data and their existing clear bookkeeping, including comparisons without GetItem. Tooltip initialization also defers during combat.

Installed WowB.exe was read October 8 as 1.60.1.70291. The exact pinned 70291 source comparison preserves inventory/container/bank/identity signatures; the bank UI change moves interaction registration into shared templates. The full source cache remains 70245 with a narrow 70291 inventory overlay, recorded in sources.json. Nineteen shipped Lua 5.1 files, identical TOCs and 1,784 behavior checks pass. Live counts, account-bank access, native tooltip fit, combat taint and saved persistence require the new smoke test.

Delivery: the 0.1.49 ZIP contains 24 addon files matching source by SHA256, with no cache/test/documentation files. Source-provenance JSON validates, and the existing installed junction points to this workspace. In-game verification remains pending.

## Home and world latency — 0.1.48

The October 8 request changes the minimap stats format to `XX FPS / H: XX ms W: XX ms`. The existing latency toggle controls both values, with home and world kept together after one separator. Each value is independently checked for readable numeric data before formatting; unavailable or restricted values are omitted. Settings identify both latency values. The existing one-second ticker, native coordinate/clock suppression and stats placement remain in use.

October 8 offline validation passes eighteen Lua 5.1 files, identical TOCs and all 1,709 existing behavior checks. The 0.1.48 ZIP contains all 23 addon files matching source by SHA256, and the existing installed junction targets this workspace. Native text fit, actual latency values and combat/taint require the new smoke test.

## Meter detail header and click-away dismissal — 0.1.47

The user accepts the compact details except for the title strip extending past the visible native background. Remove the opaque strip and place the passive gold player name and native X directly inside the popup border. Keep the existing compact context and spell rows.

Clicking outside closes the popup. Matching Blizzard source uses GLOBAL_MOUSE_DOWN with GetMouseFoci and DoesAncestryIncludeAny; use that native focus predicate with readable input/result guards instead of measuring widget rectangles. Clicking the popup or its descendants keeps it open, and the outside click continues to its normal target. Listen only while shown and unregister/clear runtime source, icons and text on hide. X/Escape remain available, including when the focus APIs are absent. Prebuilt combat clicks retain their existing geometry. Appearance and native input/taint require the new smoke test.

October 7 validation/delivery: eighteen Lua 5.1 files, identical TOCs and all 1,709 behavior checks pass. The 0.1.47 ZIP contains 23 addon files matching source by SHA256; provenance JSON parses and the installed junction remains linked. Native inset appearance, outside-click propagation and combat/taint results remain pending.

## Meter name space and exact numbers — 0.1.46

The user's October 7 side-by-side screenshot shows Drock Bracketfix clipped in Suite while the similarly sized native meter fits, alongside 16.6k (13) instead of Blizzard's 16,568 (13.5). The fixed 140-unit value reservation wastes space for shorter values. Keep the requested 14-point font and use native right-aligned, naturally sized value text; anchor the name's right edge four units before it. Main and popup rows share this layout, without reading text width/rectangles or deriving geometry in Lua. Plain input/frame dimensions remain independent of data-bearing font regions.

Full numbers become the default, with a one-time per-window numberRevision migration to apply the user's requested exact display to existing windows. Later Compact choices stay saved. Native BreakUpLargeNumbers groups exact totals and explicitly accepts secret arguments when tainted; opaque output goes directly to native text. Readable fractional rates use one decimal, whole rates omit .0, and native formatting preserves one decimal for secret rates. Count/total fields remain whole, DPS/HPS popup primary values use rate precision, and absent rates still leave only the total. A guarded readable fallback groups numbers when native grouping is unavailable; no hidden arithmetic, serialization or text readback is added. In-game name fit, native secret grouping and precision still require the new smoke test.

October 7 validation/delivery: eighteen Lua 5.1 files, identical TOCs and all 1,678 behavior checks pass. The 0.1.46 ZIP contains 23 addon files matching source by SHA256; provenance JSON parses and the installed junction remains linked. Actual native name fit, restricted numeric formatting and taint verification are pending.

## Macro update stalls — 0.1.45

The user reports that created macros fail to update with **Keep created macros current** On and Blizzard's editor closed. Read-only inspection of the last saved Suite settings confirms the toggle, four created recipes and four ownership records; their saved native macro commands match. This is disk evidence, not a running-client diagnosis.

An event-driven regression reproduces a concrete stall: one uncached crafting reagent set the whole supply snapshot incomplete, preventing every recipe from updating. Track pending data by recipe and selected item instead. Readable instant class/subclass metadata can exclude unrelated uncached gear/reagents. Pending food/drink retains recovery text; pending bandages retain bandages; potions only pause enabled combat additions. Known ordinary stones pause their matching weapon family, and Healthstones pause the enabled health addition. Unknown item classes conservatively pause recovery choices. Unreadable bag fields or classification still pause all writes; selected-item and equipped-weapon data guards remain intact. Relevant data-completion events resume updates through the existing coalesced timer.

Confirmed ownership accepts CRLF/LF differences and terminal empty lines without treating them as custom commands or issuing needless edits. Command and condition changes still pause management. `/wfs macrostatus` reports the preference, completed refresh count, last event and each created recipe's current loading, ownership or editor state without writing native macros. No migration, automatic creation or saved-file changes are needed. Live bag/equipment updates and reload behavior still require the new smoke test.

October 7 offline validation passes eighteen Lua 5.1 files, identical TOCs and all 1,661 behavior checks. The 0.1.45 ZIP contains 23 shipped files matching source by SHA256; source-provenance JSON parses and the installed junction remains linked. The existing bag/meter changes are included. No new running-client result was obtained.

The subsequent October 7 diagnostic screenshot reports updates On, one completed refresh, last event BAG_UPDATE_DELAYED, no queued refresh, and FS Food/Bandage/Main Hand/Off Hand current in General macros. The user clarifies that only opening/closing bags occurred between the two identical reports. That is not a supply/equipment change, so the unchanged counter does not demonstrate an updater failure. It confirms runtime diagnostics and current ownership/body matching; a real supply or weapon change, native execution and running build/Interface remain unverified.

The user then confirms on October 7 that the macros have updated and are working now, after previously failing. Record automatic updating as observed successfully in game after the 0.1.45 repair. The precise running build/Interface, individual recipe transitions and full execution/combat/persistence smoke tests were not supplied; do not extend this confirmation to those checks.

## Bag combat placement — 0.1.44

The October 7 follow-up reports that bags still move to Blizzard's default position in combat and snap back afterward. The earlier blanket combat deferral preserved SavedVariables but did not meet the requested on-screen retention. The user reports `IsProtected()` false for native bags 1 and 2 on the running client; its build/Interface were not supplied.

After the native `UpdateContainerFrameAnchors` finishes, a narrow post-hook restores saved position/scale for the known combined and numbered bag frames only when their current protection result is readable and exactly false. Check this on each pass rather than caching protection. Saved bags first opened in combat use a lightweight Lua record without creating movement controls; ordinary discovery/layout still waits until combat ends. Unsaved, hidden, forbidden, protected, unknown-protection and restricted-geometry bags stay on the native path. Disabling/resetting leaves native bag defaults to the current bag manager. No movement input, protected geometry, frame parenting, native function replacement, header scans, timers or polling are introduced during combat. Existing native-window gestures and other modules retain their rules. Actual corrected retention, native input, taint and performance require the new smoke test.

Final October 7 validation passes eighteen Lua 5.1 files, identical TOCs and 1,661 behavior checks with the latest workspace changes included. The 0.1.44 package contains 23 files matching current source by SHA256, and the existing installed junction remains linked. The earlier window mover reproduces the jump under the new regression; the current mover passes. Corrected live combat and performance results remain pending.

## Meter text and compact breakdown — 0.1.43

The user's October 7 follow-up dislikes the small harsh bar text and the report-like source popup, and permits either a closer Blizzard presentation or the native popup. Raise the default bar font from 11 to the native Roman NumberFontNormal size of 14 and use normal OUTLINE flags instead of inheriting MONOCHROME/THICKOUTLINE changes from a shared font object. A per-window fontRevision migrates the old 11-point default once; different custom sizes and later small choices remain available. Plain font/width settings reserve separate name/value columns.

Keep source details Suite-owned and prebuilt, using Blizzard's compact visual treatment: 420-by-246 popup, native dropdown background/close button, textured 22-unit rows, spell icons and one-line total/rate/share values. DPS/HPS place supplied rates first; counts omit rate parentheses. Readable total/amount alone permit a rounded share; restricted values omit it and remain on native display paths. Recipient/unit text joins the spell name through native formatting. Readable spell IDs enable normal hover tooltips; secret spell IDs/icons use only documented taint-permitted presentation. Popup placement uses cached plain window rectangles outside combat and retains its previous anchor during combat.

The native source window is tied to its session owner and reanchors on open; its scroll provider dynamically initializes rows and its shared entry formatters branch/divide combat amounts. Reusing those routines in Suite execution would not grant their native security context. Matching installed artwork/font primitives with existing guarded source queries preserves independent layout and sample tests. The supplied screenshot confirms source rows/totals were visible and the user reports the popup seems functional, without a running build/Interface or combat/taint result. Native visual/input/combat verification remains pending.

October 7 offline validation passes eighteen Lua 5.1 files, matching TOCs and all 1,601 behavior checks. The 0.1.43 ZIP contains 23 addon files matching source by SHA256; source-provenance JSON parses and the installed junction remains linked. Native appearance, spell textures/tooltips, combat legality and the earlier dropdown error require the smoke test.

## Meter spacing correction — 0.1.42

The follow-up October 7 screenshot shows native arrow artwork nested inside a second Suite border and bar shadows stretched over the fill. Use only the arrow's own native border, a square 22-unit hit area, 25-unit artwork and the native two-unit downward offset, with native hover/press states. Retain the compact header and passive draggable title. Bar fills now sit one unit inside the row vertically and four units inside its right edge; their native shadow textures extend two units around the fill. Row clipping keeps shadows within their own row, and full-height class icons align with the stacked bars. All geometry uses existing plain settings outside combat. In-game fit at normal/alternate UI scales still needs a retest.

October 7 offline validation passes eighteen Lua 5.1 files, identical TOCs and all 1,585 behavior checks. The 0.1.42 ZIP contains 23 addon files matching source by SHA256; the installed junction remains linked to this workspace. Native visuals/input and the earlier dropdown error remain pending.

## Meter appearance and selector fix — 0.1.41

The October 7 screenshot/request replaces the main rows' Friz title font and flat fill with the matching Blizzard meter's NumberFontNormal family (Arial Narrow for Roman text), native textured fill and soft track/edge artwork. Readable known classes receive their native class atlas beside the rank/name; restricted, unknown or missing classes clear the previous icon. Suite teal and the saved class-color preference remain available. Font and icon sizing follow existing controls and reserve separate name/value columns. The metric click target becomes a 20-unit left arrow with a passive gold title, allowing movement from the title/header while retaining the lock, resizing, C/O and supplied DPS/HPS displays.

The reported tainted secret-number conversion occurs in shared Blizzard Menu.lua MeasureExtents. Its stack reaches a native DropdownButton and does not establish which earlier operation introduced taint. The correction removes Suite meters' participation in the shared MenuUtil/compositor pools: two private, prebuilt twelve-row menu panels provide expandable category/history choices, selected checks, wheel scrolling and actual-height backgrounds. Only readable descriptions and plain layout dimensions reach them; unprotected popup geometry may change in combat without constructing frames or touching native/protected geometry. Escape, outside click, selection and owner/lifecycle cleanup dismiss them. Native menu functions, pools, security and hidden data are left under native ownership. A reload and the added native-dropdown smoke test are necessary to assess the reported failure.

All 1,573 offline behavior checks and eighteen-file Lua/TOC checks pass against installed executable 1.60.1.70245, re-read October 7. Actual running build/Interface, appearance, class atlas rendering, input/drag, popup combat legality and shared-menu error resolution remain pending.

## Requested features and first implementation

| Request | Version 0.1.50 implementation | Remaining verification or expansion |
| --- | --- | --- |
| Square minimap with stats | Original square mask and teal border, translucent bordered header with centered area/subzone labels and native tracking/calendar controls; enlarged native clock at the map bottom center, one-line FPS and home/world latency below Blizzard's coordinates; optional fallback coordinates/time | Native rendering, rotated minimap, icon placement, UI scale and Edit Mode interaction |
| Move all WoW windows | Drag empty native header space on standard named frames and registered `UIPanelWindows`, including combined/individual bags and Calendar; exclude clickable header controls | Test each major panel; add adapters for windows with unusual ownership or layout rules |
| Save position, resize, reset | Positions stored relative to screen dimensions; Ctrl+scroll proportional scale; Ctrl-right-click/reset all; one coalesced layout worker, no combat position timers, interrupted drags retain the committed layout | Combat transitions/native reflows, client restart, display changes and default layout restoration |
| Item levels on equippable gear | Quality-colored number at the top right of equipment/weapon icons, without Retail upgrade paths; current slot lookup and native container refresh hooks, with shared equipment-only tooltip scope | Verify gear in bags, equipment, bank, mail, vendor, quest rewards, loot and professions; food and reagents must remain unlabeled |
| Player tooltip item levels | Gold Item Level label on the left and a white rounded whole-number value on the right; own equipment average and mouseover inspection with a short cache, queued cooldown and bounded retries | Fresh hover inspection without targeting, server latency, range, missing item data and coexistence with the Inspect window |
| Character frame item level | Independent optional equipped-average label centered above the character, below the model controls; gold label and white rounded number | Native average availability, model layering, scaling, pet/sidebar transitions and combat deferral |
| Class color options | Independent tooltip-name and player/target/target-of-target/focus health bar toggles; health fills replace the native colored pixels and tint | Native health-fill rendering, restoration, identity transitions, combat taint and persistence; party/raid keep their built-in option |
| Simpler EverCore-style macros | Fixed Food / Health, Drink / Mana, self-bandage and main/off-hand coating recipes; repeatable chosen-item macros; preview and explicit General creation | Live item execution, native targeting/prompts, visual fit, ownership, combat deferral and character persistence |
| Camping bar | Small nearby-camp bar, carried camp-object actions with counts/cooldowns, remembered Sit/Kneel/Sleep/Lie down pose, saved position and inactive preview | Live proximity aura, object discovery, all four poses, placement, visuals, persistence and combat taint |
| Two damage meters | Blizzard meter font/textured bars and class icons in the Suite's slate/teal windows; left arrow/passive title, independent private metric/C/O/history menus, totals with DPS/HPS, player breakdowns, quick reset, lock, sliders, snapping and eight-player test | Native appearance/input, shared-menu error retest, API/widget/source queries in combat, restricted identity, retention/eviction and persistence |
| Full button range indicator | Independent optional red tint over the entire native action/pet icon, following native range updates and restoring current usability colors | Live spell/item/macro targeting, paging, pet/override/extra bars, combat taint, visuals and persistence |
| Repair and junk selling | Independent off-by-default automatic repair with personal/guild funding; slow stack-by-stack selling capped at 12 per visit, or automatic Blizzard instant junk sale with settings warning and scoped popup acceptance | Native sales/popups and Buyback, guild permissions/balances, server repair behavior, combat taint, UI fit and persistence |
| Upgrade indicator | Teal + on supported item buttons and a tooltip explanation for higher weighted stat scores | User role preferences; custom weights; weapon DPS, unique equipment and special-effect models |
| More personal QoL features | Extension points through independent modules | Add features as the user identifies them |
| Mail contacts | Full first/last names, informational rulesets, original docked list/search/sorting/paging, legacy completion, confirmed removal and independent successful-send recipient memory | Native full-name input/autocomplete, ruleset detection/delivery boundaries, combat taint, visuals and persistence |
| Quests and gossip | Independent automatic pickup, ready turn-in with zero/one reward, and single-option gossip; Shift bypass and native manual choices | Live NPC/greeting/reward transitions, confirmations, repeatables, combat taint and persistence |
| Quick loot | Immediate auto-loot slot pass respecting the game's setting/modifier, with native bulk fallback and manual bind confirmations | Native speed, slot readiness, bag-full/locked/unique loot, combat and persistence |
| Unique GUI | Original slate background, teal active states, warm gold footer, fourteen-page sidebar and reusable control rows | In-game visual QA, accessibility and user feedback |

The first version favors conservative hints over an item-level-only decision. Balanced, Physical, Caster, Healer and Tank presets expose their weights through the control panel. A hint indicates a possible improvement under that preset; it does not evaluate a complete build or simulate damage and healing.

The user's October 5 update removes the unlock/lock workflow. Window tools remain optional, but enabled windows and bags are always movable outside combat. A plain right-click must never reset a layout; per-window reset requires Ctrl and right-click together. Item tooltip callbacks now use their supplied item data, including comparison tooltips without a `GetItem` method.

The later header update removes separate drag bars. Transparent drag regions occupy empty native header space, with the actual click bounds of visible native controls subtracted, including nested and anonymous controls. Calendar uses its raised month title and lower side bars; arrows, Filters and close remain native. Version 0.1.5 shares bag titles between movement and the native menu: normal left-clicks forward the native menu handler on release, while dragging cancels that click. Portrait settings and close buttons retain direct input. The next user update removes resize grips entirely: hold Ctrl and scroll up/down over the header to enlarge/shrink the window. Each notch changes scale by 0.05, bounded to 0.55–1.8, and persists immediately.

## Architecture

Version 0.1.40 adds the user's October 7 **Repair and junk selling** request under **Vendor** and `/wfs vendor`. Automatic repair and junk selling are independent and start off; Personal funding and Slow sale are the initial choices. Funding and sale mode each flip through a visible two-choice control. Guild repair requires full readable permitted guild coverage, since the native guild action can charge personal gold for a shortfall. Insufficient/unavailable guild coverage skips repair. Initially unaffordable personal repair can retry after sales through money events.

Slow sends one carried gray stack at a time, at least 0.2 seconds apart, and waits up to two seconds for its bag slot to change before continuing. It stops after 12 attempted stacks per active vendor visit to avoid displacing the beginning of that batch from the native 12-entry Buyback list. Additional manual sales or subsequent visits can still displace earlier Buyback entries; the settings explain that recovery is temporary. The initial queue is a snapshot and each slot's ID/count, gray quality, value, lock and native bag exclusion are checked again immediately before use. Changed replacements, inaccessible data and locked/no-value items stay untouched. Completed visits do not resell bought-back items merely because bag/money events fire.

The user's subsequent October 7 request changes Instant in version 0.1.42 to automatic permanent selling with native junk-popup acceptance. With both automatic junk selling and Instant selected, one automatic native `C_MerchantFrame.SellAllJunkItems` request runs per active visit without a Suite confirmation. Settings retain the explicit no-recovery warning and explain that permanent sales need no confirmation. A post-hook on the native generic-confirmation presenter recognizes only the exact `MerchantFrame_OnSellAllJunkButtonConfirmed` callback, invokes it under the same current setting/combat/merchant/capability guards and hides only that data table's popup. Matching text alone never identifies an action. Repair-only, disabled and Slow settings leave that native popup alone; unrelated popups remain native. Install the observer outside combat only when the permanent option is enabled; late loading is event-driven, and disabled observers have no effect.

Instant retains native junk classification/exclusions. Close, disable, mode change and combat cancel queued automatic work; unsold visits resume after combat, while completed permanent sales do not repeat solely from events/combat. `Vendor.lua` shares one cancellable event worker, guards all action-time contexts and creates its event frame outside combat. It has no idle updater or timer when closed/disabled. Its queue tolerates MERCHANT_SHOW arriving before the native frame shows and retries guild funding through the matching native guild-money events. Actual in-game sales, popup acceptance, recovery, funds, UI and taint remain pending.

Version 0.1.39 adds the October 7 **Full button range indicator** request under the new **Action bars** page and `/wfs actionbars`. The independent preference starts off. The entire icon becomes red only for a readable, explicitly checked out-of-range result; the existing native keybind indication remains. Native usability recolors retain the red tint while keeping their latest readable color for restoration. In-range, unchecked/unknown/restricted range, hidden/empty buttons and disabling restore native colors, including blue for insufficient resources and gray for unusable actions. Cooldowns, counts, keybinds, click scripts, secure attributes, anchors and action-bar ownership retain their native behavior.

`ActionBars.lua` observes the shared `ActionButton_UpdateRangeIndicator` presentation callback, native icon color setters and individual button updates/show/hide. It seeds current range from guarded `C_ActionBar.HasAction`/`IsActionInRange` queries and the native pet-info range tuple. Main, seven additional bars, override, extra-action and pet buttons are covered when present. Custom action-bar replacements and flyout spell choices are outside the initial scope. No range-service subscriptions, Suite polling updater, overlay frames or custom spell-distance model are added. Discovery uses one cancellable event timer and defers hook installation/frame creation during combat; existing icon color updates and disable cleanup use permitted cosmetic setters. Native visuals, range availability/targeting, combat taint and saved preference still need the new smoke test.

Version 0.1.38 implements the initial October 7 request for combat placement with low overhead. Native window hooks share one cancellable timer and one core combat callback; events during combat only mark work pending. A completed out-of-combat move saves normally, while unfinished combat/hide/disable gestures retain the previous saved layout. Readably unprotected windows stop following the cursor on combat entry; protected/unknown cleanup and general window anchoring/scale/input layout wait until combat ends. Version 0.1.44 above adds a narrow immediate saved-position restore for readably unprotected native bags after their manager runs. The launcher immediately removes its temporary drag updater on combat entry. Suite meter positions already remain fixed while native data updates, and the camping bar still hides securely. No position polling, new options or saved settings are added. Blizzard can relocate protected native windows during combat; Suite restores those afterward rather than overriding secure ownership. Actual client retention/taint and performance need the smoke tests.

Version 0.1.37 adds the October 6 character-frame request under **Items → Character frame item level**. The independent setting starts off. A passive gold **Item Level** label and white rounded equipped average sit at the top center of the model pane, below its zoom/rotation controls. This uses the user's first placement suggestion and preserves the full native level/class line for Warrior, Paladin, Warlock and longer localized names. The native model parent supplies scale/visibility; selecting the pet sidebar hides the player value. The equipped second return from GetAverageItemLevel supplies the number, with an em dash for missing, restricted or invalid data. One cancellable event timer handles gear changes; hidden sheets keep no timer and all construction/layout/display work defers during combat. The existing player-tooltip calculation is unchanged. Native API access, rendering, input, taint and persistence remain subject to the smoke test.

`Core.lua` owns the namespace, SavedVariables defaults, slash commands and deferred combat work. `Minimap.lua`, `Windows.lua`, `ActionBars.lua`, `Items.lua`, `Character.lua` and `Tooltips.lua` each apply their own preferences. `Scoring.lua` contains the independent stat model. `MacroItems.lua` classifies carried supplies and matches weapons; `Macros.lua` owns recipes, macro ownership and coalesced refreshes. `CampingItems.lua` discovers carried camp objects; `Camping.lua` owns proximity, secure actions, positioning and event lifecycle. `DamageMeters.lua` owns native-session display, selectors, docking and its event lifecycle. `GUI.lua` provides the original interface and reusable controls.

Disabled modules install no initial feature hooks or timers. Where WoW hooks cannot be removed, callbacks consult the current preferences and disabled visuals are cleared. The minimap ticker runs only when its stats strip is enabled; window resizing responds only to a Ctrl+mouse-wheel event and uses no idle updates.

## Design direction

The user's October 6 icon request adds one shared visual identity for the addon list and minimap settings launcher: a broad interwoven gold-and-teal infinity emblem on dark slate. It represents Forever without relying on tiny letters. Both surfaces consume the same original TGA; the launcher retains its square size, one-unit teal outline, saved angle and normal click/drag behavior. The addon list uses TOC metadata rather than a runtime hook. Artwork generation provenance and the final prompt are recorded in `artwork/ForeverSuiteIcon-prompt.md`. Client rendering is pending.

Version 0.1.25 adds the user's requested GUI variant: WARCRAFT above the infinity emblem and FOREVER below, with matching word widths and gold Warcraft-style fantasy lettering. Following the user's placement clarification, the separate 256 x 256 texture appears at 56 x 56 in the top-left header, beside the Forever Suite title and subtitle. The title block shifts right to give it room. It is passive artwork and does not alter navigation or header input. The small addon-list/minimap texture and its metadata remain unchanged. The source and prompt are in `artwork/ForeverSuiteLogo-prompt.md`; native rendering still needs a visual check.

Version 0.1.26 revises only the GUI artwork to the user's chosen stacked title: WARCRAFT, FOREVER, a smaller gold-and-teal infinity, then SUITE. The original infinity is about 60 percent of the canvas width. Blizzard's official Forever logo was read as the user-requested typography reference: pale champagne-gold Warcraft letterforms and ivory classical serif letters for FOREVER and SUITE, with bronze-gold bevels. The 56-unit header placement and title block are retained. The previous PNG master is preserved; the current master is `artwork/ForeverSuiteLogo-v2.png`. Small launcher/addon-list artwork remains word-free.

Version 0.1.27 follows the user's supplied game-logo screenshot and request for an interwoven treatment. WARCRAFT, FOREVER and SUITE now form three stacked rows. The gold-and-teal infinity flows from FOREVER's letter tails and weaves over/under the SUITE lettering, eliminating its separate row while retaining readable letter faces. The GUI still uses the same 56-unit header placement and texture path. The current source is `artwork/ForeverSuiteLogo-v3.png`; earlier master images and the v2 prompt record are preserved. Small icons keep their original word-free infinity.

Version 0.1.28 moves the infinity's center and main weaving onto FOREVER, following the user's alternate-version request. Gold and teal loops thread its counters and selected stems; WARCRAFT stays above and SUITE is clear beneath. The GUI's 56-unit header placement, fonts' visual style and runtime texture path remain the same. The current source is `artwork/ForeverSuiteLogo-v4.png`, with earlier images and prompts preserved. Small icons remain unchanged.

The panel should feel like a small personal toolbox. Keep page names familiar, controls sparse and the current state visible. Use clear explanations beside each option, and expose reset actions where the user changes layouts. Expand the navigation only when a new feature group merits its own page.

Use the native WoW font and code-drawn panels without borrowing Enhance QoL's art or GUI. The addon's own small square mask is generated directly for its map shape. No third-party library is required by the shipped addon.

## Next work

Run the in-game test sequence, including the user's requested macro expansion. Correct errors and missing surface adapters from those results, then refine the visual design and stat preferences with the user. Public releases and a stable-client compatibility claim come after those checks.

While square minimap styling is enabled, release screen clamping on the native minimap cluster, map and backdrop. Edit Mode continues to own movement and persistence. Disabling square styling restores the original clamp flags; combat changes defer.

Version 0.1.10 expands Overview helpers with practical controls and feature limits. Window guidance includes move, Ctrl+scroll resize and Ctrl+right-click reset directly in the row. Two-line helpers use taller rows and a 680-unit panel to preserve footer space. A shared noninteractive hint appears after a half-second header hover, includes bag menu guidance, and cancels on leave/hide/click/drag/scroll or disabling the feature. It anchors beside the cursor against UIParent and does not take ownership of GameTooltip.

Version 0.1.11 adds an original slate/teal FS launcher on the minimap, enabled by default and independently optional through Minimap settings. Left-click toggles the GUI; left-drag moves around circular or square edges and saves an angle. The button follows map size/scale, pauses repositioning in combat, and keeps no idle update. MinimapButton.lua is a separate module so the launcher does not require square styling or stats. Settings row heights now follow one/two-line helpers, fitting all seven minimap options above the footer.

Version 0.1.12 replaces the custom delayed header hint with immediate native GameTooltip guidance using ANCHOR_CURSOR. Standard tooltip styling displays the same move/resize/reset and bag-menu instructions. No header hint frame or hover timer remains. Hide only when the tooltip is still owned by the corresponding header.

Version 0.1.13 limits item tooltip levels to equipment inventory types, including armor, jewelry, cloaks, weapons, ranged weapons/wands, shields, off-hand items and relics. Non-equipment, bags, quivers and ammunition receive no Suite item-level tooltip line. This filter is independent of usability for the current character. The October 6 correction below extends the same scope to icon levels.

The user's October 6 cooking screenshot showed item-level numbers on Slitherskin Mackerel and its raw-fish reagent. The icon path lacked the tooltip's equipment filter. Both now use `Items:IsEquipment` on every supported window, so only equipment and weapons receive levels. Recycled buttons clear previous levels before checking the current item, including missing/restricted data and delayed loading. Gear remains eligible even when unusable by this character. GUI helpers describe this equipment-only scope. In-game recipe and other-window retests are pending.

Version 0.1.24 responds to the user's October 6 screenshot of three gear icons without levels. The user authorized a read-only review of ZoidsTools Retail's `Modules/ItemOverlays.lua`; its current-location lookup and native container lifecycle served as behavior references. Forever Suite now prioritizes live bag/bank slots and equipment item locations over the inherited `GetItemLink` getter, whose value can remain nil on native buttons. Numeric labels retain rarity colors and move to the top-right corner above native overlay artwork. No Retail track letters, suffixes or upgrade-path API are included. Native bag/bank refresh hooks cover copied button mixins and pooled slots; reset, missing quality, restricted data and disable cleanup clear stale presentation. Item-level data remains independent of stat scoring. In-game confirmation is pending.

Version 0.1.14 presents equipment tooltip levels in the requested Retail style: one gold Item Level N line immediately below the item name. A tooltip pre-call inserts or replaces the ItemLevel data line before native rendering; post-call bookkeeping prevents a duplicate footer. Native text, binding lines and right-column equipment labels retain their order. Equipment-only scope remains.

Version 0.1.15 responds to the user's October 6 screenshot of the overhanging FS button. Its center track is inset by half the button size, with a one-unit allowance matching the square map's teal border. The button's outer sides align with that border at square edges and corners. Round placement uses the same inset radii; dragging and map-size updates share that geometry, retaining the saved angle.

Version 0.1.16 replaces the long player equipment tooltip sentence and item-count suffix with the requested Retail-style two-column row. The left label is gold Item Level; the right value is white and rounded to the nearest whole number. Self, cached and newly inspected levels share this layout. No M+ rating is added.

Version 0.1.17 follows the user's clarification that the FS launcher must sit outside the minimap. It supersedes the inward placement in 0.1.15. Square center radii add half the button size plus the map's one-unit border, making the button's inner edges meet the outer map border. Round placement accounts for the square button's footprint to keep it outside the curved map. Positioning and dragging retain the same saved-angle convention.

Version 0.1.18 addresses the user's report that unknown players can remain blank until clicked, and otherwise load slowly. Resolve a readable tooltip GUID against mouseover before the native GUID-to-token lookup. Start a cold hover request after 0.1 seconds, retain it through the three-second inspect cooldown, and replace abandoned requests when hovering another player. Check briefly for item data arriving after INSPECT_READY and retry missing responses up to three requests within a 30-second hover window. Cancel timers on clearing/hiding, combat, disabling the feature or external inspect takeover. Resume a still-visible hover after combat. The user confirmed the 0.1.16 layout for previously seen players; fresh inspection still needs an in-game retest.

## Camping decisions — October 6

Version 0.1.23 adds **Camping** and `/wfs camping` (alias `/wfs campfire`). The independent feature starts off. Its original low-profile slate and teal bar appears outside combat while the screenshot's **Campfire Nearby** aura is present. It remains useful with no carried objects because the pose button is always available at camp. The four choices are Sit, Kneel, Sleep and Lie down; selecting only changes the preference, and a hardware click on the secure pose button performs the localized native command. Blizzard's [September 24 beta notes](https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-october-1/2360696) explicitly confirm these poses, plus sitting in a chair, can receive campsite buffs. Chair use remains a native world interaction. No invented rest countdown or buff-earned indicator is added.

`CampingItems.lua` discovers finished objects from readable carried-bag metadata, an item-use spell and English tooltip text requiring a nearby campfire. This covers the supplied Lodestone example and discovers new object IDs without a fixed catalog. Recipes, ingredients and ordinary consumables are excluded. All discovered carried objects appear, including ones currently restricted by native profession/placement rules; native feedback decides whether they can be used. Duplicate stacks combine, names determine stable ordering, more than eight objects wrap, and native cooldown swipes/tooltip details are retained. Uncached metadata is requested once and rechecked on item-data events. Restricted records are omitted; action attributes always use a readable item ID, never a stale bag slot. Object discovery currently supports English tooltips.

The compact header drags without an unlock mode. Pose and normalized position are account-wide preferences, following the other Suite settings. Ctrl-right-click or the settings reset restores the default. **Preview position** creates a separate inactive outline with no secure item/pose buttons, so automatic gameplay visibility remains tied to proximity. Leaving settings, Escape or combat ends the preview. A native secure state driver hides the bar and the pose flyout in combat and leaves the bar hidden until a fresh out-of-combat proximity check; interrupted protected movement restores the last saved anchor after combat. Bag/aura work is coalesced with one cancellable 0.12-second timer; there is no addon OnUpdate or idle scanner.

EverCore's Campfire.lua and README were read as behavior references only. Forever Suite's scanner, UI, control flow and tests are newly implemented, and EverCore was not modified. The nearby aura ID 1283391 comes from that reference; the English screenshot name is also supported. The refreshed source metadata records build 70235, with addon sources identical to the earlier 70205 cache; the installed executable observation is 70235, and the running build/Interface remain unreported. The real proximity aura, native secure execution, item coverage, pose eligibility, visual fit and taint remain subject to the camping smoke test.

The October 6 combat report exposed an unprotected pose-chooser handle in the secure state snippet. The bar and chooser now both have explicit secure frame templates, with combat-driver registration last in construction. The original visibility rule remains: combat closes the bar and chooser; only fresh out-of-combat proximity can show the bar again. The separate position preview stays unprotected. Regression substitutes now reject unprotected restricted handles in combat instead of assuming protection flows from parent to child. Test open/closed choosers, an empty object inventory, repeated transitions and the retained driver after disabling; the live correction still needs `/reload` and the camping combat smoke test.

## Macro decisions — October 6

The user authorized review of `P:\GitHub Repos\EverCore` to make macro generation clearer. `PrepItems.lua`, `PrepMacros.lua`, README and preparation tests were read as behavior references. Forever Suite uses new code and its own GUI; EverCore was not changed.

Version 0.1.19 adds **Macros** and `/wfs macros`. Five fixed recipes use stable names (`FS Food`, `FS Drink`, `FS Bandage`, `FS Main Hand`, `FS Off Hand`). Select a recipe, read its explanation and generated preview, then click Create. Names, inventory slots and ordinary combat conditions are supplied by the recipe. No type/name/target/condition editor or custom-text builder is included. The preview supports copying. Users who want custom commands can edit in Blizzard's editor, which pauses further changes to that macro's text.

Food and drink prefer conjured supplies, then restoration amount, item level and quality. Buff food, energy items, sleep potions, recipes, non-use items and supplies above player level are excluded from automatic recovery. Classification from tooltip text supports English; explicit food/drink choices support other languages. Percentage restoration is classified without reading player health or power, using item level/quality for ranking when no flat amount is available. Optional combat additions start unchecked: Food attempts a carried Healthstone and healing potion, in that order; Drink attempts a mana potion. Both health actions can occur on one press if native rules permit; this is not a cooldown fallback.

Bandages target the player. Each coating recipe automatically selects the highest usable ordinary sharpening/weightstone tier matching its equipped weapon. Empty hands, shields and unsupported weapons have no automatic action. Selecting a carried oil, poison or other coating overrides stone matching; Select automatically removes that override. All coating actions stay outside combat. Special stat stones require a chosen item. Item-specific compatibility and replacement prompts remain native.

**Add item macro** supports up to ten independent chosen-item variants with generated names (`FS Item 1`, etc.), covering flasks, elixirs, scrolls and other use items. These keep the item's normal targeting and prompts. Remove choice stops management and retains the game macro. Removed serial numbers are not reused on that character. Ground-at-cursor and fixed armor-slot templates remain outside this first simplified version.

**Keep created macros current** starts off and is independent of other Suite features. It is an account-wide toggle, like the other Suite options. Recipe choices and combat additions are per character in `WoWForeverSuiteCharDB`; shared ownership is in the existing account database. The original per-character created-recipe gate is superseded by 0.1.92: existing confirmed Suite General macros automatically become active on other characters. General names are shared across characters: the last character explicitly creating or automatically updating a managed name determines its text. Existing EverCore and other unowned names are never adopted automatically.

No game macro is created from login, viewing a recipe, selecting an item or enabling updates. Events refresh created or recognized shared recipes outside combat. Updates require the current name/body to match Suite's confirmed ownership record. External text edits, duplicate names, missing macros, full slots and API failures produce feedback and retain other macros. A missing owned macro requires another explicit Create / update. Native macro editor visibility pauses writes to preserve unsaved edits; closing it queues a refresh. Incomplete or restricted item/weapon data retains existing text. A confirmed empty supply set clears obsolete automatic actions. Disabled, hidden macro tools retain no timer or event registrations; active refreshes use one cancellable 0.15-second timer and no OnUpdate.

Version 0.1.20 fixes the user's October 6 error opening Macros. The preview is an EditBox, whose SetFont requires an explicit flags string; it now passes an empty string for plain text. The API substitute enforces this EditBox-specific requirement and reproduces the original failure before the fix. The recipe design is unchanged; page construction and live rendering need a retest after reload.

Version 0.1.21 follows the user's screenshot and request to create an empty off-hand macro before equipping a relevant weapon. Both automatic weapon recipes now allow explicit **Create placeholder** when complete data shows an empty/unsupported hand or missing matching coating. The saved body is `#showtooltip`, with no use commands. The character's created record and account ownership are confirmed normally. With Keep created macros current on, equipment/bag events fill that same macro when a relevant weapon and carried coating become available, and return it to the inert placeholder when they are absent. Updates off preserves the placeholder until an explicit update or enabling updates. Pending/restricted data still retains the previous text; chosen-item and other recipe creation rules are unchanged.

The user confirmed that closing Blizzard's Macros window resolves main-hand creation in 0.1.20. Keep the native-editor guard: even creating another macro triggers native UPDATE_MACROS handling that refreshes the selected text, so writes while the editor is open can discard unsaved edits. The screenshot confirms the page renders after the font fix; it does not establish live coating execution or a running build. New placeholder behavior still needs its in-game smoke test.

## Damage meters — version 0.1.29

The user approved the October 6 interactive exploration and asked for the Forever Suite color scheme by default. The implemented module starts off and opens through **Damage meters** or `/wfs meters`. Its two original frames use slate panels and teal bars, compact native fonts and expandable native menus. Window 1 initially shows Damage / Current; Window 2 shows Healing / Current. Visibility, dimensions, row height, text size, class colors, background opacity, number presentation and content selection are independent. Snap enablement and gap are shared options. Details supplied a read-only behavior reference; no code, skin, assets, parser or libraries were copied.

Each header's metric menu groups Damage → Damage, DPS, Damage Taken, Avoidable Damage Taken, Enemy Damage Taken; Healing → Healing, HPS; Actions → Interrupts, Dispels, Deaths. Entries require their native enum. The client supplies source order, totals, maxima and rates; Suite does not derive DPS/HPS. Absorbs is omitted to match the native ten-choice picker pending a live capability check. Forty-eight prebuilt row widgets support the expanded height bounds and arbitrary source-list lengths through scrolling.

The session menu presents Overall and Current. Current expands to **Follow current fight** and the client's retained fights, with names, IDs and readable durations. Historical selection stays on its ID until changed or evicted; its name appears in the header. Current follows native session changes and Overall follows native aggregation/reset rules. A confirmed eviction returns the affected window to Current with feedback; an unavailable history query cannot falsely evict it. History is the client's retained segments, with no permanent archive or time-series replay. Suite saves preferences and layout only; historical IDs and combat data are runtime-only.

| Docking action | Implemented result |
| --- | --- |
| Drop against the other window's left/right edge | Match the dropped window's height; align top/bottom and preserve its own width |
| Drop against the other window's top/bottom edge | Match the dropped window's width; align left/right and preserve its own height |
| Drag either docked member by empty header space | Move the pair together |
| Drag either lower corner, Ctrl-wheel or edit size in settings | Preserve the join and equal shared dimension; the partner's other dimension stays independent |
| Detach from settings or Alt-drag | Separate without changing content; Alt-drag prevents re-snapping for that gesture |
| Ctrl-right-click empty header/background | Reset the selected layout and detach; retain metric/session/style |

Snapping uses a 12-unit edge threshold, a teal candidate border and a configurable 0–16-unit gap. Only visible Suite meter windows are targets. The stationary window remains unchanged during preview; size matching commits on release. Absolute rectangles avoid circular frame anchors, save positions relative to screen dimensions and clamp the pair together. An impossible pair detaches after a screen/layout change. Hiding either member preserves the other's saved position. The initial no-grip choice was superseded for these Suite-owned meters by the explicit October 6 request below; general native window tools retain their earlier gestures.

The source review found that Blizzard's primary meter belongs to Edit Mode and appearance settings are mostly shared. Two Suite-owned views allow the requested independent layout. They consume `C_DamageMeter` and use the explicitly secret-accepting native font-string/status-bar operations. Lua abbreviation, duration formatting and class-color indexing require readable values. Frame construction and layout changes defer during combat; combat display uses existing native widgets. Updates coalesce through one cancellable timer and OnUpdate runs only during dragging. The general mover excludes Suite meters. Native frames, CVar, Edit Mode and recording settings remain under native ownership; users must have native recording available to receive data. Source/spell breakdowns are added in 0.1.35 below; Absorbs remains outside the exposed native picker.

The matching 70235 source is pinned and unchanged from 70205. Lua/TOC and substitute behavior checks cover selectors, history, restricted values, layout and lifecycle; they do not establish ordinary-addon combat rendering or taint safety. Complete the meter smoke test in `docs/testing.md` before calling the feature verified.

Version 0.1.30 adds **Test both windows** alongside the two window tabs. It temporarily displays both meters with eight static sample players without enabling the module or changing either saved visibility setting. Six players fit the default height; the rest are accessible through normal scrolling. The existing renderer, metric choices, style controls, drag and docking remain usable. Header/footer label the sample display **Test data**. The same button becomes **Stop test**, with another stop action in each header's settings menu. Stopping restores prior real session selection, scroll offset and visibility. Tests end on combat, reload or explicitly disabling an enabled module; they can remain visible after closing settings for movement testing. No sample session is queried, recorded or saved, and no idle refresh timer is added. Layout/style edits retain their normal persistence. The installed executable is now 70245; its pinned UI-source commit changes only version.txt from 70235, leaving these APIs unchanged. In-game preview rendering remains pending.

Version 0.1.31 responds to the user's report that the unboxed selector text made finding a draggable spot difficult. Metric and fight selectors now have bordered slate button backgrounds, teal hover/press feedback and separate dropdown arrows. A 52-unit center gap carries passive grab dots, leaving that header input available for movement even at the minimum width. Both lower corners have small visible handles. They resize width and height independently, holding the opposite top corner until screen clamping is necessary. Bounds expand to width 240–1600 and height 120–1000, additionally limited by the viewport and docked partner's unshared size. Corner dragging works in test mode, preserves linked shared dimensions, saves only on release and discards unfinished changes on combat, option change, hide, disable or test stop. Layout/spatial work uses readable geometry only; the updater exists exclusively during the gesture. The general native mover receives no corner handles. In-game hit targets, visuals and corner transitions require the new smoke test.

Version 0.1.32 follows the user's annotated settings screenshot: all six numeric values move beside their labels in matching 64-unit right-aligned entry boxes, and 248-unit teal sliders occupy the space below. The two columns and three paired rows retain symmetrical spacing. Width, height, bar height, text size, opacity and snap gap share their existing bounds; sliders step by one unit and support wheel changes. Enter/focus loss commits typed values, including fractions; Escape cancels. Number and slider synchronization is guarded against native programmatic value-change callbacks. Live drag updates coalesce through one short cancellable timer, with final values committed on release, navigation or other settings actions. Edits retain the originating window, shared gap remains global, and gameplay layout changes still defer during combat. The supplied screenshot establishes the existing settings layout, without a running build or combat result. Native slider/thumb appearance and input still need live confirmation.

Version 0.1.33 responds to the user's two meter reference screenshots and request for a sleek layout with a lock. The original Suite slate/teal style now uses a 24-unit header, smaller translucent selectors, faint one-unit borders, tightly stacked full-width bars, native-order rank numbers and outlined row text. The separate footer and opaque row tracks are removed. Readable duration moves into the metric button when width permits, with the full metric/time in its tooltip; player ranges move into the options tooltip and a small passive cue indicates more players below. All eight test players fit the existing 300-by-220 default, without changing saved sizes/styles. Both corner handles use unobtrusive 14-unit hit areas with no boxed backgrounds.

The shared, saved `meterLocked` setting starts false and is accessible through either header's original drawn padlock, both settings tabs and either options menu. Locking hides corner grips and header dots and blocks movement, snapping, corner sizing, Ctrl-wheel and background Ctrl-right-click reset. The shared scope prevents a docked partner from moving a locked window. Metric/session menus, scrolling and deliberate settings edits remain usable. Locking cancels unfinished gestures and restores committed geometry; changing the lock during combat touches only existing unprotected presentation widgets. General native window tools retain their original controls. No reference code/assets were copied. Offline checks pass; native visual/input, combat and persistence verification remains pending.

Version 0.1.34 adds the requested quick reset as an original 18-unit header arrow beside the lock. One explicit click calls the native shared `C_DamageMeter.ResetAllCombatSessions`, clearing Overall, Current and retained fights in Suite and native meters. The tooltip states that shared scope; no automatic reset occurs. Both views clear historical IDs and scroll offsets and refresh immediately; native synchronous reset events are reconciled without a stale timer. Metrics, session preferences, styling, geometry and lock remain intact. Missing/unavailable capability leaves data untouched. Test mode rewinds sample rows only and retains real history/scroll. The existing settings/menu layout reset remains separate.

The user's follow-up also reduces the session selector to a 24-unit **C** or **O** button. Current historical selections use C with the complete fight name in the tooltip and original menu; Overall uses O. The freed space enlarges the metric title and header drag gap. Test mode places a passive **TEST** label in that gap, including when locked, so compact letters never conceal sample data. Native reset, header icon readability and compact selector input still need client verification; offline checks pass.

Version 0.1.35 adds left-click player bars and one compact original 440-by-370 spell breakdown popup. It captures the originating window, metric, session/fight and a readable source GUID or creature ID. Native source queries supply total, ordered spell amounts/rates and per-entry unit/recipient names. Eight prebuilt rows scroll through the full list. Existing coalesced meter events also refresh the popup, while source reordering cannot retarget an open selection. Bars retain scrolling and a subtle hover cue, including while locked. X/Escape, owner content changes/hiding, reset, disable and preview transitions clear the selection. Sample players have invented ability/unit breakdowns without native source reads or saved combat data.

The popup and its rows are built only outside combat when meters/testing are active. A combat click shows and updates existing unprotected widgets without construction or geometry changes. The source APIs permit secret arguments only from untainted code, so hidden identifiers are never passed from addon code or reconstructed. A restricted source still opens the popup with its native displayed total and asks for a new click after combat. Secret names/amounts/rates/maxima reach permitted native display operations only. Secret spell identifiers may feed the explicitly taint-permitted GetSpellName presentation API; readable missing spell IDs use bounded async name requests. Missing endpoints, restricted outer records and absent identity show explicit feedback. Native combat availability, graphics, taint and Escape/input behavior remain pending.

Version 0.1.36 adds the requested total-and-DPS presentation: **972.6k (38.9k)** on damage bars, with total/HPS on healing and the supplied equivalent rate on damage-taken categories. Both components follow each window's compact/full preference and selected session; no duration division or extra data queries are needed. DPS/HPS-only views and action counts retain their existing displays. Zero rates show `(0)`; missing or invalid readable rates leave only the total. Each component is guarded independently, allowing readable abbreviation beside an untouched restricted value using native SetFormattedText. A wider value column scales with the selected font and window width while retaining a separate name column. No text readback, saved combat data or additional update loop is introduced. Automated checks pass; native formatting and narrow-window readability require the added smoke test.

## ForeverWoW.gg scoring investigation — November 7, 2026

Research only: [findings](foreverwow-scoring-research.md) recommend expanded supported stat keys and explicit spec profiles as the first upgrade-scoring improvement, followed by validated effects and actual equipped-set breakpoints. Current five presets and Automatic class starter miss important spec distinctions and secondary stats. Preserve custom profiles, independent switches and legal hand comparisons. Implementation is not part of this research request; no weights or runtime behavior changed.

