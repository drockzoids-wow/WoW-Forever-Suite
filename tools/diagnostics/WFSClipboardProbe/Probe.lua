-- Standalone reproduction: no Suite code, hooks, widgets, callbacks, timers or saved data.
-- Reload to end the test and restore native chat input defaults.
SLASH_WFSCLIPBOARDPROBE1 = "/wfscopyprobe"
SlashCmdList.WFSCLIPBOARDPROBE = function()
    if InCombatLockdown() then return end
    ChatFrame1:SetHyperlinksEnabled(false)
    ChatFrame1:SetTextCopyable(true)
    ChatFrame1:SetMouseClickEnabled(true)
end
