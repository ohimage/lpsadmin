local tbl = {}
tbl.format = {
	{PAdmin.types.PLY, "target<ply>" },
	{PAdmin.types.NUMBER, "HP<num>" }
}
tbl.perm = "PAdmin.hp"
tbl.catagory = "Fun"

tbl.run = function( ply, args )
	local res = PAdmin:FindPlayersByName( args[1] )
	for k,v in pairs( res )do
		v:SetHealth( tonumber( args[2] ) )
		if v:Health() <= 0 then
			v:Kill()
		end
	end
	PAdmin:Notify( player.GetAll(), PAdmin.colors.neutral, ply, " set health for ", PAdmin:FormatPlayerTable( res ) , " to ", args[2] )
end
PAdmin:RegisterCommand( "hp" , tbl )