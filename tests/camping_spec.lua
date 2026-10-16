local Suite, equal, Frame, SetCombat = ...
local camping, items = Suite.Camping, Suite.CampingItems
SetCombat(false)
Suite.db = Suite.InitializeDB(nil)
equal(Suite.db.campingBar, false, "camping display defaults off")
equal(Suite.db.campingPose, "sit", "sitting is the default pose")
camping:Apply()
equal(camping.bar, nil, "disabled camping creates no secure UI")
equal(camping.events, nil, "disabled camping registers no feature events")

local timers, secure, made = {}, false, {}
C_Timer.NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end
local function Flush()
    local pending = timers; timers = {}
    for _, timer in ipairs(pending) do if not timer.cancelled then timer.callback() end end
end
local function Mutate(frame)
    assert(not InCombatLockdown() or not frame.protected or secure, "protected camping mutation in combat")
end
local function RestrictedHandle(frame)
    if frame.handle then return frame.handle end
    local function Check()
        -- RestrictedFrames.lua rejects unprotected handles in combat even in secure code.
        assert(not InCombatLockdown() or frame.protected, "Invalid frame handle")
    end
    frame.handle = {
        GetFrameRef = function(_, key) Check(); return frame.refs[key] end,
        Show = function() Check(); frame:Show() end,
        Hide = function() Check(); frame:Hide() end,
    }
    return frame.handle
end
CreateFrame = function(kind, name, parent, templates)
    local frame = Frame(name)
    frame.objectType, frame.parent = kind, parent
    frame.explicitlyProtected = templates and templates:find("Secure", 1, true) ~= nil or false
    if frame.explicitlyProtected then
        -- A protected child protects its ancestors, not its unrelated siblings/descendants.
        local ancestor = frame
        while ancestor do ancestor.protected = true; ancestor = ancestor.parent end
    end
    frame.IsProtected = function(self) return self.protected == true, self.explicitlyProtected end
    if parent and parent.children then parent.children[#parent.children + 1] = frame end
    frame.attributes, frame.refs, frame.registered = {}, {}, {}
    frame.SetAttribute = function(self, key, value) Mutate(self); self.attributes[key] = value end
    frame.GetAttribute = function(self, key) return self.attributes[key] end
    frame.SetFrameRef = function(self, key, value) Mutate(self); self.refs[key] = RestrictedHandle(value) end
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    frame.SetAllPoints = function(self, target) Mutate(self); self.allPoints = target end
    frame.SetTexture = function(self, texture) self.texture = texture end
    frame.SetTexCoord = function() end
    frame.SetDrawLayer = function() end
    frame.SetCooldown = function(self, start, duration) self.cooldownStart, self.duration = start, duration end
    frame.IsVisible = function(self) return self:IsShown() and (not self.parent or self.parent:IsVisible()) end
    for _, method in ipairs({ "SetPoint", "ClearAllPoints", "SetSize", "StartMoving", "StopMovingOrSizing", "Show", "Hide", "SetShown" }) do
        local original = frame[method]
        frame[method] = function(self, ...) Mutate(self); return original(self, ...) end
    end
    frame.CreateTexture = function() return CreateFrame("Texture", nil, frame) end
    frame.CreateFontString = function() return CreateFrame("FontString", nil, frame) end
    made[#made + 1] = frame
    return frame
end
RegisterStateDriver = function(frame, state, condition)
    assert(frame.explicitlyProtected, "state drivers require an explicitly protected controller")
    frame.driverState, frame.driverCondition = state, condition
    local compile = loadstring or load
    local snippet = assert(compile("return function(self, newstate) " .. frame.attributes["_onstate-" .. state] .. " end"))()
    frame.RunState = function(self, newstate)
        local previous = secure
        secure = true
        local ok, message = pcall(snippet, RestrictedHandle(self), newstate)
        secure = previous
        assert(ok, message)
    end
    frame:RunState("peaceful")
end
local nearby, restrictedAura, auraReads = false, false, 0
C_UnitAuras = { GetAuraDataByIndex = function(_, index, filter)
    assert(filter == "HELPFUL", "only helpful player auras determine proximity")
    assert(not InCombatLockdown(), "never scan combat auras")
    auraReads = auraReads + 1
    if index == 1 and restrictedAura then return { name = { secret = true }, spellId = { secret = true } } end
    if index == 1 and nearby then return { name = "Campfire Nearby", spellId = 1283391 } end
end }
C_Spell = { GetSpellName = function() return "Campfire Nearby" end }
equal(camping:Nearby(), false, "no aura means no nearby camp")
nearby = true
equal(camping:Nearby(), true, "the screenshot's nearby aura is detected")
restrictedAura = true
equal(camping:Nearby(), false, "secret aura fields cannot establish proximity")
restrictedAura = false
local auraAPI = C_UnitAuras.GetAuraDataByIndex
C_UnitAuras.GetAuraDataByIndex = function(_, index) if index == 1 then return { name = "Camping Benefit", spellId = 1229739 } end end
equal(camping:Nearby(), false, "a reward buff never substitutes for camp proximity")
C_UnitAuras.GetAuraDataByIndex = auraAPI

local data = {
    [900] = { name = "Lodestone", text = "Requires a Campfire nearby. All camping features share a cooldown of 1 hour." },
    [901] = { name = "New Camp Object", text = "|cff00ff00Requires a\nCampfire nearby.|r" },
    [902] = { name = "Blueprint: Lodestone", class = 9, text = "Requires a Campfire nearby." },
    [903] = { name = "Copper Bar", noUse = true, text = "Requires a Campfire nearby." },
    [904] = { name = "Potion", text = "Restores health." },
    [905] = { name = "Late Object", text = "Requires a Campfire nearby." },
}
local bag = { 900, 900, 901, 902, 903, 904 }
local requests, missing, secretBag, secretTooltip = {}, nil, false, nil
local bagReads, itemReads = 0, 0
C_Item = {
    GetItemInfo = function(id)
        itemReads = itemReads + 1
        if id == missing then return nil end
        local item = data[id]
        return item.name, "item:" .. id, 1, 1, 0, "", "", 20, "", 134400, 0, item.class or 0
    end,
    GetItemSpell = function(id) return not data[id].noUse and "Place" or nil end,
    RequestLoadItemDataByID = function(id) requests[id] = (requests[id] or 0) + 1 end,
    GetItemCooldown = function() return 5, 3600, true end,
}
NUM_TOTAL_EQUIPPED_BAG_SLOTS = 5
C_Container = {
    GetContainerNumSlots = function(index) assert(index >= 0 and index <= 5, "never scan banks"); return index == 0 and #bag or 0 end,
    GetContainerItemInfo = function(_, slot)
        assert(not InCombatLockdown(), "never scan combat inventory")
        bagReads = bagReads + 1
        return { itemID = secretBag and { secret = true } or bag[slot], stackCount = 2, iconFileID = 134400 }
    end,
}
C_TooltipInfo = { GetBagItem = function(_, slot)
    if bag[slot] == secretTooltip then return { lines = { { leftText = { secret = true } } } } end
    return { lines = { { leftText = data[bag[slot]].name }, { rightText = data[bag[slot]].text } } }
end }
local snapshot = items:Scan()
equal(#snapshot.list, 2, "discover every camp-use object without an ID catalog")
equal(snapshot.byID[900].count, 4, "duplicate carried stacks share one action and a combined count")
equal(snapshot.byID[901].count, 2, "unknown IDs and wrapped colored requirement text are supported")
equal(snapshot.byID[902], nil, "exclude camp object recipes")
equal(snapshot.byID[903], nil, "exclude ingredients without a use action")
equal(snapshot.byID[904], nil, "exclude unrelated use items")
bag[#bag + 1], missing = 905, 905
snapshot = items:Scan(); items:Scan()
equal(snapshot.incomplete, true, "uncached objects report incomplete data")
equal(requests[905], 1, "request missing metadata only once")
missing = nil
snapshot = items:Scan()
equal(snapshot.byID[905].id, 905, "item data arrival includes the newly loaded object")
items.catalog[901], secretTooltip = nil, 901
snapshot = items:Scan()
equal(snapshot.byID[901], nil, "restricted tooltip text is skipped without comparison")
secretTooltip = nil
secretBag = true
snapshot = items:Scan()
equal(#snapshot.list, 0, "secret item IDs never become secure action attributes")
secretBag = false

UIParent = Frame()
UIParent:SetSize(1000, 800)
UIParent:Show()
bag[7] = nil
Suite.db.campingBar = true
camping:Apply()
equal(camping.bar:IsShown(), true, "nearby camp shows the optional bar")
equal(camping.controller.driverCondition, "[combat] combat; peaceful", "secure state driver owns combat hiding")
equal(camping.rest.attributes.type1, "macro", "rest requires a hardware secure macro action")
equal(camping.rest.attributes.macrotext1, "/sit", "rest performs the selected pose")
equal(camping.rest.attributes.useOnKeyDown, false, "rest only runs on release")
equal(camping.buttons[1].attributes.item1, "item:900", "object action uses item ID rather than an unstable bag slot")
equal(camping.buttons[1].count.text, "4", "bar shows the combined item count")
equal(camping.buttons[1].cooldown.duration, 3600, "native item cooldown swipe receives guarded duration")
equal(camping.bar:GetScript("OnUpdate"), nil, "bar has no idle OnUpdate")
equal(camping.events.registered.UNIT_AURA, true, "enabled bar observes proximity changes")
bag[7], missing, items.catalog[905] = 905, 905, nil
camping.events.OnEvent(nil, "BAG_UPDATE_DELAYED"); Flush()
equal(camping.snapshot.byID[905], nil, "pending item data does not expose an unknown action")
missing = nil
camping.events.OnEvent(nil, "ITEM_DATA_LOAD_RESULT", 905, true); Flush()
equal(camping.snapshot.byID[905].id, 905, "relevant item-data events refresh the carried actions")
bag[7] = nil
camping.events.OnEvent(nil, "BAG_UPDATE_DELAYED"); Flush()
local readsBefore = bagReads
camping.events.OnEvent(nil, "UNIT_AURA", "target")
equal(camping.timer, nil, "non-player aura updates do no work")
camping.events.OnEvent(nil, "UNIT_AURA", "player")
camping.events.OnEvent(nil, "UNIT_AURA", "player")
equal(#timers, 1, "coalesce aura bursts into one cancellable refresh")
Flush()
equal(bagReads, readsBefore, "unchanged camp proximity reuses the inventory snapshot")
camping.header.OnDragStart()
camping:Refresh()
equal(camping.bar.moving, true, "aura refreshes do not cancel a live drag")
camping.header.OnDragStop()
equal(type(Suite.db.campingPosition.x), "number", "drag saves normalized screen position")

local executed = 0
DoEmote = function() executed = executed + 1 end
EMOTE1_TOKEN, EMOTE1_CMD1 = "KNEEL", "/knien"
camping:SelectPose("kneel")
equal(camping.rest.attributes.macrotext1, "/knien", "poses prefer the client's localized native command")
equal(executed, 0, "choosing a pose never performs it automatically")
camping:SelectPose("sleep")
equal(camping.rest.attributes.macrotext1, "/sleep", "sleep is selectable")
camping:SelectPose("lie")
equal(camping.rest.attributes.macrotext1, "/lie", "lie down is selectable")
camping:SelectPose("bad")
equal(Suite.db.campingPose, "lie", "invalid pose settings cannot inject macro commands")

nearby = false
camping.events.OnEvent(nil, "UNIT_AURA", "player"); Flush()
equal(camping.bar:IsShown(), false, "leaving the proximity buff hides the bar")
local inventoryBefore = bagReads
camping.events.OnEvent(nil, "BAG_UPDATE_DELAYED"); Flush()
equal(bagReads, inventoryBefore, "inventory changes away from camp defer bag scanning")
camping:SetSettingsVisible(true); camping:SetPreview(true)
equal(camping.preview:IsShown(), true, "explicit position preview works away from camp")
equal(camping.bar:IsShown(), false, "position preview never reveals gameplay buttons away from camp")
equal(camping.preview.protected, nil, "preview has no secure action children")
camping:SetSettingsVisible(false)
equal(camping.preview:IsShown(), false, "leaving settings ends position preview")

bag = {}; nearby = true
camping.events.OnEvent(nil, "UNIT_AURA", "player"); Flush()
equal(camping.bar:IsShown(), true, "rest remains available when no objects are carried")
equal(camping.empty:IsShown(), true, "empty inventory receives a quiet status")
equal(camping.buttons[1].attributes.item1, nil, "recycled empty item buttons clear their old action")
equal(camping.buttons[1]:IsShown(), false, "removed objects disappear")
camping.arrow.OnClick()
equal(camping.flyout:IsShown(), true, "pose chooser can open with no carried camp objects")
SetCombat(true); camping.controller:RunState("combat")
equal(camping.flyout:IsShown(), false, "combat can securely hide the open chooser without item actions")
equal(camping.bar:IsShown(), false, "combat hides the empty-inventory bar through valid frame handles")
equal(camping.rest:IsVisible(), false, "rest action is inaccessible while the secure controller is hidden")
camping.events.OnEvent(nil, "PLAYER_REGEN_DISABLED")
SetCombat(false); camping.controller:RunState("peaceful")
equal(camping.bar:IsShown(), false, "secure exit alone does not reveal stale actions before refresh")
equal(camping.flyout:IsShown(), false, "secure exit does not reopen the pose chooser")
camping.events.OnEvent(nil, "PLAYER_REGEN_ENABLED")
equal(camping.bar:IsShown(), true, "fresh nearby check restores the empty-inventory bar after combat")
equal(camping.flyout:IsShown(), false, "fresh nearby check keeps the pose chooser closed")
bag = {}
for id = 910, 921 do data[id] = { name = "Object " .. id, text = "Requires a Campfire nearby." }; bag[#bag + 1] = id end
camping.events.OnEvent(nil, "BAG_UPDATE_DELAYED"); Flush()
equal(#camping.snapshot.list, 12, "all distinct objects remain available beyond one row")
equal(camping.bar.height, 92, "additional objects wrap into a compact second row")
equal(camping.buttons[12].attributes.item1, "item:921", "wrapped objects retain secure use actions")
C_Item.GetItemCooldown = function() return { secret = true }, { secret = true }, { secret = true } end
camping:Cooldowns()
equal(camping.buttons[1].cooldown:IsShown(), false, "restricted cooldown values are never compared or formatted")

camping:SetSettingsVisible(true); camping:SetPreview(true)
camping.arrow.OnClick(); camping.header.OnDragStart()
camping:Queue(true)
local auraBefore, bagBefore, actionBefore = auraReads, bagReads, camping.rest.attributes.macrotext1
SetCombat(true); camping.controller:RunState("combat")
equal(camping.flyout:IsShown(), false, "secure combat state hides the Escape-managed chooser itself")
camping.events.OnEvent(nil, "PLAYER_REGEN_DISABLED")
camping:SelectPose("sit"); camping:Refresh(); camping:Cooldowns(); Flush()
equal(camping.controller:IsShown(), false, "native secure handler hides the entire combat bar")
equal(camping.bar:IsShown(), false, "combat exit cannot reveal a stale shown bar")
equal(camping.preview:IsShown(), false, "combat ends the inert position preview")
equal(auraReads, auraBefore, "combat performs no aura scans")
equal(bagReads, bagBefore, "combat performs no bag scans")
equal(camping.rest.attributes.macrotext1, actionBefore, "combat cannot change secure pose actions")
equal(camping.timer, nil, "entering combat cancels queued work")
nearby = false
SetCombat(false); camping.controller:RunState("peaceful")
equal(camping.bar:IsShown(), false, "repeated combat exit waits for refreshed proximity")
camping.events.OnEvent(nil, "PLAYER_REGEN_ENABLED")
equal(camping.bar:IsShown(), false, "combat exit checks fresh proximity before revealing actions")
equal(camping.bar.moving, nil, "interrupted movement stops after combat")
equal(camping.flyout:IsShown(), false, "combat closes the pose chooser")
nearby = true
camping.events.OnEvent(nil, "UNIT_AURA", "player"); Flush()
SetCombat(true)
Suite.db.campingBar = false; camping:Apply()
equal(camping.events.registered.UNIT_AURA, nil, "disabling during combat unregisters events immediately")
equal(type(Suite.pending.camping), "function", "protected cleanup defers until combat ends")
SetCombat(false)
Suite.pending.camping(); Suite.pending.camping = nil
equal(camping.bar:IsShown(), false, "deferred disable leaves the bar hidden")
equal(camping.timer, nil, "disabled camping leaves no timer")
SetCombat(true); camping.controller:RunState("combat")
equal(camping.flyout:IsShown(), false, "retained secure driver safely handles combat while camping is disabled")
SetCombat(false); camping.controller:RunState("peaceful")
equal(camping.bar:IsShown(), false, "retained driver cannot show disabled camping on combat exit")
camping:ResetPosition()
equal(next(Suite.db.campingPosition), nil, "position reset restores the default without changing other layouts")
local beforeGUI = #made
Suite.GUI:OpenPage("camping")
equal(Suite.GUI.page, "camping", "camping has its own settings page")
equal(Suite.GUI.rows[2].value.text, "Lie down", "settings show the remembered pose")
equal(#made, beforeGUI, "opening settings reuses controls and creates no secure buttons")
Suite.GUI:Select("overview")
equal(camping.settingsVisible, false, "leaving the Camping page stops positioning")
