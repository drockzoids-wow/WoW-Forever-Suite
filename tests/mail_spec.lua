local Suite, equal, Frame, SetCombat = ...
local mail = Suite.Mail
local names = { "CreateFrame", "C_Timer", "MenuUtil", "UnitGUID", "UnitName", "UnitClass", "UnitLevel", "UnitFactionGroup",
    "GetCurrentRegion", "GetNormalizedRealmName", "GetRealmName", "C_GameRules", "C_AutoComplete", "C_CreatureInfo", "Enum", "RAID_CLASS_COLORS", "MailFrame", "SendMailFrame",
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
local function Stored(name)
    for key, entry in pairs(mail:Database()) do
        if type(entry.name) == "string" and (entry.name == name or entry.name:match("^(%S+)") == name) then
            return entry, key
        end
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
equal(mail.frame:GetParent(), UIParent, "unified window remains independent of native mailbox hierarchy")
equal(#mail:List(), 1, "only same-ruleset alts appear while current character is hidden")
equal(Find("Foreign"), nil, "other-region records stay outside mail list")
equal(mail.frame, mail.book.frame, "mailbox opens the same Contacts shell")
equal(mail.rows[1].name.textColor[2], 0.8, "class color in recorded contact row")
equal(mail.search.fontFlags, "", "edit-box font supplies required flags")
equal(mail.search.maxLetters, 240, "search includes bounded contact notes")
equal(mail.book.use:GetParent(), mail.book.content, "recipient action is explicit in the shared details pane")
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
mail:EditContact(arc); mail.book.remove.OnClick()
MailFrameTab_OnClick(nil, 1)
equal(mail.frame:IsShown(), false, "switching to Inbox immediately hides contacts")
equal(mail.book.confirm, nil, "tab hide cancels contact confirmation")
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
equal(#mail:List(), 0, "search cannot reveal other-ruleset contacts")
mail.search:SetText("[")
equal(#mail:List(), 0, "search punctuation is not a Lua pattern")
equal(mail.empty:IsShown(), true, "empty search explains no matches")
mail.search:SetText("")
SendMailNameEditBox:SetText("  Courier   Post  ")
mail:SaveRecipient()
equal(Find("Courier").address, "Courier Post", "manual recipient keeps both names and normalizes spaces")
mail:SaveRecipient()
equal(#mail:List(), 2, "repeated recipient saves deduplicate")
SendMailNameEditBox:SetText("Localalt Post"); mail:SaveRecipient()
equal(Find("Localalt").ruleset, "PvE", "typed recipient is recorded under the current ruleset")
for _, bad in ipairs({ "", "A1", "Bad|cff00ff00", "Name-", "Name-/realm", "Name\nRealm", "Drock",
    "Drock Bracketfix-ClassicBetaPvE", "Drock Extra Bracketfix", "Drock Bracket1", "Drock\tBracketfix" }) do
    local before = #mail:List()
    SendMailNameEditBox:SetText(bad); mail:SaveRecipient()
    equal(#mail:List(), before, "invalid recipient not saved: " .. bad)
end
SendMailNameEditBox.text = { secret = true }; mail:SaveRecipient()
equal(#mail:List(), 3, "secret recipient never saved or parsed")
SendMailNameEditBox.text = ""

for index = 1, 9 do mail:Store("Alt" .. string.char(64 + index) .. " Letter", "PvE", 110, nil, "MAGE", index) end
mail:Refresh()
equal(#mail.rows, 8, "unified list reuses eight rows for long rosters")
equal(mail.next.enabled, true, "long list has accessible next page")
mail.next.OnClick()
equal(mail.page, 2, "next-page contact navigation")
mail.book.wheelArea.OnMouseWheel(mail.book.wheelArea, -1)
equal(mail.page, 2, "wheel clamps to filtered final page")
mail.next.OnClick()
equal(mail.page, 2, "last page is clamped")
mail.sortButtons.level.OnClick()
equal(mail:List()[1].name, "AltI Letter", "first level sort is descending among alts")
mail.sortButtons.level.OnClick()
equal(mail.ascending, true, "sort direction toggles")
mail.sortButtons.name.OnClick()
equal(mail.sort, "name", "name sorting remains available")

mail:SelectContactTab("alts")
mail:EditContact(arc); mail.book.remove.OnClick()
equal(mail.book.confirm, arc.key, "contact removal records confirmation before deletion")
mail:EditContact(arc)
equal(#mail:List(), 12, "cancel preserves contact")
mail:EditContact(arc); mail.book.remove.OnClick(); mail.book.remove.OnClick()
equal(#mail:List(), 11, "confirmed removal affects only chosen contact")
mail:SeedRecordedCharacters()
equal(#mail:List(), 11, "inventory seeding does not resurrect removed contact")
local saved = Suite.Copy(Suite.db)
Suite.db = Suite.InitializeDB(saved); mail.removed = nil; mail:Apply(); mail:SeedRecordedCharacters()
equal(#mail:List(), 11, "contact removal survives database reload")
local zoids = Find("Zoids")
mail:EditContact(zoids)
equal(mail.book.remove.enabled, false, "current character removal is disabled")
equal(mail:DeleteContact(zoids.key), false, "current character cannot be removed through the shared deletion path")
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
equal(mail.frame, mail.book.frame, "native reflow retains shared shell")
MailFrame.rect = { { secret = true }, 100, 338, 424 }; mail:Place()
equal(mail.frame.point[1], "CENTER", "unreadable geometry falls back to centered placement")
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
equal(#mail:List(), 2, "migration displays only same-ruleset legacy contacts")
local legacy = Find("Drock")
equal(legacy.name, "Drock", "migration does not invent a surname")
equal(legacy.incomplete, true, "legacy first-name-only contact requests completion")
equal(legacy.address, nil, "legacy contact has no fabricated delivery address")
equal(legacy.ruleset, "PvE", "observed beta server label migrates to PvE")
equal(migrated[legacy.key].realm, nil, "new contact record omits realm")
equal(Stored("Hard").ruleset, "Hardcore", "known legacy Hardcore label")
equal(Stored("Role").ruleset, "RP", "known legacy RP label")
equal(Stored("Unknown").ruleset, nil, "unrecognized server label stays unknown")
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
equal(mail.search.placeholder.text, "Search contacts", "mail search uses unified contact wording")
equal(mail.sortButtons.ruleset, nil, "redundant ruleset sort is removed")
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
local crossRulesetWrites = writes
mail:Choose(retainedKey)
equal(Find("Drock"), nil, "PvE contact is hidden on PvP")
equal(Stored("Drock").ruleset, "PvE", "hidden contact retains its original ruleset")
equal(writes, crossRulesetWrites, "stale cross-ruleset selection cannot fill recipient")
player.hardcore = true; mail:RecordPlayer()
equal(Find("Drockhilda").ruleset, "Hardcore", "native Hardcore flag takes precedence over a server label")
player.hardcore = false
player.realm = "ClassicBetaRP"; mail:RecordPlayer()
equal(Find("Drockhilda").ruleset, "RP", "RP ruleset label is recorded")
player.realm = "ClassicBetaRPPvP"; mail:RecordPlayer()
equal(Find("Drockhilda").ruleset, "RP-PvP", "combined RP-PvP ruleset label is recorded")
player.realm = "UnreleasedVariant"; mail:RecordPlayer()
equal(Stored("Drockhilda").ruleset, nil, "unknown new variant clears a stale ruleset without guessing PvE")
equal(#mail:List(true), 0, "unknown current ruleset hides all contacts")
player.realm, player.hardcore = { secret = true }, { secret = true }; mail:RecordPlayer()
equal(Stored("Drockhilda").ruleset, nil, "restricted ruleset inputs are not compared or serialized")
equal(#mail:List(true), 0, "restricted current ruleset hides all contacts")
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
equal(mail:DeleteContact(retainedKey), true, "shared deletion removes the retained contact")
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
mail:SelectContactTab("all")
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
equal(Stored("Pvponly").name, "Pvponly", "other-ruleset incomplete contact remains saved")
equal(Find("Pvponly"), nil, "other-ruleset incomplete contact is hidden")
Incomplete("Unknownrule"); Suite.db.mailContacts.entries["110:guid:Old-Unknownrule"].ruleset = nil
responses.Unknownrule = { Result("Unknownrule Person") }; mail:ResolveRecordedNames()
equal(Stored("Unknownrule").name, "Unknownrule", "unknown ruleset cannot be inferred from a same-server name")
equal(Find("Unknownrule"), nil, "unknown contact ruleset stays hidden")
CheckUnresolved("Late", {}, "empty cache leaves old name intact until another native refresh")
responses.Late = { Result("Late Person") }
local beforeRetry = #queries; mail:ResolveRecordedNames()
equal(#queries, beforeRetry, "an unresolved contact is attempted only once per mailbox refresh generation")
Fire("MAIL_SHOW"); Flush()
equal(Find("Late").address, "Late Person", "native mailbox show retries newly available account data")
local beforeTombstone = #mail:List()
equal(mail:DeleteContact(Find("Drockhilda").key), true, "shared deletion removes the resolved alt")
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

-- Standalone contact management with both mailbox preferences off and no native mailbox.
do
    local savedDB, savedRealm = Suite.db, player.realm
    Suite.db = Suite.InitializeDB(nil)
    player.realm = "CAMWOWUS2Realm1PvE"
    equal(mail:CurrentRuleset(), "PvE", "observed normalized CAMWOW realm identifies PvE")
    player.realm = "CAMWOW US2 Realm 1 PvP"
    equal(mail:CurrentRuleset(), "PvP", "CAMWOW PvP remains separate")
    player.realm = "CAMWOW US2 Realm 1 Unreleased"
    equal(mail:CurrentRuleset(), nil, "unknown CAMWOW suffix is not guessed")
    GetRealmName = function() return "CAMWOW US2 Realm 1 PvE" end
    equal(mail:CurrentRuleset(), "PvE", "recognized display realm can resolve unknown normalized label")
    GetRealmName = function() return "Fallback Realm" end
    player.realm = "CAMWOWUS2Realm1PvE"
    Suite.db.inventory.characters = {
        ["Repair-PvE"] = { name = "Recovered", fullName = "Recovered Friend", realm = player.realm, region = 110 },
        ["Seed-PvE"] = { name = "Seeded", fullName = "Seeded Friend", realm = "CAMWOW US2 Realm 1 PvE", region = 110 },
        ["Seed-PvP"] = { name = "Opponent", realm = "CAMWOW US2 Realm 1 PvP", region = 110 },
        ["Removed-PvE"] = { name = "Removed", realm = player.realm, region = 110 },
    }
    local repair = mail:Store("Recovered", nil, 110, "Repair-PvE", "MAGE", 25, nil, true)
    mail:Database()[repair].category, mail:Database()[repair].notes = "Friends", "Keep this note"
    mail.removed["110:guid:Removed-PvE"] = true
    mail:SeedRecordedCharacters()
    equal(#mail:List(true, ""), 2, "CAMWOW repair and seeding restore PvE roster only")
    equal(mail:Database()[repair].ruleset, "PvE", "unknown existing contact ruleset is repaired by recorded GUID realm")
    equal(mail:Database()[repair].notes, "Keep this note", "repair preserves contact notes")
    equal(mail:Database()[repair].category, "Friends", "repair preserves categories")
    equal(mail:Database()[repair].level, 25, "repair preserves richer level metadata")
    equal(Find("Recovered").address, "Recovered Friend", "repair restores a recorded surname for the same GUID and first name")
    equal(Find("Seeded").address, "Seeded Friend", "new inventory seed uses recorded full name")
    equal(Find("Opponent"), nil, "CAMWOW PvP inventory is hidden on PvE")
    equal(Find("Removed"), nil, "ruleset repair cannot resurrect removed contact")
    Suite.db, player.realm = savedDB, savedRealm
    mail:Database()
end
MailFrame = nil; SendMailFrame:Hide()
mail.query = "unrelated mailbox search"
local bookWrites, bookSends, bookTabs = writes, sends, tabs
mail:OpenBook()
equal(mail.book.frame:IsShown(), true, "contact book opens without mailbox or enabled mail helper")
equal(mail.book.frame:GetParent(), UIParent, "contact book is independent of mailbox hierarchy")
equal(mail.book.frame.OnUpdate, nil, "contact book has no idle updater")
local book = mail.book
equal(book.frame.point[1], "CENTER", "standalone contact book opens centrally")
local previousPoint = book.frame.point
mail:OpenBook(book.frame)
equal(book.frame.point, previousPoint, "reopening visible unified window does not move it")
mail:PlaceBook(book.frame)
equal(book.frame.point, previousPoint, "self anchor is rejected to avoid a frame cycle")
SetCombat(true); mail:PlaceBook(); SetCombat(false)
equal(book.frame.point, previousPoint, "combat preserves directory placement")
mail:EditContact()
book.name:SetText("Parcel Friend")
equal(book.ruleset, nil, "contact editor has no manual ruleset choice")
local craftersGroup = mail:SaveGroup(nil, "Crafters")
book.groupChanges[craftersGroup] = true; book.notes:SetText("Send spare ore")
book.save.OnClick()
local friendKey = book.key
equal(type(friendKey), "string", "standalone editor saves a full-name contact")
equal(mail:Database()[friendKey].notes, "Send spare ore", "editor stores notes")
equal(#mail:ContactList(craftersGroup, "", nil, true), 1, "editor stores named membership")
equal(#mail:ContactList(craftersGroup, "spare ore", nil, true), 1, "notes search combines with group filter")
equal(#mail:List(true, "Parcel", "Friends"), 0, "category filter excludes other categories")
book.search:SetText("spare ore")
equal(book.rows[1].entry.key, friendKey, "book search is independent of mailbox search")
book.rows[1].OnClick()
book.name:SetText("Parcel Courier")
local friendsGroup = mail:SaveGroup(nil, "Friends")
book.groupChanges[craftersGroup], book.groupChanges[friendsGroup] = false, true
book.save.OnClick()
local renamedKey = book.key
equal(mail:Database()[friendKey], nil, "renaming manual contact removes old address key")
equal(mail:Database()[renamedKey].name, "Parcel Courier", "editor rename updates address")
equal(mail.removed[friendKey], true, "rename suppresses stale old address")
local duplicate, duplicateMessage = mail:SaveContact(nil, "Parcel Courier", "Other", "")
equal(duplicate, nil, "duplicate name and ruleset rejected")
equal(type(duplicateMessage), "string", "duplicate provides useful feedback")
equal(#mail:ContactList(friendsGroup, "", nil, true), 1, "duplicate cannot overwrite membership")
equal(mail:SaveContact(nil, "Incomplete", "", ""), nil, "standalone contact requires surname")
equal(mail:SaveContact(nil, "Hidden Person", { secret = true }, ""), nil, "restricted category rejected")
equal(mail:SaveContact(nil, "Hidden Person", "Friends", "|Hbad"), nil, "markup in notes rejected")
equal(mail:SaveContact(nil, "Hidden Person", "Friends", string.rep("x", 241)), nil, "oversized notes rejected")
equal(mail:SaveContact("missing", "Missing Person", "", ""), nil, "stale editor cannot recreate deleted record")
local guided = mail:Store("Guided Person", "PvE", 110, "Book-Guid", "MAGE", 20, "Alliance")
equal(mail:SaveContact(guided, "Guided Person", "Alts", "Bank alt"), guided, "recorded contact retains GUID key")
mail:Store("Guided Person", "PvE", 110, "Book-Guid", "MAGE", 21, "Alliance")
equal(mail:Database()[guided].category, "Alts", "automatic identity refresh preserves category")
equal(mail:Database()[guided].notes, "Bank alt", "automatic identity refresh preserves notes")
equal(mail:Database()[guided].level, 21, "automatic identity refresh still updates level")
local bookSaved = Suite.Copy(Suite.db)
Suite.db = Suite.InitializeDB(bookSaved)
equal(mail:Database()[guided].notes, "Bank alt", "book metadata survives saved-data initialization")
book.search:SetText("")
local previousFilterMenu = MenuUtil; MenuUtil = nil
book.filterButton.OnClick()
equal(mail:GroupDefinitions()[book.groupFilter].name, "Alts", "fallback starts with first named group")
equal(book.rows[1].entry.key, guided, "category picker filters shared contact list")
book.filterButton.OnClick()
equal(mail:GroupDefinitions()[book.groupFilter].name, "Crafters", "fallback includes empty named groups")
book.filterButton.OnClick()
equal(mail:GroupDefinitions()[book.groupFilter].name, "Friends", "fallback reaches next named group")
book.filterButton.OnClick()
equal(book.groupFilter, nil, "fallback returns to all contacts")
MenuUtil = previousFilterMenu
equal(book.category, nil, "contact editor has no separate category field")
equal(book.categoryChoose, nil, "contact editor has only the unified groups chooser")
equal(mail:DeleteContact("110:guid:Old-Drock"), false, "standalone removal protects active character")
equal(mail:SaveContact({ secret = true }, "Hidden Person", "", ""), nil, "restricted contact key rejected")
player.realm = "ClassicBetaPvP"
local separate = mail:SaveContact(nil, "Parcel Courier", "", "")
equal(type(separate), "string", "same name on different ruleset remains distinct")
equal(mail:Database()[separate].notes, nil, "empty optional metadata is omitted")
equal(mail:Database()[separate].ruleset, "PvP", "new contacts automatically use current ruleset")
equal(#mail:List(true, "Parcel"), 1, "PvP shows only its own matching contact")
equal(mail:SaveContact(guided, "Guided Person", "", ""), nil, "stale PvE editor cannot change contact on PvP")
player.realm = "ClassicBetaPvE"
equal(#mail:List(true, "Parcel"), 1, "returning to PvE restores its contact only")
equal(mail:GroupDefinitions()[friendsGroup].contacts["110:name:pve:parcel courier"], true, "switching rulesets preserves other contact memberships")
player.realm = "UnknownVariant"
equal(mail:SaveContact(nil, "Unknown Person", "", ""), nil, "unknown ruleset blocks new contact")
player.realm = "ClassicBetaPvE"
equal(mail:SaveContact(guided, "Guided Person", "", ""), guided, "metadata can be cleared")
equal(mail:Database()[guided].category, nil, "cleared category is removed")
equal(mail:Database()[guided].notes, nil, "cleared notes are removed")
for _, suffix in ipairs({ "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine" }) do
    mail:SaveContact(nil, "Paging " .. suffix, "Paging", "")
end
book.filter = "Paging"; mail:RefreshBook()
equal(book.rows[8]:IsShown(), true, "book fills its eight-row first page")
book.next.OnClick()
equal(book.page, 2, "book can reach contacts after first eight")
equal(book.rows[1]:IsShown(), true, "last page includes remaining contact")
equal(book.rows[2]:IsShown(), false, "last page hides unused rows")
book.previous:Show(); book.next:Show() -- Substitute frames do not inherit native default visibility.
book.rows[1]:OnMouseWheel(1)
equal(book.page, 1, "wheel over contact row returns to previous page")
book.wheelArea:OnMouseWheel(-1)
equal(book.page, 2, "wheel over contact list background advances page")
book.next:OnMouseWheel(-1)
equal(book.page, 2, "wheel at last contact page remains clamped")
SetCombat(true); book.rows[1]:OnMouseWheel(1); SetCombat(false)
equal(book.page, 2, "combat wheel input does not queue contact page changes")
book.previous:OnMouseWheel(1)
equal(book.page, 1, "wheel over contact footer changes page")
book.previous:OnMouseWheel(1)
equal(book.page, 1, "wheel at first contact page remains clamped")
for _, delta in ipairs({ 0, 0/0, math.huge, "1", { secret = true } }) do
    book.rows[1]:OnMouseWheel(delta)
    equal(book.page, 1, "invalid contact wheel input is ignored")
end
book.search:SetText("no such person")
equal(book.page, 1, "search resets pagination")
equal(book.empty:IsShown(), true, "empty search explains no results")
book.filter = nil; book.search:SetText("")
SetCombat(true)
equal(mail:SaveContact(renamedKey, "Combat Rename", "", ""), nil, "combat blocks contact mutation")
equal(mail:DeleteContact(renamedKey), false, "combat blocks contact removal")
SetCombat(false)
book.remove.OnClick()
equal(mail:Database()[renamedKey] ~= nil, true, "first remove click only asks for confirmation")
book.remove.OnClick()
equal(mail:Database()[renamedKey], nil, "second remove click deletes selected contact")
equal(mail.removed[renamedKey], true, "standalone removal retains tombstone")
equal(writes, bookWrites, "contact book never writes native recipient")
equal(sends, bookSends, "contact book never sends mail")
equal(tabs, bookTabs, "contact book never switches native mail tabs")
book.frame:Hide()

-- Automatic mailbox buckets use live guild membership without persisting the roster.
local oldClub, oldGuild = C_Club, C_GuildInfo
C_CreatureInfo = { GetClassInfo = function(id)
    equal(id, 8, "guild class lookup uses readable native class ID")
    return { classFile = "MAGE" }
end }
RAID_CLASS_COLORS = { MAGE = { r = 0.2, g = 0.6, b = 0.9 } }
Suite.db = Suite.InitializeDB(nil); Suite.db.mailHelper = true
player.name, player.surname, player.guid, player.realm = "Zoids", "Ward", "Player-110-1", "ClassicBetaPvE"
mail:RecordPlayer()
local altKey = mail:Store("Account Alt", "PvE", 110, "Account-GUID")
local friendKey = mail:Store("Friendly Person", "PvE", 110)
mail:Store("Guild Friend", "PvE", 110)
local roster = {
    { name = "Zoids Ward", guid = player.guid, isSelf = true },
    { name = "Account Alt", guid = "Account-GUID", isSelf = false },
    { name = "Guild Friend", guid = "Guild-GUID", isSelf = false, level = 40, classID = 8 },
    { name = "Offline Member", guid = "Offline-GUID", isSelf = false, level = 20, classID = 8 },
    { name = { secret = true }, guid = "Secret-GUID", isSelf = false },
    { secret = true },
}
local rosterReads, requests = 0, 0
C_Club = {
    GetGuildClubId = function() return 7 end,
    GetClubMembers = function() rosterReads = rosterReads + 1; return { 1, 2, 3, 4, 5, 6 } end,
    GetMemberInfo = function(_, id) return roster[id] end,
}
C_GuildInfo = { GuildRoster = function() requests = requests + 1 end }
mail:EndVisit(); MailFrame = NewMailFrame(); mail:Apply(); MailFrame:Show(); MailFrameTab_OnClick(nil, 2); Flush()
equal(mail.frame:GetWidth(), 740, "shared Contacts window uses a narrower three-column layout")
equal(requests, 1, "one roster refresh requested per mailbox visit")
mail:SelectContactTab("alts")
equal(#mail:ContactList(), 1, "alts contains account character without active player")
equal(mail:ContactList()[1].key, altKey, "account identity takes priority over guild membership")
mail:SelectContactTab("guild")
equal(#mail:ContactList(), 2, "guild includes offline members and deduplicates saved members")
equal(mail.rows[1].name.textColor[1], 0.2, "saved guild recipient uses observed class color in mailbox")
equal(mail.rows[2].name.textColor[3], 0.9, "unsaved guild member uses native class color in mailbox")
equal(Stored("Guild Friend").class, "MAGE", "existing saved guild contact learns observed class")
equal(mail.rows[1].remove, nil, "directory rows have no destructive roster action")
equal(#mail:List(), 3, "live guild roster never seeds saved contacts")
mail:EditContact()
local guildClickSends = sends
mail.rows[2].OnClick()
equal(SendMailNameEditBox:GetText(), "Offline Member", "clicking unsaved guild row fills native To")
equal(sends, guildClickSends, "guild-row click keeps sending manual")
local guildRows = mail:ContactList()
mail:Choose(guildRows[1].key)
equal(SendMailNameEditBox:GetText(), "Guild Friend", "guild selection fills native full recipient")
mail:Choose(guildRows[2].key)
equal(SendMailNameEditBox:GetText(), "Offline Member", "unsaved offline guild member can receive mail")
mail.search:SetText("offline")
equal(#mail:ContactList(), 1, "guild search filters roster")
local beforeReads = rosterReads
mail:Refresh(); mail:Refresh()
equal(rosterReads, beforeReads, "rendering never polls guild roster")
mail.search:SetText("")
mail.page, mail.book.confirm = 4, altKey
mail:SelectContactTab("other")
equal(mail.page, 1, "switching buckets resets pagination")
equal(mail.book.confirm, nil, "switching buckets clears pending removal")
equal(#mail:ContactList(), 1, "other excludes alts and guild members")
equal(mail:ContactList()[1].key, friendKey, "manual non-guild recipient appears in other")
SendMailNameEditBox:SetText("New Contact"); mail:SaveRecipient()
equal(mail.contactTab, "other", "saving a new recipient selects Other")
equal(#mail:ContactList(), 2, "new recipient automatically belongs in Other")
mail:SelectContactTab("guild")
SetCombat(true); mail:SelectContactTab("other")
equal(mail.contactTab, "guild", "combat prevents tab changes")
local combatReads = rosterReads
Fire("CLUB_MEMBERS_UPDATED", 7); Flush()
equal(rosterReads, combatReads, "combat defers guild queries")
roster[3], roster[4] = nil, nil
DrainCombat()
equal(#mail:ContactList(), 0, "guild member removal refreshes after combat")
mail:SelectContactTab("other")
equal(#mail:ContactList(), 3, "saved former guild member moves to Other")
C_Club.GetGuildClubId = function() return nil end
Fire("PLAYER_GUILD_UPDATE", "player"); Flush()
mail:SelectContactTab("guild")
equal(#mail:ContactList(), 0, "leaving guild clears guild members")
C_Club.GetGuildClubId = function() return 7 end
C_Club.GetClubMembers = function() return { secret = true } end
mail:ReadGuild()
equal(next(mail.guildEntries), nil, "restricted guild member list remains empty")
C_Club.GetClubMembers = function() error("not initialized") end
mail:ReadGuild()
equal(next(mail.guildEntries), nil, "uninitialized clubs fail quietly")
C_Club.GetGuildClubId = function() return { secret = true } end
mail:ReadGuild()
equal(next(mail.guildEntries), nil, "secret guild identity is never queried")
Suite.db.mailHelper = false; mail:Apply()
equal(next(mail.events.registered), nil, "disabled helper unregisters guild events")
equal(mail.guildEntries, nil, "disabled helper discards transient roster")

-- The same groups work in the standalone book with mailbox options disabled.
roster[3] = { name = "Guild Friend", guid = "Guild-GUID", isSelf = false, level = 40, classID = 8 }
roster[4] = { name = "Offline Member", guid = "Offline-GUID", isSelf = false, level = 20, classID = 8 }
C_Club.GetGuildClubId = function() return 7 end
C_Club.GetClubMembers = function() rosterReads = rosterReads + 1; return { 1, 2, 3, 4 } end
Suite.db.mailRememberRecipient = false; mail:Apply()
book.filter, book.unassigned, book.tab = nil, false, "all"
mail:OpenBook(); book.search:SetText("")
equal(book.navigation.rows[1].entry.id, "all", "shared sidebar always offers All contacts")
equal(mail.active, nil, "standalone groups do not enable mailbox features")
mail:SelectContactTab("alts")
equal(#mail:ContactList("alts", "", nil, true), 2, "book alts retain current identity and guild alt precedence")
equal(book.rows[1].entry.group, "alts", "book renders selected group")
book.page, book.confirm = 4, friendKey
mail:SelectContactTab("guild")
equal(book.page, 1, "book group switch resets paging")
equal(book.confirm, nil, "book group switch clears removal confirmation")
equal(#mail:ContactList("guild", "", nil, true), 2, "standalone guild includes offline and saved members once")
book.search:SetText("Offline")
equal(book.rows[1].entry.roster, true, "book search finds unsaved guild member")
equal(book.rows[1].label.textColor[1], 0.2, "book Guild tab uses roster class color")
book.rows[1].OnClick()
equal(book.key, nil, "guild selection does not use roster GUID as account identity")
equal(book.remove.enabled, false, "unsaved guild member cannot be removed from roster")
book.groupChanges[mail:SaveGroup(nil, "Friends")] = true; book.notes:SetText("Guild note")
book.save.OnClick()
local guildSaved = mail:Database()[book.key]
equal(guildSaved.guid, nil, "saving guild member does not misclassify it as an account alt")
equal(guildSaved.notes, "Guild note", "saved guild member retains notes")
equal(guildSaved.class, "MAGE", "new saved contact retains observed guild class")
mail:SelectContactTab("guild"); book.search:SetText("Offline")
equal(book.rows[1].entry.roster, nil, "saved guild member is editable without duplicate live row")
local bookReads = rosterReads
mail:RefreshBook(); mail:SelectContactTab("all"); book.search:SetText("Friendly")
equal(rosterReads, bookReads, "book render search and tabs do not poll guild")
equal(book.rows[1].entry.group, "other", "All includes saved non-guild contacts")
mail:SelectContactTab("guild")
SetCombat(true)
roster[4] = nil
book.events.OnEvent(book.events, "CLUB_MEMBERS_UPDATED")
equal(rosterReads, bookReads, "standalone guild event defers in combat")
mail:SelectContactTab("all")
equal(book.tab, "guild", "combat blocks book tab changes")
DrainCombat()
mail:SelectContactTab("all"); book.search:SetText("Offline")
equal(book.rows[1].entry.name, "Offline Member", "saved departed guild member moves to Other")
equal(book.rows[1].label.textColor[3], 0.9, "Other tab keeps class color after guild departure")
book.events.OnEvent(book.events, "GUILD_ROSTER_UPDATE")
book.events.OnEvent(book.events, "CLUB_MEMBERS_UPDATED")
equal(TimerCount(), 1, "book coalesces roster event bursts")
book.frame:Hide()
equal(book.timer, nil, "closing standalone book cancels roster worker")
equal(next(book.events.registered), nil, "closing book unregisters roster events")
equal(mail.guildEntries, nil, "closing standalone book drops roster cache")
Flush()
Suite.db.mailHelper = true
mail.contactTab, mail.query = "other", "Offline"
mail:Refresh()
equal(mail.rows[1].name.textColor[1], 0.2, "mailbox Other tab retains observed class color")
Suite.db = Suite.InitializeDB(Suite.Copy(Suite.db))
equal(Stored("Offline Member").class, "MAGE", "saved recipient class survives reload initialization")
mail.query = ""
roster[4] = { name = "Unknown Member", isSelf = false, classID = { secret = true } }
mail:ReadGuild()
equal(mail:ContactList("guild", "Unknown")[1].class, nil, "restricted class ID yields neutral live row")
equal(Stored("Offline Member").class, "MAGE", "unavailable roster class does not erase saved class")
roster[4].classID = 8
local classAPI = C_CreatureInfo
C_CreatureInfo = nil; mail:ReadGuild()
equal(mail:ContactList("guild", "Unknown")[1].class, nil, "missing class API is optional")
C_CreatureInfo = { GetClassInfo = function() error("unavailable") end }; mail:ReadGuild()
equal(mail:ContactList("guild", "Unknown")[1].class, nil, "class API failure is contained")
C_CreatureInfo = { GetClassInfo = function() return { classFile = { secret = true } } end }; mail:ReadGuild()
equal(mail:ContactList("guild", "Unknown")[1].class, nil, "restricted class token is omitted")
C_CreatureInfo = classAPI
Suite.db.mailHelper = false
C_Club, C_GuildInfo = oldClub, oldGuild

-- Older books allowed blank server types. Filtering must leave a recovery path.
Suite.db = Suite.InitializeDB(nil)
player.realm, player.region = "ClassicBetaPvE", 110
mail.query = ""
for _, suffix in ipairs({ "One", "Two", "Three" }) do
    mail:Store("Known " .. suffix, "PvE", 110)
end
local lostKeys = {}
for _, suffix in ipairs({ "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine" }) do
    local key = mail:Store("Legacy " .. suffix, nil, 110)
    mail:Database()[key].category, mail:Database()[key].notes = "Friends", "Keep this note"
    lostKeys[#lostKeys + 1] = key
end
equal(#mail:List(true, ""), 3, "old twelve-contact book reproduces three visible after filtering")
local recoverySaved = Suite.Copy(Suite.db)
Suite.db = Suite.InitializeDB(recoverySaved)
mail:Store("Foreign Person", nil, 1)
mail:Store("Pvp Person", "PvP", 110)
book.filter, book.unassigned = nil, false
mail:OpenBook(); book.search:SetText("")
book.recovery.OnClick()
equal(book.unassigned, true, "book offers explicit unassigned recovery")
equal(#mail:List(true, "", nil, true), 9, "all nine unassigned names survive reload; other scopes excluded")
equal(book.rows[8]:IsShown(), true, "recovery fills first page")
book.next.OnClick()
equal(book.rows[1]:IsShown(), true, "ninth lost contact reachable by paging")
equal(book.rows[2]:IsShown(), false, "recovery paging hides unused rows")
book.rows[1].OnClick()
local recoveredOldKey = book.key
equal(book.status.text, "Save assigns this contact to PvE.", "recovery discloses server assignment")
book.save.OnClick()
equal(book.unassigned, false, "successful recovery returns to current contacts")
equal(mail:Database()[recoveredOldKey], nil, "recovery replaces only the old unassigned address")
equal(mail:Database()[book.key].notes, "Keep this note", "recovery preserves notes")
equal(#mail:ContactList("category:Friends", "", nil, true), 1, "recovery preserves migrated named membership")
equal(#mail:List(true, ""), 4, "explicit recovery makes one contact available for mail")
equal(#mail:List(true, "", nil, true), 8, "remaining unassigned contacts remain stored")
local colored = mail:Store("Colored Person", "PvE", 110, "Colored-Guid", "MAGE")
RAID_CLASS_COLORS = { MAGE = { r = 0.2, g = 0.6, b = 0.9 } }
book.search:SetText("Colored Person")
equal(book.rows[1].entry.key, colored, "book renders recorded class contact")
equal(book.rows[1].label.textColor[1], 0.2, "book uses recorded class color")
book.search:SetText("Known One")
equal(book.rows[1].label.textColor[1], 0.88, "reused row resets unknown class to normal text")
RAID_CLASS_COLORS.MAGE = { r = { secret = true }, g = 0.6, b = 0.9 }
book.search:SetText("Colored Person")
equal(book.rows[1].label.textColor[1], 0.88, "restricted class color safely falls back")
book.search:SetText("")
SetCombat(true); book.recovery.OnClick(); SetCombat(false)
equal(book.unassigned, false, "combat blocks recovery toggle")
book.recovery.OnClick()
player.realm = "UnknownVariant"
equal(#mail:List(true, "", nil, true), 0, "unknown active server cannot recover contacts")
equal(mail:SaveContact(lostKeys[1], "Legacy One", "Friends", "Keep this note"), nil, "unknown server cannot assign contacts")
player.realm = "ClassicBetaPvE"
book.unassigned = false; book.frame:Hide()

-- Explicit player-created contacts are persistent records, independent of roster/UI state.
Suite.db = Suite.InitializeDB(nil)
mail.book.unassigned = false
local permanentKeys = {}
for _, suffix in ipairs({ "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve" }) do
    local key = mail:SaveContact(nil, "Permanent " .. suffix, "Friends", "Player-created note")
    equal(type(key), "string", "player-created contact saves to the account book")
    permanentKeys[#permanentKeys + 1] = key
end
for cycle = 1, 3 do
    Suite.db = Suite.InitializeDB(Suite.Copy(Suite.db))
    Suite.db.mailHelper, Suite.db.mailRememberRecipient = false, false
    mail:Apply(); mail:EndVisit()
    player.realm = "ClassicBetaPvP"
    equal(#mail:List(true, "Permanent"), 0, "server-type filtering only hides player contacts")
    player.realm = "ClassicBetaPvE"
    equal(#mail:List(true, "Permanent"), 12, "all twelve player-created contacts survive reload and feature disable")
    for _, key in ipairs(permanentKeys) do
        equal(mail:Database()[key].notes, "Player-created note", "persistent contact metadata survives reload")
    end
end
equal(Suite.Profiles.excluded.mailContacts, true, "settings profiles exclude persistent contacts")

-- Custom parents combine categories, automatic groups and explicit contacts.
Suite.db = Suite.InitializeDB(nil); Suite.db.mailHelper = true
mail.query, mail.contactTab, mail.guildEntries = "", "alts", nil
local groupAlt = mail:Store("Group Alt", "PvE", 110, "Group-Alt-GUID")
local family = mail:SaveContact(nil, "Family Person", "Family", "")
local friend = mail:SaveContact(nil, "Friend Person", "Friends", "")
local extra = mail:SaveContact(nil, "Extra Person", "", "")
local elsewhere = mail:Store("Remote Person", "PvP", 110)
equal(mail:GroupVisible("alts"), true, "default Alts group remains visible")
equal(mail:GroupVisible("category:Family"), false, "contact categories are opt-in tabs")
local inner = mail:SaveGroup(nil, "Family and friends")
local outer = mail:SaveGroup(nil, "Alts, family & friends")
equal(mail:ToggleGroupMember(inner, "sources", "category:Family"), true, "parent includes Family category")
equal(mail:ToggleGroupMember(inner, "sources", "category:Friends"), true, "parent includes Friends category")
equal(mail:ToggleGroupMember(outer, "sources", inner), true, "parent includes another custom group")
equal(mail:ToggleGroupMember(outer, "sources", "alts"), true, "parent includes all automatic alts")
equal(mail:ToggleGroupMember(outer, "contacts", extra), true, "parent includes individual contact")
equal(mail:ToggleGroupMember(outer, "contacts", family), true, "individual may overlap included category")
equal(#mail:ContactList(outer, ""), 4, "nested union deduplicates overlapping membership")
equal(#mail:ContactList(outer, "person"), 3, "custom groups preserve search")
equal(mail:ToggleGroupMember(inner, "sources", outer), false, "parent loop is rejected")
equal(mail:ToggleGroupMember(inner, "sources", inner), false, "self inclusion is rejected")
equal(mail:ToggleGroupMember(outer, "contacts", elsewhere), false, "individuals cannot cross server types")
equal(#mail:ContactList("category:Friends", ""), 1, "category can be used directly as a tab")
mail:GroupSettings().custom[inner].sources[outer] = true
equal(#mail:ContactList(outer, ""), 4, "malformed saved cycle terminates and keeps reachable contacts")
mail:GroupSettings().custom[inner].sources[outer] = nil
local newExtra = mail:SaveContact(extra, "Renamed Person", "", "")
equal(#mail:ContactList(outer, "renamed"), 1, "direct membership survives a contact rename")
equal(mail:SaveGroup(outer, "My people"), outer, "group rename keeps its identity")
equal(mail:SaveGroup("alts", "Renamed alts"), nil, "built-in groups cannot be overwritten")
equal(mail:SaveGroup(nil, "   "), nil, "empty group names are rejected")
mail:SelectContactTab(outer)
equal(mail.contactTab, outer, "new custom group is selectable in Send Mail")
equal(book.filterSummary.text, "My people", "group navigation uses shared filter summary")
local savedGroup = Suite.Copy(mail:GroupSettings())
SetCombat(true)
equal(mail:SaveGroup(nil, "Combat"), nil, "combat prevents group creation")
equal(mail:ToggleGroupMember(outer, "sources", "guild"), false, "combat prevents group membership changes")
mail:OpenGroups()
equal(mail.groupEditor, nil, "combat prevents group editor creation")
SetCombat(false)
Suite.db = Suite.InitializeDB(Suite.Copy(Suite.db))
equal(Suite.db.mailContacts.groups.custom[outer].name, savedGroup.custom[outer].name, "group definition survives saved-data initialization")
equal(#mail:ContactList(outer, ""), 4, "nested and direct membership survive reload")
player.realm = "ClassicBetaPvP"
equal(#mail:ContactList(outer, ""), 0, "parent group preserves ruleset isolation")
player.realm = "ClassicBetaPvE"
mail:OpenGroups()
local editor = mail.groupEditor
equal(editor.frame:IsShown(), true, "group editor opens without sending mail")
editor.id = outer; mail:RefreshGroups()
local function GroupRow(list, key)
    for page = 1, 20 do
        list.page = page; list.refresh()
        for _, row in ipairs(list.rows) do
            if row.entry and (row.entry.key == key or row.entry.id == key) then return row end
        end
        if not list.next:IsEnabled() then break end
    end
    error("Missing visible group row: " .. tostring(key))
end
equal(GroupRow(editor.sourceList, "alts"):IsEnabled(), true, "custom group permits visible source editing")
GroupRow(editor.sourceList, "alts").OnClick()
equal(#mail:ContactList(outer, ""), 3, "source row removes automatic group membership")
GroupRow(editor.sourceList, "alts").OnClick()
equal(#mail:ContactList(outer, ""), 4, "source row restores automatic group membership")
editor.search:SetText("Renamed Person")
local directRow = GroupRow(editor.memberList, newExtra)
equal(directRow.label.text, "[x] Renamed Person", "visible contact row identifies direct membership")
SetCombat(true); directRow.OnClick(); SetCombat(false)
equal(#mail:ContactList(outer, "renamed"), 1, "contact membership cannot change in combat")
mail.guildEntries = { native = { name = "Native Person", region = 110, ruleset = "PvE" } }
editor.search:SetText("Native Person")
local nativeEntry = mail:ContactList("guild", "native")[1]
GroupRow(editor.memberList, nativeEntry.key).OnClick()
equal(#mail:ContactList(outer, "native"), 1, "visible member row can include session guild recipient")
equal(Find("Native Person"), nil, "group membership does not silently save guild roster contacts")
local nativeSaved = mail:SaveContact(nil, "Native Person", "", "")
equal(#mail:ContactList(outer, "native"), 1, "explicit membership survives saving guild recipient to book")
mail:DeleteContact(nativeSaved); mail.guildEntries = nil
editor.search:SetText("")
editor.visible.OnClick()
equal(mail:GroupVisible(outer), false, "editor hides selected custom tab")
equal(mail.contactTab, outer, "hiding a sidebar shortcut preserves the active group filter")
editor.visible.OnClick()
equal(mail:GroupVisible(outer), true, "editor restores selected custom tab")
local function EditorClick(label)
    for _, button in ipairs(editor.frame.children) do
        if button.label and button.label.text == label then button.OnClick(); return end
    end
    error("Missing group editor control: " .. label)
end
EditorClick("Move up")
local _, reordered = mail:GroupDefinitions()
equal(reordered[#reordered - 1], outer, "group order can move earlier")
for i = 1, 22 do mail:SaveGroup(nil, "Overflow group " .. i) end
mail:Refresh()
equal(#editor.navigation.rows, 10, "group navigation pools a bounded set of rows")
editor.navigation.next.OnClick()
equal(editor.navigation.page, 2, "additional groups are reachable by paging")
local groupPage = editor.navigation.page
SetCombat(true); editor.navigation.next.OnClick(); SetCombat(false)
equal(editor.navigation.page, groupPage, "combat cannot change group page")
mail:DeleteContact(newExtra)
equal(#mail:ContactList(outer, ""), 3, "deleting direct contact removes it from union")
editor.id = outer; mail:RefreshGroups(); editor.remove.OnClick()
equal(mail:GroupDefinitions()[outer] ~= nil, true, "deleting group requires confirmation")
editor.remove.OnClick()
equal(mail:GroupDefinitions()[outer], nil, "confirmed deletion removes parent group")
equal(#mail:ContactList(inner, ""), 2, "deleting parent preserves child group and contacts")
for id in pairs(mail:GroupDefinitions()) do mail:GroupSettings().hidden[id] = true end
mail:Refresh()
equal(book.navigation.rows[1].entry.id, "all", "All remains accessible when every sidebar group is hidden")
editor.frame:Hide()

-- Contacts and Groups share one shell; switching preserves both drafts and placement.
mail:OpenBook()
local shell, shellPoint = book.frame, book.frame.point
equal(book.content:GetParent(), shell, "contact content belongs to shared window")
equal(editor.frame:GetParent(), shell, "groups content belongs to shared window")
equal(book.editorTabs.contacts.label.text, "Contacts", "shared window has Contacts tab")
equal(book.editorTabs.groups.label.text, "Groups", "shared window has Groups tab")
book.name:SetText("Unsent Edit"); book.notes:SetText("Unsent notes")
book.editorTabs.groups.OnClick()
equal(mail.editorTab, "groups", "Groups tab selects group editor")
equal(book.content:IsShown(), false, "group tab hides all contact controls together")
equal(editor.frame:IsShown(), true, "group tab reveals group controls")
equal(shell.point, shellPoint, "tab change preserves shared window placement")
editor.name:SetText("Unsent group")
book.editorTabs.contacts.OnClick()
equal(book.name:GetText(), "Unsent Edit", "contact name draft survives tab switch")
equal(book.notes:GetText(), "Unsent notes", "contact notes draft survives tab switch")
equal(editor.frame:IsShown(), false, "Contacts tab hides group controls together")
book.editorTabs.groups.OnClick()
equal(editor.name:GetText(), "Unsent group", "group name draft survives tab switch")
mail:OpenBook(mail.frame)
equal(mail.editorTab, "contacts", "mailbox Contact book entry selects Contacts")
mail:OpenGroups(mail.frame)
equal(mail.editorTab, "groups", "mailbox Groups entry selects Groups in same window")
equal(book.frame, shell, "both entry points reuse one window")
equal(shell.point, shellPoint, "mailbox entry points preserve already-open window placement")
SetCombat(true)
book.editorTabs.contacts.OnClick(); mail:OpenBook(); mail:OpenGroups()
SetCombat(false)
equal(mail.editorTab, "groups", "combat blocks tab and entry-point changes")
equal(shell.point, shellPoint, "combat preserves shared placement")
book.close.OnClick()
equal(shell:IsShown(), false, "one close button hides shared window")
equal(editor.frame:IsShown(), false, "shared close hides groups content")
equal(next(book.events.registered), nil, "shared close releases roster events from Groups tab")
mail:OpenGroups()
equal(shell:IsShown(), true, "Groups entry reopens shared window")
equal(mail.editorTab, "groups", "Groups reopen selects matching tab")
editor.name.OnEscapePressed()
equal(shell:IsShown(), false, "Escape in group input closes shared shell")
mail:OpenBook()
equal(mail.editorTab, "contacts", "Contact book reopen selects Contacts")
book.name.OnEscapePressed()
equal(shell:IsShown(), false, "Escape in contact input closes shared shell")

local existingBook, existingEditor = mail.book, mail.groupEditor
mail.book, mail.groupEditor = nil, nil
local beforeGroupFirst = constructed
SetCombat(true); mail:OpenGroups(); SetCombat(false)
equal(constructed, beforeGroupFirst, "combat defers shared shell construction from Groups entry")
Suite.db.mailHelper, Suite.db.mailRememberRecipient = false, false
mail:OpenGroups()
equal(mail.editorTab, "groups", "Groups-first opening initializes shared shell and correct tab")
equal(mail.groupEditor.frame:GetParent(), mail.book.frame, "Groups-first builds a child pane rather than a second window")
equal(mail.book.content:IsShown(), false, "Groups-first leaves contact pane hidden")
equal(mail.book.frame:IsShown(), true, "Groups-first shows shared shell with helpers off")
equal(mail.book.events.registered.GUILD_ROSTER_UPDATE, true, "Groups-first retains visible shared roster listening")
local groupFirstShell = mail.book.frame
mail.book.editorTabs.contacts.OnClick()
equal(mail.book.frame, groupFirstShell, "Groups-first Contacts switch retains original shell")
equal(mail.book.content:IsShown(), true, "Groups-first Contacts switch reveals contact pane")
equal(mail.groupEditor.frame:IsShown(), false, "Groups-first Contacts switch hides group pane")
mail.book.close.OnClick()
equal(next(mail.book.events.registered), nil, "closing Groups-first shell removes roster listeners")
mail.book, mail.groupEditor = existingBook, existingEditor

-- Named groups are visible in the contact filter even before first assignment.
Suite.db = Suite.InitializeDB(nil); player.realm, player.region = "ClassicBetaPvE", 110
book.filter, book.groupFilter, book.unassigned, book.tab = nil, nil, false, "all"
mail.query, mail.guildEntries = "", nil
local assignedGroup = mail:SaveGroup(nil, "My friends")
local secondGroup = mail:SaveGroup(nil, "Family")
local parentGroup = mail:SaveGroup(nil, "Everyone close")
mail:ToggleGroupMember(parentGroup, "sources", assignedGroup)
mail:OpenBook(); book.search:SetText("")
local contactMenus = {}
MenuUtil = { CreateContextMenu = function(owner, generate)
    contactMenus = {}
    generate(owner, {
        CreateButton = function(_, label, callback) contactMenus[label] = { callback = callback } end,
        CreateCheckbox = function(_, label, checked, callback) contactMenus[label] = { checked = checked, callback = callback } end,
    })
end }
book.filterButton.OnClick()
equal(contactMenus["My friends"] ~= nil, true, "empty newly created group appears in Custom dropdown")
contactMenus["My friends"].callback()
equal(book.groupFilter, assignedGroup, "Custom dropdown selects exact custom group")
equal(book.filterSummary.text, "My friends", "selected custom name is visible above contact rows")
equal(book.empty:IsShown(), true, "empty group filter truthfully has no contacts")
mail:SelectContactTab("all")
equal(book.groupFilter, nil, "All button clears custom filter")
mail:EditContact(); book.name:SetText("Named Person")
book.groupsChoose.OnClick()
equal(contactMenus["My friends"].checked(), false, "contact chooser offers new group unchecked")
contactMenus["My friends"].callback(); contactMenus.Family.callback()
equal(#mail:ContactList(assignedGroup, ""), 0, "contact group choices remain drafts until Save")
book.editorTabs.groups.OnClick(); book.editorTabs.contacts.OnClick()
equal(book.groupChoices[assignedGroup], true, "group assignment draft survives editor tab changes")
equal(book.name:GetText(), "Named Person", "new contact name survives group assignment tab changes")
book.save.OnClick()
local namedKey = book.key
equal(#mail:ContactList(assignedGroup, ""), 1, "Save adds contact to selected custom group")
equal(#mail:ContactList(secondGroup, ""), 1, "Save supports multiple groups on one contact")
equal(book.rows[1].detail.text:find("My friends", 1, true) ~= nil, true, "contact row displays its saved custom memberships")
equal(#mail:ContactList(parentGroup, ""), 1, "direct group assignment also appears in parent filter")
book.filterButton.OnClick(); contactMenus["Everyone close"].callback()
equal(book.rows[1].entry.key, namedKey, "parent filter renders newly assigned contact")
book.search:SetText("absent")
equal(book.empty:IsShown(), true, "search combines with custom group filter")
book.search:SetText("")
mail:SelectContactTab("alts")
equal(book.groupFilter, nil, "Alts clears custom group selection")
mail:SelectContactTab("all"); mail:EditContact(Find("Named Person"))
book.groupsChoose.OnClick()
equal(contactMenus["My friends"].checked(), true, "saved assignment appears checked on selected contact")
local staleAssignment = contactMenus["My friends"].callback
SetCombat(true); staleAssignment(); SetCombat(false)
equal(book.groupChoices[assignedGroup], true, "combat prevents contact assignment edits")
book.editorTabs.groups.OnClick(); staleAssignment(); book.editorTabs.contacts.OnClick()
equal(book.groupChoices[assignedGroup], true, "hidden contact pane rejects stale group chooser")
book.groupsChoose.OnClick(); contactMenus["My friends"].callback()
equal(#mail:ContactList(assignedGroup, ""), 1, "unchecking group waits for Save")
book.save.OnClick()
equal(#mail:ContactList(assignedGroup, ""), 0, "Save removes unchecked direct membership")
equal(#mail:ContactList(secondGroup, ""), 1, "saving one changed membership preserves other groups")
book.groupsChoose.OnClick()
local staleContactChoice = contactMenus.Family.callback
mail:EditContact(); staleContactChoice()
equal(book.groupChoices[secondGroup], false, "menu from prior contact cannot change new contact draft")
local legacyCategory = mail:SaveContact(nil, "Category Person", "Old category", "")
book.filterButton.OnClick()
equal(contactMenus["Old category"] ~= nil, true, "Custom dropdown also lists existing contact categories")
contactMenus["Old category"].callback()
equal(mail:GroupDefinitions()[book.groupFilter].name, "Old category", "legacy category is a named group")
equal(book.filter, nil, "legacy category uses unified group filter")
equal(book.rows[1].entry.key, legacyCategory, "legacy category dropdown filters correct contact")
book.filterButton.OnClick()
local staleFilter = contactMenus["Family"].callback
player.realm = "ClassicBetaPvP"; staleFilter(); player.realm = "ClassicBetaPvE"
equal(mail:GroupDefinitions()[book.groupFilter].name, "Old category", "stale filter cannot cross server-type context")
staleFilter()
equal(book.groupFilter, secondGroup, "current scoped group filter works")
mail:SaveGroup(secondGroup, "Relatives"); mail:RefreshBook()
equal(book.filterSummary.text, "Relatives", "active group filter follows renamed group identity")
equal(mail:SaveContact(nil, "Bad Choices", "", "", { secret = true }), nil, "unreadable membership changes fail before contact save")
book.close.OnClick(); MenuUtil = old.MenuUtil

-- Adopt category metadata into the same named groups, across every scope.
Suite.db = Suite.InitializeDB(nil); player.realm, player.region = "ClassicBetaPvE", 110
local oldFamily = mail:Store("Old Person", "PvE", 110)
local caseFamily = mail:Store("Case Person", "PvE", 110)
local pvpFamily = mail:Store("Pvp Family", "PvP", 110)
local remoteFamily = mail:Store("Remote Family", "PvE", 1)
local unknownFamily = mail:Store("Unknown Family", nil, 110)
local keptFriend = mail:Store("Saved Friend", "PvE", 110)
local mergedFriend = mail:Store("Second Friend", "PvE", 110)
for _, key in ipairs({ oldFamily, pvpFamily, remoteFamily, unknownFamily }) do mail:Database()[key].category = "Family" end
mail:Database()[caseFamily].category = " family "
Suite.db.mailContacts.groups = {
    custom = {
        ["custom:7"] = { name = "Family", contacts = { [keptFriend] = true }, sources = { alts = true } },
        ["custom:8"] = { name = " family ", contacts = { [mergedFriend] = true }, sources = { ["custom:9"] = true } },
        ["custom:9"] = { name = "Close", sources = { ["custom:8"] = true, ["category:Family"] = true } },
    }, order = { "category:Family", "custom:8", "custom:9" }, hidden = { ["category:Family"] = false },
}
SetCombat(true); mail:GroupSettings(); SetCombat(false)
equal(Suite.db.mailContacts.groups.categoryAliases.Family, nil, "combat does not adopt saved category assignments")
local unified, unifiedOrder = mail:GroupDefinitions()
local familyID = mail:GroupSettings().categoryAliases.Family
equal(familyID, "custom:7", "legacy category reuses existing same-name group")
equal(unified["custom:8"], nil, "pre-existing duplicate group names merge")
equal(unifiedOrder[1], familyID, "category and duplicate order references resolve to one group")
equal(unifiedOrder[2], "custom:9", "merged group retains parent ordering")
equal(mail:GroupVisible(familyID), true, "old visible category remains a visible unified group")
equal(#mail:ContactList(familyID, "", nil, true), 4, "merged group unions both categories and existing direct members")
equal(#mail:ContactList("custom:9", "", nil, true), 4, "old category/duplicate parent links retain their union and terminate merged cycles")
equal(mail:GroupSettings().categoryAliases[" family "], familyID, "category names merge ignoring case and outer whitespace")
equal(mail:SaveGroup(nil, "FAMILY"), familyID, "creating same name reuses group instead of another list entry")
equal(mail:SaveGroup("custom:9", "Family"), nil, "rename cannot introduce duplicate group names")
equal(mail:ToggleGroupMember(familyID, "sources", "category:Family"), false, "legacy category aliases cannot bypass parent self-inclusion guard")
player.realm = "ClassicBetaPvP"
equal(#mail:ContactList(familyID, "", nil, true), 1, "category adoption preserves PvP scope")
player.realm, player.region = "ClassicBetaPvE", 1
equal(#mail:ContactList(familyID, "", nil, true), 1, "category adoption preserves region scope")
player.region = 110
mail:ToggleGroupMember(familyID, "contacts", oldFamily)
mail:Store("Old Person", "PvE", 110)
Suite.db = Suite.InitializeDB(Suite.Copy(Suite.db))
equal(#mail:ContactList(familyID, "Old Person", nil, true), 0, "removed old-category assignment is not reimported by Store or reload")
equal(#mail:ContactList(familyID, "", nil, true), 3, "other unified memberships survive reload")
book.filter, book.groupFilter, book.unassigned, book.tab = nil, nil, false, "all"
mail:OpenBook(); book.search:SetText("")
local unifiedMenu, menuNameCounts = {}, {}
MenuUtil = { CreateContextMenu = function(owner, generate)
    unifiedMenu = {}; menuNameCounts = {}
    generate(owner, {
        CreateButton = function(_, label, callback) unifiedMenu[label] = { callback = callback }; menuNameCounts[label] = (menuNameCounts[label] or 0) + 1 end,
        CreateCheckbox = function(_, label, checked, callback) unifiedMenu[label] = { checked = checked, callback = callback }; menuNameCounts[label] = (menuNameCounts[label] or 0) + 1 end,
    })
end }
book.filterButton.OnClick()
equal(menuNameCounts.Family, 1, "Custom shows one plain Family name after category/group merge")
equal(unifiedMenu["Family (group)"], nil, "Custom does not distinguish category and group labels")
unifiedMenu.Family.callback()
equal(book.groupFilter, familyID, "plain Custom choice selects canonical unified group")
mail:EditContact(Find("Case Person")); book.groupsChoose.OnClick()
equal(menuNameCounts.Family, 1, "contact chooser uses the same single Family entry")
equal(unifiedMenu.Family.checked(), true, "migrated category membership is checked on contact")
unifiedMenu.Family.callback(); book.save.OnClick()
equal(#mail:ContactList(familyID, "Case Person", nil, true), 0, "unchecking migrated category membership uses ordinary group Save")
book.unassigned, book.groupFilter = true, familyID; mail:RefreshBook()
equal(book.rows[1].entry.key, unknownFamily, "unassigned recovery can filter adopted group membership without exposing other scope")
book.unassigned = false
mail:SelectEditorTab("groups"); mail.groupEditor.id = familyID; mail:RefreshGroups()
mail.groupEditor.remove.OnClick(); mail.groupEditor.remove.OnClick()
Suite.db = Suite.InitializeDB(Suite.Copy(Suite.db))
equal(mail:GroupDefinitions()[familyID], nil, "deleted adopted group does not resurrect from retained legacy metadata")
local laterGroup = mail:SaveGroup(nil, "Later")
equal(laterGroup ~= familyID, true, "deleted adopted IDs are not reused by new groups")
equal(mail:GroupDefinitions()["category:Family"], nil, "old category alias cannot select a newly created unrelated group")
book.close.OnClick(); MenuUtil = old.MenuUtil

-- Unified directory: a saved contact is immediately addressable with no transfer step.
Suite.db = Suite.InitializeDB(nil); mail:Apply(); mail:EndVisit()
MailFrame = NewMailFrame(); SendMailFrame:Hide(); book.frame:Hide()
mail.guildEntries, mail.dismissed = nil, nil
mail:OpenBook(); mail:SelectContactTab("all"); book.search:SetText(""); mail:EditContact()
mail:SaveContact(nil, "Scope Guard", "", "")
local unifiedShell, unifiedWrites, unifiedSends = book.frame, writes, sends
for _, pane in ipairs({ book.content, book.preferences, editor.frame }) do
    for _, child in ipairs(pane.children) do
        local point = child.point
        if point and point[1] == "TOPLEFT" and type(point[2]) == "number" and type(point[3]) == "number"
            and child:GetWidth() > 0 and child:GetHeight() > 0 then
            equal(point[2] >= 0 and point[2] + child:GetWidth() <= pane:GetWidth(), true, "directory control fits pane width")
            equal(point[3] <= 0 and -point[3] + child:GetHeight() <= pane:GetHeight(), true, "directory control fits pane height")
        end
    end
end
equal(book.editorTabs.preferences.label.text, "Preferences", "shared directory includes Preferences tab")
equal(book.use:IsEnabled(), false, "standalone directory cannot fill a closed mailbox")
local priorEntry = book.entry
local staleRow = book.rows[1]
equal(type(staleRow.entry), "table", "stale-row fixture has a rendered scoped contact")
player.realm = "ClassicBetaPvP"; staleRow.OnClick(); player.realm = "ClassicBetaPvE"
equal(book.entry, priorEntry, "stale contact row cannot select a contact under another server type")
book.name:SetText("Ready Recipient"); book.notes:SetText("Available immediately")
equal(book.editState.text, "Unsaved changes", "editing clearly marks unsaved changes")
book.save.OnClick()
local readyKey = book.key
equal(type(readyKey), "string", "standalone save creates a persistent contact")
equal(book.dirty, nil, "successful save clears dirty state")
equal(book.entry.key, readyKey, "saved contact remains selected")
equal(#mail:ContactList("all", "Ready Recipient"), 1, "saved contact is immediately in the recipient directory")
equal(writes, unifiedWrites, "saving never writes native To")
equal(sends, unifiedSends, "saving never sends mail")
Suite.db.mailHelper = true; mail:Apply(); MailFrame:Show(); MailFrameTab_OnClick(nil, 2)
equal(mail.frame, unifiedShell, "opening Send Mail reuses standalone window")
equal(book.use:IsEnabled(), true, "saved selection becomes usable when Send Mail opens")
mail:EditContact()
book.name.OnTextChanged(book.name, false); book.notes.OnTextChanged(book.notes, false)
equal(book.dirty, nil, "empty editor stays clean after delayed native text notifications")
book.dirty = true -- Reproduce the screenshot's stale blank-editor dirty flag.
book.search:SetText("Ready Recipient")
local rowWrites = writes
book.rows[1].OnClick()
equal(SendMailNameEditBox:GetText(), "Ready Recipient", "single contact-row click fills native To")
equal(writes, rowWrites + 1, "row click writes native To exactly once")
equal(book.entry.key, readyKey, "clean row click also selects contact details")
equal(book.dirty, nil, "row click clears a false dirty flag by comparing actual fields")
equal(sends, unifiedSends, "row click never sends mail")
book.name.OnTextChanged(book.name, false); book.notes.OnTextChanged(book.notes, false)
equal(book.dirty, nil, "saved selection stays clean after late programmatic text callbacks")
book.notes:SetText("Temporary edit"); equal(book.dirty, true, "real text changes are dirty")
book.notes:SetText("Available immediately"); equal(book.dirty, nil, "restoring original text clears dirty state")
book.search:SetText("")
book.use.OnClick()
equal(SendMailNameEditBox:GetText(), "Ready Recipient", "explicit recipient action fills native To")
equal(book.frame, unifiedShell, "recipient action retains the same shell")
equal(sends, unifiedSends, "recipient action never sends")
local keepPoint = book.frame.point
book.name:SetText("Unsaved Recipient")
equal(book.use:IsEnabled(), false, "unsaved address edits disable recipient action")
local beforeDraftUse = writes; book.use.OnClick()
equal(writes, beforeDraftUse, "stale enabled recipient click cannot use a dirty draft")
book.search:SetText("Scope Guard")
book.rows[1].OnClick()
equal(book.name:GetText(), "Unsaved Recipient", "selecting a row cannot discard a draft")
equal(SendMailNameEditBox:GetText(), "Scope Guard", "mailbox row click addresses a different saved row while retaining editor draft")
equal(book.entry.key, readyKey, "addressing a different row preserves the draft owner")
book.search:SetText("")
mail:SelectContactTab("guild"); mail:SelectContactTab("all")
equal(book.name:GetText(), "Unsaved Recipient", "filter changes retain contact draft")
book.editorTabs.preferences.OnClick()
equal(book.content:IsShown(), false, "Preferences hides Contacts pane")
equal(editor.frame:IsShown(), false, "Preferences hides Groups pane")
equal(book.preferences:IsShown(), true, "Preferences has its own child pane")
book.editorTabs.contacts.OnClick()
equal(book.name:GetText(), "Unsaved Recipient", "Preferences round trip preserves draft")
equal(book.frame.point, keepPoint, "tab and filter changes preserve placement")
book.cancel.OnClick()
equal(book.name:GetText(), "Ready Recipient", "Cancel restores selected saved address")
equal(book.use:IsEnabled(), true, "Cancel restores recipient availability")
book.notes:SetText("Invalid scope draft"); player.realm = "ClassicBetaPvP"; book.save.OnClick()
equal(mail:Database()[readyKey].notes, "Available immediately", "scope changes cannot save a draft under another server type")
equal(book.dirty, true, "scope rejection retains draft")
player.realm = "ClassicBetaPvE"; book.cancel.OnClick()

local directGroup = mail:SaveGroup(nil, "Delivery")
local includedGroup = mail:SaveGroup(nil, "Friends of delivery")
mail:ToggleGroupMember(directGroup, "contacts", readyKey)
mail:ToggleGroupMember(includedGroup, "sources", directGroup)
mail:OpenGroups(); editor.id, editor.loadedID = includedGroup, nil; mail:RefreshGroups()
editor.search:SetText("Ready Recipient")
local inheritedRow = GroupRow(editor.memberList, readyKey)
equal(inheritedRow.label.text, "[via] Ready Recipient", "visible membership distinguishes inherited contacts")
inheritedRow.OnEnter()
equal(editor.status.text:find("Delivery", 1, true) ~= nil, true, "inherited membership explains its source")
inheritedRow.OnClick()
equal(GroupRow(editor.memberList, readyKey).label.text, "[x] Ready Recipient", "inherited contact can also be a direct member")
GroupRow(editor.memberList, readyKey).OnClick()
equal(GroupRow(editor.memberList, readyKey).label.text, "[via] Ready Recipient", "removing direct membership preserves inherited membership")
equal(mail:Database()[readyKey] ~= nil, true, "removing membership keeps saved contact")
local staleSource = GroupRow(editor.sourceList, directGroup)
player.realm = "ClassicBetaPvP"; staleSource.OnClick(); player.realm = "ClassicBetaPvE"
equal(#mail:ContactList(includedGroup, "Ready Recipient"), 1, "stale membership rows cannot mutate another scope")
book.editorTabs.contacts.OnClick(); staleSource.OnClick()
equal(#mail:ContactList(includedGroup, "Ready Recipient"), 1, "hidden Groups pane rejects stale membership clicks")
mail:SelectContactTab(directGroup); book.search:SetText(""); book.new.OnClick()
equal(book.groupChoices[directGroup], true, "new contact preselects currently viewed custom group")
equal(book.dirty, true, "preselected group membership is an unsaved contact draft")
equal(book.cancel:IsEnabled(), true, "preselected membership can be cancelled before entering a name")
book.name:SetText("Second Recipient"); book.save.OnClick()
equal(#mail:ContactList(directGroup, "Second Recipient"), 1, "saving in a group assigns membership in the same operation")
equal(book.use:IsEnabled(), true, "newly saved grouped contact is immediately usable")
book.use.OnClick()
equal(SendMailNameEditBox:GetText(), "Second Recipient", "grouped contact fills To without a separate publishing step")
book.editorTabs.preferences.OnClick(); book.details.OnClick()
equal(book.rows[1].detail:IsShown(), false, "row detail preference applies to shared list")
local preferenceCopy = Suite.Copy(Suite.db)
Suite.db = Suite.InitializeDB(preferenceCopy)
equal(mail:GroupSettings().hideDetails, true, "directory preference survives settings reload")
book.editorTabs.contacts.OnClick(); mail:SelectContactTab("all")
mail.sortButtons.level.OnClick()
equal(mail:GroupSettings().sort, "level", "sort choice is saved with contact preferences")
local savedSort = Suite.Copy(Suite.db); Suite.db = Suite.InitializeDB(savedSort)
equal(mail:GroupSettings().ascending, false, "sort direction persists")
MailFrame:Hide(); Fire("MAIL_CLOSED"); Flush()
equal(book.frame:IsShown(), true, "standalone-opened directory stays available after mailbox closes")
equal(book.use:IsEnabled(), false, "mailbox close disables recipient action immediately")
book.close.OnClick(); mail:OpenBook(MailFrame)
MailFrame:Show(); MailFrameTab_OnClick(nil, 2)
book.close.OnClick(); mail:Schedule(); Flush()
equal(book.frame:IsShown(), false, "explicit close is respected by queued mailbox refreshes")
MailFrame:Hide(); Fire("MAIL_CLOSED"); MailFrame:Show(); MailFrameTab_OnClick(nil, 2)
equal(book.frame:IsShown(), true, "a fresh mailbox visit restores automatic Contacts opening")
equal(book.mailbox, true, "automatic opening records mailbox lifecycle ownership")
MailFrameTab_OnClick(nil, 1)
equal(book.frame:IsShown(), false, "Inbox hides a mailbox-opened directory")
MailFrameTab_OnClick(nil, 2)
equal(book.frame:IsShown(), true, "Send Mail restores a mailbox-opened directory")
MailFrame:Hide(); Fire("MAIL_CLOSED")
equal(book.frame:IsShown(), false, "mailbox-opened directory closes with mailbox")
mail:OpenBook(); mail:EditContact(); book.search:SetText(""); mail:SelectContactTab("all")
local widthGetter, heightGetter = UIParent.GetWidth, UIParent.GetHeight
book.frame:Hide(); UIParent.GetWidth = function() return 680 end; UIParent.GetHeight = function() return 600 end
mail:OpenBook()
equal(book.frame:GetScale() < 1, true, "small viewports fit the whole directory")
UIParent.GetWidth, UIParent.GetHeight = widthGetter, heightGetter
book.close.OnClick()
equal(book.timer, nil, "closing shared directory leaves no roster timer")
equal(next(book.events.registered), nil, "closing shared directory releases all visible-only events")
Suite.db.mailHelper, Suite.db.mailRememberRecipient = false, false; mail:Apply(); Flush()

-- Multiline notes retain a fixed visible editor and survive every storage path.
mail:OpenBook(); mail:EditContact(); mail:SelectContactTab("all"); book.search:SetText("")
equal(book.notesPanel:GetHeight(), 100, "notes backdrop has a fixed readable height")
equal(book.notesScroll:GetParent(), book.notesPanel, "notes viewport stays inside fixed backdrop")
equal(book.notes:GetParent(), book.notesScroll, "multiline input is a scroll child")
equal(book.notes.OnEnterPressed, nil, "Enter retains native multiline newline behavior")
book.notes:SetHeight(12)
equal(book.notesPanel:GetHeight(), 100, "empty multiline text cannot collapse its backdrop")
book.notesPanel.OnMouseDown()
equal(book.notes.focused, true, "clicking blank notes area focuses its input")
book.notes:SetHeight(240); book.notes.OnCursorChanged(book.notes, 0, -180, 1, 14)
equal(book.notesScroll.offset, 110, "cursor movement scrolls overflowing notes into view")
book.notes.OnMouseWheel(book.notes, -1)
equal(book.notesScroll.offset, 134, "notes wheel scrolls within the viewport")
book.notes:SetHeight(12); book.notes.OnSizeChanged()
equal(book.notesScroll.offset, 0, "shrinking notes clamps stale scroll offset")
equal(book.use:GetFrameLevel() > book.notes:GetFrameLevel(), true, "recipient action stays clickable above overflowing notes")
book.name:SetText("Multiline Writer"); book.notes:SetText("First line\nSecond line\nThird line")
book.save.OnClick()
local notesKey, multiline = book.key, "First line\nSecond line\nThird line"
equal(type(notesKey), "string", "multiline notes can be saved through contact editor")
equal(mail:Database()[notesKey].notes, multiline, "Save preserves embedded newlines")
mail:Store("Multiline Writer", "PvE", 110)
equal(mail:Database()[notesKey].notes, multiline, "automatic contact updates preserve multiline notes")
Suite.db = Suite.InitializeDB(Suite.Copy(Suite.db))
equal(Find("Multiline Writer").notes, multiline, "multiline notes survive reload and list validation")
equal(#mail:List(true, "Second line"), 1, "search finds text on later note lines")
local normalized = mail:SaveContact(notesKey, "Multiline Writer", "", "First\r\nSecond\rThird")
equal(normalized, notesKey, "pasted platform line endings are accepted")
equal(mail:Database()[notesKey].notes, "First\nSecond\nThird", "pasted line endings normalize to newlines")
for _, bad in ipairs({ "Bad|markup", "Bad" .. string.char(1), string.rep("x", 241) }) do
    equal(mail:SaveContact(notesKey, "Multiline Writer", "", bad), nil, "notes still reject markup, unsafe controls and excessive length")
end
local bounded = string.rep("a", 119) .. "\n" .. string.rep("b", 120)
equal(mail:SaveContact(notesKey, "Multiline Writer", "", bounded), notesKey, "240-character multiline notes retain the existing limit")
book.close.OnClick()

local unknownBook = { schema = 99, entries = { keep = { name = "Permanent Unknown", category = "Friends" } }, removed = {} }
Suite.db.mailContacts = unknownBook
mail:Database()
equal(Suite.db.mailContacts.preserved, unknownBook, "unfamiliar contact schema is preserved intact")
Suite.db = Suite.InitializeDB(Suite.Copy(Suite.db))
mail:Database()
equal(Suite.db.mailContacts.preserved.entries.keep.name, "Permanent Unknown", "preserved unfamiliar book survives reload")
local legacyBook = { schema = 1, entries = { keep = { name = "Permanent Legacy", realm = "ClassicBetaPvE", region = 110 } }, removed = {} }
Suite.db.mailContacts = legacyBook
mail:Database()
equal(Suite.db.mailContacts.preserved, legacyBook, "legacy migration retains its original source book")

SetCombat(false)
for _, name in ipairs(names) do _G[name] = old[name] end
Suite.db, Suite.pending = oldDB, oldPending
