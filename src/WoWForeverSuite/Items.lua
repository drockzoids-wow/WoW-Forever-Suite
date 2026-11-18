local _, Suite = ...
local Items = { buttons = setmetatable({}, { __mode = "k" }), containers = setmetatable({}, { __mode = "k" }), requested = {} }
Suite.Items = Items
table.insert(Suite.modules, Items)

local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and math.abs(value) < math.huge
end

local equipmentTypes = {
    INVTYPE_HEAD = true, INVTYPE_NECK = true, INVTYPE_SHOULDER = true,
    INVTYPE_BODY = true, INVTYPE_CHEST = true, INVTYPE_ROBE = true,
    INVTYPE_WAIST = true, INVTYPE_LEGS = true, INVTYPE_FEET = true,
    INVTYPE_WRIST = true, INVTYPE_HAND = true, INVTYPE_FINGER = true,
    INVTYPE_TRINKET = true, INVTYPE_CLOAK = true, INVTYPE_TABARD = true,
    INVTYPE_WEAPON = true, INVTYPE_2HWEAPON = true, INVTYPE_WEAPONMAINHAND = true,
    INVTYPE_WEAPONOFFHAND = true, INVTYPE_SHIELD = true, INVTYPE_HOLDABLE = true,
    INVTYPE_RANGED = true, INVTYPE_RANGEDRIGHT = true, INVTYPE_THROWN = true,
    INVTYPE_RELIC = true,
}

function Items:IsEquipment(info)
    return info ~= nil and Suite.IsReadable(info.equipLoc) and type(info.equipLoc) == "string"
        and equipmentTypes[info.equipLoc] == true
end

function Items:GetInfo(item)
    if not Suite.IsReadable(item) or not item or not C_Item or not C_Item.GetItemInfo then return nil end
    local name, link, quality, level, _, _, _, _, equipLoc = C_Item.GetItemInfo(item)
    if not Suite.IsReadable(name) then return nil end
    if not name then
        local id = C_Item.GetItemInfoInstant and C_Item.GetItemInfoInstant(item)
        if Suite.IsReadable(id) and type(id) == "number" and id > 0 and not self.requested[id] then
            if C_Item.RequestLoadItemDataByID then
                self.requested[id] = true
                C_Item.RequestLoadItemDataByID(id)
            end
        end
        return nil
    end
    if not Suite.IsReadable(link) or not link then return nil end
    local actual = C_Item.GetDetailedItemLevelInfo and C_Item.GetDetailedItemLevelInfo(link)
    if not Suite.IsReadable(actual) then return nil end
    local itemLevel = actual or level
    if not Number(itemLevel) or itemLevel <= 0 then return nil end
    return { link = link, quality = quality, level = itemLevel, equipLoc = equipLoc }
end

local function Read(callback, ...)
    if type(callback) ~= "function" then return nil end
    local ok, value = pcall(callback, ...)
    if ok and Suite.IsReadable(value) then return value end
end

-- Suite-owned list presentation, independent of the optional item-level overlay.
function Items:Icon(id)
    if not Number(id) or id < 1 or id > 2147483647 or id % 1 ~= 0 then return 134400, false end
    local icon = C_Item and Read(C_Item.GetItemIconByID, id)
    if Number(icon) and icon > 0 and icon <= 2147483647 and icon % 1 == 0 then return icon, true end
    return 134400, false
end
function Items:ListIconEvents()
    local pending = self.listIcons and next(self.listIcons) ~= nil
    if pending and not self.listIconEvents and InCombatLockdown() then
        Suite.AfterCombat("listIcons", function()
            for texture, id in pairs(self.listIcons) do self:SetListIcon(texture, id) end
        end)
    elseif not pending then Suite.pending.listIcons = nil end
    if pending and not self.listIconEvents and not InCombatLockdown() then
        self.listIconEvents = CreateFrame("Frame")
        self.listIconEvents:SetScript("OnEvent", function(_, event, id)
            if event == "ITEM_DATA_LOAD_RESULT" and (not Number(id) or id < 1 or id % 1 ~= 0) then return end
            for texture, itemID in pairs(self.listIcons) do
                if event == "PLAYER_REGEN_ENABLED" or itemID == id then self:SetListIcon(texture, itemID) end
            end
        end)
    end
    if self.listIconEvents then
        self.listIconEvents:UnregisterAllEvents()
        if pending then
            self.listIconEvents:RegisterEvent("ITEM_DATA_LOAD_RESULT")
            self.listIconEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
        end
    end
end
function Items:SetListIcon(texture, id)
    if not Number(id) or id < 1 or id > 2147483647 or id % 1 ~= 0 then id = nil end
    local icon, known = self:Icon(id)
    texture.listItemID = id; texture:SetTexture(icon)
    self.listIcons = self.listIcons or setmetatable({}, { __mode = "k" })
    self.listIcons[texture] = nil
    if not known and id and C_Item and type(C_Item.GetItemIconByID) == "function"
        and Read(texture.listOwner.IsVisible, texture.listOwner) == true then
        self.listIcons[texture] = id
        self:ListIconEvents()
        if not InCombatLockdown() and C_Item and type(C_Item.RequestLoadItemDataByID) == "function" then
            self.listIconRequested = self.listIconRequested or {}
            if not self.listIconRequested[id] then
                self.listIconRequested[id] = true
                pcall(C_Item.RequestLoadItemDataByID, id)
            end
        end
    end
    self:ListIconEvents()
end
function Items:CreateListIcon(parent, size, x, y)
    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetSize(size, size); icon:SetPoint("TOPLEFT", x, y); icon.listOwner = parent
    parent:HookScript("OnShow", function() self:SetListIcon(icon, icon.listItemID) end)
    parent:HookScript("OnHide", function()
        if self.listIcons then self.listIcons[icon] = nil; self:ListIconEvents() end
    end)
    return icon
end
function Items:IconText(id, text)
    return "|T" .. self:Icon(id) .. ":16:16:0:0|t " .. text
end
function Items:ModifiedClick(id, button)
    if button ~= "LeftButton" or InCombatLockdown() or Read(IsModifiedClick, "CHATLINK") ~= true then return false end
    if not Number(id) or id < 1 or id > 2147483647 or id % 1 ~= 0 then
        Suite.Print("This item has no available link."); return true
    end
    local ok, _, link
    if C_Item and type(C_Item.GetItemInfo) == "function" then ok, _, link = pcall(C_Item.GetItemInfo, id) end
    if not ok or not Suite.IsReadable(link) or type(link) ~= "string" or #link > 4096
        or link:find("%c") or tonumber(link:match("|Hitem:(%d+):")) ~= id or not link:find("|h%[.-%]|h") then
        self.linkRequested = self.linkRequested or {}
        if not self.linkRequested[id] and C_Item and type(C_Item.RequestLoadItemDataByID) == "function" then
            self.linkRequested[id] = true; pcall(C_Item.RequestLoadItemDataByID, id)
        end
        Suite.Print("Item data is unavailable or loading. Shift-click the item again after it loads.")
        return true
    end
    if type(HandleModifiedItemClick) ~= "function" then Suite.Print("Item linking is unavailable right now."); return true end
    local success, handled = pcall(HandleModifiedItemClick, link)
    if not success or not Suite.IsReadable(handled) or handled ~= true then
        Suite.Print("Open the auction house search or a chat editor, then Shift-click the item again.")
    end
    return true
end

function Items:Resolve(button, record)
    -- Bag buttons inherit GetItemLink, but UpdateItems does not populate it.
    -- The current slot is authoritative, including when it has become empty.
    local bag, slot
    if button.GetBankTabID and button.GetContainerSlotID then
        bag, slot = button:GetBankTabID(), button:GetContainerSlotID()
    elseif button.GetBagID and button.GetID then
        bag, slot = button:GetBagID(), button:GetID()
    end
    if not Suite.IsReadable(bag) or not Suite.IsReadable(slot) then return nil end
    if bag ~= nil then
        if type(bag) ~= "number" or type(slot) ~= "number" or slot <= 0
            or not C_Container or not C_Container.GetContainerItemLink then return nil end
        local location = ItemLocation and ItemLocation.CreateFromBagAndSlot and ItemLocation:CreateFromBagAndSlot(bag, slot)
        local item = C_Container.GetContainerItemLink(bag, slot)
        if not Suite.IsReadable(item) then return nil end
        if not item and C_Container.GetContainerItemInfo then
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if not Suite.IsReadable(info) then return nil end
            if type(info) == "table" and Suite.IsReadable(info.itemID) then item = info.itemID end
        end
        return item, location, false
    end
    if button.GetItemLocation then
        local location = button:GetItemLocation()
        if not Suite.IsReadable(location) then return nil end
        if type(location) == "table" and C_Item and C_Item.DoesItemExist and C_Item.GetItemLink then
            if not Suite.IsReadable(location.bagID) or not Suite.IsReadable(location.slotIndex)
                or not Suite.IsReadable(location.equipmentSlotIndex) then return nil end
            local exists = C_Item.DoesItemExist(location)
            if not Suite.IsReadable(exists) or not exists then return nil end
            local item = C_Item.GetItemLink(location)
            if not Suite.IsReadable(item) then return nil end
            if not item and C_Item.GetItemID then item = C_Item.GetItemID(location) end
            -- This is the actual equipped instance, not a second copy with the same link.
            return item, location, location.equipmentSlotIndex ~= nil
        end
    end
    if button.GetItemLink then
        local link = button:GetItemLink()
        if not Suite.IsReadable(link) then return nil end
        if link then return link end
    end
    return record.item
end

function Items:Update(button, record)
    if not self:UsableFrame(button) then return end
    if not Suite.db or not Suite.db.itemLevels then
        if record.level then record.level:SetText("") end
        return
    end
    if not record.level then
        if InCombatLockdown() then
            Suite.pending[button] = function() self:Update(button, record) end
            return
        end
        record.level = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        record.level:SetDrawLayer("OVERLAY", 7)
        record.level:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
        record.level:SetJustifyH("RIGHT")
        record.level:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    end
    record.level:SetText("")
    local item, location = self:Resolve(button, record)
    local info = self:GetInfo(item)
    if not self:IsEquipment(info) then return end
    if Suite.db.itemLevels and location and C_Item.GetCurrentItemLevel then
        local current = C_Item.GetCurrentItemLevel(location)
        if not Suite.IsReadable(current) then return end
        if type(current) == "number" and current > 0 then info.level = current end
    end
    if Suite.db.itemLevels and Suite.IsReadable(info.level) and type(info.level) == "number" and info.level > 0 then
        record.level:SetText(info.level)
        local color = Suite.IsReadable(info.quality) and type(info.quality) == "number" and ITEM_QUALITY_COLORS[info.quality]
        if color then record.level:SetTextColor(color.r, color.g, color.b)
        else record.level:SetTextColor(1, 1, 1) end
    end
end

function Items:Track(button, item, supplied)
    if not Suite.db or not Suite.db.itemLevels then return end
    if not self:UsableFrame(button) or type(button.CreateFontString) ~= "function" then return end
    local record = self.buttons[button]
    if not record then
        record = {}
        self.buttons[button] = record
        if button.SetItemButtonQuality then hooksecurefunc(button, "SetItemButtonQuality", function(_, _, newItem)
            record.item = nil
            if Suite.IsReadable(newItem) then record.item = newItem end
            self:Update(button, record)
        end) end
        if button.Reset then hooksecurefunc(button, "Reset", function()
            record.item = nil
            self:Update(button, record)
        end) end
        button:HookScript("OnShow", function() self:Update(button, record) end)
        button:HookScript("OnHide", function()
            if record.level then record.level:SetText("") end
        end)
    end
    if supplied then
        record.item = nil
        if Suite.IsReadable(item) then record.item = item end
    end
    self:Update(button, record)
end

function Items:UsableFrame(frame)
    if not Suite.IsReadable(frame) or (type(frame) ~= "table" and type(frame) ~= "userdata") then return false end
    local predicate = frame.IsForbidden
    if not Suite.IsReadable(predicate) then return false end
    if predicate ~= nil and (type(predicate) ~= "function" or Read(predicate, frame) ~= false) then return false end
    return true
end

function Items:VisibleFrame(frame)
    return self:UsableFrame(frame) and Read(frame.IsVisible, frame) == true
end

function Items:VisitContainer(frame)
    if not Suite.db or not Suite.db.itemLevels then return end
    if not self:UsableFrame(frame) then return end
    if not self.containers[frame] then
        self.containers[frame] = true
        frame:HookScript("OnShow", function() self:VisitContainer(frame) end)
        for _, method in ipairs({ "UpdateItems", "GenerateItemSlotsForSelectedTab", "RefreshAllItemsForSelectedTab" }) do
            if frame[method] then hooksecurefunc(frame, method, function() self:VisitContainer(frame) end) end
        end
    end
    if not self:VisibleFrame(frame) then return end
    if frame.EnumerateValidItems then
        -- Bags yield index/button; bank pools yield button/active-marker.
        for first, second in frame:EnumerateValidItems() do
            if Suite.IsReadable(first) then self:Track(type(first) == "number" and second or first) end
        end
    end
end

function Items:ScanContainers()
    self:VisitContainer(ContainerFrameCombinedBags)
    if ContainerFrameContainer and ContainerFrameContainer.ContainerFrames then
        for _, frame in ipairs(ContainerFrameContainer.ContainerFrames) do self:VisitContainer(frame) end
    end
    self:VisitContainer(BankFrame and BankFrame.BankPanel or BankPanel)
end

function Items:ScanVisible()
    if InCombatLockdown() then return end
    self:ScanContainers()
    if not EnumerateFrames then return end
    local frame = EnumerateFrames()
    while Suite.IsReadable(frame) and frame do
        -- Native aura widgets also appear here. Establish item capabilities
        -- before asking about visibility, which can remain secret out of combat.
        if self:UsableFrame(frame) and type(frame.SetItemButtonQuality) == "function"
            and (type(frame.GetItemLink) == "function" or type(frame.GetItemLocation) == "function" or type(frame.GetBagID) == "function")
            and self:VisibleFrame(frame) then self:Track(frame) end
        frame = EnumerateFrames(frame)
    end
end

function Items:Refresh()
    for button, record in pairs(self.buttons) do if self:VisibleFrame(button) then self:Update(button, record) end end
end

function Items:Initialize()
    if self.initialized then return end
    self.initialized = true
    if SetItemButtonQuality then hooksecurefunc("SetItemButtonQuality", function(button, _, item)
        self:Track(button, item, true)
    end) end
    if ItemButtonMixin and ItemButtonMixin.SetItemButtonQuality then
        hooksecurefunc(ItemButtonMixin, "SetItemButtonQuality", function(button, _, item) self:Track(button, item, true) end)
    end
    self.events = CreateFrame("Frame")
    self.events:SetScript("OnEvent", function(_, event, itemID)
        if event == "GET_ITEM_INFO_RECEIVED" and Suite.IsReadable(itemID) and itemID then self.requested[itemID] = nil end
        if event == "ADDON_LOADED" then self.scanQueued = true end
        if self.refreshTimer then return end
        self.refreshTimer = C_Timer.NewTimer(0.1, function()
            self.refreshTimer = nil
            if self.scanQueued then
                self.scanQueued = nil
                Suite.AfterCombat("itemScan", function() self:ScanVisible() end)
            else self:ScanContainers() end
            self:Refresh()
        end)
    end)
end

function Items:Apply()
    local enabled = Suite.db.itemLevels
    if enabled then self:Initialize() end
    if self.events then
        self.events:UnregisterAllEvents()
        if enabled then
            for _, event in ipairs({ "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "GET_ITEM_INFO_RECEIVED", "ADDON_LOADED" }) do self.events:RegisterEvent(event) end
        end
    end
    if not enabled then
        if self.refreshTimer then self.refreshTimer:Cancel(); self.refreshTimer = nil end
        self.scanQueued = nil
        Suite.pending.itemScan = nil
        for button in pairs(self.buttons) do Suite.pending[button] = nil end
    end
    if enabled and not self.wasEnabled then Suite.AfterCombat("itemScan", function() self:ScanVisible() end) end
    self.wasEnabled = enabled
    self:Refresh()
end
