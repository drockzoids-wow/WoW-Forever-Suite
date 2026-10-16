local Suite, equal, Frame, SetCombat = ...
local meters = Suite.DamageMeters
SetCombat(false)
Suite.db = Suite.InitializeDB(nil)
meters:Apply()
equal(Suite.db.damageMeters, false, "damage meters default off")
equal(Suite.db.meterLocked, false, "meters start unlocked for placement")
equal(#meters.windows, 0, "disabled meters create no gameplay frames")
equal(meters.events, nil, "disabled meters register no events")
equal(Suite.db.meterWindows[1].classColors, false, "meter bars default to Suite teal")
equal(Suite.db.meterWindows[2].metric, "HealingDone", "second window defaults to healing")

local timers, created, menus = {}, 0, {}
local oldCreate, oldTimer, oldEnum = CreateFrame, C_Timer, Enum
local oldAPI, oldMenu, oldAlt = C_DamageMeter, MenuUtil, IsAltKeyDown
local oldTooltip, oldControl = GameTooltip, IsControlKeyDown
local oldCursor, oldClassColors = GetCursorPosition, RAID_CLASS_COLORS
local oldClassAtlas, oldClassCoords, oldNumberFont = GetClassAtlas, CLASS_ICON_TCOORDS, NumberFontNormal
local oldMouseFoci, oldAncestry = GetMouseFoci, DoesAncestryIncludeAny
local oldOpenMenu = meters.OpenMenu
meters.OpenMenu = function(self, ...)
    oldOpenMenu(self, ...)
    if self.menuUI and self.menuUI.rootDescription then menus[#menus + 1] = self.menuUI.rootDescription end
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
local function Flush()
    local pending = timers; timers = {}
    for _, timer in ipairs(pending) do if not timer.cancelled then timer.callback() end end
end
local function Secret()
    return setmetatable({ secret = true }, { __lt = function() error("compared secret meter value") end,
        __le = function() error("compared secret meter value") end, __div = function() error("divided secret meter value") end,
        __concat = function() error("formatted secret meter value") end })
end
do
    local saved = Suite.db.meterWindows
    Suite.db.meterWindows = { { fontSize = 11, numbers = "compact" }, { fontSize = 12, numbers = "full" } }
    meters:Normalize()
    equal(Suite.db.meterWindows[1].fontSize, 14, "old default text size upgrades to the native fourteen-point size")
    equal(Suite.db.meterWindows[2].fontSize, 12, "different custom text size survives the appearance migration")
    equal(Suite.db.meterWindows[1].numbers, "full", "existing compact preference upgrades to requested exact totals once")
    equal(Suite.db.meterWindows[2].numbers, "full", "existing full-number preference remains full")
    Suite.db.meterWindows[1].numbers = "compact"; meters:Normalize()
    equal(Suite.db.meterWindows[1].numbers, "compact", "later deliberate compact choice survives normalization")
    Suite.db.meterWindows[1].fontSize = 11; meters:Normalize()
    equal(Suite.db.meterWindows[1].fontSize, 11, "later deliberate small text choice survives normalization")
    Suite.db.meterWindows[1].fontRevision, Suite.db.meterWindows[1].fontSize = Secret(), Secret()
    meters:Normalize()
    equal(Suite.db.meterWindows[1].fontSize, 14, "restricted saved font settings fall back without comparison")
    Suite.db.meterWindows[1].numberRevision, Suite.db.meterWindows[1].numbers = Secret(), Secret()
    meters:Normalize()
    equal(Suite.db.meterWindows[1].numbers, "full", "restricted number preferences migrate without comparison")
    Suite.db.meterWindows = saved
end
CreateFrame = function(kind, name, parent)
    assert(not InCombatLockdown(), "no meter frame construction in combat")
    created = created + 1
    local frame = Frame(name)
    frame.objectType, frame.parent = kind, parent
    frame.SetAllPoints = function() end
    frame.SetClipsChildren = function(self, clip) self.clipsChildren = clip end
    frame.SetMinMaxValues = function(self, low, high) self.low, self.high = low, high end
    frame.SetValue = function(self, value)
        if self.objectType == "Slider" then
            value = math.max(self.low, math.min(self.high, value))
            local changed = self.value ~= value; self.value = value
            if changed and self.OnValueChanged then self:OnValueChanged(value) end
        else self.value = value end
    end
    frame.GetValue = function(self) return self.value or self.low or 0 end
    frame.SetOrientation = function(self, orientation) self.orientation = orientation end
    frame.SetValueStep = function(self, step) self.valueStep = step end
    frame.SetObeyStepOnDrag = function(self, obey) self.obeyStep = obey end
    frame.SetThumbTexture = function(self, texture) self.thumb = Frame(); self.thumb.texture = texture end
    frame.GetThumbTexture = function(self) return self.thumb end
    frame.SetStatusBarTexture = function(self, texture) self.texture = texture end
    frame.GetStatusBarTexture = function(self)
        self.statusTexture = self.statusTexture or self:CreateTexture()
        return self.statusTexture
    end
    frame.SetStatusBarColor = function(self, ...) self.barColor = { ... } end
    frame.SetMaxLetters = function() end
    frame.SetTextInsets = function() end
    frame.HasFocus = function(self) return self.focused == true end
    frame.SetFocus = function(self) self.focused = true; if self.OnEditFocusGained then self:OnEditFocusGained() end end
    frame.ClearFocus = function(self) self.focused = false; if self.OnEditFocusLost then self:OnEditFocusLost() end end
    frame.Hide = function(self)
        local wasShown = self.shown == true; self.shown = false
        if wasShown and self.OnHide then self:OnHide() end
    end
    frame.Show = function(self)
        local wasShown = self.shown == true; self.shown = true
        if not wasShown and self.foreverMeter and not self.firstShowAnchor then self.firstShowAnchor = { unpack(self.point or {}) } end
        if not wasShown and self.OnShow then self:OnShow() end
    end
    frame.SetShown = function(self, shown) if shown then self:Show() else self:Hide() end end
    frame.RegisterEvent = function(self, event) self.events = self.events or {}; self.events[event] = true end
    frame.UnregisterEvent = function(self, event) if self.events then self.events[event] = nil end end
    frame.UnregisterAllEvents = function(self) self.events = {} end
    frame.SetPoint = function(self, ...)
        assert(not InCombatLockdown() or self.foreverMeterMenu and self.parent == UIParent,
            "only independent unprotected menu panels may be anchored in combat")
        self.point = { ... }
    end
    frame.SetHeight = function(self, height)
        assert(not InCombatLockdown() or self.foreverMeterMenu and self.parent == UIParent,
            "only independent unprotected menu panels may change height in combat")
        assert(type(height) == "number" and not issecretvalue(height), "menu height stays readable")
        self.height = height
    end
    frame.SetSize = function(self, width, height)
        assert(not InCombatLockdown(), "no meter sizing in combat")
        self.width, self.height = width, height
    end
    frame.CreateFontString = function(self)
        local font = Frame(); font.parent = self
        font.SetWidth = function(self, width) self.width, self.explicitWidth = width, true end
        font.SetFormattedText = function(self, format, ...)
            self.nativeSecret, self.nativeFormat, self.nativeArgs = nil, format, { ... }
            for index = 1, select("#", ...) do
                local value = select(index, ...)
                if issecretvalue(value) then self.nativeSecret = value; break end
            end
            if self.nativeSecret then self.text = "<native secret>"
            else self.text = string.format(format, ...) end
        end
        return font
    end
    frame.CreateTexture = function()
        local texture = Frame(); texture.SetAllPoints = function() end
        texture.SetVertexOffset = function(self, index, x, y)
            assert(not InCombatLockdown(), "meter triangle geometry is configured only outside combat")
            self.vertexOffsets = self.vertexOffsets or {}; self.vertexOffsets[index] = { x, y }
        end
        texture.SetAtlas = function(self, atlas)
            assert(not issecretvalue(atlas), "secret class never enters an atlas lookup")
            self.atlas = atlas
        end
        texture.SetTexture = function(self, asset) self.texture, self.atlas = asset, nil end
        return texture
    end
    return frame
end
UIParent = Frame(); UIParent:SetSize(1000, 800)
local available, restrictedHistory, alt, control = true, false, false, false
local meterCursorX, meterCursorY = 200, 300
GetCursorPosition = function() return meterCursorX, meterCursorY end
RAID_CLASS_COLORS = { MAGE = { r = 0.2, g = 0.6, b = 1 } }
CLASS_ICON_TCOORDS = {}
for _, class in ipairs({ "WARRIOR", "MAGE", "ROGUE", "PRIEST", "DRUID", "HUNTER", "SHAMAN", "PALADIN", "WARLOCK" }) do
    CLASS_ICON_TCOORDS[class] = { 0, 1, 0, 1 }
end
GetClassAtlas = function(class) assert(type(class) == "string"); return "classicon-" .. class end
NumberFontNormal = { GetFont = function() return "Fonts\\ARIALN.TTF", 14, "OUTLINE, MONOCHROME" end }
local mouseFoci = {}
GetMouseFoci = function() return mouseFoci end
DoesAncestryIncludeAny = function(root, foci)
    for _, focus in ipairs(foci) do
        assert(not issecretvalue(focus), "restricted focus never enters native ancestry lookup")
        local region = focus
        while region do
            if region == root then return true end
            region = region:GetParent()
        end
    end
    return false
end
IsAltKeyDown = function() return alt end
IsControlKeyDown = function() return control end
GameTooltip = nil
Enum = { DamageMeterSessionType = { Overall = 0, Current = 1 }, DamageMeterType = {} }
for index, metric in ipairs(meters.metrics) do Enum.DamageMeterType[metric.key] = index - 1 end
local histories = { { sessionID = 77, name = "Repeated fight", durationSeconds = 61 },
    { sessionID = 78, name = "Repeated fight", durationSeconds = nil }, { sessionID = 79, name = "", durationSeconds = Secret() },
    { sessionID = Secret(), name = "Unavailable ID" } }
local calls, idCalls = {}, {}
local sources = {}
for i = 1, 100 do sources[i] = { name = "Player " .. i, classFilename = "MAGE", totalAmount = 1000 - i, amountPerSecond = 200 - i } end
local data = { combatSources = sources, maxAmount = 1000, durationSeconds = 61 }
C_DamageMeter = {
    IsDamageMeterAvailable = function() return available, "Unavailable in this mode" end,
    GetAvailableCombatSessions = function() return restrictedHistory and Secret() or histories end,
    GetCombatSessionFromType = function(sessionType, metric) calls[#calls + 1] = { sessionType, metric }; return data end,
    GetCombatSessionFromID = function(id, metric) idCalls[#idCalls + 1] = { id, metric }; return data end,
}
MenuUtil = { CreateContextMenu = function() error("Suite meters must not enter Blizzard's shared menu compositor") end }
local function Rects() return Suite.Copy(meters.rects) end

Suite.db.damageMeters = true
SetCombat(true)
meters:Apply()
equal(created, 0, "enabling in combat defers meter construction")
SetCombat(false)
local apply = Suite.pending.meters; Suite.pending.meters = nil; apply()
equal(#meters.windows, 2, "enable creates exactly two windows")
local first, second = meters.windows[1], meters.windows[2]
equal(first.frame.firstShowAnchor[1], "BOTTOMLEFT", "first meter has its final anchor before becoming visible")
equal(second.frame.firstShowAnchor[1], "BOTTOMLEFT", "second meter has its final anchor before becoming visible")
equal(first.frame.firstShowAnchor[4], meters.rects[1].x, "first meter show uses the settled horizontal position")
equal(second.frame.firstShowAnchor[5], meters.rects[2].y, "second meter show uses the settled vertical position")
equal(first.frame.foreverMeter, true, "meter has its own layout ownership marker")
Suite.Windows:Track("meterTest", first.frame)
equal(Suite.Windows.tracked.meterTest, nil, "general mover cannot also own a meter window")
equal(first.rows[1].bar.barColor[1], 0.20, "default bar uses Suite teal")
equal(first.rows[1].bar.statusTexture.atlas, "UI-HUD-CoolDownManager-Bar", "bar uses matching native meter fill artwork")
equal(first.rows[1].background.atlas, "ui-damagemeters-bar-shadowbg", "row uses native shaded track artwork")
equal(first.rows[1].edge.atlas, "ui-damagemeters-bar-shadowedge", "row uses native soft bar edges")
equal(first.rows[1].name.fontPath, "Fonts\\ARIALN.TTF", "rows use the native meter font instead of the old title font")
equal(first.rows[1].name.fontSize, 14, "fresh meter text starts at the native fourteen-point size")
equal(first.rows[1].name.fontFlags, "OUTLINE", "shared monochrome flags do not reach our meter rows")
equal(Suite.db.meterWindows[1].numbers, "full", "fresh meters use exact full numbers")
equal(first.rows[1].value.fontPath, first.rows[1].name.fontPath, "amounts and names share the native font")
equal(first.rows[1].name.textColor[1], 1, "bar labels use native white text")
equal(first.rows[1].icon.atlas, "classicon-MAGE", "known source receives its native class icon")
equal(first.rows[1].icon.width, Suite.db.meterWindows[1].rowHeight, "class icon follows the full row height")
equal(first.rows[1].bar.point[4], Suite.db.meterWindows[1].rowHeight, "bar starts to the right of the class icon")
do
    local source = sources[1]
    source.classFilename = "WARRIOR"; meters:RefreshWindow(first)
    equal(first.rows[1].icon.atlas, "classicon-WARRIOR", "recycled row updates its class icon")
    source.classFilename = Secret(); meters:RefreshWindow(first)
    equal(first.rows[1].icon:IsShown(), false, "restricted class is never used for an atlas lookup")
    equal(first.rows[1].icon.atlas, nil, "restricted class clears the previous icon")
    source.classFilename = "UNKNOWN"; meters:RefreshWindow(first)
    equal(first.rows[1].icon:IsShown(), false, "unrecognized class never requests an invalid atlas")
    source.classFilename = "MAGE"
    local atlasAPI = GetClassAtlas; GetClassAtlas = nil; meters:RefreshWindow(first)
    equal(first.rows[1].icon:IsShown(), false, "missing class atlas capability leaves a clean row")
    GetClassAtlas = atlasAPI; meters:RefreshWindow(first)
    equal(first.rows[1].icon.atlas, "classicon-MAGE", "restored class capability repopulates the current icon")
end
equal(first.visibleRows > 0, true, "layout has visible rows")
equal(first.frame.height, second.frame.height, "default side docking matches height")
equal(meters.rects[2].x, meters.rects[1].x + meters.rects[1].width + Suite.db.meterGap, "default docking aligns join")
equal(first.rows[1].value.text, "999 (199)", "damage pairs supplied total and DPS without duration arithmetic")
equal(second.rows[1].value.text, "999 (199)", "healing pairs supplied total and HPS")
do
    local source, value = sources[1], first.rows[1].value
    local total, rate = source.totalAmount, source.amountPerSecond
    source.totalAmount, source.amountPerSecond = 16568, 13.5
    meters:RefreshWindow(first)
    equal(value.text, "16,568 (13.5)", "reported example retains exact damage and decimal DPS")
    source.amountPerSecond = 1234.5; meters:RefreshWindow(first)
    equal(value.text, "16,568 (1,234.5)", "large fractional rates keep grouping and decimal precision")
    source.amountPerSecond = 13.5
    meters:ChooseMetric(1, "Dps")
    equal(value.text, "13.5/s", "rate-only view retains fractional DPS")
    meters:ChooseMetric(1, "HealingDone")
    equal(value.text, "16,568 (13.5)", "healing retains exact total and fractional HPS")
    meters:ChooseMetric(1, "DamageDone")
    source.totalAmount, source.amountPerSecond = 972600, 38900
    meters:RefreshWindow(first)
    equal(value.text, "972,600 (38,900)", "full numbers preserve both grouped total and whole supplied rate")
    meters:SetOption(1, "numbers", "compact")
    equal(value.text, "972.6k (38.9k)", "compact damage matches the requested total and parenthesized DPS")
    source.totalAmount, source.amountPerSecond = 1234567, 999
    meters:RefreshWindow(first)
    equal(value.text, "1.2m (999)", "total and rate abbreviate independently")
    meters:SetOption(1, "numbers", "full")
    equal(value.text, "1,234,567 (999)", "full numbers preserve both values with grouping and no rate suffix")
    meters:SetOption(1, "numbers", "compact")
    source.totalAmount, source.amountPerSecond = 0, 0
    meters:RefreshWindow(first)
    equal(value.text, "0 (0)", "zero supplied rate remains visible")
    source.totalAmount = 972600
    for _, invalid in ipairs({ { label = "missing" }, { value = "bad", label = "text" },
        { value = false, label = "boolean" }, { value = 0 / 0, label = "NaN" },
        { value = math.huge, label = "infinite" } }) do
        source.amountPerSecond = invalid.value
        meters:RefreshWindow(first)
        equal(value.text, "972.6k", invalid.label .. " rate leaves the total without an invented DPS")
    end
    source.amountPerSecond = 38900
    for _, key in ipairs({ "DamageTaken", "AvoidableDamageTaken", "EnemyDamageTaken", "HealingDone" }) do
        meters:ChooseMetric(1, key)
        equal(value.text, "972.6k (38.9k)", key .. " pairs its own supplied total and rate")
    end
    for _, key in ipairs({ "Interrupts", "Dispels", "Deaths" }) do
        meters:ChooseMetric(1, key)
        equal(value.text, "972.6k", key .. " remains a single count")
    end
    meters:ChooseMetric(1, "DamageDone")
    local secretTotal, secretRate = Secret(), Secret()
    local oldWidth = value.GetStringWidth
    value.GetStringWidth = function() error("cannot measure secret meter text") end
    local framesBeforePair = created
    SetCombat(true)
    source.totalAmount, source.amountPerSecond = secretTotal, secretRate
    meters:RefreshWindow(first)
    equal(value.nativeFormat, "%.0f (%.1f)", "two hidden numbers retain rate precision through native paired formatting")
    equal(value.nativeArgs[1], secretTotal, "hidden total passes untouched to native formatting")
    equal(value.nativeArgs[2], secretRate, "hidden DPS passes untouched to native formatting")
    source.amountPerSecond = 38900
    meters:RefreshWindow(first)
    equal(value.nativeFormat, "%.0f (%s)", "hidden total and readable rate format independently")
    equal(value.nativeArgs[2], "38.9k", "readable rate can abbreviate beside a hidden total")
    source.totalAmount, source.amountPerSecond = 972600, secretRate
    meters:RefreshWindow(first)
    equal(value.nativeFormat, "%s (%.1f)", "readable total and hidden rate format independently")
    equal(value.nativeArgs[1], "972.6k", "readable total can abbreviate beside a hidden DPS")
    equal(value.nativeArgs[2], secretRate, "second-position secret is passed only to the native widget")
    local oldGrouping = BreakUpLargeNumbers
    local secretGrouped = Secret()
    BreakUpLargeNumbers = function(amount)
        equal(amount, secretTotal, "native grouping accepts the original opaque total")
        return secretGrouped
    end
    meters.ui.pair(value, secretTotal, secretRate, false)
    equal(value.nativeFormat, "%s (%.1f)", "native grouped text pairs with a native decimal-rate argument")
    equal(value.nativeArgs[1], secretGrouped, "native grouped secret string is displayed without inspection")
    equal(value.nativeArgs[2], secretRate, "grouped secret total never exposes the rate to Lua")
    BreakUpLargeNumbers = oldGrouping
    source.totalAmount, source.amountPerSecond = total, rate
    meters:RefreshWindow(first)
    equal(value.text, "999 (199)", "readable updates replace a previously hidden pair")
    equal(created, framesBeforePair, "paired combat refresh creates no frames or geometry")
    SetCombat(false)
    value.GetStringWidth = oldWidth
    equal(first.rows[1].name.point[2], value, "name ends beside the native value text instead of a fixed value column")
    equal(first.rows[1].name.point[4], -4, "name and value text retain a four-unit native anchor gap")
    equal(value.explicitWidth, nil, "values use their native text width without a fixed reservation")
    meters:SetOption(1, "width", 240); meters:SetOption(1, "fontSize", 16)
    equal(first.rows[1].name.explicitWidth, nil, "narrow windows leave name width to the native anchors")
    equal(first.rows[1].name.point[2], value, "largest font at minimum width preserves the native name/value relationship")
    meters:SetOption(1, "width", 300); meters:SetOption(1, "fontSize", 11)
    meters:SetOption(1, "numbers", "full")
end
meters:ChooseMetric(1, "Dps")
equal(first.rows[1].value.text, "199/s", "DPS uses supplied rate rather than dividing total by duration")
equal(Suite.db.meterWindows[2].metric, "HealingDone", "changing first metric leaves second independent")
meters:ChooseSession(1, "Overall")
equal(calls[#calls][1], 0, "overall uses native overall session")
meters:ChooseSession(2, "History", 78)
equal(second.fightID, 78, "historical fight uses ID with duplicate names")
equal(idCalls[#idCalls][1], 78, "history queries by ID")
equal(Suite.db.meterWindows[2].session, "Current", "history ID is not persisted as session preference")
equal(Suite.db.meterWindows[2].fightID, nil, "no fight IDs in window SavedVariables")
equal(#meters:ReadHistory(), 3, "restricted ID is omitted from menu")
equal(meters.history[1].label, "Repeated fight [1:01]", "readable duration appears in history")
equal(meters.history[3].label, "Fight 79", "unnamed fight and restricted duration remain safe")
meters:OpenMenu(first, first.metric, "metric")
equal(#menus[#menus].children, 3, "metric menu has native-style categories")
equal(first.metric.borderColor[4], 1, "open metric menu highlights its Suite selector")
meters:OpenMenu(second, second.session, "session")
equal(first.metric.borderColor[4], 0.45, "switching menu owners clears the old selector highlight")
equal(menus[#menus].children[1].label, "Overall", "session menu offers overall")
equal(menus[#menus].children[2].label, "Current", "session menu expands current")
menus[#menus].children[2].children[3].callback()
equal(second.fightID, 77, "first history menu callback retains its own ID")
menus[#menus].children[2].children[4].callback()
equal(second.fightID, 78, "second history menu callback retains its own ID")

do
    local menu, storedHistory = meters.menuUI, histories
    equal(menu.root.frame.parent, UIParent, "picker belongs to Suite presentation rather than a native menu pool")
    equal(#menu.root.rows, 12, "root choices are prebuilt and bounded")
    equal(#menu.child.rows, 12, "history flyout uses a bounded prebuilt row pool")
    local escapeName
    for _, name in ipairs(UISpecialFrames) do if name == "WoWForeverSuiteMeterMenu" then escapeName = name end end
    equal(escapeName, "WoWForeverSuiteMeterMenu", "only the Suite picker receives standard Escape registration")
    histories = {}
    for index = 1, 30 do
        histories[index] = { sessionID = 1000 + index, name = "Repeated fight", durationSeconds = 61 }
    end
    histories[1].name, histories[1].durationSeconds = Secret(), Secret()
    meters:OpenMenu(second, second.session, "session")
    equal(menu.root.frame:IsShown(), true, "C/O click opens its private menu")
    equal(menu.dismiss:IsShown(), true, "outside clicks have a menu dismissal surface")
    equal(menu.root.frame.height, 52, "short root menu fits its actual two choices")
    equal(menu.root.rows[1].label.text, "Overall", "root displays Overall")
    menu.root.rows[2]:OnEnter()
    equal(menu.child.frame:IsShown(), true, "hovering Current expands the stored fights")
    equal(menu.child.rows[1].label.text, "Follow current fight", "Current flyout retains the follow-current action")
    equal(menu.child.rows[3].label.text, "Fight 1001", "hidden fight name and duration become a readable fallback")
    equal(menu.child.rows[2].enabled, false, "separator cannot trigger a fight action")
    equal(menu.child.more:IsShown(), true, "long history advertises additional scrollable fights")
    menu.child.rows[4]:OnMouseWheel(-1)
    equal(menu.child.offset, 3, "wheel over a history row scrolls the same flyout")
    menu.child.frame:OnMouseWheel(-100)
    equal(menu.child.offset, 20, "long history clamps at its last twelve entries")
    equal(menu.child.rows[12].entry.label, "Repeated fight [1:01]", "last retained fight remains selectable")
    menu.child.rows[12]:OnClick()
    equal(second.fightID, 1030, "recycled menu row selects its own retained ID despite repeated labels")
    equal(menu.root.frame:IsShown() or menu.child.frame:IsShown() or menu.dismiss:IsShown(), false,
        "selecting a fight dismisses all menu surfaces")
    equal(menu.root.rows[1].entry, nil, "closing discards menu callbacks")
    histories = storedHistory; meters:ChooseSession(2, "History", 78)

    local source, savedTotal, savedRate = sources[1], sources[1].totalAmount, sources[1].amountPerSecond
    local savedMetric, savedRect = Suite.db.meterWindows[1].metric, first.rows[1].bar.GetRect
    first.rows[1].bar.GetRect = function() error("must not measure restricted combat geometry for menus") end
    source.totalAmount, source.amountPerSecond = Secret(), Secret()
    meters:RefreshWindow(first)
    local framesBefore = created
    SetCombat(true)
    meters:OpenMenu(first, first.metric, "metric")
    equal(menu.root.rows[1].label.text, "Damage", "restricted combat bars cannot taint the menu label")
    menu.root.rows[2]:OnEnter()
    equal(menu.child.rows[1].label.text, "Healing", "combat menu expands through its private widgets")
    menu.child.rows[1]:OnClick()
    equal(Suite.db.meterWindows[1].metric, "HealingDone", "existing menu widgets can select a metric in combat")
    equal(created, framesBefore, "combat menus create no frames or shared native menu elements")
    SetCombat(false)
    source.totalAmount, source.amountPerSecond = savedTotal, savedRate
    first.rows[1].bar.GetRect = savedRect; meters:ChooseMetric(1, savedMetric)
    meters:OpenMenu(first, first.metric, "metric"); first.metric:OnLeave(); menu.root.rows[1]:OnEnter()
    equal(first.metric.borderColor[4], 1, "selector remains highlighted while moving into its menu")
    menu.root.frame:Hide()
    equal(first.metric.borderColor[4], 0.45, "Escape-style dismissal restores the quiet selector border")
    equal(menu.child.frame:IsShown() or menu.dismiss:IsShown(), false, "Escape-style hiding clears child and dismissal frames")
    meters:OpenMenu(first, first.metric, "metric"); menu.dismiss:OnMouseDown()
    equal(menu.root.frame:IsShown(), false, "outside click closes the private picker")
    meters:OpenMenu(first, first.metric, "metric"); meters:OpenMenu(first, first.metric, "metric")
    equal(menu.root.frame:IsShown(), false, "repeated arrow click toggles the picker closed")
    equal(first.metric.menuOpen, false, "repeated selector click clears active appearance state")
    meters:OpenMenu(first, first.metric, "metric"); meters:CloseMenus(2)
    equal(menu.root.frame:IsShown(), true, "other window cleanup does not dismiss this window's picker")
    meters:CloseMenus(1)
    equal(menu.rootDescription, nil, "owner cleanup drops the runtime menu description")
end

meters:SetOption(2, "height", 260)
equal(first.frame.height, 260, "side shared-height option propagates")
equal(second.frame.height, 260, "resized side member has matching height")
meters:SetOption(2, "width", 270)
equal(first.frame.width, 300, "side unshared width stays independent")
Suite.db.meterDock = { anchor = 2, side = "TOP" }; meters:Apply()
equal(first.frame.width, second.frame.width, "vertical docking matches widths")
meters:SetOption(1, "width", 330)
equal(first.frame.width, 330, "vertical resize updates selected member")
equal(second.frame.width, 330, "vertical resize updates shared width")
local previousOtherHeight = Suite.db.meterWindows[2].height
meters:Resize(1, 1)
equal(second.frame.width, first.frame.width, "Ctrl-wheel preserves vertical shared width")
equal(Suite.db.meterWindows[2].height, previousOtherHeight, "Ctrl-wheel retains partner's unshared dimension")
local beforeHide = Rects()
meters:SetOption(1, "shown", false)
equal(meters.rects[2].x, beforeHide[2].x, "hiding root does not jump remaining window horizontally")
equal(meters.rects[2].y, beforeHide[2].y, "hiding root does not jump remaining window vertically")
meters:SetOption(1, "shown", true)
meters:Detach()
equal(Suite.db.meterDock.anchor, nil, "detach removes layout link")
equal(second.fightID, 78, "detach preserves historical selection")
local far = { { x = 10, y = 30, width = 300, height = 220 }, { x = 600, y = 30, width = 280, height = 180 } }
equal(meters:SnapCandidate(1, far), nil, "far windows do not snap")
local near = { { x = 296, y = 80, width = 300, height = 180 }, { x = 600, y = 40, width = 280, height = 220 } }
equal(meters:SnapCandidate(1, near).side, "LEFT", "left snap detects near full-header alignment")
near[1].x, near[1].y = 884, 80
equal(meters:SnapCandidate(1, near).side, "RIGHT", "right snap detected")
near[1].x, near[1].y = 600, 264
equal(meters:SnapCandidate(1, near).side, "TOP", "top snap detected")
near[1].y = -144
equal(meters:SnapCandidate(1, near).side, "BOTTOM", "bottom snap detected")
Suite.db.meterSnap = false
equal(meters:SnapCandidate(1, near), nil, "snap toggle independently disables snap detection")
Suite.db.meterSnap = true

-- Secret values must only enter native setters; they must not influence Lua layout or number formatting.
local secretAmount, secretName, secretMax = Secret(), Secret(), Secret()
Suite.db.meterWindows[1].classColors = true
sources[1] = { name = secretName, classFilename = Secret(), totalAmount = secretAmount, amountPerSecond = secretAmount }
data.maxAmount, data.durationSeconds = secretMax, Secret()
SetCombat(true)
local beforeFrames = created
meters:Refresh()
equal(first.rows[1].value.nativeSecret, secretAmount, "secret rate goes directly to native formatted text")
equal(first.rows[1].name.text, secretName, "secret name goes directly to native text")
equal(first.rows[1].bar.value, secretAmount, "secret amount goes directly to status bar")
equal(first.rows[1].bar.high, secretMax, "secret maximum goes directly to bar range")
equal(first.rows[1].bar.barColor[1], 0.20, "restricted class cannot become a color key")
equal(created, beforeFrames, "combat refresh reuses prebuilt widgets")
local oldWidth = first.frame.width
meters:SetOption(1, "width", 350)
equal(first.frame.width, oldWidth, "settings sizing defers during combat")
restrictedHistory = true
meters:Refresh()
equal(second.fightID, 78, "unreadable history does not falsely evict a selected fight")
restrictedHistory = false
SetCombat(false)
apply = Suite.pending.meters; Suite.pending.meters = nil; apply()
equal(first.frame.width, 350, "latest deferred sizing applies after combat")
histories = { histories[1] }
meters:Refresh()
equal(second.fightID, nil, "actual history eviction clears stale ID")
equal(Suite.db.meterWindows[2].session, "Current", "history eviction falls back to current")
sources[1] = { name = "Player 1", classFilename = "MAGE", totalAmount = 999, amountPerSecond = 199 }
data.maxAmount, data.durationSeconds = 1000, 61
Suite.db.meterWindows[1].classColors = false
first.frame:OnMouseWheel(-1)
equal(first.offset, 3, "body scroll advances list without resizing")
equal(first.rows[1].name.text, "Player 4", "scroll uses current source order")
for _ = 1, 100 do first.frame:OnMouseWheel(-1) end
equal(first.offset, 100 - first.visibleRows, "long list scroll clamps to last entries")
Suite.db.meterWindows[1].session = "Current"
meters.events:OnEvent("DAMAGE_METER_CURRENT_SESSION_UPDATED")
equal(first.offset, 0, "follow-current resets scroll on a new fight")
meters.events:OnEvent("DAMAGE_METER_COMBAT_SESSION_UPDATED")
meters.events:OnEvent("DAMAGE_METER_CURRENT_SESSION_UPDATED")
equal(#timers, 1, "burst of session events coalesces one refresh")
Flush()
equal(meters.timer, nil, "refresh timer completes")

local savedFirst = Suite.Copy(Suite.db.meterWindows[1].position)
local savedOtherWidth = Suite.db.meterWindows[2].width
first.header:OnMouseUp("RightButton")
equal(Suite.db.meterWindows[1].position.x, savedFirst.x, "plain right-click preserves saved position")
control = true; first.header:OnMouseUp("RightButton"); control = false
equal(Suite.db.meterWindows[1].width, 300, "Ctrl-right-click resets selected width")
equal(Suite.db.meterWindows[2].width, savedOtherWidth, "reset retains other window width")
meters:StartDrag(1)
equal(type(first.header.OnUpdate), "function", "OnUpdate exists during drag only")
SetCombat(true); meters.events:OnEvent("PLAYER_REGEN_DISABLED")
equal(first.header.OnUpdate, nil, "combat interrupts drag update")
equal(meters.drag, nil, "combat cancels active drag")
SetCombat(false)
if Suite.pending.meterLayout then apply = Suite.pending.meterLayout; Suite.pending.meterLayout = nil; apply() end
meters:StartDrag(1); alt = true; meters:CancelDrag(); meters:StartDrag(1)
equal(meters.drag.detached, true, "Alt drag bypasses snap for gesture")
meters:EndDrag(); alt = false
equal(first.header.OnUpdate, nil, "release removes drag OnUpdate")

Suite.db.meterWindows[1].position = { x = 0.1, y = 0.1 }
Suite.db.meterDock = { anchor = 1, side = "RIGHT" }; meters:Apply()
local beforeMove = Rects()
meters:StartDrag(2); meterCursorX, meterCursorY = meterCursorX + 20, meterCursorY + 10
meters:DragUpdate()
equal(meters.rects[1].x, beforeMove[1].x + 20, "dragging child moves group root")
equal(meters.rects[2].y, beforeMove[2].y + 10, "dragging child moves both group members")
meters:EndDrag()
equal(Suite.db.meterWindows[1].position.x, meters.rects[1].x / 1000, "group position is saved normalized")
Suite.db.meterDock = {}
Suite.db.meterWindows[1].position, Suite.db.meterWindows[2].position = { x = 0.296, y = 0.1 }, { x = 0.6, y = 0.05 }
Suite.db.meterWindows[1].width, Suite.db.meterWindows[1].height = 300, 180
Suite.db.meterWindows[2].width, Suite.db.meterWindows[2].height = 280, 220
meters:Apply(); meters:StartDrag(1); meters:EndDrag()
equal(Suite.db.meterDock.anchor, 2, "drop makes stationary window the layout root")
equal(Suite.db.meterDock.side, "LEFT", "drop commits detected side")
equal(first.frame.height, 220, "drop matches moved window height to stationary side")
equal(first.frame.width, 300, "drop preserves unshared moved width")
equal(second.frame.width, 280, "drop preserves stationary width")
equal(meters.rects[1].x + meters.rects[1].width + Suite.db.meterGap, meters.rects[2].x, "snap commits exact join")
local outOfBounds = { { x = -100, y = -50, width = 300, height = 220 }, { x = 204, y = -50, width = 280, height = 220 } }
meters:Clamp(outOfBounds, true)
equal(outOfBounds[1].x, 0, "group clamps as a unit at screen edge")
equal(outOfBounds[2].x, 304, "clamping retains docking gap")
equal(outOfBounds[1].y, 0, "group bottom stays on screen")

available = false; meters:Refresh()
equal(first.empty.text, "Unavailable in this mode", "availability reason is shown without invented data")
available = true
Suite.db.meterWindows[1].shown, Suite.db.meterWindows[2].shown = false, false
meters:Schedule()
equal(meters.timer, nil, "two hidden windows do not schedule data refreshes")
Suite.db.meterWindows[1].shown, Suite.db.meterWindows[2].shown = true, true
meters:Schedule(); Suite.db.damageMeters = false; meters:Apply()
equal(meters.timer, nil, "disable cancels refresh timer")
equal(next(meters.events.events), nil, "disable unregisters feature events")
equal(first.frame:IsShown(), false, "disable hides window one")
equal(second.frame:IsShown(), false, "disable hides window two")
Flush()
equal(first.frame:IsShown(), false, "cancelled refresh cannot revive disabled UI")

C_DamageMeter = nil; Suite.db.damageMeters = true; meters:Apply()
equal(first.empty.text, "Damage meters are unavailable on this client.", "missing API gets clear feedback")
equal(meters.events.events.DAMAGE_METER_COMBAT_SESSION_UPDATED, nil, "missing API does not register unknown meter events")
meters:OpenMenu(first, first.metric, "metric")
equal(menus[#menus].children[1].label, "Damage", "available enum categories can still describe choices without querying absent API")
Suite.db.damageMeters = false; meters:Apply()

-- Construct the actual settings controls using the stricter EditBox substitute.
Suite.GUI:OpenMeters(2)
equal(Suite.GUI.page, "meters", "slash-accessible eighth settings page exists")
equal(Suite.GUI.meterIndex, 2, "header settings can select the correct window")
equal(Suite.GUI.meterFields.width:GetText(), "280", "settings show selected window width")
equal(Suite.GUI.meterFields.opacity:GetText(), "90", "settings show opacity as percent")
equal(Suite.GUI.meterButtons.classColors.label:GetText(), "Bars: Suite teal", "GUI describes default Suite colors")
Suite.GUI.meterFields.width:SetText("410"); Suite.GUI.meterFields.width:OnEditFocusLost()
equal(Suite.db.meterWindows[2].width, 410, "settings numeric editing configures selected window")
Suite.GUI:Select("overview")
equal(Suite.GUI.meterPanel:IsShown(), false, "settings panel hides on navigation")

-- Testing replaces only presentation, including when native recording/module visibility is off.
Suite.GUI:OpenMeters(1)
Suite.db.meterWindows[1].shown, Suite.db.meterWindows[2].shown = false, false
Suite.db.meterWindows[1].metric, Suite.db.meterWindows[2].metric = "DamageDone", "HealingDone"
first.offset, second.offset = 14, 9
first.fightID = 77
local retainedHistory = meters.history
local nativeReads = 0
local function UnexpectedRead() nativeReads = nativeReads + 1; error("preview queried native combat data") end
C_DamageMeter = { IsDamageMeterAvailable = UnexpectedRead, GetAvailableCombatSessions = UnexpectedRead,
    GetCombatSessionFromType = UnexpectedRead, GetCombatSessionFromID = UnexpectedRead }
equal(Suite.GUI.meterButtons.test.label:GetText(), "Test both windows", "settings offer a test button")
Suite.GUI.meterButtons.test:OnClick()
equal(meters.preview, true, "test button starts preview")
equal(Suite.db.damageMeters, false, "testing preserves module enable preference")
equal(Suite.db.meterWindows[1].shown, false, "testing preserves first hidden preference")
equal(Suite.db.meterWindows[2].shown, false, "testing preserves second hidden preference")
equal(first.frame:IsShown() and second.frame:IsShown(), true, "test temporarily shows both hidden meters")
equal(first.rows[1].name.text, "Sample Warrior", "test renders invented player names")
equal(first.rows[6]:IsShown() and second.rows[6]:IsShown(), true, "both default-height windows show more than five players")
equal(first.rows[1].value.text, "940,000 (9,800)", "damage test pairs exact sample totals and DPS")
equal(second.rows[1].value.text, "760,000 (7,900)", "healing test pairs distinct exact sample totals and HPS")
equal(first.testLabel.text, "TEST", "header clearly identifies test data")
equal(first.session.fullLabel, "Test data · Current", "compact session button identifies test mode in its tooltip")
equal(first.settings.fullLabel, "Window 1 options · 1–8 of 8 players", "options tooltip identifies all eight players without a footer")
equal(first.rows[8]:IsShown(), true, "compact default window fits all eight test players")
equal(first.more:IsShown(), false, "complete list has no scroll cue")
equal(first.fightID, 77, "testing preserves selected real historical fight")
equal(meters.history, retainedHistory, "testing does not replace the retained session index")
equal(Suite.GUI.meterButtons.test.label:GetText(), "Stop test", "test button offers a stop action")
equal(Suite.db.preview, nil, "test mode is not saved")
equal(Suite.db.meterWindows[1].testOffset, nil, "test state stays outside saved window preferences")
meters:SetOption(1, "height", 160)
equal(first.more:IsShown(), true, "shortened window signals more players below")
first.frame:OnMouseWheel(-1)
equal(first.rows[first.visibleRows].name.text, "Sample Paladin", "body scrolling reaches eighth test player")
equal(first.more:IsShown(), false, "scroll cue clears at the last player")
local testWidth = first.frame.width
meters:Resize(1, 1)
equal(first.frame.width > testWidth, true, "preview supports resizing while real feature is off")
local testNear = { { x = 296, y = 80, width = 300, height = 180 }, { x = 600, y = 40, width = 280, height = 220 } }
equal(meters:SnapCandidate(1, testNear).side, "LEFT", "preview supports snapping despite saved hidden target")
meters:StartDrag(1)
equal(type(first.header.OnUpdate), "function", "preview supports normal dragging")
meters:EndDrag()
meters:ChooseMetric(1, "Dps")
equal(first.rows[1].value.text, "9,800/s", "sample DPS follows metric selector")
meters:ChooseMetric(2, "Hps")
equal(second.rows[1].value.text, "7,900/s", "sample HPS follows independent metric selector")
meters:ChooseMetric(1, "Interrupts")
equal(first.rows[1].value.text, "8", "action metrics show small sample counts")
meters:OpenMenu(second, second.session, "session")
equal(menus[#menus].children[2].children[3].label, "Test players only; no stored test fights", "test menu never lists fictional combat history")
meters:Schedule()
equal(meters.timer, nil, "static test mode starts no refresh ticker or native-data timer")
equal(meters.events.events.DAMAGE_METER_COMBAT_SESSION_UPDATED, nil, "test mode skips native combat events")
equal(nativeReads, 0, "test display and selectors read no live combat API")
Suite.GUI:Select("overview")
equal(meters.preview, true, "closing test settings leaves meters usable for layout testing")
meters:OpenMenu(first, first.settings, "settings")
equal(menus[#menus].children[2].label, "Stop test", "meter header offers stop without reopening settings")
menus[#menus].children[2].callback()
equal(meters.preview, nil, "header stop action ends preview")
equal(first.offset, 14, "stop restores real list offset")
equal(second.offset, 9, "stop restores second real list offset")
equal(first.frame:IsShown() or second.frame:IsShown(), false, "stop restores disabled hidden state")
equal(next(meters.events.events), nil, "preview-only event handlers are removed on stop")
equal(first.header.OnUpdate, nil, "test leaves no drag update behind")
C_DamageMeter = nil
meters:SetPreview(true)
equal(first.rows[1].name.text, "Sample Warrior", "test also works when native meter API is absent")
SetCombat(true)
meters.events:OnEvent("PLAYER_REGEN_DISABLED")
equal(meters.preview, nil, "combat automatically ends test")
equal(first.frame:IsShown() or second.frame:IsShown(), false, "combat hides preview-only meters immediately")
local beforeTestCombat = created
meters:SetPreview(true)
equal(meters.preview, nil, "starting a test during combat is rejected")
equal(created, beforeTestCombat, "combat test attempt constructs no frames")
SetCombat(false)
if Suite.pending.meters then apply = Suite.pending.meters; Suite.pending.meters = nil; apply() end
Suite.db.damageMeters = true
Suite.db.meterWindows[1].shown, Suite.db.meterWindows[2].shown = true, false
C_DamageMeter = { IsDamageMeterAvailable = function() return true, "" end,
    GetAvailableCombatSessions = function() return histories end,
    GetCombatSessionFromType = function() return data end, GetCombatSessionFromID = function() return data end }
meters:Apply()
meters:SetPreview(true); meters:SetPreview(false)
equal(first.rows[1].name.text, "Player 15", "stop restores live rows and prior offset")
equal(first.session.fullLabel, "Current · Repeated fight", "stop restores the real historical session tooltip")
equal(first.frame:IsShown(), true, "stop keeps enabled visible meter")
equal(second.frame:IsShown(), false, "stop restores independently hidden live meter")
meters:SetPreview(true)
SetCombat(true); meters.events:OnEvent("PLAYER_REGEN_DISABLED")
equal(meters.preview, nil, "combat ends tests while real meters are enabled")
equal(first.rows[1].name.text, "Player 15", "combat exit from test immediately returns visible meter to live data")
equal(second.frame:IsShown(), false, "combat exit from test hides previously hidden meter")
equal(meters.events.events.DAMAGE_METER_COMBAT_SESSION_UPDATED, true, "live combat updates remain registered after test ends in combat")
sources[15].name = "Live during combat"
meters.events:OnEvent("DAMAGE_METER_COMBAT_SESSION_UPDATED"); Flush()
equal(first.rows[1].name.text, "Live during combat", "live data continues refreshing through combat after test")
sources[15].name = "Player 15"
SetCombat(false)
if Suite.pending.meters then apply = Suite.pending.meters; Suite.pending.meters = nil; apply() end
meters:SetPreview(true)
Suite.db.damageMeters = false; meters:Apply()
equal(meters.preview, nil, "disabling an enabled feature also ends its test")
equal(first.testOffset, nil, "disable clears transient preview scroll state")
equal(first.frame:IsShown() or second.frame:IsShown(), false, "disable hides test windows")

-- Corner sizing keeps the opposite top corner fixed and preserves every dock orientation.
meters:SetPreview(true); meters:Detach()
Suite.db.meterWindows[1].width, Suite.db.meterWindows[1].height = 300, 220
Suite.db.meterWindows[2].width, Suite.db.meterWindows[2].height = 280, 220
Suite.db.meterWindows[1].position, Suite.db.meterWindows[2].position = { x = 0.1, y = 0.375 }, { x = 0.6, y = 0.375 }
meters:Apply()
equal(first.metric.backdrop ~= nil, true, "metric selector uses the Suite button border")
equal(first.session.backdrop ~= nil, true, "session selector retains its distinct button border")
equal(first.metric.arrow.atlas, nil, "metric glyph has no native dropdown artwork or nested border")
equal(first.metric.width, 22, "metric input is confined to the left arrow")
equal(first.title, first.metric.label, "metric title is a passive header font string")
equal(first.title.textColor[1], 1, "native-style title uses warm gold")
equal(first.session.arrow.text, "v", "session arrow is always available")
equal(first.metric.OnDragStart, nil, "selector buttons cannot start a move")
equal(first.session.OnDragStart, nil, "session selector cannot start a move")
equal(first.frame.width - first.metric.width - first.session.width - 68 >= 28, true, "compact header reserves a distinct drag gap")
equal(first.grip.mouseEnabled, false, "passive grab dots leave header input available")
equal(#first.grip.dots, 6, "visible grab dots mark the move area")
first.metric:OnEnter()
equal(first.metric.borderColor[4], 1, "hover brightens the Suite selector border")
first.metric:OnLeave()
equal(first.metric.borderColor[4], 0.45, "selector border settles after hover")
local rightCorner, leftCorner = first.corners.RIGHT, first.corners.LEFT
equal(rightCorner.mouseEnabled and leftCorner.mouseEnabled, true, "both lower corners accept resize input")
equal(rightCorner:GetFrameLevel() > first.frame:GetFrameLevel(), true, "corner handles sit above the window content")
local startRect = Suite.Copy(meters.rects[1])
rightCorner:OnDragStart()
meterCursorX, meterCursorY = meterCursorX + 80, meterCursorY - 60
rightCorner:OnUpdate()
equal(first.frame.width, 380, "right corner changes width freely")
equal(first.frame.height, 280, "right corner changes height independently of width")
equal(meters.rects[1].x, startRect.x, "right resize retains top-left x")
equal(meters.rects[1].y + first.frame.height, startRect.y + startRect.height, "right resize retains top-left y")
equal(Suite.db.meterWindows[1].width, 300, "in-progress sizing does not overwrite saved width")
equal(Suite.db.meterWindows[1].position.y, 0.375, "in-progress sizing does not overwrite saved position")
equal(first.rows[8]:IsShown(), true, "growing a test meter fills newly visible rows")
rightCorner:OnMouseUp("LeftButton")
equal(Suite.db.meterWindows[1].width, 380, "release saves free width")
equal(Suite.db.meterWindows[1].height, 280, "release saves free height")
equal(rightCorner.OnUpdate, nil, "right corner has no idle updater after release")
local priorRight, priorTop = meters.rects[1].x + first.frame.width, meters.rects[1].y + first.frame.height
leftCorner:OnDragStart()
meterCursorX, meterCursorY = meterCursorX - 40, meterCursorY + 30
leftCorner:OnUpdate(); leftCorner:OnDragStop()
equal(first.frame.width, 420, "left corner expands toward the left")
equal(first.frame.height, 250, "left corner can shrink height while growing width")
equal(meters.rects[1].x + first.frame.width, priorRight, "left resize retains top-right x")
equal(meters.rects[1].y + first.frame.height, priorTop, "left resize retains top-right y")
equal(leftCorner.OnUpdate, nil, "left corner removes its updater on release")
rightCorner:OnDragStart()
meterCursorX, meterCursorY = meterCursorX - 1000, meterCursorY + 1000
rightCorner:OnUpdate(); rightCorner:OnDragStop()
equal(first.frame.width, 240, "corner shrink respects usable header minimum")
equal(first.frame.height, 120, "corner shrink respects minimum height")
rightCorner:OnDragStart()
meterCursorX, meterCursorY = meterCursorX + 2000, meterCursorY - 2000
rightCorner:OnUpdate(); rightCorner:OnDragStop()
equal(first.frame.width, 1000, "corner growth supports viewport width beyond old limit")
equal(first.frame.height, 800, "corner growth supports viewport height beyond old limit")
equal(meters.rects[1].x, 0, "large resized meter remains inside horizontal screen bounds")
equal(meters.rects[1].y, 0, "large resized meter remains inside vertical screen bounds")
equal(first.visibleRows > 20, true, "larger row pool supports taller meters")

for _, side in ipairs({ "LEFT", "RIGHT", "TOP", "BOTTOM" }) do
    for index = 1, 2 do
        Suite.db.meterWindows[1].width, Suite.db.meterWindows[1].height = 300, 180
        Suite.db.meterWindows[2].width, Suite.db.meterWindows[2].height = 280, 160
        Suite.db.meterWindows[1].position = { x = 0.4, y = 0.35 }
        Suite.db.meterDock = { anchor = 1, side = side }; meters:Apply()
        local partnerRect = Suite.Copy(meters.rects[3 - index])
        local corner = index == 1 and "RIGHT" or "LEFT"
        meters.windows[index].corners[corner]:OnDragStart()
        meterCursorX, meterCursorY = meterCursorX + (corner == "RIGHT" and 20 or -20), meterCursorY - 15
        meters:ResizeUpdate(); meters:EndResize()
        local anchor, child = meters.rects[1], meters.rects[2]
        if side == "LEFT" or side == "RIGHT" then
            equal(anchor.height, child.height, "corner resize preserves shared height on " .. side .. " member " .. index)
            equal(meters.rects[3 - index].width, partnerRect.width, "corner resize preserves independent partner width")
            equal(child.y, anchor.y, "side-resized pair retains vertical alignment")
            equal(side == "LEFT" and child.x + child.width + Suite.db.meterGap or anchor.x + anchor.width + Suite.db.meterGap,
                side == "LEFT" and anchor.x or child.x, "side resize retains exact join")
        else
            equal(anchor.width, child.width, "corner resize preserves shared width on " .. side .. " member " .. index)
            equal(meters.rects[3 - index].height, partnerRect.height, "corner resize preserves independent partner height")
            equal(child.x, anchor.x, "stack-resized pair retains horizontal alignment")
            equal(side == "BOTTOM" and child.y + child.height + Suite.db.meterGap or anchor.y + anchor.height + Suite.db.meterGap,
                side == "BOTTOM" and anchor.y or child.y, "stack resize retains exact join")
        end
        equal(Suite.db.meterDock.side, side, "corner sizing preserves dock orientation")
    end
end

meters:Detach()
local savedResizeWidth = Suite.db.meterWindows[1].width
rightCorner:OnDragStart(); meterCursorX = meterCursorX + 35; meters:ResizeUpdate()
SetCombat(true); meters.events:OnEvent("PLAYER_REGEN_DISABLED")
equal(meters.resizing, nil, "combat cancels an active corner resize")
equal(rightCorner.OnUpdate, nil, "combat removes corner update immediately")
equal(Suite.db.meterWindows[1].width, savedResizeWidth, "combat interruption retains last committed width")
meters:StartResize(1, "LEFT")
equal(meters.resizing, nil, "combat cannot start corner sizing")
SetCombat(false)
if Suite.pending.meterLayout then apply = Suite.pending.meterLayout; Suite.pending.meterLayout = nil; apply() end
if Suite.pending.meters then apply = Suite.pending.meters; Suite.pending.meters = nil; apply() end
meters:SetPreview(true)
equal(first.frame.width, savedResizeWidth, "cancelled corner dimensions restore after combat")
rightCorner:OnDragStart(); meterCursorX = meterCursorX + 25; meters:ResizeUpdate()
meters:SetOption(1, "fontSize", 12)
equal(meters.resizing, nil, "an option change safely cancels the active sizing gesture")
equal(first.frame.width, savedResizeWidth, "option changes discard uncommitted corner dimensions")
meters:StartResize(1, "LEFT"); meters:SetPreview(false)
equal(leftCorner.OnUpdate, nil, "stopping a test cancels corner sizing")
equal(meters.resizing, nil, "stopping test releases resize state")

-- Native slider callbacks also fire from SetValue; synchronization must not write settings recursively.
local oldControlSettings, oldControlGap = Suite.Copy(Suite.db.meterWindows), Suite.db.meterGap
Suite.GUI:OpenMeters(1); Flush()
local fields, buttons = Suite.GUI.meterFields, Suite.GUI.meterButtons
equal(fields.width.width, 64, "numeric entries are compact inline controls")
equal(fields.width.point[2], fields.height.point[2] - 264, "inline values share symmetrical column placement")
equal(fields.width.slider.point[3], fields.height.slider.point[3], "paired sliders align beneath their labels")
equal(fields.width.slider.low, 240, "width slider uses the supported minimum")
equal(fields.width.slider.high, 1600, "width slider uses expanded maximum")
equal(fields.opacity.slider.low, 20, "opacity slider uses percent units")
equal(fields.gap.slider.high, 16, "shared gap slider has its own bounds")
equal(fields.width.slider.valueStep, 1, "sliders allow single-unit adjustments")
equal(fields.width.slider.obeyStep, true, "native drag respects the adjustment step")
Suite.GUI:RefreshMeters()
equal(Suite.GUI.meterTimer, nil, "programmatic slider synchronization schedules no writes")
local untouchedSecondWidth = Suite.db.meterWindows[2].width
local beforeSliderWidth = Suite.db.meterWindows[1].width
fields.width.slider:SetValue(620); fields.width.slider:SetValue(621); fields.width.slider:SetValue(623)
equal(fields.width:GetText(), "623", "dragging updates the inline number immediately")
equal(Suite.db.meterWindows[1].width, beforeSliderWidth, "drag writes are coalesced instead of applying each intermediate value")
equal(#timers, 1, "slider motion shares one short update timer")
Flush()
equal(Suite.db.meterWindows[1].width, 623, "coalesced update applies latest slider value")
equal(Suite.db.meterWindows[2].width, untouchedSecondWidth, "independent width slider leaves other window unchanged")
equal(Suite.GUI.meterTimer, nil, "live slider timer ends after applying")
fields.width:SetFocus(); fields.width:SetText("488.5"); fields.width:OnEnterPressed()
equal(Suite.db.meterWindows[1].width, 488.5, "typed fractional dimensions remain available")
equal(fields.width:GetText(), "488.5", "inline input retains typed precision")
equal(fields.width.slider:GetValue(), 488.5, "typing synchronizes native slider without rounding away precision")
fields.opacity.slider:SetValue(75); fields.opacity.slider:OnMouseUp()
equal(Suite.db.meterWindows[1].opacity, 0.75, "percent slider converts to stored opacity")
fields.opacity:SetFocus(); fields.opacity:SetText("66.25"); fields.opacity:OnEnterPressed()
equal(Suite.db.meterWindows[1].opacity, 0.6625, "typed opacity keeps precise percentage")
equal(fields.opacity.slider:GetValue(), 66.25, "opacity slider synchronizes percent precision")
fields.width:SetFocus(); fields.width:SetText("19900"); fields.width:OnEnterPressed()
equal(Suite.db.meterWindows[1].width, 1600, "typed dimensions clamp to slider bounds")
fields.width:SetFocus(); fields.width:SetText("invalid"); fields.width:OnEnterPressed()
equal(fields.width:GetText(), "1600", "invalid input restores current number")
fields.width:SetFocus(); fields.width:SetText("700"); fields.width:OnEscapePressed()
equal(Suite.db.meterWindows[1].width, 1600, "Escape cancels uncommitted typed changes")
fields.gap:SetFocus(); fields.gap:SetText("-5"); fields.gap:OnEnterPressed()
equal(Suite.db.meterGap, 0, "typed gap clamps at zero")
fields.gap.slider:OnMouseWheel(1); fields.gap.slider:OnMouseUp()
equal(Suite.db.meterGap, 1, "mouse wheel provides precise single-unit changes")
fields.width:SetFocus(); fields.width:SetText("405"); buttons.window2:OnClick()
equal(Suite.db.meterWindows[1].width, 405, "tab switch commits active text to its original window")
equal(Suite.db.meterWindows[2].width, untouchedSecondWidth, "tab switch does not send old input to the newly selected window")
equal(fields.width:GetText(), string.format("%.0f", untouchedSecondWidth), "new tab shows its own width")
fields.height.slider:SetValue(360)
buttons.reset:OnClick(); Flush()
equal(Suite.db.meterWindows[2].height, 220, "reset wins over previously queued slider changes")
equal(Suite.GUI.meterTimer, nil, "actions leave no pending slider timer")
fields.fontSize.slider:SetValue(13)
fields.width:SetFocus(); fields.width:SetText("999")
Suite.GUI.meterPanel:OnHide()
equal(Suite.db.meterWindows[2].fontSize, 13, "closing settings commits pending slider changes")
equal(Suite.db.meterWindows[2].width, 300, "closing settings cancels unfinished text edits")
equal(Suite.GUI.meterTimer, nil, "closing settings cancels its short slider timer")
Suite.GUI:OpenMeters(1)
Suite.db.meterWindows[1].width, Suite.db.meterWindows[1].height = 300, 220
Suite.db.meterDock = {}; Suite.db.damageMeters = true; meters:Apply(); Suite.GUI:RefreshMeters()
local beforeCombatSlider = first.frame.width
SetCombat(true)
fields.width.slider:SetValue(440); Flush()
equal(Suite.db.meterWindows[1].width, 440, "slider changes retain the latest setting in combat")
equal(first.frame.width, beforeCombatSlider, "combat slider change defers gameplay window geometry")
SetCombat(false)
if Suite.pending.meters then apply = Suite.pending.meters; Suite.pending.meters = nil; apply() end
equal(first.frame.width, 440, "latest slider dimension applies after combat")
Suite.db.damageMeters = false
Suite.db.meterWindows, Suite.db.meterGap = oldControlSettings, oldControlGap
meters:Apply(); Suite.GUI:RefreshMeters(); Flush()

-- Lock both members together so moving/resizing a docked partner cannot move a locked window.
Suite.GUI:OpenMeters(1); meters:SetPreview(true); meters:Detach()
Suite.db.meterWindows[1].width, Suite.db.meterWindows[1].height = 300, 220
Suite.db.meterWindows[2].width, Suite.db.meterWindows[2].height = 300, 220
meters:Apply(); meters:ChooseMetric(1, "DamageDone")
equal(first.header.height, 23, "slim header occupies 24 units including the top border")
equal(first.metric.height, 22, "metric arrow fits the slim header with an even hit area")
equal(first.footer, nil, "compact meters have no separate footer")
equal(first.visibleRows, 8, "default size fits eight tightly stacked rows")
equal(first.rows[1].point[5] - first.rows[2].point[5], 22, "bars stack without inter-row gutters")
equal(first.rows[1].width, 296, "bars span the window with only a narrow inset")
equal(first.rows[1].rank.text, "1.", "native source order is visibly ranked")
equal(first.rows[8].rank.text, "8.", "last test player's rank remains visible")
equal(first.rows[1].name.fontFlags, "OUTLINE", "row text uses an outline for readability over colored bars")
equal(first.duration.text, "1:36", "readable fight time appears in the header")
equal(first.duration:IsShown(), true, "default width displays the header time")
meters:SetOption(1, "width", 240)
equal(first.duration:IsShown(), true, "compact session button leaves room for the time at minimum width")
equal(first.metric.fullLabel, "Damage · 1:36", "full metric and time remain available in the tooltip")
equal(first.frame.width - first.metric.width - first.session.width - 68 >= 28, true, "drag gap survives the minimum width")
meters:SetOption(1, "width", 300)
first.lock:OnClick()
equal(Suite.db.meterLocked, true, "header padlock locks both windows")
equal(first.corners.LEFT:IsShown() or first.corners.RIGHT:IsShown(), false, "first locked window hides both corner handles")
equal(second.corners.LEFT:IsShown() or second.corners.RIGHT:IsShown(), false, "second locked window hides both corner handles")
equal(first.grip.dots[1]:IsShown() or second.grip.dots[1]:IsShown(), false, "locked headers hide movement dots")
equal(first.testLabel:IsShown() and second.testLabel:IsShown(), true, "locking preserves the test labels")
equal(first.lock.shackleRight:IsShown() and second.lock.shackleRight:IsShown(), true, "both padlocks show the closed state")
equal(Suite.GUI.meterButtons.lock.label.text, "Windows: Locked", "settings follow the shared lock state")
equal(Suite.InitializeDB(Suite.Copy(Suite.db)).meterLocked, true, "saved lock survives database initialization")
local lockedRect = Suite.Copy(meters.rects[1])
meters:StartDrag(1); meters:StartDrag(2)
equal(meters.drag, nil, "locked headers cannot move either member")
meters:StartResize(1, "LEFT"); meters:StartResize(2, "RIGHT")
equal(meters.resizing, nil, "hidden handles cannot resize either locked member")
meters:Resize(1, 1)
equal(first.frame.width, lockedRect.width, "locked Ctrl-wheel leaves dimensions unchanged")
equal(first.frame.height, lockedRect.height, "locked Ctrl-wheel leaves height unchanged")
control = true; first.header:OnMouseUp("RightButton"); first.frame:OnMouseUp("RightButton"); control = false
equal(meters.rects[1].x, lockedRect.x, "locked background reset gesture leaves position unchanged")
equal(meters:SnapCandidate(1, testNear), nil, "locked windows do not offer snap candidates")
local beforeLockedMenus = #menus
first.metric:OnClick(); first.session:OnClick()
equal(#menus, beforeLockedMenus + 2, "metric and fight menus still open while locked")
meters:ChooseMetric(1, "Hps")
equal(first.rows[1].value.text, "7,900/s", "locked window can change displayed metric")
meters:SetOption(1, "height", 120); first.frame:OnMouseWheel(-1)
equal(first.offset > 0, true, "locked body still scrolls through players")
equal(first.rows[1].rank.text, "4.", "rank follows the visible source after scrolling")
equal(Suite.db.meterLocked, true, "deliberate settings changes do not clear the lock")
meters:OpenMenu(first, first.settings, "settings")
local lockAction = menus[#menus].children[#menus[#menus].children]
equal(lockAction.label, "Unlock both windows", "options menu offers the shared unlock action")
lockAction.callback()
equal(Suite.db.meterLocked, false, "options menu unlocks both members")
equal(first.corners.LEFT:IsShown() and second.corners.RIGHT:IsShown(), true, "unlock restores corners on both windows")
equal(first.grip:IsShown() and second.grip:IsShown(), true, "unlock restores the drag areas")
local dragStart = Suite.Copy(meters.rects[1])
meters:StartDrag(1); meterCursorX = meterCursorX + 35; meters:DragUpdate()
equal(meters.rects[1].x ~= dragStart.x, true, "unlocked window starts a real move")
Suite.GUI.meterButtons.lock:OnClick()
equal(meters.drag, nil, "locking during a move cancels the gesture")
equal(first.header.OnUpdate, nil, "locking removes the drag updater")
equal(meters.rects[1].x, dragStart.x, "locking discards unfinished position changes")
first.lock:OnClick()
local committedWidth = Suite.db.meterWindows[1].width
meters:StartResize(1, "RIGHT"); meterCursorX = meterCursorX + 40; meters:ResizeUpdate()
equal(first.frame.width > committedWidth, true, "unlocked corner starts a real resize")
second.lock:OnClick()
equal(meters.resizing, nil, "locking from the other header cancels resizing")
equal(first.corners.RIGHT.OnUpdate, nil, "locking removes the corner updater")
equal(first.frame.width, committedWidth, "locking restores the last committed size")
equal(Suite.db.meterWindows[1].width, committedWidth, "unfinished size never reaches saved settings")
meters:SetLocked(false); meters:SetPreview(false)
Suite.db.damageMeters = true; meters:Apply()
local beforeCombatLock = created
SetCombat(true); second.lock:OnClick()
equal(Suite.db.meterLocked, true, "lock control works during live combat")
equal(created, beforeCombatLock, "combat locking creates no widgets")
equal(first.corners.LEFT:IsShown() or second.corners.RIGHT:IsShown(), false, "combat locking immediately hides existing unprotected handles")
first.lock:OnClick()
equal(Suite.db.meterLocked, false, "combat unlock updates the shared preference")
meters:StartDrag(1)
equal(meters.drag, nil, "unlock does not permit movement during combat")
SetCombat(false)
Suite.db.damageMeters = false; Suite.db.meterWindows = oldControlSettings
meters:Apply(); Suite.GUI:RefreshMeters(); Flush()

-- Quick reset uses the native shared-session action; test mode never clears real fights.
local beforeResetSettings, beforeResetDock = Suite.Copy(Suite.db.meterWindows), Suite.Copy(Suite.db.meterDock)
local beforeResetHistory, beforeResetData = histories, data
Suite.db.damageMeters = true; Suite.db.meterLocked = true
Suite.db.meterWindows[1].shown, Suite.db.meterWindows[2].shown = true, true
histories = { { sessionID = 501, name = "Reset target", durationSeconds = 61 } }
meters:Apply(); meters:ChooseSession(1, "Overall"); meters:ChooseSession(2, "History", 501)
equal(first.session.label.text, "O", "Overall uses its compact initial")
equal(second.session.label.text, "C", "retained fight uses the compact Current initial")
equal(second.session.fullLabel, "Current · Reset target", "compact history button preserves full fight identity in its tooltip")
equal(first.session.width, 24, "session button is much narrower than the old text selector")
equal(first.reset.enabled, false, "reset button is disabled when native reset capability is absent")
meters:ResetData()
equal(second.fightID, 501, "unsupported reset leaves historical selection intact")
local resetCalls = 0
C_DamageMeter.ResetAllCombatSessions = function()
    resetCalls = resetCalls + 1
    histories = {}; data = { combatSources = {}, maxAmount = 0, durationSeconds = 0 }
    meters.events:OnEvent("DAMAGE_METER_RESET")
end
meters:Refresh(); first.offset, second.offset = 3, 9
local beforeResetRects, beforeResetStyles = Rects(), Suite.Copy(Suite.db.meterWindows)
equal(first.reset.enabled, true, "available native reset enables the compact header control")
equal(first.reset.fullLabel, "Reset all combat data", "reset tooltip makes its data scope explicit")
first.reset:OnClick()
equal(resetCalls, 1, "one header click invokes the native shared reset exactly once")
equal(first.fightID or second.fightID, nil, "reset clears historical IDs in both views")
equal(first.offset + second.offset, 0, "reset clears both list offsets")
equal(#meters.history, 0, "reset refreshes the empty native history index")
equal(first.empty.text, "Waiting for combat data", "reset removes old displayed rows immediately")
equal(first.rows[1]:IsShown() or second.rows[1]:IsShown(), false, "both meter bodies stop showing cleared combat sources")
equal(meters.timer, nil, "synchronous native reset event leaves no stale refresh timer")
equal(Suite.db.meterLocked, true, "data reset leaves the shared position lock intact")
equal(Suite.db.meterWindows[1].session, "Overall", "reset keeps the Overall preference")
equal(Suite.db.meterWindows[2].session, "Current", "historical reset returns to Current")
equal(first.session.label.text, "O", "Overall initial survives reset")
equal(second.session.label.text, "C", "Current initial survives reset")
equal(meters.rects[1].x, beforeResetRects[1].x, "data reset preserves first window position")
equal(meters.rects[2].y, beforeResetRects[2].y, "data reset preserves second window position")
equal(first.frame.width, beforeResetStyles[1].width, "data reset preserves the window size")
equal(Suite.db.meterWindows[1].metric, beforeResetStyles[1].metric, "data reset preserves the chosen metric")
histories = { { sessionID = 501, name = "Reset target", durationSeconds = 61 } }; data = beforeResetData
meters:ReadHistory(); meters:ChooseSession(2, "History", 501)
first.offset, second.offset = 12, 9
meters:SetOption(1, "height", 120); meters:SetOption(2, "height", 120); meters:SetPreview(true)
first.offset, second.offset = 3, 2; meters:Refresh()
equal(first.session.label.text, "O", "test display retains the compact Overall selector")
equal(first.testLabel:IsShown(), true, "compact test mode stays visibly marked while locked")
equal(first.reset.fullLabel, "Restart test display", "test reset clearly identifies its sample-only action")
second.reset:OnClick()
equal(resetCalls, 1, "test reset never invokes native combat reset")
equal(first.offset + second.offset, 0, "test reset rewinds both sample lists")
equal(second.fightID, 501, "test reset preserves the real historical fight")
equal(second.testOffset, 9, "test reset preserves the pre-test live scroll")
equal(first.rows[1].name.text, "Sample Warrior", "test reset immediately displays the first sample player")
meters:SetPreview(false)
equal(second.offset, 9, "stopping a reset test restores the live scroll")
equal(second.fightID, 501, "stopping a reset test restores the real historical view")
local beforeCombatReset = created
SetCombat(true); second.reset:OnClick()
equal(resetCalls, 2, "native reset remains usable from an existing header during combat")
equal(created, beforeCombatReset, "combat reset constructs no frames")
equal(second.fightID, nil, "combat reset reconciles a historical selection")
SetCombat(false)
C_DamageMeter.ResetAllCombatSessions = nil
histories, data = beforeResetHistory, beforeResetData
Suite.db.damageMeters, Suite.db.meterLocked = false, false
Suite.db.meterWindows, Suite.db.meterDock = beforeResetSettings, beforeResetDock
meters:Apply(); Suite.GUI:RefreshMeters(); Flush()

-- Bar clicks use native source identities and prebuilt widgets, including during combat.
local oldDetailSpellAPI, detailSettings, detailData, detailHistories = C_Spell, Suite.Copy(Suite.db.meterWindows), data, histories
local detailGUIDs = {}
for index, source in ipairs(sources) do detailGUIDs[index] = source.sourceGUID; source.sourceGUID = "Player-" .. index end
Suite.db.damageMeters, Suite.db.meterLocked = true, true
Suite.db.meterWindows[1].shown, Suite.db.meterWindows[2].shown = true, true
Suite.db.meterWindows[1].metric, Suite.db.meterWindows[1].session = "Dps", "Current"
Suite.db.meterWindows[2].metric, Suite.db.meterWindows[2].session = "HealingDone", "Current"
data = { combatSources = sources, maxAmount = 1000, durationSeconds = 61 }
histories = { { sessionID = 901, name = "Detail fight", durationSeconds = 61 } }
local spellData = { maxAmount = 900, totalAmount = 7000, combatSpells = {} }
for index = 1, 12 do
    spellData.combatSpells[index] = { spellID = 9000 + index, totalAmount = 950 - index * 50,
        amountPerSecond = 46 - index, combatSpellDetails = { unitName = "Target " .. index } }
end
local sourceTypeCalls, sourceIDCalls, spellRequests = {}, {}, {}
local secretSpellName, secretSpellIcon, unloadedSpell = Secret(), Secret(), nil
C_Spell = {
    GetSpellName = function(id)
        if issecretvalue(id) then return secretSpellName end
        return id ~= unloadedSpell and "Ability " .. id or nil
    end,
    GetSpellTexture = function(id)
        if issecretvalue(id) then return secretSpellIcon end
        return id ~= unloadedSpell and 40000 + id or nil
    end,
    RequestLoadSpellData = function(id)
        assert(not issecretvalue(id), "hidden spell IDs never become async request keys")
        spellRequests[id] = (spellRequests[id] or 0) + 1
    end,
}
local function QuerySource(callsList, sessionID, metric, guid, creature)
    assert(not issecretvalue(sessionID) and not issecretvalue(metric) and not issecretvalue(guid) and not issecretvalue(creature), "source queries accept only readable identities")
    callsList[#callsList + 1] = { sessionID, metric, guid, creature }
    return spellData
end
C_DamageMeter.GetCombatSessionSourceFromType = function(...) return QuerySource(sourceTypeCalls, ...) end
C_DamageMeter.GetCombatSessionSourceFromID = function(...) return QuerySource(sourceIDCalls, ...) end
meters:Apply()
local details = meters.details
equal(details.frame:GetName(), "WoWForeverSuiteCombatDetails", "details uses one named Escape-close compatibility frame")
equal(details.frame:IsShown(), false, "prebuilt popup starts hidden")
equal(details.frame.events and details.frame.events.GLOBAL_MOUSE_DOWN or false, false, "hidden popup does not listen for outside clicks")
equal(details.title.parent, details.frame, "source name sits inside the popup without a separate title strip")
equal(details.close.parent, details.frame, "close button sits inside the popup border")
equal(#details.rows, 8, "details rows are prebuilt outside combat")
equal(details.frame.height < 260, true, "compact breakdown has no tall empty report area")
equal(details.rows[1].name.fontPath, first.rows[1].name.fontPath, "breakdown and main bars share the native font family")
equal(details.rows[1].name.fontSize, 14, "breakdown rows use readable fourteen-point text")
equal(details.rows[1].bar.statusTexture.atlas, "UI-HUD-CoolDownManager-Bar", "breakdown uses native textured bars")
do
    local rect = meters.rects[1]
    meters.rects[1] = { x = 800, y = 700, width = 200, height = 100 }
    meters:PositionDetails(1)
    equal(details.frame.point[4], 376, "popup opens to the left when the right edge has no room")
    equal(details.frame.point[5] + details.frame.height <= UIParent.height, true, "popup stays within the vertical viewport")
    meters.rects[1] = rect; meters:PositionDetails(1)
end
equal(first.rows[1].objectType, "Button", "player bars accept click input")
first.rows[1]:OnEnter(); equal(first.rows[1].highlight:IsShown(), true, "bar hover indicates click interaction")
first.rows[1]:OnLeave(); equal(first.rows[1].highlight:IsShown(), false, "bar hover clears on leave")
local beforeCombatDetails = created
SetCombat(true); first.rows[1]:OnClick()
equal(created, beforeCombatDetails, "combat click creates no popup or rows")
equal(details.frame:IsShown(), true, "locked player bar opens its prebuilt popup in combat")
equal(details.frame.events.GLOBAL_MOUSE_DOWN, true, "visible popup listens for click-away dismissal")
do
    for _, focus in ipairs({ details.frame, details.rows[1], details.rows[1].bar, details.close }) do
        mouseFoci = { UIParent, focus }; details.frame:OnEvent("GLOBAL_MOUSE_DOWN", "LeftButton")
        equal(details.frame:IsShown(), true, "clicking popup content or descendants keeps the details open")
    end
    mouseFoci = Secret(); details.frame:OnEvent("GLOBAL_MOUSE_DOWN", "LeftButton")
    equal(details.frame:IsShown(), true, "restricted outer mouse focus is not traversed")
    mouseFoci = { Secret() }; details.frame:OnEvent("GLOBAL_MOUSE_DOWN", "LeftButton")
    equal(details.frame:IsShown(), true, "restricted mouse focus is not passed to ancestry lookup")
    local focusAPI, ancestryAPI = GetMouseFoci, DoesAncestryIncludeAny
    GetMouseFoci = nil; details.frame:OnEvent("GLOBAL_MOUSE_DOWN", "LeftButton")
    equal(details.frame:IsShown(), true, "missing focus capability leaves X and Escape dismissal available")
    GetMouseFoci, DoesAncestryIncludeAny = focusAPI, nil
    details.frame:OnEvent("GLOBAL_MOUSE_DOWN", "LeftButton")
    equal(details.frame:IsShown(), true, "missing native ancestry predicate does not break popup input")
    DoesAncestryIncludeAny = function() return Secret() end
    details.frame:OnEvent("GLOBAL_MOUSE_DOWN", "LeftButton")
    equal(details.frame:IsShown(), true, "restricted ancestry result is never used in a condition")
    DoesAncestryIncludeAny = ancestryAPI
    for _, foci in ipairs({ { UIParent }, {}, { first.rows[1] } }) do
        mouseFoci = foci; details.frame:OnEvent("GLOBAL_MOUSE_DOWN", "RightButton")
        equal(details.frame:IsShown(), false, "clicking another window or the world dismisses the popup in combat")
        equal(details.selection, nil, "click-away clears the captured source")
        equal(details.rows[1].icon.texture, nil, "click-away clears old spell icons")
        equal(details.frame.events.GLOBAL_MOUSE_DOWN, nil, "click-away stops the popup mouse listener")
        first.rows[1]:OnClick()
        equal(details.frame.events.GLOBAL_MOUSE_DOWN, true, "new player click restores click-away dismissal")
    end
    mouseFoci = {}
    equal(created, beforeCombatDetails, "click-away and reopening do not create combat frames")
end
equal(details.title.text, "Player 1", "popup title belongs to the clicked source")
equal(details.context.text, "DPS · Current", "popup captures the clicked metric and session")
equal(sourceTypeCalls[#sourceTypeCalls][1], 1, "Current details use the native Current endpoint")
equal(sourceTypeCalls[#sourceTypeCalls][2], Enum.DamageMeterType.Dps, "details query uses the selected metric")
equal(sourceTypeCalls[#sourceTypeCalls][3], "Player-1", "details identifies the source by GUID")
equal(details.total.text, "7,000", "popup displays exact grouped native source total")
equal(details.rows[1].name.text, "Ability 9001 (Target 1)", "popup combines the native spell and recipient on one row")
equal(details.rows[1].value.text, "45 (900) 13%", "DPS breakdown puts supplied rate first with total and readable share")
spellData.combatSpells[1].amountPerSecond = 13.5; meters:RefreshDetails()
equal(details.rows[1].value.text, "13.5 (900) 13%", "rate-first breakdown retains fractional DPS in its primary value")
spellData.combatSpells[1].amountPerSecond = 45; meters:RefreshDetails()
equal(details.rows[1].icon.texture, 49001, "popup resolves the native spell icon")
spellData.totalAmount = Secret(); meters:RefreshDetails()
equal(details.rows[1].value.text, "45 (900)", "restricted source total omits percentage without deriving hidden information")
spellData.totalAmount = 7000; meters:RefreshDetails()
details.frame:OnMouseWheel(-100)
equal(details.offset, 4, "long spell list scrolls to its last page")
equal(details.rows[8].name.text, "Ability 9012 (Target 12)", "scroll reaches the last native spell")
equal(details.footer.text, "5–12 of 12 · Scroll for more", "details identifies the visible spell range")
spellData.combatSpells[5].amountPerSecond = 123
meters.events:OnEvent("DAMAGE_METER_COMBAT_SESSION_UPDATED"); Flush()
equal(details.rows[1].value.text, "123 (700) 10%", "existing event refresh updates paired breakdown values")
meters.events:OnEvent("DAMAGE_METER_CURRENT_SESSION_UPDATED"); Flush()
equal(details.offset, 0, "new Current fight resets the breakdown scroll")
sources[1], sources[2] = sources[2], sources[1]; meters:Refresh()
equal(details.selection.guid, "Player-1", "source reorder does not retarget an open breakdown")
first.rows[1]:OnClick()
equal(details.selection.guid, "Player-2", "recycled visible bar clicks its current source")
sources[1], sources[2] = sources[2], sources[1]
details.close:OnClick()
equal(details.selection, nil, "closing clears runtime source selection")
equal(details.frame:IsShown(), false, "close button hides the popup during combat")
equal(details.frame.events.GLOBAL_MOUSE_DOWN, nil, "close button unregisters the outside-click listener")
SetCombat(false); meters:ChooseSession(2, "History", 901)
second.rows[1]:OnClick()
equal(sourceIDCalls[#sourceIDCalls][1], 901, "historical details query the captured fight ID")
equal(details.context.text, "Healing · Detail fight", "historical details display the retained fight name")
meters:ChooseMetric(1, "DamageDone")
equal(details.frame:IsShown(), true, "other window's metric choice leaves this breakdown intact")
meters:ChooseMetric(2, "Hps")
equal(details.frame:IsShown(), false, "owning window's metric change dismisses its old breakdown")
second.rows[1]:OnClick()
local savedIDQuery = C_DamageMeter.GetCombatSessionSourceFromID
C_DamageMeter.GetCombatSessionSourceFromID = nil
local oldTypeCount = #sourceTypeCalls
meters:RefreshDetails()
equal(details.message.text, "Detailed combat data is unavailable on this client.", "missing historical endpoint shows clear feedback")
equal(#sourceTypeCalls, oldTypeCount, "missing historical endpoint never falls back to the Current endpoint")
equal(details.rows[1]:IsShown(), false, "unavailable details clear stale spell rows")
equal(details.rows[1].icon.texture, nil, "unavailable details clear stale spell icons")
C_DamageMeter.GetCombatSessionSourceFromID = savedIDQuery
meters:ChooseSession(2, "Current"); first.offset = 9; meters:Refresh()
first.rows[1]:OnClick()
equal(details.selection.guid, "Player-10", "scrolling player list preserves clicked source identity")
first.rows[1]:OnMouseWheel(1)
equal(first.offset, 6, "clickable player bars retain body scrolling")
unloadedSpell = 9001; details.offset = 0; meters:RefreshDetails(); meters:RefreshDetails()
equal(details.rows[1].name.text, "Spell 9001 (Target 1)", "missing spell name shows a readable ID fallback")
equal(details.rows[1].icon.texture, "Interface\\Icons\\INV_Misc_QuestionMark", "missing spell icon replaces the previous icon with a fallback")
equal(spellRequests[9001], 1, "missing spell data is requested once per popup selection")
unloadedSpell = nil; meters.events:OnEvent("SPELL_DATA_LOAD_RESULT", 9001, true); Flush()
equal(details.rows[1].name.text, "Ability 9001 (Target 1)", "spell-data event replaces the fallback name")
local secretAmount, secretMaximum, secretRate, secretUnit = Secret(), Secret(), Secret(), Secret()
spellData.totalAmount, spellData.maxAmount = secretAmount, secretMaximum
spellData.combatSpells[1].totalAmount, spellData.combatSpells[1].amountPerSecond = secretAmount, secretRate
spellData.combatSpells[1].spellID, spellData.combatSpells[1].combatSpellDetails.unitName = Secret(), secretUnit
SetCombat(true); meters:RefreshDetails()
equal(details.rows[1].bar.high, secretMaximum, "hidden detail maximum passes directly to the native status bar")
equal(details.rows[1].bar.value, secretAmount, "hidden detail amount passes directly to the native status bar")
equal(details.rows[1].value.nativeArgs[1], secretAmount, "hidden amount uses only native paired formatting")
equal(details.rows[1].value.nativeArgs[2], secretRate, "hidden spell rate uses only native paired formatting")
equal(details.rows[1].value.nativeFormat, "%.0f (%.1f)", "restricted amounts omit percentage while preserving native rate precision")
equal(details.rows[1].name.nativeArgs[1], secretSpellName, "secret-accepting spell-name API feeds only native text")
equal(details.rows[1].name.nativeArgs[2], secretUnit, "hidden unit name feeds native formatted text directly")
equal(details.rows[1].icon.texture, secretSpellIcon, "hidden spell texture feeds the permitted native widget")
equal(details.total.nativeSecret, secretAmount, "hidden source total uses native formatting")
local hiddenSource = { sourceGUID = Secret(), name = Secret(), totalAmount = Secret(), amountPerSecond = Secret() }
local oldSources = data.combatSources
data.combatSources = { hiddenSource }; first.offset = 0; meters:Refresh()
local oldSourceQueryCount = #sourceTypeCalls
first.rows[1]:OnClick()
equal(#sourceTypeCalls, oldSourceQueryCount, "hidden source GUID is never sent to the untainted-only source query")
equal(details.message.text, "Spell details are restricted for this player. Click their bar again after combat.", "restricted source still opens a useful popup message")
equal(details.title.text, hiddenSource.name, "restricted source name is displayed without inspection")
equal(details.total.nativeSecret, hiddenSource.totalAmount, "restricted source popup retains its native total")
hiddenSource.sourceGUID = nil
meters:Refresh(); first.rows[1]:OnClick()
equal(details.message.text, "No player identifier is available for this selection.", "missing readable source identity is distinguished from combat restriction")
hiddenSource.sourceGUID, hiddenSource.sourceCreatureID = nil, 123
meters:Refresh(); first.rows[1]:OnClick()
equal(sourceTypeCalls[#sourceTypeCalls][3], nil, "creature-only source uses a nil GUID")
equal(sourceTypeCalls[#sourceTypeCalls][4], 123, "creature-only source uses its readable creature ID")
local oldSpellData = spellData; spellData = Secret(); meters:RefreshDetails()
equal(details.message.text, "Spell details are restricted during combat.", "restricted outer detail record is not traversed")
equal(details.rows[1]:IsShown(), false, "restricted detail record clears stale rows")
equal(created, beforeCombatDetails, "all combat detail operations use prebuilt widgets")
SetCombat(false); spellData = oldSpellData; data.combatSources = oldSources
meters:Refresh(); first.rows[1]:OnClick(); meters:SetOption(1, "shown", false)
equal(details.frame:IsShown(), false, "hiding the owner dismisses its popup")
meters:SetPreview(true); first.rows[1]:OnClick()
local beforeSampleQueries = #sourceTypeCalls + #sourceIDCalls
equal(details.context.text, "Damage · TEST", "sample breakdown stays explicitly marked")
equal(details.rows[1].name.text, "Primary ability (Sample unit)", "sample player has invented ability and unit details")
equal(details.rows[1].icon.texture, "Interface\\Icons\\Ability_MeleeDamage", "sample breakdown uses static native spell artwork")
equal(#sourceTypeCalls + #sourceIDCalls, beforeSampleQueries, "sample breakdown makes no native source reads")
meters:ResetData()
equal(details.frame:IsShown(), false, "sample reset dismisses its old breakdown")
first.rows[1]:OnClick(); meters:SetPreview(false)
equal(details.selection, nil, "ending preview discards the sample breakdown")
meters:SetOption(1, "shown", true); first.rows[1]:OnClick()
meters.events:OnEvent("DAMAGE_METER_RESET")
equal(details.frame:IsShown(), false, "native reset dismisses the breakdown immediately")
first.rows[1]:OnClick(); Suite.db.damageMeters = false; meters:Apply()
equal(details.frame:IsShown(), false, "disabling meters dismisses the breakdown")
equal(details.frame.events.GLOBAL_MOUSE_DOWN, nil, "disabling meters leaves no popup mouse listener")
equal(Suite.db.meterWindows[1].sourceGUID, nil, "source selection never enters saved preferences")
equal(Suite.db.meterDetails, nil, "no saved combat breakdown table is introduced")
for index, source in ipairs(sources) do source.sourceGUID = detailGUIDs[index] end
C_Spell = oldDetailSpellAPI
C_DamageMeter.GetCombatSessionSourceFromType, C_DamageMeter.GetCombatSessionSourceFromID = nil, nil
data, histories, Suite.db.meterWindows = detailData, detailHistories, detailSettings
Suite.db.damageMeters, Suite.db.meterLocked = false, false
meters:Apply(); Flush()

CreateFrame, C_Timer, Enum = oldCreate, oldTimer, oldEnum
C_DamageMeter, MenuUtil, IsAltKeyDown = oldAPI, oldMenu, oldAlt
GameTooltip, IsControlKeyDown = oldTooltip, oldControl
GetCursorPosition, RAID_CLASS_COLORS = oldCursor, oldClassColors
GetClassAtlas, CLASS_ICON_TCOORDS, NumberFontNormal = oldClassAtlas, oldClassCoords, oldNumberFont
GetMouseFoci, DoesAncestryIncludeAny = oldMouseFoci, oldAncestry
meters.OpenMenu = oldOpenMenu
SetCombat(false)
