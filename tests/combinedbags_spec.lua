local Suite, equal, Frame, SetCombat = ...
local feature = Suite.CombinedBags
local names = { "ContainerFrameCombinedBags", "AnchorUtil", "InputUtil", "CreateFrame", "hooksecurefunc" }
local saved = {}
for _, name in ipairs(names) do saved[name] = _G[name] end
local oldDB, oldPending, oldApply = Suite.db, Suite.pending, Suite.Apply
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
equal(Suite.db.reverseCombinedBags, false, "combined bag reversal starts independently off")
equal(Suite.db.reverseBagSlots, false, "within-bag slot reversal starts independently off")
equal(Suite.InitializeDB({ reverseBagSlots = true }).reverseBagSlots, true, "within-bag display choice persists")
equal(Suite.InitializeDB({ reverseCombinedBags = true }).reverseCombinedBags, true, "combined bag order is saved")
equal(Suite.InitializeDB({ reverseCombinedBags = { secret = true } }).reverseCombinedBags, false, "restricted bag preference is normalized")
local constructed, hooks, writes, native, gamepad = 0, 0, 0, false, false
CreateFrame = function(...)
    assert(not InCombatLockdown(), "combined bag event creation must wait through combat")
    constructed = constructed + 1
    local frame = saved.CreateFrame(...)
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    return frame
end
hooksecurefunc = function(...)
    assert(not InCombatLockdown(), "combined bag hooks must wait through combat")
    hooks = hooks + 1
    return saved.hooksecurefunc(...)
end
InputUtil = { IsGamepadUIEnabled = function() return gamepad end }
local function Security(frame)
    frame.protected, frame.anchorRestricted, frame.anchorSecret = false, false, false
    frame.IsProtected = function(self) return self.protected end
    frame.IsAnchoringRestricted = function(self) return self.anchorRestricted end
    frame.IsAnchoringSecret = function(self) return self.anchorSecret end
end
AnchorUtil = { GridLayout = function(buttons, anchor, layout)
    if not native then
        if InCombatLockdown() then
            for _, object in ipairs({ ContainerFrameCombinedBags, anchor.relativeTo }) do
                assert(object:IsProtected() == false and object:IsAnchoringRestricted() == false and object:IsAnchoringSecret() == false,
                    "combat grid requires a public unprotected native container and anchor")
            end
            for _, button in ipairs(buttons) do
                assert(button:IsProtected() == false and button:IsAnchoringRestricted() == false and button:IsAnchoringSecret() == false,
                    "combat writes require each current slot to be public and unprotected")
            end
        end
        writes = writes + 1
    end
    for index, button in ipairs(buttons) do
        local cell = index - 1
        button:ClearAllPoints()
        button:SetPoint(anchor.point, anchor.relativeTo, anchor.relativePoint,
            anchor.x - (cell % layout.stride) * (button:GetWidth() + layout.paddingX),
            anchor.y + math.floor(cell / layout.stride) * (button:GetHeight() + layout.paddingY))
    end
end }
local function MakeBag(shown)
    local frame = Frame()
    frame.shown, frame.Items, frame.nativeLayouts, frame.prompts = shown, {}, 0, 0
    frame.IsForbidden = function(self) return self.forbidden or false end
    frame.MoneyFrame = Frame(); frame.MoneyFrame.IsForbidden = function() return false end
    Security(frame); Security(frame.MoneyFrame)
    frame.layout = { direction = { x = -1, y = 1 }, stride = 5, paddingX = 5, paddingY = 5,
        GetCustomOffset = function() return 0, 0 end }
    frame.anchor = { point = "BOTTOMRIGHT", relativeTo = frame.MoneyFrame, relativePoint = "TOPRIGHT", x = 0, y = 4,
        SetPointWithExtraOffset = function() end }
    frame.GetInitialItemAnchor = function(self) return self.anchor end
    frame.GetAnchorLayout = function(self) return self.layout end
    frame.EnumerateValidItems = function(self) return ipairs(self.Items) end
    frame.LayoutAddSlots = function(self) self.prompts = self.prompts + 1 end
    for bag, size in ipairs({ 3, 2, 4, 4 }) do
        for slot = size, 1, -1 do
            local button = Frame()
            button.parent, button.bag, button.slot, button.extended = frame, bag - 1, slot, false
            button:SetSize(37, 37)
            button.IsForbidden = function(self) return self.forbidden or false end
            Security(button)
            button.GetBagID = function(self) return self.bag end
            button.GetID = function(self) return self.slot end
            button.IsExtended = function(self) return self.extended end
            button.SetID = function() error("reversing layout must never reassign a physical slot") end
            button.OnClick = function() end
            frame.Items[#frame.Items + 1] = button
        end
    end
    frame.UpdateItemLayout = function(self)
        self.nativeLayouts = self.nativeLayouts + 1
        local ordered = {}
        for index, button in ipairs(self.Items) do ordered[index] = button end
        table.sort(ordered, function(a, b)
            if a.extended ~= b.extended then return not a.extended end
            if a.bag ~= b.bag then return a.bag > b.bag end
            return a.slot > b.slot
        end)
        native = true; AnchorUtil.GridLayout(ordered, self.anchor, self.layout); native = false
        self:LayoutAddSlots()
    end
    return frame
end
local function Order(frame)
    local ordered, result = {}, {}
    for index, button in ipairs(frame.Items) do ordered[index] = button end
    table.sort(ordered, function(a, b)
        if a.point[5] ~= b.point[5] then return a.point[5] > b.point[5] end
        return a.point[4] < b.point[4]
    end)
    for index, button in ipairs(ordered) do result[index] = button.bag .. ":" .. button.slot end
    return table.concat(result, ",")
end
local function Drain()
    local pending = Suite.pending; Suite.pending = {}
    for _, callback in pairs(pending) do callback() end
end
local frame = MakeBag(true)
ContainerFrameCombinedBags = frame
frame:UpdateItemLayout()
local original = Order(frame)
local reversed = "3:1,3:2,3:3,3:4,2:1,2:2,2:3,2:4,1:1,1:2,0:1,0:2,0:3"
equal(original, "0:1,0:2,0:3,1:1,1:2,2:1,2:2,2:3,2:4,3:1,3:2,3:3,3:4", "native fixture puts backpack first")
feature:Apply(); equal(constructed, 0, "disabled reversal creates no event frame")
equal(hooks, 0, "disabled reversal installs no native hook")
SetCombat(true); Suite.db.reverseCombinedBags = true; feature:Apply()
equal(constructed, 0, "first combat enable defers frame construction")
equal(type(Suite.pending.combinedBagOrder), "function", "first combat enable queues activation")
Suite.db.reverseCombinedBags = false; feature:Apply()
equal(Suite.pending.combinedBagOrder, nil, "disable cancels pending activation")
SetCombat(false); Suite.db.reverseCombinedBags = true; feature:Apply()
equal(Order(frame), reversed, "ammo then red then blue then backpack, preserving within-bag slot order")
equal(hooks, 1, "the live combined frame receives one post-hook")
equal(constructed, 1, "late loading uses one anonymous event frame")
equal(feature.events.OnUpdate, nil, "combined bag order has no idle updater")
equal(next(feature.events.registered), nil, "attached bag layout needs no engine event subscription")
equal(frame.prompts, 3, "the native locked-slot prompt follows changed anchors")
local first, click = frame.Items[1], frame.Items[1].OnClick
equal(first.parent, frame, "native item parents stay unchanged")
equal(first.OnClick, click, "native item actions stay unchanged")
local both = "3:4,3:3,3:2,3:1,2:4,2:3,2:2,2:1,1:2,1:1,0:3,0:2,0:1"
local slotsOnly = "0:3,0:2,0:1,1:2,1:1,2:4,2:3,2:2,2:1,3:4,3:3,3:2,3:1"
local hearthstone
for _, button in ipairs(frame.Items) do
    if button.bag == 0 and button.slot == 1 then hearthstone = button; button.itemID = 6948 end
end
local oldContainer = C_Container
C_Container = {
    SortBags = function() error("display options must not sort items") end,
    SetSortBagsRightToLeft = function() error("display options must not change bag priority") end,
    PickupContainerItem = function() error("display options must not move physical items") end,
}
Suite.db.reverseBagSlots = true; feature:Apply()
equal(Order(frame), both, "slot reversal preserves reversed bag groups and reverses each group internally")
equal(hearthstone.bag, 0, "Hearthstone remains in the backpack")
equal(hearthstone.slot, 1, "Hearthstone retains its physical first slot")
equal(hearthstone.point[4], 0, "backpack first slot becomes the rightmost cell")
equal(hearthstone.point[5], 4, "backpack first slot becomes the bottommost cell")
equal(hearthstone.parent, frame, "corner placement retains the native item parent")
equal(hearthstone.itemID, 6948, "corner placement does not replace item contents")
frame:UpdateItemLayout(); equal(Order(frame), both, "native refresh preserves both display choices")
frame.layout.stride = 7; frame:UpdateItemLayout()
equal(Order(frame), both, "within-bag reversal preserves section order with partial rows")
equal(hearthstone.point[4], 0, "first backpack slot remains rightmost after column changes")
equal(hearthstone.point[5], 4, "first backpack slot remains bottommost after column changes")
frame.layout.stride = 5
Suite.db.reverseCombinedBags = false; feature:Apply()
equal(Order(frame), slotsOnly, "slot reversal also works without reversed bag section order")
Suite.db.reverseBagSlots = false; feature:Apply()
equal(Order(frame), original, "turning off both options restores the complete native layout")
Suite.db.reverseCombinedBags, Suite.db.reverseBagSlots = true, true; feature:Apply()
SetCombat(true); Suite.db.reverseBagSlots = false; feature:Apply()
equal(Order(frame), both, "changing slot display in combat defers anchoring")
equal(type(Suite.pending.combinedBagOrder), "function", "an active mode change queues combat reconciliation")
feature:Apply(); SetCombat(false); Drain()
equal(Order(frame), reversed, "combat exit applies the changed slot mode without disabling bag reversal")
Suite.db.reverseBagSlots = true; feature:Apply()
SetCombat(true); Suite.db.reverseCombinedBags = false; feature:Apply()
Suite.db.reverseBagSlots = false; feature:Apply(); SetCombat(false); Drain()
equal(Order(frame), original, "final combat state with both toggles off restores native layout")
Suite.db.reverseBagSlots = { secret = true }; feature:Apply()
equal(Order(frame), original, "restricted slot preference never activates display changes")
Suite.db.reverseCombinedBags, Suite.db.reverseBagSlots = true, false; feature:Apply()
C_Container = oldContainer
local before = writes
feature:Apply(); equal(writes, before, "unrelated settings do not relayout bags")
frame:UpdateItemLayout(); equal(Order(frame), reversed, "native refresh reapplies reverse order")
equal(hooks, 1, "refresh does not reinstall hooks")
frame.layout.stride = 7; frame:UpdateItemLayout()
equal(Order(frame), reversed, "partial rows and different column counts retain section order")
frame.layout.stride = 5
frame.Items[1].extended = true; frame:UpdateItemLayout()
equal(frame.Items[1].point[5], 88, "locked extension retains native separate placement")
frame.Items[1].extended = false
gamepad = true; before = writes; frame:UpdateItemLayout()
equal(writes, before, "gamepad bag headers and collapse layout stay native")
gamepad = { secret = true }; frame:UpdateItemLayout()
equal(writes, before, "restricted input mode is left native")
gamepad = false; frame:UpdateItemLayout()
SetCombat(true); before = writes; frame:UpdateItemLayout()
equal(writes, before + 1, "safe native combat relayout immediately retains prepared slot order")
equal(Order(frame), reversed, "unprotected combat bag keeps the chosen section order")
equal(Suite.pending.combinedBagOrder, nil, "successful combat retention needs no deferred replay")
frame.protected = true; before = writes; frame:UpdateItemLayout()
equal(writes, before, "protected container layout still waits through combat")
equal(type(Suite.pending.combinedBagOrder), "function", "unsafe combat relayout queues reversal")
feature:Apply(); equal(type(Suite.pending.combinedBagOrder), "function", "unrelated apply preserves unsafe combat reconciliation")
frame.protected = false
SetCombat(false); Drain(); equal(Order(frame), reversed, "combat exit reapplies reversed sections")
Suite.db.reverseBagSlots = true; feature:Apply()
local beforeFrames, beforeHooks, beforePrompts = constructed, hooks, frame.prompts
SetCombat(true); before = writes; frame:UpdateItemLayout()
equal(Order(frame), both, "reported combat redraw retains both bag and within-bag reversal")
equal(hearthstone.point[4], 0, "Hearthstone remains rightmost during combat redraw")
equal(hearthstone.point[5], 4, "Hearthstone remains bottommost during combat redraw")
equal(writes, before + 1, "one native combat pass gets one synchronous correction")
equal(frame.prompts, beforePrompts + 1, "combat correction never calls the native prompt's anchor writer again")
equal(constructed, beforeFrames, "combat retention constructs no frames")
equal(hooks, beforeHooks, "combat retention installs no hooks")
frame.shown = false; frame.shown = true; frame:UpdateItemLayout()
equal(Order(frame), both, "reopening the prepared combined bag during combat retains order")
local originalItems = frame.Items
local recycled = MakeBag(true)
frame.Items = recycled.Items
for _, button in ipairs(frame.Items) do button.parent = frame end
frame:UpdateItemLayout()
equal(Order(frame), both, "fresh native pooled slot buttons use current combat safety checks")
equal(constructed, beforeFrames, "native pooled slots require no Suite frame construction")
frame.Items = originalItems
local last = frame.Items[#frame.Items]
for _, object in ipairs({ frame, frame.MoneyFrame, last }) do
    for _, method in ipairs({ "IsProtected", "IsAnchoringRestricted", "IsAnchoringSecret" }) do
        local originalPredicate = object[method]
        for _, value in ipairs({ true, { secret = true } }) do
            object[method] = function() return value end
            before = writes; frame:UpdateItemLayout()
            equal(writes, before, "unsafe or unknown native grid member prevents all combat writes: " .. method)
            equal(Order(frame), original, "unsafe combat preflight leaves the whole native order intact")
        end
        object[method] = originalPredicate
    end
end
for _, method in ipairs({ "IsProtected", "IsAnchoringRestricted", "IsAnchoringSecret" }) do
    local originalPredicate = last[method]
    for _, replacement in ipairs({ false, function() return nil end, function() error("unavailable security predicate") end }) do
        if replacement == false then last[method] = nil else last[method] = replacement end
        before = writes; frame:UpdateItemLayout()
        equal(writes, before, "missing, nil or rejected security capabilities forbid combat writes")
        equal(Order(frame), original, "late unsafe slot cannot produce a partly reordered grid")
    end
    last[method] = originalPredicate
end
frame:UpdateItemLayout()
equal(Order(frame), both, "fresh readable false predicates restore combat order without cached refusal")
Suite.db.reverseBagSlots = false; feature:Apply(); frame:UpdateItemLayout()
equal(Order(frame), both, "a new combat setting cannot replace the previously committed display mode")
last.protected = true; frame:UpdateItemLayout(); last.protected = false
SetCombat(false); Drain()
equal(Order(frame), reversed, "deferred unsafe-layout refresh applies the final selected mode")
equal(feature.mode, 1, "deferred refresh commits the mode for later combat passes")
SetCombat(true); frame:UpdateItemLayout()
equal(Order(frame), reversed, "later combat uses the newly committed mode")
SetCombat(false)
SetCombat(true); Suite.db.reverseCombinedBags = false; feature:Apply()
equal(Order(frame), reversed, "disable in combat defers restoration")
equal(next(feature.events.registered), nil, "disabled feature unregisters engine events")
SetCombat(false); Drain(); equal(Order(frame), original, "disable restores native order")
Suite.db.reverseCombinedBags = true; feature:Apply()
SetCombat(true); frame.protected = true; frame:UpdateItemLayout(); frame.protected = false
Suite.db.reverseCombinedBags = false; feature:Apply()
equal(Suite.pending.combinedBagOrder, nil, "disable cancels obsolete combat reversal")
SetCombat(false); Drain(); equal(Order(frame), original, "cancelled combat work cannot reenable reversal")

Suite.db.reverseCombinedBags = true; feature:Apply()
for _, field in ipairs({ "bag", "slot", "extended", "isBag" }) do
    local value = first[field]; first[field] = { secret = true }; before = writes
    feature:Layout(frame); equal(writes, before, "restricted slot classification is never sorted: " .. field)
    first[field] = value
end
for _, owner in ipairs({ frame, first }) do
    owner.forbidden = true; before = writes; feature:Layout(frame)
    equal(writes, before, "forbidden frames are never anchored"); owner.forbidden = nil
end
local direction = frame.layout.direction; frame.layout.direction = { secret = true }; before = writes
feature:Layout(frame); equal(writes, before, "restricted layout direction is not inspected")
frame.layout.direction = direction
local stride = frame.layout.stride; frame.layout.stride = 0 / 0
feature:Layout(frame); equal(writes, before, "invalid stride does not reach grid arithmetic")
frame.layout.stride = stride
local bag = first.bag; first.bag = -2; feature:Layout(frame)
equal(writes, before, "keyring or other containers cannot enter the carried desktop layout"); first.bag = bag
local grid = AnchorUtil.GridLayout; AnchorUtil.GridLayout = nil; feature:Layout(frame)
equal(writes, before, "missing grid capability leaves native anchors intact"); AnchorUtil.GridLayout = grid
Suite.db.reverseCombinedBags = false; feature:Apply()
local late = MakeBag(false); ContainerFrameCombinedBags = nil
Suite.db.reverseCombinedBags = true; feature:Apply()
ContainerFrameCombinedBags = late; feature.events.OnEvent(feature.events, "ADDON_LOADED", "Blizzard_UIPanels_Game")
equal(late.nativeLayouts, 0, "a never-opened frame is hooked without premature native layout")
late.shown = true; late:UpdateItemLayout()
equal(Order(late), reversed, "late first opening uses reverse order")
local lateHooks = hooks; feature.events.OnEvent(feature.events, "ADDON_LOADED", "Unrelated")
equal(hooks, lateHooks, "later addon loads cannot duplicate the frame hook")
Suite.GUI:OpenPage("bags")
equal(Suite.GUI.rows[10].label.text, "Reverse combined bag order", "bag order has a separate clear setting")
equal(Suite.SettingsCatalog:Search("backpack bottom")[1].key, "reverseCombinedBags", "backpack order is searchable")
equal(Suite.GUI.rows[11].label.text, "Reverse slots within each bag", "replacement choice explains within-bag display")
equal(Suite.SettingsCatalog:Search("hearthstone bottom right")[1].key, "reverseBagSlots", "Hearthstone goal finds the within-bag option")
Suite.Apply = function() feature:Apply() end
Suite.GUI.rows[11].OnClick()
equal(Order(late), both, "within-bag checkbox places backpack first slot at the bottom right")
equal(Suite.db.reverseBagSlots, true, "within-bag checkbox saves independently")
Suite.GUI.rows[11].OnClick()
equal(Order(late), reversed, "within-bag checkbox can restore slot order while retaining bag reversal")
Suite.GUI.rows[10].OnClick()
equal(Suite.db.reverseCombinedBags, false, "bag order switch saves disabling")
equal(Suite.db.sortBagsOnOpen, false, "reversal does not enable sorting items")
equal(Suite.db.windowTools, false, "reversal does not require window tools")
equal(Order(late), original, "the setting restores native display immediately")
Suite.Apply, Suite.db, Suite.pending = oldApply, oldDB, oldPending
for _, name in ipairs(names) do _G[name] = saved[name] end
SetCombat(false)
