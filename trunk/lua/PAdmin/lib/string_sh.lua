function PAdmin:ValidSteamID( str )
	return string.match( str, "STEAM_[0-5]:[0-9]:[0-9]+" )
end
function PAdmin:TimeToMinutes(  str )
	local time = 0
	local cur = ""
	for i = 1, string.len( str )do
		if( str[i] == "d" )then
			time = time + 1440 * tonumber( cur )
			cur = ""
		elseif( str[i] == "h" )then
			time = time + 60 * tonumber( cur )
			cur = ""
		elseif( str[i] == "m" )then
			time = time + tonumber( cur )
			cur = ""
		elseif( str[i] == "w" )then
			time = time + 1440 * tonumber( cur )
			cur = ""
		else
			cur = cur..str[i]
		end
	end
end
PAdmin:TimeToSeconds( "1w2d" )