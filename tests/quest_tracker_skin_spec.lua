local Suite, equal, Frame, SetCombat = ...
local skin = Suite.QuestTrackerSkin
local saved = { db = Suite.db, pending = Suite.pending, tracker = ObjectiveTrackerFrame, create = CreateFrame,
    timer = C_Timer, hook = hooksecurefunc, properties = skin.properties, panels = skin.panels, buttons = skin.buttons,
    watched = skin.watched, events = skin.events }
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
skin.properties, skin.panels, skin.buttons, skin.watched, skin.events = {}, {}, {}, {}, nil
local combat, native, created, installed, updates = false, false, 0, 0, 0
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
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
local function OwnedTexture(self, name, layer, template, level)
    assert(not combat, "tracker textures are never created in combat")
    equal(name, nil, "owned tracker art is anonymous")
    equal(layer == "BACKGROUND" or layer == "OVERLAY" or layer == "ARTWORK" or layer == "BORDER", true, "owned tracker art uses native draw layers")
    equal(level == -7 or level == 7, true, "owned tracker art uses valid sublevels")
    created = created + 1
    local texture = Frame()
    texture.parent, texture.points, texture.drawLayer, texture.drawSublevel = self, {}, layer, level
    texture.SetColorTexture = function(region, ...) assert(not combat, "owned art colors defer combat"); region.fill = { ... } end
    texture.ClearAllPoints = function(region) assert(not combat, "owned anchors defer combat"); region.points = {} end
    texture.SetPoint = function(region, ...)
        assert(not combat, "owned tracker anchors wait for combat")
        region.points[#region.points + 1] = { ... }
    end
    texture.Show = function(region) assert(not combat, "Suite art shows outside combat"); region.shown = true end
    texture.Hide = function(region) assert(not combat, "Suite art hides outside combat"); region.shown = false end
    return texture
end
CreateFrame = function(...)
    assert(not combat, "tracker controller construction waits for combat")
    created = created + 1
    local frame = saved.create(...)
    frame.CreateTexture = OwnedTexture
    frame.SetAllPoints = function(self, target) assert(not combat, "owned backdrop anchors defer combat"); self.allPoints = target end
    frame.SetFrameStrata = function(self, strata) assert(not combat, "owned backdrop strata defer combat"); self.strata = strata end
    frame.SetFrameLevel = function(self, level) assert(not combat, "owned backdrop levels defer combat"); self.frameLevel = level end
    frame.GetFrameStrata = function(self) return self.strata or (self.parent and self.parent:GetFrameStrata()) or "MEDIUM" end
    frame.EnableMouse = function(self, enabled) assert(not combat, "owned backdrop input defers combat"); self.mouseEnabled = enabled end
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    return frame
end
hooksecurefunc = function(...)
    assert(not combat, "tracker hooks install outside combat")
    installed = installed + 1
    return saved.hook(...)
end
local function Native(callback)
    native = true; callback(); native = false
end
local function Widget()
    local frame = Frame()
    frame.shown, frame.alpha, frame.vertex, frame.color = true, 0.35, { 0.9, 0.8, 0.7, 0.6 }, { 1, 0.82, 0, 0.9 }
    frame.IsForbidden = function(self) return self.forbidden or false end
    frame.IsAnchoringRestricted = function(self) return self.restricted or false end
    frame.GetAlpha = function(self) return self.alpha end
    frame.GetVertexColor = function(self) return unpack(self.vertex) end
    frame.GetTextColor = function(self) return unpack(self.color) end
    frame.SetShown = function(self, value)
        assert(native or not combat, "native filter visibility defers combat")
        assert(native or Suite.IsReadable(value), "Suite never replays hidden visibility")
        self.shown = value
    end
    frame.SetAlpha = function(self, value)
        assert(native or not combat, "Suite alpha changes wait for combat")
        assert(native or Suite.IsReadable(value), "Suite never sets a hidden alpha")
        self.alpha = value
    end
    frame.SetVertexColor = function(self, ...)
        assert(native or not combat, "Suite texture color changes wait for combat")
        self.vertex = { ... }
        for _, value in ipairs(self.vertex) do assert(native or Suite.IsReadable(value), "Suite never replays secret texture color") end
    end
    frame.SetTextColor = function(self, ...)
        assert(native or not combat, "Suite text color changes wait for combat")
        self.color = { ... }
        for _, value in ipairs(self.color) do assert(native or Suite.IsReadable(value), "Suite never replays secret text color") end
    end
    frame.SetFontObject = function(self) self.color = { 0.7, 0.6, 0.5, 0.4 } end
    frame.CreateTexture = OwnedTexture
    for _, method in ipairs({ "SetParent", "SetPoint", "ClearAllPoints", "SetSize", "SetWidth", "SetHeight", "SetScale",
        "EnableMouse", "RegisterForClicks", "SetAttribute", "SetTexture", "SetAtlas", "SetFont", "SetText" }) do
        frame[method] = function() error("tracker skin must retain native layout, input, assets, fonts and text: " .. method) end
    end
    return frame
end
local function Header()
    local header = Widget()
    header.Background, header.Text, header.MinimizeButton, header.FilterButton = Widget(), Widget(), Widget(), Widget()
    header.MinimizeButton.OnClick = function() return "native minimize" end
    local button = header.MinimizeButton
    button.normal, button.pushed, button.highlight = Widget(), Widget(), Widget()
    button.GetNormalTexture = function(self) return self.normal end
    button.GetPushedTexture = function(self) return self.pushed end
    button.GetHighlightTexture = function(self) return self.highlight end
    button.state = "NORMAL"
    button.GetButtonState = function(self) return self.state end
    button.SetButtonState = function(self, value) self.state = value end
    button.IsMouseOver = function(self) return self.hovered or false end
    button.OnEnter, button.OnLeave = function(self) self.nativeEnter = true end, function(self) self.nativeLeave = true end
    button.OnMouseDown, button.OnMouseUp = function(self) self.nativeDown = true end, function(self) self.nativeUp = true end
    header.SetCollapsed = function(self, value)
        self.MinimizeButton.normal.atlas = value and "native-expand" or "native-collapse"
    end
    header.FilterButton.OnClick = function() return "native filter" end
    header.Shine, header.Glow = Widget(), Widget()
    return header
end
local function Module()
    local module = Widget()
    module.Header = Header()
    module.IsCollapsed = function(self) if self.collapseValue ~= nil then return self.collapseValue end; return self.collapsed == true end
    -- Traversing pooled quest data would fail; this skin needs only the section header.
    module.usedBlocks = setmetatable({}, { __index = function() error("skin must not inspect quest blocks") end })
    module.Update = function() updates = updates + 1 end
    module.OnShow, module.OnHide = function() updates = updates + 1 end, function() updates = updates + 1 end
    return module
end
local function Tracker()
    local tracker = Widget()
    tracker.GetFrameStrata = function() return "LOW" end
    tracker.Header, tracker.NineSlice, tracker.modules = Header(), Widget(), { Module(), Module() }
    tracker.IsCollapsed = function(self) if self.collapseValue ~= nil then return self.collapseValue end; return self.collapsed == true end
    tracker.Update = function() updates = updates + 1; return "native result", 17 end
    return tracker
end
ObjectiveTrackerFrame = Tracker()
local tracker, first = ObjectiveTrackerFrame, ObjectiveTrackerFrame.modules[1]
local function Enabled(value) Suite.db.questTrackerSkin = value; skin:Apply() end
local function PanelShown(parent) return skin.panels[parent] and skin.panels[parent].textures[1].shown or false end
equal(Suite.defaults.questTrackerSkin, false, "quest tracker skin starts independently off")
equal(Suite.InitializeDB({ questTrackerSkin = "yes" }).questTrackerSkin, false, "corrupt skin preference returns to off")
equal(Suite.InitializeDB({ questTrackerSkin = secret }).questTrackerSkin, false, "restricted skin preference returns to off")
skin:Apply(); equal(created, 0, "disabled skin creates no frames or artwork"); equal(installed, 0, "disabled skin installs no hooks")
Enabled(true)
equal(tracker.NineSlice.alpha, 0, "native body artwork is suppressed without changing its assets")
equal(tracker.Header.Background.vertex[4], 0, "native main-header artwork is suppressed by vertex alpha")
equal(first.Header.Background.vertex[4], 0, "native section-header artwork is suppressed")
equal(tracker.Header.Text.color[1], 0.41, "main header uses Suite teal")
equal(first.Header.Text.color[3], 0.75, "section header uses Suite teal")
equal(first.Header.Text.color[4], 0.9, "native header text opacity is retained")
equal(first.Header.Shine.alpha, 0.35, "native added-objective feedback is retained")
equal(first.Header.MinimizeButton.OnClick(), "native minimize", "section minimize input is retained")
equal(tracker.Header.FilterButton.OnClick(), "native filter", "main filter input is retained")
equal(PanelShown(tracker), true, "body panel appears with displayed contents")
equal(skin.panels[tracker].textures[1].points[1][2], tracker.NineSlice, "body follows native content bounds rather than reserved tracker height")
equal(skin.panels[first.Header].textures[1].parent, first.Header, "section panel follows native header visibility and parent")
equal(#skin.panels[first.Header].textures, 1, "section header has only one underline")
equal(skin.panels[first.Header].background, nil, "section header has no separate boxed background")
-- Exact native XML puts the standalone timer in BACKGROUND while the tracker is LOW.
-- Texture sublevels cannot put a LOW-frame texture behind a BACKGROUND-frame timer.
local strataOrder = { BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4, DIALOG = 5 }
local function DrawsAbove(texture, other)
    local owner, otherOwner = texture.parent, other.parent
    local strata, otherStrata = strataOrder[owner:GetFrameStrata()], strataOrder[otherOwner:GetFrameStrata()]
    if strata ~= otherStrata then return strata > otherStrata end
    if owner:GetFrameLevel() ~= otherOwner:GetFrameLevel() then return owner:GetFrameLevel() > otherOwner:GetFrameLevel() end
    local layers = { BACKGROUND = 1, BORDER = 2, ARTWORK = 3, OVERLAY = 4 }
    if texture.drawLayer ~= other.drawLayer then return layers[texture.drawLayer] > layers[other.drawLayer] end
    return texture.drawSublevel > other.drawSublevel
end
local questTimer = Widget()
questTimer.parent, questTimer.frameLevel = tracker, tracker:GetFrameLevel() + 1
questTimer.GetFrameStrata = function() return "BACKGROUND" end
questTimer.SetFrameStrata, questTimer.SetFrameLevel = function() error("skin must not raise native quest timers") end, function() error("skin must not raise native quest timers") end
questTimer.activeElements = setmetatable({}, { __index = function() error("skin must not inspect timer values or pooled rows") end })
local timerCaption = { parent = questTimer, drawLayer = "ARTWORK", drawSublevel = 0 }
local timerCountdown = { parent = questTimer, drawLayer = "OVERLAY", drawSublevel = 1 }
local originalTimerShow = questTimer.Show
tracker.QuestTimerFrame = questTimer
local bodyPanel = skin.panels[tracker]
equal(DrawsAbove(bodyPanel.background, timerCaption), false, "tracker backdrop stays below the native quest timer caption")
equal(DrawsAbove(bodyPanel.background, timerCountdown), false, "tracker backdrop stays below the native countdown")
equal(bodyPanel.background.parent.parent, tracker, "lower backdrop inherits native tracker visibility and alpha")
equal(bodyPanel.background.parent.mouseEnabled, false, "lower backdrop cannot cover timer clicks")
equal(questTimer.Show, originalTimerShow, "native timer visibility script is untouched")
local layerCount, priorUpdates = created, updates
tracker:Update(); Flush()
equal(created, layerCount, "lower tracker backdrop reuses its prepared frame and art")
equal(DrawsAbove(bodyPanel.background, timerCountdown), false, "native tracker refresh preserves timer foreground order")
tracker.QuestTimerFrame = nil
updates = priorUpdates
equal(DrawsAbove(bodyPanel.background, timerCaption), false, "backdrop ordering works even if timer discovery is unavailable")
equal(skin.panels[first.Header].edges.TOP, nil, "section header has no top border")
equal(skin.panels[tracker.Header].edges.LEFT, nil, "main header has no side border")
equal(skin.panels[tracker].edges.RIGHT.drawLayer, "OVERLAY", "whole tracker outline draws above its fill")
local primary, minimize = tracker.Header.MinimizeButton, first.Header.MinimizeButton
local primaryArt, minimizeArt = skin.buttons[primary], skin.buttons[minimize]
equal(primary.normal.vertex[4], 0, "primary native minimize artwork is hidden")
equal(minimize.pushed.vertex[4], 0, "section native pressed artwork is hidden")
equal(minimize.highlight.vertex[4], 0, "section native highlight artwork is hidden")
equal(minimizeArt.background.fill[1], 0.035, "minimize button uses the Suite control surface")
equal(minimizeArt.edges[1].fill[4], 0.45, "minimize button uses a muted teal resting border")
equal(minimizeArt.vertical.shown, false, "expanded section shows minus")
equal(primaryArt.vertical.shown, false, "expanded tracker shows minus")
minimize.hovered = true; minimize:OnEnter()
equal(minimize.nativeEnter, true, "native enter handler is preserved")
equal(minimizeArt.edges[1].fill[4], 1, "hover brightens the teal edge")
minimize:OnMouseDown("LeftButton")
equal(minimize.nativeDown, true, "native press handler is preserved")
equal(minimizeArt.background.fill[1], 0.10, "press uses the meter control's active slate color")
minimize:OnMouseUp("LeftButton")
equal(minimize.nativeUp, true, "native release handler is preserved")
equal(minimizeArt.background.fill[1], 0.07, "release returns to hover color")
minimize.hovered = false; minimize:OnLeave()
equal(minimize.nativeLeave, true, "native leave handler is preserved")
equal(minimizeArt.edges[1].fill[4], 0.45, "leave restores muted edge")
minimize:SetButtonState("PUSHED")
equal(minimizeArt.background.fill[1], 0.10, "native button state can drive gamepad/keyboard feedback")
minimize:SetButtonState(secret)
equal(minimizeArt.background.fill[1], 0.035, "hidden native button state is never compared as a string")
minimize:SetButtonState("NORMAL")
equal(skin.events.registered.ADDON_LOADED, true, "late native sections are discovered")
equal(skin.events.OnUpdate, nil, "skin has no idle per-frame scanner")
equal(Suite.db.autoQuestPickup, false, "styling does not enable quest automation")
equal(Suite.db.quickLoot, false, "styling does not enable quick loot")
local beforeCreated, beforeHooks = created, installed
skin:Apply(); skin:Apply()
equal(created, beforeCreated, "reapplying does not duplicate tracker artwork")
equal(installed, beforeHooks, "reapplying does not duplicate hooks")
local result, second = tracker:Update()
equal(result, "native result", "post-hook preserves native update return")
equal(second, 17, "post-hook preserves every native update return")
tracker:Update(); first:OnShow(); skin.events:OnEvent("PLAYER_ENTERING_WORLD")
equal(TimerCount(), 1, "native updates and show events coalesce")
Flush(); equal(updates, 3, "native update and script callbacks still run without extra native updates")
first:Update(); equal(TimerCount(), 1, "module dispatch covers native dirty closures that retain the original container Update")
Flush()
Native(function() tracker.NineSlice:SetAlpha(0.72); first.Header.Background:SetVertexColor(0.2, 0.3, 0.4, 0.5); first.Header.Text:SetTextColor(0.6, 0.7, 0.8, 0.3) end)
Flush(); equal(tracker.NineSlice.alpha, 0, "new native background opacity is restyled")
equal(first.Header.Text.color[4], 0.3, "native text opacity updates survive styling")
Enabled(false)
equal(minimize.normal.vertex[4], 0.6, "disable restores native minimize texture opacity")
equal(minimizeArt.background.shown, false, "disable hides owned minimize art")
equal(tracker.NineSlice.alpha, 0.72, "disable restores latest native background opacity")
equal(first.Header.Background.vertex[1], 0.2, "disable restores latest native texture color")
equal(first.Header.Background.vertex[4], 0.5, "disable restores latest native texture opacity")
equal(first.Header.Text.color[1], 0.6, "disable restores latest native text color")
equal(first.Header.Text.color[4], 0.3, "disable restores latest native text opacity")
equal(PanelShown(tracker), false, "disable hides owned body panel")
equal(next(skin.events.registered), nil, "disable stops events")
tracker:Update(); equal(TimerCount(), 0, "retained native hooks are inert while disabled")
Enabled(true)
tracker.collapsed = true; tracker:Update(); Flush()
equal(PanelShown(tracker), false, "collapsed tracker hides the entire Suite background and outline")
equal(tracker.Header.Text.color[4], 0, "collapsed tracker hides the All Objectives label")
equal(tracker.Header.FilterButton.shown, false, "collapsed tracker hides native filter input")
equal(primaryArt.vertical.shown, true, "collapsed tracker shows plus")
equal(primaryArt.background.shown, true, "collapsed tracker keeps only the compact native plus button")
equal(primary.shown, true, "the existing native plus button remains shown")
equal(created, beforeCreated, "collapse reuses existing panels and buttons")
equal(PanelShown(tracker.Header), false, "collapsed tracker hides the main header underline")
equal(PanelShown(first.Header), false, "collapsed tracker hides every owned section underline")
equal(minimizeArt.background.shown, false, "collapsed tracker hides owned section minimize artwork")
equal(tracker.NineSlice.alpha, 0, "collapsed tracker keeps stale tall native background suppressed")
tracker.collapsed = false; tracker.modules[1].shown, tracker.modules[2].shown = false, false
tracker:Update(); Flush(); equal(skin.panels[tracker].target, tracker.Header, "empty tracker does not retain a stale body")
equal(tracker.Header.Text.color[4], 0.9, "expansion restores the main label's captured native alpha")
equal(tracker.Header.FilterButton.shown, true, "expansion restores previously shown native filter input")
first.shown = true; first:OnShow(); Flush(); equal(PanelShown(tracker), true, "displayed contents restore body styling")
equal(skin.panels[tracker].target, tracker.NineSlice, "expanded outline returns to actual content bounds")
equal(created, beforeCreated, "collapse and expand do not allocate replacement panels")
for _ = 1, 3 do
    tracker.collapsed = true; tracker:Update(); Flush()
    tracker.collapsed = false; tracker:Update(); Flush()
end
Enabled(false)
equal(tracker.Header.Text.color[4], 0.9, "repeated collapse transitions do not overwrite native label restoration with hidden alpha")
equal(tracker.NineSlice.alpha, 0.72, "disable restores original native opacity after repeated collapse transitions")
Enabled(true)
tracker.collapsed = true; tracker:Update(); Flush()
Native(function() tracker.NineSlice:SetAlpha(0.61); tracker.Header.Text:SetTextColor(0.2, 0.3, 0.4, 0.7) end)
Flush()
equal(tracker.NineSlice.alpha, 0, "native opacity updates stay suppressed while minimized")
equal(tracker.Header.Text.color[4], 0, "native text-color updates stay hidden while minimized")
Enabled(false)
equal(tracker.NineSlice.alpha, 0.61, "disable while minimized restores the latest native background opacity")
equal(tracker.Header.Text.color[4], 0.7, "disable while minimized restores the latest native text opacity")
equal(tracker.Header.FilterButton.shown, true, "disable while minimized restores native filter visibility")
tracker.Header.FilterButton.shown = false
Enabled(true); equal(tracker.Header.FilterButton.shown, false, "already hidden filter stays hidden while minimized")
Native(function() tracker.Header.FilterButton:Show() end); Flush()
equal(tracker.Header.FilterButton.shown, false, "native filter Show is suppressed while minimized")
Native(function() tracker.Header.FilterButton:Hide() end); Flush()
tracker.collapsed = false; tracker:Update(); Flush()
equal(tracker.Header.FilterButton.shown, false, "expansion preserves the latest native filter Hide")
tracker.collapsed = true; tracker:Update(); Flush()
Native(function() tracker.Header.FilterButton:Show() end); Flush()
tracker.collapsed = false; tracker:Update(); Flush()
equal(tracker.Header.FilterButton.shown, true, "expansion restores the latest requested native filter Show")
tracker.collapseValue = secret; skin:Refresh()
equal(tracker.Header.Text.color[4], 0.7, "unreadable collapse state cannot hide a readable label")
equal(tracker.Header.FilterButton.shown, true, "unreadable collapse state cannot hide native filter input")
tracker.collapseValue = nil; skin:Refresh()
Combat(true); tracker.collapsed = true; tracker:Update()
equal(PanelShown(tracker), true, "combat collapse defers whole-panel visibility changes")
equal(tracker.Header.Text.color[4], 0.7, "combat collapse defers hiding the main label")
equal(tracker.Header.FilterButton.shown, true, "combat collapse defers native filter visibility changes")
LeaveCombat()
equal(PanelShown(tracker), false, "combat exit completes plus-only collapse")
equal(tracker.Header.Text.color[4], 0, "combat exit hides the label")
equal(primaryArt.vertical.shown, true, "combat exit keeps the visible plus glyph")
Combat(true); tracker.collapsed = false; tracker:Update(); LeaveCombat()
equal(PanelShown(tracker), true, "deferred expansion restores the full tracker")
equal(tracker.Header.Text.color[4], 0.7, "deferred expansion restores the main label's native alpha")
equal(tracker.Header.FilterButton.shown, true, "deferred expansion restores native filter input")
tracker.Header.Text.color = { 1, 0.82, 0, 0.9 }
Native(function() tracker.Header.Text:SetTextColor(1, 0.82, 0, 0.9) end); Flush()
first.collapsed = true; first.Header:SetCollapsed(true); Flush()
equal(minimizeArt.vertical.shown, true, "section collapse switches its native button art to plus")
equal(minimize.normal.atlas, "native-expand", "native collapse handler retains its atlas change")
first.collapsed = false; first.Header:SetCollapsed(false); Flush()
equal(minimizeArt.vertical.shown, false, "section expansion switches its art back to minus")
Native(function() minimize.normal:SetVertexColor(0.1, 0.2, 0.3, 0.4) end)
Flush(); equal(minimize.normal.vertex[4], 0, "native button color updates are suppressed while skinned")
Enabled(false)
equal(minimize.normal.vertex[1], 0.1, "button disable restores the latest native texture color")
equal(minimize.normal.vertex[4], 0.4, "button disable restores the latest native texture opacity")
equal(minimize.normal.atlas, "native-collapse", "button disable retains the current native collapse atlas")
minimize:OnEnter(); equal(minimizeArt.background.shown, false, "disabled feedback hooks cannot reveal owned button art")
Enabled(true)
local oldNormal = minimize.normal
minimize.normal = Widget(); skin:Refresh()
equal(oldNormal.vertex[4], 0.4, "replaced native button texture is restored")
equal(minimize.normal.vertex[4], 0, "replacement native button texture is restyled")
equal(skin.buttons[minimize], minimizeArt, "replacement native texture reuses the existing owned button art")
first.collapseValue = secret; skin:Refresh()
equal(minimizeArt.background.shown, false, "secret collapse state leaves the entire minimize button native")
equal(minimize.normal.vertex[4], 0.6, "secret collapse state restores supported native button artwork")
first.collapseValue = nil; skin:Refresh()
equal(minimizeArt.background.shown, true, "readable collapse state restores Suite button styling")
local removed = tracker.modules[2]
tracker.modules[2] = nil; tracker:Update(); Flush()
equal(PanelShown(removed.Header), false, "removed or relocated module loses owned art")
equal(removed.Header.Text.color[1], 1, "removed module restores its native header color")
equal(skin.buttons[removed.Header.MinimizeButton].background.shown, false, "removed section hides its button art")
equal(removed.Header.MinimizeButton.normal.vertex[4], 0.6, "removed section restores native button artwork")
local late = Module(); tracker.modules[2] = late; tracker:Update(); Flush()
equal(PanelShown(late.Header), true, "late module header receives the skin")
Native(function() first.Header.Text:SetFontObject({}) end); Flush(); Enabled(false)
equal(first.Header.Text.color[1], 0.7, "font-object changes retain latest native text color for restoration")
equal(first.Header.Text.color[4], 0.4, "font-object changes retain native alpha")

-- Missing, restricted and unreadable components stay on the native path independently.
local bad = Tracker(); ObjectiveTrackerFrame = bad
bad.Header.Background.vertex = { secret, 1, 1, 1 }
bad.modules[1].Header.Background.forbidden = true
bad.modules[2].Header.CreateTexture = nil
bad.NineSlice.restricted = true
Enabled(true)
equal(skin.panels[bad.Header], nil, "secret texture channels cannot be cached or restyled")
equal(skin.panels[bad.modules[1].Header], nil, "forbidden header artwork stays native")
equal(bad.modules[2].Header.Background.vertex[4], 0.6, "missing texture creation never suppresses native header art")
equal(bad.NineSlice.alpha, 0.35, "restricted anchor target stays native")
local partialButton = bad.Header.MinimizeButton
partialButton.GetPushedTexture = nil
bad.Header.Background.vertex = { 1, 1, 1, 1 }; bad.NineSlice.restricted = false
bad.Header.Text.GetTextColor = nil
skin:Refresh()
equal(PanelShown(bad.Header), true, "missing text-color API does not prevent an otherwise supported header panel")
equal(bad.Header.Text.color[1], 1, "missing text-color API retains native text styling")
equal(skin.buttons[partialButton], nil, "missing native button texture capability skips the whole button")
equal(partialButton.normal.vertex[4], 0.6, "partial button capabilities never suppress only one native state")
partialButton.GetPushedTexture = function(self) return self.pushed end
partialButton.pushed.vertex = { secret, 1, 1, 1 }; skin:Refresh()
equal(skin.buttons[partialButton], nil, "secret button texture color skips the whole button")
equal(partialButton.normal.vertex[4], 0.6, "secret button state leaves other native states intact")
partialButton.pushed.vertex = { 1, 1, 1, 1 }; skin:Refresh()
equal(skin.buttons[partialButton].background.shown, true, "readable button capabilities recover without a reload")
Native(function() partialButton.normal:SetVertexColor(secret, 1, 1, 1) end); Flush()
equal(skin.buttons[partialButton].background.shown, false, "unreadable native button update hides owned replacement art")
equal(partialButton.pushed.vertex[4], 1, "unreadable native button update restores the other states")
Native(function() partialButton.normal:SetVertexColor(1, 1, 1, 1) end); Flush()
equal(skin.buttons[partialButton].background.shown, true, "later readable native button update recovers styling")
Native(function() bad.NineSlice:SetAlpha(secret) end); Flush(); Enabled(false)
equal(bad.NineSlice.alpha, secret, "unreadable native alpha invalidates restoration")
equal(PanelShown(bad), false, "unreadable alpha hides owned body without replaying old data")
bad.NineSlice.alpha = 0.2
bad.Header.Text.GetTextColor = function(self) return unpack(self.color) end
Enabled(true)
Native(function() bad.Header.Text:SetTextColor(secret, 1, 1, 1); bad.Header.Background:SetVertexColor(secret, 1, 1, 1) end)
Flush(); Enabled(false)
equal(bad.Header.Text.color[1], secret, "unreadable text color is never overwritten or restored from stale data")
equal(bad.Header.Background.vertex[1], secret, "unreadable vertex color is never overwritten or restored from stale data")
ObjectiveTrackerFrame = secret; Enabled(true); equal(TimerCount(), 0, "restricted frame reference is not used as a key")
ObjectiveTrackerFrame = nil; skin:Refresh(); equal(TimerCount(), 0, "unavailable tracker needs no polling timer")
ObjectiveTrackerFrame = tracker; skin.events:OnEvent("ADDON_LOADED"); Flush()
equal(PanelShown(tracker), true, "late-loaded native tracker is styled through the addon event")

ObjectiveTrackerFrame = tracker
Enabled(false); Combat(true)
beforeCreated, beforeHooks = created, installed
Enabled(true); tracker:Update()
equal(created, beforeCreated, "combat enable creates no art")
equal(installed, beforeHooks, "combat enable installs no hooks")
equal(Suite.pending.questTrackerSkin ~= nil, true, "combat updates coalesce complete activation")
LeaveCombat(); equal(PanelShown(tracker), true, "combat exit completes activation")
equal(skin.events.registered.ADDON_LOADED, true, "retained combat hooks cannot omit event registration")
Combat(true)
local beforeButtonColor = minimizeArt.background.fill[1]
minimize.hovered = true; minimize:OnEnter(); minimize:OnMouseDown("LeftButton"); minimize:OnMouseUp("LeftButton")
equal(minimizeArt.background.fill[1], beforeButtonColor, "combat hover and press defer cosmetic writes")
Native(function() tracker.NineSlice:SetAlpha(0.58) end)
Enabled(false); equal(PanelShown(tracker), true, "combat disable waits before hiding protected-parent artwork")
LeaveCombat(); equal(PanelShown(tracker), false, "combat exit completes restoration")
equal(tracker.NineSlice.alpha, 0.58, "combat native updates become the restored value")
Combat(true); Enabled(true); Enabled(false); LeaveCombat()
equal(PanelShown(tracker), false, "rapid combat toggles retain the final disabled choice")
Enabled(true); tracker:Update()
local stale = timers[#timers]
Enabled(false); stale.callback()
equal(PanelShown(tracker), false, "stale cancelled worker cannot revive disabled skin")
equal(TimerCount(), 0, "disable cancels pending work")
Enabled(true); tracker:Update(); Combat(true); Flush()
equal(Suite.pending.questTrackerSkin ~= nil, true, "queued worker rechecks combat before writes")
LeaveCombat(); equal(PanelShown(tracker), true, "deferred worker resumes once")
Enabled(false)
local timerAPI = C_Timer; C_Timer = nil
Enabled(true); tracker:Update(); equal(PanelShown(tracker), true, "missing timer capability uses bounded immediate refresh")
Enabled(false); C_Timer = timerAPI
Suite.GUI:OpenPage("quests")
equal(Suite.GUI.rows[5].label.text, "Suite quest tracker skin", "quest page has an independent skin toggle")
equal(-Suite.GUI.rows[5].point[3] + Suite.GUI.rows[5].height < Suite.GUI.content.height - 28, true, "five quest rows fit above the footer")
Suite.GUI.rows[5]:OnClick(); equal(Suite.db.questTrackerSkin, true, "GUI toggle saves enabling skin")
equal(Suite.db.autoGossip, false, "GUI styling toggle leaves gossip preference independent")
Suite.GUI.rows[5]:OnClick(); equal(Suite.db.questTrackerSkin, false, "GUI toggle restores native styling")
skin:Cancel(); Combat(false)
Suite.db, Suite.pending = saved.db, saved.pending
skin.properties, skin.panels, skin.buttons, skin.watched, skin.events = saved.properties, saved.panels, saved.buttons, saved.watched, saved.events
ObjectiveTrackerFrame, CreateFrame, C_Timer, hooksecurefunc = saved.tracker, saved.create, saved.timer, saved.hook
