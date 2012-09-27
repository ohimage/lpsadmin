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
	
	hook.Add("PlayerAuthed","PAdmin.Auth",function( ply, steamid, uniqueid )
		if( ply )then
			print("PAdmin: Recieved SteamID auth for "..ply:Nick()..".")
			local banned = sql.Query( "SELECT * FROM PAdmin_Bans WHERE steamid = "..sql.SQLStr( ply:SteamID()))
			if( banned )then
				PAdmin:LoadMsg("Found user "..ply:Name().." is banned. Applying ban.")
				PrintTable( banned[1] )
				ply:Kick("Banned for "..(banned[1].reason or "Banned by Admin."))
				return
			end
			ply.PAdmin_Authed = { ply:SteamID(), ply:UniqueID() }
			
			if( string.len( ply:Name() ) >= 2 )then
				if( ply.PAdmin_Authed[ 1 ] == ply:SteamID() and ply.PAdmin_Authed[ 2 ] == ply:UniqueID() )then
					PAdmin:LoadMsgLN()
					PAdmin:LoadMsg(string.format("Player %s is authed by PAdmin.", ply:Name()))
					hook.Call("PAdmin_PlayerAuthed",GAMEMODE, ply) -- this is called once user is ready for data and stuff.
					ply:SetNWInt( "GroupID", 1 )
					ply:SetNWString( "UserGroup", "user" )
					ply.PAdmin_Authed = true
				end
			end
			PAdmin:LoadUser( ply )
		else
			ply:Kick("Failed to auth user.")
		end
	end)
	
	hook.Add("PlayerConnect","PAdmin.PlayerJoin",function( name, addr )
		PAdmin:Notify( player.GetAll(), PAdmin.colors.neutral, "Player ", PAdmin.colors.player, name, PAdmin.colors.neutral, " connected.")
	end)
end

local PlyMeta = FindMetaTable( "Player" )
function PlyMeta:IsAuthed() -- check if the player is authed.
	if( CLIENT or self.PAdmin_Authed )then
		return true
	else
		return false
	end
end
-- returns the player's user group meta table.
function PlyMeta:GetUserGroupTbl()
	if( not self )then return nil end
	return PAdmin:GetGroupByID( self:GetNWInt("GroupID", 1) )
end

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
	else
		target = tonumber( ply )
	end
	if( not reason )then reason = "<none>" end
	print("Called save ban info.")
	PAdmin:SaveBanInfo( target, admin:Name(), os.time() + time * 60, reason )
	for k,v in pairs(player.GetAll())do
		if( v:SteamID() == ply:SteamID() )then
			v:Kick("Banned "..reason..".")
		end
	end
end