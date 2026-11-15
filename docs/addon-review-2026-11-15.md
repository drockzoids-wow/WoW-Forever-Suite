# Whole-addon and GUI consistency review — November 15, 2026

## Scope and limits

Reviewed the canonical C: checkout, including pending profession-guide changes and the concurrent section/overall material-shortage clarification. No version bump, commit, publication, game deployment, junction change or real SavedVariables edit. Existing work is preserved.

Automated coverage spans all 94 runtime Lua files, 103 package inputs and 80 registered Lua test files. Manual inspection concentrates on shared UI construction, selection callbacks, owner lifecycle, pending diffs, defaults/profile wiring and the action/combat/data boundaries represented by the behavior suite. This is an offline review: no running-client build, screenshots of these revisions, native rendering, input or taint result was obtained. Passing substitutes cannot establish that the addon has no bugs.

## Findings and fixes

| Finding | Resolution |
| --- | --- |
| Ordinary action buttons independently chose font sizes, alignment, padding, surfaces, border opacity, hover behavior and disabled text. Some Suite controls still used red native buttons. | Add `Theme:ActionButton`: slate surface, theme-aware thin border, centered 12px ivory text, bounded horizontal space, native hover/press textures and shared disabled dimming. Migrate settings actions and the module helpers for profiles, buffs, gear, inventory, characters, contacts, macros, talents, training, supplies, mail deadlines, support and chat-copy controls. Replace Suite-owned native red buttons in bank deposit, character selectors, coordinate Tell and the native settings launcher. Preserve caller dimensions and action/combat guards. |
| Buff and macro checkboxes retained the native gold checkbox treatment. | Add `Theme:CheckButton` with slate surface, shared theme border, checked marker and disabled feedback; retain native CheckButton state and input semantics. |
| Ordinary selectors used native context-menu surfaces while profession and meter lists had owned slate surfaces. | Add bundled `Menus.lua` before its consumers in both identical TOCs. Ordinary selectors share an opaque slate list, 12px ivory labels, theme-colored selection marker, bounded 12-row scrolling, click-away/Escape dismissal and owner hide/disable/combat cleanup. Popup widgets stay outside scroll clipping and explicitly above their dismissal surface. No native menu pools are styled or replaced. Profession lists use the same action helper, menu palette and themed marker; damage-meter submenus retain their independent owned implementation. |
| An item-picker callback retained an old macro entry after selection changed. | Recheck the current selected entry before applying an item choice. Regression invokes a captured callback after changing selection and confirms the earlier macro is untouched. |
| Native-menu capability fallback branches became obsolete once Suite menus were bundled. | Remove the macro item-cycling and contact group-cycling fallbacks. Regression now selects explicit choices through the Suite-menu interface. |

Keep purpose-specific presentations: sidebar navigation, settings toggle rows, section headers, list rows, recipe/material links, secure item/spell buttons, dismiss icons and meter selectors serve different roles. Their interaction/selection semantics are preserved. The generic action helper does not impose a combat policy: callers retain existing guards or deliberate model-only changes with deferred layout. Native window tools and secure gameplay frames are not restyled by this work.

## Dormant code, APIs and packaging

- Scope-aware local/function and method-reference scans find no unreferenced candidates or unreachable statements. Write-only field candidates were checked against string-key access, registries, callbacks and public namespace registration. This is not a proof of complete runtime reachability.
- Retain old `/wfs randommount` execution, SavedVariables migrations and guarded compatibility paths: they still support retained macros and existing data, and are not abandoned features.
- All runtime Lua files appear in the TOCs; test entry points reach all 80 spec files. Media/package inventory accounts for 103 source inputs; no cache or third-party reference source is an addon input.
- Static scan against the pinned build-70862 documentation indexes 5,144 functions: no duplicate literal table keys, unknown directly registered literal events or detected calls missing required documented arguments. The scanner's `C_Item.bag/count/guid/id/slot` reports are scope-insensitive alias false positives from AutoOpen's local item record. The two pre-existing capability-guarded MerchantKnown pet-journal fallbacks remain undocumented in that reference.
- Detected global assignments remain declared saved roots, slash/binding registration and the documented minimap-shape compatibility hook. No new global writes, idle OnUpdate work or polling were added.

## Validation and remaining work

`node scripts/check-addon.cjs`: 94 files parse as Lua 5.1; Core and both TOC versions match; 47,530 substitute behavior assertions pass. `node --test tests/gear_baseline.test.cjs`: all 11 independent gear-model tests pass. `git diff --check` passes. Development-only audit receipts are `.cache/review-20261115-api.txt` and `.cache/review-20261115-cleanup.txt`.

Menu regression covers disabled and selected rows, long-list scrolling/reuse, restricted/non-finite wheel input, callback cleanup, selection, click-away, Escape propagation, owner hide/disable and combat entry/reopen prevention. Shared action regression covers disabled activation, text restoration and native feedback textures. Existing functional specs now intercept Suite-menu descriptions without depending on Blizzard menu availability.

Follow the November 15 whole-GUI smoke test in `testing.md` before calling appearance or interaction verified. Prior in-game confirmations are historical evidence only for those versions. The existing native `UseContainerItem` taint investigation is still unresolved; this review does not claim to fix it.
