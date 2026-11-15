local Suite, equal, Combat = ...
local check = Suite.VersionCheck
local old = { db = Suite.db, api = C_ChatInfo, timer = C_Timer, time = GetTime, guild = IsInGuild,
    group = IsInGroup, raid = IsInRaid, category = LE_PARTY_CATEGORY_INSTANCE, version = Suite.version, print = Suite.Print }
local state = {}; for key, value in pairs(check) do state[key] = value end
check.active, check.events, check.timer, check.warned = nil, nil, nil, nil
check.pending, check.lastSent = {}, {}
local now, guild, group, raid, instance, registration, reject = 100, false, false, false, false, 0, false
local sent, notices, timers = {}, {}, {}
GetTime = function() return now end
IsInGuild = function() return guild end
LE_PARTY_CATEGORY_INSTANCE = 2
IsInGroup = function(category) if category == 2 then return instance end; return group end
IsInRaid = function() return raid end
C_Timer = { NewTimer = function(delay, callback)
    local timer = { due = now + delay, callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
local function Advance(seconds)
    now = now + seconds
    local queue = timers; timers = {}
    for _, timer in ipairs(queue) do
        if not timer.cancelled then
            if timer.due <= now then timer.callback() else timers[#timers + 1] = timer end
        end
    end
end
C_ChatInfo = {
    RegisterAddonMessagePrefix = function(prefix) equal(prefix, check.prefix, "dedicated version prefix registered"); return registration end,
    SendAddonMessage = function(prefix, message, channel, target)
        assert(not InCombatLockdown(), "no combat version sends")
        sent[#sent + 1] = { prefix = prefix, message = message, channel = channel, target = target }
        if reject then error("unsupported route") end
        return 0
    end,
    SendChatMessage = function() error("version exchange must not send visible chat") end,
}
Suite.Print = function(message) notices[#notices + 1] = message end
Suite.version, Suite.db = "1.0.18", { updateNotifications = false }
Combat(false)
equal(Suite.defaults.updateNotifications, false, "update detection is independently default off")
check:Apply()
equal(check.events, nil, "disabled update detection creates no frame")
equal(#timers, 0, "disabled update detection starts no timer")
Suite.db.updateNotifications = true
check:Apply(); check:Apply()
equal(#timers, 1, "enable and repeated apply coalesce discovery")
Advance(2)
equal(#sent, 1, "solo unguilded players still broadcast for nearby Suite users")
equal(sent[1].channel, "YELL", "nearby discovery uses invisible YELL distribution")
equal(sent[1].message, "Q:1.0.18", "only installed stable version is advertised")
equal(sent[1].target, nil, "nearby broadcast addresses no named player")
equal(check.timer, nil, "discovery leaves no idle timer")
local function Receive(message, channel, prefix)
    check.events:GetScript("OnEvent")(check.events, "CHAT_MSG_ADDON", prefix or check.prefix, message, channel or "YELL", "Another Player")
end
for _, message in ipairs({ "Q:1.0.18", "V:1.0.17", "V:1.0.9", "V:1.0.19-beta", "V:01.0.19", "V:1.0.19|Hbad", "V:999999.0.0", "V:1.0", "X:2.0.0", { secret = true } }) do
    Receive(message)
end
Receive("V:2.0.0", "CHANNEL")
Receive("V:2.0.0", { secret = true })
Receive("V:2.0.0", "YELL", "other")
Receive("V:2.0.0", "YELL", { secret = true })
equal(#notices, 0, "equal older malformed secret unrelated and unsupported packets cannot warn")
Receive("V:1.0.19")
equal(#notices, 1, "newer nearby user triggers a local warning")
equal(notices[1]:find("1.0.19", 1, true) ~= nil, true, "warning includes detected version")
equal(notices[1]:find("1.0.18", 1, true) ~= nil, true, "warning includes installed version")
equal(notices[1]:find("CurseForge", 1, true) ~= nil, true, "warning directs the user to CurseForge")
Receive("Q:2.0.0", "GUILD"); Receive("V:3.0.0", "RAID")
equal(#notices, 1, "additional newer versions and channels never repeat the session warning")
Suite.db.updateNotifications = false; check:Apply()
Suite.db.updateNotifications = true; registration = 1; check:Apply()
Receive("V:4.0.0")
equal(#notices, 1, "disable enable and duplicate prefix registration preserve session warning limit")
Advance(30)
local before = #sent
for _ = 1, 50 do Receive("Q:1.0.17") end
Advance(2)
equal(#sent, before, "older queries respect existing channel cooldown")
Advance(28)
equal(#sent, before + 1, "many older queries produce one bounded response")
equal(sent[#sent].message, "V:1.0.18", "reply advertises only this installation")
equal(check.timer, nil, "response does not leave polling running")
before = #sent
Receive("V:1.0.17"); Advance(31)
equal(#sent, before, "responses never cause reply loops")
guild, group, raid, instance = true, true, true, true
check.events:GetScript("OnEvent")(check.events, "GROUP_ROSTER_UPDATE")
Advance(2)
local seen = {}; for index = before + 1, #sent do seen[sent[index].channel] = true end
equal(seen.GUILD, true, "discovery includes guild members")
equal(seen.RAID, true, "discovery includes raid members")
equal(seen.INSTANCE_CHAT, true, "discovery includes instance groups")
equal(seen.PARTY, nil, "raid discovery avoids duplicate party sends")
raid, instance = false, false
check.events:GetScript("OnEvent")(check.events, "GROUP_ROSTER_UPDATE"); Advance(2)
equal(sent[#sent].channel, "PARTY", "party distribution follows current group type")
Receive("Q:1.0.17", "GUILD")
guild, group = false, false
before = #sent
Advance(30)
equal(#sent, before + 1, "only pending nearby discovery remains after leaving guild and group")
equal(sent[#sent].channel, "YELL", "departed guild and group routes are discarded before sending")
before = #sent
check:Announce(); Combat(true)
check.events:GetScript("OnEvent")(check.events, "PLAYER_REGEN_DISABLED")
Advance(40)
equal(#sent, before, "combat entry cancels pending transmission")
Combat(false)
check.events:GetScript("OnEvent")(check.events, "PLAYER_REGEN_ENABLED"); Advance(2)
equal(#sent, before + 1, "combat exit resumes bounded discovery")
before = #sent
check:Announce(); Suite.db.updateNotifications = false; check:Apply(); Advance(40)
Receive("V:9.0.0")
equal(#sent, before, "disable cancels all queued sends")
equal(check.timer, nil, "disable clears timer")
equal(#notices, 1, "disabled receive remains silent")
Suite.db.updateNotifications = true; registration = { secret = true }; check:Apply()
equal(check.active, false, "unreadable prefix registration cannot authorize networking")
registration = 0; reject = true; check:Apply(); Advance(2)
equal(check.timer, nil, "native send rejection creates no retry loop")
check:Cancel(); check.active = false; check.events = nil
Combat(true); check:Apply()
equal(check.events, nil, "initialization in combat defers frame creation")
Suite.pending.versionCheck = nil; Combat(false)
equal(check:Newer(check:Version("1.10.0"), check:Version("1.9.99")), true, "version comparison is numeric")
equal(check:Newer(check:Version("2.0.0"), check:Version("1.99.99")), true, "major releases sort numerically")
check:Cancel()
for key in pairs(check) do check[key] = nil end
for key, value in pairs(state) do check[key] = value end
Suite.db, C_ChatInfo, C_Timer, GetTime = old.db, old.api, old.timer, old.time
IsInGuild, IsInGroup, IsInRaid, LE_PARTY_CATEGORY_INSTANCE = old.guild, old.group, old.raid, old.category
Suite.version, Suite.Print = old.version, old.print
