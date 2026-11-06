local _, Suite = ...
local Shortcuts = { registered = {} }
Suite.Shortcuts = Shortcuts
table.insert(Suite.modules, Shortcuts)

local commands = {
    { key = "kb", label = "Quick Keybind" },
    { key = "edit", label = "Edit Mode" },
    { key = "binds", label = "Key bindings" },
    { key = "macros", label = "Blizzard macros" },
    { key = "cal", label = "Calendar" },
    { key = "settings", label = "Settings" },
    { key = "addons", label = "AddOns" },
    { key = "rl", label = "Reload UI" },
}
local byKey = {}
for _, command in ipairs(commands) do byKey[command.key] = command end

function Shortcuts:Enabled()
    return Suite.db and Suite.IsReadable(Suite.db.chatShortcuts) and Suite.db.chatShortcuts == true
end

local function Shown(frame)
    if not frame or type(frame.IsShown) ~= "function" then return nil end
    local value = frame:IsShown()
    return Suite.IsReadable(value) and type(value) == "boolean" and value or nil
end

local function Open(key)
    if key == "kb" then
        if not QuickKeybindFrame or type(QuickKeybindFrame.Show) ~= "function"
            or not SettingsPanel or type(SettingsPanel.Close) ~= "function" then return false end
        if Shown(QuickKeybindFrame) then return true end
        -- Match Blizzard's settings button: close settings without returning to its opener.
        if Shown(SettingsPanel) then
            if type(SettingsPanel.HasUnappliedSettings) == "function" then
                local pending = SettingsPanel:HasUnappliedSettings()
                if not Suite.IsReadable(pending) or pending ~= false then
                    Suite.Print("Apply or cancel your pending game settings before Quick Keybind."); return true
                end
            end
            SettingsPanel:Close(true)
        end
        QuickKeybindFrame:Show()
    elseif key == "edit" then
        if not EditModeManagerFrame or type(EditModeManagerFrame.CanEnterEditMode) ~= "function"
            or type(ShowUIPanel) ~= "function" then return false end
        local allowed = EditModeManagerFrame:CanEnterEditMode()
        if not Suite.IsReadable(allowed) or allowed ~= true then return false end
        ShowUIPanel(EditModeManagerFrame)
    elseif key == "binds" then
        if not Settings or type(Settings.OpenToCategory) ~= "function"
            or not Suite.IsReadable(Settings.KEYBINDINGS_CATEGORY_ID) or type(Settings.KEYBINDINGS_CATEGORY_ID) ~= "number" then return false end
        Settings.OpenToCategory(Settings.KEYBINDINGS_CATEGORY_ID)
    elseif key == "settings" then
        if not SettingsPanel or type(SettingsPanel.Open) ~= "function" then return false end
        SettingsPanel:Open()
    elseif key == "addons" then
        if not AddonList or type(ShowUIPanel) ~= "function" then return false end
        ShowUIPanel(AddonList)
    else
        -- Use native command handlers so their game-rule checks and lazy loading remain native.
        local native = ({ macros = "MACRO", cal = "CALENDAR", rl = "RELOAD" })[key]
        local handler = native and SlashCmdList[native]
        if type(handler) ~= "function" then return false end
        handler("")
    end
    return true
end

function Shortcuts:Run(key)
    if not self:Enabled() then Suite.Print("Enable Chat Shortcuts in /wfs shortcuts first."); return end
    if InCombatLockdown() then Suite.Print("Chat shortcuts are available outside combat. Try again afterward."); return end
    local ok, result = pcall(Open, key)
    if not ok or result ~= true then Suite.Print("This shortcut is unavailable right now. Try the game's menu.") end
end

function Shortcuts:Handle(key)
    -- Preserve /wfs macros as the Suite builder; use /wfs mac for Blizzard's editor.
    if key == "mac" then key = "macros" elseif key == "macros" then return false end
    if not byKey[key] then return false end
    self:Run(key)
    return true
end

function Shortcuts:Help()
    Suite.Print("Chat Shortcuts: " .. (self:Enabled() and "on" or "off (enable in /wfs shortcuts)"))
    for _, command in ipairs(commands) do
        local fallback = command.key == "macros" and "mac" or command.key
        Suite.Print("/" .. command.key .. " — " .. command.label .. " (also /wfs " .. fallback .. ")")
    end
    Suite.Print("Existing commands take priority. /wfs macros opens the Suite Macro Builder.")
end

function Shortcuts:Apply()
    if self.active == self:Enabled() then return end
    for id, entry in pairs(self.registered) do
        if SlashCmdList[id] == entry.handler then
            SlashCmdList[id] = nil
            if _G["SLASH_" .. id .. "1"] == entry.alias then _G["SLASH_" .. id .. "1"] = nil end
        end
        -- Blizzard caches callbacks by uppercase alias after the first use.
        if hash_SlashCmdList and hash_SlashCmdList[entry.alias:upper()] == entry.handler then
            hash_SlashCmdList[entry.alias:upper()] = nil
        end
    end
    self.registered = {}
    self.active = self:Enabled()
    if not self.active then return end
    local occupied = {}
    for name, value in pairs(_G) do
        if type(name) == "string" and name:match("^SLASH_.+%d+$") and Suite.IsReadable(value) and type(value) == "string" then
            occupied[value:lower()] = true
        end
    end
    for _, command in ipairs(commands) do
        local key, alias = command.key, "/" .. command.key
        local id = "WOWFOREVERSUITESHORTCUT_" .. key:upper()
        local cached = hash_SlashCmdList and hash_SlashCmdList[alias:upper()]
        local secure = type(IsSecureCmd) == "function" and IsSecureCmd(alias)
        if not occupied[alias] and not cached and not secure and not SlashCmdList[id] then
            local handler = function() self:Run(key) end
            _G["SLASH_" .. id .. "1"] = alias
            SlashCmdList[id] = handler
            self.registered[id] = { alias = alias, handler = handler }
        end
    end
end
