local Suite, equal, Frame, SetCombat = ...
local module = Suite.QuestItem
local names = { "CreateFrame", "RegisterStateDriver", "C_Timer", "C_QuestLog", "C_Item", "C_Minimap", "C_SuperTrack", "C_EventUtils",
    "GetQuestLogSpecialItemInfo", "IsQuestLogSpecialItemInRange", "UnitIsDeadOrGhost", "GetUnitSpeed", "GetCursorInfo", "IsControlKeyDown", "UIParent", "GameTooltip" }
local old, saved = {}, {}
for _, name in ipairs(names) do old[name] = _G[name] end
for key, value in pairs(module) do saved[key] = value end
local oldDB, oldPending = Suite.db, Suite.pending
Suite.db = Suite.Copy(Suite.defaults); Suite.pending = {}
local rows, carried, tracked, dead, cursor, ctrl, speed = {}, {}, nil, false, nil, false, 0
local timers, made, states = {}, 0, {}
local function Drain()
    local pending = timers; timers = {}
    for _, timer in ipairs(pending) do if not timer.cancelled then timer.callback() end end
end
local function Count()
    local count = 0; for _, timer in ipairs(timers) do if not timer.cancelled then count = count + 1 end end; return count
end
C_Timer = { NewTimer = function(delay, callback)
    local timer = { delay = delay, callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
CreateFrame = function(kind, name, parent, template)
    assert(not InCombatLockdown(), "quest-item construction must wait outside combat")
    made = made + 1
    local frame = old.CreateFrame(kind, name, parent, template)
    frame.attributes, frame.references, frame.registered = {}, {}, {}
    frame.SetAttribute = function(self, key, value) assert(not InCombatLockdown()); self.attributes[key] = value end
    frame.GetAttribute = function(self, key) return self.attributes[key] end
    frame.SetFrameRef = function(self, key, value) self.references[key] = value end
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    frame.SetCooldown = function(self, start, duration) self.cooldownStart, self.cooldownDuration = start, duration end
    frame.Clear = function(self) self.cooldownStart, self.cooldownDuration = nil, nil end
    local createTexture = frame.CreateTexture
    frame.CreateTexture = function(self, ...)
        local texture = createTexture(self, ...)
        texture.SetVertexColor = function(region, ...) region.vertexColor = { ... } end
        return texture
    end
    for _, key in ipairs({ "SetPoint", "ClearAllPoints", "SetSize", "StartMoving", "StopMovingOrSizing", "Show", "Hide" }) do
        local original = frame[key]
        frame[key] = function(self, ...) assert(not InCombatLockdown(), "protected quest-item layout/visibility must defer"); return original(self, ...) end
    end
    return frame
end
RegisterStateDriver = function(controller, key, condition) states[#states + 1] = { controller, key, condition } end
C_EventUtils = { IsEventValid = function(event) return event ~= "QUEST_POI_UPDATE" end }
UIParent = Frame(); UIParent:SetSize(1000, 800)
GameTooltip = Frame(); GameTooltip.IsForbidden = function() return false end
GameTooltip.GetOwner = function(self) return self.owner end
GameTooltip.SetOwner = function(self, owner) self.owner = owner end
GameTooltip.SetHyperlink = function(self, link) self.link = link end
UnitIsDeadOrGhost = function() return dead end
GetUnitSpeed = function() return speed end
GetCursorInfo = function() return cursor end
IsControlKeyDown = function() return ctrl end
C_QuestLog = {
    GetNumQuestLogEntries = function() return #rows end,
    GetInfo = function(index) local row = rows[index]; return row and { questID = row.id, title = row.title or "Test quest", isHeader = row.header, isHidden = row.hidden } end,
    IsComplete = function(id) for _, row in ipairs(rows) do if row.id == id then return row.complete end end end,
    GetDistanceSqToQuest = function(id) for _, row in ipairs(rows) do if row.id == id then return row.distance, row.same end end end,
}
C_Item = { GetItemCount = function(id, bank, uses, reagent, account)
    assert(bank == false and uses == false and reagent == false and account == false, "bank contents cannot authorize quest item use")
    return carried[id] or 0
end, GetItemCooldown = function() return 10, 30, true end }
C_Minimap = { IsInsideQuestBlob = function(id) for _, row in ipairs(rows) do if row.id == id then return row.inside end end end }
C_SuperTrack = { GetSuperTrackedQuestID = function() return tracked end }
GetQuestLogSpecialItemInfo = function(index) local row = rows[index]; return row.link, row.icon or 134400, 1, row.showComplete end
IsQuestLogSpecialItemInRange = function(index) return rows[index].range end
local function Row(id, item, distance)
    return { id = id, link = "item:" .. item, distance = distance or 100, same = true, complete = false, range = 1 }
end
SetCombat(false); module:Apply()
equal(made, 0, "default-off quest helper creates no frames")
equal(Count(), 0, "default-off helper leaves no work")
Suite.db.questItemButton = true; SetCombat(true); module:Apply()
equal(made, 0, "combat enable defers secure construction")
Suite.db.questItemButton = false; module:Apply()
equal(Suite.pending.questItemApply, nil, "disable cancels deferred enable")
SetCombat(false); Suite.pending.questItemDisable(); Suite.pending.questItemDisable = nil
rows, carried = { Row(1, 100), Row(2, 200, 400) }, { [100] = 2, [200] = 1 }
Suite.db.questItemButton = true; module:Apply()
equal(module.candidate.id, 100, "nearest objective supplies the item")
equal(module.button:GetAttribute("macrotext1"), "/use [nocombat,nodead] item:100", "secure click uses stable item identity and native combat/death conditions even for bindings")
equal(module.button:GetAttribute("type1"), "macro", "guarded native action is prepared only after valid selection")
equal(module.button.width, 48, "quest button matches the compact trash icon footprint")
equal(module.button.icon.width, 44, "icon retains the trash button's inset")
equal(module.button.cooldown.cooldownDuration, 30, "native cooldown widget receives public timing")
equal(states[1][3], "[combat][dead] blocked; peaceful", "native driver hides during combat/death without automatically showing a stale button")
equal(module.events.registered.QUEST_POI_UPDATE, nil, "unsupported optional events are skipped")
equal(Count(), 0, "stationary helper has no idle polling timer")
tracked = 2; equal(module:Find().id, 200, "tracked quest wins between nearby candidates")
rows[1].inside = true; equal(module:Find().id, 100, "inside quest area takes priority over a merely nearby tracked objective")
rows[1].inside, tracked = false, nil
rows[1].distance, rows[2].distance = 62501, 62501
equal(module:Find(), nil, "distant objectives do not appear even if item range claims usable")
rows[1].inside = true; equal(module:Find().id, 100, "inside blob can authorize proximity independently of distance")
rows[1].inside, rows[1].distance, rows[1].same = false, 100, false
rows[2].same = false; equal(module:Find(), nil, "different-continent objectives cannot appear")
rows[1].same, rows[1].complete = true, true
equal(module:Find(), nil, "completed quest items stay hidden by default")
rows[1].showComplete = true; equal(module:Find().id, 100, "native explicit show-when-complete items remain available")
rows[1].complete, rows[1].showComplete = false, nil
for _, key in ipairs({ "id", "link", "distance", "same", "complete", "hidden", "header" }) do
    local original = rows[1][key]; rows[1][key] = { secret = true }
    equal(module:Find(), nil, "unreadable quest " .. key .. " cannot authorize an offer")
    rows[1][key] = original
end
rows[1].inside = { secret = true }
equal(module:Find().id, 100, "public nearby distance remains usable without relying on a restricted blob flag")
rows[1].inside = false
carried[100] = { secret = true }; equal(module:Find(), nil, "secret carried counts cannot authorize actions")
carried[100] = 0; equal(module:Find(), nil, "quest log entry without carried item is suppressed")
carried[100], rows[1].range = 2, 0; module:Refresh()
equal(module.button.icon.vertexColor[2], 0.25, "native out-of-range result uses subdued red tint")
dead = true; equal(module:Find(), nil, "dead players do not receive item candidates"); dead = false
module.button.PreClick(module.button, "LeftButton", false)
equal(module.button:GetAttribute("type1"), "macro", "fresh hardware click retains its prepared native action")
cursor = "item"; module.button.PreClick(module.button, "LeftButton", false)
equal(module.button:GetAttribute("type1"), nil, "occupied cursor blocks item use")
cursor = nil; module:Refresh(); rows[1].complete = true
module.button.PreClick(module.button, "LeftButton", false)
equal(module.button:GetAttribute("type1"), nil, "completion between refresh and click invalidates the action")
rows[1].complete = false; module:Refresh(); rows[1].link = "item:200"
module.button.PreClick(module.button, "LeftButton", false)
equal(module.button:GetAttribute("type1"), nil, "changed item identity is never substituted during a click")
rows[1].link = "item:100"; module:Refresh()
module.button.OnEnter()
equal(GameTooltip.link, "item:100", "hover uses the actual item tooltip")
equal(GameTooltip.lines[2][1], "Test quest", "quest title is available on hover without an always-visible label")
module.button.OnLeave()
module.button.OnDragStart(); module.button.centerX, module.button.centerY = 700, 600; module.button.OnDragStop()
equal(math.abs(Suite.db.questItemPosition.x - 0.2) < 0.000001, true, "drag persists normalized horizontal placement")
equal(Suite.db.questItemPosition.y, 0.25, "drag persists normalized vertical placement")
module.button.PreClick(module.button, "LeftButton", false)
equal(module.button:GetAttribute("type1"), nil, "drag release cannot activate a quest item")
module.button.OnMouseDown(); module:Refresh(); ctrl = true
module.button.PreClick(module.button, "RightButton", false); ctrl = false
equal(next(Suite.db.questItemPosition), nil, "Ctrl-right-click resets only quest button placement")
module:OnEvent("QUEST_LOG_UPDATE"); module:OnEvent("BAG_UPDATE_DELAYED")
equal(Count(), 1, "quest and bag work coalesce")
Drain(); equal(Count(), 0, "ordinary refresh settles without idle work")
module:OnEvent("PLAYER_STARTED_MOVING")
equal(module.moveTimer.delay, 0.5, "movement enables a bounded proximity check")
module:OnEvent("PLAYER_STOPPED_MOVING"); Drain()
equal(module.moveTimer, nil, "stopping movement cancels repeated checks")
module:OnEvent("PLAYER_STARTED_MOVING"); Drain()
equal(module.traveling, nil, "a fresh stationary speed cancels checks even if the stop event was missed")
equal(module.moveTimer, nil, "missing movement-stop notification cannot leave an idle poller")
module:Queue(); SetCombat(true); Drain()
equal(type(Suite.pending.questItemRefresh), "function", "timer crossing combat defers protected refresh")
module:OnEvent("PLAYER_REGEN_DISABLED")
equal(Count(), 0, "combat entry cancels work")
SetCombat(false); Suite.pending.questItemRefresh(); Suite.pending.questItemRefresh = nil
equal(module.candidate.id, 100, "post-combat refresh uses fresh public quest data")
Suite.db.questItemButton = false; SetCombat(true); module:Apply()
equal(next(module.events.registered), nil, "disable removes quest helper events immediately")
SetCombat(false); Suite.pending.questItemDisable(); Suite.pending.questItemDisable = nil
equal(module.button:IsShown(), false, "deferred disable hides the protected button")
equal(module.button:GetAttribute("macrotext1"), nil, "disable removes the saved native action")
equal(Count(), 0, "disabled feature retains no timer")
Suite.db.questItemButton = true; module:Apply(); module:OnEvent("PLAYER_LOGOUT"); module:Queue()
equal(Count(), 0, "logout cannot requeue work")
equal(Suite.SettingsCatalog:Search("smart quest item")[1].key, "questItemButton", "settings search finds the new optional feature")
module:Cancel(); SetCombat(false)
for _, name in ipairs(names) do _G[name] = old[name] end
for key in pairs(module) do module[key] = nil end
for key, value in pairs(saved) do module[key] = value end
Suite.db, Suite.pending = oldDB, oldPending
