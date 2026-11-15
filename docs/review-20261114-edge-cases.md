# Addon edge-case review — November 14, 2026

The user requested a deep review, initially with publication only if no improvements were found. The follow-up explicitly authorizes fixing all three findings and publishing the latest updates if checks pass. The original findings below describe the pre-fix behavior; resolution and validation are recorded next.

## Resolution for 1.0.18

All three findings are addressed. Drag completion queues re-arming; a fresh matching out-of-combat click can restore the existing action before that worker runs. Drag releases remain suppressed and combat-interrupted cleanup defers. A separate cooldown presentation method handles native cooldown events for the retained item during combat without changing selection, attributes, layout or visibility. Invalid/restricted timing clears the stale swipe without arithmetic on unreadable values.

Auto-open now prunes vanished GUIDs only after a complete scan that corroborates occupied/empty slots through C_Item.DoesItemExist, validates IDs/counts/GUIDs, and rechecks bag sizes. Zero-capacity equipped bags or unavailable equipment state preserve the old history. Moved, locked and rejected carried stacks retain retry suppression. No new timers or idle polling were added.

Final offline checks pass 93 Lua 5.1 files, matching Core/TOCs 1.0.18 and 46,599 substitute assertions (38 additional assertions), plus all 11 gear-baseline tests and git diff --check. Regression covers both original reproductions, immediate next-click and binding use after dragging, combat interruption, repeated combat cooldown changes, invalid/restricted timings, 1,000 obsolete GUID records, moved/locked stacks and incomplete scans. The 102-file addon-only package matches source by SHA256. [Release record](release-1.0.18.md).

Pinned build-70862 ItemDocumentation.lua documents GetItemCooldown's public number/number/bool shape. FrameAPICooldownDocumentation.lua and Blizzard_ActionBar/Shared/ActionButton.lua document/use SetCooldown and Clear for presentation updates, separate from secure button actions. Native input, combat widget permissions and taint confirmation remain pending.

## P2: Restore the quest action after dragging

QuestItem.lua clears type1 on drag start (line 142), but StopDrag only saves/restores placement. A drag release normally ends the drag without executing a button click. On the next deliberate click, OnMouseDown clears suppressClick, but PreClick never restores the missing action. The first click can do nothing; its PostClick queues the refresh that makes a later click work. An intervening quest, bag or player-movement event can mask this.

An isolated probe in the existing fixture completes a drag, drains work, and invokes the next mouse-down/PreClick: type1 is nil instead of macro. Native drag event ordering still needs confirmation.

Suggested change: queue a fresh selection/action refresh at drag completion while preserving release suppression. Cover the first subsequent mouse click/keybinding and combat starting during/just after a drag.

## P2: Update combat quest-item cooldown presentation

QuestItem.lua:163 defers all Refresh work in combat. Cooldown events reach Queue, which also defers. The newly enabled combat item action therefore cannot start or update its displayed cooldown until combat ends. An existing swipe can continue, but newly changed timing remains absent/stale.

A fixture probe changes readable cooldown timing from start 10/duration 30 to start 50/duration 60 during combat, dispatches BAG_UPDATE_COOLDOWN and drains work. The widget retains 10/30.

Suggested change: separate guarded cooldown presentation for the retained item from protected selection, attributes, visibility and positioning. Verify permitted widget operations, restricted timing and repeated combat uses in the client.

## P3: Prune obsolete auto-open attempt history

AutoOpen.lua:135 records each attempted physical container GUID. Successful disappearance, Cancel and bag updates never prune these entries; only disabling the feature clears them (line 237). Memory follows all containers attempted during a session rather than containers still carried. This is a small lifetime improvement, not an observed performance failure.

Suggested change: prune absent GUIDs after complete readable bag scans. Preserve records during incomplete scans and for unchanged carried stacks so denied lockboxes cannot enter a retry loop. This finding is from code inspection; no memory benchmark was performed.

## Validation and limits

- Full addon check: 93 Lua 5.1 files, matching TOCs/Core and 46,561 passing substitute behavior assertions.
- All 11 separate gear-baseline tests pass; git diff --check passes.
- Runtime static scan against pinned build 70862: 5,144 documented APIs indexed, 167 namespace references, no detected duplicate literal keys, unknown directly registered literal events or too-short documented calls. Global assignments match existing declared/compatibility uses. Two existing guarded MerchantKnown pet-journal fallbacks remain undocumented in that reference.
- Focused manual inspection covered pending runtime changes and action/lifecycle boundaries in quest items, peer version checks, tooltips, vendor, quests, loot, auto-open, bag sorting, bank deposit, equipment sets, profiles, mail and saved chat.
- Ignored reproduction runner .cache/deep-review-20261114.cjs injects probes into fixtures in memory without modifying tracked tests/runtime. It reproduces both quest-item findings alongside the passing existing suite.

This offline review does not establish native compatibility, rendering or taint safety, or constitute a manual audit of every runtime path. Actual running build/Interface, combat item activation and the existing UseContainerItem taint investigation remain unresolved. Publication status belongs to the release record above. No game deployment, junction or real SavedVariables changes were made.
