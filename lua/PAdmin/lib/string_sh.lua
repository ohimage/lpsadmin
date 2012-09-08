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
			time = time + 10080 * tonumber( cur )
			cur = ""
		else
			cur = cur..str[i]
		end
	end
	return time
end
print( "Time Converter test: ".. PAdmin:TimeToMinutes( "1w2d" ) )

/*====================
	Input Validation
====================*/
// Data Types
PAdmin.types = {}
PAdmin.types.STEAMID = 1
PAdmin.types.STRING = 2
PAdmin.types.PLY = 3
PAdmin.types.INT = 4
PAdmin.types.TIME = 5
local argTypeChecks = {}
argTypeChecks[ PAdmin.types.STEAMID ] = function( arg )
	local res = string.match( arg, "STEAM_[0-5]:[0-9]:[0-9]+" )
	if( res )then
		return true
	else
		return false
	end
end
argTypeChecks[ PAdmin.types.STRING ] = function( arg )
	if( type( arg ) == "string" )then
		return true
	else
		return false
	end
end
argTypeChecks[ PAdmin.types.PLY ] = function( arg )
	for k,v in pairs( player.GetAll())do
		if( string.find( v:Nick(), arg ) )then
			return true
		end
	end
	return false
end
argTypeChecks[ PAdmin.types.INT ] = function( arg )
	if( type( arg ) == "number" )then
		return true
	else
		return false
	end
end
argTypeChecks[ PAdmin.types.TIME ] = function( arg )
	local res = string.match( arg , "[0-9wdhm]*" )
	if( res == arg )then
		return true
	else
		return false
	end
end

-- checks the type of the input
function PAdmin:CheckType( arg, TypeID )
	if( argTypeChecks[ TypeID ] )then
		return argTypeChecks[ TypeID ]( arg )
	else
		ErrorNoHalt( "PAdmin: Invalid Arg Type check requested.")
		return false
	end
end