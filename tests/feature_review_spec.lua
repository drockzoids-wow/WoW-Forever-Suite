local Suite, equal, Frame, Combat = ...
local review, profiles = Suite.FeatureReview, Suite.Profiles
local saved = { db = Suite.db, frame = review.frame, view = review.view, page = review.page, rows = review.rows,
    preview = review.preview, guid = UnitGUID, addons = C_AddOns, create = CreateFrame, timer = C_Timer,
    tooltip = GameTooltip,
    personal = profiles.activePersonal, id = profiles.activeID, store = profiles.store, find = profiles.Find,
    draft = Suite.Setup.draft, guiPage = Suite.GUI.page, apply = Suite.Apply, print = Suite.Print,
    open = Suite.GUI.OpenPage, reveal = Suite.GUI.RevealSetting, menu = Suite.Menus.CreateContextMenu }
Combat(false); Suite.db = Suite.InitializeDB(nil)
review.frame, review.preview, review.page = nil, nil, 1
Suite.Print = function() end
for key, value in pairs(Suite.defaults) do
    if type(value) == "boolean" and not review.internal[key] then equal(review:Entry(key) ~= nil, true, "every boolean option has a readable settings destination: " .. key) end
end
local function Find(rows, key)
    for _, row in ipairs(rows) do if row.key == key then return row end end
end
local rows, counts = review:Features()
equal(#rows, 1, "fresh defaults show only the visible settings launcher as enabled")
equal(rows[1].key, "minimapButton", "launcher is the single default-on standalone feature")
Suite.db.minimapDrawerMoved = true
equal(Find(review:Features(nil, true), "minimapDrawerMoved"), nil, "stored layout marker is never reported as a feature")
equal(review:Value({secret=true}), nil, "restricted setting keys are not indexed")
equal(counts.waiting > 0, true, "default-on child preferences are counted separately")
equal(Find(rows, "missingBuffSelf"), nil, "disabled buff bar does not look like an active reminder feature")
rows = review:Features(nil, true)
equal(Find(rows, "missingBuffSelf").ready, false, "saved On view includes inactive child choices")
equal(Find(rows, "missingBuffSelf").detail:find("requires", 1, true) ~= nil, true, "waiting row explains its main switch")
Suite.db.missingBuffs, Suite.db.damageMeters = true, true
Suite.db.castbars = { player = { enabled = false, match = "target" }, target = { enabled = true } }
rows = review:Features()
equal(Find(rows, "missingBuffSelf").ready, true, "turning on parent makes saved child effective")
equal(Find(rows, "castbars.player.enabled") ~= nil, true, "matched castbar sizes count as enabled even with stale explicit false")
equal(Find(rows, "castbars.target.enabled") ~= nil, true, "manual castbar sizing is listed")
equal(Find(rows, "meterWindows.1.shown") ~= nil, true, "first default meter window is enabled with meters")
equal(Find(rows, "meterWindows.3.icons"), nil, "third hidden meter's icon preference is not an enabled feature")
equal(Find(rows, "meterWindows.2.pinSelf") ~= nil, true, "nested per-window preferences are included")
Suite.db.castbars.player = { secret = true }
equal(review:Value("castbars.player.enabled"), nil, "unreadable castbar record is unknown rather than off")
Suite.db.autoRepair = {secret=true}
rows, counts = review:Features()
equal(Find(rows, "autoRepair"), nil, "restricted switches never become enabled rows")
equal(counts.unknown > 0, true, "unreadable settings are disclosed")
Suite.db.autoRepair = false
profiles.activeID, profiles.activePersonal = "fixture", true
profiles.Find = function() return { name = "Shared test", values = { autoRepair = false, minimapButton = true, castbars = {} } } end
Suite.db.autoRepair = true
equal(review:Scope("autoRepair"), "Only this character", "unsaved personal differences use current values, not a stale override snapshot")
equal(review:Scope("minimapButton"), "Shared · Shared test", "unchanged personal settings still inherit shared scope")
equal(review:Scope("itemKeepRulesEnabled"), "Account-wide", "shared protection flag is not mislabeled as profile owned")
equal(review:Scope("autoRepair", { autoRepair = false }), "Setup draft · not applied", "staged false is a real draft override")
-- Native metadata queries only; all mutations and settings roots are traps.
local installed, loaded, enabled, calls, writes = {}, {}, {}, 0, 0
UnitGUID = function() return "current-character-guid" end
C_AddOns = {
    DoesAddOnExist = function(name) calls = calls + 1; return installed[name] == true end,
    IsAddOnLoaded = function(name) return loaded[name] == true, loaded[name] == true end,
    GetAddOnEnableState = function(name, character)
        equal(character, "current-character-guid", "addon enable state uses native current-character GUID")
        return enabled[name]
    end,
    EnableAddOn = function() writes = writes + 1; error("review must never enable another addon") end,
    DisableAddOn = function() writes = writes + 1; error("review must never disable another addon") end,
    LoadAddOn = function() writes = writes + 1; error("review must never load another addon") end,
}
Suite.db = Suite.InitializeDB(nil)
installed.Leatrix_Plus, enabled.Leatrix_Plus = true, 2
Suite.db.autoRepair = true
local overlaps, complete = review:Overlaps()
equal(#overlaps, 1, "only enabled matching Suite features generate guidance")
equal(overlaps[1].label, "Vendor automation", "known utility suite maps to concrete shared behavior")
equal(overlaps[1].detail:find("Enabled · not loaded", 1, true) ~= nil, true, "installed enable state is distinct from loaded evidence")
equal(complete, true, "readable known-addon metadata completes the bounded check")
enabled.Leatrix_Plus = 0
equal(#review:Overlaps(), 0, "installed but disabled addon is not warned as active overlap")
loaded.Leatrix_Plus = true
equal(#review:Overlaps(), 1, "still-loaded addon remains relevant even when disabled for next reload")
loaded.Leatrix_Plus = false; enabled.Leatrix_Plus = {secret=true}
overlaps, complete = review:Overlaps()
equal(overlaps[1].detail:find("state unknown", 1, true) ~= nil, true, "unknown enable state is labeled without guessing")
equal(complete, false, "restricted metadata cannot claim a complete inspection")
enabled.Leatrix_Plus = 2
Suite.db.autoRepair = false
overlaps = review:Overlaps({ autoRepair = true })
equal(#overlaps, 1, "setup's staged On choice participates before applying")
Suite.db.autoRepair = true
equal(#review:Overlaps({ autoRepair = false }), 0, "staged Off choice suppresses saved-on overlap")
installed.Questie, loaded.Questie = true, true
enabled.Leatrix_Plus = 0
Suite.db.autoRepair = false; Suite.db.autoQuestPickup = true
equal(#review:Overlaps(), 0, "Questie presence does not revive removed quest-location or comparison overlaps")
Suite.db.questTrackerSkin = true
equal(review:Overlaps()[1].label, "Quest tracker", "Questie guidance is restricted to the retained tracker domain")
local summary = review:SetupSummary({ autoRepair = true, questTrackerSkin = false })
equal(summary:find("staged choices", 1, true) ~= nil, true, "setup labels overlap evidence as a preview")
equal(summary:find("matching option is on", 1, true) ~= nil, true, "guidance never claims addon presence proves option ownership")
equal(Suite.db.autoRepair, false, "inspecting a staged plan changes no Suite choices")
equal(writes, 0, "metadata checks never mutate or load addons")
C_AddOns = nil
overlaps, complete = review:Overlaps()
equal(complete, false, "missing addon APIs are disclosed")
equal(#overlaps, 0, "missing APIs invent no installed addons")
Suite.db = Suite.InitializeDB(nil)
-- UI lifecycle, filtering, direct navigation and stale setup preview handling.
local timers, made = {}, 0
CreateFrame = function(_, name, parent)
    assert(not InCombatLockdown(), "feature review creates no frames during combat")
    made = made + 1
    local frame = Frame(name); frame.parent = parent; frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    frame.Show = function(self) self.shown = true; if self.OnShow then self:OnShow() end end
    frame.Hide = function(self) local shown = self.shown; self.shown = false; if shown and self.OnHide then self:OnHide() end end
    return frame
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
local function Flush()
    local work = timers; timers = {}; for _, timer in ipairs(work) do if not timer.cancelled then timer.callback() end end
end
local before = made; review:Apply()
equal(made, before, "hidden review creates nothing and registers no addon observer")
review:Open("enabled")
equal(review.frame:GetNumPoints() > 0,true,"standalone feature review has a screen position")
equal(review.frame:IsShown(), true, "explicit request opens enabled feature view")
equal(review.frame.registered.ADDON_LOADED, true, "only visible view observes addon loading")
review.frame.tabs.saved.OnClick()
equal(review.view, "saved", "saved On options has its own view")
equal(review.frame.tabs.enabled.label.textColor[1], 0.88, "previous tab returns to its normal appearance")
equal(review.frame.tabs.saved.label.textColor[1], 0.41, "selected tab has a distinct accent")
equal(#review.rows > 6, true, "long lists are paged")
review.frame.next.OnClick(); equal(review.page, 2, "paging reaches later preferences")
review.frame.search:SetText("does not exist"); review.frame.search.OnTextChanged(); Flush()
equal(#review.rows, 0, "search filters rather than mutating features")
equal(review.frame.empty:IsShown(), true, "filtered empty state is clear")
review.frame.search:SetText(""); review.frame.search.OnTextChanged(); Flush()
local destination, revealed
Suite.GUI.OpenPage = function(_, page) destination = page end
Suite.GUI.RevealSetting = function(_, entry) revealed = entry.key end
review:Go(review:Entry("minimapButton"))
equal(destination, "minimap", "enabled-feature link opens its canonical settings page")
equal(revealed, "minimapButton", "link reuses exact settings reveal")
equal(review.frame:IsShown(), false, "navigation dismisses review")
local draft = { squareMinimap = true }
Suite.Setup.draft, Suite.GUI.page = draft, "setup"
review:Open("overlaps", nil, draft)
equal(review.preview, draft, "setup opens a read-only staged preview")
destination = nil; review:Go(review:Entry("minimapButton"))
equal(destination, nil, "preview cannot discard the setup draft by following settings links")
equal(Suite.Setup.draft, draft, "preview retains staged choices")
local tooltip = Frame(); tooltip.IsForbidden = function() return false end
tooltip.ClearLines = function(self) self.lines = {} end
tooltip.SetOwner = function(self, owner) self.owner = owner end
tooltip.IsOwned = function(self, owner) return self.owner == owner end
GameTooltip = tooltip
local button = review.frame.rows[1]
button.featureRow = { label = "Vendor automation", detail = string.rep("Long addon name; ", 30), help = "Review each matching option.", keys = { "autoRepair" } }
review:Tooltip(button)
equal(tooltip.lines[2][1], button.featureRow.detail, "hover exposes complete long addon lists without clipping")
equal(tooltip:IsShown(), true, "guidance tooltip is visible")
tooltip.owner = Frame(); review:HideTooltip()
equal(tooltip:IsShown(), true, "review does not hide a tooltip taken by another owner")
review:Tooltip(button); review:HideTooltip()
equal(tooltip:IsShown(), false, "owned guidance tooltip is cleaned up")
Suite.Setup.draft = nil; review:Refresh()
equal(review.preview, nil, "stale draft cannot remain the displayed source after setup ends")
review:Queue(); local timer = review.timer
review.frame.header.OnDragStart()
Combat(true); before = made
review.frame.header:OnEvent("PLAYER_REGEN_DISABLED")
review.frame.OnEvent(review.frame, "PLAYER_REGEN_DISABLED")
equal(timer.cancelled, true, "combat transition cancels pending review work")
equal(review.frame.suiteDragging, nil, "combat ends review dragging")
review:Open("enabled"); equal(made, before, "combat open builds nothing")
equal(review.frame.tabs.enabled:IsEnabled(), false, "combat pauses navigation controls")
Combat(false); review.frame.OnEvent(review.frame, "PLAYER_REGEN_ENABLED"); Flush()
equal(review.frame.tabs.enabled:IsEnabled(), true, "controls recover after combat")
review:Queue(); timer = review.timer; review.frame:Hide(); Flush()
equal(timer.cancelled, true, "hiding cancels delayed work")
equal(next(review.frame.registered), nil, "hidden review releases all feature events")
Suite.db, Suite.Apply, Suite.Print = saved.db, saved.apply, saved.print
profiles.activePersonal, profiles.activeID, profiles.store, profiles.Find = saved.personal, saved.id, saved.store, saved.find
Suite.Setup.draft, Suite.GUI.page = saved.draft, saved.guiPage
Suite.GUI.OpenPage, Suite.GUI.RevealSetting, Suite.Menus.CreateContextMenu = saved.open, saved.reveal, saved.menu
UnitGUID, C_AddOns, CreateFrame, C_Timer = saved.guid, saved.addons, saved.create, saved.timer
GameTooltip = saved.tooltip
review.frame, review.view, review.page, review.rows, review.preview = saved.frame, saved.view, saved.page, saved.rows, saved.preview
Combat(false)
