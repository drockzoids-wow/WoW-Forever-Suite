local Suite, equal, Frame, SetCombat = ...
local journal = Suite.Journey
local names = { "GetTime", "GetServerTime", "GetMoney", "UnitLevel", "UnitXP", "UnitXPMax", "IsXPUserDisabled",
    "UnitIsDeadOrGhost", "UnitIsFeignDeath", "GetZoneText", "C_Item", "C_Reputation", "C_GossipInfo", "C_Container",
    "GetRepairAllCost", "C_Timer", "LOOT_ITEM_SELF", "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF", "LOOT_ITEM_PUSHED_SELF_MULTIPLE" }
local saved = {}; for _, name in ipairs(names) do saved[name] = _G[name] end
local originalFeature, originalPending = Suite.Leveling, Suite.pending
Suite.pending = {}
local now, server, money, level, xp, maximum, dead, feign = 1000, 2000000, 100000, 10, 800, 1000, false, false
local work, queries, repQueries, requests = {}, 0, 0, 0
local prices = { [101] = 7 }
local faction = { factionID = 72, name = "Stormwind", currentStanding = -2000, currentReactionThreshold = -3000,
    nextReactionThreshold = 0, isHeader = false, isHeaderWithRep = false, isCollapsed = false }
local collapsed = false
GetTime = function() return now end
GetServerTime = function() return server end
GetMoney = function() queries = queries + 1; return money end
UnitLevel = function() queries = queries + 1; return level end
UnitXP = function() queries = queries + 1; return xp end
UnitXPMax = function() queries = queries + 1; return maximum end
IsXPUserDisabled = function() return false end
UnitIsDeadOrGhost = function() return dead end
UnitIsFeignDeath = function() return feign end
GetZoneText = function() return "Elwynn Forest" end
LOOT_ITEM_SELF, LOOT_ITEM_SELF_MULTIPLE = "You receive loot: %s.", "You receive loot: %sx%d."
LOOT_ITEM_PUSHED_SELF, LOOT_ITEM_PUSHED_SELF_MULTIPLE = "You receive item: %s.", "You receive item: %sx%d."
C_Item = { GetItemInfo = function(id)
    queries = queries + 1
    if not prices[id] then return end
    return "Item " .. id, "item:" .. id, 1, 1, 1, "", "", 1, "", 1, prices[id]
end, RequestLoadItemDataByID = function() requests = requests + 1 end }
C_GossipInfo = { GetFriendshipReputation = function() return { friendshipFactionID = 0 } end }
C_Reputation = {
    GetNumFactions = function() repQueries = repQueries + 1; return 2 end,
    GetFactionDataByIndex = function(index)
        repQueries = repQueries + 1
        if index == 2 then return { factionID = 999, name = "Special", currentStanding = 100, isHeader = false, isCollapsed = false } end
        return collapsed and { isHeader = true, isHeaderWithRep = false, isCollapsed = true } or faction
    end,
    GetFactionDataByID = function(id) repQueries = repQueries + 1; if id == 72 then return faction end end,
    IsMajorFaction = function(id) return id == 999 end, IsFactionParagon = function() return false end,
    ExpandFactionHeader = function() error("journal must not expand native groups") end,
    SetWatchedFactionByID = function() error("journal must not change watched reputation") end,
}
C_Timer = {
    NewTicker = function() return { Cancel = function() end } end,
    NewTimer = function(delay, callback)
        equal(delay, 0.05, "journey events share the existing leveling coalescer")
        local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
        work[#work + 1] = timer; return timer
    end,
}
local function Flush()
    local current = work; work = {}
    for _, timer in ipairs(current) do if not timer.cancelled then timer.callback() end end
end
local function Advance(seconds) now, server = now + seconds, server + seconds end
local function Fresh(state, reload)
    local env = { modules = {}, db = { levelingBar = true }, pending = Suite.pending, IsReadable = Suite.IsReadable,
        AfterCombat = Suite.AfterCombat, BagSpace = Suite.BagSpace, Journey = journal }
    assert(loadfile("src/WoWForeverSuite/Leveling.lua"))("WoWForeverSuite", env)
    local feature = env.Leveling
    feature:InitializeCharacter(state); feature.events = Frame()
    feature.Render = function() end; feature.active = true
    feature:OnWorld(not reload, reload == true)
    return feature, env
end
local feature, env = Fresh()
equal(next(feature.session.journey.reputation), nil, "starting reputation never becomes a gain")
equal(feature.session.journey.baselines[72], -2000, "negative ordinary standing is a valid baseline")
equal(feature.session.journey.baselines[999], nil, "special reputation systems are excluded")
local register = feature.events.RegisterEvent
feature.events.RegisterEvent = function(_, event) if event == "PLAYER_ALIVE" then return false end end
journal:Events(feature)
equal(feature.session.journey.deathsPartial, true, "unsupported resurrection events disclose incomplete death tracking")
feature.events.RegisterEvent = register
feature.session.journey.deathsPartial = false
Advance(45); dead = true
feature:OnEvent("PLAYER_DEAD"); feature:OnEvent("PLAYER_DEAD")
equal(feature.session.journey.deaths, 1, "duplicate death events count once")
feature:OnEvent("PLAYER_ALIVE"); feature:OnEvent("PLAYER_DEAD")
equal(feature.session.journey.deaths, 1, "ghost release cannot rearm the death latch")
dead = false; feature:OnEvent("PLAYER_UNGHOST")
dead, feign = true, true; feature:OnEvent("PLAYER_DEAD")
equal(feature.session.journey.deaths, 1, "Feign Death is not a journey death")
feign = false; feature:OnEvent("PLAYER_DEAD")
equal(feature.session.journey.deaths, 2, "a later real death is recorded")
equal(feature.session.journey.lastDeath.zone, "Elwynn Forest", "last death records an ordinary zone")
dead = { secret = true }; feature:OnEvent("PLAYER_DEAD")
equal(feature.session.journey.deaths, 2, "restricted death state cannot authorize a count")
equal(feature.session.journey.deathsPartial, true, "restricted observations disclose incomplete death tracking")
dead = false; feature:OnEvent("PLAYER_UNGHOST")
Advance(60); money = money + 100; feature:OnEvent("PLAYER_MONEY")
feature:OnEvent("PLAYER_LEVEL_UP", 11); feature:OnEvent("PLAYER_LEVEL_UP", 11)
equal(#feature.session.journey.levels, 1, "early duplicate level-up boundaries produce one milestone")
local milestone = feature.session.journey.levels[1]
equal(milestone.level, 11, "milestone uses the reached-level event before UnitLevel catches up")
equal(milestone.elapsed, 105, "milestone includes tracked idle time")
equal(milestone.gold, 100, "milestone records net gold at that level")
equal(milestone.deaths, 2, "milestone includes observed deaths")
equal(milestone.partial, true, "starting partway through a level is disclosed")
level, xp, maximum = 11, 0, 1500; Flush()
equal(#feature.session.journey.levels, 1, "readback after a level event cannot duplicate its milestone")
local link = "|cff00ff00|Hitem:101:0:0:0|h[Item 101]|h|r"
feature:OnEvent("CHAT_MSG_LOOT", "You receive loot: " .. link .. "x2.", nil, nil, nil, nil, nil, nil, nil, nil, nil, 91)
feature:OnEvent("CHAT_MSG_LOOT", "You receive loot: " .. link .. "x2.", nil, nil, nil, nil, nil, nil, nil, nil, nil, 91)
equal(feature.session.journey.loot[101].count, 2, "receipt line ID passes through the controller and deduplicates")
equal(feature.session.journey.loot[101].value, 14, "known vendor estimate uses price per received item")
journal:Loot(feature, "Other receives loot: " .. link .. ".", 92)
journal:Loot(feature, "You create: " .. link .. ".", 93)
equal(feature.session.journey.loot[101].count, 2, "other-player and crafting messages are excluded")
local unknown = "|Hitem:102:0|h[Unknown]|h"
journal:Loot(feature, "You receive item: " .. unknown .. "x3.", 94)
equal(feature.session.journey.loot[102].count, 3, "uncached loot retains observed quantity")
equal(feature.session.journey.loot[102].priced, 0, "missing prices remain unpriced rather than known zero")
equal(requests, 1, "uncached metadata requests are bounded")
prices[102] = 5; feature:OnEvent("ITEM_DATA_LOAD_RESULT", 102)
equal(feature.session.journey.loot[102].priced, 3, "metadata recovery prices the existing quantity")
equal(feature.session.journey.loot[102].value, 15, "metadata recovery adds only the missing estimate")
feature:OnEvent("GET_ITEM_INFO_RECEIVED", 102)
equal(feature.session.journey.loot[102].value, 15, "duplicate metadata events cannot inflate value")
prices[103] = 0
journal:Loot(feature, "You receive loot: |Hitem:103:0|h[No sale value]|h.", 90)
equal(feature.session.journey.loot[103].priced, 1, "readable zero vendor price is known rather than missing")
feature.journeyRuntime.formats = journal:LootFormats()
LOOT_ITEM_SELF_MULTIPLE = "%2$d objets reçus : %1$s."
feature.journeyRuntime.formats = journal:LootFormats()
journal:Loot(feature, "7 objets reçus : " .. link .. ".", 95)
equal(feature.session.journey.loot[101].count, 9, "localized positional receipt placeholders are supported")
journal:Loot(feature, { secret = true }, 96)
equal(feature.session.journey.lootPartial, true, "restricted receipt text marks incomplete tracking without serialization")
faction.currentStanding = -1900
feature:OnEvent("UPDATE_FACTION"); feature:OnEvent("FACTION_STANDING_CHANGED", 72)
equal(#work, 1, "reputation and level work share one coalesced timer")
Flush()
equal(feature.session.journey.reputation[72].gained, 100, "reputation gain is an observed absolute-standing difference")
faction.currentStanding = -1930; feature:OnEvent("UPDATE_FACTION"); Flush()
equal(feature.session.journey.reputation[72].lost, 30, "reputation losses are separate from gains")
feature:OnEvent("UPDATE_FACTION"); Flush()
equal(feature.session.journey.reputation[72].gained, 100, "repeated faction events do not count the baseline twice")
collapsed = true; faction.currentStanding = -1920; feature:OnEvent("UPDATE_FACTION"); Flush()
equal(feature.session.journey.reputation[72].gained, 110, "known factions remain readable under collapsed groups")
SetCombat(true); local beforeRep = repQueries
faction.currentStanding = -1910; feature:OnEvent("UPDATE_FACTION"); Flush()
equal(repQueries, beforeRep, "reputation data is not scanned in combat")
SetCombat(false); feature:OnEvent("PLAYER_REGEN_ENABLED"); Flush()
equal(feature.session.journey.reputation[72].gained, 120, "combat recovery observes the retained baseline once")
local beforeQueries = queries + repQueries
for _, view in ipairs({ "Loot", "Reputation", "Levels", "History" }) do journal:Rows(feature, feature:Recap("Current"), "Current", view, "quantity", true) end
journal:Summary(feature:Recap("Current"), "Current")
equal(queries + repQueries, beforeQueries, "journal presentation performs no item, money, XP or reputation API reads")
feature:SaveSession(); local checkpoint = Suite.Copy(feature.db)
Advance(15)
local resumed, resumedEnv = Fresh(checkpoint, true)
equal(#resumed.db.history, 0, "reload keeps journey details in Current")
equal(resumed.session.journey.loot[101].count, 9, "loot quantities survive checkpoint validation and reload")
equal(resumed.session.journey.deaths, 2, "death totals survive reload without adding a death")
equal(resumed.journeyRuntime.progress.elapsed, 15, "reload loading time continues the level in progress")
Advance(20); resumed:ResetSession()
equal(#resumed.db.history, 1, "New session archives journey detail once")
equal(resumed.session.journey.deaths, 0, "a new session starts a fresh death counter")
equal(resumed.journeyRuntime.progress.elapsed, 35, "New session preserves the level in progress")
equal(resumed:Recap("Overall").journey.deaths, 2, "Overall adds completed and live journey details once")
local login, loginEnv = Fresh(checkpoint, false)
equal(#login.db.history, 1, "fresh login archives the previous journey once")
equal(login.session.journey.baselines[72], faction.currentStanding, "fresh login seeds current reputation rather than offline gains")
equal(next(login.session.journey.reputation), nil, "fresh login excludes offline reputation changes")
local legacy = Suite.Copy(checkpoint); legacy.checkpoint.journey = nil
local migrated, migratedEnv = Fresh(legacy, false)
equal(migrated.db.history[1].journey, nil, "legacy session details remain unknown rather than fabricated zeros")
equal(journal:Summary(migrated.db.history[1], "Previous").details[2][2], "Not recorded", "legacy deaths are labeled honestly")
local migratedLive = migrated.session; migrated.session = nil; migrated.historyTotal = nil
equal(migrated:Recap("Overall").journey, nil, "all-legacy Overall does not fabricate zero journey counters")
migrated.session, migrated.historyTotal = migratedLive, nil
local bad = journal:New(); bad.loot[{ secret = true }] = { count = 1, priced = 1, value = 1 }
bad.reputation[72] = { name = { secret = true }, gained = 1, lost = 0 }; bad.deaths = { secret = true }
local clean = journal:Validate(bad)
equal(next(clean.loot), nil, "restricted item keys cannot enter saved history")
equal(next(clean.reputation), nil, "restricted faction identity cannot enter saved history")
equal(clean.deathsPartial, true, "malformed detail fields retain a partial marker")
local bounded = journal:New()
for id = 1, 1001 do bounded.loot[id] = { count = 1, priced = 1, value = 0 } end
local capped, kept = journal:Validate(bounded), 0
for _ in pairs(capped.loot) do kept = kept + 1 end
equal(kept, 1000, "per-session item IDs are bounded without deleting completed sessions")
equal(capped.lootPartial, true, "hitting a detail cap discloses omitted observations")
Suite.Leveling = resumed
C_Container = { GetContainerItemInfo = function() return nil end, GetContainerItemID = function() return nil end }
local sale = journal:BeginVendor("sale", { { bag = 0, slot = 1, id = 101, count = 2 } })
money = money + 14; journal:EndVendor(sale)
equal(resumed.session.journey.soldCopper, 14, "matching native disappearance and money confirm Suite sale income")
equal(resumed.session.journey.soldItems, 2, "verified sales count items rather than stacks")
sale = journal:BeginVendor("sale", { { bag = 0, slot = 1, id = 101, count = 2 } })
money = money + 14; C_Container.GetContainerItemInfo = function() error("data rejected") end
journal:EndVendor(sale)
equal(resumed.session.journey.soldCopper, 14, "rejected bag reads cannot confirm an apparent sale")
C_Container.GetContainerItemInfo = function() return { itemID = 101, stackCount = 2 } end
sale = journal:BeginVendor("sale", { { bag = 0, slot = 1, id = 101, count = 2 } })
journal:EndVendor(sale)
equal(resumed.session.journey.soldCopper, 14, "an asynchronous sale request is not counted before completion")
money = money + 14; C_Container.GetContainerItemInfo = function() return nil end
resumed:OnEvent("PLAYER_MONEY")
equal(resumed.session.journey.soldCopper, 28, "money events reconcile a delayed native sale without another worker")
resumed:OnEvent("PLAYER_MONEY")
equal(resumed.session.journey.soldCopper, 28, "completed vendor observations are consumed once")
GetRepairAllCost = function() return 0 end
local repair = journal:BeginVendor("repair", nil, 50, false); money = money - 50; journal:EndVendor(repair)
equal(resumed.session.journey.repairCopper, 50, "personal repairs require both money and completion evidence")
repair = journal:BeginVendor("repair", nil, 70, true); journal:EndVendor(repair)
equal(resumed.session.journey.guildRepairCopper, 70, "guild-paid repairs stay outside personal spending")
GetRepairAllCost = function() return 100 end
repair = journal:BeginVendor("repair", nil, 100, false); journal:EndVendor(repair)
equal(resumed.session.journey.repairCopper, 50, "a repair request alone does not create spending")
local nilFriend = C_GossipInfo.GetFriendshipReputation
C_GossipInfo.GetFriendshipReputation = function() return nil end
local priorGain = resumed.session.journey.reputation[72] and resumed.session.journey.reputation[72].gained or 0
faction.currentStanding = faction.currentStanding + 10; journal:Reputation(resumed)
equal(resumed.session.journey.reputation[72].gained, priorGain + 10, "native nil friendship result still permits ordinary reputation")
C_GossipInfo.GetFriendshipReputation = nilFriend
Suite.Leveling = originalFeature
for _, pair in ipairs({ {feature, env}, {resumed, resumedEnv}, {login, loginEnv}, {migrated, migratedEnv} }) do pair[2].db.levelingBar = false; pair[1]:Apply() end
for _, name in ipairs(names) do _G[name] = saved[name] end
Suite.pending = originalPending
SetCombat(false)

-- Actual shared GUI methods: summary, detail navigation, history selection and combat cancellation.
local gui, feature = Suite.GUI, Suite.Leveling
local old = { db = feature.db, session = feature.session, active = feature.active, runtime = feature.journeyRuntime,
    page = gui.page, shown = gui.frame:IsShown(), view = gui.levelingView, scope = gui.levelingScope, record = gui.levelingRecord }
local record = { version = 1, elapsed = 2460, xp = 12345, gold = -12345, xpPartial = false, goldPartial = false,
    timePartial = false, lastXP = 345, maxXP = 1000, lastMoney = 100000, startedAt = 2000000, savedAt = 2002460,
    startLevel = 29, level = 30, journey = journal:New() }
record.journey.loot[101] = { name = "Linen Cloth", count = 12, priced = 12, value = 156 }
record.journey.reputation[72] = { name = "Stormwind", gained = 175, lost = 25 }
record.journey.levels[1] = { from = 29, level = 30, elapsed = 2300, deaths = 0, gold = -12345, partial = false, zone = "Elwynn Forest", at = 2002300 }
feature.db = { history = {}, checkpoint = record }; feature.session, feature.active = nil, false
for index = 1, 14 do feature.db.history[index] = Suite.Copy(record) end
gui.levelingView, gui.levelingScope, gui.levelingRecord = "Summary", "Current", nil
gui.frame:Show(); gui:Select("leveling")
equal(gui.levelingCards[1].caption.text, "Time played", "summary labels identify each statistic")
equal(gui.levelingCards[2].value.text, "12,345", "earned XP uses readable thousands separators")
equal(gui.levelingCards[3].value.text, "-1g 23s 45c", "net gold keeps its sign and coin units")
equal(gui.levelingLogRows[1]:IsShown(), false, "summary does not mix history paragraphs into its statistics")
local function Preview(view)
    if not WFS_JOURNAL_PREVIEW then return end
    local model = { width = gui.levelingLogPanel:GetWidth(), height = gui.levelingLogPanel:GetHeight(),
        title = gui.levelingJournalTitle.text, subtitle = gui.levelingJournalSubtitle.text, cards = {}, details = {},
        view = view, detailTop = gui.levelingDetailTop, note = gui.levelingJournalNote.text,
        noteY = -gui.levelingJournalNote.point[3], headers = {}, rows = {},
        navigation = gui.levelingLogCount:IsShown(), page = gui.levelingLogCount.text,
        navigationY = -gui.levelingLogBack.point[3] }
    for _, card in ipairs(gui.levelingCards) do if card:IsShown() and view == "Summary" then model.cards[#model.cards + 1] = { x = card.point[2], y = -card.point[3],
        width = card.width, height = card.height, label = card.caption.text, value = card.value.text, size = card.value.fontSize } end
    end
    for _, row in ipairs(gui.levelingDetails) do if row.label:IsShown() and view == "Summary" then model.details[#model.details + 1] = { label = row.label.text, value = row.value.text } end end
    for _, header in ipairs(gui.levelingColumnHeaders) do if header:IsShown() then model.headers[#model.headers + 1] = {
        x = header.point[2], y = -header.point[3], width = header.width, label = header.label.text } end end
    for _, row in ipairs(gui.levelingLogRows) do if row:IsShown() then
        local item = { y = -row.point[3], height = row.height, detail = row.detail.text, cells = {} }
        for _, text in ipairs(row.cells) do if text:IsShown() then item.cells[#item.cells + 1] = {
            x = text.point[2], width = text.width, text = text.text, align = text.justifyH } end end
        model.rows[#model.rows + 1] = item
    end end
    WFS_JOURNAL_PREVIEW(model)
end
Preview("Summary")
record.journey.deaths = 1
record.journey.lastDeath = { elapsed = 10, at = 2000000, zone = string.rep("Long zone ", 12) }
gui:RefreshLevelingLog()
equal(gui.levelingDetails[3].value.height > 24, true, "long last-death locations wrap without clipping")
equal(-gui.levelingDetails[4].value.point[3] >= -gui.levelingDetails[3].value.point[3] + gui.levelingDetails[3].value.height,
    true, "wrapped details move later rows down rather than overlap")
for _, view in ipairs({ "Loot", "Reputation", "Levels" }) do
    gui.levelingViewButtons[view].OnClick()
    equal(gui.levelingLogRows[1]:IsShown(), true, "each journey detail tab displays its recorded rows")
    equal(gui.levelingLogRows[1].cells[1].text ~= "", true, "detail rows have labeled primary data")
    Preview(view)
end
gui.levelingViewButtons.History.OnClick()
equal(gui.levelingLogCount.text, "1 / 3", "session history paginates without clipping")
Preview("History")
gui.levelingScopeButtons.Current.OnClick()
equal(gui.levelingView, "Summary", "scope buttons leave the all-session browser for the requested summary")
gui.levelingViewButtons.History.OnClick()
gui.levelingLogNext.OnClick(); gui.levelingLogRows[1].OnClick()
equal(gui.levelingRecord, 8, "history selects the actual newest-first record on later pages")
equal(gui.levelingView, "Summary", "selecting a history row opens its readable summary")
local selectedJourney = feature.db.history[8].journey; feature.db.history[8].journey = nil
gui.levelingViewButtons.Loot.OnClick()
equal(gui.levelingJournalEmpty:IsShown(), true, "legacy detail views explain missing history")
equal(gui.levelingColumnHeaders[1]:IsShown(), false, "empty-state text cannot overlap table headings")
equal(gui.levelingJournalSubtitle.text, "Details not recorded", "missing detail is not labeled as zero received items")
feature.db.history[8].journey = selectedJourney
gui.levelingScopeButtons.Overall.OnClick()
equal(gui.levelingRecord, nil, "scope navigation clears a selected historical record")
SetCombat(true); gui:RefreshLevelingLog()
equal(type(Suite.pending.levelingJournalLayout), "function", "journal geometry refresh defers during combat")
gui:Select("overview")
equal(Suite.pending.levelingJournalLayout, nil, "leaving the page cancels deferred journal layout")
SetCombat(false)
feature.db, feature.session, feature.active, feature.journeyRuntime = old.db, old.session, old.active, old.runtime
gui.levelingView, gui.levelingScope, gui.levelingRecord = old.view, old.scope, old.record
gui:Select(old.page or "overview"); gui.frame:SetShown(old.shown)
