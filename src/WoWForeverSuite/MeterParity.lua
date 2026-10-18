local _, Suite = ...
local Meters, ui = Suite.DamageMeters, Suite.DamageMeters.ui
local function Read(value, kind) return Suite.IsReadable(value) and type(value) == kind end
local function Number(value)
    return Read(value, "number") and value == value and value > -math.huge and value < math.huge
end
local pinMetrics = { DamageDone = true, Dps = true, HealingDone = true, Hps = true, Interrupts = true,
    Dispels = true, DamageTaken = true, AvoidableDamageTaken = true }

-- Only public metadata drives selection/layout. Hidden amounts go straight to supported widgets.
function Meters:SetUnitIcon(icon, spec, class)
    if Number(spec) and spec > 0 then icon:SetTexture(spec); icon:Show(); return true end
    if Read(class, "string") and Read(CLASS_ICON_TCOORDS, "table") and Read(CLASS_ICON_TCOORDS[class], "table")
        and type(GetClassAtlas) == "function" then
        local atlas = GetClassAtlas(class)
        if Read(atlas, "string") and atlas ~= "" then icon:SetAtlas(atlas); icon:Show(); return true end
    end
    icon:SetTexture(nil); icon:Hide()
    return false
end

function Meters:RenderSourceRow(window, row, source, sourceIndex, metric, maximum, sessionTotal)
    local visible = Read(source, "table")
    row.source, row.sourceIndex = visible and source or nil, visible and sourceIndex or nil
    row:SetShown(visible)
    if not visible then
        row.icon:SetTexture(nil); row.icon:Hide(); row.highlight:Hide()
        row.rank:SetText(""); row.name:SetText(""); row.value:SetText("")
        row.bar:SetMinMaxValues(0, 1); row.bar:SetValue(0)
        return
    end
    local settings = Suite.db.meterWindows[window.index]
    local death = Number(source.deathRecapID) and source.deathRecapID > 0
    row.rank:SetText("")
    if not death then row.rank:SetFormattedText("%d.", sourceIndex) end
    local name = source.name
    if Suite.IsReadable(name) then row.name:SetText(Read(name, "string") and name or "Unknown")
    else row.name:SetText(name) end
    if not death and settings.classColors and Enum and Enum.DamageMeterSourceDisplayType
        and Number(source.sourceDisplayType) and Number(Enum.DamageMeterSourceDisplayType.Enemy)
        and source.sourceDisplayType == Enum.DamageMeterSourceDisplayType.Enemy
        and Read(source.factionGroup, "string") then
        local atlas = source.factionGroup == "Horde" and "HordeSymbol" or source.factionGroup == "Alliance" and "AllianceSymbol"
        if atlas then
            local label = name
            if Suite.IsReadable(name) and not Read(name, "string") then label = "Unknown" end
            row.name:SetFormattedText("|A:" .. atlas .. ":14:14|a %s", label)
        end
    end
    local total = source.totalAmount
    if Suite.IsReadable(total) and not Number(total) then total = 0 end
    row.bar:SetMinMaxValues(0, death and 1 or maximum)
    row.bar:SetValue(death and 1 or total)
    local r, g, b = ui.barColor(settings, source.classFilename)
    row.bar:SetStatusBarColor(r, g, b, 0.85)
    if settings.icons and metric.key ~= "EnemyDamageTaken" then
        self:SetUnitIcon(row.icon, source.specIconID, source.classFilename)
    else row.icon:SetTexture(nil); row.icon:Hide() end
    if death then
        local time = source.deathTimeSeconds
        if settings.session == "Overall" and not window.fightID then row.value:SetText("")
        elseif Number(time) and time >= 0 then
            row.value:SetFormattedText("%dm%02ds", math.floor(time / 60), math.floor(time % 60))
        elseif not Suite.IsReadable(time) then row.value:SetFormattedText("%.0fs", time)
        else row.value:SetText("") end
        return
    end
    local percentage
    if settings.content == "complete" and Number(total) and Number(sessionTotal) and sessionTotal > 0 then
        local value = total / sessionTotal * 100
        if Number(value) then percentage = math.max(0, math.min(100, value)) end
    end
    if settings.content == "minimal" then
        local primary = total
        if metric.rate then primary = source.amountPerSecond end
        ui.number(row.value, primary, settings.numbers == "compact", metric.rate)
    elseif metric.rate and settings.content == "standard" then
        -- Preserve the user's existing rate-only presentation until they select Complete.
        ui.number(row.value, source.amountPerSecond, settings.numbers == "compact", true)
    else
        local primary, secondary = total, source.amountPerSecond
        if metric.count then secondary = nil
        elseif metric.rate then primary, secondary = secondary, primary end
        ui.pair(row.value, primary, secondary, settings.numbers == "compact", percentage, metric.rate)
    end
end

function Meters:RefreshPinnedRow(window, sources, metric, maximum, total)
    for _, row in ipairs(window.pinned or {}) do self:RenderSourceRow(window, row, nil, nil, metric, maximum, total) end
    local settings = Suite.db.meterWindows[window.index]
    if not window.pinned or not settings.pinSelf or window.visibleRows == 0 or not pinMetrics[metric.key] then return end
    for index, source in ipairs(sources) do
        if Read(source, "table") and Read(source.isLocalPlayer, "boolean") and source.isLocalPlayer then
            local pin = index <= window.offset and 1 or index > window.offset + window.visibleRows and 2 or nil
            if pin then self:RenderSourceRow(window, window.pinned[pin], source, index, metric, maximum, total) end
            return
        end
    end
end

function Meters:RefreshDuration(window, session, metric)
    local duration = Read(session, "table") and session.durationSeconds
    if not self.preview and not window.fightID and C_DamageMeter and type(C_DamageMeter.GetSessionDurationSeconds) == "function" then
        local sessionType = Enum and Enum.DamageMeterSessionType and Enum.DamageMeterSessionType[Suite.db.meterWindows[window.index].session]
        if Number(sessionType) then
            local live = C_DamageMeter.GetSessionDurationSeconds(sessionType)
            if not Suite.IsReadable(live) or Number(live) then duration = live end
        end
    end
    if Number(duration) and duration >= 0 then
        window.duration:SetFormattedText("%d:%02d", math.floor(duration / 60), math.floor(duration % 60))
        window.metric.fullLabel = metric.label .. string.format(" · %d:%02d", math.floor(duration / 60), math.floor(duration % 60))
    elseif not Suite.IsReadable(duration) then window.duration:SetFormattedText("%.0fs", duration)
    else window.duration:SetText("") end
end

function Meters:IsPlayerInCombat()
    if type(UnitAffectingCombat) ~= "function" then return InCombatLockdown() end
    local value = UnitAffectingCombat("player")
    return Read(value, "boolean") and value or false
end

function Meters:UpdateClock()
    local needed = false
    if Suite.db and Suite.db.damageMeters and not self.preview and self:IsPlayerInCombat()
        and C_DamageMeter and type(C_DamageMeter.GetSessionDurationSeconds) == "function" then
        for _, window in ipairs(self.windows) do
            if window.layoutReady and self:IsWindowShown(window.index) and not window.fightID then needed = true; break end
        end
    end
    if not needed then
        if self.clockTimer then self.clockTimer:Cancel(); self.clockTimer = nil end
    elseif not self.clockTimer and C_Timer and C_Timer.NewTimer then
        self.clockTimer = C_Timer.NewTimer(1, function()
            self.clockTimer = nil
            if not self:IsActive() then return end
            for _, window in ipairs(self.windows) do
                if window.layoutReady and self:IsWindowShown(window.index) and not window.fightID then
                    for _, metric in ipairs(self.metrics) do
                        if metric.key == Suite.db.meterWindows[window.index].metric then self:RefreshDuration(window, nil, metric); break end
                    end
                end
            end
            self:UpdateClock()
        end)
    end
end

function Meters:UpdateVisibility()
    if not Suite.db then return end
    for _, window in ipairs(self.windows) do
        window.frame:SetShown(window.layoutReady == true and self:IsWindowShown(window.index))
    end
end

function Meters:RefreshInteraction()
    if InCombatLockdown() then return end
    for _, window in ipairs(self.windows) do
        local mouse = not Suite.db.meterWindows[window.index].clickThrough or self.preview == true
        window.frame:EnableMouse(mouse); window.frame:EnableMouseWheel(mouse)
        window.header:EnableMouse(mouse); window.header:EnableMouseWheel(mouse)
        for _, key in ipairs({ "settings", "lock", "metric", "session", "reset" }) do
            window[key]:EnableMouse(mouse)
        end
        for _, corner in pairs(window.corners) do corner:EnableMouse(mouse) end
        window.grip:EnableMouse(false)
        for _, rows in ipairs({ window.rows, window.pinned }) do
            for _, row in ipairs(rows) do row:EnableMouse(mouse); row:EnableMouseWheel(mouse) end
        end
    end
end

function Meters:OpenRecap(source)
    local id = source.deathRecapID
    if not Number(id) or id <= 0 then return false end
    self:CloseDetails(); self:CloseMenus()
    -- The native bootstrap owns loading and opening its own recap UI. Never cache combat IDs.
    if type(OpenDeathRecapUI) ~= "function" then Suite.Print("Death recap is unavailable on this client.")
    elseif InCombatLockdown() then Suite.Print("Open the death recap again after combat.")
    else OpenDeathRecapUI(id) end
    return true
end
