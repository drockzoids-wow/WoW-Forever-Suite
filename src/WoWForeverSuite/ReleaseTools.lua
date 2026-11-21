local _, Suite = ...
local Supplies, Expiry = { page = 1 }, { page = 1 }
Suite.SupplyChecklist, Suite.MailExpiry = Supplies, Expiry
table.insert(Suite.modules, Supplies)
table.insert(Suite.modules, Expiry)
local ROW_STEP = 44
local MAIL_WIDTH, MAIL_ROW_TOP, MAIL_ROW_STEP, MAIL_FOOTER, MAIL_COUNT_WIDTH = 440, 93, 40, 76, 68
local function Read(v, kind) return Suite.IsReadable(v) and type(v) == kind end
local function Number(v, low, high) return Read(v, "number") and v >= low and v <= high and v == v end
local function Integer(v, low, high) return Number(v, low, high) and v % 1 == 0 end
local function Text(v, limit) return Read(v, "string") and #v > 0 and #v <= limit and not v:find("[%c|]") end
local function Call(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Label(parent, x, y, width, size)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE")
    label:SetTextColor(0.88, 0.91, 0.93); label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(width); label:SetJustifyH("LEFT"); return label
end
local function Surface(frame)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.035, 0.05, 0.065, 1); Suite.Theme:Backdrop(frame, 0.75)
end
local function Button(parent, text, x, y, width, callback)
    local button = Suite.Theme:ActionButton(parent, text, width, 26, function() if not InCombatLockdown() then callback() end end)
    button:SetPoint("TOPLEFT", x, y)

    return button
end
local function Window(owner, name, title)
    local mail = owner == Expiry
    local width = mail and MAIL_WIDTH or 620
    local rowWidth = width - 28
    local rowTop = mail and MAIL_ROW_TOP or 104
    local rowStep = mail and MAIL_ROW_STEP or ROW_STEP
    local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate"); Surface(frame)
    frame:SetSize(width, mail and MAIL_ROW_TOP + MAIL_ROW_STEP + MAIL_FOOTER or 580)
    frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true); frame:EnableMouse(true)
    if UISpecialFrames then table.insert(UISpecialFrames, name) end
    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT"); header:SetSize(width - 46, 38)
    Label(header, 14, -11, width - 75, 17):SetText(title)
    Suite.BindWindowDrag(frame, header)
    local close = Suite.Theme:IconButton(frame, "Close " .. title, function() frame:Hide() end)
    close:SetSize(26, 26); close:SetPoint("TOPRIGHT", -8, -6)
    frame.context = Label(frame, 14, mail and -34 or -48, rowWidth, 11)
    frame.context:SetHeight(mail and 26 or 46)
    frame.status = Label(frame, 14, -503, rowWidth, 11); frame.status:SetHeight(30)
    frame.rows = {}
    for index = 1, 8 do
        local row = Button(frame, "", 14, -rowTop - (index - 1) * rowStep, rowWidth, function()
            if owner == Supplies and Suite.Items:ModifiedClick(frame.rows[index].supplyID, "LeftButton") then return end
            if owner.Select then owner:Select(index + (owner.page - 1) * 8) end
        end)
        row:SetHeight(rowStep - 4); row.label:SetJustifyH("LEFT"); row.label:SetWidth(rowWidth - 14)
        row.detail = Label(row, 5, -23, rowWidth - 14, 10)
        row.detail:SetWordWrap(false); row.detail:SetHeight(12)
        frame.rows[index] = row
    end
    frame.previous = Button(frame, "Previous", 14, -544, mail and 80 or 90, function() owner.page = owner.page - 1; owner:Refresh() end)
    frame.next = Button(frame, "Next", 112, -544, mail and 68 or 90, function() owner.page = owner.page + 1; owner:Refresh() end)
    frame.page = Label(frame, 218, -550, mail and 42 or 90)
    if mail then
        frame.context:SetJustifyV("MIDDLE")
        frame.status:ClearAllPoints(); frame.status:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 14, 66)
        frame.status:SetHeight(26); frame.status:SetJustifyV("TOP"); frame.status:SetWordWrap(true)
        frame.previous:ClearAllPoints(); frame.previous:SetPoint("BOTTOMLEFT", 14, 10)
        frame.next:ClearAllPoints(); frame.next:SetPoint("BOTTOMLEFT", 102, 10)
        frame.page:ClearAllPoints(); frame.page:SetPoint("BOTTOMLEFT", 180, 10)
        frame.page:SetHeight(26); frame.page:SetJustifyH("CENTER"); frame.page:SetJustifyV("MIDDLE")
    end
    frame.wheelArea = Suite.Theme:PageWheel(frame, frame.rows, frame.previous, frame.next, frame.next)
    frame:SetScript("OnHide", function()
        owner.confirmRemove = nil
        frame:UnregisterAllEvents()
        if owner.OnHide then owner:OnHide() end
    end)
    frame:SetScript("OnShow", function() frame:RegisterEvent("PLAYER_REGEN_DISABLED"); frame:RegisterEvent("PLAYER_REGEN_ENABLED") end)
    frame:SetScript("OnEvent", function()
        if owner.CancelRefresh then owner:CancelRefresh() end
        owner:Refresh()
    end)
    frame:Hide(); owner.frame = frame; return frame
end
local function Paging(owner, rows)
    local frame = owner.frame
    owner.page = math.max(1, math.min(owner.page, math.max(1, math.ceil(#rows / 8))))
    frame.page:SetText(owner.page .. " / " .. math.max(1, math.ceil(#rows / 8)))
    frame.previous:SetEnabled(owner.page > 1 and not InCombatLockdown())
    frame.next:SetEnabled(owner.page * 8 < #rows and not InCombatLockdown())
    for index, widget in ipairs(frame.rows) do
        local row = rows[index + (owner.page - 1) * 8]
        widget:SetShown(row ~= nil); widget:SetEnabled(not InCombatLockdown())
        if row then
            widget.label:SetText(row.title); widget.detail:SetText(row.detail or "")
            if widget.mailCount then widget.mailCount:SetText(row.mailCount) end
        end
    end
end

function Supplies:InitializeCharacter(saved)
    local result = { entries = {} }
    if Read(saved, "table") and Read(saved.entries, "table") then
        local seen = {}
        for index = 1, math.min(#saved.entries, 32) do
            local entry = saved.entries[index]
            if Read(entry, "table") and Integer(entry.id, 1, 2147483647) and Integer(entry.wanted, 1, 100000)
                and not seen[entry.id] then
                result.entries[#result.entries + 1] = { id = entry.id, wanted = entry.wanted,
                    automatic = Read(entry.automatic, "boolean") and entry.automatic or nil }
                seen[entry.id] = true
            end
        end
    end
    result.professionPlans = Suite.ShoppingList:Normalize(Read(saved, "table") and saved.professionPlans or nil)
    self.db = result; return result
end
function Supplies:Enabled() return Suite.db and Suite.IsReadable(Suite.db.supplyChecklist) and Suite.db.supplyChecklist == true end
function Supplies:Save(id, wanted)
    if InCombatLockdown() then return false, "Try again outside combat." end
    if not Integer(id, 1, 2147483647) or not Integer(wanted, 1, 100000) then return false, "Enter an item ID or item link, and a quantity from 1 to 100000." end
    if not self.db then self:InitializeCharacter(nil) end
    for _, entry in ipairs(self.db.entries) do
        if entry.id == id then entry.wanted = wanted; return true end
    end
    if #self.db.entries >= 32 then return false, "The checklist holds up to 32 items." end
    self.db.entries[#self.db.entries + 1] = { id = id, wanted = wanted }; return true
end
function Supplies:Remove(id)
    if InCombatLockdown() or not Integer(id, 1, 2147483647) or not self.db then return false end
    for index, entry in ipairs(self.db.entries) do
        if entry.id == id then table.remove(self.db.entries, index); return true end
    end
    return false
end
function Supplies:Counts()
    if not self:Enabled() or InCombatLockdown() then return end
    local maximum = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS
    if not Integer(maximum, 0, 5) then return end
    local ids = {}; for bag = 0, maximum do ids[#ids + 1] = bag end
    local ok, snapshot = pcall(Suite.Inventory.ScanContainers, Suite.Inventory, ids, false)
    if ok and Read(snapshot, "table") then return snapshot.items end
end
function Supplies:Rows(counts)
    local rows = {}
    for _, entry in ipairs(self.db and self.db.entries or {}) do
        local name = Call(C_Item and C_Item.GetItemNameByID, entry.id)
        local count = counts and counts[entry.id] or counts and 0
        rows[#rows + 1] = { id = entry.id, wanted = entry.wanted, count = count,
            title = (Text(name, 240) and name or "Item " .. entry.id) .. " · target " .. entry.wanted,
            detail = count and ("Carried: " .. count .. " · " .. (count < entry.wanted and "Need " .. entry.wanted - count or "Stocked"))
                or "Carried quantity unavailable; no shortage assumed." }
        if not name and self.frame and self.frame:IsShown() and not InCombatLockdown() then
            self.requested = self.requested or {}
            if not self.requested[entry.id] then self.requested[entry.id] = true; Call(C_Item and C_Item.RequestLoadItemDataByID, entry.id) end
        end
    end
    if Suite.ShoppingList then
        for _, row in ipairs(Suite.ShoppingList:Rows()) do row.profession = true; rows[#rows + 1] = row end
    end
    return rows
end
function Supplies:Select(index)
    local row = self.db.entries[index]
    if not row then
        self.frame.item:SetText(""); self.frame.quantity:SetText("")
        Suite.ShoppingList:Open(self.frame); return
    end
    self.confirmRemove = nil; self.frame.item:SetText(tostring(row.id)); self.frame.quantity:SetText(tostring(row.wanted))
    self.frame.remove.label:SetText("Remove item")
end
local function SafeTooltip(tip)
    if not Suite.IsReadable(tip) or (type(tip) ~= "table" and type(tip) ~= "userdata") then return false end
    for _, method in ipairs({ "IsForbidden", "SetOwner", "SetItemByID", "Show", "Hide", "IsOwned", "GetOwner" }) do
        if not Suite.IsReadable(tip[method]) then return false end
    end
    if type(tip.IsForbidden) == "function" and Call(tip.IsForbidden, tip) ~= false then return false end
    return true
end
local function OwnsTooltip(tip, row)
    if not SafeTooltip(tip) then return false end
    if type(tip.IsOwned) == "function" then return Call(tip.IsOwned, tip, row) == true end
    return type(tip.GetOwner) == "function" and Call(tip.GetOwner, tip) == row
end
function Supplies:HideTooltip()
    local tip, row = self.tooltip, self.hovered
    self.tooltip, self.hovered = nil, nil
    if row and OwnsTooltip(tip, row) and type(tip.Hide) == "function" then pcall(tip.Hide, tip) end
end
function Supplies:ItemTooltip(row)
    self:HideTooltip()
    if InCombatLockdown() or not self.frame or not self.frame:IsShown() or not row:IsShown()
        or not Integer(row.supplyID, 1, 2147483647) then return end
    local tip = GameTooltip
    if not SafeTooltip(tip) or type(tip.SetOwner) ~= "function" or type(tip.SetItemByID) ~= "function"
        or type(tip.Show) ~= "function" or type(tip.Hide) ~= "function"
        or (type(tip.IsOwned) ~= "function" and type(tip.GetOwner) ~= "function") then return end
    self.tooltip, self.hovered = tip, row
    if not pcall(tip.SetOwner, tip, row, "ANCHOR_RIGHT") then self:HideTooltip(); return end
    if not OwnsTooltip(tip, row) or not pcall(tip.SetItemByID, tip, row.supplyID) or not OwnsTooltip(tip, row) then self:HideTooltip(); return end
    if not pcall(tip.Show, tip) then self:HideTooltip() end
end
function Supplies:Refresh()
    self:CancelRefresh()
    local hovered = self.hovered
    self:HideTooltip()
    if not self.frame or not self.frame:IsShown() then return end
    self.rows = self:Rows(self:Counts()); Paging(self, self.rows)
    for index, widget in ipairs(self.frame.rows) do
        local row = self.rows[index + (self.page - 1) * 8]
        widget.supplyID = row and row.id or nil
        if row then Suite.Items:SetListIcon(widget.icon, row.id) end
    end
    if not InCombatLockdown() and hovered and Call(MouseIsOver, hovered) == true then self:ItemTooltip(hovered) end
    self.frame.context:SetText("Manual targets count carried bags. Profession plans count all recorded characters and banks.\nClick a profession row to open its shopping list. Targets belong to this character.")
    self.frame.status:SetText(InCombatLockdown() and "Paused in combat. Retry after combat."
        or not self:Enabled() and "Tracking is off. Enable it in Supply Checklist settings to count carried items."
        or #self.rows == 0 and "Your checklist is empty. Add an item below." or "Select an item to change its target or remove it. No items are bought or used.")
    for _, widget in ipairs({ self.frame.save, self.frame.remove }) do widget:SetEnabled(not InCombatLockdown()) end
end
local function ItemInput(value)
    if not Read(value, "string") or #value > 512 then return end
    local id = value:match("^%s*(%d+)%s*$") or value:match("|Hitem:(%d+):") or value:match("^item:(%d+)")
    id = id and tonumber(id); return Integer(id, 1, 2147483647) and id or nil
end
function Supplies:TakeCursorItem(merchantItemID)
    if InCombatLockdown() then return end
    if not Read(GetCursorInfo, "function") or not Read(ClearCursor, "function") then
        return nil, "Item drops are unavailable."
    end
    local ok, kind, value = pcall(GetCursorInfo)
    if not ok or not Suite.IsReadable(kind) then
        return nil, "The cursor item is unavailable."
    end
    if kind == nil then return end
    local id
    if kind == "item" then id = value
    elseif kind == "merchant" and merchantItemID then id = merchantItemID(value) end
    if not Integer(id, 1, 2147483647) then
        return nil, "Drop an available item here."
    end
    local cleared, result = pcall(ClearCursor)
    if not cleared or not Suite.IsReadable(result) or (result ~= nil and result ~= true) then
        return nil, "The item drop could not finish."
    end
    if not InCombatLockdown() then return id end
end
function Supplies:ReceiveItem()
    if InCombatLockdown() or not self.frame or not self.frame:IsShown() then return false end
    local id, message = self:TakeCursorItem()
    if not id then
        if message then self.frame.status:SetText(message .. " Paste an item ID or link instead.") end
        return false
    end
    self.frame.item:SetText(tostring(id))
    self.confirmRemove = nil; self.frame.remove.label:SetText("Remove item")
    self.frame.item:ClearFocus(); self.frame.quantity:SetFocus()
    self.frame.status:SetText("Item selected. Choose a quantity and click Save target.")
    return true
end
function Supplies:Open(owner)
    if InCombatLockdown() then Suite.Print("Open the Supply Checklist outside combat."); return end
    if not self.db then self:InitializeCharacter(nil) end
    if not self.frame then
        local frame = Window(self, "WoWForeverSuiteSupplies", "Supply Checklist")
        -- The drop target only fills this editor; saving remains explicit.
        frame.status:ClearAllPoints(); frame.status:SetPoint("TOPLEFT", 14, -460)
        local function Input(x, width, maximum)
            local box = CreateFrame("EditBox", nil, frame, "BackdropTemplate"); Surface(box)
            box:SetSize(width, 26); box:SetPoint("TOPLEFT", x, -502)
            box:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE"); box:SetAutoFocus(false)
            box:SetTextInsets(6, 6, 0, 0); box:SetMaxLetters(maximum)
            box:SetScript("OnEscapePressed", function() box:ClearFocus(); frame:Hide() end)
            box:SetScript("OnTextChanged", function() self.confirmRemove = nil; if frame.remove then frame.remove.label:SetText("Remove item") end end)
            return box
        end
        Label(frame, 14, -486, 250, 10):SetText("Drop item, ID or pasted link")
        Label(frame, 274, -486, 90, 10):SetText("Target quantity")
        frame.item, frame.quantity = Input(14, 250, 512), Input(274, 90, 6)
        frame.item:EnableMouse(true)
        frame.item:SetScript("OnReceiveDrag", function() self:ReceiveItem() end)
        frame.item:HookScript("OnMouseDown", function(_, button) if button == "LeftButton" then self:ReceiveItem() end end)
        for _, row in ipairs(frame.rows) do
            row.icon = Suite.Items:CreateListIcon(row, 30, 5, -5)
            row.label:ClearAllPoints(); row.label:SetPoint("TOPLEFT", 44, -4); row.label:SetWidth(540)
            row.detail:ClearAllPoints(); row.detail:SetPoint("TOPLEFT", 44, -23); row.detail:SetWidth(540)
            row:SetScript("OnEnter", function(owner) self:ItemTooltip(owner) end)
            row:SetScript("OnLeave", function(owner) if self.hovered == owner then self:HideTooltip() end end)
            row:HookScript("OnHide", function(owner) if self.hovered == owner then self:HideTooltip() end; owner.supplyID = nil end)
        end
        frame.save = Button(frame, "Save target", 374, -502, 108, function()
            local quantity = frame.quantity:GetText()
            local id, wanted = ItemInput(frame.item:GetText()), Read(quantity, "string") and tonumber(quantity) or nil
            local ok, message = self:Save(id, wanted)
            self.confirmRemove = nil; frame.remove.label:SetText("Remove item")
            self:Refresh(); if not ok then frame.status:SetText(message) end
        end)
        frame.remove = Button(frame, "Remove item", 490, -502, 116, function()
            local id = ItemInput(frame.item:GetText())
            if not id then frame.status:SetText("Select a saved item first."); return end
            if self.confirmRemove ~= id then self.confirmRemove = id; frame.remove.label:SetText("Confirm remove"); return end
            self:Remove(id)
            self.confirmRemove = nil; frame.remove.label:SetText("Remove item"); self:Refresh()
        end)
        frame.settings = Button(frame, "Settings", 498, -544, 108, function() Suite.GUI:OpenPage("supplies", nil, self.frame) end)
        frame.shopping = Button(frame, "Shopping list", 330, -544, 158, function() Suite.ShoppingList:Open(self.frame) end)
    end
    Suite.PlaceWindow(self.frame, owner)
    self.requested = {}; self.frame:Show(); self:Apply()
end
function Supplies:OnHide()
    self:CancelRefresh()
    self:HideTooltip()
    self.requested = nil
    if self.events then self.events:UnregisterAllEvents() end
    if self.frame then
        self.frame.item:ClearFocus(); self.frame.quantity:ClearFocus()
        self.frame.remove.label:SetText("Remove item")
    end
end
function Supplies:CancelRefresh()
    if self.refreshTimer then self.refreshTimer:Cancel(); self.refreshTimer = nil end
end
function Supplies:QueueRefresh(event, itemID)
    if not self.frame or not self.frame:IsShown() or InCombatLockdown() then return end
    if event == "ITEM_DATA_LOAD_RESULT" then
        if not Integer(itemID, 1, 2147483647) or not self.requested or not self.requested[itemID] then return end
    elseif event ~= "BAG_UPDATE_DELAYED" or not self:Enabled() then return end
    if self.refreshTimer then return end
    if not C_Timer or type(C_Timer.NewTimer) ~= "function" then self:Refresh(); return end
    self.refreshTimer = C_Timer.NewTimer(0.1, function()
        self.refreshTimer = nil
        if self.frame and self.frame:IsShown() and not InCombatLockdown() then self:Refresh() end
    end)
end
function Supplies:Apply()
    self:CancelRefresh()
    if self.events then self.events:UnregisterAllEvents() end
    if not self.frame or not self.frame:IsShown() then return end
    if not self.events then
        if InCombatLockdown() then return end
        self.events = CreateFrame("Frame")
        self.events:SetScript("OnEvent", function(_, event, itemID) self:QueueRefresh(event, itemID) end)
    end
    -- The visible window already owns combat events and immediate status refreshes.
    self.events:RegisterEvent("ITEM_DATA_LOAD_RESULT")
    if self:Enabled() then self.events:RegisterEvent("BAG_UPDATE_DELAYED") end
    self:Refresh()
end

function Expiry:Enabled() return Suite.db and Suite.IsReadable(Suite.db.mailExpiry) and Suite.db.mailExpiry == true end
function Expiry:Validate(value)
    if not Read(value, "table") or not Integer(value.at, 1, 10000000000) or not Integer(value.count, 0, 10000)
        or not Integer(value.total, value.count, 10000) then return end
    if value.count > 0 and not Number(value.deadline, value.at, value.at + 366 * 86400) then return end
    return { at = value.at, count = value.count, total = value.total, deadline = value.count > 0 and value.deadline or nil }
end
function Expiry:Capture(allowEmpty)
    if not self:Enabled() or not self.mailOpen or InCombatLockdown() then return end
    if type(GetInboxNumItems) ~= "function" or type(GetInboxHeaderInfo) ~= "function" then return end
    local ok, count, total = pcall(GetInboxNumItems)
    local now = Call(GetServerTime)
    if not ok or not Integer(count, 0, 10000) or not Integer(total, count, 10000) or not Integer(now, 1, 10000000000)
        or (count == 0 and (not allowEmpty or total > 0)) then return end
    local deadline
    for index = 1, count do
        -- Native MailFrame reads daysLeft from return seven, in fractional days.
        local success, _, _, _, _, _, _, days = pcall(GetInboxHeaderInfo, index)
        if not success or not Number(days, 0, 366) then return end
        local at = now + days * 86400; deadline = deadline and math.min(deadline, at) or at
    end
    local character = Suite.Inventory:Character(); if not character then return end
    character.mailExpiry = { at = now, count = count, total = total, deadline = deadline }
    self:Refresh(); Suite.CharacterDashboard:RefreshView()
end
local function DeadlineText(saved, now, compact)
    if not saved.deadline or not Integer(now, 1, 10000000000) then return "" end
    local remaining = saved.deadline - now
    if remaining <= 0 then
        return compact and " · Deadline passed" or " · Recorded deadline passed; check mailbox"
    end
    return (compact and " · Due in " or " · Earliest deadline in ") .. math.ceil(remaining / 3600) .. "h"
end
local function ClassNameText(name, class)
    local color = Read(RAID_CLASS_COLORS, "table") and Text(class, 32) and RAID_CLASS_COLORS[class]
    if not Read(color, "table") or not Number(color.r, 0, 1)
        or not Number(color.g, 0, 1) or not Number(color.b, 0, 1) then return name end
    return string.format("|cff%02x%02x%02x%s|r", math.floor(color.r * 255 + 0.5),
        math.floor(color.g * 255 + 0.5), math.floor(color.b * 255 + 0.5), name)
end
function Expiry:Rows()
    local rows, region, now = {}, Call(GetCurrentRegion), Call(GetServerTime)
    if not Integer(region, 1, 1000000) then return rows end
    for _, character in pairs(Suite.Inventory:Database().characters) do
        if Read(character, "table") and Integer(character.region, 1, 1000000) and character.region == region
            and Text(character.name, 128) then
            local saved = self:Validate(character.mailExpiry)
            if saved then
                local stamp = Call(date, "%b %d, %H:%M", saved.at)
                local name = Text(character.fullName, 128) and character.fullName or character.name
                local ruleset = Suite.Mail:RecordedRuleset(character)
                local partial = saved.total > saved.count
                local count = partial and (saved.count .. " / " .. saved.total) or tostring(saved.count)
                local title = ClassNameText(name, character.class) .. (ruleset and " · " .. ruleset or "")
                rows[#rows + 1] = { name = name, title = title, snapshot = saved,
                    mailCount = (saved.count > 0 and "|cff68d6bf" or "|cff8ca6b3") .. count .. "|r",
                    detail = "Checked " .. (Text(stamp, 80) and stamp or "date unavailable")
                        .. (partial and " · Partial inbox" or "") .. DeadlineText(saved, now, true) }
            end
        end
    end
    table.sort(rows, function(a, b)
        local left, right = a.snapshot.deadline or math.huge, b.snapshot.deadline or math.huge
        if left ~= right then return left < right end
        return a.name < b.name
    end)
    return rows
end
function Expiry:Summary(value, now)
    local saved = self:Validate(value); if not saved then return "Mail not recorded" end
    local result = saved.count .. (saved.count == 1 and " recorded letter" or " recorded letters")
    result = result .. DeadlineText(saved, now)
    if saved.total > saved.count then result = result .. " · Partial inbox (" .. saved.count .. "/" .. saved.total .. ")" end
    return result
end
function Expiry:Refresh()
    local frame = self.frame
    if not frame or not frame:IsShown() then return end
    local rows = self:Rows(); Paging(self, rows)
    local visible = math.max(1, math.min(#frame.rows, #rows - (self.page - 1) * #frame.rows))
    local height = MAIL_ROW_TOP + visible * MAIL_ROW_STEP + MAIL_FOOTER
    if not InCombatLockdown() and frame:GetHeight() ~= height then frame:SetHeight(height) end
    frame.context:SetText("Counts are from the last mailbox visit.")
    frame.status:SetText(not self:Enabled() and "Recording and login reminders are off. Saved records remain available."
        or #rows == 0 and "No mailbox recorded. Open a mailbox with recording enabled."
        or "Inbox loading can leave partial records. Visit a mailbox to refresh.")
    frame.refresh:SetEnabled(not InCombatLockdown())
end
function Expiry:Open(owner)
    if InCombatLockdown() then Suite.Print("Open Mail Deadlines outside combat."); return end
    if not self.frame then
        local frame = Window(self, "WoWForeverSuiteMailDeadlines", "Mail Deadlines")
        local countX = MAIL_WIDTH - 22 - MAIL_COUNT_WIDTH
        local band = frame:CreateTexture(nil, "BORDER")
        band:SetPoint("TOPLEFT", 14, -64); band:SetSize(MAIL_WIDTH - 28, 24)
        band:SetColorTexture(0.08, 0.11, 0.14, 1)
        local function ColumnHeader(text, x, width, justify)
            local label = Label(frame, x, -64, width, 16)
            label:SetHeight(24); label:SetJustifyH(justify); label:SetJustifyV("MIDDLE")
            label:SetText(text)
        end
        ColumnHeader("Character", 20, countX - 26, "LEFT")
        ColumnHeader("Mail", countX, MAIL_COUNT_WIDTH, "RIGHT")
        for _, row in ipairs(frame.rows) do
            row.label:ClearAllPoints(); row.label:SetPoint("TOPLEFT", 6, -4)
            row.label:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
            row.label:SetHeight(17); row.label:SetWidth(countX - 26)
            row.detail:SetTextColor(0.55, 0.65, 0.7)
            row.mailCount = Label(row, countX - 14, -4, MAIL_COUNT_WIDTH, 13)
            row.mailCount:SetJustifyH("RIGHT")
        end
        frame.refresh = Button(frame, "Refresh times", 0, 0, 108, function() self:Refresh() end)
        frame.refresh:ClearAllPoints(); frame.refresh:SetPoint("BOTTOMRIGHT", -104, 10)
        local settings = Button(frame, "Settings", 0, 0, 82, function() Suite.GUI:OpenPage("mail", nil, self.frame) end)
        settings:ClearAllPoints(); settings:SetPoint("BOTTOMRIGHT", -14, 10)
    end
    self.frame:Show(); self:Refresh()
    Suite.PlaceWindow(self.frame, owner)
end
function Expiry:Cancel()
    if self.timer then self.timer:Cancel(); self.timer = nil end
    self.token = nil
end
function Expiry:Queue(allowEmpty)
    self:Cancel()
    if not self:Enabled() or not self.mailOpen or InCombatLockdown() then return end
    if not C_Timer or type(C_Timer.NewTimer) ~= "function" then self:Capture(allowEmpty); return end
    local token = {}; self.token = token
    self.timer = C_Timer.NewTimer(0.2, function()
        if self.token ~= token then return end
        self.timer, self.token = nil, nil; self:Capture(allowEmpty)
    end)
end
function Expiry:OnEvent(event)
    if not self:Enabled() then return end
    if event == "PLAYER_ENTERING_WORLD" then self.mailOpen = nil; self:Cancel() end
    if event == "MAIL_SHOW" then self.mailOpen = true; self:Queue(false)
    elseif event == "MAIL_CLOSED" then self.mailOpen = nil; self:Cancel()
    elseif event == "MAIL_INBOX_UPDATE" then self:Queue(true)
    elseif event == "PLAYER_REGEN_DISABLED" then
        self:Cancel()
    elseif event == "PLAYER_REGEN_ENABLED" then self:Queue(false); self:Refresh()
    elseif event == "PLAYER_ENTERING_WORLD" and not self.warned then
        self.warned = true
        local now, due = Call(GetServerTime), 0
        if Integer(now, 1, 10000000000) then
            for _, row in ipairs(self:Rows()) do if row.snapshot.deadline and row.snapshot.deadline - now <= 3 * 86400 then due = due + 1 end end
        end
        if due > 0 then Suite.Print("Recorded mail deadlines need attention on " .. due .. " character(s). Open /wfs maildeadlines to review; visit mailboxes to refresh.") end
    end
end
function Expiry:Apply()
    Suite.pending.mailExpiryApply = nil
    self:Cancel()
    if self.events then self.events:UnregisterAllEvents() end
    if not self:Enabled() then self.mailOpen = nil; self:Refresh(); return end
    if not self.events then
        if InCombatLockdown() then Suite.AfterCombat("mailExpiryApply", function() self:Apply() end); return end
        self.events = CreateFrame("Frame"); self.events:SetScript("OnEvent", function(_, event) self:OnEvent(event) end)
    end
    for _, event in ipairs({ "MAIL_SHOW", "MAIL_CLOSED", "MAIL_INBOX_UPDATE", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD" }) do self.events:RegisterEvent(event) end
    if not InCombatLockdown() and MailFrame and Call(MailFrame.IsShown, MailFrame) == true then self.mailOpen = true; self:Queue(false) end
    self:Refresh()
end
