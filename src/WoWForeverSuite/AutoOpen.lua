local _, Suite = ...
local Open = {}
Suite.AutoOpen = Open
table.insert(Suite.modules, Open)

local function Probe(fn, ...)
    if type(fn) ~= "function" then return nil, "unavailable" end
    local ok, value = pcall(fn, ...)
    if not ok then return nil, "rejected" end
    if not Suite.IsReadable(value) then return nil, "restricted" end
    return value, "readable"
end
local function Read(fn, ...)
    local value = Probe(fn, ...)
    return value
end
local function Int(value, max)
    return Suite.IsReadable(value) and type(value) == "number" and value >= 0 and value <= max and value == math.floor(value)
end
function Open:Enabled()
    return Suite.db and Suite.IsReadable(Suite.db.autoOpenContainers) and Suite.db.autoOpenContainers == true
end
local contexts = { "MerchantFrame", "BankFrame", "BankPanel", "GuildBankFrame", "MailFrame", "TradeFrame",
    "AuctionHouseFrame", "AuctionFrame", "ItemInteractionFrame", "ScrappingMachineFrame", "ItemUpgradeFrame", "LootFrame" }
function Open:Idle()
    if InCombatLockdown() then return false, "combat" end
    if self.lootOpen then return false, "waiting for loot to close" end
    if Read(UnitIsDeadOrGhost, "player") ~= false then return false, "player dead or state unavailable" end
    for _, name in ipairs(contexts) do
        local frame = _G[name]
        if not Suite.IsReadable(frame) then return false, name .. " restricted" end
        -- BankPanel stays locally shown under a hidden BankFrame. Keep checking
        -- the bank root, and use effective visibility only for this child panel.
        local method = name == "BankPanel" and "IsVisible" or "IsShown"
        if frame and Read(frame[method], frame) ~= false then return false, name .. " open or state unavailable" end
    end
    for _, name in ipairs({ "GetCursorInfo", "UnitCastingInfo", "UnitChannelInfo" }) do
        local fn = _G[name]
        if type(fn) ~= "function" then return false, name .. " unavailable" end
        local ok, value
        if name == "GetCursorInfo" then ok, value = pcall(fn) else ok, value = pcall(fn, "player") end
        if not ok or not Suite.IsReadable(value) or value ~= nil then return false, name .. " active or unavailable" end
    end
    -- Native bag code tests SpellIsTargeting by truthiness. A successful nil
    -- result means no targeting; missing/rejected/restricted calls still block.
    local targeting, state = Probe(SpellIsTargeting)
    if state ~= "readable" then return false, "SpellIsTargeting " .. state end
    if targeting ~= nil and targeting ~= false then return false, "spell targeting active" end
    if Read(GetNumLootItems) ~= 0 then return false, "loot present or count unavailable" end
    return true, "ready"
end
function Open:Bags()
    local api = C_Container
    if not api or type(api.GetContainerNumFreeSlots) ~= "function" then return nil, nil, "bag API unavailable" end
    local last = NUM_TOTAL_EQUIPPED_BAG_SLOTS
    if not Int(last, 32) then last = NUM_BAG_SLOTS end
    if not Int(last, 32) then return nil, nil, "equipped bag range unavailable" end
    local bags, free = {}, 0
    for bag = 0, last do
        local count = Read(api.GetContainerNumSlots, bag)
        if not Int(count, 200) then return nil, nil, "bag " .. bag .. " size unavailable" end
        bags[#bags + 1] = { id = bag, count = count }
        if count > 0 then
            local ok, available, family = pcall(api.GetContainerNumFreeSlots, bag)
            if not ok or not Int(available, count) or not Int(family, 2147483647) then return nil, nil, "bag " .. bag .. " space/type unavailable" end
            if family == 0 then free = free + available end
        end
    end
    if free >= 1 then return bags, free, "ready" end
    return nil, free, "no free regular bag slot"
end
function Open:Openable(info, bag, slot, inspect)
    -- Some openable items expose their native opening prompt without hasLoot.
    -- Use that exact localized signal, never an item name or a generic use spell.
    if not Suite.IsReadable(info.hasLoot) or type(info.hasLoot) ~= "boolean" then return false, "loot flag unavailable or restricted" end
    if info.hasLoot then return true, "loot flag" end
    if not Suite.IsReadable(ITEM_OPENABLE) or type(ITEM_OPENABLE) ~= "string" or ITEM_OPENABLE == "" then return false, "localized opening prompt unavailable" end
    local data, state = Probe(C_TooltipInfo and C_TooltipInfo.GetBagItem, bag, slot)
    if state ~= "readable" then return false, "bag tooltip " .. state end
    if type(data) ~= "table" then return false, "bag tooltip not ready" end
    if not Suite.IsReadable(data.id) or data.id ~= nil and data.id ~= info.itemID then return false, "tooltip item ID mismatched or restricted" end
    local lines = data.lines
    if Suite.IsReadable(lines) and type(lines) == "table" then
        for _, line in ipairs(lines) do
            if Suite.IsReadable(line) and type(line) == "table" and Suite.IsReadable(line.leftText)
                and type(line.leftText) == "string" and line.leftText == ITEM_OPENABLE then return true, "native opening prompt" end
        end
    end
    -- Sparse native tooltips can fill asynchronously. Only their own update
    -- wakes another scan; hovering unrelated UI must not cause repeated work.
    if not inspect and Int(data.dataInstanceID, 2147483647) then
        self.tooltipWait = self.tooltipWait or {}; self.tooltipWait[data.dataInstanceID] = true
    end
    return false, "native opening prompt absent, loading or restricted"
end
function Open:Candidate(bag, slot, inspect)
    local info = Read(C_Container and C_Container.GetContainerItemInfo, bag, slot)
    if type(info) ~= "table" then return nil, "empty or unreadable slot" end
    if not Suite.IsReadable(info.isLocked) or info.isLocked ~= false then return nil, "item locked or lock state unavailable" end
    if not Int(info.itemID, 10000000) or info.itemID == 0
        or not Int(info.stackCount, 1000000000) or info.stackCount == 0 then return nil, "item ID/count unavailable" end
    local location = Read(ItemLocation and ItemLocation.CreateFromBagAndSlot, ItemLocation, bag, slot)
    if not location then return nil, "item location unavailable" end
    local guid, state = Probe(C_Item and C_Item.GetItemGUID, location)
    if type(guid) ~= "string" or guid == "" then return nil, "item GUID " .. (state == "readable" and "missing" or state) end
    -- One attempt per unchanged physical stack. Sorting/moving cannot cause an
    -- unopenable lockbox or a rejected native request to loop indefinitely.
    if self.attempted and self.attempted[guid] == info.stackCount then return nil, "unchanged stack already attempted" end
    local openable, reason = self:Openable(info, bag, slot, inspect)
    if not openable then return nil, reason end
    return { bag = bag, slot = slot, id = info.itemID, count = info.stackCount, guid = guid }, reason
end
function Open:Cancel()
    for _, key in ipairs({ "timer", "settle" }) do
        if self[key] then self[key]:Cancel(); self[key] = nil end
    end
    self.inFlight = nil
    self.tooltipWait = nil
end
function Open:Run()
    if not self.active or not self:Enabled() or self.inFlight or not self:Idle() then return end
    if not C_Container or type(C_Container.UseContainerItem) ~= "function" then return end
    local bags = self:Bags()
    if not bags then return end
    self.tooltipWait = nil
    for _, bag in ipairs(bags) do
        for slot = 1, bag.count do
            local item = self:Candidate(bag.id, slot)
            if item then
                -- Recheck current slot identity, space and interaction context
                -- immediately before using it. No vendor/bank use is permitted.
                if not self:Idle() or not self:Bags() then return end
                local current = self:Candidate(item.bag, item.slot)
                if not current or current.guid ~= item.guid or current.id ~= item.id or current.count ~= item.count then return end
                self.attempted = self.attempted or {}; self.attempted[item.guid] = item.count
                self.inFlight = true
                local ok = pcall(C_Container.UseContainerItem, item.bag, item.slot)
                self.lastAttempt = { id = item.id, bag = item.bag, slot = item.slot, result = ok and "request sent; loot not confirmed" or "native request rejected" }
                if not ok then
                    self.inFlight = nil
                    self:Queue() -- Skip this attempted stack and continue with other containers.
                    return
                end
                if self.active and self:Enabled() and self.inFlight then
                    -- Bounded settling for containers that close without a loot
                    -- window (e.g. currency). This is not an idle polling timer.
                    self.settle = C_Timer.NewTimer(2, function()
                        self.settle = nil; self.inFlight = nil; self:Queue()
                    end)
                end
                return
            end
        end
    end
end
function Open:Queue()
    if not self.active or not self:Enabled() or self.timer or self.inFlight or InCombatLockdown()
        or not C_Timer or type(C_Timer.NewTimer) ~= "function" then return end
    self.timer = C_Timer.NewTimer(0.25, function() self.timer = nil; self:Run() end)
end
function Open:WatchLoot()
    if self.lootRegistry or not Suite.IsReadable(EventRegistry) or type(EventRegistry) ~= "table"
        or type(EventRegistry.RegisterCallback) ~= "function" or type(EventRegistry.UnregisterCallback) ~= "function" then return end
    self.lootRegistry = EventRegistry
    self.lootRegistry:RegisterCallback("LootFrame.Hide", self.Queue, self)
end
function Open:UnwatchLoot()
    if not self.lootRegistry then return end
    self.lootRegistry:UnregisterCallback("LootFrame.Hide", self)
    self.lootRegistry = nil
end
local function Summary(value)
    if not Suite.IsReadable(value) then return "restricted" end
    if value == nil then return "nil" end
    if type(value) == "boolean" then return value and "true" or "false" end
    if Int(value, 1000000000) then return tostring(value) end
    return "present"
end
function Open:Status(itemID)
    if not Suite.IsReadable(itemID) or itemID ~= nil and (not Int(itemID, 10000000) or itemID == 0) then
        Suite.Print("Usage: /wfs containerstatus [itemID]"); return
    end
    Suite.Print("Auto-open v" .. Suite.version .. ": enabled=" .. Summary(self:Enabled()) .. ", active=" .. Summary(self.active == true))
    local idle, reason = self:Idle()
    Suite.Print("Context: " .. reason .. "; in flight=" .. Summary(self.inFlight == true))
    if InCombatLockdown() then return end
    local targeting, state = Probe(SpellIsTargeting)
    Suite.Print("SpellIsTargeting: " .. state .. ", value=" .. Summary(targeting))
    local bags, free, bagReason = self:Bags()
    Suite.Print("Bags: " .. bagReason .. "; free regular slots=" .. Summary(free))
    local last = self.lastAttempt
    if last then Suite.Print("Last item " .. last.id .. " @ " .. last.bag .. ":" .. last.slot .. ": " .. last.result)
    else Suite.Print("No open request recorded.") end
    if not bags then return end
    local shown = 0
    for _, bag in ipairs(bags) do
        for slot = 1, bag.count do
            local info = Read(C_Container and C_Container.GetContainerItemInfo, bag.id, slot)
            if type(info) == "table" and Int(info.itemID, 10000000) and info.itemID > 0
                and (itemID == nil or info.itemID == itemID) then
                local openable, signal = self:Openable(info, bag.id, slot, true)
                if itemID or openable then
                    local item, why = self:Candidate(bag.id, slot, true)
                    Suite.Print("Item " .. info.itemID .. " @ " .. bag.id .. ":" .. slot .. ": count=" .. Summary(info.stackCount)
                        .. ", loot=" .. Summary(info.hasLoot) .. ", locked=" .. Summary(info.isLocked)
                        .. "; " .. signal .. "; " .. (item and (idle and "eligible" or "paused: " .. reason) or "stopped: " .. why))
                    shown = shown + 1
                    if shown == 5 then Suite.Print("Showing at most five item slots."); return end
                end
            end
        end
    end
    if shown == 0 then Suite.Print(itemID and "No readable carried slot matches that item ID." or "No readable openable item found. Add an item ID to inspect it.") end
end
function Open:OnEvent(event, value)
    if not self.active then return end
    if event == "PLAYER_LOGOUT" then self:Cancel(); self:UnwatchLoot(); self.active = nil; return end
    if event == "PLAYER_REGEN_DISABLED" then self:Cancel(); return end
    if event == "LOOT_OPENED" or event == "LOOT_READY" then
        -- Another synchronous loot listener may have emptied/closed this session
        -- before this handler runs. Never latch a completed session as still open.
        -- Unknown/restricted counts remain blocked; visible loot is checked by Idle.
        self.lootOpen = Read(GetNumLootItems) ~= 0 or nil
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then self.lootOpen = nil; self:Cancel() end
    if event == "TOOLTIP_DATA_UPDATE" then
        if not Suite.IsReadable(value) or not self.tooltipWait then return end
        if value ~= nil and (not Int(value, 2147483647) or not self.tooltipWait[value]) then return end
    end
    if event == "LOOT_CLOSED" then self.lootOpen = nil; self:Cancel() end
    self:Queue()
end
function Open:Apply()
    Suite.pending.autoOpen = nil
    if not self:Enabled() then
        self.active, self.lootOpen, self.attempted, self.lastAttempt = nil, nil, nil, nil; self:Cancel(); self:UnwatchLoot()
        if self.events then self.events:UnregisterAllEvents() end
        return
    end
    Suite.AfterCombat("autoOpen", function()
        if not self:Enabled() then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event, value) self:OnEvent(event, value) end)
        end
        self.active = true
        self:WatchLoot()
        for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_LOGOUT",
            "BAG_UPDATE_DELAYED", "ITEM_UNLOCKED", "LOOT_READY", "LOOT_OPENED", "LOOT_CLOSED", "MERCHANT_CLOSED",
            "BANKFRAME_CLOSED", "MAIL_CLOSED", "TRADE_CLOSED", "AUCTION_HOUSE_CLOSED", "CURSOR_CHANGED", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_CHANNEL_STOP",
            "ITEM_DATA_LOAD_RESULT", "TOOLTIP_DATA_UPDATE" }) do
            pcall(self.events.RegisterEvent, self.events, event)
        end
        self:Queue()
    end)
end
