# Forever Suite 1.0.19

November 15, 2026.

The user explicitly authorizes publishing the latest changes to CurseForge. This includes the pending shared GUI controls and menus, profession-guide behavior/material accounting, and outside-combat/combat buff range changes. This authorization supersedes earlier no-publication notes for the included changes.

Core and both TOCs advance together to 1.0.19. Use the existing tag-triggered Package and Release workflow for CurseForge project 1749120, Forever flavor. The remote main baseline is 3f2a47b361d88dadcb32fc292f706518a1a2db9a; v1.0.19 did not exist at preflight.

## Validation

- `node scripts/check-addon.cjs` passes: 94 Lua 5.1 runtime files, identical TOCs/Core 1.0.19, 47,711 behavior assertions and 1,240,360 profession math/render invariants across 2,416 skill states.
- `node --test tests/gear_baseline.test.cjs`: all 11 independent tests pass. `git diff --check` passes.
- `scripts/Package.ps1` produces `dist/WoWForeverSuite-1.0.19.zip`. All 103 non-directory entries match source SHA256, with no extra, missing or duplicate files. ZIP SHA256: `0C2BF76A877FCAF44EAEF6952AB7D85BD5897BC34691DB873B01DB446E39FE51`.

Native rendering, input, combat/range behavior and taint verification remain pending. The existing UseContainerItem investigation is not claimed fixed. No game deployment, junction or real SavedVariables changes.

## Publication

Release commit `ee99214bb51182fba44f67a5f4b4f3a8b156f37f` passes [main Addon checks 43757291069](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/43757291069). Annotated tag `v1.0.19` targets that commit.

[Package and Release 43757474301](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/43757474301), job `132944620625`, completes successfully: 47,711 behavior assertions, 1,240,360 profession audit invariants, tag/version matching, CurseForge authentication, addon-only package comparison, publication and GitHub release-asset verification.

The job logs uploading `WoWForeverSuite-v1.0.19-forever.zip` as a 1.60.1 release to CurseForge project 1749120 at `2026-11-15T20:22:31.641Z`, followed by `Success!` at `20:22:31.961Z` (November 15, 2026, 2:22 p.m. America/Chicago). This verifies upload acceptance. CurseForge public moderation/availability was not independently verified.

[GitHub release v1.0.19](https://github.com/drockzoids-wow/WoW-Forever-Suite/releases/tag/v1.0.19) is published, neither draft nor prerelease, with `WoWForeverSuite-v1.0.19-forever.zip` and `release.json` in uploaded state. Published ZIP SHA256 from GitHub's asset digest: `625b45f01e0adcb43bd6aac671fa026a430a6e7af0065f9b997d61e2ad6d5eb7`. The published archive's hash can differ from the local package because of source line endings and archive metadata. Native smoke tests and the existing bag-use taint investigation remain pending.
