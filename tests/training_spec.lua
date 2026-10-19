local Suite, equal, Frame, SetCombat = ...
local training = Suite.Training
local oldDB, oldPending, oldTrainingDB = Suite.db, Suite.pending, training.db
local names = { "CreateFrame", "C_Timer", "C_Trainer", "Enum", "GetNumTrainerServices", "GetTrainerServiceInfo", "GetTrainerServiceCost", "GetMoney", "GetServerTime", "UnitName", "UnitLevel", "BuyTrainerService", "SelectTrainerService", "SetTrainerServiceTypeFilter", "ExpandTrainerSkillLine", "ClassTrainerFrame", "GetTrainerServiceSkillReq", "GetTrainerServiceNumAbilityReq", "GetTrainerServiceAbilityReq", "C_Spell", "GetRealZoneText", "GetSubZoneText", "UnitFactionGroup" }
local old = {}; for _, name in ipairs(names) do old[name] = _G[name] end
SetCombat(false); Suite.db = Suite.InitializeDB(nil); Suite.pending = {}
local secret = setmetatable({ secret = true }, { __lt = function() error("compared trainer secret") end, __le = function() error("compared trainer secret") end, __concat = function() error("formatted trainer secret") end })
local created, scans, money, petType = 0, 0, 600, 0
local trainerName = "Test trainer"
local factionTag = "Alliance"
local timers = {}
C_Timer = { NewTimer = function(delay, callback)
    local timer = { delay = delay, callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
local function Flush()
    local pending = timers; timers = {}
    for _, timer in ipairs(pending) do if not timer.cancelled then timer.callback() end end
end
local function Event(event, ...) training:OnEvent(event, ...); Flush() end
CreateFrame = function(kind, name, parent)
    assert(not InCombatLockdown(), "trainer creates no frames in combat")
    created = created + 1
    local f = Frame(name); f.parent, f.objectType, f.registered = parent, kind, {}
    if parent then
        parent.children[#parent.children + 1] = f
        f.frameLevel = parent:GetFrameLevel() + 1
    end
    f.RegisterEvent = function(self, event) self.registered[event] = true end
    f.UnregisterAllEvents = function(self) self.registered = {} end
    f.Show = function(self) self.shown = true end
    f.Hide = function(self) self.shown = false; if self.OnHide then self:OnHide() end end
    f.SetPoint = function(self, ...) assert(not InCombatLockdown(), "trainer anchors defer in combat"); self.point = { ... } end
    f.StopMovingOrSizing = function(self) assert(not InCombatLockdown(), "trainer movement defers in combat"); self.stopped = true end
    return f
end
for _, name in ipairs({ "BuyTrainerService", "SelectTrainerService", "SetTrainerServiceTypeFilter", "ExpandTrainerSkillLine" }) do _G[name] = function() error("planner must not mutate native trainer state") end end
Enum = { TrainerType = { General = 0, Tradeskills = 2, Pet = 3 } }; C_Trainer = { GetTrainerType = function() return petType end }
local weaponNames = { [15590] = "Fist Weapons", [2567] = "Thrown", [201] = "Swords" }
local function SpellName(id) return weaponNames[id] or "Weapon proficiency " .. id end
C_Spell = { GetSpellName = SpellName }
UnitFactionGroup = function() return factionTag, "Localized faction" end
GetRealZoneText = function() return "Stormwind City" end
GetSubZoneText = function() return "Trade District" end
GetMoney = function() return money end; GetServerTime = function() return 1800000000 end
local playerLevel = 6
UnitLevel = function() return playerLevel end; UnitName = function() return trainerName end
local offers = {
    { name = "Group", state = "header" }, { name = "Skill A", state = "available", cost = 400, rank = "Rank 2", level = 6 },
    { name = "Skill B", state = "available", cost = 400, level = 6 }, { name = "Next skill", state = "unavailable", cost = 600, level = 8 },
    { name = "Later skill", state = "unavailable", cost = 1000, level = 12 }, { name = "Requires quest", state = "unavailable", cost = 0, level = 4 },
    { name = "Learned", state = "used" },
}
GetNumTrainerServices = function() assert(not InCombatLockdown(), "no trainer scans in combat"); scans = scans + 1; return #offers end
GetTrainerServiceInfo = function(index) local row = offers[index]; return row.name, row.state, 123, row.level, row.rank, "General" end
GetTrainerServiceCost = function(index) return offers[index].cost end
training:InitializeCharacter(nil); training:Apply()
equal(Suite.db.trainingPlanner, false, "training recording defaults off")
equal(training.events, nil, "disabled planner registers no events")
equal(created, 0, "disabled planner builds no frame")
Suite.db.trainingPlanner = true; SetCombat(true); training:Apply()
equal(created, 0, "first combat enable waits for frame construction")
equal(type(Suite.pending.trainingApply), "function", "combat activation has a deferred registration")
SetCombat(false); Suite.pending.trainingApply(); Event("TRAINER_SHOW")
equal(training.frame:IsShown(), true, "readable offers open planner automatically")
local burstScans = scans
for _ = 1, 100 do training:OnEvent("TRAINER_SERVICE_INFO_NAME_UPDATE") end
equal(#timers, 1, "trainer event burst queues one worker")
equal(scans, burstScans, "trainer burst does not scan before the worker")
Flush(); equal(scans, burstScans + 1, "trainer burst performs one snapshot scan")
training:OnEvent("TRAINER_UPDATE"); local cancelledWorker = training.timer
Event("TRAINER_CLOSED"); cancelledWorker.callback()
equal(scans, burstScans + 1, "closing trainer cancels pending and stale callback work")
Event("TRAINER_SHOW")
equal(#training.db.snapshot.rows, 5, "snapshot excludes headers and learned services")
equal(training.db.snapshot.rows[1].rank, "Rank 2", "Forever fifth return supplies the rank")
equal(training.db.snapshot.rows[1].level, 6, "Forever fourth return supplies required level")
equal(training.frame.rows[1].name.text, "Skill A · Rank 2", "planner renders native name and rank")
local groups = training:Groups(training.db.snapshot, 6)
equal(#groups, 4, "groups include available, future levels and other requirements")
equal(groups[2].title, "Level 8", "future levels sort ascending")
equal(groups[3].title, "Level 12", "later requirements keep separate level pages")
equal(groups[4].title, "Other requirements", "nonlevel requirements retain a separate page")
local total, covered, partial = training:Budget(groups[1].rows, money)
equal(total, 800, "available budget sums all available prices")
equal(covered, 2, "individual affordability is distinct from buying everything")
equal(partial, false, "readable costs produce a complete total")
equal(training.frame.total.text, "Group total: 0g 8s 0c", "total uses all offers in the group")
equal(training.frame.funds.text:find("0g 2s 0c", 1, true) ~= nil, true, "budget displays the savings gap")
training.page = 2; training:Refresh(); equal(training.frame.group.text, "Level 8", "future group renders independently")
equal(training.frame.rows[1].name.text, "Next skill", "future page contains its own offerings")
local before = scans; money = 2000; Event("PLAYER_MONEY")
equal(scans, before, "money updates reuse the saved offers instead of scanning")
equal(training.frame.funds.text:find("Savings gap: 0g 0s 0c",1,true) ~= nil, true, "new funds update affordability")
training.frame:Hide(); Event("TRAINER_UPDATE")
equal(training.frame:IsShown(), false, "manual dismissal persists for the current visit")
Event("TRAINER_CLOSED"); equal(training.live, nil, "closing trainer clears live state")
training:Open(); equal(training.frame.context.text:find("Saved offerings",1,true) ~= nil, true, "away view labels saved data")
local saved = training.db.snapshot
local classOffers = offers
Event("TRAINER_CLOSED")
trainerName = "Test weapon master"
offers = { { name = "Fist Weapons", state = "available", cost = 1000, level = 1 }, { name = "Thrown", state = "used", cost = 1000, level = 1 } }
Event("TRAINER_SHOW")
equal(training.db.snapshot, saved, "weapon trainer cannot overwrite recorded class training")
equal(training.db.snapshot.kind, "class", "class snapshots retain an explicit trainer kind")
equal(training.db.weapons[1].kind, "weapons", "weapon visits use a separate typed record")
equal(training.db.weapons[1].faction, "Alliance", "observed weapon visit records its faction")
equal(training.db.weapons[1].place, "Stormwind City · Trade District", "weapon records retain the observed trainer location")
equal(training.db.weapons[1].rows[2].state, "used", "weapon directory can retain visible already-trained proficiencies")
equal(training.view, "weapons", "weapon trainer auto-open selects the separate Weapons tab")
Event("PLAYER_LEVEL_UP", 7)
equal(training.view, "class", "level up always selects class training from a weapon visit")
equal(training.frame.rows[1].name.text, "Skill A · Rank 2", "level-up view cannot show the weapon trainer list")
equal(training.frame.context.text:find("Current visit", 1, true), nil, "class view cannot claim live weapon data as current class offerings")
equal(training.db.snapshot, saved, "level-up refresh at a weapon trainer still preserves class training")
training:SelectView("weapons")
equal(training.frame.rows[1].name.text, "Fist Weapons", "Weapons tab shows its own recorded offerings")
equal(training.frame.rows[2].state.text, "Already trained", "known weapon skills are labeled separately")
equal(training.frame.total.text, "Group total: 0g 10s 0c", "weapon budget excludes already-trained skills")
Event("TRAINER_UPDATE")
equal(#training.db.weapons, 1, "repeated weapon updates replace only the same trainer record")
trainerName = "Second weapon master"; Event("TRAINER_CLOSED"); Event("TRAINER_SHOW")
equal(#training.db.weapons, 2, "different weapon trainers retain separate location and cost lists")
local weaponGroups = training:WeaponGroups()
equal(#weaponGroups, 6, "Alliance sees its four reference weapon masters alongside both own visits")
local wooPing = weaponGroups[3]
equal(wooPing.title, "Woo Ping", "full reference directory starts with the Stormwind weapon master")
equal(wooPing.snapshot.place:find("Weller's Arsenal", 1, true) ~= nil, true, "directory gives the trainer's building and district")
equal(wooPing.rows[6].cost, 10000, "Polearms reference cost is one gold before discounts")
equal(wooPing.rows[6].level, 20, "Polearms reference identifies the level twenty requirement")
equal(wooPing.rows[6].state, "reference", "reference stock never claims present class trainability")
for _, group in ipairs(weaponGroups) do
    equal(group.title == "Archibald" or group.title == "Sayoc" or group.title == "Hanashi" or group.title == "Ansekhwa", false, "Alliance weapon list never recommends Horde cities")
end
factionTag = "Horde"
local hordeGroups = training:WeaponGroups()
equal(#hordeGroups, 4, "Horde list excludes saved Alliance visits and Alliance references")
equal(hordeGroups[1].title, "Sayoc", "Horde reference starts with Orgrimmar")
equal(hordeGroups[4].title, "Archibald", "Horde list includes its Undercity trainer")
for _, group in ipairs(hordeGroups) do equal(group.snapshot.faction, "Horde", "every Horde group belongs to Horde") end
factionTag = secret
local unknownGroups = training:WeaponGroups()
equal(#unknownGroups[1].rows, 0, "restricted player faction never exposes either trainer list")
factionTag = "Neutral"
equal(#training:WeaponGroups()[1].rows, 0, "unselected faction has no cross-faction recommendations")
factionTag = "Alliance"
training.view, training.page = "weapons", 3; training:Refresh()
equal(training.frame.context.text:find("Reference", 1, true) ~= nil, true, "directory view labels reference information")
equal(training.frame.total.text, "Reference base prices", "reference list does not present every weapon as a character budget")
equal(training.frame.funds.text:find("Your class", 1, true) ~= nil, true, "reference view discloses class eligibility instead of inventing availability")

equal(training.db.snapshot, saved, "a second weapon trainer cannot replace class data")
local typedDB = training.db
local reloaded = training:InitializeCharacter(typedDB)
equal(reloaded.snapshot.kind, "class", "class identity survives reload validation")
equal(#reloaded.weapons, 2, "weapon directory survives reload validation")
-- Old weapon records require a known master or an explicit captured faction.
local oldWeapons = {
    { kind = "weapons", trainer = "Sayoc", rows = { { name = "Fist Weapons", state = "available", cost = 1000 } } },
    { kind = "weapons", trainer = "Woo Ping", rows = { { name = "Daggers", state = "available", cost = 1000 } } },
    { kind = "weapons", trainer = "Unidentified old master", rows = { { name = "Thrown", state = "available", cost = 1000 } } },
}
training:InitializeCharacter({ snapshot = saved, weapons = oldWeapons })
local oldAlliance = training:WeaponGroups()
equal(#oldAlliance, 5, "old known Alliance visit appears alongside four Alliance references")
equal(oldAlliance[1].title, "Woo Ping", "old Horde and unidentified visits cannot enter the Alliance list")
equal(#training.db.weapons, 3, "filtering preserves all stored weapon history")
factionTag = "Horde"
local oldHorde = training:WeaponGroups()
equal(#oldHorde, 5, "old known Horde visit appears alongside four Horde references")
equal(oldHorde[1].title, "Sayoc", "old Alliance and unidentified visits cannot enter the Horde list")
factionTag = "Alliance"
Event("TRAINER_CLOSED"); trainerName = "Fresh weapon master"; Event("TRAINER_SHOW")
equal(training.page, 2, "weapon auto-open uses its visible page after opposite-faction history is filtered")
equal(training.frame.group.text, "Fresh weapon master", "filtered auto-open displays the just-recorded weapon trainer")
equal(training.db.weapons[4].faction, "Alliance", "new unknown master captures the current player's faction")
local factionAPI = UnitFactionGroup; UnitFactionGroup = nil
training:SelectView("weapons")
equal(training.frame.status.text:find("faction is unavailable", 1, true) ~= nil, true, "missing faction API renders an empty explanatory view")
equal(training.frame.rows[1]:IsShown(), false, "missing faction API never displays a weapon trainer row")
UnitFactionGroup = factionAPI
training.db = typedDB
local legacyWeapon = { rows = { { name = "Fist Weapons", state = "available", cost = 1000 } } }
local migrated = training:InitializeCharacter({ snapshot = legacyWeapon })
equal(migrated.snapshot, nil, "untyped pre-update offerings cannot enter class level-up data")
equal(migrated.legacy.rows[1].name, "Fist Weapons", "old untyped data is retained separately instead of guessed as class training")
training.db = typedDB
local spellLookup = C_Spell.GetSpellName
C_Spell.GetSpellName = function(id) if id == 201 then return secret end; return SpellName(id) end
trainerName, offers = "Test trainer", classOffers
Event("TRAINER_CLOSED"); Event("TRAINER_SHOW")
equal(training.db.snapshot, saved, "incomplete proficiency names cannot authorize a new class snapshot")
C_Spell.GetSpellName = spellLookup; Event("TRAINER_UPDATE")
equal(training.db.snapshot.kind, "class", "complete readable names recover class recording")
saved = training.db.snapshot
petType = 2; Event("TRAINER_CLOSED"); Event("TRAINER_SHOW")
equal(training.db.snapshot, saved, "profession trainer cannot overwrite class training")
petType = 0; offers = { classOffers[2], { name = "Fist Weapons", state = "available", cost = 1000 } }
Event("TRAINER_CLOSED"); Event("TRAINER_SHOW")
equal(training.db.snapshot, saved, "mixed class and proficiency offerings do not overwrite the class list")
-- Delayed weapon metadata and deferred tab clicks cannot replace a later level notice.
Event("TRAINER_CLOSED"); offers = { { name = "Fist Weapons", state = "available", cost = 900 } }
training:OnEvent("TRAINER_SHOW")
Event("PLAYER_LEVEL_UP", 7)
equal(training.view, "class", "late weapon offerings cannot auto-open over a level-up class view")
equal(training.db.snapshot, saved, "late weapon metadata still cannot overwrite the class snapshot")
SetCombat(true); training:SelectView("weapons")
local oldViewWork = Suite.pending.trainingView
Event("PLAYER_LEVEL_UP", 7)
local classNotice = Suite.pending.trainingLevelUp
SetCombat(false); classNotice(); oldViewWork()
equal(training.view, "class", "stale deferred Weapons tab cannot replace a newer class level-up notice")
SetCombat(true); Event("PLAYER_LEVEL_UP", 7)
local cancelledNotice = Suite.pending.trainingLevelUp
training:SelectView("weapons")
local chosenView = Suite.pending.trainingView
SetCombat(false); chosenView(); cancelledNotice()
equal(training.view, "weapons", "a later deliberate tab choice supersedes an older automatic notice")
trainerName, offers = "Test trainer", classOffers
training.level, training.levelNotice = nil, nil
Event("TRAINER_CLOSED"); Event("TRAINER_SHOW")
saved = training.db.snapshot
petType = 3; Event("TRAINER_SHOW")
equal(training.db.snapshot, saved, "pet training points never overwrite gold snapshots")
equal(training.message:find("points",1,true) ~= nil, true, "pet exclusion is explained")
Event("TRAINER_CLOSED"); petType = secret; Event("TRAINER_SHOW")
equal(training.db.snapshot, saved, "restricted trainer type cannot authorize gold budgeting")
Event("TRAINER_CLOSED"); petType = 0
local originalOffers = offers; offers = {}; training.frame:Hide(); Event("TRAINER_SHOW")
equal(training.frame:IsShown(), false, "initial empty list never opens a stale planner")
equal(training.db.snapshot, saved, "delayed initial data retains saved snapshot")
offers = originalOffers; Event("TRAINER_UPDATE")
equal(training.frame:IsShown(), true, "readable delayed offers complete auto-opening")
offers[2].cost = secret; Event("TRAINER_UPDATE")
equal(training.db.snapshot.partial, true, "restricted costs mark the snapshot partial")
equal(training.db.snapshot.rows[1].cost, nil, "secret costs are never saved")
offers[2].cost = 400; offers[2].rank, offers[2].level = secret, secret; Event("TRAINER_UPDATE")
equal(training.db.snapshot.rows[1].rank, nil, "optional restricted rank is omitted")
equal(training.db.snapshot.rows[1].level, nil, "optional restricted level is omitted")
offers[2].rank, offers[2].level = "Rank 2", 6
offers = {}; Event("TRAINER_UPDATE")
equal(#training.db.snapshot.rows, 0, "readable empty update clears a previously live offer list")
offers = originalOffers; Event("TRAINER_UPDATE")
local beforeFrames, beforeScans = created, scans
SetCombat(true); Event("PLAYER_REGEN_DISABLED"); Event("TRAINER_UPDATE"); training:Open()
equal(scans, beforeScans, "combat trainer events do not scan services")
equal(created, beforeFrames, "combat opens construct no frames")
equal(training.pending, true, "combat retains a refresh request")
SetCombat(false); Event("PLAYER_REGEN_ENABLED")
equal(scans, beforeScans + 1, "combat recovery reads once while still visiting")
Event("TRAINER_CLOSED"); SetCombat(true); Event("TRAINER_UPDATE"); SetCombat(false); before = scans; Event("PLAYER_REGEN_ENABLED")
equal(scans, before, "closed trainer is never rescanned on combat exit")
Suite.pending.trainingOpen = nil
local many = {}; for index = 1, 10 do many[index] = { name = "Skill " .. index, state = "available", cost = 10, level = 6 } end
offers = many; Event("TRAINER_SHOW"); training.offset = 4; training:Refresh()
equal(training.frame.rows[6].name.text, "Skill 10", "scroll reaches every offering")
equal(training.frame.total.text, "Group total: 0g 1s 0c", "group total includes offscreen rows")
local restored = training:InitializeCharacter({ snapshot = training.db.snapshot, position = { x = 0.2, y = -0.1 } })
equal(#restored.snapshot.rows, 10, "saved snapshot validates for reload continuity")
equal(restored.position.y, -0.1, "per-character normalized placement persists")
equal(training:Validate(secret), nil, "restricted saved snapshot is rejected")
equal(training:Validate({ rows = secret }), nil, "restricted saved row table is rejected")
equal(training:Validate({ rows = { { name = secret, state = "available" } } }), nil, "secret names are never serialized")
Suite.db.trainingAuto = false; training.frame:Hide(); Event("TRAINER_SHOW")
equal(training.frame:IsShown(), false, "automatic opening can be disabled independently")
equal(#training.db.snapshot.rows, 10, "auto-open opt-out retains recording")
training:Open(); training.moving = true; SetCombat(true)
Suite.db.trainingPlanner = false; training:Apply(); Event("TRAINER_SHOW")
equal(type(Suite.pending.trainingMove), "function", "disable during combat queues interrupted drag cleanup")
SetCombat(false); Suite.pending.trainingMove(); Suite.pending.trainingMove = nil
equal(training.moving, nil, "interrupted drag cleanup completes even after subscriptions are removed")
equal(next(training.events.registered), nil, "disable removes every planner subscription")
equal(training.live, nil, "late events cannot reactivate a disabled planner")
equal(training.frame:IsShown(), false, "disable hides the companion")
-- Trainer attachment remains Suite-owned; only saved level projections are shown away.
Suite.db.trainingPlanner, Suite.db.trainingAuto, Suite.db.trainingLevelUp = true, true, true
Suite.pending = {}; training.level, training.levelNotice, training.levelWork = nil, nil, nil
training.db.position = { x = -0.1, y = 0.05 }
ClassTrainerFrame = Frame("NativeTrainer")
ClassTrainerFrame:SetSize(400, 500)
ClassTrainerFrame.shown = true
ClassTrainerFrame.IsVisible = function(self) return self.shown end
ClassTrainerFrame.GetRight = function() return 450 end
ClassTrainerFrame.GetLeft = function() return 50 end
ClassTrainerFrame.IsForbidden = function() return false end
local nativePoints, nativeScale = ClassTrainerFrame.point, ClassTrainerFrame.scale
GetTrainerServiceSkillReq = function(index)
    if offers[index].name == "Requires quest" then return "Prerequisite", 1, false end
end
GetTrainerServiceNumAbilityReq = function() return 0 end
GetTrainerServiceAbilityReq = function() error("no ability requirement expected") end
offers = originalOffers; playerLevel = 6
training:Apply(); Event("TRAINER_SHOW")
equal(training.frame.parent, UIParent, "docking preserves the Suite-owned root parent")
equal(training.frame.point[1], "TOPLEFT", "planner docks at its top left")
equal(training.frame.point[2], ClassTrainerFrame, "planner anchors directly to native trainer")
equal(training.frame.point[3], "TOPRIGHT", "planner appears beside trainer's right edge")
equal(training.frame.point[4], 8, "trainer and planner retain a small input gap")
equal(training.frame.OnUpdate, nil, "attachment uses anchors without idle polling")
equal(ClassTrainerFrame.point, nativePoints, "docking never moves the native trainer")
equal(ClassTrainerFrame.scale, nativeScale, "docking preserves native trainer scale")
equal(ClassTrainerFrame.OnShow, nil, "docking does not install native show hooks")
equal(ClassTrainerFrame.OnHide, nil, "docking does not replace native hide behavior")
equal(training.db.position.x, -0.1, "docking preserves standalone saved placement")
training.frame.header:OnDragStart()
equal(training.moving, nil, "docked planner cannot detach through its own header drag")
ClassTrainerFrame.GetRight = function() return 1000 end
ClassTrainerFrame.GetLeft = function() return 800 end
training:Place()
equal(training.frame.point[1], "TOPRIGHT", "planner uses left attachment when the right side cannot fit")
equal(training.frame.point[3], "TOPLEFT", "left attachment remains relative to trainer")
equal(training.frame.point[4], -8, "left attachment preserves the native input gap")
ClassTrainerFrame.GetEffectiveScale = function() return 2 end
ClassTrainerFrame.GetRight = function() return 500 end
ClassTrainerFrame.GetLeft = function() return 400 end
training:Place()
equal(training.frame.point[1], "TOPRIGHT", "side fitting accounts for native trainer scale")
ClassTrainerFrame.GetEffectiveScale = function() return 1 end
ClassTrainerFrame.IsVisible = function() return secret end
training:Place()
equal(training.frame.point[2], UIParent, "unreadable native visibility cannot authorize attachment")
ClassTrainerFrame.IsVisible = function(self) return self.shown end
ClassTrainerFrame.shown = false; Event("TRAINER_CLOSED")
equal(training.frame:IsShown(), false, "native trainer closure dismisses the companion")
training:Open()
equal(training.frame.point[1], "CENTER", "away view returns to standalone anchor")
equal(training.frame.point[2], UIParent, "standalone placement no longer depends on hidden trainer")
equal(training.frame.point[4], -100, "standalone view restores normalized horizontal offset")
training.frame.header:OnDragStart()
equal(training.moving, true, "standalone planner still supports dragging")
training:StopDrag(false)
ClassTrainerFrame.shown = true; SetCombat(true)
local beforeDockPoint, beforeDockFrames = training.frame.point, created
Event("TRAINER_SHOW")
equal(training.frame.point, beforeDockPoint, "combat trainer opening never changes anchors")
equal(created, beforeDockFrames, "combat trainer opening never creates companion widgets")
SetCombat(false); Event("PLAYER_REGEN_ENABLED")
equal(training.frame.point[2], ClassTrainerFrame, "combat recovery attaches the existing companion")
equal(training.db.snapshot.level, 6, "snapshots record the readable player level")
equal(training.db.snapshot.rows[3].otherReady, true, "level-gated skill records known satisfied nonlevel requirements")
equal(training.db.snapshot.rows[5].otherReady, false, "known missing nonlevel requirement stays explicit")
ClassTrainerFrame.shown = false; Event("TRAINER_CLOSED")
Suite.db.trainingAuto = false
local scansBeforeLevels = scans
training.page, training.offset = 3, 4
Event("PLAYER_LEVEL_UP", 8)
equal(training.frame:IsShown(), true, "level event opens independently of trainer auto-open preference")
equal(training.page, 1, "level popup selects Available now")
equal(training.offset, 0, "level popup starts at the top of Available now")
equal(training.frame.group.text, "Available now", "level popup keeps the requested group visible")
equal(training.frame.context.text:find("Level 8", 1, true) ~= nil, true, "popup identifies the new event level")
equal(training.frame.rows[3].name.text, "Next skill", "newly reached saved level appears in Available now")
equal(training.frame.rows[3].state.text, "Level met · confirm at trainer", "saved estimate does not claim freshly confirmed eligibility")
equal(training.frame.total.text, "Group total: 0g 14s 0c", "available estimate includes newly unlocked saved cost")
equal(training:CurrentLevel(), 8, "new event level works before UnitLevel catches up")
equal(scans, scansBeforeLevels, "level popup never scans a closed trainer")
equal(training.db.snapshot.rows[3].state, "unavailable", "projection never rewrites captured native availability")
equal(training.db.snapshot.rows[3].projected, nil, "projection state never enters the saved snapshot")
local projected = training:Groups(training.db.snapshot, 8, true)
equal(#projected[1].rows, 3, "available projection retains only eligible level candidates")
equal(projected[2].title, "Level 12", "unreached future skills remain separate")
equal(projected[3].rows[1].name, "Requires quest", "known missing prerequisite remains under Other requirements")
training.frame:Hide(); Event("PLAYER_MONEY")
equal(training.frame:IsShown(), false, "money changes do not reopen a dismissed level popup")
Event("PLAYER_LEVEL_UP", 9)
equal(training.frame:IsShown(), true, "every later level can open Available now again")
training.frame:Hide(); local beforeSecretLevel = training.level
Event("PLAYER_LEVEL_UP", secret); Event("PLAYER_LEVEL_UP", 0)
equal(training.level, beforeSecretLevel, "restricted and invalid level payloads cannot change projection level")
equal(training.frame:IsShown(), false, "invalid level payload never triggers a popup")
Suite.db.trainingLevelUp = false; Event("PLAYER_LEVEL_UP", 10)
equal(training.frame:IsShown(), false, "level popup can be disabled without disabling recording")
Suite.db.trainingLevelUp = true; SetCombat(true)
local beforeLevelFrames, beforeLevelScans = created, scans
Event("PLAYER_LEVEL_UP", 11)
local earlierLevelOpen = Suite.pending.trainingLevelUp
Event("PLAYER_LEVEL_UP", 12)
equal(training.frame:IsShown(), false, "combat level-up waits before showing the planner")
equal(created, beforeLevelFrames, "combat level-up builds no frames")
equal(scans, beforeLevelScans, "combat level-up scans no trainer services")
SetCombat(false); earlierLevelOpen()
equal(training.frame:IsShown(), false, "superseded level-up callback cannot open stale notice")
local latestLevelOpen = Suite.pending.trainingLevelUp; Suite.pending.trainingLevelUp = nil; latestLevelOpen()
equal(training.frame:IsShown(), true, "combat-deferred level notice opens after combat")
equal(training.frame.context.text:find("Level 12", 1, true) ~= nil, true, "coalesced level notice uses the latest level")
equal(training.frame.rows[4].name.text, "Later skill", "later level unlock joins the available budget")
training.frame:Hide(); SetCombat(true); Event("PLAYER_LEVEL_UP", 13)
local cancelledLevelOpen = Suite.pending.trainingLevelUp
Suite.db.trainingLevelUp = false
SetCombat(false); training:Apply(); cancelledLevelOpen()
equal(training.frame:IsShown(), false, "turning off level notices cancels an already deferred open")
equal(Suite.pending.trainingLevelUp, nil, "disabled level notices retain no automatic open callback")
Suite.db.trainingLevelUp = true; SetCombat(true); Event("PLAYER_LEVEL_UP", 14)
local disabledLevelOpen = Suite.pending.trainingLevelUp
Suite.db.trainingPlanner = false; training:Apply(); SetCombat(false); disabledLevelOpen()
equal(training.frame:IsShown(), false, "disabling planner invalidates a deferred level popup")
equal(training.levelWork, nil, "disable clears the level work token")
Suite.db.trainingPlanner = true; training:Apply()
training.db.snapshot = nil; Event("PLAYER_LEVEL_UP", 15)
equal(training.frame:IsShown(), true, "each level opens a clear view even before a trainer is recorded")
equal(training.frame.group.text, "Available now", "empty history still starts at Available now")
equal(training.frame.rows[1]:IsShown(), false, "empty history never invents trainable skills")
equal(training.frame.status.text:find("Visit your class trainer", 1, true) ~= nil, true, "empty history explains how to populate the planner")
training.frame:Hide(); SetCombat(true); Event("PLAYER_LEVEL_UP", 16)
local worldLevelOpen = Suite.pending.trainingLevelUp
Event("PLAYER_ENTERING_WORLD"); SetCombat(false); worldLevelOpen()
equal(training.frame:IsShown(), false, "world transition cancels an obsolete level notice")
equal(training.level, nil, "world entry clears transient level override")
local validated = training:Validate({ level = secret, rows = { { name = "Saved", state = "unavailable", level = 20, cost = 10, otherReady = secret } } })
equal(validated.level, nil, "restricted saved capture level is not serialized")
equal(validated.rows[1].otherReady, nil, "restricted saved prerequisite state stays unknown")
-- Legacy snapshots remain useful without pretending they contained prerequisite checks.
training.levelNotice = 20
local legacy = training:Validate({ rows = { { name = "Legacy next", state = "unavailable", level = 20, cost = 50 } } })
equal(#training:Groups(legacy, 20, true)[1].rows, 1, "legacy snapshot can show the exact newly reached level as an estimate")
equal(training:Groups(legacy, 20, true)[1].rows[1].projected, true, "legacy estimate remains explicitly unconfirmed")
training.levelNotice = nil
equal(#training:Groups(legacy, 20, true)[1].rows, 0, "legacy rows with no capture level do not become confirmed available")
local knownBlocked = training:Validate({ level = 6, rows = { { name = "Prerequisite skill", state = "unavailable", level = 8, cost = 50, otherReady = false } } })
equal(#training:Groups(knownBlocked, 20, true)[1].rows, 0, "a reached level cannot bypass an explicitly missing nonlevel prerequisite")
GetTrainerServiceSkillReq = function() return nil end
GetTrainerServiceNumAbilityReq = function() return 1 end
GetTrainerServiceAbilityReq = function() return "Previous rank", false end
equal(training:OtherRequirements(1), false, "native ability prerequisite failure is recorded")
GetTrainerServiceAbilityReq = function() return "Previous rank", secret end
equal(training:OtherRequirements(1), nil, "restricted ability eligibility remains unknown")
GetTrainerServiceAbilityReq = function() return "Previous rank", true end
equal(training:OtherRequirements(1), true, "readable native ability requirements can be satisfied")
GetTrainerServiceNumAbilityReq = function() return secret end
equal(training:OtherRequirements(1), nil, "restricted requirement counts never drive a loop")
GetTrainerServiceSkillReq = function() return "Profession", 100, false end
GetTrainerServiceNumAbilityReq = function() return 0 end
equal(training:OtherRequirements(1), false, "native profession prerequisite failure is recorded")
SetCombat(true); training:LevelUp(21)
local supersededNotice = Suite.pending.trainingLevelUp
training:Open()
equal(Suite.pending.trainingLevelUp, nil, "later manual open replaces a queued automatic level notice")
SetCombat(false); supersededNotice()
equal(training.frame:IsShown(), false, "superseded automatic callback cannot override manual intent")
Suite.pending.trainingOpen = nil
Suite.db.trainingPlanner = false; training:Apply()
training.level, training.levelNotice, training.levelWork, training.docked = nil, nil, nil, nil
Suite.db, Suite.pending, training.db = oldDB, oldPending, oldTrainingDB
for _, name in ipairs(names) do _G[name] = old[name] end
SetCombat(false)
