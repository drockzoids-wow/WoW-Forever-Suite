local _, Suite = ...
local Timers = {}
Suite.ReminderTimers = Timers

local GLOBAL_COOLDOWN = 61304
local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and value >= 0 and value < math.huge
end

local function CooldownInfo(id)
    if not C_Spell or type(C_Spell.GetSpellCooldown) ~= "function" then return end
    local ok, info = pcall(C_Spell.GetSpellCooldown, id)
    if ok and Suite.IsReadable(info) and type(info) == "table" then return info end
end

local function CooldownDuration(id, actionSlot, ignoreGCD)
    if actionSlot and C_ActionBar and type(C_ActionBar.GetActionCooldownDuration) == "function" then
        local ok, duration = pcall(C_ActionBar.GetActionCooldownDuration, actionSlot, ignoreGCD)
        if ok and Suite.IsReadable(duration) and duration then return duration end
    end
    if not C_Spell or type(C_Spell.GetSpellCooldownDuration) ~= "function" then return end
    local ok, duration = pcall(C_Spell.GetSpellCooldownDuration, id, ignoreGCD)
    if ok and Suite.IsReadable(duration) then return duration end
end

function Timers:SpellCooldown(id, onGCD, cooldownEvent, includeGCD)
    if not Number(id) or id == 0 or id == GLOBAL_COOLDOWN then return end
    local info = CooldownInfo(id)
    if not info then return end
    if cooldownEvent and Suite.IsReadable(info.isOnGCD) and type(info.isOnGCD) == "boolean" then onGCD = info.isOnGCD end
    if not includeGCD and onGCD == true or Suite.IsReadable(info.isActive) and info.isActive == false
        or Suite.IsReadable(info.isEnabled) and info.isEnabled == false then return end
    local start, duration, rate = info.startTime, info.duration, info.modRate
    if not Number(start) or not Number(duration) or duration == 0 or not Suite.IsReadable(rate) then return end
    if rate == nil then rate = 1 end
    if not Number(rate) or rate == 0 then return end
    if not includeGCD then
        local gcd = CooldownInfo(GLOBAL_COOLDOWN)
        if gcd and Number(gcd.duration) and (gcd.duration == 0 or Number(gcd.startTime)) then
            if gcd.duration == duration and gcd.startTime == start then return end
        elseif onGCD ~= false then
            return
        end
    end
    local now = GetTime()
    if Number(now) and start + duration / rate > now then return start, duration, rate end
end

function Timers:ActiveSpellCooldown(id, onGCD, widget, actionSlot, actionOnGCD)
    local start, duration, rate = self:SpellCooldown(id, onGCD)
    if start then return true, math.max(0.02, start + duration / rate - GetTime() + 0.05) end
    if not widget or not widget.SetCooldownFromDurationObject then return false end
    local native = CooldownDuration(id, actionSlot, true)
    if not native then return false end
    -- Read duration state only when the client identifies the object as public.
    -- Otherwise rely on the public active and GCD flags, then bind the object
    -- directly to the swipe.
    if native.HasSecretValues and native.IsActive then
        local ok, secret = pcall(native.HasSecretValues, native)
        if ok and Suite.IsReadable(secret) and secret == false then
            local success, active = pcall(native.IsActive, native)
            if success and Suite.IsReadable(active) and type(active) == "boolean" then return active end
        end
    end
    local info
    -- On some updates the action's sampled GCD flag is absent. If the GCD
    -- spell is publicly inactive, an active action cooldown cannot be the GCD.
    local gcd = actionSlot and actionOnGCD == nil and CooldownInfo(GLOBAL_COOLDOWN)
    local actionOwnCooldown = actionOnGCD == false
        or gcd and Suite.IsReadable(gcd.isActive) and gcd.isActive == false
    if actionSlot and actionOwnCooldown and C_ActionBar and type(C_ActionBar.GetActionCooldown) == "function" then
        local ok, result = pcall(C_ActionBar.GetActionCooldown, actionSlot)
        if ok and Suite.IsReadable(result) and type(result) == "table" then info = result end
    end
    if not info and onGCD == false then info = CooldownInfo(id) end
    return info and Suite.IsReadable(info.isActive) and info.isActive == true
        and Suite.IsReadable(info.isEnabled) and info.isEnabled == true or false
end

function Timers:Create(owner, fontSize)
    local swipe = CreateFrame("Cooldown", nil, owner, "CooldownFrameTemplate")
    swipe:SetPoint("TOPLEFT", owner.icon, "TOPLEFT")
    swipe:SetPoint("BOTTOMRIGHT", owner.icon, "BOTTOMRIGHT")
    swipe:EnableMouse(false)
    if swipe.SetHideCountdownNumbers then swipe:SetHideCountdownNumbers(true) end
    if swipe.SetDrawSwipe then swipe:SetDrawSwipe(true) end
    if swipe.SetDrawBling then swipe:SetDrawBling(false) end
    if swipe.SetDrawEdge then swipe:SetDrawEdge(false) end
    if swipe.SetSwipeColor then swipe:SetSwipeColor(0, 0, 0, 0.80) end
    swipe:Hide()
    owner.cooldownSwipe = swipe
    if not fontSize then return end
    local overlay = CreateFrame("Frame", nil, owner)
    -- The expiry number has its own visibility and draws over the swipe.
    overlay:SetPoint("CENTER", owner.icon, "CENTER")
    overlay:SetSize(1, 1)
    if overlay.SetFrameLevel and swipe.GetFrameLevel then overlay:SetFrameLevel(swipe:GetFrameLevel() + 1) end
    overlay:EnableMouse(false)
    local label = overlay:CreateFontString(nil, "OVERLAY")
    label:SetPoint("CENTER")
    label:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
    label:SetTextColor(1, 0.94, 0.72)
    owner.countdown = label
end

function Timers:Swipe(owner, start, duration, rate)
    local swipe = owner.cooldownSwipe
    if not swipe or not swipe.SetCooldown then return end
    if not start then
        if swipe.start then
            swipe.start, swipe.duration, swipe.rate = nil, nil, nil
            swipe:Hide()
        end
    elseif swipe.start ~= start or swipe.duration ~= duration or swipe.rate ~= rate then
        swipe.start, swipe.duration, swipe.rate = start, duration, rate
        swipe:SetCooldown(start, duration, rate)
        swipe:Show()
    end
end

function Timers:UpdateCooldown(owner, spellID, onGCD, cooldownEvent, rebind, actionSlot, includeGCD)
    local swipe = owner.cooldownSwipe
    if spellID and swipe.SetCooldownFromDurationObject then
        if swipe.spellID == spellID and swipe.actionSlot == actionSlot and swipe.includeGCD == includeGCD
            and not cooldownEvent and not rebind then return end
        -- Pass the spell's selected cooldown directly to the native widget.
        local duration = CooldownDuration(spellID, actionSlot, not includeGCD)
        if duration and pcall(swipe.SetCooldownFromDurationObject, swipe, duration, true) then
            swipe.spellID = spellID
            swipe.actionSlot = actionSlot
            swipe.includeGCD = includeGCD
            swipe.start, swipe.duration, swipe.rate = nil, nil, nil
            swipe:Show()
            return
        end
    end
    if swipe.spellID then
        swipe.spellID, swipe.actionSlot, swipe.includeGCD = nil, nil, nil
        swipe:Hide()
    end
    self:Swipe(owner, self:SpellCooldown(spellID, onGCD, cooldownEvent, includeGCD))
end

function Timers:Expiry(owner, remaining)
    local seconds = remaining and remaining > 0 and math.ceil(remaining)
    owner.countdown:SetText(seconds and tostring(seconds) or "")
    if seconds then return math.max(0.02, remaining - seconds + 1) end
end
