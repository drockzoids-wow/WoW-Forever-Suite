local _, Suite = ...
local Planner = Suite.TalentPlanner
local function Table(v) return Suite.IsReadable(v) and type(v) == "table" end
local function Int(v, low, high)
    return Suite.IsReadable(v) and type(v) == "number" and v == v and v >= low and v <= high and v % 1 == 0
end
local function Read(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function State() return { ranks = {}, entries = {}, groups = {}, currency = {}, points = 0 } end

function Planner:CleanOrder(order)
    if not Table(order) or #order > 512 then return end
    local result = {}
    for index = 1, #order do
        local step = order[index]
        if not Table(step) or not Int(step.node, 1, 100000000) or not Int(step.entry, 1, 100000000)
            or not Int(step.rank, 1, 100) then return end
        result[index] = { node = step.node, entry = step.entry, rank = step.rank }
    end
    return result
end

function Planner:ValidateOrder(ranks, order)
    local clean = self:Validate(ranks)
    order = self:CleanOrder(order)
    if not clean or not order then return nil, "Leveling order is unavailable." end
    local total = 0
    for _, value in pairs(clean) do total = total + value.rank end
    if total ~= #order then return nil, "The order must include each planned point exactly once." end
    local state, result = State(), {}
    for index = 1, #order do
        local step = order[index]
        if not Table(step) or not Int(step.node, 1, 100000000) or not Int(step.entry, 1, 100000000)
            or not Int(step.rank, 1, 100) then return nil, "Invalid leveling step." end
        local desired = clean[step.node]
        if not desired or desired.entry ~= step.entry or step.rank ~= (state.ranks[step.node] or 0) + 1
            or step.rank > desired.rank then return nil, "Ranks of the same talent must stay in order." end
        local reason = self:RuleReason(step.node, step.entry, state, nil, false)
        if reason then return nil, "Point " .. index .. ": " .. reason end
        self:AddRuleRank(state, step.node, step.entry)
        result[index] = { node = step.node, entry = step.entry, rank = step.rank }
    end
    return result
end

function Planner:BuildSequence(ranks, preferred)
    local clean = self:Validate(ranks)
    if not clean then return end
    local total, ids = 0, {}
    for _, id in ipairs(self.model.order) do
        if clean[id] then total = total + clean[id].rank; ids[#ids + 1] = id end
    end
    if total > 512 then return end
    local result, state = {}, State()
    local function Append(id, entry)
        self:AddRuleRank(state, id, entry)
        result[#result + 1] = { node = id, entry = entry, rank = state.ranks[id] }
    end
    -- Keep legal existing choices in their saved order when a draft is edited.
    if Table(preferred) and #preferred <= 512 then
        for _, step in ipairs(preferred) do
            if Table(step) and Int(step.node, 1, 100000000) and Int(step.entry, 1, 100000000) and Int(step.rank, 1, 100) then
                local desired = clean[step.node]
                if desired and desired.entry == step.entry and step.rank <= desired.rank
                    and step.rank == (state.ranks[step.node] or 0) + 1
                    and not self:RuleReason(step.node, step.entry, state, nil, false) then Append(step.node, step.entry) end
            end
        end
    end
    table.sort(ids, function(a, b)
        local ay, by = self.model.rules[a].y or 0, self.model.rules[b].y or 0
        return ay < by or ay == by and a < b
    end)
    for _ = 1, 512 do
        local changed = false
        for _, id in ipairs(ids) do
            local desired = clean[id]
            while (state.ranks[id] or 0) < desired.rank and not self:RuleReason(id, desired.entry, state, nil, false) do
                Append(id, desired.entry); changed = true
            end
        end
        if not changed or state.points == total then break end
    end
    if state.points == total then return result end
end

function Planner:Sequence(build)
    if not build then return end
    local order = self:ValidateOrder(build.ranks, build.sequence)
    if not order then order = self:BuildSequence(build.ranks, build.sequence) end
    if order then build.sequence = order end
    return order
end
function Planner:SaveOrder(order)
    if self.starter then return end
    if not self:Ready() or not self:Current() then return end
    local clean, reason = self:ValidateOrder(self:Current().ranks, order)
    if not clean then self:Message(reason); return end
    local previous = self:ValidateOrder(self:Current().ranks, self:Current().sequence)
    local same = previous and #previous == #clean
    if same then
        for index, step in ipairs(clean) do
            local old = previous[index]
            if old.node ~= step.node or old.entry ~= step.entry or old.rank ~= step.rank then same = false; break end
        end
    end
    if same then self.notice = nil; self:Render(); return true end
    return self:Store(self:Current().ranks, true, clean)
end

function Planner:InitializeGuide(saved)
    local result = {}
    if Table(saved) and Suite.IsReadable(saved.class) and type(saved.class) == "string" and saved.class:match("^[A-Z]+$")
        and #saved.class <= 24 and (Int(saved.buildID, 1, 1000000000) or Suite.IsReadable(saved.starter) and saved.starter == true) then
        result.class, result.buildID = saved.class, saved.buildID
        result.starter = Suite.IsReadable(saved.starter) and saved.starter == true or nil
        if result.starter then result.buildID = nil end
    end
    self.guideDB = result
    return result
end
function Planner:StopGuide()
    if InCombatLockdown() then return end
    self.guiding = false
    if self.guideDB then self.guideDB.class, self.guideDB.buildID, self.guideDB.starter = nil, nil, nil end
    if self.guideHighlight then self.guideHighlight:Hide() end
    self:HideGuideMarks()
end

-- Compare the whole plan even when the next-step guide must pause. These are
-- informational deltas, never buttons or permission to purchase a native rank.
function Planner:GuideComparison()
    if not self:Ready() or not (self.guiding or self:StarterHelperActive()) then return end
    local build = self:Current()
    if not build then return end
    local result = {}
    for _, id in ipairs(self.model.order) do
        local desired, actual = build.ranks[id], self.model.native[id]
        if actual and (not desired or actual.entry ~= desired.entry or actual.rank > desired.rank) then
            result[id] = { kind = "conflict", text = "X", target = desired and desired.rank or 0 }
        elseif desired then
            local remaining = desired.rank - (actual and actual.rank or 0)
            result[id] = { kind = remaining > 0 and "planned" or "complete",
                text = remaining > 0 and "+" .. remaining or "OK", target = desired.rank, remaining = remaining }
        end
    end
    return result
end
function Planner:RestoreGuide()
    local saved = self.guideDB
    if not self.model or not Table(saved) or not Suite.IsReadable(saved.class) or saved.class ~= self.model.class
        then return end
    if Suite.IsReadable(saved.starter) and saved.starter == true then
        local full = self:StarterBuild(60)
        if full and full.verified then
            self.starter, self.starterLevel, self.guiding, self.preview, self.expanded = true, 60, true, false, true
        end
        return
    end
    if not Int(saved.buildID, 1, 1000000000) then return end
    for index, build in ipairs(self:Library()) do
        if build.id == saved.buildID and build.tree == self.model.tree and build.hash == self.model.hash then
            self.selected, self.guiding, self.preview, self.expanded = index, true, false, true
            return
        end
    end
end
function Planner:StartGuide()
    if not self:Ready() then return end
    if self.starter then
        local full = self:StarterBuild(60)
        if not full or not full.verified then self:Message("This reference plan needs its talent requirements verified before learning."); return end
        self.starterLevel = 60
    end
    if not self:Current() then return end
    if not self:Sequence(self:Current()) then self:Message("Create a valid leveling order before following this build."); return end
    if not self.guideDB then self:InitializeGuide(nil) end
    self.guideDB.class, self.guideDB.buildID = self.model.class, self:Current().id
    self.guideDB.starter = self.starter == true or nil
    self.guiding, self.preview, self.notice = true, false, nil
    self:CloseNotes(); self:CloseOrder(); self:Render()
    self:CloseStarterPanel()
end

function Planner:GuideStep()
    if not self:Ready() or not self.guiding then return end
    local build = self:Current()
    if not build then return nil, "Choose a saved build to follow." end
    if self.starter and not build.verified then return nil, "Reference comparison only: talent requirements need review." end
    local order = self:Sequence(build)
    if not order then return nil, "This build needs a valid leveling order." end
    local active = Read(C_ClassTalents and C_ClassTalents.GetActiveConfigID)
    if not Int(active, 1, 100000000) then return nil, "Live talent guidance is unavailable on this client." end
    if active ~= self.model.config then return nil, "Show your active spec to follow this build." end
    if self.model.staged then return nil, "Review and apply or undo pending changes in the native talent window." end
    local native, learned, state = self.model.native, 0, State()
    for _, id in ipairs(self.model.order) do
        local actual, desired = native[id], build.ranks[id]
        if actual then
            if not desired or actual.entry ~= desired.entry or actual.rank > desired.rank then
                local entry = self.model.nodes[id].entries[actual.entry]
                return nil, "Live talents differ: " .. entry.name .. ".\nPlan: "
                    .. (desired and self.model.nodes[id].entries[desired.entry].name or "no ranks")
                    .. (desired and " (" .. desired.rank .. ")." or ".")
            end
            for _ = 1, actual.rank do self:AddRuleRank(state, id, actual.entry) end
            learned = learned + actual.rank
        end
    end
    for index, step in ipairs(order) do
        local actual = native[step.node]
        if not actual or actual.rank < step.rank then
            local level, _, available = self:Budget()
            if available == nil then return nil, "Your available talent points are unavailable." end
            if available == 0 then return nil, "Plan progress: " .. learned .. "/" .. #order .. ". Earn another talent point to continue." end
            local reason = self:RuleReason(step.node, step.entry, state, level, true)
            if reason then return nil, reason end
            local allowed = Read(C_Traits and C_Traits.CanPurchaseRank, self.model.config, step.node, step.entry)
            if allowed ~= true then return nil, "The game cannot learn the next planned talent right now." end
            return step, "Point " .. index .. ": " .. self.model.nodes[step.node].entries[step.entry].name
                .. " (" .. step.rank .. "/" .. self.model.nodes[step.node].entries[step.entry].max .. ").\nProgress: " .. learned .. "/" .. #order .. " learned."
        end
    end
    return nil, "All " .. #order .. " planned points match your live talents."
end
