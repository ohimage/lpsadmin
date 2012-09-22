local tbl = {}

tbl.format = {
	{PAdmin.types.STEAMID, "target<ID>" },
	{PAdmin.types.TIME, "time<number>"}
}

tbl.perm = "PAdmin.ban"
tbl.permdefault = true

tbl.run = function( ply, args )
	local id = args[1]

	ply:ConCommand( "banid "..id )
	
	PAdmin:Notice( player.GetAll(), PAdmin.colors.neutral, ply, " banned player with ID: ", id )
end

PAdmin:RegisterCommand( "banid", tbl )