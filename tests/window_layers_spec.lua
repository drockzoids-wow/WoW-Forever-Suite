-- A scoped frame-order model exercises overlapping real Suite window hierarchies.
-- Native hit testing/rendering and automatic top-level behavior still need a client test.
local Suite, equal, _, SetCombat = ...
local gui, training = Suite.GUI, Suite.Training
local settings, planner = gui.frame, training.frame
local oldDB, oldPending, oldTrainingDB = Suite.db, Suite.pending, training.db
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
SetCombat(false)
local function Walk(frame, callback)
    callback(frame)
    for _, child in ipairs(frame.children) do Walk(child, callback) end
end
local function Highest(frame)
    local highest = frame:GetFrameLevel()
    Walk(frame, function(child) highest = math.max(highest, child:GetFrameLevel()) end)
    return highest
end
local function Shift(frame, delta)
    Walk(frame, function(child) child.frameLevel = child:GetFrameLevel() + delta end)
end
local oldSettingsRaise, oldPlannerRaise = settings.Raise, planner.Raise
-- Model native Raise shifting the root and its descendants above a sibling family.
local raises = 0
local function Raise(frame)
    assert(not InCombatLockdown(), "overlap repair must not raise windows in combat")
    raises = raises + 1
    local other = frame == settings and planner or settings
    Shift(frame, math.max(0, Highest(other) + 1 - frame:GetFrameLevel()))
end
settings.Raise, planner.Raise = Raise, Raise
local function InFront(front, back, label)
    equal(front:GetFrameLevel() > Highest(back), true, label)
end
local function Click(child)
    while child and not child.topLevel do child = child.parent end
    if child then child:Raise() end
end
-- Equal root levels reproduce child text drawing above another window's plate.
Shift(planner, settings:GetFrameLevel() - planner:GetFrameLevel())
equal(planner.rows[1]:GetFrameLevel() > settings:GetFrameLevel(), true, "overlap fixture starts with planner text above the settings plate")
gui:OpenPage("professions")
InFront(settings, planner, "opening settings covers the entire planner hierarchy")
training:Open()
InFront(planner, settings, "opening the planner covers the entire settings hierarchy")
equal(planner.backdropAlpha, 1, "foreground planner plate fully obscures underlying text")
gui:OpenPage("professions")
InFront(settings, planner, "opening already visible settings brings its whole hierarchy forward")
training:Open()
InFront(planner, settings, "opening an already visible planner brings its whole hierarchy forward")
Click(gui.tabs.professions)
InFront(settings, planner, "clicking a settings child focuses the complete settings window")
Click(planner.rows[1])
InFront(planner, settings, "clicking a planner child focuses the complete planner window")
local settingsButton
for _, child in ipairs(planner.children) do
    if child.label and child.label.text == "Settings" then settingsButton = child end
end
assert(settingsButton, "planner settings button exists")
settingsButton:OnClick()
InFront(settings, planner, "planner Settings action opens a coherent foreground window")
gui:Toggle(); training:Open(); gui:Toggle()
InFront(settings, planner, "settings toggle raises the newly shown window")
training:Open(); gui:OpenMeters(1)
InFront(settings, planner, "meter settings opens above all planner controls")
local beforeCombat = raises
SetCombat(true); training:Open()
equal(raises, beforeCombat, "combat planner open waits without changing levels")
SetCombat(false); Suite.pending.trainingOpen()
InFront(planner, settings, "deferred planner open raises only after combat")
beforeCombat = raises
SetCombat(true); gui:OpenPage("professions")
equal(raises, beforeCombat, "combat settings open waits without changing levels")
SetCombat(false); Suite.pending.guiOpen()
InFront(settings, planner, "deferred settings open raises only after combat")
settings.Raise, planner.Raise = oldSettingsRaise, oldPlannerRaise
planner:Hide(); settings:Hide()
Suite.db, Suite.pending, training.db = oldDB, oldPending, oldTrainingDB
