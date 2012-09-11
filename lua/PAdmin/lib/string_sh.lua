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
PAdmin.types.NUMBER = 4
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
	if( arg == '*')then	
		return true
	end
	for k,v in pairs( player.GetAll())do 
		print("Checking ply "..v:Nick().." with "..arg)
		if( string.find( string.lower( v:Nick() ), string.lower( arg ) ) )then
			print("Its a match!")
			return true
		end
	end
	for k,v in pairs( player.GetAll())do 
		if( arg == v:SteamID() )then
			print("Its a match!")
			return true
		end
	end
	return false
end
argTypeChecks[ PAdmin.types.NUMBER ] = function( arg )
	if( string.match( arg, "[0-9.]+") == arg )then
		return true
	else
		return false
	end
end
argTypeChecks[ PAdmin.types.TIME ] = function( arg )
	local res = string.match( arg , "[0-9wdhm]+" )
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

-- find player by Name:
function PAdmin:FindPlayersByName( name )
	if( name == '*' )then return player.GetAll() end
	local tbl = {}
	for k,v in pairs(player.GetAll())do
		if( string.find( string.lower( v:Nick() ), string.lower( name ) ))then
			table.insert( tbl, v )
		end
	end
	return tbl
end
-- this finds a single player, and returns nil if none are found, or if more than one match is found.
function PAdmin:FindPlayerByName( name )
	local res = PAdmin:FindPlayersByName( name )
	if( #res > 0)then
		if( #res == 1 )then
			return res[1]
		else
			return nil, "More Specific."
		end
	else
		return nil, "No Results."
	end
end

function PAdmin:FormatPlayerTable( tbl )
	res = {}
	-- check if its everyone.
	if( #tbl == #player.GetAll())then
		return {PAdmin.colors.cyan, "Everyone"}
	end
	if( #tbl == 1 )then
		table.insert( res, "player ")
	else
		table.insert( res, "players ")
	end
	for k,v in pairs( tbl )do
		table.insert( res, v )
		table.insert( res, ", " )
	end
	table.remove( res, #res )
	if( #res == 1 )then
		table.insert( res, " (1 Player)")
	else
		table.insert( res, string.format(" (%d Players)", #tbl ) )
	end
	return res
end

function PAdmin:ParseCommandString( str )
	local res = {}
	local args = string.Explode( ' ', str )
	local buff = nil
	
	local quotes = false
	for k,v in ipairs( args )do
		if( quotes )then
			buff = buff .. v
			if( v[string.len( v )] == '"' )then
				quotes = false
				local carg = string.gsub(v, '"', '' )
				table.insert( res, carg)
			end
		else
			if( v[1] == '"' and not( v[string.len( v )] == '"' ))then
				quotes = true
				buff = v
			else
				local carg = string.gsub( v, '"', '')
				table.insert( res, carg )
			end
		end
	end
	return res
end