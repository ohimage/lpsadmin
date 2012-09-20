-- cmds is a list of things it can be asked to do
-- left off here... not much done yet.
local cmds = {}
local res = sql.Query( "SELECT * FROM sqlite_master WHERE type='table';" )
