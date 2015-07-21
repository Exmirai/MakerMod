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

-- outs
easing['swingOut'] = function(t) return 1 - easing['swing'](1 - t) end
easing['springOut'] = function(t) return 1 - easing['spring'](1 - t) end
easing['pulseOut'] = function(t) return 1 - easing['pulse'](1 - t) end
easing['wobbleOut'] = function(t) return 1 - easing['wobble'](1 - t) end
easing['easeOut'] = function(t) return 1 - easing['ease'](1 - t) end
easing['cubicOut'] = function(t) return 1 - easing['cubic'](1 - t) end
easing['quartOut'] = function(t) return 1 - easing['quart'](1 - t) end
easing['quintOut'] = function(t) return 1 - easing['quint'](1 - t) end
easing['expoOut'] = function(t) return 1 - easing['expo'](1 - t) end
easing['circOut'] = function(t) return 1 - easing['circ'](1 - t) end
easing['sineOut'] = function(t) return 1 - easing['sine'](1 - t) end
easing['backOut'] = function(t) return 1 - easing['back'](1 - t) end
easing['bounceOut'] = function(t) return 1 - easing['bounce'](1 - t) end
easing['elasticOut'] = function(t) return 1 - easing['elastic'](1 - t) end

-- inouts
easing['swingInOut'] = function(x)
	if x <= 0.5 then
		return easing['swing'](2 * x) / 2
	else
		return (2 - easing['swing'](2 * (1 - x))) / 2
	end
end
easing['springInOut'] = function(x)
	if x <= 0.5 then
		return easing['spring'](2 * x) / 2
	else
		return (2 - easing['spring'](2 * (1 - x))) / 2
	end
end
easing['pulseInOut'] = function(x)
	if x <= 0.5 then
		return easing['pulse'](2 * x) / 2
	else
		return (2 - easing['pulse'](2 * (1 - x))) / 2
	end
end
easing['wobbleInOut'] = function(x)
	if x <= 0.5 then
		return easing['wobble'](2 * x) / 2
	else
		return (2 - easing['wobble'](2 * (1 - x))) / 2
	end
end
easing['easeInOut'] = function(x)
	if x <= 0.5 then
		return easing['ease'](2 * x) / 2
	else
		return (2 - easing['ease'](2 * (1 - x))) / 2
	end
end
easing['cubicInOut'] = function(x)
	if x <= 0.5 then
		return easing['cubic'](2 * x) / 2
	else
		return (2 - easing['cubic'](2 * (1 - x))) / 2
	end
end
easing['quartInOut'] = function(x)
	if x <= 0.5 then
		return easing['quart'](2 * x) / 2
	else
		return (2 - easing['quart'](2 * (1 - x))) / 2
	end
end
easing['quintInOut'] = function(x)
	if x <= 0.5 then
		return easing['quint'](2 * x) / 2
	else
		return (2 - easing['quint'](2 * (1 - x))) / 2
	end
end
easing['expoInOut'] = function(x)
	if x <= 0.5 then
		return easing['expo'](2 * x) / 2
	else
		return (2 - easing['expo'](2 * (1 - x))) / 2
	end
end
easing['circInOut'] = function(x)
	if x <= 0.5 then
		return easing['circ'](2 * x) / 2
	else
		return (2 - easing['circ'](2 * (1 - x))) / 2
	end
end
easing['sineInOut'] = function(x)
	if x <= 0.5 then
		return easing['sine'](2 * x) / 2
	else
		return (2 - easing['sine'](2 * (1 - x))) / 2
	end
end
easing['backInOut'] = function(x)
	if x <= 0.5 then
		return easing['back'](2 * x) / 2
	else
		return (2 - easing['back'](2 * (1 - x))) / 2
	end
end
easing['bounceInOut'] = function(x)
	if x <= 0.5 then
		return easing['bounce'](2 * x) / 2
	else
		return (2 - easing['bounce'](2 * (1 - x))) / 2
	end
end
easing['elasticInOut'] = function(x)
	if x <= 0.5 then
		return easing['elastic'](2 * x) / 2
	else
		return (2 - easing['elastic'](2 * (1 - x))) / 2
	end
end

-- for mmove list
easinglist = 'linear, swing, spring, pulse, wobble, ease, cubic, quart, quint, expo, circ, sine, back, bounce, elastic'

-- WIP movings
local steps = {}
steps['ellipse'] = function(object)

	local now = GetRealTime()
	local period = object.period
	local delta = (now - object.start) % period
	local t = delta / period
	local ang = t * 2 * 3.14159265358979
	local center = object.center

	local pos = Vector3(center.x + object.rx * math.cos(ang), center.y + object.ry * math.sin(ang), center.z)
	object.ent.position = pos
end

steps['astroid'] = function(object)

	local now = GetRealTime()
	local period = object.period
	local delta = (now - object.start) % period
	local t = delta / period
	local ang = t * 2 * 3.14159265358979
	local center = object.center

	local pos = Vector3(center.x + object.rx * ((math.cos(ang)) ^ 3), center.y + object.ry * ((math.sin(ang)) ^ 3), center.z)
	object.ent.position = pos
end

steps['spiral'] = function(object)

	local now = GetRealTime()
	local period = object.period
	local delta = (now - object.start)
	local t = delta / period
	local phi = t * 2 * 3.14159265358979
	local r = object.k * phi
	local center = object.center

	local pos = Vector3(center.x + r * math.cos(phi), center.y + r * math.sin(phi), center.z)
	object.ent.position = pos
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

end