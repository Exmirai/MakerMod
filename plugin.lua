local plugin = RegisterPlugin("MakerMod", "2.0")

makermod = {}
makermod.objects = {}
makermod.objects.moving = {} -- for mmove
makermod.objects.attached = {} -- for mattachfx
makermod.players = {}
makermod.cvars = {}

makermod.commands = {}
makermod.timers = {} -- instead of objects.moving and objects.attached
makermod.timerListeners = {}

makermod.cvars['pain_maxdist'] = CreateCvar('makermod_pain_maxdistance', '199', CvarFlags.ARCHIVE)
makermod.cvars['pain_maxdmg'] = CreateCvar('makermod_pain_maxdamage', '100000000', CvarFlags.ARCHIVE)
makermod.cvars['max_arm'] = CreateCvar('makermod_arm_max', '1000', CvarFlags.ARCHIVE)

require(plugin['dirname'] .. '/animation.lua')
require(plugin['dirname'] .. '/toolgun.lua')

local function BlankFunc() end -----fucking lua without 'continue' statement


local function MainLoop()
	for id,data in pairs(makermod.players) do
		local ply = GetPlayer(id)
		if #makermod.players[ply.id]['grabbed'] > 0 then
			for k, ent in pairs(makermod.players[ply.id]['grabbed']) do
				local temp = JPMath.AngleVectors(ply.angles, true, false, false)
				temp = ply.position:MA(makermod.players[ply.id]['arm'], temp)
				ent.position = temp
				local ang = ply.angles
				ang.x = ent.angles.x
				ent.angles = ang
			end
		end
	end

	for k, v in pairs(makermod.timers) do
		if makermod.timerListeners[v.type] then
			if makermod.timerListeners[v.type](v) == false then
				makermod.timers[k] = nil
			end
		end
	end
end

AddListener('JPLUA_EVENT_RUNFRAME', MainLoop)


-- Registers user
function makermod.RegUser(ply)
	if makermod.players[ply.id] then return end

	local plyob = {}

	-- properties
	plyob.selected = nil
	plyob.grabbed = {}
	plyob.arm = 200
	plyob.movetime = 10000
	plyob.autograbbing = true
	plyob.names = {}
	plyob.objects = {}
	plyob.password = ''
	plyob.mark_position = nil
	plyob.marks = {}
	plyob.groups = {}

	-- commands
	plyob.print = function(str)
		SendReliableCommand(ply.id, string.format('print "%s\n"', str))
	end

	makermod.players[ply.id] = plyob

	if makermod.toolgun then
		makermod.toolgun.setupplayer(ply)
	end
end

AddListener('JPLUA_EVENT_CLIENTSPAWN', makermod.RegUser)


-- Adds a loop callback
function makermod.AddTimer(object)
	makermod.timers[#makermod.timers + 1] = object
end

-- Removes timers
function makermod.StopAllTimers(ent)
	for k, v in pairs(makermod.timers) do
		if v.ent == ent then
			makermod.timers[k] = nil
		end
	end
end

function makermod.StopTimersExceptRotate(ent)
	for k, v in pairs(makermod.timers) do
		if v.type ~= 'rotate' and v.ent == ent then
			makermod.timers[k] = nil
		end
	end
end

-- Adds new command
function makermod.AddCommand(name, func, selectedObj)
	if not func then
		print('Can\'t find function for command ' .. name .. '.')
		return
	end

	makermod.commands[name] = function(ply, args)
		-- lua_reload after player connect
		if not makermod.players[ply.id] then
			makermod.RegUser(ply)
		end

		if selectedObj then
			local ent = makermod.players[ply.id]['selected']
			if not ent then
				SendReliableCommand(ply.id, 'print "You have no selected objects.\n"')
				return
			end
			return func(ply, args, makermod.players[ply.id], ent)
		end

		return func(ply, args, makermod.players[ply.id])
	end

	AddClientCommand(name, makermod.commands[name])
end

-- Executes command from the player name
function makermod.Exec(command, ply, params)
	return makermod.commands[command](ply, params)
end

-- Runs multiple commands from the player name
function makermod.Run(code, ply)
	-- preprocessing
	local len = string.len(code)

	-- add ; at the end of commands
	if code.sub(code, len, len) ~= ';' then
		code = code .. ';'
		len = len + 1
	end

	-- remove spaces after ;
	code = string.gsub(code, '; ', ';')

	-- commands parsing
	local char
	local state = 1 -- 1: read command; 2: read arguments
	local currentCommand = ""
	local currentCommandId = 1
	local currentArguments = {}
	local currentArgument = ""
	local currentArgumentId = 1
	local inQuotes = false

	for i=1, len do
		char = string.sub(code, i, i)

		if char == ' ' then
			if state == 1 then
				state = 2
			elseif inQuotes then
				-- read arguments
				currentArgument = currentArgument .. " "
			else
				-- the next argument
				currentArguments[currentArgumentId] = currentArgument
				currentArgument = ""
				currentArgumentId = currentArgumentId + 1
			end
		elseif char == ';' then
			if inQuotes then
				currentArgument = currentArgument .. ";"
			else
				-- the next command
				currentArguments[currentArgumentId] = currentArgument
				currentArgument = ""
				currentArgumentId = 1

				if currentCommand == 'wait' then
					local delay = currentArguments[1]
					local next = string.sub(code, i+1, len)
					local data = {}
					data['type'] = 'runtimer'
					data['start'] = GetRealTime()
					data['delay'] = tonumber(delay)
					data['code'] = next
					data['player'] = ply
					makermod.AddTimer(data)
					return
				else
					makermod.Exec(currentCommand, ply, currentArguments)
				end

				currentCommand = ""
				currentCommandId = currentCommandId + 1
				currentArguments = {}
				state = 1
			end
		elseif char == "\"" then
			if inQuotes == true then
				inQuotes = false
			else
				inQuotes = true
			end
		else
			if state == 1 then
				-- read command name
				currentCommand = currentCommand .. string.lower(char)
			elseif state == 2 then
				-- read arguments
				currentArgument = currentArgument .. char
			end
		end
	end
end

makermod.timerListeners['runtimer'] = function(object)
	if object.start + object.delay <= GetRealTime() then
		makermod.Run(object.code, object.player)
		return false
	end
end




local function StopEntity(ent)
	for k, v in pairs(makermod.objects.moving) do
		if v.ent == ent then
			makermod.objects.moving[k] = nil
		end
	end
end

local function RemoveEntity(ent)
	StopEntity(ent)

	for k, v in pairs(makermod.objects.attached) do
		if v.ent == ent then
			makermod.objects.attached[k] = nil
		end
	end

	makermod.objects[ent.id] = nil
	ent:Free()
end

local function ParseVector(vec, args, startfrom)
		startfrom = startfrom or 0
		for i=1+startfrom, 3+startfrom do
			if i==1 then type = 'x' elseif i==2 then type = 'y' elseif i==3 then type='z' end
			if args[i] == nil then
				return vec
			else
				res = string.match(args[i], "+(%d+)")
				if res then
					vec[type] = vec[type] + res
				else
					res = string.match(args[i], "-(%d+)")
					if res then
						vec[type] = vec[type] - res
					else
						res = string.match(args[i], "%d+")
						if res then
							vec[type] = res
						end
					end
				end
			end
		end
		return vec
end

local function ParseNumber(args, count, startfrom, result)
	startfrom = startfrom or 0
	result = result or {}
	local i
	for i=1+startfrom, count+startfrom do
		if args[i] == nil then
				return vec
		else
				res = string.match(args[i], "+(%d+)")
				if res then
					result[i] = vec[type] + res
				else
					res = string.match(args[i], "-(%d+)")
					if res then
						result[i] = vec[type] - res
					else
						res = string.match(args[i], "%d+")
						if res then
							result[i] = res
						end
					end
				end
		
		end
	end
end

local function SetupEntity(ent, ply)
	local temp = {}
		temp['owner'] = ply
		temp['touchfuncs'] = {}
		temp['usefuncs'] = {}
		temp['connectedTo'] = {}
		temp['connectedFrom'] = {}
		temp['password'] = ''
		temp['name'] = ''
		temp['tele_destination'] = nil
		 
		
		
	local touchfunc = function(ent, from, trace)
						for _, r in pairs(temp['touchfuncs']) do ---Check Internal functions
							pcall(r, ent, from, trace)
						end
						
						for _, r in pairs(temp['connectedTo']) do  ---Check Connected Entities
							local data = makermod.objects[r]
							if not data then
							 	BlankFunc()
							else
								pcall(data['touchfunc'], ent, from, trace)
							end	
						end
	                  end
					  
	local usefunc = function(ent, from, activator)
				if (from.player ~= nil ) and (makermod.objects[ent.id]['password'] ~= '') then ---check for password
					if makermod.players[from.player.id]['password'] ~= makermod.objects[ent.id]['password'] then return end
				end
				
						for _, r in pairs(temp['usefuncs']) do ---Check Internal functions
							pcall(r, ent, from, activator)
						end
						
						for _, r in pairs(temp['connectedTo']) do ---Check Connected Entities
							local data = makermod.objects[r]
							if not data then
							 	BlankFunc()
							else
								pcall(data['usefunc'], ent, from, trace)
							end	
						end
	                  end
		temp['touchfunc'] = touchfunc
		temp['usefunc'] = usefunc
		
		ent:SetTouchFunction(touchfunc)
		ent:SetUseFunction(usefunc)
		
	makermod.objects[ent.id] = temp
end

function TraceEntity(ply, dist)
	if not ply then return end
	if not dist then dist = 16384 end
	local pos = ply.position
	pos.z = pos.z + 36.0
	local angles = JPMath.AngleVectors(ply.angles,true, false, false)
	local endPos = pos:MA(dist, angles)
	local mask = Contents.Solid | Contents.Slime | Contents.Lava | Contents.Terrain | Contents.Body | Contents.Item | Contents.Corpse
	local trace = RayTrace(pos, 0, endPos, ply.id,mask)
	return trace
end

local function CheckEntity(ent, ply)
		if not makermod.objects[ent.id] then
		--	SetupEntity(ent, 'map_object')
			SendReliableCommand(ply.id, string.format('print "You cannot select map object!\n"'))
			return false
		else
			local data = makermod.objects[ent.id]
			if data['owner'] ~= plyob then
				SendReliableCommand(ply.id, string.format('print "You are not owner of this entity!\n"'))
				return false
			end
			if data['owner'] == 'map_object' then
				SendReliableCommand(ply.id, string.format('print "You cannot select map object!\n"'))
				return false
			end
		end
		return true
end

local function onUserDisconnect(ply)
	for _, ent in pairs(makermod.players[ply.id]['objects']) do
		makermod.objects[ent.id] = nil
		ent:Free()
	end
	makermod.players[ply.id] = nil
end
AddListener('JPLUA_EVENT_CLIENTDISCONNECT',onUserDisconnect)




--[[
		## Makermod Commands ##
  ]]--


-- Special objects
local specialObjects = {
	stunbaton = 'weapon_stun_baton',
	melee = 'weapon_melee',
	saber = 'weapon_saber',
	blasterpistol = 'weapon_blaster_pistol',
	concussionrifle = 'weapon_concussion_rifle',
	bryarpistol = 'weapon_bryar_pistol',
	blaster = 'weapon_blaster',
	disruptor = 'weapon_disruptor',
	bowcaster = 'weapon_bowcaster',
	repeater = 'weapon_repeater',
	demp2 = 'weapon_demp2',
	flechette = 'weapon_flechette',
	rocket = 'weapon_rocket_launcher',

	smallarmor = 'item_shield_sm_instant',
	armor = 'item_shield_lrg_instant',
	medpak = 'item_medpak_instant',
	seeker = 'item_seeker',
	shield = 'item_shield',
	bacta = 'item_medpac',
	bigbacta = 'item_medpac_big',
	binoculars = 'item_binoculars',
	sentry = 'item_sentry_gun',
	jetpack = 'item_jetpack',
	healthdisp = 'item_healthdisp',
	ammodisp = 'item_ammodisp',
	eweb = 'item_eweb_holdable',
	cloak = 'item_cloak',
	enlightenlight = 'item_force_enlighten_light',
	enlightendark = 'item_force_enlighten_dark',
	boon = 'item_force_boon',
	ysalimari = 'item_ysalimari',
	thermal = 'ammo_thermal', -- weapon_thermal ?
	tripmine = 'ammo_tripmine', -- weapon_trip_mine ?
	detpack = 'ammo_detpack', -- weapon_det_pack ?
	force = 'ammo_force',
	blasterammo = 'ammo_blaster',
	powercell = 'ammo_powercell',
	bolts = 'ammo_metallic_bolts',
	rockets = 'ammo_rockets',
	allammo = 'ammo_all',
	redcube = 'item_redcube',
	bluecube = 'item_bluecube',

	gun = '',
	ammounit = '',
	shieldunit = '',
	turret = '',
	miniturret = '',
	deathturret = ''
}


-- mplace <foldername/modelname>
-- mplace <modelpath>
-- mplace <special-ob-name> <optional-special-ob-parameters>
local function mPlace(ply, args, plyob)
	local model = args[1]

	-- wrong syntax
	if not model then
		plyob.print('Command usage:   ^5/mplace <foldername/modelname>\n^7Command usage:   ^5/mplace <special-ob-name> <optional-special-ob-parameters>')
		return
	end

	local vars = {}
	if specialObjects[model] then
		vars['classname'] = specialObjects[model]
	else

		-- factory/catw2_b instead of models/map_objects/factory/catw2_b.md3
		if not string.match(model, 'models/map_objects') then
			model = 'models/map_objects/' .. model .. '.md3'
		end

		-- making an entity
		vars['classname'] = 'misc_model'
		vars['model'] = model
	end

	local ent = CreateEntity(vars)
	SetupEntity(ent)

	-- setting position
	if plyob['autograbbing'] then
		plyob['grabbed'][#plyob['grabbed'] + 1] = ent
		plyob.print(string.format('Object grabbed:%d. Use /mgrabbing to turn off auto-grabbing.', ent.id))
	else
		if plyob['mark_position'] then
			-- player has mmark
			ent.position = plyob['mark_position']
		else
			-- player hasn't mmark
			ent.position = ply.position:MA(plyob['arm'], JPMath.AngleVectors(ply.angles, true, false, false))
		end
		plyob.print( string.format("Object placed:%d  Origin: (%d %d %d)", ent.id, math.floor(ent.position.x), math.floor(ent.position.y), math.floor(ent.position.z)) )
	end

	plyob['selected'] = ent
	plyob['objects'][#plyob['objects'] + 1] = ent
end


-- mplacefx <effectname>
-- mplacefx <effectname> <delay>
-- mplacefx <effectname> <delay> <random-component>
local function mPlaceFX(ply, args, plyob)
	local fx = args[1]

	-- wrong syntax
	if not fx then
		plyob.print('Command usage:   ^5/mplacefx <effectname> <delay-between-firings-in-milliseconds> <optional-random-delay-component-in-ms>\n^71 second is 1000 milliseconds')
		return
	end

	-- making an entity
	local vars = {}
	vars['classname'] = 'fx_runner'
	vars['fxFile'] = fx

	-- delay
	if args[2] then
		vars['delay'] = tonumber(args[2])
		if args[3] then
			vars['random'] = tonumber(args[3])
		end
	end

	local ent = CreateEntity(vars)
	SetupEntity(ent)

	-- setting position
	if plyob['autograbbing'] then
		plyob['grabbed'][#plyob['grabbed'] + 1] = ent
		plyob.print(string.format('Effect grabbed:%d. Use /mgrabbing to turn off auto-grabbing.', ent.id))
	else
		if plyob['mark_position'] then
			-- player has mmark
			ent.position = plyob['mark_position']
		else
			-- player hasn't mmark
			ent.position = ply.position:MA(plyob['arm'], JPMath.AngleVectors(ply.angles, true, false, false))
		end
		plyob.print( string.format('Effect placed:%d  Origin: (%d %d %d)', ent.id, math.floor(ent.position.x), math.floor(ent.position.y), math.floor(ent.position.z)) )
	end

	plyob['selected'] = ent
	plyob['objects'][#plyob['objects'] + 1] = ent
end


function mKill(ply, args, plyob)
	local mode = args[1]

	if mode == 'in' then

		local ent = plyob['selected']
		if not ent then return end

		local data = {}
		data.type = 'killin'
		data.ent = ent
		data.start = GetRealTime()
		data.time = tonumber(args[2])
		if args[2] == nil then data.time = 1 end

		makermod.AddTimer(data)

	elseif mode == 'trace' then
		-- mkill trace
		local trace = TraceEntity(ply, nil)
		if trace.entityNum > 0 then
			local ent = GetEntity(trace.entityNum)
			if not ent then return end
			if CheckEntity(ent, ply) then
				for i=0, #GetPlayers() do
						if makermod.players[ply.id]['selected'] == ent then
							makermod.players[ply.id]['selected'] = nil
						end
						if makermod.players[ply.id]['grabbed'] == ent then
							makermod.players[ply.id]['grabbed'] = {}
						end
					end
				RemoveEntity(ent)
				return
			end
		end

	elseif mode == 'all' then
		-- mkill all
		makermod.players[ply.id]['selected'] = nil
		makermod.players[ply.id]['grabbed'] = {}
		for _, ent in pairs(makermod.players[ply.id]['objects']) do
			if ent then
				makermod.StopAllTimers(ent)
				RemoveEntity(ent)
			end
		end
		makermod.players[ply.id]['objects'] = {}

	elseif mode and string.sub(mode, 0, 1) == '#' then
		-- mkill #id
		mode = string.sub(mode, 2)
		local ent = plyob.names[mode]
		if not ent then return end
		for k, v in pairs(makermod.players[ply.id]['objects']) do
			if ent and v == ent then
				makermod.players[ply.id]['objects'][k] = nil
			end
		end

		for k, v in pairs(makermod.players[ply.id]['grabbed']) do
			if v == ent then
				makermod.players[ply.id]['grabbed'][k] = nil
			end
		end

		makermod.players[ply.id]['selected'] = nil
		makermod.StopAllTimers(ent)
		RemoveEntity(ent)

		-- todo: remove ob from names

	else
		local ent = plyob['selected']
		if not ent then return end

		for k, v in pairs(makermod.players[ply.id]['objects']) do
			if ent and v == ent then
				makermod.players[ply.id]['objects'][k] = nil
			end
		end

		for k, v in pairs(makermod.players[ply.id]['grabbed']) do
			if v == ent then
				makermod.players[ply.id]['grabbed'][k] = nil
			end
		end

		makermod.players[ply.id]['selected'] = nil
		makermod.StopAllTimers(ent)
		RemoveEntity(ent)
	end
end

-- kill in listener
makermod.timerListeners['killin'] = function(object)
	if object.start + object.time < GetRealTime() then
		RemoveEntity(object.ent)
		return false
	end
end

local function mMoveTime(ply, args, plyob)
	if #args < 1 then
		plyob.print(string.format("Your mmove time: %d ms (%d s)", makermod.players[ply.id]['movetime'], makermod.players[ply.id]['movetime'] / 1000))
		return
	end
	local time = tonumber(args[1])
	if time then
		plyob['movetime'] = time
	else
		plyob.print("Wrong number!")
	end
end

local function mMove(ply, args, plyob, ent)
	-- wrong syntax
	if #args < 1 then
		plyob.print("Command usage:   ^5/mmove <speed>\n^7Command usage:   ^5/mmove <x> <y> <z>\n^7Command usage:   ^5/mmove <x> <y> <z> <duration> <easing>\n^7Type /mmove list for easing list.")
		return
	end

	-- easing functions list
	if args[1] == 'list' then
		-- todo: minfo easing
		plyob.print(easinglist)
		return
	end


	-- removing any timers
	makermod.StopTimersExceptRotate(ent)

	-- removing a grabbing
	for k, v in pairs(plyob['grabbed']) do
		if v == ent then
			plyob['grabbed'][k] = nil
		end
	end

	-- parsing the args:

	-- mmove speed
	-- mmove speed dur
	-- mmove speed dur easing
	-- mmove speed easing
	-- mmove x y z
	-- mmove x y z dur
	-- mmove x y z dur easing
	-- mmove x y z easing
	local dest = Vector3(0, 0, 0)
	local dur = plyob['movetime']
	local ease = 'linear'

	if #args == 1 or #args == 2 or (#args == 3 and makermod.easing[args[3]]) then
		-- move in eye direction
		local ma = JPMath.AngleVectors(ply.angles, true, false, false)
		dest = ply.position:MA(tonumber(args[1]), ma)
		dest = dest - ply.position

		if #args > 1 then
			if #args == 2 then
				if makermod.easing[args[2]] then
					-- mmove <speed> <easing>
					ease = args[2]
				else
					-- mmove <speed> <duration>
					dur = args[2]
				end
			else
				-- mmove <speed> <duration>
				dur = args[2]
				ease = args[3]
			end
		end
	else
		-- move by (x y z)
		dest = ParseVector(Vector3(0, 0, 0), args, 0) * 10

	--	dest.x = tonumber(args[1]) * 10
	--	dest.y = tonumber(args[2]) * 10
	--	dest.z = tonumber(args[3]) * 10

		if #args > 3 then
			if #args == 4 then
				if makermod.easing[args[4]] then
					-- mmove <x> <y> <z> <easing>
					ease = args[4]
				else
					-- mmove <x> <y> <z> <duration>
					dur = args[4]
				end
			else
				-- mmove <x> <y> <z> <duration> <easing>
				dur = args[4]
				ease = args[5]
			end
		end
	end

	if dest == Vector3(0, 0, 0) then return end

	dur = tonumber(dur)

	-- moving
	if dur == 0 then
		ent.position = ent.position + dest
	else
		-- animation
		local data = {}
		data.type = 'move'
		data.ent = ent
		data.start = GetRealTime()
		data.coords = dest
		data.pos = ent.position
		data.ease = ease
		data.dur = dur
		makermod.AddTimer(data)
	end
end

local function mRotate(ply, args, plyob, ent)
	-- wrong syntax
	if #args < 1 then
		plyob.print("Command usage:   ^5/mrotate <x> <y> <z>\n^7Command usage:   ^5/mrotate <x> <y> <z> <duration> <easing>\n^7Type /mmove list for easing list.")
		return
	end

	-- stopping the current rotating
	for k, v in pairs(makermod.timers) do
		if v.ent == ent and v.type == 'rotate' then
			ent.angles = v.from
			makermod.timers[k] = nil
			break
		end
	end

	if args[1] == "clear" then
		ent.angles = Vector3(0, 0, 0)
		return
	end

	-- parsing the args:

	-- mrotate x y z
	-- mrotate x y z dur
	-- mrotate x y z dur easing
	-- mrotate x y z easing
	local angle = Vector3(tonumber(args[1]), tonumber(args[2]), tonumber(args[3]))
	local dur = plyob['movetime']
	local ease = 'linear'

	if #args > 3 then
		if #args == 4 then
			if makermod.easing[args[4]] then
				-- mrotate <x> <y> <z> <easing>
				ease = args[4]
			else
				-- mrotate <x> <y> <z> <duration>
				dur = args[4]
			end
		else
			-- mrotate <x> <y> <z> <duration> <easing>
			dur = args[4]
			ease = args[5]
		end
	end

	if angle == Vector3(0, 0, 0) then return end

	dur = tonumber(dur)

	-- moving
	if dur == 0 then
		ent.angles = ent.angles + angle
	else
		-- animation
		local data = {}
		data.type = 'rotate'
		data.ent = ent
		data.start = GetRealTime()
		data.angle = angle
		data.from = ent.angles
		data.ease = ease
		data.dur = dur
		makermod.AddTimer(data)
	end
end

function mConnectTo(ply, args)
	if not makermod.players[ply.id]['selected'] then return end
	
	local trace = TraceEntity(ply, nil)
	if trace.entityNum >= 0 then
		local ent = GetEntity(trace.entityNum)
		if not CheckEntity(ent, ply) then return end
		local data1 = makermod.objects[makermod.players[ply.id]['selected'].id]
		local data2 = makermod.objects[ent.id]
			data1['connectedTo'][#data1['connectedTo']+1] = ent
			data2['connectedFrom'][#data2['connectedFrom']+1] = makermod.players[ply.id]['selected']
	else
		SendReliableCommand(ply.id, string.format('print "0 entity traced\n"'))
		return 
	end
	
end

function mTouchable(ply, args)
 if not makermod.players[ply.id]['selected'] then return end
 		makermod.players[ply.id]['selected'].touchable = true
end

function mUsable(ply, args)
	if not makermod.players[ply.id]['selected'] then return end
	makermod.players[ply.id]['selected'].usable = true
end

local function mPrintsw(ply, args)
	if not makermod.players[ply.id]['selected'] then return end
	local text = args[1]
	local ent = makermod.players[ply.id]['selected']
	if ent.touchable or ent.usable then
		local printfunc = function(a,b,c)
							if b ~= nil and b.player ~= nil then
								SendReliableCommand(b.player.id, string.format('cp "%s" ', text))
							end
						  end
		if ent.touchable then
			makermod.objects[ent.id]['touchfuncs'][#makermod.objects[ent.id]['touchfuncs'] + 1] = printfunc
		end
		if ent.usable then
			makermod.objects[ent.id]['usefuncs'][#makermod.objects[ent.id]['usefuncs'] + 1] = printfunc
		end
	end
end

local function mTelesw(ply, args)
	if not makermod.players[ply.id]['selected'] then return end
	local data = makermod.objects[makermod.players[ply.id]['selected'].id]
	local ent = makermod.players[ply.id]['selected']
	local func = function(a,b,c)
		if not b then return end
		if b.player then
			if not data['tele_destination'] then
				data['tele_destination'] = Vector3(tonumber(args[1]), tonumber(args[2]), tonumber(args[3]))
			end
			b.player:Teleport(data['tele_destination'], b.player.angles)
		else
			b.position = data['tele_destination'] --TODO: Entity Teleporting?
		end
	end
	if ent.touchable then
		makermod.objects[ent.id]['touchfuncs'][#makermod.objects[ent.id]['touchfuncs'] + 1] = func
	end
	if ent.usable then
		makermod.objects[ent.id]['usefuncs'][#makermod.objects[ent.id]['usefuncs'] + 1] = func
	end
end

function mDest(ply, args)
	 if not makermod.players[ply.id]['selected'] then return end
	 if #args >= 1 then
		if args[1] == 'trace' then
			local trace = TraceEntity(ply, nil)
			makermod.objects[makermod.players[ply.id]['selected'].id]['tele_destination'] = Vector3(trace.endpos.x, trace.endpos.y, trace.endpos.z)
		else
		 	--makermod.objects[makermod.players[ply.id]['selected'].id]['tele_destination'] = ParseVector(ply.position, args, 0)
		 	makermod.objects[makermod.players[ply.id]['selected'].id]['tele_destination'] = Vector3(tonumber(args[1]), tonumber(args[2]), tonumber(args[3]))
		end
	else
		makermod.objects[makermod.players[ply.id]['selected'].id]['tele_destination'] = ParseVector(ply.position, args)
	end
end

local function mArm(ply, args, plyob)
	if #args < 1 then
		plyob.print("Marm: " .. plyob['arm'])
		return
	end
	plyob['arm'] = tonumber(args[1]) --ParseNumber(args, 1, 0,{makermod.players[ply.id]['arm']})[1]
end

local function mGrabbing(ply, args, plyob)
	local state
	if args[1] then
		if args[1] == 'off' then
			state = true
		else
			state = false
		end
	else
		state = plyob['autograbbing']
	end

	if state then
		plyob['autograbbing'] = false
		plyob.print("Automatic Grabbing OFF.")
	else
		plyob['autograbbing'] = true
		plyob.print("Automatic Grabbing ON.")
	end
end


function mSelect(ply, args, plyob)
	if #args == 1 then
		if not plyob.names[args[1]] then
			plyob.print("There is no object.")
			return
		end
		plyob['selected'] = plyob.names[args[1]]
		plyob.print("Entity selected: " .. plyob['selected'].id)
	else
		local trace = TraceEntity(ply, nil)
		if trace.entityNum >= 0 then
			local ent = GetEntity(trace.entityNum)
			if not ent then return end
			if not CheckEntity(ent, ply) then
			 	return
			end
			plyob['selected'] = ent
			plyob.print("Entity selected: " .. ent.id)
		end
	end
end

function mDrop(ply, args)
	if args[1] == 'all' then
		makermod.players[ply.id]['grabbed'] = {}
		return
	end
	for k, v in pairs(makermod.players[ply.id]['grabbed']) do
		if v == makermod.players[ply.id]['selected'] then
			makermod.players[ply.id]['grabbed'][k] = nil
		end
	end
end

function mGrab(ply, args)
	if not makermod.players[ply.id]['selected'] then return end
	makermod.players[ply.id]['grabbed'][#makermod.players[ply.id]['grabbed'] + 1] = makermod.players[ply.id]['selected']
end

local function mSetPassword(ply, args)
	if #args < 1 then return end
	local value = args[1]
	if value == 'trace' then
		local pass = args[2]
		if not pass then return end
		local trace = TraceEntity(ply, nil)
		if trace.entityNum >= 0 then
			local ent = GetEntity(trace.entityNum)
			if not ent then return end
			if not CheckEntity(ent, ply) then return end
			makermod.objects[ent.id]['password'] = tostring(pass)
		end
	else
		if not makermod.players[ply.id]['selected'] then return end
		local ent = makermod.players[ply.id]['selected']
		makermod.objects[ent.id]['password'] = tostring(value)
	end
end

local function mPassword(ply, args)
	if #args < 1 then return end
	makermod.players[ply.id]['password'] = tostring(args[1])
end

local function mDoor(ply, args)

end

local function mName(ply, args, plyob, ent)
	plyob.objects[args[1]] = ent
end

local function mAnim(ply, args)
	if #args < 1 then return end
	ply:SetAnim(args[1], 1, 1)
end

function mMark(ply, args, plyob)
	local vec = ply.position
	local i, type, res
	if #args > 1 then
		vec = ParseVector(Vector3(0,0,0), args, 0)
	elseif args[1] and string.sub(args[1], 0, 1) == '#' then
		-- mmark #id
		local ent = plyob.names[string.sub(args[1], 2)]
		if not ent then return end
		vec = ent.position
	end
	if not makermod.players[ply.id]['mark_position'] then
		makermod.players[ply.id]['autograbbing'] = false
		SendReliableCommand(ply.id, string.format('print "Automatic Grabbing OFF. Use /mgrabbing to turn it back on.\n"'))
	end
	makermod.players[ply.id]['mark_position'] = vec
	SendReliableCommand(ply.id, string.format('print "Marked: (%d %d %d)\n"', math.floor(vec.x), math.floor(vec.y), math.floor(vec.z)))
end

function mMarkSave(ply, args)
	if #args < 1 then
		SendReliableCommand(ply.id, 'print "Command usage:   ^5/mmarksave <name>\n"')
		return
	end

	local mark = makermod.players[ply.id]['mark_position']
	makermod.players[ply.id]['marks'][args[1]] = mark
	SendReliableCommand(ply.id, string.format('print "Mark (%s) saved: (%d %d %d)\n"', args[1], math.floor(mark.x), math.floor(mark.y), math.floor(mark.z)))
end

function mMarkSelect(ply, args)
	if #args < 1 then
		SendReliableCommand(ply.id, 'print "Command usage:   ^5/mmarkselect <name>\n"')
		return
	end

	local mark = makermod.players[ply.id]['marks'][args[1]]
	if not mark then
		SendReliableCommand(ply.id, string.format('print "Mark \"%s\" not found.\n"', args[1]))
		return
	end

	makermod.players[ply.id]['mark_position'] = mark
	SendReliableCommand(ply.id, string.format('print "Mark (%s) selected: (%d %d %d)\n"', args[1], math.floor(mark.x), math.floor(mark.y), math.floor(mark.z)))
end

local function mOrigin(ply)
	local vec = ply.position
	-- todo: make numbers round instead of floor
	SendReliableCommand(ply.id, string.format('print "Origin: (%d %d %d)\n"', math.floor(vec.x), math.floor(vec.y), math.floor(vec.z)))
end

-- l_arm, *l_arm
-- r_arm, *r_arm
-- torso_collar


local function mAttachFx(ply, args, plyob, ent)
	if #args < 1 then
		plyob.print("Command usage:   ^5/mattachfx <bolt id>, attach to existing bone.\nCommand usage:   ^5/mattachfx <bone name>, attach to bone, creating new bolt if needed")
		return
	end
	if ent.classname ~= 'fx_runner' then
		plyob.print('This object is not an effect.')
		return
	end
	makermod.StopTimersExceptRotate(ent)
	local data = {}
	data['type'] = 'attach'
	data['bone'] = args[1]
	data['ply'] = ply.entity
	data['ent'] = ent
	data['align'] = ParseVector(Vector3(0,0,0), args, 1)
	makermod.AddTimer(data)
end

local function mAttachOb(ply, args, plyob, ent)
	if #args < 1 then
		plyob.print("Command usage:   ^5/mattachob <bolt id>, attach to existing bone.\nCommand usage:   ^5/mattachob <bone name>, attach to bone, creating new bolt if needed")
		return
	end
	if ent.classname ~= 'misc_model' then
		plyob.print('This object is not an model object.')
		return
	end

	ent.contents = 2
	makermod.StopTimersExceptRotate(ent)
	local data = {}
	data['type'] = 'attach'
	data['bone'] = args[1]
	data['ply'] = ply.entity
	data['ent'] = ent
	data['align'] = ParseVector(Vector3(0,0,0), args, 1)
	makermod.AddTimer(data)
end


makermod.timerListeners['attach'] = function(object)
	local bone = object['ply']:GetBoneVector(object['bone'])
	if bone then
		object['ent'].position = object['align'] + bone
	end
end

local function mScale(ply, args)
	if #args < 1 then return end
	if args[1] == 'trace' then
		local trace = TraceEntity(ply, nil)
		if trace.entityNum >= 0 then
			local ent = GetEntity(trace.entityNum)
			if not ent then return end
			if not CheckEntity(ent, ply) then return end
			ent:Scale(tonumber(args[2]) * 100)
		end
	else
		if not makermod.players[ply.id]['selected'] then return end
		makermod.players[ply.id]['selected']:Scale(tonumber(args[1]) * 100)
	end
end

local function mScaleMe(ply, args)
	if #args < 1 then return end
	local ent = ply.entity
	local num = tonumber(args[1]) * 100
	if num == 10.24 then end
	if num < 1 then
		num = 1
	end
	ent:Scale(num)
end

local function mBreakable(ply, args, plyob, ent)
	if #args < 1 then return end
	plyob['selected'].breakable = true
	plyob['selected'].health = tonumber(args[1])
	plyob['selected']:SetDieFunction( function(a,b,c, d,e) 
		if makermod.objects[ent.id]['ondie'] then
			makermod.Run(makermod.objects[ent.id]['ondie'], ply)
		end
		RemoveEntity(a)
	end )
end

local function mOnDie(ply, args, plyob, ent)
	if #args < 1 then
		plyob.print("Command usage:   ^5/mondie <commands>\n^7Example:   ^3/mondie \"mplacefx env/fire; wait 1000; mkill\"")
		return
	end
	makermod.objects[ent.id]['ondie'] = args[1]
end

local function mPain(ply, args)
	if #args < 1 then return end

	local ent = makermod.players[ply.id]['selected']
	if not ent then return end
	if ent.classname ~= 'fx_runner' then return end

	local maxDmg = makermod.cvars['pain_maxdmg']:GetInteger()
	local maxDst = makermod.cvars['pain_maxdist']:GetInteger()

	local damage = tonumber(args[1])
	local radius = tonumber(args[2])

	if damage > maxDmg then
		damage = maxDmg
	end

	ent:SetVar('splashDamage', damage)

	if radius then
		if radius > maxDst then
			radius = maxDst
		end
		ent:SetVar('splashRadius', radius)
	end

	ent.spawnflags = 4
end



local function mList(ply, args)
	local list
	if #args < 1 then
		list = GetFileList('models/map_objects/', '/')
	else
		list = GetFileList('models/map_objects/' .. args[1], '.md3')
	end

	local function isHas(object, value)
		for _, v in pairs(object) do
			if v == value then
				return true
			end
		end
		return false
	end

	local models = {}
	for k, v in pairs(list) do
		if not isHas(models, v) then
			models[#models + 1] = v
			SendReliableCommand(ply.id, 'print "' .. string.gsub(v, '.md3', '') .. '\n"')
		end
	end
end

local function mListFx(ply, args)
	local list
	if #args < 1 then
		list = GetFileList('effects', '/')
	else
		list = GetFileList('effects/' .. args[1], 'efx')
	end

	local function isHas(object, value)
		for _, v in pairs(object) do
			if v == value then
				return true
			end
		end
		return false
	end

	local models = {}
	for k, v in pairs(list) do
		if not isHas(models, v) then
			models[#models + 1] = v
			SendReliableCommand(ply.id, 'print "' .. string.gsub(v, '.efx', '') .. '\n"')
		end
	end
end

local function mTelesp(ply, args)
	local list = FindEntityByClassname('info_player_deathmatch')
	local len = #list
	local spot = list[math.random(len)]
	ply:Teleport(spot.position)
end

local function mEllipse(ply, args)
	-- mellipse <rx> <ry> <from> <to>
	-- mellipse <rx> <ry> <from> <to> <dur>
	-- mellipse <rx> <ry> <from> <to> <dur> <easing>
	-- mellipse <rx> <ry> <period-in-ms>

	if #args < 1 then
		SendReliableCommand(ply.id, string.format('print "Command usage:   ^5/mellipse <radius> <from> <to> <dur> <easing>\n^7Command usage:   ^5/mellipse <rx> <ry> <from> <to> <dur> <easing>\n^7Command usage:   ^5/mellipse <rx> <ry> <period-in-milliseconds>\n"'))
		return
	end

	local ent = makermod.players[ply.id]['selected']
	if not ent then return end

	local data = {}

	data.rx = tonumber(args[1])
	data.ry = tonumber(args[2])
	data.ent = ent
	data.start = GetRealTime()
	data.center = ent.position

	if #args == 3 or #args == 2 then
		data.movingType = 'ellipse_inf'
		data.period = tonumber(args[3]) or 1000
	else
		data.movingType = 'ellipse'
		data.from = tonumber(args[3])
		data.to = tonumber(args[4])
		data.dur = tonumber(args[5]) or 1000--makermod.players[ply.id]['movetime']
		data.ease = args[6] or 'linear'
	end

	makermod.objects.moving[#makermod.objects.moving + 1] = data
end

local function mAstroid(ply, args)

	if #args < 1 then
		SendReliableCommand(ply.id, string.format('print "Command usage:   ^5/mastroid <radius> <from> <to> <dur> <easing>\n^7Command usage:   ^5/mastroid <rx> <ry> <from> <to> <dur> <easing>\n^7Command usage:   ^5/mastroid <rx> <ry> <period-in-milliseconds>\n"'))
		return
	end

	local ent = makermod.players[ply.id]['selected']
	if not ent then return end

	local data = {}

	data.rx = tonumber(args[1])
	data.ry = tonumber(args[2])
	data.ent = ent
	data.start = GetRealTime()
	data.center = ent.position

	if #args == 3 then
		data.movingType = 'astroid_inf'
		data.period = tonumber(args[3]) or 1000
	else
		data.movingType = 'astroid'
		data.from = tonumber(args[3])
		data.to = tonumber(args[4])
		data.dur = tonumber(args[5]) or makermod.players[ply.id]['movetime']
		data.ease = args[6] or 'linear'
	end

	makermod.objects.moving[#makermod.objects.moving + 1] = data
end

local function mSpiral(ply, args)
	-- mspiral k from to dur easing

	if #args < 1 then
		SendReliableCommand(ply.id, string.format('print "Command usage:   ^5/mspiral <k> <from> <to> <dur> <easing>\n"'))
		return
	end

	local ent = makermod.players[ply.id]['selected']
	if not ent then return end

	local data = {}
	data.movingType = 'spiral'
	data.k = tonumber(args[1])
	data.from = tonumber(args[2])
	data.to = tonumber(args[3])
	data.ent = ent
	data.start = GetRealTime()
	data.center = ent.position
	data.dur = makermod.players[ply.id]['movetime']
	data.ease = 'linear'

	if #args == 4 then
		if makermod.easing[args[4]] then
			data.ease = args[4]
		else
			data.dur = tonumber(args[4])
		end
	elseif #args == 5 then
		data.dur = tonumber(args[4])
		data.ease = args[5]
	end

	makermod.objects.moving[#makermod.objects.moving + 1] = data
end

local function mListObs(ply, args)
	local page = tonumber(args[1]) or 1--(tonumber(args[1]) - 1) or 0
	local obsOnPage = 10
	local obs = makermod.players[ply.id]['objects']
	local numPages = math.floor(#obs / obsOnPage + 0.9)
	if #obs == 0 then
		SendReliableCommand(ply.id, 'print "You have 0 objects.\n"')
		return
	end
	if page < 0 then
		SendReliableCommand(ply.id, 'print "Wrong page!\n"')
		return
	end
	if page > numPages then
		if numPages == 1 then
			SendReliableCommand(ply.id, 'print "There is 1 page.\n"')
		else
			SendReliableCommand(ply.id, string.format('print "There are %s pages.\n"', numPages))
		end
		return
	end

	local endOb = page * obsOnPage
	local str = string.format("Your objects (page %d of %d)\n", page, numPages)
	for i=(endOb-9),endOb do
		if obs[i] then
			if obs[i].classname == 'fx_runner' then
				str = str .. string.format("%d   %s    (%d %d %d)\n", obs[i].id, makermod.objects[obs[i].id]['fxFile'], math.floor(obs[i].position.x), math.floor(obs[i].position.y), math.floor(obs[i].position.z))
			else
				local model = obs[i].model
				model = string.gsub(model, 'models/map_objects/', '')
				model = string.gsub(model, '.md3', '')
				str = str .. string.format("%d   %s    (%d %d %d)\n", obs[i].id, model, math.floor(obs[i].position.x), math.floor(obs[i].position.y), math.floor(obs[i].position.z))
			end
		end
	end
	SendReliableCommand(ply.id, string.format('print "%s"', str))
end

local function mLight(ply, args, plyob, ent)
	if #args < 1 then
		plyob.print("Command usage:   ^5/mlight <intensity> <r> <g> <b>")
		return
	end
	local light = {}
	light['a'] = args[1]
	if #args > 1 then
		light['r'] = args[2]
		light['g'] = args[3]
		light['b'] = args[4]
	else
		light['r'] = 0.255
		light['g'] = 0.255
		light['b'] = 0.255
	end

	ent.light = light
	makermod.objects[ent.id].lightA = tonumber(args[1])
end

local function mLightTo(ply, args, plyob, ent)
	if #args < 1 then
		plyob.print("Command usage:   ^5/mlightto <intensity> <r> <g> <b>")
		return
	end

	if not makermod.objects[ent.id].lightA then
		makermod.objects[ent.id].lightA = 0
	end

	for k, v in pairs(makermod.timers) do
		if v.ent == ent and v.type == 'light' then
			makermod.timers[k] = nil
			break
		end
	end

	-- parsing the args:

	local data = {}
	local dur = plyob['movetime']
	local ease = 'linear'

	-- mlightto <i>
	-- mlightto <i> <dur>
	-- mlightto <i> <easing>
	-- mlightto <i> <dur> <easing>
	-- mlightto <i> <r> <g> <b>
	-- mlightto <i> <r> <g> <b> <dur>
	-- mlightto <i> <r> <g> <b> <easing>
	-- mlightto <i> <r> <g> <b> <dur> <easing>

	data['a'] = tonumber(args[1])

	-- only intensity
	if #args == 2 then
		if makermod.easing[args[2]] then
			-- mlightto <i> <easing>
			ease = args[2]
		else
			-- mlightto <i> <dur>
			dur = args[2]
		end
	elseif #args == 3 then
		-- mlightto <i> <dur> <easing>
		dur = args[2]
		ease = args[3]
	else
		-- r, g, b
		data['r'] = tonumber(args[2])
		data['g'] = tonumber(args[3])
		data['b'] = tonumber(args[4])

		if #args == 5 then
			if makermod.easing[args[5]] then
				-- mlight <i> <r> <g> <b> <easing>
				ease = args[5]
			else
				-- mlight <i> <r> <g> <b> <dur>
				dur = args[5]
			end
		elseif #args == 6 then
			-- mlight <i> <r> <g> <b> <dur> <easing>
			dur = args[5]
			ease = args[6]
		end
	end

	if not data['r'] then
		data['r'] = ent.light['r']
		data['g'] = ent.light['g']
		data['b'] = ent.light['b']
	end


	dur = tonumber(dur)

	-- animating
	if dur == 0 then
		ent.light = data
		makermod.objects[ent.id].lightA = data['a']
	else
		-- animation
		data.type = 'light'
		data.ent = ent
		data.start = GetRealTime()
		data.from = {
			a = makermod.objects[ent.id].lightA,
			r = ent.light['r'],
			g = ent.light['g'],
			b = ent.light['b']
		}

		data.ease = ease
		data.dur = dur

		data['r'] = data['r'] - ent.light['r']
		data['g'] = data['g'] - ent.light['g']
		data['b'] = data['b'] - ent.light['b']
		data['a'] = data['a'] - makermod.objects[ent.id].lightA

		makermod.AddTimer(data)
	end
end

makermod.timerListeners['light'] = function(object)
	local now = GetRealTime()
	local delta = now - object.start

	local t = delta / object.dur
	if t > 1 then
		t = 1
	end

	if object.ease ~= 'linear' and easing[object.ease] then
		t = easing[object.ease](t)
	end
	local newlight = {}

	newlight['r'] = object.from['r'] + object['r'] * t
	newlight['g'] = object.from['g'] + object['g'] * t
	newlight['b'] = object.from['b'] + object['b'] * t
	newlight['a'] = object.from['a'] + object['a'] * t

	print(string.format('r: %f; g: %f; b: %f; a: %f', newlight['r'], newlight['g'], newlight['b'], newlight['a']))
	makermod.objects[object.ent.id].lightA = newlight['a']
	object.ent.light = newlight

	if delta > object.dur then
		return false
	end
end

-- Groups --
------------

makermod.AddCommand('mleadgroupcreate', function(ply, args, plyob)

	plyob.groups[args[1]] = {}
	if #args > 1 then
		for k, v in args do
			print(v);
		end
	end

end)

makermod.AddCommand('mleadgroupadd', function(ply, args, plyob)

	--

end)
makermod.AddCommand('mleadgroupremove', function(ply, args, plyob)

	--

end)
makermod.AddCommand('mgroupcreate', function(ply, args, plyob)

	--

end)
makermod.AddCommand('mgroupadd', function(ply, args, plyob)

	--

end)
makermod.AddCommand('mgroupremove', function(ply, args, plyob)

	--

end)
makermod.AddCommand('mgselect', function(ply, args, plyob)

	--

end)
makermod.AddCommand('mgmove', function(ply, args, plyob)

	--

end)
makermod.AddCommand('mgrotate', function(ply, args, plyob)

	--

end)

-- Groups end --
----------------


makermod.AddCommand('mplace', mPlace) -- toolgun
makermod.AddCommand('mplacefx', mPlaceFX) -- toolgun 
makermod.AddCommand('mkill', mKill) -- toolgun
makermod.AddCommand('mmovetime', mMoveTime)
makermod.AddCommand('mmove', mMove, true)
makermod.AddCommand('mrotate', mRotate, true)
makermod.AddCommand('mconnectto', mConnectTo) -- toolgun
makermod.AddCommand('mtouchable', mTouchable) -- toolgun
makermod.AddCommand('musable', mUsable) -- toolgun
makermod.AddCommand('mprintsw', mPrintsw)
makermod.AddCommand('mdest', mDest) -- toolgun
makermod.AddCommand('marm', mArm)
makermod.AddCommand('mgrabbing', mGrabbing)
makermod.AddCommand('mselect', mSelect) -- toolgun
makermod.AddCommand('mdrop', mDrop) -- toolgun
makermod.AddCommand('mgrab', mGrab) -- toolgun
makermod.AddCommand('msetpassword', mSetPassword)
makermod.AddCommand('mpassword', mPassword)
makermod.AddCommand('mname', mName, true)
makermod.AddCommand('mmark', mMark) -- toolgun
makermod.AddCommand('mmarksave', mMarkSave)
makermod.AddCommand('mmarkselect', mMarkSelect)
makermod.AddCommand('morigin', mOrigin)
makermod.AddCommand('manim', mAnim)
makermod.AddCommand('mattachfx', mAttachFx, true)
makermod.AddCommand('mattachob', mAttachOb, true)
makermod.AddCommand('mscale', mScale)
makermod.AddCommand('mscaleme', mScaleMe)
makermod.AddCommand('mbreakable', mBreakable, true)
makermod.AddCommand('mondie', mOnDie, true)
makermod.AddCommand('mpain', mPain)
makermod.AddCommand('mlist', mList)
makermod.AddCommand('mlistfx', mListFx)
makermod.AddCommand('mtelesp', mTelesp)
makermod.AddCommand('mlistobs', mListObs)
makermod.AddCommand('mlight', mLight, true)
makermod.AddCommand('mlightto', mLightTo, true)
makermod.AddCommand('mtelesw', mTelesw)

makermod.AddCommand('mellipse', mEllipse)
makermod.AddCommand('mastroid', mAstroid)
makermod.AddCommand('mspiral', mSpiral)

makermod.toolgun.init()

makermod.AddCommand('minfo', function(ply)
	SendReliableCommand(ply.id, 'print "^5 === New Features ===\n^1/mmovetime^7 -- default moving time.\n^1/mmove <x> <y> <z> <duration> <easing>^7\n^1/mmove list^7 -- easing list (use with Out and InOut: ^3bounce^7 -> ^3bounce^7, ^3bounceOut^7, ^3bounceInOut^7).\n^1/mrotate <x> <y> <z> <duration> <easing>^7\n^1/mgrabbing on / off^7\n^1/mdrop all^7 -- drops all grabbed objects.\n^1/mmarksave <name>^7, ^1/mmarkselect <name>^7 -- saves / selects current mark.\n^1/mellipse^7, ^1/mastroid^7, ^1/mspiral^7.\n^1Toolgun^7 (use the stun baton).\n\n\n^5 === Notes ===\n^7Use ^1/mkill all ^7instead of ^1/mkillall^7.\n^7Use anim number with manim (example: ^2/manim 150^7).\n^7Use bone names (r_hand, *r_hand, l_hand, *l_hand, head) with mattachfx.\n"')
end)
