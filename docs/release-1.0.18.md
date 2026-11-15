# Forever Suite 1.0.18

November 14, 2026.

The user explicitly requests fixing all three deep-review findings, rerunning checks and publishing the latest updates to CurseForge if they pass. This supersedes earlier no-publication notes for the included features.

This release restores quest-item activation after dragging, updates the retained item's combat cooldown presentation and prunes obsolete auto-open GUID history after complete readable scans. It also includes the pending persistent/combat-usable nearby quest item, independent default-off peer version notifications and native target/focus level-number outlines. [Review and resolution](review-20261114-edge-cases.md).

## Validation

- node scripts/check-addon.cjs passes: 93 Lua 5.1 files, identical TOCs/Core 1.0.18, 46,599 substitute behavior assertions.
- All 11 separate gear-baseline tests and git diff --check pass.
- Static API/event/duplicate-key/global-write/argument scan against pinned build 70862 identifies no new concrete issue. The scanner's file-wide alias heuristic mislabels candidate item fields after the local C_Item alias; those are manually confirmed as ordinary candidate-record fields. The two pre-existing guarded MerchantKnown pet-journal fallbacks remain undocumented in that reference.
- scripts/Package.ps1 produces dist/WoWForeverSuite-1.0.18.zip. All 102 non-directory entries match source SHA256; no extra, missing or duplicate entries. ZIP SHA256: 74C68844260282599203B47A0B988EEBA206B736762566C19BABB9A405574090.

Native compatibility, combat activation, cooldown permissions, messaging delivery/range, outlines and taint checks remain pending. The existing UseContainerItem investigation is not claimed fixed. No game deployment, junction or real SavedVariables changes.

## Publication

Baseline was 53df88d27ce9853e96687f8f241a6822951241a7, confirmed as remote main. The prepared commit was pushed to main; after Addon checks passed, a fresh annotated v1.0.18 tag invoked the existing Package and Release workflow for CurseForge project 1749120, Forever flavor. Upload acceptance and public moderation availability are separate observations.

## Publication verified

Release commit 9b56f163df78a4e3ac4249b6a0f48321f0a719d3 passes [main Addon checks 43663792178](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/43663792178). A fresh annotated v1.0.18 tag targets that commit. [Package and Release 43663882160](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/43663882160), job 132658898555, completes every step successfully: 46,599 assertions, tag/version check, CurseForge authentication, addon-only package comparison, upload and GitHub asset verification.

The job records uploading WoWForeverSuite-v1.0.18-forever.zip as a 1.60.1 release to CurseForge project 1749120 at 2026-11-15T01:37:28Z, followed by Success at 01:37:29Z (November 14, 2026, 7:37 p.m. America/Chicago). This verifies upload acceptance; CurseForge moderation/public availability was not independently verified.

[GitHub release v1.0.18](https://github.com/drockzoids-wow/WoW-Forever-Suite/releases/tag/v1.0.18) is published with its addon ZIP and release.json in uploaded state. Published ZIP SHA256: 9d7e30ffb444386694f5d669bdda65912530727973f52c8b968ce232ef426253. Differences from the local ZIP hash can result from line endings/archive metadata. Native checks and the existing bag-use taint investigation remain pending as described above.
