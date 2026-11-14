# Forever Suite 1.0.17

November 14, 2026.

The user requests an addon-wide review and authorizes CurseForge publication, superseding the earlier no-release notes for the included changes. Review covers all 92 runtime Lua files through Lua 5.1 parsing, pinned build-70862 API/event/signature/global-write/duplicate-key scans, package/media/load-order inventory and the complete behavior suite, with focused manual inspection of every pending runtime diff and action/lifecycle boundaries. The 78 Lua test files are reachable from the entry point; 101 addon package inputs are accounted for. No detected duplicate literal keys, unknown directly registered literal events, too-short documented calls, unused local/function candidates or unreachable statements remain. Two existing capability-guarded MerchantKnown pet-journal fallbacks remain undocumented in the pinned source.

Fix two review findings: SetUserWaypoint returns a success boolean, so a non-throwing false or unreadable result must not attach the previous native pin link; retained legacy mount execution must reuse one status key rather than accumulating an entry per press. Regression covers both. Include clickable coordinates and recent Tell recipients, the independent native mount keybinding and retired builder recipe, profession-only tracking discovery and compact silver talent badges. Core and both identical TOCs advance to 1.0.17.

Offline validation passes 92 Lua 5.1 files, matching Core/TOCs, 46,489 substitute behavior assertions, all 11 separate gear-baseline tests and git diff --check. These checks do not establish native compatibility, chat delivery, mount permission, rendering or taint safety. Actual running build/Interface and native smoke results remain pending; the existing UseContainerItem taint investigation remains unresolved. No game deployment, junction or real SavedVariables changes.

Release evidence is recorded in [release-1.0.17.md](release-1.0.17.md).

Review baseline: dfd981fe93429313c0f3111b9a698e59349a32f5, confirmed remote main before preparation; v1.0.17 is absent. Publish through main CI, then a fresh annotated v1.0.17 tag and the existing Package and Release workflow for CurseForge project 1749120, Forever flavor. Upload acceptance and public moderation availability are separate observations.

Native follow-up: restart for the new binding XML, record actual running build/Interface and /wfs status, and follow the coordinate/Tell, mount, profession tracking and talent-badge checklists in testing.md. Check opt-out restoration, failed pin placement, stale menu callbacks, combat entry and native input. No native result is inferred from this review.

## Package verified

scripts/Package.ps1 produced dist/WoWForeverSuite-1.0.17.zip. All 101 non-directory entries match src/WoWForeverSuite by SHA256, with no extra, duplicate, missing or mismatched files. Development caches, tests, documentation and SavedVariables are excluded. ZIP SHA256: 6FCD955C78FDC7782E4F2E6B97AF953221951BF8FCB431E5EC72EA82366C7085.
