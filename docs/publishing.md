# GitHub and CurseForge publishing

## Project settings

- GitHub: `drockzoids-wow/WoWForeverSuite`, public.
- GitHub Desktop checkout: `P:\GitHub Repos\WoW Forever Suite`.
- CurseForge project ID: **1749120**.
- CurseForge game flavor: **Forever**, explicitly selected with `-g forever`.
- Install folder: **WoWForeverSuite**. Only files in `src/WoWForeverSuite` ship.

The junction inside the game's AddOns directory must also be named exactly **WoWForeverSuite**, with no spaces, and point to `P:\GitHub Repos\WoW Forever Suite\src\WoWForeverSuite`, where the matching TOC files live. The repository folder may contain spaces. On October 17, a junction named `WoW Forever Suite` was corrected to `WoWForeverSuite`; both TOCs were readable through the link and matched source version 0.2.58. In-game discovery still requires confirmation after fully exiting and restarting WoW.

This follows ZoidsTools Retail's version-tag release process. An ordinary commit/push backs up the code and runs addon checks. Pushing a version tag starts checks, packaging and upload to CurseForge, and attaches the package to a GitHub release. CurseForge moderation is a separate step. The decision to push the tag is the release approval; there is no additional GitHub reviewer gate.

## First-time setup

1. In GitHub Desktop, use **File > Add local repository** and choose `P:\GitHub Repos\WoW Forever Suite`. Commit the prepared files to `main`, then **Publish repository** as public `WoWForeverSuite` under `drockzoids-wow`. Do not initialize a second copy in another directory.
2. In the new GitHub repository, open **Settings > Secrets and variables > Actions > New repository secret**. Name it exactly **CF_API_KEY**. Paste a CurseForge **author upload API token** from the [API Tokens page](https://authors.curseforge.com/account/api-tokens), then save. This is a CurseForge token, not a GitHub personal access token or a third-party CurseForge data API key. A valid existing author token used for ZoidsTools can also be stored for this repository if its account can upload to Forever Suite. Secrets do not automatically carry over between repositories.
3. GitHub supplies `GITHUB_TOKEN` automatically; do not create that secret. The new workflow maps `CF_API_KEY` to the packager's current `CF_API_TOKEN` environment variable and the automatic GitHub token to `GH_API_TOKEN`. Never commit or paste the actual key in source, chat or screenshots.
4. Open **Actions > Package and Release > Run workflow**, choose `main` and run it. This manual run checks the addon, requests CurseForge's game-version list with the key, builds the real packager ZIP and compares its file list with the shipped source. It does not upload a release. A successful API read does not by itself prove upload permission for project 1749120.
5. Complete the CurseForge project and ensure its author account owns or can upload to project 1749120. The first tagged release confirms the actual upload destination and permission. Inspect the resulting file on CurseForge; approval and public availability can follow later.

## Release from GitHub Desktop

1. Finish local checks and the relevant in-game smoke tests. Update `CHANGELOG.md`, `Suite.version` in `Core.lua`, and `## Version` in **both** TOCs to the same version.
2. Commit and **Push origin** to back up changes. Wait for **Addon checks** to pass.
3. In **History**, right-click the intended release commit and choose **Create tag**. Use `v0.2.57` for the currently prepared version, or `vX.Y.Z` matching the next addon version.
4. Push the tag using **Push origin**. This triggers **Package and Release** automatically. A normal branch push alone does not upload to CurseForge.
5. Check the workflow's final result and CurseForge's file status. A successful upload is not the same as moderation approval. Release tags are unique; do not move an already published tag to different code.

The workflow fails before upload for missing credentials, failed addon checks, mismatched tag/version or unexpected archive contents. Manual **Run workflow** remains a setup check, even if a tag is selected.

## Working directory

User decision, October 16, 2026: `P:\GitHub Repos\WoW Forever Suite` is the canonical working copy. All future Forever Suite updates must be made only in this directory, including code, documentation, artwork and release configuration. Chats opened elsewhere must direct their edits and command working directories here. The user will manage the junction into the game's AddOns folder; do not update the former development copy or change the game junction without a later request.

## References

- [ZoidsTools release workflow](https://github.com/drockzoids-wow/ZoidsTools/blob/main/.github/workflows/release.yml)
- [GitHub Actions secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets)
- [GitHub Desktop tags](https://docs.github.com/en/desktop/managing-commits/managing-tags-in-github-desktop)
- [BigWigsMods packager](https://github.com/BigWigsMods/packager)
- [CurseForge Upload API](https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-upload-api)
