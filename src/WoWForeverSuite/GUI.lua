local addonName, Suite = ...
local GUI = { rows = {}, tabs = {} }
Suite.GUI = GUI
local LOGO_TEXTURE = "Interface\\AddOns\\" .. addonName .. "\\Media\\ForeverSuiteLogo.tga"
local Catalog = Suite.SettingsCatalog
local CONTENT_WIDTH, BODY_HEIGHT = 816, 628
local WINDOW_WIDTH, WINDOW_HEIGHT, SIDEBAR_WIDTH = 1120, 760, 208
GUI.contentWidth, GUI.detailWidth = CONTENT_WIDTH, 780

local palette = {
    background = { 0.035, 0.05, 0.065 }, sidebar = { 0.055, 0.075, 0.09 },
    row = { 0.07, 0.095, 0.11 }, accent = { 0.41, 0.84, 0.75 },
    text = { 0.88, 0.91, 0.93 }, muted = { 0.55, 0.65, 0.7 }, gold = { 0.9, 0.72, 0.4 },
}

local function Fill(frame, color)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    frame:SetBackdropColor(unpack(color))
end

local function Text(parent, size, color)
    local font = parent:CreateFontString(nil, "OVERLAY")
    font:SetFont("Fonts\\FRIZQT__.TTF", size)
    font:SetTextColor(unpack(color))
    font:SetJustifyH("LEFT")
    return font
end

local pages = {
    leveling = { title = "Leveling", description = "Your XP, gold and pace in one compact tracker.", rows = {
        { key = "levelingBar", label = "Leveling tracker", help = "Stack XP/hour, net gold/hour, level progress and time to level.\nStarts at the top left. Drag its unlocked header; position saves per character." },
        { action = "levelingLock", label = "Lock tracker", help = "Locked clicks pass through; hover details remain available.\nThe header lock and minimize buttons stay clickable." },
        { action = "levelingMinimize", label = "Minimize tracker", help = "Show only the Leveling header. Tracking continues while minimized.\nClick the header's + button to expand it again." },
        { action = "levelingSession", label = "Start a new session", help = "Reset tracked XP, gold and elapsed time. Rates appear after one minute.\nReload keeps the session; a fresh login starts a new one. Idle time counts." },
        { action = "levelingPosition", label = "Reset tracker position", help = "Return this character's tracker to the top left.\nCtrl-right-clicking its unlocked header also resets its position." },
    }, note = "Gold/hour includes spending and transfers. Estimates use your session pace; incomplete XP tracking shows no estimate." },
    professions = { title = "Professions", description = "Plan training costs and use deliberate profession shortcuts.", rows = {
        { key = "modifierDisenchant", label = "Modifier-click Disenchant", help = "Hold the selected modifier and left-click highlighted bag equipment.\nDisenchant destroys the item; the character must know the spell." },
        { action = "disenchantModifier", label = "Choose modifier key", help = "Cycle Alt, Ctrl and Shift. Hold only that modifier.\nEquipped gear, bank items, locked slots and combat are excluded." },
        { key = "trainingPlanner", label = "Record trainer offerings", help = "Save class skills separately from weapon trainer visits.\nStarts off. Training purchases remain manual." },
        { key = "trainingAuto", label = "Show Training Planner at trainers", help = "Open Class or Weapons beside the trainer after offerings arrive.\nClosing the planner dismisses it for that visit." },
        { key = "trainingLevelUp", label = "Show Training Planner on level up", help = "Show saved class training after each level while recording is enabled.\nWeapon trainer visits keep their own list." },
        { action = "trainingOpen", label = "Open Training Planner", help = "Review class training and your faction's weapon-trainer reference.\nWeapon visits save their own locations and prices." },
    }, note = "Only uncommon, rare or epic weapons and armor are offered.\nThe game makes the final skill and eligibility check. Nothing is disenchanted automatically." },
    castbars = { title = "Castbars", description = "Adjust player, target and focus castbar sizes. Native positions are kept.", rows = {},
        note = "Each bar is optional. Turning custom size off restores its native dimensions.\nPreview ends on leaving this page or a real cast; combat cleanup waits until combat ends." },
    audio = { title = "Audio", description = "Keep game sound with the Windows playback device you choose.", rows = {
        { key = "audioSync", label = "Follow Windows audio device", help = "Switch game sound when your default Windows playback device changes.\nUses System Default output; refreshing may briefly interrupt sound." },
        { action = "audioRefresh", label = "Sync now", help = "Refresh game sound for your current Windows default device.\nWaits until movies and cinematics finish." },
    }, note = "Disabling stops syncing. Choose a fixed device in the game's Audio settings.\nYour volume, mute, microphone and voice-chat choices stay under your control." },
    profiles = { title = "Profiles", description = "Save a familiar setup, share it, or make it personal.", rows = {},
        note = "Switches reload the UI. Gear weights, macros, inventory and contacts stay separate.\nNative Edit Mode layouts, keybindings and the character leveling tracker keep their own settings." },
    setup = { title = "Setup guide", description = "Five steps to a setup that feels like yours.", rows = {} },
    overview = { title = "A little less friction.", description = "Choose the tools that belong in your everyday setup.\nStart with Setup guide for a tour of the main choices.", rows = {
        { key = "squareMinimap", label = "Square minimap", help = "Area and subzone header with a clock inside the map.\nMove closer to screen edges in Edit Mode, then save the layout." },
        { key = "minimapStats", label = "Minimap stats", help = "FPS and home/world latency below Blizzard's coordinates.\nClick the stats row to open this panel; customize it in Minimap." },
        { key = "windowTools", label = "Window tools", help = "Drag a header to move. Ctrl+scroll to resize.\nCtrl+right-click the header to reset position and size." },
        { key = "itemLevels", label = "Item levels on icons", help = "Show quality-colored levels at the top right of gear icons.\nEnable tooltip item levels separately in Items or Tooltips." },
        { key = "upgradeHints", label = "Possible upgrades", help = "A teal + marks a possible upgrade under your chosen comparison.\nChoose Stats or Item level in Gear Details; effects need your judgment." },
        { key = "playerItemLevel", label = "Player item levels", help = "Hover yourself or a nearby player to see equipment level.\nOther players need an available inspect; requests pause in combat." },
    } },
    minimap = { title = "Minimap", description = "A compact header, a clear map, and room for Blizzard's coordinates.", rows = {
        { key = "minimapButton", label = "Minimap button", help = "Show the Suite settings button. /wfs works when hidden." },
        { key = "minimapDrawer", label = "Addon button drawer", help = "Click the grid button to open addons; drag it around the map." },
        { key = "squareMinimap", label = "Square map and header", help = "Area and subzone header, with the clock inside. Move it in Edit Mode.\nHides the checkered quest ring; keeps the quest boundary." },
        { key = "minimapStats", label = "Stats row", help = "A slim row below the coordinates. Click to open Forever Suite." },
        { key = "showFPS", label = "Frame rate", help = "Show frames per second in the enabled stats row." },
        { key = "showLatency", label = "Home and world latency", help = "Show H: home and W: world response times in milliseconds." },
        { key = "showCoordinates", label = "Fallback coordinates", help = "Show coordinates here when Blizzard's display is disabled." },
        { key = "showClock", label = "Fallback local clock", help = "Show local time here when the native clock is hidden." },
    }, note = "The drawer includes Suite settings. Turn it off to return addon buttons to the map." },
    worldmap = { title = "See the road ahead.", description = "Reveal unexplored terrain on the world map.", rows = {
        { key = "revealWorldMap", label = "Reveal unexplored areas", help = "Show unvisited terrain over a dark, translucent area cover.\nExplored areas and surrounding map artwork keep their normal appearance." },
    }, note = "This changes the map view. Discoveries and exploration credit still require visiting each area." },
    windows = { title = "Put things where you want them.", description = "Window movement, bag sorting and bank snapshots have independent switches.", rows = {
        { key = "windowTools", label = "Move and remember windows", help = "Drag a header to move. Ctrl+scroll to resize.\nCtrl+right-click the header to reset position and size." },
        { action = "reset", label = "Reset all windows", help = "Clear all saved window positions and sizes at once.\nBags return to Blizzard's default arrangement." },
        { key = "offlineBank", label = "Bank snapshots", help = "Save bank items and slot positions during bank visits.\nView the last recorded bank anywhere, with normal item tooltips." },
        { action = "bankView", label = "Open bank view", help = "Browse saved character and account bank pages.\nMoving items and buying bank slots require a bank visit." },
        { action = "bankBindings", label = "Bank keybind", help = "Assign Open bank view under Forever Suite in Keybindings.\nYou can also open the saved view with /wfs bank." },
        { key = "sortBagsOnOpen", label = "Sort bags on opening", help = "Use the game's cleanup and bag exclusions once per opening.\nWaits through combat; skips sorting while you hold an item." },
        { key = "inventorySearch", label = "Search across characters", help = "Show recorded item owners beside the bag or bank.\nLog into alts and visit their banks to record counts; hover for dates." },
    }, note = "Move and resize outside combat. Layouts save automatically. Bag title clicks open their menus; dragging moves the bag." },
    items = { title = "Know what you picked up.", description = "Clear item levels and a stat comparison you can understand.", rows = {
        { key = "itemLevels", label = "Item levels on icons", help = "Show quality-colored equipment and weapon levels at the top right of icons." },
        { key = "itemTooltipLevels", label = "Item levels in tooltips", help = "Show item levels for equipment and weapons only." },
        { key = "characterItemLevel", label = "Character frame item level", help = "Show your equipped average above the character model.\nThe level and class line keeps its full space." },
        { key = "upgradeHints", label = "Possible upgrades", help = "A teal + marks usable gear for an empty slot or a possible upgrade, including weapons." },
        { action = "upgradePreference", label = "Prefer", help = "Click to prefer Stats or Item level. Stats includes role weights and DPS.\nWeapon comparisons include the hands being replaced." },
        { action = "preset", label = "Comparison profile", help = "Ready-made class and role presets work without editing.\nChoose Automatic, a role, or your own saved weights for this character." },
        { action = "weights", label = "Details & custom weights", help = "See how scores are calculated and choose tooltip detail.\nOptionally create or edit your own weights; built-in presets stay intact." },
    }, note = "Special effects, set bonuses and weapon abilities need your judgment.\nHigher item level can still be worse for your build." },
    tooltips = { title = "Useful details, right on hover.", description = "A few additions to the tooltips you already use.", rows = {
        { key = "itemTooltipLevels", label = "Item level", help = "Show item levels for equipment and weapons, including comparisons." },
        { key = "itemInventory", label = "Item inventory", help = "Show recorded bag and bank counts for characters you've logged into with this on.\nVisit each character's bank to record its counts. Unrecorded locations are hidden; Known total includes only recorded counts." },
        { key = "playerItemLevel", label = "Player equipment level", help = "Inspect nearby players when possible; recent results are cached." },
        { key = "classNames", label = "Class color names", help = "Use each player's class color for their tooltip name." },
    }, note = "Player equipment details depend on inspect range and availability. New inspect requests pause during combat." },
    macros = { title = "Useful macros, without the setup.", description = "Shared recipes and macros for your class. Choose, preview, then create.\nGeneral macros are shared; the last character to update sets their supplies.", rows = {},
        note = "Create never uses an item. Drag the macro from Blizzard's General tab onto your action bar." },
    camping = { title = "A quiet moment by the fire.", description = "Rest, share a camp object, and continue your journey.", rows = {
        { key = "campingBar", label = "Camping bar", help = "Show a small bar while the Campfire Nearby buff is active.\nYour carried camp objects appear automatically, with counts and cooldowns." },
        { action = "campingPose", label = "Preferred resting pose", help = "Choose Sit, Kneel, Sleep or Lie down.\nThe bar's arrow also lets you choose; click its Rest button to perform it." },
        { action = "campingPreview", label = "Preview position", help = "Show a movable outline to position the bar away from a camp.\nDrag its header; closing these settings ends the preview." },
        { action = "campingReset", label = "Reset bar position", help = "Return the camping bar to its starting position." },
    }, note = "Rest and place objects outside combat. Camp capacity, profession requirements and shared cooldowns still apply." },
    meters = { title = "Two views of the fight.", description = "Suite colors, familiar bars, and independent metric and fight menus.", rows = {
        { key = "damageMeters", label = "Damage meters", help = "Show two configurable windows using the game's recorded fights." },
    }, note = "Drag the dotted header area to move; either lower corner resizes. Ctrl+scroll also resizes. Alt+drag detaches; Ctrl+right-click resets." },
    buffs = { title = "Ready for the next pull.", description = "Missing buffs for you and your group, plus class upkeep.\nClickable outside combat; optional passive combat reminders.", rows = {
        { key = "missingBuffs", label = "Missing buff bar", help = "Show reminders for missing buffs and class upkeep." },
        { key = "missingBuffSelf", label = "My missing buffs", help = "Show learned group buffs you can cast on yourself." },
        { key = "missingBuffOutgoing", label = "Buff my party and raid", help = "Click to buff the first listed member missing your learned buff." },
        { key = "missingBuffIncoming", label = "Buffs my group can give me", help = "Show gold Group icons for relevant buffs a nearby teammate may provide.\nLeft-click an icon to request that buff in group chat; browsing never sends." },
        { key = "missingBuffClass", label = "Class upkeep", help = "Aspects, armor, auras, totems, shields, imbues and rogue poisons." },
        { action = "buffPreview", label = "Preview position", help = "Drag the preview header. Closing settings ends the preview." },
        { action = "buffReset", label = "Reset bar position", help = "Restore the top-center position near breath and fatigue bars.\nCtrl+right-click its header also resets." },
        { action = "buffChoices", label = "Restore buff choices", help = "Undo hidden families, selected alternatives and chosen poisons." },
        { key = "missingBuffExpiry", label = "Warn before buffs expire", help = "Short buffs warn at 15 seconds; long buffs use your chosen interval.\nUnknown expiry never counts as an expiring buff." },
        { action = "buffWarning", label = "Long-buff warning interval", help = "Cycle 30, 60 or 120 seconds for buffs lasting at least 30 minutes and coatings." },
        { key = "missingBuffCombat", label = "Combat buff reminders", help = "Show passive reminders for selected shouts, Thorns, shields and Righteous Fury.\nRefresh from your action bar; restricted aura data is skipped." },
        { key = "missingBuffWeapons", label = "Weapon coating reminders", help = "Use main/off-hand choices from Macros for stones, oils and poisons.\nCarried compatible supplies appear on the bar.\nMissing supplies use local chat reminders." },
        { action = "buffCustom", label = "Custom learned buff spells", help = "Find learned spells by name and icon; add up to eight reminders.\nChoose Self or Party / raid; custom spells stay outside combat." },
        { action = "buffManage", label = "Manage buff reminders", help = "See hidden families, restore individual reminders and choose learned alternatives." },
        { action = "buffAppearance", label = "Buff bar appearance", help = "Adjust scale and icon size, lock movement and choose rested-area behavior." },
    }, note = "Teal icons cast your buffs; gold Group icons show buffs teammates may provide. Missing supplies use local chat. Right-click chooses alternatives or hides a family." },
    actionbars = { title = "Your buttons, Suite style.", description = "Slate and teal to match your meters and minimap.", rows = {
        { key = "fullButtonRange", label = "Full button range indicator", help = "Turn the whole action icon red when your target is out of range.\nButtons return to their normal colors when range clears." },
        { key = "actionBarSkin", label = "Suite action bar skin", help = "Square icons, slate backgrounds and fine teal borders.\nIncludes pet and stance buttons; removes the main bar's ornamental art." },
    }, note = "Arrange Blizzard bars in Edit Mode. Bindings, cooldowns, glows and clicks stay native.\nSkin and font changes wait until combat ends; disabling them restores the native look." },
    bars = { title = "The finishing touches.", description = "Slate surfaces and fine teal borders for your other bars.", rows = {
        { key = "statusBarSkin", label = "XP, honor and reputation bars", help = "Give your progress bars a slate background and thin teal outline.\nKeep native fill colors, rested XP, text and tooltips." },
        { key = "bagBarSkin", label = "Suite bag bar skin", help = "Frame native bag icons with fitted teal borders and hover feedback.\nKeep free-slot counts, highlights and clicks." },
        { key = "microBarSkin", label = "Suite micro menu skin", help = "Slate menu buttons with teal borders and hover feedback.\nKeep native icons, alerts, tooltips and shortcuts." },
        { key = "playerBuffBorders", label = "Player buff borders", help = "Square icons with fine teal borders in your top-right buff display.\nDebuffs, weapon enchants and unit-frame auras keep their native appearance." },
    }, note = "Move these bars in Edit Mode. Progress options use the progress bar skin.\nValues stay visible in combat; layout and skin changes wait until it ends." },
    unitframes = { title = "Unit frame details", description = "Optional color and threat details on your existing unit frames.", rows = {
        { key = "classHealthBars", label = "Class colored health bars", help = "Softer class colors for player, target, target of target and focus.\nReplace the original fill so its color stays clear." },
        { key = "targetThreat", label = "Target threat indicator", help = "Your threat against the target: grey at 0%, red at 100%.\nA translucent Blizzard-style rectangle moves below the frame when buffs are on top." },
    }, note = "NPCs and vehicles keep their normal health bars. Party and raid use Blizzard's class color setting.\nThreat appears for enemy NPCs; -- means no percentage is available." },
    mail = { title = "A familiar name, a quicker letter.", description = "Your characters and saved recipients beside the mailbox.", rows = {
        { key = "mailHelper", label = "Mail contacts", help = "Show full character names and rulesets beside Send Mail.\nClick a name to fill To; Blizzard handles delivery rules." },
        { key = "mailRememberRecipient", label = "Remember recipient", help = "Keep the recipient in the To field after a successful send.\nClosing the mailbox clears it for the next visit." },
    }, note = "Known alts fill missing last names from account autocomplete when available. Your active character stays hidden. Save full names in To for any unresolved contact." },
    chat = { title = "A quieter place for conversation.", description = "A clean chat panel using your active settings profile.", rows = {},
        note = "Click the small copy icon on chat, then drag across text and release to copy. A chat message reports the result. Click the icon again for normal chat." },
    vendor = { title = "Ready for the next trip.", description = "Repair your gear and choose how to clear gray-quality junk.", rows = {
        { key = "autoRepair", label = "Automatically repair", help = "Repair when you visit a vendor who offers repairs." },
        { action = "repairSource", label = "Repair funding", help = "Personal uses your gold. Guild requires full permitted guild funds.\nGuild mode skips repairs if those funds are unavailable." },
        { key = "autoSellJunk", label = "Automatically sell junk", help = "Clear gray-quality items when you visit a vendor.\nBoth modes respect bags excluded from junk selling." },
        { action = "junkMode", label = "Junk sale mode", help = "Slow sells one stack at a time, up to 12 per vendor visit.\nInstant sells permanently and accepts the junk-sale popup for you." },
        { action = "junkDetails", label = "Sale and recovery", help = "", passive = true },
    }, note = "Buyback retains only the last 12 sold stacks. Later sales can displace them. Instant sales aren't recoverable." },
    quests = { title = "Keep your journey moving.", description = "Style your tracker and choose how conversations and looting are handled.", rows = {
        { key = "autoQuestPickup", label = "Automatically pick up quests", help = "Open and accept available quests, including low-level quests.\nIgnored quests and PvP confirmations stay manual." },
        { key = "autoQuestTurnIn", label = "Automatically turn in quests", help = "Complete ready quests with no reward choice or one item.\nChoose between multiple rewards yourself; gold costs stay manual." },
        { key = "autoGossip", label = "Automatically advance gossip", help = "Select a single available conversation option when no quests are listed.\nMenus with several options and confirmation prompts stay manual." },
        { key = "quickLoot", label = "Quick loot", help = "Collect auto-loot as soon as it is ready.\nUses the game's Auto Loot setting and modifier key." },
        { key = "questTrackerSkin", label = "Suite quest tracker skin", help = "A slate tracker with one outline, underlined headers and teal buttons.\nKeep native quest colors, controls and text-size settings." },
        { key = "questItemButton", label = "Nearby quest-item button", help = "A compact, draggable item icon near quest objectives; left-click to use it.\nHides in combat. Ctrl-right-click resets its position; bind it under Forever Suite." },
        { key = "zoneReputation", label = "Track reputation for this zone", help = "Watch the home-city faction in known outdoor zones and towns.\nUnmapped zones and instances keep your watched faction." },
    }, note = "Hold Shift when talking to pause quests. Repeatable quests run once per visit.\nLoot rolls and bind confirmations keep their normal behavior." },
}

Catalog:Configure(pages)

function GUI:Action(action)
    if action == "levelingSession" then Suite.Leveling:ResetSession()
    elseif action == "levelingPosition" then Suite.Leveling:ResetPosition()
    elseif action == "levelingLock" then Suite.Leveling:SetLocked(not Suite.Leveling.db.locked); self:Select("leveling")
    elseif action == "levelingMinimize" then Suite.Leveling:SetMinimized(not Suite.Leveling.db.minimized); self:Select("leveling")
    elseif action == "disenchantModifier" then
        Suite.Set("disenchantModifier", ({ alt="ctrl", ctrl="shift", shift="alt" })[Suite.ProfessionHelper:Modifier()]); self:Select("professions")
    elseif action == "trainingOpen" then Suite.Training:Open()
    elseif action == "buffCustom" then Suite.BuffReminders:OpenOptions()
    elseif action == "buffAppearance" then Suite.BuffSettings:Open("display")
    elseif action == "buffManage" then Suite.BuffSettings:Open("choices")
    elseif action == "buffWarning" then
        Suite.Set("missingBuffWarning", ({ [30]=60, [60]=120, [120]=30 })[Suite.db.missingBuffWarning] or 60)
        self:Select("buffs")
    elseif action == "audioRefresh" then Suite.Audio:SyncNow()
    elseif action == "reset" then Suite.Windows:ResetAll()
    elseif action == "bagSpaceReset" then Suite.BagSpace:ResetBlacklist()
    elseif action == "bankView" then Suite.OfflineBank:Toggle()
    elseif action == "bankBindings" then
        if InCombatLockdown() then Suite.Print("Open keybinding settings outside combat."); return end
        if Settings and Settings.OpenToCategory and Settings.KEYBINDINGS_CATEGORY_ID then
            self.frame:Hide()
            Settings.OpenToCategory(Settings.KEYBINDINGS_CATEGORY_ID, BINDING_HEADER_WOWFOREVERSUITE)
        else Suite.Print("Open Options → Keybindings → Forever Suite to assign Open bank view.") end
    elseif action == "upgradePreference" then
        Suite.Scoring:SetPreference(Suite.Scoring.Preference(Suite.db) == "stats" and "ilevel" or "stats")
        self:Select(self.page)
    elseif action == "preset" then Suite.GearSettings:Open("picker")
    elseif action == "weights" then Suite.GearSettings:Open("editor")
    elseif action == "campingPose" then
        local poses, current = Suite.Camping.poses, Suite.Camping:GetPose()
        for index, pose in ipairs(poses) do
            if pose == current then Suite.Camping:SelectPose(poses[index % #poses + 1].key); break end
        end
    elseif action == "campingPreview" then
        Suite.Camping:SetPreview(not (Suite.Camping.preview and Suite.Camping.preview:IsShown()))
    elseif action == "campingReset" then Suite.Camping:ResetPosition()
    elseif action == "buffPreview" then Suite.MissingBuffs:SetPreview(not (Suite.MissingBuffs.preview and Suite.MissingBuffs.preview:IsShown()))
    elseif action == "buffReset" then Suite.MissingBuffs:ResetPosition()
    elseif action == "buffChoices" then Suite.MissingBuffs:ResetChoices()
    elseif action == "repairSource" then
        Suite.Set("repairSource", Suite.db.repairSource == "personal" and "guild" or "personal"); self:Select("vendor")
    elseif action == "junkMode" then
        Suite.Set("junkMode", Suite.db.junkMode == "slow" and "instant" or "slow"); self:Select("vendor")
    end
end

function GUI:GetRow(index)
    if self.rows[index] then return self.rows[index] end
    local row = CreateFrame("Button", nil, self.content, "BackdropTemplate")
    row:SetSize(CONTENT_WIDTH, 66)
    row:SetPoint("TOPLEFT", 0, -88 - (index - 1) * 72)
    row.label = Text(row, 13, palette.text)
    row.label:SetPoint("TOPLEFT", 14, -16)
    row.label:SetWidth(CONTENT_WIDTH - 150)
    row.help = Text(row, 11, palette.muted)
    row.help:SetPoint("TOPLEFT", 13, -29)
    row.help:SetWidth(CONTENT_WIDTH - 130)
    row.help:SetHeight(30)
    row.help:SetWordWrap(true)
    row.help:SetJustifyV("TOP")
    row.switch = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.switch:SetSize(38, 18)
    row.switch:SetPoint("RIGHT", -14, 0)
    row.switch.knob = row.switch:CreateTexture(nil, "OVERLAY")
    row.switch.knob:SetSize(12, 12)
    row.switch.knob:SetColorTexture(0.9, 0.94, 0.95)
    row.value = Text(row, 11, palette.accent)
    row.value:SetPoint("RIGHT", -14, 0)
    row.value:SetJustifyH("RIGHT")
    row.value:SetWidth(120); row.value:SetWordWrap(false)
    Fill(row, palette.row)
    row:SetScript("OnEnter", function() row:SetBackdropColor(0.09, 0.13, 0.145) end)
    row:SetScript("OnLeave", function() Fill(row, palette.row) end)
    self.rows[index] = row
    return row
end

function GUI:Select(key)
    self:StopScrollDrags()
    if not Suite.IsReadable(key) or type(key) ~= "string" or not pages[key] then return end
    local previousPage, previousScroll = self.page, self.scrollOffset or 0
    Suite.pending.settingsReveal = nil
    self.selectionSerial = (self.selectionSerial or 0) + 1
    if key == "setup" and not self.setupPanel and InCombatLockdown() then Suite.Setup:Open(); return end
    if key ~= "setup" then Suite.pending.setupOpen = nil end
    if key ~= "characters" then
        Suite.pending.dashboardBuild, Suite.pending.dashboardView = nil, nil
        Suite.CharacterBrowser:SetVisible(false)
    end
    if self.page == "setup" and key ~= "setup" then Suite.Setup:Dismiss() end
    if key ~= "buffs" then Suite.BuffSettings:Dismiss() end
    if key ~= "items" then Suite.GearSettings:Dismiss() end
    if key ~= "profiles" then Suite.ProfileSettings:Dismiss() end
    self.page = key
    self:ClearSettingHighlight()
    self:ClearSearch()
    self:LayoutNavigation(key)
    Suite.ProfileSettings:RefreshCaption()
    local page = pages[key]
    self.heading:SetText(page.title)
    self.description:SetText(page.description)
    self.note:SetHeight(key == "setup" and 12 or 40)
    self.note:SetText(page.note or "Every tool is optional. Changes apply as you make them.")
    for _, row in ipairs(self.rows) do row:Hide() end
    for _, section in ipairs(self.sections or {}) do section:Hide() end
    if self.homePanel then self.homePanel:SetShown(key == "overview") end
    if key == "overview" then self:BuildHome() end
    if self.profilePanel then self.profilePanel:SetShown(key == "profiles") end
    if key == "profiles" then Suite.ProfileSettings:Build(); Suite.ProfileSettings:Refresh() end
    if self.macroPanel then self.macroPanel:SetShown(key == "macros") end
    if self.gearPanel then self.gearPanel:SetShown(key == "items" and Suite.GearSettings.mode ~= nil) end
    if key == "items" then Suite.GearSettings:Refresh() end
    if self.buffPanel then self.buffPanel:SetShown(key=="buffs" and Suite.BuffSettings.mode~=nil) end
    if key=="buffs" and Suite.BuffSettings.mode then Suite.BuffSettings:Build();Suite.BuffSettings:Refresh() end
    if self.meterPanel then self.meterPanel:SetShown(key == "meters") end
    if self.chatPanel then self.chatPanel:SetShown(key == "chat") end
    if self.characterPanel then self.characterPanel:SetShown(key == "characters") end
    if self.keybindPanel then self.keybindPanel:SetShown(key == "actionbars") end
    if self.progressPanel then self.progressPanel:SetShown(key == "bars") end
    if self.mapPanel then self.mapPanel:SetShown(key == "worldmap") end
    if self.castbarPanel then self.castbarPanel:SetShown(key == "castbars") end
    if self.setupPanel then self.setupPanel:SetShown(key == "setup") end
    if key == "setup" then Suite.Setup:Begin(); self:BuildSetup(); self:RefreshSetup() end
    if key == "macros" then self:BuildMacros() end
    if key == "meters" then self:BuildMeters(); self:RefreshMeters() end
    if key == "chat" then self:BuildChat(); self:RefreshChat() end
    if key == "characters" then self:BuildCharacterDashboard(); Suite.CharacterDashboard:Render() end
    if key == "actionbars" then self:BuildKeybinds(); self:RefreshKeybinds() end
    if key == "bars" then self:BuildProgress(); self:RefreshProgress() end
    if key == "worldmap" then self:BuildWorldMap(); self:RefreshWorldMap() end
    if key == "castbars" then self:BuildCastbars(); self:RefreshCastbars() end
    Suite.Macros:SetVisible(key == "macros" and self.frame:IsShown())
    Suite.Camping:SetSettingsVisible(key == "camping" and self.frame:IsShown())
    Suite.MissingBuffs:SetSettingsVisible(key == "buffs" and self.frame:IsShown())
    local offset, sectionIndex, sectionStart, collapsed = 0, 0, nil, false
    local column, lineHeight, pairedRow = 0, 0, nil
    local function FlushRows()
        if column > 0 then offset = offset + lineHeight + 12; column, lineHeight = 0, 0 end
    end
    self.rowOffsets = {}
    for i, data in ipairs(page.rows) do
        local section = Catalog.sections[key] and Catalog.sections[key][i]
        if section then
            FlushRows()
            if i > 1 then offset = offset + 12 end
            sectionIndex = sectionIndex + 1
            sectionStart = i
            collapsed = self:IsSectionCollapsed(key, i)
            local header = self:GetSection(sectionIndex)
            header.page, header.firstRow = key, i
            header:SetPoint("TOPLEFT", 0, -offset)
            header.label:SetText(section)
            header.indicator:SetText(collapsed and "+" or "-")
            header:Show()
            offset = offset + 25
        end
        if not collapsed then
            local row = self:GetRow(i)
            local nextSection = Catalog.sections[key] and Catalog.sections[key][i + 1]
            local paired = column > 0 or (i < #page.rows and not nextSection)
            local width = paired and (CONTENT_WIDTH - 16) / 2 or CONTENT_WIDTH
            row:SetWidth(width)
            row.label:SetText(data.label); row.label:SetWidth(width - (data.key and 82 or 154))
            row.label:SetWordWrap(true)
            local labelHeight = 16 * math.max(1, math.ceil(#data.label / math.max(1, math.floor((width - (data.key and 82 or 154)) / 7))))
            if row.label.GetStringHeight then
                local measured = row.label:GetStringHeight()
                if Suite.IsReadable(measured) and type(measured) == "number" and measured > 0 and measured < 100 then labelHeight = math.max(labelHeight, math.ceil(measured)) end
            end
            row.label:SetHeight(labelHeight)
            row.help:ClearAllPoints(); row.help:SetPoint("TOPLEFT", 14, -16 - labelHeight - 6)
            row.help:SetWidth(width - 28)
            row.switch:ClearAllPoints(); row.switch:SetPoint("TOPRIGHT", -14, -15)
            row.value:ClearAllPoints(); row.value:SetPoint("TOPRIGHT", -14, -17)
            local help = data.help
            if data.action == "junkDetails" then
                help = Suite.db.junkMode == "instant"
                    and "Warning: items sold instantly aren't recoverable through Buyback.\nWith automatic selling on, permanent sales need no confirmation."
                    or "Sold stacks are recoverable through the vendor's Buyback tab.\nStops at 12 stacks; later sales can replace them in Buyback."
            end
            row.help:SetText(help)
            local lines = select(2, help:gsub("\n", "\n")) + 1
            local helpHeight = lines * 13
            if row.help.GetStringHeight then
                local measured = row.help:GetStringHeight()
                if Suite.IsReadable(measured) and type(measured) == "number" and measured >= 0 and measured < 200 then
                    helpHeight = math.max(helpHeight, math.ceil(measured))
                end
            end
            local height = 16 + labelHeight + 6 + helpHeight + 16
            row.help:SetHeight(helpHeight)
            row:SetHeight(height)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", column * ((CONTENT_WIDTH + 16) / 2), -offset)
            self.rowOffsets[i] = offset
            lineHeight = math.max(lineHeight, height)
            if paired and column == 0 then column, pairedRow = 1, row
            else
                if pairedRow then pairedRow:SetHeight(lineHeight); row:SetHeight(lineHeight) end
                offset = offset + lineHeight + 12; column, lineHeight, pairedRow = 0, 0, nil
            end
            row.label:SetText(data.label)
            row.help:SetText(help)
            row.switch:SetShown(data.key ~= nil)
            row.value:SetShown(data.key == nil)
            if data.key then
                local active = Suite.db[data.key]
                Fill(row.switch, active and palette.accent or { 0.2, 0.27, 0.3 })
                row.switch.knob:ClearAllPoints()
                row.switch.knob:SetPoint(active and "RIGHT" or "LEFT", active and -3 or 3, 0)
                row:SetScript("OnClick", function() Suite.Set(data.key, not Suite.db[data.key]); self:Select(key) end)
            else
                row.value:SetText(data.action == "preset" and (Suite.Scoring:ActiveID() == "automatic" and "Automatic" or Suite.Scoring:Profile().label)
                    or data.action == "buffWarning" and (Suite.db.missingBuffWarning .. "s")
                    or data.action == "disenchantModifier" and Suite.ProfessionHelper:Modifier():upper()
                    or data.action == "upgradePreference" and (Suite.Scoring.Preference(Suite.db) == "ilevel" and "Item level" or "Stats")
                    or data.action == "campingPose" and Suite.Camping:GetPose().label
                    or data.action == "repairSource" and (Suite.db.repairSource == "guild" and "Guild gold" or "Personal gold")
                    or data.action == "junkMode" and (Suite.db.junkMode == "instant" and "Instant" or "Slow")
                    or data.action == "levelingLock" and (Suite.Leveling.db and Suite.Leveling.db.locked and "Locked" or "Unlocked")
                    or data.action == "levelingMinimize" and (Suite.Leveling.db and Suite.Leveling.db.minimized and "Minimized" or "Expanded") or ">")
                if data.passive then row.value:Hide(); row:SetScript("OnClick", nil)
                else row:SetScript("OnClick", function() self:Action(data.action) end) end
            end
            row:Show()
        end
    end
    FlushRows()
    self.detailSection = sectionStart
    self.controlsOffset = offset + (#page.rows > 0 and not collapsed and 12 or 0)
    self:LayoutPage(key)
    self:ScrollTo(previousPage == key and previousScroll or 0)
    for tabKey, tab in pairs(self.tabs) do
        if self.groupTabs[Suite.SettingsCatalog.pageGroup[tabKey].key] ~= tab then
        Fill(tab, tabKey == key and { 0.1, 0.2, 0.21 } or (tab:GetParent() == self.body and palette.row or palette.sidebar))
        tab.indicator:SetShown(tabKey == key)
        tab.label:SetTextColor(unpack(tabKey == key and palette.accent or palette.muted))
        end
    end
end

function GUI:FitToScreen()
    if not self.frame then return end
    if InCombatLockdown() then
        Suite.pending.guiScreenFit = function() self:FitToScreen() end
        return
    end
    Suite.pending.guiScreenFit = nil
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    if not Suite.IsReadable(width) or not Suite.IsReadable(height) or type(width) ~= "number" or type(height) ~= "number"
        or width ~= width or height ~= height or width < 320 or height < 240 or width > 100000 or height > 100000 then return end
    local scale = math.min(1, (width - 48) / WINDOW_WIDTH, (height - 48) / WINDOW_HEIGHT)
    if self.frame:GetScale() ~= scale then self:StopScrollDrags(); self.frame:SetScale(scale) end
end

function GUI:BuildHome()
    if self.homePanel then return end
    local panel = CreateFrame("Frame", nil, self.content)
    self.homePanel = panel; panel:SetSize(780, 402)
    local title = Text(panel, 15, palette.text); title:SetPoint("TOPLEFT", 0, 0)
    title:SetText("Make yourself at home")
    local hint = Text(panel, 11, palette.muted); hint:SetPoint("TOPLEFT", 0, -27)
    hint:SetWidth(780); hint:SetText("Open a workspace on the left, or start with a frequently used tool.")
    self.homeCards = {}
    local entries = {
        { "characters", "Characters & inventory", "Find recorded items, check your alts and browse their saved banks." },
        { "items", "Gear comparisons", "Choose ready-made profiles and see why an item may be an upgrade." },
        { "meters", "Damage meters", "Set up your combat views, appearance and window behavior." },
        { "leveling", "Leveling tracker", "Follow your XP, session pace and progress toward the next level." },
        { "minimap", "Maps & interface", "Arrange your minimap and find the window and chat tools nearby." },
        { "setup", "Guided setup", "Walk through the main choices. Review everything before applying it." },
    }
    for index, entry in ipairs(entries) do
        local card = CreateFrame("Button", nil, panel, "BackdropTemplate")
        card:SetSize(382, 100); card:SetPoint("TOPLEFT", ((index - 1) % 2) * 398, -66 - math.floor((index - 1) / 2) * 112)
        card:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        card:SetBackdropColor(unpack(palette.row)); card:SetBackdropBorderColor(0.13, 0.2, 0.23)
        card.label = Text(card, 14, palette.text); card.label:SetPoint("TOPLEFT", 18, -17)
        card.label:SetText(entry[2]); card.label:SetWidth(330)
        card.help = Text(card, 11, palette.muted); card.help:SetPoint("TOPLEFT", 18, -44)
        card.help:SetSize(346, 42); card.help:SetWordWrap(true); card.help:SetJustifyV("TOP"); card.help:SetText(entry[3])
        card.arrow = Text(card, 16, palette.accent); card.arrow:SetPoint("TOPRIGHT", -16, -16); card.arrow:SetText("›")
        local page = entry[1]; card.page = page
        card:SetScript("OnClick", function() if not InCombatLockdown() then self:Select(page) end end)
        card:SetScript("OnEnter", function() card:SetBackdropBorderColor(unpack(palette.accent)) end)
        card:SetScript("OnLeave", function() card:SetBackdropBorderColor(0.13, 0.2, 0.23) end)
        self.homeCards[index] = card
    end
end

function GUI:BuildCharacterDashboard()
    if self.characterPanel then return end
    if InCombatLockdown() then
        Suite.pending.dashboardBuild = function()
            if self.page == "characters" then self:BuildCharacterDashboard(); self:Select("characters") end
        end
        return
    end
    self.characterPanel = Suite.CharacterDashboard:Build(self.content)
end

function GUI:BuildSetup()
    if self.setupPanel then return end
    local panel = CreateFrame("Frame", nil, self.body)
    panel:SetPoint("TOPLEFT", 18, 0)
    panel:SetSize(780, 550)
    self.setupPanel, self.setupCards, self.setupSteps = panel, {}, {}
    local function Button(x, y, width, label, callback)
        local button = CreateFrame("Button", nil, panel, "BackdropTemplate")
        button:SetSize(width, 26)
        button:SetPoint("TOPLEFT", x, y)
        Fill(button, palette.row)
        button.label = Text(button, 11, palette.accent)
        button.label:SetPoint("CENTER")
        button.label:SetText(label)
        button:SetScript("OnClick", callback)
        return button
    end
    for i, page in ipairs(Suite.Setup.pages) do
        local step = Button((i - 1) * 158, -77, 148, i .. "  " .. page.short, function() Suite.Setup:Move(i) end)
        step.label:SetFont("Fonts\\FRIZQT__.TTF", 10)
        self.setupSteps[i] = step
    end
    self.setupSuggested = Button(0, -109, 194, "Use suggested choices", function()
        Suite.Setup:ChoosePage(true); self:RefreshSetup()
    end)
    self.setupCurrent = Button(200, -109, 172, "Use current choices", function()
        Suite.Setup:ChoosePage(false); self:RefreshSetup()
    end)
    self.setupCount = Text(panel, 10, palette.muted)
    self.setupCount:SetPoint("TOPRIGHT", -2, -117)
    for i = 1, 10 do
        local card = CreateFrame("Button", nil, panel, "BackdropTemplate")
        card:SetSize(384, 60)
        card:SetPoint("TOPLEFT", (i - 1) % 2 * 396, -143 - math.floor((i - 1) / 2) * 64)
        Fill(card, palette.row)
        card.label = Text(card, 11, palette.text)
        card.label:SetPoint("TOPLEFT", 9, -7)
        card.label:SetWidth(317)
        card.value = Text(card, 10, palette.accent)
        card.value:SetPoint("TOPRIGHT", -9, -8)
        card.help = Text(card, 10, palette.muted)
        card.help:SetPoint("TOPLEFT", 9, -25)
        card.help:SetSize(366, 30)
        card.help:SetJustifyV("TOP")
        card:SetScript("OnEnter", function() card:SetBackdropColor(0.09, 0.13, 0.145) end)
        card:SetScript("OnLeave", function() Fill(card, palette.row) end)
        card:SetScript("OnClick", function()
            local option = card.option
            if not option or not Suite.Setup.draft then return end
            local value = Suite.Setup.draft[option.key]
            if option.choices then
                for index, choice in ipairs(option.choices) do
                    if choice == value then Suite.Setup:Stage(option.key, option.choices[index % #option.choices + 1]); break end
                end
            else Suite.Setup:Stage(option.key, not value) end
            self:RefreshSetup()
        end)
        self.setupCards[i] = card
    end
    local scroll = self:CreateSuiteScrollFrame(panel)
    scroll:SetPoint("TOPLEFT", 0, -143)
    scroll:SetSize(750, 316)
    self.setupReview = scroll
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(750, 316)
    scroll:SetScrollChild(child)
    self.setupReviewChild = child
    self.setupReviewText = Text(child, 11, palette.text)
    self.setupReviewText:SetPoint("TOPLEFT", 10, -8)
    self.setupReviewText:SetWidth(730)
    self.setupReviewText:SetWordWrap(true)
    self.setupReviewText:SetJustifyV("TOP")
    self.setupTip = Text(panel, 10, palette.muted)
    self.setupTip:SetPoint("TOPLEFT", 0, -467)
    self.setupTip:SetSize(780, 38)
    self.setupTip:SetJustifyV("TOP")
    self.setupBack = Button(0, -512, 88, "Back", function() Suite.Setup:Move(Suite.Setup.page - 1) end)
    self.setupLater = Button(94, -512, 110, "Later", function() self:Select("overview") end)
    self.setupNext = Button(606, -512, 174, "Next", function()
        if Suite.Setup.page == #Suite.Setup.pages then Suite.Setup:Finish()
        else Suite.Setup:Move(Suite.Setup.page + 1) end
    end)
end

function GUI:RefreshSetup()
    local setup = Suite.Setup
    if self.page ~= "setup" or not self.setupPanel or not setup.draft then return end
    local page = setup.pages[setup.page]
    local review = setup.page == #setup.pages
    self.heading:SetText(page.title)
    self.description:SetText(page.description)
    self.note:SetText("Step " .. setup.page .. " of 5  ·  Choices apply only when you finish.  ·  /wfs setup")
    for i, step in ipairs(self.setupSteps) do
        Fill(step, i == setup.page and { 0.1, 0.2, 0.21 } or palette.row)
        step.label:SetTextColor(unpack(i == setup.page and palette.accent or palette.muted))
    end
    self.setupSuggested:SetShown(not review)
    self.setupCurrent:SetShown(not review)
    self.setupReview:SetShown(review)
    local count, summary = 0, {}
    for i = 1, 4 do
        local changes = setup:Changes(i)
        count = count + #changes
        summary[#summary + 1] = "|cff68d5bf" .. i .. "  " .. setup.pages[i].short .. "|r\n"
            .. (#changes > 0 and table.concat(changes, "\n") or "Keep current choices.")
    end
    self.setupCount:SetText(count .. (count == 1 and " change" or " changes"))
    for i, card in ipairs(self.setupCards) do
        local option = page.options[i]
        card.option = option
        card:SetShown(option ~= nil)
        if option then
            local value = setup.draft[option.key]
            local available = not option.native or setup:AutoLoot() ~= nil
            card:SetEnabled(available)
            card.label:SetText(option.label)
            card.value:SetText(not available and "N/A" or option.choices and option.labels[value] or (value and "ON" or "OFF"))
            card.value:SetTextColor(unpack(available and (option.choices or value) and palette.accent or palette.muted))
            card.help:SetText(available and option.help or "Change this in Options > Controls.\nThe game setting stays unchanged.")
        end
    end
    if review then
        self.setupReviewText:SetText(table.concat(summary, "\n\n"))
        self.setupReviewText:SetHeight(0)
        local height = self.setupReviewText:GetStringHeight()
        if Suite.IsReadable(height) and type(height) == "number" and height >= 0 and height < math.huge then
            self.setupReviewText:SetHeight(height)
            self.setupReviewChild:SetHeight(math.max(316, height + 16))
        end
    end
    self.setupTip:SetText(setup.message or (review and InCombatLockdown()
        and "Apply setup after combat ends. Your choices are still staged." or page.tip))
    self.setupTip:SetTextColor(unpack(setup.message and palette.gold or palette.muted))
    self.setupBack:SetEnabled(setup.page > 1)
    self.setupNext:SetEnabled(not review or not InCombatLockdown())
    self.setupNext.label:SetText(review and "Apply setup" or "Next")
end

function GUI:BuildCastbars()
    if self.castbarPanel then return end
    if InCombatLockdown() then
        Suite.pending.castbarBuild = function()
            if self.page == "castbars" and self.frame:IsShown() then self:BuildCastbars(); self:RefreshCastbars(); self:LayoutPage("castbars") end
        end
        return
    end
    local panel = CreateFrame("Frame", nil, self.content)
    self.castbarPanel, self.castbarKey, self.castbarFields, self.castbarTabs = panel, "player", {}, {}
    panel:SetSize(514, 254)
    local function Button(x, y, width, label, callback)
        local button = CreateFrame("Button", nil, panel, "BackdropTemplate")
        button:SetPoint("TOPLEFT", x, -y); button:SetSize(width, 32); Fill(button, palette.row)
        button.label = Text(button, 12, palette.accent); button.label:SetPoint("LEFT", 10, 0); button.label:SetText(label)
        button:SetScript("OnClick", callback); return button
    end
    for index, key in ipairs(Suite.Castbars.order) do
        self.castbarTabs[key] = Button((index - 1) * 176, 0, 162, key:sub(1,1):upper() .. key:sub(2), function()
            Suite.Castbars:StopPreview(); self.castbarKey = key; self.castbarMessage = nil; self:RefreshCastbars()
        end)
    end
    self.castbarEnable = Button(0, 46, 244, "", function()
        Suite.Castbars:Set(self.castbarKey, "enabled", not Suite.Castbars:Options(self.castbarKey).enabled); self:RefreshCastbars()
    end)
    self.castbarPreviewButton = Button(264, 46, 244, "Preview native castbar", function()
        if Suite.Castbars.preview then Suite.Castbars:StopPreview(); self.castbarMessage = "Preview stopped."
        else local _, message = Suite.Castbars:Preview(self.castbarKey); self.castbarMessage = message end
        self:RefreshCastbars()
    end)
    for index, spec in ipairs({ { "width", "Width", 80, 600 }, { "height", "Height", 8, 60 } }) do
        local key, label, low, high = unpack(spec)
        local x = (index - 1) * 264
        local caption = Text(panel, 12, palette.text); caption:SetPoint("TOPLEFT", x, -103); caption:SetText(label .. " (" .. low .. "–" .. high .. ")")
        local input = CreateFrame("EditBox", nil, panel, "BackdropTemplate")
        input:SetSize(70, 26); input:SetPoint("TOPLEFT", x+174, -96); Fill(input, palette.row)
        input:SetFont("Fonts\\FRIZQT__.TTF", 12, ""); input:SetAutoFocus(false); input:SetNumeric(true); input:SetMaxLetters(3)
        local slider = CreateFrame("Slider", nil, panel)
        slider:SetSize(244, 20); slider:SetPoint("TOPLEFT", x, -136); slider:SetOrientation("HORIZONTAL")
        slider:SetMinMaxValues(low, high); slider:SetValueStep(1); slider:SetObeyStepOnDrag(true); slider:EnableMouse(true); slider:EnableMouseWheel(true)
        slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
        slider:GetThumbTexture():SetSize(10, 16); slider:GetThumbTexture():SetColorTexture(unpack(palette.accent))
        local track = slider:CreateTexture(nil, "BACKGROUND"); track:SetHeight(3)
        track:SetPoint("LEFT", 5, 0); track:SetPoint("RIGHT", -5, 0); track:SetColorTexture(0.17, 0.25, 0.29)
        local function Commit(value)
            if self.castbarSyncing or not Suite.IsReadable(value) or type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return end
            Suite.Castbars:Set(self.castbarKey, key, math.max(low, math.min(high, math.floor(value+0.5)))); self:RefreshCastbars()
        end
        input:SetScript("OnEnterPressed", function() local value = input:GetText(); Commit(Suite.IsReadable(value) and tonumber(value)); input:ClearFocus() end)
        input:SetScript("OnEditFocusLost", function() local value = input:GetText(); Commit(Suite.IsReadable(value) and tonumber(value)) end)
        input:SetScript("OnTextChanged", function(_, userInput)
            if self.castbarSyncing or not Suite.IsReadable(userInput) or userInput ~= true then return end
            local text = input:GetText()
            local value = Suite.IsReadable(text) and tonumber(text)
            -- Leave partial input alone; valid typed dimensions take effect live,
            -- just like dragging the slider, without requiring Enter first.
            if not Suite.IsReadable(value) or type(value) ~= "number" or value < low or value > high or value ~= math.floor(value) then return end
            Suite.Castbars:Set(self.castbarKey, key, value)
            self.castbarSyncing = true; slider:SetValue(value); self.castbarSyncing = nil
            self.castbarStatus:SetText(Suite.Castbars:SizeStatus(self.castbarKey) or "Size updated.")
        end)
        input:SetScript("OnEscapePressed", function() self:RefreshCastbars(); input:ClearFocus() end)
        slider:SetScript("OnValueChanged", function(_, value) Commit(value) end)
        slider:SetScript("OnMouseWheel", function(_, direction)
            if Suite.IsReadable(direction) and type(direction) == "number" and math.abs(direction) == 1 then Commit(Suite.Castbars:Options(self.castbarKey)[key] + direction) end
        end)
        self.castbarFields[key] = { input=input, slider=slider }
    end
    Button(0, 177, 244, "Restore native size", function() Suite.Castbars:Set(self.castbarKey, "enabled", false); self:RefreshCastbars() end)
    self.castbarStatus = Text(panel, 11, palette.muted); self.castbarStatus:SetPoint("TOPLEFT", 0, -225); self.castbarStatus:SetWidth(514)
    panel:SetScript("OnHide", function() Suite.Castbars:StopPreview(); for _, field in pairs(self.castbarFields) do field.input:ClearFocus() end end)
end
function GUI:RefreshCastbars()
    if not self.castbarPanel then return end
    local settings = Suite.Castbars:Options(self.castbarKey)
    self.castbarSyncing = true
    for key, field in pairs(self.castbarFields) do field.input:SetText(tostring(settings[key])); field.slider:SetValue(settings[key]) end
    self.castbarSyncing = nil
    for key, tab in pairs(self.castbarTabs) do Fill(tab, key == self.castbarKey and {0.1,0.2,0.21} or palette.row) end
    self.castbarEnable.label:SetText("Custom size: " .. (settings.enabled and "On" or "Off"))
    self.castbarPreviewButton.label:SetText(Suite.Castbars.preview and "Stop preview" or "Preview native castbar")
    self.castbarStatus:SetText(Suite.Castbars:SizeStatus(self.castbarKey) or self.castbarMessage or "Choose a bar, enable custom size, then adjust its width and height.")
end

function GUI:BuildProgress()
    if self.progressPanel then return end
    local panel = CreateFrame("Frame", nil, self.content)
    self.progressPanel, self.progressControls, self.progressFields = panel, {}, {}
    panel:SetPoint("TOPLEFT", 0, -314); panel:SetSize(514, 194)
    local heading = Text(panel, 14, palette.text)
    heading:SetPoint("TOPLEFT"); heading:SetText("Progress bar options")
    local function Button(key, label, x, y, callback)
        local button = CreateFrame("Button", nil, panel, "BackdropTemplate")
        self.progressControls[key] = { button = button, label = label }
        button:SetPoint("TOPLEFT", x, -y); button:SetSize(244, 34); Fill(button, palette.row)
        button.label = Text(button, 12, palette.accent)
        button.label:SetPoint("LEFT", 12, 0); button.label:SetWidth(220)
        button:SetScript("OnClick", function() callback(); self:RefreshProgress() end)
    end
    local function Toggle(key)
        return function() Suite.Set(key, not (Suite.IsReadable(Suite.db[key]) and Suite.db[key] == true)) end
    end
    Button("progressBarValues", "Always show values", 0, 24, Toggle("progressBarValues"))
    Button("progressBarSegments", "10% sections", 264, 24, Toggle("progressBarSegments"))
    Button("progressBarCustomSize", "Custom size", 0, 64, Toggle("progressBarCustomSize"))
    Button("reset", "Use Edit Mode size", 264, 64, function() Suite.Set("progressBarCustomSize", false) end)
    local function Field(key, label, x, low, high)
        local caption = Text(panel, 12, palette.text)
        caption:SetPoint("TOPLEFT", x, -111); caption:SetText(label)
        local input = CreateFrame("EditBox", nil, panel, "BackdropTemplate")
        input:SetPoint("TOPLEFT", x + 174, -104); input:SetSize(70, 24); Fill(input, palette.row)
        input:SetFont("Fonts\\FRIZQT__.TTF", 12, ""); input:SetTextColor(unpack(palette.accent))
        input:SetAutoFocus(false); input:SetNumeric(true); input:SetMaxLetters(4)
        input:SetJustifyH("CENTER")
        local slider = CreateFrame("Slider", nil, panel)
        self.progressFields[key] = { input = input, slider = slider }
        slider:SetPoint("TOPLEFT", x, -137); slider:SetSize(244, 20)
        slider:SetOrientation("HORIZONTAL"); slider:SetMinMaxValues(low, high)
        slider:SetValueStep(1); slider:SetObeyStepOnDrag(true)
        slider:EnableMouse(true); slider:EnableMouseWheel(true)
        slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
        local thumb = slider:GetThumbTexture()
        if thumb then thumb:SetSize(10, 16); thumb:SetColorTexture(unpack(palette.accent)) end
        local track = slider:CreateTexture(nil, "BACKGROUND")
        track:SetPoint("LEFT", 5, 0); track:SetPoint("RIGHT", -5, 0)
        track:SetHeight(3); track:SetColorTexture(0.17, 0.25, 0.29)
        local function Commit(value)
            if not self.progressSyncing and Suite.IsReadable(value) and type(value) == "number"
                and value == value and math.abs(value) ~= math.huge then
                value = math.max(low, math.min(high, math.floor(value + 0.5)))
                if not Suite.IsReadable(Suite.db[key]) or Suite.db[key] ~= value then Suite.Set(key, value) end
            end
            self:RefreshProgress()
        end
        local function CommitInput()
            local value = input:GetText()
            Commit(Suite.IsReadable(value) and type(value) == "string" and tonumber(value) or nil)
        end
        input:SetScript("OnEnterPressed", function() CommitInput(); input:ClearFocus() end)
        input:SetScript("OnEditFocusLost", CommitInput)
        input:SetScript("OnEscapePressed", function() self:RefreshProgress(); input:ClearFocus() end)
        slider:SetScript("OnValueChanged", function(_, value) if not self.progressSyncing then Commit(value) end end)
        slider:SetScript("OnMouseWheel", function(_, direction)
            if not Suite.IsReadable(direction) or type(direction) ~= "number" or direction ~= direction
                or math.abs(direction) == math.huge then return end
            local width, height = Suite.HUDSkin:Options()
            Commit((key == "progressBarWidth" and width or height) + direction)
        end)
    end
    Field("progressBarWidth", "Width (120–1600)", 0, 120, 1600)
    Field("progressBarHeight", "Thickness (6–40)", 264, 6, 40)
    local help = Text(panel, 10, palette.muted)
    help:SetPoint("TOPLEFT", 0, -168); help:SetWidth(508)
    help:SetText("Type an exact size and press Enter, or use sliders and scroll for small changes.\nCustom size applies to both progress bars. Your Edit Mode position is kept.")
end
function GUI:RefreshProgress()
    if not self.progressPanel then return end
    for key, control in pairs(self.progressControls) do
        local active = Suite.IsReadable(Suite.db[key]) and Suite.db[key] == true
        control.button.label:SetText(control.label .. (key ~= "reset" and (active and ": On" or ": Off") or ""))
    end
    local width, height = Suite.HUDSkin:Options()
    self.progressSyncing = true
    for key, field in pairs(self.progressFields) do
        local value = key == "progressBarWidth" and width or height
        field.input:SetText(tostring(value)); field.slider:SetValue(value)
    end
    self.progressSyncing = nil
end

function GUI:BuildKeybinds()
    if self.keybindPanel then return end
    local panel = CreateFrame("Frame", nil, self.content)
    self.keybindPanel, self.keybindControls = panel, {}
    panel:SetPoint("TOPLEFT", 0, -238); panel:SetSize(514, 276)
    local heading = Text(panel, 14, palette.text)
    heading:SetPoint("TOPLEFT"); heading:SetText("Keybind labels")
    local function Button(key, x, y, callback)
        local button = CreateFrame("Button", nil, panel, "BackdropTemplate")
        self.keybindControls[key] = button
        button:SetPoint("TOPLEFT", x, -y); button:SetSize(244, 34); Fill(button, palette.row)
        button.label = Text(button, 12, palette.accent)
        button.label:SetPoint("LEFT", 12, 0); button.label:SetWidth(220)
        button:SetScript("OnClick", function() callback(); self:RefreshKeybinds() end)
    end
    local function Toggle(key)
        return function() Suite.Set(key, not (Suite.IsReadable(Suite.db[key]) and Suite.db[key] == true)) end
    end
    Button("shortKeybinds", 0, 28, Toggle("shortKeybinds"))
    Button("keybindFontStyle", 264, 28, Toggle("keybindFontStyle"))
    local function Cycle(key, order, selected)
        for index, value in ipairs(order) do
            if value == selected then Suite.Set(key, order[index % #order + 1]); return end
        end
    end
    Button("font", 0, 76, function()
        local font = Suite.Keybinds:Options()
        Cycle("keybindFont", Suite.Keybinds.fontOrder, font)
    end)
    Button("outline", 264, 76, function()
        local _, _, outline = Suite.Keybinds:Options()
        Cycle("keybindOutline", Suite.Keybinds.outlineOrder, outline)
    end)
    Button("keybindBold", 264, 132, Toggle("keybindBold"))
    self.keybindSizeLabel = Text(panel, 12, palette.text)
    self.keybindSizeLabel:SetPoint("TOPLEFT", 0, -128)
    local slider = CreateFrame("Slider", nil, panel)
    self.keybindSizeSlider = slider
    slider:SetPoint("TOPLEFT", 0, -155); slider:SetSize(244, 20)
    slider:SetOrientation("HORIZONTAL"); slider:SetMinMaxValues(8, 24)
    slider:SetValueStep(1); slider:SetObeyStepOnDrag(true)
    slider:EnableMouse(true); slider:EnableMouseWheel(true)
    slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    local thumb = slider:GetThumbTexture()
    if thumb then thumb:SetSize(10, 16); thumb:SetColorTexture(unpack(palette.accent)) end
    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("LEFT", 5, 0); track:SetPoint("RIGHT", -5, 0)
    track:SetHeight(3); track:SetColorTexture(0.17, 0.25, 0.29)
    slider:SetScript("OnValueChanged", function(_, value)
        if self.keybindSyncing or not Suite.IsReadable(value) or type(value) ~= "number"
            or value ~= value or math.abs(value) == math.huge then return end
        Suite.Set("keybindSize", math.max(8, math.min(24, math.floor(value + 0.5))))
        self:RefreshKeybinds()
    end)
    slider:SetScript("OnMouseWheel", function(_, direction)
        if not Suite.IsReadable(direction) or type(direction) ~= "number" or direction ~= direction
            or math.abs(direction) == math.huge then return end
        local _, size = Suite.Keybinds:Options()
        slider:SetValue(math.max(8, math.min(24, size + direction)))
    end)
    local preview = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    preview:SetPoint("TOPLEFT", 0, -194); preview:SetSize(508, 42); Fill(preview, palette.row)
    self.keybindPreview = Text(preview, 12, palette.text)
    self.keybindPreview:SetPoint("LEFT", 12, 0); self.keybindPreview:SetWidth(484)
    local help = Text(panel, 10, palette.muted)
    help:SetPoint("TOPLEFT", 0, -248); help:SetWidth(508)
    help:SetText("Click a font or outline to cycle. Font controls use Custom font.\nBold adds a little size and a stronger shadow; preview your choices above.")
end
function GUI:RefreshKeybinds()
    if not self.keybindPanel then return end
    local module, controls = Suite.Keybinds, self.keybindControls
    local font, size, outline, bold = module:Options()
    local short = Suite.IsReadable(Suite.db.shortKeybinds) and Suite.db.shortKeybinds == true
    local style = Suite.IsReadable(Suite.db.keybindFontStyle) and Suite.db.keybindFontStyle == true
    controls.shortKeybinds.label:SetText("Short keybinds: " .. (short and "On" or "Off"))
    controls.keybindFontStyle.label:SetText("Custom font: " .. (style and "On" or "Off"))
    controls.font.label:SetText("Font: " .. module.fonts[font].label)
    controls.outline.label:SetText("Outline: " .. module.outlines[outline].label)
    controls.keybindBold.label:SetText("Bold treatment: " .. (bold and "On" or "Off"))
    self.keybindSizeLabel:SetText("Text size: " .. size)
    self.keybindSyncing = true
    self.keybindSizeSlider:SetValue(size)
    self.keybindSyncing = nil
    local preview = self.keybindPreview
    local nativePath, nativeFlags = "Fonts\\ARIALN.TTF", "THICKOUTLINE"
    if Suite.IsReadable(NumberFontNormalSmallGray) and NumberFontNormalSmallGray and type(NumberFontNormalSmallGray.GetFont) == "function" then
        local path, _, flags = NumberFontNormalSmallGray:GetFont()
        if Suite.IsReadable(path) and type(path) == "string" and path ~= "" then nativePath = path end
        if Suite.IsReadable(flags) and type(flags) == "string" then nativeFlags = flags end
    end
    local ok, success = pcall(preview.SetFont, preview, module:FontPath(font, nativePath), size + (bold and 1 or 0), module.outlines[outline].flags or nativeFlags)
    if not ok or not Suite.IsReadable(success) or success ~= true then preview:SetFont("Fonts\\ARIALN.TTF", size, "OUTLINE") end
    if type(preview.SetShadowColor) == "function" and type(preview.SetShadowOffset) == "function" then
        preview:SetShadowColor(0, 0, 0, bold and 0.95 or 0)
        preview:SetShadowOffset(bold and 1 or 0, bold and -1 or 0)
    end
    preview:SetText(short and "SCM4   S1   N7   MWU" or "Shift-Ctrl-Mouse4   Shift-1")
end

function GUI:BuildWorldMap()
    if self.mapPanel then return end
    local panel = CreateFrame("Frame", nil, self.content)
    self.mapPanel = panel
    panel:SetPoint("TOPLEFT", 0, -178); panel:SetSize(514, 132)
    local caption = Text(panel, 13, palette.text)
    caption:SetPoint("TOPLEFT"); caption:SetText("Unexplored area opacity")
    self.mapOpacityValue = Text(panel, 13, palette.accent)
    self.mapOpacityValue:SetPoint("TOPRIGHT", -10, 0)
    local slider = CreateFrame("Slider", nil, panel)
    self.mapOpacitySlider = slider
    slider:SetPoint("TOPLEFT", 0, -31); slider:SetSize(504, 20)
    slider:SetOrientation("HORIZONTAL"); slider:SetMinMaxValues(0, 100)
    slider:SetValueStep(1); slider:SetObeyStepOnDrag(true)
    slider:EnableMouse(true); slider:EnableMouseWheel(true)
    slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    local thumb = slider:GetThumbTexture()
    if thumb then thumb:SetSize(10, 16); thumb:SetColorTexture(unpack(palette.accent)) end
    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("LEFT", 5, 0); track:SetPoint("RIGHT", -5, 0)
    track:SetHeight(3); track:SetColorTexture(0.17, 0.25, 0.29)
    local help = Text(panel, 11, palette.muted)
    help:SetPoint("TOPLEFT", 0, -62); help:SetWidth(504); help:SetWordWrap(true)
    help:SetText("0% hides unvisited terrain; 100% shows it fully.\nThe dark cover follows each area; surrounding map artwork stays visible.")
    slider:SetScript("OnValueChanged", function(_, value)
        if self.mapSyncing or not Suite.IsReadable(value) or type(value) ~= "number"
            or value ~= value or math.abs(value) == math.huge then return end
        Suite.WorldMap:SetOpacity(value / 100)
        self:RefreshWorldMap()
    end)
    slider:SetScript("OnMouseWheel", function(_, direction)
        if not Suite.IsReadable(direction) or type(direction) ~= "number" or direction ~= direction
            or math.abs(direction) == math.huge then return end
        slider:SetValue(math.max(0, math.min(100, Suite.WorldMap:Opacity() * 100 + direction)))
    end)
end

function GUI:RefreshWorldMap()
    if not self.mapPanel then return end
    local value = math.floor(Suite.WorldMap:Opacity() * 100 + 0.5)
    self.mapSyncing = true
    self.mapOpacitySlider:SetValue(value)
    self.mapOpacityValue:SetText(tostring(value) .. "%")
    self.mapSyncing = false
end

function GUI:BuildChat()
    if self.chatPanel then return end
    local panel = CreateFrame("Frame", nil, self.content)
    self.chatPanel, self.chatFields = panel, {}
    panel:SetPoint("TOPLEFT", 0, -88); panel:SetSize(514, 350)
    local function Field(key, label, y, low, high, percent)
        local caption = Text(panel, 13, palette.text)
        caption:SetPoint("TOPLEFT", 0, -y); caption:SetText(label)
        local valueText = Text(panel, 13, palette.accent)
        valueText:SetPoint("TOPRIGHT", -10, -y)
        local slider = CreateFrame("Slider", nil, panel)
        self.chatFields[key] = { slider = slider, value = valueText, percent = percent }
        slider:SetPoint("TOPLEFT", 0, -y - 31); slider:SetSize(504, 20)
        slider:SetOrientation("HORIZONTAL"); slider:SetMinMaxValues(low, high)
        slider:SetValueStep(1); slider:SetObeyStepOnDrag(true)
        slider:EnableMouse(true); slider:EnableMouseWheel(true)
        slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
        local thumb = slider:GetThumbTexture()
        if thumb then thumb:SetSize(10, 16); thumb:SetColorTexture(unpack(palette.accent)) end
        local track = slider:CreateTexture(nil, "BACKGROUND")
        track:SetPoint("LEFT", 5, 0); track:SetPoint("RIGHT", -5, 0)
        track:SetHeight(3); track:SetColorTexture(0.17, 0.25, 0.29)
        local help = Text(panel, 10, palette.muted)
        help:SetPoint("TOPLEFT", 0, -y - 62)
        help:SetText(percent and "0% is transparent; 100% is opaque." or "Message and typing text, saved for all characters.")
        slider:SetScript("OnValueChanged", function(_, value)
            if self.chatSyncing or not Suite.IsReadable(value) or type(value) ~= "number"
                or value ~= value or math.abs(value) == math.huge then return end
            value = math.max(low, math.min(high, math.floor(value + 0.5)))
            Suite.Chat:SetOption(key, percent and value / 100 or value)
            valueText:SetText(tostring(value) .. (percent and "%" or ""))
        end)
        slider:SetScript("OnMouseWheel", function(_, direction)
            if not Suite.IsReadable(direction) or type(direction) ~= "number" or direction ~= direction
                or math.abs(direction) == math.huge then return end
            local size, opacity = Suite.Chat:Options()
            slider:SetValue(math.max(low, math.min(high, (percent and opacity * 100 or size) + direction)))
        end)
    end
    Field("chatFontSize", "Default text size", 0, 10, 24, false)
    Field("chatOpacity", "Background opacity", 112, 0, 100, true)
    local apply = CreateFrame("Button", nil, panel, "BackdropTemplate")
    self.chatApply = apply
    apply:SetPoint("TOPLEFT", 0, -235); apply:SetSize(504, 34); Fill(apply, palette.row)
    apply.label = Text(apply, 12, palette.accent); apply.label:SetPoint("CENTER")
    apply:SetScript("OnClick", function()
        Suite.Set("chatStyle", not Suite.Chat:Enabled()); self:RefreshChat()
    end)
    self.chatStatus = Text(panel, 11, palette.muted)
    self.chatStatus:SetPoint("TOPLEFT", 0, -283); self.chatStatus:SetWidth(504); self.chatStatus:SetWordWrap(true)
end
function GUI:RefreshChat()
    if not self.chatPanel then return end
    local size, opacity = Suite.Chat:Options()
    self.chatSyncing = true
    self.chatFields.chatFontSize.slider:SetValue(size)
    self.chatFields.chatFontSize.value:SetText(tostring(size))
    self.chatFields.chatOpacity.slider:SetValue(math.floor(opacity * 100 + 0.5))
    self.chatFields.chatOpacity.value:SetText(tostring(math.floor(opacity * 100 + 0.5)) .. "%")
    self.chatSyncing = false
    local enabled = Suite.Chat:Enabled()
    self.chatApply.label:SetText(enabled and "Restore Blizzard chat" or "Use Suite chat")
    self.chatStatus:SetText(enabled and "Active for this account, including new characters. Blizzard's scroll-to-current button stays available."
        or "Choose your defaults, then use Suite chat. Restoring Blizzard chat keeps these account defaults saved.")
end
function GUI:GetSection(index)
    self.sections = self.sections or {}
    if not self.sections[index] then
        local header = CreateFrame("Button", nil, self.content, "BackdropTemplate")
        header:SetSize(CONTENT_WIDTH, 22)
        header:RegisterForClicks("LeftButtonUp")
        header.label = Text(header, 11, palette.accent)
        header.label:SetPoint("LEFT", 22, 0); header.label:SetWidth(CONTENT_WIDTH - 28)
        header.indicator = Text(header, 13, palette.accent)
        header.indicator:SetPoint("LEFT", 4, 0); header.indicator:SetWidth(12)
        header.indicator:SetJustifyH("CENTER")
        Fill(header, palette.background)
        header:SetScript("OnEnter", function() Fill(header, palette.row) end)
        header:SetScript("OnLeave", function() Fill(header, palette.background) end)
        header:SetScript("OnClick", function()
            if self.page ~= header.page then return end
            self:SetSectionCollapsed(header.page, header.firstRow, not self:IsSectionCollapsed(header.page, header.firstRow))
            self:Select(header.page)
        end)
        self.sections[index] = header
    end
    self.sections[index]:ClearAllPoints()
    return self.sections[index]
end

function GUI:IsSectionCollapsed(page, firstRow)
    return firstRow ~= nil and self.collapsedSections ~= nil and self.collapsedSections[page] ~= nil
        and self.collapsedSections[page][firstRow] == true or false
end

function GUI:SetSectionCollapsed(page, firstRow, collapsed)
    if not firstRow then return end
    -- Presentation memory belongs to this login session, independently of feature preferences.
    self.collapsedSections = self.collapsedSections or {}
    self.collapsedSections[page] = self.collapsedSections[page] or {}
    self.collapsedSections[page][firstRow] = collapsed or nil
end

local function ScrollNumber(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and math.abs(value) < 1000000
end

local function ScrollCursor(bar)
    local _, y = GetCursorPosition()
    local scale = bar:GetEffectiveScale()
    if ScrollNumber(y) and ScrollNumber(scale) and scale > 0 then return y / scale end
end

function GUI:StopScrollDrag(scroll)
    local bar = scroll.suiteScrollBar
    if not bar then return end
    bar.drag = nil; bar:SetScript("OnUpdate", nil); bar:UnregisterAllEvents()
    if bar.thumbFill then bar.thumbFill:SetColorTexture(0.41, 0.84, 0.75, 0.75) end
end

function GUI:StopScrollDrags()
    for _, scroll in ipairs(self.scrollWidgets or {}) do self:StopScrollDrag(scroll) end
end

function GUI:SyncScrollBar(scroll, range)
    local bar, height = scroll.suiteScrollBar, scroll:GetHeight()
    if not bar or not ScrollNumber(height) or height <= 0 then return end
    if ScrollNumber(range) and range >= 0 then scroll.suiteMaximum = range end
    local maximum = scroll.suiteMaximum or 0
    local offset = math.max(0, math.min(maximum, scroll.suiteOffset or 0))
    scroll.suiteOffset = offset
    if InCombatLockdown() then
        self:StopScrollDrag(scroll)
        Suite.pending[scroll.suiteLayoutKey] = function() self:SyncScrollBar(scroll) end
        return
    end
    Suite.pending[scroll.suiteLayoutKey] = nil
    local thumbHeight = math.min(height, math.max(24, height * height / (height + maximum)))
    local travel = height - thumbHeight
    local top = maximum > 0 and travel * (offset / maximum) or 0
    if bar:GetHeight() ~= height then bar:SetHeight(height) end
    if bar.thumb:GetHeight() ~= thumbHeight then bar.thumb:SetHeight(thumbHeight) end
    if bar.thumbTop ~= top then
        bar.thumb:ClearAllPoints(); bar.thumb:SetPoint("TOP", bar, "TOP", 0, -top)
        bar.thumbTop = top
    end
    bar.travel = travel
    bar:SetShown(maximum > 0)
end

function GUI:CreateSuiteScrollFrame(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    self.scrollWidgets = self.scrollWidgets or {}
    self.scrollWidgets[#self.scrollWidgets + 1] = scroll
    scroll.suiteLayoutKey = "suiteScrollLayout:" .. #self.scrollWidgets
    scroll.suiteOffset, scroll.suiteMaximum = 0, 0
    local bar = CreateFrame("Frame", nil, scroll)
    scroll.suiteScrollBar = bar
    bar:EnableMouse(true)
    bar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 6, 0); bar:SetSize(14, 100)
    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetWidth(4); track:SetPoint("TOP", 0, 0); track:SetPoint("BOTTOM", 0, 0)
    track:SetColorTexture(0.12, 0.19, 0.21, 1)
    local thumb = CreateFrame("Button", nil, bar)
    bar.thumb = thumb
    thumb:SetSize(14, 24)
    local fill = thumb:CreateTexture(nil, "ARTWORK"); bar.thumbFill = fill
    fill:SetPoint("TOP", 0, 0); fill:SetPoint("BOTTOM", 0, 0); fill:SetWidth(10)
    fill:SetColorTexture(0.41, 0.84, 0.75, 0.75)
    bar:Hide()
    local function Stop() self:StopScrollDrag(scroll) end
    local function SetOffset(offset)
        if scroll == self.scrollFrame then self:ScrollTo(offset)
        else
            scroll.suiteOffset = math.max(0, math.min(scroll.suiteMaximum, offset))
            scroll:SetVerticalScroll(scroll.suiteOffset); self:SyncScrollBar(scroll)
        end
    end
    local function PaintHover() fill:SetColorTexture(0.41, 0.84, 0.75, 1) end
    local function PaintRest() if not bar.drag then fill:SetColorTexture(0.41, 0.84, 0.75, 0.75) end end
    bar:SetScript("OnEnter", PaintHover); bar:SetScript("OnLeave", PaintRest)
    thumb:SetScript("OnEnter", PaintHover); thumb:SetScript("OnLeave", PaintRest)
    thumb:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or InCombatLockdown() then return end
        local y = ScrollCursor(bar)
        if not y or not bar.travel or bar.travel <= 0 or scroll.suiteMaximum <= 0 then return end
        -- Preserve the grab point. Only the free track, excluding the thumb, maps to content travel.
        bar.drag = { y = y, offset = scroll.suiteOffset, travel = bar.travel, maximum = scroll.suiteMaximum }
        PaintHover()
        pcall(bar.RegisterEvent, bar, "GLOBAL_MOUSE_UP")
        bar:RegisterEvent("PLAYER_REGEN_DISABLED")
        bar:SetScript("OnUpdate", function()
            local drag = bar.drag
            if not drag or InCombatLockdown() or not scroll:IsVisible() then Stop(); return end
            local cursor = ScrollCursor(bar)
            if not cursor then Stop(); return end
            SetOffset(drag.offset + (drag.y - cursor) * drag.maximum / drag.travel)
        end)
    end)
    thumb:SetScript("OnMouseUp", function(_, button) if button == "LeftButton" then Stop() end end)
    bar:SetScript("OnEvent", function(_, event, button)
        if event == "PLAYER_REGEN_DISABLED" or event == "GLOBAL_MOUSE_UP" and button == "LeftButton" then Stop() end
    end)
    bar:SetScript("OnHide", Stop); scroll:SetScript("OnHide", Stop)
    bar:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or InCombatLockdown() then return end
        Stop()
        local cursor = ScrollCursor(bar)
        local _, bottom, _, height = bar:GetRect()
        if not cursor or not ScrollNumber(bottom) or not ScrollNumber(height) then return end
        local position = bottom + height - cursor
        local top, extent = bar.thumbTop or 0, bar.thumb:GetHeight()
        if position < top then SetOffset(scroll.suiteOffset - scroll:GetHeight() * 0.9)
        elseif position > top + extent then SetOffset(scroll.suiteOffset + scroll:GetHeight() * 0.9) end
    end)
    local function Wheel(_, delta)
        if not ScrollNumber(delta) then return end
        Stop(); SetOffset(scroll.suiteOffset - delta * 40)
    end
    scroll:EnableMouseWheel(true); scroll:SetScript("OnMouseWheel", Wheel)
    bar:EnableMouseWheel(true); bar:SetScript("OnMouseWheel", Wheel)
    thumb:EnableMouseWheel(true); thumb:SetScript("OnMouseWheel", Wheel)
    scroll:SetScript("OnVerticalScroll", function(_, offset)
        if not ScrollNumber(offset) or offset < 0 then return end
        scroll.suiteOffset = offset
        if scroll == self.scrollFrame then self.scrollOffset = offset end
        self:SyncScrollBar(scroll)
    end)
    scroll:SetScript("OnScrollRangeChanged", function(_, _, range)
        if not ScrollNumber(range) or range < 0 then return end
        if range ~= scroll.suiteMaximum then Stop() end
        scroll.suiteMaximum = range
        SetOffset(math.max(0, math.min(range, scroll.suiteOffset)))
    end)
    scroll:SetScript("OnSizeChanged", function() Stop(); self:SyncScrollBar(scroll) end)
    return scroll
end


function GUI:ScrollTo(offset)
    if not Suite.IsReadable(offset) or type(offset) ~= "number" or offset ~= offset or math.abs(offset) == math.huge then return end
    local maximum = self.scrollFrame and self.scrollFrame.suiteMaximum
        or math.max(0, (self.contentHeight or 0) - (self.viewportHeight or 0))
    self.scrollOffset = math.max(0, math.min(maximum, offset))
    if self.scrollFrame and self.scrollFrame.SetVerticalScroll then
        self.scrollFrame.suiteOffset = self.scrollOffset
        self.scrollFrame:SetVerticalScroll(self.scrollOffset)
        self:SyncScrollBar(self.scrollFrame)
    end
end

function GUI:LayoutNavigation(key)
    local group = Catalog.pageGroup[key]
    self.group, self.groupLast = group.key, self.groupLast or {}
    self.groupLast[group.key] = key
    local y = 42
    for _, candidate in ipairs(Catalog.groups) do
        local tab, active = self.groupTabs[candidate.key], group == candidate
        tab:Show();tab:ClearAllPoints()
        if candidate.utility then tab:SetPoint("BOTTOMLEFT", 12, 46)
        else tab:SetPoint("TOPLEFT", 12, -y); y = y + 42 end
        Fill(tab, active and { 0.1, 0.2, 0.21 } or palette.sidebar)
        tab.indicator:SetShown(active); tab.label:SetTextColor(unpack(active and palette.accent or palette.text))
        if not candidate.utility and #candidate.pages > 1 then
            for _, leaf in ipairs(candidate.pages) do
                local child = self.tabs[leaf[1]]
                child:SetShown(active)
                if active then child:ClearAllPoints(); child:SetPoint("TOPLEFT", 28, -y); y = y + 29 end
            end
            if active then y = y + 10 end
        end
    end
    self.heading:ClearAllPoints(); self.heading:SetPoint("TOPLEFT", 0, 0)
    self.description:ClearAllPoints(); self.description:SetPoint("TOPLEFT", 0, -35)
    self.viewportHeight = BODY_HEIGHT - 78 - 50
    self.scrollFrame:ClearAllPoints(); self.scrollFrame:SetPoint("TOPLEFT", 0, -78)
    self.scrollFrame:SetSize(CONTENT_WIDTH, self.viewportHeight)
end

function GUI:LayoutPage(key)
    local panels = { buffs = Suite.BuffSettings.mode and self.buffPanel or nil, profiles = self.profilePanel, overview = self.homePanel, items = Suite.GearSettings.mode and self.gearPanel or nil, macros = self.macroPanel, meters = self.meterPanel, chat = self.chatPanel,
        actionbars = self.keybindPanel, bars = self.progressPanel, worldmap = self.mapPanel, characters = self.characterPanel, castbars = self.castbarPanel }
    local panel, bottom = panels[key], self.controlsOffset or 0
    if panel then
        local collapsed = self:IsSectionCollapsed(key, self.detailSection)
        panel:SetShown(not collapsed)
        if not collapsed then
            panel:ClearAllPoints(); panel:SetPoint("TOPLEFT", math.max(18, (CONTENT_WIDTH - panel:GetWidth()) / 2), -bottom)
            local height = panel:GetHeight()
            if Suite.IsReadable(height) and type(height) == "number" and height >= 0 and height < 10000 then bottom = bottom + height end
        end
    end
    self.contentHeight = math.max(self.viewportHeight, bottom + 36)
    self.scrollFrame.suiteMaximum = math.max(0, self.contentHeight - self.viewportHeight)
    self.content:SetHeight(self.contentHeight)
    self.scrollFrame:SetShown(key ~= "setup")
    self:SyncScrollBar(self.scrollFrame)
end

function GUI:ClearSettingHighlight()
    if self.settingHighlight then self.settingHighlight:Hide() end
end

function GUI:RevealSetting(entry)
    if not entry or not pages[entry.page] then return end
    self:SetSectionCollapsed(entry.page, Catalog:SectionFor(entry.page, entry.row), false)
    self:Select(entry.page)
    local target, offset = Catalog:Target(self, entry)
    if not target then return end
    self:ScrollTo(offset or 0)
    local serial = self.selectionSerial
    -- First construction/anchors stay outside combat; a search never focuses or invokes an action control.
    Suite.AfterCombat("settingsReveal", function()
        if self.page ~= entry.page or self.selectionSerial ~= serial or not self.frame:IsShown() then return end
        if not self.settingHighlight then
            self.settingHighlight = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
            self.settingHighlight:EnableMouse(false)
            self.settingHighlight:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
            self.settingHighlight:SetBackdropBorderColor(unpack(palette.accent))
        end
        local ring = self.settingHighlight
        ring:SetParent(target); ring:ClearAllPoints()
        ring:SetPoint("TOPLEFT", target, "TOPLEFT", -2, 2)
        ring:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 2, -2)
        ring:Show()
    end)
end

function GUI:ClearSearch()
    if self.searchBox then
        self.searchBox:SetText(""); self.searchBox:ClearFocus()
        self.searchBox.placeholder:Show()
    end
    if self.searchPopup then self.searchPopup:Hide() end
    self.searchResults, self.searchPage = nil, 1
end

function GUI:PaintSearch()
    local results, page = self.searchResults or {}, self.searchPage or 1
    local pagesCount = math.max(1, math.ceil(#results / 6))
    page = math.max(1, math.min(pagesCount, page)); self.searchPage = page
    for index, button in ipairs(self.searchRows) do
        local entry = results[(page - 1) * 6 + index]; button.entry = entry
        if entry then button.label:SetText(entry.label); button.context:SetText(entry.context) end
        button:SetShown(entry ~= nil)
    end
    self.searchEmpty:SetShown(#results == 0)
    self.searchPopup:SetHeight(26 + math.max(1, math.min(6, #results)) * 45 + 28)
    self.searchCount:SetText(#results .. (#results == 1 and " setting" or " settings"))
    self.searchPrevious:SetEnabled(page > 1); self.searchNext:SetEnabled(page < pagesCount)
    self.searchPrevious:SetShown(pagesCount > 1); self.searchNext:SetShown(pagesCount > 1)
    self.searchPageLabel:SetText(page .. "/" .. pagesCount); self.searchPageLabel:SetShown(pagesCount > 1)
    self.searchPopup:Show()
end

function GUI:UpdateSearch()
    local query = self.searchBox:GetText()
    if not Suite.IsReadable(query) or type(query) ~= "string" or query:match("^%s*$") or #query > 100 or query:find("[%c|]") then
        self.searchPopup:Hide(); self.searchResults = nil
        self.searchBox.placeholder:SetShown(Suite.IsReadable(query) and type(query) == "string" and query == "")
        return
    end
    self.searchBox.placeholder:Hide()
    self.searchResults, self.searchPage = Catalog:Search(query), 1
    self:PaintSearch()
end

function GUI:BuildSettingsSearch(header)
    local search = CreateFrame("EditBox", nil, header, "BackdropTemplate")
    self.searchBox = search
    search:SetSize(310, 32); search:SetPoint("RIGHT", self.closeButton, "LEFT", -12, 0)
    search:SetFrameLevel(header:GetFrameLevel() + 2)
    search:SetFont("Fonts\\FRIZQT__.TTF", 11, ""); search:SetTextColor(unpack(palette.text))
    search:SetAutoFocus(false); search:SetMaxLetters(100); search:SetTextInsets(11, 30, 0, 0)
    search:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    search:SetBackdropColor(unpack(palette.row)); search:SetBackdropBorderColor(0.17, 0.25, 0.29)
    search.placeholder = Text(search, 11, palette.muted)
    search.placeholder:SetPoint("LEFT", 11, 0); search.placeholder:SetText("Search settings…")
    local clear = CreateFrame("Button", nil, search)
    clear:SetSize(25, 26); clear:SetPoint("RIGHT", -2, 0)
    clear.label = Text(clear, 12, palette.muted); clear.label:SetPoint("CENTER"); clear.label:SetText("×")
    clear:SetScript("OnClick", function() self:ClearSearch() end)
    local popup = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    self.searchPopup, self.searchRows = popup, {}
    popup:SetWidth(350); popup:SetPoint("TOPRIGHT", search, "BOTTOMRIGHT", 0, -5)
    popup:SetFrameLevel(header:GetFrameLevel() + 10); popup:EnableMouse(true); popup:EnableMouseWheel(true)
    popup:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    popup:SetBackdropColor(0.035, 0.05, 0.065, 0.98); popup:SetBackdropBorderColor(0.17, 0.25, 0.29)
    self.searchCount = Text(popup, 10, palette.muted); self.searchCount:SetPoint("TOPLEFT", 12, -9)
    self.searchEmpty = Text(popup, 11, palette.muted)
    self.searchEmpty:SetPoint("TOPLEFT", 12, -34); self.searchEmpty:SetText("No matching settings. Try a shorter phrase.")
    for index = 1, 6 do
        local button = CreateFrame("Button", nil, popup, "BackdropTemplate")
        button:SetSize(334, 42); button:SetPoint("TOPLEFT", 8, -25 - (index - 1) * 45); Fill(button, palette.row)
        button.label = Text(button, 12, palette.text); button.label:SetPoint("TOPLEFT", 9, -6); button.label:SetWidth(316)
        button.context = Text(button, 10, palette.muted); button.context:SetPoint("TOPLEFT", 9, -23); button.context:SetWidth(316)
        button:SetScript("OnEnter", function() button:SetBackdropColor(0.09, 0.13, 0.145) end)
        button:SetScript("OnLeave", function() Fill(button, palette.row) end)
        button:SetScript("OnClick", function() self:RevealSetting(button.entry) end)
        self.searchRows[index] = button
    end
    local function PageButton(x, label, delta)
        local button = CreateFrame("Button", nil, popup)
        button:SetSize(30, 24); button:SetPoint("BOTTOMRIGHT", x, 2)
        local text = Text(button, 13, palette.accent); text:SetPoint("CENTER"); text:SetText(label)
        button:SetScript("OnClick", function() self.searchPage = (self.searchPage or 1) + delta; self:PaintSearch() end)
        return button
    end
    self.searchPrevious, self.searchNext = PageButton(-83, "‹", -1), PageButton(-7, "›", 1)
    self.searchPageLabel = Text(popup, 10, palette.muted); self.searchPageLabel:SetPoint("BOTTOMRIGHT", -44, 9)
    popup:SetScript("OnMouseWheel", function(_, delta)
        if Suite.IsReadable(delta) and type(delta) == "number" and (delta == 1 or delta == -1) then
            self.searchPage = (self.searchPage or 1) - delta; self:PaintSearch()
        end
    end)
    search:SetScript("OnTextChanged", function() self:UpdateSearch() end)
    search:SetScript("OnEditFocusGained", function() self:UpdateSearch() end)
    search:SetScript("OnEscapePressed", function() self:ClearSearch() end)
    search:SetScript("OnEnterPressed", function()
        local entry = self.searchResults and self.searchResults[((self.searchPage or 1) - 1) * 6 + 1]
        if entry then self:RevealSetting(entry) end
    end)
    popup:Hide()
end

function GUI:Initialize()
    if self.frame or InCombatLockdown() then return end
    local frame = CreateFrame("Frame", "WoWForeverSuitePanel", UIParent, "BackdropTemplate")
    self.frame = frame
    frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    -- Let native focus raise the complete window when any child is clicked.
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(unpack(palette.background))
    frame:SetBackdropBorderColor(0.17, 0.25, 0.29)
    frame:Hide()
    table.insert(UISpecialFrames, frame:GetName())

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(76)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() if not InCombatLockdown() then frame:StartMoving() end end)
    header:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        Suite.db.guiPosition = Suite.Windows:CapturePosition(frame) or {}
    end)
    self.branding = header:CreateTexture(nil, "ARTWORK")
    self.branding:SetSize(56, 56)
    self.branding:SetPoint("TOPLEFT", header, "TOPLEFT", 24, -10)
    self.branding:SetTexture(LOGO_TEXTURE)
    local title = Text(header, 21, palette.text)
    title:SetPoint("TOPLEFT", 94, -19)
    title:SetText("FOREVER  |cff68d5bfSUITE|r")
    local subtitle = Text(header, 10, palette.muted)
    subtitle:SetPoint("TOPLEFT", 95, -47)
    subtitle:SetText("A setup that feels like yours.")
    subtitle:SetWidth(420);subtitle:SetWordWrap(false);self.profileSubtitle=subtitle
    Suite.ProfileSettings:RefreshCaption()
    -- Keep the button above the mouse-enabled drag header so the header cannot swallow clicks.
    local close = CreateFrame("Button", nil, header, "BackdropTemplate")
    self.closeButton = close
    close:SetSize(30, 30)
    close:SetPoint("TOPRIGHT", -14, -22)
    close:SetFrameLevel(header:GetFrameLevel() + 1)
    close:EnableMouse(true)
    close:RegisterForClicks("LeftButtonUp")
    local closeText = Text(close, 16, palette.muted)
    closeText:SetPoint("CENTER")
    closeText:SetText("X")
    close:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    local function PaintClose(hovered)
        close:SetBackdropColor(unpack(hovered and { 0.09, 0.13, 0.145 } or palette.row))
        close:SetBackdropBorderColor(unpack(hovered and palette.accent or { 0.17, 0.25, 0.29 }))
        closeText:SetTextColor(unpack(hovered and palette.accent or palette.muted))
    end
    PaintClose(false)
    close:SetScript("OnEnter", function() PaintClose(true) end)
    close:SetScript("OnLeave", function() PaintClose(false) end)
    close:SetScript("OnHide", function() PaintClose(false) end)
    close:SetScript("OnClick", function() frame:Hide() end)
    self:BuildSettingsSearch(header)
    local rule = header:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetPoint("BOTTOMLEFT", 24, 0)
    rule:SetPoint("BOTTOMRIGHT", -24, 0)
    rule:SetColorTexture(0.17, 0.25, 0.29)

    local sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", 0, -77)
    sidebar:SetPoint("BOTTOMLEFT", 0, 0)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    self.sidebar = sidebar
    Fill(sidebar, palette.sidebar)
    self.groupTabs = {}
    for i, entry in ipairs(Catalog.groups) do
        local key, label = entry.key, entry.label
        local tab = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
        tab:SetSize(SIDEBAR_WIDTH - 24, 36)
        tab:SetPoint("TOPLEFT", 12, -18 - (i - 1) * 42)
        tab.label = Text(tab, 13, palette.muted)
        tab.label:SetPoint("LEFT", 15, 0)
        tab.label:SetText(label)
        tab.indicator = tab:CreateTexture(nil, "ARTWORK")
        tab.indicator:SetWidth(2)
        tab.indicator:SetPoint("TOPLEFT", 0, -8)
        tab.indicator:SetPoint("BOTTOMLEFT", 0, 8)
        tab.indicator:SetColorTexture(unpack(palette.accent))
        tab:SetScript("OnClick", function() self:Select(self.groupLast and self.groupLast[key] or entry.pages[1][1]) end)
        self.groupTabs[key] = tab
        if #entry.pages == 1 then self.tabs[entry.pages[1][1]] = tab end
    end
    local stamp = Text(sidebar, 10, palette.gold)
    stamp:SetPoint("BOTTOMLEFT", 24, 22)
    stamp:SetText("PERSONAL EDITION  ·  " .. Suite.version)

    local navHelp = Text(sidebar, 10, palette.muted)
    navHelp:SetPoint("BOTTOMLEFT", 24, 94); navHelp:SetWidth(160)
    navHelp:SetText("Choose a workspace.\nSearch finds any setting.")
    self.body = CreateFrame("Frame", nil, frame)
    self.body:SetPoint("TOPLEFT", 240, -102); self.body:SetSize(CONTENT_WIDTH + 32, BODY_HEIGHT)
    self.scrollFrame = self:CreateSuiteScrollFrame(self.body)
    self.content = CreateFrame("Frame", nil, self.scrollFrame)
    self.content:SetSize(CONTENT_WIDTH, BODY_HEIGHT); self.scrollFrame:SetScrollChild(self.content)
    for _, group in ipairs(Catalog.groups) do
        if not group.utility and #group.pages > 1 then
            for _, entry in ipairs(group.pages) do
                local key = entry[1]
                local tab = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
                tab:SetSize(SIDEBAR_WIDTH - 40, 27)
                tab.label = Text(tab, 12, palette.muted); tab.label:SetPoint("LEFT", 14, 0)
                tab.label:SetWidth(SIDEBAR_WIDTH - 62); tab.label:SetWordWrap(false); tab.label:SetText(entry[2])
                tab.indicator = tab:CreateTexture(nil, "ARTWORK"); tab.indicator:SetWidth(2)
                tab.indicator:SetPoint("TOPLEFT", 0, -5); tab.indicator:SetPoint("BOTTOMLEFT", 0, 5)
                tab.indicator:SetColorTexture(unpack(palette.accent))
                tab:SetScript("OnClick", function() self:Select(key) end)
                self.tabs[key] = tab
            end
        end
    end
    local navTitle = Text(sidebar, 10, palette.muted)
    navTitle:SetPoint("TOPLEFT", 24, -20); navTitle:SetText("WORKSPACES")
    self.heading = Text(self.body, 24, palette.text)
    self.heading:SetPoint("TOPLEFT", 0, 0)
    self.heading:SetWidth(CONTENT_WIDTH)
    self.description = Text(self.body, 11, palette.muted)
    self.description:SetPoint("TOPLEFT", 0, -31)
    self.description:SetWidth(CONTENT_WIDTH)
    self.description:SetHeight(34)
    self.description:SetJustifyV("TOP")
    self.note = Text(self.body, 10, palette.muted)
    self.note:SetPoint("BOTTOMLEFT", 0, -2)
    self.note:SetWidth(CONTENT_WIDTH)
    self.note:SetHeight(28)
    self.note:SetWordWrap(true)
    self.note:SetJustifyV("BOTTOM")
    frame:SetScript("OnShow", function()
        self:FitToScreen()
        Suite.CharacterDashboard:RefreshView()
        Suite.Macros:SetVisible(self.page == "macros")
        Suite.Camping:SetSettingsVisible(self.page == "camping")
        Suite.MissingBuffs:SetSettingsVisible(self.page == "buffs")
    end)
    frame:SetScript("OnHide", function()
        self:StopScrollDrags()
        Suite.pending.dashboardBuild, Suite.pending.dashboardView = nil, nil
        self:ClearSearch(); self:ClearSettingHighlight(); Suite.pending.settingsReveal = nil
        Suite.GearSettings:Dismiss()
        Suite.CharacterBrowser:SetVisible(false)
        Suite.pending.setupOpen = nil
        if self.page == "setup" then Suite.Setup:Dismiss() end
        Suite.ProfileSettings:Dismiss()
        Suite.BuffSettings:Dismiss()
        Suite.Macros:SetVisible(false)
        Suite.Camping:SetSettingsVisible(false)
        Suite.MissingBuffs:SetSettingsVisible(false)
        if self.macroPreview then self.macroPreview:ClearFocus() end
    end)
    frame:SetScript("OnEvent", function(_, event)
        if event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" then self:FitToScreen(); return end
        if event ~= "GLOBAL_MOUSE_DOWN" or not self.searchPopup:IsShown() then return end
        local function Over(widget)
            if not widget.IsMouseOver then return false end
            local ok, value = pcall(widget.IsMouseOver, widget)
            return ok and Suite.IsReadable(value) and value == true
        end
        if not Over(self.searchBox) and not Over(self.searchPopup) then self.searchPopup:Hide() end
    end)
    local valid = not C_EventUtils or not C_EventUtils.IsEventValid
    if not valid then
        local ok, value = pcall(C_EventUtils.IsEventValid, "GLOBAL_MOUSE_DOWN")
        valid = ok and Suite.IsReadable(value) and value == true
    end
    if valid then pcall(frame.RegisterEvent, frame, "GLOBAL_MOUSE_DOWN") end
    pcall(frame.RegisterEvent, frame, "DISPLAY_SIZE_CHANGED")
    pcall(frame.RegisterEvent, frame, "UI_SCALE_CHANGED")
    self:FitToScreen()
    local saved = Suite.db.guiPosition
    if type(saved.x) == "number" and type(saved.y) == "number" then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", saved.x * UIParent:GetWidth(), saved.y * UIParent:GetHeight())
    end
    self:Select("overview")
end

function GUI:RegisterSettings()
    if self.settingsCategory or not Suite.db then return end
    Suite.AfterCombat("settingsCategory", function()
        if self.settingsCategory or not Settings
            or type(Settings.RegisterCanvasLayoutCategory) ~= "function"
            or type(Settings.RegisterAddOnCategory) ~= "function" then return end

        local panel = CreateFrame("Frame", nil, UIParent)
        panel:Hide()
        local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText("Forever Suite")
        local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        description:SetPoint("TOPLEFT", 16, -56)
        description:SetPoint("TOPRIGHT", -16, -56)
        description:SetJustifyH("LEFT")
        description:SetText("Open the Suite panel to choose features and customize your setup.\nType /wfs setup for the five-step guide, or /wfs for settings.")
        local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        button:SetSize(220, 28)
        button:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -20)
        button:SetText("Open Forever Suite")
        button:SetScript("OnClick", function() self:OpenFromSettings() end)
        panel.openButton = button
        self.settingsPanel = panel
        self.settingsCategory = Settings.RegisterCanvasLayoutCategory(panel, "Forever Suite")
        Settings.RegisterAddOnCategory(self.settingsCategory)
    end)
end

function GUI:OpenFromSettings()
    if self.settingsOpenTimer then self.settingsOpenTimer:Cancel(); self.settingsOpenTimer = nil end
    Suite.AfterCombat("settingsOpen", function()
        local panel = SettingsPanel
        if panel and panel:IsShown() and type(panel.Close) == "function" then
            if type(panel.HasUnappliedSettings) == "function" and type(StaticPopup_Show) == "function" then
                local unapplied = panel:HasUnappliedSettings()
                if not Suite.IsReadable(unapplied) then return end
                if unapplied then
                    -- Keep Blizzard's choices; wait until its close/menu cleanup has finished.
                    StaticPopup_Show("GAME_SETTINGS_CONFIRM_DISCARD", nil, nil, nil, nil, function()
                        if self.settingsOpenTimer then self.settingsOpenTimer:Cancel() end
                        self.settingsOpenTimer = C_Timer.NewTimer(0, function()
                            self.settingsOpenTimer = nil
                            if not panel:IsShown() then self:OpenFromSettings() end
                        end)
                    end)
                    return
                end
            end
            panel:Close(true)
            if panel:IsShown() then return end
        end
        self:OpenPage(self.page or "overview")
    end)
end

function GUI:Toggle()
    if not Suite.db then return end
    if InCombatLockdown() then
        if self.frame and self.frame:IsShown() then
            Suite.pending.guiOpen = nil
            self.frame:Hide()
        else Suite.AfterCombat("guiOpen", function() self:Toggle() end) end
        return
    end
    Suite.pending.guiOpen = nil
    self:Initialize()
    if not self.frame:IsShown() then self:Select(self.page or "overview") end
    self.frame:SetShown(not self.frame:IsShown())
    if self.frame:IsShown() then self.frame:Raise() end
end

function GUI:OpenPage(key)
    if not Suite.db then return end
    if not pages[key] then return end
    if key == "setup" and not self.setupPanel and InCombatLockdown() then Suite.Setup:Open(); return end
    if InCombatLockdown() then Suite.AfterCombat("guiOpen", function() self:OpenPage(key) end); return end
    Suite.pending.guiOpen = nil
    self:Initialize()
    self:Select(key)
    self.frame:Show()
    self.frame:Raise()
end

function GUI:OpenMeters(index)
    if not Suite.db then return end
    if InCombatLockdown() then Suite.AfterCombat("guiOpen", function() self:OpenMeters(index) end); return end
    Suite.pending.guiOpen = nil
    self:Initialize()
    if index and index ~= self.meterIndex then self:FinishMeterInputs() end
    if index == 1 or index == 2 or index == 3 then self.meterIndex = index end
    self:Select("meters")
    self.frame:Show()
    self.frame:Raise()
end

local function MeterNumber(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function MeterValueText(value)
    return string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", "")
end

function GUI:CommitMeterValues()
    if self.meterTimer then self.meterTimer:Cancel(); self.meterTimer = nil end
    local pending = self.meterPending or {}
    self.meterPending = {}
    for _, edit in pairs(pending) do
        if edit.key == "gap" then Suite.db.meterGap = edit.value; Suite.DamageMeters:Apply()
        else Suite.DamageMeters:SetOption(edit.index, edit.key, edit.value) end
    end
    self:RefreshMeters()
end

function GUI:QueueMeterValue(index, key, value)
    if not MeterNumber(value) then return end
    self.meterPending = self.meterPending or {}
    local id = key == "gap" and "gap" or index .. ":" .. key
    self.meterPending[id] = { index = index, key = key, value = value }
    if not self.meterTimer and C_Timer and C_Timer.NewTimer then
        self.meterTimer = C_Timer.NewTimer(0.05, function() self.meterTimer = nil; self:CommitMeterValues() end)
    elseif not C_Timer or not C_Timer.NewTimer then self:CommitMeterValues() end
end

function GUI:FinishMeterInputs()
    for _, field in pairs(self.meterFields or {}) do
        if field.HasFocus and field:HasFocus() then field:ClearFocus() end
    end
    self:CommitMeterValues()
end

function GUI:BuildMeters()
    if self.meterPanel then self.meterPanel:Show(); return end
    local panel = CreateFrame("Frame", nil, self.content)
    self.meterPanel, self.meterFields, self.meterButtons, self.meterIndex = panel, {}, {}, self.meterIndex or 1
    panel:SetPoint("TOPLEFT", 0, -154); panel:SetSize(514, 504)
    local function Button(name, x, y, width, callback)
        local button = CreateFrame("Button", nil, panel, "BackdropTemplate")
        button:SetSize(width, 30); button:SetPoint("TOPLEFT", x, -y); Fill(button, palette.row)
        button.label = Text(button, 11, palette.text); button.label:SetPoint("LEFT", 10, 0); button.label:SetWidth(width - 20)
        button:SetScript("OnClick", function() self:FinishMeterInputs(); callback() end); self.meterButtons[name] = button
        return button
    end
    for index = 1, 3 do
        local index = index
        local tab = Button("window" .. index, (index - 1) * 86, 0, 78, function()
            self.meterIndex = index; self:RefreshMeters()
        end)
        tab.label:SetText("Window " .. index)
    end
    Button("test", 264, 0, 248, function() Suite.DamageMeters:SetPreview(not Suite.DamageMeters.preview) end)
    Button("shown", 0, 38, 248, function()
        local settings = Suite.db.meterWindows[self.meterIndex]
        Suite.DamageMeters:SetOption(self.meterIndex, "shown", not settings.shown)
    end)
    Button("classColors", 264, 38, 248, function()
        local settings = Suite.db.meterWindows[self.meterIndex]
        Suite.DamageMeters:SetOption(self.meterIndex, "classColors", not settings.classColors)
    end)
    local function Field(key, label, x, y, low, high, percent)
        local caption = Text(panel, 11, palette.muted)
        caption:SetPoint("TOPLEFT", x, -y - 6); caption:SetWidth(176); caption:SetWordWrap(false); caption:SetText(label)
        local input = CreateFrame("EditBox", nil, panel, "BackdropTemplate")
        input:SetSize(64, 24); input:SetPoint("TOPLEFT", x + 184, -y)
        input:SetFont("Fonts\\FRIZQT__.TTF", 11, ""); input:SetTextColor(unpack(palette.text))
        input:SetJustifyH("RIGHT"); input:SetAutoFocus(false); input:SetMaxLetters(8); input:SetTextInsets(6, 6, 0, 0)
        input:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        input:SetBackdropColor(unpack(palette.background)); input:SetBackdropBorderColor(0.17, 0.25, 0.29)
        local slider = CreateFrame("Slider", nil, panel)
        input.slider, input.caption = slider, caption
        slider:SetSize(248, 18); slider:SetPoint("TOPLEFT", x, -y - 32)
        slider:SetOrientation("HORIZONTAL"); slider:SetMinMaxValues(low, high); slider:SetValueStep(1); slider:SetObeyStepOnDrag(true)
        slider:EnableMouse(true); slider:EnableMouseWheel(true)
        slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
        local thumb = slider:GetThumbTexture()
        if thumb then thumb:SetSize(12, 16); thumb:SetColorTexture(unpack(palette.accent)) end
        local track = slider:CreateTexture(nil, "BACKGROUND")
        track:SetPoint("LEFT", 6, 0); track:SetPoint("RIGHT", -6, 0); track:SetHeight(3); track:SetColorTexture(0.17, 0.25, 0.29)
        slider.fill = slider:CreateTexture(nil, "ARTWORK")
        slider.fill:SetPoint("LEFT", 6, 0); slider.fill:SetHeight(3); slider.fill:SetColorTexture(0.20, 0.54, 0.49)
        function slider:PaintValue(value)
            self.fill:SetWidth(math.max(1, 236 * (value - low) / (high - low)))
            self.fill:SetShown(value > low)
        end
        slider:SetScript("OnValueChanged", function(_, value)
            if self.meterSyncing or not MeterNumber(value) then return end
            value = math.max(low, math.min(high, value))
            slider:PaintValue(value); input:SetText(MeterValueText(value))
            self:QueueMeterValue(self.meterIndex, key, percent and value / 100 or value)
        end)
        slider:SetScript("OnMouseDown", function() self:FinishMeterInputs() end)
        slider:SetScript("OnMouseUp", function() self:CommitMeterValues() end)
        slider:SetScript("OnMouseWheel", function(_, direction)
            local value = slider:GetValue()
            if MeterNumber(value) and MeterNumber(direction) then slider:SetValue(math.max(low, math.min(high, value + direction))) end
        end)
        slider:SetScript("OnEnter", function() if thumb then thumb:SetColorTexture(0.65, 0.95, 0.87) end end)
        slider:SetScript("OnLeave", function() if thumb then thumb:SetColorTexture(unpack(palette.accent)) end end)
        input:SetScript("OnEditFocusGained", function() input.editIndex = self.meterIndex end)
        input:SetScript("OnEnterPressed", function() input:ClearFocus() end)
        input:SetScript("OnEscapePressed", function() input.cancelEdit = true; input:ClearFocus(); self:RefreshMeters() end)
        input:SetScript("OnEditFocusLost", function()
            local index = input.editIndex or self.meterIndex
            input.editIndex = nil
            if input.cancelEdit then input.cancelEdit = nil; return end
            local text = input:GetText()
            local value = Suite.IsReadable(text) and tonumber(text)
            if MeterNumber(value) then
                value = math.max(low, math.min(high, value))
                self:QueueMeterValue(index, key, percent and value / 100 or value)
                self:CommitMeterValues()
            end
            self:RefreshMeters()
        end)
        self.meterFields[key] = input
    end
    Field("width", "Width", 0, 82, 240, 1600); Field("height", "Height", 264, 82, 120, 1000)
    Field("rowHeight", "Bar height", 0, 144, 18, 32); Field("fontSize", "Text size", 264, 144, 9, 16)
    Field("opacity", "Background opacity (%)", 0, 206, 20, 100, true); Field("gap", "Gap between snapped windows", 264, 206, 0, 16)
    Button("numbers", 0, 270, 248, function()
        local settings = Suite.db.meterWindows[self.meterIndex]
        Suite.DamageMeters:SetOption(self.meterIndex, "numbers", settings.numbers == "compact" and "full" or "compact")
    end)
    Button("snap", 264, 270, 248, function()
        Suite.db.meterSnap = not Suite.db.meterSnap; self:RefreshMeters()
    end)
    Button("lock", 0, 318, 160, function() Suite.DamageMeters:SetLocked(not Suite.db.meterLocked) end)
    Button("reset", 172, 318, 168, function() Suite.DamageMeters:Reset(self.meterIndex) end).label:SetText("Reset window layout")
    Button("detach", 352, 318, 160, function() Suite.DamageMeters:Detach() end).label:SetText("Detach windows")
    Button("content", 0, 356, 248, function()
        local settings = Suite.db.meterWindows[self.meterIndex]
        local nextMode = { standard = "paired", paired = "complete", complete = "minimal", minimal = "standard" }
        Suite.DamageMeters:SetOption(self.meterIndex, "content", nextMode[settings.content])
    end)
    Button("icons", 264, 356, 248, function()
        local settings = Suite.db.meterWindows[self.meterIndex]
        Suite.DamageMeters:SetOption(self.meterIndex, "icons", not settings.icons)
    end)
    Button("pinSelf", 0, 394, 248, function()
        local settings = Suite.db.meterWindows[self.meterIndex]
        Suite.DamageMeters:SetOption(self.meterIndex, "pinSelf", not settings.pinSelf)
    end)
    Button("minimized", 264, 394, 248, function()
        local settings = Suite.db.meterWindows[self.meterIndex]
        Suite.DamageMeters:SetOption(self.meterIndex, "minimized", not settings.minimized)
    end)
    Button("visibility", 0, 432, 248, function()
        local settings = Suite.db.meterWindows[self.meterIndex]
        local nextMode = { always = "combat", combat = "group", group = "always" }
        Suite.DamageMeters:SetOption(self.meterIndex, "visibility", nextMode[settings.visibility])
    end)
    Button("clickThrough", 264, 432, 248, function()
        local settings = Suite.db.meterWindows[self.meterIndex]
        Suite.DamageMeters:SetOption(self.meterIndex, "clickThrough", not settings.clickThrough)
    end)
    local inputHint = Text(panel, 11, palette.muted)
    inputHint:SetPoint("TOPLEFT", 0, -476); inputHint:SetWidth(512)
    inputHint:SetText("Shift-click a bar to keep details open. Use /wfs to restore mouse input.")
    panel:SetScript("OnHide", function()
        for _, field in pairs(self.meterFields) do field.cancelEdit = true; field:ClearFocus(); field.cancelEdit = nil; field.editIndex = nil end
        self:CommitMeterValues()
    end)
end

function GUI:RefreshMeters()
    if not self.meterPanel or self.page ~= "meters" then return end
    Suite.DamageMeters:Normalize()
    local index = self.meterIndex or 1
    local settings, buttons = Suite.db.meterWindows[index], self.meterButtons
    for i = 1, 3 do Fill(buttons["window" .. i], i == index and { 0.1, 0.2, 0.21 } or palette.row) end
    buttons.test.label:SetText(Suite.DamageMeters.preview and "Stop test"
        or #Suite.DamageMeters.windows == 3 and "Test windows" or "Test both windows")
    buttons.shown.label:SetText((Suite.DamageMeters.preview and "After test, Window " or "Show Window ") .. index .. ": " .. (settings.shown and "On" or "Off"))
    buttons.classColors.label:SetText(settings.classColors and "Bars: class colors" or "Bars: Suite teal")
    buttons.numbers.label:SetText(settings.numbers == "compact" and "Numbers: compact" or "Numbers: full")
    buttons.content.label:SetText("Values: " .. ({ minimal = "Primary", standard = "Standard", paired = "Total + rate", complete = "Total, rate, share" })[settings.content])
    buttons.icons.label:SetText("Class / spec icons: " .. (settings.icons and "On" or "Off"))
    buttons.pinSelf.label:SetText("Keep my row visible: " .. (settings.pinSelf and "On" or "Off"))
    buttons.minimized.label:SetText(settings.minimized and "Window: Minimized" or "Window: Expanded")
    buttons.visibility.label:SetText("Visible: " .. ({ always = "Always", combat = "In combat", group = "In a group" })[settings.visibility])
    buttons.clickThrough.label:SetText("Mouse input: " .. (settings.clickThrough and "Off" or "On"))
    buttons.snap.label:SetText("Snap windows: " .. (Suite.db.meterSnap and "On" or "Off"))
    buttons.lock.label:SetText(Suite.db.meterLocked and "Windows: Locked" or "Windows: Unlocked")
    buttons.detach:SetEnabled(Suite.db.meterDock.anchor ~= nil)
    self.meterSyncing = true
    for key, field in pairs(self.meterFields) do
        local value = key == "gap" and Suite.db.meterGap or settings[key]
        local id = key == "gap" and "gap" or index .. ":" .. key
        local pending = self.meterPending and self.meterPending[id]
        if pending then value = pending.value end
        if key == "opacity" then value = value * 100 end
        if not field.HasFocus or not field:HasFocus() then
            field:SetText(MeterValueText(value))
        end
        field.slider:SetValue(value); field.slider:PaintValue(value)
    end
    self.meterSyncing = nil
end

function GUI:RefreshCamping()
    if self.page == "camping" and self.rows[2] then self.rows[2].value:SetText(Suite.Camping:GetPose().label) end
end

local function MacroButton(parent, x, y, width, label, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetPoint("TOPLEFT", x, y)
    button:SetSize(width, 28)
    Fill(button, palette.row)
    button.label = Text(button, 11, palette.accent)
    button.label:SetPoint("LEFT", 10, 0)
    button.label:SetWidth(width - 20)
    button.label:SetWordWrap(false)
    button.label:SetText(label)
    button:SetScript("OnClick", callback)
    button:SetScript("OnEnter", function() button:SetBackdropColor(0.09, 0.13, 0.145) end)
    button:SetScript("OnLeave", function() Fill(button, palette.row) end)
    return button
end

function GUI:ChooseMacroItem()
    if InCombatLockdown() then return end
    local macros, entry = Suite.Macros, self.macroSelected
    if not entry or not macros:Applicable(entry) then return end
    local recipe = macros.byRecipe[entry.recipe]
    if recipe.spell then return end
    macros.snapshot = Suite.MacroItems:Scan()
    local choices, choiceNote = Suite.MacroItems:Choices(macros.snapshot, entry.recipe)
    local function Choose(id)
        if InCombatLockdown() then return end
        if recipe.foodChoice then
            local accepted, problem = Suite.MacroItems:PetCanEat(id)
            if accepted ~= true then
                macros.statuses[entry] = problem or "Your active pet cannot eat this item. Choose another food."
                self:RefreshMacros(); return
            end
        end
        entry.item = id
        macros.statuses[entry] = nil
        macros:Queue()
        self:RefreshMacros()
    end
    if MenuUtil and type(MenuUtil.CreateContextMenu) == "function" then
        MenuUtil.CreateContextMenu(self.macroChoose, function(_, root)
            if choiceNote then root:CreateTitle(choiceNote) end
            if entry.recipe ~= "item" and not recipe.foodChoice then root:CreateButton("Select automatically", function() Choose(nil) end) end
            for _, item in ipairs(choices) do
                local id = item.id
                root:CreateButton(item.name .. " (" .. item.count .. " carried)", function() Choose(id) end)
            end
            if #choices == 0 and not choiceNote then root:CreateTitle("No suitable carried items. Check your bags.") end
        end)
    else
        -- A small capability fallback for clients without native context menus.
        local nextIndex = 1
        for i, item in ipairs(choices) do if item.id == entry.item then nextIndex = i + 1; break end end
        if choices[nextIndex] then Choose(choices[nextIndex].id)
        elseif entry.recipe ~= "item" and not recipe.foodChoice then Choose(nil)
        elseif choices[1] then Choose(choices[1].id) end
        macros.statuses[entry] = choiceNote or (#choices > 0 and "Click Choose / change item again to cycle carried items." or "No suitable carried items.")
        self:RefreshMacros()
    end
end

local function MacroGroup(entry)
    local recipe = Suite.Macros.byRecipe[entry.recipe]
    return recipe.class and recipe.class:sub(1, 1) .. recipe.class:sub(2):lower() .. " Macros"
        or entry.recipe == "item" and "Item Macros" or "General"
end

function GUI:BuildMacros()
    if self.macroPanel then self:RefreshMacros(); return end
    local panel = CreateFrame("Frame", nil, self.content)
    self.macroPanel = panel
    panel:SetPoint("TOPLEFT", 0, -88)
    panel:SetSize(780, 425)
    panel:Show()
    self.macroSelected = Suite.Macros:Entries()[1]
    local list = self:CreateSuiteScrollFrame(panel)
    self.macroListScroll = list
    list:SetPoint("TOPLEFT", 0, 0); list:SetSize(248, 346)
    local listContent = CreateFrame("Frame", nil, list)
    self.macroListContent = listContent
    listContent:SetSize(248, 1); list:SetScrollChild(listContent)
    self.macroCollapsed = self.macroCollapsed or {}
    self.macroListHeadings = {}
    for i = 1, 3 do
        local heading = MacroButton(listContent, 0, 0, 248, "", function()
            local button = self.macroListHeadings[i]
            if not button.group then return end
            self.macroCollapsed[button.group] = not self.macroCollapsed[button.group] or nil
            button.label:SetText((self.macroCollapsed[button.group] and "+ " or "− ") .. button.group)
            self:RefreshMacros()
        end)
        heading:SetHeight(22); heading:Hide()
        heading:EnableMouseWheel(true)
        heading:SetScript("OnMouseWheel", function(_, delta) list:GetScript("OnMouseWheel")(list, delta) end)
        self.macroListHeadings[i] = heading
    end
    self.macroRows = {}
    -- Prepare the bounded recipe/item capacity outside combat. Refresh only
    -- changes entries; the native scroll child clips rows to this viewport.
    for i = 1, Suite.Macros:VisibleCapacity() do
        local row = MacroButton(listContent, 0, -(i - 1) * 52, 248, "", function()
            local selected = self.macroRows[i].entry
            if selected then self.macroSelected = selected; self:RefreshMacros() end
        end)
        row:SetHeight(46)
        row.label:ClearAllPoints()
        row.label:SetPoint("TOPLEFT", 10, -7)
        row.subtitle = Text(row, 10, palette.muted)
        row.subtitle:SetPoint("TOPLEFT", 10, -26)
        row.subtitle:SetWidth(228)
        row.subtitle:SetWordWrap(false)
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function(_, delta) list:GetScript("OnMouseWheel")(list, delta) end)
        self.macroRows[i] = row
    end
    self.macroAdd = MacroButton(panel, 0, -357, 248, "+ Add item macro", function()
        local entry, message = Suite.Macros:AddItem()
        if entry then
            self.macroSelected = entry
            self.macroCollapsed[MacroGroup(entry)] = nil
            self.macroReveal = entry
        else Suite.Macros.statuses[self.macroSelected] = message end
        self:RefreshMacros()
        if entry then self:ChooseMacroItem() end
    end)
    self.macroTitle = Text(panel, 16, palette.text)
    self.macroTitle:SetPoint("TOPLEFT", 288, 0)
    self.macroTitle:SetWidth(492)
    self.macroName = Text(panel, 11, palette.gold)
    self.macroName:SetPoint("TOPLEFT", 288, -24)
    self.macroName:SetWidth(492)
    self.macroHelp = Text(panel, 11, palette.muted)
    self.macroHelp:SetPoint("TOPLEFT", 288, -47)
    self.macroHelp:SetSize(492, 52)
    self.macroHelp:SetJustifyV("TOP")
    self.macroChoose = MacroButton(panel, 288, -105, 492, "Choose / change item", function() self:ChooseMacroItem() end)
    self.macroCombat = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    self.macroCombat:SetPoint("TOPLEFT", 286, -146)
    self.macroCombat:SetSize(24, 24)
    self.macroCombat.label = Text(self.macroCombat, 10, palette.text)
    self.macroCombat.label:SetPoint("TOPLEFT", 29, -3)
    self.macroCombat.label:SetSize(460, 36)
    self.macroCombat:SetScript("OnClick", function(button)
        if InCombatLockdown() then self:RefreshMacros(); return end
        self.macroSelected.combat = button:GetChecked() == true
        Suite.Macros.statuses[self.macroSelected] = nil
        Suite.Macros:Queue()
        self:RefreshMacros()
    end)
    self.macroRemove = MacroButton(panel, 288, -146, 492, "Remove choice · game macro is kept", function()
        if Suite.Macros:RemoveItem(self.macroSelected) then
            self.macroSelected = Suite.Macros:Entries()[1]
            self:RefreshMacros()
        end
    end)
    self.macroStatus = Text(panel, 10, palette.muted)
    self.macroStatus:SetPoint("TOPLEFT", 288, -191)
    self.macroStatus:SetSize(492, 36)
    self.macroStatus:SetJustifyV("TOP")
    local caption = Text(panel, 10, palette.gold)
    caption:SetPoint("TOPLEFT", 288, -229)
    caption:SetText("Preview · select and copy the generated text")
    local scroll = self:CreateSuiteScrollFrame(panel)
    scroll:SetPoint("TOPLEFT", 288, -247)
    scroll:SetSize(464, 93)
    local preview = CreateFrame("EditBox", nil, scroll)
    self.macroPreview = preview
    preview:SetSize(460, 240)
    preview:SetMultiLine(true)
    preview:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    preview:SetAutoFocus(false)
    scroll:SetScrollChild(preview)
    preview:SetScript("OnTextChanged", function(box, user)
        if user then box:SetText(self.macroPreviewBody or "") end
    end)
    preview:SetScript("OnEscapePressed", function(box) box:ClearFocus(); self.frame:Hide() end)
    self.macroSave = MacroButton(panel, 288, -357, 492, "Create macro", function() Suite.Macros:Save(self.macroSelected) end)
    self.macroUpdates = MacroButton(panel, 0, -393, 780, "", function()
        Suite.Set("macroUpdates", not Suite.db.macroUpdates)
        self:RefreshMacros()
    end)
    self:RefreshMacros()
end

function GUI:LayoutMacroList()
    if not self.macroListScroll then return end
    if InCombatLockdown() then
        Suite.pending.macroListLayout = function() self:LayoutMacroList() end
        return
    end
    Suite.pending.macroListLayout = nil
    local entries, scroll = Suite.Macros:Entries(), self.macroListScroll
    local viewport = scroll:GetHeight()
    if not ScrollNumber(viewport) or viewport <= 0 then return end
    local y, bottom, group, headingIndex = 0, 0, nil, 0
    for index, entry in ipairs(entries) do
        local nextGroup = MacroGroup(entry)
        if nextGroup ~= group then
            if group then y = y + 4 end
            headingIndex = headingIndex + 1
            local heading = self.macroListHeadings[headingIndex]
            heading:ClearAllPoints(); heading:SetPoint("TOPLEFT", 0, -y)
            heading.group = nextGroup
            heading.label:SetText((self.macroCollapsed[nextGroup] and "+ " or "− ") .. nextGroup); heading:Show()
            bottom = y + 22
            y, group = y + 24, nextGroup
        end
        local row = self.macroRows[index]
        local expanded = not self.macroCollapsed[nextGroup]
        row:SetShown(expanded)
        row.listTop = expanded and y or nil
        if expanded then
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y)
            bottom = y + 46
            y = y + 52
        end
    end
    for index = headingIndex + 1, #self.macroListHeadings do self.macroListHeadings[index]:Hide() end
    local height = math.max(1, bottom)
    scroll.suiteMaximum = math.max(0, height - viewport)
    self.macroListContent:SetHeight(height)
    local offset = math.max(0, math.min(scroll.suiteMaximum, scroll.suiteOffset or 0))
    if self.macroReveal then
        for index, entry in ipairs(entries) do
            if entry == self.macroReveal then
                local top = self.macroRows[index].listTop
                if top then
                    local bottom = top + 46
                    if top < offset then offset = top
                    elseif bottom > offset + viewport then offset = bottom - viewport end
                end
                break
            end
        end
        self.macroReveal = nil
    end
    scroll.suiteOffset = offset
    scroll:SetVerticalScroll(offset); self:SyncScrollBar(scroll)
end

function GUI:RefreshMacros()
    if not self.macroPanel then return end
    local macros = Suite.Macros
    local entries = macros:Entries()
    local entry = self.macroSelected
    local present = false
    for _, candidate in ipairs(entries) do if candidate == entry then present = true end end
    if not present then entry = entries[1]; self.macroSelected = entry end
    local recipe = macros.byRecipe[entry.recipe]
    local snapshot = macros.snapshot or { incomplete = true }
    for i, row in ipairs(self.macroRows) do
        local record = entries[i]
        row.entry = record
        row:SetShown(record ~= nil and not self.macroCollapsed[MacroGroup(record)])
        if record then
            local rowRecipe = macros.byRecipe[record.recipe]
            local title = rowRecipe.class and rowRecipe.title:gsub("^.- · ", "") or rowRecipe.title
            row.label:SetText(record.recipe == "item" and record.name or title)
            row.subtitle:SetText(record.created and (rowRecipe.class and "Created · General tab" or "General macros") or "Not created")
            Fill(row, record == entry and { 0.1, 0.2, 0.21 } or palette.row)
        end
    end
    self:LayoutMacroList()
    local paused = InCombatLockdown()
    self.macroTitle:SetText(recipe.title)
    self.macroName:SetText(entry.name .. " · General macros")
    self.macroHelp:SetText(recipe.help)
    local body, detail, pending, ready, selectedItem = macros:Generate(entry, snapshot)
    local choice = selectedItem or (entry.item and snapshot.byID and snapshot.byID[entry.item])
    self.macroChoose.label:SetText(entry.item and (choice and choice.name or "Chosen item · " .. entry.item)
        or (choice and "Auto: " .. choice.name or (recipe.foodChoice and "Choose pet food from bags"
            or entry.recipe == "item" and "Choose a carried item" or "Automatic · choose an override")))
    self.macroChoose:SetShown(not recipe.spell and not recipe.body)
    self.macroChoose:SetEnabled(not paused)
    self.macroAdd:SetEnabled(not paused)
    self.macroCombat:SetShown(entry.recipe == "food" or entry.recipe == "water")
    self.macroCombat:SetChecked(entry.combat == true)
    self.macroCombat:SetEnabled(not paused)
    self.macroRemove:SetShown(entry.recipe == "item")
    self.macroRemove:SetEnabled(not paused)
    self.macroCombat.label:SetText(entry.recipe == "food" and "Combat: Healthstone + healing potion\nBoth are attempted when pressed." or "Combat: mana potion")
    self.macroPreviewBody = body or "#showtooltip"
    self.macroPreview:SetText(self.macroPreviewBody)
    self.macroStatus:SetText(paused and "Changes are paused until combat ends." or macros.statuses[entry] or detail or "")
    self.macroSave.label:SetText(entry.created and "Update macro" or (not pending and not ready and recipe.slot and "Create placeholder" or "Create macro"))
    self.macroSave:SetEnabled(macros:CanSave(entry, body, pending, ready))
    self.macroUpdates.label:SetText("Keep created macros current: " .. (Suite.db.macroUpdates and "On" or "Off") .. " · click to change")
end
