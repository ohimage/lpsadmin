function PAdmin:WriteFile( path, data )
	if( not string.find( path, "PAdmin/"))then
		path = "PAdmin/"..path
	end
	if( not string.find( path, ".txt") )then
		path = path .. ".txt"
	end
	file.Write( path, data )
end
function PAdmin:ReadFile( path )
	if( not string.find( path, "PAdmin/"))then
		path = "PAdmin/"..path
	end
	if( not string.find( path, ".txt") )then
		path = path .. ".txt"
	end
	return file.Read( path, "DATA" )
end
function PAdmin:CheckDir( path )
	if( not path )then return end
	if( not file.IsDir( path, "DATA" ) )then
		file.CreateDir( path )
	end
end

PAdmin:CheckDir( "PAdmin")