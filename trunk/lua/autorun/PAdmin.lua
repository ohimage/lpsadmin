/*
LPS Admin mod by TheLastPenguin and Trip
This admin mod is created for the needs and use of ||LPS|| Servers
URL: http://lastpenguin.com
It may be reused so long as proper credits are given.
*/
PAdmin = {}
PAdmin.Version = "0.1.0"

if(SERVER)then
	AddCSLuaFile("autorun/PAdmin.lua")
	AddCSLuaFile("PAdmin/core/main.lua")
	print(string.format("Loaded LPS Admin mod Version %s.",PAdmin.Version))
else
	chat.AddText(Color(50,50,50),string.format("Loaded LPS Admin mod Version %s.",PAdmin.Version))
end

include("lua/PAdmin/core/main.lua")