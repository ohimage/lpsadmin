local tbl = {}
tbl.format = {
	{PAdmin.types.PLY, "target<ply>" },
	{PAdmin.types.NUMBER, "damage<num>" }
}
tbl.perm = "PAdmin.slap"
tbl.permdefault = true
tbl.run = function( ply, args )
	local res = PAdmin:FindPlayersByName( args[1] )
	for k,v in pairs( res )do
		v:TakeDamage( tonumber( args[2] ), ply, ply)
		v:SetVelocity( Vector( math.random( -200, 200 ), math.random( -200, 200 ), math.random( 100, 600 ) )) 
	end
	PAdmin:Notice( player.GetAll(), PAdmin.colors.neutral, ply, " slapped ", PAdmin:FormatPlayerTable( res ), " with ", args[2] , " damage." )
end
PAdmin:RegisterCommand( "slap" , tbl )