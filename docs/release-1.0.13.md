# Forever Suite 1.0.13

November 11, 2026. User authorizes addon review and CurseForge publication if the code looks good. The offline review identifies no new concrete release blocker; [review and native limits](addon-review-2026-11-11.md). Core and both TOCs advance together to 1.0.13. [Changes](../CHANGELOG.md#1013--november-11-2026).

Includes profession leveling guides and remaining-material/ownership views, manual and optional automatic recipe selection, one-time existing-setting adoption, shared bank search, optional personal-bank reagent deposits and flat buff-icon borders. New main guide/deposit modules remain independently optional/default-off. Recipe selection never starts crafting. No game deployment, junction or live SavedVariables edits.

Local checks: 89 Lua 5.1 files, matching TOCs and 37,439 substitute behavior assertions; all 11 gear-baseline tests pass. git diff --check passes. Package entry/hash and final CI/upload receipts follow after execution.

scripts/Package.ps1 produced dist/WoWForeverSuite-1.0.13.zip. Archive verification compared all 98 non-directory entries and their SHA256 hashes with src/WoWForeverSuite: no extra, duplicate, omitted or mismatched files. ZIP SHA256: F32EF9A0527CAFBA833B2D53A52AA80443018AB0066B8F58D89E6EF3A24EE44F. Remote main matched local HEAD 5dfe045d84f4fae340166ac48a6881fdd8ea0c72; v1.0.13 was absent during preflight. CI/upload not yet observed.

Use the existing v1.0.13 tag workflow for CurseForge project 1749120 with Forever flavor. Native permission/input/layout/batch/taint smoke tests remain pending and are not established by publication; the existing bag-use taint investigation remains open. CurseForge upload acceptance and public moderation availability are separate observations.
