-- Exercise real hint/tooltip paths with competing levels, DPS and complete hand sets.
local Suite, equal, Frame = ...
local saved = { class = UnitClass, api = C_Item, link = GetInventoryItemLink, dual = CanDualWield,
    level = UnitLevel, db = Suite.db, apply = Suite.Apply, page = Suite.GUI.page }
UnitClass = function() return "Warlock", "WARLOCK", 9 end
local records, equipment = {}, {}
local function Item(name, loc, level, intellect, dps, strength)
    records[name] = { link = name, loc = loc, level = level, required = 1, usable = true,
        stats = { ITEM_MOD_INTELLECT_SHORT = intellect, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = dps,
            ITEM_MOD_STRENGTH_SHORT = strength } }
end
Item("helmOld", "INVTYPE_HEAD", 20, 10)
Item("helmLevel", "INVTYPE_HEAD", 30, 2)
Item("helmStats", "INVTYPE_HEAD", 15, 15)
Item("main", "INVTYPE_WEAPONMAINHAND", 40, 10, 20)
Item("off", "INVTYPE_WEAPONOFFHAND", 30, 10, 10)
Item("flex", "INVTYPE_WEAPON", 45, 11, 22)
Item("offDPS", "INVTYPE_WEAPONOFFHAND", 25, 10, 12)
Item("staff", "INVTYPE_2HWEAPON", 50, 25, 30)
Item("staffWorse", "INVTYPE_2HWEAPON", 55, 5, 15)
Item("staffOld", "INVTYPE_2HWEAPON", 40, 22, 26)
Item("shield", "INVTYPE_SHIELD", 35, 4)
Item("holdable", "INVTYPE_HOLDABLE", 45, 12)
Item("ranged", "INVTYPE_RANGED", 30, 1, 10)
Item("rangedBetter", "INVTYPE_RANGEDRIGHT", 35, 1, 12)
Item("relic", "INVTYPE_RELIC", 40, 8)
Item("ringOld", "INVTYPE_FINGER", 20, 8)
Item("ringOther", "INVTYPE_FINGER", 40, 12)
Item("ringNew", "INVTYPE_FINGER", 30, 10)
local statsCalls, dual = 0, true
C_Item = {
    GetItemInfo = function(link)
        local item = records[link]
        if item then return "Item", item.link, 2, item.level, item.required, "Weapon", "", 1, item.loc, 1, 0, 4, 1 end
    end,
    GetDetailedItemLevelInfo = function(link) return records[link] and records[link].level end,
    IsUsableItem = function(link) return records[link] and records[link].usable end,
    GetItemStats = function(link) statsCalls = statsCalls + 1; return records[link] and records[link].stats end,
}
UnitLevel = function() return 60 end
GetInventoryItemLink = function(_, slot) return equipment[slot] end
CanDualWield = function() return dual end
Suite.db = Suite.InitializeDB(nil)
Suite.db.upgradeHints, Suite.db.scorePreset = true, "caster"
equal(Suite.db.upgradePreference, "stats", "existing behavior remains the default")
equal(Suite.InitializeDB({ upgradePreference = "ilevel" }).upgradePreference, "ilevel", "level preference survives initialization")
equal(Suite.InitializeDB({ upgradePreference = "bogus" }).upgradePreference, "stats", "invalid preference repaired")
equal(Suite.InitializeDB({ upgradePreference = { secret = true } }).upgradePreference, "stats", "restricted preference repaired")
equipment[1] = "helmOld"
equal(Suite.Items:UpgradeDelta("helmLevel"), nil, "stats mode omits higher-level weaker armor")
equal(Suite.Items:UpgradeDelta("helmStats"), 5, "stats mode includes lower-level stronger armor")
Suite.db.upgradePreference = "ilevel"
equal(Suite.Items:UpgradeDelta("helmLevel"), 10, "level mode includes higher-level weaker armor")
equal(Suite.Items:UpgradeDelta("helmStats"), nil, "level mode omits lower-level stronger armor")
equal(statsCalls, 4, "level mode does not query bonus stats")
equipment[11], equipment[12] = "ringOld", "ringOther"
equal(Suite.Items:UpgradeDelta("ringNew"), 10, "level mode replaces the lower-level ring")

equipment[16], equipment[17] = "main", "off"
local delta, detail = Suite.Items:UpgradeDelta("staff")
equal(delta, 15, "two-hander level compares against the two-hand average")
equal(detail.slot, "Both hands", "two-hander discloses both replaced hands")
delta, detail = Suite.Items:UpgradeDelta("flex")
equal(delta, 7.5, "flexible one-hander chooses better valid hand replacement")
equal(detail.slot, "Off hand", "flexible weapon identifies its best hand")
dual = false
delta, detail = Suite.Items:UpgradeDelta("flex")
equal(delta, 2.5, "non-dual-wielder only receives main-hand replacement")
equal(detail.slot, "Main hand", "main-hand replacement is explicit")
equal(Suite.Items:UpgradeDelta("offDPS"), nil, "off-hand weapon requires dual-wield capability")
dual = true
Suite.db.upgradePreference, Suite.db.scorePreset = "stats", "physical"
equal(Suite.Items:UpgradeDelta("offDPS"), 7, "physical off-hand score includes half-weighted DPS")
equal(Suite.Items:UpgradeDelta("staff"), 35, "two-hander counts its DPS once against complete dual-wield baseline")
equal(Suite.Items:UpgradeDelta("staffWorse"), nil, "higher-level lower-DPS two-hander has no stats hint")
Suite.db.scorePreset = "caster"
equal(Suite.Items:UpgradeDelta("staff"), 5, "caster counts both hands bonuses before staff replacement")
equal(Suite.Items:UpgradeDelta("staffWorse"), nil, "caster loses both bonuses when replacing a pair")
equipment[16], equipment[17] = "staffOld", nil
equal(Suite.Items:UpgradeDelta("flex"), nil, "one-hander cannot assume an unowned companion against a staff")
equal(Suite.Items:UpgradeDelta("holdable"), nil, "off-hand item cannot coexist with equipped two-hander")
equipment[17] = "off"
equal(Suite.Items:UpgradeDelta("staff"), nil, "unsupported two-handed dual-wield state is omitted")
equipment[16], equipment[17] = "main", "shield"
equal(Suite.Items:UpgradeDelta("holdable"), 8, "held-in-offhand bonuses compare against the actual offhand")
equipment[18] = "ranged"
Suite.db.scorePreset = "physical"
equal(Suite.Items:UpgradeDelta("rangedBetter"), 14, "ranged weapon DPS compares in ranged slot only")
equal(Suite.Items:UpgradeDelta("relic"), nil, "relic does not replace ranged weapon in a guessed configuration")
equipment[18] = nil
Suite.db.scorePreset = "caster"
equal(Suite.Items:UpgradeDelta("relic"), 8, "relic bonuses can fill an empty ranged slot")

Item("plainGloves", "INVTYPE_HAND", 5)
Item("plainRing", "INVTYPE_FINGER", 5)
Item("plainWeapon", "INVTYPE_WEAPON", 5, nil, 2)
for _, preference in ipairs({ "stats", "ilevel" }) do
    Suite.db.upgradePreference=preference
    equipment[10]=nil
    local emptyDelta, emptyDetail=Suite.Items:UpgradeDelta("plainGloves")
    equal(emptyDelta~=nil,true,preference.." marks usable gloves for a bare slot")
    equal(emptyDetail.emptySlot,true,preference.." explains the empty-slot reason")
    records.plainGloves.usable=false
    equal(Suite.Items:UpgradeDelta("plainGloves"),nil,preference.." does not mark unusable gloves for an empty slot")
    records.plainGloves.usable=true
    equipment[11],equipment[12]="uncachedRing",nil
    equal(Suite.Items:UpgradeDelta("plainRing")~=nil,true,preference.." recognizes an empty second ring independently of the occupied ring's stats")
end
Suite.db.upgradePreference="stats"
equipment[16],equipment[17]=nil,nil
local emptyDelta,emptyDetail=Suite.Items:UpgradeDelta("plainWeapon")
equal(emptyDelta~=nil,true,"zero-weight caster weapon can fill a permitted empty main hand")
equal(emptyDetail.emptySlot,true,"empty weapon hint uses the empty-slot reason")
equipment[16]="staffOld"
equal(Suite.Items:UpgradeDelta("holdable"),nil,"two-hander's offhand is not treated as a free equipment slot")

local hidden = setmetatable({ secret = true }, { __index = function() error("secret indexed") end })
equipment[16], equipment[17] = "main", "off"
Suite.db.scorePreset = "physical"
local oldDPS = records.flex.stats.ITEM_MOD_DAMAGE_PER_SECOND_SHORT
records.flex.stats.ITEM_MOD_DAMAGE_PER_SECOND_SHORT = hidden
equal(Suite.Items:UpgradeDelta("flex"), nil, "restricted candidate DPS cannot produce a hint")
records.flex.stats.ITEM_MOD_DAMAGE_PER_SECOND_SHORT = nil
equal(Suite.Items:UpgradeDelta("flex"), nil, "missing physical DPS cannot become zero")
records.flex.stats.ITEM_MOD_DAMAGE_PER_SECOND_SHORT = math.huge
equal(Suite.Items:UpgradeDelta("flex"), nil, "nonfinite DPS omitted")
records.flex.stats.ITEM_MOD_DAMAGE_PER_SECOND_SHORT = oldDPS
equipment[17] = "uncached"
equal(Suite.Items:UpgradeDelta("flex"), nil, "unknown equipped hand prevents partial pair comparison")
equipment[17] = hidden
equal(Suite.Items:UpgradeDelta("flex"), nil, "restricted equipped hand never becomes empty")
equipment[17] = "off"
records.flex.required = 70
equal(Suite.Items:UpgradeDelta("flex"), nil, "weapon level requirement enforced")
records.flex.required, records.flex.usable = 1, false
equal(Suite.Items:UpgradeDelta("flex"), nil, "unusable weapons omitted")
records.flex.usable = true
local oldStats = C_Item.GetItemStats
C_Item.GetItemStats = function() error("unavailable") end
equal(Suite.Items:UpgradeDelta("flex"), nil, "rejected stat API does not escape into item hover")
Suite.db.upgradePreference = "ilevel"
equal(Suite.Items:UpgradeDelta("flex"), 7.5, "explicit level mode works without stat capability")
C_Item.GetItemStats = oldStats
local oldInventory = GetInventoryItemLink
GetInventoryItemLink = function() error("unavailable") end
equal(Suite.Items:UpgradeDelta("flex"), nil, "failed equipment read never authorizes comparison with empty hands")
GetInventoryItemLink = oldInventory
CanDualWield = function() return hidden end
delta, detail = Suite.Items:UpgradeDelta("flex")
equal(detail.slot, "Main hand", "restricted capability cannot authorize off-hand placement")
CanDualWield = function() return true end

local button, record = Frame(), {}
button.GetItemLink = function() return "staffWorse" end
Suite.db.upgradePreference = "stats"
Suite.Items:Update(button, record)
equal(record.arrow.text, "", "real icon path hides worse stats weapon")
Suite.db.upgradePreference = "ilevel"
Suite.Items:Update(button, record)
equal(record.arrow.text, "+", "real icon path shows higher-level weapon marker")
Suite.db.upgradeHints = false
Suite.Items:Update(button, record)
equal(record.arrow.text, "", "disabled hints clear weapon marker")
Suite.db.upgradeHints = true
-- Equipped buttons retain levels without scoring themselves against the second slot.
do
    local oldEquipment, oldPreference, oldLevels, oldPreset = equipment, Suite.db.upgradePreference, Suite.db.itemLevels, Suite.db.scorePreset
    local oldExists, oldLocationLink = C_Item.DoesItemExist, C_Item.GetItemLink
    Item("trinketStrong", "INVTYPE_TRINKET", 40, 12)
    Item("trinketWeak", "INVTYPE_TRINKET", 20, 4)
    local candidate
    C_Item.DoesItemExist = function() return true end
    C_Item.GetItemLink = function() return candidate end
    Suite.db.itemLevels, Suite.db.scorePreset = true, "caster"
    for _, preference in ipairs({ "stats", "ilevel" }) do
        Suite.db.upgradePreference = preference
        for _, case in ipairs({
            { "ringOther", 11, 12, "ringOld" },
            { "trinketStrong", 13, 14, "trinketWeak" },
            { "flex", 16, 17, "off" },
        }) do
            candidate = case[1]; equipment = { [case[2]] = candidate, [case[3]] = case[4] }
            local location = { bagID = 0, slotIndex = 1 }
            local ownButton, ownRecord = Frame(), {}
            ownButton.GetItemLocation = function() return location end
            Suite.Items:Update(ownButton, ownRecord)
            equal(ownRecord.arrow.text, "+", preference .. " " .. candidate .. " still marks a separate bag copy for the weaker second slot")
            location = { equipmentSlotIndex = case[2] }
            Suite.Items:Update(ownButton, ownRecord)
            equal(ownRecord.equipped, true, "equipment origin is flagged")
            equal(ownRecord.arrow.text, "", preference .. " clears the plus for the equipped instance")
            equal(ownRecord.level.text, records[candidate].level, "equipped item level remains visible")
            location = { bagID = 0, slotIndex = 1 }
            Suite.Items:Update(ownButton, ownRecord)
            equal(ownRecord.equipped, false, "recycled button clears equipped flag after moving to a bag")
            equal(ownRecord.arrow.text, "+", "the separate bag candidate can qualify again")
            location = { equipmentSlotIndex = { secret = true } }
            Suite.Items:Update(ownButton, ownRecord)
            equal(ownRecord.arrow.text, "", "restricted equipped location never produces a marker")
        end
    end
    equipment, Suite.db.upgradePreference, Suite.db.itemLevels = oldEquipment, oldPreference, oldLevels
    C_Item.DoesItemExist, C_Item.GetItemLink = oldExists, oldLocationLink
    Suite.db.scorePreset = oldPreset
end
local tooltip = Frame()
Suite.Tooltips:Item(tooltip, { hyperlink = "staffWorse" })
equal(tooltip.lines[1][1], "Higher weapon-set item level · +20.0 (Both hands)", "weapon tooltip identifies level basis and replaced hands")
Suite.db.upgradePreference, Suite.db.scorePreset = "stats", "caster"
tooltip = Frame()
Suite.Tooltips:Item(tooltip, { hyperlink = "staff" })
equal(tooltip.lines[1][1], "Possible weapon upgrade · +5.0 (Caster; Both hands)", "weapon tooltip discloses stat preset")

records.plainGloves.stats=nil;equipment[10]=nil
local gloveButton,gloveRecord=Frame(),{}
gloveButton.GetItemLink=function()return "plainGloves"end
Suite.Items:Update(gloveButton,gloveRecord)
equal(gloveRecord.arrow.text,"+","real icon path marks loaded empty-slot gloves with no native stat table")
equal(gloveRecord.arrow.drawSublevel,7,"upgrade marker draws on the high overlay layer")
tooltip=Frame();Suite.Tooltips:Item(tooltip,{hyperlink="plainGloves"})
equal(tooltip.lines[1][1],"Fills an empty equipment slot","no-stat gloves receive the correct real tooltip reason")
equipment[10]="plainGloves"
Suite.Items:Update(gloveButton,gloveRecord)
equal(gloveRecord.arrow.text,"","equipping no-stat gloves clears the empty-slot marker")
equipment[10]=nil
local originalStats=C_Item.GetItemStats;C_Item.GetItemStats=function()error("empty slots must not require stat data")end
equal(Suite.Items:UpgradeDelta("plainGloves"),1,"empty slot hint never queries unavailable or rejected stat data")
C_Item.GetItemStats=nil
equal(Suite.Items:UpgradeDelta("plainGloves"),1,"empty slot hint does not require a stat capability")
C_Item.GetItemStats=originalStats
local oldPlayerInfo,oldInstant,oldUsable=C_PlayerInfo,C_Item.GetItemInfoInstant,C_Item.IsUsableItem
C_Item.GetItemInfoInstant=function()return 1234 end
C_Item.IsUsableItem=function()return false end
C_PlayerInfo={CanUseItem=function()return true end}
Suite.Items:Update(gloveButton,gloveRecord)
equal(gloveRecord.arrow.text,"+","bag icon uses player gear eligibility even when passive gloves are not action-usable")
tooltip=Frame();Suite.Tooltips:Item(tooltip,{hyperlink="plainGloves"})
equal(tooltip.lines[1][1],"Fills an empty equipment slot","hover uses the same player eligibility as the icon")
C_PlayerInfo.CanUseItem=function()return false end
Suite.Items:Update(gloveButton,gloveRecord)
equal(gloveRecord.arrow.text,"","player-ineligible armor clears the real bag marker")
C_PlayerInfo,C_Item.GetItemInfoInstant,C_Item.IsUsableItem=oldPlayerInfo,oldInstant,oldUsable

Suite.Apply = function() end
Suite.GUI:Select("items")
equal(Suite.GUI.rows[5].value.text, "Stats", "comparison control displays current preference")
Suite.GUI.rows[5].OnClick()
equal(Suite.db.upgradePreference, "ilevel", "comparison control changes saved preference")
equal(Suite.GUI.rows[5].value.text, "Item level", "comparison control refreshes its label")
local search = Suite.SettingsCatalog:Search("prefer higher ilevel")
equal(search[1].key, "upgradePreference", "new comparison option is searchable")
Suite.GUI.rows[5].OnClick()
equal(Suite.db.upgradePreference, "stats", "comparison control returns to stats")
UnitClass = saved.class
C_Item, GetInventoryItemLink, CanDualWield, UnitLevel = saved.api, saved.link, saved.dual, saved.level
Suite.db, Suite.Apply = saved.db, saved.apply
Suite.GUI:Select(saved.page or "overview")
