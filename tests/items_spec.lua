-- Partial/restricted metadata must not crash a hover or produce a guessed upgrade.
local Suite, equal = ...
local oldAPI, oldLevel, oldLink, oldPlayerInfo = C_Item, UnitLevel, GetInventoryItemLink, C_PlayerInfo
local required, playerLevel, equipped, stats = 1, 30, nil, { ITEM_MOD_INTELLECT_SHORT = 8 }
C_Item = {
    GetItemInfo = function() return "Item", "item:1", 2, 20, required, "Armor", "Cloth", 1, "INVTYPE_HEAD" end,
    GetDetailedItemLevelInfo = function() return 20 end,
    IsUsableItem = function() return true end,
    GetItemStats = function() return stats end,
}
UnitLevel = function() return playerLevel end
GetInventoryItemLink = function() return equipped end
local function Hidden()
    return setmetatable({ secret = true }, { __index = function() error("restricted metadata was indexed") end })
end
local canEquip=true
C_PlayerInfo={CanUseItem=function(id)equal(id,1234,"equipment eligibility receives a numeric item ID");return canEquip end}
C_Item.GetItemInfoInstant=function()return 1234 end
C_Item.IsUsableItem=function()return false end
equal(Suite.Items:UpgradeDelta("item:1"),1,"passive usable equipment qualifies even when action-use predicate is false")
canEquip=false
equal(Suite.Items:UpgradeDelta("item:1"),nil,"player-ineligible equipment is still excluded")
canEquip=Hidden()
equal(Suite.Items:UpgradeDelta("item:1"),nil,"restricted player eligibility is never treated as usable")
C_PlayerInfo.CanUseItem=function()error("native eligibility unavailable")end
equal(Suite.Items:UpgradeDelta("item:1"),nil,"rejected player eligibility does not fall back to a guessed hint")
C_PlayerInfo.CanUseItem=function()return true end
C_Item.GetItemInfoInstant=function()return Hidden()end
equal(Suite.Items:UpgradeDelta("item:1"),nil,"restricted item IDs do not reach player eligibility")
C_PlayerInfo=nil;C_Item.IsUsableItem=function()return true end
equal(Suite.Items:UpgradeDelta("item:1"), 1, "confirmed empty slot has an independent hint result")
stats = {}
local delta, detail = Suite.Items:UpgradeDelta("item:1")
equal(delta ~= nil,true,"usable zero-weight gear fills an empty equipment slot")
equal(detail.emptySlot,true,"empty-slot hint has an explicit tooltip reason")
equipped="item:2"
equal(Suite.Items:UpgradeDelta("item:1"),nil,"zero-weight gear does not upgrade an occupied slot")
equipped=nil;stats={ ITEM_MOD_INTELLECT_SHORT = 8 }
required = nil
equal(Suite.Items:UpgradeDelta("item:1"), nil, "missing required level waits instead of comparing nil")
required = Hidden()
equal(Suite.Items:UpgradeDelta("item:1"), nil, "restricted required level is never compared")
required, playerLevel = 1, Hidden()
equal(Suite.Items:UpgradeDelta("item:1"), nil, "restricted player level is never compared")
playerLevel, equipped = 30, Hidden()
equal(Suite.Items:UpgradeDelta("item:1"), nil, "restricted equipped links are never tested for truth")
equipped, stats = "item:2", Hidden()
equal(Suite.Items:UpgradeDelta("item:1"), nil, "restricted stat tables are never indexed")
stats = { ITEM_MOD_INTELLECT_SHORT = Hidden() }
equal(Suite.Items:UpgradeDelta("item:1"), nil, "restricted weighted stats do not become a guessed zero")
equal(Suite.Scoring.Score({ RESISTANCE0_NAME = Hidden() }, "tank"), nil, "restricted armor is not selected with a truth test")
equal(Suite.Scoring.Score({ ITEM_MOD_INTELLECT_SHORT = math.huge }, "caster"), nil, "nonfinite stats do not produce upgrade markers")
equal(Suite.Scoring.Compare(Hidden(), { 1 }), nil, "restricted candidate scores are not compared")
equal(Suite.Scoring.Compare(5, { Hidden() }), nil, "restricted equipped scores are not compared")
equal(Suite.Scoring.Compare(5, Hidden()), nil, "restricted equipped lists are not iterated")
stats = { ITEM_MOD_INTELLECT_SHORT = 8 }
C_Item.GetDetailedItemLevelInfo = function() return Hidden() end
equal(Suite.Items:GetInfo("item:1"), nil, "restricted item level never enters tooltip arithmetic")
C_Item.GetDetailedItemLevelInfo = function() return nil end
C_Item.GetItemInfo = function() return "Item", "item:1", 2, nil, 1, "Armor", "Cloth", 1, "INVTYPE_HEAD" end
equal(Suite.Items:GetInfo("item:1"), nil, "incomplete item level waits for metadata")
C_Item, UnitLevel, GetInventoryItemLink = oldAPI, oldLevel, oldLink
C_PlayerInfo=oldPlayerInfo
