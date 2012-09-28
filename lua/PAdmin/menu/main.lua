PAdmin:LoadMsg("Loaded MENU system.")

local menu = nil

local WPercent, HPercent = 0.80, 0.80
local w, h = ScrW() * WPercent, ScrH() * HPercent

local tabs = {}

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

local function LoadTabs( menu )
	local PropertySheet = vgui.Create( "DPropertySheet", menu )
	PropertySheet:SetPos( 15, 30 )
	local pw, ph = w - 30, h - 45
	PropertySheet:SetSize( pw , ph )
	
	for k,v in pairs( tabs )do
		if( v["load"] )then
			local curpanel = vgui.Create( "DPanel", PropertySheet )
			PropertySheet:AddSheet( tostring(k), curpanel, v.icon or "icon16/tux.png", false, false, v["tip"] )
			v["load"]( curpanel, pw, ph )
		else
			ErrorNoHalt("PAdmin: Error! Tab "..k.." has invalid load function!!!")
		end
	end
end

concommand.Add("PA_Menu",function(ply, cmd, args)
	if(LocalPlayer():HasPermission("PAdmin.menu"))then
		if( menu and not args[1])then
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
			LoadTabs(menu)
		end
	else
		chat.AddText(PAdmin.colors.error,"You dont have permission to open the menu.")
	end
end)

function PAdmin:MenuAddTab( name, loadfunc, tooltip )
	local tab = { ["load"] = loadfunc, ["tip"] = tooltip }
	tabs[ name ] = tab
	return tab -- we return it so more properties can be modified.
end

/*
you can add properties to the table like .icon
*/
PAdmin:MenuAddTab("Home",function(panel, w, h)
	local html = vgui.Create("DHTML", panel)
	html:SetPos( 5, 5)
	html:SetSize( w - 10, h - 10 )
	html:OpenURL("http://lastpenguin.com/ThemisAdmin/welcome.html")
end,"Home").icon = "icon16/world.png"
	
PAdmin:MenuAddTab("Credits",function(panel, w, h)
	
end,"Change Log")

function PAdmin:MenuGetTabs()
	return tabs
end