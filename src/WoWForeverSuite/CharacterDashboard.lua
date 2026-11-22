local _, Suite = ...
local Dashboard = { page = 1, query = "", sort = "name" }
Suite.CharacterDashboard = Dashboard
table.insert(Suite.modules, Dashboard)
local PAGE_SIZE, LIMIT = 5, 200
local WELL_RESTED_SPELL, WELL_RESTED_MAX_RANK = 1225478, 5
local REST_XP_CAP, REST_XP_PER_RANK = 1.5, 0.04
local REST_XP_SECONDS_PER_LEVEL = 8 * 60 * 60 / 0.05
-- Forever 1.60.1.71037 LevelExperience, ContentSetID 0, levels 1 through 59.
local LEVEL_XP = {
    400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500, 7600,
    8800, 10100, 11400, 12900, 14400, 16000, 17700, 19400, 21300, 23200,
    25200, 27300, 29400, 31700, 34000, 36400, 38900, 41400, 44300, 47400,
    50800, 54500, 58600, 62800, 67100, 71600, 76100, 80800, 85700, 90700,
    95800, 101000, 106300, 111800, 117500, 123200, 129100, 135100, 141200, 147500,
    153900, 160400, 167100, 173900, 180800, 187900, 195000, 202300, 209800,
}
local teal, muted, white = { 0.41, 0.84, 0.75 }, { 0.55, 0.65, 0.7 }, { 0.88, 0.91, 0.93 }
local function Table(value) return Suite.IsReadable(value) and type(value) == "table" end
local function Text(value, limit)
    return Suite.IsReadable(value) and type(value) == "string" and #value > 0 and #value <= (limit or 128)
        and not value:find("[%c|]")
end
local function Integer(value, low, high)
    return Suite.IsReadable(value) and type(value) == "number" and value >= low and value <= high and value == math.floor(value)
end
local function Call(fn, ...)
    if not Suite.IsReadable(fn) or type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function At(value) return Integer(value, 1, 10000000000) and value or nil end
local function SnapshotAt(value) return Table(value) and At(value.at) or nil end
local function RestedCap(xpMax, rank)
    if Integer(xpMax, 1, 2147483647) and Integer(rank, 0, WELL_RESTED_MAX_RANK) then
        return xpMax * REST_XP_CAP * (1 + rank * REST_XP_PER_RANK)
    end
end
local function RestedSnapshot(value, now, recordedLevel, levelAt)
    local at = SnapshotAt(value)
    if not at then return end
    if Suite.IsReadable(value.maxLevel) and value.maxLevel == true then return { maxLevel = true, at = at } end
    if not Integer(value.amount, 0, 2147483647) then return end
    local result = { amount = value.amount, at = at }
    if Integer(value.xpMax, 1, 2147483647) then result.xpMax = value.xpMax end
    if Integer(value.level, 1, #LEVEL_XP) then result.level = value.level
    elseif Integer(levelAt, at, at) and Integer(recordedLevel, 1, #LEVEL_XP) then result.level = recordedLevel end
    local offline = value.offline
    if not Table(offline) or not Integer(offline.logoutAt, at, 10000000000) then return result end
    if not result.xpMax and Integer(offline.xpMax, 1, 2147483647) then result.xpMax = offline.xpMax end
    local cap = RestedCap(offline.xpMax, offline.rank)
    if not cap or not now or offline.logoutAt > now
        or not Suite.IsReadable(offline.resting) or type(offline.resting) ~= "boolean" then return result end

    local bonus = 1 + offline.rank * REST_XP_PER_RANK
    local seconds = now - offline.logoutAt
    local locationRate = offline.resting and 1 or 0.25
    local gain = seconds / REST_XP_SECONDS_PER_LEVEL * offline.xpMax * locationRate * bonus
    local amount = math.floor(math.min(value.amount + gain, cap))
    if amount > value.amount then
        result.estimate = amount
        result.offline = offline
    end
    return result
end
local function ReadRestedXP(at)
    local maxLevel = Table(GameRulesUtil) and Call(GameRulesUtil.IsPlayerAtEffectiveMaxLevel)
    if maxLevel == true then return { maxLevel = true, at = at } end
    if not Suite.IsReadable(GetXPExhaustion) or type(GetXPExhaustion) ~= "function" then return end
    local ok, amount = pcall(GetXPExhaustion)
    if not ok or not Suite.IsReadable(amount) then return end
    -- A nil threshold with Blizzard's normal rest state means there is no rested XP.
    if amount == nil and Call(GetRestState) == 2 then amount = 0 end
    if Integer(amount, 0, 2147483647) then return { amount = amount, at = at } end
end
local function RestedPercent(amount, xpMax, level)
    if not xpMax then return end
    if amount <= xpMax then return math.floor(amount * 100.0 / xpMax) end
    -- Only use the bundled curve when it agrees with the live reading for this level.
    if not level or LEVEL_XP[level] ~= xpMax then return end
    local percent = 100
    amount = amount - xpMax
    for nextLevel = level + 1, #LEVEL_XP do
        local requirement = LEVEL_XP[nextLevel]
        if amount < requirement then return percent + math.floor(amount * 100.0 / requirement) end
        amount, percent = amount - requirement, percent + 100
    end
    return percent
end
local function RestedLabel(snapshot, confirmed)
    if not snapshot then return "Not recorded" end
    if snapshot.maxLevel then return "Max level" end
    local estimate = not confirmed and snapshot.estimate
    local amount = estimate or snapshot.amount
    local label = Call(BreakUpLargeNumbers, amount)
    label = (estimate and "≈" or "") .. (Text(label) and label or tostring(amount))
    local xpMax = estimate and snapshot.offline.xpMax or snapshot.xpMax
    local percent = RestedPercent(amount, xpMax, snapshot.level)
    if not percent then return label end
    return label .. " (" .. (amount > 0 and percent == 0 and "<1" or tostring(percent)) .. "%)", percent
end
local function FindWellRestedNode(traits, treeID, configID)
    local nodes = Call(traits.GetTreeNodes, treeID)
    if not Table(nodes) or #nodes > 128 then return end
    for index = 1, #nodes do
        local nodeID = nodes[index]
        if Integer(nodeID, 1, 2147483647) then
            local node = Call(traits.GetNodeInfo, configID, nodeID)
            local entries = Table(node) and node.entryIDs
            if Table(entries) and #entries == 1 and Integer(entries[1], 1, 2147483647) then
                local entry = Call(traits.GetEntryInfo, configID, entries[1])
                if Table(entry) and Integer(entry.definitionID, 1, 2147483647) then
                    local definition = Call(traits.GetDefinitionInfo, entry.definitionID)
                    if Table(definition) and Integer(definition.spellID, WELL_RESTED_SPELL, WELL_RESTED_SPELL) then
                        return nodeID, node
                    end
                end
            end
        end
    end
end
function Dashboard:ReadWellRestedRank()
    if not Table(C_Traits) or not Table(Constants) or not Table(Constants.LegacyConsts) then return end
    local treeID = Constants.LegacyConsts.LEGACY_TREE_ADVENTURE_ID
    if not Integer(treeID, 1, 2147483647) then return end
    local configID = Call(C_Traits.GetConfigIDByTreeID, treeID)
    if not Integer(configID, 1, 2147483647) or Call(C_Traits.ConfigHasStagedChanges, configID) ~= false then return end

    local node
    if self.wellRestedTree == treeID then node = Call(C_Traits.GetNodeInfo, configID, self.wellRestedNode)
    else
        local nodeID
        nodeID, node = FindWellRestedNode(C_Traits, treeID, configID)
        if nodeID then self.wellRestedTree, self.wellRestedNode = treeID, nodeID end
    end
    if Table(node) and Integer(node.maxRanks, WELL_RESTED_MAX_RANK, WELL_RESTED_MAX_RANK)
        and Integer(node.activeRank, 0, WELL_RESTED_MAX_RANK) then return node.activeRank end
end
local function ClassName(token)
    if not Text(token, 32) then return "Unknown class" end
    local names = LOCALIZED_CLASS_NAMES_MALE
    if Table(names) and Text(names[token]) then return names[token] end
    return token:sub(1, 1) .. token:sub(2):lower()
end
local function ClassColor(token)
    local color = Table(RAID_CLASS_COLORS) and Text(token, 32) and RAID_CLASS_COLORS[token]
    if Table(color) then
        local valid = true
        for _, key in ipairs({ "r", "g", "b" }) do
            local value = color[key]
            if not Suite.IsReadable(value) or type(value) ~= "number" or not (value >= 0 and value <= 1) then valid = false end
        end
        if valid then return color.r, color.g, color.b end
    end
    return unpack(teal)
end
function Dashboard:Enabled()
    return Suite.db and Suite.IsReadable(Suite.db.characterDashboard) and Suite.db.characterDashboard == true
end
function Dashboard:Money(value)
    if not Integer(value, 0, 200000000000000) then return "Not recorded" end
    return math.floor(value / 10000) .. "g " .. math.floor(value / 100) % 100 .. "s " .. value % 100 .. "c"
end
function Dashboard:Stamp(value)
    if not At(value) then return "Not recorded" end
    local label = Call(date, "%b %d, %H:%M", value)
    return Text(label) and label or "Date unavailable"
end
local function Professions(value)
    if not Table(value) or #value > 7 then return end
    local count = 0
    for key in pairs(value) do
        if not Integer(key, 1, 7) then return end
        count = count + 1
    end
    if count ~= #value then return end
    local result = {}
    for _, skill in ipairs(value) do
        if not Table(skill) or not Text(skill.name) or not Integer(skill.rank, 0, 1000000)
            or not Integer(skill.maxRank, 0, 1000000) or skill.rank > skill.maxRank then return end
        result[#result + 1] = { name = skill.name, rank = skill.rank, maxRank = skill.maxRank }
    end
    return result
end
function Dashboard:ReadProfessions()
    if not Suite.IsReadable(GetProfessions) or type(GetProfessions) ~= "function"
        or not Suite.IsReadable(GetProfessionInfo) or type(GetProfessionInfo) ~= "function" then return end
    local values, result, seen = { pcall(GetProfessions) }, {}, {}
    if not values[1] then return end
    -- Forever's Camelot professions frame consumes two primary and five secondary returns.
    for index = 2, 8 do
        local skill = values[index]
        if not Suite.IsReadable(skill) then return end
        if skill ~= nil then
            if not Integer(skill, 1, 1000) or seen[skill] then return end
            seen[skill] = true
            local ok, name, _, rank, maximum = pcall(GetProfessionInfo, skill)
            if not ok or not Text(name) or not Integer(rank, 0, 1000000)
                or not Integer(maximum, 0, 1000000) or rank > maximum then return end
            result[#result + 1] = { name = name, rank = rank, maxRank = maximum }
        end
    end
    return result
end
function Dashboard:Capture()
    if not self:Enabled() or self.shuttingDown then return end
    if InCombatLockdown() then
        Suite.pending.dashboardCapture = function() self:Schedule() end
        return
    end
    local at = At(Call(GetServerTime))
    if not at then return end
    local character = Suite.Inventory:Character()
    if not character then return end
    local profile = Table(character.profile) and character.profile or {}
    character.profile = profile
    local level, money = Call(UnitLevel, "player"), Call(GetMoney)
    if Integer(level, 1, 1000) then profile.level, profile.levelAt = level, at end
    if Integer(money, 0, 1000000000000) then profile.money, profile.moneyAt = money, at end
    local rested = ReadRestedXP(at)
    self.restedLogout = nil
    if rested then
        profile.restedXP = rested
        if rested.amount then
            local xpMax, resting = Call(UnitXPMax, "player"), Call(IsResting)
            local rank = self:ReadWellRestedRank()
            if Integer(xpMax, 1, 2147483647) then rested.xpMax = xpMax end
            if Integer(level, 1, #LEVEL_XP) then rested.level = level end
            if rested.xpMax and type(resting) == "boolean" and rank ~= nil then
                self.restedLogout = { snapshot = rested, xpMax = xpMax, resting = resting, rank = rank }
            end
        end
    elseif Table(profile.restedXP) then
        -- This character has been played again, so the previous offline interval ended.
        profile.restedXP.offline = nil
    end
    local professions = self:ReadProfessions()
    if professions then profile.professions, profile.professionsAt = professions, at end
    local ruleset = Call(Suite.Mail.CurrentRuleset, Suite.Mail)
    if Text(ruleset) then profile.ruleset = ruleset end
    profile.at = at
    self:RefreshView()
end
function Dashboard:Rows(query, sort)
    local region, current = Call(GetCurrentRegion), Call(UnitGUID, "player")
    if not Integer(region, 1, 1000000) then return {}, 0, 0, 0, false, false end
    current = Text(current) and current or nil
    if not Suite.IsReadable(query) or type(query) ~= "string" or #query > 100 or query:find("[%c|]") then return {}, 0, 0, 0, false end
    if not Text(sort) or not ({ name = true, money = true, level = true, at = true })[sort] then sort = "name" end
    local tokens = {}; for token in query:lower():gmatch("%S+") do tokens[#tokens + 1] = token end
    local rows, total, gold, known, limited = {}, 0, 0, 0, false
    local now = current and At(Call(GetServerTime))
    for guid, character in pairs(Suite.Inventory:Database().characters) do
        if Text(guid) and Table(character) and Text(character.name)
            and Integer(character.region, 1, 1000000) and character.region == region then
            if total == LIMIT then limited = true; break end
            total = total + 1
            local profile = Table(character.profile) and character.profile or {}
            local owner = Suite.InventorySearch:Owner(character, guid)
            local realm = Text(character.realm) and character.realm or "Realm unavailable"
            local row = { guid = guid, name = Text(owner.name) and owner.name or character.name, realm = realm,
                class = Text(character.class, 32) and character.class or nil, current = guid == current,
                ruleset = Text(profile.ruleset) and profile.ruleset
                    or Text(owner.context) and owner.context ~= realm and owner.context or "Unknown ruleset",
                level = Integer(profile.level, 1, 1000) and profile.level or nil,
                money = Integer(profile.money, 0, 1000000000000) and profile.money or nil,
                restedXP = RestedSnapshot(profile.restedXP, guid ~= current and now or nil, profile.level, profile.levelAt),
                professions = Professions(profile.professions),
                at = At(profile.at), levelAt = At(profile.levelAt),
                moneyAt = At(profile.moneyAt), professionsAt = At(profile.professionsAt),
                bagsAt = SnapshotAt(character.bags), bankAt = SnapshotAt(character.bank) or SnapshotAt(character.bankView),
                mailExpiry = Suite.MailExpiry:Validate(character.mailExpiry) }
            if row.money then gold, known = gold + row.money, known + 1 end
            local words = (row.name .. " " .. row.realm .. " " .. row.ruleset .. " " .. (row.class or ""))
            if row.professions then for _, skill in ipairs(row.professions) do words = words .. " " .. skill.name end end
            words = words:lower()
            local matches = true
            for _, token in ipairs(tokens) do if not words:find(token, 1, true) then matches = false; break end end
            if matches then rows[#rows + 1] = row end
        end
    end
    table.sort(rows, function(a, b)
        if sort == "money" or sort == "level" or sort == "at" then
            local left, right = a[sort], b[sort]
            if (left ~= nil) ~= (right ~= nil) then return left ~= nil end
            if left ~= right then return left > right end
        end
        if a.name:lower() ~= b.name:lower() then return a.name:lower() < b.name:lower() end
        if a.realm ~= b.realm then return a.realm < b.realm end
        return a.guid < b.guid
    end)
    return rows, total, gold, known, limited, true
end
function Dashboard:HideTooltip()
    local tooltip = GameTooltip
    if self.hovered and tooltip and Call(tooltip.IsForbidden, tooltip) == false
        and Call(tooltip.GetOwner, tooltip) == self.hovered
        and (not InCombatLockdown() or Call(tooltip.IsProtected, tooltip) == false) then tooltip:Hide() end
    self.hovered = nil
end
function Dashboard:Tooltip(button)
    if InCombatLockdown() or not button.entry or not GameTooltip or Call(GameTooltip.IsForbidden, GameTooltip) ~= false then return end
    local row = button.entry
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT"); self.hovered = button
    GameTooltip:AddLine(row.name .. (row.current and " (You)" or ""), unpack(teal))
    GameTooltip:AddLine(row.ruleset .. "  ·  " .. row.realm, unpack(muted))
    GameTooltip:AddLine("Level: " .. (row.level or "Not recorded") .. "  ·  " .. ClassName(row.class))
    GameTooltip:AddLine("Level recorded: " .. self:Stamp(row.levelAt), unpack(muted))
    GameTooltip:AddLine("Money: " .. self:Money(row.money)); GameTooltip:AddLine("Money recorded: " .. self:Stamp(row.moneyAt), unpack(muted))
    local rested = row.restedXP
    local restedLabel, restedPercent = RestedLabel(rested)
    GameTooltip:AddLine("Rested XP: " .. restedLabel)
    if rested then
        if restedPercent then GameTooltip:AddLine("Percentage of full levels, starting at the recorded level", unpack(muted)) end
        if rested.estimate then
            GameTooltip:AddLine("Last confirmed: " .. RestedLabel(rested, true), unpack(muted))
            GameTooltip:AddLine("Logged out: " .. self:Stamp(rested.offline.logoutAt), unpack(muted))
            GameTooltip:AddLine((rested.offline.resting and "Rested area" or "Outside a rested area")
                .. " · Well Rested " .. rested.offline.rank .. "/" .. WELL_RESTED_MAX_RANK, unpack(muted))
        end
        GameTooltip:AddLine("Rested XP recorded: " .. self:Stamp(rested.at), unpack(muted))
    end
    if row.professions then
        for _, skill in ipairs(row.professions) do GameTooltip:AddLine(skill.name .. ": " .. skill.rank .. "/" .. skill.maxRank) end
        if #row.professions == 0 then GameTooltip:AddLine("No professions") end
    else GameTooltip:AddLine("Professions not recorded") end
    GameTooltip:AddLine("Professions recorded: " .. self:Stamp(row.professionsAt), unpack(muted))
    GameTooltip:AddLine("Bags recorded: " .. self:Stamp(row.bagsAt), unpack(muted))
    GameTooltip:AddLine("Bank recorded: " .. self:Stamp(row.bankAt), unpack(muted))
    GameTooltip:AddLine(Suite.MailExpiry:Summary(row.mailExpiry, Call(GetServerTime)), unpack(muted))
    if row.mailExpiry then GameTooltip:AddLine("Mailbox checked: " .. self:Stamp(row.mailExpiry.at), unpack(muted)) end
    GameTooltip:AddLine("Recorded information may have changed since this character was played.", unpack(muted))
    GameTooltip:Show()
end
local function Label(parent, size, color, x, y, width)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", size, ""); label:SetTextColor(unpack(color))
    label:SetJustifyH("LEFT"); label:SetWordWrap(false); label:SetWidth(width); label:SetPoint("TOPLEFT", x, y)
    return label
end
function Dashboard:Build(parent)
    if self.panel then return self.panel end
    if InCombatLockdown() then return end
    local root = CreateFrame("Frame", nil, parent); root:SetSize(780, 140)
    self.panel, self.buttons = root, {}
    local panel = CreateFrame("Frame", nil, root); panel:SetPoint("TOPLEFT", 0, -40); panel:SetSize(780, 100)
    self.rosterPanel = panel
    self.viewTabs = {}
    for index, entry in ipairs({ { "characters", "Characters" }, { "inventory", "Inventory" } }) do
        local tab = Suite.Theme:ActionButton(root, entry[2], 384, 28)
        tab:SetPoint("TOPLEFT", (index - 1) * 396, 0); tab:SetSize(384, 28)
        local key = entry[1]; tab:SetScript("OnClick", function() self:SetView(key) end)
        self.viewTabs[key] = tab
    end
    local search = CreateFrame("EditBox", nil, panel, "BackdropTemplate"); self.search = search
    search:SetSize(580, 28); search:SetPoint("TOPLEFT"); search:SetAutoFocus(false); search:SetMaxLetters(100)
    search:SetFont("Fonts\\FRIZQT__.TTF", 11, ""); search:SetTextInsets(8, 8, 0, 0)
    search:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" }); search:SetBackdropColor(0.07, 0.095, 0.11)
    self.placeholder = Label(search, 11, muted, 8, -8, 561); self.placeholder:SetText("Search characters or professions")
    search:SetScript("OnTextChanged", function(box)
        local text = Call(box.GetText, box)
        if not Suite.IsReadable(text) or type(text) ~= "string" or #text > 100 or text:find("[%c|]") then text = "" end
        self.query, self.page = text, 1; self:RefreshView()
    end)
    search:SetScript("OnEscapePressed", function(box) box:SetText(""); box:ClearFocus() end)
    search:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)
    local function Button(x, y, width, text, callback)
        local button = Suite.Theme:ActionButton(panel, text, width, 28, callback)
        button:SetPoint("TOPLEFT", x, y)
        return button
    end
    self.sortButton = Button(596, 0, 184, "Sort: Name", function()
        self.sort = ({ name = "money", money = "level", level = "at", at = "name" })[self.sort] or "name"
        self.page = 1; self:RefreshView()
    end)
    self.summary = Label(panel, 12, white, 0, -40, 780)
    self.coverage = Label(panel, 11, muted, 0, -59, 780)
    Label(panel, 11, muted, 12, -86, 414):SetText("CHARACTER · CLICK TO SELECT")
    local levelHeading = Label(panel, 11, muted, 442, -86, 48); levelHeading:SetJustifyH("CENTER"); levelHeading:SetText("LEVEL")
    local restedHeading = Label(panel, 11, muted, 510, -86, 128); restedHeading:SetJustifyH("RIGHT"); restedHeading:SetText("RESTED XP")
    local goldHeading = Label(panel, 11, muted, 645, -86, 123); goldHeading:SetJustifyH("RIGHT"); goldHeading:SetText("GOLD")
    self.empty = Label(panel, 12, muted, 0, -115, 780); self.empty:SetWordWrap(true); self.empty:SetHeight(40)
    for index = 1, PAGE_SIZE do
        local row = CreateFrame("Button", nil, panel, "BackdropTemplate"); self.buttons[index] = row
        Suite.Theme:ButtonFeedback(row)
        row:SetSize(780, 52); row:SetPoint("TOPLEFT", 0, -108 - (index - 1) * 56)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" }); row:SetBackdropColor(0.07, 0.095, 0.11)
        row.accent = row:CreateTexture(nil, "ARTWORK"); row.accent:SetPoint("TOPLEFT", 0, -5)
        row.accent:SetSize(3, 42)
        row.name = Label(row, 14, teal, 12, -8, 414)
        row.level = Label(row, 14, white, 442, -18, 48); row.level:SetJustifyH("CENTER")
        row.restedXP = Label(row, 12, white, 510, -8, 128); row.restedXP:SetJustifyH("RIGHT")
        row.restedAt = Label(row, 10, muted, 510, -30, 128); row.restedAt:SetJustifyH("RIGHT")
        row.money = Label(row, 12, white, 645, -19, 123); row.money:SetJustifyH("RIGHT")
        row.context = Label(row, 11, muted, 12, -30, 414)
        row:SetScript("OnClick", function()
            if row.entry then self.selected = row.entry.guid; self:RefreshView() end
        end)
        row:SetScript("OnEnter", function() self:Tooltip(row) end)
        row:SetScript("OnLeave", function() if self.hovered == row then self:HideTooltip() end end)
        row:SetScript("OnHide", function() if self.hovered == row then self:HideTooltip() end end)
    end
    self.details = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    self.details:SetSize(780, 100); self.details:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    self.details:SetBackdropColor(0.07, 0.095, 0.11)
    self.detailTitle = Label(self.details, 14, white, 12, -12, 756)
    self.detailContext = Label(self.details, 11, muted, 12, -35, 756)
    self.skills = {}
    for index = 1, 7 do
        local x, y = 12 + ((index - 1) % 2) * 383, -64 - math.floor((index - 1) / 2) * 26
        self.skills[index] = { name = Label(self.details, 12, white, x, y, 288),
            rank = Label(self.details, 12, teal, x + 294, y, 78) }
        self.skills[index].rank:SetJustifyH("RIGHT")
    end
    self.freshness = Label(self.details, 10, muted, 12, -56, 756)
    self.mailStatus = Label(self.details, 10, muted, 12, -108, 756)
    self.bankBrowseButton = Button(0, 0, 372, "Open saved bank", function() if self.selected then Suite.OfflineBank:OpenFor(self.selected, 0, Suite.GUI.frame) end end)
    self.bankBrowseButton:SetParent(self.details); self.bankBrowseButton:ClearAllPoints(); self.bankBrowseButton:SetPoint("TOPLEFT", 12, -80)
    for index, labels in ipairs(self.skills) do
        local x, y = 12 + ((index - 1) % 2) * 383, -122 - math.floor((index - 1) / 2) * 26
        labels.name:ClearAllPoints(); labels.name:SetPoint("TOPLEFT", x, y)
        labels.rank:ClearAllPoints(); labels.rank:SetPoint("TOPLEFT", x + 294, y)
    end
    self.skillEmpty = Label(self.details, 12, muted, 12, -122, 756)
    self.previous = Button(0, -100, 85, "Previous", function() self.page = math.max(1, self.page - 1); self:RefreshView() end)
    self.next = Button(695, -100, 85, "Next", function() self.page = self.page + 1; self:RefreshView() end)
    self.wheelArea = Suite.Theme:PageWheel(panel, self.buttons, self.previous, self.next)
    self.pageLabel = Label(panel, 11, muted, 100, -108, 580); self.pageLabel:SetJustifyH("CENTER")
    panel:SetScript("OnHide", function() self:HideTooltip(); search:ClearFocus() end)
    self:Render(); return root
end
function Dashboard:SetView(view)
    if not Suite.IsReadable(view) or (view ~= "characters" and view ~= "inventory") then return end
    if InCombatLockdown() then
        Suite.pending.dashboardView = function()
            if Suite.GUI.page == "characters" and Suite.GUI.frame:IsShown() then self:SetView(view) end
        end
        return
    end
    self.view = view
    self:RefreshView()
end
function Dashboard:Render()
    if not self.panel or InCombatLockdown() then return end
    self:HideTooltip()
    local inventory = self.view == "inventory"
    for key, tab in pairs(self.viewTabs) do tab:SetBackdropColor(unpack((key == "inventory") == inventory and { 0.1, 0.2, 0.21 } or { 0.07, 0.095, 0.11 })) end
    self.rosterPanel:SetShown(not inventory)
    if inventory then Suite.CharacterBrowser:Build(self.panel) end
    local browser = Suite.CharacterBrowser
    if browser.panel then browser.panel:SetShown(inventory) end
    browser:SetVisible(inventory and Suite.GUI.frame and Suite.GUI.frame:IsShown() == true or false)
    if inventory then browser:Refresh(); self.panel:SetHeight(40 + browser.panel:GetHeight()); return end
    local rows, total, gold, known, limited, scoped = self:Rows(self.query, self.sort)
    self.rows = rows
    local pages = math.max(1, math.ceil(#rows / PAGE_SIZE)); self.page = math.max(1, math.min(pages, self.page))
    local count = math.min(PAGE_SIZE, #rows - (self.page - 1) * PAGE_SIZE)
    local bottom = 108 + math.max(count, 1) * 56
    self.placeholder:SetShown(self.query == "")
    self.sortButton.label:SetText("Sort: " .. ({ name = "Name", money = "Gold", level = "Level", at = "Updated" })[self.sort])
    self.summary:SetText("Recorded gold: " .. self:Money(known > 0 and gold or nil))
    self.coverage:SetText(#rows .. "/" .. total .. " characters  ·  Gold recorded for " .. known .. "/" .. total
        .. (limited and "  ·  List limit reached" or ""))
    local selected
    for index = 1, count do
        local row = rows[(self.page - 1) * PAGE_SIZE + index]
        if row.guid == self.selected then selected = row end
    end
    selected = selected or rows[(self.page - 1) * PAGE_SIZE + 1]
    self.selected = selected and selected.guid or nil
    for index, button in ipairs(self.buttons) do
        local row = rows[(self.page - 1) * PAGE_SIZE + index]; button.entry = row
        if row then
            button.name:SetText(row.name .. (row.current and " (You)" or "")); button.money:SetText(self:Money(row.money))
            button.level:SetText(row.level or "—")
            button.restedXP:SetText((RestedLabel(row.restedXP)))
            button.restedAt:SetText(row.restedXP and (row.restedXP.estimate and "Offline estimate" or self:Stamp(row.restedXP.at)) or "")
            button.context:SetText(ClassName(row.class) .. "  ·  " .. row.ruleset)
            button.name:SetTextColor(ClassColor(row.class)); button.accent:SetColorTexture(ClassColor(row.class))
            if row.guid == self.selected then button:SetBackdropColor(0.1, 0.2, 0.21)
            else button:SetBackdropColor(0.07, 0.095, 0.11) end
        end
        button:SetShown(row ~= nil)
    end
    self.empty:SetText(not scoped and "Character region unavailable." or total == 0
        and "No character records yet. Enable recording and log into your characters." or "No matching characters.")
    self.empty:SetShown(count == 0)
    self.previous:ClearAllPoints(); self.previous:SetPoint("TOPLEFT", 0, -bottom)
    self.next:ClearAllPoints(); self.next:SetPoint("TOPLEFT", 695, -bottom)
    self.pageLabel:ClearAllPoints(); self.pageLabel:SetPoint("TOPLEFT", 100, -bottom - 8)
    self.pageLabel:SetText(self.page .. " / " .. pages)
    self.previous:SetEnabled(self.page > 1); self.next:SetEnabled(self.page < pages)
    self.previous:SetShown(pages > 1); self.next:SetShown(pages > 1); self.pageLabel:SetShown(pages > 1)
    self.details:ClearAllPoints(); self.details:SetPoint("TOPLEFT", 0, -bottom - (pages > 1 and 38 or 8))
    self.details:SetShown(selected ~= nil)
    local skills = selected and selected.professions
    local skillCount = skills and #skills or 0
    local detailHeight = 122 + math.max(1, math.ceil(skillCount / 2)) * 26 + 10
    self.details:SetHeight(detailHeight)
    if selected then
        self.detailTitle:SetText(selected.name .. " · Professions")
        self.detailContext:SetText(selected.realm .. "  ·  " .. selected.ruleset)
        self.mailStatus:SetText(Suite.MailExpiry:Summary(selected.mailExpiry, Call(GetServerTime))
            .. (selected.mailExpiry and " · Checked " .. self:Stamp(selected.mailExpiry.at) or ""))
        self.freshness:SetText("Bags: " .. Suite.CharacterBrowser:Age(selected.bagsAt, selected.bagsAt ~= nil)
            .. "  ·  Bank: " .. Suite.CharacterBrowser:Age(selected.bankAt, selected.bankAt ~= nil))
        local available = Suite.OfflineBank:GetSnapshot(0, selected.guid) ~= nil
        self.bankBrowseButton:SetEnabled(available)
        self.bankBrowseButton.label:SetText(available and "Open saved bank" or "No bank view recorded")
        self.bankBrowseButton.label:SetTextColor(unpack(available and teal or muted))
        self.skillEmpty:SetText(skills and "No professions" or "Professions not recorded")
    end
    self.skillEmpty:SetShown(skillCount == 0)
    for index, labels in ipairs(self.skills) do
        local skill = skills and skills[index]
        labels.name:SetShown(skill ~= nil); labels.rank:SetShown(skill ~= nil)
        if skill then labels.name:SetText(skill.name); labels.rank:SetText(skill.rank .. "/" .. skill.maxRank) end
    end
    local height = bottom + (pages > 1 and 38 or 8) + (selected and detailHeight or 0)
    self.rosterPanel:SetHeight(height); self.panel:SetHeight(40 + height)
end
function Dashboard:RefreshView()
    local gui = Suite.GUI
    if not self.panel or not gui or gui.page ~= "characters" or not gui.frame or Call(gui.frame.IsShown, gui.frame) ~= true then return end
    if InCombatLockdown() then
        Suite.pending.dashboardView = function() self:RefreshView() end; return
    end
    self:Render(); gui:LayoutPage("characters"); gui:ScrollTo(gui.scrollOffset or 0)
end
function Dashboard:Cancel() if self.timer then self.timer:Cancel(); self.timer = nil end end
function Dashboard:Schedule()
    if not self:Enabled() or self.timer or self.shuttingDown then return end
    if InCombatLockdown() then Suite.pending.dashboardCapture = function() self:Schedule() end; return end
    if C_Timer and C_Timer.NewTimer then self.timer = C_Timer.NewTimer(0.15, function() self.timer = nil; self:Capture() end) end
end
function Dashboard:OnEvent(event)
    if not self:Enabled() then return end
    if event == "PLAYER_LOGOUT" then
        -- Preserve the last in-world profile, including money shared with BagMoney.
        -- Player APIs may already return empty/zero values during teardown.
        self.shuttingDown = true; self:Cancel(); Suite.pending.dashboardCapture = nil
        local candidate, at = self.restedLogout, At(Call(GetServerTime))
        if candidate and at and at >= candidate.snapshot.at then
            candidate.snapshot.offline = { logoutAt = at, xpMax = candidate.xpMax,
                resting = candidate.resting, rank = candidate.rank }
        end
        self.restedLogout = nil
    else
        -- Required inputs may have changed while the capture is queued or deferred in combat.
        if event ~= "PLAYER_MONEY" and event ~= "SKILL_LINES_CHANGED" and event ~= "TRADE_SKILL_LIST_UPDATE" then
            self.restedLogout = nil
        end
        self:Schedule()
    end
end
function Dashboard:Apply()
    if not self:Enabled() then
        self:Cancel(); Suite.pending.dashboardEnable, Suite.pending.dashboardCapture = nil, nil
        if self.events then self.events:UnregisterAllEvents() end
        self.active, self.restedLogout = nil, nil; self:RefreshView(); return
    end
    Suite.AfterCombat("dashboardEnable", function()
        if not self:Enabled() or self.active then return end
        if not self.events then self.events = CreateFrame("Frame"); self.events:SetScript("OnEvent", function(_, event) self:OnEvent(event) end) end
        self.active, self.shuttingDown = true, nil
        for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_MONEY", "PLAYER_LEVEL_UP", "PLAYER_XP_UPDATE",
            "UPDATE_EXHAUSTION", "PLAYER_UPDATE_RESTING", "TRAIT_CONFIG_UPDATED", "TRAIT_NODE_CHANGED",
            "TRAIT_NODE_CHANGED_PARTIAL", "TRAIT_CONFIG_LIST_UPDATED", "TRAIT_TREE_CHANGED",
            "SKILL_LINES_CHANGED", "TRADE_SKILL_LIST_UPDATE", "PLAYER_LOGOUT" }) do
            local valid = true
            if Table(C_EventUtils) and type(C_EventUtils.IsEventValid) == "function" then valid = Call(C_EventUtils.IsEventValid, event) == true end
            if valid then pcall(self.events.RegisterEvent, self.events, event) end
        end
        self:Capture()
    end)
end
