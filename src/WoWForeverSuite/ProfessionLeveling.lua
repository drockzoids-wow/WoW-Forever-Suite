local _, Suite = ...
local Leveling = {}
Suite.ProfessionLeveling = Leveling
table.insert(Suite.modules, Leveling)
local guides = Suite.ProfessionGuides
local WIDTH, CONTENT_WIDTH = 460, 410
local function Read(value, kind) return Suite.IsReadable(value) and type(value) == kind end
local function Number(value) return Read(value, "number") and value == value and value >= 0 and value < math.huge end
local function Text(value) return Read(value, "string") and #value > 0 and #value <= 160 and not value:find("[%c|]") end
local function Field(object, key)
    if not Suite.IsReadable(object) or (type(object) ~= "table" and type(object) ~= "userdata") then return end
    local ok, value = pcall(function() return object[key] end)
    if ok and Suite.IsReadable(value) then return value end
end
local function Call(fn, ...)
    if not Read(fn, "function") then return end
    local ok, value = pcall(fn, ...)
    if ok and Suite.IsReadable(value) then return value end
end
local function Safe(frame)
    if not Suite.IsReadable(frame) or not frame then return false end
    local forbidden = Field(frame, "IsForbidden")
    return Read(Field(frame, "GetObjectType"), "function")
        and (not forbidden or Call(forbidden, frame) == false)
end
local function Shown(frame) return Safe(frame) and Call(Field(frame, "IsShown"), frame) == true end
local function Label(parent, size, x, y, width)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", size, "")
    label:SetTextColor(0.88, 0.91, 0.93); label:SetJustifyH("LEFT")
    label:SetPoint("TOPLEFT", x, y); label:SetWidth(width); label:SetWordWrap(true)
    return label
end
local function Surface(frame)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.035, 0.05, 0.065, 0.98); Suite.Theme:Backdrop(frame, 0.85)
end
local function Button(parent, text, width, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 23); button:SetText(text)
    button:SetScript("OnClick", function() if not InCombatLockdown() then callback() end end)
    return button
end
function Leveling:Enabled() return Suite.db and Read(Suite.db.professionLeveling, "boolean") and Suite.db.professionLeveling == true end
function Leveling:Resolve(info)
    if not Read(info, "table") then return end
    local profession, name = Field(info, "profession"), Field(info, "professionName")
    local enums = Field(Enum, "Profession")
    for index, guide in ipairs(guides) do
        local enum = guide.enum and Field(enums, guide.enum)
        if Number(profession) and Number(enum) and profession == enum then return index end
    end
    -- English fallback for clients lacking the enum, including the Lockpicking entry.
    if Text(name) then for index, guide in ipairs(guides) do if name == guide.name then return index end end end
end
function Leveling:Context()
    if not Safe(self.owner) or not Shown(Field(self.owner, "CraftingPage")) then return end
    local info = Call(Field(C_TradeSkillUI, "GetBaseProfessionInfo"))
    if not Read(info, "table") then return nil, nil, "unavailable" end
    local index = self:Resolve(info)
    local rank, maximum = Field(info, "skillLevel"), Field(info, "maxSkillLevel")
    if not Number(rank) or not Number(maximum) or rank % 1 ~= 0 or maximum % 1 ~= 0
        or rank > maximum or maximum > 10000 then rank, maximum = nil, nil end
    local name = Field(info, "professionName")
    local id = Field(info, "professionID")
    local key = Number(id) and tostring(id) or Text(name) and name or "unavailable"
    return index, rank, key, maximum
end
function Leveling:ViewOption(key)
    local value = Suite.db and Suite.db[key]
    return Read(value, "boolean") and value == true
end
function Leveling:ToggleView(key)
    if not self:Enabled() or InCombatLockdown() or not self.open then return end
    if key ~= "professionLevelingHideDone" and key ~= "professionLevelingAutoSteps" and key ~= "professionLevelingHideStocked" then return end
    Suite.db[key] = not self:ViewOption(key)
    if key == "professionLevelingAutoSteps" then self.stepOverrides = {} end
    self:Render(true)
end
local function CurrentSection(section, rank)
    return Number(rank) and rank >= section[1] and (rank < section[2] or rank == 300 and section[2] == 300)
end
function Leveling:Faction()
    local faction = Call(UnitFactionGroup, "player")
    if Read(faction, "string") and (faction == "Alliance" or faction == "Horde") then return faction end
end
function Leveling:StepDetail(section)
    local detail = section[4]
    if section[5] then detail = detail .. "\n|cffe6bf7a" .. section[5] .. "|r" end
    if section[6] then detail = detail .. "\n|cffffbd70" .. section[6] .. "|r" end
    if section.locations then
        local faction = self:Faction()
        local location = faction and section.locations[faction]
        detail = detail .. "\n|cffe6bf7a" .. (location or "See source for faction-specific locations.") .. "|r"
    end
    return detail
end
function Leveling:StepEstimates(guide, section, rank)
    local results = {}
    for _, recipe in ipairs(guide.estimates or {}) do
        if recipe[1] >= section[1] and recipe[1] < section[2] then
            local done = Number(rank) and rank >= recipe[2]
            if not done or not self:ViewOption("professionLevelingHideDone") then
                local crafts = recipe[3]
                if Number(rank) and rank >= recipe[1] and rank < recipe[2] then
                    crafts = math.ceil(recipe[3] * (recipe[2] - rank) / (recipe[2] - recipe[1]))
                end
                local estimate = { recipe = recipe[4], crafts = crafts, target = recipe[2], done = done,
                    produced = crafts * (recipe[6] or 1), recipeID = recipe.recipeID, materials = {} }
                for _, reagent in ipairs(recipe[5]) do
                    local name = reagent[2]
                    local id = Suite.ProfessionMaterialIDs[name] or Call(Field(C_Item, "GetItemInfoInstant"), name)
                    if not Number(id) or id % 1 ~= 0 or id <= 0 or id > 2147483647 then id = nil end
                    estimate.materials[#estimate.materials + 1] = { count = reagent[1] * crafts, id = id, name = name }
                end
                results[#results + 1] = estimate
            end
        end
    end
    return results
end
function Leveling:RecipeMessage(message)
    if self.frame and not InCombatLockdown() then self.frame.status:SetText(message) end
    return false
end
function Leveling:SelectGuideRecipe(button)
    if InCombatLockdown() or not self:Enabled() or not self.open or not Shown(self.owner)
        or not Shown(self.frame) or not Shown(button) then return false end
    local recipeRow = Field(button, "recipeRow")
    if not Shown(recipeRow) or Field(recipeRow, "expanded") ~= true then return false end
    local id, guideIndex = Field(button, "recipeID"), Field(button, "guideIndex")
    if not Number(id) or id <= 0 or id % 1 ~= 0 or id > 2147483647
        or not Number(guideIndex) or guideIndex % 1 ~= 0 or not guides[guideIndex] then return false end
    local current, _, context = self:Context()
    if current ~= guideIndex or self.selected ~= guideIndex then return self:RecipeMessage("Open this profession before selecting its recipes.") end
    return self:RequestRecipe(id, guideIndex, context, false)
end
function Leveling:RequestRecipe(id, guideIndex, context, automatic, expectedRank)
    local _, initialRank = self:Context()
    if automatic and initialRank ~= expectedRank then return false end
    local getInfo, inSkill, openRecipe = Field(C_TradeSkillUI, "GetRecipeInfo"),
        Field(C_TradeSkillUI, "IsRecipeInSkillLine"), Field(C_TradeSkillUI, "OpenRecipe")
    if not Read(getInfo, "function") or not Read(inSkill, "function") or not Read(openRecipe, "function") then
        return self:RecipeMessage("Recipe selection is unavailable in this client.")
    end
    local changing = Field(C_TradeSkillUI, "IsDataSourceChanging")
    if Read(changing, "function") and Call(changing) ~= false then
        return self:RecipeMessage("Profession data is loading. Try again shortly.")
    end
    local profession = Call(Field(C_TradeSkillUI, "GetBaseProfessionInfo"))
    local skillLine = Field(profession, "professionID")
    local info = Call(getInfo, id)
    local nativeID = Field(info, "recipeID")
    if not Number(skillLine) or skillLine % 1 ~= 0 or skillLine <= 0 or skillLine > 2147483647 or not Number(nativeID)
        or nativeID ~= id or Call(inSkill, id, skillLine) ~= true then
        return self:RecipeMessage("Recipe unavailable in the open profession.")
    end
    if automatic and (Field(info, "learned") ~= true or Field(info, "canSkillUp") ~= true) then return false end
    -- Revalidate after native reads; never replay a click after combat/context changes.
    local fresh, freshRank, freshContext = self:Context()
    if InCombatLockdown() or not self:Enabled() or not Shown(self.owner)
        or fresh ~= guideIndex or freshContext ~= context then return false end
    if automatic then
        if not self:ViewOption("professionLevelingAutoRecipe") or self.autoBlocked or self.autoCrafting or freshRank ~= initialRank then return false end
        -- Set before OpenRecipe: native responses may immediately cause another refresh.
        self.autoAttempt = context .. ":" .. tostring(id)
    elseif not self.open or not Shown(self.frame) or self.selected ~= guideIndex then return false end
    local ok, result = pcall(openRecipe, id)
    if not ok or not Suite.IsReadable(result) or result == false then
        return self:RecipeMessage("Recipe unavailable. Select it in the profession window.")
    end
    if not InCombatLockdown() and self.open then self.frame.status:SetText("Opening recipe…") end
    return true
end
function Leveling:AutoSelectRecipe()
    if not self:ViewOption("professionLevelingAutoRecipe") then self.autoAttempt = nil; return end
    if InCombatLockdown() or self.autoBlocked or self.autoCrafting or not Shown(self.owner) then return end
    local index, rank, context = self:Context()
    if not index or not Number(rank) then return end
    -- Never drive a linked, guild or NPC profession rather than this character's book.
    for _, name in ipairs({ "IsTradeSkillLinked", "IsTradeSkillGuild", "IsTradeSkillGuildMember", "IsNPCCrafting" }) do
        local fn = Field(C_TradeSkillUI, name)
        if Read(fn, "function") and Call(fn) ~= false then return end
    end
    for _, name in ipairs({ "UnitCastingInfo", "UnitChannelInfo" }) do
        local fn = name == "UnitCastingInfo" and UnitCastingInfo or UnitChannelInfo
        if Read(fn, "function") then
            local ok, cast = pcall(fn, "player")
            if not ok or not Suite.IsReadable(cast) or cast ~= nil then return end
        end
    end
    local target
    for _, recipe in ipairs(guides[index].estimates or {}) do
        if rank >= recipe[1] and rank < recipe[2] and Number(recipe.recipeID) then target = recipe.recipeID; break end
    end
    local token = target and context .. ":" .. tostring(target)
    if token ~= self.autoTarget then self.autoTarget, self.autoAttempt = token, nil end
    if target and self.autoAttempt ~= token then self:RequestRecipe(target, index, context, true, rank) end
end
function Leveling:StepMaterials(row, estimates, y, expanded)
    row.estimateLabels, row.estimateItems, row.recipeButtons = row.estimateLabels or {}, row.estimateItems or {}, row.recipeButtons or {}
    for _, label in ipairs(row.estimateLabels) do label:Hide() end
    for _, item in ipairs(row.estimateItems) do item.materialID = nil; item:Hide() end
    for _, button in ipairs(row.recipeButtons) do button.recipeID, button.guideIndex = nil, nil; button:Hide() end
    if row.estimateColumns then row.estimateColumns:Hide() end
    if not expanded or #estimates == 0 then return y end
    local labelIndex, itemIndex = 0, 0
    local function Note(text)
        labelIndex = labelIndex + 1
        local label = row.estimateLabels[labelIndex]
        if not label then label = Label(row, 12, 0, 0, CONTENT_WIDTH); row.estimateLabels[labelIndex] = label end
        label:ClearAllPoints(); label:SetPoint("TOPLEFT", 0, -y); label:SetText(text); label:Show()
        y = y + label:GetStringHeight() + 8
    end
    Note("Click a recipe name to select it in the open profession. Crafting stays manual. Estimates may vary; keep intermediate supplies.")
    if not row.estimateColumns then
        row.estimateColumns = CreateFrame("Frame", nil, row); row.estimateColumns:SetSize(CONTENT_WIDTH, 22)
        Label(row.estimateColumns, 11, 0, -3, 252):SetText("Required for this step")
        Label(row.estimateColumns, 11, 264, -3, 68):SetText("Have")
        Label(row.estimateColumns, 11, 340, -3, 70):SetText("Need")
    end
    row.estimateColumns:ClearAllPoints(); row.estimateColumns:SetPoint("TOPLEFT", 0, -y); row.estimateColumns:Show()
    y = y + 22
    for recipeIndex, estimate in ipairs(estimates) do
        local button = row.recipeButtons[recipeIndex]
        if not button then
            button = CreateFrame("Button", nil, row); button:EnableMouse(true); button:RegisterForClicks("LeftButtonUp")
            button.label = Label(button, 12, 0, -3, CONTENT_WIDTH)
            local highlight = button:CreateTexture(nil, "HIGHLIGHT"); highlight:SetAllPoints()
            highlight:SetColorTexture(0.41, 0.84, 0.75, 0.12)
            button:SetScript("OnClick", function(_, mouseButton)
                if mouseButton == nil or mouseButton == "LeftButton" then self:SelectGuideRecipe(button) end
            end)
            row.recipeButtons[recipeIndex] = button
        end
        button.recipeID, button.guideIndex, button.recipeRow = estimate.recipeID, self.selected, row
        button.label:SetText(estimate.recipe .. " · " .. (estimate.done and "Done · full-band reference" or "estimated " .. estimate.crafts .. " crafts to " .. estimate.target))
        local available = self.selected == self.current and Number(estimate.recipeID)
            and Read(Field(C_TradeSkillUI, "GetRecipeInfo"), "function")
            and Read(Field(C_TradeSkillUI, "IsRecipeInSkillLine"), "function") and Read(Field(C_TradeSkillUI, "OpenRecipe"), "function")
        button:SetEnabled(available == true)
        button.label:SetTextColor(unpack(available and {0.41,0.84,0.75} or {0.55,0.65,0.7}))
        local recipeHeight = math.max(24, button.label:GetStringHeight() + 6)
        button:SetSize(CONTENT_WIDTH, recipeHeight); button:ClearAllPoints(); button:SetPoint("TOPLEFT", 0, -y); button:Show()
        y = y + recipeHeight + 8
        for _, material in ipairs(estimate.materials) do
            itemIndex = itemIndex + 1
            local item = row.estimateItems[itemIndex]
            if not item then
                item = CreateFrame("Button", nil, row); item:EnableMouse(true)
                item.label = Label(item, 13, 0, -3, 252)
                item.have = Label(item, 11, 264, -4, 68)
                item.need = Label(item, 11, 358, -4, 52)
                item.check = item:CreateTexture(nil, "OVERLAY")
                item.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready"); item.check:SetSize(14, 14)
                item.check:SetPoint("TOPLEFT", 340, -3)
                item:SetScript("OnEnter", function() self:ItemTooltip(item) end)
                local function Leave() if self.hovered == item then self:HideTooltip() end end
                item:SetScript("OnLeave", Leave); item:SetScript("OnHide", Leave)
                row.estimateItems[itemIndex] = item
            end
            item.materialID = material.id
            item.label:SetText("|cffe6bf7a" .. material.count .. " x|r " .. material.name)
            local have, need, sufficient = self:Stock(material.id, material.count)
            item.have:SetText(have); item.need:SetText(estimate.done and "Done" or need)
            item.check:SetShown(sufficient and not estimate.done)
            item.need:SetTextColor(unpack(sufficient and {0.41,0.84,0.75} or {1,0.74,0.44}))
            local height = math.max(24, item.label:GetStringHeight() + 6, item.have:GetStringHeight() + 8, item.need:GetStringHeight() + 8)
            item:SetSize(CONTENT_WIDTH, height); item:ClearAllPoints(); item:SetPoint("TOPLEFT", 0, -y); item:Show()
            y = y + height
        end
        y = y + 8
    end
    return y
end
function Leveling:ToggleStep(index)
    if not self:Enabled() or InCombatLockdown() or not self.open then return end
    local row = self.frame and self.frame.stepRows and self.frame.stepRows[index]
    if not row or not Shown(row) or not row.sectionIndex then return end
    self.stepOverrides = self.stepOverrides or {}
    self.stepOverrides[index] = not row.expanded
    self:Render(false)
end
function Leveling:Steps(guide, rank, offset)
    local frame = self.frame
    frame.stepRows = frame.stepRows or {}
    for _, row in ipairs(frame.stepRows) do row.sectionIndex = nil; row:Hide() end
    local active = 0
    if guide then
        for index, section in ipairs(guide.sections) do if CurrentSection(section, rank) then active = index; break end end
    end
    local context = tostring(self.selected or 0) .. ":" .. active
    if self.stepContext ~= context then self.stepContext, self.stepOverrides = context, {} end
    frame.text:ClearAllPoints(); frame.text:SetPoint("TOPLEFT", 0, -offset)
    frame.text:SetText(guide and guide.note or "No summary for this profession. Choose a guide above to browse the library.")
    local y = offset + frame.text:GetStringHeight() + 14
    if not guide then return y end
    for index, section in ipairs(guide.sections) do
        local row = frame.stepRows[index]
        if not row then
            row = CreateFrame("Frame", nil, frame.body); row:SetWidth(CONTENT_WIDTH)
            row.header = CreateFrame("Button", nil, row); row.header:SetSize(CONTENT_WIDTH, 26)
            row.header:SetPoint("TOPLEFT"); row.header:EnableMouse(true)
            row.marker = Label(row.header, 13, 0, -4, 16)
            row.heading = Label(row.header, 13, 20, -4, CONTENT_WIDTH - 20)
            row.detail = Label(row, 13, 0, -32, CONTENT_WIDTH); row.detail:SetSpacing(4)
            row.header:SetScript("OnClick", function() self:ToggleStep(index) end)
            frame.stepRows[index] = row
        end
        local current = CurrentSection(section, rank)
        local done = Number(rank) and rank >= section[2] and not current
        local expanded = not Number(rank) or not self:ViewOption("professionLevelingAutoSteps") or current
        if self.stepOverrides[index] ~= nil then expanded = self.stepOverrides[index] end
        row.sectionIndex, row.expanded = index, expanded
        local title = guide.name == "Camping" and section[3] or section[1] .. "-" .. section[2] .. "  " .. section[3]
        row.heading:SetText((current and "Current range  |  " or done and "Done · " or "") .. title)
        row.heading:SetTextColor(unpack(done and {0.4,0.46,0.49} or {0.41,0.84,0.75}))
        row.marker:SetText(expanded and "−" or "+")
        local detail = self:StepDetail(section)
        row.detail:SetText(detail); row.detail:SetShown(expanded)
        local headerHeight = math.max(26, row.heading:GetStringHeight() + 8)
        row.header:SetHeight(headerHeight)
        row.detail:ClearAllPoints(); row.detail:SetPoint("TOPLEFT", 0, -headerHeight - 6)
        local height = headerHeight + (expanded and row.detail:GetStringHeight() + 18 or 4)
        local estimates = expanded and self:StepEstimates(guide, section, rank) or {}
        height = self:StepMaterials(row, estimates, height, expanded)
        row:SetHeight(height); row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y); row:Show()
        y = y + height + 4
    end
    return y
end
local function OwnsTooltip(tip, row)
    if not row or not Safe(tip) then return false end
    local owned = Field(tip, "IsOwned")
    if Read(owned, "function") then return Call(owned, tip, row) == true end
    return Call(Field(tip, "GetOwner"), tip) == row
end
function Leveling:HideTooltip()
    local tip, row = self.tooltip, self.hovered
    self.tooltip, self.hovered = nil, nil
    if OwnsTooltip(tip, row) then pcall(Field(tip, "Hide"), tip) end
end
function Leveling:ItemTooltip(row)
    self:HideTooltip()
    if InCombatLockdown() or not self:Enabled() or not self.open or not Shown(self.owner)
        or not Shown(self.frame) or not Shown(row) then return end
    local id = Field(row, "materialID")
    if not Number(id) or id <= 0 or id % 1 ~= 0 or id > 2147483647 then return end
    local tip = GameTooltip
    if not Safe(tip) then return end
    for _, method in ipairs({ "SetOwner", "SetItemByID", "Show", "Hide" }) do
        if not Read(Field(tip, method), "function") then return end
    end
    if not Read(Field(tip, "IsOwned"), "function") and not Read(Field(tip, "GetOwner"), "function") then return end
    self.tooltip, self.hovered = tip, row
    if not pcall(tip.SetOwner, tip, row, "ANCHOR_RIGHT") or not OwnsTooltip(tip, row)
        or not pcall(tip.SetItemByID, tip, id) or not OwnsTooltip(tip, row)
        or not pcall(tip.Show, tip) then self:HideTooltip() end
    -- Native item data and the existing tooltip post-call add recorded inventory.
    -- Do not scan possessions, enable tracking or append a second inventory block.
end
function Leveling:Stock(id, required)
    local summary = Call(Suite.Inventory.Summary, Suite.Inventory, id, true)
    if not Read(summary, "table") or Field(summary, "observed") ~= true then return "?", "?", false end
    local total, incomplete = Field(summary, "total"), Field(summary, "incomplete")
    if not Number(total) or total % 1 ~= 0 or total > 1000000000000 or not Read(incomplete, "boolean") then return "?", "?", false end
    local need = math.max(0, required - total)
    local have = string.format("%d", total) .. (incomplete and "+" or "")
    return have, (incomplete and need > 0 and "≤" or "") .. string.format("%d", need), need == 0
end
function Leveling:InventoryChanged()
    if self:Enabled() and self.open and Shown(self.frame) then self:Queue() end
end
local function MaterialKey(item) return item[2] or item[3] end
function Leveling:RemainingShopping(guide, rank)
    if not guide or not guide.estimates then return guide and guide.shopping end
    local shopping, produced = {}, {}
    shopping.projected = true
    shopping.note = "Uses the primary recipes below and reuses intermediate items made by earlier remaining steps. Recipe quests and optional alternatives are not included."
    for _, section in ipairs(guide.sections) do
        local group, merged, target = { rows = {}, endSkill = section[2] }, {}, section[1]
        for _, estimate in ipairs(self:StepEstimates(guide, section, rank)) do
            target = math.max(target, estimate.target)
            for _, material in ipairs(estimate.materials) do
                local required = material.count
                if not estimate.done then
                    local reused = math.min(produced[material.name] or 0, required)
                    produced[material.name] = (produced[material.name] or 0) - reused
                    required = required - reused
                end
                if required > 0 then
                    local key = (estimate.done and "done:" or "next:") .. (material.id or material.name)
                    local row = merged[key]
                    if not row then
                        row = { {0, material.id, material.name, Suite.ProfessionMaterialVendors[material.name]}, completed = estimate.done == true }
                        merged[key] = row; group.rows[#group.rows + 1] = row
                    end
                    row[1][1] = row[1][1] + required
                end
            end
            if not estimate.done then produced[estimate.recipe] = (produced[estimate.recipe] or 0) + estimate.produced end
        end
        if #group.rows > 0 then
            group.title = section[1] .. "-" .. math.min(section[2], target)
            shopping[#shopping + 1] = group
        end
    end
    return shopping
end
function Leveling:MaterialPlan(guide, rank)
    local plan, totals = {}, {}
    local shopping = self:RemainingShopping(guide, rank)
    if not shopping then return plan, totals end
    for _, group in ipairs(shopping) do
        for _, row in ipairs(group.rows) do
            local done = row.completed
            if done == nil then done = Number(rank) and (rank >= group.endSkill or rank >= row.endSkill) end
            plan[row] = done
            if not done then
                for _, item in ipairs(row) do
                    local key = MaterialKey(item)
                    totals[key] = (totals[key] or 0) + item[1]
                end
            end
        end
    end
    return plan, totals, shopping
end
function Leveling:Materials(guide)
    local frame, y, rowIndex, labelIndex = self.frame, 0, 0, 0
    local rank = guide and guide == guides[self.current] and self.rank or nil
    local doneRows, totals, shopping = self:MaterialPlan(guide, rank)
    local stock = {}
    local function Counts(item, total)
        local key = MaterialKey(item) .. ":" .. total
        if not stock[key] then stock[key] = { self:Stock(item[2], total) } end
        return stock[key]
    end
    local function Visible(row)
        if doneRows[row] then return not self:ViewOption("professionLevelingHideDone") end
        if not self:ViewOption("professionLevelingHideStocked") then return true end
        for _, item in ipairs(row) do if not Counts(item, totals[MaterialKey(item)] or 0)[3] then return true end end
        return false
    end
    self:HideTooltip()
    frame.materialRows, frame.materialLabels = frame.materialRows or {}, frame.materialLabels or {}
    for _, row in ipairs(frame.materialRows) do row.materialID = nil; row:Hide() end
    for _, label in ipairs(frame.materialLabels) do label:Hide() end
    local function Paragraph(text, color, x, width)
        labelIndex = labelIndex + 1
        local label = frame.materialLabels[labelIndex]
        if not label then label = Label(frame.body, 13, 0, 0, CONTENT_WIDTH); frame.materialLabels[labelIndex] = label end
        label:ClearAllPoints(); label:SetPoint("TOPLEFT", x or 0, -y); label:SetWidth(width or CONTENT_WIDTH)
        label:SetText(text); label:SetTextColor(unpack(color or {0.6, 0.68, 0.71})); label:Show()
        y = y + label:GetStringHeight() + 10
    end
    local function Item(item, done, total)
        local counts = not done and Counts(item, total)
        if counts and counts[3] and self:ViewOption("professionLevelingHideStocked") then return end
        rowIndex = rowIndex + 1
        local row = frame.materialRows[rowIndex]
        if not row then
            row = CreateFrame("Button", nil, frame.body)
            row:EnableMouse(true)
            row.quantity = Label(row, 13, 0, -3, 54)
            row.name = Label(row, 13, 54, -3, 202)
            row.have = Label(row, 11, 264, -4, 68)
            row.need = Label(row, 11, 358, -4, 52)
            row.check = row:CreateTexture(nil, "OVERLAY")
            row.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready"); row.check:SetSize(14, 14)
            row.check:SetPoint("TOPLEFT", 340, -3)
            local highlight = row:CreateTexture(nil, "HIGHLIGHT"); highlight:SetAllPoints()
            highlight:SetColorTexture(0.41, 0.84, 0.75, 0.12)
            row:SetScript("OnEnter", function() self:ItemTooltip(row) end)
            local function Leave() if self.hovered == row then self:HideTooltip() end end
            row:SetScript("OnLeave", Leave); row:SetScript("OnHide", Leave)
            frame.materialRows[rowIndex] = row
        end
        row.materialID = item[2]
        row.done = done == true
        row.check:SetShown(counts and counts[3] == true or false)
        row.quantity:SetText(item[1] .. " x"); row.quantity:SetTextColor(unpack(done and {0.4,0.46,0.49} or {0.9,0.75,0.48}))
        row.name:SetText(item[3] .. (item[4] and "  |cff9aaeb6(vendor)|r" or ""))
        row.name:SetTextColor(unpack(done and {0.4,0.46,0.49} or {0.88,0.91,0.93}))
        if done then
            row.have:SetText("—"); row.need:SetText("Done"); row.need:SetTextColor(0.4,0.46,0.49)
        else
            row.have:SetText(counts[1]); row.need:SetText(counts[2])
            row.need:SetTextColor(unpack(counts[3] and {0.41,0.84,0.75} or {1,0.74,0.44}))
        end
        row.have:SetTextColor(0.6,0.72,0.76)
        local height = math.max(24, row.name:GetStringHeight() + 6, row.have:GetStringHeight() + 8, row.need:GetStringHeight() + 8)
        row:SetSize(CONTENT_WIDTH, height); row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y); row:Show()
        y = y + height
    end
    if not shopping then return 0 end
    Paragraph("Required materials", {0.41, 0.84, 0.75})
    Paragraph("Saved character bags/banks + shared bank. + = incomplete; ≤ = upper estimate; ? = unknown.")
    Paragraph(shopping.projected and "Required follows the remaining-step estimates below. Need combines all unfinished uses before subtracting stock. Actual crafts may vary."
        or "Done = completed range. Active quantities are full-band estimates. Need combines unfinished main-route rows; alternatives replace one row.")
    if shopping.note then Paragraph(shopping.note) end
    if #shopping == 0 then Paragraph("No unfinished recipe inputs in the available plan.") end
    local anyGroup = false
    for _, group in ipairs(shopping) do
        local visible = false
        for _, row in ipairs(group.rows) do
            if Visible(row) then visible = true; break end
        end
        if visible then
            anyGroup = true
            Paragraph(group.title, {0.41, 0.84, 0.75})
            if group.note then Paragraph(group.note, {1, 0.74, 0.44}) end
            local headerY = y
            Paragraph("Required"); local headerEnd = y
            y = headerY; Paragraph("Have", nil, 264, 68)
            y = headerY; Paragraph("Need total", nil, 340, 70)
            y = math.max(y, headerEnd)
            for _, row in ipairs(group.rows) do
                local done = doneRows[row]
                if Visible(row) then
                    for _, item in ipairs(row) do Item(item, done, totals[MaterialKey(item)] or 0) end
                    if row.alternative then
                        Paragraph(#row > 1 and "OR replace the above " .. #row .. " items with:" or "OR replace the above item with:")
                        local replacement = {}
                        for _, item in ipairs(row) do
                            local key = MaterialKey(item); replacement[key] = (replacement[key] or totals[key] or 0) - item[1]
                        end
                        for _, item in ipairs(row.alternative) do
                            local key = MaterialKey(item); replacement[key] = (replacement[key] or totals[key] or 0) + item[1]
                        end
                        for _, item in ipairs(row.alternative) do Item(item, done, replacement[MaterialKey(item)]) end
                        y = y + 8
                    end
                end
            end
            y = y + 14
        end
    end
    if #shopping > 0 and not anyGroup then Paragraph("No materials to get in the current view.", {0.41,0.84,0.75}) end
    Paragraph("Leveling steps", {0.41, 0.84, 0.75})
    return y
end
function Leveling:Cancel()
    if self.timer then self.timer:Cancel(); self.timer = nil end
    Suite.pending.professionLevelingRefresh = nil
end
function Leveling:Close()
    self.open = nil
    self:HideTooltip()
    if InCombatLockdown() then
        Suite.AfterCombat("professionLevelingRefresh", function() self:Close() end); return
    end
    if self.frame then self.frame.source:ClearFocus(); self.frame:Hide() end
end
function Leveling:Place()
    if InCombatLockdown() or not self:Enabled() or not Safe(self.owner) then return end
    local owner, frame = self.owner, self.frame
    local page = Field(owner, "CraftingPage")
    local link = Safe(page) and Field(page, "LinkButton")
    self.button:ClearAllPoints()
    if Shown(page) and Safe(link) then self.button:SetPoint("LEFT", link, "RIGHT", 10, 0)
    else self.button:SetPoint("TOPRIGHT", owner, "TOPRIGHT", -14, -40) end
    if not frame then return end
    local side, gap = "RIGHT", 58 -- Clear the native profession tabs.
    local right, left = Call(Field(owner, "GetRight"), owner), Call(Field(owner, "GetLeft"), owner)
    local scale, uiScale = Call(Field(owner, "GetEffectiveScale"), owner), Call(Field(UIParent, "GetEffectiveScale"), UIParent)
    local screen = Call(Field(UIParent, "GetWidth"), UIParent)
    if Number(right) and Number(left) and Number(scale) and scale > 0 and Number(uiScale) and uiScale > 0 and Number(screen) then
        local ratio = scale / uiScale
        local width = frame:GetWidth()
        if (right + gap + width) * ratio > screen and (left - 8 - width) * ratio >= 0 then side, gap = "LEFT", 8 end
    end
    frame:ClearAllPoints()
    if side == "LEFT" then frame:SetPoint("TOPRIGHT", owner, "TOPLEFT", -gap, 0)
    else frame:SetPoint("TOPLEFT", owner, "TOPRIGHT", gap, 0) end
end
function Leveling:CreatePanel()
    if self.frame or InCombatLockdown() then return end
    local frame = CreateFrame("Frame", nil, self.owner, "BackdropTemplate"); self.frame = frame
    frame:Hide(); frame:SetSize(WIDTH, 550); frame:SetClampedToScreen(true); frame:EnableMouse(true)
    frame:SetFrameStrata("HIGH"); frame:SetFrameLevel(520); Surface(frame)
    frame.title = Label(frame, 16, 14, -14, WIDTH - 62)
    frame.status = Label(frame, 11, 14, -40, WIDTH - 30)
    local close = Button(frame, "X", 24, function() self:Close() end); close:SetPoint("TOPRIGHT", -8, -8)
    local previous = Button(frame, "< Guide", 92, function() self:Select((self.selected or 1) - 1) end)
    previous:SetPoint("TOPLEFT", 14, -64)
    local follow = Button(frame, "Current", 110, function() self:Refresh(true) end); follow:SetPoint("LEFT", previous, "RIGHT", 8, 0)
    local nextGuide = Button(frame, "Guide >", 100, function() self:Select((self.selected or 1) + 1) end)
    nextGuide:SetPoint("LEFT", follow, "RIGHT", 8, 0)
    frame.hideDone = Button(frame, "Hide Done", 84, function() self:ToggleView("professionLevelingHideDone") end)
    frame.hideDone:SetPoint("LEFT", nextGuide, "RIGHT", 8, 0)
    frame.scroll = Suite.GUI:CreateSuiteScrollFrame(frame)
    frame.scroll:SetPoint("TOPLEFT", 14, -98); frame.scroll:SetSize(CONTENT_WIDTH, 350)
    frame.scroll:HookScript("OnVerticalScroll", function() self:HideTooltip() end)
    frame:HookScript("OnHide", function() self:HideTooltip() end)
    frame.body = CreateFrame("Frame", nil, frame.scroll); frame.body:SetWidth(CONTENT_WIDTH)
    frame.text = Label(frame.body, 13, 0, 0, CONTENT_WIDTH); frame.text:SetSpacing(4)
    frame.scroll:SetScrollChild(frame.body)
    frame.credit = Label(frame, 10, 14, -460, WIDTH - 28)
    frame.credit:SetText("Original summary · WoW-Professions reference\nReviewed November 11, 2026 · English")
    local sourceButton = Button(frame, "Copy source link", 132, function()
        if self.url then frame.source:SetFocus(); frame.source:HighlightText() end
    end)
    sourceButton:SetPoint("TOPLEFT", 14, -493)
    frame.autoSteps = Button(frame, "Auto steps: On", 144, function() self:ToggleView("professionLevelingAutoSteps") end)
    frame.autoSteps:SetPoint("LEFT", sourceButton, "RIGHT", 8, 0)
    frame.hideStocked = Button(frame, "Show Stocked", 134, function() self:ToggleView("professionLevelingHideStocked") end)
    frame.hideStocked:SetPoint("LEFT", frame.autoSteps, "RIGHT", 8, 0)
    frame.source = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    frame.source:SetAutoFocus(false); frame.source:SetSize(WIDTH - 40, 20); frame.source:SetPoint("TOPLEFT", 20, -522)
    frame.source:SetFont("Fonts\\FRIZQT__.TTF", 10, ""); frame.source:SetMaxLetters(240)
    frame.source:SetScript("OnTextChanged", function(input)
        local expected = self.url or ""
        if Call(input.GetText, input) ~= expected then input:SetText(expected) end
    end)
    frame.source:SetScript("OnEscapePressed", function() self:Close() end)
    frame.source:SetScript("OnEnterPressed", function(input) input:ClearFocus() end)
    frame.source:SetScript("OnEditFocusGained", function(input) input:HighlightText() end)
    frame.sourceButton = sourceButton
    frame.previous, frame.follow, frame.nextGuide, frame.close = previous, follow, nextGuide, close
end
function Leveling:Render(reset)
    local frame = self.frame
    if not frame or InCombatLockdown() then return end
    local guide = guides[self.selected]
    local rank = self.selected == self.current and self.rank or nil
    frame.title:SetText(guide and guide.name .. " · Leveling" or "Profession Leveling")
    frame.status:SetText(rank and string.format("Your skill: %d / %d", rank, self.maximum)
        or self.context == "unavailable" and "Profession data unavailable · browse a guide"
        or "Browse guides · choose Current to follow your profession")
    local offset = self:Materials(guide)
    local height = math.max(350, self:Steps(guide, rank, offset) + 12)
    frame.body:SetHeight(height)
    if reset then frame.scroll.suiteOffset = 0; frame.scroll:SetVerticalScroll(0) end
    Suite.GUI:SyncScrollBar(frame.scroll, math.max(0, height - 350))
    frame.scroll:SetVerticalScroll(frame.scroll.suiteOffset)
    frame.hideDone:SetText(self:ViewOption("professionLevelingHideDone") and "Show Done" or "Hide Done")
    frame.autoSteps:SetText(self:ViewOption("professionLevelingAutoSteps") and "Auto steps: On" or "Auto steps: Off")
    frame.hideStocked:SetText(self:ViewOption("professionLevelingHideStocked") and "Show Stocked" or "Hide Stocked")
    self.url = guide and guide.url or nil
    frame.source:ClearFocus(); frame.source:SetText(self.url or "")
    frame.sourceButton:SetEnabled(self.url ~= nil)
    frame.sourceButton:SetText("Source link · Ctrl+C")
end
function Leveling:Select(index)
    if not self:Enabled() or InCombatLockdown() or not self.open then return end
    self.selected = (index - 1) % #guides + 1
    self.stepContext, self.stepOverrides = nil, {}
    self:Render(true)
end
function Leveling:Refresh(follow)
    if not self:Enabled() or InCombatLockdown() or not Safe(self.owner) then return end
    local current, rank, context, maximum = self:Context()
    local changed = context ~= self.context
    self.current, self.rank, self.maximum, self.context = current, rank, maximum, context
    if changed or follow then
        self.stepContext, self.stepOverrides = nil, {}
        if context then self.selected = current else self.selected = self.selected or 1 end
    end
    self:Place(); self.button:Show()
    if self.open then self:Render(changed or follow) end
    self:AutoSelectRecipe()
end
function Leveling:Queue()
    if not self:Enabled() then return end
    if InCombatLockdown() then
        Suite.AfterCombat("professionLevelingRefresh", function() self:Discover() end); return
    end
    if not self.timer and Read(Field(C_Timer, "NewTimer"), "function") then
        self.timer = C_Timer.NewTimer(0, function() self.timer = nil; self:Discover() end)
    end
end
function Leveling:Toggle()
    if not self:Enabled() or InCombatLockdown() or not Shown(self.owner) then return end
    if self.open then self:Close(); return end
    self:CreatePanel(); self.open = true; self:Refresh(true); self.frame:Show()
end
function Leveling:Discover()
    if not self:Enabled() or InCombatLockdown() or not Safe(ProfessionsFrame) then return end
    if self.owner ~= ProfessionsFrame then
        -- The native frame is a singleton. Never replace its scripts or stored profession data.
        self.owner = ProfessionsFrame
        self.button = Button(self.owner, "Leveling", 68, function() self:Toggle() end)
        self.button:SetFrameStrata("HIGH"); self.button:SetFrameLevel(520)
        self.owner:HookScript("OnShow", function() self.autoBlocked, self.autoAttempt, self.autoTarget = nil, nil, nil; self:Queue() end)
        self.owner:HookScript("OnHide", function()
            self:Cancel(); self.open, self.context = nil, nil
            self.autoAttempt, self.autoTarget, self.autoBlocked = nil, nil, nil
            Suite.AfterCombat("professionLevelingRefresh", function() self:Close() end)
        end)
        self.owner:HookScript("OnSizeChanged", function() if self:Enabled() then self:Queue() end end)
        if Read(hooksecurefunc, "function") then
            local page = Field(self.owner, "CraftingPage")
            if Read(Field(page, "CreateInternal"), "function") then
                hooksecurefunc(page, "CreateInternal", function() if self:Enabled() then self.autoCrafting = true end end)
            end
            for _, method in ipairs({ "SetProfessionInfo", "SelectBookPage" }) do
                if Read(Field(self.owner, method), "function") then hooksecurefunc(self.owner, method, function() self:Queue() end) end
            end
        end
    end
    if not self.open and self.frame then self:Close() end
    if Shown(self.owner) then self:Refresh() end
end
function Leveling:Apply()
    if not self:Enabled() then
        self:Cancel(); self.open = nil
        self.autoAttempt, self.autoTarget, self.autoBlocked, self.autoCrafting = nil, nil, nil, nil
        if self.events then self.events:UnregisterAllEvents() end
        self.active = nil
    end
    Suite.AfterCombat("professionLevelingApply", function()
        if not self:Enabled() then
            if self.button then self.button:Hide() end
            self:Close(); return
        end
        if not self.events then
            self.events = CreateFrame("Frame")
            self.events:SetScript("OnEvent", function(_, event, unit)
                if event == "PLAYER_REGEN_DISABLED" then self:Cancel(); self:HideTooltip(); self.open = nil; self.autoBlocked = true
                else
                    if event == "UPDATE_TRADESKILL_CAST_STOPPED" or ((event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED")
                        and Read(unit, "string") and unit == "player") then self.autoCrafting = nil end
                    self:Queue()
                end
            end)
        end
        if not self.active then
            for _, event in ipairs({ "ADDON_LOADED", "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE",
                "TRADE_SKILL_DATA_SOURCE_CHANGED", "SKILL_LINES_CHANGED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
                "UPDATE_TRADESKILL_CAST_STOPPED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_FAILED" }) do
                self.events:RegisterEvent(event)
            end
            self.active = true
        end
        -- Combat cancels an open flyout; it does not reopen automatically afterward.
        if not self.open then self:Close() end
        self:Discover()
    end)
end
