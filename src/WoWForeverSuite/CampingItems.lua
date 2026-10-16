local _, Suite = ...
local Items = { requested = {}, catalog = {} }
Suite.CampingItems = Items

local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and value >= 0 and value < math.huge
end
local function Text(value)
    return Suite.IsReadable(value) and type(value) == "string"
end
local function Read(callback, ...)
    if type(callback) ~= "function" then return nil end
    local ok, value = pcall(callback, ...)
    if ok and Suite.IsReadable(value) then return value end
end
Items.Number, Items.Text = Number, Text

function Items:Request(id)
    if self.requested[id] or not C_Item or type(C_Item.RequestLoadItemDataByID) ~= "function" then return end
    self.requested[id] = true
    pcall(C_Item.RequestLoadItemDataByID, id)
end

local function CampRequirement(bag, slot)
    local data = Read(C_TooltipInfo and C_TooltipInfo.GetBagItem, bag, slot)
    if type(data) ~= "table" or not Suite.IsReadable(data.lines) or type(data.lines) ~= "table" then return nil end
    local hasText, nearby = false, false
    for _, line in ipairs(data.lines) do
        if not Suite.IsReadable(line) or type(line) ~= "table" then return nil end
        for _, field in ipairs({ "leftText", "rightText" }) do
            local value = line[field]
            if not Suite.IsReadable(value) then return nil end
            if Text(value) and value ~= "" then
                hasText = true
                -- Read both columns and tolerate line breaks / native color markup.
                local words = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):lower()
                if words:find("requires%s+a%s+campfire%s+nearby")
                    or words:find("requires%s+a%s+nearby%s+campfire") then nearby = true end
            end
        end
    end
    if hasText then return nearby end
end

function Items:Describe(id, bag, slot)
    local cached = self.catalog[id]
    if cached ~= nil then return cached end
    if not C_Item or type(C_Item.GetItemInfo) ~= "function" or type(C_Item.GetItemSpell) ~= "function" then return nil end
    local ok, name, _, _, _, _, _, _, _, _, icon, _, class = pcall(C_Item.GetItemInfo, id)
    if not ok or not Text(name) or not Number(class) then self:Request(id); return nil end
    if class == 9 then self.catalog[id] = false; return false end -- Recipe, not a placed object.
    local spellOK, spell = pcall(C_Item.GetItemSpell, id)
    if not spellOK or not Suite.IsReadable(spell) then return nil end
    if spell == nil or (Text(spell) and spell == "") then self.catalog[id] = false; return false end
    if not Text(spell) then return nil end
    local requirement = CampRequirement(bag, slot)
    if requirement == nil then self:Request(id); return nil end
    if not requirement then self.catalog[id] = false; return false end
    local entry = { id = id, name = name, icon = Number(icon) and icon or 134400 }
    self.catalog[id] = entry
    return entry
end

function Items:Scan()
    local snapshot = { list = {}, byID = {}, carried = {}, incomplete = false }
    if InCombatLockdown() then snapshot.incomplete = true; return snapshot end
    local api = C_Container or {}
    if type(api.GetContainerNumSlots) ~= "function" or type(api.GetContainerItemInfo) ~= "function" then
        snapshot.incomplete = true; return snapshot
    end
    local last = NUM_TOTAL_EQUIPPED_BAG_SLOTS
    if not Number(last) then last = NUM_BAG_SLOTS end
    if not Number(last) then last = 4 end
    for bag = 0, math.min(5, last) do
        local slots = Read(api.GetContainerNumSlots, bag)
        if not Number(slots) then snapshot.incomplete = true; slots = 0 end
        for slot = 1, math.min(200, slots) do
            local ok, info = pcall(api.GetContainerItemInfo, bag, slot)
            if not ok or not Suite.IsReadable(info) then snapshot.incomplete = true
            elseif info ~= nil then
                if type(info) ~= "table" or not Number(info.itemID) or info.itemID < 1
                    or info.itemID % 1 ~= 0 or not Number(info.stackCount) then snapshot.incomplete = true
                elseif info.stackCount > 0 then
                    local id = info.itemID
                    snapshot.carried[id] = true
                    local entry = snapshot.byID[id]
                    if entry then entry.count = entry.count + info.stackCount
                    else
                        local description = self:Describe(id, bag, slot)
                        if description == nil then snapshot.incomplete = true
                        elseif description then
                            entry = { id = id, name = description.name, icon = description.icon,
                                count = info.stackCount, bag = bag, slot = slot }
                            if Number(info.iconFileID) then entry.icon = info.iconFileID end
                            snapshot.byID[id] = entry
                            snapshot.list[#snapshot.list + 1] = entry
                        end
                    end
                end
            end
        end
    end
    table.sort(snapshot.list, function(a, b)
        if a.name == b.name then return a.id < b.id end
        return a.name < b.name
    end)
    return snapshot
end
