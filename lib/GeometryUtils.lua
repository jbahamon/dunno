--- Helper functions related to geometry, useful for collision analysis.
-- @class module
-- @name lib.GeometryUtils

local GeometryUtils

GeometryUtils = {}

--- Calculates the contact area between two rectangles
-- (specifically, two <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> rectangle shapes.
-- @tparam Shape box1 The first <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> rectangle.
-- @tparam Shape box2 The second <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> rectangle.
-- @treturn number The contact area, in <i>units</i>^2 (where the shapes' positions are measured in <i>units</i>)
GeometryUtils.getCollisionArea = function (box1, box2)

	local x11, y11, x12, y12 = box1:bbox()
	local x21, y21, x22, y22 = box2:bbox()

    return math.max(0, math.min(x12,x22) - math.max(x11,x21)) *
           math.max(0, math.min(y12,y22) - math.max(y11,y21))
end

--- Calculates whether a rectangle (specifically, a <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> rectangle shape)
--  intersects a certain range or not.The frontier of the range is considered as part of it.
-- @tparam Shape box The rectangle <a href="http://vrld.github.com/HardonCollider/">HardonCollider</a> to check.
-- @tparam vector topLeft The position of the upper-left corner of the range to check.
-- @tparam vector bottomRight The position of the bottom-right corner of the range to check.
-- @treturn bool Whether the box is in the specified range
GeometryUtils.isBoxInRange = function (box, topLeft, bottomRight) 
	local x1, y1, x2, y2 = box:bbox()

	if (x2 < topLeft.x) then return false end -- box is left of range
    if (x1 > bottomRight.x) then return false end -- box is right of range
    if (y2 < topLeft.y) then return false end -- box is above range
    if (y1 > bottomRight.y) then return false end -- box is below range

   	return true

end

--- Calculates whether a point is in a certain range or not. The frontier of the range is considered as part of it.
-- @tparam vector point The point  to check.
-- @tparam vector topLeft The position of the upper-left corner of the range to check.
-- @tparam vector bottomRight The position of the bottom-right corner of the range to check.
-- @treturn bool Whether the point is in the specified range
GeometryUtils.isPointInRange = function (point, topLeft, bottomRight)
  return point.x >= topLeft.x and point.x <= bottomRight.x and
         point.y >= topLeft.y and point.y <= bottomRight.y
end

return GeometryUtils