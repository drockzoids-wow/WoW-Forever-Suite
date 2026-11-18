local Suite, equal = ...
local windows, prior = Suite.Windows, Suite.Windows.positions
local secret = { secret = true }
local account = { windowPositions = { Bag = { x = 0.2, y = -0.1, scale = 1.2 } }, settingsProfiles = {
    entries = { { id = "p1", values = { windowPositions = { Bag = { x = 0.3, y = 0.1, scale = 1.1 } } } } },
} }
local personal = { id = "p1", personal = true, overrides = {
    p1 = { windowPositions = { Bag = { x = -0.4, y = 0.1, scale = 0.8 } } },
} }
local first = windows:InitializeCharacter(nil, Suite.Copy(account), { id = "p1" })
equal(first.Bag.x, 0.3, "migration resolves the selected shared profile layout")
local second = windows:InitializeCharacter(nil, Suite.Copy(account), personal)
equal(second.Bag.x, -0.4, "migration preserves the character's legacy personal layout")
second.Bag.x = -0.2
equal(personal.overrides.p1.windowPositions.Bag.x, -0.4, "migration makes an independent copy")
local existing = windows:InitializeCharacter({ Bag = { x = 0.5, y = -0.1, scale = 1.3 } }, account, personal)
equal(existing.Bag.x, 0.5, "existing character layout wins over legacy profile and account")
equal(account.windowPositions, nil, "migration removes the obsolete live account layout")
local cleared = windows:InitializeCharacter({}, account, personal)
equal(next(cleared), nil, "an intentionally empty character layout never reimports legacy data")
local filtered = windows:InitializeCharacter({
    Good = { x = 0.1, y = -0.1, scale = 1 },
    Secret = secret, BadX = { x = secret, y = 0, scale = 1 },
    NaN = { x = 0/0, y = 0, scale = 1 }, Infinite = { x = 0, y = math.huge, scale = 1 },
    BadScale = { x = 0, y = 0, scale = 0 },
})
equal(filtered.Good.x, 0.1, "valid character geometry survives normalization")
for _, name in ipairs({ "Secret", "BadX", "NaN", "Infinite", "BadScale" }) do
    equal(filtered[name], nil, "invalid character geometry is discarded: " .. name)
end
equal(next(windows:InitializeCharacter(secret, account, personal)), nil, "restricted character root cannot trigger legacy fallback")

-- Reset clears the same table owned by the character, including during deferred work.
local tracked, bank, anchors, after = windows.tracked, Suite.OfflineBank, UpdateContainerFrameAnchors, Suite.AfterCombat
windows.tracked, Suite.OfflineBank, UpdateContainerFrameAnchors = {}, nil, nil
local current = windows:InitializeCharacter({ Bag = { x = 0.5, y = 0.1, scale = 1.2 } })
local pending
Suite.AfterCombat = function(_, callback) pending = callback end
windows:ResetAll()
equal(current.Bag.x, 0.5, "deferred reset retains positions until safe execution")
pending()
equal(windows.positions, current, "global reset preserves the character SavedVariables binding")
equal(next(current), nil, "reset clears the character's persistent table")
equal(first.Bag.x, 0.3, "reset leaves another character's independent layout unchanged")
windows.tracked, Suite.OfflineBank, UpdateContainerFrameAnchors, Suite.AfterCombat = tracked, bank, anchors, after
windows.positions = prior
