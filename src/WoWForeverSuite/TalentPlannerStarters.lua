local _, Suite = ...
local Planner = Suite.TalentPlanner
local function Int(v, low, high)
    return Suite.IsReadable(v) and type(v) == "number" and v == v and v >= low and v <= high and v % 1 == 0
end

function Planner:ResolveStarter()
    if not self:Ready() then return end
    if self.starterCache and self.starterCache.model == self.model then
        return self.starterCache.build, self.starterCache.reason
    end
    local data = self.starters[self.model.class]
    local cache = { model = self.model }; self.starterCache = cache
    local function Fail(reason) cache.reason = reason; return nil, reason end
    if not data then return Fail("No starter plan is available for this class.") end
    local spells, ambiguous = {}, {}
    for _, id in ipairs(self.model.order) do
        for entryID, entry in pairs(self.model.nodes[id].entries) do
            if Int(entry.spell, 1, 100000000) then
                if spells[entry.spell] then ambiguous[entry.spell] = true end
                spells[entry.spell] = { node = id, entry = entryID }
            end
        end
    end
    local ranks, order = {}, {}
    for index = 1, #data.order do
        local spell = data.spells[data.order:sub(index, index)]
        local match = spells[spell]
        if not match or ambiguous[spell] then
            cache.missingSpell = spell
            return Fail("A starter talent is missing or ambiguous in this tree. The plan needs an update; your drafts are unchanged.")
        end
        local previous = ranks[match.node]
        if previous and previous.entry ~= match.entry then return Fail("Starter plan contains conflicting choices.") end
        local rank = previous and previous.rank + 1 or 1
        if rank > self.model.nodes[match.node].entries[match.entry].max then
            return Fail("Starter plan needs an updated rank limit. Your drafts are unchanged.")
        end
        ranks[match.node] = { entry = match.entry, rank = rank }
        order[index] = { node = match.node, entry = match.entry, rank = rank }
    end
    local clean, reason = self:ValidateOrder(ranks, order)
    -- Identity/rank-safe reference views remain useful when the client cannot
    -- describe all requirements. Keep learning/copying gated on full validation.
    cache.build = { name = data.spec .. " Leveling (Starter)", tree = self.model.tree, hash = self.model.hash,
        ranks = ranks, sequence = clean or order, notes = data.tip, favorite = false, starter = true, data = data,
        verified = clean ~= nil, reviewReason = reason }
    cache.levels = {}
    return cache.build
end

function Planner:StarterBuild(level)
    local full, reason = self:ResolveStarter()
    if not full then return nil, reason end
    level = Int(level, 1, 60) and level or 60
    if level == 60 then return full end
    local levels = self.starterCache.levels
    if levels[level] then return levels[level] end
    local ranks, order = {}, {}
    -- Reference schedule: one point per level starting at 10. This is only a
    -- preview; real learning always checks native earned currency and level.
    for index = 1, math.min(math.max(0, level - 9), #full.sequence) do
        local step = full.sequence[index]
        order[index] = { node = step.node, entry = step.entry, rank = step.rank }
        ranks[step.node] = { entry = step.entry, rank = step.rank }
    end
    levels[level] = { name = full.name, tree = full.tree, hash = full.hash, ranks = ranks,
        sequence = order, notes = full.notes, favorite = false, starter = true, data = full.data,
        verified = full.verified, reviewReason = full.reviewReason }
    return levels[level]
end

function Planner:ChooseStarterLevel(level)
    if not self:Ready() or not Int(level, 1, 60) then return end
    self:StopGuide(); self.starter, self.starterLevel, self.preview = true, level, true
    self.notice = nil; self:Render(); self:RenderStarterPanel()
end
function Planner:CustomizeStarter()
    if not self:Ready() or not self.starter then return end
    local full = self:StarterBuild(60)
    if not full then return end
    if not full.verified then self:Message("This reference plan needs its talent requirements verified before customization."); return end
    -- Preserve the complete starter as a personal copy, then apply the normal
    -- current-level policy. OFF + Undo can recover the full copy after trimming.
    local build = self:New(full.data.spec .. " Leveling", full.ranks, full.notes, full.sequence, true)
    if build then
        self:CloseStarterPanel()
        if self:RulesEnabled() then self:TrimToCurrentLevel() end
    end
    return build
end

function Planner:StarterHelperActive()
    return self.starter and not self.guiding and self.expanded and self.starterPanel and self.starterPanel:IsShown()
end

function Planner:RenderStarterHelper()
    if not self:Ready() or not self:StarterHelperActive() then return end
    local build = self:Current()
    if not build then return end
    self:RenderGuideMarks()
    local matched, missing, different = 0, 0, 0
    for _, value in pairs(self:GuideComparison() or {}) do
        if value.kind == "complete" then matched = matched + 1
        elseif value.kind == "planned" then missing = missing + value.remaining
        else different = different + 1 end
    end
    local level = self.starterLevel or 60
    local full = self:StarterBuild(60)
    local step = full.sequence[level - 9]
    local text = "Level " .. level .. " reference plan"
    if step then
        text = text .. ": " .. self.model.nodes[step.node].entries[step.entry].name .. " (rank " .. step.rank .. ")."
        self:HighlightGuide(step, "LEVEL " .. level)
    end
    text = text .. "\n" .. matched .. " talents match • " .. missing .. " ranks to add • " .. different .. " talents differ from this level."
    if self.model.staged then text = text .. "\nPending native changes are shown; apply or undo them to confirm."
    elseif not full.verified then text = text .. "\nReference comparison only: talent requirements need review; learning is unavailable." end
    self:ShowGuideInstruction(nil, text, true)
    self.guideInstruction:SetHeight(54); self.guideInstruction.caption:SetHeight(46)
    self.status:SetText("Compared with level " .. level .. " plan.\n+N: missing • OK: matches • X: differs")
end
