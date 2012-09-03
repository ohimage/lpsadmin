PAdmin.types = {}
PAdmin.types.STEAMID = 1
PAdmin.types.STR = 2
PAdmin.types.PLY = 3
PAdmin.types.INT = 4
PAdmin.types.TIME = 4
local argTypeChecks = {}
argTypeChecks[ PAdmin.types.STEAMID ] = function( arg )
	return string.match( arg, "STEAM_[0-5]:[0-9]:[0-9]+" )
end

local function checkType( typeID, arg )
	
end