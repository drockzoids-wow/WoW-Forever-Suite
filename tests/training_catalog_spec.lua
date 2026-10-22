local Suite, equal, Frame, Combat = ...
local catalog, training = Suite.TrainingCatalog, Suite.Training
local oldClass, oldRace, oldFaction, oldBook, oldSpell, oldLevel, oldMoney = UnitClass, UnitRace, UnitFactionGroup, C_SpellBook, C_Spell, UnitLevel, GetMoney
local token, race, faction, learned = "WARRIOR", 1, "Alliance", {}
UnitClass = function() return token, token end
UnitRace = function() return "Human", "Human", race end
UnitFactionGroup = function() return faction end
UnitLevel = function() return 1 end
GetMoney = function() return 10000 end
C_SpellBook = { IsSpellKnown = function(id) return learned[id] == true end }
C_Spell = { GetSpellName = function() end, GetSpellSubtext = function() end, GetSpellTexture = function() return 134400 end }
local function Find(snapshot, id)
    for _, row in ipairs(snapshot.rows) do if row.spellID == id then return row end end
end
local total = 0
for class, entries in pairs(Suite.TrainingCatalogData) do
    token = class
    local snapshot = catalog:Snapshot(nil, 1)
    equal(snapshot.catalog, true, class .. " has a default catalog without saved visits")
    local seen, level60 = {}, false
    for _, row in ipairs(snapshot.rows) do
        equal(type(row.name), "string", "offline spell name")
        equal(type(row.cost), "number", "default copper cost")
        equal(row.level >= 1 and row.level <= 60, true, "catalog stays within 1–60")
        equal(seen[row.spellID], nil, "no duplicate ranks")
        seen[row.spellID] = true
        if row.level == 60 then level60 = true end
    end
    equal(level60, true, class .. " includes level 60")
    total = total + #entries
end
equal(total, 1409, "all pinned class and pet training ranks imported")
token = "WARRIOR"
local initial = catalog:Snapshot(nil, 1)
equal(Find(initial, 6673).cost, 10, "level-one Battle Shout base cost")
equal(Find(initial, 1240193) ~= nil, true, "Forever-specific low-rank Slam included")
equal(Find(initial, 11574).level, 60, "Rend rank seven visible immediately")
local saved = { trainer = "Test trainer", rows = { { name = "Battle Shout", rank = "Rank 1", level = 1, cost = 9, state = "available" },
    { name = "New server offering", level = 60, cost = 123, state = "unavailable" } } }
local base, recorded = catalog:Snapshot(saved, 1), catalog:Snapshot(saved, 1, true)
equal(Find(base, 6673).cost, 10, "recorded discounts never overwrite base cost")
equal(Find(recorded, 6673).cost, 9, "recorded mode uses observed discount")
equal(Find(recorded, 11574).cost, Find(initial, 11574).cost, "visit keeps unobserved level-60 ranks")
equal(#recorded.rows, #initial.rows + 1, "new server offerings extend catalog")
equal(saved.rows[1].cost, 9, "browsing never mutates saved observations")
local passive=catalog:Snapshot({rows={{name="Parry",state="available",level=6,cost=90}}},6,true)
equal(#passive.rows,#initial.rows,"a rankless passive visit does not duplicate the catalog entry")
equal(Find(passive,3127).cost,90,"rankless passive matches its unique catalog skill")
local unknown
for _, row in ipairs(base.rows) do if row.name == "New server offering" then unknown = row end end
equal(unknown.cost, nil, "unknown base prices are not inferred from discounted observations")
local groups = catalog:Groups(initial, 1)
equal(groups[1].title, "Ready to review", "initial review group")
local all = 0; for _, group in ipairs(groups) do all = all + #group.rows end
equal(all, #initial.rows, "paging includes every rank exactly once")
learned[11574] = true
local known = catalog:Snapshot(nil, 60)
equal(Find(known, 772).state, "used", "highest learned rank implies replaced earlier ranks")
equal(Find(known, 11574).state, "used", "known rank shown separately")
equal(Find(known, 23894).requirement, "Requires talent", "talent upgrade requirements retained")
token, race, faction = "PRIEST", 1, "Alliance"
equal(Find(catalog:Snapshot(nil,1),19275) ~= nil,true,"human priest racial retained")
race=3
equal(Find(catalog:Snapshot(nil,1),19275),nil,"other priest racials filtered")
token, faction = "MAGE", "Horde"
equal(Find(catalog:Snapshot(nil,1),3561),nil,"enemy-faction teleports filtered")
equal(Find(catalog:Snapshot(nil,1),3563) ~= nil,true,"own-faction teleport retained")
token = "ROGUE"
local poison = Find(catalog:Snapshot(nil,60),5763)
equal(poison.requirement,"Skill requirement","poison skill requirements disclosed")
equal(table.concat(catalog:Details(poison),' '):find('Poisons: 100',1,true) ~= nil,true,"exact poison threshold in details")
token = "HUNTER"
equal(Find(catalog:Snapshot(nil,60),4187).requirement,"Pet trainer","pet training distinct from player training")
token,faction,race,learned = "WARRIOR","Alliance",1,{}
training:InitializeCharacter({ weapons = {} })
local weapons = catalog:WeaponGroups(training)
equal(#weapons,4,"all Alliance master references available without visits")
equal(catalog:WeaponState(201),"Class eligible","warrior sword eligibility")
learned[201] = true
equal(catalog:WeaponState(201),"Already trained","known proficiency marked")
token = "MAGE"
equal(catalog:WeaponState(196),"Not for your class","ineligible weapon disclosed")
token = "ROGUE"
equal(catalog:WeaponState(196),"Class eligible","Forever rogue axe eligibility")
token = "SHAMAN"
equal(catalog:WeaponState(197),"Class eligible","Forever shaman two-handed axe eligibility")
token = "WARRIOR"
training.db.weapons = { {kind="weapons",trainer="Woo Ping",faction="Alliance",rows={{name="One-Handed Swords",cost=900,state="available",level=1}}} }
local merged=catalog:WeaponGroups(training,true)
equal(#merged[1].rows,6,"partial weapon visit preserves all default offerings")
local sword
for _, row in ipairs(merged[1].rows) do if row.weaponID==201 then sword=row end end
equal(sword.cost,900,"weapon recorded price mode")
equal(sword.baseCost,1000,"weapon base cost retained")
-- The window remains usable with recording off and no spell metadata cached.
training:InitializeCharacter(nil); training.view="class"; training.level=nil; training.recordedCosts=nil
Suite.db.trainingPlanner=false
Combat(false)
equal(training:Build(),true,"planner builds while recording disabled")
training.frame:Show(); training:Refresh()
equal(training.frame.context.text,"Built-in catalog · Levels 1–60","default window explains catalog")
equal(training.frame.rows[1].data.spellID,6673,"new character can review first skill")
if WFS_JOURNAL_PREVIEW then
    local frame, rows = training.frame, {}
    for _, widget in ipairs(frame.rows) do if widget.data then rows[#rows + 1] = {
        name = widget.name.text, state = widget.state.text, cost = widget.cost.text } end end
    WFS_JOURNAL_PREVIEW({ view = "training", context = frame.context.text, status = frame.status.text,
        group = frame.group.text, rows = rows, total = frame.total.text, funds = frame.funds.text,
        covered = frame.covered.text, page = frame.pageText.text })
end
training.frame.next:GetScript("OnClick")();equal(training.offset,6,"all-level Next advances six rows")
training.frame.previous:GetScript("OnClick")();equal(training.offset,0,"all-level Previous returns six rows")
training.offset=10000;training:Refresh();equal(training.offset,96,"last all-level page remains aligned")
equal(training.frame.pageText.text,"17 / 17","last page counter")
training.frame.levels:GetScript("OnClick")();equal(training.allLevels,false,"switch to grouped level view")
equal(training.frame.group.text,"Ready to review","grouped review page")
training.frame.next:GetScript("OnClick")();equal(training.page,2,"grouped Next selects next level")
training.frame.levels:GetScript("OnClick")();equal(training.allLevels,true,"return to all-level view")
training.frame.prices:GetScript("OnClick")(); equal(training.recordedCosts,true,"price switch works")
training.view="weapons"; training:Refresh()
equal(training.frame.rows[1].data.weaponID ~= nil,true,"weapon catalog renders without visits")
training.frame:Hide()
-- Unknown or rejected native knowledge never becomes an available claim.
C_SpellBook.IsSpellKnown=function() error('unavailable') end
local uncertain=catalog:Snapshot(nil,1)
equal(Find(uncertain,6673).state,"unavailable","missing knowledge stays uncertain")
-- The automatic weapon view must select the visited master in reference order.
training.db.weapons={ {kind="weapons",trainer="Buliwyf Stonehand",faction="Alliance",rows={}} }
local masterGroups=training:WeaponGroups()
equal(masterGroups[2].snapshot.trainer,"Buliwyf Stonehand","visited master keeps stable reference page")
local oldReadable=Suite.IsReadable
local restricted={}
Suite.IsReadable=function(value) return value~=restricted and oldReadable(value) end
UnitClass=function() return "Restricted",restricted end
equal(catalog:Snapshot(saved,1),saved,"restricted class token never becomes a table key")
UnitClass=function() return token,token end
C_SpellBook.IsSpellKnown=function() return restricted end
equal(Find(catalog:Snapshot(nil,1),6673).state,"unavailable","restricted knowledge never claims availability")
Suite.IsReadable=oldReadable
token="UNSUPPORTED"
equal(catalog:Snapshot(saved,1),saved,"unknown class keeps existing saved view")
UnitClass,UnitRace,UnitFactionGroup,C_SpellBook,C_Spell,UnitLevel,GetMoney=oldClass,oldRace,oldFaction,oldBook,oldSpell,oldLevel,oldMoney
Combat(false)
