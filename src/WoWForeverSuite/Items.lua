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
    local name, link, quality, level, requiredLevel, _, _, _, equipLoc, _, _, classID, subclassID = C_Item.GetItemInfo(item)
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
    return { link = link, quality = quality, level = itemLevel, requiredLevel = requiredLevel, equipLoc = equipLoc,
        classID = classID, subclassID = subclassID }
end

local function Read(callback, ...)
    if type(callback) ~= "function" then return nil end
    local ok, value = pcall(callback, ...)
    if ok and Suite.IsReadable(value) then return value end
end

local armorSlots = { INVTYPE_HEAD = true, INVTYPE_SHOULDER = true, INVTYPE_CHEST = true, INVTYPE_ROBE = true,
    INVTYPE_WAIST = true, INVTYPE_LEGS = true, INVTYPE_FEET = true, INVTYPE_WRIST = true, INVTYPE_HAND = true }
-- Blizzard item armor subclass IDs; compare IDs rather than localized item text.
local armorNames = { "Cloth", "Leather", "Mail", "Plate" }
local armorPreferences = { WARRIOR = { 3, 4 }, PALADIN = { 3, 4 }, HUNTER = { 2, 3 }, SHAMAN = { 2, 3 },
    ROGUE = 2, DRUID = 2, MAGE = 1, PRIEST = 1, WARLOCK = 1 }

function Items:UpgradeColor(info)
    if not Suite.IsReadable(info) or type(info) ~= "table" or not Suite.IsReadable(info.equipLoc)
        or type(info.equipLoc) ~= "string" then return end
    -- Cloaks, jewelry, shields and weapons have no primary-armor preference.
    if not armorSlots[info.equipLoc] then return 0.2, 1, 0.2 end
    if not Number(info.classID) or info.classID ~= 4 or not Number(info.subclassID)
        or info.subclassID ~= math.floor(info.subclassID) or not armorNames[info.subclassID]
        or type(UnitClass) ~= "function" then return end
    local ok, _, class = pcall(UnitClass, "player")
    if not ok or not Suite.IsReadable(class) or type(class) ~= "string" then return end
    local preferred = armorPreferences[class]
    if type(preferred) == "table" then
        local level = Read(UnitLevel, "player")
        if not Number(level) or level <= 0 then return end
        preferred = preferred[level < 40 and 1 or 2]
    end
    if not preferred then return end
    local name = Read(C_Item and C_Item.GetItemSubClassInfo, 4, preferred)
    if type(name) ~= "string" or name == "" then name = armorNames[preferred] end
    if info.subclassID == preferred then return 0.2, 1, 0.2, "Preferred armor type: " .. name end
    return 1, 0.82, 0, "Not your preferred armor type (" .. name .. " preferred)."
end

function Items:CanEquip(info)
    -- Native gear tutorials use player item eligibility, rather than the
    -- action-use predicate (which also reports temporary use/mana state).
    if C_PlayerInfo and type(C_PlayerInfo.CanUseItem) == "function" then
        local id = Read(C_Item and C_Item.GetItemInfoInstant, info.link)
        if not Number(id) or id <= 0 or id ~= math.floor(id) then return false end
        return Read(C_PlayerInfo.CanUseItem, id) == true
    end
    -- Older capability sets retain the conservative existing check. Never
    -- override a false/unknown answer from the modern player predicate.
    return Read(C_Item and C_Item.IsUsableItem, info.link) == true
end

function Items:WeaponUpgrade(info, preference, explain)
    local scoring = Suite.Scoring
    local profile = scoring:Profile()
    local kind = scoring.WeaponKind(info.equipLoc)
    local slots = (kind == "ranged" or kind == "relic") and { 18 } or { 16, 17 }
    local current, baseline = {}, 0
    local function Score(value, slot)
        local stats = preference == "stats" and Read(C_Item.GetItemStats, value.link) or nil
        return scoring.WeaponScore(value, stats, profile, preference, slot), stats
    end
    for _, slot in ipairs(slots) do
        local ok, link = pcall(GetInventoryItemLink, "player", slot)
        if not ok or not Suite.IsReadable(link) then return nil end
        if link ~= nil then
            local equipped = self:GetInfo(link)
            if not equipped then return nil end
            local equippedKind = scoring.WeaponKind(equipped.equipLoc)
            if slot == 18 and equippedKind ~= kind then return nil end
            if slot == 16 and (equippedKind ~= "melee" or equipped.equipLoc == "INVTYPE_WEAPONOFFHAND") then return nil end
            if slot == 17 and (equippedKind ~= "offhand" and equippedKind ~= "melee"
                or equipped.equipLoc == "INVTYPE_2HWEAPON" or equipped.equipLoc == "INVTYPE_WEAPONMAINHAND") then return nil end
            local score, stats = Score(equipped, slot)
            if not Number(score) then return nil end
            current[slot] = { info = equipped, score = score, stats = stats }
            baseline = baseline + score
        end
    end
    -- Unmodeled two-handed dual wield must not be treated as a normal pair.
    local main, off = current[16], current[17]
    local twoHanded = main and main.info.equipLoc == "INVTYPE_2HWEAPON"
    if twoHanded and off then return nil end
    local choices = {}
    if kind == "ranged" or kind == "relic" then
        choices[1] = { slot = 18, label = "Ranged", remove = baseline }
    elseif info.equipLoc == "INVTYPE_2HWEAPON" then
        choices[1] = { slot = 16, label = "Both hands", remove = baseline }
    elseif info.equipLoc == "INVTYPE_SHIELD" or info.equipLoc == "INVTYPE_HOLDABLE" then
        if not twoHanded then choices[1] = { slot = 17, label = "Off hand", remove = off and off.score or 0 } end
    else
        if info.equipLoc ~= "INVTYPE_WEAPONOFFHAND" then
            choices[#choices + 1] = { slot = 16, label = "Main hand", remove = main and main.score or 0 }
        end
        if info.equipLoc ~= "INVTYPE_WEAPONMAINHAND" and main and not twoHanded and Read(CanDualWield) == true then
            choices[#choices + 1] = { slot = 17, label = "Off hand", remove = off and off.score or 0 }
        end
    end
    local best, detail
    for _, choice in ipairs(choices) do
        local score, stats = Score(info, choice.slot)
        if Number(score) then
            local delta = scoring.Compare(baseline - choice.remove + score, { baseline })
            local empty = choice.slot == 18 and not current[18]
                or choice.slot == 17 and not off
                or choice.slot == 16 and not main and (info.equipLoc ~= "INVTYPE_2HWEAPON" or not off)
            -- A loaded usable item can fill an empty slot even when none of its
            -- stats contribute to this preset. Keep hand eligibility above intact.
            if not delta and empty then delta = 1 end
            if delta and (not best or delta > best) then
                best, detail = delta, { weapon = true, preference = preference, slot = choice.label,
                    paired = choice.slot ~= 18, emptySlot = empty or nil,
                    profile = profile.label, candidateScore = baseline - choice.remove + score, baselineScore = baseline }
                if explain and preference == "stats" and not empty then
                    local removed = {}
                    for _, slot in ipairs(slots) do
                        local record = current[slot]
                        if record and (slot == choice.slot or info.equipLoc == "INVTYPE_2HWEAPON") then
                            removed[#removed + 1] = scoring:Terms(record.stats, profile, record.info, slot) or {}
                        end
                    end
                    detail.breakdown = scoring:Breakdown(scoring:Terms(stats, profile, info, choice.slot), removed)
                end
            end
        end
    end
    return best, detail
end

function Items:UpgradeDelta(item, explain)
    local info = self:GetInfo(item)
    if not self:IsEquipment(info) or not Number(info.requiredLevel) or type(UnitLevel) ~= "function"
        or type(GetInventoryItemLink) ~= "function" then return nil end
    local playerLevel = UnitLevel("player")
    if not Number(playerLevel) or playerLevel <= 0 or info.requiredLevel > playerLevel then return nil end
    if not self:CanEquip(info) then return nil end
    local preference = Suite.Scoring.Preference(Suite.db)
    if Suite.Scoring.WeaponKind(info.equipLoc) then
        if preference == "stats" and type(C_Item.GetItemStats) ~= "function" then return nil end
        return self:WeaponUpgrade(info, preference, explain)
    end
    local slots = Suite.Scoring.slots[info.equipLoc]
    if not slots then return nil end
    local profile = Suite.Scoring:Profile()
    local equipped, links, emptySlot = {}, {}
    for _, slot in ipairs(slots) do
        local ok, link = pcall(GetInventoryItemLink, "player", slot)
        if not ok or not Suite.IsReadable(link) then return nil end
        links[slot] = link
        if link == nil then emptySlot = slot end
    end
    -- Filling a known empty armor/accessory slot is independent of stat data.
    -- GetItemStats may return nothing even after the item's identity is loaded.
    if emptySlot then return 1, { preference = preference, emptySlot = true } end
    local stats = preference == "stats" and Read(C_Item.GetItemStats, info.link) or nil
    local score = preference == "ilevel" and info.level or Suite.Scoring.Score(stats, profile)
    if not Number(score) then return nil end
    local lowest, replacement
    for _, slot in ipairs(slots) do
        local link = links[slot]
        if link then
            local equippedInfo = self:GetInfo(link)
            if not equippedInfo then return nil end
            local oldStats = preference == "stats" and Read(C_Item.GetItemStats, link) or nil
            local equippedScore = preference == "ilevel" and equippedInfo.level
                or Suite.Scoring.Score(oldStats, profile)
            if not equippedScore then return nil end
            equipped[#equipped + 1] = equippedScore
            if not lowest or equippedScore < lowest then
                lowest, replacement = equippedScore, { slot = slot, link = link, stats = oldStats }
            end
        else
            equipped[#equipped + 1] = 0
        end
    end
    local delta = Suite.Scoring.Compare(score, equipped)
    if not delta then return nil end
    local detail = { preference = preference, profile = profile.label, candidateScore = score, baselineScore = lowest,
        replacementSlot = replacement.slot, replacementLink = replacement.link }
    if explain and preference == "stats" then
        detail.breakdown = Suite.Scoring:Breakdown(Suite.Scoring:Terms(stats, profile),
            { Suite.Scoring:Terms(replacement.stats, profile) or {} })
    end
    return delta, detail
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
    if button.IsForbidden and button:IsForbidden() then return end
    if not Suite.db or (not Suite.db.itemLevels and not Suite.db.upgradeHints) then
        if record.level then record.level:SetText(""); record.arrow:SetText("") end
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
        record.arrow = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        record.arrow:SetDrawLayer("OVERLAY", 7)
        record.arrow:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        record.arrow:SetPoint("BOTTOMLEFT", 2, 2)
    end
    record.level:SetText("")
    record.arrow:SetText("")
    local item, location, equipped = self:Resolve(button, record)
    record.equipped = equipped == true
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
    if Suite.db.upgradeHints and not record.equipped and self:UpgradeDelta(info.link) then
        local red, green, blue = self:UpgradeColor(info)
        if red then
            record.arrow:SetTextColor(red, green, blue)
            record.arrow:SetText("+")
        end
    end
end

function Items:Track(button, item, supplied)
    if not Suite.db or (not Suite.db.itemLevels and not Suite.db.upgradeHints) then return end
    if not Suite.IsReadable(button) or not button or not button.CreateFontString then return end
    if button.IsForbidden and button:IsForbidden() then return end
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
            if record.level then record.level:SetText(""); record.arrow:SetText("") end
        end)
    end
    if supplied then
        record.item = nil
        if Suite.IsReadable(item) then record.item = item end
    end
    self:Update(button, record)
end

function Items:VisitContainer(frame)
    if not Suite.db or (not Suite.db.itemLevels and not Suite.db.upgradeHints) then return end
    if not frame or (frame.IsForbidden and frame:IsForbidden()) then return end
    if not self.containers[frame] then
        self.containers[frame] = true
        frame:HookScript("OnShow", function() self:VisitContainer(frame) end)
        for _, method in ipairs({ "UpdateItems", "GenerateItemSlotsForSelectedTab", "RefreshAllItemsForSelectedTab" }) do
            if frame[method] then hooksecurefunc(frame, method, function() self:VisitContainer(frame) end) end
        end
    end
    if not frame:IsVisible() then return end
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
    while frame do
        if not (frame.IsForbidden and frame:IsForbidden()) and frame:IsVisible()
            and frame.SetItemButtonQuality and (frame.GetItemLink or frame.GetItemLocation or frame.GetBagID) then self:Track(frame) end
        frame = EnumerateFrames(frame)
    end
end

function Items:Refresh()
    for button, record in pairs(self.buttons) do if button:IsVisible() then self:Update(button, record) end end
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
    local enabled = Suite.db.itemLevels or Suite.db.upgradeHints
    if enabled then self:Initialize() end
    if self.events then
        self.events:UnregisterAllEvents()
        if enabled then
            for _, event in ipairs({ "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "GET_ITEM_INFO_RECEIVED", "ADDON_LOADED" }) do self.events:RegisterEvent(event) end
            if Suite.db.upgradeHints then
                for _, event in ipairs({ "PLAYER_LEVEL_UP", "SPELLS_CHANGED", "SKILL_LINES_CHANGED" }) do self.events:RegisterEvent(event) end
            end
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
