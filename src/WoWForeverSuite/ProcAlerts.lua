local _, Suite = ...
local Alerts = { glows = {}, learned = {}, cells = {}, requested = {}, cooldownGCD = {}, history = {}, lastChecks = {} }
Suite.ProcAlerts = Alerts
Suite.modules[#Suite.modules + 1] = Alerts

-- Legacy reactive skills do not necessarily generate native overlay glows.
-- Rank IDs follow the Forever training catalog; talent roots are included too.
local reactive = {
    { 7384, 7887, 11584, 11585 }, -- Overpower
    { 6572, 6574, 7379, 11600, 11601 }, -- Revenge
    { 14251 }, -- Riposte
    { 1495, 14269, 14270, 14271 }, -- Mongoose Bite
    { 19306, 1242634, 20909, 20910 }, -- Counterattack
}
local function Read(callback, ...)
    if type(callback) ~= "function" then return end
    local ok, value = pcall(callback, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function ID(value) return Number(value) and value > 0 and value % 1 == 0 end
local function Enabled() return Suite.db and Suite.db.procAlerts == true end
local function Table(value) return Suite.IsReadable(value) and type(value) == "table" end

function Alerts:IconSize(db)
    local value = (db or Suite.db or Suite.defaults).procAlertIconSize
    return Number(value) and math.max(24, math.min(128, math.floor(value + 0.5))) or 42
end

function Alerts:ConfigureSize()
    if not self.frame or InCombatLockdown() then return end
    local size = self:IconSize()
    self.stride = math.max(110, size * 1.4 + 18)
    self.frame:SetSize(math.max(180, self.stride), size + 18)
    for _, cell in ipairs(self.cells) do
        cell:SetSize(size, size)
        cell.name:SetWidth(self.stride - 6)
        cell.name:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", math.max(10, math.min(18, math.floor(12 * size / 42 + 0.5))), "OUTLINE")
        if cell.glow then cell.glow:SetSize(size * 1.4, size * 1.4) end
    end
end

function Alerts:SetIconSize(value)
    if not Suite.db or InCombatLockdown() or not Number(value) then return end
    Suite.db.procAlertIconSize = self:IconSize({ procAlertIconSize = value })
    self:ConfigureSize(); self:Paint()
end

function Alerts:BuildGlow(cell)
    local atlas = "UI-HUD-ActionBar-Proc-Loop-Flipbook"
    if not Table(Read(C_Texture and C_Texture.GetAtlasInfo, atlas)) then return end
    local texture = cell:CreateTexture(nil, "OVERLAY", nil, 1)
    if type(texture.SetAtlas) ~= "function" or type(texture.CreateAnimationGroup) ~= "function" then return end
    texture:SetAtlas(atlas)
    texture:SetSize(42 * 1.4, 42 * 1.4)
    texture:SetPoint("CENTER", cell, "CENTER", 0, 0)
    texture:Hide()
    -- Use the client's own animated border artwork on our ordinary texture.
    -- The native animation engine advances it without a Lua OnUpdate handler.
    local group = texture:CreateAnimationGroup()
    group:SetLooping("REPEAT")
    local animation = group:CreateAnimation("FlipBook")
    animation:SetOrder(1); animation:SetDuration(1)
    animation:SetFlipBookRows(6); animation:SetFlipBookColumns(5); animation:SetFlipBookFrames(30)
    animation:SetFlipBookFrameWidth(0); animation:SetFlipBookFrameHeight(0)
    cell.glow, cell.glowAnimation = texture, group
end

function Alerts:SetGlow(cell, active)
    if not cell.glow or cell.glowing == active then return end
    cell.glowing = active
    if active then cell.glow:Show(); cell.glowAnimation:Play()
    else cell.glowAnimation:Stop(); cell.glow:Hide() end
end

function Alerts:Scan()
    self.learned, self.cooldownGCD = {}, {}
    for _, family in ipairs(reactive) do
        for index = #family, 1, -1 do
            local id = family[index]
            if Read(C_SpellBook and C_SpellBook.IsSpellKnown, id) == true then
                self.learned[#self.learned + 1] = id; break
            end
        end
    end
    -- Recover glows already active when enabling/reloading, even off the action bar.
    local book = C_SpellBook
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    local count = Read(book and book.GetNumSpellBookSkillLines)
    if not Number(bank) or not Number(count) or count < 0 or count > 32 or count % 1 ~= 0 then return end
    for line = 1, count do
        local info = Read(book.GetSpellBookSkillLineInfo, line)
        if Table(info) and Number(info.itemIndexOffset) and Number(info.numSpellBookItems)
            and info.itemIndexOffset >= 0 and info.itemIndexOffset <= 4096 and info.itemIndexOffset % 1 == 0
            and info.numSpellBookItems >= 0 and info.numSpellBookItems <= 512 and info.numSpellBookItems % 1 == 0 then
            for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
                local entry = Read(book.GetSpellBookItemInfo, slot, bank)
                if Table(entry) and ID(entry.spellID)
                    and Read(C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed, entry.spellID) == true then
                    self.glows[entry.spellID] = true
                end
            end
        end
    end
end

function Alerts:CaptureCooldownFlags()
    -- isOnGCD is only authoritative in response to SPELL_UPDATE_COOLDOWN.
    -- Keep that public event snapshot; never classify restricted numeric times.
    self.cooldownGCD = {}
    for _, id in ipairs(self.learned) do
        local info = Read(C_Spell and C_Spell.GetSpellCooldown, id)
        if Table(info) and Suite.IsReadable(info.isOnGCD) and info.isOnGCD == true then self.cooldownGCD[id] = true end
    end
end

function Alerts:Ready(id)
    local usable = Read(C_Spell and C_Spell.IsSpellUsable, id)
    if usable ~= true then return false, usable == false and "not usable" or "usability unavailable" end
    local cooldown = Read(C_Spell and C_Spell.GetSpellCooldown, id)
    if not Table(cooldown) then return false, "cooldown unavailable" end
    if Suite.IsReadable(cooldown.isEnabled) and cooldown.isEnabled == false then return false, "cooldown on hold" end
    -- These public flags are NeverSecret in the client's SpellCooldownInfo.
    -- An inactive cooldown needs no access to its potentially secret duration.
    if Suite.IsReadable(cooldown.isActive) and cooldown.isActive == false then return true, "ready" end
    if self.cooldownGCD[id] then return true, "ready during global cooldown" end
    if not Number(cooldown.duration) then return false, "cooldown timing unavailable" end
    if cooldown.duration == 0 then return true, "ready" end
    -- A global cooldown should not make an available reaction blink off.
    local gcd = Read(C_Spell and C_Spell.GetSpellCooldown, 61304)
    local global = Table(gcd) and Number(gcd.duration) and gcd.duration > 0
        and Number(gcd.startTime) and Number(cooldown.startTime)
        and gcd.startTime == cooldown.startTime and gcd.duration == cooldown.duration
    if global then return true, "ready during global cooldown" end
    local now = Read(GetTime)
    local delay
    -- A readable end time allows one precise wakeup, rather than waiting for
    -- an unrelated usable event. Nonstandard/restricted rates use event retries.
    if Number(now) and Number(cooldown.startTime) and cooldown.startTime >= 0 and cooldown.duration > 0
        and Suite.IsReadable(cooldown.modRate) and (cooldown.modRate == nil or Number(cooldown.modRate) and cooldown.modRate == 1) then
        local remaining = cooldown.startTime + cooldown.duration - now
        if remaining > 0 and remaining <= 60 then delay = remaining + 0.05 end
    end
    return false, "cooldown active", delay
end

function Alerts:Record(id, reason)
    if self.lastChecks[id] == reason then return end
    self.lastChecks[id] = reason
    self.history[#self.history + 1] = tostring(id) .. ": " .. reason .. " (" .. (self.lastEvent or "refresh") .. ")"
    if #self.history > 24 then table.remove(self.history, 1) end
end

function Alerts:Entries()
    local ids, seen = {}, {}
    for id in pairs(self.glows) do
        local overlay = Read(C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed, id)
        -- Keep the event candidate until GLOW_HIDE. A show event may precede
        -- query readiness; deleting it here would defeat the bounded retries.
        if overlay == true or not C_SpellActivationOverlay or type(C_SpellActivationOverlay.IsSpellOverlayed) ~= "function" then
            ids[#ids + 1] = id; seen[id] = true
        end
    end
    for _, id in ipairs(self.learned) do
        local ready, reason, delay = self:Ready(id)
        self:Record(id, reason)
        if delay and (not self.nextWake or delay < self.nextWake) then self.nextWake = delay end
        if not seen[id] and ready then ids[#ids + 1] = id end
    end
    table.sort(ids)
    local entries, names = {}, {}
    for _, id in ipairs(ids) do
        local info = Read(C_Spell and C_Spell.GetSpellInfo, id)
        if Table(info) and Suite.IsReadable(info.name) and type(info.name) == "string" and info.name ~= ""
            and ID(info.iconID) and not names[info.name] then
            entries[#entries + 1] = { id = id, name = info.name, icon = info.iconID }
            names[info.name] = true
        elseif not Table(info) and not self.requested[id] and C_Spell and type(C_Spell.RequestLoadSpellData) == "function" then
            self.requested[id] = true
            pcall(C_Spell.RequestLoadSpellData, id)
        end
    end
    return entries
end

function Alerts:Paint()
    if not self.frame then return end
    -- This is a fixed input policy, never a saved option: only the out-of-combat
    -- placement preview accepts mouse input. Live icons and empty space pass it on.
    local preview = self.preview == true and not InCombatLockdown()
    self.frame:EnableMouse(preview)
    self.frame:EnableMouseWheel(false)
    self.nextWake = nil
    local entries = {}
    if preview then entries = { { name = "Ability available", icon = 132223 } }
    elseif Enabled() and self.active and not self.suspended and Read(InCombatLockdown) == true then entries = self:Entries() end
    for index, cell in ipairs(self.cells) do
        local entry = entries[index]
        if entry then
            -- These cells are ordinary unprotected frames. Only public entry counts
            -- drive layout; no native/secret visibility is inspected.
            cell:ClearAllPoints()
            cell:SetPoint("TOP", self.frame, "TOP", (index - (math.min(#entries, #self.cells) + 1) / 2) * (self.stride or 110), 0)
            cell.icon:SetTexture(entry.icon); cell.name:SetText(entry.name)
            cell:Show()
            self:SetGlow(cell, true)
        else self:SetGlow(cell, false); cell:Hide() end
    end
    self.frame:SetShown(#entries > 0)
    self:WakeAtCooldownEnd(self.nextWake)
end

function Alerts:Cancel()
    if self.timer then self.timer:Cancel(); self.timer = nil end
    if self.followTimer then self.followTimer:Cancel(); self.followTimer = nil end
    if self.cooldownTimer then self.cooldownTimer:Cancel(); self.cooldownTimer = nil end
    self.followWork, self.followAt, self.cooldownWork, self.cooldownAt = nil, nil, nil, nil
    self.work = nil
end

function Alerts:Followup()
    if not self.active or not Enabled() or self.suspended or (#self.learned == 0 and not next(self.glows))
        or Read(InCombatLockdown) ~= true or not C_Timer or type(C_Timer.NewTimer) ~= "function" then return end
    if self.followTimer then
        local now = Read(GetTime)
        if not Number(now) or not Number(self.followAt) or self.followAt <= now + 0.081 then return end
        -- Fresh activity may advance a distant retry, but can never postpone one.
        self.followTimer:Cancel(); self.followTimer, self.followWork = nil, nil
    end
    -- Four checks at 80ms, 200ms, 500ms and 1.5s after a real event.
    -- New events coalesce with an existing burst instead of postponing it.
    local steps, index, work = { 0.08, 0.12, 0.30, 1.0 }, 1, {}
    self.followWork = work
    local function Schedule()
        local now = Read(GetTime)
        self.followAt = Number(now) and now + steps[index] or nil
        self.followTimer = C_Timer.NewTimer(steps[index], function()
            if self.followWork ~= work then return end
            self.followTimer, self.followAt = nil, nil
            if not self.active or not Enabled() or self.suspended or Read(InCombatLockdown) ~= true then
                self.followWork = nil; return
            end
            self.lastEvent = "event follow-up"; self:Paint()
            index = index + 1
            if steps[index] then Schedule() else self.followWork = nil end
        end)
    end
    Schedule()
end

function Alerts:WakeAtCooldownEnd(delay)
    local now = Read(GetTime)
    if not Number(delay) or not Number(now) then
        if self.cooldownTimer then self.cooldownTimer:Cancel(); self.cooldownTimer = nil end
        self.cooldownWork, self.cooldownAt = nil, nil; return
    end
    local at = now + delay
    if self.cooldownTimer and math.abs(at - self.cooldownAt) < 0.02 then return end
    if self.cooldownTimer then self.cooldownTimer:Cancel(); self.cooldownTimer = nil end
    self.cooldownWork, self.cooldownAt = nil, nil
    if not C_Timer or type(C_Timer.NewTimer) ~= "function" then return end
    local work = {}; self.cooldownWork, self.cooldownAt = work, at
    self.cooldownTimer = C_Timer.NewTimer(delay, function()
        if self.cooldownWork ~= work then return end
        self.cooldownTimer, self.cooldownWork, self.cooldownAt = nil, nil, nil
        if not self.active or not Enabled() or self.suspended or Read(InCombatLockdown) ~= true then return end
        self.lastEvent = "cooldown end"; self:Paint(); self:Followup()
    end)
end

function Alerts:Queue()
    if self.timer or not self.active then return end
    if not C_Timer or type(C_Timer.NewTimer) ~= "function" then self:Paint(); return end
    local work = {}; self.work = work
    self.timer = C_Timer.NewTimer(0.03, function()
        if self.work ~= work then return end
        self.work, self.timer = nil, nil; self:Paint()
    end)
end

function Alerts:Place()
    if not self.frame or InCombatLockdown() then return end
    local saved = Suite.db.procAlertPosition
    local x, y = 0, 100
    if Table(saved) and Number(saved.x) and Number(saved.y) and math.abs(saved.x) <= 0.5 and math.abs(saved.y) <= 0.5 then
        local width, height = Read(UIParent.GetWidth, UIParent), Read(UIParent.GetHeight, UIParent)
        if Number(width) and Number(height) and width > 0 and height > 0 then x, y = saved.x * width, saved.y * height end
    end
    self.frame:ClearAllPoints(); self.frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
end

function Alerts:StopDrag(save)
    if not self.moving then return end
    self.frame:StopMovingOrSizing(); self.moving = nil
    if save and not InCombatLockdown() then
        local ok, x, y = pcall(self.frame.GetCenter, self.frame)
        local scale, parentScale = Read(self.frame.GetEffectiveScale, self.frame), Read(UIParent.GetEffectiveScale, UIParent)
        local width, height = Read(UIParent.GetWidth, UIParent), Read(UIParent.GetHeight, UIParent)
        if ok and Number(x) and Number(y) and Number(scale) and Number(parentScale) and scale > 0 and parentScale > 0
            and Number(width) and Number(height) and width > 0 and height > 0 then
            Suite.db.procAlertPosition = { x = math.max(-0.5, math.min(0.5, x * scale / parentScale / width - 0.5)),
                y = math.max(-0.5, math.min(0.5, y * scale / parentScale / height - 0.5)) }
        end
    end
    Suite.AfterCombat("procAlertPosition", function() self:Place() end)
end

function Alerts:Build()
    if self.frame then return true end
    if InCombatLockdown() then return false end
    local frame = CreateFrame("Frame", nil, UIParent)
    self.frame = frame
    frame:Hide(); frame:SetSize(180, 60); frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(false)
    frame:RegisterForDrag("LeftButton")
    self.events = CreateFrame("Frame")
    self.events:SetScript("OnEvent", function(_, event, ...) self:OnEvent(event, ...) end)
    frame:SetScript("OnDragStart", function()
        if self.preview and not InCombatLockdown() then self.moving = true; frame:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function() self:StopDrag(true) end)
    -- All frames and font regions are prepared outside combat.
    for index = 1, 8 do
        local cell = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        cell:SetSize(42, 42); cell:EnableMouse(false); cell:EnableMouseWheel(false)
        cell:SetPoint("TOP", frame, "TOP", 0, 0)
        cell:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        cell:SetBackdropColor(0.035, 0.05, 0.065, 0.9); Suite.Theme:Backdrop(cell, 1)
        cell.icon = cell:CreateTexture(nil, "ARTWORK")
        cell.icon:SetPoint("TOPLEFT", cell, "TOPLEFT", 2, -2); cell.icon:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -2, 2)
        cell.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        cell.name = cell:CreateFontString(nil, "OVERLAY")
        cell.name:SetPoint("TOP", cell, "BOTTOM", 0, -4); cell.name:SetWidth(104)
        cell.name:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        cell.name:SetTextColor(0.6, 1, 0.85)
        self:BuildGlow(cell)
        cell:Hide(); self.cells[index] = cell
    end
    self:ConfigureSize(); self:Place(); return true
end

function Alerts:Watch()
    if not self.events then return end
    self.events:UnregisterAllEvents()
    if not self.active and not self.preview then return end
    for _, event in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD" }) do
        self.events:RegisterEvent(event)
    end
    if not self.active then return end
    for _, event in ipairs({ "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE",
        "SPELL_UPDATE_USABLE", "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_USES", "ACTION_USABLE_CHANGED",
        "SPELLS_CHANGED", "PLAYER_TARGET_CHANGED", "UPDATE_SHAPESHIFT_FORM", "SPELL_DATA_LOAD_RESULT" }) do
        self.events:RegisterEvent(event)
    end
    for _, event in ipairs({ "UNIT_COMBAT", "UNIT_POWER_UPDATE", "UNIT_SPELLCAST_SUCCEEDED" }) do
        if type(self.events.RegisterUnitEvent) == "function" then
            if event == "UNIT_COMBAT" then self.events:RegisterUnitEvent(event, "player", "target")
            else self.events:RegisterUnitEvent(event, "player") end
        else self.events:RegisterEvent(event) end
    end
end

function Alerts:SetPreview(show)
    if InCombatLockdown() then return end
    if not show and not self.preview then return end
    if not self:Build() then return end
    self:ConfigureSize()
    self:StopDrag(false); self.preview = show and true or nil
    self:Watch(); self:Paint()
end

function Alerts:ResetPosition()
    if InCombatLockdown() then return end
    self:StopDrag(false); Suite.db.procAlertPosition = {}; self:Place()
end

function Alerts:OnEvent(event, id)
    -- Unit combat is only a request to refresh public spell availability. Do not
    -- read its damage/miss payload or invent a dodge window from other attacks.
    if event == "UNIT_COMBAT" or event == "UNIT_POWER_UPDATE" or event == "UNIT_SPELLCAST_SUCCEEDED" then
        if not Suite.IsReadable(id) or type(id) ~= "string" then return end
        if id ~= "player" and not (event == "UNIT_COMBAT" and id == "target") then return end
    end
    self.lastEvent = event
    if event == "PLAYER_REGEN_DISABLED" then
        self:Cancel(); self.cooldownGCD, self.history, self.lastChecks = {}, {}, {}
        self:StopDrag(false); self.preview = nil
        self:Watch(); self:Paint(); self:Followup(); return
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:Cancel(); self.cooldownGCD = {}; self:Paint(); return
    elseif event == "PLAYER_LEAVING_WORLD" or event == "PLAYER_ENTERING_WORLD" then
        self:Cancel(); self.glows, self.cooldownGCD = {}, {}; self.suspended = event == "PLAYER_LEAVING_WORLD"
        self:StopDrag(false); self.preview = nil
        if not self.suspended then self:Scan() end
        self:Watch(); self:Paint(); self:Followup(); return
    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" or event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
        if not ID(id) then return end
        self.glows[id] = event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" or nil
    elseif event == "SPELLS_CHANGED" then self:Scan()
    elseif event == "SPELL_UPDATE_COOLDOWN" then self:CaptureCooldownFlags() end
    self:Queue()
    if event ~= "SPELL_DATA_LOAD_RESULT" then self:Followup() end
end

function Alerts:Status()
    Suite.Print("Proc popups: " .. (Enabled() and "enabled" or "disabled") .. "; "
        .. (self.active and "prepared" or "not prepared") .. "; reactive skills: " .. #self.learned .. ".")
    for _, id in ipairs(self.learned) do
        local info = Read(C_Spell and C_Spell.GetSpellInfo, id)
        local metadata = Table(info) and Suite.IsReadable(info.name) and type(info.name) == "string" and info.name ~= "" and ID(info.iconID)
        Suite.Print("Spell " .. id .. ": " .. (self.lastChecks[id] or "not checked in combat")
            .. "; icon data: " .. (metadata and "ready" or "unavailable") .. ".")
    end
    if #self.history == 0 then Suite.Print("No combat availability changes recorded this session."); return end
    Suite.Print("Recent public availability changes from the latest fight:")
    for _, line in ipairs(self.history) do Suite.Print(line) end
end

function Alerts:Apply()
    if not Enabled() then
        self.active, self.preview = nil, nil; self.glows, self.cooldownGCD = {}, {}
        self:Cancel(); self:StopDrag(false)
        self:Watch(); self:Paint(); return
    end
    Suite.AfterCombat("procAlerts", function()
        if not Enabled() or not self:Build() then return end
        self.active = true; self:ConfigureSize(); self:Scan(); self:Place(); self:Watch(); self:Paint()
    end)
end
