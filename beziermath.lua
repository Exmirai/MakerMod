local linePoint(x1, y1, x2, y2, t)
	local point = {}
	local i = 1 - t
	point['x'] = i * x1 + t * x2
	point['y'] = i * y1 + t * y2
	return point
end

local quadPoint(x1, y1, x2, y2, x3, y3, t)
	local point = {}
	local i = 1 - t
	point['x'] = i*i*x1 + 2*t*i*x2 + t*t*x3
	point['y'] = i*i*y1 + 2*t*i*y2 + t*t*y3
	return point
end

local cubPoint(x1, y1, x2, y2, x3, y3, x4, y4, t)
	local point = {}
	local i = 1 - t
	point['x'] = i*i*i*x1 + 3*t*i*i*x2 + 3*t*t*i*x3 + t*t*t*x4
	point['y'] = i*i*i*y1 + 3*t*i*i*y2 + 3*t*t*i*y3 + t*t*t*y4
	return point
end

local lineTan(x1, y1, x2, y2)
	return (y2 - y1) / (x2 - x1)
end

local quadTan(x1, y1, x2, y2, x3, y3, t)
	local i = 1 - t
	return (-1*i*y1 + y2*(1-2*t) + 2*y3*t) / (-1*i*x1 + x2*(1-2*t) + 2*x3*t)
end

local cubTan(x1, y1, x2, y2, x3, y3, x4, y4, t)
	local i = 1 - t
	return (-1*y1*i*i + y2*(i*i - 2*t*i) + y3*(2*t*i - t*t) + 3*t*t*y4) / (-1*x1*i*i + x2*(i*i - 2*t*i) + x3*(2*t*i - t*t) + 3*t*t*x4)
end
