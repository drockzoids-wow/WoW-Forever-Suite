local Suite, equal, SetCombat, fixture = ...
local macros, items = Suite.Macros, Suite.MacroItems
local db, character, native, bags = Suite.db, Suite.macroDB, fixture.native(), fixture.bags()
local oldRun, oldUse, oldAction, oldInfo = RunMacro, UseAction, C_ActionBar, GetActionInfo
local oldRunHook, oldActionHook, oldVisible, oldLogin = macros.runHook, macros.actionHook, macros.visible, macros.loginChecked
local oldTimer, oldScan = C_Timer.NewTimer, items.Scan
local timers, scans, actionName = {}, 0, "FS Bandage"
macros:FinishUsed(); macros:Cancel(); macros.visible = false
C_Timer.NewTimer = function(delay, callback)
    local timer = { delay = delay, callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end
local function Tick(limit)
    local batch = timers; timers = {}
    for _, timer in ipairs(batch) do
        if not timer.cancelled then
            if timer.delay <= (limit or 1) then timer.callback() else timers[#timers + 1] = timer end
        end
    end
end
items.Scan = function(self) scans = scans + 1; return oldScan(self) end
RunMacro, UseAction = function() end, function() end
GetActionInfo = function(slot) return slot == 7 and "macro" or "spell" end
C_ActionBar = { GetActionText = function() return actionName end }
macros.runHook, macros.actionHook = nil, nil
fixture.native({}); fixture.bags({ 107, 116 })
Suite.db = { macroOwnership = {}, macroUpdates = false }
local state = macros:Initialize(nil)
local food, water, bandage, mainhand = unpack(state.entries)
bandage.item = 107
equal(macros:Save(bandage), true, "explicit bandage is saved for after-use checks")
local register, unregister = macros.useEvents.RegisterEvent, macros.useEvents.UnregisterAllEvents
local registered = {}
macros.useEvents.RegisterEvent = function(_, event) registered[event] = true end
macros.useEvents.UnregisterAllEvents = function() registered = {} end
local hookedRun, hookedUse = RunMacro, UseAction
macros:WatchUses(); macros:WatchUses()
equal(RunMacro, hookedRun, "use observation installs its native macro post-hook only once")
equal(UseAction, hookedUse, "use observation installs its native action post-hook only once")
SetCombat(true); macros:WatchUses()
equal(type(Suite.pending.macroUseWatch), "function", "loading use observation in combat retains deferred setup")
SetCombat(false); Suite.pending.macroUseWatch()
equal(Suite.pending.macroUseWatch, nil, "post-combat setup clears its deferred request")
local bandageIndex = macros:Find(bandage.name)
local function Body(entry) return select(3, macros:Find(entry.name)) end
local function Event(event, ...) macros.useEvents.OnEvent(macros.useEvents, event, ...) end
local function FinishUse(entry)
    RunMacro(macros:Find(entry.name)); Event("BAG_UPDATE_DELAYED"); Tick()
end
local scanStart = scans
UseAction(7)
equal(scans, scanStart, "native execution hook performs no synchronous bag scan")
fixture.bags({ 116 })
Event("BAG_UPDATE_DELAYED"); Event("BAG_UPDATE_DELAYED"); Tick()
equal(scans, scanStart + 1, "one use and settling bag bursts produce one scan")
equal(Body(bandage), "#showtooltip item:116\n/use item:116", "depleted explicit bandage switches to carried fallback with background updates off")
equal(bandage.item, 107, "fallback preserves the user's preferred bandage for restocking")
equal(macros:Find(bandage.name), bandageIndex, "fallback retains the action-bar macro index")
equal(macros.used, nil, "successful check releases pending-use state")
equal(macros.useTimer, nil, "successful check leaves no use timer")
equal(next(registered), nil, "successful check unregisters its temporary use events")
Tick(100); Event("BAG_UPDATE_DELAYED"); Event("ITEM_DATA_LOAD_RESULT", 116, true); Tick(100)
equal(scans, scanStart + 1, "unused macro stays idle across time and unrelated bag/item events")
fixture.bags({ 107, 116 }); FinishUse(bandage)
equal(Body(bandage), "#showtooltip item:107\n/use item:107", "restocked preference returns on the next use check")
bandage.item = nil; fixture.bags({ 107 }); macros:Save(bandage)
fixture.bags({ 107, 116 }); FinishUse(bandage)
equal(Body(bandage), "#showtooltip item:107\n/use item:107", "automatic bandage stays on its current carried item until depleted")
scanStart = scans
UseAction(8); UseAction({ secret = true }); actionName = { secret = true }; UseAction(7)
actionName = "Other macro"; UseAction(7); Tick(100)
equal(scans, scanStart, "other actions, unknown macros and restricted identities cannot trigger supply checks")
actionName = bandage.name

food.item = 100; fixture.bags({ 100, 101 }); macros:Save(food)
fixture.bags({ 101 }); FinishUse(food)
equal(Body(food):find("item:101", 1, true) ~= nil, true, "depleted food override falls back to suitable carried food")
local foodIndex = macros:Find(food.name)
local staleFood = "#showtooltip [combat] item:858; [nocombat] item:4592\n/use [combat] item:858\n/use [nocombat] item:4592"
fixture.native()[foodIndex].body, Suite.db.macroOwnership[food.name] = staleFood, staleFood
food.combat = true; fixture.bags({ 4593 }); actionName = food.name
local catfish = oldScan(items)
equal(catfish.best.food.id, 4593, "the supplied well-fed Fishing Catfish tooltip is valid automatic food")
equal(catfish.best.food.health, 530, "food restoration ignores the separate Fishing-skill bonus")
local oldActionInfo = GetActionInfo
GetActionInfo = function() return "item", 4592 end
C_ActionBar.IsMacroActionWithShowTooltip = function(slot) return slot == 7 end
scanStart = scans; UseAction(7); Event("BAG_UPDATE_DELAYED"); Tick()
equal(scans, scanStart + 1, "native macro predicate recognizes a food macro whose legacy action resolves to an item")
equal(Body(food), "#showtooltip [nocombat] item:4593\n/use [nocombat] item:4593", "shown Catfish replaces the stale Longjaw Mud Snapper macro automatically")
GetActionInfo = function() error("Modern macro detection must not use the legacy tuple") end
scanStart = scans; UseAction(7); Event("BAG_UPDATE_DELAYED"); Tick()
equal(scans, scanStart + 1, "native macro predicate works without any legacy action-info result")
for _, result in ipairs({ false, { secret = true }, "error" }) do
    C_ActionBar.IsMacroActionWithShowTooltip = function()
        if result == "error" then error("Unavailable action") end
        return result
    end
    scanStart = scans; UseAction(7); Tick(100)
    equal(scans, scanStart, "negative, restricted or failed native macro identity does not trigger a scan")
end
GetActionInfo = oldActionInfo; C_ActionBar.IsMacroActionWithShowTooltip = nil; actionName = bandage.name
food.combat = false
water.item = 104; fixture.bags({ 104, 103 }); macros:Save(water)
fixture.bags({ 103 }); FinishUse(water)
equal(Body(water):find("item:103", 1, true) ~= nil, true, "depleted drink override falls back with background updates off")
local weapon = fixture.weapon()
fixture.weapon(201); mainhand.item = 108; fixture.bags({ 108, 2862 }); macros:Save(mainhand)
fixture.bags({ 2862 }); FinishUse(mainhand)
equal(Body(mainhand):find("item:2862", 1, true) ~= nil, true, "depleted coating falls back to a carried stone matched to the current weapon")
fixture.weapon(nil, true); FinishUse(mainhand)
equal(Body(mainhand), "#showtooltip", "after-use coating check refuses a missing weapon")
fixture.weapon(weapon, true)
food.combat = true; fixture.bags({ 100, 105, 5512 }); macros:Save(food)
fixture.bags({ 100, 105 }); FinishUse(food)
equal(Body(food):find("item:5512", 1, true), nil, "used health macro removes its depleted Healthstone")
equal(Body(food):find("item:105", 1, true) ~= nil, true, "used health macro retains its carried potion")
local custom = macros:AddItem(); custom.item = 108
fixture.bags({ 108 }); macros:Save(custom)
fixture.bags({}); FinishUse(custom)
equal(Body(custom), "#showtooltip", "depleted custom item clears its action without inventing a replacement")
equal(custom.item, 108, "custom selection survives depletion")
fixture.bags({ 108 }); FinishUse(custom)
equal(Body(custom), "#showtooltip item:108\n/use item:108", "using a placeholder after restocking restores its selected item")

bandage.item = 107; fixture.bags({ 107, 116 }); macros:Save(bandage)
local before = Body(bandage); scanStart = scans
SetCombat(true); RunMacro(bandageIndex); fixture.bags({ 116 }); Event("BAG_UPDATE_DELAYED"); Tick(100)
equal(scans, scanStart, "use in combat neither scans bags nor edits macros")
equal(Body(bandage), before, "combat leaves the current macro untouched")
SetCombat(false); Event("PLAYER_REGEN_ENABLED"); Tick()
equal(Body(bandage), "#showtooltip item:116\n/use item:116", "used macro is checked once after combat")
equal(scans, scanStart + 1, "combat release performs one deferred scan")

fixture.bags({ 107 }); macros:Save(bandage)
RunMacro(bandageIndex); fixture.bags({ 116 }); MacroFrame:Show(); Tick()
equal(Body(bandage), "#showtooltip item:107\n/use item:107", "after-use writes pause while native editor is open")
MacroFrame:Hide(); MacroFrame.OnHide(MacroFrame); Tick()
equal(Body(bandage), "#showtooltip item:116\n/use item:116", "closing native editor finishes the used macro's pending check")
local record = fixture.native()[bandageIndex]
record.body = "/say Keep my edit"; fixture.bags({ 107 }); FinishUse(bandage)
equal(record.body, "/say Keep my edit", "after-use maintenance preserves external edits")

macros:Save(bandage); fixture.unavailable(107)
RunMacro(bandageIndex); Event("BAG_UPDATE_DELAYED"); Tick()
equal(macros.used ~= nil, true, "incomplete relevant metadata is retained for event completion")
scanStart = scans
Event("ITEM_DATA_LOAD_RESULT", 116, true); Tick()
equal(scans, scanStart, "unrequested metadata cannot resume a pending check")
fixture.unavailable(nil); Event("ITEM_DATA_LOAD_RESULT", 107, true); Tick()
equal(macros.used, nil, "relevant metadata completion finishes the pending check")
equal(scans, scanStart + 1, "relevant completion is event-driven rather than polling")
fixture.unavailable(107); FinishUse(bandage); scanStart = scans; Tick(100)
equal(macros.used, nil, "failed metadata wait expires without a recurring worker")
equal(scans, scanStart, "metadata expiration performs no retry scan")
fixture.unavailable(nil)

Suite.db.macroUpdates = true; macros:Apply(); Tick(); scanStart = scans
macros.events.OnEvent(macros.events, "PLAYER_ENTERING_WORLD"); Tick()
equal(scans, scanStart, "background class updates do not rescan idle item recipes")
fixture.bags({ 116 }); before = Body(bandage); macros.visible = true
macros:Refresh(false)
equal(Body(bandage), before, "settings preview refresh does not rewrite an unused item macro")
macros.visible = false; Suite.db.macroUpdates = false
fixture.native()[foodIndex].body, Suite.db.macroOwnership[food.name] = staleFood, staleFood
fixture.bags({ 4593 }); macros.loginChecked = nil
scanStart = scans; macros:CheckAtLogin(); macros:CheckAtLogin(); Tick()
equal(scans, scanStart + 1, "login/reload coalesces all created item recipes into one stock check even with background updates off")
equal(Body(food), "#showtooltip [nocombat] item:4593\n/use [nocombat] item:4593", "startup check repairs stale food without opening settings or pressing it")
scanStart = scans; macros:CheckAtLogin(); Event("BAG_UPDATE_DELAYED"); Tick(100)
equal(scans, scanStart, "completed startup check does not recur or watch idle bag changes")
macros.loginChecked = nil; SetCombat(true); macros:CheckAtLogin(); Tick(100)
equal(scans, scanStart, "combat-time login defers its stock scan")
SetCombat(false); Suite.pending.macroLogin(); Tick()
equal(scans, scanStart + 1, "deferred login prepares observation and performs one stock scan after combat")
fixture.native()[foodIndex].body, Suite.db.macroOwnership[food.name] = staleFood, staleFood
fixture.loading(true); RunMacro(foodIndex); Event("BAG_UPDATE_DELAYED"); Tick()
equal(Body(food), staleFood, "unloaded bag records cannot establish depletion during an automatic check")
equal(macros.useBagWaiting, true, "incomplete stock keeps a bounded bag-completion wait")
fixture.loading(false); Event("BAG_UPDATE_DELAYED"); Tick()
equal(Body(food), "#showtooltip [nocombat] item:4593\n/use [nocombat] item:4593", "bag completion finishes the pending Catfish update without a GUI refresh")
equal(macros.useBagWaiting, nil, "completed stock clears its bag wait")

-- Opening bags is an independent food check, even without an observed macro use.
local oldCombined, oldIndividual, oldBagWatch = ContainerFrameCombinedBags, ContainerFrame1, macros.bagWatch
local function BagFrame(id)
    return { GetID = function() return id end, HookScript = function(self, script, callback)
        self.hooks = (self.hooks or 0) + 1; self[script] = callback
    end }
end
ContainerFrameCombinedBags, ContainerFrame1 = BagFrame(0), BagFrame(1)
macros:WatchUses(); macros:WatchUses()
equal(ContainerFrameCombinedBags.hooks, 1, "combined bag opening observer is installed once")
equal(ContainerFrame1.hooks, 1, "individual bag opening observer is installed once")
local function Open(frame) frame.OnShow(frame) end
fixture.native()[foodIndex].body, Suite.db.macroOwnership[food.name] = staleFood, staleFood
food.item, food.combat = nil, false
fixture.bags({ 4544 }); scanStart = scans
Open(ContainerFrameCombinedBags); Open(ContainerFrame1); Open(ContainerFrameCombinedBags)
equal(scans, scanStart, "opening bags does not scan or write in the native OnShow stack")
Tick(0.15)
equal(scans, scanStart + 1, "combined and individual bag opening bursts coalesce into one check")
local breadBody = "#showtooltip [nocombat] item:4544\n/use [nocombat] item:4544"
equal(Body(food), breadBody, "bag opening replaces stale food with the screenshot's Mulgore Spice Bread while background updates are off")
equal(macros:Find(food.name), foodIndex, "bag-open refresh retains the food macro index")
equal(macros.lastEvent, "Bags opened", "diagnostics identify the independent bag-open signal")
equal(macros.used, nil, "completed bag-open check releases pending work")
scanStart = scans; Tick(100); Event("BAG_UPDATE_DELAYED"); Tick(100)
equal(scans, scanStart, "finished bag-open checks leave no idle stock refresh")

fixture.bags({ 4544, 4593, 101, 20390 }); Open(ContainerFrameCombinedBags); Tick()
equal(Body(food), "#showtooltip [nocombat] item:4593\n/use [nocombat] item:4593",
    "bag opening promotes XP food while the current ordinary food remains carried")
equal(macros:Find(food.name), foodIndex, "XP promotion preserves the owned action-bar macro index")
fixture.bags({ 4544, 101, 20390 }); FinishUse(food)
equal(Body(food), "#showtooltip [nocombat] item:101\n/use [nocombat] item:101",
    "depleted XP food falls back through the existing mage-food priority")
food.item = 4544; fixture.bags({ 4544, 4593 }); Open(ContainerFrame1); Tick()
equal(Body(food), breadBody, "bag-open XP promotion respects an explicit carried ordinary choice")
food.item = nil; fixture.bags({ 4544 }); macros:Save(food); scanStart = scans

fixture.bags({ 4593 }); SetCombat(true); Open(ContainerFrameCombinedBags); Tick(100)
equal(scans, scanStart, "combat bag opening defers the stock scan")
equal(Body(food), breadBody, "combat bag opening preserves the macro")
SetCombat(false); Event("PLAYER_REGEN_ENABLED"); Tick()
equal(Body(food):find("item:4593", 1, true) ~= nil, true, "combat exit finishes the bag-open food check")

MacroFrame:Show(); fixture.bags({ 4544 }); Open(ContainerFrame1); Tick()
equal(Body(food):find("item:4593", 1, true) ~= nil, true, "native editor pauses bag-open writes")
MacroFrame:Hide(); MacroFrame.OnHide(MacroFrame); Tick()
equal(Body(food), breadBody, "editor close resumes the pending bag-open check")
fixture.native()[foodIndex].body = "/say My custom food"
fixture.bags({ 4593 }); Open(ContainerFrameCombinedBags); Tick()
equal(Body(food), "/say My custom food", "bag opening preserves external macro edits")
macros:Save(food)
fixture.loading(true); fixture.bags({ 4544 }); Open(ContainerFrame1); Tick()
equal(Body(food):find("item:4593", 1, true) ~= nil, true, "incomplete bags preserve food on bag opening")
fixture.loading(false); Event("BAG_UPDATE_DELAYED"); Tick()
equal(Body(food), breadBody, "bag completion finishes a pending bag-open check")
fixture.unavailable(4544); Open(ContainerFrame1); Tick(); scanStart = scans; Tick(100)
equal(scans, scanStart, "bag-open metadata timeout does not poll")
equal(macros.used, nil, "bag-open metadata timeout releases work")
fixture.unavailable(nil)
scanStart = scans
for _, id in ipairs({ -1, 6, { secret = true } }) do
    ContainerFrame1.GetID = function() return id end
    Open(ContainerFrame1); Tick(100)
end
equal(scans, scanStart, "bank and restricted bag identities cannot trigger food checks")
food.created = false; Open(ContainerFrameCombinedBags); Tick(100)
equal(scans, scanStart, "uncreated food recipes cannot trigger bag-open writes")
food.created = true
-- Inventory refresh survives FinishUsed and works with settings and bags closed.
local function FoodEvent(event) macros.foodEvents.OnEvent(macros.foodEvents, event) end
local oldLevel = fixture.level(35)
local untouchedBandage = Body(bandage)
food.item, food.combat = nil, false
fixture.bags({ 4544 }); macros:Save(food)
fixture.bags({ 4603 }); scanStart = scans
FoodEvent("BAG_UPDATE_DELAYED"); FoodEvent("BAG_UPDATE_DELAYED"); FoodEvent("BAG_UPDATE_DELAYED")
equal(scans, scanStart, "inventory signal never scans synchronously")
Tick(0.15)
local yellowtailBody = "#showtooltip [nocombat] item:4603\n/use [nocombat] item:4603"
equal(scans, scanStart + 1, "idle food inventory bursts coalesce with background updates off")
equal(Body(food), yellowtailBody, "newly carried Raw Spotted Yellowtail replaces depleted food without GUI or use")
equal(Body(bandage), untouchedBandage, "food inventory checks leave unrelated supplies alone")
equal(macros.used, nil, "inventory check completes temporary work")
scanStart = scans; Tick(100)
equal(scans, scanStart, "completed inventory check has no idle timer")
fixture.bags({ 4544 }); FoodEvent("BAG_UPDATE_DELAYED"); Tick()
equal(Body(food), breadBody, "later inventory changes are still observed after FinishUsed")
SetCombat(true); fixture.bags({ 4603 }); FoodEvent("BAG_UPDATE_DELAYED"); Tick(100)
equal(Body(food), breadBody, "inventory-triggered food edits wait through combat")
SetCombat(false); Event("PLAYER_REGEN_ENABLED"); Tick()
equal(Body(food), yellowtailBody, "combat exit applies pending inventory food")
MacroFrame:Show(); fixture.bags({ 4544 }); FoodEvent("BAG_UPDATE_DELAYED"); Tick()
equal(Body(food), yellowtailBody, "inventory refresh pauses while the native editor is open")
MacroFrame:Hide(); MacroFrame.OnHide(MacroFrame); Tick()
equal(Body(food), breadBody, "closing editor applies the inventory refresh")
fixture.native()[foodIndex].body = "/say Keep this food edit"
fixture.bags({ 4603 }); FoodEvent("BAG_UPDATE_DELAYED"); Tick()
equal(Body(food), "/say Keep this food edit", "inventory refresh preserves external food edits")
macros:Save(food)
fixture.loading(true); fixture.bags({ 4544 }); FoodEvent("BAG_UPDATE_DELAYED"); Tick()
equal(Body(food), yellowtailBody, "incomplete inventory preserves existing food")
fixture.loading(false); FoodEvent("BAG_UPDATE_DELAYED"); Event("BAG_UPDATE_DELAYED"); Tick()
equal(Body(food), breadBody, "inventory completion resumes with a single deferred check")
fixture.unavailable(4603); fixture.bags({ 4603 }); FoodEvent("BAG_UPDATE_DELAYED"); Tick(); Tick(100)
equal(Body(food), breadBody, "uncached food retains text through the bounded data wait")
fixture.unavailable(nil); FoodEvent("BAG_UPDATE_DELAYED"); Tick()
equal(Body(food), yellowtailBody, "a later inventory signal recovers even after metadata wait expiry")
fixture.level(34); FoodEvent("BAG_UPDATE_DELAYED"); Tick()
equal(Body(food), "#showtooltip", "under-level Yellowtail is not selected")
fixture.level(35); FoodEvent("PLAYER_LEVEL_UP"); Tick()
equal(Body(food), yellowtailBody, "level-up rechecks newly eligible carried food after the level settles")
local potionOnly = "#showtooltip [combat] item:1710\n/use [combat] item:1710"
fixture.native()[foodIndex].body, Suite.db.macroOwnership[food.name] = potionOnly, potionOnly
food.combat, macros.loginChecked = true, nil
scanStart = scans; macros:CheckAtLogin(); Tick()
equal(scans, scanStart + 1, "reload checks live cooking-class food without settings")
equal(Body(food), yellowtailBody, "reload adds cooking-class Yellowtail to the user's potion-only owned macro")
food.combat = false
food.created = false; scanStart = scans
FoodEvent("BAG_UPDATE_DELAYED"); Tick(100)
equal(scans, scanStart, "inventory refresh never scans or creates an uncreated food recipe")
food.created = true; fixture.level(oldLevel)
fixture.native()[foodIndex] = nil
FoodEvent("BAG_UPDATE_DELAYED"); Open(ContainerFrameCombinedBags); Tick()
equal(macros:Find(food.name), nil, "bag opening never recreates a missing macro")
ContainerFrameCombinedBags, ContainerFrame1, macros.bagWatch = oldCombined, oldIndividual, oldBagWatch
macros:FinishUsed(); macros:Cancel()
macros.useEvents.RegisterEvent, macros.useEvents.UnregisterAllEvents = register, unregister
items.Scan, C_Timer.NewTimer = oldScan, oldTimer
RunMacro, UseAction, C_ActionBar, GetActionInfo = oldRun, oldUse, oldAction, oldInfo
macros.runHook, macros.actionHook, macros.visible = oldRunHook, oldActionHook, oldVisible
macros.loginChecked = oldLogin
Suite.db, Suite.macroDB = db, character
fixture.native(native); fixture.bags(bags)
