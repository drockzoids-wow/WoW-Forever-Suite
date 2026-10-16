local _, Suite = ...
local Mail = { rows = {}, page = 1, sort = "name", ascending = true }
Suite.Mail = Mail
table.insert(Suite.modules, Mail)

local PAGE_SIZE, WIDTH, HEIGHT = 6, 288, 474
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

local function RulesetFromServer(value)
    if not String(value, 64) then return end
    value = value:gsub("%s", ""):lower()
    -- These are server labels, not delivery addresses. Unknown labels stay unknown.
    value = value:match("^classicbeta(.+)$") or value:match("^classic(.+)$") or value:match("^forever(.+)$") or value
    return ({ pve = "PvE", pvp = "PvP", hardcore = "Hardcore", rp = "RP",
        rppvp = "RP-PvP", rppve = "RP-PvE", ["rp-pvp"] = "RP-PvP", ["rp-pve"] = "RP-PvE" })[value]
end

local function Ruleset()
    if C_GameRules and type(C_GameRules.IsHardcoreActive) == "function" then
        local active = C_GameRules.IsHardcoreActive()
        if Suite.IsReadable(active) and active == true then return "Hardcore" end
    end
    local value = GetNormalizedRealmName and GetNormalizedRealmName()
    if not String(value, 64) then value = GetRealmName and GetRealmName() end
    return RulesetFromServer(value)
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

local function Key(region, name, ruleset, guid)
    if guid then return tostring(region) .. ":guid:" .. guid end
    return tostring(region) .. ":name:" .. (ruleset or "?"):lower() .. ":" .. name:lower()
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
    frame:SetBackdropBorderColor(0.17, 0.25, 0.29)
end

local function Button(parent, width, label, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
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
        local migrated = { schema = 2, entries = {}, removed = {} }
        if Suite.IsReadable(db.entries) and type(db.entries) == "table" then
            for _, old in pairs(db.entries) do
                if Suite.IsReadable(old) and type(old) == "table" then
                    local entry, key = Entry(old.name, RulesetFromServer(old.realm), old.region,
                        old.guid, old.class, old.level, old.faction, true)
                    if key then migrated.entries[key] = entry end
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
        db = { schema = 2, entries = {}, removed = {} }; Suite.db.mailContacts = db
    end
    if not Suite.IsReadable(db.entries) or type(db.entries) ~= "table" then db.entries = {} end
    if not Suite.IsReadable(db.removed) or type(db.removed) ~= "table" then db.removed = {} end
    self.removed = db.removed
    return db.entries
end

function Mail:Store(name, ruleset, region, guid, class, level, faction, allowIncomplete)
    local entry, key = Entry(name, ruleset, region, guid, class, level, faction, allowIncomplete)
    if not key then return end
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
            local name = Name(entry.name, true)
            local ruleset = ValidRuleset(entry.ruleset) or RulesetFromServer(entry.realm)
            -- Seed once; removed contacts stay removed until that character is logged in again.
            local contacts = self:Database()
            local key = name and Key(region, name, ruleset, guid)
            local removed = key and self.removed[key]
            local oldRemoved = name and self.removed[Key(region, name, ruleset)]
            local existing = key and contacts[key]
            if key and Suite.IsReadable(existing) and existing == nil and Suite.IsReadable(removed) and removed ~= true
                and Suite.IsReadable(oldRemoved) and oldRemoved ~= true then
                self:Store(name, ruleset, region, guid, entry.class, nil, nil, true)
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

function Mail:List(includeCurrent)
    local result, region = {}, Region()
    if not region then return result end
    local query = Suite.IsReadable(self.query) and type(self.query) == "string" and self.query:lower() or ""
    for key, entry in pairs(self:Database()) do
        if Suite.IsReadable(key) and type(key) == "string" and Suite.IsReadable(entry) and type(entry) == "table"
            and Suite.IsReadable(entry.region) and entry.region == region then
            local normalized, expectedKey = Entry(entry.name, entry.ruleset, entry.region, entry.guid,
                entry.class, entry.level, entry.faction, true)
            local address, complete
            if normalized then address, complete = Name(normalized.name, true) end
            local current = normalized and self:IsCurrent(normalized)
            if normalized and key == expectedKey and (includeCurrent or not current)
                and (normalized.name .. " " .. (normalized.ruleset or "Unknown")):lower():find(query, 1, true) then
                result[#result + 1] = { key = key, name = normalized.name, ruleset = normalized.ruleset,
                    address = complete and address or nil, incomplete = not complete,
                    class = normalized.class, faction = normalized.faction, level = normalized.level,
                    current = current }
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

function Mail:Choose(key)
    if not String(key, 200) or InCombatLockdown() or not Suite.db.mailHelper or not self.visit or self.sendPending
        or not Shown(MailFrame) or not Shown(SendMailFrame) or not Field() or type(MailFrameTab_OnClick) ~= "function" then return end
    if Shown(SendMailFrameLockSendMail) then return end
    if MailFrameTab2 and not Shown(MailFrameTab2) then return end
    local enabled = Field().IsEnabled and Field():IsEnabled()
    if not Suite.IsReadable(enabled) or enabled == false then return end
    local chosen
    for _, entry in ipairs(self:List()) do if entry.key == key then chosen = entry; break end end
    if not chosen or chosen.current then return end
    MailFrameTab_OnClick(nil, 2)
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
    self.search:SetText("")
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
        if normalized then self.removed[Key(normalized.region, normalized.name, normalized.ruleset)] = true end
    end
    entries[key], self.removed[key] = nil, true
    if self.selected == key then self.selected = nil end
    self.confirm = nil
    self:Refresh()
end

function Mail:Place()
    if InCombatLockdown() or not self.frame or not Accessible(MailFrame) then return end
    local side = "RIGHT"
    if MailFrame.GetRect and MailFrame.GetEffectiveScale and UIParent.GetEffectiveScale then
        local left, _, width = MailFrame:GetRect()
        local scale, uiScale, screenWidth = MailFrame:GetEffectiveScale(), UIParent:GetEffectiveScale(), UIParent:GetWidth()
        if Number(left, -100000, 100000) and Number(width, 1, 100000) and Number(scale, 0.01, 100)
            and Number(uiScale, 0.01, 100) and Number(screenWidth, 1, 100000)
            and (left + width + WIDTH + 10) * scale > screenWidth * uiScale then side = "LEFT" end
    end
    self.frame:ClearAllPoints()
    if side == "LEFT" then self.frame:SetPoint("TOPRIGHT", MailFrame, "TOPLEFT", -10, 0)
    else self.frame:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 10, 0) end
end

function Mail:Create()
    if self.frame or InCombatLockdown() or not Accessible(MailFrame) then return end
    local frame = CreateFrame("Frame", nil, MailFrame, "BackdropTemplate")
    self.frame = frame
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetClampedToScreen(true)
    Fill(frame, colors.background)
    frame:EnableMouse(true)
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
        if not InCombatLockdown() and Number(delta, -100, 100) then
            self.page = self.page + (delta < 0 and 1 or -1); self:Refresh()
        end
    end)
    frame:SetScript("OnHide", function()
        if self.search and Accessible(self.search) then self.search:ClearFocus() end
        self.confirm = nil
    end)
    local title = Text(frame, 15)
    title:SetPoint("TOPLEFT", 14, -16); title:SetText("Mail contacts")
    local subtitle = Text(frame, 10, colors.muted)
    subtitle:SetPoint("TOPLEFT", 14, -39); subtitle:SetText("Your characters, one click away.")
    local settings = Button(frame, 26, "...", function() Suite.GUI:OpenPage("mail") end)
    settings:SetPoint("TOPRIGHT", -12, -12)
    local search = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
    self.search = search
    search:SetSize(260, 30); search:SetPoint("TOPLEFT", 14, -64)
    Fill(search)
    search:SetAutoFocus(false); search:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    search:SetTextInsets(9, 9, 0, 0); search:SetMaxLetters(77)
    search.placeholder = Text(search, 11, colors.muted)
    search.placeholder:SetPoint("LEFT", 9, 0); search.placeholder:SetText("Search name or ruleset")
    search:SetScript("OnTextChanged", function()
        if InCombatLockdown() then return end
        local text = search:GetText()
        self.query = Suite.IsReadable(text) and type(text) == "string" and text or ""
        self.page, self.confirm = 1, nil
        search.placeholder:SetShown(self.query == "")
        self:Refresh()
    end)
    search:SetScript("OnEscapePressed", function() search:ClearFocus(); search:SetText("") end)
    search:SetScript("OnEnterPressed", function() search:ClearFocus() end)
    self.sortButtons = {}
    for index, definition in ipairs({ { "name", "Name", 104 }, { "ruleset", "Ruleset", 88 }, { "level", "Level", 60 } }) do
        local key, label = definition[1], definition[2]
        local button = Button(frame, definition[3], label, function()
            if self.sort == key then self.ascending = not self.ascending
            else self.sort, self.ascending = key, key ~= "level" end
            self.page = 1; self:Refresh()
        end)
        button:SetPoint("TOPLEFT", 14 + (index == 1 and 0 or index == 2 and 108 or 200), -103)
        button.title = label; self.sortButtons[key] = button
    end
    for index = 1, PAGE_SIZE do
        local row = CreateFrame("Button", nil, frame, "BackdropTemplate")
        self.rows[index] = row
        row:SetSize(260, 42); row:SetPoint("TOPLEFT", 14, -135 - (index - 1) * 45)
        Fill(row)
        row.name = Text(row, 12); row.name:SetPoint("TOPLEFT", 10, -7); row.name:SetWidth(186)
        row.ruleset = Text(row, 9, colors.muted); row.ruleset:SetPoint("TOPLEFT", 10, -25); row.ruleset:SetWidth(208)
        row.level = Text(row, 10, colors.muted); row.level:SetPoint("TOPRIGHT", -30, -9)
        row.remove = Button(row, 20, "x", function() if row.entry then self:ConfirmRemove(row.entry.key) end end)
        row.remove:SetPoint("RIGHT", -4, 0)
        row:SetScript("OnClick", function() if row.entry then self:Choose(row.entry.key) end end)
        row:SetScript("OnEnter", function() row:SetBackdropColor(0.1, 0.17, 0.19) end)
        row:SetScript("OnLeave", function() if not InCombatLockdown() then self:Refresh() end end)
    end
    self.empty = Text(frame, 11, colors.muted)
    self.empty:SetPoint("TOPLEFT", 26, -154); self.empty:SetSize(234, 92)
    self.empty:SetWordWrap(true)
    self.previous = Button(frame, 30, "<", function() self.page = self.page - 1; self:Refresh() end)
    self.previous:SetPoint("TOPLEFT", 14, -409)
    self.next = Button(frame, 30, ">", function() self.page = self.page + 1; self:Refresh() end)
    self.next:SetPoint("TOPRIGHT", -14, -409)
    self.count = Text(frame, 10, colors.muted); self.count:SetPoint("TOP", 0, -416)
    self.save = Button(frame, 120, "Save recipient", function() self:SaveRecipient() end)
    self.save:SetPoint("BOTTOMLEFT", 14, 12)
    self.notice = Text(frame, 9, colors.muted); self.notice:SetPoint("BOTTOMRIGHT", -14, 20)
    self.notice:SetWidth(130); self.notice:SetHeight(24); self.notice:SetWordWrap(true); self.notice:SetJustifyH("RIGHT")
    self.confirmation = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    self.confirmation:SetSize(260, 58); self.confirmation:SetPoint("BOTTOMLEFT", 14, 10)
    self.confirmation:EnableMouse(true)
    Fill(self.confirmation, colors.background)
    self.confirmation.label = Text(self.confirmation, 10)
    self.confirmation.label:SetPoint("TOPLEFT", 8, -6); self.confirmation.label:SetWidth(244)
    self.confirmation.remove = Button(self.confirmation, 112, "Remove contact", function() self:RemoveConfirmed() end)
    self.confirmation.remove:SetPoint("BOTTOMLEFT", 6, 5)
    self.confirmation.cancel = Button(self.confirmation, 112, "Cancel", function() self.confirm = nil; self:Refresh() end)
    self.confirmation.cancel:SetPoint("BOTTOMRIGHT", -6, 5)
    frame:Hide()
end

function Mail:Refresh()
    if InCombatLockdown() or not self.frame or not Suite.db.mailHelper then return end
    local entries = self:List()
    local pages = math.max(1, math.ceil(#entries / PAGE_SIZE))
    self.page = math.max(1, math.min(self.page, pages))
    for key, button in pairs(self.sortButtons) do
        -- Keep direction markers in the header font's basic character set.
        button.label:SetText(button.title .. (self.sort == key and (self.ascending and " ^" or " v") or ""))
        button.label:SetTextColor(unpack(self.sort == key and colors.accent or colors.muted))
    end
    for index, row in ipairs(self.rows) do
        local entry = entries[(self.page - 1) * PAGE_SIZE + index]
        row.entry = entry
        row:SetShown(entry ~= nil)
        if entry then
            row.name:SetText(entry.name)
            local color = RAID_CLASS_COLORS and entry.class and RAID_CLASS_COLORS[entry.class]
            if Suite.IsReadable(color) and type(color) == "table" and Number(color.r, 0, 1)
                and Number(color.g, 0, 1) and Number(color.b, 0, 1) then row.name:SetTextColor(color.r, color.g, color.b)
            else row.name:SetTextColor(unpack(colors.text)) end
            row.ruleset:SetText((entry.ruleset or "Unknown ruleset") .. (entry.incomplete and "  ·  Add last name"
                or entry.faction and "  ·  " .. entry.faction or ""))
            row.level:SetText(entry.level and tostring(entry.level) or "—")
            row:SetEnabled(not entry.current and not self.sendPending)
            row.remove:SetEnabled(not entry.current)
            row.remove.label:SetTextColor(unpack(entry.current and colors.muted or colors.accent))
            Fill(row, entry.key == self.selected and { 0.1, 0.2, 0.21 } or colors.row)
        end
    end
    self.empty:SetShown(#entries == 0)
    self.empty:SetText(self.query and self.query ~= "" and "No matching contacts.\nTry another name or ruleset."
        or "Log into your alts with Mail contacts enabled, or enter first and last name in To and save it here.")
    self.count:SetText(#entries .. " contacts  ·  " .. self.page .. " / " .. pages)
    self.previous:SetEnabled(self.page > 1); self.next:SetEnabled(self.page < pages)
    self.previous.label:SetTextColor(unpack(self.page > 1 and colors.accent or colors.muted))
    self.next.label:SetTextColor(unpack(self.page < pages and colors.accent or colors.muted))
    local confirmation
    for _, entry in ipairs(entries) do if entry.key == self.confirm then confirmation = entry end end
    self.confirmation:SetShown(confirmation ~= nil)
    if confirmation then self.confirmation.label:SetText("Remove " .. confirmation.name .. "?") end
    self.save:SetShown(confirmation == nil); self.notice:SetShown(confirmation == nil)
    self:SetNotice(self.sendPending and "Sending…" or "Click a name to fill To.")
end

function Mail:EndVisit()
    self.visit, self.sendPending, self.pendingRecipient, self.lastRecipient = nil, nil, nil, nil
    self.selected, self.confirm, self.query, self.page = nil, nil, "", 1
    self.nameAttempts = nil
    self:Cancel()
    Suite.pending.mailRecipient = nil
    if self.frame and Accessible(self.frame) then self.frame:Hide() end
end

function Mail:BeginVisit()
    if not self.active or not Shown(MailFrame) then return end
    self.visit = true
    if InCombatLockdown() then self:Schedule(); return end
    if not Suite.db.mailHelper or not Shown(SendMailFrame) then
        if self.frame and Accessible(self.frame) then self.frame:Hide() end
        return
    end
    self:SeedRecordedCharacters(); self:ResolveRecordedNames(); self:Create()
    if not self.frame then return end
    local text = self.search:GetText()
    if Suite.IsReadable(text) and text ~= (self.query or "") then self.search:SetText(self.query or "") end
    self:Place(); self:Refresh(); self.frame:Show()
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
            if self.active and self.frame and Accessible(self.frame) then self.frame:Hide() end
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
    if not Suite.db.mailHelper and not Suite.db.mailRememberRecipient then
        self.active = nil; self:EndVisit(); Suite.pending.mail = nil
        if self.events then self.events:UnregisterAllEvents() end
        return
    end
    if not Suite.db.mailRememberRecipient then self.lastRecipient = nil; Suite.pending.mailRecipient = nil end
    if not Suite.db.mailHelper and self.frame and Accessible(self.frame) then self.frame:Hide() end
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
                "MAIL_SHOW", "MAIL_CLOSED", "PLAYER_REGEN_DISABLED" }) do
                self.events:RegisterEvent(event)
            end
        end
        self:RecordPlayer(); self:Bind(); self:BeginVisit()
    end)
end
