local _, Suite = ...
local Drawer = { records = {}, hooked = {} }
Suite.MinimapDrawer = Drawer
table.insert(Suite.modules, Drawer)
local SIZE, GAP, PADDING = 24, 4, 4
local CELL = SIZE + GAP
local ignored = {
    AddonCompartmentFrame = true, GameTimeFrame = true, TimeManagerClockButton = true,
    ExpansionLandingPageMinimapButton = true, GarrisonLandingPageMinimapButton = true,
    MiniMapTracking = true, MiniMapTrackingButton = true, MiniMapWorldMapButton = true,
    MiniMapMailFrame = true, MiniMapBattlefieldFrame = true, QueueStatusMinimapButton = true,
    MinimapZoomIn = true, MinimapZoomOut = true, MiniMapInstanceDifficulty = true,
    GuildInstanceDifficulty = true, InstanceDifficultyFrame = true,
    ZoidsToolsMinimapButtonCollector = true, MBB_MinimapButton = true,
    LibDBIcon10_HidingBar = true, LibDBIcon10_MinimapButtonBag = true,
}

local function Read(value, kind) return Suite.IsReadable(value) and type(value) == kind end
local function Number(value) return Read(value, "number") and value == value and math.abs(value) < math.huge end
local function Available(frame)
    if not Suite.IsReadable(frame) or not frame or (type(frame) ~= "table" and type(frame) ~= "userdata")
        or type(frame.IsForbidden) ~= "function" then return false end
    local forbidden = frame:IsForbidden()
    return Read(forbidden, "boolean") and not forbidden
end
local function Movable(frame)
    if not Available(frame) or type(frame.IsProtected) ~= "function" then return false end
    local protected = frame:IsProtected()
    if not Read(protected, "boolean") or protected then return false end
    if frame.IsAnchoringRestricted then
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

function Drawer:Candidate(button)
    if button == self.button or not Movable(button) then return end
    -- The known Suite launcher is anonymous; use an internal sort key without a global frame name.
    local settings = button == Suite.MinimapButton.button
    local kind, name = button:GetObjectType(), settings and "WoWForeverSuiteMinimapButton" or button:GetName()
    if not Read(kind, "string") or (kind ~= "Button" and kind ~= "CheckButton")
        or not Read(name, "string") or name == "" or ignored[name] then return end
    if name:match("^Quest") or name:match("^Vignette") or name:match("^GatherMate")
        or name:match("^HandyNotes") or name:match("^MinimapPin") or (name:match("^WoWForeverSuite") and not settings)
        or name:find("Collector", 1, true) or name:find("Drawer", 1, true) then return end
    local width, height = button:GetWidth(), button:GetHeight()
    if not Number(width) or not Number(height) or width < 12 or height < 12 or width > 70 or height > 70 then return end
    -- Custom launchers need an icon; a small named HUD control is insufficient evidence.
    local icon = button.icon
    if not Suite.IsReadable(icon) then return end
    if icon == nil then icon = button.Icon end
    if not Suite.IsReadable(icon) then return end
    if not name:match("^LibDBIcon10_") and type(icon) ~= "table" and type(icon) ~= "userdata" then
        local texture = button.GetNormalTexture and button:GetNormalTexture()
        if not Suite.IsReadable(texture) or texture == nil then return end
    end
    return name, width, height
end

function Drawer:Remember(button)
    if not Suite.IsReadable(button) or not button then return end
    if self.records[button] then return end
    local name, width, height = self:Candidate(button)
    if not name then return end
    local updater = button:GetScript("OnUpdate")
    if not Suite.IsReadable(updater) or updater then return end -- Leave an ongoing addon gesture alone.
    local parent, scale, strata, level = button:GetParent(), button:GetScale(), button:GetFrameStrata(), button:GetFrameLevel()
    local count = button:GetNumPoints()
    if not Available(parent) or not Number(scale) or scale <= 0 or not Read(strata, "string")
        or not Number(level) or not Number(count) or count < 1 or count > 8 or count ~= math.floor(count) then return end
    local record = { name = name, parent = parent, scale = scale, strata = strata, level = level,
        width = width, height = height, points = {}, drag = {} }
    for _, suffix in ipairs({ "Strata", "Level" }) do
        local getter, setter = button["HasFixedFrame" .. suffix], button["SetFixedFrame" .. suffix]
        if type(getter) == "function" and type(setter) == "function" then
            local fixed = getter(button)
            if not Read(fixed, "boolean") then return end
            record["fixed" .. suffix] = fixed
        end
    end
    for index = 1, count do
        local point, relative, relativePoint, x, y = button:GetPoint(index)
        if not Read(point, "string") or not Read(relativePoint, "string") or not Suite.IsReadable(relative)
            or not Number(x) or not Number(y) then return end
        if relative ~= nil and not Available(relative) then return end
        record.points[index] = { point, relative, relativePoint, x, y }
    end
    for _, script in ipairs({ "OnDragStart", "OnDragStop" }) do
        local handler = button:GetScript(script)
        if not Suite.IsReadable(handler) then return end
        record.drag[script] = handler
    end
    self.records[button] = record
    if self.hooked[button] then return end
    self.hooked[button] = true
    local function Changed()
        if self.records[button] then self:Schedule() end
    end
    for _, method in ipairs({ "SetPoint", "SetParent", "SetScale", "SetFrameStrata", "SetFrameLevel" }) do
        hooksecurefunc(button, method, Changed)
    end
    for _, suffix in ipairs({ "Strata", "Level" }) do
        if record["fixed" .. suffix] ~= nil then
            hooksecurefunc(button, "SetFixedFrame" .. suffix, function(_, fixed)
                local current = self.records[button]
                if not current or self.changing or not Read(fixed, "boolean") then return end
                current["fixed" .. suffix] = fixed; self:Schedule()
            end)
        end
    end
    hooksecurefunc(button, "SetScript", function(_, script, handler)
        local current = self.records[button]
        if not current or self.changing or not Read(script, "string") then return end
        if script == "OnDragStart" or script == "OnDragStop" then
            if Suite.IsReadable(handler) then current.drag[script] = handler; self:Schedule() end
        end
    end)
    button:HookScript("OnShow", Changed)
    button:HookScript("OnHide", Changed)
    button:HookScript("OnClick", function(_, mouseButton)
        if not self.records[button] or not Suite.db.minimapDrawer or not Read(mouseButton, "string")
            or mouseButton ~= "LeftButton" or not Shown(self.panel) then return end
        if self.clickTimer then self.clickTimer:Cancel() end
        -- Let the original handler finish before dismissing its button's parent.
        self.clickTimer = C_Timer.NewTimer(0, function() self.clickTimer = nil; self:Close() end)
    end)
end

function Drawer:Library()
    if not Suite.IsReadable(LibStub) or not LibStub then return end
    local ok, lib = pcall(LibStub, "LibDBIcon-1.0", true)
    if not ok or not Read(lib, "table") then return end
    if self.library ~= lib then
        self.library = lib
        if lib.RegisterCallback then lib.RegisterCallback(self, "LibDBIcon_IconCreated", function() self:Schedule() end) end
        for _, method in ipairs({ "Show", "Hide", "Refresh" }) do
            if type(lib[method]) == "function" then hooksecurefunc(lib, method, function() self:Schedule() end) end
        end
        if type(lib.ShowOnEnter) == "function" then
            hooksecurefunc(lib, "ShowOnEnter", function(_, name, value)
                if self.changing or not Read(name, "string") then return end
                for button, record in pairs(self.records) do
                    if record.libraryName == name and Read(button.showOnMouseover, "boolean") then
                        record.mouseover = button.showOnMouseover
                        if not record.mouseover then record.mouseoverOverride = nil end
                        self:Schedule()
                    end
                end
            end)
        end
    end
    if type(lib.GetButtonList) ~= "function" or type(lib.GetMinimapButton) ~= "function" then return end
    local names = lib:GetButtonList()
    if not Read(names, "table") then return end
    for _, name in ipairs(names) do
        if Read(name, "string") then
            local button = lib:GetMinimapButton(name)
            if Available(button) then
                local parent = button:GetParent()
                if Suite.IsReadable(parent) and (parent == Minimap or parent == MinimapBackdrop or parent == MinimapCluster) then
                    self:Remember(button)
                end
                local record = self.records[button]
                if record then
                    record.libraryName = name
                    if record.mouseover == nil and Read(button.showOnMouseover, "boolean") then record.mouseover = button.showOnMouseover end
                end
            end
        end
    end
end

function Drawer:Discover()
    local containers = { Minimap, MinimapCluster, MinimapBackdrop, MinimapCluster and MinimapCluster.MinimapContainer }
    for _, container in pairs(containers) do
        if Available(container) and container.GetChildren then
            for _, child in ipairs({ container:GetChildren() }) do
                if Suite.IsReadable(child) then self:Remember(child) end
            end
        end
    end
    self:Library()
end

function Drawer:Position()
    if InCombatLockdown() then return end
    Suite.MinimapButton:PlaceButton(self.button, Suite.db.minimapDrawerAngle, not Suite.db.minimapDrawerMoved)
    local mapScale, rootScale = Minimap:GetEffectiveScale(), UIParent:GetEffectiveScale()
    local x, width = self.button:GetCenter(), UIParent:GetWidth()
    if not Number(mapScale) or mapScale <= 0 or not Number(rootScale) or rootScale <= 0
        or not Number(x) or not Number(width) or width <= 0 then return end
    self.panel:SetScale(mapScale / rootScale)
    self.panel:ClearAllPoints()
    if x * mapScale > width * rootScale / 2 then self.panel:SetPoint("RIGHT", self.button, "LEFT", -GAP, 0)
    else self.panel:SetPoint("LEFT", self.button, "RIGHT", GAP, 0) end
end

function Drawer:Restore(button, record, geometry)
    if InCombatLockdown() or not Movable(button) then return false end
    local parent = button:GetParent()
    if not Suite.IsReadable(parent) then return false end
    if parent ~= self.panel and parent ~= record.parent then geometry = false end
    local current = {}
    for _, script in ipairs({ "OnDragStart", "OnDragStop" }) do
        local handler = button:GetScript(script)
        if not Suite.IsReadable(handler) then return false end
        current[script] = handler
    end
    if geometry then
        if not Available(record.parent) then return false end
        for _, point in ipairs(record.points) do if point[2] and not Available(point[2]) then return false end end
        for _, suffix in ipairs({ "Strata", "Level" }) do
            if record["fixed" .. suffix] ~= nil then button["SetFixedFrame" .. suffix](button, false) end
        end
        button:SetParent(record.parent)
        button:SetScale(record.scale)
        button:SetFrameStrata(record.strata)
        button:SetFrameLevel(record.level)
        button:ClearAllPoints()
        for _, point in ipairs(record.points) do button:SetPoint(unpack(point)) end
    end
    for _, suffix in ipairs({ "Strata", "Level" }) do
        if record["fixed" .. suffix] ~= nil then button["SetFixedFrame" .. suffix](button, record["fixed" .. suffix]) end
    end
    if record.mouseoverOverride and record.mouseover ~= nil and record.libraryName and self.library and type(self.library.ShowOnEnter) == "function"
        and type(self.library.GetMinimapButton) == "function" and self.library:GetMinimapButton(record.libraryName) == button then
        self.library:ShowOnEnter(record.libraryName, record.mouseover)
    end
    for _, script in ipairs({ "OnDragStart", "OnDragStop" }) do
        if current[script] == nil then button:SetScript(script, record.drag[script]) end
    end
    return true
end

function Drawer:Refresh()
    if InCombatLockdown() or not Suite.db.minimapDrawer or not self.panel then return end
    self.changing = true
    self:Discover()
    local buttons = {}
    for button, record in pairs(self.records) do
        if Movable(button) then
            local parent = button:GetParent()
            if not Suite.IsReadable(parent) then
                -- Unavailable hierarchy cannot be used to decide ownership or change anchors.
            elseif parent ~= self.panel and parent ~= record.parent then
                -- Another collector acquired it. Give up our script changes without fighting its geometry.
                if self:Restore(button, record, false) then self.records[button] = nil end
            else
                -- New LibDBIcon versions fix both render layers. Release those
                -- owner flags while collected, so the icon can sit above our panel.
                for _, suffix in ipairs({ "Strata", "Level" }) do
                    if record["fixed" .. suffix] ~= nil then button["SetFixedFrame" .. suffix](button, false) end
                end
                if record.mouseover == true and record.libraryName and self.library and type(self.library.ShowOnEnter) == "function"
                    and type(self.library.GetMinimapButton) == "function" and self.library:GetMinimapButton(record.libraryName) == button then
                    record.mouseoverOverride = true
                    self.library:ShowOnEnter(record.libraryName, false)
                end
                if parent ~= self.panel then button:SetParent(self.panel) end
                button:SetScale(SIZE / math.max(record.width, record.height))
                button:SetFrameStrata("DIALOG")
                button:SetFrameLevel(self.panel:GetFrameLevel() + 2)
                button:SetScript("OnDragStart", nil); button:SetScript("OnDragStop", nil)
                if Shown(button) then buttons[#buttons + 1] = button end
            end
        end
    end
    table.sort(buttons, function(left, right) return self.records[left].name:lower() < self.records[right].name:lower() end)
    local columns = math.min(4, math.max(1, #buttons))
    self.panel:SetSize(#buttons == 0 and 166 or columns * CELL - GAP + PADDING * 2,
        #buttons == 0 and 44 or math.ceil(#buttons / columns) * CELL - GAP + PADDING * 2)
    self.empty:SetShown(#buttons == 0)
    for index, button in ipairs(buttons) do
        local record = self.records[button]
        local scale = SIZE / math.max(record.width, record.height)
        button:ClearAllPoints()
        -- SetPoint offsets use the scaled button's units; cell positions use panel units.
        button:SetPoint("CENTER", self.panel, "TOPLEFT", (PADDING + SIZE / 2 + CELL * ((index - 1) % columns)) / scale,
            -(PADDING + SIZE / 2 + CELL * math.floor((index - 1) / columns)) / scale)
    end
    self.count = #buttons
    self:Position()
    self.prepared = true
    self.changing = false
end

function Drawer:Schedule()
    if self.changing or not Suite.db or not Suite.db.minimapDrawer or self.timer then return end
    if InCombatLockdown() then Suite.AfterCombat("minimapDrawer", function() self:Apply() end); return end
    self.timer = C_Timer.NewTimer(0.05, function() self.timer = nil; self:Apply() end)
end

function Drawer:HideTooltip()
    if not GameTooltip or not GameTooltip.IsOwned then return end
    if self.button and GameTooltip:IsOwned(self.button) then GameTooltip:Hide(); return end
    for button in pairs(self.records) do if GameTooltip:IsOwned(button) then GameTooltip:Hide(); return end end
end
function Drawer:StopDrag()
    self.dragging = false
    if self.button then self.button:SetScript("OnUpdate", nil) end
end
function Drawer:CanToggle()
    if not Movable(self.panel) then return false end
    -- A collected addon can later become protected. Do not show/hide its ancestor in combat.
    for button in pairs(self.records) do
        if not Available(button) or type(button.GetParent) ~= "function" then return false end
        local parent = button:GetParent()
        if not Suite.IsReadable(parent) or (parent == self.panel and not Movable(button)) then return false end
    end
    return true
end
function Drawer:Close()
    if self.clickTimer then self.clickTimer:Cancel(); self.clickTimer = nil end
    if InCombatLockdown() and self.panel and not self:CanToggle() then
        Suite.AfterCombat("minimapDrawerClose", function() self:Close() end)
        return
    end
    Suite.pending.minimapDrawerClose = nil
    self:HideTooltip()
    if self.panel then
        local changing = self.changing; self.changing = true
        self.panel:Hide(); self.changing = changing
    end
end
function Drawer:Toggle()
    if not Suite.db.minimapDrawer then return end
    if InCombatLockdown() and (not self.prepared or not self:CanToggle()) then return end
    if Shown(self.panel) then self:Close(); return end
    -- In combat use the existing collection and layout, without discovery, reparenting or scaling.
    if not InCombatLockdown() then self:Apply() end
    if self.panel then self.changing = true; self.panel:Show(); self.changing = false end
end
function Drawer:Drag()
    if InCombatLockdown() or not Suite.db.minimapDrawer then self:StopDrag(); return end
    local angle = Suite.MinimapButton:CursorAngle()
    if angle then Suite.db.minimapDrawerAngle = angle; Suite.db.minimapDrawerMoved = true; self:Position() end
end

function Drawer:Initialize()
    if self.button or InCombatLockdown() or not Available(Minimap) then return end
    local button = CreateFrame("Button", nil, Minimap, "BackdropTemplate")
    self.button = button
    button.ignoreInLayout = true
    button:SetSize(26, 26)
    button:EnableMouse(true)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    button:SetBackdropColor(0.035, 0.05, 0.065, 0.95)
    Suite.Theme:Backdrop(button, 1)
    -- Original grid glyph, drawn with native solid textures.
    for row = 0, 1 do for column = 0, 1 do
        local dot = button:CreateTexture(nil, "ARTWORK")
        dot:SetSize(5, 5); dot:SetPoint("TOPLEFT", 6 + column * 9, -6 - row * 9)
        dot:SetColorTexture(0.41, 0.84, 0.75, 1)
    end end
    button:RegisterForClicks("LeftButtonUp"); button:RegisterForDrag("LeftButton")
    button:SetScript("OnMouseDown", function() self.suppressClick = false end)
    button:SetScript("OnClick", function()
        if self.suppressClick then self.suppressClick = false; return end
        self:Toggle()
    end)
    button:SetScript("OnDragStart", function()
        self.suppressClick = true; self:Close()
        if InCombatLockdown() or not Suite.db.minimapDrawer then return end
        self.dragging = true; self:Drag()
        if self.dragging then button:SetScript("OnUpdate", function() self:Drag() end) end
    end)
    button:SetScript("OnDragStop", function() self:StopDrag() end)
    button:SetScript("OnHide", function() self:StopDrag(); self:Close() end)
    button:SetScript("OnEnter", function()
        if not GameTooltip or self.dragging or not Suite.db.minimapDrawer then return end
        GameTooltip:SetOwner(button, "ANCHOR_LEFT")
        GameTooltip:AddLine("Addon button drawer", 0.41, 0.84, 0.75)
        GameTooltip:AddLine(InCombatLockdown() and "Click to open. Move after combat." or "Click to open. Drag to move around the map.", 0.85, 0.9, 0.92)
        GameTooltip:AddLine("Escape or click outside to close.", 0.55, 0.65, 0.7)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip:IsOwned(button) then GameTooltip:Hide() end
    end)
    -- Named only for Blizzard's Escape dispatcher; all behavior stays in the namespace.
    local panel = CreateFrame("Frame", "WoWForeverSuiteMinimapDrawer", UIParent, "BackdropTemplate")
    self.panel = panel
    panel:SetFrameStrata("DIALOG"); panel:SetFrameLevel(100)
    panel:SetClampedToScreen(true); panel:EnableMouse(true)
    panel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    panel:SetBackdropColor(0.035, 0.05, 0.065, 0.95); Suite.Theme:Backdrop(panel, 0.85)
    self.empty = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.empty:SetPoint("CENTER"); self.empty:SetText("No addon buttons")
    panel:SetScript("OnShow", function()
        if GetMouseFoci and DoesAncestryIncludeAny then panel:RegisterEvent("GLOBAL_MOUSE_DOWN") end
    end)
    panel:SetScript("OnHide", function() panel:UnregisterEvent("GLOBAL_MOUSE_DOWN"); self:HideTooltip() end)
    panel:SetScript("OnEvent", function()
        local foci = GetMouseFoci()
        if not Read(foci, "table") then return end
        for _, focus in ipairs(foci) do if not Suite.IsReadable(focus) then return end end
        local inside = DoesAncestryIncludeAny(panel, foci)
        local launcher = DoesAncestryIncludeAny(button, foci)
        if Read(inside, "boolean") and Read(launcher, "boolean") and not inside and not launcher then self:Close() end
    end)
    if UISpecialFrames then table.insert(UISpecialFrames, "WoWForeverSuiteMinimapDrawer") end
    panel:Hide(); button:Hide()
    self.events = CreateFrame("Frame")
    self.events:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            self:StopDrag()
            if self.timer then self.timer:Cancel(); self.timer = nil end
            Suite.AfterCombat("minimapDrawer", function() self:Apply() end)
        else self:Schedule() end
    end)
    Minimap:HookScript("OnSizeChanged", function() self:Schedule() end)
end

function Drawer:Apply()
    if self.timer then self.timer:Cancel(); self.timer = nil end
    if not Suite.db.minimapDrawer then
        self:StopDrag(); self:Close()
        self.prepared = nil
        if self.events then self.events:UnregisterAllEvents() end
        if not self.button and not next(self.records) then Suite.pending.minimapDrawer = nil; return end
    end
    Suite.AfterCombat("minimapDrawer", function()
        if Suite.db.minimapDrawer then
            self:Initialize()
            if not self.button then return end
            for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "CVAR_UPDATE", "DISPLAY_SIZE_CHANGED", "PLAYER_REGEN_DISABLED" }) do
                self.events:RegisterEvent(event)
            end
            self:Refresh(); self.button:Show()
        else
            self.changing = true
            for button, record in pairs(self.records) do
                if self:Restore(button, record, true) then self.records[button] = nil end
            end
            if self.button then self.button:Hide() end
            self.changing = false
        end
    end)
end
