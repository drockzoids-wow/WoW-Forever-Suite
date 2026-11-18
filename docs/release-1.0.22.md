# Forever Suite 1.0.22

November 18, 2026.

This release adds title dragging to independent Suite windows, makes Mail Deadlines more compact, and supplies editable subject defaults for alt and guild mail. See the [changelog](../CHANGELOG.md).

The user approved the Mail Deadlines layout in-game and confirmed that the window moves. Most other window drag checks and the final subject-switching regression have automated coverage. The exact client build, Interface and full in-game follow-up remain unreported. See the [testing notes](testing.md).

The release snapshot passed Lua 5.1 parsing for 95 files, 51,792 behavior assertions, matching TOCs, the release guard and 1,240,360 profession material invariants. The 104-file local archive matches the test-free source snapshot byte for byte. Its SHA-256 is `a10656fbd398fdd7faa0cc8da2b3ee004ca689305059a26864f12811c0064e48`.

## Publication

The `v1.0.22` tag points to `8952c0914d7a9861296a4b868d023a031b6285f9`. Only the tag was pushed. The [release workflow](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/44357356796) completed successfully, including the CurseForge upload and GitHub asset verification. The [GitHub release](https://github.com/drockzoids-wow/WoW-Forever-Suite/releases/tag/v1.0.22) contains the ZIP and release metadata. The published ZIP SHA-256 is `0fda8bf33769c7176af7810c875c794ce97cb27e1e4a00b596d9cea65b47d840`.

The development checkout retains the level-2 test logger and references in both TOCs. The public project description update awaits author dashboard sign-in.
