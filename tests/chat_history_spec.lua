local Suite, equal, Frame, Combat = ...
local history = Suite.ChatHistory
local oldDB, oldChar, oldMain, oldTimer, oldPending, oldPrint = Suite.db, WoWForeverSuiteCharDB, DEFAULT_CHAT_FRAME, C_Timer, Suite.pending, Suite.Print
local oldState = {}
for key, value in pairs(history) do oldState[key] = value end
history.hooks, history.events, history.timer, history.previous, history.restored = {}, nil, nil, nil, nil
Suite.db, Suite.pending = { chatHistory = false, chatStyle = false }, {}
local notices = 0
Suite.Print = function() notices = notices + 1 end
local timers = {}
C_Timer = { NewTimer = function(_, callback)
    local timer = { Cancel = function(self) self.cancelled = true end, callback = callback }
    timers[#timers + 1] = timer
    return timer
end }
local function Flush()
    local queue = timers; timers = {}
    for _, timer in ipairs(queue) do if not timer.cancelled then timer.callback() end end
end
local frame = Frame("ChatFrame1")
frame.IsForbidden = function(self) return self.forbidden or false end
frame.AddMessage = function(self, text) self.lines[#self.lines + 1] = text end
frame.BackFillMessage = function(self, text)
    assert(not InCombatLockdown(), "history replay in combat")
    table.insert(self.lines, 1, text)
end
DEFAULT_CHAT_FRAME = frame
local secret = { secret = true }
local clean = history:InitializeCharacter({ version = 1, lines = { "old", secret, string.rep("x", 4097), "", "new" }, foreign = true })
equal(#clean.lines, 2, "saved history drops secret, oversized and empty entries")
equal(clean.lines[1], "old", "history preserves chronological order")
equal(clean.foreign, nil, "history does not retain unknown saved fields")
equal(#history:InitializeCharacter({ version = secret, lines = { "bad" } }).lines, 0, "secret schema rejected")
equal(#history:InitializeCharacter({ version = 2, lines = { "bad" } }).lines, 0, "unknown schema rejected")
equal(#history:InitializeCharacter(secret).lines, 0, "secret root rejected")
local many = { version = 1, lines = {} }
for index = 1, 300 do many.lines[index] = "line " .. index end
local bounded = history:InitializeCharacter(many)
equal(#bounded.lines, 250, "loaded history is bounded")
equal(bounded.lines[1], "line 51", "loaded history keeps newest lines")
WoWForeverSuiteCharDB = { chatHistory = clean }
history:Apply()
equal(#timers, 0, "disabled history creates no timer")
equal(history.events, nil, "disabled history creates no event frame")
Suite.db.chatHistory = secret
equal(history:Enabled(), false, "secret enable rejected")
Suite.db.chatHistory = true
history:Apply()
equal(#timers, 1, "history schedules one startup replay")
history:Apply()
equal(#timers, 1, "repeated apply coalesces replay")
local link = "|cff00ff00|Hitem:123|h[Some item]|h|r"
frame:AddMessage(link)
frame:AddMessage(secret)
frame:AddMessage(string.rep("x", 4097))
equal(#clean.lines, 3, "capture saves only bounded readable rendered messages")
equal(clean.lines[3], link, "capture preserves original item link")
frame.lines = { "current login" }
Flush()
equal(#frame.lines, 5, "history adds saved lines and two markers")
equal(frame.lines[1], "--- Saved chat ---", "saved marker precedes history")
equal(frame.lines[2], "old", "oldest saved line appears first")
equal(frame.lines[3], "new", "newest previous line follows")
equal(frame.lines[4], "--- Current session ---", "session boundary follows saved lines")
equal(frame.lines[5], "current login", "startup messages stay newer than saved chat")
equal(#clean.lines, 3, "replay cannot duplicate persisted entries")
history.events.OnEvent(nil, "PLAYER_ENTERING_WORLD")
history:Apply(); Flush()
equal(#frame.lines, 5, "world transitions and apply never replay twice")
for index = 1, 300 do frame:AddMessage("live " .. index) end
equal(#clean.lines, 250, "live history is bounded")
equal(clean.lines[1], "live 51", "live capture evicts oldest line")
frame:AddMessage("same"); frame:AddMessage("same")
equal(clean.lines[250], "same", "legitimate repeated messages are retained")
equal(clean.lines[249], "same", "repeated-message order retained")
Suite.db.chatHistory = false; history:Apply()
frame:AddMessage("disabled")
equal(#clean.lines, 250, "disabled hook cannot record")
equal(history.events.events and next(history.events.events), nil, "disabled history unregisters events")
local second = Frame("ChatFrame3")
second.IsForbidden, second.AddMessage, second.BackFillMessage = frame.IsForbidden, frame.AddMessage, frame.BackFillMessage
DEFAULT_CHAT_FRAME = second
Suite.db.chatHistory = true; history:Apply()
DEFAULT_CHAT_FRAME = frame; history:Apply()
frame:AddMessage("single hook")
equal(clean.lines[249], "same", "rediscovery does not install duplicate hooks")
equal(clean.lines[250], "single hook", "rediscovered main window records once")
history:Capture(second, "other tab")
equal(clean.lines[250], "single hook", "non-main tabs cannot enter saved history")
frame.forbidden = true; frame:AddMessage("forbidden")
equal(clean.lines[250], "single hook", "forbidden main frame cannot be recorded")
frame.forbidden = false
-- A fresh Lua session loads a clean copy; captures from this login are not replayed.
WoWForeverSuiteCharDB = { chatHistory = history:InitializeCharacter({ version = 1, lines = { link } }) }
history.restored, history.previous = nil, nil
frame.lines = {}
history:Apply(); Flush()
equal(frame.lines[2], "|cff929da6|Hitem:123|h[Some item]|h|cff929da6", "muted replay preserves usable link markup")
equal(#WoWForeverSuiteCharDB.chatHistory.lines, 1, "character history remains separate")
equal(#clean.lines, 250, "switching saved character does not mutate prior character")
-- Defer replay during combat, and disabling cancels that deferred work.
history.restored, history.previous = nil, nil
Combat(true); history:Apply(); Flush()
equal(type(Suite.pending.chatHistory), "function", "startup replay defers in combat")
Suite.db.chatHistory = false; history:Apply()
equal(Suite.pending.chatHistory, nil, "disable cancels combat replay")
Combat(false)
Suite.db.chatHistory = true; history:Apply()
local liveCount = #frame.lines
history:Clear(); Flush()
equal(#WoWForeverSuiteCharDB.chatHistory.lines, 0, "clear removes saved lines")
equal(#frame.lines, liveCount, "clear preserves current chat and cancels startup replay")
frame:AddMessage("after clear")
equal(#WoWForeverSuiteCharDB.chatHistory.lines, 1, "recording resumes normally after clear")
history.restored, history.previous = nil, nil
history:Apply()
history.events.OnEvent(nil, "PLAYER_LOGOUT"); Flush()
equal(#frame.lines, liveCount + 1, "logout cancels outstanding replay")
history.restored, history.previous = nil, nil
local backfill = frame.BackFillMessage
frame.BackFillMessage = function() error("unavailable native operation") end
history:Apply(); Flush()
equal(history.restoring, false, "failed replay releases capture guard")
equal(notices, 1, "failed replay explains locally without retry")
equal(#WoWForeverSuiteCharDB.chatHistory.lines, 1, "failed replay retains persisted messages")
frame.BackFillMessage = backfill
Suite.db.chatHistory = false; history:Apply()
for key in pairs(history) do history[key] = nil end
for key, value in pairs(oldState) do history[key] = value end
Suite.db, WoWForeverSuiteCharDB, DEFAULT_CHAT_FRAME, C_Timer, Suite.pending, Suite.Print = oldDB, oldChar, oldMain, oldTimer, oldPending, oldPrint
Combat(false)
