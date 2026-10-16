local _, Suite = ...
local Windows = { tracked = {}, watched = {}, bagRecords = {} }
Suite.Windows = Windows
table.insert(Suite.modules, Windows)

Windows.names = {
    "CharacterFrame", "SpellBookFrame", "PlayerSpellsFrame", "TalentFrame", "QuestLogFrame",
    "WorldMapFrame", "FriendsFrame", "GuildFrame", "CommunitiesFrame", "InspectFrame",
    "AchievementFrame", "CollectionsJournal", "MerchantFrame", "GossipFrame", "QuestFrame",
    "MailFrame", "BankFrame", "TradeFrame", "AuctionFrame", "AuctionHouseFrame",
    "TradeSkillFrame", "ProfessionsFrame", "ClassTrainerFrame", "PetStableFrame",
    "LootFrame", "GameMenuFrame", "SettingsPanel", "LFGParentFrame", "PVPParentFrame", "CalendarFrame",
    "TimeManagerFrame", "StopwatchFrame",
    "ContainerFrameCombinedBags",
}

local bagNames = { "ContainerFrameCombinedBags" }
local isBagName = { ContainerFrameCombinedBags = true }
local isBankName = { BankFrame = true, WoWForeverSuiteBankView = true }
for index = 1, 13 do
    local name = "ContainerFrame" .. index
    Windows.names[#Windows.names + 1] = name
    bagNames[#bagNames + 1] = name
    isBagName[name] = true
end

local function CanTouch(frame)
    return not InCombatLockdown() and not (frame.IsForbidden and frame:IsForbidden())
end

local function ReadableNumber(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function CursorInside(frame)
    if not CanTouch(frame) or not frame:IsVisible() then return false end
    local x, y = GetCursorPosition()
    local left, bottom, width, height = frame:GetRect()
    local scale = frame:GetEffectiveScale()
    if not ReadableNumber(x) or not ReadableNumber(y) or not ReadableNumber(left)
        or not ReadableNumber(bottom) or not ReadableNumber(width) or not ReadableNumber(height)
        or not ReadableNumber(scale) or scale <= 0 then return false end
    x, y = x / scale, y / scale
    return x >= left and x <= left + width and y >= bottom and y <= bottom + height
end

local function AddRect(rects, left, bottom, right, top)
    if right - left >= 8 and top - bottom >= 6 then
        rects[#rects + 1] = { left = left, bottom = bottom, right = right, top = top }
    end
end

local function Subtract(rects, block)
    local result = {}
    for _, rect in ipairs(rects) do
        local left, right = math.max(rect.left, block.left), math.min(rect.right, block.right)
        local bottom, top = math.max(rect.bottom, block.bottom), math.min(rect.top, block.top)
        if left < right and bottom < top then
            AddRect(result, rect.left, rect.bottom, rect.right, bottom)
            AddRect(result, rect.left, top, rect.right, rect.top)
            AddRect(result, rect.left, bottom, left, top)
            AddRect(result, right, bottom, rect.right, top)
        else
            result[#result + 1] = rect
        end
    end
    return result
end

local function Overlaps(rects, block)
    for _, rect in ipairs(rects) do
        if block.left < rect.right and block.right > rect.left and block.bottom < rect.top and block.top > rect.bottom then return true end
    end
    return false
end

local controlTypes = { Button = true, CheckButton = true, DropdownButton = true, ItemButton = true, EditBox = true, Slider = true }
local function IsInputControl(child, height)
    local kind = child:GetObjectType()
    if not Suite.IsReadable(kind) then return false end
    if controlTypes[kind] then return true end
    -- Mouse-enabled decoration/layout frames are not clickable header controls.
    -- Large content frames (models, scroll containers) do not own the title bar.
    if height > 64 or not child.GetScript then return false end
    for _, script in ipairs({ "OnMouseDown", "OnMouseUp", "OnDragStart" }) do
        if not child.HasScript or child:HasScript(script) then
            local callback = child:GetScript(script)
            if Suite.IsReadable(callback) and type(callback) == "function" then return true end
        end
    end
    return false
end

function Windows:HideHint(handle)
    if self.hintOwner and (not handle or self.hintOwner == handle) then
        if GameTooltip and GameTooltip:IsOwned(self.hintOwner) then GameTooltip:Hide() end
        self.hintOwner = nil
    end
end

function Windows:ShowHint(record, handle)
    self:HideHint()
    if not GameTooltip or not Suite.db.windowTools or not handle:IsVisible() or record.dragging then return end
    GameTooltip:SetOwner(handle, "ANCHOR_CURSOR")
    GameTooltip:AddLine("Window controls", 1, 0.82, 0)
    GameTooltip:AddLine("Click and drag to move", 1, 1, 1)
    GameTooltip:AddLine("Ctrl+scroll to resize", 1, 1, 1)
    GameTooltip:AddLine("Ctrl+right-click to reset", 1, 1, 1)
    if record.name:match("^ContainerFrame") then GameTooltip:AddLine("Click the title to open its menu", 0.7, 0.7, 0.7) end
    if InCombatLockdown() then GameTooltip:AddLine("Movement is available outside combat", 1, 0.82, 0) end
    self.hintOwner = handle
    GameTooltip:Show()
end

function Windows:HeaderRects(record)
    local frame = record.frame
    local width = frame:GetWidth()
    if not ReadableNumber(width) then return {} end
    local rects = {}
    if record.name == "StopwatchFrame" then
        -- Its title tab is only sixteen units tall; the timer and playback controls
        -- occupy the rest of the compact window. Child exclusion keeps X clickable.
        AddRect(rects, 4, -15, width - 4, -2)
    elseif record.name == "CalendarFrame" then
        -- The calendar has a raised month title and a lower bar on either side.
        AddRect(rects, 8, -44, width - 36, -22)
        AddRect(rects, width / 2 - 73, -22, width / 2 + 67, -2)
    else
        local portrait = frame.PortraitContainer or frame.PortraitButton
        AddRect(rects, portrait and 54 or 4, record.name:match("^ContainerFrame") and -38 or -32, width - 36, -2)
    end
    local frameLeft, frameBottom, _, height = frame:GetRect()
    local frameScale = frame:GetEffectiveScale()
    if not ReadableNumber(frameLeft) or not ReadableNumber(frameBottom) or not ReadableNumber(height)
        or not ReadableNumber(frameScale) or frameScale <= 0 then return {} end
    local frameTop = frameBottom + height
    local originalRects = rects
    record.headerWatched = record.headerWatched or {}
    record.headerLevel = frame:GetFrameLevel() + 1
    record.bagTitleRouters = {}

    local function WatchChild(child)
        if record.headerWatched[child] then return end
        record.headerWatched[child] = true
        local function Refresh() self:Schedule(record) end
        child:HookScript("OnShow", Refresh)
        child:HookScript("OnHide", Refresh)
        child:HookScript("OnSizeChanged", Refresh)
        hooksecurefunc(child, "SetPoint", Refresh)
    end

    local function ExcludeChildren(parent, depth)
        if not parent.GetChildren then return true end
        for _, child in ipairs({ parent:GetChildren() }) do
            if Suite.IsReadable(child) and not (record.owned and record.owned[child]) and not (child.IsForbidden and child:IsForbidden()) then
                local visible = child:IsVisible()
                if not Suite.IsReadable(visible) then return false end
                local left, bottom, childWidth, childHeight = child:GetRect()
                local scale = child:GetEffectiveScale()
                local known = ReadableNumber(left) and ReadableNumber(bottom) and ReadableNumber(childWidth)
                    and ReadableNumber(childHeight) and ReadableNumber(scale)
                if known then
                    local ratio = scale / frameScale
                    local bounds = {
                        left = left * ratio - frameLeft, right = (left + childWidth) * ratio - frameLeft,
                        bottom = bottom * ratio - frameTop, top = (bottom + childHeight) * ratio - frameTop,
                    }
                    if Overlaps(originalRects, bounds) then
                        WatchChild(child)
                        if visible then
                            local level = child:GetFrameLevel()
                            if ReadableNumber(level) then record.headerLevel = math.max(record.headerLevel, level + 1) end
                            local name = child:GetName()
                            if Suite.IsReadable(name) and type(name) == "string" and (name:find("Blocker") or name:find("Modal")) then return false end
                        end
                    end
                end
                local eligible = known and IsInputControl(child, childHeight)
                if eligible then
                    local insetLeft, insetRight, insetTop, insetBottom = 0, 0, 0, 0
                    if child.GetHitRectInsets then insetLeft, insetRight, insetTop, insetBottom = child:GetHitRectInsets() end
                    if not ReadableNumber(insetLeft) or not ReadableNumber(insetRight)
                        or not ReadableNumber(insetTop) or not ReadableNumber(insetBottom) then return false end
                    local ratio = scale / frameScale
                    local block = {
                        left = (left + insetLeft) * ratio - frameLeft - 2,
                        right = (left + childWidth - insetRight) * ratio - frameLeft + 2,
                        bottom = (bottom + insetBottom) * ratio - frameTop - 2,
                        top = (bottom + childHeight - insetTop) * ratio - frameTop + 2,
                    }
                    if Overlaps(originalRects, block) then WatchChild(child) end
                    -- Blizzard routes the entire bag title to its portrait menu.
                    -- Share that surface by distinguishing a click from a drag.
                    local route = child.routeToSibling
                    local bagTitle = record.name:match("^ContainerFrame") and Suite.IsReadable(route) and route == "PortraitButton"
                    if visible and bagTitle then
                        record.bagTitleRouters[#record.bagTitleRouters + 1] = child
                    elseif visible then
                        rects = Subtract(rects, block)
                    end
                elseif visible and (not Suite.IsReadable(left) or not Suite.IsReadable(bottom)
                    or not Suite.IsReadable(childWidth) or not Suite.IsReadable(childHeight) or not Suite.IsReadable(scale)) then
                    -- Restricted input controls are uncertain; unrelated decorations need not disable a header.
                    local kind = child:GetObjectType()
                    if Suite.IsReadable(kind) and controlTypes[kind] then return false end
                end
                if visible then
                    if depth < 12 and not ExcludeChildren(child, depth + 1) then return false end
                end
            end
        end
        return true
    end
    -- Leave an uncertain or restricted header alone rather than covering an unknown control.
    if not ExcludeChildren(frame, 0) then return {} end
    table.sort(rects, function(a, b)
        return (a.right - a.left) * (a.top - a.bottom) > (b.right - b.left) * (b.top - b.bottom)
    end)
    return rects
end

function Windows:LayoutHeader(record)
    local rects = self:HeaderRects(record)
    record.owned = record.owned or {}
    for index, rect in ipairs(rects) do
        local handle = record.handles[index]
        if not handle then
            handle = CreateFrame("Frame", nil, record.frame)
            record.handles[index] = handle
            record.owned[handle] = true
            handle:EnableMouse(true)
            handle:EnableMouseWheel(true)
            handle:RegisterForDrag("LeftButton")
            handle:SetScript("OnDragStart", record.dragStart)
            handle:SetScript("OnDragStop", record.dragStop)
            handle:SetScript("OnEnter", function() self:ShowHint(record, handle) end)
            handle:SetScript("OnLeave", function() self:HideHint(handle) end)
            handle:SetScript("OnHide", function() self:HideHint(handle) end)
            handle:SetScript("OnMouseDown", function(_, button)
                self:HideHint(handle)
                record.mouseDown(handle, button)
            end)
            handle:SetScript("OnMouseUp", record.mouseUp)
            handle:SetScript("OnMouseWheel", function(_, delta)
                self:HideHint(handle)
                record.titleClick = nil
                self:Resize(record, delta)
            end)
        end
        handle:ClearAllPoints()
        handle:SetSize(rect.right - rect.left, rect.top - rect.bottom)
        handle:SetPoint("TOPLEFT", record.frame, "TOPLEFT", rect.left, rect.top)
    end
    record.headerRects = rects
    record.handle = record.handles[1]
    for index, handle in ipairs(record.handles) do handle:SetShown(index <= #rects) end
end

function Windows:CapturePosition(frame)
    local x, y = frame:GetCenter()
    local scale, parentScale = frame:GetEffectiveScale(), UIParent:GetEffectiveScale()
    local width, height, ownScale = UIParent:GetWidth(), UIParent:GetHeight(), frame:GetScale()
    if not ReadableNumber(x) or not ReadableNumber(y) or not ReadableNumber(scale) or scale <= 0
        or not ReadableNumber(parentScale) or parentScale <= 0 or not ReadableNumber(ownScale) or ownScale <= 0
        or not ReadableNumber(width) or width <= 0 or not ReadableNumber(height) or height <= 0 then return end
    local ratio = scale / parentScale
    return {
        x = (x * ratio - width / 2) / width,
        y = (y * ratio - height / 2) / height,
        scale = ownScale,
    }
end

function Windows:Save(record)
    local position = self:CapturePosition(record.frame)
    if position then
        Suite.db.windowPositions[record.name] = position
        if Suite.InventorySearch then Suite.InventorySearch:WindowChanged(record.frame) end
    end
end

function Windows:Restore(record)
    if not CanTouch(record.frame) then return end
    record.applying = true
    record.frame:SetScale(record.originalScale)
    record.frame:ClearAllPoints()
    for _, point in ipairs(record.originalPoints) do record.frame:SetPoint(unpack(point)) end
    record.applying = false
end

-- The general mover defers combat layout. Only known native bags whose runtime
-- protection predicate is readably false can restore their existing geometry.
function Windows:ApplySavedPosition(record, saved)
    local frame = record.frame
    if frame.IsForbidden then
        local forbidden = frame:IsForbidden()
        if not Suite.IsReadable(forbidden) or forbidden ~= false then return false end
    end
    if InCombatLockdown() then
        if not isBagName[record.name] or not frame.IsProtected then return false end
        local protected = frame:IsProtected()
        if not Suite.IsReadable(protected) or protected ~= false then return false end
    end
    if record.dragging and not record.cancelDrag then return false end
    if not Suite.IsReadable(saved) or type(saved) ~= "table" or not ReadableNumber(saved.x)
        or not ReadableNumber(saved.y) or not ReadableNumber(saved.scale) then return false end
    local scale = math.max(0.55, math.min(1.8, saved.scale))
    local currentScale, effectiveScale, parentScale = frame:GetScale(), frame:GetEffectiveScale(), UIParent:GetEffectiveScale()
    local width, height, frameWidth, frameHeight = UIParent:GetWidth(), UIParent:GetHeight(), frame:GetWidth(), frame:GetHeight()
    if not ReadableNumber(currentScale) or currentScale <= 0 or not ReadableNumber(effectiveScale) or effectiveScale <= 0
        or not ReadableNumber(parentScale) or parentScale <= 0 or not ReadableNumber(width) or width <= 0
        or not ReadableNumber(height) or height <= 0 or not ReadableNumber(frameWidth) or not ReadableNumber(frameHeight) then return false end
    record.applying = true
    if currentScale ~= scale then frame:SetScale(scale) end
    effectiveScale = frame:GetEffectiveScale()
    if not ReadableNumber(effectiveScale) or effectiveScale <= 0 then record.applying = false; return false end
    local ratio = effectiveScale / parentScale
    if not ReadableNumber(ratio) or ratio <= 0 then record.applying = false; return false end
    local limitX = math.max(0, (width - frameWidth * ratio) / 2)
    local limitY = math.max(0, (height - frameHeight * ratio) / 2)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER",
        math.max(-limitX, math.min(limitX, saved.x * width)) / ratio,
        math.max(-limitY, math.min(limitY, saved.y * height)) / ratio)
    record.applying = false
    record.wasApplied = true
    if isBagName[record.name] then self.bagsHeld = true end
    if Suite.InventorySearch then Suite.InventorySearch:WindowChanged(frame) end
    return true
end

-- Settle saved windows within their opening call. Bags need their own completed
-- container pass; native panels must finish calculating sibling sizes first.
function Windows:PlaceWindow(name, frame)
    if not Suite.IsReadable(name) or type(name) ~= "string" or isBagName[name]
        or not Suite.db.windowTools or InCombatLockdown() then return end
    if FramePositionDelegate then
        local updating = FramePositionDelegate.updatingPanels
        if not Suite.IsReadable(updating) or updating then return end
    end
    if not Suite.IsReadable(frame) or not frame or not frame.IsShown then return end
    if frame.IsForbidden then
        local forbidden = frame:IsForbidden()
        if not Suite.IsReadable(forbidden) or forbidden ~= false then return end
    end
    local shown = frame:IsShown()
    if not Suite.IsReadable(shown) or shown ~= true then return end
    local supported = self.tracked[name] or self.watched[frame] or isBankName[name]
        or (UIPanelWindows and UIPanelWindows[name])
    if not supported then
        for _, known in ipairs(self.names) do if known == name and _G[name] == frame then supported = true; break end end
    end
    if not supported then return end
    local saved = Suite.db.windowPositions[name]
    if not Suite.IsReadable(saved) or type(saved) ~= "table" or not ReadableNumber(saved.x)
        or not ReadableNumber(saved.y) or not ReadableNumber(saved.scale) then return end
    local record = self.tracked[name]
    if not record then
        -- Capture Blizzard's initial anchors before applying the saved placement.
        self:Track(name, frame)
        return
    end
    if record.frame ~= frame or record.applying or record.dragging or record.cancelDrag then return end
    self:ApplySavedPosition(record, saved)
end

function Windows:HoldWindowPositions()
    if not Suite.db.windowTools or InCombatLockdown() then return end
    for name, record in pairs(self.tracked) do self:PlaceWindow(name, record.frame) end
    for _, name in ipairs(self.names) do
        if not self.tracked[name] then self:PlaceWindow(name, _G[name]) end
    end
    for name in pairs(UIPanelWindows or {}) do
        if Suite.IsReadable(name) and type(name) == "string" and not self.tracked[name] then self:PlaceWindow(name, _G[name]) end
    end
end

function Windows:HoldBagPositions()
    if not Suite.db.windowTools or self.holdingBags then return end
    self.holdingBags = true
    for _, name in ipairs(bagNames) do
        local frame, saved = _G[name], Suite.db.windowPositions[name]
        if Suite.IsReadable(frame) and frame and Suite.IsReadable(saved) and type(saved) == "table" then
            local forbidden = false
            if frame.IsForbidden then forbidden = frame:IsForbidden() end
            if Suite.IsReadable(forbidden) and forbidden == false then
                local shown = frame:IsShown()
                if Suite.IsReadable(shown) and shown == true then
                    local record = self.tracked[name] or self.bagRecords[name]
                    if not record or record.frame ~= frame then
                        if InCombatLockdown() then
                            -- A bag first opened in combat needs no header/frame creation.
                            record = { name = name, frame = frame }
                            self.bagRecords[name] = record
                        else
                            -- Capture the completed native layout before the first saved restore,
                            -- so disabling/resetting never treats our saved anchor as the default.
                            self:Track(name, frame)
                            record = self.tracked[name]
                        end
                    end
                    if record and record.frame == frame then self:ApplySavedPosition(record, saved) end
                end
            end
        end
    end
    self.holdingBags = nil
end

function Windows:ApplyRecord(record)
    local frame = record.frame
    if frame.IsForbidden and frame:IsForbidden() then return end
    if InCombatLockdown() then
        record.queued = true
        self:QueueWork()
        return
    end
    if record.dragging then return end
    local saved = Suite.db.windowTools and Suite.db.windowPositions[record.name]
    if Suite.IsReadable(saved) and type(saved) == "table" and ReadableNumber(saved.x)
        and ReadableNumber(saved.y) and ReadableNumber(saved.scale) then
        if not self:ApplySavedPosition(record, saved) then return end
    elseif record.wasApplied then
        self:Restore(record)
        record.wasApplied = false
    end
    local visible = Suite.db.windowTools and frame:IsShown()
    if not visible then
        for _, handle in ipairs(record.handles) do self:HideHint(handle) end
    end
    if visible and not record.dragging then self:LayoutHeader(record) end
    for index, handle in ipairs(record.handles) do
        handle:SetShown(visible and index <= #(record.headerRects or {}))
        if visible then
            handle:SetFrameStrata(frame:GetFrameStrata())
            handle:SetFrameLevel(record.headerLevel or frame:GetFrameLevel() + 1)
        end
    end
    if Suite.InventorySearch then Suite.InventorySearch:WindowChanged(frame) end
end

function Windows:Resize(record, delta)
    if not Suite.db.windowTools or not IsControlKeyDown() or not ReadableNumber(delta) or delta == 0
        or record.dragging or not CanTouch(record.frame) then return end
    local scale = record.frame:GetScale()
    if not ReadableNumber(scale) then return end
    self:Save(record)
    local position = Suite.db.windowPositions[record.name]
    if not position then return end
    position.scale = math.max(0.55, math.min(1.8, scale + delta * 0.05))
    self:ApplyRecord(record)
end

function Windows:Status()
    Suite.Print("Window tools: " .. (Suite.db.windowTools and "enabled" or "disabled") .. "; combat: " .. (InCombatLockdown() and "yes" or "no"))
    local names = {}
    for name, record in pairs(self.tracked) do if record.frame:IsShown() then names[#names + 1] = name end end
    table.sort(names)
    for _, name in ipairs(names) do
        local record = self.tracked[name]
        Suite.Print(name .. ": " .. #(record.headerRects or {}) .. " header regions; input layer " .. tostring(record.headerLevel))
    end
    if #names == 0 then Suite.Print("No tracked windows are open.") end
end

function Windows:CancelTimer()
    if self.timer then self.timer:Cancel(); self.timer = nil end
end

-- All native layout hooks share one cancellable next-frame pass. Combat keeps
-- only dirty flags and one deferred callback, without timers or header scans.
function Windows:QueueWork()
    if self.flushing or self.timer then return end
    if InCombatLockdown() then
        if not Suite.pending.windowWork then Suite.AfterCombat("windowWork", self.flush) end
    else
        self.timer = C_Timer.NewTimer(0, self.flush)
    end
end

function Windows:Flush()
    self:CancelTimer()
    if InCombatLockdown() then self:QueueWork(); return end
    Suite.pending.windowWork = nil
    self.flushing = true
    if self.discoverPending then
        self.discoverPending = nil
        self:Discover()
    end
    for _, record in pairs(self.tracked) do
        if record.queued then
            record.queued = nil
            if record.cancelDrag then self:StopDrag(record, true)
            else self:ApplyRecord(record) end
        end
    end
    self.flushing = nil
    if not Suite.db.windowTools and self.bagsHeld then
        self.bagsHeld = nil
        if UpdateContainerFrameAnchors then UpdateContainerFrameAnchors() end
    end
    for _, record in pairs(self.tracked) do
        if record.queued then self:QueueWork(); break end
    end
end
Windows.flush = function() Windows:Flush() end

function Windows:Schedule(record)
    if not Suite.db.windowTools or record.applying or record.queued or record.dragging
        or (record.frame.IsForbidden and record.frame:IsForbidden()) then return end
    record.queued = true
    self:QueueWork()
end

function Windows:QueueDiscovery()
    if not Suite.db.windowTools then return end
    self.discoverPending = true
    self:QueueWork()
end

function Windows:StopDrag(record, cancel)
    if not record.dragging then return end
    record.titleClick = nil
    if cancel or InCombatLockdown() or not Suite.db.windowTools then record.cancelDrag = true end
    if record.frame.IsForbidden and record.frame:IsForbidden() then
        record.dragging, record.cancelDrag, record.queued, record.moveStopped = nil, nil, nil, nil
        return
    end
    if not CanTouch(record.frame) then
        -- An ordinary window can stop following the cursor immediately. Leave
        -- protected/unknown movement and all layout restoration for combat exit.
        if not record.moveStopped and record.frame.IsProtected then
            local protected = record.frame:IsProtected()
            if Suite.IsReadable(protected) and protected == false then
                record.frame:StopMovingOrSizing()
                record.moveStopped = true
            end
        end
        record.queued = true
        if InCombatLockdown() then self:QueueWork() end
        return
    end
    if not record.moveStopped then record.frame:StopMovingOrSizing() end
    record.moveStopped = nil
    record.frame:SetMovable(record.originalMovable)
    record.dragging = nil
    if not record.cancelDrag then self:Save(record) end
    record.cancelDrag = nil
    self:ApplyRecord(record)
end

function Windows:Pause()
    self:CancelTimer()
    self:HideHint()
    for _, record in pairs(self.tracked) do
        record.titleClick = nil
        if record.dragging then self:StopDrag(record, true) end
        if record.queued then self:QueueWork() end
    end
    if self.discoverPending then self:QueueWork() end
end

function Windows:Reset(record)
    Suite.AfterCombat("windowReset:" .. record.name, function()
        Suite.db.windowPositions[record.name] = nil
        self:Restore(record)
        record.wasApplied = false
        if record.name == "WoWForeverSuiteBankView" and Suite.OfflineBank then Suite.OfflineBank:PlaceView() end
        if record.name:match("^ContainerFrame") and UpdateContainerFrameAnchors then UpdateContainerFrameAnchors() end
        self:ApplyRecord(record)
    end)
end

function Windows:Track(name, frame)
    if frame and frame.foreverMeter then return end
    if self.tracked[name] then self:Schedule(self.tracked[name]); return end
    if not CanTouch(frame) or not frame.GetNumPoints or not frame.SetScale then return end
    local scale, count = frame:GetScale(), frame:GetNumPoints()
    if not ReadableNumber(scale) or scale <= 0 or not ReadableNumber(count) or count < 1 then return end
    local record = { name = name, frame = frame, handles = {}, originalPoints = {}, originalScale = scale }
    for i = 1, count do
        local point = { frame:GetPoint(i) }
        for _, value in pairs(point) do if not Suite.IsReadable(value) then return end end
        record.originalPoints[i] = point
    end
    if #record.originalPoints == 0 then return end
    self.tracked[name] = record
    record.dragStart = function()
        self:HideHint()
        record.titleClick = nil
        if record.dragging or not Suite.db.windowTools or not CanTouch(frame) then return end
        local movable = frame:IsMovable()
        if not Suite.IsReadable(movable) or type(movable) ~= "boolean" then return end
        record.dragging = true
        record.wasApplied = true
        record.originalMovable = movable
        frame:SetMovable(true)
        frame:StartMoving()
    end
    record.dragStop = function()
        self:StopDrag(record)
    end
    if name == "StopwatchFrame" then
        -- The native stopwatch can also drag from its body. Observe its existing
        -- gesture so saved placement does not fight it and native releases save too.
        frame:HookScript("OnDragStart", function()
            if record.dragging or not Suite.db.windowTools or not CanTouch(frame) then return end
            local movable = frame:IsMovable()
            if not Suite.IsReadable(movable) or type(movable) ~= "boolean" then return end
            self:HideHint()
            record.originalMovable, record.dragging, record.wasApplied = movable, true, true
        end)
        frame:HookScript("OnDragStop", record.dragStop)
    end
    local function ResetClick(_, button)
        if Suite.db.windowTools and button == "RightButton" and IsControlKeyDown() then self:Reset(record) end
    end
    record.resetClick = ResetClick
    record.mouseDown = function(_, button)
        record.titleClick = nil
        if not Suite.db.windowTools or button ~= "LeftButton" or IsControlKeyDown() or not CanTouch(frame) then return end
        for _, router in ipairs(record.bagTitleRouters or {}) do
            if CursorInside(router) then record.titleClick = router; break end
        end
    end
    record.mouseUp = function(_, button)
        local router = record.titleClick
        record.titleClick = nil
        ResetClick(nil, button)
        if router and Suite.db.windowTools and button == "LeftButton" and not IsControlKeyDown()
            and not record.dragging and CursorInside(router) then
            local callback = router:GetScript("OnMouseDown")
            if Suite.IsReadable(callback) and type(callback) == "function" then callback(router, button) end
        end
    end

    frame:HookScript("OnShow", function() self:PlaceWindow(name, frame); self:Schedule(record) end)
    frame:HookScript("OnHide", function()
        record.titleClick = nil
        self:StopDrag(record, true)
        self:Schedule(record)
    end)
    frame:HookScript("OnSizeChanged", function() self:PlaceWindow(name, frame); self:Schedule(record) end)
    frame:HookScript("OnMouseUp", ResetClick)
    hooksecurefunc(frame, "SetPoint", function() self:PlaceWindow(name, frame); self:Schedule(record) end)
    hooksecurefunc(frame, "SetScale", function() self:PlaceWindow(name, frame); self:Schedule(record) end)
    self:ApplyRecord(record)
end

function Windows:WatchWindow(name, frame)
    if not Suite.db.windowTools or InCombatLockdown() then return end
    if not frame or frame.foreverMeter or (frame.IsForbidden and frame:IsForbidden()) then return end
    if not self.watched[frame] then
        self.watched[frame] = true
        frame:HookScript("OnShow", function()
            self:PlaceWindow(name, frame)
            if not self.tracked[name] then self:QueueDiscovery() end
        end)
    end
    if frame:IsShown() then self:Track(name, frame) end
end

function Windows:Discover()
    if not Suite.db.windowTools or InCombatLockdown() then return end
    for _, name in ipairs(self.names) do
        self:WatchWindow(name, _G[name])
    end
    self:WatchWindow("WoWForeverSuiteBankView", Suite.OfflineBank and Suite.OfflineBank.frame)
    for name in pairs(UIPanelWindows or {}) do
        self:WatchWindow(name, _G[name])
    end
end

function Windows:ResetAll()
    Suite.AfterCombat("windowReset", function()
        Suite.db.windowPositions = {}
        for _, record in pairs(self.tracked) do self:Restore(record); record.wasApplied = false end
        if Suite.OfflineBank then Suite.OfflineBank:PlaceView() end
        if UpdateContainerFrameAnchors then UpdateContainerFrameAnchors() end
        Suite.Print("Saved window positions and sizes reset.")
    end)
end

function Windows:Apply()
    if not self.events and Suite.db.windowTools then
        self.events = CreateFrame("Frame")
        self.events:SetScript("OnEvent", function(_, event, addon)
            if event == "PLAYER_REGEN_DISABLED" then self:Pause(); return end
            if event == "ADDON_LOADED" and Suite.IsReadable(addon) and addon == "Blizzard_TimeManager" then
                -- Native toggles can show these immediately after LoadAddOn returns.
                -- Watch their hidden frames now so the first show restores saved placement.
                self:WatchWindow("TimeManagerFrame", TimeManagerFrame)
                self:WatchWindow("StopwatchFrame", StopwatchFrame)
            end
            if event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
                for _, record in pairs(self.tracked) do self:Schedule(record) end
            end
            self:QueueDiscovery()
        end)
        if type(ShowUIPanel) == "function" then
            hooksecurefunc("ShowUIPanel", function(frame)
                if Suite.IsReadable(frame) and frame and frame.GetName then self:PlaceWindow(frame:GetName(), frame) end
                self:QueueDiscovery()
            end)
        end
        if FramePositionDelegate and type(FramePositionDelegate.UpdateUIPanelPositions) == "function" then
            hooksecurefunc(FramePositionDelegate, "UpdateUIPanelPositions", function() self:HoldWindowPositions() end)
        elseif type(UpdateUIPanelPositions) == "function" then
            hooksecurefunc("UpdateUIPanelPositions", function() self:HoldWindowPositions() end)
        end
        for _, functionName in ipairs({ "ToggleAllBags", "OpenAllBags", "ToggleBag", "OpenBag" }) do
            if type(_G[functionName]) == "function" then hooksecurefunc(functionName, function()
                self:QueueDiscovery()
            end) end
        end
        if type(UpdateContainerFrameAnchors) == "function" then
            hooksecurefunc("UpdateContainerFrameAnchors", function()
                if not Suite.db.windowTools then return end
                -- Settle after the complete native pass, before the opening call can render.
                -- Later header/discovery work still shares the next-frame worker.
                self:HoldBagPositions()
                self:QueueDiscovery()
            end)
        end
    end
    if self.events then
        self.events:UnregisterAllEvents()
        if Suite.db.windowTools then
            self.events:RegisterEvent("ADDON_LOADED")
            self.events:RegisterEvent("PLAYER_REGEN_DISABLED")
            self.events:RegisterEvent("PLAYER_ENTERING_WORLD")
            self.events:RegisterEvent("DISPLAY_SIZE_CHANGED")
            self.events:RegisterEvent("UI_SCALE_CHANGED")
        end
    end
    self:CancelTimer()
    self.discoverPending = Suite.db.windowTools or nil
    for _, record in pairs(self.tracked) do
        self:StopDrag(record, true)
        record.queued = true
    end
    -- Preference changes apply immediately outside combat, including disable.
    Suite.AfterCombat("windowWork", self.flush)
end
