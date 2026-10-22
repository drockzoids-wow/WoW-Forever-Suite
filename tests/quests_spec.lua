local Suite, equal, Frame, SetCombat = ...
local quests = Suite.Quests
local names = { "CreateFrame", "C_Timer", "UnitGUID", "IsShiftKeyDown", "C_GossipInfo", "Enum", "GetFileIDFromPath",
    "C_PlayerInteractionManager", "C_QuestLog",
    "GossipFrame", "QuestFrame", "QuestFrameGreetingPanel", "QuestFrameDetailPanel", "QuestFrameProgressPanel",
    "QuestFrameRewardPanel", "GetQuestID", "QuestFlagsPVP", "QuestGetAutoAccept", "AcceptQuest",
    "AcknowledgeAutoAcceptQuest", "IsQuestCompletable", "CompleteQuest", "GetQuestMoneyToGet",
    "GetNumQuestChoices", "GetQuestReward", "GetNumActiveQuests", "GetNumAvailableQuests", "GetActiveTitle",
    "GetActiveQuestID", "GetAvailableQuestInfo", "SelectActiveQuest", "SelectAvailableQuest" }
local saved = {}
for _, name in ipairs(names) do saved[name] = _G[name] end
local oldDB, oldPending = Suite.db, Suite.pending
local timers, calls, constructed = {}, {}, 0
local guid, shift, id, pvp, automatic, complete, cost, choices = "npc:one", false, 101, false, false, true, 0, 0
local active, available, options, forced = {}, {}, {}, false
local activeCount, availableCount = 0, 0
local legacyActive, legacyAvailable = {}, {}
local actionEvent
local dataRequests, dataResult = {}, true
local function Secret() return { secret = true } end
local function Called(action, value)
    calls[#calls + 1] = { action = action, value = value }
    if actionEvent then actionEvent(action, value) end
end
local function Fire(event, ...)
    if quests.events and quests.events.registered[event] then quests.events.OnEvent(quests.events, event, ...) end
end
local function TimerCount()
    local count = 0
    for _, timer in ipairs(timers) do if not timer.cancelled then count = count + 1 end end
    return count
end
local function Flush()
    for _ = 1, 50 do
        if #timers == 0 then return end
        local timer = table.remove(timers, 1)
        if not timer.cancelled then timer.callback() end
    end
    error("quest worker did not settle")
end
CreateFrame = function(...)
    assert(not InCombatLockdown(), "quest event-frame creation must defer through combat")
    constructed = constructed + 1
    local frame = saved.CreateFrame(...)
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    return frame
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
C_QuestLog = { RequestLoadQuestByID = function(questID)
    dataRequests[#dataRequests + 1] = questID
    if dataResult == "error" then error("quest data request rejected") end
    if dataResult ~= nil then Fire("QUEST_DATA_LOAD_RESULT", questID, dataResult) end
end }
UnitGUID = function() return guid end
IsShiftKeyDown = function() return shift end
Enum = { GossipOptionStatus = { Available = 0 } }
C_GossipInfo = {
    GetActiveQuests = function() return active end,
    GetAvailableQuests = function() return available end,
    GetOptions = function() return options end,
    ForceGossip = function() return forced end,
    SelectActiveQuest = function(value) Called("active", value) end,
    SelectAvailableQuest = function(value) Called("available", value) end,
    SelectOption = function(value, text, confirmed)
        equal(text, nil, "automatic gossip supplies no code")
        equal(confirmed, nil, "automatic gossip never confirms a prompt")
        Called("option", value)
    end,
}
GetQuestID = function() return id end
QuestFlagsPVP = function() return pvp end
QuestGetAutoAccept = function() return automatic end
AcceptQuest = function() Called("accept") end
AcknowledgeAutoAcceptQuest = function() Called("acknowledge") end
IsQuestCompletable = function() return complete end
CompleteQuest = function() Called("complete") end
GetQuestMoneyToGet = function() return cost end
GetNumQuestChoices = function() return choices end
GetQuestReward = function(value) Called("reward", value) end
GetNumActiveQuests = function() return activeCount end
GetNumAvailableQuests = function() return availableCount end
GetActiveTitle = function(index) return "Quest", legacyActive[index].complete end
GetActiveQuestID = function(index) return legacyActive[index].id end
GetAvailableQuestInfo = function(index) return false, 0, false, false, legacyAvailable[index].id end
SelectActiveQuest = function(index) Called("legacyActive", index) end
SelectAvailableQuest = function(index) Called("legacyAvailable", index) end
GossipFrame, QuestFrame = Frame(), Frame()
GossipFrame.IsForbidden = function(self) return self.forbidden end
QuestFrame.IsForbidden = function(self) return self.forbidden end
QuestFrameGreetingPanel, QuestFrameDetailPanel = Frame(), Frame()
QuestFrameProgressPanel, QuestFrameRewardPanel = Frame(), Frame()
local panels = { gossip = GossipFrame, greeting = QuestFrameGreetingPanel,
    detail = QuestFrameDetailPanel, progress = QuestFrameProgressPanel, reward = QuestFrameRewardPanel }
local events = { gossip = "GOSSIP_SHOW", greeting = "QUEST_GREETING", detail = "QUEST_DETAIL",
    progress = "QUEST_PROGRESS", reward = "QUEST_COMPLETE" }
local function Show(mode)
    for _, panel in pairs(panels) do panel:Hide() end
    QuestFrame:SetShown(mode ~= "gossip")
    panels[mode]:Show(); Fire(events[mode])
end
local function Fresh()
    quests:EndVisit(); calls = {}; actionEvent = nil
    dataRequests, dataResult = {}, true
    guid, shift, id, pvp, automatic, complete, cost, choices = "npc:one", false, 101, false, false, true, 0, 0
    active, available, options, forced = {}, {}, {}, false
    activeCount, availableCount, legacyActive, legacyAvailable = 0, 0, {}, {}
    GossipFrame.forbidden, QuestFrame.forbidden = false, false
    Suite.db.autoVendor = false
    Suite.db.autoQuestPickup, Suite.db.autoQuestTurnIn, Suite.db.autoGossip = true, true, true
    quests:Apply()
end
Suite.db = Suite.InitializeDB(nil); Suite.pending = {}
equal(Suite.db.autoQuestPickup, false, "quest pickup starts off")
equal(Suite.db.autoQuestTurnIn, false, "quest turn-in starts off")
equal(Suite.db.autoGossip, false, "gossip starts off independently")
equal(Suite.db.autoVendor, false, "vendor conversations start off independently")
equal(Suite.Profiles:Settings({ autoVendor = true }).autoVendor, true, "shop opening participates in copied settings profiles")
equal(Suite.Profiles:Settings({ autoVendor = Secret() }).autoVendor, false, "restricted shop preferences restore the off default")
quests:Apply()
equal(constructed, 0, "disabled quest module creates no event frame")
SetCombat(true); Suite.db.autoQuestPickup = true; quests:Apply()
equal(constructed, 0, "quest enabling in combat creates no frame")
equal(type(Suite.pending.quests), "function", "quest enable waits for combat")
Suite.db.autoQuestPickup = false; quests:Apply()
equal(Suite.pending.quests, nil, "disable cancels pending quest enable")
SetCombat(false); Fresh()
equal(constructed, 1, "one anonymous event frame serves all quest options")
equal(quests.events.registered.QUEST_ACCEPT_CONFIRM, nil, "shared acceptance confirmations stay native")
Show("detail")
equal(#calls, 0, "quest event waits until native show completes")
Fire("QUEST_DETAIL"); Fire("QUEST_ITEM_UPDATE"); Fire("QUEST_LOG_UPDATE")
equal(TimerCount(), 1, "quest event bursts coalesce")
Flush(); equal(calls[1].action, "accept", "visible quest details auto-accept")
Fire("QUEST_DETAIL"); Fire("QUEST_ITEM_UPDATE"); Flush()
equal(#calls, 1, "same stage is requested once despite duplicate events")
equal(TimerCount(), 0, "completed work leaves no idle timer")

-- A cold quest may show its detail panel before its data request completes.
Fresh(); dataResult = nil; Show("detail"); Flush()
equal(#calls, 0, "unloaded quest details cannot submit acceptance early")
equal(dataRequests[1], 101, "visible current quest requests its own data")
equal(TimerCount(), 0, "waiting for quest data uses no polling timer")
Fire("QUEST_DETAIL"); Fire("QUEST_ITEM_UPDATE"); Fire("QUEST_LOG_UPDATE"); Flush()
equal(#dataRequests, 1, "duplicate detail and metadata events share one pending data request")
Fire("QUEST_DATA_LOAD_RESULT", 102, true); Fire("QUEST_DATA_LOAD_RESULT", Secret(), true)
Fire("QUEST_DATA_LOAD_RESULT", 101, Secret()); Flush()
equal(#calls, 0, "unrelated or unreadable data results cannot authorize pickup")
Fire("QUEST_DATA_LOAD_RESULT", 101, true)
equal(#calls, 0, "data completion waits for native handlers before accepting")
Flush(); equal(calls[1].action, "accept", "matching successful data load resumes pickup")
Fire("QUEST_DATA_LOAD_RESULT", 101, true); Fire("QUEST_DETAIL"); Flush()
equal(#calls, 1, "duplicate successful data events cannot resubmit acceptance")

Fresh(); dataResult = false; Show("detail"); Flush()
equal(#calls, 0, "failed quest data load leaves the offer available manually")
Fire("QUEST_LOG_UPDATE"); Flush()
equal(#dataRequests, 1, "failed loads do not spin on log updates")
dataResult = true; Show("detail"); Flush()
equal(#dataRequests, 2, "a newly opened detail offer can retry a failed load")
equal(#calls, 1, "reopened failed load recovers without changing NPC range")
Fresh(); dataResult = "error"; Show("detail"); Flush()
equal(#calls, 0, "rejected data request does not accept an unready offer")
equal(TimerCount(), 0, "rejected data request leaves no recurring timer")

local savedDataAPI = C_QuestLog
C_QuestLog = nil; Fresh(); Show("detail"); Flush()
equal(calls[1].action, "accept", "clients without the loading API retain guarded native acceptance")
C_QuestLog = savedDataAPI
for _, change in ipairs({ "close", "npc", "quest", "panel", "shift", "combat", "world", "disable", "pickupOff", "confirmation", "pvp", "flags", "forbidden" }) do
    Fresh(); dataResult = nil; Show("detail"); Flush()
    if change == "close" then Fire("QUEST_FINISHED")
    elseif change == "npc" then guid = "npc:two"
    elseif change == "quest" then id = 102
    elseif change == "panel" then QuestFrameDetailPanel:Hide()
    elseif change == "shift" then shift = true
    elseif change == "combat" then SetCombat(true); Fire("PLAYER_REGEN_DISABLED")
    elseif change == "world" then Fire("PLAYER_ENTERING_WORLD")
    elseif change == "disable" then
        Suite.db.autoQuestPickup, Suite.db.autoQuestTurnIn, Suite.db.autoGossip = false, false, false; quests:Apply()
    elseif change == "pickupOff" then Suite.db.autoQuestPickup = false; quests:Apply()
    elseif change == "confirmation" then Fire("GOSSIP_CONFIRM")
    elseif change == "pvp" then pvp = true
    elseif change == "flags" then automatic = Secret()
    elseif change == "forbidden" then QuestFrame.forbidden = true end
    Fire("QUEST_DATA_LOAD_RESULT", 101, true); Flush()
    equal(#calls, 0, "late quest data respects " .. change .. " cancellation")
    if change == "combat" then SetCombat(false); Fire("QUEST_ITEM_UPDATE"); Flush()
        equal(#calls, 0, "data completion from combat never replays afterward") end
end

Fresh(); automatic = true; Show("detail"); Flush()
equal(calls[1].action, "acknowledge", "native auto-accepted quests are acknowledged")
Fresh(); automatic = true; local acknowledge = AcknowledgeAutoAcceptQuest; AcknowledgeAutoAcceptQuest = nil
Show("detail"); Flush(); equal(#calls, 0, "missing acknowledgment never falls back to accepting an automatic quest")
AcknowledgeAutoAcceptQuest = acknowledge
Fresh(); pvp = true; Show("detail"); Flush(); equal(#calls, 0, "PvP acceptance confirmation stays manual")
Fresh(); pvp = Secret(); Show("detail"); Flush(); equal(#calls, 0, "restricted PvP flags are not compared")
Fresh(); automatic = Secret(); Show("detail"); Flush(); equal(#calls, 0, "restricted auto-accept flags stop pickup")
Fresh(); Show("detail"); QuestFrameDetailPanel:Hide(); Flush(); equal(#calls, 0, "hidden item/area offers are not accepted")
Fresh(); Show("detail"); id = 102; Flush(); equal(#calls, 0, "changed quest identity cancels stale acceptance")
Fresh(); Show("detail"); guid = "npc:two"; Flush(); equal(#calls, 0, "changed NPC identity cancels stale acceptance")
Fresh(); id = Secret(); Show("detail"); Flush(); equal(#calls, 0, "secret quest IDs do not reach actions or keys")
Fresh(); id = 0; Show("detail"); Flush(); equal(#calls, 0, "missing quest IDs stay manual")
Fresh(); guid = Secret(); Show("detail"); Flush(); equal(#calls, 0, "secret NPC identities stop automation")
Fresh(); guid = nil; Show("detail"); Flush(); equal(calls[1].action, "accept", "ordinary dialogs can lack an NPC GUID")

Fresh(); Show("progress"); Flush(); equal(calls[1].action, "complete", "completable quests advance to rewards")
Show("reward"); Flush(); equal(calls[2].action, "reward", "reward event finishes ready turn-in")
equal(calls[2].value, 0, "no-choice quests use native zero reward index")
Fresh(); choices = 1; Show("reward"); Flush(); equal(calls[1].value, 1, "single reward uses native first index")
Fresh(); choices = 2; Show("reward"); Flush(); equal(#calls, 0, "multiple rewards remain manual")
Fresh(); choices = Secret(); Show("reward"); Flush(); equal(#calls, 0, "secret reward count stays manual")
Fresh(); choices = 0/0; Show("reward"); Flush(); equal(#calls, 0, "nonfinite reward count stays manual")
Fresh(); choices = 0.5; Show("reward"); Flush(); equal(#calls, 0, "fractional reward count stays manual")
Fresh(); choices = nil; Show("reward"); Flush(); equal(#calls, 0, "missing reward count stays manual")
choices = 1; Fire("QUEST_ITEM_UPDATE"); Flush(); equal(calls[1].value, 1, "late reward data retries only the current stage")
Fire("QUEST_COMPLETE"); Fire("QUEST_ITEM_UPDATE"); Flush(); equal(#calls, 1, "duplicate reward events cannot double turn-in")
Fresh(); complete = false; Show("progress"); Flush(); equal(#calls, 0, "unfinished quests are not completed")
Fresh(); complete = Secret(); Show("progress"); Flush(); equal(#calls, 0, "secret completion state stays manual")
Fresh(); cost = 100; Show("progress"); Flush(); Show("reward"); Flush(); equal(#calls, 0, "gold-cost quests stay manual at both steps")
Fresh(); cost = Secret(); Show("reward"); Flush(); equal(#calls, 0, "secret quest costs stop turn-in")
Fresh(); local getter = GetNumQuestChoices; GetNumQuestChoices = nil
Show("reward"); Flush(); equal(#calls, 0, "missing legacy reward API stays manual"); GetNumQuestChoices = getter
Fresh(); local accept = AcceptQuest; AcceptQuest = nil
Show("detail"); Flush(); equal(#calls, 0, "missing legacy acceptance API stays manual"); AcceptQuest = accept
Fire("QUEST_ITEM_UPDATE"); Flush(); equal(#calls, 1, "later capability/item event can retry an unrequested stage")

Fresh()
active = { { questID = 200, isComplete = false, isIgnored = false }, { questID = 201, isComplete = true, isIgnored = false } }
available = { { questID = 300, isIgnored = false, isTrivial = true } }
Show("gossip"); Flush(); equal(calls[1].action, "active", "ready turn-ins precede available quests")
equal(calls[1].value, 201, "modern active selection uses quest ID rather than row index")
id = 201; Show("progress"); Flush(); Show("reward"); Flush(); Fire("QUEST_FINISHED")
active = { { questID = 200, isComplete = false, isIgnored = false } }
Show("gossip"); Flush(); equal(calls[4].value, 300, "next gossip page picks up even a trivial quest")
id = 300; Show("detail"); Flush(); Fire("QUEST_FINISHED")
Show("gossip"); Flush(); equal(#calls, 5, "repeatable quest is not selected twice in one conversation")
Fire("GOSSIP_CLOSED", false); Show("gossip"); Flush(); equal(#calls, 6, "new conversation can repeat a quest")

Fresh(); Enum.PlayerInteractionType = { Gossip = 3, QuestGiver = 4 }
local gossipInteraction, questInteraction = true, false
C_PlayerInteractionManager = { IsInteractingWithNpcOfType = function(kind)
    if kind == 3 then return gossipInteraction else return questInteraction end
end }
available = { { questID = 301, isIgnored = false } }; Show("gossip"); Flush()
Fire("GOSSIP_CLOSED", true); id = 301; Show("detail"); Flush()
QuestFrame:Hide(); QuestFrameDetailPanel:Hide(); Fire("QUEST_FINISHED"); Flush()
equal(quests.visit ~= nil, true, "continuing native interaction retains repeatable attempt history")
gossipInteraction, questInteraction = false, false
Fire("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", 4); Flush()
equal(quests.visit, nil, "true native quest closing clears list-origin state")
gossipInteraction = true; Show("gossip"); Flush()
equal(#calls, 3, "same NPC can offer a repeatable again after true quest close")
GossipFrame:Hide(); gossipInteraction = Secret(); Fire("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", 3); Flush()
equal(quests.visit ~= nil, true, "restricted native interaction status cannot end a continuing visit")
gossipInteraction = false; Fire("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", Secret()); Flush()
equal(quests.visit ~= nil, true, "restricted interaction kind is never compared")
Fire("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", 5); Flush()
equal(quests.visit ~= nil, true, "unrelated native interaction closing does not clear quest history")
Fire("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", 3); Flush()
equal(quests.visit, nil, "true gossip interaction closing clears history")
C_PlayerInteractionManager = nil

Fresh(); available = { { questID = 333, isIgnored = true }, { questID = 334, isIgnored = false } }
Show("gossip"); Flush(); equal(calls[1].value, 334, "ignored quests are skipped")
Fresh(); active = { { questID = Secret(), isComplete = true, isIgnored = false } }
available = { { questID = 334, isIgnored = Secret() } }
Show("gossip"); Flush(); equal(#calls, 0, "secret quest IDs and ignored flags cannot select quests")
Fresh(); active = Secret(); Show("gossip"); Flush(); equal(#calls, 0, "secret quest lists stay manual")
Fresh(); available = { [2] = { questID = 334, isIgnored = false } }
Show("gossip"); Flush(); equal(#calls, 0, "sparse quest lists stay manual")

Fresh(); options = { { gossipOptionID = 900, orderIndex = 7, status = 0 } }
Show("gossip"); Flush(); equal(calls[1].value, 900, "gossip selects stable option ID rather than order index")
Fire("GOSSIP_OPTIONS_REFRESHED"); Flush(); equal(#calls, 1, "option refresh cannot repeat a submitted option")
Fresh(); options = { { gossipOptionID = 900, status = 0 }, { gossipOptionID = 901, status = 0 } }
Show("gossip"); Flush(); equal(#calls, 0, "multiple gossip choices stay manual")
Fresh(); options = { { gossipOptionID = 900, status = 1 } }; Show("gossip"); Flush()
equal(#calls, 0, "unavailable gossip option is not selected")
options[1].status = 0; Fire("GOSSIP_OPTIONS_REFRESHED"); Flush()
equal(#calls, 1, "refreshed available option can be selected")
Fresh(); options = { { gossipOptionID = Secret(), status = 0 } }; Show("gossip"); Flush()
equal(#calls, 0, "secret gossip ID is not used")
Fresh(); options = { { gossipOptionID = 900, status = Secret() } }; Show("gossip"); Flush()
equal(#calls, 0, "secret gossip status is not compared")
Fresh(); forced = true; options = { { gossipOptionID = 900, status = 0 } }; Show("gossip"); Flush()
equal(#calls, 0, "native ForceGossip keeps the conversation open")
Fresh(); forced = Secret(); options = { { gossipOptionID = 900, status = 0 } }; Show("gossip"); Flush()
equal(#calls, 0, "secret ForceGossip stays manual")
Fresh(); options = { { gossipOptionID = 900, status = 0 } }
active = { { questID = 200, isComplete = false, isIgnored = false } }; Show("gossip"); Flush()
equal(#calls, 0, "unfinished quest entries prevent gossip from hiding the menu")
Fresh(); options = { { gossipOptionID = 900, status = 0 } }; Suite.db.autoGossip = false; quests:Apply()
Show("gossip"); Flush(); equal(#calls, 0, "gossip switch is independent")
Suite.db.autoQuestPickup = false; Suite.db.autoGossip = true; quests:Apply()
Show("detail"); Flush(); equal(#calls, 0, "pickup switch is independent")
Suite.db.autoQuestTurnIn = false; quests:Apply(); Show("reward"); Flush()
equal(#calls, 0, "turn-in switch is independent")

Fresh(); activeCount, availableCount = 2, 1
legacyActive = { { id = 410, complete = false }, { id = 411, complete = true } }; legacyAvailable = { { id = 412 } }
Show("greeting"); Flush(); equal(calls[1].action, "legacyActive", "native quest greetings support turn-in")
equal(calls[1].value, 2, "legacy active selection uses row index")
Show("detail"); Flush(); Show("greeting"); Flush()
equal(calls[3].action, "legacyAvailable", "greetings proceed to available quests")
equal(calls[3].value, 1, "legacy available selection uses row index")
Fresh(); activeCount = Secret(); Show("greeting"); Flush(); equal(#calls, 0, "restricted greeting counts stay manual")

Fresh(); shift = true; Show("detail"); shift = false; Flush()
equal(#calls, 0, "Shift at interaction remains latched after release")
Fire("QUEST_ITEM_UPDATE"); Flush(); equal(#calls, 0, "later events cannot defeat Shift bypass")
Fire("QUEST_FINISHED"); Show("detail"); Flush(); equal(#calls, 1, "new direct conversation clears Shift bypass")
Fresh(); Show("detail"); shift = true; Flush(); equal(#calls, 0, "Shift just before execution also pauses")
Fresh(); shift = Secret(); Show("detail"); Flush(); equal(#calls, 0, "restricted modifier state stops automation")
Fresh(); Show("detail"); Fire("QUEST_FINISHED"); Flush(); equal(#calls, 0, "quest close cancels queued acceptance")
Fresh(); options = { { gossipOptionID = 900, status = 0 } }; Show("gossip"); Fire("GOSSIP_CLOSED", false); Flush()
equal(#calls, 0, "gossip close cancels queued selection")
Fresh(); Show("detail"); SetCombat(true); Fire("PLAYER_REGEN_DISABLED"); Flush()
equal(#calls, 0, "combat entry cancels queued quest work")
Fire("QUEST_DETAIL"); SetCombat(false); Fire("QUEST_ITEM_UPDATE"); Flush()
equal(#calls, 0, "combat dialogs do not replay after combat")
Fresh(); Show("detail"); Suite.db.autoQuestPickup, Suite.db.autoQuestTurnIn, Suite.db.autoGossip = false, false, false
quests:Apply(); Flush(); equal(#calls, 0, "disable cancels queued work")
equal(next(quests.events.registered), nil, "fully disabled module unregisters events")
equal(TimerCount(), 0, "disable leaves no timers")
Fresh(); options = { { gossipOptionID = 900, status = 0 } }; Show("gossip"); Fire("GOSSIP_CONFIRM"); Flush()
equal(#calls, 0, "native confirmation cancels queued gossip")
Fire("GOSSIP_OPTIONS_REFRESHED"); Flush(); equal(#calls, 0, "confirmations cannot be advanced by refresh events")
Fresh(); Show("gossip"); Fire("GOSSIP_ENTER_CODE"); Flush(); equal(#calls, 0, "code entry stays manual")
Fresh(); Show("detail"); QuestFrame.forbidden = true; Flush(); equal(#calls, 0, "forbidden dialogs are left alone")
Fresh(); Show("detail"); QuestFrame.forbidden = Secret(); Flush(); equal(#calls, 0, "restricted forbidden predicates stay manual")
Fresh(); Show("detail"); Fire("PLAYER_ENTERING_WORLD"); Flush(); equal(#calls, 0, "world changes cancel stale dialogs")

Fresh(); available = { { questID = 501, isIgnored = false } }
actionEvent = function(action)
    if action == "available" then Fire("GOSSIP_CLOSED", true); id = 501; Show("detail")
    elseif action == "accept" then Fire("QUEST_FINISHED") end
end
Show("gossip"); Flush(); equal(#calls, 2, "synchronous selection/acceptance transitions complete safely")
equal(quests.visit.fromList, true, "list origin survives synchronous quest finish")
Show("gossip"); Flush(); equal(#calls, 2, "synchronous repeatable cycle cannot resubmit a quest")

Fresh(); actionEvent = function(action)
    if action == "option" then Fire("GOSSIP_CLOSED", true); Fire("GOSSIP_SHOW") end
end
-- Native menus can return the same option without closing the interaction.
options = { { gossipOptionID = 900, status = 0 } }; Show("gossip"); Flush()
equal(#calls, 1, "returning the same gossip option stops without polling")
Fresh(); guid = nil
actionEvent = function(action, value)
    if action == "option" then
        Fire("GOSSIP_CLOSED", true); options = { { gossipOptionID = value + 1, status = 0 } }; Fire("GOSSIP_SHOW")
    end
end
options = { { gossipOptionID = 900, status = 0 } }; Show("gossip"); Flush()
equal(#calls, 20, "long conversation is bounded to twenty automatic actions")
equal(TimerCount(), 0, "action cap leaves no recurring work")

local function Shop()
    Fresh()
    Suite.db.autoQuestPickup, Suite.db.autoQuestTurnIn, Suite.db.autoGossip = false, false, false
    Suite.db.autoVendor = true
    GetFileIDFromPath = function(path)
        equal(path, "Interface\\GossipFrame\\VendorGossipIcon", "shop icon resolves from the native interface path")
        return 132060
    end
    forced = true
    options = { { gossipOptionID = 800, orderIndex = 7, status = 0, icon = 132060, name = Secret() },
        { gossipOptionID = 801, status = 0, icon = 136243 } }
    active = { { questID = 200, isComplete = false, isIgnored = false } }
    available = { { questID = 201, isIgnored = false } }
    quests:Apply()
end
Shop(); Show("gossip"); equal(#calls, 0, "shop opening waits for the native show handler"); Flush()
equal(calls[1] and calls[1].action, "option", "vendor-only setting selects a shop beside other services and quests")
equal(calls[1].value, 800, "vendor opening uses option ID, independent of localized text and row index")
Fire("GOSSIP_SHOW"); Fire("GOSSIP_OPTIONS_REFRESHED"); Flush()
equal(#calls, 1, "duplicate vendor events cannot repeat the shop request")
equal(TimerCount(), 0, "shop opening leaves no idle timer")
Fire("GOSSIP_CLOSED", false); Show("gossip"); Flush()
equal(#calls, 2, "closing permits another shop visit to the same vendor")
Shop(); Show("gossip"); Flush(); Fire("GOSSIP_CLOSED", true); Fire("MERCHANT_CLOSED")
equal(quests.visit, nil, "closing the shop ends a continuing gossip visit without interaction-manager reads")
Show("gossip"); Flush()
equal(#calls, 2, "the same vendor opens again after closing its shop")
Shop(); options = { options[1] }; Show("gossip"); Flush()
equal(#calls, 1, "a single forced shop choice opens even with quests listed")
Shop(); Suite.db.autoVendor = false; quests:Apply(); Show("gossip"); Flush()
equal(#calls, 0, "vendor opening does not follow repair or other quest preferences")
equal(next(quests.events.registered), nil, "vendor-only disable unregisters the shared events")
Shop(); Show("gossip"); Suite.db.autoVendor = false; quests:Apply(); Flush()
equal(#calls, 0, "disabling vendor opening cancels a queued shop request")
Shop(); shift = true; Show("gossip"); shift = false; Fire("GOSSIP_OPTIONS_REFRESHED"); Flush()
equal(#calls, 0, "Shift latches across the vendor conversation")
Fire("GOSSIP_CLOSED", false); Show("gossip"); Flush()
equal(#calls, 1, "a fresh vendor visit releases the Shift bypass")
Shop(); Show("gossip"); shift = true; Flush()
equal(#calls, 0, "Shift sampled before the shop request pauses it")
Shop(); Show("gossip"); SetCombat(true); Fire("PLAYER_REGEN_DISABLED"); Flush(); SetCombat(false)
Fire("PLAYER_REGEN_ENABLED"); Flush()
equal(#calls, 0, "vendor requests cancel in combat without replay")
Shop(); Show("gossip"); GossipFrame:Hide(); Flush()
equal(#calls, 0, "hidden vendor menus cannot open shops")
Shop(); Show("gossip"); guid = "npc:two"; Flush()
equal(#calls, 0, "vendor requests reject a changed NPC")
Shop(); actionEvent = function() Fire("GOSSIP_CLOSED", true); Fire("GOSSIP_SHOW") end
Show("gossip"); Flush()
equal(#calls, 1, "synchronous returning shop menus cannot loop")
for _, event in ipairs({ "GOSSIP_CONFIRM", "GOSSIP_ENTER_CODE", "PLAYER_ENTERING_WORLD" }) do
    Shop(); Show("gossip"); Fire(event); Flush()
    equal(#calls, 0, event .. " cancels automatic shop opening")
end
for _, value in ipairs({ 1, 2, Secret() }) do
    Shop(); options[1].status = value; Show("gossip"); Flush()
    equal(#calls, 0, "unavailable, locked and restricted shops stay manual")
end
Shop(); options[2].icon = 132060; Show("gossip"); Flush()
equal(#calls, 0, "multiple shop options require a choice")
Shop(); options[1].icon = 136243; options[1].overrideIconID = 132060; Show("gossip"); Flush()
equal(#calls, 0, "a decorative override cannot identify a shop")
for _, field in ipairs({ "icon", "gossipOptionID" }) do
    Shop(); options[1][field] = Secret(); Show("gossip"); Flush()
    equal(#calls, 0, "restricted vendor " .. field .. " stays manual")
end
Shop(); options[2].icon = Secret(); Show("gossip"); Flush()
equal(#calls, 0, "an unknown second icon cannot rule out another shop")
Shop(); options = { [2] = options[1] }; Show("gossip"); Flush()
equal(#calls, 0, "sparse vendor option lists stay manual")
Shop(); C_GossipInfo.GetOptions = function() error("unavailable") end; Show("gossip"); Flush()
equal(#calls, 0, "rejected option queries cannot trigger a shop request")
C_GossipInfo.GetOptions = function() return options end
for _, result in ipairs({ 0, Secret(), false }) do
    Shop(); GetFileIDFromPath = function() return result end; Show("gossip"); Flush()
    equal(#calls, 0, "unavailable or restricted native icon IDs stay manual")
end
Shop(); GetFileIDFromPath = nil; Show("gossip"); Flush()
equal(#calls, 0, "missing native icon lookup stays manual")
Shop(); GetFileIDFromPath = function() error("unavailable") end; Show("gossip"); Flush()
equal(#calls, 0, "rejected native icon lookup stays manual")
Shop(); Suite.db.autoQuestTurnIn = true; active[1].isComplete = true; Show("gossip"); Flush()
equal(calls[1].action, "active", "enabled ready turn-ins precede vendor opening")
Shop(); Suite.db.autoQuestPickup = true; Show("gossip"); Flush()
equal(calls[1].action, "available", "enabled quest pickup precedes vendor opening")
Fresh()

Suite.GUI:OpenPage("quests")
equal(Suite.GUI.page, "quests", "quests have their own settings page")
equal(Suite.GUI.tabs.quests.label.text, "Quests & Loot", "sidebar groups quest and loot tools")
equal(Suite.GUI.rows[1].label.text, "Automatically pick up quests", "first quest control exposes pickup")
equal(Suite.GUI.rows[2].label.text, "Automatically turn in quests", "second quest control exposes turn-in")
equal(Suite.GUI.rows[3].label.text, "Automatically advance gossip", "third quest control exposes gossip")
local oldApply = Suite.Apply
Suite.Apply = function() quests:Apply() end
Suite.GUI.rows[1].OnClick(); equal(Suite.db.autoQuestPickup, false, "pickup control saves its independent setting")
Suite.GUI.rows[2].OnClick(); equal(Suite.db.autoQuestTurnIn, false, "turn-in control saves its independent setting")
Suite.GUI.rows[3].OnClick(); equal(Suite.db.autoGossip, false, "gossip control saves its independent setting")
Suite.Apply = oldApply
equal(-Suite.GUI.tabs.chat.point[3] + Suite.GUI.tabs.chat.height < Suite.GUI.frame.height - 77 - 35,
    true, "all fourteen tabs leave room for the sidebar footer")
SlashCmdList.WOWFOREVERSUITE("quests"); equal(Suite.GUI.page, "quests", "quest slash shortcut opens settings")
SlashCmdList.WOWFOREVERSUITE("gossip"); equal(Suite.GUI.page, "quests", "gossip slash shortcut opens settings")

Suite.GUI:OpenPage("vendor")
equal(Suite.GUI.rows[6].label.text, "Automatically open vendor shops", "vendor page exposes the independent shop setting")
Suite.Apply = function() quests:Apply() end
Suite.GUI.rows[6].OnClick()
equal(Suite.db.autoVendor, true, "vendor control saves its own preference")
equal(Suite.db.autoGossip, false, "vendor control leaves general gossip disabled")
Suite.Apply = oldApply
local shopResults = Suite.SettingsCatalog:Search("auto talk")
equal(shopResults[1].key, "autoVendor", "auto talk search finds the vendor setting")

Suite.db.autoQuestPickup, Suite.db.autoQuestTurnIn, Suite.db.autoGossip = false, false, false
Suite.db.autoVendor = false
quests:Apply(); Flush(); SetCombat(false)
Suite.db, Suite.pending = oldDB, oldPending
for _, name in ipairs(names) do _G[name] = saved[name] end
