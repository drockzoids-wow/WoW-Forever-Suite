local _, Suite = ...
local BagSort = {}
Suite.BagSort = BagSort
table.insert(Suite.modules, BagSort)

local function Enabled()
    return Suite.db and Suite.IsReadable(Suite.db.sortBagsOnOpen) and Suite.db.sortBagsOnOpen == true
end

local function Boolean(value)
    return Suite.IsReadable(value) and type(value) == "boolean"
end

local function NativeDirection()
    if not C_Container or type(C_Container.GetSortBagsRightToLeft) ~= "function"
        or type(C_Container.SetSortBagsRightToLeft) ~= "function" then return end
    local success, value = pcall(C_Container.GetSortBagsRightToLeft)
    if success and Boolean(value) then return value end
end

function BagSort:RestoreDirection()
    Suite.pending.bagSortDirection = nil
    if not Suite.db or not Boolean(Suite.db.bagSortDirectionRestore) then return end
    Suite.AfterCombat("bagSortDirection", function()
        if not Suite.db then return end
        local restore = Suite.db.bagSortDirectionRestore
        if not Boolean(restore) then return end
        local current = NativeDirection()
        if current == nil then return end
        if current ~= restore then
            -- Retire 0.2.46's native bag-priority override; only restore its captured preference.
            local success = pcall(C_Container.SetSortBagsRightToLeft, restore)
            if not success or NativeDirection() ~= restore then return end
        end
        Suite.db.bagSortDirectionRestore = nil
    end)
end

local function Integer(value, maximum)
    return Suite.IsReadable(value) and type(value) == "number" and value == value
        and value >= 0 and value <= maximum and value == math.floor(value)
end

local function CarriedBag(frame)
    if not Suite.IsReadable(frame) or (type(frame) ~= "table" and type(frame) ~= "userdata") then return false end
    if type(frame.IsForbidden) == "function" then
        local forbidden = frame:IsForbidden()
        if not Suite.IsReadable(forbidden) or forbidden ~= false then return false end
    end
    if frame == ContainerFrameCombinedBags then return true end
    local getID = frame.GetBagID or frame.GetID
    if type(getID) ~= "function" then return false end
    local id = getID(frame)
    if not Integer(id, 32) then return false end
    if id == 0 then return true end
    return Integer(NUM_TOTAL_EQUIPPED_BAG_SLOTS, 32) and id <= NUM_TOTAL_EQUIPPED_BAG_SLOTS
end

local function Shown(frame)
    if not CarriedBag(frame) or type(frame.IsShown) ~= "function" then return false end
    local shown = frame:IsShown()
    return Suite.IsReadable(shown) and shown == true
end

function BagSort:CancelWork()
    self.work = nil
    if self.timer then self.timer:Cancel(); self.timer = nil end
end

function BagSort:Clear()
    self:CancelWork()
    self.visit = nil
end

function BagSort:HasOpenBag()
    if not self.visit then return false end
    for frame in pairs(self.visit.frames) do
        if Shown(frame) then return true end
        self.visit.frames[frame] = nil
    end
    return false
end

function BagSort:Queue()
    if self.work or not self.active or not Enabled() or not self.visit or self.visit.requested then return end
    if InCombatLockdown() or not C_Timer or type(C_Timer.NewTimer) ~= "function" then return end
    local visit, work = self.visit, {}
    self.work = work
    -- Wait for the whole native opening pass; all numbered bags share one sort request.
    self.timer = C_Timer.NewTimer(0, function()
        if self.work ~= work then return end
        self.work, self.timer = nil, nil
        if self.visit ~= visit or visit.requested or not self.active or not Enabled() or InCombatLockdown() then return end
        if not self:HasOpenBag() then self:Clear(); return end
        if not C_Container or type(C_Container.SortBags) ~= "function" or type(CursorHasItem) ~= "function" then return end
        local held = CursorHasItem()
        if self.visit ~= visit or visit.requested or not self.active or not Enabled() or InCombatLockdown() then return end
        -- Leave an item being moved alone; reopen the bags to request another pass.
        visit.requested = true
        if not Suite.IsReadable(held) or held ~= false then return end
        C_Container.SortBags()
    end)
end

function BagSort:Opened(frame)
    if not self.active or not Enabled() or not Shown(frame) then return end
    if not self:HasOpenBag() then self:Clear(); self.visit = { frames = {} } end
    self.visit.frames[frame] = true
    self:Queue()
end

function BagSort:Closed(frame)
    if not self.active or not self.visit or not Suite.IsReadable(frame) then return end
    if type(frame) ~= "table" and type(frame) ~= "userdata" then return end
    self.visit.frames[frame] = nil
    if not self:HasOpenBag() then self:Clear() end
end

function BagSort:OnEvent(event)
    if not self.active then return end
    if event == "PLAYER_ENTERING_WORLD" then self:Clear()
    elseif event == "PLAYER_REGEN_DISABLED" then self:CancelWork()
    elseif event == "PLAYER_REGEN_ENABLED" then self:Queue() end
end

function BagSort:Apply()
    self:RestoreDirection()
    Suite.pending.bagSort = nil
    if not Enabled() then
        self.active = nil
        self:Clear()
        if self.registry then
            self.registry:UnregisterCallback("ContainerFrame.OpenBag", self)
            self.registry:UnregisterCallback("ContainerFrame.CloseBag", self)
            self.registry = nil
        end
        if self.events then self.events:UnregisterAllEvents() end
        return
    end
    if self.active then return end
    Suite.AfterCombat("bagSort", function()
        if not Enabled() or not EventRegistry or type(EventRegistry.RegisterCallback) ~= "function"
            or type(EventRegistry.UnregisterCallback) ~= "function" then return end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event) self:OnEvent(event) end)
        end
        self.active, self.registry = true, EventRegistry
        self.registry:RegisterCallback("ContainerFrame.OpenBag", self.Opened, self)
        self.registry:RegisterCallback("ContainerFrame.CloseBag", self.Closed, self)
        for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
            self.events:RegisterEvent(event)
        end
        -- Enabling affects the next opening rather than rearranging bags already on screen.
        self.visit = { frames = {}, requested = true }
        if Shown(ContainerFrameCombinedBags) then self.visit.frames[ContainerFrameCombinedBags] = true end
        if Integer(NUM_CONTAINER_FRAMES, 64) then
            for index = 1, NUM_CONTAINER_FRAMES do
                local frame = _G["ContainerFrame" .. index]
                if Shown(frame) then self.visit.frames[frame] = true end
            end
        end
        if not self:HasOpenBag() then self.visit = nil end
    end)
end
