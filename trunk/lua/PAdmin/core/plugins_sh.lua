/*
LPS Admin mod by TheLastPenguin and Trip
This admin mod is created for the needs and use of ||LPS|| Servers
URL: http://lastpenguin.com
It may be reused so long as proper credits are given.
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

-- find the proper files
local shfiles = file.Find( "PAdmin/plugins/*_sh.lua", "lsv" )
local clfiles = file.Find( "PAdmin/plugins/*_cl.lua", "lsv" )
local svfiles = nil
PAdmin:LoadMsgLN()
PAdmin:LoadMsg( "Loading Plugins: " )
PAdmin:LoadMsgLN()
if(SERVER)then
	svfiles = file.Find( "PAdmin/plugins/*_sv.lua", "lsv" )
	for k,v in pairs( svfiles )do
		PAdmin:LoadMsg( "Plugin: "..v )
		svInclude( v )
	end
end
-- include the files.
for k,v in pairs( shfiles )do
	PAdmin:LoadMsg( "Plugin: "..v )
	shInclude( v )
end
for k,v in pairs( clfiles )do
	PAdmin:LoadMsg( "Plugin: "..v )
	clInclude( v )
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
	if( p.Init )then
		print("Calling init on "..k)
		p:Init()
	end
end