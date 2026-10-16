local addonName, Suite = ...
local Meters, ui = Suite.DamageMeters, Suite.DamageMeters.ui
local VISIBLE_ROWS, WIDTH, ROW_HEIGHT, ROW_TOP = 8, 420, 22, 52
local HEIGHT = ROW_TOP + VISIBLE_ROWS * ROW_HEIGHT + 18
local function Read(value, kind) return Suite.IsReadable(value) and type(value) == kind end
local function Number(value)
    return Read(value, "number") and value == value and value > -math.huge and value < math.huge
end
local function TextValue(font, value, fallback)
    if not Suite.IsReadable(value) then font:SetText(value)
    else font:SetText(Read(value, "string") and value ~= "" and value or fallback or "") end
end
local function Metric(key)
    for _, metric in ipairs(Meters.metrics) do if metric.key == key then return metric end end
end

function Meters:CloseDetails(index)
    local details = self.details
    if details and (not index or details.selection and details.selection.windowIndex == index) then details.frame:Hide() end
end

function Meters:PositionDetails(index)
    if InCombatLockdown() or not self.details then return end
    local rect = self.rects and self.rects[index]
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    if not Read(rect, "table") or not Number(width) or not Number(height)
        or not Number(rect.x) or not Number(rect.y) or not Number(rect.width) or not Number(rect.height) then return end
    local x = rect.x + rect.width + 4
    if x + WIDTH > width then x = rect.x - WIDTH - 4 end
    x = math.max(0, math.min(x, math.max(0, width - WIDTH)))
    local y = math.max(0, math.min(rect.y + rect.height - HEIGHT, math.max(0, height - HEIGHT)))
    self.details.frame:ClearAllPoints()
    self.details.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
end

function Meters:CreateDetails()
    if InCombatLockdown() or self.details then return end
    local details = { rows = {}, offset = 0, requested = {} }
    -- Named only for the standard Escape-close compatibility list; data/state stay in the namespace.
    local frame = CreateFrame("Frame", addonName .. "CombatDetails", UIParent, "BackdropTemplate")
    details.frame, frame.foreverMeter = frame, true
    frame:SetSize(WIDTH, HEIGHT); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true)
    frame:EnableMouse(true); frame:EnableMouseWheel(true)
    details.background = frame:CreateTexture(nil, "BACKGROUND"); details.background:SetAllPoints()
    details.background:SetAtlas("common-dropdown-bg")
    if type(UISpecialFrames) == "table" then table.insert(UISpecialFrames, frame:GetName()) end
    details.title = ui.text(frame, 14, ui.palette.gold)
    ui.rowFont(details.title, 14); details.title:SetTextColor(unpack(ui.palette.gold))
    details.title:SetPoint("TOPLEFT", 20, -10); details.title:SetWidth(WIDTH - 64); details.title:SetWordWrap(false)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    details.close = close; close:SetSize(22, 22); close:SetPoint("TOPRIGHT", -12, -6); close:RegisterForClicks("LeftButtonUp")
    close:SetScript("OnClick", function() self:CloseDetails() end)
    details.context = ui.text(frame, 11, ui.palette.muted)
    details.context:SetPoint("TOPLEFT", 10, -33); details.context:SetWidth(242); details.context:SetWordWrap(false)
    details.total = ui.text(frame, 14, ui.palette.text); ui.rowFont(details.total, 14)
    details.total:SetPoint("TOPRIGHT", -10, -31); details.total:SetWidth(148); details.total:SetJustifyH("RIGHT")
    for index = 1, VISIBLE_ROWS do
        local row = CreateFrame("Frame", nil, frame)
        row:SetPoint("TOPLEFT", 10, -ROW_TOP - (index - 1) * ROW_HEIGHT); row:SetSize(WIDTH - 20, ROW_HEIGHT)
        row:SetClipsChildren(true); row:EnableMouse(true); row:EnableMouseWheel(true)
        row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetSize(ROW_HEIGHT, ROW_HEIGHT); row.icon:SetPoint("LEFT", 0, 0)
        row.bar = CreateFrame("StatusBar", nil, row)
        row.bar:SetPoint("TOPLEFT", ROW_HEIGHT, -1); row.bar:SetSize(WIDTH - 24 - ROW_HEIGHT, ROW_HEIGHT - 2)
        row.bar:EnableMouse(false); row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        if row.bar.GetStatusBarTexture then row.bar:GetStatusBarTexture():SetAtlas("UI-HUD-CoolDownManager-Bar") end
        row.background = row.bar:CreateTexture(nil, "BACKGROUND")
        row.background:SetPoint("TOPLEFT", -2, 2); row.background:SetPoint("BOTTOMRIGHT", 2, -2)
        row.background:SetAtlas("ui-damagemeters-bar-shadowbg")
        row.edge = row.bar:CreateTexture(nil, "OVERLAY")
        row.edge:SetPoint("TOPLEFT", -2, 2); row.edge:SetPoint("BOTTOMRIGHT", 2, -2)
        row.edge:SetAtlas("ui-damagemeters-bar-shadowedge")
        row.value = ui.text(row.bar, 14, ui.palette.text); ui.rowFont(row.value, 14)
        row.value:SetPoint("RIGHT", -3, 0); row.value:SetJustifyH("RIGHT"); row.value:SetWordWrap(false)
        row.name = ui.text(row.bar, 14, ui.palette.text); ui.rowFont(row.name, 14)
        row.name:SetPoint("LEFT", 3, 0); row.name:SetPoint("RIGHT", row.value, "LEFT", -4, 0); row.name:SetWordWrap(false)
        row:SetScript("OnMouseWheel", function(_, direction) frame:GetScript("OnMouseWheel")(frame, direction) end)
        row:SetScript("OnEnter", function()
            local id = row.spell and row.spell.spellID
            if details.selection and not details.selection.preview and Number(id) and id > 0
                and GameTooltip and GameTooltip.SetOwner and GameTooltip.SetSpellByID then
                GameTooltip:SetOwner(row, "ANCHOR_CURSOR"); GameTooltip:SetSpellByID(id); GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function()
            if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(row) then GameTooltip:Hide() end
        end)
        row:SetScript("OnHide", function() row:GetScript("OnLeave")(row); row.spell = nil; row.icon:SetTexture(nil) end)
        row:Hide(); details.rows[index] = row
    end
    details.message = ui.text(frame, 12, ui.palette.muted)
    details.message:SetPoint("TOPLEFT", 12, -ROW_TOP - 6); details.message:SetSize(WIDTH - 24, 80); details.message:SetWordWrap(true)
    details.footer = ui.text(frame, 10, ui.palette.muted)
    details.footer:SetPoint("BOTTOMLEFT", 10, 5); details.footer:SetWidth(WIDTH - 20)
    frame:SetScript("OnMouseWheel", function(_, direction)
        if not Number(direction) then return end
        details.offset = math.max(0, details.offset - direction * 3); self:RefreshDetails()
    end)
    frame:SetScript("OnShow", function()
        if type(GetMouseFoci) == "function" and type(DoesAncestryIncludeAny) == "function" then
            frame:RegisterEvent("GLOBAL_MOUSE_DOWN")
        end
    end)
    frame:SetScript("OnEvent", function(_, event)
        if event ~= "GLOBAL_MOUSE_DOWN" or type(GetMouseFoci) ~= "function"
            or type(DoesAncestryIncludeAny) ~= "function" then return end
        -- Native focus ancestry avoids reading combat-tainted widget coordinates or swallowing the click.
        local foci = GetMouseFoci()
        if not Read(foci, "table") or not Number(#foci) then return end
        for _, focus in ipairs(foci) do if not Suite.IsReadable(focus) then return end end
        local inside = DoesAncestryIncludeAny(frame, foci)
        if Read(inside, "boolean") and not inside then frame:Hide() end
    end)
    frame:SetScript("OnHide", function()
        frame:UnregisterEvent("GLOBAL_MOUSE_DOWN")
        details.selection, details.offset, details.requested = nil, 0, {}
        details.title:SetText(""); details.context:SetText(""); details.total:SetText("")
        for _, row in ipairs(details.rows) do row:Hide(); row.spell = nil; row.icon:SetTexture(nil); row.name:SetText(""); row.value:SetText("") end
    end)
    frame:Hide(); self.details = details
end

function Meters:OpenDetails(window, row)
    if not self:IsWindowShown(window.index) or not self.details or not Read(row.source, "table") then return end
    self:CloseMenus()
    local source, settings, details = row.source, Suite.db.meterWindows[window.index], self.details
    local guid, creatureID = source.sourceGUID, source.sourceCreatureID
    local restricted = not Suite.IsReadable(guid) or not Suite.IsReadable(creatureID)
    -- Source queries allow secret arguments only from untainted code. Never pass a hidden identifier from addon code.
    if not Read(guid, "string") or guid == "" then guid = nil end
    if not Number(creatureID) or creatureID <= 0 then creatureID = nil end
    local selection = { windowIndex = window.index, metric = settings.metric, session = settings.session,
        fightID = window.fightID, guid = guid, creatureID = creatureID, preview = self.preview == true,
        sampleIndex = self.preview and row.sourceIndex or nil, restricted = restricted,
        class = Read(source.classFilename, "string") and source.classFilename or nil }
    details.selection, details.offset, details.requested = selection, 0, {}
    TextValue(details.title, source.name, "Combat details")
    ui.number(details.total, source.totalAmount, settings.numbers == "compact")
    local fight, metric = self:FindFight(selection.fightID), Metric(selection.metric)
    details.context:SetText(metric.label .. " · " .. (selection.preview and "TEST" or fight and fight.name or selection.session))
    self:PositionDetails(window.index)
    details.frame:Show(); self:RefreshDetails()
end

function Meters:SampleDetails(selection)
    local metric = Metric(selection.metric)
    local session = self:TestSession(metric)
    local source = Number(selection.sampleIndex) and session.combatSources[selection.sampleIndex]
    if not source then return end
    local names = { "Primary ability", "Secondary ability", "Periodic effect", "Area ability", "Companion ability", "Other ability" }
    local weights = { 0.42, 0.27, 0.15, 0.09, 0.05, 0.02 }
    local icons = { "Ability_MeleeDamage", "Ability_Warrior_SavageBlow", "Spell_Shadow_ShadowWordPain",
        "Spell_Nature_Lightning", "Ability_Hunter_Pet_Bear", "INV_Misc_QuestionMark" }
    local data = { totalAmount = source.totalAmount, maxAmount = source.totalAmount * weights[1], combatSpells = {} }
    for index, label in ipairs(names) do
        data.combatSpells[index] = { sampleName = label, sampleIcon = "Interface\\Icons\\" .. icons[index], totalAmount = source.totalAmount * weights[index],
            amountPerSecond = source.amountPerSecond * weights[index], combatSpellDetails = { unitName = "Sample unit" } }
    end
    return data
end

local function SpellLabel(font, format, name, unit)
    if not Suite.IsReadable(unit) or Read(unit, "string") and unit ~= "" then
        font:SetFormattedText(format .. " (%s)", name, unit)
    else font:SetFormattedText(format, name) end
end

local function SpellName(details, font, spell, preview, unit)
    if preview then SpellLabel(font, "%s", spell.sampleName, unit); return end
    local id, name = spell.spellID
    if C_Spell and type(C_Spell.GetSpellName) == "function" and (Number(id) or not Suite.IsReadable(id)) then
        -- GetSpellName explicitly permits secret spell arguments when tainted; only native text receives its result.
        name = C_Spell.GetSpellName(id)
    end
    if not Suite.IsReadable(name) then SpellLabel(font, "%s", name, unit)
    elseif Read(name, "string") and name ~= "" then SpellLabel(font, "%s", name, unit)
    elseif Number(id) then
        SpellLabel(font, "Spell %d", id, unit)
        if id > 0 and not details.requested[id] and C_Spell and type(C_Spell.RequestLoadSpellData) == "function" then
            details.requested[id] = true; C_Spell.RequestLoadSpellData(id)
        end
    elseif not Suite.IsReadable(id) then SpellLabel(font, "Spell %d", id, unit)
    else SpellLabel(font, "%s", "Unknown ability", unit) end
end

local function SpellIcon(row, spell, preview)
    local icon
    if preview then icon = spell.sampleIcon
    elseif C_Spell and type(C_Spell.GetSpellTexture) == "function" then
        local id = spell.spellID
        if not Suite.IsReadable(id) or Number(id) and id > 0 then icon = C_Spell.GetSpellTexture(id) end
    end
    -- Both GetSpellTexture and SetTexture explicitly permit secret arguments when tainted.
    if not Suite.IsReadable(icon) then row.icon:SetTexture(icon)
    elseif Number(icon) and icon > 0 or Read(icon, "string") and icon ~= "" then row.icon:SetTexture(icon)
    else row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") end
end

function Meters:RefreshDetails()
    local details = self.details
    if not details or not details.frame:IsShown() or not details.selection then return end
    local selection, data, message = details.selection
    if selection.preview then
        if not self.preview then self:CloseDetails(); return end
        data = self:SampleDetails(selection)
    elseif not selection.guid and not selection.creatureID then
        message = selection.restricted and "Spell details are restricted for this player. Click their bar again after combat."
            or "No player identifier is available for this selection."
    else
        local available, reason = self:Available()
        local query
        if C_DamageMeter then
            if selection.fightID then query = C_DamageMeter.GetCombatSessionSourceFromID
            else query = C_DamageMeter.GetCombatSessionSourceFromType end
        end
        if not available then message = reason
        elseif type(query) ~= "function" then message = "Detailed combat data is unavailable on this client."
        else
            local metricType = Enum.DamageMeterType[selection.metric]
            if Number(metricType) then
                if selection.fightID then data = query(selection.fightID, metricType, selection.guid, selection.creatureID)
                else data = query(Enum.DamageMeterSessionType[selection.session], metricType, selection.guid, selection.creatureID) end
            end
        end
    end
    if not Suite.IsReadable(data) then message = "Spell details are restricted during combat." end
    local spells = Read(data, "table") and data.combatSpells
    if not Read(spells, "table") then spells = {} end
    local count = #spells
    if not Number(count) then count, spells = 0, {} end
    details.offset = math.max(0, math.min(details.offset, math.max(0, count - VISIBLE_ROWS)))
    local maximum = 1
    if Read(data, "table") then maximum = data.maxAmount end
    if Suite.IsReadable(maximum) and (not Number(maximum) or maximum <= 0) then maximum = 1 end
    local settings = Suite.db.meterWindows[selection.windowIndex]
    local metric, color = Metric(selection.metric), ui.barColor(settings, selection.class)
    local total = Read(data, "table") and data.totalAmount
    if Read(data, "table") then ui.number(details.total, data.totalAmount, settings.numbers == "compact")
    elseif selection.guid or selection.creatureID then details.total:SetText("") end
    for index, row in ipairs(details.rows) do
        local spell = spells[index + details.offset]
        local visible = Read(spell, "table")
        row:SetShown(visible)
        if visible then
            row.spell = spell
            local unit = spell.combatSpellDetails
            SpellName(details, row.name, spell, selection.preview, Read(unit, "table") and unit.unitName)
            SpellIcon(row, spell, selection.preview)
            local amount = spell.totalAmount
            if Suite.IsReadable(amount) and not Number(amount) then amount = 0 end
            row.bar:SetMinMaxValues(0, maximum); row.bar:SetValue(amount)
            row.bar:SetStatusBarColor(color[1], color[2], color[3], 0.85)
            local percentage
            if Number(amount) and Number(total) and total > 0 then
                local value = amount / total * 100
                if Number(value) then percentage = math.floor(math.max(0, math.min(100, value)) + 0.5) end
            end
            local primary, secondary = amount, spell.amountPerSecond
            if metric.count then secondary = nil
            elseif metric.rate then primary, secondary = secondary, primary end
            ui.pair(row.value, primary, secondary, settings.numbers == "compact", percentage, metric.rate)
        else
            row.spell = nil; row.icon:SetTexture(nil); row.name:SetText(""); row.value:SetText("")
            row.bar:SetMinMaxValues(0, 1); row.bar:SetValue(0)
        end
    end
    details.message:SetText(message or count == 0 and "No spell details for this selection." or "")
    details.footer:SetText(count > VISIBLE_ROWS and string.format("%d–%d of %d · Scroll for more", details.offset + 1,
        math.min(count, details.offset + VISIBLE_ROWS), count) or selection.preview and "TEST · Sample abilities and units" or "")
end
