local Suite, equal, Frame, SetCombat = ...
local dashboard, gui = Suite.CharacterDashboard, Suite.GUI
local old, globals = {}, { "CreateFrame", "C_Timer", "C_EventUtils", "GetCurrentRegion", "UnitGUID", "UnitName", "UnitClass",
    "GetNormalizedRealmName", "GetServerTime", "UnitLevel", "GetMoney", "GetProfessions", "GetProfessionInfo", "C_GameRules", "date", "GameTooltip" }
for _, key in ipairs(globals) do old[key] = _G[key] end
local saved = {}; for key, value in pairs(dashboard) do saved[key] = value end
local oldDB, oldPending, oldPage, oldPanel = Suite.db, Suite.pending, gui.page, gui.characterPanel
local timers, created, now, money, level = {}, 0, 1000, 123456, 36
local function Widget(name, parent)
    local frame = Frame(name); frame.parent = parent
    frame.IsForbidden = function() return false end; frame.IsProtected = function() return false end
    frame.SetText = function(self, text)
        local changed = self.text ~= text; self.text = text
        if changed and self.OnTextChanged then self.OnTextChanged(self, false) end
    end
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    for _, method in ipairs({ "SetPoint", "ClearAllPoints", "SetWidth", "SetHeight", "SetSize" }) do
        local original = frame[method]
        frame[method] = function(self, ...) assert(not InCombatLockdown(), "dashboard geometry must defer combat"); return original(self, ...) end
    end
    return frame
end
CreateFrame = function(_, name, parent) assert(not InCombatLockdown(), "dashboard construction must defer combat"); created = created + 1; return Widget(name, parent) end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }; timers[#timers + 1] = timer; return timer
end }
local function Flush() local batch = timers; timers = {}; for _, timer in ipairs(batch) do if not timer.cancelled then timer.callback() end end end
local function Pending() local count = 0; for _, timer in ipairs(timers) do if not timer.cancelled then count = count + 1 end end; return count end
C_EventUtils = { IsEventValid = function(event) return event ~= "TRADE_SKILL_LIST_UPDATE" end }
GetCurrentRegion = function() return 110 end; UnitGUID = function() return "Player-Main" end
UnitName = function() return "Main", "Oak" end; UnitClass = function() return "Mage", "MAGE" end
GetNormalizedRealmName = function() return "ClassicBetaPvE" end
C_GameRules = { IsHardcoreActive = function() return false end }
GetServerTime = function() return now end; UnitLevel = function() return level end; GetMoney = function() return money end
GetProfessions = function() return 1, nil, 3, nil, 5, nil, 7 end
local skills = { [1] = { "Alchemy", 120, 225 }, [3] = { "First Aid", 80, 150 }, [5] = { "Cooking", 60, 150 }, [7] = { "Fishing", 20, 75 } }
GetProfessionInfo = function(id) local skill = skills[id]; return skill[1], 123, skill[2], skill[3] end
date = function(_, at) return "Time " .. at end
GameTooltip = Widget(); GameTooltip.SetOwner = function(self, owner) self.owner = owner; self.lines = {} end
GameTooltip.GetOwner = function(self) return self.owner end
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
dashboard.panel, dashboard.events, dashboard.timer, dashboard.active, dashboard.shuttingDown = nil, nil, nil, nil, nil
dashboard.query, dashboard.sort, dashboard.page = "", "name", 1; gui.characterPanel = nil
equal(Suite.db.characterDashboard, false, "dashboard recording starts independently off")
dashboard:Apply(); equal(created, 0, "disabled recording creates no frames")
equal(Pending(), 0, "disabled recording creates no work")
Suite.db.characterDashboard = true; SetCombat(true); dashboard:Apply()
equal(created, 0, "first enable defers combat creation")
equal(dashboard:Build(gui.content), nil, "first view creation defers combat")
Suite.db.characterDashboard = false; dashboard:Apply()
equal(Suite.pending.dashboardEnable, nil, "disable cancels deferred enable")
SetCombat(false); Suite.db.characterDashboard = true; dashboard:Apply()
local characters = Suite.db.inventory.characters
local profile = characters["Player-Main"].profile
equal(characters["Player-Main"].fullName, "Main Oak", "dashboard reuses native complete character identity")
equal(profile.level, 36, "capture records the observed player level")
equal(profile.money, 123456, "capture records copper without losing silver or copper")
equal(profile.ruleset, "PvE", "dashboard reuses existing ruleset detection")
equal(#profile.professions, 4, "nil profession holes do not lose secondary professions")
equal(profile.professions[4].name, "Fishing", "the seventh native profession return is recorded")
equal(profile.professions[1].rank, 120, "profession ranks come from the native tuple")
equal(profile.moneyAt, 1000, "money has an independent recording date")
equal(Suite.Inventory:Enabled(), true, "dashboard independently enables shared inventory recording")
equal(Suite.db.inventorySearch, false, "dashboard does not enable native ownership search")
equal(Suite.db.itemInventory, false, "dashboard does not enable tooltip counts")
equal(dashboard.events.registered.PLAYER_MONEY, true, "native money events update the record")
equal(dashboard.events.registered.TRADE_SKILL_LIST_UPDATE, nil, "runtime-invalid optional events are skipped")
money, level, now = 0, 37, 1010
dashboard:OnEvent("PLAYER_MONEY"); dashboard:OnEvent("SKILL_LINES_CHANGED"); dashboard:OnEvent("PLAYER_LEVEL_UP")
equal(Pending(), 1, "record bursts coalesce into one cancellable update")
Flush(); equal(profile.money, 0, "known zero gold is recorded rather than treated as missing")
equal(profile.level, 37, "level updates query current native state")
equal(Pending(), 0, "capture leaves no idle polling")
money, level, now = { secret = true }, { secret = true }, 1020
skills[1][2] = { secret = true }; dashboard:Capture()
equal(profile.money, 0, "secret money preserves the last readable record")
equal(profile.moneyAt, 1010, "unavailable money cannot acquire a fresh date")
equal(profile.level, 37, "secret level cannot replace a readable saved level")
equal(profile.levelAt, 1010, "unavailable level retains its own old date")
equal(profile.professionsAt, 1010, "partial profession data cannot replace a complete snapshot")
skills[1][2] = 120
local nativeProfessions = GetProfessions
GetProfessions = nil; dashboard:Capture()
equal(#profile.professions, 4, "missing profession capability preserves the complete record")
GetProfessions = function() return { secret = true } end; dashboard:Capture()
equal(profile.professionsAt, 1010, "unreadable profession indices are never used in API calls")
GetProfessions = function() return 1, 1 end; dashboard:Capture()
equal(profile.professionsAt, 1010, "duplicate native profession indices cannot authorize an incomplete snapshot")
GetProfessions = function() error("not available") end; dashboard:Capture()
equal(profile.professionsAt, 1010, "profession API failures remain unknown")
GetProfessions = function() end; dashboard:Capture()
equal(#profile.professions, 0, "observed absence of professions replaces an obsolete learned list")
GetProfessions = nativeProfessions; money, level = 543210, 37; dashboard:Capture()
now = { secret = true }; dashboard:Capture()
equal(profile.at, 1020, "unreadable server time prevents undated writes")
now = 1030
characters.alt = { name = "Alt", fullName = "Alt Pine", realm = "OtherRealm", region = 110, class = "WARRIOR",
    profile = { level = 60, money = 20000, at = 900, moneyAt = 900, professions = { { name = "Mining", rank = 300, maxRank = 300 } } },
    bags = { at = 800 }, bank = { at = 700 } }
characters.legacy = { name = "Legacy", realm = "Realm", region = 110 }
characters.remote = { name = "Remote", realm = "Realm", region = 1, profile = { money = 999999 } }
characters.hidden = { secret = true }
characters.bad = { name = "Bad|Name", realm = "Realm", region = 110 }
characters.corrupt = { name = "Corrupt", realm = "Realm", region = 110, profile = { money = math.huge, level = -1, professions = { secret = true } } }
local rows, total, gold, known = dashboard:Rows("", "name")
equal(total, 4, "dashboard scope omits unreadable identities and other regions")
equal(known, 2, "unknown balances do not become invented zero balances")
equal(gold, 563210, "recorded gold sums known balances once per GUID")
equal(rows[1].name, "Alt Pine", "display rows sort by complete character name")
equal(rows[1].bankAt, 700, "dashboard shows the actual bank snapshot date")
equal(rows[2].money, nil, "nonfinite saved gold remains unknown")
equal(rows[2].professions, nil, "secret saved profession lists remain unknown")
equal(rows[3].level, nil, "legacy snapshots display unrecorded profile fields")
equal(dashboard:Money(nil), "Not recorded", "unknown money is explicitly disclosed")
equal(dashboard:Money(123456), "12g 34s 56c", "gold display preserves all denominations")
equal(dashboard:Money(0), "0g 0s 0c", "known zero is distinct from unknown")
equal(dashboard:Rows("mining otherrealm", "name")[1].name, "Alt Pine", "literal AND search includes professions and realm")
equal(#dashboard:Rows("%", "name"), 0, "dashboard search treats punctuation literally")
equal(#dashboard:Rows({ secret = true }, "name"), 0, "restricted queries never reach matching")
equal(dashboard:Rows("", "money")[1].name, "Main Oak", "money sort places highest known balance first")
equal(dashboard:Rows("", "level")[1].name, "Alt Pine", "level sort orders observed levels")
equal(dashboard:Rows("", "at")[1].name, "Main Oak", "updated sort orders actual capture dates")
GetCurrentRegion = function() return { secret = true } end
equal(#dashboard:Rows("", "name"), 0, "unknown region never reuses another scope")
GetCurrentRegion = function() return 110 end
for i = 1, 7 do characters["extra" .. i] = { name = "Extra " .. i, realm = "Realm", region = 110 } end
SlashCmdList.WOWFOREVERSUITE("characters")
equal(gui.page, "characters", "characters command opens the integrated dashboard")
equal(gui.group, "overview", "dashboard remains in the existing Overview category")
equal(gui.characterPanel:GetParent(), gui.content, "dashboard uses the existing clipped scroll child")
equal(Suite.SettingsCatalog:Search("recorded character dashboard")[1].key, "characterDashboard", "settings search finds the dashboard recording control")
GetCurrentRegion = function() return { secret = true } end; dashboard:Render()
equal(dashboard.empty:GetText(), "Character region unavailable.", "unknown scope is disclosed rather than reported as an empty account")
equal(dashboard.summary:GetText():find("Not recorded", 1, true) ~= nil, true, "unavailable scope cannot imply a zero account balance")
GetCurrentRegion = function() return 110 end; dashboard:Render()
equal(dashboard.pageLabel:GetText(), "1 / 3", "larger rosters use bounded dashboard pages")
dashboard.next.OnClick(); dashboard.next.OnClick(); dashboard.next.OnClick()
equal(dashboard.page, 3, "pagination clamps to the final page")
dashboard.previous.OnClick(); equal(dashboard.page, 2, "previous page exposes earlier characters")
dashboard.search:SetText("mining"); dashboard.search.OnTextChanged(dashboard.search)
equal(#dashboard.rows, 1, "view search filters the visible roster")
equal(dashboard.buttons[1].name:GetText(), "Alt Pine", "row displays the recorded full name")
equal(dashboard.skills[1].name:GetText(), "Mining", "selected character exposes a separately aligned profession")
equal(dashboard.skills[1].rank:GetText(), "300/300", "selected character exposes its recorded rank")
dashboard.search:SetText(""); dashboard.sort = "money"; dashboard:Render()
dashboard.buttons[2].OnClick()
equal(dashboard.selected, dashboard.buttons[2].entry.guid, "click selects the requested character record")
equal(dashboard.skills[1].name:GetText(), "Mining", "selection uses the chosen character's professions")
dashboard.buttons[1].OnClick()
equal(dashboard.skills[4].name:IsShown(), true, "all four recorded professions are available without an inline list")
dashboard.search:SetText("no matching character")
equal(dashboard.details:IsShown(), false, "empty filters hide the previously selected character details")
equal(dashboard.selected, nil, "empty filters clear stale selection")
dashboard.search:SetText("mining")
equal(dashboard.selected, dashboard.buttons[1].entry.guid, "new filtered results select a visible character")
if WFS_DASHBOARD_PREVIEW then
    dashboard.search:SetText(""); dashboard.sort = "money"; dashboard:Render(); dashboard.buttons[1].OnClick()
    local model = { width = 514, height = dashboard.panel.height, title = gui.heading.text,
        summary = dashboard.summary.text, coverage = dashboard.coverage.text, rows = {}, skills = {},
        detailY = -dashboard.details.point[3], detailHeight = dashboard.details.height,
        detailTitle = dashboard.detailTitle.text, detailContext = dashboard.detailContext.text,
        offset = gui.controlsOffset, viewport = gui.viewportHeight }
    for _, button in ipairs(dashboard.buttons) do
        if button:IsShown() then model.rows[#model.rows + 1] = { y = -button.point[3], height = button.height,
            name = button.name.text, money = button.money.text, context = button.context.text,
            level = button.level.text, selected = button.entry.guid == dashboard.selected } end
    end
    for _, labels in ipairs(dashboard.skills) do
        if labels.name:IsShown() then model.skills[#model.skills + 1] = { name = labels.name.text, rank = labels.rank.text } end
    end
    WFS_DASHBOARD_PREVIEW(model)
    dashboard.search:SetText("mining")
end
dashboard.buttons[1].OnEnter()
equal(GameTooltip.lines[6][1], "Money recorded: Time 900", "hover exposes the balance's own recording date")
GameTooltip.owner = gui.frame; GameTooltip:Show(); dashboard:HideTooltip()
equal(GameTooltip:IsShown(), true, "dashboard cleanup preserves a tooltip now owned elsewhere")
dashboard.search.OnEscapePressed(dashboard.search)
equal(dashboard.query, "", "local Escape resets dashboard search")
local initialHeight = dashboard.panel:GetHeight()
SetCombat(true); dashboard:RefreshView(); dashboard:Capture(); dashboard:Schedule()
equal(dashboard.panel:GetHeight(), initialHeight, "combat does not resize the dashboard")
equal(Pending(), 0, "combat recording queues without starting a worker")
equal(type(Suite.pending.dashboardCapture), "function", "combat defers current-player recording")
SetCombat(false); Suite.pending.dashboardCapture(); Flush(); Suite.pending.dashboardView(); Suite.pending.dashboardView = nil
equal(profile.moneyAt, 1030, "combat exit captures fresh data with the actual new time")
dashboard:Schedule(); SetCombat(true); Flush()
equal(type(Suite.pending.dashboardCapture), "function", "a pre-combat timer cannot silently lose its pending update")
SetCombat(false); Suite.pending.dashboardCapture = nil
Suite.db.characterDashboard = false; dashboard:Apply()
equal(characters["Player-Main"].profile.money, 543210, "disabling recording preserves existing data")
equal(next(dashboard.events.registered), nil, "disable unregisters all recording events")
equal(Suite.Inventory:Enabled(), false, "shared inventory stops when all consumers are off")
Suite.db.inventorySearch = true; equal(Suite.Inventory:Enabled(), true, "search remains an independent inventory consumer")
Suite.db.inventorySearch = false
equal(#dashboard:Rows("mining", "name"), 1, "saved records remain browsable with recording off")
Suite.db.characterDashboard = true; dashboard:Apply(); dashboard:Schedule(); dashboard:OnEvent("PLAYER_LOGOUT"); dashboard:Schedule()
equal(Pending(), 0, "logout cancels work and never requeues a polling worker")
dashboard:Cancel(); dashboard.panel:Hide()
for _, key in ipairs(globals) do _G[key] = old[key] end
for key in pairs(dashboard) do dashboard[key] = nil end
for key, value in pairs(saved) do dashboard[key] = value end
Suite.db, Suite.pending, gui.characterPanel = oldDB, oldPending, oldPanel
SetCombat(false); gui:Select(oldPage)
