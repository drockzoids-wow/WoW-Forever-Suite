local _, Suite = ...
local Buffs = { buttons = {}, requested = {}, notices = {}, noticeTimes = {}, bookDirty = true, itemsDirty = true }
Suite.MissingBuffs = Buffs
table.insert(Suite.modules, Buffs)
local function Read(value, kind) return Suite.IsReadable(value) and type(value) == kind end
local function Number(value) return Read(value, "number") and value == value and math.abs(value) < math.huge end
local function ID(value) return Number(value) and value > 0 and value % 1 == 0 end
local function Text(value) return Read(value, "string") and #value > 0 and not value:find("[%c|]") end
local function Call(callback, ...)
    if type(callback) ~= "function" then return end
    local ok, value = pcall(callback, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Enabled() return Suite.db and Read(Suite.db.missingBuffs, "boolean") and Suite.db.missingBuffs end
local function Surface(frame)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.035, 0.05, 0.065, 0.94)
    Suite.Theme:Backdrop(frame, 0.65)
end
local function Label(parent, size)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
    label:SetTextColor(0.88, 0.91, 0.93)
    return label
end
local function HideTooltip(owner)
    if GameTooltip and type(GameTooltip.IsOwned) == "function" and GameTooltip:IsOwned(owner) then GameTooltip:Hide() end
end
local function Class(unit)
    if type(UnitClass) ~= "function" then return end
    local ok, _, class = pcall(UnitClass, unit)
    if ok and Text(class) then return class end
end

function Buffs:InitializeChoices(value, custom)
    local result = {}
    if not Read(value, "table") then return result end
    for _, family in ipairs(Suite.BuffCatalog) do
        local key = family.class .. ":" .. family.key
        local chosen = value[key]
        if Number(chosen) and chosen == 0 then result[key] = 0
        elseif ID(chosen) then result[key] = chosen end
    end
    for _, record in ipairs(Suite.BuffReminders:Custom(custom)) do
        local key = "CUSTOM:" .. record.id
        if Number(value[key]) and value[key] == 0 then result[key] = 0 end
    end
    for _, hand in ipairs({ "main", "off" }) do
        local key = "ROGUE:poison:" .. hand
        if ID(value[key]) then result[key] = value[key] end
    end
    return result
end

function Buffs:Context()
    if InCombatLockdown() then return false end
    local resting = Call(IsResting)
    return (resting == false or resting == true and Suite.db.missingBuffRested == true)
        and Call(UnitIsDeadOrGhost, "player") == false
end

function Buffs:Unit(unit)
    if Call(UnitExists, unit) ~= true or Call(UnitIsConnected, unit) ~= true
        or Call(UnitIsVisible, unit) ~= true or Call(UnitIsDeadOrGhost, unit) ~= false then return end
    if unit ~= "player" and Call(UnitCanAssist, "player", unit) ~= true then return end
    if C_Secrets and type(C_Secrets.ShouldUnitIdentityBeSecret) == "function"
        and Call(C_Secrets.ShouldUnitIdentityBeSecret, unit) ~= false then return end
    local guid, name, class, level = Call(UnitGUID, unit), Call(UnitName, unit), Class(unit), Call(UnitLevel, unit)
    if not Text(guid) or not Text(name) or not class or not ID(level) then return end
    return { unit = unit, guid = guid, name = name, class = class, level = level,
        party = unit == "player" or Call(UnitInParty, unit) == true }
end

function Buffs:Roster()
    local list, seen = {}, {}
    local player = self:Unit("player")
    if not player then return list end
    list[1], seen[player.guid] = player, true
    local raid = Call(IsInRaid)
    if not Read(raid, "boolean") then return list end
    local count = raid and Call(GetNumGroupMembers) or Call(GetNumSubgroupMembers)
    if not Number(count) or count < 0 or count % 1 ~= 0 or count > (raid and 40 or 4) then return list end
    for index = 1, count do
        local member = self:Unit((raid and "raid" or "party") .. index)
        if member and not seen[member.guid] then list[#list + 1], seen[member.guid] = member, true end
    end
    return list
end

function Buffs:Auras(unit)
    if InCombatLockdown() or not C_UnitAuras or type(C_UnitAuras.GetAuraDataByIndex) ~= "function" then return end
    local present = { names = {}, ids = {}, records = {} }
    for index = 1, 255 do
        if C_Secrets and type(C_Secrets.ShouldUnitAuraIndexBeSecret) == "function"
            and Call(C_Secrets.ShouldUnitAuraIndexBeSecret, unit, index, "HELPFUL") ~= false then return end
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, "HELPFUL")
        if not ok or not Suite.IsReadable(aura) then return end
        if aura == nil then return present end
        if not Read(aura, "table") or not Text(aura.name) or not ID(aura.spellId) then return end
        present.names[aura.name], present.ids[aura.spellId] = true, true
        if Suite.db.missingBuffExpiry then present.records[#present.records + 1] = Suite.BuffReminders:AuraRecord(aura) end
    end
    -- A truncated scan cannot establish that a buff is absent.
end

function Buffs:Spell(id)
    if not ID(id) or not C_Spell then return end
    local info = Call(C_Spell.GetSpellInfo, id)
    if not Read(info, "table") or not Text(info.name) or not ID(info.iconID) then
        if not self.requested[id] and type(C_Spell.RequestLoadSpellData) == "function" then
            self.requested[id] = true; pcall(C_Spell.RequestLoadSpellData, id)
        end
        return
    end
    return { id = id, name = info.name, icon = info.iconID }
end

function Buffs:Learned()
    local book, byName = C_SpellBook, {}
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    local spellType = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell
    if not book or not Number(bank) or not Number(spellType) then return byName, false end
    local count = Call(book.GetNumSpellBookSkillLines)
    if not Number(count) or count < 0 or count > 32 or count % 1 ~= 0 then return byName, false end
    local complete = true
    for line = 1, count do
        local info = Call(book.GetSpellBookSkillLineInfo, line)
        if Read(info, "table") and Number(info.itemIndexOffset) and Number(info.numSpellBookItems)
            and info.itemIndexOffset >= 0 and info.itemIndexOffset % 1 == 0 and info.numSpellBookItems >= 0
            and info.numSpellBookItems <= 512 and info.numSpellBookItems % 1 == 0 and info.itemIndexOffset <= 4096 then
            for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
                local entry = Call(book.GetSpellBookItemInfo, slot, bank)
                if not Read(entry, "table") or not Number(entry.itemType) then complete = false
                elseif entry.itemType == spellType then
                    if not Read(entry.isPassive, "boolean") or not Read(entry.isOffSpec, "boolean") or not ID(entry.spellID) then complete = false
                    elseif not entry.isPassive and not entry.isOffSpec then
                        local known = Call(book.IsSpellKnown, entry.spellID, bank)
                        if known == true then
                            local spell = self:Spell(entry.spellID)
                            if spell then
                                local level = Call(book.GetSpellBookItemLevelLearned, slot, bank)
                                spell.level = Number(level) and level >= 0 and level or 0
                                local previous = byName[spell.name]
                                if not previous or spell.level >= previous.level then byName[spell.name] = spell end
                            else complete = false end
                        elseif known ~= false then complete = false end
                    end
                end
            end
        else complete = false end
    end
    return byName, complete
end

function Buffs:Families(class, learned)
    local families = {}
    for _, catalog in ipairs(Suite.BuffCatalog) do
        if catalog.class == class and (not catalog.extra or Suite.db.missingBuffCombat) then
            local family = { key = class .. ":" .. catalog.key, catalog = catalog, names = {}, ids = {}, choices = {} }
            local seen = {}
            for _, root in ipairs(catalog.roots) do
                local spell = self:Spell(root)
                family.ids[root] = true
                if spell then
                    family.names[spell.name] = true
                    local known = learned[spell.name]
                    if known and not seen[known.id] then
                        known.root = root
                        family.choices[#family.choices + 1], seen[known.id] = known, true
                    end
                end
            end
            for _, auraID in ipairs(catalog.auras or {}) do
                family.ids[auraID] = true
                local aura = self:Spell(auraID)
                if aura then family.names[aura.name] = true end
            end
            local chosen = Suite.db.missingBuffChoices[family.key]
            if chosen ~= 0 then
                family.spell = family.choices[1]
                for _, spell in ipairs(family.choices) do
                    if chosen == spell.id or chosen == spell.root then family.spell = spell; break end
                end
            end
            families[#families + 1] = family
        end
    end
    Suite.BuffReminders:AppendCustom(families, learned)
    return families
end

-- Class capabilities stay stable while a Druid changes form. Forever Hunters use Mana.
local manaClasses = {MAGE=true,PRIEST=true,WARLOCK=true,HUNTER=true,PALADIN=true,SHAMAN=true,DRUID=true}
local physicalClasses = {WARRIOR=true,ROGUE=true,HUNTER=true,PALADIN=true,SHAMAN=true,DRUID=true}
function Buffs:Relevant(catalog, class, root)
    if not Text(class) or not Read(catalog,"table") then return false end
    if Suite.db.missingBuffSmart == false then return true end
    if catalog.mana or catalog.manaRoots and catalog.manaRoots[root] then return manaClasses[class] == true end
    if catalog.physical or catalog.physicalRoots and catalog.physicalRoots[root] then return physicalClasses[class] == true end
    return true
end
function Buffs:PartyOnly(catalog,root)
    if catalog.partyRoots then return catalog.partyRoots[root] == true end
    return catalog.party == true
end
function Buffs:Recipient(family,class)
    family.recipients = family.recipients or {}
    if family.recipients[class] then return family.recipients[class] end
    local result={key=family.key,catalog=family.catalog,names={},ids={},choices={}}
    if family.catalog.custom then return family end
    for index,root in ipairs(family.catalog.roots) do
        if self:Relevant(family.catalog,class,root) then
            result.ids[root]=true
            local spell=self:Spell(root)
            if spell then result.names[spell.name]=true end
            local auraID=family.catalog.auras and family.catalog.auras[index]
            if auraID then
                result.ids[auraID]=true
                local aura=self:Spell(auraID);if aura then result.names[aura.name]=true end
            end
        end
    end
    local chosen=Suite.db.missingBuffChoices[family.key]
    for _,spell in ipairs(family.choices) do
        if self:Relevant(family.catalog,class,spell.root or spell.id) then
            result.choices[#result.choices+1]=spell
            if chosen == nil and not result.spell or chosen == spell.id or chosen == spell.root then result.spell=spell end
        end
    end
    family.recipients[class]=result
    return result
end
function Buffs:DisplayOptions(db)
    db=db or Suite.db or {}
    local scale,size=db.missingBuffScale,db.missingBuffIconSize
    if not Number(scale) or scale < 0.7 or scale > 1.5 then scale=1 end
    if not Number(size) or size < 24 or size > 48 then size=34 end
    return scale,math.floor(size)
end

function Buffs:Present(family, auras, expiry)
    if not auras then return nil end
    if expiry and Suite.db.missingBuffExpiry and auras.records then return Suite.BuffReminders:Presence(family, auras) end
    for name in pairs(family.names) do if auras.names[name] then return true end end
    for id in pairs(family.ids) do if auras.ids[id] then return true end end
    return false
end

function Buffs:Weapon(slot, weaponSlot, requireImbue)
    if not C_Item or not Enum or not Enum.ItemEnchantType or not Number(weaponSlot) then return end
    local id = Call(GetInventoryItemID, "player", slot)
    if not ID(id) or type(C_Item.GetItemInfoInstant) ~= "function" then return end
    local ok, _, _, _, equip, _, class = pcall(C_Item.GetItemInfoInstant, id)
    if not ok or not Number(class) or class ~= 2 or not Text(equip) then return end
    local enchants = Call(C_Item.GetWeaponEnchantInfo, weaponSlot)
    if not Read(enchants, "table") then return end
    local temporary, imbue = Enum.ItemEnchantType.Temporary, Enum.ItemEnchantType.Imbue
    if not Number(temporary) or not Number(imbue) then return end
    for _, enchant in pairs(enchants) do
        if not Read(enchant, "table") or not Read(enchant.hasEnchant, "boolean") or not Number(enchant.enchantType) then return end
        if enchant.hasEnchant and (enchant.enchantType == imbue or not requireImbue and enchant.enchantType == temporary) then return true end
    end
    return false
end

function Buffs:PoisonChoices()
    if self.itemsDirty then
        self.itemsDirty = false
        self.items = Suite.MacroItems:Scan()
    end
    local choices, names = {}, {}
    for _, id in ipairs({ 8679, 2823, 13219, 3408, 5761 }) do
        local spell = self:Spell(id)
        if spell then names[spell.name] = true end
    end
    for _, item in ipairs(self.items and self.items.list or {}) do
        -- Reuse Suite's guarded carried-item metadata, never a hardcoded bag slot.
        if item.class == 0 and item.subclass == 6 then
            local useSpell = C_Item and Call(C_Item.GetItemSpell, item.id)
            if Text(useSpell) and names[useSpell] or item.name:lower():find("poison", 1, true) then choices[#choices + 1] = item end
        end
    end
    return choices
end

function Buffs:Collect()
    if not Enabled() or not self:Context() then return {} end
    local entries, roster = {}, self:Roster()
    local player = roster[1]
    if not player then return entries end
    if self.bookDirty then self.learned, self.learnedComplete = self:Learned(); self.bookDirty = false end
    local families = self:Families(player.class, self.learned or {})
    self.weaponBuffAvailable, self.poisonOptionsAvailable = false, false
    for _, family in ipairs(families) do
        if family.catalog.weapon and #family.choices > 0 then self.weaponBuffAvailable = true end
    end
    local scanGroup, auras = false, { player = self:Auras("player") }
    for _, family in ipairs(families) do if family.spell and family.catalog.group and Suite.db.missingBuffOutgoing then scanGroup = true end end
    if scanGroup then for index = 2, #roster do auras[roster[index].unit] = self:Auras(roster[index].unit) end end
    for _, family in ipairs(families) do
        local personalFamily = self:Recipient(family,player.class)
        local spell, catalog = personalFamily.spell, family.catalog
        if spell then
            local personal = not catalog.group or catalog.upkeep
            local present, remaining = self:Present(personalFamily, auras.player, true)
            if catalog.weapon then
                if Suite.BuffReminders:HasCoating(16) then present = true
                else present = self:Weapon(16, Enum and Enum.WeaponSlot and Enum.WeaponSlot.MainHand, true) end
            end
            if (personal and Suite.db.missingBuffClass or not personal and Suite.db.missingBuffSelf) and present == false then
                entries[#entries + 1] = { kind = "self", family = personalFamily, spell = spell, unit = "player", guid = player.guid, names = { player.name }, remaining = remaining }
            end
        end
        if catalog.group and Suite.db.missingBuffOutgoing and #family.choices > 0 then
            local buckets,ordered={},{}
            for index=2,#roster do
                local member=roster[index]
                local recipient=self:Recipient(family,member.class)
                local action=recipient.spell
                local covered,seconds=self:Present(recipient,auras[member.unit],true)
                if action and (not self:PartyOnly(catalog,action.root or action.id) or member.party) and covered == false then
                    local range=C_Spell and Call(C_Spell.IsSpellInRange,action.id,member.unit)
                    if range ~= false then
                        local bucket=buckets[action.id]
                        if not bucket then bucket={spell=action,family=recipient,members={}};buckets[action.id]=bucket;ordered[#ordered+1]=bucket end
                        bucket.members[#bucket.members+1]={member=member,remaining=seconds}
                    end
                end
            end
            for _,bucket in ipairs(ordered) do
                local names,soon={},nil
                for _,item in ipairs(bucket.members) do names[#names+1]=item.member.name;if item.remaining then soon=math.max(soon or 0,item.remaining) end end
                local missing=bucket.members[1].member
                local target=catalog.party and player or missing
                local present=self:Present(personalFamily,auras.player,true)
                local passive=catalog.toggle and present ~= false
                entries[#entries+1]={kind="group",family=bucket.family,spell=bucket.spell,unit=not passive and target.unit or nil,
                    guid=target.guid,names=names,passive=passive,checkUnit=missing.unit,checkGUID=missing.guid,remaining=soon}
            end
        end
    end
    if Suite.db.missingBuffIncoming and auras.player then
        local seen = {}
        local incomingFamilies = {}
        for _, family in ipairs(families) do
            if #family.choices > 0 then seen[family.key] = true end
        end
        for index = 2, #roster do
            local provider = roster[index]
            if not incomingFamilies[provider.class] then incomingFamilies[provider.class] = self:Families(provider.class, {}) end
            for _, family in ipairs(incomingFamilies[provider.class]) do
                local catalog = family.catalog
                local recipient=self:Recipient(family,player.class)
                local present,remaining=self:Present(recipient,auras.player,true)
                if catalog.incoming and Suite.db.missingBuffChoices[family.key] ~= 0
                    and not seen[family.key] and (provider.class ~= player.class or self.learnedComplete == true)
                    and present == false then
                    local spell
                    for _,root in ipairs(catalog.roots) do
                        if self:Relevant(catalog,player.class,root) and (not self:PartyOnly(catalog,root) or provider.party) then
                            local candidate=self:Spell(root)
                            local level=candidate and C_Spell and Call(C_Spell.GetSpellLevelLearned,candidate.id)
                            if Number(level) and level >= 0 and level % 1 == 0
                                and provider.level >= math.max(level,catalog.minimum or 1) then spell=candidate;break end
                        end
                    end
                    if spell then
                        entries[#entries+1]={kind="incoming",spell=spell,names={provider.name},family=recipient,passive=true,remaining=remaining}
                        seen[family.key]=true
                    end
                end
            end
        end
    end
    if player.class == "ROGUE" and Suite.db.missingBuffClass then
        local choices = self:PoisonChoices()
        self.poisonOptionsAvailable = #choices > 0
        local trained = C_SpellBook and Call(C_SpellBook.IsSpellKnown, 2842) == true
        if trained or #choices > 0 then
            for _, hand in ipairs({ { "main", 16, "MainHand", "MH" }, { "off", 17, "OffHand", "OH" } }) do
                if not Suite.BuffReminders:HasCoating(hand[2]) and self:Weapon(hand[2], Enum and Enum.WeaponSlot and Enum.WeaponSlot[hand[3]], true) == false then
                    local key, chosen = "ROGUE:poison:" .. hand[1], nil
                    local id = Suite.db.missingBuffChoices[key]
                    for _, item in ipairs(choices) do if item.id == id then chosen = item; break end end
                    local display = chosen or choices[1]
                    local icon = display and C_Item and Call(C_Item.GetItemIconByID, display.id)
                    entries[#entries + 1] = { kind = "poison", key = key, choices = choices, item = chosen, slot = hand[2], hand = hand[4],
                        spell = { name = chosen and chosen.name or "Choose poison", icon = ID(icon) and icon or 132273 }, names = { hand[4] },
                        unknownItems = not self.items or self.items.incomplete == true }
                end
            end
        end
    end
    Suite.BuffReminders:AddCoatings(entries)
    return entries
end

-- Local notices never broadcast requests. Keep unavailable supplies off the action bar.
function Buffs:Route(entries)
    local display, notices = {}, {}
    for _, entry in ipairs(entries) do
        if entry.kind == "incoming" then
            display[#display + 1] = entry
            if self.learnedComplete == true then notices[#notices + 1] = entry end
        elseif entry.kind == "coating" or entry.kind == "poison" then
            local choices = entry.choices
            if entry.item or choices and #choices > 0 then display[#display + 1] = entry
            elseif self.learnedComplete == true and not entry.unknownItems and not (entry.slot == 16 and self.weaponBuffAvailable)
                and not self.poisonOptionsAvailable then notices[#notices + 1] = entry end
        else display[#display + 1] = entry end
    end
    return display, notices
end
function Buffs:Notify(entries)
    local active, lines, now = {}, {}, Call(GetTime)
    for _, entry in ipairs(entries) do
        local key, message
        if entry.kind == "incoming" then
            key = entry.family.key
            message = entry.spell.name .. " (a group member may provide it)"
        else
            key = "weapon:" .. entry.slot
            message = (entry.slot == 16 and "Main-hand" or "Off-hand") .. (entry.remaining and " weapon buff expires soon" or " weapon buff is missing")
                .. " (carry or choose compatible supplies)"
        end
        if self.notices[key] then active[key] = true
        elseif not active[key] and Number(now) and now >= 0 then
            local last = self.noticeTimes[key]
            if not Number(last) or now - last >= 60 then
                lines[#lines + 1] = message
                active[key], self.noticeTimes[key] = true, now
            end
        end
    end
    self.notices = active
    if #lines > 0 then Suite.Print("Missing buffs: " .. table.concat(lines, "; ") .. ".") end
end

function Buffs:Place(frame)
    if InCombatLockdown() then return end
    local saved = Suite.db.missingBuffPosition
    local scale = self:DisplayOptions()
    frame:SetScale(scale)
    frame:ClearAllPoints()
    if Read(saved, "table") and Number(saved.x) and Number(saved.y) and math.abs(saved.x) <= 0.5 and math.abs(saved.y) <= 0.5 then
        frame:SetPoint("CENTER", UIParent, "CENTER", saved.x * UIParent:GetWidth(), saved.y * UIParent:GetHeight())
    else frame:SetPoint("TOP", UIParent, "TOP", 0, -140) end
end

function Buffs:StopMoving(frame)
    if not frame.moving then return end
    if InCombatLockdown() and frame == self.bar then self.cancelMove = true; return end
    frame:StopMovingOrSizing(); frame.moving = nil
    if self.cancelMove then self.cancelMove = nil; self:Place(frame); return end
    local x, y = frame:GetCenter()
    local scale, parentScale = frame:GetEffectiveScale(), UIParent:GetEffectiveScale()
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    if Number(x) and Number(y) and Number(scale) and Number(parentScale) and parentScale > 0
        and Number(width) and Number(height) and width > 0 and height > 0 then
        local ratio = scale / parentScale
        Suite.db.missingBuffPosition = { x = math.max(-0.5, math.min(0.5, (x * ratio - width / 2) / width)),
            y = math.max(-0.5, math.min(0.5, (y * ratio - height / 2) / height)) }
    end
end

function Buffs:Header(frame, title)
    frame:SetMovable(true); frame:SetClampedToScreen(true)
    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", 1, -1); header:SetPoint("TOPRIGHT", -1, -1); header:SetHeight(21)
    header:EnableMouse(true); header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function()
        if InCombatLockdown() or Suite.db.missingBuffLocked then return end
        frame.moving = true; frame:StartMoving()
    end)
    header:SetScript("OnDragStop", function() self:StopMoving(frame) end)
    header:SetScript("OnHide", function() self:StopMoving(frame) end)
    header:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" and not Suite.db.missingBuffLocked and IsControlKeyDown() then self:ResetPosition() end
    end)
    local caption = Label(header, 10); caption:SetPoint("CENTER"); caption:SetJustifyH("CENTER"); caption:SetText(title)
    header.caption = caption
    return header
end

function Buffs:Build()
    if self.bar then return true end
    if InCombatLockdown() or type(RegisterStateDriver) ~= "function" then return false end
    local controller = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
    local bar = CreateFrame("Frame", nil, controller, "SecureHandlerBaseTemplate,BackdropTemplate")
    self.controller, self.bar = controller, bar
    bar:SetFrameStrata("MEDIUM"); bar:SetSize(242, 70); Surface(bar); self:Place(bar)
    self.header = self:Header(bar, "MISSING BUFFS")
    bar:Hide()
    controller:SetFrameRef("bar", bar)
    controller:SetAttribute("_onstate-combat", [[
        if newstate == "combat" then
            self:GetFrameRef("bar"):Hide()
            self:Hide()
        else
            self:Show()
        end
    ]])
    RegisterStateDriver(controller, "combat", "[combat] combat; peaceful")
    return true
end

function Buffs:Cycle(entry)
    if InCombatLockdown() or not entry then return end
    if entry.kind == "incoming" then Suite.db.missingBuffChoices[entry.family.key] = 0; self:Queue(); return end
    local key, choices = entry.key or entry.family.key, entry.choices or entry.family.choices
    local current = Suite.db.missingBuffChoices[key]
    local nextID = choices[1] and choices[1].id or nil
    for index, choice in ipairs(choices) do
        if current == choice.id or not current and entry.spell.id == choice.id then
            nextID = choices[index + 1] and choices[index + 1].id or (entry.kind ~= "poison" and 0 or nil); break
        end
    end
    Suite.db.missingBuffChoices[key] = nextID
    self:Queue()
end

function Buffs:Tooltip(button)
    local entry = button.entry
    if not entry or not GameTooltip then return end
    if entry.kind == "coating" then Suite.BuffReminders:Tooltip(button, false); return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:AddLine(entry.spell.name, 0.41, 0.84, 0.75)
    if entry.kind == "incoming" then
        GameTooltip:AddLine((entry.remaining and "Expiring soon on you. " or "Missing on you. ") .. "A nearby group member may provide it: " .. Suite.BuffReminders:Names(entry), 1, 1, 1, true)
        GameTooltip:AddLine("Left-click requests this buff in party, raid or instance chat. It cannot cast another player's spell. Right-click hides this family; restore it in settings. Requests have a 30-second cooldown per buff.", 0.66, 0.77, 0.77, true)
    elseif entry.kind == "poison" then
        GameTooltip:AddLine(entry.hand .. " poison missing. Right-click to choose a carried poison.", 1, 1, 1, true)
        GameTooltip:AddLine(entry.item and "Left-click to apply to this weapon." or "Right-click to choose from carried poisons before applying. Permanent enchants and oils do not satisfy poison upkeep.", 0.66, 0.77, 0.77, true)
    else
        local status = entry.remaining and (entry.kind == "group" and "Missing / expiring: " or "Expiring: ") or "Missing: "
        GameTooltip:AddLine(status .. Suite.BuffReminders:Names(entry), 1, 1, 1, true)
        if entry.kind == "group" then
            GameTooltip:AddLine(entry.passive and "Check aura coverage and move closer to these members. This reminder will not toggle an active or unknown aura off."
                or "Left-click buffs the first listed member; party effects cast on you. Native range and reagent rules apply.", 0.66, 0.77, 0.77, true)
        end
        GameTooltip:AddLine("Right-click cycles learned alternatives, then hides this family. Restore buff choices in settings to show it again.", 0.66, 0.77, 0.77, true)
    end
    GameTooltip:Show()
end

-- This sender is called only by an incoming icon's deliberate left-button release.
-- API restrictions remain authoritative; never retry or fall back to another channel/sender.
function Buffs:RequestChannel()
    if not ID(LE_PARTY_CATEGORY_INSTANCE) or not ID(LE_PARTY_CATEGORY_HOME) then return end
    local instance=Call(IsInGroup,LE_PARTY_CATEGORY_INSTANCE)
    if instance==true then return "INSTANCE_CHAT" end
    if instance~=false or Call(IsInGroup,LE_PARTY_CATEGORY_HOME)~=true then return end
    local raid=Call(IsInRaid,LE_PARTY_CATEGORY_HOME)
    if raid==true then return "RAID" elseif raid==false then return "PARTY" end
end
function Buffs:Request(entry)
    local function Reject(message)
        Suite.Print(message);return false
    end
    if not Read(entry,"table") or not Read(entry.kind,"string") or entry.kind~="incoming" or not Read(entry.family,"table")
        or not Text(entry.family.key) or not Read(entry.spell,"table") or not ID(entry.spell.id) then return false end
    if not Enabled() or not Read(Suite.db.missingBuffIncoming,"boolean") or Suite.db.missingBuffIncoming~=true or not self:Context() then
        return Reject("Buff requests are available while reminders are enabled and you are alive, outside combat.")
    end
    local chat=C_ChatInfo
    if not chat or type(chat.SendChatMessage)~="function" or Call(chat.InChatMessagingLockdown)~=false then
        return Reject("Chat requests are restricted or unavailable right now. Please ask in group chat.")
    end
    local channel=self:RequestChannel()
    if not channel then return Reject("No available party, raid or instance chat. Please ask your group directly.") end
    local now=Call(GetTime)
    if not Number(now) or now<0 then return Reject("Unable to check the request cooldown. Please ask in group chat.") end
    self.requestTimes=self.requestTimes or {}
    local last=self.requestTimes[entry.family.key]
    local wait=Number(last) and math.max(0,30-(now-last)) or 0
    if Number(self.lastRequestAt) then wait=math.max(wait,3-(now-self.lastRequestAt)) end
    if wait>0 then return Reject("Please wait "..math.ceil(wait).." seconds before another buff request.") end
    -- Recheck the live family/provider and known absence/expiry at the click, not the old icon.
    self.bookDirty=true
    local current
    for _,candidate in ipairs(self:Collect()) do
        if candidate.kind=="incoming" and candidate.family.key==entry.family.key and candidate.spell.id==entry.spell.id then current=candidate;break end
    end
    if not current or not Text(current.spell.name) or #current.spell.name>200 then
        self:Queue();return Reject("That reminder changed or the buff is already present. Refreshing the bar.")
    end
    if InCombatLockdown() or Call(chat.InChatMessagingLockdown)~=false then
        return Reject("Chat requests are restricted right now. Please ask in group chat.")
    end
    local message="Could I get "..current.spell.name..(current.remaining and " refreshed, please?" or ", please?")
    self.requestTimes[entry.family.key],self.lastRequestAt=now,now
    local ok=pcall(chat.SendChatMessage,message,channel)
    if not ok then return Reject("The game could not send the buff request. Please ask in group chat.") end
    -- The native API has no delivery result. Success here means an attempt, not server confirmation.
    return true
end

function Buffs:Button(index)
    if self.buttons[index] then return self.buttons[index] end
    local button = CreateFrame("Button", nil, self.bar, "SecureActionButtonTemplate,BackdropTemplate")
    self.buttons[index] = button
    button:SetSize(34, 34); Surface(button)
    button:RegisterForClicks("AnyUp", "AnyDown"); button:SetAttribute("useOnKeyDown", false)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 2, -2); button.icon:SetPoint("BOTTOMRIGHT", -2, 2); button.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
    button.caption = Label(button, 9); button.caption:SetPoint("TOP", button, "BOTTOM", 0, -2)
    button:SetScript("OnEnter", function() self:Tooltip(button) end)
    button:SetScript("OnLeave", function() HideTooltip(button) end)
    button:SetScript("OnHide", function() HideTooltip(button) end)
    button:SetScript("PreClick", function(_, mouseButton)
        if InCombatLockdown() or mouseButton ~= "LeftButton" then return end
        local entry = button.entry
        if not Enabled() or not self:Context() or not entry then button:SetAttribute("type1", nil); self:Queue(); return end
        if entry.unit then
            local target = self:Unit(entry.unit)
            local check = entry.checkUnit and self:Unit(entry.checkUnit) or target
            local present = entry.family.catalog.weapon and self:Weapon(16, Enum and Enum.WeaponSlot and Enum.WeaponSlot.MainHand, true)
            if not entry.family.catalog.weapon then present = check and self:Present(entry.family, self:Auras(check.unit), true) end
            local toggleReady = not entry.family.catalog.toggle or self:Present(entry.family, self:Auras("player")) == false
            if not target or target.guid ~= entry.guid or not check or entry.checkGUID and check.guid ~= entry.checkGUID
                or entry.kind == "group" and self:PartyOnly(entry.family.catalog,entry.spell.root or entry.spell.id) and not check.party or present ~= false or not toggleReady then
                button:SetAttribute("type1", nil); self:Queue()
            end
        elseif entry.kind == "coating" then
            if not Suite.BuffReminders:CoatingClick(entry) then button:SetAttribute("type1", nil); self:Queue() end
        elseif entry.kind == "poison" then
            self.itemsDirty = true
            local carried = false
            for _, item in ipairs(self:PoisonChoices()) do if entry.item and item.id == entry.item.id then carried = true end end
            if not carried or self.items.incomplete or self:Weapon(entry.slot, Enum.WeaponSlot[entry.slot == 16 and "MainHand" or "OffHand"], true) ~= false then
                button:SetAttribute("type1", nil); self:Queue()
            end
        end
    end)
    button:SetScript("PostClick", function(_, mouseButton, down)
        if InCombatLockdown() or down then return end
        if mouseButton == "RightButton" then
            if button.entry and button.entry.kind ~= "coating" then self:Cycle(button.entry) end
        else
            if mouseButton == "LeftButton" and button.entry and button.entry.kind == "incoming" then
                self:Request(button.entry)
            elseif mouseButton == "LeftButton" and button.entry and button.entry.kind == "coating" and not button.entry.item then
                Suite.BuffReminders:ChooseCoating(button.entry)
            end
            self:Queue()
        end
    end)
    return button
end

function Buffs:Refresh()
    self:Cancel()
    if InCombatLockdown() then Suite.AfterCombat("missingBuffs", function() self:Apply() end); return end
    Suite.BuffReminders.nextDue = nil
    Suite.BuffReminders:Prepare()
    if self.bar and self.cancelMove then self:StopMoving(self.bar) end
    if not Enabled() or not self:Context() then
        if self.bar then self:StopMoving(self.bar); self.bar:Hide() end
        self.entries, self.displayEntries, self.chatEntries = {}, {}, {}
        if not Enabled() then self.notices = {} end
        return
    end
    local collected = self:Collect(); self.entries = collected
    local entries, notices = self:Route(collected)
    self.displayEntries, self.chatEntries = entries, notices
    self:Notify(notices)
    if #entries == 0 then
        for _, button in ipairs(self.buttons) do
            button:Hide(); button.entry = nil
            for _, attribute in ipairs({ "type1", "spell1", "unit", "macrotext1" }) do button:SetAttribute(attribute, nil) end
        end
        if self.bar then self:StopMoving(self.bar); self.bar:Hide() end
        Suite.BuffReminders:PlaceCombat(); Suite.BuffReminders:Schedule(); return
    end
    if not self:Build() then return end
    local _,size = self:DisplayOptions()
    if not self.bar.moving then self:Place(self.bar) end
    local stride,rowStride = size + 9,size + 14
    self.header.caption:SetText(Suite.db.missingBuffLocked and "MISSING BUFFS / LOCKED" or "MISSING BUFFS")
    local columns = math.min(8, #entries)
    local titleWidth = Call(self.header.caption.GetUnboundedStringWidth, self.header.caption)
    if not Number(titleWidth) or titleWidth <= 0 or titleWidth > 4096 then titleWidth = 96 end
    -- Small lists fit the title, with a little growth for each additional buff.
    local width = math.ceil(math.max(titleWidth + 14 + (columns - 1) * 9, columns * stride + 5))
    self.bar:SetSize(width, 28 + math.ceil(#entries / 8) * rowStride)
    for index, entry in ipairs(entries) do
        local button = self:Button(index)
        button.entry = entry
        local row = math.floor((index - 1) / 8)
        local rowCount = math.min(8, #entries - row * 8)
        local rowWidth = rowCount * stride - 9
        button:SetSize(size,size)
        button:ClearAllPoints(); button:SetPoint("TOPLEFT", (width - rowWidth) / 2 + (index - 1) % 8 * stride, -25 - row * rowStride)
        for _, attribute in ipairs({ "type1", "spell1", "unit", "macrotext1" }) do button:SetAttribute(attribute, nil) end
        if entry.unit then
            button:SetAttribute("type1", "spell"); button:SetAttribute("spell1", entry.spell.id); button:SetAttribute("unit", entry.unit)
        elseif entry.item then
            button:SetAttribute("type1", "macro"); button:SetAttribute("macrotext1", "/use item:" .. entry.item.id .. "\n/use " .. entry.slot)
        end
        button.icon:SetTexture(entry.spell.icon)
        button.caption:SetText((entry.kind == "poison" or entry.kind == "coating") and entry.hand or entry.kind == "incoming" and "Group" or entry.kind == "group" and tostring(#entry.names) or "Self")
        if entry.kind == "incoming" then Suite.Theme:Backdrop(button, 0.9)
        else Suite.Theme:Backdrop(button, 0.8) end
        button:Show()
    end
    for index = #entries + 1, #self.buttons do
        local button = self.buttons[index]
        button:Hide(); button.entry = nil; button:SetAttribute("type1", nil); button:SetAttribute("spell1", nil); button:SetAttribute("unit", nil); button:SetAttribute("macrotext1", nil)
    end
    self.bar:Show()
    Suite.BuffReminders:PlaceCombat(); Suite.BuffReminders:Schedule()
end

function Buffs:Cancel()
    Suite.BuffReminders:Cancel()
    self.work = nil
    if self.timer then self.timer:Cancel(); self.timer = nil end
end
function Buffs:Queue()
    if not Enabled() or InCombatLockdown() or self.timer then return end
    if not C_Timer or type(C_Timer.NewTimer) ~= "function" then self:Refresh(); return end
    local work = {}; self.work = work
    self.timer = C_Timer.NewTimer(0.15, function()
        if self.work ~= work then return end
        self.timer, self.work = nil, nil
        if Enabled() and not InCombatLockdown() then self:Refresh() end
    end)
end
function Buffs:Apply()
    self:Cancel(); Suite.pending.missingBuffs = nil
    if self.events then self.events:UnregisterAllEvents() end
    if not Enabled() then
        self:SetPreview(false)
        Suite.AfterCombat("missingBuffs", function() self:Refresh() end); return
    end
    Suite.AfterCombat("missingBuffs", function()
        if not Enabled() then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event, unit)
                if event == "PLAYER_REGEN_DISABLED" then
                    self:Cancel(); self:SetPreview(false)
                    if self.bar and self.bar.moving then self.cancelMove = true end
                end
                Suite.BuffReminders:OnEvent(event)
                if event == "PLAYER_REGEN_DISABLED" then return
                elseif event == "PLAYER_REGEN_ENABLED" then self:Refresh()
                elseif event == "UNIT_AURA" or event == "UNIT_FLAGS" or event == "UNIT_CONNECTION" or event == "UNIT_LEVEL" or event == "UNIT_INVENTORY_CHANGED" then
                    if Text(unit) and (unit == "player" or unit:match("^party%d+$") or unit:match("^raid%d+$")) then self:Queue() end
                else
                    if event == "SPELLS_CHANGED" or event == "SPELL_DATA_LOAD_RESULT" or event == "PLAYER_ENTERING_WORLD" then self.bookDirty = true end
                    if event == "BAG_UPDATE_DELAYED" or event == "ITEM_DATA_LOAD_RESULT" or event == "PLAYER_ENTERING_WORLD" then self.itemsDirty = true end
                    self:Queue()
                end
            end)
        end
        for _, event in ipairs({ "UNIT_AURA", "GROUP_ROSTER_UPDATE", "UNIT_CONNECTION", "UNIT_LEVEL", "PLAYER_LEVEL_UP", "SPELLS_CHANGED", "SPELL_DATA_LOAD_RESULT",
            "PLAYER_ENTERING_WORLD", "PLAYER_UPDATE_RESTING", "ZONE_CHANGED_NEW_AREA", "PLAYER_EQUIPMENT_CHANGED", "BAG_UPDATE_DELAYED", "ITEM_DATA_LOAD_RESULT",
            "UNIT_INVENTORY_CHANGED", "WEAPON_ENCHANT_CHANGED", "WEAPON_SLOT_CHANGED", "UNIT_FLAGS", "PLAYER_ALIVE", "PLAYER_UNGHOST",
            "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
            if C_EventUtils and type(C_EventUtils.IsEventValid) == "function" then
                if Call(C_EventUtils.IsEventValid, event) == true then self.events:RegisterEvent(event) end
            else
                -- Older clients may reject optional events without exposing a validity query.
                pcall(self.events.RegisterEvent, self.events, event)
            end
        end
        self:Refresh()
    end)
end

function Buffs:SetPreview(show)
    if not show then if self.preview then self:StopMoving(self.preview); self.preview:Hide() end; return end
    if InCombatLockdown() or not self.settingsVisible then return end
    if not self.preview then
        local preview = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        self.preview = preview
        preview:SetFrameStrata("DIALOG"); preview:SetSize(320, 75); Surface(preview)
        preview:EnableMouse(true); self:Header(preview, "MISSING BUFFS / POSITION PREVIEW")
        local text = Label(preview, 11); text:SetPoint("BOTTOMLEFT", 10, 14); text:SetText("Self   ·   Group   ·   Carried items   ·   Class upkeep")
        preview:SetScript("OnHide", function() self:StopMoving(preview); if self.bar and not InCombatLockdown() then self:Place(self.bar) end end)
    end
    self:Place(self.preview); self.preview:Show()
end
function Buffs:SetSettingsVisible(visible)
    self.settingsVisible = visible
    if not visible then self:SetPreview(false) end
end
function Buffs:ResetPosition()
    if InCombatLockdown() then return end
    Suite.db.missingBuffPosition = {}
    if self.bar then self:Place(self.bar) end
    if self.preview then self:Place(self.preview) end
    Suite.BuffReminders:PlaceCombat()
end
function Buffs:ResetChoices()
    Suite.db.missingBuffChoices = {}; self:Queue()
end
