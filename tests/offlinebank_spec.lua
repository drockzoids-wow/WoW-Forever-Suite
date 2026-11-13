local Suite, equal, Frame, SetCombat = ...
local bank = Suite.OfflineBank
local names = { "CreateFrame", "C_Timer", "C_Container", "C_Bank", "C_Item", "Enum", "BankFrame", "UIParent",
    "UnitGUID", "UnitName", "UnitClass", "GetNormalizedRealmName", "GetCurrentRegion", "GetServerTime", "date",
    "SetItemButtonTexture", "SetItemButtonCount", "GameTooltip", "GameTooltip_ShowCompareItem", "IsModifiedClick",
    "HandleModifiedItemClick", "HideUIPanel", "UISpecialFrames", "WoWForeverSuiteBankView", "WoWForeverSuiteBankToggleButton",
    "BagItemSearchBox", "BankItemSearchBox", "BagSearch_OnTextChanged", "GetInventoryItemID" }
local old = {}
for _, name in ipairs(names) do old[name] = _G[name] end
local oldDB, oldPending, oldPrint = Suite.db, Suite.pending, Suite.Print
local oldWindows, oldItems = Suite.Windows, Suite.Items
local oldLayoutFrame = bank.layoutFrame
local oldSearchHooked = bank.searchHooked
bank.searchHooked = nil
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
    if parent and parent.children then parent.children[#parent.children + 1] = frame end
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
bank.buttons[1]:OnMouseWheel(1)
equal(bank.page, 1, "wheel over saved slot returns to previous page")
bank.frame:OnMouseWheel(-1)
equal(bank.page, 2, "wheel over saved bank background advances page")
bank.buttons[10]:OnMouseWheel(-1)
equal(bank.page, 2, "saved bank wheel clamps at last page")
SetCombat(true); bank.buttons[1]:OnMouseWheel(1); SetCombat(false)
equal(bank.page, 2, "combat blocks saved bank wheel paging")
bank.frame:OnMouseWheel({ secret = true })
equal(bank.page, 2, "restricted saved bank wheel input is ignored")
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
-- The saved view joins Blizzard's shared search, independently of the ownership popup.
local filter, filterCalls = "", 0
BagItemSearchBox, BankItemSearchBox = Widget(), Widget()
BagSearch_OnTextChanged = function(box)
    for _, other in ipairs({ BagItemSearchBox, BankItemSearchBox }) do
        if other:GetText() ~= box:GetText() then other:SetText(box:GetText()) end
    end
    filter, filterCalls = box:GetText(), filterCalls + 1
end
for _, box in ipairs({ BagItemSearchBox, BankItemSearchBox }) do
    box.SetText = function(self, text)
        if self.text == text then return end
        self.text = text; BagSearch_OnTextChanged(self)
    end
end
bank:WatchSearch()
equal(Suite.db.inventorySearch, false, "linked filtering does not require cross-character popup")
bank.search:SetText("fang"); bank.search.OnTextChanged(bank.search)
equal(BagItemSearchBox:GetText(), "fang", "saved bank search also fills live bag search")
equal(BankItemSearchBox:GetText(), "fang", "native handler still synchronizes live bank")
equal(filter, "fang", "saved bank query reaches native item dimming")
BagItemSearchBox:SetText("400")
equal(bank.search:GetText(), "400", "live bag search also updates saved bank")
bank.search.OnTextChanged(bank.search)
equal(bank.buttons[2].searchOverlay:IsShown(), false, "shared query retains matching saved item")
BagItemSearchBox:SetText("")
equal(bank.search:GetText(), "", "clearing bags clears saved bank search")
bank.search:SetText("fang"); bank.search.OnTextChanged(bank.search)
bank.search:SetText(""); bank.search.OnTextChanged(bank.search)
equal(filter, "", "clearing saved bank clears live dimming")
local beforeCombat = filterCalls
SetCombat(true)
bank.search:SetText("fang"); bank.search.OnTextChanged(bank.search)
equal(filterCalls, beforeCombat, "saved search defers native writes during combat")
equal(type(Suite.pending.bankSearchSync), "function", "combat search queues synchronization")
SetCombat(false)
Suite.pending.bankSearchSync(); Suite.pending.bankSearchSync = nil
equal(filter, "fang", "latest saved query applies after combat")
local beforeInvalid = filterCalls
bank:SyncSearch({ IsForbidden = function() return { secret = true } end, GetText = function() error("restricted read") end })
equal(filterCalls, beforeInvalid, "restricted widgets cannot enter shared search")
bank.frame:Hide(); BagItemSearchBox:SetText("400")
equal(bank.search:GetText(), "fang", "hidden saved view leaves its field alone")
bank.frame:Show(); bank.frame.OnShow(bank.frame)
equal(bank.search:GetText(), "400", "reopened saved view adopts current bag query")
bank.search:SetText(""); bank.search.OnTextChanged(bank.search)
BagItemSearchBox, BankItemSearchBox, BagSearch_OnTextChanged = nil, nil, nil
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
bags[6].pending = { [2] = 999, [3] = 998 }
Fire("PLAYERBANKSLOTS_CHANGED"); Flush()
equal(bank:GetSnapshot(0), personal, "loading occupied slot retains prior complete snapshot")
equal(requests[999], 1, "missing item data requested once")
equal(requests[998], 1, "same pass requests later missing items rather than stopping at the first")
equal(TimerCount(), 1, "incomplete bank capture schedules a bounded data retry")
bags[6].pending = nil; bags[6][2] = Item(999, 1)
Flush()
equal(bank:GetSnapshot(0).tabs[1].slots[2].id, 999, "bounded retry captures newly available data without another native event")
personal = bank:GetSnapshot(0); bags[6][2] = nil; bags[6].pending = { [2] = 999 }
Fire("PLAYERBANKSLOTS_CHANGED"); Flush(); equal(requests[999], 1, "event retries cannot duplicate pending request")
Fire("ITEM_DATA_LOAD_RESULT", 999, false); Flush()
equal(requests[999], 1, "failed data loads do not create a recurring request loop")
for _ = 1, 5 do Flush() end
equal(TimerCount(), 0, "failed item data has no idle retry timer")
Fire("BANK_TABS_CHANGED"); Flush()
equal(TimerCount(), 1, "a fresh bank event permits another bounded recovery window")
BankFrame:Hide(); Fire("BANKFRAME_CLOSED")
equal(TimerCount(), 0, "closing bank cancels its loading retry")
local beforeClosedRetry = calls; Flush()
equal(calls, beforeClosedRetry, "cancelled bank retry never reads inaccessible containers")
BankFrame:Show(); Fire("BANKFRAME_OPENED")
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
-- Purchased but unequipped bank bags must not freeze the entire saved view.
local savedBagSlot = C_Bank.BankBagTypeAndIDToInvSlot
local equippedBag, mappedSlot = nil, nil
C_Bank.BankBagTypeAndIDToInvSlot = function(kind, index)
    equal(kind, 0, "empty bag lookup uses the personal bank type")
    equal(index, 2, "empty bag lookup uses the purchased bag index")
    return 67
end
GetInventoryItemID = function(unit, slot)
    equal(unit, "player", "bank bag equipment belongs to player")
    mappedSlot = slot; return equippedBag
end
sizes[7] = 0; time = 201; Fire("BANK_TABS_CHANGED"); Flush()
local emptyBagView = bank:GetSnapshot(0)
equal(emptyBagView.at, 201, "confirmed unequipped purchased bag allows a fresh capture")
equal(emptyBagView.totalSlots, 28, "empty bank bag contributes no item slots")
equal(emptyBagView.tabs[2].size, 0, "purchased empty bag position is retained")
equal(mappedSlot, 68, "native bank bag mapping uses one-based inventory slot")
equal(Suite.db.inventory.characters[identity].bank.items[100], 3, "empty bag capture clears obsolete aggregate holdings")
equippedBag = 123; Fire("BANK_TABS_CHANGED"); Flush()
equal(bank:GetSnapshot(0), emptyBagView, "equipped zero-slot bag is still loading and preserves the snapshot")
equippedBag = { secret = true }; Fire("BANK_TABS_CHANGED"); Flush()
equal(bank:GetSnapshot(0), emptyBagView, "restricted bag equipment cannot prove an empty bank bag")
GetInventoryItemID = nil; Fire("BANK_TABS_CHANGED"); Flush()
equal(bank:GetSnapshot(0), emptyBagView, "missing equipment API cannot prove an empty bank bag")
C_Bank.BankBagTypeAndIDToInvSlot = savedBagSlot; GetInventoryItemID = old.GetInventoryItemID
sizes[7] = 70; Fire("BANK_TABS_CHANGED"); Flush(); personal = bank:GetSnapshot(0)
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
local launcher, oldGUIFrame = Frame(), Suite.GUI.frame
launcher:SetSize(500, 500); launcher:Show()
Suite.GUI.frame = launcher
equal(bank:OpenFor("Player-alt", 0, launcher), true, "saved bank accepts an explicit launching window")
equal(launcher:IsShown(), true, "saved bank keeps its launching browser visible")
equal(bank.frame.point[2], UIParent, "saved bank gets independent screen placement")
Suite.GUI.frame = oldGUIFrame
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

-- Bag selection uses the same view-only slot renderer, with independent source records.
local selectors = Suite.InventorySelectors
local oldControls, oldWatched = selectors.controls, selectors.watched
selectors.controls, selectors.watched = {}, {}
Suite.db.itemInventory, Suite.db.offlineBank = true, true
local alt = Suite.db.inventory.characters["Player-alt"]
GetNormalizedRealmName = function() return "CAMWOWUS2Realm1PvE" end
Suite.db.inventory.characters[identity].realm = "CAMWOWUS2Realm1PvE"
alt.realm = "CAMWOW US2 Realm 1 PvE"
alt.bagView = { schema = 1, at = 222, totalSlots = 2,
    tabs = { { bag = 0, size = 2, slots = { [1] = {
        id = 999, count = 4, icon = 1999, link = "item:999", name = "Alt bag item" } } } } }
local altBags = alt.bagView
for guid, realm in pairs({ ["Player-pvp"] = "CAMWOW US2 Realm 1 PvP", ["Player-hardcore"] = "Hardcore",
    ["Player-rp"] = "RP", ["Player-unknown"] = "Unrecognized" }) do
    Suite.db.inventory.characters[guid] = { name = guid, realm = realm, region = 110, bagView = altBags, bankView = altSnapshot }
end
equal(bank:GetSnapshot(0, "Player-alt", true), altBags, "bag snapshot accepts backpack ID zero")
equal(bank:GetSnapshot(0, "Player-alt"), altSnapshot, "bag data does not replace personal bank data")
local choices = selectors:Choices(true)
equal(#choices, 2, "character chooser excludes other regions")
equal(choices[1].guid, "Player-alt", "character chooser sorts readable names")
equal(choices[1].recorded, true, "bag chooser recognizes complete slot records")
equal(choices[1].label, "Alt Pine · PvE", "dropdown replaces verbose realm with canonical server type")
equal(choices[2].recorded, false, "aggregate-only records are not misrepresented as slot snapshots")
equal(#selectors:Choices(false), 2, "bank chooser shares Contact Book region and server-type scope")
equal(selectors:Select("Player-pvp", true), false, "direct bag selection cannot bypass PvE/PvP isolation")
equal(selectors:Select("Player-hardcore", false), false, "direct bank selection cannot bypass Hardcore isolation")
local pveRealm = GetNormalizedRealmName
GetNormalizedRealmName = function() return "CAMWOW US2 Realm 1 PvP" end
local pvpChoices = selectors:Choices(true)
equal(#pvpChoices, 1, "switching to PvP lists only matching inventory owners")
equal(pvpChoices[1].guid, "Player-pvp", "PvP scope selects its own character record")
equal(selectors:Select("Player-alt", true), false, "stale PvE menu callback is rejected after server-type change")
GetNormalizedRealmName = function() return "Unrecognized" end
equal(#selectors:Choices(true), 0, "unknown active server type does not reveal mixed inventories")
GetNormalizedRealmName = pveRealm
equal(selectors:Select("Player-alt", true), true, "bag dropdown opens saved alt inventory")
equal(bank.viewBags, true, "bag dropdown selects bag rendering mode")
equal(bank.buttons[1].bankItem.id, 999, "saved bags display the selected character's actual item")
equal(bank.buttons[2].bankItem, nil, "empty saved bag slot stays empty")
equal(bank.frame.title, "Alt Pine · Saved bags", "saved bag title identifies character and source")
equal(bank.status.text, "Saved bags · date 222 · View only", "saved bag footer discloses capture time and read-only status")
equal(bank.bagLabel:IsShown(), false, "saved bags do not inherit bank bag purchase decorations")
local bagCalls = calls
SetCombat(true)
equal(selectors:Select("Player-alt", true), false, "combat rejects dropdown selection")
equal(calls, bagCalls, "combat selection makes no container scans")
SetCombat(false)
equal(selectors:Select({ secret = true }, true), false, "selector rejects restricted owner keys")
equal(selectors:Select("Player-remote", true), false, "selector rejects another region")
equal(selectors:Select(identity, true), true, "current character selection returns to live bags")
equal(bank.frame:IsShown(), false, "return to live bags closes the saved view")
equal(bank.viewBags, nil, "closing bag view clears source mode")
equal(selectors:Select("Player-alt", false), true, "same dropdown can switch to saved bank")
equal(bank.buttons[1].bankItem.count, 19, "bank mode remains independent after browsing bags")
altBags.tabs[1].slots[1].icon = { secret = true }
equal(bank:GetSnapshot(0, "Player-alt", true), nil, "restricted saved bag artwork rejects incomplete view")
altBags.tabs[1].slots[1].icon = 1999
altBags.tabs[1].bag = 6
equal(bank:GetSnapshot(0, "Player-alt", true), nil, "bank container IDs cannot masquerade as carried bags")
altBags.tabs[1].bag = 0
bank.frame:Hide()

-- Native search keeps its owner and scripts; the individual backpack uses its
-- existing header space rather than moving protected item buttons.
local oldCombined, oldInput, oldMenu = ContainerFrameCombinedBags, InputUtil, MenuUtil
local combined, single, search = Widget(), Widget(), Widget()
ContainerFrameCombinedBags = combined
search.parent = combined
local nativeChanged = function() end
search:SetScript("OnTextChanged", nativeChanged)
selectors:LayoutSearch(combined, search)
equal(search:GetParent(), combined, "shortened native search retains its parent")
equal(search:GetScript("OnTextChanged"), nativeChanged, "shortened native search retains native filtering")
equal(search:GetWidth(), 145, "combined search uses requested right-side short field")
equal(search.point[1], "TOPRIGHT", "combined search occupies right side")
equal(selectors.watched[combined].point[4], 28, "combined character selector occupies left side")
search.parent = single
selectors:LayoutSearch(single, search)
equal(search:GetWidth(), 96, "individual search preserves native width")
equal(search.point[5], -28, "individual search moves above its second row")
equal(selectors.watched[single].point[5], -50, "individual character selector sits below search")
equal(selectors.watched[single]:GetHeight(), 20, "second row fits above native item grid")
local singleControl = selectors.watched[single]
equal(singleControl:GetWidth() + 4 + singleControl.reset:GetWidth(), 150, "icon reset stays within existing individual selector space")
equal(singleControl.reset.template, "RefreshButtonTemplate", "reset uses the native refresh icon")
equal(singleControl.reset.point[3], "RIGHT", "reset sits to the right of the dropdown")
local searchPoint = search.point
SetCombat(true); selectors:LayoutSearch(single, search)
equal(search.point, searchPoint, "native search geometry stays untouched in combat")
SetCombat(false)
InputUtil = { IsGamepadUIEnabled = function() return true end }
selectors:LayoutSearch(single, search)
equal(selectors.watched[single]:IsShown(), false, "gamepad retains native prompt area")
selectors:UpdateLabels()
equal(singleControl:IsShown(), false, "label refresh preserves gamepad exclusion")
equal(selectors.watched[combined]:IsShown(), false, "label refresh hides combined selector in gamepad mode")
bank:OpenBags("Player-alt")
bank:Refresh()
equal(singleControl:IsShown(), false, "saved bag refresh cannot reveal native gamepad selector")
InputUtil.IsGamepadUIEnabled = function() return { secret = true } end
selectors:UpdateLabels()
equal(singleControl:IsShown(), false, "unreadable gamepad state keeps native prompt space clear")
InputUtil.IsGamepadUIEnabled = function() error("unavailable") end
selectors:UpdateLabels()
equal(singleControl:IsShown(), false, "failed gamepad query keeps native prompt space clear")
InputUtil = nil
selectors:UpdateLabels()
equal(singleControl:IsShown(), true, "keyboard layout restores the enabled bag selector")
local menuRows = {}
MenuUtil = { CreateContextMenu = function(_, build)
    build(nil, { CreateTitle = function() end, CreateRadio = function(_, label, selected, callback)
        local row = { label = label, selected = selected, callback = callback }
        row.SetEnabled = function(self, enabled) self.enabled = enabled end
        menuRows[#menuRows + 1] = row
        return row
    end })
end }
selectors:Menu(selectors.watched[combined])
equal(#menuRows, 2, "native dropdown lists scoped saved characters")
equal(menuRows[1].enabled, true, "complete alt snapshot is selectable")
menuRows[1].callback()
equal(bank.viewGUID, "Player-alt", "native menu callback selects its own recorded GUID")
equal(bank.viewBags, true, "native bags menu callback opens saved bags")
SetCombat(true)
singleControl.reset:Click()
equal(bank.viewGUID, "Player-alt", "reset cannot switch character in combat")
SetCombat(false)
singleControl.reset:Click()
equal(bank.frame:IsShown(), false, "bag reset icon returns to live current-character bags")
bank:OpenFor("Player-alt", 0)
local savedControl = selectors:Attach(bank.frame, "saved")
savedControl.reset:Click()
equal(bank.viewGUID, identity, "saved bank reset returns to current character")
equal(bank.buttons[1].bankItem.count, 7, "saved bank reset displays current character contents")
local currentRecord = Suite.db.inventory.characters[identity]
local currentBank = currentRecord.bankView
currentRecord.bankView = nil
bank:OpenFor("Player-alt", 0)
savedControl.reset:Click()
equal(bank.viewGUID, identity, "reset can return to current character without a recorded bank")
equal(bank.buttons[1].bankItem, nil, "unrecorded current bank clears alt items on reset")
currentRecord.bankView = currentBank
local nativeControl = selectors:Attach(BankFrame, "bank")
BankFrame:Show()
nativeControl.reset:Click()
equal(BankFrame:IsShown(), true, "reset on native current bank leaves the live bank open")
BankFrame:Hide()
bank.frame:Hide()

-- Exercise the actual setting dispatcher without invoking unrelated modules.
local oldModules = Suite.modules
Suite.modules = { bank }
bank:OpenBags("Player-alt")
Suite.Set("offlineBank", true)
equal(bank.frame:IsShown(), true, "bank recording enabled preserves saved bags")
Suite.Set("offlineBank", false)
equal(bank.frame:IsShown(), true, "disabling bank recording preserves independently enabled saved bags")
equal(next(bank.events.registered), nil, "preserving saved bags still unregisters bank recording events")
Suite.Set("chatOpacity", 0.6)
equal(bank.frame:IsShown(), true, "unrelated setting preserves saved bags with bank snapshots off")
equal(bank.viewGUID, "Player-alt", "unrelated setting preserves saved bag owner")
equal(bank.viewBags, true, "unrelated setting preserves saved bag mode")
local bagPoint, bagScans = bank.frame.point, calls
SetCombat(true)
bank:Refresh()
local bagRefresh = Suite.pending.bankViewRefresh
Suite.Set("chatOpacity", 0.7)
equal(bank.frame:IsShown(), true, "combat settings refresh preserves enabled saved bags")
equal(Suite.pending.bankViewRefresh, bagRefresh, "bank disable cleanup retains pending bag rendering")
equal(bank.frame.point, bagPoint, "combat settings refresh leaves bag geometry untouched")
equal(calls, bagScans, "combat settings refresh performs no container scans")
SetCombat(false)
pending = Suite.pending; Suite.pending = {}; for _, callback in pairs(pending) do callback() end
equal(bank.frame:IsShown(), true, "saved bags remain open after deferred refresh")
equal(bank.buttons[1].bankItem.id, 999, "deferred refresh preserves selected bag contents")
Suite.Set("itemInventory", false)
equal(bank.frame:IsShown(), false, "disabling bag recording still closes the saved bag view")
Suite.Set("itemInventory", true)
Suite.Set("offlineBank", true)
bank:OpenFor("Player-alt", 0)
Suite.Set("offlineBank", false)
equal(bank.frame:IsShown(), false, "disabling bank recording still closes a saved bank view")
Suite.modules = oldModules
ContainerFrameCombinedBags, InputUtil, MenuUtil = oldCombined, oldInput, oldMenu

sizes[0], bags[0] = 2, { [1] = Item(123, 7, "321:654") }
local view = Suite.Inventory:ScanBagView({ 0 })
equal(view.totalSlots, 2, "bag capture preserves empty slot capacity")
equal(view.tabs[1].slots[1].link, bags[0][1].hyperlink, "bag capture preserves full instance links")
equal(view.tabs[1].slots[1].count, 7, "bag capture retains stack counts")
equal(view.tabs[1].slots[2], nil, "bag capture preserves empty slots")
bags[0].pending = { [2] = 777 }
equal(Suite.Inventory:ScanBagView({ 0 }), nil, "loading occupied slot cannot become false empty snapshot")
bags[0].pending = nil
bags[0][1].hyperlink = { secret = true }
equal(Suite.Inventory:ScanBagView({ 0 }), nil, "restricted bag link is not persisted")
bags[0][1].hyperlink = "item:999"
equal(Suite.Inventory:ScanBagView({ 0 }), nil, "mismatched instance link rejects partial capture")
sizes[0], bags[0] = nil, nil
selectors.controls, selectors.watched = oldControls, oldWatched

bank:Cancel(); bank:HideTooltip()
for _, name in ipairs(names) do _G[name] = old[name] end
Suite.db, Suite.pending, Suite.Print, Suite.Windows, Suite.Items = oldDB, oldPending, oldPrint, oldWindows, oldItems
bank.frame, bank.events, bank.bindingButton, bank.active, bank.bankOpen = nil, nil, nil, nil, nil
bank.layoutFrame = oldLayoutFrame
bank.searchHooked = oldSearchHooked
