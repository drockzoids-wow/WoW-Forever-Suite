local _, Suite = ...
local Skin = { properties = {}, panels = {}, buttons = {}, watched = {} }
Suite.QuestTrackerSkin = Skin
table.insert(Suite.modules, Skin)

local function Read(value, kind) return Suite.IsReadable(value) and type(value) == kind end
local function Channel(value)
    return Read(value, "number") and value == value and value >= 0 and value <= 1
end
local function Enabled() return Suite.db and Read(Suite.db.questTrackerSkin, "boolean") and Suite.db.questTrackerSkin end
local function Usable(object)
    if not Suite.IsReadable(object) or (type(object) ~= "table" and type(object) ~= "userdata") then return false end
    if type(object.IsForbidden) == "function" then
        local forbidden = object:IsForbidden()
        if not Read(forbidden, "boolean") or forbidden then return false end
    end
    return true
end
local function Anchorable(object)
    if not Usable(object) then return false end
    if type(object.IsAnchoringRestricted) == "function" then
        local restricted = object:IsAnchoringRestricted()
        if not Read(restricted, "boolean") or restricted then return false end
    end
    return true
end
local function Shown(object)
    if not Usable(object) or type(object.IsShown) ~= "function" then return false end
    local shown = object:IsShown()
    return Read(shown, "boolean") and shown
end
local function Snapshot(record)
    if not Usable(record.object) or type(record.object[record.get]) ~= "function" then return end
    local values = { record.object[record.get](record.object) }
    if #values ~= record.count then return end
    for _, value in ipairs(values) do
        if record.kind == "Shown" then
            if not Read(value, "boolean") then return end
        elseif not Channel(value) then return end
    end
    return values
end
local function Same(left, right)
    for index, value in ipairs(left) do if value ~= right[index] then return false end end
    return true
end
local function Write(record, values)
    record.writing = true
    record.object[record.set](record.object, unpack(values))
    record.writing = nil
end
local function RestoreProperty(record)
    if not record.active then return end
    record.active = nil
    if record.saved and Usable(record.object) and type(record.object[record.set]) == "function" then Write(record, record.saved) end
    record.saved, record.applied = nil, nil
end

-- Observe cosmetic/visibility setters. Native text, fonts, assets, header animation alpha and layout stay untouched.
function Skin:Property(object, kind, desired, pass, hideText)
    local get = kind == "Shown" and "IsShown" or "Get" .. kind
    if not Usable(object) or type(object[get]) ~= "function"
        or type(object["Set" .. kind]) ~= "function" or type(hooksecurefunc) ~= "function" then return false end
    local record = self.properties[object]
    if not record then
        record = { object = object, kind = kind, get = get, set = "Set" .. kind, count = #desired }
        if not Snapshot(record) then return false end
        self.properties[object] = record
        local function Observe()
            if record.writing then return end
            -- An unavailable observation invalidates restoration; never replay an older hidden value.
            if record.active then record.saved = Snapshot(record) end
            -- A later readable native setter can recover a component that temporarily yielded to native art.
            if Enabled() then self:Queue() end
        end
        hooksecurefunc(object, record.set, Observe)
        if kind == "Shown" then
            for _, method in ipairs({ "Show", "Hide" }) do
                if type(object[method]) == "function" then hooksecurefunc(object, method, Observe) end
            end
        end
        if kind == "TextColor" and type(object.SetFontObject) == "function" then
            hooksecurefunc(object, "SetFontObject", Observe)
        end
    end
    record.seen = pass
    local current = Snapshot(record)
    if not current then record.saved = nil; return false end
    if kind == "TextColor" and not hideText then
        desired[4] = record.active and record.saved and record.saved[4] or current[4]
    end
    if not record.active or not record.applied or not Same(current, record.applied) then record.saved = current end
    if not record.saved then return false end
    record.active = true
    if not Same(current, desired) then Write(record, desired) end
    record.applied = { unpack(desired) }
    return true
end

local function Texture(parent, color, layer, level)
    local texture = parent:CreateTexture(nil, layer or "BACKGROUND", nil, level or -7)
    texture:SetColorTexture(unpack(color))
    texture:Hide()
    return texture
end
local function AnchorEdge(edge, target, side, left, right)
    edge:ClearAllPoints()
    if side == "TOP" or side == "BOTTOM" then
        edge:SetHeight(1)
        edge:SetPoint(side .. "LEFT", target, side .. "LEFT", left, 0)
        edge:SetPoint(side .. "RIGHT", target, side .. "RIGHT", right, 0)
    else
        local offset = side == "LEFT" and left or right
        edge:SetWidth(1)
        edge:SetPoint("TOP" .. side, target, "TOP" .. side, offset, 0)
        edge:SetPoint("BOTTOM" .. side, target, "BOTTOM" .. side, offset, 0)
    end
end
function Skin:Panel(parent, target, header, pass)
    if not Anchorable(parent) or not Anchorable(target) or type(parent.CreateTexture) ~= "function" then return end
    local panel = self.panels[parent]
    if not panel then
        panel = { textures = {}, edges = {} }
        if not header then
            -- Native quest timers use BACKGROUND strata below the LOW tracker.
            -- Keep only our fill below them; the native timer and tracker stay untouched.
            local layer = CreateFrame("Frame", nil, parent)
            layer:SetAllPoints(parent)
            layer:SetFrameStrata("BACKGROUND")
            layer:SetFrameLevel(0)
            layer:EnableMouse(false)
            panel.backgroundLayer = layer
            panel.background = Texture(layer, { 0.035, 0.05, 0.065, 0.88 })
            panel.textures[1] = panel.background
        end
        for _, side in ipairs(header and { "BOTTOM" } or { "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
            local edge = Texture(parent, { 0.41, 0.84, 0.75, header and 0.45 or 0.65 }, "OVERLAY", 7)
            Suite.Theme:Texture(edge, header and 0.45 or 0.65)
            panel.edges[side] = edge
            panel.textures[#panel.textures + 1] = edge
        end
        self.panels[parent] = panel
    end
    if panel.target ~= target then
        panel.target = target
        -- Reuse the same outline for empty/full contents; native anchors stay untouched.
        local left, right = 0, 0
        if not header and target == parent.Header then left, right = -30, 5 end
        if panel.background then
            panel.background:ClearAllPoints()
            panel.background:SetPoint("TOPLEFT", target, "TOPLEFT", left, 0)
            panel.background:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", right, 0)
        end
        for side, edge in pairs(panel.edges) do
            AnchorEdge(edge, target, side, left, right)
        end
    end
    panel.seen = pass
    for _, texture in ipairs(panel.textures) do texture:Show() end
end
function Skin:PaintButton(record)
    if InCombatLockdown() or not Enabled() or not record.active or not Usable(record.button) then return end
    local pressed = record.pressed
    if pressed == nil and type(record.button.GetButtonState) == "function" then
        local state = record.button:GetButtonState()
        pressed = Read(state, "string") and state == "PUSHED"
    end
    local highlighted = pressed or record.hovered
    record.background:SetColorTexture(pressed and 0.10 or highlighted and 0.07 or 0.035,
        pressed and 0.23 or highlighted and 0.15 or 0.065,
        pressed and 0.21 or highlighted and 0.15 or 0.08, 0.95)
    for _, edge in ipairs(record.edges) do Suite.Theme:Texture(edge, highlighted and 1 or 0.45) end
    for _, texture in ipairs(record.textures) do texture:Show() end
    if not record.collapsed then record.vertical:Hide() end
end
function Skin:Minimize(header, owner, pass)
    local button = header.MinimizeButton
    if not Anchorable(button) or type(button.CreateTexture) ~= "function" or type(button.HookScript) ~= "function"
        or not Usable(owner) or type(owner.IsCollapsed) ~= "function" or type(hooksecurefunc) ~= "function" then return end
    local collapsed = owner:IsCollapsed()
    if not Read(collapsed, "boolean") then return end
    local states = {}
    for _, kind in ipairs({ "Normal", "Pushed", "Highlight" }) do
        local get = button["Get" .. kind .. "Texture"]
        if type(get) ~= "function" then return end
        local texture = get(button)
        if not Usable(texture) or type(texture.SetVertexColor) ~= "function"
            or not Snapshot({ object = texture, get = "GetVertexColor", count = 4 }) then return end
        local property = self.properties[texture]
        if property and property.active and not property.saved then return end
        states[#states + 1] = texture
    end
    local record = self.buttons[button]
    if not record then
        record = { button = button, edges = {}, textures = {} }
        record.background = Texture(button, { 0.035, 0.065, 0.08, 0.95 })
        record.background:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        record.background:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
        record.textures[1] = record.background
        for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
            local edge = Texture(button, { 0.41, 0.84, 0.75, 0.45 }, "BORDER", 7)
            Suite.Theme:Texture(edge, 0.45)
            AnchorEdge(edge, button, side, 0, 0)
            record.edges[#record.edges + 1] = edge
            record.textures[#record.textures + 1] = edge
        end
        for _, vertical in ipairs({ false, true }) do
            local mark = Texture(button, { 0.41, 0.84, 0.75, 1 }, "ARTWORK", 7)
            mark:SetSize(vertical and 2 or 8, vertical and 8 or 2)
            mark:SetPoint("CENTER", button, "CENTER", 0, 0)
            record.textures[#record.textures + 1] = mark
            if vertical then record.vertical = mark end
        end
        self.buttons[button] = record
        local function Paint() if Enabled() then self:PaintButton(record) end end
        button:HookScript("OnEnter", function() record.hovered = true; Paint() end)
        button:HookScript("OnLeave", function() record.hovered, record.pressed = nil, nil; Paint() end)
        button:HookScript("OnMouseDown", function(_, mouseButton)
            if Read(mouseButton, "string") and mouseButton == "LeftButton" then record.pressed = true; Paint() end
        end)
        button:HookScript("OnMouseUp", function() record.pressed = false; Paint() end)
        button:HookScript("OnHide", function() record.hovered, record.pressed = nil, nil end)
        if type(button.SetButtonState) == "function" then
            hooksecurefunc(button, "SetButtonState", function() record.pressed = nil; Paint() end)
        end
        if type(header.SetCollapsed) == "function" then
            hooksecurefunc(header, "SetCollapsed", function() if Enabled() then self:Queue() end end)
        end
    end
    for _, texture in ipairs(states) do
        if not self:Property(texture, "VertexColor", { 1, 1, 1, 0 }, pass) then
            for _, state in ipairs(states) do
                local property = self.properties[state]
                if property then RestoreProperty(property) end
            end
            return
        end
    end
    record.active, record.collapsed, record.seen = true, collapsed, pass
    if type(button.IsMouseOver) == "function" then
        local hovered = button:IsMouseOver()
        record.hovered = Read(hovered, "boolean") and hovered or nil
    end
    self:PaintButton(record)
end
function Skin:Watch(frame)
    if not Usable(frame) or self.watched[frame] then return end
    self.watched[frame] = true
    local function Queue() if Enabled() then self:Queue() end end
    if type(frame.HookScript) == "function" then
        frame:HookScript("OnShow", Queue)
        frame:HookScript("OnHide", Queue)
    end
    if type(frame.Update) == "function" and type(hooksecurefunc) == "function" then
        hooksecurefunc(frame, "Update", Queue)
    end
end
function Skin:Header(header, owner, pass, collapsed)
    if not Anchorable(header) or type(header.CreateTexture) ~= "function" or not Anchorable(header.Background) then return end
    if self:Property(header.Background, "VertexColor", { 1, 1, 1, 0 }, pass) then
        if not collapsed then self:Panel(header, header, true, pass) end
        self:Property(header.Text, "TextColor", { 0.41, 0.84, 0.75, collapsed and 0 or 1 }, pass, collapsed)
        if collapsed then self:Property(header.FilterButton, "Shown", { false }, pass) end
        self:Minimize(header, owner, pass)
    end
end
function Skin:Restore()
    if InCombatLockdown() then Suite.AfterCombat("questTrackerSkin", function() self:Apply() end); return end
    for _, panel in pairs(self.panels) do
        for _, texture in ipairs(panel.textures) do texture:Hide() end
    end
    for _, record in pairs(self.buttons) do
        record.active, record.hovered, record.pressed = nil, nil, nil
        for _, texture in ipairs(record.textures) do texture:Hide() end
    end
    for _, record in pairs(self.properties) do RestoreProperty(record) end
end
function Skin:Cancel()
    self.work = nil
    if self.timer then self.timer:Cancel(); self.timer = nil end
end
function Skin:Refresh()
    self:Cancel()
    if not Enabled() then return end
    if InCombatLockdown() then
        Suite.AfterCombat("questTrackerSkin", function() self:Apply() end)
        return
    end
    local pass, tracker = {}, ObjectiveTrackerFrame
    if Anchorable(tracker) then
        self:Watch(tracker)
        local collapsed = type(tracker.IsCollapsed) == "function" and tracker:IsCollapsed()
        local minimized = Read(collapsed, "boolean") and collapsed
        self:Header(tracker.Header, tracker, pass, minimized)
        local hasContents = false
        if Read(tracker.modules, "table") then
            -- Native module list only: no quest IDs, text, progress or recycled block/line tables.
            for index = 1, 32 do
                local module = tracker.modules[index]
                if not Suite.IsReadable(module) or module == nil then break end
                if Usable(module) then
                    -- The container's dirty closure can retain its original Update function.
                    -- Module updates are dispatched by method lookup and also cover that path.
                    self:Watch(module)
                    if not minimized then self:Header(module.Header, module, pass) end
                    if Shown(module) then hasContents = true end
                end
            end
        end
        -- Native NineSlice can retain its last tall bounds while collapsed. Keep it suppressed,
        -- even when Suite's entire panel is hidden, so the only visible control is the native +.
        local background = type(tracker.CreateTexture) == "function" and Anchorable(tracker.NineSlice)
            and self:Property(tracker.NineSlice, "Alpha", { 0 }, pass)
        if Read(collapsed, "boolean") and not collapsed and hasContents and Shown(tracker.NineSlice)
            and background then
            -- NineSlice follows actual contents, whereas the tracker frame reserves maximum screen height.
            self:Panel(tracker, tracker.NineSlice, false, pass)
        elseif Read(collapsed, "boolean") and not collapsed and not hasContents and Shown(tracker.Header) then
            self:Panel(tracker, tracker.Header, false, pass)
        end
    end
    for _, panel in pairs(self.panels) do
        if panel.seen ~= pass then for _, texture in ipairs(panel.textures) do texture:Hide() end end
    end
    for _, record in pairs(self.buttons) do
        if record.seen ~= pass then
            record.active, record.hovered, record.pressed = nil, nil, nil
            for _, texture in ipairs(record.textures) do texture:Hide() end
        end
    end
    for _, record in pairs(self.properties) do if record.seen ~= pass then RestoreProperty(record) end end
end
function Skin:Queue()
    if not Enabled() then return end
    if InCombatLockdown() then self:Refresh(); return end
    if self.timer then return end
    if not C_Timer or type(C_Timer.NewTimer) ~= "function" then self:Refresh(); return end
    local work = {}; self.work = work
    self.timer = C_Timer.NewTimer(0.05, function()
        if self.work ~= work then return end
        self.timer, self.work = nil, nil
        self:Refresh()
    end)
end
function Skin:Apply()
    self:Cancel()
    Suite.pending.questTrackerSkin = nil
    if self.events then self.events:UnregisterAllEvents() end
    if not Enabled() then
        if next(self.properties) then Suite.AfterCombat("questTrackerSkin", function() self:Restore() end) end
        return
    end
    Suite.AfterCombat("questTrackerSkin", function()
        if not Enabled() then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function() self:Queue() end)
        end
        for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED" }) do self.events:RegisterEvent(event) end
        self:Refresh()
    end)
end
