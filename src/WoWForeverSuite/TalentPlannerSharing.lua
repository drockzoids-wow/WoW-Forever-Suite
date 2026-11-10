local _, Suite = ...
local Planner = Suite.TalentPlanner
Planner.shareLimit = 32768

local function Integer(value, maximum)
    return Suite.IsReadable(value) and type(value) == "number" and value >= 1
        and value <= maximum and value % 1 == 0
end
local function Name(value)
    return Suite.IsReadable(value) and type(value) == "string" and #value > 0 and #value <= 48
        and not value:find("[%c|]")
end
local function Hex(text)
    return (text:gsub(".", function(byte) return string.format("%02x", string.byte(byte)) end))
end
local function Unhex(text, maximum)
    if #text > maximum * 2 or #text % 2 ~= 0 or text:find("[^%x]") then return end
    return (text:gsub("%x%x", function(byte) return string.char(tonumber(byte, 16)) end))
end
local function Triple(node, entry, rank) return node .. "." .. entry .. "." .. rank end
local function DecodePoints(payload, ordered)
    local result, count = {}, 0
    if payload == "" then return result end
    for segment in (payload .. ","):gmatch("(.-),") do
        local node, entry, rank = segment:match("^(%d+)%.(%d+)%.(%d+)$")
        node, entry, rank = tonumber(node), tonumber(entry), tonumber(rank)
        count = count + 1
        if count > 512 or not Integer(node, 100000000) or not Integer(entry, 100000000)
            or not Integer(rank, 100) then return end
        if ordered then result[count] = { node = node, entry = entry, rank = rank }
        else
            if result[node] then return end
            result[node] = { entry = entry, rank = rank }
        end
    end
    return result
end

-- A bounded data format, never executable Lua. Hex encodes the original text
-- bytes so delimiters, newlines and UTF-8 notes round-trip without markup.
function Planner:Export()
    if not self:Ready() then return end
    local build = self:Current()
    if not build or not Name(build.name) or not self:ValidNotes(build.notes) then return end
    local ranks = self:Validate(build.ranks)
    if not ranks then return end
    local sequence = self:ValidateOrder(ranks, build.sequence)
    -- Pre-order saved builds can still be shared using a generated legal order.
    if not sequence and build.sequence == nil then sequence = self:BuildSequence(ranks) end
    if not sequence then self:Message("Resolve this build's point order before exporting."); return end
    local points, order = {}, {}
    for _, id in ipairs(self.model.order) do
        local value = ranks[id]
        if value then points[#points + 1] = Triple(id, value.entry, value.rank) end
    end
    for _, step in ipairs(sequence) do order[#order + 1] = Triple(step.node, step.entry, step.rank) end
    local code = table.concat({ "WFS2", self.model.class, build.tree, build.hash,
        table.concat(points, ","), table.concat(order, ","), Hex(build.name), Hex(build.notes) }, ":")
    if #code <= self.shareLimit then return code end
    self:Message("This plan is too large to share.")
end

-- Parsing and preview never create/select a saved build or learn native ranks.
function Planner:DecodeImport(text)
    if not self:Ready() then return nil, "Open your talent tree outside combat first." end
    if not Suite.IsReadable(text) or type(text) ~= "string" or #text > self.shareLimit then
        return nil, "Invalid or oversized Suite build code."
    end
    local version, class, tree, hash, payload, order, name, notes
    if text:sub(1, 5) == "WFS1:" and #text <= 16384 then
        class, tree, hash, payload = text:match("^WFS1:([A-Z]+):(%d+):([0-9a-f]+):([%d%.,]*)$")
        version, name, notes = 1, "Imported build", ""
    else
        class, tree, hash, payload, order, name, notes = text:match(
            "^WFS2:([A-Z]+):(%d+):([0-9a-f]+):([%d%.,]*):([%d%.,]*):(%x*):(%x*)$")
        version = 2
        if name then name, notes = Unhex(name, 48), Unhex(notes, 2048) end
    end
    if class ~= self.model.class or tonumber(tree) ~= self.model.tree or hash ~= self.model.hash then
        return nil, "Paste a Suite build for this class and talent-tree revision."
    end
    if not Name(name) or not self:ValidNotes(notes) then return nil, "Invalid name or notes in this build." end
    local ranks = DecodePoints(payload, false)
    ranks = ranks and self:Validate(ranks)
    if not ranks then return nil, "Invalid talent ranks in this build." end
    local sequence, reason
    if version == 1 then sequence = self:BuildSequence(ranks)
    else
        local decoded = DecodePoints(order, true)
        if decoded then sequence, reason = self:ValidateOrder(ranks, decoded) end
    end
    if not sequence then return nil, reason or "Invalid or incomplete point order in this build." end
    return { version = version, name = name, notes = notes, ranks = ranks, sequence = sequence }
end

function Planner:Import(text)
    local plan, reason = self:DecodeImport(text)
    if not plan then self:Message(reason); return end
    -- New retains current-level rules and creates a separate draft; it never
    -- replaces an existing record, follows a guide or purchases native talents.
    return self:New(plan.name, plan.ranks, plan.notes, plan.sequence)
end
