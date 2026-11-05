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
function Bars:CaptureText(text)
    if not self:Accessible(text) then return end
    if text.IsAnchoringRestricted and Read(text.IsAnchoringRestricted, text) ~= false then return end
    for _, method in ipairs({ "GetFont", "GetPoint", "GetNumPoints", "GetWidth", "GetHeight", "GetJustifyH", "GetJustifyV",
        "SetFont", "ClearAllPoints", "SetPoint", "SetSize", "SetJustifyH", "SetJustifyV" }) do
        if type(text[method]) ~= "function" then return end
    end
    local ok, face, size, flags = pcall(text.GetFont, text)
    if not ok or not Suite.IsReadable(face) or type(face) ~= "string" or face == ""
        or not Number(size, 1, 100) or not Suite.IsReadable(flags) or flags ~= nil and type(flags) ~= "string" then return end
    local width, height = Read(text.GetWidth, text, true), Read(text.GetHeight, text, true)
    local horizontal, vertical = Read(text.GetJustifyH, text), Read(text.GetJustifyV, text)
    local count = Read(text.GetNumPoints, text)
    if not Number(width, 0, 5000) or not Number(height, 0, 5000) or not Number(count, 0, 8) or count % 1 ~= 0
        or type(horizontal) ~= "string" or type(vertical) ~= "string" then return end
    local points = {}
    for index = 1, count do
        local ready, point, relative, relativePoint, x, y = pcall(text.GetPoint, text, index)
        if not ready or not Suite.IsReadable(point) or type(point) ~= "string" or not Suite.IsReadable(relative)
            or not Suite.IsReadable(relativePoint) or type(relativePoint) ~= "string"
            or not Number(x, -1000000, 1000000) or not Number(y, -1000000, 1000000) then return end
        points[index] = { point, relative, relativePoint, x, y }
    end
    local fontObject = Read(text.GetFontObject,text)
    if type(fontObject) ~= "table" and type(fontObject) ~= "userdata" and type(fontObject) ~= "string" then fontObject = nil end
    return { object=text, font={face,size,flags or ""}, fontObject=fontObject,
        width=width, height=height, horizontal=horizontal, vertical=vertical, points=points }
end
function Bars:LayoutText(frame, record, settings)
    if InCombatLockdown() or not Suite.IsReadable(frame.Text) then return end
    record.text = record.text or self:CaptureText(frame.Text)
    local style = record.text
    if not style or style.object ~= frame.Text or not self:Accessible(style.object) then return end
    local text = style.object
    if text.IsAnchoringRestricted and Read(text.IsAnchoringRestricted, text) ~= false then return end
    -- Only public configured dimensions drive text geometry. Native spell names
    -- and casting/channel state remain untouched, including secret text values.
    local size = math.max(8, math.min(28, math.floor(settings.height * 0.5 + 0.5)))
    text:SetFont(style.font[1], size, style.font[3])
    text:ClearAllPoints(); text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    text:SetSize(settings.width - 12, settings.height)
    text:SetJustifyH("CENTER"); text:SetJustifyV("MIDDLE")
end
function Bars:RestoreText(style)
    if InCombatLockdown() or not style or not self:Accessible(style.object) then return end
    local text = style.object
    if text.IsAnchoringRestricted and Read(text.IsAnchoringRestricted, text) ~= false then return end
    if style.fontObject and type(text.SetFontObject) == "function" then text:SetFontObject(style.fontObject)
    else text:SetFont(unpack(style.font)) end
    text:ClearAllPoints(); text:SetSize(style.width, style.height)
    for _, point in ipairs(style.points) do text:SetPoint(unpack(point, 1, 5)) end
    text:SetJustifyH(style.horizontal); text:SetJustifyV(style.vertical)
end
function Bars:LayoutSpark(frame, record, settings)
    if InCombatLockdown() or not Suite.IsReadable(frame.Spark) then return end
    local spark = frame.Spark
    if not self:Accessible(spark) or type(spark.SetHeight) ~= "function" then return end
    if not record.spark then
        local height = Read(spark.GetHeight, spark, true)
        if not Number(height, 1, 5000) then return end
        record.spark = { object=spark, height=height }
    end
    if record.spark.object ~= spark then return end
    -- Preserve the native vertical overhang. Never read or change the moving
    -- spark's anchors, visibility, texture, width or cast-progress position.
    spark:SetHeight(math.max(1, settings.height + record.spark.height - record.height))
end
function Bars:LayoutEffects(frame, record, settings)
    if InCombatLockdown() then return end
    record.effects = record.effects or {}
    -- Native moving highlights/shadows are clipped by a separate fixed-height
    -- mask. Resize both; retain native widths, anchors, visibility and animation.
    for _, key in ipairs({ "StandardGlow", "CraftGlow", "ChannelShadow", "BorderMask" }) do
        local object = frame[key]
        if self:Accessible(object) and type(object.SetHeight) == "function" then
            local saved = record.effects[key]
            if not saved then
                local height = Read(object.GetHeight, object, true)
                if Number(height, 1, 5000) then
                    saved = { object=object, height=height }; record.effects[key] = saved
                end
            end
            if saved and saved.object == object then
                object:SetHeight(math.max(1, settings.height + saved.height - record.height))
            end
        end
    end
end
function Bars:Restore(frame, record)
    if InCombatLockdown() or not self:Accessible(frame) then return end
    frame:SetSize(record.width, record.height)
    self:RestoreText(record.text)
    if record.spark and self:Accessible(record.spark.object) then record.spark.object:SetHeight(record.spark.height) end
    for _, saved in pairs(record.effects or {}) do
        if self:Accessible(saved.object) then saved.object:SetHeight(saved.height) end
    end
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
                if record then
                    frame:SetSize(settings.width, settings.height)
                    self:LayoutText(frame, record, settings)
                    self:LayoutSpark(frame, record, settings)
                    self:LayoutEffects(frame, record, settings)
                end
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
