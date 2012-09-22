if(CLIENT)then
	timer.Simple( 5, function()
		LocalPlayer():ConCommand("PA_Welcome "..system.GetCountry())
	end)
elseif(SERVER)then
	local countries = {
		["US"]="United States",
		["LT"]="Lithuania",
		["RU"]="Russia",
		["AU"]="Australia",
		["GB"]="England"
	}
	local tbl = {}
	concommand.Add("PA_Welcome",function( ply, cmd, args )
		if( not args[1] )then return end
		if( not table.HasValue( tbl, ply:UserID() ))then
			table.insert(tbl, ply:UserID())
			if( countries[ args[1] ] )then
				args[1] = countries[ args[1] ]
			end
			PAdmin:Notify( player.GetAll(), PAdmin.colors.neutral, "Welcome player ", ply, " from ", PAdmin.colors.purple, args[1] )
		end
	end)
end