# Native clipboard probe

Temporary standalone reproduction for the Forever build 70790 clipboard failure. This is development tooling and is not part of Forever Suite or its release package.

Extract `WFSClipboardProbe.zip` into the client's `Interface/AddOns` directory so that it contains `WFSClipboardProbe/WFSClipboardProbe.toc` and `Probe.lua`. The user manages installation; do not overwrite another addon. A client restart may be needed to discover the new addon.

Enable **only WFS Clipboard Probe**, optionally with !BugGrabber and BugSack. Disable Forever Suite for this test. Outside combat, run `/wfscopyprobe`, select a new main-chat message and paste into an external text field. Record actual clipboard contents, any error and actual running build/Interface. The command has no success feedback and does not toggle off. Reload to reset its input changes. Disable the probe afterward; re-enable the user's normal addons.

The probe invokes only the native hyperlink, copyability and click-input setters. It creates no widgets and installs no native scripts, hooks, result callbacks or timers. It reads no chat/selection buffers and never calls CopyToClipboard. No SavedVariables are declared or changed.

If it fails, Forever Suite code is not required for that reproduction; this does not establish which native/client behavior caused the restriction. If it works, investigate Suite initialization separately. Do not infer clipboard success from selection highlights.
