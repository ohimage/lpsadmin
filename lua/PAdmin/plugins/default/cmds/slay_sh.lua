local tbl = {}
tbl.format = {
	{PAdmin.types.PLY, "target<ply>" }
}
tbl.perm = "PAdmin.slay"
tbl.catagory = "Punishments"

tbl.run = function( ply, args )
	local res = PAdmin:FindPlayersByName( args[1] )
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