local god = {}
god.format = {
	{PAdmin.types.PLY, "target<ply>" }
}
god.perm = "PAdmin.god"
god.catagory = "Fun"

god.run = function( ply, args )
	local res = PAdmin:FindPlayersByName( args[1] )
	local goded = {}
	local ungoded = {}
	for k,v in pairs( res )do
		if(v.PA_Goded)then
			if( ply:HasPermission("PAdmin.ungod"))then
				v:GodDisable()
				v.PA_Goded = nil
				table.insert(ungoded, v )
			end
		else
			v:GodEnable()
			v.PA_Goded = true
			table.insert(goded, v )
		end
	end
	if( #goded > 0 )then
	PAdmin:Notify( player.GetAll(), PAdmin.colors.good, ply, " enabled ",PAdmin.colors.neutral,"godmode for ", PAdmin:FormatPlayerTable( goded ))
	end
	if( #ungoded > 0 )then
	PAdmin:Notify( player.GetAll(), PAdmin.colors.bad, ply, " disabled",PAdmin.colors.neutral," godmode for ", PAdmin:FormatPlayerTable( ungoded ) )
	end
end
PAdmin:RegisterCommand( "god" , god )


local ungod = {}
ungod.format = {
	{PAdmin.types.PLY, "target<ply>" }
}
ungod.perm = "PAdmin.ungod"
ungod.catagory = "Fun"

ungod.run = function( ply, args )
	local res = PAdmin:FindPlayersByName( args[1] )
	local goded = {}
	local ungoded = {}
	for k,v in pairs( res )do
		if(v.PA_Goded)then
			v:GodDisable()
			v.PA_Goded = nil
			table.insert(ungoded, v )
		end
	end
	if( #ungoded > 0 )then
	PAdmin:Notify( player.GetAll(), PAdmin.colors.bad, ply, " disabled",PAdmin.colors.neutral," godmode for ", PAdmin:FormatPlayerTable( ungoded ) )
	end
end
PAdmin:RegisterCommand( "ungod" , ungod )