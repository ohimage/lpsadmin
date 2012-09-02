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

-- find the proper files
local shfiles = file.Find( "PAdmin/plugins/*_sh.lua", "lsv" )
local clfiles = file.Find( "PAdmin/plugins/*_cl.lua", "lsv" )
local svfiles = nil
PAdmin:LoadMsg( "Loading Plugins: " )
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