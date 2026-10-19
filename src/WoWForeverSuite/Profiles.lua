local _, Suite = ...
local Profiles = { limit = 12 }
Suite.Profiles = Profiles
-- These records describe possessions, ownership, safety rules or native restoration state.
-- They must never be rolled back or copied by a settings/layout switch.
Profiles.excluded = { schema=true, setupGuide=true, inventory=true, inventoryBrowser=true,
    mailContacts=true, macroOwnership=true, bagSpaceBlacklist=true, scorePreset=true, upgradePreference=true }
local function Table(v) return Suite.IsReadable(v) and type(v) == "table" end
local function Text(v, limit) return Suite.IsReadable(v) and type(v) == "string" and #v > 0 and #v <= (limit or 80) and not v:find("[%c|]") end
local function Clone(value, depth, seen, budget)
    if not Suite.IsReadable(value) then return end
    local kind = type(value)
    if kind == "boolean" then return value end
    if kind == "number" then
        if value == value and math.abs(value) <= 1000000000000 then return value end
    elseif kind == "string" then
        if #value <= 4096 then return value end
    elseif kind == "table" and depth < 8 and not seen[value] then
        seen[value] = true
        local result = {}
        for key, child in pairs(value) do
            budget.n = budget.n + 1
            if budget.n > 4096 then break end
            if Suite.IsReadable(key) and ((type(key) == "string" and #key <= 128)
                or (type(key) == "number" and key == key and key % 1 == 0 and math.abs(key) < 1000000)) then
                result[key] = Clone(child, depth + 1, seen, budget)
            end
        end
        seen[value] = nil
        return result
    end
end
local function Copy(v) return Clone(v, 0, {}, {n=0}) end
local function Same(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for k,v in pairs(a) do if not Same(v,b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end
function Profiles:Keys()
    local keys = {}
    for key in pairs(Suite.defaults) do if not self.excluded[key] then keys[#keys+1] = key end end
    table.sort(keys); return keys
end
function Profiles:Settings(source, partial)
    source = Table(source) and source or {}
    local result = {}
    for _,key in ipairs(self:Keys()) do
        local value = source[key]
        if Suite.IsReadable(value) and type(value) == type(Suite.defaults[key]) then result[key] = Copy(value)
        elseif not partial then result[key] = Copy(Suite.defaults[key]) end
    end
    return result
end
function Profiles:Find(id)
    if not Text(id) or not self.store then return end
    for _,entry in ipairs(self.store.entries) do if entry.id == id then return entry end end
end
function Profiles:Initialize(db, saved)
    local old = Table(db.settingsProfiles) and db.settingsProfiles or {}
    local store = {schema=1, entries={}, characters={}, nextID=1}
    local ids, names = {}, {}
    for _,entry in ipairs(Table(old.entries) and old.entries or {}) do
        if #store.entries >= self.limit then break end
        if Table(entry) and Text(entry.id) and (entry.id == "default" or entry.id:match("^p%d+$"))
            and Text(entry.name,40) and (entry.id == "default" or entry.name:lower() ~= "default")
            and not ids[entry.id] and not names[entry.name:lower()] then
            local name = entry.id == "default" and "Default" or entry.name
            store.entries[#store.entries+1] = {id=entry.id,name=name,values=self:Settings(entry.values)}
            ids[entry.id],names[name:lower()] = true,true
            local serial = tonumber(entry.id:match("^p(%d+)$"))
            if serial and serial < 1000000 then store.nextID = math.max(store.nextID,serial+1) end
        end
    end
    if not ids.default then
        if #store.entries == self.limit then
            local removed = table.remove(store.entries); ids[removed.id] = nil
        end
        table.insert(store.entries,1,{id="default",name="Default",values=self:Settings(db)})
        ids.default = true
    end
    local count = 0
    for guid,record in pairs(Table(old.characters) and old.characters or {}) do
        if count >= 80 then break end
        if Text(guid) and Table(record) and Text(record.name) then
            store.characters[guid] = {name=record.name, realm=Text(record.realm) and record.realm or "",
                id=Text(record.id) and ids[record.id] and record.id or "default", personal=Suite.IsReadable(record.personal) and record.personal == true,
                values=self:Settings(record.values)}
            count=count+1
        end
    end
    saved = Table(saved) and saved or {}
    local state = {id=Text(saved.id) and ids[saved.id] and saved.id or "default",
        personal=Suite.IsReadable(saved.personal) and saved.personal == true, overrides={}}
    for id in pairs(ids) do
        if Table(saved.overrides) and Table(saved.overrides[id]) then state.overrides[id]=self:Settings(saved.overrides[id],true) end
    end
    self.store, self.state, self.activeID, self.activePersonal = store,state,state.id,state.personal
    self.reloadPending, self.guid = nil, nil
    db.settingsProfiles = store
    local values = self:Effective(state.id,state.personal)
    for _,key in ipairs(self:Keys()) do db[key] = values[key] end
    return state
end
function Profiles:Effective(id, personal)
    local entry = self:Find(id)
    if not entry then return end
    local values = self:Settings(entry.values)
    local overrides = self.state and self.state.overrides[id]
    if personal and Table(overrides) then for key,value in pairs(overrides) do values[key] = Copy(value) end end
    return values
end
function Profiles:RegisterCharacter()
    if not self.store or not self.state then return end
    local guid = UnitGUID and UnitGUID("player")
    if not Text(guid) then return end
    local name = UnitName and UnitName("player")
    local realm = GetNormalizedRealmName and GetNormalizedRealmName() or nil
    self.guid = guid
    local record = self.store.characters[guid] or {}
    record.name, record.realm = Text(name) and name or "Current character", Text(realm) and realm or ""
    self.store.characters[guid] = record
    self:SaveActive()
end
function Profiles:SaveActive()
    if not self.store or not self.state or not Suite.db then return end
    local entry = self:Find(self.activeID)
    if not entry then return end
    local values = self:Settings(Suite.db)
    if self.activePersonal then
        local overrides = {}
        for key,value in pairs(values) do if not Same(value,entry.values[key]) then overrides[key] = Copy(value) end end
        self.state.overrides[self.activeID] = overrides
    else entry.values = self:Settings(values) end
    if self.guid and self.store.characters[self.guid] then
        local record = self.store.characters[self.guid]
        record.id, record.personal, record.values = self.activeID,self.activePersonal,values
    end
end
function Profiles:Name(value, except)
    if not Text(value,40) then return nil,"Use 1-40 bytes without formatting or control characters." end
    value = value:match("^%s*(.-)%s*$")
    if value == "" then return nil,"Enter a profile name." end
    for _,entry in ipairs(self.store.entries) do
        if entry.id ~= except and entry.name:lower() == value:lower() then return nil,"That name is already in use." end
    end
    return value
end
function Profiles:Create(name, sourceGUID)
    if InCombatLockdown() or self.reloadPending or not self.store then return nil,"Finish combat or the pending reload first." end
    self:SaveActive()
    if #self.store.entries >= self.limit then return nil,"All 12 profile slots are in use." end
    local valid,err = self:Name(name); if not valid then return nil,err end
    local source = Suite.db
    if sourceGUID then
        if not Text(sourceGUID) or not self.store.characters[sourceGUID] then return nil,"That character has no recorded setup." end
        source = self.store.characters[sourceGUID].values
    end
    local id = "p" .. self.store.nextID
    self.store.nextID = self.store.nextID+1
    self.store.entries[#self.store.entries+1] = {id=id,name=valid,values=self:Settings(source)}
    return id
end
function Profiles:Rename(id,name)
    if InCombatLockdown() or self.reloadPending then return false,"Finish combat or the pending reload first." end
    local entry = self:Find(id)
    if not entry or id == "default" then return false,"Default keeps its name." end
    local valid,err = self:Name(name,id); if not valid then return false,err end
    entry.name=valid; return true
end
function Profiles:Delete(id)
    if InCombatLockdown() or self.reloadPending then return false,"Finish combat or the pending reload first." end
    if not self:Find(id) or id == "default" or id == self.activeID then return false,"Default and the active profile are kept." end
    for _,record in pairs(self.store.characters) do
        if record.id == id then return false,"A character still uses this profile. Switch that character first." end
    end
    for i,entry in ipairs(self.store.entries) do if entry.id == id then table.remove(self.store.entries,i);break end end
    self.state.overrides[id]=nil
    return true
end
function Profiles:Review(id,personal)
    if not Suite.IsReadable(personal) or type(personal) ~= "boolean" then return end
    self:SaveActive()
    local target = self:Effective(id,personal)
    if not target then return end
    local changes,enabled = {},{}
    local labels = {}
    for _,entry in ipairs(Suite.SettingsCatalog.entries) do labels[entry.key]=entry.label end
    local current = self:Settings(Suite.db)
    local layoutLabels = {windowPositions="Window positions and sizes",guiPosition="Suite panel position",
        meterWindows="Meter layout and appearance",meterDock="Meter docking",castbars="Castbar sizes",
        campingPosition="Camping bar position",missingBuffPosition="Buff bar position",
        questItemPosition="Quest item position",bagSpacePosition="Bag alert position",
        missingBuffChoices="Buff choices",missingBuffCustom="Custom buff spells"}
    for _,key in ipairs(self:Keys()) do
        if not Same(current[key],target[key]) then
            local label = layoutLabels[key] or labels[key] or key
            changes[#changes+1]=label..(type(target[key]) == "boolean" and (target[key] and ": on" or ": off") or "")
            if target[key] == true and Suite.defaults[key] == false then enabled[#enabled+1]=label end
        end
    end
    return {id=id,personal=personal == true,changes=changes,enabled=enabled,values=target}
end
function Profiles:Activate(review)
    if InCombatLockdown() or self.reloadPending then return false,"Switch profiles outside combat." end
    if not Table(review) or not self:Find(review.id) or not Suite.IsReadable(review.personal)
        or type(review.personal) ~= "boolean" or not Table(review.values) then return false,"Choose a profile first." end
    -- Recheck the reviewed target; no module or protected geometry is changed in this UI session.
    self:SaveActive()
    if not Same(self:Settings(review.values),self:Effective(review.id,review.personal)) then return false,"The setup changed. Review it again." end
    self.state.id,self.state.personal = review.id,review.personal == true
    self.reloadPending=true
    if type(ReloadUI) == "function" then
        local ok = pcall(ReloadUI)
        if ok then return true end
    end
    return true,"Selection saved. Type /reload to apply it."
end
