local _, Suite = ...
local Browser = { query = "", location = "all", page = 1 }
Suite.CharacterBrowser = Browser
local ROWS, MAX_FAVORITES = 8, 8
local colors = { teal = { 0.41, 0.84, 0.75 }, text = { 0.88, 0.91, 0.93 }, muted = { 0.55, 0.65, 0.7 },
    stale = { 0.95, 0.72, 0.38 }, row = { 0.07, 0.095, 0.11 } }
local locations = { all = "All locations", bags = "Bags", bank = "Personal bank", account = "Shared bank" }
local function Table(value) return Suite.IsReadable(value) and type(value) == "table" end
local function Text(value, limit)
    return Suite.IsReadable(value) and type(value) == "string" and #value > 0 and #value <= (limit or 128) and not value:find("[%c|]")
end
local function Integer(value, low, high)
    return Suite.IsReadable(value) and type(value) == "number" and value >= low and value <= high and value == math.floor(value)
end
local function Call(callback, ...)
    if not Suite.IsReadable(callback) or type(callback) ~= "function" then return end
    local ok, value = pcall(callback, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Query(value)
    if not Suite.IsReadable(value) or type(value) ~= "string" or #value > 100 or value:find("[%c|]") then return end
    return value:match("^%s*(.-)%s*$")
end
local function Key(view)
    return view.query:lower() .. "\031" .. (view.owner or "") .. "\031" .. view.location
end
local function Label(parent, text, x, y, width, size, color)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", size or 11, ""); label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(width); label:SetJustifyH("LEFT"); label:SetWordWrap(false)
    label:SetTextColor(unpack(color or colors.text)); label:SetText(text)
    return label
end
local function Button(parent, text, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetPoint("TOPLEFT", x, y); button:SetSize(width, 28)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    button:SetBackdropColor(unpack(colors.row)); Suite.Theme:Backdrop(button, 1)
    button.label = Label(button, text, 9, -8, width - 18, 11, colors.teal)
    button:SetScript("OnClick", function() if not InCombatLockdown() then callback() end end)
    button:SetScript("OnEnter", function() button:SetBackdropColor(0.09, 0.13, 0.145) end)
    button:SetScript("OnLeave", function() button:SetBackdropColor(unpack(colors.row)) end)
    return button
end

function Browser:InitializeOptions(saved)
    local options, seen = { schema = 1, favorites = {} }, {}
    if not Table(saved) or not Table(saved.favorites) then return options end
    for index = 1, MAX_FAVORITES do
        local entry = saved.favorites[index]
        if Table(entry) then
            local query = Query(entry.query)
            local location = Text(entry.location) and locations[entry.location] and entry.location
            local owner = entry.owner
            if query and location and Suite.IsReadable(entry.owner) and (owner == nil or Text(owner)) then
                local view = { query = query, location = location, owner = owner }
                if not seen[Key(view)] then options.favorites[#options.favorites + 1], seen[Key(view)] = view, true end
            end
        end
    end
    return options
end
function Browser:Options()
    local options = Suite.db.inventoryBrowser
    if not Table(options) or not Table(options.favorites) then
        options = self:InitializeOptions(options); Suite.db.inventoryBrowser = options
    end
    return options
end
function Browser:View() return { query = Query(self.query) or "", owner = self.owner, location = self.location } end
function Browser:FavoriteIndex()
    local key = Key(self:View())
    for index, view in ipairs(self:Options().favorites) do if Key(view) == key then return index end end
end
function Browser:SaveView()
    if InCombatLockdown() then return false end
    local favorites, index = self:Options().favorites, self:FavoriteIndex()
    local success = true
    if index then table.remove(favorites, index); self.message = "Saved view removed."
    elseif #favorites >= MAX_FAVORITES then success = false; self.message = "Eight views are saved. Remove a saved view before adding another."
    else favorites[#favorites + 1] = self:View(); self.message = "Search and filters saved." end
    self:Update(); return success
end
function Browser:LoadView(index)
    if InCombatLockdown() or not Integer(index, 1, MAX_FAVORITES) then return false end
    local view = self:Options().favorites[index]
    if not view then return false end
    self.query, self.owner, self.location = view.query, view.owner, view.location
    self.page, self.expanded, self.message = 1, false, nil
    self:Update(); return true
end
function Browser:Age(at, recorded)
    if recorded == false then return "Not recorded", false end
    if not Integer(at, 1, 10000000000) then return "Date unavailable", false end
    local now = Call(GetServerTime)
    if not Integer(now, 1, 10000000000) or at > now then return "Date unavailable", false end
    local age = now - at
    if age < 60 then return "Just recorded", false end
    if age < 3600 then return math.floor(age / 60) .. "m ago", false end
    if age < 86400 then return math.floor(age / 3600) .. "h ago", false end
    return math.floor(age / 86400) .. "d ago", true
end
function Browser:OwnerName(guid)
    if not Text(guid) then return "Unrecorded character" end
    local owner = Suite.InventorySearch.owners and Suite.InventorySearch.owners[guid]
    if owner then return owner.name end
    local region = Call(GetCurrentRegion)
    local record = Text(guid) and Suite.Inventory:Database().characters[guid]
    if Table(record) and Integer(region, 1, 1000000) and Suite.IsReadable(record.region) and record.region == region and Text(record.name) then
        return Text(record.fullName) and record.fullName or record.name
    end
    return "Unrecorded character"
end
function Browser:Coverage()
    local search = Suite.InventorySearch
    if not search.region then return "Character region unavailable." end
    if self.location == "account" then
        local status = search.coverage and search.coverage.account and search.coverage.account.account
        return "Shared bank · " .. self:Age(status and status.at, status and status.recorded == true or false)
            .. (status and status.partial and " · Partial record" or "")
    end
    if self.owner then
        local status = search.coverage and search.coverage[self.owner]
        local function Stamp(key)
            local source = status and status[key]
            return self:Age(source and source.at, source and source.recorded == true or false)
        end
        return "Bags: " .. Stamp("bags") .. "  ·  Bank: " .. Stamp("bank")
            .. (status and (status.bags and status.bags.partial or status.bank and status.bank.partial) and " · Partial record" or "")
    end
    local count, bags, bank, partial = 0, 0, 0, false
    for guid, status in pairs(search.coverage or {}) do if guid ~= "account" then
        count = count + 1
        if status.bags and status.bags.recorded then bags = bags + 1 end
        if status.bank and status.bank.recorded then bank = bank + 1 end
        if status.bags and status.bags.partial or status.bank and status.bank.partial then partial = true end
    end end
    return "Bags recorded: " .. bags .. "/" .. count .. "  ·  Banks: " .. bank .. "/" .. count
        .. (partial and "  ·  Some data incomplete" or "")
end
function Browser:BankTarget()
    if self.location == "account" then return "account", 2 end
    return self.owner, 0
end
function Browser:OpenBank()
    local guid, bankType = self:BankTarget()
    if guid then return Suite.OfflineBank:OpenFor(guid, bankType) end
    return false
end
function Browser:Open(guid)
    if not Suite.IsReadable(guid) or guid ~= nil and not Text(guid) then return end
    if InCombatLockdown() then Suite.AfterCombat("guiOpen", function() self:Open(guid) end); return end
    self.owner, self.location, self.page = guid, "all", 1
    Suite.CharacterDashboard.view = "inventory"
    Suite.GUI:OpenPage("characters")
end
function Browser:SetLocation(location)
    if InCombatLockdown() or not Text(location) or not locations[location] then return false end
    self.location, self.page, self.message = location, 1, nil; self:Update(); return true
end
function Browser:ToggleOwner()
    if InCombatLockdown() then return end
    if self.owner then self.owner = nil
    else self.owner = Suite.CharacterDashboard.selected end
    self.page, self.message = 1, nil; self:Update()
end
function Browser:Select(row)
    if InCombatLockdown() or not row then return end
    if row.link and (Call(IsModifiedClick, "CHATLINK") == true or Call(IsModifiedClick, "DRESSUP") == true) then
        Call(HandleModifiedItemClick, row.link); return
    end
    if row.owner.guid == "account" then self.location = "account"
    else self.owner = row.owner.guid end
    self.page, self.message = 1, nil; self:Update()
end
function Browser:HideTooltip()
    local tip = GameTooltip
    if self.hovered and tip and (not tip.IsForbidden or Call(tip.IsForbidden, tip) == false) and Call(tip.GetOwner, tip) == self.hovered
        and (not InCombatLockdown() or Call(tip.IsProtected, tip) == false) then tip:Hide() end
    self.hovered = nil
end
function Browser:Tooltip(button)
    if button.view then self:FavoriteTooltip(button); return end
    local tip, row = GameTooltip, button.entry
    if InCombatLockdown() or not row or not tip or tip.IsForbidden and Call(tip.IsForbidden, tip) ~= false then return end
    tip:SetOwner(button, "ANCHOR_RIGHT"); self.hovered = button
    if row.link and type(tip.SetHyperlink) == "function" then tip:SetHyperlink(row.link) else tip:AddLine(row.name) end
    tip:AddLine(" "); tip:AddLine(row.owner.name, unpack(colors.teal)); tip:AddLine(row.owner.context, unpack(colors.muted))
    tip:AddLine(Suite.InventorySearch:Counts(row))
    for _, key in ipairs({ "bags", "bank", "account" }) do if row[key] then
        local at = row[key .. "At"]
        local stamp = Integer(at, 1, 10000000000) and Call(date, "%b %d, %H:%M", at) or nil
        tip:AddLine((key == "bags" and "Bags recorded: " or "Bank recorded: ") .. (Text(stamp) and stamp or "Date unavailable"), unpack(colors.muted))
    end end
    tip:AddLine("Recorded counts; item variants are combined.", unpack(colors.muted))
    tip:AddLine("Gear comparisons use your current character.", unpack(colors.muted))
    tip:AddLine("Click to browse this owner. Modified item-link clicks stay native.", unpack(colors.muted))
    tip:Show()
    if row.link and type(GameTooltip_ShowCompareItem) == "function" and Call(IsModifiedClick, "COMPAREITEMS") == true then
        pcall(GameTooltip_ShowCompareItem, tip)
    end
end
function Browser:FavoriteTooltip(button)
    local tip, view = GameTooltip, button.view
    if InCombatLockdown() or not view or not tip or tip.IsForbidden and Call(tip.IsForbidden, tip) ~= false then return end
    tip:SetOwner(button, "ANCHOR_RIGHT"); self.hovered = button
    tip:AddLine(view.query ~= "" and view.query or "All recorded items", unpack(colors.teal))
    tip:AddLine(view.owner and self:OwnerName(view.owner) or "All characters", unpack(colors.text))
    tip:AddLine(locations[view.location], unpack(colors.muted))
    tip:AddLine("Click to restore this search and its filters.", unpack(colors.muted)); tip:Show()
end
function Browser:Cancel()
    if self.timer then self.timer:Cancel(); self.timer = nil end
    Suite.pending.inventoryBrowserView = nil
end
function Browser:SetVisible(visible)
    if self.visible == visible then return end
    self.visible = visible; self:Cancel()
    if not self.panel then return end
    self.panel:UnregisterAllEvents()
    if visible then
        for _, event in ipairs({ "ITEM_DATA_LOAD_RESULT", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "MODIFIER_STATE_CHANGED" }) do
            if not C_EventUtils or not C_EventUtils.IsEventValid or Call(C_EventUtils.IsEventValid, event) == true then
                pcall(self.panel.RegisterEvent, self.panel, event)
            end
        end
    else
        self:HideTooltip(); self.search:ClearFocus(); self.rows, self.expanded = nil, false
        for _, button in ipairs(self.buttons) do button.entry = nil end
    end
end
function Browser:Schedule()
    if not self.visible or self.timer then return end
    if InCombatLockdown() then
        Suite.pending.inventoryBrowserView = function() if self.visible then self:Update() end end
        return
    end
    if C_Timer and C_Timer.NewTimer then self.timer = C_Timer.NewTimer(0.12, function()
        self.timer = nil; if self.visible then self:Update() end
    end) end
end
function Browser:Update()
    if self.visible then Suite.CharacterDashboard:RefreshView() end
end
function Browser:Changed() if self.visible then self:Schedule() end end
function Browser:OnEvent(event, id)
    if not self.visible then return end
    if event == "PLAYER_REGEN_DISABLED" then self:Cancel(); self:HideTooltip()
    elseif event == "MODIFIER_STATE_CHANGED" then if self.hovered then self:Tooltip(self.hovered) end
    elseif event == "ITEM_DATA_LOAD_RESULT" then
        if Integer(id, 1, 2147483647) and Suite.InventorySearch.requested[id] then
            Suite.InventorySearch.metadata[id] = nil; self:Schedule()
        end
    else Suite.InventorySearch.index = nil; self:Schedule() end
end

function Browser:Build(parent)
    if self.panel then return self.panel end
    if InCombatLockdown() then return end
    local panel = CreateFrame("Frame", nil, parent); panel:SetSize(780, 620); self.panel = panel
    panel:SetPoint("TOPLEFT", 0, -40)
    panel:SetScript("OnEvent", function(_, ...) self:OnEvent(...) end)
    panel:SetScript("OnHide", function() self:SetVisible(false) end)
    self.ownerButton = Button(panel, "All characters", 0, 0, 384, function() self:ToggleOwner() end)
    self.locationButton = Button(panel, "All locations", 396, 0, 384, function()
        self:SetLocation(({ all = "bags", bags = "bank", bank = "account", account = "all" })[self.location])
    end)
    self.scope = Label(panel, "", 0, -36, 780, 10, colors.muted)
    local search = CreateFrame("EditBox", nil, panel, "BackdropTemplate"); self.search = search
    search:SetPoint("TOPLEFT", 0, -58); search:SetSize(686, 28); search:SetAutoFocus(false); search:SetMaxLetters(100)
    search:SetFont("Fonts\\FRIZQT__.TTF", 12, ""); search:SetTextInsets(8, 8, 0, 0)
    search:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    search:SetBackdropColor(unpack(colors.row)); Suite.Theme:Backdrop(search, 1)
    self.placeholder = Label(search, "Search item name, type, or item ID", 8, -8, 400, 11, colors.muted)
    search:SetScript("OnTextChanged", function(box)
        if self.updating then return end
        self.query, self.page, self.message = Query(Call(box.GetText, box)) or "", 1, nil
        self.placeholder:SetShown(self.query == ""); self:Schedule()
    end)
    search:SetScript("OnEscapePressed", function(box) box:SetText(""); self.query, self.page = "", 1; box:ClearFocus(); self:Update() end)
    search:SetScript("OnEnterPressed", function(box) box:ClearFocus(); self:Cancel(); self:Update() end)
    self.saveButton = Button(panel, "Save view", 692, -58, 88, function() self:SaveView() end)
    self.favoriteButton = Button(panel, "Saved searches", 0, -98, 384, function() self.expanded = not self.expanded; self:Update() end)
    self.favoriteHint = Label(panel, "Searches remember these filters", 408, -107, 372, 10, colors.muted)
    self.favoriteRows = {}
    for index = 1, MAX_FAVORITES do
        self.favoriteRows[index] = Button(panel, "", ((index - 1) % 2) * 396, -136 - math.floor((index - 1) / 2) * 34, 384,
            function() self:LoadView(index) end)
        local button = self.favoriteRows[index]
        button:SetScript("OnEnter", function() self:FavoriteTooltip(button) end)
        button:SetScript("OnLeave", function() if self.hovered == button then self:HideTooltip() end end)
    end
    self.coverage = Label(panel, "", 0, -140, 780, 10, colors.muted)
    self.summary = Label(panel, "", 0, -160, 780, 11)
    self.buttons = {}
    for index = 1, ROWS do
        local button
        button = Button(panel, "", 0, 0, 780, function() self:Select(button.entry) end)
        button:SetHeight(44); button.label:Hide()
        button.icon = button:CreateTexture(nil, "ARTWORK"); button.icon:SetSize(28, 28); button.icon:SetPoint("TOPLEFT", 8, -8)
        button.name = Label(button, "", 44, -7, 628, 12)
        button.count = Label(button, "", 678, -7, 92, 12, colors.teal); button.count:SetJustifyH("RIGHT")
        button.context = Label(button, "", 44, -26, 566, 10, colors.muted)
        button.age = Label(button, "", 616, -26, 154, 10, colors.muted); button.age:SetJustifyH("RIGHT")
        button:SetScript("OnEnter", function() self:Tooltip(button) end)
        button:SetScript("OnLeave", function() if self.hovered == button then self:HideTooltip() end end)
        self.buttons[index] = button
    end
    self.empty = Label(panel, "", 0, 0, 780, 12, colors.muted); self.empty:SetHeight(52); self.empty:SetWordWrap(true)
    self.previous = Button(panel, "Previous", 0, 0, 90, function() self.page = math.max(1, self.page - 1); self:Update() end)
    self.next = Button(panel, "Next", 690, 0, 90, function() self.page = self.page + 1; self:Update() end)
    self.pageLabel = Label(panel, "", 100, 0, 580, 11, colors.muted); self.pageLabel:SetJustifyH("CENTER")
    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function(_, delta)
        if InCombatLockdown() or not Integer(delta, -100, 100) or delta == 0 then return end
        if Call(IsShiftKeyDown) == true then self.page = math.max(1, self.page - delta); self:Update()
        else Suite.GUI:ScrollTo((Suite.GUI.scrollOffset or 0) - delta * 40) end
    end)
    self.bankButton = Button(panel, "Open saved bank", 0, 0, 384, function() self:OpenBank() end)
    self.notice = Label(panel, "", 0, 0, 780, 10, colors.muted); self.notice:SetHeight(30); self.notice:SetWordWrap(true)
    return panel
end

function Browser:Refresh()
    if not self.panel or InCombatLockdown() then return end
    self:HideTooltip()
    local more
    self.rows, self.pendingItems, more = Suite.InventorySearch:Query(self.query, { browse = true, owner = self.owner, location = self.location })
    local favorites, selected = self:Options().favorites, self:FavoriteIndex()
    self.updating = true; self.search:SetText(self.query); self.updating = nil
    self.placeholder:SetShown(self.query == "")
    self.ownerButton.label:SetText(self.location == "account" and "Shared bank · all characters" or self.owner and self:OwnerName(self.owner) or "All characters")
    self.ownerButton:SetEnabled(self.location ~= "account")
    self.locationButton.label:SetText(locations[self.location])
    self.scope:SetText(self.location == "account" and "Shared contents are counted once for this region."
        or self.owner and ("Inventory belonging to " .. self:OwnerName(self.owner)) or "All recorded characters in this region")
    self.saveButton.label:SetText(selected and "Remove" or "Save view")
    self.favoriteButton.label:SetText((self.expanded and "Hide" or "Saved") .. " searches (" .. #favorites .. ")")
    self.favoriteHint:SetText(self.expanded and #favorites == 0 and "Use Save view to keep a search." or "Saved views include character and location.")
    local extra = self.expanded and math.ceil(#favorites / 2) * 34 + 8 or 0
    for index, button in ipairs(self.favoriteRows) do
        local view = favorites[index]
        button:SetShown(self.expanded and view ~= nil)
        button.view = view
        if view then button.label:SetText((view.query ~= "" and view.query or "All items") .. " · "
            .. (view.owner and self:OwnerName(view.owner) or "Everyone") .. " · " .. locations[view.location]) end
    end
    local function Place(widget, x, y) widget:ClearAllPoints(); widget:SetPoint("TOPLEFT", x, -y) end
    Place(self.coverage, 0, 140 + extra); self.coverage:SetText(self:Coverage())
    local total = 0
    for _, row in ipairs(self.rows) do total = total + (row.bags or 0) + (row.bank or 0) + (row.account or 0) end
    Place(self.summary, 0, 160 + extra)
    self.summary:SetText(#self.rows == 0 and self.pendingItems > 0 and "Searching recorded items · names loading/unavailable"
        or (#self.rows .. " results · " .. total .. " items recorded"))
    local pages = math.max(1, math.ceil(#self.rows / ROWS)); self.page = math.max(1, math.min(pages, self.page))
    for index, button in ipairs(self.buttons) do
        local row = self.rows[(self.page - 1) * ROWS + index]; button.entry = row
        Place(button, 0, 184 + extra + (index - 1) * 48); button:SetShown(row ~= nil)
        if row then
            button.icon:SetTexture(row.icon); button.name:SetText(row.name)
            button.count:SetText("×" .. ((row.bags or 0) + (row.bank or 0) + (row.account or 0)))
            local location = row.account and "Shared bank" or row.bags and row.bank and "Bags + bank" or row.bags and "Bags" or "Bank"
            button.context:SetText(row.owner.name .. " · " .. location)
            local at, undated = nil, false
            for _, key in ipairs({ "bags", "bank", "account" }) do if row[key] then
                local stamp = row[key .. "At"]
                if not stamp then undated = true else at = at and math.min(at, stamp) or stamp end
            end end
            local age, stale = self:Age(not undated and at or nil)
            button.age:SetText(age); button.age:SetTextColor(unpack(stale and colors.stale or colors.muted))
            local quality = row.quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[row.quality]
            if Table(quality) and Suite.IsReadable(quality.r) and Suite.IsReadable(quality.g) and Suite.IsReadable(quality.b)
                and type(quality.r) == "number" and quality.r >= 0 and quality.r <= 1
                and type(quality.g) == "number" and quality.g >= 0 and quality.g <= 1
                and type(quality.b) == "number" and quality.b >= 0 and quality.b <= 1 then
                button.name:SetTextColor(quality.r, quality.g, quality.b)
            else button.name:SetTextColor(unpack(colors.text)) end
        end
    end
    Place(self.empty, 0, 192 + extra); self.empty:SetShown(#self.rows == 0)
    self.empty:SetText(not Suite.InventorySearch.region and "Character region unavailable."
        or self.pendingItems > 0 and "Item names are loading or unavailable. Search by item ID to find an uncached item."
        or self.owner and "No recorded items match this view. Unknown locations are not treated as empty."
        or "No recorded items match this view. Enable character recording, log into alts, and visit their banks.")
    local visibleRows = math.min(ROWS, #self.rows)
    local bottom = 184 + extra + math.max(2, visibleRows) * 48 + 8
    Place(self.previous, 0, bottom); Place(self.next, 690, bottom); Place(self.pageLabel, 100, bottom + 8)
    self.previous:SetEnabled(self.page > 1); self.next:SetEnabled(self.page < pages)
    self.pageLabel:SetText(self.page .. " / " .. pages)
    self.previous:SetShown(pages > 1); self.next:SetShown(pages > 1); self.pageLabel:SetShown(pages > 1)
    if pages > 1 then bottom = bottom + 38 end
    local guid, bankType = self:BankTarget()
    local available = guid ~= nil and Suite.OfflineBank:GetSnapshot(bankType, guid) ~= nil
    Place(self.bankButton, 0, bottom); self.bankButton:SetEnabled(available)
    self.bankButton.label:SetText(guid == "account" and "Open shared bank snapshot" or guid and "Open this character's bank" or "Select an owner for bank view")
    self.bankButton.label:SetTextColor(unpack(available and colors.teal or colors.muted))
    bottom = bottom + 39; Place(self.notice, 0, bottom)
    self.notice:SetText(self.message or (Suite.InventorySearch.limited and "Some results omitted. " or "")
        .. (self.pendingItems > 0 and self.pendingItems .. " item names loading/unavailable. " or "")
        .. "Snapshots can be stale. Log into alts and visit banks to refresh; no items can be moved here.")
    self.panel:SetHeight(bottom + 38)
    if more then self:Schedule() end
end
