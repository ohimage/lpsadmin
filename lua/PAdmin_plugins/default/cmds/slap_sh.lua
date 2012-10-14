local tbl = {}
tbl.format = {
	{PAdmin.types.PLY, "target<ply>" },
	{PAdmin.types.NUMBER, "damage<num>" }
}
tbl.perm = "PAdmin.slap"
tbl.catagory = "Punishments"

tbl.run = function( ply, name, damage )
	local res = PAdmin:FindPlayersByName( name )
	local soundvar = 1
	for k,v in pairs( res )do
		soundvar = math.Round(math.Rand(1, 6))
		v:TakeDamage( tonumber( damage ), ply, ply)
		v:SetVelocity( Vector( math.random( -200, 200 ), math.random( -200, 200 ), math.random( 100, 600 ) )) 
		v:EmitSound( "physics/body/body_medium_impact_hard"..soundvar..".wav", 100, 100 )
	end
	PAdmin:Notice( player.GetAll(), PAdmin.colors.neutral, ply, " slapped ", PAdmin:FormatPlayerTable( res ), " with ", damage , " damage." )
end
PAdmin:RegisterCommand( "slap" , tbl )