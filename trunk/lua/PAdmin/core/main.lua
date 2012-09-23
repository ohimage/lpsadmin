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
local colBorder = nil
local colText = nil
if(SERVER)then
	colBorder = Color( 0, 0, 255 )
	colText = Color( 0, 155, 255 )
else
	colBorder = Color( 255, 0, 0 )
	colText = Color( 255, 155, 0 )
end
function PAdmin:LoadMsg( msg )
	local len = math.Max( 1, 70 - string.len( msg ) )
	MsgC(colBorder, "||" )
	MsgC(colText, string.format( " %s%"..len.."s ", msg, "" ) )
	MsgC(colBorder, "||\n")
end
function PAdmin:LoadMsgLN( )
	MsgC( colBorder, "||========================================================================||\n" )
end

timer.Simple( 1, function()
	for k,v in pairs(player.GetAll())do
		hook.Call("PlayerSpawn",GM, v)
		hook.Call("PlayerInitialSpawn",GM, v)
		hook.Call("PlayerAuthed",GM, v, v:SteamID(), v:UniqueID())
	end
end)
PAdmin:LoadMsgLN()
MsgC(colText, [[
 ______  __                                       
/\__  _\/\ \                         __           
\/_/\ \/\ \ \___      __    ___ ___ /\_\    ____  
   \ \ \ \ \  _ `\  /'__`\/' __` __`\/\ \  /',__\ 
    \ \ \ \ \ \ \ \/\  __//\ \/\ \/\ \ \ \/\__, `\
     \ \_\ \ \_\ \_\ \____\ \_\ \_\ \_\ \_\/\____/
      \/_/  \/_/\/_/\/____/\/_/\/_/\/_/\/_/\/___/ 
]])
MsgC( colText, [[
 ______      __                             
/\  _  \    /\ \              __            
\ \ \L\ \   \_\ \    ___ ___ /\_\    ___    
 \ \  __ \  /'_` \ /' __` __`\/\ \ /' _ `\  
  \ \ \/\ \/\ \L\ \/\ \/\ \/\ \ \ \/\ \/\ \ 
   \ \_\ \_\ \___,_\ \_\ \_\ \_\ \_\ \_\ \_\
    \/_/\/_/\/__,_ /\/_/\/_/\/_/\/_/\/_/\/_/
]])
PAdmin:LoadMsgLN()
PAdmin:LoadMsg("Loading PAdmin version "..PAdmin.Version..".")
PAdmin:LoadMsg("Mod framework by TheLastPenguin.")
PAdmin:LoadMsg("Mod core plugin set by Trip.")
PAdmin:LoadMsgLN()

/*====================================
Includes after this line
====================================*/

-- Libraries First:
shInclude("config.lua" )
svInclude("lib/sourcebans.lua") -- Ban system. Not by me. Made by source bans team.
shInclude("lib/player_sh.lua") -- genaric stuff library.
shInclude("lib/data_sh.lua") -- data library.
shInclude("lib/string_sh.lua") -- string library.
shInclude("lib/genaric_sh.lua") -- genaric stuff library.

-- Inbetween stuff:
shInclude( "core/permissions_sh.lua" )
shInclude( "core/commands_sh.lua" )
-- Things with Dependencies Last
shInclude("core/plugins_sh.lua")
