local Suite, equal, Frame, SetCombat = ...
local leveling, guides = Suite.ProfessionLeveling, Suite.ProfessionGuides
local saved, state = {}, {}
local globals = { "CreateFrame", "ProfessionsFrame", "C_TradeSkillUI", "Enum", "C_Timer", "UIParent", "GameTooltip", "GetCurrentRegion", "UnitFactionGroup", "UnitCastingInfo", "UnitChannelInfo" }
for _, name in ipairs(globals) do saved[name] = _G[name] end
for key, value in pairs(leveling) do state[key] = value end
local db, pending = Suite.db, Suite.pending
local scrollCount = #(Suite.GUI.scrollWidgets or {})
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
equal(Suite.db.professionLevelingAutoRecipe, true, "automatic recipe selection defaults on")
equal(Suite.InitializeDB({ professionLevelingAutoRecipe = false }).professionLevelingAutoRecipe, true, "legacy disabled recipe selection adopts on once")
equal(Suite.Profiles:Settings({ professionLevelingAutoRecipe = false }).professionLevelingAutoRecipe, true, "legacy profiles adopt recipe selection once")
equal(Suite.db.professionLevelingAutoRecipeVersion, 1, "default selection adoption has a marker")
local adopted = Suite.InitializeDB({ professionLevelingAutoRecipe = false })
adopted.professionLevelingAutoRecipe = false
equal(Suite.InitializeDB(adopted).professionLevelingAutoRecipe, false, "later disabled selection survives reload")
local adoptedProfile = Suite.Profiles:Settings({ professionLevelingAutoRecipe = false })
adoptedProfile.professionLevelingAutoRecipe = false
equal(Suite.Profiles:Settings(adoptedProfile).professionLevelingAutoRecipe, false, "later disabled selection survives profile normalization")
equal(Suite.Profiles:Settings({ professionLevelingAutoRecipe = false }, true).professionLevelingAutoRecipe, true, "legacy personal override adopts selection")
equal(Suite.Profiles:Settings({ professionLevelingAutoRecipe = false, professionLevelingAutoRecipeVersion = 1 }, true).professionLevelingAutoRecipe, false, "marked personal override preserves later opt-out")
equal(Suite.Profiles:Settings({}, true).professionLevelingAutoRecipe, nil, "empty personal overrides inherit profile choice")
local profiles = Suite.Profiles
local oldStore, oldState, oldID, oldPersonal, oldGUID = profiles.store, profiles.state, profiles.activeID, profiles.activePersonal, profiles.guid
profiles.store = { entries = { { id = "default", values = Suite.Profiles:Settings(Suite.db) } } }
profiles.state, profiles.activeID, profiles.activePersonal, profiles.guid = { overrides = {} }, "default", true, nil
Suite.db.professionLevelingAutoRecipe = false
profiles:SaveActive()
equal(profiles.state.overrides.default.professionLevelingAutoRecipeVersion, 1, "personal opt-out saves adoption marker even when equal to shared profile")
equal(profiles:Settings(profiles.state.overrides.default, true).professionLevelingAutoRecipe, false, "saved personal opt-out survives next load")
profiles.store, profiles.state, profiles.activeID, profiles.activePersonal, profiles.guid = oldStore, oldState, oldID, oldPersonal, oldGUID
Suite.db.professionLevelingAutoRecipe = false -- Exercise optional selection separately below.
equal(Suite.db.professionLevelingHideStocked, true, "shortage-only material view defaults on")
Suite.db.professionLevelingHideStocked = false -- Keep full reference visible for existing coverage.
equal(Suite.db.professionLevelingHideDone, true, "Hide Done defaults on")
equal(Suite.db.professionLevelingViewVersion, 1, "default adoption records a one-time version")
equal(Suite.InitializeDB({ professionLevelingHideDone = false }).professionLevelingHideDone, true, "legacy default switches to Hide Done once")
equal(Suite.InitializeDB({ professionLevelingHideDone = false, professionLevelingViewVersion = 1 }).professionLevelingHideDone, false, "later saved Show Done choice survives initialization")
equal(Suite.Profiles:Settings({ professionLevelingHideDone = false }).professionLevelingHideDone, true, "old settings profile adopts new default")
equal(Suite.Profiles:Settings({ professionLevelingHideDone = false, professionLevelingViewVersion = 1 }).professionLevelingHideDone, false, "upgraded profile retains explicit Show Done")
Suite.db.professionLevelingHideDone = false -- Exercise the full reference before testing filters.
UnitFactionGroup = function() return "Alliance" end
local timers, made, info = {}, 0
local function Widget(parent)
    local frame = Frame(); frame.parent = parent
    frame.IsForbidden = function(self) return self.forbidden or false end
    frame.SetSpacing = function(self, value) self.spacing = value end
    frame.SetFocus = function(self) self.focused = true; if self.OnEditFocusGained then self:OnEditFocusGained() end end
    frame.ClearFocus = function(self) self.focused = false end
    frame.HighlightText = function(self) self.highlighted = true end
    frame.CreateFontString = function(self) return Widget(self) end
    return frame
end
CreateFrame = function(_, _, parent)
    assert(not InCombatLockdown(), "profession guide frame creation must wait for combat")
    made = made + 1; return Widget(parent)
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { Cancel = function(self) self.cancelled = true end, callback = callback }
    timers[#timers + 1] = timer; return timer
end }
local function Flush()
    local work = timers; timers = {}
    for _, timer in ipairs(work) do if not timer.cancelled then timer.callback() end end
end
local function Pending()
    local work = Suite.pending; Suite.pending = {}
    for _, callback in pairs(work) do callback() end
end
UIParent = Widget(); UIParent:SetSize(1900, 1000)
Enum = { Profession = { Blacksmithing = 1, Alchemy = 3, FirstAid = 0 } }
C_TradeSkillUI = { GetBaseProfessionInfo = function() return info end }
ProfessionsFrame = Widget(); ProfessionsFrame:SetSize(782, 594); ProfessionsFrame:Show()
ProfessionsFrame.GetLeft = function() return 30 end
ProfessionsFrame.GetRight = function() return 812 end
ProfessionsFrame.CraftingPage = Widget(ProfessionsFrame); ProfessionsFrame.CraftingPage:Show()
ProfessionsFrame.CraftingPage.LinkButton = Widget(ProfessionsFrame.CraftingPage)
ProfessionsFrame.CraftingPage.CreateInternal = function() end
ProfessionsFrame.SetProfessionInfo = function() end
ProfessionsFrame.SelectBookPage = function() ProfessionsFrame.CraftingPage:Hide() end
local function Blacksmith(rank)
    info = { profession = 1, professionID = 164, professionName = "Blacksmithing", skillLevel = rank or 173, maxSkillLevel = 225 }
end
Blacksmith()
leveling:Apply()
equal(Suite.db.professionLeveling, false, "profession leveling starts off")
equal(made, 0, "disabled guide constructs nothing")
Suite.db.professionLeveling = true
local owner = ProfessionsFrame
ProfessionsFrame = nil
leveling:Apply()
equal(leveling.button, nil, "load-on-demand owner may be absent when enabled")
ProfessionsFrame = owner
leveling.events:OnEvent("ADDON_LOADED"); Flush()
equal(leveling.button.text, "Leveling", "native header launcher label")
equal(leveling.button.point[2], ProfessionsFrame.CraftingPage.LinkButton, "launcher follows native link without moving it")
equal(leveling.frame, nil, "content is lazy until clicked")
leveling.button:OnClick()
equal(leveling.frame:IsShown(), true, "explicit button opens companion")
equal(leveling.frame.parent, ProfessionsFrame, "companion inherits native movement and hiding")
equal(leveling.frame:GetWidth(), 460, "flyout widened for shopping lists")
equal(leveling.frame.scroll:GetWidth(), 410, "readable content uses wider panel")
equal(leveling.frame.text.point[3] < -500, true, "full shopping list precedes leveling prose")
equal(leveling.frame.materialLabels[1].text, "Required materials", "materials heading appears first")
equal(leveling.frame.materialRows[1].materialID, 2835, "first shopping item uses Rough Stone item ID")
equal(leveling.frame.materialRows[1].quantity.text, "90 x", "first quantity matches published list")
equal(leveling.frame.scroll.suiteMaximum > 500, true, "long materials list remains scrollable")
local shoppingCreated = made
leveling:Refresh()
equal(made, shoppingCreated, "same-guide updates reuse material widgets")
local function Material(id)
    for _, row in ipairs(leveling.frame.materialRows) do
        if row.materialID == id and row:IsShown() then return row end
    end
end
local function StepText()
    local text = { leveling.frame.text.text }
    for _, row in ipairs(leveling.frame.stepRows or {}) do
        if row:IsShown() then
            text[#text + 1] = row.heading.text
            if row.detail:IsShown() then text[#text + 1] = row.detail.text end
            for _, label in ipairs(row.estimateLabels or {}) do if label:IsShown() and row.expanded then text[#text + 1] = label.text end end
            for _, button in ipairs(row.recipeButtons or {}) do if button:IsShown() and row.expanded then text[#text + 1] = button.label.text end end
            for _, item in ipairs(row.estimateItems or {}) do if item:IsShown() and row.expanded then text[#text + 1] = item.label.text end end
        end
    end
    return table.concat(text, "\n")
end
local thorium = Material(12359)
equal(thorium.quantity.text, "1770 x", "top estimate sums recipe inputs without a quest allowance")
GetCurrentRegion = function() return 110 end
Suite.db.inventory.characters = {
    ["Guide-Alt-A"] = { name = "GuideAltA", realm = "Test", region = 110,
        bags = { items = { [12359] = 17 } }, bank = { items = { [12359] = 4 } } },
    ["Guide-Alt-B"] = { name = "GuideAltB", realm = "Test", region = 110,
        bags = { items = { [12359] = 2 } }, bank = { items = { [12359] = 30 } } },
}
Suite.db.inventory.accountBanks[110] = { items = { [12359] = 5 } }
leveling:Refresh()
equal(Material(2835).done, true, "skill 173 marks Rough Stone done")
equal(Material(2835).need.text, "Done", "past materials have no shopping shortage")
equal(Material(2841).done, true, "earlier bronze supplies marked done")
equal(Material(3575).done, false, "current iron band remains active")
equal(Material(12359).have.text, "58", "Have combines both characters and shared bank once")
equal(Material(12359).need.text, "1712", "Need subtracts all recorded stock from projected requirement")
equal(Material(3575).have.text, "0", "complete empty records are known zero")
equal(Material(3575).quantity.text, "24 x", "top iron quantity matches remaining step at 173")
equal(Material(3575).need.text, "24", "top shortage uses remaining whole-craft estimate")
equal(Material(2605).quantity.text, "4 x", "top dye quantity matches four remaining crafts")
Suite.db.inventory.characters["Guide-Alt-A"].bags.items[3575] = 10
Suite.db.inventory.characters["Guide-Alt-A"].bags.items[2605] = 2
leveling:Refresh()
equal(Material(3575).need.text, "14", "projected iron shortage subtracts recorded stock")
equal(Material(2605).need.text, "2", "projected dye shortage subtracts recorded stock")
Blacksmith(174); leveling:Refresh()
equal(Material(3575).quantity.text, "12 x", "top material estimate updates with current skill")
equal(Material(3575).need.text, "2", "top shortage updates with remaining crafts")
equal(Material(2605).need.text, "0", "existing dye covers next skill-point estimate")
equal(Material(2605).check:IsShown(), true, "stocked dye has a green check")
equal(Material(2605).check.texture, "Interface\\RaidFrame\\ReadyCheck-Ready", "stock mark uses native green ready check")
equal(Material(3575).check:IsShown(), false, "shortage has no success check")
leveling.frame.hideStocked:OnClick()
equal(Suite.db.professionLevelingHideStocked, true, "Hide Stocked preference saved")
equal(leveling.frame.hideStocked.text, "Show Stocked", "toggle offers restoring stocked materials")
equal(Material(2605), nil, "stocked dye removed from shopping view")
equal(Material(3575).need.text, "2", "shortage remains visible and unchanged")
local currentGuide = guides[leveling.current]
local fullRecipes = currentGuide.estimates
for _, recipe in ipairs(fullRecipes) do if recipe[1] == 170 then currentGuide.estimates = {recipe}; break end end
Suite.db.inventory.characters["Guide-Alt-A"].bags.items[3575] = 12
leveling:Refresh()
local emptyCovered = false
for _, label in ipairs(leveling.frame.materialLabels) do
    if label:IsShown() and label.text == "No materials to get in the current view." then emptyCovered = true end
end
equal(emptyCovered, true, "fully stocked plan explains empty shopping view")
currentGuide.estimates = fullRecipes
Suite.db.inventory.characters["Guide-Alt-A"].bags.items[3575] = 10
leveling.frame.hideStocked:OnClick()
equal(Material(2605).check:IsShown(), true, "Show Stocked restores checked reference")
Blacksmith(173)
Suite.db.inventory.characters["Guide-Alt-A"].bags.items[3575] = nil
Suite.db.inventory.characters["Guide-Alt-A"].bags.items[2605] = nil
leveling:Refresh()
equal(Material(2605).check:IsShown(), false, "recycled row clears success check when stock no longer covers estimate")
Suite.db.inventory.characters["Guide-Alt-A"].bags.items[3860] = 100
leveling:Refresh()
local repeatedMithril = 0
for _, row in ipairs(leveling.frame.materialRows) do
    if row.materialID == 3860 and not row.done then
        repeatedMithril = repeatedMithril + 1
        equal(row.have.text, "100", "repeated material displays actual owned total")
        equal(row.need.text, "482", "Need combines remaining 358 and 224 before subtracting stock")
    end
end
equal(repeatedMithril, 2, "both unfinished Mithril brackets included")
Suite.db.professionLevelingHideStocked = true; leveling:Refresh()
equal(Material(3860).need.text, "482", "shortage filter uses the whole plan rather than individually affordable rows")
Suite.db.professionLevelingHideStocked = false; leveling:Refresh()
local savedBank = Suite.db.inventory.characters["Guide-Alt-B"].bank
Suite.db.inventory.characters["Guide-Alt-B"].bank = nil
leveling:Refresh()
equal(Material(12359).have.text, "28+", "unrecorded bank gives known minimum stock")
equal(Material(12359).need.text, "≤1742", "partial storage gives upper projected shortage estimate")
Suite.db.inventory.characters["Guide-Alt-B"].bank = savedBank
local savedInventory = Suite.db.inventory
Suite.db.inventory = { schema = 1, characters = {}, accountBanks = {} }
leveling:Refresh()
equal(Material(12359).have.text, "?", "absent inventory is not asserted empty")
equal(Material(12359).need.text, "?", "absent inventory does not invent shortage")
Suite.db.inventory = savedInventory
Suite.db.inventory.characters["Guide-Alt-A"].bags.items[12359] = 3000
leveling:Refresh()
equal(Material(12359).need.text, "0", "surplus never produces negative Need")
Suite.db.inventory.characters["Guide-Alt-A"].bags.items[12359] = 17
Blacksmith(175); leveling:Refresh()
equal(Material(3575).done, true, "current materials become done at next skill band")
equal(Material(2605).need.text, "Done", "dye no longer suggested after bracers")
Blacksmith(173); leveling:Refresh()
local originalSummary = Suite.Inventory.Summary
Suite.Inventory.Summary = function() return { observed = true, total = {}, incomplete = false } end
equal(leveling:Stock(12359, 50), "?", "restricted count omitted before arithmetic")
Suite.db.professionLevelingHideStocked = true
leveling:Refresh()
equal(Material(12359) ~= nil, true, "unknown stock is never hidden as satisfied")
equal(Material(12359).check:IsShown(), false, "unknown stock is never checked")
Suite.db.professionLevelingHideStocked = false
Suite.Inventory.Summary = originalSummary
leveling:InventoryChanged(); leveling:InventoryChanged()
equal(#timers, 1, "inventory updates coalesce while guide open")
Flush()
equal(Material(12359).need.text, "1712", "inventory refresh updates projected shortage")
GameTooltip = Widget()
GameTooltip.SetOwner = function(self, row) self.owner = row end
GameTooltip.IsOwned = function(self, row) return self.owner == row end
GameTooltip.GetOwner = function(self) return self.owner end
local tooltipIDs = {}
GameTooltip.SetItemByID = function(self, id)
    tooltipIDs[#tooltipIDs + 1] = id; self.lines = {}; Suite.Tooltips.records[self] = nil
    -- Simulate the native item post-call through the real Suite tooltip pipeline.
    Suite.Tooltips:Item(self, { id = id })
end
thorium:OnEnter()
equal(tooltipIDs[#tooltipIDs], 12359, "hover uses exact native item ID")
equal(#GameTooltip.lines, 0, "hover preserves disabled inventory setting")
equal(Suite.db.itemInventory, false, "hover never enables recording or counts")
Suite.db.itemInventory = true
thorium:OnEnter()
local tooltipText = {}
for _, line in ipairs(GameTooltip.lines) do tooltipText[#tooltipText + 1] = table.concat(line, " ") end
tooltipText = table.concat(tooltipText, "\n")
equal(tooltipText:find("GuideAltA", 1, true) ~= nil, true, "material tooltip shows first recorded character")
equal(tooltipText:find("GuideAltB", 1, true) ~= nil, true, "material tooltip shows second recorded character")
equal(tooltipText:find("Bags:|r 17", 1, true) ~= nil, true, "material tooltip retains recorded bags count")
equal(tooltipText:find("Bank:|r 30", 1, true) ~= nil, true, "material tooltip retains recorded bank count")
local _, inventoryBlocks = tooltipText:gsub("Inventory", "")
equal(inventoryBlocks, 1, "existing pipeline appends inventory exactly once")
thorium:OnLeave()
equal(GameTooltip:IsShown(), false, "leaving material hides owned tooltip")
thorium:OnEnter(); GameTooltip.owner = Widget(); leveling:HideTooltip()
equal(GameTooltip:IsShown(), true, "guide never hides a tooltip acquired by another owner")
thorium:OnEnter(); leveling.frame.scroll:SetVerticalScroll(10)
equal(GameTooltip:IsShown(), false, "scrolling dismisses stale material tooltip")
local savedID = thorium.materialID
thorium.materialID = {}; local beforeHover = #tooltipIDs; thorium:OnEnter()
equal(#tooltipIDs, beforeHover, "restricted material ID never reaches tooltip API")
thorium.materialID = savedID
GameTooltip.forbidden = true; thorium:OnEnter()
equal(#tooltipIDs, beforeHover, "forbidden tooltip remains untouched")
GameTooltip.forbidden = false
local setItem = GameTooltip.SetItemByID
GameTooltip.SetItemByID = function() error("unavailable item tooltip") end
thorium:OnEnter()
equal(leveling.hovered, nil, "tooltip API rejection clears hover state")
GameTooltip.SetItemByID = setItem
thorium:OnEnter()
leveling:Select(7)
equal(GameTooltip:IsShown(), false, "changing guides dismisses previous material tooltip")
for _, row in ipairs(leveling.frame.materialRows) do
    equal(row:IsShown(), false, "gathering guide hides unused material rows")
    equal(row.materialID, nil, "hidden pooled row clears old ID")
end
leveling:Refresh(true)
equal(guides[leveling.selected].name, "Blacksmithing", "guide follows selected profession")
equal(leveling.frame.status.text, "Your skill: 173 / 225", "native rank shown")
equal(StepText():find("Current range  |  170%-175") ~= nil, true, "current blacksmithing band marked")
equal(StepText():find("24 x|r Iron Bar", 1, true) ~= nil, true, "current step estimates materials for remaining skill points")
equal(StepText():find("4 x|r Green Dye", 1, true) ~= nil, true, "step rounds crafts before multiplying dye quantity")
equal(StepText():find("estimated 4 crafts to 175", 1, true) ~= nil, true, "skill 173 estimates four crafts remaining")
equal(StepText():find("Bombus Finespindle", 1, true) ~= nil, true, "Alliance sees Alliance dye vendor")
equal(StepText():find("Tamar", 1, true), nil, "Alliance omits Horde dye vendor")
UnitFactionGroup = function() return "Horde" end
leveling:Refresh()
equal(StepText():find("Tamar", 1, true) ~= nil, true, "Horde sees Horde dye vendor")
equal(StepText():find("Bombus Finespindle", 1, true), nil, "Horde omits Alliance dye vendor")
UnitFactionGroup = function() return {} end
leveling:Refresh()
equal(StepText():find("Tamar", 1, true), nil, "restricted faction never guesses Horde directions")
equal(StepText():find("Bombus Finespindle", 1, true), nil, "restricted faction never guesses Alliance directions")
UnitFactionGroup = function() return "Alliance" end
leveling:Refresh()
local bracerEstimate = leveling:StepEstimates(guides[leveling.current], guides[leveling.current].sections[4], 174)[1]
equal(bracerEstimate.crafts, 2, "one remaining skill point rounds whole expected crafts upward")
equal(bracerEstimate.materials[1].count, 12, "one-point iron estimate preserves six bars per craft")
local fullBracers = leveling:StepEstimates(guides[leveling.current], guides[leveling.current].sections[4], nil)[1]
equal(fullBracers.crafts, 9, "unrelated/unknown rank keeps whole-band reference")
equal(fullBracers.materials[1].count, 54, "full-band iron reference remains 54")
local stepIron = leveling.frame.stepRows[4].estimateItems[1]
equal(stepIron.materialID, 3575, "step material uses sourced item ID")
stepIron:OnEnter()
equal(tooltipIDs[#tooltipIDs], 3575, "step ingredient uses ordinary item tooltip")
stepIron:OnLeave()
local recipeRequests = {}
local nativeRecipe = { recipeID = 3501, name = "Localized Green Iron Bracers", learned = true }
local recipeBelongs, recipeLoading, recipeRejected, shiftOnRead = true, false, false, false
C_TradeSkillUI.GetRecipeInfo = function(id)
    equal(id, 3501, "click looks up exact sourced bracer recipe ID")
    if shiftOnRead then info = { profession = 3, professionID = 171, professionName = "Alchemy", skillLevel = 50, maxSkillLevel = 75 } end
    return nativeRecipe
end
C_TradeSkillUI.IsRecipeInSkillLine = function(id, skillLine)
    equal(id, 3501, "native membership checks exact recipe")
    equal(skillLine, 164, "native membership checks open profession skill line")
    return recipeBelongs
end
C_TradeSkillUI.IsDataSourceChanging = function() return recipeLoading end
C_TradeSkillUI.OpenRecipe = function(id)
    assert(not InCombatLockdown(), "recipe selection never runs in combat")
    if recipeRejected then error("native request rejected") end
    recipeRequests[#recipeRequests + 1] = id
end
C_TradeSkillUI.CraftRecipe = function() error("guide must never craft") end
leveling:Refresh()
local recipeButton = leveling.frame.stepRows[4].recipeButtons[1]
equal(recipeButton.recipeID, 3501, "render binds sourced recipe ID to clickable name")
equal(recipeButton.enabled, true, "matching open profession enables recipe button")
recipeButton:OnClick("LeftButton")
equal(recipeRequests[1], 3501, "click requests native recipe opening")
nativeRecipe.learned = false
recipeButton:OnClick("LeftButton")
equal(#recipeRequests, 2, "unlearned recipe preview is left to native opening rules")
nativeRecipe.learned = true
recipeButton:OnClick("RightButton")
equal(#recipeRequests, 2, "right-click does not select a recipe")
recipeLoading = true; recipeButton:OnClick("LeftButton"); recipeLoading = false
equal(#recipeRequests, 2, "loading profession cannot receive selection request")
recipeBelongs = false; recipeButton:OnClick("LeftButton"); recipeBelongs = true
equal(#recipeRequests, 2, "wrong profession membership cannot select")
nativeRecipe.recipeID = {}; recipeButton:OnClick("LeftButton"); nativeRecipe.recipeID = 3501
equal(#recipeRequests, 2, "restricted native recipe ID cannot select")
local savedNativeRecipe = nativeRecipe
nativeRecipe = nil; recipeButton:OnClick("LeftButton"); nativeRecipe = savedNativeRecipe
equal(#recipeRequests, 2, "unavailable metadata never replays a click")
shiftOnRead = true; recipeButton:OnClick("LeftButton"); shiftOnRead = false
equal(#recipeRequests, 2, "profession change during metadata lookup cancels the click")
Blacksmith(173); leveling:Refresh(true)
recipeRejected = true; recipeButton:OnClick("LeftButton"); recipeRejected = false
equal(#recipeRequests, 2, "native selection error is contained without retries")
local openRecipe = C_TradeSkillUI.OpenRecipe
C_TradeSkillUI.OpenRecipe = nil; leveling:Refresh()
equal(recipeButton.enabled, false, "missing selection capability disables recipe button")
recipeButton:OnClick("LeftButton")
equal(#recipeRequests, 2, "missing native opening API cannot select")
C_TradeSkillUI.OpenRecipe = openRecipe
leveling:Refresh()
ProfessionsFrame.forbidden = true; recipeButton:OnClick("LeftButton"); ProfessionsFrame.forbidden = false
equal(#recipeRequests, 2, "forbidden profession frame cannot receive selection")
SetCombat(true); recipeButton:OnClick("LeftButton"); SetCombat(false); Flush()
equal(#recipeRequests, 2, "combat click is not queued for later")
leveling:ToggleStep(4)
equal(recipeButton.recipeID, nil, "collapsed step clears stale recipe binding")
recipeButton:OnClick("LeftButton")
equal(#recipeRequests, 2, "collapsed recipe callback is inert")
leveling:ToggleStep(4)
local boundGuide = recipeButton.guideIndex
recipeButton.guideIndex = 1; recipeButton:OnClick("LeftButton"); recipeButton.guideIndex = boundGuide
equal(#recipeRequests, 2, "unrelated browsed guide cannot switch professions")
C_TradeSkillUI.GetRecipeInfo, C_TradeSkillUI.IsRecipeInSkillLine, C_TradeSkillUI.OpenRecipe = nil, nil, nil
C_TradeSkillUI.IsDataSourceChanging, C_TradeSkillUI.CraftRecipe = nil, nil
leveling:Refresh(true)
equal(Suite.db.professionLevelingAutoSteps, true, "automatic step folding starts on")
equal(Suite.db.professionLevelingHideDone, false, "explicit Show Done remains available after default adoption")
for index, row in ipairs(leveling.frame.stepRows) do
    equal(row.expanded, index == 4, "skill 173 expands only its current section")
end
leveling.frame.stepRows[1].header:OnClick()
equal(leveling.frame.stepRows[1].expanded, true, "earlier step header can expand manually")
equal(leveling.frame.stepRows[4].expanded, true, "opening one header preserves current section")
leveling:Refresh()
equal(leveling.frame.stepRows[1].expanded, true, "inventory/context refresh retains manual expansion")
leveling.frame.scroll.suiteOffset = leveling.frame.scroll.suiteMaximum
leveling.frame.scroll:SetVerticalScroll(leveling.frame.scroll.suiteMaximum)
leveling.frame.stepRows[4].header:OnClick()
equal(leveling.frame.stepRows[4].expanded, false, "current section can be collapsed explicitly")
equal(leveling.frame.scroll.verticalScroll <= leveling.frame.scroll.suiteMaximum, true, "collapse clamps native scroll to shortened content")
leveling.frame.autoSteps:OnClick()
equal(Suite.db.professionLevelingAutoSteps, false, "Auto steps toggle saves preference")
for _, row in ipairs(leveling.frame.stepRows) do equal(row.expanded, true, "Auto steps Off restores all details") end
leveling.frame.autoSteps:OnClick()
equal(leveling.frame.stepRows[4].expanded, true, "Auto steps On returns to current range")
equal(leveling.frame.stepRows[1].expanded, false, "Auto steps On clears manual overrides")
local originalShortage = Material(3860).need.text
Material(2835):OnEnter()
leveling.frame.hideDone:OnClick()
equal(Suite.db.professionLevelingHideDone, true, "Hide Done preference saved")
equal(leveling.frame.hideDone.text, "Show Done", "toggle offers restoring hidden rows")
equal(GameTooltip:IsShown(), false, "hiding Done clears old hovered tooltip")
equal(Material(2835), nil, "Hide Done removes completed rough stone")
equal(Material(2841), nil, "Hide Done removes completed bronze")
equal(Material(3575) ~= nil, true, "Hide Done preserves current materials")
equal(Material(3860).need.text, originalShortage, "filter does not change aggregated stock or Need")
local oldBracketShown = false
for _, label in ipairs(leveling.frame.materialLabels) do
    if label:IsShown() and label.text == "1-150" then oldBracketShown = true end
end
equal(oldBracketShown, false, "empty completed bracket heading removed")
info.skillLevel = {}; leveling:Refresh()
equal(Material(2835) ~= nil, true, "unknown rank never filters materials as completed")
Blacksmith(173); leveling:Refresh()
leveling.frame.hideDone:OnClick()
equal(Material(2835).need.text, "Done", "Show Done restores completed reference")
Blacksmith(175); leveling:Refresh()
equal(leveling.frame.stepRows[4].expanded, false, "previous current range folds on skill transition")
equal(leveling.frame.stepRows[5].expanded, true, "new current range opens on skill transition")
Blacksmith(173); leveling:Refresh()
equal(leveling.frame.point[3], "TOPRIGHT", "roomy layout docks on right beyond tabs")
equal(leveling.frame.point[4], 58, "right dock clears side tabs")
equal(leveling.frame.source.focused, false, "opening does not steal keyboard focus")
leveling.frame.sourceButton:OnClick()
equal(leveling.frame.source.focused, true, "source button focuses selectable URL")
equal(leveling.frame.source.highlighted, true, "URL selected for native copy")
equal(leveling.url, "https://www.wow-professions.com/forever/blacksmithing-leveling-guide", "Forever source rather than Classic")
leveling.frame.source.text = "https://untrusted.invalid/"
leveling.frame.source:OnTextChanged()
equal(leveling.frame.source.text, leveling.url, "source field rejects edits")
leveling.frame.source.text = {}
leveling.frame.source:OnTextChanged()
equal(leveling.frame.source.text, leveling.url, "restricted source-field input restored")
local firstText = StepText()
leveling:Select(1)
equal(guides[leveling.selected].name, "Alchemy", "manual library browsing")
equal(leveling.frame.status.text:find("Your skill", 1, true), nil, "manual guide does not inherit other skill rank")
leveling:Refresh(true)
equal(StepText(), firstText, "Current returns to active profession")
local retainedScroll = 47
leveling.frame.scroll.suiteOffset = retainedScroll
leveling.frame.scroll:SetVerticalScroll(retainedScroll)
leveling:Refresh()
equal(leveling.frame.scroll.verticalScroll, retainedScroll, "same-context updates preserve scrolling")
info.skillLevel = 175
leveling:Queue(); leveling:Queue()
equal(#timers, 1, "profession updates coalesce")
Flush()
equal(StepText():find("Current range  |  175%-195") ~= nil, true, "rank updates current range")
info = { profession = 3, professionID = 171, professionName = "Localized alchemy", skillLevel = 50, maxSkillLevel = 75 }
ProfessionsFrame:SetProfessionInfo()
Flush()
equal(guides[leveling.selected].name, "Alchemy", "profession switch resolves localized name through enum")
equal(leveling.frame.scroll.verticalScroll, 0, "profession switch resets scroll")
equal(leveling.frame.source.text:find("/alchemy-leveling-guide", 1, true) ~= nil, true, "profession switch changes source")
info = { profession = 0, professionID = 129, professionName = "First Aid", skillLevel = 1, maxSkillLevel = 75 }
leveling:Refresh()
equal(guides[leveling.selected].name, "First Aid", "zero enum is valid")
info = { profession = {}, professionID = 9999, professionName = "Unknown", skillLevel = {}, maxSkillLevel = 75 }
leveling:Refresh()
equal(leveling.selected, nil, "unknown profession never displays previous guide as current")
equal(leveling.url, nil, "unknown profession clears stale source")
equal(leveling.frame.text.text:find("No summary", 1, true) ~= nil, true, "unknown profession explained")
leveling.frame.nextGuide:OnClick()
equal(guides[leveling.selected].name, "Blacksmithing", "unknown context can still browse summaries")
Blacksmith(); info.skillLevel = {}; leveling:Refresh(true)
equal(leveling.rank, nil, "restricted rank omitted before arithmetic")
equal(StepText():find("Current range", 1, true), nil, "restricted rank never labels current band")
info.skillLevel, info.maxSkillLevel = 226, 225; leveling:Refresh()
equal(leveling.rank, nil, "impossible rank omitted")
for _, row in ipairs(leveling.frame.stepRows) do
    if row:IsShown() then equal(row.expanded, true, "unknown rank never hides route details automatically") end
end
info = nil; leveling:Refresh()
equal(leveling.context, "unavailable", "missing native data distinguished")
equal(leveling.url, nil, "missing data clears stale guide")
local getInfo = C_TradeSkillUI.GetBaseProfessionInfo
C_TradeSkillUI.GetBaseProfessionInfo = function() error("unavailable") end
leveling:Refresh()
equal(leveling.url, nil, "native API failure cannot retain stale source")
C_TradeSkillUI.GetBaseProfessionInfo = getInfo
Blacksmith(); leveling:Refresh()
ProfessionsFrame.GetLeft = function() return 1300 end
ProfessionsFrame.GetRight = function() return 1782 end
leveling:Place()
equal(leveling.frame.point[3], "TOPLEFT", "dock flips left at right screen edge")
equal(leveling.frame.clamped, true, "flyout clamps when neither side fits")
ProfessionsFrame:SelectBookPage(); Flush()
equal(leveling.current, nil, "overview has no stale active profession")
equal(leveling.button.point[1], "TOPRIGHT", "overview keeps a launcher for gathering guides")
for index, guide in ipairs(guides) do
    leveling:Select(index)
    equal(leveling.frame.source.text, guide.url, guide.name .. " accessible from overview")
    equal(guide.url:find("https://www.wow-professions.com/forever/", 1, true), 1, guide.name .. " uses Forever source")
    local words = guide.name .. " " .. guide.note
    for _, section in ipairs(guide.sections) do
        equal(section[1] < section[2], true, guide.name .. " valid skill band")
        words = words .. " " .. section[3] .. " " .. section[4] .. " " .. (section[5] or "") .. " " .. (section[6] or "")
    end
    local count = 0; for _ in words:gmatch("%S+") do count = count + 1 end
    equal(count <= 200, true, guide.name .. " remains a concise original summary")
    if guide.shopping then
        for _, group in ipairs(guide.shopping) do
            equal(type(group.endSkill), "number", "shopping bracket has a validated completion boundary")
            for _, row in ipairs(group.rows) do
                equal(type(row.endSkill) == "number" and row.endSkill > 0, true, "shopping row has an explicit last-use boundary")
                for _, choice in ipairs({row, row.alternative or {}}) do
                    for _, item in ipairs(choice) do
                        equal(type(item[1]) == "number" and item[1] > 0 and item[1] % 1 == 0, true, "material quantity is a positive whole estimate")
                        equal(type(item[2]) == "number" and item[2] > 0 and item[2] % 1 == 0, true, "every material alternative has an item ID")
                    end
                end
            end
        end
    end
    for _, recipe in ipairs(guide.estimates or {}) do
        equal(recipe[1] < recipe[2] and recipe[3] > 0 and recipe[3] % 1 == 0, true, guide.name .. " estimate uses valid band and whole crafts")
        equal(type(recipe.recipeID) == "number" and recipe.recipeID > 0 and recipe.recipeID % 1 == 0, true, guide.name .. " recipe has sourced numeric selection ID")
        for _, material in ipairs(recipe[5]) do
            equal(type(material[2]) == "string" and material[1] > 0 and material[1] % 1 == 0, true, guide.name .. " recipe has whole reagent quantities")
        end
    end
end
local function Guide(name) for _, guide in ipairs(guides) do if guide.name == name then return guide end end end
local hidden = Suite.db.professionLevelingHideDone
Suite.db.professionLevelingHideDone = true
local function ProjectedCount(guide, rank, name)
    local _, _, shopping = leveling:MaterialPlan(guide, rank)
    local count = 0
    for _, group in ipairs(shopping or {}) do
        for _, row in ipairs(group.rows) do
            if not row.completed then for _, item in ipairs(row) do if item[3] == name then count = count + item[1] end end end
        end
    end
    return count
end
equal(ProjectedCount(Guide("Blacksmithing"), 173, "Iron Bar"), 24, "top and step share rounded current-recipe calculation")
equal(ProjectedCount(Guide("Blacksmithing"), 220, "Mithril Bar"), 304, "top projects the current recipe within a multi-recipe band plus future uses")
equal(ProjectedCount(Guide("Blacksmithing"), 173, "Solid Grinding Stone"), 0, "planned grinding outputs cover later axes without duplicate shopping")
equal(ProjectedCount(Guide("Blacksmithing"), 180, "Solid Grinding Stone"), 6, "completed production is not assumed still in inventory")
equal(ProjectedCount(Guide("Alchemy"), 130, "Fire Oil"), 0, "two oils per craft cover future fire-power ingredients")
equal(ProjectedCount(Guide("Alchemy"), 145, "Fire Oil"), 20, "partial remaining production leaves only uncovered intermediate demand")
equal(ProjectedCount(Guide("Alchemy"), 145, "Firefin Snapper"), 10, "top keeps raw inputs required for planned intermediate production")
equal(ProjectedCount(Guide("Blacksmithing"), nil, "Iron Bar"), 54, "unknown rank retains full modeled reference")
equal(ProjectedCount(Guide("Cooking"), 280, "Raw Sunscale Salmon"), 28, "cooking gains a top list from its remaining-step model")
equal(#leveling:StepEstimates(Guide("Alchemy"), Guide("Alchemy").sections[4], 295), 0, "unfinished alchemy endgame has no invented estimate")
equal(#leveling:StepEstimates(Guide("Tailoring"), Guide("Tailoring").sections[6], 275), 0, "unfinished tailoring endgame has no invented estimate")
equal(#leveling:StepEstimates(Guide("Blacksmithing"), Guide("Blacksmithing").sections[4], 175), 0, "finished recipe removes its step estimate")
local unknownEstimates = leveling:StepEstimates(Guide("Blacksmithing"), Guide("Blacksmithing").sections[4], {})
equal(unknownEstimates[1].crafts, 9, "restricted rank cannot enter step arithmetic")
Suite.db.professionLevelingHideDone = hidden
equal(#Guide("Blacksmithing").shopping[1].rows, 8, "all early blacksmithing source rows present")
equal(#Guide("Blacksmithing").shopping[2].rows, 12, "all middle blacksmithing source rows present")
equal(#Guide("Blacksmithing").shopping[3].rows, 7, "all late blacksmithing source rows present")
equal(#Guide("Alchemy").shopping[1].rows[7], 2, "alchemy primary alternative bundle preserves both ingredients")
equal(#Guide("Alchemy").shopping[1].rows[7].alternative, 2, "alchemy replacement bundle preserves both ingredients")
equal(#Guide("Leatherworking").shopping[1].rows[6].alternative, 4, "hide replacement retains four components")
equal(Guide("Tailoring").shopping[3].title, "225-265", "unpublished tailoring materials are never invented")
equal(Guide("Alchemy").shopping[2].title, "225-290", "alchemy shopping list discloses true published coverage")
equal(Guide("First Aid").shopping[2].rows[3][1][2], 13464, "first aid includes late healing-potion herb")
-- Browsing another profession cannot apply the active blacksmith's skill.
leveling:Select(1)
for _, row in ipairs(leveling.frame.materialRows) do
    if row.materialID then equal(row.done, false, "manual other-profession guide has no assumed rank") end
end
Suite.db.inventory.characters["Guide-Alt-A"].bags.items[785] = 50
leveling:Refresh()
local mageroyalNeeds = {}
for _, row in ipairs(leveling.frame.materialRows) do
    if row.materialID == 785 then mageroyalNeeds[#mageroyalNeeds + 1] = row.need.text end
end
equal(mageroyalNeeds[1], "0", "main ingredient stock satisfies main-route total")
equal(#mageroyalNeeds, 1, "projected shopping uses the chosen primary step route rather than mixing alternative routes")
leveling:Refresh(true)
equal(#guides, 14, "profession, lockpicking and camping summaries available")
leveling:Select(0); equal(leveling.selected, #guides, "previous wraps library")
leveling:Select(#guides + 1); equal(leveling.selected, 1, "next wraps library")
local size = made
SetCombat(true)
leveling.events:OnEvent("PLAYER_REGEN_DISABLED")
local hidePreference = Suite.db.professionLevelingHideDone
local autoPreference = Suite.db.professionLevelingAutoSteps
local stockedPreference = Suite.db.professionLevelingHideStocked
leveling.frame.hideStocked:OnClick()
equal(Suite.db.professionLevelingHideStocked, stockedPreference, "combat cannot alter stocked filter")
leveling.frame.hideDone:OnClick(); leveling.frame.autoSteps:OnClick(); leveling:ToggleStep(1)
equal(Suite.db.professionLevelingHideDone, hidePreference, "combat cannot alter material filter")
equal(Suite.db.professionLevelingAutoSteps, autoPreference, "combat cannot alter folding preference")
local combatTooltipCount = #tooltipIDs
leveling:ItemTooltip(leveling.frame.materialRows[1])
equal(#tooltipIDs, combatTooltipCount, "combat does not open material tooltips")
leveling:Toggle(); leveling:Select(2); leveling:Apply(); leveling:Queue()
equal(made, size, "combat performs no UI construction")
equal(leveling.open, nil, "combat cancels open intent")
equal(Suite.pending.professionLevelingApply ~= nil, true, "combat layout defers")
SetCombat(false); Pending(); Flush()
equal(leveling.frame:IsShown(), false, "combat exit does not reopen cancelled guide")
leveling:Toggle()
leveling:Queue()
ProfessionsFrame:OnHide()
equal(leveling.timer, nil, "native hide cancels queued refresh")
equal(leveling.frame:IsShown(), false, "native hide dismisses flyout")
Flush(); leveling:Toggle()
-- Follow native skill boundaries even with the flyout closed; never start a craft.
equal(Suite.db.professionLevelingAutoRecipe, false, "automatic recipe selection can be disabled")
local autoRequests, learned, canSkillUp, loading, rejects, cast = {}, true, true, false, false, nil
UnitCastingInfo = function() return cast end
UnitChannelInfo = function() return nil end
C_TradeSkillUI.GetRecipeInfo = function(id) return { recipeID = id, learned = learned, canSkillUp = canSkillUp } end
C_TradeSkillUI.IsRecipeInSkillLine = function(_, skill) return skill == 164 end
C_TradeSkillUI.IsDataSourceChanging = function() return loading end
C_TradeSkillUI.OpenRecipe = function(id)
    assert(not InCombatLockdown(), "automatic selection must stay out of combat")
    autoRequests[#autoRequests + 1] = id
    leveling:Queue() -- Native selection feeds list-update events back to us.
    if rejects then error("native request rejected") end
end
C_TradeSkillUI.CraftRecipe = function() error("automatic selection must never craft") end
Blacksmith(173); ProfessionsFrame.CraftingPage:Show(); leveling:Close(); ProfessionsFrame:OnShow(); Flush()
equal(#autoRequests, 0, "opening does not auto-select with option off")
Suite.db.professionLevelingAutoRecipe = true; leveling:Apply(); Flush()
equal(autoRequests[1], 3501, "enabling selects current Green Iron Bracers with guide closed")
equal(leveling.open, nil, "automatic selection does not open flyout")
Flush(); leveling:Refresh(); Blacksmith(174); leveling:Refresh()
equal(#autoRequests, 1, "feedback and skill gains within a recipe preserve manual choices")
ProfessionsFrame.CraftingPage:CreateInternal()
Blacksmith(175); leveling:Refresh()
equal(#autoRequests, 1, "step boundary waits for manually started batch")
leveling.events:OnEvent("UPDATE_TRADESKILL_CAST_STOPPED", false); Flush()
equal(autoRequests[2], 9920, "batch completion selects next Solid Grinding Stone recipe")
Flush(); equal(#autoRequests, 2, "next-recipe feedback does not loop")
ProfessionsFrame:OnHide(); ProfessionsFrame:OnShow(); Flush()
equal(#autoRequests, 3, "reopening selects the current recipe anew")
Blacksmith(173); learned = false; leveling:Refresh()
equal(#autoRequests, 3, "automatic path never previews unlearned recipes")
learned = true; canSkillUp = false; leveling:Refresh()
equal(#autoRequests, 3, "automatic path skips grey recipes")
canSkillUp = true; loading = true; leveling:Refresh()
equal(#autoRequests, 3, "loading data cannot trigger selection")
loading = false; cast = "Craft"; leveling:Refresh()
equal(#autoRequests, 3, "player cast blocks automatic changes")
cast = nil; leveling:Refresh()
equal(#autoRequests, 4, "ready data can resolve pending current recipe")
Blacksmith(175); rejects = true; leveling:Refresh(); Flush(); leveling:Refresh()
equal(#autoRequests, 5, "native rejection is attempted only once per target")
rejects = false
SetCombat(true); leveling.events:OnEvent("PLAYER_REGEN_DISABLED"); Blacksmith(180)
SetCombat(false); leveling.events:OnEvent("PLAYER_REGEN_ENABLED"); Pending(); Flush()
equal(#autoRequests, 5, "combat exit cannot replay automatic selection")
ProfessionsFrame:OnHide(); ProfessionsFrame:OnShow(); Flush()
equal(#autoRequests, 6, "reopening after combat resumes automatic selection")
Suite.db.professionLevelingAutoRecipe = false; leveling:Refresh(); Blacksmith(173); leveling:Refresh()
equal(#autoRequests, 6, "disabling optional selection stops following skill")
equal(Suite.Profiles:Settings({ professionLevelingAutoRecipe = true }).professionLevelingAutoRecipe, true, "auto-selection participates in settings profiles")
C_TradeSkillUI.OpenRecipe, C_TradeSkillUI.GetRecipeInfo, C_TradeSkillUI.IsRecipeInSkillLine = nil, nil, nil
Suite.db.professionLeveling = false
leveling:Apply()
equal(leveling.button:IsShown(), false, "disable removes launcher")
equal(leveling.frame:IsShown(), false, "disable closes companion")
local disabled = made
ProfessionsFrame:OnShow(); Flush()
equal(made, disabled, "retained native hooks inert when off")
Suite.db.professionLeveling = {}; leveling:Apply()
equal(leveling:Enabled(), false, "restricted setting stays off")
Suite.db.professionLeveling = true
ProfessionsFrame.forbidden = true
leveling:Discover()
equal(made, disabled, "forbidden owner never modified")
ProfessionsFrame.forbidden = false
equal(Suite.Profiles:Settings(Suite.db).professionLeveling, true, "guide switch included in ordinary settings profiles")
equal(Suite.Profiles:Settings(Suite.db).professionLevelingHideDone, false, "material filter participates in settings profiles")
equal(Suite.Profiles:Settings(Suite.db).professionLevelingAutoSteps, true, "automatic folding participates in settings profiles")
equal(Suite.Profiles:Settings(Suite.db).professionLevelingHideStocked, false, "stocked filter participates in settings profiles")
local found = Suite.SettingsCatalog:Search("blacksmithing")
equal(#found > 0, true, "profession guides discoverable through settings search")
leveling:Cancel()
while Suite.GUI.scrollWidgets and #Suite.GUI.scrollWidgets > scrollCount do table.remove(Suite.GUI.scrollWidgets) end
for key in pairs(leveling) do leveling[key] = nil end
for key, value in pairs(state) do leveling[key] = value end
for _, name in ipairs(globals) do _G[name] = saved[name] end
Suite.db, Suite.pending = db, pending
SetCombat(false)
