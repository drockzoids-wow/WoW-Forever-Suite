local Suite, equal, Frame, SetCombat = ...
local alert = Suite.BagSpace
local names = { "CreateFrame", "C_Timer", "C_Container", "C_Item", "C_Cursor", "ItemLocation", "GetCursorInfo", "ClearCursor",
    "DeleteCursorItem", "StaticPopup_Show", "StaticPopup_IsAnyDialogShown", "StaticPopup_Hide", "GameTooltip", "UIParent",
    "NUM_TOTAL_EQUIPPED_BAG_SLOTS", "NUM_BAG_SLOTS" }
local old, oldModule = {}, {}
for _, name in ipairs(names) do old[name] = _G[name] end
for key, value in pairs(alert) do oldModule[key] = value end
local oldDB, oldPending, oldPrint = Suite.db, Suite.pending, Suite.Print
local timers, bags, metadata, requests, messages = {}, {}, {}, {}, {}
local cursor, popup, otherPopup, reject, wrongPickup, pickupError, noPopup
local pickups, confirmations, deletions, clears, hidden = 0, 0, 0, 0, 0
local blockedCalls, accepting = 0, false
local constructed = 0
local function Secret() return { secret = true } end
local function Fire(event, ...)
    if alert.events and alert.events.registered[event] then alert.events.OnEvent(alert.events, event, ...) end
end
local function Drain()
    local queued = timers; timers = {}
    for _, timer in ipairs(queued) do if not timer.cancelled then timer.callback() end end
end
local function TimerCount()
    local count = 0
    for _, timer in ipairs(timers) do if not timer.cancelled then count = count + 1 end end
    return count
end
CreateFrame = function(kind, name, parent, template)
    assert(not InCombatLockdown(), "bag-space frames are constructed outside combat")
    assert(name == nil, "bag-space frames are anonymous")
    constructed = constructed + 1
    local frame = old.CreateFrame(kind, name, parent, template)
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    local effectiveScale = frame.GetEffectiveScale
    frame.GetEffectiveScale = function(self)
        if issecretvalue(self.scale) then return self.scale end
        return effectiveScale(self)
    end
    for _, method in ipairs({ "StartMoving", "StopMovingOrSizing", "SetPoint", "ClearAllPoints" }) do
        local native = frame[method]
        frame[method] = function(self, ...)
            assert(not InCombatLockdown(), "bag-space movement and anchors must wait outside combat")
            return native(self, ...)
        end
    end
    return frame
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
UIParent = Frame()
UIParent:SetSize(1000, 800)
NUM_TOTAL_EQUIPPED_BAG_SLOTS, NUM_BAG_SLOTS = 5, 4
ItemLocation = { CreateFromBagAndSlot = function(_, bag, slot) return { bag = bag, slot = slot } end }
GetCursorInfo = function() return cursor and cursor.kind end
C_Cursor = { GetCursorItem = function() return cursor and cursor.kind == "item" and { cursor = true } or nil end }
ClearCursor = function()
    clears = clears + 1
    if cursor and cursor.item and cursor.bag and not bags[cursor.bag][cursor.slot] then bags[cursor.bag][cursor.slot] = cursor.item end
    cursor = nil; Fire("CURSOR_CHANGED")
end
StaticPopup_IsAnyDialogShown = function() return otherPopup or (popup and popup:IsShown()) or false end
StaticPopup_Hide = function(which, data)
    equal(which, "DELETE_ITEM", "only a deletion dialog can be dismissed")
    if popup and popup.data == data then popup:Hide(); hidden = hidden + 1 end
end
DeleteCursorItem = function()
    assert(accepting and not InCombatLockdown() and cursor and cursor.item,
        "cursor deletion requires the user's explicit native confirmation click")
    deletions = deletions + 1; cursor = nil; Fire("CURSOR_CHANGED"); Fire("BAG_UPDATE_DELAYED")
end
StaticPopup_Show = function(which, link, _, data)
    equal(which, "DELETE_ITEM", "gray/white items use the native cursor deletion dialog")
    assert(not InCombatLockdown() and cursor and cursor.item, "native cursor confirmation keeps the item held")
    confirmations = confirmations + 1
    if reject then error("native confirmation rejected") end
    if noPopup then return end
    local offeredGUID = cursor.guid
    popup = Frame(); popup.data, popup.link = data, link; popup:Show()
    popup.accept = function()
        -- Matches Blizzard's native DELETE_ITEM OnAccept; never called by the addon.
        equal(cursor.guid, offeredGUID, "native acceptance deletes the exact offered instance")
        accepting = true
        if popup.data and popup.data.itemGUID then C_Item.DeleteItem(popup.data.itemGUID)
        else DeleteCursorItem() end
        accepting = false
        popup:Hide()
    end
    popup.cancel = function() popup:Hide(); ClearCursor() end
    return popup
end
C_Container = {
    GetContainerNumSlots = function(bag)
        assert(bag >= 0 and bag <= 5, "only equipped carried bags are scanned")
        return bags[bag] and bags[bag].slots or 0
    end,
    GetContainerNumFreeSlots = function(bag) return bags[bag].free, bags[bag].family end,
    GetContainerItemInfo = function(bag, slot) return bags[bag][slot] end,
    GetContainerItemID = function(bag, slot)
        local item = bags[bag][slot]
        return item and item.itemID or bags[bag].unavailableID
    end,
    GetContainerItemQuestInfo = function(bag, slot) return bags[bag][slot].quest end,
    PickupContainerItem = function(bag, slot)
        assert(not InCombatLockdown() and cursor == nil, "pickup requires explicit outside-combat input and an empty cursor")
        pickups = pickups + 1
        if pickupError then error("native pickup rejected") end
        if wrongPickup then cursor = { kind = "item", guid = "different" }; Fire("CURSOR_CHANGED"); return end
        local item = bags[bag][slot]
        cursor = { kind = "item", item = item, guid = item.guid, bag = bag, slot = slot }
        bags[bag][slot] = nil
        Fire("CURSOR_CHANGED")
    end,
}
C_Item = {
    GetItemInfo = function(link)
        local value = metadata[link]
        if not value or value.loading then return nil end
        return value.name, link, value.quality, 1, 1, "Misc", "Other", 20, "", value.icon or 134400, value.price, value.class
    end,
    GetItemGUID = function(location)
        if location.cursor then return cursor and cursor.guid end
        return bags[location.bag][location.slot] and bags[location.bag][location.slot].guid
    end,
    RequestLoadItemDataByID = function(id) requests[id] = (requests[id] or 0) + 1 end,
    ConfirmDeleteItem = function()
        blockedCalls = blockedCalls + 1
        error("ADDON_ACTION_BLOCKED: GUID confirmation is protected")
    end,
    DeleteItem = function()
        blockedCalls = blockedCalls + 1
        error("ADDON_ACTION_BLOCKED: GUID deletion is protected")
    end,
}
GameTooltip = Frame()
GameTooltip.SetOwner = function(self, owner) self.owner = owner end
GameTooltip.GetOwner = function(self) return self.owner end
GameTooltip.SetHyperlink = function(self, link) self.link = link; self.lines = {} end
GameTooltip.ClearLines = function(self) self.link = nil; self.lines = {} end
Suite.Print = function(message) messages[#messages + 1] = message end
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
local function Item(id, price, count, quality)
    local link = "|Hitem:" .. id .. ":0|h[Item " .. id .. "]|h"
    metadata[link] = { name = "Item " .. id, price = price, quality = quality or 0, class = 15 }
    return { itemID = id, stackCount = count or 1, quality = quality or 0, isLocked = false, hasNoValue = false,
        hyperlink = link, guid = "Item-GUID-" .. id, quest = { isQuestItem = false, isActive = false } }
end
local function Fixture(free)
    alert:CancelWork(); alert:CancelDelete()
    cursor, popup, otherPopup, reject, wrongPickup, pickupError, noPopup = nil, nil, false, false, false, false, false
    bags = { [0] = { slots = 4, free = free or 2, family = 0 }, [1] = { slots = 1, free = 0, family = 0 },
        [5] = { slots = 1, free = 40, family = 32 } }
    -- Actual free counts must fit the bag, even when its capacity is specialized.
    bags[5].slots = 40
    bags[0][1], bags[0][2], bags[0][3] = Item(10, 1, 20), Item(11, 7, 1, 1), Item(12, 1, 1, 2)
    bags[1][1] = Item(13, 7)
    alert.requests = {}; requests = {}; Suite.db.bagSpaceBlacklist = {}
end
Fixture()
equal(Suite.db.bagSpaceAlert, false, "bag-space alert starts independently off")
alert:Apply(); equal(constructed, 0, "disabled alert creates no frames")
equal(TimerCount(), 0, "disabled alert schedules no work")
local clean = alert:InitializeBlacklist({ [10] = true, [11] = false, [12] = Secret(), [-1] = true, text = true })
equal(clean[10], true, "saved item-ID blacklist persists")
equal(clean[11], nil, "false blacklist entries are removed")
equal(clean[12], nil, "restricted blacklist values are never persisted")
equal(clean[-1], nil, "invalid blacklist IDs are removed")
equal(next(alert:InitializeBlacklist(Secret())), nil, "a restricted blacklist becomes an empty safe table")
local restored = Suite.InitializeDB({ bagSpaceAlert = true, bagSpaceBlacklist = { [10] = true } })
equal(restored.bagSpaceAlert, true, "alert toggle survives database initialization")
equal(restored.bagSpaceBlacklist[10], true, "blacklist survives database initialization")
equal(Suite.InitializeDB({ bagSpaceAlert = Secret() }).bagSpaceAlert, false, "restricted toggle stays off")
local savedPlacement = Suite.InitializeDB({ bagSpacePosition = { x = 0.25, y = -0.25 } })
equal(savedPlacement.bagSpacePosition.x, 0.25, "horizontal alert position survives database initialization")
equal(savedPlacement.bagSpacePosition.y, -0.25, "vertical alert position survives database initialization")
for _, invalid in ipairs({ Secret(), { x = Secret(), y = 0 }, { x = 0, y = Secret() },
    { x = 0 / 0, y = 0 }, { x = math.huge, y = 0 }, { x = 0.6, y = 0 }, { x = 0 } }) do
    equal(next(alert:InitializePosition(invalid)), nil, "invalid or restricted placement safely uses the default")
end
SetCombat(true); Suite.db.bagSpaceAlert = true; alert:Apply()
equal(constructed, 0, "enabling during combat defers construction")
equal(type(Suite.pending.bagSpace), "function", "combat enabling records only deferred apply work")
SetCombat(false); Suite.pending.bagSpace(); Drain()
equal(alert.candidate.id, 11, "total stack price outranks cheaper individual units")
equal(alert.candidate.value, 7, "candidate price uses the full stack")
equal(alert.button:IsShown(), true, "two free general slots show a central button despite specialty capacity")
equal(alert.button.point[1], "CENTER", "alert is centered on screen")
equal(alert.button.OnUpdate, nil, "alert has no idle per-frame scanner")
equal(pickups, 0, "appearance performs no pickup")
equal(confirmations, 0, "appearance requests no confirmation")
equal(deletions, 0, "appearance never deletes")
for _, free in ipairs({ 0, 1, 2, 3 }) do
    bags[0].free = free; Fire("BAG_UPDATE_DELAYED"); Drain()
    equal(alert.button:IsShown(), free <= 2, "alert follows the exact two-slot threshold")
end
bags[0].free = 2
for index = 1, 20 do Fire("BAG_UPDATE_DELAYED"); Fire("ITEM_LOCK_CHANGED") end
equal(TimerCount(), 1, "bag and lock events share one coalesced worker")
Drain(); equal(TimerCount(), 0, "refresh leaves no polling timer")

Fixture(); bags[0].unavailableID = 14
Fire("BAG_UPDATE_DELAYED"); Drain()
equal(alert.candidate, nil, "occupied slots without records cannot establish a cheapest stack")
equal(alert.status, "unavailable", "missing occupied records disclose unavailable values")
local beforeUnavailablePickup = pickups
alert:Click("LeftButton")
equal(pickups, beforeUnavailablePickup, "missing occupied records cannot authorize item pickup")
equal(TimerCount(), 0, "missing occupied records do not add polling")
bags[0].unavailableID = Secret(); Fire("BAG_UPDATE_DELAYED"); Drain()
equal(alert.candidate, nil, "restricted occupancy is never inferred to mean empty")
local occupancy = C_Container.GetContainerItemID
C_Container.GetContainerItemID = nil; Fire("BAG_UPDATE_DELAYED"); Drain()
equal(alert.candidate, nil, "unavailable occupancy capability cannot establish a minimum")
C_Container.GetContainerItemID = occupancy
bags[0].unavailableID, bags[0][4] = nil, Item(14, 1)
Fire("ITEM_DATA_LOAD_RESULT", 14, true); Fire("BAG_UPDATE_DELAYED"); Drain()
equal(alert.candidate.id, 14, "completed slot records participate in the fresh minimum")
bags[0][4] = nil; Fire("BAG_UPDATE_DELAYED"); Drain()
equal(alert.candidate.id, 11, "readably empty slots still permit a complete minimum")

alert.button.OnEnter(); equal(GameTooltip.link, alert.candidate.link, "hover shows the offered instance link")
alert.button.OnLeave(); equal(GameTooltip:IsShown(), false, "leave cleans up the alert-owned tooltip")
GameTooltip.owner = Frame(); GameTooltip:Show(); alert:HideTooltip()
equal(GameTooltip:IsShown(), true, "cleanup preserves another tooltip owner")
alert:Click("RightButton")
equal(Suite.db.bagSpaceBlacklist[11], true, "right click persistently protects an item type")
equal(confirmations, 0, "blacklisting requests no deletion")
Drain(); equal(alert.candidate.id, 13, "blacklisting immediately offers the next cheapest type")
bags[0][4] = Item(11, 1, 1, 1); Fire("BAG_UPDATE_DELAYED"); Drain()
equal(alert.candidate.id, 13, "blacklisting excludes all stacks of the same item ID")
alert:ResetBlacklist(); Drain(); equal(alert.candidate.id, 11, "settings reset restores blacklisted suggestions")
equal(Suite.db.autoSellJunk, false, "trash blacklist does not enable vendor tools")

Fixture(); bags[0][2].isLocked = true; bags[1][1].hasNoValue = true
Fire("BAG_UPDATE_DELAYED"); Drain(); equal(alert.candidate.id, 10, "locked and no-sale-value items are excluded")
bags[0][2].isLocked = false; metadata[bags[0][2].hyperlink].price = 0
Fire("BAG_UPDATE_DELAYED"); Drain(); equal(alert.candidate.id, 10, "zero vendor price is protected even without a no-value flag")
bags[0][1].quest.isQuestItem = true; Fire("BAG_UPDATE_DELAYED"); Drain()
equal(alert.candidate, nil, "quest items are protected")
equal(alert.button:IsShown(), true, "low space stays visible without a deletable item")
bags[0][1].quest.isQuestItem = false; bags[0][1].quest.questID = 123
Fire("BAG_UPDATE_DELAYED"); Drain(); equal(alert.candidate, nil, "inactive quest starters are protected")
bags[0][1].quest.questID = nil; metadata[bags[0][1].hyperlink].class = 12
Fire("BAG_UPDATE_DELAYED"); Drain(); equal(alert.candidate, nil, "quest item class is protected independently")

Fixture(); metadata[bags[0][1].hyperlink].loading = true; bags[0][1].quality = nil
Fire("BAG_UPDATE_DELAYED"); Drain()
equal(alert.candidate, nil, "unknown metadata cannot produce a falsely cheapest offer")
equal(requests[10], 1, "uncached quality requests item data once")
Fire("BAG_UPDATE_DELAYED"); Drain(); equal(requests[10], 1, "unresolved data never polls or repeats its request")
equal(TimerCount(), 0, "unknown values leave no polling worker")
metadata[bags[0][1].hyperlink].loading = false; metadata[bags[0][1].hyperlink].price = 1; bags[0][1].stackCount = 1
Fire("ITEM_DATA_LOAD_RESULT", 10, true); Drain()
equal(alert.candidate.id, 10, "successful async data refreshes the true minimum")
equal(alert.candidate.quality, 0, "nil container quality uses readable loaded item quality")
Fixture(); metadata[bags[0][1].hyperlink].loading = true; Fire("BAG_UPDATE_DELAYED"); Drain()
Fire("ITEM_DATA_LOAD_RESULT", 10, false); Drain()
alert.button.OnEnter()
equal(GameTooltip.lines[4][1], "Item values unavailable", "failed loads disclose unavailable values in the tooltip")
equal(requests[10], 1, "failed loads do not auto-retry")
Fire("ITEM_DATA_LOAD_RESULT", Secret(), true); equal(TimerCount(), 0, "secret item-data IDs cannot schedule work")
Fixture(); local requestAPI = C_Item.RequestLoadItemDataByID; C_Item.RequestLoadItemDataByID = nil
metadata[bags[0][1].hyperlink].loading = true; Fire("BAG_UPDATE_DELAYED"); Drain()
alert.button.OnEnter()
equal(GameTooltip.lines[4][1], "Item values unavailable", "missing load API never claims active loading in the tooltip")
C_Item.RequestLoadItemDataByID = requestAPI

Fixture(); bags[0].slots = 80; bags[0][1] = nil; bags[0][2] = nil; bags[0][3] = nil
for slot = 1, 70 do bags[0][slot] = Item(100 + slot, 1); metadata[bags[0][slot].hyperlink].loading = true end
Fire("BAG_UPDATE_DELAYED"); Drain()
local sent = 0; for _ in pairs(requests) do sent = sent + 1 end
equal(sent, 32, "item-data requests are bounded to 32 per worker")
equal(TimerCount(), 0, "large async queues never self-poll")
Fire("ITEM_DATA_LOAD_RESULT", 101, true); Drain()
sent = 0; for _ in pairs(requests) do sent = sent + 1 end
equal(sent, 64, "load events continue finite request batches")

for _, field in ipairs({ "itemID", "stackCount", "quality", "isLocked", "hasNoValue", "hyperlink", "guid" }) do
    Fixture(); bags[0][1][field] = Secret(); Fire("BAG_UPDATE_DELAYED"); Drain()
    equal(alert.candidate, nil, "restricted slot " .. field .. " blocks an uncertain minimum")
    local before = pickups; alert:Click("LeftButton"); equal(pickups, before, "restricted slot cannot be picked up")
end
for _, field in ipairs({ "name", "price", "quality", "class" }) do
    Fixture(); metadata[bags[0][1].hyperlink][field] = Secret(); Fire("BAG_UPDATE_DELAYED"); Drain()
    equal(alert.candidate, nil, "restricted metadata " .. field .. " is not compared or formatted")
    equal(requests[10], nil, "restricted metadata is not a reason to try recovering item data")
end
for _, field in ipairs({ "isQuestItem", "questID", "isActive" }) do
    Fixture(); bags[0][1].quest[field] = Secret(); Fire("BAG_UPDATE_DELAYED"); Drain()
    equal(alert.candidate, nil, "restricted quest " .. field .. " cannot become an eligible item")
end
for _, field in ipairs({ "slots", "free", "family" }) do
    Fixture(); bags[0][field] = Secret(); Fire("BAG_UPDATE_DELAYED"); Drain()
    equal(alert.button:IsShown(), false, "restricted capacity " .. field .. " cannot assert low bag space")
end
Fixture(); Suite.db.bagSpaceBlacklist[10] = Secret(); Fire("BAG_UPDATE_DELAYED"); Drain()
equal(alert.candidate, nil, "restricted blacklist choices are never used as booleans")
Fixture(); Fire("BAG_UPDATE_DELAYED"); Drain()
local beforePickups = pickups
for _, kind in ipairs({ "item", "spell", "macro", "money" }) do
    cursor = { kind = kind }; alert:Click("LeftButton")
    equal(pickups, beforePickups, "existing " .. kind .. " cursor payload blocks deletion")
end
cursor = { kind = Secret() }; alert:Click("LeftButton")
equal(pickups, beforePickups, "restricted cursor payload blocks deletion")
cursor = nil
for _, change in ipairs({ "guid", "count", "value", "cheaper", "free" }) do
    Fixture(); Fire("BAG_UPDATE_DELAYED"); Drain()
    if change == "guid" then bags[0][2].guid = "replacement-instance"
    elseif change == "count" then bags[0][2].stackCount = 2
    elseif change == "value" then metadata[bags[0][2].hyperlink].price = 8
    elseif change == "cheaper" then bags[0][1].stackCount = 1
    else bags[0].free = 3 end
    local before = pickups; alert:Click("LeftButton")
    equal(pickups, before, "changed " .. change .. " cancels the stale offer before pickup")
end
Fixture(); Fire("BAG_UPDATE_DELAYED"); Drain(); otherPopup = true
local offeredLink = alert.candidate.link
local before = pickups; alert:Click("LeftButton")
equal(pickups, before, "another native dialog is preserved")
otherPopup = false; alert:Click("LeftButton")
equal(popup ~= nil, true, "left click opens confirmation while GUID deletion APIs reject addon calls")
equal(cursor.guid, "Item-GUID-11", "left click holds the exact lowest-value stack for confirmation")
equal(popup.link, offeredLink, "native confirmation names the offered item")
equal(popup.data.itemGUID, nil, "native acceptance uses cursor deletion instead of the protected GUID API")
equal(popup.data, alert.popupData, "confirmation cleanup owns an exact unique data table")
equal(deletions, 0, "requesting native confirmation does not delete anything")
equal(alert.button:IsShown(), false, "alert hides while its item is on the cursor")
popup.cancel(); Drain()
equal(bags[0][2].itemID, 11, "native cancel returns the offered stack to bags")
equal(deletions, 0, "native cancel performs no deletion")
alert:Click("LeftButton"); popup.accept(); Drain()
equal(deletions, 1, "only the user's native acceptance deletes the offered stack")
equal(blockedCalls, 0, "confirmation and acceptance never call protected GUID item APIs")
equal(alert.candidate.id, 13, "bag acknowledgement offers the next eligible item")

local protectedConfirm, protectedDelete = C_Item.ConfirmDeleteItem, C_Item.DeleteItem
C_Item.ConfirmDeleteItem, C_Item.DeleteItem = nil, nil
Fixture(); Fire("BAG_UPDATE_DELAYED"); Drain(); alert:Click("LeftButton")
equal(popup:IsShown(), true, "cursor confirmation works without the protected GUID capabilities")
popup.cancel(); Drain()
C_Item.ConfirmDeleteItem, C_Item.DeleteItem = protectedConfirm, protectedDelete

for _, failure in ipairs({ "reject", "noPopup", "pickupError", "wrongPickup" }) do
    Fixture(); Fire("BAG_UPDATE_DELAYED"); Drain()
    reject, noPopup, pickupError, wrongPickup = failure == "reject", failure == "noPopup", failure == "pickupError", failure == "wrongPickup"
    local deletesBefore, clearsBefore = deletions, clears
    alert:Click("LeftButton")
    equal(deletions, deletesBefore, "native " .. failure .. " failure never deletes")
    if failure == "wrongPickup" then
        equal(clears, clearsBefore, "mismatched cursor item is never cleared")
        equal(cursor.guid, "different", "unrelated cursor item stays under user control")
    else equal(bags[0][2].itemID, 11, "failed native request retains its original item") end
end
Fixture(); Fire("BAG_UPDATE_DELAYED"); Drain(); alert:Click("LeftButton")
local hiddenBefore = hidden
cursor = { kind = "item", guid = "user-replacement" }; Fire("CURSOR_CHANGED")
equal(hidden, hiddenBefore + 1, "changing cursor ownership dismisses only the Suite's native confirmation")
equal(cursor.guid, "user-replacement", "confirmation cleanup keeps a replacement item on the cursor")
Fixture(); Fire("BAG_UPDATE_DELAYED"); Drain(); alert:Click("LeftButton")
SetCombat(true); Fire("PLAYER_REGEN_DISABLED")
equal(popup:IsShown(), false, "combat entry dismisses the owned native confirmation")
equal(bags[0][2].itemID, 11, "combat entry returns the offered item")
equal(TimerCount(), 0, "combat cancels queued work")
local constructionBefore = constructed; alert:Apply(); equal(constructed, constructionBefore, "combat reapply creates no frames")
Suite.db.bagSpaceAlert = false; alert:Apply()
equal(Suite.pending.bagSpace, nil, "disabling cancels deferred enablement")
SetCombat(false); Fire("PLAYER_REGEN_ENABLED"); Drain()
equal(alert.button:IsShown(), false, "disabled alert cannot reappear after combat")
equal(next(alert.events.registered), nil, "disabled alert registers no feature events")
Suite.db.bagSpaceAlert = true; alert:Apply(); Drain()

-- Drag release is destructive if it accidentally dispatches either original click action.
Fixture(); Fire("BAG_UPDATE_DELAYED"); Drain()
local button = alert.button
local picksBeforeDrag, promptsBeforeDrag = pickups, confirmations
button.OnMouseDown(button, "LeftButton"); button.OnDragStart(button)
equal(button.moving, true, "native drag begins movement without preparing an item")
button.OnClick(button, "LeftButton")
equal(pickups, picksBeforeDrag, "click dispatched during a drag cannot pick up an item")
button.centerX, button.centerY = 750, 200
button.OnDragStop(button)
button.OnClick(button, "LeftButton"); button.OnClick(button, "RightButton")
equal(pickups, picksBeforeDrag, "drag release after stopping cannot pick up an item")
equal(confirmations, promptsBeforeDrag, "drag release cannot open deletion confirmation")
equal(Suite.db.bagSpaceBlacklist[11], nil, "drag release cannot blacklist the current offer")
equal(Suite.db.bagSpacePosition.x, 0.25, "completed movement saves normalized horizontal position")
equal(Suite.db.bagSpacePosition.y, -0.25, "completed movement saves normalized vertical position")
equal(button.point[4], 250, "movement restores a center-relative horizontal anchor")
equal(button.point[5], -200, "movement restores a center-relative vertical anchor")
alert:Hide(); Fire("BAG_UPDATE_DELAYED"); Drain()
equal(button.point[4], 250, "saved placement survives the alert hiding and reappearing")
button.OnMouseDown(button, "LeftButton"); button.OnClick(button, "LeftButton")
equal(confirmations, promptsBeforeDrag + 1, "a new real click still opens native confirmation after a drag")
popup.cancel(); Drain()
button.OnMouseDown(button, "RightButton"); button.OnClick(button, "RightButton"); Drain()
equal(Suite.db.bagSpaceBlacklist[11], true, "a new real right click still blacklists after a drag")
alert:ResetBlacklist(); Drain()

button.scale = 2; button.centerX, button.centerY = 375, 100
button.OnMouseDown(button, "LeftButton"); button.OnDragStart(button); button.OnDragStop(button)
equal(Suite.db.bagSpacePosition.x, 0.25, "effective-scale conversion preserves horizontal screen position")
equal(Suite.db.bagSpacePosition.y, -0.25, "effective-scale conversion preserves vertical screen position")
button.scale = 1
local completedPosition = Suite.db.bagSpacePosition
for _, field in ipairs({ "centerX", "centerY", "scale" }) do
    button.centerX, button.centerY, button.scale = 900, 700, 1
    button.OnMouseDown(button, "LeftButton"); button.OnDragStart(button)
    button[field] = Secret(); button.OnDragStop(button)
    equal(Suite.db.bagSpacePosition, completedPosition, "restricted drag " .. field .. " cannot overwrite saved placement")
end
button.centerX, button.centerY, button.scale = 750, 200, 1
cursor = { kind = "macro" }; button.OnMouseDown(button, "LeftButton"); button.OnDragStart(button)
equal(alert.moving, nil, "cursor-held payloads prevent starting a drag")
equal(cursor.kind, "macro", "refused drag preserves the existing cursor payload")
cursor = nil

UIParent:SetSize(1200, 1000); Fire("DISPLAY_SIZE_CHANGED"); Drain()
equal(button.point[4], 300, "display changes restore normalized horizontal placement")
equal(button.point[5], -250, "display changes restore normalized vertical placement")
button.OnMouseDown(button, "LeftButton"); button.OnDragStart(button)
button.centerX, button.centerY = 1100, 900
Fire("UI_SCALE_CHANGED"); Drain()
equal(button.moving, false, "layout changes stop unfinished movement outside combat")
equal(Suite.db.bagSpacePosition, completedPosition, "layout changes do not save unfinished gestures")
UIParent:SetSize(1000, 800); Fire("UI_SCALE_CHANGED"); Drain()

button.OnMouseDown(button, "LeftButton"); button.OnDragStart(button)
button.centerX, button.centerY = 950, 700
bags[0].free = 3; Fire("BAG_UPDATE_DELAYED"); Drain()
equal(button:IsShown(), false, "freeing bag space hides an alert during a drag")
equal(button.moving, false, "ordinary hide cancels native movement")
equal(Suite.db.bagSpacePosition, completedPosition, "ordinary hide keeps the last completed placement")
bags[0].free = 2; Fire("BAG_UPDATE_DELAYED"); Drain()
button.OnMouseDown(button, "LeftButton"); button.OnDragStart(button)
SetCombat(true); Fire("PLAYER_REGEN_DISABLED")
equal(button:IsShown(), false, "combat hides a dragged button immediately")
equal(type(Suite.pending.bagSpaceMove), "function", "combat movement rollback defers protected calls")
equal(Suite.db.bagSpacePosition, completedPosition, "combat cannot save an unfinished placement")
button.OnDragStop(button); button.OnClick(button, "LeftButton")
equal(confirmations, promptsBeforeDrag + 1, "combat drag release cannot discard the offer")
SetCombat(false); Fire("PLAYER_REGEN_ENABLED"); Drain()
equal(button.moving, false, "combat exit stops and restores canceled movement")
equal(button.point[4], 250, "combat rollback restores the last completed horizontal placement")
equal(button.point[5], -200, "combat rollback restores the last completed vertical placement")
equal(Suite.pending.bagSpaceMove, nil, "completed rollback clears its deferred callback")

button.OnMouseDown(button, "LeftButton"); button.OnDragStart(button)
SetCombat(true); Fire("PLAYER_REGEN_DISABLED")
Suite.db.bagSpaceAlert = false; alert:Apply()
SetCombat(false); Suite.pending.bagSpaceMove(); Drain()
equal(button:IsShown(), false, "disabled button remains hidden after deferred drag rollback")
equal(Suite.db.bagSpacePosition, completedPosition, "disabling during a drag retains the last completed placement")
equal(next(alert.events.registered), nil, "disabled drag rollback restores no feature events")
Suite.db.bagSpaceAlert = true; alert:Apply(); Drain()

Fire("BAG_UPDATE_DELAYED"); Fire("PLAYER_LOGOUT")
equal(TimerCount(), 0, "logout cancels pending work")
equal(alert.button:IsShown(), false, "logout hides the alert")
equal(blockedCalls, 0, "all click, cleanup and drag paths avoid protected GUID deletion APIs")
Suite.db.bagSpaceAlert = false; alert:Apply()

for key in pairs(alert) do alert[key] = nil end
for key, value in pairs(oldModule) do alert[key] = value end
for _, name in ipairs(names) do _G[name] = old[name] end
Suite.db, Suite.pending, Suite.Print = oldDB, oldPending, oldPrint
SetCombat(false)
