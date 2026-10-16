local _, Suite = ...
local Character = {}
Suite.Character = Character
table.insert(Suite.modules, Character)

local function Usable(frame)
    return frame and not (frame.IsForbidden and frame:IsForbidden())
end

function Character:CancelRefresh()
    if self.refreshTimer then self.refreshTimer:Cancel(); self.refreshTimer = nil end
end

function Character:Discover()
    if InCombatLockdown() or self.display or not Usable(CharacterModelScene) then return end
    local scene = CharacterModelScene
    local level = scene:GetFrameLevel()
    if not Suite.IsReadable(level) or type(level) ~= "number" then return end

    -- Passive child overlay: preserve the model controls, class line and native layout.
    local display = CreateFrame("Frame", nil, scene)
    display:EnableMouse(false)
    display:SetFrameLevel(level + 1)
    display:SetPoint("TOPLEFT", scene, "TOPLEFT", 64, -48)
    display:SetPoint("TOPRIGHT", scene, "TOPRIGHT", -64, -48)
    display:SetHeight(20)
    local text = display:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    text:SetTextColor(1, 0.82, 0)
    text:SetJustifyH("CENTER")
    text:SetWordWrap(false)
    text:SetPoint("LEFT", display, "LEFT")
    text:SetPoint("RIGHT", display, "RIGHT")
    display:Hide()
    self.scene, self.display, self.text = scene, display, text
    scene:HookScript("OnShow", function() self:Refresh() end)
    scene:HookScript("OnHide", function() self:CancelRefresh() end)
    if type(PaperDollFrame_ShowSidebar) == "function" then
        hooksecurefunc("PaperDollFrame_ShowSidebar", function() self:QueueRefresh(true) end)
    end
end

function Character:Update()
    if InCombatLockdown() then
        Suite.AfterCombat("characterItemLevel", function() self:Update() end)
        return
    end
    if not Suite.db or not Suite.db.characterItemLevel then
        if self.display then self.display:Hide(); self.text:SetText("") end
        return
    end
    self:Discover()
    if not self.display then return end
    local playerView = Usable(self.scene) and self.scene:IsVisible()
        and not (Usable(CharacterStatsPanePetScrollBox) and CharacterStatsPanePetScrollBox:IsShown())
    if not playerView then self.display:Hide(); return end

    local equipped
    if type(GetAverageItemLevel) == "function" then
        -- The second return is equipped gear; the first includes carried upgrades.
        local _, current = GetAverageItemLevel()
        if Suite.IsReadable(current) and type(current) == "number" and current > 0 and current < math.huge then
            equipped = current
        end
    end
    if equipped then
        self.text:SetText(string.format("Item Level |cffffffff%d|r", math.floor(equipped + 0.5)))
    else
        self.text:SetText("Item Level |cff9aa5ad—|r")
    end
    self.display:Show()
end

function Character:Refresh()
    self:CancelRefresh()
    if not Suite.db or not Suite.db.characterItemLevel then return end
    Suite.AfterCombat("characterItemLevel", function() self:Update() end)
end

function Character:QueueRefresh(discover)
    if not Suite.db or not Suite.db.characterItemLevel or self.refreshTimer then return end
    if not discover and self.scene and (not Usable(self.scene) or not self.scene:IsVisible()) then return end
    self.refreshTimer = C_Timer.NewTimer(0.05, function()
        self.refreshTimer = nil
        self:Refresh()
    end)
end

function Character:Apply()
    self:CancelRefresh()
    Suite.pending.characterItemLevel = nil
    if self.events then self.events:UnregisterAllEvents() end
    if not Suite.db.characterItemLevel and not self.display then return end
    Suite.AfterCombat("characterItemLevel", function()
        if Suite.db.characterItemLevel then
            if not self.events then
                self.events = CreateFrame("Frame")
                self.events:SetScript("OnEvent", function(_, event)
                    self:QueueRefresh(event == "ADDON_LOADED")
                end)
            end
            for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_AVG_ITEM_LEVEL_UPDATE" }) do
                self.events:RegisterEvent(event)
            end
        end
        self:Update()
    end)
end
