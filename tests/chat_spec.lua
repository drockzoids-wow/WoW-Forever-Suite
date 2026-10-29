-- Check native input ownership, account defaults, restrictions and reversible presentation.
local Suite, equal, Frame, SetCombat = ...
local chat = Suite.Chat
local globals = { "CreateFrame", "C_Timer", "CHAT_FRAMES", "ChatFrame1", "ChatFrame2", "ChatFrame3",
    "ChatFrame4", "ChatFrame5", "ChatFrame6", "FCF_OpenNewWindow", "FCF_OpenTemporaryWindow", "FCF_ResetChatWindows",
    "FCFTab_UpdateColors", "CopyToClipboard", "GetCursorPosition", "GameTooltip" }
local old = {}; for _, name in ipairs(globals) do old[name] = _G[name] end
local oldDB, oldPending, oldPrint = Suite.db, Suite.pending, Suite.Print
local messages = {}
Suite.Print = function(message) messages[#messages + 1] = message end
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
local inCombat, created, inputCalls, copied, nativeCalls = false, 0, 0, 0, 0
local timers, regions = {}, {}
local cursorX, cursorY, nativeClipboard = 0, 0, "old clipboard"
GetCursorPosition = function() error("Suite must leave native chat mouse gestures untouched") end
local function Combat(value) inCombat = value; SetCombat(value) end
local function LeaveCombat()
    Combat(false)
    local pending = Suite.pending; Suite.pending = {}
    for _, callback in pairs(pending) do callback() end
end
local function TimerCount()
    local count = 0; for _, timer in ipairs(timers) do if not timer.cancelled then count = count + 1 end end; return count
end
local function Flush()
    local pending = timers; timers = {}
    for _, timer in ipairs(pending) do if not timer.cancelled then timer.callback() end end
    equal(TimerCount(), 0, "chat worker settles without a polling loop")
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
local function Widget(kind, name, parent)
    local widget = Frame(name)
    widget.objectType, widget.parent, widget.shown, widget.alpha = kind, parent, true, 0.6
    widget.IsForbidden = function(self) return self.forbidden or false end
    widget.IsProtected = function(self) return self.protected or false end
    widget.GetAlpha = function(self) return self.alpha end
    widget.SetAlpha = function(self, alpha) self.alpha = alpha end
    widget.GetFont = function(self) return self.fontPath or "Fonts\\ARIALN.TTF", self.fontSize or 12, self.fontFlags or "" end
    widget.SetFont = function(self, path, size, flags)
        assert(not inCombat, "chat addon changed a font during combat")
        self.fontPath, self.fontSize, self.fontFlags = path, size, flags
    end
    widget.Show = function(self)
        local previous = self.shown; self.shown = true
        if not previous and self.OnShow then self.OnShow(self) end
    end
    widget.Hide = function(self)
        local previous = self.shown; self.shown = false
        if previous and self.OnHide then self.OnHide(self) end
    end
    widget.SetShown = function(self, shown) if shown then self:Show() else self:Hide() end end
    widget.SetBackdropColor = function(self, ...) self.backdropColor = { ... }; self.backdropAlpha = select(4, ...) end
    widget.SetColorTexture = function(self, ...) self.color = { ... } end
    widget.GetVerticalScroll = function(self) return self.verticalScroll or 0 end
    widget.GetVerticalScrollRange = function(self) return self.maximum or 0 end
    widget.GetClampRectInsets = function(self) return unpack(self.insets or { 0, 0, 0, 0 }) end
    widget.SetClampRectInsets = function(self, ...)
        assert(not inCombat, "Suite changed screen clamps during combat")
        self.insets = { ... }
    end
    widget.RegisterEvent = function(self, event) self.events = self.events or {}; self.events[event] = true end
    widget.UnregisterAllEvents = function(self) self.events = {} end
    for _, method in ipairs({ "SetPoint", "SetSize", "SetFrameLevel" }) do
        local base = widget[method]
        widget[method] = function(self, ...)
            assert(not inCombat, "chat addon changed layout during combat"); base(self, ...)
            if method == "SetPoint" then
                self.points = self.points or {}; self.points[select(1, ...)] = { ... }
                self.pointOrder = self.pointOrder or {}
                local found = false
                for _, point in ipairs(self.pointOrder) do if point == select(1, ...) then found = true end end
                if not found then self.pointOrder[#self.pointOrder + 1] = select(1, ...) end
            end
        end
    end
    local clear = widget.ClearAllPoints
    widget.ClearAllPoints = function(self)
        assert(not inCombat, "chat addon cleared anchors during combat")
        clear(self); self.points, self.pointOrder = {}, {}
    end
    widget.GetNumPoints = function(self) return self.pointOrder and #self.pointOrder or 0 end
    widget.GetPoint = function(self, index)
        local point = self.pointOrder and self.pointOrder[index or 1]
        if point then return unpack(self.points[point]) end
    end
    local height = widget.SetHeight
    widget.SetHeight = function(self, value)
        assert(not inCombat, "chat addon changed height during combat"); height(self, value)
    end
    widget.CreateTexture = function() return Widget("Texture") end
    if kind == "Slider" then
        widget.SetOrientation = function() end
        widget.SetMinMaxValues = function(self, low, high) self.low, self.high = low, high end
        widget.SetValueStep = function() end; widget.SetObeyStepOnDrag = function() end
        widget.SetThumbTexture = function(self) self.thumb = Widget("Texture") end
        widget.GetThumbTexture = function(self) return self.thumb end
        widget.SetValue = function(self, value) self.value = value; if self.OnValueChanged then self.OnValueChanged(self, value) end end
        widget.GetValue = function(self) return self.value end
    end
    return widget
end
CreateFrame = function(kind, name, parent)
    assert(not inCombat, "chat addon created a frame in combat")
    created = created + 1; return Widget(kind, name, parent)
end
CopyToClipboard = function() error("ordinary addon code must never call the restricted clipboard function") end
local function Region(name)
    local region = Widget("Texture", name)
    _G[name] = region; regions[#regions + 1] = name; return region
end
local function Native(index)
    local name = "ChatFrame" .. index
    local frame = Widget("Frame", name)
    frame.isScrollingMessageFrame, frame.mouseEnabled, frame.motionEnabled = true, false, true
    frame.copyable, frame.hyperlinks, frame.text = false, true, "native chat contents"
    frame:SetSize(640, 180)
    frame.Background = Region(name .. "Background")
    frame.buttonFrame = Widget("Frame", name .. "ButtonFrame", frame)
    frame.buttonFrame:SetWidth(29)
    frame.buttonFrame:SetPoint("TOPRIGHT", frame.Background, "TOPLEFT", -3, -3)
    frame.buttonFrame:SetPoint("BOTTOMRIGHT", frame.Background, "BOTTOMLEFT", -3, 6)
    frame.buttonFrame.menu = Widget("Button", nil, frame.buttonFrame)
    frame.buttonFrame.menu:SetSize(32, 32)
    frame.buttonFrame.menu:SetPoint("BOTTOM", frame.buttonFrame, "BOTTOM", 0, 0)
    frame.buttonFrame.menu:SetScript("OnClick", function() nativeCalls = nativeCalls + 1 end)
    if index == 1 then
        frame.Selection = Widget("Frame", nil, frame)
        frame.Selection.GetWidth = function() error("selection extent reads are unnecessary and may be restricted") end
        frame.Selection:SetPoint("TOPLEFT", frame, "TOPLEFT", -32, 60)
        frame.Selection:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 25, -32)
        frame.Selection:SetScript("OnDragStart", function() nativeCalls = nativeCalls + 1 end)
        frame.Selection:Hide()
        frame.EditModeResizeButton = Widget("Button", nil, frame)
        frame.EditModeResizeButton:SetPoint("BOTTOMRIGHT", frame.Selection, "BOTTOMRIGHT", 0, 26)
        frame.EditModeResizeButton:SetScript("OnMouseDown", function() nativeCalls = nativeCalls + 1 end)
        frame.insets = { -32, 25, 60, -32 }
        frame.UpdateClampOffsets = function(self)
            nativeCalls = nativeCalls + 1
            self:SetClampRectInsets(-32, 25, 60, self.Selection.points.BOTTOMRIGHT[5])
        end
    end
    Region(name .. "TopTexture"); Region(name .. "ButtonFrameBackground")
    local tab = Widget("Button", name .. "Tab")
    tab:SetSize(64, 32)
    tab.Text = Widget("FontString", nil, tab)
    tab.Text:SetSize(44, 8) -- Native text box is shorter than its twelve-point font.
    tab.Text:SetPoint("CENTER", tab, "CENTER", 0, -5)
    tab.Text.GetStringWidth = function() error("Suite must not measure potentially secret tab text") end
    tab.Text.GetText = function() error("Suite must not read potentially secret tab names") end
    tab:SetScript("OnEnter", function() nativeCalls = nativeCalls + 1 end)
    tab:SetScript("OnLeave", function() nativeCalls = nativeCalls + 1 end)
    tab:SetScript("OnClick", function() nativeCalls = nativeCalls + 1 end)
    tab:SetScript("OnDragStart", function() nativeCalls = nativeCalls + 1 end)
    _G[name .. "Tab"] = tab; regions[#regions + 1] = name .. "Tab"
    for _, key in ipairs({ "Left", "Middle", "Right", "ActiveLeft", "ActiveMiddle", "ActiveRight" }) do tab[key] = Widget("Texture") end
    tab.glow = Widget("Texture"); tab.glow.alpha = 0.9
    frame.ScrollToBottomButton, frame.ScrollBar = Widget("Button"), Widget("Frame")
    local input = Widget("EditBox", name .. "EditBox", UIParent)
    input:SetSize(640, 32)
    input:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -5, -2)
    input:SetPoint("RIGHT", frame.ScrollBar, "RIGHT", 8, 0)
    input:SetScript("OnTextChanged", function() nativeCalls = nativeCalls + 1 end)
    input:SetScript("OnEnterPressed", function() nativeCalls = nativeCalls + 1 end)
    input.text = "unsent draft"
    input.channelColor = { 1, 1, 1 }
    input:SetTextColor(1, 1, 1)
    input.GetTextColor = function(self) return unpack(self.textColor) end
    input.GetText = function() error("border styling must never inspect typed messages") end
    input.GetTellTarget = function() error("border styling must never inspect recipients") end
    input.UpdateHeader = function(self)
        nativeCalls = nativeCalls + 1
        self:SetTextColor(unpack(self.channelColor)) -- Native UpdateHeader resolves its final display color.
    end
    _G[name .. "EditBox"] = input; regions[#regions + 1] = name .. "EditBox"
    Region(name .. "EditBoxLeft"); Region(name .. "EditBoxFocusMid")
    frame.ScrollToBottomButton:SetScript("OnClick", function() nativeCalls = nativeCalls + 1 end)
    frame.SetTextCopyable = function(self, value) inputCalls = inputCalls + 1; self.copyable = value end
    frame.IsTextCopyable = function(self) return self.copyable end
    frame.SetMouseClickEnabled = function(self, value) inputCalls = inputCalls + 1; self.mouseEnabled = value end
    frame.IsMouseClickEnabled = function(self) return self.mouseEnabled end
    frame.SetHyperlinksEnabled = function(self, value) inputCalls = inputCalls + 1; self.hyperlinks = value end
    frame.GetHyperlinksEnabled = function(self) return self.hyperlinks end
    frame.SetOnTextCopiedCallback = function(self, callback)
        -- Native secure mixin barriers wrap function arguments before storing them.
        self.textCopiedCallback = callback and function(...) return callback(...) end or nil
    end
    frame.GetOnTextCopiedCallback = function(self) return self.textCopiedCallback end
    frame.GetMessageInfo = function() error("Suite must not read messages or secret history") end
    frame.visibleLines = { secret = true }
    frame:SetScript("OnMouseDown", function(self)
        nativeCalls = nativeCalls + 1
    end)
    frame:SetScript("OnMouseUp", function(self)
        nativeCalls = nativeCalls + 1
    end)
    local nativeDown,nativeUp=frame.OnMouseDown,frame.OnMouseUp
    -- Model XML intrinsicOrder="postcall": extrinsic hooks run first, then native copy/reset/callback.
    frame.Release = function(self, mouse, text, count)
        assert(self.OnMouseDown==nativeDown and self.OnMouseUp==nativeUp,
            "addon mouse hooks must not run ahead of the native protected copy action")
        self.OnMouseUp(self, mouse)
        if mouse == "LeftButton" and self.copyable and self.mouseEnabled and text ~= nil then
            if type(count) == "number" and count > 0 then nativeClipboard = text; copied = copied + 1 end
            if count ~= nil and self.textCopiedCallback then self.textCopiedCallback(self, text, count) end
        end
    end
    frame:SetScript("OnHyperlinkClick", function() nativeCalls = nativeCalls + 1 end)
    frame:SetScript("OnUpdate", function() end)
    frame:SetScript("OnHide", function() nativeCalls = nativeCalls + 1 end)
    frame:SetPoint("BOTTOMLEFT", nil, "BOTTOMLEFT", 100, 100)
    _G[name] = frame; return frame, tab, input
end
local first, tab, input = Native(1)
local second = Native(2); second:Hide()
local unsafe = Native(3); unsafe.protected = true
local forbidden = Native(4); forbidden.forbidden = true
forbidden.GetName = function() error("forbidden frame must not be inspected") end
local restricted = Native(5); restricted.GetFont = function() return { secret = true }, 12, "" end
CHAT_FRAMES = { "ChatFrame1", "ChatFrame2", "ChatFrame3", "ChatFrame4", "ChatFrame5", { secret = true }, "SomeOtherChat" }
local nativeMouseDown, nativeMouseUp, nativeHyperlink, nativeUpdate = first.OnMouseDown, first.OnMouseUp, first.OnHyperlinkClick, first.OnUpdate
local scrollAction, scrollParent, originalPoint = first.ScrollToBottomButton.OnClick, first.ScrollBar.parent, first.point
local tabClick, tabDrag, labelPoint = tab.OnClick, tab.OnDragStart, tab.Text.point
local inputChange, inputEnter, inputParent = input.OnTextChanged, input.OnEnterPressed, input.parent
local oldInputLeft, oldInputRight = input.points.TOPLEFT, input.points.RIGHT
local selection, resize = first.Selection, first.EditModeResizeButton
local selectionTop, selectionBottom, selectionDrag = selection.points.TOPLEFT, selection.points.BOTTOMRIGHT, selection.OnDragStart
local resizePoint, resizeAction, clampMethod = resize.point, resize.OnMouseDown, first.UpdateClampOffsets
local secondInput = _G.ChatFrame2EditBox
local secondPoint = secondInput.GetPoint
secondInput.GetPoint = function() return "TOPLEFT", first, "BOTTOMLEFT", { secret = true }, -2 end
FCF_OpenNewWindow = function() nativeCalls = nativeCalls + 1 end
FCF_OpenTemporaryWindow = function() nativeCalls = nativeCalls + 1 end
FCF_ResetChatWindows = function() nativeCalls = nativeCalls + 1 end
FCFTab_UpdateColors = function(_, selected) nativeCalls = nativeCalls + 1 end
created = 0
chat:Apply()
equal(Suite.db.chatStyle, false, "chat presentation starts off independently")
equal(created, 0, "disabled chat creates no frames")
equal(first.fontSize, nil, "disabled chat leaves original font untouched")
equal(first.Background.alpha, 0.6, "disabled chat leaves native background untouched")
local clean = Suite.InitializeDB({ chatStyle = { secret = true }, chatFontSize = { secret = true }, chatOpacity = 0 / 0 })
equal(clean.chatStyle, false, "restricted enable preference is rejected")
equal(clean.chatFontSize, 14, "restricted font preference uses default")
equal(clean.chatOpacity, 0.5, "nonfinite opacity uses default")
local clamped = Suite.InitializeDB({ chatFontSize = 50, chatOpacity = -1 })
equal(clamped.chatFontSize, 24, "saved font size is bounded")
equal(clamped.chatOpacity, 0, "saved opacity is bounded")
Suite.db.chatStyle, Suite.db.chatFontSize, Suite.db.chatOpacity = true, 16, 0.45
Combat(true); chat:Apply()
equal(created, 0, "first enable in combat defers construction")
Suite.db.chatStyle = false; chat:Apply(); LeaveCombat()
equal(created, 0, "disable cancels deferred first enable")
Suite.db.chatStyle = true; chat:Apply()
local record = chat.records[first]
equal(record ~= nil, true, "native chat window is managed")
equal(chat.records[unsafe], nil, "protected chat window is skipped")
equal(chat.records[forbidden], nil, "forbidden chat window is skipped")
equal(chat.records[restricted], nil, "restricted font prevents initial modification")
equal(first.fontSize, 16, "account text size applies to message display")
equal(input.fontSize, 16, "account text size applies to native typing input")
equal(input.points.TOPLEFT[2], first.Background, "typing input aligns to the visible chat background")
equal(input.points.TOPLEFT[3], "BOTTOMLEFT", "typing input is below the chat panel")
equal(input.points.TOPLEFT[4], 0, "typing input has no left overhang")
equal(input.points.TOPLEFT[5], -3, "typing input leaves a small three-unit gap")
equal(input.points.TOPRIGHT[2], first.Background, "typing input follows the visible chat panel width")
equal(input.points.TOPRIGHT[3], "BOTTOMRIGHT", "typing input aligns to the panel's right edge")
equal(input.points.TOPRIGHT[4], 0, "typing input has no right overhang")
equal(input:GetHeight(), 32, "typing input retains its native height")
equal(input.parent, inputParent, "typing input retains its native parent")
equal(input.OnTextChanged, inputChange, "typing input retains native autocomplete and draft handling")
equal(input.OnEnterPressed, inputEnter, "typing input retains native sending callback")
equal(chat.records[second].inputGeometry, nil, "secret anchors prevent typing input movement")
equal(secondInput.points.TOPLEFT[4], -5, "restricted typing geometry is left untouched")
secondInput.GetPoint = secondPoint
chat:Apply()
equal(secondInput.points.TOPLEFT[5], -3, "readable typing geometry can be styled on a later apply")
equal(selection.points.BOTTOMRIGHT[5], -43, "Edit Mode selection includes input height, gap and a little screen clearance")
equal(first.insets[4], -43, "screen clamp reserves space for the entire typing box")
equal(selection.points.TOPLEFT, selectionTop, "native selection top and left padding are preserved")
equal(selection.points.BOTTOMRIGHT[4], selectionBottom[4], "native selection right padding is preserved")
equal(selection.OnDragStart, selectionDrag, "native Edit Mode dragging callback is retained")
equal(selection:IsShown(), false, "styling never forces Edit Mode's overlay shown")
equal(resize.point, resizePoint, "native Edit Mode resize control retains its anchors")
equal(resize.OnMouseDown, resizeAction, "native Edit Mode resizing callback is retained")
equal(first.UpdateClampOffsets, clampMethod, "Suite does not replace the native clamp updater")
first:UpdateClampOffsets()
equal(first.insets[4], -43, "native Edit Mode clamp update sees the expanded selection")
first:SetClampRectInsets(-32, 25, 60, -32)
equal(first.insets[4], -43, "a later native clamp reset retains typing-box screen clearance")
equal(TimerCount(), 0, "clamp refresh leaves no idle worker")
input:SetHeight(40); Flush()
equal(first.insets[4], -51, "screen clearance follows a readable native input height change")
input:SetHeight(32); Flush()
first:SetScale(0.8); Flush()
equal(first.insets[4], -51, "screen clearance converts UIParent typing height to chat scale")
first:SetScale(1); Flush()
equal(first.insets[4], -43, "returning to native scale restores the normal expanded footprint")
local inputHeight = input.GetHeight
input.GetHeight = function() return { secret = true } end
chat:Apply()
equal(first.insets[4], -43, "restricted input height cannot enter clamp arithmetic")
input.GetHeight = inputHeight
equal(first.fontPath, "Fonts\\ARIALN.TTF", "original font family is preserved")
equal(first.Background.alpha, 0, "native background is suppressed while Suite panel is used")
equal(record.panes[1].backdropAlpha, 0.45, "account opacity is used for Suite background")
equal(record.inputPane.backdropAlpha, 0.9, "typing fill remains dark independently of message transparency")
equal(record.inputPane.borderColor[4], record.panes[1].borderColor[4] * 1.3, "input border is brighter than the message border opacity")
equal(record.inputPane.borderColor[1], 1, "initial Say border is white")
local nativeInputUpdate = input.UpdateHeader
for _, channel in ipairs({
    { "SAY", 1, 1, 1 }, { "GUILD", 0.25, 1, 0.25 }, { "WHISPER", 1, 0.5, 1 },
    { "PARTY", 0.67, 0.67, 1 }, { "RAID", 1, 0.5, 0 }, { "YELL", 1, 0.25, 0.25 },
    { "BN_WHISPER", 0, 1, 1 }, { "CHANNEL1", 1, 0.75, 0.75 }, { "CHANNEL2", 0.15, 0.45, 0.85 },
}) do
    input.channelColor = { channel[2], channel[3], channel[4] }
    input:UpdateHeader()
    for index = 1, 3 do equal(record.inputPane.borderColor[index], channel[index + 1], channel[1] .. " uses the native display RGB") end
    equal(record.inputPane.borderColor[4], record.panes[1].borderColor[4] * 1.3, "channel changes retain the brighter border opacity")
end
equal(input.UpdateHeader, nativeInputUpdate, "native header update is never replaced or hooked")
equal(input.OnTextChanged, inputChange, "channel tint never changes native typing handlers")
equal(input.OnEnterPressed, inputEnter, "channel tint never changes native sending handlers")
equal(input.points.TOPLEFT[5], -3, "channel tint preserves the visible gap")
equal(TimerCount(), 0, "color changes paint directly without an idle or per-key timer")
secondInput:SetTextColor(0.71, 0.22, 0.13)
equal(chat.records[second].inputPane.borderColor[1], 0.71, "each native input owns its channel tint")
equal(record.inputPane.borderColor[1], 0.15, "another window's color never leaks into this input")
Suite.Theme:Refresh()
equal(record.inputPane.borderColor[3], 0.85, "theme refresh preserves active channel tint")
equal(chat.records[second].inputPane.borderColor[2], 0.22, "theme refresh preserves other windows' distinct tints")
local inputColorGetter = input.GetTextColor
local fallbackR, fallbackG, fallbackB = Suite.Theme:RGB()
for _, channels in ipairs({
    { { secret = true }, 1, 1 }, { 1, { secret = true }, 1 }, { 1, 1, { secret = true } },
    { -1, 1, 1 }, { 1, 2, 1 }, { 1, 1, 0/0 }, { math.huge, 1, 1 }, { "1", 1, 1 }, {},
}) do
    input.GetTextColor = function() return unpack(channels) end
    chat:PaintInputBorder(record)
    equal(record.inputPane.borderColor[1], fallbackR, "unreadable or invalid RGB uses the selected theme")
    equal(Suite.Theme.borders[record.inputPane].color, nil, "invalid RGB never enters the semantic border registry")
end
input.GetTextColor = nil; chat:PaintInputBorder(record)
equal(record.inputPane.borderColor[2], fallbackG, "missing native getter uses safe themed fallback")
input.GetTextColor = function() error("unavailable native display color") end; chat:PaintInputBorder(record)
equal(record.inputPane.borderColor[3], fallbackB, "rejected native getter uses safe themed fallback")
input.GetTextColor = inputColorGetter
input:SetTextColor(0, 0, 0)
equal(record.inputPane.borderColor[1], 0, "ordinary black channel colors remain valid")
equal(Suite.Theme.borders[record.inputPane].color.g, 0, "zero green is retained as a semantic color")
input:SetTextColor(1, 1, 1)
for _, opacity in ipairs({ 0, 0.5, 1 }) do
    chat:SetOption("chatOpacity", opacity); Flush()
    equal(record.inputPane.borderColor[4], record.panes[1].borderColor[4] * 1.3, "border stays brighter at all transparency settings")
    equal(record.inputPane.backdropAlpha, math.max(0.9, opacity), "channel border changes preserve the dark typing fill")
end
chat:SetOption("chatOpacity", 0.45); Flush()
equal(tab.glow.alpha, 0.9, "native new-message alerts remain intact")
equal(record.tabPane:GetHeight(), 20, "tab chrome fits the font with four units above and below")
equal(record.tabPane.points.LEFT[2], tab.Text, "tab chrome follows the native label instead of the tall button")
equal(record.tabPane.points.LEFT[4], -8, "tab label has compact left padding")
equal(record.tabPane.points.RIGHT[2], tab.Text, "tab chrome follows native clipping and width changes")
equal(record.tabPane.points.RIGHT[4], 8, "tab label has compact right padding")
equal(record.tabPane.points.LEFT[5], 0, "tab label is vertically centered in the chrome")
equal(tab:GetHeight(), 32, "native tab height and hit target remain intact")
equal(tab:GetWidth(), 64, "native dock width remains intact")
equal(tab.Text:GetHeight(), 8, "native short label box remains intact")
equal(tab.Text.point, labelPoint, "native label anchors remain intact")
equal(tab.OnClick, tabClick, "tab switching and context-menu callback remains native")
equal(tab.OnDragStart, tabDrag, "native tab docking and movement callback remains intact")
equal(record.tabColor[1] ~= chat.records[second].tabColor[1], true,
    "General and Combat Log retain distinct background accents")
equal(record.indicator.color[1], record.tabPane.borderColor[1], "selected underline shares the chosen border color")
local beforeRelease = nativeCalls
first.OnMouseUp(first, "RightButton")
equal(nativeCalls, beforeRelease + 1, "native release script still runs through the observer hook")
equal(first.OnHyperlinkClick, nativeHyperlink, "native hyperlink handler is retained")
equal(first.OnUpdate, nativeUpdate, "native chat updater remains unchanged")
equal(first.ScrollToBottomButton.OnClick, scrollAction, "native scroll-to-current action is retained")
equal(first.ScrollBar.parent, scrollParent, "native scrollbar retains its parent")
equal(first.point, originalPoint, "chat window anchors are unchanged")
equal(second:IsShown(), false, "styling does not show hidden native tabs")
equal(input.text, "unsent draft", "styling preserves typed input")
equal(record.button:GetWidth(), 27, "copy button matches native toolbar face width")
equal(record.button:GetHeight(), 26, "copy button matches native toolbar face height")
equal(record.button.parent, first.buttonFrame, "copy button shares native toolbar visibility and ownership")
equal(record.button.point[1], "TOP", "copy control uses its own slot below the native toolbar")
equal(record.button.point[2], first.buttonFrame, "copy control follows the native toolbar instead of the scrollbar")
equal(record.button.point[3], "BOTTOM", "native bottom controls remain above the copy target")
equal(record.button.point[5], -12, "copy button is centered beside the typing input with clear native control spacing")
local menuPoint, menuClick = first.buttonFrame.menu.point, first.buttonFrame.menu.OnClick
first.buttonFrame:ClearAllPoints()
first.buttonFrame:SetPoint("TOPLEFT", first.Background, "TOPRIGHT", 3, -3)
first.buttonFrame:SetPoint("BOTTOMLEFT", first.Background, "BOTTOMRIGHT", 3, 6)
chat:Apply()
equal(record.button.point[2], first.buttonFrame, "copy control follows native toolbar side changes through its anchor")
equal(first.buttonFrame.menu.point, menuPoint, "copy layout preserves native chat bubble anchors")
equal(first.buttonFrame.menu.OnClick, menuClick, "copy layout preserves native chat bubble input")
first.buttonFrame:ClearAllPoints()
first.buttonFrame:SetPoint("TOPRIGHT", first.Background, "TOPLEFT", -3, -3)
first.buttonFrame:SetPoint("BOTTOMRIGHT", first.Background, "BOTTOMLEFT", -3, 6)
equal(TimerCount(), 0, "initial styling leaves no idle worker")
for _, pane in ipairs(record.panes) do equal(pane.OnUpdate, nil, "Suite chat decorations have no idle updater") end
FCFTab_UpdateColors(tab, false)
equal(record.indicator:IsShown(), false, "inactive native tab loses Suite underline")
local inactiveTint = record.tabPane.backdropColor[2]
local beforeHover = nativeCalls
tab.OnEnter(tab)
equal(nativeCalls, beforeHover + 1, "tab hover still runs native tooltip callback")
equal(record.tabPane.backdropColor[2] > inactiveTint, true, "hover brightens the inactive tab")
tab.OnLeave(tab)
equal(record.tabPane.backdropColor[2], inactiveTint, "leaving the tab restores its inactive tint")
FCFTab_UpdateColors(tab, true)
equal(record.indicator:IsShown(), true, "selected native tab gains Suite underline")
equal(record.tabPane.backdropColor[2] > inactiveTint, true, "selected tab is brighter than an inactive tab")
tab.Text:SetWidth(75) -- Native rename/dock layout, including fixed-width secret whisper tabs.
equal(record.tabPane.points.RIGHT[2], tab.Text, "native label width changes retain automatic chrome anchors")
equal(tab.Text:GetWidth(), 75, "Suite does not override native label width")
tab.Text:SetFont("Fonts\\ARIALN.TTF", 15, ""); Flush()
equal(record.tabPane:GetHeight(), 23, "tab chrome follows a later native font size")
record.button.OnClick()
equal(chat.copyRecord, record, "copy icon enters selection mode on this chat window")
equal(first.copyable, true, "native text copying is enabled")
equal(first.mouseEnabled, true, "native selection receives mouse clicks")
equal(first.motionEnabled, true, "copy mode leaves mouse-motion configuration alone")
equal(first.hyperlinks, false, "selection does not open clicked links")
equal(first.OnMouseDown,nativeMouseDown,"Suite preserves the exact native press script when copying")
equal(first.OnMouseUp,nativeMouseUp,"Suite preserves the exact native release script before protected copying")
equal(record.copyPane, nil, "copy mode never creates the rejected text overlay")
equal(record.copyEdit, nil, "copy mode retains direct chat selection without an editor")
local beforeGestureFrames = created
cursorX, cursorY = 10, 10; first.OnMouseDown(first, "LeftButton")
equal(chat.copyRecord, record, "pressing chat keeps copy mode active when the native callback is wrapped")
cursorX, cursorY = 80, 10; first:Release("LeftButton", "Selected chat text", 18)
equal(nativeClipboard, "Selected chat text", "native release copy result is modeled independently of addon code")
equal(messages[#messages], "Chat text copied to clipboard.", "success feedback follows the native result")
equal(TimerCount(), 0, "native copying needs no addon gesture verification timer")
equal(created, beforeGestureFrames, "copy gestures create no extra frames")
equal(copied, 1, "the native intrinsic alone owns clipboard copying")
equal(record.button.borderColor[4], 1, "copy mode is visibly active")
record.button.OnClick()
equal(chat.copyRecord, nil, "copy icon toggles back to normal chat")
equal(first.copyable, false, "previous copyability is restored")
equal(first.mouseEnabled, false, "previous click-through behavior is restored")
equal(first.hyperlinks, true, "normal hyperlinks are restored")
equal(first:GetOnTextCopiedCallback(), nil, "leaving copy mode restores the prior callback")

local ownerCalls, forwardedText = 0, nil
local owner = function(_, text) ownerCalls = ownerCalls + 1; forwardedText = text end
first:SetOnTextCopiedCallback(owner); record.button.OnClick()
for _, count in ipairs({ 0, { secret = true }, -1, 0.5, math.huge }) do
    local clipboard = nativeClipboard
    cursorX, cursorY = 10, 10; first.OnMouseDown(first, "LeftButton")
    cursorX = 80; first:Release("LeftButton", "selected", count)
    equal(messages[#messages], "The game did not confirm copying that selection to the clipboard.", "zero/unknown native results never claim copying succeeded")
    equal(TimerCount(), 0, "native failure callbacks create no gesture checks")
    if count == 0 then equal(nativeClipboard, clipboard, "native zero-copy leaves previous clipboard contents intact") end
end
equal(ownerCalls, 5, "the original owner's callback remains chained")
equal(forwardedText, "selected", "owner callback arguments are preserved without Suite retaining text")
cursorX, cursorY = 10, 10; first.OnMouseDown(first, "LeftButton")
local beforeSilentMessages=#messages
cursorX = 80; first:Release("LeftButton", "selected", nil)
equal(TimerCount(), 0, "missing native callback cannot schedule addon work ahead of copying")
Flush()
equal(#messages,beforeSilentMessages,"Suite does not infer clipboard results from a mouse gesture")
local beforeClickMessages = #messages
cursorX, cursorY = 10, 10; first.OnMouseDown(first, "LeftButton"); first:Release("LeftButton", nil, nil)
Flush()
equal(#messages, beforeClickMessages, "a click without a drag produces no false copy failure")
equal(first.OnMouseDown,nativeMouseDown,"native press remains unchanged after repeated selections")
equal(first.OnMouseUp,nativeMouseUp,"native release remains unchanged after repeated selections")
record.button.OnClick()
local restoredOwner = first:GetOnTextCopiedCallback()
equal(type(restoredOwner), "function", "copy exit restores the prior owner's callback behavior")
restoredOwner(first, "restored", 8)
equal(ownerCalls, 6, "native rewrapping during restoration retains the prior callback")
record.button.OnClick()
local replacement = function() end
first:SetOnTextCopiedCallback(replacement)
local replacementProxy = first:GetOnTextCopiedCallback()
first.OnMouseDown(first, "LeftButton")
equal(chat.copyRecord, nil, "a new callback owner ends Suite mode at registration without a press hook")
equal(first:GetOnTextCopiedCallback(), replacementProxy, "cleanup preserves the newer callback owner")
first:SetOnTextCopiedCallback(nil)
record.button.OnClick()
cursorX, cursorY = 10, 10; first.OnMouseDown(first, "LeftButton")
cursorX = 80; first:Release("LeftButton", "selected", nil)
local beforeCancelMessages = #messages
record.button.OnClick(); Flush()
equal(#messages, beforeCancelMessages, "exiting copy mode creates no synthetic release report")
record.button.OnClick()
first.buttonFrame:Hide(); record.button.OnHide() -- Native inherited OnHide when toolbar is hidden.
equal(chat.copyRecord, nil, "hiding native toolbar ends selection when the copy control disappears")
equal(first.hyperlinks, true, "toolbar hiding restores native link input")
equal(first.buttonFrame:IsShown(), false, "selection cleanup does not force the native toolbar visible")
first.buttonFrame:Show()
second:Show(); Flush()
record.button.OnClick(); chat.records[second].button.OnClick()
equal(chat.copyRecord, chat.records[second], "switching windows ends the previous copy mode")
equal(first.copyable, false, "previous window resumes normal interaction")
second:Hide()
equal(chat.copyRecord, nil, "hiding a native chat window ends its copy mode")
record.button.OnClick(); input:Hide(); input:Show()
equal(chat.copyRecord, nil, "starting native typing ends chat selection")
equal(input.text, "unsent draft", "copy mode never changes the draft")
record.button.OnClick(); first:SetHyperlinksEnabled(true)
equal(chat.copyRecord, nil, "new native input changes end Suite selection")
equal(first.hyperlinks, true, "new native hyperlink preference is honored")
first.mouseEnabled = { secret = true }
local beforeRestricted = inputCalls; record.button.OnClick()
equal(inputCalls, beforeRestricted, "restricted input state prevents changes")
equal(chat.copyRecord, nil, "restricted input state cannot enter copy mode")
first.mouseEnabled = false
first:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
equal(first.fontSize, 16, "native font reset settles to account size synchronously")
equal(first.fontPath, "Fonts\\FRIZQT__.TTF", "new native font family is retained")
equal(first.fontFlags, "OUTLINE", "new native font flags are retained")
first.Background:SetAlpha(0.73)
equal(first.Background.alpha, 0, "native fade cannot replace the flat Suite background")
for _ = 1, 500 do chat.events.OnEvent(chat.events, "UPDATE_CHAT_WINDOWS") end
equal(TimerCount(), 1, "chat event bursts share one worker")
Flush()
equal(record.inputGeometry.points[1][4], -5, "repeated styling keeps the original native input layout")
local alignedLeft = input.points.TOPLEFT
first.Background:SetWidth(720)
first:SetPoint("BOTTOMLEFT", nil, "BOTTOMLEFT", 140, 120)
equal(input.points.TOPLEFT, alignedLeft, "chat movement and resizing follow anchors without new input work")
local beforeCreated = created
local late = Native(6); CHAT_FRAMES[#CHAT_FRAMES + 1] = "ChatFrame6"
FCF_OpenTemporaryWindow()
equal(late.fontSize, 16, "new whisper appearance settles before the first timer")
equal(chat.records[late] and chat.records[late].applied, true, "new whisper pane is styled before rendering")
equal(_G.ChatFrame6EditBox.points.TOPLEFT[2], late.Background, "new whisper input is aligned before rendering")
Flush()
equal(chat.records[late] ~= nil, true, "late native whisper window is discovered")
equal(late.fontSize, 16, "late window receives the account default")
equal(created > beforeCreated, true, "late window gets its own decorations")
late:Hide()
_G.ChatFrame6EditBox:ClearAllPoints()
_G.ChatFrame6EditBox:SetPoint("TOPLEFT", late, "BOTTOMLEFT", -5, -8)
late:Show()
equal(_G.ChatFrame6EditBox.points.TOPLEFT[2], late.Background, "reopened native chat aligns before a timer runs")
Flush()
record.button.OnClick(); Combat(true)
chat.events.OnEvent(chat.events, "PLAYER_REGEN_DISABLED")
equal(chat.copyRecord, nil, "combat entry ends native selection mode")
equal(TimerCount(), 0, "combat leaves no copy gesture workers")
equal(first.mouseEnabled, false, "combat entry restores unprotected native input")
local combatInputBorder = record.inputPane.borderColor
input:SetTextColor(0.25, 1, 0.25)
input:SetTextColor(1, 0.5, 1)
equal(record.inputPane.borderColor, combatInputBorder, "combat queues channel tint without repainting")
equal(TimerCount(), 0, "combat tint changes use the existing deferred worker without timers")
local combatInputs = inputCalls
record.button.OnClick()
equal(inputCalls, combatInputs, "combat cannot start a new copy gesture")
chat:SetOption("chatFontSize", 18); chat:SetOption("chatOpacity", 0.2)
equal(first.fontSize, 16, "combat defers font changes")
equal(record.panes[1].backdropAlpha, 0.45, "combat defers background changes")
equal(TimerCount(), 0, "combat keeps no chat worker timer")
local tabHeight = record.tabPane:GetHeight()
tab.Text.fontSize = 17 -- Native substitute changes a readable font during combat.
FCFTab_UpdateColors(tab, false); tab.OnEnter(tab)
equal(record.tabPane:GetHeight(), tabHeight, "combat tab events defer geometry changes")
LeaveCombat()
equal(record.tabPane:GetHeight(), 25, "deferred tab font geometry settles after combat")
equal(first.fontSize, 18, "latest account size applies after combat")
equal(record.panes[1].backdropAlpha, 0.2, "latest opacity applies after combat")
equal(record.inputPane.borderColor[2], 0.5, "combat exit reads the final native channel color")
equal(record.inputPane.borderColor[4], record.panes[1].borderColor[4] * 1.3, "combat exit retains brighter border opacity")
local savedAccount = Suite.Copy(Suite.db)
local newCharacter = Suite.InitializeDB(savedAccount)
equal(newCharacter.chatStyle, true, "enabled chat is account-wide for a new character")
equal(newCharacter.chatFontSize, 18, "new character inherits account text size")
equal(newCharacter.chatOpacity, 0.2, "new character inherits account opacity")
Suite.db.chatStyle = false; Combat(true); chat:Apply()
equal(first.fontSize, 18, "combat disable defers native font restoration")
equal(input.points.TOPLEFT[5], -3, "combat disable defers typing input restoration")
equal(first.insets[4], -43, "combat disable defers clamp restoration")
LeaveCombat()
equal(selection.points.BOTTOMRIGHT[5], -32, "disable restores original Edit Mode selection footprint")
equal(first.insets[4], -32, "disable restores original native screen clamp")
equal(input.points.TOPLEFT[2], oldInputLeft[2], "disable restores original input anchor owner")
equal(input.points.TOPLEFT[4], oldInputLeft[4], "disable restores original input horizontal position")
equal(input.points.TOPLEFT[5], oldInputLeft[5], "disable restores original input vertical position")
equal(input.points.RIGHT[4], oldInputRight[4], "disable restores original native right anchor")
equal(input.points.TOPRIGHT, nil, "disable removes the Suite input width anchor")
equal(input:GetWidth(), 640, "disable restores the original input width")
equal(first.fontSize, 11, "disable restores latest native text size")
equal(first.fontPath, "Fonts\\FRIZQT__.TTF", "disable preserves native font family")
equal(first.Background.alpha, 0.73, "disable restores latest native fade alpha")
equal(record.button:IsShown(), false, "disable hides copy icon")
equal(record.panes[1]:IsShown(), false, "disable hides Suite background")
equal(record.tabPane:IsShown(), false, "disable hides compact tab chrome")
equal(record.inputPane:IsShown(), false, "disable removes the channel-colored input pane")
local disabledBorder = record.inputPane.borderColor
input:SetTextColor(0.2, 0.3, 0.4)
equal(record.inputPane.borderColor, disabledBorder, "disabled color hooks leave borders untouched")
equal(TimerCount(), 0, "disabled input colors schedule no work")
equal(tab:GetWidth(), 64, "restoration leaves native dock width intact")
equal(tab.Text.point, labelPoint, "restoration leaves native label anchors intact")
equal(tab.Text.fontSize, 17, "restoration retains the latest native tab font")
equal(tab.Left.alpha, 0.6, "restoration returns native tab artwork")
equal(input.text, "unsent draft", "restoration preserves draft text")
equal(next(chat.events.events), nil, "disable unregisters chat events")
equal(Suite.db.chatFontSize, 18, "restore retains saved account default")
first:SetFont("Fonts\\ARIALN.TTF", 13, "")
equal(first.fontSize, 13, "disabled hooks do not override native fonts")
FCF_OpenNewWindow(); first.Background:SetAlpha(0.4)
equal(TimerCount(), 0, "disabled retained hooks schedule no work")
tab.Text:SetFont("Fonts\\ARIALN.TTF", 12, ""); tab.OnLeave(tab)
equal(TimerCount(), 0, "disabled tab font/hover hooks stay inert")
first:SetClampRectInsets(-32, 25, 60, -36)
equal(first.insets[4], -36, "disabled clamp hook yields to native changes")
Suite.db.chatStyle = true; chat:Apply()
equal(first.fontSize, 18, "re-enable applies account defaults")
equal(record.inputPane.borderColor[1], 0.2, "re-enable reads the current native color instead of a stale tint")
equal(input.points.TOPLEFT[5], -3, "re-enable restores the separated aligned typing input")
equal(first.insets[4], -43, "re-enable expands the current native screen clamp again")
local fontGetter = first.GetFont
first.GetFont = function() return { secret = true }, 12, "" end
first:SetFont("Fonts\\ARIALN.TTF", 12, "")
equal(first.fontSize, 12, "unreadable current font is not overridden")
first.GetFont = fontGetter
first:SetFont("Fonts\\ARIALN.TTF", 13, "")
record.button.OnClick(); first.forbidden = true; chat:StopCopy()
equal(chat.copyRecord, record, "forbidden copy owner is left untouched without recursive retries")
first.forbidden = false; chat:StopCopy()
equal(chat.copyRecord, nil, "copy state restores when its owner becomes available")
Suite.db.chatStyle = false; chat:Apply()
equal(first.insets[4], -36, "re-enable captures the latest native clamp for restoration")
equal(first.fontSize, 13, "re-enable snapshots current native size for later restoration")
equal(first.Background.alpha, 0.4, "re-enable snapshots current native background alpha")

-- Only the two requested appearance fields are shown; activation/restoration is an action.
local gui = Suite.GUI
gui:Select("chat")
local count = 0; for _ in pairs(gui.chatFields) do count = count + 1 end
equal(count, 2, "Chat page has exactly two appearance controls")
equal(gui.chatApply.label.text, "Use Suite chat", "activation is an explicit optional action")
gui.chatFields.chatFontSize.slider:SetValue(20)
gui.chatFields.chatOpacity.slider:SetValue(65)
equal(Suite.db.chatFontSize, 20, "GUI updates account text size")
equal(Suite.db.chatOpacity, 0.65, "GUI updates account opacity")
equal(Suite.db.chatStyle, false, "choosing defaults does not silently enable chat")
equal(gui.chatFields.chatOpacity.value.text, "65%", "opacity has a readable percent value")
local oldSet = Suite.Set
Suite.Set = function(key, value) Suite.db[key] = value; chat:Apply() end
gui.chatApply.OnClick()
equal(Suite.db.chatStyle, true, "activation action enables Suite chat")
equal(first.fontSize, 20, "activation uses the chosen default text size")
equal(gui.chatApply.label.text, "Restore Blizzard chat", "enabled action restores native chat")
gui.chatApply.OnClick()
equal(Suite.db.chatStyle, false, "restoration action disables Suite chat")
equal(first.fontSize, 13, "GUI restoration restores native size")
equal(gui.tabs.chat.height, 27, "contextual Chat navigation fits the workspace sidebar")
Suite.Set = oldSet
gui:Select("overview")
equal(gui.chatPanel:IsShown(), false, "Chat controls hide on another page")
equal(TimerCount(), 0, "disabled Chat page leaves no worker")
for _, name in ipairs(regions) do _G[name] = nil end
for _, name in ipairs(globals) do _G[name] = old[name] end
Suite.db, Suite.pending, Suite.Print = oldDB, oldPending, oldPrint
Combat(false)
