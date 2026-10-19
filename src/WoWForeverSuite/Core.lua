local addonName, Suite = ...
Suite.name = addonName
Suite.version = "0.2.85"
Suite.modules = {}
Suite.pending = {}
Suite.defaults = {
    schema = 1,
    setupGuide = { version = 1, seen = false, completed = false },
    squareMinimap = false, minimapStats = false,
    revealWorldMap = false, mapRevealOpacity = 0.6,
    minimapButton = true, minimapButtonAngle = 225,
    minimapDrawer = false, minimapDrawerAngle = 225, minimapDrawerMoved = false,
    showFPS = true, showLatency = true, showCoordinates = true, showClock = true,
    windowTools = false, windowPositions = {}, guiPosition = {}, offlineBank = false,
    fullButtonRange = false, actionBarSkin = false, classHealthBars = false, targetThreat = false,
    statusBarSkin = false, bagBarSkin = false, microBarSkin = false, playerBuffBorders = false,
    progressBarValues = false, progressBarCustomSize = false, progressBarWidth = 600, progressBarHeight = 14, progressBarSegments = false,
    shortKeybinds = false, keybindFontStyle = false, keybindFont = "default", keybindSize = 12,
    keybindOutline = "default", keybindBold = false,
    autoRepair = false, repairSource = "personal", autoSellJunk = false, junkMode = "slow",
    autoQuestPickup = false, autoQuestTurnIn = false, autoGossip = false,
    quickLoot = false, sortBagsOnOpen = false, reverseCombinedBags = false, reverseBagSlots = false, autoOpenContainers = false, questTrackerSkin = false, questItemButton = false, questItemPosition = {},
    modifierDisenchant = false, disenchantModifier = "alt", castbars = {}, zoneReputation = false,
    bagSpaceAlert = false, bagSpaceBlacklist = {}, bagSpacePosition = {},
    mailHelper = false, mailRememberRecipient = false,
    mailContacts = { schema = 2, entries = {}, removed = {} },
    chatStyle = false, chatFontSize = 14, chatOpacity = 0.5, audioSync = false,
    itemLevels = false, itemTooltipLevels = false, characterItemLevel = false, upgradeHints = false,
    itemInventory = false, inventorySearch = false, characterDashboard = false, inventory = { schema = 1, characters = {}, accountBanks = {} },
    inventoryBrowser = { schema = 1, favorites = {} },
    scorePreset = "balanced", upgradePreference = "stats", playerItemLevel = false, classNames = false,
    macroUpdates = false, macroOwnership = {},
    campingBar = false, campingPose = "sit", campingPosition = {},
    levelingBar = false, trainingPlanner = false, trainingAuto = true, trainingLevelUp = true,
    missingBuffExpiry = false, missingBuffCombat = false, missingBuffWeapons = false, missingBuffWarning = 60, missingBuffCustom = {},
    missingBuffScale = 1, missingBuffIconSize = 34, missingBuffLocked = false, missingBuffRested = true, missingBuffSmart = true,
    missingBuffs = false, missingBuffSelf = true, missingBuffOutgoing = true, missingBuffIncoming = true, missingBuffClass = true,
    missingBuffPosition = {}, missingBuffChoices = {},
    damageMeters = false, meterSnap = true, meterGap = 4, meterLocked = false,
    meterWindows = {}, meterDock = { anchor = 1, side = "RIGHT" },
}

function Suite.IsReadable(value)
    if issecretvalue and issecretvalue(value) then return false end
    if canaccessvalue and not canaccessvalue(value) then return false end
    return true
end

function Suite.Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = Suite.Copy(child) end
    return result
end

function Suite.InitializeDB(saved)
    local db = Suite.IsReadable(saved) and type(saved) == "table" and saved or {}
    if not Suite.IsReadable(db.reverseBagSlots) or type(db.reverseBagSlots) ~= "boolean" then
        -- The user's clarified goal is slot display within each bag, rather than bag cleanup priority.
        db.reverseBagSlots = Suite.IsReadable(db.reverseBagSort) and db.reverseBagSort == true or false
    end
    db.reverseBagSort = nil
    if not Suite.IsReadable(db.minimapDrawerMoved) or type(db.minimapDrawerMoved) ~= "boolean" then
        local angle = db.minimapDrawerAngle
        -- Older releases did not distinguish their default angle from a dragged position.
        db.minimapDrawerMoved = Suite.IsReadable(angle) and type(angle) == "number"
            and angle == angle and math.abs(angle) < math.huge and angle ~= 315 or false
        if not db.minimapDrawerMoved then db.minimapDrawerAngle = 225 end
    end
    for key, value in pairs(Suite.defaults) do
        if not Suite.IsReadable(db[key]) or type(db[key]) ~= type(value) then db[key] = Suite.Copy(value) end
    end
    if not Suite.Scoring.presets[db.scorePreset] then db.scorePreset = "balanced" end
    db.upgradePreference = Suite.Scoring.Preference(db, true)
    db.inventoryBrowser = Suite.CharacterBrowser:InitializeOptions(db.inventoryBrowser)
    db.chatFontSize, db.chatOpacity = Suite.Chat:Options(db)
    db.keybindFont, db.keybindSize, db.keybindOutline, db.keybindBold = Suite.Keybinds:Options(db)
    db.progressBarWidth, db.progressBarHeight = Suite.HUDSkin:Options(db)
    -- Retain the native text preference across reloads until Always show values releases it.
    local nativeText = db.progressBarTextRestore
    if not Suite.IsReadable(nativeText) or type(nativeText) ~= "string" or (nativeText ~= "0" and nativeText ~= "1") then
        db.progressBarTextRestore = nil
    end
    local nativeSort = db.bagSortDirectionRestore
    if not Suite.IsReadable(nativeSort) or type(nativeSort) ~= "boolean" then db.bagSortDirectionRestore = nil end
    db.mapRevealOpacity = Suite.WorldMap:Opacity(db)
    db.setupGuide = Suite.Setup:InitializeState(db.setupGuide)
    db.missingBuffChoices = Suite.MissingBuffs:InitializeChoices(db.missingBuffChoices, db.missingBuffCustom)
    db.bagSpaceBlacklist = Suite.BagSpace:InitializeBlacklist(db.bagSpaceBlacklist)
    db.bagSpacePosition = Suite.BagSpace:InitializePosition(db.bagSpacePosition)
    db.questItemPosition = Suite.BagSpace:InitializePosition(db.questItemPosition)
    if db.missingBuffWarning ~= 30 and db.missingBuffWarning ~= 60 and db.missingBuffWarning ~= 120 then db.missingBuffWarning = 60 end
    db.missingBuffScale, db.missingBuffIconSize = Suite.MissingBuffs:DisplayOptions(db)
    db.missingBuffCustom = Suite.BuffReminders:Custom(db.missingBuffCustom)
    return db
end

function Suite.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff68d5bfForever Suite|r  " .. message)
end

function Suite.AfterCombat(key, callback)
    if InCombatLockdown() then
        Suite.pending[key] = callback
        return false
    end
    Suite.pending[key] = nil
    callback()
    return true
end

function Suite.Apply()
    if not Suite.db then return end
    for _, module in ipairs(Suite.modules) do module:Apply() end
end

function Suite.Set(key, value)
    Suite.db[key] = value
    Suite.Apply()
end

function Suite.Status()
    local version, build, _, interface = GetBuildInfo()
    Suite.Print("v" .. Suite.version .. " · client " .. version .. " (" .. build .. ") · interface " .. interface)
    local APIs = { "C_Item", "C_Container", "C_DamageMeter", "TooltipDataProcessor", "Settings", "issecretvalue" }
    for _, name in ipairs(APIs) do Suite.Print(name .. ": " .. (_G[name] and "available" or "missing")) end
    Suite.Print("Settings loaded from disk at startup: " .. (Suite.loadedSavedVariables and "yes" or "no / first launch"))
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event, name, second)
    if event == "ADDON_LOADED" and name == addonName then
        Suite.loadedSavedVariables = type(WoWForeverSuiteDB) == "table"
        WoWForeverSuiteDB = Suite.InitializeDB(WoWForeverSuiteDB)
        Suite.db = WoWForeverSuiteDB
        local character = Suite.IsReadable(WoWForeverSuiteCharDB) and type(WoWForeverSuiteCharDB) == "table" and WoWForeverSuiteCharDB or {}
        local scoring = Suite.Scoring:InitializeCharacter(character.scoring,
            Suite.IsReadable(WoWForeverSuiteCharDB) and type(WoWForeverSuiteCharDB) == "table" and Suite.db or nil)
        local leveling = Suite.Leveling:InitializeCharacter(character.leveling)
        local training = Suite.Training:InitializeCharacter(character.training)
        WoWForeverSuiteCharDB = Suite.Macros:Initialize(character)
        WoWForeverSuiteCharDB.leveling = leveling
        WoWForeverSuiteCharDB.training = training
        WoWForeverSuiteCharDB.scoring = scoring
        WoWForeverSuiteCharDB.suiteProfile = Suite.Profiles:Initialize(Suite.db, character.suiteProfile)
        Suite.InitializeDB(Suite.db)
    elseif event == "PLAYER_LOGIN" then
        Suite.Profiles:RegisterCharacter()
        Suite.GUI:RegisterSettings()
        Suite.Apply()
        Suite.Setup:OnLogin()
    elseif event == "ADDON_LOADED" and Suite.db then
        Suite.GUI:RegisterSettings()
    elseif event == "PLAYER_ENTERING_WORLD" then
        Suite.Leveling:OnWorld(name, second)
    elseif event == "PLAYER_LOGOUT" then
        Suite.Profiles:SaveActive()
        Suite.Leveling:SaveSession()
    elseif event == "PLAYER_REGEN_ENABLED" then
        local pending = Suite.pending
        Suite.pending = {}
        for _, callback in pairs(pending) do callback() end
        if Suite.GUI.page == "setup" then Suite.GUI:RefreshSetup() end
    elseif event == "PLAYER_REGEN_DISABLED" then
        if Suite.GUI.page == "setup" then Suite.GUI:RefreshSetup() end
    end
end)

SLASH_WOWFOREVERSUITE1 = "/wfs"
SLASH_WOWFOREVERSUITE2 = "/foreversuite"
local commandPages = {
    profiles = "profiles", profile = "profiles", characters = "characters", dashboard = "characters", gear = "items", items = "items",
    bags = "bags", macros = "macros", camping = "camping", campfire = "camping",
    actionbars = "actionbars", unitframes = "unitframes", vendor = "vendor", buffs = "buffs", missingbuffs = "buffs",
    bars = "bars", map = "worldmap", worldmap = "worldmap",
    quests = "quests", gossip = "quests", loot = "quests", mail = "mail", chat = "chat", audio = "audio",
    leveling = "leveling", xp = "leveling",
}
SlashCmdList.WOWFOREVERSUITE = function(message)
    local command = message:match("^%s*(%S*)"):lower()
    if command == "status" then Suite.Status()
    elseif command == "containerstatus" then
        local itemID = message:match("^%s*%S+%s+(%d+)%s*$")
        if itemID then Suite.AutoOpen:Status(tonumber(itemID))
        elseif message:match("^%s*%S+%s*$") then Suite.AutoOpen:Status()
        else Suite.Print("Usage: /wfs containerstatus [itemID]") end
    elseif command == "setup" then Suite.Setup:Open()
    elseif command == "windows" then Suite.Windows:Status()
    elseif command == "resetwindows" then Suite.Windows:ResetAll()
    elseif command == "training" or command == "trainer" then Suite.Training:Open()
    elseif command == "inventory" then Suite.CharacterBrowser:Open()
    elseif command == "bank" then Suite.OfflineBank:Toggle()
    elseif command == "macrostatus" then Suite.Macros:Status()
    elseif command == "meters" or command == "damage" then Suite.GUI:OpenMeters()
    elseif commandPages[command] then Suite.GUI:OpenPage(commandPages[command])
    else Suite.GUI:Toggle() end
end
