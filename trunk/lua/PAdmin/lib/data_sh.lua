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

PAdmin:LoadMsgLN()
PAdmin:LoadMsg("Loading Data Library.")

local PAdmin = PAdmin
local sql = sql

function PAdmin:WriteFile( path, data )
	if( not string.find( path, "PAdmin/"))then
		path = "PAdmin/"..path
	end
	if( not string.find( path, ".txt") )then
		path = path .. ".txt"
	end
	print("wrote file at path "..path)
	file.Write( path, data )
end
function PAdmin:ReadFile( path )
	if( not string.find( path, "PAdmin/"))then
		path = "PAdmin/"..path
	end
	if( not string.find( path, ".txt") )then
		path = path .. ".txt"
	end
	return file.Read( path, "DATA" )
end
function PAdmin:CheckDir( path )
	if( not path )then return end
	if( not file.IsDir( path, "DATA" ) )then
		file.CreateDir( path )
	end
end

PAdmin:CheckDir( "PAdmin")

sql.Begin()
	sql.Query( "CREATE TABLE IF NOT EXISTS PAdmin_Users ( id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, uniqueid INT, steamid VARCHAR( 20 ), name VARCHAR( 30 ), groupid INT)" )
	sql.Query( "CREATE TABLE IF NOT EXISTS PAdmin_Bans ( steamid VARCHAR( 30 ), name VARCHAR( 30 ), AdminName VARCHAR( 30 ), UnbanDate INT, reason VARCHAR( 255 ))" )
sql.Commit()

if( SERVER )then
	concommand.Add("PA_DumpDatabases",function( ply, cmd, args )
		if( ( not ValidEntity( ply ) and ply:EntIndex() < 0 ) or ply:IsListenServerHost() )then
			local res = sql.Query( "SELECT * FROM sqlite_master WHERE type='table';" )
			local res2 = {}
			for k,v in pairs( res )do
				if( string.find( v.name, "PAdmin") )then
					table.insert( res2, v )
				end
			end
			PrintTable( res2 )
			res = nil
			res2 = nil
		end
	end)
	
	function PAdmin:LoadUser( ply )
		local result = sql.Query(string.format( "SELECT * FROM PAdmin_Users WHERE uniqueid = %s", sql.SQLStr( ply:UniqueID() ) ) )
		if( result and result[1])then
			PAdmin:LoadMsg("Player has database entry.")
			if( ply:IsListenServerHost())then
				PAdmin:LoadMsg("Making server host Owner rank.")
				sql.Query( string.format( "UPDATE PAdmin_Users SET groupid=%s WHERE uniqueid = %s", sql.SQLStr( 2 ), sql.SQLStr( ply:UniqueID() ) ) )
			end
			result = result[1] -- it returns multiple lines of the database, we only want the first one.
			local groupID = tonumber( result.groupid or "1" )
			ply:SetNWInt("GroupID",groupID)
			ply:SetNWString( "UserGroup", PAdmin:GetGroupByID( groupID ):GetTitle()  )
		else
			PAdmin:LoadMsg("Created DataBase entry for user.")
			local groupID
			if( ply:IsListenServerHost() )then
				groupID = 2
			else
				groupID = 1
			end
			sql.Query( string.format( "INSERT INTO PAdmin_Users ( uniqueid, steamid, name, groupid ) VALUES ( %s, %s, %s, %s )", sql.SQLStr( ply:UniqueID() ), sql.SQLStr( ply:SteamID() ), sql.SQLStr( ply:Name() ), sql.SQLStr( groupID ) ) )
			timer.Simple( 0.5, function()
				PAdmin:LoadUser( ply )
			end)
			return
		end
	end
	
	function PAdmin:SavePlayerGroup( ply )
		PAdmin:LoadMsg("Saved usergroup for "..ply:Nick().." to "..ply:GetUserGroup())
		sql.Query( string.format( "UPDATE PAdmin_Users SET groupid=%s WHERE uniqueid = %s", sql.SQLStr( ply:GetNWInt("GroupID") ), sql.SQLStr( ply:UniqueID() )))
	end
	
	-- this starts the data load.
	hook.Add("PAdmin_PlayerAuthed","PAdminLoadData",function( ply )
		PAdmin:LoadMsgLN()
		PAdmin:LoadMsg("PAdmin Loading User data for "..ply:Nick() )
		PAdmin:LoadUser( ply )
		PAdmin:LoadMsgLN()
		
		PAdmin:LoadMsg("Beginning Group sync.")
		for k,v in pairs( PAdmin:GetAllGroups() )do
			PAdmin:SendGroupData( v, ply )
		end
	end)
	
	-- registers a ban in the table. This is NOT the same as banning a user. It just makes the mod think
	-- that the player is banned.
	-- unban date is a time in minutes
	function PAdmin:SaveBanInfo( steamid, admin_name, UnbanDate, reason )
		UnbanDate = math.Round( UnbanDate )
		if( not ( steamid and UnbanDate ) )then return end
		local name = nil
		local result = sql.QueryValue(string.format( "SELECT name FROM PAdmin_Users WHERE steamid = %s", sql.SQLStr( steamid ) ) )
		if( result )then
			name = result
		else
			name = "<unknown>"
		end
		if( not reason )then
			reason = "Banned by Admin."
		end
		PAdmin:LoadMsgLN()
		PAdmin:LoadMsg("Banning "..name.." steamid "..steamid )
		local query = string.format( "INSERT INTO PAdmin_Bans ( steamid, name, AdminName, UnbanDate, reason ) VALUES ( %s, %s, %s, %s, %s )", sql.SQLStr( steamid ), sql.SQLStr( name ), sql.SQLStr( admin_name ),  sql.SQLStr( UnbanDate ), sql.SQLStr( reason ) )
		PAdmin:LoadMsg( query )
		PAdmin:LoadMsgLN()
		sql.Query( query )
	end
	
	-- this timer will scan the Ban table for expired bans and remove them.
	timer.Create("PAdmin.CheckBans",30, 0, function()
		local res = sql.Query( "SELECT * FROM PAdmin_Bans WHERE UnbanDate != '0' AND UnbanDate <= "..sql.SQLStr( math.Round( os.time() ) ) )
		if( res )then
			PAdmin:LoadMsgLN()
			PAdmin:LoadMsg("Removing expired bans")
			for k,v in pairs( res )do
				PAdmin:LoadMsg( string.format("Removing ban filter on %s uid %s", v[ "name" ], v[ "steamid" ] ) )
				game.ConsoleCommand("removeid "..tostring( v[ "steamid" ] ) )
			end
			PAdmin:LoadMsg("Purging expired ban records.")
			sql.Query( "DELETE FROM PAdmin_Bans WHERE UnbanDate != '0' AND UnbanDate <= "..sql.SQLStr( math.Round( os.time() ) ) )
			PAdmin:LoadMsgLN()
		end
	end)
end

PAdmin:LoadMsgLN()