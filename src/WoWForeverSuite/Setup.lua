local _, Suite = ...
local Setup = { version = 2 }
Suite.Setup = Setup

-- Original guide content. Suggestions are drafts, never addon defaults.
Setup.pages = {
    { title = "Make everyday play easier.", short = "Everyday", description = "Choose your looting, quest and leveling tools. Scroll to see every choice.\nNothing changes until Apply setup; Auto Loot is a game setting.",
        tip = "Hold your configured loot modifier to reverse Auto Loot. Hold Shift when talking to pause quest automation for that conversation.", options = {
        { key = "autoLoot", native = true, label = "Auto Loot", help = "Collect loot automatically.\nKeeps your current loot modifier.", suggested = true },
        { key = "quickLoot", label = "Quick loot", help = "Collect automatic loot sooner.\nManual loot and prompts stay native.", suggested = true },
        { key = "autoRepair", label = "Repair at vendors", help = "Repair when repairs are offered.\nUses the funding choice below.", suggested = true },
        { key = "autoSellJunk", label = "Sell gray junk", help = "Sell gray items at vendors.\nUses the sale mode below.", suggested = false },
        { key = "repairSource", label = "Repair funding", help = "Personal spends your gold. Guild\nrequires full permitted funds.", choices = { "personal", "guild" }, labels = { personal = "Personal", guild = "Guild" }, suggested = "personal" },
        { key = "junkMode", label = "Junk sale mode", help = "Slow: up to 12 Buyback stacks.\nInstant: permanent, no confirmation.", choices = { "slow", "instant" }, labels = { slow = "Slow", instant = "Instant" }, suggested = "slow" },
        { key = "autoQuestPickup", label = "Accept quests", help = "Accept available quests. Ignored\nquests and PvP prompts stay manual.", suggested = true },
        { key = "autoQuestTurnIn", label = "Turn in quests", help = "Finish ready quests. Multiple\nrewards and gold costs stay manual.", suggested = true },
        { key = "autoGossip", label = "Advance gossip", help = "Advance a single dialogue option.\nChoices and prompts stay manual.", suggested = false },
        { key = "sortBagsOnOpen", label = "Sort bags on opening", help = "Run native cleanup once per visit.\nRespects the game's bag exclusions.", suggested = false },
        { key = "vendorKnownItems", label = "Known vendor items", help = "Green highlights for learned recipes\nand collected vendor items.", suggested = false },
        { key = "autoVendor", label = "Open vendor shops", help = "Skip an extra shop dialogue click.\nHold Shift to keep the menu open.", suggested = false },
        { key = "autoOpenContainers", label = "Open bag containers", help = "Open loot containers one at a time.\nNeeds a free slot; pauses in combat.", suggested = false },
        { key = "questItemButton", label = "Nearby quest items", help = "Show a usable quest-item button\nnear objectives. Hides in combat.", suggested = true },
        { key = "zoneReputation", label = "Zone reputation", help = "Watch the known local city faction.\nOther areas keep your current choice.", suggested = false },
        { key = "levelingBar", label = "Leveling tracker", help = "Track session XP, net gold and time.\nMove or lock it in Leveling settings.", suggested = false },
        { key = "trainingPlanner", label = "Record trainer skills", help = "Save class and weapon trainer visits.\nTraining purchases remain manual.", suggested = false },
        { key = "trainingAuto", label = "Planner at trainers", help = "Open the planner beside trainers.\nNeeds Record trainer skills.", suggested = true },
        { key = "trainingLevelUp", label = "Planner on level up", help = "Show saved class skills on level up.\nNeeds Record trainer skills.", suggested = true },
        { key = "trainingSpellbook", label = "Planner with spellbook", help = "Show saved skills with the spellbook.\nNeeds Record trainer skills.", suggested = true },
    } },
    { title = "Bring your bars together.", short = "Bars & HUD", description = "Choose the Suite look and the feedback you find useful.\nArrange native bars and unit frames through Game Menu > Edit Mode.",
        tip = "Meter headers move; lower corners resize. The shared meter lock is in Damage meters. Fonts and progress-bar sizes have more options in settings.", options = {
        { key = "actionBarSkin", label = "Action bar skin", help = "Square icons with slate and teal.\nNative actions and glows remain.", suggested = true },
        { key = "fullButtonRange", label = "Full icon range color", help = "Turn the icon red when your\ntarget is outside the action's range.", suggested = true },
        { key = "shortKeybinds", label = "Short keybind labels", help = "Compact labels such as SCM4.\nYour key assignments stay the same.", suggested = true },
        { key = "classHealthBars", label = "Class health colors", help = "Class colors on player, target,\ntarget of target and focus health.", suggested = true },
        { key = "statusBarSkin", label = "Progress bar skin", help = "Style XP, honor and reputation.\nKeeps native fill colors and text.", suggested = true },
        { key = "progressBarValues", label = "Always show values", help = "Keep native progress text visible.\nNeeds the progress bar skin above.", suggested = true },
        { key = "bagBarSkin", label = "Bag button skin", help = "Slate buttons with teal edges.\nKeeps bag counts and shortcuts.", suggested = true },
        { key = "microBarSkin", label = "Micro menu skin", help = "Match your menu buttons.\nKeeps alerts, tooltips and clicks.", suggested = true },
        { key = "questTrackerSkin", label = "Quest tracker skin", help = "A slate tracker with teal controls.\nKeeps quest colors and text size.", suggested = true },
        { key = "damageMeters", label = "Damage meters", help = "Two views of native recorded fights.\nChoose metrics in each meter.", suggested = false },
        { key = "borderColorMode", label = "Border color", help = "Teal, your class or saved custom color.\nPick new custom colors in Appearance.", choices = { "default", "class", "custom" }, labels = { default = "Teal", class = "My class", custom = "Custom" }, suggested = "default" },
        { key = "playerBuffBorders", label = "Player buff borders", help = "Frame your top-right buff icons.\nKeeps native timers and controls.", suggested = true },
        { key = "targetThreat", label = "Target threat", help = "Show your threat against enemy NPCs.\nUnknown percentages display as --.", suggested = false },
        { key = "combatIndicator", label = "Combat indicator", help = "Show when combat starts and ends.\nMove or lock it in Combat settings.", suggested = false },
        { key = "progressBarSegments", label = "Progress bar sections", help = "Mark ten-percent progress sections.\nNeeds the progress bar skin above.", suggested = false },
        { key = "missingBuffs", label = "Missing buff bar", help = "Remind you of missing group buffs\nand your class upkeep choices.", suggested = false },
        { key = "missingBuffSelf", label = "My missing buffs", help = "Show learned buffs you can cast on you.\nNeeds the Missing buff bar.", suggested = true },
        { key = "missingBuffOutgoing", label = "Buff party and raid", help = "Offer buffs your group is missing.\nCasting needs an outside-combat click.", suggested = true },
        { key = "missingBuffIncoming", label = "Group buffs for me", help = "Show buffs teammates could provide.\nOnly an icon click sends a request.", suggested = true },
        { key = "missingBuffClass", label = "Class upkeep", help = "Aspects, armor, shields and poisons.\nNeeds the Missing buff bar.", suggested = true },
        { key = "missingBuffExpiry", label = "Expiring buff warnings", help = "Warn before readable buffs expire.\nChoose warning times in Buffs.", suggested = false },
        { key = "missingBuffCombat", label = "Combat buff reminders", help = "Passive reminders for selected buffs.\nRefresh them from your action bar.", suggested = false },
        { key = "missingBuffWeapons", label = "Weapon coatings", help = "Remind you of selected oils and poisons.\nChoose supplies in Macros first.", suggested = false },
    } },
    { title = "Make room for your journey.", short = "Map & bags", description = "Choose map, bag and window tools. Scroll to see every choice.\nUse Edit Mode to position the minimap; window layouts save automatically.",
        tip = "Outside combat: drag empty window headers, Ctrl+scroll there to resize, and Ctrl+right-click to reset. Bags and many standard windows are supported.", options = {
        { key = "squareMinimap", label = "Square minimap", help = "An area header and an inset clock.\nNative map controls stay available.", suggested = true },
        { key = "minimapStats", label = "Minimap stats", help = "FPS and home/world latency below\nnative coordinates. Click for settings.", suggested = true },
        { key = "minimapDrawer", label = "Addon button drawer", help = "Gather supported addon buttons.\nClick the grid to open the drawer.", suggested = false },
        { key = "minimapButton", label = "Suite minimap button", help = "Keep settings close at hand.\n/wfs also works when it is hidden.", suggested = true },
        { key = "revealWorldMap", label = "Reveal world map", help = "Show unvisited terrain dimmed.\nVisit areas for exploration credit.", suggested = false },
        { key = "windowTools", label = "Move and save windows", help = "Move bags and standard windows.\nResize with Ctrl+scroll on headers.", suggested = true },
        { key = "showFPS", label = "Show FPS", help = "Include FPS in the minimap stats.\nNeeds Minimap stats above.", suggested = true },
        { key = "showLatency", label = "Show latency", help = "Include home and world latency.\nNeeds Minimap stats above.", suggested = true },
        { key = "showCoordinates", label = "Map coordinates", help = "Use the native minimap coordinates.\nManaged by the enabled map tools.", suggested = true },
        { key = "showClock", label = "Minimap clock", help = "Keep the native clock available\nwith the Suite minimap tools.", suggested = true },
        { key = "bagSpaceAlert", label = "Low bag space alert", help = "Offer a low-value stack when full.\nDiscarding always needs confirmation.", suggested = false },
        { key = "reverseCombinedBags", label = "Reverse bag order", help = "Show equipped bags before backpack\nin the native combined bag.", suggested = false },
        { key = "reverseBagSlots", label = "Reverse bag slots", help = "Reverse the display inside each bag.\nItems stay in their current bags.", suggested = false },
        { key = "inventorySearch", label = "Inventory search", help = "Search recorded items across alts.\nLog into alts and visit banks first.", suggested = true },
        { key = "characterDashboard", label = "Record characters", help = "Save levels, gold and profession ranks.\nRecorded information can be stale.", suggested = true },
    } },
    { title = "Keep useful details close.", short = "Items & social", description = "Choose gear details, recorded inventory and a few quieter conveniences.\nUse the sidebar later to fine-tune each feature.",
        tip = "Log into alts to record inventory and mail names; visit banks to record their contents. Create supply macros explicitly in Macros, then drag them to a bar.", options = {
        { key = "itemLevels", label = "Gear icon levels", help = "Quality-colored levels on gear.\nFood and reagents stay unlabeled.", suggested = true },
        { key = "itemTooltipLevels", label = "Gear tooltip levels", help = "Add equipment and weapon levels\nto native and comparison tooltips.", suggested = true },
        { key = "characterItemLevel", label = "Character item level", help = "Show your equipped average\nabove the character model.", suggested = true },
        { key = "playerItemLevel", label = "Player tooltip levels", help = "Show equipment level on hover.\nOther players need an inspect.", suggested = false },
        { key = "itemInventory", label = "Inventory in tooltips", help = "Recorded counts across characters.\nUnrecorded locations stay hidden.", suggested = true },
        { key = "offlineBank", label = "Bank snapshots", help = "Record bank visits; browse anywhere\nwith /wfs bank. Items stay in bank.", suggested = true },
        { key = "mailHelper", label = "Mail contacts", help = "Full names beside Send Mail.\nClick a name to fill the To field.", suggested = true },
        { key = "mailRememberRecipient", label = "Remember recipient", help = "Keep To after a successful send.\nClears when you close the mailbox.", suggested = false },
        { key = "chatStyle", label = "Suite chat style", help = "A quieter chat panel and copy tool.\nAdjust font and opacity in Chat.", suggested = false },
        { key = "campingBar", label = "Camping bar", help = "Rest and use carried camp objects\nwhile Campfire Nearby is active.", suggested = false },
        { key = "upgradeHints", label = "Gear upgrade hints", help = "Hints use your chosen stat weights.\nThey are not definitive best-in-slot.", suggested = false },
        { key = "classNames", label = "Class-colored names", help = "Color player tooltip names by class.\nKeeps the native tooltip content.", suggested = true },
        { key = "modifierDisenchant", label = "Disenchant shortcut", help = "Modifier-click eligible bag gear.\nDisenchanting destroys that item.", suggested = false },
        { key = "disenchantModifier", label = "Disenchant modifier", help = "Choose Alt, Ctrl or Shift for the\noptional disenchant shortcut above.", choices = { "alt", "ctrl", "shift" }, labels = { alt = "Alt", ctrl = "Ctrl", shift = "Shift" }, suggested = "alt" },
        { key = "chatHistory", label = "Remember chat history", help = "Save recent chat through reloads.\nClear saved messages in Chat settings.", suggested = false },
        { key = "macroUpdates", label = "Update owned macros", help = "Update macros you explicitly created.\nCreates no new macros during setup.", suggested = false },
        { key = "audioSync", label = "Sync audio output", help = "Follow the system's playback device.\nUses the game's audio refresh.", suggested = false },
    } },
    { title = "Review your setup.", short = "Review", description = "Only the changes listed below will apply when you finish.\nBack lets you revise any page. Later discards this draft.",
        tip = "After applying, arrange your HUD in Edit Mode and try moving a bag. Each Suite feature can be changed independently from the sidebar.", options = {} },
}

local function Read(value, kind) return Suite.IsReadable(value) and type(value) == kind end
local function Valid(option, value)
    if option.choices then
        if not Read(value, "string") then return false end
        for _, choice in ipairs(option.choices) do if value == choice then return true end end
        return false
    end
    return Read(value, "boolean")
end

-- Only offer settings actually supported by this build. New installed features can
-- use the same guide without inventing settings in older source snapshots.
local options = {}
for _, page in ipairs(Setup.pages) do
    local available = {}
    for _, option in ipairs(page.options) do
        if option.native or Valid(option, Suite.defaults[option.key]) then
            available[#available + 1], options[option.key] = option, option
        end
    end
    page.options = available
end

function Setup:InitializeState(value)
    if not Read(value, "table") then value = {} end
    local completed = Read(value.completed, "boolean") and value.completed or false
    return { version = self.version, seen = completed or (Read(value.seen, "boolean") and value.seen or false),
        completed = completed }
end

function Setup:AutoLoot()
    if not Read(C_CVar, "table") or type(C_CVar.GetCVarInfo) ~= "function"
        or type(C_CVar.SetCVar) ~= "function" then return end
    local ok, value, _, _, _, locked, secure, readOnly = pcall(C_CVar.GetCVarInfo, "autoLootDefault")
    if not ok or not Read(value, "string") or (value ~= "0" and value ~= "1")
        or not Read(locked, "boolean") or locked or not Read(secure, "boolean") or secure
        or not Read(readOnly, "boolean") or readOnly then return end
    return value == "1"
end

function Setup:Current(option)
    if option.native then return self:AutoLoot() end
    local value = Suite.db[option.key]
    if Valid(option, value) then return value end
    return Suite.defaults[option.key]
end

function Setup:Begin()
    if self.draft or not Suite.db then return end
    self.draft, self.dirty, self.page, self.message = {}, {}, 1, nil
    for key, option in pairs(options) do self.draft[key] = self:Current(option) end
end

function Setup:Stage(key, value)
    local option = Read(key, "string") and options[key]
    if not self.draft or not option or not Valid(option, value) then return false end
    if option.native and self:AutoLoot() == nil then return false end
    self.draft[key] = value
    self.dirty[key] = true
    self.message = nil
    return true
end

function Setup:ChoosePage(suggested)
    if not self.draft then return end
    for _, option in ipairs(self.pages[self.page].options) do
        if suggested then self:Stage(option.key, option.suggested)
        else
            self.draft[option.key] = self:Current(option)
            self.dirty[option.key] = nil
        end
    end
    self.message = nil
end

function Setup:Move(page)
    if not Read(page, "number") or page ~= math.floor(page) or not self.pages[page] then return end
    self.page, self.message = page, nil
    Suite.GUI:RefreshSetup()
end

function Setup:Changes(page)
    local result = {}
    if not self.draft then return result end
    for _, option in ipairs(self.pages[page].options) do
        local value = self.draft[option.key]
        if self.dirty[option.key] and Valid(option, value) and value ~= self:Current(option) then
            result[#result + 1] = option.label .. ": " .. (option.choices and option.labels[value] or (value and "On" or "Off"))
        end
    end
    return result
end

function Setup:Dismiss()
    if not Suite.db or not self.draft then return end
    Suite.db.setupGuide.seen = true
    self.draft, self.dirty, self.message = nil, nil, nil
end

function Setup:Open()
    if not Suite.db then return end
    Suite.AfterCombat("setupOpen", function()
        if not Suite.db then return end
        Suite.GUI:OpenPage("setup")
        local shown = Suite.GUI.frame and Suite.GUI.frame:IsShown()
        if Suite.GUI.page == "setup" and self.draft and Read(shown, "boolean") and shown then
            Suite.db.setupGuide.seen = true
        end
    end)
end

function Setup:OnLogin()
    if Suite.db and not Suite.db.setupGuide.seen then self:Open() end
end

function Setup:Finish()
    if not self.draft or self.page ~= #self.pages then return false end
    if InCombatLockdown() then
        self.message = "Finish this setup outside combat. Your choices are still staged."
        Suite.GUI:RefreshSetup()
        return false
    end
    -- Native preferences are a one-time explicit choice, never enforced on later logins.
    if self.dirty.autoLoot and Valid(options.autoLoot, self.draft.autoLoot) then
        local current, desired = self:AutoLoot(), self.draft.autoLoot
        if current == nil then
            self.message = "Auto Loot is unavailable. Use current choices on Everyday to leave it unchanged."
            Suite.GUI:RefreshSetup()
            return false
        end
        if current ~= desired then
            local ok, success = pcall(C_CVar.SetCVar, "autoLootDefault", desired and "1" or "0")
            if not ok or not Read(success, "boolean") or not success or self:AutoLoot() ~= desired then
                self.message = "The game did not confirm Auto Loot. Check Options > Controls, then try again."
                Suite.GUI:RefreshSetup()
                return false
            end
        end
    end
    for key, option in pairs(options) do
        if not option.native and self.dirty[key] and Valid(option, self.draft[key]) then Suite.db[key] = self.draft[key] end
    end
    Suite.db.setupGuide.seen, Suite.db.setupGuide.completed = true, true
    self.draft, self.dirty, self.message = nil, nil, nil
    Suite.Apply()
    Suite.GUI:Select("overview")
    Suite.Print("Setup applied. Arrange your HUD in Edit Mode; /wfs setup opens the guide again.")
    return true
end
