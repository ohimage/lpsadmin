if(CLIENT)then
	timer.Simple( 5, function()
		LocalPlayer():ConCommand("PA_Welcome "..system.GetCountry())
	end)
elseif(SERVER)then
	local tbl = {}
	concommand.Add("PA_Welcome",function( ply, cmd, args )
		if( not table.HasValue( tbl, ply:UserID() ))then
			table.insert(tbl, ply:UserID())
			PAdmin:Notify( player.GetAll(), PAdmin.colors.neutral, "Welcome player ", ply, " from ", PAdmin.colors.purple, args[1] )
		end
	end)
end