local _, Suite = ...
local Indicator = {}
Suite.CombatIndicator = Indicator
Suite.modules[#Suite.modules + 1] = Indicator

local function Read(callback, ...)
    if type(callback) ~= "function" then return end
    local ok, value = pcall(callback, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function Option(key)
    return Suite.db and Suite.IsReadable(Suite.db[key]) and Suite.db[key] == true
end
local function Enabled() return Option("combatIndicator") end
local function Persistent() return Option("combatIndicatorPersistent") end

function Indicator:InitializePosition(saved)
    if Suite.IsReadable(saved) and type(saved) == "table" and Number(saved.x) and Number(saved.y)
        and math.abs(saved.x) <= 0.5 and math.abs(saved.y) <= 0.5 then return { x = saved.x, y = saved.y } end
    return {}
end

function Indicator:CanPaint()
    local frame = self.frame
    return frame and Read(frame.IsForbidden, frame) == false
        and (not InCombatLockdown() or Read(frame.IsProtected, frame) == false)
end

function Indicator:Paint()
    if not self.frame then return end
    if not self:CanPaint() then
        if InCombatLockdown() then Suite.AfterCombat("combatIndicatorVisual", function() self:Paint() end) end
        return
    end
    if not self.state or not (self.preview or self.active and Enabled()) then self.frame:Hide(); return end
    local ended = self.state == "ended"
    local r, g, b = 1, 0.84, 0.28
    if ended then r, g, b = 0.48, 1, 0.60 end
    self.frame.title:SetText(ended and "COMBAT ENDED" or "IN COMBAT")
    self.frame.title:SetTextColor(r, g, b, 1)
    self.frame.accent:SetColorTexture(r, g, b, 0.8)
    self.frame:Show()
end

function Indicator:CancelTimer()
    self.work = nil
    if self.timer then self.timer:Cancel(); self.timer = nil end
end

function Indicator:Watch()
    if not self.frame then return end
    self.frame:UnregisterAllEvents()
    if not self.active and not self.preview then return end
    for _, event in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD",
        "PLAYER_LEAVING_WORLD", "PLAYER_LOGOUT" }) do self.frame:RegisterEvent(event) end
end

function Indicator:Expire()
    self:CancelTimer()
    if self.active and Enabled() and self.combat and Persistent() and not self.preview then return end
    if not C_Timer or type(C_Timer.NewTimer) ~= "function" then
        self.state, self.preview = nil, nil; self:Paint(); self:Watch(); return
    end
    local work = {}; self.work = work
    self.timer = C_Timer.NewTimer(4, function()
        if self.work ~= work then return end
        self.work, self.timer = nil, nil
        self.preview = nil
        self.state = self.active and Enabled() and self.combat and Persistent() and "combat" or nil
        self:Paint(); self:Watch()
    end)
end

function Indicator:Place()
    if not self.frame or self.moving then return end
    Suite.AfterCombat("combatIndicatorPosition", function()
        if not self.frame or self.moving then return end
        local position = self:InitializePosition(Suite.db.combatIndicatorPosition)
        local x, y = 0, 220
        if position.x then
            local width, height = Read(UIParent.GetWidth, UIParent), Read(UIParent.GetHeight, UIParent)
            if not Number(width) or not Number(height) or width <= 0 or height <= 0 then return end
            x, y = position.x * width, position.y * height
        end
        self.frame:ClearAllPoints()
        self.frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    end)
end

function Indicator:StopDrag(save)
    if not self.moving then return end
    -- Stop only our explicitly unprotected frame during combat; restore anchors later.
    if not self:CanPaint() then
        if InCombatLockdown() then Suite.AfterCombat("combatIndicatorMove", function() self:StopDrag(false) end)
        else self.moving = nil end
        return
    end
    self.frame:StopMovingOrSizing(); self.moving = nil
    if save and not InCombatLockdown() and not Option("combatIndicatorLocked") then
        local ok, x, y = pcall(self.frame.GetCenter, self.frame)
        local scale, parentScale = Read(self.frame.GetEffectiveScale, self.frame), Read(UIParent.GetEffectiveScale, UIParent)
        local width, height = Read(UIParent.GetWidth, UIParent), Read(UIParent.GetHeight, UIParent)
        if ok and Number(x) and Number(y) and Number(scale) and Number(parentScale) and scale > 0 and parentScale > 0
            and Number(width) and Number(height) and width > 0 and height > 0 then
            local nx, ny = x * scale / parentScale / width - 0.5, y * scale / parentScale / height - 0.5
            if Number(nx) and Number(ny) then
                Suite.db.combatIndicatorPosition = { x = math.max(-0.5, math.min(0.5, nx)), y = math.max(-0.5, math.min(0.5, ny)) }
            end
        end
    end
    self:Place()
    if save and not InCombatLockdown() then self:Expire() end
end

function Indicator:Build()
    if self.frame then return true end
    if InCombatLockdown() then return false end
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    self.frame = frame
    frame:Hide(); frame:SetSize(280, 44); frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true); frame:SetMovable(true); frame:RegisterForDrag("LeftButton")
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.035, 0.05, 0.065, 0.82)
    Suite.Theme:Backdrop(frame, 0.8)
    frame.accent = frame:CreateTexture(nil, "ARTWORK")
    frame.accent:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    frame.accent:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    frame.accent:SetHeight(2)
    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.title:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    frame.title:SetShadowColor(0, 0, 0, 0.9); frame.title:SetShadowOffset(1, -1)
    frame:SetScript("OnEvent", function(_, event) self:OnEvent(event) end)
    frame:SetScript("OnDragStart", function()
        if InCombatLockdown() or Option("combatIndicatorLocked") or not (self.preview or self.active and Enabled()) then return end
        if Read(frame.IsShown, frame) ~= true then return end
        self:CancelTimer(); self.moving = true; frame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function() self:StopDrag(true) end)
    frame:SetScript("OnHide", function() self:StopDrag(false) end)
    frame:SetScript("OnMouseUp", function(_, button)
        if Suite.IsReadable(button) and button == "RightButton" and not InCombatLockdown()
            and not Option("combatIndicatorLocked") and Read(IsControlKeyDown) == true then self:ResetPosition() end
    end)
    self:Place()
    return true
end

function Indicator:Configure()
    if InCombatLockdown() or not self.frame then return end
    if Option("combatIndicatorLocked") and self.moving then
        self:StopDrag(false)
        if self.preview then self:Expire() end
    end
    self.frame:EnableMouse(not Option("combatIndicatorLocked"))
    self:Place()
end

function Indicator:StopPreview()
    if not self.preview then return end
    self:StopDrag(false); self:CancelTimer()
    self.preview, self.state = nil, nil
    self:Paint(); self:Watch()
end

function Indicator:Preview()
    if InCombatLockdown() or not Suite.db or not self:Build() then return end
    self:StopDrag(false); self:Configure()
    self.preview, self.state = true, "combat"
    self:Watch(); self:Paint(); self:Expire()
end

function Indicator:ResetPosition()
    if not Suite.db or InCombatLockdown() then return end
    self:StopDrag(false)
    Suite.db.combatIndicatorPosition = {}
    self:Place()
    if self.preview then self:Expire() end
end

function Indicator:OnEvent(event)
    if event == "PLAYER_LOGOUT" then
        self.active = nil; self:StopPreview(); self:CancelTimer(); self:StopDrag(false)
        self.state, self.combat = nil, nil
        Suite.pending.combatIndicator, Suite.pending.combatIndicatorVisual = nil, nil
        self:Paint(); self:Watch(); return
    end
    if not self.active and not self.preview then return end
    if event == "PLAYER_LEAVING_WORLD" or event == "PLAYER_ENTERING_WORLD" then
        self:CancelTimer(); self:StopDrag(false)
        self.preview, self.state, self.combat = nil, nil, nil
        if event == "PLAYER_ENTERING_WORLD" and self.active and Enabled() then
            local combat = Read(InCombatLockdown)
            self.combat = combat
            if combat == true then self.state = "combat"; self:Expire() end
        end
        self:Paint(); self:Watch(); return
    end
    if event ~= "PLAYER_REGEN_DISABLED" and event ~= "PLAYER_REGEN_ENABLED" then return end
    local combat = event == "PLAYER_REGEN_DISABLED"
    if self.combat == combat and not self.preview then return end
    local wasCombat = self.combat
    self:CancelTimer(); self:StopDrag(false)
    self.preview, self.combat = nil, combat
    if not self.active or not Enabled() then self.state = nil
    elseif combat then self.state = "combat"; self:Expire()
    elseif wasCombat == true then self.state = "ended"; self:Expire()
    else self.state = nil end
    self:Paint(); self:Watch()
end

function Indicator:Apply()
    if not Enabled() then
        self.active = nil; self:StopDrag(false); self:CancelTimer()
        self.preview, self.state, self.combat = nil, nil, nil
        Suite.pending.combatIndicator, Suite.pending.combatIndicatorVisual = nil, nil
        self:Paint(); self:Watch(); return
    end
    if self.active and self.combat and Read(InCombatLockdown) == true and self.persistent ~= Persistent() then
        self.persistent, self.state = Persistent(), "combat"
        self:Expire(); self:Paint()
    end
    Suite.AfterCombat("combatIndicator", function()
        if not Enabled() or not self:Build() then return end
        if not self.active then self.combat, self.state = false, nil end
        self.active, self.persistent = true, Persistent()
        self:Configure(); self:Watch(); self:Paint()
    end)
end
