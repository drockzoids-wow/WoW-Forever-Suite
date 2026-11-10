local Suite, equal, Frame, Combat = ...
local support, scoring = Suite.Diagnostics, Suite.Scoring
local saved = { db = Suite.db, pending = Suite.pending, print = Suite.Print, loaded = Suite.loadedSavedVariables,
    character = scoring.character, owner = scoring.owner, automatic = scoring.automaticProfile, class = scoring.class,
    failure = Suite.CombatBuffs.failure,
    page = Suite.GUI.page, shown = Suite.GUI.frame:IsShown() }
local originals = {}
local function Global(name, value)
    if not originals[name] then originals[name] = { value = _G[name] } end
    _G[name] = value
end
local function Trap() error("Diagnostics must never invoke actions, scans, data readers or timers") end
-- Advertise capabilities without permitting any of the advertised actions.
local roots = {}
for _, entry in ipairs(support.features) do
    for _, path in ipairs(entry.requires) do
        local root, rest = path:match("^([%w_]+)%.(.+)$")
        if root then
            if not roots[root] then
                local result = {}; if type(_G[root]) == "table" then for key, value in pairs(_G[root]) do result[key] = value end end
                roots[root] = result; Global(root, result)
            end
            roots[root][rest] = Trap
        else Global(path, Trap) end
    end
end
Global("GetBuildInfo", function() return "1.60.1", "70862", "ignored private build date", 16001 end)
Global("GetLocale", function() return "enUS" end)
Global("GetServerTime", function() return 2000000 end)
Global("CopyToClipboard", Trap)
local enums = {}; for key, value in pairs(Enum or {}) do enums[key] = value end
enums.DamageMeterType, enums.DamageMeterSessionType = {}, { Current = 0, Overall = 1 }
Global("Enum", enums)
C_DamageMeter.IsDamageMeterAvailable = function() return true, "Never copy raw native reason" end
C_CVar.GetCVarInfo = function() return "private-device-identifier", nil, nil, nil, false, false, false end
Combat(false); Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
scoring.owner, scoring.character, scoring.automaticProfile = Suite.db, { active = "automatic", preference = "stats", profiles = {} }, nil
local messages = {}; Suite.Print = function(message) messages[#messages + 1] = message end
local function Entry(key)
    for _, entry in ipairs(support.features) do if entry.key == key then return entry end end
    error("Missing diagnostic entry: " .. key)
end
local function State(key, combat)
    if combat == nil then combat = false end
    return support:State(Entry(key), combat)
end
equal(State("damageMeters"), "Off", "disabled feature remains off even when native capabilities are present")
Suite.db.damageMeters = true
equal(State("damageMeters"), "Ready", "meter availability predicate can confirm capability presence")
local sessionTypes = Enum.DamageMeterSessionType; Enum.DamageMeterSessionType = nil
equal(State("damageMeters"), "Unavailable", "meter functions alone cannot replace missing session enum definitions")
Enum.DamageMeterSessionType = sessionTypes
C_DamageMeter.IsDamageMeterAvailable = function() return false, "PrivateName-Realm" end
local state, reason = State("damageMeters")
equal(state, "Unavailable", "client capability refusal is reported")
equal(reason:find("PrivateName", 1, true), nil, "native availability reasons are never serialized")
C_DamageMeter.IsDamageMeterAvailable = function() error("Private error stack") end
equal(State("damageMeters"), "Unknown", "failed capability predicate is unknown without exposing the error")
local secret = setmetatable({ secret = true }, { __index = Trap, __tostring = Trap })
C_DamageMeter.IsDamageMeterAvailable = function() return secret end
equal(State("damageMeters"), "Unknown", "secret capability result is never compared or formatted")
C_DamageMeter.IsDamageMeterAvailable = function() return true end
C_DamageMeter.GetCombatSessionFromType = nil
state, reason = State("damageMeters")
equal(state, "Unavailable", "namespace presence alone does not establish a feature capability")
equal(reason:find("C_DamageMeter.GetCombatSessionFromType", 1, true) ~= nil, true, "missing function reason names the exact capability")
C_DamageMeter.GetCombatSessionFromType = Trap
Suite.pending.meters = Trap
equal(State("damageMeters", true), "Paused", "actual deferred meter setup is visible during combat")
Suite.pending.meters = nil
equal(State("damageMeters", true), "Ready", "live meters are not blanket-disabled because combat is active")
Suite.db.windowTools = true
equal(State("windowTools", true), "Paused", "native window actions explain combat pause")
Suite.db.windowTools = false; Suite.pending.windowWork = Trap
equal(State("windowTools", true), "Off", "stale deferred cleanup cannot make a disabled feature appear enabled")
Suite.pending.windowWork = nil
Suite.db.itemLevels = secret
equal(State("itemLevels"), "Unknown", "unreadable settings do not become enabled")
Suite.db.itemLevels = false
Suite.db.missingBuffCombat = true; Suite.db.missingBuffs = false
equal(State("missingBuffCombat"), "Off", "dependent feature explains disabled parent")
Suite.db.missingBuffs = secret
equal(State("missingBuffCombat"), "Unknown", "unreadable parent is not described as disabled")
Suite.db.missingBuffs, Suite.db.missingBuffCombat = false, false
Suite.db.castbars = {}
equal(State("castbars.player.enabled"), "Off", "omitted native castbar options retain their off default")
Suite.db.castbars.player = secret
equal(State("castbars.player.enabled"), "Unknown", "restricted castbar options are unknown rather than off")
Suite.db.castbars = {}
Suite.db.autoRepair = true; Global("MerchantFrame", nil)
equal(State("autoRepair"), "Waiting", "enabled vendor automation waits for a vendor visit")
Global("MerchantFrame", { IsShown = function() return true end })
equal(State("autoRepair"), "Ready", "open vendor context is recognized without performing repairs")
Global("MacroFrame", { IsShown = function() return true end })
equal(State("manualMacros"), "Paused", "native macro editor pauses explicit writes")
Global("MacroFrame", nil)
Global("MacroFrame", secret)
equal(State("manualMacros"), "Unknown", "restricted editor visibility does not imply writes are ready")
Global("MacroFrame", nil)
Suite.db.audioSync = true
local oldMovie, oldCinematic = Suite.Audio.movie, Suite.Audio.cinematic
Suite.Audio.movie = true
equal(State("audioSync"), "Paused", "movie playback explains deferred audio refresh")
Suite.Audio.movie, Suite.Audio.cinematic = nil, nil
C_CVar.GetCVarInfo = function() return "omitted-device", nil, nil, nil, false, false, true end
equal(State("audioSync"), "Unavailable", "read-only audio preference is diagnosed without attempting a restart")
C_CVar.GetCVarInfo = function() return secret end
equal(State("audioSync"), "Unknown", "restricted output preference cannot be recovered")
C_CVar.GetCVarInfo = function() return "omitted-device", nil, nil, nil, false, false, false end
Suite.Audio.movie, Suite.Audio.cinematic = oldMovie, oldCinematic
Suite.db.upgradeHints = true
scoring.character.active = "custom1"
scoring.character.profiles = { { id = "custom1", label = "PrivateCustomProfile", weights = { FIRE_DAMAGE = 633.7 } } }
Global("C_TooltipInfo", { GetHyperlink = Trap })
Global("GetLocale", function() return "deDE" end)
equal(State("upgradeHints"), "Unavailable", "selected school profile explains its locale limitation")
scoring.character.preference = "ilevel"
equal(State("upgradeHints"), "Ready", "item-level preference does not falsely require school parsing")
scoring.character.preference = "stats"; Global("GetLocale", function() return "enUS" end)
C_TooltipInfo.GetHyperlink = nil
equal(State("upgradeHints"), "Unavailable", "school profile requires the real tooltip reader function")
C_TooltipInfo.GetHyperlink = Trap
-- Deliberately include private data and malicious formatting in unrelated roots.
Suite.db.mailContacts.entries = { { name = "PrivateContact", notes = "PrivateNote" } }
Suite.db.inventory.characters.secret = { name = "PrivateAlt", realm = "PrivateRealm", bags = { items = { [123] = 99 } } }
Suite.db.unrecognizedFutureSetting = "PrivateFutureData"
Suite.pending.PrivateDeferredKey = Trap
Suite.CombatBuffs.failure = "PrivateFailureStack"
Suite.db.missingBuffs, Suite.db.missingBuffCombat = true, true
Global("CreateFrame", Trap)
local body, rows, counts = support:Snapshot()
equal(body:find("Client: 1.60.1 | build 70862 | Interface 16001", 1, true) ~= nil, true, "report includes guarded client/build/Interface")
equal(body:find("custom (name and weights omitted)", 1, true) ~= nil, true, "custom profile is identified without its label or coefficients")
for _, private in ipairs({ "PrivateCustomProfile", "633.7", "PrivateContact", "PrivateNote", "PrivateAlt", "PrivateRealm", "PrivateFutureData", "PrivateDeferredKey", "PrivateFailureStack", "omitted-device" }) do
    equal(body:find(private, 1, true), nil, "support export omits private data and arbitrary error/deferred payloads")
end
equal(#rows, #support.features, "every registered feature has one diagnostic row")
equal(counts.Off > 0, true, "report distinguishes disabled preferences")
equal(scoring.automaticProfile, nil, "diagnostics never initialize automatic scoring caches")
equal(Suite.pending.PrivateDeferredKey, Trap, "snapshot never executes or clears pending callbacks")
Suite.CombatBuffs.failure = nil
local readableDB = Suite.db; Suite.db = secret
body = support:Snapshot()
equal(body:find("Setting is unavailable or unreadable", 1, true) ~= nil, true, "restricted settings root can be reported without indexing or recovery")
Suite.db = readableDB
equal(support:State(Entry("windowTools"), nil), "Off", "disabled features stay off when combat state is unknown")
Suite.db.windowTools = true
equal(support:State(Entry("windowTools"), nil), "Unknown", "unknown combat state cannot claim action readiness")
Suite.db.windowTools = false
Global("GetBuildInfo", function() return secret, secret, secret, secret end)
Global("GetLocale", function() return secret end)
body = support:Snapshot()
equal(body:find("Client: unavailable | build unavailable | Interface unavailable", 1, true) ~= nil, true, "restricted metadata is omitted before formatting")
Global("GetBuildInfo", function() error("private build error") end)
body = support:Snapshot(); equal(body:find("private build error", 1, true), nil, "native errors are never embedded in support text")
Global("GetBuildInfo", function() return "1.60.1", "70862", "ignored", "16001" end)
Global("GetLocale", function() return "enUS" end)
Suite.db.upgradeHints = false
Combat(true); support:PrintStatus()
equal(#messages > 0, true, "chat status works without creating frames during combat")
equal(support.captured:find("Combat: yes", 1, true) ~= nil, true, "combat status preserves an explicitly requested copy snapshot")
Combat(false)

-- Copy UI uses native selection and retains native scroll/text scripts.
local made, nativeChanges = 0, 0
Global("CreateFrame", function(kind, name, parent, template)
    equal(InCombatLockdown(), false, "report widgets are never constructed in combat")
    equal(name, nil, "report UI adds no globals")
    made = made + 1
    local widget = Frame(); widget.parent = parent
    widget.Hide = function(self) local was = self.shown; self.shown = false; if was and self.OnHide then self:OnHide() end end
    widget.SetText = function(self, text) self.text = text; if self.OnTextChanged then self:OnTextChanged(false) end end
    widget.SetFocus = function(self) self.focused = true end
    widget.ClearFocus = function(self) self.focused = false end
    widget.HighlightText = function(self) self.highlighted = true end
    widget.RegisterEvent = function(self, event) self.event = event end
    widget.UnregisterAllEvents = function(self) self.event = nil end
    if template == "InputScrollFrameTemplate" then
        widget.EditBox = CreateFrame("EditBox", nil, widget)
        widget.CharCount = Frame()
        widget.EditBox:SetScript("OnTextChanged", function() nativeChanges = nativeChanges + 1 end)
    end
    return widget
end)
Combat(true); support:Open(); equal(made, 0, "combat open creates no widgets and queues no automatic opening")
local combatReport = support.captured
Combat(false); support:Open()
equal(support.frame:IsShown(), true, "copyable report opens outside combat")
equal(support.body, combatReport, "post-combat open copies the exact captured combat reasons and timestamp")
equal(support.captured, nil, "opening consumes the pending combat snapshot")
equal(support.caption.text:find("Captured combat snapshot", 1, true) ~= nil, true, "captured snapshot is clearly distinguished from current state")
equal(support.edit.text, support.body, "selectable text contains the entire report")
equal(nativeChanges > 0, true, "native text-height/scroll updates are retained")
equal(support.edit.focused and support.edit.highlighted, true, "report starts selected for Ctrl+C")
support.edit.text = "User edit"; support.edit.OnTextChanged(support.edit, true)
equal(support.edit.text, support.body, "typing cannot alter the captured support report")
local oldBody = support.body
Global("GetServerTime", function() return 2000010 end)
support.refresh.OnClick()
equal(support.body ~= oldBody, true, "explicit Refresh captures a new snapshot")
equal(support.body:find("Combat: no", 1, true) ~= nil, true, "Refresh replaces captured combat state with current context")
equal(support.caption.text:find("Current snapshot", 1, true) ~= nil, true, "refreshed report is labeled as current rather than captured")
support.select.OnClick(); equal(support.edit.highlighted, true, "Select all uses native selection without clipboard APIs")
Combat(true); oldBody = support.body; support.refresh.OnClick()
equal(support.body, oldBody, "combat Refresh cannot replace selected support text")
support.frame.OnEvent(support.frame, "PLAYER_REGEN_DISABLED")
equal(support.frame:IsShown(), false, "combat entry closes the report")
equal(support.body, nil, "closing releases the captured report")
equal(support.edit.text, "", "hidden editor retains no report text")
equal(support.edit.focused, false, "closing releases keyboard focus")
equal(support.frame.event, nil, "hidden report unregisters events")
Combat(false); SlashCmdList.WOWFOREVERSUITE("support")
equal(support.frame:IsShown(), true, "support command opens the copy UI")
support.edit.OnEscapePressed(); equal(support.frame:IsShown(), false, "Escape closes the report")
SlashCmdList.WOWFOREVERSUITE("diagnostics"); equal(support.frame:IsShown(), true, "diagnostics alias opens the same copy UI")
support.frame:Hide(); support.refresh.OnClick(); equal(support.frame:IsShown(), false, "stale refresh cannot reopen a closed report")
Suite.GUI:OpenPage("support")
equal(Suite.SettingsCatalog:Search("support report")[1].key, "supportOpen", "support report is discoverable from settings search")
Suite.GUI:Action("supportOpen"); equal(support.frame:IsShown(), true, "Support settings action opens the report")
support.frame:Hide(); equal(support.frame.OnUpdate, nil, "support report has no idle updater")
support.frame, support.edit, support.scroll, support.select, support.refresh, support.caption, support.captured = nil, nil, nil, nil, nil, nil, nil
for name, original in pairs(originals) do _G[name] = original.value end
Suite.db, Suite.pending, Suite.Print, Suite.loadedSavedVariables = saved.db, saved.pending, saved.print, saved.loaded
Suite.CombatBuffs.failure = saved.failure
scoring.character, scoring.owner, scoring.automaticProfile, scoring.class = saved.character, saved.owner, saved.automatic, saved.class
Combat(false); Suite.GUI:Select(saved.page or "overview"); Suite.GUI.frame:SetShown(saved.shown)
