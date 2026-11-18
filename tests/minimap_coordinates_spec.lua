local Suite, equal, SetCombat = ...
local savedMenus = Suite.Menus
local map = Suite.Minimap
local oldMap, oldMenu, oldChat, oldChannels, oldPoint = C_Map, Suite.Menus, ChatFrameUtil, GetChannelList, UiMapPoint
local oldGuild, oldGroup, oldRaid, oldCreate = IsInGuild, IsInGroup, IsInRaid, CreateFrame
local oldChatInfo = C_ChatInfo
local locked, failSend = false, false
local oldStats, oldCoords = Suite.db.minimapStats, Suite.db.showCoordinates
local oldHistory = Suite.db.coordinateTellHistory
Suite.db.coordinateTellHistory = {}
local x, y, allowed, failPin = 0.355, 0.486, true, false
local pins, sent, menu = {}, {}, nil
local pinResult = true
C_Map = {
    GetBestMapForUnit = function() return 1 end,
    GetPlayerMapPosition = function() return { GetXY = function() return x, y end } end,
    GetMapInfo = function() return { name = "Loch Modan" } end,
    CanSetUserWaypointOnMap = function() return allowed end,
    SetUserWaypoint = function(point)
        if failPin then error("unsupported native pin") end
        pins[#pins + 1] = point
        return pinResult
    end,
    GetUserWaypointHyperlink = function() return "|Hwaypoint:1:3550:4860|h[Map Pin]|h" end,
}
UiMapPoint = { CreateFromCoordinates = function(id, px, py) return { mapID = id, x = px, y = py } end }
C_ChatInfo = {
    InChatMessagingLockdown = function() return locked end,
    SendChatMessage = function(text, channel, language, target)
        if failSend then error("native chat rejected send") end
        sent[#sent + 1] = { text = text, channel = channel, language = language, target = target }
    end,
}
GetChannelList = function() return 1, "General", false, 4, "Friends", false, 7, "Disabled", true end
IsInGuild, IsInGroup, IsInRaid = function() return true end, function() return false end, function() return false end
Suite.Menus = { CreateContextMenu = function(_, build)
    menu = {}
    build(nil, { CreateTitle = function(_, title) menu.title = title end,
        CreateButton = function(_, label, callback) menu[label] = callback end })
end }
CreateFrame = function(...)
    local frame = oldCreate(...)
    frame.SetFocus = function(self) self.focused = true end
    return frame
end
Suite.db.minimapStats, Suite.db.showCoordinates = true, true
map:Apply()
map.coordinates.OnClick()
equal(menu.title, "Share 35.5, 48.6", "coordinate menu captures current location")
equal(type(menu["Say"]), "function", "Say destination is available")
equal(type(menu["Tell..."]), "function", "Tell recipient entry is available")
equal(type(menu["Guild"]), "function", "guild destination follows membership")
equal(menu["Party"], nil, "party destination is absent when solo")
equal(type(menu["4. Friends"]), "function", "joined custom channel retains its real number")
equal(menu["7. Disabled"], nil, "disabled channels are excluded")
equal(#pins, 0, "opening menu does not place a pin")
equal(#sent, 0, "opening menu does not draft or send chat")
x, y = 0.1, 0.2
menu["4. Friends"]()
equal(sent[1].text, "Loch Modan 35.5, 48.6 |Hwaypoint:1:3550:4860|h[Map Pin]|h", "destination sends captured coordinates and native link together")
equal(sent[1].channel, "CHANNEL", "numbered channel uses native channel routing")
equal(sent[1].target, "4", "numbered channel retains its ID as the target")
equal(pins[1].x, 0.355, "pin uses captured position even after moving")
equal(pins[1].mapID, 1, "pin uses the captured map")
allowed = false
menu["Say"]()
equal(sent[2].text, "Loch Modan 35.5, 48.6", "unsupported map falls back to coordinates")
equal(#pins, 1, "unsupported map places no pin")
allowed, failPin = true, true
menu["Guild"]()
equal(sent[3].text, "Loch Modan 35.5, 48.6", "failed pin placement never shares an old native link")
failPin = false
for _, result in ipairs({ false, { secret = true } }) do
    pinResult = result
    equal(map:CoordinateMessage({ mapID = 1, x = 0.355, y = 0.486 }), "Loch Modan 35.5, 48.6", "unconfirmed waypoint placement never shares a stale pin link")
end
pinResult = true
menu["Tell..."]()
equal(map.tell:IsShown(), true, "Tell opens a recipient field")
assert(loadfile("tests/window_drag_fixture.lua"))(map.tell, equal, "coordinate recipient")
equal(map.tell.input:GetText(), "", "first Tell opens with a blank recipient")
equal(map.tell.recent:IsEnabled(), false, "empty history disables Recent")
map.tell.input:SetText("bad|name")
map.tell.input.OnEnterPressed()
equal(#sent, 3, "invalid whisper recipient cannot become slash-command text")
map.tell.input:SetText(" Jawn  Online ")
map.tell.input.OnEnterPressed()
equal(sent[4].target, "Jawn Online", "Tell accepts and normalizes first and last names without a realm")
equal(sent[4].channel, "WHISPER", "Tell uses the native whisper API")
equal(sent[4].text, sent[1].text, "Tell sends the same coordinates and pin in one message")
equal(map.tell:IsShown(), false, "sent Tell closes the recipient field")
equal(Suite.db.coordinateTellHistory[1], "Jawn Online", "sent Tell saves the full normalized name")
menu["Tell..."]()
equal(map.tell.input:GetText(), "", "remembered recipient never prepopulates Tell")
equal(map.tell.recent:IsEnabled(), true, "saved history enables Recent")
map.tell.recent.OnClick()
equal(type(menu["Jawn Online"]), "function", "Recent offers the saved full name")
menu["Jawn Online"]()
equal(map.tell.input:GetText(), "Jawn Online", "selecting Recent fills the field")
equal(#sent, 4, "selecting Recent does not send a message")
map:OpenCoordinateMenu()
map.tell.input:SetText("Jawn Online")
locked = true
local pinCount = #pins
map.tell.input.OnEnterPressed()
equal(#sent, 4, "chat lockdown prevents immediate sending")
equal(#pins, pinCount, "chat lockdown does not place a pin")
equal(map.tell:IsShown(), true, "restricted Tell retains its recipient for retry")
locked = { secret = true }
menu["Say"]()
equal(#sent, 4, "unreadable messaging permission prevents sending")
locked, failSend = false, true
map.tell.input.OnEnterPressed()
equal(map.tell:IsShown(), true, "native send error retains the Tell form")
failSend = false
equal(#Suite.db.coordinateTellHistory, 1, "restricted and rejected sends add no history")
for _, name in ipairs({ "Second Person", "Third Person", "Fourth Person", "Fifth Person", "Sixth Person" }) do
    map:AskCoordinateRecipient({ mapID = 1, x = 0.355, y = 0.486 })
    map.tell.input:SetText(name)
    map.tell.input.OnEnterPressed()
end
equal(#Suite.db.coordinateTellHistory, 5, "Tell history retains at most five recipients")
equal(Suite.db.coordinateTellHistory[1], "Sixth Person", "most recent recipient comes first")
equal(Suite.db.coordinateTellHistory[5], "Second Person", "sixth unique recipient evicts the oldest")
map:AskCoordinateRecipient({ mapID = 1, x = 0.355, y = 0.486 })
map.tell.input:SetText(" third  person ")
map.tell.input.OnEnterPressed()
equal(#Suite.db.coordinateTellHistory, 5, "reusing a recipient does not duplicate it")
equal(Suite.db.coordinateTellHistory[1], "third person", "reusing a recipient moves it to the top")
equal(Suite.db.coordinateTellHistory[2], "Sixth Person", "other recipients retain recency order")
local cleaned = map:CoordinateRecipients({ " Jawn  Online ", "jawn online", { secret = true }, "Bad| Name", "Other Person", "Sixth Person" })
equal(#cleaned, 2, "saved history normalization rejects invalid, duplicate and excess entries")
equal(cleaned[1], "Jawn Online", "saved history normalization preserves full names")
equal(Suite.Profiles.excluded.coordinateTellHistory, true, "recipient history stays outside settings profiles")
map:AskCoordinateRecipient({ mapID = 1, x = 0.355, y = 0.486 })
equal(map.tell.input:GetText(), "", "Tell still opens blank with five saved recipients")
map.tell:Hide()
local before = #sent
SetCombat(true)
menu["Say"]()
menu["Tell..."]()
equal(#sent, before, "stale menu callbacks do no work during combat")
equal(map.tell:IsShown(), false, "stale Tell callback creates no combat UI")
SetCombat(false)
x = { secret = true }
map:UpdateStats()
equal(map.coordinates.text.text, "--, --", "restricted position clears stale coordinates")
map:OpenCoordinateMenu()
equal(menu.title, "Coordinates unavailable", "restricted position offers no sharing actions")
equal(menu["Say"], nil, "restricted coordinates cannot be serialized")
x, y = 0, 0
equal(map:ReadCoordinates(), nil, "unavailable zero position is not reported as a real location")
x, y = 1.1, 0.5
equal(map:ReadCoordinates(), nil, "invalid coordinate range is rejected")
x, y = 0.3, 0.4
GetChannelList = function() return 2, "Trade", false end
map:OpenCoordinateMenu()
equal(menu["4. Friends"], nil, "leaving a channel removes it from the next menu")
equal(type(menu["2. Trade"]), "function", "newly joined channels appear without polling")
Suite.db.showCoordinates = false
map:Apply()
menu["2. Trade"]()
equal(#sent, before, "disabled coordinates invalidate existing menu actions")
equal(map.coordinates:IsShown(), false, "coordinate opt-out hides the custom row")
local native = MinimapCluster.MinimapContainer.PlayerCoords
equal(native:GetAlpha(), 0.8, "coordinate opt-out restores native opacity independently of square mode")
C_ChatInfo = oldChatInfo
C_Map, Suite.Menus, ChatFrameUtil, GetChannelList, UiMapPoint = oldMap, oldMenu, oldChat, oldChannels, oldPoint
IsInGuild, IsInGroup, IsInRaid, CreateFrame = oldGuild, oldGroup, oldRaid, oldCreate
Suite.db.minimapStats, Suite.db.showCoordinates = oldStats, oldCoords
Suite.db.coordinateTellHistory = oldHistory
map:Apply()

Suite.Menus = savedMenus
