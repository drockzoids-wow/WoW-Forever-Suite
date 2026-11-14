# Forever Suite 1.0.17

November 14, 2026.

The user requests an addon-wide review and authorizes CurseForge publication, superseding the earlier no-release notes for the included changes. Review covers all 92 runtime Lua files through Lua 5.1 parsing, pinned build-70862 API/event/signature/global-write/duplicate-key scans, package/media/load-order inventory and the complete behavior suite, with focused manual inspection of every pending runtime diff and action/lifecycle boundaries. The 78 Lua test files are reachable from the entry point; 101 addon package inputs are accounted for. No detected duplicate literal keys, unknown directly registered literal events, too-short documented calls, unused local/function candidates or unreachable statements remain. Two existing capability-guarded MerchantKnown pet-journal fallbacks remain undocumented in the pinned source.

Fix two review findings: SetUserWaypoint returns a success boolean, so a non-throwing false or unreadable result must not attach the previous native pin link; retained legacy mount execution must reuse one status key rather than accumulating an entry per press. Regression covers both. Include clickable coordinates and recent Tell recipients, the independent native mount keybinding and retired builder recipe, profession-only tracking discovery and compact silver talent badges. Core and both identical TOCs advance to 1.0.17.

Offline validation passes 92 Lua 5.1 files, matching Core/TOCs, 46,489 substitute behavior assertions, all 11 separate gear-baseline tests and git diff --check. These checks do not establish native compatibility, chat delivery, mount permission, rendering or taint safety. Actual running build/Interface and native smoke results remain pending; the existing UseContainerItem taint investigation remains unresolved. No game deployment, junction or real SavedVariables changes.

Publication receipts are recorded below.

Review baseline: dfd981fe93429313c0f3111b9a698e59349a32f5, confirmed remote main before preparation; v1.0.17 is absent. Publish through main CI, then a fresh annotated v1.0.17 tag and the existing Package and Release workflow for CurseForge project 1749120, Forever flavor. Upload acceptance and public moderation availability are separate observations.

Native follow-up: restart for the new binding XML, record actual running build/Interface and /wfs status, and follow the coordinate/Tell, mount, profession tracking and talent-badge checklists in testing.md. Check opt-out restoration, failed pin placement, stale menu callbacks, combat entry and native input. No native result is inferred from this review.

## Package verified

scripts/Package.ps1 produced dist/WoWForeverSuite-1.0.17.zip. All 101 non-directory entries match src/WoWForeverSuite by SHA256, with no extra, duplicate, missing or mismatched files. Development caches, tests, documentation and SavedVariables are excluded. ZIP SHA256: 6FCD955C78FDC7782E4F2E6B97AF953221951BF8FCB431E5EC72EA82366C7085.

## Publication verified

The user explicitly authorizes pushing 1.0.17 to GitHub main, then tagging and publishing to CurseForge once CI passes, following the initial automatic approval review requirement for default-branch authorization.

Release commit a7d025c061847957434692cae4bcd9da4412e434 passes [Addon checks 43644638732](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/43644638732). After that success, annotated tag v1.0.17 triggers [Package and Release 43644771541](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/43644771541). Job 132599971481 completes every step successfully: 46,489 substitute assertions, version/tag matching, CurseForge authentication, addon-only archive comparison, publication and GitHub asset verification.

Job logs record uploading WoWForeverSuite-v1.0.17-forever.zip as a 1.60.1 release to CurseForge project 1749120 at 2026-11-14T21:49:47Z, followed by Success at 21:49:48Z (November 14, 2026, 3:49 p.m. America/Chicago). Upload acceptance is verified; CurseForge moderation/public availability was not independently checked.

[GitHub release v1.0.17](https://github.com/drockzoids-wow/WoW-Forever-Suite/releases/tag/v1.0.17) is published with release.json and WoWForeverSuite-v1.0.17-forever.zip in uploaded state. GitHub reports published ZIP SHA256 77b746077ed9e464245820815bc826600f29332401b9c5fdecee5c99d4fc6932. Local and packager archive hashes can differ because of line endings and archive metadata. Native smoke tests and the existing bag-use taint investigation remain pending as recorded above.
