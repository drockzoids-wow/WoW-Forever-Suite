local Suite, equal, Frame, Combat = ...
local supplies = Suite.SupplyChecklist
local saved = { db = Suite.db, supplies = supplies.db, page = supplies.page, scan = Suite.Inventory.ScanContainers }
local names = { "GetCursorInfo", "ClearCursor", "GameTooltip", "MouseIsOver", "C_Item", "C_Timer" }
local globals = {}; for _, name in ipairs(names) do globals[name] = _G[name] end
Combat(false); Suite.db = Suite.InitializeDB(nil)
local scans, clears, queries, requests, timers = 0, 0, 0, 0, {}
Suite.Inventory.ScanContainers = function() scans = scans + 1; return { items = {} } end
C_Item = { GetItemNameByID = function(id) return "Item " .. id end, RequestLoadItemDataByID = function() requests = requests + 1 end }
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }; timers[#timers + 1] = timer; return timer
end }
local function Flush()
    local work = timers; timers = {}
    for _, timer in ipairs(work) do if not timer.cancelled then timer.callback() end end
end
local entries = {}; for id = 100, 109 do entries[#entries + 1] = { id = id, wanted = 20 } end
supplies:InitializeCharacter({ entries = entries }); supplies.page = 1; supplies:Open()
local frame = supplies.frame
local oldFocus, oldClear = frame.quantity.SetFocus, frame.item.ClearFocus
frame.quantity.SetFocus = function(self) self.focused = true end
frame.item.ClearFocus = function(self) self.focused = false end
local kind, cursorID = "item", 777
GetCursorInfo = function() queries = queries + 1; return kind, cursorID, "|Hitem:999:0|h[Must not use fallback]|h" end
ClearCursor = function() clears = clears + 1; kind, cursorID = nil, nil end
frame.item:SetText("100"); frame.quantity:SetText("37"); frame.remove.OnClick()
equal(supplies.confirmRemove, 100, "fixture has a pending explicit removal")
local beforeScans = scans
frame.item.OnReceiveDrag(frame.item)
equal(frame.item:GetText(), "777", "drop accepts the cursor's validated item ID")
equal(frame.quantity:GetText(), "37", "drop preserves the typed target quantity")
equal(#supplies.db.entries, 10, "drop alone saves no target")
equal(clears, 1, "accepted drop cancels only the cursor placement once")
equal(supplies.confirmRemove, nil, "accepting an item cancels stale removal confirmation")
equal(frame.quantity.focused, true, "accepted drop focuses the quantity editor")
equal(scans, beforeScans, "dropping an item runs no bag scan")
equal(requests, 0, "uncached drop does not require item metadata or name resolution")
frame.save.OnClick()
equal(supplies.db.entries[11].id, 777, "explicit Save creates the dropped target")
equal(supplies.db.entries[11].wanted, 37, "explicit Save uses the unchanged chosen quantity")

kind, cursorID = "item", 888
frame.item.OnMouseDown(frame.item, "RightButton")
equal(frame.item:GetText(), "777", "right-click does not accept a held item")
equal(clears, 1, "right-click leaves the cursor untouched")
frame.item.OnMouseDown(frame.item, "LeftButton")
equal(frame.item:GetText(), "888", "click-to-place cursor input uses the same drop path")
equal(clears, 2, "click-to-place clears only its accepted item cursor")
local oldText, oldQuantity = frame.item:GetText(), frame.quantity:GetText()
local secret = setmetatable({ secret = true }, { __index = function() error("restricted cursor indexed") end, __tostring = function() error("restricted cursor formatted") end })
for _, case in ipairs({ { "spell", 10 }, { "macro", 10 }, { "money", 100 }, { "battlepet", 100 },
    { "item", 0 }, { "item", -1 }, { "item", 1.5 }, { "item", math.huge }, { "item", secret }, { secret, 777 } }) do
    kind, cursorID = case[1], case[2]; frame.item.OnReceiveDrag(frame.item)
    equal(frame.item:GetText(), oldText, "invalid/non-item/restricted cursor leaves the item editor unchanged")
    equal(frame.quantity:GetText(), oldQuantity, "rejected cursor preserves quantity")
    equal(clears, 2, "rejected cursor never calls ClearCursor or recovers an ID from its link")
end
kind, cursorID = nil, nil
frame.item.OnMouseDown(frame.item, "LeftButton")
equal(frame.item:GetText(), oldText, "ordinary editing clicks with an empty cursor are unchanged")
local nativeCursor, nativeClear = GetCursorInfo, ClearCursor
GetCursorInfo = function() error("private native cursor error") end
equal(supplies:ReceiveItem(), false, "native cursor failure is safely rejected")
GetCursorInfo = nativeCursor; kind, cursorID = "item", 999
ClearCursor = function() error("private native clear error") end
equal(supplies:ReceiveItem(), false, "failed cursor clearing cannot overwrite an existing draft")
equal(frame.item:GetText(), oldText, "failed clear leaves draft input intact")
equal(frame.status.text:find("private", 1, true), nil, "native errors are not exposed in status text")
ClearCursor = nil; equal(supplies:ReceiveItem(), false, "missing cursor capability retains pasted-ID/link input")
ClearCursor = function() return false end
equal(supplies:ReceiveItem(), false, "explicit cursor-clear refusal leaves the draft unchanged")
ClearCursor = function() return secret end
equal(supplies:ReceiveItem(), false, "restricted cursor-clear results are not interpreted as success")
ClearCursor = nativeClear
Combat(true); local oldQueries = queries; frame.item.OnReceiveDrag(frame.item)
equal(queries, oldQueries, "combat drop does not even inspect the cursor")
equal(clears, 2, "combat drop cannot clear cursor placement")
Combat(false); frame:Hide(); frame.item.OnReceiveDrag(frame.item)
equal(queries, oldQueries, "stale hidden drop events cannot inspect or change the cursor")
supplies:Open(); kind, cursorID = nil, nil

-- Native item tooltips must follow current row bindings, including recycled rows.
local tip, other = { shown = false, hides = 0, shows = 0 }, Frame()
tip.IsForbidden = function() return false end
tip.SetOwner = function(self, row, anchor) self.owner, self.anchor = row, anchor end
tip.IsOwned = function(self, row) return self.owner == row end
tip.SetItemByID = function(self, id) self.itemID = id end
tip.Show = function(self) self.shown = true; self.shows = self.shows + 1 end
tip.Hide = function(self) self.shown = false; self.hides = self.hides + 1 end
GameTooltip = tip
local hovered
MouseIsOver = function(row) return row == hovered end
local row = frame.rows[1]; hovered = row
beforeScans = scans; row.OnEnter(row)
equal(tip.itemID, 100, "hover uses the current row's item ID with tracking off")
equal(tip.owner, row, "native tooltip belongs to the hovered row")
equal(tip.anchor, "ANCHOR_RIGHT", "item tooltip is anchored beside the checklist row")
equal(tip.shown, true, "hover shows the native item tooltip without GetItem/GetUnit shims")
equal(scans, beforeScans, "hover does not rescan bags")
local nativeClick = row.OnClick; row.OnClick(row)
equal(frame.item:GetText(), "100", "row click still selects its editor target")
equal(frame.quantity:GetText(), "20", "row click retains its existing saved quantity behavior")
equal(row.OnClick, nativeClick, "tooltip installation leaves click handlers intact")
row.OnLeave(row); equal(tip.shown, false, "leaving a row hides its own tooltip")
row.OnEnter(row); tip.owner = other; local oldHides = tip.hides; row.OnLeave(row)
equal(tip.hides, oldHides, "leaving never dismisses a tooltip taken by another owner")
row.OnEnter(row); frame.next.OnClick()
equal(row.supplyID, 108, "paging rebinds row item IDs")
equal(tip.itemID, 108, "stationary hover refreshes the recycled row's tooltip")
equal(tip.owner, row, "recycled tooltip remains owned by the actual hovered widget")
row = frame.rows[8]; supplies.page = 1; supplies:Refresh(); hovered = row; row.OnEnter(row)
supplies.page = 2; supplies:Refresh()
equal(row.supplyID, nil, "unused rows clear old item IDs")
equal(tip.shown, false, "paging away from a hidden row cannot leave its old tooltip visible")
equal(supplies.hovered, nil, "hidden rows release tooltip bookkeeping")
row = frame.rows[1]; hovered = row; row.OnEnter(row)
Combat(true); frame.OnEvent(frame, "PLAYER_REGEN_DISABLED")
equal(tip.shown, false, "combat refresh hides the current checklist tooltip")
local oldShows = tip.shows; row.OnEnter(row)
equal(tip.shows, oldShows, "combat hover cannot populate a tooltip")
Combat(false); frame.OnEvent(frame, "PLAYER_REGEN_ENABLED")
row.OnEnter(row); frame:Hide()
equal(tip.shown, false, "closing the checklist hides its owned item tooltip")
equal(supplies.tooltip, nil, "closing releases the tooltip reference")
supplies:Open(); row = frame.rows[1]; hovered = row
tip.IsForbidden = function() return true end; row.OnEnter(row)
equal(supplies.hovered, nil, "forbidden tooltip is untouched")
tip.IsForbidden = function() return false end
local ownerSetter = tip.SetOwner
tip.SetOwner = function(self, owner) self.owner = owner; error("partial native owner failure") end
row.OnEnter(row)
equal(supplies.hovered, nil, "partially failed tooltip ownership is cleaned up")
equal(tip.shown, false, "partially owned tooltip does not remain visible")
tip.SetOwner = ownerSetter
local setter = tip.SetItemByID; tip.SetItemByID = nil; row.OnEnter(row)
equal(supplies.hovered, nil, "missing item tooltip method is optional")
tip.SetItemByID = function() error("native tooltip failure") end; row.OnEnter(row)
equal(supplies.hovered, nil, "failed item data setup releases hover state")
tip.SetItemByID = function(self) self.owner = other end; oldShows, oldHides = tip.shows, tip.hides
row.OnEnter(row)
equal(tip.shows, oldShows, "tooltip stolen during item callbacks is not shown by the checklist")
equal(tip.hides, oldHides, "tooltip stolen during callbacks is not hidden either")
tip.SetItemByID = setter; row.OnEnter(row)
local loaded = false
C_Item.GetItemNameByID = function(id) return loaded and "Loaded " .. id or nil end
supplies:Refresh(); loaded = true
supplies.events.OnEvent(supplies.events, "ITEM_DATA_LOAD_RESULT", row.supplyID); Flush()
equal(row.label.text:find("Loaded", 1, true) ~= nil, true, "metadata completion updates list wording through the existing coalescer")
equal(tip.itemID, row.supplyID, "metadata refresh keeps hovered item identity current")
tip.IsOwned = nil; tip.GetOwner = function(self) return self.owner end
row.OnEnter(row); row.OnLeave(row)
equal(tip.shown, false, "tooltip cleanup supports guarded GetOwner fallback")
frame:Hide(); frame.quantity.SetFocus, frame.item.ClearFocus = oldFocus, oldClear
for _, name in ipairs(names) do _G[name] = globals[name] end
Suite.Inventory.ScanContainers, Suite.db, supplies.db, supplies.page = saved.scan, saved.db, saved.supplies, saved.page
Combat(false)
