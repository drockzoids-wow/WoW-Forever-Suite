local _, Suite = ...
local Mail = { rows = {}, page = 1, sort = "name", ascending = true }
Suite.Mail = Mail
table.insert(Suite.modules, Mail)

local CONTACT_ROWS, GROUP_ROWS = 8, 8
local BOOK_WIDTH, BOOK_HEIGHT = 740, 650
local colors = {
    background = { 0.035, 0.05, 0.065 }, row = { 0.07, 0.095, 0.11 },
    accent = { 0.41, 0.84, 0.75 }, text = { 0.88, 0.91, 0.93 }, muted = { 0.55, 0.65, 0.7 },
}

local function Number(value, minimum, maximum)
    return Suite.IsReadable(value) and type(value) == "number" and value == value
        and value >= minimum and value <= maximum and math.abs(value) < math.huge
end

local function Region()
    local value = GetCurrentRegion and GetCurrentRegion()
    if Number(value, 1, math.huge) and value == math.floor(value) then return value end
end

local function String(value, maximum)
    return Suite.IsReadable(value) and type(value) == "string" and #value > 0 and #value <= maximum
        and not value:find("[%z\1-\31\127|]")
end

-- Notes permit line breaks, but retain the plain-text/size restrictions used
-- throughout contact storage, migration and search.
local function Notes(value)
    if not Suite.IsReadable(value) or type(value) ~= "string" then return end
    value = value:gsub("\r\n", "\n"):gsub("\r", "\n")
    if String(value:gsub("\n", " "), 240) then return value end
end

local function RulesetFromServer(value)
    if not String(value, 64) then return end
    value = value:gsub("%s", ""):lower()
    -- These are server labels, not delivery addresses. Unknown labels stay unknown.
    value = value:match("^camwow[a-z]+%d+realm%d+(.+)$") or value
    value = value:match("^classicbeta(.+)$") or value:match("^classic(.+)$") or value:match("^forever(.+)$") or value
    return ({ pve = "PvE", pvp = "PvP", hardcore = "Hardcore", rp = "RP",
        rppvp = "RP-PvP", rppve = "RP-PvE", ["rp-pvp"] = "RP-PvP", ["rp-pve"] = "RP-PvE" })[value]
end

local function Ruleset()
    if C_GameRules and type(C_GameRules.IsHardcoreActive) == "function" then
        local active = C_GameRules.IsHardcoreActive()
        if Suite.IsReadable(active) and active == true then return "Hardcore" end
    end
    return RulesetFromServer(GetNormalizedRealmName and GetNormalizedRealmName())
        or RulesetFromServer(GetRealmName and GetRealmName())
end

local function Name(value, allowIncomplete)
    if not String(value, 77) then return end
    value = value:match("^%s*(.-)%s*$"):gsub(" +", " ")
    local first, surname = value:match("^(%S+) (%S+)$")
    if not first and allowIncomplete then first = value end
    if not first or not String(first, 48) or first:find("[%s%d%p]") then return end
    if surname and (not String(surname, 48) or surname:find("[%s%d%p]")) then return end
    return value, surname ~= nil
end

function Mail:CurrentRuleset() return Ruleset() end

local function Parse(value)
    return Name(value)
end

local function ValidRuleset(value)
    return String(value, 64) and value or nil
end

-- Shared with inventory selectors so server labels and unknown scopes follow
-- the same policy as the Contact Book without reading or changing contacts.
function Mail:RecordedRuleset(character)
    if not Suite.IsReadable(character) or type(character) ~= "table" then return end
    return RulesetFromServer(character.realm) or ValidRuleset(character.ruleset)
end

local function Key(region, name, ruleset, guid)
    if guid then return tostring(region) .. ":guid:" .. guid end
    return tostring(region) .. ":name:" .. (ruleset or "?"):lower() .. ":" .. name:lower()
end

local function ContactReference(entry)
    return Key(Region(), entry.name, entry.ruleset)
end

local function Entry(name, ruleset, region, guid, class, level, faction, allowIncomplete)
    name = Name(name, allowIncomplete)
    if not name or not Number(region, 1, math.huge) or region ~= math.floor(region) then return end
    guid = String(guid, 128) and guid or nil
    local entry = { name = name, ruleset = ValidRuleset(ruleset), region = region, guid = guid,
        class = String(class, 32) and class or nil,
        level = Number(level, 1, 1000) and level == math.floor(level) and level or nil,
        faction = String(faction, 32) and faction or nil }
    return entry, Key(region, name, entry.ruleset, guid)
end

local function ClassFromID(id)
    if not Number(id, 1, 1000) or id ~= math.floor(id) or not C_CreatureInfo
        or type(C_CreatureInfo.GetClassInfo) ~= "function" then return end
    local ok, info = pcall(C_CreatureInfo.GetClassInfo, id)
    if ok and Suite.IsReadable(info) and type(info) == "table" and String(info.classFile, 32) then
        return info.classFile
    end
end

local function Accessible(frame)
    if not Suite.IsReadable(frame) or not frame then return false end
    if InCombatLockdown() and not frame.IsProtected then return false end
    if frame.IsForbidden then
        local value = frame:IsForbidden()
        if not Suite.IsReadable(value) or value ~= false then return false end
    end
    if frame.IsProtected then
        local value = frame:IsProtected()
        if not Suite.IsReadable(value) or value ~= false then return false end
    end
    return true
end

local function Shown(frame)
    if not Accessible(frame) or not frame.IsShown then return false end
    local value = frame:IsShown()
    return Suite.IsReadable(value) and value == true
end

local function Field()
    local field = SendMailNameEditBox
    if Accessible(field) and field.GetText and field.SetText then return field end
end

local function Text(parent, size, color)
    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", size, "")
    text:SetTextColor(unpack(color or colors.text))
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    return text
end

local function Fill(frame, color)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(unpack(color or colors.row))
    Suite.Theme:Backdrop(frame, 1)
end

local function Button(parent, width, label, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    Suite.Theme:ButtonFeedback(button)
    button:SetSize(width, 24)
    Fill(button)
    button.label = Text(button, 10, colors.accent)
    button.label:SetPoint("CENTER")
    button.label:SetText(label)
    button:SetScript("OnClick", function() if not InCombatLockdown() then callback() end end)
    button:SetScript("OnEnter", function() button:SetBackdropColor(0.1, 0.2, 0.21) end)
    button:SetScript("OnLeave", function() Fill(button) end)
    return button
end

function Mail:Database()
    local db = Suite.db.mailContacts
    if Suite.IsReadable(db) and type(db) == "table" and Suite.IsReadable(db.schema) and db.schema == 1 then
        local migrated = { schema = 2, entries = {}, removed = {}, preserved = db }
        if Suite.IsReadable(db.entries) and type(db.entries) == "table" then
            for _, old in pairs(db.entries) do
                if Suite.IsReadable(old) and type(old) == "table" then
                    local entry, key = Entry(old.name, RulesetFromServer(old.realm), old.region,
                        old.guid, old.class, old.level, old.faction, true)
                    if key then
                        entry.category = String(old.category, 32) and old.category or nil
                        entry.notes = Notes(old.notes)
                        migrated.entries[key] = entry
                    end
                end
            end
        end
        if Suite.IsReadable(db.removed) and type(db.removed) == "table" then
            for oldKey, removed in pairs(db.removed) do
                if String(oldKey, 200) and Suite.IsReadable(removed) and removed == true then
                    local region, name, server = oldKey:match("^(%d+):([^-]+)%-(.+)$")
                    local _, key = Entry(name, RulesetFromServer(server), tonumber(region), nil, nil, nil, nil, true)
                    if key then migrated.removed[key] = true end
                end
            end
        end
        db = migrated; Suite.db.mailContacts = db
    elseif not Suite.IsReadable(db) or type(db) ~= "table" or not Suite.IsReadable(db.schema) or db.schema ~= 2 then
        -- Keep an unfamiliar readable book intact rather than discarding saved names.
        local preserved = Suite.IsReadable(db) and type(db) == "table" and db or nil
        db = { schema = 2, entries = {}, removed = {}, preserved = preserved }; Suite.db.mailContacts = db
    end
    if not Suite.IsReadable(db.entries) or type(db.entries) ~= "table" then db.entries = {} end
    if not Suite.IsReadable(db.removed) or type(db.removed) ~= "table" then db.removed = {} end
    self.removed = db.removed
    return db.entries
end

function Mail:Store(name, ruleset, region, guid, class, level, faction, allowIncomplete)
    local entry, key = Entry(name, ruleset, region, guid, class, level, faction, allowIncomplete)
    if not key then return end
    if not entry.class then
        for _, member in pairs(self.guildEntries or {}) do
            if member.region == region and member.ruleset == entry.ruleset and member.name:lower() == entry.name:lower() then
                entry.class = String(member.class, 32) and member.class or nil
                break
            end
        end
    end
    local entries = self:Database()
    local manualKey = Key(region, entry.name, entry.ruleset)
    if not entry.guid then
        local matching
        for existingKey, existing in pairs(entries) do
            if String(existingKey, 240) and Suite.IsReadable(existing) and type(existing) == "table" then
                local candidate, candidateKey = Entry(existing.name, existing.ruleset, existing.region, existing.guid,
                    existing.class, existing.level, existing.faction, true)
                if candidate and existingKey == candidateKey and candidate.region == region
                    and candidate.name:lower() == entry.name:lower() and candidate.ruleset == entry.ruleset then
                    if matching then matching = nil; break end
                    matching = candidate
                end
            end
        end
        if matching then entry.guid = matching.guid; key = Key(region, entry.name, entry.ruleset, entry.guid) end
    end
    local old = entries[key]
    if entry.guid and not (Suite.IsReadable(old) and type(old) == "table") then old = entries[manualKey] end
    if Suite.IsReadable(old) and type(old) == "table" then
        -- A temporary unreadable surname must not replace a completed player identity.
        local oldName, complete = Name(old.name, true)
        local _, newComplete = Name(entry.name, true)
        if oldName and complete and not newComplete then entry.name = oldName end
        entry.class = entry.class or (String(old.class, 32) and old.class or nil)
        entry.level = entry.level or (Number(old.level, 1, 1000) and old.level == math.floor(old.level) and old.level or nil)
        entry.faction = entry.faction or (String(old.faction, 32) and old.faction or nil)
        entry.category = String(old.category, 32) and old.category or nil
        entry.groupCategory = String(old.groupCategory, 32) and old.groupCategory or nil
        entry.notes = Notes(old.notes)
    end
    entries[key] = entry
    if entry.guid then entries[manualKey] = nil end
    return key
end

function Mail:RecordPlayer(level)
    if not Suite.db.mailHelper then return end
    local name, surname
    if UnitName then name, surname = UnitName("player") end
    if String(name, 77) and not Name(name) and String(surname, 48) then name = name .. " " .. surname end
    local guid = UnitGUID and UnitGUID("player")
    if not String(guid, 128) then return end
    local _, class
    if UnitClass then _, class = UnitClass("player") end
    self.currentGUID = guid
    self.currentName, self.currentRuleset = nil, nil
    if not Number(level, 1, 1000) or level ~= math.floor(level) then level = UnitLevel and UnitLevel("player") end
    local key = self:Store(name, Ruleset(), Region(), guid, class, level,
        UnitFactionGroup and UnitFactionGroup("player"), true)
    if key then
        self.removed[key] = nil
        local entry = self:Database()[key]
        self.currentName, self.currentRuleset = entry.name, entry.ruleset
    end
end

function Mail:IsCurrent(entry)
    if entry.guid then return String(self.currentGUID, 128) and entry.guid == self.currentGUID or false end
    return Name(self.currentName) and entry.name:lower() == self.currentName:lower()
        and (not entry.ruleset or not self.currentRuleset or entry.ruleset == self.currentRuleset) or false
end

function Mail:SeedRecordedCharacters()
    local inventory = Suite.db.inventory
    local entries = Suite.IsReadable(inventory) and type(inventory) == "table" and inventory.characters
    local region = Region()
    if not region or not Suite.IsReadable(entries) or type(entries) ~= "table" then return end
    for guid, entry in pairs(entries) do
        if String(guid, 128) and Suite.IsReadable(entry) and type(entry) == "table"
            and Suite.IsReadable(entry.region) and entry.region == region then
            local name = Name(entry.fullName) or Name(entry.name, true)
            local ruleset = self:RecordedRuleset(entry)
            -- Seed once; removed contacts stay removed until that character is logged in again.
            local contacts = self:Database()
            local key = name and Key(region, name, ruleset, guid)
            local removed = key and self.removed[key]
            local oldRemoved = name and self.removed[Key(region, name, ruleset)]
            local existing = key and contacts[key]
            if key and Suite.IsReadable(existing) and Suite.IsReadable(removed) and removed ~= true
                and Suite.IsReadable(oldRemoved) and oldRemoved ~= true then
                if existing == nil then
                    self:Store(name, ruleset, region, guid, entry.class, nil, nil, true)
                elseif type(existing) == "table" and ruleset and not ValidRuleset(existing.ruleset) then
                    -- Repair previously unknown server labels without replacing edited contact names/metadata.
                    local restoredName = existing.name
                    local first = Name(existing.name, true)
                    if first and not Name(first) and Name(name) and name:match("^(%S+)"):lower() == first:lower() then
                        restoredName = name
                    end
                    self:Store(restoredName, ruleset, region, guid, existing.class, existing.level, existing.faction, true)
                end
            end
        end
    end
end

local AUTOCOMPLETE_LIMIT = 32

local function AccountName(first, accountFlag, bnetFlag, sameRealmPriority)
    local ok, results = pcall(C_AutoComplete.GetAutoCompleteResults,
        first, AUTOCOMPLETE_LIMIT, #first, true, accountFlag, bnetFlag)
    if not ok or not Suite.IsReadable(results) or type(results) ~= "table" then return end
    local count, candidate = 0, nil
    for index, result in pairs(results) do
        if not Number(index, 1, AUTOCOMPLETE_LIMIT) or index ~= math.floor(index)
            or not Suite.IsReadable(result) or type(result) ~= "table"
            or not String(result.name, 77) or not Number(result.priority, 0, 1000)
            or not Number(result.bnetID, 0, math.huge) then return end
        count = count + 1
        local name = Name(result.name)
        if result.priority == sameRealmPriority and result.bnetID == 0 then
            if not name then return end
            if name:match("^(%S+)"):lower() == first:lower() then
                if candidate and candidate:lower() ~= name:lower() then return end
                candidate = name
            end
        end
    end
    -- A full response may be truncated; holes or restricted records also cannot prove uniqueness.
    if count >= AUTOCOMPLETE_LIMIT then return end
    for index = 1, count do
        if not Suite.IsReadable(results[index]) or type(results[index]) ~= "table" then return end
    end
    return candidate
end

function Mail:ResolveRecordedNames()
    if InCombatLockdown() or not self.active or not Suite.db.mailHelper
        or not C_AutoComplete or type(C_AutoComplete.GetAutoCompleteResults) ~= "function" then return end
    local flags = Enum and Enum.AutoCompleteEntryFlag
    local priorities = Enum and Enum.AutoCompletePriority
    if not Suite.IsReadable(flags) or type(flags) ~= "table" or not Suite.IsReadable(priorities) or type(priorities) ~= "table" then return end
    local accountFlag, bnetFlag, sameRealmPriority = flags.AccountCharacter, flags.Bnet, priorities.AccountCharacterSameRealm
    if not Number(accountFlag, 1, 65536) or accountFlag ~= math.floor(accountFlag)
        or not Number(bnetFlag, 1, 65536) or bnetFlag ~= math.floor(bnetFlag)
        or not Number(sameRealmPriority, 0, 1000) or sameRealmPriority ~= math.floor(sameRealmPriority) then return end
    local region, ruleset = Region(), Ruleset()
    if not region or not ruleset then return end
    local entries, recorded, incomplete = self:Database(), {}, {}
    for key, saved in pairs(entries) do
        if String(key, 240) and Suite.IsReadable(saved) and type(saved) == "table" then
            local entry, expectedKey = Entry(saved.name, saved.ruleset, saved.region, saved.guid,
                saved.class, saved.level, saved.faction, true)
            if entry and key == expectedKey and entry.region == region then
                recorded[#recorded + 1] = entry
                if entry.guid and entry.guid ~= self.currentGUID and entry.ruleset == ruleset and not Name(entry.name) then
                    incomplete[#incomplete + 1] = { key = key, entry = entry }
                end
            end
        end
    end
    self.nameAttempts = self.nameAttempts or {}
    for _, contact in ipairs(incomplete) do
        local entry, unique = contact.entry, true
        for _, other in ipairs(recorded) do
            if other.guid ~= entry.guid and other.ruleset == ruleset and other.name:lower() == entry.name:lower() then unique = false; break end
        end
        if unique and not self.nameAttempts[contact.key] then
            self.nameAttempts[contact.key] = true
            local name = AccountName(entry.name, accountFlag, bnetFlag, sameRealmPriority)
            if name then
                for _, other in ipairs(recorded) do
                    if other.guid ~= entry.guid and other.ruleset == ruleset and other.name:lower() == name:lower() then name = nil; break end
                end
            end
            if name then self:Store(name, entry.ruleset, region, entry.guid, entry.class, entry.level, entry.faction) end
        end
    end
end

function Mail:List(includeCurrent, search, category, unassigned)
    local result, region, ruleset = {}, Region(), Ruleset()
    if not region or not ruleset then return result end
    local query = search
    if query == nil then query = self.query end
    query = Suite.IsReadable(query) and type(query) == "string" and query:lower() or ""
    for key, entry in pairs(self:Database()) do
        if Suite.IsReadable(key) and type(key) == "string" and Suite.IsReadable(entry) and type(entry) == "table"
            and Suite.IsReadable(entry.region) and entry.region == region then
            local normalized, expectedKey = Entry(entry.name, entry.ruleset, entry.region, entry.guid,
                entry.class, entry.level, entry.faction, true)
            local address, complete
            if normalized then address, complete = Name(normalized.name, true) end
            local current = normalized and self:IsCurrent(normalized)
            local inScope = normalized and (unassigned and normalized.ruleset == nil
                or not unassigned and normalized.ruleset == ruleset)
            if inScope and key == expectedKey and (includeCurrent or not current)
                and (not category or String(entry.category, 32) and entry.category == category)
                and (normalized.name .. " " .. (normalized.ruleset or "Unknown") .. " "
                    .. (String(entry.category, 32) and entry.category or "") .. " "
                    .. (Notes(entry.notes) or "")):lower():find(query, 1, true) then
                result[#result + 1] = { key = key, name = normalized.name, ruleset = normalized.ruleset,
                    address = complete and address or nil, incomplete = not complete,
                    class = normalized.class, faction = normalized.faction, level = normalized.level,
                    current = current, category = String(entry.category, 32) and entry.category or nil,
                    notes = Notes(entry.notes) }
            end
        end
    end
    table.sort(result, function(a, b)
        local left, right
        if self.sort == "level" then left, right = a.level or 0, b.level or 0
        elseif self.sort == "ruleset" then left, right = (a.ruleset or "Unknown"):lower(), (b.ruleset or "Unknown"):lower()
        else left, right = a.name:lower(), b.name:lower() end
        if left == right then
            if a.name:lower() ~= b.name:lower() then return a.name:lower() < b.name:lower() end
            return a.key < b.key
        end
        if self.ascending then return left < right else return left > right end
    end)
    return result
end

-- Guild membership is session-only; roster updates never create saved account identities.
function Mail:ReadGuild()
    self.guildEntries = {}
    if InCombatLockdown() or not (Suite.db.mailHelper or self.book and Shown(self.book.frame)) or not C_Club
        or type(C_Club.GetGuildClubId) ~= "function" or type(C_Club.GetClubMembers) ~= "function"
        or type(C_Club.GetMemberInfo) ~= "function" then return end
    local ok, club = pcall(C_Club.GetGuildClubId)
    if not ok or not Number(club, 1, math.huge) then return end
    local success, members = pcall(C_Club.GetClubMembers, club)
    if not success or not Suite.IsReadable(members) or type(members) ~= "table" then return end
    local region, ruleset = Region(), Ruleset()
    if not region or not ruleset then return end
    for index, id in pairs(members) do
        if Number(index, 1, 10000) and index == math.floor(index)
            and (Number(id, 1, math.huge) or String(id, 128)) then
            local loaded, info = pcall(C_Club.GetMemberInfo, club, id)
            if loaded and Suite.IsReadable(info) and type(info) == "table"
                and Suite.IsReadable(info.isSelf) and info.isSelf == false then
                local entry, key = Entry(info.name, ruleset, region, info.guid, ClassFromID(info.classID), info.level, nil, true)
                if entry and not self:IsCurrent(entry) then self.guildEntries[key] = entry end
            end
        end
    end
    -- Retain observed classes for saved recipients, including after guild departure.
    local classes = {}
    for _, member in pairs(self.guildEntries) do
        if member.class then classes[member.name:lower()] = member.class end
    end
    local entries = self:Database()
    for _, saved in ipairs(self:List(true, "")) do
        local class = classes[saved.name:lower()]
        if class then entries[saved.key].class = class end
    end
end

-- Group definitions contain references, never copies of contacts or guild rosters.
function Mail:GroupSettings()
    self:Database()
    local db = Suite.db.mailContacts
    if not Suite.IsReadable(db.groups) or type(db.groups) ~= "table" then db.groups = {} end
    local settings = db.groups
    for _, key in ipairs({ "custom", "order", "hidden", "categoryAliases" }) do
        if not Suite.IsReadable(settings[key]) or type(settings[key]) ~= "table" then settings[key] = {} end
    end
    if not InCombatLockdown() then
        if not Number(settings.nextID, 1, 1000000000) then
            settings.nextID = 1
            for id in pairs(settings.custom) do
                local number = String(id, 80) and tonumber(id:match("^custom:(%d+)$"))
                if Number(number, 1, 999999999) then settings.nextID = math.max(settings.nextID, number + 1) end
            end
        end
        -- Adopt old category assignments across every scope, once per recorded
        -- assignment. Keep legacy metadata for recovery and old saved references.
        local byName, ids = {}, {}
        for id, group in pairs(settings.custom) do
            if String(id, 80) and id:match("^custom:%d+$") and Suite.IsReadable(group) and type(group) == "table"
                and String(group.name, 32) then ids[#ids + 1] = id end
        end
        table.sort(ids)
        local redirects = {}
        for _, id in ipairs(ids) do
            local name = settings.custom[id].name:match("^%s*(.-)%s*$"):lower()
            local target = byName[name]
            if not target then byName[name] = id
            else
                local kept, duplicate = settings.custom[target], settings.custom[id]
                for _, field in ipairs({ "contacts", "sources" }) do
                    if not Suite.IsReadable(kept[field]) or type(kept[field]) ~= "table" then kept[field] = {} end
                    if Suite.IsReadable(duplicate[field]) and type(duplicate[field]) == "table" then
                        for reference, selected in pairs(duplicate[field]) do
                            if String(reference, 240) and Suite.IsReadable(selected) and selected == true then kept[field][reference] = true end
                        end
                    end
                end
                if Suite.IsReadable(settings.hidden[id]) and settings.hidden[id] == false then settings.hidden[target] = false end
                redirects[id], settings.custom[id] = target, nil
            end
        end
        if next(redirects) then
            for index, id in ipairs(settings.order) do if String(id, 80) and redirects[id] then settings.order[index] = redirects[id] end end
            for name, id in pairs(settings.categoryAliases) do if String(name, 32) and String(id, 80) and redirects[id] then settings.categoryAliases[name] = redirects[id] end end
            for id, group in pairs(settings.custom) do
                if String(id, 80) and Suite.IsReadable(group) and type(group) == "table" and Suite.IsReadable(group.sources) and type(group.sources) == "table" then
                    for old, target in pairs(redirects) do
                        if Suite.IsReadable(group.sources[old]) and group.sources[old] == true then group.sources[target] = true end
                        group.sources[old] = nil
                    end
                    group.sources[id] = nil
                end
            end
        end
        for key, entry in pairs(db.entries) do
            if String(key, 240) and Suite.IsReadable(entry) and type(entry) == "table" and String(entry.category, 32)
                and (not Suite.IsReadable(entry.groupCategory) or entry.groupCategory ~= entry.category) then
                local normalized, expected = Entry(entry.name, entry.ruleset, entry.region, entry.guid, entry.class, entry.level, entry.faction, true)
                local name = entry.category:match("^%s*(.-)%s*$")
                if normalized and key == expected and name ~= "" then
                    local id = byName[name:lower()]
                    if not id then
                        local number = math.floor(settings.nextID)
                        while not Suite.IsReadable(settings.custom["custom:" .. number]) or settings.custom["custom:" .. number] ~= nil do number = number + 1 end
                        id = "custom:" .. number
                        settings.nextID = number + 1
                        settings.custom[id] = { name = name, contacts = {}, sources = {} }
                        settings.hidden[id] = not (Suite.IsReadable(settings.hidden["category:" .. entry.category]) and settings.hidden["category:" .. entry.category] == false)
                        byName[name:lower()] = id
                    end
                    local group = settings.custom[id]
                    if Suite.IsReadable(settings.hidden["category:" .. entry.category]) and settings.hidden["category:" .. entry.category] == false then settings.hidden[id] = false end
                    if not Suite.IsReadable(group.contacts) or type(group.contacts) ~= "table" then group.contacts = {} end
                    group.contacts[Key(normalized.region, normalized.name, normalized.ruleset)] = true
                    settings.categoryAliases[entry.category] = id
                    entry.groupCategory = entry.category
                end
            end
        end
    end
    return settings
end

function Mail:GroupDefinitions()
    local settings = self:GroupSettings()
    local definitions = { alts = { name = "Alts" }, guild = { name = "Guild" }, other = { name = "Other" }, all = { name = "All" } }
    for id, group in pairs(settings.custom) do
        if String(id, 80) and id:match("^custom:%d+$") and Suite.IsReadable(group) and type(group) == "table"
            and String(group.name, 32) then definitions[id] = group end
    end
    for category, id in pairs(settings.categoryAliases) do
        if String(category, 32) and String(id, 80) and definitions[id] then definitions["category:" .. category] = definitions[id] end
    end
    local order, seen = {}, {}
    local function Add(id)
        if String(id, 80) and id:sub(1, 9) == "category:" then id = settings.categoryAliases[id:sub(10)] end
        if String(id, 80) and definitions[id] and not seen[id] then order[#order + 1] = id; seen[id] = true end
    end
    for _, id in ipairs(settings.order) do Add(id) end
    for _, id in ipairs({ "alts", "guild", "other", "all" }) do Add(id) end
    local extra = {}; for id in pairs(definitions) do if not seen[id] and id:sub(1, 9) ~= "category:" then extra[#extra + 1] = id end end
    table.sort(extra, function(a, b) return definitions[a].name == definitions[b].name and a < b or definitions[a].name < definitions[b].name end)
    for _, id in ipairs(extra) do Add(id) end
    return definitions, order
end

function Mail:GroupVisible(id)
    local hidden = self:GroupSettings().hidden[id]
    if Suite.IsReadable(hidden) and type(hidden) == "boolean" then return not hidden end
    return id == "alts" or id == "guild" or id == "other"
end

function Mail:GroupMatches(id, entry, bucket, definitions, visiting)
    if id == "all" or id == bucket then return true end
    local group = definitions[id]
    if not group or visiting[id] then return false end
    if id:sub(1, 9) == "category:" then
        local alias = self:GroupSettings().categoryAliases[id:sub(10)]
        return String(alias, 80) and self:GroupMatches(alias, entry, bucket, definitions, visiting) or false
    end
    if Suite.IsReadable(group.contacts) and type(group.contacts) == "table"
        and Suite.IsReadable(group.contacts[ContactReference(entry)]) and group.contacts[ContactReference(entry)] == true then return true end
    visiting[id] = true
    if Suite.IsReadable(group.sources) and type(group.sources) == "table" then
        for source, enabled in pairs(group.sources) do
            if String(source, 80) and Suite.IsReadable(enabled) and enabled == true
                and self:GroupMatches(source, entry, bucket, definitions, visiting) then visiting[id] = nil; return true end
        end
    end
    visiting[id] = nil
    return false
end

function Mail:SaveGroup(id, name)
    if InCombatLockdown() or not String(name, 32) then return nil end
    if not Suite.IsReadable(id) or id ~= nil and not String(id, 80) then return nil end
    name = name:match("^%s*(.-)%s*$"); if name == "" then return nil end
    local settings = self:GroupSettings()
    for existingID, group in pairs(settings.custom) do
        if String(existingID, 80) and Suite.IsReadable(group) and type(group) == "table" and String(group.name, 32)
            and group.name:match("^%s*(.-)%s*$"):lower() == name:lower() and existingID ~= id then
            if not id then settings.hidden[existingID] = false; self:Refresh(); return existingID end
            return nil
        end
    end
    if id and not self:GroupDefinitions()[id] then return nil end
    if id and not id:match("^custom:%d+$") then return nil end
    if not id then
        local number = math.floor(settings.nextID)
        while not Suite.IsReadable(settings.custom["custom:" .. number]) or settings.custom["custom:" .. number] ~= nil do number = number + 1 end
        id = "custom:" .. number
        settings.nextID = number + 1
        settings.custom[id] = { sources = {}, contacts = {} }; settings.hidden[id] = false
    end
    settings.custom[id].name = name
    self:Refresh()
    return id
end

function Mail:ToggleGroupMember(id, kind, member)
    if InCombatLockdown() or not String(id, 80) or (kind ~= "sources" and kind ~= "contacts") or not String(member, 240) then return false end
    local definitions = self:GroupDefinitions()
    if kind == "sources" and member:sub(1, 9) == "category:" then
        member = self:GroupSettings().categoryAliases[member:sub(10)]
        if not String(member, 80) then return false end
    end
    local group = definitions[id]
    if not group or not id:match("^custom:%d+$") then return false end
    if not Suite.IsReadable(group[kind]) or type(group[kind]) ~= "table" then group[kind] = {} end
    if kind == "contacts" then
        local reference
        for _, entry in ipairs(self:ContactList("all", "", nil, true)) do
            if entry.key == member then reference = ContactReference(entry); break end
        end
        if not reference then return false end
        member = reference
    end
    local enabled = Suite.IsReadable(group[kind][member]) and group[kind][member] == true
    if kind == "sources" and not enabled then
        if not definitions[member] or member == id then return false end
        local function Reaches(source, visited)
            if source == id then return true end
            if visited[source] then return false end
            visited[source] = true
            local value = definitions[source]
            if value and Suite.IsReadable(value.sources) and type(value.sources) == "table" then
                for child, active in pairs(value.sources) do
                    if String(child, 80) and Suite.IsReadable(active) and active == true and Reaches(child, visited) then return true end
                end
            end
            return false
        end
        if Reaches(member, {}) then return false end
    end
    group[kind][member] = not enabled or nil
    self:Refresh()
    return true
end

function Mail:ContactList(tab, search, category, includeCurrent)
    local saved, result, alts, guildNames = self:List(includeCurrent, ""), {}, {}, {}
    local region, ruleset = Region(), Ruleset()
    local group, query = tab or self.contactTab or "alts", (search or self.query or ""):lower()
    for _, entry in ipairs(saved) do
        local old = self:Database()[entry.key]
        if String(old.guid, 128) then alts[old.guid] = true; alts[entry.name:lower()] = true end
    end
    for _, entry in pairs(self.guildEntries or {}) do
        if entry.region == region and entry.ruleset == ruleset then guildNames[entry.name:lower()] = true end
    end
    local seen, definitions = {}, self:GroupDefinitions()
    local function Add(entry, bucket)
        local name = entry.name:lower()
        if not self:GroupMatches(group, entry, bucket, definitions, {}) or seen[name] then return end
        if category and entry.category ~= category then return end
        if not (entry.name .. " " .. (entry.category or "") .. " " .. (entry.notes or "")):lower():find(query, 1, true) then return end
        entry.group = bucket
        seen[name] = true; result[#result + 1] = entry
    end
    for _, entry in ipairs(saved) do
        local old = self:Database()[entry.key]
        Add(entry, String(old.guid, 128) and "alts" or guildNames[entry.name:lower()] and "guild" or "other")
    end
    for key, entry in pairs(self.guildEntries or {}) do
        if entry.region == region and entry.ruleset == ruleset
            and not (entry.guid and alts[entry.guid]) and not alts[entry.name:lower()] then
            local address, complete = Name(entry.name, true)
            Add({ key = "guild:" .. key, name = entry.name, level = entry.level, class = entry.class,
                address = complete and address or nil, incomplete = not complete, ruleset = entry.ruleset,
                roster = true }, "guild")
        end
    end
    table.sort(result, function(a, b)
        local left, right = a.name:lower(), b.name:lower()
        if self.sort == "level" then left, right = a.level or 0, b.level or 0 end
        if left == right then return a.name:lower() < b.name:lower() end
        if self.ascending then return left < right else return left > right end
    end)
    return result
end

function Mail:SelectContactTab(tab)
    if InCombatLockdown() or not self:GroupDefinitions()[tab] then return end
    self.contactTab, self.page, self.selected, self.confirm = tab, 1, nil, nil
    if self.book then
        self.book.tab, self.book.groupFilter, self.book.filter = tab:match("^custom:%d+$") and "all" or tab, tab:match("^custom:%d+$") and tab or nil, nil
        self.book.unassigned, self.book.page, self.book.confirm = false, 1, nil
        self.book.remove.label:SetText("Remove")
    end
    self:Refresh()
end

function Mail:Choose(key)
    if not String(key, 200) or InCombatLockdown() or not Suite.db.mailHelper or not self.visit or self.sendPending
        or not Shown(MailFrame) or not Shown(SendMailFrame) or not Field() or type(MailFrameTab_OnClick) ~= "function" then return end
    if Shown(SendMailFrameLockSendMail) then return end
    if MailFrameTab2 and not Shown(MailFrameTab2) then return end
    local enabled = Field().IsEnabled and Field():IsEnabled()
    if not Suite.IsReadable(enabled) or enabled == false then return end
    local chosen
    for _, entry in ipairs(self:ContactList("all", "")) do if entry.key == key then chosen = entry; break end end
    if not chosen or chosen.current then return end
    self.choosingRecipient = true
    MailFrameTab_OnClick(nil, 2)
    self.choosingRecipient = nil
    local field = Field()
    if not field or not Shown(SendMailFrame) then return end
    field:SetText(chosen.address or (chosen.name .. " "))
    if chosen.incomplete then
        if field.SetFocus then field:SetFocus() end
    else
        if field.ClearFocus then field:ClearFocus() end
        if Accessible(SendMailSubjectEditBox) and SendMailSubjectEditBox.SetFocus then SendMailSubjectEditBox:SetFocus() end
    end
    self.selected, self.confirm = key, nil
    self:Refresh()
    if chosen.incomplete then self:SetNotice("Choose a full name, then save.") end
end

function Mail:SaveRecipient()
    if InCombatLockdown() or not Suite.db.mailHelper or not self.visit or not Shown(MailFrame)
        or not Shown(SendMailFrame) or not self.search then return end
    local field = Field()
    local name = Parse(field and field:GetText())
    if not name then self:SetNotice("Enter first and last name in To."); return end
    local ruleset, region = Ruleset(), Region()
    if not ruleset then self:SetNotice("Server type is not available yet."); return end
    local guid, class, level, faction
    for _, entry in ipairs(self:List()) do
        if entry.key == self.selected and (entry.name:lower() == name:lower()
            or entry.incomplete and name:match("^(%S+)"):lower() == entry.name:lower()) then
            local old = self:Database()[entry.key]
            guid = String(old.guid, 128) and old.guid or nil
            class, level, faction = entry.class, entry.level, entry.faction
            ruleset = entry.ruleset or ruleset
            if entry.incomplete and not guid then self:Database()[entry.key] = nil end
            break
        end
    end
    local key = self:Store(name, ruleset, region, guid, class, level, faction)
    if not key then self:SetNotice("Character details are not available yet."); return end
    self.removed[key] = nil
    self.selected, self.confirm = key, nil
    self.query, self.page = "", 1
    local saved = self:Database()[key]
    self.contactTab = String(saved.guid, 128) and "alts" or "other"
    if self.contactTab == "other" then
        for _, member in pairs(self.guildEntries or {}) do
            if member.name:lower() == name:lower() then self.contactTab = "guild"; break end
        end
    end
    self:SelectContactTab(self.contactTab)
    self.search:SetText("")
    if self.book then
        for _, entry in ipairs(self:ContactList("all", "", nil, true)) do
            if entry.key == key then self:EditContact(entry); break end
        end
    end
    self:Refresh()
    self:SetNotice("Recipient saved.")
end

function Mail:SetNotice(message)
    if self.notice and not InCombatLockdown() then self.notice:SetText(message) end
end

function Mail:ConfirmRemove(key)
    if not String(key, 200) or InCombatLockdown() or not Suite.db.mailHelper or not self.visit then return end
    for _, entry in ipairs(self:List(true)) do if entry.key == key and entry.current then return end end
    self.confirm = key
    self:Refresh()
end

function Mail:RemoveConfirmed()
    if InCombatLockdown() or not Suite.db.mailHelper or not self.visit or not self.confirm then return end
    local key = self.confirm
    local entries = self:Database()
    local old = entries[key]
    if Suite.IsReadable(old) and type(old) == "table" then
        local normalized = Entry(old.name, old.ruleset, old.region, old.guid, old.class, old.level, old.faction, true)
        if normalized then
            local reference = Key(normalized.region, normalized.name, normalized.ruleset)
            self.removed[reference] = true
            for _, group in pairs(self:GroupDefinitions()) do
                if Suite.IsReadable(group.contacts) and type(group.contacts) == "table" then group.contacts[reference] = nil end
            end
        end
    end
    entries[key], self.removed[key] = nil, true
    if self.selected == key then self.selected = nil end
    self.confirm = nil
    self:Refresh()
end

-- Mailbox and standalone entry points share the same UIParent window.
function Mail:Place()
    if not self.book or InCombatLockdown() then return end
    self:PlaceBook(Shown(MailFrame) and MailFrame or nil)
end

function Mail:Create()
    if InCombatLockdown() or not Accessible(MailFrame) then return end
    self:OpenBook(MailFrame)
end

function Mail:Refresh()
    if InCombatLockdown() or not self.book then return end
    self:RefreshBook()
    if self.groupEditor and Shown(self.groupEditor.frame) then self:RefreshGroups() end
end

function Mail:SelectEditorTab(tab)
    if InCombatLockdown() or not self.book or (tab ~= "contacts" and tab ~= "groups" and tab ~= "preferences") then return end
    if tab == "groups" and not self.groupEditor then self:OpenGroups(); return end
    local book = self.book
    self.editorTab = tab
    for _, field in ipairs({ "search", "name", "notes" }) do book[field]:ClearFocus() end
    book.confirm = nil; book.remove.label:SetText("Remove")
    if self.groupEditor then
        self.groupEditor.name:ClearFocus(); self.groupEditor.search:ClearFocus(); self.groupEditor.confirm = nil
        self.groupEditor.remove.label:SetText("Delete group")
        self.groupEditor.frame:SetShown(tab == "groups")
    end
    book.content:SetShown(tab == "contacts")
    for id, button in pairs(book.editorTabs) do
        button.label:SetTextColor(unpack(id == tab and colors.accent or colors.muted))
        button:SetBackdropBorderColor(unpack(id == tab and colors.accent or colors.row))
    end
    if book.preferences then book.preferences:SetShown(tab == "preferences") end
    if tab == "contacts" then self:RefreshBook() elseif tab == "groups" then self:RefreshGroups() end
end

local function PagedList(parent, x, y, width, count, callback)
    local list = { rows = {}, page = 1 }
    for index = 1, count do
        local row = Button(parent, width, "", function() end)
        row:SetSize(width, 36); row:SetPoint("TOPLEFT", x, y - (index - 1) * 40)
        row.label:SetWidth(width - 16)
        row:SetScript("OnClick", function()
            if not InCombatLockdown() and Shown(parent) and Shown(parent:GetParent()) and row.entry then callback(row.entry, row) end
        end)
        list.rows[index] = row
    end
    list.previous = Button(parent, 30, "<", function() if not InCombatLockdown() and Shown(parent) and Shown(parent:GetParent()) then list.page = list.page - 1; list.refresh() end end)
    list.previous:SetPoint("TOPLEFT", x, y - count * 40 - 4)
    list.next = Button(parent, 30, ">", function() if not InCombatLockdown() and Shown(parent) and Shown(parent:GetParent()) then list.page = list.page + 1; list.refresh() end end)
    list.next:SetPoint("TOPLEFT", x + width - 30, y - count * 40 - 4)
    list.count = Text(parent, 10, colors.muted); list.count:SetPoint("TOPLEFT", x + 38, y - count * 40 - 11)
    Suite.Theme:PageWheel(parent, list.rows, list.previous, list.next, list.next)
    return list
end

local function RenderList(list, entries, render)
    local pages = math.max(1, math.ceil(#entries / #list.rows))
    list.page = math.max(1, math.min(list.page, pages))
    for index, row in ipairs(list.rows) do
        row.entry = entries[(list.page - 1) * #list.rows + index]
        row:SetShown(row.entry ~= nil)
        if row.entry then render(row, row.entry) end
    end
    list.previous:SetEnabled(list.page > 1); list.next:SetEnabled(list.page < pages)
    list.count:SetText(list.page .. " / " .. pages)
end

function Mail:RefreshDirectoryGroups()
    local book = self.book
    if not book or not book.navigation then return end
    local definitions, order = self:GroupDefinitions()
    local entries = { { id = "all", name = "All contacts" } }
    for _, id in ipairs(order) do
        if id ~= "all" and self:GroupVisible(id) then entries[#entries + 1] = { id = id, name = definitions[id].name } end
    end
    RenderList(book.navigation, entries, function(row, entry)
        row.label:SetText(entry.name)
        Fill(row, entry.id == (book.groupFilter or book.tab or "all") and { 0.1, 0.2, 0.21 } or colors.row)
    end)
end

function Mail:OpenGroups(anchor)
    if InCombatLockdown() then return end
    self:OpenBook(anchor, "groups")
    if not self.groupEditor then
        local frame = CreateFrame("Frame", nil, self.book.frame)
        frame:SetSize(BOOK_WIDTH, 546); frame:SetPoint("TOPLEFT", 0, -104)
        local editor = { frame = frame }; self.groupEditor = editor
        local function Add(label, x, y, width, callback)
            local button = Button(frame, width, label, callback); button:SetPoint("TOPLEFT", x, y); return button
        end
        local function Active() return not InCombatLockdown() and Shown(frame) and Shown(self.book.frame) end
        local caption = Text(frame, 12, colors.muted); caption:SetPoint("TOPLEFT", 18, -12); caption:SetText("Groups")
        editor.navigation = PagedList(frame, 18, -40, 128, 10, function(entry)
            if Active() then editor.id = entry.id; editor.memberList.page, editor.sourceList.page = 1, 1; self:RefreshGroups() end
        end)
        editor.navigation.refresh = function() self:RefreshGroups() end
        editor.name = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
        editor.name:SetSize(212, 30); editor.name:SetPoint("TOPLEFT", 164, -10); Fill(editor.name)
        editor.name:SetAutoFocus(false); editor.name:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        editor.name:SetTextInsets(8, 8, 0, 0); editor.name:SetMaxLetters(32)
        editor.name:SetScript("OnTextChanged", function() editor.confirm = nil; if editor.remove then editor.remove.label:SetText("Delete group") end end)
        editor.name:SetScript("OnEscapePressed", function() editor.name:ClearFocus(); self.dismissed = self.visit; self.book.frame:Hide() end)
        editor.rename = Add("Rename", 384, -10, 90, function()
            if not Active() then return end
            if self:SaveGroup(editor.id, editor.name:GetText()) then editor.loadedID = nil; self:RefreshGroups()
            else editor.status:SetText("Use a unique group name, up to 32 characters.") end
        end)
        editor.create = Add("Create group", 482, -10, 112, function()
            if not Active() then return end
            local id = self:SaveGroup(nil, editor.name:GetText())
            if id then editor.id, editor.loadedID = id, nil; self:RefreshGroups()
            else editor.status:SetText("Enter a group name, up to 32 characters.") end
        end)
        editor.remove = Add("Delete group", 602, -10, 120, function()
            if not Active() or not editor.id or not editor.id:match("^custom:%d+$") then return end
            if editor.confirm ~= editor.id then editor.confirm = editor.id; editor.remove.label:SetText("Confirm delete"); return end
            local settings, id = self:GroupSettings(), editor.id
            settings.custom[id], settings.hidden[id] = nil, nil
            for _, group in pairs(self:GroupDefinitions()) do
                if Suite.IsReadable(group.sources) and type(group.sources) == "table" then group.sources[id] = nil end
            end
            editor.id, editor.loadedID = "all", nil; self:Refresh()
        end)
        editor.summary = Text(frame, 12, colors.accent); editor.summary:SetPoint("TOPLEFT", 164, -54); editor.summary:SetWidth(558)
        editor.visible = Add("", 164, -82, 270, function()
            if not Active() then return end
            self:GroupSettings().hidden[editor.id] = self:GroupVisible(editor.id); self:Refresh()
        end)
        local function Move(delta)
            if not Active() then return end
            local _, order = self:GroupDefinitions()
            for i, id in ipairs(order) do
                if id == editor.id and order[i + delta] then order[i], order[i + delta] = order[i + delta], id; break end
            end
            self:GroupSettings().order = order; self:Refresh()
        end
        Add("Move up", 452, -82, 130, function() Move(-1) end)
        Add("Move down", 590, -82, 132, function() Move(1) end)
        local membersTitle = Text(frame, 12, colors.muted); membersTitle:SetPoint("TOPLEFT", 164, -126); membersTitle:SetText("Contacts · direct / inherited"); membersTitle:SetWidth(270)
        local sourcesTitle = Text(frame, 12, colors.muted); sourcesTitle:SetPoint("TOPLEFT", 452, -126); sourcesTitle:SetText("Included groups · click to toggle"); sourcesTitle:SetWidth(270)
        editor.search = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
        editor.search:SetSize(270, 28); editor.search:SetPoint("TOPLEFT", 164, -148); Fill(editor.search)
        editor.search:SetAutoFocus(false); editor.search:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        editor.search:SetTextInsets(8, 8, 0, 0); editor.search:SetMaxLetters(240)
        editor.search:SetScript("OnTextChanged", function() editor.memberList.page = 1; self:RefreshGroups() end)
        editor.search:SetScript("OnEscapePressed", function() editor.search:ClearFocus(); self.dismissed = self.visit; self.book.frame:Hide() end)
        local function Toggle(kind, entry)
            if not Active() or entry.owner ~= editor.id or entry.region ~= Region() or entry.ruleset ~= Ruleset() then return end
            if not self:ToggleGroupMember(editor.id, kind, entry.key or entry.id) then
                editor.status:SetText("A group cannot include itself or one of its parents.")
            end
        end
        editor.memberList = PagedList(frame, 164, -188, 270, GROUP_ROWS - 2, function(entry) Toggle("contacts", entry) end)
        editor.sourceList = PagedList(frame, 452, -188, 270, GROUP_ROWS - 2, function(entry) Toggle("sources", entry) end)
        editor.memberList.refresh = function() self:RefreshGroups() end
        editor.sourceList.refresh = function() self:RefreshGroups() end
        editor.status = Text(frame, 11, colors.muted); editor.status:SetPoint("TOPLEFT", 164, -482)
        editor.status:SetSize(558, 48); editor.status:SetWordWrap(true)
        frame:SetScript("OnHide", function() editor.name:ClearFocus(); editor.search:ClearFocus(); editor.confirm = nil end)
        self:RefreshGroups()
    end
    self:SelectEditorTab("groups")
end

function Mail:RefreshGroups()
    if InCombatLockdown() or not self.groupEditor then return end
    local editor, definitions, order = self.groupEditor, self:GroupDefinitions()
    editor.id = definitions[editor.id] and editor.id or "all"
    local group, custom = definitions[editor.id], editor.id:match("^custom:%d+$") ~= nil
    if editor.loadedID ~= editor.id then editor.name:SetText(group.name); editor.loadedID = editor.id end
    editor.rename:SetEnabled(custom); editor.remove:SetEnabled(custom)
    editor.confirm = nil; editor.remove.label:SetText("Delete group")
    editor.visible.label:SetText(self:GroupVisible(editor.id) and "Hide in Contacts sidebar" or "Show in Contacts sidebar")
    local groups = {}
    for _, id in ipairs(order) do groups[#groups + 1] = { id = id, name = definitions[id].name } end
    RenderList(editor.navigation, groups, function(row, entry)
        row.label:SetText(entry.name); Fill(row, entry.id == editor.id and { 0.1, 0.2, 0.21 } or colors.row)
    end)
    local members, sources, directCount, inheritedCount = {}, {}, 0, 0
    local region, ruleset = Region(), Ruleset()
    for _, entry in ipairs(self:ContactList("all", "", nil, true)) do
        local direct = custom and Suite.IsReadable(group.contacts) and type(group.contacts) == "table"
            and Suite.IsReadable(group.contacts[ContactReference(entry)]) and group.contacts[ContactReference(entry)] == true
        local inherited = false
        local via = {}
        if custom and Suite.IsReadable(group.sources) and type(group.sources) == "table" then
            for _, id in ipairs(order) do
                if Suite.IsReadable(group.sources[id]) and group.sources[id] == true and self:GroupMatches(id, entry, entry.group, definitions, {}) then
                    inherited = true; via[#via + 1] = definitions[id].name
                end
            end
        end
        if self:GroupMatches(editor.id, entry, entry.group, definitions, {}) then
            if direct then directCount = directCount + 1 else inheritedCount = inheritedCount + 1 end
        end
        local query = editor.search:GetText()
        query = Suite.IsReadable(query) and type(query) == "string" and query:lower() or ""
        if entry.name:lower():find(query, 1, true) then
            members[#members + 1] = { key = entry.key, name = entry.name, direct = direct, inherited = inherited,
                via = table.concat(via, ", "), member = self:GroupMatches(editor.id, entry, entry.group, definitions, {}),
                owner = editor.id, region = region, ruleset = ruleset }
        end
    end
    -- Members precede candidates; all candidates remain available for direct assignment.
    table.sort(members, function(a, b) if a.member ~= b.member then return a.member end return a.name:lower() < b.name:lower() end)
    for _, id in ipairs(order) do
        if id ~= editor.id then sources[#sources + 1] = { id = id, name = definitions[id].name, owner = editor.id, region = region, ruleset = ruleset } end
    end
    RenderList(editor.memberList, members, function(row, entry)
        row.label:SetText((entry.direct and "[x] " or entry.inherited and "[via] " or "[ ] ") .. entry.name)
        row:SetEnabled(custom)
        row:SetScript("OnEnter", function()
            if not Shown(editor.frame) then return end
            editor.status:SetText(entry.direct and (entry.inherited and "Direct member and included through " .. entry.via .. ". Removing direct membership keeps inherited membership." or "Click to remove from this group. The saved contact is kept.")
                or entry.inherited and "Included through " .. entry.via .. ". Edit those groups to remove inherited membership, or click to also add directly."
                or custom and "Click to add this contact directly to the group." or "Automatic membership follows the current character or guild roster.")
        end)
    end)
    RenderList(editor.sourceList, sources, function(row, entry)
        local checked = Suite.IsReadable(group.sources) and type(group.sources) == "table" and Suite.IsReadable(group.sources[entry.id]) and group.sources[entry.id] == true
        row.label:SetText((checked and "[x] " or "[ ] ") .. entry.name); row:SetEnabled(custom)
    end)
    editor.summary:SetText((directCount + inheritedCount) .. " contacts · " .. directCount .. " direct · " .. inheritedCount .. " included automatically")
    editor.status:SetText(custom and "Changes apply immediately. [x] = direct member; [via] = included through another group. Deleting a group keeps its contacts."
        or "Automatic groups are read-only. Create a named group to combine groups and individual contacts.")
end

function Mail:EndVisit()
    self.visit, self.sendPending, self.pendingRecipient, self.lastRecipient = nil, nil, nil, nil
    self.selected, self.confirm = nil, nil
    self.nameAttempts, self.guildEntries, self.guildLoaded, self.guildRequested = nil, nil, nil, nil
    self:Cancel()
    Suite.pending.mailRecipient = nil
    if self.book and self.book.mailbox then
        self.book.mailbox = nil
        if self.frame and Accessible(self.frame) then self.frame:Hide() end
    elseif self.book and Shown(self.book.frame) then self:Refresh(); self:RefreshBookRoster() end
end

function Mail:BeginVisit()
    if not self.active or not Shown(MailFrame) then return end
    local newVisit = not self.visit
    self.visit = true
    if newVisit then self.dismissed = nil end
    if InCombatLockdown() then self:Schedule(); return end
    if not Suite.db.mailHelper or not Shown(SendMailFrame) then
        if self.book and self.book.mailbox and self.frame and Accessible(self.frame) then self.frame:Hide()
        elseif self.book and Shown(self.book.frame) then self:Refresh() end
        return
    end
    if (newVisit or not self.guildRequested) and C_GuildInfo and type(C_GuildInfo.GuildRoster) == "function" then
        self.guildRequested = true
        pcall(C_GuildInfo.GuildRoster)
    end
    self:SeedRecordedCharacters(); self:ResolveRecordedNames()
    if not self.guildLoaded then self:ReadGuild(); self.guildLoaded = true end
    if not self.frame or not Shown(self.frame) and not self.dismissed then self:Create() end
    if not self.frame or self.dismissed then return end
    self:Refresh(); self.frame:Show()
end

function Mail:Sent()
    if not self.active or not self.visit or not Shown(MailFrame) then return end
    local recipient = self.pendingRecipient
    self.sendPending, self.pendingRecipient = nil, nil
    if Suite.db.mailRememberRecipient and recipient then
        self.lastRecipient = recipient
        -- Called after Blizzard's MAIL_SEND_SUCCESS handler resets the compose fields.
        Suite.AfterCombat("mailRecipient", function()
            if not self.active or not self.visit or not Suite.db.mailRememberRecipient
                or self.lastRecipient ~= recipient or not Shown(MailFrame) then return end
            local field = Field()
            if field then
                local text = field:GetText()
                if Suite.IsReadable(text) and text == "" then field:SetText(recipient) end
            end
        end)
    end
    self:Refresh()
end

function Mail:Bind()
    if InCombatLockdown() or not self.active or not Accessible(MailFrame) then return end
    if self.bound ~= MailFrame then
        self.bound = MailFrame
        MailFrame:HookScript("OnShow", function() if self.active then self:BeginVisit() end end)
        MailFrame:HookScript("OnHide", function() if self.active then self:EndVisit() end end)
        MailFrame:HookScript("OnEvent", function(_, event)
            if not self.active or not self.visit then return end
            if event == "MAIL_SEND_SUCCESS" then self:Sent()
            elseif event == "MAIL_FAILED" then
                self.sendPending, self.pendingRecipient = nil, nil; self:Refresh()
            end
        end)
        if hooksecurefunc then
            for _, method in ipairs({ "SetPoint", "SetScale" }) do
                if MailFrame[method] then hooksecurefunc(MailFrame, method, function() if self.active and self.visit then self:Schedule() end end) end
            end
        end
    end
    if Accessible(SendMailFrame) and self.boundSend ~= SendMailFrame then
        self.boundSend = SendMailFrame
        SendMailFrame:HookScript("OnShow", function() if self.active then self:BeginVisit() end end)
        SendMailFrame:HookScript("OnHide", function()
            if self.active and not self.choosingRecipient then
                if self.book and self.book.mailbox and self.frame and Accessible(self.frame) then self.frame:Hide()
                elseif self.book and Shown(self.book.frame) then self:Refresh() end
            end
        end)
    end
    if not self.sendHook and type(SendMailFrame_SendMail) == "function" and hooksecurefunc then
        self.sendHook = true
        hooksecurefunc("SendMailFrame_SendMail", function()
            if not self.active or not self.visit or not Shown(MailFrame) then return end
            local field = Field()
            local recipient = Parse(field and field:GetText())
            self.pendingRecipient, self.sendPending = recipient, true
            self:Refresh()
        end)
    end
end

function Mail:Cancel()
    if self.timer then self.timer:Cancel(); self.timer = nil end
    Suite.pending.mailRefresh = nil
end

function Mail:Schedule()
    if not self.active then return end
    if InCombatLockdown() then
        Suite.AfterCombat("mailRefresh", function() if self.active then self:Bind(); self:BeginVisit() end end)
        return
    end
    if self.timer or not C_Timer or not C_Timer.NewTimer then return end
    self.timer = C_Timer.NewTimer(0, function()
        self.timer = nil
        if not self.active then return end
        if InCombatLockdown() then self:Schedule(); return end
        self:Bind(); self:BeginVisit()
    end)
end

function Mail:Apply()
    if not Suite.db.mailHelper then self.guildEntries, self.guildLoaded, self.guildRequested = nil, nil, nil end
    if not Suite.db.mailHelper and not Suite.db.mailRememberRecipient then
        self.active = nil; self:EndVisit(); Suite.pending.mail = nil
        if self.events then self.events:UnregisterAllEvents() end
        return
    end
    if not Suite.db.mailRememberRecipient then self.lastRecipient = nil; Suite.pending.mailRecipient = nil end
    if not Suite.db.mailHelper and self.book and self.book.mailbox and self.frame and Accessible(self.frame) then self.frame:Hide() end
    Suite.AfterCombat("mail", function()
        if not Suite.db.mailHelper and not Suite.db.mailRememberRecipient then return end
        self:Database()
        if not self.active then
            self.active = true
            if not self.events then
                self.events = CreateFrame("Frame")
                self.events:SetScript("OnEvent", function(_, event, level)
                    if not self.active then return end
                    if event == "MAIL_CLOSED" then self:EndVisit()
                    elseif event == "PLAYER_REGEN_DISABLED" then
                        self:Cancel()
                        if self.frame and Accessible(self.frame) then self.frame:Hide() end
                        self:Schedule()
                    else
                        if event == "GUILD_ROSTER_UPDATE" or event == "PLAYER_GUILD_UPDATE"
                            or event:find("^CLUB_") or event == "PLAYER_ENTERING_WORLD"
                            or event == "GAME_RULES_CHANGED" or event == "ADDON_LOADED" then self.guildLoaded = nil end
                        if event == "UNIT_NAME_UPDATE" and (not Suite.IsReadable(level) or level ~= "player") then return end
                        if event == "ADDON_LOADED" or event == "PLAYER_ENTERING_WORLD" or event == "MAIL_SHOW"
                            or event == "UNIT_NAME_UPDATE" or event == "GAME_RULES_CHANGED" then self.nameAttempts = nil end
                        if event == "PLAYER_ENTERING_WORLD" or event == "MAIL_SHOW" or event == "UNIT_NAME_UPDATE"
                            or event == "GAME_RULES_CHANGED" then self:RecordPlayer()
                        elseif event == "PLAYER_LEVEL_UP" then self:RecordPlayer(level) end
                        self:Schedule()
                    end
                end)
            end
            for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP", "UNIT_NAME_UPDATE", "GAME_RULES_CHANGED",
                "MAIL_SHOW", "MAIL_CLOSED", "PLAYER_REGEN_DISABLED", "GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE",
                "CLUB_ADDED", "CLUB_REMOVED", "CLUB_STREAMS_LOADED", "CLUB_MEMBERS_UPDATED", "CLUB_MEMBER_ADDED", "CLUB_MEMBER_REMOVED", "CLUB_MEMBER_UPDATED" }) do
                self.events:RegisterEvent(event)
            end
        end
        self:RecordPlayer(); self:Bind(); self:BeginVisit()
    end)
end

-- The book shares contact storage with Send Mail, but never requires or opens native mail UI.
local function OptionalText(value, maximum, multiline)
    if not Suite.IsReadable(value) or type(value) ~= "string" then return nil, false end
    value = value:match("^%s*(.-)%s*$")
    if value == "" then return nil, true end
    if multiline then
        local notes = Notes(value)
        return notes, notes ~= nil
    end
    if String(value, maximum) then return value, true end
    return nil, false
end

function Mail:SaveContact(key, name, category, notes, groupChanges)
    if InCombatLockdown() then return nil, "Contacts cannot be changed in combat." end
    if not Suite.IsReadable(key) or key ~= nil and not String(key, 240) then return nil, "Invalid contact." end
    name = Name(name)
    local ruleset = Ruleset()
    if not ruleset then return nil, "Server type is not available yet." end
    local validCategory, validNotes
    category, validCategory = OptionalText(category, 32)
    notes, validNotes = OptionalText(notes, 240, true)
    if not name then return nil, "Enter a first and last name." end
    if not validCategory or not validNotes then return nil, "Use plain text within the field limits." end
    if not Suite.IsReadable(groupChanges) then return nil, "Invalid group choices." end
    if groupChanges ~= nil then
        if type(groupChanges) ~= "table" then return nil, "Invalid group choices." end
        for id, selected in pairs(groupChanges) do
            if not String(id, 80) or not id:match("^custom:%d+$") or not Suite.IsReadable(selected)
                or type(selected) ~= "boolean" then return nil, "Invalid group choices." end
        end
    end
    self:GroupSettings()
    local entries, old = self:Database(), nil
    if key then
        for _, entry in ipairs(self:List(true, "", nil, self.book and self.book.unassigned)) do
            if entry.key == key then old = entry; break end
        end
        if not old then return nil, "This contact is no longer available." end
    end
    local region = Region()
    if not region then return nil, "Character region is not available yet." end
    for _, entry in ipairs(self:List(true, "")) do
        if entry.key ~= key and entry.name:lower() == name:lower() and entry.ruleset == ruleset then
            return nil, "That name is already in your contacts."
        end
    end
    local saved = key and entries[key]
    local guid = saved and String(saved.guid, 128) and saved.guid or nil
    local newKey = self:Store(name, ruleset, region, guid, old and old.class, old and old.level, old and old.faction)
    if not newKey then return nil, "Contact could not be saved." end
    if entries[newKey].category ~= category then entries[newKey].groupCategory = nil end
    entries[newKey].category, entries[newKey].notes = category, notes
    if old then
        local oldReference, newReference = ContactReference(old), Key(region, name, ruleset)
        for _, group in pairs(self:GroupDefinitions()) do
            if Suite.IsReadable(group.contacts) and type(group.contacts) == "table"
                and Suite.IsReadable(group.contacts[oldReference]) and group.contacts[oldReference] == true then
                group.contacts[oldReference] = nil
                group.contacts[newReference] = true
            end
        end
    end
    local definitions, reference = self:GroupDefinitions(), Key(region, name, ruleset)
    for id, selected in pairs(groupChanges or {}) do
        local group = definitions[id]
        if group then
            if not Suite.IsReadable(group.contacts) or type(group.contacts) ~= "table" then group.contacts = {} end
            group.contacts[reference] = selected or nil
        end
    end
    if key and key ~= newKey then entries[key], self.removed[key] = nil, true end
    self.removed[newKey] = nil
    if old then self.removed[Key(region, old.name, old.ruleset)] = true end
    self.removed[Key(region, name, ruleset)] = nil
    self:Refresh()
    return newKey, "Contact saved."
end

function Mail:DeleteContact(key)
    if InCombatLockdown() then return false end
    for _, entry in ipairs(self:List(true, "", nil, self.book and self.book.unassigned)) do
        if entry.key == key then
            if entry.current then return false end
            for _, group in pairs(self:GroupDefinitions()) do
                if Suite.IsReadable(group.contacts) and type(group.contacts) == "table" then group.contacts[ContactReference(entry)] = nil end
            end
            self:Database()[key] = nil
            self.removed[key], self.removed[Key(Region(), entry.name, entry.ruleset)] = true, true
            self:Refresh()
            return true
        end
    end
    return false
end

function Mail:Categories(unassigned)
    local categories, seen = {}, {}
    for _, entry in ipairs(self:List(true, "", nil, unassigned)) do
        if entry.category and not seen[entry.category] then
            seen[entry.category] = true; categories[#categories + 1] = entry.category
        end
    end
    table.sort(categories)
    return categories
end

function Mail:ChooseBookFilter()
    local book = self.book
    if InCombatLockdown() or not book or not Shown(book.frame) or not Shown(book.content) then return end
    local region, ruleset, unassigned = Region(), Ruleset(), book.unassigned
    local options = {}
    local definitions, order = self:GroupDefinitions()
    for _, id in ipairs(order) do
        if id:match("^custom:%d+$") then options[#options + 1] = { name = definitions[id].name, group = id } end
    end
    local function Select(option)
        if InCombatLockdown() or not Shown(book.frame) or not Shown(book.content)
            or Region() ~= region or Ruleset() ~= ruleset or book.unassigned ~= unassigned then return end
        if option then
            local available = false
            available = self:GroupDefinitions()[option.group] ~= nil
            if not available then return end
        end
        book.groupFilter, book.filter, book.tab, book.page, book.confirm = option and option.group, nil, "all", 1, nil
        self:RefreshBook()
    end
    if MenuUtil and type(MenuUtil.CreateContextMenu) == "function" then
        MenuUtil.CreateContextMenu(book.filterButton, function(_, root)
            root:CreateButton("Clear custom filter", function() Select(nil) end)
            for _, option in ipairs(options) do
                local choice = option
                root:CreateButton(choice.name, function() Select(choice) end)
            end
        end)
    else
        local nextIndex = 1
        for index, option in ipairs(options) do
            if option.group == book.groupFilter then nextIndex = index + 1; break end
        end
        Select(options[nextIndex])
    end
end

function Mail:RefreshBookGroups()
    local book = self.book
    if not book or not book.groupsChoose then return end
    local definitions, order = self:GroupDefinitions()
    book.groupChoices = {}
    local names = {}
    for _, id in ipairs(order) do
        if id:match("^custom:%d+$") then
            local group = definitions[id]
            local selected = book.groupReference and Suite.IsReadable(group.contacts) and type(group.contacts) == "table"
                and Suite.IsReadable(group.contacts[book.groupReference]) and group.contacts[book.groupReference] == true or false
            if book.groupChanges[id] ~= nil then selected = book.groupChanges[id] end
            book.groupChoices[id] = selected
            if selected then names[#names + 1] = group.name end
        end
    end
    book.groupsChoose.label:SetText(#names == 0 and "Groups: Choose..."
        or "Groups: " .. names[1] .. (#names > 1 and " + " .. (#names - 1) or ""))
end

function Mail:ChooseContactGroups()
    local book = self.book
    if InCombatLockdown() or not book or not Shown(book.frame) or not Shown(book.content) then return end
    if not MenuUtil or type(MenuUtil.CreateContextMenu) ~= "function" then book.status:SetText("The native group menu is unavailable."); return end
    self:RefreshBookGroups()
    local version, region, ruleset = book.editVersion, Region(), Ruleset()
    local function Current()
        return not InCombatLockdown() and Shown(book.frame) and Shown(book.content)
            and book.editVersion == version and Region() == region and Ruleset() == ruleset
    end
    local definitions, order = self:GroupDefinitions()
    MenuUtil.CreateContextMenu(book.groupsChoose, function(_, root)
        for _, id in ipairs(order) do
            if id:match("^custom:%d+$") then
                local groupID = id
                root:CreateCheckbox(definitions[id].name, function() return book.groupChoices[groupID] == true end, function()
                    if not Current() or not self:GroupDefinitions()[groupID] then return end
                    book.groupChanges[groupID] = not book.groupChoices[groupID]
                    self:RefreshBookGroups()
                    self:UpdateBookDirty()
                    self:RefreshBook()
                    book.confirm = nil; book.remove.label:SetText("Remove")
                    book.status:SetText("Group choices apply when you Save. Parent groups can also include this contact automatically.")
                end)
            end
        end
        root:CreateButton("Create / edit groups...", function() if Current() then self:SelectEditorTab("groups") end end)
    end)
end

-- Native EditBoxes can report programmatic/late text notifications. A callback
-- alone is not an edit: compare current fields and staged groups to the baseline.
function Mail:UpdateBookDirty()
    local book = self.book
    if not book or book.loading then return end
    local original = book.original or { name = "", notes = "", groups = {} }
    local dirty = false
    for _, field in ipairs({ "name", "notes" }) do
        local value = book[field]:GetText()
        if not Suite.IsReadable(value) or type(value) ~= "string" or value ~= original[field] then dirty = true end
    end
    for id, selected in pairs(book.groupChanges or {}) do
        if selected ~= (original.groups[id] == true) then dirty = true end
    end
    book.dirty = dirty or nil
end

function Mail:EditContact(entry)
    if InCombatLockdown() then return end
    local book = self.book
    book.loading = true
    if book.notesScroll and not InCombatLockdown() then book.notesScroll.offset = 0; book.notesScroll:SetVerticalScroll(0) end
    book.original = { name = entry and entry.name or "", notes = entry and entry.notes or "", groups = {} }
    book.entry, book.editRegion, book.editRuleset = entry, Region(), Ruleset()
    book.key, book.confirm = entry and not entry.roster and entry.key or nil, nil
    book.editVersion = (book.editVersion or 0) + 1
    book.groupReference, book.groupChanges = entry and ContactReference(entry), {}
    for _, field in ipairs({ "name", "notes" }) do
        local value = entry and entry[field]
        book[field]:SetText(value or "")
    end
    book.status:SetText(entry and (entry.roster and "Save to keep this guild member in your contacts."
        or not entry.ruleset and "Save assigns this contact to " .. (Ruleset() or "your current server type") .. "."
        or entry.incomplete and "Add this character's last name, then Save to use as a recipient."
        or entry.current and "This is your current character. Choose another contact to address mail."
        or "Edit this contact, then Save.") or "New contact. Enter a first and last name.")
    book.remove.label:SetText("Remove")
    book.remove:SetEnabled(entry ~= nil and not entry.current and not entry.roster)
    book.loading, book.dirty = nil, nil
    self:RefreshBookGroups()
    book.original.groups = Suite.Copy(book.groupChoices)
end

function Mail:RefreshBook()
    if InCombatLockdown() or not self.book then return end
    local book = self.book
    local definitions = self:GroupDefinitions()
    local preferences = self:GroupSettings()
    local hideDetails = Suite.IsReadable(preferences.hideDetails) and preferences.hideDetails == true
    book.subtitle:SetText("Your contacts and groups · " .. (Ruleset() or "Waiting for server type"))
    book.details.label:SetText(hideDetails and "Contact row details: hidden" or "Contact row details: shown")
    for key, button in pairs(self.sortButtons) do
        button.label:SetText((key == "name" and "Name" or "Level") .. (self.sort == key and (self.ascending and " ^" or " v") or ""))
    end
    if book.filter then book.groupFilter, book.filter = self:GroupSettings().categoryAliases[book.filter], nil end
    if book.groupFilter and not definitions[book.groupFilter] then book.groupFilter = nil end
    local entries = book.unassigned and self:List(true, book.search:GetText(), nil, true)
        or self:ContactList(book.groupFilter or book.tab or "all", book.search:GetText(), nil, not (Suite.db.mailHelper and self.visit and Shown(SendMailFrame)))
    if book.unassigned and book.groupFilter then
        local filtered = {}
        for _, entry in ipairs(entries) do if self:GroupMatches(book.groupFilter, entry, nil, definitions, {}) then filtered[#filtered + 1] = entry end end
        entries = filtered
    end
    local pages = math.max(1, math.ceil(#entries / CONTACT_ROWS))
    book.page = math.max(1, math.min(book.page or 1, pages))
    book.filterButton.label:SetText("All groups...")
    self.contactTab = book.groupFilter or book.tab or "all"
    local filterName = book.groupFilter and definitions[book.groupFilter].name or book.filter
    book.filterButton:SetBackdropBorderColor(unpack(filterName and colors.accent or colors.row))
    book.filterSummary:SetText(filterName or (book.unassigned and "Unassigned contacts" or ({ all = "All contacts", alts = "Account alts", guild = "Guild members" })[book.tab or "all"] or "All contacts"))
    self:RefreshBookGroups()
    book.recovery.label:SetText(book.unassigned and "Show current server contacts" or "Recover unassigned contacts")
    for index, row in ipairs(book.rows) do
        row.entry = entries[(book.page - 1) * CONTACT_ROWS + index]
        row.region, row.ruleset = Region(), Ruleset()
        row:SetShown(row.entry ~= nil)
        if row.entry then
            row.label:SetText(row.entry.name)
            local classColor = RAID_CLASS_COLORS and row.entry.class and RAID_CLASS_COLORS[row.entry.class]
            if Suite.IsReadable(classColor) and type(classColor) == "table"
                and Number(classColor.r, 0, 1) and Number(classColor.g, 0, 1) and Number(classColor.b, 0, 1) then
                row.label:SetTextColor(classColor.r, classColor.g, classColor.b)
            else row.label:SetTextColor(unpack(colors.text)) end
            local detail = book.unassigned and "Server type unassigned"
                or ({ alts = "Alt", guild = "Guild member", other = "Contact" })[row.entry.group] or "Contact"
            local memberships, reference = {}, ContactReference(row.entry)
            for id, group in pairs(definitions) do
                if id:match("^custom:%d+$") and Suite.IsReadable(group.contacts) and type(group.contacts) == "table"
                    and Suite.IsReadable(group.contacts[reference]) and group.contacts[reference] == true then memberships[#memberships + 1] = group.name end
            end
            table.sort(memberships)
            if row.entry.level then detail = detail .. " · Level " .. row.entry.level end
            row.detail:SetShown(not hideDetails)
            row.detail:SetText(detail .. (#memberships > 0 and " · " .. table.concat(memberships, ", ") or ""))
            Fill(row, row.entry.key == book.key and { 0.1, 0.2, 0.21 } or colors.row)
        end
    end
    book.count:SetText(#entries .. " contacts  ·  " .. book.page .. " / " .. pages)
    self.page = book.page
    self:RefreshDirectoryGroups()
    local selected
    local selectable = book.unassigned and self:List(true, "", nil, true) or self:ContactList("all", "", nil, true)
    for _, entry in ipairs(selectable) do
        if book.entry and entry.key == book.entry.key then selected = entry; break end
    end
    local ready = selected and not selected.current and not selected.incomplete and not book.unassigned
        and not book.dirty and book.editRegion == Region() and book.editRuleset == Ruleset()
        and Suite.db.mailHelper and self.visit and Shown(MailFrame) and Shown(SendMailFrame) and not self.sendPending
    book.use:SetEnabled(ready == true)
    book.use.label:SetText(self.sendPending and "Sending..." or book.dirty and "Save changes to use recipient"
        or not selected and "Select a contact to address"
        or selected.current and "Current character cannot receive"
        or selected.incomplete and "Add last name before use"
        or book.unassigned and "Save to assign server type"
        or not Suite.db.mailHelper and "Enable Contacts with Send Mail"
        or (not self.visit or not Shown(SendMailFrame)) and "Open Send Mail to address" or "Use as recipient")
    book.editState:SetText(book.dirty and "Unsaved changes" or selected and (selected.roster and "Guild roster · Save to keep this contact" or "Saved contact") or "New contact")
    book.cancel:SetEnabled(book.dirty == true)
    book.saveRecipient:SetShown(Suite.db.mailHelper and self.visit and Shown(SendMailFrame) or false)
    book.saveRecipient:SetEnabled(Suite.db.mailHelper and self.visit and Shown(SendMailFrame) and not self.sendPending and not book.dirty or false)
    book.previous:SetEnabled(book.page > 1); book.next:SetEnabled(book.page < pages)
    book.empty:SetShown(#entries == 0)
end

-- The standalone book listens only while visible, independently of mailbox options.
function Mail:RefreshBookRoster()
    local book = self.book
    if not book or not Shown(book.frame) then return end
    if InCombatLockdown() then
        Suite.AfterCombat("mailBook", function() self:RefreshBookRoster() end)
        return
    end
    if book.timer or not C_Timer or not C_Timer.NewTimer then return end
    book.timer = C_Timer.NewTimer(0, function()
        book.timer = nil
        if not Shown(book.frame) then return end
        if InCombatLockdown() then self:RefreshBookRoster(); return end
        self:ReadGuild(); self:Refresh()
    end)
end

function Mail:PlaceBook(anchor)
    if InCombatLockdown() or not self.book then return end
    if anchor == self.book.frame then return end
    if not Suite.PlaceWindow(self.book.frame, anchor) then
        self.book.frame:ClearAllPoints(); self.book.frame:SetPoint("CENTER")
    end
end

function Mail:OpenBook(anchor, tab)
    if InCombatLockdown() then Suite.Print("Open Contacts after combat."); return end
    local wasShown = self.book and Shown(self.book.frame)
    if not self.book then
        local window = CreateFrame("Frame", "WoWForeverSuiteContactBook", UIParent, "BackdropTemplate")
        local frame = CreateFrame("Frame", nil, window)
        local book = { frame = window, content = frame, rows = {}, page = 1, tab = "all" }; self.book = book
        window:SetSize(BOOK_WIDTH, BOOK_HEIGHT); window:SetPoint("CENTER"); window:SetFrameStrata("DIALOG")
        window:SetToplevel(true); window:SetClampedToScreen(true); window:EnableMouse(true); Fill(window, colors.background)
        window:SetMovable(true); window:RegisterForDrag("LeftButton")
        window:SetScript("OnDragStart", function() if not InCombatLockdown() then window:StartMoving() end end)
        window:SetScript("OnDragStop", function() window:StopMovingOrSizing() end)
        frame:SetSize(BOOK_WIDTH, 546); frame:SetPoint("TOPLEFT", 0, -104)
        if UISpecialFrames then table.insert(UISpecialFrames, "WoWForeverSuiteContactBook") end
        local title = Text(window, 18); title:SetPoint("TOPLEFT", 18, -18); title:SetText("Contacts")
        local subtitle = Text(window, 11, colors.muted); book.subtitle = subtitle; subtitle:SetPoint("TOPLEFT", 18, -44)
        subtitle:SetText("Your contacts and groups · " .. (Ruleset() or "Waiting for server type"))
        book.close = Button(window, 26, "X", function() self.dismissed = self.visit; window:Hide() end); book.close:SetPoint("TOPRIGHT", -12, -12)
        book.editorTabs = {}
        for index, id in ipairs({ "contacts", "groups", "preferences" }) do
            local button = Button(window, 128, ({ contacts = "Contacts", groups = "Groups", preferences = "Preferences" })[id], function() self:SelectEditorTab(id) end)
            button:SetPoint("TOPLEFT", 18 + (index - 1) * 138, -72); book.editorTabs[id] = button
        end
        local function Add(parent, label, x, y, width, callback)
            local button = Button(parent, width, label, callback); button:SetPoint("TOPLEFT", x, y); return button
        end
        local function Input(parent, label, x, y, width, limit)
            local caption = Text(parent, 11, colors.muted); caption:SetPoint("TOPLEFT", x, y); caption:SetText(label)
            local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
            box:SetSize(width, 30); box:SetPoint("TOPLEFT", x, y - 18); Fill(box)
            box:SetAutoFocus(false); box:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
            box:SetTextInsets(8, 8, 0, 0); box:SetMaxLetters(limit)
            box:SetScript("OnEscapePressed", function() box:ClearFocus(); self.dismissed = self.visit; window:Hide() end)
            box:SetScript("OnEnterPressed", function() box:ClearFocus() end)
            box:SetText(""); return box
        end
        local function Active() return not InCombatLockdown() and Shown(window) and Shown(frame) end
        local function Select(entry)
            if not Active() then return end
            self:UpdateBookDirty()
            local addressing = Suite.db.mailHelper and self.visit and Shown(MailFrame) and Shown(SendMailFrame) and not book.unassigned
            if book.dirty then
                -- Address saved recipients without replacing an unrelated editor draft.
                if addressing then self:Choose(entry.key)
                else book.status:SetText("Save or Cancel your changes before selecting another contact.") end
                return
            end
            self:EditContact(entry); self:RefreshBook()
            if addressing then self:Choose(entry.key) end
        end
        book.navigation = PagedList(frame, 18, -40, 128, 10, function(entry) if Active() then self:SelectContactTab(entry.id) end end)
        book.navigation.refresh = function() self:RefreshDirectoryGroups() end
        local groupsLabel = Text(frame, 12, colors.muted); groupsLabel:SetPoint("TOPLEFT", 18, -12); groupsLabel:SetText("Browse groups")
        book.filterButton = Add(frame, "All groups...", 18, -484, 128, function() self:ChooseBookFilter() end)
        book.search = Input(frame, "Search names or notes", 160, -10, 264, 240)
        book.search.placeholder = Text(book.search, 11, colors.muted); book.search.placeholder:SetPoint("LEFT", 8, 0); book.search.placeholder:SetText("Search contacts")
        book.search:SetScript("OnTextChanged", function()
            local text = book.search:GetText()
            self.query = Suite.IsReadable(text) and type(text) == "string" and text or ""
            book.search.placeholder:SetShown(self.query == ""); book.page = 1; self:RefreshBook()
        end)
        book.filterSummary = Text(frame, 11, colors.accent); book.filterSummary:SetPoint("TOPLEFT", 160, -68); book.filterSummary:SetWidth(264)
        book.sortButtons = {}; self.sortButtons = book.sortButtons
        for index, key in ipairs({ "name", "level" }) do
            self.sortButtons[key] = Add(frame, key == "name" and "Name" or "Level", 160 + (index - 1) * 192, -90, index == 1 and 184 or 72, function()
                if not Active() then return end
                if self.sort == key then self.ascending = not self.ascending else self.sort, self.ascending = key, key ~= "level" end
                local settings = self:GroupSettings(); settings.sort, settings.ascending = self.sort, self.ascending
                self:RefreshBook()
            end)
        end
        for index = 1, CONTACT_ROWS do
            local row = Button(frame, 264, "", function() end); book.rows[index] = row
            row:SetSize(264, 40); row:SetPoint("TOPLEFT", 160, -126 - (index - 1) * 43)
            row.label:ClearAllPoints(); row.label:SetPoint("TOPLEFT", 9, -6); row.label:SetWidth(244)
            row.name = row.label
            row.detail = Text(row, 10, colors.muted); row.detail:SetPoint("TOPLEFT", 9, -24); row.detail:SetWidth(244)
            row:SetScript("OnClick", function() if row.entry and row.region == Region() and row.ruleset == Ruleset() then Select(row.entry) end end)
        end
        book.previous = Add(frame, "<", 160, -484, 30, function() if Active() then book.page = book.page - 1; self:RefreshBook() end end)
        book.next = Add(frame, ">", 394, -484, 30, function() if Active() then book.page = book.page + 1; self:RefreshBook() end end)
        book.count = Text(frame, 10, colors.muted); book.count:SetPoint("TOPLEFT", 200, -491)
        book.wheelArea = Suite.Theme:PageWheel(frame, book.rows, book.previous, book.next, book.next)
        book.empty = Text(frame, 11, colors.muted); book.empty:SetPoint("TOPLEFT", 172, -148); book.empty:SetSize(240, 90); book.empty:SetWordWrap(true)
        book.empty:SetText("No matching contacts. Clear the search, choose another group or add a contact.")
        book.editState = Text(frame, 12, colors.accent); book.editState:SetPoint("TOPLEFT", 444, -12); book.editState:SetWidth(278)
        book.name = Input(frame, "First and last name", 444, -46, 278, 77)
        book.groupsChoose = Add(frame, "Groups: Choose...", 444, -118, 278, function() self:ChooseContactGroups() end)
        local notesLabel = Text(frame, 11, colors.muted); notesLabel:SetPoint("TOPLEFT", 444, -166); notesLabel:SetText("Notes")
        -- Keep the backdrop separate: multiline EditBoxes auto-size to their text.
        book.notesPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        book.notesPanel:SetPoint("TOPLEFT", 444, -184); book.notesPanel:SetSize(278, 100); Fill(book.notesPanel)
        book.notesScroll = CreateFrame("ScrollFrame", nil, book.notesPanel)
        book.notesScroll:SetPoint("TOPLEFT", 8, -8); book.notesScroll:SetSize(262, 84)
        book.notes = CreateFrame("EditBox", nil, book.notesScroll)
        book.notes:SetMultiLine(true); book.notes:SetSize(262, 84)
        book.notes:SetFont("Fonts\\FRIZQT__.TTF", 12, ""); book.notes:SetJustifyH("LEFT"); book.notes:SetJustifyV("TOP")
        book.notes:SetAutoFocus(false); book.notes:SetMaxLetters(240); book.notes:SetTextInsets(0, 0, 0, 0)
        book.notesScroll:SetScrollChild(book.notes)
        local function ScrollNotes(offset)
            if InCombatLockdown() or not Number(offset, -100000, 100000) then return end
            local range = math.max(0, book.notes:GetHeight() - book.notesScroll:GetHeight())
            book.notesScroll.offset = math.max(0, math.min(range, offset))
            book.notesScroll:SetVerticalScroll(book.notesScroll.offset)
        end
        local function WheelNotes(_, delta)
            if Number(delta, -100, 100) then ScrollNotes((book.notesScroll.offset or 0) - delta * 24) end
        end
        for _, surface in ipairs({ book.notesPanel, book.notesScroll, book.notes }) do
            surface:EnableMouseWheel(true); surface:SetScript("OnMouseWheel", WheelNotes)
        end
        book.notesPanel:EnableMouse(true); book.notesScroll:EnableMouse(true)
        book.notesPanel:SetScript("OnMouseDown", function() book.notes:SetFocus() end)
        book.notesScroll:SetScript("OnMouseDown", function() book.notes:SetFocus() end)
        book.notes:SetScript("OnCursorChanged", function(_, _, y, _, height)
            if not Number(y, -100000, 100000) or not Number(height, 0, 1000) then return end
            local top, offset = -y, book.notesScroll.offset or 0
            if top < offset then ScrollNotes(top)
            elseif top + height > offset + 84 then ScrollNotes(top + height - 84) end
        end)
        book.notes:SetScript("OnSizeChanged", function() ScrollNotes(book.notesScroll.offset or 0) end)
        book.notes:SetScript("OnEscapePressed", function() book.notes:ClearFocus(); self.dismissed = self.visit; window:Hide() end)
        -- No OnEnterPressed override: Enter inserts a newline in this field.
        book.use = Add(frame, "Use as recipient", 444, -298, 278, function()
            if not Active() or book.dirty or book.unassigned or book.editRegion ~= Region() or book.editRuleset ~= Ruleset() or not book.entry then return end
            local entry = book.entry
            if entry.incomplete or entry.current then return end
            self:Choose(entry.key)
        end)
        book.status = Text(frame, 11, colors.muted); book.status:SetPoint("TOPLEFT", 444, -340); book.status:SetSize(278, 68); book.status:SetWordWrap(true)
        book.save = Add(frame, "Save", 444, -424, 86, function()
            if not Active() then return end
            if book.editRegion ~= Region() or book.editRuleset ~= Ruleset() then book.status:SetText("Character context changed. Cancel and select the contact again."); return end
            local key, message = self:SaveContact(book.key, book.name:GetText(), "", book.notes:GetText(), book.groupChanges)
            if key then
                local entry
                for _, value in ipairs(self:ContactList("all", "", nil, true)) do if value.key == key then entry = value; break end end
                book.unassigned = false
                self:EditContact(entry); self:RefreshBook()
            end
            book.status:SetText(message)
        end)
        book.cancel = Add(frame, "Cancel", 538, -424, 86, function()
            if not Active() then return end
            local entry
            local selectable = book.unassigned and self:List(true, "", nil, true) or self:ContactList("all", "", nil, true)
            for _, value in ipairs(selectable) do if book.entry and value.key == book.entry.key then entry = value; break end end
            self:EditContact(entry); self:RefreshBook()
        end)
        book.remove = Add(frame, "Remove", 632, -424, 90, function()
            if not Active() or not book.key or book.editRegion ~= Region() or book.editRuleset ~= Ruleset() then return end
            if book.confirm ~= book.key then book.confirm = book.key; book.remove.label:SetText("Confirm"); book.status:SetText("Delete this saved contact? Group memberships will also be removed.")
            elseif self:DeleteContact(book.key) then self:EditContact(); self:RefreshBook(); book.status:SetText("Contact removed.") end
        end)
        book.new = Add(frame, "New contact", 444, -484, 134, function()
            if not Active() then return end
            if book.dirty then book.status:SetText("Save or Cancel your changes first."); return end
            self:EditContact()
            if book.groupFilter and book.groupFilter:match("^custom:%d+$") then book.groupChanges[book.groupFilter] = true end
            self:UpdateBookDirty()
            self:RefreshBook()
        end)
        book.saveRecipient = Add(frame, "Save current To", 586, -484, 136, function()
            if not Active() then return end
            if book.dirty then book.status:SetText("Save or Cancel your changes first."); return end
            self:SaveRecipient()
        end)
        -- A multiline input may grow beyond its viewport; footer actions keep
        -- their own input above the edit child's full extent.
        for _, button in ipairs({ book.use, book.save, book.cancel, book.remove, book.new, book.saveRecipient }) do
            button:SetFrameLevel(book.notes:GetFrameLevel() + 1)
        end
        for _, field in ipairs({ "name", "notes" }) do
            book[field]:SetScript("OnTextChanged", function()
                if book.loading then return end
                self:UpdateBookDirty(); book.confirm = nil; book.remove.label:SetText("Remove"); self:RefreshBook()
            end)
        end
        local preferences = CreateFrame("Frame", nil, window); book.preferences = preferences
        preferences:SetSize(BOOK_WIDTH, 546); preferences:SetPoint("TOPLEFT", 0, -104); preferences:Hide()
        local hint = Text(preferences, 12, colors.muted); hint:SetPoint("TOPLEFT", 18, -18); hint:SetSize(704, 60); hint:SetWordWrap(true)
        hint:SetText("Choose what appears in contact rows. Sorting is remembered. Show, hide and reorder sidebar groups on the Groups tab; All contacts always remains available.")
        book.details = Add(preferences, "", 18, -96, 300, function()
            if InCombatLockdown() or not Shown(preferences) then return end
            local settings = self:GroupSettings(); settings.hideDetails = not (Suite.IsReadable(settings.hideDetails) and settings.hideDetails == true); self:RefreshBook()
        end)
        book.recovery = Add(preferences, "Recover unassigned contacts", 18, -152, 300, function()
            if InCombatLockdown() then return end
            if book.dirty then book.status:SetText("Save or Cancel your changes before recovering contacts."); return end
            book.unassigned = not book.unassigned; book.filter, book.groupFilter, book.page = nil, nil, 1
            book.search:SetText(""); self:EditContact(); self:SelectEditorTab("contacts")
        end)
        local recoveryHint = Text(preferences, 11, colors.muted); recoveryHint:SetPoint("TOPLEFT", 18, -198); recoveryHint:SetSize(704, 64); recoveryHint:SetWordWrap(true)
        recoveryHint:SetText("Older contacts with no server type stay separate. Review and Save each one to assign it to the current server type. Contacts on other known server types remain separate automatically.")
        book.events = CreateFrame("Frame"); book.events:SetScript("OnEvent", function() self:RefreshBookRoster() end)
        window:SetScript("OnHide", function()
            if book.mailbox and Suite.db.mailHelper and self.visit and Shown(MailFrame) and Shown(SendMailFrame)
                and not InCombatLockdown() and not self.choosingRecipient then self.dismissed = true end
            book.events:UnregisterAllEvents()
            if book.timer then book.timer:Cancel(); book.timer = nil end
            Suite.pending.mailBook = nil
            if not self.visit then self.guildEntries = nil end
            for _, field in ipairs({ "search", "name", "notes" }) do book[field]:ClearFocus() end
            book.confirm, self.confirm = nil, nil; book.remove.label:SetText("Remove")
            if self.groupEditor then self.groupEditor.name:ClearFocus(); self.groupEditor.search:ClearFocus(); self.groupEditor.confirm = nil; self.groupEditor.frame:Hide() end
        end)
        self.frame, self.search, self.rows = window, book.search, book.rows
        self.previous, self.next, self.count, self.empty, self.notice = book.previous, book.next, book.count, book.empty, book.status
        local settings = self:GroupSettings()
        self.sort = String(settings.sort, 16) and settings.sort == "level" and "level" or "name"
        self.ascending = not (Suite.IsReadable(settings.ascending) and settings.ascending == false)
        self:EditContact()
    end
    local book = self.book
    self.frame, self.search, self.rows, self.sortButtons = book.frame, book.search, book.rows, book.sortButtons
    self.previous, self.next, self.count, self.empty, self.notice = book.previous, book.next, book.count, book.empty, book.status
    if not wasShown then
        local width, height = UIParent:GetWidth(), UIParent:GetHeight()
        if Number(width, 100, 100000) and Number(height, 100, 100000) then
            book.frame:SetScale(math.min(1, (width - 24) / BOOK_WIDTH, (height - 24) / BOOK_HEIGHT))
        end
        book.mailbox = anchor == MailFrame and Shown(MailFrame) or nil
        self:PlaceBook(anchor)
    end
    self.dismissed = nil
    book.frame:Show(); book.frame:Raise()
    if tab ~= "groups" or self.groupEditor then self:SelectEditorTab(tab or "contacts") else book.content:Hide() end
    for _, event in ipairs({ "GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE", "CLUB_ADDED", "CLUB_REMOVED",
        "CLUB_STREAMS_LOADED", "CLUB_MEMBERS_UPDATED", "CLUB_MEMBER_ADDED", "CLUB_MEMBER_REMOVED",
        "CLUB_MEMBER_UPDATED", "PLAYER_ENTERING_WORLD", "GAME_RULES_CHANGED" }) do book.events:RegisterEvent(event) end
    if not self.visit and C_GuildInfo and type(C_GuildInfo.GuildRoster) == "function" then pcall(C_GuildInfo.GuildRoster) end
    self:ReadGuild(); self:RefreshBook()
end
