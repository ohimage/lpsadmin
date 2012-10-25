//  ___                             ___
//   | |_  _ _ . _   /\  _| _ . _    | _ _  _
//   | | )(-||||_)  /--\(_|||||| )   |(-(_||||
/*
	LPS Admin mod by TheLastPenguin
	This admin mod is an opensource Administration tool for Gmod 13.
	URL: lpsadmin.googlecode.com
	Parts of this sourcecode less than 75 lines TOTAL ( not consecutive ) may be used in other projects
		Proper credit must be given to the PAdmin development team in all cases.
		Libraries may be used without credit if you REQUIRE that PAdmin is installed for the project to work. You may NOT copy library files.
*/

if(SERVER)then
	
	function PAdmin:PlayerIsBanned( ply )
		if( type( ply ) == "Player" )then ply = ply:SteamID() end
		local banned = sql.Query( "SELECT * FROM PAdmin_Bans WHERE steamid = "..sql.SQLStr( ply))
		if( banned )then
			return banned
		end
		return nil
	end
	
	hook.Add("PlayerInitialSpawn","PAdmin.PlayerInitalise",function(ply)
		PAdmin:LoadMsgLN()
		PAdmin:LoadMsg("Loading user "..ply:Nick()..".")
		PAdmin:LoadMsgLN()
		-- next we set some default values.
		ply:SetNWInt( "GroupID", 1 )
		ply:SetNWString( "UserGroup", "user" )
		hook.Call("PAdmin_PreLoadPlayerData",GAMEMODE,ply)
		PAdmin:LoadUser( ply ) -- defined in data_sh.lua loads from sqlite account.
		hook.Call("PAdmin_LoadPlayerData",GAMEMODE,ply)
		hook.Call("PAdmin_PostPlayerLoaded",GAMEMODE, ply)
	end)
	
	hook.Add("PlayerAuthed","PAdmin.Auth",function( ply, steamid, uniqueid )
	end)
	
	hook.Add("PlayerConnect","PAdmin.PlayerJoin",function( name, addr )
		PAdmin:Notify( player.GetAll(), PAdmin.colors.neutral, "Player ", PAdmin.colors.player, name, PAdmin.colors.neutral, " connected.")
	end)
end

local PlyMeta = FindMetaTable( "Player" )

function PlyMeta:HasPermission( perm )
	local t = self:GetUserGroupTbl()
	return t:HasPermission( perm ) or t:HasPermission( '*' )
end

function PlyMeta:IsSuperAdmin()
	return self:HasPermission( "superadmin" )
end

function PlyMeta:IsAdmin()
	if( self:IsSuperAdmin() )then
		return true
	end
	return self:HasPermission( "admin" )
end

-- this actually bans the player and tells PAdmin they are a banned motherfucker.
-- arguements are the player's uniqueid or entity, time in minutes, reason, admin as entity.
function PAdmin:BanPlayer( ply, time, reason, admin)
	print("banning.")
	local target = nil
	if( type( ply ) == "Player" )then
		target = ply:SteamID()
	end
	if( not reason )then reason = "<none>" end
	print("Called save ban info.")
	PAdmin:SaveBanInfo( target, admin:Name(), os.time() + time * 60, reason )
	for k,v in pairs(player.GetAll())do
		if( v:SteamID() == target )then
			v:Kick("Banned "..reason..".")
		end
	end
	
end

player.IsConsole = function( ply )
	if( ply:IsValid() and ply:EntIndex() ~= 0 )then
		return false
	else
		return true
	end
end