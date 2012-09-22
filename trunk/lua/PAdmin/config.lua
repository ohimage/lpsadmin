//  ___                             ___        
//   | |_  _ _ . _   /\  _| _ . _    | _ _  _  
//   | | )(-||||_)  /--\(_|||||| )   |(-(_||||
/*
	LPS Admin mod by TheLastPenguin
	This admin mod is an opensource Administration tool for Gmod 13.
	URL: lpsadmin.googlecode.com
	Parts of this sourcecode less than 75 lines TOTAL ( not consecutive ) may be used in other projects
		Proper credit must be given to the PAdmin development team in all cases.
		Libraries may be used without credit if you REQUIRE that PAdmin is installed for the project to work. You may NOT copy library files.
*/

/*====================================================
| This file contains all PAdmin config variables ect |
====================================================*/
local colors = {}
PAdmin.colors = colors
colors["white"] = Color( 255, 255, 255, 255 )
colors["red"] = Color( 255, 0, 0, 255 )
colors["green"] = Color( 0, 255, 0, 255 )
colors["blue"] = Color( 0, 0, 255, 255 )
colors["yellow"] = Color( 255, 255, 0, 255 )
colors["cyan"] = Color( 0, 255, 255, 255 )
colors["purple"] = Color( 255, 0, 255, 255 )
colors["orange"] = Color( 255, 155, 0, 255 )

colors["player"] = Color( 155, 0, 155, 255 )
colors["neutral"] = Color( 255, 255, 255, 255 )
colors["error"] = colors["red"]
colors["warning"] = colors["yellow"]
colors["good"] = colors["green"]

local schemes = {}
function PAdmin:AddScheme( name, tbl )
	schemes[ name ] = tbl
end

function PAdmin:GetScheme( name )
	return schemes[ name ]
end

PAdmin:AddScheme( "Default",
{
	["lightgray"] = Color( 180,191,190, 255 ),
	["gray"] = Color( 98,115,108, 255 ),
	["darkbrown"] = Color( 64,60,44, 255 ),
	["brown"] = Color( 166,151,124, 255 )
})