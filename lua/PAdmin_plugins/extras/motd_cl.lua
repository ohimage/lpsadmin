local CFG = {}
CFG.URL = "http://lastpenguin.com/"
CFG.time = 15 -- how long they are forced to read the page for.

local w, h = ScrW() * 0.8, ScrH() * 0.8
local Frame = vgui.Create( "DFrame" )
Frame:SetPos((ScrW()-w)/2 , (ScrH()-h)/2)
Frame:SetSize( w, h )
Frame:SetTitle( "PAdmin - MOTD" )
Frame:SetSkin("PAdmin")
Frame:SetVisible( true )
Frame:SetBackgroundBlur( true )
Frame:SetDraggable( false )
Frame:ShowCloseButton( false )
Frame:SetDeleteOnClose( false )
Frame:MakePopup()

WebView = vgui.Create("DHTML",Frame)
WebView:SetHTML("<script> window.location = \""..CFG["URL"].."\" </script>")
WebView:SetPos( 5, 30 )
WebView:SetSize( w-10, h - 70 )

local time = 0

local CloseButton = vgui.Create( "DButton", Frame )
	CloseButton:SetSize( w - 10, 35 )
	CloseButton:SetPos( 5, h - 40 )
	CloseButton:SetText( "Close" )
	CloseButton.DoClick = function( button )
		if( time <= RealTime() )then
			Frame:Close()
		end
	end

concommand.Add("PAdmin_MOTD",function()
	time = RealTime() + CFG.time
	
	hook.Add("Think","UpdateButtonText",function()
		local delay = nil
		if( time <= RealTime())then
			hook.Remove("Think","UpdateButtonText")
			CloseButton:SetText("Close")
			CloseButton:SetEnabled( true )
		else
			CloseButton:SetText("Please wait "..(math.floor( time - RealTime() )+1) .." seconds." )
		end
	end)
end)
LocalPlayer():ConCommand("PAdmin_MOTD")