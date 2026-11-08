# Release readiness — November 8, 2026

The current working tree is ready for focused in-game testing, but is **not yet an unqualified release candidate**. Both selector defects identified below were subsequently corrected at the user's request. All 32,010 addon assertions and 11 research tests pass; several recent fixes still need their native retests, and the source version is still the already-tagged 1.0.6.

Reviewed the canonical checkout on top of `2043af7`, including the existing uncommitted addon changes and untracked InventorySelectors.lua. No runtime code, version, existing distribution archive, deployment, junction, SavedVariables, commit, tag or publication was changed by this review.

Follow-up correction: UpdateLabels now preserves gamepad exclusion, and OfflineBank:Apply retains independently enabled saved bags and their pending refresh while stopping bank-specific work. Each defect failed a new regression before correction. See the newest entries in testing.md and forever-development.md. The findings below describe the original review; both code defects are now corrected offline. The initial 31,990-assertion result and package hash below describe the earlier tree; its ZIP predates these fixes and must not be used for release.

## Findings

1. **P2: A label refresh can reveal bag selectors in gamepad mode.** InventorySelectors.lua:119–127 shows every enabled control without considering gamepad layout. LayoutSearch correctly hides a bag control in gamepad mode at lines 170–173, but UpdateLabels subsequently shows it again. OfflineBank:Refresh calls UpdateLabels, so opening/searching a saved view can expose the native-bag selector/reset over space reserved for gamepad prompts. A standalone substitute probe reproduces the hide → label refresh → shown sequence. Keep gamepad exclusion in the shared visibility policy, and cover label refreshes after gamepad layout, not only LayoutSearch in isolation. Native overlap/appearance remains to be checked.

2. **P2: Bank snapshots being off makes unrelated settings close saved bags.** OfflineBank.lua:616–622 unconditionally hides the shared saved-view frame when offlineBank is off, including when viewBags is true and inventory recording remains enabled. Core.lua:123–130 applies every module after any Suite.Set. Consequently a settings change closes an independently enabled bag view in this valid configuration. A substitute probe reproduces OfflineBank:Apply hiding that active bag view. Preserve a valid bag-mode view while disabling bank-specific work; still close it when its own recording switches are disabled. Test both bank-on and bank-off configurations through Suite.Set, including combat deferral.

3. **Release preparation remains incomplete.** Core and both TOCs agree on 1.0.6, and local tag v1.0.6 already exists. Current changes are under Unreleased. Select a fresh unused version at publication time, update the release notes/version together, include the currently untracked runtime file in the release commit, then rerun checks and package verification on that final tree. The review archive deliberately retains the source's current version and must not be published as another 1.0.6.

The first two findings concern the new bag/bank feature. They do not demonstrate failure of the independent proc, chat, conversation or food fixes. A narrower fixes-only release would need an explicitly prepared and tested tree that excludes the unfinished selector integration; the current checkout contains both.

## Recent-fix assessment

| Change | Available evidence | Remaining release check |
| --- | --- | --- |
| Low-resource proc visibility/tint | Substitute coverage passes; user confirmed the requested behavior in game | Actual running build/Interface and wider recovery/expiry/other-class/taint checks remain unreported |
| Food macro recheck when bags open | Regression coverage passes, including the supplied bread and background-updates-off behavior | New native bag-open refresh/use test; the subsequent stale-food report supersedes the earlier broad fix confirmation |
| Chat typing stability and white-panel reload correction | Substitute regressions pass | Reload on a gryphon, landing/caret behavior, focus changes and disable restoration |
| Shift bypass in conversations | Substitute regressions pass for physical Shift and latched presses | Both Shift keys at an innkeeper/vendor/quest, including between continuing pages; native sole-option advancement remains outside Suite's controller |
| Bag/bank character selectors and reset | Current suite passes, but the two interaction probes above reproduce defects | Correct those interactions, then test layouts, scope, search/sort/menus, saved-slot behavior, toggles and combat |
| All-class scoring baseline | Separate 11-test reference suite passes | Research only; runtime scoring is unchanged and this is not a shipped scoring improvement |

Previously reported short-keybind action-bar blocking still lacks its focused native resolution report. Existing world-map/tracker taint reports remain open and deferred by the user's earlier decision; this review neither reopens those investigations nor labels them fixed.

## Whole-addon checks

- `node scripts/check-addon.cjs`: **82 Lua 5.1 files, 31,990 behavior assertions, identical TOCs and matching Core/TOC versions pass**.
- Scope/reference/package-input audit: **91 addon files and all 68 Lua spec files registered**. No unused local-binding, unreachable-statement or unreferenced named-method candidates were emitted. Write-only-field candidates retain the previously reviewed reasons: namespace exports, dynamically consumed pending keys, native widget fields, migrations and test handles; they are not automatic deletion findings.
- Repeated the API declaration audit against the pinned build-70862 source: 5,144 declarations; no statically identified missing required arguments, unknown literal registered events or duplicate table keys. Direct global assignments remain declared bindings/SavedVariables/slash entries and the documented minimap-shape hook. The same two capability-guarded legacy pet-journal APIs remain absent from generated documentation, as qualified in the [November 7 review](addon-review-2026-11-07.md).
- Reviewed every current runtime diff and the new InventorySelectors module, including affected Core, native bag layout and saved-view call paths. The previous review's unchanged-module assessment remains applicable; this is not a claim of a fresh manual proof of every line or native behavior.
- `node --test tests/gear_baseline.test.cjs`: **11/11 pass**, separately from the addon suite. These tools/data remain outside the addon package.
- Local release-workflow checker: all three embedded JavaScript blocks parse; token mapping and substitute release-response validation pass. Remote CI, authentication, upload and moderation were not exercised.
- `git diff --check`: clean.
- Rebuilt with Package.ps1's source/compression logic redirected to an isolated review output, preserving existing dist archives. **All 91 ZIP entries match source SHA256 hashes**, with no extra, missing or duplicate files. Cache, research, tests, tooling and source artwork are excluded. Both shipped license/notice files remain present.

Review ZIP: `.cache/release-review-20261108/package/WoWForeverSuite-1.0.6.zip`. SHA256: `A4C999813837ECC25E335CFD5231A46E54CF7C8D873E6263F0D7E4162B4F7446`. Receipt, API/scope outputs and reproducible interaction probes are under `.cache/release-review-20261108/`. This ZIP is review-only, not a release artifact.

Installed Wow.exe still reports **1.60.1.70862**. That observation matches the pinned reference source but does not establish the actual running client build/Interface. No in-game smoke test was performed. API substitutes do not establish native rendering, protected-action compatibility or taint safety.

## Completion criteria

Both selector interactions are corrected with passing regressions. Run the focused recent-fix checklists in [testing.md](testing.md), recording `/wfs status`, actual build/Interface, Lua/blocked-action results and the observed behavior. Prioritize food bag-opening refresh, gryphon/chat reload, Shift bypass, selector interactions and the unresolved keybind retest. Then prepare a fresh versioned release commit, rerun the normal suite and verify its rebuilt package before publishing.
