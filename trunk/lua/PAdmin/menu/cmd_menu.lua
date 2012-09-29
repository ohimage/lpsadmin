PAdmin:MenuAddTab("Commands",function(panel, w, h)
	local cmds = PAdmin:GetAllCommands()
	
	local catlistwidth = w / 5
	
	-- list of commands.
	catagorylist = vgui.Create( "DPanelList", panel )
	catagorylist:SetPos( 5, 5 )
	catagorylist:SetSize( catlistwidth, h - 10 )
	catagorylist:SetSpacing( 5 ) -- Spacing between items
	catagorylist:EnableHorizontal( false ) -- Only vertical items
	catagorylist:EnableVerticalScrollbar( true )
	
	local catagories = {}
	local catnames = {}
	for k,v in pairs(cmds)do
		local curCat = v.catagory or "Unknown"
		if( not table.HasValue( catnames, curCat ) )then
			-- this code is hell... garry broke the Collapsable catagory so i made my own to fix it...
			-- not fun stuff.
			local catagory = vgui.Create("PAdmin_CatagoryCollapse", catagorylist)
			catagory:SetLabel( curCat )
			catagory:SetSize( catlistwidth - 10, 50)
			catagory:SetPadding( 10 )
			catagory:SetExpanded( false )
			catagorylist:AddItem( catagory )
			
			local dlist = vgui.Create( "DPanelList" )
			dlist:SetPos( 25,25 )
			dlist:SetSize( catlistwidth - 10, h / 2 )
			dlist:SetSpacing( 5 ) -- Spacing between items
			dlist:EnableHorizontal( false ) -- Only vertical items
			dlist:EnableVerticalScrollbar( true )
			catagory:SetContents( dlist )
			
			catagories[ curCat ] = dlist
			
			table.insert( catnames, curCat )
		end
	end
	
	for k,v in pairs(cmds)do
		local button = vgui.Create( "DButton" )
		button:SetSize( w, 15 )
		button:SetPos( 50, 30 )
		button:SetText( k )
		button.DoClick = function( button )
			PAdmin:LoadMsg("HI")
		end
		local curCat = v.catagory or "Unknown"
		catagories[ curCat ]:AddItem( button )
	end
	
end,"Run Commands")