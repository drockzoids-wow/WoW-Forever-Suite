local Suite, equal, Frame, SetCombat = ...
local dashboard, gui = Suite.CharacterDashboard, Suite.GUI
local old, globals = {}, { "CreateFrame", "C_Timer", "C_EventUtils", "GetCurrentRegion", "UnitGUID", "UnitName", "UnitClass",
    "GetNormalizedRealmName", "GetServerTime", "UnitLevel", "GetMoney", "GetProfessions", "GetProfessionInfo",
    "C_GameRules", "GameRulesUtil", "GetXPExhaustion", "GetRestState", "BreakUpLargeNumbers",
    "C_Traits", "Constants", "UnitXPMax", "IsResting", "date", "GameTooltip" }
for _, key in ipairs(globals) do old[key] = _G[key] end
local saved = {}; for key, value in pairs(dashboard) do saved[key] = value end
local oldDB, oldPending, oldPage, oldPanel = Suite.db, Suite.pending, gui.page, gui.characterPanel
local timers, created, now, money, level = {}, 0, 1000, 123456, 36
local restedXP, restState, maxLevel = 12345, 1, false
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
GameRulesUtil = { IsPlayerAtEffectiveMaxLevel = function() return maxLevel end }
local function GetRestedXP() return restedXP end
GetXPExhaustion = GetRestedXP
GetRestState = function() return restState end
UnitXPMax = function() return 50000 end
BreakUpLargeNumbers = function(amount) return amount == 12345 and "12,345" or tostring(amount) end
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
equal(profile.restedXP.amount, 12345, "login captures the native rested XP amount")
equal(profile.restedXP.xpMax, 50000, "the percentage needs no Legacy rank when rested XP is confirmed")
equal(profile.restedXP.at, 1000, "rested XP has an independent recording date")
equal(Suite.Inventory:Enabled(), true, "dashboard independently enables shared inventory recording")
equal(Suite.db.inventorySearch, false, "dashboard does not enable native ownership search")
equal(Suite.db.itemInventory, false, "dashboard does not enable tooltip counts")
equal(dashboard.events.registered.PLAYER_MONEY, true, "native money events update the record")
equal(dashboard.events.registered.UPDATE_EXHAUSTION, true, "native rest changes update the record")
equal(dashboard.events.registered.PLAYER_XP_UPDATE, true, "XP changes can consume rested XP")
equal(dashboard.events.registered.TRADE_SKILL_LIST_UPDATE, nil, "runtime-invalid optional events are skipped")
money, level, now, restedXP = 0, 37, 1010, 10000
dashboard:OnEvent("PLAYER_MONEY"); dashboard:OnEvent("SKILL_LINES_CHANGED"); dashboard:OnEvent("PLAYER_LEVEL_UP")
dashboard:OnEvent("UPDATE_EXHAUSTION"); dashboard:OnEvent("PLAYER_XP_UPDATE")
equal(Pending(), 1, "record bursts coalesce into one cancellable update")
Flush(); equal(profile.money, 0, "known zero gold is recorded rather than treated as missing")
equal(profile.level, 37, "level updates query current native state")
equal(profile.restedXP.amount, 10000, "the coalesced XP update saves the new rested balance")
equal(Pending(), 0, "capture leaves no idle polling")
money, level, now = { secret = true }, { secret = true }, 1020
restedXP = { secret = true }
skills[1][2] = { secret = true }; dashboard:Capture()
equal(profile.money, 0, "secret money preserves the last readable record")
equal(profile.moneyAt, 1010, "unavailable money cannot acquire a fresh date")
equal(profile.level, 37, "secret level cannot replace a readable saved level")
equal(profile.levelAt, 1010, "unavailable level retains its own old date")
equal(profile.professionsAt, 1010, "partial profession data cannot replace a complete snapshot")
equal(profile.restedXP.amount, 10000, "restricted rested XP preserves the previous balance")
equal(profile.restedXP.at, 1010, "restricted rested XP retains its observation date")
restedXP = nil; dashboard:Capture()
equal(profile.restedXP.at, 1010, "a missing threshold in rested state retains the previous observation")
GetXPExhaustion = function() error("not available") end; restState = 2; dashboard:Capture()
equal(profile.restedXP.amount, 10000, "a rejected rested XP read does not become zero")
GetXPExhaustion = GetRestedXP; dashboard:Capture()
equal(profile.restedXP.amount, 0, "normal rest state with no threshold records zero")
maxLevel = true; dashboard:Capture()
equal(profile.restedXP.maxLevel, true, "a capped character is distinguished from zero rested XP")
equal(profile.restedXP.amount, nil, "a previous balance is cleared when the level cap is observed")
restedXP, restState, maxLevel = 12345, 1, false
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
    profile = { level = 60, money = 20000, at = 900, moneyAt = 900, restedXP = { amount = 0, at = 890 },
        professions = { { name = "Mining", rank = 300, maxRank = 300 } } },
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
equal(rows[3].restedXP, nil, "legacy snapshots leave rested XP unrecorded")
equal(rows[1].restedXP.amount, 0, "each character retains its own observed amount")
local dashboardDB = Suite.db
Suite.db = Suite.InitializeDB(Suite.Copy(dashboardDB))
equal(dashboard:Rows("main", "name")[1].restedXP.amount, 12345, "the recorded balance survives saved-variable reload")
equal(dashboard:Rows("alt", "name")[1].restedXP.at, 890, "the alt's recording date survives saved-variable reload")
Suite.db = dashboardDB
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
equal(gui.group, "tools", "recorded inventory is discoverable in Tools")
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
equal(dashboard.buttons[1].restedXP:GetText(), "0", "a zero rested balance is shown as zero")
equal(dashboard.buttons[1].restedAt:GetText(), "Time 890", "the date appears below the rested XP amount")
equal(dashboard.skills[1].name:GetText(), "Mining", "selected character exposes a separately aligned profession")
equal(dashboard.skills[1].rank:GetText(), "300/300", "selected character exposes its recorded rank")
dashboard.search:SetText(""); dashboard.sort = "money"; dashboard:Render()
equal(dashboard.buttons[1].restedXP:GetText(), "12,345 (24%)", "the row shows the formatted amount and whole-level percentage")
equal(dashboard.buttons[3].restedXP:GetText(), "Not recorded", "unknown rested balances remain distinct in the roster")
equal(dashboard.buttons[3].restedAt:GetText(), "", "unknown rested balances have no timestamp")
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
Suite.db.characterDashboard = true; dashboard:Apply(); dashboard:Schedule()
local logoutTimer = dashboard.timer
local moneyAt, professionsAt = profile.moneyAt, profile.professionsAt
money, now = 0, 1040
GetProfessions = function() end
dashboard:OnEvent("PLAYER_LOGOUT"); dashboard:Schedule()
equal(Pending(), 0, "logout cancels work and never requeues a polling worker")
equal(profile.money, 543210, "dashboard logout cannot erase account money with a teardown zero")
equal(profile.moneyAt, moneyAt, "dashboard logout preserves the actual money observation date")
equal(#profile.professions, 4, "dashboard logout preserves professions during client teardown")
equal(profile.professionsAt, professionsAt, "dashboard logout preserves the profession observation date")
logoutTimer.callback(); dashboard:Capture(); dashboard:OnEvent("PLAYER_MONEY")
equal(profile.money, 543210, "late dashboard callbacks cannot erase the saved balance after logout")
equal(Pending(), 0, "late dashboard events never restart capture after logout")

-- Confirmed observations are kept apart from metadata for one completed logout.
do
    local rank, resting, staged, nativeReads = 0, true, false, 0
    local clock, xpMax = 2000, 100000
    Constants = { LegacyConsts = { LEGACY_TREE_ADVENTURE_ID = 1188 } }
    C_Traits = {
        GetConfigIDByTreeID = function(treeID) if treeID == 1188 then return 7 end end,
        ConfigHasStagedChanges = function() return staged end,
        GetTreeNodes = function() return { 83, 84 } end,
        GetNodeInfo = function(_, nodeID)
            if nodeID == 83 then return { entryIDs = { 800 }, activeRank = 5, maxRanks = 5 } end
            if nodeID == 84 then return { entryIDs = { 801 }, activeRank = rank, maxRanks = 5 } end
        end,
        GetEntryInfo = function(_, id) return { definitionID = id + 1000 } end,
        GetDefinitionInfo = function(id) return { spellID = id == 1801 and 1225478 or 429959 } end,
    }
    local function CaptureLogout()
        now = clock
        dashboard.active = nil
        UnitGUID = function() return "Player-Main" end
        UnitXPMax = function() nativeReads = nativeReads + 1; return xpMax end
        IsResting = function() nativeReads = nativeReads + 1; return resting end
        GetXPExhaustion = function() nativeReads = nativeReads + 1; return restedXP end
        dashboard:Apply()
        now = clock + 20
        local reads = nativeReads
        dashboard:OnEvent("PLAYER_LOGOUT")
        equal(nativeReads, reads, "logout writes only the timestamp against the in-world observation")
        return profile.restedXP
    end
    local function MainRest()
        return dashboard:Rows("main", "name")[1].restedXP
    end
    restedXP = 10000
    local snapshot = CaptureLogout()
    equal(snapshot.offline.rank, 0, "an observed zero Legacy rank is usable")
    equal(snapshot.offline.logoutAt, 2020, "offline time starts at logout rather than the previous observation")
    now = 2020 + 8 * 3600
    equal(MainRest().estimate, nil, "the current character always shows its confirmed balance")
    UnitGUID = function() return "Player-Other" end
    equal(MainRest().estimate, 15000, "eight hours in a rested area adds 5% of the level requirement")
    equal(snapshot.amount, 10000, "estimates never replace confirmed XP")
    local function MainButton()
        dashboard:Render()
        for _, button in ipairs(dashboard.buttons) do
            if button.entry and button.entry.guid == "Player-Main" then return button end
        end
        error("main character row missing")
    end
    snapshot.xpMax, snapshot.level = nil, nil
    local main = MainButton()
    equal(main.restedXP:GetText(), "≈15000 (15%)", "an older logout record uses its offline XP requirement for the percentage")
    equal(main.restedAt:GetText(), "Offline estimate", "the roster identifies the estimate in words")
    local originalDB = Suite.db
    Suite.db = Suite.InitializeDB(Suite.Copy(originalDB))
    equal(MainRest().estimate, 15000, "the logout snapshot survives a saved-variable round trip")
    Suite.db = originalDB

    rank, resting = 5, false
    snapshot = CaptureLogout()
    UnitGUID = function() return "Player-Other" end
    now = snapshot.offline.logoutAt + 8 * 3600
    equal(MainRest().estimate, 11500, "outside a rested area the ranked bonus applies to the slower rate")
    now = snapshot.offline.logoutAt + 100 * 86400
    equal(MainRest().estimate, 180000, "rank five raises the base cap by twenty percent")
    now = snapshot.offline.logoutAt - 1
    equal(MainRest().estimate, nil, "a future logout time cannot create an estimate")
    snapshot.offline.rank = { secret = true }
    now = snapshot.offline.logoutAt + 86400
    equal(MainRest().estimate, nil, "restricted saved ranks fall back to the confirmed balance")

    rank = { secret = true }
    snapshot = CaptureLogout()
    equal(snapshot.offline, nil, "unreadable rank cannot authorize an offline interval")
    rank, staged = 2, true
    snapshot = CaptureLogout()
    equal(snapshot.offline, nil, "staged talent changes cannot provide an estimate")
    staged = false
    snapshot = CaptureLogout()
    equal(snapshot.offline.rank, 2, "the committed active rank is read on later captures")
    dashboard.active = nil
    dashboard:Apply()
    resting = true
    dashboard:OnEvent("PLAYER_UPDATE_RESTING")
    dashboard:OnEvent("PLAYER_LOGOUT")
    equal(profile.restedXP.offline, nil, "a pending location change cannot reuse the old logout location")
    Flush()

    resting = false
    snapshot = CaptureLogout()
    dashboard.active = nil
    restedXP = { secret = true }
    dashboard:Apply()
    equal(snapshot.offline, nil, "a new login ends the previous offline interval even when XP is unreadable")
    equal(snapshot.amount, 10000, "login fallback preserves the confirmed amount")

    profile.restedXP = { amount = 625, xpMax = 400, level = 1, at = clock }
    equal(MainButton().restedXP:GetText(), "625 (125%)", "XP beyond the first level uses the next level’s higher requirement")
    profile.restedXP.amount = 400
    equal(MainButton().restedXP:GetText(), "400 (100%)", "the full current requirement is exactly one level")
    profile.restedXP.amount = 1
    equal(MainButton().restedXP:GetText(), "1 (<1%)", "a positive amount below one percent is distinct from empty")
    profile.restedXP.amount = 0
    equal(MainButton().restedXP:GetText(), "0 (0%)", "a known empty amount has a zero percentage")
    profile.restedXP.amount, profile.restedXP.xpMax = 625, 401
    equal(MainButton().restedXP:GetText(), "625", "a mismatched curve does not assume the next level’s cost")
    profile.restedXP = { amount = 250000, xpMax = 209800, level = 59, at = clock }
    equal(MainButton().restedXP:GetText(), "250000 (100%)", "rested XP cannot span beyond Forever’s maximum level")
end

dashboard:Cancel(); dashboard.panel:Hide()
for _, key in ipairs(globals) do _G[key] = old[key] end
for key in pairs(dashboard) do dashboard[key] = nil end
for key, value in pairs(saved) do dashboard[key] = value end
Suite.db, Suite.pending, gui.characterPanel = oldDB, oldPending, oldPanel
SetCombat(false); gui:Select(oldPage)
