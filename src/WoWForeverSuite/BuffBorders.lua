local _, Suite = ...
local Borders = { buttons = {}, hooked = {} }
Suite.BuffBorders = Borders
table.insert(Suite.modules, Borders)

local function Enabled()
    return Suite.db and Suite.IsReadable(Suite.db.playerBuffBorders) and Suite.db.playerBuffBorders == true
end

local function Usable(object)
    if not Suite.IsReadable(object) or (type(object) ~= "table" and type(object) ~= "userdata") then return false end
    if type(object.IsForbidden) == "function" then
        local forbidden = object:IsForbidden()
        if not Suite.IsReadable(forbidden) or forbidden ~= false then return false end
    end
    return true
end

local function Anchorable(object)
    if not Usable(object) then return false end
    if type(object.IsAnchoringRestricted) == "function" then
        local restricted = object:IsAnchoringRestricted()
        if not Suite.IsReadable(restricted) or restricted ~= false then return false end
    end
    return true
end

local function ParentIs(object, parent)
    if not Usable(object) or type(object.GetParent) ~= "function" then return false end
    local current = object:GetParent()
    return Suite.IsReadable(current) and current == parent
end

local function Coordinates(icon)
    if type(icon.GetTexCoord) ~= "function" or type(icon.SetTexCoord) ~= "function" then return end
    local coords = { icon:GetTexCoord() }
    if #coords ~= 8 then return end
    for index = 1, 8 do
        local value = coords[index]
        if not Suite.IsReadable(value) or type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return end
    end
    return coords
end

function Borders:Crop(record, show)
    if not Usable(record.button) or not ParentIs(record.icon, record.button) or type(record.icon.SetTexCoord) ~= "function" then return false end
    if show then
        -- Match the Suite action-bar crop, excluding the bevel baked into icon artwork.
        record.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
        record.cropped = true
    elseif record.cropped then
        record.icon:SetTexCoord(unpack(record.coords))
        record.cropped = nil
    end
    return true
end

function Borders:CancelWork()
    self.work = nil
    if self.timer then self.timer:Cancel(); self.timer = nil end
    Suite.pending.buffBorders = nil
end

function Borders:Visible(record, show)
    if record.visible == show then return end
    local complete = true
    for _, edge in ipairs(record.edges) do
        if Usable(edge) then
            if show then edge:Show() else edge:Hide() end
        else complete = false end
    end
    if complete then record.visible = show else record.visible = nil end
end

function Borders:Paint()
    local root = BuffFrame
    for button, record in pairs(self.buttons) do
        local show = false
        if self.active and Enabled() and Usable(root) and root == record.root and Usable(root.AuraContainer)
            and ParentIs(button, root.AuraContainer) and Suite.IsReadable(button.Icon) and button.Icon == record.icon then
            local privateAnchor = button.isAuraAnchor
            if Suite.IsReadable(privateAnchor) and (privateAnchor == nil or privateAnchor == false) then
                local kind, unit, example = button.auraType, button.unit, button.isExample
                show = Suite.IsReadable(kind) and kind == "Buff" and Suite.IsReadable(unit)
                    and (unit == "player" or (Suite.IsReadable(example) and example == true))
            end
        end
        local ready = self:Crop(record, show)
        self:Visible(record, show and ready)
    end
end

function Borders:Track(root, button)
    if InCombatLockdown() or not Anchorable(button) or not ParentIs(button, root.AuraContainer)
        or type(button.CreateTexture) ~= "function" then return end
    local privateAnchor = button.isAuraAnchor
    if not Suite.IsReadable(privateAnchor) or (privateAnchor ~= nil and privateAnchor ~= false) then return end
    local icon = button.Icon
    if not Anchorable(icon) or not ParentIs(icon, button) then return end
    local record = self.buttons[button]
    if record and record.root == root and record.icon == icon then return end
    local coords = Coordinates(icon)
    if not coords then return end
    if record then
        self:Crop(record, false)
        if record.cropped then self:Visible(record, false); return end
    end
    if not record then
        record = { button = button, edges = {} }
        self.buttons[button] = record
        for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
            local edge = button:CreateTexture(nil, "OVERLAY", nil, 7)
            edge:SetColorTexture(0.41, 0.84, 0.75, 0.7)
            edge:Hide()
            record.edges[#record.edges + 1] = edge
        end
    end
    self:Visible(record, false)
    record.root, record.icon, record.coords = root, icon, coords
    for index, edge in ipairs(record.edges) do
        edge:ClearAllPoints()
        if index == 1 then
            edge:SetHeight(1)
            edge:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
            edge:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 1, 1)
        elseif index == 2 then
            edge:SetHeight(1)
            edge:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", -1, -1)
            edge:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
        elseif index == 3 then
            edge:SetWidth(1)
            edge:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 0)
            edge:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", -1, 0)
        else
            edge:SetWidth(1)
            edge:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 1, 0)
            edge:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, 0)
        end
    end
end

function Borders:Discover()
    if InCombatLockdown() or not self.active or not Enabled() then return end
    local root = BuffFrame
    if not Usable(root) or not Usable(root.AuraContainer) or not Suite.IsReadable(root.auraFrames)
        or type(root.auraFrames) ~= "table" or type(root.UpdateAuraButtons) ~= "function" then self:Paint(); return end
    if not self.hooked[root] then
        if type(hooksecurefunc) ~= "function" then return end
        -- A post-hook observes the completed native assignment; no aura payload is read.
        self.hooked[root] = "pending"
        local ok = pcall(hooksecurefunc, root, "UpdateAuraButtons", function()
            if self.active and Enabled() and self.hooked[root] == true then self:Paint(); self:Queue() end
        end)
        self.hooked[root] = ok and true or "failed"
    end
    if self.hooked[root] ~= true then return end
    for index, button in pairs(root.auraFrames) do
        if Suite.IsReadable(index) and type(index) == "number" and index >= 1 and index <= 256 and index % 1 == 0 then
            self:Track(root, button)
        end
    end
    self:Paint()
end

function Borders:Queue()
    if not self.active or not Enabled() then return end
    if InCombatLockdown() then
        Suite.AfterCombat("buffBorders", function() if self.active and Enabled() then self:Queue() end end)
        return
    end
    if self.work or not C_Timer or type(C_Timer.NewTimer) ~= "function" then return end
    local work = {}
    self.work = work
    self.timer = C_Timer.NewTimer(0, function()
        if self.work ~= work then return end
        self.work, self.timer = nil, nil
        if InCombatLockdown() then self:Queue(); return end
        self:Discover()
    end)
end

function Borders:OnEvent(event)
    if event == "PLAYER_LOGOUT" then
        self.active = nil; self:CancelWork(); self:Paint()
    elseif event == "PLAYER_REGEN_DISABLED" then
        self:CancelWork()
    elseif self.active then self:Queue() end
end

function Borders:Apply()
    self:CancelWork()
    if not Enabled() then
        self.active = nil
        if self.events then self.events:UnregisterAllEvents() end
        self:Paint()
        return
    end
    Suite.AfterCombat("buffBorders", function()
        if not Enabled() then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event) self:OnEvent(event) end)
        end
        if not self.active then
            self.active = true
            for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_LOGOUT" }) do
                self.events:RegisterEvent(event)
            end
        end
        self:Queue()
    end)
end
