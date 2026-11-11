# Forever Suite 1.0.11

November 10, 2026.

User authorized release and CurseForge publication of the Warrior stance macros and automatic food updates committed in 0fee002. Core and both TOCs advance to 1.0.11; no settings schema or defaults change. See [changelog](../CHANGELOG.md#1011--november-10-2026).

The user confirmed automatic Yellowtail selection after reload. Actual running build/Interface, Warrior execution, food consumption/restocking and combat/taint results remain pending. Publishing does not verify those native behaviors. No deployment, junction or real SavedVariables changes.

Release uses main checks, a fresh v1.0.11 tag and the existing Package and Release workflow targeting CurseForge project 1749120 with the Forever flavor. Final package checks and publication receipts will be recorded below.

Final local checks pass: 86 Lua 5.1 files, identical 1.0.11 Core/TOCs and 34,652 substitute assertions; git diff --check is clean. Package.ps1 produced dist/WoWForeverSuite-1.0.11.zip with 95 exact source-hash-matching files and no extras, omissions or duplicates. ZIP SHA256: 248DD8017DD28ABCDB265DEBB2E272D1087B95DE2CF5D8D4FDDBFF08CAF1CB93.


## Publication verified

Release commit 7423b3478cc2b2593d0e0de386953fd4e56ee833 passed [main checks 42955377815](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/42955377815). Fresh v1.0.11 triggered [Package and Release 42955499218](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/42955499218); job 130309497219 completed every step successfully, including addon-only package verification and published-asset checks.

The job logged upload to CurseForge project 1749120 at 2026-11-11T03:52:35Z and Success at 03:52:36Z (November 10, 2026, 9:52 p.m. America/Chicago). Upload acceptance is verified; moderation/public availability was not independently verified. [GitHub release v1.0.11](https://github.com/drockzoids-wow/WoW-Forever-Suite/releases/tag/v1.0.11) contains uploaded release.json and WoWForeverSuite-v1.0.11-forever.zip. GitHub reports published ZIP SHA256 b55ff9469ab92964151bf6fd0133d75853de84aa4393a6a241cb433020191cc4. Local and packager archives can differ in line endings/metadata. Native test limits remain as recorded above.
