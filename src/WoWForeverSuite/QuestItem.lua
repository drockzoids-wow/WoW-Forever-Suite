local _, Suite = ...
local QuestItem = {}
Suite.QuestItem = QuestItem
table.insert(Suite.modules, QuestItem)

local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and math.abs(value) < 1000000000000
end
local function ID(value, maximum)
    return Number(value) and value > 0 and value <= (maximum or 10000000) and value == math.floor(value)
end
local function Text(value, maximum)
    return Suite.IsReadable(value) and type(value) == "string" and #value > 0 and #value <= maximum and not value:find("%c")
end
local function Read(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then return end
    if not Suite.IsReadable(a) then a = nil end
    if not Suite.IsReadable(b) then b = nil end
    if not Suite.IsReadable(c) then c = nil end
    if not Suite.IsReadable(d) then d = nil end
    return a, b, c, d
end
local function Yes(value) return value == true or value == 1 end
local function CursorEmpty()
    if type(GetCursorInfo) ~= "function" then return false end
    local ok, kind = pcall(GetCursorInfo)
    return ok and Suite.IsReadable(kind) and kind == nil
end
function QuestItem:Enabled()
    return Suite.db and Suite.IsReadable(Suite.db.questItemButton) and Suite.db.questItemButton == true
end
function QuestItem:Find()
    if InCombatLockdown() or Read(UnitIsDeadOrGhost, "player") ~= false then return end
    local api = C_QuestLog or {}
    local count = Read(api.GetNumQuestLogEntries)
    if not Number(count) or count < 0 or count % 1 ~= 0 or count > 200 then return end
    local tracked = Read(C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID)
    if not ID(tracked, 1000000000) then tracked = nil end
    local best
    for index = 1, count do
        local info = Read(api.GetInfo, index)
        if Suite.IsReadable(info) and type(info) == "table" and ID(info.questID, 1000000000)
            and Suite.IsReadable(info.isHeader) and info.isHeader ~= true
            and Suite.IsReadable(info.isHidden) and info.isHidden ~= true then
            local complete = Read(api.IsComplete, info.questID)
            local link, icon, _, showComplete = Read(GetQuestLogSpecialItemInfo, index)
            local item = Text(link, 2048) and tonumber(link:match("item:(%d+)")) or nil
            if ID(item) and (complete == false or complete == true and Yes(showComplete)) then
                local countCarried = Read(C_Item and C_Item.GetItemCount, item, false, false, false, false)
                local inside = Read(C_Minimap and C_Minimap.IsInsideQuestBlob, info.questID) == true
                local distance, sameContinent = Read(api.GetDistanceSqToQuest, info.questID)
                local nearby = sameContinent == true and Number(distance) and distance >= 0 and distance <= 62500
                if ID(countCarried, 1000000000) and (inside or nearby) then
                    local range = Read(IsQuestLogSpecialItemInRange, index)
                    local candidate = { questID = info.questID, index = index, id = item, link = link,
                        icon = ID(icon, 2147483647) and icon or 134400,
                        title = Text(info.title, 256) and info.title or "Quest item", count = countCarried,
                        rank = inside and 2 or 1, tracked = info.questID == tracked,
                        distance = nearby and distance or math.huge, range = range == false or range == 0 }
                    if not best or candidate.rank > best.rank or candidate.rank == best.rank
                        and (candidate.tracked and not best.tracked or candidate.tracked == best.tracked
                            and (candidate.distance < best.distance or candidate.distance == best.distance and candidate.questID < best.questID)) then
                        best = candidate
                    end
                end
            end
        end
    end
    return best
end
function QuestItem:Place()
    Suite.AfterCombat("questItemPosition", function()
        if not self.button or self.moving then return end
        local position = Suite.BagSpace:InitializePosition(Suite.db.questItemPosition)
        local width, height = UIParent:GetWidth(), UIParent:GetHeight()
        if not Number(width) or not Number(height) or width <= 0 or height <= 0 then return end
        self.button:ClearAllPoints()
        self.button:SetPoint("CENTER", UIParent, "CENTER", position.x and position.x * width or 58, position.y and position.y * height or 0)
    end)
end
function QuestItem:HideTooltip()
    if self.hovered and GameTooltip and Read(GameTooltip.GetOwner, GameTooltip) == self.button
        and Read(GameTooltip.IsForbidden, GameTooltip) == false
        and (not InCombatLockdown() or Read(GameTooltip.IsProtected, GameTooltip) == false) then GameTooltip:Hide() end
    self.hovered = nil
end
function QuestItem:Tooltip()
    local candidate, tip = self.candidate, GameTooltip
    if not candidate or self.moving or InCombatLockdown() or not tip or Read(tip.IsForbidden, tip) ~= false then return end
    tip:SetOwner(self.button, "ANCHOR_RIGHT"); self.hovered = true
    if type(tip.SetHyperlink) == "function" then tip:SetHyperlink(candidate.link)
    else tip:ClearLines(); tip:AddLine("Quest item") end
    tip:AddLine(" "); tip:AddLine(candidate.title, 0.41, 0.84, 0.75)
    tip:AddLine(candidate.count .. " carried", 0.88, 0.91, 0.93)
    tip:AddLine("Left-click: use quest item", 0.41, 0.84, 0.75)
    tip:AddLine("Left-drag: move · Ctrl-right-click: reset position", 0.55, 0.65, 0.7)
    tip:Show()
end
function QuestItem:StopDrag(save)
    if not self.moving then return end
    if InCombatLockdown() then
        self.cancelMove = true
        Suite.pending.questItemMove = function() self:StopDrag(false) end
        return
    end
    self.button:StopMovingOrSizing(); self.moving = nil
    if save and not self.cancelMove and self:Enabled() then
        local x, y = self.button:GetCenter()
        local scale, parentScale = self.button:GetEffectiveScale(), UIParent:GetEffectiveScale()
        local width, height = UIParent:GetWidth(), UIParent:GetHeight()
        if Number(x) and Number(y) and Number(scale) and scale > 0 and Number(parentScale) and parentScale > 0
            and Number(width) and width > 0 and Number(height) and height > 0 then
            local ratio = scale / parentScale
            Suite.db.questItemPosition = { x = math.max(-0.5, math.min(0.5, x * ratio / width - 0.5)),
                y = math.max(-0.5, math.min(0.5, y * ratio / height - 0.5)) }
        end
    end
    self.cancelMove = nil; Suite.pending.questItemMove = nil; self:Place()
end
function QuestItem:Build()
    if self.button then return true end
    if InCombatLockdown() or type(RegisterStateDriver) ~= "function" then return false end
    local controller = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
    self.controller = controller
    -- The named action target is declared solely for the native CLICK binding.
    local button = CreateFrame("Button", "WoWForeverSuiteQuestItemButton", controller, "SecureActionButtonTemplate,BackdropTemplate")
    self.button = button
    button:Hide(); button:SetSize(48, 48); button:SetFrameStrata("LOW"); button:SetFrameLevel(1)
    button:SetClampedToScreen(true); button:SetMovable(true); button:RegisterForDrag("LeftButton")
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    button:SetBackdropColor(0.035, 0.05, 0.065, 0.96); Suite.Theme:Backdrop(button, 0.7)
    button.icon = button:CreateTexture(nil, "ARTWORK"); button.icon:SetSize(44, 44); button.icon:SetPoint("CENTER")
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetSize(44, 44); button.cooldown:SetPoint("CENTER")
    button:RegisterForClicks("AnyUp", "AnyDown"); button:SetAttribute("useOnKeyDown", false)
    controller:SetFrameRef("button", button)
    controller:SetAttribute("_onstate-combat", [[
        if newstate == "blocked" then
            local button = self:GetFrameRef("button")
            button:SetAttribute("type1", nil)
            button:Hide()
            self:Hide()
        else
            self:Show()
        end
    ]])
    RegisterStateDriver(controller, "combat", "[combat][dead] blocked; peaceful")
    button:SetScript("OnMouseDown", function() if not self.moving then self.suppressClick = nil end end)
    button:SetScript("OnDragStart", function()
        if InCombatLockdown() or not self:Enabled() or not CursorEmpty() then return end
        self.moving, self.suppressClick = true, true
        button:SetAttribute("type1", nil); self:HideTooltip(); button:StartMoving()
    end)
    button:SetScript("OnDragStop", function() self:StopDrag(true) end)
    button:SetScript("PreClick", function(_, mouse, down)
        if InCombatLockdown() or down then return end
        if mouse == "RightButton" then
            if Read(IsControlKeyDown) == true then Suite.db.questItemPosition = {}; self:Place() end
            return
        end
        local fresh = self:Enabled() and not self.moving and not self.suppressClick and CursorEmpty() and self:Find()
        local old = self.candidate
        if mouse ~= "LeftButton" or not fresh or not old or fresh.id ~= old.id or fresh.questID ~= old.questID then
            button:SetAttribute("type1", nil)
        end
    end)
    button:SetScript("PostClick", function(_, _, down) if not down then self:Queue() end end)
    button:SetScript("OnEnter", function() Suite.Theme:Backdrop(button, 1); self:Tooltip() end)
    button:SetScript("OnLeave", function() Suite.Theme:Backdrop(button, 0.7); self:HideTooltip() end)
    button:SetScript("OnHide", function() self:HideTooltip(); self:StopDrag(false) end)
    self:Place(); return true
end
function QuestItem:Refresh()
    if InCombatLockdown() then Suite.pending.questItemRefresh = function() self:Refresh() end; return end
    if not self:Enabled() or not self.active then
        self.candidate = nil
        if self.button then self.button:SetAttribute("type1", nil); self.button:SetAttribute("macrotext1", nil); self.button:Hide() end
        return
    end
    if not self:Build() or self.moving then return end
    local candidate = self:Find(); self.candidate = candidate
    -- The native condition also gates bindings to this named button, which can
    -- otherwise click hidden secure frames before a visibility driver updates.
    self.button:SetAttribute("type1", candidate and "macro" or nil)
    self.button:SetAttribute("macrotext1", candidate and "/use [nocombat,nodead] item:" .. candidate.id or nil)
    if candidate then
        self.button.icon:SetTexture(candidate.icon)
        self.button.icon:SetVertexColor(1, candidate.range and 0.25 or 1, candidate.range and 0.25 or 1)
        local start, duration, enabled = Read(C_Item and C_Item.GetItemCooldown, candidate.id)
        if Number(start) and start >= 0 and Number(duration) and duration >= 0 and enabled == true then
            self.button.cooldown:SetCooldown(start, duration)
        else self.button.cooldown:Clear() end
        self.button:Show(); if self.hovered then self:Tooltip() end
    else self.button:Hide() end
end
function QuestItem:Cancel()
    if self.timer then self.timer:Cancel(); self.timer = nil end
    if self.moveTimer then self.moveTimer:Cancel(); self.moveTimer = nil end
end
function QuestItem:Queue()
    if not self.active or not self:Enabled() or self.shuttingDown then return end
    if InCombatLockdown() then Suite.pending.questItemRefresh = function() self:Refresh() end; return end
    if not self.timer and C_Timer and type(C_Timer.NewTimer) == "function" then
        self.timer = C_Timer.NewTimer(0.12, function() self.timer = nil; self:Refresh() end)
    end
end
function QuestItem:MovingScan()
    if not self.traveling or self.moveTimer or not self.active or InCombatLockdown() then return end
    if C_Timer and type(C_Timer.NewTimer) == "function" then
        self.moveTimer = C_Timer.NewTimer(0.5, function()
            self.moveTimer = nil
            local speed = Read(GetUnitSpeed, "player")
            self.traveling = Number(speed) and speed > 0 or nil
            self:Queue(); self:MovingScan()
        end)
    end
end
function QuestItem:OnEvent(event)
    if event == "PLAYER_LOGOUT" then self.shuttingDown = true; self:Cancel(); self:HideTooltip(); return end
    if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_DEAD" then self:Cancel(); self:HideTooltip(); return end
    if event == "PLAYER_STARTED_MOVING" then self.traveling = true; self:MovingScan()
    elseif event == "PLAYER_STOPPED_MOVING" then
        self.traveling = nil; if self.moveTimer then self.moveTimer:Cancel(); self.moveTimer = nil end
    elseif event == "PLAYER_REGEN_ENABLED" then self:StopDrag(false); self:MovingScan()
    elseif event == "PLAYER_ENTERING_WORLD" then
        local speed = Read(GetUnitSpeed, "player")
        self.traveling = Number(speed) and speed > 0 or nil; self:MovingScan()
    elseif event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" then self:StopDrag(false); self:Place() end
    self:Queue()
end
function QuestItem:Apply()
    Suite.pending.questItemApply = nil
    if not self:Enabled() then
        self.active, self.traveling = nil, nil; self:Cancel(); self:HideTooltip()
        Suite.pending.questItemRefresh = nil
        if self.events then self.events:UnregisterAllEvents() end
        Suite.AfterCombat("questItemDisable", function() self:StopDrag(false); self:Refresh() end)
        return
    end
    Suite.pending.questItemDisable = nil
    Suite.AfterCombat("questItemApply", function()
        if not self:Enabled() or self.active then return end
        if not self:Build() then return end
        self.active, self.shuttingDown = true, nil
        local speed = Read(GetUnitSpeed, "player")
        self.traveling = Number(speed) and speed > 0 or nil
        self:MovingScan()
        self.events = self.events or CreateFrame("Frame")
        self.events:SetScript("OnEvent", function(_, event) self:OnEvent(event) end)
        for _, event in ipairs({ "QUEST_LOG_UPDATE", "QUEST_POI_UPDATE", "SUPER_TRACKING_CHANGED", "PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED",
            "PLAYER_TARGET_CHANGED", "BAG_UPDATE_DELAYED", "BAG_UPDATE_COOLDOWN", "SPELL_UPDATE_COOLDOWN", "PLAYER_ENTERING_WORLD",
            "PLAYER_STARTED_MOVING", "PLAYER_STOPPED_MOVING", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_ALIVE", "PLAYER_UNGHOST",
            "PLAYER_DEAD", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA", "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED", "PLAYER_LOGOUT" }) do
            local valid = not C_EventUtils or type(C_EventUtils.IsEventValid) ~= "function" or Read(C_EventUtils.IsEventValid, event) == true
            if valid then pcall(self.events.RegisterEvent, self.events, event) end
        end
        self:Refresh()
    end)
end
