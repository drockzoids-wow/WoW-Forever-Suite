local _, Suite = ...
local State = { watched = {}, buttons = {} }
Suite.QuestTrackerState = State
table.insert(Suite.modules, State)

local function Boolean(value) return Suite.IsReadable(value) and type(value) == "boolean" end
local function Enabled() return Suite.db and Boolean(Suite.db.questTrackerRemember) and Suite.db.questTrackerRemember end
local function Character()
    local db = WoWForeverSuiteCharDB
    if Suite.IsReadable(db) and type(db) == "table" then return db end
end
local function Usable(frame)
    if not Suite.IsReadable(frame) or (type(frame) ~= "table" and type(frame) ~= "userdata") then return false end
    if type(frame.IsForbidden) == "function" then
        local forbidden = frame:IsForbidden()
        if not Boolean(forbidden) or forbidden then return false end
    end
    return true
end
local function Collapsed(frame)
    if not Usable(frame) or type(frame.IsCollapsed) ~= "function" then return end
    local value = frame:IsCollapsed()
    if Boolean(value) then return value end
end

function State:Cancel()
    self.work = nil
    if self.timer then self.timer:Cancel(); self.timer = nil end
end

function State:Watch(tracker)
    if not Usable(tracker) or type(tracker.SetCollapsed) ~= "function"
        or type(hooksecurefunc) ~= "function" then return false end
    if not self.watched[tracker] then
        self.watched[tracker] = true
        local function Changed()
            if self.writing or not Enabled() or tracker ~= ObjectiveTrackerFrame then return end
            local db, current = Character(), Collapsed(tracker)
            if db and Boolean(db.questTrackerCollapsed) and Boolean(current)
                and current ~= db.questTrackerCollapsed then self:Queue() end
        end
        hooksecurefunc(tracker, "SetCollapsed", Changed)
        if type(tracker.Update) == "function" then hooksecurefunc(tracker, "Update", Changed) end
        if type(tracker.HookScript) == "function" then tracker:HookScript("OnShow", function() self:Queue() end) end
    end
    local header = tracker.Header
    local button = Usable(header) and header.MinimizeButton
    if Usable(button) and type(button.HookScript) == "function" and not self.buttons[button] then
        self.buttons[button] = true
        -- Observe the native click result; automatic expansions never replace the player's choice.
        button:HookScript("OnClick", function()
            if not Enabled() or tracker ~= ObjectiveTrackerFrame then return end
            local db, current = Character(), Collapsed(tracker)
            if db and Boolean(current) then
                db.questTrackerCollapsed = current
                self:Cancel()
            end
        end)
    end
    return true
end

function State:Refresh()
    self:Cancel()
    if not Enabled() then return end
    if InCombatLockdown() then
        Suite.AfterCombat("questTrackerState", function() self:Refresh() end)
        return
    end
    local tracker, db = ObjectiveTrackerFrame, Character()
    if not db or not self:Watch(tracker) then return end
    local current = Collapsed(tracker)
    if not Boolean(current) then return end
    if not Boolean(db.questTrackerCollapsed) then
        db.questTrackerCollapsed = current
    elseif current ~= db.questTrackerCollapsed then
        self.writing = true
        tracker:SetCollapsed(db.questTrackerCollapsed)
        self.writing = nil
    end
end

function State:Queue()
    if not Enabled() or self.writing then return end
    if InCombatLockdown() then
        self:Cancel()
        Suite.AfterCombat("questTrackerState", function() self:Refresh() end)
        return
    end
    if self.timer then return end
    if not C_Timer or type(C_Timer.NewTimer) ~= "function" then self:Refresh(); return end
    local work = {}; self.work = work
    self.timer = C_Timer.NewTimer(0, function()
        if self.work ~= work then return end
        self.timer, self.work = nil, nil
        self:Refresh()
    end)
end

function State:Apply()
    self:Cancel()
    Suite.pending.questTrackerState = nil
    if self.events then self.events:UnregisterAllEvents() end
    if not Enabled() then return end
    Suite.AfterCombat("questTrackerState", function()
        if not Enabled() then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function() self:Queue() end)
        end
        for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
            self.events:RegisterEvent(event)
        end
        self:Refresh()
    end)
end
