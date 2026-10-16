local _, Suite = ...
local Bars = { records = {}, hooked = {} }
Suite.Castbars = Bars
table.insert(Suite.modules, Bars)
Bars.order = { "player", "target", "focus" }
local function Read(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Number(value, low, high)
    return Suite.IsReadable(value) and type(value) == "number" and value >= low and value <= high and value == value
end
function Bars:Options(key)
    local all = Suite.db and Suite.db.castbars
    local value = Suite.IsReadable(all) and type(all) == "table" and all[key]
    value = Suite.IsReadable(value) and type(value) == "table" and value or {}
    return { enabled = Suite.IsReadable(value.enabled) and value.enabled == true,
        width = Number(value.width, 80, 600) and math.floor(value.width) or 195,
        height = Number(value.height, 8, 60) and math.floor(value.height) or 20 }
end
function Bars:Set(key, option, value)
    if not Suite.IsReadable(key) or type(key) ~= "string" or not ({ player=true, target=true, focus=true })[key]
        or not Suite.IsReadable(option) or not Suite.IsReadable(value) then return end
    local settings = self:Options(key)
    if option == "enabled" and type(value) == "boolean" then settings.enabled = value
    elseif option == "width" and Number(value, 80, 600) then settings.width = math.floor(value)
    elseif option == "height" and Number(value, 8, 60) then settings.height = math.floor(value)
    else return end
    if not Suite.IsReadable(Suite.db.castbars) or type(Suite.db.castbars) ~= "table" then Suite.db.castbars = {} end
    Suite.db.castbars[key] = settings; self:Apply()
end
function Bars:Frame(key)
    if not Suite.IsReadable(key) or type(key) ~= "string" or not ({player=true,target=true,focus=true})[key] then return end
    if key == "player" then return PlayerCastingBarFrame end
    local owner = key == "target" and TargetFrame or FocusFrame
    return Suite.IsReadable(owner) and owner and owner.spellbar or nil
end
function Bars:Accessible(frame)
    return Suite.IsReadable(frame) and frame and Read(frame.IsForbidden, frame) == false
end
function Bars:EditMode()
    if not EditModeManagerFrame then return false end
    return Read(EditModeManagerFrame.IsShown, EditModeManagerFrame) ~= false
end
function Bars:Restore(frame, record)
    if not self:Accessible(frame) then return end
    frame:SetSize(record.width, record.height)
    self.records[frame] = nil
end
function Bars:Refresh()
    if InCombatLockdown() then Suite.pending.castbars = function() self:Refresh() end; return end
    if self:EditMode() then
        self:StopPreview()
        for frame, record in pairs(self.records) do self:Restore(frame, record) end
        return
    end
    self.changing = true
    local used = {}
    for _, key in ipairs(self.order) do
        local frame, settings = self:Frame(key), self:Options(key)
        if self:Accessible(frame) then
            used[frame] = settings.enabled
            local record = self.records[frame]
            if settings.enabled then
                if not record then
                    -- Target/focus anchor to aura layout. Read configured dimensions,
                    -- not its resolved rectangle (which may carry anchor secrecy).
                    -- Returned values still require the ordinary readability checks.
                    local width, height = Read(frame.GetWidth, frame, true), Read(frame.GetHeight, frame, true)
                    if Number(width, 1, 5000) and Number(height, 1, 5000) then
                        record = { width=width, height=height }; self.records[frame] = record
                    end
                end
                if record then frame:SetSize(settings.width, settings.height) end
                if not self.hooked[frame] then
                    for _, method in ipairs({ "SetSize", "SetWidth", "SetHeight" }) do
                        hooksecurefunc(frame, method, function() if not self.changing then self:Queue() end end)
                    end
                    frame:HookScript("OnShow", function() self:Queue() end)
                    for _, method in ipairs({ "SetLook", "AdjustPosition" }) do
                        if type(frame[method]) == "function" then
                            hooksecurefunc(frame, method, function() if not self.changing then self:Queue() end end)
                        end
                    end
                    self.hooked[frame] = true
                end
            end
        end
    end
    for frame, record in pairs(self.records) do if not used[frame] then self:Restore(frame, record) end end
    self.changing = nil
end
function Bars:SizeStatus(key)
    if not self:Options(key).enabled then return end
    if InCombatLockdown() then return "Size changes will apply after combat." end
    if self:EditMode() then return "Size changes will apply after Edit Mode closes." end
    local frame = self:Frame(key)
    if not self:Accessible(frame) then return "Native castbar is not available yet." end
    if not self.records[frame] then return "Native size is unavailable; custom size has not been applied." end
end
function Bars:StopPreview()
    if not self.preview then return true end
    if InCombatLockdown() then Suite.pending.castbarPreview = function() self:StopPreview() end; return false end
    local preview = self.preview; self.preview = nil
    if self:Accessible(preview.frame) and not self:EditMode() then
        preview.frame.isInEditMode = preview.old
        if type(preview.frame.UpdateShownState) == "function" then pcall(preview.frame.UpdateShownState, preview.frame) end
    end
    Suite.pending.castbarPreview = nil
    local active = false
    for _, key in ipairs(self.order) do active = active or self:Options(key).enabled end
    if not active and self.events then self.events:UnregisterAllEvents() end
    if Suite.GUI and Suite.GUI.page == "castbars" and Suite.GUI.castbarPanel then
        Suite.GUI.castbarMessage = "Preview stopped."; Suite.GUI:RefreshCastbars()
    end
    return true
end
function Bars:Preview(key)
    if not Suite.IsReadable(key) or type(key) ~= "string" or not ({player=true,target=true,focus=true})[key] then return false, "Choose a supported castbar." end
    if InCombatLockdown() or self:EditMode() then return false, "Preview is available outside combat and Edit Mode." end
    if not self:StopPreview() then return false, "Previous preview is waiting for combat to end." end
    local frame = self:Frame(key)
    if not self:Accessible(frame) or type(frame.UpdateShownState) ~= "function" then return false, "This native castbar cannot be previewed." end
    if key ~= "player" then
        local owner = key == "target" and TargetFrame or FocusFrame
        if Read(owner.IsShown, owner) ~= true then return false, "Select a visible " .. key .. " first." end
    end
    for _, name in ipairs({ "UnitCastingInfo", "UnitChannelInfo" }) do
        local fn = _G[name]
        if type(fn) ~= "function" then return false, "Cast state unavailable." end
        local ok, value = pcall(fn, key)
        if not ok or not Suite.IsReadable(value) or value ~= nil then return false, "Wait until this unit finishes casting." end
    end
    if not Suite.IsReadable(frame.isInEditMode) or frame.isInEditMode ~= nil and type(frame.isInEditMode) ~= "boolean" then return false, "Preview state unavailable." end
    if frame.isInEditMode == true then return false, "The game is already previewing this castbar." end
    self.preview = { frame=frame, key=key, old=frame.isInEditMode }
    frame.isInEditMode = true
    local ok = pcall(frame.UpdateShownState, frame, true)
    if not ok then self:StopPreview(); return false, "Native preview unavailable." end
    self:Apply()
    return true, "Preview is on. Native position is kept."
end
function Bars:Queue()
    if self.changing or self.timer then return end
    local active = self.preview ~= nil or next(self.records) ~= nil
    for _, key in ipairs(self.order) do active = active or self:Options(key).enabled end
    if not active then return end
    if InCombatLockdown() then Suite.pending.castbars = function() self:Refresh() end; return end
    if C_Timer and C_Timer.NewTimer then self.timer = C_Timer.NewTimer(0.05, function() self.timer = nil; self:Refresh() end) end
end
function Bars:Apply()
    if self.timer then self.timer:Cancel(); self.timer = nil end
    local active = self.preview ~= nil
    for _, key in ipairs(self.order) do active = active or self:Options(key).enabled end
    if not active and self.events then self.events:UnregisterAllEvents() end
    if not active and not next(self.records) then Suite.pending.castbars = nil; return end
    Suite.AfterCombat("castbars", function()
        if active then
            if not self.events then self.events = CreateFrame("Frame") end
            self.events:SetScript("OnEvent", function(_, event, unit)
                if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED"
                    or self.preview and Suite.IsReadable(unit) and unit == self.preview.key then self:StopPreview() end
                self:Queue()
            end)
            for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
                "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START" }) do pcall(self.events.RegisterEvent, self.events, event) end
            if EditModeManagerFrame and not self.editHooked then
                EditModeManagerFrame:HookScript("OnShow", function() self:StopPreview(); self:Queue() end)
                EditModeManagerFrame:HookScript("OnHide", function() self:Queue() end); self.editHooked = true
            end
        end
        self:Refresh()
    end)
end
