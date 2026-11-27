local _, Suite = ...
local Browser = { query = "", page = 1 }
Suite.CharacterBrowser = Browser
local ROWS, MAX_FAVORITES = 8, 8
local FILTER_BUTTON_HEIGHT = 32
local colors = { teal = { 0.41, 0.84, 0.75 }, text = { 0.88, 0.91, 0.93 }, muted = { 0.55, 0.65, 0.7 },
    stale = { 0.95, 0.72, 0.38 }, row = { 0.07, 0.095, 0.11 } }
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
    return view.query:lower() .. "\031" .. (view.filters and view.filters.kind or "all")
        .. "\031" .. (view.filters and view.filters.quality or "all") .. "\031" .. (view.filters and view.filters.age or "all")
end
local function Label(parent, text, x, y, width, size, color)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", size or 11, ""); label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(width); label:SetJustifyH("LEFT"); label:SetWordWrap(false)
    label:SetTextColor(unpack(color or colors.text)); label:SetText(text)
    return label
end
local function Button(parent, text, x, y, width, callback, height)
    local button = Suite.Theme:ActionButton(parent, text, width, height or 28, function() if not InCombatLockdown() then callback() end end)
    button:SetPoint("TOPLEFT", x, y)
    return button
end

function Browser:InitializeOptions(saved)
    local options, seen = { schema = 1, favorites = {} }, {}
    if not Table(saved) or not Table(saved.favorites) then return options end
    for index = 1, MAX_FAVORITES do
        local entry = saved.favorites[index]
        if Table(entry) then
            local query = Query(entry.query)
            if query then
                local filters = Suite.InventorySearch:NormalizeFilters(entry.filters)
                local view = filters and { query = query, filters = filters, name = Text(entry.name, 40) and entry.name or nil }
                if view and not seen[Key(view)] then options.favorites[#options.favorites + 1], seen[Key(view)] = view, true end
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
function Browser:View() return { query = Query(self.query) or "",
    filters = Suite.InventorySearch:NormalizeFilters(self.filters) } end
function Browser:SetFilter(key, value)
    if InCombatLockdown() or not Text(key) or not Suite.InventorySearch.filterChoices[key] then return false end
    local filters = Suite.InventorySearch:NormalizeFilters(self.filters)
    filters[key] = value
    filters = Suite.InventorySearch:NormalizeFilters(filters)
    if not filters then return false end
    self.filters, self.page, self.message = filters, 1, nil; self:Update(); return true
end
function Browser:FilterMenu(button, key)
    if InCombatLockdown() then return end
    Suite.Menus.CreateContextMenu(button, function(_, root)
        for _, choice in ipairs(Suite.InventorySearch.filterChoices[key]) do
            local value = choice[1]
            root:CreateButton(choice[2], function() self:SetFilter(key, value) end)
        end
    end)
end
function Browser:RenameCategory()
    if InCombatLockdown() then return false end
    local index, name = self:FavoriteIndex(), self.categoryName and Query(Call(self.categoryName.GetText, self.categoryName))
    if not index or not Text(name, 40) then self.message = "Load a category and enter a name first."; self:Update(); return false end
    self:Options().favorites[index].name = name; self.message = "Category renamed."; self:Update(); return true
end
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
    else
        local view = self:View()
        local name = self.categoryName and Query(Call(self.categoryName.GetText, self.categoryName))
        view.name = Text(name, 40) and name or (view.query ~= "" and view.query:sub(1, 40) or Suite.InventorySearch:FilterLabel("kind", view.filters.kind))
        favorites[#favorites + 1] = view; self.message = "Category saved."
    end
    self:Update(); return success
end
function Browser:LoadView(index)
    if InCombatLockdown() or not Integer(index, 1, MAX_FAVORITES) then return false end
    local view = self:Options().favorites[index]
    if not view then return false end
    self.query = view.query
    self.filters = Suite.InventorySearch:NormalizeFilters(view.filters)
    if self.categoryName then self.categoryName:SetText(view.name or "") end
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
function Browser:Coverage()
    local search = Suite.InventorySearch
    if not search.region then return "Character region unavailable." end
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
function Browser:Open()
    if InCombatLockdown() then Suite.AfterCombat("guiOpen", function() self:Open() end); return end
    self.page = 1
    Suite.CharacterDashboard.view = "inventory"
    Suite.GUI:OpenPage("characters")
end
function Browser:ShowWowheadLink(row)
    if InCombatLockdown() or not self.visible or not Table(row) or not Integer(row.id, 1, 2147483647) then return end
    local open = self.wowheadFrame
    if open and open:IsShown() and open.itemID == row.id then open:Hide(); return end
    self:HideTooltip()
    if not self.wowheadFrame then
        local frame = CreateFrame("Frame", nil, Suite.GUI.frame, "BackdropTemplate")
        frame:SetSize(460, 104); frame:SetPoint("CENTER", UIParent, "CENTER")
        -- The settings window and its scroll descendants already use DIALOG.
        frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:EnableMouse(true)
        frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        frame:SetBackdropColor(0.035, 0.05, 0.065, 1); Suite.Theme:Backdrop(frame, 1)
        frame.title = Label(frame, "", 14, -12, 392, 14)
        Label(frame, "Press Ctrl+C to copy the Wowhead link.", 14, -38, 430, 11, colors.muted)
        Button(frame, "X", 416, -9, 30, function() frame:Hide() end, 25)
        local edit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        edit:SetPoint("TOPLEFT", 20, -64); edit:SetSize(418, 24)
        edit:SetFont("Fonts\\FRIZQT__.TTF", 12, ""); edit:SetAutoFocus(false)
        edit:SetScript("OnEscapePressed", function() frame:Hide() end)
        edit:SetScript("OnEnterPressed", function() frame:Hide() end)
        frame:SetScript("OnHide", function() edit:ClearFocus() end)
        frame.edit = edit
        self.wowheadFrame = frame
    end
    local frame = self.wowheadFrame
    frame.itemID = row.id
    frame.title:SetText(Text(row.name, 256) and row.name or ("Item " .. row.id))
    frame.edit:SetText(string.format("https://www.wowhead.com/forever/item=%d", row.id))
    frame:Show(); frame.edit:SetFocus(); frame.edit:HighlightText()
end
function Browser:ModifiedClick(row)
    if InCombatLockdown() or not row then return end
    if row.link and (Call(IsModifiedClick, "CHATLINK") == true or Call(IsModifiedClick, "DRESSUP") == true) then
        Call(HandleModifiedItemClick, row.link)
    end
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
    local filters = Suite.InventorySearch:NormalizeFilters(view.filters)
    for _, key in ipairs({ "kind", "quality", "age" }) do
        tip:AddLine(Suite.InventorySearch:FilterLabel(key, filters[key]), unpack(colors.muted))
    end
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
        if self.wowheadFrame then self.wowheadFrame:Hide() end
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
    if event == "PLAYER_REGEN_DISABLED" then
        self:Cancel(); self:HideTooltip()
        if self.wowheadFrame then self.wowheadFrame:Hide() end
    elseif event == "MODIFIER_STATE_CHANGED" then if self.hovered then self:Tooltip(self.hovered) end
    elseif event == "ITEM_DATA_LOAD_RESULT" then
        if Integer(id, 1, 2147483647) and Suite.InventorySearch.requested[id] then
            Suite.InventorySearch.metadata[id] = nil; self:Schedule()
        end
    else Suite.InventorySearch.index = nil; self:Schedule() end
end

function Browser:ClearSearch()
    if InCombatLockdown() or not self.visible then return end
    self.query, self.page, self.message = "", 1, nil
    self.search:ClearFocus()
    self:Cancel()
    self:Update()
end

function Browser:Build(parent)
    if self.panel then return self.panel end
    if InCombatLockdown() then return end
    local panel = CreateFrame("Frame", nil, parent); panel:SetSize(780, 620); self.panel = panel
    panel:SetPoint("TOPLEFT", 0, -40)
    panel:SetScript("OnEvent", function(_, ...) self:OnEvent(...) end)
    panel:SetScript("OnHide", function() self:SetVisible(false) end)
    local search = CreateFrame("EditBox", nil, panel, "BackdropTemplate"); self.search = search
    search:SetPoint("TOPLEFT", 0, 0); search:SetSize(686, 28); search:SetAutoFocus(false); search:SetMaxLetters(100)
    search:SetFont("Fonts\\FRIZQT__.TTF", 12, ""); search:SetTextInsets(8, 30, 0, 0)
    search:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    search:SetBackdropColor(unpack(colors.row)); Suite.Theme:Backdrop(search, 1)
    self.placeholder = Label(search, "Search item name, type, or item ID", 8, -8, 400, 11, colors.muted)
    search:SetScript("OnTextChanged", function(box)
        if self.updating then return end
        self.query, self.page, self.message = Query(Call(box.GetText, box)) or "", 1, nil
        self.placeholder:SetShown(self.query == ""); self:Schedule()
    end)
    search:SetScript("OnEscapePressed", function() self:ClearSearch() end)
    self.searchClear = Suite.Theme:IconButton(search, "Clear search", function() self:ClearSearch() end)
    self.searchClear:SetSize(25, 24); self.searchClear:SetPoint("RIGHT", -2, 0)
    search:SetScript("OnEnterPressed", function(box) box:ClearFocus(); self:Cancel(); self:Update() end)
    self.saveButton = Button(panel, "Save view", 692, 0, 88, function() self:SaveView() end)
    self.favoriteButton = Button(panel, "Saved searches", 0, -40, 384, function() self.expanded = not self.expanded; self:Update() end)
    self.favoriteHint = Label(panel, "", 0, -126, 780, 10, colors.muted)
    local name = CreateFrame("EditBox", nil, panel, "BackdropTemplate"); self.categoryName = name
    name:SetPoint("TOPLEFT", 396, -40); name:SetSize(278, 28); name:SetAutoFocus(false); name:SetMaxLetters(40)
    name:SetFont("Fonts\\FRIZQT__.TTF", 11, ""); name:SetTextInsets(8, 8, 0, 0)
    name:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    name:SetBackdropColor(unpack(colors.row)); Suite.Theme:Backdrop(name, 1)
    name:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
    name:SetScript("OnEnterPressed", function(box) box:ClearFocus(); self:RenameCategory() end)
    self.renameButton = Button(panel, "Rename", 686, -40, 94, function() self:RenameCategory() end)
    self.filterButtons = {}
    for index, key in ipairs({ "kind", "quality", "age" }) do
        local button
        button = Button(panel, "", (index - 1) * 198, -78, 186, function() self:FilterMenu(button, key) end, FILTER_BUTTON_HEIGHT)
        self.filterButtons[key] = button
    end
    self.clearButton = Button(panel, "Clear filters", 594, -78, 186, function()
        self.filters, self.query, self.page = nil, "", 1
        self.categoryName:SetText(""); self:Update()
    end, FILTER_BUTTON_HEIGHT)
    self.favoriteRows = {}
    for index = 1, MAX_FAVORITES do
        self.favoriteRows[index] = Button(panel, "", ((index - 1) % 2) * 396, -150 - math.floor((index - 1) / 2) * 34, 384,
            function() self:LoadView(index) end)
        local button = self.favoriteRows[index]
        button:SetScript("OnEnter", function() self:FavoriteTooltip(button) end)
        button:SetScript("OnLeave", function() if self.hovered == button then self:HideTooltip() end end)
    end
    self.coverage = Label(panel, "", 0, 0, 780, 10, colors.muted)
    self.summary = Label(panel, "", 0, 0, 780, 11)
    self.buttons = {}
    for index = 1, ROWS do
        local button
        button = Button(panel, "", 0, 0, 780, function() self:ModifiedClick(button.entry) end)
        button:SetHeight(44); button.label:Hide()
        button.icon = button:CreateTexture(nil, "ARTWORK"); button.icon:SetSize(28, 28); button.icon:SetPoint("TOPLEFT", 8, -8)
        button.name = Label(button, "", 44, -7, 454, 12)
        button.count = Label(button, "", 678, -7, 92, 12, colors.teal); button.count:SetJustifyH("RIGHT")
        button.context = Label(button, "", 44, -26, 454, 10, colors.muted)
        button.age = Label(button, "", 616, -26, 154, 10, colors.muted); button.age:SetJustifyH("RIGHT")
        button.wowhead = Button(button, "Wowhead", 510, -9, 98, function() self:ShowWowheadLink(button.entry) end, 26)
        button:SetScript("OnEnter", function() self:Tooltip(button) end)
        button:SetScript("OnLeave", function() if self.hovered == button then self:HideTooltip() end end)
        self.buttons[index] = button
    end
    self.empty = Label(panel, "", 0, 0, 780, 12, colors.muted); self.empty:SetHeight(52); self.empty:SetWordWrap(true)
    self.previous = Button(panel, "Previous", 0, 0, 90, function() self.page = math.max(1, self.page - 1); self:Update() end)
    self.next = Button(panel, "Next", 690, 0, 90, function() self.page = self.page + 1; self:Update() end)
    self.wheelArea = Suite.Theme:PageWheel(panel, self.buttons, self.previous, self.next, self.next)
    self.pageLabel = Label(panel, "", 100, 0, 580, 11, colors.muted); self.pageLabel:SetJustifyH("CENTER")
    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function(_, delta)
        if InCombatLockdown() or not Integer(delta, -100, 100) or delta == 0 then return end
        if Call(IsShiftKeyDown) == true then self.page = math.max(1, self.page - delta); self:Update()
        else Suite.GUI:ScrollTo((Suite.GUI.scrollOffset or 0) - delta * 40) end
    end)
    self.notice = Label(panel, "", 0, 0, 780, 10, colors.muted); self.notice:SetHeight(30); self.notice:SetWordWrap(true)
    return panel
end

function Browser:Refresh()
    if not self.panel or InCombatLockdown() then return end
    self:HideTooltip()
    local more
    self.rows, self.pendingItems, more = Suite.InventorySearch:Query(self.query, { browse = true, filters = self.filters })
    local favorites, selected = self:Options().favorites, self:FavoriteIndex()
    self.updating = true; self.search:SetText(self.query); self.updating = nil
    self.placeholder:SetShown(self.query == "")
    self.saveButton.label:SetText(selected and "Remove" or "Save")
    local filters = Suite.InventorySearch:NormalizeFilters(self.filters)
    for key, button in pairs(self.filterButtons) do button.label:SetText(Suite.InventorySearch:FilterLabel(key, filters[key])) end
    self.renameButton:SetEnabled(selected ~= nil)
    self.favoriteButton.label:SetText((self.expanded and "Hide" or "Saved") .. " categories (" .. #favorites .. ")")
    self.favoriteHint:SetText("Save the search and filters as a category. Load a category to rename or remove it.")
    local extra = 72 + (self.expanded and math.ceil(#favorites / 2) * 34 + 8 or 0)
    for index, button in ipairs(self.favoriteRows) do
        local view = favorites[index]
        button:SetShown(self.expanded and view ~= nil)
        button.view = view
        if view then button.label:SetText(view.name or (view.query ~= "" and view.query or "All items")) end
    end
    local function Place(widget, x, y) widget:ClearAllPoints(); widget:SetPoint("TOPLEFT", x, -y) end
    Place(self.coverage, 0, 82 + extra); self.coverage:SetText(self:Coverage())
    local total = 0
    for _, row in ipairs(self.rows) do total = total + (row.bags or 0) + (row.bank or 0) + (row.account or 0) end
    Place(self.summary, 0, 102 + extra)
    self.summary:SetText(#self.rows == 0 and self.pendingItems > 0 and "Searching recorded items · names loading/unavailable"
        or (#self.rows .. " results · " .. total .. " items recorded"))
    local pages = math.max(1, math.ceil(#self.rows / ROWS)); self.page = math.max(1, math.min(pages, self.page))
    for index, button in ipairs(self.buttons) do
        local row = self.rows[(self.page - 1) * ROWS + index]; button.entry = row
        Place(button, 0, 126 + extra + (index - 1) * 48); button:SetShown(row ~= nil)
        button.wowhead:SetShown(row ~= nil and Integer(row.id, 1, 2147483647))
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
    Place(self.empty, 0, 134 + extra); self.empty:SetShown(#self.rows == 0)
    self.empty:SetText(not Suite.InventorySearch.region and "Character region unavailable."
        or self.pendingItems > 0 and "Some item data is unavailable. Clear type/quality filters or search by item ID."
        or "No recorded items match this view. Enable character recording, log into alts, and visit their banks.")
    local visibleRows = math.min(ROWS, #self.rows)
    local bottom = 126 + extra + math.max(2, visibleRows) * 48 + 8
    Place(self.previous, 0, bottom); Place(self.next, 690, bottom); Place(self.pageLabel, 100, bottom + 8)
    self.previous:SetEnabled(self.page > 1); self.next:SetEnabled(self.page < pages)
    self.pageLabel:SetText(self.page .. " / " .. pages)
    self.previous:SetShown(pages > 1); self.next:SetShown(pages > 1); self.pageLabel:SetShown(pages > 1)
    if pages > 1 then bottom = bottom + 38 end
    Place(self.notice, 0, bottom)
    self.notice:SetText(self.message or (Suite.InventorySearch.limited and "Some results omitted. " or "")
        .. (self.pendingItems > 0 and self.pendingItems .. " items with unavailable name/filter data. " or "")
        .. "Snapshots can be stale. Log into alts and visit banks to refresh; no items can be moved here.")
    self.panel:SetHeight(bottom + 38)
    if more then self:Schedule() end
end
