local _, Suite = ...
local Skin = { buttons = {}, artwork = {}, bars = {} }
Suite.ActionBarSkin = Skin
table.insert(Suite.modules, Skin)

local colors = {
    PushedTexture = { 0, 0, 0, 0.35 },
    HighlightTexture = { 0.41, 0.84, 0.75, 0.14 },
    CheckedTexture = { 0.41, 0.84, 0.75, 0.22 },
}
local roles = { "PushedTexture", "HighlightTexture", "CheckedTexture" }
local cooldownRoles = { "cooldown", "chargeCooldown", "lossOfControlCooldown" }

local function Enabled()
    return Suite.db and Suite.IsReadable(Suite.db.actionBarSkin) and Suite.db.actionBarSkin == true
end
local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function Read(value, kind) return Suite.IsReadable(value) and type(value) == kind end
local function Alpha(texture)
    if type(texture.GetAlpha) ~= "function" then return end
    local alpha = texture:GetAlpha()
    if Number(alpha) and alpha >= 0 and alpha <= 1 then return alpha end
end
local function Usable(object)
    if not Suite.IsReadable(object) or (type(object) ~= "table" and type(object) ~= "userdata") then return false end
    if type(object.IsForbidden) == "function" then
        local forbidden = object:IsForbidden()
        if not Read(forbidden, "boolean") or forbidden then return false end
    end
    return true
end

local function CanAnchor(region)
    if not Usable(region) then return false end
    for _, method in ipairs({ "ClearAllPoints", "SetPoint", "SetSize" }) do
        if type(region[method]) ~= "function" then return false end
    end
    if type(region.IsAnchoringRestricted) == "function" then
        local restricted = region:IsAnchoringRestricted()
        if not Read(restricted, "boolean") or restricted then return false end
    end
    return true
end
local function Geometry(region)
    if not CanAnchor(region) then return end
    for _, method in ipairs({ "GetNumPoints", "GetPoint", "GetWidth", "GetHeight" }) do
        if type(region[method]) ~= "function" then return end
    end
    local count, width, height = region:GetNumPoints(), region:GetWidth(), region:GetHeight()
    if not Number(count) or count < 1 or count > 8 or count % 1 ~= 0
        or not Number(width) or not Number(height) or width <= 0 or height <= 0 then return end
    local saved = { points = {}, width = width, height = height }
    for index = 1, count do
        local point, relative, relativePoint, x, y = region:GetPoint(index)
        if not Read(point, "string") or not Read(relativePoint, "string") or not Number(x) or not Number(y)
            or not Suite.IsReadable(relative) or (relative ~= nil and not Usable(relative)) then return end
        saved.points[index] = { point, relative, relativePoint, x, y }
    end
    return saved
end

local function Coordinates(texture)
    if type(texture.GetTexCoord) ~= "function" or type(texture.SetTexCoord) ~= "function" then return end
    local coords = { texture:GetTexCoord() }
    if #coords ~= 8 then return end
    for _, value in ipairs(coords) do if not Number(value) then return end end
    return coords
end

local function Texture(texture)
    local geometry = Geometry(texture)
    if not geometry then return end
    for _, method in ipairs({ "GetAtlas", "GetTexture", "GetBlendMode", "SetAtlas", "SetTexture", "SetColorTexture", "SetBlendMode", "GetVertexColor", "SetVertexColor" }) do
        if type(texture[method]) ~= "function" then return end
    end
    if Alpha(texture) == nil then return end
    local atlas, file, blend = texture:GetAtlas(), texture:GetTexture(), texture:GetBlendMode()
    if not Suite.IsReadable(atlas) or not Suite.IsReadable(file) or not Read(blend, "string") then return end
    if atlas ~= nil and not Read(atlas, "string") then return end
    if file ~= nil and not Read(file, "string") and not Number(file) then return end
    if atlas == "" then atlas = nil end
    if Number(file) and file <= 0 then return end
    if not atlas and file == nil then return end -- Unknown solid-color textures cannot be restored from an asset.
    local coords = Coordinates(texture)
    if not coords then return end
    local color = { texture:GetVertexColor() }
    if #color ~= 4 then return end
    for _, value in ipairs(color) do if not Number(value) or value < 0 or value > 1 then return end end
    return { texture = texture, geometry = geometry, atlas = atlas, file = file, blend = blend, coords = coords, color = color }
end

local function Inset(region, button, padding)
    region:ClearAllPoints()
    region:SetPoint("TOPLEFT", button, "TOPLEFT", padding, -padding)
    region:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -padding, padding)
end
local function RestoreGeometry(region, saved)
    region:ClearAllPoints()
    region:SetSize(saved.width, saved.height)
    for _, point in ipairs(saved.points) do region:SetPoint(unpack(point)) end
end

function Skin:Suppress(object)
    if not Usable(object) or type(object.GetAlpha) ~= "function" or type(object.SetAlpha) ~= "function" then return end
    local record = self.artwork[object]
    if record and record.active then return end
    local alpha = object:GetAlpha()
    if not Number(alpha) or alpha < 0 or alpha > 1 then return end
    if not record then
        record = { object = object }
        self.artwork[object] = record
        hooksecurefunc(object, "SetAlpha", function(_, value)
            if record.changing or not record.active then return end
            record.alpha = Number(value) and value >= 0 and value <= 1 and value or nil
            -- Restricted native writes remain native and are never replaced with guessed alpha.
            if record.alpha and Enabled() and Usable(object) then
                record.changing = true; object:SetAlpha(0); record.changing = nil
            end
        end)
    end
    record.alpha, record.active, record.changing = alpha, true, true
    object:SetAlpha(0)
    record.changing = nil
end

function Skin:Paint(record, hovered)
    if not Enabled() or not record.active or not Usable(record.button) then return end
    for _, edge in ipairs(record.edges) do edge:SetColorTexture(0.41, 0.84, 0.75, hovered and 1 or 0.55) end
end

function Skin:Style(record)
    if not Enabled() or not record.active or not Usable(record.button) then return end
    for role, saved in pairs(record.states) do
        local texture = saved.texture
        if Usable(texture) then
            local alpha = Alpha(texture)
            if alpha then
                -- Native pet/attack updates replace vertex alpha through SetAlpha.
                -- Bake Suite's translucency into the fill; preserve native state opacity separately.
                texture:SetColorTexture(unpack(colors[role]))
                texture:SetVertexColor(1, 1, 1, alpha)
                texture:SetTexCoord(0, 1, 0, 1)
                texture:SetBlendMode("BLEND")
                if not InCombatLockdown() then Inset(texture, record.button, 2) end
            end
        end
    end
    if not InCombatLockdown() then
        Inset(record.icon, record.button, 3)
        record.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
        -- The native template adds another inset for its rounded icon artwork.
        -- Suite's square icon is already inset; every native cooldown shares its full bounds.
        for _, saved in ipairs(record.cooldowns) do
            if CanAnchor(saved.widget) then Inset(saved.widget, record.icon, 0) end
        end
    end
end

function Skin:Track(button)
    if InCombatLockdown() or not Usable(button) or type(button.CreateTexture) ~= "function"
        or type(button.HookScript) ~= "function" or not Usable(button.icon) then return end
    local record = self.buttons[button]
    if record and record.active then self:Style(record); return end
    local icon, states = button.icon, {}
    local geometry, coords = Geometry(icon), Coordinates(icon)
    if not geometry or not coords then return end
    local mask
    if type(icon.GetNumMaskTextures) ~= "function" or type(icon.GetMaskTexture) ~= "function"
        or type(icon.RemoveMaskTexture) ~= "function" or type(icon.AddMaskTexture) ~= "function" then return end
    local count = icon:GetNumMaskTextures()
    if not Number(count) or count < 0 or count > 1 or count % 1 ~= 0 then return end
    if count == 1 then
        mask = icon:GetMaskTexture(1)
        if not Usable(mask) or not Suite.IsReadable(button.IconMask) or mask ~= button.IconMask then return end
    end
    for _, role in ipairs(roles) do
        states[role] = Texture(button[role])
        if not states[role] then return end
    end
    local cooldowns = {}
    for _, role in ipairs(cooldownRoles) do
        local widget = button[role]
        if not Suite.IsReadable(widget) then return end
        if widget ~= nil then
            local saved = Geometry(widget)
            if not saved then return end
            cooldowns[#cooldowns + 1] = { widget = widget, geometry = saved }
        end
    end
    if not record then
        record = { button = button, edges = {} }
        self.buttons[button] = record
        record.background = button:CreateTexture(nil, "BACKGROUND", nil, -7)
        record.background:SetColorTexture(0.035, 0.05, 0.065, 0.95)
        Inset(record.background, button, 0)
        for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
            local edge = button:CreateTexture(nil, "BORDER", nil, 7)
            if side == "TOP" or side == "BOTTOM" then
                edge:SetHeight(1); edge:SetPoint(side .. "LEFT", button, side .. "LEFT"); edge:SetPoint(side .. "RIGHT", button, side .. "RIGHT")
            else
                edge:SetWidth(1); edge:SetPoint("TOP" .. side, button, "TOP" .. side); edge:SetPoint("BOTTOM" .. side, button, "BOTTOM" .. side)
            end
            record.edges[#record.edges + 1] = edge
        end
        button:HookScript("OnEnter", function() self:Paint(record, true) end)
        button:HookScript("OnLeave", function() self:Paint(record, false) end)
        button:HookScript("OnShow", function() if Enabled() then self:Queue() end end)
        if type(button.UpdateButtonArt) == "function" then
            hooksecurefunc(button, "UpdateButtonArt", function()
                if Enabled() and record.active then
                    -- Native state textures stay engine-managed; only their presentation changes.
                    self:Style(record)
                    if InCombatLockdown() then self:Queue() end
                end
            end)
        end
    end
    record.icon, record.geometry, record.coords, record.mask, record.states = icon, geometry, coords, mask, states
    record.cooldowns = cooldowns
    record.active = true
    if mask then icon:RemoveMaskTexture(mask) end
    record.background:Show()
    for _, edge in ipairs(record.edges) do edge:Show() end
    self:Suppress(button.NormalTexture)
    self:Suppress(button.SlotArt)
    self:Suppress(button.SlotBackground)
    self:Style(record); self:Paint(record, false)
end

function Skin:BarArtwork()
    local bar = MainActionBar
    if not Usable(bar) then return end
    self:Suppress(bar.BorderArt)
    local caps = bar.EndCaps
    if Usable(caps) then
        for _, side in ipairs({ "LeftEndCap", "RightEndCap" }) do
            if Usable(caps[side]) then self:Suppress(caps[side].Texture) end
        end
    end
    for _, name in ipairs({ "HorizontalDividersPool", "VerticalDividersPool" }) do
        local pool = bar[name]
        if Read(pool, "table") and type(pool.EnumerateActive) == "function" then
            for divider in pool:EnumerateActive() do self:Suppress(divider) end
        end
    end
    if not self.bars[bar] then
        self.bars[bar] = true
        if type(bar.UpdateDividers) == "function" then hooksecurefunc(bar, "UpdateDividers", function() if Enabled() then self:Queue() end end) end
        if type(bar.HookScript) == "function" then bar:HookScript("OnShow", function() if Enabled() then self:Queue() end end) end
    end
end

function Skin:Restore()
    if InCombatLockdown() then return end
    for _, record in pairs(self.buttons) do
        if record.active then
            record.active = nil
            if Usable(record.background) then record.background:Hide() end
            for _, edge in ipairs(record.edges) do if Usable(edge) then edge:Hide() end end
            if Usable(record.button) and Usable(record.icon) then
                RestoreGeometry(record.icon, record.geometry)
                record.icon:SetTexCoord(unpack(record.coords))
                if record.mask and Usable(record.mask) then
                    local count, present = record.icon:GetNumMaskTextures(), false
                    if Number(count) and count >= 0 and count <= 8 and count % 1 == 0 then
                        for index = 1, count do
                            local mask = record.icon:GetMaskTexture(index)
                            if not Suite.IsReadable(mask) then present = true; break end
                            if mask == record.mask then present = true; break end
                        end
                        if not present then record.icon:AddMaskTexture(record.mask) end
                    end
                end
                for _, saved in pairs(record.states) do
                    local texture = saved.texture
                    if Usable(texture) then
                        local alpha = Alpha(texture)
                        if saved.atlas then texture:SetAtlas(saved.atlas) else texture:SetTexture(saved.file) end
                        -- Restore original RGB without rewinding a later native pet/attack opacity update.
                        if alpha then texture:SetVertexColor(saved.color[1], saved.color[2], saved.color[3], alpha) end
                        texture:SetTexCoord(unpack(saved.coords)); texture:SetBlendMode(saved.blend)
                        RestoreGeometry(texture, saved.geometry)
                    end
                end
                for _, saved in ipairs(record.cooldowns) do
                    if CanAnchor(saved.widget) then RestoreGeometry(saved.widget, saved.geometry) end
                end
                -- Native art refresh observes the current Edit Mode setting, including changes made while skinned.
                if type(record.button.UpdateButtonArt) == "function" then record.button:UpdateButtonArt() end
            end
            record.icon, record.geometry, record.coords, record.mask, record.states = nil, nil, nil, nil, nil
            record.cooldowns = nil
        end
    end
    for _, record in pairs(self.artwork) do
        if record.active then
            record.active = nil
            if record.alpha and Usable(record.object) then record.object:SetAlpha(record.alpha) end
            record.alpha = nil
        end
    end
end

function Skin:Cancel()
    self.work = nil
    if self.timer then self.timer:Cancel(); self.timer = nil end
end
function Skin:Refresh()
    self:Cancel()
    if not Enabled() then return end
    if InCombatLockdown() then
        -- Retained show hooks must not replace a pending enable with a scan that omits event registration.
        Suite.AfterCombat("actionBarSkin", function() self:Apply() end)
        return
    end
    Suite.ActionBars:VisitButtons(function(button) self:Track(button) end, true)
    self:BarArtwork()
end
function Skin:Queue()
    if not Enabled() then return end
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
    Suite.pending.actionBarSkin = nil
    if self.events then self.events:UnregisterAllEvents() end
    if not Enabled() then
        if next(self.buttons) or next(self.artwork) then Suite.AfterCombat("actionBarSkin", function() self:Restore() end) end
        return
    end
    Suite.AfterCombat("actionBarSkin", function()
        if not Enabled() then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function() self:Queue() end)
        end
        for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED" }) do self.events:RegisterEvent(event) end
        self:Refresh()
    end)
end
