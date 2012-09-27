PAdmin:LoadMsg("Loaded MENU system.")

local menu = nil

local WPercent, HPercent = 0.80, 0.80
local w, h = ScrW() * WPercent, ScrH() * HPercent

local function MakeMenu()
	-- make the frame.
	local DermaPanel = vgui.Create( "DFrame" )
	-- fancy math to center the menu panel.
	DermaPanel:SetPos( w * ( (1 - HPercent ) / 2 ), w * ( (1 - WPercent ) / 2 ))
	DermaPanel:SetSize( w, h )
	DermaPanel:SetTitle( "PAdmin Menu V"..PAdmin.Version )
	DermaPanel:SetVisible( true )
	DermaPanel:SetDraggable( true )
	DermaPanel:ShowCloseButton( true )
	DermaPanel:MakePopup()
	DermaPanel:SetDeleteOnClose( false )
	DermaPanel:SetSkin("PAdmin")
	
	return DermaPanel
end

concommand.Add("PA_Menu",function(ply, cmd, args)
	if(LocalPlayer():HasPermission("PAdmin.menu"))then
		if( args[1] )then
			if( args[1] == 'reload')then
				PAdmin:LoadMsg("Reloading PAdmin menu.")
				menu = MakeMenu()
			elseif( args[1] == '?' or args[1] == '?' )then
				local tbl = {
					["reload"] = "Command to reload the menu."
				}
				print("Command help:")
				PrintTable( tbl )
			end
		elseif( menu )then
			PAdmin:LoadMsgLN()
			PAdmin:LoadMsg("Showing old menu panel.")
			PAdmin:LoadMsgLN()
			menu:SetVisible( true )
			menu:MakePopup()
		else
			PAdmin:LoadMsgLN()
			PAdmin:LoadMsg("First time showing menu.")
			PAdmin:LoadMsg("Generating menu.")
			PAdmin:LoadMsgLN()
			menu = MakeMenu()
		end
	else
		chat.AddText(PAdmin.colors.error,"You dont have permission to open the menu.")
	end
end)