-- Behavioral tests with explicit WoW API substitutes. The actual client remains the UI authority.
unpack = table.unpack or unpack
local checks = 0
local function equal(actual, expected, label)
    checks = checks + 1
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local combat = false
local controlDown = false
local cursorX, cursorY = 0, 0
function GetCursorPosition() return cursorX, cursorY end
local queued = {}
local frames = {}
local function Frame(name)
    local frame = {
        name = name, width = 0, height = 0, scale = 1, lines = {}, children = {},
        RegisterEvent = function() end, UnregisterAllEvents = function() end,
        SetScript = function(self, event, callback) self[event] = callback end,
        HookScript = function(self, event, callback)
            local original = self[event]
            self[event] = function(...)
                if original then original(...) end
                callback(...)
            end
        end,
        SetShown = function(self, shown) self.shown = shown end,
        IsShown = function(self) return self.shown == true end,
        IsVisible = function(self) return self.shown == true end,
        Show = function(self) self.shown = true end, Hide = function(self) self.shown = false end,
        GetName = function(self) return self.name end,
        GetObjectType = function(self) return self.objectType or "Frame" end,
        GetScript = function(self, event) return self[event] end,
        HasScript = function() return true end,
        SetWidth = function(self, width) self.width = width end,
        SetHeight = function(self, height) self.height = height end,
        SetSize = function(self, width, height) self.width, self.height = width, height end,
        SetPoint = function(self, ...) self.point = { ... } end,
        ClearAllPoints = function(self) self.point = nil end,
        GetPoint = function(self) return unpack(self.point) end,
        GetNumPoints = function(self) return self.point and 1 or 0 end,
        GetWidth = function(self) return self.width end, GetHeight = function(self) return self.height end,
        GetScale = function(self) return self.scale end,
        GetEffectiveScale = function(self) return self.scale * (self.parent and self.parent:GetEffectiveScale() or 1) end,
        SetScale = function(self, scale) self.scale = scale end,
        GetCenter = function(self) return self.centerX or 500, self.centerY or 400 end,
        GetRect = function(self)
            if self.rect then return unpack(self.rect) end
            return (self.centerX or 500) - self.width / 2, (self.centerY or 400) - self.height / 2, self.width, self.height
        end,
        GetChildren = function(self) return unpack(self.children) end,
        GetHitRectInsets = function(self) return unpack(self.insets or { 0, 0, 0, 0 }) end,
        IsMouseClickEnabled = function(self) return self.mouseEnabled == true end,
        GetFrameStrata = function() return "MEDIUM" end, GetFrameLevel = function(self) return self.frameLevel or 5 end,
        GetParent = function(self) return self.parent end,
        IsMovable = function(self) return self.movable == true end,
        StartMoving = function(self) self.moving = true end,
        StopMovingOrSizing = function(self) self.moving = false end,
        AddDoubleLine = function(self, label, value) self.lines[#self.lines + 1] = { label, value } end,
        AddLine = function(self, text) self.lines[#self.lines + 1] = { text } end,
        SetText = function(self, text) self.text = text end,
        GetText = function(self) return self.text or "" end,
        SetEnabled = function(self, enabled) self.enabled = enabled end,
        SetChecked = function(self, checked) self.checked = checked end,
        GetChecked = function(self) return self.checked end,
        SetMultiLine = function() end, SetAutoFocus = function() end, ClearFocus = function() end,
        SetTextInsets = function(self, ...) self.textInsets = { ... } end,
        SetVerticalScroll = function(self, value)
            self.verticalScroll = value
            if self.OnVerticalScroll then self.OnVerticalScroll(self, value) end
        end,
        SetParent = function(self, parent) self.parent = parent end,
        SetNumeric = function(self, numeric) self.numeric = numeric end,
        SetMaxLetters = function(self, count) self.maxLetters = count end,
        SetScrollChild = function(self, child) self.scrollChild = child end,
        SetTextColor = function(self, ...) self.textColor = { ... } end,
        SetDrawLayer = function(self, layer, sublevel) self.drawLayer, self.drawSublevel = layer, sublevel end,
        SetFont = function(self, font, size, flags)
            -- Unlike FontString, this client's EditBox requires the flags argument.
            if self.objectType == "EditBox" then assert(type(flags) == "string", "EditBox:SetFont requires font flags") end
            self.fontPath, self.fontSize, self.fontFlags = font, size, flags
            return true
        end,
        SetJustifyH = function(self, justify) self.justifyH = justify end, SetJustifyV = function() end,
        SetWordWrap = function(self, wrap) self.wordWrap = wrap end,
        SetNonSpaceWrap = function() end,
        GetUnboundedStringWidth = function(self) return #(self.text or "") * (self.fontSize or 10) * 0.5 end,
        GetStringHeight = function(self)
            local lines = self.wordWrap and math.max(1, math.ceil(self:GetUnboundedStringWidth() / math.max(1, self.width))) or 1
            return lines * ((self.fontSize or 10) + 2)
        end,
        SetBackdrop = function(self, backdrop) self.backdrop = backdrop end,
        SetBackdropColor = function(self, r, g, b, a) self.backdropAlpha = a end,
        SetBackdropBorderColor = function(self, ...) self.borderColor = { ... } end, SetColorTexture = function() end,
        SetTexture = function(self, texture) self.texture = texture end,
        AddMaskTexture = function(self, mask) self.maskTexture = mask end,
        SetFrameStrata = function(self, strata) self.strata = strata end,
        SetFrameLevel = function(self, level) self.frameLevel = level end,
        SetClampedToScreen = function(self, clamped) self.clamped = clamped end,
        IsClampedToScreen = function(self) return self.clamped == true end,
        SetMovable = function(self, movable) self.movable = movable end,
        EnableMouse = function(self, enabled) self.mouseEnabled = enabled end,
        EnableMouseWheel = function(self, enabled) self.wheelEnabled = enabled end,
        RegisterForDrag = function() end, RegisterForClicks = function(self, ...) self.clicks = { ... } end,
    }
    frame.CreateFontString = function(_, _, layer)
        local text = Frame()
        text.drawLayer = layer
        return text
    end
    frame.CreateTexture = function() return Frame() end
    frame.CreateMaskTexture = function() return Frame() end
    frame.SetOrientation = function(self, orientation) self.orientation = orientation end
    frame.SetMinMaxValues = function(self, low, high) self.low, self.high = low, high end
    frame.SetValueStep = function(self, step) self.step = step end
    frame.SetObeyStepOnDrag = function(self, obey) self.obeyStep = obey end
    frame.SetThumbTexture = function(self, texture) self.thumb = type(texture) == "table" and texture or Frame() end
    frame.GetThumbTexture = function(self) return self.thumb end
    frame.SetValue = function(self, value) self.value = value; if self.OnValueChanged then self.OnValueChanged(self, value) end end
    frame.SetShadowColor = function(self, ...) self.shadowColor = { ... } end
    frame.SetShadowOffset = function(self, ...) self.shadowOffset = { ... } end
    return frame
end
function CreateFrame(kind, name, parent)
    local frame = Frame(name)
    frame.objectType = kind
    frame.parent = parent
    if parent and parent.children then parent.children[#parent.children + 1] = frame end
    if parent and parent.GetFrameLevel then frame.frameLevel = parent:GetFrameLevel() + 1 end
    frames[#frames + 1] = frame
    return frame
end
function InCombatLockdown() return combat end
function issecretvalue(value) return type(value) == "table" and value.secret == true end
function canaccessvalue(value) return not issecretvalue(value) end
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
SlashCmdList = {}
C_Timer = { After = function(_, callback) queued[#queued + 1] = callback end }
C_Timer.NewTimer = function(_, callback)
    local timer = { Cancel = function(self) self.cancelled = true end }
    queued[#queued + 1] = function() if not timer.cancelled then callback() end end
    return timer
end
function hooksecurefunc(target, method, callback)
    if type(target) == "string" then callback, method, target = method, target, _G end
    local original = target[method]
    local function Pack(...) return { n = select("#", ...), ... } end
    target[method] = function(...)
        local result = original and Pack(original(...))
        callback(...)
        if result then return unpack(result, 1, result.n) end
    end
end
function IsControlKeyDown() return controlDown end
function GetTime() return 20 end
function UnitLevel() return 30 end
function UnitIsUnit(unit, other) return unit == other end
function UnitIsPlayer() return true end
function UnitGUID(unit) return "guid:" .. unit end
function CanInspect() return true end
local inspectRequests = 0
function NotifyInspect() inspectRequests = inspectRequests + 1 end
C_PaperDollInfo = { GetInspectItemLevel = function() return 0 end }
local equipment = {}
function GetInventoryItemLink(_, slot) return equipment[slot] end

local items = {
    old = { level = 12, equip = "INVTYPE_HEAD", stats = { ITEM_MOD_INTELLECT_SHORT = 3 }, usable = true },
    better = { level = 20, equip = "INVTYPE_HEAD", stats = { ITEM_MOD_INTELLECT_SHORT = 8 }, usable = true },
    worse = { level = 25, equip = "INVTYPE_HEAD", stats = { ITEM_MOD_INTELLECT_SHORT = 2 }, usable = true },
    future = { level = 30, required = 40, equip = "INVTYPE_HEAD", stats = { ITEM_MOD_INTELLECT_SHORT = 20 }, usable = true },
    ring = { level = 20, equip = "INVTYPE_FINGER", stats = { ITEM_MOD_INTELLECT_SHORT = 6 }, usable = true },
    ring1 = { level = 25, equip = "INVTYPE_FINGER", stats = { ITEM_MOD_INTELLECT_SHORT = 9 }, usable = true },
    ring2 = { level = 12, equip = "INVTYPE_FINGER", stats = { ITEM_MOD_INTELLECT_SHORT = 3 }, usable = true },
    weapon = { level = 25, equip = "INVTYPE_2HWEAPON", stats = { ITEM_MOD_INTELLECT_SHORT = 12 }, usable = true },
    forbidden = { level = 25, equip = "INVTYPE_HEAD", stats = { ITEM_MOD_INTELLECT_SHORT = 12 }, usable = false },
}
C_Item = {
    GetItemInfo = function(item)
        local data = items[item]
        if not data then return nil end
        return item, item, 2, data.level, data.required or 1, "Armor", "Cloth", 1, data.equip
    end,
    GetDetailedItemLevelInfo = function(item) return items[item] and items[item].level end,
    GetItemInfoInstant = function() return 999 end,
    RequestLoadItemDataByID = function() end,
    GetItemStats = function(item) return items[item] and items[item].stats end,
    IsUsableItem = function(item) return items[item] and items[item].usable end,
}

local Suite = {}
for _, file in ipairs(WFS_TEST_FILES) do
    assert(loadfile("src/WoWForeverSuite/" .. file))("WoWForeverSuite", Suite)
end
Suite.db = Suite.InitializeDB(nil)
Suite.Macros:Initialize(nil)
equal(Suite.db.squareMinimap, false, "features start off")
equal(Suite.db.windowTools, false, "window tools start off")
local saved = { scorePreset = "invalid", itemLevels = true, windowPositions = "corrupt" }
Suite.InitializeDB(saved)
equal(saved.itemLevels, true, "preserve valid saved preference")
equal(saved.scorePreset, "balanced", "repair invalid preset")
equal(type(saved.windowPositions), "table", "repair invalid window data")
equal(Suite.IsReadable({ secret = true }), false, "secret values rejected")
assert(loadfile("tests/core_spec.lua"))(Suite, equal)

local calls = 0
combat = true
Suite.AfterCombat("same", function() calls = calls + 10 end)
Suite.AfterCombat("same", function() calls = calls + 1 end)
equal(calls, 0, "defer combat changes")
combat = false
frames[1].OnEvent(frames[1], "PLAYER_REGEN_ENABLED")
equal(calls, 1, "coalesce stale combat changes")

equal(Suite.Scoring.Score({ ITEM_MOD_INTELLECT_SHORT = 8, ITEM_MOD_STAMINA_SHORT = 4 }, "caster"), 9, "caster weighting")
equal(Suite.Scoring.Score({ ITEM_MOD_INTELLECT_SHORT = 8 }, "physical"), 0, "irrelevant stats score zero")
equal(Suite.Scoring.Score(nil, "balanced"), nil, "unknown item data has no score")
equal(Suite.Scoring.Compare(6, { 9, 3 }), 3, "compare ring with weaker equipped slot")
equal(Suite.Scoring.Compare(3, { 3 }), nil, "ties are not upgrades")
equipment[1] = "old"
Suite.db.scorePreset = "caster"
equal(Suite.Items:UpgradeDelta("better"), 5, "stat improvement detected")
equal(Suite.Items:UpgradeDelta("worse"), nil, "higher item level alone is not a stat upgrade")
equal(Suite.Items:UpgradeDelta("future"), nil, "level requirement enforced")
equal(Suite.Items:UpgradeDelta("forbidden"), nil, "unusable item omitted")
equal(Suite.Items:UpgradeDelta("weapon"), 12, "caster two-handed bonuses compare against empty hands")
equipment[11], equipment[12] = "ring1", "ring2"
equal(Suite.Items:UpgradeDelta("ring"), 3, "ring slots compared correctly")
equipment[12] = "uncached"
equal(Suite.Items:UpgradeDelta("ring"), nil, "missing equipped data prevents a hint")
equal(Suite.Items:GetInfo({ secret = true }), nil, "secret item identifiers not passed to APIs")
equipment[11], equipment[12] = nil, nil
equipment[4], equipment[19] = "future", "future"
local average, count = Suite.Tooltips:EquippedLevel()
equal(average, 12, "average excludes shirt and tabard")
equal(count, 1, "equipped average reports contributing count")

local tooltip = Frame()
tooltip.shown = true
local record = {}
Suite.Tooltips.records[tooltip] = record
Suite.db.playerItemLevel = true
combat = true
Suite.Tooltips:RequestInspect(tooltip, record, "target", "guid:target")
equal(#queued, 0, "no inspect scheduled in combat")
combat = false
Suite.Tooltips:RequestInspect(tooltip, record, "target", "guid:target")
Suite.Tooltips.records[tooltip] = {}
for _, callback in ipairs(queued) do callback() end
equal(inspectRequests, 0, "hover change cancels delayed inspect")

UIParent = { GetEffectiveScale = function() return 1 end, GetWidth = function() return 1000 end, GetHeight = function() return 800 end }
local window = {
    GetCenter = function() return 300, 200 end, GetEffectiveScale = function() return 2 end,
    GetScale = function() return 2 end,
}
local position = Suite.Windows:CapturePosition(window)
equal(position.x, 0.1, "save horizontal position independently of scale")
equal(position.y, 0, "save vertical position independently of scale")
equal(position.scale, 2, "save original window scale")
window.GetWidth = function() return 300 end
window.GetHeight = function() return 200 end
window.SetScale = function() end
window.ClearAllPoints = function() end
window.SetPoint = function(self, ...) self.appliedPoint = { ... } end
window.IsShown = function() return true end
window.GetFrameStrata = function() return "MEDIUM" end
window.GetFrameLevel = function() return 5 end
window.GetRect = function() return 100, 100, 300, 200 end
local windowRecord = { name = "Sample", frame = window, handles = {} }
Suite.db.windowTools = true
Suite.db.windowPositions.Sample = { x = 0.49, y = 0.49, scale = 1 }
Suite.Windows:ApplyRecord(windowRecord)
equal(window.appliedPoint[4], 100, "clamp window horizontally to the screen")
equal(window.appliedPoint[5], 100, "clamp window vertically to the screen")
equal(windowRecord.handle:IsShown(), true, "movement is available without unlocking")
equal(windowRecord.handle.wheelEnabled, true, "header wheel resizing is available without unlocking")
equal(windowRecord.handle.strata, "MEDIUM", "controls follow the window's render layer")
combat = true
window.appliedPoint = nil
Suite.Windows:ApplyRecord(windowRecord)
equal(window.appliedPoint, nil, "never reanchor a window during combat")
Suite.pending = {}
combat = false

queued = {}
ContainerFrameCombinedBags = Frame("ContainerFrameCombinedBags")
ContainerFrameCombinedBags:SetSize(300, 200)
ContainerFrameCombinedBags:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -30, 30)
ContainerFrameCombinedBags:Show()
ContainerFrame2 = Frame("ContainerFrame2")
ContainerFrame2:SetSize(180, 200)
ContainerFrame2:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -330, 30)
Suite.Windows:Discover()
local bag = Suite.Windows.tracked.ContainerFrameCombinedBags
equal(bag.handle:IsShown(), true, "combined bag is immediately movable")
equal(Suite.Windows.tracked.ContainerFrame2, nil, "hidden bag waits for its first show")
ContainerFrame2:Show()
ContainerFrame2.OnShow(ContainerFrame2)
local callbacks = queued; queued = {}
for _, callback in ipairs(callbacks) do callback() end
equal(Suite.Windows.tracked.ContainerFrame2.handle:IsShown(), true, "individual bag is movable on first open")
bag.frame.centerX, bag.frame.centerY = 650, 450
bag.handle.OnDragStart(bag.handle, "LeftButton")
equal(bag.frame.moving, true, "bag drag starts without an edit mode")
bag.handle.OnDragStop(bag.handle)
equal(Suite.db.windowPositions[bag.name].x, 0.15, "bag drag saves its position")
equal(bag.frame:IsMovable(), false, "drag restores the prior native movable flag")
bag.handle.OnMouseUp(bag.handle, "RightButton")
equal(Suite.db.windowPositions[bag.name] ~= nil, true, "ordinary right-click keeps saved layout")
controlDown = true
bag.handle.OnMouseUp(bag.handle, "LeftButton")
equal(Suite.db.windowPositions[bag.name] ~= nil, true, "Ctrl-left-click keeps saved layout")
bag.frame:SetScale(1.3)
bag.handle.OnMouseUp(bag.handle, "RightButton")
equal(Suite.db.windowPositions[bag.name], nil, "Ctrl-right-click resets saved layout")
equal(bag.frame:GetScale(), 1, "Ctrl-right-click restores default size")
equal(bag.frame.point[1], "BOTTOMRIGHT", "Ctrl-right-click restores default anchor")
Suite.db.windowPositions[bag.name] = { x = 0.1, y = 0.1, scale = 1.2 }
bag.frame.OnMouseUp(bag.frame, "RightButton")
equal(Suite.db.windowPositions[bag.name], nil, "window background supports Ctrl-right-click reset")
Suite.db.windowPositions[bag.name] = { x = 0.15, y = 0.05, scale = 1.2 }
Suite.Windows:ApplyRecord(bag)
bag.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -30, 30)
callbacks = queued; queued = {}
for _, callback in ipairs(callbacks) do callback() end
equal(bag.frame.point[1], "CENTER", "bag manager reflow preserves saved position")
equal(bag.frame:GetScale(), 1.2, "bag manager reflow preserves saved size")
combat = true
bag.handle.OnMouseUp(bag.handle, "RightButton")
equal(Suite.db.windowPositions[bag.name] ~= nil, true, "reset waits for combat to finish")
combat = false
frames[1].OnEvent(frames[1], "PLAYER_REGEN_ENABLED")
equal(Suite.db.windowPositions[bag.name], nil, "deferred Ctrl-right-click reset applies after combat")
controlDown = false
ContainerFrameCombinedBags, ContainerFrame2 = nil, nil

-- Model the real header controls as separate frames, including an anonymous bag menu router.
local function HeaderPoint(record, x, y)
    for _, rect in ipairs(record.headerRects) do
        if x >= rect.left and x <= rect.right and y >= rect.bottom and y <= rect.top then return true end
    end
    return false
end
local function HeaderWindow(name, width, height)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetSize(width, height)
    frame.rect = { 100, 100, width, height }
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, -100)
    frame:Show()
    return frame
end
local function HeaderChild(parent, root, x, y, width, height, clickable)
    local child = CreateFrame(clickable and "Button" or "Frame", nil, parent)
    child.rect = { root.rect[1] + x, root.rect[2] + root.height + y, width, height }
    child:EnableMouse(clickable)
    child:Show()
    return child
end
local function FlushTimers()
    local callbacks = queued; queued = {}
    for _, callback in ipairs(callbacks) do callback() end
end
queued = {}
local standard = HeaderWindow("HeaderTest", 400, 200)
standard.CloseButton = HeaderChild(standard, standard, 355, -31, 30, 30, true)
local title = HeaderChild(standard, standard, 0, -32, 400, 32, false)
title:EnableMouse(true) -- Native layout frames can capture input without being controls.
title:SetFrameLevel(510) -- Matches Blizzard's portrait/title templates.
local titleControl = HeaderChild(title, standard, 130, -24, 30, 20, true)
titleControl.insets = { -4, -4, -3, -3 }
local closeClicks = 0
standard.CloseButton:SetScript("OnClick", function() closeClicks = closeClicks + 1; standard:Hide() end)
Suite.Windows:Track("HeaderTest", standard)
local nativeHeader = Suite.Windows.tracked.HeaderTest
equal(HeaderPoint(nativeHeader, 30, -15), true, "blank native title space is draggable")
equal(HeaderPoint(nativeHeader, 370, -15), false, "close button is excluded from dragging")
equal(HeaderPoint(nativeHeader, 140, -15), false, "nested header controls are excluded")
equal(HeaderPoint(nativeHeader, 125, -15), false, "expanded native hit rectangles remain clickable")
equal(HeaderPoint(nativeHeader, 30, 5), false, "no separate drag bar above the window")
equal(nativeHeader.handle.backdrop, nil, "header drag area has no visible panel decoration")
equal(nativeHeader.resize, nil, "no separate resize grip is created")
equal(nativeHeader.handle:GetParent(), standard, "header input is parented to the moved window")
equal(nativeHeader.handle:GetFrameLevel() > title:GetFrameLevel(), true, "header input is above the native title frame")
local unlaidOut = HeaderChild(standard, standard, 0, 0, 0, 0, true)
unlaidOut.GetRect = function() return nil end
local decoration = HeaderChild(standard, standard, 0, -200, 400, 200, false)
decoration:EnableMouse(true)
decoration:SetFrameLevel(500)
local forbiddenContent = HeaderChild(standard, standard, 0, -200, 400, 120, false)
forbiddenContent.IsForbidden = function() return true end
Suite.Windows:ApplyRecord(nativeHeader)
equal(HeaderPoint(nativeHeader, 30, -15), true, "unlaid-out controls and passive backgrounds do not remove the title drag area")
equal(nativeHeader.handle:GetFrameLevel() > decoration:GetFrameLevel(), true, "header input clears decorative frame layers")
-- Resolve a header event through the same layer competition as the native title frame.
local function HeaderReceiver(record, x, y)
    local receiver, level = nil, -1
    for index, rect in ipairs(record.headerRects) do
        local handle = record.handles[index]
        if handle:IsShown() and x >= rect.left and x <= rect.right and y >= rect.bottom and y <= rect.top
            and handle:GetFrameLevel() > level then receiver, level = handle, handle:GetFrameLevel() end
    end
    if title.mouseEnabled and title:GetFrameLevel() > level then receiver = title end
    return receiver
end
local receiver = HeaderReceiver(nativeHeader, 30, -15)
receiver.OnDragStart(receiver, "LeftButton")
equal(standard.moving, true, "a drag routed above the native title layer moves the actual window")
receiver.OnDragStop(receiver)
equal(standard.moving, false, "routed header drag stops cleanly")
equal(Suite.db.windowPositions.HeaderTest ~= nil, true, "routed header drag persists its layout")
nativeHeader.handle.OnMouseWheel(nativeHeader.handle, 1)
equal(standard:GetScale(), 1, "plain header scrolling does not resize")
controlDown = true
nativeHeader.handle.OnMouseWheel(nativeHeader.handle, 1)
equal(math.floor(standard:GetScale() * 100 + 0.5), 105, "Ctrl-scroll up enlarges the window")
equal(Suite.db.windowPositions.HeaderTest.scale, standard:GetScale(), "wheel scale is saved immediately")
nativeHeader.handle.OnMouseWheel(nativeHeader.handle, -1)
equal(math.floor(standard:GetScale() * 100 + 0.5), 100, "Ctrl-scroll down reduces the window")
nativeHeader.handle.OnMouseWheel(nativeHeader.handle, 100)
equal(standard:GetScale(), 1.8, "wheel resizing respects the upper scale limit")
nativeHeader.handle.OnMouseWheel(nativeHeader.handle, -100)
equal(standard:GetScale(), 0.55, "wheel resizing respects the lower scale limit")
combat = true
nativeHeader.handle.OnMouseWheel(nativeHeader.handle, 1)
equal(standard:GetScale(), 0.55, "wheel resizing never changes protected geometry during combat")
combat = false
nativeHeader.handle.OnMouseUp(nativeHeader.handle, "RightButton")
equal(standard:GetScale(), 1, "Ctrl-right-click resets wheel sizing to its original scale")
equal(Suite.db.windowPositions.HeaderTest, nil, "Ctrl-right-click clears saved wheel layout")
controlDown = false
local modal = HeaderChild(standard, standard, 0, -200, 400, 200, false)
modal.name = "HeaderTestModalBlocker"
modal:EnableMouse(true)
modal:Hide()
Suite.Windows:ApplyRecord(nativeHeader)
modal:Show()
modal.OnShow(modal)
FlushTimers()
equal(#nativeHeader.headerRects, 0, "a newly shown modal blocker disables header input")
modal:Hide()
modal.OnHide(modal)
FlushTimers()
equal(HeaderPoint(nativeHeader, 30, -15), true, "closing a modal blocker restores header input")
standard.CloseButton.OnClick(standard.CloseButton, "LeftButton")
equal(closeClicks, 1, "native close handler remains intact")
equal(standard:IsShown(), false, "native close button still hides its window")
standard:Show()
standard.OnShow(standard)
FlushTimers()
local laterControl = HeaderChild(standard, standard, 225, -24, 30, 20, true)
laterControl:Hide()
Suite.Windows:ApplyRecord(nativeHeader)
equal(HeaderPoint(nativeHeader, 240, -15), true, "hidden header control does not block dragging")
laterControl:Show()
laterControl.OnShow(laterControl)
FlushTimers()
equal(HeaderPoint(nativeHeader, 240, -15), false, "newly shown control regains its clickable space")
laterControl.rect[1] = 385 -- Root-relative x = 285.
laterControl:SetPoint("TOPLEFT", standard, "TOPLEFT", 285, -4)
FlushTimers()
equal(HeaderPoint(nativeHeader, 240, -15), true, "moving a control frees its old header space")
equal(HeaderPoint(nativeHeader, 300, -15), false, "moving a control preserves its new clickable space")
laterControl:Hide()
laterControl.OnHide(laterControl)
FlushTimers()
equal(HeaderPoint(nativeHeader, 300, -15), true, "hiding a control restores its header space")
local scaledControl = HeaderChild(standard, standard, 0, 0, 20, 8, true)
scaledControl.scale = 2
scaledControl.rect = { 140, 138, 20, 8 } -- At x = 180..220 and y = -24..-8 in the root's units.
Suite.Windows:ApplyRecord(nativeHeader)
equal(HeaderPoint(nativeHeader, 200, -15), false, "child control scales are normalized before exclusion")

local calendar = HeaderWindow("CalendarFrame", 659, 624)
HeaderChild(calendar, calendar, 224.5, -36, 32, 32, true)
HeaderChild(calendar, calendar, 396.5, -36, 32, 32, true)
calendar.FilterButton = HeaderChild(calendar, calendar, 526, -44, 106, 24, true)
HeaderChild(calendar, calendar, 628, -49, 32, 32, true)
Suite.Windows:Track("CalendarFrame", calendar)
local calendarHeader = Suite.Windows.tracked.CalendarFrame
equal(HeaderPoint(calendarHeader, 329, -12), true, "calendar month title remains draggable")
equal(HeaderPoint(calendarHeader, 100, -30), true, "calendar side header remains draggable")
equal(HeaderPoint(calendarHeader, 100, -6), false, "calendar drag area follows the raised header shape")
equal(HeaderPoint(calendarHeader, 240, -18), false, "previous month arrow is excluded")
equal(HeaderPoint(calendarHeader, 411, -25), false, "next month arrow is excluded")
equal(HeaderPoint(calendarHeader, 580, -30), false, "calendar filter menu is excluded")
equal(HeaderPoint(calendarHeader, 642, -30), false, "calendar close button is excluded")
calendar:SetScale(1.4)
FlushTimers()
equal(calendarHeader.handle:GetEffectiveScale(), calendar:GetEffectiveScale(), "header drag regions follow the window's scale")
equal(HeaderPoint(calendarHeader, 411, -25), false, "calendar controls stay excluded after resizing")
controlDown = true
calendarHeader.handle.OnMouseWheel(calendarHeader.handle, 1)
equal(math.floor(calendar:GetScale() * 100 + 0.5), 145, "calendar supports header wheel resizing")
controlDown = false
equal(HeaderPoint(calendarHeader, 580, -30), false, "calendar filter remains clear after wheel resizing")

local menuBag = HeaderWindow("MenuBagTest", 520, 500)
menuBag.PortraitButton = HeaderChild(menuBag, menuBag, -5, -47, 50, 52, true)
local menuRouter = HeaderChild(menuBag, menuBag, 35, -21, 461, 20, true)
menuRouter.routeToSibling = "PortraitButton"
local menuClicks = 0
menuRouter:SetScript("OnMouseDown", function() menuClicks = menuClicks + 1 end)
menuBag.CloseButton = HeaderChild(menuBag, menuBag, 490, -31, 30, 30, true)
Suite.Windows:Track("ContainerFrameMenuTest", menuBag)
local menuHeader = Suite.Windows.tracked.ContainerFrameMenuTest
equal(HeaderPoint(menuHeader, 260, -12), true, "bag title supports drag input across its menu router")
equal(HeaderPoint(menuHeader, 260, -30), true, "empty bag header below its menu remains draggable")
equal(HeaderPoint(menuHeader, 20, -12), false, "bag portrait settings remain clickable")
equal(HeaderPoint(menuHeader, 505, -12), false, "bag close button remains clickable")
menuRouter.OnMouseDown(menuRouter, "LeftButton")
equal(menuClicks, 1, "bag title menu keeps its original mouse handler")
cursorX, cursorY = 360, 588
menuHeader.handle.OnMouseDown(menuHeader.handle, "LeftButton")
equal(menuClicks, 1, "bag menu waits for release to distinguish a drag")
menuHeader.handle.OnMouseUp(menuHeader.handle, "LeftButton")
equal(menuClicks, 2, "ordinary bag title click invokes the native menu")
menuHeader.handle.OnMouseUp(menuHeader.handle, "LeftButton")
equal(menuClicks, 2, "a title click is consumed only once")
menuHeader.handle.OnMouseDown(menuHeader.handle, "LeftButton")
menuHeader.handle.OnDragStart(menuHeader.handle, "LeftButton")
equal(menuBag.moving, true, "native bag header starts movement")
menuHeader.handle.OnDragStop(menuHeader.handle)
menuHeader.handle.OnMouseUp(menuHeader.handle, "LeftButton")
equal(menuClicks, 2, "ending a bag drag does not open its menu")
equal(Suite.db.windowPositions.ContainerFrameMenuTest ~= nil, true, "native header drag still saves bag placement")
menuHeader.handle.OnMouseDown(menuHeader.handle, "LeftButton")
cursorX = 700
menuHeader.handle.OnMouseUp(menuHeader.handle, "LeftButton")
equal(menuClicks, 2, "releasing outside the title cancels a menu click")
cursorX = 360
menuHeader.handle.OnMouseDown(menuHeader.handle, "LeftButton")
controlDown = true
menuHeader.handle.OnMouseWheel(menuHeader.handle, 1)
equal(math.floor(menuBag:GetScale() * 100 + 0.5), 105, "bag supports header wheel resizing")
controlDown = false
menuHeader.handle.OnMouseUp(menuHeader.handle, "LeftButton")
equal(menuClicks, 2, "wheel resizing cancels a pending menu click")
equal(HeaderPoint(menuHeader, 260, -12), true, "bag title remains draggable after wheel resizing")
cursorX, cursorY = 360 * 1.05, 588 * 1.05
menuHeader.handle.OnMouseDown(menuHeader.handle, "LeftButton")
menuHeader.handle.OnMouseUp(menuHeader.handle, "LeftButton")
equal(menuClicks, 3, "resized bag title menu uses effective cursor coordinates")
controlDown = true
menuHeader.handle.OnMouseDown(menuHeader.handle, "RightButton")
menuHeader.handle.OnMouseUp(menuHeader.handle, "RightButton")
controlDown = false
equal(Suite.db.windowPositions.ContainerFrameMenuTest, nil, "Ctrl-right-click resets through the shared bag title")
equal(menuClicks, 3, "bag title reset does not open its menu")
cursorX, cursorY = 360, 588
menuHeader.handle.OnMouseDown(menuHeader.handle, "LeftButton")
menuBag.OnHide(menuBag)
menuHeader.handle.OnMouseUp(menuHeader.handle, "LeftButton")
equal(menuClicks, 3, "closing a bag cancels pending title clicks")
menuHeader.handle.OnMouseDown(menuHeader.handle, "LeftButton")
combat = true
menuHeader.handle.OnMouseUp(menuHeader.handle, "LeftButton")
combat = false
equal(menuClicks, 3, "combat cancels pending bag menu forwarding")
local restricted = HeaderChild(standard, standard, 230, -24, 30, 20, true)
restricted.rect[1] = { secret = true }
Suite.Windows:ApplyRecord(nativeHeader)
equal(#nativeHeader.headerRects, 0, "restricted control geometry leaves the native header untouched")
local anyHeaderShown = false
for _, handle in ipairs(nativeHeader.handles) do if handle:IsShown() then anyHeaderShown = true end end
equal(anyHeaderShown, false, "uncertain header controls cannot be covered by stale drag regions")
queued = {}

-- Start the addon with every feature disabled: there must be no game-window work.
Suite.db = Suite.InitializeDB(nil)
WoWForeverSuiteDB = nil
frames[1].OnEvent(frames[1], "ADDON_LOADED", "WoWForeverSuite")
equal(Suite.loadedSavedVariables, false, "identify first launch or missing saved data")
equal(WoWForeverSuiteDB.schema, 1, "initialize own database")
Suite.Apply()
equal(Suite.Items.initialized, nil, "disabled icon module installs no hooks")
equal(Suite.Tooltips.initialized, nil, "disabled tooltip module installs no hooks")
equal(Suite.Minimap.initialized, nil, "disabled minimap creates no UI")

UISpecialFrames = {}
Suite.GUI:Initialize()
equal(Suite.GUI.frame.height, 680, "configuration panel has room for six two-line helpers and its footer")
equal(#Suite.GUI.rows, 6, "overview exposes the requested feature groups")
equal(Suite.GUI.rows[3].help.text:find("Ctrl+right-click", 1, true) ~= nil, true, "Overview teaches per-window reset")
equal(Suite.GUI.rows[3].help.text:find("Ctrl+scroll", 1, true) ~= nil, true, "Overview teaches header resizing")
Suite.GUI:Select("items")
local frameCount = #frames
equal(Suite.GUI.rows[6].value.text, "Balanced", "stat preset appears in its control")
Suite.GUI:Action("preset")
equal(Suite.db.scorePreset, "physical", "preset control changes its saved preference")
Suite.GUI:Select("overview")
equal(#frames, frameCount, "navigation reuses its controls")
Suite.GUI:Toggle()
equal(Suite.GUI.frame:IsShown(), true, "open the custom control panel")
Suite.GUI:Toggle()
equal(Suite.GUI.frame:IsShown(), false, "close the custom control panel")
local closeButton = Suite.GUI.closeButton
equal(closeButton:GetParent():GetParent(), Suite.GUI.frame, "close button belongs to the drag header")
equal(closeButton:GetFrameLevel() > closeButton:GetParent():GetFrameLevel(), true, "close button receives clicks above the drag header")
equal(closeButton.mouseEnabled, true, "close button accepts mouse input")
equal(closeButton.clicks[1], "LeftButtonUp", "close button accepts a released left click")
Suite.GUI:Toggle()
closeButton.OnClick(closeButton, "LeftButton")
equal(Suite.GUI.frame:IsShown(), false, "clicking X hides the control panel")
Suite.GUI:Toggle()
equal(Suite.GUI.frame:IsShown(), true, "panel can reopen after clicking X")
closeButton.OnClick(closeButton, "LeftButton")

local settingsDB, selectedPage = Suite.db, Suite.GUI.page
Suite.db = nil
Suite.GUI:OpenPage("chat")
equal(Suite.GUI.frame:IsShown(), false, "opening a page before settings load leaves the panel closed")
Suite.db = settingsDB
Suite.GUI:OpenPage("missing")
equal(Suite.GUI.page, selectedPage, "unknown settings page preserves the selected page")
equal(Suite.GUI.frame:IsShown(), false, "unknown settings page cannot open an empty panel")
local openPage, openMeters = Suite.GUI.OpenPage, Suite.GUI.OpenMeters
local openedPage
Suite.GUI.OpenPage = function(_, key) openedPage = key end
Suite.GUI.OpenMeters = function() openedPage = "meters" end
for command, page in pairs({ bags = "bags", macros = "macros", camping = "camping", campfire = "camping",
    actionbars = "actionbars", unitframes = "unitframes", vendor = "vendor", quests = "quests",
    gossip = "quests", loot = "quests", mail = "mail", chat = "chat", meters = "meters", damage = "meters" }) do
    openedPage = nil
    SlashCmdList.WOWFOREVERSUITE("  " .. command:upper() .. "  ")
    equal(openedPage, page, "settings command routes " .. command .. " to its page")
end
Suite.GUI.OpenPage, Suite.GUI.OpenMeters = openPage, openMeters
Suite.GUI:OpenPage("windows")
equal(Suite.GUI.page, "windows", "shared page opener selects the requested settings")
equal(Suite.GUI.frame:IsShown(), true, "shared page opener displays the settings panel")
Suite.GUI:OpenPage("overview")
closeButton.OnClick(closeButton, "LeftButton")

local tooltipCallbacks = {}
local tooltipPreCallbacks = {}
Enum = { TooltipDataType = { Item = 0, Unit = 2 }, TooltipDataLineType = { None = 0, ItemName = 22, ItemLevel = 31 } }
NORMAL_FONT_COLOR = { r = 1, g = 0.82, b = 0 }
TooltipDataProcessor = {
    AddTooltipPostCall = function(kind, callback) tooltipCallbacks[kind] = callback end,
    AddTooltipPreCall = function(kind, callback) tooltipPreCallbacks[kind] = callback end,
}
Suite.db.itemTooltipLevels = true
Suite.Tooltips:Initialize()
local shopping = Frame("ShoppingTooltip1") -- Deliberately no GetItem method, matching the client.
tooltipCallbacks[0](shopping, { hyperlink = "better" })
equal(shopping.lines[1][1], "Item Level 20", "comparison tooltip reads the callback's hyperlink")
tooltipCallbacks[0](shopping, { hyperlink = "better" })
equal(#shopping.lines, 1, "repeated item callbacks add one annotation")
shopping.OnTooltipCleared(shopping)
shopping.lines = {}
tooltipCallbacks[0](shopping, { hyperlink = "old" })
equal(shopping.lines[1][1], "Item Level 12", "tooltip clearing allows a new item annotation")
C_Item.GetItemLinkByGUID = function(guid) if guid == "item:instance" then return "better" end end
local byGUID = Frame()
tooltipCallbacks[0](byGUID, { guid = "item:instance", hyperlink = "old" })
equal(byGUID.lines[1][1], "Item Level 20", "item instance GUID takes precedence over a generic link")
items[123] = items.better
local byID = Frame()
tooltipCallbacks[0](byID, { id = 123 })
equal(byID.lines[1][1], "Item Level 20", "comparison tooltip can fall back to a readable item ID")
local unavailable = Frame()
tooltipCallbacks[0](unavailable, {})
tooltipCallbacks[0](unavailable, { hyperlink = { secret = true }, id = { secret = true } })
tooltipCallbacks[0](unavailable, { secret = true })
equal(#unavailable.lines, 0, "missing or secret tooltip item data is ignored safely")
tooltipCallbacks[0](unavailable, { hyperlink = "uncached" })
equal(Suite.Tooltips.records[unavailable].itemDone, nil, "uncached item remains eligible for a later refresh")
local ordinary = Frame()
ordinary.GetItem = function() return "item", "old" end
tooltipCallbacks[0](ordinary, {})
equal(ordinary.lines[1][1], "Item Level 12", "ordinary tooltip item method remains a supported fallback")
local retailTooltip = Frame()
local retailData = { hyperlink = "better", lines = {
    { type = 22, leftText = "Better Helm" },
    { type = 0, leftText = "Binds when picked up" },
    { type = 0, leftText = "Armor", rightText = "Head" },
} }
tooltipPreCallbacks[0](retailTooltip, retailData)
equal(retailData.lines[1].leftText, "Better Helm", "item name remains the first tooltip line")
equal(retailData.lines[2].leftText, "Item Level 20", "gold item level is inserted directly below the name")
equal(retailData.lines[2].leftColor, NORMAL_FONT_COLOR, "item level uses native gold tooltip color")
equal(retailData.lines[2].rightText, nil, "item level is a single left-aligned line")
equal(retailData.lines[3].leftText, "Binds when picked up", "native binding line retains its order")
equal(retailData.lines[4].rightText, "Head", "native right-column equipment text is preserved")
tooltipPreCallbacks[0](retailTooltip, retailData)
equal(#retailData.lines, 4, "reprocessing does not duplicate the inserted item-level line")
tooltipCallbacks[0](retailTooltip, retailData)
equal(#retailTooltip.lines, 0, "post-call does not add a second item-level footer")
local nativeLevelData = { hyperlink = "weapon", lines = {
    { type = 22, leftText = "A Weapon" }, { type = 0, leftText = "Two-Hand" },
    { type = 31, leftText = "Item Level 1" },
} }
tooltipPreCallbacks[0](Frame(), nativeLevelData)
equal(#nativeLevelData.lines, 3, "existing native item level is replaced without duplication")
equal(nativeLevelData.lines[2].leftText, "Item Level 25", "existing item level moves below the weapon name")
local restrictedLines = { hyperlink = "better", lines = { { type = { secret = true } } } }
tooltipPreCallbacks[0](Frame(), restrictedLines)
equal(#restrictedLines.lines, 1, "restricted tooltip line classification is left untouched")
for _, equip in ipairs({ "", "INVTYPE_NON_EQUIP", "INVTYPE_BAG", "INVTYPE_QUIVER" }) do
    items.misc = { level = 30, equip = equip, stats = {} }
    local miscTooltip = Frame()
    tooltipCallbacks[0](miscTooltip, { hyperlink = "misc" })
    equal(#miscTooltip.lines, 0, "tooltip excludes non-gear slot " .. equip)
end
for _, equip in ipairs({ "INVTYPE_FINGER", "INVTYPE_TRINKET", "INVTYPE_CLOAK", "INVTYPE_HEAD", "INVTYPE_WEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONOFFHAND", "INVTYPE_2HWEAPON", "INVTYPE_RANGED", "INVTYPE_RANGEDRIGHT", "INVTYPE_THROWN", "INVTYPE_SHIELD", "INVTYPE_HOLDABLE", "INVTYPE_RELIC" }) do
    items.gear = { level = 30, equip = equip, stats = {} }
    local gearTooltip = Frame()
    tooltipCallbacks[0](gearTooltip, { hyperlink = "gear" })
    equal(gearTooltip.lines[1][1], "Item Level 30", "tooltip includes equipment slot " .. equip)
end
items.misc.equip = { secret = true }
local secretEquip = Frame()
tooltipCallbacks[0](secretEquip, { hyperlink = "misc" })
equal(#secretEquip.lines, 0, "restricted equipment classification is skipped safely")

-- Icon hooks also run for profession results/reagents and recycled item buttons.
do
    Suite.db.itemLevels = true
    ITEM_QUALITY_COLORS = { [2] = { r = 0.1, g = 1, b = 0 } }
    items.cookedFish = { level = 10, equip = "", stats = {} }
    items.rawFish = { level = 5, equip = "", stats = {} }
    SetItemButtonQuality = function() end
    ItemButtonMixin = { SetItemButtonQuality = function() end }
    Suite.Items:Initialize()
    local result, reagent = Frame(), Frame()
    SetItemButtonQuality(result, 2, "cookedFish")
    ItemButtonMixin.SetItemButtonQuality(reagent, 2, "rawFish")
    equal(Suite.Items.buttons[result].level.text, "", "cooking result has no icon item level")
    equal(Suite.Items.buttons[reagent].level.text, "", "cooking reagent has no icon item level")

    local currentItem = "better"
    local linked = Frame()
    linked.GetItemLink = function() return currentItem end
    Suite.Items:Track(linked)
    equal(Suite.Items.buttons[linked].level.text, 20, "window buttons resolve their current equipment link")
    currentItem = "cookedFish"
    Suite.Items:Update(linked, Suite.Items.buttons[linked])
    equal(Suite.Items.buttons[linked].level.text, "", "current non-gear link clears a window button level")
    local originalContainer = C_Container
    C_Container = { GetContainerItemLink = function() return currentItem end }
    local bagSlot = Frame()
    bagSlot.GetBagID, bagSlot.GetID = function() return 0 end, function() return 1 end
    currentItem = "better"
    Suite.Items:Track(bagSlot)
    equal(Suite.Items.buttons[bagSlot].level.text, 20, "bag slots resolve equipment from their current location")
    currentItem = "rawFish"
    Suite.Items:Update(bagSlot, Suite.Items.buttons[bagSlot])
    equal(Suite.Items.buttons[bagSlot].level.text, "", "bag slots exclude reagents after changing items")
    C_Container = originalContainer

    local recycled = Frame()
    recycled.SetItemButtonQuality = function() end -- A mixin copied before hooks were installed.
    SetItemButtonQuality(recycled, 2, "better")
    local record = Suite.Items.buttons[recycled]
    equal(record.level.text, 20, "equippable gear retains its icon level")
    recycled:SetItemButtonQuality(2, "rawFish")
    equal(record.level.text, "", "reusing a gear button for a reagent clears its old level")
    for _, equip in ipairs({ "", "INVTYPE_NON_EQUIP", "INVTYPE_BAG", "INVTYPE_QUIVER", "INVTYPE_AMMO" }) do
        items.iconMisc = { level = 30, equip = equip, stats = {} }
        recycled:SetItemButtonQuality(2, "iconMisc")
        equal(record.level.text, "", "icon excludes non-gear slot " .. equip)
    end
    for _, equip in ipairs({ "INVTYPE_HEAD", "INVTYPE_NECK", "INVTYPE_SHOULDER", "INVTYPE_BODY", "INVTYPE_CHEST",
        "INVTYPE_ROBE", "INVTYPE_WAIST", "INVTYPE_LEGS", "INVTYPE_FEET", "INVTYPE_WRIST", "INVTYPE_HAND",
        "INVTYPE_FINGER", "INVTYPE_TRINKET", "INVTYPE_CLOAK", "INVTYPE_TABARD", "INVTYPE_WEAPON",
        "INVTYPE_2HWEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONOFFHAND", "INVTYPE_SHIELD",
        "INVTYPE_HOLDABLE", "INVTYPE_RANGED", "INVTYPE_RANGEDRIGHT", "INVTYPE_THROWN", "INVTYPE_RELIC" }) do
        items.iconGear = { level = 30, equip = equip, required = 40, usable = false, stats = {} }
        recycled:SetItemButtonQuality(2, "iconGear")
        equal(record.level.text, 30, "icon includes equipment even when unusable: " .. equip)
    end
    items.iconGear.equip = { secret = true }
    recycled:SetItemButtonQuality(2, "iconGear")
    equal(record.level.text, "", "restricted equipment classification clears icon levels")
    items.iconGear.equip = nil
    recycled:SetItemButtonQuality(2, "iconGear")
    equal(record.level.text, "", "missing equipment classification clears icon levels")
    items.iconGear.equip, items.iconGear.level = "INVTYPE_HEAD", { secret = true }
    recycled:SetItemButtonQuality(2, "iconGear")
    equal(record.level.text, "", "restricted item levels are not displayed")

    recycled:SetItemButtonQuality(2, "better")
    recycled:SetItemButtonQuality(2, { secret = true })
    equal(record.level.text, "", "restricted supplied identifiers clear a recycled level")
    recycled:SetItemButtonQuality(2, "better")
    recycled:SetItemButtonQuality(2, nil)
    equal(record.level.text, "", "empty recycled button clears its item level")

    local originalInfo = C_Item.GetItemInfo
    C_Item.GetItemInfo = function(item)
        if item == "secretQuality" then return item, "better", { secret = true }, 20, 1, "Armor", "Cloth", 1, "INVTYPE_HEAD" end
        return originalInfo(item)
    end
    recycled:SetItemButtonQuality(2, "secretQuality")
    equal(record.level.text, 20, "readable gear level does not require indexing a restricted quality")
    C_Item.GetItemInfo = originalInfo
    Suite.db.upgradeHints, Suite.db.itemLevels, Suite.db.scorePreset = true, false, "caster"
    equipment[1] = "old"
    recycled:SetItemButtonQuality(2, "better")
    equal(record.level.text, "", "icon levels remain independently optional")
    equal(record.arrow.text, "+", "equipment stat hints still work with icon levels disabled")
    recycled:SetItemButtonQuality(2, "cookedFish")
    equal(record.arrow.text, "", "recycled non-equipment clears the stat hint")
    Suite.db.upgradeHints, Suite.db.itemLevels = false, true

    local originalInstant, originalRequest, originalQueue = C_Item.GetItemInfoInstant, C_Item.RequestLoadItemDataByID, queued
    queued = {}
    local loads = {}
    C_Item.GetItemInfoInstant = function(item) return item == "lateGear" and 1001 or 1002 end
    C_Item.RequestLoadItemDataByID = function(id) loads[id] = (loads[id] or 0) + 1 end
    recycled:Show()
    recycled:SetItemButtonQuality(2, "lateGear")
    recycled:SetItemButtonQuality(2, "lateGear")
    equal(record.level.text, "", "uncached gear does not retain an old level")
    equal(loads[1001], 1, "missing gear data is requested once")
    items.lateGear = { level = 22, equip = "INVTYPE_HEAD", stats = {} }
    Suite.Items.events.OnEvent(Suite.Items.events, "GET_ITEM_INFO_RECEIVED", 1001)
    local refreshes = queued; queued = {}
    for _, callback in ipairs(refreshes) do callback() end
    equal(record.level.text, 22, "gear level appears after its data arrives")
    recycled:SetItemButtonQuality(2, "lateFood")
    equal(record.level.text, "", "uncached food clears a recycled gear level")
    items.lateFood = { level = 10, equip = "", stats = {} }
    Suite.Items.events.OnEvent(Suite.Items.events, "GET_ITEM_INFO_RECEIVED", 1002)
    refreshes = queued; queued = {}
    for _, callback in ipairs(refreshes) do callback() end
    equal(record.level.text, "", "food stays unlabeled after its data arrives")
    recycled:SetItemButtonQuality(2, "better")
    recycled.OnHide(recycled)
    equal(record.level.text, "", "hiding a pooled button clears its level")
    recycled.OnShow(recycled)
    equal(record.level.text, 20, "showing a gear button recalculates its level")
    Suite.db.itemLevels = false
    Suite.Items:Apply()
    equal(record.level.text, "", "disabling icon levels clears visible labels")
    recycled:Hide()
    C_Item.GetItemInfoInstant, C_Item.RequestLoadItemDataByID, queued = originalInstant, originalRequest, originalQueue
end

-- Match native bags: GetItemLink exists but UpdateItems only supplies the link
-- to SetItemButtonQuality, without storing it on the button.
do
    local oldContainer, oldLocation, oldEnumerate = C_Container, ItemLocation, EnumerateFrames
    local oldCombined, oldContainers, oldBank = ContainerFrameCombinedBags, ContainerFrameContainer, BankFrame
    local oldLink, oldExists, oldCurrent, oldInfo = C_Item.GetItemLink, C_Item.DoesItemExist, C_Item.GetCurrentItemLevel, C_Item.GetItemInfo
    local oldQueue, oldPending = queued, Suite.pending
    queued, Suite.pending = {}, {}
    Suite.db.itemLevels, Suite.db.upgradeHints = true, false
    local link, currentLevel, bagReads = "better", 24, 0
    ItemLocation = { CreateFromBagAndSlot = function(_, bag, slot) return { bagID = bag, slotIndex = slot } end }
    C_Container = { GetContainerItemLink = function(bag, slot)
        assert(type(bag) == "number" and type(slot) == "number", "slot API must receive readable numbers")
        bagReads = bagReads + 1
        return link
    end }
    C_Item.GetCurrentItemLevel = function(location)
        assert(location.bagID == 0 or location.bagID == 6 or location.equipmentSlotIndex == 16, "current level uses the actual slot")
        return currentLevel
    end
    C_Item.GetItemInfo = function(item)
        if item == "blueGear" then return item, "better", 3, 20, 1, "Armor", "Cloth", 1, "INVTYPE_HEAD" end
        if item == "unknownQuality" then return item, "better", nil, 20, 1, "Armor", "Cloth", 1, "INVTYPE_HEAD" end
        return oldInfo(item)
    end
    ITEM_QUALITY_COLORS[3] = { r = 0, g = 0.44, b = 0.87 }
    local bagButton = Frame()
    bagButton.GetItemLink = function() return nil end
    bagButton.GetBagID, bagButton.GetID = function() return 0 end, function() return 1 end
    bagButton.SetItemButtonQuality = function() end -- Copied before Suite hooks.
    bagButton:Show()
    ContainerFrameCombinedBags = Frame()
    ContainerFrameCombinedBags.EnumerateValidItems = function() return ipairs({ bagButton }) end
    ContainerFrameCombinedBags.UpdateItems = function() end
    ContainerFrameContainer, BankFrame = nil, nil
    EnumerateFrames = function() end
    Suite.Items:Apply() -- Hooks hidden containers so opening them can discover buttons.
    equal(Suite.Items.buttons[bagButton], nil, "hidden bag contents wait for opening")
    ContainerFrameCombinedBags:Show()
    ContainerFrameCombinedBags.OnShow(ContainerFrameCombinedBags)
    local record = Suite.Items.buttons[bagButton]
    equal(record.level.text, 24, "native inherited nil GetItemLink does not hide a bag level")
    equal(record.level.point[1], "TOPRIGHT", "level is anchored in the top-right corner")
    equal(record.level.point[2], bagButton, "level anchor belongs to the item button")
    equal(record.level.point[4], -2, "level stays inside the right icon edge")
    equal(record.level.justifyH, "RIGHT", "level text aligns to the right edge")
    equal(record.level.drawSublevel, 7, "level draws above native overlay artwork")
    equal(record.level.textColor[2], 1, "uncommon gear retains its quality color")
    bagButton.GetItemLink = function() return "old" end
    currentLevel = 28
    ContainerFrameCombinedBags:UpdateItems()
    equal(record.level.text, 28, "slot data takes priority over an inherited stale link")
    link = "rawFish"
    ContainerFrameCombinedBags:UpdateItems()
    equal(record.level.text, "", "native bag refresh removes numbers on non-equipment")
    link = nil
    bagButton:SetItemButtonQuality(2, "better")
    equal(record.level.text, "", "an empty bag slot cannot reuse a supplied old item")
    link, currentLevel = "better", nil
    ContainerFrameCombinedBags:UpdateItems()
    equal(record.level.text, 20, "missing current level falls back to the readable link level")
    currentLevel = { secret = true }
    ContainerFrameCombinedBags:UpdateItems()
    equal(record.level.text, "", "restricted current levels do not use a fallback to reveal a number")
    currentLevel = 24
    local beforeReads = bagReads
    bagButton.GetBagID = function() return { secret = true } end
    ContainerFrameCombinedBags:UpdateItems()
    equal(record.level.text, "", "restricted bag identity clears the label")
    equal(bagReads, beforeReads, "restricted bag identity is not passed to the container API")
    bagButton.GetBagID = function() return 0 end
    link = "blueGear"
    ContainerFrameCombinedBags:UpdateItems()
    equal(record.level.textColor[3], 0.87, "rarity changes refresh the number's color")
    link = "unknownQuality"
    ContainerFrameCombinedBags:UpdateItems()
    equal(record.level.textColor[1], 1, "missing quality restores a neutral color")
    equal(record.level.textColor[3], 1, "missing quality cannot retain the previous blue color")

    local oldInstant, oldRequest = C_Item.GetItemInfoInstant, C_Item.RequestLoadItemDataByID
    local loads, loaded, slotID = 0, false, 1004
    C_Container.GetContainerItemInfo = function() if slotID then return { itemID = slotID } end end
    C_Item.GetItemInfoInstant = function(item) if item == 1004 then return item end; return oldInstant(item) end
    C_Item.RequestLoadItemDataByID = function(id) if id == 1004 then loads = loads + 1 end end
    C_Item.GetItemInfo = function(item)
        if item == 1004 then
            if loaded then return "Loaded gear", "better", 2, 20, 1, "Armor", "Cloth", 1, "INVTYPE_HEAD" end
            return nil
        end
        return oldInfo(item)
    end
    link = nil
    ContainerFrameCombinedBags:UpdateItems()
    ContainerFrameCombinedBags:UpdateItems()
    equal(record.level.text, "", "uncached slot without a hyperlink clears the previous label")
    equal(loads, 1, "current slot ID requests uncached data once even without a hyperlink")
    loaded = true
    Suite.Items.events.OnEvent(Suite.Items.events, "GET_ITEM_INFO_RECEIVED", 1004)
    local loadedCallbacks = queued; queued = {}
    for _, callback in ipairs(loadedCallbacks) do callback() end
    equal(record.level.text, 24, "current slot ID displays its level when asynchronous data arrives")
    slotID = { secret = true }
    ContainerFrameCombinedBags:UpdateItems()
    equal(record.level.text, "", "restricted fallback slot IDs cannot display an old item")
    slotID = nil
    ContainerFrameCombinedBags:UpdateItems()
    equal(record.level.text, "", "confirmed empty metadata does not reuse a supplied item")
    C_Item.GetItemInfoInstant, C_Item.RequestLoadItemDataByID, C_Item.GetItemInfo = oldInstant, oldRequest, oldInfo
    C_Container.GetContainerItemInfo = nil

    local bankButton = Frame()
    bankButton.GetBankTabID, bankButton.GetContainerSlotID = function() return 6 end, function() return 2 end
    bankButton.GetItemLink, bankButton.SetItemButtonQuality = function() return nil end, function() end
    bankButton:Show()
    BankFrame = { BankPanel = Frame() }
    BankFrame.BankPanel:Show()
    BankFrame.BankPanel.EnumerateValidItems = function() return pairs({ [bankButton] = true }) end
    BankFrame.BankPanel.RefreshAllItemsForSelectedTab = function() end
    link = "better"
    Suite.Items:ScanContainers()
    equal(Suite.Items.buttons[bankButton].level.text, 24, "native bank pool and tab/slot getters are supported")
    link = nil
    BankFrame.BankPanel:RefreshAllItemsForSelectedTab()
    equal(Suite.Items.buttons[bankButton].level.text, "", "bank tab refresh clears emptied slots")

    link, currentLevel = "better", { secret = true }
    Suite.db.itemLevels, Suite.db.upgradeHints, Suite.db.scorePreset = false, true, "caster"
    equipment[1] = "old"
    ContainerFrameCombinedBags:UpdateItems()
    equal(record.arrow.text, "+", "stat hints do not read current item levels when icon levels are off")
    Suite.db.itemLevels, Suite.db.upgradeHints = true, false

    local equipped = Frame()
    equipped.GetBagID, equipped.GetID = function() return nil end, function() return 16 end
    equipped.GetItemLink = function() return nil end
    local location = { equipmentSlotIndex = 16 }
    equipped.GetItemLocation = function() return location end
    equipped.SetItemButtonQuality = function() end
    equipped:Show()
    C_Item.DoesItemExist = function() return link ~= nil end
    C_Item.GetItemLink = function() return link end
    link, currentLevel = "weapon", 31
    EnumerateFrames = function(previous) if not previous then return equipped end end
    Suite.Items:ScanVisible()
    equal(Suite.Items.buttons[equipped].level.text, 31, "equipment slots resolve their actual item instance")
    link = nil
    Suite.Items:Refresh()
    equal(Suite.Items.buttons[equipped].level.text, "", "unequipping clears the instance level")
    location = { equipmentSlotIndex = { secret = true } }
    C_Item.DoesItemExist = function() error("restricted locations must not be probed") end
    Suite.Items:Refresh()
    equal(Suite.Items.buttons[equipped].level.text, "", "restricted location fields are skipped")

    local generic = Frame()
    local genericLink = "better"
    generic.GetItemLink = function() return genericLink end
    generic.SetItemButtonQuality = function() end
    generic.Reset = function(self) self:SetItemButtonQuality(); genericLink = nil end
    Suite.Items:Track(generic, "better", true)
    generic:Reset()
    equal(Suite.Items.buttons[generic].level.text, "", "native reset clears a link after the quality hook fires")
    genericLink = nil
    generic:SetItemButtonQuality(2, "better")
    equal(Suite.Items.buttons[generic].level.text, 20, "nil generic getter falls back to the supplied current item")

    -- The first queued event must not swallow a later ADDON_LOADED discovery.
    local discovered = Frame()
    discovered.GetItemLink, discovered.SetItemButtonQuality = function() return "better" end, function() end
    discovered:Show()
    EnumerateFrames = function(previous) if not previous then return discovered end end
    Suite.Items.events.OnEvent(Suite.Items.events, "BAG_UPDATE_DELAYED")
    Suite.Items.events.OnEvent(Suite.Items.events, "ADDON_LOADED")
    equal(#queued, 1, "event bursts share one refresh timer")
    local callbacks = queued; queued = {}
    for _, callback in ipairs(callbacks) do callback() end
    equal(Suite.Items.buttons[discovered].level.text, 20, "coalesced addon load still discovers newly loaded buttons")

    local combatButton = Frame()
    combatButton.GetBagID, combatButton.GetID = function() return 0 end, function() return 3 end
    combatButton.GetItemLink = function() return nil end
    link, combat = "better", true
    Suite.Items:Track(combatButton)
    equal(Suite.Items.buttons[combatButton].level, nil, "new icon regions wait until combat ends")
    equal(type(Suite.pending[combatButton]), "function", "combat queues the current button")
    Suite.Items.events.OnEvent(Suite.Items.events, "BAG_UPDATE_DELAYED")
    local pendingTimer = Suite.Items.refreshTimer
    Suite.db.itemLevels = false
    Suite.Items:Apply()
    equal(pendingTimer.cancelled, true, "disabling cancels the queued icon refresh")
    equal(Suite.pending[combatButton], nil, "disabling cancels deferred region creation")
    equal(record.level.text, "", "disabling clears visible bag labels")
    combat = false
    combatButton.OnShow(combatButton)
    equal(Suite.Items.buttons[combatButton].level, nil, "disabled show hooks cannot create deferred regions")
    link = "rawFish"
    ContainerFrameCombinedBags:UpdateItems()
    equal(record.level.text, "", "installed container hooks remain inert while disabled")
    C_Container, ItemLocation, EnumerateFrames = oldContainer, oldLocation, oldEnumerate
    ContainerFrameCombinedBags, ContainerFrameContainer, BankFrame = oldCombined, oldContainers, oldBank
    C_Item.GetItemLink, C_Item.DoesItemExist, C_Item.GetCurrentItemLevel, C_Item.GetItemInfo = oldLink, oldExists, oldCurrent, oldInfo
    queued, Suite.pending = oldQueue, oldPending
    bagButton:Hide(); bankButton:Hide(); equipped:Hide(); discovered:Hide()
end

Suite.db.playerItemLevel = true
local noUnit = Frame()
tooltipCallbacks[2](noUnit, {})
equal(Suite.Tooltips.records[noUnit], nil, "unit callbacks without GetUnit or readable GUID are harmless")

-- Native minimap ownership, coordinate clearance, restoration and ticker lifetime.
MinimapCluster = CreateFrame("Frame", "MinimapCluster")
MinimapCluster:SetScale(1.25)
MinimapCluster:Show()
MinimapCluster:SetClampedToScreen(true)
Minimap = CreateFrame("Frame", "Minimap", MinimapCluster)
Minimap:SetSize(240, 240)
Minimap:Show()
Minimap.SetMaskTexture = function(self, texture) self.mask = texture end
Minimap.questRingScalar = 1
Minimap.SetQuestBlobRingScalar = function(self, scalar)
    assert(not InCombatLockdown(), "quest ring changes must defer through combat")
    self.questRingScalar = scalar
end
MinimapCluster.MinimapContainer = {}
local coords = CreateFrame("Frame", nil, MinimapCluster)
coords:SetSize(90, 10)
coords:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, -18)
coords.showPlayerCoords = true
coords:Show()
MinimapCluster.MinimapContainer.PlayerCoords = coords
local originalCoordsPoint = coords.point
local function NativeWidget(name, width, height)
    local widget = CreateFrame("Button", name, MinimapCluster)
    widget:SetSize(width, height)
    widget:SetPoint("TOPRIGHT", MinimapCluster, "TOPRIGHT", -4, -4)
    widget:Show()
    return widget
end
MinimapCluster.BorderTop = NativeWidget(nil, 175, 16)
MinimapCluster.Tracking = NativeWidget(nil, 17, 17)
MinimapCluster.ZoneTextButton = NativeWidget(nil, 135, 12)
MinimapZoneText = NativeWidget(nil, 130, 12)
TimeManagerClockButton = NativeWidget("TimeManagerClockButton", 40, 16)
TimeManagerClockTicker = NativeWidget("TimeManagerClockTicker", 40, 14)
TimeManagerClockTicker:SetFont("Fonts\\ARIALN.TTF", 11, "")
TimeManagerClockTicker.GetFont = function(self) return self.fontPath, self.fontSize, self.fontFlags end
GameTimeFrame = NativeWidget("GameTimeFrame", 18, 18)
MinimapCluster.InstanceDifficulty = NativeWidget(nil, 20, 20)
MinimapCluster.IndicatorFrame = NativeWidget(nil, 20, 15)
local zoneClicks = 0
MinimapCluster.ZoneTextButton:SetScript("OnClick", function() zoneClicks = zoneClicks + 1 end)
local originalZonePoint = MinimapCluster.ZoneTextButton.point
local originalClockPoint = TimeManagerClockButton.point
local tickerStarts, tickerCancels = 0, 0
C_Timer.NewTicker = function(_, callback)
    tickerStarts = tickerStarts + 1
    return { callback = callback, Cancel = function() tickerCancels = tickerCancels + 1 end }
end
function GetFramerate() return 182.9 end
function GetNetStats() return 0, 0, 42, 19 end
function date() return "17:39" end
local areaName, subzoneName = "Loch Modan", "Stoutlager Inn"
function GetRealZoneText() return areaName end
function GetZoneText() return areaName end
function GetSubZoneText() return subzoneName end
function GetMinimapZoneText() return "Thelsamar" end
C_Map = {
    GetBestMapForUnit = function() return 1 end,
    GetPlayerMapPosition = function() return { GetXY = function() return 0.355, 0.486 end } end,
}
Suite.db.squareMinimap, Suite.db.minimapStats = true, true
Suite.Minimap:Apply()
local map = Suite.Minimap
equal(MinimapCluster:IsClampedToScreen(), false, "square minimap can move beyond Edit Mode screen bounds")
MinimapCluster:SetClampedToScreen(true)
equal(MinimapCluster:IsClampedToScreen(), false, "native reclamping is released while square mode is enabled")
equal(map.header.height, 36, "custom minimap header fits two compact label lines")
equal(map.header.area.text, "Loch Modan", "header labels the full area")
equal(map.header.subzone.text, "Stoutlager Inn", "header labels the subzone separately")
equal(map.header.area.fontSize, 12, "area uses the larger label")
equal(map.header.subzone.fontSize, 10, "subzone uses a smaller font")
equal(map.header.area.justifyH, "CENTER", "area text is centered")
equal(map.header.subzone.justifyH, "CENTER", "subzone text is centered")
equal(map.header.area.point[2], 0, "area is centered on the whole header")
equal(map.header.subzone.point[2], 0, "subzone is centered on the whole header")
equal(MinimapZoneText:IsShown(), false, "old native one-line location text is hidden")
equal(MinimapCluster.Tracking.height, 20, "tracking fits the header thickness")
equal(GameTimeFrame.height, 20, "calendar fits the header thickness")
equal(TimeManagerClockButton.height, 24, "clock has a comfortable bottom inset size")
equal(TimeManagerClockButton.point[1], "BOTTOM", "clock moves to bottom center")
equal(TimeManagerClockButton.point[2], Minimap, "clock anchors directly inside the map")
equal(TimeManagerClockButton.point[5], 8, "clock stays above the map's bottom edge")
equal(TimeManagerClockTicker.fontSize, 14, "native clock font is enlarged")
equal(map.header.area.width, 180, "moving the clock gives labels more room")
equal(map.header.backdropAlpha, 0.65, "header background is translucent")
equal(map.header.borderColor[2], map.border.borderColor[2], "header border matches the minimap accent")
equal(map.header.backdrop.edgeSize, 1, "header has a thin complete border")
areaName, subzoneName = "A Very Long Area Name That Needs More Room", "A Very Long Subzone Name That Needs More Room"
map.events.OnEvent(map.events, "ZONE_CHANGED_NEW_AREA")
equal(map.header.area.text, areaName, "long area names are retained in full")
equal(map.header.subzone.text, subzoneName, "long subzone names are retained in full")
equal(map.header.area.fontSize, 10, "long area labels fit down to a readable minimum")
equal(map.header.area.wordWrap, true, "extra-long names wrap instead of shortening")
equal(map.header.height > 36, true, "header grows to accommodate full wrapped labels")
areaName, subzoneName = "Loch Modan", "Stoutlager Inn"
map.events.OnEvent(map.events, "ZONE_CHANGED_NEW_AREA")
equal(map.header.height, 36, "normal names return to the compact header height")
equal(map.header.area.fontSize, 12, "normal area labels restore their preferred font size")
subzoneName = "Thelsamar"
map.events.OnEvent(map.events, "ZONE_CHANGED_INDOORS")
equal(map.header.subzone.text, "Thelsamar", "zone events refresh both labels")
subzoneName = { secret = true }
map.events.OnEvent(map.events, "ZONE_CHANGED")
equal(map.header.subzone.text, "Thelsamar", "restricted subzone text uses a readable native fallback")
equal(map.header.point[2], map.border, "header follows the map's outer border width")
equal(map.header.point[5], 2, "header has a two-pixel gap")
equal(map.panel.height, 20, "stats use one compact row")
equal(map.panel.point[2], coords, "stats anchor below the native coordinate band")
equal(map.panel.point[5], -6, "stats leave six pixels below native coordinates")
equal(coords.point, originalCoordsPoint, "Blizzard coordinate anchors remain unchanged")
equal(map.panel.text.text:find("35.5", 1, true), nil, "native coordinates are not duplicated")
equal(map.panel.text.text:find("17:39", 1, true), nil, "native clock is not duplicated")
equal(map.panel.text.text:find("\n", 1, true), nil, "stats are a single line")
equal(map.panel.text.wordWrap, false, "stats cannot wrap into the coordinate band")
equal(map.panel.width, 240, "stats align to map width")
equal(MinimapCluster.BorderTop:IsShown(), false, "native header art is hidden")
equal(MinimapCluster.ZoneTextButton:GetParent(), MinimapCluster, "zone button retains native ownership")
MinimapCluster.ZoneTextButton.OnClick()
equal(zoneClicks, 1, "native zone button keeps its click behavior")
equal(MinimapCluster.ZoneTextButton:GetFrameLevel() > map.header:GetFrameLevel(), true, "native controls stay above custom header")
equal(tickerStarts, 1, "one ticker updates the stats")
map:Apply()
equal(tickerStarts, 1, "reapplying does not duplicate tickers")
coords.showPlayerCoords = false
TimeManagerClockButton:Hide()
map:UpdateStats()
equal(map.panel.text.text:find("35.5, 48.6", 1, true) ~= nil, true, "fallback coordinates display when native coordinates are off")
equal(map.panel.text.text:find("17:39", 1, true) ~= nil, true, "fallback clock displays when native clock is hidden")
coords.showPlayerCoords = true
TimeManagerClockButton:Show()
map:UpdateStats()
equal(map.panel.text.text:find("35.5", 1, true), nil, "restoring native coordinates removes duplicates")
Suite.db.showFPS, Suite.db.showLatency, Suite.db.showCoordinates, Suite.db.showClock = false, false, false, false
map:UpdateStats()
equal(map.panel:IsShown(), false, "empty stats row is hidden")
Suite.db.showFPS = true
map:UpdateStats()
equal(map.panel:IsShown(), true, "stats row reappears when it has content")
Suite.db.squareMinimap = false
map:Apply()
equal(map.header:IsShown(), false, "disabling square mode restores native header")
equal(Minimap.questRingScalar, 1, "minimap stats alone preserve the normal quest ring")
equal(MinimapCluster:IsClampedToScreen(), true, "disabling square mode restores original screen clamping")
equal(Minimap:IsClampedToScreen(), false, "originally unclamped map stays unclamped after restore")
equal(MinimapCluster.BorderTop:IsShown(), true, "native header art restores")
equal(MinimapCluster.ZoneTextButton.point[2], originalZonePoint[2], "native zone anchor target restores")
equal(MinimapCluster.ZoneTextButton.point[1], originalZonePoint[1], "native zone anchor restores")
equal(MinimapCluster.ZoneTextButton.width, 135, "native zone dimensions restore")
equal(TimeManagerClockButton.point[2], originalClockPoint[2], "native clock anchor restores")
equal(TimeManagerClockButton.height, 16, "native clock size restores")
equal(TimeManagerClockTicker.fontSize, 11, "native clock font size restores")
equal(TimeManagerClockTicker.fontFlags, "", "native clock font flags restore")
equal(GameTimeFrame.height, 18, "native calendar size restores")
equal(MinimapCluster.Tracking.height, 17, "native tracking size restores")
equal(MinimapZoneText:IsShown(), true, "native zone text restores")
equal(coords.point, originalCoordsPoint, "coordinate anchors survive header restoration")
Suite.db.minimapStats = false
map:Apply()
equal(tickerCancels, 1, "disabled stats cancel the ticker")
equal(map.panel:IsShown(), false, "disabled stats hide the row")
assert(loadfile("tests/minimap_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
combat = true
Suite.db.squareMinimap = true
map:Apply()
equal(map.header:IsShown(), false, "header changes defer in combat")
equal(MinimapCluster:IsClampedToScreen(), true, "screen clamp changes defer in combat")
combat = false
frames[1].OnEvent(frames[1], "PLAYER_REGEN_ENABLED")
equal(map.header:IsShown(), true, "deferred header update applies after combat")
equal(MinimapCluster:IsClampedToScreen(), false, "deferred screen unclamping applies after combat")

-- Header guidance uses the native tooltip immediately and respects ownership.
Suite.db.windowTools = true
queued = {}
GameTooltip = Frame()
GameTooltip.SetOwner = function(self, owner, anchor) self.owner, self.anchor, self.lines = owner, anchor, {} end
GameTooltip.IsOwned = function(self, owner) return self.owner == owner end
menuHeader.handle:Show()
menuHeader.handle.OnEnter(menuHeader.handle)
equal(GameTooltip:IsShown(), true, "header help appears immediately")
equal(#queued, 0, "header help does not install a delay timer")
equal(GameTooltip.anchor, "ANCHOR_CURSOR", "header uses native cursor tooltip positioning")
menuHeader.handle.OnLeave(menuHeader.handle)
equal(GameTooltip:IsShown(), false, "leaving a header dismisses the native tooltip")
menuHeader.handle.OnEnter(menuHeader.handle)
equal(GameTooltip.lines[4][1]:find("Ctrl+right-click", 1, true) ~= nil, true, "header hint explains reset")
equal(GameTooltip.lines[5][1]:find("open its menu", 1, true) ~= nil, true, "bag header hint explains ordinary clicking")
GameTooltip.owner = Minimap
menuHeader.handle.OnLeave(menuHeader.handle)
equal(GameTooltip:IsShown(), true, "header leave does not hide another owner's tooltip")
menuHeader.handle.OnEnter(menuHeader.handle)
menuHeader.handle.OnMouseDown(menuHeader.handle, "LeftButton")
equal(GameTooltip:IsShown(), false, "mouse down dismisses header guidance")
menuHeader.handle.OnEnter(menuHeader.handle)
Suite.db.windowTools = false
Suite.Windows:ApplyRecord(menuHeader)
equal(GameTooltip:IsShown(), false, "disabled movement hides owned header guidance")

-- Launcher geometry follows both shapes; drag updates exist only during a gesture.
local launcher = Suite.MinimapButton
Suite.db.minimapButton, Suite.db.squareMinimap = true, false
Suite.db.minimapButtonAngle = 45
launcher:Apply()
equal(launcher.button:IsShown(), true, "minimap launcher is enabled initially")
local innerX = launcher.button.point[4] - launcher.button:GetWidth() / 2
local innerY = launcher.button.point[5] - launcher.button:GetHeight() / 2
equal(math.abs(math.sqrt(innerX * innerX + innerY * innerY) - 121) < 0.001, true, "round launcher's nearest corner sits outside the map")
equal(math.abs(launcher.button.point[4] - launcher.button.point[5]) < 0.001, true, "round launcher has matching outward diagonal offsets")
Suite.db.squareMinimap = true
launcher:Apply()
equal(math.abs(launcher.button.point[4] - launcher.button:GetWidth() / 2 - 121) < 0.001, true, "square launcher inner edge aligns outside the right minimap border")
equal(math.abs(launcher.button.point[5] - launcher.button:GetHeight() / 2 - 121) < 0.001, true, "square launcher inner edge aligns outside the top minimap border")
local scale = Minimap:GetEffectiveScale()
cursorX, cursorY = (500 + 134) * scale, 400 * scale
launcher.button.OnMouseDown()
launcher.button.OnDragStart()
equal(launcher.dragging, true, "launcher drag begins outside combat")
equal(Suite.db.minimapButtonAngle, 0, "drag cursor is converted through minimap scale")
equal(type(launcher.button.OnUpdate), "function", "drag installs a temporary update")
cursorX, cursorY = 500 * scale, (400 - 134) * scale
launcher.button.OnUpdate()
equal(math.abs(Suite.db.minimapButtonAngle - 270) < 0.001, true, "drag continues around the bottom edge")
launcher.button.OnDragStop()
equal(launcher.button.OnUpdate, nil, "ending drag removes the update")
local guiWasShown = Suite.GUI.frame:IsShown()
launcher.button.OnClick()
equal(Suite.GUI.frame:IsShown(), guiWasShown, "drag release does not accidentally open settings")
launcher.button.OnMouseDown()
launcher.button.OnClick()
equal(Suite.GUI.frame:IsShown(), not guiWasShown, "ordinary launcher click toggles settings")
combat = true
local savedAngle = Suite.db.minimapButtonAngle
launcher.button.OnMouseDown()
launcher.button.OnDragStart()
equal(launcher.button.OnUpdate, nil, "launcher cannot start repositioning in combat")
equal(Suite.db.minimapButtonAngle, savedAngle, "combat drag preserves the saved angle")
combat = false
launcher.button.OnDragStart()
equal(type(launcher.button.OnUpdate), "function", "launcher starts its gesture updater before combat")
combat = true
launcher.events.OnEvent(launcher.events, "PLAYER_REGEN_DISABLED")
equal(launcher.dragging, false, "combat entry immediately cancels an existing launcher drag")
equal(launcher.button.OnUpdate, nil, "combat entry removes the launcher updater without waiting for another frame")
equal(Suite.db.minimapButtonAngle, savedAngle, "combat interruption retains the last launcher angle")
combat = false
Suite.db.minimapButton = false
launcher:Apply()
equal(launcher.button:IsShown(), false, "launcher can be hidden independently")
Suite.db.minimapButton = true
launcher:Apply()
equal(launcher.button:IsShown(), true, "launcher can be shown again")
equal(Suite.db.minimapButtonAngle, savedAngle, "hiding the launcher preserves its position")
GameTooltip = Frame()
GameTooltip.SetOwner = function(self, owner) self.owner, self.lines = owner, {} end
GameTooltip.IsOwned = function(self, owner) return self.owner == owner end
launcher.button.OnEnter()
equal(GameTooltip:IsShown(), true, "launcher hover explains its controls")
equal(GameTooltip.lines[2][1]:find("Drag", 1, true) ~= nil, true, "launcher help teaches dragging")
launcher.button.OnLeave()
equal(GameTooltip:IsShown(), false, "launcher help hides on leave")
GameTooltip.owner = Minimap
GameTooltip:Show()
launcher:HideTooltip()
equal(GameTooltip:IsShown(), true, "launcher does not hide another tooltip owner's content")
Suite.GUI:Select("minimap")
equal(#Suite.GUI.rows, 8, "minimap page includes launcher and drawer toggles")
equal(Suite.GUI.rows[1].label.text, "Minimap button", "launcher visibility setting is easy to find")
equal(-Suite.GUI.rows[8].point[3] + Suite.GUI.rows[8].height < Suite.GUI.content.height - 28, true, "eight minimap settings fit above the footer")
equal(Suite.GUI.rows[2].label.text, "Addon button drawer", "drawer has its independent minimap setting")

-- Model elapsed time and server responses: mouseover must work without targeting/clicking.
do
    local now, timers, sent = 100, {}, {}
    local units = { player = "self" }
    local levels, inspectable = {}, true
    GetTime = function() return now end
    UnitGUID = function(unit) return units[unit] end
    UnitTokenFromGUID = function(guid)
        if units.target == guid then return "target" end -- Deliberately misses mouseover.
        if units.player == guid then return "player" end
    end
    CanInspect = function() return inspectable end
    C_PaperDollInfo.GetInspectItemLevel = function(unit) return levels[units[unit]] end
    C_Timer.NewTimer = function(delay, callback)
        local timer = { at = now + delay, callback = callback, Cancel = function(self) self.cancelled = true end }
        timers[#timers + 1] = timer
        return timer
    end
    hooksecurefunc("NotifyInspect", function(unit) sent[#sent + 1] = { unit = unit, guid = units[unit], at = now } end)
    local function Advance(seconds)
        local finish, steps = now + seconds, 0
        while true do
            local nextIndex
            for index, timer in ipairs(timers) do
                if not timer.cancelled and timer.at <= finish and (not nextIndex or timer.at < timers[nextIndex].at) then nextIndex = index end
            end
            if not nextIndex then break end
            local timer = table.remove(timers, nextIndex)
            now = timer.at
            timer.callback()
            steps = steps + 1
            assert(steps < 1000, "inspect timers must remain bounded")
        end
        now = finish
    end
    local function TimerCount()
        local count = 0
        for _, timer in ipairs(timers) do if not timer.cancelled then count = count + 1 end end
        return count
    end
    local tips = Suite.Tooltips
    tips:CancelInspect()
    tips.cache, tips.lastInspect = {}, -10
    Suite.db.playerItemLevel, Suite.db.classNames = true, false
    InspectFrame = nil
    local playerTip = Frame("InspectTestTooltip")
    playerTip.GetPrimaryTooltipData = function(self) return self.data end
    playerTip.GetUnit = function() return nil end -- Native shim cannot resolve an untargeted player.
    playerTip.NumLines = function(self) return #self.lines end
    playerTip.AddDoubleLine = function(self, label, value)
        local left, right = Frame(), Frame()
        left:SetText(label); right:SetText(value)
        self.lines[#self.lines + 1] = { label, value, left = left, right = right }
        _G[self.name .. "TextLeft" .. #self.lines] = left
        _G[self.name .. "TextRight" .. #self.lines] = right
    end
    local function Hover(guid)
        if playerTip.OnTooltipCleared then playerTip.OnTooltipCleared(playerTip) end
        playerTip.lines, playerTip.data = {}, { guid = guid }
        units.mouseover = guid
        playerTip:Show()
        tooltipCallbacks[2](playerTip, playerTip.data)
    end
    local function Ready(guid) tips.events.OnEvent(tips.events, "INSPECT_READY", guid) end
    Hover("mageA")
    equal(TimerCount(), 1, "untargeted mouseover queues an inspect even when the native shim returns nil")
    tooltipCallbacks[2](playerTip, playerTip.data)
    equal(TimerCount(), 1, "repeated unit callbacks coalesce the pending inspect")
    Advance(0.11)
    equal(#sent, 1, "cold mouseover starts inspection within a tenth of a second")
    equal(sent[1].unit, "mouseover", "inspection uses mouseover without selecting a target")
    equal(units.target, nil, "player remains untargeted")
    Ready("unrelated")
    equal(#playerTip.lines, 0, "unrelated inspect responses cannot fill the hovered player's tooltip")
    levels.mageA = 0
    Ready("mageA")
    equal(tips.cache.mageA, nil, "zero inspect data is not cached as an equipment level")
    levels.mageA = 18.6
    Advance(0.21)
    equal(playerTip.lines[1].left.text, "Item Level", "fresh inspect data keeps the left-column label")
    equal(playerTip.lines[1].right.text, "19", "late item data fills the rounded right-column value")
    equal(#sent, 1, "briefly delayed item data does not require another server request")
    equal(TimerCount(), 0, "successful inspection cancels its timeout and retry timers")
    Hover("mageA")
    tooltipCallbacks[2](playerTip, playerTip.data)
    equal(#playerTip.lines, 1, "cached player levels update one row without duplicate annotations")
    equal(#sent, 1, "cached hover requires no new inspect")

    Hover("mageB")
    Advance(0.11)
    equal(#sent, 1, "cold player waits for the shared inspect cooldown")
    equal(TimerCount(), 1, "cooldown retains a scheduled request instead of dropping the hover")
    Advance(2.7)
    equal(sent[#sent].guid, "mageB", "cold player automatically inspects after cooldown without another hover or click")
    levels.mageB = 20
    Ready("mageB")
    equal(playerTip.lines[1].right.text, "20", "queued inspect fills the current player's tooltip")

    Hover("mageC")
    Advance(3.01)
    equal(sent[#sent].guid, "mageC", "third player begins an inspect")
    Hover("mageD")
    levels.mageC = 30
    Ready("mageC")
    equal(#playerTip.lines, 0, "leaving a player prevents its late response from appearing on the next tooltip")
    Advance(3.01)
    equal(sent[#sent].guid, "mageD", "new hover is not blocked by the abandoned player's eight-second timeout")
    levels.mageD = 22
    Ready("mageD")

    Hover("timeout")
    Advance(3.01)
    local beforeRetry = #sent
    Advance(8.01)
    equal(#sent, beforeRetry + 1, "missing server response automatically retries while still hovering")
    levels.timeout = 24
    Ready("timeout")
    equal(playerTip.lines[1].right.text, "24", "a retry response fills the tooltip without clicking")

    Hover("hidden")
    Advance(3.01)
    playerTip:Hide(); playerTip.OnHide(playerTip)
    local beforeHidden = #sent
    Advance(9)
    Ready("hidden")
    equal(#sent, beforeHidden, "hiding the tooltip cancels all inspect retries")
    equal(tips.inspectRequest, nil, "hidden tooltip retains no pending inspect")

    Hover("busy")
    Advance(0.11)
    local beforeExternal = #sent
    NotifyInspect("mouseover") -- Even an external request for the same GUID owns the inspect context.
    Advance(9)
    equal(#sent, beforeExternal + 1, "external inspect takes ownership without automatic addon reinspection")
    equal(tips.inspectRequest, nil, "external inspect cancels our bookkeeping and timeout")

    combat = true
    Hover("combat")
    equal(TimerCount(), 0, "combat hover creates no inspect timer")
    combat = false
    tips.events.OnEvent(tips.events, "PLAYER_REGEN_ENABLED")
    Advance(0.11)
    equal(sent[#sent].guid, "combat", "visible hover resumes inspection on leaving combat")
    combat = true
    tips.events.OnEvent(tips.events, "PLAYER_REGEN_DISABLED")
    equal(TimerCount(), 0, "entering combat cancels an active inspect timeout")
    combat = false

    inspectable = { secret = true }
    Hover("restricted")
    local beforeRestricted = #sent
    Advance(1.11)
    equal(#sent, beforeRestricted, "secret CanInspect result is never treated as permission to inspect")
    Suite.db.playerItemLevel = false
    tips:Apply()
    equal(TimerCount(), 0, "disabling player item levels cancels the pending retry")

    Suite.db.playerItemLevel, inspectable = true, true
    Hover("noResponse")
    local beforeBounded = #sent
    Advance(26)
    equal(#sent - beforeBounded, 3, "unresponsive player receives at most three inspect requests per hover")
    equal(TimerCount(), 0, "unresponsive hover does not leave an endless polling timer")
    equal(tips.cache.noResponse, nil, "unresponsive inspection does not invent or cache an item level")
    Hover({ secret = true })
    equal(TimerCount(), 0, "secret tooltip identity cannot schedule an inspect")
end

assert(loadfile("tests/character_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/macros_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/camping_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/meters_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/windows_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/actionbars_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/actionbar_skin_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/keybinds_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/quest_tracker_skin_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/hud_skin_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/buff_borders_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/unitframes_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/targetthreat_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/vendor_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/inventory_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/offlinebank_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/minimapdrawer_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/mail_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/chat_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/items_spec.lua"))(Suite, equal)
assert(loadfile("tests/upgrade_spec.lua"))(Suite, equal, Frame)
assert(loadfile("tests/quests_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/loot_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/bagsort_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/bagsortdirection_spec.lua"))(Suite, equal, function(value) combat = value end)
assert(loadfile("tests/combinedbags_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/bagspace_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/questitem_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/worldmap_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/settings_spec.lua"))(Suite, equal, Frame, function(value) combat = value end, frames[1])
assert(loadfile("tests/setup_spec.lua"))(Suite, equal, Frame, function(value) combat = value end, frames[1])
assert(loadfile("tests/missing_buffs_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/inventorysearch_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/dashboard_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/gui_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/qol_trio_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/audio_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/autoopen_spec.lua"))(Suite, equal, Frame, function(value) combat = value end)
assert(loadfile("tests/leveling_spec.lua"))(Suite, equal, Frame, function(value) combat = value end, frames[1])
print("Behavior checks passed: " .. checks)
