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

-- include statements to make things easier.
local function clInclude( path )
	path = "PAdmin/plugins/"..path
	if(CLIENT)then
		include( path )
	else
		AddCSLuaFile( path )
	end
end
local function svInclude( path )
	path = "PAdmin/plugins/"..path
	if(SERVER)then
		include( path )
	end
end
local function shInclude( path )
	path = "PAdmin/plugins/"..path
	if(SERVER)then
		AddCSLuaFile( path )
	end
	include( path )
end

/*========================
Initial Plugin Loading
========================*/

local p = {}
PAdmin.plugins = p

function PAdmin:GetPlugins()
	return PAdmin.plugins
end
function PAdmin:RegisterPlugin( name, tbl )
	PAdmin.plugins[ name ] = tbl
	PAdmin:LoadMsg("Registered Plugin: "..name )
end


local clfiles = {}
if(SERVER)then
	local svfiles = {}

	PAdmin:LoadMsgLN()
	PAdmin:LoadMsg("Scanning for plugins:")
	PAdmin:LoadMsgLN()
	PAdmin:LoadMsg("Generating List:")
	local function ScanDirectory( dir )
		local count = 0
		-- scan for shared files.
		for k,v in pairs( file.Find( dir.."*_sh.lua", LUA_PATH ) )do
			count = count + 1
			local n = dir..v
			table.insert( svfiles, n )
			table.insert( clfiles, n )
		end
		-- scan for client files.
		for k,v in pairs( file.Find( dir.."*_cl.lua", LUA_PATH ) )do
			count = count + 1
			table.insert( clfiles, dir..v )
		end
		-- scan for server files.
		for k,v in pairs( file.Find( dir.."*_sv.lua", LUA_PATH ) )do
			count = count + 1
			table.insert( svfiles, dir..v )
		end
		PAdmin:LoadMsg( string.format("Scanning Dir %s found %d files.",dir, count ) )
		-- scan for other directories.
		for k,v in pairs( file.FindDir( dir.."*", LUA_PATH ))do
			ScanDirectory( dir..v.."/" )
		end
	end
	ScanDirectory("PAdmin/plugins/")
	
	-- processing serverside files.
	PAdmin:LoadMsgLN()
	PAdmin:LoadMsg("Loading SV Files:")
	for k,v in pairs( svfiles )do
		PAdmin:LoadMsg( string.format("Loading %s on server.", v ) )
		include( v )
	end
	
	-- processing clientside files.
	PAdmin:LoadMsgLN()
	PAdmin:LoadMsg("Adding CL Files to Cache:")
	for k,v in pairs( clfiles )do
		PAdmin:LoadMsg( string.format("Adding %s to CSLuaFile Cache.", v ) )
		AddCSLuaFile( v )
	end
end

/*==========================
Sending Clientside Datapack.
==========================*/

if(SERVER)then
	util.AddNetworkString( "PAdmin.SendCLFileList" )
	hook.Add("PAdmin_PlayerAuthed","PAdmin.SendCLFiles",function( ply )
		PAdmin:LoadMsgLN()
		PAdmin:LoadMsg("Sending Plugin List to "..ply:Name()..".")
		net.Start( "PAdmin.SendCLFileList" )
			net.WriteTable( clfiles )
		net.Send( ply )
	end)
elseif(CLIENT)then
	net.Receive( "PAdmin.SendCLFileList", function(length)
		PAdmin:LoadMsgLN()
		PAdmin:LoadMsg("Recieved Plugin list from Server.")
		PAdmin:LoadMsg("List Data Size is "..length )
		local tbl = net.ReadTable()
		for k,v in pairs( tbl )do
			PAdmin:LoadMsg("Loading Plugin "..v )
			include( v )
		end
		PAdmin:LoadMsgLN()
	end)
end


/*==========================
Other Plugin System Features
==========================*/
PAdmin:LoadMsgLN()
PAdmin:LoadMsg("Loading Plugin Hook System:")
PAdmin:LoadMsgLN()

function PAdmin:CallPluginHook( name, ... )
	name = "Hook_"..name
	for k,v in pairs( p )do
		if( v[name] )then
			local succ, err = pcall( v[name], ... )
			if( not succ )then -- error handler.
				print("PAdmin: Plugin Hook Error on hook "..name.." plugin: "..k.."\n      Error: "..err )
			end
		end
	end
end
local hooks = {}
function PAdmin:RegisterPluginHook( name )
	-- prevent double registering hooks
	if( not table.HasValue( hooks, name ))then table.insert( hooks, name ) else return end
	PAdmin:LoadMsg("Registered hook: PAdminPlug."..name)
	-- add the actual hook
	hook.Add( name, "PAdminPlug."..name, function( ... )
		PAdmin:CallPluginHook( name, ... )
	end)
end

-- register some useful hooks. Plugins can also register ones.
PAdmin:RegisterPluginHook( "PlayerSpawn" )
PAdmin:RegisterPluginHook( "PlayerInitialSpawn" )
PAdmin:RegisterPluginHook( "PlayerSay" )
PAdmin:RegisterPluginHook( "PostDrawOpaqueRenderables" )
PAdmin:RegisterPluginHook( "HUDPaint" )
PAdmin:RegisterPluginHook( "HUDPaintBackground" )
PAdmin:RegisterPluginHook( "PlayerConnect" )
PAdmin:RegisterPluginHook( "PlayerDeath" )


PAdmin:LoadMsgLN()
for k,v in pairs( p )do
	print("Checking plugin "..k)
	if( v.Init )then
		print("Calling init on "..k)
		v:Init()
	end
end

PAdmin:LoadMsg("Done loading plugins.")
PAdmin:LoadMsgLN()