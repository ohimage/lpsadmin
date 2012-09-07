local p = {}

local function buildMotd()
		local MotdPanel = vgui.Create( "DFrame" )  // Create the frame in a local variable
		MotdPanel:SetPos( 100, 100 )               // Set the position to 100, 100 ( x, y )
		MotdPanel:SetSize( ScrW() - 200, ScrH() - 200 )              // Set the size to 300, 200 pixels
		MotdPanel:SetTitle( "My new Derma frame" ) // Set the title
		MotdPanel:SetVisible( true )               // Can you see it? ( Optional - default true )
		MotdPanel:SetDraggable( true )             // Can you move/drag it? ( optional - default true )
		MotdPanel:ShowCloseButton( true )          // Can you see the close button ( reccomended ) ( optional - default true )
		MotdPanel:MakePopup()                    // Make it popup
		MotdPanel:OpenURL("http://www.garrysmod.com")
end

function p:Init()
	print("Called init function.")
	concommand.Add("padmin_buildmotd", buildMotd)
	timer.Simple(2, buildMotd)
end


PAdmin:RegisterPlugin( "motd", p )