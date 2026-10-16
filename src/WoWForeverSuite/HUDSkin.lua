local _, Suite = ...
local Skin = { properties = {}, panels = {}, watched = {} }
Suite.HUDSkin = Skin
table.insert(Suite.modules, Skin)

local function Read(value, kind) return Suite.IsReadable(value) and type(value) == kind end
local function Channel(value) return Read(value, "number") and value == value and value >= 0 and value <= 1 end
local function Positive(value) return Read(value, "number") and value == value and value > 0 and value < math.huge end
local function ButtonPixel(parent)
    if type(GetPhysicalScreenSize) ~= "function" or type(parent.GetEffectiveScale) ~= "function" then return end
    local _, height = GetPhysicalScreenSize()
    local scale = parent:GetEffectiveScale()
    if not Positive(height) or not Positive(scale) then return end
    local pixel = 768 / height / scale
    if Positive(pixel) then return pixel end
end
local function Enabled(key) return Suite.db and Read(Suite.db[key], "boolean") and Suite.db[key] end
local function AnyEnabled() return Enabled("statusBarSkin") or Enabled("bagBarSkin") or Enabled("microBarSkin") end
local function Usable(object)
    if not Suite.IsReadable(object) or (type(object) ~= "table" and type(object) ~= "userdata") then return false end
    if type(object.IsForbidden) == "function" then
        local forbidden = object:IsForbidden()
        if not Read(forbidden, "boolean") or forbidden then return false end
    end
    return true
end
local function Anchorable(object)
    if not Usable(object) then return false end
    if type(object.IsAnchoringRestricted) == "function" then
        local restricted = object:IsAnchoringRestricted()
        if not Read(restricted, "boolean") or restricted then return false end
    end
    return true
end
local function Unprotected(object)
    if not Usable(object) or type(object.IsProtected) ~= "function" then return false end
    local protected = object:IsProtected()
    return Read(protected, "boolean") and not protected
end
local function TextPreference(value)
    return Read(value, "string") and (value == "0" or value == "1") and value or nil
end
local function NativeTextPreference()
    if not Read(C_CVar, "table") or type(C_CVar.GetCVarInfo) ~= "function"
        or type(C_CVar.SetCVar) ~= "function" then return end
    local value, _, _, _, locked, secure, readOnly = C_CVar.GetCVarInfo("xpBarText")
    -- SetCVar requires a public, writable, nonsecure setting. Never infer permission from its name.
    if not TextPreference(value) or not Read(locked, "boolean") or locked
        or not Read(secure, "boolean") or secure or not Read(readOnly, "boolean") or readOnly then return end
    return value
end
function Skin:ValuesSetting()
    if not Suite.db or self.writingValues then return end
    local enabled = not self.loggingOut and Enabled("statusBarSkin") and Enabled("progressBarValues")
    local saved = TextPreference(Suite.db.progressBarTextRestore)
    if not enabled and not saved then return end
    local current = NativeTextPreference()
    if not current then return end
    if self.valuesCVar ~= C_CVar then
        if InCombatLockdown() or type(hooksecurefunc) ~= "function" then return end
        self.valuesCVar = C_CVar
        local function Observe(name, value)
            if self.loggingOut or self.writingValues or not Read(name, "string") or name:lower() ~= "xpbartext"
                or not Suite.db or (not (Enabled("statusBarSkin") and Enabled("progressBarValues"))
                    and not TextPreference(Suite.db.progressBarTextRestore)) then return end
            -- Keep the caller's request, rather than our correction from a nested native setter.
            local requested = TextPreference(value)
            if Read(value, "boolean") then requested = value and "1" or "0"
            elseif Read(value, "number") and (value == 0 or value == 1) then requested = tostring(value) end
            Suite.db.progressBarTextRestore = NativeTextPreference() and requested or nil
            if AnyEnabled() then self:Queue() else self:Apply() end
        end
        hooksecurefunc(C_CVar, "SetCVar", Observe)
        -- The legacy alias is still used by native settings helpers and other addons.
        if type(SetCVar) == "function" then hooksecurefunc("SetCVar", Observe) end
    end
    if enabled then
        if not saved then Suite.db.progressBarTextRestore = current end
    elseif current ~= "1" or current == saved then
        -- Already restored, or another owner changed the native preference while we were inactive.
        Suite.db.progressBarTextRestore = nil
        return
    end
    local desired = enabled and "1" or saved
    if current ~= desired then
        self.writingValues = true
        local success = C_CVar.SetCVar("xpBarText", desired)
        self.writingValues = nil
        if not Read(success, "boolean") or not success or NativeTextPreference() ~= desired then return end
    end
    if not enabled then Suite.db.progressBarTextRestore = nil end
end
function Skin:Options(db)
    db = db or Suite.db or {}
    local function Dimension(value, minimum, maximum, fallback)
        if not Positive(value) then return fallback end
        return math.max(minimum, math.min(maximum, math.floor(value + 0.5)))
    end
    return Dimension(db.progressBarWidth, 120, 1600, 600), Dimension(db.progressBarHeight, 6, 40, 14)
end
local function Snapshot(object, kind)
    local get = kind == "Shown" and "IsShown" or "Get" .. kind
    if not Usable(object) or type(object[get]) ~= "function"
        or type(object["Set" .. kind]) ~= "function" then return end
    local values = { object[get](object) }
    if #values ~= (kind == "VertexColor" and 4 or kind == "Size" and 2 or 1) then return end
    for _, value in ipairs(values) do
        if kind == "Shown" then
            if not Read(value, "boolean") then return end
        elseif kind == "Size" or kind == "Height" then
            if not Positive(value) then return end
        elseif not Channel(value) then return end
    end
    return values
end
local function Same(left, right)
    for index, value in ipairs(left) do if value ~= right[index] then return false end end
    return true
end
local function Remember(record, current)
    if not current then record.saved = nil; return end
    if record.saved and record.applied and (record.kind == "Size" or record.kind == "Height") then
        -- Native layout can reuse an overridden axis. Preserve its original size until that axis actually changes.
        for index, value in ipairs(current) do if value ~= record.applied[index] then record.saved[index] = value end end
    else record.saved = current end
end
local function Write(record, values)
    record.writing = true
    record.object["Set" .. record.kind](record.object, unpack(values))
    record.writing = nil
end
local function Restore(record)
    if not record.active then return end
    record.active = nil
    if record.saved and Usable(record.object) and type(record.object["Set" .. record.kind]) == "function"
        and ((record.kind ~= "Size" and record.kind ~= "Height") or Anchorable(record.object)) then
        Write(record, record.saved)
        if record.kind == "Size" then Skin:Resize(record.object) end
    end
    record.saved, record.applied = nil, nil
end
function Skin:Property(object, kind, key, pass, desired)
    local current = Snapshot(object, kind)
    local record = Usable(object) and self.properties[object]
    if not current then
        if record then record.saved = nil end
        return false
    end
    if type(hooksecurefunc) ~= "function" then return false end
    if not record then
        record = { object = object, kind = kind }
        self.properties[object] = record
        local function Observe()
            if record.writing then return end
            -- An unreadable native update invalidates the snapshot instead of replaying an older value.
            if record.active then Remember(record, Snapshot(object, kind)) end
            if Enabled(key) then self:Queue() end
        end
        if kind == "Shown" then
            local function ObserveShown(value)
                if record.writing then return end
                -- Capture the native request explicitly: nested Hide/SetShown hooks can otherwise
                -- mistake our immediate combat Show for the owner's intended visibility.
                if record.active then
                    Remember(record, Read(value, "boolean") and Snapshot(object, kind) and { value } or nil)
                end
                if Enabled(key) then self:Queue() end
            end
            hooksecurefunc(object, "SetShown", function(_, value) ObserveShown(value) end)
            if type(object.Show) == "function" then hooksecurefunc(object, "Show", function() ObserveShown(true) end) end
            if type(object.Hide) == "function" then hooksecurefunc(object, "Hide", function() ObserveShown(false) end) end
        else hooksecurefunc(object, "Set" .. kind, Observe) end
        for _, method in ipairs(kind == "Size" and { "SetWidth", "SetHeight" } or {}) do
            if type(object[method]) == "function" then
                hooksecurefunc(object, method, Observe)
            end
        end
    end
    if not record.active then record.saved = current
    elseif not Same(current, record.applied) then Remember(record, current) end
    if not record.saved then return false end
    record.active, record.seen = true, pass
    local changed = not Same(current, desired)
    if changed then Write(record, desired) end
    record.applied = desired
    return true, changed
end
function Skin:CombatValues()
    -- Only visibility of previously prepared, readable, unprotected native labels is allowed here.
    -- Never discover/create widgets, install hooks, resize, or invoke native formatters in combat.
    for object, record in pairs(self.properties) do
        local bar = record.progressBar
        if record.kind == "Shown" and Unprotected(bar) and Unprotected(bar.OverlayFrame)
            and Unprotected(object) and Suite.IsReadable(bar.OverlayFrame.Text) and bar.OverlayFrame.Text == object then
            local current = Snapshot(object, "Shown")
            if not current then record.saved = nil
            elseif Enabled("statusBarSkin") and Enabled("progressBarValues") then
                if not record.active then record.saved = current; record.active = true end
                if record.saved then
                    local desired = { true }
                    if not Same(current, desired) then Write(record, desired) end
                    record.applied = desired
                end
            else Restore(record) end
        end
    end
end
function Skin:Suppress(object, kind, key, pass)
    return self:Property(object, kind, key, pass, kind == "Alpha" and { 0 } or { 1, 1, 1, 0 })
end
function Skin:Watch(object, key, methods)
    if not Usable(object) or self.watched[object] or type(hooksecurefunc) ~= "function" then return end
    self.watched[object] = true
    local function Queue() if not self.sizing and Enabled(key) then self:Queue() end end
    if type(object.HookScript) == "function" then
        object:HookScript("OnShow", Queue)
        object:HookScript("OnHide", Queue)
    end
    for _, method in ipairs(methods or {}) do
        if type(object[method]) == "function" then hooksecurefunc(object, method, Queue) end
    end
end
function Skin:Resize(container, checkOnly)
    local adjustment = STATUS_BAR_SIZE_ADJUSTMENT
    if not Anchorable(container) or not Read(container.bars, "table") or type(container.ResizeContainerBars) ~= "function"
        or type(container.GetWidth) ~= "function" or type(container.GetHeight) ~= "function"
        or not Positive(adjustment) or adjustment > 16 then return false end
    local width, height = container:GetWidth(), container:GetHeight()
    if not Positive(width) or not Positive(height) or width <= adjustment or height <= adjustment then return false end
    local bars = {}
    for index = 1, 33 do
        local bar = container.bars[index]
        if not Suite.IsReadable(bar) then return false end
        if bar == nil then break end
        if index > 32 or not Anchorable(bar) or not Anchorable(bar.StatusBar)
            or type(bar.SetSize) ~= "function" or type(bar.StatusBar.SetSize) ~= "function" then return false end
        bars[#bars + 1] = bar
    end
    if checkOnly then return true end
    self.sizing = true
    container:ResizeContainerBars()
    for _, bar in ipairs(bars) do
        if Usable(bar.ExhaustionTick) and type(bar.UpdateTick) == "function" and type(bar.IsShown) == "function" then
            local shown = bar:IsShown()
            if Read(shown, "boolean") and shown then bar:UpdateTick() end
        end
    end
    self.sizing = nil
    return true
end
function Skin:Dimensions(container, pass)
    local adjustment = STATUS_BAR_SIZE_ADJUSTMENT
    if not Enabled("progressBarCustomSize") or not self:Resize(container, true) then return false end
    local width, height = self:Options()
    local success, changed = self:Property(container, "Size", "statusBarSkin", pass, { width + adjustment, height + adjustment })
    if success and changed then self:Resize(container) end
    return success
end
function Skin:Progress(bar, pass, customSize)
    if Enabled("progressBarValues") and Usable(bar.OverlayFrame) then
        local success, changed = self:Property(bar.OverlayFrame.Text, "Shown", "statusBarSkin", pass, { true })
        if success then self.properties[bar.OverlayFrame.Text].progressBar = bar end
        -- Honor initially fills its label on hover; use its existing formatter without reading/formatting values here.
        if success and changed and type(bar.UpdateOverlayFrameText) == "function" and type(bar.IsShown) == "function" then
            local shown = bar:IsShown()
            if Read(shown, "boolean") and shown then bar:UpdateOverlayFrameText() end
        end
    end
    if customSize and Anchorable(bar.ExhaustionLevelFillBar) then
        local _, height = self:Options()
        self:Property(bar.ExhaustionLevelFillBar, "Height", "statusBarSkin", pass, { height })
    end
    local panel = self.panels[bar.StatusBar]
    if not panel then return end
    local width = type(bar.StatusBar.GetWidth) == "function" and bar.StatusBar:GetWidth()
    if Enabled("progressBarSegments") and Positive(width) then
        if not panel.segments then
            panel.segments = {}
            for index = 1, 9 do
                local line = bar.StatusBar:CreateTexture(nil, "OVERLAY", nil, 6)
                line:SetWidth(1); line:SetColorTexture(0.41, 0.84, 0.75, 0.35)
                panel.segments[index] = line
            end
        end
        if panel.segmentWidth ~= width then
            panel.segmentWidth = width
            for index, line in ipairs(panel.segments) do
                line:ClearAllPoints()
                line:SetPoint("TOPLEFT", bar.StatusBar, "TOPLEFT", width * index / 10, -1)
                line:SetPoint("BOTTOMLEFT", bar.StatusBar, "BOTTOMLEFT", width * index / 10, 1)
            end
        end
        for _, line in ipairs(panel.segments) do line:Show() end
    elseif panel.segments then
        for _, line in ipairs(panel.segments) do line:Hide() end
    end
end
function Skin:Paint(record)
    if InCombatLockdown() or not record.active or not Enabled(record.key) or not Usable(record.parent) then return end
    local pressed = record.pressed
    if type(record.parent.GetButtonState) == "function" then
        local state = record.parent:GetButtonState()
        pressed = Read(state, "string") and state == "PUSHED"
    end
    local highlighted = record.hovered or pressed
    record.background:SetColorTexture(pressed and 0.10 or highlighted and 0.07 or 0.035,
        pressed and 0.23 or highlighted and 0.15 or 0.05,
        pressed and 0.21 or highlighted and 0.15 or 0.065, 0.95)
    for _, edge in ipairs(record.edges) do edge:SetColorTexture(0.41, 0.84, 0.75, highlighted and 1 or 0.55) end
end
function Skin:Panel(parent, key, pass, button, backgroundParent)
    if not Anchorable(parent) or type(parent.CreateTexture) ~= "function" then return end
    local record = self.panels[parent]
    if not record then
        record = { parent = parent, key = key, edges = {}, textures = {} }
        self.panels[parent] = record
        local inset = key == "microBarSkin" and 3 or 0
        local function Texture(layer, level, owner)
            local texture = (owner or parent):CreateTexture(nil, layer, nil, level)
            if button then
                -- Round only Suite artwork; native bars keep their Edit Mode geometry and rendering preferences.
                if type(texture.SetRoundLayoutToNearestPixel) == "function" then texture:SetRoundLayoutToNearestPixel(true) end
                if type(texture.SetSnapToPixelGrid) == "function" then texture:SetSnapToPixelGrid(false) end
                if type(texture.SetTexelSnappingBias) == "function" then texture:SetTexelSnappingBias(0) end
            end
            record.textures[#record.textures + 1] = texture
            return texture
        end
        -- XP prediction belongs to the bar wrapper. A backdrop on its higher-level
        -- StatusBar child covers that native texture even on the BACKGROUND layer.
        record.background = Texture("BACKGROUND", -7, backgroundParent)
        record.background:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -inset)
        record.background:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset, inset)
        record.background:SetColorTexture(0.035, 0.05, 0.065, 0.95)
        for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
            local edge = Texture("OVERLAY", 7)
            if side == "TOP" or side == "BOTTOM" then
                local y = side == "TOP" and -inset or inset
                edge:SetHeight(1)
                edge:SetPoint(side .. "LEFT", parent, side .. "LEFT", inset, y)
                edge:SetPoint(side .. "RIGHT", parent, side .. "RIGHT", -inset, y)
            else
                local x = side == "LEFT" and inset or -inset
                edge:SetWidth(1)
                edge:SetPoint("TOP" .. side, parent, "TOP" .. side, x, -inset)
                edge:SetPoint("BOTTOM" .. side, parent, "BOTTOM" .. side, x, inset)
            end
            edge:SetColorTexture(0.41, 0.84, 0.75, 0.55)
            record.edges[#record.edges + 1] = edge
        end
        if button then
            local function Paint() self:Paint(record) end
            parent:HookScript("OnEnter", function() record.hovered = true; Paint() end)
            parent:HookScript("OnLeave", function() record.hovered, record.pressed = nil, nil; Paint() end)
            parent:HookScript("OnMouseDown", function(_, mouseButton)
                if Read(mouseButton, "string") and mouseButton == "LeftButton" then record.pressed = true; Paint() end
            end)
            parent:HookScript("OnMouseUp", function() record.pressed = nil; Paint() end)
            parent:HookScript("OnHide", function() record.hovered, record.pressed = nil, nil end)
            if type(parent.SetButtonState) == "function" then hooksecurefunc(parent, "SetButtonState", Paint) end
        end
    end
    if button then
        local pixel = ButtonPixel(parent)
        if pixel and record.pixel ~= pixel then
            record.pixel = pixel
            for index, edge in ipairs(record.edges) do
                if index <= 2 then edge:SetHeight(pixel) else edge:SetWidth(pixel) end
            end
        end
    end
    record.active, record.seen = true, pass
    for _, texture in ipairs(record.textures) do texture:Show() end
    if button then
        if type(parent.IsMouseOver) == "function" then
            local hovered = parent:IsMouseOver()
            record.hovered = Read(hovered, "boolean") and hovered or nil
        end
        self:Paint(record)
    end
end
function Skin:Dividers(owner, key, pass, status)
    for _, name in ipairs(status and { "HorizontalDividersPool" } or { "HorizontalDividersPool", "VerticalDividersPool" }) do
        local pool = owner[name]
        if Read(pool, "table") and type(pool.EnumerateActive) == "function" then
            local count = 0
            for divider in pool:EnumerateActive() do
                count = count + 1
                if count > 64 then break end
                if Usable(divider) then
                    self:Suppress(status and divider.BarDividerTexture or divider,
                        status and "VertexColor" or "Alpha", key, pass)
                end
            end
        end
    end
end
function Skin:StatusBars(pass)
    local manager, info = StatusTrackingBarManager, StatusTrackingBarInfo
    if not Usable(manager) or not Read(manager.barContainers, "table")
        or not Read(info, "table") or not Read(info.BarsEnum, "table") then return end
    self:Watch(manager, "statusBarSkin", { "UpdateBarsShown", "CheckForLayoutChange" })
    for index = 1, 4 do
        local container = manager.barContainers[index]
        if Usable(container) and Read(container.bars, "table") then
            self:Watch(container, "statusBarSkin", { "UpdateDividers", "ApplyPendingBarToShow", "ResizeContainerBars" })
            local shown = type(container.GetShownBar) == "function" and container:GetShownBar()
            local skinnedShown, styled = false, {}
            for _, name in ipairs({ "Experience", "Honor", "Reputation" }) do
                local barIndex = info.BarsEnum[name]
                if Read(barIndex, "number") and barIndex >= 1 and barIndex <= 32 and barIndex % 1 == 0 then
                    local bar = container.bars[barIndex]
                    if Anchorable(bar) and type(bar.CreateTexture) == "function"
                        and Anchorable(bar.StatusBar) and type(bar.StatusBar.CreateTexture) == "function" then
                        self:Watch(bar, "statusBarSkin")
                        if self:Suppress(bar.StatusBar.Background, "VertexColor", "statusBarSkin", pass) then
                            -- Native fill atlases, values, rested prediction, text and gain animations remain native.
                            self:Panel(bar.StatusBar, "statusBarSkin", pass, false, bar)
                            styled[#styled + 1] = bar
                            if Suite.IsReadable(shown) and bar == shown then skinnedShown = true end
                        end
                    end
                end
            end
            local customSize = skinnedShown and self:Dimensions(container, pass)
            -- Restore native size before placing dividers, including when this slot switches to another bar type.
            if not customSize and self.properties[container] then Restore(self.properties[container]) end
            for _, bar in ipairs(styled) do self:Progress(bar, pass, customSize) end
            if skinnedShown then
                self:Suppress(container.BarFrameTexture, "VertexColor", "statusBarSkin", pass)
                self:Dividers(container, "statusBarSkin", pass, true)
            end
        end
    end
end
function Skin:Button(button, key, pass)
    if not Anchorable(button) or type(button.CreateTexture) ~= "function" or type(button.HookScript) ~= "function" then return end
    self:Watch(button, key, { "UpdateTextures", "SetScale" })
    local artwork = {}
    if key == "microBarSkin" then
        artwork = { button.Background, button.PushedBackground }
        if #artwork ~= 2 then return end
    else
        if not Usable(button.icon) then return end
        for _, kind in ipairs({ "Normal", "Pushed", "Highlight" }) do
            local get = button["Get" .. kind .. "Texture"]
            if type(get) ~= "function" then return end
            local texture = get(button)
            if not Usable(texture) then return end
            artwork[#artwork + 1] = texture
        end
    end
    -- Preflight the entire button so partial/restricted templates keep their original artwork.
    for _, texture in ipairs(artwork) do
        local record = self.properties[texture]
        if not Snapshot(texture, "VertexColor") then
            if record then record.saved = nil end
            return
        end
        if record and record.active and not record.saved then return end
    end
    for _, texture in ipairs(artwork) do
        if not self:Suppress(texture, "VertexColor", key, pass) then
            for _, state in ipairs(artwork) do
                local record = self.properties[state]
                if record then record.seen = nil; Restore(record) end
            end
            return
        end
    end
    self:Panel(button, key, pass, true)
end
function Skin:BagBar(pass)
    if not Anchorable(BagsBar) then return end
    self:Watch(BagsBar, "bagBarSkin", { "Layout", "UpdateDividers", "SetScale" })
    self:Suppress(BagsBar.BorderArt, "VertexColor", "bagBarSkin", pass)
    self:Dividers(BagsBar, "bagBarSkin", pass)
    for _, name in ipairs({ "MainMenuBarBackpackButton", "CharacterBag0Slot", "CharacterBag1Slot", "CharacterBag2Slot",
        "CharacterBag3Slot", "CharacterReagentBag0Slot", "KeyRingButton" }) do
        self:Button(_G[name], "bagBarSkin", pass)
    end
end
function Skin:MicroBar(pass)
    if not Anchorable(MicroMenu) or type(MicroMenu.GetChildren) ~= "function" then return end
    self:Watch(MicroMenu, "microBarSkin", { "AddButton", "Layout", "SetScale" })
    self:Suppress(MicroMenu.BorderArt, "VertexColor", "microBarSkin", pass)
    self:Suppress(MicroMenu.BackgroundArt, "VertexColor", "microBarSkin", pass)
    local children = { MicroMenu:GetChildren() }
    for index = 1, math.min(#children, 32) do
        local button = children[index]
        if Usable(button) and Usable(button.Background) and Usable(button.PushedBackground) then
            self:Button(button, "microBarSkin", pass)
        end
    end
end
function Skin:Finish(pass)
    for _, record in pairs(self.panels) do
        if record.seen ~= pass then
            record.active, record.hovered, record.pressed = nil, nil, nil
            for _, texture in ipairs(record.textures) do if Usable(texture) then texture:Hide() end end
            for _, texture in ipairs(record.segments or {}) do if Usable(texture) then texture:Hide() end end
        end
    end
    for _, record in pairs(self.properties) do if record.seen ~= pass then Restore(record) end end
end
function Skin:Cancel()
    self.work = nil
    if self.timer then self.timer:Cancel(); self.timer = nil end
end
function Skin:Refresh()
    self:Cancel()
    -- Blizzard's native rule continues to show and update text even when addon frame writes must wait.
    self:ValuesSetting()
    if InCombatLockdown() then
        self:CombatValues()
        Suite.AfterCombat("hudSkin", function() self:Apply() end)
        return
    end
    local pass = {}
    if Enabled("statusBarSkin") then self:StatusBars(pass) end
    if Enabled("bagBarSkin") then self:BagBar(pass) end
    if Enabled("microBarSkin") then self:MicroBar(pass) end
    self:Finish(pass)
end
function Skin:Queue()
    if self.loggingOut or not AnyEnabled() then return end
    if InCombatLockdown() then self:Refresh(); return end
    if self.timer then return end
    if not C_Timer or type(C_Timer.NewTimer) ~= "function" then self:Refresh(); return end
    local work = {}; self.work = work
    self.timer = C_Timer.NewTimer(0.05, function()
        if self.work ~= work then return end
        self.timer, self.work = nil, nil
        self:Refresh()
    end)
end
function Skin:Apply()
    self:Cancel()
    self:ValuesSetting()
    Suite.pending.hudSkin = nil
    if self.events then self.events:UnregisterAllEvents() end
    if InCombatLockdown() then self:CombatValues() end
    if not AnyEnabled() and not next(self.properties) and not TextPreference(Suite.db.progressBarTextRestore) then return end
    Suite.AfterCombat("hudSkin", function()
        if AnyEnabled() or TextPreference(Suite.db.progressBarTextRestore) then
            if not self.events then
                self.events = CreateFrame("Frame")
                self.events:SetScript("OnEvent", function(_, event)
                    if event == "PLAYER_LOGOUT" then
                        self.loggingOut = true
                        self:Cancel()
                        self:ValuesSetting()
                    else self:Queue() end
                end)
            end
            self.events:RegisterEvent("PLAYER_LOGOUT")
            if AnyEnabled() then
                for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED" }) do self.events:RegisterEvent(event) end
            end
            if Enabled("bagBarSkin") or Enabled("microBarSkin") then
                self.events:RegisterEvent("UI_SCALE_CHANGED")
                self.events:RegisterEvent("DISPLAY_SIZE_CHANGED")
            end
        end
        self:Refresh()
    end)
end
