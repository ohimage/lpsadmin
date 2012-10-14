local tbl = {}

tbl.format = {
	{PAdmin.types.STEAMID, "target<ID>" },
	{PAdmin.types.TIME, "time<number>"}
}

tbl.perm = "PAdmin.ban"
tbl.catagory = "User Managment"

tbl.run = function( ply, steamid )
	local id = args[1]

	ply:ConCommand( "removeid "..id )
	local shit = sql.Query( "SELECT * FROM PAdmin_Bans WHERE steamid = "..sql.SQLStr( steamid ) )
	sql.Query( "DELETE FROM PAdmin_Bans WHERE steamid = "..sql.SQLStr( steamid ) )
	if( shit )then
		PAdmin:Notice( player.GetAll(), PAdmin.colors.neutral, ply, " unbanned player with ID: ", id )
	else
		PAdmin:Notice( ply, PAdmin.colors.error, "SteamID isnt banned.")
	end
end

PAdmin:RegisterCommand( "unbanid", tbl )