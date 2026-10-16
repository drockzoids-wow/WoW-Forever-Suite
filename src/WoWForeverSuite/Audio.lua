local _, Suite = ...
local Audio = {}
Suite.Audio = Audio
table.insert(Suite.modules, Audio)

local OUTPUT = "Sound_OutputDriverIndex"
local SETTLE, INTERVAL = 0.2, 2
local deviceEvents = { VOICE_CHAT_OUTPUT_DEVICES_UPDATED = true, SOUND_DEVICE_UPDATE = true }

local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and value >= 0 and value < math.huge
end

function Audio:Enabled()
    return Suite.db and Suite.IsReadable(Suite.db.audioSync) and Suite.db.audioSync == true
end

function Audio:Report(message)
    if self.warning ~= message then self.warning = message; Suite.Print(message) end
end

function Audio:Cancel()
    if self.timer then self.timer:Cancel(); self.timer = nil end
end

function Audio:MediaPlaying()
    if self.cinematic or self.movie then return true end
    for _, name in ipairs({ "CinematicFrame", "MovieFrame" }) do
        local frame = _G[name]
        if not Suite.IsReadable(frame) then return true end
        if frame ~= nil then
            if type(frame.IsShown) ~= "function" then return true end
            if type(frame.IsForbidden) == "function" then
                local ok, forbidden = pcall(frame.IsForbidden, frame)
                if not ok or not Suite.IsReadable(forbidden) or forbidden ~= false then return true end
            end
            local ok, shown = pcall(frame.IsShown, frame)
            if not ok or not Suite.IsReadable(shown) or type(shown) ~= "boolean" or shown then return true end
        end
    end
    return false
end

local function OutputPreference()
    if not C_CVar or type(C_CVar.GetCVarInfo) ~= "function" or type(C_CVar.SetCVar) ~= "function" then return nil end
    local ok, value, _, _, _, locked, secure, readOnly = pcall(C_CVar.GetCVarInfo, OUTPUT)
    if not ok or not Suite.IsReadable(value) or type(value) ~= "string" or value == ""
        or not Suite.IsReadable(locked) or locked ~= false or not Suite.IsReadable(secure) or secure ~= false
        or not Suite.IsReadable(readOnly) or readOnly ~= false then return nil end
    return value
end

function Audio:Refresh(manual)
    if not self.active or not self:Enabled() or self.syncing then return end
    if self:MediaPlaying() then self.waiting, self.manual = true, manual or self.manual; return end
    local value = OutputPreference()
    if value == nil or type(Sound_GameSystem_RestartSoundSystem) ~= "function" then
        self:Report("Audio sync is unavailable. Check the game's Audio settings.")
        return
    end
    local ok, now = pcall(GetTime)
    if not ok or not Number(now) then return end
    if not manual and self.lastSync and now - self.lastSync < INTERVAL then return end
    -- Restart/CVar changes can synchronously emit device events themselves.
    -- Bound delayed feedback too; only a fresh event or manual request starts work.
    self.lastSync, self.syncing = now, true
    local success = true
    if value ~= "0" then
        local written, confirmed = pcall(C_CVar.SetCVar, OUTPUT, "0")
        success = written and Suite.IsReadable(confirmed) and confirmed == true and OutputPreference() == "0"
    end
    local restarted = false
    if success and self.active and self:Enabled() then restarted = pcall(Sound_GameSystem_RestartSoundSystem) end
    self.syncing = false
    if not self.active or not self:Enabled() then return end
    if not success then self:Report("Audio output could not switch to System Default. Check the game's Audio settings.")
    elseif not restarted then self:Report("The game declined the audio refresh. Try Sync now when it is available.")
    else
        self.warning = nil
        if manual then Suite.Print("Audio refresh requested for the Windows default device.") end
    end
end

function Audio:Schedule(manual, mediaStopped)
    if not self.active or not self:Enabled() or self.syncing then return end
    local ok, now = pcall(GetTime)
    if not ok or not Number(now) then return end
    if not manual and self.lastSync and now - self.lastSync < INTERVAL then return end
    self.manual = manual or self.manual
    -- Stop notifications can arrive just before the native movie frame hides.
    -- Let the settling callback check its final visibility before refreshing.
    if not mediaStopped and self:MediaPlaying() then self.waiting = true; self:Cancel(); return end
    if self.timer then return end
    if not C_Timer or type(C_Timer.NewTimer) ~= "function" then
        self:Report("Audio sync is unavailable. Check the game's Audio settings.")
        return
    end
    self.waiting = false
    self.timer = C_Timer.NewTimer(SETTLE, function()
        self.timer = nil
        local requested = self.manual
        self.manual = nil
        self:Refresh(requested)
    end)
end

function Audio:SyncNow()
    if not self:Enabled() then Suite.Print("Enable Follow Windows audio device first."); return end
    if not self.active then self.manual = true; self:Apply(); return end
    self:Schedule(true)
end

local function Register(frame, event)
    if C_EventUtils and type(C_EventUtils.IsEventValid) == "function" then
        local ok, valid = pcall(C_EventUtils.IsEventValid, event)
        if not ok or not Suite.IsReadable(valid) or valid ~= true then return false end
    end
    local ok, result = pcall(frame.RegisterEvent, frame, event)
    return ok and Suite.IsReadable(result) and (result == nil or result == true)
end

function Audio:Apply()
    if not self:Enabled() then
        Suite.pending.audioEnable = nil
        self.active, self.waiting, self.manual, self.cinematic, self.movie, self.warning = false, nil, nil, nil, nil, nil
        self:Cancel()
        if self.events then self.events:UnregisterAllEvents() end
        return
    end
    if self.active then return end
    Suite.AfterCombat("audioEnable", function()
        if not self:Enabled() or self.active then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event)
                if not self.active or not self:Enabled() then return end
                if event == "PLAYER_LOGOUT" then
                    self.active, self.waiting, self.manual, self.cinematic, self.movie = false, nil, nil, nil, nil
                    self:Cancel(); self.events:UnregisterAllEvents()
                elseif event == "CINEMATIC_START" or event == "PLAY_MOVIE" then
                    if event == "CINEMATIC_START" then self.cinematic = true else self.movie = true end
                    if self.timer then self.waiting = true; self:Cancel() end
                elseif event == "CINEMATIC_STOP" or event == "STOP_MOVIE" then
                    if event == "CINEMATIC_STOP" then self.cinematic = nil else self.movie = nil end
                    if self.waiting then self:Schedule(self.manual, true) end
                elseif deviceEvents[event] or event == "PLAYER_ENTERING_WORLD" then self:Schedule() end
            end)
        end
        self.active, self.lastSync = true, nil
        local automatic = false
        for event in pairs(deviceEvents) do if Register(self.events, event) then automatic = true end end
        for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "CINEMATIC_START", "CINEMATIC_STOP", "PLAY_MOVIE", "STOP_MOVIE", "PLAYER_LOGOUT" }) do
            Register(self.events, event)
        end
        if not automatic then self:Report("Device-change notifications are unavailable. Use Sync now after switching Windows audio.") end
        self:Schedule(self.manual)
    end)
end
