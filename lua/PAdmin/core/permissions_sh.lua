/*=====================================
Permissions system to check if players can do stuff.
=====================================*/

-- settup data system
PAdmin:CheckDir( "PAdmin/groups")

local groups = {}

local Group = {}
local Group_MT = {}

function Group:New( id )
	local new = {}
	setmetatable( new, Group )
	new._title = title
	new._color = Color( 255, 255, 255, 255 )
	new._immunity = 0
	new._permissions = {}
	new._id = id
	return new
end
function PAdmin:RegisterGroup( id, group )
	groups[ id ] = group
end

-- loads a group from table.
function Group:FromTable( tbl )
	local new = {}
	if( not( tbl.id ))then
		print("PAdmin: Group loader error. Group ID is missing.")
		return nil
	end
	setmetatable( new, Group )
	new:SetFromTable( tbl )
	new._id = tbl.id
	groups[ tbl.id ] = new
	return new
end
function Group:MakeUniqueID()
	return math.random( 10000, 99999999 )
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
function Group_MT:AddPermission( perm )
	self._permissions[ perm ] = true 
end
function Group_MT:RemovePermission( perm )
	self._permissions[ perm ] = nil
end
function Group_MT:HasPermission( perm )
	return self._permissions[ perm ] == true
end
function Group_MT:SetColor( col )
	self._color = col
end
function Group_MT:GetColor( col )
	return self._color
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

function PAdmin:GetGroupByID( id )
	return groups[ id ]
end

-- loading groups.
function PAdmin:LoadGroups( )
	PAdmin:LoadMsgLN()
	PAdmin:LoadMsg("Loading Groups:" )
	PAdmin:LoadMsgLN()
	local groupsFile = PAdmin:ReadFile( "groups/custom" )
	if( not groupsFile ) then
		PAdmin:LoadMsg("Custom Groups file not found.")
		if( not groupsFile) then
			local saveData = {}
			local groupOwner = Group:New( 2 )
			groupOwner:SetTitle( "owner" )
			groupOwner:SetColor( Color( 0, 255, 255, 255 ) )
			groupOwner:SetImmunity( 100 )
			groupOwner:AddPermission( "*" )
			table.insert( saveData, groupOwner:ToTable() )
			local groupUser = Group:New( 1 )
			groupUser:SetTitle( "guest" )
			groupUser:SetColor( Color( 200, 200, 200, 255 ) )
			groupUser:SetImmunity( 1 )
			groupUser:AddPermission( "PAdmin.chat" )
			groupUser:AddPermission( "PAdmin.voicechat" )
			table.insert( saveData, groupUser:ToTable() )
			groupsFile = glon.encode( saveData )
			PAdmin:WriteFile( "groups/custom" , groupsFile )
		end
	end
	local allGroups = glon.decode( groupsFile )
	for k,v in pairs( allGroups )do
		PAdmin:LoadMsg("Loaded Group "..(v.title or v.id ))
		local new = Group:FromTable( v )
		PAdmin:RegisterGroup( v.id, new )
	end
	PrintTable( groups )
end
PAdmin:LoadGroups()

for k,v in pairs( player.GetAll())do
	if( v:IsListenServerHost( ) )then
		v:SetNWInt("PAdmin.GroupID", 2 )
	end
end

local ply = FindMetaTable( "Player" )
function ply:HasPermission( perm ) -- checking permissions.
	local g = PAdmin:GetGroupByID( ply:GetNWInt("PAdmin.GroupID") or 1 )
	return g:HasPermission( perm )
end