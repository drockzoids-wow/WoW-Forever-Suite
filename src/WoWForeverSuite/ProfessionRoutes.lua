local _, Suite = ...
local Routes = { history = {}, expanded = false }
Suite.ProfessionRoutes = Routes
local function Read(v, kind) return Suite.IsReadable(v) and type(v) == kind end
local function Int(v, low, high) return Read(v, "number") and v >= low and v <= high and v % 1 == 0 end
local function Field(object, key)
    if Suite.IsReadable(object) and (type(object) == "table" or type(object) == "userdata") then
        local ok, value = pcall(function() return object[key] end)
        if ok and Suite.IsReadable(value) then return value end
    end
end
local function Call(fn, ...)
    if not Read(fn, "function") then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Plain(value)
    if not Read(value, "string") or #value > 4096 then return end
    value = value:gsub("|T.-|t", ""):gsub("|H.-|h(.-)|h", "%1"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    if value:find("[|%c]") then value = value:gsub("[\r\n]", " · "); if value:find("[|%c]") then return end end
    if #value > 700 then value = value:sub(1, 680) .. "… See the recipe source." end
    return value ~= "" and value or nil
end
function Routes:Reset()
    self.history, self.holding, self.focusID, self.focusOffset = {}, nil, nil, nil
    Suite.ProfessionLeveling.routeHold = nil
end
function Routes:Output(recipe)
    local output = Int(recipe.recipeID, 1, 2147483647) and Call(Field(C_TradeSkillUI, "GetRecipeOutputItemData"), recipe.recipeID)
    local id = Field(output, "itemID")
    if not Int(id, 1, 2147483647) then id = Suite.ProfessionMaterialIDs[recipe[4]] end
    return Int(id, 1, 2147483647) and id or nil
end
function Routes:Definitions(guide)
    local entries, names = {}, {}
    for index, recipe in ipairs(guide and guide.estimates or {}) do
        if index > 128 then break end
        if Int(recipe.recipeID, 1, 2147483647) and Int(recipe[1], 0, 300) and Int(recipe[2], 1, 300) and Plain(recipe[4]) then
            local entry = entries[recipe.recipeID]
            if not entry then
                entry = { id = recipe.recipeID, name = recipe[4], first = recipe[1], last = recipe[2], recipe = recipe, ranges = {} }
                entries[entry.id] = entry
            else entry.first, entry.last = math.min(entry.first, recipe[1]), math.max(entry.last, recipe[2]) end
            local range = recipe[1] .. "–" .. recipe[2]
            local found = false; for _, previous in ipairs(entry.ranges) do if previous == range then found = true; break end end
            if not found then entry.ranges[#entry.ranges + 1] = range end
            names[recipe[4]] = entry
        end
    end
    return entries, names
end
function Routes:Requirements(id)
    local requirements = Call(Field(C_TradeSkillUI, "GetRecipeRequirements"), id)
    local lines = {}
    if Read(requirements, "table") then for index = 1, math.min(#requirements, 6) do
        local requirement = requirements[index]
        local name, met = Plain(Field(requirement, "name")), Field(requirement, "met")
        if name and Read(met, "boolean") then lines[#lines + 1] = (met and "Met: " or "Needed: ") .. name end
    end end
    return #lines > 0 and "Native requirements: " .. table.concat(lines, " · ") or "Learning requirements unavailable; check the listed source."
end
function Routes:Missing(guide, rank)
    local definitions, names = self:Definitions(guide)
    local wanted = {}
    local function Add(entry, depth)
        if not entry or wanted[entry.id] or depth > 8 then return end
        wanted[entry.id] = true
        for _, material in ipairs(entry.recipe[5] or {}) do Add(names[material[2]], depth + 1) end
    end
    for _, entry in pairs(definitions) do if not Int(rank, 0, 300) or entry.last > rank then Add(entry, 0) end end
    local rows, missing, unknown = {}, 0, 0
    for id in pairs(wanted) do
        local learned = Suite.ProfessionLeveling:RecipeTraining(id)
        if learned ~= true then
            local entry = definitions[id]
            entry.learned, entry.output = learned, self:Output(entry.recipe)
            local reference = Suite.ProfessionRecipeSources[id]
            entry.kind = reference and reference.profession == guide.name and reference.kind or "Native source"
            entry.source = Plain(Suite.ProfessionLeveling:RecipeSource(id)) or "Source unavailable."
            if entry.kind == "Native source" and entry.source:find("^Source unavailable") then entry.kind = "Source unavailable" end
            entry.requirements = self:Requirements(id)
            if learned == false then missing = missing + 1 else unknown = unknown + 1 end
            rows[#rows + 1] = entry
        end
    end
    table.sort(rows, function(a, b) if a.first ~= b.first then return a.first < b.first end; return a.id < b.id end)
    return rows, missing, unknown
end
function Routes:Context()
    local leveling = Suite.ProfessionLeveling
    if InCombatLockdown() or not leveling:Enabled() or not leveling.open or Call(Field(leveling.frame, "IsShown"), leveling.frame) ~= true
        or Call(Field(leveling.owner, "IsShown"), leveling.owner) ~= true then return end
    local index, _, context = leveling:Context()
    if index ~= leveling.selected or not context then return end
    return index, context
end
function Routes:CurrentRecipe()
    local page = Field(Suite.ProfessionLeveling.owner, "CraftingPage")
    local form = Field(page, "SchematicForm")
    local info = Call(Field(form, "GetRecipeInfo"), form)
    local id = Field(info, "recipeID")
    return Int(id, 1, 2147483647) and id or nil
end
function Routes:Navigate(id)
    local leveling = Suite.ProfessionLeveling
    local index, context = self:Context()
    if not index or not Int(id, 1, 2147483647) then return leveling:RecipeMessage("Open this character's profession before selecting an intermediate.") end
    if leveling:RecipeBusy() then return leveling:RecipeMessage("Finish or stop the current crafting batch before navigating recipes.") end
    local before, held = self:CurrentRecipe(), leveling.routeHold
    if not before or leveling:RecipeTraining(before) ~= true then return leveling:RecipeMessage("Select a learned recipe in the profession first so Back can return to it.") end
    if before == id then return leveling:RecipeMessage("This recipe is already selected.") end
    local scroll = leveling.frame.scroll.suiteOffset or 0
    local previous = self.holding
    self.holding, leveling.routeHold = { index = index, context = context }, true
    if not leveling:RequestRecipe(id, index, context, false) then self.holding, leveling.routeHold = previous, held; return false end
    if before and before ~= id then
        if #self.history >= 8 then table.remove(self.history, 1) end
        self.history[#self.history + 1] = { id = before, index = index, context = context,
            scroll = scroll }
    end
    self:UpdateBack()
    leveling:RecipeMessage("Intermediate selected. Craft manually; Back returns to your previous recipe.")
    return true
end
function Routes:Back()
    local leveling = Suite.ProfessionLeveling
    local index, context = self:Context()
    local entry = self.history[#self.history]
    if not index then return false end
    if leveling:RecipeBusy() then return leveling:RecipeMessage("Finish or stop the current crafting batch before navigating recipes.") end
    if not self.holding or self.holding.index ~= index or self.holding.context ~= context then self:Reset(); self:UpdateBack(); return false end
    if entry then
        if entry.index ~= index or entry.context ~= context then self:Reset(); self:UpdateBack(); return false end
        if not leveling:RequestRecipe(entry.id, index, context, false) then return false end
        table.remove(self.history)
        local offset = math.max(0, math.min(entry.scroll, math.max(0, leveling.frame.body:GetHeight() - 350)))
        leveling.frame.scroll.suiteOffset = offset
        leveling.frame.scroll:SetVerticalScroll(offset)
    end
    if #self.history == 0 then self.holding, leveling.routeHold = nil, nil end
    self:UpdateBack()
    leveling:RecipeMessage(entry and "Returned to the previous recipe. Crafting stays manual." or "Returned to the leveling route.")
    return true
end
function Routes:UpdateBack()
    local leveling = Suite.ProfessionLeveling
    local button = leveling.frame and leveling.frame.recipeBack
    if InCombatLockdown() or not button then return end
    button:SetShown(self.holding ~= nil)
    button:SetText(#self.history > 0 and "Back to recipe" or "Back to route")
end
function Routes:MaterialClick(row, button)
    local id = row.materialID
    if Suite.Items:ModifiedClick(id, button) then return true end
    if button ~= "LeftButton" or InCombatLockdown() or not Int(id, 1, 2147483647) then return false end
    local leveling = Suite.ProfessionLeveling
    local guide = Suite.ProfessionGuides[leveling.selected]
    local definitions = self:Definitions(guide)
    local choices = {}
    for _, entry in pairs(definitions) do if self:Output(entry.recipe) == id then choices[#choices + 1] = entry end end
    table.sort(choices, function(a, b) return a.id < b.id end)
    if #choices == 0 then return false end
    local function Choose(entry)
        if leveling:RecipeTraining(entry.id) == true then return self:Navigate(entry.id) end
        self.expanded, self.focusID = true, entry.id
        leveling:Render(false)
    end
    if #choices == 1 then Choose(choices[1]); return true end
    Suite.Menus.CreateContextMenu(row, function(_, root)
        root:CreateTitle("Recipes for this material")
        for _, entry in ipairs(choices) do local choice = entry; root:CreateButton(entry.name, function() Choose(choice) end) end
    end)
    return true
end
local function Label(parent, size, width)
    local label = parent:CreateFontString(nil, "OVERLAY"); label:SetFont("Fonts\\FRIZQT__.TTF", size, "")
    label:SetWidth(width); label:SetJustifyH("LEFT"); label:SetWordWrap(true); label:SetTextColor(0.88, 0.91, 0.93)
    return label
end
function Routes:Render(guide, rank, y)
    local leveling, frame = Suite.ProfessionLeveling, Suite.ProfessionLeveling.frame
    if InCombatLockdown() or not frame then return y end
    if self.body ~= frame.body then
        if self.header then self.header:Hide() end
        if self.empty then self.empty:Hide() end
        for _, widget in ipairs(self.widgets or {}) do widget:Hide() end
        self.body, self.header, self.empty, self.widgets = frame.body, nil, nil, {}
    end
    self:UpdateBack()
    self.widgets = self.widgets or {}
    if self.empty then self.empty:Hide() end
    for _, widget in ipairs(self.widgets) do widget:Hide() end
    if not guide or not guide.estimates then if self.header then self.header:Hide() end; return y end
    local rows, missing, unknown = self:Missing(guide, rank)
    if not self.header then
        self.header = Suite.Theme:ActionButton(frame.body, "", 410, 32, function()
            if InCombatLockdown() then return end
            self.expanded = not self.expanded; leveling:Render(false)
        end)
    end
    self.header:ClearAllPoints(); self.header:SetPoint("TOPLEFT", 0, -y); self.header:Show()
    self.header:SetText((self.expanded and "− " or "+ ") .. "Route recipes · " .. missing .. " missing · " .. unknown .. " unknown")
    y = y + 42
    if not self.expanded then return y end
    if #rows == 0 then
        self.empty = self.empty or Label(frame.body, 11, 410)
        self.empty:ClearAllPoints(); self.empty:SetPoint("TOPLEFT", 0, -y); self.empty:SetText("All remaining route recipes are learned in the open profession."); self.empty:Show()
        return y + 34
    elseif self.empty then self.empty:Hide() end
    for index, entry in ipairs(rows) do
        local widget = self.widgets[index]
        if not widget then
            widget = CreateFrame("Frame", nil, frame.body); widget:SetWidth(410)
            widget.iconButton = CreateFrame("Button", nil, widget); widget.iconButton:SetSize(26, 26); widget.iconButton:SetPoint("TOPLEFT", 0, -2)
            widget.icon = widget.iconButton:CreateTexture(nil, "ARTWORK"); widget.icon:SetSize(24, 24); widget.icon:SetPoint("TOPLEFT")
            widget.iconButton:RegisterForClicks("LeftButtonUp")
            widget.iconButton:SetScript("OnClick", function(_, button) Suite.Items:ModifiedClick(widget.outputID, button) end)
            widget.iconButton:SetScript("OnEnter", function() leveling:ItemTooltip(widget.iconButton) end)
            widget.iconButton:SetScript("OnLeave", function() if leveling.hovered == widget.iconButton then leveling:HideTooltip() end end)
            widget.iconButton:SetScript("OnHide", function() if leveling.hovered == widget.iconButton then leveling:HideTooltip() end end)
            widget.title, widget.detail = Label(widget, 12, 378), Label(widget, 11, 410)
            widget.title:SetPoint("TOPLEFT", 32, -2); widget.detail:SetPoint("TOPLEFT", 0, -34)
            widget.action = Suite.Theme:ActionButton(widget, "Set waypoint", 132, 23, function() leveling:RecipeWaypoint(widget.action) end)
            self.widgets[index] = widget
        end
        widget.expanded = true
        widget.outputID, widget.iconButton.materialID = entry.output, entry.output
        widget.icon:SetTexture(leveling:RecipeIcon(entry.id))
        widget.title:SetText(entry.name .. " · " .. (entry.learned == false and "Not learned" or "Training unknown"))
        widget.title:SetTextColor(unpack(entry.learned == false and { 1, 0.74, 0.44 } or { 0.6, 0.72, 0.76 }))
        local top = math.max(32, widget.title:GetStringHeight() + 6)
        widget.detail:ClearAllPoints(); widget.detail:SetPoint("TOPLEFT", 0, -top)
        widget.detail:SetText("Guide skill " .. table.concat(entry.ranges, ", ") .. " · " .. entry.kind .. "\n" .. entry.source .. "\n" .. entry.requirements)
        local height = top + widget.detail:GetStringHeight() + 8
        widget.action.recipeID, widget.action.guideIndex, widget.action.recipeRow = entry.id, leveling.selected, widget
        local location = entry.learned == false and leveling:RecipeLocation(entry.id, leveling:RecipeSource(entry.id))
        widget.action:SetShown(location ~= nil and location ~= false)
        if location then widget.action:ClearAllPoints(); widget.action:SetPoint("TOPLEFT", 0, -height); height = height + 29 end
        widget:ClearAllPoints(); widget:SetPoint("TOPLEFT", 0, -y); widget:SetHeight(height); widget:Show()
        if self.focusID == entry.id then self.focusOffset = y; self.focusID = nil end
        y = y + height + 12
    end
    return y
end
function Routes:AfterRender()
    if self.focusOffset == nil then return end
    local frame = Suite.ProfessionLeveling.frame
    local offset = math.max(0, math.min(self.focusOffset, math.max(0, frame.body:GetHeight() - 350)))
    self.focusOffset = nil; frame.scroll.suiteOffset = offset; frame.scroll:SetVerticalScroll(offset)
end
