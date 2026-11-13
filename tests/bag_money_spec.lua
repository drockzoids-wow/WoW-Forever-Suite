local Suite, equal, Frame, SetCombat = ...
local feature = Suite.BagMoney
local oldDB, oldPending = Suite.db, Suite.pending
local old = { GetMoney = GetMoney, GetServerTime = GetServerTime, UnitGUID = UnitGUID,
    UnitName = UnitName, UnitClass = UnitClass, GetCurrentRegion = GetCurrentRegion,
    GetNormalizedRealmName = GetNormalizedRealmName, GetRealmName = GetRealmName,
    C_GameRules = C_GameRules, GameTooltip = GameTooltip, GetCoinTextureString = GetCoinTextureString,
    ContainerFrameCombinedBags = ContainerFrameCombinedBags, ContainerFrameContainer = ContainerFrameContainer,
    ContainerFrame1 = ContainerFrame1 }
local oldEvents, oldHooked, oldOwner = feature.events, feature.hooked, feature.owner
Suite.db, Suite.pending = Suite.InitializeDB(nil), {}
feature.events, feature.hooked, feature.owner = nil, {}, nil
equal(Suite.db.bagMoney, false, "money hover defaults off")
local balance, realm = 123456, "ForeverPvE"
GetMoney = function() return balance end
GetServerTime = function() return 1000 end
UnitGUID = function() return "Player-Money" end
UnitName = function() return "Current", "Surname" end
UnitClass = function() return "Mage", "MAGE" end
GetCurrentRegion = function() return 110 end
GetNormalizedRealmName = function() return realm end
GetRealmName = GetNormalizedRealmName
C_GameRules = nil
GetCoinTextureString = function(value) return "coins:" .. value end
local function Usable()
    local frame = Frame()
    frame.IsForbidden = function() return false end
    frame.IsProtected = function() return false end
    return frame
end
GameTooltip = Usable()
GameTooltip.SetOwner = function(self, owner) self.owner, self.lines = owner, {} end
GameTooltip.GetOwner = function(self) return self.owner end
ContainerFrameCombinedBags = Usable()
local moneyFrame = Usable()
ContainerFrameCombinedBags.MoneyFrame = moneyFrame
for _, key in ipairs({ "GoldButton", "SilverButton", "CopperButton" }) do moneyFrame[key] = Usable() end
local clicks = 0
moneyFrame.GoldButton:SetScript("OnClick", function() clicks = clicks + 1 end)
ContainerFrame1, ContainerFrameContainer = nil, nil
feature:Apply()
equal(feature.events, nil, "disabled money feature creates no events")
Suite.db.bagMoney = true
feature:Apply()
equal(Suite.db.inventory.characters["Player-Money"].profile.money, balance, "money captured independently of dashboard")
local characters = Suite.db.inventory.characters
local function Character(name, server, amount, region)
    return { name = name, realm = server, region = region or 110, profile = { money = amount, moneyAt = 900 } }
end
characters.alt = Character("Alt", "ClassicBetaPvE", 20000)
characters.pvp = Character("PvP", "ForeverPvP", 999999)
characters.foreign = Character("Foreign", "ForeverPvE", 999999, 1)
characters.unknown = Character("Unknown", "Unrecognized", 999999)
characters.empty = Character("Zero", "ForeverPvE", 0)
characters.missing = Character("Missing", "ForeverPvE", nil)
characters.invalid = Character("Invalid", "ForeverPvE", -1)
characters.secret = Character("Secret", "ForeverPvE", { secret = true })
local summary = feature:Summary()
equal(summary.total, 143456, "total includes current and same-type alts only")
equal(#summary.rows, 3, "zero balance included; foreign and unknown scopes excluded")
equal(summary.missing, 3, "missing invalid and restricted balances disclosed")
equal(summary.rows[1].guid, "Player-Money", "current character first")
local enter = moneyFrame.GoldButton.OnEnter
feature:Discover()
equal(moneyFrame.GoldButton.OnEnter, enter, "repeated discovery never duplicates hooks")
moneyFrame.GoldButton:OnClick()
equal(clicks, 1, "native coin click remains intact")
for _, key in ipairs({ "GoldButton", "SilverButton", "CopperButton" }) do
    moneyFrame[key]:OnEnter()
    equal(GameTooltip.lines[1][1], "Account money · PvE", "each denomination shows scoped tooltip")
    equal(GameTooltip:IsShown(), true, "money tooltip visible")
    moneyFrame[key]:OnLeave()
    equal(GameTooltip:IsShown(), false, "leaving money hides owned tooltip")
end
moneyFrame.GoldButton:OnEnter()
balance = 223456
feature:OnEvent("PLAYER_MONEY")
equal(feature:Summary().total, 243456, "live balance refreshed on money event")
equal(characters["Player-Money"].profile.money, balance, "money event persists current balance")
balance = { secret = true }
feature:Capture()
equal(characters["Player-Money"].profile.money, 223456, "restricted money preserves snapshot")
equal(feature:Summary().total, 20000, "restricted current money never uses stale balance")
local saved = Suite.InitializeDB(Suite.db)
equal(saved.inventory.characters.alt.profile.money, 20000, "alt money survives database normalization")
balance = 223456
SetCombat(true)
feature:OnEvent("PLAYER_REGEN_DISABLED")
equal(GameTooltip:IsShown(), false, "combat hides money tooltip")
moneyFrame.GoldButton:OnEnter()
equal(GameTooltip:IsShown(), false, "combat hover stays native")
SetCombat(false)
realm = "ForeverPvP"
summary = feature:Summary()
equal(summary.total, 999999, "switching type excludes PvE records")
realm = "Unrecognized"
equal(feature:Summary(), nil, "unknown current type never combines scopes")
realm = "ForeverPvE"
Suite.db.bagMoney = false
feature:Apply()
moneyFrame.GoldButton:OnEnter()
equal(GameTooltip:IsShown(), false, "disabled hooks remain inert")
feature.events:UnregisterAllEvents()
feature.events, feature.hooked, feature.owner = oldEvents, oldHooked, oldOwner
Suite.db, Suite.pending = oldDB, oldPending
-- Restore globals whose original value was nil as well.
for _, key in ipairs({ "GetMoney", "GetServerTime", "UnitGUID", "UnitName", "UnitClass", "GetCurrentRegion",
    "GetNormalizedRealmName", "GetRealmName", "C_GameRules", "GameTooltip", "GetCoinTextureString",
    "ContainerFrameCombinedBags", "ContainerFrameContainer", "ContainerFrame1" }) do _G[key] = old[key] end
