local _, Suite = ...
local Gear = {}
Suite.GearSettings = Gear
local Scoring, GUI = Suite.Scoring, Suite.GUI
local colors = { row = { 0.07, 0.095, 0.11 }, text = { 0.88, 0.91, 0.93 }, muted = { 0.55, 0.65, 0.7 },
    teal = { 0.41, 0.84, 0.75 }, error = { 1, 0.48, 0.38 } }

local function Label(parent, text, x, y, width, size, color)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", size or 11, "")
    label:SetPoint("TOPLEFT", x, y); label:SetWidth(width); label:SetJustifyH("LEFT")
    label:SetTextColor(unpack(color or colors.text)); label:SetText(text)
    return label
end
local function Button(parent, text, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetPoint("TOPLEFT", x, y); button:SetSize(width, 28)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    button:SetBackdropColor(unpack(colors.row)); button:SetBackdropBorderColor(0.17, 0.25, 0.29)
    button.label = Label(button, text, 9, -8, width - 18, 11, colors.teal)
    button.label:SetWordWrap(false)
    button:SetScript("OnClick", function() if not InCombatLockdown() then callback() end end)
    button:SetScript("OnEnter", function() button:SetBackdropColor(0.09, 0.13, 0.145) end)
    button:SetScript("OnLeave", function() button:SetBackdropColor(unpack(colors.row)) end)
    return button
end
local function Input(parent, x, y, width, maximum)
    local input = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    input:SetPoint("TOPLEFT", x, y); input:SetSize(width, 25)
    input:SetAutoFocus(false); input:SetMaxLetters(maximum); input:SetTextInsets(7, 7, 0, 0)
    input:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    input:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    input:SetBackdropColor(0.035, 0.05, 0.065, 1); input:SetBackdropBorderColor(0.17, 0.25, 0.29)
    input:SetScript("OnEnterPressed", function() input:ClearFocus() end)
    return input
end

function Gear:Dismiss()
    self.mode, self.draft, self.editID, self.removing, self.message = nil, nil, nil, nil, nil
    Suite.pending.gearSettings = nil
    if self.panel then
        self.panel:Hide()
        if self.nameInput then self.nameInput:ClearFocus() end
        for _, field in ipairs(self.fields or {}) do field.input:ClearFocus() end
    end
end

function Gear:Open(mode)
    if InCombatLockdown() then
        Suite.AfterCombat("gearSettings", function()
            if GUI.page == "items" and GUI.frame and GUI.frame:IsShown() then self:Open(mode) end
        end)
        return
    end
    if mode == "picker" and self.draft then
        self.message = "Save or cancel your weight edits before choosing another profile."
        self:Refresh(); return
    end
    self.mode, self.removing, self.message = mode, nil, nil
    self:Build(); self:Refresh()
    GUI:Select("items"); GUI:ScrollTo(GUI.controlsOffset)
end

function Gear:Choose(id)
    if self.draft or InCombatLockdown() then return false end
    if not Scoring:SetProfile(id) then return false end
    self.mode, self.message, self.removing = "picker", nil, nil
    self:Refresh(); GUI:Select("items")
    return true
end

function Gear:Copy()
    if InCombatLockdown() or self.draft then return end
    self.draft, self.editID, self.removing = Suite.Copy(Scoring:Profile()), nil, nil
    self.draft.label = "My custom weights"
    local names = {}; for _, entry in ipairs(Scoring:List()) do names[entry.label:lower()] = true end
    local serial = 2
    while names[self.draft.label:lower()] do self.draft.label = "My custom weights " .. serial; serial = serial + 1 end
    self.message = "Unsaved copy. Your current comparisons stay active until Save."
    self:Refresh()
end

function Gear:Edit()
    local id = Scoring:ActiveID()
    if InCombatLockdown() or self.draft or not id:match("^custom%d+$") then return end
    self.draft, self.editID, self.removing = Suite.Copy(Scoring:Profile()), id, nil
    self.message = "Unsaved edits. Save applies them to this character only."
    self:Refresh()
end

function Gear:ReadDraft()
    if not self.draft then return end
    local label = self.nameInput:GetText()
    if not Suite.IsReadable(label) or type(label) ~= "string" or #label > 48 or label:find("[%c|]")
        or not label:find("%S") then return nil, "Enter a short profile name without chat markup." end
    local profile = { label = label, weights = {}, meleeDPS = 0, rangedDPS = 0 }
    for _, field in ipairs(self.fields) do
        local text = field.input:GetText()
        local valid = Suite.IsReadable(text) and type(text) == "string" and text:match("^%d*%.?%d*$")
        local decimals = valid and text:match("%.(%d*)$")
        local value = valid and tonumber(text)
        if not value or value ~= value or value < 0 or value > 1000 or decimals and #decimals > 3 then
            return nil, field.label .. ": enter 0 to 1000, with up to three decimal places."
        end
        if field.key == "meleeDPS" or field.key == "rangedDPS" then profile[field.key] = value
        elseif value > 0 then profile.weights[field.key] = value end
    end
    return profile
end

function Gear:Save()
    if InCombatLockdown() then return end
    local profile, message = self:ReadDraft()
    if profile then
        local id; id, message = Scoring:SaveProfile(profile, self.editID)
        if id then
            self.draft, self.editID = nil, nil
            self.message = "Saved and active for this character."
            self:Refresh(); GUI:Select("items"); return true
        end
    end
    self.message = message or "Create or edit a custom profile first."
    self.status:SetText(self.message); self.status:SetTextColor(unpack(colors.error))
    return false
end

function Gear:Cancel()
    if InCombatLockdown() then return end
    self.draft, self.editID, self.removing = nil, nil, nil
    self.message = "Edits discarded. Your saved profile is unchanged."
    self:Refresh()
end

function Gear:Remove()
    if self.draft or InCombatLockdown() then return end
    local id = Scoring:ActiveID()
    if not id:match("^custom%d+$") then return end
    if self.removing == id then
        Scoring:DeleteProfile(id)
        self.removing, self.message = nil, "Custom profile removed. Automatic is active."
        self:Refresh(); GUI:Select("items")
    else
        self.removing = id
        self.message = "Click Confirm removal to delete this character's custom profile."
        self.removeButton.label:SetText("Confirm removal"); self.removeButton.label:SetTextColor(unpack(colors.error))
        self.status:SetText(self.message)
    end
end

function Gear:Build()
    if InCombatLockdown() then return end
    if not self.panel then
        local panel = CreateFrame("Frame", nil, GUI.content)
        panel:SetSize(780, 1); self.panel, GUI.gearPanel = panel, panel
    end
    if self.mode == "picker" and not self.picker then self:BuildPicker() end
    if self.mode == "editor" and not self.editor then self:BuildEditor() end
end

function Gear:BuildPicker()
    local panel = self.panel
    self.picker = CreateFrame("Frame", nil, panel); self.picker:SetSize(780, 410); self.picker:SetPoint("TOPLEFT")
    Label(self.picker, "Ready-made profiles", 0, 0, 780, 15)
    local intro = Label(self.picker, "Choose a starter or your own saved weights. Editing is optional.\nAutomatic is a class-aware leveling starter; choose a role for a different build.", 0, -25, 780, 11, colors.muted)
    intro:SetHeight(34); intro:SetWordWrap(true)
    self.profileButtons = {}
    for index = 1, 6 + Scoring.maxProfiles do
        local button
        button = Button(self.picker, "", ((index - 1) % 3) * 264, -72 - math.floor((index - 1) / 3) * 58, 252,
            function() if button.id then self:Choose(button.id) end end)
        button:SetHeight(52); button.help = Label(button, "", 9, -26, 236, 10, colors.muted)
        button.help:SetHeight(24); button.help:SetWordWrap(true)
        self.profileButtons[index] = button
    end
end

function Gear:BuildEditor()
    local panel = self.panel
    self.editor = CreateFrame("Frame", nil, panel); self.editor:SetSize(780, 586); self.editor:SetPoint("TOPLEFT")
    Label(self.editor, "Comparison weights", 0, 0, 780, 15)
    self.explanation = Label(self.editor, "", 0, -25, 780, 11, colors.muted)
    self.explanation:SetHeight(42); self.explanation:SetWordWrap(true)
    self.copyButton = Button(self.editor, "Create custom copy", 0, -76, 252, function() self:Copy() end)
    self.editButton = Button(self.editor, "Edit saved weights", 264, -76, 252, function() self:Edit() end)
    self.removeButton = Button(self.editor, "Remove profile", 528, -76, 252, function() self:Remove() end)
    Label(self.editor, "Profile name", 0, -120, 780, 11, colors.muted)
    self.nameInput = Input(self.editor, 0, -139, 780, 48)
    self.nameLabel = Label(self.editor, "", 7, -145, 766, 13, colors.teal)
    self.nameInput:SetScript("OnEscapePressed", function() if self.draft then self.nameInput:SetText(self.draft.label) end; self.nameInput:ClearFocus() end)
    Label(self.editor, "Points per stat · 0 ignores a stat · decimals allowed", 0, -179, 780, 10, colors.muted)
    self.fields = {}
    local definitions = {}
    for _, stat in ipairs(Scoring.stats) do definitions[#definitions + 1] = stat end
    definitions[#definitions + 1] = { key = "meleeDPS", label = "Melee weapon DPS" }
    definitions[#definitions + 1] = { key = "rangedDPS", label = "Ranged weapon DPS" }
    for index, stat in ipairs(definitions) do
        local field = { key = stat.key, label = stat.label }
        local x, y = ((index - 1) % 3) * 264, -204 - math.floor((index - 1) / 3) * 48
        Label(self.editor, stat.label, x, y, 244, 11)
        field.input = Input(self.editor, x, y - 17, 244, 8)
        field.value = Label(self.editor, "", x + 7, y - 23, 230, 12, colors.teal)
        field.input:SetScript("OnEscapePressed", function()
            if self.draft then
                local value = self.draft[field.key]
                if value == nil then value = self.draft.weights[field.key] or 0 end
                field.input:SetText(tostring(value))
            end
            field.input:ClearFocus()
        end)
        field.input:SetScript("OnTabPressed", function()
            local backwards = false
            if type(IsShiftKeyDown) == "function" then
                local ok, value = pcall(IsShiftKeyDown)
                backwards = ok and Suite.IsReadable(value) and value == true
            end
            local nextIndex = (index - 1 + (backwards and -1 or 1)) % #definitions + 1
            if not InCombatLockdown() and self.fields[nextIndex].input.SetFocus then self.fields[nextIndex].input:SetFocus() end
        end)
        self.fields[index] = field
    end
    self.nameInput:SetScript("OnTabPressed", function()
        if not InCombatLockdown() and self.fields[1].input.SetFocus then self.fields[1].input:SetFocus() end
    end)
    self.detailsButton = Button(self.editor, "", 0, -456, 384, function()
        local state = Scoring:State()
        if state then state.details = not state.details end
        self:Refresh()
    end)
    self.chooseButton = Button(self.editor, "Choose another profile", 260, -456, 384, function() self:Open("picker") end)
    self.saveButton = Button(self.editor, "Save & use profile", 0, -496, 384, function() self:Save() end)
    self.cancelButton = Button(self.editor, "Cancel edits", 260, -496, 384, function() self:Cancel() end)
    self.status = Label(self.editor, "", 0, -537, 780, 11, colors.muted)
    self.status:SetHeight(42); self.status:SetWordWrap(true)
end

function Gear:Refresh()
    if not self.panel or not self.mode then return end
    if InCombatLockdown() then
        Suite.pending.gearSettings = function()
            if self.mode and GUI.page == "items" then self:Refresh(); GUI:Select("items") end
        end
        return
    end
    if self.picker then self.picker:SetShown(self.mode == "picker") end
    if self.editor then self.editor:SetShown(self.mode == "editor") end
    if self.mode == "picker" then
        local list, active = Scoring:List(), Scoring:ActiveID()
        for index, button in ipairs(self.profileButtons) do
            local entry = list[index]
            button:SetShown(entry ~= nil); button.id = entry and entry.id
            if entry then
                button.label:SetText((entry.id == active and "Selected · " or "") .. entry.label)
                button.help:SetText(entry.help)
                button:SetBackdropBorderColor(unpack(entry.id == active and colors.teal or colors.row))
            end
        end
        self.panel:SetHeight(72 + math.ceil(#list / 3) * 58)
        return
    end
    local profile, active, state = self.draft or Scoring:Profile(), Scoring:ActiveID(), Scoring:State()
    local custom = active:match("^custom%d+$") ~= nil
    self.explanation:SetText("Saved for this character. Built-in presets work without editing.\nWeapon speed, talents, procs and set bonuses are not modeled.")
    self.nameInput:SetShown(self.draft ~= nil); self.nameLabel:SetShown(self.draft == nil)
    self.nameLabel:SetText(profile.label)
    local newDraft = self.renderedDraft ~= self.draft
    if self.draft and newDraft then self.nameInput:SetText(profile.label) end
    for _, field in ipairs(self.fields) do
        local value = profile[field.key]
        if value == nil then value = profile.weights[field.key] or 0 end
        field.input:SetShown(self.draft ~= nil); field.value:SetShown(self.draft == nil)
        if self.draft then
            if newDraft then field.input:SetText(tostring(value)) end
        else field.value:SetText(tostring(value)) end
    end
    local function Enable(button, enabled)
        button:SetEnabled(enabled); button.label:SetTextColor(unpack(enabled and colors.teal or colors.muted))
    end
    Enable(self.copyButton, self.draft == nil and state ~= nil and #state.profiles < Scoring.maxProfiles)
    Enable(self.editButton, custom and self.draft == nil)
    Enable(self.removeButton, custom and self.draft == nil)
    if self.removing then self.removeButton.label:SetTextColor(unpack(colors.error)) end
    self.removeButton.label:SetText(self.removing and "Confirm removal" or "Remove profile")
    self.saveButton:SetShown(self.draft ~= nil); self.cancelButton:SetShown(self.draft ~= nil)
    self.detailsButton.label:SetText(state and state.details and "Tooltip: full breakdown" or "Tooltip: summary")
    self.status:SetText(self.message or "Higher scores mean improvements under these weights. Unweighted stats and special effects still need your judgment.")
    self.status:SetTextColor(unpack(colors.muted))
    self.panel:SetHeight(586)
    self.renderedDraft = self.draft
end
