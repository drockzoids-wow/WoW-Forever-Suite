local Suite, equal, Frame, SetCombat = ...
local buffs, oldDB, oldPending = Suite.MissingBuffs, Suite.db, Suite.pending
local names = { "CreateFrame", "RegisterStateDriver", "C_Timer", "C_Spell", "C_SpellBook", "C_UnitAuras", "C_Secrets", "C_Item", "C_EventUtils", "C_ChatInfo", "Enum",
    "UnitExists", "UnitIsConnected", "UnitIsVisible", "UnitIsDeadOrGhost", "UnitCanAssist", "UnitGUID", "UnitName", "UnitClass", "UnitLevel",
    "UnitInParty", "IsInRaid", "IsInGroup", "LE_PARTY_CATEGORY_HOME", "LE_PARTY_CATEGORY_INSTANCE", "GetTime",
    "GetNumGroupMembers", "GetNumSubgroupMembers", "IsResting", "GetInventoryItemID", "C_PaperDollInfo", "UnitIsUnit" }
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
C_Timer = { NewTimer = function(delay, callback)
    local timer = { delay = delay, callback = callback, Cancel = function(self) self.cancelled = true end }
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
    for _, entry in ipairs(buffs.entries or {}) do
        if entry.kind == kind and (entry.family and entry.family.catalog.key == key or entry.hand == key) then
            for _, button in ipairs(buffs.buttons) do if button.entry == entry then return entry, button end end
            return entry
        end
    end
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
local function NoticeCount(text)
    local count = 0
    for _, message in ipairs(feedback) do
        if message:find("Missing buffs:", 1, true) and (not text or message:find(text, 1, true)) then count = count + 1 end
    end
    return count
end
equal(incoming.names[1], units.party1.name, "incoming suggestion retains its eligible provider")
equal(incomingButton, nil, "buffs we cannot provide have no Ask placeholder in the action bar")
equal(NoticeCount("Fortitude"), 1, "unavailable own buff is reported in local chat")
equal(#messages, 0, "local reminders never broadcast to party or raid")
equal(Find("incoming", "spirit"), nil, "unknown teammate talents are not inferred")
local unchangedNotices = NoticeCount()
buffs:Refresh(); clock = clock + 61; buffs:Refresh()
equal(NoticeCount(), unchangedNotices, "unchanged missing buffs do not repeat after cooldown or aura refreshes")
auras.player = { { name = "Fortitude", spellId = 1243 } }; buffs:Refresh()
auras.player = {}; buffs:Refresh()
equal(NoticeCount("Fortitude"), 2, "a newly missing buff can notify again after it was supplied")
auras.player = { { name = "Fortitude", spellId = 1243 } }; buffs:Refresh()
auras.player = {}; clock = clock + 1; buffs:Refresh()
equal(NoticeCount("Fortitude"), 2, "rapid loss and recovery respects the local notice cooldown")
clock = clock + 60; buffs:Refresh()
equal(NoticeCount("Fortitude"), 3, "a suppressed new loss can notify on a later normal update")
intellectButton:PostClick("LeftButton", false); Flush()
equal(#messages, 0, "casting an available spell never sends chat")
units.party2.class = "MAGE"; Suite.db.missingBuffSelf = false; buffs:Refresh()
equal(Find("incoming", "intellect"), nil, "turning off own buff icons never turns a learned spell into a chat reminder")
units.player.class, learned, Suite.db.missingBuffSelf = "PRIEST", {}, true; buffs.bookDirty = true; buffs:Refresh()
local beforeLearning = NoticeCount("Fortitude")
learned = { 1243 }; Suite.db.missingBuffSelf = false; buffs.bookDirty = true; buffs:Refresh()
equal(Find("incoming", "fortitude"), nil, "newly learned own spell stops incoming reminders")
equal(NoticeCount("Fortitude"), beforeLearning, "a compatible learned buff suppresses local fallback even with self icons off")
units.player.class, units.party2.class, learned, Suite.db.missingBuffSelf = "MAGE", "DRUID", { 1459, 1461, 6117, 7302 }, true
buffs.bookDirty = true; buffs:Refresh()
incoming = Find("incoming", "fortitude")
buffs:Cycle(incoming); Flush()
equal(Find("incoming", "fortitude"), nil, "existing hidden family choices also suppress local notices")
buffs:ResetChoices(); Flush()
equal(Find("incoming", "fortitude") ~= nil, true, "restoring family choices restores the watched local reminder")
local nativeSkillCount = C_SpellBook.GetNumSpellBookSkillLines
local beforeUnknownBook = NoticeCount()
C_SpellBook.GetNumSpellBookSkillLines = function() return secret end
buffs.bookDirty = true; buffs:Refresh()
equal(NoticeCount(), beforeUnknownBook, "unknown learned spells never authorize a cannot-apply chat fallback")
C_SpellBook.GetNumSpellBookSkillLines = nativeSkillCount; buffs.bookDirty = true; buffs:Refresh()
local countBeforeRightClick = 0
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
buffs.buttons[1]:PostClick("LeftButton", false)
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
equal(poison.spell.icon, 777, "carried poison choices use the actual item icon before selection")
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
Flush()
local noPoison, noPoisonButton = Find("poison", "MH")
equal(noPoison ~= nil, true, "missing poison remains in the reminder model")
equal(noPoisonButton, nil, "missing poison supplies never leave an MH placeholder on the bar")
equal(NoticeCount("Main-hand"), 1, "missing poison supplies produce a local hand reminder")
local noPoisonNotices = NoticeCount("Main-hand"); buffs:Refresh()
equal(NoticeCount("Main-hand"), noPoisonNotices, "unchanged missing poison supplies do not spam chat")
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
-- Expiry, custom spells, coating choices and passive combat presentation.
do
    local extra = Suite.BuffReminders
    local originalUnits, originalAuras, originalLearned, originalClock = units, auras, learned, clock
    local originalMacroDB = Suite.macroDB
    local originalNotices, originalNoticeTimes = buffs.notices, buffs.noticeTimes
    buffs.notices, buffs.noticeTimes = {}, {}
    local settings = { Suite.db.missingBuffSelf, Suite.db.missingBuffOutgoing, Suite.db.missingBuffIncoming, Suite.db.missingBuffClass }
    units, auras = {}, {}; Unit("player", "MAGE", 60); Unit("party1", "MAGE", 60)
    Suite.db.missingBuffIncoming, Suite.db.missingBuffOutgoing = false, false
    Suite.db.missingBuffSelf, Suite.db.missingBuffClass, Suite.db.missingBuffExpiry = true, true, true
    Suite.db.missingBuffWarning = 60; clock = 100; learned = { 1461 }; buffs.bookDirty = true
    auras.player = { { name = "Arkane Intelligenz", spellId = 1461, duration = 3600, expirationTime = clock + 61 } }
    buffs:Refresh()
    equal(Find("self", "intellect"), nil, "long buff remains covered before its warning")
    equal(extra.deadline ~= nil, true, "next expiry warning schedules a cancellable deadline")
    equal(extra.deadline.delay > 1 and extra.deadline.delay < 2, true, "deadline targets the warning boundary")
    clock = 102; local deadline = extra.deadline; deadline.callback()
    local entry, button = Find("self", "intellect")
    equal(entry.remaining, 59, "long buff warns without waiting for another aura event")
    equal(button.attributes.type1, "spell", "expiring outside-combat reminder retains native click action")
    auras.player[1].expirationTime = clock + 3600; button:PreClick("LeftButton")
    equal(button.attributes.type1, nil, "freshly refreshed aura cancels stale expiry click")
    auras.player[1].duration, auras.player[1].expirationTime = 1799, clock + 16; buffs:Refresh()
    equal(Find("self", "intellect"), nil, "short buff does not use the long-buff interval")
    auras.player[1].expirationTime = clock + 15; buffs:Refresh()
    equal(Find("self", "intellect") ~= nil, true, "short buff warns at fifteen seconds")
    auras.player[1].duration, auras.player[1].expirationTime = 1800, clock + 60; buffs:Refresh()
    equal(Find("self", "intellect") ~= nil, true, "thirty-minute full duration uses long interval")
    auras.player[1].expirationTime = secret; buffs:Refresh()
    equal(Find("self", "intellect"), nil, "restricted expiry cannot imply imminent expiration")
    auras.player[1].duration, auras.player[1].expirationTime = secret, clock + 16; buffs:Refresh()
    equal(Find("self", "intellect"), nil, "unknown full duration uses the later short warning")
    auras.player[1].expirationTime = 0; buffs:Refresh()
    equal(Find("self", "intellect"), nil, "permanent aura never expires")
    auras.player = { { name = "Arkane Intelligenz", spellId = 1461, duration = 3600, expirationTime = clock + 20 },
        { name = "Arcane Brilliance", spellId = 23028, duration = 3600, expirationTime = clock + 200 } }
    buffs:Refresh(); equal(Find("self", "intellect"), nil, "another covering equivalent suppresses an expiring rank")
    equal(extra.deadline.delay > 140, true, "equivalent coverage schedules the last covering aura")
    auras.player = { { name = "Arkane Intelligenz", spellId = 1461 } }
    auras.party1 = { { name = "Arkane Intelligenz", spellId = 1461, duration = 3600, expirationTime = clock + 10 } }
    Suite.db.missingBuffOutgoing = true; buffs:Refresh()
    equal(Find("group", "intellect").names[1], "Name party1", "expiring group member becomes the next click target")
    Suite.db.missingBuffExpiry = false; buffs:Refresh()
    equal(Find("group", "intellect"), nil, "expiry toggle leaves missing-only behavior intact")
    equal(extra:Custom(secret)[1], nil, "restricted custom tables are rejected")
    equal(#extra:Custom({ { id = secret }, { id = 9005 }, { id = 9005 } }), 1, "custom validation rejects secrets and duplicates")
    Spell(9005, "Custom Guard"); learned = { 1461, 9005 }; buffs.bookDirty = true
    equal(extra:AddCustom("9005", false), true, "custom spell IDs can be saved without casting")
    equal(extra:AddCustom("9005", true), false, "custom duplicates are rejected")
    equal(extra:AddCustom("not a spell", false), false, "invalid custom input is rejected")
    extra:OpenOptions()
    equal(extra.options:IsShown(), true, "custom editor opens from its settings action")
    equal(extra.options.rows[1].label.text:find("9005", 1, true) ~= nil, true, "custom editor shows the saved spell")
    extra.options.rows[1].scope:OnClick()
    equal(Suite.db.missingBuffCustom[1].group, true, "scope control enables group watching")
    extra.options.rows[1].scope:OnClick()
    equal(Suite.db.missingBuffCustom[1].group, false, "scope control restores self watching")
    extra.options.input:OnEscapePressed()
    equal(extra.options:IsShown(), false, "Escape from the edit field closes the custom editor")
    buffs:Refresh(); local custom, customButton = Find("self", "CUSTOM:9005")
    equal(custom.spell.id, 9005, "learned custom spell gets its own reminder")
    equal(customButton.attributes.spell1, 9005, "custom click binds the learned spell")
    customButton:PostClick("RightButton", false); buffs:Refresh()
    equal(Find("self", "CUSTOM:9005"), nil, "custom reminder can be hidden by right-click")
    equal(buffs:InitializeChoices(Suite.db.missingBuffChoices, Suite.db.missingBuffCustom)["CUSTOM:9005"], 0, "hidden custom choice survives saved-data normalization")
    Suite.db.missingBuffChoices["CUSTOM:9005"] = nil
    Suite.db.missingBuffCustom[1].group = true; buffs:Refresh()
    equal(Find("group", "CUSTOM:9005").unit, "party1", "custom group opt-in targets a group member")
    learned = { 1461 }; buffs.bookDirty = true; buffs:Refresh()
    equal(Find("self", "CUSTOM:9005"), nil, "unlearned custom spells never become actions")
    equal(Find("group", "CUSTOM:9005"), nil, "unlearned custom group spells never become actions")
    Suite.db.missingBuffCustom = {}
    -- Prepared standard coating choices use no macro creation or automatic item use.
    local savedCarried = carried
    carried = { { id = 9001, name = "Selected Oil", icon = 777, class = 0, subclass = 6 } }
    local supplyIncomplete = false
    Suite.MacroItems.Scan = function()
        itemReads = itemReads + 1
        local byID = {}; for _, item in ipairs(carried) do byID[item.id] = item end
        return { list = carried, byID = byID, incomplete = supplyIncomplete }
    end
    Suite.macroDB = { entries = { { recipe = "mainhand", item = 9001 } } }
    weapons[16] = 50; buffs.itemsDirty = true
    local enchantInfo
    C_PaperDollInfo = { GetTemporaryEnchantmentInfo = function(slot) equal(slot, 16, "coating reader uses inventory slot sixteen"); return enchantInfo end }
    Suite.db.missingBuffWeapons = true; buffs:Refresh()
    local coating
    for _, item in ipairs(buffs.entries) do if item.kind == "coating" then coating = item end end
    equal(coating.item.id, 9001, "selected carried oil supplies a coating reminder")
    equal(extra:CoatingClick(coating), true, "coating click revalidates current inventory")
    equal(coating.spell.icon, 777, "coatings resolve the native item icon instead of relying on scanner-only metadata")
    local availableOil = carried
    carried = { { id = 9002, name = "Alternative Oil", class = 0, subclass = 6 } }
    buffs.itemsDirty = true; buffs:Refresh()
    local alternativeCoating, alternativeButton = Find("coating", "MH")
    equal(alternativeCoating.item, nil, "alternative coating is not applied without an explicit choice")
    equal(#alternativeCoating.choices, 1, "compatible carried alternative is retained as a choice")
    equal(alternativeButton ~= nil, true, "compatible carried alternative stays on the missing-buff window")
    equal(alternativeButton.attributes.type1, nil, "choosing an alternative does not invent a secure item action")
    equal(alternativeCoating.spell.icon, 777, "alternative selection displays the real carried item icon")
    local oldOpenPage, oldSelected, openedCoating = Suite.GUI.OpenPage, Suite.GUI.macroSelected
    Suite.GUI.OpenPage = function(_, page) openedCoating = page end
    alternativeButton:PostClick("LeftButton", false)
    equal(openedCoating, "macros", "available coating choice opens its normal item selection page")
    equal(Suite.GUI.macroSelected, Suite.macroDB.entries[1], "coating choice selects the matching hand settings")
    Suite.GUI.OpenPage, Suite.GUI.macroSelected = oldOpenPage, oldSelected
    local beforeUnknownSupplies = NoticeCount("Main-hand")
    supplyIncomplete = true; carried = {}; buffs.itemsDirty = true; buffs:Refresh()
    equal(NoticeCount("Main-hand"), beforeUnknownSupplies, "unknown inventory never emits a no-supplies reminder")
    supplyIncomplete = false
    local beforeAbsentCoating = NoticeCount("Main-hand")
    carried = {}; buffs.itemsDirty = true; buffs:Refresh()
    equal(NoticeCount("Main-hand"), beforeAbsentCoating + 1, "known missing coating supplies produce one local notice")
    local absentCoating, absentButton = Find("coating", "MH")
    equal(absentCoating.item, nil, "missing selected coating is represented without an invented item")
    equal(absentButton, nil, "missing selected coating never creates the reported question-mark icon")
    local showSelf, showClass = Suite.db.missingBuffSelf, Suite.db.missingBuffClass
    Suite.db.missingBuffSelf, Suite.db.missingBuffClass = false, false; buffs:Refresh()
    equal(#buffs.displayEntries, 0, "only unavailable supplies leave no visual action entries")
    equal(buffs.bar:IsShown(), false, "the reported single MH question-mark window is hidden when no action is available")
    for _, button in ipairs(buffs.buttons) do equal(button.attributes.type1, nil, "chat-only state releases stale secure actions") end
    Suite.db.missingBuffSelf, Suite.db.missingBuffClass = showSelf, showClass; buffs:Refresh()
    local absentNotices = NoticeCount("Main-hand"); buffs:Refresh()
    equal(NoticeCount("Main-hand"), absentNotices, "missing selected coating remains quiet while unchanged")
    units.player.class, learned, enchants[0] = "SHAMAN", { 8232 }, {}
    buffs.bookDirty = true; buffs:Refresh()
    equal(Find("self", "imbue") ~= nil, true, "learned weapon buff is offered when selected item is unavailable")
    equal(#buffs.chatEntries, 0, "available learned weapon buff prevents an unavailable-item chat fallback")
    carried = availableOil; buffs.itemsDirty = true; buffs:Refresh()
    coating = Find("coating", "MH")
    equal(coating.item.id, 9001, "restocking restores the selected item action")
    local nativeWeaponInfo = C_Item.GetItemInfoInstant
    C_Item.GetItemInfoInstant = function(id) return id, nil, nil, "INVTYPE_WEAPON", nil, 2, 4 end
    carried = { { id = 9001, name = "Sharpening Stone", class = 0, subclass = 6, family = "sharp", tier = 1 } }
    buffs.itemsDirty = true; buffs:Refresh()
    local incompatibleStone, incompatibleButton = Find("coating", "MH")
    equal(incompatibleStone.item, nil, "a sharp stone cannot become an action for a blunt weapon")
    equal(#incompatibleStone.choices, 0, "incompatible stones are excluded from carried alternatives")
    equal(incompatibleButton, nil, "an incompatible carried stone does not create a placeholder")
    C_Item.GetItemInfoInstant = nativeWeaponInfo; carried = availableOil
    buffs.itemsDirty = true; buffs:Refresh(); coating = Find("coating", "MH")
    Suite.macroDB.entries[1].item = 9002
    equal(extra:CoatingClick(coating), false, "changed macro choice cancels a stale coating action")
    Suite.macroDB.entries[1].item = 9001
    enchantInfo = { hasExpirationTime = true, remainingTimeMs = 10000 }; buffs:Refresh()
    equal(extra:CoatingState(coating), false, "any active temporary coating provides coverage with expiry off")
    units.player.class, learned = "SHAMAN", { 8232 }; buffs.bookDirty = true; buffs:Refresh()
    equal(Find("self", "imbue"), nil, "selected standard coating avoids demanding a conflicting class imbue")
    Suite.db.missingBuffExpiry = true; buffs:Refresh()
    local needed, remaining = extra:CoatingState(coating)
    equal(needed, true, "selected coating warns before expiry")
    equal(remaining, 10, "native enchant milliseconds convert to seconds")
    enchantInfo.remainingTimeMs = secret
    equal(extra:CoatingState(coating), false, "unknown remaining time never implies expiration")
    enchantInfo = secret; equal(extra:CoatingState(coating), nil, "restricted enchant records do not imply missing coating")
    enchantInfo = nil; weapons[16] = 51
    equal(extra:CoatingClick(coating), false, "weapon swap invalidates a stale coating action")
    weapons[16] = 50
    Suite.db.missingBuffCombat = true; units.player.class = "WARRIOR"; learned = { 6673 }; buffs.bookDirty = true
    auras.player, auras.party1 = {}, {}; buffs:Refresh()
    equal(extra.combatFrame.parent, UIParent, "passive combat panel has an independent ordinary parent")
    equal(extra.combatFrame.protected, false, "combat panel is explicitly independent of protected buttons")
    equal(#extra.combatButtons, 8, "combat icons are prepared once outside combat")
    local combatReads, forbidden = 0, false
    C_Secrets.ShouldSpellAuraBeSecret = function() return forbidden end
    local combatAura
    C_UnitAuras.GetAuraDataBySpellName = function(unit, name, filter)
        assert(InCombatLockdown(), "targeted combat getter is used only in combat")
        combatReads = combatReads + 1; return combatAura
    end
    local framesBefore, bagReadsBefore, spellReadsBefore = made, itemReads, bookReads
    SetCombat(true); buffs.controller:RunState("combat"); buffs.events:OnEvent("PLAYER_REGEN_DISABLED"); Flush()
    equal(extra.combatFrame:IsShown(), true, "native combat entry reveals passive missing-buff reminders")
    equal(extra.combatEntries[1].spell.id, 6673, "selected Battle Shout is combat useful")
    buffs.itemsDirty = true; extra:RefreshCombat()
    local dirtyCoating = false
    for _, item in ipairs(extra.combatEntries) do if item.kind == "coating" then dirtyCoating = true end end
    equal(dirtyCoating, false, "combat inventory changes suppress stale coating availability without a bag scan")
    buffs.itemsDirty = false; extra:RefreshCombat()
    equal(extra.combatButtons[1].attributes.type1, nil, "combat icon has no secure action")
    equal(extra.combatButtons[1].OnClick, nil, "combat icon cannot cast or use items")
    equal(made, framesBefore, "combat reminder updates create no frames")
    equal(itemReads, bagReadsBefore, "combat refresh performs no bag scans")
    equal(bookReads, spellReadsBefore, "combat refresh performs no spellbook discovery")
    equal(buffs.bar:IsShown(), false, "native secure driver keeps click-action bar hidden")
    combatAura = { name = "Battle Shout", spellId = 6673, duration = 120, expirationTime = clock + 16 }
    extra:RefreshCombat(); equal(extra.combatEntries[1].kind, "coating", "covered shout is suppressed while coating can remain missing")
    clock = clock + 2; extra:RefreshCombat()
    equal(extra.combatEntries[1].spell.id, 6673, "short shout warns at its fifteen-second boundary in combat")
    forbidden = true; local priorReads = combatReads; extra:RefreshCombat()
    equal(combatReads, priorReads, "per-spell secrecy blocks targeted aura reads")
    equal(extra.combatEntries[1].kind, "coating", "restricted aura is omitted instead of invented missing")
    forbidden = secret; priorReads = combatReads; extra:RefreshCombat()
    equal(combatReads, priorReads, "secret predicate result fails closed")
    local predicate = C_Secrets.ShouldSpellAuraBeSecret
    C_Secrets.ShouldSpellAuraBeSecret = nil
    C_Secrets.HasSecretRestrictions = function() return true end
    C_Secrets.ShouldAurasBeSecret = function() return false end
    extra:RefreshCombat()
    equal(combatReads, priorReads, "general aura policy cannot substitute for a missing per-spell predicate")
    C_Secrets.ShouldSpellAuraBeSecret = predicate
    forbidden = false; combatAura = secret; extra:RefreshCombat()
    equal(extra.combatEntries[1].kind, "coating", "restricted aura result is omitted")
    combatAura = { name = "Different aura", spellId = 9005 }; extra:RefreshCombat()
    equal(extra.combatEntries[1].kind, "coating", "mismatched targeted aura data is rejected")
    Suite.db.missingBuffWeapons = false; extra:RefreshCombat()
    equal(extra.combatFrame:IsShown(), false, "coating opt-out immediately suppresses cached combat coatings")
    Suite.db.missingBuffWeapons = true
    weapons[16] = 51; extra:RefreshCombat()
    equal(extra.combatFrame:IsShown(), false, "combat weapon swaps suppress old coating matches")
    combatAura = nil; Suite.db.missingBuffCombat = false; extra:Apply()
    equal(extra.combatFrame:IsShown(), false, "combat reminder opt-out hides passive widgets immediately")
    Suite.db.missingBuffCombat = true; extra:OnEvent("UNIT_AURA"); local cancelled = extra.combatTimer
    Suite.db.missingBuffs = false; buffs:Apply(); extra:Apply()
    if cancelled then cancelled.callback() end
    equal(extra.combatFrame:IsShown(), false, "cancelled late combat work cannot revive a disabled panel")
    equal(extra.deadline, nil, "disable cancels expiry deadlines")
    LeaveCombat()
    Suite.db.missingBuffs = true
    Suite.db.missingBuffExpiry, Suite.db.missingBuffCombat, Suite.db.missingBuffWeapons = false, false, false
    units, auras, learned, clock, carried = originalUnits, originalAuras, originalLearned, originalClock, savedCarried
    Suite.macroDB = originalMacroDB
    buffs.notices, buffs.noticeTimes = originalNotices, originalNoticeTimes
    Suite.MacroItems.Scan = function() itemReads = itemReads + 1; return { list = carried } end
    Suite.db.missingBuffSelf, Suite.db.missingBuffOutgoing, Suite.db.missingBuffIncoming, Suite.db.missingBuffClass = unpack(settings)
    buffs.bookDirty, buffs.itemsDirty = true, true; buffs:Apply(); extra:Apply()
end

SlashCmdList.WOWFOREVERSUITE("buffs")
equal(Suite.GUI.page, "buffs", "buff bar has its own slash-accessible settings page")
for index = 1, 8 do
    equal(-Suite.GUI.rows[index].point[3] + Suite.GUI.rows[index].height <= Suite.GUI.content.height - 36, true,
        "buff settings remain within the scrollable content instead of overflowing the footer")
end
buffs:SetPreview(true); equal(buffs.preview:IsShown(), true, "settings can preview placement without actions")
Suite.GUI:Select("overview"); equal(buffs.preview:IsShown(), false, "navigation cancels the non-actionable preview")
buffs:ResetPosition(); equal(next(Suite.db.missingBuffPosition), nil, "bar position reset leaves other saved layouts alone")
equal(buffs.bar.point[1], "TOP", "default missing-buff window uses the top of the screen")
equal(buffs.bar.point[3], "TOP", "default placement stays horizontally centered")
equal(buffs.bar.point[5], -140, "default window clears the top edge near breath and fatigue bars")
Suite.db.missingBuffPosition = { x = 0.1, y = -0.2 }; buffs:Place(buffs.bar)
equal(buffs.bar.point[1], "CENTER", "an existing dragged position overrides the new default")
equal(Suite.db.missingBuffPosition.x, 0.1, "new default does not rewrite customized placement")
buffs:ResetPosition()
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
