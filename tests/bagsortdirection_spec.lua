local Suite, equal, SetCombat = ...
local sorter = Suite.BagSort
local oldDB, oldPending, oldContainer = Suite.db, Suite.pending, C_Container
local migrated = Suite.InitializeDB({ reverseBagSort = true, bagSortDirectionRestore = false, reverseCombinedBags = true })
equal(migrated.reverseBagSlots, true, "old enabled direction choice migrates to within-bag display")
equal(migrated.reverseBagSort, nil, "obsolete native direction preference is retired")
equal(migrated.reverseCombinedBags, true, "migration preserves bag section order")
equal(migrated.bagSortDirectionRestore, false, "migration retains the false native backup until restored")
equal(Suite.InitializeDB({ reverseBagSort = false }).reverseBagSlots, false, "old disabled choice stays off")
equal(Suite.InitializeDB({ reverseBagSort = { secret = true } }).reverseBagSlots, false, "restricted legacy choice is not compared")
equal(Suite.InitializeDB({ reverseBagSort = true, reverseBagSlots = false }).reverseBagSlots, false, "explicit new choice wins over old preference")
equal(Suite.InitializeDB(migrated).reverseBagSlots, true, "migration is stable across initialization")
Suite.db, Suite.pending = migrated, {}
local direction, reads, writes, reject, noChange = true, 0, {}, false, false
local function GetDirection() reads = reads + 1; return direction end
local function SetDirection(value)
    assert(not InCombatLockdown(), "legacy preference restoration waits through combat")
    assert(type(value) == "boolean", "restoration uses ordinary booleans only")
    writes[#writes + 1] = value
    if reject then error("restoration denied") end
    if not noChange then direction = value end
end
C_Container = {
    GetSortBagsRightToLeft = GetDirection, SetSortBagsRightToLeft = SetDirection,
    SortBags = function() error("migration/restoration must not sort or move items") end,
    SetInsertItemsLeftToRight = function() error("insertion direction must stay native") end,
    SetBagSlotFlag = function() error("bag exclusions must stay native") end,
}
local function Drain()
    local pending = Suite.pending; Suite.pending = {}
    for _, callback in pairs(pending) do callback() end
end
sorter:Apply()
equal(direction, false, "upgrading restores native backpack-first cleanup priority")
equal(Suite.db.bagSortDirectionRestore, nil, "confirmed restoration releases legacy backup")
equal(Suite.db.reverseBagSlots, true, "restoration preserves replacement display choice")
local count = reads; sorter:Apply()
equal(reads, count, "without a legacy backup no native direction API is queried")
equal(#writes, 1, "within-bag display never reapplies the old native reversal")
Suite.db.bagSortDirectionRestore, direction = true, false; sorter:Apply()
equal(direction, true, "an original true preference is restored correctly")
Suite.db.bagSortDirectionRestore, direction = false, true
SetCombat(true); sorter:Apply()
equal(direction, true, "legacy restoration makes no combat write")
equal(type(Suite.pending.bagSortDirection), "function", "legacy combat restoration stays queued")
Suite.db.reverseBagSlots = false; sorter:Apply()
equal(type(Suite.pending.bagSortDirection), "function", "turning display off retains required native restoration")
SetCombat(false); Drain(); equal(direction, false, "combat exit completes restoration")
for _, unknown in ipairs({ { secret = true }, "true", 1 }) do
    Suite.db.bagSortDirectionRestore, direction = false, unknown
    count = #writes; sorter:Apply()
    equal(#writes, count, "unknown native direction is never compared or overwritten")
    equal(Suite.db.bagSortDirectionRestore, false, "unconfirmed restoration retains the backup")
end
direction, reject = true, true; sorter:Apply()
equal(Suite.db.bagSortDirectionRestore, false, "rejected restoration retains backup")
reject, noChange = false, true; sorter:Apply()
equal(Suite.db.bagSortDirectionRestore, false, "no-op restoration is not treated as success")
noChange = false; sorter:Apply(); equal(direction, false, "a later allowed restoration completes")
for _, method in ipairs({ "GetSortBagsRightToLeft", "SetSortBagsRightToLeft" }) do
    local original = C_Container[method]; C_Container[method] = nil
    Suite.db.bagSortDirectionRestore, direction = false, true
    count = #writes; sorter:Apply()
    equal(#writes, count, "missing native restoration capability skips safely")
    equal(Suite.db.bagSortDirectionRestore, false, "missing restoration capability retains backup")
    C_Container[method] = original
end
sorter:Apply()
for _, value in ipairs({ { secret = true }, "false", 0 }) do
    equal(Suite.InitializeDB({ bagSortDirectionRestore = value }).bagSortDirectionRestore, nil,
        "invalid native restoration data is discarded")
end
Suite.db, Suite.pending, C_Container = oldDB, oldPending, oldContainer
SetCombat(false)
