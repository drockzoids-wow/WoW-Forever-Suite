# Forever Suite 1.0.12

November 11, 2026.

User authorizes the next version and CurseForge publication. Release includes the pending reputation tracking/zone mapping, None / 10% / 5% progress lines, shared health/mana tonic parser and combat-only Warrior shout reminders, together with their tests and documentation. Core and both TOCs advance to 1.0.12. Existing disabled options remain disabled; legacy enabled progress lines retain 10% spacing. [Changelog](../CHANGELOG.md#1012--november-11-2026).

User confirms reputation switching and observed progress-bar appearance in game. Running build/Interface, individual expanded-zone coverage, all bar types/modes, profile/reload persistence, tonic selection/execution and shout combat/taint checks remain separately pending. Recurring native bag-use taint remains an open investigation; this release claims no originating-taint fix. Publication does not mark those checks verified. No game deployment, junction or real SavedVariables changes.

Use the existing main checks and a fresh v1.0.12 tag to run Package and Release for CurseForge project 1749120 with the Forever flavor. Only src/WoWForeverSuite ships; development references/tests/docs stay outside the archive. Validation and publication receipts follow below.

## Local validation

`node scripts/check-addon.cjs` passes: 86 Lua 5.1 files, identical 1.0.12 Core/TOCs and 35,347 substitute assertions. `git diff --check` passes. `scripts/Package.ps1` produces `dist/WoWForeverSuite-1.0.12.zip`, verified by enumerating entries and comparing every file's SHA256 with `src/WoWForeverSuite`: exactly 95 files, no extras, duplicates or omissions. ZIP SHA256: `D7A2EADAF1551517CC4E37862032E56C0C6802BFEF01267564C9B11CD9EB73CA`.

Remote main was confirmed at `101ce48e0297fc0df1cb9cebb4558e33347aff7a`; the v1.0.12 tag did not exist during preflight. Final CI/upload receipts remain pending.

## Publication verified

Release commit `1fe977f181ecdd88602cb650327db41d67b10bd4` passes [main checks 43060261742](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/43060261742). Fresh annotated tag v1.0.12 triggers [Package and Release 43060483233](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/43060483233); job `130661389504` completes all steps successfully, including CurseForge authentication, addon-only preview contents, publication and GitHub asset verification.

Job logs record upload of `WoWForeverSuite-v1.0.12-forever.zip` as a 1.60.1 release to CurseForge project 1749120 at `2026-11-11T16:40:16Z` and `Success!` at `16:40:17Z` (November 11, 2026, 10:40 a.m. America/Chicago). Upload acceptance is verified; moderation/public availability was not independently verified.

[GitHub release v1.0.12](https://github.com/drockzoids-wow/WoW-Forever-Suite/releases/tag/v1.0.12) is published with uploaded `release.json` and `WoWForeverSuite-v1.0.12-forever.zip`. GitHub reports published ZIP SHA256 `40a165a0e73263d0a6e5815c5f192c655e025bb2b8c88ba6c1194de39eee8da0`. Local and packager archives can differ in line endings/metadata. Native test qualifications above remain unchanged.
