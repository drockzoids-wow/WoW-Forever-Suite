local _, Suite = ...
local Catalog = { groups = {
    { key = "overview", label = "Home", description = "Browse a section or open a tool. Each feature remains optional.", pages = { { "overview", "Home" } } },
    { key = "inventory", label = "Bags & Gear", description = "Bags, bank, item levels, upgrades and tooltip information.", pages = { { "bags", "Bags & Bank" }, { "items", "Item Levels & Upgrades" }, { "tooltips", "Tooltips" }, { "professions", "Professions" } } },
    { key = "combat", label = "Combat", description = "Buff reminders, damage meters, action buttons and unit frames.", pages = { { "buffs", "Buff Reminders" }, { "meters", "Damage Meters" }, { "actionbars", "Action Bars" }, { "castbars", "Castbars" }, { "unitframes", "Unit Frames" }, { "combat", "Combat Indicator" } } },
    { key = "layout", label = "Maps & Interface", description = "Maps, window movement, progress bars, chat and sound.", pages = { { "minimap", "Minimap" }, { "worldmap", "World Map" }, { "windows", "Window Movement" }, { "bars", "Progress Bars & UI Buttons" }, { "chat", "Chat" }, { "audio", "Audio" } } },
    { key = "journey", label = "Quests & Leveling", description = "Quests, looting, the leveling tracker and camping.", pages = { { "quests", "Quests, Loot & Tracker" }, { "leveling", "Leveling Tracker" }, { "camping", "Camping" } } },
    { key = "everyday", label = "Vendors & Mail", description = "Repairs, junk selling, shops and mail recipients.", pages = { { "vendor", "Vendor" }, { "mail", "Mail" } } },
    { key = "tools", label = "Tools", description = "Characters and inventory, training costs, supplies, talent builds, macros and chat shortcuts.", pages = { { "characters", "Characters & Inventory" }, { "training", "Training Planner" }, { "supplies", "Supply Checklist" }, { "talents", "Talent Builds" }, { "macros", "Macro Builder" }, { "shortcuts", "Chat Shortcuts" } } },
    { key = "suite", label = "Suite Settings", utility = true, description = "What's new, appearance, settings profiles, support and guided setup.", pages = { { "whatsnew", "What's New" }, { "appearance", "Appearance" }, { "profiles", "Profiles" }, { "support", "Support" }, { "setup", "Setup Guide" } } },
} }
Suite.SettingsCatalog = Catalog
Catalog.sections = {
    combat = { [1] = "Combat Indicator", [4] = "Position & Preview" },
    overview = { [1] = "Maps & Layout", [4] = "Gear Details" },
    minimap = { [1] = "Launcher & Addon Buttons", [3] = "Map Appearance", [4] = "Stats & Information" },
    windows = { [1] = "Window Layout" },
    bags = { [1] = "Bag Tools", [3] = "Recorded Inventory", [4] = "Bank Snapshots", [7] = "Low Bag Space", [9] = "Container Opening", [10] = "Bag Order" },
    items = { [1] = "Item Levels", [4] = "Upgrade Comparisons", [8] = "Equipment Manager" },
    tooltips = { [1] = "Item Information", [3] = "Player Information", [5] = "Unit Information" },
    camping = { [1] = "Camping Bar", [3] = "Position & Reset" },
    buffs = { [1] = "Missing Buff Bar", [2] = "Reminder Filters", [6] = "Position & Choices" },
    vendor = { [1] = "Repairs", [3] = "Junk Selling", [6] = "Vendor Conversation", [7] = "Known Items" },
    quests = { [1] = "Quests & Conversation", [4] = "Loot & Tracker" },
    actionbars = { [1] = "Appearance & Feedback", [3] = "Ability Proc Popups" }, bars = { [1] = "Bar Appearance" },
    unitframes = { [1] = "Health Bars", [2] = "Target Threat" }, mail = { [1] = "Recipients", [4] = "Mail Deadlines" }, meters = { [1] = "Damage Meters" },
    audio = { [1] = "Output Device" },
    leveling = { [1] = "Leveling Tracker", [2] = "Header Controls", [4] = "Session & Position" },
    professions = { [1] = "Disenchant", [3] = "Enchanting" },
    training = { [1] = "Training Planner", [3] = "Automatic Opening" },
    talents = { [1] = "Talent Build Planner" },
}
local extras = {
    { page = "buffs", key = "missingBuffRested", label = "Hide in rested areas", help = "Out-of-combat bar only.", view = "visibility", owner = "BuffSettings", target = "rested", words = "inn city resting hide" },
    { page = "buffs", key = "missingBuffCampfire", label = "Hide near a campfire", help = "Out-of-combat bar only.", view = "visibility", owner = "BuffSettings", target = "campfire", words = "camping hide" },
    { page = "buffs", key = "missingBuffScale", label = "Buff bar scale", view = "appearance", owner = "BuffSettings", target = "scale" },
    { page = "buffs", key = "missingBuffIconSize", label = "Buff icon size", view = "appearance", owner = "BuffSettings", target = "size" },
    { page = "buffs", key = "buffPreview", label = "Preview buff bar position", view = "appearance", owner = "BuffSettings", target = "normalPreview" },
    { page = "buffs", key = "buffReset", label = "Reset buff bar position", view = "appearance", owner = "BuffSettings", target = "resetPosition" },
    { page = "appearance", key = "borderColorMode", label = "Border color", target = "borderModeControls.default", words = "appearance theme borders outline default teal class custom color colour" },
    { page = "appearance", key = "customBorderColor", label = "Choose custom border color", target = "borderColorButton", words = "appearance theme wheel swatch picker rgb hex colour" },
    { page = "profiles", key = "settingsProfiles", label = "Settings and layout profiles", target = "profilePanel", words = "default shared personal character overrides copy rename switch setup" },
    { page = "characters", key = "inventoryBrowser", label = "Browse recorded inventory", target = "characterPanel", words = "items owners bags bank shared snapshots dates favorites saved searches" },
    { page = "castbars", key = "castbarSizes", label = "Castbar sizes and preview", target = "castbarPanel", words = "player target focus casting width height resize preview" },
    { page = "professions", key = "disenchantModifier", label = "Disenchant modifier key", words = "alt ctrl shift enchanting profession" },
    { page = "actionbars", key = "shortKeybinds", label = "Short keybind labels", target = "keybindControls.shortKeybinds", words = "bindings shortcuts abbreviations" },
    { page = "actionbars", key = "keybindFontStyle", label = "Custom keybind font", target = "keybindControls.keybindFontStyle" },
    { page = "actionbars", key = "keybindFont", label = "Keybind font", target = "keybindControls.font", words = "typeface text" },
    { page = "actionbars", key = "keybindSize", label = "Keybind text size", target = "keybindSizeSlider", words = "font scale" },
    { page = "actionbars", key = "procAlertIconSize", label = "Proc popup icon size", target = "procSizeSlider", words = "ability skill proc scale larger smaller slider sparkle glow overpower" },
    { page = "actionbars", key = "keybindOutline", label = "Keybind outline", target = "keybindControls.outline" },
    { page = "actionbars", key = "keybindBold", label = "Bold keybind text", target = "keybindControls.keybindBold" },
    { page = "bars", key = "progressBarValues", label = "Always show progress values", target = "progressControls.progressBarValues.button", words = "xp experience honor reputation numbers text" },
    { page = "bars", key = "progressBarSegments", label = "Progress bar lines", target = "progressControls.progressBarSegments.button", words = "xp reputation honor none five ten percent ticks bubbles 5% 10%" },
    { page = "bars", key = "progressBarCustomSize", label = "Custom progress bar size", target = "progressControls.progressBarCustomSize.button" },
    { page = "bars", key = "progressBarWidth", label = "Progress bar width", target = "progressFields.progressBarWidth.input" },
    { page = "bars", key = "progressBarHeight", label = "Progress bar height", target = "progressFields.progressBarHeight.input" },
    { page = "bars", key = "progressReset", label = "Reset progress bar size", target = "progressControls.reset.button" },
    { page = "worldmap", key = "mapRevealOpacity", label = "Unexplored map opacity", target = "mapOpacitySlider", words = "reveal fog transparency terrain" },
    { page = "chat", key = "chatHistory", label = "Remember chat history", target = "chatHistoryToggle", words = "reload login logout conversation saved messages persist" },
    { page = "chat", key = "chatHistoryClear", label = "Clear saved chat history", target = "chatHistoryClear" },
    { page = "chat", key = "chatStyle", label = "Suite chat style", target = "chatApply", words = "enable disable restore copy text messages" },
    { page = "chat", key = "chatFontSize", label = "Chat text size", target = "chatFields.chatFontSize.slider", words = "font" },
    { page = "chat", key = "chatOpacity", label = "Chat background opacity", target = "chatFields.chatOpacity.slider", words = "transparency" },
    { page = "macros", key = "macroUpdates", label = "Keep class spell macros current", target = "macroUpdates", words = "supplies food drink bandage poison coatings after use automatic" },
    { page = "macros", key = "macroCreate", label = "Create or edit macros", target = "macroSave", words = "food health drink mana bandage poison weapon oil stone class hunter misdirection mend feed revive pet druid innervate rebirth mage counterspell polymorph paladin freedom justice priest shield dispel rogue kick blind shaman earth shock chain heal warlock recall drain life warrior heroic strike taunt prowl cat form rejuvenation entangling roots concussive auto shot blink remove lesser curse flash light protection flash heal shackle undead sap vanish healing wave purge fear banish pummel sunder armor leveling pvp healing touch mark wild hibernate hunters mark pet pull raptor strike wing clip arcane intellect missiles frost nova might holy light repentance renew shadow pain psychic scream sinister strike eviscerate gouge lightning bolt shield frost shock corruption drain soul spell lock rend hamstring disarm charge intercept interrupt overpower battle berserker stance shield bash" },
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
    chatShortcuts = "slash commands hotkeys kb quick keybinding edit mode binds macros cal calendar settings addons rl reload",
    autoReplaceEnchant = "profession enchanting enchanter override overwrite replace existing enchant confirmation yes trade",
    inventorySearch = "search items alts characters owners bags bank", itemInventory = "inventory counts alts characters bags bank",
    minimapStats = "performance fps ping latency", showLatency = "ping connection", windowTools = "move drag position resize scale",
    vendorKnownItems = "vendor merchant already known owned collected green highlight recipe pet mount cosmetic",
    autoVendor = "auto talk gossip vendor merchant shop browse goods dialogue skip click",
    autoSellJunk = "vendor sell gray grey trash", playerBuffBorders = "buff aura icon outline border top right player",
    bagSpaceAlert = "trash discard delete destroy gray grey white slots full bags",
    reverseCombinedBags = "reverse combined all in one bag order backpack bottom ammo quiver",
    reverseBagSlots = "reverse sort order direction slots within bag hearthstone bottom right backpack",
    combatIndicator = "combat banner indicator start end entering leaving alert notification",
    procAlerts = "skill ability proc popup reactive overpower revenge riposte mongoose counterattack alert available",
    combatIndicatorPersistent = "combat banner indicator persistent stay visible entire fight",
    combatIndicatorLocked = "combat banner indicator lock unlock click through drag move",
    targetThreat = "target threat indicator aggro percent percentage rectangle translucent blizzard buffs top bottom",
    levelingBar = "xp experience gold per hour net leveling session time next level eta estimate movable vertical tracker top left",
    levelingLock = "lock unlock click through hover tracker", levelingMinimize = "minimize collapse expand header tracker",
    questItemButton = "smart nearby quest objective special item use button keybind",
    upgradePreference = "upgrade comparison prefer higher ilevel item level stats weapon dps hands",
    audioSync = "audio sound windows default playback output device speakers headset headphones sync",
    audioRefresh = "sync audio sound windows playback device refresh",
    trainingPlanner = "class weapon trainer skills spells learn cost budget savings future level snapshot",
    trainingOpen = "class weapon weapons master trainers locations directory faction alliance horde training planner saved costs offerings",
    trainingLevelUp = "class trainer training planner level up available skills reminder",
    trainingSpellbook = "spellbook spell book player spells class training planner automatic popup",
    mailBook = "black book addressbook contacts recipients categories notes friends crafters alts edit add offline",
    buffCustom = "custom learned spell name icon search id group raid party", buffManage = "hidden buffs families show restore intellect spirit priest mage hunter",
    buffAppearance = "scale icon size header movement preview position", missingBuffExpiry = "expiry expiring duration refresh timer",
    missingBuffCombat = "combat shout thorns lightning shield righteous fury reminders",
    missingBuffWeapons = "weapon coating oil stone poison mainhand offhand",
    bagSpaceReset = "blacklist protect trash items", preset = "weights upgrades role spec specialization feral cat bear fury frost automatic class character profile custom", weights = "editable custom stat weights score breakdown tooltip details hit crit haste expertise dodge parry block school spell resistance", scorePreset = "weights upgrades role spec", missingBuffClass = "poison imbue aspect upkeep" }

function Catalog:Configure(pages)
    self.pages, self.pageGroup, self.labels, self.entries = pages, {}, {}, {}
    pages.characters = { title = "Recorded characters", description = "Your characters, possessions and saved banks, together.", rows = {
        { key = "characterDashboard", label = "Record character dashboard", help = "Save level, gold, professions and inventory dates when you play each character.\nTurn recording off without deleting existing records." },
    }, note = "Browse saved records even with recording off. Log into alts and visit banks to refresh them. Unknown locations stay unknown; shared contents count once." }
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
    -- Views retain the original setting keys and row identities; no saved choice is migrated.
    pages.bags.views = { { key = "tools", label = "Bag tools" }, { key = "inventory", label = "Recorded inventory" } }
    for i, row in ipairs(pages.bags.rows) do row.view = i >= 2 and i <= 6 and "inventory" or "tools" end
    pages.items.views = { { key = "levels", label = "Item levels" }, { key = "upgrades", label = "Upgrades" }, { key = "equipment", label = "Equipment sets" } }
    for i, row in ipairs(pages.items.rows) do row.view = i <= 3 and "levels" or i <= 7 and "upgrades" or "equipment" end
    pages.actionbars.views = { { key = "appearance", label = "Appearance" }, { key = "feedback", label = "Range & procs" }, { key = "keybinds", label = "Keybind text" } }
    for i, row in ipairs(pages.actionbars.rows) do row.view = i == 2 and "appearance" or "feedback" end
    pages.buffs.views = { { key = "reminders", label = "Reminders" }, { key = "visibility", label = "Visibility" }, { key = "appearance", label = "Appearance" },
        { key = "choices", label = "Buff choices", secondary = true }, { key = "spells", label = "Custom spells", secondary = true } }
    for i, row in ipairs(pages.buffs.rows) do
        row.view = (i == 9 or i == 10) and "visibility" or (i == 6 or i == 7) and "appearance" or "reminders"
    end
    pages.buffs.rows[1].view = nil
    pages.buffs.rows[6].hidden, pages.buffs.rows[7].hidden = true, true -- Preview and reset are beside the appearance controls.
    pages.buffs.rows[15].hidden = true -- Legacy action remains available to existing callers.
    pages.buffs.rows[#pages.buffs.rows + 1] = { key = "missingBuffSmart", view = "reminders", label = "Class-aware buff targets",
        help = "Match mana buffs to eligible classes, including Hunters and Druids in any form." }
    pages.buffs.description = "Missing buffs for you and your group. Normal reminders are clickable; combat reminders are passive."
    pages.buffs.rows[13].label, pages.buffs.rows[14].label = "Custom learned spells", "Buff choices & hidden reminders"
    pages.buffs.rows[13].reveal = { view = "spells", owner = "BuffSettings", target = "spells" }
    pages.buffs.rows[14].reveal = { view = "choices", owner = "BuffSettings", target = "choices" }
    pages.buffs.rows[13].help = "Choose learned spells to remind you about outside combat."
    pages.buffs.rows[14].help = "Restore hidden families or choose learned alternatives."
    pages.buffs.rows[15].help = "Adjust shared icon size, scale and movement."
    pages.bars.description = "XP and reputation bars, bag buttons, micro menu and player buff borders."
    for _, page in ipairs({ "bags", "items", "actionbars", "buffs" }) do
        self.sections[page] = {}
        pages[page].singleColumn = true
    end
    -- Familiar labels are easier to scan than a different slogan on every destination.
    for _, group in ipairs(self.groups) do
        group.directory = group.key == "overview" and "overview" or "browse_" .. group.key
        if group.key ~= "overview" then pages[group.directory] = { title = group.label, description = group.description, rows = {}, directory = true } end
        self.pageGroup[group.directory], self.labels[group.directory] = group, group.label
        for _, entry in ipairs(group.pages) do
            self.pageGroup[entry[1]], self.labels[entry[1]] = group, entry[2]
            pages[entry[1]].title = entry[2]
        end
    end
    pages.overview.description = "Choose a section on the left or search for a setting above.\nYour existing choices are kept; each tool remains optional."
    pages.overview.rows = {}
    pages.overview.title, pages.overview.directory = "What would you like to change?", true
    pages.overview.description = self.groups[1].description
    pages.overview.note = "Every tool is optional. Your existing settings are kept; changes save automatically."
    local seen = {}
    -- Prefer dedicated pages over duplicated Overview shortcuts when finding a setting.
    local order = {}
    -- Keep inventory's tooltip alias canonical while deriving coverage from the navigation manifest.
    order[1] = "bags"
    for _, group in ipairs(self.groups) do for _, entry in ipairs(group.pages) do if entry[1] ~= "bags" then order[#order + 1] = entry[1] end end end
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
            if not row.passive and not row.hidden then
                local reveal = row.reveal
                Add({ page = page, key = row.key or row.action, label = row.label, help = row.help,
                    row = not reveal and index or nil, view = reveal and reveal.view or row.view,
                    owner = reveal and reveal.owner, target = reveal and reveal.target })
            end
        end
    end
    for _, entry in ipairs(extras) do
        if entry.page == "actionbars" then entry.view = entry.key == "procAlertIconSize" and "feedback" or "keybinds" end
        Add(entry)
    end
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
    local target = entry.owner and Suite[entry.owner] or gui
    for key in (entry.target or ""):gmatch("[^.]+") do
        if target == nil then return end
        target = target[key]
    end
    if target == gui then return end
    local offset, widget = 0, target
    -- Owned detail controls can sit several anchors below the scroll child.
    for _ = 1, 8 do
        if not widget or widget == gui.content or type(widget.GetPoint) ~= "function" then break end
        local ok, point, relative, relativePoint, _, y = pcall(widget.GetPoint, widget, 1)
        -- The small substitute uses the short SetPoint form; native GetPoint always returns five values.
        if Suite.IsReadable(relative) and type(relative) == "number" then y = relativePoint end
        if ok and Suite.IsReadable(point) and point == "TOPLEFT" and Suite.IsReadable(y)
            and type(y) == "number" and y <= 0 and y > -10000 then offset = offset - y end
        widget = type(widget.GetParent) == "function" and widget:GetParent() or nil
    end
    return target, offset
end
