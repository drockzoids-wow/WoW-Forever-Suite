local _, Suite = ...
-- Session-only experiment. Native widgets own aura identity, visibility and time;
-- Suite never reads their displayed values, frames, counts, textures or geometry.
local Test = {}
Suite.NativeBuffTest = Test

local function Read(value, kind) return Suite.IsReadable(value) and type(value) == kind end
local function SpellID(value)
    return Read(value, "number") and value > 0 and value < 2147483647 and value % 1 == 0
end
local function Label(parent, text, point, y, color)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    label:SetPoint(point, parent, point, 0, y)
    label:SetText(text)
    label:SetTextColor(unpack(color))
    return label
end

function Test:Build()
    if InCombatLockdown() then return false end
    if self.host then return true end
    local _, class = UnitClass("player")
    if not Read(class, "string") or class ~= "WARRIOR" then return false, "Use this test on your warrior." end
    local reference = Suite.MissingBuffs:Spell(6673)
    local learned = Suite.MissingBuffs:Learned()
    local spell = reference and learned[reference.name]
    if not spell or not SpellID(spell.id) then return false, "Battle Shout is not available in the readable spellbook yet." end

    if C_AddOns and type(C_AddOns.LoadAddOn) == "function" then pcall(C_AddOns.LoadAddOn, "Blizzard_AuraContainer") end
    local policy = CustomAuraContainerAuraProcessingPolicy
    if not Read(policy, "table") or not Read(policy.None, "number") then
        return false, "This client does not expose the native aura container required by this test."
    end

    local host = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    host:Hide()
    host:SetSize(190, 108)
    host:SetFrameStrata("MEDIUM")
    host:SetClampedToScreen(true)
    host:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    host:SetBackdropColor(0.035, 0.05, 0.065, 0.95)
    Suite.Theme:Backdrop(host, 0.8)
    Label(host, "BATTLE SHOUT / TEST", "TOP", -8, { 0.41, 0.84, 0.75, 1 })
    Label(host, "Action bar to refresh", "BOTTOM", 8, { 0.7, 0.8, 0.8, 1 })
    local fallback = CreateFrame("Frame", nil, host)
    fallback:SetSize(40, 54)
    fallback:SetPoint("TOP", host, "TOP", 0, -27)
    local icon = fallback:CreateTexture(nil, "ARTWORK")
    icon:SetSize(40, 40); icon:SetPoint("TOP", fallback, "TOP", 0, 0)
    icon:SetTexture(spell.icon); icon:SetVertexColor(0.65, 0.24, 0.20, 1)
    Label(fallback, "CHECK", "BOTTOM", 0, { 1, 0.4, 0.3, 1 })

    local container
    local ok, failure = pcall(function()
        container = CreateFrame("AuraContainer", nil, fallback, "CustomAuraContainerTemplate")
        container:SetEnabled(false)
        container:SetEditModePreviewEnabled(false)
        container:SetAuraProcessingPolicy(policy.None)
        container:SetUnit("player")
        container:SetPoint("TOPLEFT", fallback, "TOPLEFT", 0, 0)
        -- Classic ranks from Suite's factual training catalog, plus the current
        -- learned ID (including a client-specific replacement/higher rank).
        local ids = { [6673] = true, [5242] = true, [6192] = true,
            [11549] = true, [11550] = true, [11551] = true, [spell.id] = true }
        container:AddAuraGroup("BattleShout", "HELPFUL", {
            maxFrameCount = 1, candidateFilters = { includeSpellIDs = ids },
            layout = { elementWidth = 40, elementHeight = 54 },
            initializeFrame = function(button)
                -- Blizzard invokes this during out-of-combat batch creation,
                -- before restricting these objects. Do not retain the button.
                button:EnableMouse(false)
                button:SetSize(40, 54)
                local background = button:CreateTexture(nil, "BACKGROUND")
                background:SetAllPoints(button)
                background:SetColorTexture(0.035, 0.05, 0.065, 1)
                local nativeIcon = button:CreateTexture(nil, "ARTWORK")
                nativeIcon:SetSize(40, 40); nativeIcon:SetPoint("TOP", button, "TOP", 0, 0)
                button:SetIcon(nativeIcon)
                Label(button, "ACTIVE", "BOTTOM", 0, { 0.41, 0.84, 0.75, 1 })
                local timer = Label(button, "", "TOP", -25, { 1, 1, 1, 1 })
                button:SetDurationText(timer, {})
            end,
        })
        container:SetEnabled(true)
    end)
    if not ok then
        if container and type(container.SetEnabled) == "function" then pcall(container.SetEnabled, container, false) end
        host:Hide()
        self.failure = Read(failure, "string") and failure:sub(1, 240) or "Unknown widget error"
        return false, "Native aura widget setup was rejected: " .. self.failure
    end
    self.host, self.container = host, container
    return true
end

function Test:Apply()
    if InCombatLockdown() then return end
    if not self.enabled then
        if self.container then self.container:SetEnabled(false) end
        if self.host then self.host:Hide() end
        Suite.Print("Battle Shout native test off.")
        return
    end
    local ok, reason = self:Build()
    if not ok then self.enabled = false; Suite.Print(reason); return end
    -- Fixed test placement below the usual buff bar; no moving native HUD frames.
    self.host:ClearAllPoints()
    self.host:SetPoint("TOP", UIParent, "TOP", 0, -240)
    self.container:SetEnabled(true)
    self.host:Show()
    Suite.Print("Battle Shout native test on: teal ACTIVE/timer is Blizzard's buff display; red CHECK is the fallback. Refresh from your action bar. /wfs bufftest stops it; reload also stops it.")
end

function Test:Toggle()
    self.enabled = not self.enabled
    if InCombatLockdown() then Suite.Print("Battle Shout native test change queued until combat ends.") end
    Suite.AfterCombat("nativeBuffTest", function() self:Apply() end)
end
