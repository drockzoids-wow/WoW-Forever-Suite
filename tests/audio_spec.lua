-- Device events, CVar permissions and real module lifecycle, without OS audio.
local Suite, equal, Frame, SetCombat = ...
local audio, gui = Suite.Audio, Suite.GUI
local names = { "C_CVar", "C_Timer", "C_EventUtils", "GetTime", "CreateFrame",
    "Sound_GameSystem_RestartSoundSystem", "CinematicFrame", "MovieFrame" }
local saved = {}
for _, name in ipairs(names) do saved[name] = _G[name] end
local oldDB, oldApply, oldPage, oldPending = Suite.db, Suite.Apply, gui.page, Suite.pending
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
local now, value, locked, secure, readOnly = 30, "3", false, false, false
local writes, restarts, constructions, messages = {}, 0, 0, {}
local timers, valid, rejected = {}, {}, {}
local getterError, writeResult, readbackWrong, restartError, feedback = false, true, false, false, true
local oldPrint = Suite.Print
Suite.Print = function(message) messages[#messages + 1] = message end
GetTime = function() return now end
CinematicFrame, MovieFrame = nil, nil
C_Timer = { NewTimer = function(delay, callback)
    local timer = { due = now + delay, callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
C_EventUtils = { IsEventValid = function(event) return valid[event] ~= false and valid[event] or valid[event] == nil end }
CreateFrame = function(...)
    assert(not InCombatLockdown(), "audio event construction must defer combat")
    constructions = constructions + 1
    local frame = Frame(...)
    frame.registered = {}
    frame.RegisterEvent = function(self, event)
        if rejected[event] then error("unsupported event") end
        self.registered[event] = true
        return true
    end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    return frame
end
C_CVar = {
    GetCVarInfo = function(name)
        equal(name, "Sound_OutputDriverIndex", "audio reads only its output CVar")
        if getterError then error("unavailable CVar") end
        return value, "0", false, false, locked, secure, readOnly
    end,
    SetCVar = function(name, chosen)
        writes[#writes + 1] = { name, chosen }
        if writeResult == true and not readbackWrong then value = chosen end
        return writeResult
    end,
}
local function Fire(event)
    if audio.events and audio.events.registered[event] then audio.events.OnEvent(audio.events, event) end
end
Sound_GameSystem_RestartSoundSystem = function()
    if restartError then error("restart denied") end
    restarts = restarts + 1
    if feedback then Fire("SOUND_DEVICE_UPDATE"); Fire("VOICE_CHAT_OUTPUT_DEVICES_UPDATED") end
end
local function CountTimers()
    local count = 0
    for _, timer in ipairs(timers) do if not timer.cancelled then count = count + 1 end end
    return count
end
local function Flush()
    local attempts = 0
    while #timers > 0 do
        attempts = attempts + 1
        assert(attempts < 25, "sound restart feedback must settle")
        local timer = table.remove(timers, 1)
        if not timer.cancelled then now = math.max(now, timer.due); timer.callback() end
    end
end
local function Enable() Suite.db.audioSync = true; audio:Apply() end
local function Disable() Suite.db.audioSync = false; audio:Apply() end
local function Advance() now = now + 3 end
local function Resume()
    SetCombat(false)
    local pending = Suite.pending.audioEnable; Suite.pending.audioEnable = nil
    if pending then pending() end
end
local hidden = setmetatable({ secret = true }, { __index = function() error("restricted value indexed") end })
equal(Suite.db.audioSync, false, "audio sync is independently off by default")
audio:Apply()
equal(constructions, 0, "disabled audio module creates no frame")
audio:SyncNow()
equal(restarts, 0, "manual refresh while disabled performs no restart")
equal(#writes, 0, "disabled audio module changes no preference")
SetCombat(true); Enable()
equal(constructions, 0, "first enable waits for safe frame construction")
Disable(); Resume(); Flush()
equal(constructions, 0, "disabled queued enable cannot construct later")
Enable(); audio:Apply()
equal(constructions, 1, "one frame handles enabled audio events")
equal(CountTimers(), 1, "activation schedules one coalesced refresh")
equal(audio.events.registered.VOICE_CHAT_OUTPUT_DEVICES_UPDATED, true, "primary Windows output notification registered")
equal(audio.events.registered.SOUND_DEVICE_UPDATE, true, "game output notification registered")
Flush()
equal(value, "0", "activation selects native System Default")
equal(#writes, 1, "activation changes only the selected output")
equal(writes[1][1], "Sound_OutputDriverIndex", "volume microphone and voice CVars remain untouched")
equal(writes[1][2], "0", "System Default is the only written driver value")
equal(restarts, 1, "activation requests a game sound refresh")
equal(CountTimers(), 0, "synchronous sound/voice restart feedback creates no loop")
Fire("SOUND_DEVICE_UPDATE"); Fire("VOICE_CHAT_OUTPUT_DEVICES_UPDATED")
equal(CountTimers(), 0, "brief post-restart feedback is throttled")
Advance()
for _ = 1, 500 do Fire("VOICE_CHAT_OUTPUT_DEVICES_UPDATED"); Fire("SOUND_DEVICE_UPDATE") end
equal(CountTimers(), 1, "a large device-event burst coalesces to one worker")
Flush()
equal(restarts, 2, "coalesced device events request one refresh")
equal(#writes, 1, "already-default output is not unnecessarily rewritten")
Advance(); Fire("SOUND_DEVICE_UPDATE"); Disable(); Flush()
equal(restarts, 2, "disable cancels queued audio refresh")
equal(next(audio.events.registered), nil, "disable removes subscriptions")
equal(value, "0", "disable leaves native output preference available to the user")
audio.events.OnEvent(audio.events, "VOICE_CHAT_OUTPUT_DEVICES_UPDATED")
equal(CountTimers(), 0, "retained disabled callbacks stay inert")
value = "2"; Enable(); Flush()
equal(restarts, 3, "re-enable refreshes without a stale cooldown")
equal(constructions, 1, "re-enable reuses the frame")

Advance(); Fire("VOICE_CHAT_OUTPUT_DEVICES_UPDATED"); Fire("CINEMATIC_START")
Flush()
equal(restarts, 3, "cinematic start cancels an already queued refresh")
equal(audio.waiting, true, "cinematic holds the pending device update")
Fire("CINEMATIC_STOP"); Flush()
equal(restarts, 4, "cinematic stop resumes one pending update")
Advance(); MovieFrame = Frame(); MovieFrame:Show()
Fire("VOICE_CHAT_OUTPUT_DEVICES_UPDATED"); audio:SyncNow()
equal(CountTimers(), 0, "visible movie pauses automatic and manual requests")
Fire("STOP_MOVIE")
equal(CountTimers(), 1, "stop event may queue before the native frame hides")
MovieFrame:Hide(); Flush()
equal(restarts, 5, "movie stop refreshes after final visibility settles")
equal(messages[#messages], "Audio refresh requested for the Windows default device.", "deferred manual request reports the request")
Advance(); MovieFrame:Show(); Fire("PLAY_MOVIE"); Fire("SOUND_DEVICE_UPDATE")
Disable(); MovieFrame:Hide(); Fire("STOP_MOVIE"); Flush()
equal(restarts, 5, "disabled cinematic work cannot resume")
MovieFrame = { IsShown = function() return hidden end }
Enable(); Flush()
equal(restarts, 5, "unknown movie visibility cannot authorize restart")
equal(audio.waiting, true, "unknown media state waits for fresh public data")
MovieFrame = nil; Fire("STOP_MOVIE"); Flush()
equal(restarts, 6, "fresh known movie end releases pending work")

local function Denied(label, change, reset)
    Advance(); local before, writesBefore = restarts, #writes
    change(); audio:SyncNow(); Flush()
    equal(restarts, before, label .. " prevents restarting")
    equal(#writes, writesBefore, label .. " prevents preference writes")
    reset()
end
Denied("locked CVar", function() locked = true end, function() locked = false end)
Denied("secure CVar", function() secure = true end, function() secure = false end)
Denied("read-only CVar", function() readOnly = true end, function() readOnly = false end)
Denied("restricted lock flag", function() locked = hidden end, function() locked = false end)
Denied("restricted output", function() value = hidden end, function() value = "0" end)
Denied("missing CVar data", function() value = nil end, function() value = "0" end)
Denied("rejected CVar query", function() getterError = true end, function() getterError = false end)
local restartFunction = Sound_GameSystem_RestartSoundSystem
Denied("missing restart capability", function() Sound_GameSystem_RestartSoundSystem = nil end,
    function() Sound_GameSystem_RestartSoundSystem = restartFunction end)
Denied("restricted public time", function() GetTime = function() return hidden end end,
    function() GetTime = function() return now end end)
Advance(); value, writeResult = "4", false
local before = restarts
audio:SyncNow(); Flush()
equal(restarts, before, "denied CVar write prevents restart")
writeResult, readbackWrong = true, true
Advance(); audio:SyncNow(); Flush()
equal(restarts, before, "unconfirmed output selection prevents restart")
readbackWrong, writeResult = false, hidden
Advance(); audio:SyncNow(); Flush()
equal(restarts, before, "restricted write result prevents restart")
writeResult, value, restartError = true, "0", true
Advance(); audio:SyncNow(); Flush()
equal(restarts, before, "rejected restart is contained without retries")
equal(CountTimers(), 0, "restart rejection leaves no ongoing worker")
restartError = false
SetCombat(true); Advance(); Fire("VOICE_CHAT_OUTPUT_DEVICES_UPDATED"); Flush()
equal(restarts, before + 1, "enabled audio follows device events during combat without frame work")
equal(constructions, 1, "combat refresh creates no extra frames")
SetCombat(false); Advance(); Fire("SOUND_DEVICE_UPDATE"); Fire("PLAYER_LOGOUT"); Flush()
equal(restarts, before + 1, "logout cancels pending device work")
equal(next(audio.events.registered), nil, "logout unregisters audio events")

valid.VOICE_CHAT_OUTPUT_DEVICES_UPDATED, rejected.SOUND_DEVICE_UPDATE = false, true
Enable(); Flush()
equal(audio.events.registered.VOICE_CHAT_OUTPUT_DEVICES_UPDATED, nil, "invalid output event is skipped")
equal(audio.events.registered.SOUND_DEVICE_UPDATE, nil, "runtime event rejection is contained")
audio:SyncNow(); Flush()
equal(restarts, before + 3, "manual refresh remains available without device notifications")
Disable(); valid, rejected = {}, {}
Suite.db.audioSync = hidden; audio:Apply()
equal(audio.active, false, "restricted enabled flag cannot activate audio")
Suite.db.audioSync = false
Suite.Apply = function() end
gui:Select("audio")
equal(gui.rows[1].label.text, "Follow Windows audio device", "audio page exposes the optional feature")
equal(Suite.SettingsCatalog:Search("windows headphones sync")[1].key, "audioSync", "audio option is searchable")
SlashCmdList.WOWFOREVERSUITE("audio")
equal(gui.page, "audio", "audio shortcut opens its page")
equal(Suite.InitializeDB({ audioSync = true }).audioSync, true, "saved enabled preference survives initialization")
equal(Suite.InitializeDB({ audioSync = hidden }).audioSync, false, "restricted saved flag returns to default off")
Disable(); audio.events, audio.lastSync, audio.warning = nil, nil, nil
for _, name in ipairs(names) do _G[name] = saved[name] end
Suite.db, Suite.Apply, Suite.pending, Suite.Print = oldDB, oldApply, oldPending, oldPrint
gui:Select(oldPage or "overview")
SetCombat(false)
