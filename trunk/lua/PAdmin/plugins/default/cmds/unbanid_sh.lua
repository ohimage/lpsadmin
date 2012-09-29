local tbl = {}

tbl.format = {
	{PAdmin.types.STEAMID, "target<ID>" },
	{PAdmin.types.TIME, "time<number>"}
}

tbl.perm = "PAdmin.ban"
tbl.catagory = "User Managment"

tbl.run = function( ply, args )
	local id = args[1]

	ply:ConCommand( "removeid "..id )
	
	PAdmin:Notice( player.GetAll(), PAdmin.colors.neutral, ply, " unbanned player with ID: ", id )
end

PAdmin:RegisterCommand( "unbanid", tbl )