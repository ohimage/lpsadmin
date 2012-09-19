local tbl = {}

tbl.format = {
	{PAdmin.types.PLY, "target<ply>"}
}

tbl.perm = "PAdmin.kick"
tbl.permdefault = true

tbl.run = function( ply, args )
	local res = PAdmin:FindPlayerByName( args[1] )
	if( not res )then
		PAdmin:NotifY( ply, PAdmin.colors.error, "No targets found!")
		return
	end
	
	table.remove( args, 1 )
	local reason
	if( #args > 1 )then
		reason = table.concat( args, " " )
	else
		reason = "Kicked by Admin"
	end
	res:Kick()
	if not reason then reason = "Admin Control" end
	PAdmin:Notify( player.GetAll(), PAdmin.colors.neutral, ply, PAdmin.colors.good, " kicked ", PAdmin.colors.neutral, res, " with reason: ", reason )
end

PAdmin:RegisterCommand( "kick" , tbl )
