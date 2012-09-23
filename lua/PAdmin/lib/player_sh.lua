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
	-- generally authing players.
	local loading = {}
	local validIDs = {}
	local authedUsers = {}
	-- check if user is authed.
	timer.Create("PAdmin.LoadPlayers", 3, 0, function()
		for k,v in pairs( loading )do
			if( v and v:IsValid() and v:EntIndex() >= 0 )then
				print("Checking if "..v:Name().." is authed and ready for data.")
				if( string.len( v:Name() ) > 0 and not string.find( v:SteamID() , "PENDING" ))then
					if( validIDs[ v:UniqueID() ] or v:IsBot())then
						print("Player is authed and ready.")
						validIDs[ v:UniqueID() ] = nil
						v.PAdmin_Authed = true
						loading[ k ] = nil
						hook.Call("PAdmin_PlayerAuthed",GAMEMODE, v )
					else
						print("Player pending auth.")
					end
				end
			else
				loading[ k ] = nil
			end
		end
	end)
	
	hook.Add("PlayerInitialSpawn","PAdmin.SettupData",function(ply)
		loading[ ply:UserID() ] = ply
		ply:SetNWInt( "GroupID", 1 )
		ply:SetNWString( "UserGroup", "user" )
	end)
	
	hook.Add("PlayerAuthed","PAdmin.Auth",function( ply, steamid, uniqueid )
		if( ply )then
			print("PAdmin: Recieved SteamID auth for "..ply:Nick()..".")
		end
		validIDs[ uniqueid ] = true
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
	if( not ( admin and admin:IsValid() ) )then admin = '(Console' else admin = admin:Name() end
	if( not reason )then reason = "<none>" end
	print("Called save ban info.")
	PAdmin:SaveBanInfo( target, admin, os.time() + time * 60, reason )
	RunConsoleCommand( "banid", "0",target, "1" )
end