local _, Suite = ...
local Camping = { buttons = {}, dirty = true }
Suite.Camping = Camping
table.insert(Suite.modules, Camping)
local Items = Suite.CampingItems
local Number, Text = Items.Number, Items.Text

Camping.poses = {
    { key = "sit", label = "Sit", token = "SIT", command = "/sit" },
    { key = "kneel", label = "Kneel", token = "KNEEL", command = "/kneel" },
    { key = "sleep", label = "Sleep", token = "SLEEP", command = "/sleep" },
    { key = "lie", label = "Lie down", token = "LAYDOWN", command = "/lie" },
}

local function Surface(frame)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.035, 0.05, 0.065, 0.9)
    Suite.Theme:Backdrop(frame, 0.8)
end
local function Label(parent, size, r, g, b)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", size, "")
    label:SetTextColor(r, g, b)
    return label
end
local function HideTooltip(owner)
    if GameTooltip and type(GameTooltip.IsOwned) == "function" and GameTooltip:IsOwned(owner) then GameTooltip:Hide() end
end
local function Hint(owner, title, body)
    if not GameTooltip then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:AddLine(title, 0.41, 0.84, 0.75)
    GameTooltip:AddLine(body, 0.88, 0.91, 0.93, true)
    GameTooltip:Show()
end

function Camping:GetPose()
    for _, pose in ipairs(self.poses) do if pose.key == Suite.db.campingPose then return pose end end
    return self.poses[1]
end

function Camping:Command(pose)
    local maximum = Number(MAXEMOTEINDEX) and math.min(MAXEMOTEINDEX, 1000) or 628
    for index = 1, maximum do
        local token = _G["EMOTE" .. index .. "_TOKEN"]
        if Text(token) and token == pose.token then
            local alias = _G["EMOTE" .. index .. "_CMD1"]
            if Text(alias) and alias:match("^/%a+$") then return alias end
        end
    end
    return pose.command
end

function Camping:Nearby()
    if InCombatLockdown() or not C_UnitAuras or type(C_UnitAuras.GetAuraDataByIndex) ~= "function" then return false end
    -- Nearby aura ID from the local behavior reference; English name also matches the user's screenshot.
    -- Do not use the timed camping reward / rest countdown as a proximity signal.
    local localized
    if C_Spell and type(C_Spell.GetSpellName) == "function" then
        local ok, name = pcall(C_Spell.GetSpellName, 1283391)
        if ok and Text(name) then localized = name end
    end
    for index = 1, 255 do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", index, "HELPFUL")
        if not ok or not Suite.IsReadable(aura) then return false end
        if aura == nil then return false end
        if type(aura) ~= "table" then return false end
        if Text(aura.name) and (aura.name == "Campfire Nearby" or (localized and aura.name == localized)) then return true end
        if Number(aura.spellId) and aura.spellId == 1283391 then return true end
    end
    return false
end

function Camping:Place(frame)
    if InCombatLockdown() then return end
    frame:ClearAllPoints()
    local saved = Suite.db.campingPosition
    local x, y = saved.x, saved.y
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    if Suite.IsReadable(x) and Suite.IsReadable(y) and type(x) == "number" and type(y) == "number"
        and x == x and y == y and math.abs(x) <= 0.5 and math.abs(y) <= 0.5
        and Number(width) and Number(height) then
        frame:SetPoint("CENTER", UIParent, "CENTER", x * width, y * height)
    else frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 210) end
end

function Camping:StopMoving(frame)
    if not frame.moving then return end
    if InCombatLockdown() and frame ~= self.preview then frame.cancelMove = true; return end
    frame:StopMovingOrSizing()
    frame.moving = nil
    if frame.cancelMove then frame.cancelMove = nil; self:Place(frame); return end
    local x, y = frame:GetCenter()
    local scale, parentScale = frame:GetEffectiveScale(), UIParent:GetEffectiveScale()
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    if Number(x) and Number(y) and Number(scale) and Number(parentScale) and parentScale > 0
        and Number(width) and Number(height) and width > 0 and height > 0 then
        local ratio = scale / parentScale
        Suite.db.campingPosition = { x = math.max(-0.5, math.min(0.5, (x * ratio - width / 2) / width)),
            y = math.max(-0.5, math.min(0.5, (y * ratio - height / 2) / height)) }
    end
end

function Camping:Header(frame, title)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(19)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function()
        if InCombatLockdown() then return end
        HideTooltip(header)
        if self.flyout then self.flyout:Hide() end
        frame.moving = true; frame:StartMoving()
    end)
    header:SetScript("OnDragStop", function() self:StopMoving(frame) end)
    local function ResetClick(_, button)
        if button == "RightButton" and IsControlKeyDown() then self:ResetPosition() end
    end
    header:SetScript("OnMouseUp", ResetClick)
    frame:SetScript("OnMouseUp", ResetClick)
    header:SetScript("OnEnter", function() Hint(header, "Camping bar", "Drag this header to move. Ctrl+right-click to reset. Settings: /wfs camping") end)
    header:SetScript("OnLeave", function() HideTooltip(header) end)
    header:SetScript("OnHide", function() HideTooltip(header); self:StopMoving(frame) end)
    local caption = Label(header, 9, 0.66, 0.77, 0.77)
    caption:SetPoint("LEFT", 8, 0)
    caption:SetText(title)
    return header
end

function Camping:SelectPose(key)
    if InCombatLockdown() then return end
    for _, pose in ipairs(self.poses) do
        if pose.key == key then
            Suite.db.campingPose = key
            if self.rest then
                self.rest:SetAttribute("macrotext1", self:Command(pose))
                self.rest.caption:SetText(pose.label)
                self.flyout:Hide()
            end
            if Suite.GUI.RefreshCamping then Suite.GUI:RefreshCamping() end
            return
        end
    end
end

function Camping:Build()
    if self.bar then return true end
    if InCombatLockdown() or type(RegisterStateDriver) ~= "function" then return false end
    local controller = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
    self.controller = controller
    -- Give both restricted frame references explicit protection before creating handles.
    local bar = CreateFrame("Frame", nil, controller, "SecureHandlerBaseTemplate,BackdropTemplate")
    self.bar = bar
    bar:SetFrameStrata("MEDIUM")
    bar:SetSize(210, 58)
    Surface(bar)
    self:Place(bar)
    self.header = self:Header(bar, "CAMPING")
    bar:Hide()
    controller:SetFrameRef("bar", bar)
    -- Only the native secure driver hides protected ancestors/children during combat.
    -- Keep the bar hidden at combat exit until the fresh proximity check completes.
    controller:SetAttribute("_onstate-combat", [[
        if newstate == "combat" then
            local poses = self:GetFrameRef("poses")
            if poses then poses:Hide() end
            self:GetFrameRef("bar"):Hide()
            self:Hide()
        else
            self:Show()
        end
    ]])
    local rest = CreateFrame("Button", nil, bar, "SecureActionButtonTemplate,BackdropTemplate")
    self.rest = rest
    rest:SetPoint("TOPLEFT", 8, -23)
    rest:SetSize(82, 27)
    Surface(rest)
    rest:RegisterForClicks("AnyUp", "AnyDown")
    rest:SetAttribute("useOnKeyDown", false)
    rest:SetAttribute("type1", "macro")
    rest.caption = Label(rest, 11, 0.41, 0.84, 0.75)
    rest.caption:SetPoint("CENTER")
    rest:SetScript("OnEnter", function()
        local pose = self:GetPose()
        Hint(rest, pose.label .. "  " .. self:Command(pose), "Rest at the campfire to receive its buffs. Use the arrow to choose Sit, Kneel, Sleep or Lie down.")
    end)
    rest:SetScript("OnLeave", function() HideTooltip(rest) end)
    rest:SetScript("OnHide", function() HideTooltip(rest) end)

    local arrow = CreateFrame("Button", nil, bar, "BackdropTemplate")
    self.arrow = arrow
    arrow:SetPoint("LEFT", rest, "RIGHT", 3, 0)
    arrow:SetSize(23, 27)
    Surface(arrow)
    arrow.caption = Label(arrow, 11, 0.66, 0.77, 0.77)
    arrow.caption:SetPoint("CENTER"); arrow.caption:SetText("v")
    -- A protected parent does not make this chooser's frame handle valid in combat.
    local flyout = CreateFrame("Frame", "WoWForeverSuiteCampingPoses", bar, "SecureHandlerBaseTemplate,BackdropTemplate")
    -- Named only for Blizzard's Escape handling; all module state stays in Suite.
    self.flyout = flyout
    controller:SetFrameRef("poses", flyout)
    flyout:SetPoint("BOTTOMLEFT", rest, "TOPLEFT", 0, 6)
    flyout:SetSize(154, 130)
    flyout:SetFrameLevel(bar:GetFrameLevel() + 10)
    Surface(flyout)
    flyout:Hide()
    table.insert(UISpecialFrames, flyout:GetName())
    self.poseButtons = {}
    for index, pose in ipairs(self.poses) do
        local key = pose.key
        local choice = CreateFrame("Button", nil, flyout, "BackdropTemplate")
        choice:SetSize(142, 28)
        choice:SetPoint("TOPLEFT", 6, -6 - (index - 1) * 30)
        choice.caption = Label(choice, 11, 0.88, 0.91, 0.93)
        choice.caption:SetPoint("LEFT", 8, 0); choice.caption:SetText(pose.label)
        choice:SetScript("OnClick", function() self:SelectPose(key) end)
        choice:SetScript("OnEnter", function() choice:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" }); choice:SetBackdropColor(0.1, 0.2, 0.21, 1) end)
        choice:SetScript("OnLeave", function() choice:SetBackdropColor(0, 0, 0, 0) end)
        self.poseButtons[index] = choice
    end
    arrow:SetScript("OnClick", function() if not InCombatLockdown() then flyout:SetShown(not flyout:IsShown()) end end)
    arrow:SetScript("OnEnter", function() Hint(arrow, "Resting pose", "Choose how to rest. Your selection is remembered; click the rest button to perform it.") end)
    arrow:SetScript("OnLeave", function() HideTooltip(arrow) end)
    arrow:SetScript("OnHide", function() HideTooltip(arrow) end)
    self.empty = Label(bar, 10, 0.55, 0.65, 0.7)
    self.empty:SetPoint("LEFT", arrow, "RIGHT", 10, 0)
    self.empty:SetText("No objects")
    self:SelectPose(self:GetPose().key)
    -- Start the driver only after both secure references and their UI are ready.
    RegisterStateDriver(controller, "combat", "[combat] combat; peaceful")
    return true
end

function Camping:ItemButton(index)
    if self.buttons[index] then return self.buttons[index] end
    local button = CreateFrame("Button", nil, self.bar, "SecureActionButtonTemplate,BackdropTemplate")
    self.buttons[index] = button
    button:SetSize(30, 30)
    Surface(button)
    button:RegisterForClicks("AnyUp", "AnyDown")
    button:SetAttribute("useOnKeyDown", false)
    button:SetAttribute("type1", "item")
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 2, -2); button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints(button.icon)
    local countLayer = CreateFrame("Frame", nil, button)
    countLayer:SetAllPoints(button)
    countLayer:SetFrameLevel(button.cooldown:GetFrameLevel() + 1)
    button.count = Label(countLayer, 10, 1, 1, 1)
    button.count:SetPoint("BOTTOMRIGHT", -2, 2)
    button.count:SetDrawLayer("OVERLAY", 7)
    button:SetScript("OnEnter", function()
        local entry = button.entry
        if not entry or not GameTooltip then return end
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        if type(GameTooltip.SetItemByID) == "function" then GameTooltip:SetItemByID(entry.id)
        elseif type(GameTooltip.SetHyperlink) == "function" then GameTooltip:SetHyperlink("item:" .. entry.id) end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() HideTooltip(button) end)
    button:SetScript("OnHide", function() HideTooltip(button) end)
    return button
end

function Camping:Cooldowns()
    if InCombatLockdown() or not self.nearby or not self.enabled then return end
    for _, button in ipairs(self.buttons) do
        local entry = button.entry
        if entry then
            local ok, start, duration, enabled = false, nil, nil, nil
            if C_Item and type(C_Item.GetItemCooldown) == "function" then
                ok, start, duration, enabled = pcall(C_Item.GetItemCooldown, entry.id)
            end
            if ok and Number(start) and Number(duration) and Suite.IsReadable(enabled) and enabled == true and duration > 0 then
                button.cooldown:SetCooldown(start, duration)
                button.cooldown:Show()
            else button.cooldown:Hide() end
        end
    end
end

function Camping:Refresh()
    if InCombatLockdown() then return end
    if self.preview and self.preview.cancelMove then self:StopMoving(self.preview) end
    if self.closePoseAfterCombat and self.flyout then self.flyout:Hide(); self.closePoseAfterCombat = nil end
    if not self.enabled then
        if self.bar then self:StopMoving(self.bar); self.flyout:Hide(); self.bar:Hide() end
        return
    end
    local nearby = self:Nearby()
    if nearby and not self.nearby then self.dirty = true end
    self.nearby = nearby
    if not nearby then
        if self.bar then self:StopMoving(self.bar); self.flyout:Hide(); self.bar:Hide() end
        return
    end
    if not self:Build() then return end
    if self.bar.cancelMove then self:StopMoving(self.bar) end
    if self.dirty then self.snapshot = Items:Scan(); self.dirty = false end
    local list = self.snapshot and self.snapshot.list or {}
    local columns = math.min(8, #list)
    self.bar:SetSize(columns > 0 and 136 + columns * 34 or 210, 58 + math.max(0, math.ceil(#list / 8) - 1) * 34)
    for index, entry in ipairs(list) do
        local button = self:ItemButton(index)
        button.entry = entry
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", 130 + ((index - 1) % 8) * 34, -22 - math.floor((index - 1) / 8) * 34)
        button:SetAttribute("item1", "item:" .. entry.id)
        button.icon:SetTexture(entry.icon)
        button.count:SetText(entry.count > 1 and tostring(entry.count) or "")
        button:Show()
    end
    for index = #list + 1, #self.buttons do
        local button = self.buttons[index]
        button:Hide(); button:SetAttribute("item1", nil); button.entry = nil
    end
    self.empty:SetShown(#list == 0)
    self.empty:SetText(self.snapshot and self.snapshot.incomplete and "Checking..." or "No objects")
    self:Cooldowns()
    self.bar:Show()
end

function Camping:CancelTimer()
    if self.timer then self.timer:Cancel(); self.timer = nil end
end
function Camping:Queue(dirty)
    if dirty then self.dirty = true end
    if not self.enabled or InCombatLockdown() or self.timer then return end
    self.timer = C_Timer.NewTimer(0.12, function()
        self.timer = nil
        if self.enabled and not InCombatLockdown() then self:Refresh() end
    end)
end

function Camping:Apply()
    local enabled = Suite.db.campingBar == true
    if self.enabled ~= enabled then
        self:CancelTimer(); self.dirty = true
        if not enabled then self.nearby = false; self:SetPreview(false) end
    end
    self.enabled = enabled
    if not enabled then
        if self.events then self.events:UnregisterAllEvents() end
        Suite.AfterCombat("camping", function() self:Refresh() end)
        return
    end
    if not self.events then
        self.events = CreateFrame("Frame")
        self.events:SetScript("OnEvent", function(_, event, unit)
            if event == "UNIT_AURA" then
                if Text(unit) and unit == "player" then self:Queue(false) end
            elseif event == "PLAYER_REGEN_DISABLED" then
                self:CancelTimer(); self:SetPreview(false)
                self.closePoseAfterCombat = true
                if self.bar and self.bar.moving then self.bar.cancelMove = true end
            elseif event == "PLAYER_REGEN_ENABLED" then self:Refresh()
            elseif event == "ITEM_DATA_LOAD_RESULT" or event == "GET_ITEM_INFO_RECEIVED" then
                if Number(unit) and (Items.requested[unit] or (self.snapshot and self.snapshot.carried[unit])) then
                    Items.catalog[unit] = nil
                    self:Queue(true)
                end
            elseif event == "BAG_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_COOLDOWN" then self:Cooldowns()
            else self:Queue(true) end
        end)
    end
    for _, event in ipairs({ "UNIT_AURA", "BAG_UPDATE_DELAYED", "BAG_UPDATE_COOLDOWN", "SPELL_UPDATE_COOLDOWN",
        "ITEM_DATA_LOAD_RESULT", "GET_ITEM_INFO_RECEIVED", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
        self.events:RegisterEvent(event)
    end
    Suite.AfterCombat("camping", function() self:Refresh() end)
end

function Camping:SetPreview(show)
    if not show then
        if self.preview then self:StopMoving(self.preview); self.preview:Hide() end
        return
    end
    if InCombatLockdown() or not self.settingsVisible then return end
    if not self.preview then
        local preview = CreateFrame("Frame", "WoWForeverSuiteCampingPreview", UIParent, "BackdropTemplate")
        self.preview = preview
        preview:SetFrameStrata("DIALOG")
        preview:SetSize(270, 58)
        preview:EnableMouse(true)
        Surface(preview)
        self:Header(preview, "CAMPING  /  POSITION PREVIEW")
        local text = Label(preview, 11, 0.41, 0.84, 0.75)
        text:SetPoint("BOTTOMLEFT", 10, 10)
        text:SetText("Resting pose  ·  carried camp objects")
        preview:SetScript("OnHide", function()
            self:StopMoving(preview)
            if self.bar and not InCombatLockdown() then self:Place(self.bar) end
        end)
        table.insert(UISpecialFrames, preview:GetName())
    end
    self:Place(self.preview)
    self.preview:Show()
end

function Camping:SetSettingsVisible(visible)
    self.settingsVisible = visible
    if not visible then
        self:SetPreview(false)
        if self.bar then Suite.AfterCombat("campingPlace", function() self:Place(self.bar) end) end
    end
end

function Camping:ResetPosition()
    Suite.AfterCombat("campingPosition", function()
        Suite.db.campingPosition = {}
        if self.bar then self:StopMoving(self.bar); Suite.db.campingPosition = {}; self:Place(self.bar) end
        if self.preview then self:StopMoving(self.preview); Suite.db.campingPosition = {}; self:Place(self.preview) end
    end)
end
