local tbl = {}

tbl.format = {}

tbl.perm = "PAdmin.noclip"

-- note. This should be reformated as a plugin that can be loaded and unloaded.
local lastWarned = 0
hook.Add("PlayerNoClip","PAdmin.CanNoclip",function( ply )
	if( ply:GetMoveType() == MOVETYPE_NOCLIP )then return true end -- players can always un noclip.
	if(CLIENT and not ply:HasPermission( "PAdmin.noclip" ) and RealTime() - lastWarned > 5)then
		chat.AddText(PAdmin.colors.error, "You dont have permission 'PAdmin.noclip'")
		lastWarned = RealTime()
	end
	return ply:HasPermission( "PAdmin.noclip" )
end)