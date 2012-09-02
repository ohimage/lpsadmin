/*
LPS Admin mod by TheLastPenguin and Trip
This admin mod is created for the needs and use of ||LPS|| Servers
URL: http://lastpenguin.com
It may be reused so long as proper credits are given.
*/
local function clInclude( path )
	"PAdmin/"..path
	if(CLIENT)then
		include( path )
	else
		AddCSLuaFile( path )
	end
end
local function svInclude( path )
	"PAdmin/"..path
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

/*====================================
Includes after this line
====================================*/
-- Libraries First:

-- Things with Dependencies Last
shInclude("core/plugins_sh.lua")