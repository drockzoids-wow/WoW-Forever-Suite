local Suite, equal = ...
local hidden = setmetatable({ secret = true }, {
    __index = function() error("restricted settings were indexed") end,
})
local db = Suite.InitializeDB(hidden)
equal(db.squareMinimap, false, "restricted saved root uses independent defaults")
equal(db.minimapButton, true, "restricted saved root preserves the visible launcher default")

db = Suite.InitializeDB({ inventory = hidden, windowPositions = hidden, macroOwnership = hidden, scorePreset = hidden })
equal(type(db.windowPositions), "table", "restricted window layouts reset before module access")
equal(type(db.macroOwnership), "table", "restricted macro ownership resets before module access")
equal(db.scorePreset, "balanced", "restricted stat preset cannot become a lookup key")
equal(db.inventory ~= Suite.defaults.inventory, true, "restored inventory defaults are independent tables")
db.inventory.characters.example = {}
equal(Suite.defaults.inventory.characters.example, nil, "restored tables cannot modify shared defaults")

-- A restricted scalar can retain the expected Lua type; type checks alone are insufficient.
local nativeSecret, nativeAccess = issecretvalue, canaccessvalue
issecretvalue = function(value) return value == "hidden-preset" or value == 91 or nativeSecret(value) end
canaccessvalue = function(value) return not issecretvalue(value) and nativeAccess(value) end
db = Suite.InitializeDB({ scorePreset = "hidden-preset", schema = 91, itemLevels = true, minimapButton = false })
equal(db.scorePreset, "balanced", "restricted string preferences reset before lookup")
equal(db.schema, 1, "restricted numbers reset despite having the expected type")
equal(db.itemLevels, true, "readable enabled preferences survive validation")
equal(db.minimapButton, false, "readable disabled launcher preferences survive validation")
issecretvalue, canaccessvalue = nativeSecret, nativeAccess
