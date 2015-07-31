local easing = {}
if makermod then
	makermod.easing = easing
end

easing['linear'] = function(n) return n end
easing['swing'] = function(x) return (math.cos(x * math.pi) / -2) + 0.5 end
easing['spring'] = function(x) return 1 - (math.cos(x * 4.5 * math.pi) * math.exp(x * -6)) end
easing['pulse'] = function(x) return (math.cos((x * (5 - 0.5) * 2) * math.pi) / -2) + 0.5 end
easing['wobble'] = function(x) return (math.cos(x * math.pi * 9 * x) / -2) + 0.5 end
	
easing['ease'] = function(x) return x ^ 2 end
easing['cubic'] = function(x) return x ^ 3 end
easing['quart'] = function(x) return x ^ 4 end
easing['quint'] = function(x) return x ^ 5 end
	
easing['expo'] = function(x) return 2 ^ (8 * (x-1)) end
easing['circ'] = function(x) return 1 - math.sin(math.acos(x)) end
easing['sine'] = function(x) return 1 - math.cos(x * math.pi / 2) end
easing['back'] = function(x) return (x ^ 2) * (2.618 * x - 1.618) end
easing['bounce'] = function(x)
	local a = 0
	local b = 1
	local value
	while true do
		if x >= ((7 - 4*a) / 11) then
			value = b * b - (((11 - 6*a - 11*x) / 4) ^ 2)
			break
		end
		a = a+b
		b = b/2
	end
	return value
end
easing['elastic'] = function(x)
	x = x-1;
	return 2 ^ (10 * x) * math.cos(20 * x * math.pi / 3)
end

-- outs & inouts
for k, v in pairs(easing) do
	easing[k .. 'Out'] = function(t) return (1 - v(1 - t)) end
	easing[k .. 'InOut'] = function(t)
		if t <= 0.5 then
			return easing[k](2 * t) / 2
		else
			return (2 - easing[k](2 * (1 - t))) / 2
		end
	end
end


-- for mmove list
easinglist = 'linear, swing, spring, pulse, wobble, ease, cubic, quart, quint, expo, circ, sine, back, bounce, elastic'


makermod.timerListeners['move'] = function(object)
	local now = GetRealTime()
	local delta = now - object.start
	if t > 1 then
		t = 1
	end

	local t = delta / object.dur
	if object.ease ~= 'linear' and easing[object.ease] then
		t = easing[object.ease](t)
	end
	local pos = object.pos + object.coords * t
	object.ent.position = pos

	if delta > object.dur then
		return false
	end
end

makermod.timerListeners['rotate'] = function(object)
	local now = GetRealTime()
	local delta = now - object.start

	local t = delta / object.dur
	if t > 1 then
		t = 1
	end

	if object.ease ~= 'linear' and easing[object.ease] then
		t = easing[object.ease](t)
	end
	local ang = object.from + object.angle * t
	object.ent.angles = ang

	if delta > object.dur then
		return false
	end
end

-- WIP movings
--[[local steps = {}
steps['ellipse_inf'] = function(object)
	local now = GetRealTime()
	local period = object.period
	local delta = (now - object.start) % period
	local t = delta / period
	local ang = t * 2 * 3.14159265358979
	local center = object.center

	local pos = Vector3(center.x + object.rx * math.cos(ang), center.y + object.ry * math.sin(ang), center.z)
	object.ent.position = pos
end

steps['ellipse'] = function(object)
	local now = GetRealTime()
	local delta = now - object.start
	if delta >= object.dur then
		return false
	end

	local t = delta / object.dur
	if object.ease ~= 'linear' and easing[object.ease] then
		t = easing[object.ease](t)
	end
	local angle = object.from + object.to * t
	-- converting from degrees to radians
	angle = (angle / 180) * 3.14159265358979323

	local center = object.center
	local pos = Vector3(center.x + object.rx * math.cos(angle), center.y + object.ry * math.sin(angle), center.z)
	object.ent.position = pos
end

steps['astroid_inf'] = function(object)
	local now = GetRealTime()
	local period = object.period
	local delta = (now - object.start) % period
	local t = delta / period
	local ang = t * 2 * 3.14159265358979
	local center = object.center

	local pos = Vector3(center.x + object.rx * (math.cos(ang) ^ 3), center.y + object.ry * (math.sin(ang) ^ 3), center.z)
	object.ent.position = pos
end

steps['astroid'] = function(object)
	local now = GetRealTime()
	local delta = now - object.start
	if delta >= object.dur then
		return false
	end

	local t = delta / object.dur
	if object.ease ~= 'linear' and easing[object.ease] then
		t = easing[object.ease](t)
	end
	local angle = object.from + object.to * t
	-- converting from degrees to radians
	angle = (angle / 180) * 3.14159265358979323

	local center = object.center
	local pos = Vector3(center.x + object.rx * (math.cos(angle) ^ 3), center.y + object.ry * (math.sin(angle) ^ 3), center.z)
	object.ent.position = pos
end

steps['spiral'] = function(object)
	local now = GetRealTime()
	local delta = now - object.start
	if delta >= object.dur then
		return false
	end

	local t = delta / object.dur
	if object.ease ~= 'linear' and easing[object.ease] then
		t = easing[object.ease](t)
	end
	local angle = object.from + object.to * t
	-- converting from degrees to radians
	angle = (angle / 180) * 3.14159265358979323

	local center = object.center
	local r = angle * object.k

	object.ent.position = Vector3(center.x + r * math.cos(angle), center.y + r * math.sin(angle), center.z)
end

steps['rotate'] = function(object)
	
	local now = GetRealTime()
	local delta = now - object.start
	if delta > object.dur then
		return false
	end

	local t = delta / object.dur
	if object.ease ~= 'linear' and easing[object.ease] then
		t = easing[object.ease](t)
	end

	local angles = Vector3(object.from.x + object.angle.x * t, object.from.y + object.angle.y * t, object.from.z + object.angle.z * t)
	object.ent.angles = angles
end

function AnimStep(object)

	if object.movingType and steps[object.movingType] then
		return steps[object.movingType](object)
	end

	local cur = GetRealTime()
	local delta = cur - object.start
	if delta > object.dur then
		return false
	end

	local t = delta / object.dur
	if object.ease ~= 'linear' and easing[object.ease] then
		t = easing[object.ease](t)
	end
	local pos = Vector3(object.pos.x + object.coords.x * t, object.pos.y + object.coords.y * t, object.pos.z + object.coords.z * t)
	object.ent.position = pos

end --]]