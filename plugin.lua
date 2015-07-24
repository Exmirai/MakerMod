local plugin = RegisterPlugin("MakerMod", "2.0")

makermod = {}
makermod.objects = {}
makermod.objects.moving = {} -- for mmove
makermod.objects.attached = {} -- for mattachfx
makermod.players = {}
makermod.cvars = {}

makermod.cvars['pain_maxdist'] = CreateCvar('makermod_pain_maxdistance', '200', CvarFlags.ARCHIVE)
makermod.cvars['pain_maxdmg'] = CreateCvar('makermod_pain_maxdamage', '100000000', CvarFlags.ARCHIVE)

require 'Makermod/animation.lua'

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

	for k, v in pairs(makermod.objects.moving) do
		if AnimStep(v) == false then
			makermod.objects.moving[k] = nil
		end
	end

	for k, v in pairs(makermod.objects.attached) do
		local bone = v['ply']:GetBoneVector(v['bone'])
		if bone then
			local vec = Vector3(bone.x + v['x'], bone.y + v['y'], bone.z + v['z'])
			v['ent'].position = vec
		end
	end
end

AddListener('JPLUA_EVENT_RUNFRAME', MainLoop)

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
		print('a')
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


local function TraceEntity(ply, dist)
	if not ply then return end
	if not dist then dist = 16384 end
	local pos = ply.position
	pos.z = pos.z + 36.0
	local angles = JPMath.AngleVectors(ply.angles,true, false, false)
	local endPos = pos:MA(dist, angles)
	local mask = Contents.CONTENTS_SOLID | Contents.CONTENTS_SLIME | Contents.CONTENTS_LAVA | Contents.CONTENTS_TERRAIN | Contents.CONTENTS_BODY | Contents.CONTENTS_ITEM | Contents.CONTENTS_CORPSE
	local trace = RayTrace(pos, 0, endPos, ply.id,mask)
	return trace
end

local function CheckEntity(ent, ply)
		if not makermod.objects[ent.id] then
			SetupEntity(ent, 'map_object')
			SendReliableCommand(ply.id, string.format('print "You cannot select map object!\n"'))
			return false
		else
			local data = makermod.objects[ent.id]
			if data['owner'] ~= ply then
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

local function OnUserSpawn(ply, firsttime)
	if makermod.players[ply.id] then return end
	makermod.players[ply.id] = {}
	makermod.players[ply.id]['selected'] = nil
	makermod.players[ply.id]['grabbed'] = {}
	makermod.players[ply.id]['arm'] = 200
	makermod.players[ply.id]['movetime'] = 10000
	makermod.players[ply.id]['autograbbing'] = true
	makermod.players[ply.id]['objects'] = {}
	makermod.players[ply.id]['password'] = ''
	makermod.players[ply.id]['mark_position'] = nil
end
AddListener('JPLUA_EVENT_CLIENTSPAWN',OnUserSpawn)

local function onUserDisconnect(ply)
	for _, ent in pairs(makermod.players[ply.id]['objects']) do
		makermod.objects[ent.id] = nil
		ent:Free()
	end
	makermod.players[ply.id] = nil
end
AddListener('JPLUA_EVENT_CLIENTDISCONNECT',onUserDisconnect)

local function mSpawn(ply, args)
	if #args < 1 then
		SendReliableCommand(ply.id, string.format('print "Command usage:   ^5/mplace <foldername/modelname>\n^7Command usage:   ^5/mplace <special-ob-name> <optional-special-ob-parameters>\n"'))
		return
	end

	local model = args[1]
	local vars = {}
	local plypos = ply.position
	local plyang = ply.angles
	
	local entpos = JPMath.AngleVectors(plyang, true,false,false)
	entpos = plypos:MA(makermod.players[ply.id]['arm'], entpos)
	
		vars['classname'] = 'misc_model'
		vars['model'] = 'models/map_objects/' .. model .. '.md3'
	local ent = CreateEntity(vars)
	ent.position = entpos
	
	SetupEntity(ent, ply)
	
	makermod.players[ply.id]['objects'][#makermod.players[ply.id]['objects']+1] = ent
	makermod.players[ply.id]['selected'] = ent
	if makermod.players[ply.id]['autograbbing'] then
		SendReliableCommand(ply.id, string.format('print "Object grabbed:%d. Use /mgrabbing to turn off auto-grabbing.\n"', ent.id))
		makermod.players[ply.id]['grabbed'][#makermod.players[ply.id]['grabbed'] + 1] = ent
	else
		ent.position = makermod.players[ply.id]['mark_position'];
		SendReliableCommand(ply.id, string.format('print "Object placed:%d  Origin: (%d %d %d)\n"', ent.id, math.floor(ent.position.x), math.floor(ent.position.y), math.floor(ent.position.z)))
	end
end

local function mSpawnFX(ply, args)
	if #args < 1 then
		SendReliableCommand(ply.id, string.format('print "Command usage:   ^5/mplacefx <effectname> <delay-between-firings-in-milliseconds> <optional-random-delay-component-in-ms>\n^71 second is 1000 milliseconds\n"'))
		return
	end

	local fx = args[1]
	local vars = {}
	local plypos = ply.position
	local plyang = ply.angles

	local entpos = JPMath.AngleVectors(plyang, true, false, false)
	entpos = plypos:MA(makermod.players[ply.id]['arm'], entpos)
	
		vars['classname'] = 'fx_runner'
		vars['fxFile'] = fx

		if args[2] then
			-- default = 200
			-- change to makermod-compatible
			vars['delay'] = tonumber(args[2])
			if args[3] then
				vars['random'] = tonumber(args[3])
			end
		end

	local ent = CreateEntity(vars)
	ent.position = entpos
	SetupEntity(ent, ply)
	makermod.objects[ent.id]['isfx'] = true
	
	makermod.players[ply.id]['objects'][#makermod.players[ply.id]['objects']+1] = ent
	makermod.players[ply.id]['selected'] = ent
	if makermod.players[ply.id]['autograbbing'] then
		SendReliableCommand(ply.id, string.format('print "Effect grabbed:%d. Use /mgrabbing to turn off auto-grabbing.\n"', ent.id))
		makermod.players[ply.id]['grabbed'][#makermod.players[ply.id]['grabbed'] + 1] = ent
	else
		ent.position = makermod.players[ply.id]['mark_position'];
		SendReliableCommand(ply.id, string.format('print "Effect placed:%d  Origin: (%d %d %d)\n"', ent.id, math.floor(ent.position.x), math.floor(ent.position.y), math.floor(ent.position.z)))
	end
end

local function mKill(ply, args)
	local mode = args[1]
	if not mode then
		local ent = makermod.players[ply.id]['selected']
		if not ent then return end

		for k, v in pairs(makermod.players[ply.id]['grabbed']) do
			if v == ent then
				makermod.players[ply.id]['grabbed'][k] = nil
			end
		end

		makermod.players[ply.id]['selected'] = nil
 		RemoveEntity(ent)
	elseif mode == 'trace' then
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
							makermod.players[ply.id]['grabbed'] = nil
						end
					end
				RemoveEntity(ent)
				return
			end
		end
	elseif mode == 'all' then
		makermod.players[ply.id]['selected'] = nil
		makermod.players[ply.id]['grabbed'] = nil
		for _, ent in pairs(makermod.players[ply.id]['objects']) do
			if ent then
				RemoveEntity(ent)
				makermod.players[ply.id]['objects'][ent] = nil
			end
		end
	end
end

local function mMoveTime(ply, args)
	if #args < 1 then
		SendReliableCommand(ply.id, string.format('print "Your mmove time: %d ms (%d s)\n"', makermod.players[ply.id]['movetime'], makermod.players[ply.id]['movetime'] / 1000))
		return
	end
	local time = args[1]
	makermod.players[ply.id]['movetime'] = tonumber(time)
end

local function mMove(ply, args)
	-- wrong syntax
	if #args < 1 then
		SendReliableCommand(ply.id, 'print "Command usage:   ^5/mmove <speed>\n^7Command usage:   ^5/mmove <x> <y> <z>\n^7Command usage:   ^5/mmove <x> <y> <z> <duration> <easing>\n^7Type /mmove list for easing list.\n"')
		return
	end

	-- easing functions list
	if args[1] == 'list' then
		-- todo: minfo easing
		SendReliableCommand(ply.id, string.format('print "%s.\n"', easinglist))
		return
	end


	local ent = makermod.players[ply.id]['selected']
	if not ent then return end

	-- stopping the current moving
	for k, v in pairs(makermod.objects.moving) do
		if v.ent == ent and v.movingType == 'move' then
			makermod.objects.moving[k] = nil
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
	local dur = makermod.players[ply.id]['movetime']
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
		dest.x = tonumber(args[1]) * 10
		dest.y = tonumber(args[2]) * 10
		dest.z = tonumber(args[3]) * 10

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
		data.movingType = 'move'
		data.ent = ent
		data.start = GetRealTime()
		data.coords = dest
		data.pos = ent.position
		data.ease = ease
		data.dur = dur
		makermod.objects.moving[#makermod.objects.moving + 1] = data
	end
end

local function mRotate(ply, args)
	-- wrong syntax
	if #args < 1 then
		SendReliableCommand(ply.id, 'print "Command usage:   ^5/mrotate <x> <y> <z>\n^7Command usage:   ^5/mrotate <x> <y> <z> <duration> <easing>\n^7Type /mmove list for easing list.\n"')
		return
	end

	local ent = makermod.players[ply.id]['selected']
	if not ent then return end

	-- stopping the current moving
	for k, v in pairs(makermod.objects.moving) do
		if v.ent == ent and v.movingType == 'rotate' then
			makermod.objects.moving[k] = nil
		end
	end

	if #args == 1 then
		-- mrotate 0 -- for stopping rotating
		-- mrotate clear -- clear angle
		if args[1] == "clear" then
			ent.angles = Vector3(0, 0, 0)
		end
		return
	end

	-- parsing the args:

	-- mrotate x y z
	-- mrotate x y z dur
	-- mrotate x y z dur easing
	-- mrotate x y z easing
	local angle = Vector3(tonumber(args[1]), tonumber(args[2]), tonumber(args[3]))
	local dur = makermod.players[ply.id]['movetime']
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
		data.movingType = 'rotate'
		data.ent = ent
		data.start = GetRealTime()
		data.angle = angle
		data.from = ent.angles
		data.ease = ease
		data.dur = dur
		makermod.objects.moving[#makermod.objects.moving + 1] = data
	end
end

local function mConnectTo(ply, args)
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

local function mTouchable(ply, args)
 if not makermod.players[ply.id]['selected'] then return end
 		makermod.players[ply.id]['selected'].touchable = true
end

local function mUsable(ply, args)
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
	local func = function(a,b,c)
					if not b then return end
					if b.player then
						b.player:Teleport(data['tele_destination'], b.player.angles)
					else
						b.position = data['tele_destination'] --TODO: Entity Teleporting?
					end
				 end
end

local function mDest(ply, args)
	 if not makermod.players[ply.id]['selected'] then return end
	 if #args >= 1 then
		if args[1] == 'trace' then
			local trace = TraceEntity(ply, nil)
			makermod.objects[makermod.players[ply.id]['selected'].id]['tele_destination'] = Vector3(trace.endpos.x, trace.endpos.y, trace.endpos.z)
		else
		 	makermod.objects[makermod.players[ply.id]['selected'].id]['tele_destination'] = ParseVector(ply.position, args, 0)
		end
	end
end

local function mArm(ply, args)
	if #args < 1 then
		SendReliableCommand(ply.id, string.format('print "Marm: %d\n"', makermod.players[ply.id]['arm']))
		return
	end
	local arm = args[1]
	makermod.players[ply.id]['arm'] = tonumber(arm)
end

local function mGrabbing(ply, args)
	if makermod.players[ply.id]['autograbbing'] then
		makermod.players[ply.id]['autograbbing'] = false
		SendReliableCommand(ply.id, string.format('print "Automatic Grabbing OFF.\n"'))
	else
		makermod.players[ply.id]['autograbbing'] = true
		SendReliableCommand(ply.id, string.format('print "Automatic Grabbing ON.\n"'))
	end
end


local function mSelect(ply, args)
	local trace = TraceEntity(ply, nil)
	if trace.entityNum >= 0 then
		local ent = GetEntity(trace.entityNum)
		if not ent then return end
		if not CheckEntity(ent, ply) then
		 	return
		end
			makermod.players[ply.id]['selected'] = ent
	end
end

local function mDrop(ply, args)
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

local function mGrab(ply, args)
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
			makermod.objects[ent.id]['password'] = pass
		end
	else
		if not makermod.players[ply.id]['selected'] then return end
		local ent = makermod.players[ply.id]['selected']
		makermod.objects[ent.id]['password'] = value
	end
end

local function mPassword(ply, args)
	if #args < 1 then return end
	makermod.players[ply.id]['password'] = args[1]
end

local function mDoor(ply, args)

end

local function mName(ply, args)
	if not makermod.players[ply.id]['selected'] then return end
    if #args < 1 then return end
    makermod.objects[makermod.players[ply.id]['selected'].id]['name'] = args[1]
end

local function mAnim(ply, args)
	if #args < 1 then return end
	ply:SetAnim(args[1], 1, 1)
end

local function mMark(ply, args)
	local vec = ply.position
	local i, type, res
	if #args > 1 then
		vec = ParseVector(vec, args, 0)
	end
	if not makermod.players[ply.id]['mark_position'] then
		makermod.players[ply.id]['autograbbing'] = false
		SendReliableCommand(ply.id, string.format('print "Automatic Grabbing OFF. Use /mgrabbing to turn it back on.\n"'))
	end
	makermod.players[ply.id]['mark_position'] = vec
	SendReliableCommand(ply.id, string.format('print "Marked: (%d %d %d)\n"', math.floor(vec.x), math.floor(vec.y), math.floor(vec.z)))
end

local function mOrigin(ply)
	local vec = ply.position
	-- todo: make numbers round instead of floor
	SendReliableCommand(ply.id, string.format('print "Origin: (%d %d %d)\n"', math.floor(vec.x), math.floor(vec.y), math.floor(vec.z)))
end

local function mAttachFx(ply, args)
	if not makermod.players[ply.id]['selected'] then return end
	if #args < 1 then return end
	local temp = {}
	temp['bone'] = args[1]
	temp['ply'] = ply.entity
	temp['ent'] = makermod.players[ply.id]['selected']
	if #args > 1 then
		temp['x'] = tonumber(args[2])
		temp['y'] = tonumber(args[3])
		temp['z'] = tonumber(args[4])
	else
		temp['x'] = 0
		temp['y'] = 0
		temp['z'] = 0
	end
	makermod.objects.attached[#makermod.objects.attached + 1] = temp
end

local function mScale(ply, args)
	if #args < 1 then return end
	if args[1] == 'trace' then
		local trace = TraceEntity(ply, nil)
		if trace.entityNum >= 0 then
			local ent = GetEntity(trace.entityNum)
			if not ent then return end
			if not CheckEntity(ent, ply) then return end
			ent:Scale(tonumber(args[2]))
		end
	else
		if not makermod.players[ply.id]['selected'] then return end
		makermod.players[ply.id]['selected']:Scale(tonumber(args[1]))
	end
end

local function mScaleMe(ply, args)
	if #args < 1 then return end
	local ent = ply.entity
	ent:Scale(tonumber(args[1]))
end

local function mBreakable(ply, args)
	if not makermod.players[ply.id]['selected'] then return end
	if #args < 1 then return end
	makermod.players[ply.id]['selected'].breakable = true
	makermod.players[ply.id]['selected'].health = tonumber(args[1])
	makermod.players[ply.id]['selected']:SetDieFunction( function(a,b,c, d,e) 
															RemoveEntity(a)
															end )
end

local function mPain(ply, args)
	if not makermod.players[ply.id]['selected'] then return end
	if #args < 1 then return end
	local data = makermod.objects[makermod.players[ply.id]['selected'].id]
	if data['isfx'] == false then return end
	local dist = tonumber(args[1])
	local dmg = tonumber(args[2])
	if dist > makermod.cvars['pain_maxdist']:GetInteger()  or dist < 0 then dist = makermod.cvars['pain_maxdist']:GetInteger() end
	if dmg > makermod.cvars['pain_maxdmg']:GetInteger() or dmg < 0 then dmg = makermod.cvars['pain_maxdmg']:GetInteger() end
	makermod.players[ply.id]['selected']:SetVar('splashRadius', tostring(dist))
	makermod.players[ply.id]['selected']:SetVar('splashDamage', tostring(dmg))
	makermod.players[ply.id]['selected'].spawnflags = makermod.players[ply.id]['selected'].spawnflags | 4
end



local function mList(ply, args)
	local string = ''

	local list = GetFileList('models/map_objects/', 'md3')
	local function isHas(object, value)
		for _, v in pairs(object) do
			if v == value then
				return true
			end
		end
		return false
	end

	local models = {}
	for _, v in pairs(list) do
		if not isHas(models, v) then
			models[#models + 1] = v
			SendReliableCommand(ply.id, "print '" .. string.gsub(v, '.md3', '') .. "\n'")
		end
	end
end

local function mListFx(ply, args)
	local string = ''
	if #args < 1 then 
		local list = GetFileList('models/map_objects/', '/')
	else
		local list = GetFileList('models/map_objects/' .. args[1], '.md3')
	end
	for _,v in pairs(list) do
		v = string.sub(v, -4)
		string.format('%s%s\n', string, v)
		SendReliableCommand(ply.id, string.format("print '%s\n'"))
	end
end

local function mTelesp(ply, args)
	local list = FindEntityByClassname('info_player_deathmatch')
	local len = #list
	local spot = list[math.random(len)]
	ply:Teleport(spot.position)
end

local function mEllipse(ply, args)
	if #args < 1 then
		SendReliableCommand(ply.id, string.format('print "Command usage:   ^5/mellipse <radius>\n^7Command usage:   ^5/mellipse <rx> <ry>\n^7Command usage:   ^5/mellipse <rx> <ry> <period-in-milliseconds>\n"'))
		return
	end
	local rx = tonumber(args[1])
	local ry = args[2]
	local period = args[3]

	if not ry then
		ry = rx
	else
		ry = tonumber(ry)
	end

	if not period then
		period = 1000
	else
		period = tonumber(period)
	end

	local ent = makermod.players[ply.id]['selected']
	if not ent then return end

	local temp = {}
	temp.movingType = 'ellipse'
	temp.ent = ent
	temp.start = GetRealTime()
	temp.rx = rx
	temp.ry = ry
	temp.center = ply.position
	temp.period = period
	makermod.objects.moving[#makermod.objects.moving + 1] = temp
end

local function mAstroid(ply, args)
	if #args < 1 then
		return
	end
	local rx = tonumber(args[1])
	local ry = args[2]
	local period = args[3]

	if not ry then
		ry = rx
	else
		ry = tonumber(ry)
	end

	if not period then
		period = 1000
	else
		period = tonumber(period)
	end

	local ent = makermod.players[ply.id]['selected']
	if not ent then return end

	local temp = {}
	temp.movingType = 'astroid'
	temp.ent = ent
	temp.start = GetRealTime()
	temp.rx = rx
	temp.ry = ry
	temp.center = ply.position
	temp.period = period
	makermod.objects.moving[#makermod.objects.moving + 1] = temp
end

local function mSpiral(ply, args)
	if #args < 1 then
		return
	end
	local k = tonumber(args[1])
	local period = args[2]

	if not period then
		period = 1000
	else
		period = tonumber(period)
	end

	local ent = makermod.players[ply.id]['selected']
	if not ent then return end

	local temp = {}
	temp.movingType = 'spiral'
	temp.ent = ent
	temp.start = GetRealTime()
	temp.k = k
	temp.center = ply.position
	temp.period = period
	makermod.objects.moving[#makermod.objects.moving + 1] = temp
end

AddClientCommand('mplace', mSpawn)
AddClientCommand('mplacefx', mSpawnFX)
AddClientCommand('mkill', mKill)
AddClientCommand('mmovetime', mMoveTime)
AddClientCommand('mmove', mMove)
AddClientCommand('mrotate', mRotate)
AddClientCommand('mconnectto', mConnectTo)
AddClientCommand('mtouchable', mTouchable)
AddClientCommand('musable', mUsable)
AddClientCommand('mprintsw', mPrintsw)
AddClientCommand('mdest', mDest)
AddClientCommand('marm', mArm)
AddClientCommand('mgrabbing', mGrabbing)
AddClientCommand('mselect', mSelect)
AddClientCommand('mdrop', mDrop)
AddClientCommand('mgrab', mGrab)
AddClientCommand('msetpassword', mSetPassword)
AddClientCommand('mpassword', mPassword)
AddClientCommand('mname', mName)
AddClientCommand('mmark', mMark)
AddClientCommand('morigin', mOrigin)
AddClientCommand('manim', mAnim)
AddClientCommand('mattachfx', mAttachFx)
AddClientCommand('mscale', mScale)
AddClientCommand('mscaleme', mScaleMe)
AddClientCommand('mbreakable', mBreakable)
AddClientCommand('mpain', mPain)
AddClientCommand('mlist', mList)
AddClientCommand('mlistfx', mListFx)
AddClientCommand('mtelesp', mTelesp)

AddClientCommand('mellipse', mEllipse)
AddClientCommand('mastroid', mAstroid)
AddClientCommand('mspiral', mSpiral)

--[[

mlistso
mlistso weapons
mlistso items
mlistso machines

stunbaton
melee
saber
blasterpistol
concussionrifle
bryarpistol
blaster
disruptor
bowcaster
repeater
demp2
flechette
rocket

smallarmor
armor
medpak
seeker
shield
bacta
bigbacta
binoculars
sentry
jetpack
healthdisp
ammodisp
eweb
cloak
enlightenlight
enlightendark
boon
ysalimari
thermal
tripmine
detpack
force
blasterammo
powercell
bolts
rockets
allammo
redcube
bluecube

gun
ammounit
shieldunit
turret
miniturret
deathturret

]]--