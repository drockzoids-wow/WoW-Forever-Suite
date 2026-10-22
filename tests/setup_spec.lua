local Suite, equal, Frame, setCombat, events = ...
local setup, gui = Suite.Setup, Suite.GUI
local saved = { db = Suite.db, apply = Suite.Apply, cvar = C_CVar, pending = Suite.pending,
    hide = gui.frame.Hide, setShown = gui.frame.SetShown, page = gui.page, shown = gui.frame:IsShown() }
local applies, writes = 0, 0
local native = { value = "0", locked = false, secure = false, readOnly = false, success = true }
C_CVar = {
    GetCVarInfo = function(name)
        equal(name, "autoLootDefault", "setup reads only the disclosed native preference")
        return native.value, "0", false, true, native.locked, native.secure, native.readOnly
    end,
    SetCVar = function(name, value)
        equal(name, "autoLootDefault", "setup writes only Auto Loot")
        equal(InCombatLockdown(), false, "setup writes native preferences outside combat")
        writes = writes + 1
        if native.success == true and not native.ignore then native.value = value end
        return native.success
    end,
}
Suite.Apply = function() applies = applies + 1 end
Suite.pending = {}
gui.frame.Hide = function(self) saved.hide(self); if self.OnHide then self.OnHide(self) end end
gui.frame.SetShown = function(self, shown)
    if shown then self:Show() else self:Hide() end
end
local function Fresh()
    setCombat(false)
    gui:Select("overview")
    Suite.db = Suite.InitializeDB(nil)
    native.value, native.locked, native.secure, native.readOnly = "0", false, false, false
    native.success, native.ignore = true, false
    Suite.pending = {}
end
local function Review() setup:Move(5) end

Fresh()
equal(#setup.pages, 5, "guide has five steps")
equal(Suite.db.setupGuide.seen, false, "fresh account is eligible for the welcome")
setup:OnLogin()
equal(gui.page, "setup", "first Suite login opens the guide")
equal(gui.frame:IsShown(), true, "first login shows the guide")
equal(Suite.db.setupGuide.seen, true, "welcome is offered only once per account")
equal(Suite.db.setupGuide.completed, false, "opening does not complete setup")
equal(applies, 0, "welcome applies no feature changes")
equal(writes, 0, "welcome leaves native preferences alone")
equal(Suite.db.actionBarSkin, false, "features still start off")
equal(setup.draft.minimapButton, true, "existing launcher default is reflected in the draft")
equal(gui.setupBack.enabled, false, "first step cannot go backward")
setup:Stage("quickLoot", true)
equal(Suite.db.quickLoot, false, "individual guide choices are staged")
equal(setup:Finish(), false, "application requires the review step")
gui.setupLater.OnClick()
equal(gui.page, "overview", "Later returns to settings")
equal(setup.draft, nil, "Later discards unsaved choices")
equal(Suite.db.quickLoot, false, "Later retains original preferences")
setup:OnLogin()
equal(gui.page, "overview", "dismissed welcome does not reopen on an alt login")
SlashCmdList.WOWFOREVERSUITE(" SETUP ")
equal(gui.page, "setup", "slash command can reopen a dismissed guide")
equal(setup.draft.quickLoot, false, "reopened guide uses current preferences")
setup:Stage("quickLoot", true)
gui.closeButton.OnClick()
equal(setup.draft, nil, "X discards the draft through OnHide")
equal(gui.frame:IsShown(), false, "X closes the guide")
gui:Toggle()
equal(setup.draft.quickLoot, false, "reopening after X starts a fresh draft")
setup:Stage("quickLoot", true)
gui.frame.OnHide() -- Escape and native panel cleanup share this callback.
equal(setup.draft, nil, "Escape/native hiding discards the draft")
gui.tabs.setup.OnClick()
setup:Stage("quickLoot", true)
gui.tabs.minimap.OnClick()
equal(setup.draft, nil, "leaving for normal settings discards the draft")
equal(Suite.db.quickLoot, false, "navigation never applies staged automation")
gui:OpenPage("setup")
equal(setup.page, 1, "new guide visits start at the beginning")
setup:Move(0); equal(setup.page, 1, "page zero is rejected")
setup:Move(6); equal(setup.page, 1, "out-of-range pages are rejected")
setup:Move(1.5); equal(setup.page, 1, "fractional pages are rejected")
setup:Move({ secret = true }); equal(setup.page, 1, "restricted pages are rejected")
equal(setup:Stage("notASetting", true), false, "guide cannot stage arbitrary saved keys")
equal(setup:Stage({ secret = true }, true), false, "restricted setting keys are rejected")
equal(setup:Stage("quickLoot", { secret = true }), false, "restricted boolean choices are rejected")
equal(setup:Stage("junkMode", "bogus"), false, "unknown sale choices are rejected")
equal(setup:Stage("junkMode", { secret = true }), false, "restricted enum choices are rejected")
setup:ChoosePage(true)
equal(setup.draft.autoLoot, true, "suggested everyday setup includes native Auto Loot")
equal(setup.draft.quickLoot, true, "suggested everyday setup includes Quick loot")
equal(setup.draft.autoSellJunk, false, "suggested choices leave junk selling optional")
equal(setup.draft.junkMode, "slow", "suggested sale mode retains Buyback")
equal(setup.draft.autoGossip, false, "false suggestions remain false")
equal(setup.draft.sortBagsOnOpen, false, "bag sorting remains an explicit choice")
equal(setup.draft.actionBarSkin, false, "suggestions affect only the current step")
equal(writes, 0, "suggestions make no native writes")
equal(applies, 0, "suggestions call no module Apply")
setup:ChoosePage(false)
equal(setup.draft.quickLoot, false, "current choices undo suggestions on this page")
equal(setup.dirty.quickLoot, nil, "current choices release the staged change")

-- Layout bounds and instructional coverage, not a claim of native visual verification.
local tabCount = 0
for _, tab in pairs(gui.groupTabs) do
    tabCount = tabCount + 1
    equal(-tab.point[3] + tab.height < 560, true, "sidebar tabs remain above the edition footer")
end
equal(tabCount, 7, "six workspaces include standalone Profiles and a separate setup utility")
for page = 1, 4 do
    setup:Move(page)
    equal(gui.setupReview:IsShown(), false, "choice pages hide the review scrollbar")
    equal(gui.setupChoices:IsShown(), true, "choice pages use their own clipped viewport")
    equal(gui.setupChoiceChild:GetParent(), gui.setupChoices, "option cards scroll inside their viewport")
    equal(-gui.setupChoices.point[3] + gui.setupChoices.height < 467, true, "option viewport stays above instructions")
    for _, card in ipairs(gui.setupCards) do
        if card:IsShown() then
            equal(card:GetParent(), gui.setupChoiceChild, "choice card belongs to clipped scroll contents")
            equal(-card.point[3] + card.height <= gui.setupChoiceChild.height, true, "every option fits in scroll contents")
            equal(card.point[2] + card.width <= gui.setupChoiceChild.width, true, "choice card stays inside the content width")
        end
    end
end
setup:Move(3)
equal(gui.setupTip.text:find("Ctrl+scroll", 1, true) ~= nil, true, "map and window step teaches resizing")
equal(gui.setupTip.text:find("Ctrl+right-click", 1, true) ~= nil, true, "map and window step teaches resetting")
Review()
equal(gui.setupReview:IsShown(), true, "review uses a scrollable change list")
equal(gui.setupChoices:IsShown(), false, "review hides the choice viewport")
equal(gui.setupSuggested:IsShown(), false, "review has no hidden preset mutation")
equal(gui.note.height, 12, "guide footer leaves navigation clear")
equal(-gui.setupNext.point[3] + gui.setupNext.height <= 540, true, "navigation ends before the guide footer")
local stringHeight = gui.setupReviewText.GetStringHeight
for _, value in ipairs({ { secret = true }, -1, math.huge }) do
    gui.setupReviewText.GetStringHeight = function() return value end
    local childHeight = gui.setupReviewChild.height
    gui:RefreshSetup()
    equal(gui.setupReviewChild.height, childHeight, "unreadable or invalid measured text cannot enter scroll arithmetic")
end
gui.setupReviewText.GetStringHeight = stringHeight

-- Every curated setting is reachable, validated and staged, including later additions.
local keys, total = {}, 0
for index, page in ipairs(setup.pages) do
    setup:Move(index)
    for slot, option in ipairs(page.options) do
        equal(keys[option.key], nil, "setup offers each setting once")
        keys[option.key], total = true, total + 1
        equal(option.native or Suite.defaults[option.key] ~= nil, true, "setup never invents unsupported saved settings")
        equal(gui.setupCards[slot].option, option, "every option has a reachable card")
        equal(type(option.help), "string", "every choice explains its effect")
    end
end
equal(total > 60, true, "guide includes newer tools beyond the original 36 choices")
for _, key in ipairs({ "autoOpenContainers", "questItemButton", "levelingBar", "zoneReputation", "playerBuffBorders", "targetThreat",
    "missingBuffs", "missingBuffSelf", "missingBuffOutgoing", "missingBuffIncoming", "missingBuffClass", "progressBarSegments",
    "borderColorMode", "bagSpaceAlert", "reverseCombinedBags", "reverseBagSlots", "inventorySearch", "characterDashboard",
    "upgradeHints", "classNames", "modifierDisenchant", "disenchantModifier", "macroUpdates", "audioSync" }) do
    equal(keys[key], true, "guide includes supported newer choice: " .. key)
end
for _, key in ipairs({ "trainingPlanner", "trainingAuto", "trainingLevelUp", "trainingSpellbook", "chatHistory",
    "missingBuffExpiry", "missingBuffCombat", "missingBuffWeapons" }) do
    equal(keys[key] == true, Suite.defaults[key] ~= nil, "later-build choice follows actual capability: " .. key)
    if Suite.defaults[key] == nil then equal(setup:Stage(key, true), false, "unsupported options cannot be committed: " .. key) end
end
setup:Move(2)
local choices = gui.setupChoices
equal(choices.suiteMaximum > 0, true, "long choice pages expose a scrollbar")
choices.OnMouseWheel(choices, -100)
equal(choices.suiteOffset, choices.suiteMaximum, "choice wheel reaches all lower options")
local beforeScroll = choices.suiteOffset
gui.setupCards[1].OnMouseWheel(gui.setupCards[1], 1)
equal(choices.suiteOffset < beforeScroll, true, "wheel over a card scrolls its viewport")
local retainedOffset = choices.suiteOffset
gui:RefreshSetup()
equal(choices.suiteOffset, retainedOffset, "refreshing a draft retains its scroll position")
setup:Move(3)
equal(choices.suiteOffset, 0, "changing steps starts at the top of the next list")
setup:Move(2)
setup:ChoosePage(true)
equal(setup.draft.missingBuffs, false, "suggestions do not enable the missing-buff bar implicitly")
equal(setup.draft.targetThreat, false, "threat display remains an independent choice")
equal(setup.draft.borderColorMode, "default", "suggested border color is explicitly staged")
setup:ChoosePage(false)
local reviewHeight = gui.setupReviewText.GetStringHeight
gui.setupReviewText.GetStringHeight = function() return 900 end
Review()
equal(gui.setupReview.suiteMaximum > 0, true, "long review has an explicit scroll range")
gui.setupReviewText.GetStringHeight = reviewHeight

-- Successful application touches chosen settings only and coalesces module application.
Fresh()
Suite.db.windowPositions.example = { x = 0.3, y = 0.4 }
Suite.db.upgradeHints, Suite.db.scorePreset = true, "caster"
Suite.db.keybindSize = 19
setup:Open()
setup:Stage("quickLoot", true)
setup:Stage("autoLoot", true)
setup:Move(3)
setup:Stage("windowTools", true)
setup:Stage("minimapButton", false)
Suite.db.chatStyle = true -- Another source changes an untouched option while the guide is open.
Review()
equal(gui.setupReviewText.text:find("Quick loot: On", 1, true) ~= nil, true, "review discloses enabled automation")
equal(gui.setupReviewText.text:find("Suite minimap button: Off", 1, true) ~= nil, true, "review discloses disabled launcher")
equal(gui.setupReviewText.text:find("Suite chat style", 1, true), nil, "untouched external choices are not in the change list")
setCombat(true)
events.OnEvent(events, "PLAYER_REGEN_DISABLED")
equal(gui.setupNext.enabled, false, "Apply is disabled when combat starts")
equal(setup:Finish(), false, "controller also rejects combat application")
equal(writes, 0, "combat causes no native preference writes")
equal(applies, 0, "combat causes no module application")
equal(Suite.pending.setupFinish, nil, "combat does not queue automation application without another click")
setCombat(false)
events.OnEvent(events, "PLAYER_REGEN_ENABLED")
equal(gui.setupNext.enabled, true, "Apply becomes available after combat")
equal(Suite.db.quickLoot, false, "combat exit alone does not apply the draft")
equal(setup:Finish(), true, "explicit finish applies the draft")
equal(writes, 1, "native setting is written once")
equal(native.value, "1", "native Auto Loot choice was confirmed")
equal(applies, 1, "module application runs once for the whole guide")
equal(Suite.db.quickLoot, true, "chosen loot feature applies")
equal(Suite.db.windowTools, true, "chosen window feature applies")
equal(Suite.db.minimapButton, false, "launcher can be independently disabled")
equal(Suite.db.chatStyle, true, "untouched external feature is retained")
equal(Suite.db.upgradeHints, true, "advanced feature outside the guide is retained")
equal(Suite.db.scorePreset, "caster", "stat weights remain unchanged")
equal(Suite.db.keybindSize, 19, "custom font size remains unchanged")
equal(Suite.db.windowPositions.example.x, 0.3, "existing layouts remain unchanged")
equal(Suite.db.setupGuide.completed, true, "completion persists at account scope")
equal(gui.page, "overview", "completion returns to normal settings")
equal(setup:Finish(), false, "repeat completion cannot apply the stale draft")
Suite.db = Suite.InitializeDB(Suite.Copy(Suite.db))
native.value = "0" -- The user changes the game's setting after setup.
setup:OnLogin()
equal(native.value, "0", "later logins do not enforce Auto Loot")
equal(gui.page, "overview", "completed guide does not reopen after reload")

-- Native capability/permission checks reject unknown metadata and restricted values.
local function Rejected(field, value, label)
    Fresh()
    native[field] = value
    equal(setup:AutoLoot(), nil, label)
    setup:Open()
    equal(gui.setupCards[1].enabled, false, label .. " disables the native choice")
    equal(setup:Stage("autoLoot", true), false, label .. " rejects staging")
end
Rejected("value", nil, "missing preference")
Rejected("value", "unknown", "nonboolean preference")
Rejected("value", { secret = true }, "restricted preference")
for _, field in ipairs({ "locked", "secure", "readOnly" }) do
    Rejected(field, true, field .. " preference")
    Rejected(field, nil, "unknown " .. field .. " metadata")
    Rejected(field, { secret = true }, "restricted " .. field .. " metadata")
end
Fresh()
local api = C_CVar
C_CVar = nil; equal(setup:AutoLoot(), nil, "missing CVar API")
C_CVar = { GetCVarInfo = api.GetCVarInfo }; equal(setup:AutoLoot(), nil, "missing native setter")
C_CVar = api
Fresh()
local goodGetter = C_CVar.GetCVarInfo
C_CVar.GetCVarInfo = function() error("native preference read rejected") end
equal(setup:AutoLoot(), nil, "a rejected native getter cannot break the welcome")
setup:Open()
equal(gui.setupCards[1].enabled, false, "rejected native getter leaves an unavailable Auto Loot card")
C_CVar.GetCVarInfo = goodGetter
Fresh(); setup:Open(); setup:Stage("autoLoot", true); setup:Stage("quickLoot", true); Review()
local goodSetter = C_CVar.SetCVar
C_CVar.SetCVar = function() error("native preference write rejected") end
equal(setup:Finish(), false, "a rejected native setter retains the review")
equal(Suite.db.quickLoot, false, "a rejected native setter cannot partially enable Suite tools")
equal(setup.draft.quickLoot, true, "a rejected native setter retains staged choices")
C_CVar.SetCVar = goodSetter

for _, failure in ipairs({ { success = false }, { success = nil }, { success = { secret = true } }, { success = true, ignore = true } }) do
    Fresh()
    setup:Open()
    setup:Stage("autoLoot", true)
    setup:Stage("quickLoot", true)
    native.success, native.ignore = failure.success, failure.ignore
    Review()
    local before = applies
    equal(setup:Finish(), false, "unconfirmed native write prevents finishing")
    equal(applies, before, "failed native write does not apply Suite modules")
    equal(Suite.db.quickLoot, false, "failed native write preserves Suite settings")
    equal(Suite.db.setupGuide.completed, false, "failed native write does not record completion")
    equal(setup.draft.quickLoot, true, "failed native write retains choices for correction")
    equal(type(setup.message), "string", "native write failure is explained")
end
Fresh()
setup:Open()
setup:Stage("autoLoot", true)
setup:Stage("quickLoot", true)
native.locked = true
Review()
local beforeWrites = writes
equal(setup:Finish(), false, "permission is rechecked at application")
equal(writes, beforeWrites, "late permission failure causes no native write")
setup:Move(1); setup:ChoosePage(false)
equal(setup.dirty.autoLoot, nil, "current choices release an unavailable native setting")
setup:Stage("quickLoot", true)
Review()
equal(setup:Finish(), true, "guide can finish while leaving an unavailable game setting unchanged")

-- Repeated opens reuse frames; deferred first construction is cancellable.
Fresh()
gui.setupPanel = nil
setCombat(true)
setup:OnLogin()
equal(gui.setupPanel, nil, "combat defers first guide construction")
equal(Suite.db.setupGuide.seen, false, "unshown deferred welcome is not marked seen")
equal(type(Suite.pending.setupOpen), "function", "deferred opening is coalesced")
gui:Select("overview")
equal(Suite.pending.setupOpen, nil, "normal navigation cancels a pending guide opening")
setup:OnLogin()
setCombat(false)
events.OnEvent(events, "PLAYER_REGEN_ENABLED")
equal(gui.page, "setup", "combat exit can offer the deferred welcome")
equal(Suite.db.setupGuide.seen, true, "deferred welcome records successful offering")
local reused = gui.setupPanel
setup:Open(); setup:Open()
equal(gui.setupPanel, reused, "repeated openings reuse guide widgets")
gui.setupPanel:Hide()
gui:Select("overview")
for _, corrupt in ipairs({ "invalid", { secret = true }, { seen = { secret = true }, completed = { secret = true } } }) do
    local state = setup:InitializeState(corrupt)
    equal(state.seen, false, "corrupt welcome state is sanitized")
    equal(state.completed, false, "corrupt completion state is sanitized")
end
equal(setup:InitializeState({ completed = true }).seen, true, "completion implies the welcome was seen")
local valid = setup:InitializeState({ seen = true, completed = true, version = 999, draft = {} })
equal(valid.seen, true, "guide version changes do not nag completed accounts")
equal(valid.draft, nil, "runtime drafts are never persisted in guide state")

Fresh(); setup:Open()
equal(setup:Stage("borderColorMode", "invalid"), false, "unknown theme choices cannot be committed")
equal(setup:Stage("disenchantModifier", "invalid"), false, "unknown modifier choices cannot be committed")
local expected = {}
for _, page in ipairs(setup.pages) do
    for _, option in ipairs(page.options) do
        if not option.native then
            local previous = Suite.db[option.key]
            local desired = not previous
            if option.choices then
                desired = option.choices[1] == previous and option.choices[2] or option.choices[1]
            end
            equal(setup:Stage(option.key, desired), true, "supported choice can be staged: " .. option.key)
            equal(Suite.db[option.key], previous, "staging leaves the active setting unchanged: " .. option.key)
            expected[option.key] = desired
        end
    end
end
Review()
local beforeApplies = applies
equal(setup:Finish(), true, "all supported choices can be explicitly applied together")
equal(applies, beforeApplies + 1, "expanded setup still applies modules only once")
for key, value in pairs(expected) do equal(Suite.db[key], value, "new and existing choices survive commit: " .. key) end
equal(Suite.db.customBorderColor.r, Suite.defaults.customBorderColor.r, "choosing a theme retains the saved custom color")

-- The welcome is offered when the world is ready, never during earlier login UI setup.
Fresh()
local onLogin, onWorld = setup.OnLogin, Suite.Leveling.OnWorld
local initialize, register = gui.Initialize, gui.RegisterSettings
local welcomeCalls, worldCalls = 0, 0
setup.OnLogin = function() welcomeCalls = welcomeCalls + 1 end
Suite.Leveling.OnWorld = function() worldCalls = worldCalls + 1 end
gui.Initialize, gui.RegisterSettings = function() end, function() end
events.OnEvent(events, "PLAYER_LOGIN")
equal(welcomeCalls, 0, "login initialization does not show setup before world entry")
events.OnEvent(events, "PLAYER_ENTERING_WORLD", true, false)
equal(welcomeCalls, 1, "world entry dispatches the first-use welcome")
equal(worldCalls, 1, "welcome preserves the existing world-entry handler")
setup.OnLogin, Suite.Leveling.OnWorld = onLogin, onWorld
gui.Initialize, gui.RegisterSettings = initialize, register
local openPage = gui.OpenPage
gui.OpenPage = function() end
setup:OnLogin()
equal(Suite.db.setupGuide.seen, false, "an unsuccessful opening never consumes the welcome")
gui.OpenPage = openPage
setup:OnLogin(); gui:Select("overview")
local completed = setup:InitializeState({ version = 1, seen = true, completed = true })
equal(completed.version, 2, "content revision updates state without losing old completion")
equal(completed.seen and completed.completed, true, "new content does not nag an existing completed account")

-- The same setup controls fit the newer installed settings panel width.
local contentWidth = gui.contentWidth
gui.setupPanel:Hide(); gui.setupPanel = nil; gui.contentWidth = 816
setup:Open()
equal(gui.setupPanel.width, 780, "setup uses the newer panel's full content width")
for _, step in ipairs(gui.setupSteps) do
    equal(step.point[2] + step.width <= gui.setupPanel.width + 0.001, true, "all five step buttons fit the newer panel")
end
for _, card in ipairs(gui.setupCards) do
    equal(card.point[2] + card.width <= gui.setupChoiceChild.width, true, "expanded setup cards fit the newer viewport")
end
gui:Select("overview"); gui.setupPanel:Hide(); gui.setupPanel = nil; gui.contentWidth = contentWidth
setup:Open(); gui:Select("overview")

setCombat(false)
gui:Select("overview")
Suite.db, Suite.Apply, C_CVar, Suite.pending = saved.db, saved.apply, saved.cvar, saved.pending
gui.frame.Hide, gui.frame.SetShown = saved.hide, saved.setShown
gui:Select(saved.page or "overview")
gui.frame:SetShown(saved.shown)
