local tbl = {}
tbl.format = {
	{PAdmin.types.PLY, "target<ply>" },
	{PAdmin.types.NUMBER, "HP<num>" }
}
tbl.perm = "PAdmin.slay"
tbl.permdefault = true
tbl.run = function( ply, args )
	local res = PAdmin:FindPlayersByName( args[1] )
	for k,v in pairs( res )do
		v:SetHealth( tonumber( args[2] ) )
	end
	PAdmin:Notify( player.GetAll(), PAdmin.colors.white, ply, " set health for players ", PAdmin:FormatPlayerTable( res ) , " to ", args[2] )
end
PAdmin:RegisterCommand( "hp" , tbl )