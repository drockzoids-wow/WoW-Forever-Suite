local _, Suite = ...
local Restock = { page = 1, selected = {} }
Suite.MerchantRestock = Restock
table.insert(Suite.modules, Restock)
local function Read(v, kind) return Suite.IsReadable(v) and type(v) == kind end
local function Int(v, low, high) return Read(v, "number") and v >= low and v <= high and v % 1 == 0 end
local function Text(v) return Read(v, "string") and #v > 0 and #v <= 240 and not v:find("[%c|]") end
local function Call(fn, ...)
    if not Read(fn, "function") then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function SafeTooltip(tip)
    return Suite.IsReadable(tip) and (type(tip) == "table" or type(tip) == "userdata") and Call(tip.IsForbidden, tip) == false
end
local function Money(value)
    if not Int(value, 0, 1000000000000) then return "Unknown" end
    return string.format("%dg %ds %dc", math.floor(value / 10000), math.floor(value / 100) % 100, math.floor(value % 100))
end
local function Key(row)
    return table.concat({ row.id, row.index, row.target, row.carried or "?", row.quantity or 0,
        row.price or "?", row.bundle or "?", row.stack or "?", row.maximum or "?", row.reason or "" }, ":")
end
function Restock:Enabled() return Suite.db and Suite.IsReadable(Suite.db.merchantRestock) and Suite.db.merchantRestock == true end
function Restock:Ready()
    if not self:Enabled() or InCombatLockdown() or not Suite.Vendor:MerchantOpen() then return false end
    local guid = Call(UnitGUID, "npc")
    return Text(guid) and guid == self.merchant and Suite.IsReadable(MerchantFrame.selectedTab) and MerchantFrame.selectedTab == 1
end
function Restock:Targets()
    local targets = {}
    local entries = Suite.SupplyChecklist.db and Suite.SupplyChecklist.db.entries
    if Read(entries, "table") then for index = 1, math.min(#entries, 32) do
        local entry = entries[index]
        if Read(entry, "table") and Int(entry.id, 1, 2147483647) and Int(entry.wanted, 1, 100000) then targets[entry.id] = entry end
    end end
    return targets
end
function Restock:CanEdit()
    return self:Enabled() and not InCombatLockdown() and not self.job and self.frame and self.frame:IsShown()
end
function Restock:SaveTarget(id, wanted)
    if not self:CanEdit() then return false end
    if not Int(wanted, 1, 100000) then
        self.frame.status:SetText("Enter a target quantity from 1 to 100000.")
        return false
    end
    local supplies = Suite.SupplyChecklist
    local saved, message = supplies:Save(id, wanted)
    if not saved then self.frame.status:SetText(message); return false end
    if supplies.frame and supplies.frame:IsShown() then supplies:Refresh() end
    self.confirmRemove = nil
    self.message = "Restock target saved."
    return true
end
function Restock:ReceiveTarget()
    if not self:CanEdit() then return end
    local bundle = 1
    local id, message = Suite.SupplyChecklist:TakeCursorItem(function(index)
        -- A merchant cursor carries the offer index, not the item ID.
        if not self:Ready() then return end
        local count = Call(GetMerchantNumItems)
        if not Int(count, 1, 2000) or not Int(index, 1, count) then return end
        local info = Call(C_MerchantFrame and C_MerchantFrame.GetItemInfo, index)
        if Read(info, "table") then
            if Int(info.stackCount, 1, 100000) then bundle = info.stackCount end
        end
        return Call(GetMerchantItemID, index)
    end)
    if not id then
        if message then self.frame.status:SetText(message) end
        return
    end
    local existing = self:Targets()[id]
    if existing then
        self.message = "Already on your restock list."
    elseif not self:SaveTarget(id, bundle) then return end
    self.revealID = id
    self:Refresh()
end
function Restock:SavedRows()
    local rows = {}
    for id, entry in pairs(self:Targets()) do
        local name = Call(C_Item and C_Item.GetItemNameByID, id)
        if not Text(name) and not InCombatLockdown() and not self.requested[id] then
            self.requested[id] = true
            Call(C_Item and C_Item.RequestLoadItemDataByID, id)
        end
        rows[#rows + 1] = { id = id, name = Text(name) and name or "Item " .. id, target = entry.wanted,
            automatic = Read(entry.automatic, "boolean") and entry.automatic == true }
    end
    table.sort(rows, function(a, b) return a.name == b.name and a.id < b.id or a.name < b.name end)
    return rows
end
function Restock:RemoveTarget(id)
    if not self:CanEdit() then return end
    if self.confirmRemove ~= id then
        self.confirmRemove = id
    else
        local supplies = Suite.SupplyChecklist
        if supplies:Remove(id) and supplies.frame and supplies.frame:IsShown() then supplies:Refresh() end
        self.confirmRemove, self.selected[id], self.message = nil, nil, "Restock target removed."
    end
    self:Refresh()
end
function Restock:Offer(index)
    local id = Call(GetMerchantItemID, index)
    if not Int(id, 1, 2147483647) then return end
    local info = Call(C_MerchantFrame and C_MerchantFrame.GetItemInfo, index)
    if not Read(info, "table") then return { id = id, index = index, name = "Item " .. id, reason = "Merchant data unavailable", waiting = true } end
    local row = { id = id, index = index, name = Text(info.name) and info.name or "Item " .. id }
    row.price = Int(info.price, 0, 1000000000) and info.price or nil
    row.bundle = Int(info.stackCount, 1, 100000) and info.stackCount or nil
    row.stock = Int(info.numAvailable, -1, 1000000000) and info.numAvailable or nil
    row.maximum = Call(GetMerchantItemMaxStack, index)
    if not Int(row.maximum, 1, 100000) then row.maximum = nil end
    local ok, _, _, _, _, _, _, _, stack
    if C_Item and Read(C_Item.GetItemInfo, "function") then ok, _, _, _, _, _, _, _, stack = pcall(C_Item.GetItemInfo, id) end
    row.stack = ok and Int(stack, 1, 100000) and stack or nil
    if not row.stack and (self.visitAttempts or self.frame and self.frame:IsShown()) and not InCombatLockdown() then
        self.requested = self.requested or {}
        if not self.requested[id] then self.requested[id] = true; Call(C_Item and C_Item.RequestLoadItemDataByID, id) end
    end
    if not Suite.IsReadable(info.hasExtendedCost) or info.hasExtendedCost ~= false
        or not Suite.IsReadable(info.currencyID) or info.currencyID ~= nil and info.currencyID ~= 0
        or not Suite.IsReadable(info.spellID) or info.spellID ~= nil and info.spellID ~= 0 then
        row.reason = "Currency / special cost · buy manually"
    elseif not Suite.IsReadable(info.isPurchasable) or info.isPurchasable ~= true then row.reason = "Not purchasable"
    elseif not row.price or not row.bundle or row.stock == nil or not row.maximum or not row.stack then
        row.reason, row.waiting = "Price / item data unavailable", true
    elseif row.maximum < row.bundle or row.stack < row.bundle then row.reason = "Purchase bundle unavailable · buy manually"
    elseif row.stock == 0 then row.reason = "Out of stock" end
    return row
end
-- A fresh, complete carried-bag observation, independent of recording preferences.
-- Only general empty slots and unlocked partial stacks count as safe purchase space.
function Restock:Bags(stacks)
    local maximum = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS
    local api = C_Container
    if not Int(maximum, 0, 5) or not api or not Read(api.GetContainerNumFreeSlots, "function") then return end
    local counts, partial, empty = {}, {}, 0
    for bag = 0, maximum do
        local size = Call(api.GetContainerNumSlots, bag)
        if not Int(size, bag == 0 and 1 or 0, 200) then return end
        local free, family = 0, 0
        if size > 0 then
            local ok
            ok, free, family = pcall(api.GetContainerNumFreeSlots, bag)
            if not ok or not Int(free, 0, size) or not Int(family, 0, 2147483647) then return end
        end
        local observedFree = 0
        for slot = 1, size do
            if not Read(api.GetContainerItemInfo, "function") then return end
            local success, info = pcall(api.GetContainerItemInfo, bag, slot)
            if not success or not Suite.IsReadable(info) then return end
            if info == nil then
                if not Read(api.GetContainerItemID, "function") then return end
                local available, id = pcall(api.GetContainerItemID, bag, slot)
                if not available or not Suite.IsReadable(id) or id ~= nil then return end
                observedFree = observedFree + 1
            else
                if not Read(info, "table") or not Int(info.itemID, 1, 2147483647) or not Int(info.stackCount, 1, 100000)
                    or not Suite.IsReadable(info.isLocked) or info.isLocked ~= false then return end
                counts[info.itemID] = (counts[info.itemID] or 0) + info.stackCount
                local stack = stacks[info.itemID]
                if stack then partial[info.itemID] = (partial[info.itemID] or 0) + math.max(0, stack - info.stackCount) end
            end
        end
        if free ~= observedFree then return end
        if family == 0 then empty = empty + free end
    end
    return { counts = counts, partial = partial, empty = empty }
end
function Restock:Rows()
    if not self:Ready() then return {}, "Open a merchant's Buy tab outside combat." end
    local count = Call(GetMerchantNumItems)
    if not Int(count, 0, 2000) then return {}, "Merchant list unavailable.", true end
    local targets, offers, stacks, seen = self:Targets(), {}, {}, {}
    if not next(targets) then return offers end
    local waiting
    for index = 1, count do
        local id = Call(GetMerchantItemID, index)
        local offer = Int(id, 1, 2147483647) and targets[id] and self:Offer(index) or nil
        if offer and targets[offer.id] and not seen[offer.id] then
            -- Ambiguous duplicate offers stay manual, even if their prices differ.
            seen[offer.id] = offer; offers[#offers + 1] = offer
            if offer.stack then stacks[offer.id] = offer.stack end
        elseif offer and seen[offer.id] then
            seen[offer.id].reason, seen[offer.id].waiting = "Multiple merchant offers · buy manually", nil
        end
    end
    if #offers == 0 then return offers, nil, count == 0 end
    local bags = self:Bags(stacks)
    for _, row in ipairs(offers) do
        local target = targets[row.id]
        row.target = target.wanted
        row.automatic = Read(target.automatic, "boolean") and target.automatic == true
        waiting = waiting or row.waiting
        row.carried = bags and (bags.counts[row.id] or 0) or nil
        row.quantity, row.cost = 0, 0
        if not bags then row.reason = "Carried bags unavailable / busy"
        elseif not row.reason then
            row.need = math.max(0, row.target - row.carried)
            local capacity = (bags.partial[row.id] or 0) + bags.empty * row.stack
            local available = row.stock == -1 and row.need or row.stock
            row.quantity = math.floor(math.min(row.need, available, capacity) / row.bundle) * row.bundle
            row.cost = row.quantity / row.bundle * row.price
            if row.need == 0 then row.reason = "Stocked"
            elseif row.quantity == 0 then row.reason = capacity < row.bundle and "No safe bag space" or "Bundle would exceed target / stock"
            elseif row.quantity < row.need then row.note = "Limited by stock, bundle or bag space" end
        end
        row.key = Key(row)
    end
    table.sort(offers, function(a, b) return a.id < b.id end)
    return offers, not bags and "Carried bags unavailable / busy. No purchases allowed." or nil, waiting or not bags
end
function Restock:Stop(message)
    if self.job and self.job.pending then self.unconfirmed = self.job.pending end
    self.confirmClear = nil
    if self.timer then self.timer:Cancel(); self.timer = nil end
    if self.deadline then self.deadline:Cancel(); self.deadline = nil end
    if self.viewTimer then self.viewTimer:Cancel(); self.viewTimer = nil end
    self.job = nil
    if message then self.message = message end
end
function Restock:ReconcileUnconfirmed()
    local pending = self.unconfirmed
    if not pending or not self:Ready() then return end
    local bags, money = self:Bags({ [pending.id] = pending.entry.stack }), Call(GetMoney)
    if bags and Int(money, 0, 1000000000000) and (bags.counts[pending.id] or 0) >= pending.before + pending.quantity
        and money <= pending.money - pending.cost then self.unconfirmed, self.confirmClear = nil, nil end
end
function Restock:ClearUnconfirmed()
    if self.job or not self:Ready() then return end
    self:ReconcileUnconfirmed()
    if self.unconfirmed then
        if self.confirmClear then
            self.unconfirmed, self.confirmClear, self.selected = nil, nil, {}
            self.message = "Pending purchase cleared. Review and select items again before buying."
        else self.confirmClear = true end
    end
    self:Refresh()
end
function Restock:QueueView()
    if self.viewTimer or InCombatLockdown() or not self.frame or not self.frame:IsShown() then return end
    if not C_Timer or not Read(C_Timer.NewTimer, "function") then self:Refresh(); return end
    self.viewTimer = C_Timer.NewTimer(0.1, function()
        self.viewTimer = nil
        if self.frame and self.frame:IsShown() then self:Refresh() end
    end)
end
function Restock:Schedule()
    if self.timer or not self.job then return end
    local job = self.job
    self.timer = C_Timer.NewTimer(0.2, function()
        self.timer = nil
        if self.job == job then self:Advance(); self:Refresh() end
    end)
end
function Restock:Start(automatic)
    if self.job or self.view ~= "vendor" or not self:Ready() then return false end
    self:ReconcileUnconfirmed()
    if self.unconfirmed then self:Refresh(); return false end
    if self.viewTimer then self.viewTimer:Cancel(); self.viewTimer = nil end
    local fresh, reason = self:Rows()
    local byID = {}; for _, row in ipairs(fresh) do byID[row.id] = row end
    local entries, total = {}, 0
    for _, row in ipairs(self.rows or {}) do if self.selected[row.id] then
        local current = byID[row.id]
        if not current or current.key ~= row.key or row.reason or row.quantity <= 0 or automatic and not current.automatic then
            self.message = "Stock, targets or prices changed. Review and select again."; self:Refresh(); return false
        end
        entries[#entries + 1] = Suite.Copy(row); total = total + row.cost
    end end
    local money = Call(GetMoney)
    if reason or #entries == 0 or not Int(money, 0, 1000000000000) or total > money
        or not C_Timer or not Read(C_Timer.NewTimer, "function") or not Read(BuyMerchantItem, "function") then
        self.message = reason or "Check available gold and select an affordable purchase."
        self:Refresh(); return false
    end
    self.job = { entries = entries, index = 1, budget = total, spent = 0, requests = 0, merchant = self.merchant, automatic = automatic }
    self.message = "Buying selected items · waiting for observed bag and money changes."
    self:Advance(); self:Refresh(); return true
end
function Restock:Advance()
    local job = self.job; if not job then return end
    if not self:Ready() or self.merchant ~= job.merchant or not self.frame or not self.frame:IsShown() then self:Stop("Restocking stopped: merchant unavailable or combat."); return end
    local stacks = {}; for _, entry in ipairs(job.entries) do stacks[entry.id] = entry.stack end
    local bags, money = self:Bags(stacks), Call(GetMoney)
    if not bags and job.pending then return end
    if not bags or not Int(money, 0, 1000000000000) then self:Stop("Restocking stopped: bags or money unavailable."); return end
    if job.pending then
        local pending = job.pending
        if (bags.counts[pending.id] or 0) < pending.before + pending.quantity or money > pending.money - pending.cost then return end
        if self.deadline then self.deadline:Cancel(); self.deadline = nil end
        pending.entry.quantity = pending.entry.quantity - pending.quantity
        job.pending = nil
    end
    local entry = job.entries[job.index]
    while entry and (entry.quantity == 0 or (bags.counts[entry.id] or 0) >= entry.target) do
        job.index = job.index + 1; entry = job.entries[job.index]
    end
    if not entry then
        self:Stop("Selected purchases confirmed in your bags."); self.selected = {}
        if job.automatic then self:Refresh("confirm") end
        return
    end
    if job.requests >= 100 then self:Stop("Purchase batch limit reached. Review the remaining targets before buying again."); return end
    local currentTarget = self:Targets()[entry.id]
    local offer = self:Offer(entry.index)
    if not currentTarget or currentTarget.wanted ~= entry.target
        or job.automatic and not (Read(currentTarget.automatic, "boolean") and currentTarget.automatic == true)
        or not offer or offer.id ~= entry.id or offer.reason or offer.price ~= entry.price
        or offer.bundle ~= entry.bundle or offer.stack ~= entry.stack or offer.maximum ~= entry.maximum then
        self:Stop("Restocking stopped: target, merchant item or price changed. Review again."); return
    end
    local before = bags.counts[entry.id] or 0
    local capacity = (bags.partial[entry.id] or 0) + bags.empty * entry.stack
    local stock = offer.stock == -1 and entry.quantity or offer.stock
    local quantity = math.floor(math.min(entry.quantity, entry.target - before, stock, entry.maximum, capacity) / entry.bundle) * entry.bundle
    if quantity <= 0 then self:Stop("Restocking stopped: no safe space or purchasable bundle remains."); return end
    local cost = quantity / entry.bundle * entry.price
    if cost > money or job.spent + cost > job.budget then self:Stop("Restocking stopped: available gold or planned total reached."); return end
    job.pending = { id = entry.id, entry = entry, before = before, quantity = quantity, cost = cost, money = money }
    job.spent = job.spent + cost
    job.requests = job.requests + 1
    self.deadline = C_Timer.NewTimer(4, function()
        if self.job == job then self:Stop("Purchase not confirmed. Stopped; check your bags before trying again."); self:Refresh() end
    end)
    local ok = pcall(BuyMerchantItem, entry.index, quantity)
    if not ok then self:Stop("The game rejected the purchase. Restocking stopped.") end
end
function Restock:HideTooltip()
    local tip, row = self.tooltip, self.hovered
    self.tooltip, self.hovered = nil, nil
    if row and SafeTooltip(tip) and Call(tip.GetOwner, tip) == row and Read(tip.Hide, "function") then pcall(tip.Hide, tip) end
end
function Restock:Tooltip(button)
    self:HideTooltip()
    local tip, row = GameTooltip, button.entry
    if InCombatLockdown() or not self.frame or not self.frame:IsShown() or not button:IsShown() or not row or not SafeTooltip(tip) then return end
    for _, method in ipairs({ "SetOwner", "GetOwner", "SetItemByID", "Show", "Hide" }) do if not Read(tip[method], "function") then return end end
    self.tooltip, self.hovered = tip, button
    if not pcall(tip.SetOwner, tip, button, "ANCHOR_CURSOR") or Call(tip.GetOwner, tip) ~= button
        or not pcall(tip.SetItemByID, tip, row.id) or Call(tip.GetOwner, tip) ~= button or not pcall(tip.Show, tip) then self:HideTooltip() end
end
local function Label(parent, text, x, y, width, size)
    local label = parent:CreateFontString(nil, "OVERLAY"); label:SetFont("Fonts\\FRIZQT__.TTF", size or 11, "")
    label:SetPoint("TOPLEFT", x, y); label:SetWidth(width); label:SetTextColor(0.88, 0.91, 0.93); label:SetJustifyH("LEFT"); label:SetText(text)
    return label
end
function Restock:Refresh(selection)
    self:HideTooltip()
    if not self.frame or not self.frame:IsShown() then return end
    if InCombatLockdown() then self:Stop("Paused in combat. Review again afterward.") end
    self:ReconcileUnconfirmed()
    local frame = self.frame
    local editing, ready, vendor = self:CanEdit(), self:Ready(), self.view == "vendor"
    frame.dropTarget:SetEnabled(editing)
    frame.listTab:SetEnabled(editing and vendor)
    frame.vendorTab:SetEnabled(editing and ready and not vendor)
    for _, control in ipairs(frame.vendorControls) do control:SetShown(vendor) end
    local old = {}; for _, row in ipairs(self.rows or {}) do old[row.id] = row.key end
    local reason
    if vendor then self.rows, reason = self:Rows() else self.rows = {} end
    if selection then self.selected = {} end
    for _, row in ipairs(self.rows) do
        if selection then
            self.selected[row.id] = not row.reason and row.quantity > 0
                and (selection == "all" or row.automatic == (selection == "automatic")) or nil
        elseif not self.job and row.key ~= old[row.id] then self.selected[row.id] = nil end
    end
    local rows = vendor and self.rows or self:SavedRows()
    if self.revealID then
        for index, row in ipairs(rows) do
            if row.id == self.revealID then self.page = math.ceil(index / 8); break end
        end
        self.revealID = nil
    end
    self.page = math.max(1, math.min(self.page, math.max(1, math.ceil(#rows / 8))))
    local total, quantity = 0, 0
    for _, row in ipairs(self.rows) do if self.selected[row.id] and not row.reason then total, quantity = total + row.cost, quantity + row.quantity end end
    for index, button in ipairs(self.frame.rows) do
        local row = rows[index + (self.page - 1) * 8]
        if not row or not button.entry or button.entry.id ~= row.id or not editing then button.target:ClearFocus() end
        button.entry = row; button:SetShown(row ~= nil)
        button:SetEnabled(row ~= nil and editing)
        button.target:SetEnabled(row ~= nil and editing)
        button.automatic:SetShown(row ~= nil)
        button.automatic:SetEnabled(row ~= nil and editing)
        button.remove:SetShown(row ~= nil and not vendor)
        button.remove:SetEnabled(row ~= nil and editing)
        button.carried:SetShown(vendor); button.buy:SetShown(vendor); button.cost:SetShown(vendor); button.note:SetShown(vendor)
        if row then
            button.automatic:SetChecked(row.automatic)
            Suite.Items:SetListIcon(button.icon, row.id)
            local mark = vendor and not row.reason and (self.selected[row.id] and "[x] " or "[ ] ") or ""
            button.name:SetText(mark .. row.name)
            button.remove:SetText(self.confirmRemove == row.id and "Confirm" or "Remove")
            if not Call(button.target.HasFocus, button.target) then button.target:SetText(tostring(row.target)) end
        end
        if row and vendor then
            button.carried:SetText(row.carried or "?")
            button.buy:SetText(row.quantity); button.cost:SetText(row.reason and "—" or Money(row.cost))
            button.note:SetText(row.reason or (row.bundle > 1 and "Sold in bundles of " .. row.bundle .. " · " or "") .. Money(row.price) .. " / " .. row.bundle .. (row.note and " · " .. row.note or ""))
        end
    end
    local money = Call(GetMoney)
    self.frame.total:SetText(self.job and ("Reviewed budget: " .. Money(self.job.budget) .. " · Requested: " .. Money(self.job.spent) .. " · Available: " .. Money(money))
        or "Selected: " .. quantity .. " items · " .. Money(total) .. "    Available: " .. Money(money))
    self.frame.buy:SetText(quantity > 0 and ("Buy " .. quantity .. (quantity == 1 and " item" or " items")) or "Buy selected")
    self.frame.buy:SetEnabled(editing and vendor and ready and not self.unconfirmed and quantity > 0 and Int(money, 0, 1000000000000) and total <= money)
    self.frame.clearPending:SetShown(vendor and self.unconfirmed ~= nil)
    self.frame.clearPending:SetEnabled(vendor and self.unconfirmed ~= nil and ready)
    self.frame.clearPending:SetText(self.confirmClear and "Confirm clear" or "Clear pending purchase")
    self.frame.stop:SetEnabled(self.job ~= nil)
    self.frame.select:SetEnabled(editing and vendor and ready)
    self.frame.previous:SetEnabled(not self.job and not InCombatLockdown() and self.page > 1)
    self.frame.next:SetEnabled(not self.job and not InCombatLockdown() and self.page * 8 < #rows)
    self.frame.page:SetText(self.page .. " / " .. math.max(1, math.ceil(#rows / 8)))
    if not vendor then
        frame.status:SetText(InCombatLockdown() and "Editing pauses in combat."
            or self.message or (#rows == 0 and "Drop an item above to start your restock list."
                or "Press Enter to save a quantity. Automatic Purchase applies on future vendor visits."))
        return
    end
    self.frame.status:SetText((self.confirmClear and "Check bags and gold first. Clearing a purchase that is still pending can lead to a duplicate.")
        or (self.unconfirmed and "Previous purchase unconfirmed. Wait for bag and gold updates, or check them before clearing.")
        or reason
        or (not self.job and quantity > 0 and Int(money, 0, 1000000000000) and total > money and "Not enough gold for the selected items.")
        or self.message or (#self.rows == 0 and "Drop an item above to add a restock target." or "Review the selected quantities and cost before buying."))
end
function Restock:Open(owner, selection)
    if not self:Enabled() then Suite.Print("Enable Merchant restocking in /wfs supplies first."); return end
    if InCombatLockdown() then Suite.Print("Open Restock outside combat."); return end
    self:CancelVisit()
    self:Stop()
    if not self.frame then
        local frame = CreateFrame("Frame", "WoWForeverSuiteRestock", UIParent, "BackdropTemplate"); self.frame = frame
        frame:SetSize(740, 520); frame:SetPoint("CENTER", UIParent, "CENTER"); frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true)
        frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        frame:SetBackdropColor(0.035, 0.05, 0.065, 1); Suite.Theme:Backdrop(frame, 0.85)
        if UISpecialFrames then table.insert(UISpecialFrames, "WoWForeverSuiteRestock") end
        Label(frame, "Restock", 16, -14, 650, 17)
        local close = Suite.Theme:IconButton(frame, "Close restocking", function() frame:Hide() end)
        close:SetPoint("TOPRIGHT", -8, -8); close:SetSize(24, 24)
        local function Button(text, x, y, width, callback)
            local button = Suite.Theme:ActionButton(frame, text, width, 26, function() if not InCombatLockdown() then callback() end end)
            button:SetPoint("TOPLEFT", x, y); return button
        end
        local function View(view)
            if not self:CanEdit() or view == "vendor" and not self:Ready() then return end
            self.view, self.page, self.message, self.confirmRemove = view, 1, nil, nil
            self:Refresh()
        end
        frame.listTab = Button("Saved list", 16, -47, 108, function() View("list") end)
        frame.vendorTab = Button("Vendor offers", 132, -47, 128, function() View("vendor") end)
        frame.dropTarget = Button("Drop an item to add it", 426, -47, 298, function() self:ReceiveTarget() end)
        frame.dropTarget:SetScript("OnReceiveDrag", function() self:ReceiveTarget() end)
        frame.vendorControls = {}
        for _, column in ipairs({ { "ITEM", 54, 250 }, { "CARRIED", 320, 60 }, { "TARGET", 390, 60 }, { "BUY", 460, 60 }, { "COST", 530, 96 } }) do
            local label = Label(frame, column[1], column[2], -90, column[3], 10)
            if column[2] > 54 then label:SetJustifyH("RIGHT") end
            if column[1] ~= "ITEM" and column[1] ~= "TARGET" then table.insert(frame.vendorControls, label) end
        end
        Label(frame, "Automatic\nPurchase", 638, -80, 82, 10):SetJustifyH("CENTER")
        frame.rows = {}
        for index = 1, 8 do
            local button
            button = Button("", 16, -109 - (index - 1) * 36, 708, function()
                local row = button.entry
                if row and Suite.Items:ModifiedClick(row.id, "LeftButton") then return end
                if row and self.view == "vendor" and not row.reason and not self.job then
                    self.selected[row.id] = not self.selected[row.id]; self.message = nil; self:Refresh()
                end
            end)
            button:SetHeight(34); button.label:Hide()
            if Read(button.SetMotionScriptsWhileDisabled, "function") then button:SetMotionScriptsWhileDisabled(true) end
            button.icon = Suite.Items:CreateListIcon(button, 26, 2, -4)
            button.name = Label(button, "", 38, -3, 260, 12)
            button.name:SetWordWrap(false); button.name:SetHeight(16)
            button.carried = Label(button, "", 304, -4, 60)
            local target = CreateFrame("EditBox", nil, button, "InputBoxTemplate")
            target:SetPoint("TOPLEFT", 374, -5); target:SetSize(60, 22)
            target:SetAutoFocus(false); target:SetMaxLetters(6); target:SetNumeric(true)
            target:SetScript("OnEnterPressed", function(box)
                local row, value = button.entry, box:GetText()
                if row and self:SaveTarget(row.id, Text(value) and tonumber(value)) then
                    box:ClearFocus(); self:Refresh()
                end
            end)
            target:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
            target:SetScript("OnEditFocusLost", function(box)
                if button.entry then box:SetText(tostring(button.entry.target)) end
            end)
            button.target = target
            button.buy = Label(button, "", 444, -4, 60); button.buy:SetTextColor(1, 0.64, 0.4)
            button.cost = Label(button, "", 514, -4, 96)
            for _, label in ipairs({ button.carried, button.target, button.buy, button.cost }) do label:SetJustifyH("RIGHT") end
            button.note = Label(button, "", 38, -22, 580, 10); button.note:SetTextColor(0.6, 0.72, 0.76)
            button.remove = Suite.Theme:ActionButton(button, "Remove", 86, 22, function()
                if self.view == "list" and button.entry then self:RemoveTarget(button.entry.id) end
            end)
            button.remove:SetPoint("TOPLEFT", 518, -6)
            local automatic = Suite.Theme:CheckButton(button)
            automatic:SetPoint("RIGHT", -34, 0)
            automatic:RegisterForClicks("LeftButtonUp")
            automatic:SetScript("OnClick", function(check)
                local row = button.entry
                if not row or not self:CanEdit() then return end
                local target = self:Targets()[row.id]
                if not target then return end
                target.automatic = Call(check.GetChecked, check) == true or nil
                self.message = target.automatic and "This item will be purchased automatically on future visits."
                    or "This item now requires confirmation."
                self:Refresh()
            end)
            button.automatic = automatic
            button:HookScript("OnEnter", function() self:Tooltip(button) end)
            button:HookScript("OnLeave", function() if self.hovered == button then self:HideTooltip() end end)
            button:HookScript("OnHide", function() if self.hovered == button then self:HideTooltip() end end)
            frame.rows[index] = button
        end
        frame.previous = Button("Previous", 16, -404, 90, function() self.page = self.page - 1; self.confirmRemove = nil; self:Refresh() end)
        frame.next = Button("Next", 114, -404, 90, function() self.page = self.page + 1; self.confirmRemove = nil; self:Refresh() end)
        frame.page = Label(frame, "", 220, -412, 80)
        frame.total = Label(frame, "", 16, -438, 704, 12)
        frame.buy = Button("Buy selected", 16, -455, 144, function() self:Start() end)
        frame.stop = Button("Stop", 168, -455, 80, function() self:Stop("Stopped future purchases. An in-flight purchase may still finish."); self:Refresh() end)
        frame.select = Button("Select available", 256, -455, 154, function() self:Refresh("all") end)
        frame.clearPending = Button("Clear pending purchase", 418, -455, 200, function() self:ClearUnconfirmed() end)
        local skip = Button("Skip", 626, -455, 98, function() frame:Hide() end)
        for _, control in ipairs({ frame.total, frame.buy, frame.stop, frame.select, skip }) do
            table.insert(frame.vendorControls, control)
        end
        frame.status = Label(frame, "", 16, -490, 704, 10); frame.status:SetHeight(25)
        frame:SetScript("OnHide", function()
            self:HideTooltip(); self:Stop(); self.confirmRemove = nil
            for _, row in ipairs(frame.rows) do row.target:ClearFocus() end
        end)
        frame:Hide()
    end
    self.selected, self.rows, self.page, self.message, self.requested = {}, {}, 1, nil, {}
    self.confirmRemove = nil
    local ready = self:Ready()
    self.view = ready and "vendor" or "list"
    if (not ready or not Suite.PlaceWindow(self.frame, MerchantFrame)) and owner and owner ~= MerchantFrame then
        Suite.PlaceWindow(self.frame, owner)
    end
    self.frame:Show(); self:Refresh(selection)
    return true
end
function Restock:Launcher()
    if InCombatLockdown() then return end
    if not self:Ready() then if self.launcher then self.launcher:Hide() end; return end
    if not self.launcher then
        self.launcher = Suite.Theme:ActionButton(MerchantFrame, "Restock", 86, 22, function() self:Open(MerchantFrame) end)
        self.launcher:SetPoint("TOPRIGHT", -42, -5)
    end
    self.launcher:Show()
end
function Restock:CancelVisit()
    self.visitAttempts = nil
    if self.launchTimer then self.launchTimer:Cancel(); self.launchTimer = nil end
end
function Restock:QueueVisit()
    self.launchTimer = C_Timer.NewTimer(0.25, function()
        self.launchTimer = nil
        if self.visitAttempts then self:ReviewVisit() end
    end)
end
function Restock:ReviewVisit()
    if not self:Enabled() or InCombatLockdown() then self:CancelVisit(); return end
    if not self.merchant and Suite.Vendor:MerchantOpen() then
        local guid = Call(UnitGUID, "npc")
        self.merchant = Text(guid) and guid or nil
    end
    local ready = self:Ready()
    if ready then self:Launcher() end
    local rows, _, waiting = self:Rows()
    local automatic, missing
    for _, row in ipairs(rows) do
        if row.carried == nil or row.carried < row.target then missing = true end
        if row.automatic and not row.reason and row.quantity > 0 then automatic = true end
    end
    local vendorBusy = automatic and (Suite.Vendor.working or Suite.Vendor.timer)
    if (not ready or waiting or vendorBusy) and self.visitAttempts < 8
        and C_Timer and Read(C_Timer.NewTimer, "function") then
        self.visitAttempts = self.visitAttempts + 1
        self:QueueVisit()
        return
    end
    self:CancelVisit()
    if not ready or not missing then return end
    self:ReconcileUnconfirmed()
    if automatic and not vendorBusy and not waiting and not self.unconfirmed then
        if self:Open(MerchantFrame, "automatic") and not self:Start(true) then self:Refresh("all") end
    else
        self:Open(MerchantFrame, "all")
    end
end
function Restock:OnEvent(event)
    if event == "MERCHANT_SHOW" then
        local guid = Call(UnitGUID, "npc")
        if self.visitOpen and Text(guid) and self.merchant == guid then return end
        self:CancelVisit()
        if self.frame and self.view == "vendor" then self.frame:Hide() end
        self:Stop()
        self.visitOpen, self.merchant, self.requested = true, Text(guid) and guid or nil, {}
        self.visitAttempts = 1
        -- Let the native panel lay out and the initial vendor tasks run first.
        if C_Timer and Read(C_Timer.NewTimer, "function") then self:QueueVisit() else self:ReviewVisit() end
    elseif event == "MERCHANT_CLOSED" then
        self:CancelVisit()
        self:Stop(); self.visitOpen, self.merchant, self.requested = nil, nil, {}; self:HideTooltip()
        if self.frame and self.view == "vendor" then self.frame:Hide()
        elseif self.frame and self.frame:IsShown() then self:Refresh() end
        if self.launcher then self.launcher:Hide() end
    elseif event == "PLAYER_REGEN_DISABLED" then
        self:CancelVisit()
        self:Stop("Restocking stopped in combat."); self:Refresh()
    elseif event == "UI_ERROR_MESSAGE" then
        if self.job then self:Stop("The game reported an error. Restocking stopped; check bags and merchant stock."); self:Refresh() end
    elseif self.job then self:Schedule()
    elseif self.frame and self.frame:IsShown() then self:QueueView() end
    if event == "PLAYER_REGEN_ENABLED" or event == "MERCHANT_UPDATE" then self:Launcher() end
end
function Restock:Apply()
    if not self:Enabled() then
        Suite.pending.merchantRestock = nil
        self:CancelVisit()
        self.visitOpen = nil
        self:Stop(); self:HideTooltip()
        if self.events then self.events:UnregisterAllEvents() end
        if self.frame then self.frame:Hide() end
        if self.launcher then self.launcher:Hide() end
        return
    end
    Suite.AfterCombat("merchantRestock", function()
        if not self:Enabled() then return end
        if not self.events then
            self.events = CreateFrame("Frame"); self.events:SetScript("OnEvent", function(_, event) self:OnEvent(event) end)
        end
        self.events:UnregisterAllEvents()
        for _, event in ipairs({ "MERCHANT_SHOW", "MERCHANT_CLOSED", "MERCHANT_UPDATE", "BAG_UPDATE_DELAYED", "PLAYER_MONEY", "ITEM_DATA_LOAD_RESULT", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "UI_ERROR_MESSAGE" }) do self.events:RegisterEvent(event) end
        local guid = Call(UnitGUID, "npc"); self.merchant = Suite.Vendor:MerchantOpen() and Text(guid) and guid or nil
        self:Launcher()
    end)
end
