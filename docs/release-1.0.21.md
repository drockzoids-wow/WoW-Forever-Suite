# Forever Suite 1.0.21

November 17, 2026.

The release packages the current addon changes for CurseForge project 1749120, Forever flavor. See the [changelog](../CHANGELOG.md) for the player-facing changes.

## In-game evidence

The user confirmed the personal-bank carried reserve and Automatic Purchase in-game. They later reported completing the remaining tests. The saved follow-up taint log covered 8:34:53–8:37:48 p.m. Central and contained no blocked or forbidden actions. An earlier capture was truncated by the client after logout. The running build and Interface were unreported. The earlier intermittent native `UseContainerItem` and `PurchaseBankTab` reports remain open. See [testing notes](testing.md).

The release sources exclude the temporary level-2 taint logger. The release guard remains in the local packaging script and GitHub Actions workflow.

## Package verification

The versioned release build passed Lua 5.1 parsing for 95 files, 51,637 behavior assertions, matching TOCs, the release guard, and 1,240,360 profession material invariants across 2,416 skill states. All 11 standalone gear research checks and the staged whitespace check passed.

The local package contains 104 files under `WoWForeverSuite/`. Each ZIP entry matches its release source by SHA256. The ZIP SHA256 is `45D27378DC91EEB6F4AF9851FE4A911A0E44CAAE55932C6A7CF11BFFBC38E366`.
