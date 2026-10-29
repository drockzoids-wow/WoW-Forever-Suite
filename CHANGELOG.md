# Forever Suite

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
