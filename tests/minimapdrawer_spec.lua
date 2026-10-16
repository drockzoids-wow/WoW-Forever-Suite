-- Exercise collection ownership, native handler retention and actual parent visibility.
local Suite, equal, Frame, SetCombat = ...
local drawer = Suite.MinimapDrawer
local names = { "CreateFrame", "C_Timer", "Minimap", "MinimapCluster", "MinimapBackdrop", "UIParent",
    "LibStub", "GetMinimapShape", "GameTooltip", "GetMouseFoci", "DoesAncestryIncludeAny", "UISpecialFrames", "GetCursorPosition" }
local old = {}; for _, name in ipairs(names) do old[name] = _G[name] end
local oldDB, oldPending, oldLauncher, oldLauncherEvents = Suite.db, Suite.pending, Suite.MinimapButton.button, Suite.MinimapButton.events
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
equal(Suite.db.minimapDrawerAngle, 225, "new drawer default is bottom left")
equal(Suite.db.minimapDrawerMoved, false, "new drawer uses its default dock until dragged")
local previousDefault = Suite.InitializeDB({ minimapDrawerAngle = 315 })
equal(previousDefault.minimapDrawerAngle, 225, "previous default migrates to bottom left")
equal(previousDefault.minimapDrawerMoved, false, "previous default adopts the bottom-left dock")
local customPosition = Suite.InitializeDB({ minimapDrawerAngle = 90 })
equal(customPosition.minimapDrawerAngle, 90, "upgrade preserves a custom drawer angle")
equal(customPosition.minimapDrawerMoved, true, "custom angle keeps ordinary edge projection")
local draggedDefault = Suite.InitializeDB({ minimapDrawerAngle = 315, minimapDrawerMoved = true })
equal(draggedDefault.minimapDrawerAngle, 315, "recorded drag to the old angle remains intentional")
local dockedDefault = Suite.InitializeDB({ minimapDrawerAngle = 225, minimapDrawerMoved = false })
equal(dockedDefault.minimapDrawerMoved, false, "reload preserves the default corner dock")
local invalidPosition = Suite.InitializeDB({ minimapDrawerAngle = { secret = true } })
equal(invalidPosition.minimapDrawerAngle, 225, "restricted drawer angle safely adopts the new default")
local inCombat, created, nativeClicks, nativeHovers = false, 0, {}, 0
local timers, foci, cursorX, cursorY = {}, {}, 500, 400
local function Combat(value) inCombat = value; SetCombat(value) end
local function LeaveCombat()
    Combat(false)
    local work = Suite.pending; Suite.pending = {}
    for _, callback in pairs(work) do callback() end
end
local function TimerCount()
    local count = 0; for _, timer in ipairs(timers) do if not timer.cancelled then count = count + 1 end end; return count
end
local function Flush()
    for _ = 1, 10 do
        local work = timers; timers = {}
        for _, timer in ipairs(work) do if not timer.cancelled then timer.callback() end end
        if TimerCount() == 0 then return end
    end
    error("drawer work must settle without polling")
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
local function Widget(kind, name, parent)
    local widget = Frame(name)
    widget.objectType, widget.parent, widget.shown, widget.alpha = kind, parent, true, 0.7
    widget.points, widget.events = {}, {}
    widget.IsForbidden = function(self) return self.forbidden or false end
    widget.IsProtected = function(self) return self.protected or false end
    widget.IsAnchoringRestricted = function(self) return self.anchoring or false end
    widget.GetFrameStrata = function(self) return self.strata or "MEDIUM" end
    widget.HasFixedFrameStrata = function(self) return self.fixedStrata == true end
    widget.HasFixedFrameLevel = function(self) return self.fixedLevel == true end
    widget.SetFixedFrameStrata = function(self, value) assert(not inCombat and not self.protected); self.fixedStrata = value end
    widget.SetFixedFrameLevel = function(self, value) assert(not inCombat and not self.protected); self.fixedLevel = value end
    widget.RegisterEvent = function(self, event) self.events[event] = true end
    widget.UnregisterEvent = function(self, event) self.events[event] = nil end
    widget.UnregisterAllEvents = function(self) self.events = {} end
    widget.GetNumPoints = function(self) return #self.points end
    widget.GetPoint = function(self, index) return unpack(self.points[index or 1]) end
    widget.IsVisible = function(self) return self.shown and (not self.parent or self.parent:IsVisible()) end
    widget.SetParent = function(self, target)
        assert(not inCombat and not self.protected, "drawer changed protected/combat parent")
        if self.parent then
            for index, child in ipairs(self.parent.children) do if child == self then table.remove(self.parent.children, index); break end end
        end
        self.parent = target
        target.children[#target.children + 1] = self
    end
    widget.SetPoint = function(self, ...)
        assert(not inCombat and not self.protected, "drawer changed protected/combat anchors")
        self.points[#self.points + 1] = { ... }; self.point = self.points[#self.points]
    end
    widget.ClearAllPoints = function(self)
        assert(not inCombat and not self.protected, "drawer cleared protected/combat anchors")
        self.points, self.point = {}, nil
    end
    for _, method in ipairs({ "SetSize", "SetScale", "SetFrameStrata", "SetFrameLevel" }) do
        local base = widget[method]
        widget[method] = function(self, ...)
            assert(not inCombat and not self.protected, "drawer changed protected/combat layout")
            if method == "SetFrameStrata" and self.fixedStrata or method == "SetFrameLevel" and self.fixedLevel then return end
            base(self, ...)
        end
    end
    widget.Show = function(self)
        assert(not inCombat or (self:IsProtected() == false and self:IsAnchoringRestricted() == false), "combat show must stay unprotected")
        local wasShown = self.shown; self.shown = true
        if not wasShown and self.OnShow then self.OnShow(self) end
    end
    widget.Hide = function(self)
        assert(not inCombat or (self:IsProtected() == false and self:IsAnchoringRestricted() == false), "combat hide must stay unprotected")
        local wasShown = self.shown; self.shown = false
        if wasShown and self.OnHide then self.OnHide(self) end
    end
    widget.SetShown = function(self, value) if value then self:Show() else self:Hide() end end
    if parent then parent.children[#parent.children + 1] = widget end
    return widget
end
CreateFrame = function(kind, name, parent)
    assert(not inCombat, "drawer created frames in combat")
    created = created + 1; return Widget(kind, name, parent)
end
UIParent = Widget("Frame", "UIParent"); UIParent:SetSize(1000, 800); UIParent:SetScale(0.8)
MinimapCluster = Widget("Frame", "MinimapCluster", UIParent)
Minimap = Widget("Minimap", "Minimap", MinimapCluster); Minimap:SetSize(240, 240); Minimap:SetScale(1.25)
MinimapBackdrop = Widget("Frame", "MinimapBackdrop", Minimap)
GetMinimapShape = function() return "ROUND" end
GetCursorPosition = function() return cursorX, cursorY end
UISpecialFrames = {}
GameTooltip = Widget("Frame", "GameTooltip", UIParent)
GameTooltip.IsOwned = function(self, owner) return self.owner == owner end
GameTooltip.SetOwner = function(self, owner) self.owner, self.lines = owner, {} end
GetMouseFoci = function() return foci end
DoesAncestryIncludeAny = function(ancestor, focuses)
    for _, focus in ipairs(focuses) do
        while focus do if focus == ancestor then return true end; focus = focus.parent end
    end
    return false
end
local function Launcher(name, parent, size)
    local button = Widget("Button", name, parent or Minimap)
    button:SetSize(size or 32, size or 32)
    button:SetPoint("CENTER", Minimap, "CENTER", 80, 60)
    button.icon = Frame()
    button:SetScript("OnClick", function(_, mouseButton) nativeClicks[#nativeClicks + 1] = mouseButton end)
    button:SetScript("OnEnter", function(self) nativeHovers = nativeHovers + 1; GameTooltip:SetOwner(self); GameTooltip:Show() end)
    button:SetScript("OnDragStart", function() error("collected native drag should be suppressed") end)
    button:SetScript("OnDragStop", function() end)
    return button
end
local alpha = Launcher("LibDBIcon10_Alpha")
alpha:SetScale(0.9); alpha:SetFrameStrata("HIGH"); alpha:SetFrameLevel(27)
alpha:SetPoint("TOP", Minimap, "TOP", 12, -5)
alpha:SetFixedFrameStrata(true); alpha:SetFixedFrameLevel(true)
local alphaClick, alphaEnter, alphaDrag = alpha:GetScript("OnClick"), alpha:GetScript("OnEnter"), alpha:GetScript("OnDragStart")
local beta = Launcher("MyAddonMinimapButton", MinimapCluster, 48)
local hidden = Launcher("LibDBIcon10_Hidden"); hidden:Hide()
local native = Launcher("ExpansionLandingPageMinimapButton", MinimapBackdrop)
local quest = Launcher("QuestPin42")
local anonymous = Launcher(nil)
local protected = Launcher("LibDBIcon10_Protected"); protected.protected = true
local restricted = Launcher("LibDBIcon10_Restricted"); restricted.protected = { secret = true }
local forbidden = Launcher("LibDBIcon10_Forbidden"); forbidden.forbidden = true
forbidden.GetName = function() error("forbidden button must not be inspected") end
local badPoint = Launcher("LibDBIcon10_BadPoint"); badPoint.points[1][4] = { secret = true }
local badIcon = Launcher("RestrictedIconButton"); badIcon.icon = { secret = true }
local restrictedAnchor = Launcher("LibDBIcon10_Anchoring"); restrictedAnchor.anchoring = { secret = true }
local busy = Launcher("LibDBIcon10_Busy"); busy:SetScript("OnUpdate", function() end)
local otherCollector = Launcher("ZoidsToolsMinimapButtonCollector")
Suite.MinimapButton.button, Suite.MinimapButton.events = nil, nil
Suite.MinimapButton:Apply()
local settings = Suite.MinimapButton.button
local settingsPoint = { unpack(settings.point) }
local settingsClick, settingsEnter, settingsDrag = settings:GetScript("OnClick"), settings:GetScript("OnEnter"), settings:GetScript("OnDragStart")
created = 0 -- The optional drawer must not create anything while disabled.
LibStub = nil
equal(Suite.db.minimapDrawer, false, "drawer starts off")
drawer:Apply()
equal(created, 0, "disabled drawer creates no frames")
equal(drawer.records[alpha], nil, "disabled drawer leaves addon buttons alone")
Suite.db.minimapDrawer = true; Combat(true); drawer:Apply()
equal(created, 0, "first drawer enable waits for combat")
Suite.db.minimapDrawer = false; drawer:Apply(); LeaveCombat()
equal(created, 0, "disable cancels deferred first enable")
Suite.db.minimapDrawer = true; drawer:Apply(); Flush()
equal(drawer.count, 3, "shown addon launchers include the anonymous Suite settings button")
equal(drawer.panel:IsShown(), false, "enable leaves drawer collapsed")
equal(drawer.button:IsShown(), true, "enable shows the separate grid launcher")
equal(drawer.button:IsMouseClickEnabled(), true, "grid launcher explicitly accepts native mouse input")
equal(alpha:GetParent(), drawer.panel, "original button is collected")
equal(alpha:GetFrameStrata(), "DIALOG", "fixed-layer library icon renders at the drawer's strata")
equal(alpha:GetFrameLevel(), drawer.panel:GetFrameLevel() + 2, "fixed-layer library icon renders above the panel background")
equal(alpha:HasFixedFrameStrata(), false, "collector temporarily releases fixed strata")
equal(alpha:HasFixedFrameLevel(), false, "collector temporarily releases fixed frame level")
equal(alpha:IsShown(), true, "collection preserves original shown flag")
equal(alpha:IsVisible(), false, "collapsed parent hides collected button")
equal(alpha.alpha, 0.7, "collection preserves owner alpha")
equal(beta:GetScale(), 24 / 48, "large launcher fits the compact grid without changing its dimensions")
equal(beta:GetWidth(), 48, "native button dimensions are retained")
equal(alpha.point[4] * alpha:GetScale(), 16, "first sorted button has a panel-unit cell offset")
equal(beta.point[4] * beta:GetScale(), 44, "scaled button has equal compact cell spacing")
equal(alpha.point[5] * alpha:GetScale(), -16, "scaled row offset uses panel units")
equal(drawer.panel:GetScale(), 1.25, "drawer follows map scale relative to UIParent")
equal(#alpha.points, 1, "grid has one anchor per button")
equal(alpha:GetScript("OnEnter"), alphaEnter, "original tooltip handler is preserved")
equal(alpha:GetScript("OnDragStart"), nil, "native edge dragging is disabled inside drawer")
equal(settings:GetParent(), drawer.panel, "Suite settings is collected as an ordinary addon button")
equal(settings:GetScript("OnEnter"), settingsEnter, "Suite tooltip handler is retained")
equal(settings:GetScript("OnDragStart"), nil, "Suite edge dragging is suspended while collected")
local suiteHUD = Launcher("WoWForeverSuiteHUDButton")
for _, button in ipairs({ native, quest, anonymous, protected, restricted, forbidden, badPoint, badIcon, restrictedAnchor, busy, otherCollector, suiteHUD, drawer.button }) do
    equal(drawer.records[button], nil, "native/unsafe/non-launcher/other-collector controls stay untouched")
end
equal(native:GetParent(), MinimapBackdrop, "native expansion control keeps its parent")
equal(TimerCount(), 0, "stable drawer leaves no refresh timer")
equal(drawer.panel:GetScript("OnUpdate"), nil, "drawer has no mouse polling updater")
equal(drawer.button:GetScript("OnUpdate"), nil, "drawer launcher has no idle updater")
equal(UISpecialFrames[1], "WoWForeverSuiteMinimapDrawer", "Escape dispatcher owns the single named drawer")
equal(drawer.button.point[4] < 0 and drawer.button.point[5] < 0, true, "round drawer default lies at the lower-left edge")
Suite.db.squareMinimap = true; drawer:Apply(); Flush()
equal(drawer.button.point[1], "BOTTOMRIGHT", "square default aligns the launcher bottom with the map bottom")
equal(drawer.button.point[2], Minimap, "square default follows the actual minimap")
equal(drawer.button.point[3], "BOTTOMLEFT", "square default docks outside the bottom-left corner")
equal(drawer.button.point[4], -1, "square default touches the outer map border")
equal(drawer.button.point[5], 0, "square default is flush with the bottom border")
Minimap:SetSize(180, 270); drawer:Apply(); Flush()
equal(drawer.button.point[3], "BOTTOMLEFT", "default dock survives a rectangular map resize")
equal(drawer.button.point[5], 0, "default dock stays flush after resize")
Minimap:SetSize(240, 240); Suite.db.squareMinimap = false; drawer:Apply(); Flush()
Suite.MinimapButton:Apply(); Flush()
equal(settings.point[2], drawer.panel, "settings refresh cannot pull the collected button back to the map")
equal(TimerCount(), 0, "Suite settings refresh settles without a worker loop")
drawer:Toggle()
equal(alpha:IsVisible(), true, "opening parent reveals original buttons")
equal(settings:IsVisible(), true, "opening drawer reveals Suite settings")
equal(hidden:IsVisible(), false, "owner-hidden button stays hidden")
equal(drawer.panel.events.GLOBAL_MOUSE_DOWN, true, "open drawer registers click-away input")
settings.OnEnter(settings)
equal(GameTooltip.lines[2][1]:find("Drag", 1, true), nil, "collected Suite tooltip does not advertise suspended dragging")
equal(GameTooltip.owner, settings, "Suite tooltip stays on the original button")
alpha.OnEnter(alpha)
equal(nativeHovers, 1, "native tooltip callback still runs")
equal(GameTooltip.owner, alpha, "native tooltip still belongs to original button")
alpha.OnClick(alpha, "RightButton"); Flush()
equal(nativeClicks[1], "RightButton", "right click reaches native handler")
equal(drawer.panel:IsShown(), true, "right-click menu use keeps drawer open")
alpha.OnClick(alpha, "LeftButton")
equal(nativeClicks[2], "LeftButton", "left click runs native handler before dismissal")
equal(drawer.panel:IsShown(), true, "left-click dismissal waits until handler returns")
Flush()
equal(drawer.panel:IsShown(), false, "left-click dismisses drawer")
equal(GameTooltip:IsShown(), false, "closing clears collected owner tooltip")
drawer:Toggle()
local oldToggle, settingsActions = Suite.GUI.Toggle, 0
Suite.GUI.Toggle = function() settingsActions = settingsActions + 1 end
settings.OnMouseDown(settings); settings.OnClick(settings, "LeftButton")
equal(settingsActions, 1, "collected Suite button opens settings through its original handler")
equal(drawer.panel:IsShown(), true, "Suite action completes before drawer dismissal")
Flush(); Suite.GUI.Toggle = oldToggle
equal(drawer.panel:IsShown(), false, "Suite left click dismisses the drawer after its action")
Suite.db.minimapButton = false; Suite.MinimapButton:Apply(); Flush()
equal(settings:IsShown(), false, "Suite visibility preference hides the collected button")
equal(drawer.count, 2, "hidden Suite button leaves no drawer cell")
Suite.db.minimapButton = true; Suite.MinimapButton:Apply(); Flush()
equal(settings:GetParent(), drawer.panel, "showing Suite settings keeps collection ownership")
equal(drawer.count, 3, "showing Suite settings restores its drawer cell")
drawer:Toggle(); foci = { alpha }; drawer.panel.OnEvent()
equal(drawer.panel:IsShown(), true, "collected button focus counts as interior")
foci = { drawer.button }; drawer.panel.OnEvent()
equal(drawer.panel:IsShown(), true, "launcher focus is exempt from click-away closing")
foci = { { secret = true } }; drawer.panel.OnEvent()
equal(drawer.panel:IsShown(), true, "restricted mouse focus cannot close drawer")
foci = { UIParent }; GameTooltip.owner = native; GameTooltip:Show(); drawer.panel.OnEvent()
equal(drawer.panel:IsShown(), false, "outside click closes without an input overlay")
equal(GameTooltip:IsShown(), true, "closing preserves another native tooltip")
drawer:Toggle(); drawer.panel:Hide()
equal(drawer.panel.events.GLOBAL_MOUSE_DOWN, nil, "Escape unregisters click-away event")
equal(alpha:IsShown(), true, "Escape preserves individual shown flags")
hidden:Show(); Flush()
equal(drawer.count, 4, "owner showing a hidden launcher adds its cell")
hidden:Hide(); Flush()
equal(drawer.count, 3, "owner hiding a launcher removes its cell")
-- LibDBIcon's own positioning/registration can run after Suite login.
local registered, callbacks = { "Alpha" }, {}
local lib = {
    RegisterCallback = function(target, event, callback) callbacks[event] = callback; equal(target, drawer, "library callback has module ownership") end,
    GetButtonList = function() return registered end,
    GetMinimapButton = function(_, name) return name == "Late" and _G.TestLateDrawerIcon or alpha end,
    Show = function() end, Hide = function() end, Refresh = function() end,
    ShowOnEnter = function(self, name, value)
        local button = self:GetMinimapButton(name)
        button.showOnMouseover = value and true or false
        button.alpha = value and 0 or 1
    end,
}
alpha.showOnMouseover = true; alpha.alpha = 0
LibStub = function() return lib end
drawer:Apply()
equal(alpha.showOnMouseover, false, "collected library icon stops minimap-only mouseover fading")
equal(alpha.alpha, 1, "collected mouseover icon is fully visible")
equal(drawer.records[alpha].mouseover, true, "collector remembers owner mouseover preference separately")
lib:ShowOnEnter("Alpha", nil); Flush()
equal(drawer.records[alpha].mouseover, false, "owner disabling fading updates the restoration preference")
lib:ShowOnEnter("Alpha", true); Flush()
equal(alpha.showOnMouseover, false, "owner refresh cannot fade collected icons again")
equal(alpha.alpha, 1, "icon remains visible after owner requests mouseover-only mode")
equal(TimerCount(), 0, "visibility correction settles without a feedback loop")
alpha:SetFixedFrameStrata(true); alpha:SetFixedFrameLevel(true); Flush()
equal(alpha:GetFrameStrata(), "DIALOG", "late owner fixed-layer updates are reapplied inside the drawer")
equal(alpha:HasFixedFrameStrata(), false, "late fixed-strata request cannot bury the icon")
local late = Launcher("LibDBIcon10_Late"); _G.TestLateDrawerIcon = late
registered[#registered + 1] = "Late"
callbacks.LibDBIcon_IconCreated("LibDBIcon_IconCreated", late, "Late")
equal(TimerCount(), 1, "new library icon queues discovery")
Flush()
equal(late:GetParent(), drawer.panel, "late library button is collected")
equal(drawer.count, 4, "late icon adds a grid cell")
equal(drawer.panel:IsShown(), false, "late discovery never opens drawer")
alpha:ClearAllPoints(); alpha:SetPoint("CENTER", Minimap, "CENTER", 400, 400)
lib:Refresh()
for _ = 1, 500 do drawer.events.OnEvent(drawer.events, "ADDON_LOADED") end
equal(TimerCount(), 1, "library reanchors and addon event bursts share one worker")
Flush()
equal(alpha.point[2], drawer.panel, "library reanchor settles back into drawer")
equal(TimerCount(), 0, "refresh hooks do not create an idle loop")
local originalScaleGetter = beta.GetScale
beta.GetScale = function() return { secret = true } end
drawer:Refresh()
equal(beta.point[4] * beta.scale, 72, "grid offsets use validated layout scale without reading restricted scale")
beta.GetScale = originalScaleGetter
local originalParentGetter = beta.GetParent
beta.GetParent = function() return { secret = true } end
drawer:Refresh()
equal(beta.parent, drawer.panel, "restricted hierarchy is skipped without ownership or anchor writes")
beta.GetParent = originalParentGetter
drawer:Refresh()
local newerDrag = function() end
alpha:SetScript("OnDragStart", newerDrag); Flush()
equal(alpha:GetScript("OnDragStart"), nil, "owner drag refresh is suppressed while collected")
-- All foreign geometry waits until combat exits; closing the unprotected drawer remains allowed.
drawer:Toggle(); drawer.button.OnMouseDown(); drawer.button.OnDragStart()
equal(type(drawer.button.OnUpdate), "function", "drawer updater exists only during its own drag")
cursorX, cursorY = 500, 550; drawer.button.OnUpdate()
equal(Suite.db.minimapDrawerAngle, 90, "drawer saves its own cursor angle")
equal(Suite.db.minimapDrawerMoved, true, "drag opts out of default corner docking")
equal(Suite.db.minimapButtonAngle, 225, "drawer drag does not change settings-launcher angle")
Suite.db.squareMinimap = true; drawer:Position()
equal(drawer.button.point[1], "CENTER", "dragged positions keep ordinary square-map edge projection")
Suite.db.squareMinimap = false
Combat(true); drawer.events.OnEvent(drawer.events, "PLAYER_REGEN_DISABLED")
equal(drawer.dragging, false, "combat immediately ends drawer drag")
equal(drawer.button.OnUpdate, nil, "combat removes gesture updater")
equal(drawer.panel:IsShown(), false, "interrupted drag keeps the drawer closed")
local combatCreated, combatCount, combatPoint = created, drawer.count, alpha.point
drawer:Toggle(); equal(drawer.panel:IsShown(), true, "prepared unprotected drawer opens in combat")
equal(created, combatCreated, "combat drawer opening creates no frames")
equal(drawer.count, combatCount, "combat drawer opening uses the existing collection")
equal(alpha.point, combatPoint, "combat drawer opening changes no icon anchors")
equal(drawer.panel.events.GLOBAL_MOUSE_DOWN, true, "combat drawer retains click-away closing")
drawer.events.OnEvent(drawer.events, "PLAYER_REGEN_DISABLED")
equal(drawer.panel:IsShown(), true, "entering combat leaves an open drawer usable")
alpha.OnClick(alpha, "RightButton"); Flush()
equal(drawer.panel:IsShown(), true, "native right-click menu retains the combat drawer")
alpha.OnClick(alpha, "LeftButton"); Flush()
equal(drawer.panel:IsShown(), false, "native left-click still dismisses combat drawer")
drawer:Toggle(); foci = { UIParent }; drawer.panel.OnEvent()
equal(drawer.panel:IsShown(), false, "outside click dismisses combat drawer")
drawer:Toggle(); drawer.panel:Hide()
equal(drawer.panel.events.GLOBAL_MOUSE_DOWN, nil, "Escape removes combat click-away subscription")
for _, restriction in ipairs({ true, { secret = true } }) do
    drawer.panel.protected = restriction
    drawer:Toggle(); equal(drawer.panel:IsShown(), false, "protected/secret panel cannot open in combat")
    drawer.panel.protected = false
    alpha.protected = restriction
    drawer:Toggle(); equal(drawer.panel:IsShown(), false, "protected/secret collected child prevents combat opening")
    alpha.protected = false
end
local panelProtection = drawer.panel.IsProtected
drawer.panel.IsProtected = nil; drawer:Toggle()
equal(drawer.panel:IsShown(), false, "missing panel protection predicate prevents combat opening")
drawer.panel.IsProtected = panelProtection
drawer.panel.anchoring = true; drawer:Toggle()
equal(drawer.panel:IsShown(), false, "restricted panel cannot open in combat")
drawer.panel.anchoring = false
local parentGetter = alpha.GetParent
alpha.GetParent = function() return { secret = true } end
drawer:Toggle(); equal(drawer.panel:IsShown(), false, "secret collection ownership prevents combat opening")
alpha.GetParent = parentGetter
drawer.prepared = nil; drawer:Toggle()
equal(drawer.panel:IsShown(), false, "combat-first collection waits for preparation")
drawer.prepared = true
drawer:Toggle()
alpha.protected = true; drawer:Close()
equal(drawer.panel:IsShown(), true, "new protected child prevents combat ancestor hide")
equal(type(Suite.pending.minimapDrawerClose), "function", "unsafe combat closing defers until combat ends")
alpha.protected = false; drawer:Close()
equal(drawer.panel:IsShown(), false, "unprotected combat closing recovers")
equal(Suite.pending.minimapDrawerClose, nil, "recovered close clears stale deferred work")
drawer:Toggle(); drawer:Toggle()
equal(drawer.panel:IsShown(), false, "second combat launcher click closes the drawer")
drawer:Toggle(); alpha.protected = true; drawer:Close()
equal(drawer.panel:IsShown(), true, "protected close remains pending during combat")
LeaveCombat(); Flush()
equal(drawer.panel:IsShown(), false, "deferred close completes outside combat")
alpha.protected = false
drawer:Refresh()
Combat(true)
Suite.db.minimapDrawer = false; drawer:Apply()
equal(alpha:GetParent(), drawer.panel, "disable in combat defers foreign parent restoration")
equal(settings:GetParent(), drawer.panel, "disable in combat also defers Suite button restoration")
equal(TimerCount(), 0, "disable cancels queued workers")
LeaveCombat(); Flush()
equal(alpha:GetParent(), Minimap, "disable restores original minimap parent")
equal(beta:GetParent(), MinimapCluster, "disable restores cluster-parented launcher")
equal(alpha:GetScale(), 0.9, "disable restores original scale")
equal(alpha:GetFrameStrata(), "HIGH", "disable restores original strata")
equal(alpha:GetFrameLevel(), 27, "disable restores original frame level")
equal(alpha:HasFixedFrameStrata(), true, "disable restores the latest owner fixed-strata flag")
equal(alpha:HasFixedFrameLevel(), true, "disable restores the latest owner fixed-level flag")
equal(alpha.showOnMouseover, true, "disable restores the owner's original mouseover visibility mode")
equal(#alpha.points, 2, "disable restores every native anchor")
equal(alpha.points[1][4], 80, "restore preserves first anchor offset")
equal(alpha.points[2][1], "TOP", "restore preserves second anchor point")
equal(alpha.points[2][5], -5, "restore preserves second anchor offset")
equal(alpha:GetScript("OnDragStart"), newerDrag, "disable restores latest owner drag script")
equal(alpha:GetScript("OnEnter"), alphaEnter, "disable retains original tooltip handler")
equal(hidden:IsShown(), false, "disable honors owner hidden state")
equal(drawer.button:IsShown(), false, "disable hides grid button")
equal(next(drawer.records), nil, "disable releases frame records")
equal(settings:GetParent(), Minimap, "disable restores Suite settings to the map")
equal(settings:GetScale(), 1, "disable restores Suite settings scale")
equal(settings:GetScript("OnDragStart"), settingsDrag, "disable restores Suite edge dragging")
equal(settings.point[4], settingsPoint[4], "disable restores Suite saved horizontal position")
equal(settings.point[5], settingsPoint[5], "disable restores Suite saved vertical position")
Suite.MinimapButton:Apply()
equal(settings.point[2], Minimap, "ordinary Suite positioning resumes after drawer disable")
alpha:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, 2); lib:Show(); Flush()
equal(TimerCount(), 0, "disabled retained hooks and library callbacks do no work")
Suite.db.minimapDrawer = true; drawer:Apply(); Flush()
equal(#UISpecialFrames, 1, "re-enable reuses Escape registration")
equal(drawer.panel:IsShown(), false, "re-enable starts collapsed")
drawer.button.OnDragStop(); drawer.button.OnClick()
equal(drawer.panel:IsShown(), false, "interrupted drag release cannot toggle drawer")
drawer.button.OnMouseDown(); drawer.button.OnClick()
equal(drawer.panel:IsShown(), true, "ordinary launcher click toggles drawer")
local outsider = Widget("Frame", "OtherCollector", UIParent)
beta:SetParent(outsider); Flush()
equal(beta:GetParent(), outsider, "another collector acquiring a button keeps its geometry")
equal(drawer.records[beta], nil, "competing ownership releases Suite record")
late:SetParent(outsider)
Suite.db.minimapDrawer = false; drawer:Apply(); Flush()
equal(late:GetParent(), outsider, "immediate disable cannot steal a button before queued ownership release")
for button in pairs(drawer.hooked) do button:Hide() end
Minimap.children, MinimapCluster.children, MinimapBackdrop.children = {}, {}, {}
Suite.db.minimapDrawer = true; drawer:Apply(); Flush(); drawer:Toggle()
equal(drawer.count, 0, "empty drawer has no forced hidden launchers")
equal(drawer.empty:IsShown(), true, "empty drawer gives useful feedback")
equal(drawer.panel:IsShown(), true, "empty drawer still opens")
drawer:Close()
Combat(true); drawer:Toggle()
equal(drawer.panel:IsShown(), true, "prepared empty drawer opens in combat")
drawer:Close(); LeaveCombat()
Suite.MinimapButton.button, Suite.MinimapButton.events = nil, nil
Combat(true); Suite.MinimapButton:Apply()
equal(Suite.MinimapButton.button, nil, "late Suite button creation waits for combat exit")
LeaveCombat()
equal(TimerCount(), 1, "late Suite button creation schedules drawer discovery")
Flush()
equal(Suite.MinimapButton.button:GetParent(), drawer.panel, "late-created anonymous Suite button is collected without opening the drawer")
equal(drawer.count, 1, "late Suite button adds an ordinary drawer cell")
equal(drawer.panel:IsShown(), false, "late Suite creation leaves the drawer collapsed")
Suite.db.minimapDrawer = false; drawer:Apply(); Flush()
_G.TestLateDrawerIcon = nil
Suite.db, Suite.pending, Suite.MinimapButton.button, Suite.MinimapButton.events = oldDB, oldPending, oldLauncher, oldLauncherEvents
for _, name in ipairs(names) do _G[name] = old[name] end
Combat(false)
