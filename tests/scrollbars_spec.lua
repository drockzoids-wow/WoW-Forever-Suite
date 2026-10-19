local Suite, equal, Frame, SetCombat = ...
local gui = Suite.GUI
local oldCursor, oldPending = GetCursorPosition, Suite.pending
local cursorY = 1000
GetCursorPosition = function() return 0, cursorY end
Suite.pending = {}
local function Near(a, b, label) equal(math.abs(a - b) < 0.00001, true, label .. " [actual=" .. tostring(a) .. ", expected=" .. tostring(b) .. "]") end
local function Fraction(bar) return bar.travel > 0 and bar.thumbTop / bar.travel or 0 end
local function Drag(scroll, fraction)
    local bar = scroll.suiteScrollBar
    cursorY = 1000
    bar.thumb.OnMouseDown(bar.thumb, "LeftButton")
    cursorY = cursorY - (fraction * scroll.suiteMaximum - scroll.suiteOffset) / scroll.suiteMaximum * bar.travel * bar:GetEffectiveScale()
    bar.OnUpdate()
    bar.thumb.OnMouseUp(bar.thumb, "LeftButton")
end
for _, pair in ipairs({ { "Settings", gui.scrollFrame }, { "Macro recipes", gui.macroListScroll },
    { "Macro preview", gui.macroPreview:GetParent() }, { "Setup review", gui.setupReview } }) do
    local name, scroll = pair[1], pair[2]
    local height, range, offset, shown = scroll:GetHeight(), scroll.suiteMaximum, scroll.suiteOffset, scroll:IsShown()
    local outer, bar = gui.scrollOffset, scroll.suiteScrollBar
    equal(bar:GetObjectType(), "Frame", name .. " uses a track without native Slider drag feedback")
    -- Isolate the gesture: these panes belong to different, mutually exclusive pages.
    local visible = scroll.IsVisible
    scroll.IsVisible = function(self) return self:IsShown() end
    scroll:Show(); scroll:SetHeight(200); scroll.OnScrollRangeChanged(scroll, 0, 800)
    for _, fraction in ipairs({ 0, 0.25, 0.5, 0.75, 1, 0.75, 0.5, 0.25, 0 }) do
        Drag(scroll, fraction)
        Near(scroll.verticalScroll, fraction * 800, name .. " actual cursor movement maps continuously in both directions")
        Near(scroll.suiteOffset, fraction * 800, name .. " logical offset agrees with viewport")
        Near(Fraction(bar), fraction, name .. " thumb agrees with visible content")
        equal(bar.OnUpdate, nil, name .. " release removes the gesture worker")
    end
    equal(bar.thumb.height, 40, name .. " thumb represents viewport fraction")
    Drag(scroll, 0.5); bar.OnMouseWheel(bar, -1)
    Near(scroll.verticalScroll, 440, name .. " wheel down moves content down")
    Near(Fraction(bar), 0.55, name .. " wheel down moves thumb down")
    bar.thumb.OnMouseWheel(bar.thumb, 1)
    Near(scroll.verticalScroll, 400, name .. " thumb wheel moves the same viewport")
    for _, invalid in ipairs({ { secret = true }, 0 / 0, math.huge, -math.huge, "0.5" }) do
        scroll.OnMouseWheel(scroll, invalid);scroll.OnScrollRangeChanged(scroll, 0, invalid)
        Near(scroll.verticalScroll, 400, name .. " invalid input does not move content")
    end
    Drag(scroll, 2);Near(scroll.verticalScroll, 800, name .. " drag below track clamps to end")
    Drag(scroll, -1);Near(scroll.verticalScroll, 0, name .. " drag above track clamps to start")
    -- The video shows long thumbs on short-overflow pages. Test every grab point at several UI scales.
    scroll.OnScrollRangeChanged(scroll, 0, 40)
    for _, scale in ipairs({ 0.75, 1, 1.5 }) do
        local oldScale = bar:GetScale();bar:SetScale(scale)
        for _, grab in ipairs({ 0.05, 0.5, 0.95 }) do
            Drag(scroll, 0.5)
            local before, top = scroll.suiteOffset, bar.thumbTop
            local _, bottom, _, barHeight = bar:GetRect()
            cursorY = (bottom + barHeight - top - bar.thumb.height * grab) * bar:GetEffectiveScale()
            bar.thumb.OnMouseDown(bar.thumb, "LeftButton")
            bar.OnUpdate()
            Near(scroll.suiteOffset, before, name .. " grabbing anywhere on long thumb never jumps")
            local drag = bar.drag
            gui:SyncScrollBar(scroll);gui:SyncScrollBar(scroll)
            equal(bar.drag, drag, name .. " synchronization preserves the original grab")
            cursorY = cursorY - bar:GetEffectiveScale()
            bar.OnUpdate()
            Near(bar.thumbTop, top + 1, name .. " one UI-unit pointer movement moves long thumb exactly one unit")
            Near(scroll.suiteOffset, before + 40 / bar.travel, name .. " small motion never snaps to endpoint")
            bar.OnEvent(bar, "GLOBAL_MOUSE_UP", "RightButton")
            equal(bar.drag ~= nil, true, name .. " unrelated mouse release does not end left drag")
            bar.OnEvent(bar, "GLOBAL_MOUSE_UP", "LeftButton")
            equal(bar.OnUpdate, nil, name .. " release outside thumb ends gesture")
        end
        bar:SetScale(oldScale)
    end
    Drag(scroll, 0.5)
    local _, bottom, _, barHeight = bar:GetRect()
    cursorY = (bottom + barHeight) * bar:GetEffectiveScale()
    bar.OnMouseDown(bar, "LeftButton")
    equal(scroll.suiteOffset, 0, name .. " clicking above thumb pages up without recentering it")
    cursorY = bottom * bar:GetEffectiveScale()
    bar.OnMouseDown(bar, "LeftButton")
    equal(scroll.suiteOffset, 40, name .. " clicking below thumb pages down")
    cursorY = 1000;bar.thumb.OnMouseDown(bar.thumb, "LeftButton")
    bar.OnMouseWheel(bar, 1)
    equal(bar.drag, nil, name .. " wheel cancels active grab")
    cursorY = 1000;bar.thumb.OnMouseDown(bar.thumb, "LeftButton")
    scroll.OnScrollRangeChanged(scroll, 0, 800)
    equal(bar.OnUpdate, nil, name .. " changing range cancels obsolete drag geometry")
    Drag(scroll, 1)
    local changed = scroll.OnVerticalScroll;scroll.OnVerticalScroll = nil
    scroll.OnScrollRangeChanged(scroll, 0, 100)
    equal(scroll.suiteOffset, 100, name .. " shrink synchronizes without follow-up native callback")
    equal(scroll.verticalScroll, 100, name .. " shrink clamps actual viewport")
    Near(Fraction(bar), 1, name .. " shrunk range ends at track bottom")
    scroll.OnScrollRangeChanged(scroll, 0, 400)
    Near(Fraction(bar), 0.25, name .. " growth retains pixel position")
    Near(bar.thumb.height, 200 / 3, name .. " growth updates proportional thumb size")
    scroll.OnScrollRangeChanged(scroll, 0, 0)
    equal(scroll.verticalScroll, 0, name .. " zero range resets native content")
    equal(Fraction(bar), 0, name .. " hidden thumb resets to top")
    equal(bar:IsShown(), false, name .. " short content hides track")
    scroll.OnVerticalScroll = changed
    scroll.OnScrollRangeChanged(scroll, 0, 400)
    cursorY = 1000;bar.thumb.OnMouseDown(bar.thumb, "LeftButton")
    bar.OnHide()
    equal(bar.OnUpdate, nil, name .. " hidden bar has no gesture worker")
    bar.thumb.OnMouseDown(bar.thumb, "LeftButton")
    scroll.OnSizeChanged()
    equal(bar.drag, nil, name .. " viewport resize cancels grab")
    bar.thumb.OnMouseDown(bar.thumb, "LeftButton")
    SetCombat(true);bar.OnEvent(bar, "PLAYER_REGEN_DISABLED")
    equal(bar.OnUpdate, nil, name .. " combat ends pointer tracking immediately")
    bar.thumb.OnMouseDown(bar.thumb, "LeftButton")
    equal(bar.drag, nil, name .. " combat cannot start anchored thumb motion")
    local thumbHeight, thumbTop = bar.thumb.height, bar.thumbTop
    scroll.OnScrollRangeChanged(scroll, 0, 800)
    scroll.OnMouseWheel(scroll, -1)
    equal(bar.thumb.height, thumbHeight, name .. " combat defers thumb size")
    equal(bar.thumbTop, thumbTop, name .. " combat defers thumb anchors")
    SetCombat(false);Suite.pending[scroll.suiteLayoutKey]()
    equal(Suite.pending[scroll.suiteLayoutKey], nil, name .. " geometry callback clears after settling")
    Near(bar.thumb.height, 40, name .. " deferred geometry uses latest range")
    Near(Fraction(bar), scroll.suiteOffset / 800, name .. " deferred geometry catches up to latest content")
    cursorY = { secret = true };bar.thumb.OnMouseDown(bar.thumb, "LeftButton")
    equal(bar.drag, nil, name .. " restricted cursor cannot start drag")
    cursorY = 1000;bar.thumb.OnMouseDown(bar.thumb, "LeftButton")
    cursorY = { secret = true };bar.OnUpdate()
    equal(bar.OnUpdate, nil, name .. " restricted cursor during drag cancels safely")
    local getScale = bar.GetEffectiveScale
    bar.GetEffectiveScale = function() return { secret = true } end
    cursorY = 1000;bar.thumb.OnMouseDown(bar.thumb, "LeftButton")
    equal(bar.drag, nil, name .. " restricted scale never enters pointer division")
    bar.GetEffectiveScale = getScale
    bar.thumb.OnMouseDown(bar.thumb, "RightButton")
    equal(bar.drag, nil, name .. " right click does not start a drag")
    if scroll ~= gui.scrollFrame then equal(gui.scrollOffset, outer, name .. " nested interaction leaves outer page still") end
    scroll:SetHeight(height);scroll.OnScrollRangeChanged(scroll, 0, range)
    if scroll == gui.scrollFrame then gui:ScrollTo(offset) else scroll:SetVerticalScroll(offset) end
    scroll:SetShown(shown)
    scroll.IsVisible = visible
end
GetCursorPosition, Suite.pending = oldCursor, oldPending
