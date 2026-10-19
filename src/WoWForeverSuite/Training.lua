local _, Suite = ...
local Training = { page = 1, offset = 0 }
Suite.Training = Training
table.insert(Suite.modules, Training)
local function Read(v, kind) return Suite.IsReadable(v) and type(v) == kind end
local function Number(v) return Read(v, "number") and v == v and v >= 0 and v < math.huge end
local function Integer(v, maximum) return Number(v) and v % 1 == 0 and v <= maximum end
local function Text(v) return Read(v, "string") and #v > 0 and #v <= 240 and not v:find("[%c|]") end
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
    frame:SetBackdropColor(0.035, 0.05, 0.065, 0.96); frame:SetBackdropBorderColor(0.41, 0.84, 0.75, 0.75)
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
        if Text(name) then names[name] = true else complete = false end
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
        local ok, name, state, _, level, rank = pcall(GetTrainerServiceInfo, index)
        if ok and Read(state, "string") and state == "header" then
            -- Headers do not establish trainer identity.
        elseif not ok or not Text(name) or not Read(state, "string") then snapshot.partial = true; uncertain = true
        elseif state == "available" or state == "unavailable" or state == "used" then
            if weaponNames[name] then weapon = true else other = true end
            local cost = Call(GetTrainerServiceCost, index)
            local otherReady
            if state ~= "used" then otherReady = self:OtherRequirements(index) end
            snapshot.rows[#snapshot.rows + 1] = { name = name, state = state,
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
    local faction = self:PlayerFaction()
    if not faction then return { { title = "Weapon trainers", rows = {}, snapshot = { unavailable = true } } } end
    local groups, names = {}, {}
    for _, skill in ipairs(Suite.WeaponTraining.skills) do
        local name = Call(C_Spell and C_Spell.GetSpellName, skill[1])
        names[skill[1]] = Text(name) and name or skill[2]
    end
    for _, snapshot in ipairs(self.db.weapons) do
        if self:WeaponFaction(snapshot) == faction then
            groups[#groups + 1] = { title = snapshot.trainer or "Recorded weapon trainer", rows = snapshot.rows, snapshot = snapshot }
        end
    end
    for _, trainer in ipairs(Suite.WeaponTraining.trainers) do
        if trainer.faction == faction then
            local snapshot = { trainer = trainer.name, place = trainer.place, reference = true, faction = trainer.faction }
            local group = { title = trainer.name, rows = {}, snapshot = snapshot }
            for _, id in ipairs(trainer.skills) do
                group.rows[#group.rows + 1] = { name = names[id], state = "reference", cost = id == 200 and 10000 or 1000, level = id == 200 and 20 or 1 }
            end
            groups[#groups + 1] = group
        end
    end
    return groups
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
                    if group.snapshot == snapshot then weaponPage = index; break end
                end
            end
            if snapshot.kind == "class" or weaponPage then
                self.autoPending = nil; self.view, self.page = snapshot.kind, weaponPage or 1; self:Open()
            end
        end
    end
    self:Refresh()
end
function Training:Refresh()
    local frame = self.frame
    if not frame or not frame:IsShown() then return end
    self.view = self.view == "weapons" and "weapons" or "class"
    local snapshot = self.db and self.db.snapshot
    local currentVisit = self.live and self.fresh and self.visitKind == "class"
    local groups = self.view == "weapons" and self:WeaponGroups() or self:Groups(snapshot, self:CurrentLevel(), not currentVisit)
    self.page = math.max(1, math.min(self.page, #groups))
    local group = groups[self.page]
    if self.view == "weapons" then
        snapshot = group.snapshot
        currentVisit = self.live and self.fresh and self.visitKind == "weapons" and not snapshot.reference
            and snapshot.trainer == Call(UnitName, "npc")
    end
    if not InCombatLockdown() then
        for view, tab in pairs({ class = frame.classTab, weapons = frame.weaponsTab }) do
            tab:SetBackdropBorderColor(unpack(view == self.view and { 0.41, 0.84, 0.75, 1 } or { 0.17, 0.25, 0.29, 1 }))
        end
    end
    if self.groupTitle ~= group.title then self.offset = 0; self.groupTitle = group.title end
    self.offset = math.max(0, math.min(self.offset, math.max(0, #group.rows - 6)))
    local stamp = snapshot and snapshot.at and Call(date, "%m/%d %H:%M", snapshot.at)
    local reference = snapshot and snapshot.reference
    frame.context:SetText((self.levelNotice and "Level " .. self.levelNotice .. " · " or "") .. (snapshot and snapshot.unavailable and "Faction unavailable" or reference and "Reference · " .. snapshot.faction or currentVisit and "Current visit" or "Saved offerings") .. " · " .. (snapshot and snapshot.trainer or "No trainer recorded") .. (Text(stamp) and " · " .. stamp or ""))
    local message = not self.levelNotice and (not self.visitKind or self.visitKind == self.view) and self.message
    frame.status:SetText(snapshot and snapshot.unavailable and "Your faction is unavailable. Weapon trainers appear once it is known."
        or reference and snapshot.place .. "\nBase prices; confirm stock, class eligibility and discounts at the trainer."
        or self.view == "weapons" and (snapshot.place or "Location unavailable") .. "\nRecorded prices and visible skills; confirm at the trainer."
        or message or (snapshot and (currentVisit and "Only visible class trainer offerings are included."
        or "Saved class training: confirm skills, requirements and prices at a trainer.") or "Visit your class trainer with recording enabled to refresh this list."))
    frame.group:SetText(group.title)
    frame.pageText:SetText(self.page .. " / " .. #groups)
    frame.empty:SetText(#group.rows == 0 and (self.page == 1 and #groups > 1 and "Nothing available now. Next shows upcoming levels." or "No offerings in this group.") or "")
    for index, widget in ipairs(frame.rows) do
        local row = group.rows[index + self.offset]
        widget:SetShown(row ~= nil)
        if row then
            widget.name:SetText(row.name .. (row.rank and " · " .. row.rank or ""))
            widget.state:SetText(row.projected and "Level met · confirm at trainer" or row.state == "used" and "Already trained" or row.state == "reference" and "Level " .. row.level .. " · Base price" or row.state == "available" and "Available" or "Requirements apply")
            widget.cost:SetText(Money(row.cost))
            widget.cost:SetTextColor(row.state == "available" and 0.88 or 0.65, 0.91, 0.75)
        end
    end
    local money = Call(GetMoney)
    local total, covered, partial, offerCount = self:Budget(group.rows, money, snapshot and snapshot.partial)
    frame.total:SetText(reference and "Reference base prices" or (partial and "Known total: " or "Group total: ") .. Money(total))
    local sufficient = Number(money) and not partial and money >= total
    frame.total:SetTextColor(sufficient and 0.41 or 1, sufficient and 0.84 or 0.65, sufficient and 0.75 or 0.4)
    frame.funds:SetText(reference and "Your class and known skills determine what can be trained." or "Your gold: " .. Money(money) .. " · Savings gap: " .. (Number(money) and Money(math.max(0, total - money)) or "--"))
    frame.covered:SetText(reference and "Wands, Unarmed and Defense are automatic. Dual Wield is class training." or Number(money) and string.format("Gold covers %d/%d offers individually", covered, offerCount) or "Gold coverage unavailable")
    frame.range:SetText(#group.rows > 6 and string.format("%d–%d of %d · Scroll", self.offset + 1, math.min(self.offset + 6, #group.rows), #group.rows) or "")
    frame.previous:SetEnabled(self.page > 1); frame.next:SetEnabled(self.page < #groups)
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
function Training:Place()
    if not self.frame or self.moving then return end
    if InCombatLockdown() then
        Suite.AfterCombat("trainingPlace", function() self:Place() end)
        return
    end
    Suite.pending.trainingPlace = nil
    local trainer = self:TrainerFrame()
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
        if not InCombatLockdown() and not self:TrainerFrame() then self.moving = true; frame:StartMoving() end
    end)
    header:SetScript("OnDragStop", function() self:StopDrag(true) end)
    frame.header = header
    Button(frame, "X", 460, -6, 28, function() self.autoPending = nil; frame:Hide() end)
    frame:SetScript("OnHide", function() self.autoPending = nil; self:StopDrag(false) end)
    frame.classTab = Button(frame, "Class", 14, -42, 110, function() self:SelectView("class") end)
    frame.weaponsTab = Button(frame, "Weapons", 130, -42, 110, function() self:SelectView("weapons") end)
    frame.context = Label(frame, 11, 14, -80, 472); frame.context:SetWordWrap(false)
    frame.status = Label(frame, 11, 14, -101, 472); frame.status:SetHeight(34); frame.status:SetWordWrap(true)
    frame.group = Label(frame, 14, 14, -140, 330)
    frame.rows = {}
    for index = 1, 6 do
        local row = CreateFrame("Frame", nil, frame); row:SetSize(472, 37); row:SetPoint("TOPLEFT", 14, -166 - (index - 1) * 38)
        row.name = Label(row, 12, 0, 0, 325); row.name:SetWordWrap(false)
        row.state = Label(row, 10, 0, -17, 325)
        row.cost = Label(row, 12, 330, 0, 140); row.cost:SetJustifyH("RIGHT")
        frame.rows[index] = row
    end
    frame.empty = Label(frame, 12, 14, -181, 470)
    frame.total = Label(frame, 14, 14, -399, 472)
    frame.funds = Label(frame, 11, 14, -422, 472)
    frame.covered = Label(frame, 11, 14, -442, 472)
    frame.range = Label(frame, 10, 14, -461, 260)
    frame.previous = Button(frame, "Previous", 14, -487, 92, function() self.page = self.page - 1; self:Refresh() end)
    frame.next = Button(frame, "Next", 114, -487, 92, function() self.page = self.page + 1; self:Refresh() end)
    frame.pageText = Label(frame, 12, 225, -494, 75)
    Button(frame, "Settings", 388, -487, 98, function() Suite.GUI:OpenPage("professions") end)
    frame:EnableMouseWheel(true); frame:SetScript("OnMouseWheel", function(_, delta)
        if Read(delta, "number") and not InCombatLockdown() then self.offset = self.offset - delta; self:Refresh() end
    end)
    frame:Hide(); self:Place()
    return true
end
function Training:Open(levelNotice)
    if not Integer(levelNotice, 1000) or levelNotice == 0 then
        levelNotice = nil
        self.levelWork, Suite.pending.trainingLevelUp = nil, nil
    end
    Suite.AfterCombat("trainingOpen", function()
        if not self.db then self:InitializeCharacter(nil) end
        if not self:Build() then return end
        self.levelNotice = levelNotice
        if levelNotice then self.view, self.page, self.offset, self.groupTitle = "class", 1, 0, nil end
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
    if event == "PLAYER_LEVEL_UP" then self:LevelUp(value)
    elseif event == "TRAINER_SHOW" then
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
    for _, event in ipairs({ "TRAINER_SHOW", "TRAINER_CLOSED", "TRAINER_UPDATE", "TRAINER_SERVICE_INFO_NAME_UPDATE", "PLAYER_MONEY", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP", "SPELL_DATA_LOAD_RESULT" }) do
        pcall(self.events.RegisterEvent, self.events, event)
    end
end
