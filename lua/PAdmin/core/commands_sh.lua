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
		if( commands[ cmd ] )then -- check its a valid command
			print( string.format("Command %s was found!",cmd ) )
			local cmd = commands[ cmd ]
			if( not ( #args >= #(cmd.format)))then
				PAdmin:Notice( ply, PAdmin.colors.error, "Not enough arguements! Expected "..tostring( #(cmd.format) ))
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
			cmd.run(ply, args )
		else
			PAdmin:Notice( ply, PAdmin.colors.error, string.format("Command %s not found!", cmd ) )
		end
	end
	
	hook.Add("PlayerSay", "PAdmin.c.ChatCmdHook", function( ply, text )
		print("Checking what player said")
		if( text[1] == cmdPrefix )then
			text = string.sub( text, 2 )
			print("Text without ! mark is: ".. text )
			local args = string.Explode( " ", text )
			parse( ply, args )
			return ""
		end
	end)
end