# Forever Suite 1.0.15

November 13, 2026.

User authorizes preparing and publishing 1.0.15. Include expanded food/drink macro detection, bounded delayed-bank recovery and diagnostics, independent profession-guide sections and character skill snapshots, default-off account-money bag tooltips, and the Disenchant hover glow. Core and both matching TOCs advance to 1.0.15. Offline checks pass 92 Lua 5.1 files, 46,294 substitute assertions, all 11 separate gear-baseline tests and git diff --check. Native behavior remains limited to the recorded user confirmations; subsequent automatic food refresh, new UI/input and combat/taint smoke tests remain pending. The existing UseContainerItem taint investigation remains unresolved. Package verification and publication receipts are recorded in [release-1.0.15.md](release-1.0.15.md). No game deployment, junction or real SavedVariables edits.

[Changelog](../CHANGELOG.md#1015--november-13-2026), [native smoke tests](testing.md), [CurseForge description](curseforge-description.md).

Review covers the pending runtime changes and their regression cases: food restoration parsing and candidate exclusions, native macro ownership/editor and combat protections, all-or-nothing bank snapshots and bounded retry cancellation, purchased empty-bag validation, independent guide section cleanup, per-character profession skill validation, and scoped money snapshots/native hover hooks. No new concrete code blocker was identified. API substitutes do not establish native permission, layout, input or taint safety.

Remote main matches ce9e9b28d17771003fef7c4450b60694a6c0db98 and v1.0.15 is absent during preflight. Publish the release commit through main CI, then a fresh annotated v1.0.15 tag and the existing Package and Release workflow for CurseForge project 1749120, Forever flavor. Upload acceptance and public moderation availability are separate observations.

## Package verified

scripts/Package.ps1 produced dist/WoWForeverSuite-1.0.15.zip. All 101 non-directory entries match src/WoWForeverSuite by SHA256, with no extra, duplicate, missing or mismatched files. Development caches, tests, documentation and SavedVariables are excluded. ZIP SHA256: 667353AB608F6F8A61E8E4263C1717D42D701ADB1752B5D068E146388F0D9E83.

Publication receipts will be appended after execution.
