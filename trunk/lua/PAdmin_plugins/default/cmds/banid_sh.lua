local tbl = {}

tbl.format = {
	{PAdmin.types.STEAMID, "target" },
	{PAdmin.types.TIME, "time"},
	{PAdmin.types.STRING, "reason"},
}

tbl.perm = "PAdmin.ban"
tbl.catagory = "User Managment"

tbl.run = function( ply, id, time_str )
	local time = PAdmin:TimeToMinutes( time_str )
	PAdmin:Notice( player.GetAll(), PAdmin.colors.neutral, ply, " banned ", id, " for ", time_str, " ( "..time..") minutes Reason: ", PAdmin.colors.yellow, args[3] )
	PAdmin:BanPlayer( args[1], time, args[3], ply)
end

PAdmin:RegisterCommand( "banid", tbl )