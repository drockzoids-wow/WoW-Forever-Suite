local _, Suite = ...
local Search = { records = {}, requested = {}, metadata = {} }
Suite.InventorySearch = Search
table.insert(Suite.modules, Search)
local PAGE_SIZE, WIDTH, ROW_HEIGHT, SIDE_GAP = 4, 300, 28, 8
local MAX_ITEMS, MAX_ROWS, LOAD_BATCH = 20000, 40000, 32
local colors = { teal = { 0.41, 0.84, 0.75 }, text = { 0.88, 0.91, 0.93 }, muted = { 0.55, 0.65, 0.7 } }

local function Integer(value, low, high)
    return Suite.IsReadable(value) and type(value) == "number" and value >= low and value <= high
        and value == math.floor(value)
end
local function Text(value, limit)
    return Suite.IsReadable(value) and type(value) == "string" and #value > 0
        and #value <= (limit or 128) and not value:find("[%c|]")
end
local function Table(value) return Suite.IsReadable(value) and type(value) == "table" end
local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end
local function Read(object, method, ...)
    if not Suite.IsReadable(object) or not object or not Suite.IsReadable(object[method])
        or type(object[method]) ~= "function" then return end
    local ok, value = pcall(object[method], object, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Safe(frame)
    if not Suite.IsReadable(frame) or frame == nil or Read(frame, "IsForbidden") ~= false then return false end
    if type(frame.IsAnchoringRestricted) == "function" and Read(frame, "IsAnchoringRestricted") ~= false then return false end
    return true
end
local function Visible(frame) return Safe(frame) and Read(frame, "IsVisible") == true end
local function Link(value, id)
    return Suite.IsReadable(value) and type(value) == "string" and #value <= 4096
        and not value:find("%c") and tonumber(value:match("|Hitem:(%d+):")) == id
        and value:find("|h%[.-%]|h") ~= nil
end
local function Label(parent, size, color, point, x, y, width)
    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", size, "")
    text:SetTextColor(unpack(color)); text:SetJustifyH("LEFT"); text:SetWordWrap(false)
    text:SetPoint(point, x, y)
    if width then text:SetWidth(width) end
    return text
end
function Search:Enabled()
    return Suite.db and Suite.IsReadable(Suite.db.inventorySearch) and Suite.db.inventorySearch == true
end

function Search:Owner(character, guid)
    local name = Text(character.fullName) and character.fullName or character.name
    local context = character.realm
    -- Reuse known mail identities for old snapshots, without autocomplete or roster requests.
    local contacts = Suite.db.mailContacts
    local entries = Table(contacts) and contacts.entries
    if Table(entries) then
        local found, ambiguous
        for _, contact in pairs(entries) do
            if Table(contact) and Suite.IsReadable(contact.guid) and contact.guid == guid
                and Integer(contact.region, 1, 1000000) and contact.region == character.region and Text(contact.name, 77) then
                if found and found.name ~= contact.name then ambiguous = true; break end
                found = { name = contact.name, ruleset = Text(contact.ruleset) and contact.ruleset or nil }
            end
        end
        if found and not ambiguous then
            if not Text(character.fullName) then name = found.name end
            context = found.ruleset or context
        end
    end
    return { name = name, context = context, guid = guid, current = guid == self.currentGUID }
end

function Search:BuildIndex()
    self.index, self.ids, self.limited = {}, {}, false
    local region = GetCurrentRegion and GetCurrentRegion()
    local guid = UnitGUID and UnitGUID("player")
    self.currentGUID, self.region = Text(guid) and guid or nil, nil
    if not Integer(region, 1, 1000000) then return end
    self.region = region
    local db, rowCount, itemCount = Suite.Inventory:Database(), 0, 0
    local function Add(snapshot, owner, location)
        if not Table(snapshot) or not Table(snapshot.items) then return end
        local at = Integer(snapshot.at, 1, 10000000000) and snapshot.at or nil
        for id, count in pairs(snapshot.items) do
            if Integer(id, 1, 2147483647) and Integer(count, 1, 1000000000) then
                if rowCount >= MAX_ROWS or (not self.index[id] and itemCount >= MAX_ITEMS) then self.limited = true; return end
                if not self.index[id] then
                    self.index[id] = {}; self.ids[#self.ids + 1] = id; itemCount = itemCount + 1
                end
                local row = self.index[id][owner.guid]
                if not row then
                    row = { id = id, owner = owner }; self.index[id][owner.guid] = row; rowCount = rowCount + 1
                end
                row[location], row[location .. "At"] = count, at
            end
        end
    end
    if Table(db.characters) then
        for key, character in pairs(db.characters) do
            if Text(key) and Table(character) and Text(character.name) and Text(character.realm)
                and Integer(character.region, 1, 1000000) and character.region == region then
                local owner = self:Owner(character, key)
                Add(character.bags, owner, "bags"); Add(character.bank, owner, "bank")
            end
        end
    end
    if Table(db.accountBanks) then
        Add(db.accountBanks[region], { name = "Warband", context = "Shared bank", guid = "account", current = false }, "account")
    end
    table.sort(self.ids)
end

function Search:Item(id)
    if self.metadata[id] then return self.metadata[id] end
    if not C_Item or type(C_Item.GetItemInfo) ~= "function" then return end
    local ok, name, link, quality, _, _, kind, subtype, _, equip, icon = pcall(C_Item.GetItemInfo, id)
    if not ok or not Text(name, 512) then return end
    local words = name
    if Text(kind) then words = words .. " " .. kind end
    if Text(subtype) then words = words .. " " .. subtype end
    if Text(equip) and Text(_G[equip]) then words = words .. " " .. _G[equip] end
    local item = { name = name, words = words:lower(), link = Link(link, id) and link or nil,
        icon = Integer(icon, 1, 2147483647) and icon or "Interface\\Icons\\INV_Misc_QuestionMark",
        quality = Integer(quality, 0, 8) and quality or nil }
    self.metadata[id] = item
    return item
end

function Search:Query(query)
    if InCombatLockdown() or not Text(query, 100) then return {}, 0, false end
    query = query:match("^%s*(.-)%s*$"):lower()
    if query == "" then return {}, 0, false end
    local region = GetCurrentRegion and GetCurrentRegion()
    local guid = UnitGUID and UnitGUID("player")
    if not Integer(region, 1, 1000000) then self.index = nil; return {}, 0, false end
    guid = Text(guid) and guid or nil
    if not self.index or region ~= self.region or guid ~= self.currentGUID then self:BuildIndex() end
    local rows, pending, loads, more, tokens = {}, 0, 0, false, {}
    for token in query:gmatch("%S+") do tokens[#tokens + 1] = token end
    for _, id in ipairs(self.ids) do
        local item = self:Item(id)
        if not item then
            pending = pending + 1
            if not self.requested[id] and C_Item and type(C_Item.RequestLoadItemDataByID) == "function" then
                if loads < LOAD_BATCH then
                    self.requested[id] = true; loads = loads + 1; pcall(C_Item.RequestLoadItemDataByID, id)
                else more = true end
            end
        end
        local matches = tostring(id) == query
        if item and not matches then
            matches = true
            for _, token in ipairs(tokens) do if not item.words:find(token, 1, true) then matches = false; break end end
        end
        if matches then
            for _, saved in pairs(self.index[id]) do
                rows[#rows + 1] = { id = id, owner = saved.owner, bags = saved.bags, bank = saved.bank, account = saved.account,
                    bagsAt = saved.bagsAt, bankAt = saved.bankAt, accountAt = saved.accountAt,
                    name = item and item.name or ("Item " .. id), icon = item and item.icon or "Interface\\Icons\\INV_Misc_QuestionMark",
                    link = item and item.link, quality = item and item.quality }
            end
        end
    end
    table.sort(rows, function(a, b)
        if a.name:lower() ~= b.name:lower() then return a.name:lower() < b.name:lower() end
        if a.id ~= b.id then return a.id < b.id end
        if a.owner.current ~= b.owner.current then return a.owner.current end
        if a.owner.name ~= b.owner.name then return a.owner.name < b.owner.name end
        if a.owner.context ~= b.owner.context then return a.owner.context < b.owner.context end
        return a.owner.guid < b.owner.guid
    end)
    return rows, pending, more
end

function Search:Counts(row)
    local parts = {}
    if row.bags then parts[#parts + 1] = "Bags: " .. row.bags end
    if row.bank then parts[#parts + 1] = "Bank: " .. row.bank end
    if row.account then parts[#parts + 1] = "Bank: " .. row.account end
    return table.concat(parts, "  ·  ")
end
function Search:HideTooltip()
    if self.hovered and Safe(GameTooltip) and Read(GameTooltip, "GetOwner") == self.hovered
        and (not InCombatLockdown() or Read(GameTooltip, "IsProtected") == false) then
        GameTooltip:Hide()
    end
    self.hovered = nil
end
function Search:Tooltip(button)
    if InCombatLockdown() or not self:Enabled() or not button.entry or not Safe(GameTooltip) then return end
    local row = button.entry
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT"); self.hovered = button
    if row.link and type(GameTooltip.SetHyperlink) == "function" then GameTooltip:SetHyperlink(row.link)
    else GameTooltip:AddLine(row.name) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(row.owner.name .. (row.owner.current and " (You)" or ""), unpack(colors.teal))
    GameTooltip:AddLine(row.owner.context, unpack(colors.muted)); GameTooltip:AddLine(self:Counts(row))
    for _, key in ipairs({ "bags", "bank", "account" }) do
        if row[key] then
            local at = row[key .. "At"]
            local stamp = at and date and date("%b %d, %H:%M", at) or "Date unavailable"
            GameTooltip:AddLine((key == "bags" and "Bags recorded: " or "Bank recorded: ") .. stamp, unpack(colors.muted))
        end
    end
    GameTooltip:AddLine("Recorded counts; item variants are combined.", unpack(colors.muted))
    GameTooltip:AddLine("Log into alts and visit banks to update their records.", unpack(colors.muted)); GameTooltip:Show()
end

function Search:CreatePopup()
    if self.popup then return true end
    if InCombatLockdown() then return false end
    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    self.popup, self.buttons = popup, {}
    popup:Hide(); popup:SetSize(WIDTH, 28); popup:SetFrameStrata("DIALOG")
    popup:SetClampedToScreen(true); popup:EnableMouse(true); popup:EnableMouseWheel(true)
    popup:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    popup:SetBackdropColor(0.035, 0.05, 0.065, 0.97); popup:SetBackdropBorderColor(0.2, 0.35, 0.36, 0.8)
    popup:SetScript("OnHide", function() self:HideTooltip() end)
    popup:SetScript("OnMouseWheel", function(_, delta)
        if not InCombatLockdown() and Integer(delta, -100, 100) and delta ~= 0 then self:Page(delta > 0 and -1 or 1) end
    end)
    local close = CreateFrame("Button", nil, popup); self.close = close
    close:SetSize(22, 22); close:SetPoint("TOPRIGHT", -2, -2)
    Label(close, 13, colors.muted, "CENTER", 0, 0):SetText("×")
    close:SetScript("OnClick", function() self:Dismiss() end)
    self.empty = Label(popup, 11, colors.muted, "TOPLEFT", 8, -8, WIDTH - 38)
    self.notice = Label(popup, 10, colors.muted, "BOTTOMLEFT", 8, 6, WIDTH - 105)
    self.previous = CreateFrame("Button", nil, popup)
    self.previous:SetSize(20, 20); self.previous:SetPoint("BOTTOMRIGHT", -68, 0)
    Label(self.previous, 14, colors.teal, "CENTER", 0, 0):SetText("‹")
    self.previous:SetScript("OnClick", function() self:Page(-1) end)
    self.next = CreateFrame("Button", nil, popup)
    self.next:SetSize(20, 20); self.next:SetPoint("BOTTOMRIGHT", -4, 0)
    Label(self.next, 14, colors.teal, "CENTER", 0, 0):SetText("›")
    self.next:SetScript("OnClick", function() self:Page(1) end)
    self.pageLabel = Label(popup, 10, colors.text, "BOTTOMRIGHT", -24, 6, 44); self.pageLabel:SetJustifyH("CENTER")
    for index = 1, PAGE_SIZE do
        local button = CreateFrame("Button", nil, popup); self.buttons[index] = button
        -- Reserve the close button's column so it never competes with a result hit area.
        button:SetSize(WIDTH - 32, ROW_HEIGHT); button:SetPoint("TOPLEFT", 4, -4 - (index - 1) * ROW_HEIGHT)
        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints(button); highlight:SetColorTexture(0.41, 0.84, 0.75, 0.10)
        button.icon = button:CreateTexture(nil, "ARTWORK"); button.icon:SetSize(20, 20); button.icon:SetPoint("LEFT", 1, 0)
        button.name = Label(button, 11, colors.text, "TOPLEFT", 27, -2, WIDTH - 65)
        button.owner = Label(button, 10, colors.teal, "TOPLEFT", 27, -15, WIDTH - 65)
        button:SetScript("OnEnter", function() self:Tooltip(button) end)
        button:SetScript("OnLeave", function() if self.hovered == button then self:HideTooltip() end end)
        button:SetScript("OnHide", function() if self.hovered == button then self:HideTooltip() end end)
        button:RegisterForClicks("LeftButtonUp")
        button:SetScript("OnClick", function()
            local row = button.entry
            if not InCombatLockdown() and self:Enabled() and row and row.link and IsModifiedClick and HandleModifiedItemClick then
                local chat, dress = IsModifiedClick("CHATLINK"), IsModifiedClick("DRESSUP")
                if (Suite.IsReadable(chat) and chat == true) or (Suite.IsReadable(dress) and dress == true) then
                    HandleModifiedItemClick(row.link)
                end
            end
        end)
    end
    return true
end
function Search:Cancel() if self.timer then self.timer:Cancel(); self.timer = nil end end
function Search:Dismiss()
    self:Cancel(); self:HideTooltip(); self.owner, self.query, self.rows, self.page = nil, nil, nil, 1
    if Safe(self.popup) then
        if InCombatLockdown() and Read(self.popup, "IsProtected") ~= false then
            Suite.pending.inventorySearchHide = function() if not self.owner and Safe(self.popup) then self.popup:Hide() end end
        else self.popup:Hide() end
    end
end
function Search:Page(delta)
    if InCombatLockdown() or not self.rows then return end
    local pages = math.max(1, math.ceil(#self.rows / PAGE_SIZE))
    self.page = math.max(1, math.min(pages, (self.page or 1) + delta)); self:Render()
end
function Search:PlacePopup()
    if InCombatLockdown() or not self:Enabled() or not Visible(self.owner) or not Safe(self.popup) then return false end
    -- Blizzard reparents the shared search field between backpack and combined bags.
    -- Resolve its current window each time; do not retain the old search-field anchor.
    local window = Read(self.owner, "GetParent")
    if window == UIParent or not Visible(window) then return false end
    local x, name = nil, Read(window, "GetName")
    local positions = Suite.db.windowPositions
    if Suite.IsReadable(Suite.db.windowTools) and Suite.db.windowTools == true and Table(positions) and Text(name) then
        local saved = positions[name]
        if Table(saved) and Number(saved.x) and Number(saved.y) and Number(saved.scale) and saved.scale > 0 then x = saved.x end
    end
    if x == nil then
        -- Frame coordinates use that frame's effective scale; compare in UIParent units.
        local center, scale = Read(window, "GetCenter"), Read(window, "GetEffectiveScale")
        local rootScale, width = Read(UIParent, "GetEffectiveScale"), Read(UIParent, "GetWidth")
        if not Number(center) or not Number(scale) or scale <= 0 or not Number(rootScale) or rootScale <= 0
            or not Number(width) or width <= 0 then return false end
        x = center * (scale / rootScale) - width / 2
        if not Number(x) then return false end
    end
    self:Attach(self.owner)
    self.popup:ClearAllPoints()
    if x >= 0 then self.popup:SetPoint("TOPRIGHT", window, "TOPLEFT", -SIDE_GAP, 0)
    else self.popup:SetPoint("TOPLEFT", window, "TOPRIGHT", SIDE_GAP, 0) end
    local level = Read(window, "GetFrameLevel")
    if Integer(level, 0, 10000) then self.popup:SetFrameLevel(math.min(10020, level + 20)) end
    return true
end
function Search:WindowChanged(window)
    if InCombatLockdown() or not self.owner or Read(self.owner, "GetParent") ~= window or not Visible(self.popup) then return end
    if not self:PlacePopup() then self:Dismiss() end
end
function Search:Render()
    if InCombatLockdown() or not self.owner or not Visible(self.owner) or not self:CreatePopup() then return end
    self:HideTooltip()
    local popup, rows = self.popup, self.rows or {}
    if not self:PlacePopup() then self:Dismiss(); return end
    local pages = math.max(1, math.ceil(#rows / PAGE_SIZE))
    self.page = math.max(1, math.min(pages, self.page or 1))
    local count = math.min(PAGE_SIZE, #rows - (self.page - 1) * PAGE_SIZE)
    local pending = (self.pendingItems or 0) > 0
    local notice = self.limited and "Some results omitted" or pending and "Names loading/unavailable" or nil
    local width = count == 0 and (pending and 240 or 180) or WIDTH
    popup:SetWidth(width)
    popup:SetHeight(count == 0 and 28 or (8 + count * ROW_HEIGHT + ((pages > 1 or notice) and 20 or 0)))
    for index, button in ipairs(self.buttons) do
        local row = rows[(self.page - 1) * PAGE_SIZE + index]; button.entry = row
        if row then
            button.icon:SetTexture(row.icon); button.name:SetText(row.name)
            button.owner:SetText(row.owner.name .. (row.owner.current and " (You)" or ""))
        end
        button:SetShown(row ~= nil)
    end
    self.empty:SetWidth(width - 38); self.empty:SetShown(count == 0)
    self.empty:SetText(pending and "Names loading/unavailable" or self.limited and "No matches (partial)" or "No matches")
    self.notice:SetText(notice or ""); self.notice:SetShown(count > 0 and notice ~= nil)
    self.previous:SetEnabled(self.page > 1); self.next:SetEnabled(self.page < pages)
    self.pageLabel:SetText(self.page .. "/" .. pages)
    self.previous:SetShown(pages > 1); self.next:SetShown(pages > 1); self.pageLabel:SetShown(pages > 1); popup:Show()
end
function Search:Refresh()
    if not self:Enabled() or InCombatLockdown() or not self.owner or not Visible(self.owner) then self:Dismiss(); return end
    local text = Read(self.owner, "GetText")
    if not Text(text, 100) or text:match("^%s*$") then self:Dismiss(); return end
    if self.query ~= text then self.query, self.page = text, 1 end
    local more
    self.rows, self.pendingItems, more = self:Query(text); self:Render()
    -- Finite batches of unrequested metadata only. Failed or unanswered loads never poll/retry.
    if more then self:Schedule() end
end
function Search:Schedule()
    if not self:Enabled() or InCombatLockdown() or not self.owner or self.timer or self.shuttingDown
        or not C_Timer or not C_Timer.NewTimer then return end
    self.timer = C_Timer.NewTimer(0.12, function() self.timer = nil; self:Refresh() end)
end
function Search:InventoryChanged() self.index = nil; if self.owner then self:Schedule() end end
function Search:FromBox(box, takeFocus)
    if not self:Enabled() or InCombatLockdown() then return end
    if takeFocus or Read(box, "HasFocus") == true then
        if not Visible(box) then return end
        if self.owner ~= box then self:Dismiss(); self.owner = box end
        local text = Read(box, "GetText")
        if not Text(text, 100) or text:match("^%s*$") then self:Dismiss(); return end
        if text ~= self.query and self.popup then self:HideTooltip(); self.popup:Hide() end
        self:Schedule()
    elseif self.owner == box then
        local text = Read(box, "GetText")
        if not Text(text, 100) or text:match("^%s*$") then self:Dismiss() else self:Schedule() end
    end
end
function Search:Attach(box)
    if InCombatLockdown() or not self:Enabled() or not Safe(box) or type(box.HookScript) ~= "function" then return end
    local record = self.records[box] or {}; self.records[box] = record
    local function Hook(script, callback)
        if not record[script] and Read(box, "HasScript", script) == true then
            local permitted = false
            local ok, success = pcall(box.HookScript, box, script, function(...)
                if permitted then callback(...) end
            end)
            if ok and Suite.IsReadable(success) and success == true then
                permitted, record[script] = true, true
            elseif ok and (not Suite.IsReadable(success) or success ~= false) then
                -- An unknown outcome cannot justify active callbacks or duplicate installation.
                record[script] = "unknown"
            end
        end
    end
    Hook("OnTextChanged", function() self:FromBox(box, false) end)
    Hook("OnEditFocusGained", function() self:FromBox(box, true) end)
    Hook("OnShow", function() self:FromBox(box, false) end)
    Hook("OnHide", function() if self.owner == box then self:Dismiss() end end)
    Hook("OnEscapePressed", function() if self.owner == box then self:Dismiss() end end)
    Hook("OnEnterPressed", function() if self.owner == box then self:Dismiss() end end)
    local parent = Read(box, "GetParent")
    record.parents = record.parents or {}
    if Safe(parent) and type(parent.HookScript) == "function" and not record.parents[parent] then
        local permitted = false
        local ok, success = pcall(parent.HookScript, parent, "OnHide", function()
            if permitted and self.owner == box and not Visible(box) then self:Dismiss() end
        end)
        if ok and Suite.IsReadable(success) and success == true then
            permitted, record.parents[parent] = true, true
        elseif ok and (not Suite.IsReadable(success) or success ~= false) then record.parents[parent] = "unknown" end
    end
end
function Search:Discover()
    if not self:Enabled() then return end
    if InCombatLockdown() then Suite.pending.inventorySearchDiscover = function() self:Discover() end; return end
    self:Attach(BagItemSearchBox); self:Attach(BankItemSearchBox)
    if Safe(BankFrame) then self:Attach(BankFrame.BankItemSearchBox) end
    if Suite.OfflineBank then self:Attach(Suite.OfflineBank.search) end
end
function Search:OnEvent(event, id)
    if not self:Enabled() then return end
    if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_LOGOUT" then
        if event == "PLAYER_LOGOUT" then self.shuttingDown = true end
        self:Dismiss()
    elseif event == "GLOBAL_MOUSE_DOWN" then
        if self.owner and Read(self.owner, "IsMouseOver") ~= true and Read(self.popup, "IsMouseOver") ~= true then self:Dismiss() end
    elseif event == "ITEM_DATA_LOAD_RESULT" then
        if Integer(id, 1, 2147483647) and self.requested[id] then self.metadata[id] = nil; self:Schedule() end
    else
        if event == "PLAYER_ENTERING_WORLD" then self.shuttingDown = nil; self:InventoryChanged() end
        self:Discover()
    end
end
function Search:Apply()
    if not self:Enabled() then
        self:Dismiss(); self.index = nil; Suite.pending.inventorySearchEnable, Suite.pending.inventorySearchDiscover = nil, nil
        if self.events then self.events:UnregisterAllEvents() end
        self.active = nil; return
    end
    Suite.AfterCombat("inventorySearchEnable", function()
        if not self:Enabled() then return end
        if not self.active then
            if not self.events then
                self.events = CreateFrame("Frame"); self.events:SetScript("OnEvent", function(_, ...) self:OnEvent(...) end)
            end
            for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED",
                "PLAYER_REGEN_ENABLED", "ITEM_DATA_LOAD_RESULT", "GLOBAL_MOUSE_DOWN", "PLAYER_LOGOUT" }) do
                local valid = true
                if C_EventUtils and type(C_EventUtils.IsEventValid) == "function" then
                    local ok, value = pcall(C_EventUtils.IsEventValid, event); valid = ok and Suite.IsReadable(value) and value == true
                end
                if valid then pcall(self.events.RegisterEvent, self.events, event) end
            end
            self.active, self.shuttingDown = true, nil
        end
        self:Discover()
    end)
end
