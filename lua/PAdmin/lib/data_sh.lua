function PAdmin:SaveFile( path, data )
	file.Write( path, util.Compress( data ) )
end
function PAdmin:ReadFile( path )
	return util.Decompress( file.Read( path ) )
end
function PAdmin:CheckDir( path )
	if( not file.IsDir( path ) )then
		file.CreateDir( path )
	end
end

function PAdmin:Encript( str )
	
end