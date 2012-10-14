local tbl = {}
tbl.format = {
	{PAdmin.types.PLY, "target<ply>" },
	{PAdmin.types.NUMBER, "HP<num>" }
}
tbl.perm = "PAdmin.hp"
tbl.catagory = "Fun"

tbl.run = function( ply, name, num )
	local res = PAdmin:FindPlayersByName( name )
	for k,v in pairs( res )do
		v:SetHealth( tonumber( num ) )
		if v:Health() <= 0 then
			v:Kill()
		end
	end
	PAdmin:Notify( player.GetAll(), PAdmin.colors.neutral, ply, " set health for ", PAdmin:FormatPlayerTable( res ) , " to ", num )
end
PAdmin:RegisterCommand( "hp" , tbl )