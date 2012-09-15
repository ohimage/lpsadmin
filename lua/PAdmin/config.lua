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