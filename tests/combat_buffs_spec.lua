local Suite, equal, Frame, SetCombat = ...
local combat = Suite.CombatBuffs
local globals = { "CreateFrame", "C_AddOns", "CustomAuraContainerAuraProcessingPolicy", "AuraContainerSortMethod",
    "AuraContainerSortDirection", "C_StringUtil", "C_Timer", "C_UnitAuras", "UnitIsDeadOrGhost", "IsResting" }
local old = {}; for _, name in ipairs(globals) do old[name] = _G[name] end
local oldDB, oldPending = Suite.db, Suite.pending
local buffs = Suite.MissingBuffs
local oldCombatSlots = Suite.BuffReminders.combatSlots
Suite.BuffReminders.combatSlots = 0
local saved = { roster = buffs.Roster, auras = buffs.Auras, spell = buffs.Spell, learned = buffs.Learned,
    bookDirty = buffs.bookDirty, book = buffs.learned, complete = buffs.learnedComplete }
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
Suite.db.missingBuffs, Suite.db.missingBuffCombat, Suite.db.missingBuffExpiry = true, true, true
local roster = { { unit = "player", guid = "one", name = "Caster", class = "MAGE", level = 60, party = true },
    { unit = "party1", guid = "two", name = "Friend", class = "PRIEST", level = 60, party = true } }
local widgets, containers, snapshots, made = {}, {}, {}, 0
local reject, dead, resting = false, false, false
local blockedHandlers = 0
local selectedSpell, selectedName, known = 1461, "Intellect", true
local function NoRead() error("Lua must never inspect native aura display state") end
local function Outside() assert(not InCombatLockdown(), "native discovery/setup must wait for combat") end
C_Timer = setmetatable({}, { __index = function() error("native combat buffs must not poll") end })
C_UnitAuras = setmetatable({}, { __index = function() error("combat code must not query raw auras") end })
UnitIsDeadOrGhost = function() return dead end
IsResting = function() return resting end
C_AddOns = { LoadAddOn = function() Outside() end }
CustomAuraContainerAuraProcessingPolicy = { None = 0 }
AuraContainerSortMethod, AuraContainerSortDirection = { ExpirationOnly = 5 }, { Reverse = 1 }
C_StringUtil = { CreateNumericRuleFormatter = function()
    Outside(); return { SetBreakpoints = function(self, points) self.points = points end }
end }
local New
New = function(kind, name, parent, template)
    Outside(); made = made + 1
    local frame = Frame(name)
    frame.kind, frame.parent, frame.shown, frame.points = kind, parent, true, {}
    frame.secretShown = kind == "AuraButton" or parent and parent.secretShown or false
    local setScript = frame.SetScript
    frame.SetScript = function(self, event, handler)
        if self.secretShown and (event == "OnHide" or event == "OnShow") then
            blockedHandlers = blockedHandlers + 1
            error("Cannot assign script handler for 'onhide' (blocked by secret aspects)")
        end
        setScript(self, event, handler)
    end
    frame.layoutOptIn = template and template:find("DisableUntrustedLayoutScriptsTemplate", 1, true) ~= nil or parent and parent.layoutOptIn or false
    frame.SetPoint = function(self, point, relative, relativePoint, x, y)
        assert(not relative or not relative.layoutOptIn or self.layoutOptIn,
            "Anchoring disallowed as dependent object would inherit forbidden aspects: UntrustedLayoutScriptExecution")
        Outside(); self.points[point] = { relative, relativePoint, x or 0, y or 0 }
    end
    frame.ClearAllPoints = function(self) Outside(); self.points = {} end
    frame.SetAllPoints = function(self, relative)
        self:SetPoint("TOPLEFT", relative, "TOPLEFT", 0, 0)
        self:SetPoint("BOTTOMRIGHT", relative, "BOTTOMRIGHT", 0, 0)
    end
    frame.SetClipsChildren = function(self, value) self.clips = value end
    frame.SetVertexColor = function(self, ...) self.vertex = { ... } end
    frame.SetTexCoord = function(self, ...) self.texCoords = { ... } end
    frame.SetAlpha = function(self, value) self.alpha = value end
    frame.Show = function(self) local before = self.shown; self.shown = true; if not before and self.OnShow then self:OnShow() end end
    frame.Hide = function(self) local before = self.shown; self.shown = false; if before and self.OnHide then self:OnHide() end end
    frame.SetShown = function(self, value) if value then self:Show() else self:Hide() end end
    frame.CreateTexture = function(self) return New("Texture", nil, self) end
    frame.CreateFontString = function(self) return New("FontString", nil, self) end
    frame.SetText = function(self, text)
        self.text = text; self.width = #text * (self.fontSize or 10); self.height = self.fontSize or 10
    end
    widgets[#widgets + 1] = frame
    if kind == "AuraContainer" then
        containers[#containers + 1] = frame
        frame.SetEnabled = function(self, value) Outside(); self.enabled = value end
        frame.SetEditModePreviewEnabled = function(self, value) Outside(); self.preview = value end
        frame.SetAuraProcessingPolicy = function() Outside() end
        frame.SetUnit = function(self, unit) Outside(); self.unit = unit end
        frame.AddAuraGroup = function(self, _, filter, options)
            Outside(); if reject then error("rejected native setup") end
            equal(filter, "HELPFUL", "only helpful auras can cover reminders")
            equal(options.maxFrameCount, 1, "one native match per member/family")
            self.options, self.buttons = options, {}
            for index = 1, 2 do
                local button = New("AuraButton", nil, self)
                button:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
                button.SetDurationText = function(_, gate, binding)
                    button.gate, button.formatter = gate, binding.textFormatter
                    gate.GetText, gate.GetWidth, gate.GetHeight = NoRead, NoRead, NoRead
                end
                options.initializeFrame(button)
                self.buttons[index] = button
                button.IsShown, button.GetWidth, button.GetHeight, button.GetPoint = NoRead, NoRead, NoRead, NoRead
                button.shown = false
            end
        end
        frame.IsShown, frame.GetWidth, frame.GetHeight, frame.GetPoint = NoRead, NoRead, NoRead, NoRead
        frame.GetAuraGroupFrameCount, frame.GetChildren = NoRead, NoRead
    end
    return frame
end
CreateFrame = New
buffs.Roster = function() Outside(); return roster end
buffs.Auras = function(_, unit) Outside(); return snapshots[unit] or { records = {}, byName = {} } end
buffs.Spell = function(_, id)
    if selectedName == "Intellect" and (id == 1459 or id == 1461) or id == selectedSpell then
        return { id = id, name = selectedName, icon = 123 }
    end
end
buffs.Learned = function()
    Outside(); return known and { [selectedName] = { id = selectedSpell, name = selectedName, icon = 123 } } or {}, true
end
buffs.bookDirty = true

-- A minimal renderer evaluates anchors/clipping independently of addon logic.
-- These fixture reads represent the engine; native getters above throw for Lua.
local xFactor = { TOPLEFT = 0, LEFT = 0, BOTTOMLEFT = 0, TOP = 0.5, CENTER = 0.5, BOTTOM = 0.5, TOPRIGHT = 1, RIGHT = 1, BOTTOMRIGHT = 1 }
local yFactor = { TOPLEFT = 0, TOP = 0, TOPRIGHT = 0, LEFT = 0.5, CENTER = 0.5, RIGHT = 0.5, BOTTOMLEFT = 1, BOTTOM = 1, BOTTOMRIGHT = 1 }
local function Rect(frame)
    if not frame then return 0, 0, 0, 0 end
    local width, height = frame.width or 0, frame.height or 0
    local left, right, top, bottom, cx, cy
    for point, anchor in pairs(frame.points or {}) do
        local l, t, r, b = Rect(anchor[1])
        local x = l + (r - l) * xFactor[anchor[2]] + anchor[3]
        local y = t - (t - b) * yFactor[anchor[2]] + anchor[4]
        if xFactor[point] == 0 then left = x elseif xFactor[point] == 1 then right = x else cx = x end
        if yFactor[point] == 0 then top = y elseif yFactor[point] == 1 then bottom = y else cy = y end
    end
    left = left or (right and right - width) or (cx and cx - width / 2) or 0
    right = right or left + width
    top = top or (bottom and bottom + height) or (cy and cy + height / 2) or 0
    bottom = bottom or top - height
    return left, top, right, bottom
end
local function Drawn(widget)
    local left, top, right, bottom = Rect(widget)
    local parent = widget
    while parent do
        if parent.shown == false or parent.alpha == 0 then return false end
        if parent.clips then
            local l, t, r, b = Rect(parent)
            left, right, top, bottom = math.max(left, l), math.min(right, r), math.min(top, t), math.max(bottom, b)
        end
        parent = parent.parent
    end
    return right > left and top > bottom
end
local function Names()
    local names = {}
    for _, widget in ipairs(widgets) do
        if widget.kind == "FontString" and (widget.text == "Caster" or widget.text == "Friend") and Drawn(widget) then names[widget.text] = true end
    end
    return names
end
local function TitleDrawn()
    for _, widget in ipairs(widgets) do
        if widget.kind == "FontString" and widget.text == "Missing Buffs" and Drawn(widget) then return true end
    end
    return false
end
local function Icons()
    local positions = {}
    for _, widget in ipairs(widgets) do
        if widget.kind == "Texture" and widget.texture == 123 and Drawn(widget) then
            local x, y = Rect(widget); positions[x .. ":" .. y] = true
        end
    end
    local count = 0; for _ in pairs(positions) do count = count + 1 end; return count
end
local function Aura(unit, present, remaining, permanent)
    for _, container in ipairs(containers) do
        if container.unit == unit and container.options then
            local active = present and not (permanent and container.options.candidateFilters.maxDuration)
            container.width, container.height = active and 260 or 0, active and 48 or 0
            for index, button in ipairs(container.buttons) do
                button.shown = active and index == 1
                if button.gate and active then
                    local format = ""
                    for _, rule in ipairs(button.formatter.points) do if remaining >= rule.threshold then format = rule.format end end
                    button.gate:SetText(format)
                end
            end
        end
    end
end

combat:Prepare()
equal(blockedHandlers, 0, "native aura descendants never receive secret visibility scripts")
equal(combat.count, 1, "one family slot covers all eligible members")
equal(#containers, 4, "two members have native presence and expiry displays")
equal(containers[1].options.candidateFilters.includeSpellIDs[1461], true, "learned rank is covered")
equal(containers[1].options.candidateFilters.includeSpellIDs[10157], true, "other classic ranks are included without spellbook API guesses")
equal(combat.frame:IsShown(), false, "native combat host stays hidden outside combat")
local record = combat.records["MAGE:intellect"]
local oldCombatFrame = Suite.BuffReminders.combatFrame
local legacy = New("Frame", nil, UIParent, "BackdropTemplate")
Suite.BuffReminders.combatFrame = legacy
Suite.BuffReminders:PlaceCombat()
equal(legacy.points.TOP[1], UIParent, "weapon reminders anchor to the ordinary root instead of native aura layout")
equal(legacy.points.TOP[4], -140, "weapon reminders share the native default row instead of dropping below it")
Suite.db.missingBuffPosition = { x = 0.1, y = -0.2 }
Suite.BuffReminders:PlaceCombat()
equal(legacy.points.CENTER[1], UIParent, "saved placement also avoids the native forbidden-aspect dependency")
equal(legacy.points.CENTER[2], "CENTER", "saved center position provides an independent shared-row anchor")
equal(legacy.points.CENTER[3], 0.1 * UIParent:GetWidth(), "weapon row retains the saved horizontal position")
equal(legacy.points.CENTER[4], -0.2 * UIParent:GetHeight(), "weapon row retains the same saved vertical position")
Suite.BuffReminders.combatSlots = 1
Suite.BuffReminders:PlaceCombat()
local pairWidth,pairHeight,pairSize,pairStride=buffs:BarLayout(1)
equal(combat.frame.width,pairWidth,"weapon capacity does not widen the native aura host")
equal(legacy.width,pairWidth,"ordinary weapon host uses the independently computed aura width")
equal(legacy.height,pairHeight,"both hosts retain the native height for stable saved-center alignment")
equal(record.cell.points.TOPLEFT[3],(pairWidth-pairSize)/2,"lone aura stays centered despite a reserved weapon reminder")
Suite.BuffReminders.combatSlots = 0
Suite.db.missingBuffPosition = {}; Suite.BuffReminders:PlaceCombat()
Suite.BuffReminders.combatFrame = oldCombatFrame
equal(record.tooltip.points.TOP[1], record.cell, "combat tooltip is anchored below its icon cell")
equal(record.tooltip.points.TOP[2], "BOTTOM", "combat tooltip opens beneath the caption")
equal(record.tipWidth < 260, true, "short tooltip text does not reserve the native masking plane's full width")
local barWidth, barHeight = buffs:BarLayout(1)
equal(combat.frame.width, barWidth, "combat layout uses the normal bar width")
equal(combat.frame.height, barHeight, "combat layout uses the normal bar height for saved-center alignment")
equal(record.cell.points.TOPLEFT[3], (barWidth - record.size) / 2, "single combat icon is centered like the normal bar")
equal(record.cell.points.TOPLEFT[4], -25, "combat icon preserves the normal header offset")
do
    local oldPrint, oldLabels = Suite.Print, Suite.BuffReminders.combatSlotLabels
    local output = {}
    Suite.Print = function(message) output[#output + 1] = message end
    Suite.BuffReminders.combatSlots, Suite.BuffReminders.combatSlotLabels = 1, { "MH Oil" }
    SetCombat(true)
    combat:Status()
    SetCombat(false)
    equal(output[2], "Aura slots: Intellect.", "combat diagnostics list public prepared aura identities without native visibility reads")
    equal(output[3], "Additional slots reserved: 1; MH Oil.", "combat diagnostics identify the fallback consuming layout space")
    Suite.Print = oldPrint
    Suite.BuffReminders.combatSlots, Suite.BuffReminders.combatSlotLabels = 0, oldLabels
end
for _, widget in ipairs(widgets) do
    if widget.kind == "FontString" and widget.text == "Missing Buffs" then
        equal(widget.points.TOP[3],0,"native title text has no horizontal offset from the shared row center")
    end
    if widget.kind == "Texture" and widget.texture == 123 then
        equal(widget.width, record.size - 4, "combat artwork uses the normal icon inset")
    end
end
local prepared = made
SetCombat(true); combat:RefreshVisibility()
Aura("player", false, 0); Aura("party1", false, 0)
equal(Icons(), 1, "two missing members draw one shared icon position")
equal(TitleDrawn(),true,"missing coverage reveals a passive floating title")
record.tooltip:Show()
equal(Names().Caster, true, "missing caster name is shown")
equal(Names().Friend, true, "missing teammate name is shown")
Aura("player", true, 120)
equal(Icons(), 1, "missing teammate retains the shared family icon")
equal(Names().Caster, nil, "covered caster name is hidden by native geometry")
equal(Names().Friend, true, "missing teammate name remains")
Aura("party1", true, 120)
equal(Icons(), 0, "all healthy buffs render no icon or permanent panel")
equal(TitleDrawn(),false,"healthy buffs also hide the combat title through native masks")
equal(next(Names()), nil, "healthy member names do not appear in tooltip")
Aura("player", true, 15)
equal(Icons(), 1, "native warning window reveals the near-expiry icon")
equal(TitleDrawn(),true,"native near-expiry warning also reveals the floating title")
equal(Names().Caster, true, "near-expiry member is listed")
equal(Names().Friend, nil, "healthy teammate remains absent from tooltip")
Aura("player", true, 120)
equal(Icons(), 0, "refreshing in combat clears the near-expiry reminder")
equal(TitleDrawn(),false,"refreshing clears the combat title without Lua visibility queries")
Aura("player", false, 0)
equal(Icons(), 1, "expiry in combat reveals the missing icon")
record.tooltip:Hide()
equal(next(Names()), nil, "hiding tooltip also clips names parented to native buttons")
record.tooltip:Show(); record.cell:Hide()
equal(record.tooltip:IsShown(), false, "public cell hiding cleans up its tooltip without a native OnHide hook")
record.cell:Show()
Aura("player", true, 0, true)
equal(Icons(), 0, "permanent coverage cannot reuse a stale soon warning")
equal(made, prepared, "combat display transitions create no widgets")
combat:RefreshVisibility("GROUP_ROSTER_UPDATE")
equal(combat.frame:IsShown(), false, "combat roster changes suspend stale member bindings")
combat:Apply()
equal(type(Suite.pending.combatBuffs), "function", "combat option changes queue native reconfiguration")
equal(made, prepared, "queued combat reconfiguration creates no widgets")
SetCombat(false); combat:Prepare()
equal(made, prepared, "unchanged descriptors reuse native widgets")
combat:Observe("player", { name = "Intellect", spellId = 1461, duration = 1800 })
combat:Prepare()
equal(combat.records["MAGE:intellect"].descriptor.members[1].warning, 60, "known long buffs use the selected warning interval")
local formatters = C_StringUtil
C_StringUtil = nil; Suite.db.missingBuffWarning = 120; combat:Prepare()
equal(combat.coverage["MAGE:intellect"], true, "missing detection survives an unavailable expiry formatter")
equal(combat.soonUnavailable, true, "unavailable expiry binding is recorded without a misleading timer fallback")
C_StringUtil = formatters; combat.soonUnavailable, combat.expiryFailure = nil, nil
Suite.db.missingBuffOutgoing = false; combat:Prepare()
equal(#combat.records["MAGE:intellect"].descriptor.members, 1, "outgoing opt-out removes party tracking")
Suite.db.missingBuffSelf = false; combat:Prepare()
equal(combat.count, 0, "all scopes off leave no native reminders")
Suite.db.missingBuffSelf = true; Suite.db.missingBuffExpiry = false; reject = true
combat:Prepare(); local failedMade = made; combat:Prepare()
equal(made, failedMade, "rejected setup is not retried on every aura refresh")
reject = false
for _, sample in ipairs({ {"PRIEST",1243}, {"DRUID",1126}, {"HUNTER",13165}, {"WARLOCK",687},
    {"PALADIN",465}, {"SHAMAN",324}, {"WARRIOR",6673}, {"ROGUE",9005} }) do
    roster[1].class, selectedSpell = sample[1], sample[2]
    selectedName = "Buff " .. selectedSpell
    Suite.db.missingBuffCustom = sample[1] == "ROGUE" and { {id=9005,group=false} } or {}
    buffs.bookDirty = true; combat:Prepare()
    equal(combat.count, 1, sample[1] .. " learned aura family is supported, including custom reminders")
end
local oldSliding = Suite.BuffSettings.sliding
Suite.BuffSettings.sliding = true
Suite.db.missingBuffIconSize = 64
local beforeDrag = made
combat:Prepare()
equal(made, beforeDrag, "dragging sliders does not rebuild native aura groups")
equal(combat.layoutPending, true, "native appearance waits for slider release")
Suite.BuffSettings.sliding = nil; combat:Prepare()
equal(combat.records["CUSTOM:9005"].size, 64, "slider release commits the shared enlarged native icon size")
equal(combat.layoutPending, nil, "native layout deferral clears after release")
Suite.BuffSettings.sliding = oldSliding
known = false; buffs.bookDirty = true; combat:Prepare()
equal(combat.count, 0, "another player's capabilities never authorize a buff the caster does not know")
Suite.db.missingBuffs = false; combat:Prepare()
for _, container in ipairs(containers) do equal(container.enabled, false, "disable stops native processing, including retired records") end

combat.records, combat.coverage, combat.durations, combat.auraIDs, combat.failed = {}, {}, {}, {}, {}
combat.auraDurations, combat.metadataDirty = {}, nil
combat.frame, combat.count, combat.suspended, combat.failure = nil, nil, nil, nil
combat.soonUnavailable, combat.expiryFailure = nil, nil
Suite.db, Suite.pending = oldDB, oldPending
Suite.BuffReminders.combatSlots = oldCombatSlots
buffs.Roster, buffs.Auras, buffs.Spell, buffs.Learned = saved.roster, saved.auras, saved.spell, saved.learned
buffs.bookDirty, buffs.learned, buffs.learnedComplete = saved.bookDirty, saved.book, saved.complete
for _, name in ipairs(globals) do _G[name] = old[name] end
SetCombat(false)
