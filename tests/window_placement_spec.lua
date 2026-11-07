local Suite, equal, Frame, Combat = ...
local root = UIParent
UIParent = { GetWidth = function() return 1600 end, GetHeight = function() return 1000 end,
    GetEffectiveScale = function() return 1 end }
local owner, child = Frame(), Frame()
owner:SetSize(400, 500); owner.rect = { 100, 400, 400, 500 }; owner:Show()
child:SetSize(300, 300)
equal(Suite.PlaceWindow(child, owner), true, "visible launcher supplies placement")
equal(child.point[4], 510, "child opens to right with gap")
equal(child.point[5], 600, "child top aligns with launcher")
equal(child.point[2], UIParent, "placement has no lasting launcher anchor")
owner.rect = { 1200, 400, 400, 500 }; Suite.PlaceWindow(child, owner)
equal(child.point[4], 890, "right screen edge prefers left side")
owner.rect = { 100, 400, 1400, 500 }; Suite.PlaceWindow(child, owner)
equal(child.point[5], 90, "wide launcher prefers clear space below")
owner.rect = { 100, 100, 1400, 300 }; Suite.PlaceWindow(child, owner)
equal(child.point[5], 410, "bottom edge prefers clear space above")
owner.rect = { 0, 0, 1600, 1000 }; Suite.PlaceWindow(child, owner)
equal(child.point[4] >= 0 and child.point[4] + 300 <= 1600, true, "unavoidable overlap remains on screen horizontally")
equal(child.point[5] >= 0 and child.point[5] + 300 <= 1000, true, "unavoidable overlap remains on screen vertically")
child:SetHeight(1200); Suite.PlaceWindow(child, owner)
equal(child.point[5] + 1200, 1000, "oversized window keeps header at screen top")
child:SetHeight(300)
owner.scale, child.scale, owner.rect = 0.5, 2, { 200, 800, 800, 1000 }
Suite.PlaceWindow(child, owner)
equal(child.point[4], 255, "mixed scales preserve ten UI units of gap")
equal(child.point[5], 150, "mixed scales align visible top edges")
local point = child.point
Combat(true)
equal(Suite.PlaceWindow(child, owner), false, "combat refuses placement")
equal(child.point, point, "combat preserves anchors")
Combat(false); owner:Hide()
equal(Suite.PlaceWindow(child, owner), false, "hidden launcher does not reposition window")
owner:Show()
equal(Suite.PlaceWindow(child, nil), false, "standalone open retains caller's placement")
equal(Suite.PlaceWindow(child, child), false, "self-launch cannot form an anchor cycle")
owner.IsProtected = function() return true end
equal(Suite.PlaceWindow(child, owner), false, "protected launcher is left alone")
owner.IsProtected = nil
child.IsForbidden = function() return true end
equal(Suite.PlaceWindow(child, owner), false, "forbidden destination is left alone")
child.IsForbidden = nil
owner.rect = { { secret = true }, 400, 400, 500 }
equal(Suite.PlaceWindow(child, owner), false, "restricted coordinates are never used")
owner.GetRect = function() error("unavailable") end
equal(Suite.PlaceWindow(child, owner), false, "unavailable geometry retains position")
owner.GetRect = function() return nil end
equal(Suite.PlaceWindow(child, owner), false, "unlaid-out launcher retains position")
owner.GetRect = nil
equal(Suite.PlaceWindow(child, owner), false, "missing geometry capability retains position")
owner.GetRect = function(self) return unpack(self.rect) end
owner.scale, child.scale, owner.rect = 1, 1, { 100, 400, 400, 500 }
child:Show(); Suite.PlaceWindow(child, owner)
Suite.PlaceWindow(owner, child)
equal(owner.point[2], UIParent, "opening launcher back from child cannot produce cyclic anchors")

-- GUI routes pass their top-level window, not a nested content panel or button.
local gui, training, supplies, expiry, mail = Suite.GUI, Suite.Training, Suite.SupplyChecklist, Suite.MailExpiry, Suite.Mail
local openTraining, openSupplies, openExpiry, openBook = training.Open, supplies.Open, expiry.Open, mail.OpenBook
training.Open = function(_, _, _, launcher) equal(launcher, gui.frame, "training launch carries Suite window") end
supplies.Open = function(_, launcher) equal(launcher, gui.frame, "checklist launch carries Suite window") end
expiry.Open = function(_, launcher) equal(launcher, gui.frame, "deadlines launch carries Suite window") end
mail.OpenBook = function(_, launcher) equal(launcher, gui.frame, "book launch carries Suite window") end
for _, action in ipairs({ "trainingOpen", "suppliesOpen", "mailDeadlines", "mailBook" }) do gui:Action(action) end
training.Open, supplies.Open, expiry.Open, mail.OpenBook = openTraining, openSupplies, openExpiry, openBook
UIParent = root
