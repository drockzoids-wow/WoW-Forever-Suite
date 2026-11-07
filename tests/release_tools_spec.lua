local Suite, equal, Frame, Combat = ...
local supplies, mail, training = Suite.SupplyChecklist, Suite.MailExpiry, Suite.Training
local oldDB, oldPending = Suite.db, Suite.pending
local globals = { "CreateFrame", "C_Timer", "C_Item", "GetInboxNumItems", "GetInboxHeaderInfo", "GetServerTime", "GetCurrentRegion", "NUM_TOTAL_EQUIPPED_BAG_SLOTS", "MailFrame" }
local old = {}; for _, key in ipairs(globals) do old[key] = _G[key] end
local oldCharacter, oldScan = Suite.Inventory.Character, Suite.Inventory.ScanContainers
local oldDashboard = Suite.CharacterDashboard.RefreshView
local messages, oldPrint = {}, Suite.Print
Suite.Print = function(message) messages[#messages + 1] = message end
Combat(false); Suite.db = Suite.InitializeDB(nil); Suite.pending = {}
local made, scans, timers, now, loads = 0, 0, {}, 1000000, 0
CreateFrame = function(kind, name, parent)
    assert(not InCombatLockdown(), "release tools create no frames in combat")
    made = made + 1
    local frame = Frame(name); frame.parent, frame.registered = parent, {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    frame.Show = function(self) self.shown = true; if self.OnShow then self:OnShow() end end
    frame.Hide = function(self) self.shown = false; if self.OnHide then self:OnHide() end end
    frame.SetText = function(self, text) self.text = text; if self.OnTextChanged then self:OnTextChanged() end end
    return frame
end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
local function Flush()
    local work = timers; timers = {}
    for _, timer in ipairs(work) do if not timer.cancelled then timer.callback() end end
end
C_Item = { GetItemNameByID = function(id) return id == 100 and "Test reagent" end,
    RequestLoadItemDataByID = function() loads = loads + 1 end }
GetServerTime = function() return now end
GetCurrentRegion = function() return 110 end
NUM_TOTAL_EQUIPPED_BAG_SLOTS = 4
MailFrame = nil
local character = { name = "Test", realm = "ForeverPvE", region = 110 }
Suite.db.inventory.characters.test = character
Suite.Inventory.Character = function() return character, 110 end
Suite.CharacterDashboard.RefreshView = function() end
Suite.Inventory.ScanContainers = function(_, bags, bank)
    scans = scans + 1; equal(#bags, 5, "supplies count backpack and all carried bags")
    equal(bank, false, "supplies never request bank counts")
    return { items = { [100] = 7 }, at = now }
end
equal(Suite.db.supplyChecklist, false, "supply tracking starts off")
equal(Suite.db.mailExpiry, false, "mail recording starts off")
supplies:InitializeCharacter({ entries = { { id = 100, wanted = 20 }, { id = 100, wanted = 5 }, { id = -1, wanted = 9 } } })
equal(#supplies.db.entries, 1, "invalid and duplicate supply records are removed")
local launcher = Frame(); launcher:SetSize(300, 300); launcher:Show()
supplies:Open(launcher); equal(scans, 0, "opening disabled checklist does not scan bags")
equal(supplies.frame.point[1], "BOTTOMLEFT", "checklist uses its launcher for placement")
equal(supplies.rows[1].count, nil, "off is unknown rather than zero")
Suite.db.supplyChecklist = true; supplies:Apply()
equal(supplies.rows[1].count, 7, "counts current carried stock")
equal(supplies.rows[1].detail:find("Need 13", 1, true) ~= nil, true, "shortage is target minus current bags")
supplies:Save(100, 5); supplies:Refresh()
equal(supplies.rows[1].detail:find("Stocked", 1, true) ~= nil, true, "surplus is stocked")
supplies:Save(101, 20); supplies:Refresh(); supplies:Refresh()
equal(loads, 1, "unknown item data requested once per opening")
equal(supplies.rows[2].count, 0, "complete scan knows an absent item is zero")
Suite.Inventory.ScanContainers = function() return nil end; supplies:Refresh()
equal(supplies.rows[1].count, nil, "incomplete bag data never produces a false shortage")
equal(supplies:Save(100, 0), false, "zero target rejected")
local secret = { secret = true }; equal(supplies:Save(secret, 4), false, "restricted ID rejected before comparison")
supplies:Select(1); supplies.frame.remove.OnClick(); equal(supplies.confirmRemove, 100, "removal needs confirmation")
supplies.frame.quantity:SetText("6"); equal(supplies.confirmRemove, nil, "editing cancels removal")
supplies.frame.item:SetText("|cffffffff|Hitem:100:0|h[Test reagent]|h|r"); supplies.frame.save.OnClick()
equal(supplies.db.entries[1].wanted, 6, "pasted native link updates same target")
supplies.frame.remove.OnClick(); supplies.frame.remove.OnClick(); equal(#supplies.db.entries, 1, "confirmed removal affects only chosen target")
for id = 200, 216 do supplies:Save(id, 2) end
supplies:Refresh(); supplies.frame.next.OnClick(); equal(supplies.page, 2, "supply list pages")
Combat(true); local before = made
equal(supplies:Save(777, 5), false, "supply edits refuse combat")
supplies:Open(); mail:Open(); equal(made, before, "opening tools in combat constructs nothing")
Combat(false)
supplies.frame:Hide(); equal(next(supplies.events.registered), nil, "hidden checklist releases all events")
local savedSupplies = Suite.Copy(supplies.db); supplies:InitializeCharacter(savedSupplies)
equal(#supplies.db.entries, 18, "character checklist survives reinitialization")

local count, total, days = 2, 2, { 5, 0.5 }
GetInboxNumItems = function() return count, total end
GetInboxHeaderInfo = function(index) return nil, nil, "Sender", "Subject", 0, 0, days[index] end
mail:Apply(); equal(mail.events, nil, "disabled mail registers no recorder")
Suite.db.mailExpiry = true; mail:Apply()
mail:OnEvent("MAIL_SHOW"); Flush()
equal(character.mailExpiry.deadline, now + 43200, "earliest fractional-day deadline stored")
equal(character.mailExpiry.count, 2, "loaded letter count recorded")
count, total, days = 1, 5, { 2 }; mail:OnEvent("MAIL_INBOX_UPDATE"); Flush()
equal(character.mailExpiry.total, 5, "partial inbox retains reported total")
equal(mail:Summary(character.mailExpiry, now):find("Partial inbox (1/5)", 1, true) ~= nil, true, "partial coverage is disclosed")
local previous = character.mailExpiry
days[1] = secret; mail:OnEvent("MAIL_INBOX_UPDATE"); Flush()
equal(character.mailExpiry, previous, "restricted expiry preserves prior observation")
count, total = 0, 0; mail:OnEvent("MAIL_SHOW"); Flush()
equal(character.mailExpiry, previous, "initial empty mailbox does not clear saved data")
mail:OnEvent("MAIL_INBOX_UPDATE"); Flush()
equal(character.mailExpiry.count, 0, "confirmed empty inbox replaces old record")
count, total, days = 1, 1, { 1 }; mail:OnEvent("MAIL_INBOX_UPDATE"); mail:OnEvent("MAIL_CLOSED"); Flush()
equal(character.mailExpiry.count, 0, "closing cancels queued capture")
mail:OnEvent("MAIL_SHOW"); Flush(); previous = character.mailExpiry
days[1] = 3; mail:OnEvent("MAIL_INBOX_UPDATE"); Suite.db.mailExpiry = false; mail:Apply(); Flush()
equal(character.mailExpiry, previous, "disable cancels pending mail writes")
equal(next(mail.events.registered), nil, "disabled recorder has no event subscriptions")
Suite.db.inventory.characters.other = { name = "Other", realm = "Other", region = 1, mailExpiry = previous }
equal(#mail:Rows(), 1, "mail list stays within region")
now = previous.deadline + 1
equal(mail:Summary(previous, now):find("Recorded deadline passed", 1, true) ~= nil, true, "past deadline is an observation, not a deletion claim")
equal(mail:Validate({ at = 1, count = 1, total = 0, deadline = 5 }), nil, "invalid inbox totals rejected")
mail:Open(launcher); equal(#mail:Rows(), 1, "saved mail remains readable when disabled")
equal(mail.frame.point[1], "BOTTOMLEFT", "mail deadlines uses its launcher for placement")
Suite.db.mailExpiry = true; mail:Apply(); mail.warned = nil
local printed = #messages; mail:OnEvent("PLAYER_ENTERING_WORLD"); mail:OnEvent("PLAYER_ENTERING_WORLD")
equal(#messages, printed + 1, "near or passed deadline reminds only once per login")
Combat(true); mail.mailOpen = true; mail:Capture(true); equal(character.mailExpiry, previous, "mail capture is blocked in combat")
Combat(false); mail:OnEvent("MAIL_SHOW"); mail:OnEvent("PLAYER_ENTERING_WORLD"); Flush()
equal(character.mailExpiry, previous, "world transition cancels stale mailbox capture after login reminder")
equal(mail.mailOpen, nil, "world transition ends mailbox visit even without close event")
mail:OnEvent("MAIL_CLOSED"); mail.frame:Hide(); Suite.db.mailExpiry = false; mail:Apply()

-- Stable rank IDs, trained-cost exclusion and display filtering reuse the catalog.
local oldTrainingDB, oldWishlist, oldView = training.db, training.wishlistOnly, training.view
local oldSnapshot, oldIcon = Suite.TrainingCatalog.Snapshot, training.ClassIcon
local snapshot = { catalog = true, level = 60, rows = {
    { spellID = 11, name = "First", level = 10, cost = 100, state = "available", catalog = true },
    { spellID = 12, name = "First", rank = "Rank 2", level = 20, cost = 500, state = "used", catalog = true },
    { spellID = 13, name = "Unknown price", level = 30, state = "unavailable", catalog = true },
} }
Suite.TrainingCatalog.Snapshot = function() return snapshot end
training.ClassIcon = function() end
training:InitializeCharacter({ wishlist = { [11] = true, [12] = true, [13] = true, bad = true } })
local wishes, price, unknown, learned = training:Wishlist(snapshot)
equal(#wishes, 3, "wishlist preserves separate spell ranks")
equal(price, 100, "trained ranks excluded from estimated cost")
equal(unknown, 1, "missing prices counted explicitly")
equal(learned, 1, "learned rank is kept pinned and disclosed")
local restored = training:InitializeCharacter(Suite.Copy(training.db)); equal(restored.wishlist[12], true, "pins persist per character")
training.wishlistOnly, training.view = true, "class"; training:Open(); training.frame.search:SetText(""); training:Refresh()
equal(training.frame.group.text, "Pinned training", "wishlist renders its own filtered group")
equal(training.frame.rows[1].pin.label.text, "Unpin", "row exposes pinned state")
training.frame.rows[1].pin.OnClick(); equal(training.db.wishlist[11], nil, "unpin updates stable rank selection")
Combat(true); training:TogglePin(snapshot.rows[1]); equal(training.db.wishlist[11], nil, "pin mutation blocked in combat")
Combat(false); training.frame:Hide()
training.db, training.wishlistOnly, training.view = oldTrainingDB, oldWishlist, oldView
Suite.TrainingCatalog.Snapshot, training.ClassIcon = oldSnapshot, oldIcon
local page = Suite.GUI.page
Suite.GUI:OpenPage("whatsnew"); equal(Suite.GUI.page, "whatsnew", "What's New has a normal navigation route")
Suite.GUI:Action("newsSupplies"); equal(Suite.GUI.page, "supplies", "release feature links directly to its settings")
Suite.GUI:OpenPage(page)
for _, key in ipairs(globals) do _G[key] = old[key] end
Suite.Inventory.Character, Suite.Inventory.ScanContainers = oldCharacter, oldScan
Suite.CharacterDashboard.RefreshView, Suite.Print = oldDashboard, oldPrint
Suite.db, Suite.pending = oldDB, oldPending
Combat(false)
