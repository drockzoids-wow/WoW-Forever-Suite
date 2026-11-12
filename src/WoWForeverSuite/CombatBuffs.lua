local _, Suite = ...
-- All combat aura decisions stay in Blizzard's native renderer. Inverse clips
-- reveal our art/text; Lua never reads the native frames, text or their bounds.
local Combat = { records = {}, coverage = {}, durations = {}, auraIDs = {}, auraDurations = {}, failed = {} }
Suite.CombatBuffs = Combat
table.insert(Suite.modules, Combat)
local PLANE, LINE = 260, 16
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
local function TitleOffsets(total, index, size)
    local row = math.floor(index / 8)
    local rowCount = math.min(8, total - row * 8)
    return (rowCount * (size + 9) - 9 - 110) / 2 - index % 8 * (size + 9),
        24 + row * (size + 14)
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
    local roster = buffs:Roster()
    local player = roster[1]
    if not player then return descriptors end
    if buffs.bookDirty then buffs.learned, buffs.learnedComplete = buffs:Learned(); buffs.bookDirty = false end
    for _, family in ipairs(buffs:Families(player.class, buffs.learned or {})) do
        if family.spell and not family.catalog.weapon then
            local descriptor = { key = family.key, family = family, spell = family.spell, members = {} }
            for _, member in ipairs(roster) do
                local personal = not family.catalog.group or family.catalog.upkeep
                local allowed = member.unit == "player" and (personal and Suite.db.missingBuffClass or not personal and Suite.db.missingBuffSelf)
                    or member.unit ~= "player" and family.catalog.group and Suite.db.missingBuffOutgoing
                local recipient = buffs:Recipient(family, member.class)
                local spell = recipient.spell
                local inRange = member.unit == "player" or spell and Call(C_Spell and C_Spell.IsSpellInRange, spell.id, member.unit) ~= false
                if allowed and spell and inRange and (not buffs:PartyOnly(family.catalog, spell.root or spell.id) or member.party) then
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
                        unit = member.unit, guid = member.guid, name = member.name,
                        ids = self:IDs(recipient), warning = warning,
                    }
                end
            end
            if #descriptor.members > 0 then descriptors[#descriptors + 1] = descriptor end
        end
    end
    return descriptors
end

local function Signature(descriptor, size)
    local parts = { descriptor.key, descriptor.spell.id, size }
    for _, member in ipairs(descriptor.members) do
        parts[#parts + 1] = member.unit; parts[#parts + 1] = member.guid
        parts[#parts + 1] = member.name; parts[#parts + 1] = member.warning
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
        if active then Suite.MissingBuffs:Queue() end
        return
    end
    if InCombatLockdown() or not Suite.MissingBuffs.settingsVisible then return end
    Suite.MissingBuffs:SetPreview(false)
    self.previewActive = true
    self:UpdatePreview()
    if Suite.MissingBuffs.bar then Suite.MissingBuffs.bar:Hide() end
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

-- The native container's width is either 0 or PLANE. Anchor-only display
-- composition works for both states without calling GetWidth/IsShown/etc.
local function MissingClip(parent, source, anchor, x, y)
    local clip = Clip(parent)
    clip:SetPoint("TOPLEFT", source, "TOPRIGHT", x, y)
    clip:SetPoint("BOTTOMRIGHT", anchor, "TOPLEFT", x + PLANE, y - LINE)
    return clip
end

-- Each native missing/expiry mask contributes the same passive title. Thus
-- healthy coverage hides the title too, without Lua testing aura visibility.
function Combat:Title(record, parent, source, soon)
    local clip = Clip(parent)
    local x, y = record.titleX, record.titleY
    -- Native button descendants become forbidden when initializeFrame returns,
    -- including outside combat. Establish these anchors only during creation.
    if soon then
        clip:SetPoint("TOPLEFT", source, "TOPLEFT", x, y)
        clip:SetPoint("BOTTOMRIGHT", source, "BOTTOMRIGHT", x, y)
    else
        clip:SetPoint("TOPLEFT", source, "TOPRIGHT", x, y)
        clip:SetPoint("BOTTOMRIGHT", record.cell, "TOPLEFT", x + 110, y - 21)
    end
    local title = Label(clip, "Missing Buffs", 10)
    title:SetTextColor(0.88, 0.91, 0.93)
    title:SetPoint("TOP", self.frame, "TOP", 0, -6)
end

function Combat:Container(record, member, row, soon)
    local cell, size = record.cell, record.size
    local container = CreateFrame("AuraContainer", nil, cell, "CustomAuraContainerTemplate")
    record.containers[#record.containers + 1] = container
    container:SetEnabled(false); container:SetEditModePreviewEnabled(false)
    container:SetAuraProcessingPolicy(CustomAuraContainerAuraProcessingPolicy.None)
    container:SetUnit(member.unit); container:SetPoint("TOPLEFT", cell, "TOPLEFT", 0, 0)
    local tipX = (size - record.tipWidth) / 2 + 4
    local tipY = -size - 14 - 6 - 26 - (row - 1) * LINE
    if not soon then
        local iconClip = Clip(cell)
        iconClip:SetPoint("TOPLEFT", container, "TOPRIGHT", 0, 0)
        iconClip:SetPoint("BOTTOMRIGHT", cell, "TOPLEFT", PLANE, -size - 14)
        self:Chip(iconClip, record, cell)
        self:Title(record, cell, container, false)
        local nameClip = MissingClip(record.tooltip, container, cell, tipX, tipY)
        local name = Label(nameClip, member.name)
        name:SetPoint("TOPLEFT", cell, "TOPLEFT", tipX, tipY)
    end
    local options = {
        maxFrameCount = 1, candidateFilters = { includeSpellIDs = member.ids },
        layout = { elementWidth = PLANE, elementHeight = size + 14 },
        sortMethod = AuraContainerSortMethod.ExpirationOnly, sortDirection = AuraContainerSortDirection.Reverse,
        initializeFrame = function(button)
            button:EnableMouse(false); button:SetSize(PLANE, size + 14)
            if not soon then return end
            local gate = Label(button, "", size + 24)
            gate:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
            gate:SetWordWrap(false); gate:SetAlpha(0)
            local formatter = C_StringUtil.CreateNumericRuleFormatter()
            formatter:SetBreakpoints({ { threshold = 0, format = "WWWWWWWW" },
                { threshold = member.warning + 0.001, format = "" } })
            button:SetDurationText(gate, { textFormatter = formatter })
            -- Intersect the text's engine-managed bounds with native presence:
            -- an old glyph on a retired native button cannot reveal anything.
            -- Inherit this particular pooled button's visibility as well as
            -- text geometry, so retired buttons cannot leave a stale warning.
            local iconClip = Clip(button)
            iconClip:SetPoint("TOPLEFT", gate, "TOPLEFT", 0, 0)
            iconClip:SetPoint("BOTTOMRIGHT", gate, "BOTTOMRIGHT", 0, 0)
            self:Chip(iconClip, record, cell)
            self:Title(record, button, gate, true)
            local namePresence = Clip(button)
            namePresence:SetPoint("TOPLEFT", record.tooltip, "TOPLEFT", 0, 0)
            namePresence:SetPoint("BOTTOMRIGHT", record.tooltip, "BOTTOMRIGHT", 0, 0)
            local nameClip = Clip(namePresence)
            nameClip:SetPoint("TOPLEFT", gate, "TOPLEFT", tipX, tipY)
            nameClip:SetPoint("BOTTOMRIGHT", gate, "BOTTOMRIGHT", tipX, tipY)
            local name = Label(nameClip, member.name)
            name:SetPoint("TOPLEFT", cell, "TOPLEFT", tipX, tipY)
        end,
    }
    -- Permanent auras must never retain stale expiry text from a pooled button.
    if soon then options.candidateFilters.maxDuration = 864000 end
    container:AddAuraGroup("Buff", "HELPFUL", options)
    container:SetEnabled(true)
end

function Combat:Build(descriptor, size, titleX, titleY)
    local record = { descriptor = descriptor, size = size, containers = {}, titleX = titleX, titleY = titleY }
    record.cell = CreateFrame("Frame", nil, self.frame, CLIP)
    record.cell:Hide(); record.cell:SetSize(size, size + 14)
    local tooltip = CreateFrame("Frame", nil, record.cell, "BackdropTemplate," .. CLIP)
    record.tooltip = tooltip
    record.cell:SetScript("OnHide", function() tooltip:Hide() end)
    tooltip:SetFrameStrata("TOOLTIP"); tooltip:EnableMouse(false); tooltip:SetClipsChildren(true)
    tooltip:SetPoint("TOP", record.cell, "BOTTOM", 0, -6)
    local title = Label(tooltip, descriptor.spell.name, 11)
    title:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 4, -6)
    local titleWidth = Call(title.GetUnboundedStringWidth, title)
    local textWidth = Number(titleWidth) and titleWidth or 120
    -- Only public, precombat title/roster strings are measured. Bound native
    -- text and layout remain opaque; the masking plane need not size the tip.
    local measure = Label(tooltip, "", 10); measure:SetAlpha(0)
    for _, member in ipairs(descriptor.members) do
        measure:SetText(member.name)
        local width = Call(measure.GetUnboundedStringWidth, measure)
        if Number(width) then textWidth = math.max(textWidth, width) end
    end
    local tipWidth, tipHeight = math.min(PLANE, math.max(100, math.ceil(textWidth) + 8)), 32 + #descriptor.members * LINE
    record.tipWidth = tipWidth
    -- Names parented to native buttons need both native visibility and the
    -- user-controlled tooltip aperture. Never inspect either set of bounds.
    tooltip:SetScript("OnShow", function() tooltip:SetSize(tipWidth, tipHeight) end)
    tooltip:SetScript("OnHide", function() tooltip:SetSize(0, 0) end)
    tooltip:SetSize(0, 0)
    tooltip:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    tooltip:SetBackdropColor(0.035, 0.05, 0.065, 0.94); Suite.Theme:Backdrop(tooltip, 0.45)
    tooltip:Hide()
    local ok, failure = pcall(function()
        for row, member in ipairs(descriptor.members) do
            self:Container(record, member, row, false)
            if member.warning > 0 and not self.soonUnavailable then
                local before = #record.containers
                local ready, reason = pcall(self.Container, self, record, member, row, true)
                if not ready then
                    for index = before + 1, #record.containers do
                        pcall(record.containers[index].SetEnabled, record.containers[index], false)
                        record.containers[index] = nil
                    end
                    self.soonUnavailable = true
                    self.expiryFailure = Read(reason, "string") and reason:sub(1, 240) or "Native expiry binding unavailable"
                end
            end
        end
    end)
    if not ok then
        for _, container in ipairs(record.containers) do pcall(container.SetEnabled, container, false) end
        self.failure = Read(failure, "string") and failure:sub(1, 240) or "Native aura setup unavailable"
        return
    end
    return record
end

function Combat:Place()
    if not self.frame or InCombatLockdown() then return end
    -- Weapon/fallback reminders occupy their own independently centered row.
    -- Their public capacity must not shift native aura cells or the title.
    local total = self.count or 0
    local width, height, size, stride, rowStride = Suite.MissingBuffs:BarLayout(total)
    for index, key in ipairs(self.order or {}) do
        local record = self.records[key]
        local x, y = TitleOffsets(total, index - 1, size)
        if record.size ~= size or record.titleX ~= x or record.titleY ~= y then
            self:Prepare()
            return
        end
    end
    self.frame:SetSize(width, height)
    local index = 0
    for _, key in ipairs(self.order or {}) do
        local record = self.records[key]
        local row = math.floor(index / 8)
        local rowCount = math.min(8, total - row * 8)
        local rowWidth = rowCount * stride - 9
        local cellX, cellY = (width - rowWidth) / 2 + index % 8 * stride, -25 - row * rowStride
        record.cell:ClearAllPoints()
        record.cell:SetPoint("TOPLEFT", self.frame, "TOPLEFT", cellX, cellY)
        index = index + 1
    end
    Suite.MissingBuffs:Place(self.frame)
end

function Combat:Prepare()
    if InCombatLockdown() then return end
    if Suite.BuffSettings and Suite.BuffSettings.sliding then self.layoutPending = true; return end
    self.layoutPending = nil
    self.metadataDirty = nil
    self.coverage = {}; self.suspended = nil
    if self.frame then self.frame:Hide() end
    if not Enabled() then
        for _, record in pairs(self.records) do
            for _, container in ipairs(record.containers) do container:SetEnabled(false) end
        end
        return
    end
    if C_AddOns and type(C_AddOns.LoadAddOn) == "function" then pcall(C_AddOns.LoadAddOn, "Blizzard_AuraContainer") end
    if not Read(CustomAuraContainerAuraProcessingPolicy, "table") or not Read(AuraContainerSortMethod, "table")
        or not Read(AuraContainerSortDirection, "table") then return end
    local descriptors = self:Descriptors()
    if not self.frame then
        self.frame = CreateFrame("Frame", nil, UIParent, CLIP)
        self.frame:SetFrameStrata("MEDIUM"); self.frame:Hide(); self.frame:EnableMouse(false)
    end
    local _, size = Suite.MissingBuffs:DisplayOptions()
    local plans = {}
    for _, descriptor in ipairs(descriptors) do
        local signature = Signature(descriptor, size)
        if not self.failed[signature] then
            plans[#plans + 1] = { descriptor = descriptor, signature = signature }
        end
    end
    local seen, index, failed = {}, 0, false
    self.order = {}
    for slot, plan in ipairs(plans) do
        local descriptor, signature = plan.descriptor, plan.signature
        local titleX, titleY = TitleOffsets(#plans, slot - 1, size)
        local record = self.records[descriptor.key]
        if record and (record.signature ~= signature or record.titleX ~= titleX or record.titleY ~= titleY) then
            record.cell:Hide()
            for _, container in ipairs(record.containers) do container:SetEnabled(false) end
            record = nil
        end
        if not record and not self.failed[signature] then
            record = self:Build(descriptor, size, titleX, titleY)
            if not record then self.failed[signature] = true; failed = true end
        end
        if record then
            self.records[descriptor.key], record.signature = record, signature
            seen[descriptor.key], self.coverage[descriptor.key] = true, true
            self.order[#self.order + 1] = descriptor.key
            record.cell:Show()
            for _, container in ipairs(record.containers) do container:SetEnabled(true) end
            index = index + 1
        end
    end
    for key, record in pairs(self.records) do
        if not seen[key] then
            record.cell:Hide()
            for _, container in ipairs(record.containers) do container:SetEnabled(false) end
        end
    end
    self.count = index
    -- Exclude newly failed families before final layout. Each retry removes at
    -- least one failed signature, so unavailable native groups cannot loop.
    if failed then self:Prepare(); return end
    self:Place()
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
    -- The host is transparent, contains no protected widgets and has no input.
    -- Its visibility is driven by public context only, never aura display state.
    self.frame:SetShown(allowed == true)
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
