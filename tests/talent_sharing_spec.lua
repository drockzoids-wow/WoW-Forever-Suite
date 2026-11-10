local Suite, equal, Frame, SetCombat = ...
local planner = Suite.TalentPlanner
local saved, oldLibrary, oldRules = {}, Suite.db.talentBuilds, Suite.db.talentPlannerRules
for key, value in pairs(planner) do saved[key] = value end
Suite.db.talentBuilds = { schema = 1, classes = {} }
Suite.db.talentPlannerRules = false
planner.selected, planner.starter, planner.expanded, planner.guiding = nil, false, true, false
planner.guideDB = {}
local original = oldLibrary.classes[planner.model.class].builds[saved.selected]
local source = planner:New("Raid: café", original.ranks, original.notes, original.sequence)
source.notes = "First: rank 1, then rank 2.\n中文 café 🙂\tKeep this note.\r\n"
source.favorite = true
local name, notes, sequence = source.name, source.notes, Suite.Copy(source.sequence)
local ranks = Suite.Copy(source.ranks)
local code = planner:Export()
equal(code:sub(1, 5), "WFS2:", "new exports use the full-plan format")
equal(planner.code.maxLetters, planner.shareLimit, "native code input accommodates the full bounded format")
local function Hex(text) return (text:gsub(".", function(c) return string.format("%02x", string.byte(c)) end)) end
local header = "WFS2:" .. planner.model.class .. ":" .. planner.model.tree .. ":" .. planner.model.hash .. ":"
local rankPayload, orderPayload = code:match("^WFS2:[^:]+:[^:]+:[^:]+:([^:]*):([^:]*):")
local function Pack(r, o, n, text)
    return header .. (r or rankPayload) .. ":" .. (o or orderPayload) .. ":" .. Hex(n or name) .. ":" .. Hex(text or notes)
end
local function SamePlan(build, label)
    equal(build.name, name, label .. " name")
    equal(build.notes, notes, label .. " exact multiline UTF-8 notes")
    equal(#build.sequence, #sequence, label .. " point count")
    for index, step in ipairs(sequence) do
        equal(build.sequence[index].node, step.node, label .. " ordered node " .. index)
        equal(build.sequence[index].entry, step.entry, label .. " choice " .. index)
        equal(build.sequence[index].rank, step.rank, label .. " per-point rank " .. index)
    end
    for node, value in pairs(ranks) do
        equal(build.ranks[node].entry, value.entry, label .. " final choice")
        equal(build.ranks[node].rank, value.rank, label .. " final rank")
    end
end
local before, selected = #planner:Library(), planner.selected
SamePlan(planner:DecodeImport(code), "decoded full plan")
equal(#planner:Library(), before, "decode does not add a saved build")
equal(planner.selected, selected, "decode does not select a build")
local imported = planner:Import(code)
SamePlan(imported, "imported full plan")
equal(imported ~= source, true, "import creates a separate draft")
equal(imported.id ~= source.id, true, "import receives a new local build ID")
equal(imported.favorite, false, "favorites stay local")
equal(planner:Library()[1], source, "same-name import never overwrites an existing build")
equal(planner:Export(), code, "full-plan export is deterministic across round trips")
local persisted = Suite.Copy(Suite.db.talentBuilds)
Suite.db.talentBuilds = persisted
SamePlan(planner:Current(), "saved-library normalization")
-- Continue with the original instances so isolation assertions stay explicit.
Suite.db.talentBuilds = { schema = 1, classes = { [planner.model.class] = { builds = { source, imported } } } }
imported.sequence[1].node = 999
equal(source.sequence[1].node, sequence[1].node, "imported order is not aliased to the source")
imported.sequence = Suite.Copy(sequence)

local legacy = "WFS1:" .. planner.model.class .. ":" .. planner.model.tree .. ":" .. planner.model.hash .. ":" .. rankPayload
local legacyPlan = planner:DecodeImport(legacy)
equal(legacyPlan.version, 1, "existing rank-only codes remain recognized")
equal(legacyPlan.notes, "", "legacy codes have no invented notes")
equal(#planner:ValidateOrder(legacyPlan.ranks, legacyPlan.sequence), #sequence, "legacy import generates a complete legal order")
local legacyBuild = planner:Import(legacy)
equal(legacyBuild.name, "Imported build", "legacy imports retain their original default name")
equal(legacyBuild.notes, "", "legacy import stores empty notes")
equal(legacyBuild.ranks[101].rank, ranks[101].rank, "legacy ranks are preserved")
local emptyLegacy = legacy:match("^(WFS1:[^:]+:[^:]+:[^:]+:)")
equal(#planner:DecodeImport(emptyLegacy).sequence, 0, "empty legacy plans still import")
local empty = planner:DecodeImport(Pack("", "", "Empty", ""))
equal(#empty.sequence, 0, "empty full plan has an empty order")
equal(empty.notes, "", "empty full-plan notes round-trip")

local gated = Suite.Copy(sequence)
for index, step in ipairs(gated) do
    if step.node == 102 and step.rank == 1 then gated[1], gated[index] = gated[index], gated[1]; break end
end
local gatedPayload = {}
for _, step in ipairs(gated) do gatedPayload[#gatedPayload + 1] = step.node .. "." .. step.entry .. "." .. step.rank end
local bad = {
    code:gsub("^WFS2:", "WFS3:"), code:gsub("MAGE", "DRUID"), code:gsub(":11:", ":12:", 1),
    code:gsub(planner.model.hash, string.rep("f", 32), 1), code .. ":extra", code .. "\n", " " .. code,
    Pack(rankPayload .. ",101.201.1"), Pack(rankPayload .. ","), Pack("," .. rankPayload),
    Pack((rankPayload:gsub("101%.201%.5", "101.201.0"))), Pack("0.201.1"), Pack("999.201.1"),
    Pack("101.999.1"), Pack("101.201.6"), Pack("101.201.1e2"), Pack(string.rep("9", 400) .. ".201.1"),
    Pack(nil, ""), Pack(nil, orderPayload .. ","), Pack(nil, orderPayload .. ",103.204.1"),
    Pack(nil, (orderPayload:gsub("101%.201%.1", "101.201.2", 1))),
    Pack(nil, (orderPayload:gsub("102%.202%.1", "102.203.1", 1))),
    Pack(nil, "102.202.1," .. orderPayload), Pack(nil, string.rep("101.201.1,", 512) .. "101.201.1"),
    Pack(nil, table.concat(gatedPayload, ",")), -- Same ranks/point count, but a prerequisite is learned too late.
    Pack(string.rep("101.201.1,", 512) .. "101.201.1"),
    Pack("102.202.1", "102.202.1"), -- Structural prerequisite is absent in both final ranks and order.
    Pack(nil, nil, ""), Pack(nil, nil, string.rep("x", 49)), Pack(nil, nil, "bad|name"),
    Pack(nil, nil, "bad\nname"), Pack(nil, nil, nil, "bad|notes"), Pack(nil, nil, nil, "bad\000notes"),
    Pack(nil, nil, nil, "bad\001notes"), Pack(nil, nil, nil, string.rep("x", 513)),
    header .. rankPayload .. ":" .. orderPayload .. ":1:", -- Odd text encoding.
    header .. rankPayload .. ":" .. orderPayload .. ":zz:",
    header .. rankPayload .. ":" .. orderPayload .. ":41:0",
    string.rep("x", planner.shareLimit + 1), { secret = true }, 123,
}
before, selected = #planner:Library(), planner.selected
local undo, redo, guide = planner.undo, planner.redo, planner.guideDB
for index, invalid in ipairs(bad) do
    equal(planner:DecodeImport(invalid), nil, "invalid share payload rejected " .. index)
    equal(planner:Import(invalid), nil, "invalid share import rejected " .. index)
    equal(#planner:Library(), before, "invalid import leaves the library unchanged " .. index)
    equal(planner.selected, selected, "invalid import leaves selection unchanged " .. index)
end
equal(planner.undo, undo, "invalid imports preserve undo history")
equal(planner.redo, redo, "invalid imports preserve redo history")
equal(planner.guideDB, guide, "invalid imports preserve guide state")
local longNotes = string.rep("🙂", 512)
equal(planner:DecodeImport(Pack(nil, nil, "Unicode", longNotes)).notes, longNotes, "maximum UTF-8 notes preserve all original bytes")
equal(planner:DecodeImport(Pack(nil, nil, "Unicode", longNotes .. "🙂")), nil, "notes over the character and byte bounds are rejected")

-- Review is read-only and commits only the originally reviewed code.
planner:Select(1); planner.code:SetText(code)
before, selected = #planner:Library(), planner.selected
local create, nativeTextChanges = CreateFrame, 0
CreateFrame = function(...)
    local frame = create(...)
    if select(4, ...) == "InputScrollFrameTemplate" then
        frame.EditBox:SetScript("OnTextChanged", function() nativeTextChanges = nativeTextChanges + 1 end)
    end
    return frame
end
planner.import.OnClick()
CreateFrame = create
equal(planner.importFrame:IsShown(), true, "review button opens an import preview")
equal(#planner:Library(), before, "opening review creates no draft")
equal(planner.selected, selected, "opening review retains current selection")
equal(planner.importTitle:GetText(), name, "review displays the shared name")
equal(planner.importEdit:GetText():find(notes, 1, true) ~= nil, true, "review discloses exact shared notes")
equal(planner.importEdit:GetText():find("1. " .. planner.model.nodes[sequence[1].node].entries[sequence[1].entry].name, 1, true) ~= nil,
    true, "review displays the actual first ordered point")
local body = planner.importEdit:GetText()
planner.importEdit:SetText("tampered"); planner.importEdit.OnTextChanged(planner.importEdit, true)
equal(planner.importEdit:GetText(), body, "review body rejects user edits")
equal(nativeTextChanges, 1, "read-only hook retains the native scroll input text handler")
planner.code:SetText(emptyLegacy)
planner.importConfirm.OnClick()
SamePlan(planner:Current(), "review confirmation")
equal(#planner:Library(), before + 1, "explicit confirmation adds exactly one separate draft")
equal(planner.importFrame:IsShown(), false, "success closes review")
equal(planner.importCode, nil, "success clears reviewed code")
equal(planner.importEdit:GetText(), "", "success clears displayed notes")
before = #planner:Library(); planner.importConfirm.OnClick()
equal(#planner:Library(), before, "repeated confirmation cannot import again")
planner.code:SetText(legacy); planner:OpenImport()
equal(planner.importSummary:GetText():find("Legacy code", 1, true) ~= nil, true, "review explains generated legacy order")
planner.importCancel.OnClick()
equal(#planner:Library(), before, "cancel does not add a draft")
equal(planner.importCode, nil, "cancel discards pending import")
planner.code:SetText(code); planner:OpenImport(); planner.importEdit.OnEscapePressed()
equal(planner.importFrame:IsShown(), false, "Escape dismisses import review")
planner:OpenImport(); planner:Select(1)
equal(planner.importCode, nil, "switching builds cancels stale review")
planner:OpenImport(); planner:OpenNotes()
equal(planner.importCode, nil, "opening another editor cancels review")
planner:CloseNotes(); planner:OpenImport(); planner:OpenOrder()
equal(planner.importCode, nil, "order editing cancels review")
planner:CloseOrder(); planner:OpenImport()
local modelHash = planner.model.hash
planner.model.hash = string.rep("e", 32); planner.importConfirm.OnClick()
equal(#planner:Library(), before, "tree revision change blocks a stale confirmation")
equal(planner.importCode, nil, "stale revision discards review")
planner.model.hash = modelHash
planner:OpenImport()
local host = planner.model.host
local getConfig = host.GetConfigID
host.GetConfigID = function() return planner.model.config + 1 end
planner.importConfirm.OnClick()
equal(#planner:Library(), before, "native config switch blocks stale confirmation before refresh")
equal(planner.importCode, nil, "native config switch cancels pending review")
host.GetConfigID = getConfig
planner:OpenImport()
local snapshot = planner.Snapshot
planner.Snapshot = function() return nil end
planner:Refresh()
equal(planner.importCode, nil, "unavailable native model clears review immediately")
equal(planner.importFrame:IsShown(), false, "unavailable native model hides review")
planner.Snapshot = snapshot; planner:Refresh(); planner:Select(1)

-- Current-level limits must reject rather than silently truncate a shared plan.
local budget = planner.Budget
planner.Budget = function() return 10, 1, 1 end
Suite.db.talentPlannerRules = true
planner:OpenImport(); planner.importConfirm.OnClick()
equal(#planner:Library(), before, "current-level limit never imports a shortened plan")
equal(planner.importFrame:IsShown(), true, "failed confirmation retains the full review for cancellation")
planner:CloseImport(); planner.Budget = budget; Suite.db.talentPlannerRules = false

-- No native frame construction or queued imports in combat; a hidden review
-- must not return as an actionable confirmation after the secure root reopens.
planner:OpenImport(); SetCombat(true)
planner.events.OnEvent(planner.events, "PLAYER_REGEN_DISABLED")
equal(planner.importCode, nil, "combat cancels pending import")
equal(planner.importEdit:GetText(), "", "combat clears displayed shared notes")
equal(planner:Import(code), nil, "combat refuses direct imports")
equal(planner:Export(), nil, "combat refuses exports")
planner:OpenImport(); planner.importConfirm.OnClick()
equal(#planner:Library(), before, "combat never imports or queues a new build")
SetCombat(false); planner:Render()
equal(planner.importFrame:IsShown(), false, "review stays closed after combat")
planner:OpenImport(); planner.root.OnHide(planner.root)
equal(planner.importCode, nil, "hiding the talent window cancels review")
planner:OpenImport(); planner.expanded = false; planner:Render()
equal(planner.importCode, nil, "collapsing the companion cancels review")
planner.expanded = true
planner:OpenImport()
Suite.db.talentPlanner = false
planner.importConfirm.OnClick()
equal(#planner:Library(), before, "disabled planner cannot confirm a reviewed import")
planner:Apply()
equal(planner.importCode, nil, "disable clears pending review")
Suite.db.talentPlanner = true; planner:Apply(); planner.expanded = true

-- Exercise the advertised bounds with a valid plan larger than the WFS1 field.
-- Independent synthetic nodes isolate serialization size from native class data.
local model = planner.model
local large = { host = model.host, config = model.config, tree = model.tree, class = model.class, hash = model.hash,
    nodes = {}, order = {}, rules = {}, groupInfo = {}, groups = {}, native = {} }
local largeRanks, largeOrder = {}, {}
for index = 1, 512 do
    local node, entry = 90000000 + index, 80000000 + index
    large.order[index] = node
    large.nodes[node] = { max = 1, order = { entry }, entries = { [entry] = { max = 1, name = "Talent " .. index } } }
    large.rules[node] = { incoming = {}, groups = {}, costs = {}, conditions = {}, [entry] = {} }
    largeRanks[node] = { entry = entry, rank = 1 }
    largeOrder[513 - index] = { node = node, entry = entry, rank = 1 }
end
planner.model = large
local current = planner.Current
local largeBuild = { name = "Large plan", notes = longNotes, ranks = largeRanks, sequence = largeOrder,
    tree = large.tree, hash = large.hash }
planner.Current = function() return largeBuild end
local largeCode = planner:Export()
equal(#largeCode > 16384 and #largeCode <= planner.shareLimit, true, "maximum supported plan fits the expanded bounded input")
local decoded = planner:DecodeImport(largeCode)
equal(#decoded.sequence, 512, "maximum plan keeps all 512 points")
equal(decoded.sequence[1].node, largeOrder[1].node, "maximum plan preserves nondefault first point")
equal(decoded.sequence[512].node, largeOrder[512].node, "maximum plan preserves nondefault last point")
equal(decoded.notes, longNotes, "maximum-size plan preserves all notes")
largeBuild.sequence = Suite.Copy(largeOrder); largeBuild.sequence[1].node = { secret = true }
equal(planner:Export(), nil, "unreadable saved order cannot reach export formatting")
largeBuild.sequence = nil
equal(#planner:DecodeImport(planner:Export()).sequence, 512, "saved builds predating point order receive a legal export order")
planner.Current, planner.model = current, model

-- Capacity is checked again at confirmation, even if the library fills after review.
planner:OpenImport()
local builds = planner:Library()
while #builds < planner.limit do
    local copy = Suite.Copy(source); copy.id = nil; builds[#builds + 1] = copy
end
planner.importConfirm.OnClick()
equal(#planner:Library(), planner.limit, "full library cannot evict or overwrite a build")
equal(planner.importFrame:IsShown(), true, "full-library failure retains review")
equal(planner.notice:find("full", 1, true) ~= nil, true, "full-library failure explains the limit")
planner:CloseImport()

Suite.db.talentBuilds, Suite.db.talentPlannerRules = oldLibrary, oldRules
for key in pairs(planner) do planner[key] = nil end
for key, value in pairs(saved) do planner[key] = value end
planner:Render()
