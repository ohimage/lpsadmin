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
		You may use calls to PAdmin's libraries if a seperate installation of PAdmin is listed as a requirement.
*/

local groups = PAdmin:GetAllGroups()

local tbl = {}
tbl.format = {
	{PAdmin.types.STRING, "name<str>" },
	{PAdmin.types.STRING, "inheritance<str>", ["optional"] = true }
}
tbl.perm = "PAdmin.rank"
tbl.catagory = "Groups and Ranks"

tbl.run = function( ply, args )
	local NewID = #groups + 1
	local new = PAdmin.Group:New( NewID )
	new:SetTitle( args[1] )	
end
PAdmin:RegisterCommand( "makegroup" , tbl )