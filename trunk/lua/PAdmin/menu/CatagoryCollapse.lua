/*   _                                
    ( )                               
   _| |   __   _ __   ___ ___     _ _ 
 /'_` | /'__`\( '__)/' _ ` _ `\ /'_` )
( (_| |(  ___/| |   | ( ) ( ) |( (_| |
`\__,_)`\____)(_)   (_) (_) (_)`\__,_) 

	DCategoryCollapse

*/

local PANEL = {}

Derma_Hook( PANEL, "Paint", "Paint", "CategoryHeader" )
Derma_Hook( PANEL, "ApplySchemeSettings", "Scheme", "CategoryHeader" )
Derma_Hook( PANEL, "PerformLayout", "Layout", "CategoryHeader" )

/*---------------------------------------------------------
	Init
---------------------------------------------------------*/
function PANEL:Init()

	self:SetContentAlignment( 4 )
	
end

/*---------------------------------------------------------
	OnMousePressed
---------------------------------------------------------*/
function PANEL:OnMousePressed( mcode )

	if ( mcode == MOUSE_LEFT ) then
		self:GetParent():Toggle()
	return end
	
	return self:GetParent():OnMousePressed( mcode )

end

derma.DefineControl( "DCategoryHeader", "Category Header", PANEL, "DButton" )



local PANEL = {}

AccessorFunc( PANEL, "m_bSizeExpanded", 		"Expanded", 		FORCE_BOOL )
AccessorFunc( PANEL, "m_iContentHeight",	 	"StartHeight" )
AccessorFunc( PANEL, "m_fAnimTime", 			"AnimTime" )
AccessorFunc( PANEL, "m_bDrawBackground", 		"DrawBackground", 	FORCE_BOOL )
AccessorFunc( PANEL, "m_iPadding", 				"Padding" )

/*---------------------------------------------------------
	Init
---------------------------------------------------------*/
function PANEL:Init()

	self.Header = vgui.Create( "DCategoryHeader", self )
	
	
	self:SetExpanded( true )
	self:SetMouseInputEnabled( true )
	
	self:SetAnimTime( 0.2 )
	self.animSlide = Derma_Anim( "Anim", self, self.AnimSlide )
	
	self:SetDrawBackground( true )

end

/*---------------------------------------------------------
   Name: Think
---------------------------------------------------------*/
function PANEL:Think()

	self.animSlide:Run()

end

/*---------------------------------------------------------
	SetLabel
---------------------------------------------------------*/
function PANEL:SetLabel( strLabel )

	self.Header:SetText( strLabel )

end

/*---------------------------------------------------------
	Paint
---------------------------------------------------------*/
function PANEL:Paint()

	derma.SkinHook( "Paint", "PAdmin_CatagoryCollapse", self )
	return false

end

/*---------------------------------------------------------
   Name: ApplySchemeSettings
---------------------------------------------------------*/
function PANEL:ApplySchemeSettings()

	derma.SkinHook( "Scheme", "PAdmin_CatagoryCollapse", self )

end

/*---------------------------------------------------------
   Name: SetContents
---------------------------------------------------------*/
function PANEL:SetContents( pContents )

	self.Contents = pContents
	self.Contents:SetParent( self )
	self:InvalidateLayout()

end

/*---------------------------------------------------------
   Name: Toggle
---------------------------------------------------------*/
function PANEL:Toggle()

	self:SetExpanded( !self:GetExpanded() )

	self.animSlide:Start( self:GetAnimTime(), { From = self:GetTall() } )
	
	self:InvalidateLayout( true )
	self:GetParent():InvalidateLayout()
	self:GetParent():GetParent():InvalidateLayout()
	
	local cookie = '1'
	if ( !self:GetExpanded() ) then cookie = '0' end
	self:SetCookie( "Open", cookie )
	
end

/*---------------------------------------------------------
   Name: PerformLayout
---------------------------------------------------------*/
function PANEL:PerformLayout()

	local Padding = self:GetPadding() or 0

	self.Header:SetPos( 0, 0 )
	self.Header:SetWide( self:GetWide() )
	
	if ( self.Contents ) then
			
		if ( self:GetExpanded() ) then
	
			self.Contents:SetPos( Padding, self.Header:GetTall() + Padding )
			self.Contents:SetWide( self:GetWide() - Padding * 2)	
			
			self.Contents:InvalidateLayout( true )
			
			self.Contents:SetVisible( true )
			self:SetTall( self.Contents:GetTall() + self.Header:GetTall() + Padding * 2 )
		
		else
		
			
			self.Contents:SetVisible( false )
			self:SetTall( self.Header:GetTall() )
		
		end	
		
	end
	
	// Make sure the color of header text is set
	self.Header:ApplySchemeSettings()
	
	self.animSlide:Run()

end

/*---------------------------------------------------------
	OnMousePressed
---------------------------------------------------------*/
function PANEL:OnMousePressed( mcode )

	if ( !self:GetParent().OnMousePressed ) then return end;
	
	return self:GetParent():OnMousePressed( mcode )

end

/*---------------------------------------------------------
   Name: AnimSlide
---------------------------------------------------------*/
function PANEL:AnimSlide( anim, delta, data )
	
	if ( anim.Started ) then
		data.To = self:GetTall()	
	end
	
	if ( anim.Finished ) then
		self:InvalidateLayout()
	return end

	if ( self.Contents ) then self.Contents:SetVisible( true ) end
	
	self:SetTall( Lerp( delta, data.From, data.To ) )
	
	self:GetParent():InvalidateLayout()
	self:GetParent():GetParent():InvalidateLayout()

end

/*---------------------------------------------------------
	LoadCookies
---------------------------------------------------------*/
function PANEL:LoadCookies()

	local Open = self:GetCookieNumber( "Open", 1 ) == 1

	self:SetExpanded( Open )
	self:InvalidateLayout( true )
	self:GetParent():InvalidateLayout()
	self:GetParent():GetParent():InvalidateLayout()

end


/*---------------------------------------------------------
   Name: GenerateExample
---------------------------------------------------------*/
function PANEL:GenerateExample( ClassName, PropertySheet, Width, Height )

	local ctrl = vgui.Create( ClassName )
		ctrl:SetLabel( "Category List Test Category" )
		ctrl:SetSize( 300, 300 )
		ctrl:SetPadding( 10 )
		
		// The contents can be any panel, even a DPanelList
		local Contents = vgui.Create( "DButton" )
		Contents:SetText( "This is the content of the control" )
		ctrl:SetContents( Contents )
		
		ctrl:InvalidateLayout( true )
		
	PropertySheet:AddSheet( ClassName, ctrl, nil, true, true )

end

derma.DefineControl( "PAdmin_CatagoryCollapse", "Collapsable Category Panel", PANEL, "Panel" )