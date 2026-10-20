local _, Suite = ...
local Helper = {}
Suite.ProfessionHelper = Helper
table.insert(Suite.modules, Helper)
local function Read(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Int(value, low, high)
    return Suite.IsReadable(value) and type(value) == "number" and value >= low and value <= high and value == math.floor(value)
end
local keys = { alt = true, ctrl = true, shift = true }
function Helper:Modifier()
    local value = Suite.db and Suite.db.disenchantModifier
    return Suite.IsReadable(value) and type(value) == "string" and keys[value] and value or "alt"
end
function Helper:Enabled() return Suite.db and Suite.IsReadable(Suite.db.modifierDisenchant) and Suite.db.modifierDisenchant == true end
function Helper:Held()
    local selected = self:Modifier()
    for key in pairs(keys) do
        -- Fetch at call time, including clients where a modifier capability is absent.
        local fn = key == "alt" and IsAltKeyDown or key == "ctrl" and IsControlKeyDown or IsShiftKeyDown
        local held = Read(fn)
        if type(held) ~= "boolean" or held ~= (key == selected) then return false end
    end
    return true
end
function Helper:Eligible(bag, slot)
    if InCombatLockdown() or not self:Enabled() or not self:Held() or not Int(bag, 0, 5) or not Int(slot, 1, 200)
        or Read(C_SpellBook and C_SpellBook.IsSpellKnown, 13262) ~= true then return end
    if Read(UnitIsDeadOrGhost, "player") ~= false then return end
    for _, name in ipairs({ "UnitCastingInfo", "UnitChannelInfo" }) do
        local fn = _G[name]
        if type(fn) ~= "function" then return end
        local ok, name = pcall(fn, "player")
        if not ok or not Suite.IsReadable(name) or name ~= nil then return end
    end
    if type(GetCursorInfo) ~= "function" then return end
    local cursorOK, cursor = pcall(GetCursorInfo)
    if not cursorOK or not Suite.IsReadable(cursor) or cursor ~= nil then return end
    local info = Read(C_Container and C_Container.GetContainerItemInfo, bag, slot)
    if type(info) ~= "table" or not Int(info.itemID, 1, 10000000) or not Int(info.stackCount, 1, 1000000000)
        or not Suite.IsReadable(info.isLocked) or info.isLocked ~= false then return end
    if not C_Item or type(C_Item.GetItemInfo) ~= "function" then return end
    local ok, _, _, quality, _, _, _, _, _, equip, _, _, class = pcall(C_Item.GetItemInfo, info.itemID)
    if not ok or not Int(quality, 2, 4) or not Int(class, 0, 30) or class ~= 2 and class ~= 4
        or not Suite.IsReadable(equip) or type(equip) ~= "string" or equip == "" or equip == "INVTYPE_BODY" or equip == "INVTYPE_TABARD" then return end
    return info.itemID
end
function Helper:Slot(frame)
    for _ = 1, 5 do
        if not Suite.IsReadable(frame) or not frame or Read(frame.IsForbidden, frame) ~= false then return end
        if frame == self.button then return self.owner, self.bag, self.slot end
        if type(frame.GetBagID) == "function" and type(frame.GetID) == "function" then
            local bag, slot = Read(frame.GetBagID, frame), Read(frame.GetID, frame)
            if Int(bag, 0, 5) and Int(slot, 1, 200) then return frame, bag, slot end
        end
        frame = Read(frame.GetParent, frame)
    end
end
function Helper:Hide()
    if InCombatLockdown() then Suite.pending.professionHide = function() self:Hide() end; return end
    if self.button then
        self.button:Hide()
        for key in pairs(keys) do self.button:SetAttribute(key .. "-type1", nil) end
        self.button:SetAttribute("target-bag", nil); self.button:SetAttribute("target-slot", nil)
    end
    self.owner, self.bag, self.slot, self.item = nil, nil, nil, nil
end
function Helper:Refresh()
    if InCombatLockdown() then return end
    if not self:Enabled() or not self:Held() then self:Hide(); return end
    local foci = Read(GetMouseFoci)
    if type(foci) ~= "table" then self:Hide(); return end
    local owner, bag, slot
    for _, focus in ipairs(foci) do owner, bag, slot = self:Slot(focus); if owner then break end end
    local id = owner and self:Eligible(bag, slot)
    if not id or Read(owner.IsShown, owner) ~= true or Read(owner.IsProtected, owner) ~= false then self:Hide(); return end
    local left, bottom, width, height = Read(owner.GetLeft, owner), Read(owner.GetBottom, owner), Read(owner.GetWidth, owner), Read(owner.GetHeight, owner)
    local scale, rootScale = Read(owner.GetEffectiveScale, owner), Read(UIParent.GetEffectiveScale, UIParent)
    for _, number in ipairs({ left or false, bottom or false, width or false, height or false, scale or false, rootScale or false }) do
        if not Suite.IsReadable(number) or type(number) ~= "number" or number ~= number or math.abs(number) > 100000 then self:Hide(); return end
    end
    if width <= 0 or height <= 0 or scale <= 0 or rootScale <= 0 then self:Hide(); return end
    local ratio = scale / rootScale
    if ratio ~= ratio or ratio <= 0 or ratio > 100000 then self:Hide(); return end
    self.owner, self.bag, self.slot, self.item = owner, bag, slot, id
    for key in pairs(keys) do self.button:SetAttribute(key .. "-type1", nil) end
    self.button:SetAttribute(self:Modifier() .. "-type1", "spell"); self.button:SetAttribute("spell", 13262)
    self.button:SetAttribute("target-bag", bag); self.button:SetAttribute("target-slot", slot)
    self.button:ClearAllPoints(); self.button:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left * ratio, bottom * ratio)
    self.button:SetSize(width * ratio, height * ratio); self.button:Show()
end
function Helper:Queue()
    if not self:Enabled() or InCombatLockdown() or self.timer then return end
    if C_Timer and C_Timer.NewTimer then self.timer = C_Timer.NewTimer(0, function() self.timer = nil; self:Refresh() end) end
end
function Helper:Build()
    if self.button then return true end
    if InCombatLockdown() or type(RegisterStateDriver) ~= "function" then return false end
    self.controller = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
    self.button = CreateFrame("Button", nil, self.controller, "SecureActionButtonTemplate,BackdropTemplate")
    local button = self.button
    button:Hide(); button:RegisterForClicks("AnyDown", "AnyUp"); button:SetAttribute("useOnKeyDown", false)
    if type(button.SetPassThroughButtons) == "function" then button:SetPassThroughButtons("RightButton", "MiddleButton", "Button4", "Button5") end
    button:SetFrameStrata("TOOLTIP"); button:SetFrameLevel(600)
    button:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 }); Suite.Theme:Backdrop(button, 1)
    self.controller:SetFrameRef("button", button)
    self.controller:SetAttribute("_onstate-activation", [[
        if newstate == "blocked" then
            local button = self:GetFrameRef("button")
            button:SetAttribute("alt-type1", nil); button:SetAttribute("ctrl-type1", nil); button:SetAttribute("shift-type1", nil)
            button:SetAttribute("target-bag", nil); button:SetAttribute("target-slot", nil)
            button:Hide(); self:Hide()
        else self:Show() end
    ]])
    button:SetScript("PreClick", function(_, _, down)
        if InCombatLockdown() or down then return end
        local owner, bag, slot = self:Slot(self.owner)
        if not self.item or owner ~= self.owner or bag ~= self.bag or slot ~= self.slot
            or Read(owner and owner.IsShown, owner) ~= true or self:Eligible(self.bag, self.slot) ~= self.item then
            for key in pairs(keys) do button:SetAttribute(key .. "-type1", nil) end
            button:SetAttribute("target-bag", nil); button:SetAttribute("target-slot", nil)
        end
    end)
    button:SetScript("PostClick", function(_, _, down) if not down then self:Hide(); self:Queue() end end)
    button:SetScript("OnLeave", function() self:Queue() end)
    button:SetScript("OnEnter", function()
        if InCombatLockdown() or not self.item or not GameTooltip or Read(GameTooltip.IsForbidden, GameTooltip) ~= false then return end
        if type(GameTooltip.SetBagItem) ~= "function" then return end
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT"); GameTooltip:SetBagItem(self.bag, self.slot)
        GameTooltip:AddLine("Modifier-click: Disenchant (destroys this item)", 0.41, 0.84, 0.75); GameTooltip:Show()
    end)
    return true
end
function Helper:Apply()
    Suite.pending.professions = nil
    if self.timer then self.timer:Cancel(); self.timer = nil end
    if not self:Enabled() then
        if self.events then self.events:UnregisterAllEvents() end
        self:Hide(); return
    end
    Suite.pending.professionHide = nil
    Suite.AfterCombat("professions", function()
        if not self:Enabled() or not self:Build() then return end
        local mod, condition = self:Modifier(), ""
        for key in pairs(keys) do if key ~= mod then condition = condition .. ",nomod:" .. key end end
        RegisterStateDriver(self.controller, "activation", "[combat] blocked; [mod:" .. mod .. condition .. "] ready; blocked")
        if not self.events then self.events = CreateFrame("Frame"); self.events:SetScript("OnEvent", function() self:Queue() end) end
        for _, event in ipairs({ "MODIFIER_STATE_CHANGED", "BAG_UPDATE_DELAYED", "PLAYER_REGEN_ENABLED", "SPELLS_CHANGED" }) do pcall(self.events.RegisterEvent, self.events, event) end
        if not self.hooked and TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
                if tooltip == GameTooltip then self:Queue() end
            end); self.hooked = true
        end
        self:Refresh()
    end)
end
