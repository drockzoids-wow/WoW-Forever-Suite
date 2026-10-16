local addonName, Suite = ...
local Meters, ui = Suite.DamageMeters, Suite.DamageMeters.ui
local ROW, CAPACITY, WIDTH = 22, 12, 260
local function Read(value, kind) return Suite.IsReadable(value) and type(value) == kind end

-- Private descriptions and widgets never enter Blizzard's shared menu/compositor pools.
local Node = {}
Node.__index = Node
local function Description(label, kind)
    return setmetatable({ label = Read(label, "string") and label or "Unavailable", kind = kind, children = {} }, Node)
end
function Node:CreateButton(label, callback)
    local child = Description(label, "button")
    child.callback = callback; self.children[#self.children + 1] = child
    return child
end
function Node:CreateRadio(label, selected, callback)
    local child = self:CreateButton(label, callback)
    child.selected = selected
    return child
end
function Node:CreateTitle(label)
    local child = self:CreateButton(label); child.kind = "title"
    return child
end
function Node:CreateDivider()
    local child = self:CreateButton(""); child.kind = "divider"
    return child
end

function Meters:CloseMenus(index)
    local menu = self.menuUI
    if menu and (not index or menu.windowIndex == index) then menu.root.frame:Hide() end
end

function Meters:RenderMenu(panel)
    local entries = panel.description and panel.description.children or {}
    panel.offset = math.max(0, math.min(panel.offset or 0, math.max(0, #entries - CAPACITY)))
    local visible = math.min(CAPACITY, #entries)
    -- Only plain dimensions and readable labels enter these unprotected presentation frames.
    -- No combat widget geometry is read or copied, and no frame is constructed here.
    panel.frame:SetHeight(math.max(1, visible) * ROW + 8)
    for index, button in ipairs(panel.rows) do
        local entry = entries[index + panel.offset]
        button.entry = entry
        button:SetShown(entry ~= nil)
        if entry then
            local action = entry.kind ~= "divider" and entry.kind ~= "title"
            button:SetEnabled(action)
            button.label:SetText(entry.kind == "divider" and "" or entry.label)
            button.label:SetTextColor(unpack(action and ui.palette.text or ui.palette.muted))
            local selected = entry.selected and entry.selected()
            button.check:SetShown(Read(selected, "boolean") and selected)
            button.arrow:SetShown(#entry.children > 0)
            button.divider:SetShown(entry.kind == "divider")
        else
            button.label:SetText(""); button.check:Hide(); button.arrow:Hide(); button.divider:Hide()
        end
        button.highlight:Hide()
    end
    panel.more:SetShown(#entries > panel.offset + CAPACITY)
end

function Meters:ExpandMenu(panel, button)
    local menu, entry = self.menuUI, button.entry
    if not menu or not entry then return end
    if #entry.children == 0 then
        if panel == menu.root then menu.child.frame:Hide(); menu.child.description = nil end
        return
    end
    if menu.child.description == entry and menu.child.frame:IsShown() then return end
    local child = menu.child
    child.description, child.offset = entry, 0
    child.frame:ClearAllPoints()
    local rect = self.rects and self.rects[menu.windowIndex]
    local screenWidth = UIParent:GetWidth()
    local left = rect and Read(screenWidth, "number") and rect.x + WIDTH * 2 > screenWidth
    if left then child.frame:SetPoint("TOPRIGHT", button, "TOPLEFT", -2, 0)
    else child.frame:SetPoint("TOPLEFT", button, "TOPRIGHT", 2, 0) end
    self:RenderMenu(child); child.frame:Show()
end

function Meters:InvokeMenu(panel, button)
    local entry = button.entry
    if not entry then return end
    if #entry.children > 0 then self:ExpandMenu(panel, button); return end
    if entry.callback then
        local callback = entry.callback
        self:CloseMenus(); callback()
    end
end

function Meters:CreateMenus()
    if InCombatLockdown() or self.menuUI then return end
    local menu = {}
    self.menuUI = menu
    local dismiss = CreateFrame("Frame", nil, UIParent)
    menu.dismiss, dismiss.foreverMeter = dismiss, true
    dismiss:SetAllPoints(UIParent); dismiss:SetFrameStrata("DIALOG"); dismiss:SetFrameLevel(699)
    dismiss:EnableMouse(true)
    if dismiss.SetPropagateMouseClicks then dismiss:SetPropagateMouseClicks(true) end
    dismiss:SetScript("OnMouseDown", function() self:CloseMenus() end)
    dismiss:Hide()
    local function Panel(name, level)
        local panel = { rows = {}, offset = 0 }
        local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
        panel.frame, frame.foreverMeter, frame.foreverMeterMenu = frame, true, true
        frame:SetSize(WIDTH, ROW * CAPACITY + 8); frame:SetFrameStrata("DIALOG"); frame:SetFrameLevel(level)
        frame:SetClampedToScreen(true); frame:EnableMouse(true); frame:EnableMouseWheel(true)
        ui.backdrop(frame, ui.palette.background, 0.98)
        for index = 1, CAPACITY do
            local button = CreateFrame("Button", nil, frame)
            panel.rows[index] = button
            button:SetSize(WIDTH - 8, ROW); button:SetPoint("TOPLEFT", 4, -4 - (index - 1) * ROW)
            button:EnableMouse(true); button:EnableMouseWheel(true); button:RegisterForClicks("LeftButtonUp")
            button.highlight = button:CreateTexture(nil, "BACKGROUND"); button.highlight:SetAllPoints()
            button.highlight:SetColorTexture(0.11, 0.22, 0.23, 0.9); button.highlight:Hide()
            button.label = ui.text(button, 12, ui.palette.text)
            button.label:SetPoint("LEFT", 20, 0); button.label:SetWidth(WIDTH - 48); button.label:SetWordWrap(false)
            button.check = button:CreateTexture(nil, "ARTWORK")
            button.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
            button.check:SetSize(14, 14); button.check:SetPoint("LEFT", 3, 0)
            button.arrow = ui.text(button, 12, ui.palette.gold); button.arrow:SetPoint("RIGHT", -4, 0); button.arrow:SetText(">")
            button.divider = button:CreateTexture(nil, "ARTWORK")
            button.divider:SetHeight(1); button.divider:SetPoint("LEFT", 4, 0); button.divider:SetPoint("RIGHT", -4, 0)
            button.divider:SetColorTexture(0.17, 0.25, 0.29, 0.8)
            button:SetScript("OnEnter", function()
                button.highlight:Show(); self:ExpandMenu(panel, button)
            end)
            button:SetScript("OnLeave", function() button.highlight:Hide() end)
            button:SetScript("OnClick", function() self:InvokeMenu(panel, button) end)
            button:SetScript("OnMouseWheel", function(_, direction) frame:GetScript("OnMouseWheel")(frame, direction) end)
            button:Hide()
        end
        panel.more = ui.text(frame, 9, ui.palette.muted)
        panel.more:SetPoint("BOTTOMRIGHT", -3, 1); panel.more:SetText("v")
        frame:SetScript("OnMouseWheel", function(_, direction)
            if not Read(direction, "number") then return end
            if panel == menu.root then menu.child.frame:Hide(); menu.child.description = nil end
            panel.offset = (panel.offset or 0) - direction * 3
            self:RenderMenu(panel)
        end)
        frame:Hide()
        return panel
    end
    -- Named solely for standard Escape support; all menu state is namespace-owned.
    menu.root = Panel(addonName .. "MeterMenu", 700)
    menu.child = Panel(nil, 701)
    if type(UISpecialFrames) == "table" then table.insert(UISpecialFrames, menu.root.frame:GetName()) end
    menu.root.frame:SetScript("OnHide", function()
        menu.child.frame:Hide(); menu.dismiss:Hide()
        if menu.owner and menu.owner.SetMenuOpen then menu.owner:SetMenuOpen(false) end
        menu.windowIndex, menu.owner, menu.kind, menu.rootDescription = nil, nil, nil, nil
        for _, panel in ipairs({ menu.root, menu.child }) do
            panel.description, panel.offset = nil, 0
            for _, button in ipairs(panel.rows) do button.entry = nil; button.label:SetText("") end
        end
    end)
end

function Meters:OpenMenu(window, owner, kind)
    if not self:IsActive() or not self.menuUI then return end
    local menu = self.menuUI
    if menu.owner == owner and menu.root.frame:IsShown() then self:CloseMenus(); return end
    self:CloseMenus()
    local root = Description("root")
    self:DescribeMenu(window, root, kind)
    menu.windowIndex, menu.owner, menu.kind, menu.rootDescription = window.index, owner, kind, root
    menu.root.description, menu.root.offset = root, 0
    menu.root.frame:ClearAllPoints(); menu.root.frame:SetPoint("TOPLEFT", window.header, "BOTTOMLEFT", 0, -2)
    self:RenderMenu(menu.root)
    menu.dismiss:Show(); menu.root.frame:Show()
    if owner.SetMenuOpen then owner:SetMenuOpen(true) end
end
