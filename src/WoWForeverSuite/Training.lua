local _, Suite = ...
local Training = { page = 1, offset = 0 }
Suite.Training = Training
table.insert(Suite.modules, Training)
local function Read(v, kind) return Suite.IsReadable(v) and type(v) == kind end
local function Number(v) return Read(v, "number") and v == v and v >= 0 and v < math.huge end
local function Integer(v, maximum) return Number(v) and v % 1 == 0 and v <= maximum end
local function Text(v) return Read(v, "string") and #v > 0 and #v <= 240 and not v:find("[%c|]") end
local function Texture(value)
    if Integer(value, 2147483647) and value > 0 then return value end
    if Text(value) and value:lower():match("^interface[\\/]icons[\\/][%w_%-%.]+$")
        and not value:find("..", 1, true) then return value end
end
local function FactionTag(value)
    if Read(value, "string") and (value == "Alliance" or value == "Horde") then return value end
end
local function Call(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Money(v)
    if not Number(v) then return "--" end
    return string.format("%dg %ds %dc", math.floor(v / 10000), math.floor(v / 100) % 100, math.floor(v) % 100)
end
local function Label(parent, size, x, y, width)
    local font = parent:CreateFontString(nil, "OVERLAY")
    font:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE"); font:SetTextColor(0.88, 0.91, 0.93)
    font:SetPoint("TOPLEFT", x, y); font:SetWidth(width); font:SetJustifyH("LEFT")
    return font
end
local function Surface(frame)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.035, 0.05, 0.065, 0.96); Suite.Theme:Backdrop(frame, 0.75)
end
local function Button(parent, text, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate"); Surface(button)
    button:SetSize(width, 26); button:SetPoint("TOPLEFT", x, y)
    button.label = Label(button, 12, 8, -6, width - 12); button.label:SetText(text)
    button:SetScript("OnClick", callback)
    return button
end
function Training:Enabled() return Suite.db and Suite.db.trainingPlanner == true end
function Training:InitializeCharacter(value)
    local db = { position = {}, weapons = {} }
    if Read(value, "table") then
        if Read(value.position, "table") and Read(value.position.x, "number") and Read(value.position.y, "number")
            and math.abs(value.position.x) <= 0.5 and math.abs(value.position.y) <= 0.5 then
            db.position = { x = value.position.x, y = value.position.y }
        end
        local snapshot = self:Validate(value.snapshot)
        if snapshot and snapshot.kind == "class" then db.snapshot = snapshot
        elseif snapshot and snapshot.kind == "weapons" then db.weapons[1] = snapshot
        else db.legacy = snapshot end
        db.legacy = db.legacy or self:Validate(value.legacy)
        if Read(value.weapons, "table") and Integer(#value.weapons, 32) then
            for _, saved in ipairs(value.weapons) do
                local weapon = self:Validate(saved)
                if weapon and weapon.kind == "weapons" and #db.weapons < 32 then db.weapons[#db.weapons + 1] = weapon end
            end
        end
    end
    self.db = db
    return db
end
function Training:Validate(value)
    if not Read(value, "table") or not Read(value.rows, "table") then return end
    local count = #value.rows
    if not Integer(count, 200) then return end
    local result = { rows = {}, partial = Read(value.partial, "boolean") and value.partial or false }
    if Read(value.kind, "string") and (value.kind == "class" or value.kind == "weapons") then result.kind = value.kind end
    if Text(value.trainer) then result.trainer = value.trainer end
    if Text(value.place) then result.place = value.place end
    result.faction = FactionTag(value.faction)
    if Number(value.at) then result.at = value.at end
    if Integer(value.level, 1000) and value.level > 0 then result.level = value.level end
    for index = 1, count do
        local row = value.rows[index]
        if not Read(row, "table") or not Text(row.name) or not Read(row.state, "string")
            or row.state ~= "available" and row.state ~= "unavailable" and not (result.kind == "weapons" and row.state == "used") then return end
        local entry = { name = row.name, state = row.state }
        entry.icon = Texture(row.icon)
        if Text(row.rank) then entry.rank = row.rank end
        if Integer(row.level, 1000) then entry.level = row.level end
        if Read(row.otherReady, "boolean") then entry.otherReady = row.otherReady end
        if Number(row.cost) then entry.cost = row.cost elseif row.state ~= "used" then result.partial = true end
        result.rows[#result.rows + 1] = entry
    end
    return result
end
-- These native getters describe non-level prerequisites, not purchase affordability.
-- Unknown data stays unknown; only explicit readable failures suppress a level projection.
function Training:OtherRequirements(index)
    if type(GetTrainerServiceSkillReq) ~= "function" or type(GetTrainerServiceNumAbilityReq) ~= "function"
        or type(GetTrainerServiceAbilityReq) ~= "function" then return end
    local ok, skill, _, ready = pcall(GetTrainerServiceSkillReq, index)
    if not ok or not Suite.IsReadable(skill) then return end
    if skill ~= nil then
        if not Read(skill, "string") or not Read(ready, "boolean") then return end
        if not ready then return false end
    end
    local count = Call(GetTrainerServiceNumAbilityReq, index)
    if not Integer(count, 32) then return end
    for requirement = 1, count do
        local success, ability, met = pcall(GetTrainerServiceAbilityReq, index, requirement)
        if not success or not Text(ability) or not Read(met, "boolean") then return end
        if not met then return false end
    end
    return true
end
function Training:CurrentLevel()
    local current = Call(UnitLevel, "player")
    if not Integer(current, 1000) or current == 0 then current = nil end
    if self.level and (not current or self.level > current) then return self.level end
    return current
end
function Training:WeaponNames()
    local names, complete = {}, true
    for _, skill in ipairs(Suite.WeaponTraining.skills) do
        local name = Call(C_Spell and C_Spell.GetSpellName, skill[1])
        if Text(name) then names[name] = skill[1] else complete = false end
    end
    return names, complete
end
function Training:PlayerFaction()
    return FactionTag(Call(UnitFactionGroup, "player"))
end
function Training:WeaponFaction(snapshot)
    local faction = FactionTag(snapshot.faction)
    if faction then return faction end
    -- Older visit records may predate the faction field; only known master names establish it.
    if Text(snapshot.trainer) then
        for _, trainer in ipairs(Suite.WeaponTraining.trainers) do
            if trainer.name == snapshot.trainer then return trainer.faction end
        end
    end
end
function Training:WeaponLocation(snapshot)
    if not Read(snapshot, "table") then return end
    if Text(snapshot.trainer) then
        local faction = self:WeaponFaction(snapshot)
        for _, trainer in ipairs(Suite.WeaponTraining.trainers) do
            if trainer.name == snapshot.trainer and trainer.faction == faction then return trainer.place end
        end
    end
    if Text(snapshot.place) then return snapshot.place end
end
function Training:ReadOffers(allowEmpty)
    if InCombatLockdown() then self.pending = true; return nil, "Paused in combat; showing saved offerings." end
    if type(GetNumTrainerServices) ~= "function" or type(GetTrainerServiceInfo) ~= "function"
        or type(GetTrainerServiceCost) ~= "function" then return nil, "Trainer information is unavailable." end
    local types = Enum and Enum.TrainerType
    local trainerType = Call(C_Trainer and C_Trainer.GetTrainerType)
    if not Read(types, "table") or not Number(trainerType) or not Number(types.General) or not Number(types.Pet) then
        return nil, "Trainer type is unavailable; saved offerings retained."
    end
    if trainerType == types.Pet then return nil, "Pet training uses points; class training retained." end
    if trainerType ~= types.General then return nil, "This is not a class or weapon trainer; class training retained." end
    local count = Call(GetNumTrainerServices)
    if not Integer(count, 1000) then return nil, "Trainer offerings are unavailable; saved list retained." end
    if count == 0 and not allowEmpty then return nil, "Waiting for trainer offerings." end
    local weaponNames, namesReady = self:WeaponNames()
    local snapshot = { rows = {}, trainer = Call(UnitName, "npc"), at = Call(GetServerTime), level = self:CurrentLevel() }
    local weapon, other, uncertain = false, false, false
    for index = 1, count do
        if #snapshot.rows == 200 then snapshot.partial = true; uncertain = true; break end
        local ok, name, state, texture, level, rank = pcall(GetTrainerServiceInfo, index)
        if ok and Read(state, "string") and state == "header" then
            -- Headers do not establish trainer identity.
        elseif not ok or not Text(name) or not Read(state, "string") then snapshot.partial = true; uncertain = true
        elseif state == "available" or state == "unavailable" or state == "used" then
            if weaponNames[name] then weapon = true else other = true end
            local cost = Call(GetTrainerServiceCost, index)
            local otherReady
            if state ~= "used" then otherReady = self:OtherRequirements(index) end
            snapshot.rows[#snapshot.rows + 1] = { name = name, state = state, icon = Texture(texture),
                rank = Text(rank) and rank or nil, level = Integer(level, 1000) and level or nil,
                cost = Number(cost) and cost or nil, otherReady = otherReady }
            if not Number(cost) and state ~= "used" then snapshot.partial = true end
        else snapshot.partial = true; uncertain = true end
    end
    if uncertain or weapon and other then return nil, "Trainer skills could not be separated; saved class training retained." end
    if weapon and not other then snapshot.kind = "weapons"
    elseif other and namesReady then snapshot.kind = "class"
    elseif count == 0 and self.fresh then snapshot.kind = self.visitKind end
    if not snapshot.kind then return nil, "Waiting for readable trainer skills; saved class training retained." end
    if snapshot.kind == "class" then
        local rows = {}; for _, row in ipairs(snapshot.rows) do if row.state ~= "used" then rows[#rows + 1] = row end end
        snapshot.rows = rows
    else
        if not Text(snapshot.trainer) then return nil, "Weapon trainer name unavailable; saved locations retained." end
        snapshot.faction = self:WeaponFaction(snapshot) or self:PlayerFaction()
        local zone, subzone = Call(GetRealZoneText), Call(GetSubZoneText)
        if Text(zone) then snapshot.place = zone end
        if Text(subzone) and subzone ~= zone then snapshot.place = snapshot.place and snapshot.place .. " · " .. subzone or subzone end
        if not Text(snapshot.place) then snapshot.place = nil end
    end
    return self:Validate(snapshot)
end
function Training:SaveWeapons(snapshot)
    local records = self.db.weapons
    for index, saved in ipairs(records) do
        if saved.trainer == snapshot.trainer and saved.place == snapshot.place
            and self:WeaponFaction(saved) == self:WeaponFaction(snapshot) then records[index] = snapshot; return index end
    end
    if #records == 32 then table.remove(records, 1) end
    records[#records + 1] = snapshot
    return #records
end
function Training:WeaponGroups()
    return Suite.TrainingCatalog:WeaponGroups(self, self.recordedCosts)
end
function Training:SelectView(view)
    if not Read(view, "string") or view ~= "class" and view ~= "weapons" then return end
    self.levelWork, Suite.pending.trainingLevelUp = nil, nil
    local work = {}; self.viewWork = work
    Suite.AfterCombat("trainingView", function()
        if self.viewWork ~= work then return end
        self.viewWork = nil
        self.view, self.page, self.offset, self.groupTitle = view, 1, 0, nil
        self.levelNotice = nil
        self:Refresh()
    end)
end
function Training:Groups(snapshot, level, project)
    if snapshot and snapshot.catalog then return Suite.TrainingCatalog:Groups(snapshot, level, self.allLevels ~= false) end
    local groups, byLevel, levels = { { title = "Available now", rows = {} } }, {}, {}
    local other = { title = "Other requirements", rows = {} }
    for _, row in ipairs(snapshot and snapshot.rows or {}) do
        local group
        local unlocked = project and Number(level) and row.level and row.level <= level and row.otherReady ~= false
            and ((snapshot.level and row.level > snapshot.level) or (not snapshot.level and row.level == self.levelNotice))
        if row.state == "available" or unlocked then
            group = groups[1]
            if row.state ~= "available" then
                row = Suite.Copy(row); row.projected = true
            end
        elseif Number(level) and row.level and row.level > level then
            group = byLevel[row.level]
            if not group then
                group = { title = "Level " .. row.level, rows = {} }; byLevel[row.level] = group; levels[#levels + 1] = row.level
            end
        else group = other end
        group.rows[#group.rows + 1] = row
    end
    table.sort(levels)
    for _, required in ipairs(levels) do groups[#groups + 1] = byLevel[required] end
    if #other.rows > 0 then groups[#groups + 1] = other end
    return groups
end
function Training:Budget(rows, money, partial)
    local total, covered, offers = 0, 0, 0
    for _, row in ipairs(rows) do
        if row.state ~= "used" then
            offers = offers + 1
            if Number(row.cost) then
                total = total + row.cost
                if Number(money) and row.cost <= money then covered = covered + 1 end
            else partial = true end
        end
    end
    return total, covered, partial == true, offers
end
function Training:CancelWork()
    self.work = nil
    if self.timer then self.timer:Cancel(); self.timer = nil end
end
function Training:Queue(allowEmpty)
    if not self:Enabled() or not self.live then return end
    if InCombatLockdown() then self.pending = true; return end
    if self.work then self.work.allowEmpty = self.work.allowEmpty or allowEmpty; return end
    if not C_Timer or type(C_Timer.NewTimer) ~= "function" then self:Capture(allowEmpty); return end
    local work = { allowEmpty = allowEmpty }; self.work = work
    self.timer = C_Timer.NewTimer(0.1, function()
        if self.work ~= work then return end
        self.work, self.timer = nil, nil
        if self:Enabled() and self.live then self:Capture(work.allowEmpty) end
    end)
end
function Training:Capture(allowEmpty)
    if not self:Enabled() or not self.live then return end
    local snapshot, message = self:ReadOffers(allowEmpty)
    self.message = message
    if snapshot then
        self.visitKind, self.fresh, self.pending = snapshot.kind, true, nil
        local weaponPage
        if snapshot.kind == "class" then self.db.snapshot = snapshot else weaponPage = self:SaveWeapons(snapshot) end
        if self.autoPending and Suite.db.trainingAuto and #snapshot.rows > 0 then
            if snapshot.kind == "weapons" then
                weaponPage = nil
                for index, group in ipairs(self:WeaponGroups()) do
                    if group.snapshot.trainer == snapshot.trainer and group.snapshot.faction == snapshot.faction then weaponPage = index; break end
                end
            end
            if snapshot.kind == "class" or weaponPage then
                self.autoPending = nil; self.view, self.page = snapshot.kind, weaponPage or 1; self:Open()
            end
        end
    end
    self:Refresh()
end
function Training:CancelIcons()
    Suite.pending.trainingIcons, self.iconWork, self.classIconNames = nil, nil, nil
    if self.iconTimer then self.iconTimer:Cancel(); self.iconTimer = nil end
end
function Training:QueueIcons()
    if not C_Timer or type(C_Timer.NewTimer) ~= "function" then return end
    Suite.AfterCombat("trainingIcons", function()
        if not self.frame or not self.frame:IsShown() or self.iconTimer then return end
        local work = {}; self.iconWork = work
        self.iconTimer = C_Timer.NewTimer(0, function()
            if self.iconWork ~= work then return end
            self.iconWork, self.iconTimer = nil, nil
            if self.frame:IsShown() then
                if InCombatLockdown() then self:QueueIcons() else self:Refresh() end
            end
        end)
    end)
end
function Training:ClassIcon(row)
    local icon = Texture(row.icon)
    if icon then return icon end
    if row.spellID then return self:WeaponIcon(row.spellID) end
    -- Older snapshots have no captured texture; public name lookup is cosmetic only.
    if Text(row.name) then
        icon = Texture(Call(C_Spell and C_Spell.GetSpellTexture, row.name))
        if not icon and self.classIconNames then self.classIconNames[row.name] = true end
    end
    return icon or 134400
end
function Training:WeaponIcon(id)
    if not Integer(id, 2147483647) or id == 0 then return end
    local icon = Call(C_Spell and C_Spell.GetSpellTexture, id)
    if Integer(icon, 2147483647) and icon > 0 then return icon end
    -- Only visible catalog rows request icons; retain one request per public spell ID.
    self.iconLoads = self.iconLoads or {}
    if not self.iconLoads[id] and C_Spell and type(C_Spell.RequestLoadSpellData) == "function"
        and C_Timer and type(C_Timer.NewTimer) == "function" then
        self.iconLoads[id] = true -- Mark before the native call, which can complete synchronously.
        pcall(C_Spell.RequestLoadSpellData, id)
    end
    return 134400
end
function Training:LayoutHeader(compact)
    local frame = self.frame
    local shift = compact and 36 or 0
    local function Anchor(widget, x, y)
        widget:ClearAllPoints(); widget:SetPoint("TOPLEFT", x, y)
    end
    frame.compactHeader = compact
    frame.context:SetShown(not compact)
    Anchor(frame.group, 14, compact and -80 or -140)
    frame.group:SetWidth(compact and 472 or 330)
    Anchor(frame.status, 14, compact and -103 or -101)
    frame.status:SetHeight(compact and 18 or 34)
    if compact then frame.status:SetTextColor(0.55, 0.65, 0.7)
    else frame.status:SetTextColor(0.88, 0.91, 0.93) end
    for index, row in ipairs(frame.rows) do Anchor(row, 14, -166 + shift - (index - 1) * 38) end
    -- The outer window and footer stay fixed across Class and Weapons views.
    Anchor(frame.empty, 14, -181 + shift)
end
function Training:Refresh()
    local frame = self.frame
    if not frame or not frame:IsShown() then return end
    self.view = self.view == "weapons" and "weapons" or "class"
    local snapshot = Suite.TrainingCatalog:Snapshot(self.db and self.db.snapshot, self:CurrentLevel(), self.recordedCosts)
    local currentVisit = self.live and self.fresh and self.visitKind == "class"
    local groups = self.view == "weapons" and self:WeaponGroups() or self:Groups(snapshot, self:CurrentLevel(), not currentVisit)
    self.page = math.max(1, math.min(self.page, #groups))
    local group = groups[self.page]
    if self.view == "weapons" then
        snapshot = group.snapshot
        currentVisit = self.live and self.fresh and self.visitKind == "weapons" and not snapshot.reference
            and snapshot.trainer == Call(UnitName, "npc")
    end
    local reference = snapshot and snapshot.reference == true or false
    local weapons = self.view == "weapons"
    local allLevels = not weapons and snapshot and snapshot.catalog and self.allLevels ~= false
    self.catalogPaging = allLevels
    frame.levels:SetShown(not weapons)
    frame.levels.label:SetText(allLevels and "By level" or "All levels")
    frame.prices.label:SetText(self.recordedCosts and "Costs: Recorded" or "Costs: Base")
    local compact = weapons and not (snapshot and snapshot.unavailable == true)
    if frame.compactHeader ~= compact then
        if InCombatLockdown() then
            Suite.AfterCombat("trainingHeader", function() if frame:IsShown() then self:Refresh() end end)
            return
        end
        Suite.pending.trainingHeader = nil
        self:LayoutHeader(compact)
    end
    if not InCombatLockdown() then
        for view, tab in pairs({ class = frame.classTab, weapons = frame.weaponsTab }) do
            Suite.Theme:Backdrop(tab, view == self.view and 1 or 0.35)
        end
    end
    if self.groupTitle ~= group.title then self.offset = 0; self.groupTitle = group.title end
    self.offset = math.max(0, math.min(self.offset, math.max(0, allLevels and math.floor(math.max(0, #group.rows - 1) / 6) * 6 or #group.rows - 6)))
    local stamp = snapshot and snapshot.at and Call(date, "%m/%d %H:%M", snapshot.at)
    frame.context:SetText(snapshot and snapshot.catalog and "Built-in catalog · Levels 1–60" or compact and "" or (self.levelNotice and "Level " .. self.levelNotice .. " · " or "") .. (snapshot and snapshot.unavailable and "Faction unavailable" or currentVisit and "Current visit" or "Saved offerings") .. " · " .. (snapshot and snapshot.trainer or "No trainer recorded") .. (Text(stamp) and " · " .. stamp or ""))
    local message = not self.levelNotice and (not self.visitKind or self.visitKind == self.view) and self.message
    local place = compact and self:WeaponLocation(snapshot)
    local city, location
    if place then
        city, location = place:match("^(.-) · (.+)$")
        if not city then city = place end
    end
    frame.status:SetText(snapshot and snapshot.unavailable and "Your faction is unavailable. Weapon trainers appear once it is known."
        or compact and (location and location:gsub(", ", " - ") or "Location unavailable")
        or snapshot and snapshot.catalog and "Base costs exclude discounts. Trainer visits add recorded prices and offerings."
        or message or (snapshot and (currentVisit and "Only visible class trainer offerings are included."
        or "Saved class training: confirm skills, requirements and prices at a trainer.") or "Visit your class trainer with recording enabled to refresh this list."))
    frame.group:SetText(compact and ("|cff68d5bf" .. group.title .. "|r"
        .. (city and " |cff8ca6b3-|r |cffe6b866" .. city .. "|r" or "")) or group.title)
    if weapons then frame.group:SetTextColor(0.88, 0.91, 0.93)
    else frame.group:SetTextColor(0.41, 0.84, 0.75) end
    frame.pageText:SetText(self.page .. " / " .. #groups)
    frame.empty:SetText(#group.rows == 0 and (self.page == 1 and #groups > 1 and "Nothing available now. Next shows upcoming levels." or "No offerings in this group.") or "")
    local weaponNames = weapons and not reference and self:WeaponNames()
    if not InCombatLockdown() then self.classIconNames = not weapons and {} or nil end
    for index, widget in ipairs(frame.rows) do
        local row = group.rows[index + self.offset]
        widget:SetShown(row ~= nil)
        if not InCombatLockdown() then
            local icon
            if row then
                if weapons then icon = self:WeaponIcon(row.weaponID or (weaponNames and weaponNames[row.name]))
                else icon = self:ClassIcon(row) end
            end
            widget.icon:SetTexture(icon); widget.icon:SetShown(icon ~= nil)
        end
        if row then
            widget.name:SetText(row.name .. (row.rank and " · " .. row.rank or ""))
            if weapons then
                widget.name:SetTextColor(0.88, 0.91, 0.93); widget.state:SetTextColor(0.55, 0.65, 0.7)
                widget.state:SetText(row.state == "used" and "Already trained" or row.state == "reference" and "Level " .. row.level .. " · Base price" or row.state == "available" and "Available" or "Requirements apply")
            else
                widget.name:SetTextColor(0.9, 0.8, 0.55)
                local level = row.level and row.level > 0 and "|cff68d5bfLevel " .. row.level .. "|r"
                local state = row.projected and "Level met · confirm at trainer" or row.state == "available" and "Available" or "Requirements apply"
                if row.projected and level then state = level .. " met · confirm at trainer"
                elseif level then state = level .. " · " .. state end
                widget.state:SetText(state)
                if row.state == "available" and not row.projected then widget.state:SetTextColor(0.65, 0.91, 0.75)
                else widget.state:SetTextColor(0.9, 0.72, 0.4) end
            end
            widget.data = row
            if row.catalog then
                local state = row.state == "used" and "Trained" or row.requirement or row.state == "available" and "Level met" or row.level and snapshot.level and row.level > snapshot.level and "Upcoming" or "Confirm requirements"
                widget.state:SetText((row.level and "L" .. row.level .. " · " or "") .. state .. " · " .. (row.priceLabel or "Base price"))
            elseif weapons and row.weaponID then
                widget.state:SetText("L" .. row.level .. " · " .. Suite.TrainingCatalog:WeaponState(row.weaponID))
            end
            widget.cost:SetText(Money(row.cost))
            widget.cost:SetTextColor(row.state == "available" and 0.88 or 0.65, 0.91, 0.75)
        end
    end
    local money = Call(GetMoney)
    local total, covered, partial, offerCount = self:Budget(group.rows, money, snapshot and snapshot.partial)
    local totalLabel = partial and "Known total: " or "Group total: "
    if snapshot and snapshot.catalog then totalLabel = partial and "Known group cost: " or "Group cost: " end
    if weapons and not currentVisit then totalLabel = partial and "Known saved total: " or "Saved total: " end
    frame.total:SetText(reference and (self.recordedCosts and "Recorded prices where available; otherwise base" or "Reference base prices") or totalLabel .. Money(total))
    local sufficient = Number(money) and not partial and money >= total
    frame.total:SetTextColor(sufficient and 0.41 or 1, sufficient and 0.84 or 0.65, sufficient and 0.75 or 0.4)
    frame.funds:SetText(reference and "Your class and known skills determine what can be trained." or "Your gold: " .. Money(money) .. " · Savings gap: " .. (Number(money) and Money(math.max(0, total - money)) or "--"))
    frame.covered:SetText(snapshot and snapshot.catalog and "Reference catalog; talents, skills and trainer availability apply." or reference and "Wands, Unarmed and Defense are automatic. Dual Wield is class training." or Number(money) and string.format("Gold covers %d/%d offers individually", covered, offerCount) or "Gold coverage unavailable")
    frame.range:SetText(#group.rows > 6 and string.format("%d–%d of %d · Scroll", self.offset + 1, math.min(self.offset + 6, #group.rows), #group.rows) or "")
    if allLevels then
        frame.pageText:SetText(math.floor(self.offset / 6) + 1 .. " / " .. math.max(1, math.ceil(#group.rows / 6)))
        frame.previous:SetEnabled(self.offset > 0); frame.next:SetEnabled(self.offset + 6 < #group.rows)
    else frame.previous:SetEnabled(self.page > 1); frame.next:SetEnabled(self.page < #groups) end
end
function Training:StopDrag(save)
    if not self.moving then return end
    if InCombatLockdown() then self.cancelMove = true; return end
    self.frame:StopMovingOrSizing(); self.moving = nil
    if save and not self.cancelMove then
        local x, y = self.frame:GetCenter(); local ux, uy = UIParent:GetCenter()
        local w, h = UIParent:GetWidth(), UIParent:GetHeight()
        if Number(x) and Number(y) and Number(ux) and Number(uy) and Number(w) and Number(h) and w > 0 and h > 0 then
            self.db.position = { x = math.max(-0.5, math.min(0.5, (x - ux) / w)), y = math.max(-0.5, math.min(0.5, (y - uy) / h)) }
        end
    end
    self.cancelMove = nil; self:Place()
end
function Training:TrainerFrame()
    local trainer = ClassTrainerFrame
    if not Suite.IsReadable(trainer) or not trainer then return end
    if trainer.IsForbidden and Call(trainer.IsForbidden, trainer) ~= false then return end
    local visible = trainer.IsVisible or trainer.IsShown
    if Call(visible, trainer) == true then return trainer end
end
-- The modern spellbook announces its own visibility, including tab switches.
-- Observe that public callback without replacing native scripts or loading the panel.
local SPELLBOOK_SHOW = "PlayerSpellsFrame.SpellBookFrame.Show"
local SPELLBOOK_HIDE = "PlayerSpellsFrame.SpellBookFrame.Hide"
function Training:SpellbookFrame()
    local parent = _G.PlayerSpellsFrame
    if not Read(parent, "table") then return end
    if parent.IsForbidden and Call(parent.IsForbidden, parent) ~= false then return end
    local book = parent.SpellBookFrame
    if not Read(book, "table") then return end
    if book.IsForbidden and Call(book.IsForbidden, book) ~= false then return end
    if Call(book.IsVisible, book) == true then return parent end
end
function Training:EndSpellbook()
    self.spellbookVisit, Suite.pending.trainingSpellbook = nil, nil
    local owned = self.spellbookOwner
    self.spellbookOwner = nil
    if owned and self.frame then self.frame:Hide(); self:Place() end
end
function Training:SpellbookShown()
    if not self:Enabled() or not Suite.db.trainingSpellbook then return end
    local parent = self:SpellbookFrame()
    if not parent or self.spellbookVisit then return end
    local visit = {}; self.spellbookVisit = visit
    Suite.AfterCombat("trainingSpellbook", function()
        if self.spellbookVisit ~= visit or not self:Enabled() or not Suite.db.trainingSpellbook
            or self:SpellbookFrame() ~= parent then return end
        -- A manually opened planner keeps its selected view and independent lifetime.
        if self.frame and self.frame:IsShown() then return end
        self:Open(nil, visit)
    end)
end
function Training:SyncSpellbook()
    local registry = EventRegistry
    local wanted = self:Enabled() and Suite.db.trainingSpellbook and Read(registry, "table")
        and type(registry.RegisterCallback) == "function" and type(registry.UnregisterCallback) == "function"
    if wanted and self.spellbookRegistry == registry then return end
    if self.spellbookRegistry then
        self.spellbookRegistry:UnregisterCallback(SPELLBOOK_SHOW, self)
        self.spellbookRegistry:UnregisterCallback(SPELLBOOK_HIDE, self)
        self.spellbookRegistry = nil
    end
    self:EndSpellbook()
    if not wanted then return end
    self.spellbookRegistry = registry
    registry:RegisterCallback(SPELLBOOK_SHOW, self.SpellbookShown, self)
    registry:RegisterCallback(SPELLBOOK_HIDE, self.EndSpellbook, self)
    self:SpellbookShown()
end
function Training:CompanionFrame()
    return self:TrainerFrame() or (self.spellbookOwner and self:SpellbookFrame())
end
function Training:Place()
    if not self.frame or self.moving then return end
    if InCombatLockdown() then
        Suite.AfterCombat("trainingPlace", function() self:Place() end)
        return
    end
    Suite.pending.trainingPlace = nil
    local trainer = self:CompanionFrame()
    if trainer then
        local side = "RIGHT"
        local right, left = Call(trainer.GetRight, trainer), Call(trainer.GetLeft, trainer)
        local trainerScale, uiScale = Call(trainer.GetEffectiveScale, trainer), Call(UIParent.GetEffectiveScale, UIParent)
        local width, screen = Call(self.frame.GetWidth, self.frame), Call(UIParent.GetWidth, UIParent)
        if Number(right) and Number(left) and Number(trainerScale) and trainerScale > 0
            and Number(uiScale) and uiScale > 0 and Number(width) and Number(screen) then
            local ratio = trainerScale / uiScale
            if right * ratio + 8 + width > screen and left * ratio - 8 - width >= 0 then side = "LEFT" end
        end
        self.frame:ClearAllPoints()
        if side == "LEFT" then self.frame:SetPoint("TOPRIGHT", trainer, "TOPLEFT", -8, 0)
        else self.frame:SetPoint("TOPLEFT", trainer, "TOPRIGHT", 8, 0) end
        self.docked = true
        return
    end
    self.docked = nil
    local p = self.db.position
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    if not Number(width) or not Number(height) or width <= 0 or height <= 0 then return end
    self.frame:ClearAllPoints(); self.frame:SetPoint("CENTER", UIParent, "CENTER", (p.x or 0.18) * width, (p.y or 0) * height)
end
function Training:Build()
    if self.frame then return true end
    if InCombatLockdown() then return end
    local frame = CreateFrame("Frame", "WoWForeverSuiteTraining", UIParent, "BackdropTemplate")
    self.frame = frame; frame.foreverOwned = true
    frame:SetSize(500, 528); frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true); Surface(frame)
    -- Keep the window family together on native focus, with an opaque content plate.
    frame:SetToplevel(true); frame:SetBackdropColor(0.035, 0.05, 0.065, 1)
    if UISpecialFrames then table.insert(UISpecialFrames, "WoWForeverSuiteTraining") end
    local header = CreateFrame("Frame", nil, frame); header:SetPoint("TOPLEFT"); header:SetPoint("TOPRIGHT", -42, 0); header:SetHeight(36)
    header:EnableMouse(true); header:RegisterForDrag("LeftButton")
    Label(header, 17, 14, -10, 390):SetText("Training Planner")
    header:SetScript("OnDragStart", function()
        if not InCombatLockdown() and not self:CompanionFrame() then self.moving = true; frame:StartMoving() end
    end)
    header:SetScript("OnDragStop", function() self:StopDrag(true) end)
    frame.header = header
    Button(frame, "X", 460, -6, 28, function() self.autoPending = nil; frame:Hide() end)
    frame:SetScript("OnShow", function() frame:RegisterEvent("SPELL_DATA_LOAD_RESULT"); frame:RegisterEvent("SPELLS_CHANGED") end)
    frame:SetScript("OnEvent", function(_, event, id, success)
        if event == "SPELLS_CHANGED" then self:QueueIcons(); return end
        if event ~= "SPELL_DATA_LOAD_RESULT" or not Integer(id, 2147483647) or id == 0
            or not Read(success, "boolean") or not success then return end
        if self.iconLoads and self.iconLoads[id] == true then
            self.iconLoads[id] = "done"
            self:QueueIcons()
        elseif self.classIconNames then
            local name = Call(C_Spell and C_Spell.GetSpellName, id)
            if Text(name) and self.classIconNames[name] then self:QueueIcons() end
        end
    end)
    frame:SetScript("OnHide", function()
        frame:UnregisterAllEvents(); self:CancelIcons(); Suite.pending.trainingHeader = nil
        self.autoPending, self.spellbookOwner = nil, nil; self:StopDrag(false)
    end)
    frame.classTab = Button(frame, "Class", 14, -42, 110, function() self:SelectView("class") end)
    frame.weaponsTab = Button(frame, "Weapons", 130, -42, 110, function() self:SelectView("weapons") end)
    frame.compactHeader = false
    frame.context = Label(frame, 11, 14, -80, 472); frame.context:SetWordWrap(false)
    frame.status = Label(frame, 11, 14, -101, 472); frame.status:SetHeight(34); frame.status:SetWordWrap(true)
    frame.group = Label(frame, 14, 14, -140, 330)
    frame.prices = Button(frame, "Costs: Base", 254, -42, 232, function()
        self.recordedCosts = not self.recordedCosts; self:Refresh()
    end)
    frame.rows = {}
    for index = 1, 6 do
        local row = CreateFrame("Frame", nil, frame); row:SetSize(472, 37); row:SetPoint("TOPLEFT", 14, -166 - (index - 1) * 38)
        row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetSize(30, 30); row.icon:SetPoint("TOPLEFT", 0, -2); row.icon:Hide()
        row.name = Label(row, 12, 36, 0, 289); row.name:SetWordWrap(false)
        row.state = Label(row, 10, 36, -17, 289); row.state:SetTextColor(0.55, 0.65, 0.7)
        row.cost = Label(row, 12, 330, 0, 140); row.cost:SetJustifyH("RIGHT")
        row:EnableMouse(true)
        row:SetScript("OnEnter", function()
            local data = row.data
            if not data or InCombatLockdown() or not GameTooltip or type(GameTooltip.SetOwner) ~= "function"
                or type(GameTooltip.AddLine) ~= "function" or type(GameTooltip.Show) ~= "function" then return end
            GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
            GameTooltip:AddLine(data.name .. (data.rank and " · " .. data.rank or ""))
            GameTooltip:AddLine("Shown cost: " .. Money(data.cost) .. " · " .. (data.priceLabel or "Trainer price"), 0.7, 0.85, 0.8)
            for _, text in ipairs(Suite.TrainingCatalog:Details(data)) do GameTooltip:AddLine(text, 0.8, 0.8, 0.8, true) end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() if GameTooltip and type(GameTooltip.Hide) == "function" then GameTooltip:Hide() end end)
        frame.rows[index] = row
    end
    frame.empty = Label(frame, 12, 14, -181, 470)
    frame.total = Label(frame, 14, 14, -399, 472)
    frame.funds = Label(frame, 11, 14, -422, 472)
    frame.covered = Label(frame, 11, 14, -442, 472)
    frame.range = Label(frame, 10, 14, -461, 260)
    frame.previous = Button(frame, "Previous", 14, -487, 92, function() if self.catalogPaging then self.offset = math.max(0, self.offset - 6) else self.page = self.page - 1 end; self:Refresh() end)
    frame.next = Button(frame, "Next", 114, -487, 92, function() if self.catalogPaging then self.offset = self.offset + 6 else self.page = self.page + 1 end; self:Refresh() end)
    frame.pageText = Label(frame, 12, 225, -494, 75)
    frame.levels = Button(frame, "By level", 300, -487, 80, function()
        self.allLevels = self.allLevels == false; self.page, self.offset, self.groupTitle = 1, 0, nil; self:Refresh()
    end)
    frame.settings = Button(frame, "Settings", 388, -487, 98, function() Suite.GUI:OpenPage("training") end)
    frame:EnableMouseWheel(true); frame:SetScript("OnMouseWheel", function(_, delta)
        if Read(delta, "number") and not InCombatLockdown() then self.offset = self.offset - delta * (self.catalogPaging and 6 or 1); self:Refresh() end
    end)
    frame:Hide(); self:Place()
    return true
end
function Training:Open(levelNotice, spellbookVisit)
    if not spellbookVisit then
        self.spellbookVisit, self.spellbookOwner, Suite.pending.trainingSpellbook = nil, nil, nil
    end
    if not Integer(levelNotice, 1000) or levelNotice == 0 then
        levelNotice = nil
        self.levelWork, Suite.pending.trainingLevelUp = nil, nil
    end
    Suite.AfterCombat("trainingOpen", function()
        if not self.db then self:InitializeCharacter(nil) end
        if not self:Build() then return end
        self.spellbookOwner = spellbookVisit
        self.levelNotice = levelNotice
        if levelNotice or spellbookVisit then self.view, self.page, self.offset, self.groupTitle = "class", 1, 0, nil end
        self:Place(); self.frame:Show(); self.frame:Raise(); self:Refresh()
    end)
end
function Training:LevelUp(level)
    if not Integer(level, 1000) or level == 0 then return end
    self.level = level -- PLAYER_LEVEL_UP can precede UnitLevel reflecting the new level.
    if not Suite.db.trainingLevelUp then return end
    self.viewWork, self.autoPending, Suite.pending.trainingView = nil, nil, nil
    Suite.pending.trainingOpen = nil -- The latest level notice replaces an older queued manual view.
    local notice = {}; self.levelWork = notice
    Suite.AfterCombat("trainingLevelUp", function()
        if self.levelWork ~= notice or not self:Enabled() or not Suite.db.trainingLevelUp then return end
        self.levelWork = nil
        self:Open(level)
        if self.live then self:Queue(false) end
    end)
end
function Training:OnEvent(event, value)
    if not self:Enabled() then return end
    if event == "ADDON_LOADED" then self:SyncSpellbook()
    elseif event == "PLAYER_LEVEL_UP" then self:LevelUp(value)
    elseif event == "TRAINER_SHOW" then
        self:EndSpellbook()
        self:CancelWork()
        self.live, self.fresh, self.autoPending, self.pending = true, false, true, nil
        self.message, self.levelNotice, self.visitKind = nil, nil, nil
        self.page, self.offset = 1, 0
        if self.moving then self.cancelMove = true; self:StopDrag(false) end
        self:Place(); self:Queue(false)
    elseif event == "TRAINER_CLOSED" or event == "PLAYER_ENTERING_WORLD" then
        self:CancelWork()
        self.live, self.fresh, self.autoPending, self.pending = nil, nil, nil, nil
        self.message, self.levelNotice, self.visitKind = nil, nil, nil
        if event == "PLAYER_ENTERING_WORLD" then
            self:EndSpellbook()
            self.level, self.levelWork, self.viewWork = nil, nil, nil
            Suite.pending.trainingLevelUp, Suite.pending.trainingView = nil, nil
        end
        if self.frame then self.frame:Hide(); self:Place() end
    elseif event == "PLAYER_REGEN_DISABLED" then
        self:CancelWork()
        if self.moving then self.cancelMove = true end
        if self.live then self.pending = true end
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:StopDrag(false); self:Place()
        if self.pending and self.live then self:Queue(false) end
    elseif event == "PLAYER_MONEY" then self:Refresh()
    elseif self.live then self:Queue(event == "TRAINER_UPDATE" and self.fresh == true) end
end
function Training:Apply()
    if not self.db then self:InitializeCharacter(nil) end
    self:SyncSpellbook()
    if self.events then self.events:UnregisterAllEvents() end
    if not self:Enabled() then
        self:CancelWork()
        Suite.pending.trainingOpen, Suite.pending.trainingApply, Suite.pending.trainingLevelUp = nil, nil, nil
        self.levelWork, self.levelNotice, self.visitKind, self.viewWork = nil, nil, nil, nil
        Suite.pending.trainingView = nil
        self.live, self.autoPending, self.pending, self.fresh = nil, nil, nil, nil
        if self.frame then self.frame:Hide() end
        if self.moving then Suite.AfterCombat("trainingMove", function() self:StopDrag(false) end) end
        return
    end
    if InCombatLockdown() then Suite.AfterCombat("trainingApply", function() self:Apply() end); return end
    Suite.pending.trainingApply = nil
    if not Suite.db.trainingLevelUp then self.levelWork = nil; Suite.pending.trainingLevelUp = nil end
    if not self.events then
        self.events = CreateFrame("Frame")
        self.events:SetScript("OnEvent", function(_, event, ...) self:OnEvent(event, ...) end)
    end
    for _, event in ipairs({ "ADDON_LOADED", "TRAINER_SHOW", "TRAINER_CLOSED", "TRAINER_UPDATE", "TRAINER_SERVICE_INFO_NAME_UPDATE", "PLAYER_MONEY", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP", "SPELL_DATA_LOAD_RESULT" }) do
        pcall(self.events.RegisterEvent, self.events, event)
    end
end
