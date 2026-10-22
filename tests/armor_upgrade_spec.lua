local Suite, equal, Frame, setCombat = ...
local saved = { api = C_Item, playerInfo = C_PlayerInfo, class = UnitClass, level = UnitLevel,
    inventory = GetInventoryItemLink, db = Suite.db, timer = C_Timer, create = CreateFrame }
local class, level, subtype, usable = "WARRIOR", 40, 4, true
local itemClass, equipLoc, required, improvement = 4, "INVTYPE_CHEST", 1, 8
local equipped, noStats = "old", false
C_Item = {
    GetItemInfo = function(item)
        return item, item, 2, item == "old" and 10 or 20, required, "Localized type", "Localized subtype", 1,
            equipLoc, 1, 0, itemClass, subtype
    end,
    GetDetailedItemLevelInfo = function(item) return item == "old" and 10 or 20 end,
    GetItemInfoInstant = function() return 1234 end,
    GetItemStats = function(item)
        if noStats then return end
        return { ITEM_MOD_STRENGTH_SHORT = item == "old" and 1 or improvement }
    end,
    GetItemSubClassInfo = function(_, id) return ({ "Cloth", "Leather", "Mail", "Plate" })[id] end,
}
C_PlayerInfo = { CanUseItem = function() return usable end }
UnitClass = function() return "Localized class", class end
UnitLevel = function() return level end
GetInventoryItemLink = function() return equipped end
Suite.db = Suite.InitializeDB(nil)
Suite.db.upgradeHints, Suite.db.scorePreset = true, "physical"
local button, record = Frame(), {}
button.GetItemLink = function() return "candidate" end
local function Marker(preferred, label)
    Suite.Items:Update(button, record)
    equal(record.arrow.text, "+", label .. " remains an upgrade")
    equal(record.arrow.textColor[1], preferred and 0.2 or 1, label .. " uses the expected marker color")
    equal(record.arrow.textColor[2], preferred and 1 or 0.82, label .. " has a distinct green/yellow channel")
end
Marker(true, "warrior plate at level 40")
local delta = Suite.Items:UpgradeDelta("candidate")
subtype = 3; Marker(false, "warrior mail at level 40")
equal(Suite.Items:UpgradeDelta("candidate"), delta, "nonpreferred armor keeps the same upgrade score")
subtype = 2; Marker(false, "third qualifying reward in leather")
level, subtype = 39, 3; Marker(true, "warrior mail below level 40")
subtype = 1; Marker(false, "warrior cloth below level 40")
for _, entry in ipairs({
    { "PALADIN", 39, 3 }, { "PALADIN", 40, 4 },
    { "HUNTER", 39, 2 }, { "HUNTER", 40, 3 },
    { "SHAMAN", 39, 2 }, { "SHAMAN", 40, 3 },
    { "ROGUE", 20, 2 }, { "DRUID", 60, 2 },
    { "MAGE", 20, 1 }, { "PRIEST", 60, 1 }, { "WARLOCK", 1, 1 },
}) do
    class, level, subtype = unpack(entry)
    Marker(true, class .. " preferred armor at level " .. level)
    subtype = subtype == 1 and 2 or 1
    Marker(false, class .. " nonpreferred armor")
end
class, level, subtype = "WARRIOR", 40, 3
local function Tooltip()
    local tooltip = Frame()
    tooltip.AddLine = function(self, ...) self.lines[#self.lines + 1] = { ... } end
    return tooltip
end
local tooltip = Tooltip(); Suite.Tooltips:Item(tooltip, { hyperlink = "candidate" })
equal(tooltip.lines[1][2], 1, "nonpreferred upgrade explanation uses the yellow marker color")
equal(tooltip.lines[2][1], "Not your preferred armor type (Plate preferred).", "tooltip explains the yellow upgrade")
subtype = 4; tooltip = Tooltip(); Suite.Tooltips:Item(tooltip, { hyperlink = "candidate" })
equal(tooltip.lines[1][2], 0.2, "preferred upgrade explanation is green")
equal(tooltip.lines[2][1], "Preferred armor type: Plate", "tooltip explains the preferred match")
Suite.db.upgradePreference = "ilevel"; subtype = 3
Marker(false, "item-level mode nonpreferred upgrade")
equipped, noStats = nil, true
Marker(false, "nonpreferred armor filling an empty slot")
subtype = 4; Marker(true, "preferred armor filling an empty slot")
noStats, equipped = false, "old"
-- Accessory/cloak/shield/weapon colors do not depend on primary armor metadata.
for _, slot in ipairs({ "INVTYPE_CLOAK", "INVTYPE_FINGER", "INVTYPE_NECK", "INVTYPE_TRINKET",
    "INVTYPE_WEAPON", "INVTYPE_SHIELD", "INVTYPE_HOLDABLE", "INVTYPE_RELIC" }) do
    local red, green = Suite.Items:UpgradeColor({ equipLoc = slot })
    equal(red, 0.2, slot .. " retains a green upgrade color")
    equal(green, 1, slot .. " is not penalized as nonpreferred armor")
end
-- Unknown data must not be interpreted as a confirmed match or mismatch.
local function Hidden() return setmetatable({ secret = true }, { __index = function() error("hidden armor metadata indexed") end }) end
local function Missing(label)
    Suite.Items:Update(button, record)
    equal(record.arrow.text, "", label .. " waits rather than guessing an armor color")
end
for _, invalid in ipairs({ Hidden(), -1, 0, 5, 2.5, math.huge }) do subtype = invalid; Missing("invalid armor subclass") end
subtype = nil; Missing("missing armor subclass")
subtype, itemClass = 4, Hidden(); Missing("restricted item class")
itemClass = 4; class = Hidden(); Missing("restricted player class")
class = "UNKNOWN"; Missing("unknown player class")
UnitClass = function() error("class read rejected") end; Missing("rejected player class")
UnitClass = nil; Missing("unavailable player class")
UnitClass = function() return "Warrior", "WARRIOR" end
C_Item.GetItemSubClassInfo = function() return Hidden() end; Marker(true, "restricted optional armor label falls back safely")
C_Item.GetItemSubClassInfo = function() error("label read rejected") end; Marker(true, "rejected optional armor label falls back safely")
usable = false; Missing("ineligible armor")
usable, required = true, 70; Missing("above-level armor")
required = 1; Suite.db.upgradeHints = false; Missing("disabled upgrade hints")
Suite.db.upgradeHints = true
setCombat(true); subtype = 3
Marker(false, "existing marker recolors safely during combat")
setCombat(false)
-- Refresh preference at level/proficiency changes using the existing coalesced worker.
local events = Suite.Items.events
local registered, oldRegister, oldUnregister = {}, events.RegisterEvent, events.UnregisterAllEvents
events.RegisterEvent = function(_, event) registered[event] = true end
events.UnregisterAllEvents = function() registered = {} end
local timers = {}
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
Suite.Items:Apply()
equal(registered.PLAYER_LEVEL_UP, true, "level-40 armor transition is subscribed")
equal(registered.SPELLS_CHANGED, true, "learned armor proficiency can refresh eligibility")
equal(registered.SKILL_LINES_CHANGED, true, "armor skill changes can refresh eligibility")
Suite.Items.buttons[button] = record; button:Show()
level, subtype = 39, 3; Marker(true, "mail before the native level event")
events.OnEvent(events, "PLAYER_LEVEL_UP", 40)
events.OnEvent(events, "SPELLS_CHANGED")
equal(#timers, 1, "level and proficiency changes share one existing timer")
level = 40; timers[1].callback()
equal(record.arrow.textColor[1], 1, "deferred level refresh uses the new actual player level")
Suite.Items.buttons[button] = nil
Suite.db.upgradeHints, Suite.db.itemLevels = false, true
Suite.Items:Apply()
equal(registered.PLAYER_LEVEL_UP, nil, "item levels alone do not subscribe to armor preference updates")
events.RegisterEvent, events.UnregisterAllEvents = oldRegister, oldUnregister
Suite.Items.refreshTimer = nil
C_Item, C_PlayerInfo, UnitClass, UnitLevel, GetInventoryItemLink = saved.api, saved.playerInfo, saved.class, saved.level, saved.inventory
C_Timer, CreateFrame, Suite.db = saved.timer, saved.create, saved.db
Suite.Items:Apply()
