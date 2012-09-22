//  ___                             ___        
//   | |_  _ _ . _   /\  _| _ . _    | _ _  _  
//   | | )(-||||_)  /--\(_|||||| )   |(-(_||||

PAdmin:LoadMsgLN()
PAdmin:LoadMsg("Loading SQLite Database Browser.")

if(SERVER)then
	util.AddNetworkString( "SQLiteBrowse.OpenMenu" )
	util.AddNetworkString( "SQLiteBrowse.SendRow" )
	util.AddNetworkString( "SQLiteBrowse.TBLView" )
end

local cmd_open = {}
cmd_open.format = {}
cmd_open.perm = "SQLiteBrowse.OpenMenu"
cmd_open.run = function(ply)
	local dblist = sql.Query( "SELECT * FROM sqlite_master WHERE type='table';" )
	net.Start("SQLiteBrowse.OpenMenu")
		net.WriteTable( dblist )
	net.Send( ply )
	PAdmin:Notify( PAdmin.colors.neutral, ply, " opened the SQLite database browser.")
end

if(SERVER)then -- this command shouldnt be runby clients so we keep it on the server side.
	local cmd_viewtbl = {}
	cmd_viewtbl.format = { {PAdmin.types.STRING, "Table Name<string>"} }
	cmd_viewtbl.perm = "SQLiteBrowse.ViewTable"
	local que = {}
		timer.Create("PAdmin.SendTBLRows",0.1,0,function()
			local count = 0
			while( que[ 1 ])do
				net.Start( "SQLiteBrowse.SendRow" )
					net.WriteTable( que[ 1 ][ 2 ] )
				net.Send( que[ 1 ][ 1 ] )
				table.remove( que, 1 )
				count = count + 1
				if( count >= 20)then
					break
				end
			end
		end)

	cmd_viewtbl.run = function( ply, args )
		local name = args[1]
		if( string.match( name, "[a-zA-Z_.]*") == name)then			
			local dbvals = sql.Query( "SELECT * FROM "..name )
			if( not dbvals )then
				PAdmin:Notify( ply, PAdmin.colors.error, "Inturnal Error. Failed to load table.")
				return
			end
			if( dbvals[1] )then
				net.Start("SQLiteBrowse.TBLView")
					net.WriteTable( dbvals[1] )
				net.Send( ply )
				for k,v in pairs( dbvals )do
					table.insert( que, { ply, v } )
				end
			else
				PAdmin:Notify( ply, PAdmin.colors.error, "Table is emptie!")
			end
		else
			print("Invalid char in name.")
		end
	end
	PAdmin:RegisterCommand( "SQLite_ViewTable" , cmd_viewtbl )
end

if(CLIENT)then
	
	local function MakeDBMenu( tbl )
		-- make the frame.
		local DermaPanel = vgui.Create( "DFrame" )
		DermaPanel:SetPos( ScrW() / 2 - 250, ScrH() / 2 - 185 )
		DermaPanel:SetSize( 500, 390 )
		DermaPanel:SetTitle( "PAdmin: Derma List View" )
		DermaPanel:SetVisible( true )
		DermaPanel:SetDraggable( true )
		DermaPanel:ShowCloseButton( true )
		DermaPanel:MakePopup()
		
		local DBListView = vgui.Create("DListView",DermaPanel)
		
		local ViewTableButton = vgui.Create( "DButton", DermaPanel )
		ViewTableButton:SetSize( 450, 20 )
		ViewTableButton:SetPos( 25, 355 )
		ViewTableButton:SetText( "View Selected Table" )
		ViewTableButton:SetEnabled( false )
		ViewTableButton.DoClick = function( button )
			local line = DBListView:GetSelected()[1]
			print("DBList Name: "..line:GetValue( 1 ) )
			LocalPlayer():ConCommand( "PA SQLite_ViewTable "..line:GetValue( 1 ) )
		end
		
		-- make the list of Tables.
		DBListView:SetPos(25, 50)
		DBListView:SetSize(450, 300)
		DBListView:SetMultiSelect(false)
		DBListView:AddColumn("Name") -- Add column
		DBListView:AddColumn("SQL")
		DBListView:AddColumn("type")
		DBListView.OnRowSelected = function()
			ViewTableButton:SetEnabled( true )
		end
		
		for k,v in pairs(tbl) do
			if( v.tbl_name and v.sql and v.type )then
				DBListView:AddLine(v["tbl_name"],v["sql"],v.type) -- Add lines
			end
		end
	end
	
	net.Receive("SQLiteBrowse.OpenMenu",function( len )
		PAdmin:LoadMsg("Recieved Tbl List:")
		local tbl = net.ReadTable()
		MakeDBMenu( tbl )
	end)
	
	local DBListView
	net.Receive("SQLiteBrowse.SendRow",function( len )
		if( not DBListView )then return end
		local tbl = net.ReadTable()
		local new = {}
		for k,v in pairs(tbl)do
			table.insert( new, tostring( v ) )
		end
		DBListView:AddLine( unpack( new ) )
	end)
	net.Receive("SQLiteBrowse.TBLView",function( len )
		local tbl = net.ReadTable()
		local keys = {}
		for k,v in pairs( tbl )do
			table.insert( keys, k )
		end
		
		-- make the frame.
		local DermaPanel = vgui.Create( "DFrame" )
		DermaPanel:SetPos( 50, 50 )
		DermaPanel:SetSize( ScrW() - 100, ScrH() - 100 )
		DermaPanel:SetTitle( "PAdmin: View Table" )
		DermaPanel:SetVisible( true )
		DermaPanel:SetDraggable( true )
		DermaPanel:ShowCloseButton( true )
		DermaPanel:MakePopup()
		
		DBListView = vgui.Create("DListView",DermaPanel)
		
		-- make the list of Tables.
		DBListView:SetPos(25, 50)
		DBListView:SetSize(ScrW() - 150, ScrH() - 175)
		DBListView:SetMultiSelect(false)
		for k,v in pairs( keys )do
			DBListView:AddColumn( v )
		end
	end)
end

PAdmin:RegisterCommand( "SQLBrowserOpen" , cmd_open )