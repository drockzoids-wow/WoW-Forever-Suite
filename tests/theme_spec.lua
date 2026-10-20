local Suite, equal, Frame, SetCombat = ...
local theme, gui = Suite.Theme, Suite.GUI
local saved = { mode = Suite.db.borderColorMode, color = Suite.db.customBorderColor,
    unit = UnitClass, classes = C_ClassColor, raid = RAID_CLASS_COLORS, picker = ColorPickerFrame,
    borders = theme.borders, pending = Suite.pending, page = gui.page, shown = gui.frame:IsShown() }
local secret = { secret = true }
SetCombat(false)
theme.borders, Suite.pending = setmetatable({}, { __mode = "k" }), {}
local corrupt = { borderColorMode = "bogus", customBorderColor = { r = secret, g = 0.5, b = 0.2 } }
theme:Initialize(corrupt)
equal(corrupt.borderColorMode, "default", "invalid saved mode returns to default teal")
equal(corrupt.customBorderColor.r, 0.41, "restricted custom channel uses safe defaults")
for _, invalid in ipairs({ -1, 2, math.huge, 0/0, secret, "1" }) do
    corrupt.customBorderColor = { r = 0.1, g = invalid, b = 0.2 }
    theme:Initialize(corrupt)
    equal(corrupt.customBorderColor.g, 0.84, "malformed RGB is replaced as a complete color")
end
corrupt.borderColorMode, corrupt.customBorderColor = secret, secret
theme:Initialize(corrupt)
equal(corrupt.borderColorMode, "default", "restricted mode is never compared")
equal(corrupt.customBorderColor.b, 0.75, "restricted outer color is never indexed")
theme:Initialize({ borderColorMode = "custom", customBorderColor = { r = 0, g = 1, b = 0.4 } })
local profileState = Suite.InitializeDB({ borderColorMode = "custom", customBorderColor = { r = 0, g = 1, b = 0.25, extra = true } })
equal(profileState.customBorderColor.r, 0, "saved zero RGB survives normal database initialization")
equal(profileState.customBorderColor.extra, nil, "saved RGB stores only three channels")
local profileCopy = Suite.Profiles:Settings(profileState)
equal(profileCopy.borderColorMode, "custom", "shared and personal profiles include the border mode")
local restoredColor = Suite.InitializeDB(Suite.Copy(profileCopy))
equal(restoredColor.customBorderColor.g, 1, "profile copies preserve saved custom RGB through reload initialization")
equal(restoredColor.actionBarSkin, false, "color preferences do not enable a skin")
local pane, flat, art = Frame(), Frame(), Frame()
local writes = 0
pane.SetBackdropBorderColor = function(self, ...) assert(not InCombatLockdown(), "no backdrop recolor in combat"); writes = writes + 1; self.borderColor = {...} end
flat.SetColorTexture = function(self, ...) self.color = {...} end
art.SetVertexColor = function(self, ...) assert(not InCombatLockdown(), "no native art recolor in combat"); self.color = {...} end
theme:SetMode("default")
theme:Backdrop(pane, 0.45); theme:Texture(flat, 0.7); theme:Vertex(art, 0.95)
equal(pane.borderColor[1], 0.41, "fresh backdrop uses teal")
equal(flat.color[2], 0.84, "flat native skin edge uses teal")
equal(art.color[3], 0.75, "owned native border artwork uses teal")
theme:SetCustom(0, 0.3, 1)
equal(pane.borderColor[1], 0, "custom black channel stays valid")
equal(flat.color[2], 0.3, "existing flat borders change immediately")
equal(art.color[3], 1, "existing artwork borders change immediately")
equal(pane.borderColor[4], 0.45, "custom color preserves backdrop opacity")
equal(flat.color[4], 0.7, "custom color preserves texture opacity")
equal(art.color[4], 0.95, "custom color preserves art opacity")
theme:Texture(flat, 1)
equal(flat.color[2], 0.3, "hover uses custom RGB")
equal(flat.color[4], 1, "hover can still brighten a custom edge")
local late = Frame(); theme:Backdrop(late, 0.65)
equal(late.borderColor[3], 1, "late-created or newly enabled borders inherit current color")
late:Hide(); theme:SetCustom(0.2, 0.4, 0.6)
equal(late:IsShown(), false, "recolor never shows a disabled or hidden feature")
equal(late.borderColor[3], 0.6, "hidden borders are ready for their next opening")
for _, bad in ipairs({ secret, -1, math.huge, 0/0 }) do
    theme:SetCustom(bad, 0, 0)
    equal(Suite.db.customBorderColor.b, 0.6, "invalid picker data is never saved")
end
theme:SetMode(secret)
equal(Suite.db.borderColorMode, "custom", "restricted mode changes are rejected")
local token = "MAGE"
UnitClass = function() return "class", token end
C_ClassColor = { GetClassColor = function(class)
    return class == "MAGE" and { r = 0.1, g = 0.7, b = 0.9 } or { r = 0.9, g = 0.5, b = 0.1 }
end }
theme:SetMode("class")
equal(pane.borderColor[3], 0.9, "class mode uses the player's class")
token = "WARRIOR"; theme:Apply()
equal(pane.borderColor[1], 0.9, "class mode follows another character without saved RGB")
equal(Suite.db.customBorderColor.b, 0.6, "class mode remembers the previous custom color")
token = secret; theme:Apply()
equal(pane.borderColor[1], 0.41, "restricted class identity falls back to teal")
token = "MAGE"; C_ClassColor.GetClassColor = function() return { r = secret, g = 1, b = 0 } end
RAID_CLASS_COLORS = { MAGE = { r = 0.4, g = 0.5, b = 0.6 } }; theme:Apply()
equal(pane.borderColor[1], 0.4, "readable native class table can replace an unavailable class API result")
C_ClassColor.GetClassColor = function() error("unavailable") end
RAID_CLASS_COLORS = secret; theme:Apply()
equal(pane.borderColor[1], 0.41, "missing or rejected class colors fall back safely")
UnitClass = function() error("unavailable") end; theme:Apply()
equal(pane.borderColor[2], 0.84, "rejected player identity remains safe")
theme:SetMode("custom")
SetCombat(true)
local before = writes
theme:SetCustom(0.9, 0.1, 0.2); theme:SetMode("default"); theme:SetCustom(0.8, 0.2, 0.4)
equal(writes, before, "picker changes in combat do not repaint registered borders")
equal(pane.borderColor[1], 0.2, "old border remains until combat ends")
equal(type(Suite.pending.borderTheme), "function", "combat changes share one coalesced callback")
theme:Texture(flat, 0.55)
equal(flat.color[1], 0.2, "existing combat hover retains last safely applied RGB")
equal(flat.color[4], 0.55, "combat hover retains existing alpha feedback")
SetCombat(false)
local pending = Suite.pending.borderTheme; Suite.pending.borderTheme = nil; pending()
equal(pane.borderColor[1], 0.8, "only the final combat choice is applied")
equal(flat.color[3], 0.4, "combat exit updates texture and backdrop together")
local forbidden = Frame(); forbidden.IsForbidden = function() return true end
theme:Backdrop(forbidden)
equal(theme.borders[forbidden], nil, "forbidden objects are never registered")
pane.IsForbidden = function() return secret end
before = writes; theme:SetMode("default")
equal(writes, before, "unreadable forbidden state blocks a previously registered write")
pane.IsForbidden = nil
local picker = Frame(); picker.shown = false
picker.SetupColorPickerAndShow = function(self, info)
    self.info, self.swatchFunc, self.cancelFunc = info, info.swatchFunc, info.cancelFunc
    self.rgb = {info.r, info.g, info.b}; self:Show(); self.swatchFunc()
end
picker.GetColorRGB = function(self) return unpack(self.rgb) end
ColorPickerFrame = picker
theme:SetCustom(0.2, 0.3, 0.4); theme:SetMode("default")
theme:OpenPicker()
equal(picker.info.hasOpacity, false, "native wheel leaves individual border opacity under feature control")
equal(picker.info.r, 0.41, "new custom selection starts from the active border color")
picker.rgb = { 0.6, 0.1, 0.9 }; picker.swatchFunc()
equal(pane.borderColor[1], 0.6, "native wheel previews every registered border")
picker.cancelFunc({ r = 1, g = 1, b = 1 }); picker:Hide()
equal(Suite.db.borderColorMode, "default", "native Cancel restores the prior mode")
equal(Suite.db.customBorderColor.r, 0.2, "Cancel restores the previous remembered custom RGB")
equal(pane.borderColor[1], 0.41, "Cancel restores visible borders")
theme:OpenPicker(); picker.rgb = { 0.7, 0.8, 0.9 }; picker.swatchFunc(); picker:Hide()
equal(Suite.db.borderColorMode, "custom", "native Okay keeps the custom mode")
equal(Suite.db.customBorderColor.g, 0.8, "native Okay keeps selected RGB")
local oldSwatch, oldCancel = picker.swatchFunc, picker.cancelFunc
picker.swatchFunc, picker.cancelFunc = function() end, function() end
picker.rgb = { 0, 0, 0 }; oldSwatch(); oldCancel()
equal(Suite.db.customBorderColor.g, 0.8, "callbacks relinquish ownership when another picker user takes over")
picker:Show(); local owner = picker.swatchFunc; theme:OpenPicker()
equal(picker.swatchFunc, owner, "Suite does not replace a color picker already in use")
picker:Hide(); SetCombat(true); theme:OpenPicker()
equal(picker:IsShown(), false, "opening a native color wheel waits for user action outside combat")
SetCombat(false); picker.GetColorRGB = function() return secret, 0.3, 0.4 end
theme:OpenPicker(); picker.swatchFunc()
equal(Suite.db.customBorderColor.g, 0.8, "restricted native RGB is not stored")
picker.GetColorRGB = function() error("unavailable") end; picker.swatchFunc()
equal(Suite.db.customBorderColor.g, 0.8, "rejected picker reads preserve the last choice")
picker:Hide(); ColorPickerFrame = nil; theme:OpenPicker()
equal(Suite.db.customBorderColor.g, 0.8, "missing picker leaves color preferences intact")
gui:OpenPage("appearance")
equal(gui.page, "appearance", "Appearance is reachable through the normal navigation")
equal(gui.appearancePanel:IsShown(), true, "Appearance controls are displayed")
equal(Suite.SettingsCatalog:Search("border class color")[1].key, "borderColorMode", "search finds the shared color choice")
equal(Suite.SettingsCatalog:Search("wheel")[1].key, "customBorderColor", "search finds the native custom wheel")
gui.borderModeControls.class.OnClick()
equal(Suite.db.borderColorMode, "class", "My class button selects class mode")
gui.borderModeControls.default.OnClick()
equal(Suite.db.borderColorMode, "default", "Default teal button restores the default")
equal(gui.borderColorPreview.text, "Current: #69D6BF", "preview shows the actual rounded RGB hex")
gui.borderModeControls.custom.OnClick()
equal(Suite.db.customBorderColor.g, 0.8, "Custom button recalls the last selected color")
equal(gui.borderColorPreview.text, "Current: #B3CCE6", "preview follows recalled custom RGB")
picker.GetColorRGB = function(self) return unpack(self.rgb) end
ColorPickerFrame = picker; picker:Hide()
gui.borderColorButton.OnClick()
equal(picker:IsShown(), true, "Choose custom color button opens the native picker")
picker.rgb = { 0, 1, 0 }; picker.swatchFunc()
equal(gui.borderColorPreview.text, "Current: #00FF00", "wheel callback updates the visible hex preview")
picker.cancelFunc(); picker:Hide()
equal(gui.borderColorPreview.text, "Current: #B3CCE6", "native cancellation restores the page preview")
for _, button in pairs(gui.borderModeControls) do
    equal(button.point[2] + button:GetWidth() <= gui.appearancePanel:GetWidth(), true, "all three choices fit the active workspace width")
end
gui:Select("minimap")
equal(gui.appearancePanel:IsShown(), false, "color controls hide when leaving Appearance")

-- Recolor all real Suite-created borders retained by earlier feature fixtures.
theme.borders = saved.borders
local count, methods = 0, {}
for object, style in pairs(theme.borders) do
    count = count + 1; methods[style.method] = true
end
equal(count > 50, true, "feature fixtures register their real created borders")
equal(methods.SetBackdropBorderColor and methods.SetColorTexture and methods.SetVertexColor, true, "all three native border drawing paths are integrated")
theme:SetCustom(0.12, 0.34, 0.56)
equal(gui.frame.borderColor[1], 0.12, "actual Suite settings frame receives custom RGB")
local card = gui.homeCards[1]; card.OnEnter()
equal(card.borderColor[4], 1, "Home card hover still brightens its selected-color outline")
card.OnLeave()
equal(card.borderColor[4], 0.35, "Home card leave restores its quiet selected-color outline")
equal(Suite.Minimap.border.borderColor[2], 0.34, "actual minimap border receives custom RGB")
equal(Suite.Minimap.header.borderColor[3], 0.56, "actual minimap header follows the same color")
for object, style in pairs(theme.borders) do
    if not object.IsForbidden or object:IsForbidden() == false then
        equal(style.r, 0.12, "registered Suite border receives the custom theme")
        equal(style.b, 0.56, "registered Suite border receives all custom RGB channels")
    end
end
UnitClass, C_ClassColor, RAID_CLASS_COLORS, ColorPickerFrame = saved.unit, saved.classes, saved.raid, saved.picker
Suite.db.borderColorMode, Suite.db.customBorderColor = saved.mode, saved.color
theme:Apply(); Suite.pending = saved.pending
gui:Select(saved.page or "overview"); gui.frame:SetShown(saved.shown)
