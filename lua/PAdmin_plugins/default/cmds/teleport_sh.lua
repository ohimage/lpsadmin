local tbl = {}

tbl.format = {}

tbl.perm = "PAdmin.teleport"
tbl.catagory = "Teleportation"


local function TeleportPlayer( ply_calling, ply_target )
	-- if its the same person, just run normally
	if ply_calling == ply_target then 
		tbl.run( ply_calling, "" )
		return
	end
	-- check validity of calling and target players
	if not ply_calling:IsValid() or not ply_target:IsValid() then return end
	if not ply_calling:Alive() or not ply_target:Alive() then return end
	
	local trace = ply_calling:GetEyeTrace()
	local pos = trace.HitPos
	local offset = trace.HitNormal
	offset:Mul(50)
	ply_target:SetPos( pos + offset)
	ply_target:SetLocalVelocity( Vector(0, 0, 0) )
end

local function TeleportSelf( ply )
	local trace = ply:GetEyeTrace()
	local pos = trace.HitPos
	local offset = trace.HitNormal
	offset:Mul(50)
	ply:SetPos( pos + offset)
	ply:SetLocalVelocity( Vector(0, 0, 0) )
end

tbl.run = function( ply, args )
	-- check validity of calling player
	if not ply:IsValid() or not ply:Alive() then return end
	local targetply
	-- if there are arguments, find the player
	if args[1] then
		local players = PAdmin:FindPlayersByName( args[1] )
		if #players > 1 then
			--add error message here.
			return
		end
		targetply = players[1]
		if targetply:IsValid() and targetply:Alive() then
			TeleportPlayer( ply, targetply )
		end
	else
		TeleportSelf( ply )
	end
	
end



PAdmin:RegisterCommand( "teleport", tbl )