local _, Suite = ...
local History = { limit = 250, maxBytes = 4096, hooks = {} }
Suite.ChatHistory = History
Suite.modules[#Suite.modules + 1] = History

local function Read(value, kind)
    return Suite.IsReadable(value) and type(value) == kind
end
local function Line(value)
    return Read(value, "string") and #value > 0 and #value <= History.maxBytes
end
local function MainFrame()
    local frame = DEFAULT_CHAT_FRAME
    if not Suite.IsReadable(frame) or (type(frame) ~= "table" and type(frame) ~= "userdata")
        or type(frame.IsForbidden) ~= "function" then return end
    local forbidden = frame:IsForbidden()
    if not Read(forbidden, "boolean") or forbidden then return end
    if type(frame.AddMessage) == "function" and type(frame.BackFillMessage) == "function" then return frame end
end
function History:InitializeCharacter(saved)
    local clean = { version = 1, lines = {} }
    if not Read(saved, "table") or not Read(saved.version, "number") or saved.version ~= 1
        or not Read(saved.lines, "table") then return clean end
    local lines = saved.lines
    for index = math.max(1, #lines - self.limit + 1), #lines do
        if Line(lines[index]) then clean.lines[#clean.lines + 1] = lines[index] end
    end
    return clean
end
function History:Enabled()
    return Read(Suite.db, "table") and Read(Suite.db.chatHistory, "boolean") and Suite.db.chatHistory
end
function History:Store()
    if Read(WoWForeverSuiteCharDB, "table") and Read(WoWForeverSuiteCharDB.chatHistory, "table") then
        return WoWForeverSuiteCharDB.chatHistory
    end
end
function History:Capture(frame, message)
    if self.restoring or not self:Enabled() or not Suite.IsReadable(frame)
        or frame ~= MainFrame() or not Line(message) then return end
    local store = self:Store()
    if not store then return end
    local lines = store.lines
    lines[#lines + 1] = message
    if #lines > self.limit then table.remove(lines, 1) end
end
function History:Restore()
    if self.restored or not self:Enabled() then return end
    local frame = MainFrame()
    if not frame then return end
    if InCombatLockdown() then
        Suite.AfterCombat("chatHistory", function() self:Restore() end)
        return
    end
    local lines = self.previous or {}
    self.restored, self.restoring = true, true
    -- Backfill keeps startup/current-session messages newer than the saved lines.
    -- Never inspect native history buffers or message getters to recover hidden text.
    local ok = pcall(function()
        if #lines > 0 then
            frame:BackFillMessage("--- Current session ---", 0.41, 0.84, 0.75)
            for index = #lines, 1, -1 do
                -- Preserve link targets and labels; mute embedded colors as well.
                local muted = lines[index]:gsub("|c%x%x%x%x%x%x%x%x", "|cff929da6"):gsub("|r", "|cff929da6")
                frame:BackFillMessage(muted, 0.57, 0.62, 0.65)
            end
            frame:BackFillMessage("--- Saved chat ---", 0.41, 0.84, 0.75)
        end
    end)
    self.restoring, self.previous = false, nil
    if not ok then Suite.Print("Saved chat could not be restored in this window. Your saved history is kept.") end
end
function History:Discover()
    local frame = MainFrame()
    if not frame or self.hooks[frame] or type(hooksecurefunc) ~= "function" then return end
    -- Passive post-hook on this character's main chat only. Native chat filters
    -- run before AddMessage; other tabs, combat log and temporary whispers are excluded.
    hooksecurefunc(frame, "AddMessage", function(owner, message) self:Capture(owner, message) end)
    self.hooks[frame] = true
end
function History:Schedule()
    if self.timer or self.restored or not self:Enabled() then return end
    self.timer = C_Timer.NewTimer(0, function()
        self.timer = nil
        self:Discover(); self:Restore()
    end)
end
function History:Clear()
    local store = self:Store()
    if store then store.lines = {} end
    self.previous = nil
    -- Deliberate clearing also cancels any pending startup replay.
    self.restored = true
    if self.timer then self.timer:Cancel(); self.timer = nil end
    Suite.pending.chatHistory = nil
end
function History:Apply()
    if not self:Enabled() then
        if self.timer then self.timer:Cancel(); self.timer = nil end
        if self.events then self.events:UnregisterAllEvents() end
        Suite.pending.chatHistory = nil
        return
    end
    local store = self:Store()
    if not store then return end
    if not self.previous and not self.restored then
        self.previous = {}
        for index, text in ipairs(store.lines) do self.previous[index] = text end
    end
    if not self.events then
        self.events = CreateFrame("Frame")
        self.events:SetScript("OnEvent", function(_, event)
            if event == "PLAYER_LOGOUT" then
                if self.timer then self.timer:Cancel(); self.timer = nil end
                Suite.pending.chatHistory = nil
            else self:Discover(); self:Schedule() end
        end)
    end
    self.events:RegisterEvent("UPDATE_CHAT_WINDOWS")
    self.events:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.events:RegisterEvent("PLAYER_LOGOUT")
    self:Discover(); self:Schedule()
end
