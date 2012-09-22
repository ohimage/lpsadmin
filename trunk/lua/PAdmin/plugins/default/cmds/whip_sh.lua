local tbl = {}
tbl.format = {
	{PAdmin.types.PLY, "target<ply>" },
	{PAdmin.types.NUMBER, "damage<num>" },
	{PAdmin.types.NUMBER, "times<num>" }
}
tbl.perm = "whip"
tbl.permdefault = true

local whiplist = {}
local function whip( ply, dmg )
	for k,v in pairs( whiplist )do
		local soundvar = 0
		if( not ( v[2] == 0 ))then
			v[2] = v[2] - 1
			math.Round(math.Rand(1, 6))
			k:TakeDamage( v[1], nil, nil)
			k:SetVelocity(Vector( math.random( -400, 400 ), math.random( -400, 400 ), math.random( -100, 400 ) ))
			k:EmitSound( "physics/body/body_medium_impact_hard"..soundvar..".wav", 100, 100 )
			if not k:Alive() then
				whiplist[ k ] = nil
			end
		else
			whiplist[ k ] = nil
		end
	end
end

timer.Create("PAdmin.p.dowhip",1,0, whip )

tbl.run = function( ply, args )
	local res = PAdmin:FindPlayersByName( args[1] )
	local dmg = tonumber( args[2] )
	local times = tonumber( args[3] )
	for k,v in pairs( res )do
		whiplist[ v ] = { dmg, times }
	end
	PAdmin:Notice( player.GetAll(), PAdmin.colors.neutral, ply, " whipped ", PAdmin:FormatPlayerTable( res ), " with ", args[2] , " damage ", args[3], " times." )
end
PAdmin:RegisterCommand( "whip" , tbl )