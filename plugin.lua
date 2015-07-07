local plugin = RegisterPlugin("MakerMod", "2.0")

makermod = {}
makermod.objects = {}
makermod.players = {}

local function BlankFunc() end -----fucking lua without 'continue' statement

local function SetupEntity(ent, ply)
	local temp = {}
		temp['owner'] = ply
		temp['touchfuncs'] = {}
		temp['usefuncs'] = {}
		temp['connectedTo'] = {}
		temp['connectedFrom'] = {}
		
	local touchfunc = function(ent, from, trace)
						for _, r in pairs(temp['touchfuncs']) do ---Check Internal functions
							pcall(r, ent, from, trace)
						end
						
						for _, r in pairs(temp['connectedTo'])  ---Check Connected Entities
							local data = makermod.objects[r]
							if !data then
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
						
						for _, r in pairs(temp['connectedTo']) ---Check Connected Entities
							local data = makermod.objects[r]
							if !data then
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
	if !ply then return end
	if !dist then local dist = 16384
	local pos = ply.position
	pos.z = pos.z + 36.0
	local angles = JPMath.AnglesVectors(ply.angles,true, false, false)
	local endPos = pos:MA(dist, angles)
	local trace = RayTrace(pos, 0, endPos, ply.id,Contents.CONTENTS_OPAQUE)
	return trace
end

local function CheckEntity(ent)
		if !makermod.objects[ent] then
			SetupEntity(ent, 'map_object')
			SendReliableCommand(ply.id, string.format('print "You cannot select map object!"'))
			return false
		else
			local data = makermod.objects[ent]
			if data['owner'] != ply then
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
	

end

local function onUserDisconnect(ply)
	makermod.players[ply.id] = nil
end

local function mSpawn(ply, args)
	local model = args[1]
	local vars = {}
	local plypos = ply.position
	local plyang = ply.angles
	
	local foo = JPMath.AngleVectors(plyang, true,false,false)
	foo = plypos:MA(200, foo)
	
		vars['classname'] = 'misc_model'
		vars['model'] = model
	local ent = CreateEntity(vars)
	ent.position = foo
	
	SetupEntity(ent, ply)
	makermod.players[ply.id]['selected'] = ent
end

local function mKill(ply, args)
	if not makermod.players[ply.id]['selected'] then return end

 		makermod.objects[makermod.players[ply.id]['selected']] = nil
		makermod.players[ply.id]['selected']:Free()
		makermod.players[ply.id]['selected'] = nil
end

local function mMove(ply, args)
	if not makermod.players[ply.id]['selected'] then return end
	
	local vec = Vector3(args[1],args[2], args[3])
end

local function mRotate(ply, args)
	if not makermod.players[ply.id]['selected'] then return end
	
	local vec = Vector3(args[1],args[2], args[3])
	
end

local function mConnectTo(ply, args)
	if not makermod.players[ply.id]['selected'] then return end
	
	local trace = TraceEntity(ply)
	if trace.entityNum >= 0 then
		local ent = GetEntity(trace.entityNum)
		if not CheckEntity(ent) then return end
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

local function mPrint(ply, args)
	if not makermod.players[ply.id]['selected'] then return end
	local text = args[1]
	local ent = makermod.players[ply.id]['selected']
	if ent.touchable or ent.usable then
		local printfunc = function(a,b,c)
							if b != nil and b.player != nil then
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
	if 
end



local function mSelect(ply, args)
	local trace = TraceEntity(ply)
	if trace.entityNum >= 0 then
		local ent = GetEntity(trace.entityNum)
		if !ent return end
		if not CheckEntity(ent) then
			SendReliableCommand(ply.id, string.format('print "You not own this entity!"'))
		 	return
		end
			makermod.players[ply.id]['selected'] = ent
		end
	end
end


