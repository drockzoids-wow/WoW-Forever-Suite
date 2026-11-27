local _, Suite = ...
local Timers = Suite.ReminderTimers
-- All combat aura decisions stay in Blizzard's native renderer. Inverse clips
-- reveal our art/text; Lua never reads the native frames, text or their bounds.
local Combat = { pool = {}, records = {}, coverage = {}, durations = {}, auraIDs = {}, auraDurations = {}, failed = {} }
Suite.CombatBuffs = Combat
table.insert(Suite.modules, Combat)
local PLANE, LINE = 260, 16
-- These bounds cover the icon, centered header and up to 40 tooltip rows
-- for any supported icon size. Resizing the art leaves native masks intact.
local MASK_WIDTH, MASK_LEFT, MASK_TOP, MASK_DEPTH = 1024, -512, 512, 1024
local WARNING_GLYPHS = string.rep("W", 128)
local CLIP = "DisableUntrustedLayoutScriptsTemplate"
local function Read(v, kind) return Suite.IsReadable(v) and type(v) == kind end
local function Number(v) return Read(v, "number") and v == v and v >= 0 and v < math.huge end
local function ID(v) return Number(v) and v > 0 and v % 1 == 0 end
local function Call(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, result = pcall(fn, ...)
    if ok and Suite.IsReadable(result) then return result end
end
local function Enabled()
    return Suite.db and Suite.db.missingBuffs == true and Suite.db.missingBuffCombat == true
end
local function Label(parent, text, size)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", size or 10, "OUTLINE")
    label:SetTextColor(0.95, 0.95, 0.95, 1); label:SetText(text)
    return label
end
local function Clip(parent)
    local frame = CreateFrame("Frame", nil, parent, CLIP)
    frame:SetClipsChildren(true); frame:EnableMouse(false)
    return frame
end
local function SameIDs(ids, previous)
    if not previous then return false end
    for id in pairs(ids) do if not previous[id] then return false end end
    for id in pairs(previous) do if not ids[id] then return false end end
    return true
end

function Combat:IndexRanks()
    if self.rankNames then return end
    self.rankNames, self.rankIDs = {}, {}
    for _, rows in pairs(Suite.TrainingCatalogData or {}) do
        for _, row in ipairs(rows) do
            if ID(row.id) and Read(row.name, "string") then
                self.rankNames[row.id] = row.name
                local ids = self.rankIDs[row.name] or {}; self.rankIDs[row.name] = ids; ids[row.id] = true
            end
        end
    end
end

function Combat:IDs(family)
    self:IndexRanks()
    local ids = {}
    local function Add(id)
        if not ID(id) then return end
        ids[id] = true
        for rank in pairs(self.rankIDs[self.rankNames[id]] or {}) do ids[rank] = true end
    end
    for id in pairs(family.ids) do Add(id) end
    for _, spell in ipairs(family.choices or {}) do Add(spell.id) end
    if family.spell then Add(family.spell.id) end
    -- Learned outside-combat identity metadata, never cached presence or expiry.
    for name in pairs(family.names) do
        for id in pairs(self.auraIDs[name] or {}) do ids[id] = true end
    end
    return ids
end

function Combat:Observe(unit, aura)
    if not Enabled() or InCombatLockdown() or not Read(unit, "string") or not Read(aura, "table")
        or not Read(aura.name, "string") or not ID(aura.spellId) then return end
    local ids = self.auraIDs[aura.name] or {}; self.auraIDs[aura.name] = ids
    if not ids[aura.spellId] then ids[aura.spellId] = true; self.metadataDirty = true end
    if Number(aura.duration) and aura.duration > 0 then
        local durations = self.auraDurations[unit] or {}; self.auraDurations[unit] = durations
        if durations[aura.name] ~= aura.duration then durations[aura.name] = aura.duration; self.metadataDirty = true end
    end
end

function Combat:Descriptors()
    local buffs, descriptors = Suite.MissingBuffs, {}
    local roster = buffs:Roster(true)
    local player = roster[1]
    if not player then return descriptors end
    if buffs.bookDirty then buffs.learned, buffs.learnedComplete = buffs:Learned(); buffs.bookDirty = false end
    for _, family in ipairs(buffs:Families(player.class, buffs.learned or {})) do
        if family.spell and not family.catalog.weapon and not family.catalog.outOfCombatOnly then
            local descriptor = { key = family.key, family = family, spell = family.spell, members = {} }
            for _, member in ipairs(roster) do
                local personal = not family.catalog.group or family.catalog.upkeep
                local allowed = member.unit == "player" and (personal and Suite.db.missingBuffClass or not personal and Suite.db.missingBuffSelf)
                    or member.unit ~= "player" and family.catalog.group and Suite.db.missingBuffOutgoing
                local recipient = buffs:Recipient(family, member.class)
                local spell = recipient.spell
                -- Prepare every eligible member, including distant members who
                -- may approach during combat. Public range gates filter display.
                if allowed and spell and (not buffs:PartyOnly(family.catalog, spell.root or spell.id) or member.party) then
                    local seconds
                    for name in pairs(recipient.names) do
                        local duration = (self.auraDurations[member.unit] or {})[name]
                        if Number(duration) and duration > 0 then seconds = duration end
                    end
                    local durationKey = family.key .. ":" .. spell.id
                    if seconds then self.durations[durationKey] = seconds end
                    local warning = Suite.db.missingBuffExpiry and not family.catalog.toggle
                        and Suite.BuffReminders:Warning(self.durations[durationKey]) or 0
                    descriptor.members[#descriptor.members + 1] = {
                        unit = member.unit, guid = member.guid, name = member.name, spellID = spell.id,
                        ids = self:IDs(recipient), warning = warning,
                    }
                end
            end
            if #descriptor.members > 0 then descriptors[#descriptors + 1] = descriptor end
        end
    end
    return descriptors
end

local function Signature(descriptor)
    local parts = { descriptor.key, descriptor.spell.id, descriptor.spell.icon or "", descriptor.spell.name }
    for _, member in ipairs(descriptor.members) do
        parts[#parts + 1] = member.unit; parts[#parts + 1] = member.guid
        parts[#parts + 1] = member.name; parts[#parts + 1] = member.warning
        parts[#parts + 1] = member.spellID or descriptor.spell.id
        local ids = {}; for id in pairs(member.ids) do ids[#ids + 1] = id end; table.sort(ids)
        for _, id in ipairs(ids) do parts[#parts + 1] = id end
    end
    return table.concat(parts, ":")
end

function Combat:Chip(parent, record, anchor)
    local size = record.size
    local chip = CreateFrame("Frame", nil, parent, CLIP)
    chip:SetSize(size, size); chip:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
    local plate = CreateFrame("Frame", nil, chip, "BackdropTemplate")
    plate:SetSize(size, size); plate:SetPoint("TOPLEFT", chip, "TOPLEFT", 0, 0)
    plate:EnableMouse(false)
    plate:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    plate:SetBackdropColor(0.035, 0.05, 0.065, 0.94); Suite.Theme:BuffIconBorder(plate, 0.8)
    local icon = plate:CreateTexture(nil, "ARTWORK")
    icon:SetSize(size - 4, size - 4); icon:SetPoint("TOPLEFT", plate, "TOPLEFT", 2, -2)
    icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
    icon:SetTexture(record.descriptor.spell.icon)
    icon:SetVertexColor(1, 1, 1, 1)
    -- A family can contain both missing and expiring members. Do not invent a
    -- Lua-derived summary/severity for their native-composited union.
    chip:EnableMouse(false)
    if chip.SetMouseClickEnabled and chip.SetMouseMotionEnabled then
        chip:SetMouseClickEnabled(false); chip:SetMouseMotionEnabled(true)
    end
    chip:SetScript("OnEnter", function() record.tooltip:Show() end)
    chip:SetScript("OnLeave", function() record.tooltip:Hide() end)
    -- Expiry chips inherit secret Shown from native aura buttons. OnHide and
    -- OnShow are forbidden there; public cell context owns visibility cleanup.
    return chip, plate, icon
end

function Combat:SetPreview(show)
    if not show then
        local active = self.previewActive
        self.previewActive = nil
        if self.previewRoot then self.previewRoot:Hide() end
        if active then
            Suite.MissingBuffs:Queue()
            Suite.GUI:EndWorldPreview(true, self)
        end
        return
    end
    if InCombatLockdown() or not Suite.MissingBuffs.settingsVisible then return end
    Suite.MissingBuffs:SetPreview(false)
    self.previewActive = true
    self:UpdatePreview()
    if Suite.MissingBuffs.bar then Suite.MissingBuffs.bar:Hide() end
    return true
end

function Combat:UpdatePreview()
    if not self.previewActive or InCombatLockdown() then return end
    if not self.previewRoot then
        self.previewRoot = CreateFrame("Frame", nil, UIParent, CLIP)
        self.previewRoot:SetFrameStrata("DIALOG"); self.previewRoot:EnableMouse(false)
        local title = Label(self.previewRoot, "Missing Buffs", 10)
        title:SetTextColor(0.88, 0.91, 0.93); title:SetPoint("TOP", self.previewRoot, "TOP", 0, -6)
        self.previewSamples = {}
    end
    local entries = Suite.MissingBuffs:PreviewEntries()
    local width, height, size, stride = Suite.MissingBuffs:BarLayout(#entries)
    self.previewRoot:SetSize(width, height)
    for index, entry in ipairs(entries) do
        local sample = self.previewSamples[index]
        if not sample then
            sample = { descriptor = { spell = entry.spell }, size = size }
            sample.cell = CreateFrame("Frame", nil, self.previewRoot, CLIP)
            sample.tooltip = CreateFrame("Frame", nil, sample.cell, "BackdropTemplate," .. CLIP)
            sample.tooltip:SetSize(160, 36); sample.tooltip:SetPoint("TOP", sample.cell, "BOTTOM", 0, -6)
            sample.tooltip:SetFrameStrata("TOOLTIP"); sample.tooltip:EnableMouse(false)
            sample.tooltip:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
            sample.tooltip:SetBackdropColor(0.035, 0.05, 0.065, 0.94); Suite.Theme:Backdrop(sample.tooltip, 0.45)
            local text = Label(sample.tooltip, "Preview only", 10); text:SetPoint("CENTER", sample.tooltip, "CENTER", 0, 0)
            sample.tooltip:Hide()
            sample.cell:SetScript("OnHide", function() sample.tooltip:Hide() end)
            sample.chip, sample.plate, sample.icon = self:Chip(sample.cell, sample, sample.cell)
            self.previewSamples[index] = sample
        end
        sample.size = size
        sample.cell:SetSize(size, size + 14); sample.cell:ClearAllPoints()
        sample.cell:SetPoint("TOPLEFT", self.previewRoot, "TOPLEFT", (width - (#entries * stride - 9)) / 2 + (index - 1) * stride, -25)
        sample.chip:SetSize(size, size); sample.plate:SetSize(size, size)
        sample.icon:SetSize(size - 4, size - 4); sample.icon:SetTexture(entry.spell.icon)
        sample.cell:Show()
    end
    for index = #entries + 1, #self.previewSamples do self.previewSamples[index].cell:Hide() end
    Suite.MissingBuffs:Place(self.previewRoot); self.previewRoot:Show()
end

-- The native group's width is zero or MASK_WIDTH. These clips let the
-- renderer compose the icon, title and tooltip without reading aura state.
local function MissingClip(parent, container, cell)
    local clip = Clip(parent)
    clip:SetPoint("TOPLEFT", container, "TOPRIGHT", 0, 0)
    clip:SetPoint("BOTTOMRIGHT", cell, "TOPLEFT", MASK_LEFT + MASK_WIDTH, -MASK_DEPTH)
    return clip
end

local function PresentClip(parent, container)
    local clip = Clip(parent)
    clip:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    clip:SetPoint("BOTTOMRIGHT", container, "TOPRIGHT", 0, -MASK_DEPTH - MASK_TOP)
    return clip
end

local function WarningClip(parent, gate)
    local clip = Clip(parent)
    clip:SetPoint("TOPLEFT", gate, "TOPLEFT", 0, 0)
    clip:SetPoint("BOTTOMRIGHT", gate, "TOPRIGHT", 0, -MASK_DEPTH - MASK_TOP)
    return clip
end

local function Filters(member, expiry)
    return { includeSpellIDs = member.ids, maxDuration = expiry and 864000 or nil }
end

function Combat:Visuals(record, display, tooltip)
    local chip, plate, icon = self:Chip(display, record, record.cell)
    local title = Label(display, "Missing Buffs", 10)
    title:SetTextColor(0.88, 0.91, 0.93)
    title:SetPoint("TOP", self.frame, "TOP", 0, -6)
    return { display = display, tooltip = tooltip, chip = chip, plate = plate, icon = icon, name = Label(tooltip, "") }
end

local function MakeContainer(parent, cell)
    local container = CreateFrame("AuraContainer", nil, parent, "CustomAuraContainerTemplate")
    container:SetEnabled(false)
    container:SetEditModePreviewEnabled(false)
    container:SetAuraProcessingPolicy(CustomAuraContainerAuraProcessingPolicy.None)
    container:SetPoint("TOPLEFT", cell, "TOPLEFT", MASK_LEFT, MASK_TOP)
    return container
end

local function AddGroup(container, filters)
    container:AddAuraGroup("Buff", "HELPFUL", {
        maxFrameCount = 1, candidateFilters = filters,
        layout = { elementWidth = MASK_WIDTH, elementHeight = 1 },
        sortMethod = AuraContainerSortMethod.ExpirationOnly, sortDirection = AuraContainerSortDirection.Reverse,
        initializeFrame = function(button) button:EnableMouse(false); button:SetSize(MASK_WIDTH, 1) end,
    })
end

function Combat:PreparePresence(record, row, member)
    local cell = record.cell
    if not row.presence then
        local container = MakeContainer(row.display, cell)
        row.presence = container
        local art = self:Visuals(record, MissingClip(row.display, container, cell), MissingClip(row.tooltip, container, cell))
        row.missingArt = art
        local plate = art.plate
        plate.icon = art.icon
        Timers:Create(plate)
        plate.bindingLabel = Suite.MissingBuffs:BindingLabel(plate)
        row.cooldownPlate = plate
    end
    local container = row.presence
    if row.unit ~= member.unit then container:SetUnit(member.unit) end
    if not row.presenceReady then
        AddGroup(container, Filters(member))
        row.presenceReady = true
    elseif not SameIDs(member.ids, row.ids) then
        container:SetAuraGroupCandidateFilters("Buff", Filters(member))
    end
    container:SetEnabled(true)
end

function Combat:PrepareExpiry(record, row, member)
    local cell = record.cell
    if not row.expiry then
        local container = MakeContainer(row.display, cell)
        row.expiry = container
        row.clock = CreateFrame("Frame", nil, row.display, CLIP)
        row.clock:SetPoint("TOPLEFT", cell, "TOPLEFT", 2, -2)
        row.formatter = C_StringUtil.CreateNumericRuleFormatter()
    end
    local container = row.expiry
    if row.expiryUnit ~= member.unit then container:SetUnit(member.unit) end
    if row.warning ~= member.warning then
        row.formatter:SetBreakpoints({ { threshold = 0, format = WARNING_GLYPHS },
            { threshold = member.warning + 0.001, format = "" } })
    end
    local filters = Filters(member, true)
    if not row.expiryReady then
        -- A single slot owns the duration text for this lane. Its sibling group
        -- collapses when no finite aura matches, covering any retired glyphs.
        AddGroup(container, filters)
        container:AddAuraSlot("Warning", "HELPFUL", {
            candidateFilters = filters,
            sortMethod = AuraContainerSortMethod.ExpirationOnly, sortDirection = AuraContainerSortDirection.Reverse,
            initializeFrame = function(button)
                button:EnableMouse(false)
                local gate = Label(button, "", 20)
                gate:SetPoint("TOPLEFT", cell, "TOPLEFT", MASK_LEFT, MASK_TOP)
                gate:SetWordWrap(false)
                gate:SetAlpha(0)
                button:SetDurationText(gate, { textFormatter = row.formatter })
                -- These masks anchor to the native gate at creation. Their
                -- artwork and labels belong to Suite and can be updated later.
                row.expiryArt = self:Visuals(record, WarningClip(PresentClip(row.display, container), gate),
                    WarningClip(PresentClip(row.tooltip, container), gate))
                if type(button.SetDurationCooldown) == "function" then
                    local clip = Clip(WarningClip(button, gate))
                    clip:SetAllPoints(row.clock)
                    local cooldown = CreateFrame("Cooldown", nil, clip, "CooldownFrameTemplate")
                    cooldown:SetAllPoints(row.clock)
                    cooldown:EnableMouse(false)
                    cooldown:SetDrawSwipe(false)
                    cooldown:SetDrawEdge(false)
                    cooldown:SetDrawBling(false)
                    cooldown:SetHideCountdownNumbers(false)
                    if cooldown.SetMinimumCountdownDuration then cooldown:SetMinimumCountdownDuration(0) end
                    if cooldown.SetCountdownMillisecondsThreshold then cooldown:SetCountdownMillisecondsThreshold(0) end
                    cooldown:Show()
                    if not pcall(button.SetDurationCooldown, button, cooldown) then cooldown:Hide() end
                end
            end,
        })
        row.expiryReady = true
    elseif not SameIDs(member.ids, row.expiryIDs) then
        container:SetAuraGroupCandidateFilters("Buff", filters)
        container:SetAuraSlotCandidateFilters("Warning", filters)
    end
    row.expiryUnit, row.expiryIDs, row.warning = member.unit, member.ids, member.warning
    container:SetEnabled(true)
end

local function HideRow(row)
    row.display:Hide()
    row.tooltip:Hide()
    if row.presence then row.presence:SetEnabled(false) end
    if row.expiry then row.expiry:SetEnabled(false) end
end

local function PlaceArt(art, member, record, row)
    art.chip:SetSize(record.size, record.size)
    art.plate:SetSize(record.size, record.size)
    art.icon:SetSize(record.size - 4, record.size - 4)
    art.icon:SetTexture(record.descriptor.spell.icon)
    art.name:SetText(member.name)
    art.name:ClearAllPoints()
    art.name:SetPoint("TOPLEFT", record.tooltip, "TOPLEFT", 4, -20 - (row - 1) * LINE)
end

function Combat:Build(descriptor, size, index, signature)
    -- Pool by concurrent display slot and recipient count, independent of
    -- character names, aura filters, warning time and icon size.
    local record = self.pool[index]
    if record and record.signature == signature and record.size == size then return record end
    if not record then
        record = { rangeGates = {} }
        self.pool[index] = record
        local cell = CreateFrame("Frame", nil, self.frame, CLIP)
        record.cell = cell
        cell:Hide()
        local tooltip = CreateFrame("Frame", nil, cell, "BackdropTemplate," .. CLIP)
        record.tooltip = tooltip
        cell:SetScript("OnHide", function() tooltip:Hide() end)
        tooltip:SetFrameStrata("TOOLTIP")
        tooltip:EnableMouse(false)
        tooltip:SetClipsChildren(true)
        tooltip:SetPoint("TOP", cell, "BOTTOM", 0, -6)
        record.title = Label(tooltip, "", 11)
        record.title:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 4, -6)
        record.measure = Label(tooltip, "", 10)
        record.measure:SetAlpha(0)
        tooltip:SetScript("OnShow", function() tooltip:SetSize(record.tipWidth, record.tipHeight) end)
        tooltip:SetScript("OnHide", function() tooltip:SetSize(0, 0) end)
        tooltip:SetSize(0, 0)
        tooltip:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        tooltip:SetBackdropColor(0.035, 0.05, 0.065, 0.94)
        Suite.Theme:Backdrop(tooltip, 0.45)
        tooltip:Hide()
    end

    record.descriptor, record.size, record.signature = descriptor, size, nil
    record.cell:SetSize(size, size + 14)
    record.title:SetText(descriptor.spell.name)
    local titleWidth = Call(record.title.GetUnboundedStringWidth, record.title)
    local textWidth = Number(titleWidth) and titleWidth or 120
    for _, member in ipairs(descriptor.members) do
        record.measure:SetText(member.name)
        local width = Call(record.measure.GetUnboundedStringWidth, record.measure)
        if Number(width) then textWidth = math.max(textWidth, width) end
    end
    record.tipWidth = math.min(PLANE, math.max(100, math.ceil(textWidth) + 8))
    record.tipHeight = 32 + #descriptor.members * LINE

    local ok, failure = pcall(function()
        for index, member in ipairs(descriptor.members) do
            local row = record.rangeGates[index]
            if not row then
                local display = CreateFrame("Frame", nil, record.cell, CLIP)
                local tipGate = CreateFrame("Frame", nil, record.tooltip, CLIP)
                display:EnableMouse(false)
                tipGate:EnableMouse(false)
                row = { display = display, tooltip = tipGate }
                record.rangeGates[index] = row
            end
            self:PreparePresence(record, row, member)
            PlaceArt(row.missingArt, member, record, index)
            Suite.MissingBuffs:Hotkey(row.cooldownPlate, member.spellID or descriptor.spell.id)
            row.unit, row.ids = member.unit, member.ids
            local expiry = false
            if member.warning > 0 and not self.soonUnavailable then
                local ready, reason = pcall(self.PrepareExpiry, self, record, row, member)
                if ready then
                    expiry = true
                    PlaceArt(row.expiryArt, member, record, index)
                    local clockSize = (member.unit == "player" or #descriptor.members == 1) and size - 4 or 0
                    row.clock:SetSize(clockSize, clockSize)
                else
                    self.soonUnavailable = true
                    self.expiryFailure = Read(reason, "string") and reason:sub(1, 240) or "Native expiry binding unavailable"
                end
            end
            if row.expiryArt then
                row.expiryArt.display:SetShown(expiry)
                row.expiryArt.tooltip:SetShown(expiry)
            end
            if row.expiry and not expiry then row.expiry:SetEnabled(false) end
        end
    end)
    if not ok then
        for _, row in ipairs(record.rangeGates) do HideRow(row) end
        record.cell:Hide()
        self.failure = Read(failure, "string") and failure:sub(1, 240) or "Native aura setup unavailable"
        return
    end
    for index = #descriptor.members + 1, #record.rangeGates do HideRow(record.rangeGates[index]) end
    record.signature = signature
    record.cell:Show()
    return record
end

function Combat:Place()
    if not self.frame or InCombatLockdown() then return end
    -- Weapon/fallback reminders occupy their own independently centered row.
    local total = self.count or 0
    local width, height, size, stride, rowStride = Suite.MissingBuffs:BarLayout(total)
    if total > 0 and self.records[self.order[1]].size ~= size then self:Prepare(); return end
    self.frame:SetSize(width, height)
    for index, key in ipairs(self.order or {}) do
        local record = self.records[key]
        local slot = index - 1
        local row = math.floor(slot / 8)
        local rowCount = math.min(8, total - row * 8)
        local rowWidth = rowCount * stride - 9
        local cellX, cellY = (width - rowWidth) / 2 + slot % 8 * stride, -25 - row * rowStride
        record.cell:ClearAllPoints()
        record.cell:SetPoint("TOPLEFT", self.frame, "TOPLEFT", cellX, cellY)
    end
    Suite.MissingBuffs:Place(self.frame)
end

function Combat:Prepare()
    if InCombatLockdown() then return end
    if Suite.BuffSettings and Suite.BuffSettings.sliding then self.layoutPending = true; return end
    self.layoutPending, self.metadataDirty, self.suspended = nil, nil, nil
    local previousFailures = self.failed
    self.failed, self.records, self.coverage, self.order, self.count = {}, {}, {}, {}, 0
    if self.frame then self.frame:Hide() end
    if Enabled() then
        if C_AddOns and type(C_AddOns.LoadAddOn) == "function" then pcall(C_AddOns.LoadAddOn, "Blizzard_AuraContainer") end
        if Read(CustomAuraContainerAuraProcessingPolicy, "table") and Read(AuraContainerSortMethod, "table")
            and Read(AuraContainerSortDirection, "table") then
            local descriptors = self:Descriptors()
            if not self.frame then
                self.frame = CreateFrame("Frame", nil, UIParent, CLIP)
                self.frame:SetFrameStrata("MEDIUM"); self.frame:Hide(); self.frame:EnableMouse(false)
            end
            local _, size = Suite.MissingBuffs:DisplayOptions()
            for _, descriptor in ipairs(descriptors) do
                local signature = Signature(descriptor)
                local record
                if not previousFailures[signature] then record = self:Build(descriptor, size, self.count + 1, signature) end
                if record then
                    self.count = self.count + 1
                    self.records[descriptor.key], self.coverage[descriptor.key], self.order[self.count] = record, true, descriptor.key
                else
                    self.failed[signature] = true
                end
            end
        end
    end
    for index = self.count + 1, #self.pool do
        local record = self.pool[index]
        record.signature = nil
        record.cell:Hide()
        for _, row in ipairs(record.rangeGates) do HideRow(row) end
    end
    self:Place()
end

function Combat:UpdateBindingLabels()
    for _, key in ipairs(self.order or {}) do
        local record=self.records[key]
        for row, member in ipairs(record.descriptor.members) do
            local plate=record.rangeGates[row].cooldownPlate
            if plate then Suite.MissingBuffs:Hotkey(plate,member.spellID or record.descriptor.spell.id) end
        end
    end
end

function Combat:UpdateCooldowns(cooldownEvent, rebind)
    for _, key in ipairs(self.order or {}) do
        local record = self.records[key]
        for row, member in ipairs(record.descriptor.members) do
            local plate = record.rangeGates[row].cooldownPlate
            if plate then Timers:UpdateCooldown(plate, member.spellID or record.descriptor.spell.id, nil, cooldownEvent, rebind) end
        end
    end
end

function Combat:RefreshVisibility(event)
    if InCombatLockdown() then self:SetPreview(false) end
    if not self.frame then return end
    if InCombatLockdown() then
        if event == "PLAYER_ENTERING_WORLD" then
            self.suspended = true
        elseif event == "GROUP_ROSTER_UPDATE" or event == "UNIT_CONNECTION" then
            -- Notifications do not imply that a prepared unit token changed.
            -- Only public identity is checked here, never aura/display state.
            for _, key in ipairs(self.order or {}) do
                for _, member in ipairs(self.records[key].descriptor.members) do
                    local guid = Call(UnitGUID, member.unit)
                    if not Read(guid, "string") or guid ~= member.guid then self.suspended = true end
                end
            end
        end
    end
    local allowed = InCombatLockdown() and Enabled() and not self.suspended and (self.count or 0) > 0
        and Call(UnitIsDeadOrGhost, "player") == false
    for _, key in ipairs(self.order or {}) do
        local record = self.records[key]
        for row, member in ipairs(record.descriptor.members) do
            local visible = member.unit == "player" or Call(UnitExists, member.unit) == true
                and Call(UnitIsConnected, member.unit) == true and Call(UnitIsVisible, member.unit) == true
                and Call(UnitIsDeadOrGhost, member.unit) == false and Call(UnitCanAssist, "player", member.unit) == true
                and Call(C_Spell and C_Spell.IsSpellInRange, member.spellID or record.descriptor.spell.id, member.unit) == true
            local gates = record.rangeGates[row]
            gates.display:SetShown(allowed and visible)
            gates.tooltip:SetShown(allowed and visible)
        end
    end
    -- The host is transparent, contains no protected widgets and has no input.
    -- Its visibility is driven by public context only, never aura display state.
    self.frame:SetShown(allowed == true)
    if allowed and event == "PLAYER_REGEN_DISABLED" then self:UpdateCooldowns(false, true) end
end

function Combat:Apply()
    if InCombatLockdown() then self.suspended = true end
    self:RefreshVisibility()
    Suite.AfterCombat("combatBuffs", function() self:Prepare() end)
end

function Combat:Status()
    Suite.Print("Combat buff families prepared: " .. tostring(self.count or 0) .. ".")
    local names = {}
    for _, key in ipairs(self.order or {}) do
        local record = self.records[key]
        if record then names[#names + 1] = record.descriptor.spell.name end
    end
    Suite.Print("Aura slots: " .. (#names > 0 and table.concat(names, ", ") or "none") .. ".")
    local extra = Suite.BuffReminders
    local labels = extra.combatSlotLabels or {}
    Suite.Print("Additional slots reserved: " .. tostring(extra.combatSlots or 0) .. "; "
        .. (#labels > 0 and table.concat(labels, ", ") or "none") .. ".")
    Suite.Print("Layout: separate centered weapon row; native aura slots stay reserved when hidden.")
    if self.failure then Suite.Print("Native setup: " .. self.failure) end
    if self.expiryFailure then Suite.Print("Expiry display: " .. self.expiryFailure) end
end
