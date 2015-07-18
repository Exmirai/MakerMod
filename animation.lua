local easing = {}
easing['linear'] = function(n) return n end
easing['swing'] = function(x) return (math.cos(x * math.pi) / -2) + 0.5 end
easing['spring'] = function(x) return 1 - (math.cos(x * 4.5 * math.pi) * math.exp(x * -6)) end
easing['pulse'] = function(x) return (math.cos((x * (5 - 0.5) * 2) * math.pi) / -2) + 0.5 end
easing['wobble'] = function(x) return (math.cos(x * math.pi * 9 * x) / -2) + 0.5 end
	
easing['ease'] = function(x) return x ^ 2 end
easing['cubic'] = function(x) return x ^ 3 end
easing['quart'] = function(x) return x ^ 4 end
easing['quint'] = function(x) return x ^ 5 end
easing['easeOut'] = function(x) return 1 - (1 - x) ^ 2 end
easing['cubicOut'] = function(x) return 1 - (1 - x) ^ 3 end
easing['quartOut'] = function(x) return 1 - (1 - x) ^ 4 end
easing['quintOut'] = function(x) return 1 - (1 - x) ^ 5 end
	
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

-- for mmove list
easinglist = 'linear, swing, spring, pulse, wobble, ease, cubic, quart, quint, expo, circ, sine, back, bounce, elastic'

function AnimStep(object)

--		temp.ent = ent
--		temp.start = GetRealTime()
--		temp.dur = dur
--		temp.ease = ease
--		temp.coords = vec

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