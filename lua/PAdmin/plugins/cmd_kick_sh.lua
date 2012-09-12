local tbl = {}

tbl.format = {
	{PAdmin.types.PLY, "target<ply>"}
}

tbl.perm = "PAdmin.kick"
tbl.permdefault = true

tbl.run = function( ply, args )
	local res = PAdmin:FindPlayersByName( args[1] )
	local reason
	for k,v in pairs( res ) do
		if v:IsValid() then
			if #args > 1 then
				reason = ""
				for i,j in pairs( args ) do
					if i > 1 then
						reason = reason..j.." "
					end
				end
				v:Kick(reason)
			else
				v:Kick("Admin Control")
			end
		end
	end
	if not reason then reason = "Admin Control" end
	PAdmin:Notify( player.GetAll(), PAdmin.colors.neutral, ply, PAdmin.colors.good, " kicked ", PAdmin.colors.neutral, PAdmin:FormatPlayerTable( res ), " with reason: ", reason )
end

PAdmin:RegisterCommand( "kick" , tbl )
