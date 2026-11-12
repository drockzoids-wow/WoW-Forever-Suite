local _, Suite = ...
local Support = { features = {} }
Suite.Diagnostics = Support

local function Read(value, kind) return Suite.IsReadable(value) and type(value) == kind end
local function Field(object, key)
    if not Suite.IsReadable(object) or (type(object) ~= "table" and type(object) ~= "userdata") then return nil, false end
    local ok, value = pcall(function() return object[key] end)
    if ok and Suite.IsReadable(value) then return value, true end
    return nil, false
end
local function Path(root, path)
    for key in path:gmatch("[^.]+") do root = Field(root, key); if root == nil then return end end
    return root
end
local function Call(fn, ...)
    if not Read(fn, "function") then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Add(key, label, module, requires, pending, combat, parent)
    Support.features[#Support.features + 1] = { key = key, label = label, module = module,
        requires = requires or {}, pending = pending or "", combat = combat, parent = parent }
end
local bags = { "C_Container.GetContainerNumSlots", "C_Container.GetContainerItemInfo" }
local tooltip = { "TooltipDataProcessor.AddTooltipPostCall" }
Add("minimapButton", "Settings launcher", "MinimapButton", {}, "minimapButton")
Add("minimapDrawer", "Minimap button drawer", "MinimapDrawer", {}, "minimapDrawer")
Add("squareMinimap", "Square minimap", "Minimap", {}, "minimap")
Add("minimapStats", "Minimap statistics", "Minimap", { "C_Timer.NewTicker" }, "minimap")
Add("revealWorldMap", "Map reveal", "WorldMap", {}, "worldMap")
Add("windowTools", "Window movement and scaling", "Windows", {}, "windowWork windowReset", true)
Add("sortBagsOnOpen", "Sort bags on opening", "BagSort", { "C_Container.SortBags", "C_Timer.NewTimer", "CursorHasItem" }, "bagSort", true)
Add("reverseCombinedBags", "Combined bag order", "CombinedBags", {}, "combinedBagOrder")
Add("reverseBagSlots", "Bag slot order", "BagSort", {}, "bagSortDirection")
Add("autoOpenContainers", "Automatic container opening", "AutoOpen", { "C_Container.UseContainerItem", "C_Container.GetContainerItemInfo" }, "autoOpen", true)
Add("bagSpaceAlert", "Low bag-space alert", "BagSpace", bags, "bagSpace")
Add("offlineBank", "Saved bank view", "OfflineBank", bags, "bankViewEnable bankViewRefresh bankViewToggle")
Add("bankDepositReagents", "Deposit Reagents button", "BankDeposit", { "C_Container.UseContainerItem", "C_Item.GetItemInfo", "C_Bank.CanViewBank", "C_Timer.NewTimer" }, "bankDepositEnable", true)
Add("itemInventory", "Inventory stock tooltips", "Inventory", bags, "inventory")
Add("inventorySearch", "Inventory search", "InventorySearch", bags, "inventorySearchEnable")
Add("characterDashboard", "Character records", "CharacterDashboard", {}, "dashboardEnable dashboardCapture dashboardView")
Add("itemLevels", "Item levels on icons", "Items", { "C_Item.GetItemInfo" }, "itemScan")
Add("itemTooltipLevels", "Item levels in tooltips", "Tooltips", tooltip, "tooltipInitialize")
Add("characterItemLevel", "Character item level", "Character", { "C_Item.GetItemInfo", "GetInventoryItemLink" }, "characterItemLevel")
Add("upgradeHints", "Gear upgrade advice", "Items", { "C_Item.GetItemInfo", "GetInventoryItemLink" }, "itemScan")
Add("equipmentSetToggle", "Equipment-set slot controls", "EquipmentSets", {}, "equipmentSetToggle", true)
Add("playerItemLevel", "Player item-level inspection", "Tooltips", { "NotifyInspect", "C_PaperDollInfo.GetInspectItemLevel" }, "tooltipInitialize", true)
Add("classNames", "Class-colored tooltip names", "Tooltips", tooltip, "tooltipInitialize")
Add("unitLevelColors", "Tooltip level difficulty colors", "Tooltips", { "TooltipDataProcessor.AddTooltipPostCall", "UnitLevel", "C_PlayerInfo.GetContentDifficultyCreatureForPlayer", "GetDifficultyColor" }, "tooltipInitialize")
Add("fullButtonRange", "Action-button range tint", "ActionBars", {}, "actionBars")
Add("actionBarSkin", "Action-bar styling", "ActionBarSkin", {}, "actionBarSkin")
Add("shortKeybinds", "Short keybind labels", "Keybinds", {}, "keybinds")
Add("keybindFontStyle", "Keybind font styling", "Keybinds", {}, "keybinds")
Add("statusBarSkin", "Progress-bar styling", "HUDSkin", {}, "hudSkin")
Add("progressBarValues", "Progress-bar values", "HUDSkin", {}, "hudSkin")
Add("progressBarCustomSize", "Progress-bar size", "HUDSkin", {}, "hudSkin")
Add("progressBarSegments", "Progress-bar segments", "HUDSkin", {}, "hudSkin")
Add("bagBarSkin", "Bag-button styling", "HUDSkin", {}, "hudSkin")
Add("microBarSkin", "Micro-menu styling", "HUDSkin", {}, "hudSkin")
Add("classHealthBars", "Class health-bar colors", "UnitFrames", {}, "unitFrames")
Add("targetThreat", "Target threat", "TargetThreat", { "UnitDetailedThreatSituation" }, "targetThreatLayout")
Add("combatIndicator", "Combat indicator", "CombatIndicator", {}, "combatIndicator combatIndicatorVisual")
Add("procAlerts", "Ability proc popups", "ProcAlerts", { "C_Spell.IsSpellUsable", "C_Spell.GetSpellCooldown" }, "procAlerts")
Add("playerBuffBorders", "Buff borders", "BuffBorders", {}, "buffBorders")
Add("missingBuffs", "Out-of-combat buff bar", "MissingBuffs", { "C_UnitAuras.GetAuraDataByIndex" }, "missingBuffs", true)
Add("missingBuffExpiry", "Buff expiry reminders", "BuffReminders", {}, "buffOptions", nil, "missingBuffs")
Add("missingBuffWeapons", "Weapon buff reminders", "BuffReminders", { "GetWeaponEnchantInfo" }, "buffOptions", nil, "missingBuffs")
Add("missingBuffCombat", "Combat buff reminders", "CombatBuffs", {}, "combatBuffs", nil, "missingBuffs")
Add("damageMeters", "Damage meters", "DamageMeters", { "C_DamageMeter.IsDamageMeterAvailable", "C_DamageMeter.GetCombatSessionFromType", "C_DamageMeter.GetCombatSessionFromID", "C_DamageMeter.GetAvailableCombatSessions" }, "meters meterLayout")
Add("autoRepair", "Automatic repairs", "Vendor", { "CanMerchantRepair", "GetRepairAllCost", "RepairAllItems" }, "vendor", true)
Add("autoSellJunk", "Automatic junk selling", "Vendor", { "C_Container.GetContainerItemInfo", "C_Container.UseContainerItem" }, "vendor", true)
Add("autoVendor", "Vendor conversation", "Quests", { "C_GossipInfo.GetOptions", "C_GossipInfo.SelectOption" }, "quests", true)
Add("vendorKnownItems", "Known vendor highlights", "MerchantKnown", { "GetMerchantItemLink", "C_Item.GetItemInfo" }, "merchantKnownApply", true)
Add("autoQuestPickup", "Automatic quest pickup", "Quests", { "AcceptQuest" }, "quests", true)
Add("autoQuestTurnIn", "Automatic quest turn-in", "Quests", { "CompleteQuest", "GetQuestReward" }, "quests", true)
Add("autoGossip", "Automatic conversation", "Quests", { "C_GossipInfo.GetOptions", "C_GossipInfo.SelectOption" }, "quests", true)
Add("quickLoot", "Quick loot", "Loot", { "GetNumLootItems", "LootSlot" }, "", true)
Add("questTrackerRemember", "Remember quest tracker state", "QuestTrackerState", {}, "questTrackerState")
Add("questTrackerSkin", "Quest tracker styling", "QuestTrackerSkin", {}, "questTrackerSkin")
Add("questItemButton", "Nearby quest-item button", "QuestItem", { "GetQuestLogSpecialItemInfo" }, "questItemRefresh questItemApply questItemPosition")
Add("zoneReputation", "Zone reputation selection", "ZoneReputation", { "C_Reputation.SetWatchedFactionByID" }, "zoneReputation", true)
Add("modifierDisenchant", "Disenchant shortcut", "ProfessionHelper", { "C_Spell.GetSpellInfo" }, "professions", true)
Add("autoReplaceEnchant", "Enchant replacement confirmation", "ProfessionHelper", {}, "professionHide", true)
Add("professionLeveling", "Profession leveling guides", "ProfessionLeveling", { "C_TradeSkillUI.GetBaseProfessionInfo" }, "professionLevelingApply professionLevelingRefresh", true)
Add("mailHelper", "Mailbox contacts", "Mail", {}, "mail")
Add("mailRememberRecipient", "Remember mail recipients", "Mail", {}, "mail")
Add("mailExpiry", "Mail deadline recording", "MailExpiry", { "GetInboxNumItems", "GetInboxHeaderInfo", "GetServerTime" }, "mailExpiryApply", true)
Add("supplyChecklist", "Carried supply counts", "SupplyChecklist", bags, "", true)
Add("chatStyle", "Chat styling", "Chat", {}, "chat")
Add("chatHistory", "Saved chat history", "ChatHistory", {}, "chatHistory")
Add("audioSync", "Audio output sync", "Audio", { "C_CVar.GetCVarInfo", "C_CVar.SetCVar", "Sound_GameSystem_RestartSoundSystem" }, "audioEnable")
Add("chatShortcuts", "Chat shortcuts", "Shortcuts")
Add("macroUpdates", "Class macro maintenance", "Macros", { "GetMacroInfo", "EditMacro" }, "macroUseWatch macroLogin", true)
Add("campingBar", "Camping bar", "Camping", { "C_UnitAuras.GetAuraDataByIndex", "RegisterStateDriver" }, "camping", true)
Add("levelingBar", "Leveling tracker", "Leveling", { "UnitXP", "UnitXPMax" }, "leveling levelingPresentation")
Add("trainingPlanner", "Training planner", "Training", { "C_Spell.GetSpellInfo" }, "trainingApply trainingOpen trainingView")
Add("talentPlanner", "Talent planner", "TalentPlanner", { "C_Traits.GetTreeNodes", "C_Traits.GetNodeInfo" }, "talentPlanner")
Add("manualMacros", "Macro Builder actions", "Macros", { "GetMacroInfo", "CreateMacro", "EditMacro" }, "", true)
Add("randomMount", "Random mount recipe", "Macros", { "C_MountJournal.GetMountIDs", "C_MountJournal.GetMountInfoByID", "C_MountJournal.GetMountUsabilityByID", "C_MountJournal.SummonByID", "IsMounted", "Dismount", "EditMacro" }, "", true)
Add("contactBook", "Standalone contact book", "Mail")
for _, unit in ipairs({ "player", "target", "focus" }) do Add("castbars." .. unit .. ".enabled", unit .. " castbar sizing", "Castbars", {}, "castbars") end

local manual = { manualMacros = true, randomMount = true, contactBook = true }
local function Enabled(entry)
    if manual[entry.key] then return true end
    if not Read(Suite.db, "table") then return end
    if entry.key:match("^castbars%.") then
        local castbars, valid = Field(Suite.db, "castbars")
        if not valid or not Read(castbars, "table") then return end
        local unit = entry.key:match("^castbars%.(%a+)%.")
        local options, readable = Field(castbars, unit)
        if not readable then return end
        if options == nil then return false end
        local enabled, known = Field(options, "enabled")
        if known and enabled == nil then return false end
        if Read(enabled, "boolean") then return enabled end
        return
    end
    local value = Field(Suite.db, entry.key)
    if Read(value, "boolean") then return value end
end
local function Present(path)
    return Read(Path(_G, path), "function")
end
local function Visible(name)
    local frame, readable = Field(_G, name)
    if not readable then return end
    if frame == nil then return false end
    if Read(Field(frame, "IsForbidden"), "function") and Call(Field(frame, "IsForbidden"), frame) ~= false then return end
    local shown = Call(Field(frame, "IsShown"), frame)
    if Read(shown, "boolean") then return shown end
end
local function Flag(module, key) return Field(module, key) == true end
local function GearContext()
    local scorer = Field(Suite, "Scoring")
    local db = Field(Suite, "db")
    if not Read(db, "table") then return nil, nil, nil, scorer end
    local state = Field(scorer, "owner") == db and Field(scorer, "character") or nil
    local mode = Field(state, "preference") or Field(Suite.db, "upgradePreference")
    local active = Field(state, "active") or Field(db, "scorePreset")
    local profile
    if Read(active, "string") and #active <= 32 then
        if active == "automatic" then profile = Field(scorer, "automaticProfile")
        else profile = Field(Field(scorer, "presets"), active) end
        if not profile then
            local specs, class = Field(scorer, "specs"), Field(scorer, "class")
            for index = 1, 29 do
                local entry = Field(specs, index)
                if Field(entry, "id") == active and Field(entry, "class") == class then profile = entry; break end
            end
        end
        if not profile then
            local profiles = Field(state, "profiles")
            for index = 1, 8 do
                local entry = Field(profiles, index)
                if Field(entry, "id") == active then profile = entry; break end
            end
        end
    end
    return mode, active, profile, scorer
end

function Support:State(entry, combat)
    local enabled = Enabled(entry)
    if enabled == false then return "Off", "Disabled in settings." end
    if enabled == nil then return "Unknown", "Setting is unavailable or unreadable." end
    if entry.parent then
        local parent = Field(Suite.db, entry.parent)
        if not Read(parent, "boolean") then return "Unknown", "Parent setting is unavailable: " .. entry.parent end
        if not parent then return "Off", "Requires " .. entry.parent .. "." end
    end
    local module = Field(Suite, entry.module)
    if not Read(module, "table") or not Read(Field(module, "Apply"), "function") then return "Unavailable", "Suite component is not loaded: " .. entry.module end
    local missing = {}
    for _, path in ipairs(entry.requires) do if not Present(path) then missing[#missing + 1] = path end end
    if entry.key == "upgradeHints" then
        local mode, _, profile = GearContext()
        if mode ~= "stats" and mode ~= "ilevel" then return "Unknown", "Comparison preference is unavailable." end
        if mode ~= "ilevel" and not Present("C_Item.GetItemStats") then missing[#missing + 1] = "C_Item.GetItemStats" end
        if mode ~= "ilevel" then
            if not Read(profile, "table") then return "Unknown", "Selected scoring profile is not initialized or available." end
            local weights = Field(profile, "weights")
            for _, school in ipairs({ "HOLY", "FIRE", "NATURE", "FROST", "SHADOW", "ARCANE" }) do
                local weight, readable = Field(weights, school .. "_DAMAGE")
                if not readable then return "Unknown", "Selected profile's school requirement is unreadable." end
                if Read(weight, "number") and weight > 0 then
                    if not Present("C_TooltipInfo.GetHyperlink") then missing[#missing + 1] = "C_TooltipInfo.GetHyperlink"; break end
                    local locale = Call(GetLocale)
                    if not Read(locale, "string") then return "Unknown", "School-parser locale is unavailable." end
                    if locale ~= "enUS" and locale ~= "enGB" then return "Unavailable", "Selected profile needs school bonuses; only English static tooltips are supported." end
                end
            end
        end
    end
    if #missing > 0 then return "Unavailable", "Missing or unreadable function: " .. table.concat(missing, ", ") end
    if entry.key == "damageMeters" then
        if not Read(Path(_G, "Enum.DamageMeterType"), "table") or not Read(Path(_G, "Enum.DamageMeterSessionType"), "table")
            or not Read(Path(_G, "Enum.DamageMeterSessionType.Current"), "number") or not Read(Path(_G, "Enum.DamageMeterSessionType.Overall"), "number") then
            return "Unavailable", "Damage meter enum/session definitions are missing or unreadable."
        end
        local available = Call(Path(_G, "C_DamageMeter.IsDamageMeterAvailable"))
        if available == false then return "Unavailable", "Client reports damage meters unavailable in this context." end
        if available ~= true then return "Unknown", "Client availability check failed or is unreadable." end
    end
    for key in entry.pending:gmatch("%S+") do
        if Read(Field(Suite.pending, key), "function") then return "Paused", "Setup/layout work is queued until combat ends; an existing display may continue." end
    end
    if combat == true and entry.combat then return "Paused", "This feature's actions or changes wait until combat ends." end
    if combat == nil and entry.combat then return "Unknown", "Combat state is unavailable; action readiness cannot be determined." end
    if entry.key == "macroUpdates" or entry.key == "randomMount" or entry.key == "manualMacros" then
        local visible = Visible("MacroFrame")
        if visible == nil then return "Unknown", "Native macro editor visibility is unreadable." end
        if visible then return "Paused", "Native macro editor is open; Suite preserves its edits." end
    end
    if entry.key == "audioSync" and (Flag(module, "cinematic") or Flag(module, "movie")) then return "Paused", "Audio refresh waits for the movie/cinematic to end." end
    if entry.key == "audioSync" then
        local ok, value, _, _, _, locked, secure, readOnly = pcall(Path(_G, "C_CVar.GetCVarInfo"), "Sound_OutputDriverIndex")
        if not ok or not Read(value, "string") or value == "" or not Read(locked, "boolean") or not Read(secure, "boolean") or not Read(readOnly, "boolean") then
            return "Unknown", "Audio output preference/permission flags are unavailable."
        end
        if locked or secure or readOnly then return "Unavailable", "Audio output preference is locked, secure or read-only." end
    end
    if entry.key == "missingBuffCombat" then
        local failure, readable = Field(module, "failure")
        if not readable then return "Unknown", "Native aura setup status is unreadable." end
        if failure ~= nil then return "Unavailable", "Native aura setup reported a failure; use /wfs buffstatus locally." end
        if Flag(module, "suspended") then return "Paused", "Combat aura layout is suspended pending an out-of-combat rebuild." end
    end
    if entry.key == "supplyChecklist" then
        local visible = Visible("WoWForeverSuiteSupplies")
        if visible == nil then return "Unknown", "Checklist visibility is unreadable." end
        if not visible then return "Waiting", "Open the Supply Checklist to count carried items." end
    end
    if entry.key == "campingBar" and not Flag(module, "nearby") then return "Waiting", "Campfire proximity has not been observed; no aura scan is run by this report." end
    if entry.key == "mailExpiry" and not Flag(module, "mailOpen") then return "Waiting", "Visit a mailbox to refresh saved observations." end
    if entry.key == "autoRepair" or entry.key == "autoSellJunk" or entry.key == "vendorKnownItems" then
        local visible = Visible("MerchantFrame")
        if visible == nil then return "Unknown", "Vendor window visibility is unreadable." end
        if not visible then return "Waiting", "Waiting for a vendor visit." end
    end
    if entry.key == "mailHelper" or entry.key == "mailRememberRecipient" then
        local visible = Visible("MailFrame")
        if visible == nil then return "Unknown", "Mailbox visibility is unreadable." end
        if not visible then return "Waiting", "Waiting for an open mailbox." end
    end
    if entry.key == "talentPlanner" then
        local spells, spellsKnown = Field(_G, "PlayerSpellsFrame")
        local talents, talentsKnown = Field(_G, "ClassTalentFrame")
        if not spellsKnown or not talentsKnown then return "Unknown", "Native talent window availability is unreadable." end
        if not spells and not talents then return "Waiting", "Native talent window is not loaded; open it to initialize the planner." end
        if not Read(Field(module, "model"), "table") then return "Waiting", "Native talent data is not initialized; open the planner after it loads." end
    end
    if entry.key == "randomMount" then return "Ready", "Capabilities present; requires an explicitly created, owned macro and usable collected mount." end
    return "Ready", #entry.requires > 0 and "Required functions present; context/data/permissions are not verified." or "Suite component loaded; native widget/context readiness is not probed."
end

local function SafeNumber(value)
    return Read(value, "number") and value == value and value >= 0 and value < 100000000000 and tostring(value) or "unavailable"
end
local function Code(value, pattern)
    return Read(value, "string") and #value <= 32 and value:match(pattern) and value or "unavailable"
end
function Support:Snapshot()
    local combat = Call(InCombatLockdown)
    if not Read(combat, "boolean") then combat = nil end
    local version, build, interface
    local getBuild = Field(_G, "GetBuildInfo")
    if Read(getBuild, "function") then
        local ok, a, b, _, d = pcall(getBuild)
        if ok then version, build, interface = a, b, d end
    end
    local locale = Code(Call(GetLocale), "^%l%l%u%u$")
    local now = Call(GetServerTime)
    local rows, counts = {}, {}
    for _, entry in ipairs(self.features) do
        local state, reason = self:State(entry, combat)
        rows[#rows + 1] = { key = entry.key, label = entry.label, state = state, reason = reason }
        counts[state] = (counts[state] or 0) + 1
    end
    local mode, active, selected = GearContext()
    local profile = "unavailable"
    if Read(active, "string") then
        if active:match("^custom%d+$") then profile = "custom (name and weights omitted)"
        elseif active == "automatic" or Read(selected, "table") then profile = Code(active, "^[%w_]+$") end
    end
    local lines = { "Forever Suite support report v1", "Suite: " .. Code(Suite.version, "^%d+%.%d+%.%d+$"),
        "Client: " .. Code(version, "^%d+%.%d+%.%d+$") .. " | build " .. Code(build, "^%d+$") .. " | Interface " .. (Read(interface, "string") and Code(interface, "^%d+$") or SafeNumber(interface)),
        "Locale: " .. locale .. " | snapshot server time: " .. SafeNumber(now),
        "Combat: " .. (combat == true and "yes" or combat == false and "no" or "unknown"),
        "Saved settings loaded at startup: " .. (Flag(Suite, "loadedSavedVariables") and "yes" or "no/unknown"),
        "Gear comparison: " .. (mode == "stats" and "weighted stats" or mode == "ilevel" and "item level" or "unavailable") .. " | profile: " .. profile,
        "Snapshot only. Ready checks capabilities, not gameplay success or taint safety.",
        "No contacts, chat, inventory contents, macro text, player/realm names or custom names/weights are included.", "", "Features:" }
    for _, row in ipairs(rows) do lines[#lines + 1] = row.label .. " [" .. row.key .. "]: " .. row.state .. " - " .. row.reason end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Created item macros check supplies on login/use independently of the class macro-maintenance switch."
    lines[#lines + 1] = "Restricted combat data, lazy-loaded widgets and item-specific eligibility are not exhaustively probed."
    return table.concat(lines, "\n"), rows, counts, combat
end

function Support:PrintStatus()
    local body, rows, counts, combat = self:Snapshot()
    if combat == true then self.captured = body end
    for line in body:gmatch("[^\n]+") do if line == "Features:" then break end; Suite.Print(line) end
    Suite.Print("Diagnostics: " .. (counts.Unavailable or 0) .. " unavailable, " .. (counts.Paused or 0) .. " paused, " .. (counts.Waiting or 0) .. " waiting, " .. (counts.Unknown or 0) .. " unknown.")
    for _, row in ipairs(rows) do
        if row.state == "Unavailable" or row.state == "Paused" or row.state == "Unknown" then Suite.Print(row.label .. ": " .. row.state .. " - " .. row.reason) end
    end
    Suite.Print(combat == true and "Combat snapshot captured. Use /wfs support after combat to copy it."
        or "Copy the complete snapshot with /wfs support outside combat.")
end

local function Label(parent, text, x, y, width, size)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", size or 11, ""); label:SetPoint("TOPLEFT", x, y); label:SetWidth(width)
    label:SetJustifyH("LEFT"); label:SetTextColor(0.88, 0.91, 0.93); label:SetText(text); return label
end
function Support:Display(body, captured)
    if InCombatLockdown() or not self.frame or not self.frame:IsShown() then return end
    self.body = body
    self.edit:SetText(self.body); self.scroll:SetVerticalScroll(0)
    self.caption:SetText(captured and "Captured combat snapshot; Refresh shows current state." or "Current snapshot; refresh after conditions change.")
    self.edit:SetFocus(); self.edit:HighlightText()
end
function Support:Refresh()
    if InCombatLockdown() or not self.frame or not self.frame:IsShown() then return end
    self.captured = nil
    local body = self:Snapshot(); self:Display(body, false)
end
function Support:Open(owner)
    if InCombatLockdown() then
        self.captured = self:Snapshot()
        Suite.Print("Combat snapshot captured. Run /wfs support after combat to copy it; no window will open automatically.")
        return
    end
    if not self.frame then
        local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate"); self.frame = frame
        frame:Hide(); frame:SetSize(740, 540); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG")
        frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true)
        frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        frame:SetBackdropColor(0.035, 0.05, 0.065, 1); Suite.Theme:Backdrop(frame, 1)
        local header = CreateFrame("Frame", nil, frame); header:SetPoint("TOPLEFT"); header:SetSize(690, 42)
        header:EnableMouse(true); header:RegisterForDrag("LeftButton")
        Label(header, "Support report", 14, -12, 650, 18)
        header:SetScript("OnDragStart", function() if not InCombatLockdown() then self.moving = true; frame:StartMoving() end end)
        header:SetScript("OnDragStop", function() if self.moving then frame:StopMovingOrSizing(); self.moving = nil end end)
        local close = Suite.Theme:IconButton(frame, "Close support report", function() frame:Hide() end); close:SetPoint("TOPRIGHT", -10, -9)
        Label(frame, "Snapshot only. Ctrl+A selects all; Ctrl+C copies. Escape closes. Refresh captures current reasons.", 14, -52, 710)
        Label(frame, "Closes in combat. /wfs support or /wfs status captures combat context for later copying.", 14, -70, 710)
        local scroll = CreateFrame("ScrollFrame", nil, frame, "InputScrollFrameTemplate"); self.scroll, self.edit = scroll, scroll.EditBox
        scroll:SetPoint("TOPLEFT", 16, -96); scroll:SetPoint("BOTTOMRIGHT", -34, 52)
        if scroll.CharCount then scroll.CharCount:Hide() end
        local edit = self.edit
        edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:SetMaxLetters(0); edit:SetWidth(680); edit:SetFont("Fonts\\ARIALN.TTF", 12, "")
        edit:HookScript("OnTextChanged", function(box, user) if user then box:SetText(self.body or "") end end)
        edit:SetScript("OnEscapePressed", function() frame:Hide() end)
        local function Button(text, x, width, callback)
            local button = CreateFrame("Button", nil, frame, "BackdropTemplate"); button:SetPoint("BOTTOMLEFT", x, 10); button:SetSize(width, 28)
            button:SetFrameLevel(edit:GetFrameLevel() + 2)
            button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
            button:SetBackdropColor(0.07, 0.095, 0.11, 1); Suite.Theme:Backdrop(button, 0.5); Suite.Theme:ButtonFeedback(button)
            Label(button, text, 10, -7, width - 20, 12)
            button:SetScript("OnClick", function() if not InCombatLockdown() then callback() end end); return button
        end
        self.select = Button("Select all", 14, 112, function() edit:SetFocus(); edit:HighlightText() end)
        self.refresh = Button("Refresh", 614, 112, function() self:Refresh() end)
        self.caption = Label(frame, "", 142, -507, 455, 10)
        header:SetFrameLevel(edit:GetFrameLevel() + 2); close:SetFrameLevel(edit:GetFrameLevel() + 3)
        frame:SetScript("OnEvent", function() frame:Hide() end)
        frame:SetScript("OnHide", function()
            if self.moving then frame:StopMovingOrSizing(); self.moving = nil end
            frame:UnregisterAllEvents(); edit:ClearFocus(); self.body = nil; edit:SetText("")
        end)
    end
    Suite.PlaceWindow(self.frame, owner)
    self.frame:Show(); self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    if self.captured then
        local body = self.captured; self.captured = nil; self:Display(body, true)
    else self:Refresh() end
end
