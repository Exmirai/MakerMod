local easing = {}
easing['linear'] = function(n) return n end
easing['swing'] = function(x) return (math.cos(x * math.pi) / -2) + 0.5 end
easing['spring'] = function(x) return 1 - (math.cos(x * 4.5 * math.pi) * math.exp(x * -6)) end
easing['pulse'] = function(x) return (math.cos((x * (5 - 0.5) * 2) * math.pi) / -2) + 0.5 end
easing['wobble'] = function(x) return (math.cos(x * math.pi * 9 * x) / -2) + 0.5 end
	
easing['ease'] = function(x) return math.pow(x, 2) end
easing['cubic'] = function(x) return math.pow(x, 3) end
easing['quart'] = function(x) return math.pow(x, 4) end
easing['quint'] = function(x) return math.pow(x, 5) end
easing['easeOut'] = function(x) return 1 - math.pow(1 - x, 2) end
easing['cubicOut'] = function(x) return 1 - math.pow(1 - x, 3) end
easing['quartOut'] = function(x) return 1 - math.pow(1 - x, 4) end
easing['quintOut'] = function(x) return 1 - math.pow(1 - x, 5) end
	
easing['expo'] = function(x) return math.pow(2, 8 * (x-1)) end
easing['circ'] = function(x) return 1 - math.sin(math.acos(x)) end
easing['sine'] = function(x) return 1 - math.cos(x * math.pi / 2) end
easing['back'] = function(x) return math.pow(x, 2) * (2.618 * x - 1.618) end
easing['bounce'] = function(x)
	local a = 0
	local b = 1
	local value
	while true do
		if x >= ((7 - 4*a) / 11) then
			value = b * b - math.pow((11-6*a - 11*x) / 4, 2)
			break
		end
		a = a+b
		b = b/2
	end
	return value
end
easing['elastic'] = function(x)
	x = x-1;
	return math.pow(2, 10 * x) * math.cos(20 * x * math.pi / 3)
end

local function Animate(dur, ease, func)
	local ef = easing[ease]
	local start = GetRealTime()
	local finish = start + dur
	local timee
	local frame
		
	local function listener()
		timee = GetRealTime()
		if timee > finish then
			frame = 1
		else
			frame = (timee - start) / dur
		end
		frame = ef(frame)
		func(frame)
		if timee > finish then
			listener = function() end
		--	RemoveListener('JPLUA_EVENT_RUNFRAME')
		end
	end
	
	AddListener('JPLUA_EVENT_RUNFRAME', listener)
end
