local _, Suite = ...
local Timers = Suite.ReminderTimers
local Alerts = { glows = {}, learned = {}, reactions = {}, cells = {}, requested = {}, cooldownGCD = {}, history = {}, lastChecks = {} }
Suite.ProcAlerts = Alerts
Suite.modules[#Suite.modules + 1] = Alerts

-- Legacy reactive skills do not necessarily generate native overlay glows.
-- Rank IDs follow the Forever training catalog; talent roots are included too.
local overpowerRanks = { 7384, 7887, 11584, 11585 }
local revengeRanks = { 6572, 6574, 7379, 11600, 11601 }
local shadowBoltRanks = { 686, 695, 705, 1088, 1106, 7641, 11659, 11660, 11661, 25307 }
local reactive = {
    overpowerRanks,
    revengeRanks,
    { 14251 }, -- Riposte
    { 1495, 14269, 14270, 14271 }, -- Mongoose Bite
    { 19306, 1242634, 20909, 20910 }, -- Counterattack
    shadowBoltRanks, -- Nightfall
}
local reactiveByRank = {}
for _, family in ipairs(reactive) do
    for _, rank in ipairs(family) do reactiveByRank[rank] = family end
end
local OVERPOWER_AURA, OVERPOWER_WINDOW = 1282733, 5
local REACTION_WINDOW, SHADOW_TRANCE = 5, 17941
local VICTORY_RUSH, VICTORIOUS, VICTORY_WINDOW = 402927, 402975, 20
local AURA_CLIP = "DisableUntrustedLayoutScriptsTemplate"
local function Read(callback, ...)
    if type(callback) ~= "function" then return end
    local ok, value = pcall(callback, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function ID(value) return Number(value) and value > 0 and value % 1 == 0 end
local function IsOverpower(id)
    return ID(id) and reactiveByRank[id] == overpowerRanks
end
local function ReactionOverlay(family, glows)
    local query = C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed
    for _, rank in ipairs(family) do
        if Read(query, rank) == true or type(query) ~= "function" and glows[rank] then return true end
    end
    return false
end
local function Enabled() return Suite.db and Suite.db.procAlerts == true end
local function Table(value) return Suite.IsReadable(value) and type(value) == "table" end
local function PlayerProcAura(id, now)
    if C_Secrets and type(C_Secrets.ShouldSpellAuraBeSecret) == "function" then
        if Read(C_Secrets.ShouldSpellAuraBeSecret, id) ~= false then return false end
    elseif C_Secrets and type(C_Secrets.HasSecretRestrictions) == "function"
        and Read(C_Secrets.HasSecretRestrictions) ~= false then return false end
    local aura = Read(C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID, id)
    if not Table(aura) then return false end
    local expires = aura.expirationTime
    if not Number(expires) or not Number(now) or expires == 0 then return true end
    if expires > now then return true, expires end
    return false
end
local function Usability(id)
    if not C_Spell or type(C_Spell.IsSpellUsable) ~= "function" then return end
    local ok, usable, insufficientPower = pcall(C_Spell.IsSpellUsable, id)
    if not ok or not Suite.IsReadable(usable) or type(usable) ~= "boolean" then return end
    -- The second result distinguishes a resource shortage from a lost reaction.
    return usable, Suite.IsReadable(insufficientPower) and insufficientPower == true
end

local warriorFormIDs = { [17] = "Battle", [18] = "Defensive", [19] = "Berserker" }
local warriorFormSlots = { "Battle", "Defensive", "Berserker" }
local function WarriorStance()
    local form = Read(GetShapeshiftFormID)
    if Number(form) then return warriorFormIDs[form] end
    local slot = Read(GetShapeshiftForm)
    if Number(slot) then return warriorFormSlots[slot] end
end

local function OutsideBattleStance(stance)
    return stance == "Defensive" or stance == "Berserker"
end
local function AllowsProc(id, stance)
    if stance == "Defensive" then return true end
    for _, rank in ipairs(revengeRanks) do if id == rank then return false end end
    return true
end

function Alerts:IconSize(db)
    local value = (db or Suite.db or Suite.defaults).procAlertIconSize
    return Number(value) and math.max(24, math.min(128, math.floor(value + 0.5))) or 42
end

function Alerts:ConfigureSize()
    if not self.frame or InCombatLockdown() then return end
    local size = self:IconSize()
    self.stride = math.max(110, size * 1.4 + 18)
    self.frame:SetSize(math.max(180, self.stride), size + 18)
    if self.victoryAura then
        self.victoryAura.host:SetScale(size / 42)
        self.victoryAura.x = nil
    end
    for _, cell in ipairs(self.cells) do
        cell:SetSize(size, size)
        cell.name:SetWidth(self.stride - 6)
        cell.name:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", math.max(10, math.min(18, math.floor(12 * size / 42 + 0.5))), "OUTLINE")
        cell.countdown:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", math.max(12, math.floor(size * 0.46)), "OUTLINE")
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
    self.victorySlot, self.victoryActionGCD = nil, nil
    self.learned, self.cooldownGCD = {}, {}
    self.overpowerID = nil
    self.victoryRush = Read(C_SpellBook and C_SpellBook.IsSpellKnown, VICTORY_RUSH) == true
    for _, family in ipairs(reactive) do
        for index = #family, 1, -1 do
            local id = family[index]
            if Read(C_SpellBook and C_SpellBook.IsSpellKnown, id) == true then
                self.learned[#self.learned + 1] = id
                if family == overpowerRanks then self.overpowerID = id end
                break
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

function Alerts:VictoryActionSlot()
    if self.victorySlot ~= nil then return self.victorySlot or nil end
    self.victorySlot = false
    local slots = Read(C_ActionBar and C_ActionBar.FindSpellActionButtons, VICTORY_RUSH)
    if Table(slots) and ID(slots[1]) then self.victorySlot = slots[1] end
    return self.victorySlot or nil
end

function Alerts:CaptureCooldownFlags()
    -- isOnGCD is only authoritative in response to SPELL_UPDATE_COOLDOWN.
    -- Keep that public event snapshot; never classify restricted numeric times.
    self.cooldownGCD = {}
    local function Capture(id)
        local info = Read(C_Spell and C_Spell.GetSpellCooldown, id)
        if Table(info) and Suite.IsReadable(info.isOnGCD) and type(info.isOnGCD) == "boolean" then
            self.cooldownGCD[id] = info.isOnGCD
        end
    end
    for _, id in ipairs(self.learned) do Capture(id) end
    for id in pairs(self.glows) do Capture(id) end
    if self.victoryRush then
        Capture(VICTORY_RUSH)
        local slot = self:VictoryActionSlot()
        local info = slot and Read(C_ActionBar and C_ActionBar.GetActionCooldown, slot)
        self.victoryActionGCD = nil
        if Table(info) and Suite.IsReadable(info.isOnGCD) and type(info.isOnGCD) == "boolean" then
            self.victoryActionGCD = info.isOnGCD
        end
    end
end

function Alerts:Ready(id)
    local usable, insufficientPower = Usability(id)
    if usable ~= true and not insufficientPower then return false, usable == false and "not usable" or "usability unavailable" end
    local reason = insufficientPower and usable == false and "available; insufficient power" or "ready"
    return self:CooldownReady(id, reason)
end

function Alerts:CooldownReady(id, reason)
    local cooldown = Read(C_Spell and C_Spell.GetSpellCooldown, id)
    if not Table(cooldown) then return false, "cooldown unavailable" end
    if Suite.IsReadable(cooldown.isEnabled) and cooldown.isEnabled == false then return false, "cooldown on hold" end
    -- These public flags are NeverSecret in the client's SpellCooldownInfo.
    -- An inactive cooldown needs no access to its potentially secret duration.
    if Suite.IsReadable(cooldown.isActive) and cooldown.isActive == false then return true, reason end
    if self.cooldownGCD[id] then return true, reason .. " during global cooldown" end
    if not Number(cooldown.duration) then return false, "cooldown timing unavailable" end
    if cooldown.duration == 0 then return true, reason end
    -- A global cooldown should not make an available reaction blink off.
    local gcd = Read(C_Spell and C_Spell.GetSpellCooldown, 61304)
    local global = Table(gcd) and Number(gcd.duration) and gcd.duration > 0
        and Number(gcd.startTime) and Number(cooldown.startTime)
        and gcd.startTime == cooldown.startTime and gcd.duration == cooldown.duration
    if global then return true, reason .. " during global cooldown" end
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

function Alerts:VictoryRush(now, onCooldown)
    local usable = Usability(VICTORY_RUSH)
    local active, expires = PlayerProcAura(VICTORIOUS, now)
    local overlay = Read(C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed, VICTORY_RUSH) == true
    local consumed = self.victoryConsumed
    if consumed then
        -- The previous opening may still be reported briefly after the cast.
        local freshAura = expires and (not consumed.hadAura or consumed.expiry and expires > consumed.expiry)
        if freshAura or not active and not overlay and usable ~= true then self.victoryConsumed = nil
        else return false, nil, nil, "opening consumed" end
    end
    if expires then
        self.victoryUntil, self.victoryEstimated = expires, nil
    elseif not active and not overlay and usable ~= true then
        self.victoryUntil, self.victoryEstimated = nil, nil
    elseif not self.victoryUntil and Number(now) then
        self.victoryUntil, self.victoryEstimated = now + VICTORY_WINDOW, true
    end
    if not active and not overlay and usable ~= true then return false, nil, nil, "no confirmed opening" end
    local ready, cooldown, delay = self:CooldownReady(VICTORY_RUSH, "ready")
    -- A confirmed window drives visibility even if the action is unavailable
    -- or the client only permits the cooldown to be drawn by a widget.
    local glow = not onCooldown and ready and usable == true
    local reason = onCooldown and "opening during cooldown"
        or glow and cooldown or active and "Victorious active" or overlay and "native activation" or "usable; " .. cooldown
    local untilTime = self.victoryUntil
    if untilTime and Number(now) then
        if untilTime > now then return true, untilTime, delay, reason, glow end
        if not self.victoryEstimated then return false, nil, nil, "Victorious expired" end
    end
    return true, nil, delay, reason, glow
end

function Alerts:Record(id, reason)
    if self.lastChecks[id] == reason then return end
    self.lastChecks[id] = reason
    self.history[#self.history + 1] = tostring(id) .. ": " .. reason .. " (" .. (self.lastEvent or "refresh") .. ")"
    if #self.history > 24 then table.remove(self.history, 1) end
end

function Alerts:ClearOverpower()
    self.overpowerObserved, self.overpowerUntil, self.overpowerNoticeUntil, self.overpowerAuraEnd = nil, nil, nil, nil
end

function Alerts:Overpower(confirmed, now, stance)
    local active, expires = PlayerProcAura(OVERPOWER_AURA, now)
    local consumed = self.overpowerConsumed
    if consumed then
        -- A cast can be reported before Blizzard clears the old aura, glow or
        -- usability. Admit a fresh timed aura, or wait for those signals to clear.
        local freshAura = expires and (not consumed.hadAura or consumed.expiry and expires > consumed.expiry)
        if freshAura or not active and not confirmed then self.overpowerConsumed = nil
        else return false end
    end
    self.overpowerAuraEnd = expires
    if expires then
        self.overpowerObserved, self.overpowerUntil = true, expires
        return true, expires
    end
    if Number(now) and self.overpowerNoticeUntil and self.overpowerNoticeUntil > now then
        return true, self.overpowerNoticeUntil
    end
    local otherStance = OutsideBattleStance(stance)
    if confirmed or active then
        if not self.overpowerObserved and Number(now) then self.overpowerUntil = now + OVERPOWER_WINDOW end
        self.overpowerObserved = true
    elseif not otherStance or not self.overpowerUntil or not Number(now) or self.overpowerUntil <= now then
        self.overpowerObserved, self.overpowerUntil = nil, nil
    end
    local untilTime = self.overpowerUntil
    if not untilTime or not Number(now) or untilTime <= now then return false end
    return confirmed or active or otherStance == true, untilTime
end

function Alerts:ReactionCombatText()
    if not InCombatLockdown() or not C_CombatText
        or Read(C_CombatText.GetActiveUnit) ~= "player" then return end
    -- SPELL_ACTIVE describes a named activation for the watched unit. Read it
    -- during the synchronous event and ignore restricted payloads.
    local spell = Read(C_CombatText.GetCurrentEventInfo)
    if type(spell) ~= "string" then return end
    local now = Read(GetTime)
    if not Number(now) then return end
    local stance = WarriorStance()
    for _, id in ipairs(self.learned) do
        local info = Read(C_Spell and C_Spell.GetSpellInfo, id)
        if reactiveByRank[id] ~= shadowBoltRanks and AllowsProc(id, stance)
            and Table(info) and Suite.IsReadable(info.name) and spell == info.name then
            if id == self.overpowerID then
                self.overpowerConsumed = nil
                self.overpowerNoticeUntil = now + OVERPOWER_WINDOW
            else
                self.reactions[id] = { notice = now + REACTION_WINDOW }
            end
            self.lastEvent = "reaction combat text"
            self:Queue()
            return
        end
    end
end

function Alerts:ReactiveOpening(id, now, allowUsability)
    local family = reactiveByRank[id]
    if not family then return false end
    local nightfall = family == shadowBoltRanks
    local aura, expires = PlayerProcAura(nightfall and SHADOW_TRANCE or id, now)
    local usable, missingPower = Usability(id)
    -- Shadow Bolt is ordinarily castable. Only its proc aura or native alert
    -- can confirm the Nightfall window.
    local active = aura or ReactionOverlay(family, self.glows) or not nightfall and allowUsability and (usable == true or missingPower)
    local state = self.reactions[id]
    if active or state and state.notice and Number(now) and state.notice > now then
        state = state or {}
        if state.consumed and (not expires or state.auraExpiry and expires <= state.auraExpiry) then return false end
        state.consumed, state.auraExpiry = nil, expires
        state.expiry = expires or state.notice or state.expiry
        if not state.expiry and not nightfall and Number(now) then state.expiry = now + REACTION_WINDOW end
        self.reactions[id] = state
        return not state.expiry or Number(now) and state.expiry > now, state.expiry
    end
    self.reactions[id] = nil
    return false
end

function Alerts:Entries(inCombat)
    local ids, seen, expiry, recharging = {}, {}, {}, {}
    local now = Read(GetTime)
    local stance = inCombat and WarriorStance()
    local victorySlot, victoryGlow
    local function Add(id)
        if not seen[id] and AllowsProc(id, stance) then ids[#ids + 1] = id; seen[id] = true end
    end
    local function Wake(delay, cooldown)
        if delay and (not self.nextWake or delay < self.nextWake) then
            self.nextWake, self.nextWakeCooldown = delay, cooldown
        end
    end
    local function CheckCooldown(id)
        local slot = id == VICTORY_RUSH and victorySlot or nil
        local active, delay = Timers:ActiveSpellCooldown(id, self.cooldownGCD[id], self.cells[1] and self.cells[1].cooldownSwipe,
            slot, slot and self.victoryActionGCD)
        recharging[id] = active
        Wake(delay, true)
        return active
    end
    if inCombat then
        for id in pairs(self.glows) do
            local overlay = Read(C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed, id)
            -- Keep the event candidate until GLOW_HIDE. A show event may precede
            -- query readiness; deleting it here would defeat the bounded retries.
            if overlay == true or not C_SpellActivationOverlay or type(C_SpellActivationOverlay.IsSpellOverlayed) ~= "function" then
                if id ~= VICTORY_RUSH and not reactiveByRank[id] then Add(id) end
            end
        end
        for _, id in ipairs(self.learned) do
            if AllowsProc(id, stance) then
                local ready, reason, delay = self:Ready(id)
                Wake(delay, true)
                if id == self.overpowerID then
                    local usable, missingPower = Usability(id)
                    local confirmed = reason ~= "cooldown on hold" and (usable == true or missingPower)
                    local overlay = ReactionOverlay(overpowerRanks, self.glows)
                    local available, expires = self:Overpower(confirmed or overlay, now, stance)
                    expiry[id] = expires
                    if not ready and available then reason = "opening shown" end
                    reason = reason .. " [" .. (stance or "stance unavailable") .. "]"
                    ready = available
                else
                    local available, expires = self:ReactiveOpening(id, now, reason ~= "cooldown on hold")
                    expiry[id] = expires
                    if not ready and available then reason = "opening shown" end
                    ready = available
                end
                self:Record(id, reason)
                if ready then Add(id) end
            else
                self:Record(id, "Defensive Stance only")
            end
        end
    end
    if self.victoryRush then
        victorySlot = self:VictoryActionSlot()
        local onCooldown = CheckCooldown(VICTORY_RUSH)
        self.victoryCooldownConfirmed = onCooldown
        local ready, expires, delay, reason, glow = self:VictoryRush(now, onCooldown)
        self:Record(VICTORY_RUSH, reason)
        Wake(delay, true)
        if ready then
            Add(VICTORY_RUSH)
            expiry[VICTORY_RUSH] = expires
            victoryGlow = glow == true
        end
    end
    table.sort(ids)
    local entries, names = {}, {}
    for _, id in ipairs(ids) do
        if recharging[id] == nil then CheckCooldown(id) end
        local info = Read(C_Spell and C_Spell.GetSpellInfo, id)
        if Table(info) and Suite.IsReadable(info.name) and type(info.name) == "string" and info.name ~= ""
            and ID(info.iconID) and not names[info.name] then
            local usable, insufficientPower = Usability(id)
            local untilTime = expiry[id]
            if not reactiveByRank[id] and id ~= VICTORY_RUSH then
                local _, auraExpiry = PlayerProcAura(id, now)
                untilTime = auraExpiry
            end
            local remaining = untilTime and untilTime - now
            local seconds = remaining and remaining > 0 and math.ceil(remaining)
            if seconds then Wake(math.max(0.02, remaining - seconds + 1)) end
            local countdown = seconds and tostring(seconds)
            entries[#entries + 1] = { id = id, name = info.name, icon = info.iconID, countdown = countdown, recharging = recharging[id],
                actionSlot = id == VICTORY_RUSH and victorySlot or nil, suppressGlow = id == VICTORY_RUSH and not victoryGlow,
                insufficientPower = usable == false and insufficientPower == true }
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
    self.nextWake, self.nextWakeCooldown = nil, nil
    local entries = {}
    if preview then entries = { { name = "Ability available", icon = 132223 } }
    elseif Enabled() and self.active and not self.suspended then entries = self:Entries(Read(InCombatLockdown) == true) end
    local native = self.victoryAura
    local useNative = native and Enabled() and self.active and self.victoryRush and not self.suspended
        and not self.victoryConsumed and not preview and InCombatLockdown()
    local nativeX, nativeY = 0, #entries > 0 and -(self:IconSize() + 22) or 0
    for index, cell in ipairs(self.cells) do
        local entry = entries[index]
        if entry then
            local x = (index - (math.min(#entries, #self.cells) + 1) / 2) * (self.stride or 110)
            if entry.id == VICTORY_RUSH then
                if entry.countdown and not self.victoryEstimated then useNative = false end
                nativeX, nativeY = x, 0
            end
            -- These cells are ordinary unprotected frames. Only public entry counts
            -- drive layout; no native/secret visibility is inspected.
            cell:ClearAllPoints()
            cell:SetPoint("TOP", self.frame, "TOP", x, 0)
            cell.icon:SetTexture(entry.icon); cell.name:SetText(entry.name)
            cell.countdown:SetText(entry.countdown or "")
            Timers:UpdateCooldown(cell, entry.id, self.cooldownGCD[entry.id], false,
                self.repaintCooldowns or entry.id == VICTORY_RUSH and self.repaintVictory, entry.actionSlot)
            -- Match the native action bar's insufficient-power tint; always reset
            -- on reuse so recovered resources and previews regain full brightness.
            if entry.insufficientPower then cell.icon:SetVertexColor(0.5, 0.5, 1)
            else cell.icon:SetVertexColor(1, 1, 1) end
            cell:Show()
            self:SetGlow(cell, not entry.recharging and not entry.suppressGlow)
        else Timers:UpdateCooldown(cell); self:SetGlow(cell, false); cell:Hide() end
    end
    if native then
        if useNative then
            -- The container supplies the mask even when aura identity and time
            -- are private. Only public rows influence the anchor of its host.
            if native.x ~= nativeX or native.y ~= nativeY then
                native.x, native.y = nativeX, nativeY
                native.host:ClearAllPoints()
                local scale = self:IconSize() / 42
                native.host:SetPoint("TOP", self.frame, "TOP", nativeX / scale, nativeY / scale)
            end
            Timers:UpdateCooldown(native.plate, VICTORY_RUSH, self.cooldownGCD[VICTORY_RUSH], false,
                self.repaintCooldowns or self.repaintVictory, self:VictoryActionSlot())
        else Timers:UpdateCooldown(native.plate) end
        native.host:SetShown(useNative == true)
    end
    self.frame:SetShown(#entries > 0 or useNative == true)
    self.repaintCooldowns, self.repaintVictory = nil, nil
    self:WakeAtCooldownEnd(self.nextWake)
end

function Alerts:PrepareVictoryAura()
    if not self.victoryRush or self.victoryAura or self.victoryAuraFailed or InCombatLockdown()
        or not self.frame or not C_AddOns or not C_AddOns.LoadAddOn then return end
    pcall(C_AddOns.LoadAddOn, "Blizzard_AuraContainer")
    if not CustomAuraContainerAuraProcessingPolicy or not AuraContainerSortMethod or not AuraContainerSortDirection then return end
    local info = Read(C_Spell and C_Spell.GetSpellInfo, VICTORY_RUSH)
    if not Table(info) or not ID(info.iconID) or not Suite.IsReadable(info.name) or type(info.name) ~= "string" then return end
    local host = CreateFrame("Frame", nil, self.frame, AURA_CLIP)
    host:SetSize(42, 42); host:EnableMouse(false); host:Hide()
    host:SetFrameLevel(self.frame:GetFrameLevel() + 5)
    host:SetScale(self:IconSize() / 42)
    local container
    local ok, failure = pcall(function()
        container = CreateFrame("AuraContainer", nil, host, "CustomAuraContainerTemplate")
        container:SetEnabled(false); container:SetEditModePreviewEnabled(false)
        container:SetAuraProcessingPolicy(CustomAuraContainerAuraProcessingPolicy.None)
        container:SetUnit("player"); container:SetPoint("TOPLEFT", host, "TOPLEFT")
        local clip = CreateFrame("Frame", nil, host, AURA_CLIP)
        clip:EnableMouse(false); clip:SetClipsChildren(true)
        clip:SetPoint("TOPLEFT", host, "TOPLEFT")
        -- Follow both native dimensions. A zero-width strip with a fixed
        -- height could still draw an edge when rounded to screen pixels.
        clip:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT")
        local plate = CreateFrame("Frame", nil, clip, "BackdropTemplate")
        plate:SetSize(40, 40); plate:SetPoint("TOPLEFT", clip, "TOPLEFT", 1, -1); plate:EnableMouse(false)
        plate:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        plate:SetBackdropColor(0.035, 0.05, 0.065, 0.9); Suite.Theme:Backdrop(plate, 1)
        plate.icon = plate:CreateTexture(nil, "ARTWORK")
        plate.icon:SetPoint("TOPLEFT", plate, "TOPLEFT", 2, -2)
        plate.icon:SetPoint("BOTTOMRIGHT", plate, "BOTTOMRIGHT", -2, 2)
        plate.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        plate.icon:SetTexture(info.iconID)
        Timers:Create(plate)
        container:SetFrameLevel(plate.cooldownSwipe:GetFrameLevel() + 1)
        container:AddAuraGroup("Victorious", "HELPFUL", {
            maxFrameCount = 1, candidateFilters = { includeSpellIDs = { VICTORIOUS } },
            layout = { elementWidth = 42, elementHeight = 42 },
            sortMethod = AuraContainerSortMethod.ExpirationOnly, sortDirection = AuraContainerSortDirection.Reverse,
            initializeFrame = function(button)
                button:EnableMouse(false); button:SetSize(42, 42)
                local font = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
                local caption = button:CreateFontString(nil, "OVERLAY")
                caption:SetPoint("TOP", button, "BOTTOM", 0, -4)
                caption:SetFont(font, 12, "OUTLINE"); caption:SetTextColor(0.6, 1, 0.85)
                caption:SetText(info.name)
                local remaining = button:CreateFontString(nil, "OVERLAY")
                remaining:SetPoint("CENTER", button, "CENTER")
                remaining:SetFont(font, 19, "OUTLINE"); remaining:SetTextColor(1, 0.94, 0.72)
                button:SetDurationText(remaining, {})
            end,
        })
        container:SetEnabled(true)
        self.victoryAura = { host = host, plate = plate }
    end)
    if not ok then
        if container then pcall(container.SetEnabled, container, false) end
        self.victoryAuraFailed = Suite.IsReadable(failure) and type(failure) == "string"
            and failure:gsub("[%c|]", " "):sub(1, 180) or "setup rejected"
    end
end

function Alerts:Cancel()
    if self.timer then self.timer:Cancel(); self.timer = nil end
    if self.followTimer then self.followTimer:Cancel(); self.followTimer = nil end
    if self.cooldownTimer then self.cooldownTimer:Cancel(); self.cooldownTimer = nil end
    self.followWork, self.followAt, self.cooldownWork, self.cooldownAt = nil, nil, nil, nil
    self.work = nil
end

function Alerts:Followup(victory)
    local allowOutsideCombat = victory and self.victoryRush
    if not self.active or not Enabled() or self.suspended or not C_Timer or type(C_Timer.NewTimer) ~= "function" then return end
    if not allowOutsideCombat and ((#self.learned == 0 and not next(self.glows) and not self.victoryRush)
        or Read(InCombatLockdown) ~= true) then return end
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
            if not self.active or not Enabled() or self.suspended
                or not allowOutsideCombat and Read(InCombatLockdown) ~= true then
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
        if not self.active or not Enabled() or self.suspended then return end
        local retry = self.nextWakeCooldown
        self.lastEvent = retry and "cooldown end" or "proc countdown"
        self:Paint()
        if retry then self:Followup(true) end
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
        Timers:Create(cell, 16)
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
    if type(self.events.RegisterUnitEvent) == "function" then self.events:RegisterUnitEvent("UNIT_AURA", "player")
    else self.events:RegisterEvent("UNIT_AURA") end
    if self.victoryRush then
        self.events:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
        self.events:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    end
    if #self.learned > 0 and C_CombatText and type(C_CombatText.GetCurrentEventInfo) == "function" then
        pcall(self.events.RegisterEvent, self.events, "COMBAT_TEXT_UPDATE")
    end
end

function Alerts:SetPreview(show)
    if InCombatLockdown() then return end
    if not show and not self.preview then return end
    if not self:Build() then return end
    self:ConfigureSize()
    self:StopDrag(false); self.preview = show and true or nil
    self:Watch(); self:Paint()
    if not show then Suite.GUI:EndWorldPreview(true, self) end
    return self.preview == true
end

function Alerts:ResetPosition()
    if InCombatLockdown() then return end
    self:StopDrag(false); Suite.db.procAlertPosition = {}; self:Place()
end

function Alerts:OnEvent(event, id, _, spellID)
    if event == "COMBAT_TEXT_UPDATE" then
        if Suite.IsReadable(id) and id == "SPELL_ACTIVE" then self:ReactionCombatText() end
        return
    end
    -- Unit combat is only a request to refresh public spell availability. Do not
    -- read its damage/miss payload or invent a dodge window from other attacks.
    if event == "UNIT_COMBAT" or event == "UNIT_POWER_UPDATE" or event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_AURA" then
        if not Suite.IsReadable(id) or type(id) ~= "string" then return end
        if id ~= "player" and not (event == "UNIT_COMBAT" and id == "target") then return end
    end
    if event == "UNIT_AURA" then
        if not self.victoryRush and (not InCombatLockdown() or #self.learned == 0 and not next(self.glows)) then return end
        self.lastEvent = event
        self.repaintVictory = self.victoryRush
        self:Queue(); self:Followup(true); return
    end
    if event == "ACTIONBAR_SLOT_CHANGED" or event == "ACTIONBAR_UPDATE_COOLDOWN" then
        if event == "ACTIONBAR_SLOT_CHANGED" then self.victorySlot, self.victoryActionGCD = nil, nil end
        self.lastEvent, self.repaintVictory = event, true
        self:Queue()
        return
    end
    if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        -- Victory Rush remains tracked across combat transitions. Keep the
        -- last authoritative GCD flag until the next cooldown event.
        self.cooldownGCD = { [VICTORY_RUSH] = self.cooldownGCD[VICTORY_RUSH] }
    end
    self.lastEvent = event
    if event == "PLAYER_REGEN_DISABLED" then
        self:Cancel(); self.history, self.lastChecks = {}, {}
        self:StopDrag(false); self.preview = nil
        self:Watch(); self:Paint(); self:Followup(); return
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:Cancel(); self:ClearOverpower(); self.overpowerConsumed = nil
        self.reactions = {}
        self:PrepareVictoryAura()
        self:Paint(); if self.victoryRush then self:Followup(true) end
        return
    elseif event == "PLAYER_LEAVING_WORLD" or event == "PLAYER_ENTERING_WORLD" then
        self:Cancel(); self.glows, self.cooldownGCD = {}, {}; self.suspended = event == "PLAYER_LEAVING_WORLD"
        self:ClearOverpower(); self.overpowerConsumed = nil
        self.reactions = {}
        self.victoryUntil, self.victoryEstimated, self.victoryConsumed = nil, nil, nil
        self:StopDrag(false); self.preview = nil
        if not self.suspended then self:Scan(); self:PrepareVictoryAura() end
        self:Watch(); self:Paint(); self:Followup(); return
    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" or event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
        if not ID(id) then return end
        self.glows[id] = event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" or nil
    elseif event == "SPELLS_CHANGED" then self:Scan(); self:PrepareVictoryAura(); self:Watch()
    elseif event == "SPELL_DATA_LOAD_RESULT" then self:PrepareVictoryAura()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and ID(spellID) and spellID == VICTORY_RUSH then
        local now = Read(GetTime)
        local active, expires = PlayerProcAura(VICTORIOUS, now)
        local previous = self.victoryUntil
        if self.victoryEstimated or previous and (not Number(now) or previous <= now) then previous = nil end
        self.victoryConsumed = { hadAura = active or previous ~= nil, expiry = previous or expires }
        self.victoryUntil, self.victoryEstimated = nil, nil
        self.cooldownGCD[VICTORY_RUSH] = nil
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and IsOverpower(spellID) then
        local now = Read(GetTime)
        local active, expires = PlayerProcAura(OVERPOWER_AURA, now)
        local previous = self.overpowerAuraEnd
        if previous and (not Number(now) or previous <= now) then previous = nil end
        self.overpowerConsumed = { hadAura = active or previous ~= nil, expiry = previous or expires }
        self:ClearOverpower()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and ID(spellID) and reactiveByRank[spellID] then
        local family = reactiveByRank[spellID]
        for _, learnedID in ipairs(self.learned) do
            if reactiveByRank[learnedID] == family then
                local state = self.reactions[learnedID]
                -- An ordinary Shadow Bolt already in flight can finish after
                -- Nightfall appears. Let the native aura determine consumption.
                if family ~= shadowBoltRanks then
                    local _, expiry = PlayerProcAura(learnedID, Read(GetTime))
                    self.reactions[learnedID] = { consumed = true, auraExpiry = state and state.auraExpiry or expiry }
                end
                break
            end
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        self:ClearOverpower()
        -- The warlock proc belongs to the player. Melee openings should be
        -- rechecked using the new target rather than carrying their old timer.
        for id, state in pairs(self.reactions) do
            if reactiveByRank[id] ~= shadowBoltRanks and not state.consumed then self.reactions[id] = nil end
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" then self:CaptureCooldownFlags(); self.repaintCooldowns = true end
    if (event == "SPELL_UPDATE_USABLE" or event == "SPELL_UPDATE_COOLDOWN")
        and self.overpowerID and InCombatLockdown() then
        local stance = WarriorStance()
        if OutsideBattleStance(stance) then
            -- Record a native opening before another usable event can supersede
            -- it inside the coalesced display refresh.
            local ready, reason = self:Ready(self.overpowerID)
            if ready then
                self:Overpower(true, Read(GetTime), stance)
                self:Record(self.overpowerID, reason .. " [" .. stance .. "]")
            end
        end
    end
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
    if self.victoryRush then
        Suite.Print("Victory Rush: " .. (self.lastChecks[VICTORY_RUSH] or "not checked yet")
            .. "; action slot: " .. (self:VictoryActionSlot() and "found" or "unavailable")
            .. "; own cooldown: " .. (self.victoryCooldownConfirmed and "confirmed" or "unconfirmed")
            .. "; native aura display: " .. (self.victoryAura and "prepared" or self.victoryAuraFailed or "unavailable") .. ".")
    end
    if #self.history == 0 then Suite.Print("No combat availability changes recorded this session."); return end
    Suite.Print("Recent public availability changes from the latest fight:")
    for _, line in ipairs(self.history) do Suite.Print(line) end
end

function Alerts:Apply()
    if not Enabled() then
        self.active, self.preview = nil, nil; self.glows, self.cooldownGCD = {}, {}
        self:ClearOverpower(); self.overpowerConsumed = nil
        self.reactions = {}
        self.victoryUntil, self.victoryEstimated, self.victoryConsumed = nil, nil, nil
        self:Cancel(); self:StopDrag(false)
        self:Watch(); self:Paint(); return
    end
    Suite.AfterCombat("procAlerts", function()
        if not Enabled() or not self:Build() then return end
        self.active = true; self:ConfigureSize(); self:Scan(); self:PrepareVictoryAura(); self:Place(); self:Watch(); self:Paint()
    end)
end
