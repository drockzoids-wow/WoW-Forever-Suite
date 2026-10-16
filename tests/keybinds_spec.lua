local Suite, equal, Frame, SetCombat = ...
local module = Suite.Keybinds
local saved = { db = Suite.db, pending = Suite.pending, create = CreateFrame, timer = C_Timer, hook = hooksecurefunc, set = Suite.Set,
    records = module.records, buttons = module.buttons, events = module.events, standard = STANDARD_TEXT_FONT, damage = DAMAGE_TEXT_FONT }
local names = { "ActionButton1", "ActionButton2", "ActionButton3", "ActionButton4", "MultiBar7Button12", "PetActionButton1", "StanceButton1", "OverrideActionBarButton6", "ExtraActionButton1", "PossessButton2" }
local previous = {}; for _, name in ipairs(names) do previous[name] = _G[name]; _G[name] = nil end
Suite.db, Suite.pending, module.records, module.buttons, module.events = Suite.InitializeDB(nil), {}, {}, {}, nil
local combat, native, frames, hooks = false, false, 0, 0
local timers = {}
local secret = { secret = true }
local function Combat(value) combat = value; SetCombat(value) end
local function LeaveCombat()
    Combat(false)
    local pending = Suite.pending; Suite.pending = {}
    for _, callback in pairs(pending) do callback() end
end
local function Flush()
    local work = timers; timers = {}
    for _, timer in ipairs(work) do if not timer.cancelled then timer.callback() end end
end
local function TimerCount()
    local count = 0; for _, timer in ipairs(timers) do if not timer.cancelled then count = count + 1 end end; return count
end
CreateFrame = function(...)
    assert(not combat, "keybind controller creation waits for combat")
    frames = frames + 1
    local frame = saved.create(...)
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    return frame
end
hooksecurefunc = function(...)
    assert(not combat, "keybind hooks install outside combat")
    hooks = hooks + 1
    return saved.hook(...)
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
local function Button(label)
    local button, text = Frame(), Frame()
    button.HotKey, button.shown = text, true
    button.IsForbidden = function(self) if self.forbidden == nil then return false end; return self.forbidden end
    text.path, text.size, text.flags = "Fonts\\ARIALN.TTF", 10, "OUTLINE, MONOCHROME"
    text.text, text.shadowColor, text.shadowOffset = label, { 0.1, 0.2, 0.3, 0.4 }, { 0.5, -0.5 }
    text.shown, text.fontWrites, text.textWrites = false, 0, 0
    text.GetFont = function(self) return self.path, self.size, self.flags end
    text.GetShadowColor = function(self) return unpack(self.shadowColor) end
    text.GetShadowOffset = function(self) return unpack(self.shadowOffset) end
    text.SetFont = function(self, path, size, flags)
        assert(not combat or native, "Suite font changes wait for combat")
        assert(Suite.IsReadable(path) and Suite.IsReadable(size) and Suite.IsReadable(flags), "Suite never sets a secret font")
        if path == "missing.ttf" then return false end
        self.path, self.size, self.flags = path, size, flags or ""
        self.fontWrites = self.fontWrites + 1
        return true
    end
    text.SetShadowColor = function(self, ...)
        assert(not combat or native, "Suite shadow changes wait for combat")
        self.shadowColor = { ... }
    end
    text.SetShadowOffset = function(self, ...)
        assert(not combat or native, "Suite shadow geometry waits for combat")
        self.shadowOffset = { ... }
    end
    text.SetFontObject = function(self, font)
        self.path, self.size, self.flags = font[1], font[2], font[3]
        self.shadowColor, self.shadowOffset = { 0, 0, 0, 0.6 }, { 0, -1 }
    end
    text.SetText = function(self, value)
        assert(native or Suite.IsReadable(value), "Suite never sets hidden text")
        self.text, self.textWrites = value or "", self.textWrites + 1
    end
    text.SetFormattedText = function(self, format, ...) self.text = string.format(format, ...) end
    for _, method in ipairs({ "SetPoint", "SetSize", "SetScale", "SetAttribute", "SetParent", "ClearAllPoints" }) do
        button[method] = function() error("keybind formatting must not change protected buttons") end
        text[method] = function() error("keybind formatting must retain native text anchors and dimensions") end
    end
    return button
end
local function Label(button) return button.HotKey.text end
ActionButton1 = Button("Shift-Ctrl-Mouse Button 4")
MultiBar7Button12 = Button("Shift--")
PetActionButton1 = Button("Alt-Mouse Wheel Up")
StanceButton1 = Button("Num Pad 7")
OverrideActionBarButton6 = Button("●")
ExtraActionButton1 = Button("|A:Gamepad-icon:16:16|a")
PossessButton2 = Button("Backspace")

equal(Suite.db.shortKeybinds, false, "short labels start off")
equal(Suite.db.keybindFontStyle, false, "custom keybind fonts start off independently")
module:Apply()
equal(frames, 0, "disabled keybind features create no controller")
equal(hooks, 0, "disabled keybind features install no hooks")
for input, output in pairs({ ["s-C"] = "SC", ["Ctrl-Alt-F12"] = "CAF12", ["Mouse4"] = "M4", ["Mouse Wheel Down"] = "MWD",
    ["Num Pad +"] = "N+", ["Spacebar"] = "SP", ["Page Up"] = "PU", ["Page Down"] = "PD", ["Left Arrow"] = "LT",
    ["Shift--"] = "S-", ["-"] = "-", ["_"] = "_", ["é"] = "é", ["Unrecognized Key"] = "Unrecognized Key", [""] = "" }) do
    equal(module:Shorten(input), output, "short label preserves or abbreviates " .. input)
end
equal(module:Shorten(secret), nil, "secret key text cannot be shortened")
local repaired = Suite.InitializeDB({ keybindFont = secret, keybindSize = 0 / 0, keybindOutline = "invalid", keybindBold = secret })
equal(repaired.keybindFont, "default", "restricted font selection repairs to native")
equal(repaired.keybindSize, 12, "nonfinite text size repairs to default")
equal(repaired.keybindOutline, "default", "unknown outline repairs to native")
equal(repaired.keybindBold, false, "restricted bold setting repairs to off")
local _, low = module:Options({ keybindSize = -5 }); local _, high = module:Options({ keybindSize = 30 })
equal(low, 8, "font size clamps low"); equal(high, 24, "font size clamps high")

Suite.db.shortKeybinds = true
module:Apply()
equal(Label(ActionButton1), "SCM4", "main bar combines modifiers and mouse keys")
equal(Label(MultiBar7Button12), "S-", "multi bar retains a literal minus key")
equal(Label(PetActionButton1), "AMWU", "pet bar shortens wheel keys")
equal(Label(StanceButton1), "N7", "available stance hotkeys are supported")
equal(Label(OverrideActionBarButton6), "●", "unbound native range indicator stays intact")
equal(Label(ExtraActionButton1), "|A:Gamepad-icon:16:16|a", "gamepad icon markup stays native")
equal(Label(PossessButton2), "BS", "available possess hotkeys are supported")
equal(ActionButton1.HotKey.size, 10, "shortening does not change fonts")
equal(ActionButton1.HotKey:IsShown(), false, "shortening does not change native visibility")
equal(module.events.registered.UPDATE_BINDINGS, true, "binding changes use the native event")
equal(module.events.OnUpdate, nil, "keybind formatting uses no per-frame worker")
local initialHooks, initialFrames = hooks, frames
module:Apply(); module:Apply()
equal(hooks, initialHooks, "repeated applies do not duplicate native hooks")
equal(frames, initialFrames, "repeated applies reuse the controller")
ActionButton1.HotKey:SetText("Ctrl-1")
equal(Label(ActionButton1), "C1", "native binding writes shorten immediately")
ActionButton1.HotKey:SetFormattedText("Shift-%s", "2")
equal(Label(ActionButton1), "S2", "formatted native binding updates are observed")
Combat(true)
native = true; ActionButton1.HotKey:SetText("Alt-Mouse4"); native = false
equal(Label(ActionButton1), "AM4", "known text-only updates remain valid during combat")
LeaveCombat()
Suite.db.shortKeybinds = false; module:Apply()
equal(Label(ActionButton1), "Alt-Mouse4", "disable restores the latest native label")
equal(Label(MultiBar7Button12), "Shift--", "disable restores punctuation exactly")
equal(module.events.registered.UPDATE_BINDINGS, nil, "full disable unregisters events")

Suite.db.keybindFontStyle, Suite.db.keybindFont, Suite.db.keybindSize = true, "friz", 16
Suite.db.keybindOutline, Suite.db.keybindBold = "thick", true
module:Apply()
equal(Label(ActionButton1), "Alt-Mouse4", "font styling does not enable shortening")
equal(ActionButton1.HotKey.path, "Fonts\\FRIZQT__.TTF", "chosen font applies to the label")
equal(ActionButton1.HotKey.size, 17, "bold treatment adds one size unit")
equal(ActionButton1.HotKey.flags, "THICKOUTLINE", "thick outline uses the native font flag")
equal(ActionButton1.HotKey.shadowColor[4], 0.95, "bold treatment applies a strong shadow")
equal(ActionButton1.HotKey.shadowOffset[1], 1, "bold shadow uses its configured offset")
Suite.db.keybindBold = false; module:Apply()
equal(ActionButton1.HotKey.size, 16, "turning bold off restores selected size")
equal(ActionButton1.HotKey.shadowColor[1], 0.1, "turning bold off restores original shadow color")
equal(ActionButton1.HotKey.shadowOffset[1], 0.5, "turning bold off restores original shadow offset")
ActionButton1.HotKey:SetFont("Fonts\\MORPHEUS.TTF", 14) -- Optional flags omitted.
equal(ActionButton1.HotKey.path, "Fonts\\FRIZQT__.TTF", "native font writes retain Suite styling")
ActionButton1.HotKey:SetShadowOffset(2, -2)
Suite.db.keybindFontStyle = false; module:Apply()
equal(ActionButton1.HotKey.path, "Fonts\\MORPHEUS.TTF", "font disable restores the latest successful native font")
equal(ActionButton1.HotKey.size, 14, "font disable restores the latest native size")
equal(ActionButton1.HotKey.flags, "", "omitted native flags restore correctly")
equal(ActionButton1.HotKey.shadowOffset[1], 2, "shadow disable restores the latest native offset")
Suite.db.keybindFontStyle = true; module:Apply()
ActionButton1.HotKey:SetFont("missing.ttf", 15, "")
Suite.db.keybindFontStyle = false; module:Apply()
equal(ActionButton1.HotKey.path, "Fonts\\MORPHEUS.TTF", "failed external font does not corrupt restoration")

Suite.db.shortKeybinds, Suite.db.keybindFontStyle = true, true
module:Apply()
native = true; ActionButton1.HotKey:SetText(secret); native = false
equal(module.records[ActionButton1.HotKey].original, nil, "secret native text invalidates the restore snapshot")
Suite.db.shortKeybinds = false; module:Apply()
equal(Label(ActionButton1), secret, "disable never overwrites restricted native text with an old label")
native = true; ActionButton1.HotKey:SetText("Shift-3"); native = false
ActionButton1.HotKey:SetFontObject({ "Fonts\\SKURRI.TTF", 13, "OUTLINE" })
Suite.db.keybindFontStyle = false; module:Apply()
equal(ActionButton1.HotKey.path, "Fonts\\SKURRI.TTF", "font-object updates refresh the restore snapshot")
equal(ActionButton1.HotKey.shadowColor[4], 0.6, "font-object updates retain their shadow for restoration")

ActionButton2, ActionButton3, ActionButton4 = Button("Shift-4"), Button("Ctrl-5"), Button("Alt-6")
ActionButton2.HotKey.path = secret
ActionButton3.HotKey.GetShadowColor = nil
ActionButton4.forbidden = secret
Suite.db.shortKeybinds, Suite.db.keybindFontStyle = true, true
module:Apply()
equal(Label(ActionButton2), "S4", "shortening still works when font data is restricted")
equal(ActionButton2.HotKey.path, secret, "restricted font data is left native")
equal(Label(ActionButton3), "C5", "missing shadow API does not block independent shortening")
equal(ActionButton3.HotKey.size, 10, "missing restore capability leaves the font native")
equal(module.records[ActionButton4.HotKey], nil, "unreadable forbidden state skips the button")
STANDARD_TEXT_FONT, DAMAGE_TEXT_FONT = secret, secret
equal(module:FontPath("friz"), "Fonts\\FRIZQT__.TTF", "restricted standard font uses a known built-in fallback")
equal(module:FontPath("damage"), "Fonts\\FRIZQT__.TTF", "restricted damage font uses a known built-in fallback")
STANDARD_TEXT_FONT, DAMAGE_TEXT_FONT = saved.standard, saved.damage
Suite.db.shortKeybinds, Suite.db.keybindFontStyle = false, false; module:Apply()
equal(Label(ActionButton2), "Shift-4", "partial capability label restoration remains exact")
_G.ActionButton2, _G.ActionButton3, _G.ActionButton4 = nil, nil, nil

Suite.db.shortKeybinds = true
module:Apply()
local late = Button("Ctrl-Delete")
_G.ActionButton2 = late
local beforeQueue = frames
for _ = 1, 5 do module.events.OnEvent(module.events, "UPDATE_BINDINGS") end
equal(TimerCount(), 1, "binding event bursts coalesce")
Flush()
equal(Label(late), "CDEL", "discovery formats a later native button")
equal(frames, beforeQueue, "discovery needs no extra controller")
module:Queue(); local stale = timers[#timers].callback
Suite.db.shortKeybinds = false; module:Apply()
equal(TimerCount(), 0, "disable cancels discovery work")
stale()
equal(Label(late), "Ctrl-Delete", "stale timer cannot restyle disabled labels")
_G.ActionButton2 = nil

Suite.db.keybindFontStyle, Suite.db.shortKeybinds = true, true
Combat(true); module:Apply()
equal(ActionButton1.HotKey.path, "Fonts\\SKURRI.TTF", "combat activation defers fonts")
LeaveCombat()
equal(ActionButton1.HotKey.path, "Fonts\\FRIZQT__.TTF", "combat exit applies fonts")
equal(Label(ActionButton1), "S3", "combat exit applies short labels")
Combat(true)
native = true; ActionButton1.HotKey:SetFont("Fonts\\ARIALN.TTF", 11, "OUTLINE"); native = false
equal(ActionButton1.HotKey.path, "Fonts\\ARIALN.TTF", "native combat font update is left alone until combat exit")
LeaveCombat()
equal(ActionButton1.HotKey.path, "Fonts\\FRIZQT__.TTF", "combat exit restyles an updated native font")
Combat(true); Suite.db.keybindFontStyle, Suite.db.shortKeybinds = false, false; module:Apply()
equal(ActionButton1.HotKey.path, "Fonts\\FRIZQT__.TTF", "combat disable defers font restoration")
equal(module.events.registered.UPDATE_BINDINGS, nil, "combat disable immediately unregisters events")
LeaveCombat()
equal(ActionButton1.HotKey.path, "Fonts\\ARIALN.TTF", "combat disable restores the latest native font afterward")
equal(Label(ActionButton1), "Shift-3", "combat disable restores the latest native label afterward")

Suite.Set = function(key, value) Suite.db[key] = value; module:Apply() end
Suite.GUI:OpenPage("actionbars")
local controls = Suite.GUI.keybindControls
controls.shortKeybinds:OnClick()
equal(Suite.db.shortKeybinds, true, "GUI has an independent shortening control")
equal(Suite.db.keybindFontStyle, false, "GUI shortening keeps custom fonts off")
equal(Suite.db.actionBarSkin, false, "keybind controls do not enable the action bar skin")
equal(Suite.db.fullButtonRange, false, "keybind controls do not enable the range indicator")
controls.keybindFontStyle:OnClick(); controls.font:OnClick(); controls.outline:OnClick(); controls.keybindBold:OnClick()
equal(Suite.db.keybindFontStyle, true, "GUI enables font controls independently")
equal(Suite.db.keybindFont, "arial", "GUI cycles font families")
equal(Suite.db.keybindOutline, "default", "GUI cycles outline choices")
equal(Suite.db.keybindBold, true, "GUI exposes the heavier text treatment")
Suite.GUI.keybindSizeSlider:SetValue(20)
equal(Suite.db.keybindSize, 20, "GUI size slider saves its choice")
equal(Suite.GUI.keybindPreview.fontSize, 21, "preview reflects font size and bold treatment")
equal(Suite.GUI.keybindPreview.text, "SCM4   S1   N7   MWU", "preview reflects short labels")
equal(-Suite.GUI.keybindPanel.point[3] + Suite.GUI.keybindPanel.height <= Suite.GUI.content.height - 36, true, "keybind controls fit above the footer")
Suite.GUI:Select("overview")
equal(Suite.GUI.keybindPanel:IsShown(), false, "keybind controls hide on other pages")
Suite.db.shortKeybinds, Suite.db.keybindFontStyle = false, false; module:Apply()
Suite.db, Suite.pending, Suite.Set = saved.db, saved.pending, saved.set
CreateFrame, C_Timer, hooksecurefunc = saved.create, saved.timer, saved.hook
module.records, module.buttons, module.events = saved.records, saved.buttons, saved.events
STANDARD_TEXT_FONT, DAMAGE_TEXT_FONT = saved.standard, saved.damage
for _, name in ipairs(names) do _G[name] = previous[name] end
Combat(false)
