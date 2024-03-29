local tbl = {}

tbl.format = {
	{PAdmin.types.PLY, "target<ply>"},
	{PAdmin.types.STRING, "[reason]", ["optional"] = true }
}

tbl.perm = "PAdmin.kick"
tbl.catagory = "User Managment"

tbl.run = function( ply, name, ... )
	local res = PAdmin:FindPlayerByName( name )
	local arg = { ... }
	if( not res )then
		PAdmin:Notify( ply, PAdmin.colors.error, "No targets found!")
		return
	end
	
	local reason
	if( #arg > 1 )then
		reason = table.concat( arg, " " )
	else
		reason = "Kicked by Admin"
	end
	PAdmin:Notify( player.GetAll(), PAdmin.colors.neutral, ply, PAdmin.colors.good, " kicked ", PAdmin.colors.neutral, res, " with reason: ", reason )
	res:Kick( reason )
end

PAdmin:RegisterCommand( "kick" , tbl )
