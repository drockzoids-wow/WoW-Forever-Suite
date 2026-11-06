local _, Suite = ...
local Planner = Suite.TalentPlanner
local function Accessible(frame)
    if not Suite.IsReadable(frame) or not frame or type(frame.IsForbidden) ~= "function" then return false end
    local ok, forbidden = pcall(frame.IsForbidden, frame)
    return ok and Suite.IsReadable(forbidden) and forbidden == false
end
local function Label(parent, size, x, y, text, width)
    local font = parent:CreateFontString(nil, "OVERLAY")
    font:SetFont("Fonts\\FRIZQT__.TTF", size, "")
    font:SetTextColor(0.88, 0.91, 0.93); font:SetJustifyH("LEFT")
    font:SetPoint("TOPLEFT", x, y); font:SetWidth(width or 248); font:SetText(text or "")
    return font
end
local function Surface(frame)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.035, 0.05, 0.065, 0.98); Suite.Theme:Backdrop(frame, 0.8)
end
local function Button(parent, x, y, width, text, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetPoint("TOPLEFT", x, y); button:SetSize(width, 26); Surface(button)
    local font = Label(button, 11, 4, -7, text, width - 8); font:SetJustifyH("CENTER")
    font:SetWordWrap(false)
    button.caption = font
    button:RegisterForClicks("LeftButtonUp"); Suite.Theme:ButtonFeedback(button)
    button:SetScript("OnClick", function() if not InCombatLockdown() and Planner:Enabled() then callback() end end)
    return button
end
local function Input(parent, x, y, width, limit)
    local field = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    field:SetPoint("TOPLEFT", x, y); field:SetSize(width, 26); Surface(field)
    field:SetFont("Fonts\\FRIZQT__.TTF", 12, ""); field:SetTextInsets(6, 6, 0, 0)
    field:SetAutoFocus(false); field:SetMaxLetters(limit)
    field:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
    return field
end

local function BuildCog(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(24, 24); button:EnableMouse(true); button:RegisterForClicks("LeftButtonUp")
    Suite.Theme:ButtonFeedback(button)
    -- Small original cog outline; no font glyph or client-specific atlas dependency.
    local function Ring(points, radius)
        for index = 1, points do
            local first, last = (index - 1) * 2 * math.pi / points, index * 2 * math.pi / points
            local line = button:CreateLine(nil, "ARTWORK")
            local r1, r2 = radius(index - 1), radius(index % points)
            line:SetThickness(1.25); line:SetColorTexture(0.9, 0.78, 0.53, 1)
            line:SetStartPoint("CENTER", button, math.cos(first) * r1, math.sin(first) * r1)
            line:SetEndPoint("CENTER", button, math.cos(last) * r2, math.sin(last) * r2)
        end
    end
    Ring(32, function(index) local phase = index % 4; return (phase == 1 or phase == 2) and 8 or 6 end)
    Ring(12, function() return 2.8 end)
    button:SetScript("OnClick", function()
        if InCombatLockdown() or not Planner:Enabled() then return end
        Planner.expanded = not Planner.expanded
        if not Planner.expanded then Planner:StopGuide(); Planner.preview = false end
        if GameTooltip then GameTooltip:Hide() end
        Planner:Refresh()
    end)
    button:SetScript("OnEnter", function()
        if not Planner:Ready() or not GameTooltip then return end
        GameTooltip:SetOwner(button, "ANCHOR_LEFT")
        GameTooltip:SetText(Planner.expanded and "Collapse talent builds" or "Expand talent builds")
        GameTooltip:Show(); Planner.tooltipOwner = button
    end)
    local function HideTooltip()
        if Planner.tooltipOwner == button and GameTooltip then GameTooltip:Hide(); Planner.tooltipOwner = nil end
    end
    button:SetScript("OnLeave", HideTooltip); button:SetScript("OnHide", HideTooltip)
    return button
end

function Planner:Attach()
    local host = PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
    if self.root or not host or InCombatLockdown() or not self:Enabled() then return end
    if not host.ClassBackground or not host.ApplyButton or not RegisterStateDriver or not UnregisterStateDriver then return end
    if not Accessible(host) then return end
    -- A secure visibility driver hides the entire owned planner before combat input.
    -- No native widget scripts, parent, anchors, enabled state or config are changed.
    local root = CreateFrame("Frame", nil, host, "SecureHandlerStateTemplate")
    self.root, self.host = root, host
    root:SetAllPoints(host); root:SetFrameLevel(3000)
    RegisterStateDriver(root, "visibility", "[combat] hide; show")
    self.driver = true
    root:HookScript("OnHide", function()
        if self.tooltipOwner and GameTooltip then GameTooltip:Hide(); self.tooltipOwner = nil end
        if self.notesEdit then self.notesEdit:ClearFocus() end
        if self.starterLevelInput then self.starterLevelInput:ClearFocus() end
        if self.starterSource then self.starterSource:ClearFocus() end
    end)
    local panel = CreateFrame("Frame", nil, root, "BackdropTemplate")
    self.panel = panel; panel:SetSize(276, 662)
    panel:SetPoint("TOPLEFT", host, "TOPRIGHT", 6, 0); panel:SetClampedToScreen(true)
    panel:EnableMouse(true); Surface(panel); panel:SetBackdropColor(0.035, 0.05, 0.065, 1); panel:Hide()
    Label(panel, 17, 14, -16, "Talent Builds")
    Label(panel, 11, 14, -42, "Plan freely. Drafts save automatically.")
    local close = Suite.Theme:IconButton(panel, "close", function()
        if InCombatLockdown() then return end
        self:StopGuide(); self.expanded, self.preview = false, false; panel:Hide(); self:Render()
    end)
    close:SetPoint("TOPRIGHT", -6, -6)
    self.groupText = Label(panel, 11, 14, -64, "", 248)
    self.launcher = BuildCog(root)
    local nativeClose = PlayerSpellsFrame.CloseButton
    if Accessible(nativeClose) then
        self.launcher:SetPoint("RIGHT", nativeClose, "LEFT", -18, 0)
        local ok, level = pcall(nativeClose.GetFrameLevel, nativeClose)
        if ok and Suite.IsReadable(level) and type(level) == "number" and level >= 0 and level < 10000 then
            self.launcher:SetFrameLevel(math.max(5512, level + 1))
        else self.launcher:SetFrameLevel(5512) end
    else
        self.launcher:SetPoint("TOPRIGHT", PlayerSpellsFrame, "TOPRIGHT", -50, -4)
        self.launcher:SetFrameLevel(5512)
    end
    self.launcher:Hide()
    self.live = Button(panel, 14, -100, 88, "Edit draft", function()
        if self.starter then self:OpenStarterPanel()
        elseif self:Current() then self:Select(self.selected) end
    end)
    self.guideButton = Button(panel, 110, -100, 152, "Learn this build", function()
        if self.guiding then self:StopGuide(); self:Render() else self:StartGuide() end
    end)
    Button(panel, 14, -134, 76, "New empty", function() self:New() end)
    Button(panel, 98, -134, 76, "Copy native", function() if self:Ready() then self:New("Native copy", self.model.native) end end)
    self.orderButton = Button(panel, 182, -134, 80, "Point order", function() self:OpenOrder() end)
    self.starterButton = Button(panel, 14, -168, 248, "Starter leveling build", function() self:OpenStarterPanel() end)
    self.rows, self.page = {}, 1
    for index = 1, 5 do
        local row = Button(panel, 14, -208 - (index - 1) * 29, 248, "", function()
            local selected = self.visibleBuilds and self.visibleBuilds[(self.page - 1) * 5 + index]
            if selected then self:Select(selected) end
        end)
        self.rows[index] = row
    end
    self.previous = Button(panel, 14, -357, 56, "<", function() self.page = math.max(1, self.page - 1); self:Render() end)
    self.pageText = Label(panel, 11, 82, -365, "", 98); self.pageText:SetJustifyH("CENTER")
    self.next = Button(panel, 206, -357, 56, ">", function() self.page = self.page + 1; self:Render() end)
    self.name = Input(panel, 14, -394, 160, 48)
    self.favorite = Button(panel, 182, -394, 80, "Favorite", function() self:ToggleFavorite() end)
    self.name:SetScript("OnEnterPressed", function(box)
        if not InCombatLockdown() then self:Rename(box:GetText()); box:ClearFocus() end
    end)
    self.name:SetScript("OnEditFocusLost", function(box)
        if not InCombatLockdown() and self:Current() then self:Rename(box:GetText()) end
    end)
    self.duplicate = Button(panel, 14, -428, 76, "Duplicate", function()
        if self.starter then self:CustomizeStarter(); return end
        local b = self:Current(); if b then self:New(b.name:sub(1, 41) .. " (copy)", b.ranks, b.notes, b.sequence) end
    end)
    self.notesButton = Button(panel, 98, -428, 76, "Notes", function() self:OpenNotes() end)
    self.delete = Button(panel, 182, -428, 80, "Delete", function() self:Delete() end)
    self.undoButton = Button(panel, 14, -462, 120, "Undo", function() self:History(false) end)
    self.redoButton = Button(panel, 142, -462, 120, "Redo", function() self:History(true) end)
    self.code = Input(panel, 14, -506, 248, 16384)
    Label(panel, 10, 14, -492, "Suite build code")
    self.import = Button(panel, 14, -540, 120, "Import", function() self:Import(self.code:GetText()); self.code:ClearFocus() end)
    self.export = Button(panel, 142, -540, 120, "Export", function()
        local code = self:Export()
        if code then self.code:SetText(code); self.code:SetFocus(); self.code:HighlightText() end
    end)
    self.status = Label(panel, 11, 14, -580, "", 248)
    self.status:SetHeight(42)
    self.ruleHint = Label(panel, 10, 14, -627, "", 248)
    local overlay = CreateFrame("Frame", nil, root)
    self.overlay = overlay; overlay:SetAllPoints(host.ClassBackground)
    overlay:EnableMouse(true); overlay:EnableMouseWheel(true)
    overlay:SetScript("OnMouseWheel", function() end)
    local wash = overlay:CreateTexture(nil, "BACKGROUND"); wash:SetAllPoints(); wash:SetColorTexture(0.015, 0.025, 0.035, 0.72)
    self.banner = Label(overlay, 12, 12, -8, "DRAFT • Left-click adds • Right-click removes • Shift-click changes choice", 700)
    self.banner:SetTextColor(0.41, 0.84, 0.75)
    self.rulesButton = Button(overlay, 0, 0, 168, "", function()
        Suite.Set("talentPlannerRules", not self:RulesEnabled())
    end)
    self.rulesButton.caption:SetText("Limit to current level:")
    self.rulesButton.caption:ClearAllPoints(); self.rulesButton.caption:SetHeight(16)
    self.rulesState = Label(self.rulesButton, 12, 0, 0, "", 30)
    self.rulesState:ClearAllPoints(); self.rulesState:SetHeight(16)
    self.rulesState:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    self.rulesState:SetTextColor(1, 1, 1); self.rulesState:SetWordWrap(false)
    -- A small same-color shadow thickens only the state lettering inside its outline.
    self.rulesState:SetShadowColor(1, 1, 1, 1); self.rulesState:SetShadowOffset(0.5, 0)
    self.rulesState:SetPoint("LEFT", self.rulesButton.caption, "RIGHT", 5, 0)
    self.rulesButton:ClearAllPoints(); self.rulesButton:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", -12, -4)
    self.resetButton = Button(overlay, 0, 0, 104, "Reset draft", function() self:ResetDraft() end)
    self.resetButton:ClearAllPoints(); self.resetButton:SetPoint("TOPRIGHT", self.rulesButton, "TOPLEFT", -8, 0)
    overlay:Hide(); self.buttons, self.headers, self.edgeFrames = {}, {}, {}
    -- Cover the native commit/reset footer while a draft is visible, without changing it.
    local footer = CreateFrame("Frame", nil, root, "BackdropTemplate")
    self.footer = footer; footer:SetPoint("TOPLEFT", host.ApplyButton, "TOPLEFT", -200, 22)
    footer:SetPoint("BOTTOMRIGHT", host.ApplyButton, "BOTTOMRIGHT", 200, -4)
    footer:EnableMouse(true); Surface(footer)
    self.budgetText = Label(footer, 11, 6, -8, "", 550); self.budgetText:SetJustifyH("CENTER")
    self.buildLevelText = Label(footer, 11, 6, -26, "", 550); self.buildLevelText:SetJustifyH("CENTER")
    self.budgetText:SetHeight(16); self.buildLevelText:SetHeight(16)
    footer:Hide()
    host:HookScript("OnShow", function() self:Queue() end)
    host:HookScript("OnHide", function()
        if self.timer then self.timer:Cancel(); self.timer = nil end
        -- Owned protected descendants inherit the native hide; cleanup waits for safety.
        if not InCombatLockdown() then
            self.preview = false; self.code:ClearFocus(); self.name:ClearFocus(); self:CloseNotes(); self:CloseOrder()
            self:CloseStarterPanel(); self:Render()
        end
    end)
    if hooksecurefunc then
        for _, method in ipairs({ "SetConfigID", "UpdateTree", "InstantiateTalentButton", "UpdateInspecting" }) do
            if type(host[method]) == "function" then hooksecurefunc(host, method, function() self:Queue() end) end
        end
    end
end

function Planner:Tooltip(button)
    if not self:Ready() or not GameTooltip then return end
    local node, build = self.model.nodes[button.nodeID], self:Current()
    if not node or not build then return end
    local rank = build.ranks[button.nodeID]
    local entryID = rank and rank.entry or node.order[1]
    local entry = node.entries[entryID]
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(entry.name)
    local function Description(value, caption)
        local description = self:RankDescription(entryID, value)
        GameTooltip:AddLine(caption .. " " .. value, 0.9, 0.72, 0.4)
        if description then GameTooltip:AddLine(description, 1, 0.85, 0.2, true)
        else GameTooltip:AddLine("Description unavailable for this rank.", 0.55, 0.65, 0.7, true) end
    end
    if rank then Description(rank.rank, "Draft rank") end
    if not rank or rank.rank < entry.max then Description(rank and rank.rank + 1 or 1, "Next rank") end
    local native = self.model.native[button.nodeID]
    GameTooltip:AddLine("Draft " .. (rank and rank.rank or 0) .. "/" .. entry.max .. " • Native " .. (native and native.rank or 0), 0.41, 0.84, 0.75)
    if self.analysis then
        local level = self:Budget()
        local reason = self.analysis.blocked[button.nodeID]
            or self:RuleReason(button.nodeID, rank and rank.entry or node.order[1], self.analysis.state, level, self:RulesEnabled())
        if reason then GameTooltip:AddLine(reason, 1, 0.65, 0.35, true) end
    end
    if self.starter then GameTooltip:AddLine("Starter preview. Customize a copy to edit.", 0.41, 0.84, 0.75)
    elseif #node.order > 1 then GameTooltip:AddLine("Shift-left-click: next talent choice", 0.9, 0.72, 0.4) end
    GameTooltip:Show(); self.tooltipOwner = button
end

function Planner:BaselineLevelText(points)
    if not Suite.IsReadable(points) or type(points) ~= "number" or points ~= points
        or points < 0 or points > 512 or points % 1 ~= 0 then return "Point baseline unavailable." end
    if points == 0 then return "No talent points selected." end
    if points > 51 then return "More than 51 points: bonus talent points required at level 60." end
    -- Reference schedule only. Earned native currency remains the authority for
    -- actual editing limits and learning, including bonus talent points.
    return "Without bonus talent points: level " .. (points + 9) .. " for " .. points
        .. (points == 1 and " planned point." or " planned points.")
end

function Planner:Render()
    if InCombatLockdown() or not self.root then return end
    local build = self.model and self:Current()
    local active = self.expanded == true and self.preview == true and not self.starter and build ~= nil and self:Ready()
    self.overlay:SetShown(active); self.footer:SetShown(active)
    self.resetButton:SetShown(active)
    self.resetButton:SetEnabled(active and next(build.ranks) ~= nil)
    if self.guideHighlight then self.guideHighlight:Hide() end
    self:HideGuideMarks()
    if self.notesFrame and (not self.expanded or self.notesBuild ~= build) then self:CloseNotes() end
    if self.orderFrame and (not self.expanded or self.orderBuild ~= build) then self:CloseOrder() end
    if self.starterPanel and (not self.expanded or not self.starter or not self.model) then self:CloseStarterPanel() end
    if self.tooltipOwner and GameTooltip then GameTooltip:Hide(); self.tooltipOwner = nil end
    for _, button in pairs(self.buttons) do button:Hide() end
    for _, header in pairs(self.headers) do header:Hide() end
    for _, edge in pairs(self.edgeFrames) do edge:Hide() end
    if not self.model then return end
    self.launcher:Show()
    local rulesEnabled = self:RulesEnabled()
    self.rulesState:SetText(rulesEnabled and "ON" or "OFF")
    local prefixWidth = self.rulesButton.caption:GetUnboundedStringWidth()
    local stateWidth = self.rulesState:GetUnboundedStringWidth() + 1
    self.rulesButton.caption:SetWidth(prefixWidth); self.rulesState:SetWidth(stateWidth)
    self.rulesButton.caption:ClearAllPoints()
    self.rulesButton.caption:SetPoint("LEFT", self.rulesButton, "CENTER", -(prefixWidth + 5 + stateWidth) / 2, 0)
    if rulesEnabled then self.rulesButton:SetBackdropColor(0.42, 0.22, 0.08, 1)
    else self.rulesButton:SetBackdropColor(0.08, 0.32, 0.19, 1) end
    self.ruleHint:SetText(self:RulesEnabled() and "Use your current level and earned points.\nTree tiers and prerequisites always apply."
        or "Plan beyond your current level and points.\nTree tiers and prerequisites still apply.")
    self.analysis = build and self:Analyze(build.ranks, not self.starter and self:RulesEnabled()) or nil
    local totals = {}
    for _, group in ipairs(self.model.groupInfo) do
        local total = 0
        if build then for id, rank in pairs(build.ranks) do
            for _, member in ipairs(self.model.rules[id].groups) do if member == group.id then total = total + rank.rank; break end end
        end end
        totals[#totals + 1] = group.name .. ": " .. total
    end
    self.groupText:SetText(active and #totals > 0 and table.concat(totals, " / ") or table.concat(self.model.groups, " / "))
    local builds = self:Library()
    self.visibleBuilds = self:BuildOrder()
    local pages = math.max(1, math.ceil(#builds / 5))
    self.page = math.min(self.page or 1, pages)
    self.pageText:SetText(self.page .. " / " .. pages)
    self.previous:SetEnabled(self.page > 1); self.next:SetEnabled(self.page < pages)
    for i, row in ipairs(self.rows) do
        local index = self.visibleBuilds[(self.page - 1) * 5 + i]
        local b = index and builds[index]; row:SetShown(b ~= nil)
        if b then
            local compatible = b.tree == self.model.tree and b.hash == self.model.hash
            row.caption:SetText((not self.starter and index == self.selected and "> " or "") .. (b.favorite and "[Fav] " or "") .. b.name .. (compatible and "" or " (outdated)"))
        end
    end
    self.name:SetText(build and build.name or "")
    self.name:SetEnabled(build ~= nil); self.duplicate:SetEnabled(build ~= nil); self.delete:SetEnabled(build ~= nil)
    self.favorite:SetEnabled(build ~= nil); self.favorite.caption:SetText(build and build.favorite and "Unfavorite" or "Favorite")
    self.notesButton:SetEnabled(build ~= nil)
    self.orderButton:SetEnabled(build ~= nil); self.guideButton:SetEnabled(build ~= nil and (not self.starter or build.verified))
    self.live:SetEnabled(build ~= nil)
    self.live.caption:SetText(self.starter and "Levels" or "Edit draft")
    self.duplicate.caption:SetText(self.starter and "Customize" or "Duplicate")
    if self.starter then
        self.name:SetEnabled(false); self.favorite:SetEnabled(false); self.delete:SetEnabled(false); self.notesButton:SetEnabled(false)
        self.orderButton:SetEnabled(false)
        self.duplicate:SetEnabled(build ~= nil and build.verified)
    end
    self.guideButton.caption:SetText(self.guiding and "Stop learning guide" or "Learn this build")
    self.guideButton:SetBackdropColor(0.08, 0.32, 0.26, 1)
    self.export:SetEnabled(build ~= nil)
    self.undoButton:SetEnabled(build ~= nil and self.undo ~= nil and #self.undo > 0)
    self.redoButton:SetEnabled(build ~= nil and self.redo ~= nil and #self.redo > 0)
    if self.starter then self.undoButton:SetEnabled(false); self.redoButton:SetEnabled(false) end
    local level, budget = self:Budget()
    local points, added, removed = 0, 0, 0
    if build then
        for _, id in ipairs(self.model.order) do
            local node, draft, native = self.model.nodes[id], build.ranks[id], self.model.native[id]
            local rank, learned = draft and draft.rank or 0, native and native.rank or 0
            points = points + rank
            if draft and native and draft.entry ~= native.entry then added, removed = added + rank, removed + learned
            else added, removed = added + math.max(0, rank - learned), removed + math.max(0, learned - rank) end
            if active then self:RenderNode(id, node, draft, level, budget) end
        end
    end
    if active then
        self:RenderConnections(build)
        self.buildLevelText:SetText(self:BaselineLevelText(points))
        if self.starter then
            self.budgetText:SetText("Level " .. (self.starterLevel or 60) .. " preview • " .. points .. " planned points • Starter build (read-only)")
        elseif budget then
            local remaining = budget - points
            local color = remaining > 0 and "|cff66dd77" or remaining == 0 and "|cffffd24d" or "|cffff5555"
            self.budgetText:SetText("At level " .. level .. " you have " .. budget .. " talent points to spend with "
                .. color .. remaining .. "|r remaining.")
        else
            self.budgetText:SetText(level and ("At level " .. level .. ", your talent-point budget is unavailable.")
                or "Your level and talent-point budget are unavailable.")
        end
        local comparison = added .. (added == 1 and " rank added" or " ranks added") .. " · "
            .. removed .. (removed == 1 and " rank removed" or " ranks removed")
        self.status:SetText(points .. " points planned · Saved\n" .. comparison)
        if self.starter then self.status:SetText("Starter preview • Level " .. (self.starterLevel or 60) .. "\nCustomize to make your own editable copy.") end
        if self.analysis.unplaced > 0 then
            self.status:SetText(self.analysis.unplaced .. " ranks need review • see tooltip\n" .. comparison)
        end
    elseif build then self.status:SetText("Selected: " .. build.name .. "\nClick Learn this build to spend real points.")
    else self.status:SetText("Choose a saved build above.\nThen click Learn this build.") end
    if build and not self.guiding then
        self.ruleHint:SetText(self.starter and "Levels previews the starter plan.\nCustomize creates your own editable copy."
            or "Edit draft changes your saved plan.\nLearn this build guides real talent selection.")
        if active then self.ruleHint:SetText("Orange outline: next rank available.\nColored icon: points in this draft.") end
    end
    self.banner:SetText(self.starter and "STARTER PREVIEW • Use Levels to browse • Customize to edit • Learn this build to follow"
        or "DRAFT • Left-click adds • Right-click removes • Shift-click changes choice")
    self.rulesButton:SetShown(not self.starter)
    if self.notice then self.status:SetText(self.notice) end
    if self.model.staged then self.status:SetText(self.status:GetText() .. "\nNative tree has uncommitted changes.") end
    if self.guiding and not self.preview then
        self:RenderGuideMarks()
        local step, message = self:GuideStep()
        self.status:SetText(message or "Choose a saved build to follow.")
        self.ruleHint:SetText("+N: ranks to add • OK: matches • X: differs\nGold outline: next point. Use native Apply.")
        self:ShowGuideInstruction(step, message)
        if step then self:HighlightGuide(step) end
    end
    if self.starter and self.starterPanel and self.starterPanel:IsShown() then self:RenderStarterPanel() end
    self:RenderStarterHelper()
end

function Planner:HideGuideMarks()
    for _, mark in pairs(self.guideMarks or {}) do mark:Hide() end
    if self.guideInstruction then self.guideInstruction:Hide() end
end

function Planner:RenderStarterPanel()
    if not self:Ready() or not self.starterPanel or not self.starter then return end
    local full, reason = self:StarterBuild(60)
    local data = self.starters[self.model.class]
    self.starterTitle:SetText(data and data.spec .. " Leveling" or "Starter leveling build")
    self.starterLevelInput:SetText(tostring(self.starterLevel or 60))
    self.starterLearn:SetEnabled(full ~= nil and full.verified); self.starterCustomize:SetEnabled(full ~= nil and full.verified)
    self.starterDetails:SetText(data and ("Reference: Icy Veins • Forever\n" .. data.tip) or "No starter available for this class.")
    self.starterSource:SetText(data and data.source or "")
    if not full then
        self.starterSchedule:SetText(reason or "Talent data unavailable."); self.starterMilestone:SetText(""); return
    end
    local level = self.starterLevel or 60
    local first = math.max(1, math.min(46, level - 9))
    local lines = {}
    for index = first, math.min(first + 5, #full.sequence) do
        local step = full.sequence[index]
        lines[#lines + 1] = (index + 9 == level and "> " or "") .. "Level " .. (index + 9) .. ": "
            .. self.model.nodes[step.node].entries[step.entry].name .. " (" .. step.rank .. ")"
    end
    self.starterSchedule:SetText(table.concat(lines, "\n"))
    local milestone = "This path adds points without a planned respec."
    for index, step in ipairs(full.sequence) do
        local entry = self.model.nodes[step.node].entries[step.entry]
        if index + 9 > level and entry.max == 1 then
            milestone = "Next milestone: level " .. (index + 9) .. "\n" .. entry.name; break
        end
    end
    self.starterMilestone:SetText(milestone)
end

function Planner:CloseStarterPanel()
    if InCombatLockdown() then return end
    if self.starterLevelInput then self.starterLevelInput:ClearFocus() end
    if self.starterSource then self.starterSource:ClearFocus() end
    if self.starterPanel then self.starterPanel:Hide() end
end

function Planner:OpenStarterPanel()
    if not self:Ready() then return end
    self:StopGuide(); self:CloseNotes(); self:CloseOrder()
    if not self.starterPanel then
        local frame = CreateFrame("Frame", nil, self.panel, "BackdropTemplate"); self.starterPanel = frame
        frame:SetAllPoints(self.panel); frame:SetFrameLevel(self.panel:GetFrameLevel() + 25)
        frame:EnableMouse(true); Surface(frame); frame:SetBackdropColor(0.035, 0.05, 0.065, 1)
        self.starterTitle = Label(frame, 17, 14, -16, "")
        Label(frame, 11, 14, -48, "Compare your talents as you browse levels.")
        local timing = Label(frame, 10, 14, -65, "Reference schedule; bonus points may differ.")
        timing:SetWordWrap(false)
        Button(frame, 14, -82, 52, "<", function() self:ChooseStarterLevel(math.max(1, (self.starterLevel or 60) - 1)) end)
        self.starterLevelInput = Input(frame, 114, -82, 48, 2)
        Label(frame, 11, 72, -89, "Level", 40)
        self.starterLevelInput:SetScript("OnEnterPressed", function(box)
            self:ChooseStarterLevel(tonumber(box:GetText())); box:ClearFocus()
        end)
        Button(frame, 210, -82, 52, ">", function() self:ChooseStarterLevel(math.min(60, (self.starterLevel or 1) + 1)) end)
        Button(frame, 14, -118, 120, "My level", function()
            local level = self:Budget()
            if Suite.IsReadable(level) and type(level) == "number" then self:ChooseStarterLevel(math.max(1, math.min(60, level))) end
        end)
        Button(frame, 142, -118, 120, "Full build", function() self:ChooseStarterLevel(60) end)
        self.starterSchedule = Label(frame, 12, 14, -166, "", 248); self.starterSchedule:SetHeight(146)
        self.starterMilestone = Label(frame, 11, 14, -320, "", 248); self.starterMilestone:SetHeight(46)
        self.starterDetails = Label(frame, 11, 14, -378, "", 248); self.starterDetails:SetHeight(90)
        Label(frame, 10, 14, -482, "Source guide (select and copy URL)")
        self.starterSource = Input(frame, 14, -500, 248, 256)
        self.starterLearn = Button(frame, 14, -542, 248, "Learn this build", function() self:StartGuide() end)
        self.starterCustomize = Button(frame, 14, -578, 248, "Customize a copy", function() self:CustomizeStarter() end)
        Button(frame, 14, -614, 248, "Back to my builds", function()
            self:StopGuide(); self.starter, self.preview = false, false; frame:Hide(); self:Render()
        end)
    end
    local level = self:Budget()
    if not self.starter then self.starterLevel = type(level) == "number" and math.max(1, math.min(60, level)) or 10 end
    self.starter, self.preview, self.expanded = true, true, true
    self.notice = nil; self.starterPanel:Show(); self:Render(); self:RenderStarterPanel()
end

function Planner:ShowGuideInstruction(step, message, reference)
    if InCombatLockdown() or not self:Ready() then return end
    if not self.guideInstruction then
        local frame = CreateFrame("Frame", nil, self.root, "BackdropTemplate")
        self.guideInstruction = frame; frame:SetFrameLevel(3002)
        frame:EnableMouse(false); frame:EnableMouseWheel(false)
        frame:SetPoint("TOPLEFT", self.model.host.ClassBackground, "TOPLEFT", 12, -4)
        frame:SetSize(700, 38); Surface(frame)
        frame.caption = Label(frame, 12, 8, -5, "", 684); frame.caption:SetHeight(30)
    end
    local instruction = message or "Choose a saved build."
    if step then
        instruction = "Click the gold-outlined talent: " .. self.model.nodes[step.node].entries[step.entry].name
            .. " (rank " .. step.rank .. ").\nThen click the game's Apply Changes button below the tree."
    elseif not reference and self.model.staged then
        instruction = "Talent selected. Click Apply Changes below the tree to confirm, or undo the pending changes."
    end
    self.guideInstruction:SetHeight(38); self.guideInstruction.caption:SetHeight(30)
    self.guideInstruction.caption:SetText(instruction); self.guideInstruction:Show()
end
function Planner:RenderGuideMarks()
    if InCombatLockdown() or not self:Ready() then return end
    local comparison = self:GuideComparison()
    local host = self.model.host
    if not comparison or type(host.GetTalentButtonByNodeID) ~= "function" then return end
    self.guideMarks = self.guideMarks or {}
    for id, value in pairs(comparison) do
        local ok, native = pcall(host.GetTalentButtonByNodeID, host, id)
        if ok and Accessible(native) then
            local shown = native:IsShown()
            if Suite.IsReadable(shown) and shown == true then
                local mark = self.guideMarks[id]
                if not mark then
                    mark = CreateFrame("Frame", nil, self.root, "BackdropTemplate")
                    self.guideMarks[id] = mark
                    mark:SetFrameLevel(3002); mark:EnableMouse(false); mark:EnableMouseWheel(false)
                    mark:SetSize(32, 21); Surface(mark)
                    mark.caption = Label(mark, 12, 1, -3, "", 30)
                    mark.caption:SetJustifyH("CENTER"); mark.caption:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
                end
                local r, g, b = 0.65, 0.85, 0.9
                if value.kind == "conflict" then r, g, b = 1, 0.3, 0.25
                elseif value.kind == "complete" then r, g, b = 0.4, 0.9, 0.55 end
                mark.caption:SetText(value.text); mark.caption:SetTextColor(r, g, b)
                mark:SetBackdropBorderColor(r, g, b, 1)
                mark:ClearAllPoints(); mark:SetPoint("TOPLEFT", native, "TOPRIGHT", 5, 0)
                mark:Show()
            end
        end
    end
end

function Planner:HighlightGuide(step, caption)
    if InCombatLockdown() or not self:Ready() then return end
    local host = self.model.host
    if type(host.GetTalentButtonByNodeID) ~= "function" then return end
    local ok, native = pcall(host.GetTalentButtonByNodeID, host, step.node)
    if not ok or not Accessible(native) then return end
    local shown = native:IsShown()
    if not Suite.IsReadable(shown) or shown ~= true then return end
    if not self.guideHighlight then
        local frame = CreateFrame("Frame", nil, self.root, "BackdropTemplate"); self.guideHighlight = frame
        -- Rank badges sit above the outline where their corners overlap.
        frame:SetFrameLevel(3001); frame:EnableMouse(false); frame:EnableMouseWheel(false)
        frame:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 })
        Suite.Theme:Backdrop(frame, 1, {r=1,g=0.78,b=0.25})
        frame.label = Label(frame, 10, 0, 0, "NEXT", 50)
        frame.label:ClearAllPoints(); frame.label:SetPoint("BOTTOM", frame, "TOP", 0, 2)
        frame.label:SetJustifyH("CENTER"); frame.label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        frame.label:SetTextColor(1, 0.78, 0.25)
    end
    self.guideHighlight:ClearAllPoints()
    self.guideHighlight.label:SetText(caption or "NEXT")
    self.guideHighlight:SetPoint("TOPLEFT", native, "TOPLEFT", -5, 5)
    self.guideHighlight:SetPoint("BOTTOMRIGHT", native, "BOTTOMRIGHT", 5, -5)
    self.guideHighlight:Show()
end

function Planner:CloseOrder()
    if InCombatLockdown() then return end
    if self.orderFrame then self.orderFrame:Hide() end
    self.orderBuild, self.orderDraft = nil, nil
end
function Planner:RenderOrder()
    if not self:Ready() or not self.orderDraft or self.orderBuild ~= self:Current() then return end
    local pages = math.max(1, math.ceil(#self.orderDraft / 10))
    self.orderPage = math.min(self.orderPage or 1, pages)
    self.orderPageText:SetText(self.orderPage .. " / " .. pages)
    self.orderPrevious:SetEnabled(self.orderPage > 1); self.orderNext:SetEnabled(self.orderPage < pages)
    for index, row in ipairs(self.orderRows) do
        local position = (self.orderPage - 1) * 10 + index
        local step = self.orderDraft[position]; row:SetShown(step ~= nil)
        if step then
            local entry = self.model.nodes[step.node].entries[step.entry]
            row.caption:SetText((position == self.orderSelected and "> " or "") .. position .. ". " .. entry.name .. " (" .. step.rank .. ")")
        end
    end
    self.orderUp:SetEnabled(self.orderSelected ~= nil and self.orderSelected > 1)
    self.orderDown:SetEnabled(self.orderSelected ~= nil and self.orderSelected < #self.orderDraft)
end
function Planner:MoveOrder(delta)
    if not self:Ready() or self.orderBuild ~= self:Current() or not self.orderSelected then return end
    local target = self.orderSelected + delta
    if target < 1 or target > #self.orderDraft then return end
    local order = Suite.Copy(self.orderDraft)
    order[target], order[self.orderSelected] = order[self.orderSelected], order[target]
    local clean, reason = self:ValidateOrder(self:Current().ranks, order)
    if not clean then self.orderStatus:SetText(reason); return end
    self.orderDraft, self.orderSelected = clean, target
    self.orderPage = math.ceil(target / 10); self.orderStatus:SetText("Order edits are saved when you click Save."); self:RenderOrder()
end
function Planner:OpenOrder()
    if not self:Ready() or self.starter or not self:Current() then return end
    local order = self:Sequence(self:Current())
    if not order then self:Message("Resolve this draft's requirements before editing its order."); return end
    self:CloseNotes()
    if not self.orderFrame then
        local frame = CreateFrame("Frame", nil, self.panel, "BackdropTemplate"); self.orderFrame = frame
        frame:SetAllPoints(self.panel); frame:SetFrameLevel(self.panel:GetFrameLevel() + 20)
        Surface(frame); frame:SetBackdropColor(0.035, 0.05, 0.065, 1); frame:EnableMouse(true)
        Label(frame, 17, 14, -16, "Leveling order")
        Label(frame, 11, 14, -46, "Each step spends one point.\nRanks and prerequisites stay in order.")
        self.orderRows = {}
        for index = 1, 10 do
            local row = Button(frame, 14, -100 - (index - 1) * 29, 248, "", function()
                self.orderSelected = (self.orderPage - 1) * 10 + index; self:RenderOrder()
            end)
            row.caption:SetJustifyH("LEFT"); self.orderRows[index] = row
        end
        self.orderPrevious = Button(frame, 14, -404, 56, "<", function() self.orderPage = math.max(1, self.orderPage - 1); self:RenderOrder() end)
        self.orderPageText = Label(frame, 11, 82, -412, "", 98); self.orderPageText:SetJustifyH("CENTER")
        self.orderNext = Button(frame, 206, -404, 56, ">", function() self.orderPage = self.orderPage + 1; self:RenderOrder() end)
        self.orderUp = Button(frame, 14, -442, 120, "Move earlier", function() self:MoveOrder(-1) end)
        self.orderDown = Button(frame, 142, -442, 120, "Move later", function() self:MoveOrder(1) end)
        Button(frame, 14, -480, 248, "Generate order", function()
            if not self:Ready() or self.orderBuild ~= self:Current() then return end
            local generated = self:BuildSequence(self:Current().ranks)
            if generated then self.orderDraft, self.orderPage, self.orderSelected = generated, 1, nil; self:RenderOrder() end
        end)
        self.orderStatus = Label(frame, 10, 14, -520, "", 248); self.orderStatus:SetHeight(42)
        self.orderSave = Button(frame, 14, -578, 120, "Save order", function()
            if self.orderBuild == self:Current() then
                if self:SaveOrder(self.orderDraft) then self:CloseOrder()
                else self.orderStatus:SetText(self.notice or "Unable to save this order.") end
            end
        end)
        self.orderCancel = Button(frame, 142, -578, 120, "Cancel", function() self:CloseOrder() end)
    end
    self.orderBuild, self.orderDraft, self.orderPage, self.orderSelected = self:Current(), Suite.Copy(order), 1, nil
    self.orderStatus:SetText("Select a step to move it. This does not learn talents.")
    self:RenderOrder(); self.orderFrame:Show()
end

function Planner:CloseNotes()
    if InCombatLockdown() then return end
    if self.notesEdit then self.notesEdit:ClearFocus() end
    if self.notesFrame then self.notesFrame:Hide() end
    self.notesBuild = nil
end
function Planner:OpenNotes()
    if self.starter then return end
    if not self:Ready() or not self:Current() then return end
    self:CloseOrder()
    if not self.notesFrame then
        local frame = CreateFrame("Frame", nil, self.panel, "BackdropTemplate")
        self.notesFrame = frame; frame:SetAllPoints(self.panel); frame:SetFrameLevel(self.panel:GetFrameLevel() + 20)
        Surface(frame); frame:SetBackdropColor(0.035, 0.05, 0.065, 1); frame:EnableMouse(true)
        Label(frame, 17, 14, -16, "Build notes")
        self.notesTitle = Label(frame, 11, 14, -44, "", 248)
        self.notesTitle:SetWordWrap(false)
        Label(frame, 10, 14, -70, "Up to 512 characters. Save when finished.", 248)
        local scroll = CreateFrame("ScrollFrame", nil, frame, "InputScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 14, -100); scroll:SetPoint("BOTTOMRIGHT", -34, 90)
        if scroll.CharCount then scroll.CharCount:Hide() end
        self.notesEdit = scroll.EditBox
        self.notesEdit:SetMultiLine(true); self.notesEdit:SetAutoFocus(false); self.notesEdit:SetMaxLetters(512)
        self.notesEdit:SetWidth(224); self.notesEdit:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        self.notesEdit:SetScript("OnEscapePressed", function() self:CloseNotes() end)
        local save = Button(frame, 14, -550, 120, "Save notes", function()
            if self:Ready() and self.notesBuild == self:Current() then
                if self:SetNotes(self.notesEdit:GetText()) then self:CloseNotes()
                else self.notesStatus:SetText(self.notice or "Unable to save these notes.") end
            end
        end)
        local cancel = Button(frame, 142, -550, 120, "Cancel", function() self:CloseNotes() end)
        save:SetFrameLevel(self.notesEdit:GetFrameLevel() + 2); cancel:SetFrameLevel(self.notesEdit:GetFrameLevel() + 2)
        self.notesSave, self.notesCancel = save, cancel
        self.notesStatus = Label(frame, 10, 14, -593, "", 248)
    end
    self.notesBuild = self:Current(); self.notesTitle:SetText(self.notesBuild.name)
    self.notesStatus:SetText("Notes stay with this saved build.")
    self.notesEdit:SetText(self.notesBuild.notes); self.notesFrame:Show(); self.notesEdit:SetFocus()
end

function Planner:RenderNode(id, node, draft, level, budget)
    local host = self.model.host
    if type(host.GetTalentButtonByNodeID) ~= "function" then return end
    local ok, nativeButton = pcall(host.GetTalentButtonByNodeID, host, id)
    if not ok or not Accessible(nativeButton) then return end
    local shownOK, shown = pcall(nativeButton.IsShown, nativeButton)
    if not shownOK or not Suite.IsReadable(shown) or shown ~= true then return end
    local button = self.buttons[id]
    if not button then
        button = CreateFrame("Button", nil, self.overlay, "BackdropTemplate")
        self.buttons[id] = button; button.nodeID = id
        Surface(button); button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button.icon = button:CreateTexture(nil, "ARTWORK"); button.icon:SetPoint("TOPLEFT", 3, -3); button.icon:SetPoint("BOTTOMRIGHT", -3, 3)
        button.rank = Label(button, 11, 0, -24, "", 40); button.rank:SetJustifyH("CENTER")
        button.rank:ClearAllPoints(); button.rank:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
        button.rank:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        button:SetScript("OnClick", function(_, mouse)
            if InCombatLockdown() then return end
            self:Change(id, mouse == "RightButton" and -1 or 1, mouse == "LeftButton" and IsShiftKeyDown())
        end)
        button:SetScript("OnEnter", function() self:Tooltip(button) end)
        button:SetScript("OnLeave", function()
            if self.tooltipOwner == button and GameTooltip then GameTooltip:Hide(); self.tooltipOwner = nil end
        end)
    end
    button:ClearAllPoints(); button:SetAllPoints(nativeButton)
    local entry = node.entries[draft and draft.entry or node.order[1]]
    button.icon:SetTexture(entry.icon)
    button.icon:SetDesaturated(not draft)
    button.rank:SetText((draft and draft.rank or 0) .. "/" .. entry.max)
    -- Draft spending controls icon color; live allocations do not mark an empty
    -- draft. Availability uses the reconstructed draft, never native isAvailable.
    local r, g, b = 0.55, 0.65, 0.7
    if draft then r, g, b = 0.41, 0.84, 0.75 end
    button.rank:SetTextColor(r, g, b)
    local analysis = self.analysis
    local blocked = analysis and analysis.blocked[id]
    local available = analysis and not blocked and (not draft or draft.rank < entry.max)
        and not self:RuleReason(id, draft and draft.entry or node.order[1], analysis.state, level, self:RulesEnabled())
        and (not self:RulesEnabled() or budget ~= nil and analysis.points < budget)
    if draft and blocked then
        r, g, b = 1, 0.33, 0.3
        button.rank:SetTextColor(r, g, b)
    elseif available then
        r, g, b = 1, 0.62, 0.2
    end
    Suite.Theme:Backdrop(button, 1, { r = r, g = g, b = b })
    button:Show()
end

function Planner:RenderConnections(build)
    -- These are owned overlays. Blizzard retains every original label/edge and
    -- immediately regains the complete native view when the draft is dismissed.
    local headers = self.model.host.treeHeaders
    if Suite.IsReadable(headers) and type(headers) == "table" and #headers <= 8 then
        for index, native in ipairs(headers) do
            local info = Accessible(native) and native.displayInfo
            local group = Suite.IsReadable(info) and type(info) == "table" and info.groupID
            local knownGroup
            if Suite.IsReadable(group) and type(group) == "number" then
                for _, display in ipairs(self.model.groupInfo) do if display.id == group then knownGroup = display; break end end
            end
            local target = knownGroup and native.Text
            if knownGroup and Suite.IsReadable(target) and (type(target) == "table" or type(target) == "userdata") then
                local total = 0
                for id, value in pairs(build.ranks) do
                    for _, member in ipairs(self.model.rules[id].groups) do if member == group then total = total + value.rank; break end end
                end
                local header = self.headers[index]
                if not header then
                    header = CreateFrame("Frame", nil, self.overlay, "BackdropTemplate"); self.headers[index] = header
                    Surface(header); header:SetSize(300, 56); header:SetBackdropColor(0.035, 0.05, 0.065, 1)
                    header.icon = header:CreateTexture(nil, "ARTWORK"); header.icon:SetSize(36, 36)
                    header.icon:SetPoint("LEFT", header, "LEFT", 12, 0)
                    header.name = Label(header, 16, 0, 0, "", 190)
                    header.name:ClearAllPoints(); header.name:SetPoint("LEFT", header, "LEFT", 60, 0); header.name:SetHeight(26)
                    header.name:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
                    header.name:SetTextColor(0.96, 0.97, 0.98); header.name:SetWordWrap(false)
                    header.text = Label(header, 16, 0, 0, "", 40)
                    header.text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE"); header.text:SetTextColor(0.96, 0.97, 0.98)
                    header.text:SetWordWrap(false)
                    header.text:ClearAllPoints(); header.text:SetPoint("LEFT", header.name, "RIGHT", 10, 0)
                    header.text:SetHeight(26); header.text:SetJustifyH("LEFT")
                end
                -- Cover the entire dim native heading, including its old portrait
                -- counter. The owned name and total share one readable line.
                -- Camelot places the native heading at x=140 in each 400-unit
                -- column. Center our 300-unit box at x=200, leaving 50 per side.
                header:ClearAllPoints(); header:SetPoint("CENTER", native, "CENTER", 60, 0)
                header.name:SetText(knownGroup.name)
                header.text:SetText(tostring(total))
                local totalWidth = math.max(1, header.text:GetUnboundedStringWidth())
                local nameWidth = math.min(math.max(1, 180 - 10 - totalWidth), header.name:GetUnboundedStringWidth())
                header.name:SetWidth(nameWidth); header.text:SetWidth(totalWidth)
                header.name:ClearAllPoints()
                header.name:SetPoint("LEFT", header, "CENTER", -(nameWidth + 10 + totalWidth) / 2, 0)
                local icon = info.icon
                if Suite.IsReadable(icon) and type(icon) == "number" and icon > 0 and icon < 100000000 and icon % 1 == 0 then
                    header.icon:SetTexture(icon); header.icon:Show()
                else header.icon:Hide() end
                header:Show()
            end
        end
    end
    for index, data in ipairs(self.model.edges) do
        local source, target = self.buttons[data.from], self.buttons[data.to]
        local from, to = self.model.rules[data.from], self.model.rules[data.to]
        if source and target and source:IsShown() and target:IsShown() and from.x and to.x then
            local edge = self.edgeFrames[index]
            if not edge then
                edge = CreateFrame("Frame", nil, self.overlay); self.edgeFrames[index] = edge; edge:SetAllPoints(self.overlay)
                edge.mask = edge:CreateLine(nil, "BACKGROUND"); edge.mask:SetThickness(12); edge.mask:SetColorTexture(0.015, 0.025, 0.035, 1)
                edge.line = edge:CreateLine(nil, "ARTWORK"); edge.line:SetThickness(2)
                edge.left = edge:CreateLine(nil, "ARTWORK"); edge.left:SetThickness(2)
                edge.right = edge:CreateLine(nil, "ARTWORK"); edge.right:SetThickness(2)
                -- Talent buttons sit over their connecting strokes.
                for _, button in pairs(self.buttons) do button:SetFrameLevel(edge:GetFrameLevel() + 1) end
            end
            local r, g, b = 0.3, 0.34, 0.37
            local sourceRank, targetRank = build.ranks[data.from], build.ranks[data.to]
            local reachable = self.analysis.state.ranks[data.from] or 0
            local enabled = reachable >= (from.firstRank and 1 or self.model.nodes[data.from].max)
            if data.type == 4 then
                if sourceRank and targetRank then r, g, b = 1, 0.33, 0.3 end
            elseif enabled then r, g, b = 0.41, 0.84, 0.75
            elseif targetRank then r, g, b = 1, 0.33, 0.3 end
            for _, line in ipairs({edge.mask, edge.line}) do
                line:SetStartPoint("CENTER", source); line:SetEndPoint("CENTER", target)
            end
            local dx, dy = to.x - from.x, from.y - to.y
            local length = math.sqrt(dx * dx + dy * dy)
            edge.left:Hide(); edge.right:Hide()
            if length > 0 and data.type ~= 4 then
                local nx, ny = dx / length, dy / length
                for _, spec in ipairs({{edge.left, 1}, {edge.right, -1}}) do
                    local line, side = spec[1], spec[2]
                    line:SetStartPoint("CENTER", target, -nx * 22, -ny * 22)
                    line:SetEndPoint("CENTER", target, -nx * 29 - ny * 4 * side, -ny * 29 + nx * 4 * side)
                    line:SetColorTexture(r, g, b, 1); line:Show()
                end
            end
            edge.line:SetColorTexture(r, g, b, 1); edge:Show()
        end
    end
end
