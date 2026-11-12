local Suite, equal, Frame, SetCombat = ...
local gui, catalog = Suite.GUI, Suite.SettingsCatalog
local oldPage, oldShown, oldApply, oldSeen = gui.page, gui.frame:IsShown(), Suite.Apply, Suite.db.setupGuide.seen
local oldPending, collapsed = Suite.pending, gui.collapsedSections
local width, height = UIParent.GetWidth, UIParent.GetHeight
Suite.pending, gui.collapsedSections = {}, {}
local applied = 0;Suite.Apply = function() applied = applied + 1 end
gui.frame:Show()
equal(gui.frame:GetWidth(), 1120, "workspace uses a wider rectangle")
equal(gui.frame:GetHeight(), 760, "workspace adds height without filling a widescreen display")
local primary, utilities = 0, 0
for _, group in ipairs(catalog.groups) do if group.utility then utilities = utilities + 1 else primary = primary + 1 end end
equal(primary, 7, "seven fixed browse sections include Tools")
equal(utilities, 1, "Suite Settings groups the utility pages")
local routes, previewPages = 0, { overview = true, items = true, actionbars = true, minimap = true, bags = true, macros = true, characters = true }
for _, group in ipairs(catalog.groups) do
    for _, entry in ipairs(group.pages) do
        local key = entry[1];gui:Select(key);routes = routes + 1
        equal(gui.viewportHeight, 500, "removing the top tab strip gives every page a larger viewport")
        local visible = 0
        for _, candidate in ipairs(catalog.groups) do
            if not candidate.utility and #candidate.pages > 1 then for _, leaf in ipairs(candidate.pages) do
                local tab = gui.tabs[leaf[1]]
                equal(tab:GetParent(), gui.sidebar, "page navigation lives in the sidebar")
                equal(tab:IsShown(), false, "category directories replace expanding sidebar leaves")
                if tab:IsShown() then
                    visible = visible + 1
                    equal(tab.point[2] + tab:GetWidth() <= gui.sidebar:GetWidth(), true, "page hit area stays inside sidebar")
                    equal(-tab.point[3] + tab:GetHeight() < 550, true, "expanded navigation clears help and setup")
                end
            end end
        end
        equal(visible, 0, "sidebar positions remain fixed on every leaf page")
        local cards = {}
        for index, data in ipairs(catalog.pages[key].rows) do
            local row = gui.rows[index]
            if row:IsShown() then
                local x, y = row.point[2], -row.point[3]
                equal(x >= 0 and x + row:GetWidth() <= gui.contentWidth, true, "setting tile stays inside content width")
                equal(y + row:GetHeight() <= gui.contentHeight - 36, true, "tile height is included in scrolling")
                equal(-row.help.point[3] >= -row.label.point[3] + row.label:GetHeight() + 4, true, "description clears wrapped title")
                equal(-row.help.point[3] + row.help:GetHeight() <= row:GetHeight() - 10, true, "description clears row bottom")
                cards[#cards + 1] = { x = x, y = y, width = row:GetWidth(), height = row:GetHeight(),
                    label = row.label.text, help = row.help.text, labelWidth = row.label:GetWidth(), labelHeight = row.label:GetHeight(),
                    helpY = -row.help.point[3], value = not data.key and row.value.text or nil, toggle = data.key ~= nil,
                    on = data.key and Suite.db[data.key] == true or false }
            end
        end
        for a = 1, #cards do for b = a + 1, #cards do
            local left, right = cards[a], cards[b]
            equal(left.x + left.width <= right.x or right.x + right.width <= left.x
                or left.y + left.height <= right.y or right.y + right.height <= left.y, true, "setting tiles never overlap")
        end end
        if WFS_WORKSPACE_PREVIEW and previewPages[key] then
            local model = { page = key, width = 1120, height = 760, contentWidth = gui.contentWidth, viewport = gui.viewportHeight,
                heading = gui.heading.text, description = gui.description.text, note = gui.note.text, contentHeight = gui.contentHeight,
                sidebar = {}, rows = cards, sections = {}, home = {} }
            for _, candidate in ipairs(catalog.groups) do
                local button = gui.groupTabs[candidate.key]
                model.sidebar[#model.sidebar + 1] = { label = candidate.label, x = 12, y = candidate.utility and 601 or -button.point[3],
                    width = button:GetWidth(), height = button:GetHeight(), active = group == candidate, group = true }
            end
            for _, section in ipairs(gui.sections) do if section:IsShown() then model.sections[#model.sections + 1] = { y = -section.point[3], label = section.label.text } end end
            if key == "overview" then for _, card in ipairs(gui.homeCards) do model.home[#model.home + 1] = { x = card.point[2], y = -card.point[3], width = card:GetWidth(), height = card:GetHeight(), label = card.label.text, help = card.help.text } end end
            WFS_WORKSPACE_PREVIEW(model)
        end
    end
end
equal(catalog.pageGroup.profiles.key,"suite","Profiles belongs to Suite Settings")
gui:Select("overview")
equal(gui.groupTabs.suite:IsShown(),true,"Suite Settings remains visible from Home")
gui.groupTabs.suite.OnClick(gui.groupTabs.suite)
equal(gui.page,"browse_suite","Suite Settings lists all its utility pages")
equal(gui.groupTabs.suite.point[2],12,"Suite Settings aligns with other sections")
equal(routes, 33, "all existing routes plus Support remain accessible")
local gear = Suite.GearSettings
gear:Open("picker")
for _, card in ipairs(gear.profileButtons) do
    equal(card.point[2] + card:GetWidth() <= gear.panel:GetWidth(), true, "three-column profiles fit their wider panel")
end
gear:Open("editor")
for _, field in ipairs(gear.fields) do
    equal(field.input.point[2] + field.input:GetWidth() <= gear.panel:GetWidth(), true, "three-column weight fields stay within panel")
    equal(-field.input.point[3] + field.input:GetHeight() < -gear.detailsButton.point[3], true, "weight fields clear the relocated footer")
end
equal(gear.panel:GetHeight() >= -gear.status.point[3] + gear.status:GetHeight(), true, "expanded weights keep the status inside the scrollable panel")
gear:Dismiss()
equal(gui.macroCombat.point[2] >= 280, true, "macro checkbox aligns with the wider detail pane")
equal(gui.setupReviewChild:GetWidth(), 750, "setup review text fills its wider viewport")
gui:Select("overview")
equal(gui.scrollFrame.suiteScrollBar:IsShown(), false, "home fits without scrolling")
local shortcuts = {}
for _, card in ipairs(gui.homeCards) do shortcuts[#shortcuts + 1] = { card = card, page = card.page } end
for _, shortcut in ipairs(shortcuts) do
    gui:Select("overview"); shortcut.card.OnClick();equal(gui.page, shortcut.page, "each home shortcut opens its destination")
end
equal(applied, 0, "navigation, layout and home shortcuts never apply optional features")
local trainingOpen, talentOpen, trainingCalls, talentCalls = Suite.Training.Open, Suite.TalentPlanner.Open, 0, 0
Suite.Training.Open = function() trainingCalls = trainingCalls + 1 end
Suite.TalentPlanner.Open = function() talentCalls = talentCalls + 1 end
gui:Select("overview");gui.homeToolButtons[2].OnClick();gui.homeToolButtons[3].OnClick()
equal(trainingCalls, 1, "Home launches the training tool directly")
equal(talentCalls, 1, "Home uses the talent tool's existing enable-aware opening action")
Suite.Training.Open, Suite.TalentPlanner.Open = trainingOpen, talentOpen
-- The directories and view tabs must expose every existing route and control without search.
local positions, reachable = {}, { overview = true }
for _, group in ipairs(catalog.groups) do positions[group.key] = { unpack(gui.groupTabs[group.key].point) } end
for _, group in ipairs(catalog.groups) do
    gui.groupTabs[group.key].OnClick()
    equal(gui.page, group.directory, "fixed section selection always opens its directory")
    if group.key ~= "overview" then
        local destinations = {}
        for _, card in ipairs(gui.homeCards) do if card:IsShown() then destinations[#destinations + 1] = card.page end end
        equal(#destinations, #group.pages, "directory exposes every child destination")
        for _, route in ipairs(destinations) do
            gui:Select(group.directory)
            local found
            for _, card in ipairs(gui.homeCards) do if card:IsShown() and card.page == route then found = card end end
            found.OnClick(); equal(gui.page, route, "directory cards lead to their named destinations")
            reachable[route] = true
            gui.breadcrumbGroup.OnClick(gui.breadcrumbGroup)
            equal(gui.page, group.directory, "category breadcrumb returns to the complete feature list")
        end
    end
end
local reached = 0; for _ in pairs(reachable) do reached = reached + 1 end
equal(reached, 33, "all destinations including Support can be browsed without search")
for _, route in ipairs({ "bags", "items", "actionbars" }) do
    gui:Select(route)
    equal(catalog.pages[route].views, nil, "feature options share one page without subview tabs")
    for _, group in ipairs(catalog.groups) do
        equal(gui.groupTabs[group.key].point[3], positions[group.key][3], "sidebar destinations remain fixed")
    end
    for index, data in ipairs(catalog.pages[route].rows) do
        equal(gui.rows[index]:IsShown(), not data.hidden, "all ordinary feature settings are present together")
        if not data.hidden then
            equal(gui.rows[index]:GetWidth(), gui.contentWidth, "settings use a single scan column")
            equal(gui.rowOffsets[index] + gui.rows[index]:GetHeight() <= gui.contentHeight - 36, true, "every setting can scroll above the footer")
        end
    end
    for _, button in ipairs(gui.viewButtons or {}) do equal(button:IsShown(), false, "no extra feature navigation is shown") end
    gui:ScrollTo(0);gui.rows[1]:OnMouseWheel(-1)
    equal(gui.scrollOffset,40,"wheel over settings scrolls the unified page")
end
gui:Select("actionbars")
equal(gui.procPanel:IsShown(),true,"proc sizing stays on the action bar page")
equal(gui.keybindPanel:IsShown(),true,"keybind appearance stays on the same action bar page")
equal(-gui.keybindPanel.point[3]>=-gui.procPanel.point[3]+gui.procPanel:GetHeight(),true,"action bar detail sections do not overlap")
equal(-gui.keybindPanel.point[3]+gui.keybindPanel:GetHeight()<=gui.contentHeight-36,true,"last action bar controls remain reachable")
local function Entry(key)
    for _, entry in ipairs(catalog.entries) do if entry.key == key then return entry end end
end
for _, key in ipairs({ "talentPlanner", "talentPlannerRules", "talentsOpen", "missingBuffRested", "missingBuffCampfire", "missingBuffSmart",
    "missingBuffScale", "missingBuffIconSize", "buffPreview", "buffReset", "buffCustom", "buffManage", "keybindSize", "procAlertIconSize" }) do
    local entry = Entry(key)
    equal(entry ~= nil, true, "previously nested controls are indexed individually")
    gui:RevealSetting(entry)
    local target = catalog:Target(gui, entry)
    equal(target ~= nil, true, "search can resolve the actual control in its destination view")
    local widget, visible = target, true
    while widget and widget ~= gui.frame do
        -- The substitute leaves new layout frames' shown field nil; WoW shows them by default.
        if widget.shown == false then visible = false end
        widget = widget.GetParent and widget:GetParent() or nil
    end
    equal(visible, true, "resolved search controls have no hidden ancestor: " .. key)
    equal(gui.settingHighlight:GetParent(), target, "search highlights the control without invoking it")
    if entry.view then equal(gui.pageViews[entry.page], entry.view, "search selects the view containing the result") end
end
gui:Select("buffs", "appearance")
Suite.BuffSettings.normalPreview:OnClick()
equal(Suite.MissingBuffs.preview:IsShown(), true, "appearance controls can preview the bar without enabling it")
Suite.BuffSettings.appearanceToggle:OnClick()
equal(Suite.MissingBuffs.preview:IsShown(), false, "collapsing appearance stops the owned preview")
local oldProcPreview = Suite.ProcAlerts.SetPreview
Suite.ProcAlerts.SetPreview = function(self, value) self.preview = value and true or nil end
gui:Select("actionbars", "feedback"); Suite.ProcAlerts:SetPreview(true)
gui:Select("bags")
equal(Suite.ProcAlerts.preview, nil, "leaving the action bar page stops its preview")
Suite.ProcAlerts.SetPreview = oldProcPreview
gui:Select("buffs", "reminders");gui:ScrollTo(100000)
local remembered = gui.scrollOffset
gui:Select("buffs", "visibility");gui:Select("buffs", "reminders")
equal(gui.scrollOffset, remembered, "the unified buff page retains its scrolling position")
Suite.BuffSettings.advancedOpen=false;Suite.BuffSettings:Refresh()
SetCombat(true)
Suite.BuffSettings.advancedToggle:OnClick()
equal(Suite.BuffSettings.advancedOpen, false, "buff layout controls ignore combat clicks")
gui:RevealSetting(Entry("missingBuffCampfire"))
equal(Suite.BuffSettings.advancedOpen, false, "combat search does not expand hidden details")
local reveal = Suite.pending.settingsReveal
equal(type(reveal), "function", "nested search queues its complete reveal until combat ends")
SetCombat(false);reveal()
equal(Suite.BuffSettings.advancedOpen, true, "deferred search expands the matching inline section after combat")
equal(gui.settingHighlight:GetParent(), Suite.BuffSettings.campfire, "deferred search highlights the specific hiding rule")
equal(applied, 0, "directory browsing, view changes and search never apply optional features")
for _, destination in ipairs({ { "bags", "inventory" }, { "items", "levels" }, { "actionbars", "feedback" }, { "actionbars", "keybinds" } }) do
    gui:Select(destination[1], destination[2])
    equal(gui.contentHeight >= gui.viewportHeight, true, "unified feature pages have a valid scroll range")
end
local originalScale = gui.frame:GetScale()
for _, size in ipairs({ { 1920, 1080 }, { 1366, 768 }, { 1024, 768 }, { 800, 600 } }) do
    UIParent.GetWidth = function() return size[1] end;UIParent.GetHeight = function() return size[2] end
    gui:FitToScreen()
    equal(gui.frame:GetWidth() * gui.frame:GetScale() <= size[1] - 48 + 0.00001, true, "automatic width fits available screen")
    equal(gui.frame:GetHeight() * gui.frame:GetScale() <= size[2] - 48 + 0.00001, true, "automatic height fits available screen")
    equal(gui.frame:GetScale() <= 1, true, "large screens do not magnify text unnecessarily")
end
for _, invalid in ipairs({ { secret = true }, 0 / 0, math.huge, 0, "1920" }) do
    local previous = gui.frame:GetScale();UIParent.GetWidth = function() return invalid end
    gui:FitToScreen();equal(gui.frame:GetScale(), previous, "invalid screen data does not enter layout arithmetic")
end
UIParent.GetWidth = function() return 1920 end;UIParent.GetHeight = function() return 1080 end
local previous = gui.frame:GetScale();SetCombat(true);gui:FitToScreen()
equal(gui.frame:GetScale(), previous, "screen-fit geometry defers in combat")
equal(type(Suite.pending.guiScreenFit), "function", "screen changes coalesce during combat")
SetCombat(false);Suite.pending.guiScreenFit()
equal(gui.frame:GetScale(), 1, "deferred fit uses latest available screen")
equal(Suite.pending.guiScreenFit, nil, "screen fitting leaves no pending worker")
UIParent.GetWidth, UIParent.GetHeight = width, height
gui:FitToScreen()
Suite.Apply, Suite.pending, gui.collapsedSections = oldApply, oldPending, collapsed
Suite.db.setupGuide.seen = oldSeen
gui:Select(oldPage or "overview");gui.frame:SetShown(oldShown)
