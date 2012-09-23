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

local PAdmin = PAdmin
local string = string
local table = table

PAdmin:LoadMsgLN()
PAdmin:LoadMsg( "Loading Commands_sh.lua" )
PAdmin:LoadMsgLN()

local cmdPrefix = '!'

local commands = {}
function PAdmin:RegisterCommand( name, tbl)
	if( not tbl )then
		ErrorNoHalt( "PAdmin: Cmd Register Error no Table Given!")
		return
	end
	if( not tbl.run )then
		ErrorNoHalt( "PAdmin: Cmd Register Error Table has no run property.")
		return
	end
	if( not tbl.format )then
		ErrorNoHalt( "PAdmin: Cmd Register Error Table has no format property.")
		return
	end
	if( not tbl.perm )then
		ErrorNoHalt( "PAdmin: Cmd Register Error Table has no perm property.")
		return
	end
	PAdmin:LoadMsg("Registered Command: "..name)
	name = string.lower( name )
	commands[ name ] = tbl
end
/*=========================
Command Parsing and Running
=========================*/

local function AutoComplete( str )
	local result = {}
	local tocans = PAdmin:ParseCommandString( string.Explode( ' ', string.sub( str, 2 ) ) )
	local cmd = nil
	local help = {}
	if( not tocans[1] )then
		return result
	end
	if( #tocans == 1)then
		local firstArg = tocans[1]
		for k,v in pairs( commands )do
			if( string.find( string.lower( k ), string.lower( firstArg ) ) and LocalPlayer():HasPermission( v.perm ))then
				table.insert( result, k )
			end
		end
		print("Found a command!")
		return result
	end
	cmd = tocans[ 1 ]
	cmd = string.lower( cmd )
	local cmdtbl = commands[ cmd ]
	if( not cmdtbl )then
		return {"<No Such Command>"}
	end
	
	table.insert( help, "!"..cmd )
	for k,v in pairs( cmdtbl.format )do
		table.insert( help, v[2] )
	end
	
	if( commands[ cmd ] and LocalPlayer():HasPermission( commands[ cmd ].perm ) )then
		local args = table.Copy( tocans )
		table.remove( args, 1 )
		local curArg = args[#args]
		if( cmdtbl["AutoComplete_".. #args ] )then -- allows commands to have their own autocomplete generators
			return cmdtbl["AutoComplete_".. #args ]()
		else
			local f = cmdtbl.format[ #args ]
			if( f )then
				if( f[3] and type( f[3] ) == "table")then -- format table can have a suggestions list.
					return f[3]
				else
					if( f[1] == PAdmin.types.PLY )then
						local plys = PAdmin:FindPlayersByName( curArg )
						for k,v in pairs( plys )do
							table.insert( result, v:Name() )
						end
					elseif( f[1] == PAdmin.types.STEAMID )then
						local curArg = string.lower( curArg )
						for k,v in pairs( player.GetAll() )do
							if( string.match( curArg, string.lower( v:SteamID() ) ) )then
								table.insert( result, '"'..v:SteamID()..'"' )
							end
						end
					else
						table.insert( result, f[2] )
					end
				end
			else
				table.insert( result, "<None>")
			end
		end
	else
		table.insert( result, "<None>" )
	end
	if( #result == 0 )then
		result = {"<none>"}
	end
	return result, table.concat( help, " " )
end

local ConCmdParse
if(SERVER)then
	-- the actual parsing of the commands
	local function parse( ply, args )
		local cmd = args[1]
		cmd = string.lower( cmd )
		table.remove( args, 1 )
		if( commands[ cmd ] and args)then -- check its a valid command
			print( string.format("Command %s was found!",cmd ) )
			local cmd = commands[ cmd ]
			if( not ply:HasPermission( cmd.perm ) )then
				PAdmin:Notice( ply, PAdmin.colors.error, string.format("You dont have permission %s.", cmd.perm ))
				return
			end
			if( not ( #args >= #(cmd.format)))then
				PAdmin:Notice( ply, PAdmin.colors.error, "Not enough arguements! Expected "..tostring( #(cmd.format) )," got " .. #args)
				local msg = {}
				table.insert( msg, PAdmin.colors.error )
				table.insert( msg, "Expected: ")
				table.insert( msg, PAdmin.colors.neutral )
				for k,v in pairs(cmd.format)do
					table.insert( msg, v[2])
					table.insert( msg, ", ")
					if( k == #args )then
						table.insert( msg, PAdmin.colors.error )
					end
				end
				table.remove( msg, #msg )
				PAdmin:Notice( ply, msg )
				return 
			end
			for k,v in ipairs( args )do
				if( cmd.format[ k ] )then
					if( not PAdmin:CheckType( v, cmd.format[ k ][1] ) )then
						PAdmin:Notice( ply, PAdmin.colors.error, string.format( "Type Mismatch on arg %d got %s expected type %s", k, v, cmd.format[ k ][2])) 
						return
					end
				else
					break
				end
			end
			local status, errmsg = pcall( cmd.run, ply, args )
			if( not status and errmsg )then
				print(string.format( "PAdmin: Plugin.run failed on command %s. Error Dump: ", cmd))
				PrintTable( args )
				ErrorNoHalt( errmsg )
			end
		else
			PAdmin:Notice( ply, PAdmin.colors.error, string.format("Command %s not found!", cmd ) )
		end
	end
	
	hook.Add("PlayerSay", "PAdmin.c.ChatCmdHook", function( ply, text )
		if( text[1] == cmdPrefix )then
			text = string.sub( text, 2 )
			local args = PAdmin:ParseCommandString(text )
			parse( ply, args )
			return ""
		end
	end)
	function ConCmdParse( ply, arg )
		local args = PAdmin:ParseCommandString( arg )
		parse( ply, args )
	end
	
	util.AddNetworkString( "PAdmin.Command" )
	net.Receive( "PAdmin.Command", function( length, ply )
		if( length < 5000 )then
			ConCmdParse( ply, net.ReadString( ) )
		end
	end)
end

if( CLIENT )then
	local nextRun = 0
	
	local cmd_run = function( ply, cmd, args )
		if( RealTime() >= nextRun )then
			local str = table.concat( args, ' ' )
			if( string.len( str ) > 1000 )then
				chat.AddText(PAdmin.colors.error,"Command is too long. Must be < 1000 charactors.")
				return
			end
			net.Start("PAdmin.Command")
				net.WriteString( str )
			net.SendToServer( )
			nextRun = RealTime() + 1
		else
			nextRun = nextRun + 1
			chat.AddText(PAdmin.colors.warning,"Slow down! Your running commands to fast! Please wait ", nextRun - RealTime()," seconds.")
		end
	end
	
	local cmd_auto = function( cmd, args )
		local options = AutoComplete( args )
		local tocans = PAdmin:ParseCommandString( string.sub( args, 2 ) )
		local result = {}
		local enteredTbl = { cmd }
		for k,v in pairs( tocans )do
			if( k ~= #tocans )then
				if( string.find( v, " " ) )then
					table.insert( enteredTbl, string.format("\"%s\"", v ))
				else
					table.insert( enteredTbl, v )
				end
			end
		end
		local entered = table.concat( enteredTbl, " ")
		for k,v in pairs( options )do
			if( string.find( v, " " ) )then
				table.insert( result, string.format("%s \"%s\"", entered, v ))
			else
				table.insert( result, string.format("%s %s", entered, v ))
			end
		end
		return result
	end
	
	concommand.Add("PA", cmd_run, cmd_auto)
	concommand.Add("PAdmin", cmd_run, cmd_auto)
	
	-- its generally not too pretty but it gets the job done.
	local results = nil
	local delay = 0
	local chatOpen = false
	local help = nil
	hook.Add("ChatTextChanged","PAdmin.AutoComplete",function(str)
		if( delay ~= RealTime() and str and str[1] == cmdPrefix )then
			local options, h = AutoComplete( str )
			help = h
			local tocans = PAdmin:ParseCommandString( string.sub( str, 2 ) )
			local result = {}
			local enteredTbl = { }
			for k,v in pairs( tocans )do
				if( k ~= #tocans )then
					if( string.find( v, " " ) )then
						table.insert( enteredTbl, string.format("\"%s\"", v ))
					else
						table.insert( enteredTbl, string.format("%s", v ))
					end
				end
			end
			local entered = table.concat( enteredTbl, " ")
			for k,v in pairs( options )do
				if( string.find( v, " " ) )then
					table.insert( result, string.format("%s \"%s\"", entered, v ))
				else
					table.insert( result, string.format("%s %s", entered, v ))
				end
			end
			results = result
		else
			if( delay ~= RealTime() )then
				results = nil
			end
		end
	end)
	hook.Add("OnChatTab","PAdmin.ChatTab",function(text)
		if( results and results[1] )then
			local ret = results[1]
			if( results[1][1] == ' ' )then
				ret = "!"..string.sub( results[1], 2 )
			else
				ret = "!"..results[1]
			end
			table.insert( results, results[ 1 ] )
			table.remove( results, 1 )
			delay = RealTime()
			return ret
		end
	end)
	hook.Add("HUDPaint","PAdmin.DrawAutoComplete",function( )
		if( results )then
			local x, y = chat.GetChatBoxPos( )
			local YPos = y - 30 - #results * 18
			local cury
			
			for k,v in ipairs( results )do
				cury = YPos + k * 18
				draw.SimpleText( v, "TargetID", x + 11, cury+1, Color( 0, 0, 0, 155 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
				draw.SimpleText( v, "TargetID", x + 10, cury, Color( 255, 255, 0, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
			end
			if( help )then
				draw.SimpleText( help, "TargetID", x + 11, cury + 18, Color( 0, 0, 0, 155 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
				draw.SimpleText( help, "TargetID", x + 10, cury + 17, Color( 0, 200, 0, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
			end
		end
	end)
	hook.Add("StartChat","PAdmin.ChatOpen",function() chatOpen = true end)
	hook.Add("FinishChat","PAdmin.ChatFinish",function() chatOpen = false end)
end
