# Forever Suite 1.0.16

November 14, 2026.

The user requests an addon-wide review and authorizes CurseForge publication if the review passes. Reviewed all 92 runtime Lua files with syntax, static API/global/duplicate/dead-code scans and the full behavior suite. Removed three unused Mail helpers (ConfirmRemove, RemoveConfirmed and Categories) plus obsolete self.confirm state; current book.confirm and DeleteContact remain the sole Contacts confirmation/deletion path. Updated regression cases to exercise the active UI and shared deletion logic. No new concrete release blocker was identified. Core and matching TOCs advance to 1.0.16 with the pending tracking reminders and talent-badge colors. Native permissions, appearance, input and combat/taint smoke tests remain pending; the existing UseContainerItem taint investigation is not claimed fixed.

[Changes](../CHANGELOG.md#1016--november-14-2026), [native smoke tests](testing.md).

Final offline validation: node scripts/check-addon.cjs passes 92 Lua 5.1 files, identical TOCs/Core 1.0.16 and 46,381 substitute behavior assertions; all 11 separate gear-baseline tests and git diff --check pass. All 77 Lua test files are reachable from the test entry point. Static analysis against the pinned build-70862 documentation indexes 5,144 functions and finds no duplicate literal keys, unknown directly registered literal events or detected too-short documented calls. The two pre-existing, capability-guarded MerchantKnown pet-journal fallback APIs remain undocumented in that reference. Static and substitute checks do not prove native compatibility or taint safety.

Review includes TOC coverage/load order, package inputs and media references; optional defaults; existing OnUpdate gesture lifetimes and active-only display timers; protected-frame deferral; tooltip callbacks; macro ownership/editor protection; event coalescing/cancellation; bank snapshot completeness and bounded retries; Contacts confirmation/deletion and tombstones; tracking learned-state/native active-state checks and combat exclusions; and passive talent sequence coloring with manual learning preserved. Candidate unused fields were checked against dynamic-key consumers, native widget contracts and tests; they were not removed solely on a heuristic warning. The unused local/function scan has no remaining candidates. No dynamic-code execution or new global export is introduced.

The review uses the canonical checkout against d1e798c04d423d4221dd247e0f88273a40f3f9d9, confirmed remote main before preparation; v1.0.16 is absent. Publish through main CI, then a fresh annotated v1.0.16 tag and the existing Package and Release workflow for CurseForge project 1749120, Forever flavor. Upload acceptance and public moderation availability are separate observations.

Native follow-up: record actual running build/Interface and /wfs status. Check tracking detection, individual opt-out persistence, resurrection recovery, out-of-combat-only display and manual clicks. Check green/red talent markers in guided and passive views, earlier missing points, no available points, mismatches and native learning/Apply. Recheck Contacts two-click Remove, cancellation on navigation/hide, current-character protection, group cleanup and tombstones after reload. Follow the broader pending combat/taint tests in testing.md. No native result is inferred from this review.

## Package verified

scripts/Package.ps1 produced dist/WoWForeverSuite-1.0.16.zip. All 101 non-directory entries match src/WoWForeverSuite by SHA256, with no extra, duplicate, missing or mismatched files. Development caches, tests, documentation and SavedVariables are excluded. ZIP SHA256: 9461E7D9DC4148D95CEF16DF37808ACA02BC1790E16BC35510091F5DEC2660A2.

Publication receipts will be appended after execution.
