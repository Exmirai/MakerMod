local plugin = RegisterPlugin("MakerMod", "2.0")

makermod = {}
makermod.objects = {}
makermod.players = {}

local function BlankFunc() end -----fucking lua without 'continue' statement

local function MainLoop()
	for id,data in pairs(makermod.players) do
		local ply = GetPlayer(id)
		if not makermod.players[ply.id]['grabbed'] then return end
		local ent = makermod.players[ply.id]['grabbed']
		local temp = JPMath.AngleVectors(ply.angles, true, false, false)
		temp = ply.position:MA(makermod.players[ply.id]['arm'], temp)
		ent.position = temp
		local ang = ply.angles
		ang.x = ent.angles.x
		ent.angles = ang
	end
end

AddListener('JPLUA_EVENT_RUNFRAME', MainLoop)


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
		
	makermod.objects[ent] = temp
end


local function TraceEntity(ply, dist)
	if not ply then return end
	if not dist then local dist = 16384 end
	local pos = ply.position
	pos.z = pos.z + 36.0
	local angles = JPMath.AngleVectors(ply.angles,true, false, false)
	local endPos = pos:MA(dist, angles)
	local trace = RayTrace(pos, 0, endPos, ply.id,Contents.CONTENTS_OPAQUE)
	return trace
end

local function CheckEntity(ent, ply)
		if not makermod.objects[ent] then
			SetupEntity(ent, 'map_object')
			SendReliableCommand(ply.id, string.format('print "You cannot select map object!"'))
			return false
		else
			local data = makermod.objects[ent]
			if data['owner'] ~= ply then
				SendReliableCommand(ply.id, string.format('print "You are not owner of this entity!"'))
				return false
			end
			if data['owner'] == 'map_object' then
				SendReliableCommand(ply.id, string.format('print "You cannot select map object!"'))
				return false
			end
		end
		return true
end

local function OnUserSpawn(ply, firsttime)
 	if not firsttime then return end
	makermod.players[ply.id] = {}
	makermod.players[ply.id]['selected'] = nil
	makermod.players[ply.id]['grabbed'] = nil
	makermod.players[ply.id]['arm'] = 200
	makermod.players[ply.id]['autograbbing'] = true
	makermod.players[ply.id]['objects'] = {}
	makermod.players[ply.id]['password'] = ''
	makermod.players[ply.id]['mark_position'] = nil
end
AddListener('JPLUA_EVENT_CLIENTSPAWN',OnUserSpawn)

local function onUserDisconnect(ply)
	for _, ent in pairs(makermod.players[ply.id]['objects']) do
		makermod.objects[ent] = nil
		ent:Free()
	end
	makermod.players[ply.id] = nil
end
AddListener('JPLUA_EVENT_CLIENTDISCONNECT',onUserDisconnect)

local function mSpawn(ply, args)
    if #args < 1 then return end

	local model = args[1]
	local vars = {}
	local plypos = ply.position
	local plyang = ply.angles
	
	local entpos = JPMath.AngleVectors(plyang, true,false,false)
	entpos = plypos:MA(makermod.players[ply.id]['arm'], entpos)
	
		vars['classname'] = 'misc_model'
		vars['model'] = model
	local ent = CreateEntity(vars)
	ent.position = entpos
	
	SetupEntity(ent, ply)
	makermod.players[ply.id]['objects'][#makermod.players[ply.id]['objects']+1] = ent
	makermod.players[ply.id]['selected'] = ent
	if makermod.players[ply.id]['autograbbing'] then
		makermod.players[ply.id]['grabbed'] = ent
	end
end

local function mSpawnFX(ply, args)
	if #args < 1 then return end

	local fx = args[1]
	local vars = {}
	local plypos = ply.position
	local plyang = ply.angles

	local entpos = JPMath.AngleVectors(plyang, true, false, false)
	entpos = plypos:MA(makermod.players[ply.id]['arm'], entpos)
	
		vars['classname'] = 'fx_runner'
		vars['fxFile'] = fx
	local ent = CreateEntity(vars)
	ent.position = entpos
	
	SetupEntity(ent, ply)
	makermod.players[ply.id]['objects'][#makermod.players[ply.id]['objects']+1] = ent
	makermod.players[ply.id]['selected'] = ent
	if makermod.players[ply.id]['autograbbing'] then
		makermod.players[ply.id]['grabbed'] = ent
	end
end

local function mKill(ply, args)
	local mode = args[1]
	if not mode then
		if not makermod.players[ply.id]['selected'] then return end
 		makermod.objects[makermod.players[ply.id]['selected']] = nil
		makermod.players[ply.id]['selected']:Free()
		makermod.players[ply.id]['selected'] = nil
	elseif mode == 'trace' then
		local trace = TraceEntity(ply, nil)
		if trace.entityNum > 0 then
			local ent = GetEntity(trace.entityNum)
			if not ent then return end
			if CheckEntity(ent, ply) then
				ent:Free()
				makermod.objects[ent] = nil
				return
			end
		end
	elseif mode == 'all' then
		for _, ent in pairs(makermod.players[ply.id]['objects']) do
			ent:Free()
		end
		makermod.players[ply.id]['grabbed'] = nil
	end
end

local function mMove(ply, args)
	if not makermod.players[ply.id]['selected'] then return end
	local vec = Vector3(args[1], args[2], args[3])
	makermod.players[ply.id]['selected'].position = vec
end

local function mRotate(ply, args)
	if not makermod.players[ply.id]['selected'] then return end
	local vec = Vector3(args[1], args[2], args[3])
	makermod.players[ply.id]['selected'].angles = vec
end

local function mConnectTo(ply, args)
	if not makermod.players[ply.id]['selected'] then return end
	
	local trace = TraceEntity(ply, nil)
	if trace.entityNum >= 0 then
		local ent = GetEntity(trace.entityNum)
		if not CheckEntity(ent, ply) then return end
		local data1 = makermod.objects[makermod.players[ply.id]['selected']]
		local data2 = makermod.objects[ent]
			data1['connectedTo'][#data1['connectedTo']+1] = ent
			data2['connectedFrom'][#data2['connectedFrom']+1] = makermod.players[ply.id]['selected']
	else
		SendReliableCommand(ply.id, string.format('print "0 entity traced"'))
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
			makermod.objects[ent]['touchfuncs'][#makermod.objects[ent]['touchfuncs'] + 1] = printfunc
		end
		if ent.usable then
			makermod.objects[ent]['usefuncs'][#makermod.objects[ent]['usefuncs'] + 1] = printfunc
		end
	end
end

local function mTelesw(ply, args)
	if not makermod.players[ply.id]['selected'] then return end
	local data = makermod.objects[makermod.players[ply.id]['selected']]
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
			makermod.objects[makermod.players[ply.id]['selected']]['tele_destination'] = Vector3(trace.endpos.x, trace.endpos.y, trace.endpos.z)
		elseif #args >= 3 then
			makermod.objects[makermod.players[ply.id]['selected']]['tele_destination'] = Vector3(tonumber(args[1]), tonumber(args[2]) ,tonumber(args[3]))
		end
	 elseif #args == 0 then
	 		makermod.objects[makermod.players[ply.id]['selected']]['tele_destination'] = Vector3(ply.position.x, ply.position.y, ply.position.z)
	 end
end

local function mArm(ply, args)
	if #args < 1 then
		SendReliableCommand(ply.id, string.format('print "Marm: "' .. makermod.players[ply.id]['arm']))
		return
	end
	local arm = args[1]
	makermod.players[ply.id]['arm'] = tonumber(arm)
end

local function mGrabbing(ply, args)
	if makermod.players[ply.id]['autograbbing'] then
		makermod.players[ply.id]['autograbbing'] = false
		SendReliableCommand(ply.id, string.format('print "^3Autograbbing - ^1disabled"'))
	else
		makermod.players[ply.id]['autograbbing'] = true
		SendReliableCommand(ply.id, string.format('print "^3Autograbbing - ^2enabled"'))
	end
end


local function mSelect(ply, args)
	local trace = TraceEntity(ply, nil)
	if trace.entityNum >= 0 then
		local ent = GetEntity(trace.entityNum)
		if not ent then return end
		if not CheckEntity(ent, ply) then
			SendReliableCommand(ply.id, string.format('print "You not own this entity!"'))
		 	return
		end
			makermod.players[ply.id]['selected'] = ent
	end
end

local function mDrop(ply, args)
	if not makermod.players[ply.id]['grabbed'] then return end
	makermod.players[ply.id]['grabbed'] = nil
end

local function mGrab(ply, args)
	if not makermod.players[ply.id]['selected'] then return end
	makermod.players[ply.id]['grabbed'] = makermod.players[ply.id]['selected']
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
			makermod.objects[ent]['password'] = pass
		end
	else
		if not makermod.players[ply.id]['selected'] then return end
		local ent = makermod.players[ply.id]['selected']
		makermod.objects[ent]['password'] = value
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
    makermod.objects[makermod.players[ply.id]['selected']]['name'] = args[1]
end

local function mAnim(ply, args)
	if #args < 1 then return end
	ply:SetAnim(args[1], 1, 1)
end

local function mMark(ply, args)
	local vec = ply.position
	local i, type, res
	if #args > 1 then
		for i=1, 3 do
			if i==1 then type = 'x' elseif i==2 then type = 'y' elseif i==3 then type='z' end
			if args[i] == nil then
				return
			else
				res = string.match(args[i], "+(%d+)")
				if res then
					vec[type] = vec[type] + res
				else
					res = string.match(args[i], "-(%d+)")
					if res then
						vec[type] = vec[type] - res
					end
				end
			end
		end
	end
	makermod.players[ply.id]['mark_position'] = vec
	SendReliableCommand(ply.id, string.format('print "Mark set to %s"', tostring(vec)))
end

AddClientCommand('mplace', mSpawn)
AddClientCommand('mplacefx', mSpawnFX)
AddClientCommand('mkill', mKill)
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
AddClientCommand('manim', mAnim)
