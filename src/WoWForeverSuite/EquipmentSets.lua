local _, Suite = ...
local Sets = {}
Suite.EquipmentSets = Sets
table.insert(Suite.modules, Sets)

-- Explicit equipment allowlist: never touch ammo (0), hands (16/17), ranged (18) or bags.
local slots = {
    { 1, "HeadSlot" }, { 2, "NeckSlot" }, { 3, "ShoulderSlot" }, { 4, "ShirtSlot" },
    { 5, "ChestSlot" }, { 6, "WaistSlot" }, { 7, "LegsSlot" }, { 8, "FeetSlot" },
    { 9, "WristSlot" }, { 10, "HandsSlot" }, { 11, "Finger0Slot" }, { 12, "Finger1Slot" },
    { 13, "Trinket0Slot" }, { 14, "Trinket1Slot" }, { 15, "BackSlot" }, { 19, "TabardSlot" },
}

function Sets:Enabled()
    return Suite.db and Suite.db.equipmentSetToggle == true
end

function Sets:HasSelection()
    local pane = self.pane
    if not pane or not pane:IsVisible() then return false end
    local selected = pane.selectedSetID
    if not Suite.IsReadable(selected) or type(selected) ~= "number" or selected ~= selected
        or selected < 0 or selected >= math.huge or selected % 1 ~= 0 then return false end
    if not C_EquipmentSet or type(C_EquipmentSet.GetEquipmentSetInfo) ~= "function" then return false end
    local ok, _, _, setID = pcall(C_EquipmentSet.GetEquipmentSetInfo, selected)
    return ok and Suite.IsReadable(setID) and type(setID) == "number" and setID == selected
end

function Sets:ReadSlots()
    local api = C_EquipmentSet
    if not api or type(api.IsSlotIgnoredForSave) ~= "function"
        or type(api.IgnoreSlotForSave) ~= "function" or type(api.UnignoreSlotForSave) ~= "function"
        or type(PaperDollItemSlotButton_Update) ~= "function" then return end
    local pane = self.pane
    if not self:HasSelection() or not pane.SaveSet then return end
    local buttons, allIgnored = {}, true
    for _, entry in ipairs(slots) do
        local button = _G["Character" .. entry[2]]
        if not button then return end
        local ok, ignored = pcall(api.IsSlotIgnoredForSave, entry[1])
        if not ok or not Suite.IsReadable(ignored) or type(ignored) ~= "boolean" then return end
        buttons[#buttons + 1] = { id = entry[1], button = button }
        if not ignored then allIgnored = false end
    end
    return buttons, allIgnored
end

function Sets:Tooltip()
    if not GameTooltip or not self.button then return end
    local buttons, allIgnored = self:ReadSlots()
    GameTooltip:SetOwner(self.button, "ANCHOR_RIGHT")
    GameTooltip:SetText(buttons and (allIgnored and "Include non-weapon slots" or "Ignore non-weapon slots") or "Equipment slot toggle")
    GameTooltip:AddLine("Leaves weapons, offhand, ranged and ammo unchanged.", 1, 1, 1, true)
    GameTooltip:AddLine(InCombatLockdown() and "Unavailable in combat." or
        (buttons and "Click, then use Save to keep the set changes." or "Select an existing equipment set first."), 0.7, 0.7, 0.7, true)
    GameTooltip:Show()
end

function Sets:Toggle()
    if not self:Enabled() or InCombatLockdown() then return end
    local buttons, allIgnored = self:ReadSlots()
    if not buttons then return end
    local ignore = not allIgnored
    self.changing = true
    for _, entry in ipairs(buttons) do
        if ignore then C_EquipmentSet.IgnoreSlotForSave(entry.id)
        else C_EquipmentSet.UnignoreSlotForSave(entry.id) end
        -- Match the native flyout: update the unsaved slot marker, not the saved set.
        entry.button.ignored = ignore or nil
        PaperDollItemSlotButton_Update(entry.button)
    end
    self.pane.SaveSet:Enable()
    self.changing = nil
    self:Refresh()
    if self.hovered then self:Tooltip() end
end

function Sets:Discover()
    if self.button or InCombatLockdown() then return end
    local pane = PaperDollFrame and PaperDollFrame.EquipmentManagerPane
    if not pane then return end
    self.pane = pane
    local button = CreateFrame("Button", nil, pane, "BackdropTemplate")
    self.button = button
    button:SetSize(24, 24)
    button:SetPoint("BOTTOMRIGHT", pane, "BOTTOMLEFT", -12, 20)
    -- Camelot's model background is level 50 and equipment artwork is level 100.
    -- This control extends left of its pane, so its pane's low level is insufficient.
    local level = pane:GetFrameLevel()
    for _, frame in ipairs({ PaperDollFrame.CharacterModelScene or CharacterModelScene, PaperDollFrame.ItemsFrame }) do
        if frame and type(frame.GetFrameLevel) == "function" then
            local candidate = frame:GetFrameLevel()
            if Suite.IsReadable(candidate) and type(candidate) == "number" then level = math.max(level, candidate) end
        end
    end
    button:SetFrameLevel(math.max(100, level) + 5)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    button:SetBackdropColor(0.04, 0.065, 0.075, 1)
    Suite.Theme:Backdrop(button, 1)
    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", 17, "OUTLINE")
    label:SetPoint("CENTER")
    self.label = label
    button:SetScript("OnClick", function() self:Toggle() end)
    button:SetScript("OnEnter", function() self.hovered = true; self:Refresh(); self:Tooltip() end)
    button:SetScript("OnLeave", function() self.hovered = nil; if GameTooltip then GameTooltip:Hide() end end)
    button:SetScript("OnHide", function() if self.hovered and GameTooltip then GameTooltip:Hide() end; self.hovered = nil end)
    pane:HookScript("OnShow", function() self:Refresh() end)
    pane:HookScript("OnHide", function() self:Refresh() end)
    for _, name in ipairs({ "PaperDollEquipmentManagerPane_Update", "PaperDollItemSlotButton_Update",
        "PaperDollFrame_ClearIgnoredSlots", "PaperDollFrame_IgnoreSlotsForSet" }) do
        if type(_G[name]) == "function" then hooksecurefunc(name, function() self:Refresh() end) end
    end
    if GearManagerPopupFrame then
        GearManagerPopupFrame:HookScript("OnShow", function() self:Refresh() end)
        GearManagerPopupFrame:HookScript("OnHide", function() self:Refresh() end)
    end
end

function Sets:Refresh()
    if self.changing then return end
    Suite.AfterCombat("equipmentSetToggle", function()
        if self:Enabled() then self:Discover() end
        if not self.button then return end
        self.button:SetShown(self:Enabled() and self:HasSelection())
        local buttons, allIgnored = self:ReadSlots()
        self.button:SetEnabled(self:Enabled() and buttons ~= nil)
        self.label:SetText(allIgnored and "+" or "X")
        self.label:SetTextColor(unpack(allIgnored and { 0.41, 0.84, 0.75 } or { 1, 0.3, 0.25 }))
    end)
end

function Sets:Apply()
    if InCombatLockdown() then
        Suite.AfterCombat("equipmentSetApply", function() self:Apply() end)
        return
    end
    Suite.pending.equipmentSetApply = nil
    if self.events then self.events:UnregisterAllEvents() end
    if self:Enabled() then
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function() self:Refresh() end)
        end
        self.events:RegisterEvent("ADDON_LOADED")
        self.events:RegisterEvent("PLAYER_REGEN_ENABLED")
    end
    self:Refresh()
end
