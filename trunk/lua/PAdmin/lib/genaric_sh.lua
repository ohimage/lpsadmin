if( SERVER )then
	util.AddNetworkString( "PAdmin.ChatPrint" )
	-- both are the same, its just a matter of preference.
	function PAdmin:Notice( ply, ... )
		if( not ply )then return end
		if( type( ply ) == "player" )then
			print("Ply is a player!")
			if( ply:EntIndex() < 0 )then
				return
			end
		end
		local msg = {}
		for k,v in pairs( arg )do
			if( type( v ) == "table" and not( v.r and v.g and v.b and v.a ))then
				for h, j in pairs( v )do
					table.insert( msg, j )
				end
			else
				table.insert( msg, v )
			end
		end
		net.Start( "PAdmin.ChatPrint" )
		net.WriteTable( msg )
		net.Send( ply )
	end
	function PAdmin:Notify( ply, ... )
		PAdmin:Notice( ply, ... )
	end
	-- this is just for testing stuff.
	hook.Add("PlayerInitialSpawn","PAdmin.SpawnNotice",function( ply )
		PAdmin:Notice( player.GetAll(), {Color( 100, 100, 100 ),"Player "..ply:Nick().." spawned." } )
	end)
elseif( CLIENT )then
	-- chat brodcasts system.
	net.Receive( "PAdmin.ChatPrint", function( length )
		chat.AddText( unpack( net.ReadTable() ) )
	end )
end