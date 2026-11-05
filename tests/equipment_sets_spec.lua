local Suite, equal, Frame, SetCombat = ...
local sets = Suite.EquipmentSets
local oldDB, oldPending = Suite.db, Suite.pending
local oldPaper, oldAPI, oldUpdate, oldPopup = PaperDollFrame, C_EquipmentSet, PaperDollItemSlotButton_Update, GearManagerPopupFrame
local oldCreate = CreateFrame
local originals, ignored, writes, updates = {}, {}, {}, 0
local names = { "HeadSlot", "NeckSlot", "ShoulderSlot", "ShirtSlot", "ChestSlot", "WaistSlot", "LegsSlot", "FeetSlot",
    "WristSlot", "HandsSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot", "BackSlot", "TabardSlot" }
local ids = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 19 }
for _, name in ipairs(names) do originals[name] = _G["Character" .. name]; _G["Character" .. name] = Frame() end
local pane = Frame(); pane:Show(); pane.selectedSetID = 0
pane.SaveSet = Frame(); pane.SaveSet.Enable = function(self) self.enabled = true end
local model, itemLayer = Frame(), Frame()
model:SetFrameLevel(50); itemLayer:SetFrameLevel(100)
PaperDollFrame = { EquipmentManagerPane = pane, CharacterModelScene = model, ItemsFrame = itemLayer }
GearManagerPopupFrame = Frame()
PaperDollItemSlotButton_Update = function() updates = updates + 1 end
local restricted = { secret = true }
C_EquipmentSet = {
    GetEquipmentSetInfo = function(id) if id == 0 then return "Test set", 1, id end end,
    IsSlotIgnoredForSave = function(id) if ignored[id] == restricted then return restricted end; return ignored[id] == true end,
    IgnoreSlotForSave = function(id) assert(not InCombatLockdown()); ignored[id] = true; writes[#writes + 1] = id end,
    UnignoreSlotForSave = function(id) assert(not InCombatLockdown()); ignored[id] = false; writes[#writes + 1] = id end,
}
local created = 0
CreateFrame = function(...)
    assert(not InCombatLockdown(), "equipment manager widget creation defers in combat")
    created = created + 1
    return oldCreate(...)
end
SetCombat(false); Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
equal(Suite.db.equipmentSetToggle, false, "equipment slot toggle defaults off")
sets:Apply(); equal(sets.button, nil, "disabled feature creates no button")
Suite.db.equipmentSetToggle = true
SetCombat(true); sets:Apply(); equal(created, 0, "first enable defers all frames")
SetCombat(false); Suite.pending.equipmentSetApply(); equal(sets.button.parent, pane, "toggle visibility follows equipment pane")
equal(sets.button.point[3], "BOTTOMLEFT", "toggle sits beside lower-right character equipment area")
equal(sets.button.enabled, true, "zero equipment set ID is valid")
equal(sets.button:IsShown(), true, "existing selected set reveals control")
equal(sets.button:GetFrameLevel() > model:GetFrameLevel(), true, "button draws above model background")
equal(sets.button:GetFrameLevel() > itemLayer:GetFrameLevel(), true, "button draws above equipment artwork")
ignored[0], ignored[16], ignored[17], ignored[18], ignored[20] = true, false, true, false, true
ignored[4] = true -- Mixed selections always converge to ignored first.
sets.button.OnClick()
equal(#writes, 16, "all sixteen eligible slots change once")
equal(updates, 16, "native markers refresh once per eligible slot")
for index, id in ipairs(ids) do
    equal(writes[index], id, "explicit equipment allowlist order")
    equal(ignored[id], true, "mixed selection becomes ignored")
    equal(_G["Character" .. names[index]].ignored, true, "native ignore marker matches pending save")
end
equal(pane.SaveSet.enabled, true, "changes enable native Save")
equal(sets.label.text, "+", "all ignored offers include")
sets.button.OnClick()
equal(#writes, 32, "second click includes the same slots")
for index, id in ipairs(ids) do
    equal(ignored[id], false, "second click includes every eligible slot")
    equal(_G["Character" .. names[index]].ignored, nil, "include clears native marker")
end
for _, id in ipairs({ 0, 16, 17, 18, 20 }) do
    equal(ignored[id], id == 0 or id == 17 or id == 20, "weapons ammo and bags retain their original state")
end
local before = #writes
SetCombat(true); sets:Toggle(); equal(#writes, before, "combat click changes nothing")
SetCombat(false)
ignored[15] = restricted; sets:Refresh(); equal(sets.button.enabled, false, "restricted slot state disables toggle")
sets:Toggle(); equal(#writes, before, "preflight prevents partial mutation on restricted state")
ignored[15] = false
local head = CharacterHeadSlot; CharacterHeadSlot = nil; sets:Toggle()
equal(#writes, before, "missing native widget prevents partial mutation")
CharacterHeadSlot = head
pane.selectedSetID = nil; sets:Refresh(); equal(sets.button.enabled, false, "no selected set disables toggle")
equal(sets.button:IsShown(), false, "no selected set hides control from navigation")
GearManagerPopupFrame:Show(); sets:Refresh(); equal(sets.button.enabled, false, "new set editor cannot enable toggle")
equal(sets.button:IsShown(), false, "new set editor cannot reveal toggle before selection")
sets:Toggle(); equal(#writes, before, "new set editor cannot modify slots")
pane.selectedSetID = 99; sets:Refresh()
equal(sets.button:IsShown(), false, "stale deleted selection cannot reveal control")
pane.selectedSetID = restricted; sets:Refresh()
equal(sets.button:IsShown(), false, "restricted selection cannot reveal control")
GearManagerPopupFrame:Hide(); pane.selectedSetID = 0
sets:Refresh(); equal(sets.button:IsShown(), true, "selecting existing set reveals control again")
pane:Hide(); sets:Toggle(); equal(#writes, before, "hidden pane cannot mutate slots")
pane:Show(); Suite.db.equipmentSetToggle = false; sets:Apply()
equal(sets.button:IsShown(), false, "disable hides button")
sets:Toggle(); equal(#writes, before, "disable preserves unsaved choices")
Suite.db.equipmentSetToggle = true; C_EquipmentSet.UnignoreSlotForSave = nil; sets:Refresh()
equal(sets.button.enabled, false, "missing API disables feature")
Suite.db.equipmentSetToggle = false; sets:Apply()
for _, name in ipairs(names) do _G["Character" .. name] = originals[name] end
PaperDollFrame, C_EquipmentSet, PaperDollItemSlotButton_Update, GearManagerPopupFrame = oldPaper, oldAPI, oldUpdate, oldPopup
CreateFrame = oldCreate
Suite.db, Suite.pending = oldDB, oldPending
SetCombat(false)
