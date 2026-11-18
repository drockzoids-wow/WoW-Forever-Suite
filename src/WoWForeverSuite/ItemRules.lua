local _, Suite = ...
local Rules = { page = 1, limit = 256 }
Suite.ItemRules = Rules
table.insert(Suite.modules, Rules)
local flags = { "neverSell", "neverDelete", "pauseSort" }
local function Read(v, kind) return Suite.IsReadable(v) and type(v) == kind end
local function Int(v, low, high) return Read(v, "number") and v == v and v >= low and v <= high and v % 1 == 0 end
local function Call(fn, ...)
    if not Read(fn, "function") then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Text(v) return Read(v, "string") and #v > 0 and #v <= 240 and not v:find("[%c|]") end
local function SafeTooltip(tip)
    return Suite.IsReadable(tip) and (type(tip) == "table" or type(tip) == "userdata")
        and Call(tip.IsForbidden, tip) == false
end
function Rules:Enabled() return Suite.db and Read(Suite.db.itemKeepRulesEnabled, "boolean") and Suite.db.itemKeepRulesEnabled == true end
local function ValidRule(rule)
    if not Read(rule, "table") then return end
    local result = {}
    for _, flag in ipairs(flags) do
        local value = rule[flag]
        if not Suite.IsReadable(value) or value ~= nil and type(value) ~= "boolean" then return end
        result[flag] = value == true
    end
    return result
end
function Rules:Normalize(saved)
    local result, count = {}, 0
    if Read(saved, "table") then for id, entry in pairs(saved) do
        if Int(id, 1, 2147483647) then
            local rule = ValidRule(entry)
            if rule and (rule.neverSell or rule.neverDelete or rule.pauseSort) and count < self.limit then
                result[id] = rule; count = count + 1
            end
        end
    end end
    return result
end
function Rules:InitializeCharacter(saved)
    local result, count = {}, 0
    if Read(saved, "table") then for id, quantity in pairs(saved) do
        if Int(id, 1, 2147483647) and Int(quantity, 1, 100000) and count < self.limit then
            result[id] = quantity; count = count + 1
        end
    end end
    self.reserves = result; return result
end
function Rules:Rule(id)
    if not Int(id, 1, 2147483647) or not Read(Suite.db.itemKeepRules, "table") then return end
    local value = Suite.db.itemKeepRules[id]
    if not Suite.IsReadable(value) then return end
    return value == nil and {} or ValidRule(value)
end
function Rules:Reserve(id)
    if not Int(id, 1, 2147483647) then return end
    if not self.reserves then return 0 end
    if not Read(self.reserves, "table") then return end
    local value = self.reserves[id]
    if not Suite.IsReadable(value) then return end
    if value == nil then return 0 end
    if Int(value, 0, 100000) then return value end
end
function Rules:Counts()
    local maximum = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS
    if not Int(maximum, 0, 32) or InCombatLockdown() then return end
    local bags = {}; for id = 0, maximum do bags[#bags + 1] = id end
    local snapshot = Call(Suite.Inventory.ScanContainers, Suite.Inventory, bags, false)
    return Read(snapshot, "table") and Read(snapshot.items, "table") and snapshot.items or nil
end
function Rules:CanRemove(id, action, quantity)
    if not self:Enabled() then return true end
    if not Read(action, "string") or (action ~= "sell" and action ~= "delete" and action ~= "deposit") then return false, "unavailable" end
    local rule = self:Rule(id)
    if not rule then return false, "unavailable" end
    if action == "sell" and rule.neverSell or action == "delete" and rule.neverDelete then return false, "keep" end
    local reserve = self:Reserve(id)
    if reserve == nil then return false, "unavailable" end
    if reserve > 0 then
        local counts = self:Counts()
        local total = counts and counts[id]
        if total == nil and counts then total = 0 end
        if not Int(total, 0, 1000000000) or not Int(quantity, 1, 1000000000) then return false, "unavailable" end
        if total - quantity < reserve then return false, "reserve" end
    end
    return true
end
function Rules:MaySort()
    if not self:Enabled() then return true end
    if not Read(Suite.db.itemKeepRules, "table") then return false end
    local relevant = {}
    for id in pairs(Suite.db.itemKeepRules) do
        local rule = self:Rule(id)
        if not rule then return false end
        if rule.pauseSort then relevant[#relevant + 1] = id end
    end
    if #relevant == 0 then return true end
    local counts = self:Counts(); if not counts then return false end
    for _, id in ipairs(relevant) do
        local count = counts[id]
        if not Suite.IsReadable(count) or count ~= nil and (not Int(count, 0, 1000000000) or count > 0) then return false end
    end
    return true
end
function Rules:MayBulkSell()
    if not self:Enabled() then return true end
    if not Read(Suite.db.itemKeepRules, "table") or not Read(self.reserves or {}, "table") then return false end
    local relevant = {}
    for id in pairs(Suite.db.itemKeepRules) do
        local rule = self:Rule(id); if not rule then return false end
        if rule.neverSell then relevant[id] = true end
    end
    for id in pairs(self.reserves or {}) do
        local reserve = self:Reserve(id)
        if reserve == nil or not Int(id, 1, 2147483647) then return false end
        if reserve > 0 then relevant[id] = true end
    end
    if next(relevant) == nil then return true end
    local counts = self:Counts(); if not counts then return false end
    for id in pairs(relevant) do
        local count = counts[id]
        if not Suite.IsReadable(count) or count ~= nil and not Int(count, 0, 1000000000) then return false end
        if count and count > 0 then
            local ok, _, _, quality = false, nil, nil, nil
            if C_Item and Read(C_Item.GetItemInfo, "function") then ok, _, _, quality = pcall(C_Item.GetItemInfo, id) end
            if not ok or not Int(quality, 0, 8) or quality == 0 then return false end
        end
    end
    return true
end
function Rules:Save(id, values, reserve)
    if InCombatLockdown() then return false, "Edit keep rules outside combat." end
    local rule = ValidRule(values)
    if not Int(id, 1, 2147483647) or not rule or not Int(reserve, 0, 100000) then return false, "Choose an item and a reserve from 0 to 100000." end
    local entries = Suite.db.itemKeepRules
    if not Read(entries, "table") then return false, "Keep rules are unavailable." end
    if not self.reserves then self:InitializeCharacter(nil) end
    if not Read(self.reserves, "table") then return false, "Reserves are unavailable." end
    local function Full(store, key)
        local existing = store[key]
        if not Suite.IsReadable(existing) then return true end
        if existing ~= nil then return false end
        local count = 0; for _ in pairs(store) do count = count + 1 end
        return count >= self.limit
    end
    local hasRule = rule.neverSell or rule.neverDelete or rule.pauseSort
    if hasRule and Full(entries, id) or reserve > 0 and Full(self.reserves, id) then return false, "Up to 256 item rules and 256 reserves are supported." end
    entries[id] = hasRule and rule or nil; self.reserves[id] = reserve > 0 and reserve or nil
    -- Editing this checkbox also owns the existing low-space blacklist entry.
    if Read(Suite.db.bagSpaceBlacklist, "table") and not rule.neverDelete then Suite.db.bagSpaceBlacklist[id] = nil end
    Suite.db.itemKeepRulesEnabled = true
    if Suite.BagSpace then Suite.BagSpace:CancelDelete() end
    if Suite.BankDeposit then Suite.BankDeposit:Cancel() end
    Suite.Apply()
    return true
end
function Rules:Usage(id)
    if not Int(id, 1, 2147483647) then return {} end
    if not self.usage then
        self.usage = {}
        for _, guide in ipairs(Suite.ProfessionGuides) do
            local byID = {}
            for _, recipe in ipairs(guide.estimates or {}) do
                for _, material in ipairs(recipe[5]) do
                    local materialID = Suite.ProfessionMaterialIDs[material[2]]
                    if Int(materialID, 1, 2147483647) then
                        byID[materialID] = byID[materialID] or {}
                        table.insert(byID[materialID], { recipe[1], recipe[2] })
                    end
                end
            end
            for materialID, ranges in pairs(byID) do
                table.sort(ranges, function(a, b) if a[1] ~= b[1] then return a[1] < b[1] end; return a[2] < b[2] end)
                local merged = {}
                for _, range in ipairs(ranges) do
                    local last = merged[#merged]
                    if last and range[1] <= last[2] then last[2] = math.max(last[2], range[2])
                    else merged[#merged + 1] = { range[1], range[2] } end
                end
                local labels = {}; for _, range in ipairs(merged) do labels[#labels + 1] = range[1] .. "–" .. range[2] end
                self.usage[materialID] = self.usage[materialID] or {}
                table.insert(self.usage[materialID], "Used for " .. guide.name .. " · guide skill " .. table.concat(labels, ", "))
            end
        end
    end
    return self.usage[id] or {}
end
function Rules:AddTooltip(tooltip, item, record)
    if not Read(tooltip.AddLine, "function") or not Suite.IsReadable(item) then return end
    local id = Int(item, 1, 2147483647) and item or Read(item, "string") and tonumber(item:match("item:(%d+)"))
    if not Int(id, 1, 2147483647) then return end
    if self:Enabled() and not record.keepDone then
        record.keepDone = true
        local rule, reserve = self:Rule(id), self:Reserve(id)
        if rule then
            local labels = {}
            if rule.neverSell then labels[#labels + 1] = "Never sell" end
            if rule.neverDelete then labels[#labels + 1] = "Never suggest deleting" end
            if rule.pauseSort then labels[#labels + 1] = "Pause auto sort" end
            if #labels > 0 then tooltip:AddLine("Keep rules: " .. table.concat(labels, " · "), 0.41, 0.84, 0.75, true) end
        end
        if reserve and reserve > 0 then tooltip:AddLine("Keep carried: " .. reserve .. " (this character)", 0.41, 0.84, 0.75, true) end
    end
    if Read(Suite.db.professionUsage, "boolean") and Suite.db.professionUsage == true and not record.usageDone then
        record.usageDone = true
        for _, line in ipairs(self:Usage(id)) do tooltip:AddLine(line, 0.7, 0.77, 0.8, true) end
    end
end
local function Label(parent, text, x, y, width, size)
    local label = parent:CreateFontString(nil, "OVERLAY"); label:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE")
    label:SetTextColor(0.88, 0.91, 0.93); label:SetPoint("TOPLEFT", x, y); label:SetWidth(width); label:SetJustifyH("LEFT"); label:SetText(text); return label
end
local function Input(parent, x, y, width, maximum)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate"); box:SetSize(width, 24); box:SetPoint("TOPLEFT", x, y)
    box:SetAutoFocus(false); box:SetFont("Fonts\\FRIZQT__.TTF", 12, ""); box:SetMaxLetters(maximum)
    box:SetScript("OnEscapePressed", function() box:ClearFocus(); parent:Hide() end); return box
end
function Rules:Rows()
    local ids, rows = {}, {}
    for _, store in ipairs({ Suite.db.itemKeepRules, self.reserves or {}, Suite.db.bagSpaceBlacklist }) do
        if Read(store, "table") then for id in pairs(store) do if Int(id, 1, 2147483647) then ids[id] = true end end end
    end
    for id in pairs(ids) do
        local name = Call(C_Item and C_Item.GetItemNameByID, id)
        local rule = self:Rule(id) or {}
        local legacyValue = Read(Suite.db.bagSpaceBlacklist, "table") and Suite.db.bagSpaceBlacklist[id]
        local legacy = Suite.IsReadable(legacyValue) and legacyValue == true
        local labels = {}
        if rule.neverSell then labels[#labels + 1] = "No sale" end
        if rule.neverDelete or legacy then labels[#labels + 1] = "No trash suggestion" end
        if rule.pauseSort then labels[#labels + 1] = "Pause auto sort" end
        local reserve = self:Reserve(id)
        if reserve and reserve > 0 then labels[#labels + 1] = "Carry ≥" .. reserve end
        rows[#rows + 1] = { id = id, title = Text(name) and name or "Item " .. id, detail = table.concat(labels, " · ") }
    end
    table.sort(rows, function(a, b) return a.id < b.id end); return rows
end
function Rules:Select(id)
    local frame, rule = self.frame, self:Rule(id)
    if not frame or not rule or InCombatLockdown() then return end
    self.loading = true
    frame.item:SetText(tostring(id)); frame.reserve:SetText(tostring(self:Reserve(id) or 0))
    self.loading = nil
    for _, flag in ipairs(flags) do frame[flag]:SetChecked(rule[flag] == true) end
    local legacy = Read(Suite.db.bagSpaceBlacklist, "table") and Suite.db.bagSpaceBlacklist[id]
    if Suite.IsReadable(legacy) and legacy == true then frame.neverDelete:SetChecked(true) end
    self.selectedID = id
    self.confirmRemove = nil
end
function Rules:HideTooltip()
    local tip, owner = self.tooltip, self.hovered
    self.tooltip, self.hovered = nil, nil
    if owner and SafeTooltip(tip) and Call(tip.GetOwner, tip) == owner and Read(tip.Hide, "function") then pcall(tip.Hide, tip) end
end
function Rules:ItemTooltip(row)
    self:HideTooltip()
    if InCombatLockdown() or not self.frame or not self.frame:IsShown() or not row:IsShown()
        or not Int(row.itemID, 1, 2147483647) then return end
    local tip = GameTooltip
    if not SafeTooltip(tip) then return end
    for _, method in ipairs({ "SetOwner", "GetOwner", "SetItemByID", "Show", "Hide" }) do
        if not Read(tip[method], "function") then return end
    end
    self.tooltip, self.hovered = tip, row
    -- Keep the item beside the pointer, rather than beyond this wide rule row.
    if not pcall(tip.SetOwner, tip, row, "ANCHOR_CURSOR") or Call(tip.GetOwner, tip) ~= row
        or not pcall(tip.SetItemByID, tip, row.itemID) or Call(tip.GetOwner, tip) ~= row then
        self:HideTooltip(); return
    end
    if not pcall(tip.Show, tip) then self:HideTooltip() end
end
function Rules:Refresh()
    local hovered, itemID = self.hovered, self.hovered and self.hovered.itemID
    self:HideTooltip()
    local frame = self.frame; if not frame or not frame:IsShown() then return end
    local combat = InCombatLockdown()
    self.rows = self:Rows(); self.page = math.max(1, math.min(self.page, math.max(1, math.ceil(#self.rows / 8))))
    for index, button in ipairs(frame.rows) do
        local row = self.rows[index + (self.page - 1) * 8]
        button.itemID = row and row.id or nil
        button:SetShown(row ~= nil); button:SetEnabled(not combat)
        if row then button:SetText(row.title); button.detail:SetText(row.detail); Suite.Items:SetListIcon(button.icon, row.id) end
    end
    frame.previous:SetEnabled(not combat and self.page > 1); frame.next:SetEnabled(not combat and self.page * 8 < #self.rows)
    frame.page:SetText(self.page .. " / " .. math.max(1, math.ceil(#self.rows / 8)))
    for _, key in ipairs({ "item", "reserve", "neverSell", "neverDelete", "pauseSort", "save", "remove", "load" }) do frame[key]:SetEnabled(not combat) end
    frame.status:SetText(combat and "Edit rules outside combat." or "Save enables keep rules. Whole stacks are retained if a reserve would be crossed.")
    frame.remove:SetText("Remove item")
    if not combat and hovered and hovered.itemID == itemID and Call(MouseIsOver, hovered) == true then self:ItemTooltip(hovered) end
end
local function ItemID(text)
    if not Read(text, "string") or #text > 512 then return end
    local id = tonumber(text:match("^%s*(%d+)%s*$") or text:match("item:(%d+)"))
    if Int(id, 1, 2147483647) then return id end
end
function Rules:Open(owner)
    if InCombatLockdown() then Suite.Print("Open keep rules outside combat."); return end
    if not self.reserves then self:InitializeCharacter(nil) end
    if not self.frame then
        local frame = CreateFrame("Frame", "WoWForeverSuiteKeepRules", UIParent, "BackdropTemplate"); self.frame = frame
        frame:SetSize(650, 620); frame:SetClampedToScreen(true); frame:SetFrameStrata("DIALOG"); frame:EnableMouse(true)
        frame:SetPoint("CENTER", UIParent, "CENTER")
        frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        frame:SetBackdropColor(0.035, 0.05, 0.065, 1); Suite.Theme:Backdrop(frame, 0.85)
        if UISpecialFrames then table.insert(UISpecialFrames, "WoWForeverSuiteKeepRules") end
        Label(frame, "Item Keep Rules", 14, -14, 580, 17)
        Label(frame, "Sell, trash and sorting rules apply to every character. Reserves belong to this character.\nAffects Suite actions only. Manual game and other-addon actions remain under your control.", 14, -47, 620, 11)
        local close = Suite.Theme:IconButton(frame, "Close keep rules", function() frame:Hide() end)
        close:SetSize(24, 24); close:SetPoint("TOPRIGHT", -8, -8)
        local function Button(text, x, y, width, callback)
            local button = Suite.Theme:ActionButton(frame, text, width, 24, function() if not InCombatLockdown() then callback() end end)
            button:SetPoint("TOPLEFT", x, y); return button
        end
        frame.rows = {}
        for index = 1, 8 do
            local button = Button("", 14, -97 - (index - 1) * 37, 620, function()
                local row = self.rows[index + (self.page - 1) * 8]; if row then self:Select(row.id) end
            end)
            button:SetHeight(34); button.label:SetJustifyH("LEFT"); button.label:ClearAllPoints(); button.label:SetPoint("TOPLEFT", 42, -2); button.label:SetWidth(570)
            button.icon = Suite.Items:CreateListIcon(button, 28, 6, -3)
            button.detail = Label(button, "", 42, -19, 570, 10); frame.rows[index] = button
            button:HookScript("OnEnter", function() self:ItemTooltip(button) end)
            button:HookScript("OnLeave", function() if self.hovered == button then self:HideTooltip() end end)
            button:HookScript("OnHide", function() if self.hovered == button then self:HideTooltip() end; button.itemID = nil end)
        end
        frame.previous = Button("Previous", 14, -403, 90, function() self.page = self.page - 1; self:Refresh() end)
        frame.next = Button("Next", 112, -403, 90, function() self.page = self.page + 1; self:Refresh() end)
        frame.page = Label(frame, "", 218, -409, 90)
        Label(frame, "Item ID or pasted link", 20, -446, 270, 11); Label(frame, "Keep carried (this character)", 328, -446, 270, 11)
        frame.item, frame.reserve = Input(frame, 20, -464, 280, 512), Input(frame, 328, -464, 190, 6)
        frame.reserve:SetText("0")
        frame.load = Button("Load item", 528, -464, 106, function()
            local id = ItemID(frame.item:GetText()); if id then self:Select(id) else frame.status:SetText("Enter an item ID or link first.") end
        end)
        local captions = { neverSell = "Never sell", neverDelete = "Never suggest deleting", pauseSort = "Pause auto sort" }
        for index, flag in ipairs(flags) do
            frame[flag] = Suite.Theme:CheckButton(frame)
            frame[flag]:SetPoint("TOPLEFT", 14 + (index - 1) * 208, -505)
            frame[flag].label = Label(frame[flag], captions[flag], 30, -5, 174, 11)
            frame[flag]:SetScript("OnClick", function() self.confirmRemove = nil; frame.remove:SetText("Remove item") end)
        end
        frame.save = Button("Save & enable", 14, -550, 142, function()
            local id = ItemID(frame.item:GetText())
            if id and self.selectedID ~= id then
                local existing, reserve, legacy = Suite.db.itemKeepRules[id], self:Reserve(id), Suite.db.bagSpaceBlacklist[id]
                if not Suite.IsReadable(existing) or not Suite.IsReadable(legacy) or reserve == nil then frame.status:SetText("This item's rules are unavailable."); return end
                if existing ~= nil or reserve > 0 or legacy == true then frame.status:SetText("Load this item's existing rules before changing them."); return end
            end
            local values = {}; for _, flag in ipairs(flags) do values[flag] = frame[flag]:GetChecked() == true end
            local ok, message = self:Save(id, values, tonumber(frame.reserve:GetText()))
            if ok then self.selectedID = id end
            self.confirmRemove = nil; self:Refresh(); frame.status:SetText(ok and "Saved. Reserves may keep extra until you split a stack manually." or message)
        end)
        frame.remove = Button("Remove item", 166, -550, 140, function()
            local id = ItemID(frame.item:GetText()); if not id then return end
            if self.confirmRemove ~= id then self.confirmRemove = id; frame.remove:SetText("Confirm remove"); return end
            self:Save(id, {}, 0); self.confirmRemove = nil; self:Refresh()
        end)
        for _, input in ipairs({ frame.item, frame.reserve }) do input:SetScript("OnTextChanged", function(box)
            if box == frame.item and not self.loading then self.selectedID = nil end
            self.confirmRemove = nil; if frame.remove then frame.remove:SetText("Remove item") end
        end) end
        frame.status = Label(frame, "", 14, -591, 620, 10)
        frame:SetScript("OnShow", function() frame:RegisterEvent("PLAYER_REGEN_DISABLED"); frame:RegisterEvent("PLAYER_REGEN_ENABLED") end)
        frame:SetScript("OnHide", function() self:HideTooltip(); frame:UnregisterAllEvents(); frame.item:ClearFocus(); frame.reserve:ClearFocus(); self.confirmRemove = nil end)
        frame:SetScript("OnEvent", function() self:Refresh() end)
        frame:Hide()
    end
    Suite.PlaceWindow(self.frame, owner); self.frame:Show(); self:Refresh()
end
function Rules:Apply()
    local enabled = self:Enabled() == true
    if self.lastEnabled ~= nil and self.lastEnabled ~= enabled and not InCombatLockdown() then
        if Suite.BagSpace then Suite.BagSpace:CancelDelete() end
        if Suite.BankDeposit then Suite.BankDeposit:Cancel() end
    end
    self.lastEnabled = enabled
    if self.frame and self.frame:IsShown() then self:Refresh() end
    if Suite.BagSpace and Suite.BagSpace.active then Suite.BagSpace:Queue() end
end
