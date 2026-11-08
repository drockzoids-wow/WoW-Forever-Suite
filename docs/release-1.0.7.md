# Forever Suite 1.0.7 — November 8, 2026

Released from commit `0aaa2030e3020719daaebfcbf2126036dceee6f9`, tag `v1.0.7`, following the user's explicit publication authorization. Core and both TOCs report 1.0.7. See [changes](../CHANGELOG.md#107--november-8-2026).

[Main CI](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/42485067973) and [Package and Release](https://github.com/drockzoids-wow/WoW-Forever-Suite/actions/runs/42485127391) both passed. The release workflow validated syntax/behavior, tag/version agreement, CurseForge authentication and exact package file inventory before publication.

The packager logged a successful upload of `WoWForeverSuite-v1.0.7-forever.zip` for Forever 1.60.1 to CurseForge project **1749120** at 13:29:04 UTC. Upload acceptance is confirmed; moderation/public availability was not verified. The public listing retrieved immediately afterward still showed older files and was not evidence of rejection or approval.

The [GitHub release](https://github.com/drockzoids-wow/WoW-Forever-Suite/releases/tag/v1.0.7) is published, with both ZIP and release.json uploaded. GitHub reports archive SHA256 `144c7359775a0b63cb106e476eefce77538d9b3d53b61a97c1a7a9c4c387d4b9`. This remote packager archive is distinct from the local PowerShell ZIP.

Local validation passed: **82 Lua 5.1 files, 32,010 behavior assertions, 68 registered Lua spec files, identical TOCs/Core version**, clean scope/whitespace checks and release-workflow substitute checks. All **91** local package entries match source hashes, with no extra, missing or duplicate files. Local archive SHA256: `4520BD525BB8371FC0A1CAD6F2ECB3262FEAB65F95FA4E2FF1007825323E5705`; receipt `.cache/release-107/package-receipt.json`.

The new gamepad visibility and independent saved-bag regressions each failed before correction and now pass. Native tests remain qualified in [testing.md](testing.md): publication authorization does not establish game compatibility, appearance or taint safety. Separate scoring research remains uncommitted and outside this release/package. No game deployment, junction or SavedVariables changes were made.
