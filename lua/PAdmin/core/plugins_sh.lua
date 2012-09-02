/*
LPS Admin mod by TheLastPenguin and Trip
This admin mod is created for the needs and use of ||LPS|| Servers
URL: http://lastpenguin.com
It may be reused so long as proper credits are given.
*/


if(SERVER)then
	local files, directories = file.Find( "PAdmin/plugins/*", "lsv" )
	PrintTable(files)
elseif(CLIENT)then
	
end