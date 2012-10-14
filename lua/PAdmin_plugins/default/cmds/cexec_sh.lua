local tbl = {}

tbl.format = {
	{PAdmin.types.PLY, "target<ply>"},
	{PAdmin.types.STRING, "command<string>"}
}

tbl.perm = "PAdmin.cexec"
tbl.catagory = "RCON"

tbl.run = function( ply, name, ... )
	local res = PAdmin:FindPlayersByName( args[1] )
	table.remove( args, 1 )
	local command = table.concat( arg, " " )
	--[[Add command filters here]]--
	
	for k,v in pairs( res ) do
		v:ConCommand( command )
	end
end
tbl.AutoComplete = function(Count)
	if( Count == 1 )then
		return {"target<ply>"}
	else
		return {"command"}
	end
end

PAdmin:RegisterCommand( "cexec", tbl )