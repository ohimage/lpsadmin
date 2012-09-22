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

/*=====================================
Permissions system to check if players can do stuff.
=====================================*/

-- settup data system
PAdmin:CheckDir( "PAdmin/groups")

local groups = {}

local Group = {}
local Group_MT = {}

function PAdmin:GetAllGroups()
	return groups
end

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
function Group_MT:GetID()
	return self._id
end
function Group_MT:SetImmunity( level )
	self._immunity = level
end
function Group_MT:GetImmunity()
	return self._immunity
end
function Group_MT:AddPermission( perm )
	self._permissions[ perm ] = true
	PAdmin:SyncPermission( self:GetID(), perm, true, player.GetAll() )
end
function Group_MT:RemovePermission( perm )
	self._permissions[ perm ] = nil
	PAdmin:SyncPermission( self:GetID(), perm, false, player.GetAll() )
end
function Group_MT:HasPermission( perm )
	return self._permissions[ perm ] == true
end
function Group_MT:GetPermissions()
	return self._permissions
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
	return util.TableToKeyValues( self )
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
	if( not groups[ id ] )then
		local noGroup = Group:New( 0 ) -- this is the group returned if there is none, so it will never be null.
		noGroup:SetTitle( "none" )
		noGroup:SetColor( Color( 255, 255, 255, 255 ) )
		noGroup:SetImmunity( 0 )
		return noGroup
	else
		return groups[ id ]
	end
end

-- loading groups.
if(SERVER)then
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
		PAdmin:LoadMsg("Loaded groups: ")
		PrintTable( groups )
	end
	PAdmin:LoadGroups()
end

function PAdmin:SaveGroups( )
	PAdmin:LoadMsgLN()
	PAdmin:LoadMsg("Saveing Groups.")
	PAdmin:LoadMsgLN()
	local save = {}
	for k,v in pairs( groups )do
		PAdmin:LoadMsg("Saving "..( v:GetTitle() or v:GetID() ))
		table.insert( save, v:ToTable() )
	end
	PAdmin:WriteFile("PAdmin/groups/custom.txt")
	PAdmin:LoadMsgLN()
end

local ply = FindMetaTable( "Player" )
function ply:HasPermission( perm ) -- checking permissions.
	local g = PAdmin:GetGroupByID( self:GetNWInt("GroupID", 1 ) )
	return g:HasPermission( perm ) or g:HasPermission( '*' )
end
function ply:SetUserGroup( val )
	if( type( val ) == "string" )then
		for k,v in pairs( groups )do
			if( v:GetTitle() == val )then
				self:SetNWInt( "GroupID", v:GetID() )
				self:SetNWString("UserGroup", val )
				return
			end
		end
	elseif( type( val ) == "number" )then
		if( groups[ val ] )then
			self:SetNWInt( "GroupID", val )
			self:SetNWString( "UserGroup", groups[ val ]:GetTitle() )
			return 
		end
	end
	--ErrorNoHalt("SetUserGroup invalid group specified!")
end

function ply:GetUserGroup( val )
	return PAdmin:GetGroupByID( self:GetNWInt("GroupID" ) ):GetTitle()
end

-- synching permissions tables.
if(SERVER)then
	util.AddNetworkString( "PAdmin.SendPerm" )
	util.AddNetworkString( "PAdmin.SendGroup" )
	function PAdmin:SyncPermission( groupid, name, value, target)
		net.Start( "PAdmin.SendPerm" )
			net.WriteInt( groupid , 4)
			net.WriteString( name )
			net.WriteBit( value )
		if( target )then
			net.Send( target )
		else
			net.Broadcast()
		end
	end
	function PAdmin:SendGroupData( grouptbl, target )
		net.Start( "PAdmin.SendGroup" )
			net.WriteTable( grouptbl:ToTable() )
		if( target )then
			net.Send( target )
		else
			net.Broadcast()
		end
	end
else
	net.Receive( "PAdmin.SendPerm", function(length)
		local id = net.ReadInt( 4 )
		local name = net.ReadString()
		local value = net.ReadBit()
		PAdmin:LoadMsg("Recieved Perm Update "..name.." = "..value )
		if( value )then
			PAdmin:GetGroupByID( id ):AddPermission( name )
		else
			PAdmin:GetGroupByID( id ):RemovePermission( name )
		end
	end)
	
	net.Receive( "PAdmin.SendGroup", function( length )
		local groupTbl = net.ReadTable()
		print("Recieved group tbl: ")
		PrintTable( groupTbl )
		local group = Group:FromTable( groupTbl )
		PAdmin:RegisterGroup( group:GetID(), group )
	end)
end