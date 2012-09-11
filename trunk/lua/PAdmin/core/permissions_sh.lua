/*=====================================
Permissions system to check if players can do stuff.
=====================================*/

-- settup data system
PAdmin:CheckDir( "PAdmin/groups")

local groups = {}
PAdmin:WriteFile("groups/default.txt", glon.encode( {
{["name"] = "owner", ["permissions"] = { "*" } }
}))

local Group = {}
local Group_MT = {}

function Group:New( title )
	local new = {}
	setmetatable( new, Group_MT )
	new.title = title
	new._immunity = 0
	new._permissions = {}
	new._id = RealTime()
	table.insert( groups, new )
	return new
end

function Group_MT:SetTitle( str )
	self._title = str
end
function Group_MT:GetTitle( str )
	return self._title or "none"
end

function Group_MT:SetImmunity( level )
	self._immunity = level
end
function Group_MT:GetImmunity()
	return self._immunity
end
function Group_MT.__eq( op1, op2 ) -- = operation
	return op1._immunity == op2._immunity
end
function Group_MT.__lt( op1, op2 ) -- < operation
	return op1._immunity < op2._immunity
end
function Group_MT.__le( op1, op2 ) -- <= operation
	return op1._immunity <= op2._immunity
end
function Group_MT.__tostring( self )
	local tbl = {"Group:"}
	for k,v in pairs( self )do
		if( type( v ) == "string" or type( v ) == "number" )then
			table.insert(tbl, k.." -- "..v )
		end
	end
	return table.concat( tbl, "\n")
end
function Group_MT:ToTable()
	local tbl = {}
	for k,v in pairs( self )do
		if( k[1] == '_')then
			tbl[string.sub( k, 2 )] = v
		end
	end
	return tbl
end
function Group_MT:SetFromTable( tbl )
	for k,v in pairs( tbl )do
		self[ '_'..k ] = v
	end
end

Group.__index = Group_MT
PAdmin.Group = Group