


/*=========================
Command Parsing and Running
=========================*/
local cmdPrefix = '!'
hook.Add("PlayerSay", "PAdmin.c.ChatCmdHook", function( ply, text )
	print("Checking what player said")
	if( text[1] == cmdPrefix )then
		text = string.sub( text, 2 )
		print("Text without ! mark is: ".. text )
		local args = string.Explode( " ", text )
		local cmd = args[1]
		table.remove( args, 1 )
		PrintTable( args )
	else
		
	end
end)