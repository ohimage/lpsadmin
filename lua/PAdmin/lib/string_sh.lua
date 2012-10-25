//  ___                             ___        
//   | |_  _ _ . _   /\  _| _ . _    | _ _  _  
//   | | )(-||||_)  /--\(_|||||| )   |(-(_|||| 
//                                                                                                     
/*
	LPS Admin mod by TheLastPenguin
	This admin mod is an opensource Administration tool for Gmod 13.
	URL: lpsadmin.googlecode.com
	Parts of this sourcecode less than 75 lines TOTAL ( not consecutive ) may be used in other projects
		Proper credit must be given to the PAdmin development team in all cases.
		Libraries may be used without credit if you REQUIRE that PAdmin is installed for the project to work. You may NOT copy library files.
*/

local string = string
local table = table

function PAdmin:TimeToMinutes( str )
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
PAdmin.types.PLY = 4
PAdmin.types.NUMBER = 8
PAdmin.types.TIME = 16
PAdmin.types.BOOL = 32
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
		if( name == arg or string.find( string.lower( v:Name() ), string.lower( arg ) ) )then
			return true
		end
	end
	for k,v in pairs( player.GetAll())do 
		if( arg == v:SteamID() )then
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
argTypeChecks[ PAdmin.types.BOOL ] = function( arg )
	if( string.len( arg ) >= 1 )then
		local char = string.lower( arg[1] )
		if( char == 't' or char == 'f' or char == 'y' or char == 'n' )then
			return true
		end
	end
	return false
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
-- ply is the caller and will be excluded.
function PAdmin:FindPlayersByName( name , ply )
	if( not name )then return {} end
	if( name == '*' )then return player.GetAll() end
	local tbl = {}
	for k,v in pairs(player.GetAll())do
		if( string.find( string.lower( v:Nick() ), string.lower( name ) ) or name == v:SteamID())then
			if( not ply or v ~= ply )then
				table.insert( tbl, v )
			end
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


function PAdmin:FormatPlayerName( ply )
	if( player.IsConsole( ply ) )then
		return { PAdmin.colors["console"], "(CONSOLE)" }
	else
		local gtbl = ply:GetUserGroupTbl()
		local prefix = ""
		if( gtbl:GetID() ~= 1 )then
			prefix = "["..ply:GetUserGroup().."]"
		end
		return { ply:GetUserGroupTbl():GetColor(), prefix, team.GetColor( ply:Team() ), ply:Name() }
	end
end

function PAdmin:FormatPlayerTable( tbl )
	res = {}
	if( #tbl == #player.GetAll())then
		table.insert( res, PAdmin.colors.yellow )
		table.insert( res, "(EVERYONE)" )
	else
		for k,v in pairs( tbl )do
			table.insert( res, PAdmin:FormatPlayerName( v ) )
			table.insert( res, ", " )
		end
		table.remove( res, #res )
		table.insert( res, Color( 255, 255, 255, 255 ) )
		table.insert( res, " ("..#tbl.." Players)" )
	end
	return res
end

function PAdmin:ParseCommandString( args )
	if( type( args ) == "table" )then
		args = table.concat( args, " ")
	end
	local tocans = string.Explode( '"', args )
	local res = {}
	for k,v in pairs( tocans )do
		if( k % 2 == 0 )then
			if( string.len( v ) > 0 )then
				table.insert( res, v )
			end
		else
			for m,j in pairs( string.Explode( ' ' , v ) )do
				if( string.len( j ) > 0 )then
					table.insert( res, j )
				end
			end
		end
	end
	return res
end

-- gets the boolean value of the string.
function PAdmin:StringToBoolean( str )
	if( string.len( str ) >= 1 )then
		local char = string.lower( str[1] )
		if( char == 't' or char == 'y' )then
			return true
		end
	end
	return false
end
