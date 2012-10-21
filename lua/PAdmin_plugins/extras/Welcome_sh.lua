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
		["GB"]="England",
		["FL"]="Finland",
		["KR"]="Korea",
		["NZ"]="New Zeland",
	}
	local tbl = {} 
	concommand.Add("PA_Welcome",function( ply, cmd, args )
		if( not args[1] )then return end
		if( not table.HasValue( tbl, ply:UserID() ))then
			table.insert(tbl, ply:UserID())
			local country = args[1]
			if( countries[ args[1] ] )then
				country = countries[ args[1] ]
			end
			PAdmin:Notify( player.GetAll(), PAdmin.colors.neutral, "Welcome player ", ply, " from ", PAdmin.colors.blue, country )
		end
	end)
end