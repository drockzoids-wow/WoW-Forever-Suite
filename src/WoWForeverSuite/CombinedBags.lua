local _, Suite = ...
local CombinedBags = {}
local combatPredicates = { "IsProtected", "IsAnchoringRestricted", "IsAnchoringSecret" }
Suite.CombinedBags = CombinedBags
table.insert(Suite.modules, CombinedBags)

local function Option(key)
    return Suite.db and Suite.IsReadable(Suite.db[key]) and Suite.db[key] == true
end

local function Mode()
    return (Option("reverseCombinedBags") and 1 or 0) + (Option("reverseBagSlots") and 2 or 0)
end

local function Enabled()
    return Mode() > 0
end

local function Number(value, minimum, maximum)
    return Suite.IsReadable(value) and type(value) == "number" and value >= minimum and value <= maximum
end

local function Integer(value, minimum, maximum)
    return Number(value, minimum, maximum) and value == math.floor(value)
end

local function Accessible(frame)
    if not Suite.IsReadable(frame) or (type(frame) ~= "table" and type(frame) ~= "userdata") then return false end
    if type(frame.IsForbidden) ~= "function" then return false end
    local forbidden = frame:IsForbidden()
    return Suite.IsReadable(forbidden) and forbidden == false
end

local function CombatAnchorable(frame)
    if not Accessible(frame) then return false end
    for _, method in ipairs(combatPredicates) do
        if type(frame[method]) ~= "function" then return false end
        local success, value = pcall(frame[method], frame)
        if not success or not Suite.IsReadable(value) or value ~= false then return false end
    end
    return true
end

function CombinedBags:Layout(frame)
    if not self.active or not Enabled() or not Accessible(frame) then return end
    -- Retain the prepared mode through combat; preference changes still commit after lockdown.
    local mode = Mode()
    if InCombatLockdown() then mode = self.mode end
    if not Integer(mode, 1, 3) then return end
    if not InputUtil or type(InputUtil.IsGamepadUIEnabled) ~= "function" then return end
    local gamepad = InputUtil.IsGamepadUIEnabled()
    if not Suite.IsReadable(gamepad) or gamepad ~= false then return end
    if type(frame.EnumerateValidItems) ~= "function" or type(frame.GetInitialItemAnchor) ~= "function"
        or type(frame.GetAnchorLayout) ~= "function" or not AnchorUtil or type(AnchorUtil.GridLayout) ~= "function" then return end

    local records, seen = {}, {}
    for _, button in frame:EnumerateValidItems() do
        if #records >= 1000 or not Accessible(button) or seen[button] or type(button.GetBagID) ~= "function"
            or type(button.GetID) ~= "function" or type(button.IsExtended) ~= "function"
            or type(button.GetParent) ~= "function" or type(button.GetWidth) ~= "function"
            or type(button.GetHeight) ~= "function" or type(button.SetPoint) ~= "function"
            or type(button.ClearAllPoints) ~= "function" then return end
        local parent, bag, slot, extended = button:GetParent(), button:GetBagID(), button:GetID(), button:IsExtended()
        if not Suite.IsReadable(parent) or parent ~= frame or not Integer(bag, 0, 5) or not Integer(slot, 1, 1000)
            or not Suite.IsReadable(extended) or type(extended) ~= "boolean"
            or not Suite.IsReadable(button.isBag) or button.isBag ~= nil
            or not Number(button:GetWidth(), 1, 1000) or not Number(button:GetHeight(), 1, 1000) then return end
        seen[button] = true
        records[#records + 1] = { button = button, bag = bag, slot = slot, extended = extended }
    end
    if #records == 0 then return end

    local anchor, layout = frame:GetInitialItemAnchor(), frame:GetAnchorLayout()
    if not Suite.IsReadable(anchor) or type(anchor) ~= "table" or not Suite.IsReadable(layout) or type(layout) ~= "table" then return end
    local direction = layout.direction
    if not Suite.IsReadable(direction) or type(direction) ~= "table" then return end
    -- Reuse only the native desktop grid. Controller headers/collapsed bags keep their own layout.
    if not Suite.IsReadable(direction.x) or direction.x ~= -1 or not Suite.IsReadable(direction.y) or direction.y ~= 1
        or not Suite.IsReadable(direction.isVertical) or (direction.isVertical ~= nil and direction.isVertical ~= false)
        or not Integer(layout.stride, 1, 64) or not Number(layout.paddingX, 0, 64) or not Number(layout.paddingY, 0, 64)
        or not Suite.IsReadable(layout.customOffsetFunction) or layout.customOffsetFunction ~= nil
        or type(layout.GetCustomOffset) ~= "function" or type(anchor.SetPointWithExtraOffset) ~= "function" then return end
    for _, key in ipairs({ "horizontalSpacing", "verticalSpacing" }) do
        local value = layout[key]
        if not Suite.IsReadable(value) or (value ~= nil and not Number(value, 1, 1000)) then return end
    end
    if not Suite.IsReadable(anchor.point) or anchor.point ~= "BOTTOMRIGHT"
        or not Suite.IsReadable(anchor.relativePoint) or anchor.relativePoint ~= "TOPRIGHT"
        or not Accessible(anchor.relativeTo) or not Suite.IsReadable(frame.MoneyFrame) or anchor.relativeTo ~= frame.MoneyFrame
        or not Number(anchor.x, -10000, 10000) or not Number(anchor.y, -10000, 10000) then return end

    local reverseBags, reverseSlots = mode == 1 or mode == 3, mode == 2 or mode == 3
    table.sort(records, function(a, b)
        if a.extended ~= b.extended then return not a.extended end
        if a.bag ~= b.bag then
            if reverseBags then return a.bag < b.bag end
            return a.bag > b.bag
        end
        if reverseSlots then return a.slot < b.slot end
        return a.slot > b.slot
    end)
    local buttons = {}
    for index, record in ipairs(records) do buttons[index] = record.button end
    if not self.active or not Enabled() then return end
    if InCombatLockdown() then
        -- Preflight the whole native grid before any writes. Protection is never cached.
        if frame ~= self.frame or not Suite.IsReadable(ContainerFrameCombinedBags) or frame ~= ContainerFrameCombinedBags
            or not CombatAnchorable(frame) or not CombatAnchorable(anchor.relativeTo) then return end
        for _, button in ipairs(buttons) do if not CombatAnchorable(button) then return end end
    end
    AnchorUtil.GridLayout(buttons, anchor, layout)
    self.overridden = true
    -- Its existing native prompt anchor follows the locked slot automatically during combat.
    if not InCombatLockdown() and type(frame.LayoutAddSlots) == "function" then frame:LayoutAddSlots() end
    return true
end

function CombinedBags:OnLayout(frame)
    if not Suite.IsReadable(frame) or frame ~= self.frame then return end
    self.overridden = nil
    if not self.active or not Enabled() then return end
    if self:Layout(frame) then return end
    if InCombatLockdown() then
        Suite.AfterCombat("combinedBagOrder", function() self:Refresh() end)
    end
end

function CombinedBags:Refresh()
    if InCombatLockdown() then return end
    local frame = ContainerFrameCombinedBags
    if not Accessible(frame) or type(frame.UpdateItemLayout) ~= "function" then return end
    if Enabled() then
        self.mode = Mode()
        if type(hooksecurefunc) ~= "function" then return end
        if frame ~= self.frame then
            self.frame = frame
            hooksecurefunc(frame, "UpdateItemLayout", function(owner) self:OnLayout(owner) end)
        end
        if self.events then self.events:UnregisterAllEvents() end
    end
    -- A never-opened native frame may not have acquired its item buttons yet.
    if type(frame.IsShown) ~= "function" then return end
    local shown = frame:IsShown()
    if not Suite.IsReadable(shown) or shown ~= true then return end
    if Enabled() or (self.overridden and frame == self.frame) then
        frame:UpdateItemLayout()
    end
    if not Enabled() then
        self.overridden = nil
    end
end

function CombinedBags:Apply()
    if not Enabled() then
        Suite.pending.combinedBagOrder = nil
        self.active, self.mode = nil, nil
        if self.events then self.events:UnregisterAllEvents() end
        if self.overridden then Suite.AfterCombat("combinedBagOrder", function() self:Refresh() end) end
        return
    end
    if self.active and self.mode == Mode() then return end
    Suite.AfterCombat("combinedBagOrder", function()
        if not Enabled() then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function()
                if not self.active or not Enabled() then return end
                if Accessible(ContainerFrameCombinedBags) and self.frame == ContainerFrameCombinedBags then return end
                Suite.AfterCombat("combinedBagOrder", function() self:Refresh() end)
            end)
        end
        self.active, self.mode = true, Mode()
        self.events:RegisterEvent("ADDON_LOADED")
        self:Refresh()
    end)
end
