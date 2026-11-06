local Suite, equal, Frame, setCombat = ...
local shortcuts = Suite.Shortcuts
local saved = { db = Suite.db, print = Suite.Print, settings = Settings, panel = SettingsPanel,
    quick = QuickKeybindFrame, edit = EditModeManagerFrame, addons = AddonList, show = ShowUIPanel,
    hash = hash_SlashCmdList, secure = IsSecureCmd, macro = SlashCmdList.MACRO,
    calendar = SlashCmdList.CALENDAR, reload = SlashCmdList.RELOAD, page = Suite.GUI.page }
local output, calls = {}, {}
Suite.Print = function(message) output[#output + 1] = message end
Suite.db = Suite.InitializeDB(nil)
shortcuts:Apply()
equal(Suite.db.chatShortcuts, false, "shortcuts default off")
equal(SLASH_WOWFOREVERSUITESHORTCUT_KB1, nil, "disabled shortcuts claim no aliases")

-- Exercise all three native collision paths: declarations, cached handlers and secure commands.
local other = function() end
SLASH_WFSSHORTCUTTEST1 = "/EdIt"
SlashCmdList.WFSSHORTCUTTEST = other
hash_SlashCmdList = { ["/CAL"] = other }
IsSecureCmd = function(alias) return alias == "/rl" end
Suite.db.chatShortcuts = true
shortcuts:Apply()
equal(SLASH_WOWFOREVERSUITESHORTCUT_KB1, "/kb", "available alias registered")
equal(SLASH_WOWFOREVERSUITESHORTCUT_EDIT1, nil, "case-insensitive declared collision preserved")
equal(SLASH_WOWFOREVERSUITESHORTCUT_CAL1, nil, "cached collision preserved")
equal(SLASH_WOWFOREVERSUITESHORTCUT_RL1, nil, "secure collision preserved")
equal(SlashCmdList.WFSSHORTCUTTEST, other, "other command callback preserved")
local kb = SlashCmdList.WOWFOREVERSUITESHORTCUT_KB
shortcuts:Apply()
equal(SlashCmdList.WOWFOREVERSUITESHORTCUT_KB, kb, "unrelated Apply retains callback")

SettingsPanel = Frame()
SettingsPanel:Show()
SettingsPanel.Close = function(self, skip) calls.closed = skip; self:Hide() end
SettingsPanel.Open = function() calls.settings = true end
SettingsPanel.HasUnappliedSettings = function() return false end
QuickKeybindFrame = Frame()
QuickKeybindFrame.Show = function(self) calls.quick = (calls.quick or 0) + 1; self.shown = true end
EditModeManagerFrame = Frame()
EditModeManagerFrame.CanEnterEditMode = function() return true end
AddonList = Frame()
ShowUIPanel = function(frame) calls.panel = frame end
Settings = { KEYBINDINGS_CATEGORY_ID = 42, OpenToCategory = function(id) calls.category = id end }
SlashCmdList.MACRO = function(msg) calls.macro = msg end
SlashCmdList.CALENDAR = function(msg) calls.calendar = msg end
SlashCmdList.RELOAD = function(msg) calls.reload = msg end

setCombat(false)
kb()
equal(calls.closed, true, "quick binding closes settings without transition")
equal(calls.quick, 1, "quick binding opens Blizzard frame")
kb()
equal(calls.quick, 1, "repeated kb does not restart binding mode")
QuickKeybindFrame:Hide(); SettingsPanel:Show()
SettingsPanel.HasUnappliedSettings = function() return true end
kb()
equal(calls.quick, 1, "pending settings are preserved")
equal(SettingsPanel:IsShown(), true, "pending settings keep native panel open")
shortcuts:Run("edit")
equal(calls.panel, EditModeManagerFrame, "edit opens native manager despite alias conflict")
calls.panel = nil
EditModeManagerFrame.CanEnterEditMode = function() return false end
shortcuts:Run("edit")
equal(calls.panel, nil, "native edit permission enforced")
for _, key in ipairs({ "binds", "settings", "addons", "macros", "cal", "rl" }) do shortcuts:Run(key) end
equal(calls.category, 42, "binds uses native keybindings category")
equal(calls.settings, true, "settings uses native opener")
equal(calls.panel, AddonList, "addons opens native list")
equal(calls.macro, "", "macros delegates to native command")
equal(calls.calendar, "", "calendar delegates to native command")
equal(calls.reload, "", "reload delegates to native command")
calls.reload = nil
setCombat(true)
shortcuts:Run("rl")
equal(calls.reload, nil, "combat never reloads")
setCombat(false)
equal(calls.reload, nil, "combat request is not replayed")
Settings = nil; QuickKeybindFrame = nil; SlashCmdList.MACRO = nil
for _, key in ipairs({ "binds", "kb", "macros" }) do
    local before = #output
    shortcuts:Run(key)
    equal(#output, before + 1, "missing capability reports unavailable: " .. key)
end
SettingsPanel.Open = function() error("native failure") end
shortcuts:Run("settings")
equal(output[#output]:find("unavailable", 1, true) ~= nil, true, "native failures give readable feedback")
Suite.Print = saved.print
Suite.GUI:OpenPage("shortcuts")
equal(Suite.GUI.page, "shortcuts", "shortcut settings are reachable")
equal(Suite.SettingsCatalog:Search("quick keybinding")[1].key, "chatShortcuts", "shortcut commands are searchable")
Suite.Print = function(message) output[#output + 1] = message end
equal(shortcuts:Handle("macros"), false, "wfs macros retains Suite builder")
local handled = false
SlashCmdList.MACRO = function() handled = true end
SlashCmdList.WOWFOREVERSUITE("  MAC  ")
equal(handled, true, "namespaced fallback opens Blizzard editor")
SlashCmdList.WOWFOREVERSUITE("commands")
equal(output[#output]:find("Suite Macro Builder", 1, true) ~= nil, true, "help explains existing macro route")

hash_SlashCmdList["/KB"] = kb
-- Another addon may replace one of our callbacks after registration.
SlashCmdList.WOWFOREVERSUITESHORTCUT_BINDS = other
hash_SlashCmdList["/BINDS"] = other
Suite.db.chatShortcuts = false
shortcuts:Apply()
equal(SlashCmdList.WOWFOREVERSUITESHORTCUT_KB, nil, "disable unregisters owned command")
equal(SLASH_WOWFOREVERSUITESHORTCUT_KB1, nil, "disable releases alias")
equal(hash_SlashCmdList["/KB"], nil, "disable clears owned cached callback")
equal(hash_SlashCmdList["/BINDS"], other, "disable preserves replaced cached callback")
equal(SlashCmdList.WOWFOREVERSUITESHORTCUT_BINDS, other, "disable preserves replaced command handler")
equal(SLASH_WOWFOREVERSUITESHORTCUT_BINDS1, "/binds", "disable preserves alias for replaced handler")
handled = false; kb()
equal(handled, false, "stale callback stays inert after disable")
SLASH_WFSSHORTCUTTEST1, SlashCmdList.WFSSHORTCUTTEST = nil, nil
SlashCmdList.WOWFOREVERSUITESHORTCUT_BINDS = nil
SLASH_WOWFOREVERSUITESHORTCUT_BINDS1 = nil
Suite.db, Suite.Print = saved.db, saved.print
Settings, SettingsPanel, QuickKeybindFrame = saved.settings, saved.panel, saved.quick
EditModeManagerFrame, AddonList, ShowUIPanel = saved.edit, saved.addons, saved.show
hash_SlashCmdList, IsSecureCmd = saved.hash, saved.secure
SlashCmdList.MACRO, SlashCmdList.CALENDAR, SlashCmdList.RELOAD = saved.macro, saved.calendar, saved.reload
shortcuts:Apply()
Suite.GUI:Select(saved.page)
