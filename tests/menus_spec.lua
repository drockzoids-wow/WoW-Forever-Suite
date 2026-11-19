local Suite, equal, Frame, Combat = ...
local originalMenus, originalCreate, originalNative = Suite.Menus, CreateFrame, MenuUtil
local oldPending = Suite.pending
Suite.pending = {}
Combat(false)
local created = 0
CreateFrame = function(kind, name, parent, template)
    assert(not InCombatLockdown(), "menus never construct widgets during combat")
    created = created + 1
    local widget = originalCreate(kind, name, parent, template)
    widget.EnableKeyboard = function(self, value) self.keyboard = value end
    widget.SetPropagateKeyboardInput = function(self, value) self.propagates = value end
    widget.Hide = function(self)
        local shown = self.shown; self.shown = false
        if shown and self.OnHide then self:OnHide() end
    end
    return widget
end
MenuUtil = { CreateContextMenu = function() error("Suite lists must not use native shared menu pools") end }
assert(loadfile("src/WoWForeverSuite/Menus.lua"))("WoWForeverSuite", Suite)
local menus = Suite.Menus
local window = CreateFrame("Frame", nil, UIParent)
window:SetFrameStrata("DIALOG"); window:SetToplevel(true); window:SetFrameLevel(600)
local owner = CreateFrame("Button", nil, window)
window:Show()
owner:Show()
local selected, invoked = 2, 0
local function Build(_, root)
    root:CreateTitle("Choices")
    for i = 1, 25 do
        local row = root:CreateRadio("Choice " .. i, function() return selected == i end,
            function() selected = i; invoked = invoked + 1 end)
        if i == 1 then row:SetEnabled(false) end
    end
end
menus.CreateContextMenu(owner, Build)
equal(menus.frame:GetParent(), UIParent, "popup avoids clipping under scrolling settings")
equal(menus.frame.strata, "FULLSCREEN_DIALOG", "popup strata stays above a raised Contacts or Settings window")
equal(menus.list:GetParent(), menus.frame, "options share the dismissal surface's higher strata")
equal(#menus.rows, 12, "long lists allocate only the visible row capacity")
equal(menus.list.height, 296, "long list height stays bounded")
equal(menus.rows[3].marker:IsShown(), true, "current radio choice has a visible marker")
menus.rows[2]:OnClick()
equal(invoked, 0, "disabled options cannot invoke callbacks")
equal(menus.frame:IsShown(), true, "disabled selection keeps the list open")
menus.list:OnMouseWheel(-1)
equal(menus.offset, 3, "list scrolling advances through long choices")
menus.list:OnMouseWheel({ secret = true })
menus.list:OnMouseWheel(0/0)
equal(menus.offset, 3, "restricted and non-finite wheel values are ignored")
menus.rows[1]:OnClick()
equal(selected, 3, "a scrolled row invokes its current entry")
equal(invoked, 1, "selection runs exactly once")
equal(menus.frame:IsShown(), false, "selection dismisses before invoking an action")
equal(menus.rows[1].entry, nil, "dismissal releases stale callbacks")
local count = created
menus.CreateContextMenu(owner, Build)
equal(created, count, "reopening reuses bounded widgets")
menus.frame:OnKeyDown("A")
equal(menus.frame.propagates, true, "ordinary keyboard input passes through")
menus.frame:OnKeyDown("ESCAPE")
equal(menus.frame:IsShown(), false, "Escape closes the menu")
equal(menus.frame.propagates, false, "Escape is consumed by the menu")
menus.CreateContextMenu(owner, Build); owner:Hide()
equal(menus.frame:IsShown(), false, "owner hiding dismisses its popup")
owner:Show(); menus.CreateContextMenu(owner, Build); owner:SetEnabled(false)
equal(menus.frame:IsShown(), false, "owner disabling dismisses its popup")
owner:SetEnabled(true); menus.CreateContextMenu(owner, Build)
Combat(true); menus.rows[3]:OnClick()
equal(invoked, 1, "combat blocks option actions")
menus.frame:OnEvent("PLAYER_REGEN_DISABLED")
equal(menus.frame:IsShown(), false, "combat entry closes the popup")
menus.CreateContextMenu(owner, Build)
equal(created, count, "combat cannot create or reopen menu widgets")
equal(menus.frame:IsShown(), false, "combat keeps the list closed")
Combat(false)
menus.CreateContextMenu(owner, Build); menus.frame:OnClick()
equal(menus.frame:IsShown(), false, "click-away surface dismisses the popup")
menus.CreateContextMenu(owner, Build); menus.CreateContextMenu(owner, Build)
equal(menus.frame:IsShown(), false, "clicking the same selector toggles its list")
local action = Suite.Theme:ActionButton(owner, "Example", 100, 26, function() invoked = invoked + 1 end)
action:SetEnabled(false); action:OnClick()
equal(invoked, 1, "disabled shared actions cannot invoke their callback")
equal(action.label.textColor[4], 0.4, "disabled actions have the same dimmed text")
action:SetEnabled(true)
equal(action.label.textColor[4], 1, "reenabling restores shared action text")
action:OnClick()
equal(invoked, 2, "enabled action invokes its original callback")
equal(action:GetScript("OnEnter"), nil, "native highlight feedback leaves tooltip scripts available")
equal(action.highlightTexture ~= nil and action.pushedTexture ~= nil, true, "shared actions have native hover and press textures")
Suite.Menus, CreateFrame, MenuUtil, Suite.pending = originalMenus, originalCreate, originalNative, oldPending
