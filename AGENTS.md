# Forever Suite development

## Required working directory

- User instruction, October 16, 2026: make all Forever Suite updates only in `P:\GitHub Repos\WoW Forever Suite`. This is the canonical working copy for code, documentation, artwork, checks and release configuration in every Forever Suite chat.
- If a chat starts in another directory, direct file edits and command working directories to this canonical checkout and read its project instructions before continuing. Do not update or synchronize changes back to `C:\Games\Development\WoW Forever Suite` or another copy.
- The user will manage the junction into the game's AddOns folder. Do not deploy or change that junction unless the user later requests it.

Build a personal, modular addon for WoW Forever. The user wants selected QoL features and an original GUI. Treat Enhance QoL as a feature reference; do not copy its implementation, assets, layouts or visual identity. Its upstream LICENSE is all rights reserved.

Read `docs/forever-development.md`, `docs/feature-plan.md` and `docs/testing.md` before substantial changes. Keep these findings and feature decisions current.

## Client and source

- Installed game: `C:\Games\World of Warcraft\_classic_beta_`.
- Verified on October 5, 2026: product `wow_classic_beta`, executable `1.60.1.70205`, Interface `16001`.
- This client uses modern API conventions. A low Interface number does not imply Classic Era APIs. Prefer capability checks and exact build sources.
- Source of truth for implementations: the running client, then its matching Blizzard API and UI source. The cached mirror is `.cache/wow-ui-source/Interface/AddOns`; revision metadata is `.cache/forever-ui-source.json`.
- `.cache/forever-api.json` is a community export from build 70170. It is a secondary signature index and omits important restrictions. Never treat it as proof that an API is available to ordinary addon code on build 70205.
- Cache files and third-party source are development references. Never package them with the addon.

## Implementation

- Use WoW-compatible Lua 5.1 syntax and current `C_Item`, `C_Container`, `C_Spell` and tooltip APIs. Check functions and return shapes, including nil results and asynchronous data.
- Keep addon code in the namespace passed through `...`. Avoid global writes except declared SavedVariables, slash commands and narrowly documented compatibility hooks.
- Guard secret values before using them in conditions, comparisons, arithmetic, formatting, keys or serialization. Do not try to recover hidden combat information. Check per-function predicates and permitted widget operations.
- Defer protected frame creation, anchors, movement and scale changes while `InCombatLockdown()` is true. Do not modify `UIPanelWindows`, replace Blizzard secure functions, or detach protected HUD elements from their native management.
- Each module must be independently optional. Defaults start off so the user can test against the existing addon setup. Use events, coalesced work and cancellable timers; avoid idle per-frame updates.
- The requested minimap settings launcher starts visible and can be disabled independently. Save its angle, project it onto circular or rectangular map edges, and use OnUpdate only during a drag gesture; preserve `/wfs` access when hidden.
- Movement restores original anchors and scale. Resize standard windows proportionally; do not claim that all protected frames or third-party UIs are supported.
- When window tools are enabled, supported windows and bags stay movable without an unlock/lock mode or separate drag bars. Use empty native header space, preserving native close buttons, arrows, filters, menus and clickable titles. Bag title menu routers can be anonymous children; Calendar has a raised central header. Parent transparent input frames to their windows and keep them above native header layers (Blizzard commonly uses level 510). Passive or unlaid-out descendants must not erase a whole header's input area. Resize exclusively with Ctrl+mouse-wheel over the header; never add a resize icon/grip. Per-window reset requires Ctrl-right-click on empty header space or the background; plain right-click must preserve saved positions.
- Bag titles share native menu and drag input: recognize the anonymous PortraitButton router, forward ordinary left-clicks on release, and cancel clicks on drag, wheel, hide or combat. Exclude the actual portrait and close buttons.
- The user explicitly requested draggable lower-left and lower-right corners for the Suite-owned damage meters on October 6. Those meters may use corner grips and free width/height resizing; the Ctrl-wheel-only rule above still applies to the general native window tools. Keep meter selectors visibly distinct from the header's drag area.
- The user's subsequent October 6 meter redesign requests a shared lock that hides corner grips and prevents movement/resizing. This lock applies only to Suite-owned damage meters; native window tools remain movable without an unlock mode.
- Preserve Blizzard's minimap coordinate frame and CVar. Anchor stats below it, avoid duplicate coordinates/time, and keep native header widgets' parents and scripts while restoring their layout when square mode is disabled.
- Tooltip post-calls must use the supplied data and guard optional methods. Comparison tooltips lack GameTooltip's `GetItem`/`GetUnit` compatibility methods on this client.
- Upgrade hints mean improvements under disclosed stat weights. Do not label them definitive best-in-slot decisions. Do not compare weapon configurations without a model for DPS and hand combinations.
- The GUI is an original slate-and-teal panel with a sidebar, reusable controls and clear wording. Keep implementation and research details out of normal user flows.

## Validation and delivery

- Run `node scripts/check-addon.cjs` after code changes. If its cache is missing, `scripts/Bootstrap-Checks.ps1` fetches pinned test dependencies without install scripts.
- The checks cover Lua syntax, packaging inputs and behavior with API substitutes. They do not prove game compatibility, taint safety or visual correctness.
- In-game smoke tests in `docs/testing.md` are required before calling a feature verified. Record the actual build and results.
- `scripts/Deploy.ps1` creates a new junction to this workspace and refuses to overwrite an existing addon. Do not delete or modify the user's other addons or SavedVariables.
- Ship only `src/WoWForeverSuite` through `scripts/Package.ps1`. Keep both TOC variants identical.
