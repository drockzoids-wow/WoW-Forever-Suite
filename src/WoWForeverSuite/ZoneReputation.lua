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
-- Native area IDs supply localized names; faction IDs are not localized text.
local zones = { Alliance = { [1]=47, [38]=47, [11]=47, [1537]=47, [12]=72, [40]=72, [44]=72, [10]=72, [1519]=72,
    [141]=69, [148]=69, [1657]=69 }, Horde = { [14]=76, [17]=76, [1637]=76, [215]=81, [1638]=81, [85]=68, [130]=68, [1497]=68 } }
local towns = { [35]=21, [392]=470, [976]=369, [2255]=577 }
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
    return Match(towns) or Match(zones[side])
end
function Reputation:Refresh()
    if not self:Enabled() then return end
    if InCombatLockdown() then Suite.pending.zoneReputation = function() self:Refresh() end; return end
    local id, api = self:Desired(), C_Reputation
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
function Reputation:Apply()
    Suite.pending.zoneReputation = nil
    if self.timer then self.timer:Cancel(); self.timer = nil end
    if not self:Enabled() then self.attempted = nil; if self.events then self.events:UnregisterAllEvents() end; return end
    Suite.AfterCombat("zoneReputation", function()
        if not self:Enabled() then return end
        if not self.events then self.events = CreateFrame("Frame"); self.events:SetScript("OnEvent", function(_, event)
            if event ~= "UPDATE_FACTION" then self.attempted = nil end
            self:Queue()
        end) end
        for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED_INDOORS", "UPDATE_FACTION" }) do
            pcall(self.events.RegisterEvent, self.events, event)
        end
        self:Refresh()
    end)
end
