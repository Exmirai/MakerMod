local toolgun = {}
if makermod then
	makermod.toolgun = toolgun
end

toolgun.modes = {}
toolgun.settings = {}

local function PrintToPlayer(ply, string)
	SendReliableCommand(ply.id, string.format('print "%s\n"', string))
end

function toolgun.setupplayer(ply)
	local temp = {}
	temp['currentmode'] = 'place'
	temp['currentmodeinc'] = 1
	temp['place_model'] = 'factory/catw2_b'
	temp['connect_selected'] = nil
	toolgun.settings[ply.id] = temp
end

local function Fire(ent)
	if not ent.player then return end
	local mode = toolgun.settings[ent.player.id].currentmode
	local modefunc = toolgun.modes[mode]
	local res, err = pcall(modefunc, ent)
--	if not res then print('^2JPLua: ^3Makermod: ^1Error: ^7 Failed to execute ' .. toolgun.settings[ent.player.id]['currentmode'] .. ' mode ( ' .. err .. ' )') end
end

local function AltFire(ent) --mode selector
	if not ent.player then return end
	if toolgun.settings[ent.player.id]['currentmodeinc'] >= #toolgun.modes then toolgun.settings[ent.player.id]['currentmodeinc'] = 1 else
		toolgun.settings[ent.player.id]['currentmodeinc'] = toolgun.settings[ent.player.id]['currentmodeinc'] + 1
	end
	toolgun.settings[ent.player.id]['currentmode'] = toolgun.modes[toolgun.settings[ent.player.id]['currentmodeinc']]
	PrintToPlayer(ent.player, "Current Mode is: " .. toolgun.settings[ent.player.id]['currentmode'])
end

local function TPlace(ent)
	makermod.mSpawn(ent.player, {toolgun.settings[ent.player.id]['place_model']})
end

local function TPlace_SelectModel(ent)
	toolgun.settings[ent.player.id]['place_model'] = 'factory/catw2_b'
end

local function TRemove(ent)
	makermod.mKill(ent.player, {'trace'})
end

local function TTrace(ent)
	-- doesnt works :(
	local trace = TraceEntity(ent.player, nil)
	if trace.entityNum > 0 then
		local ent = GetEntity(trace.entityNum)
		if not ent then return end
		SendReliableCommand(ent.player.id, string.format('print "Entity %s: %d\nOrigin: (%d %d %d)\n"', ent.classname, ent.id, math.floor(ent.position.x), math.floor(ent.position.y), math.floor(ent.position.z)))
	end
end

local function TConnect(ent)
	if not toolgun.settings[ent.player.id]['connect_selected'] then
		local trace = TraceEntity(ent.player, nil)
			if trace.entityNum > 0 then
				local target = GetEntity(trace.entityNum)
				if not target then return end
				if CheckEntity(target, ply) then
					toolgun.settings[ent.player.id]['connect_selected'] = target
				end
			end
	else
			local trace = TraceEntity(ent.player, nil)
			if trace.entityNum > 0 then
				local target = GetEntity(trace.entityNum)
				if not target then return end
				if CheckEntity(target, ply) then
					if toolgun.settings[ent.player.id]['connect_selected'] == target then 
						toolgun.settings[ent.player.id]['connect_selected'] = nil
						return
					else
						local data1 = makermod.objects[toolgun.settings[ent.player.id]['connect_selected'].id]
						local data2 = makermod.objects[target.id]
						data1['connectedTo'][#data1['connectedTo']+1] = target
						data2['connectedFrom'][#data2['connectedFrom']+1] = toolgun.settings[ent.player.id]['connect_selected']
					end
				end
			end
	
	end
end

function toolgun.init()
	toolgun.modes['place'] = TPlace
		toolgun.modes[1] = 'place'
	toolgun.modes['remove'] = TRemove
		toolgun.modes[2] = 'remove'
	toolgun.modes['connect'] = TConnect
		toolgun.modes[3] = 'connect'
	toolgun.modes['place_modelselect'] = TPlace_SelectModel
		toolgun.modes[4] = 'place_modelselect'
	toolgun.modes['trace'] = TTrace
		toolgun.modes[5] = 'trace'

	SetWeaponFireFunc(Weapons.STUN_BATON, Fire)
	SetWeaponAltFireFunc(Weapons.STUN_BATON, AltFire)
end

