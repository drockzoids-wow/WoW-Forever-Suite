local _, Suite = ...
local Check = { prefix = "WFSVersion1", pending = {}, lastSent = {} }
Suite.VersionCheck = Check
Suite.modules[#Suite.modules + 1] = Check

local channels = { YELL = true, GUILD = true, PARTY = true, RAID = true, INSTANCE_CHAT = true }
local function Text(value)
    return Suite.IsReadable(value) and type(value) == "string"
end
local function Call(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, result = pcall(fn, ...)
    if ok and Suite.IsReadable(result) then return result end
end
local function Clock()
    local value = Call(GetTime)
    if type(value) == "number" and value == value and value >= 0 and value < math.huge then return value end
end

-- Only canonical stable releases cross the wire. Never display remote free text.
function Check:Version(value)
    if not Text(value) or #value > 17 then return end
    local major, minor, patch = value:match("^(%d+)%.(%d+)%.(%d+)$")
    if not major then return end
    local result = {}
    for index, part in ipairs({ major, minor, patch }) do
        local number = tonumber(part)
        if not number or number > 99999 or tostring(number) ~= part then return end
        result[index] = number
    end
    return result
end

function Check:Newer(left, right)
    for index = 1, 3 do
        if left[index] ~= right[index] then return left[index] > right[index] end
    end
    return false
end

function Check:Enabled()
    return Suite.db and Suite.IsReadable(Suite.db.updateNotifications) and Suite.db.updateNotifications == true
end

function Check:Available(channel)
    if channel == "YELL" then return true end
    if channel == "GUILD" then return Call(IsInGuild) == true end
    if channel == "INSTANCE_CHAT" then
        return LE_PARTY_CATEGORY_INSTANCE ~= nil and Call(IsInGroup, LE_PARTY_CATEGORY_INSTANCE) == true
    end
    if channel == "RAID" then return Call(IsInRaid) == true end
    return channel == "PARTY" and Call(IsInGroup) == true and Call(IsInRaid) == false
end

function Check:Cancel()
    if self.timer then self.timer:Cancel(); self.timer = nil end
end

function Check:Schedule(delay)
    if self.timer or not self.active or not self:Enabled() or InCombatLockdown() then return end
    self.timer = C_Timer.NewTimer(delay, function() self.timer = nil; self:Flush() end)
end

function Check:Queue(channel, kind)
    if not self.active or not self:Enabled() then return end
    if not self.pending[channel] or kind == "Q" then self.pending[channel] = kind end
    self:Schedule(2)
end

function Check:Announce()
    for channel in pairs(channels) do
        if self:Available(channel) then self:Queue(channel, "Q") end
    end
end

function Check:Flush()
    if not self.active or not self:Enabled() or InCombatLockdown() then return end
    local now, version = Clock(), self:Version(Suite.version)
    if not now or not version then self.pending = {}; return end
    local wait
    for channel, kind in pairs(self.pending) do
        if not self:Available(channel) then self.pending[channel] = nil
        else
            local remaining = self.lastSent[channel] and 30 - (now - self.lastSent[channel]) or 0
            if remaining <= 0 then
                -- Bound attempts even when native routing rejects a channel. No retry loop.
                self.pending[channel], self.lastSent[channel] = nil, now
                Call(C_ChatInfo and C_ChatInfo.SendAddonMessage, self.prefix, kind .. ":" .. Suite.version, channel)
            else wait = math.min(wait or remaining, remaining) end
        end
    end
    if wait then self:Schedule(wait) end
end

function Check:Receive(prefix, message, channel)
    if not self.active or not self:Enabled() or not Text(prefix) or prefix ~= self.prefix
        or not Text(channel) or not channels[channel] or not Text(message) or #message > 19 then return end
    local kind, version = message:match("^([QV]):(.+)$")
    local remote, current = self:Version(version), self:Version(Suite.version)
    if not kind or not remote or not current then return end
    if not self.warned and self:Newer(remote, current) then
        self.warned = true -- Session-only; neither reapplying settings nor profile changes reset it.
        Suite.Print("A newer Forever Suite version is available (" .. version .. "). You're running " .. Suite.version .. ". Check CurseForge for an update.")
    end
    -- Reply only to older queries, on their existing distribution. Replies never trigger replies.
    if kind == "Q" and self:Newer(current, remote) and self:Available(channel) then self:Queue(channel, "V") end
end

function Check:Apply()
    Suite.AfterCombat("versionCheck", function()
        if not self:Enabled() then
            self.active = false; self:Cancel(); self.pending = {}
            if self.events then self.events:UnregisterAllEvents() end
            return
        end
        if self.active then return end
        local chat = C_ChatInfo
        if not chat or type(chat.RegisterAddonMessagePrefix) ~= "function" or type(chat.SendAddonMessage) ~= "function"
            or not C_Timer or type(C_Timer.NewTimer) ~= "function" then return end
        -- Build-70862 RegisterAddonMessagePrefixResult: Success=0, DuplicatePrefix=1.
        local result = Call(chat.RegisterAddonMessagePrefix, self.prefix)
        if result ~= 0 and result ~= 1 then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event, ...)
                if not self:Enabled() then return end
                if event == "CHAT_MSG_ADDON" then self:Receive(...)
                elseif event == "PLAYER_REGEN_DISABLED" then self:Cancel()
                elseif event == "PLAYER_LOGOUT" then self.active = false; self:Cancel(); self.pending = {}
                else self:Announce() end
            end)
        end
        for _, event in ipairs({ "CHAT_MSG_ADDON", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA", "GROUP_ROSTER_UPDATE",
            "PLAYER_GUILD_UPDATE", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_LOGOUT" }) do
            self.events:RegisterEvent(event)
        end
        self.active = true
        self:Announce()
    end)
end
