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
equal(primary, 6, "Profiles has its own primary workspace")
equal(utilities, 1, "setup stays a separate utility")
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
                equal(tab:IsShown(), candidate == group, "only the active workspace reveals its pages")
                if tab:IsShown() then
                    visible = visible + 1
                    equal(tab.point[2] + tab:GetWidth() <= gui.sidebar:GetWidth(), true, "page hit area stays inside sidebar")
                    equal(-tab.point[3] + tab:GetHeight() < 550, true, "expanded navigation clears help and setup")
                end
            end end
        end
        equal(visible, (group.utility or #group.pages == 1) and 0 or #group.pages, "no unrelated navigation rows remain visible")
        local cards = {}
        for index, data in ipairs(catalog.pages[key].rows) do
            local row = gui.rows[index]
            if row:IsShown() then
                local x, y = row.point[2], -row.point[3]
                equal(x >= 0 and x + row:GetWidth() <= gui.contentWidth, true, "setting tile stays inside content width")
                equal(y + row:GetHeight() <= gui.contentHeight - 36, true, "tile height is included in scrolling")
                equal(-row.help.point[3] >= 16 + row.label:GetHeight() + 6, true, "description clears wrapped title")
                equal(-row.help.point[3] + row.help:GetHeight() <= row:GetHeight() - 16, true, "description clears tile bottom")
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
                if candidate == group and not candidate.utility and #candidate.pages > 1 then for _, leaf in ipairs(candidate.pages) do
                    local tab = gui.tabs[leaf[1]]
                    model.sidebar[#model.sidebar + 1] = { label = leaf[2], x = tab.point[2], y = -tab.point[3], width = tab:GetWidth(),
                        height = tab:GetHeight(), active = leaf[1] == key }
                end end
            end
            for _, section in ipairs(gui.sections) do if section:IsShown() then model.sections[#model.sections + 1] = { y = -section.point[3], label = section.label.text } end end
            if key == "overview" then for _, card in ipairs(gui.homeCards) do model.home[#model.home + 1] = { x = card.point[2], y = -card.point[3], width = card:GetWidth(), height = card:GetHeight(), label = card.label.text, help = card.help.text } end end
            WFS_WORKSPACE_PREVIEW(model)
        end
    end
end
equal(gui.tabs.profiles,gui.groupTabs.profiles,"Profiles uses one standalone navigation button")
gui:Select("overview")
equal(gui.groupTabs.profiles:IsShown(),true,"Profiles remains visible from Home")
gui.groupTabs.profiles.OnClick(gui.groupTabs.profiles)
equal(gui.page,"profiles","standalone Profiles opens the existing profile page")
equal(gui.groupTabs.profiles.point[2],12,"Profiles aligns with other primary sections")
equal(routes, 28, "all existing routes plus Appearance and Combat Indicator remain accessible")
local gear = Suite.GearSettings
gear:Open("picker")
for _, card in ipairs(gear.profileButtons) do
    equal(card.point[2] + card:GetWidth() <= gear.panel:GetWidth(), true, "three-column profiles fit their wider panel")
end
gear:Open("editor")
for _, field in ipairs(gear.fields) do
    equal(field.input.point[2] + field.input:GetWidth() <= gear.panel:GetWidth(), true, "three-column weight fields stay within panel")
    equal(-field.input.point[3] + field.input:GetHeight() < 456, true, "weight fields clear the relocated footer")
end
equal(gear.panel:GetHeight(), 586, "wider weights reduce editor height by 144 units")
gear:Dismiss()
equal(gui.macroCombat.point[2] >= 280, true, "macro checkbox aligns with the wider detail pane")
equal(gui.setupReviewChild:GetWidth(), 750, "setup review text fills its wider viewport")
gui:Select("overview")
equal(gui.scrollFrame.suiteScrollBar:IsShown(), false, "home fits without scrolling")
for _, card in ipairs(gui.homeCards) do card.OnClick();equal(gui.page, card.page, "each home shortcut opens its destination") end
equal(applied, 0, "navigation, layout and home shortcuts never apply optional features")
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
