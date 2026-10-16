local Suite, equal, Frame, setCombat, events = ...
local gui = Suite.GUI
local saved = {
    db = Suite.db, settings = Settings, nativePanel = SettingsPanel, apply = Suite.Apply,
    category = gui.settingsCategory, panel = gui.settingsPanel,
    page = gui.page, shown = gui.frame:IsShown(),
    popup = StaticPopup_Show, newTimer = C_Timer.NewTimer,
}
local canvases, categories = {}, {}
local api = {
    RegisterCanvasLayoutCategory = function(panel, name)
        local category = { name = name, panel = panel }
        canvases[#canvases + 1] = category
        return category
    end,
    RegisterAddOnCategory = function(category) categories[#categories + 1] = category end,
}
Suite.Apply = function() end
Settings = api
Suite.db = nil
gui:RegisterSettings()
equal(#canvases, 0, "settings registration waits for saved variables")

Suite.db = Suite.InitializeDB(nil)
Settings = nil
events.OnEvent(events, "PLAYER_LOGIN")
equal(#canvases, 0, "login tolerates an unavailable Settings API")
Settings = { RegisterCanvasLayoutCategory = api.RegisterCanvasLayoutCategory }
events.OnEvent(events, "ADDON_LOADED", "Blizzard_Settings_Shared")
equal(#canvases, 0, "partial Settings API creates no orphan canvas")

Settings = api
events.OnEvent(events, "ADDON_LOADED", "Blizzard_Settings_Shared")
equal(#canvases, 1, "late settings availability registers a canvas")
equal(#categories, 1, "canvas is added to the native AddOns list")
equal(categories[1], canvases[1], "native registration receives the returned category")
equal(categories[1].name, "Forever Suite", "category has the addon display name")
equal(categories[1].panel, gui.settingsPanel, "native settings own the registered canvas layout")
equal(gui.settingsPanel:IsShown(), false, "registration leaves the canvas hidden until native selection")
equal(Suite.db.actionBarSkin, false, "registration works with optional features disabled")
equal(Suite.db.minimapButton, true, "registration preserves the independent minimap launcher")
local panel = gui.settingsPanel
events.OnEvent(events, "PLAYER_LOGIN")
events.OnEvent(events, "ADDON_LOADED", "UnrelatedAddon")
gui:RegisterSettings()
equal(#categories, 1, "repeated startup and addon events do not duplicate the category")
equal(gui.settingsPanel, panel, "repeated registration reuses the canvas")

SettingsPanel = Frame()
local closes, skipTransition = 0, nil
SettingsPanel.Close = function(self, skip)
    closes, skipTransition = closes + 1, skip
    self:Hide()
    -- Model native window cleanup hiding Escape-registered addon windows.
    gui.frame:Hide()
end
SettingsPanel.HasUnappliedSettings = function(self) return self.unapplied end
SettingsPanel:Show()
gui.frame:Hide()
gui.page = nil
panel.openButton.OnClick()
equal(gui.frame:IsShown(), true, "native launcher opens the Suite GUI")
equal(gui.page, "overview", "first launch selects Overview")
equal(SettingsPanel:IsShown(), false, "native launcher closes Options before showing Suite")
equal(skipTransition, true, "launcher skips the native transition back to the game menu")
gui:OpenPage("actionbars")
gui.frame:Hide()
SettingsPanel:Show()
panel.openButton.OnClick()
equal(gui.page, "actionbars", "native launcher preserves the last Suite page")
equal(gui.frame:IsShown(), true, "native launcher reopens the last page")
panel.openButton.OnClick()
equal(gui.frame:IsShown(), true, "Open does not close an already visible Suite GUI")
equal(closes, 2, "already hidden Options are not closed again")
equal(Suite.db.actionBarSkin, false, "opening settings does not enable a feature")

local timers, prompt, afterPrompt = {}, nil, nil
C_Timer.NewTimer = function(delay, callback)
    local timer = { delay = delay, callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end
StaticPopup_Show = function(which, _, _, _, _, onHide) prompt, afterPrompt = which, onHide end
local function RunTimers()
    local work = timers
    timers = {}
    for _, timer in ipairs(work) do if not timer.cancelled then timer.callback() end end
end
SettingsPanel.unapplied = true
SettingsPanel:Show()
gui.frame:Hide()
local beforePrompt = closes
panel.openButton.OnClick()
equal(prompt, "GAME_SETTINGS_CONFIRM_DISCARD", "unapplied options use Blizzard's existing close dialog")
equal(closes, beforePrompt, "launcher does not silently commit or discard native settings")
equal(gui.frame:IsShown(), false, "Suite waits for the native close decision")
afterPrompt() -- Cancel or Escape closes the dialog while Options remains visible.
RunTimers()
equal(SettingsPanel:IsShown(), true, "cancelling the close prompt leaves Options open")
equal(gui.frame:IsShown(), false, "cancelling the close prompt cancels the Suite launch")
SettingsPanel:Close()
RunTimers()
equal(gui.frame:IsShown(), false, "later manual Options close cannot revive a cancelled launch")

for _, decision in ipairs({ "Apply", "Discard" }) do
    SettingsPanel:Show()
    panel.openButton.OnClick()
    SettingsPanel:Close() -- The native decision closes Options and runs its normal cleanup.
    afterPrompt()
    gui.frame:Hide() -- Further synchronous game-menu/window cleanup must finish first.
    equal(gui.frame:IsShown(), false, decision .. " waits until native cleanup returns")
    equal(timers[1].delay, 0, decision .. " queues one next-turn launch")
    RunTimers()
    equal(gui.frame:IsShown(), true, decision .. " opens Suite after all native cleanup")
    equal(gui.page, "actionbars", decision .. " retains the last Suite page")
    equal(gui.settingsOpenTimer, nil, decision .. " leaves no launch timer")
end

SettingsPanel.unapplied = false
SettingsPanel:Show()
gui.frame:Hide()
setCombat(true)
panel.openButton.OnClick()
panel.openButton.OnClick()
equal(SettingsPanel:IsShown(), true, "combat launch does not close a protected native panel")
equal(gui.frame:IsShown(), false, "combat launch waits for the complete handoff")
equal(type(Suite.pending.settingsOpen), "function", "combat launch uses one coalesced callback")
setCombat(false)
events.OnEvent(events, "PLAYER_REGEN_ENABLED")
equal(SettingsPanel:IsShown(), false, "combat exit closes Options")
equal(gui.frame:IsShown(), true, "combat exit opens Suite after closing Options")
equal(Suite.pending.settingsOpen, nil, "combat launch clears its pending work")
SettingsPanel = nil
gui.frame:Hide()
panel.openButton.OnClick()
equal(gui.frame:IsShown(), true, "launcher tolerates an absent native panel")
SettingsPanel = saved.nativePanel
C_Timer.NewTimer, StaticPopup_Show = saved.newTimer, saved.popup

-- Model a fresh startup in combat without constructing or registering its canvas.
gui.settingsCategory, gui.settingsPanel = nil, nil
canvases, categories = {}, {}
setCombat(true)
events.OnEvent(events, "PLAYER_LOGIN")
events.OnEvent(events, "ADDON_LOADED", "Blizzard_Settings_Shared")
gui:RegisterSettings()
equal(#canvases, 0, "combat defers native settings registration")
equal(gui.settingsPanel, nil, "combat defers launcher frame creation")
equal(type(Suite.pending.settingsCategory), "function", "combat queues one registration callback")
setCombat(false)
events.OnEvent(events, "PLAYER_REGEN_ENABLED")
equal(#categories, 1, "combat exit completes coalesced registration once")
equal(Suite.pending.settingsCategory, nil, "completed registration leaves no pending work")

-- Recheck capabilities when deferred work runs, then recover through a late load.
gui.settingsCategory, gui.settingsPanel = nil, nil
canvases, categories = {}, {}
setCombat(true)
gui:RegisterSettings()
Settings = nil
setCombat(false)
events.OnEvent(events, "PLAYER_REGEN_ENABLED")
equal(#canvases, 0, "deferred registration rechecks API availability")
Settings = api
events.OnEvent(events, "ADDON_LOADED", "Blizzard_Settings_Shared")
equal(#categories, 1, "late load recovers after a deferred API check")

Suite.db, Suite.Apply = saved.db, saved.apply
Settings, SettingsPanel = saved.settings, saved.nativePanel
gui.settingsCategory, gui.settingsPanel = saved.category, saved.panel
gui:Select(saved.page or "overview")
gui.frame:SetShown(saved.shown)
