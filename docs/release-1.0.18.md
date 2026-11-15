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

Baseline is 53df88d27ce9853e96687f8f241a6822951241a7, confirmed as remote main. Publish the prepared commit to main, wait for Addon checks, then create a fresh annotated v1.0.18 tag to invoke the existing Package and Release workflow for CurseForge project 1749120, Forever flavor. Upload acceptance and public moderation availability are separate observations. Receipts will be recorded after completion.
