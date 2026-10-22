local _, Suite = ...
local Journey = {}
Suite.Journey = Journey

-- A helper of the optional Leveling feature; it owns no frame, hook or timer.
local MAX_ITEMS, MAX_FACTIONS, MAX_LEVELS, LIMIT = 1000, 500, 1000, 1000000000000
local function Table(value) return Suite.IsReadable(value) and type(value) == "table" end
local function Number(value, minimum, maximum)
    return Suite.IsReadable(value) and type(value) == "number" and value == value
        and value >= (minimum or -LIMIT) and value <= (maximum or LIMIT)
end
local function Integer(value, minimum, maximum)
    return Number(value, minimum, maximum) and value == math.floor(value)
end
local function Text(value)
    return Suite.IsReadable(value) and type(value) == "string" and #value > 0 and #value <= 160
        and not value:find("[%c|]")
end
local function Flag(value) return Suite.IsReadable(value) and value == true end
local function Read(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Zone() local value = Read(GetZoneText); return Text(value) and value or nil end
local function Size(value) local count = 0; for _ in pairs(value) do count = count + 1 end; return count end
local function Total(target, key, amount, partial)
    local value = target[key] + amount * 1.0
    if Number(value, 0) then target[key] = value else target[partial] = true end
end

function Journey:New(partial)
    return { version = 1, deaths = 0, loot = {}, reputation = {}, levels = {},
        soldCopper = 0, soldItems = 0, repairCopper = 0, guildRepairCopper = 0,
        deathsPartial = partial == true, lootPartial = partial == true, reputationPartial = partial == true,
        levelsPartial = partial == true, vendorPartial = partial == true }
end

function Journey:Validate(saved)
    if not Table(saved) or not Integer(saved.version, 1, 1) then return end
    local clean = self:New()
    for _, key in ipairs({ "deaths", "soldCopper", "soldItems", "repairCopper", "guildRepairCopper" }) do
        if Integer(saved[key], 0) then clean[key] = saved[key]
        elseif key == "deaths" then clean.deathsPartial = true else clean.vendorPartial = true end
    end
    for _, key in ipairs({ "deathsPartial", "lootPartial", "reputationPartial", "levelsPartial", "vendorPartial" }) do
        clean[key] = clean[key] or Flag(saved[key]) or not Suite.IsReadable(saved[key]) or type(saved[key]) ~= "boolean"
    end
    local death = saved.lastDeath
    if Table(death) and Number(death.elapsed, 0) then
        clean.lastDeath = { elapsed = death.elapsed, at = Integer(death.at, 0) and death.at or nil,
            zone = Text(death.zone) and death.zone or nil }
    end
    if Table(saved.loot) then
        local count = 0
        for id, row in pairs(saved.loot) do
            if count < MAX_ITEMS and Integer(id, 1, 2147483647) and Table(row) and Integer(row.count, 1)
                and Integer(row.priced, 0, row.count) and Integer(row.value, 0) then
                clean.loot[id] = { count = row.count, priced = row.priced, value = row.value,
                    name = Text(row.name) and row.name or nil }
                count = count + 1
            else clean.lootPartial = true end
        end
    else clean.lootPartial = true end
    if Table(saved.reputation) then
        local count = 0
        for id, row in pairs(saved.reputation) do
            if count < MAX_FACTIONS and Integer(id, 1, 2147483647) and Table(row) and Text(row.name)
                and Integer(row.gained, 0) and Integer(row.lost, 0) then
                clean.reputation[id] = { name = row.name, gained = row.gained, lost = row.lost }; count = count + 1
            else clean.reputationPartial = true end
        end
    else clean.reputationPartial = true end
    if Table(saved.baselines) then
        clean.baselines = {}
        local count = 0
        for id, value in pairs(saved.baselines) do
            if count < MAX_FACTIONS and Integer(id, 1, 2147483647) and Integer(value) then
                clean.baselines[id] = value; count = count + 1
            else clean.reputationPartial = true end
        end
    end
    clean.seeded = Flag(saved.seeded)
    if Table(saved.levels) then
        for index, row in ipairs(saved.levels) do
            if index <= MAX_LEVELS and Table(row) and Integer(row.from, 1, 1000) and Integer(row.level, row.from + 1, 1000)
                and Number(row.elapsed, 0) and Integer(row.deaths, 0) then
                clean.levels[#clean.levels + 1] = { from = row.from, level = row.level, elapsed = row.elapsed,
                    gold = Number(row.gold) and row.gold or nil, deaths = row.deaths, partial = Flag(row.partial),
                    at = Integer(row.at, 0) and row.at or nil, zone = Text(row.zone) and row.zone or nil }
            else clean.levelsPartial = true end
        end
    else clean.levelsPartial = true end
    return clean
end

function Journey:Progress(saved)
    if not Table(saved) or not Integer(saved.level, 1, 1000) or not Number(saved.elapsed, 0)
        or not Integer(saved.deaths, 0) then return end
    return { level = saved.level, elapsed = saved.elapsed, deaths = saved.deaths,
        gold = Number(saved.gold) and saved.gold or 0, goldPartial = Flag(saved.goldPartial) or not Number(saved.gold),
        partial = Flag(saved.partial), savedAt = Integer(saved.savedAt, 0) and saved.savedAt or nil,
        lastMoney = Integer(saved.lastMoney, 0) and saved.lastMoney or nil }
end

function Journey:Merge(left, right, offset)
    local result = self:Validate(left) or self:New(true)
    local other = self:Validate(right) or self:New(true)
    for _, key in ipairs({ "deaths", "soldCopper", "soldItems", "repairCopper", "guildRepairCopper" }) do
        Total(result, key, other[key], key == "deaths" and "deathsPartial" or "vendorPartial")
    end
    for _, key in ipairs({ "deathsPartial", "lootPartial", "reputationPartial", "levelsPartial", "vendorPartial" }) do
        result[key] = result[key] or other[key]
    end
    if other.lastDeath then
        result.lastDeath = other.lastDeath
        result.lastDeath.elapsed = result.lastDeath.elapsed + (offset or 0)
    end
    for _, definition in ipairs({ { "loot", MAX_ITEMS, "lootPartial", { "count", "priced", "value" } },
        { "reputation", MAX_FACTIONS, "reputationPartial", { "gained", "lost" } } }) do
        local key, maximum, partial, fields = unpack(definition)
        local count = Size(result[key])
        for id, row in pairs(other[key]) do
            local existing = result[key][id]
            if existing then
                for _, field in ipairs(fields) do
                    local sum = existing[field] + row[field]
                    if Number(sum, 0) then existing[field] = sum else result[partial] = true end
                end
                existing.name = row.name or existing.name
            elseif count < maximum then result[key][id] = row; count = count + 1
            else result[partial] = true end
        end
    end
    for _, row in ipairs(other.levels) do
        if #result.levels < MAX_LEVELS then result.levels[#result.levels + 1] = row else result.levelsPartial = true end
    end
    result.baselines, result.seeded = nil, nil
    return result
end

function Journey:Start(feature, restoring)
    local s = feature.session
    s.journey = self:Validate(s.journey) or self:New(restoring)
    local now, server = Read(GetTime), Read(GetServerTime)
    local previous = feature.journeyRuntime
    local progress = previous and previous.progress or self:Progress(feature.db.levelProgress)
    local level, xp = Read(UnitLevel, "player"), Read(UnitXP, "player")
    if not progress or not Integer(level, 1, 1000) or level ~= progress.level and not restoring then
        progress = Integer(level, 1, 1000) and { level = level, elapsed = 0, deaths = 0, gold = 0, partial = xp ~= 0 } or nil
    elseif restoring and not previous then
        if Number(server, 0) and progress.savedAt and server >= progress.savedAt then
            progress.elapsed = progress.elapsed + server - progress.savedAt
        else progress.partial = true end
    end
    if progress then
        progress.lastTime = Number(now, 0) and now or nil
        if not restoring or previous then progress.lastMoney = Read(GetMoney) end
        if not Integer(progress.lastMoney, 0) then progress.lastMoney, progress.goldPartial = nil, true end
    end
    local known, knownCount = {}, 0
    for _, record in ipairs(feature.db.history) do
        if knownCount >= MAX_FACTIONS then break end
        if record.journey then
        for id in pairs(record.journey.reputation) do if not known[id] and knownCount < MAX_FACTIONS then known[id], knownCount = true, knownCount + 1 end end
    end end
    feature.journeyRuntime = { progress = progress, seen = previous and previous.seen or {}, recent = previous and previous.recent or {},
        standings = {}, requested = {}, formats = self:LootFormats(), knownFactions = known }
    for id, row in pairs(s.journey.loot) do if row.priced < row.count then
        feature.journeyRuntime.requested[id] = true; Read(C_Item and C_Item.RequestLoadItemDataByID, id)
    end end
    self:SyncDeath(feature)
    self:Reputation(feature)
end

function Journey:Sync(feature, reached)
    local state, s = feature.journeyRuntime, feature.session
    if not state or not s then return end
    local p = state.progress
    local now, money = Read(GetTime), Read(GetMoney)
    local level = Integer(reached, 1, 1000) and reached or Read(UnitLevel, "player")
    if not p then
        if Integer(level, 1, 1000) then state.progress = { level = level, elapsed = 0, deaths = 0, gold = 0,
            partial = true, lastTime = Number(now, 0) and now or nil, lastMoney = Integer(money, 0) and money or nil } end
        return
    end
    if Number(now, 0) and p.lastTime and now >= p.lastTime then p.elapsed = p.elapsed + now - p.lastTime
    else p.partial = true end
    p.lastTime = Number(now, 0) and now or nil
    if Integer(money, 0) then
        if p.lastMoney then p.gold = p.gold + money - p.lastMoney else p.goldPartial = true end
        p.lastMoney = money
    else p.lastMoney, p.goldPartial = nil, true end
    if Integer(level, 1, 1000) and level > p.level then
        local rows = s.journey.levels
        if #rows < MAX_LEVELS then rows[#rows + 1] = { from = p.level, level = level, elapsed = p.elapsed,
            gold = not p.goldPartial and p.gold or nil, deaths = p.deaths, partial = p.partial or level ~= p.level + 1,
            at = Read(GetServerTime), zone = Zone() }
        else s.journey.levelsPartial = true end
        state.progress = { level = level, elapsed = 0, gold = 0, deaths = 0, lastTime = p.lastTime, lastMoney = p.lastMoney }
    elseif not Integer(level, 1, 1000) then p.partial = true end
end

function Journey:SaveProgress(feature, stopping)
    self:Sync(feature)
    local state = feature.journeyRuntime
    local progress = state and self:Progress(state.progress)
    if progress then progress.savedAt = Read(GetServerTime); feature.db.levelProgress = self:Progress(progress) end
    if stopping then
        if feature.db.levelProgress then feature.db.levelProgress.partial = true end
        feature.journeyRuntime = nil
    end
end

function Journey:SyncDeath(feature)
    local state, s = feature.journeyRuntime, feature.session
    if not state or not s then return end
    local dead = Read(UnitIsDeadOrGhost, "player")
    if type(dead) == "boolean" then state.dead = dead else s.journey.deathsPartial = true end
end

function Journey:Death(feature)
    local state, s = feature.journeyRuntime, feature.session
    if not state or not s then return end
    local dead, feign = Read(UnitIsDeadOrGhost, "player"), Read(UnitIsFeignDeath, "player")
    if type(dead) ~= "boolean" or type(feign) ~= "boolean" then s.journey.deathsPartial = true; return end
    if not dead or feign or state.dead then return end
    self:Sync(feature)
    state.dead = true
    Total(s.journey, "deaths", 1, "deathsPartial")
    if state.progress then state.progress.deaths = state.progress.deaths + 1 end
    local elapsed = feature:Seconds()
    if Number(elapsed, 0) then s.journey.lastDeath = { elapsed = elapsed, at = Read(GetServerTime), zone = Zone() } end
end

-- Compile only Blizzard's localized self-receipt templates, including positional placeholders.
local function ReceiptPattern(template)
    if not Suite.IsReadable(template) or type(template) ~= "string" or #template > 512 then return end
    local parts, fields, cursor = { "^" }, {}, 1
    while cursor <= #template do
        local char = template:sub(cursor, cursor)
        if char == "%" then
            local token, kind = template:sub(cursor):match("^(%%[12]%$([sd]))")
            if not token then token, kind = template:sub(cursor):match("^(%%([sd]))") end
            if token then
                parts[#parts + 1] = kind == "d" and "(%d+)" or "(.-)"; fields[#fields + 1] = kind
                cursor = cursor + #token
            elseif template:sub(cursor, cursor + 1) == "%%" then parts[#parts + 1] = "%%"; cursor = cursor + 2
            else return end
        else
            parts[#parts + 1] = char:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"); cursor = cursor + 1
        end
    end
    parts[#parts + 1] = "$"
    if #fields == 1 and fields[1] == "s" or #fields == 2 and fields[1] ~= fields[2] then
        return { pattern = table.concat(parts), fields = fields }
    end
end
function Journey:LootFormats()
    local formats = {}
    for _, name in ipairs({ "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_SELF", "LOOT_ITEM_PUSHED_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF" }) do
        local format = ReceiptPattern(_G[name]); if format then formats[#formats + 1] = format end
    end
    return formats
end
local function ItemInfo(id)
    if not C_Item or type(C_Item.GetItemInfo) ~= "function" then return end
    local ok, name, _, _, _, _, _, _, _, _, _, price = pcall(C_Item.GetItemInfo, id)
    if not ok then return end
    return Text(name) and name or nil, Integer(price, 0) and price or nil
end
function Journey:Loot(feature, message, lineID)
    local state, s = feature.journeyRuntime, feature.session
    if not state or not s then return end
    if not Suite.IsReadable(message) or type(message) ~= "string" or #message > 4096
        or not Suite.IsReadable(lineID) or lineID ~= nil and not Integer(lineID, 1) then s.journey.lootPartial = true; return end
    if lineID and state.seen[lineID] then return end
    local item, quantity
    for _, format in ipairs(state.formats) do
        local first, second = message:match(format.pattern)
        if first then
            item, quantity = format.fields[1] == "s" and first or second, format.fields[1] == "d" and tonumber(first)
                or format.fields[2] == "d" and tonumber(second) or 1
            break
        end
    end
    local id = type(item) == "string" and tonumber(item:match("|Hitem:(%d+):"))
    if not Integer(id, 1, 2147483647) or not Integer(quantity, 1, 1000000) then return end
    if lineID then
        state.seen[lineID] = true; state.recent[#state.recent + 1] = lineID
        if #state.recent > 128 then state.seen[table.remove(state.recent, 1)] = nil end
    else s.journey.lootPartial = true end
    local rows, row = s.journey.loot, s.journey.loot[id]
    if not row then
        if Size(rows) >= MAX_ITEMS then s.journey.lootPartial = true; return end
        row = { count = 0, priced = 0, value = 0 }; rows[id] = row
    end
    if not Number(row.count + quantity, 0) then s.journey.lootPartial = true; return end
    row.count = row.count + quantity
    local name, price = ItemInfo(id); row.name = name or row.name
    if price and Number(price * 1.0 * quantity + row.value, 0) then
        row.priced, row.value = row.priced + quantity, row.value + price * 1.0 * quantity
    elseif not state.requested[id] then
        state.requested[id] = true
        Read(C_Item and C_Item.RequestLoadItemDataByID, id)
    end
end
function Journey:ResolveItem(feature, id)
    local state, s = feature.journeyRuntime, feature.session
    if not state or not s or not Integer(id, 1, 2147483647) or not state.requested[id] then return end
    local row = s.journey.loot[id]
    if not row then return end
    local name, price = ItemInfo(id); row.name = name or row.name
    if price and Number(price * 1.0 * (row.count - row.priced) + row.value, 0) then
        row.value, row.priced = row.value + price * 1.0 * (row.count - row.priced), row.count
        state.requested[id] = nil
    end
end

function Journey:Reputation(feature, extraID)
    local state, s = feature.journeyRuntime, feature.session
    if not state or not s then return end
    if InCombatLockdown() then state.reputationDirty = true; s.journey.reputationPartial = true; return end
    state.reputationDirty = nil
    local api, journal = C_Reputation or {}, s.journey
    local count = Read(api.GetNumFactions)
    if not Integer(count, 0, 2000) or type(api.GetFactionDataByIndex) ~= "function" then journal.reputationPartial = true; return end
    journal.baselines = journal.baselines or {}
    local observations, queried = {}, {}
    local function Observe(info)
        if not Table(info) then journal.reputationPartial = true; return end
        if not Suite.IsReadable(info.isHeader) or not Suite.IsReadable(info.isHeaderWithRep) or not Suite.IsReadable(info.isCollapsed) then
            journal.reputationPartial = true; return
        end
        if info.isCollapsed == true then journal.reputationPartial = true end
        if info.isHeader == true and info.isHeaderWithRep ~= true then return end
        local id = info.factionID
        if not Integer(id, 1, 2147483647) or not Text(info.name) or not Integer(info.currentStanding) then journal.reputationPartial = true; return end
        local major, paragon = Read(api.IsMajorFaction, id), Read(api.IsFactionParagon, id)
        local friendshipAPI = C_GossipInfo and C_GossipInfo.GetFriendshipReputation
        local ok, friendship
        if type(friendshipAPI) == "function" then ok, friendship = pcall(friendshipAPI, id) end
        if type(major) ~= "boolean" or type(paragon) ~= "boolean" or not ok or not Suite.IsReadable(friendship)
            or friendship ~= nil and (not Table(friendship) or not Integer(friendship.friendshipFactionID, 0, 2147483647)) then
            journal.reputationPartial = true; return
        end
        if major or paragon or friendship and friendship.friendshipFactionID > 0 then
            if journal.baselines[id] ~= nil then journal.reputationPartial = true end
            journal.baselines[id], state.knownFactions[id], queried[id] = nil, nil, true
            return
        end
        observations[id], queried[id] = info, true
    end
    for index = 1, count do Observe(Read(api.GetFactionDataByIndex, index)) end
    local known = {}; for id in pairs(journal.baselines) do known[id] = true end
    for id in pairs(state.knownFactions) do known[id] = true end
    if Integer(extraID, 1, 2147483647) then known[extraID] = true end
    for id in pairs(known) do if not queried[id] then Observe(Read(api.GetFactionDataByID, id)) end end
    local size, baseSize = Size(journal.reputation), Size(journal.baselines)
    for id, info in pairs(observations) do
        local old = journal.baselines[id]
        local delta = old and info.currentStanding - old or 0
        if old and delta ~= 0 then
            local row = journal.reputation[id]
            if not row and size < MAX_FACTIONS then row = { name = info.name, gained = 0, lost = 0 }; journal.reputation[id] = row; size = size + 1 end
            if row then
                local key = delta > 0 and "gained" or "lost"
                if Number(row[key] + math.abs(delta), 0) then row[key] = row[key] + math.abs(delta) else journal.reputationPartial = true end
            else journal.reputationPartial = true end
        elseif not old and journal.seeded then journal.reputationPartial = true end
        if old or baseSize < MAX_FACTIONS then journal.baselines[id] = info.currentStanding; if not old then baseSize = baseSize + 1 end
        else journal.reputationPartial = true end
        local low, high = info.currentReactionThreshold, info.nextReactionThreshold
        state.standings[id] = Number(low) and Number(high) and high > low and info.currentStanding >= low and info.currentStanding <= high
            and ((info.currentStanding - low) .. " / " .. (high - low)) or nil
    end
    journal.seeded = true
end

function Journey:Events(feature)
    local s, state = feature.session, feature.journeyRuntime
    if not s or not state then return end
    for _, event in ipairs({ "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "CHAT_MSG_LOOT", "ITEM_DATA_LOAD_RESULT",
        "GET_ITEM_INFO_RECEIVED", "UPDATE_FACTION", "FACTION_STANDING_CHANGED", "PLAYER_REGEN_ENABLED" }) do
        local ok, result = pcall(feature.events.RegisterEvent, feature.events, event)
        if not ok or not Suite.IsReadable(result) or result == false then
            if event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then s.journey.deathsPartial = true
            elseif event == "CHAT_MSG_LOOT" or event == "ITEM_DATA_LOAD_RESULT" or event == "GET_ITEM_INFO_RECEIVED" then
                s.journey.lootPartial = true
            else s.journey.reputationPartial = true end
        end
    end
    if #state.formats == 0 then s.journey.lootPartial = true end
end

-- Categorize only Suite actions with matching money and native completion observations.
-- A successful request alone never becomes sale income or repair spending.
function Journey:BeginVendor(kind, items, cost, guild)
    local feature = Suite.Leveling
    if not feature or not feature:Enabled() or not feature.session or InCombatLockdown() then return end
    local journal = feature.session.journey
    if not journal then return end
    local operation = { session = feature.session, kind = kind, money = Read(GetMoney), cost = cost, guild = guild, items = items, count = 0 }
    operation.at = Read(GetTime)
    if not Integer(operation.money, 0) then journal.vendorPartial = true; return end
    if kind == "sale" then
        operation.cost = 0
        if not Table(items) or #items > MAX_ITEMS then journal.vendorPartial = true; return end
        for _, item in ipairs(items) do
            if not Table(item) or not Integer(item.id, 1, 2147483647) or not Integer(item.count, 1)
                or not Integer(item.bag, 0, 5) or not Integer(item.slot, 1, 200) then journal.vendorPartial = true; return end
            local _, price = ItemInfo(item.id)
            if not price or not Integer(item.count, 1) or not Number(operation.cost + price * 1.0 * item.count, 0) then journal.vendorPartial = true; return end
            operation.cost = operation.cost + price * 1.0 * item.count; operation.count = operation.count + item.count
        end
    end
    if not Integer(operation.cost, 0) then journal.vendorPartial = true; return end
    return operation
end
function Journey:EndVendor(operation, final, feature)
    feature = feature or Suite.Leveling
    if not operation or not feature or feature.session ~= operation.session then return end
    if operation.done then return true end
    local journal = operation.session.journey
    if not feature:Enabled() then
        if final then journal.vendorPartial, operation.done = true, true end
        return false
    end
    if InCombatLockdown() then
        if final then journal.vendorPartial, operation.done = true, true end
        return false
    end
    local money = Read(GetMoney)
    local complete = Integer(money, 0)
    if operation.kind == "sale" then
        complete = complete and money - operation.money == operation.cost
        for _, item in ipairs(operation.items) do
            local api = C_Container or {}
            if type(api.GetContainerItemInfo) ~= "function" or type(api.GetContainerItemID) ~= "function" then complete = false
            else
                local ok, info = pcall(api.GetContainerItemInfo, item.bag, item.slot)
                local idOK, id = pcall(api.GetContainerItemID, item.bag, item.slot)
                if not ok or not Suite.IsReadable(info) or info ~= nil or not idOK or not Suite.IsReadable(id) or id ~= nil then complete = false end
            end
        end
        if complete then Total(journal, "soldCopper", operation.cost, "vendorPartial"); Total(journal, "soldItems", operation.count, "vendorPartial") end
    else
        local remaining = Read(GetRepairAllCost)
        complete = complete and Number(remaining, 0) and remaining == 0
            and money == operation.money - (operation.guild and 0 or operation.cost)
        if complete then Total(journal, operation.guild and "guildRepairCopper" or "repairCopper", operation.cost, "vendorPartial") end
    end
    if complete then operation.done = true; return true end
    local now = Read(GetTime)
    if final or not Number(now, 0) or not Number(operation.at, 0) or now - operation.at > 3 then
        journal.vendorPartial, operation.done = true, true
    elseif not operation.queued and feature.journeyRuntime then
        local state = feature.journeyRuntime
        state.vendorPending = state.vendorPending or {}
        if #state.vendorPending < 32 then state.vendorPending[#state.vendorPending + 1] = operation; operation.queued = true
        else journal.vendorPartial, operation.done = true, true end
    end
    return false
end
function Journey:ReconcileVendor(feature, final)
    local state = feature and feature.journeyRuntime
    if not state or not state.vendorPending then return end
    local remaining = {}
    for _, operation in ipairs(state.vendorPending) do
        self:EndVendor(operation, final, feature)
        if not operation.done then remaining[#remaining + 1] = operation end
    end
    state.vendorPending = #remaining > 0 and remaining or nil
end

function Journey:Count(value)
    if not Number(value, 0) then return "Not recorded" end
    local text = string.format("%.0f", math.floor(value))
    local changed
    repeat text, changed = text:gsub("^(%d+)(%d%d%d)", "%1,%2") until changed == 0
    return text
end
function Journey:Money(value)
    if not Number(value) then return "Not recorded" end
    local copper = math.floor(math.abs(value))
    local gold, silver, remainder = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
    local parts = {}
    if gold > 0 then parts[#parts + 1] = self:Count(gold) .. "g" end
    if silver > 0 then parts[#parts + 1] = silver .. "s" end
    if remainder > 0 then parts[#parts + 1] = remainder .. "c" end
    return (value < 0 and "-" or "") .. (#parts > 0 and table.concat(parts, " ") or "0g")
end
function Journey:Duration(value)
    if not Number(value, 0) then return "Not recorded" end
    value = math.floor(value)
    if value < 60 then return value .. "s" end
    if value < 3600 then return string.format("%dm %02ds", math.floor(value / 60), value % 60) end
    if value < 86400 then return string.format("%dh %02dm", math.floor(value / 3600), math.floor(value / 60) % 60) end
    return string.format("%dd %02dh %02dm", math.floor(value / 86400), math.floor(value / 3600) % 24, math.floor(value / 60) % 60)
end
function Journey:Stamp(at)
    if not Integer(at, 0) then return "Date not recorded" end
    local text = Read(date, "%b %d, %Y  %H:%M", at)
    return Text(text) and text or "Date not recorded"
end
local function Partial(value, partial) return (partial and "~" or "") .. value end

function Journey:Summary(record, scope)
    if not record then return { cards = {}, details = {}, title = scope == "Current" and "No active session" or "No previous session",
        subtitle = "Your saved sessions are available in History.", note = "Enable the Leveling tracker to record your journey." } end
    local j = record.journey
    local rateReady = record.elapsed >= 60
    local remaining = record.maxXP and record.lastXP and record.maxXP > 0 and record.maxXP - record.lastXP or nil
    local eta = "Not recorded"
    if record.xpPaused then eta = "XP gain paused"
    elseif record.xpPartial or record.timePartial then eta = "Tracking incomplete"
    elseif record.maxXP and record.lastXP and record.maxXP > 0 then
        if not rateReady then eta = "After 1 minute"
        elseif record.xp <= 0 then eta = "Earn XP first"
        else eta = "~" .. self:Duration((record.maxXP - record.lastXP) * 1.0 * record.elapsed / record.xp) end
    end
    local cards = {
        { "Time played", Partial(self:Duration(record.elapsed), record.timePartial) },
        { "XP earned", Partial(self:Count(record.xp), record.xpPartial) },
        { "Net gold", Partial(self:Money(record.gold), record.goldPartial), record.gold < 0 and "negative" or "positive" },
        { "XP / hour", rateReady and Partial(self:Count(record.xp * 3600.0 / record.elapsed), record.xpPartial or record.timePartial) or "After 1 minute" },
        { "Gold / hour", rateReady and Partial(self:Money(record.gold * 3600.0 / record.elapsed), record.goldPartial or record.timePartial) or "After 1 minute",
            record.gold < 0 and "negative" or "positive" },
        { scope == "Overall" and "Sessions recorded" or remaining and ("Next level · " .. self:Count(remaining) .. " XP left") or "Time to next level",
            scope == "Overall" and self:Count(record.sessions) or eta },
    }
    local level = record.startLevel and record.level and (record.startLevel == record.level and "Level " .. record.level
        or ("Level " .. record.startLevel .. " → " .. record.level)) or scope == "Overall" and j and #j.levels .. " recorded level-ups" or "Not recorded"
    local details = { { "Level progress", level }, { "Deaths", j and Partial(self:Count(j.deaths), j.deathsPartial) or "Not recorded" } }
    details[#details + 1] = { "Last recorded death", j and j.lastDeath and ((j.lastDeath.zone or "Unknown zone") .. " · " .. self:Stamp(j.lastDeath.at))
        or j and "None recorded" or "Not recorded" }
    if j and j.lastDeath then details[#details + 1] = { "Time since recorded death",
        Partial(self:Duration(math.max(0, record.elapsed - j.lastDeath.elapsed)), record.timePartial or j.deathsPartial) } end
    for _, row in ipairs({ { "Suite junk sales", "soldCopper" }, { "Junk items sold", "soldItems" },
        { "Personal repairs", "repairCopper" }, { "Guild-paid repairs", "guildRepairCopper" } }) do
        details[#details + 1] = { row[1], j and Partial(row[2] == "soldItems" and self:Count(j[row[2]]) or self:Money(j[row[2]]), j.vendorPartial) or "Not recorded" }
    end
    details[#details + 1] = { "Other net gold", j and Partial(self:Money(record.gold - j.soldCopper + j.repairCopper), record.goldPartial or j.vendorPartial) or "Not recorded" }
    return { cards = cards, details = details, title = scope == "Overall" and "Your recorded journey"
        or (scope == "Current" or scope == "Previous") and scope .. " session" or scope,
        subtitle = scope == "Overall" and "Completed sessions plus the current session. Offline time is excluded."
            or (self:Stamp(record.startedAt) .. (record.savedAt and ("  →  " .. self:Stamp(record.savedAt))
                or scope == "Current" and "  ·  In progress" or "  ·  End time not recorded")),
        note = "Idle time counts. Gold includes spending and transfers. Sales and repairs show Suite-confirmed actions only. ~ means incomplete tracking." }
end

function Journey:Rows(feature, record, scope, view, sort, descending)
    local j = record and record.journey
    local model = { rows = {}, note = "~ means incomplete tracking. Older sessions keep only the details recorded at the time." }
    if view == "History" then
        local cached = feature.journalHistoryModel
        if cached and cached.history == feature.db.history and cached.count == #feature.db.history then return cached.model end
        model.headers, model.widths = { "Recorded session", "Time", "XP", "Net gold" }, { 0.42, 0.18, 0.18, 0.22 }
        model.title = "Completed sessions · " .. #feature.db.history
        for index = #feature.db.history, 1, -1 do
            local entry = feature.db.history[index]
            local journey = entry.journey
            local reason = ({ login = "New login", restart = "New session", disabled = "Tracking stopped" })[entry.reason] or "Saved session"
            model.rows[#model.rows + 1] = { number = index, cells = { "#" .. index .. " · " .. self:Stamp(entry.startedAt), self:Duration(entry.elapsed),
                Partial(self:Count(entry.xp), entry.xpPartial), Partial(self:Money(entry.gold), entry.goldPartial) },
                detail = reason .. " · " .. (entry.startLevel and entry.level and ("Level " .. entry.startLevel .. " → " .. entry.level .. " · ") or "")
                    .. (journey and (Partial(self:Count(journey.deaths), journey.deathsPartial) .. " deaths") or "Journey details not recorded") }
        end
        model.empty = "Your first completed session will appear here after a new login, New session or turning tracking off."
        model.note = "Select a session to read its summary and journey details."
        feature.journalHistoryModel = { history = feature.db.history, count = #feature.db.history, model = model }
        return model
    end
    if view == "Loot" then
        model.headers, model.widths = { "Received item", "Qty", "Vendor estimate" }, { 0.56, 0.14, 0.30 }
        local items, value, unpriced = 0, 0, 0
        for id, row in pairs(j and j.loot or {}) do
            items, value, unpriced = items + row.count, value + row.value, unpriced + row.count - row.priced
            model.rows[#model.rows + 1] = { id = id, name = row.name or ("Item " .. id), quantity = row.count, value = row.value,
                cells = { row.name or ("Item " .. id), self:Count(row.count), row.priced == 0 and "Not priced" or self:Money(row.value) .. (row.priced < row.count and " +" or "") },
                detail = row.priced < row.count and (self:Count(row.count - row.priced) .. " awaiting a vendor estimate") or "Received during this session" }
        end
        table.sort(model.rows, function(a, b)
            local left, right = sort == "name" and a.name:lower() or sort == "value" and a.value or a.quantity,
                sort == "name" and b.name:lower() or sort == "value" and b.value or b.quantity
            if left ~= right then if descending then return left > right else return left < right end end
            return a.id < b.id
        end)
        model.title = Partial(self:Count(items), j and j.lootPartial) .. " items received · " .. self:Money(value) .. " known vendor value"
        model.note = "Receipts can include quest and container rewards. Estimates are not sale income."
            .. (unpriced > 0 and (" " .. self:Count(unpriced) .. " items are unpriced.") or "")
    elseif view == "Reputation" then
        model.headers, model.widths = { "Faction", "Gained", "Lost", "Net" }, { 0.46, 0.18, 0.18, 0.18 }
        for id, row in pairs(j and j.reputation or {}) do
            local net = row.gained - row.lost
            local standing = scope == "Current" and feature.journeyRuntime and feature.journeyRuntime.standings[id]
            model.rows[#model.rows + 1] = { name = row.name, cells = { row.name, self:Count(row.gained), self:Count(row.lost),
                (net > 0 and "+" or net < 0 and "-" or "") .. self:Count(math.abs(net)) },
                tone = net < 0 and "negative" or "positive", detail = standing and ("Standing: " .. standing) or "Recorded changes" }
        end
        table.sort(model.rows, function(a, b) return a.name:lower() < b.name:lower() end)
        model.title = "Reputation changes" .. (j and j.reputationPartial and " · Partial tracking" or "")
        model.note = "Observed gains and losses in ordinary reputation. Starting reputation is not a gain. Special reputation systems are excluded."
    else
        model.headers, model.widths = { "Level reached", "Time at level", "Net gold", "Deaths" }, { 0.24, 0.28, 0.28, 0.20 }
        local levels = j and j.levels or {}
        for index = #levels, 1, -1 do
            local row = levels[index]
            model.rows[#model.rows + 1] = { cells = { Partial(tostring(row.level), row.partial), self:Duration(row.elapsed),
                self:Money(row.gold), self:Count(row.deaths) }, detail = (row.zone or "Zone not recorded") .. " · " .. self:Stamp(row.at) }
        end
        model.title = "Level-up milestones" .. (j and j.levelsPartial and " · Partial tracking" or "")
        model.note = "Time at a level can span sessions. Idle time counts; offline time is excluded. ~ marks a partially tracked level."
    end
    model.empty = not j and "Journey details were not recorded for this session."
        or view == "Loot" and "No loot receipts recorded yet."
        or view == "Reputation" and "No reputation changes recorded yet." or "Your next recorded level-up will appear here."
    if not j then model.title = "Details not recorded" end
    return model
end
