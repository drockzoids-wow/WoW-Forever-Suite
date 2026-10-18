# Forever Suite

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
