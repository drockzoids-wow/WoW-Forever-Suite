local Suite, equal, Frame, SetCombat = ...
local bank = Suite.OfflineBank
local names = { "CreateFrame", "C_Timer", "C_Container", "C_Bank", "C_Item", "Enum", "BankFrame", "UIParent",
    "UnitGUID", "UnitName", "UnitClass", "GetNormalizedRealmName", "GetCurrentRegion", "GetServerTime", "date",
    "SetItemButtonTexture", "SetItemButtonCount", "GameTooltip", "GameTooltip_ShowCompareItem", "IsModifiedClick",
    "HandleModifiedItemClick", "HideUIPanel", "UISpecialFrames", "WoWForeverSuiteBankView", "WoWForeverSuiteBankToggleButton" }
local old = {}
for _, name in ipairs(names) do old[name] = _G[name] end
local oldDB, oldPending, oldPrint = Suite.db, Suite.pending, Suite.Print
local oldWindows, oldItems = Suite.Windows, Suite.Items
local oldLayoutFrame = bank.layoutFrame
local function Near(actual, expected, label) equal(math.abs(actual - expected) < 0.000001, true, label) end
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
bank.frame, bank.events, bank.bindingButton, bank.active, bank.bankOpen = nil, nil, nil, nil, nil
bank.layoutFrame = nil
bank.buttons, bank.pageTabs, bank.bagButtons, bank.requested, bank.page, bank.bankType = {}, {}, {}, {}, 1, 0
local timers, created, calls, requests, modified, comparisons, messages = {}, 0, 0, {}, {}, 0, {}
local identity, region = "Player-110-first", 110
local accessible, ids, sizes, bags = { [0] = true, [2] = true }, { [0] = { 6, 7 }, [2] = { 13 } }, { [6] = 28, [7] = 70, [13] = 90 }, {}
local purchased = { [0] = 2, [2] = 1 }
local metadata = { [0] = { { ID = 6, name = "Bank", icon = 11 }, { ID = 7, name = "Big bag", icon = 12 } },
    [2] = { { ID = 13, name = "Shared", icon = 13 } } }
local time, keyMode = 100, nil
local function Item(id, count, suffix)
    return { itemID = id, stackCount = count, iconFileID = 1000 + id, quality = 3, itemName = "Item " .. id,
        hyperlink = "|cff0070dd|Hitem:" .. id .. ":" .. (suffix or "0") .. "|h[Item " .. id .. "]|h|r" }
end
bags[6], bags[7], bags[13] = { [1] = Item(100, 3, "123:456"), [28] = Item(200, 1) }, { [1] = Item(100, 5), [70] = Item(300, 2) }, { [90] = Item(400, 4) }
local function Flush()
    local work = timers; timers = {}
    for _, timer in ipairs(work) do if not timer.cancelled then timer.callback() end end
end
local function TimerCount()
    local n = 0; for _, timer in ipairs(timers) do if not timer.cancelled then n = n + 1 end end; return n
end
local function Fire(event, ...)
    bank.events.OnEvent(bank.events, event, ...)
end
local function Forbidden() error("Offline viewer attempted a bank transaction") end
local function Widget(name)
    local widget = Frame(name)
    widget.SetAtlas = function(self, atlas) self.atlas = atlas end
    widget.SetAllPoints = function() end
    widget.SetHorizTile, widget.SetVertTile = function() end, function() end
    widget.SetMaxLetters = function() end
    widget.SetToplevel = function(self, top) self.toplevel = top end
    widget.IsForbidden = function() return false end
    widget.IsMouseOver = function(self) return self.mouseOver == true end
    return widget
end
CreateFrame = function(kind, name, parent, template)
    assert(not InCombatLockdown(), "Offline bank created a frame during combat")
    assert(template ~= "BankFrameTemplate" and template ~= "BankPanelTemplate" and template ~= "CamelotBankItemButtonTemplate", "Live bank scripts inherited")
    created = created + 1
    local frame = Widget(name); frame.parent, frame.objectType, frame.template = parent, kind, template
    frame.SetPoint = function(self, ...) assert(not InCombatLockdown(), "Combat anchor change"); self.point = { ... } end
    frame.SetHeight = function(self, value) assert(not InCombatLockdown(), "Combat height change"); self.height = value end
    frame.SetScale = function(self, value) assert(not InCombatLockdown(), "Combat scale change"); self.scale = value end
    frame.CreateTexture = function() return Widget() end
    frame.CreateFontString = function(_, _, _, font) local result = Widget(); result.fontTemplate = font; return result end
    frame.Hide = function(self) self.shown = false; if self.OnHide then self.OnHide(self) end end
    frame.RegisterEvent = function(self, event) self.registered = self.registered or {}; self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    frame.Click = function(self, button) if self.OnClick then self.OnClick(self, button or "LeftButton") end end
    if template == "PortraitFrameTemplate" then
        frame.CloseButton = Widget()
        frame.SetTitle = function(self, title) self.title = title end
        frame.SetPortraitToAsset = function(self, asset) self.portrait = asset end
    elseif template == "LargeSideTabButtonTemplate" then
        frame.Icon = Widget()
        frame.SetFillToInterior = function() end
        frame.SetCustomOnMouseUpHandler = function(self, callback) self.customMouseUpHandler = callback end
    end
    if kind == "ItemButton" then
        frame.icon, frame.Count, frame.searchOverlay, frame.normal = Widget(), Widget(), Widget(), Widget()
        frame.GetNormalTexture = function(self) return self.normal end
        frame.SetItemButtonQuality = function(self, quality, link) self.quality, self.qualityLink = quality, link end
        -- Match the intrinsic ItemButton: both methods exist but return nil for a snapshot.
        frame.GetBagID = function(self) return self.bagID end
        frame.GetID = function() return 0 end
        frame.GetItemLocation = function(self) return self.itemLocation end
        frame.GetItemLink = function(self) return self.itemLink end
        if template == "WoWForeverSuiteBankBagTemplate" then frame.Background = Widget() end
    end
    if name then _G[name] = frame end
    return frame
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
UIParent, BankFrame, UISpecialFrames = Widget(), Widget(), {}
UIParent:SetSize(1920, 1080); UIParent:SetScale(0.8)
BankFrame.parent = UIParent; BankFrame:SetSize(480, 460); BankFrame:SetScale(1.25)
BankFrame.rect = { 120, 200, 480, 460 }
UnitGUID = function() return identity end
UnitName = function() return "Banker" end
UnitClass = function() return "Mage", "MAGE" end
GetNormalizedRealmName = function() return "Beta" end
GetCurrentRegion = function() return region end
GetServerTime = function() return time end
date = function(_, stamp) return "date " .. stamp end
Enum = { BankType = { Character = 0, Account = 2 } }
C_Bank = {
    CanViewBank = function(bankType) return accessible[bankType] end,
    ShouldUsePlayerBagsInBank = function() return true end,
    FetchPurchasedBankTabIDs = function(bankType) return ids[bankType] end,
    FetchNumPurchasedBankTabs = function(bankType) return purchased[bankType] end,
    FetchPurchasedBankTabData = function(bankType) return metadata[bankType] end,
    PurchaseBankTab = Forbidden, DepositMoney = Forbidden, WithdrawMoney = Forbidden,
}
C_Container = {
    GetContainerNumSlots = function(bag) calls = calls + 1; return sizes[bag] end,
    GetContainerItemInfo = function(bag, slot) calls = calls + 1; return bags[bag] and bags[bag][slot] end,
    GetContainerItemID = function(bag, slot)
        local info = bags[bag] and bags[bag][slot]
        return info and info.itemID or (bags[bag] and bags[bag].pending and bags[bag].pending[slot])
    end,
    PickupContainerItem = Forbidden, UseContainerItem = Forbidden, SplitContainerItem = Forbidden,
}
C_Item = { RequestLoadItemDataByID = function(id) requests[id] = (requests[id] or 0) + 1 end }
SetItemButtonTexture = function(button, icon) button.icon.texture = icon end
SetItemButtonCount = function(button, count) button.Count.text = count end
GameTooltip = Widget()
GameTooltip.SetOwner = function(self, owner) self.owner = owner end
GameTooltip.SetHyperlink = function(self, link) self.link = link end
GameTooltip.IsOwned = function(self, owner) return self.owner == owner end
GameTooltip_ShowCompareItem = function() comparisons = comparisons + 1 end
IsModifiedClick = function(mode) return keyMode == mode end
HandleModifiedItemClick = function(link) modified[#modified + 1] = link end
HideUIPanel = function(frame) frame:Hide(); if bank.events then Fire("BANKFRAME_CLOSED") end end
Suite.Print = function(message) messages[#messages + 1] = message end
Suite.Windows = { Track = function() end }
Suite.Items = { Track = function() end }

equal(Suite.db.offlineBank, false, "offline bank defaults off")
bank:Apply()
equal(bank.events, nil, "disabled bank does not register feature events")
equal(calls, 0, "disabled bank does not query containers")
equal(bank.bindingButton:GetName(), "WoWForeverSuiteBankToggleButton", "binding has a stable native click target")
equal(BINDING_HEADER_WOWFOREVERSUITE, "Forever Suite", "native binding header")
equal(_G["BINDING_NAME_CLICK WoWForeverSuiteBankToggleButton:LeftButton"], "Open bank view", "native binding label")
bank.bindingButton:Click(); equal(bank.frame, nil, "disabled key does not create the viewer")
Suite.db.offlineBank = true; bank:Apply()
equal(bank.active, true, "bank recording enabled independently of inventory tooltips")
equal(Suite.db.itemInventory, false, "offline bank does not enable inventory tooltips")
equal(calls, 0, "enabling away from banker does not scan inaccessible bank")
Suite.db.windowTools = true
Suite.db.windowPositions.WoWForeverSuiteBankView = { x = 0.1, y = 0.1, scale = 1 }
bank.bindingButton:Click()
equal(bank.frame:GetNumPoints(), 1, "existing snapshot placement still initializes a native reset anchor before mover discovery")
Suite.db.windowTools = false; Suite.db.windowPositions.WoWForeverSuiteBankView = nil
equal(bank.frame.template, "PortraitFrameTemplate", "viewer uses native portrait framing")
equal(bank.frame.toplevel, true, "native bank window raises on mouse interaction")
equal(bank.empty:IsShown(), true, "first use offers a bank-visit prompt")
equal(bank.status.text, "Saved bank · Not recorded · View only", "first-use status does not invent a record")
equal(bank:GetSnapshot(2), nil, "absent account bank cannot fall back to character bank")
equal(#bank.pageTabs, 1, "unrecorded account bank has no invented side tab")
equal(bank.frame.point[1], "TOPLEFT", "unvisited snapshot uses native top-left instead of centering")
Near(bank.frame.point[4], 16, "unvisited snapshot uses native panel horizontal offset")
Near(bank.frame.point[5], -116, "unvisited snapshot uses native panel top offset")
equal(bank.frame.scale, 1, "unvisited snapshot uses native default scale")
bank.frame.CloseButton.OnClick(); equal(bank.frame:IsShown(), false, "native close control closes only viewer")
BankFrame:Show(); Fire("BANKFRAME_OPENED"); Flush()
local personal = bank:GetSnapshot(0)
local account = bank:GetSnapshot(2)
equal(personal.totalSlots, 98, "records total slots including empties and all bags")
equal(personal.tabs[1].slots[1].link, bags[6][1].hyperlink, "full enchanted instance link retained")
equal(personal.tabs[1].slots[2], nil, "empty native slots remain empty")
equal(personal.tabs[2].slots[1].count, 5, "same item in another bag retains its own stack")
equal(personal.tabs[2].name, "Big bag", "bag name recorded")
equal(account.totalSlots, 90, "account bank recorded separately")
equal(Suite.db.inventory.characters[identity].bankViewLayout.scale, 1.25, "native layout saved separately from item snapshot")
equal(Suite.db.inventory.characters[identity].bank.items[100], 8, "completed bank view also refreshes shared inventory tooltip counts")
equal(Suite.db.inventory.accountBanks[110].items[400], 4, "shared bank quantities use the existing deduplicated inventory cache")
equal(TimerCount(), 0, "no idle polling after capture")
bank.bindingButton:Click(); equal(BankFrame:IsShown(), false, "key at banker delegates closing to native panel")
equal(bank.frame:IsShown(), false, "closing live bank does not also open cached bank")
local oldCalls = calls
accessible[0], accessible[2] = false, false
bank.bindingButton:Click()
equal(calls, oldCalls, "offline opening never reads bank containers")
equal(bank.buttons[1].bankItem.link, personal.tabs[1].slots[1].link, "offline button uses saved instance")
equal(bank.buttons[2].bankItem, nil, "saved empty slot clears previous item")
equal(bank.buttons[29].bankItem.count, 5, "page combines bank bags in native order")
equal(bank.buttons[1].normal.atlas, "bank-frame-bag-slotframe", "occupied slot has native Forever art")
equal(bank.buttons[1].template, "WoWForeverSuiteBankSlotTemplate", "slot normal artwork uses native XML override instead of intrinsic padded texture")
equal(bank.buttons[2].normal.atlas, "bank-frame-item-slotframe", "empty slot has native Forever art")
equal(bank.buttons[1].Background.atlas, "bags-item-bankslot64", "personal slots use native character-bank background")
equal(bank.frame.height, 695, "native 88-slot page height")
Near(bank.frame.point[4], 120, "recorded snapshot inherits visible bank horizontal position at non-default UI scale")
equal(bank.frame.scale, 1.25, "recorded snapshot inherits visible native bank scale")
Near(bank.frame.point[5], -204, "larger saved bank page preserves the native top edge")
equal(#bank.pageTabs, 4, "separate personal and shared page selectors")
bank.buttons[1].OnEnter()
equal(GameTooltip.link, personal.tabs[1].slots[1].link, "tooltip uses saved full link without SetBagItem")
equal(GameTooltip.owner, bank.buttons[1], "normal native tooltip owner")
keyMode = "COMPAREITEMS"; Fire("MODIFIER_STATE_CHANGED")
equal(comparisons, 1, "modifier event refreshes native equipment comparison")
bank.buttons[1].mouseOver = true; bank:Refresh()
equal(GameTooltip:IsShown(), true, "data refresh restores the tooltip for the same hovered item")
bank.buttons[1].mouseOver = false
keyMode = nil; bank.buttons[1]:Click("LeftButton"); bank.buttons[1]:Click("RightButton")
equal(#modified, 0, "ordinary clicks have no item action")
equal(bank.buttons[1].OnDragStart, nil, "cached items cannot drag")
equal(bank.buttons[1].OnReceiveDrag, nil, "cached slots cannot receive items")
keyMode = "CHATLINK"; bank.buttons[1]:Click()
equal(modified[1], personal.tabs[1].slots[1].link, "shift-click links saved item")
keyMode = "DRESSUP"; bank.buttons[1]:Click()
equal(#modified, 2, "dress-up modified click supported")
keyMode = "SPLITSTACK"; bank.buttons[1]:Click()
equal(#modified, 2, "split stack does not reach modified item actions")
keyMode = nil
bank.pageTabs[2].customMouseUpHandler(bank.pageTabs[2], "LeftButton", true)
equal(bank.page, 2, "native side tab changes personal bank page")
equal(bank.buttons[10].bankItem.id, 300, "last partial page retains final bank slot")
equal(bank.buttons[11]:IsShown(), false, "buttons beyond partial page hidden")
Near(bank.frame.point[5], -204, "short final page does not shift the native top edge")
equal(bank.buttons[1].bankItem, nil, "page switch cannot reuse prior item tooltip")
equal(GameTooltip:IsShown(), false, "page change dismisses prior hover")
bank.pageTabs[4].customMouseUpHandler(bank.pageTabs[4], "LeftButton", true)
equal(bank.bankType, 2, "shared-bank page selected")
equal(bank.buttons[2].bankItem.id, 400, "shared-bank page uses its own slots")
equal(bank.buttons[2].Background.atlas, "warband-bank-slot", "account slots retain their native bank background")
bank.search:SetText("400"); bank.search.OnTextChanged(bank.search)
equal(bank.buttons[2].searchOverlay:IsShown(), false, "literal search keeps matching item visible")
equal(bank.buttons[1].searchOverlay:IsShown(), true, "search dims nonmatching empty slots")
bank.search:SetText("100%"); bank.search.OnTextChanged(bank.search)
equal(bank.buttons[2].searchOverlay:IsShown(), true, "search uses literal text without Lua patterns")
bank.search:SetText(""); bank.search.OnTextChanged(bank.search)
equal(calls, oldCalls, "offline paging searching and tooltips never query live bank")
equal(bank.frame.OnUpdate, nil, "viewer has no idle updater")
equal(bank.buttons[2].OnUpdate, nil, "hover comparison is event driven")

-- Account pages require their own nonempty capacity record; personal data never supplies them.
local storedAccount = Suite.db.inventory.accountBankViews[110]
Suite.db.inventory.accountBankViews[110] = nil
bank:Refresh()
equal(bank:GetSnapshot(2), nil, "personal snapshot is not reused when shared-bank record is absent")
equal(bank.bankType, 0, "missing shared bank selection falls back to actual personal bank")
equal(bank.pageTabs[3]:IsShown(), false, "previously rendered shared-bank tab is removed")
equal(bank.buttons[1].bankItem.id, 100, "fallback selection retains correctly labeled personal items")
Suite.db.inventory.accountBankViews[110] = { schema = 1, tabs = {}, totalSlots = 0, at = time }
bank:Refresh()
equal(bank.pageTabs[3]:IsShown(), false, "zero purchased account slots cannot invent an account page")
Suite.db.inventory.accountBankViews[110] = storedAccount
bank:Refresh()
equal(bank.pageTabs[3]:IsShown(), true, "genuine shared-bank record restores its own pages")

-- Capture the displayed bank before closing; hidden/reflowed native geometry must not replace it.
BankFrame:Show(); Fire("BANKFRAME_OPENED"); Flush()
BankFrame.rect = { 200, 160, 480, 460 }
local layoutCharacter = Suite.db.inventory.characters[identity]
bank:CaptureLayout(layoutCharacter)
local displayedLayout = layoutCharacter.bankViewLayout
BankFrame:Hide(); BankFrame.rect = { 16, 100, 480, 460 }; Fire("BANKFRAME_CLOSED")
equal(layoutCharacter.bankViewLayout, displayedLayout, "closing bank preserves its last visible layout")
bank:CaptureLayout(layoutCharacter)
equal(layoutCharacter.bankViewLayout, displayedLayout, "hidden bank anchors cannot overwrite its displayed layout")
bank:PlaceView()
Near(bank.frame.point[4], 200, "snapshot follows displayed bank instead of hidden default horizontal position")
Near(bank.frame.point[5], -244, "snapshot follows displayed bank instead of hidden default top edge")
Near(bank.frame.point[4] * bank.frame:GetEffectiveScale(), 200,
    "snapshot left edge matches displayed bank in physical pixels at non-default UI/bank scales")
Near(UIParent:GetHeight() * UIParent:GetEffectiveScale() + bank.frame.point[5] * bank.frame:GetEffectiveScale(), 620,
    "snapshot top edge matches displayed bank in physical pixels across different page heights")
local liveRect = BankFrame.GetRect
BankFrame.GetRect = function() return nil end
bank:PlaceView()
Near(bank.frame.point[4], 200, "saved last-visible layout works before native frame is laid out")
local storedLayout = layoutCharacter.bankViewLayout
layoutCharacter.bankViewLayout = { x = { secret = true }, y = 0.5, scale = 1 }
bank:PlaceView()
equal(bank.frame.point[4], 16, "restricted saved geometry uses native panel fallback")
equal(bank.frame.point[5], -116, "first unlaid-out bank uses native default top offset")
layoutCharacter.bankViewLayout = storedLayout
BankFrame.GetRect = liveRect
Suite.db.windowTools = true
Suite.db.windowPositions.BankFrame = { x = 0, y = 0, scale = 1 }
bank:PlaceView()
Near(bank.frame.point[4], 200, "last displayed bank geometry takes precedence over generic saved center")
layoutCharacter.bankViewLayout = nil
bank:PlaceView()
Near(bank.frame.point[4], 720, "saved native mover position works before bank is shown")
Near(bank.frame.point[5], -310, "saved native mover center is converted to its top edge")
local mover = { frame = bank.frame }
Suite.Windows.tracked = { WoWForeverSuiteBankView = mover }
Suite.db.windowPositions.WoWForeverSuiteBankView = { x = 0.1, y = 0.1, scale = 0.8 }
local ownPoint = bank.frame.point
bank:PlaceView()
equal(bank.frame.point, ownPoint, "intentional snapshot placement is preserved")
Near(mover.originalPoints[1][4], 720, "snapshot reset target follows saved native bank position")
equal(mover.originalScale, 1, "snapshot reset target follows saved native bank scale")
Suite.db.windowPositions.WoWForeverSuiteBankView = nil
mover.dragging = true; BankFrame.rect = { 300, 160, 480, 460 }
bank:PlaceView()
equal(bank.frame.point, ownPoint, "default placement never interrupts an active snapshot drag")
mover.dragging = nil; Suite.db.windowPositions.BankFrame = nil
BankFrame:Show(); Fire("BANKFRAME_OPENED"); Flush(); BankFrame:SetPoint("TOPLEFT", 300, -244)
local movedLayout = layoutCharacter.bankViewLayout
BankFrame:Hide(); BankFrame.rect = { 16, 100, 480, 460 }; Fire("BANKFRAME_CLOSED")
bank:PlaceView()
Near(bank.frame.point[4], 300, "reset restores current bank position")
equal(layoutCharacter.bankViewLayout, movedLayout, "movement immediately before close is retained without a data timer")
Near(movedLayout.x, 300 * 1.25 / 1920, "visible native anchor changes record the final horizontal position")
BankFrame:SetPoint("TOPLEFT", 16, -116)
equal(layoutCharacter.bankViewLayout, movedLayout, "hidden native anchor hooks leave last shown geometry intact")
Suite.Windows.tracked = nil; Suite.db.windowTools = false
BankFrame.rect = { 120, 200, 480, 460 }

-- Incomplete/restricted records never replace a complete snapshot or serialize hidden data.
accessible[0], accessible[2] = true, true
BankFrame:Show(); Fire("BANKFRAME_OPENED"); Flush()
personal = bank:GetSnapshot(0)
equal(bank.frame:IsShown(), false, "real banker automatically dismisses cached view")
bags[6].pending = { [2] = 999 }
Fire("PLAYERBANKSLOTS_CHANGED"); Flush()
equal(bank:GetSnapshot(0), personal, "loading occupied slot retains prior complete snapshot")
equal(requests[999], 1, "missing item data requested once")
Fire("PLAYERBANKSLOTS_CHANGED"); Flush(); equal(requests[999], 1, "event retries cannot duplicate pending request")
Fire("ITEM_DATA_LOAD_RESULT", 999, false); Flush()
equal(requests[999], 1, "failed data loads do not create a recurring request loop")
equal(TimerCount(), 0, "failed item data has no idle retry timer")
bags[6].pending = nil; bags[6][2] = Item(999, 1); time = 200
Fire("ITEM_DATA_LOAD_RESULT", 999, true); Flush()
personal = bank:GetSnapshot(0)
equal(personal.tabs[1].slots[2].id, 999, "data-completion event finishes snapshot")
equal(personal.at, 200, "snapshot time updates only on successful capture")
local original = bags[6][1]
for _, bad in ipairs({ { secret = true }, Item(100, 0), Item(100, math.huge), Item(100, 1.5),
    { itemID = { secret = true }, stackCount = 1 }, { itemID = 100, stackCount = { secret = true } } }) do
    bags[6][1] = bad; Fire("PLAYERBANKSLOTS_CHANGED"); Flush()
    equal(bank:GetSnapshot(0), personal, "invalid required item data preserves complete bank")
end
bags[6][1] = Item(100, 3); bags[6][1].hyperlink = { secret = true }
Fire("PLAYERBANKSLOTS_CHANGED"); Flush()
equal(bank:GetSnapshot(0), personal, "secret link never enters saved snapshot")
equal(requests[100], nil, "restricted link does not trigger attempts to recover it")
bags[6][1] = original
sizes[7] = 0; Fire("BANK_TABS_CHANGED"); Flush()
equal(bank:GetSnapshot(0), personal, "unloaded purchased bank cannot erase snapshot")
sizes[7] = 70
ids[0] = { 6, 6 }; Fire("BANK_TABS_CHANGED"); Flush()
equal(bank:GetSnapshot(0), personal, "duplicate purchased bag IDs reject capture")
ids[0] = { 6, 7 }; purchased[0] = 3; Fire("BANK_TABS_CHANGED"); Flush()
equal(bank:GetSnapshot(0), personal, "partial purchased-tab list rejected")
purchased[0] = 2
metadata[0][2].ID = 8; Fire("BANK_TABS_CHANGED"); Flush()
equal(bank:GetSnapshot(0), personal, "metadata must describe every purchased bag")
metadata[0][2].ID = 7
for _ = 1, 500 do Fire("PLAYERBANKSLOTS_CHANGED") end
equal(TimerCount(), 1, "bank event bursts share one worker")
accessible[0], accessible[2] = false, false; BankFrame:Hide(); Fire("BANKFRAME_CLOSED"); sizes[6], sizes[7] = 0, 0
Flush(); equal(bank:GetSnapshot(0), personal, "leaving bank does not clear complete snapshot")
equal(TimerCount(), 0, "close cancels pending capture")
sizes[6], sizes[7] = 28, 70
local saved = Suite.Copy(Suite.db)
Suite.db = Suite.InitializeDB(saved)
equal(bank:GetSnapshot(0).tabs[1].slots[1].link, original.hyperlink, "full links survive saved-table reinitialization")
identity = "Player-110-second"
equal(bank:GetSnapshot(0), nil, "new character has no invented personal bank")
equal(bank:GetSnapshot(2).tabs[1].slots[90].id, 400, "account snapshot shared once in the same region")
region = 111
equal(bank:GetSnapshot(2), nil, "shared bank cache is region scoped")
region, identity = 110, "Player-110-first"
local record = bank:GetSnapshot(0)
record.tabs[1].slots[1].link = { secret = true }
equal(bank:GetSnapshot(0), nil, "replayed malformed saved links cannot reach tooltip")
record.tabs[1].slots[1].link = original.hyperlink

bank:Toggle(); equal(bank.frame:IsShown(), true, "viewer opens again after persistence checks")
local beforeCombat = created
SetCombat(true); local combatPoint = bank.frame.point; bank:PlaceView(); bank:Refresh()
equal(bank.frame.point, combatPoint, "bank placement never changes anchors during combat")
equal(created, beforeCombat, "combat refresh creates no UI")
equal(type(Suite.pending.bankViewRefresh), "function", "combat layout deferred")
bank:Toggle(); equal(type(Suite.pending.bankViewToggle), "function", "combat key press defers toggle")
bank:Toggle(); equal(Suite.pending.bankViewToggle, nil, "second combat press cancels deferred toggle")
bank:Toggle(); Suite.db.offlineBank = false; bank:Apply()
equal(Suite.pending.bankViewToggle, nil, "disable cancels deferred key action")
equal(Suite.pending.bankViewRefresh, nil, "disable cancels deferred rendering")
equal(next(bank.events.registered), nil, "disable removes recording and modifier events")
equal(bank.frame:IsShown(), false, "disable hides viewer during combat without layout changes")
equal(created, beforeCombat, "disable creates no protected or unprotected frames in combat")
SetCombat(false)
local pending = Suite.pending; Suite.pending = {}; for _, callback in pairs(pending) do callback() end
local afterDisable = calls; Fire("BAG_UPDATE_DELAYED"); Flush()
equal(calls, afterDisable, "disabled retained callbacks do no scans")
equal(bank:GetSnapshot(0).tabs[1].slots[1].id, 100, "disable retains saved bank data")
Suite.db.offlineBank = true; SetCombat(true); bank.active = nil; bank:Apply()
equal(bank.active, nil, "first enable waits for combat end")
SetCombat(false); pending = Suite.pending; Suite.pending = {}; for _, callback in pairs(pending) do callback() end
equal(bank.active, true, "deferred enable installs recording after combat")
BankFrame:Show(); Fire("BANKFRAME_OPENED"); Flush()
local readableLayout = Suite.db.inventory.characters[identity].bankViewLayout
local normalRect = BankFrame.GetRect
BankFrame.GetRect = function() return { secret = true }, 100, 480, 460 end
BankFrame:SetPoint("TOPLEFT", 16, -116)
equal(Suite.db.inventory.characters[identity].bankViewLayout, readableLayout,
    "restricted native anchor geometry cannot replace last readable visible layout")
BankFrame.GetRect = normalRect
Suite.db.offlineBank = false; bank:Apply(); BankFrame:SetPoint("TOPLEFT", 16, -116)
equal(Suite.db.inventory.characters[identity].bankViewLayout, readableLayout,
    "retained layout hooks do no recording when snapshots are disabled")
Suite.db.offlineBank = true; bank:Apply()
accessible[0], accessible[2] = true, true; BankFrame:Show(); Fire("BANKFRAME_OPENED"); Flush()
bags[6][1].stackCount = 7; Fire("PLAYERBANKSLOTS_CHANGED"); Fire("PLAYER_LOGOUT")
equal(bank:GetSnapshot(0).tabs[1].slots[1].count, 7, "logout flushes complete bank data before save")
equal(TimerCount(), 0, "logout cancels queued work")

-- Hub browsing selects an actual recorded owner without enabling recording or touching a live bank.
BankFrame:Hide(); bank:Cancel()
local originalSnapshot = bank:GetSnapshot(0)
local altSnapshot = Suite.Copy(originalSnapshot)
altSnapshot.tabs[1].slots[1].count = 19
Suite.db.inventory.characters["Player-alt"] = { name = "Alt", fullName = "Alt Pine", realm = "Beta", region = 110, bankView = altSnapshot }
Suite.db.inventory.characters["Player-remote"] = { name = "Remote", realm = "Beta", region = 111, bankView = altSnapshot }
Suite.db.offlineBank = false; bank:Apply()
local readCalls = calls
equal(bank:OpenFor("Player-alt", 0), true, "hub opens an alt's saved bank with recording disabled")
equal(bank.viewGUID, "Player-alt", "slot viewer retains the explicit recorded owner")
equal(bank.buttons[1].bankItem.count, 19, "selected owner supplies the actual displayed slot contents")
equal(bank.frame.title, "Alt Pine · Saved bank", "slot view identifies the selected character")
equal(originalSnapshot.tabs[1].slots[1].count, 7, "browsing an alt never overwrites the current character's snapshot")
equal(calls, readCalls, "opening recorded data makes no live bank scans")
equal(Suite.db.offlineBank, false, "read-only browsing does not enable recording")
equal(bank:OpenFor("Player-remote", 0), false, "other-region snapshots cannot be opened")
equal(bank:OpenFor({ secret = true }, 0), false, "restricted owner IDs never reach a saved-data key")
equal(bank:GetSnapshot(0, "missing"), nil, "missing owner cannot fall back to the current character")
equal(bank:GetSnapshot(0, { secret = true }), nil, "direct snapshot lookup rejects a restricted owner")
BankFrame:Show()
equal(bank:OpenFor("Player-alt", 0), false, "hub cannot interrupt an open live bank")
equal(BankFrame:IsShown(), true, "failed saved-view request leaves the live bank open")
BankFrame:Hide(); SetCombat(true)
equal(bank:OpenFor("Player-alt", 0), false, "saved-view owner changes are unavailable in combat")
SetCombat(false)
bank.frame:Hide()
equal(bank.viewGUID, nil, "closing clears the recorded-owner override")
equal(bank:GetSnapshot(0), originalSnapshot, "ordinary bank commands return to the current character")

bank:Cancel(); bank:HideTooltip()
for _, name in ipairs(names) do _G[name] = old[name] end
Suite.db, Suite.pending, Suite.Print, Suite.Windows, Suite.Items = oldDB, oldPending, oldPrint, oldWindows, oldItems
bank.frame, bank.events, bank.bindingButton, bank.active, bank.bankOpen = nil, nil, nil, nil, nil
bank.layoutFrame = oldLayoutFrame
