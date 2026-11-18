local Suite, equal, Frame, Combat = ...
local oldDB, oldItem, oldStats = Suite.db, C_Item, Suite.Items.buttons
Combat(false)
equal(Suite.Scoring, nil, "scoring engine is no longer loaded")
equal(Suite.GearStats, nil, "comparison stat extraction is no longer loaded")
equal(Suite.GearSettings, nil, "weight/profile editor is no longer loaded")
equal(Suite.Items.UpgradeDelta, nil, "item comparison entry point is removed")
equal(Suite.Tooltips.ComparisonDetails, nil, "comparison tooltip renderer is removed")
Suite.db = Suite.InitializeDB({ upgradeHints = true, scorePreset = "caster", upgradePreference = "stats" })
equal(Suite.db.upgradeHints, nil, "previous enabled upgrade setting is retired")
equal(Suite.db.scorePreset, nil, "legacy score profile is retired")
equal(Suite.db.upgradePreference, nil, "legacy comparison preference is retired")
-- Even a stale in-memory key cannot invoke the removed feature.
Suite.db.upgradeHints = true
C_Item = {
    GetItemInfo = function() return "Test gear", "item:100", 2, 20, 1, "Armor", "Cloth", 1, "INVTYPE_HEAD" end,
    GetDetailedItemLevelInfo = function() return 20 end,
    GetItemStats = function() error("removed comparison must never read stats") end,
}
local tooltip = Frame(); tooltip.GetItem, tooltip.GetUnit = nil, nil
tooltip.IsForbidden = function() return false end
Suite.Tooltips:Item(tooltip, { id = 100 })
equal(#tooltip.lines, 0, "stale upgrade flag adds no tooltip information")
Suite.db.itemTooltipLevels = true
Suite.Tooltips:Item(tooltip, { id = 100 })
equal(#tooltip.lines, 1, "item-level annotation remains without comparison prose")
equal(tooltip.lines[1][1], "Item Level 20", "retained level annotation has its original value")
Suite.Tooltips:Item(tooltip, { id = 100 })
equal(#tooltip.lines, 1, "item-level bookkeeping still prevents duplicate tooltip lines")
Suite.db.itemLevels = true
local button, record = Frame(), { item = "item:100" }
button.IsForbidden = function() return false end; button:Show()
button.GetItemLink = function() return "item:100" end
Suite.Items:Update(button, record)
equal(record.level.text, 20, "equipment icon still displays its item level")
equal(record.arrow, nil, "no upgrade marker is created even with a stale enabled flag")
for _, data in ipairs(Suite.SettingsCatalog.pages.items.rows) do
    equal(data.key == "upgradeHints" or data.action == "preset" or data.action == "weights" or data.action == "upgradePreference", false,
        "item settings contain only retained tools")
end
for _, feature in ipairs(Suite.Diagnostics.features) do equal(feature.key == "upgradeHints", false, "support no longer advertises gear advice") end
Suite.db, C_Item, Suite.Items.buttons = oldDB, oldItem, oldStats
Combat(false)
