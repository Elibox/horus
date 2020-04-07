horus.command('slay', 'Eliminate a player', {'player_one'}, function(caller, target)
	if target:Alive() then
		target:Kill()
	end
	return true, '%c killed %1'
end)

--horus.command('multislay', 'Eliminate multiple players!', {'player_one', 'player_two'}, function(caller, target1, target2)
--	if target1:Alive() then
--		target1:Kill()
--	end
--	return true, '%c killed %1'
--	if target2:Alive() then
--		target2:Kill()
--	end
--	return true, '%c killed %1'
--end)

horus.command('explode', 'Detonate a player', {'player_one'}, function(caller, target)
	if target:Alive() then
		local boom = ents.Create('env_explosion')
		boom:SetPos( target:GetPos() )
		boom:Spawn()
		boom:SetKeyValue('iMagnitude', '150')
		boom:Fire('Explode')
		target:Kill()
	end
	return true, '%c exploded %1'
end)

horus.command('spookify', 'Sets the model of a player to a skeleton', {'player_one'}, function(caller, target)
	if target:Alive() then
		target:SetModel('models/player/skeleton.mdl')
	end
	return true, '%c spookified %1'
end)

horus.command('goto', 'Goto a player', {'player_one'}, function(caller,target)
	if target:Alive() then
		local pos = target:GetPos()
		caller:SetPos(pos)
	end
	return true, '%c went to %1'
end)

horus.command('teleport', "Teleport a player to where you're looking", {'player_one'}, function(caller,target)
	if target:Alive() then
		local pos = caller:GetAimVector()
		target:SetPos(pos)
	end
	return true, '%c teleported %1'
end)