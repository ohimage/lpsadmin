local tbl = {}
tbl.format = {
	{PAdmin.types.PLY, "target<ply>" },
	{PAdmin.types.NUMBER, "damage<num>" }
}
tbl.perm = "PAdmin.slap"
tbl.catagory = "Punishments"

tbl.run = function( ply, args )
	local res = PAdmin:FindPlayersByName( args[1] )
	local soundvar = 1
	for k,v in pairs( res )do
		soundvar = math.Round(math.Rand(1, 6))
		v:TakeDamage( tonumber( args[2] ), ply, ply)
		v:SetVelocity( Vector( math.random( -200, 200 ), math.random( -200, 200 ), math.random( 100, 600 ) )) 
		v:EmitSound( "physics/body/body_medium_impact_hard"..soundvar..".wav", 100, 100 )
	end
	PAdmin:Notice( player.GetAll(), PAdmin.colors.neutral, ply, " slapped ", PAdmin:FormatPlayerTable( res ), " with ", args[2] , " damage." )
end
PAdmin:RegisterCommand( "slap" , tbl )