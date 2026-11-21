-- Independent conservation checks across the complete bundled guide library.
local Suite, equal = ...
local leveling, guides = Suite.ProfessionLeveling, Suite.ProfessionGuides
local savedSummary, savedSkill = Suite.Inventory.Summary, leveling.GuideSkill
local savedDone, savedStocked = Suite.db.professionLevelingHideDone, Suite.db.professionLevelingHideStocked
local savedCollapsed = Suite.db.professionLevelingMaterialsCollapsed
local holding, partial, unknown, rank = 0, false, false, 0
Suite.Inventory.Summary = function(_, id)
    if unknown or type(id) ~= "number" then return end
    return { observed = true, total = holding, incomplete = partial }
end
leveling.GuideSkill = function() return rank end
Suite.db.professionLevelingMaterialsCollapsed = false
Suite.db.professionLevelingHideStocked = false
Suite.db.professionLevelingHideDone = true
local function Key(item) return item[2] or item[3] end
local auditChecks = 0
local function Expect(actual, expected, context)
    auditChecks = auditChecks + 1
    assert(actual == expected, context .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function Number(text) return tonumber((text:gsub("≤", ""))) end

-- Use raw craft transactions, without calling StepEstimates or RemainingShopping.
-- Track fresh intermediate outputs separately from external reagent demand.
local function Reference(guide, skill)
    local outputs, external = {}, {}
    for _, recipe in ipairs(guide.estimates) do
        if not skill or skill < recipe[2] then
            local crafts = recipe[3]
            if skill and skill > recipe[1] then
                local remaining = recipe[3] * (recipe[2] - skill)
                crafts = math.floor((remaining + recipe[2] - recipe[1] - 1) / (recipe[2] - recipe[1]))
            end
            for _, reagent in ipairs(recipe[5]) do
                local demand = crafts * reagent[1]
                local available = outputs[reagent[2]] or 0
                if available >= demand then outputs[reagent[2]] = available - demand
                else
                    external[reagent[2]] = (external[reagent[2]] or 0) + demand - available
                    outputs[reagent[2]] = 0
                end
            end
            outputs[recipe[4]] = (outputs[recipe[4]] or 0) + crafts * (recipe[6] or 1)
        end
    end
    return external
end

local modeled, referenceOnly, states = 0, 0, 0
for _, guide in ipairs(guides) do
    if guide.estimates then
        modeled = modeled + 1
        local covered = {}
        for _, recipe in ipairs(guide.estimates) do
            for skill = recipe[1], recipe[2] - 1 do covered[skill] = true end
            local owners = 0
            for _, section in ipairs(guide.sections) do
                if recipe[1] >= section[1] and recipe[1] < section[2] then
                    owners = owners + 1
                    Expect(recipe[2] <= section[2], true, guide.name .. " recipe finishes within its section")
                end
            end
            Expect(owners, 1, guide.name .. " recipe belongs to exactly one section")
        end
        for skill = 1, 299 do Expect(covered[skill], true, guide.name .. " includes a recipe at skill " .. skill) end
        for skillIndex = -1, 300 do
            local skill = skillIndex >= 0 and skillIndex or nil
            local context = guide.name .. " at " .. tostring(skill)
            local expected = Reference(guide, skill)
            local done, totals, shopping = leveling:MaterialPlan(guide, skill)
            local byName, demands = {}, {}
            for _, group in ipairs(shopping) do
                for _, row in ipairs(group.rows) do
                    if not done[row] then
                        for _, item in ipairs(row) do
                            local key = Key(item)
                            byName[item[3]] = (byName[item[3]] or 0) + item[1]
                            demands[key] = demands[key] or {}
                            demands[key][#demands[key] + 1] = item[1]
                        end
                    end
                end
            end
            for name, count in pairs(expected) do Expect(byName[name], count, context .. " reagent " .. name) end
            for name, count in pairs(byName) do Expect(count, expected[name], context .. " no invented reagent " .. name) end
            for key, uses in pairs(demands) do
                local total = 0; for _, count in ipairs(uses) do total = total + count end
                Expect(totals[key], total, context .. " aggregate requirement")
                for _, stock in ipairs({0, 1, math.floor(total / 2), total, total + 17}) do
                    holding = stock
                    for _, incomplete in ipairs({false, true}) do
                        partial = incomplete
                        local available, prior, sum = stock, 0, 0
                        for _, demand in ipairs(uses) do
                            local take = math.min(available, demand)
                            available = available - take
                            local _, need = leveling:Stock(3860, demand, prior)
                            Expect(Number(need), demand - take, context .. " section allocation")
                            Expect(need:find("≤", 1, true) ~= nil, incomplete and demand > take, context .. " section coverage marker")
                            sum, prior = sum + Number(need), prior + demand
                        end
                        local _, totalNeed = leveling:Stock(3860, total)
                        Expect(sum, math.max(0, total - stock), context .. " section shortages conserve stock")
                        Expect(Number(totalNeed), sum, context .. " sections equal overall shortage")
                    end
                end
            end
            Suite.db.professionLevelingHideDone = false
            local _, shownTotals = leveling:MaterialPlan(guide, skill)
            for key, count in pairs(totals) do Expect(shownTotals[key], count, context .. " completed references preserve demand") end
            for key, count in pairs(shownTotals) do Expect(totals[key], count, context .. " completed references add no demand") end
            Suite.db.professionLevelingHideDone = true
            states = states + 1
        end
    else
        referenceOnly = referenceOnly + 1
        local _, totals, shopping = leveling:MaterialPlan(guide, 150)
        Expect(next(totals), nil, guide.name .. " does not invent a material budget")
        Expect(shopping, nil, guide.name .. " has no modeled shopping route")
    end
end
equal(modeled, 8, "math audit covers all eight modeled professions")
equal(referenceOnly, 6, "math audit covers six reference-only guides without invented totals")
equal(states, 2416, "math audit sweeps unknown skill and every integer from zero through 300")

-- Verify the actual rendered stock allocation across unfinished sections.
local function RenderAudit(guide, skill)
    rank = skill
    local done, totals, shopping = leveling:MaterialPlan(guide, skill)
    local expectedRows, available = {}, {}
    for _, group in ipairs(shopping or {}) do
        for _, row in ipairs(group.rows) do
            if not done[row] then
                local visible = not Suite.db.professionLevelingHideStocked
                for _, item in ipairs(row) do
                    if unknown or type(item[2]) ~= "number" or totals[Key(item)] > holding then visible = true end
                end
                local function Append(item, need, total)
                    if visible and (not Suite.db.professionLevelingHideStocked or unknown or type(item[2]) ~= "number" or total > holding) then
                        expectedRows[#expectedRows + 1] = { item = item, need = need, total = total }
                    end
                end
                for _, item in ipairs(row) do
                    local key = Key(item)
                    local left = available[key]
                    if left == nil then left = holding end
                    local take = math.min(left, item[1]); available[key] = left - take
                    Append(item, item[1] - take, totals[key])
                end
            end
        end
    end
    leveling:Materials(guide, 0)
    local index = 0
    for _, row in ipairs(leveling.frame.materialRows) do
        if row:IsShown() and not row.done then
            index = index + 1
            local expected = expectedRows[index]
            if expected then
                local context = guide.name .. " rendered at " .. tostring(skill) .. " " .. expected.item[3]
                if type(expected.item[2]) == "number" and not unknown then
                    Expect(Number(row.sectionNeed.text), expected.need, context .. " need here")
                    Expect(Number(row.need.text), math.max(0, expected.total - holding), context .. " overall shortage")
                else
                    Expect(row.sectionNeed.text, "?", context .. " unknown section shortage")
                    Expect(row.need.text, "?", context .. " unknown overall shortage")
                end
            end
        end
    end
    Expect(index, #expectedRows, guide.name .. " rendered rows match the plan")
end
for _, guide in ipairs(guides) do
    if guide.estimates then
        for _, stock in ipairs({0, 21, 200, 100000}) do
            holding = stock; partial = stock == 21
            for _, skill in ipairs({0, 75, 150, 218, 225, 265, 300}) do RenderAudit(guide, skill) end
        end
        holding, partial = 21, true
        Suite.db.professionLevelingHideDone = false; Suite.db.professionLevelingHideStocked = true
        RenderAudit(guide, 150)
        Suite.db.professionLevelingHideStocked = false
        RenderAudit(guide, 150)
        unknown = true; RenderAudit(guide, 218); unknown = false
        Suite.db.professionLevelingHideDone = true
        RenderAudit(guide, nil)
    end
end
Suite.Inventory.Summary, leveling.GuideSkill = savedSummary, savedSkill
Suite.db.professionLevelingHideDone, Suite.db.professionLevelingHideStocked = savedDone, savedStocked
Suite.db.professionLevelingMaterialsCollapsed = savedCollapsed
equal(true, true, "rendered profession material audit completed")
print("Profession material audit passed: " .. states .. " skill states; " .. auditChecks .. " invariants")
