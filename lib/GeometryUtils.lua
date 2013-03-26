--- Helper functions related to geometry. Useful for collision analysis.
-- @class module
-- @name lib.GeometryUtils

local GeometryUtils

GeometryUtils = {}

--- Calculates the contact area between two rectangles
-- (specifically, two <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> rectangle shapes.
-- @param box1 The first <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> rectangle.
-- @param box2 The second <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> rectangle.
-- @return The contact area, in <i>units</i>^2 (where the shapes' positions are measured in <i>units</i>)
GeometryUtils.getCollisionArea = function (box1, box2)

	local x11, y11, x12, y12 = box1:bbox()
	local x21, y21, x22, y22 = box2:bbox()

       return math.max(0, math.min(x12,x22) - math.max(x11,x21)) *
              math.max(0, math.min(y12,y22) - math.max(y11,y21))
end

return GeometryUtils