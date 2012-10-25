PAdmin:LoadMsg("Loading lib/genaric_sh.lua")

table.flaten = function( tbl )
	for k,v in pairs( tbl )do
		if( type( v ) == "table" and not ( v.r and v.g and v.b and v.a ) )then
			local nested = v
			-- clear value of current tbl at k
			tbl[ k ] = nil
			table.flaten( nested )
			local c = 0
			for j,l in pairs( nested )do
				if( type( j ) == "number" )then
					-- insert new values into old position
					table.insert( tbl,k + c, l )
					c = c + 1
				else
					tbl[ j ] = l
				end
			end
		end
	end
end

function PAMsgC( ... )
	local arg = { ... }
	local col = Color( 255, 255, 255, 255 )
	for k,v in pairs( arg )do
		if( type( v ) == "table" and ( v.r and v.g and v.b and v.a))then
			col = v
		elseif( type( v ) == "string" )then
			MsgC(col, v )
		elseif( type( v ) == "number" )then
			MsgC(col, tostring( v ) )
		elseif( type( v ) == "Player" )then
			PAMsgC( unpack( PAdmin:FormatPlayerName( v ) ) )
		end
	end
end

if( SERVER )then
	function BuildNotice( ply, ... )
		local arg = { ... }
		if( not arg )then
			print("Notify: arg is nil. Return end")
			return
		end
		table.flaten( arg )
		if( not ply or ( not type( ply ) == "table" and player.IsConsole( ply ) ))then
			table.insert( arg, 1, "PAdmin: " )
			table.insert( arg, "\n" )
			PAMsgC( unpack( arg ) )
			return
		end
		if( type( ply ) == "table" and #ply == #player.GetAll())then
			local arg = table.Copy( arg )
			table.insert( arg, 1, "PAdmin: " )
			table.insert( arg, "\n" )
			PAMsgC( unpack( arg ) )
		end
		return arg
	end
	
	util.AddNetworkString( "PAdmin.ChatPrint" )
	-- both are the same, its just a matter of preference.
	function PAdmin:Notice( ply, ... )
		local tbl = BuildNotice( ply, ... )
		net.Start( "PAdmin.ChatPrint" )
		net.WriteTable( tbl )
		net.Send( ply )
	end
	function PAdmin:Notify( ply, ... )
		PAdmin:Notice( ply, ... )
	end
	function PAdmin:ConMessage( ply, ... )
		local tbl = BuildNotice( ply, ... )
		net.Start( "PAdmin.ConPrint" )
		net.WriteTable( tbl )
		net.Send( ply )
	end
	-- this is just for testing stuff.
	hook.Add("PlayerInitialSpawn","PAdmin.SpawnNotice",function( ply )
		PAdmin:Notice( player.GetAll(), {Color( 100, 100, 100 ),"Player "..ply:Nick().." spawned." } )
	end)
elseif( CLIENT )then
	-- chat brodcasts system.
	net.Receive( "PAdmin.ChatPrint", function( length )
		local tbl  = net.ReadTable()
		local lastCol = Color( 255, 255, 255, 255 )
		for k,v in pairs(tbl)do
			if( type( v ) == "Player" )then
				local ntbl = PAdmin:FormatPlayerName( v )
				ntbl[#ntbl + 1 ] = lastCol
				tbl[ k ] = ntbl
			elseif( type( v ) == "table" and v.r and v.g and v.b and v.a )then
				lastCol = v
			end
		end
		table.flaten( tbl )
		chat.AddText( unpack( tbl ) )
	end )
	
	net.Receive( "PAdmin.ConPrint", function( length )
		local tbl  = net.ReadTable()
		local lastCol = Color( 255, 255, 255, 255 )
		for k,v in pairs(tbl)do
			if( type( v ) == "Player" )then
				local ntbl = PAdmin:FormatPlayerName( v )
				ntbl[#ntbl + 1 ] = lastCol
				tbl[ k ] = ntbl
			elseif( type( v ) == "table" and v.r and v.g and v.b and v.a )then
				lastCol = v
			end
		end
		table.flaten( tbl )
		PAMsgC( unpack( tbl ) )
	end )
end