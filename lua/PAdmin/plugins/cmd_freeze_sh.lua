local tbl = {}
local p = {}

function p:Init()
	PAdmin:RegisterPluginHook( "SetupMove" )
	PAdmin:RegisterPluginHook( "FinishMove" )
	PAdmin:RegisterPluginHook( "Move" )
end


tbl.format = {
	{PAdmin.types.PLY, "target<ply>"}
}

tbl.perm = "PAdmin.freeze"
tbl.permdefault = true

tbl.run = function( ply, args )
	if args[1] then
		local list = PAdmin:FindPlayersByName( args[1] )
		for k, v in pairs( list ) do
			if v:IsValid() then
				if v.frozen then
					if v.frozen == true then
						v:Freeze(false)
						v.frozen = false
					else
						v:Freeze(true)
						v.frozen = true
					end
				else
					v:Freeze(true)
					v.frozen = true
				end
			end
		end
	end
end

PAdmin:RegisterPlugin( "freeze", p )
PAdmin:RegisterCommand( "freeze", tbl )
