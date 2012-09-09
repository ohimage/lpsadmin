local tbl = {}
tbl.format = {
	{PAdmin.types.PLY, "target<ply>" }
}
tbl.perm = "PAdmin.slay"
tbl.permdefault = true
tbl.run = function( ply, args )
	local res = PAdmin:FindPlayersByName( args[1] )
	for k,v in pairs( res )do
		v:Kill()
	end
	PAdmin:Notice( player.GetAll(), PAdmin.colors.neutral, ply, " slayed ", unpack( PAdmin:FormatPlayerTable( res ) ) )
end
PAdmin:RegisterCommand( "slay" , tbl )