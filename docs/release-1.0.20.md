# Forever Suite 1.0.20

November 16, 2026.

The user explicitly authorizes checking the current source and publishing to CurseForge. This includes the pending account-money/dashboard logout preservation, incoming buff-provider proximity and EasyFishing minimap drawer changes; this supersedes earlier no-publication notes for those changes.

Core and both TOCs advance together to 1.0.20. Use the existing tag-triggered Package and Release workflow for CurseForge project 1749120, Forever flavor. Remote main baseline: 51b764fe66172cb2f1a72125582f2b8854856b9e; v1.0.20 did not exist at preflight.

## Validation

- Final versioned node scripts/check-addon.cjs passes: 94 Lua 5.1 runtime files, matching TOCs/Core, 47,801 behavior assertions and 1,240,360 profession audit invariants across 2,416 skill states.
- All 11 independent gear-baseline tests and git diff --check pass.
- scripts/Package.ps1 produces dist/WoWForeverSuite-1.0.20.zip. All 103 non-directory entries match source SHA256, with no extras, omissions or duplicates. ZIP SHA256: 96D16284E2008C9EFC16E777197AB1960BE03B42761A4EEBE657BE46CA3F40C7.
- Focused review of the pending runtime changes and regression coverage found no additional concrete blocker.

Native persistence, rendering, input, range/combat behavior and taint verification remain pending. Previously overwritten gold balances require a fresh in-world observation with recording enabled. Incoming provider checks use native group proximity rather than exact teammate spell range. The existing UseContainerItem investigation is not claimed fixed. No game deployment, junction or real SavedVariables changes.

## Publication

Release commit 7043a43181ae0877566257efb1b71c75404f2585 passes [main Addon checks 43858236533](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/43858236533). Annotated tag v1.0.20 targets that commit.

[Package and Release 43858533182](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/43858533182), job 133268968646, completes successfully: full addon checks, tag/version matching, CurseForge authentication, addon-only package comparison, publication and GitHub release-asset verification.

The job logs uploading WoWForeverSuite-v1.0.20-forever.zip as a 1.60.1 release to CurseForge project 1749120 at 2026-11-16T11:33:39.015Z, followed by Success! at 11:33:39.755Z (November 16, 2026, 5:33 a.m. America/Chicago). This verifies upload acceptance. CurseForge public moderation/availability was not independently verified.

[GitHub release v1.0.20](https://github.com/drockzoids-wow/WoW-Forever-Suite/releases/tag/v1.0.20) is published, neither draft nor prerelease, with WoWForeverSuite-v1.0.20-forever.zip and release.json in uploaded state. Published ZIP SHA256 from GitHub's asset digest: bc926ce94314d080a0027945dff4478e316cab86f8b9348bb4161d9c66426abd. Published and local hashes can differ because of source line endings and archive metadata. Native smoke tests and the existing bag-use taint investigation remain pending.
