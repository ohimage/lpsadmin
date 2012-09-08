local p = {}

/*
	Name = motd_sh.lua
	Desc. = Displays MOTD and changelog to players via Derma
	TODO = 	Improve the UI,
			Create convar for local or external motd url,
			a TON more
*/
local function buildMotd()
	local w,h = ScrW() - 200, ScrH() - 200
	local MotdPanel = vgui.Create( "DFrame" )  // Create the frame in a local variable
	MotdPanel:SetPos( 100, 100 )               // Set the position to 100, 100 ( x, y )
	MotdPanel:SetSize( w, h )              // Set the size to 300, 200 pixels
	MotdPanel:SetTitle( "||LPS|| Admin MOTD" ) // Set the title
	MotdPanel:SetVisible( true )               // Can you see it? ( Optional - default true )
	MotdPanel:SetDraggable( true )             // Can you move/drag it? ( optional - default true )
	MotdPanel:ShowCloseButton( true )          // Can you see the close button ( reccomended ) ( optional - default true )
	MotdPanel:MakePopup()                    // Make it popup
	MotdPanel:ParentToHUD()
	MotdPanel.Paint = function()
		draw.RoundedBox(4, 0, 0, w, h, Color(0, 155, 155))
		draw.RoundedBox(4, 0, 0, w, 20, Color(0, 100, 100))
		surface.DrawRect(0, 4, w, 18, Color(0, 100, 100)) 
	end
		local Sheet = vgui.Create( "DPropertySheet", MotdPanel )
		local offx, offy = 20, 50
		Sheet:SetPos( offx, offy )
		Sheet:SetSize( w - offx*2, h - offy - offx )
		Sheet.Paint = function()
			draw.RoundedBox(4, 0, 0, w - offx*2, h - offy - offx, Color(0, 0, 0, 80))
		end
		
			local HTMLPanel = vgui.Create( "HTML" )
			--HTMLPanel:SetPos( 10, -50 )
			HTMLPanel:SetSize( w - offx*2 - 20, h - offy - offx - 44)
			HTMLPanel:OpenURL("http://www.garrysmod.com")
		Sheet:AddSheet( "MOTD", HTMLPanel, "gui/silkicons/user", false, true, "Displays the MOTD" )
end

function p:Init()
	print("Called init function.")
	concommand.Add("padmin_buildmotd", buildMotd)
	timer.Simple(2, buildMotd)
end


PAdmin:RegisterPlugin( "motd", p )