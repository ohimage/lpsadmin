local tbl = {}

tbl.format = {
	{PAdmin.types.PLY, "target<ply>"},
	{PAdmin.types.STRING, "command<string>"}
}

tbl.perm = "PAdmin.cexec"
tbl.permdefault = true

tbl.run = function( ply, args )
	local res = PAdmin:FindPlayersByName( args[1] )
	for k,v in pairs( res ) do
		if v:IsValid() then
			local command = ""
			for i,j in pairs( args ) do
				if i > 1 then
					command = command..j.." "
				end
			end
			command = string.TrimRight( command )
			command = command.."\n"
			print("The command was: \""..command.."\"")
			v:ConCommand( command )
		end
	end
end

PAdmin:RegisterCommand( "cexec", tbl )