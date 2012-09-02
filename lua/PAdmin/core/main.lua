/*
LPS Admin mod by TheLastPenguin and Trip
This admin mod is created for the needs and use of ||LPS|| Servers
URL: http://lastpenguin.com
It may be reused so long as proper credits are given.
*/
local function clInclude( path )
	path = "PAdmin/"..path
	if(CLIENT)then
		include( path )
	else
		AddCSLuaFile( path )
	end
end
local function svInclude( path )
	path = "PAdmin/"..path
	if(SERVER)then
		include( path )
	end
end
local function shInclude( path )
	path = "PAdmin/"..path
	if(SERVER)then
		AddCSLuaFile( path )
	end
	include( path )
end

<<<<<<< .mine
if(CLIENT)then
	concommand.Add("padmin_reload",function( ply )
		if(ply:IsSuperAdmin())then
			print("PAdmin: Reloading...")
			net.Start( "PAdmin_ReloadSV" )
			net.SendToServer( player.GetAll() )
			include("autorun/PAdmin.lua")
		else
			print("Error: You must be a superadmin to do this.")
		end
	end)
else
	util.AddNetworkString( "PAdmin_ReloadSV" )
	net.Receive( "PAdmin_ReloadSV", function( length, client )
		if(client:IsSuperAdmin())then
			include("autorun/padmin.lua")
		else
			client:Kick("PAdmin: Attempting to hack reload system.")
		end
	end );
end
function PAdmin:LoadMsg( msg )
	local len = math.Max( 1, 80 - string.len( msg ) )
	MsgN(string.format( "|| %s%"..len.."s ||", msg, "" ) )
end
function PAdmin:LoadMsgLN( )
	MsgN( "||==================================================================================||" )
end

=======
if(CLIENT)then
	concommand.Add("padmin_reload",function( ply )
		if(ply:IsSuperAdmin())then
			print("PAdmin: Reloading...")
			net.Start( "PAdmin_ReloadSV" )
			net.SendToServer( player.GetAll() )
			include("autorun/PAdmin.lua")
		else
			print("Error: You must be a superadmin to do this.")
		end
	end)
else
	util.AddNetworkString( "PAdmin_ReloadSV" )
	net.Receive( "PAdmin_ReloadSV", function( length, client )
		if(client:IsSuperAdmin())then
			include("autorun/padmin.lua")
		else
			client:Kick("PAdmin: Attempting to hack reload system.")
		end
	end );
end
function PAdmin:LoadMsg( msg )
	print(string.format( "||%50s||", msg ) )
end

>>>>>>> .r8
/*====================================
Includes after this line
====================================*/
-- Libraries First:

-- Things with Dependencies Last
shInclude("core/plugins_sh.lua")