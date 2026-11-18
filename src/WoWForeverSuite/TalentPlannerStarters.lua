local _, Suite = ...
local Planner = Suite.TalentPlanner
local function Int(v, low, high)
    return Suite.IsReadable(v) and type(v) == "number" and v == v and v >= low and v <= high and v % 1 == 0
end

function Planner:PresetData(id)
    if not self.model then return end
    if not Suite.IsReadable(id) then return end
    if id == nil then return self.starters[self.model.class] end
    if type(id) ~= "string" or #id > 160 then return end
    for _, data in ipairs(self.presets[self.model.class] or {}) do
        if data.id == id then return data end
    end
end

function Planner:ChoosePreset(id)
    if not self:Ready() or not Suite.IsReadable(id) or type(id) ~= "string" or not self:PresetData(id) then return end
    self:StopGuide(); self:CloseImport()
    self.presetID, self.starterCache = id, nil
    self.starter, self.preview, self.starterLevel = true, true, 60
    if self.presetPicker then self.presetPicker:Hide() end
    self:OpenStarterPanel()
end

function Planner:ResolveStarter(presetID)
    if not self:Ready() then return end
    local data = self:PresetData(presetID or self.presetID)
    if self.starterCache and self.starterCache.model == self.model and self.starterCache.data == data then
        return self.starterCache.build, self.starterCache.reason
    end
    local cache = { model = self.model, data = data }; self.starterCache = cache
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
    cache.build = { name = data.name, tree = self.model.tree, hash = self.model.hash,
        ranks = ranks, sequence = clean or order, notes = data.tip, favorite = false, starter = true, data = data,
        verified = clean ~= nil, reviewReason = reason }
    cache.levels = {}
    return cache.build
end

function Planner:StarterBuild(level, presetID)
    local full, reason = self:ResolveStarter(presetID)
    if not full then return nil, reason end
    level = Int(level, 1, 60) and level or 60
    if full.data.kind ~= "Leveling" then level = 60 end
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
    local data = self:PresetData(self.presetID)
    if not data or data.kind ~= "Leveling" then return end
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
    local build = self:New(full.name, full.ranks, full.notes, full.sequence, true)
    if build then
        self:CloseStarterPanel()
        if self:RulesEnabled() then self:TrimToCurrentLevel() end
    end
    return build
end

function Planner:StarterHelperActive()
    return self.starter and not self.guiding and self.expanded and self.starterPanel and self.starterPanel:IsShown()
end

function Planner:FullBuildEnabled()
    return self:Enabled() and Suite.IsReadable(Suite.db.talentPlannerFullBuild) and Suite.db.talentPlannerFullBuild == true
end

function Planner:RememberFullBuild()
    if not self:FullBuildEnabled() or not self:Ready() or not self.expanded then return end
    local build = self:Current()
    if not build then return end
    if not self.guideDB then self:InitializeGuide(nil) end
    -- Keep the reference character-owned; build records remain in the class library.
    if self.starter then self.guideDB.fullBuild = {class=self.model.class,starter=true,presetID=build.data.id}
    elseif Int(build.id,1,1000000000) then self.guideDB.fullBuild = {class=self.model.class,buildID=build.id} end
end

function Planner:FullBuild()
    if not self:FullBuildEnabled() or not self:Ready() then return end
    local reference = self.guideDB and self.guideDB.fullBuild
    if not reference then
        local default = self.starters[self.model.class]
        if default then return self:StarterBuild(60, default.id) end
        return
    end
    if reference.class ~= self.model.class then return end
    if reference.starter then
        local data = self:PresetData(reference.presetID)
        if data then return self:StarterBuild(60, data.id) end
        return
    end
    for _, build in ipairs(self:Library() or {}) do
        if build.id == reference.buildID and build.tree == self.model.tree and build.hash == self.model.hash
            and self:Validate(build.ranks) then return build end
    end
end

function Planner:RenderFullBuild(activeDraft)
    if not self:FullBuildEnabled() or not self:Ready() or activeDraft or self.guiding or self:StarterHelperActive() then return end
    local build = self:FullBuild()
    if not build then return end
    self:RenderGuideMarks(build)
    if build.starter and build.data.kind == "Leveling" and build.sequence and build.sequence[#build.sequence] then
        self:HighlightGuide(build.sequence[#build.sequence], "LEVEL 60")
    end
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
    local leveling = build.data.kind == "Leveling"
    local level = leveling and (self.starterLevel or 60) or 60
    local full = self:StarterBuild(60)
    local step = full.sequence[level - 9]
    local text = leveling and "Level " .. level .. " reference plan" or build.name .. " reference"
    if step then
        text = text .. ": " .. self.model.nodes[step.node].entries[step.entry].name .. " (rank " .. step.rank .. ")."
        self:HighlightGuide(step, leveling and "LEVEL " .. level or "FULL BUILD")
    end
    text = text .. "\n" .. matched .. " talents match • " .. missing .. " ranks to add • " .. different
        .. (leveling and " talents differ from this level." or " talents differ from this build.")
    if self.model.staged then text = text .. "\nPending native changes are shown; apply or undo them to confirm."
    elseif not full.verified then text = text .. "\nReference comparison only: talent requirements need review; learning is unavailable." end
    self:ShowGuideInstruction(nil, text, true)
    self.guideInstruction:SetHeight(54); self.guideInstruction.caption:SetHeight(46)
    self.status:SetText((leveling and "Compared with level " .. level .. " plan." or "Compared with full build.")
        .. "\n+N: missing • OK: matches • X: differs")
end
