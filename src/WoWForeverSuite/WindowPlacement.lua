local _, Suite = ...

local function Number(value)
    return Suite.IsReadable(value) and type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function Accessible(frame, visible)
    if not Suite.IsReadable(frame) or not frame then return false end
    for _, method in ipairs({ "IsForbidden", "IsProtected" }) do
        if frame[method] then
            local ok, value = pcall(frame[method], frame)
            if not ok or not Suite.IsReadable(value) or value ~= false then return false end
        end
    end
    if visible then
        local method = frame.IsVisible or frame.IsShown
        if not method then return false end
        local ok, shown = pcall(method, frame)
        if not ok or not Suite.IsReadable(shown) or shown ~= true then return false end
    end
    return true
end

-- Only callers owning the destination frame use this. Never move Blizzard panels.
-- Resolve geometry now and anchor to UIParent: opening a parent from its child cannot form a cycle.
function Suite.PlaceWindow(frame, owner)
    if InCombatLockdown() or not Accessible(frame) or not Accessible(owner, true) then return false end
    if frame == owner then return false end
    if not owner.GetRect or not owner.GetEffectiveScale or not frame.GetWidth or not frame.GetHeight
        or not frame.GetEffectiveScale then return false end
    local ok, left, bottom, width, height, sourceScale, targetScale, uiScale, screenWidth, screenHeight, w, h = pcall(function()
        local x, y, sw, sh = owner:GetRect()
        return x, y, sw, sh, owner:GetEffectiveScale(), frame:GetEffectiveScale(), UIParent:GetEffectiveScale(),
            UIParent:GetWidth(), UIParent:GetHeight(), frame:GetWidth(), frame:GetHeight()
    end)
    if not ok then return false end
    if not Number(left) or not Number(bottom) or not Number(width) or not Number(height)
        or not Number(sourceScale) or not Number(targetScale) or not Number(uiScale)
        or not Number(screenWidth) or not Number(screenHeight) or not Number(w) or not Number(h)
        or width <= 0 or height <= 0 or sourceScale <= 0 or targetScale <= 0 or uiScale <= 0
        or screenWidth <= 0 or screenHeight <= 0 or w <= 0 or h <= 0 then return false end
    local sourceRatio, ratio = sourceScale / uiScale, targetScale / uiScale
    left, bottom, width, height = left * sourceRatio, bottom * sourceRatio, width * sourceRatio, height * sourceRatio
    w, h = w * ratio, h * ratio
    local right, top, gap = left + width, bottom + height, 10
    local candidates = { { right + gap, top - h }, { left - gap - w, top - h },
        { left, bottom - gap - h }, { left, top + gap } }
    local best, overlap
    for _, point in ipairs(candidates) do
        local x = math.max(0, math.min(point[1], math.max(0, screenWidth - w)))
        local y = math.max(0, math.min(point[2], math.max(0, screenHeight - h)))
        if h > screenHeight then y = screenHeight - h end -- Keep an oversized window's header reachable.
        local area = math.max(0, math.min(x + w, right) - math.max(x, left))
            * math.max(0, math.min(y + h, top) - math.max(y, bottom))
        if not overlap or area < overlap then best, overlap = { x, y }, area end
        if area == 0 then break end
    end
    frame:ClearAllPoints()
    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", best[1] / ratio, best[2] / ratio)
    return true
end
