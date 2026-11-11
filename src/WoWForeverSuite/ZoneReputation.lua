local _, Suite = ...
local Reputation = {}
Suite.ZoneReputation = Reputation
table.insert(Suite.modules, Reputation)
local function Read(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Text(value) return Suite.IsReadable(value) and type(value) == "string" and #value > 0 and #value <= 256 end
local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and value > -math.huge and value < math.huge
end
-- Native area IDs supply localized names; faction IDs are not localized text.
-- Curated primary quest factions, not territorial ownership or enemy factions.
local zones = {
    Alliance = {
        [1]=47, [38]=47, [11]=47, [1537]=47, -- Ironforge
        [12]=72, [40]=72, [44]=72, [10]=72, [1519]=72, [267]=72, [15]=72, [4]=72, [46]=72, -- Stormwind
        [141]=69, [148]=69, [1657]=69, [331]=69, [406]=69, [357]=69, -- Darnassus
        [47]=471, -- Wildhammer Clan: Hinterlands
        [16591]=2826, [16593]=2779, -- Riverglades / Zephras Isle
    },
    Horde = {
        [14]=76, [17]=76, [1637]=76, [331]=76, [406]=76, [3]=76, [8]=76, [15]=76, -- Orgrimmar
        [215]=81, [1638]=81, [357]=81, [400]=81, -- Thunder Bluff
        [85]=68, [130]=68, [1497]=68, [267]=68, -- Undercity
        [16591]=2782, [16593]=2778, -- Riverglades / Zephras Isle
    },
}
local neutralZones = {
    [28]=529, [139]=529, -- Argent Dawn: Western / Eastern Plaguelands
    [51]=59, -- Thorium Brotherhood: Searing Gorge
    [493]=609, [1377]=609, -- Cenarion Circle: Moonglade / Silithus
    [440]=369, -- Gadgetzan: Tanaris
    [616]=2765, -- Forever Guardians of Hyjal (not Cataclysm faction 1158)
}
local towns = { [35]=21, [392]=470, [976]=369, [2255]=577,
    [16727]=2827, [16631]=2758 } -- Powderfuse Port / Shadowgale Forest
function Reputation:Enabled() return Suite.db and Suite.IsReadable(Suite.db.zoneReputation) and Suite.db.zoneReputation == true end
function Reputation:Desired()
    if Read(IsInInstance) ~= false then return end
    local side = Read(UnitFactionGroup, "player")
    if not Text(side) or not zones[side] then return end
    local zone, subzone = Read(GetRealZoneText), Read(GetSubZoneText)
    if not Text(zone) then return end
    local function Match(entries)
        for area, faction in pairs(entries) do
            local name = Read(C_Map and C_Map.GetAreaInfo, area)
            if Text(name) and (name == zone or Text(subzone) and name == subzone) then return faction end
        end
    end
    return Match(towns) or Match(zones[side]) or Match(neutralZones)
end
function Reputation:Refresh()
    if not self:Enabled() then return end
    if InCombatLockdown() then Suite.pending.zoneReputation = function() self:Refresh() end; return end
    if Read(IsInInstance) ~= false then return end
    local id, api = self.changedFaction or self:Desired(), C_Reputation
    if not id or not api or type(api.SetWatchedFactionByID) ~= "function" then return end
    local data = Read(api.GetFactionDataByID, id)
    if type(data) ~= "table" or not Text(data.name) or not Suite.IsReadable(data.isHeader)
        or not Suite.IsReadable(data.isHeaderWithRep) or data.isHeader and not data.isHeaderWithRep then return end
    if self.attempted == id then return end
    self.attempted = id
    local watched = Read(api.GetWatchedFactionData)
    if type(watched) == "table" and Suite.IsReadable(watched.factionID) and watched.factionID == id then return end
    -- Updating reputation can emit UPDATE_FACTION synchronously.
    self.writing = true; pcall(api.SetWatchedFactionByID, id); self.writing = nil
end
function Reputation:Queue()
    if self.writing or self.timer or not self:Enabled() then return end
    if InCombatLockdown() then Suite.pending.zoneReputation = function() self:Refresh() end; return end
    if C_Timer and C_Timer.NewTimer then self.timer = C_Timer.NewTimer(0.15, function() self.timer = nil; self:Refresh() end) end
end
function Reputation:OnEvent(event, id, standing)
    if not self:Enabled() or self.writing then return end
    if event == "FACTION_STANDING_CHANGED" then
        -- The native event identifies factions even beneath collapsed headers.
        -- Do not enumerate/expand the reputation UI or infer factions from names.
        if not Number(id) or id < 1 or id > 2147483647 or id % 1 ~= 0 or not Number(standing) then return end
        if Read(IsInInstance) ~= false then return end
        self.changedFaction, self.attempted = id, nil
    elseif event ~= "UPDATE_FACTION" then
        self.changedFaction, self.attempted = nil, nil
    end
    self:Queue()
end
function Reputation:Apply()
    Suite.pending.zoneReputation = nil
    if self.timer then self.timer:Cancel(); self.timer = nil end
    if not self:Enabled() then self.changedFaction, self.attempted = nil, nil; if self.events then self.events:UnregisterAllEvents() end; return end
    Suite.AfterCombat("zoneReputation", function()
        if not self:Enabled() then return end
        if not self.events then self.events = CreateFrame("Frame"); self.events:SetScript("OnEvent", function(_, event, ...)
            self:OnEvent(event, ...)
        end) end
        for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED_INDOORS", "UPDATE_FACTION", "FACTION_STANDING_CHANGED" }) do
            pcall(self.events.RegisterEvent, self.events, event)
        end
        self:Refresh()
    end)
end
