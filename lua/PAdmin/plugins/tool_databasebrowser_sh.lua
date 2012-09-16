local tbl = {}

tbl.format = {}

tbl.perm = "PAdmin.kick"
tbl.permdefault = true

tbl.run = function( ply, args )
	PAdmin:Notify(player.GetAll(), ply, " opened the SQLite Database browser.")
	
end

PAdmin:RegisterCommand( "MySQLBrowser" , tbl )