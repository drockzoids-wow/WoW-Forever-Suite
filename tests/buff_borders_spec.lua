local Suite, equal, Frame, SetCombat = ...
local borders = Suite.BuffBorders
local names = { "CreateFrame", "C_Timer", "hooksecurefunc", "BuffFrame", "DebuffFrame", "PlayerFrame", "TargetFrame", "C_UnitAuras" }
local old, oldModule = {}, {}
for _, name in ipairs(names) do old[name] = _G[name] end
for key, value in pairs(borders) do oldModule[key] = value end
local oldDB, oldPending = Suite.db, Suite.pending
local timers, textures, hooks, constructed, nativeUpdates = {}, 0, 0, 0, 0
local function Secret() return { secret = true } end
local function Drain()
    local queued = timers; timers = {}
    for _, timer in ipairs(queued) do if not timer.cancelled then timer.callback() end end
end
local function CountTimers()
    local count = 0; for _, timer in ipairs(timers) do if not timer.cancelled then count = count + 1 end end; return count
end
local function Fire(event)
    if borders.events and borders.events.registered[event] then borders.events.OnEvent(borders.events, event) end
end
local function LeaveCombat()
    SetCombat(false)
    local pending = Suite.pending; Suite.pending = {}
    for _, callback in pairs(pending) do callback() end
    Fire("PLAYER_REGEN_ENABLED"); Drain()
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
CreateFrame = function(...)
    assert(not InCombatLockdown(), "buff-border controller creation must stay outside combat")
    constructed = constructed + 1
    local frame = old.CreateFrame(...); frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    return frame
end
hooksecurefunc = function(...)
    assert(not InCombatLockdown(), "buff-border hook installation must stay outside combat")
    hooks = hooks + 1; return old.hooksecurefunc(...)
end
C_UnitAuras = setmetatable({}, { __index = function() error("borders must never read or cancel auras") end })
local function Native(parent)
    local widget = Frame(); widget.parent = parent
    widget.IsForbidden = function(self) return self.forbidden or false end
    widget.IsAnchoringRestricted = function(self) return self.restricted or false end
    widget.coords = { 0, 0, 0, 1, 1, 0, 1, 1 }
    widget.GetTexCoord = function(self) return unpack(self.coords) end
    widget.SetTexCoord = function(self, ...)
        local values = { ... }
        for _, value in ipairs(values) do assert(Suite.IsReadable(value), "secret coordinates cannot be replayed") end
        if #values == 4 then
            self.coords = { values[1], values[3], values[1], values[4], values[2], values[3], values[2], values[4] }
        else assert(#values == 8, "native coordinate restoration retains all four corners"); self.coords = values end
    end
    for _, method in ipairs({ "SetPoint", "ClearAllPoints", "SetSize", "SetWidth", "SetHeight", "SetScale", "SetParent",
        "SetTexture", "SetAtlas", "SetAlpha", "SetVertexColor", "SetScript", "HookScript", "EnableMouse", "RegisterForClicks" }) do
        widget[method] = function() error("buff borders cannot alter native layout, artwork or input") end
    end
    widget.CreateTexture = function(self, name, layer, _, sublevel)
        assert(not InCombatLockdown(), "buff border textures are created outside combat")
        assert(name == nil and layer == "OVERLAY" and sublevel == 7, "borders use anonymous owned overlay edges")
        textures = textures + 1
        local edge = Frame(); edge.parent = self; edge.points = {}
        edge.IsForbidden = function(self) return self.forbidden or false end
        edge.SetPoint = function(self, ...)
            assert(not InCombatLockdown(), "border anchors must stay outside combat"); self.points[#self.points + 1] = { ... }
        end
        edge.ClearAllPoints = function(self) assert(not InCombatLockdown()); self.points = {} end
        edge.SetWidth = function(self, width) assert(not InCombatLockdown()); self.width = width end
        edge.SetHeight = function(self, height) assert(not InCombatLockdown()); self.height = height end
        edge.SetColorTexture = function(self, ...) assert(not InCombatLockdown()); self.color = { ... } end
        return edge
    end
    return widget
end
local function Button(parent, kind, unit)
    local button = Native(parent)
    button.Icon = Native(button)
    button.auraType, button.unit = kind, unit
    button.OnClick, button.OnEnter = function() end, function() end
    button.Duration, button.Count, button.DebuffBorder, button.TempEnchantBorder = Native(button), Native(button), Native(button), Native(button)
    return button
end
local function Root()
    local root = Native(); root.AuraContainer = Native(root); root.auraFrames = {}
    root.UpdateAuraButtons = function() nativeUpdates = nativeUpdates + 1 end
    return root
end
local function Visible(button)
    local record = borders.buttons[button]
    if not record then return false end
    for _, edge in ipairs(record.edges) do if not edge:IsShown() then return false end end
    return true
end
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
BuffFrame, DebuffFrame = Root(), Root()
PlayerFrame, TargetFrame = Native(), Native()
local buff = Button(BuffFrame.AuraContainer, "Buff", "player")
local enchant = Button(BuffFrame.AuraContainer, "TempEnchant", "player")
local other = Button(BuffFrame.AuraContainer, "Buff", "party1")
local vehicle = Button(BuffFrame.AuraContainer, "Buff", "vehicle")
local unknown = Button(BuffFrame.AuraContainer, Secret(), "player")
local unused = Button(BuffFrame.AuraContainer, nil, nil)
local example = Button(BuffFrame.AuraContainer, "Buff", nil); example.isExample = true
local debuff = Button(DebuffFrame.AuraContainer, "Debuff", "player")
local playerAura = Button(PlayerFrame, "Buff", "player")
local targetAura = Button(TargetFrame, "Buff", "player")
BuffFrame.auraFrames = { buff, enchant, other, vehicle, unknown, unused, example, debuff, playerAura, targetAura }
local nativeClick, nativeEnter, nativeIcon = buff.OnClick, buff.OnEnter, buff.Icon
equal(Suite.db.playerBuffBorders, false, "buff borders start independently off")
borders:Apply(); Drain()
equal(textures, 0, "disabled buff borders create no artwork")
equal(hooks, 0, "disabled buff borders install no hooks")
equal(constructed, 0, "disabled buff borders create no controller")
equal(Suite.InitializeDB({ playerBuffBorders = true }).playerBuffBorders, true, "buff border preference persists")
equal(Suite.InitializeDB({ playerBuffBorders = Secret() }).playerBuffBorders, false, "restricted preference stays off")
SetCombat(true); Suite.db.playerBuffBorders = true; borders:Apply()
equal(constructed, 0, "enabling borders during combat defers construction")
equal(type(Suite.pending.buffBorders), "function", "combat enablement records deferred work")
Suite.db.playerBuffBorders = false; borders:Apply(); LeaveCombat()
equal(textures, 0, "disable cancels queued combat enablement")
Suite.db.playerBuffBorders = true; borders:Apply(); Drain()
equal(Visible(buff), true, "ordinary player buff gets an outline")
equal(buff.Icon.coords[1], 0.06, "buff icon uses the same bevel-removing crop as Suite action bars")
equal(buff.Icon.coords[8], 0.94, "cropped art fills the original icon rectangle")
equal(enchant.Icon.coords[1], 0, "weapon enchant retains native coordinates")
equal(playerAura.Icon.coords[1], 0, "player-frame aura retains native coordinates")
equal(targetAura.Icon.coords[1], 0, "target-frame aura retains native coordinates")
equal(Visible(example), true, "native buff Edit Mode preview gets an outline")
for _, button in ipairs({ enchant, other, vehicle, unknown, unused, debuff, playerAura, targetAura }) do
    equal(Visible(button), false, "only player BuffFrame buff types are outlined")
end
equal(borders.buttons[debuff], nil, "debuff container is never decorated even if referenced by the buff list")
equal(borders.buttons[playerAura], nil, "player-frame buff aura is never decorated")
equal(borders.buttons[targetAura], nil, "target-frame buff aura is never decorated")
equal(buff.OnClick, nativeClick, "native right-click cancellation remains authoritative")
equal(buff.OnEnter, nativeEnter, "native tooltip input is preserved")
equal(buff.Icon, nativeIcon, "native icon widget stays intact")
equal(hooks, 1, "only the native BuffFrame instance update is observed")
equal(textures, 28, "all seven owned slots are prepared outside combat for later reuse")
equal(borders.buttons[buff].edges[1].points[1][2], buff.Icon, "border surrounds the icon rather than the duration area")
equal(CountTimers(), 0, "initial styling leaves no polling worker")
buff.Icon.coords = { 0, 0, 0, 1, 1, 0, 1, 1 }; BuffFrame:UpdateAuraButtons()
equal(buff.Icon.coords[1], 0.06, "native artwork refresh cannot leave the baked bevel visible again")
Drain()

SetCombat(true)
unused.auraType, unused.unit = "Buff", "player"; BuffFrame:UpdateAuraButtons()
equal(Visible(unused), true, "a newly filled prepared slot gains a border during combat")
equal(unused.Icon.coords[1], 0.06, "prepared combat slot gains the cropped icon without layout work")
equal(textures, 28, "combat filling creates no textures")
enchant.auraType = "Buff"; BuffFrame:UpdateAuraButtons()
equal(Visible(enchant), true, "slot reuse can change an enchant into a normal buff")
buff.auraType = "TempEnchant"; BuffFrame:UpdateAuraButtons()
equal(Visible(buff), false, "reuse immediately removes a border from a weapon enchant")
equal(buff.Icon.coords[1], 0, "enchant reuse restores native cropping during combat")
buff.auraType = "Debuff"; BuffFrame:UpdateAuraButtons()
equal(Visible(buff), false, "harmful types never get a border")
buff.auraType, buff.unit = "Buff", Secret(); BuffFrame:UpdateAuraButtons()
equal(Visible(buff), false, "secret unit tokens cannot imply a player buff")
equal(buff.Icon.coords[1], 0, "unknown unit restores the public native crop")
buff.unit, buff.auraType = "player", Secret(); BuffFrame:UpdateAuraButtons()
equal(Visible(buff), false, "secret aura type cannot imply a buff")
buff.auraType = "Buff"; BuffFrame:UpdateAuraButtons()
equal(Visible(buff), true, "public player buff classification restores the cosmetic border")
local fresh = Button(BuffFrame.AuraContainer, "Buff", "player"); BuffFrame.auraFrames[#BuffFrame.auraFrames + 1] = fresh
BuffFrame:UpdateAuraButtons()
equal(borders.buttons[fresh], nil, "a new combat-created native slot defers border construction")
equal(CountTimers(), 0, "combat discovery uses deferred work rather than timers")
equal(type(Suite.pending.buffBorders), "function", "new slot discovery waits for combat exit")
LeaveCombat()
equal(Visible(fresh), true, "new native slot is decorated after combat")
equal(textures, 32, "only the new slot adds artwork after combat")
local previousUpdates = nativeUpdates
for i = 1, 12 do BuffFrame:UpdateAuraButtons() end
equal(nativeUpdates, previousUpdates + 12, "post-hook preserves every original native update")
equal(CountTimers(), 1, "repeated updates coalesce discovery into one worker")
Drain(); equal(textures, 32, "ordinary refreshes reuse existing textures")

buff.parent = TargetFrame; BuffFrame:UpdateAuraButtons()
equal(Visible(buff), false, "reparenting to a unit frame immediately drops the border")
equal(buff.Icon.coords[1], 0, "reparented icon regains its native crop")
buff.parent = BuffFrame.AuraContainer; buff.Icon = Native(buff); buff.auraType = "TempEnchant"
BuffFrame:UpdateAuraButtons(); Drain()
equal(Visible(buff), false, "reanchoring to a replacement icon cannot leave an enchant bordered")
buff.auraType = "Buff"; BuffFrame:UpdateAuraButtons(); Drain()
equal(Visible(buff), true, "replacement native icon retains ordinary buff support")
equal(borders.buttons[buff].edges[1].points[1][2], buff.Icon, "replacement icon becomes the owned border anchor")
equal(buff.Icon.coords[1], 0.06, "replacement icon receives its own reversible crop")
buff.forbidden = true; BuffFrame:UpdateAuraButtons()
equal(Visible(buff), false, "forbidden button stops being styled")
buff.forbidden = false; BuffFrame:UpdateAuraButtons(); Drain()
local denied = Button(BuffFrame.AuraContainer, "Buff", "player"); denied.restricted = Secret()
BuffFrame.auraFrames[#BuffFrame.auraFrames + 1] = denied
BuffFrame:UpdateAuraButtons(); Drain()
equal(borders.buttons[denied], nil, "unknown anchor permission prevents new artwork")
local missingCoords = Button(BuffFrame.AuraContainer, "Buff", "player"); missingCoords.Icon.GetTexCoord = nil
BuffFrame.auraFrames[#BuffFrame.auraFrames + 1] = missingCoords
local secretCoords = Button(BuffFrame.AuraContainer, "Buff", "player"); secretCoords.Icon.coords[1] = Secret()
BuffFrame.auraFrames[#BuffFrame.auraFrames + 1] = secretCoords
local malformedCoords = Button(BuffFrame.AuraContainer, "Buff", "player"); malformedCoords.Icon.coords = { 0, 1 }
BuffFrame.auraFrames[#BuffFrame.auraFrames + 1] = malformedCoords
local partialCoords = Button(BuffFrame.AuraContainer, "Buff", "player")
partialCoords.Icon.GetTexCoord = function() return nil, 0, 0, 1, 1, 0, 1, 1 end
BuffFrame.auraFrames[#BuffFrame.auraFrames + 1] = partialCoords
BuffFrame:UpdateAuraButtons(); Drain()
equal(borders.buttons[missingCoords], nil, "missing coordinate snapshot capability preserves native artwork")
equal(borders.buttons[secretCoords], nil, "secret initial coordinates cannot be captured or guessed")
equal(borders.buttons[malformedCoords], nil, "incomplete initial coordinates prevent an irreversible crop")
equal(borders.buttons[partialCoords], nil, "a nil coordinate cannot hide inside an otherwise complete tuple")
local privateAnchor = Button(BuffFrame.AuraContainer, "Buff", "player"); privateAnchor.isAuraAnchor = true
BuffFrame.auraFrames[#BuffFrame.auraFrames + 1] = privateAnchor
BuffFrame:UpdateAuraButtons(); Drain()
equal(borders.buttons[privateAnchor], nil, "private aura anchor placeholders are never decorated")
privateAnchor.isAuraAnchor = Secret(); BuffFrame:UpdateAuraButtons(); Drain()
equal(borders.buttons[privateAnchor], nil, "unknown private-anchor classification is never bypassed")
buff.isAuraAnchor = true; BuffFrame:UpdateAuraButtons()
equal(Visible(buff), false, "a previously styled button cannot retain a private-anchor border")
buff.isAuraAnchor = Secret(); BuffFrame:UpdateAuraButtons()
equal(Visible(buff), false, "unknown anchor role immediately hides an existing border")
buff.isAuraAnchor = nil; BuffFrame:UpdateAuraButtons(); Drain()

SetCombat(true); BuffFrame:UpdateAuraButtons()
Suite.db.playerBuffBorders = false; borders:Apply()
equal(Visible(buff), false, "disabling in combat hides only the owned border")
equal(buff.Icon.coords[1], 0, "disabling in combat restores native icon coordinates")
equal(buff.Icon.coords[8], 1, "restoration retains the original lower-right corner")
equal(Suite.pending.buffBorders, nil, "disabling cancels deferred discovery")
equal(next(borders.events.registered), nil, "disabled module registers no feature events")
BuffFrame:UpdateAuraButtons(); equal(Visible(fresh), false, "persistent post-hook stays passive while disabled")
LeaveCombat(); equal(CountTimers(), 0, "disabled module stays idle after combat")
local oldRoot = BuffFrame; BuffFrame = nil
Suite.db.playerBuffBorders = true; borders:Apply(); Drain()
equal(CountTimers(), 0, "missing native BuffFrame does not cause polling")
BuffFrame = Root(); local late = Button(BuffFrame.AuraContainer, "Buff", "player"); BuffFrame.auraFrames = { late }
late.Icon.coords = { 0.02, 0.01, 0.03, 0.99, 0.98, 0.02, 0.99, 0.98 }
Fire("ADDON_LOADED"); Drain()
equal(Visible(late), true, "late native buff frame is discovered after addon loading")
equal(Visible(buff), false, "a replaced root cannot retain old borders")
equal(hooks, 2, "each native root is hooked once")
oldRoot:UpdateAuraButtons(); Drain(); equal(Visible(buff), false, "obsolete native root callbacks cannot reclaim old buttons")
Fire("PLAYER_LOGOUT")
equal(Visible(late), false, "logout releases the owned border")
equal(late.Icon.coords[1], 0.02, "logout restores the captured original crop rather than a guessed default")
equal(late.Icon.coords[3], 0.03, "restoration preserves all four original corner coordinates")
equal(CountTimers(), 0, "logout cancels outstanding discovery")
BuffFrame:UpdateAuraButtons(); equal(CountTimers(), 0, "late logout updates cannot restart work")
Suite.db.playerBuffBorders = false; borders:Apply()

for key in pairs(borders) do borders[key] = nil end
for key, value in pairs(oldModule) do borders[key] = value end
for _, name in ipairs(names) do _G[name] = old[name] end
Suite.db, Suite.pending = oldDB, oldPending
SetCombat(false)
