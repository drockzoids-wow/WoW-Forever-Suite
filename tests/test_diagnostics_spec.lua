local Suite, equal = ...
-- Test the optional test-build file in isolation, without changing real CVars.
if not Suite.TestDiagnostics then return end -- Release preparation removes the temporary file.
local oldCVar, oldCreate = C_CVar, CreateFrame
local value, writes, messages, frame = "0", 0, {}, nil
local fake = { IsReadable = Suite.IsReadable, Print = function(message) messages[#messages + 1] = message end }
local function Load()
    CreateFrame = function()
        frame = {
            RegisterEvent = function(self, event) self.event = event end,
            SetScript = function(self, _, callback) self.callback = callback end,
            UnregisterAllEvents = function(self) self.event = nil end,
        }
        return frame
    end
    assert(loadfile("src/WoWForeverSuite/TestDiagnostics.lua"))("WoWForeverSuite", fake)
end
C_CVar = {
    SetCVar = function(name, setting)
        equal(name, "taintLog", "test startup writes only taint logging")
        equal(setting, "2", "test startup requests verbose taint logging")
        writes = writes + 1; value = setting
    end,
    GetCVar = function() return value end,
}
Load()
equal(value, "2", "logging starts during file loading before login")
equal(writes, 1, "startup performs one immediate write")
equal(#messages, 0, "file loading does not announce an unconfirmed login state")
equal(frame.event, "PLAYER_LOGIN", "test diagnostics rechecks at login")
value = "0"; frame.callback()
equal(value, "2", "login restores requested logging after an earlier change")
equal(messages[1], "Test build: taint logging is active (level 2).", "login announces verified logging")
equal(frame.event, nil, "login listener stops without polling")
value = "0"; Load()
equal(value, "2", "reloading the addon re-enables logging")
C_CVar.SetCVar = function() error("unavailable") end
equal(fake.TestDiagnostics:EnableTaintLogging(), false, "rejected setter cannot interrupt startup")
C_CVar.SetCVar = function() end
C_CVar.GetCVar = function() return "0" end
equal(fake.TestDiagnostics:EnableTaintLogging(), false, "unchanged readback is not reported as enabled")
C_CVar.GetCVar = function() return { secret = true } end
equal(fake.TestDiagnostics:EnableTaintLogging(), false, "restricted readback is not compared")
C_CVar.GetCVar = function() error("unavailable") end
equal(fake.TestDiagnostics:EnableTaintLogging(), false, "failed readback cannot interrupt startup")
C_CVar = nil
Load(); frame.callback()
equal(messages[#messages], "Test build: taint logging could not be enabled. Run /console taintLog 2 manually.", "missing capabilities give a manual fallback")
C_CVar, CreateFrame = oldCVar, oldCreate
