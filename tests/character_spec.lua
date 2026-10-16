local Suite, equal, Frame, SetCombat = ...
local module = Suite.Character
local oldCreate, oldTimers, oldAverage = CreateFrame, C_Timer, GetAverageItemLevel
local oldScene, oldPet, oldSidebar = CharacterModelScene, CharacterStatsPanePetScrollBox, PaperDollFrame_ShowSidebar
local oldClassText = CharacterLevelText
local oldPending = Suite.pending
local timers, constructed, queries, inCombat = {}, 0, 0, false
local average, equipped = 99, 16.6
local function Combat(value) inCombat = value; SetCombat(value) end
local function Flush()
    local ready = timers; timers = {}
    for _, timer in ipairs(ready) do if not timer.cancelled then timer.callback() end end
end
local function LeaveCombat()
    Combat(false)
    local pending = Suite.pending; Suite.pending = {}
    for _, callback in pairs(pending) do callback() end
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
CreateFrame = function(...)
    assert(not inCombat, "character widgets cannot be constructed during combat")
    constructed = constructed + 1
    local frame = oldCreate(...)
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    local setPoint, setHeight, setLevel = frame.SetPoint, frame.SetHeight, frame.SetFrameLevel
    frame.SetPoint = function(self, ...)
        assert(not inCombat, "character overlay anchors defer during combat")
        setPoint(self, ...)
    end
    frame.SetHeight = function(self, ...)
        assert(not inCombat, "character overlay size defers during combat")
        setHeight(self, ...)
    end
    frame.SetFrameLevel = function(self, ...)
        assert(not inCombat, "character overlay layer defers during combat")
        setLevel(self, ...)
    end
    return frame
end
GetAverageItemLevel = function() queries = queries + 1; return average, equipped, 120 end
Suite.pending = {}
CharacterModelScene = nil
CharacterStatsPanePetScrollBox = Frame()
PaperDollFrame_ShowSidebar = function() end

equal(Suite.db.characterItemLevel, false, "character item level starts off independently")
module:Apply()
equal(constructed, 0, "disabled character module creates no widgets")
equal(module.events, nil, "disabled character module registers no events")
Suite.db.characterItemLevel = true
Combat(true)
module:Apply()
equal(constructed, 0, "first character enable in combat defers all construction")
Suite.db.characterItemLevel = false
module:Apply()
LeaveCombat()
equal(constructed, 0, "disable cancels a deferred character enable")

Suite.db.characterItemLevel = true
module:Apply()
equal(module.events.registered.ADDON_LOADED, true, "late character UI can be discovered")
equal(module.display, nil, "missing character scene creates no orphan overlay")
CharacterModelScene = Frame()
CharacterModelScene:Show()
local sceneShow = 0
CharacterModelScene:SetScript("OnShow", function() sceneShow = sceneShow + 1 end)
-- Keep native level/class text and its full available space, including long class names.
local classText = Frame()
CharacterLevelText = classText
classText:SetText("Level 60 Warrior / Paladin / Warlock")
classText:SetPoint("CENTER", 7, 0)
module.events.OnEvent(module.events, "ADDON_LOADED")
Flush()
equal(module.display:GetParent(), CharacterModelScene, "passive display follows native model visibility and scale")
equal(module.display.mouseEnabled, false, "item level does not intercept model controls")
equal(module.text.text, "Item Level |cffffffff17|r", "display rounds equipped second return rather than carried or PvP level")
equal(module.display:IsShown(), true, "visible player model shows the label")
equal(module.display.OnUpdate, nil, "no idle overlay update")
equal(classText.text, "Level 60 Warrior / Paladin / Warlock", "long class line retains its text")
equal(classText.point[1], "CENTER", "class line retains its native anchor")
CharacterModelScene.OnShow(CharacterModelScene)
equal(sceneShow, 1, "native scene show script is preserved")

local before = queries
equipped = 21.4
module.events.OnEvent(module.events, "PLAYER_EQUIPMENT_CHANGED")
module.events.OnEvent(module.events, "PLAYER_AVG_ITEM_LEVEL_UPDATE")
equal(#timers, 1, "equipment event burst uses one timer")
Flush()
equal(queries, before + 1, "event burst queries equipped average once")
equal(module.text.text, "Item Level |cffffffff21|r", "gear changes replace the displayed value")
average, equipped = { secret = true }, 14
module:Refresh()
equal(module.text.text, "Item Level |cffffffff14|r", "unused carried average can be restricted")
for _, value in ipairs({ { secret = true }, false, 0, -1, math.huge, 0 / 0 }) do
    equipped = value
    module:Refresh()
    equal(module.text.text, "Item Level |cff9aa5ad—|r", "restricted or invalid equipped value clears stale numbers")
end
equipped = nil
module:Refresh()
equal(module.text.text, "Item Level |cff9aa5ad—|r", "pending equipped average is not shown as zero")
GetAverageItemLevel = nil
module:Refresh()
equal(module.text.text, "Item Level |cff9aa5ad—|r", "absent native average leaves an unavailable value")
GetAverageItemLevel = function() queries = queries + 1; return 99, equipped end
equipped = 32

CharacterStatsPanePetScrollBox:Show()
PaperDollFrame_ShowSidebar()
Flush()
equal(module.display:IsShown(), false, "player item level hides on native pet view")
CharacterStatsPanePetScrollBox:Hide()
PaperDollFrame_ShowSidebar()
Flush()
equal(module.display:IsShown(), true, "player sidebar restores the display")
CharacterModelScene:Hide()
before = queries
module.events.OnEvent(module.events, "PLAYER_AVG_ITEM_LEVEL_UPDATE")
equal(#timers, 0, "hidden character sheet schedules no equipment refresh")
equal(queries, before, "hidden character sheet does not query equipment")
CharacterModelScene:Show()
CharacterModelScene.OnShow(CharacterModelScene)
equal(module.text.text, "Item Level |cffffffff32|r", "reopening refreshes the current gear")

Combat(true)
equipped = 48
before = queries
local beforeConstruction = constructed
module.events.OnEvent(module.events, "PLAYER_EQUIPMENT_CHANGED")
Flush()
equal(queries, before, "combat refresh defers native average query and layout")
equal(constructed, beforeConstruction, "combat refresh uses no widget construction")
LeaveCombat()
equal(module.text.text, "Item Level |cffffffff48|r", "deferred gear refresh runs after combat")

module.events.OnEvent(module.events, "PLAYER_EQUIPMENT_CHANGED")
local cancelled = module.refreshTimer
Suite.db.characterItemLevel = false
module:Apply()
equal(cancelled.cancelled, true, "disable cancels queued character refresh")
equal(next(module.events.registered), nil, "disable removes feature events")
equal(module.text.text, "", "disable clears old item level")
equal(module.display:IsShown(), false, "disable hides the overlay")
Flush()
CharacterModelScene.OnShow(CharacterModelScene)
PaperDollFrame_ShowSidebar()
equal(#timers, 0, "retained native hooks stay idle while disabled")
equal(Suite.pending.characterItemLevel, nil, "disable leaves no deferred work")

Suite.GUI:Select("items")
equal(Suite.GUI.rows[3].label.text, "Character frame item level", "Items exposes the independent setting")
Suite.pending = oldPending
CreateFrame, C_Timer, GetAverageItemLevel = oldCreate, oldTimers, oldAverage
CharacterModelScene, CharacterStatsPanePetScrollBox, PaperDollFrame_ShowSidebar = oldScene, oldPet, oldSidebar
CharacterLevelText = oldClassText
Combat(false)
