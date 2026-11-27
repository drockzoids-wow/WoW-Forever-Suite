local _, Suite = ...
local Review = { page = 1, view = "enabled" }
Review.internal = { minimapDrawerMoved = true } -- Stored layout state, not a user switch.
Suite.FeatureReview = Review
table.insert(Suite.modules, Review)
local function Read(v, kind) return Suite.IsReadable(v) and type(v) == kind end
local function Text(v) return Read(v, "string") and #v > 0 and #v <= 240 and not v:find("[%c|]") end
local function Field(object, key)
    if not Read(object, "table") then return end
    local value = object[key]; if Suite.IsReadable(value) then return value end
end
local function Call(fn, ...)
    if not Read(fn, "function") then return nil, false end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value, true end
    return nil, false
end
local parents = {
    showFPS = "minimapStats", showLatency = "minimapStats", showCoordinates = "minimapStats", showClock = "minimapStats",
    keybindBold = "keybindFontStyle", progressBarValues = "statusBarSkin", progressBarCustomSize = "statusBarSkin", progressBarSegments = "statusBarSkin",
    combatIndicatorPersistent = "combatIndicator", combatIndicatorLocked = "combatIndicator",
    mailRememberRecipient = "mailHelper", trainingAuto = "trainingPlanner", trainingLevelUp = "trainingPlanner", trainingSpellbook = "trainingPlanner",
    professionLevelingHideDone = "professionLeveling", professionLevelingAutoSteps = "professionLeveling", professionLevelingAutoRecipe = "professionLeveling",
    professionLevelingHideStocked = "professionLeveling", professionLevelingMaterialsCollapsed = "professionLeveling", professionLevelingStepsCollapsed = "professionLeveling",
    talentPlannerRules = "talentPlanner", talentPlannerFullBuild = "talentPlanner",
    missingBuffSelf = "missingBuffs", missingBuffOutgoing = "missingBuffs", missingBuffIncoming = "missingBuffs", missingBuffClass = "missingBuffs",
    missingBuffExpiry = "missingBuffs", missingBuffCombat = "missingBuffs", missingBuffWeapons = "missingBuffs", missingBuffSmart = "missingBuffs",
    missingBuffRested = "missingBuffs", missingBuffCampfire = "missingBuffs", meterSnap = "damageMeters", meterLocked = "damageMeters",
}
local fallback = {
    professionLevelingHideDone = { "Hide completed guide steps", "professions" },
    professionLevelingAutoSteps = { "Automatic guide steps", "professions" },
    professionLevelingAutoRecipe = { "Select current leveling recipe", "professions" },
    professionLevelingHideStocked = { "Hide stocked guide materials", "professions" },
    professionLevelingMaterialsCollapsed = { "Collapse guide materials", "professions" },
    professionLevelingStepsCollapsed = { "Collapse guide steps", "professions" },
    meterSnap = { "Snap damage meters", "meters", "meter_snap" }, meterLocked = { "Lock damage meters", "meters", "meter_lock" },
    combatIndicatorLocked = { "Lock combat indicator", "combat" },
}
-- Exact addon folder IDs only. Presence does not reveal which of an addon's options are on.
local families = {
    leatrix = { label = "Leatrix Plus", ids = { "Leatrix_Plus", "Leatrix_Plus_Forever" } },
    evercore = { label = "EverCore", ids = { "EverCore" } },
    elvui = { label = "ElvUI", ids = { "ElvUI" } },
    bags = { label = "Bag addons", ids = { "Bagnon", "Baganator", "BetterBags", "ArkInventory" } },
    alts = { label = "Alt inventory", ids = { "Altoholic" } },
    windows = { label = "Window movement", ids = { "BlizzMove", "MoveAny" } },
    minimap = { label = "Minimap styling", ids = { "SexyMap" } },
    drawer = { label = "Minimap drawers", ids = { "MBB", "HidingBar" } },
    maps = { label = "World map tools", ids = { "Leatrix_Maps", "Mapster" } },
    junk = { label = "Vendor tools", ids = { "Scrap", "Dejunk", "AutoRepair" } },
    loot = { label = "Loot tools", ids = { "SpeedyAutoLoot", "FasterLoot" } },
    chat = { label = "Chat tools", ids = { "Prat-3.0", "Chatter", "Glass", "GlassForever", "BetterForeverChat" } },
    professions = { label = "Profession companions", ids = { "ForeverRecipes", "Forever_Recipes", "TradeSkillMaster" } },
    mail = { label = "Mail helpers", ids = { "Postal" } },
    meters = { label = "Damage meters", ids = { "Details", "Skada", "Recount" } },
    buffs = { label = "Buff helpers", ids = { "PallyPower", "Buffomat", "BuffomatClassic" } },
    bars = { label = "Custom action bars", ids = { "Bartender4", "Dominos" } },
    castbars = { label = "Custom castbars", ids = { "Quartz" } },
    tracker = { label = "Quest trackers", ids = { "Questie" } },
    guides = { label = "Leveling guides", ids = { "ZygorGuidesViewerForever", "ZygorGuidesViewer", "RXPGuides", "Guidelime" } },
}
Review.domains = {
    { label = "Window movement", keys = { "windowTools" }, families = { "windows", "leatrix", "evercore", "elvui" }, help = "Choose one tool to manage a native window's movement and size." },
    { label = "Bag organization", keys = { "sortBagsOnOpen", "reverseCombinedBags", "reverseBagSlots" }, families = { "bags", "leatrix", "evercore" }, help = "Check bag layout and cleanup options in each addon. Suite bag tools work with native bags." },
    { label = "Recorded inventory", keys = { "offlineBank", "inventorySearch", "itemInventory" }, families = { "bags", "alts" }, help = "Choose which inventory and tooltip views you want to see; recording in both is not proof of a conflict." },
    { label = "Minimap appearance", keys = { "squareMinimap", "minimapStats" }, families = { "minimap", "leatrix", "evercore", "elvui" }, help = "Review which addon styles the native minimap and displays coordinates or time." },
    { label = "Minimap button drawer", keys = { "minimapDrawer" }, families = { "drawer", "leatrix", "evercore" }, help = "Use one drawer for the same addon buttons." },
    { label = "World map reveal", keys = { "revealWorldMap" }, families = { "maps" }, help = "Choose which addon adds unexplored terrain to the map." },
    { label = "Vendor automation", keys = { "autoRepair", "autoSellJunk", "autoVendor" }, families = { "junk", "leatrix", "evercore", "elvui" }, help = "Review automatic repairs, junk sales and shop opening so each action has one owner." },
    { label = "Quest conversations", keys = { "autoQuestPickup", "autoQuestTurnIn", "autoGossip" }, families = { "leatrix", "evercore", "guides" }, help = "Review quest automation in your utility or guide addon, if provided. Choose one owner for each automatic action." },
    { label = "Quest tracker", keys = { "questTrackerSkin", "questTrackerRemember" }, families = { "tracker", "elvui", "evercore" }, help = "Check which tracker you use and which addon controls its appearance. Suite adds no quest-location database." },
    { label = "Quick loot", keys = { "quickLoot" }, families = { "loot", "leatrix", "evercore", "elvui" }, help = "Choose one tool for speeding up native automatic looting." },
    { label = "Chat appearance and history", keys = { "chatStyle", "chatHistory" }, families = { "chat", "leatrix", "elvui" }, help = "Review chat styling and saved-history options to avoid duplicate presentation or restored lines." },
    { label = "Profession companion", keys = { "professionLeveling" }, families = { "professions" }, help = "Check panel space and recipe-selection options if you use more than one profession companion." },
    { label = "Mail recipients", keys = { "mailHelper", "mailRememberRecipient" }, families = { "mail", "evercore" }, help = "Choose which recipient helper you want beside Send Mail." },
    { label = "Damage meters", keys = { "damageMeters" }, families = { "meters", "evercore" }, help = "Choose which meter windows to display. Multiple meter addons being installed does not prove a problem." },
    { label = "Buff reminders", keys = { "missingBuffs" }, families = { "buffs", "evercore" }, help = "Review reminder and buff-button choices so you see only the reminders you want." },
    { label = "Action bar presentation", keys = { "actionBarSkin", "shortKeybinds", "keybindFontStyle", "fullButtonRange" }, families = { "bars", "elvui" }, help = "Suite styles native action bars; custom bars may use their own appearance and range settings." },
    { label = "Unit frame colors", keys = { "classHealthBars" }, families = { "elvui" }, help = "Suite colors native unit frames. Custom unit frames have their own settings." },
    { label = "Castbar sizing", keys = { "castbars.player.enabled", "castbars.target.enabled", "castbars.focus.enabled" }, families = { "castbars", "elvui" }, help = "Suite sizes native castbars; check whether you use a custom castbar instead." },
}
function Review:Value(key, draft)
    if not Text(key) then return end
    local value = Field(draft, key)
    if Read(value, "boolean") then return value end
    if key:match("^castbars%.") then
        local unit = key:match("^castbars%.(%w+)%.enabled$")
        local all = Field(Suite.db, "castbars")
        if not Read(all, "table") then return end
        local bar = all[unit]
        if not Suite.IsReadable(bar) then return end
        if bar == nil then return false end
        if not Read(bar, "table") then return end
        local match = bar.match
        if not Suite.IsReadable(match) then return end
        if Read(match, "string") and match ~= unit and ({ player = true, target = true, focus = true })[match] then return true end
        value = bar.enabled
        if not Suite.IsReadable(value) then return end
        if value == nil then return false end
    elseif key:match("^meterWindows%.") then
        local index, option = key:match("^meterWindows%.(%d+)%.(%w+)$"); index = tonumber(index)
        local all = Field(Suite.db, "meterWindows"); if not Read(all, "table") then return end
        local saved = all[index]
        if not Suite.IsReadable(saved) or saved ~= nil and not Read(saved, "table") then return end
        value = saved and saved[option]
        if not Suite.IsReadable(value) then return end
        if value == nil then value = Suite.DamageMeters:Defaults(index)[option] end
    else value = Field(Suite.db, key) end
    if Read(value, "boolean") then return value end
end
function Review:Entry(key)
    if not Text(key) then return end
    local index, option = key:match("^meterWindows%.(%d+)%.(%w+)$")
    if index then return { page = "meters", key = key, label = "Meter " .. index .. (option == "shown" and " visibility" or " options") } end
    local info = fallback[key]
    local targetKey = info and info[3] or key
    for _, entry in ipairs(Suite.SettingsCatalog.entries) do if entry.key == targetKey then return entry end end
    if info then return { key = key, page = info[2], label = info[1], context = Suite.SettingsCatalog.labels[info[2]] } end
end
function Review:Ready(key, draft)
    if not Text(key) then return false end
    local index, option = key:match("^meterWindows%.(%d+)%.(%w+)$")
    local parent = index and (option == "shown" and "damageMeters" or "meterWindows." .. index .. ".shown") or parents[key]
    for _ = 1, 8 do
        if not parent then return true end
        if self:Value(parent, draft) ~= true then return false, parent end
        parent = parent:match("^meterWindows%.") and "damageMeters" or parents[parent]
    end
    return false
end
local function Same(value, other, depth)
    if not Suite.IsReadable(value) or not Suite.IsReadable(other) then return false end
    if type(value) ~= type(other) then return false end
    if type(value) ~= "table" then return value == other end
    if depth > 5 then return false end
    for key, child in pairs(value) do if not Suite.IsReadable(key) or not Same(child, other[key], depth + 1) then return false end end
    for key in pairs(other) do if not Suite.IsReadable(key) or not Suite.IsReadable(value[key]) or value[key] == nil then return false end end
    return true
end
function Review:Scope(key, draft)
    if not Text(key) then return "Scope unavailable" end
    if Read(Field(draft, key), "boolean") then return "Setup draft · not applied" end
    local root = key:match("^[^.]+")
    if Suite.Profiles.excluded[root] then return "Account-wide" end
    local profiles = Suite.Profiles
    local entry = Text(profiles.activeID) and profiles:Find(profiles.activeID)
    local shared = Field(entry, "values")
    if Read(profiles.activePersonal, "boolean") and profiles.activePersonal == true and not Same(Field(Suite.db, root), Field(shared, root), 0) then return "Only this character" end
    local name = Field(entry, "name")
    return "Shared · " .. (Text(name) and name or "current profile")
end
function Review:Features(draft, includeWaiting)
    local rows, counts = {}, { enabled = 0, waiting = 0, unknown = 0 }
    local function Add(key, label, entry)
        local value = self:Value(key, draft)
        if value == nil then counts.unknown = counts.unknown + 1; return end
        if not value then return end
        local ready, parent = self:Ready(key, draft)
        if ready then counts.enabled = counts.enabled + 1 else counts.waiting = counts.waiting + 1 end
        if ready or includeWaiting then
            local dependency = parent and self:Entry(parent)
            rows[#rows + 1] = { key = key, label = label, entry = entry,
                detail = (ready and "On" or "Saved On · requires " .. (dependency and dependency.label or "main feature")) .. " · " .. self:Scope(key, draft),
                context = entry and entry.context or "", ready = ready }
        end
    end
    for key, default in pairs(Suite.defaults) do
        if type(default) == "boolean" and not self.internal[key] then
            local entry = self:Entry(key)
            Add(key, entry and entry.label or key, entry)
        end
    end
    for _, unit in ipairs({ "player", "target", "focus" }) do
        local entry = self:Entry("castbarSizes")
        Add("castbars." .. unit .. ".enabled", unit:sub(1, 1):upper() .. unit:sub(2) .. " castbar sizing", entry)
    end
    for index = 1, 3 do
        for _, option in ipairs({ {"shown", "Show window", "meter_shown"}, {"classColors", "Class colors", "meter_classColors"},
            {"icons", "Class and specialization icons", "meter_icons"}, {"pinSelf", "Keep my row visible", "meter_pinSelf"},
            {"minimized", "Minimize window", "meter_minimized"}, {"clickThrough", "Mouse input off", "meter_clickThrough"} }) do
            local base = self:Entry(option[3])
            local entry = base and Suite.Copy(base) or { page = "meters", context = "Combat / Damage Meters" }
            entry.meterIndex = index
            Add("meterWindows." .. index .. "." .. option[1], "Meter " .. index .. " · " .. option[2], entry)
        end
    end
    table.sort(rows, function(a, b) if a.context ~= b.context then return a.context < b.context end; return a.label < b.label end)
    return rows, counts
end
function Review:Addon(id, guid)
    if not Text(id) then return nil, false, false end
    local api = C_AddOns
    local loaded, loading = false, false
    local fn = Field(api, "IsAddOnLoaded")
    if Read(fn, "function") then
        local ok, first, second = pcall(fn, id)
        if ok then
            loaded = Read(second, "boolean") and second == true
            loading = Read(first, "boolean") and first == true
            if loaded then return "Loaded", true, true end
        end
    end
    local exists, known = Call(Field(api, "DoesAddOnExist"), id)
    if not known or not Read(exists, "boolean") then
        local name, readable = Call(Field(api, "GetAddOnInfo"), id)
        if readable and Text(name) then exists, known = name == id, true end
    end
    if loading then return "Loaded or loading", true, true end
    if exists ~= true then return nil, false, known and exists == false end
    local state = Text(guid) and Call(Field(api, "GetAddOnEnableState"), id, guid) or nil
    if Read(state, "number") and (state == 1 or state == 2) then return "Enabled · not loaded", true, true end
    if state == 0 then return "Installed · disabled", false, true end
    return "Installed · state unknown", true, false
end
function Review:Detected()
    local guid = Call(UnitGUID, "player")
    guid = Text(guid) and guid or nil
    local results, complete = {}, true
    for family, data in pairs(families) do
        local found = {}
        for _, id in ipairs(data.ids) do
            local state, relevant, known = self:Addon(id, guid)
            if not known then complete = false end
            if state and relevant then found[#found + 1] = { id = id, state = state } end
        end
        results[family] = found
    end
    return results, complete
end
function Review:Overlaps(draft)
    local detected, complete = self:Detected()
    local rows = {}
    for _, domain in ipairs(self.domains) do
        local active, matches, seen = {}, {}, {}
        for _, key in ipairs(domain.keys) do
            if self:Value(key, draft) == true and self:Ready(key, draft) then active[#active + 1] = key end
        end
        if #active > 0 then
            for _, family in ipairs(domain.families) do for _, addon in ipairs(detected[family]) do
                if not seen[addon.id] then matches[#matches + 1] = addon.id .. " (" .. addon.state .. ")"; seen[addon.id] = true end
            end end
            if #matches > 0 then rows[#rows + 1] = { label = domain.label, keys = active, detail = table.concat(matches, ", "), help = domain.help } end
        end
    end
    return rows, complete
end
function Review:SetupSummary(draft)
    local rows, complete = self:Overlaps(draft)
    local lines = { "Possible addon overlap · staged choices", "Presence does not prove another addon's matching option is on." }
    for _, row in ipairs(rows) do lines[#lines + 1] = row.label .. ": " .. row.detail .. "\n" .. row.help end
    if #rows == 0 then lines[#lines + 1] = complete and "No matches in the known-addon list. Other overlaps may exist." or "Addon detection is incomplete; review your other addons manually." end
    if not complete and #rows > 0 then lines[#lines + 1] = "Some addon states are unavailable; other overlaps may exist." end
    return table.concat(lines, "\n\n")
end
function Review:Go(entry)
    if InCombatLockdown() or not entry or self.preview then return end
    if entry.meterIndex then Suite.GUI:OpenMeters(entry.meterIndex) else Suite.GUI:OpenPage(entry.page) end
    Suite.GUI:RevealSetting(entry)
    if self.frame then self.frame:Hide() end
end
function Review:Choose(row, owner)
    if InCombatLockdown() or self.preview then return end
    if not row.keys then self:Go(row.entry); return end
    Suite.Menus.CreateContextMenu(owner, function(_, root)
        root:CreateTitle("Review Suite settings")
        for _, key in ipairs(row.keys) do
            local entry = self:Entry(key)
            if entry then root:CreateButton(entry.label, function() self:Go(entry) end) end
        end
    end)
end
function Review:HideTooltip()
    local owner, tip = self.tooltipOwner, GameTooltip
    self.tooltipOwner = nil
    if not owner or not Suite.IsReadable(tip) or (type(tip) ~= "table" and type(tip) ~= "userdata") or not Read(tip.Hide, "function") then return end
    local own = Call(tip.IsOwned, tip, owner)
    if own == nil then own = Call(tip.GetOwner, tip) == owner end
    if own == true then tip:Hide() end
end
function Review:Tooltip(button)
    self:HideTooltip()
    if InCombatLockdown() then return end
    local row, tip = button.featureRow, GameTooltip
    if not row or not Suite.IsReadable(tip) or (type(tip) ~= "table" and type(tip) ~= "userdata") or Call(tip.IsForbidden, tip) ~= false or not Read(tip.SetOwner, "function")
        or not Read(tip.ClearLines, "function") or not Read(tip.AddLine, "function") or not Read(tip.Show, "function") then return end
    local function Owns() return Call(tip.IsOwned, tip, button) == true or Call(tip.GetOwner, tip) == button end
    tip:SetOwner(button, "ANCHOR_RIGHT")
    if not Owns() then return end
    self.tooltipOwner = button; tip:ClearLines()
    local function Add(text, r, g, b)
        if not Owns() then return false end
        tip:AddLine(text, r, g, b, true); return Owns()
    end
    if not Add(row.label, 0.41, 0.84, 0.75) or not Add(row.detail, 0.88, 0.91, 0.93)
        or not Add(row.help or row.context or "", 0.7, 0.77, 0.8) then return end
    if row.keys and not Add("Possible overlap only; matching options may be off.", 0.7, 0.77, 0.8) then return end
    if Owns() then tip:Show() end
end
local function Label(parent, text, x, y, width, size)
    local label = parent:CreateFontString(nil, "OVERLAY"); label:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE")
    label:SetTextColor(0.88, 0.91, 0.93); label:SetPoint("TOPLEFT", x, y); label:SetWidth(width); label:SetJustifyH("LEFT"); label:SetText(text); return label
end
function Review:Refresh()
    if not self.frame or not self.frame:IsShown() then return end
    self:Cancel()
    self:HideTooltip()
    local frame, combat = self.frame, InCombatLockdown()
    for key, button in pairs(frame.tabs) do
        button:SetEnabled(not combat)
        if key == self.view then button.label:SetTextColor(0.41, 0.84, 0.75, combat and 0.4 or 1)
        else button.label:SetTextColor(0.88, 0.91, 0.93, combat and 0.4 or 1) end
    end
    if self.preview and (Suite.Setup.draft ~= self.preview or Suite.GUI.page ~= "setup") then self.preview = nil end
    local all, counts, complete
    if self.view == "overlaps" then all, complete = self:Overlaps(self.preview)
    else all, counts = self:Features(self.preview, self.view == "saved") end
    local query = frame.search:GetText()
    query = Read(query, "string") and #query <= 100 and not query:find("[%c|]") and query:lower() or ""
    self.rows = {}
    for _, row in ipairs(all) do
        local words = (row.label .. " " .. row.detail .. " " .. (row.context or "") .. " " .. (row.help or "")):lower()
        local match = true; for token in query:gmatch("%S+") do if not words:find(token, 1, true) then match = false; break end end
        if match then self.rows[#self.rows + 1] = row end
    end
    self.page = math.max(1, math.min(self.page, math.max(1, math.ceil(#self.rows / 6))))
    for index, button in ipairs(frame.rows) do
        local row = self.rows[index + (self.page - 1) * 6]
        button.featureRow = row
        button:SetShown(row ~= nil); button:SetEnabled(not combat and not self.preview)
        if row then button:SetText(row.label); button.detail:SetText(row.detail); button.help:SetText(row.help or row.context) end
    end
    frame.context:SetText(self.view == "overlaps" and "Possible overlap only. Other addons' matching options may be off.\nChoose who handles each action in its settings. Nothing here changes another addon."
        or "Enabled switches and options, with their settings scope. On does not mean currently visible.\nSaved On options also includes choices waiting for their main feature.")
    frame.status:SetText(self.preview and "Setup preview · no choices applied. Return to setup to adjust these options."
        or combat and "Viewing saved choices · open settings links after combat."
        or self.view == "overlaps" and (complete and "Known-addon matches only; unrecognized addons may overlap too." or "Some addon states are unavailable; review your other addons manually.")
        or (counts.enabled .. " enabled · " .. counts.waiting .. " saved On, waiting · " .. counts.unknown .. " unreadable"))
    if #self.rows == 0 then
        frame.empty:SetText(query ~= "" and "No matching rows." or self.view == "overlaps"
            and (complete and "No possible overlaps found in the known-addon list." or "Addon detection is incomplete; check other addons manually.")
            or "No enabled choices in this view.")
        frame.empty:Show()
    else frame.empty:Hide() end
    frame.previous:SetEnabled(not combat and self.page > 1); frame.next:SetEnabled(not combat and self.page * 6 < #self.rows)
    frame.page:SetText(self.page .. " / " .. math.max(1, math.ceil(#self.rows / 6)))
end
function Review:Toggle(view, owner, draft)
    if not InCombatLockdown() and self.frame and self.frame:IsShown() and self.launchView == view and self.preview == draft then
        self.frame:Hide()
        return
    end
    return self:Open(view, owner, draft)
end
function Review:Open(view, owner, draft)
    if InCombatLockdown() then Suite.Print("Open the feature review outside combat."); return end
    self.view, self.page = view == "overlaps" and "overlaps" or "enabled", 1
    self.launchView = self.view
    self.preview = Read(draft, "table") and draft or nil
    if not self.frame then
        local frame = CreateFrame("Frame", "WoWForeverSuiteFeatureReview", UIParent, "BackdropTemplate"); self.frame = frame
        frame:SetSize(760, 650); frame:SetClampedToScreen(true); frame:SetFrameStrata("DIALOG"); frame:EnableMouse(true)
        frame:SetPoint("CENTER", UIParent, "CENTER")
        frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        frame:SetBackdropColor(0.035, 0.05, 0.065, 1); Suite.Theme:Backdrop(frame, 0.85)
        if UISpecialFrames then table.insert(UISpecialFrames, "WoWForeverSuiteFeatureReview") end
        local header = CreateFrame("Frame", nil, frame); frame.header = header
        header:SetPoint("TOPLEFT"); header:SetSize(710, 34)
        Label(header, "Enabled Features & Addon Overlap", 14, -14, 690, 17)
        Suite.BindWindowDrag(frame, header)
        local close = Suite.Theme:IconButton(frame, "Close feature review", function() frame:Hide() end)
        close:SetSize(24, 24); close:SetPoint("TOPRIGHT", -8, -8)
        local function Button(text, x, y, width, callback)
            local button = Suite.Theme:ActionButton(frame, text, width, 26, function() if not InCombatLockdown() then callback() end end)
            button:SetPoint("TOPLEFT", x, y); return button
        end
        frame.context = Label(frame, "", 14, -46, 730, 11); frame.context:SetHeight(38)
        frame.tabs = {}
        for index, option in ipairs({ { "enabled", "Enabled features" }, { "saved", "Saved On options" }, { "overlaps", "Possible overlap" } }) do
            local viewKey = option[1]
            frame.tabs[viewKey] = Button(option[2], 14 + (index - 1) * 180, -94, 170, function() self.view = viewKey; self.page = 1; self:Refresh() end)
        end
        Label(frame, "Filter by feature, category or addon", 20, -126, 566, 10)
        frame.search = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        frame.search:SetPoint("TOPLEFT", 20, -140); frame.search:SetSize(566, 25); frame.search:SetAutoFocus(false)
        frame.search:SetFont("Fonts\\FRIZQT__.TTF", 12, ""); frame.search:SetMaxLetters(100)
        frame.search:SetScript("OnTextChanged", function() self.page = 1; self:Queue() end)
        frame.search:SetScript("OnEscapePressed", function() frame.search:ClearFocus(); frame:Hide() end)
        Button("Refresh", 614, -140, 130, function() self:Refresh() end)
        frame.rows = {}
        for index = 1, 6 do
            local button = Button("", 14, -184 - (index - 1) * 60, 730, function()
                local row = self.rows[index + (self.page - 1) * 6]; if row then self:Choose(row, frame.rows[index]) end
            end)
            button:SetHeight(56); button.label:ClearAllPoints(); button.label:SetPoint("TOPLEFT", 7, -3); button.label:SetJustifyH("LEFT")
            button.detail = Label(button, "", 7, -21, 714, 10); button.detail:SetHeight(15)
            button.help = Label(button, "", 7, -37, 714, 10); button.help:SetHeight(15)
            button:SetScript("OnEnter", function() self:Tooltip(button) end)
            button:SetScript("OnLeave", function() if self.tooltipOwner == button then self:HideTooltip() end end)
            button:HookScript("OnHide", function() if self.tooltipOwner == button then self:HideTooltip() end end)
            frame.rows[index] = button
        end
        frame.empty = Label(frame, "", 20, -190, 710)
        frame.previous = Button("Previous", 14, -557, 90, function() self.page = self.page - 1; self:Refresh() end)
        frame.next = Button("Next", 112, -557, 90, function() self.page = self.page + 1; self:Refresh() end)
        frame.wheelArea = Suite.Theme:PageWheel(frame, frame.rows, frame.previous, frame.next, frame.next)
        frame.page = Label(frame, "", 218, -563, 90)
        frame.status = Label(frame, "", 14, -605, 730, 11); frame.status:SetHeight(30)
        frame:SetScript("OnShow", function()
            for _, event in ipairs({ "ADDON_LOADED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do frame:RegisterEvent(event) end
        end)
        frame:SetScript("OnEvent", function(_, event) if event == "PLAYER_REGEN_DISABLED" then self:Cancel(); self:Refresh() else self:Queue() end end)
        frame:Hide()
        frame:SetScript("OnHide", function()
            self:Cancel(); self:HideTooltip(); frame:UnregisterAllEvents(); frame.search:ClearFocus(); self.preview = nil
        end)
    end
    self.frame.search:SetText("")
    Suite.PlaceWindow(self.frame, owner); self.frame:Show(); self:Refresh()
end
function Review:Cancel() if self.timer then self.timer:Cancel(); self.timer = nil end end
function Review:Queue()
    if self.timer or not self.frame or not self.frame:IsShown() then return end
    if not C_Timer or not Read(C_Timer.NewTimer, "function") then self:Refresh(); return end
    self.timer = C_Timer.NewTimer(0.1, function() self.timer = nil; self:Refresh() end)
end
function Review:Apply() if self.frame and self.frame:IsShown() then self:Queue() end end
