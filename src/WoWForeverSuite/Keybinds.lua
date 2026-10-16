local _, Suite = ...
local Keybinds = { records = {}, buttons = {} }
Suite.Keybinds = Keybinds
table.insert(Suite.modules, Keybinds)

Keybinds.fontOrder = { "default", "friz", "arial", "morpheus", "skurri", "damage" }
Keybinds.fonts = {
    default = { label = "Native" }, friz = { label = "Friz Quadrata", path = "Fonts\\FRIZQT__.TTF" },
    arial = { label = "Arial Narrow", path = "Fonts\\ARIALN.TTF" },
    morpheus = { label = "Morpheus", path = "Fonts\\MORPHEUS.TTF" },
    skurri = { label = "Skurri", path = "Fonts\\SKURRI.TTF" }, damage = { label = "Damage" },
}
Keybinds.outlineOrder = { "default", "none", "outline", "thick" }
Keybinds.outlines = {
    default = { label = "Native" }, none = { label = "None", flags = "" },
    outline = { label = "Outline", flags = "OUTLINE" }, thick = { label = "Thick", flags = "THICKOUTLINE" },
}
local function Read(value, kind) return Suite.IsReadable(value) and type(value) == kind end
local function Number(value) return Read(value, "number") and value == value and math.abs(value) < math.huge end
local function On(key) return Suite.db and Read(Suite.db[key], "boolean") and Suite.db[key] == true end
local function Usable(widget)
    if not Suite.IsReadable(widget) or (type(widget) ~= "table" and type(widget) ~= "userdata") then return false end
    if type(widget.IsForbidden) == "function" then
        local forbidden = widget:IsForbidden()
        if not Read(forbidden, "boolean") or forbidden then return false end
    end
    return true
end
function Keybinds:Options(db)
    db = db or Suite.db or {}
    local font, size, outline = db.keybindFont, db.keybindSize, db.keybindOutline
    if not Read(font, "string") or not self.fonts[font] then font = "default" end
    if not Number(size) then size = 12 end
    size = math.max(8, math.min(24, math.floor(size + 0.5)))
    if not Read(outline, "string") or not self.outlines[outline] then outline = "default" end
    return font, size, outline, Read(db.keybindBold, "boolean") and db.keybindBold == true
end
function Keybinds:FontPath(key, native)
    if not Read(key, "string") or not self.fonts[key] then key = "default" end
    if key == "default" then return native end
    if key == "damage" then return Read(DAMAGE_TEXT_FONT, "string") and DAMAGE_TEXT_FONT ~= "" and DAMAGE_TEXT_FONT or "Fonts\\FRIZQT__.TTF" end
    if key == "friz" and Read(STANDARD_TEXT_FONT, "string") and STANDARD_TEXT_FONT ~= "" then return STANDARD_TEXT_FONT end
    return self.fonts[key].path
end

local modifiers = { SHIFT = "S", CTRL = "C", CONTROL = "C", ALT = "A", META = "M", COMMAND = "M", CMD = "M", S = "S", C = "C", A = "A", M = "M" }
local keys = {
    MOUSEWHEELUP = "MWU", MWHEELUP = "MWU", WHEELUP = "MWU",
    MOUSEWHEELDOWN = "MWD", MWHEELDOWN = "MWD", WHEELDOWN = "MWD",
    LEFTMOUSE = "M1", LEFTBUTTON = "M1", RIGHTMOUSE = "M2", RIGHTBUTTON = "M2", MIDDLEMOUSE = "M3", MIDDLEBUTTON = "M3",
    SPACE = "SP", SPACEBAR = "SP", PAGEUP = "PU", PAGEDOWN = "PD", INSERT = "INS", DELETE = "DEL", DEL = "DEL",
    BACKSPACE = "BS", ENTER = "ENT", RETURN = "ENT", ESCAPE = "ESC",
    UP = "UP", UPARROW = "UP", DOWN = "DN", DOWNARROW = "DN", LEFT = "LT", LEFTARROW = "LT", RIGHT = "RT", RIGHTARROW = "RT",
}
function Keybinds:Shorten(text)
    if not Read(text, "string") then return end
    if text == "" or #text > 128 or text:find("|", 1, true) then return text end
    local rest, prefix = text, ""
    while true do
        local part, tail = rest:match("^([^%-]+)%-(.*)$")
        if not part then break end
        local modifier = modifiers[part:upper():gsub("%s+", "")]
        if not modifier then break end
        prefix, rest = prefix .. modifier, tail
    end
    local compact = rest:upper():gsub("%s+", "")
    local mouse = compact:match("^MOUSEBUTTON(%d+)$") or compact:match("^MOUSE(%d+)$") or compact:match("^BUTTON(%d+)$")
    local numpad = compact:match("^NUMPAD(.+)$")
    local short = keys[compact] or (mouse and "M" .. mouse)
    if numpad then short = "N" .. numpad end
    if not short and (#rest == 1 or compact:match("^F%d+$")) then short = compact end
    return prefix .. (short or rest)
end

local function Font(path, size, flags)
    if Read(path, "string") and path ~= "" and Number(size) and size > 0 and Read(flags, "string") then return { path, size, flags } end
end
local function Color(r, g, b, a)
    if not Number(r) or not Number(g) or not Number(b) or not Number(a) then return end
    for _, value in ipairs({ r, g, b, a }) do if value < 0 or value > 1 then return end end
    return { r, g, b, a }
end
local function Offset(x, y) if Number(x) and Number(y) then return { x, y } end end
local function Snapshot(record)
    local text = record.text
    record.font = Font(text:GetFont())
    record.color = Color(text:GetShadowColor())
    record.offset = Offset(text:GetShadowOffset())
end
local function WriteText(record, value)
    record.writing = true
    record.text:SetText(value)
    record.writing = nil
end
function Keybinds:ApplyText(record)
    if not Usable(record.text) then return end
    if self.short and On("shortKeybinds") then
        if not record.shortActive then
            local value = record.text:GetText()
            if not Read(value, "string") then return end
            record.original = value
            record.shortActive = true
        end
        local short = self:Shorten(record.original)
        if short and short ~= record.original then WriteText(record, short) end
    elseif record.shortActive then
        if Read(record.original, "string") then WriteText(record, record.original) end
        record.shortActive, record.original = nil, nil
    end
end
function Keybinds:ApplyFont(record)
    if InCombatLockdown() or not Usable(record.text) or not record.fontCapable then return end
    local text = record.text
    if self.style and On("keybindFontStyle") then
        if not record.fontActive then
            Snapshot(record)
            if not record.font or not record.color or not record.offset then return end
            record.fontActive = true
        end
        if not record.font or not record.color or not record.offset then return end
        local path = self:FontPath(self.font, record.font[1])
        local flags = self.outlines[self.outline].flags or record.font[3]
        record.writing = true
        local ok, success = pcall(text.SetFont, text, path, self.size + (self.bold and 1 or 0), flags)
        if ok and Suite.IsReadable(success) and success == true then
            if self.bold then text:SetShadowColor(0, 0, 0, 0.95); text:SetShadowOffset(1, -1)
            else text:SetShadowColor(unpack(record.color)); text:SetShadowOffset(unpack(record.offset)) end
        end
        record.writing = nil
    elseif record.fontActive then
        record.writing = true
        if record.font then pcall(text.SetFont, text, unpack(record.font)) end
        if record.color then text:SetShadowColor(unpack(record.color)) end
        if record.offset then text:SetShadowOffset(unpack(record.offset)) end
        record.writing = nil
        record.fontActive, record.font, record.color, record.offset = nil, nil, nil, nil
    end
end
function Keybinds:Track(button)
    if not Usable(button) then return end
    local text = button.HotKey
    if not Usable(text) or type(text.GetText) ~= "function" or type(text.SetText) ~= "function" then return end
    if not self.buttons[button] and type(button.HookScript) == "function" then
        self.buttons[button] = true
        button:HookScript("OnShow", function() if On("shortKeybinds") or On("keybindFontStyle") then self:Queue() end end)
    end
    if self.records[text] then return end
    local record = { text = text, fontCapable = true }
    for _, method in ipairs({ "GetFont", "SetFont", "GetShadowColor", "SetShadowColor", "GetShadowOffset", "SetShadowOffset" }) do
        if type(text[method]) ~= "function" then record.fontCapable = false end
    end
    self.records[text] = record
    hooksecurefunc(text, "SetText", function(_, value)
        if record.writing or not record.shortActive then return end
        if not Suite.IsReadable(value) then record.original = nil; return end
        if value == nil then value = "" end
        record.original = Read(value, "string") and value or nil
        self:ApplyText(record)
    end)
    if type(text.SetFormattedText) == "function" then
        hooksecurefunc(text, "SetFormattedText", function()
            if record.writing or not record.shortActive then return end
            if not Usable(text) then record.original = nil; return end
            local value = text:GetText()
            record.original = Read(value, "string") and value or nil
            self:ApplyText(record)
        end)
    end
    if record.fontCapable then
        for _, entry in ipairs({ { "SetFont", "font" }, { "SetShadowColor", "color", Color }, { "SetShadowOffset", "offset", Offset } }) do
            local field, capture = entry[2], entry[3]
            hooksecurefunc(text, entry[1], function(_, ...)
                if record.writing or not record.fontActive then return end
                if not Usable(text) then record[field] = nil; return end
                if field == "font" then
                    local path, size, flags = ...
                    if not Suite.IsReadable(flags) then record.font = nil; return end
                    local requested = Font(path, size, flags or "")
                    if not requested then record.font = nil; return end
                    local actual = Font(text:GetFont())
                    -- A failed native SetFont must not replace the restore font with its rejected path.
                    if not actual then record.font = nil
                    elseif actual[1] == requested[1] and actual[2] == requested[2] then record.font = actual end
                else record[field] = capture(...) end
                if On("keybindFontStyle") then
                    if InCombatLockdown() then self:Queue() else self:ApplyFont(record) end
                end
            end)
        end
        if type(text.SetFontObject) == "function" then
            hooksecurefunc(text, "SetFontObject", function()
                if record.writing or not record.fontActive then return end
                if not Usable(text) then record.font, record.color, record.offset = nil, nil, nil; return end
                Snapshot(record)
                if On("keybindFontStyle") then
                    if InCombatLockdown() then self:Queue() else self:ApplyFont(record) end
                end
            end)
        end
    end
end
function Keybinds:Cancel()
    self.work = nil
    if self.timer then self.timer:Cancel(); self.timer = nil end
end
function Keybinds:Refresh()
    self:Cancel()
    if InCombatLockdown() then Suite.AfterCombat("keybinds", function() self:Apply() end); return end
    if self.short or self.style then Suite.ActionBars:VisitButtons(function(button) self:Track(button) end, true) end
    for _, record in pairs(self.records) do self:ApplyText(record); self:ApplyFont(record) end
end
function Keybinds:Queue()
    if not On("shortKeybinds") and not On("keybindFontStyle") then return end
    if InCombatLockdown() then self:Cancel(); Suite.AfterCombat("keybinds", function() self:Apply() end); return end
    if self.timer then return end
    local work = {}; self.work = work
    self.timer = C_Timer.NewTimer(0.05, function()
        if self.work ~= work then return end
        self.timer, self.work = nil, nil
        self:Apply()
    end)
end
function Keybinds:Apply()
    self:Cancel()
    Suite.pending.keybinds = nil
    if self.events then self.events:UnregisterAllEvents() end
    if not On("shortKeybinds") and not On("keybindFontStyle") and not next(self.records) then return end
    Suite.AfterCombat("keybinds", function()
        self.short, self.style = On("shortKeybinds"), On("keybindFontStyle")
        self.font, self.size, self.outline, self.bold = self:Options()
        if self.short or self.style then
            if not self.events then
                self.events = CreateFrame("Frame")
                self.events:SetScript("OnEvent", function() self:Queue() end)
            end
            for _, event in ipairs({ "UPDATE_BINDINGS", "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED" }) do self.events:RegisterEvent(event) end
        end
        self:Refresh()
    end)
end
