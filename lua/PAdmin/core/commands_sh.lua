PAdmin:LoadMsgLN()
PAdmin:LoadMsg( "Loading Commands_sh.lua" )
PAdmin:LoadMsgLN()
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
	commands[ name ] = tbl
end
/*=========================
Command Parsing and Running
=========================*/
if(SERVER)then
	local cmdPrefix = '!'
	-- the actual parsing of the commands
	local function parse( ply, args )
		local cmd = args[1]
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
			local args = PAdmin:ParseCommandString( text )
			parse( ply, args )
			return ""
		end
	end)
end