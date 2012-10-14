local tbl = {}
tbl.format = {
	{PAdmin.types.PLY, "target<ply>" }
	{PAdmin.types.STRING, "killmode<enum>", {"explode","none"}}
}
tbl.perm = "PAdmin.slay"
tbl.catagory = "Punishments"

tbl.run = function( ply, name )
	local res = PAdmin:FindPlayersByName( name )
	local killmode
	if args[2] then
		killmode = args[2]
	end
	for k,v in pairs( res )do
		if killmode then
			if killmode == "explode" then
				--[[ Add Particle effects Here ]]--
				--[[ Add Limb Spawns Here ]]--
			end
		end
		v:Kill()
	end
	PAdmin:Notice( player.GetAll(), PAdmin.colors.neutral, ply, " slayed ", unpack( PAdmin:FormatPlayerTable( res ) ) )
end
PAdmin:RegisterCommand( "slay" , tbl )