local p = {}
PAdmin:RegisterPlugin( "motd", p )

p.PlayerSpawn = function( ply )
	print( ply:Nick() .. " spawned!." )
	asfkd()
end