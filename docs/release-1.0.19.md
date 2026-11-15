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

Publication and upload acceptance are pending. CurseForge upload acceptance and public moderation availability are separate observations.
