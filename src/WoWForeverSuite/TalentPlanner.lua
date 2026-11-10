local _, Suite = ...
local Planner = { limit = 30, historyLimit = 50 }
Suite.TalentPlanner = Planner
Suite.modules[#Suite.modules + 1] = Planner

local function Table(v) return Suite.IsReadable(v) and type(v) == "table" end
local function Integer(v, low, high)
    return Suite.IsReadable(v) and type(v) == "number" and v == v and v >= low and v <= high and v % 1 == 0
end
local function Text(v, limit)
    return Suite.IsReadable(v) and type(v) == "string" and #v > 0 and #v <= limit and not v:find("[%c|]")
end
local function Notes(v)
    return Suite.IsReadable(v) and type(v) == "string" and #v <= 2048
        and not v:find("%z") and not v:find("[\001-\008\011\012\014-\031\127|]")
        and #(v:gsub("[\128-\191]", "")) <= 512
end
function Planner:ValidNotes(value) return Notes(value) end
local function Read(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function List(v, limit)
    if not Table(v) or #v > limit then return end
    local result = {}
    for i = 1, #v do
        if not Integer(v[i], 1, 100000000) then return end
        result[i] = v[i]
    end
    return result
end
function Planner:Enabled() return Suite.db and Suite.IsReadable(Suite.db.talentPlanner) and Suite.db.talentPlanner == true end

function Planner:Budget()
    if not self:Ready() then return end
    local level = Read(UnitLevel, "player")
    if not Integer(level, 1, 1000) then return end
    -- Camelot's native class-point display uses the first tree currency.
    -- Include committed spending so a full draft has the whole earned budget;
    -- exclude staged native edits and never assume a level-to-points formula.
    local currencies = Read(C_Traits and C_Traits.GetTreeCurrencyInfo, self.model.config, self.model.tree, true)
    local currency = Table(currencies) and currencies[1]
    if not Table(currency) or not Integer(currency.quantity, 0, 10000) or not Integer(currency.spent, 0, 10000) then
        return level
    end
    return level, currency.quantity + currency.spent, currency.quantity
end

function Planner:Context()
    if InCombatLockdown() or not self:Enabled() then return end
    local host = PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
    if not host or Read(host.IsForbidden, host) ~= false or Read(host.IsVisible, host) ~= true
        or Read(host.IsInspecting, host) ~= false then return end
    local config, tree = Read(host.GetConfigID, host), Read(host.GetTalentTreeID, host)
    local ok, _, class = pcall(UnitClass, "player")
    if not ok or not Text(class, 24) or not class:match("^[A-Z]+$")
        or not Integer(config, 1, 100000000) or not Integer(tree, 1, 100000000) then return end
    return { host = host, config = config, tree = tree, class = class }
end

-- Only getters are used. Never stage, refund, select, load or commit a game config.
function Planner:Snapshot()
    local model, api = self:Context(), C_Traits
    if not model or type(api) ~= "table" then return end
    local hash, ids = Read(api.GetTreeHash, model.tree), List(Read(api.GetTreeNodes, model.tree), 512)
    if not Table(hash) or #hash ~= 16 or not ids or #ids == 0 then return end
    local encoded = {}
    for i = 1, 16 do
        if not Integer(hash[i], 0, 255) then return end
        encoded[i] = string.format("%02x", hash[i])
    end
    model.hash, model.nodes, model.order, model.native = table.concat(encoded), {}, {}, {}
    model.staged = Read(api.ConfigHasStagedChanges, model.config)
    if type(model.staged) ~= "boolean" then return end
    for _, id in ipairs(ids) do
        local node = Read(api.GetNodeInfo, model.config, id)
        if not Table(node) or not Suite.IsReadable(node.isVisible) then return end
        if node.isVisible == true then
            local entries = List(node.entryIDs, 8)
            if not entries or not Integer(node.maxRanks, 0, 100) then return end
            if #entries > 0 and node.maxRanks > 0 then
                if not Integer(node.ranksPurchased, 0, node.maxRanks) then return end
                local data = { id = id, max = node.maxRanks, entries = {}, order = entries }
                for _, entryID in ipairs(entries) do
                    local entry = Read(api.GetEntryInfo, model.config, entryID)
                    if not Table(entry) or not Integer(entry.maxRanks, 1, 100) or not Integer(entry.definitionID, 1, 100000000) then return end
                    local definition = Read(api.GetDefinitionInfo, entry.definitionID)
                    if not Table(definition) then return end
                    local spell = Integer(definition.spellID, 1, 100000000) and definition.spellID or nil
                    local info = spell and Read(C_Spell and C_Spell.GetSpellInfo, spell)
                    local name = Text(definition.overrideName, 160) and definition.overrideName
                        or Table(info) and Text(info.name, 160) and info.name or ("Talent " .. id)
                    local icon = Integer(definition.overrideIcon, 1, 100000000) and definition.overrideIcon
                        or Table(info) and Integer(info.iconID, 1, 100000000) and info.iconID or 134400
                    data.entries[entryID] = { max = math.min(node.maxRanks, entry.maxRanks), name = name, icon = icon, spell = spell }
                end
                local active = node.activeEntry
                if not Suite.IsReadable(active) then return end
                local entryID = Table(active) and active.entryID or entries[1]
                if not Integer(entryID, 1, 100000000) or not data.entries[entryID] then return end
                if node.ranksPurchased > data.entries[entryID].max then return end
                model.nodes[id], model.order[#model.order + 1] = data, id
                if node.ranksPurchased > 0 then model.native[id] = { entry = entryID, rank = node.ranksPurchased } end
            end
        end
    end
    if #model.order == 0 then return end
    table.sort(model.order)
    local groups = Read(api.GetGroupDisplayInfoByTreeID, model.tree)
    model.groups = {}
    if Table(groups) and #groups <= 8 then
        for _, group in ipairs(groups) do
            if Table(group) and Text(group.displayName, 80) then model.groups[#model.groups + 1] = group.displayName end
        end
    end
    self:CaptureRules(model)
    return model
end

function Planner:Library()
    if not self.model then return end
    local db = Suite.db.talentBuilds
    if not Table(db) or not Table(db.classes) then db = { schema = 1, classes = {} }; Suite.db.talentBuilds = db end
    local library = db.classes[self.model.class]
    if not Table(library) or not Table(library.builds) then
        library = { builds = {} }; db.classes[self.model.class] = library
    end
    -- Bound and sanitize saved metadata without deleting incompatible trees.
    local builds = {}
    for i = 1, math.min(#library.builds, self.limit) do
        local b = library.builds[i]
        if Table(b) and Text(b.name, 48) and Text(b.hash, 32) and b.hash:match("^[0-9a-f]+$")
            and Integer(b.tree, 1, 100000000) and Table(b.ranks) then
            if not Notes(b.notes) then b.notes = "" end
            b.favorite = Suite.IsReadable(b.favorite) and b.favorite == true
            b.sequence = self:CleanOrder(b.sequence)
            builds[#builds + 1] = b
        end
    end
    library.builds = builds
    local used, nextID = {}, Integer(library.nextID, 1, 1000000000) and library.nextID or 1
    for _, build in ipairs(builds) do
        if Integer(build.id, 1, 1000000000) and not used[build.id] then
            used[build.id] = true; nextID = math.max(nextID, build.id + 1)
        else build.id = nil end
    end
    if nextID > 1000000000 then nextID = 1 end
    for _, build in ipairs(builds) do
        if not build.id then
            while used[nextID] do nextID = nextID + 1 end
            build.id = nextID; used[nextID] = true; nextID = nextID + 1
        end
    end
    library.nextID = nextID
    return builds
end

function Planner:Validate(ranks)
    if not self.model or not Table(ranks) then return end
    local clean, count = {}, 0
    for id, value in pairs(ranks) do
        count = count + 1
        if count > 512 or not Integer(id, 1, 100000000) or not Table(value) then return end
        local node = self.model.nodes[id]
        if not node or not Integer(value.entry, 1, 100000000) or not node.entries[value.entry]
            or not Integer(value.rank, 1, node.entries[value.entry].max) then return end
        clean[id] = { entry = value.entry, rank = value.rank }
    end
    return clean
end
function Planner:Ready()
    local context = self:Context()
    return context and self.model and context.host == self.model.host and context.config == self.model.config
        and context.tree == self.model.tree and context.class == self.model.class
end
function Planner:Current()
    if self.starter then return self:StarterBuild(self.starterLevel) end
    local builds = self:Library()
    local build = builds and self.selected and builds[self.selected]
    if build and build.tree == self.model.tree and build.hash == self.model.hash then return build end
end
function Planner:Message(message)
    self.notice = message
    if self.status then self.status:SetText(message) else Suite.Print(message) end
end
function Planner:BuildOrder()
    local builds, order = self:Library(), {}
    for index in ipairs(builds or {}) do order[#order + 1] = index end
    table.sort(order, function(a, b)
        if builds[a].favorite ~= builds[b].favorite then return builds[a].favorite end
        return a < b
    end)
    return order
end
function Planner:ToggleFavorite()
    if not self:Ready() or self.starter then return end
    local build = self:Current()
    if not build then return end
    build.favorite = not build.favorite; self.notice = nil
    for position, index in ipairs(self:BuildOrder()) do if index == self.selected then self.page = math.ceil(position / 5); break end end
    self:Render(); return true
end
function Planner:SetNotes(text)
    if not self:Ready() or self.starter or not self:Current() then return end
    if not Notes(text) then self:Message("Keep notes within 512 characters and avoid formatting codes."); return end
    self:Current().notes = text; self.notice = nil; self:Render(); return true
end
function Planner:RankDescription(entryID, rank)
    if not self:Ready() or not Integer(entryID, 1, 100000000) or not Integer(rank, 1, 100) then return end
    local description = Read(C_Traits and C_Traits.GetTraitDescription, entryID, rank)
    if Suite.IsReadable(description) and type(description) == "string" and #description > 0 and #description <= 8192 then return description end
end

function Planner:New(name, ranks, notes, sequence, starterCopy)
    if not self:Ready() then return end
    local builds, clean = self:Library(), self:Validate(ranks or {})
    if not clean then self:Message("This build does not match the current talent tree."); return end
    local requirements = self:Analyze(clean, not starterCopy and self:RulesEnabled())
    if not requirements.valid then self:Message(requirements.reason); return end
    if #builds >= self.limit then self:Message("Build library is full (30 per class)."); return end
    if not Text(name, 48) then name = "Build " .. (#builds + 1) end
    self:StopGuide()
    self.starter = false
    builds[#builds + 1] = { name = name, tree = self.model.tree, hash = self.model.hash, ranks = clean,
        favorite = false, notes = Notes(notes) and notes or "", sequence = self:BuildSequence(clean, sequence) }
    self.notice = nil
    self.selected, self.preview, self.undo, self.redo = #builds, true, {}, {}
    self.page = math.ceil(#builds / 5)
    self:Render()
    return builds[#builds]
end
function Planner:Select(index)
    if not self:Ready() or not Integer(index, 1, self.limit) then return end
    local build = self:Library()[index]
    if not build or build.tree ~= self.model.tree or build.hash ~= self.model.hash or not self:Validate(build.ranks) then
        self:Message("This saved build belongs to a different talent-tree revision."); return
    end
    self:StopGuide()
    self.starter = false
    self.selected, self.preview, self.undo, self.redo = index, true, {}, {}
    self.notice = nil
    self:Render()
    if self:RulesEnabled() then self:TrimToCurrentLevel() end
end
function Planner:Store(ranks, history, sequence)
    if not self:Ready() or self.starter then return end
    local build, clean = self:Current(), self:Validate(ranks)
    if not build or not clean then return end
    if not self:CheckEdit(clean) then return end
    if history then
        self.undo = self.undo or {}; self.undo[#self.undo + 1] = { ranks = Suite.Copy(build.ranks), sequence = Suite.Copy(build.sequence) }
        if #self.undo > self.historyLimit then table.remove(self.undo, 1) end
        self.redo = {}
    end
    build.sequence = self:BuildSequence(clean, sequence or build.sequence) or build.sequence
    build.ranks = clean; self.notice = nil; self:Render(); return true
end
function Planner:ResetDraft()
    if not self:Ready() or not self.preview or self.starter then return end
    local build = self:Current()
    if not build or not next(build.ranks) then return end
    return self:Store({}, true, {})
end

function Planner:Change(id, delta, cycle)
    if not self:Ready() or not self.preview or not Integer(id, 1, 100000000) then return end
    local build, node = self:Current(), self.model.nodes[id]
    if not build or not node or (delta ~= 1 and delta ~= -1) then return end
    local ranks, entry, rank = Suite.Copy(build.ranks), node.order[1], 0
    if ranks[id] then entry, rank = ranks[id].entry, ranks[id].rank end
    if cycle and #node.order > 1 then
        for index, candidate in ipairs(node.order) do
            if candidate == entry then entry = node.order[index % #node.order + 1]; break end
        end
        rank = math.max(1, math.min(rank, node.entries[entry].max))
    else
        local nextRank = math.max(0, math.min(node.entries[entry].max, rank + delta))
        if nextRank == rank then return end
        rank = nextRank
    end
    ranks[id] = rank > 0 and { entry = entry, rank = rank } or nil
    self:Store(ranks, true)
end
function Planner:History(redo)
    if not self:Ready() then return end
    local build = self:Current()
    local source, target = redo and self.redo or self.undo, redo and self.undo or self.redo
    if not build or not source or #source == 0 then return end
    local previous = { ranks = Suite.Copy(build.ranks), sequence = Suite.Copy(build.sequence) }
    local snapshot = source[#source]
    local structured = Table(snapshot) and Table(snapshot.ranks)
    if self:Store(structured and snapshot.ranks or snapshot, false, structured and snapshot.sequence or nil) then
        table.remove(source); target[#target + 1] = previous; self:Render()
    end
end
function Planner:Rename(name)
    if not self:Ready() or self.starter then return end
    local build = self:Current()
    if build and Text(name, 48) then build.name = name; self.notice = nil; self:Render(); return true end
    self:Message("Use a name of 1–48 characters without formatting codes.")
end
function Planner:Delete()
    if not self:Ready() or self.starter or not self:Current() then return end
    self:StopGuide(); table.remove(self:Library(), self.selected)
    self.selected, self.preview, self.undo, self.redo = nil, false, {}, {}
    self.notice = nil
    self:Render()
end
function Planner:Refresh()
    if InCombatLockdown() then return end
    if not self:Enabled() then if self.root then self.root:Hide() end; return end
    self:Attach()
    if not self.root then return end
    local model = self:Snapshot()
    if not model then
        self:CloseImport()
        self.model, self.preview = nil, false
        self.guiding = false
        if self.guideHighlight then self.guideHighlight:Hide() end
        self:HideGuideMarks()
        self:CloseStarterPanel()
        self.panel:Hide(); self.overlay:Hide(); self.footer:Hide(); self.launcher:Hide()
        return
    end
    local changed = not self.model or self.model.class ~= model.class or self.model.tree ~= model.tree
        or self.model.hash ~= model.hash or self.model.config ~= model.config
    if changed then
        self.starter = false
        self.selected, self.preview, self.undo, self.redo = nil, false, {}, {}
        self.notice, self.guiding = nil, false
    end
    self.model = model
    if changed then self:RestoreGuide() end
    self.launcher:Show(); self.panel:SetShown(self.expanded == true)
    self:Render()
end
function Planner:Queue()
    if not self:Enabled() or self.timer or InCombatLockdown() then return end
    self.timer = C_Timer.NewTimer(0.05, function() self.timer = nil; self:Refresh() end)
end
function Planner:Apply()
    if self.timer then self.timer:Cancel(); self.timer = nil end
    Suite.pending.talentPlanner = nil
    if self.events then self.events:UnregisterAllEvents() end
    if not self:Enabled() then
        self:CloseImport()
        Suite.AfterCombat("talentPlanner", function()
            if self.root then
                if self.driver then UnregisterStateDriver(self.root, "visibility"); self.driver = nil end
                self.root:Hide()
            end
            self.preview, self.expanded = false, false
        end)
        return
    end
    Suite.AfterCombat("talentPlanner", function()
        if not self:Enabled() then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event)
                if event == "PLAYER_REGEN_DISABLED" then
                    self:CloseImport()
                    if self.timer then self.timer:Cancel(); self.timer = nil end
                else self:Queue() end
            end)
        end
        for _, event in ipairs({ "ADDON_LOADED", "PLAYER_TALENT_UPDATE", "TRAIT_CONFIG_UPDATED", "TRAIT_NODE_CHANGED",
            "SPELL_DATA_LOAD_RESULT", "PLAYER_LEVEL_UP", "TRAIT_TREE_CURRENCY_INFO_UPDATED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
            pcall(self.events.RegisterEvent, self.events, event)
        end
        local wasLimited = self.limitEnabled
        self.limitEnabled = self:RulesEnabled()
        if wasLimited ~= self.limitEnabled then self.notice = nil end
        self:Refresh()
        if wasLimited == false and self.limitEnabled then self:TrimToCurrentLevel() end
        if self.root then
            if not self.driver then RegisterStateDriver(self.root, "visibility", "[combat] hide; show"); self.driver = true end
            self.root:Show()
        end
    end)
end
function Planner:Open()
    if InCombatLockdown() then Suite.Print("Open Talent Builds outside combat."); return end
    if not self:Enabled() then Suite.Print("Enable Talent Builds in Suite settings first."); Suite.GUI:OpenPage("talents"); return end
    if not PlayerSpellsUtil or type(PlayerSpellsUtil.OpenToClassTalentsTab) ~= "function" then
        Suite.Print("The talent window is unavailable on this client."); return
    end
    PlayerSpellsUtil.OpenToClassTalentsTab()
    self.expanded = true; self:Refresh()
    if not self.model then Suite.Print("Talent data is not ready. Reopen Talents after it loads.") end
end
