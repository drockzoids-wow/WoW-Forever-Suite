local Suite, equal, Frame, SetCombat = ...
local search, inventory = Suite.InventorySearch, Suite.Inventory
local keys = { "CreateFrame", "C_Timer", "C_Item", "C_Container", "C_Bank", "C_EventUtils", "UIParent",
    "UnitGUID", "UnitName", "UnitClass", "GetNormalizedRealmName", "GetCurrentRegion", "GetServerTime", "Enum",
    "NUM_TOTAL_EQUIPPED_BAG_SLOTS", "BagItemSearchBox", "BankItemSearchBox", "BankFrame", "GameTooltip",
    "IsModifiedClick", "HandleModifiedItemClick", "date" }
local old, oldSearch, oldInventory = {}, {}, {}
for _, key in ipairs(keys) do old[key] = _G[key] end
for key, value in pairs(search) do oldSearch[key] = value end
for key, value in pairs(inventory) do oldInventory[key] = value end
local oldDB, oldPending, oldOfflineSearch = Suite.db, Suite.pending, Suite.OfflineBank.search
local timers, constructed, nativeCalls, linked = {}, 0, 0, 0
local function Widget(parent)
    local frame = Frame(); frame.parent = parent
    frame.IsForbidden = function(self) return self.forbidden or false end
    frame.IsProtected = function(self) return self.protected or false end
    frame.IsAnchoringRestricted = function(self) return self.anchoring or false end
    frame.HasFocus = function(self) return self.focused or false end
    frame.IsMouseOver = function(self) return self.over or false end
    frame.IsVisible = function(self)
        if self.visibility ~= nil then return self.visibility end
        return self.shown == true and (not self.parent or self.parent:IsVisible())
    end
    frame.Show = function(self) local changed = not self.shown; self.shown = true; if changed and self.OnShow then self.OnShow(self) end end
    frame.Hide = function(self)
        assert(not InCombatLockdown() or self.protected ~= true, "protected hide must defer")
        local changed = self.shown; self.shown = false; if changed and self.OnHide then self.OnHide(self) end
    end
    frame.SetShown = function(self, value) if value then self:Show() else self:Hide() end end
    frame.SetText = function(self, text)
        local changed = self.text ~= text; self.text = text
        if changed and self.OnTextChanged then self.OnTextChanged(self, false) end
    end
    frame.CreateTexture = function()
        local texture = Frame()
        texture.SetAllPoints = function(self, target) self.allPoints = target end
        return texture
    end
    for _, method in ipairs({ "SetPoint", "ClearAllPoints", "SetSize", "SetHeight", "SetFrameLevel", "SetFrameStrata", "HookScript" }) do
        local original = frame[method]
        frame[method] = function(self, ...)
            assert(not InCombatLockdown(), method .. " must stay outside combat")
            if method == "HookScript" and self.rejectHook then error("script bindings restricted") end
            if method == "HookScript" and self.hookResult == false then return false end
            local result = original(self, ...)
            if method == "HookScript" then return self.hookResult or true end
            return result
        end
    end
    return frame
end
CreateFrame = function(_, _, parent)
    assert(not InCombatLockdown(), "search creates no combat frames")
    constructed = constructed + 1
    local frame = Widget(parent); frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    return frame
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
local function Flush()
    local batch = timers; timers = {}
    for _, timer in ipairs(batch) do if not timer.cancelled then timer.callback() end end
end
local function Pending()
    local count = 0; for _, timer in ipairs(timers) do if not timer.cancelled then count = count + 1 end end
    return count
end
UIParent = Widget(); UIParent:SetSize(1000, 800); UIParent:Show()
UnitGUID = function() return "Player-110-1" end
UnitName = function() return "Zoids", "Frostrun" end
UnitClass = function() return "Mage", "MAGE" end
GetNormalizedRealmName = function() return "ClassicBetaPvE" end
GetCurrentRegion = function() return 110 end
GetServerTime = function() return 1000 end
NUM_TOTAL_EQUIPPED_BAG_SLOTS = 5
Enum = { BankType = { Character = 0, Account = 2 } }
C_EventUtils = { IsEventValid = function() return true end }
local bags = { [0] = { { itemID = 100, stackCount = 8 }, { itemID = 200, stackCount = 3 } },
    [6] = { { itemID = 100, stackCount = 5 } } }
C_Container = { GetContainerNumSlots = function(id) return bags[id] and #bags[id] or 0 end,
    GetContainerItemInfo = function(id, slot) return bags[id] and bags[id][slot] end,
    GetContainerItemID = function(id, slot) return bags[id] and bags[id][slot] and bags[id][slot].itemID end,
    SetItemSearch = function() nativeCalls = nativeCalls + 1 end,
    UseContainerItem = function() error("search must never use/move/sell an item") end }
C_Bank = { CanViewBank = function(kind) return kind == 0 end,
    FetchPurchasedBankTabIDs = function() return { 6 } end, FetchNumPurchasedBankTabs = function() return 1 end }
local data = { [100] = { "Runecloth", "Trade Goods", "Cloth" }, [200] = { "Healing Potion", "Consumable", "Potion" },
    [300] = { "Rune Thread", "Trade Goods", "Reagent" }, [400] = { "Runecloth Bag", "Container", "Bag" } }
local requested = {}
C_Item = { GetItemInfo = function(id)
    local item = data[id]; if not item then return end
    return item[1], "|Hitem:" .. id .. ":0|h[" .. item[1] .. "]|h", 1, 1, 1, item[2], item[3], 20, "", 123
end, RequestLoadItemDataByID = function(id) requested[id] = (requested[id] or 0) + 1 end }
local bagParent = Widget(UIParent); bagParent.name = "ContainerFrame1"
bagParent:SetSize(240, 400); bagParent.centerX = 850; bagParent:Show()
BagItemSearchBox = Widget(bagParent); BagItemSearchBox:Show()
BankFrame = Widget(UIParent); BankFrame.name = "BankFrame"; BankFrame.centerX = 300; BankFrame:Show()
BankItemSearchBox = Widget(BankFrame); BankItemSearchBox:Show(); BankFrame.BankItemSearchBox = BankItemSearchBox
local boxes = { BagItemSearchBox, BankItemSearchBox }
for _, box in ipairs(boxes) do
    box:SetScript("OnTextChanged", function(self)
        for _, other in ipairs(boxes) do if other:GetText() ~= self:GetText() then other:SetText(self:GetText()) end end
        C_Container.SetItemSearch(self:GetText())
    end)
    box:SetScript("OnEscapePressed", function(self) self.focused = false end)
end
GameTooltip = Widget(UIParent)
GameTooltip.SetOwner = function(self, owner) self.owner = owner; self.lines = {} end
GameTooltip.GetOwner = function(self) return self.owner end
GameTooltip.SetHyperlink = function(self, link) self.link = link end
IsModifiedClick = function() return false end
HandleModifiedItemClick = function() linked = linked + 1 end
date = function(_, value) return "Recorded " .. value end
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
search.records, search.requested, search.metadata, search.index, search.popup = {}, {}, {}, nil, nil
search.owner, search.timer, search.events, search.active, search.shuttingDown = nil, nil, nil, nil, nil
inventory.active, inventory.events, inventory.timer, inventory.bankOpen = nil, nil, nil, nil
Suite.OfflineBank.search = nil
equal(Suite.db.inventorySearch, false, "cross-character search starts off independently")
equal(Suite.InitializeDB({ inventorySearch = { secret = true } }).inventorySearch, false, "restricted preference is sanitized")
search:Apply(); inventory:Apply()
equal(constructed, 0, "disabled search and tracking construct no feature frames")
equal(Pending(), 0, "disabled search leaves no idle timers")
Suite.db.inventorySearch = true
SetCombat(true); inventory:Apply(); search:Apply()
equal(constructed, 0, "first search enable defers combat construction")
Suite.db.inventorySearch = false; search:Apply(); inventory:Apply()
equal(Suite.pending.inventorySearchEnable, nil, "disable cancels pending search enable")
Suite.db.inventorySearch = true; SetCombat(false); inventory:Apply(); search:Apply()
equal(Suite.db.itemInventory, false, "search does not enable tooltip counts")
equal(inventory.active, true, "search independently starts shared snapshot recording")
local player = Suite.db.inventory.characters["Player-110-1"]
equal(player.fullName, "Zoids Frostrun", "inventory captures native Forever surnames")
equal(player.bags.items[100], 8, "search recording captures carried stacks")
inventory:OnEvent("BANKFRAME_OPENED"); Flush()
equal(player.bank.items[100], 5, "search recording captures banks on a visit")
local characters = Suite.db.inventory.characters
characters["Player-110-2"] = { name = "Zoids", realm = "ClassicBetaPvE", region = 110,
    bags = { items = { [100] = 12, [300] = 2 }, at = 800 }, bank = { items = { [100] = 4 }, at = 700 } }
characters["Player-110-3"] = { name = "Zoids", fullName = "Zoids Stone", realm = "ClassicBetaPvE", region = 110,
    bank = { items = { [100] = 7 }, at = 600 } }
characters.remote = { name = "Other", realm = "Elsewhere", region = 1, bags = { items = { [100] = 999 } } }
characters.unknown = { name = "Unknown", realm = "Realm", region = { secret = true }, bags = { items = { [100] = 999 } } }
Suite.db.mailContacts.entries.known = { name = "Zoids Iron", guid = "Player-110-2", region = 110, ruleset = "PvE" }
Suite.db.mailContacts.entries.oldPlayer = { name = "Zoids Oldname", guid = "Player-110-1", region = 110, ruleset = "PvE" }
Suite.db.inventory.accountBanks[110] = { items = { [100] = 20 }, at = 500 }
search:InventoryChanged()
local function Query(text) return search:Query(text) end
local rows = Query("runecloth")
equal(#rows, 4, "one matching item lists three owners and shared bank exactly once")
equal(rows[1].owner.current, true, "current owner sorts before other owners of the same item")
equal(rows[1].owner.name, "Zoids Frostrun", "fresh native full name wins over stale mail contact")
equal(rows[1].bags, 8, "current character bags remain a separate count")
equal(rows[1].bank, 5, "current character bank remains a separate count")
equal(rows[2].owner.name, "Warband", "shared inventory has its own owner row")
equal(rows[3].owner.name, "Zoids Iron", "known GUID mail identity completes an old inventory name")
equal(rows[3].bags, 12, "same first names do not merge independent GUID counts")
equal(rows[4].owner.name, "Zoids Stone", "same server surnames remain distinguishable")
equal(search:Counts(rows[4]), "Bank: 7", "unrecorded bags never appear as a false zero")
equal(#Query("  rune cloth  "), 4, "case-insensitive multiword matching is literal AND")
equal(#Query("potion"), 1, "native item subtype participates in search")
equal(#Query("100"), 4, "exact numeric item ID can find every recorded owner")
equal(#Query("%"), 0, "query metacharacters are literal rather than Lua patterns")
equal(#Query(" "), 0, "empty input does not enumerate the whole account")
equal(#Query({ secret = true }), 0, "restricted search text is never compared or formatted")
local function Type(box, text)
    for _, other in ipairs(boxes) do other.focused = other == box end
    box:SetText(text); Flush()
end
Type(BagItemSearchBox, "runecloth")
equal(search.owner, BagItemSearchBox, "synchronized bank callback cannot steal the active bag dropdown")
equal(BankItemSearchBox:GetText(), "runecloth", "native search synchronization survives the observer")
equal(nativeCalls > 0, true, "native container filtering continues receiving text")
equal(search.popup:IsShown(), true, "typing in native search displays the dropdown")
equal(search.popup.point[2], bagParent, "popup attaches to the owning bag rather than beneath its search field")
equal(search.popup.point[1], "TOPRIGHT", "right-side bag places results on its left")
equal(search.popup.point[3], "TOPLEFT", "results align with the bag's outer top edge")
equal(search.popup.point[4], -8, "left popup has a gap outside the bag")
equal(search.popup.parent, UIParent, "results retain independent scale and native bag parenting")
Suite.db.windowTools = true
Suite.db.windowPositions.ContainerFrame1 = { x = -0.25, y = 0, scale = 1 }
search:WindowChanged(bagParent)
equal(search.popup.point[1], "TOPLEFT", "saved left-side placement takes precedence over transient native geometry")
equal(search.popup.point[3], "TOPRIGHT", "left-side bag places results beyond its right edge")
equal(search.popup.point[4], 8, "right popup has a gap outside the bag")
bagParent.centerX = 250
Suite.db.windowPositions.ContainerFrame1.x = 0.25
search:WindowChanged(bagParent)
equal(search.popup.point[1], "TOPRIGHT", "saved right-side placement wins while live geometry is still on the left")
Suite.db.windowTools = false; search:WindowChanged(bagParent)
equal(search.popup.point[1], "TOPLEFT", "disabled window tools use actual placement rather than an inactive saved position")
Suite.db.windowTools = true
Suite.db.windowPositions.ContainerFrame1.x = { secret = true }; search:WindowChanged(bagParent)
equal(search.popup.point[1], "TOPLEFT", "restricted saved coordinates fall back to readable live geometry")
Suite.db.windowPositions.ContainerFrame1.x = math.huge; search:WindowChanged(bagParent)
equal(search.popup.point[1], "TOPLEFT", "nonfinite saved coordinates cannot determine placement")
Suite.db.windowPositions.ContainerFrame1 = nil
bagParent.centerX = 850; Suite.Windows:Save({ frame = bagParent, name = "ContainerFrame1" })
equal(search.popup.point[1], "TOPRIGHT", "saving a moved bag immediately updates the existing popup's side")
equal(search.page, 1, "moving the window preserves the current result page")
equal(Pending(), 0, "placement notifications add no polling or query work")
local moved = { frame = bagParent, name = "ContainerFrame1" }
Suite.db.windowPositions.ContainerFrame1.x = -0.25
Suite.Windows:ApplySavedPosition(moved, Suite.db.windowPositions.ContainerFrame1)
equal(search.popup.point[1], "TOPLEFT", "native saved-position restores update the popup without a new query")
Suite.db.windowTools = false; bagParent.centerX = 850
Suite.Windows:ApplyRecord({ frame = bagParent, name = "ContainerFrame1", handles = {} })
equal(search.popup.point[1], "TOPRIGHT", "window reset or restore completion reconsiders the live side")
Suite.db.windowPositions.ContainerFrame1 = nil
UIParent.scale = 0.8; bagParent.scale = 2; bagParent.centerX = 300
search:WindowChanged(bagParent)
equal(search.popup.point[1], "TOPRIGHT", "live side comparison converts scaled bag coordinates into screen units")
bagParent.scale = 0.5; bagParent.centerX = 800; search:WindowChanged(bagParent)
equal(search.popup.point[1], "TOPLEFT", "a smaller bag on the left is not misclassified by its unscaled center")
bagParent.scale = 1; UIParent.scale = 1; bagParent.centerX = 500
search:WindowChanged(bagParent)
equal(search.popup.point[1], "TOPRIGHT", "a centered bag consistently places results on its left")
bagParent.centerX = 850
local combined = Widget(UIParent); combined.name = "ContainerFrameCombinedBags"; combined.centerX = 250; combined:Show()
BagItemSearchBox:SetParent(combined); search:Render()
equal(search.popup.point[2], combined, "reparenting the native field moves results to the combined bag")
equal(search.popup.point[1], "TOPLEFT", "combined bags choose their own screen side")
bagParent:Hide()
equal(search.popup:IsShown(), true, "hiding the former backpack does not dismiss results attached to a visible combined bag")
combined:Hide()
equal(search.popup:IsShown(), false, "a newly discovered combined parent hides its popup with the window")
BagItemSearchBox:SetParent(bagParent); bagParent:Show(); BagItemSearchBox.OnEditFocusGained(); Flush()
equal(search.buttons[1].owner:GetText(), "Zoids Frostrun (You)", "compact results retain visible character ownership")
search.buttons[1].OnEnter()
equal(GameTooltip.link, "|Hitem:100:0|h[Runecloth]|h", "result hover uses a native item hyperlink")
equal(GameTooltip.lines[5][1], "Bags recorded: Recorded 1000", "hover discloses the bag capture timestamp")
GameTooltip.owner = BankFrame; GameTooltip:Show(); search:HideTooltip()
equal(GameTooltip:IsShown(), true, "search cleanup preserves a tooltip subsequently owned by a native control")
search.buttons[1].OnClick(); equal(linked, 0, "plain click performs no native item operation")
IsModifiedClick = function() return true end
search.buttons[1].OnClick(); equal(linked, 1, "explicit modified click forwards only the native item link")
IsModifiedClick = function() return { secret = true } end
search.buttons[1].OnClick(); equal(linked, 1, "restricted modifier cannot authorize a native link action")
for id = 601, 610 do data[id] = { "Rune Item " .. id, "Trade Goods", "Reagent" }; player.bags.items[id] = 1 end
search:InventoryChanged(); Type(BagItemSearchBox, "rune")
equal(search.pageLabel:GetText(), "1/4", "large match sets are paginated in compact pages")
search.next.OnClick(); equal(search.page, 2, "page controls expose additional owners and items")
search.popup.OnMouseWheel(search.popup, -1); equal(search.page, 3, "mouse wheel advances the dropdown page")
Type(BankItemSearchBox, "potion")
equal(search.owner, BankItemSearchBox, "typing in bank search moves the single dropdown")
equal(search.page, 1, "new query resets the page")
equal(search.popup.point[2], BankFrame, "bank results attach to the bank's outer edge")
equal(search.popup.point[1], "TOPLEFT", "left-side bank places results on its right")
equal(#search.rows, 1, "bank query also finds items recorded in bags")
BagItemSearchBox.focused, BankItemSearchBox.focused = false, true
BankItemSearchBox:SetText("")
equal(search.owner, nil, "clearing search immediately dismisses stale results")
equal(search.popup:IsShown(), false, "empty search hides the dropdown")
Type(BagItemSearchBox, "rune")
BagItemSearchBox.over = false; search.popup.over = true; search:OnEvent("GLOBAL_MOUSE_DOWN")
equal(search.popup:IsShown(), true, "clicking dropdown pagination does not dismiss it")
search.popup.over = false; search:OnEvent("GLOBAL_MOUSE_DOWN")
equal(search.popup:IsShown(), false, "outside click dismisses without clearing native filters")
equal(BagItemSearchBox:GetText(), "rune", "dismissal preserves native search text")
BagItemSearchBox.OnEditFocusGained(); Flush(); BagItemSearchBox.OnEscapePressed(BagItemSearchBox)
equal(search.popup:IsShown(), false, "Escape preserves its native handler and dismisses the extension")
equal(BagItemSearchBox.focused, false, "native Escape focus behavior remains intact")
Type(BagItemSearchBox, "potion"); bagParent:Hide()
equal(search.popup:IsShown(), false, "hiding a source window hides UIParent-owned results")
bagParent:Show()
Type(BagItemSearchBox, "rune"); BagItemSearchBox:SetText("potion")
equal(search.popup:IsShown(), false, "new input immediately hides stale clickable results during debounce")
equal(Pending(), 1, "burst typing coalesces into one worker")
SetCombat(true); search:OnEvent("PLAYER_REGEN_DISABLED")
equal(Pending(), 0, "combat entry cancels pending work")
equal(search.popup:IsShown(), false, "combat entry hides the ordinary search popup")
local beforeCombat = constructed
search:Discover(); search:FromBox(BagItemSearchBox, true); Flush()
search:WindowChanged(bagParent)
equal(constructed, beforeCombat, "combat never constructs or anchors search UI")
SetCombat(false); search:OnEvent("PLAYER_REGEN_ENABLED")
equal(search.owner, nil, "combat exit does not reopen a stale query")
BagItemSearchBox.OnEditFocusGained(); Flush()
equal(search.popup:IsShown(), true, "another explicit field focus can reopen after combat")
search.popup.protected = true; SetCombat(true); search:OnEvent("PLAYER_REGEN_DISABLED")
equal(type(Suite.pending.inventorySearchHide), "function", "unexpected popup protection defers its hide")
SetCombat(false); Suite.pending.inventorySearchHide(); search.popup.protected = nil
equal(search.popup:IsShown(), false, "deferred cleanup hides the protected popup safely")
Suite.pending.inventorySearchHide = nil
player.bags.items[500] = 2; search:InventoryChanged()
local _, pending = Query("unloaded")
equal(pending, 1, "uncached item metadata is disclosed without inventing a name")
equal(requested[500], 1, "uncached metadata is requested once")
Query("unloaded"); equal(requested[500], 1, "repeated input cannot create a loading retry loop")
data[500] = { "Unloaded Supplies", "Consumable", "Other" }
Type(BagItemSearchBox, "unloaded"); search:OnEvent("ITEM_DATA_LOAD_RESULT", 500); Flush()
equal(#search.rows, 1, "native item data completion reveals previously unavailable matching items")
equal(search.buttons[1].entry.id, 500, "completed data updates the matching owner row")
for id = 700, 764 do player.bags.items[id] = 1 end
search:InventoryChanged(); Type(BagItemSearchBox, "nothing")
local loadCount = 0; for id, attempts in pairs(requested) do if id >= 700 then loadCount = loadCount + attempts end end
equal(loadCount, 32, "unavailable data loads are bounded per coalesced worker")
Flush(); Flush()
loadCount = 0; for id, attempts in pairs(requested) do if id >= 700 then loadCount = loadCount + attempts end end
equal(loadCount, 65, "finite metadata batches eventually cover all recorded items")
equal(Pending(), 0, "unanswered metadata requests leave no idle timers")
characters.bad = { name = "Bad", realm = "Realm", region = 110, bags = { items = { [100] = { secret = true } } } }
characters.hidden = { secret = true }
characters["Player-110-3"].bags = { secret = true }
player.bags.items[999] = -2; player.bags.items[998] = math.huge
search:InventoryChanged(); equal(#Query("runecloth"), 4, "invalid and restricted snapshots cannot contribute counts")
local region = GetCurrentRegion
GetCurrentRegion = function() return { secret = true } end
equal(#Query("rune"), 0, "unreadable region invalidates an already cached scope without exposing records")
GetCurrentRegion = function() return 1 end
local remote = Query("runecloth")
equal(#remote, 1, "a changed readable region rebuilds the index rather than reusing prior owners")
equal(remote[1].owner.name, "Other", "region changes retain only the appropriate recorded owners")
GetCurrentRegion = region
search:InventoryChanged(); BagItemSearchBox.visibility = { secret = true }; search:Refresh()
equal(search.owner, nil, "restricted source visibility dismisses results")
BagItemSearchBox.visibility = nil
BagItemSearchBox.OnEditFocusGained(); Flush()
local liveCenter = bagParent.GetCenter
bagParent.GetCenter = function() return { secret = true } end; search:WindowChanged(bagParent)
equal(search.owner, nil, "unreadable live geometry dismisses results rather than guessing an overlapping anchor")
bagParent.GetCenter = liveCenter
BagItemSearchBox.OnEditFocusGained(); Flush()
UIParent.width = 0; search:WindowChanged(bagParent)
equal(search.popup:IsShown(), false, "unavailable screen dimensions leave no orphan side popup")
UIParent.width = 1000
local savedBank = Widget(UIParent); savedBank.name = "WoWForeverSuiteBankView"; savedBank.centerX = 800; savedBank:Show()
local late = Widget(savedBank); late:Show(); Suite.OfflineBank.search = late
search:Discover(); equal(type(late.OnTextChanged), "function", "late saved-bank search receives the same extension")
late.focused = true; late:SetText("potion"); Flush()
equal(search.owner, late, "saved bank search can query all recorded characters")
equal(search.popup.point[2], savedBank, "offline bank search attaches to its owning saved-bank window")
equal(search.popup.point[1], "TOPRIGHT", "right-side saved bank places results on its left")
late.forbidden = true; search:Refresh(); equal(search.owner, nil, "forbidden source remains untouched")
late.forbidden = nil
late.anchoring = { secret = true }; search:Discover()
late.focused = true; late:SetText("rune"); Flush()
equal(search.owner, nil, "restricted anchoring leaves the source native and does not attach results")
late.anchoring = nil
local rejected = Widget(UIParent); rejected:Show(); rejected.rejectHook = true
Suite.OfflineBank.search = rejected; search:Discover()
equal(rejected.OnTextChanged, nil, "restricted script bindings are contained")
rejected.rejectHook = nil; search:Discover()
equal(type(rejected.OnTextChanged), "function", "later permitted discovery can retry previously unavailable hooks")
local declined = Widget(UIParent); declined:Show(); declined.hookResult = false
Suite.OfflineBank.search = declined; search:Discover()
equal(declined.OnTextChanged, nil, "readable false HookScript result keeps the native field alone")
declined.hookResult = nil; search:Discover()
equal(type(declined.OnTextChanged), "function", "explicitly rejected hooks can be retried once access returns")
local uncertain = Widget(UIParent); uncertain:Show(); uncertain.hookResult = { secret = true }
Suite.OfflineBank.search = uncertain; search:Discover()
uncertain.focused = true; uncertain:SetText("potion"); Flush()
equal(search.owner, nil, "unknown hook result cannot activate a callback installed by an uncertain native outcome")
uncertain.hookResult = nil; search:Discover(); uncertain:SetText("rune"); Flush()
equal(search.owner, nil, "uncertain binding outcomes do not install duplicate active observers")
Suite.db.inventorySearch = false; search:Apply(); inventory:Apply()
equal(Pending(), 0, "disable cancels all dropdown work")
equal(next(search.events.registered), nil, "disable removes search event subscriptions")
equal(inventory.active, nil, "shared recording stops when both consumers are off")
Type(BagItemSearchBox, "rune"); equal(search.owner, nil, "retained disabled hooks cannot open results")
Suite.db.itemInventory = true; inventory:Apply()
equal(inventory.active, true, "tooltip tracking still works independently after disabling search")
Suite.db.inventorySearch = true; search:Apply(); BagItemSearchBox.OnEditFocusGained(); Flush()
search:OnEvent("PLAYER_LOGOUT"); search:InventoryChanged()
equal(Pending(), 0, "logout cannot requeue inventory-driven search work")
equal(search.popup:IsShown(), false, "logout clears the visible popup")
Suite.db.inventorySearch = false; search:Apply()
Suite.db.itemInventory = false; inventory:Apply()
for _, key in ipairs(keys) do _G[key] = old[key] end
for key in pairs(search) do search[key] = nil end
for key, value in pairs(oldSearch) do search[key] = value end
for key in pairs(inventory) do inventory[key] = nil end
for key, value in pairs(oldInventory) do inventory[key] = value end
Suite.db, Suite.pending, Suite.OfflineBank.search = oldDB, oldPending, oldOfflineSearch
SetCombat(false)
