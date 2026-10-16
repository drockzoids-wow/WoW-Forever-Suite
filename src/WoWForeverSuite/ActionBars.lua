local _, Suite = ...
local ActionBars = { records = {} }
Suite.ActionBars = ActionBars
table.insert(Suite.modules, ActionBars)

local function Enabled()
    return Suite.db and Suite.db.fullButtonRange
end

local function Usable(object)
    if not Suite.IsReadable(object) or not object then return false end
    if object.IsForbidden then
        local forbidden = object:IsForbidden()
        return Suite.IsReadable(forbidden) and forbidden == false
    end
    return true
end

local function Color(r, g, b, a)
    if not Suite.IsReadable(r) or not Suite.IsReadable(g) or not Suite.IsReadable(b) or not Suite.IsReadable(a) then return end
    if a == nil then a = 1 end
    if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" or type(a) ~= "number" then return end
    for _, value in ipairs({ r, g, b, a }) do
        if value ~= value or value < 0 or value > 1 then return end
    end
    return { r, g, b, a }
end

local function Paint(record, r, g, b, a)
    record.painting = true
    record.icon:SetVertexColor(r, g, b, a)
    record.painting = nil
end

function ActionBars:Restore(record)
    if record.tinted and record.color and Usable(record.button) and Usable(record.icon) then
        Paint(record, unpack(record.color))
    end
    record.tinted, record.color = nil, nil
end

function ActionBars:Tint(record)
    if record.tinted or not Usable(record.button) or not Usable(record.icon) then return end
    local color = Color(record.icon:GetVertexColor())
    if not color then return end
    record.color = color
    Paint(record, 1, 0.15, 0.15, color[4])
    record.tinted = true
end

function ActionBars:SetRange(record, checksRange, inRange)
    -- Unknown/restricted range never becomes an inferred out-of-range result.
    record.outOfRange = Suite.IsReadable(checksRange) and Suite.IsReadable(inRange)
        and checksRange == true and inRange == false
    if record.outOfRange then self:Tint(record) else self:Restore(record) end
end

function ActionBars:RefreshButton(record)
    if not Enabled() or not Usable(record.button) then return end
    local visible = record.button:IsVisible()
    if not Suite.IsReadable(visible) or visible ~= true then self:SetRange(record, false); return end
    if record.petSlot then
        if type(GetPetActionInfo) == "function" then
            local checksRange, inRange = select(8, GetPetActionInfo(record.petSlot))
            self:SetRange(record, checksRange, inRange)
        else self:SetRange(record, false) end
        return
    end
    local action = record.button.action
    if not Suite.IsReadable(action) or type(action) ~= "number" or action < 1
        or action >= math.huge or action % 1 ~= 0 or not C_ActionBar
        or type(C_ActionBar.HasAction) ~= "function" or type(C_ActionBar.IsActionInRange) ~= "function" then
        self:SetRange(record, false); return
    end
    local hasAction = C_ActionBar.HasAction(action)
    if not Suite.IsReadable(hasAction) or hasAction ~= true then self:SetRange(record, false); return end
    self:SetRange(record, true, C_ActionBar.IsActionInRange(action))
end

function ActionBars:Track(button, petSlot)
    if InCombatLockdown() or not Usable(button) or self.records[button] then return end
    local icon = button.icon
    if not Usable(icon) or type(icon.SetVertexColor) ~= "function" or type(icon.GetVertexColor) ~= "function" then return end
    local record = { button = button, icon = icon, petSlot = petSlot }
    self.records[button] = record
    -- Observe native usability colors without replacing button logic or scripts.
    hooksecurefunc(icon, "SetVertexColor", function(_, r, g, b, a)
        if record.painting or not Enabled() then return end
        record.tinted = nil -- The native setter just replaced our tint.
        record.color = Color(r, g, b, a)
        if record.outOfRange and record.color and Usable(button) and Usable(icon) then
            Paint(record, 1, 0.15, 0.15, record.color[4])
            record.tinted = true
        end
    end)
    local update = petSlot and "UpdateButtonState" or "Update"
    if type(button[update]) == "function" then
        hooksecurefunc(button, update, function() self:RefreshButton(record) end)
    end
    button:HookScript("OnShow", function() self:RefreshButton(record) end)
    button:HookScript("OnHide", function()
        if Enabled() then self:SetRange(record, false) end
    end)
end

function ActionBars:VisitButtons(callback, includeForms)
    for _, prefix in ipairs({ "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
        "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button" }) do
        for index = 1, 12 do callback(_G[prefix .. index]) end
    end
    for index = 1, 6 do callback(_G["OverrideActionBarButton" .. index]) end
    callback(_G.ExtraActionButton1)
    for index = 1, 10 do callback(_G["PetActionButton" .. index], index) end
    if includeForms then
        for index = 1, 10 do callback(_G["StanceButton" .. index]) end
        for index = 1, 2 do callback(_G["PossessButton" .. index]) end
    end
end

function ActionBars:Discover()
    if InCombatLockdown() then return end
    self:VisitButtons(function(button, petSlot) self:Track(button, petSlot) end)
end

function ActionBars:InstallHook()
    if self.rangeHooked or type(ActionButton_UpdateRangeIndicator) ~= "function" then return end
    -- Shared native presentation callback, including pet buttons; no range-service ownership changes.
    hooksecurefunc("ActionButton_UpdateRangeIndicator", function(button, checksRange, inRange)
        if not Enabled() or not Usable(button) then return end
        local record = self.records[button]
        if record then
            local visible = button:IsVisible()
            if Suite.IsReadable(visible) and visible == true then self:SetRange(record, checksRange, inRange)
            else self:SetRange(record, false) end
        end
    end)
    self.rangeHooked = true
end

function ActionBars:CancelRefresh()
    if self.refreshTimer then self.refreshTimer:Cancel(); self.refreshTimer = nil end
end

function ActionBars:Refresh()
    self:CancelRefresh()
    if not Enabled() then return end
    if InCombatLockdown() then
        Suite.AfterCombat("actionBars", function() self:Refresh() end)
        return
    end
    self:InstallHook()
    self:Discover()
    for _, record in pairs(self.records) do self:RefreshButton(record) end
end

function ActionBars:QueueRefresh()
    if not Enabled() then return end
    if InCombatLockdown() then self:Refresh(); return end
    if self.refreshTimer then return end
    self.refreshTimer = C_Timer.NewTimer(0.05, function()
        self.refreshTimer = nil
        self:Refresh()
    end)
end

function ActionBars:Apply()
    self:CancelRefresh()
    Suite.pending.actionBars = nil
    if self.events then self.events:UnregisterAllEvents() end
    if not Enabled() then
        for _, record in pairs(self.records) do
            record.outOfRange = false
            self:Restore(record)
        end
        return
    end
    Suite.AfterCombat("actionBars", function()
        if not Enabled() then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event)
                if event == "PLAYER_REGEN_DISABLED" then
                    if self.refreshTimer then self:CancelRefresh(); self:QueueRefresh() end
                else self:QueueRefresh() end
            end)
        end
        for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED" }) do
            self.events:RegisterEvent(event)
        end
        self:Refresh()
    end)
end
