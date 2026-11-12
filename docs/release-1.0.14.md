# Forever Suite 1.0.14

November 12, 2026.

The user authorizes a final full review and release, superseding the earlier holds. The complete current tree passes 90 Lua 5.1 files, matching Core/TOCs at 1.0.14, 41,967 substitute behavior assertions, all 11 gear-baseline tests and git diff --check. Repeated pinned-70862 AST/API/global-write scans and focused review of all pending runtime changes identify no new concrete release blocker. This includes the optional persistent talent-build comparison and its character-owned reference, linked castbar sizes with immediate Manual state after direct edits, settings simplification, Contacts/groups/multiline notes, profession learning-source hints, combat reminder identity handling and native tooltip difficulty colors. Native permissions, layout, input and combat/taint smoke tests remain pending; the existing bag-use taint investigation is not claimed fixed. No game deployment, junction or real SavedVariables edits.

[Changes](../CHANGELOG.md#1014--november-12-2026), [review](addon-review-2026-11-12.md), [native smoke tests](testing.md).

scripts/Package.ps1 produced dist/WoWForeverSuite-1.0.14.zip. All 99 non-directory entries match current addon source by SHA256, with no extra, duplicate, omitted or mismatched files. ZIP SHA256: 9E7F9BF92FEF7AB4DB16F648A50332273EDF184C1C139193B5AB62972DBB8CDB. Development caches, tests, documents, credentials and SavedVariables are excluded.

Publish through the existing main-check → fresh annotated v1.0.14 tag → Package and Release workflow, targeting CurseForge project 1749120 with Forever flavor. Remote main matches 3c224f062f15a3d21dac124f379d87ceffe2aad7 and v1.0.14 is absent during preflight. CI/upload receipts will be appended after execution. Upload acceptance and public moderation availability are separate observations.

## Publication verified

Release commit 718884ee166208d1c76c69b24c9332a68e681e95 passes [Addon checks 43275230333](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/43275230333). Annotated v1.0.14 triggers [Package and Release 43275543425](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/43275543425); job 131382822685 completes every step successfully, including repeated 41,967-assertion checks, tag/version match, CurseForge authentication, addon-only archive comparison, upload and GitHub asset verification.

Job logs record uploading WoWForeverSuite-v1.0.14-forever.zip as a 1.60.1 release to CurseForge project 1749120 at 2026-11-12T18:02:53Z, followed by Success at the same minute (November 12, 2026, 12:02 p.m. America/Chicago). Upload acceptance is verified; CurseForge moderation/public availability was not independently verified.

[GitHub release v1.0.14](https://github.com/drockzoids-wow/WoW-Forever-Suite/releases/tag/v1.0.14) is published with uploaded release.json and WoWForeverSuite-v1.0.14-forever.zip. GitHub reports published ZIP SHA256 c089c5afe4943bf7f5447207cac8dbd2922c1ff4abb5c12db6fb8960bc21d24c. Local and packager archive hashes may differ because of line endings and archive metadata. Native limitations remain as recorded in the review and testing guide.
