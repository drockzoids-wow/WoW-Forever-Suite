local _, Suite = ...
local Bank = { buttons = {}, pageTabs = {}, bagButtons = {}, requested = {}, page = 1, bankType = 0 }
Suite.OfflineBank = Bank
table.insert(Suite.modules, Bank)

local PAGE_SIZE, COLUMNS = 88, 8
local FRAME_NAME = "WoWForeverSuiteBankView"
local pageIcons = { "INV_SideTab_Bank_c60", "ACHIEVEMENT_GUILDPERK_MOBILEBANKING",
    "TRADE_ARCHAEOLOGY_CHESTOFTINYGLASSANIMALS", "Ability_Racial_PackHobgoblin" }

local function Integer(value, low, high)
    return Suite.IsReadable(value) and type(value) == "number" and value >= low
        and value <= high and value == math.floor(value)
end

local function Text(value)
    return Suite.IsReadable(value) and type(value) == "string" and value ~= "" and #value <= 4096
end

local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end

local function Layout(value)
    return Suite.IsReadable(value) and type(value) == "table" and Number(value.x) and Number(value.y)
        and math.abs(value.x) <= 10 and math.abs(value.y) <= 10
        and Number(value.scale) and value.scale >= 0.05 and value.scale <= 10
end

local function ReadLayout(frame)
    if not frame or not frame.GetRect or not frame.GetEffectiveScale or not UIParent then return end
    if frame.IsForbidden then
        local forbidden = frame:IsForbidden()
        if not Suite.IsReadable(forbidden) or forbidden ~= false then return end
    end
    local left, bottom, width, height = frame:GetRect()
    local scale, parentScale = frame:GetEffectiveScale(), UIParent:GetEffectiveScale()
    local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
    if not Number(left) or not Number(bottom) or not Number(width) or width <= 0
        or not Number(height) or height <= 0 or not Number(scale) or scale <= 0
        or not Number(parentScale) or parentScale <= 0 or not Number(screenWidth) or screenWidth <= 0
        or not Number(screenHeight) or screenHeight <= 0 then return end
    local ratio = scale / parentScale
    local layout = { x = left * ratio / screenWidth, y = (bottom + height) * ratio / screenHeight, scale = ratio }
    if Layout(layout) then return layout end
end

local function Visible(frame)
    if not frame or not frame.IsShown then return false end
    local shown = frame:IsShown()
    return Suite.IsReadable(shown) and shown == true
end

function Bank:Context()
    local character, region = Suite.Inventory:Character()
    if not character then return end
    local db = Suite.Inventory:Database()
    if type(db.accountBankViews) ~= "table" then db.accountBankViews = {} end
    return character, db.accountBankViews, region
end

function Bank:RequestItem(id)
    if not self.requested[id] and C_Item and C_Item.RequestLoadItemDataByID then
        self.requested[id] = true
        C_Item.RequestLoadItemDataByID(id)
    end
end

function Bank:Scan(bankType)
    if not self.bankOpen or not C_Bank or not C_Container or not Enum or not Enum.BankType
        or not C_Bank.CanViewBank or not C_Bank.FetchPurchasedBankTabIDs
        or not C_Bank.FetchNumPurchasedBankTabs or not C_Bank.FetchPurchasedBankTabData
        or not C_Bank.ShouldUsePlayerBagsInBank or not C_Container.GetContainerNumSlots
        or not C_Container.GetContainerItemInfo or not C_Container.GetContainerItemID then return end
    local allowed, bagMode = C_Bank.CanViewBank(bankType), C_Bank.ShouldUsePlayerBagsInBank()
    if not Suite.IsReadable(allowed) or allowed ~= true or not Suite.IsReadable(bagMode) or bagMode ~= true then return end
    local ids, purchased = C_Bank.FetchPurchasedBankTabIDs(bankType), C_Bank.FetchNumPurchasedBankTabs(bankType)
    local metadata = C_Bank.FetchPurchasedBankTabData(bankType)
    if not Suite.IsReadable(ids) or type(ids) ~= "table" or not Integer(purchased, 0, 32)
        or #ids ~= purchased or not Suite.IsReadable(metadata) or type(metadata) ~= "table"
        or #metadata ~= purchased then return end
    local seen, details, snapshot = {}, {}, { schema = 1, tabs = {}, totalSlots = 0 }
    for _, tab in ipairs(metadata) do
        if not Suite.IsReadable(tab) or type(tab) ~= "table" or not Integer(tab.ID, 6, 1000)
            or details[tab.ID] then return end
        details[tab.ID] = tab
    end
    for index, bag in ipairs(ids) do
        if not Integer(bag, 6, 1000) or seen[bag] or not details[bag] then return end
        seen[bag] = true
        local size, metadataTab = C_Container.GetContainerNumSlots(bag), details[bag]
        if not Integer(size, 1, 1000) or snapshot.totalSlots + size > 2816 then return end
        local tab = { bag = bag, size = size, slots = {} }
        tab.name = Text(metadataTab.name) and metadataTab.name or (BANK_BAG or "Bank bag")
        tab.icon = Integer(metadataTab.icon, 1, 2147483647) and metadataTab.icon or nil
        if index > 1 and C_Bank.BankBagTypeAndIDToInvSlot and GetInventoryItemLink then
            local inventorySlot = C_Bank.BankBagTypeAndIDToInvSlot(bankType, index)
            if Integer(inventorySlot, 0, 1000) then
                local link = GetInventoryItemLink("player", inventorySlot + 1)
                if Text(link) and Integer(tonumber(link:match("item:(%d+)")), 1, 2147483647) then tab.link = link end
            end
        end
        for slot = 1, size do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if not Suite.IsReadable(info) then return end
            if info == nil then
                local id = C_Container.GetContainerItemID(bag, slot)
                if not Suite.IsReadable(id) or id ~= nil then
                    if Integer(id, 1, 2147483647) then self:RequestItem(id) end
                    return
                end
            else
                if type(info) ~= "table" or not Integer(info.itemID, 1, 2147483647)
                    or not Integer(info.stackCount, 1, 1000000000) then return end
                if not Suite.IsReadable(info.hyperlink) or not Suite.IsReadable(info.iconFileID) then return end
                if not Text(info.hyperlink) or not Integer(info.iconFileID, 1, 2147483647) then
                    self:RequestItem(info.itemID); return
                end
                -- Keep the full instance link: enchants, gems and random properties matter to tooltips.
                if tonumber(info.hyperlink:match("item:(%d+)")) ~= info.itemID then return end
                tab.slots[slot] = { id = info.itemID, count = info.stackCount, link = info.hyperlink,
                    icon = info.iconFileID, quality = Integer(info.quality, 0, 8) and info.quality or nil,
                    name = Text(info.itemName) and info.itemName or info.hyperlink:match("%[(.-)%]") }
                if Suite.IsReadable(info.isBound) and type(info.isBound) == "boolean" then
                    tab.slots[slot].isBound = info.isBound
                end
            end
        end
        snapshot.tabs[#snapshot.tabs + 1] = tab
        snapshot.totalSlots = snapshot.totalSlots + size
    end
    local now = GetServerTime and GetServerTime()
    snapshot.at = Integer(now, 1, 10000000000) and now or nil
    return snapshot
end

local function Aggregate(snapshot)
    local result = { items = {}, at = snapshot.at }
    for _, tab in ipairs(snapshot.tabs) do
        for _, item in pairs(tab.slots) do
            local count = (result.items[item.id] or 0) + item.count
            if count > 1000000000 then return end
            result.items[item.id] = count
        end
    end
    return result
end

function Bank:Capture()
    if not Suite.db.offlineBank or not self.bankOpen then return end
    local character, accounts, region = self:Context()
    if not character then return end
    self:CaptureLayout(character)
    local types = Enum and Enum.BankType
    if not types or not Integer(types.Character, 0, 2) or not Integer(types.Account, 0, 2) then return end
    local personal, account = self:Scan(types.Character), self:Scan(types.Account)
    if personal then
        character.bankView = personal
        character.bank = Aggregate(personal) or character.bank
    end
    if account then
        accounts[region] = account
        local totals = Aggregate(account)
        if totals then Suite.Inventory:Database().accountBanks[region] = totals end
    end
    if Suite.InventorySearch then Suite.InventorySearch:InventoryChanged() end
    if Suite.CharacterDashboard then Suite.CharacterDashboard:RefreshView() end
end

function Bank:CaptureLayout(character)
    if not Suite.db.offlineBank or not Visible(BankFrame) then return end
    local layout = ReadLayout(BankFrame)
    if character and layout then character.bankViewLayout = layout end
end

function Bank:WatchLayout()
    local frame = BankFrame
    if not frame or self.layoutFrame == frame or InCombatLockdown() or not frame.HookScript then return end
    if frame.IsForbidden then
        local forbidden = frame:IsForbidden()
        if not Suite.IsReadable(forbidden) or forbidden ~= false then return end
    end
    self.layoutFrame = frame
    local function Remember()
        if Suite.db.offlineBank and frame == BankFrame and Visible(frame) then
            local character = self:Context()
            self:CaptureLayout(character)
        end
    end
    -- Remember final shown geometry independently of item-data timers. Hidden reflows are ignored.
    frame:HookScript("OnShow", Remember)
    frame:HookScript("OnSizeChanged", Remember)
    for _, method in ipairs({ "SetPoint", "SetScale", "StopMovingOrSizing" }) do
        if type(frame[method]) == "function" then hooksecurefunc(frame, method, Remember) end
    end
end

function Bank:DefaultLayout()
    if Visible(BankFrame) then
        local live = ReadLayout(BankFrame)
        if live then return live end
    end
    -- A hidden bank may have been reflowed. Its last visible top edge is authoritative.
    local character = self:Context()
    if character and Layout(character.bankViewLayout) then return character.bankViewLayout end
    -- Window tools may have a saved native-bank position before BankFrame has been opened this session.
    local saved = Suite.db.windowTools and Suite.db.windowPositions.BankFrame
    local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
    if Layout(saved) and Number(screenWidth) and screenWidth > 0 and Number(screenHeight) and screenHeight > 0 then
        local width, height = BankFrame:GetWidth(), BankFrame:GetHeight()
        if Number(width) and width > 0 and Number(height) and height > 0 then
            local scale = math.max(0.55, math.min(1.8, saved.scale))
            local limitX, limitY = math.max(0, (screenWidth - width * scale) / 2), math.max(0, (screenHeight - height * scale) / 2)
            local x = math.max(-limitX, math.min(limitX, saved.x * screenWidth))
            local y = math.max(-limitY, math.min(limitY, saved.y * screenHeight))
            return { x = (screenWidth / 2 + x - width * scale / 2) / screenWidth,
                y = (screenHeight / 2 + y + height * scale / 2) / screenHeight, scale = scale }
        end
    end
end

function Bank:PlaceView()
    if not self.frame or InCombatLockdown() then return end
    local layout = self:DefaultLayout()
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    local scale, x, y = 1, 16, -116
    if Layout(layout) and Number(width) and width > 0 and Number(height) and height > 0 then
        scale, x, y = layout.scale, layout.x * width / layout.scale, (layout.y - 1) * height / layout.scale
    elseif GetUIPanelLayoutAttribute then
        local left, top = GetUIPanelLayoutAttribute("LEFT_OFFSET"), GetUIPanelLayoutAttribute("TOP_OFFSET")
        if Number(left) then x = left end
        if Number(top) then y = top end
    end
    -- Keep the mover's reset target current even when the snapshot has its own saved placement.
    local record = Suite.Windows and Suite.Windows.tracked and Suite.Windows.tracked[FRAME_NAME]
    if record then
        record.originalScale = scale
        record.originalPoints = { { "TOPLEFT", UIParent, "TOPLEFT", x, y } }
    end
    local saved = Suite.db.windowTools and Suite.db.windowPositions[FRAME_NAME]
    if record and (record.dragging or Layout(saved)) then return end
    self.frame:SetScale(scale); self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
end

function Bank:GetSnapshot(bankType)
    local character, accounts, region = self:Context()
    if not character then return end
    local snapshot
    if bankType == 2 then snapshot = accounts[region] else snapshot = character.bankView end
    if not Suite.IsReadable(snapshot) or type(snapshot) ~= "table" or not Suite.IsReadable(snapshot.schema) or snapshot.schema ~= 1
        or not Integer(snapshot.totalSlots, 0, 2816) or not Suite.IsReadable(snapshot.tabs) or type(snapshot.tabs) ~= "table"
        or #snapshot.tabs > 32 then return end
    -- Validate persisted data again, before arithmetic, indexing or presentation.
    local total, seen = 0, {}
    for _, tab in ipairs(snapshot.tabs) do
        if not Suite.IsReadable(tab) or type(tab) ~= "table" or not Integer(tab.bag, 6, 1000)
            or seen[tab.bag] or not Integer(tab.size, 1, 1000) or not Suite.IsReadable(tab.slots) or type(tab.slots) ~= "table" then return end
        seen[tab.bag] = true; total = total + tab.size
        for slot, item in pairs(tab.slots) do
            if not Integer(slot, 1, tab.size) or not Suite.IsReadable(item) or type(item) ~= "table"
                or not Integer(item.id, 1, 2147483647) or not Integer(item.count, 1, 1000000000)
                or not Integer(item.icon, 1, 2147483647) or not Text(item.link)
                or tonumber(item.link:match("item:(%d+)")) ~= item.id then return end
        end
    end
    if total ~= snapshot.totalSlots then return end
    return snapshot
end

function Bank:Slots(snapshot, page)
    local rows, offset = {}, 0
    local first, last = (page - 1) * PAGE_SIZE + 1, page * PAGE_SIZE
    for _, tab in ipairs(snapshot.tabs) do
        for slot = 1, tab.size do
            local index = offset + slot
            if index >= first and index <= last then
                rows[#rows + 1] = { item = tab.slots[slot], bag = tab.bag, slot = slot }
            end
        end
        offset = offset + tab.size
    end
    return rows
end

function Bank:HideTooltip()
    if self.hovered and GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(self.hovered) then GameTooltip:Hide() end
    self.hovered = nil
end

function Bank:ShowTooltip(button)
    self:HideTooltip()
    local item = button.bankItem
    if not item or not Text(item.link) or not GameTooltip or not GameTooltip.SetHyperlink then return end
    self.hovered = button
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(item.link)
    GameTooltip:Show()
    if IsModifiedClick and IsModifiedClick("COMPAREITEMS") and GameTooltip_ShowCompareItem then
        GameTooltip_ShowCompareItem(GameTooltip)
    end
end

local function Font(parent, template, point, x, y)
    local text = parent:CreateFontString(nil, "OVERLAY", template)
    text:SetPoint(point, x, y)
    return text
end

function Bank:CreateView()
    if self.frame then return true end
    if InCombatLockdown() or not BankFrame then return false end
    -- Compose native visual templates only. BankFrameTemplate/BankPanelTemplate contain live bank actions.
    local frame = CreateFrame("Frame", FRAME_NAME, UIParent, "PortraitFrameTemplate")
    self.frame = frame
    frame:Hide(); frame:SetSize(480, 460)
    self:PlaceView()
    frame:SetFrameStrata("MEDIUM"); frame:EnableMouse(true)
    frame:SetToplevel(true)
    frame:SetTitle(BANK or "Bank")
    frame:SetPortraitToAsset("Interface\\Icons\\INV_Misc_Bag_10")
    frame.CloseButton:SetScript("OnClick", function() frame:Hide() end)
    frame:SetScript("OnHide", function() self:HideTooltip() end)
    if UISpecialFrames then table.insert(UISpecialFrames, FRAME_NAME) end
    local background = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    background:SetAtlas("bank-frame-background")
    background:SetHorizTile(true); background:SetVertTile(true)
    background:SetPoint("TOPLEFT", 0, -20); background:SetPoint("BOTTOMRIGHT", 0, 30)
    local inset = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
    inset:SetPoint("TOPLEFT", 0, -20); inset:SetPoint("BOTTOMRIGHT", 0, 30)
    if inset.Bg then inset.Bg:Hide() end
    local shadows = CreateFrame("Frame", nil, frame, "BankPanelEdgeShadowTemplate")
    shadows:SetPoint("TOPLEFT"); shadows:SetPoint("BOTTOMRIGHT", 0, 30)
    self.status = Font(frame, "GameFontHighlightSmall", "BOTTOMLEFT", 20, 14)
    self.status:SetWidth(438); self.status:SetJustifyH("LEFT")
    self.empty = Font(frame, "GameFontHighlight", "CENTER", 0, 0)
    self.empty:SetWidth(370); self.empty:SetWordWrap(true)
    self.bagLabel = Font(frame, "GameFontNormalLarge2", "BOTTOMLEFT", 43, 80)
    self.bagLabel:SetText(BAGSLOTTEXT_COLON or "Bag Slots:")
    local search = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
    self.search = search
    search:SetSize(110, 20); search:SetPoint("TOPRIGHT", -56, -33); search:SetAutoFocus(false)
    search:SetMaxLetters(100)
    search:SetScript("OnTextChanged", function(box)
        if SearchBoxTemplate_OnTextChanged then SearchBoxTemplate_OnTextChanged(box) end
        self:Refresh()
    end)
    search:SetScript("OnEscapePressed", function(box) box:ClearFocus(); frame:Hide() end)
    search:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)
    if Suite.InventorySearch then Suite.InventorySearch:Discover() end
    for index = 1, PAGE_SIZE do
        local button = CreateFrame("ItemButton", nil, frame, "WoWForeverSuiteBankSlotTemplate")
        self.buttons[index] = button
        button:SetSize(37, 37)
        button:SetPoint("TOPLEFT", 47 + ((index - 1) % COLUMNS) * 50, -63 - math.floor((index - 1) / COLUMNS) * 47)
        button.Background = button:CreateTexture(nil, "BACKGROUND")
        button.Background:SetAllPoints(button); button.Background:SetAtlas("bags-item-bankslot64")
        -- No live bag/slot methods, item locations, pickup, use, split or receive-drag handlers.
        button:SetScript("OnEnter", function() self:ShowTooltip(button) end)
        button:SetScript("OnLeave", function() self:HideTooltip() end)
        button:SetScript("OnHide", function() if self.hovered == button then self:HideTooltip() end end)
        button:SetScript("OnClick", function()
            local item = button.bankItem
            if item and HandleModifiedItemClick and IsModifiedClick
                and (IsModifiedClick("CHATLINK") or IsModifiedClick("DRESSUP")) then HandleModifiedItemClick(item.link) end
        end)
        button:Hide()
    end
    return true
end

function Bank:Refresh()
    if not self.frame then return end
    if InCombatLockdown() then
        Suite.pending.bankViewRefresh = function() if Suite.db.offlineBank and Visible(self.frame) then self:Refresh() end end
        return
    end
    local hovered = self.hovered
    local hoverLink = hovered and hovered.bankItem and hovered.bankItem.link
    self:HideTooltip()
    if self.bankType == 2 then
        local account = self:GetSnapshot(2)
        if not account or account.totalSlots == 0 then self.bankType, self.page = 0, 1 end
    end
    local snapshot = self:GetSnapshot(self.bankType)
    local pages = snapshot and math.max(1, math.ceil(snapshot.totalSlots / PAGE_SIZE)) or 1
    self.page = math.max(1, math.min(self.page, pages))
    local slots = snapshot and self:Slots(snapshot, self.page) or {}
    local height = 460 + math.max(0, math.ceil(#slots / COLUMNS) - 6) * 47
    self.frame:SetHeight(height)
    self.frame:SetTitle(self.bankType == 2 and (ACCOUNT_BANK_PANEL_TITLE or "Account Bank") or (BANK or "Bank"))
    local search = self.search:GetText()
    search = Text(search) and search:lower() or ""
    for index, button in ipairs(self.buttons) do
        local row, item = slots[index], slots[index] and slots[index].item
        button.bankItem, button.itemLink = item, item and item.link or nil
        SetItemButtonTexture(button, item and item.icon or nil)
        SetItemButtonCount(button, item and item.count or 0)
        local bound
        if item and Suite.IsReadable(item.isBound) and type(item.isBound) == "boolean" then bound = item.isBound end
        button:SetItemButtonQuality(item and Integer(item.quality, 0, 8) and item.quality or nil, button.itemLink, false, bound)
        button:GetNormalTexture():SetAtlas(item and "bank-frame-bag-slotframe" or "bank-frame-item-slotframe", false)
        button.Background:ClearAllPoints()
        if self.bankType == 2 then
            button.Background:SetAtlas("warband-bank-slot")
            button.Background:SetPoint("TOPLEFT", -6, 5); button.Background:SetPoint("BOTTOMRIGHT", 6, -7)
        else button.Background:SetAtlas("bags-item-bankslot64"); button.Background:SetAllPoints(button) end
        local name = item and (Text(item.name) and item.name or item.link) or ""
        button.searchOverlay:SetShown(search ~= "" and (not item or not name:lower():find(search, 1, true)))
        button:SetShown(row ~= nil)
        if Suite.Items and (Suite.db.itemLevels or Suite.db.upgradeHints) then Suite.Items:Track(button, button.itemLink, true) end
    end
    self.empty:SetText(snapshot and "No bank slots recorded." or "Visit a bank with Bank snapshots enabled to save this view.")
    self.empty:SetShown(#slots == 0)
    local timestamp = snapshot and Integer(snapshot.at, 1, 10000000000) and date and date("%b %d, %H:%M", snapshot.at)
    self.status:SetText("Saved bank · " .. (timestamp or "Not recorded") .. " · View only")
    self:RefreshTabs()
    self:RefreshBags(snapshot)
    if Suite.db.windowTools then Suite.Windows:Track(FRAME_NAME, self.frame) end
    if hovered and hoverLink and hovered.bankItem and hovered.bankItem.link == hoverLink
        and Visible(self.frame) and hovered.IsMouseOver then
        local over = hovered:IsMouseOver()
        if Suite.IsReadable(over) and over == true then self:ShowTooltip(hovered) end
    end
end

function Bank:RefreshTabs()
    local choices = {}
    for _, bankType in ipairs({ 0, 2 }) do
        local snapshot = self:GetSnapshot(bankType)
        local pages = snapshot and math.ceil(snapshot.totalSlots / PAGE_SIZE) or 0
        if bankType == 0 then pages = math.max(1, pages) end
        for page = 1, pages do choices[#choices + 1] = { bankType = bankType, page = page } end
    end
    for index, choice in ipairs(choices) do
        local tab = self.pageTabs[index]
        if not tab then
            tab = CreateFrame("Frame", nil, self.frame, "LargeSideTabButtonTemplate")
            self.pageTabs[index] = tab
            tab:SetFillToInterior(true)
            tab:SetCustomOnMouseUpHandler(function(button, mouse, inside)
                if mouse == "LeftButton" and inside and not InCombatLockdown() then
                    self.bankType, self.page = button.bankType, button.page
                    self:Refresh()
                end
            end)
        end
        tab.bankType, tab.page = choice.bankType, choice.page
        tab:ClearAllPoints()
        if index == 1 then tab:SetPoint("TOPLEFT", self.frame, "TOPRIGHT", 3, -60)
        else tab:SetPoint("TOPLEFT", self.pageTabs[index - 1], "BOTTOMLEFT", 0, -2) end
        tab.Icon:SetTexture("Interface\\Icons\\" .. (choice.bankType == 2 and "UI_Warbands" or pageIcons[choice.page] or pageIcons[1]))
        tab.tooltipText = (choice.bankType == 2 and (ACCOUNT_BANK_PANEL_TITLE or "Account Bank") or (BANK or "Bank")) .. " · " .. choice.page
        tab:SetChecked(choice.bankType == self.bankType and choice.page == self.page); tab:Show()
    end
    for index = #choices + 1, #self.pageTabs do self.pageTabs[index]:Hide() end
end

function Bank:RefreshBags(snapshot)
    local tabs = snapshot and snapshot.tabs or {}
    self.bagLabel:SetShown(#tabs > 1)
    for index = 2, #tabs do
        local button = self.bagButtons[index]
        if not button then
            button = CreateFrame("ItemButton", nil, self.frame, "WoWForeverSuiteBankBagTemplate")
            self.bagButtons[index] = button
            button:SetSize(37, 37); button:SetScale(0.75)
            button:SetScript("OnEnter", function()
                if button.bankItem then self:ShowTooltip(button); return end
                self:HideTooltip()
                if GameTooltip then
                    self.hovered = button; GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
                    GameTooltip:SetText(button.bankBagName); GameTooltip:Show()
                end
            end)
            button:SetScript("OnLeave", function() self:HideTooltip() end)
        end
        button.bankBagName = Text(tabs[index].name) and tabs[index].name or (BANK_BAG or "Bank bag")
        local bagLink = tabs[index].link
        button.bankItem = Text(bagLink) and Integer(tonumber(bagLink:match("item:(%d+)")), 1, 2147483647) and { link = bagLink } or nil
        button:ClearAllPoints()
        if index == 2 then button:SetPoint("TOPLEFT", self.bagLabel, "TOPRIGHT", 20, 5)
        else button:SetPoint("TOPLEFT", self.bagButtons[index - 1], "TOPLEFT", 50, 0) end
        SetItemButtonTexture(button, Integer(tabs[index].icon, 1, 2147483647) and tabs[index].icon or "Interface\\Icons\\INV_Misc_Bag_10")
        button:Show()
    end
    for index, button in pairs(self.bagButtons) do if index > #tabs then button:Hide() end end
end

function Bank:Toggle()
    if not Suite.db or not Suite.db.offlineBank then
        Suite.Print("Enable Bank snapshots in /wfs → Windows first."); return
    end
    if InCombatLockdown() then
        if Suite.pending.bankViewToggle then Suite.pending.bankViewToggle = nil
        else
            Suite.pending.bankViewToggle = function() if Suite.db.offlineBank then self:Toggle() end end
            Suite.Print("Bank view will open after combat. Press again to cancel.")
        end
        return
    end
    if Visible(BankFrame) then
        self:Capture()
        if HideUIPanel then HideUIPanel(BankFrame) end
        return
    end
    if Visible(self.frame) then self.frame:Hide(); return end
    if not self:CreateView() then Suite.Print("The bank view is unavailable on this client."); return end
    if Suite.GUI and Suite.GUI.frame then Suite.GUI.frame:Hide() end
    self:Refresh(); self:PlaceView(); self.frame:Show()
end

function Bank:Cancel()
    if self.timer then self.timer:Cancel(); self.timer = nil end
end

function Bank:Schedule()
    if self.timer or not Suite.db.offlineBank or not C_Timer or not C_Timer.NewTimer then return end
    self.timer = C_Timer.NewTimer(0.15, function()
        self.timer = nil
        if not Suite.db.offlineBank then return end
        self:Capture()
        if Visible(self.frame) then self:Refresh() end
    end)
end

function Bank:OnEvent(event, id)
    if not Suite.db.offlineBank then return end
    if event == "MODIFIER_STATE_CHANGED" then
        if self.hovered and self.hovered.bankItem then self:ShowTooltip(self.hovered) end
        return
    elseif event == "BANKFRAME_OPENED" then
        self.bankOpen, self.requested = true, {}
        if self.frame then self.frame:Hide() end
        Suite.AfterCombat("bankLayoutWatch", function()
            if Suite.db.offlineBank and self.bankOpen then self:WatchLayout() end
        end)
    elseif event == "BANKFRAME_CLOSED" then
        -- The close event can arrive after the client has already cleared its bank containers.
        Suite.pending.bankLayoutWatch = nil
        self.bankOpen = false; self:Cancel(); return
    elseif event == "PLAYER_LOGOUT" then self:Cancel(); self:Capture(); return
    elseif event == "PLAYER_ENTERING_WORLD" then
        self.bankOpen = Visible(BankFrame)
        if self.frame then self.frame:Hide() end
    end
    if self.bankOpen or Visible(self.frame) then self:Schedule() end
end

function Bank:Apply()
    -- This named, non-secure click target is required by Blizzard's CLICK keybinding dispatcher.
    Suite.AfterCombat("bankBinding", function()
        if not self.bindingButton then
            self.bindingButton = CreateFrame("Button", "WoWForeverSuiteBankToggleButton", UIParent)
            self.bindingButton:RegisterForClicks("LeftButtonUp")
            self.bindingButton:SetScript("OnClick", function() self:Toggle() end)
            self.bindingButton:Hide()
        end
    end)
    if not Suite.db.offlineBank then
        self:Cancel(); self:HideTooltip()
        Suite.pending.bankViewToggle, Suite.pending.bankViewRefresh, Suite.pending.bankViewEnable = nil, nil, nil
        Suite.pending.bankLayoutWatch = nil
        if self.events then self.events:UnregisterAllEvents() end
        if self.frame then self.frame:Hide() end
        self.active, self.bankOpen, self.requested = nil, nil, {}
        return
    end
    Suite.AfterCombat("bankViewEnable", function()
        if not Suite.db.offlineBank or self.active then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event, ...) self:OnEvent(event, ...) end)
        end
        for _, event in ipairs({ "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "BAG_UPDATE_DELAYED",
            "PLAYERBANKSLOTS_CHANGED", "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED", "BANK_TABS_CHANGED",
            "BANK_TAB_SETTINGS_UPDATED", "ITEM_DATA_LOAD_RESULT", "PLAYER_ENTERING_WORLD", "PLAYER_LOGOUT",
            "MODIFIER_STATE_CHANGED" }) do self.events:RegisterEvent(event) end
        self.active, self.bankOpen = true, Visible(BankFrame)
        self:WatchLayout()
        self:Capture()
    end)
end
