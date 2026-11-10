# Copyable support reports and capability diagnostics

Open **Suite Settings → Support → Open support report**, `/wfs support`, or `/wfs diagnostics`. The selected text can be copied with Ctrl+C; use Select all or Ctrl+A to select it again. Refresh takes a new snapshot. Escape or Close dismisses the window.

`/wfs status` prints the client metadata, status counts and unavailable/paused/unknown feature reasons in chat. During combat, `/wfs support`, `/wfs diagnostics` and `/wfs status` capture a report without constructing or opening a window. After combat, explicitly open `/wfs support` to copy that exact snapshot, including its original timestamp and combat reasons. The footer identifies captured combat context; Refresh replaces it with current state. No window opens automatically after combat.

## Status meanings

| Status | Meaning |
| --- | --- |
| Off | The feature switch or required parent switch is disabled. This takes priority over stale cleanup/deferred work. |
| Unavailable | A listed required function/component is missing or unreadable, a public availability predicate refuses support, or a known requirement cannot be met. |
| Paused | Relevant setup/layout work is queued, the feature's actions wait for combat to end, native macro edits are open, audio waits for a movie/cinematic, or combat aura layout is suspended. Existing displays may continue when only layout/setup is queued. |
| Waiting | The feature is enabled but needs an observed context, such as a vendor/mailbox visit, an open checklist, camp proximity, or loaded talent data. |
| Ready | Listed probes passed. Some entries check only their Suite component, explicitly stating that native widget/context readiness was not probed. This is not gameplay, visual or taint verification. |
| Unknown | A setting, predicate result, context observation or required state cannot safely be read. |

The report covers the main feature switches, three castbar switches and explicit Macro Builder/random-mount/contact-book tools. Dependent buff switches are evaluated with their parent. Class-macro maintenance being Off does not disable the independent login/use checks for already-created item macros.

## What is captured

The allowlist includes Suite/client versions, build and Interface, locale, numeric server timestamp, public combat state, whether settings loaded at startup, comparison mode and a built-in profile ID or the generic label `custom`. Feature rows contain fixed labels/keys, their status and a fixed diagnostic reason. Missing function names come from the static capability catalog. No arbitrary settings/deferred-work/error dump is generated.

Function-level requirements are checked without invoking their actions. The few native read-only probes are build/locale/time/combat metadata, existing window visibility, `C_DamageMeter.IsDamageMeterAvailable` and `C_CVar.GetCVarInfo` for audio output permission flags. The device value and native failure strings are discarded. School-parser availability reflects the selected profile and locale, without requesting any item/tooltip data.

Snapshots never inspect another player, enumerate inventory, query an inbox, read chat messages, retrieve macro bodies, scan auras/mounts, re-run module Apply, execute pending callbacks, register gameplay events, or retry protected actions. They do not initialize scoring caches, change switches, upload anything or write SavedVariables. No polling or idle timer is added.

## Privacy and lifetime

Player/realm names, contact records/notes, chat history, inventory contents, macro names/text, custom profile names/coefficients, output-device identifiers, arbitrary pending keys and raw error/availability strings are omitted. Metadata is type/format checked before rendering; secret values and rejected native calls receive a fixed unavailable/unknown explanation.

Reports remain in memory only. Closing clears displayed text and keyboard focus and unregisters the window's combat event. An explicitly captured combat report is retained only until opening/replacing it or reloading; there is one pending captured snapshot. The window closes on combat entry, and opening/copy controls do no UI construction or movement in combat.

## Limits and validation

Capability presence cannot establish ordinary-addon permission for every call, fresh asynchronous item data, macro ownership, a usable collected mount, role calibration, available targets, loaded native widget behavior, conflicts with other addons or taint safety. The report does not harvest error stacks or probe combat amounts. Use the focused native smoke tests in `testing.md` alongside the report.

`tests/diagnostics_spec.lua` checks missing member versus namespace presence, native refusal/error/secret results, context/dependency/combat precedence, observed deferred work, school locale requirements, audio permission flags, privacy sentinels, unreadable settings and metadata, no action/scan/timer calls, immutable selectable text, native text-script preservation, Refresh, exact post-combat capture, aliases, settings/search access, focus/Escape and cleanup. Clipboard interaction and visual layout still require in-game validation.
