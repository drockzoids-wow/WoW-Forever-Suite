local _, Suite = ...
local Macros = { statuses = {} }
Suite.Macros = Macros
table.insert(Suite.modules, Macros)
local Items = Suite.MacroItems
local Number, Text = Items.Number, Items.Text

Macros.recipes = {
    { key = "food", name = "FS Food", title = "Food / Health", help = "Eat outside combat. Optionally use a Healthstone and healing potion in combat." },
    { key = "water", name = "FS Drink", title = "Drink / Mana", help = "Drink outside combat. Optionally use a mana potion in combat." },
    { key = "bandage", name = "FS Bandage", title = "Bandage", help = "Use your strongest carried bandage on yourself. Native bandage rules still apply." },
    { key = "mainhand", name = "FS Main Hand", title = "Main-hand coating", slot = 16,
        help = "Match an ordinary stone to your weapon, or choose an oil or poison. Apply outside combat." },
    { key = "offhand", name = "FS Off Hand", title = "Off-hand coating", slot = 17,
        help = "Match an ordinary stone to your weapon, or choose an oil or poison. Apply outside combat." },
    { key = "hunterMisdirection", name = "FS Misdirection", title = "Hunter · Misdirection", class = "HUNTER", spell = 34477,
        help = "Cast on a friendly focus, then a friendly target, then your pet. Requires Misdirection to be learned." },
    { key = "hunterPet", name = "FS Pet Care", title = "Hunter · Pet care", class = "HUNTER", foodChoice = true,
        help = "Revive a dead pet; Shift with no pet. Mend in combat; feed outside combat. Choose food your pet can eat." },
}
Macros.byRecipe = { item = { key = "item", title = "Item macro", help = "Use the item you choose. The item keeps its normal targeting and confirmation prompts." } }
for _, recipe in ipairs(Macros.recipes) do Macros.byRecipe[recipe.key] = recipe end

function Macros:PlayerClass()
    if type(UnitClass) ~= "function" then return end
    local ok, _, class = pcall(UnitClass, "player")
    if ok and Text(class) and #class <= 32 then return class end
end
function Macros:Applicable(entry)
    local recipe = self.byRecipe[entry.recipe]
    return recipe and (not recipe.class or self:PlayerClass() == recipe.class) or false
end
function Macros:Entries()
    self:EnsureClassRecipes()
    local entries = {}
    for _, entry in ipairs(Suite.macroDB.entries) do
        if self:Applicable(entry) then entries[#entries + 1] = entry end
    end
    return entries
end
function Macros:EnsureClassRecipes()
    if InCombatLockdown() or not Suite.macroDB then return end
    local class, existing = self:PlayerClass(), {}
    for _, entry in ipairs(Suite.macroDB.entries) do existing[entry.recipe] = true end
    for _, recipe in ipairs(self.recipes) do
        if recipe.class and recipe.class == class and not existing[recipe.key] then
            local position = #Suite.macroDB.entries + 1
            for index, entry in ipairs(Suite.macroDB.entries) do
                if entry.recipe == "item" then position = index; break end
            end
            table.insert(Suite.macroDB.entries, position, { recipe = recipe.key, name = recipe.name, created = false, combat = false })
        end
    end
end
local function ItemCount(entries)
    local count = 0
    for _, entry in ipairs(entries) do if entry.recipe == "item" then count = count + 1 end end
    return count
end
local function SpellName(id)
    if not C_Spell or type(C_Spell.GetSpellInfo) ~= "function" then return end
    local ok, info = pcall(C_Spell.GetSpellInfo, id)
    if not ok or not Suite.IsReadable(info) or type(info) ~= "table" then return end
    local name = info.name
    if Text(name) and #name > 0 and #name <= 100 and not name:find("[%c|;]") then return name end
end

local function ValidBody(value) return Text(value) and #value > 0 and #value <= 255 and not value:find("%z") end
local function ValidName(value) return Text(value) and #value > 0 and #value <= 16 and not value:find('[%c|";]') end
local function ItemID(value) return Number(value) and value > 0 and value % 1 == 0 and value <= 10000000 end
local function Serial(value) return Number(value) and value >= 1 and value <= 9999 and value % 1 == 0 end
local function ItemSerial(name)
    if not Text(name) then return nil end
    local serial = tonumber(name:match("^FS Item (%d+)$"))
    return Serial(serial) and name == "FS Item " .. serial and serial or nil
end
local function Lines(value) return (value:gsub("\r\n", "\n"):gsub("\n+$", "")) end
local function SameBody(first, second)
    if not Text(first) or not Text(second) then return false end
    return Lines(first) == Lines(second)
end
local function SharedItem(body)
    if not Text(body) then return nil end
    local tooltip, action = Lines(body):match("^#showtooltip item:(%d+)\n/use item:(%d+)$")
    local id = tonumber(action)
    return tooltip == action and ItemID(id) and id or nil
end

function Macros:Initialize(saved)
    saved = type(saved) == "table" and saved or {}
    local previous = type(saved.entries) == "table" and saved.entries or {}
    local entries, fixed, serials, ignoredItems = {}, {}, {}, {}
    for serial, ignored in pairs(type(saved.ignoredItems) == "table" and saved.ignoredItems or {}) do
        if Serial(serial) and Suite.IsReadable(ignored) and ignored == true then ignoredItems[serial] = true end
    end
    local function Settings(record, recipe, name, serial)
        local id = record.item
        return { recipe = recipe, name = name, serial = serial, created = record.created == true,
            combat = record.combat == true, item = ItemID(id) and id or nil }
    end
    for _, record in ipairs(previous) do
        if type(record) == "table" and self.byRecipe[record.recipe] then
            if record.recipe ~= "item" then fixed[record.recipe] = record
            elseif Serial(record.serial) and not ignoredItems[record.serial] and not serials[record.serial] and #entries < 10 then
                serials[record.serial] = true
                entries[#entries + 1] = Settings(record, "item", "FS Item " .. record.serial, record.serial)
            end
        end
    end
    local custom = entries
    entries = {}
    local class = self:PlayerClass()
    for _, recipe in ipairs(self.recipes) do
        if not recipe.class or recipe.class == class or fixed[recipe.key] then
            entries[#entries + 1] = Settings(fixed[recipe.key] or {}, recipe.key, recipe.name)
        end
    end
    for _, record in ipairs(custom) do entries[#entries + 1] = record end
    local nextSerial = 1
    for serial in pairs(serials) do nextSerial = math.max(nextSerial, serial + 1) end
    for serial in pairs(ignoredItems) do nextSerial = math.max(nextSerial, serial + 1) end
    if Number(saved.nextSerial) and saved.nextSerial % 1 == 0 then nextSerial = math.max(nextSerial, math.min(10000, saved.nextSerial)) end
    Suite.macroDB = { schema = 2, entries = entries, nextSerial = nextSerial, ignoredItems = ignoredItems }
    local ownership = {}
    for name, body in pairs(Suite.db.macroOwnership) do
        if ValidName(name) and ValidBody(body) then
            ownership[name] = body
            local serial = ItemSerial(name)
            if serial then Suite.macroDB.nextSerial = math.max(Suite.macroDB.nextSerial, serial + 1) end
        end
    end
    Suite.db.macroOwnership = ownership
    self:SyncGeneral()
    return Suite.macroDB
end

function Macros:AddItem()
    local db = Suite.macroDB
    if InCombatLockdown() then return nil, "Add item macros after combat." end
    self:SyncGeneral()
    if ItemCount(db.entries) >= 10 or db.nextSerial > 9999 then return nil, "Up to ten item macros can be kept here." end
    local serial = db.nextSerial
    db.nextSerial = serial + 1
    local entry = { recipe = "item", serial = serial, name = "FS Item " .. serial, created = false, combat = false }
    db.entries[#db.entries + 1] = entry
    return entry
end

function Macros:RemoveItem(entry)
    if InCombatLockdown() or entry.recipe ~= "item" then return false end
    for index, record in ipairs(Suite.macroDB.entries) do
        if record == entry then
            table.remove(Suite.macroDB.entries, index)
            Suite.macroDB.ignoredItems[entry.serial] = true
            self.statuses[entry] = nil
            return true -- Removing a choice never deletes or changes its game macro.
        end
    end
    return false
end

function Macros:Generate(entry, snapshot)
    if InCombatLockdown() then return nil, "Macro changes wait until combat ends.", true end
    local recipe = self.byRecipe[entry.recipe]
    if not self:Applicable(entry) then return nil, "This recipe is for another class.", true end
    if recipe.spell then
        local spell = SpellName(recipe.spell)
        if not spell then return nil, "Spell information is unavailable in this client.", true end
        local body = "#showtooltip " .. spell .. "\n/cast [@focus,help][@target,help][@pet,exists] " .. spell
        if not ValidBody(body) then return nil, "This spell name exceeds the game's macro text limit.", true end
        return body,
            "Friendly focus → friendly target → pet. Requires the learned spell.", false, true
    end
    if snapshot.incomplete then return nil, "Bag data is loading or unavailable. Existing text is kept.", true end
    if recipe.foodChoice then
        if not ItemID(entry.item) then return nil, "Choose food from your bags that your pet eats.", true end
        if snapshot.carriedIncomplete then return nil, "Carried item names are loading. Existing text is kept.", true end
        local revive, mend, feed = SpellName(982), SpellName(136), SpellName(6991)
        if not revive or not mend or not feed then return nil, "Pet spell information is unavailable in this client.", true end
        local body = "#showtooltip\n/cast [@pet,dead][nopet,mod:shift] " .. revive
            .. "\n/cast [combat,@pet,exists,nodead] " .. mend .. "; [nocombat,@pet,exists,nodead] " .. feed
            .. "\n/use [nocombat,@pet,exists,nodead] item:" .. entry.item
        if not ValidBody(body) then return nil, "These spell names exceed the game's macro text limit.", true end
        local food = snapshot.carriedByID and snapshot.carriedByID[entry.item]
        if not food then return body, "Chosen food is not carried. Restock it or choose another food; the macro keeps your choice.", false, true end
        local accepted, problem = Items:PetCanEat(entry.item)
        if accepted ~= true then
            return body, problem or "Your active pet cannot eat the chosen food. Choose another food; the macro keeps your choice.", false, true, food
        end
        return body, "Food: " .. food.name .. " (" .. food.count .. " carried). Suitable for your active pet.", false, true, food
    end
    local waiting = snapshot.pending or {}
    if entry.combat and (entry.recipe == "food" and (waiting.healthstone or waiting.healing)
        or entry.recipe == "water" and waiting.mana) then
        return nil, "Combat supply data is loading. Existing text is kept.", true
    end
    local item, note, pending
    if entry.item then
        if snapshot.pendingByID and snapshot.pendingByID[entry.item] then
            return nil, "Chosen item data is loading. Existing text is kept.", true
        end
        item = snapshot.byID[entry.item]
        if not item then item, pending = Items:Read(entry.item, nil, nil, UnitLevel("player"), snapshot.english) end
        if pending then return nil, "Chosen item data is loading. Existing text is kept.", true end
        if not item then return nil, "Choose a usable item for your current level.", true end
    elseif recipe.slot then item, note, pending = Items:WeaponStone(snapshot, recipe.slot)
    elseif entry.recipe == "item" then return nil, "Choose a carried item first.", true
    elseif (entry.recipe == "food" or entry.recipe == "water") and not snapshot.english then
        return nil, "Choose food or drink for this language.", true
    else
        if waiting[entry.recipe] then return nil, "Recovery supply data is loading. Existing text is kept.", true end
        item = snapshot.best[entry.recipe]
    end
    if pending then return nil, note, true end
    local tooltip, commands, details = {}, {}, {}
    local function Use(candidate, condition, target)
        if not candidate then return end
        local qualifier = condition and "[" .. condition .. "] " or ""
        tooltip[#tooltip + 1] = qualifier .. "item:" .. candidate.id
        local rule = target and ("[" .. target .. (condition and "," .. condition or "") .. "] ") or qualifier
        commands[#commands + 1] = "/use " .. rule .. "item:" .. candidate.id
        details[#details + 1] = candidate.name
    end
    if entry.combat and (entry.recipe == "food" or entry.recipe == "water") then
        if entry.recipe == "food" then
            -- Both lines are attempted on a press; this is not a cooldown-based fallback.
            Use(snapshot.best.healthstone, "combat")
            Use(snapshot.best.healing, "combat")
            if snapshot.best.healthstone and snapshot.best.healing then table.remove(tooltip, #tooltip) end
        else Use(snapshot.best.mana, "combat") end
    end
    local rest = entry.recipe == "food" or entry.recipe == "water" or recipe.slot ~= nil
    Use(item, rest and "nocombat" or nil, entry.recipe == "bandage" and "@player" or nil)
    if recipe.slot and item then commands[#commands + 1] = "/use [nocombat] " .. recipe.slot end
    if #commands == 0 then return "#showtooltip", note or "Carry suitable supplies, or choose an item.", false, false end
    table.insert(commands, 1, "#showtooltip " .. table.concat(tooltip, "; "))
    return table.concat(commands, "\n"), table.concat(details, ", "), false, true, item
end

local function Limit()
    local constants = Constants and Constants.MacroConsts
    local value = constants and constants.MAX_ACCOUNT_MACROS
    return Number(value) and value > 0 and value % 1 == 0 and value or 120
end
local function ReadMacro(index)
    local ok, name, _, body = pcall(GetMacroInfo, index)
    if not ok or not Suite.IsReadable(name) or not Suite.IsReadable(body) then return nil, nil, false end
    if name ~= nil and (not Text(name) or not Text(body)) then return nil, nil, false end
    return name, body, true
end

function Macros:SyncGeneral()
    self:EnsureClassRecipes()
    if InCombatLockdown() or not Suite.macroDB or type(GetMacroInfo) ~= "function" then return end
    local general = {}
    for index = 1, Limit() do
        local name, body, readable = ReadMacro(index)
        if not readable then return end -- An incomplete list cannot establish shared ownership.
        if name then
            if general[name] then general[name].duplicate = true
            else general[name] = { body = body } end
        end
    end
    local function Shared(name)
        local macro, owned = general[name], Suite.db.macroOwnership[name]
        return macro and not macro.duplicate and owned and SameBody(macro.body, owned)
    end
    local db, existing, imports = Suite.macroDB, {}, {}
    for _, entry in ipairs(db.entries) do
        existing[entry.name] = true
        if Shared(entry.name) then
            entry.created = true
            if entry.recipe == "item" and not entry.item then entry.item = SharedItem(Suite.db.macroOwnership[entry.name]) end
        end
    end
    for name, owned in pairs(Suite.db.macroOwnership) do
        local serial = ItemSerial(name)
        if serial then
            db.nextSerial = math.max(db.nextSerial, serial + 1)
            if not existing[name] and not db.ignoredItems[serial] and Shared(name) then
                -- Chosen-item recipes have one exact generated action. Require confirmed
                -- account ownership as well as this shape; an FS prefix alone is insufficient.
                local id = SharedItem(owned)
                if id then
                    imports[#imports + 1] = { recipe = "item", name = name, serial = serial,
                        item = id, created = true, combat = false }
                end
            end
        end
    end
    table.sort(imports, function(first, second) return first.serial < second.serial end)
    for _, entry in ipairs(imports) do
        if ItemCount(db.entries) >= 10 then break end
        db.entries[#db.entries + 1] = entry
    end
end

function Macros:CanSave(entry, body, pending, ready)
    if InCombatLockdown() or pending or not body or not ValidBody(body) or not self:Applicable(entry) then return false end
    local recipe = self.byRecipe[entry.recipe]
    return ready == true or entry.created == true or recipe.slot ~= nil and entry.item == nil
end
function Macros:Find(name)
    if type(GetMacroInfo) ~= "function" then return nil, "Macro information is unavailable." end
    local found, saved
    for index = 1, Limit() do
        local current, body, readable = ReadMacro(index)
        if not readable then return nil, "Macro information is unavailable. Existing macros are kept." end
        if current == name then
            if found then return nil, "Duplicate names in General macros. Rename one in Blizzard's Macros window." end
            found, saved = index, body
        end
    end
    return found, nil, saved
end

local function EditorOpen()
    if MacroFrame and type(MacroFrame.IsShown) == "function" then
        local ok, shown = pcall(MacroFrame.IsShown, MacroFrame)
        return not ok or not Suite.IsReadable(shown) or shown
    end
    return false
end
function Macros:Owned(entry)
    local index, problem, old = self:Find(entry.name)
    if problem then return nil, problem end
    if index then
        local owned = Suite.db.macroOwnership[entry.name]
        if not owned then return nil, "That General macro name is already in use. Rename it in Blizzard's Macros window." end
        if not SameBody(old, owned) then return nil, "Edited in Blizzard's Macros window. Automatic changes are paused for this macro." end
    end
    return index, nil, old
end
function Macros:Write(entry, body, explicit)
    if InCombatLockdown() then return false, "Create or update after combat." end
    if not self:Applicable(entry) then return false, "This recipe is for another class." end
    if EditorOpen() then return false, "Close Blizzard's Macros window before updating." end
    if not ValidName(entry.name) or not ValidBody(body) then return false, "This macro exceeds the game's name or text limit." end
    if type(CreateMacro) ~= "function" or type(EditMacro) ~= "function" or type(GetNumMacros) ~= "function" then
        return false, "Macro creation is unavailable in this client."
    end
    local index, problem, old = self:Owned(entry)
    if problem then return false, problem end
    if not index and not explicit then return false, "Macro missing. Click Create to make it again." end
    if index and SameBody(old, body) then entry.created = true; return true, "Current in General macros." end
    self.writing = true
    local ok, result
    if index then ok, result = pcall(EditMacro, index, nil, nil, body)
    else
        local read, count = pcall(GetNumMacros)
        if not read or not Number(count) or count >= Limit() then self.writing = nil; return false, "General macro slots are full or unavailable." end
        ok, result = pcall(CreateMacro, entry.name, 134400, body, false)
    end
    self.writing = nil
    if not ok or not Number(result) or result < 1 or result % 1 ~= 0 or result > Limit() then
        return false, "The client could not save this General macro."
    end
    local name, saved, readable = ReadMacro(result)
    if not readable or name ~= entry.name or not SameBody(saved, body) then return false, "The client did not confirm the saved macro." end
    Suite.db.macroOwnership[name], entry.created = saved, true
    return true, "Saved in General macros. Drag it from Blizzard's Macros window to an action bar."
end

function Macros:Notify()
    if self.visible and Suite.GUI.RefreshMacros then Suite.GUI:RefreshMacros() end
end
function Macros:Refresh()
    if InCombatLockdown() then self.dirty = true; self:Notify(); return end
    self:SyncGeneral()
    self.refreshes = (self.refreshes or 0) + 1
    self.snapshot = Items:Scan()
    if Suite.db.macroUpdates then
        for _, entry in ipairs(Suite.macroDB.entries) do
            if entry.created and self:Applicable(entry) then
                local body, note, pending, ready = self:Generate(entry, self.snapshot)
                if not pending and body then
                    local detail = note
                    local ok, status = self:Write(entry, body, false)
                    note = ok and self.byRecipe[entry.recipe].foodChoice and detail or ok and not ready and self.byRecipe[entry.recipe].slot
                        and "Waiting for a suitable weapon and carried coating." or status
                end
                self.statuses[entry] = note
            end
        end
    end
    self.dirty = false
    self:Notify()
end
function Macros:Status()
    self:SyncGeneral()
    Suite.Print("Automatic macro updates: " .. (Suite.db.macroUpdates and "On" or "Off")
        .. " · completed refreshes: " .. (self.refreshes or 0))
    Suite.Print("Last macro event: " .. (self.lastEvent or "none since reload")
        .. (self.timer and " · refresh queued" or " · no refresh queued"))
    local snapshot, count = Items:Scan(), 0
    for _, entry in ipairs(Suite.macroDB.entries) do
        if entry.created and self:Applicable(entry) then
            count = count + 1
            local body, note, pending = self:Generate(entry, snapshot)
            local detail = note
            if not pending and body then
                if EditorOpen() then note = "Close Blizzard's Macros window before updating."
                else
                    local index, problem, old = self:Owned(entry)
                    if problem then note = problem
                    elseif not index then note = "Macro missing. Click Create to make it again."
                    elseif SameBody(old, body) then note = "Current in General macros."
                    elseif not Suite.db.macroUpdates then note = "Automatic updates are Off."
                    else note = "Supplies changed. Last update: " .. (self.statuses[entry] or "awaiting an event.") end
                end
                if self.byRecipe[entry.recipe].foodChoice then note = note .. " " .. detail end
            end
            Suite.Print(entry.name .. ": " .. (note or "Waiting for supplies."))
        end
    end
    if count == 0 then Suite.Print("No created macros are tracked on this character.") end
end
function Macros:Save(entry)
    if InCombatLockdown() then self.statuses[entry] = "Click Create / update after combat."; self:Notify(); return false end
    self.snapshot = Items:Scan()
    local body, note, pending, ready = self:Generate(entry, self.snapshot)
    local detail = note
    local ok = false
    if self:CanSave(entry, body, pending, ready) then
        ok, note = self:Write(entry, body, true)
        if ok and self.byRecipe[entry.recipe].foodChoice then note = note .. " " .. detail end
        if ok and not ready then
            if self.byRecipe[entry.recipe].slot then
                note = Suite.db.macroUpdates and "Placeholder saved. Waiting for a suitable weapon and carried coating."
                    or "Placeholder saved. Enable automatic updates to fill it when a weapon and coating are ready."
            else note = "No suitable supplies. The old automatic action was cleared." end
        end
    end
    self.statuses[entry] = note
    self:Notify()
    return ok
end
function Macros:Cancel()
    if self.timer then self.timer:Cancel(); self.timer = nil end
end
function Macros:Queue()
    self.dirty = true
    if InCombatLockdown() or self.timer or not (Suite.db.macroUpdates or self.visible) then return end
    if C_Timer and type(C_Timer.NewTimer) == "function" then
        self.timer = C_Timer.NewTimer(0.15, function() self.timer = nil; self:Refresh() end)
    end
end
function Macros:SetVisible(visible)
    self.visible = visible == true
    self:Apply()
end
function Macros:WatchEditor()
    local frame = MacroFrame
    if not frame or frame == self.editor or type(frame.HookScript) ~= "function" then return end
    self.editor = frame
    frame:HookScript("OnHide", function() if Suite.db.macroUpdates or self.visible then self:Queue() end end)
end
function Macros:Apply()
    if not Suite.macroDB then return end
    self:SyncGeneral()
    local active = Suite.db.macroUpdates or self.visible
    if not active then
        self:Cancel()
        if self.events then self.events:UnregisterAllEvents() end
        return
    end
    if not self.events then
        self.events = CreateFrame("Frame")
        self.events:SetScript("OnEvent", function(_, event, id)
            if event == "UNIT_PET" and (not Text(id) or id ~= "player") then return end
            if event == "UNIT_LEVEL" and (not Text(id) or id ~= "pet") then return end
            if event == "UNIT_PET" or event == "UNIT_LEVEL" then
                for _, entry in ipairs(Suite.macroDB.entries) do
                    if self.byRecipe[entry.recipe].foodChoice then self.statuses[entry] = nil end
                end
            end
            if event == "UPDATE_MACROS" and self.writing then return end
            if event == "PLAYER_REGEN_DISABLED" then self:Cancel(); self.dirty = true; self:Notify(); return end
            if event == "GET_ITEM_INFO_RECEIVED" then
                if not Number(id) or not Items.requested[id] then return end
                -- Keep the request marker even on failure; do not loop on failed data loads.
            end
            if event == "ADDON_LOADED" then
                if not Text(id) or id ~= "Blizzard_MacroUI" then return end
                self:WatchEditor()
            end
            self.lastEvent = event
            self:Queue()
        end)
    end
    for _, event in ipairs({ "BAG_UPDATE_DELAYED", "PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP", "PLAYER_EQUIPMENT_CHANGED",
        "GET_ITEM_INFO_RECEIVED", "SPELLS_CHANGED", "UNIT_PET", "UNIT_LEVEL", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "UPDATE_MACROS", "ADDON_LOADED" }) do self.events:RegisterEvent(event) end
    self:WatchEditor()
    self:Queue()
end
