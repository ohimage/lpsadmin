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

if(CLIENT)then
	concommand.Add("padmin_reload",function( ply )
		if( ply:IsSuperAdmin() )then
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
	local function reload( cl )
		if(cl:IsSuperAdmin() or cl:IsListenServerHost())then
			include("autorun/padmin.lua")
		else
			cl:Kick("PAdmin: Attempting to hack reload system.")
		end
	end
	net.Receive( "PAdmin_ReloadSV", function( length, client )
		reload( client )
	end );
	concommand.Add("PAdmin_reloadSV", reload )
end
function PAdmin:LoadMsg( msg )
	local len = math.Max( 1, 80 - string.len( msg ) )
	MsgN(string.format( "|| %s%"..len.."s ||", msg, "" ) )
end
function PAdmin:LoadMsgLN( )
	MsgN( "||==================================================================================||" )
end

timer.Simple( 1, function()
	for k,v in pairs(player.GetAll())do
		hook.Call("PlayerSpawn",GM, v)
		hook.Call("PlayerInitialSpawn",GM, v)
		hook.Call("PlayerAuthed",GM, v, v:SteamID(), v:UniqueID())
	end
end)

/*====================================
Includes after this line
====================================*/

-- Libraries First:
shInclude( "config.lua" )
shInclude("lib/player_sh.lua") -- genaric stuff library.
shInclude("lib/data_sh.lua") -- data library.
shInclude("lib/string_sh.lua") -- string library.
shInclude("lib/genaric_sh.lua") -- genaric stuff library.

-- Inbetween stuff:
shInclude( "core/permissions_sh.lua" )
shInclude( "core/commands_sh.lua" )
-- Things with Dependencies Last
shInclude("core/plugins_sh.lua")
