local _, Suite = ...
local Supplies, Expiry = { page = 1 }, { page = 1 }
Suite.SupplyChecklist, Suite.MailExpiry = Supplies, Expiry
table.insert(Suite.modules, Supplies)
table.insert(Suite.modules, Expiry)
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
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate"); Surface(button)
    button:SetSize(width, 26); button:SetPoint("TOPLEFT", x, y)
    button.label = Label(button, 5, -6, width - 10); button.label:SetJustifyH("CENTER"); button.label:SetText(text)
    button.label:SetWordWrap(false); button.label:SetHeight(16)
    Suite.Theme:ButtonFeedback(button)
    button:SetScript("OnClick", function() if not InCombatLockdown() then callback() end end)
    return button
end
local function Window(owner, name, title)
    local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate"); Surface(frame)
    frame:SetSize(620, 580); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true)
    if UISpecialFrames then table.insert(UISpecialFrames, name) end
    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT"); header:SetSize(574, 38); header:EnableMouse(true); header:RegisterForDrag("LeftButton")
    Label(header, 14, -11, 545, 17):SetText(title)
    header:SetScript("OnDragStart", function() if not InCombatLockdown() then owner.moving = true; frame:StartMoving() end end)
    header:SetScript("OnDragStop", function() if owner.moving then frame:StopMovingOrSizing(); owner.moving = nil end end)
    local close = Suite.Theme:IconButton(frame, "Close " .. title, function() frame:Hide() end)
    close:SetSize(26, 26); close:SetPoint("TOPRIGHT", -8, -6)
    frame.context = Label(frame, 14, -48, 592, 11); frame.context:SetHeight(46)
    frame.status = Label(frame, 14, -503, 592, 11); frame.status:SetHeight(30)
    frame.rows = {}
    for index = 1, 8 do
        local row = Button(frame, "", 14, -104 - (index - 1) * 44, 592, function()
            if owner.Select then owner:Select(index + (owner.page - 1) * 8) end
        end)
        row:SetHeight(40); row.label:SetJustifyH("LEFT"); row.label:SetWidth(578)
        row.detail = Label(row, 5, -23, 578, 10)
        row.detail:SetWordWrap(false); row.detail:SetHeight(12)
        frame.rows[index] = row
    end
    frame.previous = Button(frame, "Previous", 14, -544, 90, function() owner.page = owner.page - 1; owner:Refresh() end)
    frame.next = Button(frame, "Next", 112, -544, 90, function() owner.page = owner.page + 1; owner:Refresh() end)
    frame.page = Label(frame, 218, -550, 90)
    frame:SetScript("OnHide", function()
        if owner.moving then frame:StopMovingOrSizing(); owner.moving = nil end
        owner.confirmRemove = nil
        frame:UnregisterAllEvents()
        if owner.OnHide then owner:OnHide() end
    end)
    frame:SetScript("OnShow", function() frame:RegisterEvent("PLAYER_REGEN_DISABLED"); frame:RegisterEvent("PLAYER_REGEN_ENABLED") end)
    frame:SetScript("OnEvent", function()
        if owner.moving then frame:StopMovingOrSizing(); owner.moving = nil end
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
        if row then widget.label:SetText(row.title); widget.detail:SetText(row.detail or "") end
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
                result.entries[#result.entries + 1] = { id = entry.id, wanted = entry.wanted }
                seen[entry.id] = true
            end
        end
    end
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
    return rows
end
function Supplies:Select(index)
    local row = self.db.entries[index]; if not row then return end
    self.confirmRemove = nil; self.frame.item:SetText(tostring(row.id)); self.frame.quantity:SetText(tostring(row.wanted))
    self.frame.remove.label:SetText("Remove item")
end
function Supplies:Refresh()
    if not self.frame or not self.frame:IsShown() then return end
    self.rows = self:Rows(self:Counts()); Paging(self, self.rows)
    self.frame.context:SetText("Set targets for reagents, food, water, bandages or coatings. Click a row to edit.\nCounts use carried bags only. Targets belong to this character.")
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
function Supplies:Open(owner)
    if InCombatLockdown() then Suite.Print("Open the Supply Checklist outside combat."); return end
    if not self.db then self:InitializeCharacter(nil) end
    if not self.frame then
        local frame = Window(self, "WoWForeverSuiteSupplies", "Supply Checklist")
        -- Leave the list above a compact editor; keep native item links as text input only.
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
        Label(frame, 14, -486, 250, 10):SetText("Item ID or pasted item link")
        Label(frame, 274, -486, 90, 10):SetText("Target quantity")
        frame.item, frame.quantity = Input(14, 250, 512), Input(274, 90, 6)
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
            for index, row in ipairs(self.db.entries) do if row.id == id then table.remove(self.db.entries, index); break end end
            self.confirmRemove = nil; frame.remove.label:SetText("Remove item"); self:Refresh()
        end)
        frame.settings = Button(frame, "Settings", 498, -544, 108, function() Suite.GUI:OpenPage("supplies", nil, self.frame) end)
    end
    Suite.PlaceWindow(self.frame, owner)
    self.requested = {}; self.frame:Show(); self:Apply(); self:Refresh()
end
function Supplies:OnHide()
    self.requested = nil
    if self.events then self.events:UnregisterAllEvents() end
    if self.frame then
        self.frame.item:ClearFocus(); self.frame.quantity:ClearFocus()
        self.frame.remove.label:SetText("Remove item")
    end
end
function Supplies:Apply()
    if self.events then self.events:UnregisterAllEvents() end
    if not self.frame or not self.frame:IsShown() then return end
    if not self.events then
        if InCombatLockdown() then return end
        self.events = CreateFrame("Frame")
        self.events:SetScript("OnEvent", function(_, event)
            if event == "PLAYER_REGEN_DISABLED" and self.moving then self.frame:StopMovingOrSizing(); self.moving = nil end
            self:Refresh()
        end)
    end
    self.events:RegisterEvent("PLAYER_REGEN_DISABLED"); self.events:RegisterEvent("PLAYER_REGEN_ENABLED")
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
function Expiry:Rows()
    local rows, region, now = {}, Call(GetCurrentRegion), Call(GetServerTime)
    if not Integer(region, 1, 1000000) then return rows end
    for _, character in pairs(Suite.Inventory:Database().characters) do
        if Read(character, "table") and Integer(character.region, 1, 1000000) and character.region == region
            and Text(character.name, 128) and Text(character.realm, 128) then
            local saved = self:Validate(character.mailExpiry)
            if saved then
                local stamp = Call(date, "%b %d, %H:%M", saved.at)
                rows[#rows + 1] = { title = (Text(character.fullName, 128) and character.fullName or character.name) .. " · " .. character.realm,
                    detail = self:Summary(saved, now) .. " · Checked " .. (Text(stamp, 80) and stamp or "date unavailable"),
                    snapshot = saved }
            end
        end
    end
    table.sort(rows, function(a, b)
        local left, right = a.snapshot.deadline or math.huge, b.snapshot.deadline or math.huge
        if left ~= right then return left < right end
        return a.title < b.title
    end)
    return rows
end
function Expiry:Summary(value, now)
    local saved = self:Validate(value); if not saved then return "Mail not recorded" end
    local result = saved.count .. (saved.count == 1 and " recorded letter" or " recorded letters")
    if saved.deadline and Integer(now, 1, 10000000000) then
        local remaining = saved.deadline - now
        result = result .. (remaining <= 0 and " · Recorded deadline passed; check mailbox"
            or " · Earliest deadline in " .. math.ceil(remaining / 3600) .. "h")
    end
    if saved.total > saved.count then result = result .. " · Partial inbox (" .. saved.count .. "/" .. saved.total .. ")" end
    return result
end
function Expiry:Refresh()
    if not self.frame or not self.frame:IsShown() then return end
    local rows = self:Rows(); Paging(self, rows)
    self.frame.context:SetText("Recorded mailbox deadlines for this region. Visit each character's mailbox to refresh.\nA passed deadline does not confirm that mail expired or is still present.")
    self.frame.status:SetText(not self:Enabled() and "Recording and login reminders are off. Saved records remain available."
        or #rows == 0 and "No mailbox recorded. Open a mailbox with recording enabled."
        or "Inbox loading may produce partial records. New letters and mailbox changes need another visit.")
end
function Expiry:Open(owner)
    if InCombatLockdown() then Suite.Print("Open Mail Deadlines outside combat."); return end
    if not self.frame then
        local frame = Window(self, "WoWForeverSuiteMailDeadlines", "Mail Deadlines")
        Button(frame, "Settings", 498, -544, 108, function() Suite.GUI:OpenPage("mail", nil, self.frame) end)
    end
    Suite.PlaceWindow(self.frame, owner)
    self.frame:Show(); self:Refresh()
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
        self:Cancel(); if self.moving then self.frame:StopMovingOrSizing(); self.moving = nil end
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
