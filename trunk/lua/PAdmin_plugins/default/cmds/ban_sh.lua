local tbl = {}

tbl.format = {
	{PAdmin.types.PLY, "target" },
	{PAdmin.types.TIME, "time", {"5m","30m","1h","12h","1d","1w","2w","0"}},
	{PAdmin.types.STRING, "[reason]", ["optional"] = true},
}

tbl.perm = "PAdmin.ban"
tbl.catagory = "User Managment"

tbl.run = function( ply, name, time_str, reason )
	local targ = PAdmin:FindPlayerByName( name )
	if( not targ )then
		PAdmin:Notify(ply, PAdmin.colors.error, "Player not found." )
		return
	end
	if( not reason )then
		reason = "(Banned by admin.)"
	end
	local time = PAdmin:TimeToMinutes( time_str )
	PAdmin:Notice( player.GetAll(), PAdmin.colors.neutral, ply, " banned ", targ, " for ", time_str, " ( "..time..") minutes Reason: ", PAdmin.colors.yellow, reason )
	PAdmin:BanPlayer( targ, time, reason, ply)
end

PAdmin:RegisterCommand( "ban", tbl )