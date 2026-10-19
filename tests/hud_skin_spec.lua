local Suite, equal, Frame, SetCombat = ...
local skin = Suite.HUDSkin
local saved = { db = Suite.db, pending = Suite.pending, create = CreateFrame, timer = C_Timer, hook = hooksecurefunc,
    properties = skin.properties, panels = skin.panels, watched = skin.watched, events = skin.events, set = Suite.Set,
    page = Suite.GUI.page, shown = Suite.GUI.frame:IsShown(), screen = GetPhysicalScreenSize,
    cvar = C_CVar, getCvar = GetCVar, setCvar = SetCVar, valuesCVar = skin.valuesCVar, loggingOut = skin.loggingOut }
local names = { "StatusTrackingBarManager", "StatusTrackingBarInfo", "BagsBar", "MicroMenu", "MainMenuBarBackpackButton",
    "CharacterBag0Slot", "CharacterBag1Slot", "CharacterBag2Slot", "CharacterBag3Slot", "CharacterReagentBag0Slot", "KeyRingButton" }
local savedAdjustment = STATUS_BAR_SIZE_ADJUSTMENT
STATUS_BAR_SIZE_ADJUSTMENT = 3
local globals = {}
for _, name in ipairs(names) do globals[name] = _G[name]; _G[name] = nil end
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
skin.properties, skin.panels, skin.watched, skin.events = {}, {}, {}, nil
local combat, native, textures, hooks, controllers = false, false, 0, 0, 0
local screenHeight, rasterMethods = 1080, true
GetPhysicalScreenSize = function() return 1920, screenHeight end
local timers, secret = {}, { secret = true }
local function Combat(value) combat = value; SetCombat(value) end
local function Native(callback)
    local previous = native; native = true; callback(); native = previous
end
local function Flush()
    local ready = timers; timers = {}
    for _, timer in ipairs(ready) do if not timer.cancelled then timer.callback() end end
end
local function TimerCount()
    local count = 0; for _, timer in ipairs(timers) do if not timer.cancelled then count = count + 1 end end; return count
end
local function LeaveCombat()
    Combat(false)
    local pending = Suite.pending; Suite.pending = {}
    for _, callback in pairs(pending) do callback() end
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
CreateFrame = function(...)
    assert(not combat, "HUD skin controller construction waits for combat")
    controllers = controllers + 1
    local frame = saved.create(...)
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    return frame
end
hooksecurefunc = function(...)
    assert(not combat, "HUD skin hooks install outside combat")
    hooks = hooks + 1; return saved.hook(...)
end
local function Widget()
    local object = Frame()
    object.shown, object.alpha, object.vertex = true, 0.8, { 0.9, 0.8, 0.7, 0.6 }
    object.IsForbidden = function(self) return self.forbidden or false end
    object.IsProtected = function(self) return self.protected or false end
    object.IsAnchoringRestricted = function(self) return self.restricted or false end
    object.GetAlpha = function(self) return self.alpha end
    object.SetAlpha = function(self, value)
        assert(native or not combat, "HUD native alpha writes defer combat")
        assert(native or Suite.IsReadable(value), "HUD skin cannot replay secret alpha")
        self.alpha = value
    end
    object.GetVertexColor = function(self) return unpack(self.vertex) end
    object.SetVertexColor = function(self, ...)
        assert(native or not combat, "HUD native color writes defer combat")
        self.vertex = { ... }
        for _, value in ipairs(self.vertex) do assert(native or Suite.IsReadable(value), "HUD skin cannot replay secret colors") end
    end
    object.SetAtlas = function(self, atlas) assert(native, "HUD skin keeps native assets"); self.atlas = atlas end
    object.GetTexture = function(self) return self.texture end
    object.SetTexture = function(self, asset) assert(native, "HUD skin keeps native assets"); self.texture = asset end
    for _, method in ipairs({ "SetPoint", "ClearAllPoints", "SetSize", "SetWidth", "SetHeight", "SetScale", "SetParent",
        "SetAttribute", "SetScript", "RegisterForClicks", "EnableMouse", "SetText", "SetFont", "RemoveMaskTexture",
        "SetRoundLayoutToNearestPixel", "SetSnapToPixelGrid", "SetTexelSnappingBias" }) do
        object[method] = function() error("HUD skin cannot alter native geometry, input, text or masks") end
    end
    object.CreateTexture = function(parent, name, layer, _, level)
        assert(not combat, "HUD skin creates artwork outside combat")
        assert(name == nil and (layer == "BACKGROUND" or layer == "OVERLAY"), "HUD artwork is anonymous on known layers")
        assert(level == -7 or level == 6 or level == 7, "HUD artwork uses supported sublevels")
        textures = textures + 1
        local texture = Frame()
        texture.parent, texture.points, texture.layer, texture.sublevel = parent, {}, layer, level
        texture.SetPoint = function(self, ...)
            assert(not combat, "HUD owned anchors defer combat"); self.points[#self.points + 1] = { ... }
        end
        texture.ClearAllPoints = function(self) assert(not combat, "owned divider anchors defer combat"); self.points = {} end
        texture.SetWidth = function(self, value) assert(not combat, "owned edge width defers combat"); self.width = value end
        texture.SetHeight = function(self, value) assert(not combat, "owned edge height defers combat"); self.height = value end
        if rasterMethods then
            texture.SetRoundLayoutToNearestPixel = function(self, value)
                assert(not combat, "owned pixel rounding defers combat"); self.roundPixels = value
            end
            texture.SetSnapToPixelGrid = function(self, value)
                assert(not combat, "owned texture snapping defers combat"); self.snapPixels = value
            end
            texture.SetTexelSnappingBias = function(self, value)
                assert(not combat, "owned texture bias defers combat"); self.snapBias = value
            end
        end
        texture.SetColorTexture = function(self, ...)
            assert(not combat, "HUD owned colors defer combat"); self.color = { ... }
        end
        texture.Show = function(self) assert(not combat, "HUD owned visibility defers combat"); self.shown = true end
        texture.Hide = function(self) assert(not combat, "HUD owned visibility defers combat"); self.shown = false end
        return texture
    end
    return object
end
local function Geometry(object, width, height)
    object.width, object.height = width, height
    object.GetSize = function(self) return self.width, self.height end
    object.SetSize = function(self, w, h)
        assert(native or not combat, "progress dimensions defer combat")
        assert(native or (Suite.IsReadable(w) and Suite.IsReadable(h)), "progress dimensions cannot replay secrets")
        self.width, self.height = w, h; self.sizes = (self.sizes or 0) + 1
    end
    object.SetWidth = function(self, value) self:SetSize(value, self.height) end
    object.SetHeight = function(self, value) self:SetSize(self.width, value) end
    return object
end
local function Button(micro)
    local button = Geometry(Widget(), 45, 45)
    button.icon, button.SlotHighlightTexture, button.FreeSlots = Geometry(Widget(), 32, 32), Widget(), Widget()
    button.icon.parent = button
    button.icon.centerX, button.icon.centerY = 499, 401
    button.normal, button.pushed, button.highlight = Widget(), Widget(), Widget()
    button.normal.texture, button.pushed.texture, button.highlight.texture = "normal-icon", "pushed-icon", "hover-icon"
    button.GetNormalTexture = function(self) return self.normal end
    button.GetPushedTexture = function(self) return self.pushed end
    button.GetHighlightTexture = function(self) return self.highlight end
    button.state = "NORMAL"
    button.GetButtonState = function(self) return self.state end
    button.SetButtonState = function(self, value) self.state = value; return "native-state-result" end
    button.IsMouseOver = function(self) return self.hovered or false end
    button.UpdateTextures = function() return "native-art-result" end
    button.SetScale = function(self, value) assert(native, "skin never changes native button scale"); self.scale = value end
    button.OnEnter = function(self) self.enters = (self.enters or 0) + 1 end
    button.OnClick = function(self) self.clicksReceived = (self.clicksReceived or 0) + 1 end
    if micro then
        button.Background, button.PushedBackground = Widget(), Widget()
        button.NotificationOverlay, button.FlashBorder, button.Portrait = Widget(), Widget(), Widget()
    end
    return button
end
local function Pool(list)
    return { list = list, EnumerateActive = function(self)
        local index = 0
        return function() index = index + 1; return self.list[index] end
    end }
end
local function Progress()
    local bar = Geometry(Widget(), 1189, 14)
    bar.StatusBar = Geometry(Widget(), 1189, 14)
    -- Native XML puts prediction on the wrapper and the StatusBar one frame level above it.
    bar.frameLevel, bar.StatusBar.frameLevel, bar.StatusBar.parent = 1, 2, bar
    bar.StatusBar.Background, bar.StatusBar.BarTexture = Widget(), Widget()
    bar.StatusBar.GainFlareAnimationTexture = Widget()
    bar.ExhaustionLevelFillBar, bar.ExhaustionTick, bar.OverlayFrame = Geometry(Widget(), 300, 11), Widget(), Widget()
    bar.ExhaustionLevelFillBar.parent, bar.ExhaustionLevelFillBar.layer, bar.ExhaustionLevelFillBar.sublevel = bar, "ARTWORK", -1
    bar.StatusBar.BarTexture.parent, bar.StatusBar.BarTexture.layer, bar.StatusBar.BarTexture.sublevel = bar.StatusBar, "BORDER", 0
    local label = Widget()
    bar.OverlayFrame.Text = label
    label.shown, label.text = false, "native progress label"
    label.IsShown = function(self) return self.shown end
    label.SetShown = function(self, shown)
        assert(native or not combat or (self:IsProtected() == false and bar:IsProtected() == false
            and bar.OverlayFrame:IsProtected() == false), "protected native label visibility defers combat")
        assert(native or Suite.IsReadable(shown), "native progress label cannot replay secrets")
        if Suite.IsReadable(shown) and type(shown) == "boolean" then
            if shown then self:Show() else self:Hide() end
        else self.shown = shown end
    end
    label.Show = function(self) self.shown = true end
    label.Hide = function(self) self.shown = false end
    bar.UpdateOverlayFrameText = function(self)
        assert(not combat, "native honor formatter waits for combat")
        self.formats = (self.formats or 0) + 1; self.OverlayFrame.Text.text = "native formatter result"
    end
    bar.UpdateTick = function(self)
        assert(not combat, "native rested tick update waits for combat")
        self.tickUpdates = (self.tickUpdates or 0) + 1
        self.ExhaustionLevelFillBar:SetWidth(self.width / 4)
    end
    bar.StatusBar.BarTexture.texture = "native-progress-fill"
    bar.StatusBar.GetValue = function() error("HUD skin must not read progress values") end
    bar.StatusBar.SetValue = function() error("HUD skin must not change native progress") end
    bar.StatusBar.SetStatusBarTexture = function() error("HUD skin must not replace native status-bar management") end
    return bar
end
local function Container()
    local container = Geometry(Widget(), 1192, 17)
    container.bars = { Progress(), Progress(), Progress(), Progress() }
    container.current = container.bars[1]
    container.BarFrameTexture = Widget()
    container.divider = { BarDividerTexture = Widget() }
    container.HorizontalDividersPool = Pool({ container.divider })
    container.GetShownBar = function(self) return self.current end
    container.UpdateDividers = function() return "native-divider-result" end
    container.ApplyPendingBarToShow = function() end
    container.ResizeContainerBars = function(self)
        for _, bar in ipairs(self.bars) do
            bar:SetSize(self.width - STATUS_BAR_SIZE_ADJUSTMENT, self.height - STATUS_BAR_SIZE_ADJUSTMENT)
            bar.StatusBar:SetSize(bar.width, bar.height)
        end
    end
    return container
end
local function Enabled(status, bags, micro)
    Suite.db.statusBarSkin, Suite.db.bagBarSkin, Suite.db.microBarSkin = status == true, bags == true, micro == true
    skin:Apply()
end
local function PanelShown(parent)
    return skin.panels[parent] and skin.panels[parent].background.shown == true or false
end
local function DrawsAbove(texture, other)
    local level, otherLevel = texture.parent.frameLevel, other.parent.frameLevel
    if level ~= otherLevel then return level > otherLevel end
    local layers = { BACKGROUND = 1, BORDER = 2, ARTWORK = 3, OVERLAY = 4 }
    if texture.layer ~= other.layer then return layers[texture.layer] > layers[other.layer] end
    return texture.sublevel > other.sublevel
end
Combat(false); skin:Apply()
equal(controllers, 0, "disabled HUD skins create no controller")
equal(textures, 0, "disabled HUD skins create no art")
equal(hooks, 0, "disabled HUD skins install no hooks")
equal(TimerCount(), 0, "disabled HUD skins schedule no work")
for _, key in ipairs({ "statusBarSkin", "bagBarSkin", "microBarSkin" }) do
    equal(Suite.InitializeDB(nil)[key], false, "HUD preference starts off: " .. key)
    equal(Suite.InitializeDB({ [key] = true })[key], true, "HUD preference persists: " .. key)
    equal(Suite.InitializeDB({ [key] = secret })[key], false, "HUD preference rejects hidden data: " .. key)
end
Enabled(true, true, true)
equal(textures, 0, "enabled skins tolerate unavailable native bars")
equal(skin.events.registered.ADDON_LOADED, true, "HUD skin observes late native loading")
StatusTrackingBarInfo = { BarsEnum = { Experience = 1, Honor = 2, Reputation = 3, Artifact = 4 } }
local first, second = Container(), Container()
StatusTrackingBarManager = Widget()
StatusTrackingBarManager.barContainers = { first, second }
StatusTrackingBarManager.UpdateBarsShown = function() return "native-manager-result" end
StatusTrackingBarManager.CheckForLayoutChange = function() end
BagsBar = Widget()
BagsBar.BorderArt, BagsBar.divider = Widget(), Widget()
BagsBar.HorizontalDividersPool, BagsBar.VerticalDividersPool = Pool({ BagsBar.divider }), Pool({})
BagsBar.Layout, BagsBar.UpdateDividers = function() end, function() end
BagsBar.SetScale = function(self, value) assert(native, "skin never changes native bag bar scale"); self.scale = value end
for index = 5, #names do _G[names[index]] = Button(); _G[names[index]].parent = BagsBar end
MicroMenu = Widget()
MicroMenu.BorderArt, MicroMenu.BackgroundArt = Widget(), Widget()
local character, menuButton = Button(true), Button(true)
MicroMenu.children = { character, menuButton, Widget() }
MicroMenu.Layout = function() end
MicroMenu.SetScale = function(self, value) assert(native, "skin never changes native micro menu scale"); self.scale = value end
MicroMenu.AddButton = function(self, button) self.children[#self.children + 1] = button; button.parent = self end
character.parent, menuButton.parent = MicroMenu, MicroMenu
local click = character.OnClick
skin.events:OnEvent("ADDON_LOADED", "Blizzard_StatusTrackingBar"); Flush()
for _, container in ipairs({ first, second }) do
    for index = 1, 3 do
        local bar = container.bars[index]
        equal(PanelShown(bar.StatusBar), true, "both containers style each supported progress bar")
        equal(bar.StatusBar.Background.vertex[4], 0, "native progress background is suppressed")
        equal(bar.StatusBar.BarTexture.texture, "native-progress-fill", "native progress fill asset is retained")
        local panel = skin.panels[bar.StatusBar]
        equal(DrawsAbove(panel.background, bar.ExhaustionLevelFillBar), false, "slate background cannot cover or dim native rested prediction")
        equal(DrawsAbove(bar.StatusBar.BarTexture, bar.ExhaustionLevelFillBar), true, "earned XP still draws over native prediction")
        equal(DrawsAbove(panel.edges[1], bar.ExhaustionLevelFillBar), true, "teal outline remains above rested prediction")
        equal(panel.background.points[1][2], bar.StatusBar, "background follows visible progress bounds")
        equal(panel.background.points[2][2], bar.StatusBar, "background follows opposite visible progress corner")
    end
    equal(PanelShown(container.bars[4].StatusBar), false, "other progress bar types stay native")
    equal(container.BarFrameTexture.vertex[4], 0, "supported active bar removes ornamental frame")
    equal(container.divider.BarDividerTexture.vertex[4], 0, "supported active bar removes native segments")
end
equal(first.bars[1].ExhaustionLevelFillBar.vertex[4], 0.6, "rested XP prediction stays native")
equal(first.bars[1].ExhaustionTick.shown, true, "native rested tick remains available")
equal(first.bars[1].StatusBar.GainFlareAnimationTexture.vertex[4], 0.6, "native gain animation is retained")
equal(first.bars[1].OverlayFrame.shown, true, "native progress text frame is retained")
equal(BagsBar.BorderArt.vertex[4], 0, "bag bar ornate frame is suppressed")
equal(BagsBar.divider.alpha, 0, "bag bar divider art is suppressed")
for index = 5, #names do
    local button = _G[names[index]]
    equal(PanelShown(button), true, "native bag button is skinned: " .. names[index])
    equal(button.normal.vertex[4], 0, "native bag frame art is suppressed")
    equal(button.icon.vertex[4], 0.6, "native bag icon and mask are preserved")
    local panel = skin.panels[button]
    -- Resolve the plate from its actual two-point anchors. Native icon bounds are
    -- smaller and off-center relative to the 45-unit clickable button.
    local top, bottom = panel.background.points[1], panel.background.points[2]
    local left, low, width, height = top[2]:GetRect()
    local right, base = bottom[2]:GetRect()
    right = right + bottom[2]:GetWidth() + (bottom[4] or 0)
    base = base + (bottom[5] or 0)
    left = left + (top[4] or 0)
    low = low + height + (top[5] or 0)
    local iconLeft, iconBottom, iconWidth, iconHeight = button.icon:GetRect()
    equal(left, iconLeft, "bag plate starts at the visible icon rather than the click target")
    equal(low, iconBottom + iconHeight, "bag plate follows the native icon's vertical offset")
    equal(right - left, iconWidth, "bag plate fits the narrower native icon")
    equal(low - base, iconHeight, "bag plate fits the native icon height")
end
equal(MainMenuBarBackpackButton.FreeSlots.shown, true, "native free-slot count is untouched")
equal(CharacterBag0Slot.SlotHighlightTexture.vertex[4], 0.6, "native open/slot-match highlight is retained")
equal(MicroMenu.BorderArt.vertex[4], 0, "micro menu ornamental frame is suppressed")
equal(MicroMenu.BackgroundArt.vertex[4], 0, "micro menu ornamental background is suppressed")
equal(PanelShown(character), true, "micro menu child gets a slate surface")
equal(character.Background.vertex[4], 0, "micro menu normal background is suppressed")
equal(character.PushedBackground.vertex[4], 0, "micro menu pushed background is suppressed")
equal(character.normal.texture, "normal-icon", "micro menu native glyph is retained")
equal(character.FlashBorder.vertex[4], 0.6, "native micro menu alerts remain visible")
equal(character.NotificationOverlay.shown, true, "native micro notifications remain visible")
equal(character.Portrait.vertex[4], 0.6, "native character portrait is retained")
equal(character.OnClick, click, "micro menu native click script is unchanged")
character:OnClick(); character:OnEnter()
equal(character.clicksReceived, 1, "native micro menu click dispatch still works")
equal(character.enters, 1, "native tooltip/hover script still runs")
equal(skin.panels[character].edges[1].color[4], 1, "Suite micro hover brightens the edge")
equal(character:SetButtonState("PUSHED"), "native-state-result", "native button state return is retained")
equal(skin.panels[character].background.color[1], 0.10, "micro menu pressed state uses meter fill")
character:SetButtonState("NORMAL"); character:OnLeave()
equal(skin.panels[character].edges[1].color[4], 0.55, "Suite resting border returns after hover")
MainMenuBarBackpackButton:OnEnter()
equal(skin.panels[MainMenuBarBackpackButton].edges[1].color[4], 1, "bag hover uses the same teal edge")
local beforeTextures, beforeHooks = textures, hooks
skin:Apply(); skin:Apply()
equal(textures, beforeTextures, "reapplying HUD skins reuses textures")
equal(hooks, beforeHooks, "reapplying HUD skins reuses hooks")
equal(StatusTrackingBarManager:UpdateBarsShown(), "native-manager-result", "native progress manager return is retained")
BagsBar:Layout(); MicroMenu:Layout()
equal(TimerCount(), 1, "independent native update bursts coalesce into one pass")
Flush()
local late = Button(true)
MicroMenu:AddButton(late); Flush()
equal(PanelShown(late), true, "later native micro menu children are discovered")
MicroMenu.children = { character, menuButton }; MicroMenu:Layout(); Flush()
equal(PanelShown(late), false, "removed micro menu child loses Suite art")
equal(late.Background.vertex[4], 0.6, "removed micro menu child regains native background")
local previousNormal = CharacterBag0Slot.normal
CharacterBag0Slot.normal = Widget(); CharacterBag0Slot:UpdateTextures(); Flush()
equal(previousNormal.vertex[4], 0.6, "replaced native bag texture is restored")
equal(CharacterBag0Slot.normal.vertex[4], 0, "replacement bag frame texture receives the skin")
CharacterBag0Slot.shown = false; skin:Refresh()
equal(CharacterBag0Slot.shown, false, "skinning never forces a hidden native bag button to show")
character.state = secret; character:OnLeave()
equal(skin.panels[character].background.color[1], 0.035, "hidden button state cannot select pressed styling")
character.state = "NORMAL"
first.current = first.bars[4]; first:ApplyPendingBarToShow(); Flush()
equal(first.BarFrameTexture.vertex[4], 0.6, "unsupported active progress bar restores native container frame")
equal(first.divider.BarDividerTexture.vertex[4], 0.6, "unsupported active progress bar restores native segments")
first.current = secret; StatusTrackingBarManager:UpdateBarsShown(); Flush()
equal(first.BarFrameTexture.vertex[4], 0.6, "hidden active-bar reference cannot suppress shared chrome")
first.current = first.bars[3]; first:ApplyPendingBarToShow(); Flush()
equal(first.BarFrameTexture.vertex[4], 0, "switching back to reputation reapplies shared chrome")
local replacement = { BarDividerTexture = Widget() }
first.HorizontalDividersPool.list = { replacement }; first:UpdateDividers(); Flush()
equal(first.divider.BarDividerTexture.vertex[4], 0.6, "released native divider art is restored")
equal(replacement.BarDividerTexture.vertex[4], 0, "new native divider art is discovered")
Native(function() BagsBar.divider:SetAlpha(0.45); character.Background:SetVertexColor(0.2, 0.3, 0.4, 0.7) end)
Flush()
equal(BagsBar.divider.alpha, 0, "latest native divider update stays suppressed while enabled")
Enabled(false, true, false)
equal(first.bars[1].StatusBar.Background.vertex[4], 0.6, "disabling progress skin restores its native background")
equal(PanelShown(first.bars[1].StatusBar), false, "disabling progress skin hides its own panel")
equal(character.Background.vertex[4], 0.7, "disabling micro skin restores latest native color alpha")
equal(character.Background.vertex[1], 0.2, "disabling micro skin restores latest native color")
equal(PanelShown(character), false, "micro skin disables independently")
equal(PanelShown(MainMenuBarBackpackButton), true, "bag skin remains enabled independently")
StatusTrackingBarManager:UpdateBarsShown(); MicroMenu:Layout(); character:OnEnter()
equal(TimerCount(), 0, "disabled progress and micro hooks do not schedule bag work")
Enabled(false, false, false)
equal(BagsBar.divider.alpha, 0.45, "disable restores latest native divider alpha")
equal(MainMenuBarBackpackButton.normal.vertex[4], 0.6, "disable restores original bag state color")
equal(MicroMenu.BorderArt.vertex[4], 0.6, "disable restores original micro container art")
equal(Suite.db.actionBarSkin, false, "HUD skins do not enable action bar styling")
equal(Suite.db.questTrackerSkin, false, "HUD skins do not enable quest tracker styling")
Enabled(true, true, true)
character.Background.vertex[1] = secret; skin:Refresh()
equal(PanelShown(character), false, "unreadable button art yields the complete button to native")
equal(character.PushedBackground.vertex[4], 0.6, "partial button yields readable companion art to native")
equal(character.Background.vertex[1], secret, "unreadable observation is never replayed or guessed")
Native(function() character.Background:SetVertexColor(0.3, 0.4, 0.5, 0.8) end); Flush()
equal(PanelShown(character), true, "later readable native setter recovers button styling")
CharacterBag1Slot.forbidden = true
CharacterBag2Slot.restricted = true
CharacterBag3Slot.GetHighlightTexture = nil
skin:Refresh()
equal(PanelShown(CharacterBag1Slot), false, "forbidden bag button receives no Suite art")
equal(PanelShown(CharacterBag2Slot), false, "restricted bag button receives no Suite art")
equal(PanelShown(CharacterBag3Slot), false, "partial bag button stays native")
equal(CharacterBag3Slot.normal.vertex[4], 0.6, "partial bag button restores known state textures")
first.bars[1].StatusBar.Background.vertex[1] = secret; skin:Refresh()
equal(PanelShown(first.bars[1].StatusBar), false, "hidden native progress color yields its surface")
equal(first.bars[1].StatusBar.Background.vertex[1], secret, "hidden progress color is never replaced")
Native(function() first.bars[1].StatusBar.Background:SetVertexColor(0.9, 0.8, 0.7, 0.6) end); Flush()
equal(PanelShown(first.bars[1].StatusBar), true, "readable progress setter recovers its surface")
local createProgressTexture = first.bars[1].CreateTexture
first.bars[1].CreateTexture = nil; skin:Refresh()
equal(PanelShown(first.bars[1].StatusBar), false, "missing wrapper artwork capability yields the progress skin to native")
equal(first.bars[1].StatusBar.Background.vertex[4], 0.6, "missing wrapper capability restores native background")
first.bars[1].CreateTexture = createProgressTexture; skin:Refresh()
equal(PanelShown(first.bars[1].StatusBar), true, "returning wrapper capability recovers the progress skin")
Native(function() BagsBar.divider:SetAlpha(secret) end); Flush()
equal(BagsBar.divider.alpha, secret, "hidden native divider alpha stays on its native path")
Enabled(false, false, false)
equal(BagsBar.divider.alpha, secret, "disabling cannot replay an older divider alpha after a hidden native update")
beforeTextures, beforeHooks = textures, hooks
Combat(true); Enabled(true, true, true)
equal(textures, beforeTextures, "combat enabling creates no HUD textures")
equal(hooks, beforeHooks, "combat enabling installs no HUD hooks")
equal(PanelShown(character), false, "combat enabling defers native visual changes")
character:OnEnter(); MicroMenu:Layout(); LeaveCombat()
equal(PanelShown(character), true, "combat exit completes the requested skin")
equal(skin.events.registered.ADDON_LOADED, true, "retained show/update hooks preserve deferred enable registration")
Combat(true); Native(function() character.Background:SetVertexColor(0.7, 0.6, 0.5, 0.4) end)
equal(character.Background.vertex[4], 0.4, "native combat color update runs without Suite replacement")
character:SetButtonState("PUSHED"); character:OnEnter()
Enabled(false, false, false)
equal(PanelShown(character), true, "combat disable defers owned visibility changes")
LeaveCombat()
equal(PanelShown(character), false, "combat exit completes disable")
equal(character.Background.vertex[4], 0.4, "combat disable restores latest native requested alpha")
equal(TimerCount(), 0, "combat disable leaves no scheduled worker")
Enabled(false, true, false); BagsBar:Layout()
local stale = timers[#timers]
Enabled(false, false, false)
stale.callback()
equal(PanelShown(MainMenuBarBackpackButton), false, "cancelled worker cannot revive disabled art")
equal(TimerCount(), 0, "disable cancels its timer")
Suite.Set = function(key, value) Suite.db[key] = value; skin:Apply() end
SlashCmdList.WOWFOREVERSUITE("bars")
equal(Suite.GUI.page, "bars", "bars slash command opens the new page")
equal(Suite.GUI.tabs.bars.label.text, "Bars & Buttons", "new page has a clear sidebar label")
equal(Suite.GUI.rows[1].label.text, "XP, honor and reputation bars", "progress skin has a settings toggle")
equal(Suite.GUI.rows[2].label.text, "Suite bag bar skin", "bag skin has a settings toggle")
equal(Suite.GUI.rows[3].label.text, "Suite micro menu skin", "micro skin has a settings toggle")
equal(Suite.GUI.keybindPanel:IsShown(), false, "HUD page hides action-bar font controls")
equal(-Suite.GUI.rows[3].point[3] + Suite.GUI.rows[3].height <= Suite.GUI.content.height - 36, true, "HUD rows fit above footer")
equal(-Suite.GUI.tabs.chat.point[3] + Suite.GUI.tabs.chat.height <= Suite.GUI.frame.height - 77 - 44, true, "all sixteen tabs fit above sidebar stamp")
for index, key in ipairs({ "statusBarSkin", "bagBarSkin", "microBarSkin" }) do
    Suite.GUI.rows[index]:OnClick()
    equal(Suite.db[key], true, "HUD settings control enables only its preference: " .. key)
end
Enabled(false, false, false)
for _, key in ipairs({ "progressBarValues", "progressBarCustomSize", "progressBarSegments" }) do
    equal(Suite.InitializeDB(nil)[key], false, "progress option starts off: " .. key)
    equal(Suite.InitializeDB({ [key] = true })[key], true, "progress option persists: " .. key)
    equal(Suite.InitializeDB({ [key] = secret })[key], false, "progress option rejects hidden preference: " .. key)
end
local options = {
    { {}, 600, 14 }, { { progressBarWidth = 257.4, progressBarHeight = 23.6 }, 257, 24 },
    { { progressBarWidth = 1, progressBarHeight = 100 }, 120, 40 },
    { { progressBarWidth = 2000, progressBarHeight = 1 }, 1600, 6 },
    { { progressBarWidth = secret, progressBarHeight = math.huge }, 600, 14 },
    { { progressBarWidth = 0 / 0, progressBarHeight = -1 }, 600, 14 },
}
for _, data in ipairs(options) do
    local db = Suite.InitializeDB(data[1])
    equal(db.progressBarWidth, data[2], "progress width is normalized")
    equal(db.progressBarHeight, data[3], "progress thickness is normalized")
end
first.current, second.current = first.bars[1], second.bars[3]
Suite.db.progressBarValues, Suite.db.progressBarSegments, Suite.db.progressBarCustomSize = true, true, true
Suite.db.progressBarWidth, Suite.db.progressBarHeight = 251, 23
skin:Apply()
equal(first.width, 1192, "dependent progress options do not enable their skin")
equal(first.bars[1].OverlayFrame.Text.shown, false, "disabled skin leaves native label visibility alone")
Enabled(true, false, false)
for _, container in ipairs({ first, second }) do
    equal(container.width, 254, "both native slots use the precise visible width plus native inset")
    equal(container.height, 26, "both native slots use the chosen thickness plus native inset")
    for index = 1, 3 do
        local bar, panel = container.bars[index], skin.panels[container.bars[index].StatusBar]
        equal(bar.width, 251, "native resizing updates wrapper width")
        equal(bar.StatusBar.width, 251, "native resizing updates visible width")
        equal(bar.StatusBar.height, 23, "native resizing updates visible thickness")
        equal(bar.ExhaustionLevelFillBar.height, 23, "rested prediction follows thickness")
        equal(bar.ExhaustionLevelFillBar.width, 251 / 4, "native rested updater recalculates prediction width")
        equal(DrawsAbove(panel.background, bar.ExhaustionLevelFillBar), false, "custom dimensions retain visible rested prediction")
        equal(bar.OverlayFrame.Text.shown, true, "each supported native label can stay visible")
        equal(bar.OverlayFrame.Text.text, "native formatter result", "native formatter supplies the label")
        equal(#panel.segments, 9, "nine boundaries mark ten sections")
        for boundary, line in ipairs(panel.segments) do
            equal(DrawsAbove(line, bar.ExhaustionLevelFillBar), true, "10% boundaries stay above rested prediction")
            equal(line.shown, true, "10% boundary is visible")
            equal(#line.points, 2, "10% boundary spans the native fill")
            equal(line.points[1][4], 251 * boundary / 10, "10% boundary follows exact width")
        end
    end
    equal(PanelShown(container.bars[4].StatusBar), false, "other bar types retain native presentation")
end
local xp, honor = first.bars[1], first.bars[2]
beforeTextures, beforeHooks = textures, hooks
skin:Apply(); skin:Apply()
equal(textures, beforeTextures, "progress controls reuse their labels and dividers")
equal(hooks, beforeHooks, "progress controls reuse setter hooks")
Native(function() xp.OverlayFrame.Text:Hide(); honor.OverlayFrame.Text:SetShown(false) end)
equal(TimerCount(), 1, "native label hide requests coalesce")
Flush()
equal(xp.OverlayFrame.Text.shown, true, "native leave cannot permanently hide always-visible XP")
equal(honor.OverlayFrame.Text.shown, true, "native leave cannot permanently hide always-visible honor")
Native(function() xp.OverlayFrame.Text:Show() end); Flush()
Suite.db.progressBarValues = false; skin:Apply()
equal(xp.OverlayFrame.Text.shown, true, "value toggle restores latest native always-show preference")
equal(honor.OverlayFrame.Text.shown, false, "value toggle restores latest native hidden preference")
local formats = honor.formats
honor.shown = false; Suite.db.progressBarValues = true; skin:Apply()
equal(honor.formats, formats, "hidden honor bar does not request data formatting")
honor.shown = true; Native(function() honor.OverlayFrame.Text:Hide() end); Flush()
equal(honor.formats > formats, true, "visible honor reuses its native formatter")
-- Cosmetic visibility is independent of layout/formatting and can be maintained in combat.
local combatLabels = { xp.OverlayFrame.Text, honor.OverlayFrame.Text, second.bars[3].OverlayFrame.Text }
beforeTextures, beforeHooks = textures, hooks
formats = honor.formats
Combat(true)
for _, text in ipairs(combatLabels) do
    Native(function() text:Hide() end)
    equal(text.shown, true, "XP/honor/reputation values survive native combat hide requests")
    Native(function() text:SetShown(false) end)
    equal(text.shown, true, "native combat SetShown(false) is corrected immediately")
end
equal(TimerCount(), 0, "combat text maintenance creates no refresh timer")
equal(textures, beforeTextures, "combat text maintenance constructs no textures")
equal(hooks, beforeHooks, "combat text maintenance installs no hooks")
equal(honor.formats, formats, "combat text maintenance never requests data formatting")
equal(honor.OverlayFrame.Text.text, "native formatter result", "combat text uses existing native formatted values")
Native(function() xp.OverlayFrame.Text:Show() end)
Suite.db.progressBarValues = false; skin:Apply()
equal(xp.OverlayFrame.Text.shown, true, "combat disable restores latest native visible preference")
equal(honor.OverlayFrame.Text.shown, false, "combat disable restores latest native hidden preference")
equal(second.bars[3].OverlayFrame.Text.shown, false, "combat disable restores reputation visibility")
Suite.db.progressBarValues = true; skin:Apply()
equal(honor.OverlayFrame.Text.shown, true, "prepared label visibility can be re-enabled in combat")
local honorText = honor.OverlayFrame.Text
for _, restricted in ipairs({ true, secret }) do
    honorText.protected = restricted
    Native(function() honorText:Hide() end)
    equal(honorText.shown, false, "protected/secret label protection skips combat writes")
    honorText.protected = false
    honor.protected = restricted
    skin:Apply(); equal(honorText.shown, false, "protected/secret progress bar skips combat writes")
    honor.protected = false
    honor.OverlayFrame.protected = restricted
    skin:Apply(); equal(honorText.shown, false, "protected/secret overlay skips combat writes")
    honor.OverlayFrame.protected = false
    skin:Apply(); equal(honorText.shown, true, "readable unprotected label resumes cosmetic visibility")
end
local protectionMethod = honorText.IsProtected
honorText.IsProtected = nil
Native(function() honorText:Hide() end)
equal(honorText.shown, false, "missing protection predicate defers combat visibility")
honorText.IsProtected = protectionMethod
Native(function() honorText:SetShown(secret) end)
equal(honorText.shown, secret, "secret combat shown result stays native")
Native(function() honorText:SetShown(false) end)
equal(honorText.shown, true, "readable combat visibility recovers without secret replay")
LeaveCombat()
Suite.db.progressBarValues = false; skin:Apply()
equal(honorText.shown, false, "combat nested setter correction preserves native hide restoration")
Suite.db.progressBarValues = true; skin:Apply()
Suite.db.progressBarSegments = false; skin:Apply()
equal(skin.panels[xp.StatusBar].segments[1].shown, false, "sections can be hidden independently")
Suite.db.progressBarSegments = true; skin:Apply()
equal(textures, beforeTextures, "showing sections again reuses existing artwork")
-- Native Edit Mode can change one axis while carrying forward the Suite's other axis.
Native(function() first:SetSize(903, first:GetHeight()); first:ResizeContainerBars() end); Flush()
equal(first.width, 254, "custom size survives native Edit Mode size updates")
Native(function() first:SetHeight(22) end); Flush()
Suite.db.progressBarCustomSize = false; skin:Apply()
equal(first.width, 903, "disable restores latest native width")
equal(first.height, 22, "disable restores latest independently changed native height")
equal(second.width, 1192, "disable restores other slot's original width")
equal(second.height, 17, "disable restores other slot's original height")
equal(xp.StatusBar.width, 900, "native children are resized when native dimensions return")
equal(xp.StatusBar.height, 19, "native child thickness is restored")
equal(xp.ExhaustionLevelFillBar.height, 11, "rested prediction's native thickness is restored")
equal(xp.ExhaustionLevelFillBar.width, 900 / 4, "restored width recalculates native rested prediction")
equal(skin.panels[xp.StatusBar].segments[9].points[1][4], 810, "dividers immediately follow restored native width")
Suite.db.progressBarCustomSize = true; skin:Apply()
first.current = first.bars[4]; first:ApplyPendingBarToShow(); Flush()
equal(first.width, 903, "switching to an unsupported bar restores shared native width")
equal(first.bars[4].StatusBar.width, 900, "unsupported active bar uses its native size")
equal(xp.ExhaustionLevelFillBar.height, 11, "inactive custom slot restores prediction thickness")
first.current = xp; first:ApplyPendingBarToShow(); Flush()
equal(first.width, 254, "returning to XP restores custom dimensions")
Suite.db.progressBarCustomSize = false; skin:Apply()
first.bars[4].restricted = true; Suite.db.progressBarCustomSize = true; skin:Apply()
equal(first.width, 903, "restricted native children prevent partial container resizing")
equal(xp.ExhaustionLevelFillBar.height, 11, "failed container preflight preserves native rested thickness")
first.bars[4].restricted = false
STATUS_BAR_SIZE_ADJUSTMENT = secret; skin:Apply()
equal(first.width, 903, "hidden native size adjustment cannot reach arithmetic")
STATUS_BAR_SIZE_ADJUSTMENT = 3
first.width = secret; skin:Apply()
equal(first.width, secret, "hidden native width is not guessed or overwritten")
first.width = 903
skin:Apply()
equal(first.width, 254, "later readable native dimensions recover custom sizing")
Native(function() first:SetWidth(secret) end)
Suite.db.progressBarCustomSize = false; skin:Apply()
equal(first.width, secret, "hidden native size update invalidates an old restore snapshot")
first.width, first.height = 903, 22
Suite.db.progressBarValues, Suite.db.progressBarSegments = false, false
skin:Apply()
local label = xp.OverlayFrame.Text
Native(function() label:SetShown(secret) end)
Suite.db.progressBarValues = true; skin:Apply()
equal(label.shown, secret, "unreadable native visibility stays on its native path")
Native(function() label:SetShown(false) end); Flush()
equal(label.shown, true, "readable native visibility recovers always-show mode")
beforeTextures, beforeHooks = textures, hooks
Combat(true)
Suite.db.progressBarWidth, Suite.db.progressBarHeight = 120, 40
Suite.db.progressBarCustomSize, Suite.db.progressBarSegments = true, true; skin:Apply()
equal(first.width, 903, "combat custom sizing defers native geometry")
equal(textures, beforeTextures, "combat options defer new divider construction")
equal(hooks, beforeHooks, "combat options defer hooks")
LeaveCombat()
equal(first.width, 123, "combat exit applies a width smaller than native Edit Mode minimum")
equal(xp.StatusBar.height, 40, "combat exit applies increased thickness")
Combat(true); Suite.db.progressBarWidth = 307; skin:Apply(); Suite.db.progressBarWidth = 309; skin:Apply()
equal(first.width, 123, "combat changes keep current native size until safe")
LeaveCombat(); equal(first.width, 312, "combat coalescing applies latest exact width")
Combat(true); Enabled(false, false, false)
equal(first.width, 312, "combat disable defers native size restoration")
LeaveCombat()
equal(first.width, 903, "combat exit restores latest native width")
equal(skin.panels[xp.StatusBar].segments[1].shown, false, "disable hides owned sections")
Suite.GUI:Select("bars")
equal(-Suite.GUI.progressPanel.point[3] + Suite.GUI.progressPanel.height <= Suite.GUI.content.height - 36, true, "progress options fit above footer")
for key, field in pairs(Suite.GUI.progressFields) do
    equal(field.slider.step, 1, "progress slider changes by one unit: " .. key)
    equal(field.slider.obeyStep, true, "progress slider snaps to one unit: " .. key)
    equal(field.input.numeric, true, "progress input accepts numbers: " .. key)
end
local widthField, heightField = Suite.GUI.progressFields.progressBarWidth, Suite.GUI.progressFields.progressBarHeight
widthField.input:SetText("247"); widthField.input:OnEnterPressed()
heightField.input:SetText("21"); heightField.input:OnEditFocusLost()
equal(Suite.db.progressBarWidth, 247, "exact width input stores requested size")
equal(Suite.db.progressBarHeight, 21, "exact thickness input stores requested size")
equal(Suite.db.statusBarSkin, false, "dimension controls never enable the skin implicitly")
widthField.slider:OnMouseWheel(-1); heightField.slider:SetValue(22.7)
equal(Suite.db.progressBarWidth, 246, "width wheel supports one-unit adjustments")
equal(Suite.db.progressBarHeight, 23, "thickness slider rounds to one unit")
widthField.input:SetText("1"); widthField.input:OnEnterPressed()
heightField.input:SetText("999"); heightField.input:OnEnterPressed()
equal(Suite.db.progressBarWidth, 120, "width input enforces lower limit")
equal(Suite.db.progressBarHeight, 40, "thickness input enforces upper limit")
for _, invalid in ipairs({ "", "abc", "1e999", secret }) do
    widthField.input:SetText(invalid); widthField.input:OnEnterPressed()
    equal(Suite.db.progressBarWidth, 120, "invalid exact width cannot alter preference")
end
widthField.slider:OnValueChanged(secret); widthField.slider:OnValueChanged(0 / 0); widthField.slider:OnMouseWheel(secret)
equal(Suite.db.progressBarWidth, 120, "hidden and non-finite slider input cannot alter preference")
widthField.input:SetText("399"); widthField.input:OnEscapePressed(); widthField.input:OnEditFocusLost()
equal(Suite.db.progressBarWidth, 120, "Escape discards uncommitted exact size")
Suite.db.progressBarCustomSize = false; Suite.GUI.progressControls.progressBarCustomSize.button:OnClick()
equal(Suite.db.progressBarCustomSize, true, "custom size toggle enables its own preference")
Suite.GUI.progressControls.reset.button:OnClick()
equal(Suite.db.progressBarCustomSize, false, "native size button disables only the size override")
equal(Suite.db.progressBarWidth, 120, "native size button retains chosen custom width")
for _, key in ipairs({ "progressBarValues", "progressBarSegments" }) do
    Suite.db[key] = false; Suite.GUI.progressControls[key].button:OnClick()
    equal(Suite.db[key], true, "progress toggle enables its own preference: " .. key)
    equal(Suite.db.statusBarSkin, false, "progress toggle does not enable its skin: " .. key)
end
Suite.GUI:Select("actionbars")
equal(Suite.GUI.progressPanel:IsShown(), false, "action-bar page hides progress controls")
Suite.GUI:Select("bars")
equal(Suite.GUI.progressPanel:IsShown(), true, "progress controls reappear on Other bars")
Enabled(false, false, false)
-- Borders retain a full physical pixel across menu scale, resolution and fractional native movement.
Suite.db.progressBarValues, Suite.db.progressBarSegments, Suite.db.progressBarCustomSize = false, false, false
Enabled(false, false, true)
equal(skin.events.registered.UI_SCALE_CHANGED, true, "micro skin observes UI scale changes")
equal(skin.events.registered.DISPLAY_SIZE_CHANGED, true, "micro skin observes display changes")
local microPanel = skin.panels[character]
local function PixelBorders(label, parent, panel)
    parent, panel = parent or character, panel or microPanel
    for index, edge in ipairs(panel.edges) do
        local units = index <= 2 and edge.height or edge.width
        equal(math.abs(units * parent:GetEffectiveScale() * screenHeight / 768 - 1) < 0.0000001, true, label)
        equal(edge.roundPixels, true, "button border layout rounds to screen pixels")
        equal(edge.snapPixels, false, "button border avoids separate texel-grid snapping")
        equal(edge.snapBias, 0, "button border avoids texture snapping bias")
    end
end
PixelBorders("micro edges initially occupy one physical pixel")
equal(microPanel.background.roundPixels, true, "micro background shares border pixel layout")
equal(skin.panels[MainMenuBarBackpackButton].edges[1].roundPixels, true, "bag border shares the owned pixel layout")
equal(skin.panels[first.bars[1].StatusBar].edges[1].roundPixels, nil, "micro fix leaves progress rendering preferences alone")
beforeTextures, beforeHooks = textures, hooks
for _, scale in ipairs({ 0.35, 0.7, 1, 1.25 }) do
    Native(function() MicroMenu:SetScale(scale) end); Flush()
    equal(MicroMenu.scale, scale, "native menu scale is retained")
    PixelBorders("native scaling retains a full physical pixel on every edge")
end
MicroMenu.scale = 0.7
screenHeight = 1440; skin.events:OnEvent("DISPLAY_SIZE_CHANGED"); Flush()
PixelBorders("resolution change updates physical edge thickness")
character.scale = 0.8; skin.events:OnEvent("UI_SCALE_CHANGED"); Flush()
PixelBorders("inherited UI scaling updates physical edge thickness")
for _, offset in ipairs({ 0.1, 0.4, 0.75 }) do
    character.centerX, character.centerY = 500 + offset, 400 + offset
    MicroMenu:Layout(); Flush()
    PixelBorders("fractional native movement keeps borders at one physical pixel")
    equal(microPanel.edges[1].points[1][2], character, "micro border follows its native parent while moving")
    equal(#microPanel.edges[1].points, 2, "micro movement does not accumulate new anchors")
end
equal(textures, beforeTextures, "moving/scaling micro menu reuses artwork")
equal(hooks, beforeHooks, "moving/scaling micro menu reuses hooks")
local readablePixel = microPanel.pixel
screenHeight = secret; skin.events:OnEvent("DISPLAY_SIZE_CHANGED"); Flush()
equal(microPanel.pixel, readablePixel, "hidden display size retains last readable thickness")
screenHeight = 0; skin.events:OnEvent("DISPLAY_SIZE_CHANGED"); Flush()
equal(microPanel.pixel, readablePixel, "invalid display size cannot collapse borders")
screenHeight = 1080
local nativeEffectiveScale = character.GetEffectiveScale
character.GetEffectiveScale = function() return secret end
MicroMenu:Layout(); Flush()
equal(microPanel.pixel, readablePixel, "hidden effective scale cannot reach pixel arithmetic")
character.GetEffectiveScale = function() return math.huge end
MicroMenu:Layout(); Flush()
equal(microPanel.pixel, readablePixel, "nonfinite effective scale cannot alter thickness")
character.GetEffectiveScale = nativeEffectiveScale
GetPhysicalScreenSize = nil; MicroMenu:Layout(); Flush()
equal(microPanel.pixel, readablePixel, "missing screen API retains current border thickness")
GetPhysicalScreenSize = function() return 1920, screenHeight end
rasterMethods = false
local compatible = Button(true); MicroMenu:AddButton(compatible); Flush()
equal(PanelShown(compatible), true, "micro artwork tolerates unavailable optional raster methods")
equal(skin.panels[compatible].edges[1].roundPixels, nil, "unavailable raster method is not called")
rasterMethods = true
MicroMenu.children = { character, menuButton }; MicroMenu:Layout(); Flush()
local pixelBeforeCombat = microPanel.pixel
Combat(true); screenHeight = 2160
Native(function() MicroMenu:SetScale(0.4) end)
skin.events:OnEvent("DISPLAY_SIZE_CHANGED"); skin.events:OnEvent("UI_SCALE_CHANGED")
equal(microPanel.pixel, pixelBeforeCombat, "combat scaling defers owned edge size changes")
LeaveCombat(); PixelBorders("combat exit refreshes edges using latest scale and resolution")
Enabled(false, true, false)
equal(skin.events.registered.UI_SCALE_CHANGED, true, "enabled bag skin retains shared scale subscription")
equal(skin.events.registered.DISPLAY_SIZE_CHANGED, true, "enabled bag skin retains shared display subscription")
Native(function() MicroMenu:SetScale(0.8) end)
equal(TimerCount(), 0, "disabled native micro scale hook schedules no unrelated work")
CharacterBag1Slot.forbidden, CharacterBag2Slot.restricted = false, false
CharacterBag3Slot.GetHighlightTexture = function(self) return self.highlight end
skin:Apply()
for index = 5, #names do
    local bag = _G[names[index]]
    PixelBorders("every supported bag uses a full physical-pixel edge", bag, skin.panels[bag])
    equal(skin.panels[bag].background.roundPixels, true, "bag background shares border pixel rounding")
    equal(bag.icon.vertex[4], 0.6, "pixel treatment preserves native bag icon and mask")
end
beforeTextures, beforeHooks = textures, hooks
Native(function() BagsBar:SetScale(0.35) end); Flush()
equal(BagsBar.scale, 0.35, "bag skin retains native Edit Mode scale")
for index = 5, #names do
    local bag = _G[names[index]]
    PixelBorders("small native bag scale retains full-pixel borders", bag, skin.panels[bag])
end
local backpack = MainMenuBarBackpackButton
Native(function() backpack:SetScale(0.8) end); Flush()
PixelBorders("individual native bag button scaling refreshes thickness", backpack, skin.panels[backpack])
screenHeight = 1440; skin.events:OnEvent("DISPLAY_SIZE_CHANGED"); Flush()
PixelBorders("bag-only display change updates thickness", backpack, skin.panels[backpack])
backpack.scale = 0.7; skin.events:OnEvent("UI_SCALE_CHANGED"); Flush()
PixelBorders("bag-only UI scale change updates thickness", backpack, skin.panels[backpack])
backpack.centerX, backpack.centerY = 500.4, 400.75
BagsBar:Layout(); Flush()
equal(skin.panels[backpack].edges[1].points[1][2], backpack.icon, "bag borders follow the native icon during fractional movement")
equal(#skin.panels[backpack].edges[1].points, 2, "bag movement preserves original owned anchors")
backpack:OnClick(); backpack:OnEnter(); backpack:SetButtonState("PUSHED")
equal(backpack.clicksReceived, 1, "bag native click survives the pixel fix")
equal(skin.panels[backpack].edges[1].color[4], 1, "bag hover and pressed feedback remain visible")
equal(backpack.FreeSlots.shown, true, "bag free-slot count remains native")
backpack:SetButtonState("NORMAL"); backpack:OnLeave()
equal(textures, beforeTextures, "bag scaling and movement reuse existing artwork")
equal(hooks, beforeHooks, "bag scaling and movement reuse existing hooks")
local bagPixelBeforeCombat = skin.panels[backpack].pixel
Combat(true); screenHeight = 1080
Native(function() BagsBar:SetScale(1.2) end); skin.events:OnEvent("DISPLAY_SIZE_CHANGED")
equal(skin.panels[backpack].pixel, bagPixelBeforeCombat, "bag pixel changes defer during combat")
LeaveCombat(); PixelBorders("bag combat exit uses latest scale and resolution", backpack, skin.panels[backpack])
Enabled(true, false, false)
equal(skin.events.registered.UI_SCALE_CHANGED, nil, "disabled bag and micro skins remove scale subscription")
equal(skin.events.registered.DISPLAY_SIZE_CHANGED, nil, "disabled bag and micro skins remove display subscription")
Native(function() BagsBar:SetScale(0.9); backpack:SetScale(1) end)
equal(TimerCount(), 0, "disabled bag scale hooks cannot schedule progress-only work")
equal(PanelShown(backpack), false, "bag disable hides pixel artwork independently")
Enabled(false, false, false)
-- Native icons may be replaced or temporarily lack readable layout.
Enabled(false, true, false)
local oldBagIcon = backpack.icon
local replacementIcon = Geometry(Widget(), 30, 28)
replacementIcon.parent, replacementIcon.centerX, replacementIcon.centerY = backpack, 502, 399
backpack.icon = replacementIcon; backpack:UpdateTextures(); Flush()
local fittedPanel = skin.panels[backpack]
equal(fittedPanel.background.points[1][2], replacementIcon, "replacement native icon becomes the plate anchor")
equal(fittedPanel.edges[1].points[1][2], replacementIcon, "replacement native icon becomes the border anchor")
equal(#fittedPanel.background.points, 2, "replacement icon does not accumulate plate anchors")
local nativeIconWidth = replacementIcon.GetWidth
replacementIcon.GetWidth = function() return secret end
backpack:UpdateTextures(); Flush()
equal(PanelShown(backpack), false, "restricted icon layout cannot leave an oversized Suite plate")
equal(backpack.normal.vertex[4], 0.6, "restricted icon layout restores readable native frame art")
replacementIcon.GetWidth = function() return 0 end
backpack:UpdateTextures(); Flush()
equal(PanelShown(backpack), false, "unlaid-out icon keeps its native frame")
replacementIcon.GetWidth = nativeIconWidth; replacementIcon.restricted = true
backpack:UpdateTextures(); Flush()
equal(PanelShown(backpack), false, "restricted icon anchors keep the native frame")
replacementIcon.restricted = false; backpack:UpdateTextures(); Flush()
equal(PanelShown(backpack), true, "readable native icon layout resumes fitted styling")
local countBeforeCombat = #fittedPanel.background.points
Combat(true); backpack:UpdateTextures()
equal(#fittedPanel.background.points, countBeforeCombat, "combat icon refresh changes no owned anchors")
LeaveCombat()
Enabled(false, false, false)
equal(PanelShown(backpack), false, "disabling the fitted skin hides its plate")
equal(backpack.normal.vertex[4], 0.6, "disabling the fitted skin restores native frame tint")
equal(replacementIcon.width, 30, "fitted skin never resizes the native icon width")
equal(replacementIcon.height, 28, "fitted skin never resizes the native icon height")
equal(replacementIcon.vertex[4], 0.6, "fitted skin preserves native dimming and color")
backpack.icon = oldBagIcon
-- Blizzard's native visibility rule must keep text on when addon frame writes are unavailable.
-- All progress counters stay native; this fixture never exposes the underlying values.
local nativeText, cvarWrites, secureCVar, readOnlyCVar, lockedCVar, failCVar = "0", 0, false, false, false, false
local nativeBars = { xp, honor, second.bars[3] }
local function NativeTextVisibility()
    Native(function()
        for _, bar in ipairs(nativeBars) do
            -- StatusTrackingBarMixin:ShouldBarTextBeDisplayed also checks native hover locks.
            bar.OverlayFrame.Text:SetShown(nativeText == "1" or bar.textLocked == true)
        end
    end)
end
C_CVar = {
    GetCVarInfo = function(name)
        assert(name == "xpBarText", "progress option reads only its native text setting")
        return nativeText, "0", false, false, lockedCVar, secureCVar, readOnlyCVar
    end,
    SetCVar = function(name, value)
        assert(name == "xpBarText", "progress option writes only its native text setting")
        assert(value == "0" or value == "1", "native text preference has a validated static value")
        assert(secureCVar == false and readOnlyCVar == false and lockedCVar == false,
            "secure/read-only/locked CVars must remain untouched")
        cvarWrites = cvarWrites + 1
        if failCVar == "nil" then return end
        if failCVar then return false end
        nativeText = value
        NativeTextVisibility()
        return true
    end,
}
GetCVar = function() error("progress preference uses the capability-checked current C_CVar API") end
SetCVar = function(name, value) return C_CVar.SetCVar(name, value) end
Suite.db.progressBarValues = true
Enabled(true, false, false); Flush()
equal(nativeText, "1", "always-show values enables Blizzard's native visibility rule before combat")
equal(Suite.db.progressBarTextRestore, "0", "original native hover-only preference is retained")
for _, bar in ipairs(nativeBars) do bar.protected, bar.OverlayFrame.protected = true, true end
beforeTextures, beforeHooks, formats = textures, hooks, honor.formats
Combat(true); NativeTextVisibility()
for _, bar in ipairs(nativeBars) do
    equal(bar.OverlayFrame.Text.shown, true, "native combat visibility works even with protected bar ancestors")
end
equal(honor.formats, formats, "native combat visibility does not invoke addon data formatting")
equal(textures, beforeTextures, "native combat preference creates no artwork")
equal(hooks, beforeHooks, "native combat preference installs no hooks")
Suite.db.progressBarValues = false; skin:Apply()
equal(nativeText, "0", "combat disable safely restores the nonsecure native preference")
for _, bar in ipairs(nativeBars) do equal(bar.OverlayFrame.Text.shown, false, "native combat disable restores hover-only labels") end
Suite.db.progressBarValues = true; skin:Apply()
equal(nativeText, "1", "prepared native preference can be re-enabled during combat")
Native(function() SetCVar("xpBarText", "0") end)
equal(nativeText, "1", "external native hide preference cannot remove always-show combat values")
equal(Suite.db.progressBarTextRestore, "0", "nested native CVar calls retain the requested preference")
Suite.db.progressBarValues = false; skin:Apply()
equal(nativeText, "0", "disable preserves the latest external hide preference")
Suite.db.progressBarValues = true; skin:Apply()
Native(function() SetCVar("xpBarText", "1") end)
Suite.db.progressBarValues = false; skin:Apply()
equal(nativeText, "1", "disable retains an external native always-show preference")
equal(Suite.db.progressBarTextRestore, nil, "successful restoration clears saved ownership")
local protectedMethod = honor.OverlayFrame.Text.IsProtected
honor.OverlayFrame.Text.IsProtected = nil
Suite.db.progressBarValues = true; skin:Apply(); NativeTextVisibility()
equal(honor.OverlayFrame.Text.shown, true, "native combat visibility does not require a FontString protection method")
honor.OverlayFrame.Text.IsProtected = protectedMethod
Suite.db.progressBarValues = false; skin:Apply()
nativeText = "0"; Suite.db.progressBarValues = true; skin:Apply()
failCVar = true; Suite.db.progressBarValues = false; skin:Apply()
equal(nativeText, "1", "failed native restoration does not pretend the preference changed")
equal(Suite.db.progressBarTextRestore, "0", "failed restoration retains its readable original for retry")
failCVar = false; skin:Apply()
equal(nativeText, "0", "later successful restoration retries the original preference")
equal(Suite.db.progressBarTextRestore, nil, "restoration ownership clears only after success")
Suite.db.progressBarValues = true; skin:Apply()
failCVar = "nil"; Suite.db.progressBarValues = false; skin:Apply()
equal(Suite.db.progressBarTextRestore, "0", "a setter returning nothing retains pending restoration")
failCVar = false; skin:Apply()
Suite.db.progressBarValues = true; skin:Apply()
Enabled(false, false, false)
equal(nativeText, "0", "disabling the entire skin in combat also restores native text preferences")
Enabled(true, false, false)
equal(nativeText, "1", "re-enabling a prepared skin in combat restores native always-show values")
Suite.db.progressBarValues = false; skin:Apply()
for _, denied in ipairs({ true, secret, "invalid" }) do
    for _, flag in ipairs({ "secure", "readonly", "locked" }) do
        secureCVar, readOnlyCVar, lockedCVar = false, false, false
        if flag == "secure" then secureCVar = denied
        elseif flag == "readonly" then readOnlyCVar = denied else lockedCVar = denied end
        local writes = cvarWrites
        Suite.db.progressBarValues = true; skin:Apply()
        equal(cvarWrites, writes, "restricted/unreadable native CVar predicates forbid writes")
        equal(Suite.db.progressBarTextRestore, nil, "restricted settings do not acquire restoration ownership")
        Suite.db.progressBarValues = false; skin:Apply()
    end
end
secureCVar, readOnlyCVar, lockedCVar = false, false, false
for _, unreadable in ipairs({ secret, "unknown", 1 }) do
    nativeText = unreadable
    local writes = cvarWrites
    Suite.db.progressBarValues = true; skin:Apply()
    equal(cvarWrites, writes, "unavailable/secret native values cannot be captured or rewritten")
    Suite.db.progressBarValues = false; skin:Apply()
end
nativeText = "0"
Suite.db.progressBarValues = true; skin:Apply()
local reloaded = Suite.InitializeDB(Suite.Copy(Suite.db))
Suite.db = reloaded; skin:Apply()
equal(Suite.db.progressBarTextRestore, "0", "reload retains the original instead of capturing the forced setting")
Suite.db.progressBarValues = false; skin:Apply()
equal(nativeText, "0", "disable after reload restores the original native preference")
for _, value in ipairs({ secret, true, 0, "2", {} }) do
    equal(Suite.InitializeDB({ progressBarTextRestore = value }).progressBarTextRestore, nil,
        "corrupt/secret persisted restoration data is discarded")
end
for _, value in ipairs({ "0", "1" }) do
    equal(Suite.InitializeDB({ progressBarTextRestore = value }).progressBarTextRestore, value,
        "readable persisted native preferences survive initialization")
end
Suite.db.progressBarValues = true; skin.valuesCVar = nil
local writes, installedHooks = cvarWrites, hooks
skin:Apply()
equal(cvarWrites, writes, "first native preference preparation waits until combat ends")
equal(hooks, installedHooks, "first combat preference setup installs no hooks")
Suite.db.progressBarValues = false; skin:Apply()
for _, bar in ipairs(nativeBars) do bar.protected, bar.OverlayFrame.protected = false, false end
LeaveCombat(); Flush()
Suite.db.progressBarValues = true; skin:Apply(); Flush()
equal(nativeText, "1", "outside-combat preparation applies the native preference")
local ownedRestore = Suite.db.progressBarTextRestore
local nativeGetter, nativeSetter = C_CVar.GetCVarInfo, C_CVar.SetCVar
C_CVar.GetCVarInfo = nil
writes = cvarWrites; skin:ValuesSetting()
equal(cvarWrites, writes, "missing native metadata API prevents writes")
C_CVar.GetCVarInfo = nativeGetter; C_CVar.SetCVar = nil
skin:ValuesSetting()
equal(Suite.db.progressBarTextRestore, ownedRestore, "missing setter preserves a pending readable restoration")
C_CVar.SetCVar = nativeSetter
Native(function() C_CVar.SetCVar("xpBarText", "0") end); Flush()
equal(nativeText, "1", "modern native CVar changes are observed outside combat too")
equal(Suite.db.progressBarTextRestore, "0", "external hide preference remains available for release")
Native(function() xp.OverlayFrame.Text:Hide() end)
equal(TimerCount() > 0, true, "native refresh can have coalesced work queued before logout")
skin.events:OnEvent("PLAYER_LOGOUT")
equal(nativeText, "0", "logout releases the temporary native text preference")
equal(Suite.db.progressBarTextRestore, nil, "logout clears successfully restored ownership")
equal(Suite.db.progressBarValues, true, "logout retains the user's always-show addon option")
equal(TimerCount(), 0, "logout cancels work that could reapply the temporary preference")
Native(function() C_CVar.SetCVar("xpBarText", "0") end)
equal(nativeText, "0", "late logout native events cannot re-enable the setting")
equal(Suite.db.progressBarTextRestore, nil, "late logout events cannot reclaim native preference ownership")
skin.loggingOut = nil
Enabled(false, false, false)
Suite.GUI:Select(saved.page); Suite.GUI.frame:SetShown(saved.shown)
Suite.db, Suite.pending, Suite.Set = saved.db, saved.pending, saved.set
CreateFrame, C_Timer, hooksecurefunc = saved.create, saved.timer, saved.hook
GetPhysicalScreenSize = saved.screen
C_CVar, GetCVar, SetCVar = saved.cvar, saved.getCvar, saved.setCvar
skin.valuesCVar = saved.valuesCVar
skin.loggingOut = saved.loggingOut
skin.properties, skin.panels, skin.watched, skin.events = saved.properties, saved.panels, saved.watched, saved.events
for _, name in ipairs(names) do _G[name] = globals[name] end
STATUS_BAR_SIZE_ADJUSTMENT = savedAdjustment
Combat(false)
