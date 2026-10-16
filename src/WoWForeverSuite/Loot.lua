local _, Suite = ...
local Loot = {}
Suite.Loot = Loot
table.insert(Suite.modules, Loot)

local function Enabled()
    return Suite.db and Suite.IsReadable(Suite.db.quickLoot) and Suite.db.quickLoot == true
end

local function Count(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value
        and value >= 0 and value <= 1000 and value == math.floor(value)
end

function Loot:Ready(autoLoot)
    if not self.active or not Enabled() then return end
    local visit = self.visit
    if not visit then visit = {}; self.visit = visit end
    -- The engine supplies the effective setting, including the player's auto-loot modifier.
    if not Suite.IsReadable(autoLoot) or autoLoot ~= true then visit.blocked = true end
    if visit.blocked or visit.requested then return end
    if type(GetNumLootItems) ~= "function" or type(GetLootSlotType) ~= "function" or type(LootSlot) ~= "function" then
        local callback = C_LootFrame and C_LootFrame.TryAutoLoot
        if type(callback) == "function" then
            visit.requested = true
            callback()
        end
        return
    end
    local count = GetNumLootItems()
    if not Count(count) or count == 0 then return end
    local types = Enum and Enum.LootSlotType
    if not types or not Count(types.Item) or not Count(types.Money) or not Count(types.Currency) then return end
    -- Request a single burst before native loot-window presentation. Reverse order tolerates slot removal.
    -- Mark before calls because clearing/closing/bind-confirm events can fire synchronously.
    visit.requested = true
    for slot = count, 1, -1 do
        if self.visit ~= visit or visit.blocked or not self.active or not Enabled() then return end
        local currentCount = GetNumLootItems()
        if not Count(currentCount) then return end
        if slot <= currentCount then
            local kind = GetLootSlotType(slot)
            if self.visit ~= visit or visit.blocked or not self.active or not Enabled() then return end
            if Count(kind) and (kind == types.Item or kind == types.Money or kind == types.Currency) then LootSlot(slot) end
        end
    end
end

function Loot:OnEvent(event, autoLoot)
    if not self.active then return end
    if event == "LOOT_READY" then self:Ready(autoLoot)
    elseif event == "LOOT_BIND_CONFIRM" then
        if not self.visit then self.visit = {} end
        self.visit.blocked = true
    elseif event == "LOOT_CLOSED" or event == "PLAYER_ENTERING_WORLD" then self.visit = nil end
end

function Loot:Apply()
    Suite.pending.loot = nil
    if not Enabled() then
        self.active, self.visit = nil, nil
        if self.events then self.events:UnregisterAllEvents() end
        return
    end
    Suite.AfterCombat("loot", function()
        if not Enabled() then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event, ...) self:OnEvent(event, ...) end)
        end
        self.active = true
        for _, event in ipairs({ "LOOT_READY", "LOOT_CLOSED", "LOOT_BIND_CONFIRM", "PLAYER_ENTERING_WORLD" }) do
            self.events:RegisterEvent(event)
        end
        -- Enabling does not sweep an already-open manual loot window.
    end)
end
