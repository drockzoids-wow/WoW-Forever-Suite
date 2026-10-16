-- Combat movement and event-burst regressions. Native combat legality still
-- requires the client smoke test; these substitutes reject addon mutations.
local Suite, equal, Frame, SetCombat = ...
local windows = Suite.Windows
local oldDB, oldPending, oldCreate, oldTimers = Suite.db, Suite.pending, CreateFrame, C_Timer
local oldParent, oldPanels = UIParent, UIPanelWindows
local oldCharacter, oldBag, oldHidden = CharacterFrame, ContainerFrameCombinedBags, ContainerFrame2
local oldFirst, oldAnchors = ContainerFrame1, UpdateContainerFrameAnchors
local oldBagRecords, oldBagsHeld = windows.bagRecords, windows.bagsHeld
local oldNames, oldTracked, oldWatched, oldEvents = windows.names, windows.tracked, windows.watched, windows.events
local oldHeaderRects = windows.HeaderRects
windows:CancelTimer()
windows.names = { "CharacterFrame", "ContainerFrameCombinedBags", "ContainerFrame2" }
windows.tracked, windows.watched, windows.events = {}, {}, nil
windows.discoverPending = nil
windows.bagRecords, windows.bagsHeld = {}, nil
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
Suite.db.windowTools = true
UIParent = { GetEffectiveScale = function() return 1 end, GetWidth = function() return 1000 end, GetHeight = function() return 800 end }
UIPanelWindows = {}
local inCombat, native, constructed, scheduled, headerScans = false, false, 0, 0, 0
local timers = {}
local function Combat(value) inCombat = value; SetCombat(value) end
C_Timer = { NewTimer = function(_, callback)
    scheduled = scheduled + 1
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
local function ActiveTimers()
    local count = 0
    for _, timer in ipairs(timers) do if not timer.cancelled then count = count + 1 end end
    return count
end
local function Flush()
    for _ = 1, 8 do
        local current = timers; timers = {}
        for _, timer in ipairs(current) do if not timer.cancelled then timer.callback() end end
        if ActiveTimers() == 0 then return end
    end
    error("window work failed to settle")
end
local function LeaveCombat()
    Combat(false)
    local pending = Suite.pending; Suite.pending = {}
    for _, callback in pairs(pending) do callback() end
    Flush()
end
CreateFrame = function(kind, name, parent)
    assert(not inCombat, "window tools must not create frames in combat")
    constructed = constructed + 1
    local frame = Frame(name)
    frame.objectType, frame.parent, frame.registered = kind, parent, {}
    if parent and parent.children then parent.children[#parent.children + 1] = frame end
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    for _, method in ipairs({ "SetPoint", "ClearAllPoints", "SetScale", "SetSize", "SetFrameLevel", "SetFrameStrata",
        "SetMovable", "StartMoving", "StopMovingOrSizing", "SetShown", "Hide" }) do
        local original = frame[method]
        frame[method] = function(self, ...)
            local unprotectedGeometry = self.protected == false and (method == "StopMovingOrSizing"
                or method == "SetPoint" or method == "ClearAllPoints" or method == "SetScale")
            assert(not inCombat or native or unprotectedGeometry,
                "combat window mutation: " .. method)
            self.mutations = (self.mutations or 0) + 1
            return original(self, ...)
        end
    end
    frame.IsProtected = function(self) return self.protected ~= false end
    frame.IsForbidden = function(self) return self.forbidden == true end
    return frame
end
windows.HeaderRects = function(self, record)
    assert(not inCombat, "combat must not scan window headers")
    headerScans = headerScans + 1
    return oldHeaderRects(self, record)
end
local function Window(name, shown)
    local frame = CreateFrame("Frame", name)
    frame:SetSize(300, 200)
    frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -30, 30)
    frame.shown = shown
    return frame
end
CharacterFrame = Window("CharacterFrame", true)
ContainerFrameCombinedBags = Window("ContainerFrameCombinedBags", true)
ContainerFrame2 = Window("ContainerFrame2", false)
local bagPasses = 0
UpdateContainerFrameAnchors = function()
    bagPasses = bagPasses + 1
    local wasNative = native
    native = true
    for _, name in ipairs({ "ContainerFrameCombinedBags", "ContainerFrame1", "ContainerFrame2" }) do
        local frame = _G[name]
        if frame and frame.shown then
            frame:SetScale(0.8)
            frame:ClearAllPoints()
            frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -30, 30)
        end
    end
    native = wasNative
end
Suite.db.windowPositions.CharacterFrame = { x = 0.1, y = 0.1, scale = 1.2 }
Suite.db.windowPositions.ContainerFrameCombinedBags = { x = -0.1, y = 0.05, scale = 1 }
windows:Apply(); Flush()
local record = windows.tracked.CharacterFrame
equal(windows.events.registered.PLAYER_REGEN_DISABLED, true, "mover observes combat entry")
equal(windows.events.registered.PLAYER_REGEN_ENABLED, nil, "combat exit uses the core queue without duplicate discovery")
equal(ActiveTimers(), 0, "idle mover keeps no timer")
equal(record.handle.OnUpdate, nil, "native movement uses no addon per-frame polling")
-- The first render can occur before the shared next-frame worker runs.
local openingScans = headerScans
UpdateContainerFrameAnchors()
equal(ContainerFrameCombinedBags.point[1], "CENTER", "ordinary bag layout restores saved placement before any timer runs")
equal(ContainerFrameCombinedBags.scale, 1, "ordinary bag opening restores the saved scale in the same call")
equal(headerScans, openingScans, "immediate placement retains coalesced header work")
Flush()
local beforeScheduled, beforeScans = scheduled, headerScans
for _ = 1, 500 do
    CharacterFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -30, 30)
    ContainerFrameCombinedBags:SetScale(0.9)
    windows:QueueDiscovery()
end
equal(scheduled - beforeScheduled, 1, "one timer coalesces 500 native event bursts across windows")
equal(headerScans, beforeScans, "hook bursts defer header scans to their shared pass")
Flush()
equal(headerScans - beforeScans, 2, "one pass refreshes each visible tracked header once")
equal(CharacterFrame.point[1], "CENTER", "burst reflow restores the saved character anchor")
equal(ContainerFrameCombinedBags.scale, 1, "burst reflow restores the saved bag scale")
equal(ActiveTimers(), 0, "completed burst leaves no retry timer")

CharacterFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
local cancelled = windows.timer
local beforeCombatConstruction = constructed
Combat(true); windows.events.OnEvent(windows.events, "PLAYER_REGEN_DISABLED")
equal(cancelled.cancelled, true, "combat entry cancels an already queued layout timer")
beforeScheduled, beforeScans = scheduled, headerScans
native = true
for _ = 1, 500 do
    CharacterFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
    ContainerFrameCombinedBags:SetScale(0.8)
    windows:QueueDiscovery()
end
ContainerFrame2.shown = true; ContainerFrame2.OnShow(ContainerFrame2)
CharacterFrame.shown = false; CharacterFrame.OnHide(CharacterFrame)
native = false
Flush()
local pendingCount = 0
for _ in pairs(Suite.pending) do pendingCount = pendingCount + 1 end
equal(pendingCount, 1, "combat layout/discovery bursts keep one deferred callback")
equal(scheduled, beforeScheduled, "combat bursts create no timers")
equal(headerScans, beforeScans, "combat bursts perform no header scans")
equal(constructed, beforeCombatConstruction, "opening a previously hidden window creates no combat handles")
equal(windows.tracked.ContainerFrame2, nil, "first-show discovery waits for combat exit")
equal(Suite.db.windowPositions.CharacterFrame.x, 0.1, "native combat reflow cannot overwrite saved placement")
LeaveCombat()
equal(CharacterFrame.point[1], "CENTER", "native combat reflow is corrected after combat")
equal(CharacterFrame.point[4], 100 / 1.2, "combat recovery uses the last saved horizontal position")
equal(record.handle:IsShown(), false, "hidden headers reconcile after combat without protected hide calls")
equal(windows.tracked.ContainerFrame2 ~= nil, true, "a window first shown in combat is discovered afterward")
equal(next(Suite.pending), nil, "combat recovery consumes deferred window work")
equal(ActiveTimers(), 0, "combat recovery leaves no timer")

-- Model the actual manager's full pass, followed by its secure post-hook. Only
-- readably unprotected native bags can repair their geometry before rendering.
do
    ContainerFrameCombinedBags.protected, ContainerFrame2.protected = false, false
    Suite.db.windowPositions.ContainerFrameCombinedBags = { x = -0.1, y = 0.05, scale = 1.2 }
    Suite.db.windowPositions.ContainerFrame2 = { x = 0.1, y = 0.1, scale = 1.1 }
    windows:ApplyRecord(windows.tracked.ContainerFrameCombinedBags)
    windows:ApplyRecord(windows.tracked.ContainerFrame2)
    Flush()
    Combat(true); windows.events.OnEvent(windows.events, "PLAYER_REGEN_DISABLED")
    local beforeCreates, beforeTimers, beforeHeaders, beforePasses = constructed, scheduled, headerScans, bagPasses
    local inputWrites = windows.tracked.ContainerFrameCombinedBags.handle.mutations
    for _ = 1, 500 do UpdateContainerFrameAnchors() end
    equal(ContainerFrameCombinedBags.point[1], "CENTER", "unprotected combined bag stays at its saved anchor during combat")
    equal(ContainerFrameCombinedBags.point[4], -100 / 1.2, "combat restore preserves the combined bag's screen-relative position")
    equal(ContainerFrameCombinedBags.scale, 1.2, "combat bag reflow retains the saved scale immediately")
    equal(ContainerFrame2.point[4], 100 / 1.1, "individual bags independently retain their saved combat positions")
    equal(ContainerFrame2.scale, 1.1, "individual bag retains its independent combat scale")
    equal(Suite.db.windowPositions.ContainerFrameCombinedBags.x, -0.1, "combat repair does not rewrite saved positions")
    equal(constructed, beforeCreates, "combat bag repair constructs no frames")
    equal(scheduled, beforeTimers, "500 combat bag passes create no timers")
    equal(headerScans, beforeHeaders, "combat bag repair never scans headers")
    equal(bagPasses - beforePasses, 500, "post-hook repair never recursively runs the native manager")
    equal(windows.tracked.ContainerFrameCombinedBags.handle.mutations, inputWrites, "combat repair leaves header layout and input untouched")
    CharacterFrame.protected = false
    equal(windows:ApplySavedPosition(record, Suite.db.windowPositions.CharacterFrame), false,
        "unprotected non-bag windows still defer combat positioning")
    CharacterFrame.protected = true
    LeaveCombat()

    -- Saved bags can first appear in combat after reload, before tracking has
    -- ever created their movement controls or captured an original anchor.
    ContainerFrame1 = Window("ContainerFrame1", false)
    ContainerFrame1.protected = false
    windows.names[#windows.names + 1] = "ContainerFrame1"
    Suite.db.windowPositions.ContainerFrame1 = { x = 0.22, y = -0.1, scale = 1.15 }
    Combat(true); windows.events.OnEvent(windows.events, "PLAYER_REGEN_DISABLED")
    ContainerFrame1.shown = true
    beforeCreates, beforeHeaders = constructed, headerScans
    UpdateContainerFrameAnchors()
    equal(ContainerFrame1.point[1], "CENTER", "an untracked bag first opened in combat restores its saved placement")
    equal(ContainerFrame1.point[4], 220 / 1.15, "first combat open retains a persisted bag coordinate")
    equal(ContainerFrame1.scale, 1.15, "first combat open retains its persisted bag scale")
    equal(windows.tracked.ContainerFrame1, nil, "first combat open does not create a movement record with handles")
    equal(constructed, beforeCreates, "first combat open creates no addon UI")
    equal(headerScans, beforeHeaders, "first combat open performs no header scan")
    LeaveCombat()
    equal(windows.tracked.ContainerFrame1 ~= nil, true, "first combat bag gains normal controls after lockdown")
    Suite.db.windowPositions.ContainerFrame1 = nil
    Combat(true); windows.events.OnEvent(windows.events, "PLAYER_REGEN_DISABLED")
    UpdateContainerFrameAnchors()
    equal(ContainerFrame1.point[1], "BOTTOMRIGHT", "unsaved bags keep native combat layout")
    equal(ContainerFrame1.scale, 0.8, "unsaved bags keep native combat scale")
    LeaveCombat()

    ContainerFrame2.protected = true
    Combat(true); windows.events.OnEvent(windows.events, "PLAYER_REGEN_DISABLED")
    UpdateContainerFrameAnchors()
    equal(ContainerFrame2.point[1], "BOTTOMRIGHT", "a runtime-protected bag cannot be reanchored in combat")
    equal(ContainerFrameCombinedBags.point[1], "CENTER", "one protected bag does not prevent other safe bag restores")
    LeaveCombat()
    equal(ContainerFrame2.point[1], "CENTER", "a protected bag restores once combat ends")
    ContainerFrame2.protected = false
    local protection = ContainerFrame2.IsProtected
    ContainerFrame2.IsProtected = function() return { secret = true } end
    Combat(true); windows.events.OnEvent(windows.events, "PLAYER_REGEN_DISABLED")
    UpdateContainerFrameAnchors()
    equal(ContainerFrame2.point[1], "BOTTOMRIGHT", "secret bag protection fails closed without a combat mutation")
    LeaveCombat(); ContainerFrame2.IsProtected = protection
    ContainerFrame2.IsProtected = nil
    Combat(true); windows.events.OnEvent(windows.events, "PLAYER_REGEN_DISABLED")
    UpdateContainerFrameAnchors()
    equal(ContainerFrame2.point[1], "BOTTOMRIGHT", "missing bag protection capability fails closed")
    LeaveCombat(); ContainerFrame2.IsProtected = protection

    local getWidth, shown = ContainerFrame2.GetWidth, ContainerFrame2.IsShown
    ContainerFrame2.GetWidth = function() return { secret = true } end
    Combat(true); windows.events.OnEvent(windows.events, "PLAYER_REGEN_DISABLED")
    UpdateContainerFrameAnchors()
    equal(ContainerFrame2.point[1], "BOTTOMRIGHT", "restricted bag geometry cannot drive combat arithmetic")
    ContainerFrame2.GetWidth = getWidth
    ContainerFrame2.forbidden = true
    ContainerFrame2.IsShown = function() error("forbidden bag visibility must not be queried") end
    UpdateContainerFrameAnchors()
    equal(ContainerFrame2.point[1], "BOTTOMRIGHT", "forbidden bag receives no addon combat mutation")
    ContainerFrame2.forbidden = false; ContainerFrame2.IsShown = shown
    LeaveCombat()

    -- Disabling cannot use the narrow combat restore. The native manager owns
    -- the final default arrangement once protected cleanup is possible.
    Suite.db.windowPositions.ContainerFrame1 = { x = 0.22, y = -0.1, scale = 1.15 }
    Combat(true); windows.events.OnEvent(windows.events, "PLAYER_REGEN_DISABLED")
    UpdateContainerFrameAnchors()
    Suite.db.windowTools = false; windows:Apply()
    beforeTimers = scheduled
    UpdateContainerFrameAnchors()
    equal(ContainerFrameCombinedBags.point[1], "BOTTOMRIGHT", "disabled mover leaves native combat bag anchors alone")
    equal(ContainerFrameCombinedBags.scale, 0.8, "disabled mover leaves native combat bag scale alone")
    equal(scheduled, beforeTimers, "disabled bag post-hook creates no timer")
    LeaveCombat()
    equal(ContainerFrame1.point[1], "BOTTOMRIGHT", "disable rebuilds native defaults for a bag first restored in combat")
    equal(ContainerFrame1.scale, 0.8, "disable uses the current native bag scale")
    equal(ActiveTimers(), 0, "combat bag disable leaves no continuing work")
    Suite.db.windowTools = true; windows:Apply(); Flush()
end

CharacterFrame.shown = true; CharacterFrame.OnShow(CharacterFrame); Flush()
record.dragStart()
CharacterFrame.centerX, CharacterFrame.centerY = 850, 650
Combat(true); windows.events.OnEvent(windows.events, "PLAYER_REGEN_DISABLED")
record.dragStop()
equal(record.cancelDrag, true, "combat marks a protected drag for cancellation")
equal(CharacterFrame.moving, true, "protected movement cleanup waits for combat exit")
equal(Suite.db.windowPositions.CharacterFrame.x, 0.1, "combat interruption never commits an unfinished drag")
LeaveCombat()
equal(CharacterFrame.moving, false, "protected drag stops after combat")
equal(CharacterFrame:IsMovable(), false, "interrupted drag restores the native movable flag")
equal(CharacterFrame.point[4], 100 / 1.2, "interrupted drag restores the committed anchor")
equal(record.cancelDrag, nil, "completed cancellation clears its gesture state")
local committed = Suite.db.windowPositions.CharacterFrame
Suite.db.windowPositions.CharacterFrame = nil
record.dragStart()
Combat(true); windows.events.OnEvent(windows.events, "PLAYER_REGEN_DISABLED")
LeaveCombat()
equal(Suite.db.windowPositions.CharacterFrame, nil, "an interrupted first drag creates no saved layout")
equal(CharacterFrame.point[1], "BOTTOMRIGHT", "an interrupted first drag restores its original anchors")
Suite.db.windowPositions.CharacterFrame = committed; windows:ApplyRecord(record)

CharacterFrame.protected = false
record.dragStart()
Combat(true); windows.events.OnEvent(windows.events, "PLAYER_REGEN_DISABLED")
equal(CharacterFrame.moving, false, "unprotected windows stop following the cursor on combat entry")
equal(Suite.db.windowPositions.CharacterFrame.x, 0.1, "unprotected combat cancellation also preserves saved placement")
LeaveCombat()
CharacterFrame.protected = true
local oldProtection = CharacterFrame.IsProtected
CharacterFrame.IsProtected = function() return { secret = true } end
record.dragStart()
Combat(true); windows.events.OnEvent(windows.events, "PLAYER_REGEN_DISABLED")
equal(CharacterFrame.moving, true, "an unreadable protection predicate defers movement cleanup")
LeaveCombat()
equal(CharacterFrame.moving, false, "unknown protection can safely clean up after combat")
CharacterFrame.IsProtected = oldProtection

-- A hide before drag release must also discard the unfinished placement.
record.dragStart(); CharacterFrame.shown = false; CharacterFrame.OnHide(CharacterFrame)
Flush()
equal(CharacterFrame.moving, false, "hiding an actively dragged window stops its movement")
equal(Suite.db.windowPositions.CharacterFrame.x, 0.1, "hide interruption preserves the previous saved layout")
CharacterFrame.shown = true; CharacterFrame.OnShow(CharacterFrame); Flush()
CharacterFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
cancelled = windows.timer
Combat(true); windows.events.OnEvent(windows.events, "PLAYER_REGEN_DISABLED")
Suite.db.windowTools = false; windows:Apply()
equal(cancelled.cancelled, true, "disable retains cancellation of the precombat timer")
equal(next(windows.events.registered), nil, "disable removes mover event registrations immediately")
beforeScheduled = scheduled
native = true
for _ = 1, 100 do CharacterFrame:SetScale(1); windows:QueueDiscovery() end
native = false
equal(scheduled, beforeScheduled, "disabled retained hooks create no timers")
LeaveCombat()
equal(CharacterFrame.point[1], "BOTTOMRIGHT", "combat disable restores the original native anchor afterward")
equal(CharacterFrame.scale, 1, "combat disable restores original scale")
equal(record.handle:IsShown(), false, "combat disable hides movement input afterward")
equal(ActiveTimers(), 0, "disabled mover leaves no timers")
equal(next(Suite.pending), nil, "disabled mover leaves no deferred callbacks")

Suite.db.windowTools = true; windows:Apply(); Flush()
record.dragStart(); CharacterFrame.forbidden = true
Combat(true); windows.events.OnEvent(windows.events, "PLAYER_REGEN_DISABLED")
LeaveCombat()
equal(ActiveTimers(), 0, "a newly forbidden drag target does not cause a retry loop")
equal(record.dragging, nil, "forbidden targets discard addon gesture bookkeeping")
CharacterFrame.forbidden = false
equal(windows:CapturePosition({ GetCenter = function() return { secret = true }, 1 end,
    GetEffectiveScale = function() return 1 end, GetScale = function() return 1 end }), nil,
    "restricted geometry cannot enter saved window positions")

-- First/late bag openings must settle before rendering, while preserving native resets.
do
    windows:CancelTimer()
    local priorNames, priorTracked, priorWatched = windows.names, windows.tracked, windows.watched
    local priorCombined, priorIndividual = ContainerFrameCombinedBags, ContainerFrame1
    local priorHidden, priorPositions = ContainerFrame2.shown, Suite.db.windowPositions
    windows.names, windows.tracked, windows.watched = { "ContainerFrameCombinedBags", "ContainerFrame1" }, {}, {}
    ContainerFrameCombinedBags, ContainerFrame1 = Window("ContainerFrameCombinedBags", false), nil
    ContainerFrame2.shown = false
    Suite.db.windowPositions = {
        ContainerFrameCombinedBags = { x = -0.12, y = 0.05, scale = 1.2 },
        ContainerFrame1 = { x = 0.18, y = 0.1, scale = 1.1 },
    }
    windows:Apply(); Flush()
    equal(windows.tracked.ContainerFrameCombinedBags, nil, "hidden saved bag waits for its native opening layout")
    ContainerFrameCombinedBags:Show(); ContainerFrameCombinedBags:OnShow()
    -- A numbered container may also be created after startup discovery.
    ContainerFrame1 = Window("ContainerFrame1", true)
    UpdateContainerFrameAnchors()
    equal(ContainerFrameCombinedBags.point[1], "CENTER", "first combined opening restores before discovery timers")
    equal(ContainerFrameCombinedBags.point[4], -120 / 1.2, "first combined opening uses its saved horizontal position immediately")
    equal(ContainerFrameCombinedBags.scale, 1.2, "first combined opening uses its saved scale immediately")
    equal(ContainerFrame1.point[1], "CENTER", "late numbered bag opening restores in the native layout call")
    equal(ContainerFrame1.scale, 1.1, "late numbered bag retains its independent saved scale")
    local combinedRecord = windows.tracked.ContainerFrameCombinedBags
    equal(combinedRecord.originalPoints[1][1], "BOTTOMRIGHT", "first bag placement preserves native reset anchors")
    equal(combinedRecord.originalScale, 0.8, "first bag placement preserves the native manager scale for reset")
    Flush()
    local normalScans, normalCreates = headerScans, constructed
    for _ = 1, 100 do UpdateContainerFrameAnchors() end
    equal(ContainerFrameCombinedBags.point[1], "CENTER", "repeat ordinary layout passes settle before rendering")
    equal(ContainerFrame1.point[1], "CENTER", "repeat layout independently restores numbered bags")
    equal(headerScans, normalScans, "ordinary bag layout bursts keep header scans deferred")
    equal(constructed, normalCreates, "ordinary bag layout bursts construct no additional controls")
    equal(ActiveTimers(), 1, "ordinary bag layout bursts coalesce later header work")
    Flush()
    windows:Reset(combinedRecord); Flush()
    equal(ContainerFrameCombinedBags.point[1], "BOTTOMRIGHT", "bag reset returns to native anchors rather than first saved placement")
    equal(ContainerFrameCombinedBags.scale, 0.8, "bag reset returns to the current native manager scale")
    Suite.db.windowTools = false; windows:Apply(); Flush()
    UpdateContainerFrameAnchors()
    equal(ContainerFrame1.point[1], "BOTTOMRIGHT", "disabled immediate placement yields numbered bags to native layout")
    equal(ActiveTimers(), 0, "disabled ordinary bag opening leaves no worker")
    windows:CancelTimer()
    windows.names, windows.tracked, windows.watched = priorNames, priorTracked, priorWatched
    ContainerFrameCombinedBags, ContainerFrame1, ContainerFrame2.shown = priorCombined, priorIndividual, priorHidden
    Suite.db.windowPositions, Suite.db.windowTools = priorPositions, true
end

-- Simulate a render opportunity immediately after native bank opening, before timers.
local oldBank, oldView, oldShow = BankFrame, WoWForeverSuiteBankView, ShowUIPanel
local oldBankViewFrame = Suite.OfflineBank.frame
windows:CancelTimer()
windows.names, windows.tracked, windows.watched, windows.events = { "BankFrame" }, {}, {}, nil
BankFrame = Window("BankFrame", false)
BankFrame:SetSize(480, 460)
WoWForeverSuiteBankView = Window("WoWForeverSuiteBankView", false)
Suite.OfflineBank.frame = WoWForeverSuiteBankView
Suite.db.windowPositions.BankFrame = { x = 0.18, y = -0.12, scale = 1.2 }
Suite.db.windowPositions.WoWForeverSuiteBankView = { x = -0.1, y = 0.05, scale = 1 }
ShowUIPanel = function(frame)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -116)
    frame:Show()
    if frame.OnShow then frame.OnShow(frame) end
    -- Native bank refresh/reflow can position the frame again during the same opening.
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -116)
end
windows:Apply(); Flush()
equal(windows.tracked.BankFrame, nil, "hidden native bank waits for opening")
ShowUIPanel(BankFrame)
equal(BankFrame.point[1], "CENTER", "first bank opening restores its position before the next render")
equal(BankFrame.point[4], 150, "first bank opening restores saved horizontal offset immediately")
equal(BankFrame.point[5], -80, "first bank opening restores saved vertical offset immediately")
equal(BankFrame.scale, 1.2, "first bank opening restores saved scale immediately")
local bankRecord = windows.tracked.BankFrame
equal(bankRecord.originalPoints[1][1], "TOPLEFT", "immediate first-open placement preserves native reset anchor")
equal(bankRecord.originalPoints[1][4], 16, "immediate first-open placement preserves native reset offset")
Flush()
local beforeBankHeaders = headerScans
for _ = 1, 100 do BankFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -116) end
equal(BankFrame.point[1], "CENTER", "later native bank reflows restore saved position in the same call")
equal(headerScans, beforeBankHeaders, "immediate bank position holding leaves header scans coalesced")
equal(ActiveTimers(), 1, "bank reflow bursts share one header refresh")
Flush()
equal(ActiveTimers(), 0, "bank reflows leave no idle timer or recursive hook loop")
BankFrame:Hide(); BankFrame.OnHide(BankFrame)
ShowUIPanel(BankFrame)
equal(BankFrame.point[1], "CENTER", "repeat bank opening does not wait for scheduled work")
WoWForeverSuiteBankView:Show(); WoWForeverSuiteBankView.OnShow(WoWForeverSuiteBankView)
equal(WoWForeverSuiteBankView.point[1], "CENTER", "saved bank viewer also opens at its saved position before timers")
equal(WoWForeverSuiteBankView.point[4], -100, "saved viewer keeps its separately chosen placement")
Flush()

bankRecord.dragging = true
BankFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 50, -50)
equal(BankFrame.point[4], 50, "immediate bank positioning does not fight an active drag")
bankRecord.dragging = nil
BankFrame.forbidden = true
BankFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 60, -60)
equal(BankFrame.point[4], 60, "immediate bank positioning skips forbidden frames")
BankFrame.forbidden = false
local bankSaved = Suite.db.windowPositions.BankFrame
Suite.db.windowPositions.BankFrame = { x = { secret = true }, y = 0, scale = 1 }
BankFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 70, -70)
equal(BankFrame.point[4], 70, "immediate bank positioning rejects restricted saved coordinates")
Suite.db.windowPositions.BankFrame = bankSaved
Flush()
Combat(true)
native = true
local beforeCombatBank = BankFrame.mutations
BankFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 80, -80)
native = false
equal(BankFrame.mutations, beforeCombatBank + 1, "native bank reflow in combat causes no addon geometry writes")
equal(BankFrame.point[4], 80, "combat leaves native positioning untouched until exit")
LeaveCombat()
equal(BankFrame.point[1], "CENTER", "saved bank placement resumes after combat")
windows:Reset(bankRecord)
equal(Suite.db.windowPositions.BankFrame, nil, "bank reset removes saved placement before synchronous hooks run")
equal(BankFrame.point[1], "TOPLEFT", "bank reset restores original native anchor")
equal(BankFrame.point[4], 16, "bank reset restores original native offset")
ShowUIPanel(BankFrame)
equal(BankFrame.point[1], "TOPLEFT", "unsaved native bank keeps its default position")
Suite.db.windowPositions.BankFrame = bankSaved

-- A load-on-demand BankFrame might not exist during discovery at startup.
windows.tracked.BankFrame = nil
BankFrame = Window("BankFrame", false)
ShowUIPanel(BankFrame)
equal(BankFrame.point[1], "CENTER", "late-created native bank restores placement before discovery timer")
equal(windows.tracked.BankFrame.frame, BankFrame, "late bank opening discovers its actual frame synchronously")
Suite.db.windowTools = false; windows:Apply(); Flush()
ShowUIPanel(BankFrame)
equal(BankFrame.point[1], "TOPLEFT", "disabled bank hooks leave native opening alone")
equal(ActiveTimers(), 0, "disabled bank opening creates no timers")
BankFrame, WoWForeverSuiteBankView, ShowUIPanel = oldBank, oldView, oldShow
Suite.OfflineBank.frame = oldBankViewFrame

-- Saved native panels must settle before rendering, after the whole panel pass.
local oldDelegate = FramePositionDelegate
local auditCharacter, auditPanels = CharacterFrame, UIPanelWindows
windows:CancelTimer()
windows.names, windows.tracked, windows.watched, windows.events = { "CharacterFrame" }, {}, {}, nil
Suite.db.windowTools = true
CharacterFrame = Window("CharacterFrame", false)
Suite.db.windowPositions.CharacterFrame = { x = 0.1, y = 0.1, scale = 1.2 }
local latePanel = Window("ForeverAuditNativePanel", false)
_G.ForeverAuditNativePanel = nil -- Load-on-demand frame is absent during startup discovery.
UIPanelWindows = { ForeverAuditNativePanel = {} }
Suite.db.windowPositions.ForeverAuditNativePanel = { x = -0.15, y = 0.1, scale = 1 }
local nativeScale
FramePositionDelegate = { UpdateUIPanelPositions = function(self, frame)
    self.updatingPanels = true
    frame:SetScale(0.8)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -116)
    nativeScale = frame:GetScale()
    self.updatingPanels = nil
end }
ShowUIPanel = function(frame)
    FramePositionDelegate:UpdateUIPanelPositions(frame)
    frame:Show()
    if frame.OnShow then frame.OnShow(frame) end
    FramePositionDelegate:UpdateUIPanelPositions(frame)
end
windows:Apply(); Flush()
ShowUIPanel(CharacterFrame)
equal(CharacterFrame.point[1], "CENTER", "saved character window opens before the first timer")
equal(CharacterFrame.scale, 1.2, "saved character scale settles before rendering")
equal(nativeScale, 0.8, "saved restoration waits until the full native panel pass finishes")
local auditRecord = windows.tracked.CharacterFrame
equal(auditRecord.originalPoints[1][1], "TOPLEFT", "first panel opening preserves native reset anchors")
equal(auditRecord.originalScale, 0.8, "first panel opening preserves native reset scale")
Flush()
local auditScans = headerScans
for _ = 1, 100 do FramePositionDelegate:UpdateUIPanelPositions(CharacterFrame) end
equal(CharacterFrame.point[1], "CENTER", "complete native panel reflows settle without a later snap")
equal(nativeScale, 0.8, "repeated panel passes retain native internal scaling")
equal(headerScans, auditScans, "immediate panel placement keeps header scans coalesced")
equal(ActiveTimers(), 1, "native panel bursts share one later header worker")
Flush()
_G.ForeverAuditNativePanel = latePanel
ShowUIPanel(latePanel)
equal(latePanel.point[1], "CENTER", "registered native panels also settle on their first opening")
equal(latePanel.point[4], -150, "registered panel uses its own saved position")
equal(windows.tracked.ForeverAuditNativePanel.originalScale, 0.8, "late panel preserves native reset scale")
local unsupported = Window("ForeverAuditUnsupported", false)
Suite.db.windowPositions.ForeverAuditUnsupported = { x = 0.2, y = 0.2, scale = 1.2 }
ShowUIPanel(unsupported)
equal(unsupported.point[1], "TOPLEFT", "unregistered unsupported windows keep native placement")
equal(windows.tracked.ForeverAuditUnsupported, nil, "synchronous opening does not expand window support")
Suite.db.windowPositions.ForeverAuditUnsupported = nil
auditRecord.dragging = true
CharacterFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 50, -50)
equal(CharacterFrame.point[4], 50, "synchronous panel placement preserves active drags")
auditRecord.dragging = nil
Combat(true); native = true
FramePositionDelegate:UpdateUIPanelPositions(CharacterFrame)
native = false
equal(CharacterFrame.point[1], "TOPLEFT", "native panel positioning is left alone in combat")
LeaveCombat()
equal(CharacterFrame.point[1], "CENTER", "panel placement recovers after combat")
windows:Reset(auditRecord)
equal(CharacterFrame.point[1], "TOPLEFT", "panel reset restores the captured native anchor")
equal(CharacterFrame.scale, 0.8, "panel reset restores the captured native scale")
Suite.db.windowTools = false; windows:Apply(); Flush()
ShowUIPanel(latePanel)
equal(latePanel.point[1], "TOPLEFT", "disabled panel hooks retain native placement")
equal(ActiveTimers(), 0, "disabled panel hooks leave no idle worker")
CharacterFrame, UIPanelWindows, FramePositionDelegate, ShowUIPanel = auditCharacter, auditPanels, oldDelegate, oldShow
_G.ForeverAuditNativePanel = nil
Suite.db.windowPositions.ForeverAuditNativePanel = nil

-- Clock settings and the compact stopwatch are separate load-on-demand frames.
local listed = {}; for _, name in ipairs(oldNames) do listed[name] = true end
equal(listed.TimeManagerFrame, true, "window catalog includes clock settings")
equal(listed.StopwatchFrame, true, "window catalog includes the compact stopwatch")
local oldClock, oldStopwatch, oldControl = TimeManagerFrame, StopwatchFrame, IsControlKeyDown
local control = false
IsControlKeyDown = function() return control end
windows.names = { "TimeManagerFrame", "StopwatchFrame" }
windows.tracked, windows.watched = {}, {}
TimeManagerFrame, StopwatchFrame = nil, nil
Suite.db.windowTools = true; windows:Apply(); Flush()
equal(windows.tracked.StopwatchFrame, nil, "unloaded stopwatch waits for native creation")
TimeManagerFrame, StopwatchFrame = Window("TimeManagerFrame", false), Window("StopwatchFrame", false)
TimeManagerFrame:SetSize(220, 240)
StopwatchFrame:SetSize(132, 44); StopwatchFrame.rect = { 100, 100, 132, 44 }
StopwatchFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -250, -300)
StopwatchFrame:SetMovable(true); StopwatchFrame.protected = false
local starts, stops, clicks = 0, 0, 0
StopwatchFrame:SetScript("OnDragStart", function(frame) starts = starts + 1; frame:StartMoving() end)
StopwatchFrame:SetScript("OnDragStop", function(frame) stops = stops + 1; frame:StopMovingOrSizing() end)
local function StopwatchChild(kind, parent, x, y, width, height)
    local child = CreateFrame(kind, nil, parent)
    child:SetSize(width, height); child.rect = { 100 + x, 144 + y, width, height }; child.shown = true
    return child
end
local tab = StopwatchChild("Frame", StopwatchFrame, 3, -16, 126, 16)
tab:SetFrameLevel(510)
local close = StopwatchChild("Button", tab, 110, -19, 20, 20)
local reset = StopwatchChild("Button", StopwatchFrame, 106, -41, 24, 24)
local play = StopwatchChild("Button", StopwatchFrame, 87, -41, 24, 24)
local nativeClick = function() clicks = clicks + 1 end
close:SetScript("OnClick", nativeClick); reset:SetScript("OnClick", nativeClick); play:SetScript("OnClick", nativeClick)
Suite.db.windowPositions.StopwatchFrame = { x = -0.1, y = 0.1, scale = 1 }
Suite.db.windowPositions.TimeManagerFrame = { x = 0.1, y = -0.1, scale = 1.1 }
windows.events.OnEvent(windows.events, "ADDON_LOADED", "Blizzard_TimeManager")
equal(windows.watched[StopwatchFrame], true, "late-loaded hidden stopwatch is watched before discovery timers")
equal(windows.watched[TimeManagerFrame], true, "late-loaded clock panel is watched before discovery timers")
StopwatchFrame.shown = true; StopwatchFrame.OnShow(StopwatchFrame)
equal(StopwatchFrame.point[1], "CENTER", "saved stopwatch placement is applied during its opening call")
equal(StopwatchFrame.point[4], -100, "stopwatch restores its own horizontal position")
TimeManagerFrame.shown = true; TimeManagerFrame.OnShow(TimeManagerFrame); Flush()
equal(TimeManagerFrame.scale, 1.1, "clock settings restores its own saved scale")
local watchRecord = windows.tracked.StopwatchFrame
local function InHeader(x, y)
    for _, rect in ipairs(watchRecord.headerRects) do
        if x >= rect.left and x <= rect.right and y >= rect.bottom and y <= rect.top then return true end
    end
    return false
end
equal(InHeader(30, -8), true, "stopwatch title is available for dragging")
equal(InHeader(117, -7), false, "stopwatch close button is excluded")
equal(InHeader(95, -25), false, "stopwatch play/pause control is outside the drag region")
equal(InHeader(118, -25), false, "stopwatch reset control is outside the drag region")
equal(InHeader(30, -25), false, "stopwatch timer digits are outside the drag region")
equal(InHeader(30, 3), false, "stopwatch adds no separate drag bar")
equal(watchRecord.handle:GetFrameLevel() > tab:GetFrameLevel(), true, "drag input clears the passive native title layer")
equal(close.OnClick, nativeClick, "stopwatch close callback is preserved")
equal(reset.OnClick, nativeClick, "stopwatch reset callback is preserved")
equal(play.OnClick, nativeClick, "stopwatch play/pause callback is preserved")
close.OnClick(); reset.OnClick(); play.OnClick()
equal(clicks, 3, "all native stopwatch controls still receive input")
watchRecord.handle.OnDragStart(watchRecord.handle)
StopwatchFrame.centerX, StopwatchFrame.centerY = 700, 500
watchRecord.handle.OnDragStop(watchRecord.handle); Flush()
equal(Suite.db.windowPositions.StopwatchFrame.x, 0.2, "header drag saves stopwatch position")
equal(StopwatchFrame:IsMovable(), true, "header drag retains native movable state")
StopwatchFrame.shown = false; StopwatchFrame.OnHide(StopwatchFrame); Flush()
StopwatchFrame.shown = true; StopwatchFrame.OnShow(StopwatchFrame)
equal(StopwatchFrame.point[4], 200, "closing and reopening restores the moved stopwatch immediately")
StopwatchFrame.OnDragStart(StopwatchFrame)
equal(watchRecord.dragging, true, "native stopwatch body drag participates in position saving")
StopwatchFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 77, -66)
equal(StopwatchFrame.point[4], 77, "saved placement does not fight native stopwatch dragging")
StopwatchFrame.centerX, StopwatchFrame.centerY = 650, 450
StopwatchFrame.OnDragStop(StopwatchFrame); Flush()
equal(starts, 1, "native stopwatch drag-start script still runs")
equal(stops, 1, "native stopwatch drag-stop script still runs")
equal(Suite.db.windowPositions.StopwatchFrame.x, 0.15, "native stopwatch drag saves its new position")
local persisted = Suite.InitializeDB(Suite.Copy(Suite.db))
equal(persisted.windowPositions.StopwatchFrame.x, 0.15, "stopwatch position survives database initialization")
local watchSaved = Suite.db.windowPositions.StopwatchFrame
watchRecord.handle.OnMouseUp(watchRecord.handle, "RightButton")
equal(Suite.db.windowPositions.StopwatchFrame, watchSaved, "plain right-click preserves stopwatch placement")
watchRecord.handle.OnMouseWheel(watchRecord.handle, 1)
equal(StopwatchFrame.scale, 1, "plain stopwatch wheel input cannot resize")
control = true; watchRecord.handle.OnMouseWheel(watchRecord.handle, 1)
equal(StopwatchFrame.scale, 1.05, "Ctrl-wheel scales the compact stopwatch proportionally")
watchRecord.handle.OnMouseUp(watchRecord.handle, "RightButton"); control = false; Flush()
equal(Suite.db.windowPositions.StopwatchFrame, nil, "Ctrl-right-click resets only stopwatch placement")
equal(StopwatchFrame.point[1], "TOPRIGHT", "stopwatch reset restores its original native anchor")
equal(StopwatchFrame.scale, 1, "stopwatch reset restores its original scale")
equal(Suite.db.windowPositions.TimeManagerFrame.scale, 1.1, "stopwatch reset preserves clock panel placement")
Suite.db.windowPositions.StopwatchFrame = { x = 0.15, y = 0.0625, scale = 1 }
windows:ApplyRecord(watchRecord)
watchRecord.handle.OnDragStart(watchRecord.handle)
StopwatchFrame.centerX, StopwatchFrame.centerY = 800, 600
Combat(true); windows.events.OnEvent(windows.events, "PLAYER_REGEN_DISABLED")
equal(StopwatchFrame.moving, false, "combat stops an unprotected stopwatch drag")
equal(Suite.db.windowPositions.StopwatchFrame.x, 0.15, "combat does not save unfinished stopwatch movement")
LeaveCombat()
equal(StopwatchFrame.point[4], 150, "combat exit restores the committed stopwatch position")
Suite.db.windowTools = false; windows:Apply(); Flush()
equal(StopwatchFrame.point[1], "TOPRIGHT", "disabling window tools restores native stopwatch anchors")
equal(watchRecord.handle:IsShown(), false, "disabled stopwatch drag input is hidden")
equal(ActiveTimers(), 0, "disabled stopwatch support keeps no worker alive")
TimeManagerFrame, StopwatchFrame, IsControlKeyDown = oldClock, oldStopwatch, oldControl

windows:CancelTimer()
windows.names, windows.tracked, windows.watched, windows.events = oldNames, oldTracked, oldWatched, oldEvents
windows.HeaderRects, windows.discoverPending = oldHeaderRects, nil
windows.bagRecords, windows.bagsHeld = oldBagRecords, oldBagsHeld
Suite.db, Suite.pending, CreateFrame, C_Timer = oldDB, oldPending, oldCreate, oldTimers
UIParent, UIPanelWindows = oldParent, oldPanels
CharacterFrame, ContainerFrameCombinedBags, ContainerFrame2 = oldCharacter, oldBag, oldHidden
ContainerFrame1, UpdateContainerFrameAnchors = oldFirst, oldAnchors
Combat(false)
