//  ___                             ___        
//   | |_  _ _ . _   /\  _| _ . _    | _ _  _  
//   | | )(-||||_)  /--\(_|||||| )   |(-(_|||| 
//                                             
/*
	LPS Admin mod by TheLastPenguin
	This admin mod is an opensource Administration tool for Gmod 13.
	URL: lpsadmin.googlecode.com
	Parts of this sourcecode less than 75 lines TOTAL ( not consecutive ) may be used in other projects
		Proper credit must be given to the PAdmin development team in all cases.
		Libraries may be used without credit if you REQUIRE that PAdmin is installed for the project to work. You may NOT copy library files.
*/


local tbl = {}
tbl.format = {
	{PAdmin.types.PLY, "target<ply>" },
	{PAdmin.types.STRING, "group name<str>" }
}
tbl.perm = "PAdmin.rank"
tbl.permdefault = true
tbl.run = function( ply, args )
	local res = PAdmin:FindPlayerByName( args[1] )
	if(res)then
		if(PAdmin:GetGroupByID( tonumber( args[2] ) ))then
			local val = args[2]
			PAdmin:Notice( player.GetAll(), PAdmin.colors.neutral, ply, " set ", res, "'s rank to ",PAdmin.colors.purple, args[2] )
			if( type( val ) == "string" )then
				for k,v in pairs( PAdmin:GetAllGroups() )do
					if( v:GetTitle() == val )then
						res:SetUserGroup( val )
						PAdmin:SavePlayerGroup( res )
						break
					end
				end
			end
		end
	else
		PAdmin:Notify(ply, PAdmin.colors.error )
	end
end
PAdmin:RegisterCommand( "rank" , tbl )