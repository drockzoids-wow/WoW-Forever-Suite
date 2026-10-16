local Suite, equal, Frame, SetCombat = ...
local mail = Suite.Mail
local names = { "CreateFrame", "C_Timer", "UnitGUID", "UnitName", "UnitClass", "UnitLevel", "UnitFactionGroup",
    "GetCurrentRegion", "GetNormalizedRealmName", "GetRealmName", "C_GameRules", "C_AutoComplete", "Enum", "RAID_CLASS_COLORS", "MailFrame", "SendMailFrame",
    "MailFrameTab2", "SendMailFrameLockSendMail", "SendMailNameEditBox", "SendMailSubjectEditBox", "MailFrameTab_OnClick", "SendMailFrame_SendMail" }
local old = {}; for _, name in ipairs(names) do old[name] = _G[name] end
local oldDB, oldPending = Suite.db, Suite.pending
local timers, constructed, writes, sends, tabs = {}, 0, 0, 0, 0
local player = { name = "Zoids", surname = "Ward", realm = "ClassicBetaPvE", region = 110, class = "WARRIOR", level = 30,
    faction = "Alliance", guid = "Player-110-1" }
local function Flush()
    local queued = timers; timers = {}
    for _, timer in ipairs(queued) do if not timer.cancelled then timer.callback() end end
end
local function TimerCount()
    local count = 0; for _, timer in ipairs(timers) do if not timer.cancelled then count = count + 1 end end
    return count
end
local function Fire(event, ...) mail.events.OnEvent(mail.events, event, ...) end
local function DrainCombat()
    SetCombat(false)
    local queued = Suite.pending; Suite.pending = {}
    for _, callback in pairs(queued) do callback() end
    Flush()
end
local function Native(event)
    MailFrame.OnEvent(MailFrame, event)
end
local function Find(name)
    for _, entry in ipairs(mail:List(true)) do
        if entry.name == name or entry.name:match("^(%S+)") == name then return entry end
    end
end
local function NewMailFrame()
    local frame = CreateFrame("Frame")
    frame:SetSize(338, 424); frame.rect = { 80, 100, 338, 424 }
    frame.OnEvent = function(_, event)
        if event == "MAIL_SEND_SUCCESS" then
            SendMailNameEditBox:SetText(""); SendMailSubjectEditBox:SetText("")
        end
    end
    frame:Hide()
    return frame
end
CreateFrame = function(...)
    assert(not InCombatLockdown(), "mail creates no frames in combat")
    constructed = constructed + 1
    local frame = old.CreateFrame(...)
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    frame.IsForbidden = function(self) return self.forbidden or false end
    frame.IsProtected = function(self) return self.protected or false end
    frame.SetTextInsets = function(self, ...) self.textInsets = { ... } end
    frame.SetMaxLetters = function(self, value) self.maxLetters = value end
    frame.SetFocus = function(self) self.focused = true end
    frame.ClearFocus = function(self) self.focused = false end
    frame.SetText = function(self, text)
        self.text = text
        if self.OnTextChanged then self.OnTextChanged(self, false) end
    end
    frame.Show = function(self)
        if not self.shown then self.shown = true; if self.OnShow then self.OnShow(self) end end
    end
    frame.Hide = function(self)
        if self.shown then self.shown = false; if self.OnHide then self.OnHide(self) end end
    end
    frame.SetPoint = function(self, ...)
        assert(not InCombatLockdown(), "mail does not set anchors in combat")
        self.point = { ... }
    end
    frame.SetSize = function(self, width, height)
        assert(not InCombatLockdown(), "mail does not size frames in combat")
        self.width, self.height = width, height
    end
    return frame
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
UnitGUID = function() return player.guid end
UnitName = function() return player.name, player.surname end
UnitClass = function() return player.class, player.class end
UnitLevel = function() return player.level end
UnitFactionGroup = function() return player.faction end
GetCurrentRegion = function() return player.region end
GetNormalizedRealmName = function() return player.realm end
GetRealmName = function() return "Fallback Realm" end
C_GameRules = { IsHardcoreActive = function() return player.hardcore or false end }
C_AutoComplete = nil
RAID_CLASS_COLORS = { WARRIOR = { r = 0.78, g = 0.61, b = 0.43 }, MAGE = { r = 0.4, g = 0.8, b = 1 } }
MailFrame = nil
MailFrameTab2 = nil
SendMailFrame = CreateFrame("Frame"); SendMailFrame:Hide()
SendMailFrameLockSendMail = CreateFrame("Frame"); SendMailFrameLockSendMail:Hide()
SendMailNameEditBox = CreateFrame("EditBox")
SendMailNameEditBox:SetScript("OnTextChanged", function() writes = writes + 1 end)
SendMailSubjectEditBox = CreateFrame("EditBox")
MailFrameTab_OnClick = function(_, id)
    tabs = tabs + 1
    SendMailFrame:Hide()
    if id == 2 then SendMailFrame:Show() end
end
SendMailFrame_SendMail = function() sends = sends + 1 end
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
equal(Suite.db.mailHelper, false, "mail helper starts off")
equal(Suite.db.mailRememberRecipient, false, "recipient memory starts off independently")
local baseline = constructed
mail:Apply()
equal(constructed, baseline, "disabled mail creates no frames")
equal(TimerCount(), 0, "disabled mail creates no timers")

SetCombat(true); Suite.db.mailHelper = true; mail:Apply()
equal(constructed, baseline, "initial enable creates no event or panel frames in combat")
equal(mail.active, nil, "initial enable remains deferred in combat")
Suite.db.mailHelper = false; mail:Apply(); DrainCombat()
equal(constructed, baseline, "disable cancels initial deferred construction")

Suite.db.mailHelper = true
Suite.db.inventory.characters = {
    ["Alt-2"] = { name = "Arcanist Ember", realm = "ClassicBetaPvE", region = 110, class = "MAGE" },
    ["Alt-3"] = { name = "Arcanist Frost", realm = "ClassicBetaPvP", region = 110, class = "MAGE" },
    ["Alt-4"] = { name = "Foreign Traveler", realm = "ClassicBetaPvE", region = 1 },
    ["Alt-5"] = { name = { secret = true }, realm = "ClassicBetaPvE", region = 110 },
}
mail:Apply()
equal(mail.active, true, "mail enables with late native UI absent")
equal(mail.frame, nil, "mail panel waits for native mailbox")
equal(Find("Zoids").current, true, "beta-110 current character is recorded")
equal(Find("Zoids").level, 30, "recorded character level")
MailFrame = NewMailFrame()
Fire("ADDON_LOADED"); Flush()
equal(mail.bound, MailFrame, "late-loaded mailbox is hooked")
equal(mail.frame, nil, "hidden mailbox does not create helper")
MailFrame:Show()
equal(mail.frame, nil, "inbox opening does not construct contacts panel")
equal(mail.visit, true, "inbox still starts the mailbox visit")
MailFrameTab_OnClick(nil, 2)
equal(mail.frame:IsShown(), true, "character helper shows on selecting native Send Mail")
equal(mail.frame:GetParent(), MailFrame, "helper follows native mailbox hierarchy and scale")
equal(#mail:List(), 2, "existing Suite alts retain full names and rulesets while current character is hidden")
equal(Find("Foreign"), nil, "other-region records stay outside mail list")
equal(mail.frame.point[1], "TOPLEFT", "helper docks right with available room")
equal(mail.rows[1].name.textColor[2], 0.8, "class color in recorded contact row")
equal(mail.search.fontFlags, "", "edit-box font supplies required flags")
equal(mail.search.maxLetters, 77, "search bounded to native recipient length")
equal(mail.rows[1].remove:GetParent(), mail.rows[1], "remove control distinct from recipient click")
equal(mail.frame.OnUpdate, nil, "mail has no idle updater")

local arc = Find("Arcanist")
local oldWrites = writes
local previousTabs = tabs
mail:Choose(arc.key)
equal(tabs, previousTabs + 1, "contact preserves native compose-tab handling")
equal(SendMailNameEditBox:GetText(), "Arcanist Ember", "contact fills first and last name without a realm suffix")
equal(writes, oldWrites + 1, "native recipient text callback retained")
equal(SendMailSubjectEditBox.focused, true, "subject receives focus after contact choice")
equal(sends, 0, "choosing contact never sends mail")
mail:Choose(Find("Zoids").key)
equal(writes, oldWrites + 1, "current character does not fill itself")
SendMailFrameLockSendMail:Show(); mail:Choose(arc.key)
equal(writes, oldWrites + 1, "locked attachment confirmation is respected")
SendMailFrameLockSendMail:Hide()
SendMailNameEditBox.protected = true; mail:Choose(arc.key)
equal(writes, oldWrites + 1, "protected recipient skipped")
SendMailNameEditBox.protected = false
SendMailNameEditBox.forbidden = true; mail:Choose(arc.key)
equal(writes, oldWrites + 1, "forbidden recipient skipped")
SendMailNameEditBox.forbidden = false
MailFrameTab2 = CreateFrame("Button"); MailFrameTab2:Hide()
mail:Choose(arc.key)
equal(writes, oldWrites + 1, "hidden native compose tab cannot be bypassed")
MailFrameTab2:Show()
SendMailNameEditBox.IsEnabled = function() return false end
mail:Choose(arc.key)
equal(writes, oldWrites + 1, "disabled native recipient cannot be filled")
SendMailNameEditBox.IsEnabled = function() return { secret = true } end
mail:Choose(arc.key)
equal(writes, oldWrites + 1, "restricted native input state cannot be used as permission")
SendMailNameEditBox.IsEnabled = nil
mail.search:SetText("Arcanist")
mail:ConfirmRemove(arc.key)
MailFrameTab_OnClick(nil, 1)
equal(mail.frame:IsShown(), false, "switching to Inbox immediately hides contacts")
equal(mail.confirm, nil, "tab hide cancels contact confirmation")
equal(mail.visit, true, "tab switch retains the current mailbox visit")
oldWrites = writes; previousTabs = tabs
mail:Choose(arc.key)
equal(writes, oldWrites, "stale contact click on Inbox cannot change To")
equal(tabs, previousTabs, "stale contact click cannot switch Inbox to compose")
mail:Schedule(); Flush()
equal(mail.frame:IsShown(), false, "queued refresh on Inbox cannot reveal contacts")
MailFrameTab_OnClick(nil, 2)
equal(mail.frame:IsShown(), true, "returning to Send Mail shows contacts")
equal(mail.search:GetText(), "Arcanist", "contact search survives a mailbox tab switch")
mail.search:SetText("")

mail.search:SetText("pvp")
equal(#mail:List(), 1, "ruleset search is literal and case-insensitive")
mail.search:SetText("[")
equal(#mail:List(), 0, "search punctuation is not a Lua pattern")
equal(mail.empty:IsShown(), true, "empty search explains no matches")
mail.search:SetText("")
SendMailNameEditBox:SetText("  Courier   Post  ")
mail:SaveRecipient()
equal(Find("Courier").address, "Courier Post", "manual recipient keeps both names and normalizes spaces")
mail:SaveRecipient()
equal(#mail:List(), 3, "repeated recipient saves deduplicate")
SendMailNameEditBox:SetText("Localalt Post"); mail:SaveRecipient()
equal(Find("Localalt").ruleset, "PvE", "typed recipient is recorded under the current ruleset")
for _, bad in ipairs({ "", "A1", "Bad|cff00ff00", "Name-", "Name-/realm", "Name\nRealm", "Drock",
    "Drock Bracketfix-ClassicBetaPvE", "Drock Extra Bracketfix", "Drock Bracket1", "Drock\tBracketfix" }) do
    local before = #mail:List()
    SendMailNameEditBox:SetText(bad); mail:SaveRecipient()
    equal(#mail:List(), before, "invalid recipient not saved: " .. bad)
end
SendMailNameEditBox.text = { secret = true }; mail:SaveRecipient()
equal(#mail:List(), 4, "secret recipient never saved or parsed")
SendMailNameEditBox.text = ""

for index = 1, 9 do mail:Store("Alt" .. string.char(64 + index) .. " Letter", "PvE", 110, nil, "MAGE", index) end
mail:Refresh()
equal(#mail.rows, 6, "list reuses six rows for long rosters")
equal(mail.next.enabled, true, "long list has accessible next page")
mail.next.OnClick()
equal(mail.page, 2, "next-page contact navigation")
mail.frame.OnMouseWheel(mail.frame, -1)
equal(mail.page, 3, "wheel contact navigation")
mail.next.OnClick()
equal(mail.page, 3, "last page is clamped")
mail.sortButtons.level.OnClick()
equal(mail:List()[1].name, "AltI Letter", "first level sort is descending among alts")
mail.sortButtons.level.OnClick()
equal(mail.ascending, true, "sort direction toggles")
mail.sortButtons.ruleset.OnClick()
equal(mail.sort, "ruleset", "ruleset sorting available")

mail:ConfirmRemove(arc.key)
equal(mail.confirmation:IsShown(), true, "contact removal requires inline confirmation")
mail.confirmation.cancel.OnClick()
equal(#mail:List(), 13, "cancel preserves contact")
mail:ConfirmRemove(arc.key); mail:RemoveConfirmed()
equal(#mail:List(), 12, "confirmed removal affects only chosen contact")
mail:SeedRecordedCharacters()
equal(#mail:List(), 12, "inventory seeding does not resurrect removed contact")
local saved = Suite.Copy(Suite.db)
Suite.db = Suite.InitializeDB(saved); mail.removed = nil; mail:Apply(); mail:SeedRecordedCharacters()
equal(#mail:List(), 12, "contact removal survives database reload")
local zoids = Find("Zoids")
mail:ConfirmRemove(zoids.key)
equal(mail.confirm, nil, "current character removal is disabled")
player.name = "Renamed"; mail:RecordPlayer()
equal(Find("Zoids"), nil, "GUID rename removes obsolete address")
equal(Find("Renamed").current, true, "renamed character retains current identity")
player.name = "Zoids"; mail:RecordPlayer()
mail:Store("Regional Letter", "PvP", 1, player.guid)
equal(Find("Zoids").current, true, "identical foreign GUID cannot remove current region identity")

local beforeInvalid = #mail:List()
for _, region in ipairs({ 0, -1, 110.5, math.huge, { secret = true } }) do
    player.region = region; mail:RecordPlayer()
    equal(#mail:List(), 0, "unavailable region never mixes character rosters")
end
player.region = 110
equal(#mail:List(), beforeInvalid, "invalid regions preserve previous roster")
player.name = { secret = true }; mail:RecordPlayer()
player.name = "Zoids"
player.level = { secret = true }; player.class = { secret = true }; player.faction = { secret = true }
mail:RecordPlayer()
equal(Find("Zoids").level, 30, "secret optional fields preserve readable prior metadata")
player.level, player.class, player.faction = 31, "WARRIOR", "Alliance"
Fire("PLAYER_LEVEL_UP"); Flush()
equal(Find("Zoids").level, 31, "level event updates from current player data")
Fire("PLAYER_LEVEL_UP", 32); Flush()
equal(Find("Zoids").level, 32, "synchronous level payload wins over a stale getter")
player.level = 32

MailFrame.rect = { 780, 100, 338, 424 }; MailFrame:SetPoint("CENTER"); Flush()
equal(mail.frame.point[1], "TOPRIGHT", "helper flips left near screen edge")
MailFrame.rect = { { secret = true }, 100, 338, 424 }; mail:Place()
equal(mail.frame.point[1], "TOPLEFT", "secret geometry uses safe default without arithmetic")
MailFrame.rect = { 80, 100, 338, 424 }
for index = 1, 50 do MailFrame:SetPoint("CENTER"); Fire("ADDON_LOADED") end
equal(TimerCount(), 1, "native reflows and addon bursts coalesce")
Flush(); equal(TimerCount(), 0, "mail event work leaves no idle timer")

Suite.db.mailRememberRecipient = true; mail:Apply()
SendMailNameEditBox:SetText("Arcanist Ember")
SendMailSubjectEditBox:SetText("A letter")
SendMailFrame_SendMail()
equal(mail.sendPending, true, "native send capture waits for completion")
oldWrites = writes; mail:Choose(Find("Courier").key)
equal(writes, oldWrites, "contact choice is blocked during pending native send")
Native("MAIL_SEND_SUCCESS")
equal(SendMailNameEditBox:GetText(), "Arcanist Ember", "recipient restored after native success reset")
equal(SendMailSubjectEditBox:GetText(), "", "native subject reset preserved")
equal(mail.sendPending, nil, "successful send clears pending state")
MailFrameTab_OnClick(nil, 1)
equal(mail.frame:IsShown(), false, "successful sending does not keep contacts on Inbox")
equal(mail.lastRecipient, "Arcanist Ember", "Inbox switch preserves same-visit recipient memory")
mail:Apply()
equal(mail.frame:IsShown(), false, "settings reapply on Inbox cannot reveal contacts")
MailFrameTab_OnClick(nil, 2)
equal(mail.frame:IsShown(), true, "Send Mail restores contacts after Inbox")
SendMailNameEditBox:SetText("Courier Post"); SendMailFrame_SendMail()
Native("MAIL_FAILED")
equal(mail.pendingRecipient, nil, "failed mail never stores recipient for reset")
SendMailNameEditBox:SetText(""); Native("MAIL_SEND_SUCCESS")
equal(SendMailNameEditBox:GetText(), "", "unmatched success does not insert stale recipient")
Suite.db.mailRememberRecipient = false; mail:Apply()
SendMailNameEditBox:SetText("Courier Post"); SendMailFrame_SendMail(); Native("MAIL_SEND_SUCCESS")
equal(SendMailNameEditBox:GetText(), "", "disabled recipient memory respects native reset")
Suite.db.mailRememberRecipient = true; mail:Apply()
SendMailNameEditBox:SetText("Courier Post"); SendMailFrame_SendMail()
MailFrame:Hide(); Fire("MAIL_CLOSED")
equal(mail.lastRecipient, nil, "closing mail clears recipient memory")
equal(mail.pendingRecipient, nil, "closing mail cancels pending recipient")
equal(mail.frame:IsShown(), false, "helper hides with native mailbox")
MailFrame:Show(); SendMailNameEditBox:SetText(""); Native("MAIL_SEND_SUCCESS")
equal(SendMailNameEditBox:GetText(), "", "reopening does not restore previous visit")

Suite.db.mailHelper = false; mail:Apply()
equal(mail.frame:IsShown(), false, "helper toggle hides panel independently")
SendMailNameEditBox:SetText("Arcanist Ember"); SendMailFrame_SendMail(); Native("MAIL_SEND_SUCCESS")
equal(SendMailNameEditBox:GetText(), "Arcanist Ember", "recipient memory works with helper off")
Suite.db.mailHelper = true; mail:Apply()
SendMailNameEditBox:SetText("Courier Post"); SendMailFrame_SendMail()
SetCombat(true); Fire("PLAYER_REGEN_DISABLED"); Native("MAIL_SEND_SUCCESS")
equal(SendMailNameEditBox:GetText(), "", "success during combat leaves native reset intact")
equal(type(Suite.pending.mailRecipient), "function", "recipient restoration waits for combat")
DrainCombat()
equal(SendMailNameEditBox:GetText(), "Courier Post", "recipient restoration completes outside combat")
SendMailFrame_SendMail()
SetCombat(true); Fire("PLAYER_REGEN_DISABLED"); Native("MAIL_SEND_SUCCESS")
SendMailNameEditBox:SetText("Newchoice Letter"); DrainCombat()
equal(SendMailNameEditBox:GetText(), "Newchoice Letter", "deferred restore preserves a newer recipient")
SetCombat(true); Fire("PLAYER_REGEN_DISABLED"); MailFrameTab_OnClick(nil, 1)
DrainCombat()
equal(mail.frame:IsShown(), false, "combat exit on Inbox cannot reveal contacts")
MailFrameTab_OnClick(nil, 2)
equal(mail.frame:IsShown(), true, "Send Mail selection after combat returns contacts")
SetCombat(true); Fire("PLAYER_REGEN_DISABLED")
equal(mail.frame:IsShown(), false, "combat entry hides helper")
oldWrites = writes; mail:Choose(Find("Courier").key)
equal(writes, oldWrites, "combat forbids recipient choice")
for index = 1, 30 do Fire("ADDON_LOADED") end
equal(TimerCount(), 0, "combat bursts have no polling timer")
equal(type(Suite.pending.mailRefresh), "function", "combat keeps one deferred mailbox refresh")
Suite.db.mailHelper, Suite.db.mailRememberRecipient = false, false; mail:Apply()
equal(Suite.pending.mailRefresh, nil, "combat disable cancels deferred refresh")
equal(next(mail.events.registered), nil, "disabled mail unregisters events")
DrainCombat()
equal(mail.frame:IsShown(), false, "disabled helper does not return after combat")
equal(TimerCount(), 0, "disable leaves no timer")
oldWrites = writes; SendMailFrame_SendMail(); Native("MAIL_SEND_SUCCESS")
equal(writes, oldWrites + 1, "retained disabled hooks preserve only native text reset")

SetCombat(true); baseline = constructed
Suite.db.mailHelper = true; mail:Apply()
equal(constructed, baseline, "first re-enable in combat defers construction")
equal(type(Suite.pending.mail), "function", "enable uses core combat queue")
DrainCombat()
equal(mail.frame:IsShown(), true, "open mailbox returns after combat")
mail:Schedule(); equal(TimerCount(), 1, "queued mailbox refresh created once")
Suite.db.mailHelper = false; mail:Apply(); Flush()
equal(TimerCount(), 0, "disable cancels queued next-frame work")
equal(mail.frame:IsShown(), false, "queued refresh cannot reopen disabled helper")
equal(sends, 8, "only explicit native send invocations send mail")

Suite.db.mailContacts = { secret = true }
equal(next(mail:Database()), nil, "restricted saved roster repaired without indexing")
Suite.db.mailContacts.entries.bad = { region = { secret = true }, name = "Bad", realm = "ForeverBeta" }
Suite.db.mailContacts.entries.secret = { secret = true }
equal(#mail:List(), 0, "malformed and restricted saved entries ignored")

-- The running-client screenshot exposed first-name-only schema-1 contacts.
Suite.db = Suite.InitializeDB(nil)
Suite.db.mailContacts = { schema = 1, entries = {
    ["110:drock-classicbetapve"] = { name = "Drock", realm = "ClassicBetaPvE", region = 110,
        guid = "Legacy-Drock", class = "WARRIOR", level = 15, faction = "Alliance" },
    ["110:drockhilda-classicbetapve"] = { name = "Drockhilda", realm = "ClassicBetaPvE", region = 110,
        guid = "Legacy-Hilda", class = "MAGE", level = 18 },
    ["110:unknown-other"] = { name = "Unknown", realm = "Other", region = 110, guid = "Legacy-Unknown" },
    ["110:hard-classicbetahardcore"] = { name = "Hard", realm = "ClassicBetaHardcore", region = 110 },
    ["110:role-classicbetarp"] = { name = "Role", realm = "ClassicBetaRP", region = 110 },
    secret = { secret = true },
    bad = { name = { secret = true }, realm = "ClassicBetaPvE", region = 110 },
}, removed = { ["110:removed-classicbetapve"] = true, ["1:foreign-classicbetapve"] = true,
    bad = { secret = true } } }
mail.query, mail.sort, mail.ascending = "", "name", true
local migrated = mail:Database()
equal(Suite.db.mailContacts.schema, 2, "legacy contacts migrate to full-name schema")
equal(#mail:List(), 5, "migration retains valid legacy contacts and ignores unreadable entries")
local legacy = Find("Drock")
equal(legacy.name, "Drock", "migration does not invent a surname")
equal(legacy.incomplete, true, "legacy first-name-only contact requests completion")
equal(legacy.address, nil, "legacy contact has no fabricated delivery address")
equal(legacy.ruleset, "PvE", "observed beta server label migrates to PvE")
equal(migrated[legacy.key].realm, nil, "new contact record omits realm")
equal(Find("Hard").ruleset, "Hardcore", "known legacy Hardcore label")
equal(Find("Role").ruleset, "RP", "known legacy RP label")
equal(Find("Unknown").ruleset, nil, "unrecognized server label stays unknown")
local retainedKey = legacy.key
equal(mail:Database(), migrated, "migration is stable across repeated database access")
Suite.db.inventory.characters = {
    ["Removed-alt"] = { name = "Removed", realm = "ClassicBetaPvE", region = 110 },
    ["Legacy-Hilda"] = { name = "Drockhilda", realm = "ClassicBetaPvE", region = 110 },
    ["New-alt"] = { name = "Newseed", realm = "ClassicBetaPvE", region = 110 },
}
mail:SeedRecordedCharacters()
equal(Find("Removed"), nil, "migrated removal survives old inventory seeding")
equal(Find("Newseed").incomplete, true, "first-name-only inventory is retained for explicit completion")
equal(Find("Drockhilda").level, 18, "inventory seeding preserves richer contact metadata")
Suite.db.mailHelper, Suite.db.mailRememberRecipient = true, true
mail:Apply()
equal(Find("Zoids").name, "Zoids Ward", "Camelot UnitName second return is the surname")
equal(Find("Zoids").ruleset, "PvE", "logged-in character records current PvE ruleset")
equal(mail.search.placeholder.text, "Search name or ruleset", "visible search no longer refers to realms")
equal(mail.sortButtons.ruleset.title, "Ruleset", "visible sort replaces Realm")
local sendsBefore = sends
mail:Choose(retainedKey)
equal(SendMailNameEditBox:GetText(), "Drock ", "legacy click begins native full-name input")
equal(SendMailNameEditBox.focused, true, "legacy input keeps recipient focus for native autocomplete")
equal(mail.notice.text, "Choose a full name, then save.", "legacy row explains completing its name")
local beforeCompletion = #mail:List()
SendMailNameEditBox:SetText("Drock Bracketfix"); mail:SaveRecipient()
equal(Find("Drock").key, retainedKey, "explicit completion retains the recorded GUID identity")
equal(#mail:List(), beforeCompletion, "explicit completion adds no duplicate")
equal(Find("Drock").address, "Drock Bracketfix", "completed contact uses full recipient without realm")
equal(Find("Drock").level, 15, "explicit completion preserves known level")
equal(Find("Drock").class, "WARRIOR", "explicit completion preserves class")
equal(Find("Drock").faction, "Alliance", "explicit completion preserves faction")
mail:Choose(retainedKey)
equal(SendMailNameEditBox:GetText(), "Drock Bracketfix", "completed contact fills exactly the screenshot name")
mail:SaveRecipient()
equal(#mail:List(), beforeCompletion, "saving a completed account contact deduplicates by identity")
mail.search:SetText("Bracketfix")
equal(#mail:List(), 1, "surname search finds completed contacts")
mail.search:SetText("ClassicBetaPvE")
equal(#mail:List(), 0, "old realm labels are absent from visible search data")
mail.search:SetText("")
player.guid, player.name, player.surname = "Legacy-Hilda", "Drockhilda", "Mirthbraid"
mail:RecordPlayer(); mail:Refresh()
equal(Find("Drockhilda").address, "Drockhilda Mirthbraid", "alt login completes its stored surname")
equal(Find("Drockhilda").current, true, "completed alt becomes current character")
player.surname = { secret = true }; mail:RecordPlayer()
equal(Find("Drockhilda").address, "Drockhilda Mirthbraid", "secret surname preserves prior readable full name")
player.name, player.surname = "Drockhilda Mirthbraid", nil; mail:RecordPlayer()
equal(Find("Drockhilda").address, "Drockhilda Mirthbraid", "already combined native name is not duplicated")
player.name, player.surname = "Drockhilda", "Mirthbraid"
player.realm = "ClassicBetaPvP"; mail:RecordPlayer()
equal(Find("Drockhilda").ruleset, "PvP", "PvP ruleset label is recorded")
mail:Choose(retainedKey)
local crossRulesetWrites = writes
mail:SaveRecipient()
equal(Find("Drock").ruleset, "PvE", "saving a selected contact preserves its own known ruleset")
equal(writes, crossRulesetWrites, "rulesets do not rewrite or block native recipient input")
player.hardcore = true; mail:RecordPlayer()
equal(Find("Drockhilda").ruleset, "Hardcore", "native Hardcore flag takes precedence over a server label")
player.hardcore = false
player.realm = "ClassicBetaRP"; mail:RecordPlayer()
equal(Find("Drockhilda").ruleset, "RP", "RP ruleset label is recorded")
player.realm = "ClassicBetaRPPvP"; mail:RecordPlayer()
equal(Find("Drockhilda").ruleset, "RP-PvP", "combined RP-PvP ruleset label is recorded")
player.realm = "UnreleasedVariant"; mail:RecordPlayer()
equal(Find("Drockhilda").ruleset, nil, "unknown new variant clears a stale ruleset without guessing PvE")
player.realm, player.hardcore = { secret = true }, { secret = true }; mail:RecordPlayer()
equal(Find("Drockhilda").ruleset, nil, "restricted ruleset inputs are not compared or serialized")
player.realm, player.hardcore = "ClassicBetaPvE", false
local nativeRules = C_GameRules; C_GameRules = nil; mail:RecordPlayer()
equal(Find("Drockhilda").ruleset, "PvE", "missing optional Hardcore API retains public server-label fallback")
C_GameRules = nativeRules
player.surname = "Brightbraid"; Fire("UNIT_NAME_UPDATE", "target"); Flush()
equal(Find("Drockhilda").address, "Drockhilda Mirthbraid", "other-unit name events do not change player identity")
Fire("UNIT_NAME_UPDATE", { secret = true }); Flush()
equal(Find("Drockhilda").address, "Drockhilda Mirthbraid", "restricted unit token is guarded before comparison")
Fire("UNIT_NAME_UPDATE", "player"); Flush()
equal(Find("Drockhilda").address, "Drockhilda Brightbraid", "late native player-name event refreshes surname")
player.hardcore = true; Fire("GAME_RULES_CHANGED"); Flush()
equal(Find("Drockhilda").ruleset, "Hardcore", "native game-rules change refreshes ruleset without polling")
player.hardcore = false; player.surname = "Mirthbraid"; mail:RecordPlayer()
mail:Choose(retainedKey)
SendMailFrame_SendMail(); Native("MAIL_SEND_SUCCESS")
equal(SendMailNameEditBox:GetText(), "Drock Bracketfix", "full-name memory survives native successful reset")
equal(sends, sendsBefore + 1, "migration, completion and selection perform no mail transaction")
mail:ConfirmRemove(retainedKey); mail:RemoveConfirmed()
Suite.db.inventory.characters["Legacy-Drock"] = { name = "Drock", realm = "ClassicBetaPvE", region = 110 }
mail:SeedRecordedCharacters()
equal(Find("Drock"), nil, "GUID tombstone blocks stale first-name inventory after completed contact removal")
player.guid, player.name, player.surname = "Legacy-Drock", "Drock", "Bracketfix"
mail:RecordPlayer()
equal(Find("Drock").current, true, "logging into a removed contact deliberately records it again")
local completedSave = Suite.Copy(Suite.db)
Suite.db = Suite.InitializeDB(completedSave); mail:Apply()
equal(Find("Drock").address, "Drock Bracketfix", "completed name persists through saved-data initialization")
equal(Suite.db.mailContacts.schema, 2, "schema-2 contacts do not migrate again on reload")
mail.search:SetText("")
local beforeTyped = #mail:List()
SendMailNameEditBox:SetText("Élodie Brisé"); mail:SaveRecipient()
equal(Find("Élodie").address, "Élodie Brisé", "non-ASCII character names remain valid")
SendMailNameEditBox:SetText(string.rep("A", 48) .. " " .. string.rep("B", 48)); mail:SaveRecipient()
equal(#mail:List(), beforeTyped + 1, "full recipient respects native 77-byte input bound")
Suite.db.mailHelper, Suite.db.mailRememberRecipient = false, false; mail:Apply(); Flush()

-- Repair old logged-in alts using the native account-character autocomplete cache.
Enum = Suite.Copy(old.Enum or {})
Enum.AutoCompleteEntryFlag = { AccountCharacter = 128, Bnet = 8 }
Enum.AutoCompletePriority = { AccountCharacter = 5, AccountCharacterSameRealm = 6 }
local queries, responses = {}, {}
local function Result(name, priority) return { name = name, priority = priority or 6, bnetID = 0 } end
C_AutoComplete = { GetAutoCompleteResults = function(first, limit, cursor, full, include, exclude)
    assert(not InCombatLockdown(), "account surname lookup does not run in combat")
    equal(include, 128, "surname lookup requests only native account characters")
    equal(exclude, 8, "surname lookup excludes Battle.net display names")
    equal(cursor, #first, "surname lookup uses the native prefix cursor position")
    equal(full, true, "surname lookup permits native full matches")
    equal(limit, 32, "surname lookup has a bounded native response")
    queries[#queries + 1] = first
    local result = responses[first]
    if result == "error" then error("cache unavailable") end
    return result or {}
end }
responses.Drock = { Result("Drock Bracketfix"), Result("Drockhilda Mirthbraid"), Result("Drockynne Quickgale") }
responses.Drockhilda = { Result("Drockhilda Mirthbraid") }
Suite.db = Suite.InitializeDB(nil)
Suite.db.mailContacts = { schema = 1, removed = {}, entries = {
    ["110:drock-classicbetapve"] = { name = "Drock", realm = "ClassicBetaPvE", region = 110,
        guid = "Old-Drock", level = 15, class = "WARRIOR", faction = "Alliance" },
    ["110:drockhilda-classicbetapve"] = { name = "Drockhilda", realm = "ClassicBetaPvE", region = 110,
        guid = "Old-Hilda", level = 18, class = "PRIEST", faction = "Alliance" },
    ["110:drockshot-classicbetapve"] = { name = "Drockshot", realm = "ClassicBetaPvE", region = 110,
        guid = "Current-Shot", level = 8, class = "HUNTER" },
} }
player.guid, player.name, player.surname, player.class, player.level = "Current-Shot", "Drockshot", "Swiftmane", "HUNTER", 8
player.realm = "ClassicBetaPvE"
SendMailNameEditBox:SetText("Untouched Letter"); SendMailSubjectEditBox:SetText("Keep subject")
local repairWrites, repairSends = writes, sends
Suite.db.mailHelper = true; mail:Apply()
equal(#queries, 2, "opening mail queries each incomplete same-ruleset alt once")
equal(Find("Drock").name, "Drock Bracketfix", "old logged-in Drock gains native cached surname automatically")
equal(Find("Drockhilda").name, "Drockhilda Mirthbraid", "old logged-in Drockhilda gains native cached surname automatically")
equal(Find("Drock").level, 15, "automatic backfill retains level")
equal(Find("Drockhilda").class, "PRIEST", "automatic backfill retains class")
equal(Find("Drock").key, "110:guid:Old-Drock", "automatic backfill retains recorded GUID identity")
equal(#mail:List(), 2, "screenshot roster displays only the two alts")
equal(#mail:List(true), 3, "active character remains stored for use on another toon")
equal(mail.rows[3]:IsShown(), false, "active toon consumes no displayed contact row")
equal(mail.count.text, "2 contacts  ·  1 / 1", "active toon is excluded from displayed count and paging")
mail.search:SetText("Swiftmane")
equal(#mail:List(), 0, "surname search cannot reveal active toon")
equal(mail.empty:IsShown(), true, "active-only search gives no matching recipients")
mail.search:SetText("")
mail:ResolveRecordedNames(); mail:BeginVisit()
equal(#queries, 2, "completed names and repeated mailbox reflow do not repeat lookups")
equal(writes, repairWrites, "automatic completion does not alter native To input")
equal(SendMailSubjectEditBox:GetText(), "Keep subject", "automatic completion preserves subject")
equal(sends, repairSends, "automatic completion never sends mail")
player.guid, player.name, player.surname, player.class, player.level = "Old-Drock", "Drock", "Bracketfix", "WARRIOR", 15
mail:RecordPlayer(); mail:Refresh()
equal(mail:List()[1].name, "Drockhilda Mirthbraid", "switching characters hides the newly active toon")
equal(mail:List()[2].name, "Drockshot Swiftmane", "previously active toon appears with its full name on an alt")
local beforeOwnSave = #mail:List()
mail:Store("Drock Bracketfix", "PvE", 110)
equal(#mail:List(), beforeOwnSave, "saving active toon does not make it visible")
Suite.db.mailContacts.entries["110:name:?:drock bracketfix"] = { name = "Drock Bracketfix", region = 110 }
equal(#mail:List(), beforeOwnSave, "manual active-name alias with unknown ruleset also stays hidden")
Suite.db.mailContacts.entries["110:name:?:drock bracketfix"] = nil

local function Incomplete(first, guid, ruleset)
    return mail:Store(first, ruleset or "PvE", 110, guid or ("Old-" .. first), nil, nil, nil, true)
end
local function CheckUnresolved(first, response, reason)
    Incomplete(first)
    responses[first] = response
    mail:ResolveRecordedNames()
    equal(Find(first).incomplete, true, reason)
end
CheckUnresolved("Ambiguous", { Result("Ambiguous One"), Result("Ambiguous Two") }, "different surnames for one first name are not guessed")
CheckUnresolved("Prefix", { Result("Prefixother Person") }, "native prefix matches must match the complete first name")
CheckUnresolved("Friend", { Result("Friend Person", 4) }, "friend priority cannot supply an account surname")
CheckUnresolved("Crossrule", { Result("Crossrule Person", 5) }, "other-server account priority cannot identify a same-ruleset record")
CheckUnresolved("Broken", "error", "unavailable native cache errors leave surname unresolved")
CheckUnresolved("Hidden", { secret = true }, "restricted result table is not indexed")
CheckUnresolved("Hiddenrow", { { secret = true } }, "restricted autocomplete row is not indexed")
CheckUnresolved("Hiddenname", { { name = { secret = true }, priority = 6, bnetID = 0 } }, "secret autocomplete name is not parsed")
CheckUnresolved("Hiddenrank", { { name = "Hiddenrank Person", priority = { secret = true }, bnetID = 0 } }, "secret priority is not compared")
CheckUnresolved("Hiddenbnet", { { name = "Hiddenbnet Person", priority = 6, bnetID = { secret = true } } }, "secret Battle.net ID is not compared")
CheckUnresolved("Bnet", { { name = "Bnet Person", priority = 6, bnetID = 10 } }, "Battle.net identity cannot complete a character")
CheckUnresolved("Hole", { [2] = Result("Hole Person") }, "sparse native response cannot establish uniqueness")
local restrictedIndex = {}; restrictedIndex[{ secret = true }] = Result("Index Person")
CheckUnresolved("Index", restrictedIndex, "secret native result index is guarded")
local capped = {}; for index = 1, 32 do capped[index] = Result("Capped Person") end
CheckUnresolved("Capped", capped, "possibly truncated response cannot establish uniqueness")
CheckUnresolved("Realmname", { Result("Realmname Person-OtherServer") }, "realm-qualified result is not treated as a surname")
mail:Store("Owned Person", "PvE", 110, "Already-Complete")
CheckUnresolved("Owned", { Result("Owned Person") }, "cached full name already owned by another GUID is not rebound")
Incomplete("Twice", "Old-Twice-One"); Incomplete("Twice", "Old-Twice-Two")
responses.Twice = { Result("Twice Person") }
local beforeDuplicates = #queries; mail:ResolveRecordedNames()
equal(#queries, beforeDuplicates, "duplicate incomplete recorded identities do not query an ambiguous first name")
local beforeOtherRuleset = #queries
Incomplete("Pvponly", nil, "PvP"); responses.Pvponly = { Result("Pvponly Person") }; mail:ResolveRecordedNames()
equal(#queries, beforeOtherRuleset, "current account cache does not assign another ruleset's surname")
equal(Find("Pvponly").incomplete, true, "other-ruleset incomplete contact remains available for explicit completion")
Incomplete("Unknownrule"); Suite.db.mailContacts.entries["110:guid:Old-Unknownrule"].ruleset = nil
responses.Unknownrule = { Result("Unknownrule Person") }; mail:ResolveRecordedNames()
equal(Find("Unknownrule").incomplete, true, "unknown ruleset cannot be inferred from a same-server name")
CheckUnresolved("Late", {}, "empty cache leaves old name intact until another native refresh")
responses.Late = { Result("Late Person") }
local beforeRetry = #queries; mail:ResolveRecordedNames()
equal(#queries, beforeRetry, "an unresolved contact is attempted only once per mailbox refresh generation")
Fire("MAIL_SHOW"); Flush()
equal(Find("Late").address, "Late Person", "native mailbox show retries newly available account data")
local beforeTombstone = #mail:List()
mail:ConfirmRemove(Find("Drockhilda").key); mail:RemoveConfirmed()
Suite.db.inventory.characters["Old-Hilda"] = { name = "Drockhilda", realm = "ClassicBetaPvE", region = 110 }
mail:SeedRecordedCharacters(); mail:ResolveRecordedNames()
equal(#mail:List(), beforeTombstone - 1, "autocomplete cannot resurrect a removed alt through stale inventory")
equal(Find("Drockhilda"), nil, "removed autocomplete candidate stays absent")
local beforeGuards = #queries
Incomplete("Combatcache"); responses.Combatcache = { Result("Combatcache Person") }
SetCombat(true); mail:ResolveRecordedNames()
equal(#queries, beforeGuards, "combat prevents account surname lookup")
SetCombat(false)
Suite.db.mailHelper = false; Suite.db.mailRememberRecipient = true; mail:ResolveRecordedNames()
equal(#queries, beforeGuards, "memory-only preference does not populate contacts")
Suite.db.mailHelper = true
local cacheAPI = C_AutoComplete; C_AutoComplete = nil; mail:ResolveRecordedNames()
equal(#queries, beforeGuards, "missing account-cache API leaves recorded identities intact")
C_AutoComplete = cacheAPI
local flags = Enum.AutoCompleteEntryFlag; Enum.AutoCompleteEntryFlag = { secret = true }; mail:ResolveRecordedNames()
equal(#queries, beforeGuards, "restricted enum table is guarded before field access")
Enum.AutoCompleteEntryFlag = flags
flags.AccountCharacter = { secret = true }; mail:ResolveRecordedNames()
equal(#queries, beforeGuards, "secret account flag cannot be passed to native API")
flags.AccountCharacter = 128
mail:ResolveRecordedNames()
equal(Find("Combatcache").address, "Combatcache Person", "eligible pending surname resolves after combat and capabilities restore")
local autoSaved = Suite.Copy(Suite.db)
Suite.db = Suite.InitializeDB(autoSaved); mail:Apply()
equal(Find("Drockshot").address, "Drockshot Swiftmane", "previously active full name survives saved-data initialization")
equal(Find("Drock").current, true, "stored active identity survives saved-data initialization")
mail.search:SetText("Bracketfix")
equal(#mail:List(), 0, "active identity remains hidden after saved-data initialization")
mail.search:SetText("")
Suite.db.mailHelper, Suite.db.mailRememberRecipient = false, false; mail:Apply(); Flush()

SetCombat(false)
for _, name in ipairs(names) do _G[name] = old[name] end
Suite.db, Suite.pending = oldDB, oldPending
