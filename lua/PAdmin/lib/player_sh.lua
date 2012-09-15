if(SERVER)then
	-- generally authing players.
	local loading = {}
	local validIDs = {}
	local authedUsers = {}
	-- check if user is authed.
	timer.Create("PAdmin.LoadPlayers", 3, 0, function()
		for k,v in pairs( loading )do
			if( v and ValidEntity( v ) )then
				print("Checking if "..v:Name().." is authed and ready for data.")
				if( string.len( v:Name() ) > 0 and not string.find( v:SteamID() , "PENDING" ))then
					if( validIDs[ v:UniqueID() ] )then
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
	end)
	
	hook.Add("PlayerAuthed","PAdmin.Auth",function( ply, steamid, uniqueid )
		if( ply and ValidEntity( ply ) )then
			print("PAdmin: Recieved SteamID auth for "..ply:Nick()..".")
		end
		validIDs[ uniqueid ] = true
	end)
	
	hook.Add("PlayerConnect","PAdmin.PlayerJoin",function( name, addr )
		PAdmin:Notify( player.GetAll(), PAdmin.colors.neutral, "Player ", PAdmin.colors.player, name, PAdmin.colors.neutral, " connected.")
	end)
	
	local PlyMeta = FindMetaTable( "Player" )
	function PlyMeta:IsAuthed() -- check if the player is authed.
		if( self.PAdmin_Authed )then
			return true
		else
			return false
		end
	end
end