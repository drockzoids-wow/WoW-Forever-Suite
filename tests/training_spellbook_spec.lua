local Suite, equal, Frame, SetCombat = ...
local training = Suite.Training
local oldClass = UnitClass
-- Exercise the saved-view fallback while checking companion lifecycle.
UnitClass = function() return "Unsupported", "UNSUPPORTED" end
local oldDB, oldPending, oldTrainingDB = Suite.db, Suite.pending, training.db
local oldRegistry, oldPlayerSpells, oldTrainer = EventRegistry, PlayerSpellsFrame, ClassTrainerFrame
local showEvent, hideEvent = "PlayerSpellsFrame.SpellBookFrame.Show", "PlayerSpellsFrame.SpellBookFrame.Hide"
local registry = { callbacks = {}, registrations = 0 }
function registry:RegisterCallback(event, callback, owner)
    self.registrations = self.registrations + 1
    self.callbacks[event] = { callback = callback, owner = owner }
end
function registry:UnregisterCallback(event, owner)
    if self.callbacks[event] and self.callbacks[event].owner == owner then self.callbacks[event] = nil end
end
function registry:TriggerEvent(event)
    local entry = self.callbacks[event]
    if entry then entry.callback(entry.owner) end
end
EventRegistry, ClassTrainerFrame = registry, nil
PlayerSpellsFrame = Frame("NativePlayerSpells")
local parent = PlayerSpellsFrame
local book = Frame("NativeSpellbook"); parent.SpellBookFrame = book
parent.IsForbidden, book.IsForbidden = function() return false end, function() return false end
book.IsVisible = function() return book.shown and parent.shown end
parent.GetRight, parent.GetLeft = function() return 450 end, function() return 50 end
parent.HookScript, parent.SetScript, book.HookScript, book.SetScript = function() error("no native script hook") end, function() error("no native script replacement") end, function() error("no native script hook") end, function() error("no native script replacement") end
local function ShowBook()
    parent.shown, book.shown = true, true; registry:TriggerEvent(showEvent)
end
local function HideBook()
    book.shown = false; registry:TriggerEvent(hideEvent)
end
SetCombat(false); Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
training:InitializeCharacter({ position = { x = -0.1, y = 0.05 }, snapshot = {
    kind = "class", level = 6, rows = { { name = "Saved class skill", state = "available", level = 6, cost = 400 } },
} })
training:Apply()
equal(Suite.db.trainingPlanner, false, "planner master preference remains default off")
equal(Suite.db.trainingSpellbook, true, "spellbook companion is ready when the planner is enabled")
equal(next(registry.callbacks), nil, "disabled planner has no spellbook subscriptions")
ShowBook(); equal(training.frame:IsShown(), false, "disabled recording never auto-opens at the spellbook")
HideBook(); Suite.db.trainingPlanner = true; training:Apply()
equal(registry.registrations, 2, "enabled planner listens to native spellbook show and hide")
training:Apply(); training:Apply()
equal(registry.registrations, 2, "reapplying unrelated settings cannot duplicate callbacks")
local scans = 0
local oldCount = GetNumTrainerServices
GetNumTrainerServices = function() scans = scans + 1; error("spellbook is not a trainer visit") end
training.view, training.page, training.offset = "weapons", 3, 4
ShowBook()
equal(training.frame:IsShown(), true, "native spellbook show opens its planner companion")
equal(training.view, "class", "spellbook opening selects class training")
equal(training.page, 1, "spellbook starts on Available now")
equal(training.offset, 0, "spellbook opening starts at the first row")
equal(training.frame.rows[1].name.text, "Saved class skill", "spellbook displays the saved class snapshot")
equal(scans, 0, "spellbook never reads live trainer offerings")
equal(training.frame:GetParent(), UIParent, "companion remains owned by Suite under UIParent")
equal(training.frame.point[2], parent, "companion attaches beside the Player Spells window")
equal(training.frame.point[3], "TOPRIGHT", "spellbook companion uses the existing right-side gap")
equal(training.frame.OnUpdate, nil, "spellbook integration has no idle polling")
equal(parent.point, nil, "spellbook integration never reanchors the native window")
equal(parent.scale, 1, "spellbook integration preserves native scale")
equal(training.db.position.x, -0.1, "temporary spellbook attachment preserves standalone placement")
training.frame.header:OnDragStart()
equal(training.moving, nil, "companion cannot detach while docked to the spellbook")
HideBook()
equal(training.frame:IsShown(), false, "closing the spellbook closes its automatic companion")
equal(training.frame.point[2], UIParent, "closed companion restores standalone anchors")
equal(training.db.position.y, 0.05, "closed companion retains saved standalone coordinates")
ShowBook(); training.frame:Hide(); training:Apply(); registry:TriggerEvent(showEvent)
equal(training.frame:IsShown(), false, "manual dismissal lasts for the current spellbook opening")
HideBook(); ShowBook()
equal(training.frame:IsShown(), true, "reopening the spellbook permits a fresh automatic companion")
training:Open(); HideBook()
equal(training.frame:IsShown(), true, "manual opening gives the planner an independent lifetime")
training:SelectView("weapons"); ShowBook()
equal(training.view, "weapons", "spellbook preserves the selection of an already open manual planner")
HideBook(); equal(training.frame:IsShown(), true, "spellbook hide cannot dismiss an already open manual planner")
training.frame:Hide()
parent.shown, book.shown = true, false; registry:TriggerEvent(showEvent)
equal(training.frame:IsShown(), false, "a visible talents window alone does not open training")
parent.shown, book.shown = false, true; registry:TriggerEvent(showEvent)
equal(training.frame:IsShown(), false, "locally shown spellbook under a hidden parent cannot open training")
local secret = { secret = true }
parent.shown = true; book.IsVisible = function() return secret end; registry:TriggerEvent(showEvent)
equal(training.frame:IsShown(), false, "restricted effective visibility cannot authorize a popup")
book.IsVisible = function() return true end; book.IsForbidden = function() return true end; registry:TriggerEvent(showEvent)
equal(training.frame:IsShown(), false, "forbidden spellbook cannot become a companion anchor")
book.IsForbidden = function() return false end
book.IsVisible = function() return book.shown and parent.shown end
SetCombat(true); ShowBook()
local cancelled = Suite.pending.trainingSpellbook
equal(type(cancelled), "function", "spellbook opening during combat defers")
equal(training.frame:IsShown(), false, "combat spellbook show leaves the planner hidden")
HideBook(); SetCombat(false); cancelled()
equal(training.frame:IsShown(), false, "closing the spellbook cancels its deferred popup")
equal(Suite.pending.trainingSpellbook, nil, "closed spellbook leaves no deferred callback")
SetCombat(true); ShowBook(); local resumed = Suite.pending.trainingSpellbook
SetCombat(false); Suite.pending.trainingSpellbook = nil; resumed()
equal(training.frame:IsShown(), true, "still-visible spellbook opens after combat ends")
HideBook(); SetCombat(true); ShowBook(); local optionCancelled = Suite.pending.trainingSpellbook
Suite.db.trainingSpellbook = false; training:Apply(); SetCombat(false); optionCancelled()
equal(training.frame:IsShown(), false, "disabling the spellbook option invalidates deferred work")
equal(next(registry.callbacks), nil, "independent opt-out removes spellbook callbacks")
equal(Suite.db.trainingPlanner, true, "spellbook opt-out preserves trainer recording")
Suite.db.trainingSpellbook = true; training:Apply()
equal(training.frame:IsShown(), true, "enabling while the spellbook is visible opens once")
Suite.db.trainingSpellbook = false; training:Apply()
equal(training.frame:IsShown(), false, "spellbook opt-out closes only its automatic companion")
training:Open(); training:Apply()
equal(training.frame:IsShown(), true, "applying spellbook opt-out preserves a manual view")
training.frame:Hide(); HideBook(); Suite.db.trainingSpellbook = true; training:Apply()
SetCombat(true); ShowBook(); local disabled = Suite.pending.trainingSpellbook
Suite.db.trainingPlanner = false; training:Apply(); SetCombat(false); disabled()
equal(training.frame:IsShown(), false, "master disable invalidates the queued spellbook opening")
equal(next(registry.callbacks), nil, "master disable removes native callbacks even in combat")
Suite.db.trainingPlanner = true; training:Apply(); HideBook(); SetCombat(true); ShowBook()
local worldCancelled = Suite.pending.trainingSpellbook
training:OnEvent("PLAYER_ENTERING_WORLD"); SetCombat(false); worldCancelled()
equal(training.frame:IsShown(), false, "world entry cancels a stale spellbook popup")
HideBook(); EventRegistry = nil; training:Apply()
equal(next(registry.callbacks), nil, "unavailable registry drops only Suite-owned subscriptions")
EventRegistry = registry; training:OnEvent("ADDON_LOADED", "Blizzard_PlayerSpells")
equal(registry.callbacks[showEvent].owner, training, "late native availability restores callback ownership")
local nativeBook = parent.SpellBookFrame; parent.SpellBookFrame = nil; registry:TriggerEvent(showEvent)
equal(training.frame:IsShown(), false, "missing lazy-loaded spellbook child is harmless")
parent.SpellBookFrame = nativeBook
Suite.db.trainingPlanner = false; training:Apply()
GetNumTrainerServices = oldCount
EventRegistry, PlayerSpellsFrame, ClassTrainerFrame = oldRegistry, oldPlayerSpells, oldTrainer
Suite.db, Suite.pending, training.db = oldDB, oldPending, oldTrainingDB
SetCombat(false)

UnitClass = oldClass
