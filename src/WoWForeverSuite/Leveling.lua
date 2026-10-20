local _, Suite = ...
local Leveling = {}
Suite.Leveling = Leveling
table.insert(Suite.modules, Leveling)

local LIMIT, WIDTH, HEADER, HEIGHT = 1000000000000000, 224, 24, 142
local function Number(value, minimum, maximum)
    return Suite.IsReadable(value) and type(value) == "number" and value == value
        and value >= (minimum or -LIMIT) and value <= (maximum or LIMIT)
end
local function Integer(value, minimum, maximum)
    return Number(value, minimum, maximum) and value == math.floor(value)
end
local function Read(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function CursorEmpty()
    if type(GetCursorInfo) ~= "function" then return false end
    local ok, kind = pcall(GetCursorInfo)
    return ok and Suite.IsReadable(kind) and kind == nil
end
local function Accessible(frame)
    if not Suite.IsReadable(frame) or not frame then return false end
    if frame.IsForbidden and Read(frame.IsForbidden, frame) ~= false then return false end
    return not InCombatLockdown() or Read(frame.IsProtected, frame) == false
end
local function Duration(seconds)
    if not Number(seconds, 0) then return "--" end
    local minutes = math.floor(seconds / 60)
    if minutes >= 60 then return string.format("%dh %02dm", math.floor(minutes / 60), minutes % 60) end
    return string.format("%dm", minutes)
end
local function Compact(value)
    if not Number(value, 0) then return "--" end
    if value >= 1000000 then return string.format("%.1fm", value / 1000000) end
    if value >= 10000 then return string.format("%.1fk", value / 1000) end
    return tostring(math.floor(value))
end
local function Money(copper)
    if not Number(copper) then return "--" end
    local sign = copper < 0 and "-" or ""
    copper = math.floor(math.abs(copper))
    return string.format("%s%dg %ds %dc", sign, math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100)
end

function Leveling:Enabled()
    return Suite.db and Suite.IsReadable(Suite.db.levelingBar) and Suite.db.levelingBar == true
end

function Leveling:ValidateCheckpoint(saved)
    if not Suite.IsReadable(saved) or type(saved) ~= "table" or not Suite.IsReadable(saved.version) or saved.version ~= 1
        or not Number(saved.elapsed, 0, 315360000) or not Number(saved.xp, 0) or not Number(saved.gold) then return end
    local result = { version = 1, elapsed = saved.elapsed, xp = saved.xp, gold = saved.gold }
    for _, key in ipairs({ "xpPartial", "goldPartial", "timePartial" }) do
        if not Suite.IsReadable(saved[key]) or type(saved[key]) ~= "boolean" then return end
        result[key] = saved[key]
    end
    for _, key in ipairs({ "savedAt", "lastXP", "maxXP", "level", "lastMoney" }) do
        local value = saved[key]
        if not Suite.IsReadable(value) then return end
        if value ~= nil then
            if not Integer(value, 0) then return end
            result[key] = value
        end
    end
    if result.level and not Integer(result.level, 1, 1000) then return end
    if result.lastXP and (not result.maxXP or not result.level or result.lastXP > result.maxXP) then return end
    if not result.lastXP then result.maxXP, result.level, result.xpPartial = nil, nil, true end
    if not result.lastMoney then result.goldPartial = true end
    return result
end

function Leveling:InitializeCharacter(saved)
    saved = Suite.IsReadable(saved) and type(saved) == "table" and saved or {}
    self.db = { position = Suite.BagSpace:InitializePosition(saved.position), checkpoint = self:ValidateCheckpoint(saved.checkpoint),
        locked = Suite.IsReadable(saved.locked) and saved.locked == true or false,
        minimized = Suite.IsReadable(saved.minimized) and saved.minimized == true or false }
    return self.db
end

function Leveling:SampleMoney()
    local s = self.session
    if not s then return end
    local money = Read(GetMoney)
    if not Integer(money, 0) then
        s.lastMoney, s.goldReadable, s.goldPartial = nil, false, true
        return
    end
    if s.lastMoney ~= nil then
        local total = s.gold + money - s.lastMoney
        if Number(total) then s.gold = total else s.goldPartial = true end
    end
    s.lastMoney, s.goldReadable = money, true
end

function Leveling:SampleXP()
    local s = self.session
    if not s then return end
    local xp, maximum, level = Read(UnitXP, "player"), Read(UnitXPMax, "player"), Read(UnitLevel, "player")
    local paused = Read(IsXPUserDisabled)
    s.paused = nil
    if type(paused) == "boolean" then s.paused = paused end
    if not Integer(xp, 0) or not Integer(maximum, 0) or not Integer(level, 1, 1000) or xp > maximum then
        s.lastXP, s.maxXP, s.level, s.xpReadable, s.xpPartial = nil, nil, nil, false, true
        self.expectedLevel, self.pendingXP = nil, nil
        return
    end
    -- Level-up payloads can precede UnitLevel/UnitXP settling. Never interpret an
    -- early reset as a negative gain, nor replace the old boundary prematurely.
    if self.expectedLevel and level < self.expectedLevel
        or s.level == level and s.lastXP and (xp < s.lastXP or maximum ~= s.maxXP) then
        self.pendingXP = (self.pendingXP or 0) + 1
        s.xpReadable = false
        if self.pendingXP >= 5 then
            s.lastXP, s.maxXP, s.level, s.xpPartial = nil, nil, nil, true
            self.expectedLevel, self.pendingXP = nil, nil
        end
        return
    end
    local gain = 0
    if s.lastXP ~= nil then
        if level == s.level then gain = xp - s.lastXP
        elseif level == s.level + 1 and s.maxXP > 0 then gain = s.maxXP - s.lastXP + xp
        else s.xpPartial = true end -- Unobserved intermediate level costs are unknown.
    end
    local total = s.xp + gain
    if Number(total, 0) then s.xp = total else s.xpPartial = true end
    s.lastXP, s.maxXP, s.level, s.xpReadable = xp, maximum, level, true
    self.expectedLevel, self.pendingXP = nil, nil
end

function Leveling:Seconds()
    local s, now = self.session, Read(GetTime)
    if s and Number(s.start) and Number(now, 0) and now >= s.start then return now - s.start end
end

function Leveling:Snapshot()
    local s = self.session
    if not s then return {} end
    local v = { seconds = self:Seconds(), xpPartial = s.xpPartial, goldPartial = s.goldPartial,
        timePartial = s.timePartial, level = s.xpReadable and s.level or nil, nextState = "unavailable" }
    if s.xpReadable then v.xp = s.xp end
    if s.goldReadable then v.gold = s.gold end
    if s.xpReadable and not self.pendingXP and s.maxXP > 0 then
        v.remaining, v.percent = s.maxXP - s.lastXP, s.lastXP * 100 / s.maxXP
    end
    if Number(v.seconds, 60) then
        if v.xp then v.xpRate = v.xp * 3600 / v.seconds end
        if v.gold then v.goldRate = v.gold * 3600 / v.seconds end
    end
    if s.paused == true then v.nextState = "paused"
    elseif v.remaining ~= nil then
        if s.xpPartial or s.timePartial then v.nextState = "partial"
        elseif s.paused == nil then v.nextState = "unavailable"
        elseif not v.xpRate or v.xpRate <= 0 then v.nextState = "gathering"
        else
            local estimate = v.remaining * v.seconds / s.xp
            if Number(estimate, 0) then v.nextSeconds, v.nextState = estimate, "ready" end
        end
    end
    return v
end

function Leveling:CancelWork()
    if self.work then self.work:Cancel(); self.work = nil end
    if self.ticker then self.ticker:Cancel(); self.ticker = nil end
end

function Leveling:StartSession(restore)
    self:CancelWork()
    local saved = restore and self:ValidateCheckpoint(self.db.checkpoint)
    local s = saved or { xp = 0, gold = 0, xpPartial = false, goldPartial = false, timePartial = false }
    local now, server = Read(GetTime), Read(GetServerTime)
    local elapsed = saved and saved.elapsed or 0
    if saved then
        if Number(server, 0) and saved.savedAt and server >= saved.savedAt then elapsed = elapsed + server - saved.savedAt
        else s.timePartial = true end
    end
    s.start = Number(now, 0) and now - elapsed or nil
    self.session, self.expectedLevel, self.pendingXP, self.db.checkpoint, self.restorePending = s, nil, nil, nil, nil
    self:SampleXP(); self:SampleMoney()
    if C_Timer and type(C_Timer.NewTicker) == "function" then
        local ticker
        ticker = C_Timer.NewTicker(1, function()
            if self.ticker ~= ticker or not self.active or not self:Enabled() then return end
            if self.pendingXP then self:SampleXP() end
            self:Render()
        end)
        self.ticker = ticker
    end
    self:Render()
end

function Leveling:OnWorld(initial, reloading)
    local first = not self.worldEntered
    self.worldEntered = true
    if not self:Enabled() then
        if self.db then self.db.checkpoint = nil end
        return
    end
    local restore = first and Suite.IsReadable(initial) and initial == false
        and Suite.IsReadable(reloading) and reloading == true
    if not self.active then
        -- A reload can enter the world during combat before the owned bar may be
        -- built. Keep its checkpoint and reload decision for the deferred setup.
        if first then self.restorePending = restore end
        return
    end
    if not self.session then
        self:StartSession(restore)
    else self:SampleXP(); self:SampleMoney(); self:Render() end
end

function Leveling:SaveSession()
    if not self.active or not self.session or not self:Enabled() then return end
    self:SampleXP(); self:SampleMoney()
    local s, elapsed = self.session, self:Seconds()
    if Number(elapsed, 0, 315360000) then
        local record = { version = 1, elapsed = elapsed, xp = s.xp, gold = s.gold,
            xpPartial = s.xpPartial or self.pendingXP ~= nil, goldPartial = s.goldPartial, timePartial = s.timePartial,
            lastXP = s.lastXP, maxXP = s.maxXP, level = s.level, lastMoney = s.lastMoney }
        local server = Read(GetServerTime)
        if Integer(server, 0) then record.savedAt = server end
        if self.pendingXP then record.lastXP, record.maxXP, record.level = nil, nil, nil end
        self.db.checkpoint = self:ValidateCheckpoint(record)
    else self.db.checkpoint = nil end
    self:CancelWork()
end

function Leveling:Place()
    Suite.AfterCombat("levelingPosition", function()
        if not self.frame or self.moving then return end
        local position = Suite.BagSpace:InitializePosition(self.db.position)
        local width, height = Read(UIParent.GetWidth, UIParent), Read(UIParent.GetHeight, UIParent)
        if not Number(width, 1) or not Number(height, 1) then return end
        self.frame:ClearAllPoints()
        -- Saved coordinates retain the expanded center convention from the old bar.
        -- Always anchor by the expanded top-left so collapsing cannot move the header.
        if position.x then self.frame:SetPoint("TOPLEFT", UIParent, "CENTER", position.x * width - WIDTH / 2, position.y * height + HEIGHT / 2)
        else self.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 12, -12) end
    end)
end

function Leveling:HideTooltip()
    if self.frame and Accessible(GameTooltip) then
        local owner = Read(GameTooltip.GetOwner, GameTooltip)
        if owner and (owner == self.frame or owner == self.lockButton or owner == self.minimizeButton) then GameTooltip:Hide() end
    end
    self.hovered = nil
end

function Leveling:Tooltip(control)
    if InCombatLockdown() or self.moving or not self.active or not Accessible(GameTooltip) then return end
    local v, tip = self:Snapshot(), GameTooltip
    if control == self.lockButton or control == self.minimizeButton then
        tip:SetOwner(control, "ANCHOR_RIGHT"); tip:ClearLines()
        if control == self.lockButton then
            tip:AddLine(self.db.locked and "Unlock leveling tracker" or "Lock leveling tracker", 0.41, 0.84, 0.75)
            tip:AddLine("Locked: clicks pass through; hover details and header buttons stay available.", 0.88, 0.91, 0.93, true)
            tip:AddLine("Unlocked: drag the header to move.", 0.55, 0.65, 0.7, true)
        else
            tip:AddLine(self.db.minimized and "Expand leveling tracker" or "Minimize leveling tracker", 0.41, 0.84, 0.75)
            tip:AddLine("Minimized shows only the header. Session tracking continues.", 0.88, 0.91, 0.93, true)
        end
        tip:Show(); self.hovered = control; return
    end
    tip:SetOwner(self.frame, "ANCHOR_BOTTOM"); tip:ClearLines()
    tip:AddLine("Leveling tracker", 0.41, 0.84, 0.75)
    tip:AddLine("Elapsed: " .. Duration(v.seconds), 0.88, 0.91, 0.93)
    tip:AddLine("XP earned: " .. (v.xp and Compact(v.xp) or "--") .. (v.xpPartial and " (partial)" or ""), 0.88, 0.91, 0.93)
    tip:AddLine("Net gold: " .. Money(v.gold) .. (v.goldPartial and " (partial)" or ""), 0.88, 0.91, 0.93)
    tip:AddLine("XP remaining: " .. (v.remaining and Compact(v.remaining) or "--"), 0.88, 0.91, 0.93)
    local states = { gathering = "Rates need one minute; estimates also need earned XP.", partial = "Next-level estimate needs complete XP and time tracking.",
        paused = "XP gain is paused.", unavailable = "Next-level estimate is unavailable.", ready = "Next-level time estimates your current session pace." }
    tip:AddLine(states[v.nextState or "unavailable"], 0.55, 0.65, 0.7, true)
    tip:AddLine("Idle time counts. Gold is net change, including spending and transfers.", 0.55, 0.65, 0.7, true)
    if v.timePartial then tip:AddLine("Reload time was unavailable; time tracking is partial.", 0.55, 0.65, 0.7, true) end
    tip:AddLine(self.locked and "Locked: clicks pass through. Use the header lock to unlock."
        or "Drag the header to move. Right-click: settings. Ctrl-right-click: reset position.", 0.41, 0.84, 0.75, true)
    tip:Show(); self.hovered = self.frame
end

function Leveling:StopDrag(save)
    if not self.moving then return end
    if InCombatLockdown() then
        self.cancelMove = true
        -- Stop only the known ordinary owned frame; anchors and saving still wait.
        if Accessible(self.frame) then self.frame:StopMovingOrSizing(); self.moving = nil end
        Suite.AfterCombat("levelingMove", function() self:StopDrag(false); self.cancelMove = nil; self:Place() end)
        return
    end
    self.frame:StopMovingOrSizing(); self.moving = nil
    if save and not self.cancelMove and self.active and self:Enabled() then
        local x, y = self.frame:GetCenter()
        local scale, parentScale = Read(self.frame.GetEffectiveScale, self.frame), Read(UIParent.GetEffectiveScale, UIParent)
        local width, height = Read(UIParent.GetWidth, UIParent), Read(UIParent.GetHeight, UIParent)
        if Number(x) and Number(y) and Number(scale, 0.0001) and Number(parentScale, 0.0001)
            and Number(width, 1) and Number(height, 1) then
            local ratio = scale / parentScale
            local currentHeight = Read(self.frame.GetHeight, self.frame)
            if Number(currentHeight, HEADER, HEIGHT) then
                self.db.position = { x = math.max(-0.5, math.min(0.5, x * ratio / width - 0.5)),
                    y = math.max(-0.5, math.min(0.5, (y - (HEIGHT - currentHeight) / 2) * ratio / height - 0.5)) }
            end
        end
    end
    self.cancelMove = nil; Suite.pending.levelingMove = nil; self:Place()
end

function Leveling:ResetPosition()
    if not self.db then return end
    self:StopDrag(false); self.db.position = {}; self:Place()
end

function Leveling:ResetSession()
    if self.active and self:Enabled() and self.worldEntered then self:StartSession(false) end
end

function Leveling:SetLocked(locked)
    if not self.db or not Suite.IsReadable(locked) or type(locked) ~= "boolean" then return end
    self.db.locked = locked; self:Presentation()
end

function Leveling:SetMinimized(minimized)
    if not self.db or not Suite.IsReadable(minimized) or type(minimized) ~= "boolean" then return end
    self.db.minimized = minimized; self:Presentation()
end

function Leveling:Presentation()
    Suite.AfterCombat("levelingPresentation", function()
        if not self.frame or not self:Enabled() then return end
        local locked, minimized = self.db.locked, self.db.minimized
        if self.moving then
            if self.locked == locked and self.minimized == minimized then return end
            self:StopDrag(false)
        end
        -- Motion and click input are independent: retain OnEnter/OnLeave while
        -- locked, and leave only the two explicit header controls clickable.
        for _, surface in ipairs({ self.frame, self.header }) do
            surface:SetMouseClickEnabled(not locked); surface:SetMouseMotionEnabled(true)
        end
        self.frame:SetMovable(not locked)
        self.frame:SetHeight(minimized and HEADER or HEIGHT)
        self.body:SetShown(not minimized)
        self.locked, self.minimized = locked, minimized
        self.lockButton.shackleRight:SetShown(locked)
        Suite.Theme:Backdrop(self.lockButton, locked and 1 or 0.45)
        self.minimizeButton.label:SetText(minimized and "+" or "-")
        self:Place(); self:Render()
        local gui = Suite.GUI
        if gui and gui.page == "leveling" and gui.frame and Read(gui.frame.IsShown, gui.frame) == true then gui:Select("leveling") end
    end)
end

function Leveling:StartDrag()
    if InCombatLockdown() or not self.active or not self:Enabled() or self.locked or self.db.locked or not CursorEmpty() then return end
    self.moving, self.suppressClick = true, true; self:HideTooltip(); self.frame:StartMoving()
end

function Leveling:Build()
    if self.frame then return end
    local frame = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
    self.frame = frame
    frame:SetSize(WIDTH, HEIGHT); frame:SetFrameStrata("LOW"); frame:SetClampedToScreen(true); frame:SetMovable(true)
    frame:RegisterForClicks("RightButtonUp")
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.035, 0.05, 0.065, 0.70); Suite.Theme:Backdrop(frame, 0.7)
    local function Font(parent, size)
        local text = parent:CreateFontString(nil, "OVERLAY")
        text:SetFont("Fonts\\FRIZQT__.TTF", size, ""); text:SetWordWrap(false)
        return text
    end
    local header = CreateFrame("Button", nil, frame, "BackdropTemplate")
    self.header = header
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1); header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    header:SetHeight(HEADER - 2); header:RegisterForDrag("LeftButton"); header:RegisterForClicks("RightButtonUp")
    header:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" }); header:SetBackdropColor(0.055, 0.075, 0.09, 0.85)
    header.title = Font(header, 12); header.title:SetPoint("LEFT", 9, 0); header.title:SetWidth(WIDTH - 64)
    header.title:SetJustifyH("LEFT"); header.title:SetTextColor(0.41, 0.84, 0.75); header.title:SetText("Leveling")
    local body = CreateFrame("Frame", nil, frame)
    self.body = body
    body:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -HEADER); body:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    body:EnableMouse(false)
    self.labels, self.captions = {}, {}
    for index, title in ipairs({ "Level", "XP/hour", "Net gold/hour", "Next level", "Session" }) do
        local caption, value = Font(body, 11), Font(body, 11)
        caption:SetPoint("TOPLEFT", body, "TOPLEFT", 10, -7 - (index - 1) * 22)
        caption:SetWidth(98); caption:SetJustifyH("LEFT"); caption:SetText(title); caption:SetTextColor(0.55, 0.65, 0.7)
        value:SetPoint("TOPRIGHT", body, "TOPRIGHT", -10, -7 - (index - 1) * 22)
        value:SetWidth(100); value:SetJustifyH("RIGHT")
        self.labels[index], self.captions[index] = value, caption
    end
    local function Control(x, callback)
        local button = CreateFrame("Button", nil, header, "BackdropTemplate")
        button:SetSize(18, 18); button:SetPoint("RIGHT", header, "RIGHT", x, 0)
        button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        button:SetBackdropColor(0.035, 0.05, 0.065, 0.85); Suite.Theme:Backdrop(button, 0.45)
        button:SetMouseClickEnabled(true); button:SetMouseMotionEnabled(true); button:RegisterForClicks("LeftButtonUp")
        button:SetScript("OnClick", function() if self.active and self:Enabled() then callback() end end)
        button:SetScript("OnEnter", function() self:Tooltip(button) end)
        button:SetScript("OnLeave", function() self:HideTooltip() end)
        return button
    end
    self.minimizeButton = Control(-4, function() self:SetMinimized(not self.db.minimized) end)
    self.minimizeButton.label = Font(self.minimizeButton, 13); self.minimizeButton.label:SetPoint("CENTER")
    self.minimizeButton.label:SetTextColor(0.41, 0.84, 0.75)
    self.lockButton = Control(-26, function() self:SetLocked(not self.db.locked) end)
    local function LockPart(width, height, x, y)
        local part = self.lockButton:CreateTexture(nil, "ARTWORK")
        part:SetSize(width, height); part:SetPoint("CENTER", x, y); part:SetColorTexture(0.41, 0.84, 0.75, 1)
        return part
    end
    LockPart(8, 6, 0, -2); LockPart(1, 4, -3, 3); LockPart(6, 1, 0, 5)
    self.lockButton.shackleRight = LockPart(1, 4, 3, 3)
    local keyhole = self.lockButton:CreateTexture(nil, "OVERLAY")
    keyhole:SetSize(1, 3); keyhole:SetPoint("CENTER", 0, -2); keyhole:SetColorTexture(0.035, 0.05, 0.065, 1)
    local function MouseDown() if not self.moving then self.suppressClick = nil end end
    local function Click(_, button)
        if InCombatLockdown() or self.suppressClick or not self:Enabled() or self.locked then return end
        if button == "RightButton" then
            if Read(IsControlKeyDown) == true then self:ResetPosition()
            else self:HideTooltip(); Suite.GUI:OpenPage("leveling") end
        end
    end
    frame:SetScript("OnMouseDown", MouseDown); frame:SetScript("OnClick", Click)
    header:SetScript("OnMouseDown", MouseDown); header:SetScript("OnClick", Click)
    header:SetScript("OnDragStart", function() self:StartDrag() end)
    header:SetScript("OnDragStop", function() self:StopDrag(true) end)
    header:SetScript("OnEnter", function() self:Tooltip() end); header:SetScript("OnLeave", function() self:HideTooltip() end)
    frame:SetScript("OnEnter", function() self:Tooltip() end)
    frame:SetScript("OnLeave", function() self:HideTooltip() end)
    frame:SetScript("OnHide", function() self:HideTooltip(); self:StopDrag(false) end)
    self.events = CreateFrame("Frame")
    self.events:SetScript("OnEvent", function(_, event, value) self:OnEvent(event, value) end)
end

function Leveling:Render()
    if not self.active or not Accessible(self.frame) then return end
    local v = self:Snapshot()
    local level = v.level and tostring(v.level) or "--"
    if Number(v.percent, 0, 100) then level = level .. string.format(" (%.0f%%)", v.percent) end
    local xp = Compact(v.xpRate)
    local gold = Number(v.goldRate) and string.format("%.2fg", v.goldRate / 10000) or "--"
    if xp ~= "--" and (v.xpPartial or v.timePartial) then xp = "~" .. xp end
    if gold ~= "--" and (v.goldPartial or v.timePartial) then gold = "~" .. gold end
    local nextLevel = v.nextState == "paused" and "Paused" or v.nextSeconds and "~" .. Duration(math.max(60, math.ceil(v.nextSeconds / 60) * 60)) or "--"
    local values = { level, xp, gold, nextLevel, Duration(v.seconds) }
    for index, value in ipairs(values) do self.labels[index]:SetText(value); self.labels[index]:SetTextColor(0.8, 0.91, 0.89) end
    if self.hovered and Read(GameTooltip and GameTooltip.GetOwner, GameTooltip) == self.hovered then self:Tooltip(self.hovered) end
end

function Leveling:OnEvent(event, value)
    if not self.active or not self:Enabled() then return end
    if event == "PLAYER_REGEN_DISABLED" then self:HideTooltip(); self:StopDrag(false)
    elseif event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" then self:Place()
    elseif event == "PLAYER_MONEY" then self:SampleMoney(); self:Render()
    elseif event == "PLAYER_XP_UPDATE" or event == "UNIT_LEVEL" then
        if Suite.IsReadable(value) and value == "player" then self:SampleXP(); self:Render() end
    elseif event == "ENABLE_XP_GAIN" or event == "DISABLE_XP_GAIN" then self:SampleXP(); self:Render()
    elseif event == "PLAYER_LEVEL_UP" then
        if Integer(value, 1, 1000) then self.expectedLevel = math.max(self.expectedLevel or 0, value) end
        if self.work then return end
        local work
        work = C_Timer.NewTimer(0.05, function()
            if self.work ~= work then return end
            self.work = nil
            if self.active and self:Enabled() then self:SampleXP(); self:Render() end
        end)
        self.work = work
    end
end

function Leveling:Apply()
    if not self:Enabled() then
        self.active = false; self:CancelWork(); self:HideTooltip(); self:StopDrag(false)
        if self.events then self.events:UnregisterAllEvents() end
        Suite.pending.levelingPresentation = nil
        self.session, self.expectedLevel, self.pendingXP, self.restorePending = nil, nil, nil, nil
        if self.db then self.db.checkpoint = nil end
    end
    Suite.AfterCombat("leveling", function()
        if not self:Enabled() then if Accessible(self.frame) then self.frame:Hide() end; return end
        if not self.db then self:InitializeCharacter(nil) end
        self:Build(); self.active = true
        self.events:UnregisterAllEvents()
        for _, event in ipairs({ "PLAYER_XP_UPDATE", "UNIT_LEVEL", "PLAYER_LEVEL_UP", "PLAYER_MONEY", "ENABLE_XP_GAIN",
            "DISABLE_XP_GAIN", "PLAYER_REGEN_DISABLED", "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED" }) do self.events:RegisterEvent(event) end
        if self.worldEntered and not self.session then self:StartSession(self.restorePending == true) end
        self:Presentation(); self.frame:Show(); self:Render()
    end)
end
