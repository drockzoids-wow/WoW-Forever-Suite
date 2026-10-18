local _, Suite = ...
local Catalog = { groups = {
    { key = "overview", label = "Overview", pages = { { "overview", "Overview" }, { "characters", "Characters" } } },
    { key = "layout", label = "Maps & Layout", pages = { { "minimap", "Minimap" }, { "worldmap", "World Map" }, { "windows", "Windows" } } },
    { key = "inventory", label = "Bags & Gear", pages = { { "bags", "Bags & Bank" }, { "items", "Gear Details" }, { "tooltips", "Tooltips" }, { "professions", "Professions" } } },
    { key = "combat", label = "Combat & Bars", pages = { { "actionbars", "Action Bars" }, { "bars", "Other Bars" },
        { "unitframes", "Unit Frames" }, { "buffs", "Missing Buffs" }, { "meters", "Meters" }, { "castbars", "Castbars" } } },
    { key = "everyday", label = "Everyday Tools", pages = { { "quests", "Quests & Loot" }, { "vendor", "Vendor" }, { "leveling", "Leveling" }, { "camping", "Camping" }, { "audio", "Audio" } } },
    { key = "social", label = "Mail & Chat", pages = { { "mail", "Mail" }, { "chat", "Chat" } } },
    { key = "macros", label = "Macros", pages = { { "macros", "Macros" } } },
    { key = "setup", label = "Setup Guide", pages = { { "setup", "Setup Guide" } } },
} }
Suite.SettingsCatalog = Catalog
Catalog.sections = {
    overview = { [1] = "Maps & Layout", [4] = "Gear Details" },
    minimap = { [1] = "Launcher & Addon Buttons", [3] = "Map Appearance", [4] = "Stats & Information" },
    windows = { [1] = "Window Layout" },
    bags = { [1] = "Bag Tools", [3] = "Recorded Inventory", [4] = "Bank Snapshots", [7] = "Low Bag Space", [9] = "Container Opening", [10] = "Bag Order" },
    items = { [1] = "Item Levels", [4] = "Upgrade Comparisons" },
    tooltips = { [1] = "Item Information", [3] = "Player Information" },
    camping = { [1] = "Camping Bar", [3] = "Position & Reset" },
    buffs = { [1] = "Missing Buff Bar", [2] = "Reminder Filters", [6] = "Position & Choices" },
    vendor = { [1] = "Repairs", [3] = "Junk Selling" },
    quests = { [1] = "Quests & Conversation", [4] = "Loot & Tracker" },
    actionbars = { [1] = "Appearance & Feedback" }, bars = { [1] = "Bar Appearance" },
    unitframes = { [1] = "Health Bars", [2] = "Target Threat" }, mail = { [1] = "Recipients" }, meters = { [1] = "Damage Meters" },
    audio = { [1] = "Output Device" },
    leveling = { [1] = "Leveling Tracker", [2] = "Header Controls", [4] = "Session & Position" },
    professions = { [1] = "Disenchant", [3] = "Training Planner" },
}
local extras = {
    { page = "castbars", key = "castbarSizes", label = "Castbar sizes and preview", target = "castbarPanel", words = "player target focus casting width height resize preview" },
    { page = "professions", key = "disenchantModifier", label = "Disenchant modifier key", words = "alt ctrl shift enchanting profession" },
    { page = "actionbars", key = "shortKeybinds", label = "Short keybind labels", target = "keybindControls.shortKeybinds", words = "bindings shortcuts abbreviations" },
    { page = "actionbars", key = "keybindFontStyle", label = "Custom keybind font", target = "keybindControls.keybindFontStyle" },
    { page = "actionbars", key = "keybindFont", label = "Keybind font", target = "keybindControls.font", words = "typeface text" },
    { page = "actionbars", key = "keybindSize", label = "Keybind text size", target = "keybindSizeSlider", words = "font scale" },
    { page = "actionbars", key = "keybindOutline", label = "Keybind outline", target = "keybindControls.outline" },
    { page = "actionbars", key = "keybindBold", label = "Bold keybind text", target = "keybindControls.keybindBold" },
    { page = "bars", key = "progressBarValues", label = "Always show progress values", target = "progressControls.progressBarValues.button", words = "xp experience honor reputation numbers text" },
    { page = "bars", key = "progressBarSegments", label = "Progress bar sections", target = "progressControls.progressBarSegments.button", words = "xp ten percent ticks" },
    { page = "bars", key = "progressBarCustomSize", label = "Custom progress bar size", target = "progressControls.progressBarCustomSize.button" },
    { page = "bars", key = "progressBarWidth", label = "Progress bar width", target = "progressFields.progressBarWidth.input" },
    { page = "bars", key = "progressBarHeight", label = "Progress bar height", target = "progressFields.progressBarHeight.input" },
    { page = "bars", key = "progressReset", label = "Reset progress bar size", target = "progressControls.reset.button" },
    { page = "worldmap", key = "mapRevealOpacity", label = "Unexplored map opacity", target = "mapOpacitySlider", words = "reveal fog transparency terrain" },
    { page = "chat", key = "chatStyle", label = "Suite chat style", target = "chatApply", words = "enable disable restore copy text messages" },
    { page = "chat", key = "chatFontSize", label = "Chat text size", target = "chatFields.chatFontSize.slider", words = "font" },
    { page = "chat", key = "chatOpacity", label = "Chat background opacity", target = "chatFields.chatOpacity.slider", words = "transparency" },
    { page = "macros", key = "macroUpdates", label = "Automatic macro updates", target = "macroUpdates", words = "supplies food drink bandage poison coatings" },
    { page = "macros", key = "macroCreate", label = "Create or edit macros", target = "macroSave", words = "food health drink mana bandage poison weapon oil stone class hunter misdirection mend feed revive pet" },
    { page = "setup", key = "setupGuide", label = "Run the setup guide", words = "welcome installer auto loot first login" },
}
for _, item in ipairs({ { "width", "Meter width" }, { "height", "Meter height" }, { "rowHeight", "Meter bar height" },
    { "fontSize", "Meter text size" }, { "opacity", "Meter background opacity" }, { "gap", "Meter gap" } }) do
    extras[#extras + 1] = { page = "meters", key = "meter_" .. item[1], label = item[2], target = "meterFields." .. item[1], words = "damage healing dps hps font size appearance" }
end
for _, item in ipairs({ { "lock", "Lock damage meters" }, { "snap", "Snap damage meters" }, { "numbers", "Meter number format" },
    { "classColors", "Meter class colors" }, { "shown", "Show a meter window" }, { "reset", "Reset meter layout" },
    { "detach", "Detach meter windows" }, { "test", "Preview meters" },
    { "content", "Meter value details" }, { "icons", "Meter class and specialization icons" },
    { "pinSelf", "Keep my meter row visible" }, { "minimized", "Minimize a meter window" },
    { "visibility", "Meter visibility" }, { "clickThrough", "Meter mouse input" } }) do
    extras[#extras + 1] = { page = "meters", key = "meter_" .. item[1], label = item[2], target = "meterButtons." .. item[1], words = "damage healing dps hps" }
end
local synonyms = { characterDashboard = "recorded characters dashboard alts money gold professions levels snapshots dates",
    inventorySearch = "search items alts characters owners bags bank", itemInventory = "inventory counts alts characters bags bank",
    minimapStats = "performance fps ping latency", showLatency = "ping connection", windowTools = "move drag position resize scale",
    autoSellJunk = "vendor sell gray grey trash", playerBuffBorders = "buff aura icon outline border top right player",
    bagSpaceAlert = "trash discard delete destroy gray grey white slots full bags",
    reverseCombinedBags = "reverse combined all in one bag order backpack bottom ammo quiver",
    reverseBagSlots = "reverse sort order direction slots within bag hearthstone bottom right backpack",
    targetThreat = "target threat indicator aggro percent percentage rectangle translucent blizzard buffs top bottom",
    levelingBar = "xp experience gold per hour net leveling session time next level eta estimate movable vertical tracker top left",
    levelingLock = "lock unlock click through hover tracker", levelingMinimize = "minimize collapse expand header tracker",
    questItemButton = "smart nearby quest objective special item use button keybind",
    upgradePreference = "upgrade comparison prefer higher ilevel item level stats weapon dps hands",
    audioSync = "audio sound windows default playback output device speakers headset headphones sync",
    audioRefresh = "sync audio sound windows playback device refresh",
    trainingPlanner = "trainer skills spells learn cost budget savings future level snapshot",
    trainingOpen = "trainer training planner saved costs offerings",
    trainingLevelUp = "trainer training planner level up available skills reminder",
    buffCustom = "custom learned spell id group raid party", missingBuffExpiry = "expiry expiring duration refresh timer",
    missingBuffCombat = "combat shout thorns lightning shield righteous fury reminders",
    missingBuffWeapons = "weapon coating oil stone poison mainhand offhand",
    bagSpaceReset = "blacklist protect trash items", scorePreset = "weights upgrades role", missingBuffClass = "poison imbue aspect upkeep" }

function Catalog:Configure(pages)
    self.pages, self.pageGroup, self.labels, self.entries = pages, {}, {}, {}
    pages.characters = { title = "Recorded characters", description = "Your characters, gold and professions at a glance.", rows = {
        { key = "characterDashboard", label = "Record character dashboard", help = "Save level, gold, professions and inventory dates when you play each character.\nTurn recording off without deleting existing records." },
    }, note = "Log into alts with recording enabled to update them. Gold totals cover recorded characters in this region; unknown values are omitted." }
    local old = pages.windows.rows
    pages.windows.rows = { old[1], old[2] }
    pages.windows.description = "Move supported windows, save their layout and restore it when needed."
    pages.bags = { title = "Bags & bank", description = "Bag tools and recorded inventory, together in one place.", rows = {
        old[6], old[7], pages.tooltips.rows[2], old[3], old[4], old[5],
        { key = "bagSpaceAlert", label = "Low bag space alert", help = "At two free regular bag slots or fewer, offer the cheapest gray or white stack.\nUses vendor value; left-click to confirm discarding, right-click to blacklist." },
        { action = "bagSpaceReset", label = "Clear trash blacklist", help = "Allow blacklisted item types to be suggested again on every character.\nQuest items and items with no vendor sale value are always skipped." },
        { key = "autoOpenContainers", label = "Auto-open bag containers", help = "Open loot containers, including clams, one at a time with a free regular bag slot.\nPauses in combat and at vendors, banks or mail. Uses your normal loot settings." },
        { key = "reverseCombinedBags", label = "Reverse combined bag order", help = "Show equipped bags first and the backpack last in the combined bag.\nKeeps each bag's slot order. Changing this choice waits until combat ends." },
        { key = "reverseBagSlots", label = "Reverse slots within each bag", help = "Display each bag's first slot at its bottom-right end. Items stay in the same bag.\nCombine with reversed bag order to put the backpack's first slot at the bottom right." },
    }, note = "Log into alts and visit their banks to update records. Saved counts can be stale; bank views cannot move items." }
    pages.bags.rows[3].label = "Inventory in tooltips"
    pages.bags.rows[3].help = "Show recorded bag and bank counts in item tooltips.\nUnknown locations are omitted."
    old[3].help = "Record bank contents when you visit a bank.\nBrowse the last saved view from anywhere."
    old[4].help = "Open your saved bank. Browsing cannot move items."
    old[5].help = "Assign a shortcut in Blizzard's Keybindings settings."
    -- Familiar labels are easier to scan than a different slogan on every destination.
    for _, group in ipairs(self.groups) do
        for _, entry in ipairs(group.pages) do
            self.pageGroup[entry[1]], self.labels[entry[1]] = group, entry[2]
            pages[entry[1]].title = entry[2]
        end
    end
    pages.overview.description = "Choose a section on the left or search for a setting above.\nYour existing choices are kept; each tool remains optional."
    local seen = {}
    -- Prefer dedicated pages over duplicated Overview shortcuts when finding a setting.
    local order = { "characters", "bags", "items", "tooltips", "minimap", "worldmap", "windows", "actionbars", "bars", "unitframes",
        "buffs", "meters", "quests", "vendor", "leveling", "camping", "audio", "mail", "chat", "macros" }
    local function Add(entry)
        if seen[entry.key] then return end
        seen[entry.key] = true
        local group = self.pageGroup[entry.page]
        entry.context = group.label .. "  /  " .. self.labels[entry.page]
        entry.words = (entry.label .. " " .. entry.context .. " " .. (entry.help or "") .. " " .. (entry.words or "")
            .. " " .. (synonyms[entry.key] or "")):lower()
        self.entries[#self.entries + 1] = entry
    end
    for _, page in ipairs(order) do
        for index, row in ipairs(pages[page].rows) do
            if not row.passive then Add({ page = page, key = row.key or row.action, label = row.label, help = row.help, row = index }) end
        end
    end
    for _, entry in ipairs(extras) do Add(entry) end
end

function Catalog:Search(query)
    if not Suite.IsReadable(query) or type(query) ~= "string" or #query > 100 or query:find("[%c|]") then return {} end
    query = query:match("^%s*(.-)%s*$"):lower()
    if query == "" then return {} end
    local tokens, results = {}, {}
    for token in query:gmatch("%S+") do tokens[#tokens + 1] = token end
    for _, entry in ipairs(self.entries) do
        local matches = true
        for _, token in ipairs(tokens) do if not entry.words:find(token, 1, true) then matches = false; break end end
        if matches then results[#results + 1] = entry end
    end
    table.sort(results, function(a, b)
        local exactA, exactB = a.label:lower() == query, b.label:lower() == query
        if exactA ~= exactB then return exactA end
        if a.label ~= b.label then return a.label < b.label end
        return a.context < b.context
    end)
    return results
end

function Catalog:SectionFor(page, row)
    local section
    for index = 1, row or #self.pages[page].rows do
        if self.sections[page] and self.sections[page][index] then section = index end
    end
    return section
end

function Catalog:Target(gui, entry)
    if entry.row then return gui.rows[entry.row], gui.rowOffsets and gui.rowOffsets[entry.row] end
    local target = gui
    for key in (entry.target or ""):gmatch("[^.]+") do
        if target == nil then return end
        target = target[key]
    end
    if target == gui then return end
    local offset = gui.controlsOffset or 0
    if target and type(target.GetPoint) == "function" then
        local ok, point, relative, relativePoint, _, y = pcall(target.GetPoint, target, 1)
        -- The small substitute uses the short SetPoint form; native GetPoint always returns five values.
        if Suite.IsReadable(relative) and type(relative) == "number" then y = relativePoint end
        if ok and Suite.IsReadable(point) and point == "TOPLEFT" and Suite.IsReadable(y)
            and type(y) == "number" and y <= 0 and y > -10000 then offset = offset - y end
    end
    return target, offset
end
