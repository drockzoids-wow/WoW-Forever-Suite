# Pre-release cleanup review — October 28, 2026

Work performed in `C:\Games\Development\GitHub Repos\WoW Forever Suite`. Existing uncommitted feature changes were preserved. Version remains 1.0.0.

## Review scope

- Parsed all 67 runtime Lua files with scope-aware Lua 5.1 AST analysis. Inspected unused-binding candidates, method-name references, write-only field candidates and unreachable statements. Reference scans are supporting evidence, not proof that a dynamically accessed field is unused.
- Traced candidate fields through runtime code and tests before removal. Kept namespace module exports, dynamic timer/deferred-work keys, native widget properties, scoring breakdown keys and saved-setting migrations.
- Reviewed Suite-owned `OnUpdate` assignments: they belong to active dragging, resizing or scrollbar gestures, with stop paths. The drawer also inspects existing buttons' handlers; that is not an added polling loop.
- Inspected TOC/XML/binding inputs, shipped media and notices. All 67 Lua files load through the TOCs; the three textures are referenced, including the extensionless square-mask path. All 58 test files are reachable through direct or nested test registration.

## Changes

| Area | Cleanup |
| --- | --- |
| Buff borders | Replace an allocated four-string direction list and unused direction variable with a numeric four-edge loop. |
| Drawer and bank | Remove unused callback parameters and unnecessary bank-event payload forwarding. |
| GUI and gear editor | Remove the unused detail-width field and retained Choose button reference; the button and its callback remain. |
| Inventory search | Remove the unused retained close-button reference; the parent owns the button. |
| Scoring | Remove unused automatic/starter flags from the resolved profile; class selection, weights and caching remain. |
| Training | Remove unused docking state and an unconsumed frame ownership marker; companion-frame checks continue to control docking and dragging. |
| Native window tools | Remove an unused retained reset callback; existing hooks retain the function. |
| Chat | Remove the copied/failed result field and its reset. Native callback validation and printed feedback remain. |
| Buff reminders | Remove display/chat/combat list fields retained only for tests. Active buttons retain their entries, and local lists still drive routing, notification and layout. |
| Tests | Read combat button entries, routing results and actual feedback instead of removed bookkeeping fields. |

## Validation

The baseline `node scripts/check-addon.cjs` passed 23,410 assertions. After cleanup, it passes 23,407 assertions, Lua 5.1 syntax for all 67 files, and matching TOC/version/load-order checks. Three redundant internal-state assertions were removed; the existing observable behavior assertions remain. No new feature tests were needed.

The local static audit reports no remaining unused local-binding candidates or statements after unconditional returns/breaks. The package inventory contains 76 expected files: 67 Lua, two TOCs, two XML files, three textures and two notices/licenses. Development caches, test programs and research are outside the shipped directory. No package was rebuilt or deployed as part of this cleanup.

Native rendering, input, persistence, protected actions and taint safety require the smoke checks in `testing.md`; no new in-game verification is claimed. This review does not establish that every possible runtime path is free of defects.
