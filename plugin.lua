local plugin = RegisterPlugin("MakerMod", "2.0")

makermod = {}
makermod.objects = {}
makermod.players = {}

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
	local ent = CreateEntity()
	ent.position = foo
	
	local temp = {}
		temp['owner'] = ply
		temp['touchfuncs'] = {}
		temp['usefuncs'] = {}
		
	local touchfunc = function(ent, from, trace)
						for _, r in pairs(temp['touchfuncs']) do
							pcall(r, ent, from, trace)
						end
	                  end
					  
	local usefunc = function(ent, from, activator)
						for _, r in pairs(temp['usefuncs']) do
							pcall(r, ent, from, activator)
						end
	                  end
		
	makermod.objects[ent] = temp
	makermod.players[ply.id]['selected'] = ent
end

local function mRemove(ply, args)
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
	
end

local function mTouchable(ply, args)
 if not makermod.users[ply.id]['selected'] then return end
 		makermod.users[ply.id]['selected'].touchable = true
end

local function mUsable(ply, args)
	if not makermod.players[ply.id]['selected'] then return end
	makermod.users[ply.id]['selected'].usable = true
end

local function mPrint(ply, args)
	if not makermod.players[ply.id]['selected'] then return end
	local text = args[1]
	local ent = makermod.users[ply.id]['selected']
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
	if not makermod.players[ply.id]['selected'] then return end
	
end


