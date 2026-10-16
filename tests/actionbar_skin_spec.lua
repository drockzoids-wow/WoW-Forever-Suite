local Suite, equal, Frame, SetCombat = ...
local skin = Suite.ActionBarSkin
local oldCreate, oldTimer, oldHook, oldPending = CreateFrame, C_Timer, hooksecurefunc, Suite.pending
local oldSkin, oldRange, oldBar, oldSet = Suite.db.actionBarSkin, Suite.db.fullButtonRange, MainActionBar, Suite.Set
local names = { "ActionButton1", "MultiBar7Button12", "PetActionButton1", "StanceButton1", "PossessButton2", "OverrideActionBarButton6", "ExtraActionButton1", "ActionButton2", "ActionButton3" }
local previous = {}
for _, name in ipairs(names) do previous[name] = _G[name]; _G[name] = nil end
local combat, nativeGeometry, constructions, hooks, geometryWrites, textures = false, false, 0, 0, 0, 0
local timers = {}
local secret = { secret = true }
local cooldownRoles = { "cooldown", "chargeCooldown", "lossOfControlCooldown" }
local function Combat(value) combat = value; SetCombat(value) end
local function GuardGeometry()
    assert(not combat or nativeGeometry, "Suite skin must not change geometry or masks in combat")
    if not nativeGeometry then geometryWrites = geometryWrites + 1 end
end
local function Region(parent)
    local region = Frame()
    region.parent, region.width, region.height = parent, 45, 45
    region.points = { { "TOPLEFT", parent, "TOPLEFT", 0, 0 }, { "BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0 } }
    region.alpha, region.blend, region.coords = 1, "ADD", { 0.1, 0.2, 0.1, 0.8, 0.9, 0.2, 0.9, 0.8 }
    -- Native textures share opacity between SetAlpha and the fourth vertex-color channel.
    region.GetAlpha = function(self) return self.vertex[4] end
    region.SetAlpha = function(self, value) self.alpha, self.vertex[4] = value, value end
    region.vertex = { 1, 1, 1, 1 }
    region.GetVertexColor = function(self) return unpack(self.vertex) end
    region.SetVertexColor = function(self, r, g, b, a)
        self.vertex, self.alpha = { r, g, b, a or 1 }, a or 1
    end
    region.IsForbidden = function(self) return self.forbidden or false end
    region.IsAnchoringRestricted = function(self) return self.restricted or false end
    region.GetNumPoints = function(self) return #self.points end
    region.GetPoint = function(self, index) return unpack(self.points[index]) end
    region.ClearAllPoints = function(self) GuardGeometry(); self.points = {} end
    region.SetPoint = function(self, ...) GuardGeometry(); self.points[#self.points + 1] = { ... } end
    region.SetSize = function(self, width, height) GuardGeometry(); self.width, self.height = width, height end
    region.GetAtlas = function(self) return self.atlas end
    region.GetTexture = function(self) return self.texture end
    region.SetAtlas = function(self, value) self.atlas, self.texture, self.solid = value, "atlas:" .. value, nil end
    region.SetTexture = function(self, value) self.texture, self.atlas, self.solid = value, nil, nil end
    region.GetTexCoord = function(self) return unpack(self.coords) end
    region.SetTexCoord = function(self, ...)
        local values = { ... }
        if #values == 4 then values = { values[1], values[3], values[1], values[4], values[2], values[3], values[2], values[4] } end
        self.coords = values
    end
    region.GetBlendMode = function(self) return self.blend end
    region.SetBlendMode = function(self, value) self.blend = value end
    region.SetColorTexture = function(self, ...) self.solid, self.atlas, self.texture = { ... }, nil, nil end
    return region
end
local function Button()
    local button = Frame()
    button.shown, button.bar = true, {}
    button.IsForbidden = function(self) return self.forbidden or false end
    button.icon, button.IconMask = Region(button), Region(button)
    button.icon.masks = { button.IconMask }
    button.icon:SetVertexColor(0.5, 0.5, 1, 0.8)
    button.icon.GetNumMaskTextures = function(self) return #self.masks end
    button.icon.GetMaskTexture = function(self, index) return self.masks[index] end
    button.icon.RemoveMaskTexture = function(self, mask)
        GuardGeometry()
        for index, current in ipairs(self.masks) do if current == mask then table.remove(self.masks, index); return end end
    end
    button.icon.AddMaskTexture = function(self, mask)
        GuardGeometry()
        for _, current in ipairs(self.masks) do assert(current ~= mask, "a restored mask must not be added twice") end
        self.masks[#self.masks + 1] = mask
    end
    for _, role in ipairs({ "NormalTexture", "PushedTexture", "HighlightTexture", "CheckedTexture", "SlotArt", "SlotBackground" }) do
        button[role] = Region(button); button[role]:SetAtlas("original-" .. role)
    end
    button.NormalTexture:SetAlpha(0.8)
    for _, role in ipairs(cooldownRoles) do
        local cooldown = Region(button)
        local padding = role == "chargeCooldown" and 2 or 3
        cooldown.points = { { "TOPLEFT", button.icon, "TOPLEFT", padding, -padding }, { "BOTTOMRIGHT", button.icon, "BOTTOMRIGHT", -padding, padding } }
        cooldown.width, cooldown.height = 45 - padding * 2, 45 - padding * 2
        cooldown.timing, cooldown.swipeColor = secret, role == "lossOfControlCooldown" and { 0.17, 0, 0, 0.64 } or { 0, 0, 0, 0.64 }
        cooldown.drawSwipe, cooldown.drawEdge, cooldown.hideNumbers = role ~= "chargeCooldown", role ~= "cooldown", role ~= "cooldown"
        for _, method in ipairs({ "GetCooldownTimes", "SetCooldown", "Clear", "SetSwipeTexture", "SetSwipeColor", "SetDrawSwipe", "SetDrawEdge", "SetHideCountdownNumbers", "SetParent", "SetScript" }) do
            cooldown[method] = function() error("skin must retain native cooldown timing, artwork, number preferences and ownership") end
        end
        button[role] = cooldown
    end
    button.SpellHighlightTexture, button.Flash, button.AutoCastOverlay, button.Border = Frame(), Frame(), Frame(), Frame()
    button.HotKey, button.Count, button.Name = Frame(), Frame(), Frame()
    button.HotKey.text, button.Count.text, button.Name.text = "1", "12", "Macro"
    button.OnClick = function(self) self.clicked = (self.clicked or 0) + 1 end
    button.OnEnter = function(self) self.nativeEnter = (self.nativeEnter or 0) + 1 end
    button.CreateTexture = function(self)
        assert(not combat, "skin textures must be created outside combat")
        textures = textures + 1
        return Region(self)
    end
    button.UpdateButtonArt = function(self)
        nativeGeometry = true
        local art = self.bar.hideBarArt and "addrow" or "main"
        self.NormalTexture:SetAtlas(art .. "-normal"); self.PushedTexture:SetAtlas(art .. "-pushed")
        self.NormalTexture:SetSize(51, 51); self.PushedTexture:SetSize(51, 51)
        if self.small then
            self.cooldown:ClearAllPoints()
            self.cooldown:SetPoint("TOPLEFT", self.icon, "TOPLEFT", 1.7, -1.7)
            self.cooldown:SetPoint("BOTTOMRIGHT", self.icon, "BOTTOMRIGHT", -1, 1)
        end
        nativeGeometry = false
    end
    for _, method in ipairs({ "SetPoint", "ClearAllPoints", "SetSize", "SetScale", "SetParent", "SetAttribute", "SetScript" }) do
        button[method] = function() error("skin must preserve protected button layout, attributes and scripts") end
    end
    return button
end
CreateFrame = function(...)
    assert(not combat, "skin controller creation waits for combat")
    constructions = constructions + 1
    local frame = oldCreate(...)
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    return frame
end
hooksecurefunc = function(...)
    assert(not combat, "skin hook installation waits for combat")
    hooks = hooks + 1
    return oldHook(...)
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
local function Flush()
    local ready = timers; timers = {}
    for _, timer in ipairs(ready) do if not timer.cancelled then timer.callback() end end
end
local function LeaveCombat()
    Combat(false)
    local pending = Suite.pending; Suite.pending = {}
    for _, callback in pairs(pending) do callback() end
end
local function TimerCount()
    local count = 0; for _, timer in ipairs(timers) do if not timer.cancelled then count = count + 1 end end
    return count
end
Suite.pending = {}
Suite.db.actionBarSkin, Suite.db.fullButtonRange = false, false
Combat(false); skin:Apply()
equal(constructions, 0, "disabled skin constructs nothing")
equal(textures, 0, "disabled skin creates no textures")
equal(hooks, 0, "disabled skin installs no hooks")
equal(TimerCount(), 0, "disabled skin schedules no work")
equal(Suite.InitializeDB(nil).actionBarSkin, false, "skin starts off on a fresh database")
equal(Suite.InitializeDB({ actionBarSkin = true }).actionBarSkin, true, "saved skin preference persists")
for _, name in ipairs(names) do _G[name] = Button() end
PetActionButton1.small = true
ActionButton2.forbidden = true
ActionButton3.icon.coords[1] = secret
MainActionBar = Frame()
MainActionBar.BorderArt = Region(MainActionBar)
MainActionBar.EndCaps = { LeftEndCap = { Texture = Region(MainActionBar) }, RightEndCap = { Texture = Region(MainActionBar) } }
local divider = Region(MainActionBar)
local dividers = { [divider] = true }
MainActionBar.HorizontalDividersPool = { EnumerateActive = function() return next, dividers end }
MainActionBar.UpdateDividers = function(self) self.nativeDividers = (self.nativeDividers or 0) + 1 end
local originalClick = ActionButton1.OnClick
local originalIconPoints, originalStatePoints = ActionButton1.icon.points, ActionButton1.CheckedTexture.points
local originalIconCoords, originalCheckedCoords = ActionButton1.icon.coords, ActionButton1.CheckedTexture.coords
ActionButton1.CheckedTexture:SetVertexColor(0.6, 0.7, 0.8, 0.9)
local cooldown, proc, key = ActionButton1.cooldown, ActionButton1.SpellHighlightTexture, ActionButton1.HotKey
local originalCooldowns = {}
for _, role in ipairs(cooldownRoles) do
    local widget = ActionButton1[role]
    originalCooldowns[role] = { widget = widget, points = widget.points, width = widget.width, height = widget.height, color = widget.swipeColor }
end
local function FitsIcon(button, role)
    local widget = button[role]
    equal(widget.points[1][2], button.icon, role .. " follows the cropped icon")
    equal(widget.points[2][2], button.icon, role .. " follows the opposite icon corner")
    for index = 1, 2 do
        equal(widget.points[index][4], 0, role .. " has no extra horizontal inset")
        equal(widget.points[index][5], 0, role .. " has no extra vertical inset")
    end
end
local function Bounds(region)
    if not region.points then return 0, 0, region.width, region.height end
    local first, last = region.points[1], region.points[2]
    local left, top = Bounds(first[2])
    local _, _, right, bottom = Bounds(last[2])
    return left + first[4], top - first[5], right + last[4], bottom - last[5]
end
Suite.db.actionBarSkin = true
Combat(true); skin:Apply()
equal(constructions, 0, "first combat enable creates no controller")
equal(textures, 0, "first combat enable creates no textures")
equal(hooks, 0, "first combat enable installs no hooks")
Suite.db.actionBarSkin = false; skin:Apply(); LeaveCombat()
equal(textures, 0, "disabled deferred enable cannot skin later")
Suite.db.actionBarSkin = true; skin:Apply()
local function EffectiveAlpha(texture)
    return (texture.solid and texture.solid[4] or 1) * texture:GetAlpha()
end
local function PetState(button, active, attacking)
    -- PetActionButtonMixin:UpdateButtonState writes opacity before the engine's checked flag.
    if active then button.CheckedTexture:SetAlpha(attacking and 0.5 or 1) end
    button:SetChecked(active)
end
PetActionButton1.icon:SetTexture("pet-follow")
PetState(PetActionButton1, true, false)
equal(EffectiveAlpha(PetActionButton1.CheckedTexture), 0.22, "selected pet command cannot become an opaque teal tile")
equal(PetActionButton1.icon:GetTexture(), "pet-follow", "pet state feedback preserves the native command icon")
equal(PetActionButton1.CheckedTexture:GetAlpha(), 1, "selected pet command retains native full state opacity")
PetState(PetActionButton1, true, true)
equal(EffectiveAlpha(PetActionButton1.CheckedTexture), 0.11, "active pet attack keeps the softer native half-opacity feedback")
equal(PetActionButton1.CheckedTexture:GetAlpha(), 0.5, "pet attack retains native half state opacity")
PetState(PetActionButton1, false, false)
equal(PetActionButton1:GetChecked(), false, "native pet deselection still clears the engine state")
equal(constructions, 1, "skin uses one event controller")
equal(skin.events.registered.ADDON_LOADED, true, "skin discovers bars loaded later")
equal(Suite.db.fullButtonRange, false, "skin does not enable range coloring")
equal(ActionButton1.NormalTexture.alpha, 0, "ornate button frame is suppressed")
equal(ActionButton1.SlotArt.alpha, 0, "slot ornament is suppressed")
equal(ActionButton1.SlotBackground.alpha, 0, "native empty-slot background is suppressed")
equal(MainActionBar.BorderArt.alpha, 0, "main bar ornament is suppressed")
equal(MainActionBar.EndCaps.LeftEndCap.Texture.alpha, 0, "left ornamental cap is suppressed")
equal(MainActionBar.EndCaps.RightEndCap.Texture.alpha, 0, "right ornamental cap is suppressed")
equal(divider.alpha, 0, "native divider remains managed but visually suppressed")
equal(#ActionButton1.icon.masks, 0, "only the original icon mask is removed for a square icon")
equal(ActionButton1.icon.points[1][4], 3, "icon is inset within its original button")
equal(ActionButton1.icon.coords[1], 0.06, "icon edge is cropped")
equal(ActionButton1.icon.vertex[3], 1, "skin leaves native mana tint intact")
equal(ActionButton1.icon.vertex[4], 0.8, "skin leaves native icon alpha intact")
equal(ActionButton1.CheckedTexture.solid[2], 0.84, "engine-managed checked fill uses Suite teal")
equal(ActionButton1.CheckedTexture:GetAlpha(), 0.9, "initial styling retains the original native state opacity")
equal(ActionButton1.PushedTexture.solid[4], 0.35, "engine-managed press retains visible feedback")
equal(ActionButton1.HighlightTexture.blend, "BLEND", "hover fill stays subdued")
equal(ActionButton1.cooldown, cooldown, "native cooldown widget is preserved")
for _, role in ipairs(cooldownRoles) do
    FitsIcon(ActionButton1, role)
    equal(ActionButton1[role], originalCooldowns[role].widget, role .. " retains the native widget")
    equal(ActionButton1[role].timing, secret, role .. " leaves restricted native timing untouched")
    equal(ActionButton1[role].swipeColor, originalCooldowns[role].color, role .. " retains native swipe colors")
    equal(ActionButton1[role].drawSwipe, role ~= "chargeCooldown", role .. " retains native swipe visibility")
    equal(ActionButton1[role].drawEdge, role ~= "cooldown", role .. " retains native edge visibility")
    equal(ActionButton1[role].hideNumbers, role ~= "cooldown", role .. " retains native number visibility")
end
equal(ActionButton1.SpellHighlightTexture, proc, "native proc widget is preserved")
equal(ActionButton1.HotKey, key, "native hotkey widget is preserved")
equal(ActionButton1.HotKey.text, "1", "native binding text is preserved")
equal(ActionButton1.Count.text, "12", "native count is preserved")
equal(ActionButton1.Name.text, "Macro", "native macro text is preserved")
equal(ActionButton1.OnClick, originalClick, "secure click script is preserved")
ActionButton1:OnClick()
equal(ActionButton1.clicked, 1, "native action click still runs")
for _, name in ipairs({ "MultiBar7Button12", "PetActionButton1", "StanceButton1", "PossessButton2", "OverrideActionBarButton6", "ExtraActionButton1" }) do
    equal(skin.buttons[_G[name]].active, true, name .. " gets the same optional skin")
    for _, role in ipairs(cooldownRoles) do FitsIcon(_G[name], role) end
end
for _, size in ipairs({ 32, 45, 64 }) do
    ActionButton1.width, ActionButton1.height = size, size
    for _, scale in ipairs({ 0.7, 1, 1.4 }) do
        local left, top, right, bottom = Bounds(ActionButton1.icon)
        for _, role in ipairs(cooldownRoles) do
            local x1, y1, x2, y2 = Bounds(ActionButton1[role])
            equal((x2 - x1) * scale, (right - left) * scale, role .. " covers the icon width at native size/scale")
            equal((y2 - y1) * scale, (bottom - top) * scale, role .. " covers the icon height at native size/scale")
        end
    end
end
ActionButton1.width, ActionButton1.height = 45, 45
for _, change in ipairs({
    function(button) button.cooldown = secret end,
    function(button) button.cooldown.forbidden = true end,
    function(button) button.cooldown.restricted = true end,
    function(button) button.cooldown.restricted = secret end,
    function(button) button.cooldown.width = secret end,
    function(button) button.chargeCooldown.height = 0 end,
    function(button) button.chargeCooldown.GetPoint = nil end,
    function(button) button.lossOfControlCooldown.points[1][2] = secret end,
    function(button) button.lossOfControlCooldown.points[2][5] = secret end,
}) do
    local button = Button(); change(button); skin:Track(button)
    equal(skin.buttons[button], nil, "unavailable cooldown restoration data leaves the whole button native")
    equal(button.NormalTexture.alpha, 0.8, "rejected cooldown snapshot preserves native button art")
    equal(#button.icon.masks, 1, "rejected cooldown snapshot preserves the native icon mask")
end
local singleCooldown = Button()
singleCooldown.chargeCooldown, singleCooldown.lossOfControlCooldown = nil, nil
skin:Track(singleCooldown); FitsIcon(singleCooldown, "cooldown")
equal(#skin.buttons[singleCooldown].cooldowns, 1, "buttons without optional cooldown widgets are supported")
local restrictedCooldown = ActionButton1.chargeCooldown
nativeGeometry = true
restrictedCooldown:ClearAllPoints()
restrictedCooldown:SetPoint("TOPLEFT", ActionButton1.icon, "TOPLEFT", 2, -2)
restrictedCooldown:SetPoint("BOTTOMRIGHT", ActionButton1.icon, "BOTTOMRIGHT", -2, 2)
nativeGeometry = false
restrictedCooldown.restricted = secret
skin:Style(skin.buttons[ActionButton1])
equal(restrictedCooldown.points[1][4], 2, "later restricted anchoring prevents cooldown geometry writes")
restrictedCooldown.restricted = false
skin:Refresh(); FitsIcon(ActionButton1, "chargeCooldown")
equal(skin.buttons[ActionButton2], nil, "forbidden buttons are skipped")
equal(skin.buttons[ActionButton3], nil, "restricted texture coordinates are not used or cached")
equal(ActionButton2.NormalTexture.alpha, 0.8, "skipped button keeps native art")
equal(ActionButton3.NormalTexture.alpha, 0.8, "restricted button keeps native art")
local record = skin.buttons[ActionButton1]
equal(record.background.solid[1], 0.035, "skin surface matches meter slate")
equal(record.edges[1].solid[4], 0.55, "resting border uses a quiet teal edge")
ActionButton1:OnEnter()
equal(ActionButton1.nativeEnter, 1, "native tooltip enter script still runs")
equal(record.edges[1].solid[4], 1, "hover brightens the edge")
ActionButton1:OnLeave()
equal(record.edges[1].solid[4], 0.55, "leaving restores the resting edge")
equal(ActionButton1.OnUpdate, nil, "skin adds no button polling updater")
equal(skin.events.OnUpdate, nil, "skin adds no controller polling updater")
local restrictedState = Button()
skin:Track(restrictedState)
restrictedState.CheckedTexture:SetAlpha(secret)
skin:Style(skin.buttons[restrictedState])
equal(restrictedState.CheckedTexture:GetAlpha(), secret, "style never replaces restricted native state opacity")
local beforeHooks, beforeTextures = hooks, textures
skin:Apply(); skin:Refresh()
equal(hooks, beforeHooks, "reapplying skin never duplicates hooks")
equal(textures, beforeTextures, "reapplying skin reuses its textures")
ActionButton1.NormalTexture:SetAlpha(0.65)
equal(ActionButton1.NormalTexture.alpha, 0, "native alpha writes keep ornament suppressed while active")
ActionButton1.CheckedTexture:SetAlpha(0.5)
equal(ActionButton1.CheckedTexture.alpha, 0.5, "native checked-state alpha remains native")
equal(EffectiveAlpha(ActionButton1.CheckedTexture), 0.11, "native action-state alpha cannot erase fill translucency")
ActionButton1.bar.hideBarArt = true
ActionButton1:UpdateButtonArt()
equal(ActionButton1.PushedTexture.solid[4], 0.35, "native art refresh retains Suite press feedback")
equal(ActionButton1.CheckedTexture:GetAlpha(), 0.5, "native art refresh preserves the latest state opacity")
equal(EffectiveAlpha(ActionButton1.CheckedTexture), 0.11, "native art refresh keeps state feedback translucent")
local laterDivider = Region(MainActionBar); dividers[laterDivider] = true
MainActionBar:UpdateDividers(); Flush()
equal(MainActionBar.nativeDividers, 1, "native divider function still runs")
equal(laterDivider.alpha, 0, "late divider artwork is discovered")
for _ = 1, 200 do skin.events:OnEvent("ADDON_LOADED") end
equal(TimerCount(), 1, "discovery bursts coalesce to one cancellable timer")
local stale = skin.timer
Combat(true); skin.events:OnEvent("PLAYER_REGEN_DISABLED")
equal(TimerCount(), 0, "combat entry cancels pending discovery")
local beforeGeometry = geometryWrites
ActionButton1:UpdateButtonArt(); ActionButton1:OnEnter()
PetState(PetActionButton1, true, false)
equal(EffectiveAlpha(PetActionButton1.CheckedTexture), 0.22, "combat pet selection remains translucent without a refresh")
PetState(PetActionButton1, true, true)
equal(EffectiveAlpha(PetActionButton1.CheckedTexture), 0.11, "combat pet attack keeps native reduced opacity")
equal(geometryWrites, beforeGeometry, "combat cosmetic feedback changes no Suite geometry")
equal(record.edges[1].solid[4], 1, "existing hover feedback works in combat")
equal(ActionButton1.PushedTexture.solid[4], 0.35, "existing press feedback survives native combat refresh")
Suite.db.actionBarSkin = false; skin:Apply()
equal(record.background:IsShown(), true, "combat disable defers restoration until safe")
equal(next(skin.events.registered), nil, "disable removes skin event subscriptions immediately")
LeaveCombat()
equal(record.background:IsShown(), false, "combat exit removes Suite surface after disable")
equal(ActionButton1.NormalTexture.alpha, 0.65, "disable restores the latest native ornament alpha")
equal(ActionButton1.SlotArt.alpha, 1, "disable restores slot artwork")
equal(MainActionBar.BorderArt.alpha, 1, "disable restores main border alpha")
equal(MainActionBar.EndCaps.LeftEndCap.Texture.alpha, 1, "disable restores end-cap art")
equal(divider.alpha, 1, "disable restores native divider alpha")
equal(#ActionButton1.icon.masks, 1, "disable restores the known icon mask once")
equal(ActionButton1.icon.masks[1], ActionButton1.IconMask, "disable restores the original mask object")
equal(ActionButton1.icon.points[1][4], originalIconPoints[1][4], "disable restores original icon anchors")
equal(table.concat(ActionButton1.icon.coords, ","), table.concat(originalIconCoords, ","), "disable restores all eight icon coordinates")
equal(table.concat(ActionButton1.CheckedTexture.coords, ","), table.concat(originalCheckedCoords, ","), "disable restores all eight state coordinates")
equal(ActionButton1.CheckedTexture.points[1][4], originalStatePoints[1][4], "disable restores state anchors")
equal(ActionButton1.CheckedTexture.atlas, "original-CheckedTexture", "disable restores the native checked atlas")
equal(ActionButton1.CheckedTexture.blend, "ADD", "disable restores native blend mode")
equal(ActionButton1.CheckedTexture.alpha, 0.5, "disable preserves native checked alpha changes")
equal(table.concat(ActionButton1.CheckedTexture.vertex, ","), "0.6,0.7,0.8,0.5", "disable restores original RGB with the latest native opacity")
equal(PetActionButton1.CheckedTexture:GetAlpha(), 0.5, "disable retains the latest native pet attack opacity")
equal(PetActionButton1.CheckedTexture.solid, nil, "disable removes the Suite pet fill")
equal(restrictedState.CheckedTexture:GetAlpha(), secret, "restore never replaces restricted native state opacity")
equal(ActionButton1.PushedTexture.atlas, "addrow-pushed", "native restoration observes the current Edit Mode art choice")
equal(ActionButton1.PushedTexture.width, 51, "native restoration retains current art sizing")
for _, role in ipairs(cooldownRoles) do
    local widget, saved = ActionButton1[role], originalCooldowns[role]
    equal(widget.width, saved.width, role .. " restores the original width")
    equal(widget.height, saved.height, role .. " restores the original height")
    for index = 1, 2 do
        for field = 1, 5 do equal(widget.points[index][field], saved.points[index][field], role .. " restores the complete native anchor") end
    end
end
stale.callback()
equal(record.background:IsShown(), false, "cancelled stale timer cannot reapply a disabled skin")
equal(TimerCount(), 0, "disable leaves no idle work")
ActionButton1.NormalTexture:SetAlpha(0.4)
equal(ActionButton1.NormalTexture.alpha, 0.4, "disabled alpha observer is inert")
Suite.db.actionBarSkin = true; skin:Apply()
equal(textures, beforeTextures, "reenabling reuses the same surface and edge textures")
equal(ActionButton1.NormalTexture.alpha, 0, "reenabling captures current native alpha before suppressing")
PetState(PetActionButton1, true, false)
equal(EffectiveAlpha(PetActionButton1.CheckedTexture), 0.22, "reenabling keeps selected pet icons visible")
skin:Queue(); local oldWork = skin.timer
skin:Cancel(); skin:Queue(); local currentWork = skin.timer
oldWork.callback()
equal(skin.timer, currentWork, "stale timer cannot erase a newer work handle")
Flush()
ActionButton1.icon:AddMaskTexture(ActionButton1.IconMask)
Suite.db.actionBarSkin = false; skin:Apply()
equal(#ActionButton1.icon.masks, 1, "restoration tolerates a native mask already reattached")
equal(ActionButton1.NormalTexture.alpha, 0.4, "second disable restores recaptured native alpha")
ActionButton3.icon.coords[1] = 0.1
ActionButton3.icon.masks = { Region(ActionButton3) }
ActionButton2.forbidden = false
ActionButton2.HighlightTexture.GetBlendMode = nil
Suite.db.actionBarSkin = true; skin:Apply()
equal(skin.buttons[ActionButton3], nil, "an unrelated icon mask is never removed")
equal(skin.buttons[ActionButton2], nil, "missing restore capability leaves the whole button native")
ActionButton2.HighlightTexture.GetBlendMode = function(self) return self.blend end
ActionButton2.CheckedTexture.vertex[1] = secret
skin:Refresh()
equal(skin.buttons[ActionButton2], nil, "restricted state tint cannot enter a restoration snapshot")
for _, change in ipairs({
    function(button) button.CheckedTexture.SetColorTexture = nil end,
    function(button) button.CheckedTexture.GetAlpha = nil end,
    function(button) button.CheckedTexture:SetAlpha(secret) end,
    function(button) button.CheckedTexture.GetAlpha = function() return nil end end,
    function(button) button.CheckedTexture.GetAlpha = function() return 2 end end,
}) do
    local button = Button(); change(button); skin:Track(button)
    equal(skin.buttons[button], nil, "missing or unreadable state-opacity capability leaves the whole button native")
    equal(button.NormalTexture.alpha, 0.8, "rejected state-opacity snapshot preserves native button art")
end
Suite.ActionBars:Track(ActionButton1)
local rangeRecord = Suite.ActionBars.records[ActionButton1]
Suite.db.fullButtonRange = true
Suite.ActionBars:SetRange(rangeRecord, true, false)
equal(ActionButton1.icon.vertex[1], 1, "full range red works with the skin enabled")
equal(ActionButton1.icon.vertex[2], 0.15, "skin does not overwrite full range tint")
ActionButton1:UpdateButtonArt()
equal(ActionButton1.icon.vertex[2], 0.15, "native skin refresh does not clear range tint")
Suite.db.actionBarSkin = false; skin:Apply()
equal(ActionButton1.icon.vertex[2], 0.15, "disabling the skin preserves independently enabled range feedback")
Suite.db.fullButtonRange = false; Suite.ActionBars:Restore(rangeRecord)
equal(ActionButton1.icon.vertex[1], 0.5, "range restoration retains native mana color after skin removal")
equal(ActionButton1.icon.vertex[3], 1, "independent range restoration keeps native mana blue")
Suite.db.actionBarSkin = true; skin:Apply()
MainActionBar.BorderArt:SetAlpha(secret)
equal(MainActionBar.BorderArt.alpha, secret, "restricted native alpha stays on its native path")
Suite.db.actionBarSkin = false; skin:Apply()
equal(MainActionBar.BorderArt.alpha, secret, "disable never serializes or guesses restricted alpha")
Suite.Set = function(key, value)
    equal(key, "actionBarSkin", "skin control only edits the skin preference")
    Suite.db[key] = value; skin:Apply()
end
Suite.GUI:OpenPage("actionbars")
equal(Suite.GUI.rows[2].label.text, "Suite action bar skin", "skin has a clear independent settings toggle")
Suite.GUI.rows[2]:OnClick()
equal(Suite.db.actionBarSkin, true, "settings toggle enables the skin")
equal(Suite.db.fullButtonRange, false, "settings skin toggle keeps range preference off")
Suite.GUI.rows[2]:OnClick()
equal(Suite.db.actionBarSkin, false, "settings toggle restores native presentation")
Suite.db.actionBarSkin = true
Combat(true); skin:Apply(); ActionButton1:OnShow(); LeaveCombat()
equal(skin.events.registered.ADDON_LOADED, true, "a retained combat show hook cannot lose the deferred enable subscriptions")
equal(skin.buttons[ActionButton1].active, true, "combat reenabling still skins buttons after a retained show callback")
PetActionButton1:UpdateButtonArt(); FitsIcon(PetActionButton1, "cooldown")
Combat(true); skin.events:OnEvent("PLAYER_REGEN_DISABLED")
beforeGeometry = geometryWrites
PetActionButton1:UpdateButtonArt()
equal(geometryWrites, beforeGeometry, "native combat cooldown layout does not trigger Suite geometry writes")
equal(PetActionButton1.cooldown.points[1][4], 1.7, "native cooldown layout remains authoritative during combat")
LeaveCombat(); FitsIcon(PetActionButton1, "cooldown")
Suite.db.actionBarSkin = false; skin:Apply()
equal(PetActionButton1.cooldown.points[1][4], 1.7, "disable lets current native small-button artwork set its cooldown layout")
equal(singleCooldown.cooldown.points[1][4], 3, "a single-cooldown button restores its original icon inset")
Suite.db.actionBarSkin, Suite.db.fullButtonRange = oldSkin, oldRange
CreateFrame, C_Timer, hooksecurefunc, Suite.pending, Suite.Set = oldCreate, oldTimer, oldHook, oldPending, oldSet
MainActionBar = oldBar
for _, name in ipairs(names) do _G[name] = previous[name] end
Combat(false)
