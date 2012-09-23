local tbl = {}

tbl.format = {
	{PAdmin.types.PLY, "target" },
	{PAdmin.types.TIME, "time"},
	{PAdmin.types.STRING, "reason"},
}

tbl.perm = "PAdmin.ban"
tbl.permdefault = true

tbl.run = function( ply, args )
	local targ = PAdmin:FindPlayerByName( args[1] )
	if( not targ )then
		PAdmin:Notify(ply, PAdmin.colors.error, "Player not found." )
		return
	end
	print("Started to look at the time.")
	local time = PAdmin:TimeToMinutes( args[2] )
	PAdmin:Notice( player.GetAll(), PAdmin.colors.neutral, ply, " banned ", targ, " for ", args[2], " ( "..time..") minutes Reason: ", PAdmin.colors.yellow, args[3] )
	print("Past the time.")
	PAdmin:BanPlayer( targ, time, args[3], ply)
end

PAdmin:RegisterCommand( "ban", tbl )