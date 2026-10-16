local Suite, equal, Frame, SetCombat = ...
local macros, supplies = Suite.Macros, Suite.MacroItems
SetCombat(false)
local data = {
    [100] = { name = "Vendor Bread", sub = 5, description = "Restores 2600 health over 30 seconds." },
    [101] = { name = "Conjured Bread", sub = 5, description = "Restores 600 health over 24 seconds." },
    [102] = { name = "Buff Steak", sub = 5, description = "Restores 4000 health. You become well fed." },
    [103] = { name = "Conjured Water", sub = 5, description = "Restores 800 mana over 24 seconds." },
    [104] = { name = "Milk", sub = 5, description = "Restores 2400 mana over 24 seconds." },
    [105] = { name = "Healing Potion", sub = 1, description = "Restores 70 to 90 health." },
    [106] = { name = "Mana Potion", sub = 1, description = "Restores 400 mana." },
    [107] = { name = "Bandage", sub = 7, description = "Heals 200 damage over 8 seconds." },
    [108] = { name = "Shadow Oil", sub = 6, description = "Coats your weapon." },
    [109] = { name = "Recipe", class = 9, description = "Teaches a recipe." },
    [110] = { name = "Future Potion", sub = 1, required = 60, description = "Restores 9000 health." },
    [111] = { name = "Thistle Tea", sub = 5, description = "Restores 100 energy." },
    [112] = { name = "Dreamless Sleep Potion", sub = 1, description = "Restores 900 health and 900 mana while asleep." },
    [113] = { name = "Crafting Oil", noUse = true },
    [114] = { name = "Percent Food", sub = 5, description = "Restores 20% of your health over 20 seconds." },
    [115] = { name = "Uncached Reagent", class = 7, noUse = true },
    [116] = { name = "Stronger Bandage", sub = 7, required = 20, description = "Heals 400 damage over 8 seconds." },
    [5512] = { name = "Healthstone", description = "Restores 100 health." },
    [2862] = { name = "Rough Sharpening Stone", sub = 6 },
    [12404] = { name = "Dense Sharpening Stone", sub = 6, required = 50 },
    [3239] = { name = "Rough Weightstone", sub = 6 },
    [12643] = { name = "Dense Weightstone", sub = 6, required = 50 },
}
local bags = { 100, 101, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 5512, 2862, 12404, 3239, 12643 }
local locale, level = "enUS", 30
local unavailable, restrictedTooltip, restrictedBag, restrictedWeapon, loadingBag
local requests = {}
local weapon = { [16] = 201, [17] = 202 }
local classes = { [201] = 7, [202] = 4, [203] = 6, [204] = 10, [205] = 13, [206] = 14 }
UnitLevel = function() return level end
GetLocale = function() return locale end
UnitHealthMax = function() error("Macro selection must not read player health") end
UnitPowerMax = function() error("Macro selection must not read player power") end
C_Item = {
    GetItemInfo = function(id)
        if id == unavailable then return nil end
        local item = data[id]; if not item then return nil end
        return item.name, "item:" .. id, 1, item.required or 10, item.required or 0, "Consumable", "",
            20, "", 134400, 0, item.class or 0, item.sub or 0
    end,
    GetItemSpell = function(id) return data[id] and not data[id].noUse and "Use" or nil end,
    RequestLoadItemDataByID = function(id) requests[id] = (requests[id] or 0) + 1 end,
    GetItemInfoInstant = function(id)
        local item = data[id]
        if item then return id, "", "", "", 1, item.class or 0, item.sub or 0 end
        if classes[id] then return id, "Weapon", "", "", 1, id == 206 and 4 or 2, classes[id] end
    end,
}
C_Container = {
    GetContainerNumSlots = function(bag) return bag == 0 and #bags or 0 end,
    GetContainerItemInfo = function(bag, slot)
        if loadingBag then return nil end
        if restrictedBag then return { itemID = { secret = true }, stackCount = 1 } end
        if bag == 0 and bags[slot] then return { itemID = bags[slot], stackCount = 2 } end
    end,
    GetContainerItemID = function(bag, slot) if bag == 0 then return bags[slot] end end,
}
C_TooltipInfo = {
    GetItemByID = function(id)
        if id == restrictedTooltip then return { lines = { { leftText = { secret = true } } } } end
        return data[id] and { lines = { { leftText = data[id].description or "Applies an effect." } } }
    end,
}
C_TooltipInfo.GetBagItem = function(_, slot) return C_TooltipInfo.GetItemByID(bags[slot]) end
GetInventoryItemID = function(_, slot) return restrictedWeapon and { secret = true } or weapon[slot] end

Suite.db = Suite.InitializeDB(nil)
local char = macros:Initialize(nil)
local food, water, bandage, mainhand, offhand = unpack(char.entries)
equal(Suite.db.macroUpdates, false, "macro updates default off")
equal(food.created, false, "starter recipes create nothing")
equal(food.combat, false, "combat supplies require an explicit choice")
local snapshot = supplies:Scan()
equal(snapshot.best.food.id, 101, "prefer conjured food to higher restoration vendor food")
equal(snapshot.best.water.id, 103, "prefer conjured drink")
equal(snapshot.byID[101].count, 4, "combine identical carried stacks")
equal(snapshot.best.healing.id, 105, "sleep potions are excluded from automatic healing")
equal(snapshot.best.mana.id, 106, "sleep potions are excluded from automatic mana")
equal(snapshot.byID[102].flags.food, nil, "buff food does not replace ordinary recovery food")
equal(snapshot.byID[111].flags.water, false, "energy supplies are excluded from drinking")
equal(snapshot.byID[109], nil, "recipes cannot be picked as consumables")
equal(snapshot.byID[110], nil, "exclude supplies above player level")
equal(snapshot.byID[113], nil, "exclude crafting items with no use action")
equal(snapshot.best.food.health, 600, "restoration is read from item text")
equal(snapshot.best.healing.health, 80, "range restoration uses its midpoint")
local body = macros:Generate(food, snapshot)
equal(body, "#showtooltip [nocombat] item:101\n/use [nocombat] item:101", "food stays outside combat by default")
food.combat, water.combat = true, true
body = macros:Generate(food, snapshot)
equal(body:find("/use [combat] item:5512", 1, true) ~= nil, true, "health recipe includes the carried Healthstone")
equal(body:find("/use [combat] item:105", 1, true) ~= nil, true, "health recipe also attempts the carried potion")
equal(#body <= 255, true, "combined recovery fits the native text limit")
local function Actions(text, inCombat)
    local actions = {}
    for condition, id in text:gmatch("/use %[(%a+)%] item:(%d+)") do
        if (condition == "combat") == inCombat then actions[#actions + 1] = id end
    end
    return table.concat(actions, ",")
end
equal(Actions(body, false), "101", "out-of-combat health recipe only eats")
equal(Actions(body, true), "5512,105", "combat health recipe attempts both supplies in order")
equal(Actions(macros:Generate(water, snapshot), true), "106", "combat mana recipe drinks no water")
equal(macros:Generate(bandage, snapshot), "#showtooltip item:107\n/use [@player] item:107", "bandage uses fixed self targeting")
equal(macros:Generate(mainhand, snapshot), "#showtooltip [nocombat] item:2862\n/use [nocombat] item:2862\n/use [nocombat] 16", "sword matches sharpening stone and main hand")
equal(macros:Generate(offhand, snapshot):find("item:3239", 1, true) ~= nil, true, "mace matches weightstone")
weapon[16] = 204
equal(macros:Generate(mainhand, snapshot):find("item:3239", 1, true) ~= nil, true, "staff swap changes the stone family")
weapon[16] = 205
equal(macros:Generate(mainhand, snapshot):find("item:3239", 1, true) ~= nil, true, "fist weapon matches weightstone")
weapon[16] = 203
equal(macros:Generate(mainhand, snapshot):find("item:2862", 1, true) ~= nil, true, "polearm matches sharpening stone")
level = 60; snapshot = supplies:Scan()
equal(macros:Generate(mainhand, snapshot):find("item:12404", 1, true) ~= nil, true, "highest ordinary usable stone tier wins")
level = 30; snapshot = supplies:Scan()
weapon[16] = 206
equal(macros:Generate(mainhand, snapshot), "#showtooltip", "shield never receives an automatic stone action")
weapon[16] = nil
equal(macros:Generate(mainhand, snapshot), "#showtooltip", "empty weapon slot has no action")
weapon[16] = 201
mainhand.item = 108
equal(macros:Generate(mainhand, snapshot):find("item:108", 1, true) ~= nil, true, "chosen coating overrides automatic stone")
mainhand.item = nil
locale = "deDE"; snapshot = supplies:Scan()
local _, _, pending = macros:Generate(food, snapshot)
equal(pending, true, "localized automatic food is never guessed")
food.item = 100
equal(macros:Generate(food, snapshot):find("item:100", 1, true) ~= nil, true, "explicit food supports another locale")
food.item, locale = nil, "enUS"
snapshot = supplies:Scan()

local native, created, edited = {}, 0, 0
Constants = { MacroConsts = { MAX_ACCOUNT_MACROS = 120, MAX_CHARACTER_MACROS = 30 } }
GetMacroInfo = function(index)
    local macro = native[index]
    if macro then return macro.name, 134400, macro.body end
end
local full = false
GetNumMacros = function()
    if full then return 120, 0 end
    local count = 0; for index in pairs(native) do if index <= 120 then count = count + 1 end end
    return count, 0
end
CreateMacro = function(name, _, text, perCharacter)
    assert(not InCombatLockdown() and not perCharacter)
    created = created + 1
    for i = 1, 120 do
        if not native[i] then native[i] = { name = name, body = text }; return i end
    end
end
EditMacro = function(index, name, icon, text)
    assert(not InCombatLockdown() and index <= 120)
    edited = edited + 1
    if name then native[index].name = name end
    native[index].body = text
    if macros.events then macros.events.OnEvent(macros.events, "UPDATE_MACROS") end
    return index
end
equal(macros:Save(food), true, "explicit create saves a General recipe")
equal(created, 1, "explicit create uses one slot")
equal(food.created, true, "confirmed save marks this character's recipe managed")
equal(macros:Save(food), true, "unchanged save is accepted")
equal(edited, 0, "unchanged macro causes no edit")
local original = native[1].body
local originalBags = bags
bags = { 100, 105 }
macros:Refresh()
equal(native[1].body, original, "disabled automatic updates keep created text unchanged")
Suite.db.macroUpdates = true
macros:Refresh()
equal(native[1].body:find("item:100", 1, true) ~= nil, true, "enabled updates follow current carried food")
equal(created, 1, "events never create unchecked or uncreated recipes")
local current = native[1].body
local unchangedEdits = edited
native[1].body = current:gsub("\n", "\r\n") .. "\r\n"
equal(macros:Save(food), true, "line-ending differences do not revoke confirmed macro ownership")
equal(edited, unchangedEdits, "equivalent native line endings cause no unnecessary edit")
bags = { 101, 105 }
macros:Refresh()
equal(native[1].body:find("item:101", 1, true) ~= nil, true, "a macro with normalized native line endings can still update")
bags = { 100, 105 }
macros:Refresh()
current = native[1].body
local getSpell = C_Item.GetItemSpell
C_Item.GetItemSpell = function() return { secret = true } end
macros:Refresh()
equal(native[1].body, current, "restricted item-use data retains existing actions")
C_Item.GetItemSpell = nil
macros:Refresh()
equal(native[1].body, current, "missing item-use API cannot clear owned actions")
C_Item.GetItemSpell = getSpell
unavailable = 100
macros:Refresh(); macros:Refresh()
equal(native[1].body, current, "uncached data preserves existing text")
equal(requests[100], 1, "uncached item data is requested once")
unavailable, restrictedTooltip = nil, 100
macros:Refresh()
equal(native[1].body, current, "secret tooltip text preserves the old action")
restrictedTooltip, restrictedBag = nil, true
macros:Refresh()
equal(native[1].body, current, "secret container fields never become macro keys or text")
restrictedBag = nil
loadingBag, bags = true, { 101, 105 }
macros:Refresh()
equal(native[1].body, current, "occupied slot with missing item information preserves the previous macro")
equal(requests[101], 1, "readable occupied ID requests its missing data once")
macros:Refresh()
equal(requests[101], 1, "repeated loading scans coalesce item data requests")
local getContainerID = C_Container.GetContainerItemID
C_Container.GetContainerItemID = function() return { secret = true } end
macros:Refresh()
equal(native[1].body, current, "restricted slot occupancy cannot clear an owned macro")
C_Container.GetContainerItemID = function() error("slot unavailable") end
macros:Refresh()
equal(native[1].body, current, "failed occupancy query cannot clear an owned macro")
C_Container.GetContainerItemID = nil
macros:Refresh()
equal(native[1].body, current, "missing occupancy API cannot turn loading slots into empty supplies")
C_Container.GetContainerItemID, loadingBag = getContainerID, nil
macros:Refresh()
equal(native[1].body:find("item:101", 1, true) ~= nil, true, "ready slot information resumes automatic macro updates")
loadingBag = true
C_Container.GetContainerItemID = function() return nil end
macros:Refresh()
equal(native[1].body, "#showtooltip", "explicitly empty slots clear obsolete actions even when their item information is nil")
C_Container.GetContainerItemID, loadingBag = getContainerID, nil
bags = {}
macros:Refresh()
equal(native[1].body, "#showtooltip", "confirmed empty supplies clear obsolete automatic actions")
bags = originalBags
macros:Refresh()
equal(native[1].body:find("item:101", 1, true) ~= nil, true, "supplies returning restore owned automatic action")
native[1].body = "/say My edited macro"
current = native[1].body
macros:Refresh()
equal(native[1].body, current, "manual text edits pause updates")
equal(macros:Save(food), false, "explicit save also preserves external edits")
native[1] = nil
macros:Refresh()
equal(native[1], nil, "deleted macros are not recreated by events")
equal(macros:Save(food), true, "explicit create can restore a deleted owned macro")
native[2] = { name = water.name, body = "/say Existing user macro" }
equal(macros:Save(water), false, "same-name user macro is never overwritten")
equal(native[2].body, "/say Existing user macro", "conflict preserves user's text")
native[2] = nil
full = true
equal(macros:Save(water), false, "full General slots produce a safe failure")
full = false
MacroFrame = Frame("MacroFrame")
MacroFrame:Show()
equal(macros:Save(water), false, "open native macro editor cannot lose unsaved edits")
MacroFrame:Hide()
native[121] = { name = water.name, body = "/say Character macro" }
equal(macros:Save(water), true, "character-scope names do not block General creation")
equal(native[121].body, "/say Character macro", "existing character macro is preserved")
native[3] = { name = food.name, body = native[1].body }
equal(macros:Save(food), false, "duplicate General names cannot be selected ambiguously")
native[3] = nil
local firstCharacter = Suite.macroDB
local beforeAltCreates = created
local secondCharacter = macros:Initialize(nil)
equal(secondCharacter.entries[1].created, true, "another character recognizes the shared owned food macro")
equal(secondCharacter.entries[2].created, true, "another character recognizes the shared owned drink macro")
equal(secondCharacter.entries[3].created, false, "a missing General recipe remains uncreated on an alt")
equal(secondCharacter.entries[1].combat, false, "shared recognition keeps the alt's default combat choice")
bags = { 100 }
macros:Refresh()
equal(native[1].body, "#showtooltip [nocombat] item:100\n/use [nocombat] item:100", "shared food refreshes to alt supplies without another Create")
equal(native[2].body, "#showtooltip", "shared drink clears unavailable alt supplies automatically")
equal(created, beforeAltCreates, "recognizing and refreshing shared macros allocates no new General slots")
Suite.macroDB = firstCharacter
bags = originalBags

weapon[17] = nil
equal(macros:Save(offhand), true, "empty off hand can explicitly create a placeholder")
local offhandIndex = macros:Find(offhand.name)
equal(native[offhandIndex].body, "#showtooltip", "empty off-hand placeholder contains no use action")
equal(offhand.created, true, "placeholder is managed like a created recipe")
local placeholderCreates = created
weapon[17] = 202
macros:Refresh()
equal(native[offhandIndex].body, "#showtooltip [nocombat] item:3239\n/use [nocombat] item:3239\n/use [nocombat] 17", "equipping a suitable off hand fills its existing placeholder")
equal(created, placeholderCreates, "filling a placeholder reuses its General slot")
weapon[17] = 206
macros:Refresh()
equal(native[offhandIndex].body, "#showtooltip", "equipping a shield clears the automatic off-hand action")
weapon[17] = 202
macros:Refresh()
local offhandBody = native[offhandIndex].body
restrictedWeapon = true
macros:Refresh()
equal(native[offhandIndex].body, offhandBody, "unreadable weapon data cannot empty an active coating macro")
restrictedWeapon = nil
SetCombat(true)
weapon[17] = nil
macros:Refresh()
equal(native[offhandIndex].body, offhandBody, "removing a weapon in combat defers changes to its macro")
SetCombat(false)
macros:Refresh()
equal(native[offhandIndex].body, "#showtooltip", "leaving combat clears the now-empty hand")

bags = {}
Suite.db.macroUpdates = false
equal(macros:Save(mainhand), true, "missing carried coating permits an explicit main-hand placeholder")
local mainhandIndex = macros:Find(mainhand.name)
equal(native[mainhandIndex].body, "#showtooltip", "main-hand placeholder contains no stale action")
equal(Suite.db.macroUpdates, false, "creating a placeholder preserves the automatic-update preference")
bags = originalBags
macros:Refresh()
equal(native[mainhandIndex].body, "#showtooltip", "updates off keeps a placeholder inert when supplies arrive")
Suite.db.macroUpdates = true
macros:Refresh()
equal(native[mainhandIndex].body, "#showtooltip [nocombat] item:2862\n/use [nocombat] item:2862\n/use [nocombat] 16", "returning supplies fill the existing main-hand placeholder")
weapon[17] = 202
local _, _, awaitingData = macros:Generate(offhand, { incomplete = true })
equal(awaitingData, true, "placeholder support keeps incomplete-data safeguards")
equal(macros:CanSave(offhand, nil, true, false), false, "unreadable data does not allow an empty overwrite")
equal(macros:CanSave({ recipe = "food", created = false }, "#showtooltip", false, false), false, "empty non-weapon starter retains its existing creation rule")

local timers = {}
C_Timer.NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end
local function Flush()
    local batch = timers; timers = {}
    for _, timer in ipairs(batch) do if not timer.cancelled then timer.callback() end end
end
Suite.db.macroUpdates = true
macros:Apply(); Flush()
equal(macros:Save(bandage), true, "create bandage for event-driven update regressions")
local bandageIndex = macros:Find(bandage.name)
bags, unavailable, weapon[16], weapon[17] = { 100, 104, 116, 3239, 115 }, 115, 204, nil
macros.events.OnEvent(macros.events, "BAG_UPDATE_DELAYED")
macros.events.OnEvent(macros.events, "PLAYER_EQUIPMENT_CHANGED", 16)
Flush()
equal(native[1].body:find("item:100", 1, true) ~= nil, true, "bag events update food despite an uncached unrelated reagent")
equal(native[2].body:find("item:104", 1, true) ~= nil, true, "bag events update drink despite an uncached unrelated reagent")
equal(native[bandageIndex].body:find("item:116", 1, true) ~= nil, true, "bag events update bandages despite an uncached unrelated reagent")
equal(native[mainhandIndex].body:find("item:3239", 1, true) ~= nil, true, "equipment events update coatings despite an uncached unrelated reagent")
equal(native[offhandIndex].body, "#showtooltip", "empty hand clears its coating despite an uncached unrelated reagent")
equal(requests[115], 1, "unrelated uncached data is still requested once")

bags, unavailable, weapon[16] = { 101, 107, 2862, 3239 }, 101, 201
local pendingFood = native[1].body
macros.events.OnEvent(macros.events, "BAG_UPDATE_DELAYED"); Flush()
equal(native[1].body, pendingFood, "pending relevant food retains its previous action")
equal(native[2].body:find("item:104", 1, true) ~= nil, true, "unknown recovery item also preserves drink until classified")
equal(native[bandageIndex].body:find("item:107", 1, true) ~= nil, true, "pending food does not pause ready bandage updates")
equal(native[mainhandIndex].body:find("item:2862", 1, true) ~= nil, true, "pending food does not pause ready coating updates")
unavailable = nil
macros.events.OnEvent(macros.events, "GET_ITEM_INFO_RECEIVED", 101, true); Flush()
equal(native[1].body:find("item:101", 1, true) ~= nil, true, "item data completion fills the previously pending food recipe")
equal(native[2].body, "#showtooltip", "complete recovery data can clear now-missing water")

bags, unavailable, food.combat = { 100, 105, 107, 2862, 3239 }, 105, false
macros.events.OnEvent(macros.events, "BAG_UPDATE_DELAYED"); Flush()
equal(native[1].body:find("item:100", 1, true) ~= nil, true, "pending potion cannot pause food with combat additions off")
food.combat, bags = true, { 101, 105, 107, 2862, 3239 }
pendingFood = native[1].body
macros.events.OnEvent(macros.events, "BAG_UPDATE_DELAYED"); Flush()
equal(native[1].body, pendingFood, "enabled combat addition waits for its pending potion")
unavailable = nil
macros.events.OnEvent(macros.events, "GET_ITEM_INFO_RECEIVED", 105, true); Flush()
equal(native[1].body:find("item:105", 1, true) ~= nil, true, "completed potion data resumes the combat food recipe")

weapon[16], weapon[17] = 204, 202
macros.events.OnEvent(macros.events, "PLAYER_EQUIPMENT_CHANGED", 17); Flush()
local pendingMainhand, pendingOffhand = native[mainhandIndex].body, native[offhandIndex].body
bags, unavailable, weapon[16] = { 100, 107, 2862, 3239 }, 3239, 204
macros.events.OnEvent(macros.events, "BAG_UPDATE_DELAYED"); Flush()
equal(native[offhandIndex].body, pendingOffhand, "pending matching weightstone preserves the off-hand action")
equal(native[mainhandIndex].body, pendingMainhand, "pending matching weightstone preserves the previous main-hand action")
weapon[16] = 201
macros.events.OnEvent(macros.events, "PLAYER_EQUIPMENT_CHANGED", 16); Flush()
equal(native[mainhandIndex].body:find("item:2862", 1, true) ~= nil, true, "pending weightstone does not pause a ready sharpening recipe")
equal(native[1].body:find("item:100", 1, true) ~= nil, true, "pending stone does not pause recovery updates")

local diagnostics, printMessage = {}, Suite.Print
Suite.Print = function(message) diagnostics[#diagnostics + 1] = message end
local diagnosticWrites = created + edited
SlashCmdList.WOWFOREVERSUITE("macrostatus")
equal(diagnostics[1]:find("On", 1, true) ~= nil, true, "macro status reports the enabled update preference")
equal(table.concat(diagnostics, "\n"):find("Matching stone data is loading", 1, true) ~= nil, true, "macro status exposes the actual pending recipe")
equal(created + edited, diagnosticWrites, "macro status performs no native macro writes")
Suite.Print = printMessage
bags, unavailable, weapon[16], weapon[17] = originalBags, nil, 201, 202
macros:Apply(); macros:Queue(); macros:Queue()
equal(#timers, 1, "event bursts coalesce into one cancellable timer")
MacroFrame:Show()
local editorBody = native[1].body
Flush()
equal(native[1].body, editorBody, "automatic updates pause while native editor is open")
MacroFrame:Hide(); MacroFrame.OnHide(MacroFrame)
equal(macros.timer ~= nil, true, "closing the native editor queues a refresh")
SetCombat(true)
macros.events.OnEvent(macros.events, "PLAYER_REGEN_DISABLED")
equal(macros.timer, nil, "combat cancels pending update")
local writes = edited + created
equal(macros:Save(mainhand), false, "combat cannot create a macro")
Flush()
equal(edited + created, writes, "cancelled timer performs no combat writes")
SetCombat(false)
macros.events.OnEvent(macros.events, "PLAYER_REGEN_ENABLED")
Flush()
equal(macros.timer, nil, "post-combat refresh leaves no idle timer")
Suite.db.macroUpdates = false
macros:Queue(); macros:Apply(); Flush()
equal(macros.timer, nil, "disabled hidden module leaves no timer")
restrictedWeapon = true
local _, _, weaponPending = macros:Generate(mainhand, supplies:Scan())
equal(weaponPending, true, "secret equipped weapon data retains the owned action")
restrictedWeapon = nil

local gui = Suite.GUI
gui:Select("macros")
macros:Refresh()
equal(gui.macroPanel:IsShown(), true, "Macros opens as a sidebar page")
equal(gui.macroRows[1].entry, food, "recipe selection uses persistent character choices")
offhand.created = false
weapon[17] = nil
macros.snapshot = supplies:Scan()
gui.macroRows[5].OnClick()
equal(gui.macroSave.enabled, true, "empty hand leaves the GUI Create button enabled")
equal(gui.macroSave.label.text, "Create placeholder", "GUI explains blank weapon macro creation")
gui.macroSave.OnClick()
equal(offhand.created, true, "GUI can save the empty-hand placeholder")
equal(native[offhandIndex].body, "#showtooltip", "GUI placeholder cannot apply a coating to an empty hand")
weapon[17] = 202
gui.macroRows[2].OnClick()
equal(gui.macroSelected, water, "recipe click changes the preview")
local menuChoices = {}
MenuUtil = { CreateContextMenu = function(_, build)
    build(nil, { CreateButton = function(_, label, callback) menuChoices[#menuChoices + 1] = { label, callback } end,
        CreateTitle = function() end })
end }
gui.macroRows[4].OnClick(); gui:ChooseMacroItem()
equal(menuChoices[1][1], "Select automatically", "item picker offers automatic reset for coatings")
for _, choice in ipairs(menuChoices) do if choice[1]:find("Shadow Oil", 1, true) then choice[2]() end end
equal(mainhand.item, 108, "picker chooses a carried coating without using it")
gui.macroPreview.text = "/say altered"
gui.macroPreview.OnTextChanged(gui.macroPreview, true)
equal(gui.macroPreview.text, gui.macroPreviewBody, "copyable preview cannot silently change the recipe")
SetCombat(true)
gui:RefreshMacros()
equal(gui.macroSave.enabled, false, "create button is disabled in combat")
equal(gui.macroChoose.enabled, false, "item choices are disabled in combat")
SetCombat(false)
gui:Select("overview")
equal(gui.macroPanel:IsShown(), false, "leaving Macros hides its controls")
equal(macros.visible, false, "leaving Macros stops preview subscriptions")
local extra = macros:AddItem()
equal(extra.name, "FS Item 1", "item variants have stable generated names")
local restored = macros:Initialize(Suite.macroDB)
equal(restored.entries[4].item, 108, "chosen coating survives character settings reload")
equal(restored.entries[6].name, "FS Item 1", "item variant survives character settings reload")
equal(macros:RemoveItem(restored.entries[6]), true, "remove an item choice independently of its game macro")
equal(#Suite.macroDB.entries, 5, "removing a choice stops its future updates")
equal(macros:AddItem().name, "FS Item 2", "removed names are not reused for unrelated items")
local generic = Suite.macroDB.entries[6]
generic.item = 108
equal(macros:Save(generic), true, "chosen item variant can be created")
local genericIndex = macros:Find(generic.name)
local keptBody = native[genericIndex].body
equal(macros:RemoveItem(generic), true, "created item option can stop updates")
equal(native[genericIndex].body, keptBody, "removing a choice leaves its game macro intact")
local readMacro = GetMacroInfo
GetMacroInfo = function(index) if index == 1 then return { secret = true } end; return readMacro(index) end
equal(macros:Save(food), false, "unreadable macro names cannot select a write target")
GetMacroInfo = readMacro
local writeMacro = EditMacro
EditMacro = function() error("Client refused edit") end
food.combat = true
equal(macros:Write(food, "#showtooltip\n/use [nocombat] item:100", true), false, "native API failure leaves ownership unchanged")
EditMacro = writeMacro
local bad = macros:Initialize({ entries = { { recipe = "item", serial = 1, item = -4 },
    { recipe = "item", serial = 1 }, { recipe = "unknown" }, { recipe = "food", item = "invalid", created = true } } })
equal(#bad.entries, 7, "corrupt saved choices are repaired while existing shared item macros are recognized")
equal(bad.entries[1].item, nil, "invalid saved item IDs do not enter macro text")

-- Exercise shared enrollment through real saves and the normal event lifecycle.
macros:Cancel(); Flush()
local previousNative, previousDB, previousCharacter = native, Suite.db, Suite.macroDB
local registered = {}
local eventRegister, eventUnregister = macros.events.RegisterEvent, macros.events.UnregisterAllEvents
macros.events.RegisterEvent = function(_, event) registered[event] = true end
macros.events.UnregisterAllEvents = function() registered = {} end
native = {}
Suite.db = Suite.InitializeDB(nil)
local owner = macros:Initialize(nil)
bags, weapon[16], weapon[17] = originalBags, 201, 202
owner.entries[1].combat, owner.entries[4].item = true, 108
for _, entry in ipairs(owner.entries) do equal(macros:Save(entry), true, "create a fixed recipe for cross-character recognition") end
local chosen = macros:AddItem(); chosen.item = 108
equal(macros:Save(chosen), true, "save first shared chosen-item recipe")
local secondItem = macros:AddItem(); secondItem.item = 107
equal(macros:Save(secondItem), true, "save second shared chosen-item recipe")
local shareCreates, shareWrites, ownerFood = created, edited, native[1].body
local alt = macros:Initialize(nil)
for index = 1, 5 do equal(alt.entries[index].created, true, "every existing fixed General macro is recognized on a fresh alt") end
equal(#alt.entries, 7, "shared chosen-item recipes appear without adding them on the alt")
equal(alt.entries[6].name, "FS Item 1", "shared item imports retain stable sorted names")
equal(alt.entries[6].item, 108, "shared item import recovers its confirmed chosen item")
equal(alt.entries[7].item, 107, "shared item variants retain independent choices")
equal(alt.nextSerial, 3, "new item names advance beyond existing shared names")
equal(created, shareCreates, "login recognition never creates game macros")
equal(edited, shareWrites, "login recognition never edits game macros")
equal(Suite.db.macroUpdates, false, "recognition preserves the disabled automatic-update preference")
macros:Refresh()
equal(native[1].body, ownerFood, "updates off keeps the owner's shared text unchanged on the alt")
equal(alt.entries[1].combat, false, "recognition preserves fresh character combat defaults")
equal(alt.entries[4].item, nil, "fixed recipes retain per-character item choices")
local existingAlt = macros:Initialize({ schema = 1, entries = {
    { recipe = "food", created = false, combat = true, item = 100 },
    { recipe = "item", serial = 1, created = false, item = 107 },
    { recipe = "item", serial = 2, created = false },
} })
equal(existingAlt.schema, 2, "older character settings migrate to shared discovery with removal memory")
equal(existingAlt.entries[1].created, true, "previously visited alts recognize General macros despite old false flags")
equal(existingAlt.entries[1].combat, true, "recognition retains the alt's saved combat choice")
equal(existingAlt.entries[1].item, 100, "recognition retains the alt's saved food override")
equal(existingAlt.entries[6].created, true, "a saved item choice becomes active without another Create")
equal(existingAlt.entries[6].item, 107, "existing alt item choices are preserved during recognition")
equal(existingAlt.entries[7].item, 107, "an unfinished alt item choice recovers the existing shared macro's item")
alt = macros:Initialize(nil)
Suite.db.macroUpdates = true
bags = { 100, 104, 107, 108, 2862, 3239 }
macros:Apply(); Flush()
equal(native[1].body, "#showtooltip [nocombat] item:100\n/use [nocombat] item:100", "normal login work updates shared food for the alt's current supplies")
equal(native[2].body:find("item:104", 1, true) ~= nil, true, "shared drink follows alt supplies through normal queued work")
equal(native[4].body:find("item:2862", 1, true) ~= nil, true, "shared coating follows the alt's weapon and own recipe choice")
equal(created, shareCreates, "automatic alt updates reuse existing General slots")
local altItem = alt.entries[6]
equal(macros:RemoveItem(altItem), true, "an alt can still remove a shared item choice locally")
local keptItem = native[6].body
macros:Refresh()
equal(#alt.entries, 6, "refresh does not re-import a deliberately removed item choice")
equal(native[6].body, keptItem, "local removal keeps the General macro unchanged")
alt = macros:Initialize(alt)
equal(#alt.entries, 6, "reload retains local removal of a shared item choice")
equal(alt.ignoredItems[1], true, "removed item serial is remembered on this character")
local otherAlt = macros:Initialize(nil)
equal(#otherAlt.entries, 7, "local removal does not hide the shared item from another character")
local newItem = macros:AddItem()
equal(newItem.name, "FS Item 3", "adding on another character cannot reuse an existing shared item name")
equal(newItem.created, false, "adding a new item choice still requires explicit creation")
equal(created, shareCreates, "adding a choice cannot create a General macro automatically")
local baselineNative, baselineOwnership = Suite.Copy(native), Suite.Copy(Suite.db.macroOwnership)
local function ResetShared()
    macros:Cancel(); Flush()
    native, Suite.db.macroOwnership = Suite.Copy(baselineNative), Suite.Copy(baselineOwnership)
end

ResetShared()
native[119] = Suite.Copy(native[1])
alt = macros:Initialize(nil)
equal(alt.entries[1].created, false, "duplicate General names are not automatically adopted")
equal(alt.entries[2].created, true, "duplicate names do not block independent shared recipes")
local duplicateBody = native[1].body
macros:Refresh()
equal(native[1].body, duplicateBody, "ambiguous shared names cannot be rewritten")
native[119] = nil
macros.events.OnEvent(macros.events, "UPDATE_MACROS"); Flush()
equal(alt.entries[1].created, true, "a later macro event recognizes a now-unambiguous shared recipe")

ResetShared()
native[1].body = "/say My edited shared macro"
alt = macros:Initialize(nil)
equal(alt.entries[1].created, false, "a fresh alt does not adopt an externally edited shared macro")
macros:Refresh()
equal(native[1].body, "/say My edited shared macro", "automatic alt refresh preserves an external text edit")
ResetShared()
Suite.db.macroOwnership["FS Food"] = nil
alt = macros:Initialize(nil)
equal(alt.entries[1].created, false, "matching Suite names and generated text alone cannot establish ownership")
ResetShared()
native[121], native[1] = native[1], nil
alt = macros:Initialize(nil)
equal(alt.entries[1].created, false, "character-only macros cannot activate a General recipe")
equal(native[121].name, "FS Food", "shared discovery preserves character macros")
ResetShared()
native[1].body = native[1].body:gsub("\n", "\r\n") .. "\r\n"
alt = macros:Initialize(nil)
equal(alt.entries[1].created, true, "shared recognition accepts the same native line-ending normalization as updates")

ResetShared()
GetMacroInfo = nil
alt = macros:Initialize(nil)
equal(alt.entries[1].created, false, "missing macro APIs cannot falsely recognize ownership")
equal(#alt.entries, 5, "missing macro APIs cannot import item choices")
GetMacroInfo = readMacro
macros:Apply(); Flush()
equal(alt.entries[1].created, true, "late macro API availability recognizes fixed recipes without another Create")
equal(#alt.entries, 7, "late macro API availability imports shared chosen-item recipes")
for _, restriction in ipairs({ "name", "body", "error" }) do
    ResetShared()
    GetMacroInfo = function(index)
        if index == 120 then
            if restriction == "name" then return { secret = true }, 134400, "#showtooltip" end
            if restriction == "body" then return "Other", 134400, { secret = true } end
            error("Macro information unavailable")
        end
        return readMacro(index)
    end
    alt = macros:Initialize(nil)
    equal(alt.entries[1].created, false, "unreadable General listings defer all new ownership recognition")
    equal(#alt.entries, 5, "unreadable General listings cannot import item recipes")
    GetMacroInfo = readMacro
    macros.events.OnEvent(macros.events, "UPDATE_MACROS"); Flush()
    equal(alt.entries[1].created, true, "a readable later macro event resumes deferred recognition")
end

ResetShared()
MacroFrame:Show()
alt = macros:Initialize(nil)
equal(alt.entries[1].created, true, "read-only shared recognition is allowed while the native editor is open")
local editorWrites = edited
bags = { 101, 107, 108, 2862, 3239 }
macros:Refresh()
equal(edited, editorWrites, "shared enrollment cannot discard open native editor text")
MacroFrame:Hide(); MacroFrame.OnHide(MacroFrame); Flush()
equal(native[1].body:find("item:101", 1, true) ~= nil, true, "closing the editor refreshes the alt's recognized shared recipe")

ResetShared()
SetCombat(true)
alt = macros:Initialize(nil)
equal(alt.entries[1].created, false, "first shared discovery defers in combat")
equal(#alt.entries, 5, "combat cannot import shared item choices")
local combatWrites = created + edited
macros:Apply()
macros.events.OnEvent(macros.events, "UPDATE_MACROS")
equal(macros.timer, nil, "combat leaves no pending discovery worker")
equal(created + edited, combatWrites, "combat discovery attempts never create or edit a game macro")
SetCombat(false)
macros.events.OnEvent(macros.events, "PLAYER_REGEN_ENABLED"); Flush()
equal(alt.entries[1].created, true, "post-combat work recognizes the shared fixed recipe")
equal(#alt.entries, 7, "post-combat work imports shared item choices")

ResetShared()
native[8] = { name = "FS Item 3", body = "#showtooltip item:108\n/use item:108" }
alt = macros:Initialize(nil)
equal(#alt.entries, 7, "unowned item macro names are never imported")
for _, text in ipairs({ "#showtooltip item:108\n/use item:107", "#showtooltip item:108\n/use item:108\n/say extra", "#showtooltip item:10000001\n/use item:10000001" }) do
    ResetShared()
    native[6].body, Suite.db.macroOwnership["FS Item 1"] = text, text
    alt = macros:Initialize(nil)
    equal(#alt.entries, 6, "item import requires the exact confirmed generated single-item shape and a valid ID")
end
ResetShared()
native[6].body = "/say Custom item"
alt = macros:Initialize(nil)
equal(#alt.entries, 6, "externally edited chosen-item macros are not imported")
ResetShared()
native = {}
alt = macros:Initialize(nil)
equal(#alt.entries, 5, "ownership history without existing General macros cannot import item choices")
macros:Refresh()
equal(created, shareCreates, "deleted shared macros are never recreated by login or events")
Suite.db.macroUpdates = false
macros:Apply()
equal(macros.timer, nil, "updates off and hidden sharing retain no timer")
equal(next(registered), nil, "updates off and hidden sharing retain no feature events")

native, Suite.db.macroOwnership = {}, {}
for serial = 12, 1, -1 do
    local name, text = "FS Item " .. serial, "#showtooltip item:108\n/use item:108"
    native[serial] = { name = name, body = text }
    Suite.db.macroOwnership[name] = text
end
alt = macros:Initialize(nil)
equal(#alt.entries, 15, "shared item discovery retains the ten-choice limit")
equal(alt.entries[6].serial, 1, "bounded item imports choose the earliest serial first")
equal(alt.entries[15].serial, 10, "bounded item imports are stable despite ownership table order")
equal(alt.nextSerial, 13, "name allocation accounts for shared items beyond the local choice limit")
equal(macros:AddItem(), nil, "full shared item choices keep the existing add limit")
equal(macros:RemoveItem(alt.entries[6]), true, "shared item removal remains available at the limit")
alt = macros:Initialize(alt)
equal(alt.entries[15].serial, 11, "the next available shared item can fill space after a local removal")
equal(alt.ignoredItems[1], true, "bounded imports preserve deliberate local removals")
-- Class recipes share the existing ownership rules, but never appear or update on other classes.
local oldUnitClass, oldSpellAPI, oldPetAPI, oldUnitExists = UnitClass, C_Spell, C_PetInfo, UnitExists
local playerClass = "HUNTER"
UnitClass = function() return "Hunter", playerClass end
local petExists, petFoods = true, { [100] = true, [113] = true }
UnitExists = function(unit) return unit == "pet" and petExists or false end
C_PetInfo = { CanPetEatItem = function(id) return petFoods[id] == true end }
local spells = { [34477] = "Misdirection", [982] = "Revive Pet", [136] = "Mend Pet", [6991] = "Feed Pet" }
C_Spell = { GetSpellInfo = function(id) return spells[id] and { name = spells[id] } end }
native, Suite.db.macroOwnership = {}, {}
Suite.db.macroUpdates = false
alt = macros:Initialize(nil)
equal(#macros:Entries(), 7, "hunter sees the two class recipes alongside shared recipes")
local redirect, pet = alt.entries[6], alt.entries[7]
equal(redirect.recipe, "hunterMisdirection", "hunter recipes precede arbitrary item choices")
equal(macros:Generate(redirect, { incomplete = true }), "#showtooltip Misdirection\n/cast [@focus,help][@target,help][@pet,exists] Misdirection", "misdirection exactly preserves requested friendly target precedence without bag dependencies")
equal(macros:Save(redirect), true, "hunter can explicitly create misdirection")
local redirectIndex = macros:Find(redirect.name)
local savedRedirect = native[redirectIndex].body
local blankBody, _, blankPending = macros:Generate(pet, supplies:Scan())
equal(blankBody, nil, "pet care needs a deliberate food choice")
equal(blankPending, true, "unselected pet food cannot create a misleading macro")
bags = { 100, 100, 113, 105, 109 }
data[113].name = "Raw Pet Food"
macros.snapshot = supplies:Scan()
equal(macros.snapshot.carriedByID[100].count, 4, "explicit picker counts duplicate stacks")
equal(macros.snapshot.carriedByID[113].name, "Raw Pet Food", "explicit picker includes ingredients without a use spell")
gui.macroSelected = pet
gui:RefreshMacros()
equal(gui.macroRows[7].entry, pet, "all hunter recipes occupy the scroll child without paging")
equal(gui.macroRows[7]:GetParent(), gui.macroListContent, "recipe rows belong to the independent list viewport")
equal(gui.macroListHeadings[1].label.text, "− General", "ordinary recipes have their own heading")
equal(gui.macroListHeadings[2].label.text, "− Hunter Macros", "hunter recipes have a separate heading")
local outerOffset = gui.scrollOffset
gui.macroListScroll.suiteScrollBar.OnValueChanged(gui.macroListScroll.suiteScrollBar, 1)
equal(gui.macroListScroll.suiteOffset, gui.macroListScroll.suiteMaximum, "list thumb reaches the last hunter recipe")
equal(gui.scrollOffset, outerOffset, "list thumb scrolling leaves the surrounding page unchanged")
gui.macroRows[7].OnClick()
equal(gui.macroSelected, pet, "a scrolled hunter row selects its matching detail view")
gui.macroRows[7].OnMouseWheel(gui.macroRows[7], 1)
equal(gui.macroListScroll.suiteOffset, gui.macroListScroll.suiteMaximum - 40, "wheel over a recipe scrolls its own list")
equal(gui.scrollOffset, outerOffset, "row wheel input does not scroll the outer page")
equal(gui.macroChoose:IsShown(), true, "hunter pet care exposes a food picker")
menuChoices = {}; gui:ChooseMacroItem()
equal(menuChoices[1][1] ~= "Select automatically", true, "pet food never offers an automatic replacement")
for _, choice in ipairs(menuChoices) do if choice[1]:find("Raw Pet Food", 1, true) then choice[2]() end end
equal(pet.item, 113, "pet food picker records the player's explicit ingredient choice")
local petBody = macros:Generate(pet, macros.snapshot)
equal(petBody, "#showtooltip\n/cast [@pet,dead][nopet,mod:shift] Revive Pet\n/cast [combat,@pet,exists,nodead] Mend Pet; [nocombat,@pet,exists,nodead] Feed Pet\n/use [nocombat,@pet,exists,nodead] item:113", "pet macro guards feeding against combat, dead and absent pets")
equal(#petBody <= 255, true, "English pet care fits the native body limit")
equal(macros:Save(pet), true, "selected pet food allows explicit creation")
local petIndex = macros:Find(pet.name)
bags = {}; Suite.db.macroUpdates = true; macros:Refresh()
equal(native[petIndex].body, petBody, "depleted food retains the chosen action rather than clearing or substituting it")
equal(macros.statuses[pet]:find("not carried", 1, true) ~= nil, true, "depleted food remains visible as a reminder after automatic refresh")
bags = { 113 }; macros:Refresh()
equal(macros.statuses[pet]:find("2 carried", 1, true) ~= nil, true, "restocking clears the depletion message through ordinary bag refresh")
local foodName = data[113].name; data[113].name = { secret = true }; macros:Refresh()
equal(native[petIndex].body, petBody, "unreadable carried names preserve pet text")
equal(macros:Generate(pet, macros.snapshot), nil, "unreadable carried metadata cannot establish depletion")
data[113].name = foodName
-- Use the game's per-item predicate, including ingredients; never infer diet
-- from an English food name or fall back to all carried items on unknown data.
bags = { 100, 100, 113, 105, 109 }
local dietSnapshot = supplies:Scan()
local dietChoices, dietNote = supplies:Choices(dietSnapshot, "hunterPet")
equal(#dietChoices, 2, "active pet food predicate removes potions and recipes from the picker")
equal(dietNote, nil, "complete accepted food data needs no diagnostic")
equal(dietChoices[1].id, 113, "no-use-spell ingredients remain eligible when the active pet accepts them")
equal(dietChoices[2].count, 4, "filtered choices preserve combined carried stack counts")
petFoods = { [100] = true }
equal(#supplies:Choices(dietSnapshot, "hunterPet"), 1, "switching pets immediately changes the allowed list")
local preservedPetText, incompatibleNote = macros:Generate(pet, dietSnapshot)
equal(preservedPetText, petBody, "switching to an incompatible diet retains the selected macro item")
equal(incompatibleNote:find("cannot eat", 1, true) ~= nil, true, "incompatible selected food gets a change-food reminder")
petFoods = { [113] = true }; gui.macroSelected = pet; menuChoices = {}; gui:ChooseMacroItem()
equal(#menuChoices, 1, "native menu contains only current-pet-compatible food")
local previousFood = pet.item
petFoods = { [100] = true }; menuChoices[1][2]()
equal(pet.item, previousFood, "stale menu selection cannot accept food after changing pets")
equal(macros.statuses[pet]:find("cannot eat", 1, true) ~= nil, true, "stale diet selection explains why it was rejected")
petExists = false
local noPetChoices, noPetNote = supplies:Choices(dietSnapshot, "hunterPet")
equal(#noPetChoices, 0, "no active pet produces no unfiltered fallback")
equal(noPetNote, "Call your pet to choose food it can eat.", "no-pet picker asks the player to summon a pet")
petExists = { secret = true }
equal(#supplies:Choices(dietSnapshot, "hunterPet"), 0, "secret pet identity suppresses food choices")
petExists = true
local nativeCanEat = C_PetInfo.CanPetEatItem
C_PetInfo.CanPetEatItem = nil
local unsupported, unsupportedNote = supplies:Choices(dietSnapshot, "hunterPet")
equal(#unsupported, 0, "missing pet food predicate never exposes all bag items")
equal(unsupportedNote:find("unavailable", 1, true) ~= nil, true, "missing native predicate explains unavailable filtering")
C_PetInfo.CanPetEatItem = function(id) return id == 113 and true or { secret = true } end
local partialChoices, partialNote = supplies:Choices(dietSnapshot, "hunterPet")
equal(#partialChoices, 1, "restricted predicate results omit only unconfirmed candidates")
equal(partialChoices[1].id, 113, "readable accepted food can remain visible amid unknown candidates")
equal(partialNote:find("unavailable", 1, true) ~= nil, true, "unknown candidate results disclose partial information")
C_PetInfo.CanPetEatItem = function() error("unavailable") end
equal(#supplies:Choices(dietSnapshot, "hunterPet"), 0, "native predicate failures never become accepted foods")
C_PetInfo.CanPetEatItem = function() return nil end
equal(#supplies:Choices(dietSnapshot, "hunterPet"), 0, "nil native predicate results are unknown")
C_PetInfo.CanPetEatItem, petFoods = nativeCanEat, {}
local emptyFoods, emptyFoodNote = supplies:Choices(dietSnapshot, "hunterPet")
equal(#emptyFoods, 0, "known mismatches produce an empty food list")
equal(emptyFoodNote, "No carried food matches your active pet.", "known empty diet choices are clearly distinguished from unavailable data")
equal(supplies:PetCanEat({ secret = true }), nil, "unreadable item IDs cannot reach the pet API")
equal(supplies:PetCanEat(-1), nil, "invalid item IDs cannot reach the pet API")
petFoods = { [100] = true, [113] = true }
SetCombat(true)
equal(supplies:PetCanEat(113), nil, "pet food selection stays paused in combat")
equal(#supplies:Choices(dietSnapshot, "hunterPet"), 0, "combat produces no actionable pet-food menu choices")
SetCombat(false)
macros:Cancel(); macros.events.OnEvent(macros.events, "UNIT_PET", "target")
equal(macros.timer, nil, "unrelated units do not queue pet-food refresh")
macros.statuses[pet] = "Suitable for the previous pet."
macros.events.OnEvent(macros.events, "UNIT_PET", "player")
equal(macros.timer ~= nil, true, "own pet changes queue a coalesced refresh")
equal(macros.statuses[pet], nil, "changing pets clears outdated suitability feedback even with automatic writes disabled")
macros:Cancel(); macros.events.OnEvent(macros.events, "UNIT_LEVEL", "pet")
equal(macros.timer ~= nil, true, "pet level changes refresh native food eligibility")
macros:Cancel()
spells[136] = { secret = true }
equal(macros:Generate(pet, supplies:Scan()), nil, "secret spell names never enter macro text")
spells[136] = string.rep("M", 100)
equal(macros:Generate(pet, supplies:Scan()), nil, "long localized spell names fail safely at the body limit")
spells[136] = "Heilendes Tier"
equal(macros:Generate(pet, supplies:Scan()):find("Heilendes Tier", 1, true) ~= nil, true, "generated spells use the client's localized names")
spells[136], spells[34477] = "Mend Pet", nil
equal(macros:Save(redirect), false, "missing spell metadata does not replace a saved macro")
equal(native[redirectIndex].body, savedRedirect, "missing spell lookup preserves old misdirection text")
spells[34477] = "Misdirection"
playerClass = "MAGE"; macros:Refresh(); gui:RefreshMacros()
equal(#macros:Entries(), 5, "other classes hide hunter recipes even when retained in saved choices")
equal(gui.macroListScroll.suiteScrollBar:IsShown(), false, "short class-filtered lists hide their scrollbar")
equal(gui.macroListScroll.suiteOffset, 0, "shrinking the list clamps an obsolete scroll position")
equal(gui.macroListHeadings[2]:IsShown(), false, "class-filtered lists hide unused group headings")
equal(gui.macroSelected, alt.entries[1], "GUI selection cannot stay on an excluded class recipe")
equal(macros:Save(pet), false, "another class cannot explicitly rewrite a hunter macro")
equal(macros:Write(redirect, "/say changed", true), false, "write boundary rejects hidden class recipes")
equal(native[petIndex].body, petBody, "other-class refresh leaves the shared hunter macro unchanged")
playerClass = { secret = true }
equal(#macros:Entries(), 5, "unreadable class never exposes class-only entries")
local deferredClass = macros:Initialize(nil)
equal(#deferredClass.entries, 5, "unknown startup class creates only ordinary recipes")
playerClass = "HUNTER"; macros:SyncGeneral(); macros:SyncGeneral()
equal(#deferredClass.entries, 7, "late class availability adds each class recipe exactly once")
SetCombat(true)
equal(macros:Save(pet), false, "combat still blocks explicit class macro changes")
equal(native[petIndex].body, petBody, "combat cannot rewrite pet-care text")
SetCombat(false)
local limited = macros:Initialize(nil)
for i = 1, 9 do equal(macros:AddItem() ~= nil, true, "hunter retains each of the ten arbitrary item slots") end
gui.macroCollapsed["Item Macros"] = true; gui:RefreshMacros()
gui.macroAdd.OnClick()
equal(gui.macroCollapsed["Item Macros"], nil, "adding an item expands its collapsed category before revealing it")
equal(gui.macroSelected, limited.entries[17], "adding a custom item selects the new scroll-list entry")
equal(gui.macroListScroll.suiteOffset, gui.macroListScroll.suiteMaximum, "newly added items are revealed at the list bottom")
equal(gui.macroListHeadings[3].label.text, "− Item Macros", "custom item choices are grouped separately")
local selectedAtBottom = gui.macroSelected
gui:RefreshMacros()
equal(gui.macroSelected, selectedAtBottom, "ordinary refresh preserves the selected custom entry")
equal(gui.macroListScroll.suiteScrollBar.value, 1, "ordinary refresh preserves the list position")
local listHeight = gui.macroListContent.height
SetCombat(true); gui:RefreshMacros()
equal(gui.macroListContent.height, listHeight, "combat does not relayout list geometry")
equal(type(Suite.pending.macroListLayout), "function", "combat defers list layout through the existing queue")
SetCombat(false); Suite.pending.macroListLayout()
equal(Suite.pending.macroListLayout, nil, "deferred layout settles after combat")
equal(#limited.entries, 17, "class recipes do not reduce arbitrary item capacity")
equal(macros:AddItem(), nil, "hunter still enforces the ten-item cap")
gui.macroSelected = limited.entries[6]; gui:RefreshMacros()
equal(gui.macroChoose:IsShown(), false, "misdirection hides irrelevant item controls")
local fullListHeight, keptSelection, keptPreview = gui.macroListContent.height, gui.macroSelected, gui.macroPreviewBody
gui.macroListHeadings[1].OnClick()
equal(gui.macroListHeadings[1].label.text, "+ General", "collapsed category offers a visible expand indicator")
equal(gui.macroRows[1]:IsShown(), false, "collapsing General hides its recipe rows")
equal(gui.macroRows[6]:IsShown(), true, "collapsing General keeps Hunter recipes expanded")
equal(gui.macroListContent.height, fullListHeight - 260, "collapsed General removes its row space from the scroll range")
gui.macroListHeadings[2].OnClick()
equal(gui.macroRows[6]:IsShown(), false, "Hunter recipes collapse independently")
equal(gui.macroRows[8]:IsShown(), true, "custom items remain visible when other categories collapse")
equal(gui.macroSelected, keptSelection, "collapsing the selected category preserves the detail selection")
equal(gui.macroPreviewBody, keptPreview, "collapse does not change the generated macro preview")
equal(#limited.entries, 17, "collapse does not remove or change saved recipes")
gui.macroListHeadings[3].OnClick()
equal(gui.macroListScroll.suiteMaximum, 0, "collapsing all categories eliminates list overflow")
equal(gui.macroListScroll.suiteOffset, 0, "collapsing categories clamps obsolete scroll positions")
equal(gui.macroListScroll.suiteScrollBar:IsShown(), false, "all-collapsed categories hide the scrollbar")
equal(gui.macroListContent.height, 78, "the final collapsed header is fully included in the scroll child")
gui:RefreshMacros()
equal(gui.macroRows[1]:IsShown(), false, "ordinary refresh retains category collapse choices")
local collapsedHeight = gui.macroListContent.height
SetCombat(true); gui.macroListHeadings[1].OnClick()
equal(gui.macroListContent.height, collapsedHeight, "combat category clicks defer geometry changes")
SetCombat(false); Suite.pending.macroListLayout()
equal(gui.macroRows[1]:IsShown(), true, "deferred category expansion settles after combat")
equal(gui.macroRows[6]:IsShown(), false, "expanding General preserves the other category's collapsed state")
gui:Select("overview"); gui:Select("macros")
equal(gui.macroRows[6]:IsShown(), false, "category choices survive navigation within the login session")
gui.macroListHeadings[2].OnClick(); gui.macroListHeadings[3].OnClick()
equal(gui.macroListContent.height, fullListHeight, "expanding every category restores the full list range")
UnitClass, C_Spell, C_PetInfo, UnitExists, bags = oldUnitClass, oldSpellAPI, oldPetAPI, oldUnitExists, originalBags
native, Suite.db, Suite.macroDB = previousNative, previousDB, previousCharacter
macros.events.RegisterEvent, macros.events.UnregisterAllEvents = eventRegister, eventUnregister
macros:Cancel(); Flush()

