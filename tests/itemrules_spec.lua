local Suite, equal, Frame, Combat = ...
local rules, vendor, deposit, sorter, bagspace = Suite.ItemRules, Suite.Vendor, Suite.BankDeposit, Suite.BagSort, Suite.BagSpace
local saved = { db = Suite.db, apply = Suite.Apply, print = Suite.Print, scan = Suite.Inventory.ScanContainers,
    reserves = rules.reserves, frame = rules.frame, page = rules.page, usage = rules.usage }
local names = { "C_Item", "C_Container", "C_Timer", "NUM_TOTAL_EQUIPPED_BAG_SLOTS", "CursorHasItem", "Enum", "CreateFrame", "GameTooltip", "MouseIsOver" }
local globals = {}; for _, name in ipairs(names) do globals[name] = _G[name] end
local methods = {}
local function Override(object, key, value) methods[#methods + 1] = { object, key, object[key] }; object[key] = value end
local originalDeposit, originalSort = {}, {}
for key, value in pairs(deposit) do originalDeposit[key] = value end
for key, value in pairs(sorter) do originalSort[key] = value end
Combat(false); Suite.db = Suite.InitializeDB(nil); rules:InitializeCharacter(nil); rules.frame, rules.usage = nil, nil
Suite.Apply = function() end
local messages, counts, scans, timers = {}, { [100] = 60 }, 0, {}
Suite.Print = function(text) messages[#messages + 1] = text end
NUM_TOTAL_EQUIPPED_BAG_SLOTS = 1
Suite.Inventory.ScanContainers = function() scans = scans + 1; return counts and { items = counts } or nil end
C_Timer = { NewTimer = function(delay, callback)
    local timer = { delay = delay, callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer; return timer
end }
local function Flush(delay)
    local work = timers; timers = {}
    for _, timer in ipairs(work) do
        if not timer.cancelled then
            if not delay or timer.delay == delay then timer.callback() else timers[#timers + 1] = timer end
        end
    end
end
local quality = 0
C_Item = { GetItemInfo = function() return "Test material", nil, quality, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, true end,
    GetItemNameByID = function(id) return "Item " .. id end }
local junk = { itemID = 100, stackCount = 40, quality = 0, isLocked = false, hasNoValue = false, hyperlink = "item:100" }
C_Container = { GetContainerItemInfo = function() return junk end }
equal(Suite.db.itemKeepRulesEnabled, false, "shared keep rules start off")
equal(Suite.db.professionUsage, false, "profession use annotations start off independently")
equal(rules:CanRemove(100, "sell", 60), true, "off adds no item action restriction")
equal(scans, 0, "disabled rules do not scan bags")
local normalized = rules:Normalize({ [100] = { neverSell = true }, [101] = { neverDelete = { secret = true } }, [-1] = { pauseSort = true } })
equal(normalized[100].neverSell, true, "valid account rule normalizes")
equal(normalized[101], nil, "restricted flags cannot enter normalized rules")
equal(normalized[-1], nil, "invalid item IDs cannot enter rules")
normalized[100].neverSell = false
equal(rules:Save(100, { neverSell = true, neverDelete = true }, 20), true, "explicit rule save opts in")
equal(rules:Enabled(), true, "saving enables account rules")
equal(rules:CanRemove(100, "sell", 1), false, "never sell blocks even a small stack")
equal(rules:CanRemove(100, "delete", 1), false, "never suggest deleting blocks trash candidates")
equal(rules:CanRemove(100, "deposit", 40), true, "sell and trash flags do not block allowed reagent deposits")
equal(rules:CanRemove(100, "deposit", 60), false, "whole-stack transfer cannot cross carried reserve")
equal(rules:Save(100, {}, 20), true, "reserve can exist without a shared protection flag")
equal(rules:CanRemove(100, "sell", 40), true, "reserve allows surplus stack sale")
equal(rules:CanRemove(100, "sell", 60), false, "reserve blocks full-stack sale")
equal(rules:CanRemove(100, "delete", 60), false, "reserve also protects trash suggestions")
counts = nil
local allowed, reason = rules:CanRemove(100, "deposit", 1)
equal(allowed, false, "incomplete carried inventory cannot prove a reserve is met")
equal(reason, "unavailable", "unknown counts are distinct from a known retained reserve")
equal(rules:MayBulkSell(), false, "unreadable bags prevent unsafe native bulk sale")
counts = { [100] = 60 }
equal(rules:MayBulkSell(), false, "bulk sale is blocked when a reserved gray item is carried")
quality = 1; equal(rules:MayBulkSell(), true, "known non-junk reserved materials do not block native gray sales")
quality = { secret = true }; equal(rules:MayBulkSell(), false, "hidden quality cannot justify a native bulk sale")
quality = 0
rules:Save(100, { pauseSort = true }, 0)
equal(rules:MaySort(), false, "carried pause-sort item suppresses Suite auto cleanup")
counts = {}; equal(rules:MaySort(), true, "absent protected item leaves cleanup available")
counts = nil; equal(rules:MaySort(), false, "unknown bags cannot prove cleanup is safe")
counts = { [100] = 60 }
Suite.db.itemKeepRules[100] = { neverSell = { secret = true } }
equal(rules:CanRemove(100, "sell", 1), false, "malformed active rule fails closed")
equal(rules:CanRemove({secret=true}, "sell", 1), false, "restricted item ID never becomes a key")
equal(rules:Reserve({secret=true}), nil, "reserve lookup guards restricted keys")
equal(rules:Save(100, {}, {secret=true}), false, "restricted reserve cannot replace an existing rule")
rules:Save(100, { neverSell = true, neverDelete = true }, 20)
local characterA = rules.reserves
rules:InitializeCharacter({ [100] = 7, [101] = -1, [102] = {secret=true} })
equal(rules:Reserve(100), 7, "second character gets its own reserve")
equal(rules:Rule(100).neverSell, true, "account keep flags remain shared across character bindings")
rules.reserves = characterA; equal(rules:Reserve(100), 20, "returning to first character restores its reserve")
equal(Suite.Profiles.excluded.itemKeepRules, true, "profile copies cannot replace safety rules")
equal(Suite.Profiles.excluded.itemKeepRulesEnabled, true, "profile switches cannot silently disable account protections")
Suite.db.bagSpaceBlacklist[300] = true
local found = false; for _, row in ipairs(rules:Rows()) do if row.id == 300 then found = true end end
equal(found, true, "existing trash blacklist is visible in the unified editor")
rules:Save(300, {}, 0); equal(Suite.db.bagSpaceBlacklist[300], nil, "explicitly clearing trash protection also clears the legacy entry")
Override(vendor, "BagExcluded", function() return false end)
equal(vendor:JunkInfo(0, 1), nil, "slow vendor path consults shared keep rules")
equal(bagspace:ReadSlot(0, 1, false), nil, "low-space suggestion path consults shared keep rules before item-data work")
local bulkCalls, slowCalls = 0, 0
Override(vendor, "InstantAvailable", function() return true end)
Override(vendor, "MerchantOpen", function() return true end)
Override(vendor, "SlowSale", function() slowCalls = slowCalls + 1 end)
Override(vendor, "Repair", function() end)
Override(Suite.Journey, "ReconcileVendor", function() end)
local oldVisit = vendor.visit; vendor.visit = { sent = 0 }
Suite.db.autoSellJunk, Suite.db.junkMode = true, "instant"
equal(vendor:SellInstant(function() bulkCalls = bulkCalls + 1 end), false, "instant confirmation cannot bypass protection")
equal(bulkCalls, 0, "blocked native bulk callback is never invoked")
vendor:Work(); equal(slowCalls, 1, "instant mode falls back to guarded slow selling")
vendor.visit = oldVisit
-- Native cleanup is never asked to pin an unsupported individual slot.
rules:Save(100, { pauseSort = true }, 0)
sorter.active, sorter.visit, sorter.work, sorter.timer = true, { frames = {} }, nil, nil
Suite.db.sortBagsOnOpen = true
Override(sorter, "HasOpenBag", function() return true end)
local sorts = 0; CursorHasItem = function() return false end
C_Container.SortBags = function() sorts = sorts + 1 end
sorter:Queue(); Flush(); equal(sorts, 0, "native SortBags is not called around a carried pause-sort item")
-- Re-evaluate fresh total before every whole-stack bank request.
rules:Save(100, {}, 20)
local transfers = 0
Enum = { BankType = { Character = 0 } }
Override(deposit, "Ready", function() return true end)
Override(deposit, "Current", function() return true end)
C_Container.UseContainerItem = function(_, _, _, bankType)
    equal(bankType, 0, "reserve-aware deposit retains explicit personal bank destination")
    transfers = transfers + 1
end
counts = { [100] = 60 }
deposit.job = { entries = { {id=100,count=20,bag=0,slot=1}, {id=100,count=20,bag=0,slot=2}, {id=100,count=20,bag=0,slot=3} }, index = 1 }
deposit:Step(); Flush(0.2)
equal(transfers, 1, "a timer cannot advance while the prior transfer is unconfirmed")
deposit:OnEvent("BAG_UPDATE_DELAYED"); Flush(0.2)
equal(transfers, 1, "an unrelated bag update cannot advance the batch")
counts[100] = 40
deposit:OnEvent("BAG_UPDATE_DELAYED"); Flush(0.2)
equal(transfers, 2, "the first confirmed transfer releases the next surplus stack")
counts[100] = 20
deposit:OnEvent("BAG_UPDATE_DELAYED"); Flush(0.2)
equal(transfers, 2, "the last stack cannot transfer past the reserve")
equal(counts[100], 20, "carried reserve remains after transfer")
counts[100] = 60
deposit.job = { entries = { {id=100,count=60,bag=0,slot=1} }, index = 1 }
deposit:Step(); equal(transfers, 2, "crossing stack remains intact rather than manipulating the cursor")
equal(messages[#messages]:find("Split off excess manually", 1, true) ~= nil, true, "retained excess has clear user feedback")
-- Real guide facts, with gaps retained and adjacent ranges merged.
rules.usage = nil
local linen = table.concat(rules:Usage(2589), "\n")
equal(linen:find("Used for Tailoring · guide skill 1–30", 1, true) ~= nil, true, "raw linen reports its actual tailoring guide band")
equal(linen:find("Used for First Aid · guide skill 1–80", 1, true) ~= nil, true, "adjacent first aid bands merge without duplicate lines")
local linenEngineering
for _, line in ipairs(rules:Usage(2589)) do if line:find("Engineering", 1, true) then linenEngineering = line end end
equal(linenEngineering:find("51–75, 90–100", 1, true) ~= nil, true, "noncontiguous engineering bands retain their gap")
equal(#rules:Usage(2147483647), 0, "unmodeled item does not acquire an invented profession use")
equal(#rules:Usage({secret=true}), 0, "tooltip lookup guards restricted item IDs")
Suite.db.professionUsage = true
local tip, record = Frame(), {}
rules:AddTooltip(tip, "item:2589", record); local lineCount = #tip.lines
rules:AddTooltip(tip, "item:2589", record)
equal(#tip.lines, lineCount, "tooltip annotations appear once per native tooltip lifecycle")
equal(lineCount > 1, true, "all matching professions appear")
local comparison = Frame(); comparison.IsForbidden = function() return false end
comparison.GetItem, comparison.GetUnit = nil, nil
Suite.Tooltips:Item(comparison, { id = 2589 })
equal(#comparison.lines, lineCount, "tooltip post-call uses supplied item data without legacy comparison methods")
Suite.Tooltips:Item(comparison, { id = 2589 })
equal(#comparison.lines, lineCount, "post-call lifecycle bookkeeping prevents duplicate profession uses")
local unavailableTip = Frame(); unavailableTip.IsForbidden = function() return false end
Suite.Tooltips:Item(unavailableTip, { id = {secret=true} })
equal(#unavailableTip.lines, 0, "unreadable supplied item IDs produce no tooltip annotations")
local keepTip = Frame(); rules:AddTooltip(keepTip, 100, {})
equal(keepTip.lines[1][1]:find("Keep carried: 20", 1, true) ~= nil, true, "reserve is visible on the item's tooltip")
Suite.db.professionUsage = false
local offTip = Frame(); rules:AddTooltip(offTip, 2589, {})
equal(#offTip.lines, 0, "profession-use toggle is independent of keep-rule processing")
-- Editor honors stale-item protection and combat guards.
CreateFrame = function(_, name, parent)
    assert(not InCombatLockdown(), "keep editor creates no frames in combat")
    local frame = Frame(name); frame.parent = parent
    frame.Show = function(self) self.shown = true; if self.OnShow then self:OnShow() end end
    frame.Hide = function(self) self.shown = false; if self.OnHide then self:OnHide() end end
    return frame
end
Suite.db.itemKeepRulesEnabled = false
SlashCmdList.WOWFOREVERSUITE("  KEEP  ")
equal(rules.frame:IsShown(),true,"keep slash command opens editor with keep rules disabled")
equal(Suite.db.itemKeepRulesEnabled,false,"opening keep editor never enables keep rules")
equal(rules.frame:GetNumPoints(),1,"first standalone keep open has a screen anchor")
equal(rules.frame.point[1],"CENTER","first keep command centers the editor without a launcher")
rules.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 50, -50)
rules.frame:Hide(); SlashCmdList.WOWFOREVERSUITE("itemrules")
equal(rules.frame.point[1],"TOPLEFT","standalone alias preserves an existing editor position")
local tip, owner, itemID, anchor, hides = Frame(), nil, nil, nil, 0
tip.IsForbidden = function() return false end
tip.SetOwner = function(_, row, mode) owner,anchor = row,mode end
tip.GetOwner = function() return owner end
tip.SetItemByID = function(_, id) itemID=id end
tip.Hide = function(self) self.shown=false; hides=hides+1 end
GameTooltip = tip
local row = rules.frame.rows[1]
row.OnEnter(row)
equal(itemID,row.itemID,"keep row opens native tooltip for its own item")
equal(anchor,"ANCHOR_CURSOR","keep tooltip stays beside hovered item rather than beyond wide row")
equal(tip:IsShown(),true,"keep item tooltip is visible")
row.OnLeave(row)
equal(tip:IsShown(),false,"leaving keep row clears tooltip")
row.OnEnter(row); MouseIsOver = function(widget) return widget == row end
rules:Refresh()
equal(rules.hovered,row,"same item remains inspectable across keep-rule refresh")
MouseIsOver = function() return false end
rules:Refresh()
equal(rules.hovered,nil,"keep refresh clears tooltip when pointer leaves")
row.OnEnter(row); local before=hides; owner=Frame(); rules:HideTooltip()
equal(hides,before,"keep cleanup leaves another tooltip owner intact")
local setter=tip.SetItemByID; tip.SetItemByID=nil; row.OnEnter(row)
equal(rules.hovered,nil,"missing native item lookup safely suppresses tooltip")
tip.SetItemByID=function() error("missing item") end; row.OnEnter(row)
equal(rules.hovered,nil,"failed native item tooltip does not retain ownership")
tip.SetItemByID=setter
row.OnEnter(row); row:Hide()
equal(rules.hovered,nil,"hidden keep row clears item tooltip")
rules:Refresh()
row.OnEnter(row); rules.frame:Hide()
equal(rules.hovered,nil,"closing keep editor clears its tooltip")
SlashCmdList.WOWFOREVERSUITE("keep")
row.OnEnter(row); Combat(true); rules:Refresh()
equal(rules.hovered,nil,"combat entry clears keep item tooltip")
itemID=nil; row.OnEnter(row)
equal(itemID,nil,"keep tooltip never opens in combat")
Combat(false); rules:Refresh()
rules:Select(100)
equal(rules.frame.reserve.text, "20", "editor loads this character's reserve")
equal(rules.frame.neverDelete.label.text, "Never suggest deleting", "checkbox labels use the shared theme control")
rules.frame.item:SetText("999"); rules.frame.reserve:SetText("3"); rules.frame.save.OnClick()
equal(rules:Reserve(999), 3, "explicit editor save creates a new reserve")
rules.frame.item:SetText("100"); rules.frame.reserve:SetText("1"); rules.frame.save.OnClick()
equal(rules:Reserve(100), 20, "typing an existing item cannot silently overwrite its unloaded rule")
rules:Select(100); rules.frame.remove.OnClick()
equal(rules:Reserve(100), 20, "removal requires confirmation")
rules.frame.reserve:SetText("21"); rules.frame.reserve.OnTextChanged()
equal(rules.confirmRemove, nil, "editing cancels removal confirmation")
Combat(true); rules.frame.OnEvent()
equal(rules.frame.save:IsEnabled(), false, "combat disables editor actions")
equal(rules:Save(100, {}, 0), false, "model edits reject combat too")
Combat(false); rules.frame.OnEvent(); rules.frame:Hide()
for index = #methods, 1, -1 do local entry = methods[index]; entry[1][entry[2]] = entry[3] end
for key in pairs(deposit) do deposit[key] = nil end; for key, value in pairs(originalDeposit) do deposit[key] = value end
for key in pairs(sorter) do sorter[key] = nil end; for key, value in pairs(originalSort) do sorter[key] = value end
Suite.db, Suite.Apply, Suite.Print, Suite.Inventory.ScanContainers = saved.db, saved.apply, saved.print, saved.scan
rules.reserves, rules.frame, rules.page, rules.usage = saved.reserves, saved.frame, saved.page, saved.usage
for _, name in ipairs(names) do _G[name] = globals[name] end
Combat(false)
