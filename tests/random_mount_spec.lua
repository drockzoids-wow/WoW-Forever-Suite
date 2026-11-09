local Suite, equal, SetCombat, Native = ...
local macros = Suite.Macros
local previous = { db = Suite.macroDB, ownership = Suite.db.macroOwnership, api = C_MountJournal,
    edit = EditMacro, random = math.random, print = Suite.Print, mounted = IsMounted, dismount = Dismount }
local mounted, dismounts = false, 0
IsMounted = function() return mounted end
Dismount = function() dismounts = dismounts + 1 end
SetCombat(false)
MacroFrame:Hide()
Suite.Print = function() end
Suite.db.macroOwnership = {}
macros:Initialize(nil)
local entry
for _, candidate in ipairs(macros:Entries()) do if candidate.recipe == "randomMount" then entry = candidate end end
equal(entry ~= nil, true, "random mount is available alongside every class's shared recipes")
local body, _, pending, ready = macros:Generate(entry, { incomplete = true })
equal(body, "#showtooltip\n/stopmacro [combat]\n/wfs randommount", "mount recipe is independent of bag data and has a stable command")
equal(pending, false, "mount recipe does not wait for consumable data")
equal(ready, true, "mount macro can be created before riding is learned")
local gui, oldSelected = Suite.GUI, Suite.GUI.macroSelected
gui.macroSelected = entry; gui:RefreshMacros()
equal(gui.macroChoose:IsShown(), false, "random mount has no inventory item picker")
equal(gui.macroCombat:IsShown(), false, "random mount has no combat consumable option")
equal(gui.macroSave:IsEnabled(), true, "random mount exposes the existing Create macro action")
gui.macroSelected = oldSelected
local ids, rows, available, calls, reads = {}, {}, {}, {}, 0
C_MountJournal = {
    GetMountIDs = function() reads = reads + 1; return ids end,
    GetMountInfoByID = function(id)
        local row = rows[id]
        if row == "error" then error("Unavailable mount") end
        if not row then return end
        return row.name or "Mount " .. id, 123, row.icon or (1000 + id), false,
            row.usable, 1, false, false, nil, row.hidden, row.collected
    end,
    GetMountUsabilityByID = function(id, indoors)
        equal(indoors, true, "mount eligibility includes the current location")
        return available[id]
    end,
    SummonByID = function(id) calls[#calls + 1] = id end,
}
local icon, writes, choice = nil, 0, 1
EditMacro = function(index, name, texture, text)
    icon, writes = texture, writes + 1
    return previous.edit(index, name, texture, text)
end
math.random = function(count) equal(choice <= count, true, "random choice stays in the eligible pool"); return choice end
local function Use() SlashCmdList.WOWFOREVERSUITE("randommount") end
Use()
equal(reads, 0, "uncreated recipe cannot summon or enumerate mounts")
equal(macros:Save(entry), true, "Macros page can explicitly create the mount macro")
local index = macros:Find(entry.name)
equal(Native()[index].body, body, "created General macro retains its preview text")
Use()
equal(#calls, 0, "empty collection does not attempt a summon")
equal(writes, 0, "empty collection does not change the icon")
local beforeReads = reads
mounted = true; Use()
equal(dismounts, 1, "mounted use requests one dismount even with an empty mount pool")
equal(reads, beforeReads, "dismount skips collection enumeration")
equal(writes, 0, "dismount preserves the existing macro icon")
equal(#calls, 0, "dismount never falls through to a summon on the same press")
SetCombat(true); Use(); SetCombat(false)
equal(dismounts, 1, "combat retains the macro's existing no-action rule")
local dismountAPI = Dismount
Dismount = nil; Use()
equal(#calls, 0, "unavailable dismount never falls back to mounting")
Dismount = function() error("Unavailable") end; Use()
equal(#calls, 0, "refused dismount never falls back to mounting")
Dismount = dismountAPI
mounted = { secret = true }; Use()
equal(dismounts, 1, "restricted mounted state cannot request dismount")
equal(reads, beforeReads, "restricted mounted state cannot enumerate mounts")
IsMounted = nil; Use()
equal(reads, beforeReads, "missing mounted status cannot attempt a new mount")
IsMounted = function() error("Unavailable") end; Use()
equal(reads, beforeReads, "failed mounted query cannot attempt a new mount")
IsMounted = function() return mounted end
mounted = false
ids = { 1, 2, 3, 4, 5, 6, 7, 8, 1, { secret = true } }
rows = {
    { usable = true, hidden = false, collected = true },
    { usable = true, hidden = false, collected = true },
    { usable = false, hidden = false, collected = true },
    { usable = true, hidden = true, collected = true },
    { usable = true, hidden = false, collected = false },
    { usable = { secret = true }, hidden = false, collected = true },
    { usable = true, hidden = false, collected = true },
    "error",
}
available = { true, true, true, true, true, true, false }
Use()
equal(calls[1], 1, "first eligible collected mount is summoned")
equal(icon, 1001, "icon follows the selected mount")
equal(Native()[index].body, body, "selection leaves command text and ownership stable")
equal(Suite.db.macroOwnership[entry.name], body, "icon updates retain confirmed Suite ownership")
choice = 2; Use()
equal(calls[2], 2, "another press chooses again from the full eligible collection")
equal(icon, 1002, "second selection updates the same macro's icon")
equal(macros:Find(entry.name), index, "icon updates retain the action-bar macro index")
ids = { 9 }; rows[9] = { usable = true, hidden = false, collected = true }; available[9] = true
choice = 1; Use()
equal(calls[3], 9, "newly acquired mounts are included without editing the macro")
local selectedIcon, selectedWrites, selectedReads = icon, writes, reads
mounted = true; Use(); mounted = false
equal(dismounts, 2, "press after mounting requests dismount")
equal(icon, selectedIcon, "dismount retains the last selected mount icon")
equal(writes, selectedWrites, "dismount does not rewrite the selected macro")
equal(reads, selectedReads, "dismount does not rebuild the mount pool")
equal(#calls, 3, "dismount after selection does not summon another mount")
for _, field in ipairs({ "usable", "hidden", "collected", "icon" }) do
    local old = rows[9][field]; rows[9][field] = { secret = true }
    Use(); equal(#calls, 3, "restricted " .. field .. " cannot enter eligibility or icon writes")
    rows[9][field] = old
end
available[9] = { secret = true }; Use()
equal(#calls, 3, "restricted location eligibility cannot trigger a summon")
available[9] = true
local oldReads, oldWrites = reads, writes
SetCombat(true); Use()
equal(reads, oldReads, "combat performs no mount query")
equal(writes, oldWrites, "combat performs no macro mutation")
SetCombat(false); MacroFrame:Show(); Use()
equal(reads, oldReads, "open native editor prevents icon changes and summoning")
MacroFrame:Hide()
Native()[index].body = "/say Custom mount"
Use(); equal(#calls, 3, "external body edits pause mount execution")
equal(Native()[index].body, "/say Custom mount", "external edits are preserved")
Native()[index].body = body
local duplicate = index == 119 and 118 or 119
local kept = Native()[duplicate]; Native()[duplicate] = { name = entry.name, body = body }
Use(); equal(#calls, 3, "duplicate General names cannot select an icon target")
Native()[duplicate] = kept
local api = C_MountJournal; C_MountJournal = nil
Use(); equal(#calls, 3, "missing journal APIs are reported without attempting a summon")
C_MountJournal = api
local getter = api.GetMountIDs; api.GetMountIDs = function() return { secret = true } end
Use(); equal(#calls, 3, "restricted collection cannot trigger a summon")
api.GetMountIDs = function() error("Not ready") end
Use(); equal(#calls, 3, "failed collection reads cannot trigger a summon")
api.GetMountIDs = getter
EditMacro = function() error("No edit") end
Use(); equal(#calls, 3, "refused icon update does not claim a selected action")
EditMacro, math.random, C_MountJournal, Suite.Print = previous.edit, previous.random, previous.api, previous.print
IsMounted, Dismount = previous.mounted, previous.dismount
Suite.macroDB, Suite.db.macroOwnership = previous.db, previous.ownership
