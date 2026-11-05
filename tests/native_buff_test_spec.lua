local Suite, equal, Frame, SetCombat = ...
local test = Suite.NativeBuffTest
local saved = { create = CreateFrame, class = UnitClass, addons = C_AddOns,
    policy = CustomAuraContainerAuraProcessingPolicy, timer = C_Timer, auras = C_UnitAuras,
    print = Suite.Print, pending = Suite.pending, spell = Suite.MissingBuffs.Spell,
    learned = Suite.MissingBuffs.Learned }
local messages, containers, nativeButtons = {}, {}, {}
local created, class, known, reject = 0, "WARRIOR", true, false
Suite.pending = {}
Suite.Print = function(message) messages[#messages + 1] = message end
UnitClass = function() return "Localized class", class end
C_AddOns = { LoadAddOn = function(name) equal(name, "Blizzard_AuraContainer", "only Blizzard's aura library is requested") end }
CustomAuraContainerAuraProcessingPolicy = { None = 0 }
C_Timer = setmetatable({}, { __index = function() error("native buff test must not poll") end })
C_UnitAuras = setmetatable({}, { __index = function() error("native buff test must not read aura data") end })
Suite.MissingBuffs.Spell = function() return { id = 6673, name = "Localized Shout", icon = 132333 } end
Suite.MissingBuffs.Learned = function()
    return known and { ["Localized Shout"] = { id = 11551, name = "Localized Shout", icon = 132333 } } or {}
end
local function Guard() assert(not InCombatLockdown(), "native test setup/layout waits for combat") end
local function Hidden() error("addon must not inspect native aura display state") end
local function Texture()
    Guard()
    local texture = Frame()
    texture.SetVertexColor = function(self, ...) self.vertex = { ... } end
    texture.SetAllPoints = function(self, target) self.target = target end
    return texture
end
CreateFrame = function(kind, name, parent, template)
    Guard(); created = created + 1
    equal(name, nil, "native test creates no global frames")
    local frame = Frame()
    frame.parent = parent
    frame.CreateTexture = Texture
    for _, method in ipairs({ "Show", "Hide", "SetPoint", "ClearAllPoints", "SetSize" }) do
        local original = frame[method]
        frame[method] = function(self, ...) Guard(); return original(self, ...) end
    end
    if kind == "AuraContainer" then
        equal(template, "CustomAuraContainerTemplate", "native test uses the supported custom container")
        containers[#containers + 1] = frame
        frame.SetEnabled = function(self, enabled) Guard(); self.enabled = enabled end
        frame.SetEditModePreviewEnabled = function(self, enabled) Guard(); self.preview = enabled end
        frame.SetAuraProcessingPolicy = function(self, policy) Guard(); self.policy = policy end
        frame.SetUnit = function(self, unit) Guard(); self.unit = unit end
        frame.AddAuraGroup = function(self, key, filter, options)
            Guard(); if reject then error("Unsupported test widget") end
            self.key, self.filter, self.options = key, filter, options
            -- Native source preallocates a batch before applying access restrictions.
            for _ = 1, 3 do
                local button = Frame(); button.parent = self; button.CreateTexture = Texture
                button.SetIcon = function(_, texture) Guard(); equal(texture ~= nil, true, "icon handed to native binding") end
                button.SetDurationText = function(_, text, options)
                    Guard(); equal(type(options), "table", "native timer uses documented binding options")
                    text.GetText = Hidden
                end
                options.initializeFrame(button)
                equal(button.mouseEnabled, false, "native aura display cannot consume clicks")
                for _, method in ipairs({ "IsShown", "IsVisible", "GetChildren", "GetWidth", "GetHeight", "GetPoint", "GetNumPoints" }) do button[method] = Hidden end
                nativeButtons[#nativeButtons + 1] = button
            end
        end
        for _, method in ipairs({ "IsShown", "IsVisible", "GetChildren", "GetWidth", "GetHeight", "GetPoint", "GetNumPoints", "GetAuraGroupFrameCount" }) do frame[method] = Hidden end
    end
    return frame
end
local function LeaveCombat()
    SetCombat(false)
    local pending = Suite.pending; Suite.pending = {}
    for _, callback in pairs(pending) do callback() end
end

equal(test.enabled, nil, "native test has no saved or default-on activation")
equal(created, 0, "native test creates nothing until explicitly requested")
SetCombat(true); test:Toggle()
equal(created, 0, "enabling native test during combat only queues setup")
test:Toggle(); LeaveCombat()
equal(created, 0, "cancelled combat enable cannot create the native display")
SlashCmdList.WOWFOREVERSUITE("bufftest")
equal(test.host:IsShown(), true, "slash command starts the independent test card")
equal(test.container.unit, "player", "native display is limited to the player")
equal(test.container.preview, false, "Edit Mode cannot invent sample aura coverage")
equal(test.container.filter, "HELPFUL", "native filtering admits only buffs")
equal(test.container.options.maxFrameCount, 1, "native display bounds visible native frames")
equal(test.container.options.candidateFilters.includeSpellIDs[6673], true, "rank one is covered")
equal(test.container.options.candidateFilters.includeSpellIDs[11551], true, "learned higher rank is covered")
equal(test.container.options.candidateFilters.includeSpellIDs[1459], nil, "unrelated auras cannot cover the reminder")
equal(test.host.OnUpdate, nil, "test host never uses an idle updater")
equal(#nativeButtons, 3, "all native batch buttons are styled during initial setup")
local beforeCreated = created
SetCombat(true); test:Toggle()
equal(test.host:IsShown(), true, "combat disable does not mutate the native hierarchy")
equal(created, beforeCreated, "combat stop creates no frames")
LeaveCombat()
equal(test.host:IsShown(), false, "queued stop hides the test card after combat")
equal(test.container.enabled, false, "stop disables native processing")
test:Toggle()
equal(created, beforeCreated, "explicit restart reuses the prepared native display")
equal(test.container.enabled, true, "restart reenables native processing")
test:Toggle()

-- No partial capability failure may reveal an apparently working reminder.
test.host, test.container = nil, nil
CustomAuraContainerAuraProcessingPolicy = nil; test:Toggle()
equal(test.enabled, false, "missing native capability cancels the experiment")
equal(created, beforeCreated, "missing native capability creates no test UI")
CustomAuraContainerAuraProcessingPolicy = { None = 0 }
known = false; test:Toggle()
equal(test.enabled, false, "unknown spellbook cannot arm a misleading test")
class = { secret = true }; test:Toggle()
equal(test.enabled, false, "unreadable class cannot select a combat aura")
class, known, reject = "WARRIOR", true, true
test:Toggle()
equal(test.enabled, false, "native setup rejection leaves test disabled")
equal(containers[#containers].enabled, false, "partial setup disables native processing")
equal(test.host, nil, "failed setup is not exposed as a ready display")
equal(messages[#messages]:find("Unsupported test widget", 1, true) ~= nil, true, "setup rejection supplies actionable diagnostic text")

test.host, test.container, test.enabled, test.failure = nil, nil, nil, nil
CreateFrame, UnitClass, C_AddOns = saved.create, saved.class, saved.addons
CustomAuraContainerAuraProcessingPolicy, C_Timer, C_UnitAuras = saved.policy, saved.timer, saved.auras
Suite.Print, Suite.pending = saved.print, saved.pending
Suite.MissingBuffs.Spell, Suite.MissingBuffs.Learned = saved.spell, saved.learned
SetCombat(false)
