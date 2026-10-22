-- Real character state, scoring, hint, tooltip and editor paths; no game compatibility claim.
local Suite, equal, Frame, Combat, events = ...
local scoring, gear, gui = Suite.Scoring, Suite.GearSettings, Suite.GUI
local saved = { db = Suite.db, character = scoring.character, owner = scoring.owner, class = scoring.class,
    automatic = scoring.automaticProfile, automaticClass = scoring.automaticClass, api = C_Item,
    playerInfo = C_PlayerInfo, unitClass = UnitClass, level = UnitLevel, inventory = GetInventoryItemLink,
    dual = CanDualWield, page = gui.page, shown = gui.frame:IsShown(), pending = Suite.pending }
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
UnitClass = function() return "Hunter", "HUNTER" end
scoring.class, scoring.automaticProfile = nil, nil
local state = scoring:InitializeCharacter(nil)
equal(state.active, "automatic", "fresh character needs no weight editing")
equal(state.preference, "stats", "fresh comparison uses useful stat scoring")
equal(#state.profiles, 0, "built-ins do not consume custom profile slots")
equal(scoring:Profile().rangedDPS, 7, "automatic Hunter starter values ranged DPS")
equal(scoring:Profile().meleeDPS, 0, "automatic Hunter starter does not mistake a melee DPS stick for a ranged upgrade")
equal(scoring:Profile(), scoring:Profile(), "automatic profiles reuse their resolved data between item updates")
for _, class in ipairs({ "MAGE", "WARLOCK", "PRIEST", "ROGUE", "WARRIOR", "DRUID", "PALADIN", "SHAMAN" }) do
    scoring.class, scoring.automaticProfile = class, nil
    local profile = scoring:Profile()
    equal(profile ~= nil and profile.weights.STAMINA > 0, true, class .. " has a complete ready-to-use starter")
    if class == "ROGUE" or class == "WARRIOR" then equal(profile.rangedDPS, 0, class .. " does not prioritize ranged weapon DPS") end
end
scoring.class, scoring.automaticProfile = "MAGE", nil
state = scoring:InitializeCharacter(nil, { scorePreset = "healer", upgradePreference = "ilevel" })
equal(state.active, "healer", "existing role choice migrates to this character")
equal(scoring.Preference(Suite.db), "ilevel", "existing comparison mode migrates with the profile")
scoring:SetPreference("stats"); scoring:SetProfile("caster")
equal(Suite.db.scorePreset, "balanced", "character profile selection leaves legacy account defaults alone")
equal(Suite.db.upgradePreference, "stats", "character comparison mode does not overwrite account defaults")
local hidden = setmetatable({ secret = true }, { __index = function() error("restricted profile indexed") end })
state = scoring:InitializeCharacter(hidden)
equal(state.active, "automatic", "restricted character settings reset before access")
state = scoring:InitializeCharacter({ schema = hidden, active = hidden, profiles = hidden, preference = hidden, details = hidden })
equal(state.active, "automatic", "restricted nested state cannot become a profile key")
equal(state.details, false, "restricted detail choice cannot authorize a full report")
state = scoring:InitializeCharacter({ schema = 1, active = "custom999", profiles = { hidden } })
equal(state.active, "automatic", "missing or invalid saved profile falls back to a useful starter")

local function Custom(label, intellect)
    return { label = label, weights = { INTELLECT = intellect or 2, STAMINA = 0.5 }, meleeDPS = 0, rangedDPS = 0 }
end
local profile = Custom("My casting")
local id = scoring:SaveProfile(profile)
equal(id, "custom1", "custom profile receives a stable character-local identity")
profile.weights.INTELLECT = 999
equal(scoring:Profile().weights.INTELLECT, 2, "saved profile does not alias the editing table")
equal(scoring.presets.caster.weights.INTELLECT, 1, "editing never changes the built-in preset")
equal(scoring.Score({ ITEM_MOD_INTELLECT_SHORT = 5 }, scoring:Profile()), 10, "custom weights drive actual scores")
equal(scoring:SaveProfile(Custom("MY CASTING")), nil, "duplicate profile names are rejected case-insensitively")
equal(scoring:SaveProfile(Custom("Caster")), nil, "custom names cannot impersonate built-in presets")
equal(scoring:SaveProfile(Custom("Unsafe|cffff0000")), nil, "chat markup cannot enter profile labels")
equal(scoring:SaveProfile(Custom("bad", -1)), nil, "negative weights are rejected")
equal(scoring:SaveProfile(Custom("bad", math.huge)), nil, "infinite weights are rejected")
equal(scoring:SaveProfile(Custom("bad", 1001)), nil, "extreme weights have a bounded input range")
equal(scoring:SaveProfile(Custom("bad", hidden)), nil, "secret weights cannot enter saved preferences")
equal(scoring:SaveProfile({ label = "Zero", weights = {}, meleeDPS = 0, rangedDPS = 0 }), nil, "all-zero profiles cannot silently suppress every stat comparison")
equal(scoring:SaveProfile(Custom("Bad overwrite"), "caster"), nil, "built-in overwrite is rejected at the data boundary")
local restored = scoring:InitializeCharacter(Suite.Copy(state))
equal(restored.active, id, "active custom identity survives reload sanitization")
equal(scoring:Profile().weights.INTELLECT, 2, "custom numeric weights survive reload")
local firstState = restored
scoring:InitializeCharacter(nil)
equal(scoring:ActiveID(), "automatic", "an alt starts with its own class preset")
equal(#scoring:State().profiles, 0, "custom weights do not spill into another character")
scoring:InitializeCharacter(firstState)
for index = 2, 8 do equal(scoring:SaveProfile(Custom("Profile " .. index)) ~= nil, true, "custom profile capacity remains bounded") end
equal(scoring:SaveProfile(Custom("Ninth profile")), nil, "ninth custom profile is refused without overwriting saved weights")
equal(scoring:DeleteProfile("caster"), false, "built-ins cannot be deleted")
scoring:SetProfile(id)
equal(scoring:DeleteProfile(id), true, "custom profiles can be removed deliberately")
equal(scoring:ActiveID(), "automatic", "deleting the active custom falls back to Automatic")

-- Independent initialization must never inherit the live character's mode implicitly.
scoring:SetPreference("ilevel")
equal(Suite.InitializeDB({ upgradePreference = "stats" }).upgradePreference, "stats", "account initialization reads its own migration value")
scoring:SetPreference("stats")
local serialState = scoring:InitializeCharacter({ schema = 1, active = "automatic", nextID = 42, profiles = {} })
equal(scoring:SaveProfile(Custom("Stable identity")), "custom42", "reload does not recycle deleted custom identities")
equal(serialState.nextID, 43, "custom serial advances after restoring an empty profile list")
equal(scoring.WeaponScore({ equipLoc = "INVTYPE_WEAPON" }, { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = hidden }, "caster", "stats", 16), 0,
    "unweighted unreadable DPS is unnecessary for a caster stat-stick comparison")
local invalidProfile = { label = "Invalid", weights = {}, meleeDPS = hidden, rangedDPS = 1 }
equal(scoring.WeaponScore({ equipLoc = "INVTYPE_WEAPON" }, {}, invalidProfile, "stats", 16), nil,
    "restricted DPS weights are rejected before arithmetic")

-- Stat gains, losses and the correct replacement must explain the same + shown on real icons.
local equipment, records = {}, {
    old = { loc = "INVTYPE_HEAD", level = 20, stats = { ITEM_MOD_INTELLECT_SHORT = 5, ITEM_MOD_STAMINA_SHORT = 8 } },
    new = { loc = "INVTYPE_HEAD", level = 18, stats = { ITEM_MOD_INTELLECT_SHORT = 10, ITEM_MOD_STAMINA_SHORT = 4 } },
    ring1 = { loc = "INVTYPE_FINGER", level = 20, stats = { ITEM_MOD_INTELLECT_SHORT = 10 } },
    ring2 = { loc = "INVTYPE_FINGER", level = 20, stats = { ITEM_MOD_INTELLECT_SHORT = 2 } },
    ring = { loc = "INVTYPE_FINGER", level = 20, stats = { ITEM_MOD_INTELLECT_SHORT = 5 } },
    main = { loc = "INVTYPE_WEAPONMAINHAND", level = 20, stats = { ITEM_MOD_INTELLECT_SHORT = 4, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 10 } },
    off = { loc = "INVTYPE_WEAPONOFFHAND", level = 20, stats = { ITEM_MOD_INTELLECT_SHORT = 3, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 6 } },
    staff = { loc = "INVTYPE_2HWEAPON", level = 25, stats = { ITEM_MOD_INTELLECT_SHORT = 10, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 20 } },
}
C_Item = {
    GetItemInfo = function(link) local r = records[link]; if r then return link, link, 2, r.level, 1, "Armor", "", 1, r.loc, 1, 0, 4, 1 end end,
    GetDetailedItemLevelInfo = function(link) return records[link] and records[link].level end,
    IsUsableItem = function() return true end,
    GetItemStats = function(link) return records[link] and records[link].stats end,
}
C_PlayerInfo = nil
UnitLevel = function() return 60 end
GetInventoryItemLink = function(_, slot) return equipment[slot] end
CanDualWield = function() return true end
state = scoring:InitializeCharacter(nil)
id = scoring:SaveProfile(Custom("Detailed caster"))
Suite.db.upgradeHints = true
equipment[1] = "old"
local delta, comparison = Suite.Items:UpgradeDelta("new", true)
equal(delta, 8, "actual custom gain accounts for both intellect gain and stamina loss")
equal(comparison.baselineScore, 14, "report preserves the exact equipped score")
equal(comparison.candidateScore, 22, "report preserves the exact candidate score")
equal(comparison.replacementSlot, 1, "report identifies the actual replaced slot")
equal(comparison.profile, "Detailed caster", "report names the effective character profile")
local sum = 0; for _, row in ipairs(comparison.breakdown) do sum = sum + row.points end
equal(sum, delta, "displayed contribution changes reconcile with the marker's gain")
equal(comparison.breakdown[1].points, 10, "largest contribution is first")
equal(comparison.breakdown[2].points, -2, "negative tradeoffs remain visible")
local tip = Frame(); Suite.Tooltips:Item(tip, { hyperlink = "new" })
equal(tip.lines[1][1], "Possible stat upgrade · +8.0 (Detailed caster)", "tooltip uses the same character weights as icons")
equal(tip.lines[2][1], "Not your preferred armor type (Mail preferred).", "armor explanation preserves the full custom comparison below it")
equal(tip.lines[3][1], "Score · equipped -> candidate", "score label uses a font-safe comparison separator")
equal(tip.lines[3][2], "14.0 -> 22.0", "tooltip shows exact equipped/candidate basis")
state.details = true
tip = Frame(); Suite.Tooltips:Item(tip, { hyperlink = "new" })
equal(tip.lines[4][2], "old", "full detail names the item being replaced")
equal(tip.lines[5][1], "Intellect +5.0 x 2", "full detail exposes the actual weight multiplication")
local button, buttonRecord = Frame(), {}; button.GetItemLink = function() return "new" end
Suite.Items:Update(button, buttonRecord)
equal(buttonRecord.arrow.text, "+", "custom improvements appear through the real item icon renderer")
equipment[11], equipment[12] = "ring1", "ring2"
delta, comparison = Suite.Items:UpgradeDelta("ring", true)
equal(comparison.replacementSlot, 12, "paired accessories name the weaker replaceable slot")
equal(comparison.replacementLink, "ring2", "paired accessory explanation does not point at the stronger item")
equipment[16], equipment[17] = "main", "off"
scoring:SetProfile("physical")
delta, comparison = Suite.Items:UpgradeDelta("staff", true)
sum = 0; for _, row in ipairs(comparison.breakdown) do sum = sum + row.points end
equal(sum, delta, "two-hander breakdown reconciles against both occupied hands")
equal(comparison.baselineScore, 91, "full hand set includes half-weight off-hand DPS")
equal(comparison.candidateScore, 140, "two-hander DPS is counted once")
equal(Suite.Scoring.Format(0.002, true), "+0.002", "small gains are never displayed as +0.0")
equal(Suite.Scoring.Format(100.002), "100.002", "score totals retain small changes on a large baseline")
equal(Suite.Scoring.Format(8.333, true), "+8.333", "ordinary weighted deltas retain fractional precision")
equal(Suite.Scoring.Format(-0.00001, true), "-0.00001", "small negative tradeoffs are not rounded into zero")
scoring:SetProfile(id)
records.old.stats = hidden
equal(Suite.Items:UpgradeDelta("new", true), nil, "unreadable equipped stats suppress partial explanations and markers together")
equipment[1] = hidden
equal(Suite.Items:UpgradeDelta("new", true), nil, "restricted equipment is never explained as an empty slot")
equipment[1], records.old.stats = "old", { ITEM_MOD_INTELLECT_SHORT = 5, ITEM_MOD_STAMINA_SHORT = 8 }

-- Draft UX must be transactional; selection and geometry are guarded through combat/navigation.
gui.frame:Show(); gui:Select("items"); gear:Open("editor")
equal(gear.copyButton.enabled, true, "custom editing is optional and available through an explicit copy")
gear:Edit(); gear.nameInput:SetText("Renamed caster")
for _, field in ipairs(gear.fields) do if field.key == "INTELLECT" then field.input:SetText("3.25") end end
equal(scoring:Profile().weights.INTELLECT, 2, "typing a draft never changes active comparisons")
gear.detailsButton.OnClick()
equal(gear.nameInput:GetText(), "Renamed caster", "changing tooltip detail does not erase a draft name")
local intellectField; for _, field in ipairs(gear.fields) do if field.key == "INTELLECT" then intellectField = field end end
equal(intellectField.input:GetText(), "3.25", "refreshing editor options preserves typed unsaved weights")
equal(gear:Choose("healer"), false, "profile selection cannot silently discard edits")
intellectField.input:SetText("-1")
equal(gear:Save(), false, "invalid numeric input blocks Save")
equal(scoring:Profile().weights.INTELLECT, 2, "invalid Save leaves the complete saved profile intact")
intellectField.input:SetText("3.25")
equal(gear:Save(), true, "explicit Save validates and applies the entire draft")
equal(scoring:Profile().weights.INTELLECT, 3.25, "saved weights immediately become active")
gear:Edit(); intellectField.input:SetText("7")
gear:Cancel()
equal(scoring:Profile().weights.INTELLECT, 3.25, "Cancel preserves the saved weights")
gear:Edit(); intellectField.input:SetText("7")
gui:Select("overview")
equal(gear.draft, nil, "leaving the page discards unsaved edits")
equal(scoring:Profile().weights.INTELLECT, 3.25, "navigation never commits unfinished input")
gui:Select("items"); gear:Open("editor"); gear:Edit(); intellectField.input:SetText("7")
Combat(true)
gear:Save(); gear:Choose("tank")
equal(scoring:Profile().weights.INTELLECT, 3.25, "combat cannot commit editor actions")
local priorHeight = gear.panel.height
gear:Refresh()
equal(gear.panel.height, priorHeight, "combat refresh does not resize the settings panel")
equal(type(Suite.pending.gearSettings), "function", "combat presentation is coalesced")
gear:Dismiss()
equal(Suite.pending.gearSettings, nil, "closing cancels delayed editor presentation")
Combat(false)
equal(scoring:Profile().weights.INTELLECT, 3.25, "combat-cancelled drafts cannot reappear or commit later")
gui:Select("items"); gear:Open("picker")
equal(gear:Choose("automatic"), true, "Automatic is always one deliberate selection away")
equal(#scoring:State().profiles, 1, "switching back to built-ins preserves the custom profile")
equal(Suite.SettingsCatalog:Search("custom stat weights")[1].key, "weights", "custom comparisons are discoverable through settings search")
gear:Open("editor")
equal(gear.panel.height, 586, "advanced editor reserves the entire footer and status area")
equal(gui.contentHeight >= gui.controlsOffset + gear.panel.height + 36, true, "every editor control can scroll above the fixed settings footer")
for _, field in ipairs(gear.fields) do
    local _, x, y = field.input:GetPoint()
    equal(x >= 0 and x + field.input:GetWidth() <= 780, true, "weight inputs stay within the three-column content width")
    equal(-y + field.input:GetHeight() < 456, true, "weight inputs cannot overlap the tooltip and save controls")
end
gear:Dismiss()

-- Exercise the actual SavedVariables startup integration, including the macro-owned root replacement.
local globals = { account = WoWForeverSuiteDB, character = WoWForeverSuiteCharDB,
    leveling = Suite.Leveling.db, training = Suite.Training.db, macros = Suite.macroDB,
    loaded = Suite.loadedSavedVariables }
local beforeAccount, beforeCharacter, beforeOwner = Suite.db, scoring.character, scoring.owner
WoWForeverSuiteDB = { scorePreset = "healer", upgradePreference = "ilevel" }
WoWForeverSuiteCharDB = nil
events.OnEvent(events, "ADDON_LOADED", "WoWForeverSuite")
equal(WoWForeverSuiteCharDB.scoring.active, "automatic", "a new character receives the automatic starter even on an existing account")
equal(WoWForeverSuiteCharDB.scoring.preference, "stats", "a new character gets useful scoring without inheriting another character's level-only choice")
WoWForeverSuiteCharDB = { schema = 2, entries = {} }
events.OnEvent(events, "ADDON_LOADED", "WoWForeverSuite")
equal(WoWForeverSuiteCharDB.scoring.active, "healer", "an existing character retains its legacy role on first migration")
equal(WoWForeverSuiteCharDB.scoring.preference, "ilevel", "legacy comparison preference survives actual startup")
local rootProfile = WoWForeverSuiteCharDB.scoring
scoring:SetProfile("caster")
equal(rootProfile.active, "caster", "runtime profile changes remain attached to the saved character root")
equal(WoWForeverSuiteCharDB.training ~= nil and WoWForeverSuiteCharDB.leveling ~= nil, true, "profile integration preserves existing tracker/trainer roots")
WoWForeverSuiteDB, WoWForeverSuiteCharDB = globals.account, globals.character
Suite.Leveling.db, Suite.Training.db, Suite.macroDB = globals.leveling, globals.training, globals.macros
Suite.loadedSavedVariables, Suite.db = globals.loaded, beforeAccount
scoring.character, scoring.owner = beforeCharacter, beforeOwner

C_Item, C_PlayerInfo, UnitClass, UnitLevel, GetInventoryItemLink, CanDualWield = saved.api, saved.playerInfo, saved.unitClass, saved.level, saved.inventory, saved.dual
Suite.db, Suite.pending = saved.db, saved.pending
scoring.character, scoring.owner, scoring.class = saved.character, saved.owner, saved.class
scoring.automaticProfile, scoring.automaticClass = saved.automatic, saved.automaticClass
gui:Select(saved.page or "overview"); gui.frame:SetShown(saved.shown)
