local Suite, equal, Frame, SetCombat = ...
local copy = Suite.ChatCopy
local oldCreate, oldSecret, oldClipboard, oldPrint = CreateFrame, issecretvalue, CopyToClipboard, Suite.Print
local secret, made, reads, messages, nativeTextChanges = {}, 0, 0, {}, 0
issecretvalue = function(value) return value == secret end
CopyToClipboard = function() error("Suite must never invoke the restricted clipboard function") end
Suite.Print = function(message) messages[#messages + 1] = message end
SetCombat(false)
CreateFrame = function(kind, name, parent, template)
    assert(not InCombatLockdown(), "copy window construction must stay outside combat")
    made = made + 1
    equal(name, nil, "copy window widgets add no globals")
    local widget = Frame(); widget.parent, widget.objectType = parent, kind
    widget.Hide = function(self)
        local shown = self.shown; self.shown = false
        if shown and self.OnHide then self.OnHide(self) end
    end
    widget.SetFocus = function(self) self.focused = true end
    widget.ClearFocus = function(self) self.focused = false end
    widget.HighlightText = function(self) self.highlighted = true end
    widget.RegisterEvent = function(self, event) self.event = event end
    widget.UnregisterAllEvents = function(self) self.event = nil end
    if template == "InputScrollFrameTemplate" then
        widget.EditBox = CreateFrame("EditBox", nil, widget)
        widget.EditBox:SetScript("OnTextChanged", function() nativeTextChanges = nativeTextChanges + 1 end)
        widget.CharCount = Frame()
    end
    return widget
end
local source = Frame()
source.IsForbidden = function() return false end
local rows = { "|cff00ff00First|r", "|Hitem:123|h[Fish]|h |Ticon:12|t |A:atlas:12:12|a", secret,
    "|Kq123|k hidden", "Last" }
source.GetNumMessages = function() return #rows end
source.GetMessageInfo = function(_, index) reads = reads + 1; return rows[index] end
for _, method in ipairs({ "SetTextCopyable", "SetMouseClickEnabled", "SetHyperlinksEnabled", "SetOnTextCopiedCallback",
    "GetChildren", "GetRegions", "SetFont" }) do
    source[method] = function() error("copying must leave native chat selection, fonts and rendered widgets alone") end
end
local text, omitted, count = copy:Snapshot(source)
local initialText = "|cffffffff|cff00ff00First|r|cffffffff|r\n|cffffffff[Fish]  |r\n|cffffffffLast|r"
equal(text, initialText, "copy text preserves inline colors and chronological link labels without artwork")
equal(omitted, true, "unavailable messages are disclosed without inspecting them")
equal(count, 3, "restricted values and hidden names are omitted")
equal(made, 0, "snapshot creates no UI")
source.GetNumMessages = function() return 1 end
source.GetMessageInfo = function() return "[Trade] |cff69ccf0Mage|r: |cffa335ee[Item]|r hello", 1, 0.5, 0.25 end
text = copy:Snapshot(source)
equal(text, "|cffff8040[Trade] |cff69ccf0Mage|r|cffff8040: |cffa335ee[Item]|r|cffff8040 hello|r",
    "native channel color surrounds preserved class/item colors and returns after each reset")
for _, bad in ipairs({ secret, math.huge, 0 / 0, -0.1, 1.1, "0.5" }) do
    source.GetMessageInfo = function() return "ordinary", bad, 0.5, 0.25 end
    equal(copy:Snapshot(source), "|cffffffffordinary|r", "unreadable or malformed native RGB safely uses white")
end
source.GetMessageInfo = function() return "black", 0, 0, 0 end
equal(copy:Snapshot(source), "|cff000000black|r", "valid zero-valued native color channels are preserved")
source.GetMessageInfo = function() return "", 1, 0.5, 0.25 end
text, omitted, count = copy:Snapshot(source)
equal(text, "", "color wrappers cannot invent a message for empty native text")
equal(count, 0, "empty messages do not increase copied message count")
source.GetNumMessages = function() return secret end
equal(copy:Snapshot(source), nil, "restricted message counts cannot drive iteration")
for _, invalid in ipairs({ -1, 0.5, math.huge, 0 / 0, "5" }) do
    source.GetNumMessages = function() return invalid end
    equal(copy:Snapshot(source), nil, "invalid native counts are rejected")
end
source.GetNumMessages = function() return 1000 end
reads = 0
source.GetMessageInfo = function(_, index) reads = reads + 1; return "Line " .. index end
text, omitted, count = copy:Snapshot(source)
equal(reads, 500, "copying reads a bounded recent window")
equal(count, 500, "recent snapshot retains at most 500 messages")
equal(text:sub(1, 18), "|cffffffffLine 501", "oldest included message is first")
equal(text:sub(-11), "Line 1000|r", "newest message is last and its color cannot bleed")
source.GetMessageInfo = function() return string.rep("a", 8192) end
text, omitted = copy:Snapshot(source)
equal(#text <= 131072, true, "large readable history is bounded in memory")
equal(omitted, true, "size-limited snapshot discloses omissions")
source.GetMessageInfo = function() error("native history unavailable") end
text, omitted, count = copy:Snapshot(source)
equal(text, "", "unavailable native rows produce no invented text")
equal(omitted, true, "failed native getters are disclosed")
source.IsForbidden = function() return true end
equal(copy:Snapshot(source), nil, "forbidden chat frames are not inspected")
source.IsForbidden = function() return false end
source.GetNumMessages = function() return #rows end
source.GetMessageInfo = function(_, index) return rows[index] end
SetCombat(true)
equal(copy:Snapshot(source), nil, "combat does not read native chat history")
copy:Open(source)
equal(made, 0, "combat open creates no widgets")
SetCombat(false)
copy:Open(source)
equal(copy.frame:IsShown(), true, "readable chat opens the Suite copy window")
equal(copy.edit.text, initialText, "only readable colored text reaches the edit box")
equal(copy.edit.focused, true, "copy text receives keyboard focus for Ctrl+C")
equal(copy.edit.highlighted, true, "opening selects text for native keyboard copying")
equal(copy.frame.event, "PLAYER_REGEN_DISABLED", "open window watches combat entry")
equal(copy.status.text:find("unavailable", 1, true) ~= nil, true, "window explains omitted messages")
local original = copy.body
copy.edit.text = "accidental edit"; copy.edit.OnTextChanged(copy.edit, true)
equal(copy.edit.text, original, "typing cannot replace the captured snapshot")
equal(nativeTextChanges, 1, "native template text/scroll updates survive the read-only observer")
local before = made
local savedPosition, selectedBeforeRefresh = copy.frame.point, SELECTED_CHAT_FRAME
SELECTED_CHAT_FRAME = Frame()
rows = { "Replacement" }; copy.refresh.OnClick(copy.refresh)
SELECTED_CHAT_FRAME = selectedBeforeRefresh
equal(made, before, "Refresh reuses the copy window")
equal(copy.edit.text, "|cffffffffReplacement|r", "Refresh replaces the snapshot with newly available messages")
equal(copy.owner, source, "Refresh keeps the original chat tab when the selected tab changes")
equal(copy.frame.point, savedPosition, "Refresh preserves the dragged window position")
source.IsForbidden = function() return true end
copy.refresh.OnClick(copy.refresh)
equal(copy.edit.text, "|cffffffffReplacement|r", "unavailable refresh leaves the previous readable snapshot intact")
source.IsForbidden = function() return false end
local otherSource = Frame()
otherSource.IsForbidden = function() return false end
otherSource.GetNumMessages = function() return 1 end
otherSource.GetMessageInfo = function() return "Other tab" end
copy:Open(otherSource)
equal(copy.edit.text, "|cffffffffOther tab|r", "copy window follows the requested native tab")
equal(copy.owner, otherSource, "native tab identity is retained only for window cleanup")
copy.edit.OnEscapePressed()
equal(copy.frame:IsShown(), false, "Escape closes the copy window")
equal(copy.body, nil, "closing releases the captured text")
equal(copy.owner, nil, "closing releases the source frame")
equal(copy.edit.text, "", "hidden edit box retains no chat snapshot")
equal(copy.edit.focused, false, "closing restores keyboard focus")
equal(copy.frame.event, nil, "hidden window unregisters combat events")
copy.refresh.OnClick(copy.refresh)
equal(copy.frame:IsShown(), false, "stale Refresh clicks cannot reopen a closed copy window")
copy:Open(source); SetCombat(true)
copy.refresh.OnClick(copy.refresh)
equal(copy.edit.text, "|cffffffffReplacement|r", "combat Refresh callbacks cannot replace the snapshot")
copy.frame.OnEvent(copy.frame, "PLAYER_REGEN_DISABLED")
equal(copy.frame:IsShown(), false, "combat entry closes existing copy UI")
SetCombat(false)
local oldSelected = SELECTED_CHAT_FRAME
SELECTED_CHAT_FRAME = otherSource
SlashCmdList.WOWFOREVERSUITE("copychat")
equal(copy.edit.text, "|cffffffffOther tab|r", "copychat command opens the selected native tab")
SELECTED_CHAT_FRAME = oldSelected
copy:Hide()
equal(copy.frame.OnUpdate, nil, "copy window has no idle updater")
copy.frame, copy.edit, copy.scroll, copy.status, copy.refresh = nil, nil, nil, nil, nil
CreateFrame, issecretvalue, CopyToClipboard, Suite.Print = oldCreate, oldSecret, oldClipboard, oldPrint
SetCombat(false)
