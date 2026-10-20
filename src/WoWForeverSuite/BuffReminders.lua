local _, Suite = ...
local Extra = { combatButtons = {} }
Suite.BuffReminders = Extra
table.insert(Suite.modules, Extra)
local function Read(v, kind) return Suite.IsReadable(v) and type(v) == kind end
local function Number(v) return Read(v, "number") and v == v and v >= 0 and v < math.huge end
local function ID(v) return Number(v) and v > 0 and v % 1 == 0 and v <= 2147483647 end
local function Text(v) return Read(v, "string") and #v > 0 and #v <= 240 and not v:find("[%c|]") end
local function Call(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function ClassForBuffs(unit)
    if type(UnitClass) ~= "function" then return end
    local ok,_,class=pcall(UnitClass,unit)
    if ok and Text(class) then return class end
end
local function Enabled() return Suite.db and Suite.db.missingBuffs == true end
local function ActiveCombat() return Enabled() and Suite.db.missingBuffCombat == true and InCombatLockdown() end
local function Surface(frame)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.035, 0.05, 0.065, 0.94); Suite.Theme:Backdrop(frame, 0.65)
end
local function Label(parent, size)
    local font = parent:CreateFontString(nil, "OVERLAY"); font:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
    font:SetTextColor(0.88, 0.91, 0.93); return font
end
local function Button(parent, text, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate"); Surface(button)
    button:SetPoint("TOPLEFT", x, y); button:SetSize(width, 26)
    button.label = Label(button, 11); button.label:SetPoint("CENTER"); button.label:SetText(text)
    button:SetScript("OnClick", callback); return button
end
function Extra:Custom(value)
    local result, seen = {}, {}
    if not Read(value, "table") then return result end
    local count = #value
    if not Number(count) or count > 8 then return result end
    for index = 1, count do
        local item = value[index]
        if Read(item, "table") and ID(item.id) and not seen[item.id] then
            result[#result + 1] = { id = item.id, group = Read(item.group, "boolean") and item.group or false }; seen[item.id] = true
        end
    end
    return result
end
function Extra:Warning(duration)
    return Number(duration) and duration >= 1800 and Suite.db.missingBuffWarning or 15
end
function Extra:Due(seconds)
    if Number(seconds) and seconds > 0 then self.nextDue = math.min(self.nextDue or math.huge, seconds) end
end
function Extra:AuraRecord(aura)
    return { name = aura.name, id = aura.spellId,
        duration = Number(aura.duration) and aura.duration or nil,
        expiry = Number(aura.expirationTime) and aura.expirationTime or nil }
end
function Extra:Presence(family, auras)
    if not auras then return end
    local now = Call(GetTime)
    if not Number(now) then return true end -- Unknown timing cannot authorize a refresh action.
    local found, remaining, covering = false, nil, nil
    for _, aura in ipairs(auras.records or {}) do
        if family.names[aura.name] or family.ids[aura.id] then
            found = true
            if not aura.expiry or aura.expiry == 0 or family.catalog.toggle then return true end
            local seconds = aura.expiry - now
            local warning = self:Warning(aura.duration)
            if seconds > warning then covering = math.max(covering or 0, seconds - warning) end
            remaining = math.max(remaining or 0, seconds)
        end
    end
    if covering then self:Due(covering + 0.05); return true end
    return false, found and remaining and remaining > 0 and remaining or nil
end
function Extra:AppendCustom(families, learned)
    local seen = {}
    for _, family in ipairs(families) do for name in pairs(family.names) do seen[name] = true end end
    for _, record in ipairs(Suite.db.missingBuffCustom or {}) do
        local reference = Suite.MissingBuffs:Spell(record.id)
        local spell = reference and learned[reference.name]
        if spell and not seen[spell.name] and Suite.db.missingBuffChoices["CUSTOM:" .. record.id] ~= 0 then
            local key = "CUSTOM:" .. record.id
            families[#families + 1] = { key = key, spell = spell,
                choices = { spell }, names = { [spell.name] = true }, ids = { [record.id] = true, [spell.id] = true },
                catalog = { key = key, roots = { record.id }, group = record.group, custom = true } }
            seen[spell.name] = true
        end
    end
end
function Extra:CoatingState(record)
    if not C_PaperDollInfo or type(C_PaperDollInfo.GetTemporaryEnchantmentInfo) ~= "function" then return end
    local weapon = Call(GetInventoryItemID, "player", record.slot)
    if not ID(weapon) or weapon ~= record.weapon then return end
    local ok, info = pcall(C_PaperDollInfo.GetTemporaryEnchantmentInfo, record.slot)
    if not ok or not Suite.IsReadable(info) then return end
    if info == nil then return true end
    if not Read(info, "table") or not Read(info.hasExpirationTime, "boolean") then return end
    if not info.hasExpirationTime or not Number(info.remainingTimeMs) then return false end
    local seconds = info.remainingTimeMs / 1000
    if Suite.db.missingBuffExpiry and seconds <= Suite.db.missingBuffWarning then return true, seconds end
    if Suite.db.missingBuffExpiry then self:Due(seconds - Suite.db.missingBuffWarning + 0.05) end
    return false
end
function Extra:CoatingItem(snapshot, entry, slot)
    if entry.item then
        if snapshot.pendingByID and snapshot.pendingByID[entry.item] then return nil, true end
        local item = snapshot.byID and snapshot.byID[entry.item]
        if item and item.family then
            local matching, _, pending = Suite.MacroItems:WeaponStone({ list = { item }, pending = snapshot.pending }, slot)
            return matching, pending
        end
        return item, false
    end
    local item, _, pending = Suite.MacroItems:WeaponStone(snapshot, slot)
    return item, pending
end
function Extra:CoatingChoices(snapshot, recipe, slot)
    local choices = {}
    for _, candidate in ipairs(Suite.MacroItems:Choices(snapshot, recipe)) do
        local compatible = self:CoatingItem(snapshot, { item = candidate.id }, slot)
        if compatible then choices[#choices + 1] = compatible end
    end
    return choices
end
function Extra:ChooseCoating(entry)
    if InCombatLockdown() or not Enabled() or not entry or entry.item then return end
    for _, choice in ipairs(Suite.macroDB and Suite.macroDB.entries or {}) do
        if choice.recipe == (entry.slot == 16 and "mainhand" or "offhand") then
            Suite.GUI.macroSelected = choice
            Suite.GUI:OpenPage("macros")
            return
        end
    end
end
function Extra:Prepare()
    if InCombatLockdown() or not Enabled() then return end
    local buffs = Suite.MissingBuffs
    self.watches, self.coatings = nil, nil
    if not Suite.db.missingBuffCombat and not Suite.db.missingBuffWeapons then return end
    self.watches, self.coatings = {}, {}
    if Suite.db.missingBuffCombat then
        if buffs.bookDirty then buffs.learned, buffs.learnedComplete = buffs:Learned(); buffs.bookDirty = false end
        local _, class
        if type(UnitClass) == "function" then local ok, localized, token = pcall(UnitClass, "player"); if ok and Text(token) then class = token end end
        if class then
            for _, family in ipairs(buffs:Families(class, buffs.learned or {})) do
                local catalog = family.catalog
                if family.spell and catalog.combat and not catalog.custom
                    and ((not catalog.group or catalog.upkeep) and Suite.db.missingBuffClass or catalog.group and Suite.db.missingBuffSelf or catalog.group and Suite.db.missingBuffOutgoing) then
                    self.watches[#self.watches + 1] = family
                end
            end
        end
    end
    if Suite.db.missingBuffWeapons then
        if buffs.itemsDirty or not buffs.items then buffs.items = Suite.MacroItems:Scan(); buffs.itemsDirty = false end
        local snapshot = buffs.items
        if snapshot and not snapshot.incomplete then
            for _, entry in ipairs(Suite.macroDB and Suite.macroDB.entries or {}) do
                local slot = entry.recipe == "mainhand" and 16 or entry.recipe == "offhand" and 17 or nil
                if slot then
                    local weapon = Call(GetInventoryItemID, "player", slot)
                    local ok, _, _, _, _, _, class
                    if ID(weapon) and C_Item and type(C_Item.GetItemInfoInstant) == "function" then
                        ok, _, _, _, _, _, class = pcall(C_Item.GetItemInfoInstant, weapon)
                    end
                    if ok and Number(class) and class == 2 then
                        local item, pending = self:CoatingItem(snapshot, entry, slot)
                        local choices = not item and self:CoatingChoices(snapshot, entry.recipe, slot) or nil
                        local display = item or choices and choices[1]
                        local icon = display and Call(C_Item.GetItemIconByID, display.id)
                        if not ID(icon) then icon = display and display.icon end
                        local name = item and item.name or choices and #choices > 0 and "Choose weapon coating"
                            or entry.item and Call(C_Item.GetItemNameByID, entry.item) or "Weapon coating"
                        local record = { kind = "coating", slot = slot, hand = slot == 16 and "MH" or "OH", weapon = weapon,
                            item = item, choices = choices, chosenID = entry.item, names = { slot == 16 and "Main hand" or "Off hand" },
                            spell = { name = Text(name) and name or "Weapon coating", icon = ID(icon) and icon or 134400 } }
                        if not pending then self.coatings[#self.coatings + 1] = record end
                    end
                end
            end
        end
    end
    if Suite.db.missingBuffCombat then self:BuildCombat() end
end
function Extra:AddCoatings(entries)
    if not Suite.db.missingBuffWeapons then return end
    for _, record in ipairs(self.coatings or {}) do
        local needed, remaining = self:CoatingState(record)
        if needed and (not InCombatLockdown() or record.item and not Suite.MissingBuffs.itemsDirty) then
            local entry = {}
            for key, value in pairs(record) do entry[key] = value end
            entry.remaining = remaining; entries[#entries + 1] = entry
        end
    end
end
function Extra:HasCoating(slot)
    if not Suite.db.missingBuffWeapons then return false end
    for _, record in ipairs(self.coatings or {}) do if record.slot == slot and (record.item or record.choices and #record.choices > 0) then return true end end
    return false
end
function Extra:CoatingClick(entry)
    local needed = self:CoatingState(entry)
    if not needed or not entry.item then return false end
    if not Suite.db.missingBuffWeapons then return false end
    local choice
    for _, candidate in ipairs(Suite.macroDB and Suite.macroDB.entries or {}) do
        if candidate.recipe == (entry.slot == 16 and "mainhand" or "offhand") then choice = candidate; break end
    end
    if not choice or choice.item ~= entry.chosenID then return false end
    local snapshot = Suite.MacroItems:Scan()
    if not snapshot or snapshot.incomplete then return false end
    local item = self:CoatingItem(snapshot, choice, entry.slot)
    return item and item.id == entry.item.id or false
end
function Extra:Cancel()
    self.token, self.combatToken = nil, nil
    if self.deadline then self.deadline:Cancel(); self.deadline = nil end
    if self.combatTimer then self.combatTimer:Cancel(); self.combatTimer = nil end
end
function Extra:Schedule()
    if self.deadline then self.deadline:Cancel(); self.deadline = nil end
    if not Enabled() or not self.nextDue or not C_Timer or type(C_Timer.NewTimer) ~= "function" then return end
    local token = {}; self.token = token
    self.deadline = C_Timer.NewTimer(math.max(0.2, self.nextDue), function()
        if self.token ~= token then return end
        self.deadline = nil
        if ActiveCombat() then self:RefreshCombat()
        elseif Enabled() and not InCombatLockdown() then Suite.MissingBuffs:Refresh() end
    end)
end
function Extra:Names(entry)
    local names = {}
    for index = 1, math.min(5, #entry.names) do names[#names + 1] = entry.names[index] end
    return table.concat(names, ", ") .. (#entry.names > 5 and (" +" .. (#entry.names - 5) .. " more") or "")
end
function Extra:Tooltip(button, combat)
    local entry = button.entry
    if not entry or not GameTooltip then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT"); GameTooltip:AddLine(entry.spell.name, 0.41, 0.84, 0.75)
    GameTooltip:AddLine(entry.remaining and ((#entry.names > 1 and "Missing or expiring within " or "Expiring within ") .. math.ceil(entry.remaining) .. " seconds") or "Missing", 1, 0.82, 0.4)
    GameTooltip:AddLine(self:Names(entry), 1, 1, 1, true)
    GameTooltip:AddLine(combat and "Reminder only. Refresh from your action bar during combat."
        or entry.item and "Left-click applies the selected coating. Native replacement rules apply."
        or "Carried coatings are available. Click to choose this hand's item in Macros.", 0.7, 0.8, 0.8, true)
    GameTooltip:Show()
end
function Extra:BuildCombat()
    if self.combatFrame or InCombatLockdown() then return end
    -- Independent, unprotected presentation. Never parent this to secure buff widgets.
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate"); self.combatFrame = frame
    frame:SetFrameStrata("LOW"); Surface(frame)
    local title = Label(frame, 11); title:SetPoint("TOP", 0, -6); title:SetText("BUFF REMINDERS")
    for index = 1, 8 do
        local button = CreateFrame("Frame", nil, frame, "BackdropTemplate"); Surface(button); button:SetSize(34, 34)
        button:EnableMouse(true)
        if button.SetMouseClickEnabled then button:SetMouseClickEnabled(false) end
        if button.SetMouseMotionEnabled then button:SetMouseMotionEnabled(true) end
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetPoint("TOPLEFT", 2, -2); button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
        button.caption = Label(button, 9); button.caption:SetPoint("TOP", button, "BOTTOM", 0, -2)
        button:SetScript("OnEnter", function() self:Tooltip(button, true) end)
        button:SetScript("OnLeave", function() if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(button) then GameTooltip:Hide() end end)
        button:SetScript("OnHide", button:GetScript("OnLeave"))
        self.combatButtons[index] = button
    end
    self:PlaceCombat(); frame:Hide()
end
function Extra:PlaceCombat()
    if not self.combatFrame or InCombatLockdown() then return end
    Suite.MissingBuffs:Place(self.combatFrame)
end
function Extra:CombatAuras(family, unit)
    local getter = C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName
    if type(getter) ~= "function" then return end
    local secrets = C_Secrets or {}
    local auras = { records = {} }
    for name in pairs(family.names) do
        local permitted
        if type(secrets.ShouldSpellAuraBeSecret) == "function" then permitted = Call(secrets.ShouldSpellAuraBeSecret, name) == false
        else permitted = Call(secrets.HasSecretRestrictions) == false end
        if not permitted then return end
        local ok, aura = pcall(getter, unit, name, "HELPFUL")
        if not ok or not Suite.IsReadable(aura) then return end
        if aura ~= nil then
            if not Read(aura, "table") or not Text(aura.name) or not ID(aura.spellId)
                or not (family.names[aura.name] or family.ids[aura.spellId]) then return end
            auras.records[#auras.records + 1] = self:AuraRecord(aura)
        end
    end
    return auras
end
function Extra:CombatUnits()
    local result, tokens = {}, { "player" }
    local raid = Call(IsInRaid)
    if not Read(raid, "boolean") then return result end
    local count = Call(raid and GetNumGroupMembers or GetNumSubgroupMembers)
    if not Number(count) or count % 1 ~= 0 or count > (raid and 40 or 4) then return result end
    for index = 1, count do tokens[#tokens + 1] = (raid and "raid" or "party") .. index end
    local seenPlayer = false
    for _, unit in ipairs(tokens) do
        local isPlayer = unit == "player" or Call(UnitIsUnit, unit, "player") == true
        if not (isPlayer and seenPlayer) and Call(UnitExists, unit) == true and Call(UnitIsConnected, unit) == true
            and Call(UnitIsVisible, unit) == true and Call(UnitIsDeadOrGhost, unit) == false then
            local name = Call(UnitName, unit)
            result[#result + 1] = { unit = unit, player = isPlayer, name = Text(name) and name or unit,
                party = isPlayer or Call(UnitInParty, unit) == true }
            if isPlayer then seenPlayer = true end
        end
    end
    return result
end
function Extra:RefreshCombat()
    if not self.combatFrame then return end
    if not ActiveCombat() or Call(UnitIsDeadOrGhost, "player") ~= false or (Call(IsResting) ~= false and Suite.db.missingBuffRested ~= true) then
        self.combatFrame:Hide(); return
    end
    self.nextDue = nil
    local entries, units = {}, self:CombatUnits()
    for _, family in ipairs(self.watches or {}) do
        local names, remaining = {}, nil
        for _, member in ipairs(units) do
            local catalog = family.catalog
            local selfFilter = (not catalog.group or catalog.upkeep) and Suite.db.missingBuffClass or catalog.group and Suite.db.missingBuffSelf
            if Suite.MissingBuffs:Relevant(catalog,ClassForBuffs(member.unit),family.spell.root or family.spell.id) and (member.player and selfFilter or not member.player and catalog.group and Suite.db.missingBuffOutgoing)
                and (not Suite.MissingBuffs:PartyOnly(catalog,family.spell.root or family.spell.id) or member.party) then
                local auras = self:CombatAuras(family, member.unit)
                local present, seconds
                if Suite.db.missingBuffExpiry then present, seconds = self:Presence(family, auras)
                elseif auras then
                    present = #auras.records > 0
                end
                if present == false then names[#names + 1] = member.name; if seconds then remaining = math.max(remaining or 0, seconds) end end
            end
        end
        if #names > 0 then entries[#entries + 1] = { spell = family.spell, names = names, remaining = remaining } end
    end
    self:AddCoatings(entries)
    local _,size=Suite.MissingBuffs:DisplayOptions()
    local stride,rowStride=size+9,size+14
    local count, width = math.min(#entries, 8), math.max(140, math.min(#entries, 8) * stride + 5)
    self.combatFrame:SetSize(width, 28 + math.ceil(count / 8) * rowStride)
    for index, button in ipairs(self.combatButtons) do
        local entry = index <= count and entries[index] or nil; button.entry = entry
        if entry then
            local row = math.floor((index - 1) / 8); local rowCount = math.min(8, count - row * 8)
            button:SetSize(size,size)
            button:ClearAllPoints(); button:SetPoint("TOPLEFT", (width - (rowCount * stride - 9)) / 2 + (index - 1) % 8 * stride, -25 - row * rowStride)
            button.icon:SetTexture(entry.spell.icon); button.caption:SetText(entry.hand or (entry.remaining and "Soon" or "Missing"))
        end
        button:SetShown(entry ~= nil)
    end
    self.combatEntries = entries; self.combatFrame:SetShown(count > 0); self:Schedule()
end
function Extra:OnEvent(event)
    if not Enabled() then return end
    if event == "PLAYER_REGEN_ENABLED" then
        self:Cancel(); if self.combatFrame then self.combatFrame:Hide() end; return
    end
    if event == "PLAYER_REGEN_DISABLED" then
        self:Cancel()
    end
    if ActiveCombat() and not self.combatTimer and C_Timer and C_Timer.NewTimer then
        local token = {}; self.combatToken = token
        self.combatTimer = C_Timer.NewTimer(0.15, function()
            if self.combatToken ~= token then return end
            self.combatTimer = nil; self:RefreshCombat()
        end)
    end
end
function Extra:AddCustom(text, group)
    if InCombatLockdown() or not Read(text, "string") or #text > 20 then return false end
    local id = tonumber(text:match("^%s*(%d+)%s*$"))
    if not ID(id) then return false end
    local entries = Suite.db.missingBuffCustom
    local candidate=Suite.MissingBuffs:Spell(id)
    for _,entry in ipairs(entries) do
        if entry.id==id then return false end
        local existing=Suite.MissingBuffs:Spell(entry.id)
        if candidate and existing and candidate.name==existing.name then return false end
    end
    if #entries >= 8 then return false end
    entries[#entries + 1] = { id = id, group = group == true }
    Suite.MissingBuffs.bookDirty = true; Suite.MissingBuffs:Queue(); self:RefreshOptions(); return true
end
function Extra:RefreshOptions()
    if Suite.BuffSettings.mode=="spells" then Suite.BuffSettings:Refresh() end
end
function Extra:OpenOptions()
    Suite.BuffSettings:Open("spells")
end
function Extra:Apply()
    if self.combatFrame then self.combatFrame:Hide() end
    if not Enabled() then
        self:Cancel(); self.combatToken = nil
        self.watches, self.coatings = nil, nil; Suite.pending.buffOptions = nil
        return
    end
    if not InCombatLockdown() then self:Prepare(); self:PlaceCombat(); self:Schedule()
    elseif Suite.db.missingBuffCombat then self:OnEvent("OPTIONS_CHANGED") end
end
