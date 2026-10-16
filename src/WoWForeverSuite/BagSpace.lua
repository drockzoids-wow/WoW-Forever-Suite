local _, Suite = ...
local BagSpace = { requests = {} }
Suite.BagSpace = BagSpace
table.insert(Suite.modules, BagSpace)

local function Integer(value, maximum)
    return Suite.IsReadable(value) and type(value) == "number" and value == value
        and value >= 0 and value <= maximum and value == math.floor(value)
end

local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end

local function String(value, maximum)
    return Suite.IsReadable(value) and type(value) == "string" and #value > 0 and #value <= maximum
end

local function Object(value)
    return Suite.IsReadable(value) and (type(value) == "table" or type(value) == "userdata")
end

local function Enabled()
    return Suite.db and Suite.IsReadable(Suite.db.bagSpaceAlert) and Suite.db.bagSpaceAlert == true
end

local function CursorEmpty()
    if type(GetCursorInfo) ~= "function" then return false end
    local kind = GetCursorInfo()
    return Suite.IsReadable(kind) and kind == nil
end

local function Same(a, b)
    return a and b and a.bag == b.bag and a.slot == b.slot and a.id == b.id
        and a.count == b.count and a.link == b.link and a.guid == b.guid and a.value == b.value
end

function BagSpace:InitializeBlacklist(saved)
    local result = {}
    if Suite.IsReadable(saved) and type(saved) == "table" then
        for id, value in pairs(saved) do
            if Integer(id, 2147483647) and id > 0 and Suite.IsReadable(value) and value == true then result[id] = true end
        end
    end
    return result
end

function BagSpace:InitializePosition(saved)
    if Suite.IsReadable(saved) and type(saved) == "table" and Number(saved.x) and Number(saved.y)
        and math.abs(saved.x) <= 0.5 and math.abs(saved.y) <= 0.5 then return { x = saved.x, y = saved.y } end
    return {}
end

function BagSpace:Place()
    if not self.button or self.moving then return end
    Suite.AfterCombat("bagSpacePosition", function()
        if not self.button or self.moving then return end
        local saved = self:InitializePosition(Suite.db.bagSpacePosition)
        local x, y = 0, 0
        if saved.x then
            local width, height = UIParent:GetWidth(), UIParent:GetHeight()
            if not Number(width) or not Number(height) or width <= 0 or height <= 0 then return end
            x, y = saved.x * width, saved.y * height
        end
        self.button:ClearAllPoints()
        self.button:SetPoint("CENTER", UIParent, "CENTER", x, y)
    end)
end

function BagSpace:StartDrag()
    if self.moving or not self.active or not Enabled() or InCombatLockdown() or not CursorEmpty() then return end
    local shown = self.button and self.button:IsShown()
    if not Suite.IsReadable(shown) or shown ~= true then return end
    self.moving, self.suppressClick = true, true
    self.hovered = nil
    self:HideTooltip()
    self.button:StartMoving()
end

function BagSpace:StopDrag(save)
    if not self.moving then return end
    if InCombatLockdown() then
        self.cancelMove = true
        Suite.AfterCombat("bagSpaceMove", function() self:StopDrag(false) end)
        return
    end
    Suite.pending.bagSpaceMove = nil
    self.button:StopMovingOrSizing()
    self.moving = nil
    if save and not self.cancelMove and Enabled() then
        local x, y = self.button:GetCenter()
        local scale, parentScale = self.button:GetEffectiveScale(), UIParent:GetEffectiveScale()
        local width, height = UIParent:GetWidth(), UIParent:GetHeight()
        if Number(x) and Number(y) and Number(scale) and scale > 0 and Number(parentScale) and parentScale > 0
            and Number(width) and width > 0 and Number(height) and height > 0 then
            local ratio = scale / parentScale
            local nx, ny = x * ratio / width - 0.5, y * ratio / height - 0.5
            if Number(nx) and Number(ny) then
                Suite.db.bagSpacePosition = { x = math.max(-0.5, math.min(0.5, nx)), y = math.max(-0.5, math.min(0.5, ny)) }
            end
        end
    end
    self.cancelMove = nil
    self:Place()
end

function BagSpace:ResetBlacklist()
    if not Suite.db then return end
    Suite.db.bagSpaceBlacklist = {}
    Suite.Print("Trash blacklist cleared.")
    self:Queue()
end

function BagSpace:CancelWork()
    self.work = nil
    if self.timer then self.timer:Cancel(); self.timer = nil end
end

function BagSpace:OwnsTooltip()
    if not self.button then return false end
    local tip = GameTooltip
    if tip and type(tip.GetOwner) == "function" then
        local owner = tip:GetOwner()
        return Suite.IsReadable(owner) and owner == self.button
    end
    return false
end

function BagSpace:HideTooltip()
    if self:OwnsTooltip() and type(GameTooltip.Hide) == "function" then GameTooltip:Hide() end
end

function BagSpace:Hide()
    self:StopDrag(false)
    self.candidate = nil
    self.free, self.status, self.hovered = nil, nil, nil
    self:HideTooltip()
    if self.button then self.button:Hide() end
end

function BagSpace:CursorGUID()
    if not C_Cursor or type(C_Cursor.GetCursorItem) ~= "function" or not C_Item or type(C_Item.GetItemGUID) ~= "function" then return nil end
    local location = C_Cursor.GetCursorItem()
    if not Object(location) then return nil end
    local guid = C_Item.GetItemGUID(location)
    if String(guid, 128) then return guid end
end

function BagSpace:CancelDelete()
    local data, guid = self.popupData, self.heldGUID
    self.popupData, self.heldGUID = nil, nil
    if data and type(StaticPopup_Hide) == "function" then StaticPopup_Hide("DELETE_ITEM", data) end
    -- Never clear an item or other cursor payload acquired independently by the user.
    if guid and self:CursorGUID() == guid and type(ClearCursor) == "function" then ClearCursor() end
end

function BagSpace:ReadSlot(bag, slot, request)
    local api = C_Container
    local info = api.GetContainerItemInfo(bag, slot)
    if not Suite.IsReadable(info) then return nil, "unavailable" end
    if info == nil then
        -- A loading occupied slot must not disappear from the minimum-value comparison.
        local id = api.GetContainerItemID(bag, slot)
        if not Suite.IsReadable(id) or id ~= nil then return nil, "unavailable" end
        return nil
    end
    if type(info) ~= "table" then return nil, "unavailable" end
    if not Integer(info.itemID, 2147483647) or info.itemID == 0
        or not Integer(info.stackCount, 1000000) or info.stackCount == 0
        or not Suite.IsReadable(info.quality) or (info.quality ~= nil and not Integer(info.quality, 8)) or not Suite.IsReadable(info.isLocked)
        or not Suite.IsReadable(info.hasNoValue) then return nil, "unavailable" end
    if (info.quality ~= nil and info.quality > 1) or info.isLocked ~= false or info.hasNoValue ~= false then return nil end
    local blacklist = Suite.db.bagSpaceBlacklist
    if not Suite.IsReadable(blacklist) or type(blacklist) ~= "table" then return nil, "unavailable" end
    local blocked = blacklist[info.itemID]
    if not Suite.IsReadable(blocked) then return nil, "unavailable" end
    if blocked == true then return nil end
    local quest = api.GetContainerItemQuestInfo(bag, slot)
    if not Suite.IsReadable(quest) or type(quest) ~= "table" or not Suite.IsReadable(quest.isQuestItem)
        or not Suite.IsReadable(quest.questID) or not Suite.IsReadable(quest.isActive) then return nil, "unavailable" end
    if quest.isQuestItem ~= false or quest.questID ~= nil or quest.isActive ~= false then return nil end
    if not String(info.hyperlink, 2048) then return nil, "unavailable" end
    local name, _, quality, _, _, _, _, _, _, icon, price, class = C_Item.GetItemInfo(info.hyperlink)
    if not Suite.IsReadable(name) then return nil, "unavailable" end
    if not String(name, 256) then
        local state = self.requests[info.itemID]
        if request and state == nil and self.requestBudget > 0 and type(C_Item.RequestLoadItemDataByID) == "function" then
            self.requestBudget = self.requestBudget - 1
            self.requests[info.itemID] = "pending"
            local ok = pcall(C_Item.RequestLoadItemDataByID, info.itemID)
            if not ok then self.requests[info.itemID] = "failed" end
            state = self.requests[info.itemID]
        end
        return nil, (state == "pending" or (state == nil and type(C_Item.RequestLoadItemDataByID) == "function")) and "loading" or "unavailable"
    end
    if not Integer(quality, 8) or (info.quality ~= nil and quality ~= info.quality) or not Integer(class, 30)
        or not Integer(price, 100000000000) then return nil, "unavailable" end
    if quality > 1 or class == 12 or price == 0 then return nil end -- Quest class includes inactive quest starters.
    local value = price * info.stackCount
    if not Integer(value, 9007199254740991) then return nil, "unavailable" end
    local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
    if not Object(location) then return nil, "unavailable" end
    local guid = C_Item.GetItemGUID(location)
    if not String(guid, 128) then return nil, "unavailable" end
    return { bag = bag, slot = slot, id = info.itemID, count = info.stackCount, link = info.hyperlink,
        guid = guid, name = name, icon = Integer(icon, 2147483647) and icon or 134400,
        value = value, quality = quality }
end

function BagSpace:Snapshot(request)
    local api = C_Container
    if not api or type(api.GetContainerNumSlots) ~= "function" or type(api.GetContainerNumFreeSlots) ~= "function"
        or type(api.GetContainerItemInfo) ~= "function" or type(api.GetContainerItemID) ~= "function"
        or type(api.GetContainerItemQuestInfo) ~= "function"
        or not C_Item or type(C_Item.GetItemInfo) ~= "function" or type(C_Item.GetItemGUID) ~= "function"
        or not ItemLocation or type(ItemLocation.CreateFromBagAndSlot) ~= "function" then return nil end
    local last = NUM_TOTAL_EQUIPPED_BAG_SLOTS
    if not Integer(last, 32) then last = NUM_BAG_SLOTS end
    if not Integer(last, 32) then return nil end
    local free, bags = 0, {}
    for bag = 0, last do
        local slots = api.GetContainerNumSlots(bag)
        if not Integer(slots, 200) then return nil end
        if slots > 0 then
            local available, family = api.GetContainerNumFreeSlots(bag)
            if not Integer(available, slots) or not Integer(family, 2147483647) then return nil end
            -- Specialized and reagent slots cannot relieve general inventory pressure.
            if family == 0 then free = free + available; bags[#bags + 1] = { id = bag, slots = slots } end
        end
    end
    if free > 2 then return free end
    local best, status
    self.requestBudget = 32
    for _, bag in ipairs(bags) do
        for slot = 1, bag.slots do
            local item, unknown = self:ReadSlot(bag.id, slot, request)
            if unknown == "loading" then status = "loading"
            elseif unknown and status ~= "loading" then status = "unavailable" end
            if item and (not best or item.value < best.value) then best = item end
        end
    end
    -- An unresolved item could be cheaper. Do not offer a misleading minimum.
    if status then best = nil end
    return free, best, status
end

local function Money(value)
    local gold = math.floor(value / 10000)
    local silver = math.floor(value / 100) % 100
    local copper = value % 100
    return (gold > 0 and gold .. "g " or "") .. (silver > 0 and silver .. "s " or "") .. copper .. "c"
end

function BagSpace:ShowTooltip()
    local item, tip = self.candidate, GameTooltip
    if self.moving or not Integer(self.free, 2) or InCombatLockdown() or not tip or type(tip.SetOwner) ~= "function"
        or type(tip.AddLine) ~= "function" or type(tip.Show) ~= "function" then return end
    local itemTooltip = item and type(tip.SetHyperlink) == "function"
    if not itemTooltip and type(tip.ClearLines) ~= "function" then return end
    tip:SetOwner(self.button, "ANCHOR_RIGHT")
    if itemTooltip then tip:SetHyperlink(item.link)
    else
        tip:ClearLines()
        tip:AddLine(item and item.name or "Low bag space", 0.88, 0.91, 0.93)
    end
    tip:AddLine(" ")
    tip:AddLine(self.free .. (self.free == 1 and " bag slot left" or " bag slots left"), 0.41, 0.84, 0.75)
    if item then
        tip:AddLine("Stack count: " .. item.count, 0.88, 0.91, 0.93)
        tip:AddLine("Stack vendor value: " .. Money(item.value), 0.9, 0.72, 0.4)
        tip:AddLine(" ")
        tip:AddLine("Left-click: confirm discarding this stack", 0.41, 0.84, 0.75)
        tip:AddLine("Right-click: blacklist this item type", 0.55, 0.65, 0.7)
    else
        tip:AddLine(self.status == "loading" and "Loading item values..."
            or self.status and "Item values unavailable" or "No eligible gray or white items", 0.88, 0.91, 0.93)
        tip:AddLine("Quest, no-value and blacklisted items are skipped", 0.55, 0.65, 0.7, true)
    end
    tip:AddLine("Left-drag: move this button", 0.55, 0.65, 0.7)
    tip:Show()
end

function BagSpace:Build()
    if self.button then return end
    local button = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
    self.button = button
    button:Hide()
    button:SetSize(48, 48)
    button:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    button:SetMovable(true)
    button:RegisterForDrag("LeftButton")
    button:SetFrameStrata("LOW")
    button:SetFrameLevel(1)
    button:SetClampedToScreen(true)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    button:SetBackdropColor(0.035, 0.05, 0.065, 0.96)
    button:SetBackdropBorderColor(0.41, 0.84, 0.75, 0.7)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(44, 44)
    button.icon:SetPoint("CENTER")
    local banner = button:CreateTexture(nil, "ARTWORK", nil, 1)
    banner:SetPoint("BOTTOMLEFT", 1, 1)
    banner:SetPoint("BOTTOMRIGHT", -1, 1)
    banner:SetHeight(12)
    banner:SetColorTexture(0.035, 0.05, 0.065, 0.94)
    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetPoint("CENTER", banner, "CENTER", 0, 0)
    label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    label:SetTextColor(0.75, 0.93, 0.88)
    label:SetText("Trash")
    button:SetScript("OnClick", function(_, mouse) self:Click(mouse) end)
    button:SetScript("OnMouseDown", function(_, mouse)
        if not self.moving and Suite.IsReadable(mouse) and (mouse == "LeftButton" or mouse == "RightButton") then
            self.suppressClick = nil
        end
    end)
    button:SetScript("OnDragStart", function() self:StartDrag() end)
    button:SetScript("OnDragStop", function() self:StopDrag(true) end)
    button:SetScript("OnEnter", function()
        self.hovered = true
        button:SetBackdropBorderColor(0.41, 0.84, 0.75, 1)
        self:ShowTooltip()
    end)
    local function EndHover()
        self.hovered = nil
        button:SetBackdropBorderColor(0.41, 0.84, 0.75, 0.7)
        self:HideTooltip()
    end
    button:SetScript("OnLeave", EndHover)
    button:SetScript("OnHide", function() self:StopDrag(false); EndHover() end)
    self:Place()
end

function BagSpace:Refresh()
    if not self.active or not Enabled() or InCombatLockdown() then self:Hide(); return end
    if not CursorEmpty() then self:Hide(); return end
    self:CancelDelete()
    local free, item, status = self:Snapshot(true)
    if free == nil or free > 2 then self:Hide(); return end
    self:Build()
    local refreshTooltip = self.hovered and self:OwnsTooltip()
    if not Same(self.candidate, item) then self:HideTooltip() end
    self.candidate, self.free, self.status = item, free, status
    local button = self.button
    button.icon:SetTexture(item and item.icon or "Interface\\Buttons\\Button-Backpack-Up")
    button:Show()
    if refreshTooltip then self:ShowTooltip() end
end

function BagSpace:Click(mouse)
    -- A drag release can also dispatch OnClick. Suppress it until a fresh mouse press.
    if self.moving or self.suppressClick then return end
    if not Suite.IsReadable(mouse) or (mouse ~= "LeftButton" and mouse ~= "RightButton") then return end
    if not self.active or not Enabled() or InCombatLockdown() or not CursorEmpty() or not self.candidate then return end
    local offered = self.candidate
    local free, current = self:Snapshot(false)
    if free == nil or free > 2 or not Same(offered, current) then self:Queue(); return end
    if mouse == "RightButton" then
        Suite.db.bagSpaceBlacklist[offered.id] = true
        Suite.Print(offered.name .. " added to the trash blacklist.")
        self:Hide(); self:Queue(); return
    end
    if not C_Cursor or type(C_Cursor.GetCursorItem) ~= "function" or type(DeleteCursorItem) ~= "function"
        or type(C_Container.PickupContainerItem) ~= "function" or type(ClearCursor) ~= "function"
        or type(StaticPopup_Show) ~= "function" or type(StaticPopup_Hide) ~= "function"
        or type(StaticPopup_IsAnyDialogShown) ~= "function" then
        Suite.Print("Item deletion confirmation is unavailable."); return
    end
    local popupShown = StaticPopup_IsAnyDialogShown()
    if not Suite.IsReadable(popupShown) or popupShown ~= false then return end
    self.heldGUID = offered.guid
    local pickedUp = pcall(C_Container.PickupContainerItem, offered.bag, offered.slot)
    if not pickedUp or self:CursorGUID() ~= offered.guid then
        self:CancelDelete(); self:Queue(); return
    end
    self:Hide()
    -- GUID-based ConfirmDeleteItem is protected on Forever. Use the native cursor
    -- dialog instead: without itemGUID its Accept calls DeleteCursorItem on the
    -- user's confirmation click. The unique data table only scopes our cleanup.
    local data = {}
    self.popupData = data
    local requested, dialog = pcall(StaticPopup_Show, "DELETE_ITEM", offered.link, nil, data)
    if requested and Object(dialog) and Suite.IsReadable(dialog.data) and dialog.data == data
        and self.heldGUID == offered.guid and self:CursorGUID() == offered.guid then
        return
    end
    self:CancelDelete(); self:Queue()
    Suite.Print("The game did not open item deletion confirmation; the item was kept.")
end

function BagSpace:Queue()
    if self.work or not self.active or not Enabled() or InCombatLockdown() then return end
    if not C_Timer or type(C_Timer.NewTimer) ~= "function" then return end
    local work = {}
    self.work = work
    self.timer = C_Timer.NewTimer(0.1, function()
        if self.work ~= work then return end
        self.work, self.timer = nil, nil
        self:Refresh()
    end)
end

function BagSpace:OnEvent(event, id, success)
    if not self.active then return end
    if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_LOGOUT" then
        self:CancelWork(); self:CancelDelete(); self:Hide(); return
    elseif event == "ITEM_DATA_LOAD_RESULT" then
        if not Integer(id, 2147483647) or not self.requests[id] then return end
        self.requests[id] = Suite.IsReadable(success) and success == true and "done" or "failed"
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:CancelDelete(); self:Hide(); self.requests = {}
    elseif event == "CURSOR_CHANGED" and self.heldGUID and self:CursorGUID() ~= self.heldGUID then
        self:CancelDelete()
    elseif event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" then
        self:StopDrag(false); self:Place()
    elseif event == "PLAYER_REGEN_ENABLED" and self.cancelMove then
        self:StopDrag(false)
    end
    self:Queue()
end

function BagSpace:Apply()
    Suite.pending.bagSpace = nil
    if not Enabled() then
        self.active = nil
        self:CancelWork(); self:CancelDelete(); self:Hide()
        self.requests = {}
        if self.events then self.events:UnregisterAllEvents() end
        return
    end
    Suite.AfterCombat("bagSpace", function()
        if not Enabled() then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event, ...) self:OnEvent(event, ...) end)
        end
        if not self.active then
            self.active = true
            for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED", "BAG_CONTAINER_UPDATE", "ITEM_LOCK_CHANGED",
                "ITEM_DATA_LOAD_RESULT", "CURSOR_CHANGED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_LOGOUT",
                "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED" }) do
                self.events:RegisterEvent(event)
            end
        end
        self:Queue()
    end)
end
