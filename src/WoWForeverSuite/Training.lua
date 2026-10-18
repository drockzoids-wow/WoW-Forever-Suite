local _, Suite = ...
local Training = { page = 1, offset = 0 }
Suite.Training = Training
table.insert(Suite.modules, Training)
local function Read(v, kind) return Suite.IsReadable(v) and type(v) == kind end
local function Number(v) return Read(v, "number") and v == v and v >= 0 and v < math.huge end
local function Integer(v, maximum) return Number(v) and v % 1 == 0 and v <= maximum end
local function Text(v) return Read(v, "string") and #v > 0 and #v <= 240 and not v:find("[%c|]") end
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
    local db = { position = {} }
    if Read(value, "table") then
        if Read(value.position, "table") and Read(value.position.x, "number") and Read(value.position.y, "number")
            and math.abs(value.position.x) <= 0.5 and math.abs(value.position.y) <= 0.5 then
            db.position = { x = value.position.x, y = value.position.y }
        end
        db.snapshot = self:Validate(value.snapshot)
    end
    self.db = db
    return db
end
function Training:Validate(value)
    if not Read(value, "table") or not Read(value.rows, "table") then return end
    local count = #value.rows
    if not Integer(count, 200) then return end
    local result = { rows = {}, partial = Read(value.partial, "boolean") and value.partial or false }
    if Text(value.trainer) then result.trainer = value.trainer end
    if Number(value.at) then result.at = value.at end
    if Integer(value.level, 1000) and value.level > 0 then result.level = value.level end
    for index = 1, count do
        local row = value.rows[index]
        if not Read(row, "table") or not Text(row.name) or not Read(row.state, "string")
            or row.state ~= "available" and row.state ~= "unavailable" then return end
        local entry = { name = row.name, state = row.state }
        if Text(row.rank) then entry.rank = row.rank end
        if Integer(row.level, 1000) then entry.level = row.level end
        if Read(row.otherReady, "boolean") then entry.otherReady = row.otherReady end
        if Number(row.cost) then entry.cost = row.cost else result.partial = true end
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
function Training:ReadOffers(allowEmpty)
    if InCombatLockdown() then self.pending = true; return nil, "Paused in combat; showing saved offerings." end
    if type(GetNumTrainerServices) ~= "function" or type(GetTrainerServiceInfo) ~= "function"
        or type(GetTrainerServiceCost) ~= "function" then return nil, "Trainer information is unavailable." end
    local pet = Enum and Enum.TrainerType and Enum.TrainerType.Pet
    local trainerType = Call(C_Trainer and C_Trainer.GetTrainerType)
    if not Number(pet) or not Number(trainerType) then return nil, "Trainer type is unavailable; saved offerings retained." end
    if trainerType == pet then return nil, "Pet training uses points; gold planning is unavailable." end
    local count = Call(GetNumTrainerServices)
    if not Integer(count, 1000) then return nil, "Trainer offerings are unavailable; saved list retained." end
    if count == 0 and not allowEmpty then return nil, "Waiting for trainer offerings." end
    local snapshot = { rows = {}, trainer = Call(UnitName, "npc"), at = Call(GetServerTime), level = self:CurrentLevel() }
    for index = 1, count do
        if #snapshot.rows == 200 then snapshot.partial = true; break end
        -- Exact Forever source: name, serviceType, texture, requiredLevel, subText.
        local ok, name, state, _, level, rank = pcall(GetTrainerServiceInfo, index)
        if not ok or not Text(name) or not Read(state, "string") then snapshot.partial = true
        elseif state == "available" or state == "unavailable" then
            local cost = Call(GetTrainerServiceCost, index)
            snapshot.rows[#snapshot.rows + 1] = { name = name, state = state,
                rank = Text(rank) and rank or nil, level = Integer(level, 1000) and level or nil,
                cost = Number(cost) and cost or nil, otherReady = self:OtherRequirements(index) }
            if not Number(cost) then snapshot.partial = true end
        elseif state ~= "header" and state ~= "used" then snapshot.partial = true end
    end
    if #snapshot.rows == 0 and snapshot.partial then return nil, "Offerings could not be read; saved list retained." end
    return self:Validate(snapshot)
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
    local total, covered = 0, 0
    for _, row in ipairs(rows) do
        if Number(row.cost) then
            total = total + row.cost
            if Number(money) and row.cost <= money then covered = covered + 1 end
        else partial = true end
    end
    return total, covered, partial == true
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
        self.db.snapshot, self.fresh, self.pending = snapshot, true, nil
        if self.autoPending and Suite.db.trainingAuto and #snapshot.rows > 0 then self.autoPending = nil; self:Open() end
    end
    self:Refresh()
end
function Training:Refresh()
    local frame = self.frame
    if not frame or not frame:IsShown() then return end
    local snapshot = self.db and self.db.snapshot
    local currentVisit = self.live and self.fresh
    local groups = self:Groups(snapshot, self:CurrentLevel(), not currentVisit)
    self.page = math.max(1, math.min(self.page, #groups))
    local group = groups[self.page]
    if self.groupTitle ~= group.title then self.offset = 0; self.groupTitle = group.title end
    self.offset = math.max(0, math.min(self.offset, math.max(0, #group.rows - 6)))
    local stamp = snapshot and snapshot.at and Call(date, "%m/%d %H:%M", snapshot.at)
    frame.context:SetText((self.levelNotice and "Level " .. self.levelNotice .. " · " or "") .. (currentVisit and "Current visit" or "Saved offerings") .. " · " .. (snapshot and snapshot.trainer or "No trainer recorded") .. (Text(stamp) and " · " .. stamp or ""))
    frame.status:SetText(self.message or (snapshot and (currentVisit and "Only visible trainer offerings are included."
        or "Saved offerings: confirm skills, requirements and prices at a trainer.") or "Visit a trainer with recording enabled to save skills and future levels."))
    frame.group:SetText(group.title)
    frame.pageText:SetText(self.page .. " / " .. #groups)
    frame.empty:SetText(#group.rows == 0 and (self.page == 1 and #groups > 1 and "Nothing available now. Next shows upcoming levels." or "No offerings in this group.") or "")
    for index, widget in ipairs(frame.rows) do
        local row = group.rows[index + self.offset]
        widget:SetShown(row ~= nil)
        if row then
            widget.name:SetText(row.name .. (row.rank and " · " .. row.rank or ""))
            widget.state:SetText(row.projected and "Level met · confirm at trainer" or row.state == "available" and "Available" or "Requirements apply")
            widget.cost:SetText(Money(row.cost))
            widget.cost:SetTextColor(row.state == "available" and 0.88 or 0.65, 0.91, 0.75)
        end
    end
    local money = Call(GetMoney)
    local total, covered, partial = self:Budget(group.rows, money, snapshot and snapshot.partial)
    frame.total:SetText((partial and "Known total: " or "Group total: ") .. Money(total))
    local sufficient = Number(money) and not partial and money >= total
    frame.total:SetTextColor(sufficient and 0.41 or 1, sufficient and 0.84 or 0.65, sufficient and 0.75 or 0.4)
    frame.funds:SetText("Your gold: " .. Money(money) .. " · Savings gap: " .. (Number(money) and Money(math.max(0, total - money)) or "--"))
    frame.covered:SetText(Number(money) and string.format("Gold covers %d/%d offers individually", covered, #group.rows) or "Gold coverage unavailable")
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
    frame:SetSize(500, 492); frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true); Surface(frame)
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
    frame.context = Label(frame, 11, 14, -44, 472); frame.context:SetWordWrap(false)
    frame.status = Label(frame, 11, 14, -65, 472); frame.status:SetHeight(34); frame.status:SetWordWrap(true)
    frame.group = Label(frame, 14, 14, -104, 330)
    frame.rows = {}
    for index = 1, 6 do
        local row = CreateFrame("Frame", nil, frame); row:SetSize(472, 37); row:SetPoint("TOPLEFT", 14, -130 - (index - 1) * 38)
        row.name = Label(row, 12, 0, 0, 325); row.name:SetWordWrap(false)
        row.state = Label(row, 10, 0, -17, 325)
        row.cost = Label(row, 12, 330, 0, 140); row.cost:SetJustifyH("RIGHT")
        frame.rows[index] = row
    end
    frame.empty = Label(frame, 12, 14, -145, 470)
    frame.total = Label(frame, 14, 14, -363, 472)
    frame.funds = Label(frame, 11, 14, -386, 472)
    frame.covered = Label(frame, 11, 14, -406, 472)
    frame.range = Label(frame, 10, 14, -425, 260)
    frame.previous = Button(frame, "Previous", 14, -451, 92, function() self.page = self.page - 1; self:Refresh() end)
    frame.next = Button(frame, "Next", 114, -451, 92, function() self.page = self.page + 1; self:Refresh() end)
    frame.pageText = Label(frame, 12, 225, -458, 75)
    Button(frame, "Settings", 388, -451, 98, function() Suite.GUI:OpenPage("professions") end)
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
        if levelNotice then self.page, self.offset, self.groupTitle = 1, 0, nil end
        self:Place(); self.frame:Show(); self:Refresh()
    end)
end
function Training:LevelUp(level)
    if not Integer(level, 1000) or level == 0 then return end
    self.level = level -- PLAYER_LEVEL_UP can precede UnitLevel reflecting the new level.
    if not Suite.db.trainingLevelUp then return end
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
        self.message, self.levelNotice = nil, nil
        self.page, self.offset = 1, 0
        if self.moving then self.cancelMove = true; self:StopDrag(false) end
        self:Place(); self:Queue(false)
    elseif event == "TRAINER_CLOSED" or event == "PLAYER_ENTERING_WORLD" then
        self:CancelWork()
        self.live, self.fresh, self.autoPending, self.pending = nil, nil, nil, nil
        self.message, self.levelNotice = nil, nil
        if event == "PLAYER_ENTERING_WORLD" then
            self.level, self.levelWork = nil, nil
            Suite.pending.trainingLevelUp = nil
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
        self.levelWork, self.levelNotice = nil, nil
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
    for _, event in ipairs({ "TRAINER_SHOW", "TRAINER_CLOSED", "TRAINER_UPDATE", "TRAINER_SERVICE_INFO_NAME_UPDATE", "PLAYER_MONEY", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP" }) do
        pcall(self.events.RegisterEvent, self.events, event)
    end
end
