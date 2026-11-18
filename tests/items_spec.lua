-- Item-level display must remain safe with partial/restricted metadata.
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
C_Item.GetDetailedItemLevelInfo = function() return Hidden() end
equal(Suite.Items:GetInfo("item:1"), nil, "restricted item level never enters tooltip arithmetic")
C_Item.GetDetailedItemLevelInfo = function() return nil end
C_Item.GetItemInfo = function() return "Item", "item:1", 2, nil, 1, "Armor", "Cloth", 1, "INVTYPE_HEAD" end
equal(Suite.Items:GetInfo("item:1"), nil, "incomplete item level waits for metadata")
C_Item, UnitLevel, GetInventoryItemLink = oldAPI, oldLevel, oldLink
C_PlayerInfo=oldPlayerInfo

-- Global enumeration includes native aura buttons whose visibility is secret.
do
    local items = Suite.Items
    local saved = { enum = EnumerateFrames, combined = ContainerFrameCombinedBags, containers = ContainerFrameContainer,
        bank = BankFrame, panel = BankPanel, track = items.Track, update = items.Update, buttons = items.buttons,
        levels = Suite.db.itemLevels }
    Suite.db.itemLevels = true
    ContainerFrameCombinedBags, ContainerFrameContainer, BankFrame, BankPanel = nil, nil, nil, nil
    local tracked, updated, visibilityReads = {}, {}, 0
    local function Item(visible, forbidden)
        return { SetItemButtonQuality = function() end, GetItemLink = function() return nil end,
            IsForbidden = function() return forbidden end, IsVisible = function() visibilityReads = visibilityReads + 1; return visible end }
    end
    local aura = { IsForbidden = function() return false end,
        IsVisible = function() error("item scan must not query a native non-item aura's secret visibility") end }
    local good, hidden, forbidden = Item(true, false), Item(Hidden(), false), Item(true, Hidden())
    local denied = Item(true, false); denied.IsForbidden = function() error("restricted predicate") end
    local rejected = Item(true, false); rejected.IsVisible = function() error("restricted visibility") end
    local frames = { aura, good, hidden, forbidden, denied, rejected }
    EnumerateFrames = function(previous)
        if not previous then return frames[1] end
        for index, frame in ipairs(frames) do if previous == frame then return frames[index + 1] end end
    end
    items.Track = function(_, button) tracked[button] = true end
    items:ScanVisible()
    equal(tracked[good], true, "visible ordinary item remains discoverable after native aura widgets")
    for _, button in ipairs({ aura, hidden, forbidden, denied, rejected }) do
        equal(tracked[button], nil, "native or unreadable frames cannot become discovered item buttons")
    end
    equal(visibilityReads, 2, "only item candidates with readable access reach visibility queries")
    items.buttons = { [good] = {}, [hidden] = {}, [forbidden] = {}, [rejected] = {} }
    items.Update = function(_, button) updated[button] = true end
    items:Refresh()
    equal(updated[good], true, "refresh retains normal item behavior")
    equal(updated[hidden], nil, "tracked secret visibility is not treated as shown")
    equal(updated[forbidden], nil, "tracked unknown access remains untouched")
    equal(updated[rejected], nil, "visibility rejection cannot abort a refresh")
    items.Track, items.Update, items.buttons = saved.track, saved.update, saved.buttons
    -- Hook-driven entry points also need the same access guard.
    local direct = Item(true, Hidden())
    direct.CreateFontString = function() error("unreadable access must prevent region creation") end
    items:Track(direct)
    equal(items.buttons[direct], nil, "direct tracking rejects an unreadable forbidden predicate")
    EnumerateFrames, ContainerFrameCombinedBags, ContainerFrameContainer = saved.enum, saved.combined, saved.containers
    BankFrame, BankPanel = saved.bank, saved.panel
    Suite.db.itemLevels = saved.levels
end
