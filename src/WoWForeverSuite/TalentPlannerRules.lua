local _, Suite = ...
local Planner = Suite.TalentPlanner
local function Table(v) return Suite.IsReadable(v) and type(v) == "table" end
local function Number(v, low, high)
    return Suite.IsReadable(v) and type(v) == "number" and v == v and v >= low and v <= high
end
local function Int(v, low, high) return Number(v, low, high) and v % 1 == 0 end
local function Read(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function IDs(value, limit)
    if not Table(value) or #value > limit then return end
    local result = {}
    for _, id in ipairs(value) do if not Int(id, 1, 100000000) then return end; result[#result + 1] = id end
    return result
end
local function Flag(flags, mask) return math.floor(flags / mask) % 2 == 1 end

-- Enum values are from pinned TraitConstantsDocumentation. Do not use the live
-- canPurchaseRank/isActive/isMet gate results to validate a different draft.
function Planner:CaptureRules(model)
    local api = C_Traits
    model.rules, model.groupInfo, model.edges, model.groupCurrencies = {}, {}, {}, {}
    local groupMap, displays = {}, Read(api.GetGroupDisplayInfoByTreeID, model.tree)
    if Table(displays) and #displays <= 8 then
        for _, group in ipairs(displays) do
            if Table(group) and Int(group.groupID, 1, 100000000) and Suite.IsReadable(group.displayName)
                and type(group.displayName) == "string" and #group.displayName <= 80 then
                local info = { id = group.groupID, name = group.displayName }
                model.groupInfo[#model.groupInfo + 1] = info; groupMap[info.id] = true
            end
        end
    end
    local groupIDs = {}
    for _, group in ipairs(model.groupInfo) do groupIDs[#groupIDs + 1] = group.id end
    local groupCurrencyInfo = Read(api.GetGroupCurrencyInfo, model.config, groupIDs)
    if Table(groupCurrencyInfo) and #groupCurrencyInfo <= 8 then
        for _, group in ipairs(groupCurrencyInfo) do
            if Table(group) and Int(group.traitNodeGroupID, 1, 100000000) and Table(group.currencyInfos) then
                local currency = group.currencyInfos[1]
                if Table(currency) and Int(currency.traitCurrencyID, 1, 100000000) then
                    model.groupCurrencies[group.traitNodeGroupID] = currency.traitCurrencyID
                end
            end
        end
    end
    for _, id in ipairs(model.order) do
        local raw = Read(api.GetNodeInfo, model.config, id)
        local rule = { groups = {}, costs = {}, conditions = {}, incoming = {} }
        model.rules[id] = rule
        if not Table(raw) then rule.unknown = true else
            local groups, conditions = IDs(raw.groupIDs, 16), IDs(raw.conditionIDs, 32)
            if not groups or not conditions or not Int(raw.flags, 0, 65535) or not Int(raw.type, 0, 3) then rule.unknown = true end
            if groups then for _, group in ipairs(groups) do if groupMap[group] then rule.groups[#rule.groups + 1] = group end end end
            if Int(raw.flags, 0, 65535) then
                rule.firstRank, rule.never = Flag(raw.flags, 16), Flag(raw.flags, 2)
            end
            if not Int(raw.type, 0, 3) or (raw.type ~= 0 and raw.type ~= 2) then rule.unknown = true end
            if Number(raw.posX, -10000000, 10000000) and Number(raw.posY, -10000000, 10000000) then
                rule.x, rule.y = raw.posX, raw.posY
            end
            if not Int(raw.activeRank, 0, 100) or not Int(raw.ranksIncreased, 0, 100) or not Int(raw.ranksPurchased, 0, 100)
                or raw.activeRank > raw.ranksPurchased or raw.ranksIncreased > 0 then rule.unknown = true end
            local costs = Read(api.GetNodeCost, model.config, id)
            if not Table(costs) or #costs > 8 then rule.unknown = true else
                for _, cost in ipairs(costs) do
                    if not Table(cost) or not Int(cost.ID, 1, 100000000) or not Int(cost.amount, 0, 100) then rule.unknown = true
                    else rule.costs[cost.ID] = (rule.costs[cost.ID] or 0) + cost.amount end
                end
            end
            local edges = raw.visibleEdges
            if not Table(edges) or #edges > 32 then rule.unknown = true else
                for _, edge in ipairs(edges) do
                    if not Table(edge) or not Int(edge.targetNode, 1, 100000000) or not Int(edge.type, 0, 5) then rule.unknown = true
                    elseif edge.type ~= 0 then
                        model.edges[#model.edges + 1] = { from = id, to = edge.targetNode, type = edge.type }
                        if edge.type == 1 or edge.type == 5 then rule.unknown = true end
                    end
                end
            end
            local function CaptureConditions(list, destination)
                if not list then rule.unknown = true; return end
                local levelTracks = {}
                for _, conditionID in ipairs(list) do
                    local c = Read(api.GetConditionInfo, model.config, conditionID)
                    if not Table(c) or not Int(c.type, 0, 5) then rule.unknown = true else
                        if c.type == 2 or c.type == 3 then rule.unknown = true end
                        if c.type == 0 or c.type == 5 then
                            local out = { type = c.type }
                            destination[#destination + 1] = out
                            if not Suite.IsReadable(c.playerLevel) or not Suite.IsReadable(c.spentAmountRequired)
                                or not Suite.IsReadable(c.traitCurrencyID) or not Suite.IsReadable(c.questID)
                                or not Suite.IsReadable(c.achievementID) or not Suite.IsReadable(c.specSetID)
                                or not Suite.IsReadable(c.isAlwaysMet) or type(c.isAlwaysMet) ~= "boolean"
                                or not Suite.IsReadable(c.isSufficient) or type(c.isSufficient) ~= "boolean"
                                or not Suite.IsReadable(c.isGate) or type(c.isGate) ~= "boolean" then out.unknown = true else
                                out.sufficient = c.isSufficient
                                if c.isAlwaysMet then out.always = true
                                elseif c.type == 0 and c.spentAmountRequired == 0 and Int(c.traitCurrencyID, 1, 100000000)
                                    and c.playerLevel == nil and c.questID == nil and c.achievementID == nil and c.specSetID == nil
                                    and Suite.IsReadable(c.traitCondAccountElementID) and c.traitCondAccountElementID == nil
                                    and Suite.IsReadable(c.ranksGranted) and c.ranksGranted == nil then
                                    -- Build 70790 reports ordinary first-tier availability as
                                    -- zero spending, even on nodes in several groups. Zero is
                                    -- satisfied independently of the draft or currency group.
                                    out.always = true
                                    rule.zeroSpending = true
                                elseif c.isGate or Int(c.spentAmountRequired, 1, 10000) then
                                    local currency = c.traitCurrencyID
                                    if currency == nil and #rule.groups == 1 then currency = model.groupCurrencies[rule.groups[1]] end
                                    if Int(c.spentAmountRequired, 0, 10000) and Int(currency, 1, 100000000) and #rule.groups == 1 then
                                        out.spent, out.currency, out.group = c.spentAmountRequired, currency, rule.groups[1]
                                        if Int(c.playerLevel, 1, 1000) then out.level = c.playerLevel end
                                    else out.unknown = true end
                                elseif Int(c.playerLevel, 1, 1000) then
                                    out.level = c.playerLevel
                                    if c.type == 5 and model.nodes[id].max > 1 then
                                        -- One ordinary minimum-level condition applies to the
                                        -- talent. Multiple thresholds/partial caps need a rank model.
                                        levelTracks[#levelTracks + 1] = out
                                        if not Suite.IsReadable(c.ranksGranted) or (c.ranksGranted ~= nil
                                            and (not Int(c.ranksGranted, 0, 100) or c.ranksGranted > 0 and c.ranksGranted < model.nodes[id].max)) then out.unknown = true end
                                    end
                                elseif Int(c.questID, 1, 100000000) or Int(c.achievementID, 1, 100000000) or Int(c.specSetID, 1, 100000000) then
                                    if Suite.IsReadable(c.isMet) and type(c.isMet) == "boolean" then out.static = c.isMet else out.unknown = true end
                                else out.unknown = true end
                            end
                        end
                    end
                end
                if #levelTracks > 1 then for _, condition in ipairs(levelTracks) do condition.unknown = true end end
            end
            CaptureConditions(conditions, rule.conditions)
            for _, entryID in ipairs(model.nodes[id].order) do
                local entry = Read(api.GetEntryInfo, model.config, entryID)
                local entryConditions = Table(entry) and IDs(entry.conditionIDs, 32)
                rule[entryID] = {}; CaptureConditions(entryConditions, rule[entryID])
            end
        end
    end
    -- Forever's class trees retain five-point row gates. A zero-spending
    -- condition alone does not describe those gates (including already learned
    -- live rows). Locate rows within each native display group, then evaluate
    -- them against draft spending. Do not group by localized talent names or
    -- infer row membership from the player's live allocation.
    local rows, seen = {}, {}
    for _, rule in pairs(model.rules) do
        if #rule.groups == 1 and rule.y then
            local group = rule.groups[1]
            rows[group], seen[group] = rows[group] or {}, seen[group] or {}
            if not seen[group][rule.y] then
                seen[group][rule.y] = true; rows[group][#rows[group] + 1] = rule.y
            end
        end
    end
    for _, positions in pairs(rows) do table.sort(positions) end
    for _, rule in pairs(model.rules) do
        local group = #rule.groups == 1 and rule.groups[1]
        -- Apply the complete seven-row class layout to every node, including
        -- rows whose reported condition still has a positive spending amount.
        if group and rule.y and (rule.zeroSpending or #rows[group] == 7) then
            for index, y in ipairs(rows[group]) do
                if rule.y == y then rule.tier = { group = group, points = (index - 1) * 5 }; break end
            end
        elseif rule.zeroSpending then rule.unknown = true end
    end
    for _, edge in ipairs(model.edges) do
        local target = model.rules[edge.to]
        if target then
            target.incoming[#target.incoming + 1] = edge
            if edge.type == 4 then
                model.rules[edge.from].incoming[#model.rules[edge.from].incoming + 1] = { from = edge.to, to = edge.from, type = 4 }
            end
        else model.rules[edge.from].unknown = true end
    end
    for _, rule in pairs(model.rules) do
        local required, sufficient = false, false
        for _, edge in ipairs(rule.incoming) do
            required = required or edge.type == 3; sufficient = sufficient or edge.type == 2
        end
        -- Mixed edge policies are not documented sufficiently to infer their
        -- composition. Keep free planning available instead of inventing it.
        if required and sufficient then rule.unknown = true end
    end
end

-- Explicit support report only: inspect public metadata without changing the
-- active model, saved drafts, native ranks or purchase permissions.
function Planner:Status(spellID)
    spellID = spellID or 1323963 -- Furious Precision, the reported blocked talent.
    if not Int(spellID, 1, 100000000) then return end
    if InCombatLockdown() then Suite.Print("Run talentstatus outside combat."); return end
    local model = self:Snapshot()
    if not model then Suite.Print("Enable Talent Builds and keep your own talent window open, then run /wfs talentstatus."); return end
    local function Value(value)
        if not Suite.IsReadable(value) then return "unreadable" end
        if value == nil then return "nil" end
        if type(value) == "boolean" then return value and "true" or "false" end
        if Number(value, -1000000000, 1000000000) then return tostring(value) end
        if type(value) == "string" and #value <= 40 and value:match("^[%w%.%-]+$") then return value end
        return "unsupported"
    end
    local function Fields(label, record, keys)
        if not Table(record) then Suite.Print(label .. " unavailable"); return end
        local parts = {}
        for _, key in ipairs(keys) do parts[#parts + 1] = key .. "=" .. Value(record[key]) end
        Suite.Print(label .. " " .. table.concat(parts, " "))
    end
    local function Conditions(label, ids)
        ids = IDs(ids, 32)
        if not ids then Suite.Print(label .. " condition IDs unavailable"); return end
        Suite.Print(label .. " conditions=" .. #ids)
        for _, id in ipairs(ids) do
            Fields("condition " .. id, Read(C_Traits.GetConditionInfo, model.config, id),
                { "type", "isAlwaysMet", "isMet", "isGate", "isSufficient", "playerLevel", "ranksGranted",
                    "spentAmountRequired", "traitCurrencyID", "questID", "achievementID", "specSetID", "traitCondAccountElementID" })
        end
    end
    local found = false
    for _, id in ipairs(model.order) do
        local node = model.nodes[id]
        for _, entryID in ipairs(node.order) do
            if node.entries[entryID].spell == spellID then
                found = true
                local level = Read(UnitLevel, "player")
                local currencies = Read(C_Traits.GetTreeCurrencyInfo, model.config, model.tree, true)
                local currency = Table(currencies) and currencies[1]
                local budget = Table(currency) and Int(currency.quantity, 0, 10000) and Int(currency.spent, 0, 10000)
                    and currency.quantity + currency.spent or nil
                Suite.Print("Talent report v" .. Suite.version .. " spell=" .. spellID .. " node=" .. id .. " entry=" .. entryID)
                if type(GetBuildInfo) == "function" then
                    local ok, version, build, _, interface = pcall(GetBuildInfo)
                    if ok then Fields("client", { version = version, build = build, interface = interface }, { "version", "build", "interface" }) end
                end
                Fields("context", { config = model.config, tree = model.tree, level = level, budget = budget,
                    limited = self:RulesEnabled(), staged = model.staged, unknown = model.rules[id].unknown },
                    { "config", "tree", "level", "budget", "limited", "staged", "unknown" })
                Fields("draft tier", model.rules[id].tier, { "group", "points" })
                local raw = Read(C_Traits.GetNodeInfo, model.config, id)
                Fields("node", raw, { "type", "flags", "maxRanks", "activeRank", "ranksPurchased", "ranksIncreased", "posX", "posY" })
                if Table(raw) then
                    Conditions("node", raw.conditionIDs)
                    local groups = IDs(raw.groupIDs, 16)
                    if groups then Suite.Print("groups=" .. table.concat(groups, ",")) end
                    if Table(raw.visibleEdges) then
                        for index = 1, math.min(#raw.visibleEdges, 32) do
                            Fields("edge", raw.visibleEdges[index], { "targetNode", "type" })
                        end
                    end
                end
                local entry = Read(C_Traits.GetEntryInfo, model.config, entryID)
                Fields("entry", entry, { "maxRanks", "definitionID" })
                if Table(entry) then Conditions("entry", entry.conditionIDs) end
                return
            end
        end
    end
    if not found then Suite.Print("Talent spell " .. spellID .. " was not found in the visible tree.") end
end

local function State()
    return { ranks = {}, entries = {}, groups = {}, currency = {}, points = 0 }
end
function Planner:AddRuleRank(state, id, entry)
    state.ranks[id] = (state.ranks[id] or 0) + 1; state.points = state.points + 1
    state.entries[id] = entry or self.model.nodes[id].order[1]
    local rule = self.model.rules[id]
    state.treePoints = state.treePoints or {}
    for _, group in ipairs(rule.groups) do state.treePoints[group] = (state.treePoints[group] or 0) + 1 end
    for currency, amount in pairs(rule.costs) do
        state.currency[currency] = (state.currency[currency] or 0) + amount
        for _, group in ipairs(rule.groups) do
            state.groups[group] = state.groups[group] or {}
            state.groups[group][currency] = (state.groups[group][currency] or 0) + amount
        end
    end
end
function Planner:RuleReason(id, entry, state, level, enforceLevel)
    local rule = self.model.rules and self.model.rules[id]
    if not rule or rule.unknown then return "Talent requirements are unavailable." end
    if rule.never then return "This talent cannot be purchased." end
    if rule.tier then
        local spent = state.treePoints and state.treePoints[rule.tier.group] or 0
        if spent < rule.tier.points then
            local name = "this tree"
            for _, group in ipairs(self.model.groupInfo) do if group.id == rule.tier.group then name = group.name; break end end
            local missing = rule.tier.points - spent
            return "Spend " .. missing .. " more " .. (missing == 1 and "point" or "points") .. " in " .. name .. "."
        end
    end
    local sufficient, anySufficient, requiredReason, alternatives = false, false, nil, {}
    for _, edge in ipairs(rule.incoming) do
        local source = self.model.rules[edge.from]
        local rank = state.ranks[edge.from] or 0
        local maximum = self.model.nodes[edge.from].max
        local needed = source.firstRank and 1 or maximum
        local sourceNode = self.model.nodes[edge.from]
        local name = sourceNode.entries[state.entries[edge.from] or sourceNode.order[1]].name
        local requirement = needed .. "/" .. maximum .. " " .. name
        local active = source and rank >= needed
        if edge.type == 3 and not active then requiredReason = "Requires " .. requirement .. " (" .. rank .. "/" .. needed .. " planned)."
        elseif edge.type == 2 then
            anySufficient = true; sufficient = sufficient or active; alternatives[#alternatives + 1] = requirement
        elseif edge.type == 4 and rank > 0 then return "Cannot combine this talent with " .. name .. "."
        elseif edge.type == 1 or edge.type == 5 then return "Talent requirements are unavailable." end
    end
    if requiredReason then return requiredReason end
    if anySufficient and not sufficient then return "Requires one of: " .. table.concat(alternatives, "; ") .. "." end
    local function Conditions(list)
        if not list then return "Talent requirements are unavailable." end
        local met, failures = {}, {}
        for _, c in ipairs(list) do
            local reason
            if c.unknown then reason = "Talent requirements are unavailable."
            elseif c.always then reason = nil
            elseif c.spent then
                local spent = state.groups[c.group] and state.groups[c.group][c.currency] or 0
                if spent < c.spent then
                    local name = "this tree"
                    for _, group in ipairs(self.model.groupInfo) do if group.id == c.group then name = group.name; break end end
                    local missing = c.spent - spent
                    reason = "Spend " .. missing .. " more " .. (missing == 1 and "point" or "points") .. " in " .. name .. "."
                end
                if not reason and enforceLevel ~= false and c.level and (not level or level < c.level) then reason = "Requires level " .. c.level .. "." end
            elseif c.level then
                if enforceLevel ~= false and (not level or level < c.level) then reason = "Requires level " .. c.level .. "." end
            elseif c.static ~= true then reason = "A character requirement has not been met." end
            if not reason and c.sufficient then met[c.type] = true end
            if reason then failures[#failures + 1] = { type = c.type, reason = reason } end
        end
        for _, failure in ipairs(failures) do if not met[failure.type] then return failure.reason end end
    end
    return Conditions(rule.conditions) or Conditions(rule[entry])
end

function Planner:Analyze(ranks, budgetRules)
    local result = { state = State(), blocked = {}, unplaced = 0, points = 0, deficit = 0 }
    local level, budget = self:Budget()
    for _, value in pairs(ranks) do result.points = result.points + value.rank end
    -- Reconstruct a legal purchase order from an empty draft. Final group totals
    -- alone could let gated talents unlock one another in a circular allocation.
    for _ = 1, 1024 do
        local changed = false
        for _, id in ipairs(self.model.order) do
            local desired = ranks[id]
            if desired and (result.state.ranks[id] or 0) < desired.rank
                and not self:RuleReason(id, desired.entry, result.state, level, budgetRules) then
                self:AddRuleRank(result.state, id, desired.entry); changed = true
            end
        end
        if not changed then break end
    end
    for _, id in ipairs(self.model.order) do
        local value = ranks[id]
        if value then
            local missing = value.rank - (result.state.ranks[id] or 0)
            if missing > 0 then
                result.unplaced = result.unplaced + missing
                result.blocked[id] = self:RuleReason(id, value.entry, result.state, level, budgetRules) or "Talent requirements are unavailable."
                result.reason = result.reason or result.blocked[id]
            end
        end
    end
    if budgetRules then
        if budget == nil then result.reason = "Your talent-point budget is unavailable."; result.deficit = 100000; result.budgetUnknown = true
        elseif result.points > budget then result.deficit = result.points - budget; result.reason = result.reason or "No talent points remain at your level." end
    end
    result.valid = not result.reason
    return result
end
function Planner:RulesEnabled() return Suite.db.talentPlannerRules == true end
function Planner:TrimToCurrentLevel()
    if self.starter then return end
    if not self:RulesEnabled() or not self:Ready() then return end
    local build = self:Current()
    if not build then return end
    local desired = self:Validate(build.ranks)
    local level, budget = self:Budget()
    if not desired or not level or budget == nil then
        self:Message("Cannot trim this draft while its level or point budget is unavailable."); return
    end
    local order, originalPoints = {}, 0
    for _, id in ipairs(self.model.order) do
        local value = desired[id]
        if value then
            local rule = self.model.rules[id]
            local unknown = not rule or rule.unknown
            if rule then
                for _, conditions in ipairs({rule.conditions, rule[value.entry] or {}}) do
                    for _, condition in ipairs(conditions) do unknown = unknown or condition.unknown end
                end
            end
            if unknown then
                self:Message("Cannot trim this draft until its talent requirements are available."); return
            end
            order[#order + 1] = id; originalPoints = originalPoints + value.rank
        end
    end
    -- Preserve selected lower-tier talents first, then stable node-ID order.
    -- Rebuild only from existing choices so every retained rank is reachable;
    -- deleting arbitrary ranks could leave their descendants invalid.
    table.sort(order, function(a, b)
        local ay, by = self.model.rules[a].y or 0, self.model.rules[b].y or 0
        if ay ~= by then return ay < by end
        return a < b
    end)
    local state, trimmed = State(), {}
    for _ = 1, 1024 do
        local changed = false
        for _, id in ipairs(order) do
            local value = desired[id]
            while state.points < budget and (state.ranks[id] or 0) < value.rank
                and not self:RuleReason(id, value.entry, state, level, true) do
                self:AddRuleRank(state, id, value.entry); changed = true
                trimmed[id] = { entry = value.entry, rank = state.ranks[id] }
            end
        end
        if not changed or state.points >= budget then break end
    end
    if state.points == originalPoints then return true end
    if self:Store(trimmed, true) then
        self:Message("Removed " .. (originalPoints - state.points) .. " planned ranks to fit your current level.")
        return true
    end
end
function Planner:CheckEdit(ranks)
    local currentLevel = self:RulesEnabled()
    local after = self:Analyze(ranks, currentLevel)
    if after.valid then return true end
    local build = self:Current()
    local before = build and self:Analyze(build.ranks, currentLevel)
    if before and not before.valid and after.deficit <= before.deficit
        and after.unplaced <= before.unplaced and (not after.budgetUnknown or after.points < before.points) then
        local newFailure = false
        for id in pairs(after.blocked) do if not before.blocked[id] then newFailure = true end end
        if not newFailure then return true end
    end
    self:Message(after.reason); return false
end
