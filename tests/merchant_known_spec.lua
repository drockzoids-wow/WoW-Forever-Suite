local Suite, equal, Frame, SetCombat = ...
local names = { "CreateFrame", "MerchantFrame", "MERCHANT_ITEMS_PER_PAGE", "MerchantItem1", "MerchantItem2", "MerchantItem1ItemButton",
    "MerchantItem2ItemButton", "GetMerchantNumItems", "GetMerchantItemID", "GetMerchantItemLink", "C_TooltipInfo", "C_PetJournal", "C_Timer",
    "ITEM_SPELL_KNOWN", "ERR_COSMETIC_KNOWN", "MerchantFrame_UpdateMerchantInfo", "MerchantFrame_UpdateBuybackInfo", "hooksecurefunc" }
local previous = {}; for _, name in ipairs(names) do previous[name] = _G[name] end
local env = { modules = {}, db = { vendorKnownItems = false, autoRepair = false, autoSellJunk = false, autoVendor = false },
    pending = {}, IsReadable = Suite.IsReadable }
env.AfterCombat = function(key, callback)
    if InCombatLockdown() then env.pending[key] = callback else env.pending[key] = nil; callback() end
end
local function LeaveCombat()
    SetCombat(false); local pending = env.pending; env.pending = {}
    for _, callback in pairs(pending) do callback() end
end
local constructed, queries, timers, hooks = 0, 0, {}, {}
local function Secret() return { secret = true } end
CreateFrame = function(kind, name, parent)
    assert(not InCombatLockdown(), "merchant highlights never construct in combat")
    constructed = constructed + 1
    local frame = Frame(name); frame.parent = parent
    frame.IsProtected = function(self) return self.protected or false end
    frame.IsForbidden = function(self) return self.forbidden or false end
    frame.CreateTexture = function(self)
        assert(not InCombatLockdown(), "merchant textures wait for combat")
        local texture = Frame(); texture.parent = self
        texture.SetAllPoints = function(region, target) region.allPoints = target end
        texture.SetColorTexture = function(region, ...) region.color = { ... } end
        texture.SetVertexColor = function(region, ...) region.tint = { ... } end
        return texture
    end
    frame.SetAllPoints = function(self, target) self.allPoints = target end
    frame.registered = {}
    frame.RegisterEvent = function(self, event) self.registered[event] = true end
    frame.UnregisterAllEvents = function(self) self.registered = {} end
    for _, method in ipairs({ "SetAllPoints", "SetPoint", "SetSize", "SetFrameLevel" }) do
        local original = frame[method]
        frame[method] = function(self, ...) assert(not InCombatLockdown(), "merchant highlight geometry waits for combat"); return original(self, ...) end
    end
    return frame
end
local function Flush()
    local ready = timers; timers = {}
    for _, timer in ipairs(ready) do if not timer.cancelled then timer.callback() end end
end
C_Timer = { NewTimer = function(delay, callback)
    equal(delay, 0.05, "merchant updates use one short coalescer")
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }; timers[#timers + 1] = timer; return timer
end }
hooksecurefunc = function(name, callback) hooks[name] = callback end
MerchantFrame_UpdateMerchantInfo, MerchantFrame_UpdateBuybackInfo = function() end, function() end
MerchantFrame = Frame(); MerchantFrame:Show(); MerchantFrame.page, MerchantFrame.selectedTab = 1, 1
MERCHANT_ITEMS_PER_PAGE = 2
MerchantItem1, MerchantItem2 = Frame(), Frame()
MerchantItem1ItemButton, MerchantItem2ItemButton = Frame(), Frame()
local buttons = { MerchantItem1ItemButton, MerchantItem2ItemButton }
for index, button in ipairs(buttons) do
    button.parent = index == 1 and MerchantItem1 or MerchantItem2
    button.id = index; button.GetID = function(self) return self.id end; button:Show()
end
ITEM_SPELL_KNOWN, ERR_COSMETIC_KNOWN = "Schon bekannt", "Bereits gesammelt"
local data = { [1] = { lines = { { leftText = "Recipe" }, { rightText = "|cff00ff00Schon bekannt|r" } } },
    [2] = { lines = { { leftText = "Unknown recipe" } } } }
GetMerchantNumItems = function() return 4 end
GetMerchantItemLink = function(index) return "item:" .. index end
GetMerchantItemID = function(index) return index end
C_TooltipInfo = { GetMerchantItem = function(index) queries = queries + 1; return data[index] end }
C_PetJournal = nil
assert(loadfile("src/WoWForeverSuite/MerchantKnown.lua"))("WoWForeverSuite", env)
local known = env.MerchantKnown
known:Apply(); equal(constructed, 0, "disabled known-item feature creates nothing")
equal(queries, 0, "disabled known-item feature does not inspect stock")
env.db.vendorKnownItems = true; SetCombat(true); known:Apply()
equal(constructed, 0, "first enable waits for combat recovery")
LeaveCombat(); Flush()
local record = known.records[buttons[1]]
equal(record.frame:IsShown(), true, "localized already-known item turns green")
equal(known.records[buttons[2]], nil, "unknown stock is not highlighted or allocated")
equal(record.frame:GetParent(), MerchantItem1, "owned artwork inherits native row visibility")
equal(record.frame.mouseEnabled, false, "highlight cannot intercept purchases or native tooltips")
equal(record.icon.color[2] > record.icon.color[1], true, "owned icon wash is green")
equal(env.db.autoRepair or env.db.autoSellJunk or env.db.autoVendor, false, "highlighting enables no vendor automation")
equal(known:KnownText("Recipe: Schon bekannt"), false, "item names do not match a partial known phrase")
equal(known:KnownText(Secret()), false, "restricted tooltip text is never parsed")
equal(known:TooltipKnown({ lines = Secret() }), false, "restricted tooltip lists are unavailable")
equal(known:TooltipKnown({ lines = { Secret(), { leftText = Secret() } } }), false, "restricted rows and fields cannot imply ownership")
local before = queries
hooks.MerchantFrame_UpdateMerchantInfo(); hooks.MerchantFrame_UpdateMerchantInfo()
equal(queries, before, "native post-hooks queue without synchronous stock reads")
equal(#timers, 1, "burst native updates coalesce")
Flush()
MerchantFrame.page = 2; buttons[1].id, buttons[2].id = 3, 4
data[3] = { lines = { { leftText = "Unknown item" } } }; data[4] = { lines = { { leftText = ERR_COSMETIC_KNOWN } } }
hooks.MerchantFrame_UpdateMerchantInfo(); Flush()
equal(record.frame:IsShown(), false, "page reuse clears a formerly known row")
equal(known.records[buttons[2]].frame:IsShown(), true, "second page uses native absolute indices")
MerchantFrame.selectedTab = 2; hooks.MerchantFrame_UpdateBuybackInfo(); Flush()
equal(known.records[buttons[2]].frame:IsShown(), false, "Buyback has no green stock markers")
MerchantFrame.selectedTab, MerchantFrame.page = 1, 1; buttons[1].id, buttons[2].id = 1, 2
C_PetJournal = { GetPetInfoByItemID = function(id) if id == 2 then return nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,7 end end,
    GetNumCollectedInfo = function(species) equal(species, 7, "pet query uses readable species identifier"); return 1 end }
known:Queue(); Flush()
equal(known.records[buttons[2]].frame:IsShown(), true, "one collected pet copy is sufficient")
C_PetJournal.GetNumCollectedInfo = function() return 0 end
known.events.OnEvent(known.events, "PET_JOURNAL_LIST_UPDATE"); Flush()
equal(known.records[buttons[2]].frame:IsShown(), false, "uncollected pet loses its marker on journal update")
C_PetJournal.GetNumCollectedInfo = function() return Secret() end
known:Queue(); Flush(); equal(known.records[buttons[2]].frame:IsShown(), false, "secret pet count is not ownership")
C_PetJournal.GetPetInfoByItemID = function() error("unavailable") end
known:Queue(); Flush(); equal(known.records[buttons[2]].frame:IsShown(), false, "rejected pet query leaves the row native")
C_PetJournal = nil
local merchantGetter = C_TooltipInfo.GetMerchantItem
C_TooltipInfo.GetMerchantItem = function() error("not available") end
known:Queue(); Flush(); equal(record.frame:IsShown(), false, "rejected tooltip query clears prior state")
C_TooltipInfo.GetMerchantItem = merchantGetter
C_TooltipInfo.GetHyperlink = function(link) if link == "item:2" then return { lines = { { leftText = ITEM_SPELL_KNOWN } } } end end
known:Queue(); Flush(); equal(known.records[buttons[2]].frame:IsShown(), true, "matching-link tooltip can resolve missing merchant metadata")
C_TooltipInfo.GetHyperlink = nil
data[2] = nil; known:Queue(); Flush()
equal(known.records[buttons[2]].frame:IsShown(), false, "pending item metadata does not retain an old marker")
data[2] = { lines = { { leftText = ITEM_SPELL_KNOWN } } }
known.events.OnEvent(known.events, "TOOLTIP_DATA_UPDATE"); Flush()
equal(known.records[buttons[2]].frame:IsShown(), true, "asynchronous tooltip metadata can resolve the visible stock")
known.events.OnEvent(known.events, "SPELLS_CHANGED"); Flush()
equal(known.records[buttons[2]].frame:IsShown(), true, "learning updates known stock without reopening")
buttons[1].id = Secret(); known:Queue(); Flush()
equal(record.frame:IsShown(), false, "restricted native row ID cannot be used for another item")
buttons[1].id = 1
MerchantFrame.page = Secret(); known:Queue(); Flush()
equal(known.records[buttons[2]].frame:IsShown(), false, "restricted page data clears recycled markers")
MerchantFrame.page = 1
known:Queue(); Flush()
SetCombat(true); local count, reads = constructed, queries
record.frame.protected = true
known.events.OnEvent(known.events, "PLAYER_REGEN_DISABLED")
hooks.MerchantFrame_UpdateMerchantInfo()
equal(constructed, count, "combat never constructs or anchors highlights")
equal(queries, reads, "combat does not inspect tooltips or pet ownership")
env.db.vendorKnownItems = false; known:Apply(); LeaveCombat()
equal(record.frame:IsShown(), false, "disable clears protected owned artwork after combat")
equal(next(known.events.registered), nil, "disable releases all feature events")
equal(known.work, nil, "disable cancels pending work")
known:Queue(); equal(#timers, 0, "disabled hooks cannot start work")
env.db.vendorKnownItems = true; known:Apply(); known.events.OnEvent(known.events, "MERCHANT_CLOSED"); Flush()
equal(record.frame:IsShown(), false, "close cancels queued refresh and clears artwork")
MerchantFrame:Hide(); before = queries; known:Queue(); Flush()
equal(queries, before, "closed merchants have no background polling")
env.db.vendorKnownItems = false; known:Apply()
for _, name in ipairs(names) do _G[name] = previous[name] end
equal(Suite.InitializeDB(nil).vendorKnownItems, false, "new vendor highlights default off")
equal(Suite.SettingsCatalog:Search("merchant green collected")[1].key, "vendorKnownItems", "known-item highlighting is searchable in Vendor settings")
SetCombat(false)
