local _, Suite = ...
local Quests = {}
Suite.Quests = Quests
table.insert(Suite.modules, Quests)

local function Read(callback, ...)
    if type(callback) ~= "function" then return end
    local ok, a, b, c, d, e = pcall(callback, ...)
    if ok then return a, b, c, d, e end
end

local function Yes(value)
    return Suite.IsReadable(value) and value == true
end

local function No(value)
    return Suite.IsReadable(value) and value == false
end

local function Count(value, limit)
    return Suite.IsReadable(value) and type(value) == "number" and value == value
        and value >= 0 and value <= limit and value == math.floor(value)
end

local function ID(value)
    return Count(value, 2147483647) and value > 0
end

local function Enabled()
    local db = Suite.db
    return db and (Yes(db.autoQuestPickup) or Yes(db.autoQuestTurnIn) or Yes(db.autoGossip) or Yes(db.autoVendor))
end

local function Shown(frame)
    if not frame or type(frame.IsShown) ~= "function" then return false end
    if frame.IsForbidden and not No(frame:IsForbidden()) then return false end
    return Yes(frame:IsShown())
end

local function List(value)
    if not Suite.IsReadable(value) or type(value) ~= "table" then return nil end
    local size = 0
    for key, row in pairs(value) do
        if not Count(key, 100) or key == 0 or not Suite.IsReadable(row) or type(row) ~= "table" then return nil end
        size = size + 1
    end
    -- Reject sparse/malformed lists before using their lengths or rows.
    for index = 1, size do if value[index] == nil then return nil end end
    return value
end

function Quests:Cancel()
    if self.timer then self.timer:Cancel(); self.timer = nil end
end

function Quests:EndVisit()
    self:Cancel()
    self.stage, self.visit = nil, nil
end

function Quests:CheckClosed()
    if not self.visit or InCombatLockdown() or not C_Timer or type(C_Timer.NewTimer) ~= "function" then return end
    self:Cancel()
    local visit = self.visit
    self.timer = C_Timer.NewTimer(0, function()
        self.timer = nil
        if not self.active or self.visit ~= visit or InCombatLockdown() then return end
        local kinds = Enum and Enum.PlayerInteractionType
        local api = C_PlayerInteractionManager and C_PlayerInteractionManager.IsInteractingWithNpcOfType
        -- A quest-finished event also occurs between pages. Retain attempts during native continuation.
        if kinds and Count(kinds.Gossip, 100) and Count(kinds.QuestGiver, 100)
            and No(Read(api, kinds.Gossip)) and No(Read(api, kinds.QuestGiver))
            and not Shown(GossipFrame) and not Shown(QuestFrame) then self:EndVisit()
        else self:Queue() end
    end)
end

function Quests:PauseIfShift()
    -- Latch the bypass so releasing Shift before the worker runs cannot accept a quest.
    if self.visit and not No(Read(IsShiftKeyDown)) then self.visit.paused = true end
    return not self.visit or self.visit.paused
end

function Quests:SetStage(mode)
    self:Cancel()
    local guid = Read(UnitGUID, mode == "gossip" and "npc" or "questnpc")
    if not Suite.IsReadable(guid) or (guid ~= nil and type(guid) ~= "string") then self:EndVisit(); return end
    if not self.visit or (guid and self.visit.guid and guid ~= self.visit.guid) then
        self.visit = { guid = guid, sent = {}, actions = 0 }
        self.stage = nil
    elseif guid then self.visit.guid = guid end
    local id
    if mode ~= "gossip" and mode ~= "greeting" then
        id = Read(GetQuestID)
        if not ID(id) then self.stage = nil; return end
    end
    local old = self.stage
    if not old or old.mode ~= mode or old.id ~= id or old.dataFailed then
        self.stage = { mode = mode, id = id }
    end
    if not self:PauseIfShift() then self:Queue() end
end

function Quests:Request(key, callback, argument, fromList)
    local visit = self.visit
    if not visit or visit.sent[key] or visit.actions >= 20 or type(callback) ~= "function" then return false end
    -- Mark before calling: native quest/gossip events can fire synchronously.
    visit.sent[key], visit.actions = true, visit.actions + 1
    if fromList then visit.fromList = true end
    if self.stage then self.stage.requested = true end
    if argument ~= nil then callback(argument) else callback() end
    return true
end

local function VendorOption(options)
    -- The API exposes the base icon, not an NPC service type. Resolve the native
    -- shop icon on this client instead of depending on text or a fixed file ID.
    local icon = Read(GetFileIDFromPath, "Interface\\GossipFrame\\VendorGossipIcon")
    if not ID(icon) then return end
    local vendor
    for _, option in ipairs(options) do
        -- Unknown icons cannot rule out a second shop entry.
        if not ID(option.icon) then return end
        if option.icon == icon then
            if vendor then return end
            vendor = option
        end
    end
    return vendor
end

function Quests:Gossip()
    if not Shown(GossipFrame) then return end
    local api = C_GossipInfo or {}
    local active, available = List(Read(api.GetActiveQuests)), List(Read(api.GetAvailableQuests))
    if not active or not available then return end
    if Yes(Suite.db.autoQuestTurnIn) then
        for _, quest in ipairs(active) do
            if ID(quest.questID) and Yes(quest.isComplete) and No(quest.isIgnored) then
                if self:Request("active:" .. quest.questID, api.SelectActiveQuest, quest.questID, true) then return end
            end
        end
    end
    if Yes(Suite.db.autoQuestPickup) then
        for _, quest in ipairs(available) do
            if ID(quest.questID) and No(quest.isIgnored) then
                if self:Request("available:" .. quest.questID, api.SelectAvailableQuest, quest.questID, true) then return end
            end
        end
    end
    if not Yes(Suite.db.autoVendor) and not Yes(Suite.db.autoGossip) then return end
    local options = List(Read(api.GetOptions))
    if not options then return end
    local option = Yes(Suite.db.autoVendor) and VendorOption(options) or nil
    if not option then
        -- General conversation still preserves quest entries and deliberate menus.
        if not Yes(Suite.db.autoGossip) or #active > 0 or #available > 0
            or #options ~= 1 or not No(Read(api.ForceGossip)) then return end
        option = options[1]
    end
    local status = Enum and Enum.GossipOptionStatus and Enum.GossipOptionStatus.Available
    if not Count(status, 10) or not Suite.IsReadable(option.status) or option.status ~= status
        or not ID(option.gossipOptionID) then return end
    self:Request("option:" .. option.gossipOptionID, api.SelectOption, option.gossipOptionID)
end

function Quests:Greeting()
    if not Shown(QuestFrame) or not Shown(QuestFrameGreetingPanel) then return end
    local active, available = Read(GetNumActiveQuests), Read(GetNumAvailableQuests)
    if not Count(active, 100) or not Count(available, 100) then return end
    if Yes(Suite.db.autoQuestTurnIn) then
        for index = 1, active do
            local _, complete = Read(GetActiveTitle, index)
            local id = Read(GetActiveQuestID, index)
            if ID(id) and Yes(complete) and self:Request("active:" .. id, SelectActiveQuest, index, true) then return end
        end
    end
    if Yes(Suite.db.autoQuestPickup) then
        for index = 1, available do
            local _, _, _, _, id = Read(GetAvailableQuestInfo, index)
            if ID(id) and self:Request("available:" .. id, SelectAvailableQuest, index, true) then return end
        end
    end
end

function Quests:DetailReady(stage)
    local load = C_QuestLog and C_QuestLog.RequestLoadQuestByID
    if type(load) ~= "function" or stage.dataReady then return true end
    if not stage.dataRequested then
        -- The result may arrive synchronously; retain the stage before requesting it.
        stage.dataRequested = true
        local ok = pcall(load, stage.id)
        if not ok and self.stage == stage then stage.dataFailed = true end
    end
    return false
end

function Quests:Quest(stage)
    if not Shown(QuestFrame) then return end
    local id = Read(GetQuestID)
    if not ID(id) or id ~= stage.id then return end
    if stage.mode == "detail" then
        if not Yes(Suite.db.autoQuestPickup) or not Shown(QuestFrameDetailPanel)
            or not No(Read(QuestFlagsPVP)) then return end
        local automatic = Read(QuestGetAutoAccept)
        if not Yes(automatic) and not No(automatic) then return end
        local accept = AcceptQuest
        if Yes(automatic) then accept = AcknowledgeAutoAcceptQuest end
        if type(accept) == "function" and self:DetailReady(stage) then
            self:Request("accept:" .. id, accept)
        end
    elseif Yes(Suite.db.autoQuestTurnIn) then
        local cost = Read(GetQuestMoneyToGet)
        if not Count(cost, 1000000000000) or cost > 0 then return end
        if stage.mode == "progress" and Shown(QuestFrameProgressPanel) and Yes(Read(IsQuestCompletable)) then
            self:Request("complete:" .. id, CompleteQuest)
        elseif stage.mode == "reward" and Shown(QuestFrameRewardPanel) then
            local choices = Read(GetNumQuestChoices)
            if Count(choices, 1) then self:Request("reward:" .. id, GetQuestReward, choices) end
        end
    end
end

function Quests:Work(stage)
    if not self.active or not Enabled() or InCombatLockdown() or self.stage ~= stage
        or stage.requested or self:PauseIfShift() then return end
    local guid = Read(UnitGUID, stage.mode == "gossip" and "npc" or "questnpc")
    if not Suite.IsReadable(guid) or (self.visit.guid and guid ~= self.visit.guid) then return end
    if stage.mode == "gossip" then self:Gossip()
    elseif stage.mode == "greeting" then self:Greeting()
    else self:Quest(stage) end
end

function Quests:Queue()
    if self.timer or not self.active or not self.stage or not Enabled() or InCombatLockdown()
        or self:PauseIfShift() or not C_Timer or type(C_Timer.NewTimer) ~= "function" then return end
    local stage = self.stage
    -- Events may precede Blizzard's show handlers; act after the native dialog settles.
    self.timer = C_Timer.NewTimer(0, function()
        self.timer = nil
        self:Work(stage)
    end)
end

function Quests:OnEvent(event, continuing, success)
    if not self.active then return end
    if InCombatLockdown() then self:EndVisit(); return end
    if event == "GOSSIP_SHOW" then self:SetStage("gossip")
    elseif event == "QUEST_GREETING" then self:SetStage("greeting")
    elseif event == "QUEST_DETAIL" then self:SetStage("detail")
    elseif event == "QUEST_DATA_LOAD_RESULT" then
        local stage = self.stage
        if not stage or stage.mode ~= "detail" or not stage.dataRequested or stage.dataReady
            or stage.requested or not ID(continuing) or continuing ~= stage.id then return end
        if Yes(success) then
            stage.dataReady, stage.dataFailed = true, nil
            self:Queue()
        elseif No(success) then stage.dataFailed = true end
    elseif event == "QUEST_PROGRESS" then self:SetStage("progress")
    elseif event == "QUEST_COMPLETE" then self:SetStage("reward")
    elseif event == "MERCHANT_CLOSED" then
        if Yes(Suite.db.autoVendor) then self:EndVisit() end
    elseif event == "GOSSIP_CLOSED" then
        self:Cancel(); self.stage = nil
        if not Yes(continuing) then self:EndVisit() end
    elseif event == "QUEST_FINISHED" then
        self:Cancel(); self.stage = nil
        if not self.visit or not self.visit.fromList then self:EndVisit() else self:CheckClosed() end
    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
        local kinds = Enum and Enum.PlayerInteractionType
        if kinds and Count(kinds.Gossip, 100) and Count(kinds.QuestGiver, 100) and Count(continuing, 100)
            and (continuing == kinds.Gossip or continuing == kinds.QuestGiver) then
            self:CheckClosed()
        end
    elseif event == "GOSSIP_CONFIRM" or event == "GOSSIP_ENTER_CODE" then
        self:Cancel(); self.stage = nil
        if self.visit then self.visit.paused = true end
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_ENTERING_WORLD" then self:EndVisit()
    else self:Queue() end
end

function Quests:Apply()
    Suite.pending.quests = nil
    if not Enabled() then
        self.active = nil; self:EndVisit()
        if self.events then self.events:UnregisterAllEvents() end
        return
    end
    Suite.AfterCombat("quests", function()
        if not Enabled() then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event, ...) self:OnEvent(event, ...) end)
        end
        self.active = true
        for _, event in ipairs({ "GOSSIP_SHOW", "GOSSIP_CLOSED", "MERCHANT_CLOSED", "GOSSIP_OPTIONS_REFRESHED", "GOSSIP_CONFIRM",
            "GOSSIP_ENTER_CODE", "QUEST_GREETING", "QUEST_DETAIL", "QUEST_DATA_LOAD_RESULT", "QUEST_PROGRESS", "QUEST_COMPLETE",
            "QUEST_FINISHED", "QUEST_ITEM_UPDATE", "QUEST_LOG_UPDATE", "PLAYER_INTERACTION_MANAGER_FRAME_HIDE",
            "PLAYER_REGEN_DISABLED", "PLAYER_ENTERING_WORLD" }) do
            self.events:RegisterEvent(event)
        end
        -- Settings changes affect the current known stage, without discovering or opening dialogs.
        self:Cancel(); self:Queue()
    end)
end
