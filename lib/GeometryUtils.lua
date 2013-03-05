local GeometryUtils

GeometryUtils = {}
GeometryUtils.getCollisionArea = function (x11, y11, x12, y12,
										   x21, y21, x22, y22)

       return math.max(0, math.min(x12,x22) - math.max(x11,x21)) *
              math.max(0, math.min(y12,y22) - math.max(y11,y21))
end

return GeometryUtils