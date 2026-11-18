local frame, equal, name = ...
local header = frame.suiteDragHeader
equal(type(header), "table", name .. " has a drag surface")
equal(header:GetParent(), frame, name .. " owns the drag surface")
equal(frame:IsMovable(), true, name .. " is movable")
equal(InCombatLockdown(), false, name .. " drag fixture is outside combat")
equal(frame:IsShown(), true, name .. " is shown before dragging")
if frame.IsProtected then equal(frame:IsProtected(), false, name .. " is unprotected before dragging") end
if frame.IsForbidden then equal(frame:IsForbidden(), false, name .. " is accessible before dragging") end
local position = frame.suiteManualPosition
header:OnDragStart()
equal(frame.moving, true, name .. " moves from its header")
header:OnDragStop()
equal(frame.moving, false, name .. " stops on release")
equal(frame.suiteManualPosition, true, name .. " remembers a manual move")
frame.suiteManualPosition = position
