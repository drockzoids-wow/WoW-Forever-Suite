local _, Suite = ...
local Selectors = { controls = {}, watched = {} }
Suite.InventorySelectors = Selectors
table.insert(Suite.modules, Selectors)

local function Text(value)
    return Suite.IsReadable(value) and type(value) == "string" and #value > 0 and #value <= 128
        and not value:find("[%c|]")
end

local function Accessible(frame)
    if not Suite.IsReadable(frame) or not frame or not frame.IsForbidden then return false end
    local ok, forbidden = pcall(frame.IsForbidden, frame)
    return ok and Suite.IsReadable(forbidden) and forbidden == false
end

local function GamepadLayout()
    if not InputUtil or not InputUtil.IsGamepadUIEnabled then return false end
    local ok, active = pcall(InputUtil.IsGamepadUIEnabled)
    return not ok or not Suite.IsReadable(active) or active ~= false
end

function Selectors:Enabled(kind)
    if not Suite.db then return false end
    return kind == "bags" and Suite.Inventory:Enabled() or kind == "bank" and Suite.db.offlineBank
        or kind == "saved" and (Suite.db.offlineBank or Suite.Inventory:Enabled())
end

function Selectors:CurrentGUID()
    local guid = UnitGUID and UnitGUID("player")
    return Text(guid) and guid or nil
end

function Selectors:ScopedCharacter(guid)
    local character = Suite.OfflineBank:ViewContext(guid)
    if not character or not Suite.Mail then return end
    local current, recorded = Suite.Mail:CurrentRuleset(), Suite.Mail:RecordedRuleset(character)
    if Text(current) and Text(recorded) and current == recorded then return character, recorded end
end

function Selectors:Choices(bags)
    local choices = {}
    for guid in pairs(Suite.Inventory:Database().characters) do
        if Text(guid) then
            local character, ruleset = self:ScopedCharacter(guid)
            if character then
                local name = Text(character.fullName) and character.fullName or character.name
                choices[#choices + 1] = { guid = guid, name = name,
                    label = name .. " · " .. ruleset,
                    recorded = Suite.OfflineBank:GetSnapshot(0, guid, bags) ~= nil }
            end
        end
    end
    table.sort(choices, function(a, b)
        if a.label ~= b.label then return a.label < b.label end
        return a.guid < b.guid
    end)
    return choices
end

function Selectors:Select(guid, bags, owner)
    if InCombatLockdown() or not Text(guid) or not self:Enabled(bags and "bags" or "bank") then return false end
    local bank = Suite.OfflineBank
    if bags and guid == self:CurrentGUID() then
        if bank.frame and bank.viewBags then bank.frame:Hide() end
        if OpenBackpack then OpenBackpack() end
        return true
    end
    if not self:ScopedCharacter(guid) then return false end
    if not bank:GetSnapshot(0, guid, bags) then return false end
    if bags then return bank:OpenBags(guid, owner) end
    -- Close the native bank through its normal panel lifecycle, never repurpose
    -- live item buttons or give a saved slot a container identity.
    local shown = Accessible(BankFrame) and BankFrame:IsShown()
    if not Suite.IsReadable(shown) then return false end
    if shown == true then
        if not HideUIPanel then return false end
        bank:Capture(); HideUIPanel(BankFrame)
    end
    return bank:OpenFor(guid, 0, owner)
end

function Selectors:Menu(control)
    if InCombatLockdown() or not self:Enabled(control.kind) or not MenuUtil or not MenuUtil.CreateContextMenu then return end
    local bank = Suite.OfflineBank
    local bags = control.kind == "bags" or control.kind == "saved" and bank.viewBags == true
    local selected = control.kind == "saved" and bank.viewGUID or self:CurrentGUID()
    local choices = self:Choices(bags)
    MenuUtil.CreateContextMenu(control, function(_, root)
        root:CreateTitle(bags and "Character bags" or "Character bank")
        for _, choice in ipairs(choices) do
            local guid = choice.guid
            local current = guid == self:CurrentGUID()
            local label = choice.label .. (current and " (current)" or "")
            if not choice.recorded and not (bags and current) then label = label .. " · Not recorded" end
            local row = root:CreateRadio(label, function() return selected == guid end,
                function() self:Select(guid, bags, control:GetParent()) end)
            row:SetEnabled(choice.recorded or bags and current)
        end
        if #choices == 0 then root:CreateTitle("No characters recorded") end
    end)
end

function Selectors:Reset(control)
    if InCombatLockdown() or not self:Enabled(control.kind) then return false end
    local guid = self:CurrentGUID()
    if not guid then return false end
    -- The native bank already belongs to the logged-in character.
    if control.kind == "bank" then return true end
    local bank = Suite.OfflineBank
    if control.kind == "bags" or bank.viewBags then return self:Select(guid, true, control:GetParent()) end
    if not self:Enabled("bank") or not bank:ViewContext(guid) then return false end
    -- An unrecorded current bank still has a valid empty/unknown view.
    bank.viewGUID, bank.viewBags, bank.bankType, bank.page = guid, nil, 0, 1
    bank:Refresh()
    return true
end

function Selectors:UpdateLabels()
    if InCombatLockdown() then return end
    for _, control in ipairs(self.controls) do
        local guid = control.kind == "saved" and Suite.OfflineBank.viewGUID or self:CurrentGUID()
        local character = guid and Suite.OfflineBank:ViewContext(guid)
        local name = character and (Text(character.fullName) and character.fullName or character.name) or "Character"
        if guid == "account" then name = "Shared bank" end
        control:SetText(name)
        -- Saved-view refreshes also update labels; retain native gamepad space
        -- even when this runs after LayoutSearch has hidden the bag control.
        control:SetShown(self:Enabled(control.kind) == true and (control.kind ~= "bags" or not GamepadLayout()))
    end
end

function Selectors:Attach(frame, kind)
    if InCombatLockdown() or not Accessible(frame) or self.watched[frame] then return end
    local control = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    control.kind = kind
    control:SetSize(kind == "bags" and 126 or 186, 20)
    control:SetFrameLevel(math.max(frame:GetFrameLevel() + 10, 520))
    control:SetScript("OnClick", function() self:Menu(control) end)
    local arrow = control:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(12, 12); arrow:SetPoint("RIGHT", -5, 0)
    arrow:SetAtlas("auctionhouse-ui-dropdown-arrow-up")
    local reset = CreateFrame("Button", nil, control, "RefreshButtonTemplate")
    control.reset = reset
    reset:SetSize(20, 20)
    reset:SetPoint("LEFT", control, "RIGHT", 4, 0)
    reset:SetScript("OnClick", function() self:Reset(control) end)
    local function HideResetTooltip()
        if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(reset) then GameTooltip:Hide() end
    end
    reset:SetScript("OnEnter", function()
        if GameTooltip then
            GameTooltip:SetOwner(reset, "ANCHOR_RIGHT")
            GameTooltip:SetText("Return to current character"); GameTooltip:Show()
        end
    end)
    reset:SetScript("OnLeave", HideResetTooltip)
    reset:SetScript("OnHide", HideResetTooltip)
    local label = control.GetFontString and control:GetFontString()
    if label then label:SetWordWrap(false); label:SetWidth(control:GetWidth() - 20) end
    self.watched[frame] = control
    self.controls[#self.controls + 1] = control
    if kind ~= "bags" then control:SetPoint("TOPLEFT", frame, "TOPLEFT", 52, -33) end
    frame:HookScript("OnShow", function() self:Schedule() end)
    self:UpdateLabels()
    return control
end

function Selectors:LayoutSearch(frame, search)
    if InCombatLockdown() or not self:Enabled("bags") or not Accessible(frame) or not Accessible(search) then return end
    -- Gamepad has native prompts in this space. Leave its layout under native ownership.
    if GamepadLayout() then
        local control = self.watched[frame]
        if control then control:Hide() end
        return
    end
    local control = self.watched[frame] or self:Attach(frame, "bags")
    if not control then return end
    local combined = frame == ContainerFrameCombinedBags
    search:ClearAllPoints()
    control:ClearAllPoints()
    if combined then
        search:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -38, -37)
        search:SetWidth(145)
        control:SetSize(146, 20)
        control:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -36)
    else
        -- Fit both rows in the backpack's existing attic, above the first item row.
        search:SetPoint("TOPLEFT", frame, "TOPLEFT", 42, -28)
        search:SetWidth(96)
        control:SetSize(126, 20)
        control:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -50)
    end
    local label = control.GetFontString and control:GetFontString()
    if label then label:SetWidth(control:GetWidth() - 20) end
    control:Show()
end

function Selectors:Refresh()
    if InCombatLockdown() then return end
    self:UpdateLabels()
    if not self:Enabled("saved") then return end
    if self:Enabled("bank") and Accessible(BankFrame) then self:Attach(BankFrame, "bank") end
    for _, frame in ipairs({ ContainerFrameCombinedBags or false, ContainerFrame1 or false }) do
        if Accessible(frame) and type(frame.SetSearchBoxPoint) == "function" then
            if not self.searchHooks then self.searchHooks = {} end
            if not self.searchHooks[frame] then
                self.searchHooks[frame] = true
                hooksecurefunc(frame, "SetSearchBoxPoint", function(owner, search) self:LayoutSearch(owner, search) end)
                frame:HookScript("OnShow", function() self:Schedule() end)
            end
        end
    end
    if Accessible(BagItemSearchBox) then
        local parent = BagItemSearchBox:GetParent()
        if self.searchHooks and self.searchHooks[parent] then
            if parent.UpdateSearchBox then parent:UpdateSearchBox()
            else self:LayoutSearch(parent, BagItemSearchBox) end
        end
    end
end

function Selectors:Schedule()
    if not self:Enabled("saved") or self.timer or not C_Timer or not C_Timer.NewTimer then return end
    self.timer = C_Timer.NewTimer(0, function()
        self.timer = nil
        Suite.AfterCombat("inventorySelectors", function() self:Refresh() end)
    end)
end

function Selectors:Apply()
    if self.timer then self.timer:Cancel(); self.timer = nil end
    Suite.AfterCombat("inventorySelectors", function()
        local enabled = self:Enabled("saved")
        if not self.events and enabled then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function() self:Schedule() end)
        end
        if self.events then
            self.events:UnregisterAllEvents()
            if enabled then
                for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED", "GAME_PAD_ACTIVE_CHANGED" }) do
                    self.events:RegisterEvent(event)
                end
            end
        end
        self:Refresh()
        if not self:Enabled("bags") then
            if Accessible(BagItemSearchBox) then
                local parent = BagItemSearchBox:GetParent()
                if Accessible(parent) and parent.UpdateSearchBox then parent:UpdateSearchBox() end
            end
            if Suite.OfflineBank.viewBags and Suite.OfflineBank.frame then Suite.OfflineBank.frame:Hide() end
        end
    end)
end
