local _, Suite = ...
local Menus = { watched = setmetatable({}, { __mode = "k" }) }
Suite.Menus = Menus
local ROW, CAPACITY, WIDTH = 24, 12, 300
local Node = {}
Node.__index = Node
local function Description(label, kind)
    return setmetatable({ label = Suite.IsReadable(label) and type(label) == "string" and label or "Unavailable",
        kind = kind, enabled = true }, Node)
end
function Node:CreateButton(label, callback)
    local entry = Description(label, "button")
    entry.callback = callback; self.entries[#self.entries + 1] = entry
    return entry
end
function Node:CreateRadio(label, selected, callback)
    local entry = self:CreateButton(label, callback); entry.selected = selected
    return entry
end
function Node:CreateCheckbox(label, selected, callback) return self:CreateRadio(label, selected, callback) end
function Node:CreateTitle(label)
    local entry = self:CreateButton(label); entry.enabled = false
    return entry
end
function Node:SetEnabled(enabled) self.enabled = Suite.IsReadable(enabled) and enabled == true end

function Menus:Close()
    if self.frame then self.frame:Hide() end
end
function Menus:Render()
    local entries = self.entries or {}
    self.offset = math.max(0, math.min(self.offset or 0, math.max(0, #entries - CAPACITY)))
    self.list:SetHeight(math.max(1, math.min(CAPACITY, #entries)) * ROW + 8)
    for index, button in ipairs(self.rows) do
        button:SetFrameLevel(self.list:GetFrameLevel() + 1)
        local entry = entries[index + self.offset]
        button.entry = entry
        button:SetShown(entry ~= nil)
        if entry then
            button.label:SetText(entry.label)
            button:SetEnabled(entry.enabled)
            local selected = entry.selected and entry.selected()
            button.selected = Suite.IsReadable(selected) and selected == true
            button.marker:SetShown(button.selected); button.paint()
        else button.label:SetText(""); button.marker:Hide(); button.selected = nil end
    end
    self.more:SetShown(#entries > self.offset + CAPACITY)
end
function Menus:Create()
    if self.frame or InCombatLockdown() then return end
    local frame = CreateFrame("Button", nil, UIParent)
    self.frame, self.rows = frame, {}
    -- A raised Suite window can cover a sibling popup on the same strata.
    frame:Hide(); frame:SetAllPoints(UIParent); frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:EnableMouse(true); frame:EnableKeyboard(true)
    frame:RegisterForClicks("AnyUp")
    frame:SetScript("OnClick", function() self:Close() end)
    frame:SetScript("OnKeyDown", function(control, key)
        if InCombatLockdown() then return end
        control:SetPropagateKeyboardInput(key ~= "ESCAPE")
        if key == "ESCAPE" then self:Close() end
    end)
    frame:SetScript("OnHide", function()
        self.owner, self.entries, self.offset = nil, nil, 0
        for _, button in ipairs(self.rows) do button.entry = nil; button.label:SetText("") end
    end)
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:SetScript("OnEvent", function() self:Close() end)
    local list = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    self.list = list
    list:SetWidth(WIDTH); list:SetClampedToScreen(true); list:EnableMouse(true); list:EnableMouseWheel(true)
    list:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    list:SetBackdropColor(0.035, 0.05, 0.065, 1); Suite.Theme:Backdrop(list, 0.85)
    local function Wheel(_, delta)
        if InCombatLockdown() or not Suite.IsReadable(delta) or type(delta) ~= "number"
            or delta ~= delta or math.abs(delta) == math.huge or delta == 0 then return end
        self.offset = (self.offset or 0) + (delta > 0 and -3 or 3); self:Render()
    end
    list:SetScript("OnMouseWheel", Wheel)
    for index = 1, CAPACITY do
        local button = Suite.Theme:ActionButton(list, "", WIDTH - 8, ROW, function()
            local entry, owner = self.rows[index].entry, self.owner
            if InCombatLockdown() or not frame:IsShown() or not owner or not owner:IsShown()
                or owner.IsEnabled and not owner:IsEnabled() or not entry or not entry.enabled then return end
            local callback = entry.callback
            self:Close()
            if callback then callback() end
        end)
        button:SetPoint("TOPLEFT", 4, -4 - (index - 1) * ROW)
        button.label:ClearAllPoints(); button.label:SetPoint("LEFT", 18, 0); button.label:SetPoint("RIGHT", -6, 0)
        button.label:SetJustifyH("LEFT")
        button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        button.marker = button:CreateTexture(nil, "OVERLAY")
        button.marker:SetSize(2, 14); button.marker:SetPoint("LEFT", 5, 0); Suite.Theme:Texture(button.marker, 1)
        button:EnableMouseWheel(true); button:SetScript("OnMouseWheel", Wheel)
        self.rows[index] = button
    end
    self.more = list:CreateFontString(nil, "OVERLAY")
    self.more:SetFont("Fonts\\FRIZQT__.TTF", 9, ""); self.more:SetTextColor(0.55, 0.65, 0.7)
    self.more:SetPoint("BOTTOMRIGHT", -4, 0); self.more:SetText("Scroll for more")
end

-- Flat Suite selectors share one bounded, opaque list. Meter submenus retain
-- their separate owned implementation; Blizzard's menu pools are untouched.
function Menus.CreateContextMenu(owner, generate)
    if InCombatLockdown() or not owner or not owner:IsShown() then return end
    if Menus.owner == owner and Menus.frame and Menus.frame:IsShown() then Menus:Close(); return end
    Menus:Create(); Menus:Close()
    local root = Description("root"); root.entries = {}
    generate(owner, root)
    Menus.owner, Menus.entries, Menus.offset = owner, root.entries, 0
    -- Keep the list outside scroll-child clipping while following its owner's
    -- hide/disable lifecycle. No hooks or styles enter native menu pools.
    if not Menus.watched[owner] then
        Menus.watched[owner] = true
        local function Dismiss() if Menus.owner == owner then Menus:Close() end end
        owner:HookScript("OnHide", Dismiss)
        if owner.HasScript and owner:HasScript("OnDisable") then owner:HookScript("OnDisable", Dismiss) end
    end
    Menus.list:ClearAllPoints(); Menus.list:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -3)
    Menus:Render(); Menus.frame:SetPropagateKeyboardInput(true); Menus.frame:Show()
end
