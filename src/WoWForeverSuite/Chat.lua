local _, Suite = ...
local Chat = { records = {}, tabs = {} }
Suite.Chat = Chat
table.insert(Suite.modules, Chat)

local edges = { "Background", "TopLeftTexture", "BottomLeftTexture", "TopRightTexture", "BottomRightTexture",
    "LeftTexture", "RightTexture", "BottomTexture", "TopTexture" }
local tabArt = { "Left", "Middle", "Right", "ActiveLeft", "ActiveMiddle", "ActiveRight",
    "HighlightLeft", "HighlightMiddle", "HighlightRight" }
local inputArt = { "Left", "Mid", "Right", "FocusLeft", "FocusMid", "FocusRight" }
-- Stable window colors: General, Combat Log, then additional native windows.
local tabColors = { { 0.41, 0.84, 0.75 }, { 0.93, 0.66, 0.32 }, { 0.53, 0.80, 0.48 },
    { 0.48, 0.69, 0.96 }, { 0.77, 0.60, 0.94 }, { 0.93, 0.55, 0.68 }, { 0.39, 0.79, 0.91 },
    { 0.96, 0.52, 0.28 }, { 0.72, 0.79, 0.39 }, { 0.90, 0.40, 0.39 } }
local function Read(value, kind) return Suite.IsReadable(value) and type(value) == kind end
local function Number(value) return Read(value, "number") and value == value and math.abs(value) < math.huge end
local function Available(object)
    if not Suite.IsReadable(object) or not object or (type(object) ~= "table" and type(object) ~= "userdata")
        or type(object.IsForbidden) ~= "function" then return false end
    local forbidden = object:IsForbidden()
    return Read(forbidden, "boolean") and not forbidden
end
local function Writable(frame)
    if not Available(frame) or type(frame.IsProtected) ~= "function" then return false end
    local protected = frame:IsProtected()
    if not Read(protected, "boolean") or protected then return false end
    if type(frame.IsAnchoringRestricted) == "function" then
        local restricted = frame:IsAnchoringRestricted()
        if not Read(restricted, "boolean") or restricted then return false end
    end
    return true
end
local function Shown(frame)
    if not Available(frame) then return false end
    local shown = frame:IsShown()
    return Read(shown, "boolean") and shown
end
local function Anchorable(region)
    if not Available(region) then return false end
    if type(region.IsAnchoringRestricted) == "function" then
        local restricted = region:IsAnchoringRestricted()
        if not Read(restricted, "boolean") or restricted then return false end
    end
    return true
end
local function Font(object)
    if not Available(object) or type(object.GetFont) ~= "function" then return end
    local path, size, flags = object:GetFont()
    if not Read(path, "string") or path == "" or not Number(size) or size <= 0
        or not Suite.IsReadable(flags) or (flags ~= nil and type(flags) ~= "string") then return end
    return { path, size, flags or "" }
end
local function Points(region)
    if not Writable(region) or type(region.GetNumPoints) ~= "function" or type(region.GetPoint) ~= "function" then return end
    local count = region:GetNumPoints()
    if not Number(count) or count < 1 or count > 8 or count ~= math.floor(count) then return end
    local points = {}
    for index = 1, count do
        local point, relative, relativePoint, x, y = region:GetPoint(index)
        if not Read(point, "string") or not Read(relativePoint, "string") or not Number(x) or not Number(y)
            or not Suite.IsReadable(relative) or (relative ~= nil and not Anchorable(relative)) then return end
        points[index] = { point, relative, relativePoint, x, y }
    end
    return points
end
local function InputGeometry(input)
    local points = Points(input)
    if not points or type(input.GetWidth) ~= "function" then return end
    local width = input:GetWidth()
    if Number(width) and width > 0 then return { points = points, width = width } end
end
function Chat:DeferInput(record)
    local input = record.input
    if input then
        -- Native IM chat keeps an inactive edit box shown. Only focus means
        -- typing; never infer activity from visibility or read the draft.
        local ok, focused = false, nil
        if Available(input) and type(input.HasFocus) == "function" then
            ok, focused = pcall(input.HasFocus, input)
        end
        if not ok or not Read(focused, "boolean") or focused then
            record.inputPending = true
            return true
        end
    end
    record.inputPending = nil
    return false
end
function Chat:Options(db)
    db = db or Suite.db or {}
    local size, opacity = db.chatFontSize, db.chatOpacity
    if not Number(size) then size = 14 end
    if not Number(opacity) then opacity = 0.5 end
    return math.max(10, math.min(24, math.floor(size + 0.5))), math.max(0, math.min(1, opacity))
end
function Chat:Enabled()
    return Suite.db and Read(Suite.db.chatStyle, "boolean") and Suite.db.chatStyle
end
function Chat:SetOption(key, value)
    if not Read(key, "string") or (key ~= "chatFontSize" and key ~= "chatOpacity") or not Number(value) then return end
    local values = { chatFontSize = Suite.db.chatFontSize, chatOpacity = Suite.db.chatOpacity }
    values[key] = value
    Suite.db.chatFontSize, Suite.db.chatOpacity = self:Options(values)
    self:Schedule()
end

local function Pane(parent, relative)
    if not Anchorable(relative) or type(parent.GetFrameLevel) ~= "function" then return end
    local level = parent:GetFrameLevel()
    if not Number(level) or level < 0 then return end
    local pane = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    pane.ignoreInLayout = true
    pane:SetFrameLevel(math.max(0, level - 1))
    pane:SetPoint("TOPLEFT", relative, "TOPLEFT", 0, 0)
    pane:SetPoint("BOTTOMRIGHT", relative, "BOTTOMRIGHT", 0, 0)
    pane:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    pane:EnableMouse(false)
    pane:Hide() -- Never expose an unpainted default-white backdrop during discovery.
    return pane
end
function Chat:PaintTab(record, opacity)
    if not Writable(record.tab) or not Anchorable(record.tabLabel) then return end
    local pane, color = record.tabPane, record.tabColor
    local font = Font(record.tabLabel)
    if font and font[2] ~= record.tabFontSize then
        record.tabFontSize = font[2]
        pane:SetHeight(font[2] + 8)
    end
    local strength = record.selected and 0.22 or record.hovered and 0.18 or 0.10
    pane:SetBackdropColor(0.035 + color[1] * strength, 0.045 + color[2] * strength,
        0.055 + color[3] * strength, opacity)
    Suite.Theme:Backdrop(pane, opacity * (record.selected and 0.7 or 0.25))
    pane:Show()
    record.indicator:SetShown(record.selected)
end
function Chat:PaintInputBorder(record)
    if not record.applied or not self:Enabled() or not Writable(record.frame)
        or not Writable(record.input) or not Writable(record.inputPane) then return end
    if InCombatLockdown() then self:Schedule(); return end
    local color
    if type(record.input.GetTextColor) == "function" then
        -- The native header update already resolves Say, whispers, numbered channels and custom colors.
        -- Read only its display color; never inspect typed text, recipients or channel names.
        local ok, r, g, b = pcall(record.input.GetTextColor, record.input)
        if ok and Number(r) and r >= 0 and r <= 1 and Number(g) and g >= 0 and g <= 1
            and Number(b) and b >= 0 and b <= 1 then color = { r = r, g = g, b = b } end
    end
    local _, opacity = self:Options()
    Suite.Theme:Backdrop(record.inputPane, (0.4 + opacity * 0.2) * 1.3, color)
end
function Chat:Paint(record)
    local _, opacity = self:Options()
    for _, pane in ipairs(record.panes) do
        if pane == record.tabPane then self:PaintTab(record, opacity)
        else
            -- Keep typing readable over bright scenery, independently of chat transparency.
            local paneOpacity = pane == record.inputPane and math.max(0.9, opacity) or opacity
            pane:SetBackdropColor(0.025, 0.04, 0.05, paneOpacity)
            if pane == record.inputPane then self:PaintInputBorder(record)
            else Suite.Theme:Backdrop(pane, 0.4 + opacity * 0.2) end
            pane:Show()
        end
    end
    local button = record.button
    if button then
        button:SetBackdropColor(0.035, 0.065, 0.08, 0.95)
        Suite.Theme:Backdrop(button, 0.45)
        button:Show()
    end
end

function Chat:RememberAlpha(record, object)
    if not Available(object) or type(object.GetAlpha) ~= "function" or type(object.SetAlpha) ~= "function" then return end
    local alpha = object:GetAlpha()
    if not Number(alpha) or alpha < 0 or alpha > 1 then return end
    local entry = { object = object, alpha = alpha }
    record.alphas[#record.alphas + 1] = entry
    hooksecurefunc(object, "SetAlpha", function(_, value)
        if self.changing or not record.applied then return end
        if not Number(value) or value < 0 or value > 1 then entry.alpha = nil; return end
        entry.alpha = value -- Retain current native fade/settings state for restoration.
        if self:Enabled() and not InCombatLockdown() and Writable(record.frame) and Available(object) then
            self.changing = true; object:SetAlpha(0); self.changing = false
        end
    end)
end
function Chat:RememberFont(record, object)
    local font = Writable(object) and Font(object)
    if not font or type(object.SetFont) ~= "function" then return end
    local entry = { object = object, font = font }
    record.fonts[#record.fonts + 1] = entry
    -- Native message-frame font setters are secure mixin entry points. Observe
    -- their current font at normal refresh/restore instead of wrapping them.
    if object == record.frame then return end
    local function Changed()
        if self.changing or not record.applied or not self:Enabled() then return end
        entry.font = Font(object)
        self:Schedule()
    end
    hooksecurefunc(object, "SetFont", Changed)
    if type(object.SetFontObject) == "function" then hooksecurefunc(object, "SetFontObject", Changed) end
end
function Chat:Fonts(record, restore)
    if InCombatLockdown() or not Writable(record.frame) then return end
    local deferInput = self:DeferInput(record)
    local changing = self.changing; self.changing = true
    local size = self:Options()
    for _, entry in ipairs(record.fonts) do
        local readable = entry.object ~= record.input or not deferInput
        if entry.object == record.frame and record.applied then
            local current, applied = Font(entry.object), entry.appliedFont
            if not current then
                readable = false
            elseif applied and (current[1] ~= applied[1] or current[2] ~= applied[2] or current[3] ~= applied[3]) then
                entry.font = current -- Preserve a later native font choice on restoration.
            end
        end
        if readable and entry.font and Writable(entry.object) then
            local targetSize = restore and entry.font[2] or size
            local current = Font(entry.object)
            if current and (current[1] ~= entry.font[1] or current[2] ~= targetSize or current[3] ~= entry.font[3]) then
                entry.object:SetFont(entry.font[1], targetSize, entry.font[3])
            end
            entry.appliedFont = not restore and { entry.font[1], targetSize, entry.font[3] } or nil
        end
    end
    self.changing = changing
end
function Chat:InputLayout(record, restore)
    local input = record.input
    if InCombatLockdown() or not Writable(record.frame) or not Writable(input) or self:DeferInput(record) then return end
    if restore then
        local geometry = record.inputGeometry
        if not geometry then return end
        for _, point in ipairs(geometry.points) do
            if point[2] ~= nil and not Anchorable(point[2]) then return end
        end
        input:ClearAllPoints()
        input:SetWidth(geometry.width)
        for _, point in ipairs(geometry.points) do input:SetPoint(unpack(point, 1, 5)) end
        record.inputGeometry = nil
    else
        local background = record.frame.Background
        if not Anchorable(background) then return end
        if not record.inputGeometry then record.inputGeometry = InputGeometry(input) end
        if not record.inputGeometry then return end
        local points = Points(input)
        if points and #points == 2 then
            local left, right = false, false
            for _, point in ipairs(points) do
                if point[2] == background and point[4] == 0 and point[5] == -3 then
                    if point[1] == "TOPLEFT" and point[3] == "BOTTOMLEFT" then left = true end
                    if point[1] == "TOPRIGHT" and point[3] == "BOTTOMRIGHT" then right = true end
                end
            end
            if left and right then return end
        end
        -- Match the visible chat panel, including its native scrollbar gutter. Keep typing height,
        -- parent, insets, headers and input scripts native, with a small gap below the panel.
        input:ClearAllPoints()
        input:SetPoint("TOPLEFT", background, "BOTTOMLEFT", 0, -3)
        input:SetPoint("TOPRIGHT", background, "BOTTOMRIGHT", 0, -3)
    end
end
function Chat:EditBounds(record, restore)
    local frame, input, selection = record.frame, record.input, record.frame.Selection
    if InCombatLockdown() or not Writable(frame) or not Writable(selection)
        or type(frame.GetClampRectInsets) ~= "function" or type(frame.SetClampRectInsets) ~= "function" then return end
    local state = record.editBounds
    if restore then
        if not state or selection ~= state.selection or not Anchorable(state.point[2]) then return end
        local changing = self.changing; self.changing = true
        selection:SetPoint(unpack(state.point, 1, 5))
        frame:SetClampRectInsets(unpack(state.insets))
        self.changing = changing
        record.editBounds = nil
        return
    end
    if not record.inputGeometry or not Writable(input) or type(input.GetHeight) ~= "function"
        or type(input.GetEffectiveScale) ~= "function" or type(frame.GetEffectiveScale) ~= "function"
        or type(selection.GetEffectiveScale) ~= "function" then return end
    local height, inputScale, frameScale, selectionScale = input:GetHeight(), input:GetEffectiveScale(),
        frame:GetEffectiveScale(), selection:GetEffectiveScale()
    if not Number(height) or height <= 0 or not Number(inputScale) or inputScale <= 0
        or not Number(frameScale) or frameScale <= 0 or not Number(selectionScale) or selectionScale <= 0 then return end
    local bottom = -(6 + 3 + height * inputScale / frameScale + 2)
    local selectionBottom = bottom * frameScale / selectionScale
    if not Number(bottom) or not Number(selectionBottom) then return end
    if not state then
        local points = Points(selection)
        if not points then return end
        local point
        for _, anchor in ipairs(points) do
            if anchor[1] == "BOTTOMRIGHT" and anchor[2] == frame and anchor[3] == "BOTTOMRIGHT" then point = anchor end
        end
        local left, right, top, bottom = frame:GetClampRectInsets()
        if not point or not Number(left) or not Number(right) or not Number(top) or not Number(bottom) then return end
        state = { selection = selection, point = point, insets = { left, right, top, bottom } }
        record.editBounds = state
    end
    if selection ~= state.selection then return end
    -- Native background extends six units below the message frame; include the three-unit gap,
    -- the input's readable height in chat units, and two units of breathing room. No rectangle reads.
    state.bottom = math.min(state.insets[4], bottom)
    local changing = self.changing; self.changing = true
    selection:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", state.point[4], math.min(state.point[5], selectionBottom))
    frame:SetClampRectInsets(state.insets[1], state.insets[2], state.insets[3], state.bottom)
    self.changing = changing
end

function Chat:Button(record)
    local frame, toolbar = record.frame, record.frame.buttonFrame
    if not Writable(toolbar) or type(toolbar.GetFrameLevel) ~= "function" then return end
    local level = toolbar:GetFrameLevel()
    if not Number(level) or level < 0 then return end
    local button = CreateFrame("Button", nil, toolbar, "BackdropTemplate")
    record.button = button
    button.ignoreInLayout = true
    button:SetSize(27, 26) -- Match the native voice/chat toolbar button face.
    -- The native bar ends six units above the chat background's bottom. A dedicated
    -- slot below it sits centered beside the 32-unit typing box, clear of native controls.
    button:SetPoint("TOP", toolbar, "BOTTOM", 0, -12)
    button:SetFrameLevel(level + 4)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    button:EnableMouse(true); button:RegisterForClicks("LeftButtonUp")
    for index = 1, 2 do
        local paper = button:CreateTexture(nil, "ARTWORK")
        paper:SetSize(10, 14); paper:SetPoint("TOPLEFT", 7 + (index - 1) * 3, -4 - (index - 1) * 3)
        paper:SetColorTexture(0.41, 0.84, 0.75, index == 1 and 0.5 or 1)
    end
    button:SetScript("OnClick", function() Suite.ChatCopy:Open(frame) end)
    button:SetScript("OnEnter", function()
        if not GameTooltip or not self:Enabled() then return end
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Copy chat text", 0.41, 0.84, 0.75)
        GameTooltip:AddLine("Open recent messages, then select text and press Ctrl+C.", 0.88, 0.91, 0.93)
        GameTooltip:AddLine("Unavailable messages are left out.", 0.55, 0.65, 0.7)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(button) then GameTooltip:Hide() end
    end)
    button:SetScript("OnHide", function()
        if Suite.ChatCopy.owner == record.frame then Suite.ChatCopy:Hide() end
        if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(button) then GameTooltip:Hide() end
    end)
end

function Chat:Remember(frame)
    if not Writable(frame) then return end
    if self.records[frame] or not Read(frame.isScrollingMessageFrame, "boolean")
        or not frame.isScrollingMessageFrame or not Anchorable(frame.Background) or not Font(frame)
        or type(frame.GetName) ~= "function" or type(frame.GetFrameLevel) ~= "function" then return end
    local name, level = frame:GetName(), frame:GetFrameLevel()
    if not Read(name, "string") or not name:match("^ChatFrame%d+$") or not Number(level) or level < 0 then return end
    local record = { frame = frame, alphas = {}, fonts = {}, panes = {}, selected = Shown(frame) }
    self.records[frame] = record
    self:RememberFont(record, frame)
    for _, prefix in ipairs({ "", "ButtonFrame" }) do
        for _, suffix in ipairs(edges) do self:RememberAlpha(record, _G[name .. prefix .. suffix]) end
    end
    record.panes[#record.panes + 1] = Pane(frame, frame.Background)
    local tab = _G[name .. "Tab"]
    local label = Available(tab) and tab.Text
    local labelFont = Anchorable(label) and Font(label)
    if Writable(tab) and labelFont then
        local pane = Pane(tab, label)
        if pane then
            record.tab, record.tabLabel, record.tabPane, record.tabFontSize = tab, label, pane, labelFont[2]
            record.tabColor = tabColors[(tonumber(name:match("%d+$")) - 1) % #tabColors + 1]
            self.tabs[tab] = record
            for _, key in ipairs(tabArt) do self:RememberAlpha(record, tab[key]) end
            -- Native labels have a short fixed box near the tab's bottom. Follow its center/width,
            -- but use the readable font size for height, without measuring text or changing dock geometry.
            pane:ClearAllPoints()
            pane:SetPoint("LEFT", label, "LEFT", -8, 0); pane:SetPoint("RIGHT", label, "RIGHT", 8, 0)
            pane:SetHeight(labelFont[2] + 8)
            record.panes[#record.panes + 1] = pane
            record.indicator = pane:CreateTexture(nil, "OVERLAY")
            record.indicator:SetPoint("BOTTOMLEFT", 5, 1); record.indicator:SetPoint("BOTTOMRIGHT", -5, 1)
            record.indicator:SetHeight(1); Suite.Theme:Texture(record.indicator, 1)
            local function Hover(value)
                record.hovered = value
                if record.applied and self:Enabled() and not InCombatLockdown() and Writable(frame) then
                    self:PaintTab(record, select(2, self:Options()))
                end
            end
            tab:HookScript("OnEnter", function() Hover(true) end)
            tab:HookScript("OnLeave", function() Hover(false) end)
            tab:HookScript("OnHide", function() record.hovered = false end)
            for _, method in ipairs({ "SetFont", "SetFontObject" }) do
                if type(label[method]) == "function" then
                    hooksecurefunc(label, method, function() if self:Enabled() then self:Schedule() end end)
                end
            end
        end
    end
    local input = _G[name .. "EditBox"]
    if Writable(input) then
        record.input = input
        self:RememberFont(record, input)
        for _, suffix in ipairs(inputArt) do self:RememberAlpha(record, _G[name .. "EditBox" .. suffix]) end
        record.inputPane = Pane(input, input)
        record.panes[#record.panes + 1] = record.inputPane
        if type(input.SetTextColor) == "function" then
            hooksecurefunc(input, "SetTextColor", function() self:PaintInputBorder(record) end)
        end
        input:HookScript("OnShow", function()
            if Suite.ChatCopy.owner == record.frame then Suite.ChatCopy:Hide() end
            self:PaintInputBorder(record)
        end)
        local function InputIdle()
            -- Queue outside native focus/send/cancel/hide stacks, including a
            -- pending disable. IM chat may lose focus without hiding.
            if record.inputPending then self:Schedule(true) end
        end
        input:HookScript("OnHide", InputIdle)
        input:HookScript("OnEditFocusLost", InputIdle)
    end
    if Available(frame.Selection) and type(frame.SetClampRectInsets) == "function" then
        hooksecurefunc(frame, "SetClampRectInsets", function(_, left, right, top, bottom)
            local state = record.editBounds
            if self.changing or not record.applied or not self:Enabled() or not state
                or not Number(left) or not Number(right) or not Number(top) or not Number(bottom) then return end
            if InCombatLockdown() then self:Schedule(); return end
            if Writable(frame) and bottom > state.bottom then
                self.changing = true
                frame:SetClampRectInsets(left, right, top, state.bottom)
                self.changing = false
            end
        end)
        for _, object in ipairs({ frame, input }) do
            if Writable(object) then
                for _, method in ipairs({ "SetScale", "SetHeight", "SetSize" }) do
                    if type(object[method]) == "function" then
                        hooksecurefunc(object, method, function() if self:Enabled() then self:Schedule() end end)
                    end
                end
            end
        end
    end
    self:Button(record)
    -- OnShow/OnHide, like mouse scripts, run before intrinsic postcalls.
    -- Leave the native scripts untouched: OnPostShow refreshes rendered text
    -- and OnPostHide resets selection. The owned paper button handles hiding;
    -- native tab/window notifications queue appearance work after this stack.
end
function Chat:Discover()
    if not Read(CHAT_FRAMES, "table") then return end
    for index = 1, math.min(#CHAT_FRAMES, 256) do
        local name = CHAT_FRAMES[index]
        if Read(name, "string") and name:match("^ChatFrame%d+$") then
            local frame = _G[name]
            if Available(frame) then self:Remember(frame) end
        end
    end
end
function Chat:Style(record)
    if not Writable(record.frame) then return end
    if not record.applied then
        for _, entry in ipairs(record.fonts) do entry.font, entry.appliedFont = Font(entry.object), nil end
        for _, entry in ipairs(record.alphas) do
            if Available(entry.object) then
                local alpha = entry.object:GetAlpha()
                entry.alpha = Number(alpha) and alpha >= 0 and alpha <= 1 and alpha or nil
            end
        end
    end
    record.applied = true
    self:Fonts(record)
    self:InputLayout(record)
    if not record.inputPending then self:EditBounds(record) end
    for _, entry in ipairs(record.alphas) do if entry.alpha ~= nil and Available(entry.object) then entry.object:SetAlpha(0) end end
    self:Paint(record)
end
function Chat:Restore(record)
    if not record.applied then record.inputPending = nil; return end
    if not Writable(record.frame) or self:DeferInput(record) then return end
    self:Fonts(record, true)
    self:InputLayout(record, true)
    self:EditBounds(record, true)
    for _, entry in ipairs(record.alphas) do if entry.alpha ~= nil and Available(entry.object) then entry.object:SetAlpha(entry.alpha) end end
    for _, pane in ipairs(record.panes) do pane:Hide() end
    if record.button then record.button:Hide() end
    record.applied = false
end
function Chat:Initialize()
    if self.events then return end
    self.events = CreateFrame("Frame")
    self.events:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGOUT" then
            Suite.ChatCopy:Hide()
            if self.timer then self.timer:Cancel(); self.timer = nil end
            Suite.pending.chat = nil
        elseif event == "PLAYER_REGEN_DISABLED" then
            Suite.ChatCopy:Hide()
            if self.timer then self.timer:Cancel(); self.timer = nil end
            Suite.AfterCombat("chat", function() self:Apply() end)
        else self:Schedule() end
    end)
    for _, method in ipairs({ "FCF_OpenNewWindow", "FCF_OpenTemporaryWindow", "FCF_ResetChatWindows" }) do
        if type(_G[method]) == "function" then hooksecurefunc(method, function()
            if not self:Enabled() or self.changing then return end
            -- These helpers can run inside native frame show/refresh stacks.
            -- Reapply on the next queued turn, outside intrinsic text rendering.
            self:Schedule()
        end) end
    end
    if type(FCFTab_UpdateColors) == "function" then
        hooksecurefunc("FCFTab_UpdateColors", function(tab, selected)
            if not Available(tab) or not Read(selected, "boolean") or not self:Enabled() then return end
            local record = self.tabs[tab]
            if record then
                record.selected = selected
                if record.applied and not InCombatLockdown() and Writable(record.frame) then self:Paint(record) end
                if selected then self:Schedule() end
            end
        end)
    end
end
function Chat:Schedule(allowDisabled)
    if (not self:Enabled() and not allowDisabled) or self.changing or self.timer then return end
    if InCombatLockdown() then Suite.AfterCombat("chat", function() self:Apply() end); return end
    self.timer = C_Timer.NewTimer(0, function() self.timer = nil; self:Apply() end)
end
function Chat:Apply()
    if self.timer then self.timer:Cancel(); self.timer = nil end
    if not self:Enabled() then
        Suite.ChatCopy:Hide()
        if self.events then self.events:UnregisterAllEvents() end
        if not next(self.records) then Suite.pending.chat = nil; return end
    end
    Suite.AfterCombat("chat", function()
        self.changing = true
        if self:Enabled() then
            self:Initialize(); self:Discover()
            for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "ADDON_LOADED", "UPDATE_CHAT_WINDOWS",
                "UPDATE_FLOATING_CHAT_WINDOWS", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED",
                "PLAYER_REGEN_DISABLED", "PLAYER_LOGOUT" }) do self.events:RegisterEvent(event) end
            for _, record in pairs(self.records) do self:Style(record) end
        else
            for _, record in pairs(self.records) do self:Restore(record) end
        end
        self.changing = false
    end)
end
