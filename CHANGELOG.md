# Forever Suite

## 1.0.8 — November 8, 2026

- Recover older contacts with no assigned server type through Contact book's Recover unassigned contacts view. Select a name and Save to assign it to the current server type while preserving notes and categories.
- Keep player-created contacts in account-wide SavedVariables independently of mail-feature switches, guild membership, settings profiles and filtered views. Preserve the original book during legacy migration or unfamiliar-format recovery. WoW writes SavedVariables on reload or orderly logout; a crash can lose changes made since its last save.
- Add Alts, Guild and Other tabs beside Send Mail and to Contact book, with All in the book. Include available offline guild members, prioritize known account alts, retain custom categories/notes and save guild members as ordinary contacts.
- Color names by known class across all mail groups and retain observed guild classes on saved contacts after guild departure and reload. Contacts without known class data retain normal text.
- Add mouse-wheel paging across Suite lists, including rows, child buttons, list gaps and paging controls. Preserve normal settings/text scrolling and existing slider behavior. Include saved bag/bank pages and standalone tools.
- Prefer food with a disclosed positive kill-experience bonus in automatic FS Food selection. Explicit carried food choices retain priority; existing combat, editor, item-data and macro-ownership safeguards remain.
- Offline checks cover persistence, recovery, guild classes and wheel routing; actual in-game wheel capture and detailed color/taint retests remain pending. The reported game crash has not been diagnosed.

## 1.0.7 — November 8, 2026

- Keep bag selectors hidden during gamepad label refreshes and preserve independently enabled saved bags when bank snapshots are disabled or unrelated settings change.
- Recheck the created food macro when native bags open, even with background updates off; coalesce opening bursts and preserve combat, editor, item-data and manual-edit safeguards.
- Show concise server types such as PvE in inventory character dropdowns and match Contact Book's region/server-type isolation for bag and bank selections.
- Add a tiny refresh-icon button beside each inventory character dropdown to return to the current character.
- Add character dropdowns to bank and backpack/combined bags for saved inventory slots. Keep shortened combined search on the right and stack individual backpack search above its selector; show recording time and view-only status.
- Keep available ability proc popups visible with the native low-resource icon tint when rage, mana or energy is insufficient; restore brightness when resources recover.
- Strengthen the Shift bypass for innkeeper, vendor and quest conversations: check physical Shift independently of bindings and latch presses between dialogue events and queued advancement.
- Keep input fonts and anchors stable while typing; apply pending changes after focus loss or hide and honor combat deferral. Initialize chat appearance even when native inactive input stays shown, hide unpainted backdrops and avoid resetting matching fonts or anchors.

## 1.0.6 — November 7, 2026

- Use the native macro-with-tooltip predicate for action-bar use detection; a resolved legacy item action must not prevent a supply check. Add one coalesced check of created item-use macros at login/reload, independent of background updates. Finish incomplete stock checks on bounded bag-completion events; retain no idle refresh.
- User confirms the automatic food fix works in game. Other detailed native checks remain qualified separately.
- Check created item-use macros once after native macro/action use, independently of background class-spell updates. Keep carried choices, fall back when depleted, clear unavailable custom-item actions and retain saved preferences for restocking. No idle supply polling; combat/editor writes defer and incomplete data preserves existing text.
- Render short keybind labels in Suite-owned overlays, preserving Blizzard's HotKey text. The reported action-bar visibility block still needs a focused native retest.
- Scope mail contacts automatically to the current region/server type, add an existing-category chooser, and recover recorded contacts with CAMWOW realm labels while preserving metadata and removal decisions.
- Open Suite companion tools beside their launcher with scale-aware screen clamping; retain dragged Chat Copy placement on Refresh and keep inventory browsers visible when opening saved banks.
- Refresh the pinned Forever training data: correct Paladin Righteous Fury level/cost and Retribution Aura cost, correct three Shaman prices, and include level-50 Lava Burst rank 3 with its talent/rank requirements. Recorded trainer prices remain independent.
- Remove unused settings/planner bookkeeping and review all shipped modules against pinned build-70862 Blizzard UI/API source. Offline checks do not establish native compatibility or taint safety.

## 1.0.5 — November 6, 2026

- Add a per-character Training Planner wishlist with Pin/Unpin controls, search and pagination. Estimate outstanding costs using base or recorded prices, excluding trained ranks and disclosing unknown prices. Widen Unpin buttons to prevent truncation.
- Add an optional Supply Checklist with up to 32 per-character item targets, carried-stock shortages, editable quantities and confirmed removal. Tracking starts off; unavailable bag data remains unknown and bank stock is excluded.
- Add optional mailbox deadline recording, regional saved-record review, character-dashboard summaries and one login reminder for nearby/passed recorded deadlines. Show partial inbox coverage and checked times; a passed observation never claims confirmed mail loss.
- Add What's New under Suite Settings, with links to recent features and their settings.
- Add a standalone contact book with full-name/ruleset editing, categories, notes, search, filters and paging, available away from a mailbox and independently of mailbox integrations.
- Expand every class's macro library with leveling and PvP utilities, plus the requested Druid Prowl recipe. Keep explicit creation/update, localized spell lookup where applicable, ownership protection and combat deferral.
- Restore ordinary bandage targeting/self-cast behavior in FS Bandage while retaining automatic supply updates at the existing managed macro index.
- Add default-off chat shortcuts for Blizzard key bindings, Edit Mode, macros, calendar, settings, AddOns and reload. Preserve existing alias owners and provide namespaced alternatives outside combat.
- Add default-off automatic own-item/trade enchant replacement confirmation for enchanters, independent of modifier Disenchant. Other confirmations and final trade acceptance remain manual.
- Widen damage-meter session selectors so the Overall initial fits beside the dropdown arrow; user confirms the fix in game.
- Validate 80 Lua files as Lua 5.1, identical TOCs and 30,536 behavior assertions with API substitutes. Relevant native checks remain documented separately. The previously reported world-map and quest-tracker combat taint issues remain open for monitoring; the user reports no recent recurrence and defers further investigation. No taint fix is claimed in this release.

## 1.0.4 — November 6, 2026

- Replace expanding workspace navigation with fixed sidebar sections and category directories. Add focused views for bags, item levels/upgrades, action bars and buff reminders, with search links into nested settings.
- Add an optional talent build planner beside the native talent window: saved class builds, draft editing, point order, undo/redo, notes, import/export and guidance through manual native learning.
- Add nine built-in leveling starter references with level browsing, talent comparisons and editable personal copies.
- Make talent icons reflect draft spending and orange outlines reflect available next ranks. Enforce per-tree row requirements independently of learned native talents, including zero-spending condition handling.
- Show the no-bonus point-based level reference below the actual earned-point budget. Add an undoable Reset draft button beside Limit to current level. User accepts the current talent workflow for production.
- Add optional per-character quest-tracker collapse persistence.
- Add campfire hiding for normal buff reminders, retain rested-area hiding and keep enabled combat reminders independent of those filters. Move buff positioning into the settings preview and remove its movement-lock control.
- Exclude armor kits from weapon-coating choices/reminders and remove Shaman totems from the built-in buff reminder catalog.
- Prefer word-prefix matches in weapon trainer search, so Bows wins over Crossbows when searching for bow.

## 1.0.3 — Release candidate (November 5, 2026)

- Center and scale spell labels, progress markers, cast-edge effects and clipping masks with custom castbar height. Restore native geometry when custom sizing is disabled or Edit Mode opens.
- Replace direct chat selection with a Suite copy window using ordinary Ctrl+C. Preserve native message/class/item colors, add a bottom-right Refresh button and match Suite styling. Paper opens its own chat tab; /wfs copychat uses the selected tab. Unavailable/hidden-name text is omitted; closing/combat clears the snapshot. Remove the retired selection, copytest and probe paths.
- Add optional combat ability proc popups with animated borders, saved placement, a 24–128 px size control and an outside-combat preview. Live popups always pass mouse input through. Native Overpower consistency and other-class coverage remain under test.
- Add an optional equipment-manager control to ignore/include non-weapon slots for an existing selected set. Save remains manual; weapons and ammo stay unchanged.
- Add Class spell search and Weapons trainer search to the Training Planner, with compact controls, centered labels and a borderless clear button. Class matches retain their original page references.
- Add consistent theme-colored hover/press feedback and shared close, clear and recipient-removal controls throughout Suite windows.
- Allow settings to move beyond screen edges; right-click the minimap launcher to center and open settings again.
- Establish combat buff title-mask anchors before native descendants become forbidden, fixing the reported dungeon anchor-error path in substitute tests. Native dungeon verification remains pending.
- Combine recipients of the same missing buff in one icon/tooltip. Keep a floating title and icon-only reminders, shared size/scale controls and normal/combat previews; locked title space passes clicks through.
- Center combat weapon reminders on their own row beneath native aura reminders. Unavailable coatings no longer reserve empty combat space. Native aura slots remain reserved when healthy; full visible-icon compaction is not implemented.
- Restore enabled damage-meter windows on world entry after reload.
- Include armor in built-in gear comparisons, preserving custom weights and preferred-armor colors.
- Preserve multiple-service gossip menus and the Training Planner's saved All levels / By level choice.
- Include health-restoring buff food in automatic FS Food selection and normalize tooltip colors/wrapping during recovery-item classification, preserving mage and seasonal priority.
- Remove the superseded session-only Battle Shout prototype and its slash command, empty buff-caption widgets, duplicate inventory hover artwork and a redundant damage-detail close callback.
- Remove the resolved temporary castbar artwork report and an unused proc-size cache.
- Align Core and both TOCs at 1.0.3, avoiding existing local release tags. Offline checks and packaging do not establish in-game compatibility or taint safety.

## 1.0.1

- Collect the ForeverWoW.gg BiS minimap button even though its icon texture is private.
- Make Square minimap expand the shorter side to match the longer side, retaining Edit Mode scale and position. Disabling restores the latest native dimensions; combat defers resizing. No new map icons or controls.

## 1.0.0 — Initial release (planned November 4, 2026)

- Remove unused runtime fields and callback arguments; simplify buff-border creation and test visible buff/chat behavior directly.
- Establish the accepted 0.2.104 feature set as the planned Forever launch release.
- Include the modular Suite settings, profiles and setup guide; inventory and gear tools; window, minimap, chat and combat tools; vendor helpers; readable journey journal; and built-in class/weapon training planner.
- Preserve existing preferences, session history and optional feature defaults.
- Prefer seasonal food/water after mage supplies, including Hallow's End candy for health and mana.
- Show blocked or failed macro updates in red and confirmed saves in teal.
- Let explicit Update apply the preview to previously owned, manually edited macros; preserve background and food-picker edit protection.
- Keep macro Create/Update and automatic-update buttons above the copyable preview input layer.
- Feed pets using the chosen food's exact localized name, with separate combat/dead/absent guards for item targeting.
- Apply deliberate pet-food changes to existing owned macros even when automatic updates are off; retain reagent-bag ingredient support.
- Add an optional combat start/end indicator with persistent display, saved movement, click-through lock, preview and reset.


## 0.2.104

- Hide gear-upgrade plus markers on equipped item buttons while preserving item-level labels.
- Keep separate bag copies eligible for second-slot upgrades and reset the equipped flag when buttons are reused.

## 0.2.103

- Reconcile the readable journey journal and default level 1–60 training catalog into the canonical P: repository.
- Add labeled journal cards and Loot/Reputation/Levels/History views while preserving prior session totals.
- Include base training costs/prerequisites from first login; preserve recorded prices and complete weapon-master references.
- Bring earlier layout/unused-code fixes into canonical source and dispatch combat reminders once after preview cleanup.
- Preserve newer vendor, chat, profile and setup changes; no deployment or junction change.

## 0.2.102

- Add optional green highlights and checkmarks for already-known vendor recipes and collected items, including pets when readable ownership is available.
- Refresh highlights when paging, switching Buyback, learning spells/recipes or updating the pet journal; keep native purchases, prices, quality colors and tooltips intact.
- Add the default-off setting under Vendor > Known Items and as an optional setup-guide choice.

## 0.2.101

- Add per-character leveling session history with Current, Previous and Overall recaps, dates, observed level endpoints, XP, net gold and rates. Reload continues Current; completed sessions remain available with tracking off.
- Expand the five-step setup guide with scrollable choices and show its first-use welcome after entering the world, preserving previous completion and profile behavior.
- Show green upgrade markers for preferred armor and yellow for other usable armor improvements, with matching tooltip explanations.
- Keep the quest tracker's owned background below native text, controls and timers during parent restacking.
- Reconcile these updates into the official P: checkout, preserving newer chat styling, vendor conversations, profiles and removal of standalone quest guidance.

## 0.2.100

- Brighten the channel-colored typing-box border for visibility while preserving the dark fill, alignment and visible gap.

## 0.2.99

- Match the typing-box border to the active chat channel color, including Say, Guild and whispers.
- Soften its border to the chat panel's opacity while preserving the dark input fill and visible gap.

## 0.2.98

- Darken the chat typing box for readability while preserving its visible gap and alignment below chat.
- Keep message/tab transparency adjustable and native typing behavior intact.

## 0.2.97

- Remove the standalone quest map pins, nameplate marks, location learning, bundled catalog and local updater at the user's request.
- Remove their settings page, search entries and command aliases; discard retired saved fields on reload.
- Keep the existing quest automation, tracker style, nearby quest-item button and vendor auto-talk.

## 0.2.96

- Show Suite quest pins only on individual zone maps; remove continent/world projection.
- Clear old pins immediately when changing maps, and skip quest scans on unsupported map scopes.
- Preserve zone coordinates, completion filtering, hidden quests and native map providers.

## 0.2.95

- Add standalone map markers for cataloged uncompleted quests, native active objectives and optional learned quest-giver locations.
- Add optional yellow quest-mob markers to the left of nameplates using public native quest relevance.
- Add per-quest map hiding, restore-hidden and clear-learned controls under Everyday → Quest Locations.
- Include a compact Classic reference catalog and local data update tools; neither Questie nor QuestieDB is required.

## 0.2.94

- Add an independent Vendor option to open a shop without the extra dialogue click, including menus with quests or other services.
- Hold Shift when talking to keep the menu open; multiple shops and confirmation prompts stay manual.
- Save shop-opening choices with the active settings profile.

## 0.2.93

- Add Interface → Appearance: default teal, your current class color, or a custom color wheel.
- Apply the choice across Suite-styled borders, including skins, minimap, chat, Training Planner and profile controls.
- Preserve hover feedback and transparency; preview custom colors live and restore the previous choice on Cancel.
- Save colors with your active settings profile and defer combat recoloring until combat ends.

## 0.2.92

- Add native ability icons to Class training, including saved and future-level offerings.
- Use gold ability names, teal level headings/numbers, green availability and amber requirements/confirmation text.
- Save validated trainer icons and resolve older entries by native name where possible; retain placeholders when data is unavailable.

## 0.2.91

- Apply the compact, color-coded trainer/city header to every weapon page, including saved visits and all Alliance/Horde masters.
- Show the full district/building for known masters; keep recorded locations as a fallback for other trainers.
- Identify historical weapon costs as Saved total in the footer while preserving the common window size and controls.

## 0.2.90

- Keep Training Planner at the same size across Class, weapon references and recorded visits.
- Keep totals and footer buttons in fixed positions while preserving the compact weapon reference header.

## 0.2.89

- Compact weapon reference headers into a teal trainer name and gold city, with the district/building in a muted line below.
- Remove the separate Reference/faction/trainer row and the header's base-price explanation; show the city only once.
- Move the list and footer up and shorten reference windows by 36 units; preserve full detail for saved and current trainer visits.

## 0.2.88

- Add native weapon proficiency icons beside names in Training Planner reference lists and recorded weapon-trainer visits.
- Separate weapon names from muted requirement text while keeping prices aligned.
- Refresh missing icon data asynchronously with bounded requests and cancellable work; preserve the Class tab's full text width.

## 0.2.87

- Add Home → Training Planner with an Open button, trainer recording and all automatic-opening choices together.
- Show saved class training beside the spellbook when recording is enabled; turn this off independently with Show with spellbook.
- Close only an automatically opened companion with the spellbook, retain manual dismissal for that opening, and cancel stale combat popups.
- Make every planner control searchable and point the planner's Settings button to its dedicated page.

## 0.2.86

- Add optional per-character main-chat history: remember up to 250 lines and restore automatically after reload or login.
- Keep saved messages before current-session chat, preserve links and mute old colors with a session divider.
- Add enable/disable and clear-history controls under Interface → Chat; no appearance changes or manual tuning required.
- Bound saved data, exclude inaccessible text, and prevent duplicate replays or recording of replayed messages.

## 0.2.85

- Left-click a gold incoming-buff reminder to ask for that buff in party, raid or instance chat.
- Recheck the current buff/provider before requesting; keep right-click hiding and original usable-spell/item actions.
- Add per-buff/global click cooldowns and local feedback for stale, restricted or unavailable requests. Never send from automatic updates or retry rejected messages.

## 0.2.84

- Keep teammate-provided missing buffs visible as gold Group icons instead of local-chat-only reminders, including Arcane Intellect for Hunters.
- Add class-aware incoming/outgoing targets and learned alternatives; accept readable level-zero metadata and retain conservative unknown-data handling.
- Update Forever baseline Spirit/Fear Ward and raid resistance-aura scope, without inferring unseen talents or future Salvation changes.
- Add learned-name/icon custom selection, a searchable hidden-family manager, individual restore, alternative choices and duplicate-rank protection.
- Add scale/icon-size controls, movement lock, class-aware targeting preference and configurable rested-area visibility; useful defaults require no manual edits.
- Keep secure combat hiding, native action checks, optional module switches, local notice throttling and no group messages/automatic casting.

## 0.2.83

- Move Profiles to its own top-level sidebar section alongside Home, Bags & Gear and Combat.
- Open the profile page directly without a duplicate nested entry; preserve all saved profiles, search and slash shortcuts.

## 0.2.82

- Preserve the current setup as Default and add named settings/layout profiles under Home → Profiles.
- Add independent current/character copies, shared settings, per-character differences, rename and confirmed removal of unused profiles.
- Show the active editing scope throughout settings; review changes before an explicit UI reload. Keep outgoing settings and private overrides saved.
- Keep inventory, macros, gear weights, contacts, item protection, training and leveling records separate. Block profile changes in combat.
- Add bounded/readable-only persistence, corruption recovery and startup, inheritance, reload and GUI regression coverage.

## 0.2.81

- Replace unsupported arrow and multiplication glyphs in upgrade tooltips with plain `->` and `x`.
- Preserve comparison scores, signed stat changes, profile names and tooltip ownership.

## 0.2.80

- Add two researched class recipes each for Druid, Mage, Paladin, Priest, Rogue, Shaman, Warlock and Warrior; retain the Hunter pair.
- Use client-localized spell names and complete targeting defaults without manual name/rank/equipment edits.
- Reuse explicit Preview/Create, class filtering, General-tab ownership protection and combat deferral.
- Add class-spell search keywords and keep the macro UI pool bounded to the visible class, shared recipes and ten custom items.

## 0.2.79

- Redesign the Suite panel as a wider 1120×760 workspace that automatically fits the available screen.
- Replace the crowded horizontal page tabs with five expandable sidebar workspaces; keep Setup Guide separate at the bottom.
- Add a Home screen with six direct tool shortcuts and remove duplicate Home switches.
- Arrange related settings in aligned two-column cards with more padding and measured text space.
- Widen character/inventory tables, macro list/details and setup cards. Use three columns for gear profiles and weights to reduce scrolling.
- Preserve the user-confirmed scrollbar controller, feature switches, saved choices and all 24 page routes.

## 0.2.78

- Replace native-slider scrollbar dragging with explicit thumb movement that preserves where the thumb was grabbed.
- Map cursor motion across the actual free track, keeping large thumbs predictable on short-overflow pages.
- Page through content when clicking above/below the thumb; preserve wheel scrolling and proportional sizing.
- Cancel drag tracking on release, hide, page/range/viewport changes, invalid cursor data or combat. No idle update loop.
- Exercise real cursor deltas, grab points and UI scales in the scrollbar regression fixtures.

## 0.2.77

- Correct reversed scrollbar thumbs throughout the settings GUI, macro recipe list, macro preview and setup review.
- Keep top/middle/bottom thumb positions consistent with content, wheel scrolling and page changes.
- Synchronize nested scrollbar state when content shrinks even without a second native scroll callback.
- Correct the earlier direction assumption in regression coverage and check every settings page.

## 0.2.76

- Unify Characters, recorded inventory search and saved bank access in an original Characters/Inventory workspace.
- Browse all recorded items immediately, filter by owner and location, and save eight searches with their filters.
- Show snapshot ages, distinguish unrecorded locations from recorded empty locations, and count shared-bank contents once.
- Open an alt's saved bank explicitly without enabling recording or reading the live bank; preserve normal current-character bank access.
- Handle delayed item names in finite batches; cancel hidden or combat-deferred presentation work.

## 0.2.75

- Add character-specific gear-comparison profiles, with an Automatic class leveling starter and five ready-made roles; custom editing remains optional.
- Preserve existing role/comparison choices on migration and support eight named custom copies per character with explicit Save/Cancel and guarded removal.
- Explain upgrade hints with equipped/candidate scores, signed stat contributions, actual accessory replacements and complete weapon-hand comparisons.
- Add Summary/Full breakdown tooltips, small-gain formatting, searchable profile controls and /wfs gear.
- Keep unknown data conservative, built-in presets intact and editor setup deferred during combat.

## 0.2.74

- Show only the character's faction in the Weapons tab: Alliance masters for Alliance, Horde masters for Horde.
- Apply the same separation to recorded visits, preserve older history and retain class-only level-up reminders.


## 0.2.73

- Separate class training from weapon trainer visits so weapons cannot replace the class list or appear in level-up reminders.
- Add Class and Weapons tabs, with eight capital-city weapon masters, locations, stock and reference base prices plus separate recorded visit prices.
- Keep older mixed records out of level-up reminders; visit a class trainer once to refresh the Class list.

## 0.2.72

- Keep native quest timer headings and countdowns above the Suite quest tracker background.
- Move only the Suite background to a lower layer while preserving native timer layout and behavior.

## 0.2.71

- Fit the bag bar skin's backgrounds and teal borders to the native icons, correcting oversized frames around the backpack and keyring.
- Preserve native icon colors, counts, highlights and click areas; retain native frames when icon layout is unavailable.

## 0.2.70

- Fix overlapping Training Planner and settings windows drawing their text, borders and controls through each other.
- Bring opened windows forward together and make the planner background opaque.

## 0.2.69

- Wait for the current quest's data to load before automatic pickup, matching the readiness approach used by Retail ZoidsTools.
- Recheck the visible offer, NPC, Shift bypass and combat before acceptance; failed loads stay manual and can retry when the offer is opened again.

## 0.2.68

- Show missing buffs in local chat when you have no compatible spell or carried item; remove unavailable-supply and Ask placeholders from the buff window.
- Keep usable spells, selected coatings and carried alternatives on the bar, with native item icons and deliberate item selection.
- Move the default Missing Buffs position to top center near breath/fatigue bars while preserving saved custom positions.

## 0.2.67

- Fix damage-meter layout errors by giving pinned personal rows the backdrop template required for their opaque background.

## 0.2.66

- Fix reversed GUI scrollbar dragging so the thumb and page follow normal up/down movement.
- Keep mouse-wheel scrolling and nested macro/setup/preview scrollbars synchronized.

## 0.2.65

- Fix damage-meter refresh errors when startup layout has not prepared the visible rows yet.
- Keep new windows hidden until geometry is ready and recover through normal events, including combat exit and delayed third-window creation.

## 0.2.64

- Attach the Training Planner beside the native trainer, preserving standalone placement for saved views and level-up reminders.
- Open Available now after each level, with combat deferral and a separate reminder toggle.
- Include clearly labeled saved skills whose level requirement is newly met, while keeping known unmet prerequisites separate.

## 0.2.63

- Match supported native meter behavior with specialization icons, pinned personal rows, pet labels, death times and native recap clicks after combat.
- Add a live combat clock, native value-detail choices, icon/visibility/mouse-input controls and stable header-only minimization.
- Add an optional third meter while preserving the first pair's snapping, shared lock and saved appearance.
- Preserve native source order, totals and retained fights; keep hidden-value calculations and restricted detail queries guarded.

## 0.2.62

- Add an optional Training Planner with saved trainer offerings, future-level groups, costs and savings gaps.
- Add optional buff-expiry warnings, learned custom spells and weapon-coating reminders.
- Add passive combat reminders for selected class buffs and coatings, preserving native action restrictions.

## 0.2.61

- Fix damage-meter errors with class colors enabled, including player rows and spell details.
- Preserve class colors without allocating a color table for every row.

## 0.2.60

- Fix auto-open getting stuck after fast looting when several containers are acquired together.
- Resume after the native loot window finishes closing and continue past rejected items without repeatedly retrying them.

## 0.2.59

- Reduce damage-meter allocation overhead with viewport-sized player-row pools and fewer repeated native data queries.
- Build the main settings panel when first opened and defer settings opens during combat.

## 0.2.58

- Align the threat indicator with the target frame's visible left edge.
- Strengthen the threat background color for combat readability while retaining transparency.

## 0.2.57

- Fix automatic container opening being paused by a hidden bank panel, including the reported Small Barnacled Clam case.
- Restore native chat text-copy gestures to address the reported blocked clipboard action.
- Includes optional inventory, map, interface, combat, chat, mail and leveling tools.
