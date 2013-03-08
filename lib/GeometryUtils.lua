local GeometryUtils

GeometryUtils = {}
GeometryUtils.getCollisionArea = function (box1, box2)

	local x11, y11, x12, y12 = box1:bbox()
	local x21, y21, x22, y22 = box2:bbox()

       return math.max(0, math.min(x12,x22) - math.max(x11,x21)) *
              math.max(0, math.min(y12,y22) - math.max(y11,y21))
end

return GeometryUtils