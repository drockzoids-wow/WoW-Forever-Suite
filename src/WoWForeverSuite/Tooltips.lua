local _, Suite = ...
local Tips = { records = setmetatable({}, { __mode = "k" }), cache = {}, lastInspect = -10 }
Suite.Tooltips = Tips
table.insert(Suite.modules, Tips)

local function UnitMatches(unit, guid)
    if not Suite.IsReadable(unit) or type(unit) ~= "string" then return false end
    local currentGUID = UnitGUID(unit)
    return Suite.IsReadable(currentGUID) and currentGUID == guid
end

local function ResolveUnit(guid, fallback)
    if not Suite.IsReadable(guid) or type(guid) ~= "string" then return nil end
    -- The native GetUnit shim relies on UnitTokenFromGUID, which may miss mouseover.
    if UnitMatches("mouseover", guid) then return "mouseover" end
    if UnitMatches(fallback, guid) then return fallback end
    if UnitMatches("player", guid) then return "player" end
    local unit = UnitTokenFromGUID and UnitTokenFromGUID(guid)
    if UnitMatches(unit, guid) then return unit end
end

local function GetUnit(tooltip, data)
    if not Suite.IsReadable(data) then return nil end
    if not data and tooltip.GetPrimaryTooltipData then data = tooltip:GetPrimaryTooltipData() end
    if not Suite.IsReadable(data) then return nil end
    if data then
        if not Suite.IsReadable(data) or type(data) ~= "table" or not Suite.IsReadable(data.guid) then return nil end
        if type(data.guid) == "string" then return ResolveUnit(data.guid) end
    end
    if tooltip.GetUnit then
        local _, unit, guid = tooltip:GetUnit()
        if not Suite.IsReadable(unit) or type(unit) ~= "string" then return nil end
        if not Suite.IsReadable(guid) then return nil end
        return ResolveUnit(guid or UnitGUID(unit), unit)
    end
end

local function GetItem(tooltip, data)
    -- ShoppingTooltip uses TooltipDataHandlerMixin, without GameTooltip's GetItem shim.
    if not Suite.IsReadable(data) then return nil end
    if data then
        if type(data) ~= "table" then return nil end
        local guid = data.guid
        if Suite.IsReadable(guid) and type(guid) == "string" and C_Item and C_Item.GetItemLinkByGUID then
            local link = C_Item.GetItemLinkByGUID(guid)
            if Suite.IsReadable(link) and type(link) == "string" then return link end
        end
        local link = data.hyperlink
        if Suite.IsReadable(link) and type(link) == "string" then return link end
    end
    local id = data and data.id
    if Suite.IsReadable(id) and type(id) == "number" and id > 0 then return id end
    if tooltip.GetItem then
        local _, link = tooltip:GetItem()
        if Suite.IsReadable(link) and type(link) == "string" then return link end
    end
end

function Tips:Record(tooltip)
    local record = self.records[tooltip]
    if not record then
        record = {}
        self.records[tooltip] = record
        tooltip:HookScript("OnTooltipCleared", function()
            self:CancelInspect(tooltip)
            self.records[tooltip] = {}
        end)
        tooltip:HookScript("OnHide", function() self:CancelInspect(tooltip) end)
    end
    return self.records[tooltip]
end

function Tips:PrepareItem(tooltip, data)
    if not Suite.db or not Suite.db.itemTooltipLevels or not Suite.IsReadable(data) or type(data) ~= "table"
        or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
    local lines = data.lines
    if not Suite.IsReadable(lines) or type(lines) ~= "table" then return end
    local item = GetItem(tooltip, data)
    local info = item and Suite.Items:GetInfo(item)
    if not Suite.Items:IsEquipment(info)
        or not Suite.IsReadable(info.level) or type(info.level) ~= "number" or info.level <= 0 then return end
    local types = Enum.TooltipDataLineType
    if not types then return end
    local titleIndex, levelIndex
    for index, line in ipairs(lines) do
        if not Suite.IsReadable(line) or type(line) ~= "table" or not Suite.IsReadable(line.type)
            or not Suite.IsReadable(line.foreverSuiteItemLevel) then return end
        if line.type == types.ItemName and not titleIndex then titleIndex = index end
        if line.type == types.ItemLevel or line.foreverSuiteItemLevel then levelIndex = index end
    end
    if not titleIndex then return end
    local levelLine = { type = types.ItemLevel or types.None, leftText = string.format("Item Level %d", info.level),
        leftColor = NORMAL_FONT_COLOR, foreverSuiteItemLevel = true }
    if levelIndex then
        table.remove(lines, levelIndex)
        if levelIndex < titleIndex then titleIndex = titleIndex - 1 end
    end
    table.insert(lines, titleIndex + 1, levelLine)
    self:Record(tooltip).itemLevelPrepared = true
end

function Tips:Item(tooltip, data)
    if not Suite.db or (not Suite.db.itemTooltipLevels and not Suite.db.upgradeHints and not Suite.db.itemInventory) then return end
    if tooltip.IsForbidden and tooltip:IsForbidden() then return end
    local item = GetItem(tooltip, data)
    if not item then return end
    local record = self:Record(tooltip)
    if not record.itemDone and (Suite.db.itemTooltipLevels or Suite.db.upgradeHints) then
        local info = Suite.Items:GetInfo(item)
        if Suite.Items:IsEquipment(info) then
            record.itemDone = true
            if Suite.db.itemTooltipLevels and not record.itemLevelPrepared and Suite.IsReadable(info.level) and type(info.level) == "number" and info.level > 0 then
                tooltip:AddLine(string.format("Item Level %d", info.level), 1, 0.82, 0)
            end
            if Suite.db.upgradeHints then
                local delta, comparison = Suite.Items:UpgradeDelta(item)
                if delta then
                    local preset = Suite.Scoring.presets[Suite.db.scorePreset]
                    local text
                    if comparison.emptySlot then
                        text = comparison.weapon and ("Fills an empty equipment slot · " .. comparison.slot) or "Fills an empty equipment slot"
                    elseif comparison.preference == "ilevel" then
                        if comparison.paired then text = string.format("Higher weapon-set item level · +%.1f (%s)", delta, comparison.slot)
                        elseif comparison.weapon then text = string.format("Higher item level · +%.1f (%s)", delta, comparison.slot)
                        else text = string.format("Higher item level · +%.1f", delta) end
                    elseif comparison.weapon then
                        text = string.format("Possible weapon upgrade · +%.1f (%s; %s)", delta, preset.label, comparison.slot)
                    else text = string.format("Possible stat upgrade · +%.1f (%s)", delta, preset.label) end
                    tooltip:AddLine(text, 0.41, 0.84, 0.75)
                end
            end
        end
    end
    Suite.Inventory:AddTooltip(tooltip, item, record)
end

function Tips:EquippedLevel()
    local total, count = 0, 0
    for _, slot in ipairs({ 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }) do
        local link = GetInventoryItemLink("player", slot)
        if not Suite.IsReadable(link) then return nil end
        if link then
            local info = Suite.Items:GetInfo(link)
            if not info then return nil end
            total, count = total + info.level, count + 1
        end
    end
    if count > 0 then return total / count, count end
end

function Tips:LevelLine(tooltip, record, level)
    if not Suite.IsReadable(level) or type(level) ~= "number" or not (level > 0 and level < math.huge) then return end
    local text = string.format("%d", math.floor(level + 0.5))
    if record.levelLine then
        record.levelLine:SetText(text)
    else
        tooltip:AddDoubleLine("Item Level", text, 1, 0.82, 0, 1, 1, 1)
        local name = tooltip:GetName()
        if name then record.levelLine = _G[name .. "TextRight" .. tooltip:NumLines()] end
    end
end

function Tips:CancelInspect(tooltip)
    local request = self.inspectRequest
    if not request or (tooltip and request.tooltip ~= tooltip) then return end
    if request.timer then request.timer:Cancel(); request.timer = nil end
    if self.inflight == request then self.inflight = nil end
    self.inspectRequest = nil
end

function Tips:ScheduleInspect(request, delay)
    if self.inspectRequest ~= request or request.timer then return end
    request.timer = C_Timer.NewTimer(delay, function()
        request.timer = nil
        if self.inspectRequest == request then self:ContinueInspect(request) end
    end)
end

function Tips:ContinueInspect(request)
    if self.inspectRequest ~= request then return end
    local tooltip, record = request.tooltip, request.record
    local unit = ResolveUnit(request.guid, request.unit)
    if not Suite.db.playerItemLevel or (tooltip.IsForbidden and tooltip:IsForbidden()) or not tooltip:IsShown()
        or self.records[tooltip] ~= record or record.guid ~= request.guid or not unit
        or GetTime() >= request.expires then self:CancelInspect(); return end
    request.unit = unit
    if InCombatLockdown() then self:CancelInspect(); return end
    if InspectFrame and InspectFrame:IsShown() then self:ScheduleInspect(request, 1); return end

    if request.readyUntil then
        local level = C_PaperDollInfo.GetInspectItemLevel(unit)
        if Suite.IsReadable(level) and type(level) == "number" and level > 0 and level < math.huge then
            for key, cached in pairs(self.cache) do if GetTime() - cached.at > 120 then self.cache[key] = nil end end
            self.cache[request.guid] = { level = level, at = GetTime() }
            self:CancelInspect()
            self:LevelLine(tooltip, record, level)
            tooltip:Show()
            return
        end
        -- Item data can arrive just after INSPECT_READY. Never cache zero/missing levels.
        if GetTime() < request.readyUntil then self:ScheduleInspect(request, 0.2); return end
        request.readyUntil = nil
    end
    if self.inflight == request then self.inflight = nil end -- Our response timed out.
    if request.attempts >= 3 then self:CancelInspect(); return end
    local canInspect = CanInspect(unit)
    if not Suite.IsReadable(canInspect) or not canInspect then self:ScheduleInspect(request, 1); return end
    local wait = self.lastInspect + 3 - GetTime()
    if wait > 0 then self:ScheduleInspect(request, wait); return end
    request.attempts = request.attempts + 1
    self.lastInspect = GetTime()
    self.inflight = request
    self.sendingInspect = true
    NotifyInspect(unit)
    self.sendingInspect = nil
    if self.inflight == request then self:ScheduleInspect(request, 8) end
end

function Tips:RequestInspect(tooltip, record, unit, guid)
    if InCombatLockdown() or not NotifyInspect or not CanInspect or not C_Timer.NewTimer
        or not C_PaperDollInfo or not C_PaperDollInfo.GetInspectItemLevel then return end
    if not Suite.IsReadable(guid) or type(guid) ~= "string" then return end
    local current = self.inspectRequest
    if current and current.record == record and current.guid == guid then return end
    self:CancelInspect()
    record.guid = guid
    local request = { guid = guid, unit = unit, tooltip = tooltip, record = record, attempts = 0, expires = GetTime() + 30 }
    self.inspectRequest = request
    self:ScheduleInspect(request, 0.1)
end

function Tips:Unit(tooltip, data)
    if not Suite.db or (not Suite.db.playerItemLevel and not Suite.db.classNames) then return end
    if tooltip.IsForbidden and tooltip:IsForbidden() then return end
    local unit = GetUnit(tooltip, data)
    if not unit then return end
    local isPlayer = UnitIsPlayer(unit)
    if not Suite.IsReadable(isPlayer) or not isPlayer then return end
    local record = self:Record(tooltip)
    if Suite.db.classNames then
        local _, class = UnitClass(unit)
        local name = tooltip:GetName()
        if Suite.IsReadable(class) and class and name then
            local color = RAID_CLASS_COLORS[class]
            local line = _G[name .. "TextLeft1"]
            if color and line then
                if not record.originalColor then record.originalColor = { line:GetTextColor() }; record.nameLine = line end
                line:SetTextColor(color.r, color.g, color.b)
            end
        end
    end
    if not Suite.db.playerItemLevel then return end
    local guid = UnitGUID(unit)
    if not Suite.IsReadable(guid) or not guid then return end
    record.guid = guid
    local isSelf = UnitIsUnit(unit, "player")
    if Suite.IsReadable(isSelf) and isSelf then
        local level = self:EquippedLevel()
        if level then self:LevelLine(tooltip, record, level) end
    elseif self.cache[guid] and GetTime() - self.cache[guid].at < 120 then
        self:LevelLine(tooltip, record, self.cache[guid].level)
    else
        self:RequestInspect(tooltip, record, unit, guid)
    end
end

function Tips:Initialize()
    if self.initialized or not TooltipDataProcessor then return end
    self.initialized = true
    if TooltipDataProcessor.AddTooltipPreCall then
        TooltipDataProcessor.AddTooltipPreCall(Enum.TooltipDataType.Item, function(tooltip, data) self:PrepareItem(tooltip, data) end)
    end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data) self:Item(tooltip, data) end)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data) self:Unit(tooltip, data) end)
    self.events = CreateFrame("Frame")
    self.events:SetScript("OnEvent", function(_, event, guid)
        if event == "PLAYER_REGEN_DISABLED" then self:CancelInspect(); return end
        if event == "PLAYER_REGEN_ENABLED" then
            for tooltip, record in pairs(self.records) do
                if record.guid and not (tooltip.IsForbidden and tooltip:IsForbidden()) and tooltip:IsShown() then self:Unit(tooltip) end
            end
            return
        end
        if not Suite.IsReadable(guid) then return end
        local request = self.inflight
        if not request or request.guid ~= guid then return end
        if request.timer then request.timer:Cancel(); request.timer = nil end
        self.inflight = nil
        request.readyUntil = GetTime() + 1
        self:ContinueInspect(request)
    end)
    -- Cancel our bookkeeping if another addon or the player's Inspect window takes over.
    hooksecurefunc("NotifyInspect", function()
        if self.sendingInspect then return end
        self.lastInspect = GetTime()
        self:CancelInspect()
    end)
end

function Tips:Apply()
    Suite.pending.tooltipInitialize = nil
    if Suite.db.itemTooltipLevels or Suite.db.upgradeHints or Suite.db.playerItemLevel or Suite.db.classNames or Suite.db.itemInventory then
        if not self.initialized and InCombatLockdown() then
            Suite.AfterCombat("tooltipInitialize", function() self:Apply() end)
        else self:Initialize() end
    end
    if self.events then
        self.events:UnregisterAllEvents()
        if Suite.db.playerItemLevel then
            self.events:RegisterEvent("INSPECT_READY")
            self.events:RegisterEvent("PLAYER_REGEN_DISABLED")
            self.events:RegisterEvent("PLAYER_REGEN_ENABLED")
        else self:CancelInspect() end
    end
    if not Suite.db.classNames then
        for _, record in pairs(self.records) do
            if record.nameLine and record.originalColor then record.nameLine:SetTextColor(unpack(record.originalColor)) end
        end
    end
end
