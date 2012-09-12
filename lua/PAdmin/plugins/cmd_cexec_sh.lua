local tbl = {}

tbl.format = {
	{PAdmin.types.PLY, "target<ply>"},
	{PAdmin.types.STRING, "command<string>"}
}

tbl.perm = "PAdmin.cexec"
tbl.permdefault = true

tbl.run = function( ply, args )
	local res = PAdmin:FindPlayersByName( args[1] )
	table.remove( args, 1 )
	command = table.concat( args, " " )
			
	for k,v in pairs( res ) do
		if v:IsValid() then
			v:ConCommand( command )
		end
	end
end

PAdmin:RegisterCommand( "cexec", tbl )