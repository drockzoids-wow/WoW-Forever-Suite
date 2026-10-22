local _, Suite = ...
local Vendor = { interval = 0.2, buybackLimit = 12 }
Suite.Vendor = Vendor
table.insert(Suite.modules, Vendor)

local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end

local function Read(callback, ...)
    if type(callback) ~= "function" then return nil end
    return callback(...)
end

local function Yes(value)
    return Suite.IsReadable(value) and value == true
end

local function Enabled()
    return Suite.db and (Suite.db.autoRepair or Suite.db.autoSellJunk)
end

function Vendor:Normalize()
    if Suite.db.repairSource ~= "personal" and Suite.db.repairSource ~= "guild" then Suite.db.repairSource = "personal" end
    if Suite.db.junkMode ~= "slow" and Suite.db.junkMode ~= "instant" then Suite.db.junkMode = "slow" end
end

function Vendor:MerchantOpen()
    if not MerchantFrame or type(MerchantFrame.IsShown) ~= "function" or not Yes(MerchantFrame:IsShown()) then return false end
    local kind = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.Merchant
    if not Number(kind) then return false end
    return Yes(Read(C_PlayerInteractionManager and C_PlayerInteractionManager.IsInteractingWithNpcOfType, kind))
end

function Vendor:CancelTimer()
    if self.timer then self.timer:Cancel(); self.timer = nil end
end

function Vendor:EndVisit()
    Suite.Journey:ReconcileVendor(Suite.Leveling, true)
    self:CancelTimer()
    self.visit = nil
    self.eventPending = nil
end

function Vendor:BeginVisit()
    self:EndVisit()
    self.visit = { sent = 0 }
    self:Queue(0.1)
end

function Vendor:Notice(key, text)
    if self.visit and self.visit[key] ~= text then
        self.visit[key] = text
        Suite.Print(text)
    end
end

function Vendor:Repair()
    local visit = self.visit
    if not Suite.db.autoRepair or visit.repairRequested then return end
    if type(GetRepairAllCost) ~= "function" or type(RepairAllItems) ~= "function"
        or not Yes(Read(CanMerchantRepair)) then return end
    local cost, canRepair = GetRepairAllCost()
    if not Number(cost) or cost <= 0 or not Yes(canRepair) then return end
    local guild = Suite.db.repairSource == "guild"
    if guild then
        local permission = Read(CanGuildBankRepair)
        local funds, allowance = Read(GetGuildBankMoney), Read(GetGuildBankWithdrawMoney)
        if not Yes(permission) or not Number(funds) or not Number(allowance) or funds < cost
            or (allowance ~= -1 and allowance < cost) then
            self:Notice("repairNotice", "Guild repair skipped: permission or sufficient guild funds are unavailable.")
            return
        end
    else
        local money = Read(GetMoney)
        if not Number(money) or money < cost then
            self:Notice("repairNotice", "Personal repair skipped: not enough available gold.")
            return
        end
    end
    -- The native guild path can charge personal gold for a shortfall. Require full guild coverage first.
    visit.repairRequested = true
    local journal = Suite.Journey:BeginVendor("repair", nil, cost, guild)
    RepairAllItems(guild)
    Suite.Journey:EndVendor(journal)
end

function Vendor:BagExcluded(bag)
    local api = C_Container or {}
    local excluded
    if bag == 0 then
        if type(api.GetBackpackSellJunkDisabled) ~= "function" then return true end
        excluded = api.GetBackpackSellJunkDisabled()
    else
        local flag = Enum and Enum.BagSlotFlags and Enum.BagSlotFlags.ExcludeJunkSell
        if not Number(flag) or type(api.GetBagSlotFlag) ~= "function" then return true end
        excluded = api.GetBagSlotFlag(bag, flag)
    end
    return not Suite.IsReadable(excluded) or excluded ~= false
end

function Vendor:JunkInfo(bag, slot)
    if self:BagExcluded(bag) then return nil end
    local info = Read(C_Container and C_Container.GetContainerItemInfo, bag, slot)
    if not Suite.IsReadable(info) or type(info) ~= "table" then return nil end
    if not Number(info.itemID) or info.itemID <= 0 or not Number(info.stackCount) or info.stackCount <= 0
        or not Suite.IsReadable(info.quality) or info.quality ~= 0
        or not Suite.IsReadable(info.isLocked) or info.isLocked ~= false
        or not Suite.IsReadable(info.hasNoValue) or info.hasNoValue ~= false then return nil end
    return info
end

function Vendor:SnapshotJunk()
    local queue = {}
    local api = C_Container or {}
    local last = NUM_TOTAL_EQUIPPED_BAG_SLOTS
    if not Number(last) then last = NUM_BAG_SLOTS end
    if not Number(last) then last = 4 end
    for bag = 0, math.min(5, last) do
        if not self:BagExcluded(bag) then
            local slots = Read(api.GetContainerNumSlots, bag)
            if Number(slots) then
                for slot = 1, math.min(200, slots) do
                    local info = self:JunkInfo(bag, slot)
                    if info then queue[#queue + 1] = { bag = bag, slot = slot, id = info.itemID, count = info.stackCount } end
                end
            end
        end
    end
    return queue
end

function Vendor:SlowSale()
    local visit, api = self.visit, C_Container or {}
    if visit.slowDone then return end
    if type(api.UseContainerItem) ~= "function" or type(api.GetContainerItemInfo) ~= "function" then
        visit.slowDone = true
        self:Notice("saleNotice", "Slow junk selling is unavailable on this client.")
        return
    end
    local pending = visit.pendingSale
    if pending then
        local info = api.GetContainerItemInfo(pending.bag, pending.slot)
        if not Suite.IsReadable(info) or (info ~= nil and (type(info) ~= "table"
            or not Number(info.itemID) or not Number(info.stackCount))) then
            visit.slowDone = true
            self:Notice("saleNotice", "Slow junk selling stopped: bag data is unavailable.")
            return
        end
        if info and info.itemID == pending.id and info.stackCount == pending.count then
            pending.waits = pending.waits + 1
            if pending.waits < 10 then return self.interval end
            visit.slowDone = true
            self:Notice("saleNotice", "Slow junk selling stopped: the vendor did not complete the last sale.")
            return
        end
        visit.pendingSale = nil
    end
    if visit.sent >= self.buybackLimit then
        visit.slowDone = true
        self:Notice("saleNotice", "Slow junk selling stopped after 12 stacks. Buyback keeps only the last 12 sales; remaining junk stays in your bags.")
        return
    end
    -- Never turn a vendor sale into an item use or a manual single-item repair.
    local cursor, repairing = Read(CursorHasItem), Read(InRepairMode)
    if not Suite.IsReadable(cursor) or cursor ~= false or not Suite.IsReadable(repairing) or repairing ~= false then return end
    if not visit.queue then visit.queue, visit.nextItem = self:SnapshotJunk(), 1 end
    while visit.nextItem <= #visit.queue do
        local item = visit.queue[visit.nextItem]
        visit.nextItem = visit.nextItem + 1
        local info = self:JunkInfo(item.bag, item.slot)
        -- Revalidate the current slot immediately; sorting/replacing a queued item must not sell its replacement.
        if info and info.itemID == item.id and info.stackCount == item.count then
            item.waits = 0
            visit.pendingSale = item
            visit.sent = visit.sent + 1
            local journal = Suite.Journey:BeginVendor("sale", { item })
            api.UseContainerItem(item.bag, item.slot)
            Suite.Journey:EndVendor(journal)
            return self.interval
        end
    end
    visit.slowDone = true
    if visit.sent > 0 then self:Notice("saleNotice", "Slow junk selling finished. Sold items can be recovered from Buyback until displaced by later sales.") end
end

function Vendor:InstantAvailable()
    local api = C_MerchantFrame or {}
    if type(api.SellAllJunkItems) ~= "function" or type(api.GetNumJunkItems) ~= "function"
        or not Yes(Read(api.IsSellAllJunkEnabled)) then return false end
    local count = api.GetNumJunkItems()
    return Number(count) and count > 0
end

function Vendor:SellInstant(callback)
    if not Suite.db or not Suite.db.autoSellJunk or Suite.db.junkMode ~= "instant"
        or InCombatLockdown() or not self:MerchantOpen() or not self:InstantAvailable() then return false end
    if self.visit then self.visit.fastSold = true end
    local journal = Suite.Journey:BeginVendor("sale", self:SnapshotJunk())
    if callback then callback() else C_MerchantFrame.SellAllJunkItems() end
    Suite.Journey:EndVendor(journal)
    self:Queue(0.1)
    return true
end

function Vendor:AcceptNativeJunkPopup(data)
    if not Suite.IsReadable(data) or type(data) ~= "table" then return end
    local callback = data.callback
    if not Suite.IsReadable(callback) or type(callback) ~= "function"
        or type(MerchantFrame_OnSellAllJunkButtonConfirmed) ~= "function"
        or callback ~= MerchantFrame_OnSellAllJunkButtonConfirmed then return end
    -- This shared popup also serves unrelated actions. Recognize only Blizzard's exact junk-sale callback.
    if type(StaticPopup_Hide) ~= "function" or not self:SellInstant(callback) then return end
    StaticPopup_Hide("GENERIC_CONFIRMATION", data)
end

function Vendor:InstallPopupHook()
    if self.popupHooked or InCombatLockdown() or not Suite.db.autoSellJunk or Suite.db.junkMode ~= "instant"
        or type(StaticPopup_ShowCustomGenericConfirmation) ~= "function" then return end
    hooksecurefunc("StaticPopup_ShowCustomGenericConfirmation", function(data) self:AcceptNativeJunkPopup(data) end)
    self.popupHooked = true
end

function Vendor:Work()
    if not Enabled() or not self.visit or InCombatLockdown() or not self:MerchantOpen() then return end
    Suite.Journey:ReconcileVendor(Suite.Leveling)
    self:Repair()
    if not self.visit or not Suite.db.autoSellJunk then return end
    if Suite.db.junkMode == "instant" then
        self:InstallPopupHook()
        if not self.visit.fastSold then self:SellInstant() end
    else return self:SlowSale() end
end

function Vendor:Queue(delay)
    -- MERCHANT_SHOW can precede the native window's show handler. Validate visibility at execution time.
    if not Enabled() or not self.visit or InCombatLockdown() then return end
    if self.working then self.eventPending = true; return end
    if self.timer or not C_Timer or type(C_Timer.NewTimer) ~= "function" then return end
    local visit = self.visit
    self.timer = C_Timer.NewTimer(delay or 0.05, function()
        self.timer = nil
        if self.visit ~= visit then return end
        self.working = true
        local again = self:Work()
        self.working = nil
        if not again and self.eventPending then again = 0.05 end
        self.eventPending = nil
        if again then self:Queue(again) end
    end)
end

function Vendor:Apply()
    self:Normalize()
    Suite.pending.vendor = nil
    if not Enabled() then
        self:EndVisit()
        if self.events then self.events:UnregisterAllEvents() end
        self.settings = nil
        return
    end
    local settings = { repair = Suite.db.autoRepair, source = Suite.db.repairSource,
        junk = Suite.db.autoSellJunk, mode = Suite.db.junkMode }
    local old = self.settings
    self.settings = settings
    if self.visit and old then
        if old.repair ~= settings.repair or old.source ~= settings.source then
            self.visit.repairRequested, self.visit.repairNotice = nil, nil
        end
        if old.junk ~= settings.junk or old.mode ~= settings.mode then
            self:CancelTimer()
            self.visit.queue, self.visit.pendingSale, self.visit.nextItem = nil, nil, nil
            self.visit.slowDone, self.visit.fastSold, self.visit.saleNotice = nil, nil, nil
        end
    end
    Suite.AfterCombat("vendor", function()
        if not Enabled() then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event)
                if event == "MERCHANT_SHOW" then self:BeginVisit()
                elseif event == "MERCHANT_CLOSED" or event == "PLAYER_ENTERING_WORLD" then self:EndVisit()
                elseif event == "PLAYER_REGEN_DISABLED" then
                    self:CancelTimer()
                else
                    if event == "ADDON_LOADED" then self:InstallPopupHook() end
                    self:Queue()
                end
            end)
        end
        self:InstallPopupHook()
        for _, event in ipairs({ "ADDON_LOADED", "MERCHANT_SHOW", "MERCHANT_CLOSED", "MERCHANT_UPDATE", "PLAYER_MONEY",
            "GUILDBANK_UPDATE_MONEY", "GUILDBANK_UPDATE_WITHDRAWMONEY",
            "BAG_UPDATE_DELAYED", "ITEM_LOCK_CHANGED", "BAG_SLOT_FLAGS_UPDATED", "PLAYER_REGEN_DISABLED",
            "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD" }) do self.events:RegisterEvent(event) end
        if self:MerchantOpen() then
            if not self.visit then self:BeginVisit() else self:Queue() end
        else self:EndVisit() end
    end)
end
