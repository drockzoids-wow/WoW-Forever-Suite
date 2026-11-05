local _, Suite = ...
local Copy = {}
Suite.ChatCopy = Copy

-- Behavior reference: ChatCopyPaste 1.41. Original Suite implementation; no
-- native selection state, hidden-name recovery or direct clipboard calls.
local function Read(value, kind) return Suite.IsReadable(value) and type(value) == kind end
local function Count(value)
    return Read(value, "number") and value == value and value >= 0 and value <= 1000000 and value % 1 == 0
end
local function Accessible(frame)
    if not Suite.IsReadable(frame) or (type(frame) ~= "table" and type(frame) ~= "userdata") then return false end
    if type(frame.IsForbidden) ~= "function" then return false end
    local ok, forbidden = pcall(frame.IsForbidden, frame)
    return ok and Read(forbidden, "boolean") and not forbidden
end
local function Channel(value)
    return Read(value, "number") and value == value and value >= 0 and value <= 1
end
local function Display(text, r, g, b)
    -- Hidden names are deliberately omitted rather than resolved through other APIs.
    if not Read(text, "string") or #text > 8192 or text:find("|K", 1, true) then return end
    local base = "|cffffffff"
    if Channel(r) and Channel(g) and Channel(b) then
        base = string.format("|cff%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
    end
    -- Keep supplied inline class/item colors. Their resets return to the native
    -- line color, rather than turning the remainder of a channel message white.
    text = text:gsub("|H.-|h(.-)|h", "%1"):gsub("|T.-|t", ""):gsub("|A.-|a", "")
        :gsub("|n", "\n"):gsub("|r", "|r" .. base)
    if text == "" then return "" end
    return base .. text .. "|r"
end

function Copy:Snapshot(frame)
    if InCombatLockdown() or not Accessible(frame) or type(frame.GetNumMessages) ~= "function"
        or type(frame.GetMessageInfo) ~= "function" then return end
    local ok, count = pcall(frame.GetNumMessages, frame)
    if not ok or not Count(count) then return end
    local newest, bytes, omitted = {}, 0, false
    -- Bound both native calls and retained text. Prefer the newest 500 messages.
    for index = count, math.max(1, count - 499), -1 do
        local success, message, r, g, b = pcall(frame.GetMessageInfo, frame, index)
        local text = success and Display(message, r, g, b) or nil
        if text and text ~= "" then
            if bytes + #text + 1 > 131072 then omitted = true; break end
            newest[#newest + 1] = text; bytes = bytes + #text + 1
        elseif not text then omitted = true end
    end
    local lines = {}
    for index = #newest, 1, -1 do lines[#lines + 1] = newest[index] end
    return table.concat(lines, "\n"), omitted, #lines
end

function Copy:Hide()
    if self.frame then self.frame:Hide() end
end

function Copy:Refresh()
    if InCombatLockdown() or not self.frame or not self.frame:IsShown() or not self.owner then return end
    self:Open(self.owner)
end

local function SkinScroll(scroll)
    -- Style only this owned template. Retain its scrolling/cursor scripts.
    if scroll.GetRegions then
        for _, region in ipairs({ scroll:GetRegions() }) do
            if region.GetObjectType and region:GetObjectType() == "Texture" then region:Hide() end
        end
    end
    if scroll.NineSlice then scroll.NineSlice:Hide() end
    local bar = scroll.ScrollBar
    if not bar then return end
    for _, key in ipairs({ "Top", "Middle", "Bottom", "Background" }) do
        if bar[key] and bar[key].Hide then bar[key]:Hide() end
    end
    local thumb = bar.GetThumbTexture and bar:GetThumbTexture()
    if thumb then
        thumb:SetTexture("Interface\\Buttons\\WHITE8X8"); thumb:SetTexCoord(0, 1, 0, 1)
        thumb:SetWidth(8); Suite.Theme:Vertex(thumb, 0.8)
    end
    for index, button in ipairs({ bar.ScrollUpButton, bar.ScrollDownButton }) do
        for _, method in ipairs({ "SetNormalTexture", "SetPushedTexture", "SetDisabledTexture", "SetHighlightTexture" }) do
            if button[method] then button[method](button, nil) end
        end
        Suite.Theme:ButtonFeedback(button)
        for side = -1, 1, 2 do
            local line = button:CreateLine(nil, "ARTWORK")
            local direction = index == 1 and 1 or -1
            line:SetThickness(1.5)
            line:SetStartPoint("CENTER", button, side * 4, -direction * 2)
            line:SetEndPoint("CENTER", button, 0, direction * 2)
            Suite.Theme:Texture(line, 0.85)
        end
    end
end

function Copy:Build()
    if self.frame then return end
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    self.frame = frame
    frame:Hide(); frame:SetSize(640, 420); frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true); frame:SetMovable(true)
    frame:SetToplevel(true); frame:EnableMouse(true)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.035, 0.05, 0.065, 1); Suite.Theme:Backdrop(frame, 1)
    local footer = frame:CreateTexture(nil, "BACKGROUND")
    footer:SetPoint("BOTTOMLEFT", 1, 1); footer:SetPoint("BOTTOMRIGHT", -1, 1); footer:SetHeight(43)
    footer:SetColorTexture(0.055, 0.075, 0.09, 1)
    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", 0, 0); header:SetSize(606, 44); header:EnableMouse(true); header:RegisterForDrag("LeftButton")
    local headerFill = header:CreateTexture(nil, "BACKGROUND")
    headerFill:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1); headerFill:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -1, -44)
    headerFill:SetColorTexture(0.055, 0.075, 0.09, 1)
    local rule = header:CreateTexture(nil, "ARTWORK")
    rule:SetPoint("BOTTOMLEFT", 14, 0); rule:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -14, -44); rule:SetHeight(1)
    Suite.Theme:Texture(rule, 0.35)
    header:SetScript("OnDragStart", function()
        if not InCombatLockdown() then self.moving = true; frame:StartMoving() end
    end)
    header:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); self.moving = nil end)
    local title = header:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 18, ""); title:SetPoint("LEFT", 18, 0); title:SetText("Copy chat")
    title:SetTextColor(0.88, 0.91, 0.93)
    local close = Suite.Theme:IconButton(frame, "Close chat copy", function() self:Hide() end)
    close:SetPoint("TOPRIGHT", -12, -10)
    local help = frame:CreateFontString(nil, "OVERLAY")
    help:SetFont("Fonts\\FRIZQT__.TTF", 11, ""); help:SetPoint("TOPLEFT", 14, -56)
    help:SetTextColor(0.55, 0.65, 0.7)
    help:SetText("Select text and press Ctrl+C. Ctrl+A selects all. Escape closes.")
    local plate = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    plate:SetPoint("TOPLEFT", 13, -79); plate:SetPoint("BOTTOMRIGHT", -13, 47); plate:EnableMouse(false)
    plate:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    plate:SetBackdropColor(0.07, 0.095, 0.11, 1); Suite.Theme:Backdrop(plate, 0.35)
    local scroll = CreateFrame("ScrollFrame", nil, frame, "InputScrollFrameTemplate")
    self.scroll, self.edit = scroll, scroll.EditBox
    scroll:SetPoint("TOPLEFT", 18, -84); scroll:SetPoint("BOTTOMRIGHT", -34, 52)
    if scroll.CharCount then scroll.CharCount:Hide() end
    SkinScroll(scroll)
    local edit = self.edit
    header:SetFrameLevel(edit:GetFrameLevel() + 2); close:SetFrameLevel(edit:GetFrameLevel() + 3)
    edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:SetMaxLetters(0)
    edit:SetFont("Fonts\\ARIALN.TTF", 12, ""); edit:SetWidth(580)
    -- Retain the template's native text-height, scrollbar and cursor updates.
    edit:HookScript("OnTextChanged", function(box, user)
        if user then box:SetText(self.body or "") end
    end)
    edit:SetScript("OnEscapePressed", function() self:Hide() end)
    local refresh = CreateFrame("Button", nil, frame, "BackdropTemplate")
    self.refresh = refresh
    refresh:SetPoint("BOTTOMRIGHT", -14, 9); refresh:SetSize(92, 28)
    refresh:SetFrameLevel(edit:GetFrameLevel() + 2)
    refresh:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    refresh:SetBackdropColor(0.07, 0.095, 0.11, 1); Suite.Theme:Backdrop(refresh, 0.5); Suite.Theme:ButtonFeedback(refresh)
    local refreshText = refresh:CreateFontString(nil, "OVERLAY")
    refreshText:SetFont("Fonts\\FRIZQT__.TTF", 12, ""); refreshText:SetAllPoints(refresh)
    refreshText:SetJustifyH("CENTER"); refreshText:SetJustifyV("MIDDLE"); refreshText:SetText("Refresh")
    refreshText:SetTextColor(0.41, 0.84, 0.75)
    refresh:SetScript("OnClick", function() self:Refresh() end)
    local status = frame:CreateFontString(nil, "OVERLAY")
    self.status = status
    status:SetFont("Fonts\\FRIZQT__.TTF", 10, ""); status:SetPoint("BOTTOMLEFT", 14, 18)
    status:SetWidth(490); status:SetWordWrap(false); status:SetJustifyH("LEFT"); status:SetTextColor(0.55, 0.65, 0.7)
    frame:SetScript("OnEvent", function() self:Hide() end)
    frame:SetScript("OnHide", function()
        if self.moving then frame:StopMovingOrSizing(); self.moving = nil end
        frame:UnregisterAllEvents(); edit:ClearFocus(); self.body, self.owner = nil, nil; edit:SetText("")
    end)
end

function Copy:Open(source)
    if InCombatLockdown() then Suite.Print("Copy chat outside combat."); return end
    local text, omitted, count = self:Snapshot(source)
    if text == nil then Suite.Print("Chat text is unavailable in this window."); return end
    self:Build()
    self.body, self.owner = text, source
    self.frame:Show(); self.frame:Raise(); self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.edit:SetText(text); self.scroll:SetVerticalScroll(0)
    self.status:SetText(count == 0 and "No messages available to copy." or omitted
        and "Some messages are unavailable. Showing recent readable messages." or "Showing up to 500 recent messages.")
    self.edit:SetFocus(); self.edit:HighlightText()
end
