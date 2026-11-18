local _, Suite = ...
local Shopping = { page = 1, requested = {} }
Suite.ShoppingList = Shopping
table.insert(Suite.modules, Shopping)
local tones = { required = { 0.9, 0.75, 0.48 }, stock = { 0.6, 0.72, 0.76 },
    shortage = { 1, 0.64, 0.4 }, stocked = { 0.41, 0.84, 0.75 }, unknown = { 0.7, 0.74, 0.77 } }
local function Read(v, kind) return Suite.IsReadable(v) and type(v) == kind end
local function Int(v, low, high) return Read(v, "number") and v == v and v >= low and v <= high and v % 1 == 0 end
local function Text(v) return Read(v, "string") and #v > 0 and #v <= 240 and not v:find("[%c|]") end
local function Call(fn, ...)
    if not Read(fn, "function") then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Safe(frame)
    return Suite.IsReadable(frame) and (type(frame) == "table" or type(frame) == "userdata")
        and Call(frame.IsForbidden, frame) == false
end
function Shopping:Enabled() return Suite.db and Read(Suite.db.professionShopping, "boolean") and Suite.db.professionShopping == true end
function Shopping:Normalize(saved)
    local plans = {}
    if Read(saved, "table") then
        for _, guide in ipairs(Suite.ProfessionGuides) do
            local plan = saved[guide.name]
            if Read(plan, "table") and guide.estimates and Int(plan.rank, 0, 300) then
                local limit = plan.endSkill
                if Suite.IsReadable(limit) and limit == nil then plans[guide.name] = { rank = plan.rank }
                elseif Int(limit, 1, 300) then
                    for _, section in ipairs(guide.sections) do
                        if section[2] == limit then plans[guide.name] = { rank = plan.rank, endSkill = limit }; break end
                    end
                end
            end
        end
    end
    return plans
end
function Shopping:Plans()
    local supplies = Suite.SupplyChecklist
    if not supplies.db then supplies:InitializeCharacter(nil) end
    if not supplies.db.professionPlans then supplies.db.professionPlans = {} end
    return supplies.db.professionPlans
end
function Shopping:Rank(name, plan)
    local skill = Suite.ProfessionLeveling.skills and Suite.ProfessionLeveling.skills[name]
    return Read(skill, "table") and Int(skill.rank, 0, 300) and skill.rank or plan.rank
end
function Shopping:Targets(plans)
    local merged, missing = {}, false
    for _, guide in ipairs(Suite.ProfessionGuides) do
        local plan = plans[guide.name]
        if plan then
            local done, _, groups = Suite.ProfessionLeveling:MaterialPlan(guide, self:Rank(guide.name, plan))
            for _, group in ipairs(groups or {}) do
                if not plan.endSkill or group.endSkill == plan.endSkill then
                    for _, row in ipairs(group.rows) do
                        if not done[row] then for _, item in ipairs(row) do
                            local quantity, id, name = item[1], item[2], item[3]
                            if Int(id, 1, 2147483647) and Int(quantity, 1, 1000000) and Text(name) then
                                local target = merged[id] or { id = id, wanted = 0, name = name }
                                target.wanted = target.wanted + quantity; merged[id] = target
                            else missing = true end
                        end end
                    end
                end
            end
        end
    end
    local rows = {}
    for _, row in pairs(merged) do rows[#rows + 1] = row end
    table.sort(rows, function(a, b) if a.name ~= b.name then return a.name < b.name end; return a.id < b.id end)
    return rows, missing
end
function Shopping:Carried()
    if not self:Enabled() or InCombatLockdown() then return end
    local maximum = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS
    if not Int(maximum, 0, 32) then return {} end
    local bags = {}; for id = 0, maximum do bags[#bags + 1] = id end
    -- An incomplete fresh scan replaces, rather than adds to, old current bags.
    return Call(Suite.Inventory.ScanContainers, Suite.Inventory, bags, false) or {}
end
function Shopping:Rows(preview)
    local plans = self:Plans()
    if preview and self.pending then
        plans = Suite.Copy(plans); plans[self.pending.name] = self.pending.plan
    end
    local rows, missing = self:Targets(plans)
    if #rows == 0 then return rows, missing end
    local carried = self:Carried()
    for _, row in ipairs(rows) do
        local summary = Suite.Inventory:Summary(row.id, true, carried)
        row.observed = Read(summary, "table") and summary.observed == true
        row.count = row.observed and summary.total or nil
        row.incomplete = not row.observed or summary.incomplete == true
        row.oldestAt, row.undated = summary and summary.oldestAt, summary and summary.undated
        row.need = row.count and math.max(0, row.wanted - row.count) or nil
        local nativeName = Call(C_Item and C_Item.GetItemNameByID, row.id)
        if Text(nativeName) then row.name = nativeName
        elseif self.frame and self.frame:IsShown() and not self.requested[row.id] and not InCombatLockdown() then
            self.requested[row.id] = true; Call(C_Item and C_Item.RequestLoadItemDataByID, row.id)
        end
        row.title = row.name .. " · required " .. row.wanted
        row.detail = row.count and ("All characters / banks: " .. row.count .. (row.incomplete and "+" or "")
            .. " · Buy " .. (row.incomplete and "up to " or "") .. row.need)
            or "Stock unknown · Check characters and banks before buying."
    end
    return rows, missing
end
function Shopping:QuantityCells(row)
    local stock = row.count and tostring(row.count) .. (row.incomplete and "+" or "") or "Unknown"
    local buy = row.need == nil and "Check stock" or row.need == 0 and "0 · Stocked"
        or (row.incomplete and "Up to " or "") .. row.need
    return tostring(row.wanted), stock, buy, row.need == nil and tones.unknown or row.need == 0 and tones.stocked or tones.shortage
end
function Shopping:Review(name, rank, endSkill, owner)
    if InCombatLockdown() or not Text(name) or not Int(rank, 0, 300) then Suite.Print("Open a guide with a known skill level first."); return false end
    local normalized = self:Normalize({ [name] = { rank = rank, endSkill = endSkill } })
    if not normalized[name] then Suite.Print("This guide has no supported material plan."); return false end
    self.pending = { name = name, plan = normalized[name] }; self.page, self.confirmRemove = 1, nil
    self:Open(owner); return true
end
function Shopping:SavePlan()
    if InCombatLockdown() or not self.pending then return false end
    local pending = self.pending
    self:Plans()[pending.name] = Suite.Copy(pending.plan)
    self.pending = nil
    -- Save & track is the explicit opt-in; opening or reviewing never enables recording.
    Suite.Set("professionShopping", true)
    self:Changed(); return true
end
function Shopping:Changed()
    if Suite.SupplyChecklist.frame and Suite.SupplyChecklist.frame:IsShown() then Suite.SupplyChecklist:Refresh() end
    if self.frame and self.frame:IsShown() then self:Queue() end
end
local function Label(parent, x, y, width, size)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE"); label:SetTextColor(0.88, 0.91, 0.93)
    label:SetPoint("TOPLEFT", x, y); label:SetWidth(width); label:SetJustifyH("LEFT"); return label
end
local function Button(parent, text, x, y, width, callback)
    local button = Suite.Theme:ActionButton(parent, text, width, 24, function() if not InCombatLockdown() then callback() end end)
    button:SetPoint("TOPLEFT", x, y); return button
end
function Shopping:HideTooltip()
    local tip, owner = self.tooltip, self.hovered
    self.tooltip, self.hovered = nil, nil
    if owner and Safe(tip) and Call(tip.GetOwner, tip) == owner and Read(tip.Hide, "function") then pcall(tip.Hide, tip) end
end
function Shopping:ItemTooltip(row)
    self:HideTooltip()
    if InCombatLockdown() or not self.frame or not self.frame:IsShown() or not row:IsShown()
        or not Int(row.itemID, 1, 2147483647) then return end
    local tip = GameTooltip
    if not Safe(tip) then return end
    for _, method in ipairs({ "SetOwner", "GetOwner", "SetItemByID", "Show", "Hide" }) do
        if not Read(tip[method], "function") then return end
    end
    self.tooltip, self.hovered = tip, row
    if not pcall(tip.SetOwner, tip, row, "ANCHOR_RIGHT") or Call(tip.GetOwner, tip) ~= row
        or not pcall(tip.SetItemByID, tip, row.itemID) or Call(tip.GetOwner, tip) ~= row then
        self:HideTooltip(); return
    end
    if not pcall(tip.Show, tip) then self:HideTooltip() end
end
function Shopping:Refresh()
    local hovered, itemID = self.hovered, self.hovered and self.hovered.itemID
    self:HideTooltip()
    if not self.frame or not self.frame:IsShown() then return end
    local frame = self.frame
    if InCombatLockdown() then
        frame.status:SetText("Paused in combat. Reopen after combat.")
        for _, button in ipairs({ frame.save, frame.manage, frame.previous, frame.next, frame.checklist }) do button:SetEnabled(false) end
        return
    end
    Suite.ProfessionLeveling:CaptureSkills()
    local rows, missing = self:Rows(true)
    self.page = math.max(1, math.min(self.page, math.max(1, math.ceil(#rows / 8))))
    local oldest, undated
    for _, row in ipairs(rows) do
        if row.oldestAt then oldest = oldest and math.min(oldest, row.oldestAt) or row.oldestAt end
        undated = undated or row.undated
    end
    local stamp = oldest and Call(date, "%b %d, %H:%M", oldest)
    frame.context:SetText(self.pending and ("Review " .. self.pending.name .. (self.pending.plan.endSkill and " section" or " remaining materials")
        .. ". Save replaces this profession's plan.\nSave & track enables bag/bank recording; manual supply targets stay separate.")
        or "All saved profession plans combined. Recorded stock may be stale.\nLog into alts with shopping tracking enabled and visit banks to refresh them.")
    if #rows == 0 and not self.pending then
        frame.context:SetText("No unfinished materials in saved plans.\nOpen a profession's Leveling guide and choose Track section or Track remaining.")
    end
    frame.status:SetText((self:Enabled() and "Tracking on" or "Tracking off · saved records only")
        .. " · Oldest stock record: " .. (Text(stamp) and stamp or "not recorded") .. (undated and " · Some dates unknown" or "")
        .. (missing and "\nSome materials lack item IDs; check the guide." or "\nStock = all characters / banks. + = incomplete stock; Up to = estimated purchase."))
    for index, widget in ipairs(frame.rows) do
        local row = rows[index + (self.page - 1) * 8]
        widget.itemID = row and row.id or nil
        widget:SetShown(row ~= nil)
        if row then
            Suite.Items:SetListIcon(widget.icon, row.id)
            widget.title:SetText(row.name)
            local required, stock, buy, color = self:QuantityCells(row)
            widget.required:SetText(required); widget.stock:SetText(stock); widget.buy:SetText(buy)
            widget.stock:SetTextColor(unpack(row.count and tones.stock or tones.unknown))
            widget.buy:SetTextColor(unpack(color))
        end
    end
    frame.save:SetShown(self.pending ~= nil); frame.save:SetEnabled(self.pending ~= nil)
    frame.manage:SetEnabled(true); frame.checklist:SetEnabled(true)
    frame.previous:SetEnabled(self.page > 1); frame.next:SetEnabled(self.page * 8 < #rows)
    frame.page:SetText(self.page .. " / " .. math.max(1, math.ceil(#rows / 8)))
    if hovered and hovered.itemID == itemID and Call(MouseIsOver, hovered) == true then self:ItemTooltip(hovered) end
end
function Shopping:Manage(button)
    if not Suite.Menus then return end
    Suite.Menus.CreateContextMenu(button, function(_, root)
        root:CreateTitle("Remove a saved profession plan")
        for _, guide in ipairs(Suite.ProfessionGuides) do
            local name = guide.name
            if self:Plans()[name] then
                root:CreateButton((self.confirmRemove == name and "Confirm remove " or "Remove ") .. name, function()
                    if InCombatLockdown() then return end
                    if self.confirmRemove ~= name then self.confirmRemove = name; self:Manage(button); return end
                    self:Plans()[name] = nil; self.confirmRemove = nil; self:Changed()
                end)
            end
        end
        if self.pending then root:CreateButton("Discard preview", function() self.pending = nil; self:Refresh() end) end
    end)
end
function Shopping:Open(owner)
    if InCombatLockdown() then Suite.Print("Open the shopping list outside combat."); return end
    if not self.frame then
        local frame = CreateFrame("Frame", "WoWForeverSuiteShopping", UIParent, "BackdropTemplate"); self.frame = frame
        frame:SetSize(660, 530); frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true); frame:EnableMouse(true)
        frame:SetPoint("CENTER", UIParent, "CENTER")
        frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        frame:SetBackdropColor(0.035, 0.05, 0.065, 1); Suite.Theme:Backdrop(frame, 0.85)
        if UISpecialFrames then table.insert(UISpecialFrames, "WoWForeverSuiteShopping") end
        local header = CreateFrame("Frame", nil, frame)
        frame.header = header
        header:SetPoint("TOPLEFT"); header:SetSize(610, 34)
        Label(header, 14, -12, 590, 17):SetText("Profession Shopping List")
        Suite.BindWindowDrag(frame, header)
        local close = Suite.Theme:IconButton(frame, "Close shopping list", function() frame:Hide() end)
        close:SetSize(24, 24); close:SetPoint("TOPRIGHT", -8, -8)
        frame.context = Label(frame, 14, -43, 630, 11); frame.context:SetHeight(42)
        frame.save = Button(frame, "Save & track", 14, -91, 124, function() self:SavePlan() end)
        frame.manage = Button(frame, "Manage plans", 146, -91, 132, function() self:Manage(frame.manage) end)
        frame.checklist = Button(frame, "Supply Checklist", 286, -91, 154, function() Suite.SupplyChecklist:Open(frame) end)
        Label(frame, 54, -126, 220, 10):SetText("ITEM")
        for _, column in ipairs({ { "REQUIRED", 296, 76 }, { "RECORDED STOCK", 390, 110 }, { "BUY", 520, 124 } }) do
            local label = Label(frame, column[2], -126, column[3], 10)
            label:SetJustifyH("RIGHT"); label:SetText(column[1])
        end
        frame.rows = {}
        for index = 1, 8 do
            local row = CreateFrame("Button", nil, frame); row:SetPoint("TOPLEFT", 14, -146 - (index - 1) * 32); row:SetSize(632, 30)
            row:EnableMouse(true); row:RegisterForClicks("LeftButtonUp")
            row:SetScript("OnClick", function(_, button) Suite.Items:ModifiedClick(row.itemID, button) end)
            row:SetScript("OnEnter", function() self:ItemTooltip(row) end)
            row:SetScript("OnLeave", function() if self.hovered == row then self:HideTooltip() end end)
            row:SetScript("OnHide", function() if self.hovered == row then self:HideTooltip() end; row.itemID = nil end)
            row.icon = Suite.Items:CreateListIcon(row, 26, 0, -1)
            row.title = Label(row, 40, -5, 224); row.title:SetHeight(26)
            row.required = Label(row, 282, -7, 76); row.required:SetTextColor(unpack(tones.required))
            row.stock = Label(row, 376, -7, 110)
            row.buy = Label(row, 506, -7, 124)
            for _, label in ipairs({ row.required, row.stock, row.buy }) do label:SetJustifyH("RIGHT"); label:SetWordWrap(false) end
            frame.rows[index] = row
        end
        frame.previous = Button(frame, "Previous", 14, -425, 90, function() self.page = self.page - 1; self:Refresh() end)
        frame.next = Button(frame, "Next", 112, -425, 90, function() self.page = self.page + 1; self:Refresh() end)
        frame.page = Label(frame, 218, -431, 90)
        frame.status = Label(frame, 14, -460, 630, 10); frame.status:SetHeight(38)
        Label(frame, 14, -505, 630, 10):SetText("Shift-click an item to fill the open auction search or link it to chat.")
        frame:Hide()
        frame:SetScript("OnHide", function()
            self:HideTooltip()
            self:Cancel(); self.pending, self.confirmRemove = nil, nil; self:Apply()
        end)
    end
    Suite.PlaceWindow(self.frame, owner)
    self.frame:Show(); self.requested = {}; self:Apply(); self:Refresh()
end
function Shopping:Cancel()
    if self.timer then self.timer:Cancel(); self.timer = nil end
end
function Shopping:Queue()
    if self.timer or not self.frame or not self.frame:IsShown() or InCombatLockdown() then return end
    if not C_Timer or not C_Timer.NewTimer then self:Refresh(); return end
    self.timer = C_Timer.NewTimer(0.15, function() self.timer = nil; self:Refresh() end)
end
function Shopping:AuctionButton()
    if InCombatLockdown() then return end
    if not self:Enabled() then if self.auctionButton then self.auctionButton:Hide() end; return end
    local owner = AuctionHouseFrame
    if not Safe(owner) then return end
    if not self.auctionButton then
        self.auctionButton = Suite.Theme:ActionButton(owner, "Shopping list", 110, 22, function()
            if not InCombatLockdown() and self:Enabled() then self.pending = nil; self:Open(owner) end
        end)
        -- The native title's right edge leaves the close control and tabs available.
        self.auctionButton:SetPoint("TOPRIGHT", owner, "TOPRIGHT", -42, -5)
    end
    self.auctionButton:SetShown(self:Enabled())
end
function Shopping:Apply()
    self:Cancel()
    if InCombatLockdown() then
        Suite.AfterCombat("shopping", function() self:Apply(); self:Refresh() end)
        return
    end
    if not self.events then
        if not self:Enabled() and not (self.frame and self.frame:IsShown()) then return end
        self.events = CreateFrame("Frame")
        self.events:SetScript("OnEvent", function(_, event, id)
            if event == "PLAYER_REGEN_DISABLED" then self:Cancel(); self:Refresh()
            elseif event == "AUCTION_HOUSE_SHOW" or event == "ADDON_LOADED" then self:AuctionButton()
            elseif event == "ITEM_DATA_LOAD_RESULT" then
                if Int(id, 1, 2147483647) and self.requested[id] then self:Queue() end
            else self:Queue() end
        end)
    end
    self.events:UnregisterAllEvents()
    self:AuctionButton()
    if self:Enabled() then self.events:RegisterEvent("AUCTION_HOUSE_SHOW"); self.events:RegisterEvent("ADDON_LOADED") end
    if self.frame and self.frame:IsShown() then
        for _, event in ipairs({ "BAG_UPDATE_DELAYED", "SKILL_LINES_CHANGED", "TRADE_SKILL_LIST_UPDATE", "ITEM_DATA_LOAD_RESULT",
            "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do self.events:RegisterEvent(event) end
    end
end
