local Suite, equal, Frame, Combat = ...
local browser, dashboard, search, gui = Suite.CharacterBrowser, Suite.CharacterDashboard, Suite.InventorySearch, Suite.GUI
local function CopyFields(value) local copy = {}; for k, v in pairs(value) do copy[k] = v end; return copy end
local function Restore(target, saved) for k in pairs(target) do target[k] = nil end; for k, v in pairs(saved) do target[k] = v end end
local oldBrowser, oldDashboard, oldSearch = CopyFields(browser), CopyFields(dashboard), CopyFields(search)
local oldDB, oldPending, oldPanel, oldPage, oldShown = Suite.db, Suite.pending, gui.characterPanel, gui.page, gui.frame:IsShown()
local keys = { "CreateFrame", "C_Timer", "C_Item", "C_Container", "C_Bank", "GetCurrentRegion", "GetServerTime", "UnitGUID", "date", "GameTooltip", "IsModifiedClick", "HandleModifiedItemClick", "IsShiftKeyDown", "C_EventUtils" }
local globals = {}; for _, key in ipairs(keys) do globals[key] = _G[key] end
local timers, requests, linked, now, created = {}, {}, {}, 1000000, 0
local function Widget(name, parent)
    local widget = Frame(name); widget.parent = parent
    widget.IsForbidden, widget.IsProtected = function() return false end, function() return false end
    widget.SetText = function(self, text)
        local changed = self.text ~= text; self.text = text
        if changed and self.OnTextChanged then self.OnTextChanged(self, false) end
    end
    widget.Hide = function(self) local changed = self.shown; self.shown = false; if changed and self.OnHide then self.OnHide(self) end end
    widget.Show = function(self) self.shown = true end
    widget.SetShown = function(self, value) if value then self:Show() else self:Hide() end end
    widget.registered = {}
    widget.RegisterEvent = function(self, event) self.registered[event] = true end
    widget.UnregisterAllEvents = function(self) self.registered = {} end
    for _, method in ipairs({ "SetPoint", "ClearAllPoints", "SetSize", "SetHeight", "SetWidth" }) do
        local original = widget[method]
        widget[method] = function(self, ...) assert(not InCombatLockdown(), "inventory browser geometry must defer combat"); return original(self, ...) end
    end
    return widget
end
CreateFrame = function(_, name, parent) assert(not InCombatLockdown(), "inventory browser construction must defer combat"); created = created + 1; return Widget(name, parent) end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }; timers[#timers + 1] = timer; return timer
end }
local function Flush() local pending = timers; timers = {}; for _, timer in ipairs(pending) do if not timer.cancelled then timer.callback() end end end
local function Pending() local n = 0; for _, timer in ipairs(timers) do if not timer.cancelled then n = n + 1 end end; return n end
local function Forbidden() error("Recorded inventory browsing attempted a live inventory/bank action") end
C_Container, C_Bank = { GetContainerItemInfo = Forbidden, UseContainerItem = Forbidden, PickupContainerItem = Forbidden }, { CanViewBank = Forbidden, FetchPurchasedBankTabIDs = Forbidden }
GetCurrentRegion = function() return 110 end; GetServerTime = function() return now end; UnitGUID = function() return "main" end
C_EventUtils = { IsEventValid = function() return true end }
date = function(_, at) return "Time " .. at end
local names = { [100] = "Copper Ore", [200] = "Linen Cloth", [300] = "Healing Potion", [400] = "Silver Ore" }
C_Item = { GetItemInfo = function(id)
    if names[id] then return names[id], "|cff1eff00|Hitem:" .. id .. ":0|h[" .. names[id] .. "]|h|r", 2, 10, 1, "Trade Goods", "Metal", 20, "", 10000 + id end
end, RequestLoadItemDataByID = function(id) requests[id] = (requests[id] or 0) + 1 end }
GameTooltip = Widget(); GameTooltip.SetOwner = function(self, owner) self.owner = owner; self.lines = {} end
GameTooltip.GetOwner = function(self) return self.owner end
GameTooltip.SetHyperlink = function(self, link) self.link = link; self.lines = {} end
local modified = false
IsModifiedClick = function() return modified end
HandleModifiedItemClick = function(link) linked[#linked + 1] = link end
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
local chars = Suite.db.inventory.characters
chars.main = { name = "Main", fullName = "Main Oak", realm = "Realm", region = 110, class = "MAGE",
    profile = { level = 30, money = 10000, professions = {} }, bags = { at = now - 60, items = { [100] = 2, [200] = 1 } },
    bank = { at = now - 180000, items = { [100] = 3 } } }
chars.alt = { name = "Alt", fullName = "Alt Pine", realm = "Realm", region = 110, class = "WARRIOR",
    profile = { level = 25, money = 20000, professions = {} }, bags = { at = now - 120, items = { [100] = 7, [300] = 2 } } }
chars.empty = { name = "Empty", realm = "Realm", region = 110, bags = { at = now - 80, items = {} } }
chars.remote = { name = "Remote", realm = "Realm", region = 1, bags = { at = now, items = { [100] = 999 } } }
chars.hidden = { secret = true }
Suite.db.inventory.accountBanks[110] = { at = now - 86400, items = { [100] = 5, [400] = 4 } }
search.index, search.metadata, search.requested, search.region, search.currentGUID = nil, {}, {}, nil, nil
browser.panel, browser.visible, browser.timer, browser.owner, browser.query, browser.location, browser.page = nil, false, nil, nil, "", "all", 1
dashboard.panel, dashboard.rosterPanel, dashboard.view = nil, nil, "characters"
dashboard.query, dashboard.sort, dashboard.page, dashboard.selected = "", "name", 1, nil
gui.characterPanel = nil
local function Total(rows) local count = 0; for _, row in ipairs(rows) do count = count + (row.bags or 0) + (row.bank or 0) + (row.account or 0) end; return count end
equal(#search:Query(""), 0, "native ownership popup keeps its empty-query behavior")
local rows = search:Query("", { browse = true })
equal(#rows, 6, "standalone browsing includes all recorded item-owner rows")
equal(Total(rows), 24, "known personal and shared contents add up once")
equal(search.coverage.empty.bags.recorded, true, "a captured empty bag remains known empty")
equal(search.coverage.empty.bank.recorded, false, "an unvisited bank remains unknown")
equal(search.coverage.remote, nil, "other-region characters do not enter coverage totals")
equal(Total(search:Query("", { browse = true, owner = "main" })), 6, "selected-owner browsing excludes other owners and shared-bank duplication")
equal(Total(search:Query("", { browse = true, owner = "main", location = "bags" })), 3, "bag filter omits bank quantities from each result")
equal(Total(search:Query("", { browse = true, owner = "main", location = "bank" })), 3, "bank filter omits bag quantities from each result")
equal(Total(search:Query("", { browse = true, owner = "main", location = "account" })), 9, "explicit shared-bank filter is independent of a retained personal selection")
equal(#search:Query("", { browse = true, owner = "alt", location = "bank" }), 0, "unknown bank cannot invent any items")
equal(#search:Query("metal", { browse = true }), 6, "item-type search reuses native metadata words")
equal(#search:Query("100", { browse = true }), 3, "numeric item search finds owners without combining them")
equal(#search:Query("Copper Ore", { browse = true }), 3, "multiple words find matching items across owners")
equal(#search:Query("Copper missing", { browse = true }), 0, "all search tokens must match")
local hidden = setmetatable({ secret = true }, { __index = function() error("hidden browser data indexed") end })
equal(#search:Query("", hidden), 0, "restricted query options cannot be inspected")
equal(#search:Query("", { browse = true, owner = hidden }), 0, "restricted owner never becomes an index key")
equal(#search:Query("", { browse = true, location = hidden }), 0, "restricted location never becomes a filter key")
equal(#search:Query(hidden, { browse = true }), 0, "restricted search text cannot enter string matching")
equal(#search:Query("\n", { browse = true }), 0, "control characters are rejected")
equal(browser:Age(nil, false), "Not recorded", "missing capture is distinct from unknown capture time")
equal(browser:Age(nil, true), "Date unavailable", "an undated capture is not labeled fresh")
equal(browser:Age(now + 1), "Date unavailable", "future timestamps do not become negative ages")
local age, stale = browser:Age(now - 86400)
equal(age, "1d ago", "old snapshots have a visible relative age")
equal(stale, true, "old snapshots receive a distinct muted amber state")

gui.frame:Show(); browser:Open("alt")
equal(gui.page, "characters", "inventory browser lives in the existing character hub")
equal(dashboard.view, "inventory", "explicit browse navigation opens the Inventory tab")
equal(browser.ownerButton.label:GetText(), "Alt Pine", "selected character scope is visible beside location")
equal(browser.locationButton.label:GetText(), "All locations", "location filter starts explicitly unfiltered")
equal(browser.coverage:GetText():find("Bank: Not recorded", 1, true) ~= nil, true, "unrecorded bank is disclosed in the browsing header")
equal(browser.summary:GetText(), "2 results · 9 items recorded", "result summary follows the selected owner")
equal(browser.panel:GetParent(), dashboard.panel, "inventory and roster share one owned hub")
equal(dashboard.rosterPanel:IsShown(), false, "inventory tab hides roster input")
equal(browser.panel.registered.ITEM_DATA_LOAD_RESULT, true, "visible inventory listens for item metadata completion")
equal(Suite.db.characterDashboard, false, "browsing does not enable recording")
equal(Suite.db.inventorySearch, false, "browsing does not enable native popup search")
equal(Suite.db.itemInventory, false, "browsing does not enable tooltip counts")
equal(Suite.db.offlineBank, false, "browsing does not enable bank recording")
equal(browser.bankButton.enabled, false, "no slot snapshot produces a disabled bank action")
local popupOwner, popupRows = search.owner, search.rows
browser:Tooltip(browser.buttons[1])
equal(GameTooltip.owner, browser.buttons[1], "item tooltip uses the owned browser row")
equal(GameTooltip.link:find("item:", 1, true) ~= nil, true, "normal item hyperlinks remain available")
equal(search.owner, popupOwner, "browser tooltip does not seize a native search owner")
equal(search.rows, popupRows, "browser does not replace a native popup result list")
modified = true; browser.buttons[1].OnClick(); equal(#linked, 1, "modified item clicks delegate the native link behavior")
modified = false
browser:SetLocation("bags"); browser.query = "Ore"; browser:Update()
equal(browser:SaveView(), true, "current search and filters can be saved")
equal(#browser:Options().favorites, 1, "saved search is stored once")
equal(browser:Options().favorites[1].owner, "alt", "saved view preserves its owner scope")
equal(browser:Options().favorites[1].location, "bags", "saved view preserves its location scope")
browser.owner, browser.query, browser.location = nil, "Cloth", "all"
browser:LoadView(1)
equal(browser.owner, "alt", "loading a favorite restores its character")
equal(browser.query, "Ore", "loading a favorite restores its query")
equal(browser.location, "bags", "loading a favorite restores its location")
local stored = browser:InitializeOptions(Suite.Copy(browser:Options()))
equal(stored.favorites[1].query, "Ore", "favorites survive independent saved-table validation")
equal(#browser:InitializeOptions(hidden).favorites, 0, "restricted saved favorite root resets safely")
equal(#browser:InitializeOptions({ favorites = { { query = "Ore", owner = false, location = "all" } } }).favorites, 0, "invalid favorite owner cannot silently broaden its scope")
equal(#browser:InitializeOptions({ favorites = { { query = "Ore", owner = hidden, location = "all" } } }).favorites, 0, "restricted favorite owners are rejected")
equal(#browser:InitializeOptions({ favorites = { { query = "Bad|Text", location = "all" } } }).favorites, 0, "saved chat markup cannot enter search labels")
for index = 2, 8 do browser.query = "View " .. index; browser:SaveView() end
equal(#browser:Options().favorites, 8, "saved searches have a bounded capacity")
browser.query = "Ninth view"; equal(browser:SaveView(), false, "full saved-search list refuses another entry explicitly")
equal(#browser:Options().favorites, 8, "capacity cannot overwrite an existing favorite")
browser:LoadView(1); browser:SaveView()
equal(#browser:Options().favorites, 7, "explicit removal frees a favorite slot")

browser.query, browser.owner, browser.location = "", nil, "all"; browser:Update()
local allScope = browser.owner
browser.buttons[1].OnClick()
equal(browser.owner ~= allScope, true, "ordinary result click drills into its actual owner")
browser.owner = nil; browser:SetLocation("account")
equal(browser.ownerButton.enabled, false, "shared-bank scope cannot imply a character owns another copy")
equal(browser.summary:GetText(), "2 results · 9 items recorded", "shared-only view counts shared items once")
browser:SetLocation("all"); browser.owner = "empty"; browser:Update()
equal(browser.coverage:GetText():find("Bags: 1m ago", 1, true) ~= nil, true, "known empty bag retains its capture date")
equal(browser.empty:IsShown(), true, "empty recorded scope has a readable empty state")
chars.empty.bags.items[999] = hidden; search:InventoryChanged(); Flush()
equal(browser.coverage:GetText():find("Partial record", 1, true) ~= nil, true, "invalid item rows are disclosed as partial rather than known complete")

-- Uncached metadata is requested in finite batches and never turns into idle polling.
browser.owner, browser.location, browser.query = "alt", "bags", ""
for id = 500, 534 do chars.alt.bags.items[id] = 1 end
search:InventoryChanged(); browser:Update(); Flush(); Flush()
local requested = 0; for id = 500, 534 do requested = requested + (requests[id] or 0) end
equal(requested, 35, "metadata is requested once for each relevant uncached item")
equal(Pending(), 0, "completed finite metadata batches leave no idle worker")
browser:Update(); Flush()
equal(requests[500], 1, "failed or unanswered metadata is not requested repeatedly")
names[500] = "Loaded Herb"; browser:OnEvent("ITEM_DATA_LOAD_RESULT", 500); Flush()
local found = false; for _, row in ipairs(browser.rows) do if row.id == 500 and row.name == "Loaded Herb" then found = true end end
equal(found, true, "native metadata completion refreshes the visible row")
equal(browser.next:IsShown(), true, "larger inventories have explicit paging")
for index = 1, 20 do browser.next.OnClick() end
equal(browser.page, math.ceil(#browser.rows / 8), "inventory paging clamps to its final page")
browser.page = 1; browser.expanded = true; browser:Update()
equal(gui.contentHeight >= gui.controlsOffset + dashboard.panel:GetHeight() + 36, true, "all filters, favorites, rows and footer fit the scroll range")
for _, row in ipairs(browser.buttons) do
    local _, x, y = row:GetPoint()
    equal(x == 0 and row:GetWidth() == 780, true, "item row width matches the hub content")
    equal(-y + row:GetHeight() < browser.panel:GetHeight(), true, "item rows remain above the bank action and notice")
end
gui:ScrollTo(0)
IsShiftKeyDown = function() return false end
browser.panel.OnMouseWheel(browser.panel, -1)
equal(gui.scrollOffset, 40, "ordinary wheel scrolls the settings viewport so footer controls remain reachable")
IsShiftKeyDown = function() return true end
local scrollOffset = gui.scrollOffset
browser.panel.OnMouseWheel(browser.panel, -1)
equal(browser.page, 2, "Shift-wheel pages through recorded results")
equal(gui.scrollOffset, scrollOffset, "result paging preserves the viewport position")
browser.panel.OnMouseWheel(browser.panel, hidden)
equal(browser.page, 2, "restricted wheel input never enters arithmetic")
IsShiftKeyDown = function() return false end
local oldHeight, oldCreated = browser.panel:GetHeight(), created
browser:Schedule(); Combat(true); browser:OnEvent("PLAYER_REGEN_DISABLED")
equal(Pending(), 0, "combat entry cancels pending metadata work")
browser:Schedule(); browser:Refresh(); browser:SetLocation("bank"); browser:SaveView()
equal(browser.panel:GetHeight(), oldHeight, "combat cannot resize the browser")
equal(created, oldCreated, "combat cannot create browser widgets")
equal(type(Suite.pending.inventoryBrowserView), "function", "combat refresh retains one guarded request")
browser:SetVisible(false)
equal(Suite.pending.inventoryBrowserView, nil, "hiding cancels delayed browser work")
equal(next(browser.panel.registered), nil, "hidden browser leaves no feature event registrations")
Combat(false)
dashboard:SetView("characters")
equal(dashboard.rosterPanel:IsShown(), true, "returning to Characters restores the original roster")
dashboard.search:SetText("Alt"); dashboard.search.OnTextChanged(dashboard.search)
dashboard.browseButton.OnClick()
equal(browser.owner, "alt", "selected-character action opens the matching inventory")
equal(dashboard.view, "inventory", "selected-character action reaches the Inventory tab")
GetCurrentRegion = function() return hidden end; search.index = nil; browser:Update()
equal(browser.coverage:GetText(), "Character region unavailable.", "restricted region cannot retain another scope's coverage")
equal(#browser.rows, 0, "unknown region suppresses all saved item rows")
GetCurrentRegion = function() error("region unavailable") end; browser:Update()
equal(#browser.rows, 0, "rejected region API leaves no guessed matches or exception")
browser:SetVisible(false)
for _, key in ipairs(keys) do _G[key] = globals[key] end
Restore(browser, oldBrowser); Restore(dashboard, oldDashboard); Restore(search, oldSearch)
Suite.db, Suite.pending, gui.characterPanel = oldDB, oldPending, oldPanel
Combat(false); gui:Select(oldPage or "overview"); gui.frame:SetShown(oldShown)
