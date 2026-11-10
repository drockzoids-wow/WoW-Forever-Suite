# GitHub and CurseForge publishing

## Verified 1.0.10 upload — November 10, 2026

The authorized final code review established no new concrete release blocker. Release commit 7cf8562be47adaddbef131ab0cb8d81e51b3a8e0 passed [main checks 42857916836](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/42857916836); fresh v1.0.10 completed [Package and Release 42858141099](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/42858141099). Job 129976677204 logged upload to CurseForge project 1749120 at 2026-11-10T16:48:21Z, followed by Success at 16:48:23Z. Upload acceptance is verified; moderation/public availability is separate and was not independently verified.

[GitHub release v1.0.10](https://github.com/drockzoids-wow/WoW-Forever-Suite/releases/tag/v1.0.10) has its uploaded addon ZIP and release.json. Published ZIP SHA256: ce462524e3097d68345b4f0f29901e089127ee4bc91adbc72118265ebd7b88d3. Final local checks pass 86 Lua 5.1 files, 34,529 assertions and 95 source-hash-matching archive entries. [Review](addon-review-2026-11-10.md) and [release evidence](release-1.0.10.md) preserve remaining native calibration/input/layout/taint limits. No game deployment, junction or real SavedVariables changes.

## Verified 1.0.8 upload — November 8, 2026

User authorized the release in this chat. Tag `v1.0.8` targets `77572c67ed6427a1b9ef5b1db5d8c41f43a7ce29`. [Main checks 42532859302](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/42532859302) and [Package and Release 42532959285](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/42532959285) completed successfully. Release job `128891023714` logs the upload of `WoWForeverSuite-v1.0.8-forever.zip` to CurseForge project **1749120** at `2026-11-08T23:00:41Z`, followed by `Success!`. This establishes upload acceptance; CurseForge moderation/public availability has not been independently verified.

[GitHub release v1.0.8](https://github.com/drockzoids-wow/WoW-Forever-Suite/releases/tag/v1.0.8) is published with uploaded `release.json` and `WoWForeverSuite-v1.0.8-forever.zip`. Published ZIP SHA256: `9330d48d22c8d9715bbc928d6e3d3aee95c4650a3d7f9e26c9d85b27ce62742f`. Local candidate was separately checked: 82 Lua 5.1 files, matching TOCs, 32,266 assertions and 91 source-hash-matching package entries. Local ZIP SHA256: `19E71B5801EB11E977DBC675ED619B771156943FE7FB4D9C619CF438FD28F200`; packager archives can differ in line endings/metadata. Receipts/logs are under `.cache/release-108`.

Player-created contacts remain account-wide saved records; twelve-contact persistence/metadata tests pass through repeated reload initialization, disabled mail options and scope filtering. Original readable legacy/unfamiliar books are retained during migration/recovery. WoW writes SavedVariables on successful reload/orderly logout; a crash may lose changes since its last flush. User's crash cause and native color/wheel/taint retests remain unverified. No game deployment/junction or real SavedVariables modifications; separate scoring research remains uncommitted.

## Project settings

- GitHub: `drockzoids-wow/WoW-Forever-Suite`, public.
- GitHub Desktop checkout: `C:\Games\Development\GitHub Repos\WoW Forever Suite`.
- CurseForge project ID: **1749120**.
- CurseForge game flavor: **Forever**, explicitly selected with `-g forever`.
- Install folder: **WoWForeverSuite**. Only files in `src/WoWForeverSuite` ship.

The user manages the junction inside the game's AddOns directory. Its addon folder must be named exactly **WoWForeverSuite**, with no spaces, and the current source is `C:\Games\Development\GitHub Repos\WoW Forever Suite\src\WoWForeverSuite`, where the matching TOC files live. The repository folder may contain spaces. The October 17 junction observation was historical and does not establish the current target; do not change it without a later request.

This follows ZoidsTools Retail's version-tag release process. An ordinary commit/push backs up the code and runs addon checks. Pushing a version tag starts checks, packaging and upload to CurseForge, and attaches the package to a GitHub release. CurseForge moderation is a separate step. The decision to push the tag is the release approval; there is no additional GitHub reviewer gate.

## First-time setup

1. In GitHub Desktop, use **File > Add local repository** and choose `C:\Games\Development\GitHub Repos\WoW Forever Suite`. The existing public repository is `drockzoids-wow/WoW-Forever-Suite`; commit prepared files to `main` and push to its existing origin. Do not initialize a second copy or publish a second repository.
2. In the new GitHub repository, open **Settings > Secrets and variables > Actions > New repository secret**. Name it exactly **CF_API_KEY**. Paste a CurseForge **author upload API token** from the [API Tokens page](https://authors.curseforge.com/account/api-tokens), then save. This is a CurseForge token, not a GitHub personal access token or a third-party CurseForge data API key. A valid existing author token used for ZoidsTools can also be stored for this repository if its account can upload to Forever Suite. Secrets do not automatically carry over between repositories.
3. GitHub supplies `GITHUB_TOKEN` automatically; do not create that secret. The workflow maps `CF_API_KEY` to the packager's `CF_API_TOKEN` environment variable and the automatic GitHub token to `GITHUB_OAUTH`. The packager does not read `GH_API_TOKEN`; using that name silently skips GitHub release publishing. A final step verifies that the published GitHub release contains the addon ZIP and `release.json`. Never commit or paste the actual key in source, chat or screenshots.
4. Open **Actions > Package and Release > Run workflow**, choose `main` and run it. This manual run checks the addon, requests CurseForge's game-version list with the key, builds the real packager ZIP and compares its file list with the shipped source. It does not upload a release. A successful API read does not by itself prove upload permission for project 1749120.
5. Complete the CurseForge project and ensure its author account owns or can upload to project 1749120. The first tagged release confirms the actual upload destination and permission. Inspect the resulting file on CurseForge; approval and public availability can follow later.

## Release from GitHub Desktop

1. Finish local checks and the relevant in-game smoke tests. Update `CHANGELOG.md`, `Suite.version` in `Core.lua`, and `## Version` in **both** TOCs to the same version.
2. Commit and **Push origin** to back up changes. Wait for **Addon checks** to pass.
3. In **History**, right-click the intended release commit and choose **Create tag**. Use `vX.Y.Z` matching the addon version. The current 1.0.0 tag already exists remotely; use a new matching version for subsequent releases.
4. Push the tag using **Push origin**. This triggers **Package and Release** automatically. A normal branch push alone does not upload to CurseForge.
5. Check the workflow's final result and CurseForge's file status. A successful upload is not the same as moderation approval. Release tags are unique; do not move an already published tag to different code.

The workflow fails before upload for missing credentials, failed addon checks, mismatched tag/version or unexpected archive contents. Manual **Run workflow** remains a setup check, even if a tag is selected.

## Working directory

User decision, October 25, 2026: `C:\Games\Development\GitHub Repos\WoW Forever Suite` is the canonical working copy, superseding the October 16 P: requirement. All future Forever Suite updates belong here, including code, documentation, artwork and release configuration. The user manages the game junction.

## October 29 publishing diagnosis

Remote `v1.0.0` points to `5a96baa0d335677ef29b328d6ce6de2f0f5e7ce5`. [Run 40972219585](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/40972219585) completed successfully and logged a successful upload of `WoWForeverSuite-v1.0.0-forever.zip` to CurseForge project 1749120. Its packager summary showed no GitHub token, and no public GitHub release was returned by the releases API. The configured `GH_API_TOKEN` name is unsupported by the packager; `GITHUB_OAUTH` and `GITHUB_API_TOKEN` are supported. Correct that mapping and verify release assets after publishing. Re-running the old tagged workflow still uses its old configuration; a branch push alone does not publish. CurseForge upload acceptance does not establish moderation approval or public availability.

## References

- [ZoidsTools release workflow](https://github.com/drockzoids-wow/ZoidsTools/blob/main/.github/workflows/release.yml)
- [GitHub Actions secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets)
- [GitHub Desktop tags](https://docs.github.com/en/desktop/managing-commits/managing-tags-in-github-desktop)
- [BigWigsMods packager](https://github.com/BigWigsMods/packager)
- [CurseForge Upload API](https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-upload-api)
