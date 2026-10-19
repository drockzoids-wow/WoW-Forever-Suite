local Suite, equal, Frame, SetCombat = ...
local gui, catalog = Suite.GUI, Suite.SettingsCatalog
local exactEqual = equal
equal = function(actual, expected, label)
    if type(actual) == "number" and type(expected) == "number" then
        exactEqual(math.abs(actual - expected) < 0.00001, true, label)
    else exactEqual(actual, expected, label) end
end
local function ThumbFraction(bar)
    return bar.travel > 0 and bar.thumbTop / bar.travel or 0
end
local function DragTo(bar, fraction)
    local oldCursor = GetCursorPosition
    local y = 1000
    GetCursorPosition = function() return 0, y end
    local scroll = bar:GetParent()
    bar.thumb.OnMouseDown(bar.thumb, "LeftButton")
    local target = fraction * scroll.suiteMaximum
    y = y - (target - scroll.suiteOffset) / scroll.suiteMaximum * bar.travel * bar:GetEffectiveScale()
    bar.OnUpdate()
    bar.thumb.OnMouseUp(bar.thumb, "LeftButton")
    GetCursorPosition = oldCursor
end
local oldDB, oldApply, oldPage, oldShown, oldPending = Suite.db, Suite.Apply, gui.page, gui.frame:IsShown(), Suite.pending
local originalSeen = Suite.db.setupGuide.seen
local changes = 0
Suite.Apply = function() changes = changes + 1 end
Suite.pending = {}
gui.frame:Show()
local function Serialize(value)
    if type(value) ~= "table" then return type(value) .. ":" .. tostring(value) end
    local keys = {}; for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local parts = {}; for _, key in ipairs(keys) do parts[#parts + 1] = tostring(key) .. "=" .. Serialize(value[key]) end
    return "{" .. table.concat(parts, ";") .. "}"
end
local baseline = Serialize(Suite.db)
equal(#catalog.groups, 7, "six workspaces and a setup utility retain all destinations")
local leafCount, seen = 0, {}
for _, group in ipairs(catalog.groups) do
    equal(gui.groupTabs[group.key] ~= nil, true, "each category has a visible sidebar destination")
    for _, leaf in ipairs(group.pages) do
        equal(seen[leaf[1]], nil, "each settings page belongs to exactly one category")
        seen[leaf[1]] = true; leafCount = leafCount + 1
        gui:Select(leaf[1])
        equal(gui.page, leaf[1], "all existing leaf pages remain accessible")
        equal(gui.group, group.key, "direct page navigation also selects the correct category")
        if #group.pages > 1 then
            for _, other in ipairs(group.pages) do equal(gui.tabs[other[1]]:IsShown(), true, "related tabs stay visible") end
        end
        equal(gui.scrollFrame:GetParent(), gui.body, "the viewport sits inside the content area")
        equal(gui.content:GetParent(), gui.scrollFrame, "setting controls belong to the clipped scroll child")
        equal(gui.contentHeight >= gui.viewportHeight, true, "short pages fill the viewport without a negative scroll range")
        local range = gui.scrollFrame.suiteMaximum
        for _, fraction in ipairs({ 0, 0.5, 1 }) do
            gui:ScrollTo(range * fraction)
            equal(gui.scrollFrame.verticalScroll, range * fraction, leaf[1] .. " scroll reaches the requested content position")
            equal(ThumbFraction(gui.scrollFrame.suiteScrollBar), range > 0 and fraction or 0,
                leaf[1] .. " thumb tracks top, middle and bottom across every settings page")
        end
    end
end
equal(leafCount, 25, "existing destinations plus leveling remain present")
equal(gui.scrollFrame.suiteScrollBar ~= nil, true, "the owned viewport uses a Suite scrollbar")
gui:Select("overview")
equal(changes, 0, "browsing every settings page applies no feature change")
-- Entering/leaving the guide keeps its established seen marker; all other saved choices are preserved.
Suite.db.setupGuide.seen = originalSeen
equal(Serialize(Suite.db), baseline, "regrouping and visiting pages preserves the existing preference values")
gui:Select("worldmap"); gui.groupTabs.inventory.OnClick(); gui.groupTabs.layout.OnClick()
equal(gui.page, "worldmap", "switching categories remembers its last visited related tab")
SlashCmdList.WOWFOREVERSUITE("bags")
equal(gui.page, "bags", "the bags shortcut now opens the related bag and inventory controls")
equal(#catalog.pages.windows.rows, 2, "window movement and reset are separated from inventory")
equal(gui.rows[1].label.text, "Sort bags on opening", "bag behavior leads the new bag page")
equal(gui.rows[2].label.text, "Search across characters", "cross-character search remains easy to find")
equal(gui.rows[3].label.text, "Inventory in tooltips", "recorded tooltip counts sit beside inventory search")
equal(gui.rows[4].label.text, "Bank snapshots", "bank recording keeps its independent switch")
equal(gui.rows[7].label.text, "Low bag space alert", "bag space alert has its own switch on the bag page")
equal(gui.rows[8].label.text, "Clear trash blacklist", "bag-space blacklist can be reset from settings")
equal(catalog:Search("discard white")[1].key, "bagSpaceAlert", "settings search finds gray/white discard suggestions")
equal(catalog:Search("clear trash blacklist")[1].key, "bagSpaceReset", "settings search finds the blacklist reset action")
for index, row in ipairs(catalog.pages.bags.rows) do
    equal(gui.rowOffsets[index] + gui.rows[index].height <= gui.contentHeight - 36, true,
        "every bag row is accounted for in the scroll range")
    equal(gui.rows[index].help.height + 29 <= gui.rows[index].height - 5, true,
        "measured helper text fits its row without overlapping the next setting")
end
gui:Select("buffs")
equal(gui.contentHeight > gui.viewportHeight, true, "long buff pages scroll instead of escaping the panel")
gui:ScrollTo(100000)
local maximum = gui.contentHeight - gui.viewportHeight
equal(gui.scrollOffset, maximum, "scrolling clamps to the last reachable setting")
equal(gui.content.verticalScroll, nil, "scroll is applied to the viewport rather than moving row anchors")
equal(gui.scrollFrame.verticalScroll, maximum, "the native scroll widget receives the clamped position")
local bar = gui.scrollFrame.suiteScrollBar
equal(ThumbFraction(bar), 1, "bottom scroll places the native vertical thumb at its bottom endpoint")
equal(bar:IsShown(), true, "overflow pages show the custom scrollbar")
equal(bar.thumb.height > 24, true, "the thumb represents the visible portion rather than a fixed tiny knob")
DragTo(bar, 0)
equal(gui.scrollOffset, 0, "dragging the native vertical slider to its top returns to the first control")
DragTo(bar, 0.5)
equal(gui.scrollOffset, maximum / 2, "the slider and content share one continuous range")
equal(gui.scrollFrame.verticalScroll, maximum / 2, "thumb dragging moves actual viewport content")
bar.OnMouseWheel(bar, -1)
equal(gui.scrollOffset, math.min(maximum, maximum / 2 + 40), "wheel over the scrollbar uses the existing scroll step")
gui:ScrollTo(maximum)
for _, invalid in ipairs({ { secret = true }, math.huge, 0 / 0 }) do
    bar.OnMouseWheel(bar, invalid)
    equal(gui.scrollOffset, maximum, "restricted or invalid wheel values do not move content")
end
gui.scrollFrame.OnScrollRangeChanged(gui.scrollFrame, 0, maximum / 2)
equal(gui.scrollOffset, maximum / 2, "native range changes clamp an obsolete lower offset")
equal(ThumbFraction(bar), 1, "the thumb reaches the bottom of the actual new range")
gui.scrollFrame.OnScrollRangeChanged(gui.scrollFrame, 0, { secret = true })
equal(gui.scrollOffset, maximum / 2, "unreadable native range changes preserve the known position")
gui:Select("buffs"); gui:ScrollTo(maximum)
equal(gui.rowOffsets[8] + gui.rows[8].height - maximum <= gui.viewportHeight, true,
    "the last buff control can be brought fully above the fixed footer")
for _, invalid in ipairs({ { secret = true }, math.huge, 0 / 0 }) do
    gui:ScrollTo(invalid); equal(gui.scrollOffset, maximum, "unreadable scroll inputs leave the layout intact")
end
gui:Select("buffs"); equal(gui.scrollOffset, maximum, "toggling a setting on the same page preserves scroll")
gui:Select("bags"); equal(gui.scrollOffset, 0, "changing pages begins at the top")
gui:Select("windows")
equal(bar:IsShown(), false, "short pages hide the scrollbar entirely")
equal(ThumbFraction(bar), 0, "short pages reset the thumb to the top without recursive scroll callbacks")
gui:Select("bags")

local function Find(key)
    for _, entry in ipairs(catalog.entries) do if entry.key == key then return entry end end
end
local result = catalog:Search("search across characters")
equal(result[1].key, "inventorySearch", "an exact phrase finds the existing account search preference")
equal(result[1].page, "bags", "inventory search routes to the combined bag page")
equal(#catalog:Search("  METER TEXT SIZE  "), 1, "search handles case and surrounding spaces for advanced controls")
equal(catalog:Search("meter text size")[1].key, "meter_fontSize", "meter font controls are included in the index")
equal(catalog:Search("%")[1].key, "targetThreat", "literal percent search finds the setting whose help contains a percentage")
equal(#catalog:Search({ secret = true }), 0, "restricted text cannot become search terms")
equal(#catalog:Search("\n"), 0, "control characters do not reach matching or labels")
equal(#catalog:Search(string.rep("a", 101)), 0, "search length is bounded")
local counts = {}; for _, entry in ipairs(catalog.entries) do counts[entry.key] = (counts[entry.key] or 0) + 1 end
equal(counts.itemTooltipLevels, 1, "duplicated overview/tooltip switches produce one search result")
equal(counts.itemInventory, 1, "inventory aliases cannot duplicate the same toggle in results")
for _, key in ipairs({ "keybindFont", "keybindSize", "progressBarWidth", "progressBarHeight", "mapRevealOpacity",
    "chatFontSize", "chatOpacity", "macroUpdates", "meter_lock", "meter_gap", "setupGuide" }) do
    equal(Find(key) ~= nil, true, "specialized appearance and workflow controls are searchable")
end
local function Query(text)
    gui.searchBox:SetText(text); gui.searchBox.OnTextChanged(gui.searchBox)
end
baseline = Serialize(Suite.db)
Query("meter")
equal(gui.searchPopup:IsShown(), true, "typing opens a settings search dropdown")
equal(#gui.searchResults > 6, true, "broad queries can expose more than one page of results")
gui.searchNext.OnClick(); equal(gui.searchPage, 2, "pagination reaches results beyond the first six")
gui.searchPopup.OnMouseWheel(gui.searchPopup, 1); equal(gui.searchPage, 1, "wheel pages search results")
equal(changes, 0, "typing and paging do not apply feature settings")
Query("cross characters")
equal(gui.searchRows[1].entry.key, "inventorySearch", "synonyms still find cross-character inventory search")
gui.searchRows[1].OnClick()
equal(gui.page, "bags", "a result takes the user to its settings page")
equal(gui.searchPopup:IsShown(), false, "result navigation clears the dropdown")
equal(gui.searchBox:GetText(), "", "result navigation clears the query")
equal(gui.settingHighlight:GetParent(), gui.rows[2], "the selected setting is highlighted without clicking its switch")
equal(Serialize(Suite.db), baseline, "result navigation does not change any preferences")
equal(changes, 0, "highlighting a toggle never invokes its callback")
gui:RevealSetting(Find("meter_lock"))
equal(gui.page, "meters", "an advanced result opens the corresponding custom page")
equal(gui.settingHighlight:GetParent(), gui.meterButtons.lock, "an advanced result highlights its actual control")
equal(gui.scrollOffset > 0, true, "lower controls scroll into view when revealed")
gui:RevealSetting(Find("macroUpdates"))
equal(gui.settingHighlight:GetParent(), gui.macroUpdates, "macro preferences share the same search navigation")
equal(gui.controlsOffset + 393 + gui.macroUpdates:GetHeight() - gui.scrollOffset <= gui.viewportHeight, true, "the last macro control clears the fixed footer after a search jump")
equal(changes, 0, "searching an action or macro preference never executes it")
Query("not a real setting")
equal(gui.searchEmpty:IsShown(), true, "no-match searches explain the empty result")
Query("font"); gui.searchBox.OnEscapePressed()
equal(gui.searchPopup:IsShown(), false, "Escape clears results and query")
equal(gui.frame:IsShown(), true, "search Escape leaves the settings panel available")
Query("font")
gui.searchBox.IsMouseOver = function() return false end
gui.searchPopup.IsMouseOver = function() return true end
gui.frame.OnEvent(gui.frame, "GLOBAL_MOUSE_DOWN")
equal(gui.searchPopup:IsShown(), true, "clicks inside the dropdown keep results usable")
gui.searchPopup.IsMouseOver = function() return { secret = true } end
gui.frame.OnEvent(gui.frame, "GLOBAL_MOUSE_DOWN")
equal(gui.searchPopup:IsShown(), false, "unknown hit testing safely dismisses results")
Query("font"); gui.frame.OnHide()
equal(gui.searchBox:GetText(), "", "closing settings clears search state")
equal(gui.settingHighlight:IsShown(), false, "closing settings removes the highlight")
gui.frame:Show()
SetCombat(true); gui:RevealSetting(Find("inventorySearch"))
equal(type(Suite.pending.settingsReveal), "function", "highlight anchors defer through combat")
equal(gui.settingHighlight:IsShown(), false, "combat does not change highlight parenting or geometry")
gui:Select("windows"); equal(Suite.pending.settingsReveal, nil, "navigation cancels a pending search reveal")
SetCombat(false)
-- Collapse is presentation only; search must still reach ordinary and detailed controls.
local oldCollapsed = gui.collapsedSections
gui.collapsedSections = {}
baseline = Serialize(Suite.db)
gui:Select("minimap")
local expandedHeight, mapOffset = gui.contentHeight, gui.rowOffsets[3]
gui.sections[1].OnClick()
equal(gui.rows[1]:IsShown(), false, "collapsing Launcher hides its first setting")
equal(gui.rows[2]:IsShown(), false, "collapsing Launcher hides all settings before the next heading")
equal(gui.rows[3]:IsShown(), true, "collapsing one section leaves the next section available")
equal(gui.rowOffsets[3] < mapOffset, true, "later settings move up when a section closes")
equal(gui.contentHeight < expandedHeight, true, "hidden settings no longer enlarge the scroll range")
gui.sections[2].OnClick()
gui.sections[1].OnClick()
equal(gui.rows[1]:IsShown(), true, "a closed section can reopen from its heading")
equal(gui.rows[3]:IsShown(), false, "reopening Launcher preserves the independent Map collapse")
gui:Select("bags"); gui.sections[1].OnClick(); gui:Select("minimap")
equal(gui.rows[1]:IsShown(), true, "reused headers keep collapse choices scoped to their page")
equal(gui.rows[3]:IsShown(), false, "page navigation remembers a collapsed section")
gui.frame:Hide(); gui.frame:Show(); gui:Select("minimap")
equal(gui.rows[3]:IsShown(), false, "closing and reopening settings preserves session collapse choices")
gui:ScrollTo(100000); gui.sections[3].OnClick()
equal(gui.rows[8]:IsShown(), false, "collapsing the final section hides its last control")
equal(gui.scrollOffset, 0, "a shortened page clamps an obsolete lower scroll position")
gui:RevealSetting(Find("showFPS"))
equal(gui.rows[5]:IsShown(), true, "search expands a hidden setting's section")
equal(gui.settingHighlight:GetParent(), gui.rows[5], "search highlights the newly visible actual setting")
equal(gui.rows[3]:IsShown(), false, "search leaves unrelated sections collapsed")
gui:Select("meters")
local meterHeight = gui.contentHeight
gui.sections[1].OnClick()
equal(gui.meterPanel:IsShown(), false, "collapsing a section also hides its detailed appearance panel")
equal(gui.contentHeight < meterHeight, true, "hidden detailed controls do not retain empty scroll space")
gui:RevealSetting(Find("meter_lock"))
equal(gui.meterPanel:IsShown(), true, "search expands the section containing detailed meter controls")
equal(gui.settingHighlight:GetParent(), gui.meterButtons.lock, "a revealed detailed control keeps its search outline")
SetCombat(true); gui:RevealSetting(Find("showFPS")); gui.sections[3].OnClick()
equal(Suite.pending.settingsReveal, nil, "collapsing cancels a deferred outline for the now-hidden setting")
SetCombat(false)
equal(changes, 0, "section toggles and automatic search expansion apply no module change")
equal(Serialize(Suite.db), baseline, "section visibility never changes saved feature preferences")
gui.collapsedSections = oldCollapsed
-- Search never applies a setup draft; selecting another destination keeps normal discard behavior.
gui:Select("setup"); Suite.Setup:Stage("quickLoot", not Suite.db.quickLoot)
local draft, currentLoot = Suite.Setup.draft, Suite.db.quickLoot
Query("keybind font"); equal(Suite.Setup.draft, draft, "typing leaves setup choices staged")
gui:RevealSetting(Find("keybindFont"))
equal(Suite.Setup.draft, nil, "search navigation discards the setup draft like ordinary navigation")
equal(Suite.db.quickLoot, currentLoot, "search navigation never applies staged automation")
gui:Select("bags")
if WFS_GUI_PREVIEW then
    gui.collapsedSections = {}
    local function Preview(page, variant)
        gui:Select(page)
        local group = catalog.pageGroup[page]
        local model = { page = page, variant = variant, version = Suite.version, width = gui.frame.width, height = gui.frame.height,
            heading = gui.heading.text, description = gui.description.text, note = gui.note.text,
            group = group.key, headingY = -gui.heading.point[3], viewportHeight = gui.viewportHeight,
            viewportTop = 0, contentHeight = gui.contentHeight, groups = {}, tabs = {}, sections = {}, rows = {} }
        model.viewportTop = #group.pages > 1 and 130 or 88
        for _, category in ipairs(catalog.groups) do
            local button = gui.groupTabs[category.key]
            model.groups[#model.groups + 1] = { key = category.key, label = category.label, y = -button.point[3], height = button.height }
        end
        if #group.pages > 1 then
            for _, leaf in ipairs(group.pages) do
                local button = gui.tabs[leaf[1]]
                model.tabs[#model.tabs + 1] = { label = leaf[2], active = leaf[1] == page, x = button.point[2], width = button.width }
            end
        end
        for _, header in ipairs(gui.sections) do
            if header:IsShown() then model.sections[#model.sections + 1] = {
                label = header.label.text, indicator = header.indicator.text, y = -header.point[3] } end
        end
        for index, data in ipairs(catalog.pages[page].rows) do
            local row = gui.rows[index]
            if row:IsShown() then
                model.rows[#model.rows + 1] = { label = row.label.text, help = row.help.text, height = row.height,
                    y = gui.rowOffsets[index], toggle = data.key ~= nil, on = data.key and Suite.db[data.key] == true or false,
                    value = row.value.text or ">" }
            end
        end
        WFS_GUI_PREVIEW(model)
    end
    for _, page in ipairs({ "windows", "bags", "buffs", "minimap" }) do Preview(page) end
    gui:SetSectionCollapsed("minimap", 1, true); gui:SetSectionCollapsed("minimap", 4, true)
    Preview("minimap", "collapsed")
    gui.collapsedSections = oldCollapsed
end
gui:ClearSearch(); gui:ClearSettingHighlight()
gui:Select("buffs")
local dragBar, cursorBefore = gui.scrollFrame.suiteScrollBar, GetCursorPosition
GetCursorPosition = function() return 0, 1000 end
dragBar.thumb.OnMouseDown(dragBar.thumb, "LeftButton")
equal(dragBar.drag ~= nil, true, "long settings page starts a real thumb gesture")
gui:Select("actionbars")
equal(dragBar.drag, nil, "navigation cancels pointer tracking before relayout")
equal(dragBar.OnUpdate, nil, "page changes leave no gesture worker")
gui:Select("buffs")
dragBar.thumb.OnMouseDown(dragBar.thumb, "LeftButton")
gui.frame.OnHide()
equal(dragBar.OnUpdate, nil, "closing the GUI cancels all scrollbar gestures")
GetCursorPosition = cursorBefore
Suite.db, Suite.Apply, Suite.pending = oldDB, oldApply, oldPending
gui:Select(oldPage or "overview"); gui.frame:SetShown(oldShown)
SetCombat(false)
