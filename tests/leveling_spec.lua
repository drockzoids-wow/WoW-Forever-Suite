local Suite, equal, Frame, SetCombat, core = ...
local feature = Suite.Leveling
local names = { "UnitXP", "UnitXPMax", "UnitLevel", "IsXPUserDisabled", "GetMoney", "GetTime", "GetServerTime",
    "GetCursorInfo", "IsControlKeyDown", "CreateFrame", "C_Timer", "UIParent", "GameTooltip", "WoWForeverSuiteCharDB" }
local previous = {}; for _, name in ipairs(names) do previous[name] = _G[name] end
local oldDB, oldPending, oldFeatureDB, oldWorld = Suite.db, Suite.pending, feature.db, feature.worldEntered
equal(WoWForeverSuiteCharDB.leveling, feature.db, "core preserves leveling data beside character macro settings")
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
local now, server, xp, maximum, level, money, paused, cursor = 100, 2000000, 100, 1000, 10, 100000, false, nil
local queries, constructed, geometry, ticks, work = 0, 0, 0, {}, {}
local control = false
local function Secret()
    return setmetatable({ secret = true }, { __lt = function() error("secret comparison") end,
        __add = function() error("secret arithmetic") end, __tostring = function() error("secret formatting") end })
end
UnitXP = function(unit) assert(unit == "player"); queries = queries + 1; return xp end
UnitXPMax = function(unit) assert(unit == "player"); queries = queries + 1; return maximum end
UnitLevel = function(unit) assert(unit == "player"); queries = queries + 1; return level end
GetMoney = function() queries = queries + 1; return money end
IsXPUserDisabled = function() return paused end
GetTime = function() return now end
GetServerTime = function() return server end
GetCursorInfo = function() return cursor end
IsControlKeyDown = function() return control end
UIParent = Frame(); UIParent:SetSize(1200, 800)
GameTooltip = Frame(); GameTooltip.owner = Frame(); GameTooltip:Show()
GameTooltip.GetOwner = function(self) return self.owner end
GameTooltip.SetOwner = function(self, owner) self.owner = owner end
GameTooltip.ClearLines = function(self) self.lines = {} end
CreateFrame = function(kind, name, parent)
    assert(not InCombatLockdown(), "leveling construction must wait outside combat")
    constructed = constructed + 1
    local frame = Frame(name)
    frame.objectType, frame.parent = kind, parent
    frame.CreateFontString = function(self) local text = Frame(); text.parent = self; return text end
    frame.IsForbidden = function(self) return self.forbidden or false end
    frame.IsProtected = function(self) return self.protected or false end
    frame.SetMouseClickEnabled = function(self, enabled) assert(not InCombatLockdown()); self.mouseEnabled = enabled end
    frame.SetMouseMotionEnabled = function(self, enabled) assert(not InCombatLockdown()); self.motionEnabled = enabled end
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    for _, method in ipairs({ "SetPoint", "ClearAllPoints", "SetSize", "SetHeight", "SetScale", "SetFrameStrata", "SetFrameLevel", "StartMoving", "SetMovable" }) do
        local original = frame[method]
        frame[method] = function(self, ...)
            assert(not InCombatLockdown(), "leveling geometry cannot change during combat")
            geometry = geometry + 1; return original(self, ...)
        end
    end
    local stop = frame.StopMovingOrSizing
    frame.StopMovingOrSizing = function(self)
        assert(not InCombatLockdown() or self:IsProtected() == false, "combat stop requires an ordinary owned bar")
        return stop(self)
    end
    return frame
end
local function Timer(callback)
    return { callback = callback, Cancel = function(self) self.cancelled = true end }
end
C_Timer = {
    NewTimer = function(delay, callback) equal(delay, 0.05, "level transitions use one short coalescer")
        local timer = Timer(callback); work[#work + 1] = timer; return timer end,
    NewTicker = function(delay, callback) equal(delay, 1, "elapsed and rate display updates once per second")
        local ticker = Timer(callback); ticks[#ticks + 1] = ticker; return ticker end,
}
local function Flush()
    local ready = work; work = {}
    for _, timer in ipairs(ready) do if not timer.cancelled then timer.callback() end end
end
local function Advance(seconds)
    now, server = now + seconds, server + seconds
    local ready = {}; for _, ticker in ipairs(ticks) do if not ticker.cancelled then ready[#ready + 1] = ticker end end
    for _, ticker in ipairs(ready) do ticker.callback() end
end
local function CountTicks()
    local count = 0; for _, ticker in ipairs(ticks) do if not ticker.cancelled then count = count + 1 end end; return count
end
local function LeaveCombat()
    SetCombat(false)
    local pending = Suite.pending; Suite.pending = {}
    for _, callback in pairs(pending) do callback() end
end
local function Fire(event, value) feature:OnEvent(event, value) end
feature.worldEntered, feature.session = nil, nil
WoWForeverSuiteCharDB = { leveling = feature:InitializeCharacter(nil) }
equal(Suite.db.levelingBar, false, "leveling starts independently off")
feature:Apply()
equal(constructed, 0, "disabled leveling creates no frames")
equal(queries, 0, "disabled leveling makes no XP or money queries")
equal(GameTooltip:IsShown(), true, "disabled leveling cannot hide an unrelated tooltip")
Suite.db.levelingBar = true; SetCombat(true); feature:Apply()
equal(constructed, 0, "first combat enable defers construction")
Suite.db.levelingBar = false; feature:Apply(); LeaveCombat()
equal(constructed, 0, "disable cancels queued first enable")
Suite.db.levelingBar = true; feature:Apply()
equal(constructed, 6, "tracker owns its frame, header, body, two controls and event controller")
equal(queries, 0, "login setup waits for world entry before sampling")
equal(feature.frame:GetParent(), UIParent, "leveling does not attach to native HUD frames")
equal(feature.frame.point[1], "TOPLEFT", "initial tracker starts at the screen top left")
equal(feature.frame.point[2], UIParent, "initial bar uses the screen as its anchor")
equal(feature.frame.point[3], "TOPLEFT", "initial tracker follows the screen corner")
equal(feature.frame.point[4], 12, "initial tracker has a small left inset")
equal(feature.frame.point[5], -12, "initial tracker has a small top inset")
equal(feature.header.title.text, "Leveling", "tracker header identifies its content")
equal(feature.frame.width, 224, "tracker uses a compact column width")
equal(feature.frame.height, 142, "expanded tracker fits five vertical rows")
equal(feature.labels[2].point[5] < feature.labels[1].point[5], true, "stats are stacked vertically")
equal(feature.captions[3].text, "Net gold/hour", "row captions identify the net money rate")
equal(feature.labels[3].justifyH, "RIGHT", "stat values align along the right edge")
equal(feature.db.locked, false, "new tracker defaults unlocked")
equal(feature.db.minimized, false, "new tracker defaults expanded")
equal(#feature.labels, 5, "bar contains only the five leveling/session readings")
equal(feature.frame:GetScript("OnUpdate"), nil, "leveling has no per-frame worker")
core.OnEvent(core, "PLAYER_ENTERING_WORLD", true, false)
equal(CountTicks(), 1, "world entry starts one active display ticker")
equal(feature:Snapshot().xp, 0, "world entry establishes an XP baseline")
equal(feature:Snapshot().gold, 0, "world entry establishes a money baseline")
local before = queries
Fire("PLAYER_XP_UPDATE", "pet"); Fire("PLAYER_XP_UPDATE", Secret())
equal(queries, before, "nonplayer and restricted event units cannot trigger XP queries")
Advance(30)
equal(feature:Snapshot().xpRate, nil, "rates wait for the first full minute")
xp = 220; Fire("PLAYER_XP_UPDATE", "player")
money = 110000; Fire("PLAYER_MONEY")
money = 85000; Fire("PLAYER_MONEY")
equal(feature:Snapshot().gold, -15000, "net gold includes both income and spending")
before = queries; Advance(30)
equal(queries, before, "ordinary display ticks do not poll XP or money APIs")
local v = feature:Snapshot()
equal(v.xpRate, 7200, "XP rate divides earned XP by the whole elapsed session")
equal(v.goldRate, -900000, "gold rate retains a negative net result")
equal(v.remaining, 780, "remaining XP uses the current native maximum")
equal(v.nextSeconds, 390, "time to level uses remaining XP at the session pace")
equal(feature.labels[3].text, "-90.00g", "tracker identifies a negative gold rate clearly")
equal(feature.labels[4].text, "~7m", "tracker rounds the estimate up to whole minutes")
feature:Tooltip()
equal(GameTooltip.owner, feature.frame, "leveling tooltip belongs only to the bar")
equal(GameTooltip.lines[4][1], "Net gold: -1g 50s 0c", "tooltip shows exact net gold in ordinary coin units")
Advance(60)
equal(feature:Snapshot().xpRate, 3600, "idle time lowers the session rate")
equal(feature:Snapshot().nextSeconds, 780, "idle time also changes the next-level estimate")
xp = 950; Fire("PLAYER_XP_UPDATE", "player")
local earned = feature.session.xp
Fire("PLAYER_LEVEL_UP", 11); Fire("PLAYER_LEVEL_UP", 11)
equal(#work, 1, "repeated level-up notifications share one pending read")
Flush()
equal(feature.session.xp, earned, "early level payload cannot count old XP twice")
equal(feature:Snapshot().nextSeconds, nil, "unsettled level transition suppresses estimates")
xp, maximum = 25, 1200; Fire("PLAYER_XP_UPDATE", "player")
equal(feature.session.xp, earned, "XP rollover before UnitLevel settles preserves the old boundary")
level = 11; Fire("UNIT_LEVEL", "player")
equal(feature.session.xp, earned + 75, "single-level rollover counts the old remainder plus new XP")
Fire("PLAYER_XP_UPDATE", "player")
equal(feature.session.xp, earned + 75, "duplicate XP events do not double count")
xp = 1190; Fire("PLAYER_XP_UPDATE", "player")
level, xp, maximum = 12, 20, 1400; Fire("PLAYER_XP_UPDATE", "player")
equal(feature.session.xp, 2120, "separately observed consecutive levels retain complete XP totals")
equal(feature.session.xpPartial, false, "observed ordinary rollovers are complete")
level, xp, maximum = 14, 10, 1800; Fire("PLAYER_XP_UPDATE", "player")
equal(feature.session.xp, 2120, "multiple unobserved levels do not invent intermediate XP costs")
equal(feature:Snapshot().nextState, "partial", "partial multi-level tracking disables the estimate")
equal(feature.labels[2].text:find("~", 1, true) ~= nil, true, "known partial XP rate is visibly marked")
feature:ResetSession()
equal(feature.session.xp, 0, "new session resets XP without changing actual player XP")
equal(feature.session.gold, 0, "new session resets net gold")
equal(CountTicks(), 1, "session reset replaces rather than duplicates the display ticker")
xp = 110; Fire("PLAYER_XP_UPDATE", "player"); Advance(60)
paused = true; Fire("DISABLE_XP_GAIN")
equal(feature:Snapshot().nextState, "paused", "paused XP shows no leveling estimate")
equal(feature.labels[4].text, "Paused", "tracker explains paused XP")
paused = Secret(); Fire("ENABLE_XP_GAIN")
equal(feature:Snapshot().nextSeconds, nil, "unknown XP pause state cannot produce an estimate")
paused = false; Fire("ENABLE_XP_GAIN")
equal(feature:Snapshot().nextState, "ready", "explicit false XP pause state permits a complete estimate")
xp = Secret(); Fire("PLAYER_XP_UPDATE", "player")
equal(feature:Snapshot().xp, nil, "restricted XP is unavailable rather than formatted or compared")
equal(feature:Snapshot().nextSeconds, nil, "restricted XP cannot leave a stale estimate")
xp = 210; Fire("PLAYER_XP_UPDATE", "player")
equal(feature.session.xp, 100, "XP recovery does not reconstruct an unreadable interval")
equal(feature:Snapshot().xpPartial, true, "XP recovery remains visibly partial")
money = Secret(); Fire("PLAYER_MONEY")
equal(feature:Snapshot().gold, nil, "restricted money does not display fabricated zero")
money = 60000; Fire("PLAYER_MONEY")
money = 60500; Fire("PLAYER_MONEY")
equal(feature.session.gold, 500, "money recovery only counts subsequent ordinary changes")
equal(feature:Snapshot().goldPartial, true, "money gap remains marked partial")
for _, invalid in ipairs({ -1, math.huge, 0 / 0, Secret() }) do
    maximum = invalid; Fire("PLAYER_XP_UPDATE", "player")
    equal(feature:Snapshot().remaining, nil, "invalid maximum suppresses XP progress safely")
end
xp, maximum = 0, 0; Fire("PLAYER_XP_UPDATE", "player")
equal(feature:Snapshot().percent, nil, "zero maximum does not divide or guess a level cap")
equal(feature:Snapshot().nextSeconds, nil, "zero maximum shows no next-level time")
maximum, xp = 1800, 50; feature:ResetSession()
local ordinaryXP, ordinaryMoney = UnitXP, GetMoney
UnitXP = function() error("XP API unavailable") end; GetMoney = nil
Fire("PLAYER_XP_UPDATE", "player"); Fire("PLAYER_MONEY")
equal(feature:Snapshot().xp, nil, "rejected XP capability is contained")
equal(feature:Snapshot().gold, nil, "missing money capability is contained")
UnitXP, GetMoney = ordinaryXP, ordinaryMoney
feature:ResetSession(); Advance(60)
xp, money = 150, 61500; Fire("PLAYER_XP_UPDATE", "player"); Fire("PLAYER_MONEY")
core.OnEvent(core, "PLAYER_LOGOUT")
local saved = Suite.Copy(feature.db)
equal(saved.checkpoint.xp, 100, "core logout checkpoints earned XP")
equal(saved.checkpoint.gold, 1000, "core logout checkpoints net money")
equal(CountTicks(), 0, "logout cancels all display work")
local function Fresh(state)
    local env = { modules = {}, db = { levelingBar = true }, IsReadable = Suite.IsReadable, BagSpace = Suite.BagSpace,
        AfterCombat = Suite.AfterCombat, pending = Suite.pending, GUI = Suite.GUI, Theme = Suite.Theme }
    assert(loadfile("src/WoWForeverSuite/Leveling.lua"))("WoWForeverSuite", env)
    env.Leveling:InitializeCharacter(state); env.Leveling:Apply()
    return env.Leveling, env
end
now, server, xp, money = now + 15, server + 15, 175, 61300
SetCombat(true)
local beforeConstruction = constructed
local delayed, delayedEnv = Fresh(saved); delayed:OnWorld(false, true)
equal(constructed, beforeConstruction, "a combat reload defers all new bar construction")
equal(delayed.db.checkpoint ~= nil, true, "combat world entry retains the reload checkpoint")
LeaveCombat()
equal(delayed:Snapshot().seconds, 75, "deferred combat setup continues the reload session's elapsed time")
equal(delayed:Snapshot().xp, 125, "deferred combat setup retains and updates the saved XP baseline")
delayedEnv.db.levelingBar = false; delayed:Apply()
local restored, restoredEnv = Fresh(saved)
restored:OnWorld(false, true)
equal(restored:Snapshot().seconds, 75, "reload includes its loading time")
equal(restored:Snapshot().xp, 125, "reload accounts for newly readable XP exactly once")
equal(restored:Snapshot().gold, 800, "reload retains and updates the same net money session")
restored:OnWorld(false, false)
equal(restored:Snapshot().xp, 125, "zoning and duplicate world events do not reset or double count")
restoredEnv.db.levelingBar = false; restored:Apply()
now, server = now + 5000, server + 5000
local fresh, freshEnv = Fresh(saved); fresh:OnWorld(true, false)
equal(fresh:Snapshot().seconds, 0, "fresh login excludes offline time")
equal(fresh:Snapshot().xp, 0, "fresh login starts a new XP baseline")
equal(fresh:Snapshot().gold, 0, "fresh login starts a new money baseline")
freshEnv.db.levelingBar = false; fresh:Apply()
local ambiguous, ambiguousEnv = Fresh(saved); ambiguous:OnWorld(Secret(), true)
equal(ambiguous:Snapshot().seconds, 0, "unknown login flags do not restore an old session")
ambiguousEnv.db.levelingBar = false; ambiguous:Apply()
local login, loginEnv = Fresh(saved); login:OnWorld(true, true)
equal(login:Snapshot().seconds, 0, "initial-login flag wins over a contradictory reload flag")
loginEnv.db.levelingBar = false; login:Apply()
local noServer, noServerEnv = Fresh(saved)
local nativeServer = GetServerTime; GetServerTime = nil; noServer:OnWorld(false, true); GetServerTime = nativeServer
equal(noServer:Snapshot().seconds, 60, "missing server time retains only saved elapsed time")
equal(noServer:Snapshot().timePartial, true, "missing reload timing is disclosed as partial")
equal(noServer:Snapshot().nextSeconds, nil, "uncertain reload time suppresses the estimate")
noServerEnv.db.levelingBar = false; noServer:Apply()
for _, corrupt in ipairs({ Secret(), { version = 1, xp = Secret(), gold = 0, elapsed = 1 },
    { version = 1, elapsed = -1, xp = 0, gold = 0 } }) do
    equal(feature:ValidateCheckpoint(corrupt), nil, "invalid checkpoint never becomes live session data")
end
local bad = Suite.Copy(saved.checkpoint); bad.lastXP = bad.maxXP + 1
equal(feature:ValidateCheckpoint(bad), nil, "impossible saved XP progress is rejected")
bad = Suite.Copy(saved.checkpoint); bad.goldPartial = Secret()
equal(feature:ValidateCheckpoint(bad), nil, "restricted checkpoint flags cannot be serialized or tested")
feature:ResetSession()
local nativeTime = GetTime; GetTime = function() return Secret() end
equal(feature:Snapshot().seconds, nil, "restricted clock data cannot drive a rate")
feature:SaveSession(); equal(feature.db.checkpoint, nil, "unknown elapsed time is not saved as a guessed duration")
GetTime = nativeTime; feature:ResetSession()
cursor = Secret(); feature.header.OnDragStart()
equal(feature.moving, nil, "unknown cursor data cannot start a drag")
cursor = "item"; feature.header.OnDragStart()
equal(feature.moving, nil, "holding an item does not start a bar drag")
cursor = nil; feature.header.OnDragStart()
equal(feature.moving, true, "plain left-drag moves the owned bar")
feature.frame.centerX, feature.frame.centerY = 900, 600
feature.header.OnDragStop()
equal(feature.db.position.x, 0.25, "horizontal bar position saves as a character-relative fraction")
equal(feature.db.position.y, 0.25, "vertical bar position saves as a character-relative fraction")
equal(feature.frame.point[4], 188, "saved tracker center converts to its fixed top-left anchor")
local positioned, positionEnv = Fresh({ position = Suite.Copy(feature.db.position) })
equal(positioned.frame.point[4], 188, "a fresh character-state load restores the dragged horizontal position")
equal(positioned.frame.point[5], 271, "a fresh character-state load restores the dragged vertical position")
UIParent:SetSize(1600, 900); positioned:OnEvent("DISPLAY_SIZE_CHANGED")
equal(positioned.frame.point[4], 288, "saved placement scales with screen width")
equal(positioned.frame.point[5], 296, "saved placement scales with screen height")
positionEnv.db.levelingBar = false; positioned:Apply(); UIParent:SetSize(1200, 800)
feature.frame:SetScale(0.75); feature.header.OnDragStart(); feature.header.OnDragStop()
equal(feature.db.position.x, 0.0625, "saved placement accounts for the frame's effective scale")
feature.frame:SetScale(1)
-- Header controls change presentation only; locking preserves hover but gives
-- ordinary world clicks back to the layer below the tracker.
local trackedSession, ticker = feature.session, feature.ticker
local behindClicks, openedWhileLocked = 0, 0
local nativeOpen = Suite.GUI.OpenPage
Suite.GUI.OpenPage = function() openedWhileLocked = openedWhileLocked + 1 end
before = queries
feature.lockButton.OnClick()
equal(feature.db.locked, true, "header lock persists this character's locked state")
equal(feature.frame.mouseEnabled, false, "locked stats surface is click-through")
equal(feature.header.mouseEnabled, false, "locked header also passes clicks through")
equal(feature.frame.motionEnabled, true, "locked stats retain mouse motion for hover")
equal(feature.header.motionEnabled, true, "locked header retains hover input")
equal(feature.lockButton.mouseEnabled, true, "lock control remains clickable for unlocking")
equal(feature.minimizeButton.mouseEnabled, true, "minimize control remains clickable while locked")
equal(feature.frame.movable, false, "locking also disables movement")
if feature.frame.mouseEnabled then feature.frame.OnClick(feature.frame, "RightButton") else behindClicks = behindClicks + 1 end
equal(behindClicks, 1, "locked hit-test model routes ordinary clicks to the layer below")
equal(openedWhileLocked, 0, "locked ordinary clicks cannot open settings")
feature.header.OnDragStart(); equal(feature.moving, nil, "locked header cannot start movement")
feature.frame.OnEnter()
equal(GameTooltip.owner, feature.frame, "locked stats still display their information tooltip")
feature.lockButton.OnEnter()
equal(GameTooltip.lines[1][1], "Unlock leveling tracker", "lock hover identifies how to unlock")
feature.minimizeButton.OnClick()
equal(feature.frame.height, 24, "minimized tracker is only the header high")
equal(feature.body:IsShown(), false, "minimize hides all five stat rows")
equal(feature.labels[1]:GetParent(), feature.body, "stat values hide with the minimized body")
equal(feature.captions[1]:GetParent(), feature.body, "row captions hide with the minimized body")
equal(feature.minimizeButton.label.text, "+", "collapsed header offers an expand control")
equal(feature.session, trackedSession, "minimizing preserves the active accounting session")
equal(feature.ticker, ticker, "header controls reuse the existing active ticker")
equal(CountTicks(), 1, "minimizing creates no extra workers")
equal(queries, before, "presentation controls make no XP or money queries")
local remembered, rememberedEnv = Fresh(Suite.Copy(feature.db))
equal(remembered.db.locked, true, "lock choice survives a character-state reload")
equal(remembered.frame.height, 24, "minimized choice survives a character-state reload")
equal(remembered.frame.mouseEnabled, false, "restored lock reapplies click-through")
rememberedEnv.db.levelingBar = false; remembered:Apply()
local clean, cleanEnv = Fresh({ locked = Secret(), minimized = "yes" })
equal(clean.db.locked, false, "restricted saved lock state uses the ordinary unlocked default")
equal(clean.db.minimized, false, "invalid saved minimized state uses expanded default")
cleanEnv.db.levelingBar = false; clean:Apply()
feature.lockButton.OnClick()
equal(feature.frame.mouseEnabled, true, "unlock restores ordinary surface clicks")
equal(feature.frame.motionEnabled, true, "unlock retains hover input")
feature.db.position = { x = 0.1, y = 0.1 }; feature:Place()
local left, top = feature.frame.point[4], feature.frame.point[5]
feature.minimizeButton.OnClick() -- Expand without moving the header.
equal(feature.frame.point[4], left, "expanding holds the header's horizontal anchor")
equal(feature.frame.point[5], top, "expanding holds the header's vertical anchor")
feature.minimizeButton.OnClick()
feature.frame.centerX = UIParent:GetWidth() / 2 + left + feature.frame.width / 2
feature.frame.centerY = UIParent:GetHeight() / 2 + top - feature.frame.height / 2
feature.header.OnDragStart(); feature.header.OnDragStop()
equal(math.abs(feature.db.position.y - 0.1) < 0.000001, true, "saving a collapsed drag retains the expanded-center position convention")
equal(math.abs(feature.frame.point[5] - top) < 0.000001, true, "releasing a collapsed header cannot jump vertically")
feature.minimizeButton.OnClick()
equal(feature.frame.height, 142, "expand restores all rows")
equal(feature.body:IsShown(), true, "expanded stat body is visible again")
equal(math.abs(feature.frame.point[5] - top) < 0.000001, true, "restoring rows keeps the dragged header anchored")
local lastPosition = feature.db.position
feature.header.OnDragStart(); feature.lockButton.OnClick()
equal(feature.moving, nil, "locking during a drag stops it without committing")
equal(feature.db.position, lastPosition, "locking during a drag retains the previous saved position")
feature.lockButton.OnClick()
SetCombat(true)
before = geometry
feature.lockButton.OnClick(); feature.minimizeButton.OnClick()
equal(feature.locked, false, "combat lock changes wait before altering input")
equal(feature.minimized, false, "combat minimize changes wait before changing geometry")
equal(geometry, before, "combat header controls perform no layout or movement writes")
feature.lockButton.OnClick(); feature.minimizeButton.OnClick()
LeaveCombat()
equal(feature.locked, false, "final combat lock choice wins")
equal(feature.minimized, false, "final combat expansion choice wins")
equal(feature.session, trackedSession, "deferred presentation never resets the leveling session")
SetCombat(true); feature.lockButton.OnClick(); feature.minimizeButton.OnClick(); LeaveCombat()
equal(feature.locked, true, "a queued lock applies after combat")
equal(feature.frame.mouseEnabled, false, "queued lock restores click-through after combat")
equal(feature.frame.height, 24, "queued minimize applies the header-only size after combat")
feature.lockButton.OnClick(); feature.minimizeButton.OnClick()
feature:SetLocked(Secret()); feature:SetMinimized("yes")
equal(feature.db.locked, false, "restricted live lock choices cannot become input settings")
equal(feature.db.minimized, false, "invalid live minimize choices are rejected")
Suite.GUI.OpenPage = nativeOpen
local opened, openPage = nil, Suite.GUI.OpenPage
Suite.GUI.OpenPage = function(_, page) opened = page end
feature.frame.OnMouseDown(); feature.frame.OnClick(feature.frame, "RightButton")
equal(opened, "leveling", "ordinary right-click opens leveling settings")
Suite.GUI.OpenPage = openPage
control = true; feature.frame.OnClick(feature.frame, "RightButton"); control = false
equal(next(feature.db.position), nil, "Ctrl-right-click clears only this character's saved bar position")
equal(feature.frame.point[1], "TOPLEFT", "position reset restores top left")
feature.header.OnDragStart()
local committed = feature.db.position
SetCombat(true); Fire("PLAYER_REGEN_DISABLED")
equal(feature.frame.moving, false, "combat entry stops the ordinary owned frame's movement")
equal(feature.db.position, committed, "interrupted drag cannot save a combat position")
before = geometry
xp = xp + 20; Fire("PLAYER_XP_UPDATE", "player"); money = money + 300; Fire("PLAYER_MONEY"); Advance(60)
equal(feature:Snapshot().xp, 20, "ordinary XP tracking continues during combat")
equal(feature:Snapshot().gold, 300, "ordinary money tracking continues during combat")
equal(geometry, before, "combat data changes perform no geometry writes")
feature.header.OnDragStart(); equal(feature.moving, nil, "combat cannot begin a tracker drag")
LeaveCombat()
equal(feature.frame.point[1], "TOPLEFT", "combat exit restores the last committed tracker position")
SetCombat(true); feature.frame.protected = true
local oldText = feature.labels[2].text
xp = xp + 20; Fire("PLAYER_XP_UPDATE", "player")
equal(feature.labels[2].text, oldText, "unexpected protection suppresses combat widget writes")
feature:SetMinimized(true)
equal(type(Suite.pending.levelingPresentation), "function", "protected combat presentation stays queued")
Suite.db.levelingBar = false; feature:Apply()
equal(Suite.pending.levelingPresentation, nil, "disable cancels queued presentation changes")
equal(CountTicks(), 0, "disable cancels all rate display tickers immediately")
equal(next(feature.events.registered), nil, "disabled leveling releases its engine events")
feature.frame.protected = false; LeaveCombat()
equal(feature.frame:IsShown(), false, "deferred disable hides the bar")
Suite.db.levelingBar = true; feature:Apply()
Fire("PLAYER_LEVEL_UP", level + 1)
local obsolete = feature.work
Suite.db.levelingBar = false; feature:Apply()
before = queries; obsolete.callback(); Advance(60)
equal(queries, before, "cancelled work and tickers cannot resume disabled tracking")
equal(feature.session, nil, "disabled feature retains no active session")
equal(#Suite.SettingsCatalog:Search("xp gold hour"), 1, "settings search finds the focused leveling option")
local selected, shown = Suite.GUI.page, Suite.GUI.frame:IsShown()
SlashCmdList.WOWFOREVERSUITE("leveling")
equal(Suite.GUI.page, "leveling", "leveling command opens its dedicated settings")
SlashCmdList.WOWFOREVERSUITE("xp")
equal(Suite.GUI.page, "leveling", "XP shortcut reaches the same settings")
for index in ipairs(Suite.SettingsCatalog.pages.leveling.rows) do
    equal(Suite.GUI.rowOffsets[index] + Suite.GUI.rows[index].height <= Suite.GUI.contentHeight - 36, true,
        "all leveling controls fit the settings scroll range")
end
Suite.db.levelingBar = true; feature:Apply(); feature:SetMinimized(false)
local settingsSession = feature.session
Suite.GUI:Action("levelingLock")
equal(feature.db.locked, true, "settings provide an independent way to lock or unlock")
equal(Suite.GUI.rows[2].value.text, "Locked", "settings report the saved lock state")
Suite.GUI:Action("levelingMinimize")
equal(feature.db.minimized, true, "settings can minimize without reaching header controls")
equal(Suite.GUI.rows[3].value.text, "Minimized", "settings report the saved minimized state")
equal(feature.session, settingsSession, "settings presentation controls retain current session data")
Suite.db.levelingBar = false; feature:Apply()
Suite.GUI:Select(selected); Suite.GUI.frame:SetShown(shown)
feature.db, feature.worldEntered = oldFeatureDB, oldWorld
Suite.db, Suite.pending = oldDB, oldPending
for _, name in ipairs(names) do _G[name] = previous[name] end
SetCombat(false)
