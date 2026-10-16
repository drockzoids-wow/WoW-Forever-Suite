local Suite, equal, Frame, SetCombat = ...
local buffs, oldDB, oldPending = Suite.MissingBuffs, Suite.db, Suite.pending
local names = { "CreateFrame", "RegisterStateDriver", "C_Timer", "C_Spell", "C_SpellBook", "C_UnitAuras", "C_Secrets", "C_Item", "C_EventUtils", "C_ChatInfo", "Enum",
    "UnitExists", "UnitIsConnected", "UnitIsVisible", "UnitIsDeadOrGhost", "UnitCanAssist", "UnitGUID", "UnitName", "UnitClass", "UnitLevel",
    "UnitInParty", "IsInRaid", "IsInGroup", "LE_PARTY_CATEGORY_HOME", "LE_PARTY_CATEGORY_INSTANCE", "GetTime",
    "GetNumGroupMembers", "GetNumSubgroupMembers", "IsResting", "GetInventoryItemID" }
local previous = {}; for _, name in ipairs(names) do previous[name] = _G[name] end
local oldScan = Suite.MacroItems.Scan
local oldPrint, feedback = Suite.Print, {}
Suite.Print = function(message) feedback[#feedback + 1] = message end
local secret, resting, raid, secure, made, reads, bookReads, itemReads = { secret = true }, false, false, false, 0, 0, 0, 0
local timers, units, auras, spells, learned, weapons, enchants = {}, {}, {}, {}, {}, {}, {}
local unavailableEvent
local messages, clock, homeGroup, instanceGroup, chatLock = {}, 100, true, false, false
LE_PARTY_CATEGORY_HOME, LE_PARTY_CATEGORY_INSTANCE = 1, 2
IsInGroup = function(category) return category == LE_PARTY_CATEGORY_INSTANCE and instanceGroup or category == LE_PARTY_CATEGORY_HOME and homeGroup end
GetTime = function() return clock end
C_ChatInfo = {
    InChatMessagingLockdown = function() return chatLock end,
    SendChatMessage = function(message, channel, ...)
        equal(select("#", ...), 0, "buff requests have no recipient or language override")
        messages[#messages + 1] = { message = message, channel = channel }
    end,
}
C_EventUtils = { IsEventValid = function(event) return event ~= "LEARNED_SPELL_IN_TAB" and event ~= unavailableEvent end }
Suite.pending = {}; Suite.db = Suite.InitializeDB(nil); SetCombat(false)
equal(Suite.db.missingBuffs, false, "missing buff bar defaults off")
equal(Suite.db.missingBuffIncoming, true, "teammate class suggestions are part of the enabled bar")
buffs:Apply()
equal(buffs.events, nil, "disabled buff bar registers no initial events")
equal(buffs.bar, nil, "disabled buff bar creates no protected UI")
Enum = { SpellBookSpellBank = { Player = 0 }, SpellBookItemType = { Spell = 1 }, WeaponSlot = { MainHand = 0, OffHand = 1 }, ItemEnchantType = { Temporary = 2, Imbue = 3 } }
local function Mutate(frame) assert(not InCombatLockdown() or not frame.protected or secure, "no addon mutation of protected buff UI in combat") end
CreateFrame = function(kind, name, parent, templates)
    assert(not InCombatLockdown(), "buff UI construction waits for combat")
    made = made + 1
    local frame = Frame(name)
    frame.parent = parent; frame.protected = parent and parent.protected or templates and templates:find("Secure", 1, true) ~= nil or false
    frame.attributes, frame.refs, frame.registered = {}, {}, {}
    frame.SetTexCoord = function(self, ...) self.texCoords = { ... } end
    frame.SetAttribute = function(self, key, value) Mutate(self); self.attributes[key] = value end
    frame.SetFrameRef = function(self, key, value) Mutate(self); self.refs[key] = value end
    frame.RegisterEvent = function(self, event)
        if event == "LEARNED_SPELL_IN_TAB" or event == unavailableEvent then error('Attempt to register unknown event "' .. event .. '"') end
        self.registered[event] = true
    end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    frame.StopMovingOrSizing = function(self) Mutate(self); self.moving = nil end
    for _, method in ipairs({ "SetPoint", "ClearAllPoints", "SetSize", "Show", "Hide", "SetShown", "StartMoving" }) do
        local original = frame[method]
        frame[method] = function(self, ...) Mutate(self); return original(self, ...) end
    end
    frame.CreateTexture = function(self) return CreateFrame("Texture", nil, self) end
    frame.CreateFontString = function(self) return CreateFrame("FontString", nil, self) end
    return frame
end
RegisterStateDriver = function(frame, state, condition)
    equal(frame.protected, true, "buff state controller is explicitly secure")
    equal(frame.refs.bar.protected, true, "buff bar has a valid protected reference")
    frame.condition = condition
    local compile = loadstring or load
    local snippet = assert(compile("return function(self, newstate) " .. frame.attributes["_onstate-" .. state] .. " end"))()
    frame.GetFrameRef = function(self, key) return self.refs[key] end
    frame.RunState = function(self, value)
        secure = true; local ok, errorMessage = pcall(snippet, self, value); secure = false; assert(ok, errorMessage)
    end
    frame:RunState("peaceful")
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
local function Flush()
    local pending = timers; timers = {}
    for _, timer in ipairs(pending) do if not timer.cancelled then timer.callback() end end
end
local function LeaveCombat()
    SetCombat(false)
    if buffs.controller then buffs.controller:RunState("peaceful") end
    local pending = Suite.pending; Suite.pending = {}
    for _, callback in pairs(pending) do callback() end
end
local function Unit(token, class, level)
    units[token] = { guid = "guid:" .. token, name = "Name " .. token, class = class, level = level or 40, connected = true, visible = true, dead = false, party = true }
    auras[token] = {}
end
Unit("player", "MAGE"); Unit("party1", "PRIEST"); Unit("party2", "DRUID"); Unit("party3", "WARRIOR")
UnitExists = function(unit) return units[unit] ~= nil end
UnitIsConnected = function(unit) return units[unit] and units[unit].connected end
UnitIsVisible = function(unit) return units[unit] and units[unit].visible end
UnitIsDeadOrGhost = function(unit) return units[unit] and units[unit].dead end
UnitCanAssist = function(_, unit) return units[unit] ~= nil end
UnitGUID = function(unit) return units[unit] and units[unit].guid end
UnitName = function(unit) return units[unit] and units[unit].name end
UnitClass = function(unit) return "Localized class", units[unit] and units[unit].class end
UnitLevel = function(unit) return units[unit] and units[unit].level end
UnitInParty = function(unit) return units[unit] and units[unit].party end
IsInRaid = function() return raid end
GetNumSubgroupMembers = function() return 3 end
GetNumGroupMembers = function() return 4 end
IsResting = function() return resting end
C_Secrets = { ShouldUnitIdentityBeSecret = function() return false end, ShouldUnitAuraIndexBeSecret = function() return false end }
C_UnitAuras = { GetAuraDataByIndex = function(unit, index, filter)
    assert(not InCombatLockdown(), "buff model never reads combat auras")
    equal(filter, "HELPFUL", "buff model only reads helpful auras")
    reads = reads + 1; return auras[unit] and auras[unit][index]
end }
local function Spell(id, name, level) spells[id] = { name = name, iconID = id + 100, level = level or 1 } end
Spell(1459, "Arkane Intelligenz"); Spell(1461, "Arkane Intelligenz", 14); Spell(23028, "Arcane Brilliance", 56)
Spell(6117, "Mage Armor", 34); Spell(7302, "Ice Armor", 30); Spell(168, "Frost Armor")
Spell(1243, "Fortitude"); Spell(976, "Shadow Protection", 30); Spell(14752, "Divine Spirit", 30)
Spell(1126, "Mark of the Wild"); Spell(467, "Thorns", 6); Spell(6673, "Battle Shout")
Spell(13165, "Aspect of the Hawk", 10); Spell(13163, "Aspect of the Monkey", 4)
Spell(8232, "Windfury Weapon", 30)
Spell(8075, "Strength of Earth Totem", 10); Spell(8076, "Strength of Earth", 10)
Spell(465, "Devotion Aura")
Spell(8679, "Sofort wirkendes Gift")
learned = { 1459, 1461, 6117, 7302 }
C_Spell = {
    GetSpellInfo = function(id) return spells[id] end,
    GetSpellLink = function(id) return spells[id] and "|cff71d5ff|Hspell:" .. id .. "|h[" .. spells[id].name .. "]|h|r" end,
    GetSpellLevelLearned = function(id) return spells[id] and spells[id].level end,
    IsSpellInRange = function(_, unit) return units[unit].range end,
}
C_SpellBook = {
    GetNumSpellBookSkillLines = function() bookReads = bookReads + 1; return 1 end,
    GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = #learned } end,
    GetSpellBookItemInfo = function(slot) return { itemType = 1, isPassive = false, isOffSpec = false, spellID = learned[slot] } end,
    GetSpellBookItemLevelLearned = function(slot) return spells[learned[slot]].level end,
    IsSpellKnown = function(id) if id == 2842 then return units.player.class == "ROGUE" end; for _, known in ipairs(learned) do if known == id then return true end end; return false end,
}
GetInventoryItemID = function(_, slot) return weapons[slot] end
C_Item = { GetWeaponEnchantInfo = function(slot) return enchants[slot] end,
    GetItemSpell = function(id) return id == 9001 and "Sofort wirkendes Gift" end,
    GetItemIconByID = function() return 777 end,
    GetItemInfoInstant = function(id) return id, nil, nil, id == 99 and "INVTYPE_SHIELD" or "INVTYPE_WEAPON", nil, id == 99 and 4 or 2 end }
local carried = { { id = 9001, name = "Instant Poison", icon = 132273, class = 0, subclass = 6 }, { id = 9002, name = "Occult Poison", icon = 132274, class = 0, subclass = 6 } }
Suite.MacroItems.Scan = function() itemReads = itemReads + 1; return { list = carried } end
local function Find(kind, key)
    for index, entry in ipairs(buffs.entries or {}) do if entry.kind == kind and (entry.family and entry.family.catalog.key == key or entry.hand == key) then return entry, buffs.buttons[index] end end
end
Suite.db.missingBuffs = true; resting = true; buffs:Apply()
equal(reads, 0, "rested areas perform no missing-buff aura scans")
equal(buffs.bar, nil, "rested areas create no action bar")
resting = false; SetCombat(true); buffs:Apply()
equal(buffs.bar, nil, "first combat activation defers protected bar creation")
Suite.db.missingBuffs = false; buffs:Apply(); LeaveCombat()
equal(buffs.bar, nil, "cancelled combat activation cannot reveal stale actions")
Suite.db.missingBuffs = true; buffs:Apply()
equal(buffs.events.registered.LEARNED_SPELL_IN_TAB, nil, "activation never registers the obsolete spell-learning event")
equal(buffs.events.registered.SPELLS_CHANGED, true, "modern spellbook changes remain subscribed")
equal(buffs.events.registered.PLAYER_REGEN_ENABLED, true, "registration completes through the final combat event")
unavailableEvent = "WEAPON_SLOT_CHANGED"; buffs:Apply()
equal(buffs.events.registered.WEAPON_SLOT_CHANGED, nil, "native capability check skips unavailable optional events")
equal(buffs.events.registered.PLAYER_REGEN_ENABLED, true, "an unavailable event cannot interrupt later subscriptions")
local eventAPI = C_EventUtils; C_EventUtils = nil; buffs:Apply()
equal(buffs.events.registered.WEAPON_SLOT_CHANGED, nil, "clients without event validation tolerate rejected optional registration")
equal(buffs.events.registered.PLAYER_REGEN_ENABLED, true, "fallback event rejection does not abort activation")
C_EventUtils = { IsEventValid = function(event) return event == unavailableEvent and secret or true end }; buffs:Apply()
equal(buffs.events.registered.WEAPON_SLOT_CHANGED, nil, "unreadable event-validity results are not used as true")
C_EventUtils = { IsEventValid = function(event) if event == unavailableEvent then error("Unavailable event validation") end; return true end }; buffs:Apply()
equal(buffs.events.registered.WEAPON_SLOT_CHANGED, nil, "event validation failures keep registration unknown")
C_EventUtils, unavailableEvent = eventAPI, nil; buffs:Apply()
equal(buffs.events.registered.WEAPON_SLOT_CHANGED, true, "later activation registers a now-supported event")
local initialBookReads = bookReads
buffs.events:OnEvent("SPELLS_CHANGED"); Flush()
equal(bookReads, initialBookReads + 1, "modern spellbook event invalidates and rediscovers learned buffs")
equal(buffs.bar:IsShown(), true, "missing readable buffs reveal the optional bar")
equal(buffs.controller.condition, "[combat] combat; peaceful", "native secure driver owns combat hiding")
local intellect, intellectButton = Find("self", "intellect")
equal(intellect.spell.id, 1461, "highest learned rank is selected through native learned levels")
equal(intellectButton.attributes.spell1, 1461, "self action uses the actual learned spell ID")
equal(intellectButton.attributes.unit, "player", "self buff does not change the player's target")
local outgoing, outgoingButton = Find("group", "intellect")
equal(#outgoing.names, 3, "outgoing family aggregates every missing eligible party member")
equal(outgoingButton.attributes.unit, "party1", "outgoing action targets the first missing member")
local incoming, incomingButton = Find("incoming", "fortitude")
equal(incoming.names[1], units.party1.name, "incoming suggestion names a present provider")
equal(incomingButton.attributes.type1, nil, "incoming requests have no secure spell or macro action")
equal(incomingButton.caption.text, "Ask", "incoming reminders are visibly distinct")
equal(Find("incoming", "spirit"), nil, "unknown teammate talents are not inferred")
equal(#messages, 0, "activation and spellbook events never request buffs automatically")
incomingButton:PostClick("LeftButton", true); incomingButton:PostClick("MiddleButton", false)
intellectButton:PostClick("LeftButton", false); outgoingButton:PostClick("LeftButton", false); Flush()
equal(#messages, 0, "mouse-down, other mouse buttons and castable buffs never send chat")
incoming, incomingButton = Find("incoming", "fortitude")
incomingButton:PostClick("LeftButton", false); Flush()
equal(#messages, 1, "only left-click release requests an incoming missing buff")
equal(messages[1].message, "Missing " .. C_Spell.GetSpellLink(1243), "request contains the native clickable spell link and exact phrase")
equal(messages[1].channel, "PARTY", "home parties route requests to party chat")
incomingButton:PostClick("LeftButton", false); Flush()
equal(#messages, 1, "repeated clicks on one buff are throttled")
local _, markButton = Find("incoming", "mark")
clock = clock + 1; markButton:PostClick("LeftButton", false); Flush()
equal(#messages, 1, "rapid requests for different buffs are throttled too")
clock = clock + 2; markButton:PostClick("LeftButton", false); Flush()
equal(#messages, 2, "another family can be requested after the short global cooldown")
clock = clock + 26; incomingButton:PostClick("LeftButton", false); Flush()
equal(#messages, 2, "same-family cooldown lasts thirty seconds")
clock = clock + 1; incomingButton:PostClick("LeftButton", false); Flush()
equal(#messages, 3, "same-family requests resume after thirty seconds without a timer")
for index, token in ipairs({ "player", "party1", "party2", "party3" }) do units["raid" .. index], auras["raid" .. index] = units[token], auras[token] end
raid = true; clock = clock + 30; incomingButton:PostClick("LeftButton", false); Flush()
equal(messages[#messages].channel, "RAID", "home raids route requests to raid chat")
instanceGroup = true; clock = clock + 30; incomingButton:PostClick("LeftButton", false); Flush()
equal(messages[#messages].channel, "INSTANCE_CHAT", "instance group chat takes precedence over a simultaneous home raid")
raid, instanceGroup = false, false
local function Blocked(change, restore, reason)
    buffs:Refresh()
    local _, button = Find("incoming", "fortitude")
    local count = #messages
    clock = clock + 30; change(); button:PostClick("LeftButton", false)
    equal(#messages, count, reason)
    restore(); Flush()
end
Blocked(function() homeGroup = false end, function() homeGroup = true end, "leaving the group before clicking sends no chat")
Blocked(function() instanceGroup = secret end, function() instanceGroup = false end, "unknown instance membership cannot fall back to a home channel")
local nativeGroup = IsInGroup
Blocked(function() IsInGroup = function() error("Group unavailable") end end, function() IsInGroup = nativeGroup end, "group API failure cannot route a request")
Blocked(function() LE_PARTY_CATEGORY_INSTANCE = secret end, function() LE_PARTY_CATEGORY_INSTANCE = 2 end, "unreadable category constants cannot route requests")
Blocked(function() chatLock = true end, function() chatLock = false end, "native chat lockdown suppresses a clicked request")
Blocked(function() chatLock = secret end, function() chatLock = false end, "unreadable chat lockdown never permits sending")
local nativeChat = C_ChatInfo
Blocked(function() C_ChatInfo = nil end, function() C_ChatInfo = nativeChat end, "missing modern chat APIs do not use a legacy sender")
Blocked(function() C_ChatInfo.InChatMessagingLockdown = nil end,
    function() C_ChatInfo.InChatMessagingLockdown = function() return chatLock end end, "missing lockdown predicate keeps chat access unknown")
Blocked(function() clock = secret end, function() clock = 1000 end, "secret clocks cannot be compared or used for throttling")
Blocked(function() clock = 0 / 0 end, function() clock = 1030 end, "nonfinite clocks cannot permit requests")
Blocked(function() auras.player = { { name = "Fortitude", spellId = 1243 } } end, function() auras.player = {} end, "a newly received buff cancels a stale request icon")
Blocked(function() units.party1.connected = false end, function() units.party1.connected = true end, "a departed provider cancels a stale request")
Blocked(function() units.party1.level = 0 end, function() units.party1.level = 40 end, "a provider with unavailable level cannot establish a castable buff")
local nativeAuras = C_UnitAuras.GetAuraDataByIndex
Blocked(function() C_UnitAuras.GetAuraDataByIndex = function() return secret end end,
    function() C_UnitAuras.GetAuraDataByIndex = nativeAuras end, "unknown current auras never establish a missing buff for chat")
local nativeLines, nativeBookItem = C_SpellBook.GetNumSpellBookSkillLines, C_SpellBook.GetSpellBookItemInfo
Blocked(function() C_SpellBook.GetNumSpellBookSkillLines = function() return secret end end,
    function() C_SpellBook.GetNumSpellBookSkillLines = nativeLines end, "unknown learned spellbooks cannot prove that we need someone else's buff")
Blocked(function() C_SpellBook.GetSpellBookItemInfo = function() return secret end end,
    function() C_SpellBook.GetSpellBookItemInfo = nativeBookItem end, "incomplete learned spellbooks cannot authorize a group request")
Blocked(function() resting = true end, function() resting = false end, "entering a rested area cancels clicked requests")
Blocked(function() units.player.dead = true end, function() units.player.dead = false end, "death cancels clicked requests")
Blocked(function() Suite.db.missingBuffIncoming = false end, function() Suite.db.missingBuffIncoming = true end, "disabling incoming reminders cancels stale requests")
Blocked(function() Suite.db.missingBuffs = false end, function() Suite.db.missingBuffs = true end, "disabling the feature cancels stale requests")
local nativeLink = C_Spell.GetSpellLink
for _, value in ipairs({ secret, "Fortitude", "|Hspell:976|h[Shadow Protection]|h", "|Hspell:1243|h[Bad\nlink]|h", string.rep("x", 248) }) do
    Blocked(function() C_Spell.GetSpellLink = function() return value end end,
        function() C_Spell.GetSpellLink = nativeLink end, "unreadable, malformed, mismatched or oversized spell links cannot enter chat")
end
Blocked(function() C_Spell.GetSpellLink = function() return nil end end,
    function() C_Spell.GetSpellLink = nativeLink end, "loading spell links send no fabricated fallback text")
Blocked(function() C_Spell.GetSpellLink = function() error("Link unavailable") end end,
    function() C_Spell.GetSpellLink = nativeLink end, "failed link queries cannot escape the click handler or enter chat")
local nativeSend, attempts = C_ChatInfo.SendChatMessage, 0
Blocked(function() C_ChatInfo.SendChatMessage = function() attempts = attempts + 1; error("Native send rejected") end end,
    function() C_ChatInfo.SendChatMessage = nativeSend end, "native sender rejection is contained without a fallback channel")
equal(attempts, 1, "native rejection causes just one send attempt")
incoming, incomingButton = Find("incoming", "fortitude")
local countAfterFailure = #messages
incomingButton:PostClick("LeftButton", false); Flush()
equal(#messages, countAfterFailure, "unknown delivery outcomes are throttled and never retried automatically")
-- Own learned buffs remain ours to cast even when their personal filter is off.
units.party2.class = "MAGE"; Suite.db.missingBuffSelf = false; buffs:Refresh()
equal(Find("incoming", "intellect"), nil, "disabling own buff reminders does not turn a learned buff into a request")
units.player.class, learned, Suite.db.missingBuffSelf = "PRIEST", {}, true; buffs.bookDirty = true; buffs:Refresh()
incoming, incomingButton = Find("incoming", "fortitude")
clock = clock + 30; learned = { 1243 }; Suite.db.missingBuffSelf = false
local countBeforeLearned = #messages
incomingButton:PostClick("LeftButton", false); Flush()
equal(#messages, countBeforeLearned, "clicking rediscovers newly learned own buffs before requesting")
equal(Find("incoming", "fortitude"), nil, "newly learned own buff disappears from incoming requests despite disabled self filter")
units.player.class, units.party2.class, learned, Suite.db.missingBuffSelf = "MAGE", "DRUID", { 1459, 1461, 6117, 7302 }, true
buffs.bookDirty = true; buffs:Refresh()
incoming, incomingButton = Find("incoming", "fortitude")
local countBeforeRightClick = #messages
incomingButton:PostClick("RightButton", false); Flush()
equal(#messages, countBeforeRightClick, "right-click hides the family without sending chat")
buffs:ResetChoices(); Flush(); incoming, incomingButton = Find("incoming", "fortitude")
buffs:Cycle(incoming); Flush()
equal(Find("incoming", "fortitude"), nil, "right-click can hide an unwanted incoming family without sending messages")
buffs:ResetChoices(); Flush()
equal(Find("incoming", "fortitude") ~= nil, true, "restoring choices brings incoming reminders back")
units.party1.level = 10; buffs:Refresh()
equal(Find("incoming", "shadow"), nil, "provider level gates baseline class suggestions")
units.party1.level = 40
units.party2.visible = false; units.party3.connected = false; buffs:Refresh()
equal(#Find("group", "intellect").names, 1, "invisible and disconnected units are excluded")
equal(Find("incoming", "mark"), nil, "invisible providers do not establish available buffs")
units.party2.visible, units.party3.connected = true, true
auras.player = { { name = "Arkane Intelligenz", spellId = 1460 }, { name = "Frost Armor", spellId = 168 } }
auras.party1 = { { name = "Arkane Intelligenz", spellId = 1459 } }; buffs:Refresh()
equal(Find("self", "intellect"), nil, "localized aura names match lower ranks")
equal(Find("self", "armor"), nil, "an alternative armor satisfies the whole family")
equal(#Find("group", "intellect").names, 2, "already buffed members leave the outgoing queue")
outgoing, outgoingButton = Find("group", "intellect")
local originalGUID = units.party2.guid; units.party2.guid = "replacement"
outgoingButton:PreClick("LeftButton")
equal(outgoingButton.attributes.type1, nil, "roster token replacement cancels a stale cast")
units.party2.guid = originalGUID; Flush()
outgoing, outgoingButton = Find("group", "intellect")
auras.party2 = { { name = "Arkane Intelligenz", spellId = 1461 } }
outgoingButton:PreClick("LeftButton")
equal(outgoingButton.attributes.type1, nil, "a newly present buff cancels a stale cast on release")
Flush()
auras.player, auras.party1, auras.party2 = {}, {}, {}
local beforeBook = bookReads
buffs:Refresh(); buffs:Refresh()
equal(bookReads, beforeBook, "ordinary aura refreshes reuse learned spellbook discovery")
for _ = 1, 200 do buffs.events:OnEvent("UNIT_AURA", "party1") end
equal(#timers, 1, "raid aura bursts coalesce to one timer")
local stale = buffs.timer
SetCombat(true); buffs.controller:RunState("combat"); buffs.events:OnEvent("PLAYER_REGEN_DISABLED")
equal(buffs.bar:IsShown(), false, "secure combat entry hides the protected bar")
equal(buffs.timer, nil, "combat entry cancels pending scans")
local beforeCombatReads, beforeMade = reads, made
local beforeCombatMessages = #messages
incomingButton:PostClick("LeftButton", false)
equal(#messages, beforeCombatMessages, "combat clicks never send buff requests")
stale.callback(); buffs:Refresh(); buffs:Collect()
equal(reads, beforeCombatReads, "combat performs no aura scans")
equal(made, beforeMade, "combat creates no protected action controls")
LeaveCombat(); buffs.events:OnEvent("PLAYER_REGEN_ENABLED")
equal(buffs.bar:IsShown(), true, "combat exit rebuilds from current readable data")
local nativeAura = C_UnitAuras.GetAuraDataByIndex
C_UnitAuras.GetAuraDataByIndex = function() return secret end; buffs:Refresh()
equal(#buffs.entries, 0, "secret aura results cannot become missing buffs")
C_UnitAuras.GetAuraDataByIndex = function() return { name = secret, spellId = 1459 } end; buffs:Refresh()
equal(#buffs.entries, 0, "secret individual aura fields keep absence unknown")
C_UnitAuras.GetAuraDataByIndex = function() error("Aura access unavailable") end; buffs:Refresh()
equal(#buffs.entries, 0, "API access failure is not an empty aura list")
C_UnitAuras.GetAuraDataByIndex = function() return { name = "Other buff", spellId = 123 } end; buffs:Refresh()
equal(#buffs.entries, 0, "bounded incomplete aura lists cannot prove absence")
C_UnitAuras.GetAuraDataByIndex = nativeAura
C_Secrets.ShouldUnitAuraIndexBeSecret = function() return secret end; buffs:Refresh()
equal(#buffs.entries, 0, "unreadable aura predicate rejects scanning")
C_Secrets.ShouldUnitAuraIndexBeSecret = function() return false end
resting = secret; buffs:Refresh(); equal(#buffs.entries, 0, "unknown resting state hides the bar")
resting = false
units.player.class, learned = "HUNTER", { 13165 }; buffs.bookDirty = true
auras.player = { { name = "Aspect of the Monkey", spellId = 13163 } }; buffs:Refresh()
equal(Find("self", "aspect"), nil, "any active hunter aspect satisfies upkeep without asking for every aspect")
auras.player = {}; buffs:Refresh()
local aspect, aspectButton = Find("self", "aspect")
equal(aspectButton.attributes.spell1, 13165, "missing aspect is a learned self-cast action")
buffs:Cycle(aspect); Flush(); equal(Find("self", "aspect"), nil, "cycling after the last learned alternative hides its family")
buffs:ResetChoices(); Flush(); equal(Find("self", "aspect").spell.id, 13165, "restoring choices brings hidden families back")
raid = true; units.raid1 = units.player; auras.raid1 = auras.player
Unit("raid2", "MAGE"); Unit("raid3", "DRUID"); Unit("raid4", "PRIEST")
units.raid3.party = false
equal(#buffs:Roster(), 4, "raid roster removes the duplicate player GUID")
units.raid4.class = "PALADIN"; buffs:Refresh()
equal(Find("incoming", "aura") ~= nil, true, "a party paladin can supply a missing native aura")
units.raid4.party = false; buffs:Refresh()
equal(Find("incoming", "aura"), nil, "incoming party auras do not infer coverage from another raid subgroup")
units.raid4.class, units.raid4.party = "PRIEST", true
units.player.class, learned = "WARRIOR", { 6673 }; buffs.bookDirty = true; buffs:Refresh()
equal(#Find("group", "shout").names, 2, "party-wide casts exclude other raid subgroups")
auras.player = { { name = "Battle Shout", spellId = 6673 } }; buffs:Refresh()
local shout, shoutButton = Find("group", "shout")
equal(shoutButton.attributes.unit, "player", "party-wide shout uses the native self cast")
shoutButton:PreClick("LeftButton")
equal(shoutButton.attributes.type1, "spell", "already buffed caster can still buff missing party members")
units.raid2.party = false
shoutButton:PreClick("LeftButton")
equal(shoutButton.attributes.type1, nil, "a changed raid subgroup cancels stale party-only casts")
units.raid2.party = true; Flush()
raid = false; auras.player = {}; units.player.class, learned = "ROGUE", {}; buffs.bookDirty, buffs.itemsDirty = true, true
weapons[16], weapons[17], enchants[0], enchants[1] = 1, 99, { { hasEnchant = true, enchantType = 2 } }, {}
buffs:Refresh()
local poison, poisonButton = Find("poison", "MH")
equal(poisonButton.attributes.type1, nil, "poison application requires an explicit carried-item choice")
equal(Find("poison", "OH"), nil, "shield off hands never request poison")
buffs:Cycle(poison); Flush(); poison, poisonButton = Find("poison", "MH")
equal(poisonButton.attributes.macrotext1, "/use item:9001\n/use 16", "chosen carried poison targets its exact equipped hand")
equal(poison.spell.icon, 777, "carried-item icons are read through the modern item API")
local nativeIcon = C_Item.GetItemIconByID; C_Item.GetItemIconByID = function() return secret end
buffs:Refresh(); equal(Find("poison", "MH").spell.icon, 132273, "unavailable poison icons keep a readable fallback")
C_Item.GetItemIconByID = nativeIcon
carried[1].name = "Sofort wirkendes Gift"; buffs.itemsDirty = true
equal(#buffs:PoisonChoices(), 2, "native localized poison spell names recognize carried items")
carried[1].name = "Instant Poison"
local poisonScans = itemReads; buffs:Refresh(); equal(itemReads, poisonScans, "aura changes reuse carried poison metadata")
carried = {}; poisonButton:PreClick("LeftButton")
equal(poisonButton.attributes.type1, nil, "removed poison cancels a stale item action")
carried = { { id = 9001, name = "Instant Poison", icon = 132273, class = 0, subclass = 6 } }
enchants[0] = { { hasEnchant = true, enchantType = 3 } }; buffs.itemsDirty = true; buffs:Refresh()
equal(Find("poison", "MH"), nil, "native active imbue satisfies rogue poison upkeep independently of oils")
enchants[0] = {}; buffs.events:OnEvent("WEAPON_ENCHANT_CHANGED"); Flush()
equal(Find("poison", "MH") ~= nil, true, "native enchant expiry event restores the missing poison reminder")
enchants[0] = secret; buffs:Refresh(); equal(Find("poison", "MH"), nil, "restricted enchant records cannot establish missing poison")
units.player.class, learned = "SHAMAN", { 8232 }; buffs.bookDirty = true
enchants[0] = { { hasEnchant = true, enchantType = 2 } }; buffs:Refresh()
local imbue, imbueButton = Find("self", "imbue")
equal(imbue.spell.id, 8232, "temporary oils do not satisfy shaman weapon imbues")
enchants[0] = { { hasEnchant = true, enchantType = 3 } }
imbueButton:PreClick("LeftButton")
equal(imbueButton.attributes.type1, nil, "already applied weapon imbue cancels stale recasting")
learned = { 8232, 8075 }; buffs.bookDirty = true; buffs:Refresh()
local totem, totemButton = Find("group", "earth")
equal(totemButton.attributes.unit, "player", "learned party totems cast on the player for missing group members")
auras.player = { { name = "Strength of Earth", spellId = 8076 } }; buffs:Refresh()
equal(Find("self", "earth"), nil, "native totem aura IDs satisfy upkeep independently of the totem spell name")
equal(Find("group", "earth") ~= nil, true, "a totem reminder still identifies uncovered party members")
Suite.db.missingBuffClass = false; auras.player = {}; buffs:Refresh()
equal(Find("self", "earth"), nil, "class-upkeep toggle independently controls personal party aura upkeep")
units.player.class, learned = "PALADIN", { 465 }; buffs.bookDirty = true
auras.player = { { name = "Devotion Aura", spellId = 465 } }; buffs:Refresh()
local coverage, coverageButton = Find("group", "aura")
equal(coverage.passive, true, "already active toggle auras show group coverage reminders")
equal(coverageButton.attributes.type1, nil, "group reminders never toggle a currently active aura off")
auras.player = {}; buffs:Refresh(); coverage, coverageButton = Find("group", "aura")
equal(coverageButton.attributes.type1, "spell", "an inactive party aura can be activated for the group")
auras.player = { { name = "Devotion Aura", spellId = 465 } }; coverageButton:PreClick("LeftButton")
equal(coverageButton.attributes.type1, nil, "a newly active aura cancels a stale group toggle on release")
units.player.class, learned, auras.player = "MAGE", { 1461 }, {}; buffs.bookDirty = true
local delayed, requests = spells[1461], {}; spells[1461] = nil
C_Spell.RequestLoadSpellData = function(id) requests[id] = (requests[id] or 0) + 1 end
buffs:Refresh(); buffs:Refresh()
equal(Find("self", "intellect"), nil, "unavailable learned spell data does not fabricate a usable action")
equal(requests[1461], 1, "unavailable public spell data is requested once without polling")
spells[1461] = delayed; buffs.events:OnEvent("SPELL_DATA_LOAD_RESULT", 1461, true); Flush()
equal(Find("self", "intellect").spell.id, 1461, "asynchronous spell data completion rebuilds learned actions")
equal(buffs:InitializeChoices(secret)["MAGE:armor"], nil, "secret choice tables are discarded")
equal(buffs:InitializeChoices({ ["MAGE:armor"] = secret, bad = 42 })["MAGE:armor"], nil, "secret choices and unrecognized keys are discarded")
equal(buffs:InitializeChoices({ ["MAGE:armor"] = 0 })["MAGE:armor"], 0, "hidden family choice survives normalization")
SlashCmdList.WOWFOREVERSUITE("buffs")
equal(Suite.GUI.page, "buffs", "buff bar has its own slash-accessible settings page")
for index = 1, 8 do
    equal(-Suite.GUI.rows[index].point[3] + Suite.GUI.rows[index].height <= Suite.GUI.content.height - 36, true,
        "buff settings remain within the scrollable content instead of overflowing the footer")
end
buffs:SetPreview(true); equal(buffs.preview:IsShown(), true, "settings can preview placement without actions")
Suite.GUI:Select("overview"); equal(buffs.preview:IsShown(), false, "navigation cancels the non-actionable preview")
buffs:ResetPosition(); equal(next(Suite.db.missingBuffPosition), nil, "bar position reset leaves other saved layouts alone")
Suite.db.missingBuffs = false; buffs:Apply()
equal(next(buffs.events.registered), nil, "disable removes buff feature event subscriptions")
equal(buffs.timer, nil, "disable leaves no timer")
equal(buffs.bar:IsShown(), false, "disable hides the bar")
equal(#messages, countBeforeRightClick, "later aura, spell data, enchant, preview and disable events send no automatic requests")
Suite.db, Suite.pending = oldDB, oldPending
Suite.MacroItems.Scan = oldScan
Suite.Print = oldPrint
for _, name in ipairs(names) do _G[name] = previous[name] end
SetCombat(false)
