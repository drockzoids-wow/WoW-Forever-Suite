# Release review — 1.0.3

Reviewed November 5, 2026 in the canonical checkout, C:\Games\Development\GitHub Repos\WoW Forever Suite.

## Outcome

No new release-blocking functional defect identified in this review. The local candidate passes its automated checks and package inspection. This is a code-review result, not proof of every native-client interaction. No commit, tag, push, upload, addon installation, junction or SavedVariables change was performed.

The user confirms working replacement chat copying and colors, and accepts the resized Fishing castbar including its slight edge overhang. For the latest proc/dungeon changes, the user reports having tested casually and thinks they work, while explicitly noting they were not watching closely. Record that positive observation without treating it as a focused reproduction test. Actual running build/Interface remains unreported.

## Scope

- Static Lua 5.1 parsing and reference inspection across all 71 shipped Lua files, including local scopes, table keys, internal method references and global writes. No remaining unused locals, duplicate table keys or unresolved internal method references were found. Global writes are limited to declared SavedVariables, binding/slash declarations and the documented minimap-shape compatibility hook. Dynamic references/callbacks require manual interpretation; this is not a proof that every branch is reachable.
- Manual review of current changes/new modules and higher-risk paths: initialization/profile persistence, load order, optional-feature lifecycle, timer cancellation/coalescing, combat deferral/restoration, chat copy/history, castbar geometry, buff containers, proc availability, selected equipment-set edits, Training search, shared controls, vendor/quest/item-use guards, inventory and tooltip boundaries.
- Version/TOC consistency, local packaging, release workflow triggers, package filtering, source notices, and tracked/untracked release inputs. Compared the current tracked source against local v1.0.1 as well as HEAD; new modules/tests were inspected separately because git diff omits untracked files.

## Cleanup completed

Removed the now-resolved /wfs castbarstatus report, its slash route and diagnostic-only fixture. Removed an unused cached proc icon-size field; rendering continues to use the validated setting and stride. Kept the accepted castbar geometry unchanged.

Earlier cleanup remains in place: removed the superseded Battle Shout prototype, direct native chat-selection/copytest/probe paths, permanently empty buff captions, unused preview metadata/placement branch, duplicate inventory hover artwork and redundant close callback. Retained intentional default-off features, migrations, native restoration records, event callbacks and useful bounded support diagnostics.

## Validation

- node scripts/check-addon.cjs: 71 Lua 5.1 files; 26,561 behavior assertions; identical TOCs and matching Core/TOC version 1.0.3. The four-assertion decrease reflects removal of the retired diagnostic fixture.
- git diff --check: clean.
- scripts/Package.ps1: rebuilt dist/WoWForeverSuite-1.0.3.zip. All 80 archived files match source by SHA256, with no extras. Cache, tests, scripts, research and historical development notes are excluded.
- Archive SHA256: 0A7C98039ED174EBBC8BB12A14387A0D9D13B99E348D214D39C721B760B756F1.
- All test specs are reached by the runner, including class_macros_spec.lua through macros_spec.lua. Static reference checks distinguish dynamic timer keys/native callback fields and test widget handles from dead code.

## Before full release

A short focused in-game smoke pass remains appropriate: repeated Overpower opportunities against the native button, dungeon combat-buff behavior, equipment-set Toggle/Save persistence, chat Refresh/selection/scrolling, and disable/re-enable/reload/profile behavior. Capture /wfs status for the actual running build/Interface. Older detailed checklists in testing.md remain available; historical native-selection/copytest instructions there are superseded.

Core and both TOCs are ready at 1.0.3. Local v1.0.1/v1.0.2 tags already exist; v1.0.2 points to a tree declaring 1.0.1. A future release tag must match v1.0.3; no publication history is inferred from local tags. Include intended untracked modules ChatCopy.lua, EquipmentSets.lua, ProcAlerts.lua and their tests when committing: local checks/packages can include files that GitHub Actions cannot see until committed. Remote authentication/upload permissions have not been checked or exercised. The tag-push workflow publishes; workflow_dispatch builds without publishing.
