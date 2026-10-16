local _, Suite = ...
local Meters = { windows = {}, history = {} }
Suite.DamageMeters = Meters
table.insert(Suite.modules, Meters)

-- Layout and input belong to Suite. Only native widgets receive restricted combat values.
local MIN_WIDTH, MAX_WIDTH, MIN_HEIGHT, MAX_HEIGHT = 240, 1600, 120, 1000
local MAX_ROWS, HEADER = 48, 24
local palette = {
    background = { 0.035, 0.05, 0.065 }, header = { 0.055, 0.075, 0.09 },
    teal = { 0.41, 0.84, 0.75 },
    bar = { 0.20, 0.54, 0.49 }, text = { 0.88, 0.91, 0.93 }, muted = { 0.55, 0.65, 0.7 }, gold = { 1, 0.82, 0 },
    control = { 0.085, 0.125, 0.145 }, hover = { 0.11, 0.22, 0.23 },
}
local metrics = {
    { label = "Damage", key = "DamageDone" }, { label = "DPS", key = "Dps", rate = true },
    { label = "Damage Taken", key = "DamageTaken" },
    { label = "Avoidable Damage Taken", key = "AvoidableDamageTaken" },
    { label = "Enemy Damage Taken", key = "EnemyDamageTaken" },
    { label = "Healing", key = "HealingDone" }, { label = "HPS", key = "Hps", rate = true },
    { label = "Interrupts", key = "Interrupts", count = true },
    { label = "Dispels", key = "Dispels", count = true }, { label = "Deaths", key = "Deaths", count = true },
}
Meters.metrics = metrics
local metricByKey, sides = {}, { LEFT = true, RIGHT = true, TOP = true, BOTTOM = true }
for _, metric in ipairs(metrics) do metricByKey[metric.key] = metric end
local groups = { { label = "Damage", first = 1, last = 5 }, { label = "Healing", first = 6, last = 7 }, { label = "Actions", first = 8, last = 10 } }
-- Invented, static players for layout testing. Never written to client sessions or SavedVariables.
local testPlayers = {
    { name = "Sample Warrior", class = "WARRIOR", damage = 940000, dps = 9800, healing = 760000, hps = 7900 },
    { name = "Sample Mage", class = "MAGE", damage = 820000, dps = 8500, healing = 680000, hps = 7100 },
    { name = "Sample Rogue", class = "ROGUE", damage = 710000, dps = 7400, healing = 570000, hps = 5900 },
    { name = "Sample Priest", class = "PRIEST", damage = 590000, dps = 6100, healing = 490000, hps = 5100 },
    { name = "Sample Druid", class = "DRUID", damage = 470000, dps = 4900, healing = 380000, hps = 4000 },
    { name = "Sample Hunter", class = "HUNTER", damage = 360000, dps = 3800, healing = 290000, hps = 3000 },
    { name = "Sample Shaman", class = "SHAMAN", damage = 260000, dps = 2700, healing = 180000, hps = 1900 },
    { name = "Sample Paladin", class = "PALADIN", damage = 140000, dps = 1500, healing = 90000, hps = 900 },
}

local function Read(value, kind)
    return Suite.IsReadable(value) and type(value) == kind
end
local function Number(value)
    return Read(value, "number") and value == value and value > -math.huge and value < math.huge
end
local function Bound(value, low, high, fallback)
    return Number(value) and math.max(low, math.min(high, value)) or fallback
end
local function Horizontal(side) return side == "LEFT" or side == "RIGHT" end
local function Font(parent, size, color, flags)
    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", size, flags or "")
    text:SetTextColor(unpack(color))
    text:SetJustifyH("LEFT")
    return text
end
local function RowFont(text, size)
    local path = "Fonts\\ARIALN.TTF"
    if NumberFontNormal and NumberFontNormal.GetFont then
        local nativePath = NumberFontNormal:GetFont()
        if Read(nativePath, "string") and nativePath ~= "" then path = nativePath end
    end
    -- Keep normal antialiased outlines even if another addon changes the shared font's flags.
    text:SetFont(path, size, "OUTLINE")
    text:SetTextColor(1, 1, 1)
end
local function BarColor(settings, class)
    if settings.classColors and Read(class, "string") and Read(RAID_CLASS_COLORS, "table") then
        local color = RAID_CLASS_COLORS[class]
        if Read(color, "table") and Number(color.r) and Number(color.g) and Number(color.b) then
            return { color.r, color.g, color.b }
        end
    end
    return palette.bar
end
local function Backdrop(frame, color, opacity)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(color[1], color[2], color[3], opacity or 1)
    frame:SetBackdropBorderColor(0.17, 0.25, 0.29, 0.35)
end
local function Screen()
    local width, height, scale = UIParent:GetWidth(), UIParent:GetHeight(), UIParent:GetEffectiveScale()
    if not Number(width) or not Number(height) or not Number(scale) or width <= 0 or height <= 0 or scale <= 0 then return end
    return width, height, scale
end
local function Cursor()
    local _, _, scale = Screen()
    local x, y = GetCursorPosition()
    if not scale or not Number(x) or not Number(y) then return end
    return x / scale, y / scale
end

function Meters:Defaults(index)
    return { shown = true, metric = index == 1 and "DamageDone" or "HealingDone", session = "Current",
        width = 300, height = 220, rowHeight = 22, fontSize = 14, fontRevision = 1, classColors = false,
        opacity = 0.9, numbers = "full", numberRevision = 1, position = {} }
end

function Meters:IsActive()
    return Suite.db and (Suite.db.damageMeters or self.preview) or false
end

function Meters:IsWindowShown(index)
    return self:IsActive() and (self.preview or Suite.db.meterWindows[index].shown) or false
end

function Meters:TestSession(metric)
    local session = { combatSources = {}, maxAmount = 0, durationSeconds = 96 }
    local healing = metric.key == "HealingDone" or metric.key == "Hps"
    for index, player in ipairs(testPlayers) do
        local total, rate = player.damage, player.dps
        if healing then total, rate = player.healing, player.hps
        elseif metric.count then total, rate = 9 - index, 0 end
        session.combatSources[index] = { name = player.name, classFilename = player.class,
            totalAmount = total, amountPerSecond = rate }
        session.maxAmount = math.max(session.maxAmount, total)
    end
    return session
end

function Meters:ClearPreview()
    self.preview = nil
    for _, window in ipairs(self.windows) do
        if window.testOffset ~= nil then window.offset = window.testOffset end
        window.testOffset = nil
    end
end

function Meters:SetPreview(enabled)
    if not Suite.db then return end
    if enabled and InCombatLockdown() then Suite.Print("Test damage meters outside combat."); return end
    if (self.preview == true) == (enabled == true) then return end
    self:CloseDetails(); self:CloseMenus()
    self:CancelTimer()
    self:CancelDrag()
    self:CancelResize()
    if enabled then
        self.preview = true
        for _, window in ipairs(self.windows) do window.testOffset, window.offset = window.offset, 0 end
    else self:ClearPreview() end
    self:Apply()
    if not self.preview then
        for _, window in ipairs(self.windows) do
            if not self:IsWindowShown(window.index) then window.frame:Hide() end
        end
        if InCombatLockdown() then self:Refresh() end
    end
    self:RefreshSettings()
end

function Meters:Normalize()
    local db = Suite.db
    if not Read(db.meterWindows, "table") then db.meterWindows = {} end
    for index = 1, 2 do
        local saved, defaults = db.meterWindows[index], self:Defaults(index)
        if not Read(saved, "table") then saved = {}; db.meterWindows[index] = saved end
        if not Number(saved.fontRevision) or saved.fontRevision < 1 then
            if Number(saved.fontSize) and saved.fontSize == 11 then saved.fontSize = 14 end
            saved.fontRevision = 1
        end
        if not Number(saved.numberRevision) or saved.numberRevision < 1 then
            saved.numbers, saved.numberRevision = "full", 1
        end
        for key, value in pairs(defaults) do
            if not Suite.IsReadable(saved[key]) or type(saved[key]) ~= type(value) then saved[key] = Suite.Copy(value) end
        end
        if not metricByKey[saved.metric] then saved.metric = defaults.metric end
        if saved.session ~= "Current" and saved.session ~= "Overall" then saved.session = "Current" end
        if saved.numbers ~= "compact" and saved.numbers ~= "full" then saved.numbers = "full" end
        saved.width = Bound(saved.width, MIN_WIDTH, MAX_WIDTH, 300)
        saved.height = Bound(saved.height, MIN_HEIGHT, MAX_HEIGHT, 220)
        saved.rowHeight = Bound(saved.rowHeight, 18, 32, 22)
        saved.fontSize = Bound(saved.fontSize, 9, 16, 14)
        saved.opacity = Bound(saved.opacity, 0.2, 1, 0.9)
        local pos = saved.position
        if not Number(pos.x) or not Number(pos.y) then saved.position = {} end
    end
    db.meterGap = Bound(db.meterGap, 0, 16, 4)
    if not Read(db.meterLocked, "boolean") then db.meterLocked = false end
    local dock = db.meterDock
    if not Read(dock, "table") or not Number(dock.anchor) or (dock.anchor ~= 1 and dock.anchor ~= 2)
        or not Read(dock.side, "string") or not sides[dock.side] then db.meterDock = {} end
end

function Meters:Available()
    if type(C_DamageMeter) ~= "table" or type(C_DamageMeter.IsDamageMeterAvailable) ~= "function"
        or type(C_DamageMeter.GetCombatSessionFromType) ~= "function" or type(C_DamageMeter.GetCombatSessionFromID) ~= "function"
        or type(C_DamageMeter.GetAvailableCombatSessions) ~= "function" or not Enum or not Enum.DamageMeterType
        or not Enum.DamageMeterSessionType then return false, "Damage meters are unavailable on this client." end
    if not Number(Enum.DamageMeterSessionType.Current) or not Number(Enum.DamageMeterSessionType.Overall) then
        return false, "Damage meters are unavailable on this client."
    end
    local available, reason = C_DamageMeter.IsDamageMeterAvailable()
    if not Read(available, "boolean") or not available then
        return false, Read(reason, "string") and reason ~= "" and reason or "Damage meters are unavailable here."
    end
    return true
end

function Meters:ReadHistory()
    self.historyReady = false
    if not self:Available() then return {} end
    local sessions = C_DamageMeter.GetAvailableCombatSessions()
    if not Read(sessions, "table") then return {} end
    self.history, self.historyReady = {}, true
    for _, session in ipairs(sessions) do
        if Read(session, "table") and Number(session.sessionID) then
            local name = session.name
            if not Read(name, "string") or name == "" then name = "Fight " .. session.sessionID end
            local duration = session.durationSeconds
            local label = name
            if Number(duration) and duration >= 0 then
                label = name .. string.format(" [%d:%02d]", math.floor(duration / 60), math.floor(duration % 60))
            end
            self.history[#self.history + 1] = { id = session.sessionID, name = name, label = label }
        end
    end
    return self.history
end

function Meters:FindFight(id)
    if not Number(id) then return end
    for _, fight in ipairs(self.history) do if fight.id == id then return fight end end
end

function Meters:ChooseMetric(index, key)
    if not Read(key, "string") or not metricByKey[key] then return end
    self:CloseDetails(index); self:CloseMenus(index)
    Suite.db.meterWindows[index].metric = key
    local window = self.windows[index]
    if window then window.offset = 0; self:RefreshWindow(window) end
    self:RefreshSettings()
end

function Meters:ChooseSession(index, kind, id)
    local window, settings = self.windows[index], Suite.db.meterWindows[index]
    if not window then return end
    if kind == "History" then
        self:ReadHistory()
        if not self.historyReady or not self:FindFight(id) then return end
        window.fightID = id -- Runtime only; recent session IDs never enter SavedVariables.
        settings.session = "Current"
    elseif kind == "Overall" or kind == "Current" then
        settings.session, window.fightID = kind, nil
    else return end
    self:CloseDetails(index); self:CloseMenus(index)
    window.offset = 0
    self:RefreshWindow(window)
end

function Meters:MetricMenu(window, root)
    if not Enum or not Enum.DamageMeterType then root:CreateTitle("Meter categories are unavailable."); return end
    for _, group in ipairs(groups) do
        local submenu = root:CreateButton(group.label)
        for index = group.first, group.last do
            local metric = metrics[index]
            if Number(Enum.DamageMeterType[metric.key]) then
                submenu:CreateRadio(metric.label, function() return Suite.db.meterWindows[window.index].metric == metric.key end,
                    function() self:ChooseMetric(window.index, metric.key) end)
            end
        end
    end
end

function Meters:SessionMenu(window, root)
    local settings = Suite.db.meterWindows[window.index]
    root:CreateRadio("Overall", function() return not window.fightID and settings.session == "Overall" end,
        function() self:ChooseSession(window.index, "Overall") end)
    local current = root:CreateButton("Current")
    current:CreateRadio("Follow current fight", function() return not window.fightID and settings.session == "Current" end,
        function() self:ChooseSession(window.index, "Current") end)
    current:CreateDivider()
    local history = self.preview and {} or self:ReadHistory()
    if #history == 0 then current:CreateTitle(self.preview and "Test players only; no stored test fights" or "No stored fights") end
    for _, fight in ipairs(history) do
        local fight = fight
        current:CreateRadio(fight.label, function() return window.fightID == fight.id end,
            function() self:ChooseSession(window.index, "History", fight.id) end)
    end
end

function Meters:DescribeMenu(window, root, kind)
    if kind == "metric" then self:MetricMenu(window, root)
    elseif kind == "session" then self:SessionMenu(window, root)
    else
        root:CreateButton("Window " .. window.index .. " settings", function() Suite.GUI:OpenMeters(window.index) end)
        if self.preview then root:CreateButton("Stop test", function() self:SetPreview(false) end) end
        if Suite.db.meterDock.anchor then root:CreateButton("Detach windows", function() self:Detach() end) end
        root:CreateButton("Reset window layout", function() self:Reset(window.index) end)
        if not self.preview then root:CreateButton("Hide this window", function() self:SetOption(window.index, "shown", false) end) end
        root:CreateDivider()
        root:CreateButton(Suite.db.meterLocked and "Unlock both windows" or "Lock both windows",
            function() self:SetLocked(not Suite.db.meterLocked) end)
    end
end

function Meters:ResetData()
    if not self:IsActive() then return end
    self:CloseMenus()
    if self.preview then
        self:CloseDetails()
        for _, window in ipairs(self.windows) do window.offset = 0 end
        self:Refresh()
        return
    end
    if not C_DamageMeter or type(C_DamageMeter.ResetAllCombatSessions) ~= "function" then
        Suite.Print("Resetting combat data is unavailable on this client.")
        return
    end
    local available, reason = self:Available()
    if not available then Suite.Print(reason); return end
    C_DamageMeter.ResetAllCombatSessions()
    self:CloseDetails()
    -- The native service owns all sessions. Reconcile both views immediately, including a synchronous reset event.
    self:CancelTimer()
    self.history, self.historyReady = {}, false
    for _, window in ipairs(self.windows) do window.fightID = nil; window.offset = 0 end
    self:Refresh()
end

local function GroupReadableNumber(text)
    local integer, fraction = text:match("^(%-?%d+)(.*)$")
    if not integer then return text end
    local sign, groups = "", {}
    if integer:sub(1, 1) == "-" then sign, integer = "-", integer:sub(2) end
    while #integer > 3 do
        table.insert(groups, 1, integer:sub(-3)); integer = integer:sub(1, -4)
    end
    table.insert(groups, 1, integer)
    local separator = Read(LARGE_NUMBER_SEPERATOR, "string") and LARGE_NUMBER_SEPERATOR or ","
    return sign .. table.concat(groups, separator) .. fraction
end
local function NumberArgument(value, compact, rate)
    local readable = Suite.IsReadable(value)
    if readable then
        if not Number(value) then return end
        if compact and value >= 1000000 then return "%s", string.format("%.1fm", value / 1000000)
        elseif compact and value >= 1000 then return "%s", string.format("%.1fk", value / 1000) end
        if rate then
            local text = string.format(value % 1 == 0 and "%.0f" or "%.1f", value)
            return "%s", GroupReadableNumber(text)
        end
    end
    if not compact and not rate and type(BreakUpLargeNumbers) == "function" then
        -- The matching native API explicitly accepts secret arguments when tainted.
        local text = BreakUpLargeNumbers(value)
        if not Suite.IsReadable(text) or Read(text, "string") then return "%s", text end
    end
    if readable then
        if not compact then return "%s", GroupReadableNumber(string.format("%.0f", value)) end
        return "%.0f", value
    end
    -- Secret rates retain a decimal through native formatting; no rounding or grouping in Lua.
    return rate and "%.1f" or "%.0f", value
end
local function DisplayNumber(font, value, compact, rate)
    local format, argument = NumberArgument(value, compact, rate)
    if not format then font:SetText(""); return end
    font:SetFormattedText(format .. (rate and "/s" or ""), argument)
end
local function DisplayTotalAndRate(font, total, rate, compact, percentage, ratePrimary)
    local totalFormat, totalArgument = NumberArgument(total, compact, ratePrimary == true)
    if not totalFormat then font:SetText(""); return end
    local rateFormat, rateArgument = NumberArgument(rate, compact, ratePrimary ~= true)
    if not rateFormat then
        if Number(percentage) then font:SetFormattedText(totalFormat .. " %.0f%%", totalArgument, percentage)
        else font:SetFormattedText(totalFormat, totalArgument) end
        return
    end
    -- Format components independently: either amount can be restricted while the other remains readable.
    if Number(percentage) then
        font:SetFormattedText(totalFormat .. " (" .. rateFormat .. ") %.0f%%", totalArgument, rateArgument, percentage)
    else font:SetFormattedText(totalFormat .. " (" .. rateFormat .. ")", totalArgument, rateArgument) end
end
Meters.ui = { palette = palette, text = Font, rowFont = RowFont, backdrop = Backdrop, number = DisplayNumber,
    pair = DisplayTotalAndRate, barColor = BarColor }

function Meters:RefreshWindow(window)
    if not self:IsWindowShown(window.index) then return end
    local settings, metric = Suite.db.meterWindows[window.index], metricByKey[Suite.db.meterWindows[window.index].metric]
    local available, reason, session
    window.metric.label:SetText(metric.label)
    window.metric.fullLabel = metric.label
    local fight = self:FindFight(window.fightID)
    if not self.preview and window.fightID and not fight and self.historyReady then
        self:CloseDetails(window.index)
        window.fightID, settings.session = nil, "Current"
        window.offset = 0
        Suite.Print("The selected fight is no longer stored. Window " .. window.index .. " now follows Current.")
    end
    local sessionLabel = self.preview and "Test data" or fight and fight.name or settings.session
    window.session.label:SetText(settings.session == "Overall" and "O" or "C")
    window.session.fullLabel = self.preview and "Test data · " .. settings.session
        or fight and "Current · " .. sessionLabel or sessionLabel
    window.testLabel:SetShown(self.preview == true)
    for _, dot in ipairs(window.grip.dots) do dot:SetShown(not Suite.db.meterLocked and not self.preview) end
    if self.preview then
        available, session = true, self:TestSession(metric)
    else
        available, reason = self:Available()
        local metricType = available and Enum.DamageMeterType[metric.key]
        if Number(metricType) then
            if window.fightID then session = C_DamageMeter.GetCombatSessionFromID(window.fightID, metricType)
            else session = C_DamageMeter.GetCombatSessionFromType(Enum.DamageMeterSessionType[settings.session], metricType) end
        end
    end
    window.reset:SetEnabled(self.preview or available and type(C_DamageMeter.ResetAllCombatSessions) == "function")
    window.reset.fullLabel = self.preview and "Restart test display" or "Reset all combat data"
    local sources
    if Read(session, "table") then sources = session.combatSources end
    if not Read(sources, "table") then sources = {} end
    local count = #sources
    if not Number(count) then count = 0; sources = {} end
    window.offset = math.max(0, math.min(window.offset or 0, math.max(0, count - window.visibleRows)))
    local maximum = 1
    if Read(session, "table") then maximum = session.maxAmount end
    if Suite.IsReadable(maximum) and (not Number(maximum) or maximum <= 0) then maximum = 1 end
    for rowIndex, row in ipairs(window.rows) do
        local source = sources[rowIndex + window.offset]
        local visible = rowIndex <= window.visibleRows and Read(source, "table")
        row.source, row.sourceIndex = visible and source or nil, visible and rowIndex + window.offset or nil
        row:SetShown(visible)
        if visible then
            row.rank:SetFormattedText("%d.", rowIndex + window.offset)
            local name = source.name
            if Suite.IsReadable(name) then row.name:SetText(Read(name, "string") and name or "Unknown")
            else row.name:SetText(name) end
            local total = source.totalAmount
            if Suite.IsReadable(total) and not Number(total) then total = 0 end
            row.bar:SetMinMaxValues(0, maximum)
            row.bar:SetValue(total)
            local class = source.classFilename
            local color = BarColor(settings, class)
            local atlas
            if Read(class, "string") and Read(CLASS_ICON_TCOORDS, "table") and Read(CLASS_ICON_TCOORDS[class], "table")
                and type(GetClassAtlas) == "function" then
                local result = GetClassAtlas(class)
                if Read(result, "string") and result ~= "" then atlas = result end
            end
            if atlas then row.icon:SetAtlas(atlas); row.icon:Show()
            else row.icon:SetTexture(nil); row.icon:Hide() end
            row.bar:SetStatusBarColor(color[1], color[2], color[3], 0.85)
            if metric.rate then
                DisplayNumber(row.value, source.amountPerSecond, settings.numbers == "compact", true)
            elseif metric.count then
                DisplayNumber(row.value, total, settings.numbers == "compact")
            else
                DisplayTotalAndRate(row.value, total, source.amountPerSecond, settings.numbers == "compact")
            end
        else
            row.icon:SetTexture(nil); row.icon:Hide()
            row.rank:SetText(""); row.name:SetText(""); row.value:SetText("")
            row.bar:SetMinMaxValues(0, 1); row.bar:SetValue(0)
        end
    end
    window.empty:SetText(not available and reason or count == 0 and "Waiting for combat data" or "")
    window.settings.fullLabel = "Window " .. window.index .. " options"
    if count > 0 then
        window.settings.fullLabel = window.settings.fullLabel .. string.format(" · %d–%d of %d players",
            window.offset + 1, math.min(count, window.offset + window.visibleRows), count)
    end
    window.more:SetShown(count > window.offset + window.visibleRows)
    local duration
    if Read(session, "table") then duration = session.durationSeconds end
    if Number(duration) and duration >= 0 then
        window.duration:SetFormattedText("%d:%02d", math.floor(duration / 60), math.floor(duration % 60))
        window.metric.fullLabel = metric.label .. string.format(" · %d:%02d", math.floor(duration / 60), math.floor(duration % 60))
    else window.duration:SetText("") end
end

function Meters:Refresh()
    if not self:IsActive() then return end
    if not self.preview then self:ReadHistory() end
    for _, window in ipairs(self.windows) do self:RefreshWindow(window) end
    self:RefreshDetails()
end

function Meters:Schedule()
    if self.preview or not Suite.db.damageMeters or self.timer or not C_Timer or not C_Timer.NewTimer then return end
    if not Suite.db.meterWindows[1].shown and not Suite.db.meterWindows[2].shown then return end
    self.timer = C_Timer.NewTimer(0.08, function()
        self.timer = nil
        if Suite.db.damageMeters then self:Refresh() end
    end)
end

function Meters:CancelTimer()
    if self.timer then self.timer:Cancel(); self.timer = nil end
end

function Meters:DockVisible()
    local dock = Suite.db.meterDock
    return dock.anchor and self:IsWindowShown(1) and self:IsWindowShown(2) and dock or nil
end

function Meters:Rects(dock)
    local width, height = Screen()
    if not width then return end
    local rects = {}
    for index = 1, 2 do
        local settings = Suite.db.meterWindows[index]
        local position = settings.position
        local x = Number(position.x) and position.x * width or math.max(0, width - (3 - index) * 312 - 12)
        local y = Number(position.y) and position.y * height or 40
        rects[index] = { x = x, y = y, width = math.min(settings.width, width), height = math.min(settings.height, height) }
    end
    if dock then
        local anchor, child = rects[dock.anchor], rects[3 - dock.anchor]
        local gap = Suite.db.meterGap
        if Horizontal(dock.side) then
            child.height = anchor.height
            child.x = dock.side == "LEFT" and anchor.x - child.width - gap or anchor.x + anchor.width + gap
            child.y = anchor.y
        else
            child.width = anchor.width
            child.x = anchor.x
            child.y = dock.side == "BOTTOM" and anchor.y - child.height - gap or anchor.y + anchor.height + gap
        end
        if math.max(anchor.x + anchor.width, child.x + child.width) - math.min(anchor.x, child.x) > width
            or math.max(anchor.y + anchor.height, child.y + child.height) - math.min(anchor.y, child.y) > height then return rects, false end
    end
    return rects, true
end

function Meters:Clamp(rects, grouped)
    local width, height = Screen()
    if not width then return false end
    if grouped then
        local left, bottom = math.min(rects[1].x, rects[2].x), math.min(rects[1].y, rects[2].y)
        local right = math.max(rects[1].x + rects[1].width, rects[2].x + rects[2].width)
        local top = math.max(rects[1].y + rects[1].height, rects[2].y + rects[2].height)
        if right - left > width or top - bottom > height then return false end
        local dx = left < 0 and -left or right > width and width - right or 0
        local dy = bottom < 0 and -bottom or top > height and height - top or 0
        for _, rect in ipairs(rects) do rect.x, rect.y = rect.x + dx, rect.y + dy end
    else
        for _, rect in ipairs(rects) do
            rect.x = math.max(0, math.min(width - rect.width, rect.x))
            rect.y = math.max(0, math.min(height - rect.height, rect.y))
        end
    end
    return true
end

function Meters:Position(rects)
    if InCombatLockdown() then return end
    for index, rect in ipairs(rects) do
        local frame = self.windows[index].frame
        frame:ClearAllPoints()
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", rect.x, rect.y)
    end
    self.rects = rects
end

function Meters:SavePositions(rects)
    local width, height = Screen()
    if not width or not Read(rects, "table") then return end
    for index, rect in ipairs(rects) do Suite.db.meterWindows[index].position = { x = rect.x / width, y = rect.y / height } end
end

function Meters:Layout(rects)
    if InCombatLockdown() or #self.windows < 2 then return end
    local dock = self:DockVisible()
    local fits = true
    if not rects then rects, fits = self:Rects(dock) end
    if not rects then return end
    if not fits then
        Suite.db.meterDock = {}; dock = nil
        rects = self:Rects(nil)
    end
    self:Clamp(rects, dock ~= nil)
    for index, window in ipairs(self.windows) do
        local settings, rect = Suite.db.meterWindows[index], rects[index]
        window.frame:SetSize(rect.width, rect.height)
        Backdrop(window.frame, palette.background, settings.opacity)
        -- Only the left arrow opens the picker; the passive title belongs to the draggable header.
        local titleWidth = math.min(190, math.max(50, rect.width - 196))
        window.metric:SetWidth(HEADER - 2)
        window.session:SetWidth(24)
        window.title:SetWidth(titleWidth)
        window.duration:Show()
        window.visibleRows = math.min(MAX_ROWS, math.max(1, math.floor((rect.height - HEADER - 4) / settings.rowHeight)))
        -- Native font-string anchors fit the values and give names the remaining space.
        -- Input/frame geometry stays independent of text, including secret-bearing text.
        local barWidth = rect.width - 8 - settings.rowHeight
        for rowIndex, row in ipairs(window.rows) do
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", window.frame, "TOPLEFT", 2, -HEADER - 1 - (rowIndex - 1) * settings.rowHeight)
            row:SetSize(rect.width - 4, settings.rowHeight)
            row.icon:SetSize(settings.rowHeight, settings.rowHeight)
            row.bar:ClearAllPoints(); row.bar:SetPoint("TOPLEFT", row, "TOPLEFT", settings.rowHeight, -1)
            row.bar:SetSize(barWidth, settings.rowHeight - 2)
            RowFont(row.rank, settings.fontSize); RowFont(row.name, settings.fontSize); RowFont(row.value, settings.fontSize)
        end
    end
    self:Position(rects)
    -- Both windows receive their final geometry before any show handler runs.
    for index, window in ipairs(self.windows) do window.frame:SetShown(self:IsWindowShown(index)) end
    self:PositionDetails(self.details and self.details.selection and self.details.selection.windowIndex or 1)
    if not self.resizing then self:SavePositions(rects) end
end

function Meters:SnapCandidate(index, rects)
    if Suite.db.meterLocked or not Suite.db.meterSnap or not self:IsWindowShown(3 - index) then return end
    local width, height = Screen()
    if not width then return end
    local moving, target, gap = rects[index], rects[3 - index], Suite.db.meterGap
    local candidates = {
        { side = "LEFT", distance = math.abs(moving.x + moving.width + gap - target.x), alignment = math.abs(moving.y + moving.height - target.y - target.height) },
        { side = "RIGHT", distance = math.abs(moving.x - target.x - target.width - gap), alignment = math.abs(moving.y + moving.height - target.y - target.height) },
        { side = "BOTTOM", distance = math.abs(moving.y + moving.height + gap - target.y), alignment = math.abs(moving.x - target.x) },
        { side = "TOP", distance = math.abs(moving.y - target.y - target.height - gap), alignment = math.abs(moving.x - target.x) },
    }
    local best
    for _, candidate in ipairs(candidates) do
        local fits = Horizontal(candidate.side) and moving.width + target.width + gap <= width and target.height <= height
            or not Horizontal(candidate.side) and moving.height + target.height + gap <= height and target.width <= width
        if candidate.distance <= 12 and candidate.alignment <= 48 and fits
            and (not best or candidate.distance + candidate.alignment * 0.1 < best.distance + best.alignment * 0.1) then best = candidate end
    end
    return best and { anchor = 3 - index, side = best.side } or nil
end

function Meters:StartDrag(index)
    if InCombatLockdown() or Suite.db.meterLocked or not self:IsActive() or not self.rects then return end
    self:CloseMenus()
    self:CancelResize()
    local x, y = Cursor()
    if not x then return end
    local detached = IsAltKeyDown and IsAltKeyDown()
    local header = self.windows[index].header
    if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(header) then GameTooltip:Hide() end
    self.drag = { index = index, x = x, y = y, start = Suite.Copy(self.rects), detached = detached,
        grouped = not detached and self:DockVisible() ~= nil }
    self.windows[index].header:SetScript("OnUpdate", function() self:DragUpdate() end)
end

function Meters:DragUpdate()
    local drag = self.drag
    if not drag then return end
    if InCombatLockdown() then self:CancelDrag(); return end
    local x, y = Cursor()
    if not x then return end
    local rects = Suite.Copy(drag.start)
    for index, rect in ipairs(rects) do
        if drag.grouped or index == drag.index then rect.x, rect.y = rect.x + x - drag.x, rect.y + y - drag.y end
    end
    self:Clamp(rects, drag.grouped)
    self:Position(rects)
    drag.candidate = not drag.grouped and not drag.detached and self:SnapCandidate(drag.index, rects) or nil
    self.windows[drag.index].frame:SetBackdropBorderColor(unpack(drag.candidate and palette.teal or { 0.17, 0.25, 0.29 }))
end

function Meters:EndDrag()
    local drag = self.drag
    if not drag then return end
    if InCombatLockdown() then self:CancelDrag(); return end
    self:DragUpdate()
    self.windows[drag.index].header:SetScript("OnUpdate", nil)
    self.drag = nil
    if drag.detached then Suite.db.meterDock = {}
    elseif drag.candidate then
        local target = Suite.db.meterWindows[drag.candidate.anchor]
        local moving = Suite.db.meterWindows[drag.index]
        if Horizontal(drag.candidate.side) then moving.height = target.height else moving.width = target.width end
        Suite.db.meterDock = drag.candidate
    end
    self:SavePositions(self.rects)
    self:Layout()
    self:Refresh()
    self:RefreshSettings()
end

function Meters:CancelDrag()
    if not self.drag then return end
    local index = self.drag.index
    self.windows[index].header:SetScript("OnUpdate", nil)
    self.drag = nil
    Suite.AfterCombat("meterLayout", function() self:Layout() end)
end

function Meters:Resize(index, direction)
    if InCombatLockdown() or Suite.db.meterLocked or not self:IsActive() then return end
    self:CancelDrag()
    self:CancelResize()
    local header = self.windows[index] and self.windows[index].header
    if header and GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(header) then GameTooltip:Hide() end
    local settings = Suite.db.meterWindows[index]
    local factor = direction > 0 and 1.05 or 1 / 1.05
    settings.width = Bound(settings.width * factor, MIN_WIDTH, MAX_WIDTH, 300)
    settings.height = Bound(settings.height * factor, MIN_HEIGHT, MAX_HEIGHT, 220)
    local dock = self:DockVisible()
    if dock then
        local partner = Suite.db.meterWindows[3 - index]
        if Horizontal(dock.side) then partner.height = settings.height else partner.width = settings.width end
    end
    self:Layout(); self:Refresh(); self:RefreshSettings()
end

function Meters:StartResize(index, corner)
    if InCombatLockdown() or Suite.db.meterLocked or not self:IsActive() or not self.rects or (corner ~= "LEFT" and corner ~= "RIGHT") then return end
    self:CloseMenus()
    self:CancelDrag(); self:CancelResize()
    local x, y = Cursor()
    if not x then return end
    local handle = self.windows[index].corners[corner]
    if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(handle) then GameTooltip:Hide() end
    self.resizing = { index = index, corner = corner, handle = handle, x = x, y = y,
        start = Suite.Copy(self.rects), dock = Suite.Copy(self:DockVisible() or {}) }
    handle:SetScript("OnUpdate", function() self:ResizeUpdate() end)
end

function Meters:ResizeUpdate()
    local gesture = self.resizing
    if not gesture then return end
    if InCombatLockdown() then self:CancelResize(); return end
    local x, y = Cursor()
    local screenWidth, screenHeight = Screen()
    if not x or not screenWidth then return end
    local rects = Suite.Copy(gesture.start)
    local moving, partner = rects[gesture.index], rects[3 - gesture.index]
    local dock, gap = gesture.dock, Suite.db.meterGap
    local maxWidth, maxHeight = math.min(MAX_WIDTH, screenWidth), math.min(MAX_HEIGHT, screenHeight)
    if dock.anchor then
        if Horizontal(dock.side) then maxWidth = math.min(maxWidth, screenWidth - partner.width - gap)
        else maxHeight = math.min(maxHeight, screenHeight - partner.height - gap) end
    end
    if maxWidth < MIN_WIDTH or maxHeight < MIN_HEIGHT then return end
    local oldRight, oldTop = moving.x + moving.width, moving.y + moving.height
    local delta = x - gesture.x
    if gesture.corner == "LEFT" then delta = -delta end
    moving.width = Bound(moving.width + delta, MIN_WIDTH, maxWidth, moving.width)
    moving.height = Bound(moving.height - (y - gesture.y), MIN_HEIGHT, maxHeight, moving.height)
    if gesture.corner == "LEFT" then moving.x = oldRight - moving.width end
    moving.y = oldTop - moving.height
    if dock.anchor then
        -- Position the other member from the corner's fixed opposite point, independent of which member is the root.
        if Horizontal(dock.side) then partner.height = moving.height else partner.width = moving.width end
        local anchor, child = rects[dock.anchor], rects[3 - dock.anchor]
        if gesture.index == dock.anchor then
            if Horizontal(dock.side) then
                child.x = dock.side == "LEFT" and anchor.x - child.width - gap or anchor.x + anchor.width + gap
                child.y = anchor.y
            else
                child.x = anchor.x
                child.y = dock.side == "BOTTOM" and anchor.y - child.height - gap or anchor.y + anchor.height + gap
            end
        elseif Horizontal(dock.side) then
            anchor.x = dock.side == "LEFT" and child.x + child.width + gap or child.x - anchor.width - gap
            anchor.y = child.y
        else
            anchor.x = child.x
            anchor.y = dock.side == "BOTTOM" and child.y + child.height + gap or child.y - anchor.height - gap
        end
    end
    if not self:Clamp(rects, dock.anchor ~= nil) then return end
    local current = self.rects[gesture.index]
    if current.x == moving.x and current.y == moving.y and current.width == moving.width and current.height == moving.height then return end
    local firstRows, secondRows = self.windows[1].visibleRows, self.windows[2].visibleRows
    self:Layout(rects)
    if firstRows ~= self.windows[1].visibleRows then self:RefreshWindow(self.windows[1]) end
    if secondRows ~= self.windows[2].visibleRows then self:RefreshWindow(self.windows[2]) end
end

function Meters:EndResize()
    local gesture = self.resizing
    if not gesture then return end
    if InCombatLockdown() then self:CancelResize(); return end
    self:ResizeUpdate()
    gesture.handle:SetScript("OnUpdate", nil)
    self.resizing = nil
    local rect, settings = self.rects[gesture.index], Suite.db.meterWindows[gesture.index]
    settings.width, settings.height = rect.width, rect.height
    if gesture.dock.anchor then
        local partner = Suite.db.meterWindows[3 - gesture.index]
        if Horizontal(gesture.dock.side) then partner.height = rect.height else partner.width = rect.width end
    end
    self:SavePositions(self.rects)
    self:Layout(); self:Refresh(); self:RefreshSettings()
end

function Meters:CancelResize()
    if not self.resizing then return end
    self.resizing.handle:SetScript("OnUpdate", nil)
    self.resizing = nil
    Suite.AfterCombat("meterLayout", function() self:Layout(); self:Refresh() end)
end

function Meters:RefreshSettings()
    if Suite.GUI and Suite.GUI.RefreshMeters then Suite.GUI:RefreshMeters() end
end

function Meters:RefreshLock()
    local locked = Suite.db.meterLocked
    for _, window in ipairs(self.windows) do
        -- A passive TEST label remains visible when locking a sample display.
        window.grip:SetShown(not locked or self.preview == true)
        for _, dot in ipairs(window.grip.dots) do dot:SetShown(not locked and not self.preview) end
        window.lock.fullLabel = locked and "Unlock both windows" or "Lock both windows"
        window.lock.shackleRight:SetShown(locked)
        for _, part in ipairs(window.lock.icon) do part:SetColorTexture(unpack(locked and palette.teal or palette.muted)) end
        for _, corner in pairs(window.corners) do
            corner:SetShown(not locked)
            if locked and GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(corner) then GameTooltip:Hide() end
        end
        if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(window.lock) then GameTooltip:Hide() end
        if locked and GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(window.header) then GameTooltip:Hide() end
    end
end

function Meters:SetLocked(locked)
    if not Read(locked, "boolean") or not Suite.db then return end
    -- Discard unfinished movement/sizing before hiding their input handles.
    self:CancelDrag(); self:CancelResize()
    Suite.db.meterLocked = locked
    self:RefreshLock(); self:RefreshSettings()
end

function Meters:SetOption(index, key, value)
    self:Normalize()
    local settings = Suite.db.meterWindows[index]
    if not settings then return end
    local allowed = { shown = "boolean", classColors = "boolean", width = "number", height = "number",
        rowHeight = "number", fontSize = "number", opacity = "number", numbers = "string" }
    if not allowed[key] or not Read(value, allowed[key]) then return end
    if key == "width" or key == "height" then
        local dock = self:DockVisible()
        if dock and ((Horizontal(dock.side) and key == "height") or (not Horizontal(dock.side) and key == "width")) then
            Suite.db.meterWindows[3 - index][key] = value
        end
    end
    settings[key] = value
    self:Apply(); self:RefreshSettings()
end

function Meters:Detach()
    self:CancelDrag()
    self:CancelResize()
    if self.rects and not InCombatLockdown() then self:SavePositions(self.rects) end
    Suite.db.meterDock = {}
    self:Apply(); self:RefreshSettings()
end

function Meters:Reset(index)
    self:CancelDrag()
    self:CancelResize()
    local defaults, settings = self:Defaults(index), Suite.db.meterWindows[index]
    settings.width, settings.height, settings.position = defaults.width, defaults.height, {}
    Suite.db.meterDock = {}
    self:Apply(); self:RefreshSettings()
end

function Meters:CreateWindow(index)
    local window = { index = index, rows = {}, offset = 0 }
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    window.frame, frame.foreverMeter = frame, true
    frame:SetFrameStrata("MEDIUM")
    frame:EnableMouse(true); frame:EnableMouseWheel(true)
    Backdrop(frame, palette.background, 0.9)
    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    window.header = header
    header:SetPoint("TOPLEFT", 1, -1); header:SetPoint("TOPRIGHT", -1, -1); header:SetHeight(HEADER - 1)
    header:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" }); header:SetBackdropColor(unpack(palette.header))
    header:EnableMouse(true); header:EnableMouseWheel(true); header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() self:StartDrag(index) end)
    header:SetScript("OnDragStop", function() self:EndDrag() end)
    header:SetScript("OnMouseWheel", function(_, direction) if IsControlKeyDown() then self:Resize(index, direction) end end)
    local function ResetClick(_, button)
        if not Suite.db.meterLocked and button == "RightButton" and IsControlKeyDown() then self:Reset(index) end
    end
    header:SetScript("OnMouseUp", ResetClick); frame:SetScript("OnMouseUp", ResetClick)
    header:SetScript("OnEnter", function()
        if Suite.db.meterLocked then return end
        for _, dot in ipairs(window.grip.dots) do dot:SetColorTexture(unpack(palette.teal)) end
        if GameTooltip and GameTooltip.SetOwner then
            GameTooltip:SetOwner(header, "ANCHOR_CURSOR")
            GameTooltip:AddLine("Forever Suite · Window " .. index)
            GameTooltip:AddLine(InCombatLockdown() and "Move and resize after combat." or "Drag the header gap to move.", 0.88, 0.91, 0.93)
            GameTooltip:AddLine("Drag either lower corner to resize, or Ctrl+scroll here.", 0.88, 0.91, 0.93)
            GameTooltip:AddLine("Alt+drag to detach. Ctrl+right-click to reset.", 0.55, 0.65, 0.7)
            GameTooltip:Show()
        end
    end)
    header:SetScript("OnLeave", function()
        for _, dot in ipairs(window.grip.dots) do dot:SetColorTexture(unpack(palette.muted)) end
        if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(header) then GameTooltip:Hide() end
    end)
    local function Button(kind, text)
        local button = CreateFrame("Button", nil, header, "BackdropTemplate")
        button:SetHeight(kind == "metric" and HEADER - 2 or HEADER - 4)
        button:EnableMouse(true); button:RegisterForClicks("LeftButtonUp")
        button:SetFrameLevel(header:GetFrameLevel() + 1)
        button.label = Font(button, 11, palette.teal)
        local selector = kind == "metric" or kind == "session"
        button.label:SetPoint("LEFT", 4, 0)
        button.label:SetPoint("RIGHT", kind == "session" and -11 or selector and -14 or -4, 0)
        button.label:SetWordWrap(false); button.label:SetText(text)
        if selector then
            if kind == "metric" then
                button.arrow = button:CreateTexture(nil, "ARTWORK")
                button.arrow:SetSize(10, 6); button.arrow:SetPoint("CENTER", 0, -1)
                -- Collapse the lower vertices of a plain color quad into a downward triangle.
                -- These offsets are static, configured only when constructing outside combat.
                if type(button.arrow.SetVertexOffset) == "function" then
                    button.arrow:SetVertexOffset(2, 5, 0); button.arrow:SetVertexOffset(4, -5, 0)
                else
                    button.arrow:Hide()
                    button.arrow = Font(button, 10, palette.teal)
                    button.arrow:SetPoint("CENTER", 0, -1); button.arrow:SetText("v")
                end
            else
                button.arrow = Font(button, 9, palette.teal)
                button.arrow:SetPoint("RIGHT", -4, 0); button.arrow:SetText("v")
            end
        end
        local function StyleButton()
            if kind == "metric" then
                local active = button.pressed or button.menuOpen
                local highlighted = active or button.hovered
                Backdrop(button, palette.background, 0.95)
                button:SetBackdropColor(active and 0.10 or highlighted and 0.07 or 0.035,
                    active and 0.23 or highlighted and 0.15 or 0.065,
                    active and 0.21 or highlighted and 0.15 or 0.08, 0.95)
                button:SetBackdropBorderColor(0.41, 0.84, 0.75, highlighted and 1 or 0.45)
                if type(button.arrow.SetVertexOffset) == "function" then
                    button.arrow:SetColorTexture(0.41, 0.84, 0.75, button.pressed and 0.75 or 1)
                end
            else
                Backdrop(button, button.pressed and palette.header or button.hovered and palette.hover or palette.control,
                    (button.pressed or button.hovered) and 1 or 0.35)
                if button.pressed or button.hovered then button:SetBackdropBorderColor(unpack(palette.teal)) end
            end
        end
        if kind == "metric" then
            button.SetMenuOpen = function(_, open) button.menuOpen = open; StyleButton() end
        end
        StyleButton()
        button:SetScript("OnClick", function()
            if kind == "lock" then self:SetLocked(not Suite.db.meterLocked)
            elseif kind == "reset" then self:ResetData()
            else self:OpenMenu(window, button, kind) end
        end)
        button:SetScript("OnMouseDown", function(_, mouseButton)
            if mouseButton == "LeftButton" then button.pressed = true; StyleButton() end
        end)
        button:SetScript("OnMouseUp", function() button.pressed = nil; StyleButton() end)
        button:SetScript("OnHide", function() button.hovered, button.pressed = nil, nil; StyleButton() end)
        button:SetScript("OnEnter", function()
            button.hovered = true; StyleButton()
            for _, part in ipairs(button.icon or {}) do part:SetColorTexture(unpack(palette.teal)) end
            if GameTooltip and GameTooltip.SetOwner then
                GameTooltip:SetOwner(button, "ANCHOR_CURSOR"); GameTooltip:AddLine(button.fullLabel or text)
                if kind == "reset" and not self.preview then
                    GameTooltip:AddLine("Clears Overall, Current, and stored fights.", 0.88, 0.91, 0.93)
                    GameTooltip:AddLine("Affects both windows and the built-in meters.", 0.55, 0.65, 0.7)
                end
                GameTooltip:Show()
            end
        end)
        button:SetScript("OnLeave", function()
            button.hovered = nil; StyleButton()
            for _, part in ipairs(button.icon or {}) do
                part:SetColorTexture(unpack(kind == "lock" and Suite.db.meterLocked and palette.teal or palette.muted))
            end
            if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(button) then GameTooltip:Hide() end
        end)
        return button
    end
    window.settings = Button("settings", "..."); window.settings:SetWidth(18); window.settings:SetPoint("RIGHT", -2, 0)
    window.lock = Button("lock", ""); window.lock:SetWidth(18); window.lock:SetPoint("RIGHT", window.settings, "LEFT", -2, 0)
    window.lock.icon = {}
    local function LockPart(width, height, x, y)
        local part = window.lock:CreateTexture(nil, "ARTWORK")
        part:SetSize(width, height); part:SetPoint("CENTER", x, y); part:SetColorTexture(unpack(palette.muted))
        window.lock.icon[#window.lock.icon + 1] = part
        return part
    end
    LockPart(8, 6, 0, -2); LockPart(1, 4, -3, 3); LockPart(6, 1, 0, 5)
    window.lock.shackleRight = LockPart(1, 4, 3, 3)
    local keyhole = window.lock:CreateTexture(nil, "OVERLAY")
    keyhole:SetSize(1, 3); keyhole:SetPoint("CENTER", 0, -2); keyhole:SetColorTexture(unpack(palette.background))
    window.reset = Button("reset", ""); window.reset:SetWidth(18); window.reset:SetPoint("RIGHT", window.lock, "LEFT", -2, 0)
    window.reset.icon = {}
    local function ResetPart(width, height, x, y)
        local part = window.reset:CreateTexture(nil, "ARTWORK")
        part:SetSize(width, height); part:SetPoint("CENTER", x, y); part:SetColorTexture(unpack(palette.muted))
        window.reset.icon[#window.reset.icon + 1] = part
    end
    ResetPart(8, 1, -1, 4); ResetPart(1, 8, -5, 0); ResetPart(8, 1, -1, -4); ResetPart(1, 3, 3, -3)
    ResetPart(5, 1, 3, 4); ResetPart(3, 1, 3, 3); ResetPart(1, 1, 3, 2)
    window.session = Button("session", "Current"); window.session:SetPoint("RIGHT", window.reset, "LEFT", -2, 0)
    window.metric = Button("metric", ""); window.metric:SetPoint("LEFT", 2, 0); window.metric.label:Hide()
    window.title = Font(header, 12, palette.gold); window.title:SetPoint("LEFT", window.metric, "RIGHT", 4, 0)
    window.title:SetWordWrap(false); window.metric.label = window.title
    window.duration = Font(header, 9, palette.muted)
    window.duration:SetPoint("RIGHT", window.session, "LEFT", -6, 0); window.duration:SetWidth(34); window.duration:SetJustifyH("RIGHT")
    local grip = CreateFrame("Frame", nil, header)
    window.grip, grip.dots = grip, {}
    grip:EnableMouse(false); grip:SetHeight(12)
    grip:SetPoint("LEFT", window.title, "RIGHT", 4, 0); grip:SetPoint("RIGHT", window.duration, "LEFT", -4, 0)
    for row = 1, 2 do
        for column = 1, 3 do
            local dot = grip:CreateTexture(nil, "ARTWORK")
            dot:SetSize(2, 2); dot:SetPoint("CENTER", (column - 2) * 5, row == 1 and 3 or -3)
            dot:SetColorTexture(unpack(palette.muted)); grip.dots[#grip.dots + 1] = dot
        end
    end
    window.testLabel = Font(grip, 9, palette.teal); window.testLabel:SetPoint("CENTER"); window.testLabel:SetText("TEST")
    for rowIndex = 1, MAX_ROWS do
        local row = CreateFrame("Button", nil, frame)
        row:SetClipsChildren(true)
        row:EnableMouse(true); row:EnableMouseWheel(true); row:RegisterForClicks("LeftButtonUp")
        row:SetScript("OnClick", function() self:OpenDetails(window, row) end)
        row:SetScript("OnMouseWheel", function(_, direction) frame:GetScript("OnMouseWheel")(frame, direction) end)
        row:SetScript("OnEnter", function() row.highlight:Show() end)
        row:SetScript("OnLeave", function() row.highlight:Hide() end)
        row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetPoint("LEFT", 0, 0)
        row.bar = CreateFrame("StatusBar", nil, row)
        row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        if row.bar.GetStatusBarTexture then row.bar:GetStatusBarTexture():SetAtlas("UI-HUD-CoolDownManager-Bar") end
        row.bar:EnableMouse(false)
        row.background = row.bar:CreateTexture(nil, "BACKGROUND")
        row.background:SetPoint("TOPLEFT", -2, 2); row.background:SetPoint("BOTTOMRIGHT", 2, -2)
        row.background:SetAtlas("ui-damagemeters-bar-shadowbg")
        row.edge = row.bar:CreateTexture(nil, "OVERLAY")
        row.edge:SetPoint("TOPLEFT", -2, 2); row.edge:SetPoint("BOTTOMRIGHT", 2, -2)
        row.edge:SetAtlas("ui-damagemeters-bar-shadowedge")
        row.highlight = row.bar:CreateTexture(nil, "ARTWORK"); row.highlight:SetAllPoints()
        row.highlight:SetColorTexture(0.41, 0.84, 0.75, 0.12); row.highlight:Hide()
        row.rank = Font(row.bar, 11, palette.text, "OUTLINE"); row.rank:SetPoint("LEFT", 3, 0); row.rank:SetWidth(20)
        row.rank:SetWordWrap(false)
        row.value = Font(row.bar, 11, palette.text, "OUTLINE"); row.value:SetPoint("RIGHT", -4, 0); row.value:SetJustifyH("RIGHT")
        row.value:SetWordWrap(false)
        row.name = Font(row.bar, 11, palette.text, "OUTLINE"); row.name:SetPoint("LEFT", 24, 0)
        row.name:SetPoint("RIGHT", row.value, "LEFT", -4, 0); row.name:SetWordWrap(false)
        row:Hide(); window.rows[rowIndex] = row
    end
    window.empty = Font(frame, 11, palette.muted); window.empty:SetPoint("TOPLEFT", 12, -HEADER - 15); window.empty:SetWidth(210); window.empty:SetWordWrap(true)
    local more = CreateFrame("Frame", nil, frame)
    more:SetSize(8, 8); more:SetPoint("BOTTOMRIGHT", -16, 1); more:SetFrameLevel(frame:GetFrameLevel() + 3); more:EnableMouse(false)
    window.more = Font(more, 9, palette.muted); window.more:SetPoint("CENTER"); window.more:SetText("v")
    window.corners = {}
    for _, corner in ipairs({ "LEFT", "RIGHT" }) do
        local corner = corner
        local handle = CreateFrame("Button", nil, frame)
        window.corners[corner] = handle
        handle:SetSize(14, 14); handle:SetPoint("BOTTOM" .. corner, corner == "LEFT" and 1 or -1, 1)
        handle:SetFrameLevel(frame:GetFrameLevel() + 4); handle:EnableMouse(true); handle:RegisterForDrag("LeftButton")
        handle.dots = {}
        for row = 1, 3 do
            for column = 1, 4 - row do
                local dot = handle:CreateTexture(nil, "ARTWORK")
                dot:SetSize(1, 1); dot:SetPoint("BOTTOM" .. corner, (corner == "LEFT" and 1 or -1) * (1 + column * 3), row * 3)
                dot:SetColorTexture(unpack(palette.muted)); handle.dots[#handle.dots + 1] = dot
            end
        end
        handle:SetScript("OnDragStart", function() self:StartResize(index, corner) end)
        handle:SetScript("OnDragStop", function() self:EndResize() end)
        handle:SetScript("OnMouseUp", function(_, button) if button == "LeftButton" then self:EndResize() end end)
        handle:SetScript("OnEnter", function()
            for _, dot in ipairs(handle.dots) do dot:SetColorTexture(unpack(palette.teal)) end
            if GameTooltip and GameTooltip.SetOwner then
                GameTooltip:SetOwner(handle, "ANCHOR_CURSOR"); GameTooltip:AddLine("Resize Window " .. index)
                GameTooltip:AddLine(InCombatLockdown() and "Resize after combat." or "Drag to change width and height.", 0.88, 0.91, 0.93)
                GameTooltip:Show()
            end
        end)
        handle:SetScript("OnLeave", function()
            for _, dot in ipairs(handle.dots) do dot:SetColorTexture(unpack(palette.muted)) end
            if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(handle) then GameTooltip:Hide() end
        end)
    end
    frame:SetScript("OnMouseWheel", function(_, direction)
        if not self:IsActive() then return end
        window.offset = math.max(0, (window.offset or 0) - direction * 3)
        self:RefreshWindow(window)
    end)
    frame:SetScript("OnHide", function()
        self:CloseDetails(index); self:CloseMenus(index)
        if self.drag and self.drag.index == index then self:CancelDrag() end
        if self.resizing and self.resizing.index == index then self:CancelResize() end
    end)
    frame:Hide()
    self.windows[index] = window
end

function Meters:Apply()
    if not Suite.db then return end
    self:CloseMenus()
    if self.enabled and not Suite.db.damageMeters then self:ClearPreview() end
    self.enabled = Suite.db.damageMeters
    self:Normalize()
    self:CancelDrag()
    self:CancelResize()
    self:RefreshLock()
    if not self:IsActive() then
        self:CloseDetails()
        self:CancelTimer()
        if self.events then self.events:UnregisterAllEvents() end
        for _, window in ipairs(self.windows) do window.frame:Hide() end
    end
    Suite.AfterCombat("meters", function()
        if not self:IsActive() then
            for _, window in ipairs(self.windows) do window.frame:Hide() end
            return
        end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event, name)
                if event == "PLAYER_REGEN_DISABLED" then
                    self:CancelDrag()
                    self:CancelResize()
                    if self.preview then self:SetPreview(false) end
                elseif event == "CVAR_UPDATE" and name ~= "damageMeterEnabled" then return
                elseif event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" then
                    self:CancelDrag()
                    self:CancelResize()
                    Suite.AfterCombat("meterLayout", function() if self:IsActive() then self:Layout(); self:Refresh() end end)
                elseif event == "DAMAGE_METER_RESET" then
                    self:CloseDetails(); self:CloseMenus()
                    for _, window in ipairs(self.windows) do window.fightID = nil; window.offset = 0 end
                    self:Schedule()
                elseif event == "DAMAGE_METER_CURRENT_SESSION_UPDATED" then
                    if self.details and self.details.selection and self.details.selection.session == "Current" and not self.details.selection.fightID then
                        self.details.offset = 0
                    end
                    for _, window in ipairs(self.windows) do
                        if not window.fightID and Suite.db.meterWindows[window.index].session == "Current" then window.offset = 0 end
                    end
                    self:Schedule()
                elseif event == "SPELL_DATA_LOAD_RESULT" then
                    if self.details and self.details.selection then self:Schedule() end
                else self:Schedule() end
            end)
        end
        self.events:UnregisterAllEvents()
        for _, event in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED", "CVAR_UPDATE" }) do self.events:RegisterEvent(event) end
        if Suite.db.damageMeters and C_DamageMeter and type(C_DamageMeter.GetCombatSessionFromType) == "function" then
            for _, event in ipairs({ "DAMAGE_METER_COMBAT_SESSION_UPDATED", "DAMAGE_METER_CURRENT_SESSION_UPDATED", "DAMAGE_METER_RESET" }) do self.events:RegisterEvent(event) end
            self.events:RegisterEvent("SPELL_DATA_LOAD_RESULT")
        end
        for index = 1, 2 do if not self.windows[index] then self:CreateWindow(index) end end
        if not self.menuUI then self:CreateMenus() end
        if not self.details then self:CreateDetails() end
        self:Layout(); self:RefreshLock(); self:Refresh()
    end)
end
