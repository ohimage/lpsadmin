local tbl = {}

tbl.format = {}

tbl.perm = "PAdmin.noclip"
tbl.permdefault = true

hook.Add("PlayerNoClip","PAdmin.CanNoclip",function( ply )
	if( ply:GetMoveType() == MOVETYPE_NOCLIP )then return true end -- players can always un noclip.
	if(CLIENT and not ply:HasPermission( "PAdmin.noclip" ))then
		chat.AddText(PAdmin.colors.error, "You dont have permission 'PAdmin.noclip'")
	end
	return ply:HasPermission( "PAdmin.noclip" )
end)