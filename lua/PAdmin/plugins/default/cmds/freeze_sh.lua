local freeze = {}
local unfreeze = {}

freeze.format = {
	{PAdmin.types.PLY, "target<ply>"}
}
unfreeze.format = {
	{PAdmin.types.PLY, "target<ply>"}
}

freeze.perm = "PAdmin.freeze"
freeze.permdefault = true

unfreeze.perm = "PAdmin.unfreeze"
unfreeze.permdefault = true

local soundlist = {
	"physics/glass/glass_bottle_break1.wav",
	"physics/glass/glass_bottle_break2.wav",
	"physics/glass/glass_cup_break1.wav",
	"physics/glass/glass_cup_break2.wav",
	"physics/glass/glass_impact_bullet1.wav",
	"physics/glass/glass_impact_bullet2.wav",
	"physics/glass/glass_impact_bullet3.wav",
	"physics/glass/glass_pottery_break3.wav",
	"physics/glass/glass_pottery_break4.wav"
}

freeze.run = function( ply, args )
	local res = PAdmin:FindPlayersByName( args[1] )
	local rand = 0
	for k, v in pairs( res ) do
		rand = math.random( 1, #soundlist )
		v:EmitSound( soundlist[rand], 100, 100 )
		v:Freeze( true )
		v:Lock()
		v:SetColor( Color(0, 100, 255) )
	end
	PAdmin:Notice( player.GetAll(), PAdmin.colors.neutral, ply, PAdmin.colors.good, " froze ", PAdmin.colors.neutral, PAdmin:FormatPlayerTable( res ), "." )
end

unfreeze.run = function( ply, args )
	local res = PAdmin:FindPlayersByName( args[1] )
	for k, v in pairs( res ) do
		v:Freeze( false )
		v:UnLock()
		v:SetColor( Color(255, 255, 255) )
	end
	PAdmin:Notice( player.GetAll(), PAdmin.colors.neutral, ply, PAdmin.colors.error, " unfroze ", PAdmin.colors.neutral, PAdmin:FormatPlayerTable( res ), "." )
end

PAdmin:RegisterCommand( "freeze", freeze )
PAdmin:RegisterCommand( "unfreeze", unfreeze )
