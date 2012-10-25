 -- Luapad
 -- An in-game scripting environment
 -- by DarKSunrise aka Assassini
 -- Ported to GMod 13 by SparkZ

 table.insert(PAdmin.permissions, "LuaPad" )
 table.insert(PAdmin.permissions, "LuaPad_ServerExicute" )
 
 luapad = {};
 luapad.OpenFiles = {};
 //luapad.GModRoot = string.gsub(string.gsub(util.RelativePathToFull("gameinfo.txt"), "gameinfo.txt", ""), "\\", "/");	--I'm pretty sure we won't need this
 
 luapad.RestrictedFiles = {
 "data/luapad/_server_globals.txt", "data/luapad/_cached_server_globals.txt",
 "addons/Luapad/data/luapad/_server_globals.txt", "addons/Luapad/data/luapad/_cached_server_globals.txt"
 };
 luapad.debugmode = false;
 luapad.forcedownload = false;
 luapad.IgnoreConsoleOpen = true;
 
 if(SERVER) then
 	util.AddNetworkString( "luapad.Upload" )
	util.AddNetworkString( "luapad.UploadCallback" )
	util.AddNetworkString( "luapad.UploadClient" )
	util.AddNetworkString( "luapad.UploadClientCallback" )
	util.AddNetworkString( "luapad.DownloadRunClient" )

	if(luapad.forcedownload) then
		AddCSLuaFile("autorun/luapad.lua");
		AddCSLuaFile("autorun/luapad_editor.lua");
	end
	
	local content = "-- This is an automatically generated cache file for serverside global functions, meta-tables, and enumerations\n-- Don't touch it, or you'll probably mess up your syntax highlighting\n\nluapad._sG = {};\n";
	local endcontent = "";
	
	for k,v in pairs(_G) do
		if(type(v) == "function" or type(v) == "table") then
			if(type(v) == "function") then
				content = content .. "luapad._sG[\"" .. k .. "\"] = \"f\";\n";
			else
				local hasfunc = false;
				for k,v in pairs(v) do
					if(type(v) == "function") then hasfunc = true; break; end
				end
				
				if(hasfunc) then
					content = content .. "luapad._sG[\"" .. k .. "\"] = {};\n";
					for k2,v2 in pairs(v) do
						if(type(v2) == "function") then
							endcontent = endcontent .. "luapad._sG[\"" .. k .. "\"]" .. "[\"" .. k2 .. "\"] = \"f\";\n";
						end
					end
				end
			end
		end
	end
	
	content = content .. endcontent;
	
	local content = content .. "\n\n-- Enumerations\n\n";
	
	for k,v in pairs(_E) do
		if((type(v) != "function" or type(v) != "table") && string.upper(k) == k) then
			content = content .. "luapad._sG[\"" .. k .. "\"] = \"e\";\n";
		end
	end
	
	local content = content .. "\n\n-- Meta-tables\n\n";
	
	for k,v in pairs(_R) do
		if(type(v) == "table") then
			local hasfunc = false;
			for k,v in pairs(v) do
				if(type(v) == "function") then hasfunc = true; break; end
			end
			
			if(hasfunc) then
				for k2,v2 in pairs(v) do
					if(type(v2) == "function" && !string.find(content, "luapad._sG[\"" .. k2 .. "\"] = \"m\";")) then
						content = content .. "luapad._sG[\"" .. k2 .. "\"] = \"m\";\n";
					end
				end
			end
		end
	end
	
	//file.Write("luapad/_server_globals.txt", content);
	
	//resource.AddFile("data/luapad/_server_globals.txt");
	//resource.AddFile("data/luapad/_welcome.txt");
	//resource.AddFile("data/luapad/_about.txt");
	
	/*
	if(luapad.forcedownload) then
		resource.AddFile("materials/icon16/computer.png");
		resource.AddFile("materials/icon16/disk.png");
		resource.AddFile("materials/icon16/disk_multiple.png");
		resource.AddFile("materials/icon16/folder.png");
		resource.AddFile("materials/icon16/folder_page.png");
		resource.AddFile("materials/icon16/page_white.png");
		resource.AddFile("materials/icon16/page_add.png");
		resource.AddFile("materials/icon16/page_delete.png");
		resource.AddFile("materials/icon16/page_white_go.vmt");
		resource.AddFile("materials/icon16/page_white_star.png");
	end
	*/
	function luapad.Upload(len, ply)
		local str = net.ReadString()
		if(str && (ply:IsAdmin() or ply:IsSuperAdmin())) then
			RunString(str);
		end
		net.Start("luapad.UploadCallback")
		net.Send(ply)
	end
	
	net.Receive("luapad.Upload", luapad.Upload);
	
	function luapad.UploadClient(len, ply)
		local str = net.ReadString()
		if(str && (ply:IsAdmin() or ply:IsSuperAdmin())) then
			net.Start("luapad.DownloadRunClient")
				net.WriteString(str)
			net.Send(player.GetAll())
		end
		net.Start("luapad.UploadClientCallback")
		net.Send(ply)
	end
	
	net.Receive("luapad.UploadClient", luapad.UploadClient);
	
	local function AcceptStream(ply, handler, id)
		if(ply:HasPermission("LuaPad_ServerExicute") and (handler == "luapad.Upload" or handler == "luapad.UploadClient")) then return true; end
		if(!ply:IsAdmin()) and (handler == "luapad.Upload" or handler == "luapad.UploadClient") then return false; end
	end
	
	hook.Add("AcceptStream", "luapad.AcceptStream", AcceptStream);

	return;
 end
 
 if (CLIENT) then
	function luapad.DownloadRunClient(len)
		luapad.RunScriptClientFromServer(net.ReadString())
	end
	net.Receive("luapad.DownloadRunClient",luapad.DownloadRunClient)
 end
 
 if(file.Exists("luapad/_server_globals.txt", "DATA")) then
	RunString(file.Read("luapad/_server_globals.txt", "DATA"));
 else
	//RunString(file.Read("luapad/_cached_server_globals.txt", "DATA"));
 end
 
 function luapad.About()
	if(!file.Exists("luapad/_about.txt", "DATA")) then return; end
	luapad.AddTab("_about.txt", file.Read("luapad/_about.txt", "DATA"), "data/luapad/");
 end
 
 function luapad.CheckGlobal(func)
	if(luapad._sG[func] != nil) then if(luapad.debugmode) then print("found " .. func .. " in luapad._sG"); end return luapad._sG[func]; end
	if(_E[func] != nil) then if(luapad.debugmode) then print("found " .. func .. " in _E"); end return _E[func]; end
	if(_G[func] != nil) then if(luapad.debugmode) then print("found " .. func .. " in _G"); end return _G[func]; end
	
	return false;
 end
 
function luapad.OnPlayerQuit() --save my open tabs you bastard!
	local tbl = luapad.OpenFiles or {}
	local savtbl = {}
	for k,v in ipairs(tbl) do
		local strTbl = string.Explode("/",v)
		savtbl[k] = {}
		savtbl[k].name = strTbl[#strTbl]
		savtbl[k].prename = string.Left(v,string.len(v)-string.len(strTbl[#strTbl]))
		savtbl[k].location = "../"..v
	end
	if savtbl and savtbl != {} then
		file.Write("luapad/savedtabs.txt",glon.encode(savtbl))
	end
end

 function luapad.Toggle()
	if( not LocalPlayer():HasPermission("LuaPad"))then
		chat.AddText(PAdmin.colors.error,"You dont have permission LuaPad.")
		return
	end
	if(!luapad.Frame) then


		-- Build it, if it doesn't exist
		luapad.Frame = vgui.Create("DFrame");
		luapad.Frame:SetSize(ScrW() - 40, ScrH() / 1.5);
		luapad.Frame:SetPos(20, 20);
		luapad.Frame:SetTitle("Luapad");
		luapad.Frame:ShowCloseButton(true);
		luapad.Frame:MakePopup();
		luapad.Frame:SetSkin("PAdmin")
		luapad.Frame.btnClose.DoClick = function() luapad.Toggle() luapad.OnPlayerQuit() end		//Thanks Microosoft -SparkZ
		
		luapad.Toolbar = vgui.Create("DPanelList", luapad.Frame);
		luapad.Toolbar:SetPos(3, 26);
		luapad.Toolbar:SetSize(luapad.Frame:GetWide() - 6, 22);
		luapad.Toolbar:SetSpacing(5);
		luapad.Toolbar:EnableHorizontal(true);
		luapad.Toolbar:EnableVerticalScrollbar(false);
		luapad.Toolbar.PerformLayout = function(self) 
			local Wide = self:GetWide();
			local YPos = 3;
			
			if(!self.Rebuild) then debug.Trace(); end 
			
			self:Rebuild();
			
			if(self.VBar && !m_bSizeToContents) then 
				self.VBar:SetPos(self:GetWide() - 16, 0);
				self.VBar:SetSize(16, self:GetTall());
				self.VBar:SetUp(self:GetTall(), self.pnlCanvas:GetTall());
				YPos = self.VBar:GetOffset() + 3;
				if(self.VBar.Enabled) then Wide = Wide - 16; end 
			end 
		   
			self.pnlCanvas:SetPos(3, YPos);
			self.pnlCanvas:SetWide(Wide);
			
			self:Rebuild();
			
			if(self:GetAutoSize()) then 
				self:SetTall(self.pnlCanvas:GetTall());
				self.pnlCanvas:SetPos(3, 3);
			end
		end
		
		local x,y = luapad.Toolbar:GetPos();
		luapad.PropertySheet = vgui.Create("DPropertySheet", luapad.Frame);
		luapad.PropertySheet:SetPos(3, y + luapad.Toolbar:GetTall() + 5);
		luapad.PropertySheet:SetSize(luapad.Frame:GetWide() - 6, luapad.Frame:GetTall() - 82);
		luapad.PropertySheet:SetPadding(1);
		luapad.PropertySheet:SetFadeTime(0);
		luapad.PropertySheet.____SetActiveTab = luapad.PropertySheet.SetActiveTab;
		luapad.PropertySheet.SetActiveTab = function(...)
			luapad.PropertySheet.____SetActiveTab(...);
			
			if(luapad.PropertySheet:GetActiveTab()) then
				local panel = luapad.PropertySheet:GetActiveTab():GetPanel();
				luapad.Frame:SetTitle("Luapad - " .. panel.path .. panel.name);
			end
		end
		luapad.PropertySheet:InvalidateLayout();
		

		if (file.Exists("luapad/savedtabs.txt", "DATA")) then
			for k,v in pairs(glon.decode(file.Read("luapad/savedtabs.txt", "DATA"))) do
				luapad.AddTab(v.name, file.Read(v.location, "DATA"), v.prename)
			end
		elseif(file.Exists("luapad/_welcome.txt", "DATA")) then
			luapad.AddTab("_welcome.txt", file.Read("luapad/_welcome.txt", "DATA"), "data/luapad/");
		else
			luapad.NewTab();
		end
		
		luapad.Statusbar = vgui.Create("DPanelList", luapad.Frame);
		luapad.Statusbar:SetPos(3, luapad.Frame:GetTall() - 25);
		luapad.Statusbar:SetSize(luapad.Frame:GetWide() - 6, 22);
		luapad.Statusbar:SetSpacing(5);
		luapad.Statusbar:EnableHorizontal(true);
		luapad.Statusbar:EnableVerticalScrollbar(false);
		luapad.Statusbar.PerformLayout = luapad.Toolbar.PerformLayout;
		luapad.Statusbar:InvalidateLayout();
		
		luapad.AddToolbarItem("New (CTRL + N)", "icon16/page_add.png", luapad.NewTab);
		luapad.AddToolbarItem("Open (CTRL + O)", "icon16/folder_page.png", luapad.OpenScript);
		luapad.AddToolbarItem("Save (CTRL + S)", "icon16/disk.png", luapad.SaveScript);
		luapad.AddToolbarItem("Save As (CTRL + ALT + S)", "icon16/disk_multiple.png", luapad.SaveAsScript);
		luapad.AddToolbarSpacer()
		luapad.AddToolbarItem("Close tab", "icon16/page_delete.png", luapad.CloseActiveTab);
		luapad.AddToolbarItem("Run script", "icon16/page_white_go.png", function()
			local menu = DermaMenu();
			menu:AddOption("Run clientside", luapad.RunScriptClient);
			menu:AddOption("Run serverside", luapad.RunScriptServer);
			menu:AddOption("Run shared", function() luapad.RunScriptClient(); luapad.RunScriptServer(); end);
			menu:AddOption("Run on all clients", luapad.RunScriptServerClient)
			menu:Open();
		end);
	else
		luapad.Frame:SetVisible(!luapad.Frame:IsVisible());
	end
 end
 
 function luapad.AddToolbarItem(tooltip, mat, func)
	local button = vgui.Create("DImageButton");
	button:SetImage(mat);
	button:SetTooltip(tooltip);
	button:SetSize(16, 16);
	button.DoClick = func;
	
	luapad.Toolbar:AddItem(button);
 end
 
 function luapad.AddToolbarSpacer()
	local lab = vgui.Create("DLabel");
	lab:SetText(" | ");
	lab:SizeToContents();
	
	luapad.Toolbar:AddItem(lab);
 end
 
 function luapad.SetStatus(str, clr)
	timer.Remove("luapad.Statusbar.Fade");
	luapad.Statusbar:Clear();
	
	local msg = vgui.Create("DLabel", luapad.Statusbar);
	msg:SetText(str);
	msg:SetTextColor(clr);
	msg:SizeToContents();
	
	timer.Create("luapad.Statusbar.Fade", 0.01, 0, function(clr)
		local msg = luapad.Statusbar:GetItems()[1];
		local col = msg:GetTextColor();
		col.a = math.Clamp(col.a - 1, 0, 255);
		msg:SetTextColor(Color(col.r, col.g, col.b, col.a));
		
		if(col.a == 0) then timer.Destroy("luapad.Statusbar.Fade"); end
	end);
	
	luapad.Statusbar:AddItem(msg);
	surface.PlaySound("common/wpn_select.wav");
 end
 
 function luapad.AddTab(name, content, path)
	content = content or ""
	path = path or "";
	content = string.gsub(content,"\t","	   ")
	
	local form = vgui.Create("DPanelList", luapad.PropertySheet);
	form:SetSize(luapad.PropertySheet:GetWide(), luapad.PropertySheet:GetTall() - 23);
	form.name = name;
	form.path = path;
 
	 local textentry = vgui.Create("LuapadEditor", form);
	textentry:SetSize(form:GetWide(), form:GetTall())
	textentry:SetText(content or "");
	textentry:RequestFocus();
	
	form:AddItem(textentry);
	
	table.insert(luapad.OpenFiles, path .. name);
	luapad.PropertySheet:AddSheet(name, form, "icon16/page_white.png", false, false);
	luapad.PropertySheet:SetActiveTab(luapad.PropertySheet.Items[table.Count(luapad.PropertySheet.Items)]["Tab"]);
	luapad.PropertySheet:InvalidateLayout();
 end
 
 function luapad.NewTab(content)
	 local n;
	if(type(content) != "string") then content = ""; end --nobody likes nil.
	
	for i = 1, 1000 do
		if(!file.Exists("luapad/untitled" .. i .. ".txt", "DATA") && !table.HasValue(luapad.OpenFiles, "luapad/untitled" .. i .. ".txt")) then
			n = i;
			break;
		end
	end
	
	luapad.AddTab("untitled" .. n .. ".txt", content, "data/luapad/");
 end
 
 function luapad.CloseActiveTab()
	if(table.Count(luapad.PropertySheet.Items) == 1) then return; end
	
	local tabs = {};
	
	for k,v in pairs(luapad.PropertySheet.Items) do
		if(v["Tab"] != luapad.PropertySheet:GetActiveTab()) then
			table.insert(tabs, v["Panel"]);
			v["Tab"]:Remove();
			v["Panel"]:Remove();
		end
	end
	
	luapad.OpenFiles = {};
	luapad.PropertySheet:Remove();
	
	local x,y = luapad.Toolbar:GetPos();
	luapad.PropertySheet = vgui.Create("DPropertySheet", luapad.Frame);
	luapad.PropertySheet:SetPos(3, y + luapad.Toolbar:GetTall() + 5);
	luapad.PropertySheet:SetSize(luapad.Frame:GetWide() - 6, luapad.Frame:GetTall() - 82);
	luapad.PropertySheet:SetPadding(1);
	luapad.PropertySheet:SetFadeTime(0);
	luapad.PropertySheet.____SetActiveTab = luapad.PropertySheet.SetActiveTab;
	luapad.PropertySheet.SetActiveTab = function(...)
		luapad.PropertySheet.____SetActiveTab(...);
		
		if(luapad.PropertySheet:GetActiveTab()) then
			local panel = luapad.PropertySheet:GetActiveTab():GetPanel();
			luapad.Frame:SetTitle("Luapad - " .. panel.path .. panel.name);
		end
	end
	luapad.PropertySheet:InvalidateLayout();
	
	for k,v in pairs(tabs) do 
		luapad.AddTab(v.name, v:GetItems()[1]:GetValue(), v.path);
	end
 end
 
 function luapad.OpenScript()
	if(luapad.OpenTree) then luapad.OpenTree:Remove(); end
	
	local x,y = luapad.PropertySheet:GetPos();
	luapad.OpenTree = vgui.Create("DTree", luapad.Frame);
	luapad.OpenTree:SetPadding(5);
	luapad.OpenTree:SetPos(x + (luapad.PropertySheet:GetWide() - luapad.PropertySheet:GetWide() / 4), y + 22);
	luapad.OpenTree:SetSize(luapad.PropertySheet:GetWide() / 4, luapad.PropertySheet:GetTall() - 23);
	
	luapad.OpenTree.DoClick = function()
		local node = luapad.OpenTree:GetSelectedItem();
		local format = string.Explode(".", node.Label:GetValue())[#string.Explode(".", node.Label:GetValue())];

		if(#string.Explode(".", node.Label:GetValue()) != 1 && (format == "txt")) then
			print(node.Path);
			luapad.AddTab(node.Label:GetValue(), file.Read((string.gsub(node.Path, "data/", "")..node.Label:GetValue()), "DATA"), node.Path);
			luapad.OpenTree:Remove();
		end
	end	
	
	luapad.OpenCloseButton = vgui.Create("DButton", luapad.OpenTree);
	luapad.OpenCloseButton:SetSize(16, 16);
	luapad.OpenCloseButton:SetPos(luapad.OpenTree:GetWide() - 20, 4);
	luapad.OpenCloseButton:SetText("X");
	luapad.OpenCloseButton:SetTooltip("Close");
	luapad.OpenCloseButton.DoClick = function() luapad.OpenTree:Remove(); end
	
	local node = luapad.OpenTree:AddNode("garrysmodbeta\\data"); -- TODO: luapad.CreateFolder() function for this
	node.RootFolder = "data";
	node:MakeFolder("data", "GAME", true);
	node.Icon:SetImage("gui/silkicons/computer");
	
	node.AddNode = function(self, strName)
		self:CreateChildNodes();
		
		local pNode = vgui.Create("DTree_Node", self);
		pNode:SetText(strName);
		pNode:SetParentNode(self); 
		pNode:SetRoot(self:GetRoot()); 
		pNode.AddNode = self.AddNode;
		pNode.Folder = pNode:GetParentNode();
		pNode.Path = "";
		
		local folder = pNode.Folder;
		
		while(folder) do
			if(folder.Label) then
				if (folder.Label:GetValue() != "garrysmodbeta\\data"      &&			--TODO: luapad.CreateFolder() function for this
					folder.Label:GetValue() != "garrysmodbeta\\lua"       && 			
				  	folder.Label:GetValue() != "garrysmodbeta\\addons"    && 
				  	folder.Label:GetValue() != "garrysmodbeta\\gamemodes" &&		--Don't really know what I'm doing here, but it seems to work...
				   	folder.Label:GetValue() != "") 
				then 	
					pNode.Path = folder.Label:GetValue() .. "/" .. pNode.Path;
				end
			else
				break;
			end
			
			folder = folder:GetParentNode();
		end
		
		local ffolder = pNode.Folder;
		local root = self.RootFolder;
		
		while(ffolder && !root) do
			if(ffolder.RootFolder) then
				root = ffolder.RootFolder;
				break;
			end
			
			ffolder = ffolder:GetParentNode();
		end
		
		pNode.Path = root .. "/" .. pNode.Path;

		if(table.HasValue(luapad.RestrictedFiles, pNode.Path .. pNode.Label:GetValue())) then pNode:Remove(); return; end
		
		local format = string.Explode(".", strName)[#string.Explode(".", strName)];
		
		if(format == strName) then
			pNode.Icon:SetImage("icon16/folder.png");
		elseif(format == "txt") then
			pNode.Icon:SetImage("icon16/page_white.png");
		else
			pNode.Icon:SetImage("icon16/page_delete.png");
		end
		
		self.ChildNodes:Add( pNode ) 
		self:InvalidateLayout() 
		return pNode;
	end 
	
	--[[	--Some weird shit is happening with these, so don't really care unless people really need them...
	local node2 = luapad.OpenTree:AddNode("garrysmodbeta\\lua"); -- TODO: luapad.CreateFolder() function for this
	node2.RootFolder = "lua";
	node2:MakeFolder("lua", "GAME", true);
	node2.Icon:SetImage("icon16/folder_page.png");
	node2.AddNode = node.AddNode;
	
	local node2 = luapad.OpenTree:AddNode("garrysmodbeta\\addons"); -- TODO: luapad.CreateFolder() function for this
	node2.RootFolder = "addons";
	node2:MakeFolder("addons", "GAME", true);
	node2.Icon:SetImage("icon16/computer.png");
	node2.AddNode = node.AddNode;
	
	local node2 = luapad.OpenTree:AddNode("garrysmodbeta\\gamemodes"); -- TODO: luapad.CreateFolder() function for this
	node2.RootFolder = "gamemodes";
	node2:MakeFolder("gamemodes", "GAME", true);
	node2.Icon:SetImage("icon16/folder_page.png");
	node2.AddNode = node.AddNode;
	]]
 end

 function luapad.SaveScript()
	local contents = luapad.PropertySheet:GetActiveTab():GetPanel():GetItems()[1]:GetValue() or "";
	contents = string.gsub(contents,"   	","\t")
	local path = string.gsub(luapad.PropertySheet:GetActiveTab():GetPanel().path, "data/", "", 1);
	local a = 0;
	
	print("data/" .. path .. luapad.PropertySheet:GetActiveTab():GetPanel().name);
	
	if(!file.Exists(path .. luapad.PropertySheet:GetActiveTab():GetPanel().name, "DATA")) then
		luapad.SaveAsScript();
	else
		if(table.HasValue(luapad.RestrictedFiles, luapad.PropertySheet:GetActiveTab():GetPanel().path .. luapad.PropertySheet:GetActiveTab():GetPanel().name)) then
			luapad.SetStatus("Save failed! (this file is marked as restricted)", Color(205, 72, 72, 255));
			return;
		end
		
		file.Write(path .. luapad.PropertySheet:GetActiveTab():GetPanel().name, contents);
		
		if file.Exists(path .. luapad.PropertySheet:GetActiveTab():GetPanel().name, "DATA") then
			luapad.SetStatus("File succesfully saved!", Color(72, 205, 72, 255));
		else
			luapad.SetStatus("Save failed! (check your filename for illegal characters)", Color(205, 72, 72, 255));
		end
	end
 end
 
 function luapad.SaveAsScript()
	 Derma_StringRequest("Luapad",  
		"You are about to save a file, please enter the desired filename.",
		luapad.PropertySheet:GetActiveTab():GetPanel().path .. luapad.PropertySheet:GetActiveTab():GetPanel().name,
		
		function(filename)
			if(table.HasValue(luapad.RestrictedFiles, filename)) then
				luapad.SetStatus("Save failed! (this file is marked as restricted)", Color(205, 72, 72, 255));
				return;
			end
			local contents = luapad.PropertySheet:GetActiveTab():GetPanel():GetItems()[1]:GetValue() or "";
			if string.find(filename,"../") == 1 then filename = string.gsub(filename, "../", "",1); end --I really do hate how '.' is a wildcard...

			local dirs = string.Explode("/", string.gsub(filename, "data/", "", 1))
			local d = ""
			for k,v in ipairs(dirs) do
			    if k == #dirs then break end  --don't make a directory for the filename
			    d = (d..v.."/")
			    if !file.IsDir(d, "DATA") then file.CreateDir(d) end
			end

			file.Write(string.gsub(filename, "data/", "",1), contents);
			
			if file.Exists(string.gsub(filename, "data/", "",1), "DATA") then
				luapad.SetStatus("File succesfully saved!", Color(72, 205, 72, 255));
				luapad.PropertySheet:GetActiveTab():GetPanel().name = string.Explode("/", filename)[#string.Explode("/", filename)];
				luapad.PropertySheet:GetActiveTab():GetPanel().path = string.gsub(filename, luapad.PropertySheet:GetActiveTab():GetPanel().name, "",1);
				luapad.PropertySheet:GetActiveTab():SetText(string.Explode("/", filename)[#string.Explode("/", filename)]);
				luapad.PropertySheet:SetActiveTab(luapad.PropertySheet:GetActiveTab());
			else
				luapad.SetStatus("Save failed! (check your filename for illegal characters)", Color(205, 72, 72, 255));
			end
		end,
		
		nil,
		"Save", 
		"Cancel"
	);
 end
 
 function luapad.RunScriptClient()
	local objectDefintions = "local me = player.GetByID("..LocalPlayer():EntIndex()..")\nlocal this = me:GetEyeTrace().Entity\n"
	local did, err = pcall(RunString,objectDefintions..luapad.PropertySheet:GetActiveTab():GetPanel():GetItems()[1]:GetValue())
	if did then 
		luapad.SetStatus("Code ran sucessfully!", Color(72, 205, 72, 255)); 
	else
		luapad.SetStatus(err, Color(205, 72, 72, 255)); 
	end
 end
 
function luapad.RunScriptClientFromServer(script)
	local did, err = pcall(RunString,script)
	if did then 
		luapad.SetStatus("Code ran sucessfully!", Color(92, 205, 92, 255)); 
	else
		luapad.SetStatus(err, Color(205, 92, 92, 255)); 
	end
end
 
function luapad.RunScriptServer()
 
	//if(luapad.UploadID) then luapad.SetStatus("Another upload already in progress!", Color(205, 92, 92, 255)); return; end 
	
	local objectDefintions = "local me = player.GetByID("..LocalPlayer():EntIndex()..")\nlocal this = me:GetEyeTrace().Entity\n"
	local accepted
	net.Receive("luapad.UploadCallback", function() accepted = true end)
	
	net.Start("luapad.Upload")
		net.WriteString(objectDefintions..luapad.PropertySheet:GetActiveTab():GetPanel():GetItems()[1]:GetValue())
	net.SendToServer()
	
	//luapad.UploadID = nil;
	luapad.SetStatus("Upload to server completed! Check server console for possible errors.", Color(92, 205, 92, 255));
	
	if(accepted) then
		luapad.SetStatus("Upload accepted, now uploading..", Color(92, 205, 92, 255));
	else
		luapad.SetStatus("Upload denied by server! This is could be due you not being an admin.", Color(205, 92, 92, 255));
	end

end
 
function luapad.RunScriptServerClient()

	//if(luapad.UploadID) then luapad.SetStatus("Another upload already in progress!", Color(205, 92, 92, 255)); return; end 
	
	local objectDefintions = "local me = player.GetByID("..LocalPlayer():EntIndex()..")\nlocal this = me:GetEyeTrace().Entity\n"
	local accepted
	net.Receive("luapad.UploadClientCallback", function() accepted = true end)
	
	net.Start("luapad.UploadClient")
		net.WriteString(objectDefintions..luapad.PropertySheet:GetActiveTab():GetPanel():GetItems()[1]:GetValue())
	net.SendToServer()
	
	//luapad.UploadID = nil;
	luapad.SetStatus("Upload to client completed!", Color(92, 205, 92, 255));
	
	if(accepted) then
		luapad.SetStatus("Upload accepted, now uploading..", Color(92, 205, 92, 255));
	else
		luapad.SetStatus("Upload denied by server! This is could be due you not being an admin.", Color(205, 92, 92, 255));
	end
	
end
 
concommand.Add("PAdmin_LuaPad", luapad.Toggle);



/*
--Redistributable datastream fix.
if (SERVER) then
	local META = FindMetaTable("CRecipientFilter")
	if META then
		function META:IsValid()
			return true
		end
	else
		ErrorNoHalt(os.date().." Failed to fix datastream fuckup: \"CRecipientFilter\"'s metatable invalid.")
	end
end
*/





 -- Andreas "Syranide" Svensson's editor for Wire Expression 2
 -- edited by DarKSunrise aka Assassini
 -- to work with Luapad and with Lua-syntax
 
 if(SERVER) then return; end
 luapad.EditorPanel = {};

 //Create fonts
 surface.CreateFont("LuapadEditor", {
 	font = "Courier New",
 	size = 16,
 	weight = 400
 })
 surface.CreateFont("LuapadEditor_Bold", {
 	font = "Courier New",
 	size = 16,
 	weight = 800
 })
 //

 function luapad.EditorPanel:Init()
	self:SetCursor("beam");

	surface.SetFont("LuapadEditor");
	self.FontWidth, self.FontHeight = surface.GetTextSize(" ");

	self.Rows = {""};
	self.Caret = {1, 1};
	self.Start = {1, 1};
	self.Scroll = {1, 1};
	self.Size = {1, 1};
	self.Undo = {};
	self.Redo = {};
	self.PaintRows = {};

	self.Blink = RealTime();

	self.ScrollBar = vgui.Create("DVScrollBar", self);
	self.ScrollBar:SetUp(1, 1);
	
	self.TextEntry = vgui.Create("TextEntry", self);
	self.TextEntry:SetMultiline(true);
	self.TextEntry:SetSize(0, 0);
	
	self.TextEntry.OnLoseFocus = function (self) self.Parent:_OnLoseFocus(); end
	self.TextEntry.OnTextChanged = function (self) self.Parent:_OnTextChanged(); end
	self.TextEntry.OnKeyCodeTyped = function (self, code) self.Parent:_OnKeyCodeTyped(code); end
	
	self.TextEntry.Parent = self;
	
	self.LastClick = 0;
 end

 function luapad.EditorPanel:RequestFocus()
	self.TextEntry:RequestFocus();
 end

 function luapad.EditorPanel:OnGetFocus()
	self.TextEntry:RequestFocus();
 end

 function luapad.EditorPanel:CursorToCaret()
	local x, y = self:CursorPos();
	
	x = x - (self.FontWidth * 3 + 6);
	if(x < 0) then x = 0; end
	if(y < 0) then y = 0; end
	
	local line = math.floor(y / self.FontHeight);
	local char = math.floor(x / self.FontWidth + 0.5);
	
	line = line + self.Scroll[1];
	char = char + self.Scroll[2];
	
	if(line > #self.Rows) then line = #self.Rows; end
	local length = string.len(self.Rows[line]);
	if(char > length + 1) then char = length + 1; end
	
	return { line, char };
 end

 function luapad.EditorPanel:OnMousePressed(code)
	if(code == MOUSE_LEFT) then
		if((CurTime() - self.LastClick) < 1 and self.tmp and self:CursorToCaret()[1] == self.Caret[1] and self:CursorToCaret()[2] == self.Caret[2]) then
			self.Start = self:getWordStart(self.Caret)
			self.Caret = self:getWordEnd(self.Caret)
			self.tmp = false
			return
		end
		
		self.tmp = true
		
		self.LastClick = CurTime()
		self:RequestFocus()
		self.Blink = RealTime()
		self.MouseDown = true
		
		self.Caret = self:CursorToCaret()
		if(!input.IsKeyDown(KEY_LSHIFT) and !input.IsKeyDown(KEY_RSHIFT)) then
			self.Start = self:CursorToCaret()
		end
	elseif(code == MOUSE_RIGHT) then
		local menu = DermaMenu()
		
		if(self:CanUndo()) then
			menu:AddOption("Undo",  function()
				self:DoUndo()
			end)
		end
		if(self:CanRedo()) then
			menu:AddOption("Redo",  function()
				self:DoRedo()
			end)
		end
		
		if(self:CanUndo() or self:CanRedo()) then
			menu:AddSpacer()
		end
		
		if(self:HasSelection()) then
			menu:AddOption("Cut",  function()
				if(self:HasSelection()) then
					self.clipboard = self:GetSelection()
					self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
					SetClipboardText(self.clipboard)
					self:SetSelection()
				end
			end)
			menu:AddOption("Copy",  function()
				if(self:HasSelection()) then
					self.clipboard = self:GetSelection()
					self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
					SetClipboardText(self.clipboard)
				end
			end)
		end
		
		menu:AddOption("Paste",  function()
			if(self.clipboard) then
				self:SetSelection(self.clipboard)
			else
				self:SetSelection()
			end
		end)
		
		if(self:HasSelection()) then
			menu:AddOption("Delete",  function()
				self:SetSelection()
			end)
		end
		
		menu:AddSpacer()
		
		menu:AddOption("Select all",  function()
			self:SelectAll()
		end)
		
		menu:Open()
	end
 end

 function luapad.EditorPanel:OnMouseReleased(code)
	if(!self.MouseDown) then return end
	
	if(code == MOUSE_LEFT) then
		self.MouseDown = nil
		if(!self.tmp) then return end
		self.Caret = self:CursorToCaret()
	end
 end

 function luapad.EditorPanel:SetText(text)
	self.Rows = string.Explode("\n", text);
	if(self.Rows[#self.Rows] != "") then
		self.Rows[#self.Rows + 1] = "";
	end
	
	self.Caret = {1, 1};
	self.Start = {1, 1};
	self.Scroll = {1, 1};
	self.Undo = {};
	self.Redo = {};
	self.PaintRows = {};
	
	self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1);
 end

 function luapad.EditorPanel:GetValue()
	return string.Implode("\n", self.Rows)
 end

 function luapad.EditorPanel:NextChar()
	if(!self.char) then return end
	
	self.str = self.str .. self.char
	self.pos = self.pos + 1
	
	if(self.pos <= string.len(self.line)) then
		self.char = string.sub(self.line, self.pos, self.pos)
	else
		self.char = nil
	end
 end
 
 function luapad.EditorPanel:SyntaxColorLine(row)
	local cols = {}
	local lasttable;
	self.line = self.Rows[row]
	self.pos = 0
	self.char = ""
	self.str = ""

	-- TODO: Color customization?
	colors = {
		["none"] =  { Color(0, 0, 0, 255), false},
		["number"] =    { Color(218, 165, 32, 255), false},
		["function"] =  { Color(100, 100, 255, 255), false},
		["enumeration"] =  { Color(184, 134, 11, 255), false},
		["metatable"] =  { Color(140, 100, 90, 255), false},
		["string"] =    { Color(120, 120, 120, 255), false},
		["expression"] =    { Color(0, 0, 255, 255), false},
		["operator"] =  { Color(0, 0, 128, 255), false},
		["comment"] =   { Color(0, 120, 0, 255), false},
	}
	
	colors["string2"] = colors["string"];
	
	self:NextChar();
	
	while self.char do
		token = "";
		self.str = "";
		
		while self.char and self.char == " " do self:NextChar() end
		if(!self.char) then break end
		
		if(self.char >= "0" and self.char <= "9") then
			while self.char and (self.char >= "0" and self.char <= "9" or self.char == "." or self.char == "_") do self:NextChar() end
			
			token = "number"
		elseif(self.char >= "a" and self.char <= "z" or self.char >= "A" and self.char <= "Z") then
			
			while self.char and (self.char >= "a" and self.char <= "z" or self.char >= "A" and self.char <= "Z" or
			self.char >= "0" and self.char <= "9" or self.char == "_") do self:NextChar(); end
			
			local sstr = string.Trim(self.str)
			
			if(sstr == "if" or sstr == "elseif" or sstr == "else" or sstr == "then" or sstr == "end" or sstr == "function"
			or sstr == "do" or sstr == "while" or sstr == "break" or sstr == "for" or sstr == "in" or sstr == "local"
			or sstr == "true" or sstr == "false" or sstr == "nil" or sstr == "NULL" or sstr == "and" or sstr == "not"
			or sstr == "or" or sstr == "||" or sstr == "&&") then
				
				token = "expression"
				
			elseif(luapad.CheckGlobal(sstr) && (type(luapad.CheckGlobal(sstr)) == "function" or luapad.CheckGlobal(sstr) == "f"
			or luapad.CheckGlobal(sstr) == "e" or luapad.CheckGlobal(sstr) == "m" or type(luapad.CheckGlobal(sstr)) == "table")
			or (lasttable && lasttable[sstr])) then -- Could be better code, but what the hell; it works
				
				if(type(luapad.CheckGlobal(sstr)) == "table") then
					lasttable = luapad.CheckGlobal(sstr);
				end
				
				if((luapad.CheckGlobal(sstr) == "e" or _E[sstr]) && sstr == string.upper(sstr)) then
					token = "enumeration";
				elseif(luapad.CheckGlobal(sstr) == "m") then
					token = "metatable";
				else
					token = "function";
				end
				
			else
			
				lasttable = nil;
				token = "none"
				
			end
		elseif(self.char == "\"") then -- TODO: Fix multiline strings, and add support for [[stuff]]!
		
			self:NextChar()
			while self.char and self.char != "\"" do
				if(self.char == "\\") then self:NextChar() end
				self:NextChar()
			end
			self:NextChar()
			
			token = "string"
		elseif(self.char == "'") then
		
			self:NextChar()
			while self.char and self.char != "'" do
				if(self.char == "\\") then self:NextChar() end
				self:NextChar()
			end
			self:NextChar()
			
			token = "string2"
		elseif(self.char == "/" or self.char == "-") then -- TODO: Multiline comments!
		
			local lastchar = self.char;
			self:NextChar()
			
			if(self.char == lastchar) then
				while self.char do
					self:NextChar()
				end
				
				token = "comment"
			else
				token = "none";
			end
			
		else
		
			self:NextChar()
			
			token = "operator"
			
		end
		
		color = colors[token]
		if(#cols > 1 and color == cols[#cols][2]) then
			cols[#cols][1] = cols[#cols][1] .. self.str
		else
			cols[#cols + 1] = {self.str, color}
		end
	end
	
	return cols;
 end

 function luapad.EditorPanel:PaintLine(row)
	if(row > #self.Rows) then return end

	if(!self.PaintRows[row]) then
		self.PaintRows[row] = self:SyntaxColorLine(row)
	end
	
	local width, height = self.FontWidth, self.FontHeight
	
	if(row == self.Caret[1] and self.TextEntry:HasFocus()) then
		surface.SetDrawColor(220, 220, 220, 255)
		surface.DrawRect(width * 3 + 5, (row - self.Scroll[1]) * height, self:GetWide() - (width * 3 + 5), height)
	end
	
	if(self:HasSelection()) then
		local start, stop = self:MakeSelection(self:Selection())
		local line, char = start[1], start[2]
		local endline, endchar = stop[1], stop[2]
		
		surface.SetDrawColor(170, 170, 170, 255)
		local length = string.len(self.Rows[row]) - self.Scroll[2] + 1
		
		char = char - self.Scroll[2]
		endchar = endchar - self.Scroll[2]
		if(char < 0) then char = 0 end
		if(endchar < 0) then endchar = 0 end
		
		if(row == line and line == endline) then
			surface.DrawRect(char * width + width * 3 + 6, (row - self.Scroll[1]) * height, width * (endchar - char), height)
		elseif(row == line) then
			surface.DrawRect(char * width + width * 3 + 6, (row - self.Scroll[1]) * height, width * (length - char + 1), height)
		elseif(row == endline) then
			surface.DrawRect(width * 3 + 6, (row - self.Scroll[1]) * height, width * endchar, height)
		elseif(row > line and row < endline) then
			surface.DrawRect(width * 3 + 6, (row - self.Scroll[1]) * height, width * (length + 1), height)
		end
	end
	
	draw.SimpleText(tostring(row), "LuapadEditor", width * 3, (row - self.Scroll[1]) * height, Color(128, 128, 128, 255), TEXT_ALIGN_RIGHT)
	
	local offset = -self.Scroll[2] + 1
	for i,cell in ipairs(self.PaintRows[row]) do
		if(offset < 0) then
			if(string.len(cell[1]) > -offset) then
				line = string.sub(cell[1], -offset + 1)
				offset = string.len(line)
				
				if(cell[2][2]) then
					draw.SimpleText(line, "LuapadEditorBold", width * 3 + 6, (row - self.Scroll[1]) * height, cell[2][1])
				else
					draw.SimpleText(line, "LuapadEditor", width * 3 + 6, (row - self.Scroll[1]) * height, cell[2][1])
				end
			else
				offset = offset + string.len(cell[1])
			end
		else
			if(cell[2][2]) then
				draw.SimpleText(cell[1], "LuapadEditorBold", offset * width + width * 3 + 6, (row - self.Scroll[1]) * height, cell[2][1])
			else
				draw.SimpleText(cell[1], "LuapadEditor", offset * width + width * 3 + 6, (row - self.Scroll[1]) * height, cell[2][1])
			end
			
			offset = offset + string.len(cell[1])
		end
	end
	
	if(row == self.Caret[1] and self.TextEntry:HasFocus()) then
		if((RealTime() - self.Blink) % 0.8 < 0.4) then
			if(self.Caret[2] - self.Scroll[2] >= 0) then
				surface.SetDrawColor(72, 61, 139, 255)
				surface.DrawRect((self.Caret[2] - self.Scroll[2]) * width + width * 3 + 6, (self.Caret[1] - self.Scroll[1]) * height, 1, height)
			end
		end
	end
 end

 function luapad.EditorPanel:PerformLayout()
	self.ScrollBar:SetSize(16, self:GetTall())
	self.ScrollBar:SetPos(self:GetWide() - 16, 0)
	
	self.Size[1] = math.floor(self:GetTall() / self.FontHeight) - 1
	self.Size[2] = math.floor((self:GetWide() - (self.FontWidth * 3 + 6) - 16) / self.FontWidth) - 1
	
	self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
 end

 function luapad.EditorPanel:Paint(w, h)
	if(!input.IsMouseDown(MOUSE_LEFT)) then
		self:OnMouseReleased(MOUSE_LEFT)
	end

	if(!self.PaintRows) then
		self.PaintRows = {}
	end

	if(self.MouseDown) then
		self.Caret = self:CursorToCaret()
	end
	
	surface.SetDrawColor(200, 200, 200, 255)
	surface.DrawRect(0, 0, self.FontWidth * 3 + 4, self:GetTall())
	
	surface.SetDrawColor(230, 230, 230, 255)
	surface.DrawRect(self.FontWidth * 3 + 5, 0, self:GetWide() - (self.FontWidth * 3 + 5), self:GetTall())
	
	self.Scroll[1] = math.floor(self.ScrollBar:GetScroll() + 1)
	
	for i=self.Scroll[1],self.Scroll[1]+self.Size[1]+1 do
		self:PaintLine(i)
	end
	
	return true
 end
 
 function luapad.EditorPanel:SetCaret(caret)
	self.Caret = self:CopyPosition(caret)
	self.Start = self:CopyPosition(caret)
	self:ScrollCaret()
 end

 function luapad.EditorPanel:CopyPosition(caret)
	return { caret[1], caret[2] }
 end

 function luapad.EditorPanel:MovePosition(caret, offset)
	local caret = { caret[1], caret[2] }

	if(offset > 0) then
		while true do
			local length = string.len(self.Rows[caret[1]]) - caret[2] + 2
			if(offset < length) then
				caret[2] = caret[2] + offset
				break
			elseif(caret[1] == #self.Rows) then
				caret[2] = caret[2] + length - 1
				break
			else
				offset = offset - length
				caret[1] = caret[1] + 1
				caret[2] = 1
			end
		end
	elseif(offset < 0) then
		offset = -offset
		
		while true do
			if(offset < caret[2]) then
				caret[2] = caret[2] - offset
				break
			elseif(caret[1] == 1) then
				caret[2] = 1
				break
			else
				offset = offset - caret[2]
				caret[1] = caret[1] - 1
				caret[2] = string.len(self.Rows[caret[1]]) + 1
			end
		end
	end
	
	return caret
 end

 function luapad.EditorPanel:HasSelection()
	return self.Caret[1] != self.Start[1] || self.Caret[2] != self.Start[2]
 end

 function luapad.EditorPanel:Selection()
	return { { self.Caret[1], self.Caret[2] }, { self.Start[1], self.Start[2] } }
 end

 function luapad.EditorPanel:MakeSelection(selection)
	local start, stop = selection[1], selection[2]

	if(start[1] < stop[1] or start[1] == stop[1] and start[2] < stop[2]) then
		return start, stop
	else
		return stop, start
	end
 end

 function luapad.EditorPanel:GetArea(selection)
	local start, stop = self:MakeSelection(selection)

	if(start[1] == stop[1]) then
		return string.sub(self.Rows[start[1]], start[2], stop[2] - 1)
	else
		local text = string.sub(self.Rows[start[1]], start[2])
		
		for i=start[1]+1,stop[1]-1 do
			text = text .. "\n" .. self.Rows[i]
		end
		
		return text .. "\n" .. string.sub(self.Rows[stop[1]], 1, stop[2] - 1)
	end
 end

 function luapad.EditorPanel:SetArea(selection, text, isundo, isredo, before, after)
	local start, stop = self:MakeSelection(selection)
	
	local buffer = self:GetArea(selection)
	
	if(start[1] != stop[1] or start[2] != stop[2]) then
		-- clear selection
		self.Rows[start[1]] = string.sub(self.Rows[start[1]], 1, start[2] - 1) .. string.sub(self.Rows[stop[1]], stop[2])
		self.PaintRows[start[1]] = false
		
		for i=start[1]+1,stop[1] do
			table.remove(self.Rows, start[1] + 1)
			table.remove(self.PaintRows, start[1] + 1)
			self.PaintRows = {} -- TODO: fix for cache errors
		end
		
		-- add empty row at end of file (TODO!)
		if(self.Rows[#self.Rows] != "") then
			self.Rows[#self.Rows + 1] = ""
			self.PaintRows[#self.Rows + 1] = false
		end
	end
	
	if(!text or text == "") then
		self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
		
		self.PaintRows = {}
	
		self:OnTextChanged()
	
		if(isredo) then
			self.Undo[#self.Undo + 1] = { { self:CopyPosition(start), self:CopyPosition(start) }, buffer, after, before }
			return before
		elseif(isundo) then
			self.Redo[#self.Redo + 1] = { { self:CopyPosition(start), self:CopyPosition(start) }, buffer, after, before }
			return before
		else
			self.Redo = {}
			self.Undo[#self.Undo + 1] = { { self:CopyPosition(start), self:CopyPosition(start) }, buffer, self:CopyPosition(selection[1]), self:CopyPosition(start) }
			return start
		end
	end
	
	-- insert text
	local rows = string.Explode("\n", text)
	
	local remainder = string.sub(self.Rows[start[1]], start[2])
	self.Rows[start[1]] = string.sub(self.Rows[start[1]], 1, start[2] - 1) .. rows[1]
	self.PaintRows[start[1]] = false
	
	for i=2,#rows do
		table.insert(self.Rows, start[1] + i - 1, rows[i])
		table.insert(self.PaintRows, start[1] + i - 1, false)
		self.PaintRows = {} // TODO: fix for cache errors
	end

	local stop = { start[1] + #rows - 1, string.len(self.Rows[start[1] + #rows - 1]) + 1 }
	
	self.Rows[stop[1]] = self.Rows[stop[1]] .. remainder
	self.PaintRows[stop[1]] = false
	
	-- add empty row at end of file (TODO!)
	if(self.Rows[#self.Rows] != "") then
		self.Rows[#self.Rows + 1] = ""
		self.PaintRows[#self.Rows + 1] = false
		self.PaintRows = {} // TODO: fix for cache errors
	end
	
	self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
	
	self.PaintRows = {}
	
	self:OnTextChanged()
	
	if(isredo) then
		self.Undo[#self.Undo + 1] = { { self:CopyPosition(start), self:CopyPosition(stop) }, buffer, after, before }
		return before
	elseif(isundo) then
		self.Redo[#self.Redo + 1] = { { self:CopyPosition(start), self:CopyPosition(stop) }, buffer, after, before }
		return before
	else
		self.Redo = {}
		self.Undo[#self.Undo + 1] = { { self:CopyPosition(start), self:CopyPosition(stop) }, buffer, self:CopyPosition(selection[1]), self:CopyPosition(stop) }
		return stop
	end
 end

 function luapad.EditorPanel:GetSelection()
	return self:GetArea(self:Selection())
 end

 function luapad.EditorPanel:SetSelection(text)
	self:SetCaret(self:SetArea(self:Selection(), text))
 end

 function luapad.EditorPanel:_OnLoseFocus()
	if(self.TabFocus) then
		self:RequestFocus()
		self.TabFocus = nil
	end
 end

 function luapad.EditorPanel:_OnTextChanged()
	local ctrlv = false
	local text = self.TextEntry:GetValue()
	self.TextEntry:SetText("")

	if input.IsKeyDown(KEY_BACKQUOTE) and luapad.IgnoreConsoleOpen then return end
	
	if((input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)) and not (input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT))) then
		-- ctrl+[shift+]key
		if(input.IsKeyDown(KEY_V)) then
			-- ctrl+[shift+]V
			ctrlv = true
		else
			-- ctrl+[shift+]key with key ~= V
			return
		end
	end
	
	if(text == "") then return end
	if(not ctrlv) then
		if(text == "\n") then return end
		if(text == "end") then
			local row = self.Rows[self.Caret[1]]
		end
	end
	
	self:SetSelection(text)
 end

 function luapad.EditorPanel:OnMouseWheeled(delta)
	self.Scroll[1] = self.Scroll[1] - 4 * delta
	if(self.Scroll[1] < 1) then self.Scroll[1] = 1 end
	if(self.Scroll[1] > #self.Rows) then self.Scroll[1] = #self.Rows end
	self.ScrollBar:SetScroll(self.Scroll[1] - 1)
 end

 function luapad.EditorPanel:ScrollCaret()
	if(self.Caret[1] - self.Scroll[1] < 2) then
		self.Scroll[1] = self.Caret[1] - 2
		if(self.Scroll[1] < 1) then self.Scroll[1] = 1 end
	end

	if(self.Caret[1] - self.Scroll[1] > self.Size[1] - 2) then
		self.Scroll[1] = self.Caret[1] - self.Size[1] + 2
		if(self.Scroll[1] < 1) then self.Scroll[1] = 1 end
	end
	
	if(self.Caret[2] - self.Scroll[2] < 4) then
		self.Scroll[2] = self.Caret[2] - 4
		if(self.Scroll[2] < 1) then self.Scroll[2] = 1 end
	end
	
	if(self.Caret[2] - 1 - self.Scroll[2] > self.Size[2] - 4) then
		self.Scroll[2] = self.Caret[2] - 1 - self.Size[2] + 4
		if(self.Scroll[2] < 1) then self.Scroll[2] = 1 end
	end
	
	self.ScrollBar:SetScroll(self.Scroll[1] - 1)
 end

 function unindent(line)
	local i = line:find("%S")
	if(i == nil or i > 5) then i = 5 end
	return line:sub(i)
 end

 function luapad.EditorPanel:CanUndo()
	return #self.Undo > 0
 end

 function luapad.EditorPanel:DoUndo()
	if(#self.Undo > 0) then
		local undo = self.Undo[#self.Undo]
		self.Undo[#self.Undo] = nil
		
		self:SetCaret(self:SetArea(undo[1], undo[2], true, false, undo[3], undo[4]))
	end
 end

 function luapad.EditorPanel:CanRedo()
	return #self.Redo > 0
 end

 function luapad.EditorPanel:DoRedo()
	if(#self.Redo > 0) then
		local redo = self.Redo[#self.Redo]
		self.Redo[#self.Redo] = nil
		
		self:SetCaret(self:SetArea(redo[1], redo[2], false, true, redo[3], redo[4]))
	end
 end

 function luapad.EditorPanel:SelectAll()
	self.Caret = {#self.Rows, string.len(self.Rows[#self.Rows]) + 1}
	self.Start = {1, 1}
	self:ScrollCaret()
 end

 function luapad.EditorPanel:_OnKeyCodeTyped(code)
	self.Blink = RealTime()
	
	local alt = input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT)
	
	local shift = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)
	local control = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)
	
	if(control && alt && code == KEY_S) then
		luapad.SaveAsScript();
	end
	
	if(alt) then return end
	
	if(control) then
		if(code == KEY_A) then
			self:SelectAll()
		elseif(code == KEY_Z) then
			self:DoUndo()
		elseif(code == KEY_Y) then
			self:DoRedo()
		elseif(code == KEY_X) then
			if(self:HasSelection()) then
				self.clipboard = self:GetSelection()
				self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
				SetClipboardText(self.clipboard)
				self:SetSelection()
			end
		elseif(code == KEY_C) then
			if(self:HasSelection()) then
				self.clipboard = self:GetSelection()
				self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
				SetClipboardText(self.clipboard)
			end
		elseif(code == KEY_Q) then
			self:GetParent():Close()
		elseif(code == KEY_S) then
			luapad.SaveScript();
		elseif(code == KEY_O) then
			luapad.OpenScript();
		elseif(code == KEY_N) then
			luapad.NewTab();
		elseif(code == KEY_UP) then
			self.Scroll[1] = self.Scroll[1] - 1
			if(self.Scroll[1] < 1) then self.Scroll[1] = 1 end
		elseif(code == KEY_DOWN) then
			self.Scroll[1] = self.Scroll[1] + 1
		elseif(code == KEY_LEFT) then
			if(self:HasSelection() and !shift) then
				self.Start = self:CopyPosition(self.Caret)
			else
				self.Caret = self:getWordStart(self:MovePosition(self.Caret, -2))
			end
			
			self:ScrollCaret()
			
			if(!shift) then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif(code == KEY_RIGHT) then
			if(self:HasSelection() and !shift) then
				self.Start = self:CopyPosition(self.Caret)
			else
				self.Caret = self:getWordEnd(self:MovePosition(self.Caret, 1))
			end
			
			self:ScrollCaret()
			
			if(!shift) then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif(code == KEY_HOME) then
			self.Caret[1] = 1
			self.Caret[2] = 1
			
			self:ScrollCaret()
			
			if(!shift) then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif(code == KEY_END) then
			self.Caret[1] = #self.Rows
			self.Caret[2] = 1
			
			self:ScrollCaret()
			
			if(!shift) then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif(code == KEY_T) then
			luapad.RunScriptServer()
		elseif(code == KEY_G) then
			luapad.RunScriptClient()
		elseif(code == KEY_B) then
			luapad.RunScriptServer()
			luapad.RunScriptClient()
		end
		
	else
		if(code == KEY_ENTER) then
			local row = self.Rows[self.Caret[1]]:sub(1,self.Caret[2]-1)
			local diff = (row:find("%S") or (row:len()+1))-1
			local tabs = string.rep("    ", math.floor(diff / 4))
			self:SetSelection("\n" .. tabs)
		elseif(code == KEY_UP) then
			if(self.Caret[1] > 1) then
				self.Caret[1] = self.Caret[1] - 1
				
				local length = string.len(self.Rows[self.Caret[1]])
				if(self.Caret[2] > length + 1) then
					self.Caret[2] = length + 1
				end
			end
			
			self:ScrollCaret()
			
			if(!shift) then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif(code == KEY_DOWN) then
			if(self.Caret[1] < #self.Rows) then
				self.Caret[1] = self.Caret[1] + 1
				
				local length = string.len(self.Rows[self.Caret[1]])
				if(self.Caret[2] > length + 1) then
					self.Caret[2] = length + 1
				end
			end
			
			self:ScrollCaret()
			
			if(!shift) then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif(code == KEY_LEFT) then
			if(self:HasSelection() and !shift) then
				self.Start = self:CopyPosition(self.Caret)
			else
				self.Caret = self:MovePosition(self.Caret, -1)
			end
			
			self:ScrollCaret()
			
			if(!shift) then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif(code == KEY_RIGHT) then
			if(self:HasSelection() and !shift) then
				self.Start = self:CopyPosition(self.Caret)
			else
				self.Caret = self:MovePosition(self.Caret, 1)
			end
			
			self:ScrollCaret()
			
			if(!shift) then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif(code == KEY_PAGEUP) then
			self.Caret[1] = self.Caret[1] - math.ceil(self.Size[1] / 2)
			self.Scroll[1] = self.Scroll[1] - math.ceil(self.Size[1] / 2)
			if(self.Caret[1] < 1) then self.Caret[1] = 1 end
			
			local length = string.len(self.Rows[self.Caret[1]])
			if(self.Caret[2] > length + 1) then self.Caret[2] = length + 1 end
			if(self.Scroll[1] < 1) then self.Scroll[1] = 1 end
			
			self:ScrollCaret()
			
			if(!shift) then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif(code == KEY_PAGEDOWN) then
			self.Caret[1] = self.Caret[1] + math.ceil(self.Size[1] / 2)
			self.Scroll[1] = self.Scroll[1] + math.ceil(self.Size[1] / 2)
			if(self.Caret[1] > #self.Rows) then self.Caret[1] = #self.Rows end
			if(self.Caret[1] == #self.Rows) then self.Caret[2] = 1 end
			
			local length = string.len(self.Rows[self.Caret[1]])
			if(self.Caret[2] > length + 1) then self.Caret[2] = length + 1 end
			
			self:ScrollCaret()
			
			if(!shift) then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif(code == KEY_HOME) then
			local row = self.Rows[self.Caret[1]]
			local first_char = row:find("%S") or row:len()+1
			if(self.Caret[2] == first_char) then
				self.Caret[2] = 1
			else
				self.Caret[2] = first_char
			end
			
			self:ScrollCaret()
			
			if(!shift) then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif(code == KEY_END) then
			local length = string.len(self.Rows[self.Caret[1]])
			self.Caret[2] = length + 1
			
			self:ScrollCaret()
			
			if(!shift) then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif(code == KEY_BACKSPACE) then
			if(self:HasSelection()) then
				self:SetSelection()
			else
				local buffer = self:GetArea({self.Caret, {self.Caret[1], 1}})
				if(self.Caret[2] % 4 == 1 and string.len(buffer) > 0 and string.rep(" ", string.len(buffer)) == buffer) then
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, -4)}))
				else
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, -1)}))
				end
			end
		elseif(code == KEY_DELETE) then
			if(self:HasSelection()) then
				self:SetSelection()
			else
				local buffer = self:GetArea({{self.Caret[1], self.Caret[2] + 4}, {self.Caret[1], 1}})
				if(self.Caret[2] % 4 == 1 and string.rep(" ", string.len(buffer)) == buffer and string.len(self.Rows[self.Caret[1]]) >= self.Caret[2] + 4 - 1) then
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, 4)}))
				else
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, 1)}))
				end
			end
		end
	end
	
	if(code == KEY_TAB or (control and (code == KEY_I or code == KEY_O))) then
		if(code == KEY_O) then shift = not shift end
		if(code == KEY_TAB and control) then shift = not shift end
		if(self:HasSelection()) then
			self:Indent(shift)
		else
			if(shift) then
				local newpos = self.Caret[2]-4
				if(newpos < 1) then newpos = 1 end
				self.Start = { self.Caret[1], newpos }
				if(self:GetSelection():find("%S")) then 
					self.Start = self:CopyPosition(self.Caret)
				else
					self:SetSelection("")
				end
			else
				local count = (self.Caret[2] + 2) % 4 + 1
				self:SetSelection(string.rep(" ", count))
			end
		end
		self.TabFocus = true
	end
	
	if(control) then
		self:OnShortcut(code)
	end
 end

 function luapad.EditorPanel:getWordStart(caret)
	local line = string.ToTable(self.Rows[caret[1]])
	if(#line < caret[2]) then return caret end
	for i=0,caret[2] do
		if(!line[caret[2]-i]) then return {caret[1],caret[2]-i+1} end
		if(line[caret[2]-i] >= "a" and line[caret[2]-i] <= "z" or line[caret[2]-i] >= "A" and line[caret[2]-i] <= "Z" or line[caret[2]-i] >= "0" and line[caret[2]-i] <= "9") then else return {caret[1],caret[2]-i+1} end
	end
	return {caret[1],1}
 end

 function luapad.EditorPanel:getWordEnd(caret)
	local line = string.ToTable(self.Rows[caret[1]])
	if(#line < caret[2]) then return caret end
	for i=caret[2],#line do
		if(!line[i]) then return {caret[1],i} end
		if(line[i] >= "a" and line[i] <= "z" or line[i] >= "A" and line[i] <= "Z" or line[i] >= "0" and line[i] <= "9") then else return {caret[1],i} end
	end
	return {caret[1],#line+1}
 end
 
 function luapad.EditorPanel:Indent(shift)
	local tab_scroll = self:CopyPosition(self.Scroll)
	local tab_start, tab_caret = self:MakeSelection(self:Selection())
	tab_start[2] = 1

	if(tab_caret[2] ~= 1) then
		tab_caret[1] = tab_caret[1] + 1
		tab_caret[2] = 1
	end

	self.Caret = self:CopyPosition(tab_caret)
	self.Start = self:CopyPosition(tab_start)

	if (self.Caret[2] == 1) then
		self.Caret = self:MovePosition(self.Caret, -1)
	end
	
	if(shift) then
		local tmp = self:GetSelection():gsub("\n ? ? ? ?", "\n")
		self:SetSelection(unindent(tmp))
	else
		self:SetSelection("    " .. self:GetSelection():gsub("\n", "\n    "))
	end
	
	self.Caret = self:CopyPosition(tab_caret)
	self.Start = self:CopyPosition(tab_start)
	self.Scroll = self:CopyPosition(tab_scroll)
	self:ScrollCaret()
 end
 
 function luapad.EditorPanel:OnTextChanged()
 end
 
 function luapad.EditorPanel:OnShortcut()
 end

 vgui.Register("LuapadEditor", luapad.EditorPanel, "Panel");-- This is an automatically generated cache file for serverside globals, metas, and enums
-- Don't touch it, or you'll probably mess up your syntax highlighting

luapad._sG = {};
luapad._sG["WireGateExpressionSendPacket"] = "f";
luapad._sG["TableToKeyValues"] = "f";
luapad._sG["MakeWirePlug"] = "f";
luapad._sG["GMODSpawnProp"] = "f";
luapad._sG["AddConsoleCommand"] = "f";
luapad._sG["SetGlobalVector"] = "f";
luapad._sG["collectgarbage"] = "f";
luapad._sG["WorldToLocal"] = "f";
luapad._sG["NotifierSetDelay"] = "f";
luapad._sG["IncludeClientFile"] = "f";
luapad._sG["GetConVarNumber"] = "f";
luapad._sG["SetGlobalAngle"] = "f";
luapad._sG["GetGlobalAngle"] = "f";
luapad._sG["registerOperator"] = "f";
luapad._sG["RefreshSpecialOutputs"] = "f";
luapad._sG["validPhysics"] = "f";
luapad._sG["MakeXQMWireHydraulicController"] = "f";
luapad._sG["SetGlobalString"] = "f";
luapad._sG["CCSpawnSENT"] = "f";
luapad._sG["MakeWireLocator"] = "f";
luapad._sG["Matrix"] = "f";
luapad._sG["Wire_BuildDupeInfo"] = "f";
luapad._sG["CC_GMOD_Camera"] = "f";
luapad._sG["playerDeath"] = "f";
luapad._sG["SetGlobalBeamInt"] = "f";
luapad._sG["vehicles"] = {};
luapad._sG["luapad"] = {};
luapad._sG["table"] = {};
luapad._sG["ipairs"] = "f";
luapad._sG["MsgAll"] = "f";
luapad._sG["SetGlobalBeamString"] = "f";
luapad._sG["GetGlobalInt"] = "f";
luapad._sG["INIParser"] = {};
luapad._sG["Radio_SendData"] = "f";
luapad._sG["MakeWireTwoWay_Radio"] = "f";
luapad._sG["_G"] = {};
luapad._sG["CatmullRomCams"] = {};
luapad._sG["SQLStr"] = "f";
luapad._sG["MakeWireMotor"] = "f";
luapad._sG["GPU_PlayerRespawn"] = "f";
luapad._sG["Wire_CreateOutputs"] = "f";
luapad._sG["TellGps"] = "f";
luapad._sG["WireToolMakeSoundEmitter"] = "f";
luapad._sG["MakeWireString"] = "f";
luapad._sG["NotifierCheckAdmin"] = "f";
luapad._sG["Add_NPC_Class"] = "f";
luapad._sG["debug"] = {};
luapad._sG["_R"] = {};
luapad._sG["CCSpawnNPC"] = "f";
luapad._sG["PCMod_ResetOld"] = "f";
luapad._sG["PrintMessage"] = "f";
luapad._sG["usermessage"] = {};
luapad._sG["MakeWireHoverBall"] = "f";
luapad._sG["MakeWireGrabber"] = "f";
luapad._sG["GetWirelessRecv"] = "f";
luapad._sG["Reflush_GPU_Data"] = "f";
luapad._sG["ColorToHSV"] = "f";
luapad._sG["registerFunction"] = "f";
luapad._sG["BuildNetworkedVarsTable"] = "f";
luapad._sG["hook"] = {};
luapad._sG["CCTeleportLoc"] = "f";
luapad._sG["tablex"] = {};
luapad._sG["IsTableOfEntitiesValid"] = "f";
luapad._sG["MakeWireTextScreen"] = "f";
luapad._sG["pcall"] = "f";
luapad._sG["AddOriginToPVS"] = "f";
luapad._sG["ApplyColMatSpawned"] = "f";
luapad._sG["MsgN"] = "f";
luapad._sG["GetGlobalBool"] = "f";
luapad._sG["SetGlobalBeamFloat"] = "f";
luapad._sG["rawequal"] = "f";
luapad._sG["SetGlobalBool"] = "f";
luapad._sG["MakeWireKeycardSpawner"] = "f";
luapad._sG["ParticleEffect"] = "f";
luapad._sG["setfenv"] = "f";
luapad._sG["MakeWireSpeedometer"] = "f";
luapad._sG["MakeWireDataPlug"] = "f";
luapad._sG["WireToolMakeDigitalScreen"] = "f";
luapad._sG["SetGlobalEntity"] = "f";
luapad._sG["coroutine"] = {};
luapad._sG["GetGlobalEntity"] = "f";
luapad._sG["Add_TextReceiver"] = "f";
luapad._sG["MakeWireLamp"] = "f";
luapad._sG["PLUGIN"] = {};
luapad._sG["MakeWireRanger"] = "f";
luapad._sG["CCSpawn"] = "f";
luapad._sG["MakeWireDupePort"] = "f";
luapad._sG["MakeWireEmitter"] = "f";
luapad._sG["WireToolMakeOscilloscope"] = "f";
luapad._sG["MakeWireFXEmitter"] = "f";
luapad._sG["registerBone"] = "f";
luapad._sG["PreProcessor"] = {};
luapad._sG["Wire_ApplyDupeInfo"] = "f";
luapad._sG["CheckPropSolid"] = "f";
luapad._sG["WireToolMakePanel"] = "f";
luapad._sG["list"] = {};
luapad._sG["MakeWireUseHoloemitter"] = "f";
luapad._sG["WireGateExpressionParser"] = {};
luapad._sG["MakeWireMaterializer"] = "f";
luapad._sG["PCMod"] = {};
luapad._sG["WireLib"] = {};
luapad._sG["Format"] = "f";
luapad._sG["GetBuddyFinder"] = "f";
luapad._sG["NullEntity"] = "f";
luapad._sG["SortedPairsByValue"] = "f";
luapad._sG["MakeWireUser"] = "f";
luapad._sG["e2_extpp_pass1"] = "f";
luapad._sG["saverestore"] = {};
luapad._sG["WireToolMakeAdvInput"] = "f";
luapad._sG["MakeWirePID"] = "f";
luapad._sG["MakeWireLatchController"] = "f";
luapad._sG["SinglePlayer"] = "f";
luapad._sG["MakeWireBeamReader"] = "f";
luapad._sG["makedoor"] = "f";
luapad._sG["MakeWireTurret"] = "f";
luapad._sG["constraint"] = {};
luapad._sG["IsPhysicsObject"] = "f";
luapad._sG["Vertex"] = "f";
luapad._sG["DeriveGamemode"] = "f";
luapad._sG["Wire_TriggerOutput"] = "f";
luapad._sG["setmetatable"] = "f";
luapad._sG["getmetatable"] = "f";
luapad._sG["rawset"] = "f";
luapad._sG["MakeWireRelay"] = "f";
luapad._sG["MakeWireTargetFinderBeta"] = "f";
luapad._sG["CCTestNotifier"] = "f";
luapad._sG["os"] = {};
luapad._sG["construct"] = {};
luapad._sG["Parser"] = {};
luapad._sG["MakeWireRamCardReader"] = "f";
luapad._sG["CC_Face_Randomize"] = "f";
luapad._sG["CCResetUnit"] = "f";
luapad._sG["util"] = {};
luapad._sG["package"] = {};
luapad._sG["MakeWireWaypoint"] = "f";
luapad._sG["CurTime"] = "f";
luapad._sG["e2_processerror"] = "f";
luapad._sG["MakeWireGateExpressionParser"] = "f";
luapad._sG["WireToolMakeDualInput"] = "f";
luapad._sG["WireGateExpressionRecvPacket"] = "f";
luapad._sG["Radio_GetTwoWayID"] = "f";
luapad._sG["MakeLamp"] = "f";
luapad._sG["MakeTurret"] = "f";
luapad._sG["MakeWireHydraulicController"] = "f";
luapad._sG["ai_task"] = {};
luapad._sG["server_settings"] = {};
luapad._sG["MakeWirePainter"] = "f";
luapad._sG["SuppressHostEvents"] = "f";
luapad._sG["MakeWireReader"] = "f";
luapad._sG["MakeNoCollideController"] = "f";
luapad._sG["MakeWireIndicator"] = "f";
luapad._sG["GetWorldEntity"] = "f";
luapad._sG["WireToolSetup"] = {};
luapad._sG["MakeWireDualInput"] = "f";
luapad._sG["PC_AskForPort"] = "f";
luapad._sG["e2_extpp_pass2"] = "f";
luapad._sG["MakeWireXYZBeacon"] = "f";
luapad._sG["GetGlobalBeamEntity"] = "f";
luapad._sG["MakeWireSocket"] = "f";
luapad._sG["e2_get_typeid"] = "f";
luapad._sG["HSVToColor"] = "f";
luapad._sG["team"] = {};
luapad._sG["RealTime"] = "f";
luapad._sG["PCTool"] = {};
luapad._sG["MakeLight"] = "f";
luapad._sG["UnPredictedCurTime"] = "f";
luapad._sG["gcinfo"] = "f";
luapad._sG["concommand"] = {};
luapad._sG["HSHoloInteract"] = "f";
luapad._sG["WireToolMakeEmitter"] = "f";
luapad._sG["Wire_Link_Clear"] = "f";
luapad._sG["WireToolMakePixel"] = "f";
luapad._sG["MakeWireHydraulic"] = "f";
luapad._sG["next"] = "f";
luapad._sG["VectorRand"] = "f";
luapad._sG["cvars"] = {};
luapad._sG["select"] = "f";
luapad._sG["dupeshare"] = {};
luapad._sG["CCAnswer"] = "f";
luapad._sG["FrameTime"] = "f";
luapad._sG["GetGlobalBeamBool"] = "f";
luapad._sG["KeyValuesToTablePreserveOrder"] = "f";
luapad._sG["e2_install_hook_fix"] = "f";
luapad._sG["ServerLog"] = "f";
luapad._sG["MakeWireDetonator"] = "f";
luapad._sG["ParticleEffectAttach"] = "f";
luapad._sG["SafeRemoveEntity"] = "f";
luapad._sG["GAMEMODE"] = {};
luapad._sG["CCAck"] = "f";
luapad._sG["scripted_ents"] = {};
luapad._sG["DoPlayerEntitySpawn"] = "f";
luapad._sG["unpack"] = "f";
luapad._sG["MakeWireHoloemitter"] = "f";
luapad._sG["MakeWireGPS"] = "f";
luapad._sG["WireToolMakeLamp"] = "f";
luapad._sG["rawget"] = "f";
luapad._sG["MakeWireHudIndicator"] = "f";
luapad._sG["CreateSound"] = "f";
luapad._sG["WireToolMakeConsoleScreen"] = "f";
luapad._sG["engineCommandComplete"] = "f";
luapad._sG["sql"] = {};
luapad._sG["IsValid"] = "f";
luapad._sG["WorldSound"] = "f";
luapad._sG["MakeWireImplanter"] = "f";
luapad._sG["EffectData"] = "f";
luapad._sG["OrderVectors"] = "f";
luapad._sG["MakeWireRTCam"] = "f";
luapad._sG["WireGPU_AddMonitor"] = "f";
luapad._sG["Json"] = {};
luapad._sG["debugoverlay"] = {};
luapad._sG["numpad"] = {};
luapad._sG["MakeWireGyroscope"] = "f";
luapad._sG["DamageInfo"] = "f";
luapad._sG["GetAddonList"] = "f";
luapad._sG["print_r"] = "f";
luapad._sG["Wire_Link_End"] = "f";
luapad._sG["WireToolMakeHoloGrid"] = "f";
luapad._sG["QuaternionSlerp"] = "f";
luapad._sG["switch"] = "f";
luapad._sG["tablevalues"] = "f";
luapad._sG["MakeWirePod"] = "f";
luapad._sG["MakeWirePanel"] = "f";
luapad._sG["GetWirelessSrv"] = "f";
luapad._sG["HoloInteract"] = "f";
luapad._sG["MakeWireKeycard"] = "f";
luapad._sG["timer"] = {};
luapad._sG["MakeWireWheel"] = "f";
luapad._sG["MakeNail"] = "f";
luapad._sG["MakeWireScreen"] = "f";
luapad._sG["MakeWirePixel"] = "f";
luapad._sG["BTClientUpdateMessage"] = "f";
luapad._sG["MakeWireOscilloscope"] = "f";
luapad._sG["WireToolMakeExplosivesSimple"] = "f";
luapad._sG["MakeWireLight"] = "f";
luapad._sG["Wire_KeyPressed"] = "f";
luapad._sG["Wire_KeyOff"] = "f";
luapad._sG["MakeWireInput"] = "f";
luapad._sG["MakeWire7Seg"] = "f";
luapad._sG["PrecacheParticleSystem"] = "f";
luapad._sG["MakeWireHologrid"] = "f";
luapad._sG["Resend_GPU_Data"] = "f";
luapad._sG["MakeWireGate"] = "f";
luapad._sG["schedule"] = {};
luapad._sG["PCallError"] = "f";
luapad._sG["validNPC"] = "f";
luapad._sG["mess_with_args"] = "f";
luapad._sG["pairs"] = "f";
luapad._sG["Makewire_field_device"] = "f";
luapad._sG["Egateglobalvarconnect"] = "f";
luapad._sG["Egateglobalvardisconnect"] = "f";
luapad._sG["freefallwiregates"] = "f";
luapad._sG["http"] = {};
luapad._sG["exp2FindCleanup"] = "f";
luapad._sG["Msg"] = "f";
luapad._sG["getOwner"] = "f";
luapad._sG["isOwner"] = "f";
luapad._sG["validEntity"] = "f";
luapad._sG["e2_remove_hook_fix"] = "f";
luapad._sG["Exp2TextReceiving"] = "f";
luapad._sG["WireToolMakeAdvPod"] = "f";
luapad._sG["registerCallback"] = "f";
luapad._sG["registerType"] = "f";
luapad._sG["string"] = {};
luapad._sG["MakeWireDigitalScreen"] = "f";
luapad._sG["MakeWireconsoleScreen"] = "f";
luapad._sG["MakeWireButton"] = "f";
luapad._sG["MakeWireAdvPod"] = "f";
luapad._sG["InfuseSpecialOutputs"] = "f";
luapad._sG["DakaraWeapon"] = {};
luapad._sG["RingsNamingCallback"] = "f";
luapad._sG["CC_GMOD_Tool"] = "f";
luapad._sG["MakeWheel"] = "f";
luapad._sG["MakeThruster"] = "f";
luapad._sG["MakeSpawner"] = "f";
luapad._sG["UpdateRenderTarget"] = "f";
luapad._sG["MakeWireWeight"] = "f";
luapad._sG["MakeHoverBall"] = "f";
luapad._sG["MakeEmitter"] = "f";
luapad._sG["MakeButton"] = "f";
luapad._sG["PlayerDataUpdate"] = "f";
luapad._sG["isDedicatedServer"] = "f";
luapad._sG["MakeCont"] = "f";
luapad._sG["ConditionName"] = "f";
luapad._sG["ValidEntity"] = "f";
luapad._sG["HTTPGet"] = "f";
luapad._sG["MakeWireUserReader"] = "f";
luapad._sG["MakeWireTargetFilter"] = "f";
luapad._sG["MakeWireRangerBeta"] = "f";
luapad._sG["MakeWireMotorController"] = "f";
luapad._sG["MakeWireMicrophone"] = "f";
luapad._sG["MakeWireMagnet"] = "f";
luapad._sG["MakeWireKeycardReader"] = "f";
luapad._sG["MakeWireHSRanger"] = "f";
luapad._sG["MakeRadioSystems"] = "f";
luapad._sG["MakeWireFreezerController"] = "f";
luapad._sG["CreateDebugBuddy"] = "f";
luapad._sG["ColorClamp"] = "f";
luapad._sG["MakeWirefacer"] = "f";
luapad._sG["MakeWireDynMemory"] = "f";
luapad._sG["MakeWireDetcord"] = "f";
luapad._sG["CCToggleDebug"] = "f";
luapad._sG["MakeWirebtsrv"] = "f";
luapad._sG["SetupWireGateExpression"] = "f";
luapad._sG["MakeWirebtrecv"] = "f";
luapad._sG["MakeWireAdvHudIndicator"] = "f";
luapad._sG["MakeWireHSHoloemitter"] = "f";
luapad._sG["SetGlobalFloat"] = "f";
luapad._sG["MakeScaleEnt"] = "f";
luapad._sG["MakeWireAdvInput"] = "f";
luapad._sG["MakeWireWinch"] = "f";
luapad._sG["MakeWireWinchController"] = "f";
luapad._sG["file"] = {};
luapad._sG["MakeWireVectorThruster"] = "f";
luapad._sG["MakeWireVehicle"] = "f";
luapad._sG["MakeWireValue"] = "f";
luapad._sG["MakeWireTrail"] = "f";
luapad._sG["MakeWireReceiver"] = "f";
luapad._sG["MakeWireTargetFinder"] = "f";
luapad._sG["MakeWireSpawner"] = "f";
luapad._sG["MakeWireOutput"] = "f";
luapad._sG["MakeWireRadio"] = "f";
luapad._sG["MakeWireNumpad"] = "f";
luapad._sG["MakeWireNailer"] = "f";
luapad._sG["MakeWireLatch"] = "f";
luapad._sG["MakeWireLaserReciever"] = "f";
luapad._sG["MakeWireKeyboard"] = "f";
luapad._sG["MakeWireIgniter"] = "f";
luapad._sG["GetGlobalFloat"] = "f";
luapad._sG["Radio_Unregister"] = "f";
luapad._sG["MakeWireGpu"] = "f";
luapad._sG["MakeBomb"] = "f";
luapad._sG["Error"] = "f";
luapad._sG["MakeWireForcer"] = "f";
luapad._sG["MakeWireExplosive"] = "f";
luapad._sG["UpdateWireExplosive"] = "f";
luapad._sG["MakeWireEmarker"] = "f";
luapad._sG["EntityMarker_Removed"] = "f";
luapad._sG["Add_EntityMarker"] = "f";
luapad._sG["DebuggerThink"] = "f";
luapad._sG["MakeWireTransferer"] = "f";
luapad._sG["MakeWireStore"] = "f";
luapad._sG["MakeWireDataPort"] = "f";
luapad._sG["MakeWireDataSocket"] = "f";
luapad._sG["ents"] = {};
luapad._sG["MakeWireColorer"] = "f";
luapad._sG["MakeWireCDLock"] = "f";
luapad._sG["VGUIFrameTime"] = "f";
luapad._sG["MakeWireCDRay"] = "f";
luapad._sG["MakeWireCam"] = "f";
luapad._sG["MakeWireAddressBus"] = "f";
luapad._sG["HoloRightClick"] = "f";
luapad._sG["WireToolMakeWeight"] = "f";
luapad._sG["WireToolMakeInput"] = "f";
luapad._sG["WireToolMakeButton"] = "f";
luapad._sG["e2_parse_args"] = "f";
luapad._sG["WireToolMakeTextScreen"] = "f";
luapad._sG["WireToolMakeScreen"] = "f";
luapad._sG["WireToolMakeLight"] = "f";
luapad._sG["tonumber"] = "f";
luapad._sG["WireToolMakeIndicator"] = "f";
luapad._sG["WireToolMake7Seg"] = "f";
luapad._sG["Wire_Restored"] = "f";
luapad._sG["WireToolMakeSpeedometer"] = "f";
luapad._sG["RunString"] = "f";
luapad._sG["WireToolMakeGate"] = "f";
luapad._sG["WireToolHelpers"] = {};
luapad._sG["VerifyWireGateExpression"] = "f";
luapad._sG["CCSpawnVehicle"] = "f";
luapad._sG["CCSpawnSWEP"] = "f";
luapad._sG["CCGiveSWEP"] = "f";
luapad._sG["GMODSpawnEffect"] = "f";
luapad._sG["FixInvalidPhysicsObject"] = "f";
luapad._sG["IsEntity"] = "f";
luapad._sG["NotifierSetSilent"] = "f";
luapad._sG["MakeProp"] = "f";
luapad._sG["GMODSpawnRagdoll"] = "f";
luapad._sG["MaxPlayers"] = "f";
luapad._sG["utilx"] = {};
luapad._sG["Wire_AfterPasteMods"] = "f";
luapad._sG["Wire_SetPathNames"] = "f";
luapad._sG["Wire_Link_Cancel"] = "f";
luapad._sG["Wire_Link_Node"] = "f";
luapad._sG["Wire_Remove"] = "f";
luapad._sG["Wire_AdjustInputs"] = "f";
luapad._sG["TextReceiver_Received"] = "f";
luapad._sG["Radio_ChangeChannel"] = "f";
luapad._sG["Radio_RecieveData"] = "f";
luapad._sG["Radio_Register"] = "f";
luapad._sG["math"] = {};
luapad._sG["StargateExtras"] = {};
luapad._sG["CCPrivateMessage"] = "f";
luapad._sG["DestroyDebugBuddy"] = "f";
luapad._sG["SysTime"] = "f";
luapad._sG["AdvDupe"] = {};
luapad._sG["Entity"] = "f";
luapad._sG["GetGlobalBeamString"] = "f";
luapad._sG["SetGlobalBeamBool"] = "f";
luapad._sG["SetGlobalBeamEntity"] = "f";
luapad._sG["GetGlobalBeamInt"] = "f";
luapad._sG["GetGlobalBeamFloat"] = "f";
luapad._sG["GetGlobalBeamAngle"] = "f";
luapad._sG["SetGlobalBeamAngle"] = "f";
luapad._sG["GetGlobalBeamVector"] = "f";
luapad._sG["SetGlobalBeamVector"] = "f";
luapad._sG["cleanup"] = {};
luapad._sG["StarGate"] = {};
luapad._sG["PROG"] = {};
luapad._sG["PC_PortSelected"] = "f";
luapad._sG["PC_BeamPorts"] = "f";
luapad._sG["module"] = "f";
luapad._sG["MakeWireGateExpression"] = "f";
luapad._sG["Color"] = "f";
luapad._sG["getfenv"] = "f";
luapad._sG["datastream"] = {};
luapad._sG["glon"] = {};
luapad._sG["QuaternionNLerp"] = "f";
luapad._sG["Quaternion"] = {};
luapad._sG["Dbg"] = "f";
luapad._sG["NotifierSetConsole"] = "f";
luapad._sG["SortedPairs"] = "f";
luapad._sG["MeshQuad"] = "f";
luapad._sG["MeshCube"] = "f";
luapad._sG["mathx"] = {};
luapad._sG["xpcall"] = "f";
luapad._sG["DRV"] = {};
luapad._sG["duplicator"] = {};
luapad._sG["undo"] = {};
luapad._sG["SendUserMessage"] = "f";
luapad._sG["player_manager"] = {};
luapad._sG["decode"] = "f";
luapad._sG["gamemode"] = {};
luapad._sG["TimedCos"] = "f";
luapad._sG["TimedSin"] = "f";
luapad._sG["STNDRD"] = "f";
luapad._sG["RestoreCursorPosition"] = "f";
luapad._sG["RememberCursorPosition"] = "f";
luapad._sG["SafeRemoveEntityDelayed"] = "f";
luapad._sG["tablekeys"] = "f";
luapad._sG["AccessorFuncNW"] = "f";
luapad._sG["AccessorFunc"] = "f";
luapad._sG["UTIL_IsUselessModel"] = "f";
luapad._sG["Model"] = "f";
luapad._sG["Sound"] = "f";
luapad._sG["PrintTable"] = "f";
luapad._sG["error"] = "f";
luapad._sG["MakeWireCDDisk"] = "f";
luapad._sG["Wire_KeyOn"] = "f";
luapad._sG["LerpVector"] = "f";
luapad._sG["assert"] = "f";
luapad._sG["gmod"] = {};
luapad._sG["resource"] = {};
luapad._sG["player"] = {};
luapad._sG["GetMountedContent"] = "f";
luapad._sG["game"] = {};
luapad._sG["MakeWireWatersensor"] = "f";
luapad._sG["MakeWireCpu"] = "f";
luapad._sG["Vector"] = "f";
luapad._sG["RecipientFilter"] = "f";
luapad._sG["GetConVar"] = "f";
luapad._sG["PhysObject"] = "f";
luapad._sG["GetGlobalString"] = "f";
luapad._sG["GetHostName"] = "f";
luapad._sG["GetGlobalVector"] = "f";
luapad._sG["MakeWirehdd"] = "f";
luapad._sG["GetGlobalVar"] = "f";
luapad._sG["SetGlobalInt"] = "f";
luapad._sG["SetGlobalVar"] = "f";
luapad._sG["Angle"] = "f";
luapad._sG["MakeNpc"] = "f";
luapad._sG["HoloReload"] = "f";
luapad._sG["SetPhysConstraintSystem"] = "f";
luapad._sG["MakeBalloon"] = "f";
luapad._sG["ClientCallGamemode"] = "f";
luapad._sG["AddCSLuaFile"] = "f";
luapad._sG["IsFirstTimePredicted"] = "f";
luapad._sG["CreateClientConVar"] = "f";
luapad._sG["PrecacheScene"] = "f";
luapad._sG["LocalToWorld"] = "f";
luapad._sG["Lerp"] = "f";
luapad._sG["umsg"] = {};
luapad._sG["DropEntityIfHeld"] = "f";
luapad._sG["MakeDynamite"] = "f";
luapad._sG["KeyValuesToTable"] = "f";
luapad._sG["CCDial"] = "f";
luapad._sG["RunConsoleCommand"] = "f";
luapad._sG["CreateConVar"] = "f";
luapad._sG["FindMetaTable"] = "f";
luapad._sG["ConVarExists"] = "f";
luapad._sG["GetConVarString"] = "f";
luapad._sG["GetAllEnts"] = "f";
luapad._sG["include"] = "f";
luapad._sG["ErrorNoHalt"] = "f";
luapad._sG["MatrixFromAngle"] = "f";
luapad._sG["ModelPlug_Register"] = "f";
luapad._sG["weapons"] = {};
luapad._sG["MakeWireExpression2"] = "f";
luapad._sG["Wire_CreateOutputIterator"] = "f";
luapad._sG["tostring"] = "f";
luapad._sG["MakeWireNotifier"] = "f";
luapad._sG["GetGamemodes"] = "f";
luapad._sG["DoPropSpawnedEffect"] = "f";
luapad._sG["RingsDiallingCallback"] = "f";
luapad._sG["LerpAngle"] = "f";
luapad._sG["BroadcastLua"] = "f";
luapad._sG["MakeWireSatellitedish"] = "f";
luapad._sG["ai_schedule"] = {};
luapad._sG["Compiler"] = {};
luapad._sG["print"] = "f";
luapad._sG["MakeWiredatarate"] = "f";
luapad._sG["_E"] = {};
luapad._sG["Wire_AdjustOutputs"] = "f";
luapad._sG["SoundDuration"] = "f";
luapad._sG["GetMountableContent"] = "f";
luapad._sG["WireExpressionGetLines"] = "f";
luapad._sG["MakeWireStringBuffer"] = "f";
luapad._sG["MakeWireSimpleExplosive"] = "f";
luapad._sG["CreateClient"] = "f";
luapad._sG["MakeWireServo"] = "f";
luapad._sG["require"] = "f";
luapad._sG["filex"] = {};
luapad._sG["Wire_Link_Start"] = "f";
luapad._sG["Serialiser"] = {};
luapad._sG["MakeWireGraphicsTablet"] = "f";
luapad._sG["Player"] = "f";
luapad._sG["engineConsoleCommand"] = "f";
luapad._sG["WireToolMakeWheel"] = "f";
luapad._sG["MakeWireThruster"] = "f";
luapad._sG["tobool"] = "f";
luapad._sG["type"] = "f";
luapad._sG["checkEntity"] = "f";
luapad._sG["StringExplode"] = "f";
luapad._sG["IsVector"] = "f";
luapad._sG["MMatrix"] = {};
luapad._sG["Wire_CreateInputs"] = "f";
luapad._sG["GetTaskID"] = "f";
luapad._sG["Tokenizer"] = {};
luapad._sG["SortedPairsByMemberValue"] = "f";
luapad._sG["___comp___"] = "f";
luapad._sG["MakeWireSensor"] = "f";
luapad._sG["WireToolMakeUseEmitter"] = "f";
luapad._sG["vehicles"]["RefreshList"] = "f";
luapad._sG["vehicles"]["PlayerSpawn"] = "f";
luapad._sG["vehicles"]["GetTable"] = "f";
luapad._sG["vehicles"]["Add"] = "f";
luapad._sG["luapad"]["Upload"] = "f";
luapad._sG["table"]["getn"] = "f";
luapad._sG["table"]["remove"] = "f";
luapad._sG["table"]["ForceInsert"] = "f";
luapad._sG["table"]["Empty"] = "f";
luapad._sG["table"]["GetWinningKey"] = "f";
luapad._sG["table"]["insert"] = "f";
luapad._sG["table"]["MaxVal"] = "f";
luapad._sG["table"]["GetLastValue"] = "f";
luapad._sG["table"]["maxn"] = "f";
luapad._sG["table"]["MinVal"] = "f";
luapad._sG["table"]["concat"] = "f";
luapad._sG["table"]["HasKey"] = "f";
luapad._sG["table"]["Sanitise"] = "f";
luapad._sG["table"]["Add"] = "f";
luapad._sG["table"]["LowerKeyNames"] = "f";
luapad._sG["table"]["MakeSortedKeys"] = "f";
luapad._sG["table"]["Compact"] = "f";
luapad._sG["table"]["SortByMember"] = "f";
luapad._sG["table"]["TotalVal"] = "f";
luapad._sG["table"]["foreachi"] = "f";
luapad._sG["table"]["AllNumerical"] = "f";
luapad._sG["table"]["Copy"] = "f";
luapad._sG["table"]["SortByKey"] = "f";
luapad._sG["table"]["FindPrev"] = "f";
luapad._sG["table"]["FindNext"] = "f";
luapad._sG["table"]["GetLastKey"] = "f";
luapad._sG["table"]["Random"] = "f";
luapad._sG["table"]["GetFirstValue"] = "f";
luapad._sG["table"]["GetFirstKey"] = "f";
luapad._sG["table"]["ClearKeys"] = "f";
luapad._sG["table"]["setn"] = "f";
luapad._sG["table"]["CollapseKeyValue"] = "f";
luapad._sG["table"]["sortdesc"] = "f";
luapad._sG["table"]["DeSanitise"] = "f";
luapad._sG["table"]["PartialVal"] = "f";
luapad._sG["table"]["ToString"] = "f";
luapad._sG["table"]["HasValue"] = "f";
luapad._sG["table"]["foreach"] = "f";
luapad._sG["table"]["Count"] = "f";
luapad._sG["table"]["Inherit"] = "f";
luapad._sG["table"]["sort"] = "f";
luapad._sG["table"]["CopyFromTo"] = "f";
luapad._sG["table"]["IsSequential"] = "f";
luapad._sG["table"]["Merge"] = "f";
luapad._sG["INIParser"]["StripQuotes"] = "f";
luapad._sG["INIParser"]["parse"] = "f";
luapad._sG["INIParser"]["get"] = "f";
luapad._sG["INIParser"]["StripComment"] = "f";
luapad._sG["INIParser"]["__index"] = "f";
luapad._sG["INIParser"]["new"] = "f";
luapad._sG["_G"]["WireGateExpressionSendPacket"] = "f";
luapad._sG["_G"]["TableToKeyValues"] = "f";
luapad._sG["_G"]["MakeWirePlug"] = "f";
luapad._sG["_G"]["GMODSpawnProp"] = "f";
luapad._sG["_G"]["AddConsoleCommand"] = "f";
luapad._sG["_G"]["SetGlobalVector"] = "f";
luapad._sG["_G"]["collectgarbage"] = "f";
luapad._sG["_G"]["WorldToLocal"] = "f";
luapad._sG["_G"]["NotifierSetDelay"] = "f";
luapad._sG["_G"]["IncludeClientFile"] = "f";
luapad._sG["_G"]["GetConVarNumber"] = "f";
luapad._sG["_G"]["SetGlobalAngle"] = "f";
luapad._sG["_G"]["GetGlobalAngle"] = "f";
luapad._sG["_G"]["registerOperator"] = "f";
luapad._sG["_G"]["RefreshSpecialOutputs"] = "f";
luapad._sG["_G"]["validPhysics"] = "f";
luapad._sG["_G"]["MakeXQMWireHydraulicController"] = "f";
luapad._sG["_G"]["SetGlobalString"] = "f";
luapad._sG["_G"]["CCSpawnSENT"] = "f";
luapad._sG["_G"]["MakeWireLocator"] = "f";
luapad._sG["_G"]["Matrix"] = "f";
luapad._sG["_G"]["Wire_BuildDupeInfo"] = "f";
luapad._sG["_G"]["CC_GMOD_Camera"] = "f";
luapad._sG["_G"]["playerDeath"] = "f";
luapad._sG["_G"]["SetGlobalBeamInt"] = "f";
luapad._sG["_G"]["ipairs"] = "f";
luapad._sG["_G"]["MsgAll"] = "f";
luapad._sG["_G"]["SetGlobalBeamString"] = "f";
luapad._sG["_G"]["GetGlobalInt"] = "f";
luapad._sG["_G"]["Radio_SendData"] = "f";
luapad._sG["_G"]["MakeWireTwoWay_Radio"] = "f";
luapad._sG["_G"]["SQLStr"] = "f";
luapad._sG["_G"]["MakeWireMotor"] = "f";
luapad._sG["_G"]["GPU_PlayerRespawn"] = "f";
luapad._sG["_G"]["Wire_CreateOutputs"] = "f";
luapad._sG["_G"]["TellGps"] = "f";
luapad._sG["_G"]["WireToolMakeSoundEmitter"] = "f";
luapad._sG["_G"]["MakeWireString"] = "f";
luapad._sG["_G"]["NotifierCheckAdmin"] = "f";
luapad._sG["_G"]["Add_NPC_Class"] = "f";
luapad._sG["_G"]["CCSpawnNPC"] = "f";
luapad._sG["_G"]["PCMod_ResetOld"] = "f";
luapad._sG["_G"]["PrintMessage"] = "f";
luapad._sG["_G"]["MakeWireHoverBall"] = "f";
luapad._sG["_G"]["MakeWireGrabber"] = "f";
luapad._sG["_G"]["GetWirelessRecv"] = "f";
luapad._sG["_G"]["Reflush_GPU_Data"] = "f";
luapad._sG["_G"]["ColorToHSV"] = "f";
luapad._sG["_G"]["registerFunction"] = "f";
luapad._sG["_G"]["BuildNetworkedVarsTable"] = "f";
luapad._sG["_G"]["CCTeleportLoc"] = "f";
luapad._sG["_G"]["IsTableOfEntitiesValid"] = "f";
luapad._sG["_G"]["MakeWireTextScreen"] = "f";
luapad._sG["_G"]["pcall"] = "f";
luapad._sG["_G"]["AddOriginToPVS"] = "f";
luapad._sG["_G"]["ApplyColMatSpawned"] = "f";
luapad._sG["_G"]["MsgN"] = "f";
luapad._sG["_G"]["GetGlobalBool"] = "f";
luapad._sG["_G"]["SetGlobalBeamFloat"] = "f";
luapad._sG["_G"]["rawequal"] = "f";
luapad._sG["_G"]["SetGlobalBool"] = "f";
luapad._sG["_G"]["MakeWireKeycardSpawner"] = "f";
luapad._sG["_G"]["ParticleEffect"] = "f";
luapad._sG["_G"]["setfenv"] = "f";
luapad._sG["_G"]["MakeWireSpeedometer"] = "f";
luapad._sG["_G"]["MakeWireDataPlug"] = "f";
luapad._sG["_G"]["WireToolMakeDigitalScreen"] = "f";
luapad._sG["_G"]["SetGlobalEntity"] = "f";
luapad._sG["_G"]["GetGlobalEntity"] = "f";
luapad._sG["_G"]["Add_TextReceiver"] = "f";
luapad._sG["_G"]["MakeWireLamp"] = "f";
luapad._sG["_G"]["MakeWireRanger"] = "f";
luapad._sG["_G"]["CCSpawn"] = "f";
luapad._sG["_G"]["MakeWireDupePort"] = "f";
luapad._sG["_G"]["MakeWireEmitter"] = "f";
luapad._sG["_G"]["WireToolMakeOscilloscope"] = "f";
luapad._sG["_G"]["MakeWireFXEmitter"] = "f";
luapad._sG["_G"]["registerBone"] = "f";
luapad._sG["_G"]["Wire_ApplyDupeInfo"] = "f";
luapad._sG["_G"]["CheckPropSolid"] = "f";
luapad._sG["_G"]["WireToolMakePanel"] = "f";
luapad._sG["_G"]["MakeWireUseHoloemitter"] = "f";
luapad._sG["_G"]["MakeWireMaterializer"] = "f";
luapad._sG["_G"]["Format"] = "f";
luapad._sG["_G"]["GetBuddyFinder"] = "f";
luapad._sG["_G"]["NullEntity"] = "f";
luapad._sG["_G"]["SortedPairsByValue"] = "f";
luapad._sG["_G"]["MakeWireUser"] = "f";
luapad._sG["_G"]["e2_extpp_pass1"] = "f";
luapad._sG["_G"]["WireToolMakeAdvInput"] = "f";
luapad._sG["_G"]["MakeWirePID"] = "f";
luapad._sG["_G"]["MakeWireLatchController"] = "f";
luapad._sG["_G"]["SinglePlayer"] = "f";
luapad._sG["_G"]["MakeWireBeamReader"] = "f";
luapad._sG["_G"]["makedoor"] = "f";
luapad._sG["_G"]["MakeWireTurret"] = "f";
luapad._sG["_G"]["IsPhysicsObject"] = "f";
luapad._sG["_G"]["Vertex"] = "f";
luapad._sG["_G"]["DeriveGamemode"] = "f";
luapad._sG["_G"]["Wire_TriggerOutput"] = "f";
luapad._sG["_G"]["setmetatable"] = "f";
luapad._sG["_G"]["getmetatable"] = "f";
luapad._sG["_G"]["rawset"] = "f";
luapad._sG["_G"]["MakeWireRelay"] = "f";
luapad._sG["_G"]["MakeWireTargetFinderBeta"] = "f";
luapad._sG["_G"]["CCTestNotifier"] = "f";
luapad._sG["_G"]["MakeWireRamCardReader"] = "f";
luapad._sG["_G"]["CC_Face_Randomize"] = "f";
luapad._sG["_G"]["CCResetUnit"] = "f";
luapad._sG["_G"]["MakeWireWaypoint"] = "f";
luapad._sG["_G"]["CurTime"] = "f";
luapad._sG["_G"]["e2_processerror"] = "f";
luapad._sG["_G"]["MakeWireGateExpressionParser"] = "f";
luapad._sG["_G"]["WireToolMakeDualInput"] = "f";
luapad._sG["_G"]["WireGateExpressionRecvPacket"] = "f";
luapad._sG["_G"]["Radio_GetTwoWayID"] = "f";
luapad._sG["_G"]["MakeLamp"] = "f";
luapad._sG["_G"]["MakeTurret"] = "f";
luapad._sG["_G"]["MakeWireHydraulicController"] = "f";
luapad._sG["_G"]["MakeWirePainter"] = "f";
luapad._sG["_G"]["SuppressHostEvents"] = "f";
luapad._sG["_G"]["MakeWireReader"] = "f";
luapad._sG["_G"]["MakeNoCollideController"] = "f";
luapad._sG["_G"]["MakeWireIndicator"] = "f";
luapad._sG["_G"]["GetWorldEntity"] = "f";
luapad._sG["_G"]["MakeWireDualInput"] = "f";
luapad._sG["_G"]["PC_AskForPort"] = "f";
luapad._sG["_G"]["e2_extpp_pass2"] = "f";
luapad._sG["_G"]["MakeWireXYZBeacon"] = "f";
luapad._sG["_G"]["GetGlobalBeamEntity"] = "f";
luapad._sG["_G"]["MakeWireSocket"] = "f";
luapad._sG["_G"]["e2_get_typeid"] = "f";
luapad._sG["_G"]["HSVToColor"] = "f";
luapad._sG["_G"]["RealTime"] = "f";
luapad._sG["_G"]["MakeLight"] = "f";
luapad._sG["_G"]["UnPredictedCurTime"] = "f";
luapad._sG["_G"]["gcinfo"] = "f";
luapad._sG["_G"]["HSHoloInteract"] = "f";
luapad._sG["_G"]["WireToolMakeEmitter"] = "f";
luapad._sG["_G"]["Wire_Link_Clear"] = "f";
luapad._sG["_G"]["WireToolMakePixel"] = "f";
luapad._sG["_G"]["MakeWireHydraulic"] = "f";
luapad._sG["_G"]["next"] = "f";
luapad._sG["_G"]["VectorRand"] = "f";
luapad._sG["_G"]["select"] = "f";
luapad._sG["_G"]["CCAnswer"] = "f";
luapad._sG["_G"]["FrameTime"] = "f";
luapad._sG["_G"]["GetGlobalBeamBool"] = "f";
luapad._sG["_G"]["KeyValuesToTablePreserveOrder"] = "f";
luapad._sG["_G"]["e2_install_hook_fix"] = "f";
luapad._sG["_G"]["ServerLog"] = "f";
luapad._sG["_G"]["MakeWireDetonator"] = "f";
luapad._sG["_G"]["ParticleEffectAttach"] = "f";
luapad._sG["_G"]["SafeRemoveEntity"] = "f";
luapad._sG["_G"]["CCAck"] = "f";
luapad._sG["_G"]["DoPlayerEntitySpawn"] = "f";
luapad._sG["_G"]["unpack"] = "f";
luapad._sG["_G"]["MakeWireHoloemitter"] = "f";
luapad._sG["_G"]["MakeWireGPS"] = "f";
luapad._sG["_G"]["WireToolMakeLamp"] = "f";
luapad._sG["_G"]["rawget"] = "f";
luapad._sG["_G"]["MakeWireHudIndicator"] = "f";
luapad._sG["_G"]["CreateSound"] = "f";
luapad._sG["_G"]["WireToolMakeConsoleScreen"] = "f";
luapad._sG["_G"]["engineCommandComplete"] = "f";
luapad._sG["_G"]["IsValid"] = "f";
luapad._sG["_G"]["WorldSound"] = "f";
luapad._sG["_G"]["MakeWireImplanter"] = "f";
luapad._sG["_G"]["EffectData"] = "f";
luapad._sG["_G"]["OrderVectors"] = "f";
luapad._sG["_G"]["MakeWireRTCam"] = "f";
luapad._sG["_G"]["WireGPU_AddMonitor"] = "f";
luapad._sG["_G"]["MakeWireGyroscope"] = "f";
luapad._sG["_G"]["DamageInfo"] = "f";
luapad._sG["_G"]["GetAddonList"] = "f";
luapad._sG["_G"]["print_r"] = "f";
luapad._sG["_G"]["Wire_Link_End"] = "f";
luapad._sG["_G"]["WireToolMakeHoloGrid"] = "f";
luapad._sG["_G"]["QuaternionSlerp"] = "f";
luapad._sG["_G"]["switch"] = "f";
luapad._sG["_G"]["tablevalues"] = "f";
luapad._sG["_G"]["MakeWirePod"] = "f";
luapad._sG["_G"]["MakeWirePanel"] = "f";
luapad._sG["_G"]["GetWirelessSrv"] = "f";
luapad._sG["_G"]["HoloInteract"] = "f";
luapad._sG["_G"]["MakeWireKeycard"] = "f";
luapad._sG["_G"]["MakeWireWheel"] = "f";
luapad._sG["_G"]["MakeNail"] = "f";
luapad._sG["_G"]["MakeWireScreen"] = "f";
luapad._sG["_G"]["MakeWirePixel"] = "f";
luapad._sG["_G"]["BTClientUpdateMessage"] = "f";
luapad._sG["_G"]["MakeWireOscilloscope"] = "f";
luapad._sG["_G"]["WireToolMakeExplosivesSimple"] = "f";
luapad._sG["_G"]["MakeWireLight"] = "f";
luapad._sG["_G"]["Wire_KeyPressed"] = "f";
luapad._sG["_G"]["Wire_KeyOff"] = "f";
luapad._sG["_G"]["MakeWireInput"] = "f";
luapad._sG["_G"]["MakeWire7Seg"] = "f";
luapad._sG["_G"]["PrecacheParticleSystem"] = "f";
luapad._sG["_G"]["MakeWireHologrid"] = "f";
luapad._sG["_G"]["Resend_GPU_Data"] = "f";
luapad._sG["_G"]["MakeWireGate"] = "f";
luapad._sG["_G"]["PCallError"] = "f";
luapad._sG["_G"]["validNPC"] = "f";
luapad._sG["_G"]["mess_with_args"] = "f";
luapad._sG["_G"]["pairs"] = "f";
luapad._sG["_G"]["Makewire_field_device"] = "f";
luapad._sG["_G"]["Egateglobalvarconnect"] = "f";
luapad._sG["_G"]["Egateglobalvardisconnect"] = "f";
luapad._sG["_G"]["freefallwiregates"] = "f";
luapad._sG["_G"]["exp2FindCleanup"] = "f";
luapad._sG["_G"]["Msg"] = "f";
luapad._sG["_G"]["getOwner"] = "f";
luapad._sG["_G"]["isOwner"] = "f";
luapad._sG["_G"]["validEntity"] = "f";
luapad._sG["_G"]["e2_remove_hook_fix"] = "f";
luapad._sG["_G"]["Exp2TextReceiving"] = "f";
luapad._sG["_G"]["WireToolMakeAdvPod"] = "f";
luapad._sG["_G"]["registerCallback"] = "f";
luapad._sG["_G"]["registerType"] = "f";
luapad._sG["_G"]["MakeWireDigitalScreen"] = "f";
luapad._sG["_G"]["MakeWireconsoleScreen"] = "f";
luapad._sG["_G"]["MakeWireButton"] = "f";
luapad._sG["_G"]["MakeWireAdvPod"] = "f";
luapad._sG["_G"]["InfuseSpecialOutputs"] = "f";
luapad._sG["_G"]["RingsNamingCallback"] = "f";
luapad._sG["_G"]["CC_GMOD_Tool"] = "f";
luapad._sG["_G"]["MakeWheel"] = "f";
luapad._sG["_G"]["MakeThruster"] = "f";
luapad._sG["_G"]["MakeSpawner"] = "f";
luapad._sG["_G"]["UpdateRenderTarget"] = "f";
luapad._sG["_G"]["MakeWireWeight"] = "f";
luapad._sG["_G"]["MakeHoverBall"] = "f";
luapad._sG["_G"]["MakeEmitter"] = "f";
luapad._sG["_G"]["MakeButton"] = "f";
luapad._sG["_G"]["PlayerDataUpdate"] = "f";
luapad._sG["_G"]["isDedicatedServer"] = "f";
luapad._sG["_G"]["MakeCont"] = "f";
luapad._sG["_G"]["ConditionName"] = "f";
luapad._sG["_G"]["ValidEntity"] = "f";
luapad._sG["_G"]["HTTPGet"] = "f";
luapad._sG["_G"]["MakeWireUserReader"] = "f";
luapad._sG["_G"]["MakeWireTargetFilter"] = "f";
luapad._sG["_G"]["MakeWireRangerBeta"] = "f";
luapad._sG["_G"]["MakeWireMotorController"] = "f";
luapad._sG["_G"]["MakeWireMicrophone"] = "f";
luapad._sG["_G"]["MakeWireMagnet"] = "f";
luapad._sG["_G"]["MakeWireKeycardReader"] = "f";
luapad._sG["_G"]["MakeWireHSRanger"] = "f";
luapad._sG["_G"]["MakeRadioSystems"] = "f";
luapad._sG["_G"]["MakeWireFreezerController"] = "f";
luapad._sG["_G"]["CreateDebugBuddy"] = "f";
luapad._sG["_G"]["ColorClamp"] = "f";
luapad._sG["_G"]["MakeWirefacer"] = "f";
luapad._sG["_G"]["MakeWireDynMemory"] = "f";
luapad._sG["_G"]["MakeWireDetcord"] = "f";
luapad._sG["_G"]["CCToggleDebug"] = "f";
luapad._sG["_G"]["MakeWirebtsrv"] = "f";
luapad._sG["_G"]["SetupWireGateExpression"] = "f";
luapad._sG["_G"]["MakeWirebtrecv"] = "f";
luapad._sG["_G"]["MakeWireAdvHudIndicator"] = "f";
luapad._sG["_G"]["MakeWireHSHoloemitter"] = "f";
luapad._sG["_G"]["SetGlobalFloat"] = "f";
luapad._sG["_G"]["MakeScaleEnt"] = "f";
luapad._sG["_G"]["MakeWireAdvInput"] = "f";
luapad._sG["_G"]["MakeWireWinch"] = "f";
luapad._sG["_G"]["MakeWireWinchController"] = "f";
luapad._sG["_G"]["MakeWireVectorThruster"] = "f";
luapad._sG["_G"]["MakeWireVehicle"] = "f";
luapad._sG["_G"]["MakeWireValue"] = "f";
luapad._sG["_G"]["MakeWireTrail"] = "f";
luapad._sG["_G"]["MakeWireReceiver"] = "f";
luapad._sG["_G"]["MakeWireTargetFinder"] = "f";
luapad._sG["_G"]["MakeWireSpawner"] = "f";
luapad._sG["_G"]["MakeWireOutput"] = "f";
luapad._sG["_G"]["MakeWireRadio"] = "f";
luapad._sG["_G"]["MakeWireNumpad"] = "f";
luapad._sG["_G"]["MakeWireNailer"] = "f";
luapad._sG["_G"]["MakeWireLatch"] = "f";
luapad._sG["_G"]["MakeWireLaserReciever"] = "f";
luapad._sG["_G"]["MakeWireKeyboard"] = "f";
luapad._sG["_G"]["MakeWireIgniter"] = "f";
luapad._sG["_G"]["GetGlobalFloat"] = "f";
luapad._sG["_G"]["Radio_Unregister"] = "f";
luapad._sG["_G"]["MakeWireGpu"] = "f";
luapad._sG["_G"]["MakeBomb"] = "f";
luapad._sG["_G"]["Error"] = "f";
luapad._sG["_G"]["MakeWireForcer"] = "f";
luapad._sG["_G"]["MakeWireExplosive"] = "f";
luapad._sG["_G"]["UpdateWireExplosive"] = "f";
luapad._sG["_G"]["MakeWireEmarker"] = "f";
luapad._sG["_G"]["EntityMarker_Removed"] = "f";
luapad._sG["_G"]["Add_EntityMarker"] = "f";
luapad._sG["_G"]["DebuggerThink"] = "f";
luapad._sG["_G"]["MakeWireTransferer"] = "f";
luapad._sG["_G"]["MakeWireStore"] = "f";
luapad._sG["_G"]["MakeWireDataPort"] = "f";
luapad._sG["_G"]["MakeWireDataSocket"] = "f";
luapad._sG["_G"]["MakeWireColorer"] = "f";
luapad._sG["_G"]["MakeWireCDLock"] = "f";
luapad._sG["_G"]["VGUIFrameTime"] = "f";
luapad._sG["_G"]["MakeWireCDRay"] = "f";
luapad._sG["_G"]["MakeWireCam"] = "f";
luapad._sG["_G"]["MakeWireAddressBus"] = "f";
luapad._sG["_G"]["HoloRightClick"] = "f";
luapad._sG["_G"]["WireToolMakeWeight"] = "f";
luapad._sG["_G"]["WireToolMakeInput"] = "f";
luapad._sG["_G"]["WireToolMakeButton"] = "f";
luapad._sG["_G"]["e2_parse_args"] = "f";
luapad._sG["_G"]["WireToolMakeTextScreen"] = "f";
luapad._sG["_G"]["WireToolMakeScreen"] = "f";
luapad._sG["_G"]["WireToolMakeLight"] = "f";
luapad._sG["_G"]["tonumber"] = "f";
luapad._sG["_G"]["WireToolMakeIndicator"] = "f";
luapad._sG["_G"]["WireToolMake7Seg"] = "f";
luapad._sG["_G"]["Wire_Restored"] = "f";
luapad._sG["_G"]["WireToolMakeSpeedometer"] = "f";
luapad._sG["_G"]["RunString"] = "f";
luapad._sG["_G"]["WireToolMakeGate"] = "f";
luapad._sG["_G"]["VerifyWireGateExpression"] = "f";
luapad._sG["_G"]["CCSpawnVehicle"] = "f";
luapad._sG["_G"]["CCSpawnSWEP"] = "f";
luapad._sG["_G"]["CCGiveSWEP"] = "f";
luapad._sG["_G"]["GMODSpawnEffect"] = "f";
luapad._sG["_G"]["FixInvalidPhysicsObject"] = "f";
luapad._sG["_G"]["IsEntity"] = "f";
luapad._sG["_G"]["NotifierSetSilent"] = "f";
luapad._sG["_G"]["MakeProp"] = "f";
luapad._sG["_G"]["GMODSpawnRagdoll"] = "f";
luapad._sG["_G"]["MaxPlayers"] = "f";
luapad._sG["_G"]["Wire_AfterPasteMods"] = "f";
luapad._sG["_G"]["Wire_SetPathNames"] = "f";
luapad._sG["_G"]["Wire_Link_Cancel"] = "f";
luapad._sG["_G"]["Wire_Link_Node"] = "f";
luapad._sG["_G"]["Wire_Remove"] = "f";
luapad._sG["_G"]["Wire_AdjustInputs"] = "f";
luapad._sG["_G"]["TextReceiver_Received"] = "f";
luapad._sG["_G"]["Radio_ChangeChannel"] = "f";
luapad._sG["_G"]["Radio_RecieveData"] = "f";
luapad._sG["_G"]["Radio_Register"] = "f";
luapad._sG["_G"]["CCPrivateMessage"] = "f";
luapad._sG["_G"]["DestroyDebugBuddy"] = "f";
luapad._sG["_G"]["SysTime"] = "f";
luapad._sG["_G"]["Entity"] = "f";
luapad._sG["_G"]["GetGlobalBeamString"] = "f";
luapad._sG["_G"]["SetGlobalBeamBool"] = "f";
luapad._sG["_G"]["SetGlobalBeamEntity"] = "f";
luapad._sG["_G"]["GetGlobalBeamInt"] = "f";
luapad._sG["_G"]["GetGlobalBeamFloat"] = "f";
luapad._sG["_G"]["GetGlobalBeamAngle"] = "f";
luapad._sG["_G"]["SetGlobalBeamAngle"] = "f";
luapad._sG["_G"]["GetGlobalBeamVector"] = "f";
luapad._sG["_G"]["SetGlobalBeamVector"] = "f";
luapad._sG["_G"]["PC_PortSelected"] = "f";
luapad._sG["_G"]["PC_BeamPorts"] = "f";
luapad._sG["_G"]["module"] = "f";
luapad._sG["_G"]["MakeWireGateExpression"] = "f";
luapad._sG["_G"]["Color"] = "f";
luapad._sG["_G"]["getfenv"] = "f";
luapad._sG["_G"]["QuaternionNLerp"] = "f";
luapad._sG["_G"]["Dbg"] = "f";
luapad._sG["_G"]["NotifierSetConsole"] = "f";
luapad._sG["_G"]["SortedPairs"] = "f";
luapad._sG["_G"]["MeshQuad"] = "f";
luapad._sG["_G"]["MeshCube"] = "f";
luapad._sG["_G"]["xpcall"] = "f";
luapad._sG["_G"]["SendUserMessage"] = "f";
luapad._sG["_G"]["decode"] = "f";
luapad._sG["_G"]["TimedCos"] = "f";
luapad._sG["_G"]["TimedSin"] = "f";
luapad._sG["_G"]["STNDRD"] = "f";
luapad._sG["_G"]["RestoreCursorPosition"] = "f";
luapad._sG["_G"]["RememberCursorPosition"] = "f";
luapad._sG["_G"]["SafeRemoveEntityDelayed"] = "f";
luapad._sG["_G"]["tablekeys"] = "f";
luapad._sG["_G"]["AccessorFuncNW"] = "f";
luapad._sG["_G"]["AccessorFunc"] = "f";
luapad._sG["_G"]["UTIL_IsUselessModel"] = "f";
luapad._sG["_G"]["Model"] = "f";
luapad._sG["_G"]["Sound"] = "f";
luapad._sG["_G"]["PrintTable"] = "f";
luapad._sG["_G"]["error"] = "f";
luapad._sG["_G"]["MakeWireCDDisk"] = "f";
luapad._sG["_G"]["Wire_KeyOn"] = "f";
luapad._sG["_G"]["LerpVector"] = "f";
luapad._sG["_G"]["assert"] = "f";
luapad._sG["_G"]["GetMountedContent"] = "f";
luapad._sG["_G"]["MakeWireWatersensor"] = "f";
luapad._sG["_G"]["MakeWireCpu"] = "f";
luapad._sG["_G"]["Vector"] = "f";
luapad._sG["_G"]["RecipientFilter"] = "f";
luapad._sG["_G"]["GetConVar"] = "f";
luapad._sG["_G"]["PhysObject"] = "f";
luapad._sG["_G"]["GetGlobalString"] = "f";
luapad._sG["_G"]["GetHostName"] = "f";
luapad._sG["_G"]["GetGlobalVector"] = "f";
luapad._sG["_G"]["MakeWirehdd"] = "f";
luapad._sG["_G"]["GetGlobalVar"] = "f";
luapad._sG["_G"]["SetGlobalInt"] = "f";
luapad._sG["_G"]["SetGlobalVar"] = "f";
luapad._sG["_G"]["Angle"] = "f";
luapad._sG["_G"]["MakeNpc"] = "f";
luapad._sG["_G"]["HoloReload"] = "f";
luapad._sG["_G"]["SetPhysConstraintSystem"] = "f";
luapad._sG["_G"]["MakeBalloon"] = "f";
luapad._sG["_G"]["ClientCallGamemode"] = "f";
luapad._sG["_G"]["AddCSLuaFile"] = "f";
luapad._sG["_G"]["IsFirstTimePredicted"] = "f";
luapad._sG["_G"]["CreateClientConVar"] = "f";
luapad._sG["_G"]["PrecacheScene"] = "f";
luapad._sG["_G"]["LocalToWorld"] = "f";
luapad._sG["_G"]["Lerp"] = "f";
luapad._sG["_G"]["DropEntityIfHeld"] = "f";
luapad._sG["_G"]["MakeDynamite"] = "f";
luapad._sG["_G"]["KeyValuesToTable"] = "f";
luapad._sG["_G"]["CCDial"] = "f";
luapad._sG["_G"]["RunConsoleCommand"] = "f";
luapad._sG["_G"]["CreateConVar"] = "f";
luapad._sG["_G"]["FindMetaTable"] = "f";
luapad._sG["_G"]["ConVarExists"] = "f";
luapad._sG["_G"]["GetConVarString"] = "f";
luapad._sG["_G"]["GetAllEnts"] = "f";
luapad._sG["_G"]["include"] = "f";
luapad._sG["_G"]["ErrorNoHalt"] = "f";
luapad._sG["_G"]["MatrixFromAngle"] = "f";
luapad._sG["_G"]["ModelPlug_Register"] = "f";
luapad._sG["_G"]["MakeWireExpression2"] = "f";
luapad._sG["_G"]["Wire_CreateOutputIterator"] = "f";
luapad._sG["_G"]["tostring"] = "f";
luapad._sG["_G"]["MakeWireNotifier"] = "f";
luapad._sG["_G"]["GetGamemodes"] = "f";
luapad._sG["_G"]["DoPropSpawnedEffect"] = "f";
luapad._sG["_G"]["RingsDiallingCallback"] = "f";
luapad._sG["_G"]["LerpAngle"] = "f";
luapad._sG["_G"]["BroadcastLua"] = "f";
luapad._sG["_G"]["MakeWireSatellitedish"] = "f";
luapad._sG["_G"]["print"] = "f";
luapad._sG["_G"]["MakeWiredatarate"] = "f";
luapad._sG["_G"]["Wire_AdjustOutputs"] = "f";
luapad._sG["_G"]["SoundDuration"] = "f";
luapad._sG["_G"]["GetMountableContent"] = "f";
luapad._sG["_G"]["WireExpressionGetLines"] = "f";
luapad._sG["_G"]["MakeWireStringBuffer"] = "f";
luapad._sG["_G"]["MakeWireSimpleExplosive"] = "f";
luapad._sG["_G"]["CreateClient"] = "f";
luapad._sG["_G"]["MakeWireServo"] = "f";
luapad._sG["_G"]["require"] = "f";
luapad._sG["_G"]["Wire_Link_Start"] = "f";
luapad._sG["_G"]["MakeWireGraphicsTablet"] = "f";
luapad._sG["_G"]["Player"] = "f";
luapad._sG["_G"]["engineConsoleCommand"] = "f";
luapad._sG["_G"]["WireToolMakeWheel"] = "f";
luapad._sG["_G"]["MakeWireThruster"] = "f";
luapad._sG["_G"]["tobool"] = "f";
luapad._sG["_G"]["type"] = "f";
luapad._sG["_G"]["checkEntity"] = "f";
luapad._sG["_G"]["StringExplode"] = "f";
luapad._sG["_G"]["IsVector"] = "f";
luapad._sG["_G"]["Wire_CreateInputs"] = "f";
luapad._sG["_G"]["GetTaskID"] = "f";
luapad._sG["_G"]["SortedPairsByMemberValue"] = "f";
luapad._sG["_G"]["___comp___"] = "f";
luapad._sG["_G"]["MakeWireSensor"] = "f";
luapad._sG["_G"]["WireToolMakeUseEmitter"] = "f";
luapad._sG["CatmullRomCams"]["AddLua"] = "f";
luapad._sG["debug"]["getupvalue"] = "f";
luapad._sG["debug"]["debug"] = "f";
luapad._sG["debug"]["getlocal"] = "f";
luapad._sG["debug"]["sethook"] = "f";
luapad._sG["debug"]["getmetatable"] = "f";
luapad._sG["debug"]["gethook"] = "f";
luapad._sG["debug"]["setmetatable"] = "f";
luapad._sG["debug"]["setlocal"] = "f";
luapad._sG["debug"]["traceback"] = "f";
luapad._sG["debug"]["setfenv"] = "f";
luapad._sG["debug"]["getinfo"] = "f";
luapad._sG["debug"]["setupvalue"] = "f";
luapad._sG["debug"]["Trace"] = "f";
luapad._sG["debug"]["getregistry"] = "f";
luapad._sG["debug"]["getfenv"] = "f";
luapad._sG["_R"]["25"] = "f";
luapad._sG["_R"]["57"] = "f";
luapad._sG["_R"]["62"] = "f";
luapad._sG["_R"]["94"] = "f";
luapad._sG["_R"]["123"] = "f";
luapad._sG["_R"]["137"] = "f";
luapad._sG["_R"]["155"] = "f";
luapad._sG["_R"]["202"] = "f";
luapad._sG["_R"]["226"] = "f";
luapad._sG["_R"]["270"] = "f";
luapad._sG["_R"]["324"] = "f";
luapad._sG["_R"]["330"] = "f";
luapad._sG["_R"]["437"] = "f";
luapad._sG["_R"]["461"] = "f";
luapad._sG["_R"]["464"] = "f";
luapad._sG["_R"]["475"] = "f";
luapad._sG["_R"]["555"] = "f";
luapad._sG["_R"]["562"] = "f";
luapad._sG["_R"]["591"] = "f";
luapad._sG["_R"]["626"] = "f";
luapad._sG["_R"]["643"] = "f";
luapad._sG["_R"]["683"] = "f";
luapad._sG["_R"]["689"] = "f";
luapad._sG["_R"]["815"] = "f";
luapad._sG["_R"]["831"] = "f";
luapad._sG["_R"]["884"] = "f";
luapad._sG["_R"]["933"] = "f";
luapad._sG["_R"]["975"] = "f";
luapad._sG["_R"]["1068"] = "f";
luapad._sG["_R"]["1079"] = "f";
luapad._sG["_R"]["1096"] = "f";
luapad._sG["usermessage"]["Hook"] = "f";
luapad._sG["usermessage"]["IncomingMessage"] = "f";
luapad._sG["hook"]["Call"] = "f";
luapad._sG["hook"]["Remove"] = "f";
luapad._sG["hook"]["GetTable"] = "f";
luapad._sG["hook"]["Add"] = "f";
luapad._sG["tablex"]["getn"] = "f";
luapad._sG["tablex"]["remove"] = "f";
luapad._sG["tablex"]["ForceInsert"] = "f";
luapad._sG["tablex"]["Empty"] = "f";
luapad._sG["tablex"]["GetWinningKey"] = "f";
luapad._sG["tablex"]["insert"] = "f";
luapad._sG["tablex"]["MaxVal"] = "f";
luapad._sG["tablex"]["GetLastValue"] = "f";
luapad._sG["tablex"]["maxn"] = "f";
luapad._sG["tablex"]["MinVal"] = "f";
luapad._sG["tablex"]["concat"] = "f";
luapad._sG["tablex"]["HasKey"] = "f";
luapad._sG["tablex"]["Sanitise"] = "f";
luapad._sG["tablex"]["Add"] = "f";
luapad._sG["tablex"]["LowerKeyNames"] = "f";
luapad._sG["tablex"]["MakeSortedKeys"] = "f";
luapad._sG["tablex"]["Compact"] = "f";
luapad._sG["tablex"]["SortByMember"] = "f";
luapad._sG["tablex"]["TotalVal"] = "f";
luapad._sG["tablex"]["foreachi"] = "f";
luapad._sG["tablex"]["AllNumerical"] = "f";
luapad._sG["tablex"]["Copy"] = "f";
luapad._sG["tablex"]["SortByKey"] = "f";
luapad._sG["tablex"]["FindPrev"] = "f";
luapad._sG["tablex"]["FindNext"] = "f";
luapad._sG["tablex"]["GetLastKey"] = "f";
luapad._sG["tablex"]["Random"] = "f";
luapad._sG["tablex"]["GetFirstValue"] = "f";
luapad._sG["tablex"]["GetFirstKey"] = "f";
luapad._sG["tablex"]["ClearKeys"] = "f";
luapad._sG["tablex"]["setn"] = "f";
luapad._sG["tablex"]["CollapseKeyValue"] = "f";
luapad._sG["tablex"]["sortdesc"] = "f";
luapad._sG["tablex"]["DeSanitise"] = "f";
luapad._sG["tablex"]["PartialVal"] = "f";
luapad._sG["tablex"]["ToString"] = "f";
luapad._sG["tablex"]["HasValue"] = "f";
luapad._sG["tablex"]["foreach"] = "f";
luapad._sG["tablex"]["Count"] = "f";
luapad._sG["tablex"]["Inherit"] = "f";
luapad._sG["tablex"]["sort"] = "f";
luapad._sG["tablex"]["CopyFromTo"] = "f";
luapad._sG["tablex"]["IsSequential"] = "f";
luapad._sG["tablex"]["Merge"] = "f";
luapad._sG["coroutine"]["resume"] = "f";
luapad._sG["coroutine"]["yield"] = "f";
luapad._sG["coroutine"]["status"] = "f";
luapad._sG["coroutine"]["wrap"] = "f";
luapad._sG["coroutine"]["create"] = "f";
luapad._sG["coroutine"]["running"] = "f";
luapad._sG["PLUGIN"]["Hook"] = "f";
luapad._sG["PLUGIN"]["AfterLoad"] = "f";
luapad._sG["PLUGIN"]["BeforeLoad"] = "f";
luapad._sG["PLUGIN"]["IsDarkRP"] = "f";
luapad._sG["PLUGIN"]["SetupJob"] = "f";
luapad._sG["PreProcessor"]["Execute"] = "f";
luapad._sG["PreProcessor"]["ParsePorts"] = "f";
luapad._sG["PreProcessor"]["Error"] = "f";
luapad._sG["PreProcessor"]["Process"] = "f";
luapad._sG["list"]["Add"] = "f";
luapad._sG["list"]["Set"] = "f";
luapad._sG["list"]["GetForEdit"] = "f";
luapad._sG["list"]["Get"] = "f";
luapad._sG["WireGateExpressionParser"]["Expect"] = "f";
luapad._sG["WireGateExpressionParser"]["GetInstructions"] = "f";
luapad._sG["WireGateExpressionParser"]["expr11"] = "f";
luapad._sG["WireGateExpressionParser"]["expr5"] = "f";
luapad._sG["WireGateExpressionParser"]["ParsePorts"] = "f";
luapad._sG["WireGateExpressionParser"]["expr7"] = "f";
luapad._sG["WireGateExpressionParser"]["NextSymbol"] = "f";
luapad._sG["WireGateExpressionParser"]["GetInputs"] = "f";
luapad._sG["WireGateExpressionParser"]["ParseSymbols"] = "f";
luapad._sG["WireGateExpressionParser"]["GetError"] = "f";
luapad._sG["WireGateExpressionParser"]["expr3"] = "f";
luapad._sG["WireGateExpressionParser"]["expr14"] = "f";
luapad._sG["WireGateExpressionParser"]["expr9"] = "f";
luapad._sG["WireGateExpressionParser"]["expr4"] = "f";
luapad._sG["WireGateExpressionParser"]["Error"] = "f";
luapad._sG["WireGateExpressionParser"]["expr2"] = "f";
luapad._sG["WireGateExpressionParser"]["GetIndexTable"] = "f";
luapad._sG["WireGateExpressionParser"]["expr6"] = "f";
luapad._sG["WireGateExpressionParser"]["GetOutputs"] = "f";
luapad._sG["WireGateExpressionParser"]["expr15"] = "f";
luapad._sG["WireGateExpressionParser"]["expr13"] = "f";
luapad._sG["WireGateExpressionParser"]["GetLocals"] = "f";
luapad._sG["WireGateExpressionParser"]["Accept"] = "f";
luapad._sG["WireGateExpressionParser"]["ReadCharacter"] = "f";
luapad._sG["WireGateExpressionParser"]["expr16"] = "f";
luapad._sG["WireGateExpressionParser"]["expr1"] = "f";
luapad._sG["WireGateExpressionParser"]["RecurseRight"] = "f";
luapad._sG["WireGateExpressionParser"]["expr10"] = "f";
luapad._sG["WireGateExpressionParser"]["NextCharacter"] = "f";
luapad._sG["WireGateExpressionParser"]["RecurseLeft"] = "f";
luapad._sG["WireGateExpressionParser"]["expr12"] = "f";
luapad._sG["WireGateExpressionParser"]["ParseOperator"] = "f";
luapad._sG["WireGateExpressionParser"]["expr8"] = "f";
luapad._sG["WireGateExpressionParser"]["New"] = "f";
luapad._sG["PCMod"]["CanQuickType"] = "f";
luapad._sG["PCMod"]["SplitString"] = "f";
luapad._sG["PCMod"]["StringToTable"] = "f";
luapad._sG["PCMod"]["PC_Stream"] = "f";
luapad._sG["PCMod"]["SetDevParam"] = "f";
luapad._sG["PCMod"]["MakeScreenSpace"] = "f";
luapad._sG["PCMod"]["ReloadOS"] = "f";
luapad._sG["PCMod"]["SendPopupNotice"] = "f";
luapad._sG["PCMod"]["CallHook"] = "f";
luapad._sG["PCMod"]["PlayerSay"] = "f";
luapad._sG["PCMod"]["Warning"] = "f";
luapad._sG["PCMod"]["CommitLog"] = "f";
luapad._sG["PCMod"]["CompareString"] = "f";
luapad._sG["PCMod"]["Locked"] = "f";
luapad._sG["PCMod"]["TableToString"] = "f";
luapad._sG["PCMod"]["PC_Command"] = "f";
luapad._sG["PCMod"]["GMsg"] = "f";
luapad._sG["PCMod"]["BTN"] = "f";
luapad._sG["PCMod"]["PC_QuickType"] = "f";
luapad._sG["PCMod"]["Error"] = "f";
luapad._sG["PCMod"]["KeyPress"] = "f";
luapad._sG["PCMod"]["CleanString"] = "f";
luapad._sG["PCMod"]["Msg"] = "f";
luapad._sG["PCMod"]["LoadDriver"] = "f";
luapad._sG["PCMod"]["LoadAllDrivers"] = "f";
luapad._sG["PCMod"]["RestoreTable"] = "f";
luapad._sG["PCMod"]["DeriveDriver"] = "f";
luapad._sG["PCMod"]["RegisterPlugin"] = "f";
luapad._sG["PCMod"]["Notice"] = "f";
luapad._sG["PCMod"]["RestoreString"] = "f";
luapad._sG["PCMod"]["SaveLogPre"] = "f";
luapad._sG["PCMod"]["AddLog"] = "f";
luapad._sG["PCMod"]["SaveLog"] = "f";
luapad._sG["PCMod"]["PC_Run"] = "f";
luapad._sG["PCMod"]["ViewModelPos"] = "f";
luapad._sG["PCMod"]["GetSvSMessages"] = "f";
luapad._sG["WireLib"]["Link_Start"] = "f";
luapad._sG["WireLib"]["Link_Node"] = "f";
luapad._sG["WireLib"]["CreateSpecialInputs"] = "f";
luapad._sG["WireLib"]["AfterPasteMods"] = "f";
luapad._sG["WireLib"]["SetPathNames"] = "f";
luapad._sG["WireLib"]["ApplyDupeInfo"] = "f";
luapad._sG["WireLib"]["Weld"] = "f";
luapad._sG["WireLib"]["AdjustSpecialInputs"] = "f";
luapad._sG["WireLib"]["CreateOutputIterator"] = "f";
luapad._sG["WireLib"]["AdjustInputs"] = "f";
luapad._sG["WireLib"]["Link_End"] = "f";
luapad._sG["WireLib"]["Link_Clear"] = "f";
luapad._sG["WireLib"]["CreateInputs"] = "f";
luapad._sG["WireLib"]["Link_Cancel"] = "f";
luapad._sG["WireLib"]["TriggerOutput"] = "f";
luapad._sG["WireLib"]["Remove"] = "f";
luapad._sG["WireLib"]["Restored"] = "f";
luapad._sG["WireLib"]["RetypeInputs"] = "f";
luapad._sG["WireLib"]["AdjustSpecialOutputs"] = "f";
luapad._sG["WireLib"]["AdjustOutputs"] = "f";
luapad._sG["WireLib"]["RetypeOutputs"] = "f";
luapad._sG["WireLib"]["BuildDupeInfo"] = "f";
luapad._sG["WireLib"]["CreateSpecialOutputs"] = "f";
luapad._sG["WireLib"]["CreateOutputs"] = "f";
luapad._sG["saverestore"]["ReadTable"] = "f";
luapad._sG["saverestore"]["AddSaveHook"] = "f";
luapad._sG["saverestore"]["PreRestore"] = "f";
luapad._sG["saverestore"]["PreSave"] = "f";
luapad._sG["saverestore"]["SaveGlobal"] = "f";
luapad._sG["saverestore"]["ReadVar"] = "f";
luapad._sG["saverestore"]["LoadEntity"] = "f";
luapad._sG["saverestore"]["AddRestoreHook"] = "f";
luapad._sG["saverestore"]["SaveEntity"] = "f";
luapad._sG["saverestore"]["WritableKeysInTable"] = "f";
luapad._sG["saverestore"]["WriteTable"] = "f";
luapad._sG["saverestore"]["WriteVar"] = "f";
luapad._sG["saverestore"]["LoadGlobal"] = "f";
luapad._sG["constraint"]["RemoveAll"] = "f";
luapad._sG["constraint"]["Hydraulic"] = "f";
luapad._sG["constraint"]["Elastic"] = "f";
luapad._sG["constraint"]["Pulley"] = "f";
luapad._sG["constraint"]["Keepupright"] = "f";
luapad._sG["constraint"]["ForgetConstraints"] = "f";
luapad._sG["constraint"]["Muscle"] = "f";
luapad._sG["constraint"]["Axis"] = "f";
luapad._sG["constraint"]["CanConstrain"] = "f";
luapad._sG["constraint"]["FindConstraints"] = "f";
luapad._sG["constraint"]["Weld"] = "f";
luapad._sG["constraint"]["FindConstraint"] = "f";
luapad._sG["constraint"]["GetTable"] = "f";
luapad._sG["constraint"]["Ballsocket"] = "f";
luapad._sG["constraint"]["RemoveConstraints"] = "f";
luapad._sG["constraint"]["AddConstraintTableNoDelete"] = "f";
luapad._sG["constraint"]["NoCollide"] = "f";
luapad._sG["constraint"]["Winch"] = "f";
luapad._sG["constraint"]["FindConstraintEntity"] = "f";
luapad._sG["constraint"]["Motor"] = "f";
luapad._sG["constraint"]["Find"] = "f";
luapad._sG["constraint"]["HasConstraints"] = "f";
luapad._sG["constraint"]["AddConstraintTable"] = "f";
luapad._sG["constraint"]["AdvBallsocket"] = "f";
luapad._sG["constraint"]["CreateKeyframeRope"] = "f";
luapad._sG["constraint"]["Rope"] = "f";
luapad._sG["constraint"]["GetAllConstrainedEntities"] = "f";
luapad._sG["constraint"]["CreateStaticAnchorPoint"] = "f";
luapad._sG["constraint"]["Slider"] = "f";
luapad._sG["os"]["clock"] = "f";
luapad._sG["os"]["difftime"] = "f";
luapad._sG["os"]["time"] = "f";
luapad._sG["os"]["date"] = "f";
luapad._sG["construct"]["Magnet"] = "f";
luapad._sG["construct"]["SetPhysProp"] = "f";
luapad._sG["Parser"]["Expr2"] = "f";
luapad._sG["Parser"]["IfCond"] = "f";
luapad._sG["Parser"]["Process"] = "f";
luapad._sG["Parser"]["AcceptLeadingToken"] = "f";
luapad._sG["Parser"]["Expr6"] = "f";
luapad._sG["Parser"]["Stmt4"] = "f";
luapad._sG["Parser"]["IfElse"] = "f";
luapad._sG["Parser"]["GetToken"] = "f";
luapad._sG["Parser"]["GetTokenData"] = "f";
luapad._sG["Parser"]["Expr1"] = "f";
luapad._sG["Parser"]["Expr10"] = "f";
luapad._sG["Parser"]["GetTokenTrace"] = "f";
luapad._sG["Parser"]["Expr12"] = "f";
luapad._sG["Parser"]["Error"] = "f";
luapad._sG["Parser"]["Execute"] = "f";
luapad._sG["Parser"]["Expr11"] = "f";
luapad._sG["Parser"]["Stmt2"] = "f";
luapad._sG["Parser"]["Instruction"] = "f";
luapad._sG["Parser"]["ExprError"] = "f";
luapad._sG["Parser"]["Expr7"] = "f";
luapad._sG["Parser"]["IfElseIf"] = "f";
luapad._sG["Parser"]["Expr15"] = "f";
luapad._sG["Parser"]["Expr5"] = "f";
luapad._sG["Parser"]["Expr13"] = "f";
luapad._sG["Parser"]["Stmts"] = "f";
luapad._sG["Parser"]["Expr4"] = "f";
luapad._sG["Parser"]["AcceptTailingToken"] = "f";
luapad._sG["Parser"]["Expr8"] = "f";
luapad._sG["Parser"]["Stmt5"] = "f";
luapad._sG["Parser"]["Root"] = "f";
luapad._sG["Parser"]["Expr3"] = "f";
luapad._sG["Parser"]["Expr14"] = "f";
luapad._sG["Parser"]["Expr9"] = "f";
luapad._sG["Parser"]["HasTokens"] = "f";
luapad._sG["Parser"]["AcceptRoamingToken"] = "f";
luapad._sG["Parser"]["RecurseLeft"] = "f";
luapad._sG["Parser"]["Stmt1"] = "f";
luapad._sG["Parser"]["IfBlock"] = "f";
luapad._sG["Parser"]["TrackBack"] = "f";
luapad._sG["Parser"]["Stmt3"] = "f";
luapad._sG["Parser"]["NextToken"] = "f";
luapad._sG["util"]["Decal"] = "f";
luapad._sG["util"]["CRC"] = "f";
luapad._sG["util"]["IsValidModel"] = "f";
luapad._sG["util"]["TraceEntityHull"] = "f";
luapad._sG["util"]["LocalToWorld"] = "f";
luapad._sG["util"]["tobool"] = "f";
luapad._sG["util"]["DecalMaterial"] = "f";
luapad._sG["util"]["QuickTrace"] = "f";
luapad._sG["util"]["GetPlayerTrace"] = "f";
luapad._sG["util"]["PrecacheSound"] = "f";
luapad._sG["util"]["BlastDamage"] = "f";
luapad._sG["util"]["PrecacheModel"] = "f";
luapad._sG["util"]["PointContents"] = "f";
luapad._sG["util"]["TableToKeyValues"] = "f";
luapad._sG["util"]["IsValidProp"] = "f";
luapad._sG["util"]["Effect"] = "f";
luapad._sG["util"]["RelativePathToFull"] = "f";
luapad._sG["util"]["SpriteTrail"] = "f";
luapad._sG["util"]["KeyValuesToTable"] = "f";
luapad._sG["util"]["GetModelInfo"] = "f";
luapad._sG["util"]["GetSurfaceIndex"] = "f";
luapad._sG["util"]["IsValidPhysicsObject"] = "f";
luapad._sG["util"]["IsInWorld"] = "f";
luapad._sG["util"]["TraceLine"] = "f";
luapad._sG["util"]["IsValidRagdoll"] = "f";
luapad._sG["util"]["TraceHull"] = "f";
luapad._sG["util"]["TraceEntity"] = "f";
luapad._sG["util"]["ScreenShake"] = "f";
luapad._sG["package"]["loadlib"] = "f";
luapad._sG["package"]["seeall"] = "f";
luapad._sG["ai_task"]["New"] = "f";
luapad._sG["server_settings"]["Bool"] = "f";
luapad._sG["server_settings"]["Int"] = "f";
luapad._sG["WireToolSetup"]["setCategory"] = "f";
luapad._sG["WireToolSetup"]["open"] = "f";
luapad._sG["WireToolSetup"]["close"] = "f";
luapad._sG["team"]["SetSpawnPoint"] = "f";
luapad._sG["team"]["GetScore"] = "f";
luapad._sG["team"]["GetAllTeams"] = "f";
luapad._sG["team"]["TotalDeaths"] = "f";
luapad._sG["team"]["GetPlayers"] = "f";
luapad._sG["team"]["Valid"] = "f";
luapad._sG["team"]["SetClass"] = "f";
luapad._sG["team"]["BestAutoJoinTeam"] = "f";
luapad._sG["team"]["TotalFrags"] = "f";
luapad._sG["team"]["AddScore"] = "f";
luapad._sG["team"]["SetScore"] = "f";
luapad._sG["team"]["GetName"] = "f";
luapad._sG["team"]["GetColor"] = "f";
luapad._sG["team"]["GetSpawnPoint"] = "f";
luapad._sG["team"]["GetSpawnPoints"] = "f";
luapad._sG["team"]["NumPlayers"] = "f";
luapad._sG["team"]["Joinable"] = "f";
luapad._sG["team"]["GetClass"] = "f";
luapad._sG["team"]["SetUp"] = "f";
luapad._sG["PCTool"]["SetLimit"] = "f";
luapad._sG["PCTool"]["SpawnEntity"] = "f";
luapad._sG["PCTool"]["RegisterSTool"] = "f";
luapad._sG["PCTool"]["GetCnt"] = "f";
luapad._sG["PCTool"]["GetCount"] = "f";
luapad._sG["concommand"]["Remove"] = "f";
luapad._sG["concommand"]["AutoComplete"] = "f";
luapad._sG["concommand"]["Run"] = "f";
luapad._sG["concommand"]["Add"] = "f";
luapad._sG["cvars"]["OnConVarChanged"] = "f";
luapad._sG["cvars"]["AddChangeCallback"] = "f";
luapad._sG["cvars"]["GetConVarCallbacks"] = "f";
luapad._sG["dupeshare"]["split"] = "f";
luapad._sG["dupeshare"]["RebuildTableFromLoad_Old"] = "f";
luapad._sG["dupeshare"]["FileNoOverWriteCheck"] = "f";
luapad._sG["dupeshare"]["ReplaceBadChar"] = "f";
luapad._sG["dupeshare"]["NamedLikeAPublicDir"] = "f";
luapad._sG["dupeshare"]["Compress"] = "f";
luapad._sG["dupeshare"]["UpDir"] = "f";
luapad._sG["dupeshare"]["ParsePath"] = "f";
luapad._sG["dupeshare"]["GetFileFromFilename"] = "f";
luapad._sG["dupeshare"]["RebuildTableFromLoad"] = "f";
luapad._sG["dupeshare"]["UnprotectCase"] = "f";
luapad._sG["dupeshare"]["DeCompress"] = "f";
luapad._sG["dupeshare"]["CurrentToolIsDuplicator"] = "f";
luapad._sG["dupeshare"]["GetPlayerName"] = "f";
luapad._sG["GAMEMODE"]["PlayerTraceAttack"] = "f";
luapad._sG["GAMEMODE"]["CanPlayerUnfreeze"] = "f";
luapad._sG["GAMEMODE"]["PlayerSpawnedRagdoll"] = "f";
luapad._sG["GAMEMODE"]["PlayerUnfrozeObject"] = "f";
luapad._sG["GAMEMODE"]["PlayerFootstep"] = "f";
luapad._sG["GAMEMODE"]["PlayerSpawnVehicle"] = "f";
luapad._sG["GAMEMODE"]["KeyRelease"] = "f";
luapad._sG["GAMEMODE"]["PlayerAuthed"] = "f";
luapad._sG["GAMEMODE"]["EntityTakeDamage"] = "f";
luapad._sG["GAMEMODE"]["PlayerInitialSpawn"] = "f";
luapad._sG["GAMEMODE"]["PlayerSetModel"] = "f";
luapad._sG["GAMEMODE"]["PlayerCanJoinTeam"] = "f";
luapad._sG["GAMEMODE"]["Restored"] = "f";
luapad._sG["GAMEMODE"]["OnPhysgunReload"] = "f";
luapad._sG["GAMEMODE"]["PlayerSwitchFlashlight"] = "f";
luapad._sG["GAMEMODE"]["CreateTeams"] = "f";
luapad._sG["GAMEMODE"]["PlayerSpawnedEffect"] = "f";
luapad._sG["GAMEMODE"]["ContextScreenClick"] = "f";
luapad._sG["GAMEMODE"]["Saved"] = "f";
luapad._sG["GAMEMODE"]["PlayerSpawnRagdoll"] = "f";
luapad._sG["GAMEMODE"]["CanTool"] = "f";
luapad._sG["GAMEMODE"]["SetPlayerAnimation"] = "f";
luapad._sG["GAMEMODE"]["PlayerSelectTeamSpawn"] = "f";
luapad._sG["GAMEMODE"]["PlayerFrozeObject"] = "f";
luapad._sG["GAMEMODE"]["PlayerHurt"] = "f";
luapad._sG["GAMEMODE"]["PlayerLoadout"] = "f";
luapad._sG["GAMEMODE"]["WeaponEquip"] = "f";
luapad._sG["GAMEMODE"]["PlayerSpawnEffect"] = "f";
luapad._sG["GAMEMODE"]["PlayerSpawnProp"] = "f";
luapad._sG["GAMEMODE"]["PlayerSpawn"] = "f";
luapad._sG["GAMEMODE"]["CanRender"] = "f";
luapad._sG["GAMEMODE"]["GravGunOnDropped"] = "f";
luapad._sG["GAMEMODE"]["PlayerNoClip"] = "f";
luapad._sG["GAMEMODE"]["PlayerDeathThink"] = "f";
luapad._sG["GAMEMODE"]["PlayerSpawnAsSpectator"] = "f";
luapad._sG["GAMEMODE"]["Move"] = "f";
luapad._sG["GAMEMODE"]["FinishMove"] = "f";
luapad._sG["GAMEMODE"]["CanPlayerEnterVehicle"] = "f";
luapad._sG["GAMEMODE"]["CanPlayerSuicide"] = "f";
luapad._sG["GAMEMODE"]["PlayerStepSoundTime"] = "f";
luapad._sG["GAMEMODE"]["PlayerCanHearPlayersVoice"] = "f";
luapad._sG["GAMEMODE"]["SetupMove"] = "f";
luapad._sG["GAMEMODE"]["PlayerConnect"] = "f";
luapad._sG["GAMEMODE"]["IsSpawnpointSuitable"] = "f";
luapad._sG["GAMEMODE"]["OnPlayerChat"] = "f";
luapad._sG["GAMEMODE"]["InitPostEntity"] = "f";
luapad._sG["GAMEMODE"]["PlayerDeath"] = "f";
luapad._sG["GAMEMODE"]["PlayerSpawnSWEP"] = "f";
luapad._sG["GAMEMODE"]["PlayerSelectSpawn"] = "f";
luapad._sG["GAMEMODE"]["PhysgunPickup"] = "f";
luapad._sG["GAMEMODE"]["ShouldCollide"] = "f";
luapad._sG["GAMEMODE"]["PlayerSay"] = "f";
luapad._sG["GAMEMODE"]["PlayerCanPickupWeapon"] = "f";
luapad._sG["GAMEMODE"]["UpdateAnimation"] = "f";
luapad._sG["GAMEMODE"]["PlayerEnteredVehicle"] = "f";
luapad._sG["GAMEMODE"]["OnDamagedByExplosion"] = "f";
luapad._sG["GAMEMODE"]["EntityRemoved"] = "f";
luapad._sG["GAMEMODE"]["PlayerSpawnedSENT"] = "f";
luapad._sG["GAMEMODE"]["KeyPress"] = "f";
luapad._sG["GAMEMODE"]["ShutDown"] = "f";
luapad._sG["GAMEMODE"]["GravGunPickupAllowed"] = "f";
luapad._sG["GAMEMODE"]["GravGunOnPickedUp"] = "f";
luapad._sG["GAMEMODE"]["PlayerSpawnedProp"] = "f";
luapad._sG["GAMEMODE"]["SetupPlayerVisibility"] = "f";
luapad._sG["GAMEMODE"]["OnPlayerChangedTeam"] = "f";
luapad._sG["GAMEMODE"]["PlayerDisconnected"] = "f";
luapad._sG["GAMEMODE"]["DoPlayerDeath"] = "f";
luapad._sG["GAMEMODE"]["OnPhysgunFreeze"] = "f";
luapad._sG["GAMEMODE"]["OnPlayerHitGround"] = "f";
luapad._sG["GAMEMODE"]["PlayerGiveSWEP"] = "f";
luapad._sG["GAMEMODE"]["PlayerSpawnSENT"] = "f";
luapad._sG["GAMEMODE"]["CanExitVehicle"] = "f";
luapad._sG["GAMEMODE"]["Initialize"] = "f";
luapad._sG["GAMEMODE"]["PlayerUse"] = "f";
luapad._sG["GAMEMODE"]["ScalePlayerDamage"] = "f";
luapad._sG["GAMEMODE"]["OnEntityCreated"] = "f";
luapad._sG["GAMEMODE"]["PlayerLeaveVehicle"] = "f";
luapad._sG["GAMEMODE"]["CanPose"] = "f";
luapad._sG["GAMEMODE"]["PlayerSpray"] = "f";
luapad._sG["GAMEMODE"]["PlayerJoinTeam"] = "f";
luapad._sG["GAMEMODE"]["PlayerCanSeePlayersChat"] = "f";
luapad._sG["GAMEMODE"]["GetGameDescription"] = "f";
luapad._sG["GAMEMODE"]["OnNPCKilled"] = "f";
luapad._sG["GAMEMODE"]["ScaleNPCDamage"] = "f";
luapad._sG["GAMEMODE"]["ShowTeam"] = "f";
luapad._sG["GAMEMODE"]["CreateEntityRagdoll"] = "f";
luapad._sG["GAMEMODE"]["Think"] = "f";
luapad._sG["GAMEMODE"]["Tick"] = "f";
luapad._sG["GAMEMODE"]["PlayerSilentDeath"] = "f";
luapad._sG["GAMEMODE"]["PropBreak"] = "f";
luapad._sG["GAMEMODE"]["CanConstruct"] = "f";
luapad._sG["GAMEMODE"]["EntityKeyValue"] = "f";
luapad._sG["GAMEMODE"]["SetPlayerSpeed"] = "f";
luapad._sG["GAMEMODE"]["PlayerRequestTeam"] = "f";
luapad._sG["GAMEMODE"]["PlayerShouldTakeDamage"] = "f";
luapad._sG["GAMEMODE"]["PlayerSpawnObject"] = "f";
luapad._sG["GAMEMODE"]["ShowHelp"] = "f";
luapad._sG["GAMEMODE"]["CanConstrain"] = "f";
luapad._sG["GAMEMODE"]["PlayerDeathSound"] = "f";
luapad._sG["GAMEMODE"]["GetFallDamage"] = "f";
luapad._sG["GAMEMODE"]["PhysgunDrop"] = "f";
luapad._sG["GAMEMODE"]["PlayerSpawnNPC"] = "f";
luapad._sG["GAMEMODE"]["GravGunPunt"] = "f";
luapad._sG["GAMEMODE"]["PlayerSpawnedNPC"] = "f";
luapad._sG["GAMEMODE"]["PlayerSpawnedVehicle"] = "f";
luapad._sG["scripted_ents"]["GetSpawnable"] = "f";
luapad._sG["scripted_ents"]["GetList"] = "f";
luapad._sG["scripted_ents"]["GetStored"] = "f";
luapad._sG["scripted_ents"]["GetType"] = "f";
luapad._sG["scripted_ents"]["Register"] = "f";
luapad._sG["scripted_ents"]["Get"] = "f";
luapad._sG["sql"]["TableExists"] = "f";
luapad._sG["sql"]["QueryRow"] = "f";
luapad._sG["sql"]["QueryValue"] = "f";
luapad._sG["sql"]["Begin"] = "f";
luapad._sG["sql"]["LastError"] = "f";
luapad._sG["sql"]["Query"] = "f";
luapad._sG["sql"]["Commit"] = "f";
luapad._sG["sql"]["SQLStr"] = "f";
luapad._sG["Json"]["Encode"] = "f";
luapad._sG["Json"]["Decode"] = "f";
luapad._sG["Json"]["Null"] = "f";
luapad._sG["debugoverlay"]["Line"] = "f";
luapad._sG["debugoverlay"]["Cross"] = "f";
luapad._sG["debugoverlay"]["Text"] = "f";
luapad._sG["debugoverlay"]["Sphere"] = "f";
luapad._sG["debugoverlay"]["Box"] = "f";
luapad._sG["numpad"]["Activate"] = "f";
luapad._sG["numpad"]["OnUp"] = "f";
luapad._sG["numpad"]["Deactivate"] = "f";
luapad._sG["numpad"]["Remove"] = "f";
luapad._sG["numpad"]["OnDown"] = "f";
luapad._sG["numpad"]["Register"] = "f";
luapad._sG["timer"]["Destroy"] = "f";
luapad._sG["timer"]["Simple"] = "f";
luapad._sG["timer"]["Adjust"] = "f";
luapad._sG["timer"]["UnPause"] = "f";
luapad._sG["timer"]["Create"] = "f";
luapad._sG["timer"]["Check"] = "f";
luapad._sG["timer"]["IsTimer"] = "f";
luapad._sG["timer"]["Remove"] = "f";
luapad._sG["timer"]["Stop"] = "f";
luapad._sG["timer"]["Start"] = "f";
luapad._sG["timer"]["Pause"] = "f";
luapad._sG["timer"]["Toggle"] = "f";
luapad._sG["schedule"]["Remove"] = "f";
luapad._sG["schedule"]["IsSchedule"] = "f";
luapad._sG["schedule"]["Add"] = "f";
luapad._sG["http"]["Get"] = "f";
luapad._sG["string"]["IsIP"] = "f";
luapad._sG["string"]["explode"] = "f";
luapad._sG["string"]["Right"] = "f";
luapad._sG["string"]["Left"] = "f";
luapad._sG["string"]["FormattedTime"] = "f";
luapad._sG["string"]["upper"] = "f";
luapad._sG["string"]["gsub"] = "f";
luapad._sG["string"]["format"] = "f";
luapad._sG["string"]["TrimLeft"] = "f";
luapad._sG["string"]["rep"] = "f";
luapad._sG["string"]["char"] = "f";
luapad._sG["string"]["TrimRight"] = "f";
luapad._sG["string"]["ToTable"] = "f";
luapad._sG["string"]["reverse"] = "f";
luapad._sG["string"]["byte"] = "f";
luapad._sG["string"]["split"] = "f";
luapad._sG["string"]["Explode"] = "f";
luapad._sG["string"]["ToMinutesSecondsMilliseconds"] = "f";
luapad._sG["string"]["match"] = "f";
luapad._sG["string"]["lower"] = "f";
luapad._sG["string"]["GetFileFromFilename"] = "f";
luapad._sG["string"]["sub"] = "f";
luapad._sG["string"]["TrimExplode"] = "f";
luapad._sG["string"]["Replace"] = "f";
luapad._sG["string"]["gfind"] = "f";
luapad._sG["string"]["Implode"] = "f";
luapad._sG["string"]["Trim"] = "f";
luapad._sG["string"]["ToMinutesSeconds"] = "f";
luapad._sG["string"]["gmatch"] = "f";
luapad._sG["string"]["dump"] = "f";
luapad._sG["string"]["Count"] = "f";
luapad._sG["string"]["instr"] = "f";
luapad._sG["string"]["len"] = "f";
luapad._sG["string"]["GetExtensionFromFilename"] = "f";
luapad._sG["string"]["GetPathFromFilename"] = "f";
luapad._sG["string"]["find"] = "f";
luapad._sG["DakaraWeapon"]["Create"] = "f";
luapad._sG["DakaraWeapon"]["IsCharged"] = "f";
luapad._sG["DakaraWeapon"]["Setup"] = "f";
luapad._sG["file"]["FindInLua"] = "f";
luapad._sG["file"]["CreateDir"] = "f";
luapad._sG["file"]["TFind"] = "f";
luapad._sG["file"]["FindDir"] = "f";
luapad._sG["file"]["Find"] = "f";
luapad._sG["file"]["Write"] = "f";
luapad._sG["file"]["Time"] = "f";
luapad._sG["file"]["Read"] = "f";
luapad._sG["file"]["Exists"] = "f";
luapad._sG["file"]["Rename"] = "f";
luapad._sG["file"]["Delete"] = "f";
luapad._sG["file"]["IsDir"] = "f";
luapad._sG["file"]["ExistsEx"] = "f";
luapad._sG["file"]["Size"] = "f";
luapad._sG["ents"]["GetAll"] = "f";
luapad._sG["ents"]["FindInSphere"] = "f";
luapad._sG["ents"]["FindByModel"] = "f";
luapad._sG["ents"]["Create"] = "f";
luapad._sG["ents"]["FindInBox"] = "f";
luapad._sG["ents"]["FindByName"] = "f";
luapad._sG["ents"]["GetByIndex"] = "f";
luapad._sG["ents"]["FindByClass"] = "f";
luapad._sG["ents"]["FindInCone"] = "f";
luapad._sG["WireToolHelpers"]["UpdateGhost"] = "f";
luapad._sG["WireToolHelpers"]["LeftClick"] = "f";
luapad._sG["WireToolHelpers"]["Think"] = "f";
luapad._sG["WireToolHelpers"]["BaseLang"] = "f";
luapad._sG["utilx"]["Decal"] = "f";
luapad._sG["utilx"]["CRC"] = "f";
luapad._sG["utilx"]["IsValidModel"] = "f";
luapad._sG["utilx"]["TraceEntityHull"] = "f";
luapad._sG["utilx"]["LocalToWorld"] = "f";
luapad._sG["utilx"]["tobool"] = "f";
luapad._sG["utilx"]["DecalMaterial"] = "f";
luapad._sG["utilx"]["QuickTrace"] = "f";
luapad._sG["utilx"]["GetPlayerTrace"] = "f";
luapad._sG["utilx"]["PrecacheSound"] = "f";
luapad._sG["utilx"]["BlastDamage"] = "f";
luapad._sG["utilx"]["PrecacheModel"] = "f";
luapad._sG["utilx"]["PointContents"] = "f";
luapad._sG["utilx"]["TableToKeyValues"] = "f";
luapad._sG["utilx"]["IsValidProp"] = "f";
luapad._sG["utilx"]["Effect"] = "f";
luapad._sG["utilx"]["RelativePathToFull"] = "f";
luapad._sG["utilx"]["SpriteTrail"] = "f";
luapad._sG["utilx"]["KeyValuesToTable"] = "f";
luapad._sG["utilx"]["GetModelInfo"] = "f";
luapad._sG["utilx"]["GetSurfaceIndex"] = "f";
luapad._sG["utilx"]["IsValidPhysicsObject"] = "f";
luapad._sG["utilx"]["IsInWorld"] = "f";
luapad._sG["utilx"]["TraceLine"] = "f";
luapad._sG["utilx"]["IsValidRagdoll"] = "f";
luapad._sG["utilx"]["TraceHull"] = "f";
luapad._sG["utilx"]["TraceEntity"] = "f";
luapad._sG["utilx"]["ScreenShake"] = "f";
luapad._sG["math"]["Rad2Deg"] = "f";
luapad._sG["math"]["log"] = "f";
luapad._sG["math"]["TimeFraction"] = "f";
luapad._sG["math"]["BinToInt"] = "f";
luapad._sG["math"]["ldexp"] = "f";
luapad._sG["math"]["rad"] = "f";
luapad._sG["math"]["cosh"] = "f";
luapad._sG["math"]["random"] = "f";
luapad._sG["math"]["frexp"] = "f";
luapad._sG["math"]["tanh"] = "f";
luapad._sG["math"]["floor"] = "f";
luapad._sG["math"]["max"] = "f";
luapad._sG["math"]["sqrt"] = "f";
luapad._sG["math"]["modf"] = "f";
luapad._sG["math"]["Min"] = "f";
luapad._sG["math"]["BSplinePoint"] = "f";
luapad._sG["math"]["RotationMatrix"] = "f";
luapad._sG["math"]["pow"] = "f";
luapad._sG["math"]["IsOnScreen"] = "f";
luapad._sG["math"]["MidAngle"] = "f";
luapad._sG["math"]["Rand"] = "f";
luapad._sG["math"]["Mid"] = "f";
luapad._sG["math"]["ApproachAngle"] = "f";
luapad._sG["math"]["atan"] = "f";
luapad._sG["math"]["IntToBin"] = "f";
luapad._sG["math"]["NormalizeAngle"] = "f";
luapad._sG["math"]["Approach"] = "f";
luapad._sG["math"]["Dist"] = "f";
luapad._sG["math"]["calcBSplineN"] = "f";
luapad._sG["math"]["acos"] = "f";
luapad._sG["math"]["Max"] = "f";
luapad._sG["math"]["tan"] = "f";
luapad._sG["math"]["cos"] = "f";
luapad._sG["math"]["Round"] = "f";
luapad._sG["math"]["AngleDifference"] = "f";
luapad._sG["math"]["Distance"] = "f";
luapad._sG["math"]["Clamp"] = "f";
luapad._sG["math"]["log10"] = "f";
luapad._sG["math"]["AlphaFlash"] = "f";
luapad._sG["math"]["EaseInOut"] = "f";
luapad._sG["math"]["abs"] = "f";
luapad._sG["math"]["Deg2Rad"] = "f";
luapad._sG["math"]["sinh"] = "f";
luapad._sG["math"]["asin"] = "f";
luapad._sG["math"]["min"] = "f";
luapad._sG["math"]["deg"] = "f";
luapad._sG["math"]["fmod"] = "f";
luapad._sG["math"]["randomseed"] = "f";
luapad._sG["math"]["atan2"] = "f";
luapad._sG["math"]["ceil"] = "f";
luapad._sG["math"]["sin"] = "f";
luapad._sG["math"]["exp"] = "f";
luapad._sG["StargateExtras"]["SetStargateEnergyCapacity"] = "f";
luapad._sG["StargateExtras"]["UnregisterEntity"] = "f";
luapad._sG["StargateExtras"]["ArePointsInsideAShield"] = "f";
luapad._sG["StargateExtras"]["IsStargateOutbound"] = "f";
luapad._sG["StargateExtras"]["FindInsideRotatedBox"] = "f";
luapad._sG["StargateExtras"]["IsStargateDialling"] = "f";
luapad._sG["StargateExtras"]["TintGate"] = "f";
luapad._sG["StargateExtras"]["IsStargateOpen"] = "f";
luapad._sG["StargateExtras"]["LOS"] = "f";
luapad._sG["StargateExtras"]["JamDHD"] = "f";
luapad._sG["StargateExtras"]["FindEntInsideSphere"] = "f";
luapad._sG["StargateExtras"]["Initialize"] = "f";
luapad._sG["StargateExtras"]["IsEntityValid"] = "f";
luapad._sG["StargateExtras"]["GetIris"] = "f";
luapad._sG["StargateExtras"]["RegisterWithDamageSystem"] = "f";
luapad._sG["StargateExtras"]["EmitHeat"] = "f";
luapad._sG["StargateExtras"]["GetStargateEnergyCapacity"] = "f";
luapad._sG["StargateExtras"]["IsEntityShielded"] = "f";
luapad._sG["StargateExtras"]["MakeStargateUseEnergy"] = "f";
luapad._sG["StargateExtras"]["GetGateMarker"] = "f";
luapad._sG["StargateExtras"]["GetEntityCentre"] = "f";
luapad._sG["StargateExtras"]["UnJamGate"] = "f";
luapad._sG["StargateExtras"]["JamRemoteGate"] = "f";
luapad._sG["StargateExtras"]["Think"] = "f";
luapad._sG["StargateExtras"]["GetRemoteStargate"] = "f";
luapad._sG["StargateExtras"]["CauseHeatDamage"] = "f";
luapad._sG["StargateExtras"]["UpdateGateTemperatures"] = "f";
luapad._sG["StargateExtras"]["CoolEntity"] = "f";
luapad._sG["StargateExtras"]["HeatEntity"] = "f";
luapad._sG["StargateExtras"]["CoolGate"] = "f";
luapad._sG["StargateExtras"]["RegisterOverloader"] = "f";
luapad._sG["StargateExtras"]["UnJamDHD"] = "f";
luapad._sG["StargateExtras"]["ShieldTrace"] = "f";
luapad._sG["StargateExtras"]["UnregisterOverloader"] = "f";
luapad._sG["StargateExtras"]["GetTeleportedVector"] = "f";
luapad._sG["StargateExtras"]["IsProtectedByGateSpawner"] = "f";
luapad._sG["StargateExtras"]["DrawGateHeatEffects"] = "f";
luapad._sG["StargateExtras"]["DestroyStargate"] = "f";
luapad._sG["StargateExtras"]["MakeGateFlicker"] = "f";
luapad._sG["StargateExtras"]["RegisterEntity"] = "f";
luapad._sG["StargateExtras"]["GetEntityCentre2"] = "f";
luapad._sG["StargateExtras"]["IsIrisClosed"] = "f";
luapad._sG["AdvDupe"]["MakeDir"] = "f";
luapad._sG["AdvDupe"]["PasteGetConstraintArgs"] = "f";
luapad._sG["AdvDupe"]["GhostAddDelay"] = "f";
luapad._sG["AdvDupe"]["GetAllEnts"] = "f";
luapad._sG["AdvDupe"]["SendClientInfoMsg"] = "f";
luapad._sG["AdvDupe"]["PasteApplyDORInfo"] = "f";
luapad._sG["AdvDupe"]["GetSaveableConst"] = "f";
luapad._sG["AdvDupe"]["GetPasterClearToPasteDelay"] = "f";
luapad._sG["AdvDupe"]["SetPasting"] = "f";
luapad._sG["AdvDupe"]["NormPaste"] = "f";
luapad._sG["AdvDupe"]["Paste"] = "f";
luapad._sG["AdvDupe"]["PasteApplyDupeInfo"] = "f";
luapad._sG["AdvDupe"]["OverTimePasteProcessFromTable"] = "f";
luapad._sG["AdvDupe"]["LoadDupeTableFromFile"] = "f";
luapad._sG["AdvDupe"]["HideGhost"] = "f";
luapad._sG["AdvDupe"]["Copy"] = "f";
luapad._sG["AdvDupe"]["GetPlayersFolder"] = "f";
luapad._sG["AdvDupe"]["SetPercent"] = "f";
luapad._sG["AdvDupe"]["MakeProp"] = "f";
luapad._sG["AdvDupe"]["GetSaveableEntity"] = "f";
luapad._sG["AdvDupe"]["CreateEntityFromTable"] = "f";
luapad._sG["AdvDupe"]["RecieveFileContentFinish"] = "f";
luapad._sG["AdvDupe"]["GetAdvDupeToolObj"] = "f";
luapad._sG["AdvDupe"]["AfterPasteApply"] = "f";
luapad._sG["AdvDupe"]["GenericDuplicatorFunction"] = "f";
luapad._sG["AdvDupe"]["CreateConstraintFromTable"] = "f";
luapad._sG["AdvDupe"]["UpdateList"] = "f";
luapad._sG["AdvDupe"]["LimitedGhost"] = "f";
luapad._sG["AdvDupe"]["ConvertConstraintPositionsToWorld"] = "f";
luapad._sG["AdvDupe"]["GhostsPerTick"] = "f";
luapad._sG["AdvDupe"]["AddDelayedPaste"] = "f";
luapad._sG["AdvDupe"]["GhostLimitNorm"] = "f";
luapad._sG["AdvDupe"]["ConvertEntityPositionsToWorld"] = "f";
luapad._sG["AdvDupe"]["PasteGetEntArgs"] = "f";
luapad._sG["AdvDupe"]["CheckOkEnt"] = "f";
luapad._sG["AdvDupe"]["SendSaveToClient"] = "f";
luapad._sG["AdvDupe"]["FinishPasting"] = "f";
luapad._sG["AdvDupe"]["StartPaste"] = "f";
luapad._sG["AdvDupe"]["OverTimePasteProcess"] = "f";
luapad._sG["AdvDupe"]["SendSaveToClientData"] = "f";
luapad._sG["AdvDupe"]["SaveDupeTablesToFile"] = "f";
luapad._sG["AdvDupe"]["SendClientError"] = "f";
luapad._sG["AdvDupe"]["PasteEntity"] = "f";
luapad._sG["AdvDupe"]["OldMakeWheel"] = "f";
luapad._sG["AdvDupe"]["ConvertPositionsToLocal"] = "f";
luapad._sG["AdvDupe"]["GhostLimitLimited"] = "f";
luapad._sG["AdvDupe"]["ResetPositions"] = "f";
luapad._sG["AdvDupe"]["OldSetPhysProp"] = "f";
luapad._sG["AdvDupe"]["MakeTimer"] = "f";
luapad._sG["AdvDupe"]["PasteApplyEntMods"] = "f";
luapad._sG["AdvDupe"]["OverTimePasteStart"] = "f";
luapad._sG["AdvDupe"]["CheckPerms"] = "f";
luapad._sG["AdvDupe"]["NormPasteFromTable"] = "f";
luapad._sG["AdvDupe"]["ApplyParenting"] = "f";
luapad._sG["AdvDupe"]["RecieveFileContentSave"] = "f";
luapad._sG["AdvDupe"]["FileOpts"] = "f";
luapad._sG["AdvDupe"]["OldMakeProp"] = "f";
luapad._sG["AdvDupe"]["GetEntitysConstrainedEntitiesAndConstraints"] = "f";
luapad._sG["AdvDupe"]["FreezeEntity"] = "f";
luapad._sG["AdvDupe"]["RecieveFileContent"] = "f";
luapad._sG["AdvDupe"]["OldPaste"] = "f";
luapad._sG["AdvDupe"]["RecieveFileContentStart"] = "f";
luapad._sG["AdvDupe"]["SetPercentText"] = "f";
luapad._sG["cleanup"]["CC_AdminCleanup"] = "f";
luapad._sG["cleanup"]["CC_Cleanup"] = "f";
luapad._sG["cleanup"]["ReplaceEntity"] = "f";
luapad._sG["cleanup"]["Register"] = "f";
luapad._sG["cleanup"]["Add"] = "f";
luapad._sG["StarGate"]["VelocityOffset"] = "f";
luapad._sG["StarGate"]["GetConstrainedEnts"] = "f";
luapad._sG["StarGate"]["LifeSupportAndWire"] = "f";
luapad._sG["StarGate"]["CallReload"] = "f";
luapad._sG["StarGate"]["Init"] = "f";
luapad._sG["StarGate"]["CanTouch"] = "f";
luapad._sG["StarGate"]["InBox"] = "f";
luapad._sG["StarGate"]["GetAttackerAndOwner"] = "f";
luapad._sG["StarGate"]["BlastDamage"] = "f";
luapad._sG["StarGate"]["LoadConfig"] = "f";
luapad._sG["StarGate"]["Load"] = "f";
luapad._sG["PROG"]["OnInstall"] = "f";
luapad._sG["PROG"]["CanUse"] = "f";
luapad._sG["PROG"]["SetState"] = "f";
luapad._sG["PROG"]["PingSuccess"] = "f";
luapad._sG["PROG"]["ProcessPacket"] = "f";
luapad._sG["PROG"]["OnEnd"] = "f";
luapad._sG["PROG"]["ClosePrintLocation"] = "f";
luapad._sG["PROG"]["Initialize"] = "f";
luapad._sG["PROG"]["Start"] = "f";
luapad._sG["PROG"]["DoCommand"] = "f";
luapad._sG["PROG"]["Exit"] = "f";
luapad._sG["PROG"]["TriggerState"] = "f";
luapad._sG["PROG"]["CloseOpenFile"] = "f";
luapad._sG["PROG"]["PrintDocument"] = "f";
luapad._sG["PROG"]["SetScreenSpace"] = "f";
luapad._sG["PROG"]["Think"] = "f";
luapad._sG["PROG"]["Tick"] = "f";
luapad._sG["PROG"]["GetOS"] = "f";
luapad._sG["PROG"]["ShowPrintLocation"] = "f";
luapad._sG["PROG"]["OnStart"] = "f";
luapad._sG["PROG"]["GetScreenSpace"] = "f";
luapad._sG["PROG"]["RequestFocus"] = "f";
luapad._sG["PROG"]["GetDimensions"] = "f";
luapad._sG["PROG"]["GetPriority"] = "f";
luapad._sG["PROG"]["UpdateSS"] = "f";
luapad._sG["PROG"]["RemoveFocus"] = "f";
luapad._sG["PROG"]["ShowOpenFile"] = "f";
luapad._sG["PROG"]["MessageFailed"] = "f";
luapad._sG["PROG"]["TraceSuccess"] = "f";
luapad._sG["datastream"]["Hook"] = "f";
luapad._sG["datastream"]["GetProgress"] = "f";
luapad._sG["datastream"]["GetSharedTable"] = "f";
luapad._sG["datastream"]["DownstreamActive"] = "f";
luapad._sG["datastream"]["CreateSharedTable"] = "f";
luapad._sG["datastream"]["StreamToClients"] = "f";
luapad._sG["glon"]["Read"] = "f";
luapad._sG["glon"]["encode"] = "f";
luapad._sG["glon"]["decode"] = "f";
luapad._sG["glon"]["Write"] = "f";
luapad._sG["Quaternion"]["MultiplyQuaternion"] = "f";
luapad._sG["Quaternion"]["FromAngle"] = "f";
luapad._sG["Quaternion"]["AimZAxis"] = "f";
luapad._sG["Quaternion"]["SetAxisRad"] = "f";
luapad._sG["Quaternion"]["Normalize"] = "f";
luapad._sG["Quaternion"]["ToAngle"] = "f";
luapad._sG["Quaternion"]["IsIdentity"] = "f";
luapad._sG["Quaternion"]["Dot"] = "f";
luapad._sG["Quaternion"]["MultiplyScalar"] = "f";
luapad._sG["Quaternion"]["Reset"] = "f";
luapad._sG["Quaternion"]["SetAxis"] = "f";
luapad._sG["Quaternion"]["New"] = "f";
luapad._sG["mathx"]["Rad2Deg"] = "f";
luapad._sG["mathx"]["log"] = "f";
luapad._sG["mathx"]["TimeFraction"] = "f";
luapad._sG["mathx"]["BinToInt"] = "f";
luapad._sG["mathx"]["ldexp"] = "f";
luapad._sG["mathx"]["rad"] = "f";
luapad._sG["mathx"]["cosh"] = "f";
luapad._sG["mathx"]["random"] = "f";
luapad._sG["mathx"]["frexp"] = "f";
luapad._sG["mathx"]["tanh"] = "f";
luapad._sG["mathx"]["floor"] = "f";
luapad._sG["mathx"]["max"] = "f";
luapad._sG["mathx"]["sqrt"] = "f";
luapad._sG["mathx"]["modf"] = "f";
luapad._sG["mathx"]["Min"] = "f";
luapad._sG["mathx"]["BSplinePoint"] = "f";
luapad._sG["mathx"]["RotationMatrix"] = "f";
luapad._sG["mathx"]["pow"] = "f";
luapad._sG["mathx"]["IsOnScreen"] = "f";
luapad._sG["mathx"]["MidAngle"] = "f";
luapad._sG["mathx"]["Rand"] = "f";
luapad._sG["mathx"]["Mid"] = "f";
luapad._sG["mathx"]["ApproachAngle"] = "f";
luapad._sG["mathx"]["atan"] = "f";
luapad._sG["mathx"]["IntToBin"] = "f";
luapad._sG["mathx"]["NormalizeAngle"] = "f";
luapad._sG["mathx"]["Approach"] = "f";
luapad._sG["mathx"]["Dist"] = "f";
luapad._sG["mathx"]["calcBSplineN"] = "f";
luapad._sG["mathx"]["acos"] = "f";
luapad._sG["mathx"]["Max"] = "f";
luapad._sG["mathx"]["tan"] = "f";
luapad._sG["mathx"]["cos"] = "f";
luapad._sG["mathx"]["Round"] = "f";
luapad._sG["mathx"]["AngleDifference"] = "f";
luapad._sG["mathx"]["Distance"] = "f";
luapad._sG["mathx"]["Clamp"] = "f";
luapad._sG["mathx"]["log10"] = "f";
luapad._sG["mathx"]["AlphaFlash"] = "f";
luapad._sG["mathx"]["EaseInOut"] = "f";
luapad._sG["mathx"]["abs"] = "f";
luapad._sG["mathx"]["Deg2Rad"] = "f";
luapad._sG["mathx"]["sinh"] = "f";
luapad._sG["mathx"]["asin"] = "f";
luapad._sG["mathx"]["min"] = "f";
luapad._sG["mathx"]["deg"] = "f";
luapad._sG["mathx"]["fmod"] = "f";
luapad._sG["mathx"]["randomseed"] = "f";
luapad._sG["mathx"]["atan2"] = "f";
luapad._sG["mathx"]["ceil"] = "f";
luapad._sG["mathx"]["sin"] = "f";
luapad._sG["mathx"]["exp"] = "f";
luapad._sG["DRV"]["RetrievePortData"] = "f";
luapad._sG["DRV"]["Think"] = "f";
luapad._sG["DRV"]["CallEvent"] = "f";
luapad._sG["DRV"]["GetDevice"] = "f";
luapad._sG["DRV"]["FindDevices"] = "f";
luapad._sG["DRV"]["GetPortData"] = "f";
luapad._sG["DRV"]["SendDeviceData"] = "f";
luapad._sG["DRV"]["GetDeviceData"] = "f";
luapad._sG["DRV"]["Initialize"] = "f";
luapad._sG["DRV"]["ResetPortData"] = "f";
luapad._sG["DRV"]["DataRecieved"] = "f";
luapad._sG["DRV"]["OnRemove"] = "f";
luapad._sG["duplicator"]["FindEntityClass"] = "f";
luapad._sG["duplicator"]["DoFlex"] = "f";
luapad._sG["duplicator"]["DoGenericPhysics"] = "f";
luapad._sG["duplicator"]["GetAllConstrainedEntitiesAndConstraints"] = "f";
luapad._sG["duplicator"]["StoreEntityModifier"] = "f";
luapad._sG["duplicator"]["ApplyBoneModifiers"] = "f";
luapad._sG["duplicator"]["ApplyEntityModifiers"] = "f";
luapad._sG["duplicator"]["RegisterBoneModifier"] = "f";
luapad._sG["duplicator"]["CreateEntityFromTable"] = "f";
luapad._sG["duplicator"]["Paste"] = "f";
luapad._sG["duplicator"]["RegisterEntityModifier"] = "f";
luapad._sG["duplicator"]["Copy"] = "f";
luapad._sG["duplicator"]["RegisterConstraint"] = "f";
luapad._sG["duplicator"]["CopyEntTable"] = "f";
luapad._sG["duplicator"]["StoreBoneModifier"] = "f";
luapad._sG["duplicator"]["GenericDuplicatorFunction"] = "f";
luapad._sG["duplicator"]["RegisterEntityClass"] = "f";
luapad._sG["duplicator"]["ClearEntityModifier"] = "f";
luapad._sG["duplicator"]["CreateConstraintFromTable"] = "f";
luapad._sG["duplicator"]["DoGeneric"] = "f";
luapad._sG["undo"]["ReplaceEntity"] = "f";
luapad._sG["undo"]["Create"] = "f";
luapad._sG["undo"]["Do_Undo"] = "f";
luapad._sG["undo"]["AddEntity"] = "f";
luapad._sG["undo"]["SetPlayer"] = "f";
luapad._sG["undo"]["AddFunction"] = "f";
luapad._sG["undo"]["SetCustomUndoText"] = "f";
luapad._sG["undo"]["Finish"] = "f";
luapad._sG["player_manager"]["AddValidModel"] = "f";
luapad._sG["player_manager"]["TranslatePlayerModel"] = "f";
luapad._sG["player_manager"]["AllValidModels"] = "f";
luapad._sG["gamemode"]["Call"] = "f";
luapad._sG["gamemode"]["Register"] = "f";
luapad._sG["gamemode"]["Get"] = "f";
luapad._sG["gmod"]["GetGamemode"] = "f";
luapad._sG["resource"]["AddFile"] = "f";
luapad._sG["player"]["GetBots"] = "f";
luapad._sG["player"]["GetByID"] = "f";
luapad._sG["player"]["GetByUniqueID"] = "f";
luapad._sG["player"]["GetAll"] = "f";
luapad._sG["player"]["GetHumans"] = "f";
luapad._sG["game"]["ConsoleCommand"] = "f";
luapad._sG["game"]["GetMap"] = "f";
luapad._sG["game"]["CleanUpMap"] = "f";
luapad._sG["game"]["GetMapNext"] = "f";
luapad._sG["game"]["LoadNextMap"] = "f";
luapad._sG["umsg"]["Bool"] = "f";
luapad._sG["umsg"]["String"] = "f";
luapad._sG["umsg"]["PoolString"] = "f";
luapad._sG["umsg"]["Short"] = "f";
luapad._sG["umsg"]["Entity"] = "f";
luapad._sG["umsg"]["Char"] = "f";
luapad._sG["umsg"]["Float"] = "f";
luapad._sG["umsg"]["Vector"] = "f";
luapad._sG["umsg"]["End"] = "f";
luapad._sG["umsg"]["Start"] = "f";
luapad._sG["umsg"]["Angle"] = "f";
luapad._sG["umsg"]["VectorNormal"] = "f";
luapad._sG["umsg"]["Long"] = "f";
luapad._sG["weapons"]["GetList"] = "f";
luapad._sG["weapons"]["Register"] = "f";
luapad._sG["weapons"]["GetStored"] = "f";
luapad._sG["weapons"]["Get"] = "f";
luapad._sG["ai_schedule"]["New"] = "f";
luapad._sG["Compiler"]["InstrDEC"] = "f";
luapad._sG["Compiler"]["InstrASS"] = "f";
luapad._sG["Compiler"]["InstrSUB"] = "f";
luapad._sG["Compiler"]["GetFunction"] = "f";
luapad._sG["Compiler"]["InstrMOD"] = "f";
luapad._sG["Compiler"]["SetVariableType"] = "f";
luapad._sG["Compiler"]["InstrFUN"] = "f";
luapad._sG["Compiler"]["InstrNEG"] = "f";
luapad._sG["Compiler"]["Process"] = "f";
luapad._sG["Compiler"]["InstrNUM"] = "f";
luapad._sG["Compiler"]["InstrEQ"] = "f";
luapad._sG["Compiler"]["InstrLTH"] = "f";
luapad._sG["Compiler"]["PushContext"] = "f";
luapad._sG["Compiler"]["Evaluate"] = "f";
luapad._sG["Compiler"]["Error"] = "f";
luapad._sG["Compiler"]["InstrINC"] = "f";
luapad._sG["Compiler"]["Execute"] = "f";
luapad._sG["Compiler"]["InstrSTR"] = "f";
luapad._sG["Compiler"]["InstrVAR"] = "f";
luapad._sG["Compiler"]["InstrDLT"] = "f";
luapad._sG["Compiler"]["InstrTRG"] = "f";
luapad._sG["Compiler"]["MergeContext"] = "f";
luapad._sG["Compiler"]["PopContext"] = "f";
luapad._sG["Compiler"]["InstrMUL"] = "f";
luapad._sG["Compiler"]["InstrGTH"] = "f";
luapad._sG["Compiler"]["InstrADD"] = "f";
luapad._sG["Compiler"]["InstrLEQ"] = "f";
luapad._sG["Compiler"]["GetMethod"] = "f";
luapad._sG["Compiler"]["InstrGEQ"] = "f";
luapad._sG["Compiler"]["InstrNEQ"] = "f";
luapad._sG["Compiler"]["InstrCND"] = "f";
luapad._sG["Compiler"]["GetVariableType"] = "f";
luapad._sG["Compiler"]["InstrDIV"] = "f";
luapad._sG["Compiler"]["InstrAND"] = "f";
luapad._sG["Compiler"]["InstrMTO"] = "f";
luapad._sG["Compiler"]["AssertOperator"] = "f";
luapad._sG["Compiler"]["InstrSEQ"] = "f";
luapad._sG["Compiler"]["EvaluateStatement"] = "f";
luapad._sG["Compiler"]["InstrOR"] = "f";
luapad._sG["Compiler"]["InstrIF"] = "f";
luapad._sG["Compiler"]["InstrNOT"] = "f";
luapad._sG["Compiler"]["InstrEXP"] = "f";
luapad._sG["Compiler"]["GetOperator"] = "f";
luapad._sG["_E"]["WireGateExpressionSendPacket"] = "f";
luapad._sG["_E"]["TableToKeyValues"] = "f";
luapad._sG["_E"]["MakeWirePlug"] = "f";
luapad._sG["_E"]["GMODSpawnProp"] = "f";
luapad._sG["_E"]["AddConsoleCommand"] = "f";
luapad._sG["_E"]["SetGlobalVector"] = "f";
luapad._sG["_E"]["collectgarbage"] = "f";
luapad._sG["_E"]["WorldToLocal"] = "f";
luapad._sG["_E"]["NotifierSetDelay"] = "f";
luapad._sG["_E"]["IncludeClientFile"] = "f";
luapad._sG["_E"]["GetConVarNumber"] = "f";
luapad._sG["_E"]["SetGlobalAngle"] = "f";
luapad._sG["_E"]["GetGlobalAngle"] = "f";
luapad._sG["_E"]["registerOperator"] = "f";
luapad._sG["_E"]["RefreshSpecialOutputs"] = "f";
luapad._sG["_E"]["validPhysics"] = "f";
luapad._sG["_E"]["MakeXQMWireHydraulicController"] = "f";
luapad._sG["_E"]["SetGlobalString"] = "f";
luapad._sG["_E"]["CCSpawnSENT"] = "f";
luapad._sG["_E"]["MakeWireLocator"] = "f";
luapad._sG["_E"]["Matrix"] = "f";
luapad._sG["_E"]["Wire_BuildDupeInfo"] = "f";
luapad._sG["_E"]["CC_GMOD_Camera"] = "f";
luapad._sG["_E"]["playerDeath"] = "f";
luapad._sG["_E"]["SetGlobalBeamInt"] = "f";
luapad._sG["_E"]["ipairs"] = "f";
luapad._sG["_E"]["MsgAll"] = "f";
luapad._sG["_E"]["SetGlobalBeamString"] = "f";
luapad._sG["_E"]["GetGlobalInt"] = "f";
luapad._sG["_E"]["Radio_SendData"] = "f";
luapad._sG["_E"]["MakeWireTwoWay_Radio"] = "f";
luapad._sG["_E"]["SQLStr"] = "f";
luapad._sG["_E"]["MakeWireMotor"] = "f";
luapad._sG["_E"]["GPU_PlayerRespawn"] = "f";
luapad._sG["_E"]["Wire_CreateOutputs"] = "f";
luapad._sG["_E"]["TellGps"] = "f";
luapad._sG["_E"]["WireToolMakeSoundEmitter"] = "f";
luapad._sG["_E"]["MakeWireString"] = "f";
luapad._sG["_E"]["NotifierCheckAdmin"] = "f";
luapad._sG["_E"]["Add_NPC_Class"] = "f";
luapad._sG["_E"]["CCSpawnNPC"] = "f";
luapad._sG["_E"]["PCMod_ResetOld"] = "f";
luapad._sG["_E"]["PrintMessage"] = "f";
luapad._sG["_E"]["MakeWireHoverBall"] = "f";
luapad._sG["_E"]["MakeWireGrabber"] = "f";
luapad._sG["_E"]["GetWirelessRecv"] = "f";
luapad._sG["_E"]["Reflush_GPU_Data"] = "f";
luapad._sG["_E"]["ColorToHSV"] = "f";
luapad._sG["_E"]["registerFunction"] = "f";
luapad._sG["_E"]["BuildNetworkedVarsTable"] = "f";
luapad._sG["_E"]["CCTeleportLoc"] = "f";
luapad._sG["_E"]["IsTableOfEntitiesValid"] = "f";
luapad._sG["_E"]["MakeWireTextScreen"] = "f";
luapad._sG["_E"]["pcall"] = "f";
luapad._sG["_E"]["AddOriginToPVS"] = "f";
luapad._sG["_E"]["ApplyColMatSpawned"] = "f";
luapad._sG["_E"]["MsgN"] = "f";
luapad._sG["_E"]["GetGlobalBool"] = "f";
luapad._sG["_E"]["SetGlobalBeamFloat"] = "f";
luapad._sG["_E"]["rawequal"] = "f";
luapad._sG["_E"]["SetGlobalBool"] = "f";
luapad._sG["_E"]["MakeWireKeycardSpawner"] = "f";
luapad._sG["_E"]["ParticleEffect"] = "f";
luapad._sG["_E"]["setfenv"] = "f";
luapad._sG["_E"]["MakeWireSpeedometer"] = "f";
luapad._sG["_E"]["MakeWireDataPlug"] = "f";
luapad._sG["_E"]["WireToolMakeDigitalScreen"] = "f";
luapad._sG["_E"]["SetGlobalEntity"] = "f";
luapad._sG["_E"]["GetGlobalEntity"] = "f";
luapad._sG["_E"]["Add_TextReceiver"] = "f";
luapad._sG["_E"]["MakeWireLamp"] = "f";
luapad._sG["_E"]["MakeWireRanger"] = "f";
luapad._sG["_E"]["CCSpawn"] = "f";
luapad._sG["_E"]["MakeWireDupePort"] = "f";
luapad._sG["_E"]["MakeWireEmitter"] = "f";
luapad._sG["_E"]["WireToolMakeOscilloscope"] = "f";
luapad._sG["_E"]["MakeWireFXEmitter"] = "f";
luapad._sG["_E"]["registerBone"] = "f";
luapad._sG["_E"]["Wire_ApplyDupeInfo"] = "f";
luapad._sG["_E"]["CheckPropSolid"] = "f";
luapad._sG["_E"]["WireToolMakePanel"] = "f";
luapad._sG["_E"]["MakeWireUseHoloemitter"] = "f";
luapad._sG["_E"]["MakeWireMaterializer"] = "f";
luapad._sG["_E"]["Format"] = "f";
luapad._sG["_E"]["GetBuddyFinder"] = "f";
luapad._sG["_E"]["NullEntity"] = "f";
luapad._sG["_E"]["SortedPairsByValue"] = "f";
luapad._sG["_E"]["MakeWireUser"] = "f";
luapad._sG["_E"]["e2_extpp_pass1"] = "f";
luapad._sG["_E"]["WireToolMakeAdvInput"] = "f";
luapad._sG["_E"]["MakeWirePID"] = "f";
luapad._sG["_E"]["MakeWireLatchController"] = "f";
luapad._sG["_E"]["SinglePlayer"] = "f";
luapad._sG["_E"]["MakeWireBeamReader"] = "f";
luapad._sG["_E"]["makedoor"] = "f";
luapad._sG["_E"]["MakeWireTurret"] = "f";
luapad._sG["_E"]["IsPhysicsObject"] = "f";
luapad._sG["_E"]["Vertex"] = "f";
luapad._sG["_E"]["DeriveGamemode"] = "f";
luapad._sG["_E"]["Wire_TriggerOutput"] = "f";
luapad._sG["_E"]["setmetatable"] = "f";
luapad._sG["_E"]["getmetatable"] = "f";
luapad._sG["_E"]["rawset"] = "f";
luapad._sG["_E"]["MakeWireRelay"] = "f";
luapad._sG["_E"]["MakeWireTargetFinderBeta"] = "f";
luapad._sG["_E"]["CCTestNotifier"] = "f";
luapad._sG["_E"]["MakeWireRamCardReader"] = "f";
luapad._sG["_E"]["CC_Face_Randomize"] = "f";
luapad._sG["_E"]["CCResetUnit"] = "f";
luapad._sG["_E"]["MakeWireWaypoint"] = "f";
luapad._sG["_E"]["CurTime"] = "f";
luapad._sG["_E"]["e2_processerror"] = "f";
luapad._sG["_E"]["MakeWireGateExpressionParser"] = "f";
luapad._sG["_E"]["WireToolMakeDualInput"] = "f";
luapad._sG["_E"]["WireGateExpressionRecvPacket"] = "f";
luapad._sG["_E"]["Radio_GetTwoWayID"] = "f";
luapad._sG["_E"]["MakeLamp"] = "f";
luapad._sG["_E"]["MakeTurret"] = "f";
luapad._sG["_E"]["MakeWireHydraulicController"] = "f";
luapad._sG["_E"]["MakeWirePainter"] = "f";
luapad._sG["_E"]["SuppressHostEvents"] = "f";
luapad._sG["_E"]["MakeWireReader"] = "f";
luapad._sG["_E"]["MakeNoCollideController"] = "f";
luapad._sG["_E"]["MakeWireIndicator"] = "f";
luapad._sG["_E"]["GetWorldEntity"] = "f";
luapad._sG["_E"]["MakeWireDualInput"] = "f";
luapad._sG["_E"]["PC_AskForPort"] = "f";
luapad._sG["_E"]["e2_extpp_pass2"] = "f";
luapad._sG["_E"]["MakeWireXYZBeacon"] = "f";
luapad._sG["_E"]["GetGlobalBeamEntity"] = "f";
luapad._sG["_E"]["MakeWireSocket"] = "f";
luapad._sG["_E"]["e2_get_typeid"] = "f";
luapad._sG["_E"]["HSVToColor"] = "f";
luapad._sG["_E"]["RealTime"] = "f";
luapad._sG["_E"]["MakeLight"] = "f";
luapad._sG["_E"]["UnPredictedCurTime"] = "f";
luapad._sG["_E"]["gcinfo"] = "f";
luapad._sG["_E"]["HSHoloInteract"] = "f";
luapad._sG["_E"]["WireToolMakeEmitter"] = "f";
luapad._sG["_E"]["Wire_Link_Clear"] = "f";
luapad._sG["_E"]["WireToolMakePixel"] = "f";
luapad._sG["_E"]["MakeWireHydraulic"] = "f";
luapad._sG["_E"]["next"] = "f";
luapad._sG["_E"]["VectorRand"] = "f";
luapad._sG["_E"]["select"] = "f";
luapad._sG["_E"]["CCAnswer"] = "f";
luapad._sG["_E"]["FrameTime"] = "f";
luapad._sG["_E"]["GetGlobalBeamBool"] = "f";
luapad._sG["_E"]["KeyValuesToTablePreserveOrder"] = "f";
luapad._sG["_E"]["e2_install_hook_fix"] = "f";
luapad._sG["_E"]["ServerLog"] = "f";
luapad._sG["_E"]["MakeWireDetonator"] = "f";
luapad._sG["_E"]["ParticleEffectAttach"] = "f";
luapad._sG["_E"]["SafeRemoveEntity"] = "f";
luapad._sG["_E"]["CCAck"] = "f";
luapad._sG["_E"]["DoPlayerEntitySpawn"] = "f";
luapad._sG["_E"]["unpack"] = "f";
luapad._sG["_E"]["MakeWireHoloemitter"] = "f";
luapad._sG["_E"]["MakeWireGPS"] = "f";
luapad._sG["_E"]["WireToolMakeLamp"] = "f";
luapad._sG["_E"]["rawget"] = "f";
luapad._sG["_E"]["MakeWireHudIndicator"] = "f";
luapad._sG["_E"]["CreateSound"] = "f";
luapad._sG["_E"]["WireToolMakeConsoleScreen"] = "f";
luapad._sG["_E"]["engineCommandComplete"] = "f";
luapad._sG["_E"]["IsValid"] = "f";
luapad._sG["_E"]["WorldSound"] = "f";
luapad._sG["_E"]["MakeWireImplanter"] = "f";
luapad._sG["_E"]["EffectData"] = "f";
luapad._sG["_E"]["OrderVectors"] = "f";
luapad._sG["_E"]["MakeWireRTCam"] = "f";
luapad._sG["_E"]["WireGPU_AddMonitor"] = "f";
luapad._sG["_E"]["MakeWireGyroscope"] = "f";
luapad._sG["_E"]["DamageInfo"] = "f";
luapad._sG["_E"]["GetAddonList"] = "f";
luapad._sG["_E"]["print_r"] = "f";
luapad._sG["_E"]["Wire_Link_End"] = "f";
luapad._sG["_E"]["WireToolMakeHoloGrid"] = "f";
luapad._sG["_E"]["QuaternionSlerp"] = "f";
luapad._sG["_E"]["switch"] = "f";
luapad._sG["_E"]["tablevalues"] = "f";
luapad._sG["_E"]["MakeWirePod"] = "f";
luapad._sG["_E"]["MakeWirePanel"] = "f";
luapad._sG["_E"]["GetWirelessSrv"] = "f";
luapad._sG["_E"]["HoloInteract"] = "f";
luapad._sG["_E"]["MakeWireKeycard"] = "f";
luapad._sG["_E"]["MakeWireWheel"] = "f";
luapad._sG["_E"]["MakeNail"] = "f";
luapad._sG["_E"]["MakeWireScreen"] = "f";
luapad._sG["_E"]["MakeWirePixel"] = "f";
luapad._sG["_E"]["BTClientUpdateMessage"] = "f";
luapad._sG["_E"]["MakeWireOscilloscope"] = "f";
luapad._sG["_E"]["WireToolMakeExplosivesSimple"] = "f";
luapad._sG["_E"]["MakeWireLight"] = "f";
luapad._sG["_E"]["Wire_KeyPressed"] = "f";
luapad._sG["_E"]["Wire_KeyOff"] = "f";
luapad._sG["_E"]["MakeWireInput"] = "f";
luapad._sG["_E"]["MakeWire7Seg"] = "f";
luapad._sG["_E"]["PrecacheParticleSystem"] = "f";
luapad._sG["_E"]["MakeWireHologrid"] = "f";
luapad._sG["_E"]["Resend_GPU_Data"] = "f";
luapad._sG["_E"]["MakeWireGate"] = "f";
luapad._sG["_E"]["PCallError"] = "f";
luapad._sG["_E"]["validNPC"] = "f";
luapad._sG["_E"]["mess_with_args"] = "f";
luapad._sG["_E"]["pairs"] = "f";
luapad._sG["_E"]["Makewire_field_device"] = "f";
luapad._sG["_E"]["Egateglobalvarconnect"] = "f";
luapad._sG["_E"]["Egateglobalvardisconnect"] = "f";
luapad._sG["_E"]["freefallwiregates"] = "f";
luapad._sG["_E"]["exp2FindCleanup"] = "f";
luapad._sG["_E"]["Msg"] = "f";
luapad._sG["_E"]["getOwner"] = "f";
luapad._sG["_E"]["isOwner"] = "f";
luapad._sG["_E"]["validEntity"] = "f";
luapad._sG["_E"]["e2_remove_hook_fix"] = "f";
luapad._sG["_E"]["Exp2TextReceiving"] = "f";
luapad._sG["_E"]["WireToolMakeAdvPod"] = "f";
luapad._sG["_E"]["registerCallback"] = "f";
luapad._sG["_E"]["registerType"] = "f";
luapad._sG["_E"]["MakeWireDigitalScreen"] = "f";
luapad._sG["_E"]["MakeWireconsoleScreen"] = "f";
luapad._sG["_E"]["MakeWireButton"] = "f";
luapad._sG["_E"]["MakeWireAdvPod"] = "f";
luapad._sG["_E"]["InfuseSpecialOutputs"] = "f";
luapad._sG["_E"]["RingsNamingCallback"] = "f";
luapad._sG["_E"]["CC_GMOD_Tool"] = "f";
luapad._sG["_E"]["MakeWheel"] = "f";
luapad._sG["_E"]["MakeThruster"] = "f";
luapad._sG["_E"]["MakeSpawner"] = "f";
luapad._sG["_E"]["UpdateRenderTarget"] = "f";
luapad._sG["_E"]["MakeWireWeight"] = "f";
luapad._sG["_E"]["MakeHoverBall"] = "f";
luapad._sG["_E"]["MakeEmitter"] = "f";
luapad._sG["_E"]["MakeButton"] = "f";
luapad._sG["_E"]["PlayerDataUpdate"] = "f";
luapad._sG["_E"]["isDedicatedServer"] = "f";
luapad._sG["_E"]["MakeCont"] = "f";
luapad._sG["_E"]["ConditionName"] = "f";
luapad._sG["_E"]["ValidEntity"] = "f";
luapad._sG["_E"]["HTTPGet"] = "f";
luapad._sG["_E"]["MakeWireUserReader"] = "f";
luapad._sG["_E"]["MakeWireTargetFilter"] = "f";
luapad._sG["_E"]["MakeWireRangerBeta"] = "f";
luapad._sG["_E"]["MakeWireMotorController"] = "f";
luapad._sG["_E"]["MakeWireMicrophone"] = "f";
luapad._sG["_E"]["MakeWireMagnet"] = "f";
luapad._sG["_E"]["MakeWireKeycardReader"] = "f";
luapad._sG["_E"]["MakeWireHSRanger"] = "f";
luapad._sG["_E"]["MakeRadioSystems"] = "f";
luapad._sG["_E"]["MakeWireFreezerController"] = "f";
luapad._sG["_E"]["CreateDebugBuddy"] = "f";
luapad._sG["_E"]["ColorClamp"] = "f";
luapad._sG["_E"]["MakeWirefacer"] = "f";
luapad._sG["_E"]["MakeWireDynMemory"] = "f";
luapad._sG["_E"]["MakeWireDetcord"] = "f";
luapad._sG["_E"]["CCToggleDebug"] = "f";
luapad._sG["_E"]["MakeWirebtsrv"] = "f";
luapad._sG["_E"]["SetupWireGateExpression"] = "f";
luapad._sG["_E"]["MakeWirebtrecv"] = "f";
luapad._sG["_E"]["MakeWireAdvHudIndicator"] = "f";
luapad._sG["_E"]["MakeWireHSHoloemitter"] = "f";
luapad._sG["_E"]["SetGlobalFloat"] = "f";
luapad._sG["_E"]["MakeScaleEnt"] = "f";
luapad._sG["_E"]["MakeWireAdvInput"] = "f";
luapad._sG["_E"]["MakeWireWinch"] = "f";
luapad._sG["_E"]["MakeWireWinchController"] = "f";
luapad._sG["_E"]["MakeWireVectorThruster"] = "f";
luapad._sG["_E"]["MakeWireVehicle"] = "f";
luapad._sG["_E"]["MakeWireValue"] = "f";
luapad._sG["_E"]["MakeWireTrail"] = "f";
luapad._sG["_E"]["MakeWireReceiver"] = "f";
luapad._sG["_E"]["MakeWireTargetFinder"] = "f";
luapad._sG["_E"]["MakeWireSpawner"] = "f";
luapad._sG["_E"]["MakeWireOutput"] = "f";
luapad._sG["_E"]["MakeWireRadio"] = "f";
luapad._sG["_E"]["MakeWireNumpad"] = "f";
luapad._sG["_E"]["MakeWireNailer"] = "f";
luapad._sG["_E"]["MakeWireLatch"] = "f";
luapad._sG["_E"]["MakeWireLaserReciever"] = "f";
luapad._sG["_E"]["MakeWireKeyboard"] = "f";
luapad._sG["_E"]["MakeWireIgniter"] = "f";
luapad._sG["_E"]["GetGlobalFloat"] = "f";
luapad._sG["_E"]["Radio_Unregister"] = "f";
luapad._sG["_E"]["MakeWireGpu"] = "f";
luapad._sG["_E"]["MakeBomb"] = "f";
luapad._sG["_E"]["Error"] = "f";
luapad._sG["_E"]["MakeWireForcer"] = "f";
luapad._sG["_E"]["MakeWireExplosive"] = "f";
luapad._sG["_E"]["UpdateWireExplosive"] = "f";
luapad._sG["_E"]["MakeWireEmarker"] = "f";
luapad._sG["_E"]["EntityMarker_Removed"] = "f";
luapad._sG["_E"]["Add_EntityMarker"] = "f";
luapad._sG["_E"]["DebuggerThink"] = "f";
luapad._sG["_E"]["MakeWireTransferer"] = "f";
luapad._sG["_E"]["MakeWireStore"] = "f";
luapad._sG["_E"]["MakeWireDataPort"] = "f";
luapad._sG["_E"]["MakeWireDataSocket"] = "f";
luapad._sG["_E"]["MakeWireColorer"] = "f";
luapad._sG["_E"]["MakeWireCDLock"] = "f";
luapad._sG["_E"]["VGUIFrameTime"] = "f";
luapad._sG["_E"]["MakeWireCDRay"] = "f";
luapad._sG["_E"]["MakeWireCam"] = "f";
luapad._sG["_E"]["MakeWireAddressBus"] = "f";
luapad._sG["_E"]["HoloRightClick"] = "f";
luapad._sG["_E"]["WireToolMakeWeight"] = "f";
luapad._sG["_E"]["WireToolMakeInput"] = "f";
luapad._sG["_E"]["WireToolMakeButton"] = "f";
luapad._sG["_E"]["e2_parse_args"] = "f";
luapad._sG["_E"]["WireToolMakeTextScreen"] = "f";
luapad._sG["_E"]["WireToolMakeScreen"] = "f";
luapad._sG["_E"]["WireToolMakeLight"] = "f";
luapad._sG["_E"]["tonumber"] = "f";
luapad._sG["_E"]["WireToolMakeIndicator"] = "f";
luapad._sG["_E"]["WireToolMake7Seg"] = "f";
luapad._sG["_E"]["Wire_Restored"] = "f";
luapad._sG["_E"]["WireToolMakeSpeedometer"] = "f";
luapad._sG["_E"]["RunString"] = "f";
luapad._sG["_E"]["WireToolMakeGate"] = "f";
luapad._sG["_E"]["VerifyWireGateExpression"] = "f";
luapad._sG["_E"]["CCSpawnVehicle"] = "f";
luapad._sG["_E"]["CCSpawnSWEP"] = "f";
luapad._sG["_E"]["CCGiveSWEP"] = "f";
luapad._sG["_E"]["GMODSpawnEffect"] = "f";
luapad._sG["_E"]["FixInvalidPhysicsObject"] = "f";
luapad._sG["_E"]["IsEntity"] = "f";
luapad._sG["_E"]["NotifierSetSilent"] = "f";
luapad._sG["_E"]["MakeProp"] = "f";
luapad._sG["_E"]["GMODSpawnRagdoll"] = "f";
luapad._sG["_E"]["MaxPlayers"] = "f";
luapad._sG["_E"]["Wire_AfterPasteMods"] = "f";
luapad._sG["_E"]["Wire_SetPathNames"] = "f";
luapad._sG["_E"]["Wire_Link_Cancel"] = "f";
luapad._sG["_E"]["Wire_Link_Node"] = "f";
luapad._sG["_E"]["Wire_Remove"] = "f";
luapad._sG["_E"]["Wire_AdjustInputs"] = "f";
luapad._sG["_E"]["TextReceiver_Received"] = "f";
luapad._sG["_E"]["Radio_ChangeChannel"] = "f";
luapad._sG["_E"]["Radio_RecieveData"] = "f";
luapad._sG["_E"]["Radio_Register"] = "f";
luapad._sG["_E"]["CCPrivateMessage"] = "f";
luapad._sG["_E"]["DestroyDebugBuddy"] = "f";
luapad._sG["_E"]["SysTime"] = "f";
luapad._sG["_E"]["Entity"] = "f";
luapad._sG["_E"]["GetGlobalBeamString"] = "f";
luapad._sG["_E"]["SetGlobalBeamBool"] = "f";
luapad._sG["_E"]["SetGlobalBeamEntity"] = "f";
luapad._sG["_E"]["GetGlobalBeamInt"] = "f";
luapad._sG["_E"]["GetGlobalBeamFloat"] = "f";
luapad._sG["_E"]["GetGlobalBeamAngle"] = "f";
luapad._sG["_E"]["SetGlobalBeamAngle"] = "f";
luapad._sG["_E"]["GetGlobalBeamVector"] = "f";
luapad._sG["_E"]["SetGlobalBeamVector"] = "f";
luapad._sG["_E"]["PC_PortSelected"] = "f";
luapad._sG["_E"]["PC_BeamPorts"] = "f";
luapad._sG["_E"]["module"] = "f";
luapad._sG["_E"]["MakeWireGateExpression"] = "f";
luapad._sG["_E"]["Color"] = "f";
luapad._sG["_E"]["getfenv"] = "f";
luapad._sG["_E"]["QuaternionNLerp"] = "f";
luapad._sG["_E"]["Dbg"] = "f";
luapad._sG["_E"]["NotifierSetConsole"] = "f";
luapad._sG["_E"]["SortedPairs"] = "f";
luapad._sG["_E"]["MeshQuad"] = "f";
luapad._sG["_E"]["MeshCube"] = "f";
luapad._sG["_E"]["xpcall"] = "f";
luapad._sG["_E"]["SendUserMessage"] = "f";
luapad._sG["_E"]["decode"] = "f";
luapad._sG["_E"]["TimedCos"] = "f";
luapad._sG["_E"]["TimedSin"] = "f";
luapad._sG["_E"]["STNDRD"] = "f";
luapad._sG["_E"]["RestoreCursorPosition"] = "f";
luapad._sG["_E"]["RememberCursorPosition"] = "f";
luapad._sG["_E"]["SafeRemoveEntityDelayed"] = "f";
luapad._sG["_E"]["tablekeys"] = "f";
luapad._sG["_E"]["AccessorFuncNW"] = "f";
luapad._sG["_E"]["AccessorFunc"] = "f";
luapad._sG["_E"]["UTIL_IsUselessModel"] = "f";
luapad._sG["_E"]["Model"] = "f";
luapad._sG["_E"]["Sound"] = "f";
luapad._sG["_E"]["PrintTable"] = "f";
luapad._sG["_E"]["error"] = "f";
luapad._sG["_E"]["MakeWireCDDisk"] = "f";
luapad._sG["_E"]["Wire_KeyOn"] = "f";
luapad._sG["_E"]["LerpVector"] = "f";
luapad._sG["_E"]["assert"] = "f";
luapad._sG["_E"]["GetMountedContent"] = "f";
luapad._sG["_E"]["MakeWireWatersensor"] = "f";
luapad._sG["_E"]["MakeWireCpu"] = "f";
luapad._sG["_E"]["Vector"] = "f";
luapad._sG["_E"]["RecipientFilter"] = "f";
luapad._sG["_E"]["GetConVar"] = "f";
luapad._sG["_E"]["PhysObject"] = "f";
luapad._sG["_E"]["GetGlobalString"] = "f";
luapad._sG["_E"]["GetHostName"] = "f";
luapad._sG["_E"]["GetGlobalVector"] = "f";
luapad._sG["_E"]["MakeWirehdd"] = "f";
luapad._sG["_E"]["GetGlobalVar"] = "f";
luapad._sG["_E"]["SetGlobalInt"] = "f";
luapad._sG["_E"]["SetGlobalVar"] = "f";
luapad._sG["_E"]["Angle"] = "f";
luapad._sG["_E"]["MakeNpc"] = "f";
luapad._sG["_E"]["HoloReload"] = "f";
luapad._sG["_E"]["SetPhysConstraintSystem"] = "f";
luapad._sG["_E"]["MakeBalloon"] = "f";
luapad._sG["_E"]["ClientCallGamemode"] = "f";
luapad._sG["_E"]["AddCSLuaFile"] = "f";
luapad._sG["_E"]["IsFirstTimePredicted"] = "f";
luapad._sG["_E"]["CreateClientConVar"] = "f";
luapad._sG["_E"]["PrecacheScene"] = "f";
luapad._sG["_E"]["LocalToWorld"] = "f";
luapad._sG["_E"]["Lerp"] = "f";
luapad._sG["_E"]["DropEntityIfHeld"] = "f";
luapad._sG["_E"]["MakeDynamite"] = "f";
luapad._sG["_E"]["KeyValuesToTable"] = "f";
luapad._sG["_E"]["CCDial"] = "f";
luapad._sG["_E"]["RunConsoleCommand"] = "f";
luapad._sG["_E"]["CreateConVar"] = "f";
luapad._sG["_E"]["FindMetaTable"] = "f";
luapad._sG["_E"]["ConVarExists"] = "f";
luapad._sG["_E"]["GetConVarString"] = "f";
luapad._sG["_E"]["GetAllEnts"] = "f";
luapad._sG["_E"]["include"] = "f";
luapad._sG["_E"]["ErrorNoHalt"] = "f";
luapad._sG["_E"]["MatrixFromAngle"] = "f";
luapad._sG["_E"]["ModelPlug_Register"] = "f";
luapad._sG["_E"]["MakeWireExpression2"] = "f";
luapad._sG["_E"]["Wire_CreateOutputIterator"] = "f";
luapad._sG["_E"]["tostring"] = "f";
luapad._sG["_E"]["MakeWireNotifier"] = "f";
luapad._sG["_E"]["GetGamemodes"] = "f";
luapad._sG["_E"]["DoPropSpawnedEffect"] = "f";
luapad._sG["_E"]["RingsDiallingCallback"] = "f";
luapad._sG["_E"]["LerpAngle"] = "f";
luapad._sG["_E"]["BroadcastLua"] = "f";
luapad._sG["_E"]["MakeWireSatellitedish"] = "f";
luapad._sG["_E"]["print"] = "f";
luapad._sG["_E"]["MakeWiredatarate"] = "f";
luapad._sG["_E"]["Wire_AdjustOutputs"] = "f";
luapad._sG["_E"]["SoundDuration"] = "f";
luapad._sG["_E"]["GetMountableContent"] = "f";
luapad._sG["_E"]["WireExpressionGetLines"] = "f";
luapad._sG["_E"]["MakeWireStringBuffer"] = "f";
luapad._sG["_E"]["MakeWireSimpleExplosive"] = "f";
luapad._sG["_E"]["CreateClient"] = "f";
luapad._sG["_E"]["MakeWireServo"] = "f";
luapad._sG["_E"]["require"] = "f";
luapad._sG["_E"]["Wire_Link_Start"] = "f";
luapad._sG["_E"]["MakeWireGraphicsTablet"] = "f";
luapad._sG["_E"]["Player"] = "f";
luapad._sG["_E"]["engineConsoleCommand"] = "f";
luapad._sG["_E"]["WireToolMakeWheel"] = "f";
luapad._sG["_E"]["MakeWireThruster"] = "f";
luapad._sG["_E"]["tobool"] = "f";
luapad._sG["_E"]["type"] = "f";
luapad._sG["_E"]["checkEntity"] = "f";
luapad._sG["_E"]["StringExplode"] = "f";
luapad._sG["_E"]["IsVector"] = "f";
luapad._sG["_E"]["Wire_CreateInputs"] = "f";
luapad._sG["_E"]["GetTaskID"] = "f";
luapad._sG["_E"]["SortedPairsByMemberValue"] = "f";
luapad._sG["_E"]["___comp___"] = "f";
luapad._sG["_E"]["MakeWireSensor"] = "f";
luapad._sG["_E"]["WireToolMakeUseEmitter"] = "f";
luapad._sG["filex"]["Append"] = "f";
luapad._sG["Serialiser"]["SaveTablesToFile"] = "f";
luapad._sG["Serialiser"]["SerialiseWithHeaders"] = "f";
luapad._sG["Serialiser"]["SingleTable"] = "f";
luapad._sG["Serialiser"]["DeserialiseWithHeaders"] = "f";
luapad._sG["Serialiser"]["SerialiseTableKeyValues"] = "f";
luapad._sG["Serialiser"]["DeserialiseBlock"] = "f";
luapad._sG["MMatrix"]["Divide"] = "f";
luapad._sG["MMatrix"]["Determinant"] = "f";
luapad._sG["MMatrix"]["Multiply"] = "f";
luapad._sG["MMatrix"]["Copy"] = "f";
luapad._sG["MMatrix"]["__error"] = "f";
luapad._sG["MMatrix"]["Trace"] = "f";
luapad._sG["MMatrix"]["Invert"] = "f";
luapad._sG["MMatrix"]["New"] = "f";
luapad._sG["MMatrix"]["Sub"] = "f";
luapad._sG["MMatrix"]["Div"] = "f";
luapad._sG["MMatrix"]["RotationMatrix"] = "f";
luapad._sG["MMatrix"]["Trans"] = "f";
luapad._sG["MMatrix"]["Adj"] = "f";
luapad._sG["MMatrix"]["__AddAndSubstract"] = "f";
luapad._sG["MMatrix"]["Det"] = "f";
luapad._sG["MMatrix"]["EulerRotationMatrix"] = "f";
luapad._sG["MMatrix"]["Inv"] = "f";
luapad._sG["MMatrix"]["Mul"] = "f";
luapad._sG["MMatrix"]["Stroke"] = "f";
luapad._sG["MMatrix"]["__IsMatrix"] = "f";
luapad._sG["MMatrix"]["Pow"] = "f";
luapad._sG["MMatrix"]["Adjugate"] = "f";
luapad._sG["MMatrix"]["Transpose"] = "f";
luapad._sG["MMatrix"]["Add"] = "f";
luapad._sG["Tokenizer"]["NextCharacter"] = "f";
luapad._sG["Tokenizer"]["NextOperator"] = "f";
luapad._sG["Tokenizer"]["Process"] = "f";
luapad._sG["Tokenizer"]["Execute"] = "f";
luapad._sG["Tokenizer"]["NextSymbol"] = "f";
luapad._sG["Tokenizer"]["Error"] = "f";
luapad._sG["Tokenizer"]["SkipCharacter"] = "f";


-- Enumerations

luapad._sG["ACT_MP_GESTURE_VC_NODYES"] = "e";
luapad._sG["ACT_MELEE_ATTACK_SWING_GESTURE"] = "e";
luapad._sG["SCHED_TAKE_COVER_FROM_ORIGIN"] = "e";
luapad._sG["KEY_A"] = "e";
luapad._sG["ACT_DOD_CROUCH_IDLE_C96"] = "e";
luapad._sG["ACT_IDLE_STEALTH"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_DEPLOYED"] = "e";
luapad._sG["ACT_MP_STAND_PRIMARY"] = "e";
luapad._sG["ACT_DOD_RUN_IDLE_BAZOOKA"] = "e";
luapad._sG["MASK_VISIBLE_AND_NPCS"] = "e";
luapad._sG["ACT_GLOCK_SHOOT_RELOAD"] = "e";
luapad._sG["TEXT_ALIGN_CENTER"] = "e";
luapad._sG["DMG_CRUSH"] = "e";
luapad._sG["ACT_DOD_RELOAD_CROUCH_BAR"] = "e";
luapad._sG["ACT_HL2MP_JUMP_PASSIVE"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_HANDMOUTH_SECONDARY"] = "e";
luapad._sG["ACT_MP_JUMP_START_MELEE"] = "e";
luapad._sG["ACT_GET_UP_CROUCH"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_IDLE_GREASE"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_IDLE_PISTOL"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RELOAD_SLAM"] = "e";
luapad._sG["SIMPLE_USE"] = "e";
luapad._sG["ACT_DOD_WALK_AIM_GREN_STICK"] = "e";
luapad._sG["ACT_DOD_PRONEWALK_IDLE_MG"] = "e";
luapad._sG["ACT_DOD_DEPLOY_RIFLE"] = "e";
luapad._sG["KEY_6"] = "e";
luapad._sG["ACT_MP_RUN_MELEE"] = "e";
luapad._sG["HULL_WIDE_SHORT"] = "e";
luapad._sG["SIM_GLOBAL_FORCE"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST"] = "e";
luapad._sG["ACT_OVERLAY_PRIMARYATTACK"] = "e";
luapad._sG["SF_NPC_FALL_TO_GROUND"] = "e";
luapad._sG["KEY_O"] = "e";
luapad._sG["ACT_OVERLAY_GRENADEREADY"] = "e";
luapad._sG["ACT_COVER_MED"] = "e";
luapad._sG["HULL_WIDE_HUMAN"] = "e";
luapad._sG["ACT_HL2MP_JUMP_RPG"] = "e";
luapad._sG["ACT_DOD_STAND_AIM_MG"] = "e";
luapad._sG["1"] = "e";
luapad._sG["MAT_VENT"] = "e";
luapad._sG["ACT_VM_HITRIGHT2"] = "e";
luapad._sG["ACT_VM_RELOAD_EMPTY"] = "e";
luapad._sG["ACT_HL2MP_RUN_KNIFE"] = "e";
luapad._sG["ACT_HL2MP_IDLE_PISTOL"] = "e";
luapad._sG["ACT_MP_CROUCH_IDLE"] = "e";
luapad._sG["COLLISION_GROUP_VEHICLE"] = "e";
luapad._sG["KEY_XBUTTON_B"] = "e";
luapad._sG["KEY_XBUTTON_START"] = "e";
luapad._sG["CAP_MOVE_CRAWL"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_AIM_BOLT"] = "e";
luapad._sG["ACT_MP_MELEE_GRENADE2_DRAW"] = "e";
luapad._sG["ACT_DIE_BARNACLE_SWALLOW"] = "e";
luapad._sG["ACT_WALK_STEALTH_PISTOL"] = "e";
luapad._sG["ACT_DOD_PRONE_AIM_MP44"] = "e";
luapad._sG["ACT_IDLE_ANGRY_MELEE"] = "e";
luapad._sG["MOVETYPE_NONE"] = "e";
luapad._sG["ACT_DOD_RUN_IDLE_BOLT"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_AIM_RIFLE"] = "e";
luapad._sG["ACT_DOD_RELOAD_RIFLEGRENADE"] = "e";
luapad._sG["ACT_MP_ATTACK_AIRWALK_BUILDING"] = "e";
luapad._sG["FVPHYSICS_DMG_DISSOLVE"] = "e";
luapad._sG["ACT_INVALID"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_MP44"] = "e";
luapad._sG["ACT_SLAM_TRIPMINE_DRAW"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_NODNO"] = "e";
luapad._sG["ACT_DOD_SPRINT_IDLE_BOLT"] = "e";
luapad._sG["ACT_MP_PRIMARY_GRENADE1_IDLE"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK_DEPLOYED_1"] = "e";
luapad._sG["MASK_SHOT"] = "e";
luapad._sG["MOVETYPE_ISOMETRIC"] = "e";
luapad._sG["ACT_GESTURE_RANGE_ATTACK_SMG1_LOW"] = "e";
luapad._sG["ACT_SHIELD_ATTACK"] = "e";
luapad._sG["ACT_GESTURE_RANGE_ATTACK_SMG2"] = "e";
luapad._sG["ACT_HL2MP_WALK"] = "e";
luapad._sG["MASK_SHOT_PORTAL"] = "e";
luapad._sG["ACT_SLAM_THROW_THROW_ND2"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_PISTOL"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_FINGERPOINT_BUILDING"] = "e";
luapad._sG["BOX_TOP"] = "e";
luapad._sG["SCHED_FAIL_NOSTOP"] = "e";
luapad._sG["ACT_DOD_RELOAD_BOLT"] = "e";
luapad._sG["ACT_DOD_RUN_ZOOM_BOLT"] = "e";
luapad._sG["ACT_MP_RELOAD_AIRWALK_LOOP"] = "e";
luapad._sG["ACT_DEEPIDLE1"] = "e";
luapad._sG["DMG_DIRECT"] = "e";
luapad._sG["ACT_SLAM_DETONATOR_IDLE"] = "e";
luapad._sG["FVPHYSICS_NO_IMPACT_DMG"] = "e";
luapad._sG["CLASS_CONSCRIPT"] = "e";
luapad._sG["CONTINUOUS_USE"] = "e";
luapad._sG["ACT_MP_ATTACK_CROUCH_GRENADE_PRIMARY"] = "e";
luapad._sG["ACT_SPECIAL_ATTACK2"] = "e";
luapad._sG["ACT_RANGE_ATTACK_AR1"] = "e";
luapad._sG["ACT_MP_DEPLOYED_IDLE"] = "e";
luapad._sG["ACT_MP_ATTACK_SWIM_PRIMARYFIRE"] = "e";
luapad._sG["ACT_IDLE_RELAXED"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK"] = "e";
luapad._sG["ACT_VM_DEPLOY_EMPTY"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RELOAD_RPG"] = "e";
luapad._sG["ACT_DOD_SECONDARYATTACK_PRONE_TOMMY"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_KNIFE"] = "e";
luapad._sG["CLASS_SCANNER"] = "e";
luapad._sG["ACT_MP_CROUCHWALK_SECONDARY"] = "e";
luapad._sG["ACT_DOD_SECONDARYATTACK_BOLT"] = "e";
luapad._sG["SF_NPC_ALWAYSTHINK"] = "e";
luapad._sG["ACT_DOD_WALK_IDLE_TNT"] = "e";
luapad._sG["ACT_GAUSS_SPINUP"] = "e";
luapad._sG["ACT_IDLE_SMG1_RELAXED"] = "e";
luapad._sG["ACT_IDLE_AIM_STEALTH"] = "e";
luapad._sG["ACT_DOD_STAND_ZOOM_RIFLE"] = "e";
luapad._sG["IN_LEFT"] = "e";
luapad._sG["IN_ALT2"] = "e";
luapad._sG["ACT_MP_SWIM_DEPLOYED"] = "e";
luapad._sG["SCHED_AISCRIPT"] = "e";
luapad._sG["BUTTON_CODE_INVALID"] = "e";
luapad._sG["ACT_MP_ATTACK_SWIM_SECONDARY"] = "e";
luapad._sG["KEY_4"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_FISTPUMP_MELEE"] = "e";
luapad._sG["ACT_DOD_RUN_IDLE_PSCHRECK"] = "e";
luapad._sG["ACT_PICKUP_GROUND"] = "e";
luapad._sG["ACT_DOD_CROUCH_IDLE_MG"] = "e";
luapad._sG["ACT_BUSY_SIT_CHAIR"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_AIM_KNIFE"] = "e";
luapad._sG["ACT_DOD_CROUCH_IDLE_30CAL"] = "e";
luapad._sG["ACT_DOD_PRONEWALK_AIM_SPADE"] = "e";
luapad._sG["ACT_HL2MP_IDLE_RPG"] = "e";
luapad._sG["OBS_MODE_FIXED"] = "e";
luapad._sG["CAP_WEAPON_MELEE_ATTACK2"] = "e";
luapad._sG["ACT_VM_DRAW_EMPTY"] = "e";
luapad._sG["SURF_WARP"] = "e";
luapad._sG["MAT_SLOSH"] = "e";
luapad._sG["ACT_DOD_WALK_ZOOM_PSCHRECK"] = "e";
luapad._sG["ACT_MP_JUMP_LAND_MELEE"] = "e";
luapad._sG["ACT_DOD_RELOAD_PSCHRECK"] = "e";
luapad._sG["ACT_DOD_RELOAD_CROUCH"] = "e";
luapad._sG["ACT_DOD_RELOAD_CROUCH_MP44"] = "e";
luapad._sG["ACT_HL2MP_FIST_BLOCK"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK_EMPTY"] = "e";
luapad._sG["ACT_RANGE_AIM_PISTOL_LOW"] = "e";
luapad._sG["SERVER"] = "e";
luapad._sG["ACT_MP_ATTACK_CROUCH_PRIMARY"] = "e";
luapad._sG["KEY_PAD_8"] = "e";
luapad._sG["ACT_CROUCHING_SHIELD_UP"] = "e";
luapad._sG["KEY_LALT"] = "e";
luapad._sG["ACT_DIEVIOLENT"] = "e";
luapad._sG["ACT_DOD_CROUCH_AIM_GREN_STICK"] = "e";
luapad._sG["FCVAR_NOT_CONNECTED"] = "e";
luapad._sG["KEY_LBRACKET"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_IDLE_MP44"] = "e";
luapad._sG["ACT_CROUCHING_SHIELD_DOWN"] = "e";
luapad._sG["ACT_RUN_AIM_RIFLE"] = "e";
luapad._sG["ACT_VM_PULLBACK_HIGH"] = "e";
luapad._sG["TEXT_ALIGN_BOTTOM"] = "e";
luapad._sG["ACT_HL2MP_WALK_AR2"] = "e";
luapad._sG["ACT_RUN_PROTECTED"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_AIM_BAR"] = "e";
luapad._sG["MASK_SOLID"] = "e";
luapad._sG["ACT_DOD_PRONEWALK_IDLE_PSCHRECK"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_MP44"] = "e";
luapad._sG["ACT_STARTDYING"] = "e";
luapad._sG["MOVETYPE_NOCLIP"] = "e";
luapad._sG["FVPHYSICS_PENETRATING"] = "e";
luapad._sG["NPC_STATE_INVALID"] = "e";
luapad._sG["SCHED_COWER"] = "e";
luapad._sG["ACT_ITEM_THROW"] = "e";
luapad._sG["FORCE_STRING"] = "e";
luapad._sG["HITGROUP_LEFTLEG"] = "e";
luapad._sG["ACT_GET_DOWN_STAND"] = "e";
luapad._sG["ACT_DOD_PRONE_ZOOM_FORWARD_RIFLE"] = "e";
luapad._sG["ACT_DOD_PRONEWALK_IDLE_MP40"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_NODNO_SECONDARY"] = "e";
luapad._sG["HUD_PRINTCONSOLE"] = "e";
luapad._sG["D_NU"] = "e";
luapad._sG["KEY_PAD_0"] = "e";
luapad._sG["ACT_MP_RUN_SECONDARY"] = "e";
luapad._sG["ACT_DIE_BACKSHOT"] = "e";
luapad._sG["ACT_WALK_CROUCH_RIFLE"] = "e";
luapad._sG["ACT_MP_ATTACK_STAND_GRENADE_PRIMARY"] = "e";
luapad._sG["ACT_CROSSBOW_IDLE_UNLOADED"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_ZOOM_BOLT"] = "e";
luapad._sG["ACT_DOD_SPRINT_AIM_KNIFE"] = "e";
luapad._sG["ACT_BARNACLE_PULL"] = "e";
luapad._sG["_G"] = "e";
luapad._sG["CONTENTS_TESTFOGVOLUME"] = "e";
luapad._sG["ACT_DIE_LEFTSIDE"] = "e";
luapad._sG["SCHED_TARGET_FACE"] = "e";
luapad._sG["ACT_MP_JUMP_LAND_PRIMARY"] = "e";
luapad._sG["ACT_OVERLAY_SHIELD_ATTACK"] = "e";
luapad._sG["SCHED_ALERT_WALK"] = "e";
luapad._sG["ACT_SIGNAL_ADVANCE"] = "e";
luapad._sG["ACT_DOD_RELOAD_CROUCH_RIFLEGRENADE"] = "e";
luapad._sG["KEY_XSTICK1_DOWN"] = "e";
luapad._sG["COMP_NUMBER"] = "e";
luapad._sG["SCHED_SPECIAL_ATTACK1"] = "e";
luapad._sG["RENDERGROUP_TRANSLUCENT"] = "e";
luapad._sG["KEY_F6"] = "e";
luapad._sG["ACT_HANDGRENADE_THROW3"] = "e";
luapad._sG["ACT_OVERLAY_SHIELD_UP"] = "e";
luapad._sG["HITGROUP_CHEST"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_SPADE"] = "e";
luapad._sG["ACT_HL2MP_JUMP_SMG1"] = "e";
luapad._sG["ACT_DOD_STAND_AIM_MP40"] = "e";
luapad._sG["KEY_APOSTROPHE"] = "e";
luapad._sG["ACT_VM_DETACH_SILENCER"] = "e";
luapad._sG["KEY_ENTER"] = "e";
luapad._sG["SCHED_MOVE_TO_WEAPON_RANGE"] = "e";
luapad._sG["ACT_MP_RELOAD_AIRWALK_SECONDARY"] = "e";
luapad._sG["KEY_F7"] = "e";
luapad._sG["ACT_HL2MP_WALK_CROUCH_AR2"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2"] = "e";
luapad._sG["ACT_MP_WALK_MELEE"] = "e";
luapad._sG["DMG_ACID"] = "e";
luapad._sG["ACT_MP_RELOAD_AIRWALK_PRIMARY_LOOP"] = "e";
luapad._sG["ACT_HL2MP_RUN_RPG"] = "e";
luapad._sG["ACT_MP_RELOAD_SWIM_SECONDARY_END"] = "e";
luapad._sG["ACT_VM_IDLE_DEPLOYED_4"] = "e";
luapad._sG["ACT_IDLE_MANNEDGUN"] = "e";
luapad._sG["ACT_DOD_RELOAD_K43"] = "e";
luapad._sG["ACT_HL2MP_RUN_SHOTGUN"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK_8"] = "e";
luapad._sG["MOVECOLLIDE_DEFAULT"] = "e";
luapad._sG["ACT_DOD_WALK_IDLE_GREASE"] = "e";
luapad._sG["NPC_STATE_PRONE"] = "e";
luapad._sG["FCVAR_GAMEDLL"] = "e";
luapad._sG["ACT_PLAYER_CROUCH_FIRE"] = "e";
luapad._sG["ACT_MP_ATTACK_AIRWALK_GRENADE_BUILDING"] = "e";
luapad._sG["HITGROUP_RIGHTARM"] = "e";
luapad._sG["_R"] = "e";
luapad._sG["ACT_FLINCH_RIGHTLEG"] = "e";
luapad._sG["ACT_MP_PRIMARY_GRENADE1_ATTACK"] = "e";
luapad._sG["DMG_PHYSGUN"] = "e";
luapad._sG["ONOFF_USE"] = "e";
luapad._sG["ACT_HL2MP_JUMP_SLAM"] = "e";
luapad._sG["ACT_HL2MP_WALK_CROUCH_CROSSBOW"] = "e";
luapad._sG["SURF_TRIGGER"] = "e";
luapad._sG["ACT_MP_ATTACK_STAND_PRIMARYFIRE"] = "e";
luapad._sG["DMG_SLOWBURN"] = "e";
luapad._sG["ACT_HL2MP_WALK_CROUCH_PASSIVE"] = "e";
luapad._sG["ACT_DUCK_DODGE"] = "e";
luapad._sG["HULL_MEDIUM_TALL"] = "e";
luapad._sG["ACT_DOD_RUN_AIM"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_THUMBSUP_PRIMARY"] = "e";
luapad._sG["ACT_HL2MP_JUMP_KNIFE"] = "e";
luapad._sG["ACT_HL2MP_WALK_FIST"] = "e";
luapad._sG["MOVECOLLIDE_FLY_BOUNCE"] = "e";
luapad._sG["SURF_HITBOX"] = "e";
luapad._sG["ACT_MP_ATTACK_AIRWALK_MELEE"] = "e";
luapad._sG["ACT_MP_WALK_PDA"] = "e";
luapad._sG["KEY_XBUTTON_A"] = "e";
luapad._sG["SF_CITIZEN_RANDOM_HEAD"] = "e";
luapad._sG["KEY_G"] = "e";
luapad._sG["ACT_HL2MP_IDLE_CROUCH_MELEE"] = "e";
luapad._sG["ACT_TURN_RIGHT"] = "e";
luapad._sG["ACT_DOD_SPRINT_IDLE_RIFLE"] = "e";
luapad._sG["ACT_DOD_WALK_IDLE_PSCHRECK"] = "e";
luapad._sG["DMG_DROWN"] = "e";
luapad._sG["DMG_BURN"] = "e";
luapad._sG["ACT_MP_SWIM_BUILDING"] = "e";
luapad._sG["CONTENTS_SOLID"] = "e";
luapad._sG["ACT_MP_STAND_IDLE"] = "e";
luapad._sG["SCHED_SCENE_GENERIC"] = "e";
luapad._sG["KEY_INSERT"] = "e";
luapad._sG["ACT_MP_RELOAD_AIRWALK_SECONDARY_END"] = "e";
luapad._sG["ACT_CROUCH"] = "e";
luapad._sG["ACT_VM_PULLBACK_LOW"] = "e";
luapad._sG["NPC_STATE_IDLE"] = "e";
luapad._sG["ACT_MP_RELOAD_SWIM_END"] = "e";
luapad._sG["ACT_MP_ATTACK_CROUCH_GRENADE_SECONDARY"] = "e";
luapad._sG["ACT_OPEN_DOOR"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_DEPLOYED_MG"] = "e";
luapad._sG["ACT_IDLE_ANGRY_PISTOL"] = "e";
luapad._sG["ACT_DOD_STAND_ZOOM_PSCHRECK"] = "e";
luapad._sG["ACT_READINESS_PISTOL_RELAXED_TO_STIMULATED"] = "e";
luapad._sG["MASK_PLAYERSOLID"] = "e";
luapad._sG["SF_PHYSBOX_NEVER_PICK_UP"] = "e";
luapad._sG["ACT_GESTURE_RANGE_ATTACK_ML"] = "e";
luapad._sG["ACT_DOD_RELOAD_CROUCH_PISTOL"] = "e";
luapad._sG["CLASS_ZOMBIE"] = "e";
luapad._sG["ACT_RPG_IDLE_UNLOADED"] = "e";
luapad._sG["ACT_IDLE_SHOTGUN_RELAXED"] = "e";
luapad._sG["ACT_MP_JUMP"] = "e";
luapad._sG["MOVETYPE_FLYGRAVITY"] = "e";
luapad._sG["MAT_FOLIAGE"] = "e";
luapad._sG["ACT_VM_MISSRIGHT"] = "e";
luapad._sG["ACT_MP_RELOAD_CROUCH_PRIMARY_LOOP"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_FISTPUMP"] = "e";
luapad._sG["ACT_RELOAD_PISTOL_LOW"] = "e";
luapad._sG["SF_NPC_NO_WEAPON_DROP"] = "e";
luapad._sG["ACT_SLAM_STICKWALL_DRAW"] = "e";
luapad._sG["ACT_HL2MP_WALK_CROUCH_GRENADE"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_IDLE_PSCHRECK"] = "e";
luapad._sG["SCHED_RUN_RANDOM"] = "e";
luapad._sG["ACT_MP_AIRWALK_SECONDARY"] = "e";
luapad._sG["ALL_VISIBLE_CONTENTS"] = "e";
luapad._sG["ACT_DOD_SPRINT_IDLE_GREASE"] = "e";
luapad._sG["SURF_NOPORTAL"] = "e";
luapad._sG["KEY_K"] = "e";
luapad._sG["ACT_SIGNAL2"] = "e";
luapad._sG["KEY_8"] = "e";
luapad._sG["FCVAR_ARCHIVE_XBOX"] = "e";
luapad._sG["KEY_PAD_MULTIPLY"] = "e";
luapad._sG["RENDERGROUP_OPAQUE"] = "e";
luapad._sG["ACT_RUN_AIM_STIMULATED"] = "e";
luapad._sG["SCHED_COMBAT_WALK"] = "e";
luapad._sG["ACT_DEEPIDLE2"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_THUMBSUP"] = "e";
luapad._sG["ACT_DOD_RUN_IDLE_30CAL"] = "e";
luapad._sG["ACT_DRIVE_AIRBOAT"] = "e";
luapad._sG["ACT_GMOD_SIT_ROLLERCOASTER"] = "e";
luapad._sG["KEY_X"] = "e";
luapad._sG["TYPE_MUSCLE"] = "e";
luapad._sG["MOUSE_4"] = "e";
luapad._sG["HUD_PRINTNOTIFY"] = "e";
luapad._sG["ACT_DOD_SPRINT_IDLE_MP40"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_C96"] = "e";
luapad._sG["KEY_LEFT"] = "e";
luapad._sG["PATTACH_ABSORIGIN"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RELOAD_PHYSGUN"] = "e";
luapad._sG["MASK_ALL"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_GREN_FRAG"] = "e";
luapad._sG["ACT_DOD_RUN_ZOOM_PSCHRECK"] = "e";
luapad._sG["ACT_DOD_PRONEWALK_IDLE_TNT"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1"] = "e";
luapad._sG["ACT_RANGE_ATTACK2"] = "e";
luapad._sG["ACT_GESTURE_TURN_RIGHT45_FLAT"] = "e";
luapad._sG["CONTENTS_TEAM3"] = "e";
luapad._sG["ACT_DOD_WALK_AIM_SPADE"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_GREASE"] = "e";
luapad._sG["FVPHYSICS_PLAYER_HELD"] = "e";
luapad._sG["KEY_RCONTROL"] = "e";
luapad._sG["ACT_GESTURE_RANGE_ATTACK_SNIPER_RIFLE"] = "e";
luapad._sG["SF_NPC_DROP_HEALTHKIT"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_DEPLOYED_MG"] = "e";
luapad._sG["ACT_RUN_STEALTH"] = "e";
luapad._sG["ACT_VM_IDLE_DEPLOYED_EMPTY"] = "e";
luapad._sG["HITGROUP_LEFTARM"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_DEPLOYED_MG34"] = "e";
luapad._sG["SF_PHYSPROP_PREVENT_PICKUP"] = "e";
luapad._sG["ACT_HL2MP_WALK_CROUCH"] = "e";
luapad._sG["ACT_DOD_RELOAD_DEPLOYED_MG"] = "e";
luapad._sG["SCHED_FLEE_FROM_BEST_SOUND"] = "e";
luapad._sG["ACT_MP_CROUCH_SECONDARY"] = "e";
luapad._sG["ACT_OBJ_UPGRADING"] = "e";
luapad._sG["ACT_DOD_CROUCH_AIM"] = "e";
luapad._sG["SF_NPC_ALTCOLLISION"] = "e";
luapad._sG["ACT_MP_AIRWALK_PRIMARY"] = "e";
luapad._sG["ACT_DOD_STAND_IDLE_TNT"] = "e";
luapad._sG["ACT_MP_GRENADE1_DRAW"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_DEPLOYED_FG42"] = "e";
luapad._sG["ACT_RANGE_ATTACK_AR2"] = "e";
luapad._sG["SF_NPC_GAG"] = "e";
luapad._sG["RADIOSYSTEMS"] = "e";
luapad._sG["PLUGIN"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_RIFLEGRENADE"] = "e";
luapad._sG["FCVAR_SPONLY"] = "e";
luapad._sG["KEY_HOME"] = "e";
luapad._sG["ACT_IDLE_STEALTH_PISTOL"] = "e";
luapad._sG["CAP_MOVE_SHOOT"] = "e";
luapad._sG["ACT_VM_DRAW_DEPLOYED"] = "e";
luapad._sG["MOVETYPE_LADDER"] = "e";
luapad._sG["ACT_FLINCH_CHEST"] = "e";
luapad._sG["ACT_DOD_HS_CROUCH_KNIFE"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_DEPLOYED_MG"] = "e";
luapad._sG["JOYSTICK_FIRST"] = "e";
luapad._sG["ACT_MP_SECONDARY_GRENADE2_IDLE"] = "e";
luapad._sG["SCHED_SCRIPTED_FACE"] = "e";
luapad._sG["ACT_DOD_RUN_IDLE_RIFLE"] = "e";
luapad._sG["ACT_MP_ATTACK_STAND_GRENADE_SECONDARY"] = "e";
luapad._sG["ACT_IDLE_RIFLE"] = "e";
luapad._sG["KEY_M"] = "e";
luapad._sG["ACT_SLAM_TRIPMINE_IDLE"] = "e";
luapad._sG["ACT_HL2MP_RUN_SMG1"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK_DEPLOYED"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_ZOOM_RIFLE"] = "e";
luapad._sG["ACT_VM_IDLE"] = "e";
luapad._sG["ACT_MP_RELOAD_AIRWALK"] = "e";
luapad._sG["ACT_DOD_WALK_ZOOM_RIFLE"] = "e";
luapad._sG["ACT_DOD_HS_CROUCH_STICKGRENADE"] = "e";
luapad._sG["ACT_VM_DRYFIRE"] = "e";
luapad._sG["BLOOD_COLOR_YELLOW"] = "e";
luapad._sG["ACT_MP_RELOAD_CROUCH_PRIMARY"] = "e";
luapad._sG["ACT_DOD_CROUCH_ZOOM_BOLT"] = "e";
luapad._sG["ACT_DOD_STAND_IDLE_MP44"] = "e";
luapad._sG["ACT_MP_ATTACK_CROUCH_GRENADE"] = "e";
luapad._sG["IN_MOVERIGHT"] = "e";
luapad._sG["PLAYER_WALK"] = "e";
luapad._sG["ACT_MP_ATTACK_STAND_GRENADE_MELEE"] = "e";
luapad._sG["ACT_DOD_HS_CROUCH_BAZOOKA"] = "e";
luapad._sG["ACT_HL2MP_IDLE_CROUCH_FIST"] = "e";
luapad._sG["ACT_DOD_STAND_IDLE"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_GREASE"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_DEPLOYED_RIFLE"] = "e";
luapad._sG["ACT_DIEFORWARD"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_IDLE_BAZOOKA"] = "e";
luapad._sG["OBS_MODE_IN_EYE"] = "e";
luapad._sG["MAT_METAL"] = "e";
luapad._sG["ACT_MP_SECONDARY_GRENADE1_IDLE"] = "e";
luapad._sG["ACT_VM_UNDEPLOY_8"] = "e";
luapad._sG["COLLISION_GROUP_NONE"] = "e";
luapad._sG["ACT_MP_ATTACK_STAND_GRENADE"] = "e";
luapad._sG["RENDERMODE_TRANSALPHADD"] = "e";
luapad._sG["ACT_MP_JUMP_MELEE"] = "e";
luapad._sG["ACT_MP_JUMP_SECONDARY"] = "e";
luapad._sG["KEY_W"] = "e";
luapad._sG["SCHED_COMBAT_PATROL"] = "e";
luapad._sG["ACT_FLINCH_HEAD"] = "e";
luapad._sG["ACT_DROP_WEAPON"] = "e";
luapad._sG["ACT_SPECIAL_ATTACK1"] = "e";
luapad._sG["ACT_DOD_PRONEWALK_IDLE_BAZOOKA"] = "e";
luapad._sG["ACT_GAUSS_SPINCYCLE"] = "e";
luapad._sG["D_HT"] = "e";
luapad._sG["MASK_OPAQUE"] = "e";
luapad._sG["DMG_NEVERGIB"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW"] = "e";
luapad._sG["ACT_DOD_STAND_ZOOM_BAZOOKA"] = "e";
luapad._sG["ACT_DOD_PRONE_DEPLOY_TOMMY"] = "e";
luapad._sG["ACT_DOD_RUN_AIM_30CAL"] = "e";
luapad._sG["ACT_DOD_PRONEWALK_IDLE_BOLT"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_TOMMY"] = "e";
luapad._sG["MAT_CONCRETE"] = "e";
luapad._sG["ACT_READINESS_PISTOL_STIMULATED_TO_RELAXED"] = "e";
luapad._sG["ACT_HL2MP_IDLE_CROUCH_AR2"] = "e";
luapad._sG["ACT_DOD_CROUCH_IDLE"] = "e";
luapad._sG["ACT_MP_MELEE_GRENADE2_IDLE"] = "e";
luapad._sG["CAP_FRIENDLY_DMG_IMMUNE"] = "e";
luapad._sG["ACT_ITEM_PLACE"] = "e";
luapad._sG["ACT_VM_DEPLOY"] = "e";
luapad._sG["KEY_XSTICK2_RIGHT"] = "e";
luapad._sG["ACT_DOD_RUN_IDLE_MP44"] = "e";
luapad._sG["ACT_BUSY_LEAN_BACK_ENTRY"] = "e";
luapad._sG["ACT_FIRE_START"] = "e";
luapad._sG["SCHED_RUN_FROM_ENEMY"] = "e";
luapad._sG["ACT_DOD_RELOAD_DEPLOYED_30CAL"] = "e";
luapad._sG["ACT_DOD_DEFUSE_TNT"] = "e";
luapad._sG["ACT_STAND"] = "e";
luapad._sG["RENDERGROUP_BOTH"] = "e";
luapad._sG["ACT_DOD_WALK_AIM_PSCHRECK"] = "e";
luapad._sG["SCHED_COMBAT_FACE"] = "e";
luapad._sG["ACT_MP_ATTACK_CROUCH_GRENADE_MELEE"] = "e";
luapad._sG["ACT_VM_IDLE_4"] = "e";
luapad._sG["SF_NPC_FADE_CORPSE"] = "e";
luapad._sG["ACT_DO_NOT_DISTURB"] = "e";
luapad._sG["ACT_RANGE_ATTACK_PISTOL_LOW"] = "e";
luapad._sG["ACT_DOD_HS_IDLE_BAZOOKA"] = "e";
luapad._sG["ACT_DOD_STAND_IDLE_MG"] = "e";
luapad._sG["SCHED_FAIL"] = "e";
luapad._sG["ACT_MP_AIRWALK_PDA"] = "e";
luapad._sG["ACT_IDLE_AIM_RELAXED"] = "e";
luapad._sG["ACT_DOD_WALK_AIM_BAZOOKA"] = "e";
luapad._sG["KEY_SLASH"] = "e";
luapad._sG["ACT_RANGE_ATTACK_SMG2"] = "e";
luapad._sG["ACT_TRANSITION"] = "e";
luapad._sG["ACT_DOD_CROUCH_IDLE_TNT"] = "e";
luapad._sG["FVPHYSICS_WAS_THROWN"] = "e";
luapad._sG["ACT_MP_ATTACK_STAND_PRIMARY"] = "e";
luapad._sG["ACT_MP_MELEE_GRENADE1_DRAW"] = "e";
luapad._sG["SCHED_ALERT_FACE"] = "e";
luapad._sG["ACT_HL2MP_WALK_CROUCH_SLAM"] = "e";
luapad._sG["KEY_XBUTTON_RIGHT"] = "e";
luapad._sG["ACT_WALK_AIM"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_IDLE_C96"] = "e";
luapad._sG["ACT_MP_RELOAD_SWIM_LOOP"] = "e";
luapad._sG["KEY_XBUTTON_X"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_BOLT"] = "e";
luapad._sG["ACT_MP_RELOAD_STAND_SECONDARY_LOOP"] = "e";
luapad._sG["ACT_DOD_IDLE_ZOOMED"] = "e";
luapad._sG["BOX_BACK"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_MG"] = "e";
luapad._sG["ACT_DOD_PRONE_DEPLOYED"] = "e";
luapad._sG["FCVAR_NOTIFY"] = "e";
luapad._sG["KEY_COMMA"] = "e";
luapad._sG["ACT_DOD_WALK_ZOOMED"] = "e";
luapad._sG["ACT_RELOAD_PISTOL"] = "e";
luapad._sG["CLASS_MILITARY"] = "e";
luapad._sG["DMG_PLASMA"] = "e";
luapad._sG["OBS_MODE_DEATHCAM"] = "e";
luapad._sG["KEY_MINUS"] = "e";
luapad._sG["SCHED_BACK_AWAY_FROM_ENEMY"] = "e";
luapad._sG["ACT_MP_JUMP_LAND_SECONDARY"] = "e";
luapad._sG["CONTENTS_WATER"] = "e";
luapad._sG["ACT_OBJ_DISMANTLING"] = "e";
luapad._sG["ACT_WALK_PISTOL"] = "e";
luapad._sG["ACT_WALK"] = "e";
luapad._sG["ACT_DOD_RELOAD_C96"] = "e";
luapad._sG["IN_BULLRUSH"] = "e";
luapad._sG["CONTENTS_CURRENT_270"] = "e";
luapad._sG["CONTENTS_MONSTERCLIP"] = "e";
luapad._sG["ACT_DOD_HS_IDLE_K98"] = "e";
luapad._sG["KEY_PERIOD"] = "e";
luapad._sG["ACT_DOD_SPRINT_IDLE_BAR"] = "e";
luapad._sG["ACT_DOD_CROUCH_AIM_MP44"] = "e";
luapad._sG["ACT_STEP_RIGHT"] = "e";
luapad._sG["ACT_RUNTOIDLE"] = "e";
luapad._sG["SCHED_BACK_AWAY_FROM_SAVE_POSITION"] = "e";
luapad._sG["ACT_VM_MISSLEFT"] = "e";
luapad._sG["ACT_DYINGLOOP"] = "e";
luapad._sG["ACT_DOD_CROUCH_AIM_BAR"] = "e";
luapad._sG["ACT_HL2MP_WALK_SHOTGUN"] = "e";
luapad._sG["ACT_DOD_HS_IDLE_MP44"] = "e";
luapad._sG["ACT_HL2MP_JUMP_AR2"] = "e";
luapad._sG["MAT_SAND"] = "e";
luapad._sG["KEY_PAD_7"] = "e";
luapad._sG["ACT_DOD_CROUCH_IDLE_MP40"] = "e";
luapad._sG["ACT_IDLE_ON_FIRE"] = "e";
luapad._sG["KEY_J"] = "e";
luapad._sG["ACT_DOD_RUN_AIM_RIFLE"] = "e";
luapad._sG["CLASS_PROTOSNIPER"] = "e";
luapad._sG["CAP_USE_SHOT_REGULATOR"] = "e";
luapad._sG["ACT_SLAM_TRIPMINE_TO_STICKWALL_ND"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RELOAD_MELEE"] = "e";
luapad._sG["ACT_PLAYER_WALK_FIRE"] = "e";
luapad._sG["ACT_GESTURE_MELEE_ATTACK1"] = "e";
luapad._sG["SCHED_VICTORY_DANCE"] = "e";
luapad._sG["ACT_MP_SWIM_SECONDARY"] = "e";
luapad._sG["ACT_MP_PRIMARY_GRENADE2_IDLE"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RANGE_ATTACK"] = "e";
luapad._sG["KEY_SEMICOLON"] = "e";
luapad._sG["CAP_SIMPLE_RADIUS_DAMAGE"] = "e";
luapad._sG["ACT_DOD_STAND_IDLE_C96"] = "e";
luapad._sG["ACT_SHIELD_KNOCKBACK"] = "e";
luapad._sG["FVPHYSICS_MULTIOBJECT_ENTITY"] = "e";
luapad._sG["ACT_SIGNAL_GROUP"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM"] = "e";
luapad._sG["ACT_DOD_PRONE_DEPLOY_MG"] = "e";
luapad._sG["ACT_RELOAD_SHOTGUN_LOW"] = "e";
luapad._sG["ACT_IDLE_SHOTGUN_AGITATED"] = "e";
luapad._sG["DMG_RADIATION"] = "e";
luapad._sG["ACT_DOD_RELOAD_GARAND"] = "e";
luapad._sG["ACT_WALK_HURT"] = "e";
luapad._sG["ACT_DI_ALYX_ANTLION"] = "e";
luapad._sG["ACT_MP_MELEE_GRENADE1_IDLE"] = "e";
luapad._sG["SCHED_TAKE_COVER_FROM_ENEMY"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RELOAD_AR2"] = "e";
luapad._sG["ACT_DOD_RUN_AIM_GREN_STICK"] = "e";
luapad._sG["ACT_VM_SPRINT_IDLE"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_AIM_GREN_STICK"] = "e";
luapad._sG["ACT_MP_RELOAD_AIRWALK_SECONDARY_LOOP"] = "e";
luapad._sG["MASK_OPAQUE_AND_NPCS"] = "e";
luapad._sG["ACT_VM_DEPLOY_5"] = "e";
luapad._sG["ACT_MP_RELOAD_SWIM_SECONDARY_LOOP"] = "e";
luapad._sG["ACT_GESTURE_FLINCH_RIGHTARM"] = "e";
luapad._sG["ACT_SCRIPT_CUSTOM_MOVE"] = "e";
luapad._sG["ACT_DOD_PRONE_ZOOM_PSCHRECK"] = "e";
luapad._sG["ACT_VM_PULLPIN"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_K43"] = "e";
luapad._sG["HULL_HUMAN"] = "e";
luapad._sG["ACT_IDLE_ANGRY_SMG1"] = "e";
luapad._sG["CAP_NO_HIT_PLAYER"] = "e";
luapad._sG["ACT_DOD_PRONE_AIM_BAZOOKA"] = "e";
luapad._sG["ACT_GET_DOWN_CROUCH"] = "e";
luapad._sG["ACT_RUN_PISTOL"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_HANDMOUTH_PRIMARY"] = "e";
luapad._sG["_ENT"] = "e";
luapad._sG["ACT_SLAM_THROW_THROW_ND"] = "e";
luapad._sG["ACT_STRAFE_RIGHT"] = "e";
luapad._sG["COLLISION_GROUP_WORLD"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PISTOL"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE"] = "e";
luapad._sG["ACT_DOD_CROUCH_ZOOMED"] = "e";
luapad._sG["DMG_FALL"] = "e";
luapad._sG["OBS_MODE_FREEZECAM"] = "e";
luapad._sG["KEY_RIGHT"] = "e";
luapad._sG["ACT_DOD_SECONDARYATTACK_RIFLE"] = "e";
luapad._sG["CAP_INNATE_MELEE_ATTACK2"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RELOAD_GRENADE"] = "e";
luapad._sG["ACT_MP_JUMP_START_PRIMARY"] = "e";
luapad._sG["ACT_MP_JUMP_FLOAT_PDA"] = "e";
luapad._sG["ACT_IDLE_PISTOL"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PSCHRECK"] = "e";
luapad._sG["MOUSE_LEFT"] = "e";
luapad._sG["SCHED_FAIL_ESTABLISH_LINE_OF_FIRE"] = "e";
luapad._sG["MOUSE_COUNT"] = "e";
luapad._sG["ACT_VM_IDLE_TO_LOWERED"] = "e";
luapad._sG["KEY_B"] = "e";
luapad._sG["MOVETYPE_WALK"] = "e";
luapad._sG["ACT_RIDE_MANNED_GUN"] = "e";
luapad._sG["ACT_MP_JUMP_PRIMARY"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN"] = "e";
luapad._sG["ACT_DOD_STAND_AIM_SPADE"] = "e";
luapad._sG["MASK_SPLITAREAPORTAL"] = "e";
luapad._sG["ACT_CROUCHIDLE_AGITATED"] = "e";
luapad._sG["ACT_SMG2_RELOAD2"] = "e";
luapad._sG["KEY_XBUTTON_LEFT"] = "e";
luapad._sG["ACT_CROUCHING_GRENADEIDLE"] = "e";
luapad._sG["KEY_U"] = "e";
luapad._sG["ACT_HANDGRENADE_THROW2"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_M1CARBINE"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK_DEPLOYED_EMPTY"] = "e";
luapad._sG["KEY_7"] = "e";
luapad._sG["ACT_MP_ATTACK_SWIM_BUILDING"] = "e";
luapad._sG["ACT_DOD_STAND_AIM_30CAL"] = "e";
luapad._sG["KEY_5"] = "e";
luapad._sG["ACT_IDLE_AIM_RIFLE_STIMULATED"] = "e";
luapad._sG["CLIENT"] = "e";
luapad._sG["ACT_DOD_RELOAD_CROUCH_BOLT"] = "e";
luapad._sG["ACT_HL2MP_JUMP_MELEE2"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_FISTPUMP_PDA"] = "e";
luapad._sG["PLAYER_ATTACK1"] = "e";
luapad._sG["ACT_SIGNAL3"] = "e";
luapad._sG["ACT_SHIELD_UP"] = "e";
luapad._sG["ACT_GESTURE_RANGE_ATTACK_AR2_GRENADE"] = "e";
luapad._sG["ACT_DOD_STAND_IDLE_GREASE"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE"] = "e";
luapad._sG["ACT_DOD_CROUCH_IDLE_MP44"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE"] = "e";
luapad._sG["ACT_SHIELD_UP_IDLE"] = "e";
luapad._sG["ACT_MP_ATTACK_CROUCH_PRIMARY_DEPLOYED"] = "e";
luapad._sG["KEY_I"] = "e";
luapad._sG["ACT_HL2MP_SIT_RPG"] = "e";
luapad._sG["ACT_DOD_RELOAD_TOMMY"] = "e";
luapad._sG["KEY_N"] = "e";
luapad._sG["ACT_SLAM_THROW_ND_DRAW"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_FINGERPOINT_MELEE"] = "e";
luapad._sG["ACT_SHIELD_DOWN"] = "e";
luapad._sG["JOYSTICK_LAST_POV_BUTTON"] = "e";
luapad._sG["ACT_DOD_RUN_AIM_MP44"] = "e";
luapad._sG["SURF_NOLIGHT"] = "e";
luapad._sG["ACT_VM_SPRINT_LEAVE"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_BAR"] = "e";
luapad._sG["SCHED_DISARM_WEAPON"] = "e";
luapad._sG["KEY_XBUTTON_STICK2"] = "e";
luapad._sG["ACT_DOD_PRONE_AIM_GREN_STICK"] = "e";
luapad._sG["ACT_VM_RELEASE"] = "e";
luapad._sG["ACT_HL2MP_WALK_SLAM"] = "e";
luapad._sG["ACT_VM_IDLE_3"] = "e";
luapad._sG["ACT_MP_RELOAD_CROUCH"] = "e";
luapad._sG["ACT_DOD_RUN_IDLE_MG"] = "e";
luapad._sG["KEY_V"] = "e";
luapad._sG["ACT_DOD_SPRINT_IDLE_TNT"] = "e";
luapad._sG["MAT_WOOD"] = "e";
luapad._sG["ACT_VM_LOWERED_TO_IDLE"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_THUMBSUP_PDA"] = "e";
luapad._sG["KEY_TAB"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_FISTPUMP_PRIMARY"] = "e";
luapad._sG["ACT_SMALL_FLINCH"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_GREN_STICK"] = "e";
luapad._sG["ACT_ROLL_RIGHT"] = "e";
luapad._sG["ACT_PHYSCANNON_UPGRADE"] = "e";
luapad._sG["ACT_MP_MELEE_GRENADE1_ATTACK"] = "e";
luapad._sG["ACT_DI_ALYX_ZOMBIE_MELEE"] = "e";
luapad._sG["ACT_MP_GRENADE2_IDLE"] = "e";
luapad._sG["ACT_SHOTGUN_PUMP"] = "e";
luapad._sG["ACT_VM_IDLE_DEPLOYED_5"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_IDLE_TOMMY"] = "e";
luapad._sG["ACT_DIE_GUTSHOT"] = "e";
luapad._sG["ACT_RPG_HOLSTER_UNLOADED"] = "e";
luapad._sG["ACT_RUN_AIM_SHOTGUN"] = "e";
luapad._sG["ACT_DOD_RUN_IDLE"] = "e";
luapad._sG["ACT_DOD_STAND_AIM"] = "e";
luapad._sG["MOUSE_WHEEL_UP"] = "e";
luapad._sG["ACT_READINESS_AGITATED_TO_STIMULATED"] = "e";
luapad._sG["ACT_READINESS_STIMULATED_TO_RELAXED"] = "e";
luapad._sG["ACT_DOD_HS_CROUCH"] = "e";
luapad._sG["ACT_GESTURE_TURN_LEFT90"] = "e";
luapad._sG["CONTENTS_MOVEABLE"] = "e";
luapad._sG["ACT_VM_UNDEPLOY_5"] = "e";
luapad._sG["ACT_MP_RELOAD_STAND_PRIMARY"] = "e";
luapad._sG["KEY_PAD_3"] = "e";
luapad._sG["ACT_DOD_WALK_IDLE_TOMMY"] = "e";
luapad._sG["COLLISION_GROUP_NPC"] = "e";
luapad._sG["ACT_RELOAD_LOW"] = "e";
luapad._sG["KEY_PAD_DECIMAL"] = "e";
luapad._sG["ACT_DOD_RELOAD_CROUCH_BAZOOKA"] = "e";
luapad._sG["ACT_RPG_FIDGET_UNLOADED"] = "e";
luapad._sG["ACT_BARNACLE_HIT"] = "e";
luapad._sG["ACT_DOD_RUN_AIM_MP40"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE"] = "e";
luapad._sG["ACT_MP_ATTACK_STAND_PRIMARY_DEPLOYED"] = "e";
luapad._sG["ACT_VM_IDLE_DEPLOYED_2"] = "e";
luapad._sG["ACT_DOD_CROUCH_AIM_MP40"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RANGE_ATTACK_PHYSGUN"] = "e";
luapad._sG["ACT_HL2MP_IDLE_CROUCH_SMG1"] = "e";
luapad._sG["ACT_RUN"] = "e";
luapad._sG["ACT_VM_PULLBACK"] = "e";
luapad._sG["FCVAR_PRINTABLEONLY"] = "e";
luapad._sG["ACT_SIGNAL1"] = "e";
luapad._sG["KEY_DELETE"] = "e";
luapad._sG["ACT_SWIM"] = "e";
luapad._sG["ACT_DOD_RELOAD_PISTOL"] = "e";
luapad._sG["COLLISION_GROUP_DOOR_BLOCKER"] = "e";
luapad._sG["SCHED_PATROL_RUN"] = "e";
luapad._sG["ACT_MP_ATTACK_STAND_SECONDARY"] = "e";
luapad._sG["ACT_VM_UNDEPLOY_6"] = "e";
luapad._sG["ACT_VM_UNDEPLOY_3"] = "e";
luapad._sG["CONTENTS_PLAYERCLIP"] = "e";
luapad._sG["ACT_GESTURE_RANGE_ATTACK_TRIPWIRE"] = "e";
luapad._sG["ACT_HL2MP_IDLE_CROSSBOW"] = "e";
luapad._sG["ACT_DOD_PRONE_DEPLOY_30CAL"] = "e";
luapad._sG["ACT_DOD_PRONEWALK_IDLE_PISTOL"] = "e";
luapad._sG["ACT_OVERLAY_SHIELD_KNOCKBACK"] = "e";
luapad._sG["ACT_DOD_CROUCH_IDLE_BAR"] = "e";
luapad._sG["ACT_PHYSCANNON_ANIMATE_PRE"] = "e";
luapad._sG["ACT_COVER_LOW"] = "e";
luapad._sG["BOX_RIGHT"] = "e";
luapad._sG["ACT_MP_ATTACK_SWIM_GRENADE_PRIMARY"] = "e";
luapad._sG["ACT_MP_RELOAD_CROUCH_PRIMARY_END"] = "e";
luapad._sG["ACT_OBJ_STARTUP"] = "e";
luapad._sG["FVPHYSICS_HEAVY_OBJECT"] = "e";
luapad._sG["ACT_IDLE_AGITATED"] = "e";
luapad._sG["TEXT_ALIGN_RIGHT"] = "e";
luapad._sG["ACT_MP_GRENADE1_IDLE"] = "e";
luapad._sG["OBS_MODE_CHASE"] = "e";
luapad._sG["CLASS_VORTIGAUNT"] = "e";
luapad._sG["ACT_VM_RECOIL3"] = "e";
luapad._sG["KEY_H"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_30CAL"] = "e";
luapad._sG["ACT_DOD_SPRINT_IDLE_MP44"] = "e";
luapad._sG["ACT_RANGE_ATTACK_TRIPWIRE"] = "e";
luapad._sG["ACT_VM_MISSCENTER"] = "e";
luapad._sG["ACT_MP_DOUBLEJUMP"] = "e";
luapad._sG["ACT_RUN_RIFLE_RELAXED"] = "e";
luapad._sG["ACT_RANGE_ATTACK_RPG"] = "e";
luapad._sG["ACT_VM_DEPLOY_3"] = "e";
luapad._sG["ACT_MP_JUMP_START_SECONDARY"] = "e";
luapad._sG["ACT_GESTURE_RELOAD"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_NODNO_PDA"] = "e";
luapad._sG["MOVECOLLIDE_FLY_CUSTOM"] = "e";
luapad._sG["ACT_HL2MP_IDLE_AR2"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_HANDMOUTH"] = "e";
luapad._sG["ACT_MP_JUMP_LAND"] = "e";
luapad._sG["ACT_MELEE_ATTACK2"] = "e";
luapad._sG["ACT_VM_DRYFIRE_LEFT"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_ZOOMED"] = "e";
luapad._sG["ACT_VM_IDLE_7"] = "e";
luapad._sG["CONTENTS_DETAIL"] = "e";
luapad._sG["SCHED_COMBAT_STAND"] = "e";
luapad._sG["ACT_HL2MP_WALK_MELEE"] = "e";
luapad._sG["KEY_PAGEUP"] = "e";
luapad._sG["MAT_TILE"] = "e";
luapad._sG["ACT_STEP_FORE"] = "e";
luapad._sG["JOYSTICK_LAST_BUTTON"] = "e";
luapad._sG["ACT_OBJ_RUNNING"] = "e";
luapad._sG["ACT_GET_UP_STAND"] = "e";
luapad._sG["ACT_SIGNAL_RIGHT"] = "e";
luapad._sG["ACT_DOD_RELOAD_CROUCH_C96"] = "e";
luapad._sG["ACT_DOD_RELOAD_BAZOOKA"] = "e";
luapad._sG["ACT_VM_UNDEPLOY_4"] = "e";
luapad._sG["ACT_RUN_CROUCH"] = "e";
luapad._sG["KEY_PAD_DIVIDE"] = "e";
luapad._sG["USE_ON"] = "e";
luapad._sG["ACT_MP_PRIMARY_GRENADE1_DRAW"] = "e";
luapad._sG["ACT_VM_IDLE_SILENCED"] = "e";
luapad._sG["ACT_RPG_DRAW_UNLOADED"] = "e";
luapad._sG["ACT_VM_DEPLOY_2"] = "e";
luapad._sG["ACT_CLIMB_DOWN"] = "e";
luapad._sG["IN_WALK"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_AIM_GREN_FRAG"] = "e";
luapad._sG["ACT_BUSY_SIT_GROUND"] = "e";
luapad._sG["ACT_GESTURE_FLINCH_STOMACH"] = "e";
luapad._sG["ACT_CROUCHIDLE_AIM_STIMULATED"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_PSCHRECK"] = "e";
luapad._sG["CLASS_HEADCRAB"] = "e";
luapad._sG["DMG_VEHICLE"] = "e";
luapad._sG["ACT_DOD_STAND_AIM_GREN_FRAG"] = "e";
luapad._sG["ACT_DOD_PRONE_ZOOM_FORWARD_PSCHRECK"] = "e";
luapad._sG["KEY_F9"] = "e";
luapad._sG["ACT_MP_ATTACK_SWIM_GRENADE_BUILDING"] = "e";
luapad._sG["SCHED_AMBUSH"] = "e";
luapad._sG["ACT_DIE_HEADSHOT"] = "e";
luapad._sG["ACT_SLAM_DETONATOR_THROW_DRAW"] = "e";
luapad._sG["ACT_RANGE_ATTACK_SHOTGUN"] = "e";
luapad._sG["ACT_SLAM_DETONATOR_DRAW"] = "e";
luapad._sG["ACT_MP_ATTACK_SWIM_GRENADE_SECONDARY"] = "e";
luapad._sG["ACT_READINESS_RELAXED_TO_STIMULATED_WALK"] = "e";
luapad._sG["ACT_HL2MP_WALK_CROUCH_RPG"] = "e";
luapad._sG["COLLISION_GROUP_DEBRIS_TRIGGER"] = "e";
luapad._sG["ACT_HL2MP_WALK_GRENADE"] = "e";
luapad._sG["ACT_MP_RELOAD_STAND_SECONDARY"] = "e";
luapad._sG["ACT_IDLETORUN"] = "e";
luapad._sG["IN_ATTACK"] = "e";
luapad._sG["ACT_OVERLAY_GRENADEIDLE"] = "e";
luapad._sG["IN_USE"] = "e";
luapad._sG["ACT_DOD_RELOAD_BAR"] = "e";
luapad._sG["ACT_HL2MP_IDLE_CROUCH_MELEE2"] = "e";
luapad._sG["ACT_MP_ATTACK_CROUCH_MELEE"] = "e";
luapad._sG["ACT_DOD_PRONEWALK_IDLE_30CAL"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_AIM_PISTOL"] = "e";
luapad._sG["TEXT_ALIGN_TOP"] = "e";
luapad._sG["ACT_GESTURE_RELOAD_PISTOL"] = "e";
luapad._sG["SCHED_RUN_FROM_ENEMY_MOB"] = "e";
luapad._sG["ACT_90_LEFT"] = "e";
luapad._sG["KEY_XSTICK1_LEFT"] = "e";
luapad._sG["IN_DUCK"] = "e";
luapad._sG["ACT_MP_RELOAD_CROUCH_SECONDARY_LOOP"] = "e";
luapad._sG["FCVAR_NONE"] = "e";
luapad._sG["HULL_TINY"] = "e";
luapad._sG["ACT_SLAM_TRIPMINE_ATTACH"] = "e";
luapad._sG["ACT_DOD_CROUCH_AIM_TOMMY"] = "e";
luapad._sG["ACT_PHYSCANNON_DETACH"] = "e";
luapad._sG["PLAYER_SUPERJUMP"] = "e";
luapad._sG["ACT_DOD_STAND_AIM_BAR"] = "e";
luapad._sG["ACT_MP_ATTACK_STAND_STARTFIRE"] = "e";
luapad._sG["ACT_MP_SWIM"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_FINGERPOINT_PDA"] = "e";
luapad._sG["ACT_GESTURE_RANGE_ATTACK_HMG1"] = "e";
luapad._sG["ACT_ARM"] = "e";
luapad._sG["ACT_DOD_SPRINT_IDLE_C96"] = "e";
luapad._sG["ACT_MP_SPRINT"] = "e";
luapad._sG["ACT_RELOAD_FINISH"] = "e";
luapad._sG["ACT_DOD_RUN_IDLE_TNT"] = "e";
luapad._sG["ACT_VM_RECOIL2"] = "e";
luapad._sG["ACT_CROSSBOW_DRAW_UNLOADED"] = "e";
luapad._sG["ACT_VM_UNDEPLOY_2"] = "e";
luapad._sG["ACT_MP_CROUCHWALK"] = "e";
luapad._sG["ACT_LOOKBACK_RIGHT"] = "e";
luapad._sG["CAP_INNATE_MELEE_ATTACK1"] = "e";
luapad._sG["KEY_F"] = "e";
luapad._sG["KEY_F4"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_NODYES_PDA"] = "e";
luapad._sG["ACT_SLAM_DETONATOR_DETONATE"] = "e";
luapad._sG["ACT_HL2MP_RUN_PISTOL"] = "e";
luapad._sG["MOVETYPE_OBSERVER"] = "e";
luapad._sG["ACT_WALK_AIM_RIFLE"] = "e";
luapad._sG["ACT_DOD_SECONDARYATTACK_PRONE_RIFLE"] = "e";
luapad._sG["ACT_MP_ATTACK_SWIM_PRIMARY"] = "e";
luapad._sG["ACT_DOD_STAND_IDLE_PSCHRECK"] = "e";
luapad._sG["RENDERMODE_GLOW"] = "e";
luapad._sG["ACT_MP_RELOAD_SWIM_PRIMARY_LOOP"] = "e";
luapad._sG["CLASS_PLAYER_ALLY"] = "e";
luapad._sG["ACT_VM_IDLE_EMPTY_LEFT"] = "e";
luapad._sG["ACT_DOD_CROUCH_AIM_BAZOOKA"] = "e";
luapad._sG["CONTENTS_TRANSLUCENT"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_IDLE_BOLT"] = "e";
luapad._sG["KEY_XSTICK2_DOWN"] = "e";
luapad._sG["ACT_GESTURE_RANGE_ATTACK1"] = "e";
luapad._sG["ACT_IDLE_CARRY"] = "e";
luapad._sG["MAT_GRATE"] = "e";
luapad._sG["ACT_MP_WALK_PRIMARY"] = "e";
luapad._sG["ACT_MP_JUMP_BUILDING"] = "e";
luapad._sG["PLAYER_DIE"] = "e";
luapad._sG["ACT_GESTURE_RELOAD_SHOTGUN"] = "e";
luapad._sG["ACT_DIERAGDOLL"] = "e";
luapad._sG["ACT_SHOTGUN_RELOAD_START"] = "e";
luapad._sG["ACT_GESTURE_TURN_RIGHT"] = "e";
luapad._sG["ACT_MP_JUMP_LAND_PDA"] = "e";
luapad._sG["ACT_DOD_SPRINT_IDLE_BAZOOKA"] = "e";
luapad._sG["ACT_DOD_PRONEWALK_IDLE_RIFLE"] = "e";
luapad._sG["ACT_VM_UNDEPLOY_7"] = "e";
luapad._sG["PLAYER_JUMP"] = "e";
luapad._sG["ACT_BUSY_QUEUE"] = "e";
luapad._sG["ACT_FLY"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK_DEPLOYED_7"] = "e";
luapad._sG["IN_RUN"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RELOAD_KNIFE"] = "e";
luapad._sG["ACT_MP_JUMP_START_PDA"] = "e";
luapad._sG["ACT_MP_STAND_SECONDARY"] = "e";
luapad._sG["COLLISION_GROUP_PLAYER_MOVEMENT"] = "e";
luapad._sG["ACT_MP_SWIM_MELEE"] = "e";
luapad._sG["ACT_DOD_ZOOMLOAD_PSCHRECK"] = "e";
luapad._sG["SCHED_RANGE_ATTACK2"] = "e";
luapad._sG["ACT_MP_ATTACK_AIRWALK_GRENADE_SECONDARY"] = "e";
luapad._sG["KEY_D"] = "e";
luapad._sG["ACT_OBJ_IDLE"] = "e";
luapad._sG["ACT_HL2MP_IDLE_KNIFE"] = "e";
luapad._sG["CLASS_BULLSEYE"] = "e";
luapad._sG["ACT_MP_RELOAD_CROUCH_SECONDARY"] = "e";
luapad._sG["ACT_MP_PRIMARY_GRENADE2_DRAW"] = "e";
luapad._sG["ACT_BUSY_SIT_CHAIR_EXIT"] = "e";
luapad._sG["KEY_RBRACKET"] = "e";
luapad._sG["MASK_BLOCKLOS_AND_NPCS"] = "e";
luapad._sG["ACT_DOD_RUN_IDLE_BAR"] = "e";
luapad._sG["ACT_DOD_PRONE_AIM_BOLT"] = "e";
luapad._sG["FCVAR_USERINFO"] = "e";
luapad._sG["ACT_MP_RELOAD_AIRWALK_END"] = "e";
luapad._sG["CONTENTS_AREAPORTAL"] = "e";
luapad._sG["ACT_DOD_HS_CROUCH_K98"] = "e";
luapad._sG["CONTENTS_BLOCKLOS"] = "e";
luapad._sG["ACT_DOD_WALK_AIM_TOMMY"] = "e";
luapad._sG["ACT_SHOTGUN_RELOAD_FINISH"] = "e";
luapad._sG["ACT_MP_ATTACK_STAND_PRIMARYFIRE_DEPLOYED"] = "e";
luapad._sG["ACT_SHIPLADDER_DOWN"] = "e";
luapad._sG["ACT_DOD_CROUCH_AIM_GREASE"] = "e";
luapad._sG["CONTENTS_TEAM2"] = "e";
luapad._sG["ACT_VM_IDLE_DEPLOYED_7"] = "e";
luapad._sG["ACT_DOD_SPRINT_AIM_GREN_FRAG"] = "e";
luapad._sG["ACT_DOD_HS_IDLE_TOMMY"] = "e";
luapad._sG["ACT_GESTURE_RANGE_ATTACK_PISTOL"] = "e";
luapad._sG["CAP_INNATE_RANGE_ATTACK2"] = "e";
luapad._sG["ACT_HL2MP_WALK_PHYSGUN"] = "e";
luapad._sG["ACT_HL2MP_WALK_CROUCH_PHYSGUN"] = "e";
luapad._sG["ACT_DOD_STAND_ZOOM_BOLT"] = "e";
luapad._sG["SCHED_DROPSHIP_DUSTOFF"] = "e";
luapad._sG["ACT_DOD_SECONDARYATTACK_CROUCH_MP40"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL"] = "e";
luapad._sG["KEY_XBUTTON_LEFT_SHOULDER"] = "e";
luapad._sG["SCHED_INTERACTION_MOVE_TO_PARTNER"] = "e";
luapad._sG["ACT_GESTURE_FLINCH_BLAST_DAMAGED_SHOTGUN"] = "e";
luapad._sG["SOLID_NONE"] = "e";
luapad._sG["BLOOD_COLOR_ZOMBIE"] = "e";
luapad._sG["PLAYER_IN_VEHICLE"] = "e";
luapad._sG["MOUSE_MIDDLE"] = "e";
luapad._sG["ACT_DOD_PRONE_AIM_PSCHRECK"] = "e";
luapad._sG["DMG_PARALYZE"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_NODNO_PRIMARY"] = "e";
luapad._sG["KEY_SPACE"] = "e";
luapad._sG["KEY_PAGEDOWN"] = "e";
luapad._sG["ACT_IDLE_RPG"] = "e";
luapad._sG["MAT_ANTLION"] = "e";
luapad._sG["ACT_VM_IDLE_2"] = "e";
luapad._sG["ACT_VM_THROW"] = "e";
luapad._sG["ACT_DOD_SPRINT_IDLE_PISTOL"] = "e";
luapad._sG["ACT_SHIPLADDER_UP"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_BAZOOKA"] = "e";
luapad._sG["ACT_MP_GRENADE2_ATTACK"] = "e";
luapad._sG["KEY_LCONTROL"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_CROUCH_KNIFE"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_RIFLE"] = "e";
luapad._sG["SURF_NODECALS"] = "e";
luapad._sG["ACT_DOD_RELOAD_MP40"] = "e";
luapad._sG["ACT_VM_UNUSABLE"] = "e";
luapad._sG["FCVAR_SERVER_CANNOT_QUERY"] = "e";
luapad._sG["ACT_GESTURE_TURN_LEFT45"] = "e";
luapad._sG["ACT_SMG2_IDLE2"] = "e";
luapad._sG["ACT_DEPLOY"] = "e";
luapad._sG["ACT_OBJ_DETERIORATING"] = "e";
luapad._sG["IN_WEAPON1"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_AIM_BAZOOKA"] = "e";
luapad._sG["ACT_SMG2_DRAW2"] = "e";
luapad._sG["KEY_T"] = "e";
luapad._sG["ACT_MP_RELOAD_STAND"] = "e";
luapad._sG["CONTENTS_GRATE"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_AIM_PSCHRECK"] = "e";
luapad._sG["ACT_SLAM_STICKWALL_TO_THROW_ND"] = "e";
luapad._sG["ACT_MP_JUMP_FLOAT_PRIMARY"] = "e";
luapad._sG["ACT_DOD_CROUCH_AIM_C96"] = "e";
luapad._sG["ACT_GESTURE_RANGE_ATTACK_PISTOL_LOW"] = "e";
luapad._sG["KEY_CAPSLOCKTOGGLE"] = "e";
luapad._sG["ACT_DOD_SECONDARYATTACK_TOMMY"] = "e";
luapad._sG["ACT_GESTURE_FLINCH_LEFTLEG"] = "e";
luapad._sG["SF_PHYSPROP_MOTIONDISABLED"] = "e";
luapad._sG["ACT_SLAM_DETONATOR_HOLSTER"] = "e";
luapad._sG["ACT_DOD_RELOAD_RIFLE"] = "e";
luapad._sG["FVPHYSICS_CONSTRAINT_STATIC"] = "e";
luapad._sG["ACT_MP_ATTACK_CROUCH_MELEE_SECONDARY"] = "e";
luapad._sG["ACT_RUN_RIFLE"] = "e";
luapad._sG["IN_RIGHT"] = "e";
luapad._sG["ACT_MP_ATTACK_CROUCH_SECONDARY"] = "e";
luapad._sG["ACT_SLAM_THROW_TO_STICKWALL"] = "e";
luapad._sG["HUD_PRINTCENTER"] = "e";
luapad._sG["ACT_MP_STAND_PDA"] = "e";
luapad._sG["ACT_DOD_RELOAD_DEPLOYED_FG42"] = "e";
luapad._sG["ACT_HL2MP_IDLE_SHOTGUN"] = "e";
luapad._sG["SF_CITIZEN_RANDOM_HEAD_FEMALE"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_THUMBSUP_BUILDING"] = "e";
luapad._sG["ACT_VM_UNDEPLOY_1"] = "e";
luapad._sG["ACT_DOD_PRONE_ZOOM_FORWARD_BOLT"] = "e";
luapad._sG["ACT_RANGE_ATTACK1"] = "e";
luapad._sG["ACT_VM_UNUSABLE_TO_USABLE"] = "e";
luapad._sG["NPC_STATE_SCRIPT"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_AIM_C96"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK_7"] = "e";
luapad._sG["PLAYER_RELOAD"] = "e";
luapad._sG["CLASS_MISSILE"] = "e";
luapad._sG["CT_DEFAULT"] = "e";
luapad._sG["ACT_RANGE_AIM_AR2_LOW"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK_DEPLOYED_4"] = "e";
luapad._sG["ACT_HL2MP_IDLE_CROUCH_PASSIVE"] = "e";
luapad._sG["SCHED_NEW_WEAPON_CHEAT"] = "e";
luapad._sG["KEY_UP"] = "e";
luapad._sG["ACT_HL2MP_IDLE_MELEE2"] = "e";
luapad._sG["ACT_DOD_SPRINT_AIM_SPADE"] = "e";
luapad._sG["ACT_DOD_CROUCH_ZOOM_BAZOOKA"] = "e";
luapad._sG["KEY_BACKQUOTE"] = "e";
luapad._sG["ACT_WALK_SCARED"] = "e";
luapad._sG["ACT_MELEE_ATTACK1"] = "e";
luapad._sG["KEY_L"] = "e";
luapad._sG["ACT_DOD_RELOAD_CROUCH_RIFLE"] = "e";
luapad._sG["ACT_IDLE_HURT"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RELOAD_SMG1"] = "e";
luapad._sG["ACT_DOD_CROUCH_IDLE_TOMMY"] = "e";
luapad._sG["ACT_MP_ATTACK_STAND_MELEE"] = "e";
luapad._sG["TRANSMIT_ALWAYS"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_GREN_FRAG"] = "e";
luapad._sG["IN_WEAPON2"] = "e";
luapad._sG["ACT_GESTURE_FLINCH_CHEST"] = "e";
luapad._sG["ACT_HL2MP_WALK_CROUCH_SMG1"] = "e";
luapad._sG["ACT_DOD_CROUCH_AIM_PISTOL"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_IDLE_BAR"] = "e";
luapad._sG["ACT_BIG_FLINCH"] = "e";
luapad._sG["ACT_RANGE_AIM_LOW"] = "e";
luapad._sG["ACT_HL2MP_RUN_PHYSGUN"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_BAR"] = "e";
luapad._sG["ACT_MP_DEPLOYED_PRIMARY"] = "e";
luapad._sG["COMP_TEXT_AND_CHARS_AND_NUMBERS"] = "e";
luapad._sG["ACT_MP_CROUCHWALK_PDA"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_AIM_GREASE"] = "e";
luapad._sG["ACT_VM_SECONDARYATTACK"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_CROUCH_GREN_FRAG"] = "e";
luapad._sG["ACT_HL2MP_RUN_CROSSBOW"] = "e";
luapad._sG["ACT_IDLE_ANGRY_RPG"] = "e";
luapad._sG["ACT_HL2MP_WALK_KNIFE"] = "e";
luapad._sG["ACT_RANGE_ATTACK_AR2_GRENADE"] = "e";
luapad._sG["ACT_DROP_WEAPON_SHOTGUN"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_MG"] = "e";
luapad._sG["GAMEMODE"] = "e";
luapad._sG["ACT_DOD_WALK_IDLE_MP44"] = "e";
luapad._sG["MOUSE_FIRST"] = "e";
luapad._sG["KEY_XSTICK1_UP"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK_2"] = "e";
luapad._sG["KEY_BACKSPACE"] = "e";
luapad._sG["KEY_PAD_ENTER"] = "e";
luapad._sG["ACT_TRIPMINE_WORLD"] = "e";
luapad._sG["KEY_CAPSLOCK"] = "e";
luapad._sG["ACT_HL2MP_WALK_RPG"] = "e";
luapad._sG["ACT_IDLE_ANGRY_SHOTGUN"] = "e";
luapad._sG["DMG_BLAST_SURFACE"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG"] = "e";
luapad._sG["ACT_DYINGTODEAD"] = "e";
luapad._sG["ACT_HL2MP_WALK_CROUCH_PISTOL"] = "e";
luapad._sG["ACT_MP_CROUCH_BUILDING"] = "e";
luapad._sG["ACT_DOD_PRONEWALK_AIM_KNIFE"] = "e";
luapad._sG["ACT_DOD_STAND_IDLE_MP40"] = "e";
luapad._sG["ACT_COVER_LOW_RPG"] = "e";
luapad._sG["FCVAR_PROTECTED"] = "e";
luapad._sG["IN_ATTACK2"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_BOLT"] = "e";
luapad._sG["ACT_MP_WALK"] = "e";
luapad._sG["NPC_STATE_DEAD"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_DEPLOYED_30CAL"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_CROUCH"] = "e";
luapad._sG["ACT_BARNACLE_CHEW"] = "e";
luapad._sG["TRANSMIT_PVS"] = "e";
luapad._sG["KEY_PAD_9"] = "e";
luapad._sG["ACT_SLAM_STICKWALL_ND_ATTACH2"] = "e";
luapad._sG["SCHED_NONE"] = "e";
luapad._sG["PLAYER_IDLE"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_AIM_MG"] = "e";
luapad._sG["ACT_HL2MP_IDLE_CROUCH_KNIFE"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RELOAD_CROSSBOW"] = "e";
luapad._sG["ACT_SLAM_TRIPMINE_ATTACH2"] = "e";
luapad._sG["ACT_DOD_CROUCH_AIM_PSCHRECK"] = "e";
luapad._sG["ACT_MP_GESTURE_FLINCH_STOMACH"] = "e";
luapad._sG["ACT_GESTURE_RANGE_ATTACK_SHOTGUN"] = "e";
luapad._sG["ACT_DOD_CROUCH_IDLE_BAZOOKA"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_HANDMOUTH_BUILDING"] = "e";
luapad._sG["MASK_VISIBLE"] = "e";
luapad._sG["ACT_DOD_RELOAD_M1CARBINE"] = "e";
luapad._sG["ACT_DOD_RUN_AIM_BAR"] = "e";
luapad._sG["COLLISION_GROUP_IN_VEHICLE"] = "e";
luapad._sG["ACT_DI_ALYX_ZOMBIE_SHOTGUN64"] = "e";
luapad._sG["ACT_GRENADE_TOSS"] = "e";
luapad._sG["ACT_VM_IDLE_DEPLOYED"] = "e";
luapad._sG["ACT_SHOTGUN_IDLE4"] = "e";
luapad._sG["ACT_DOD_STAND_IDLE_30CAL"] = "e";
luapad._sG["IN_ALT1"] = "e";
luapad._sG["SCHED_RELOAD"] = "e";
luapad._sG["ACT_DI_ALYX_ZOMBIE_TORSO_MELEE"] = "e";
luapad._sG["ACT_HL2MP_SIT_SMG1"] = "e";
luapad._sG["HULL_SMALL_CENTERED"] = "e";
luapad._sG["ACT_DOD_DEPLOY_TOMMY"] = "e";
luapad._sG["SURF_NOCHOP"] = "e";
luapad._sG["SCHED_INTERACTION_WAIT_FOR_PARTNER"] = "e";
luapad._sG["ACT_VM_HAULBACK"] = "e";
luapad._sG["ACT_MP_WALK_SECONDARY"] = "e";
luapad._sG["FCVAR_SERVER_CAN_EXECUTE"] = "e";
luapad._sG["BOX_FRONT"] = "e";
luapad._sG["ACT_MP_ATTACK_SWIM_SECONDARYFIRE"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_NODNO_BUILDING"] = "e";
luapad._sG["ACT_COVER"] = "e";
luapad._sG["SCHED_PATROL_WALK"] = "e";
luapad._sG["KEY_NUMLOCK"] = "e";
luapad._sG["ACT_DOD_CROUCH_AIM_RIFLE"] = "e";
luapad._sG["ACT_DOD_WALK_AIM_MP40"] = "e";
luapad._sG["ACT_HL2MP_IDLE_SMG1"] = "e";
luapad._sG["ACT_IDLE_SUITCASE"] = "e";
luapad._sG["ACT_HL2MP_RUN_SLAM"] = "e";
luapad._sG["ACT_DOD_PRONE_FORWARD_ZOOMED"] = "e";
luapad._sG["ACT_DOD_DEPLOYED"] = "e";
luapad._sG["ACT_HL2MP_IDLE_CROUCH_RPG"] = "e";
luapad._sG["SF_NPC_WAIT_TILL_SEEN"] = "e";
luapad._sG["SCHED_COMBAT_SWEEP"] = "e";
luapad._sG["ACT_LAND"] = "e";
luapad._sG["MASK_NPCSOLID"] = "e";
luapad._sG["ACT_COMBAT_IDLE"] = "e";
luapad._sG["DMG_BULLET"] = "e";
luapad._sG["ACT_HL2MP_SIT_AR2"] = "e";
luapad._sG["ACT_MP_GESTURE_FLINCH_SECONDARY"] = "e";
luapad._sG["KEY_P"] = "e";
luapad._sG["ACT_VM_DRAW_SILENCED"] = "e";
luapad._sG["SURF_SKY"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK_DEPLOYED_2"] = "e";
luapad._sG["ACT_MP_ATTACK_SWIM_MELEE"] = "e";
luapad._sG["ACT_GESTURE_FLINCH_HEAD"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_IDLE_TNT"] = "e";
luapad._sG["ACT_DOD_SPRINT_IDLE_MG"] = "e";
luapad._sG["ACT_MP_ATTACK_CROUCH_SECONDARYFIRE"] = "e";
luapad._sG["ACT_DOD_RUN_AIM_BAZOOKA"] = "e";
luapad._sG["ACT_WALK_RELAXED"] = "e";
luapad._sG["ACT_DOD_RELOAD_FG42"] = "e";
luapad._sG["ACT_RUN_ON_FIRE"] = "e";
luapad._sG["ACT_SMG2_TOAUTO"] = "e";
luapad._sG["ACT_MP_RUN_PRIMARY"] = "e";
luapad._sG["ACT_DOD_SPRINT_IDLE_PSCHRECK"] = "e";
luapad._sG["ACT_WALK_CROUCH_RPG"] = "e";
luapad._sG["IN_SCORE"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_SPADE"] = "e";
luapad._sG["ACT_TURNRIGHT45"] = "e";
luapad._sG["SURF_TRANS"] = "e";
luapad._sG["ACT_DOD_ZOOMLOAD_PRONE_PSCHRECK"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_NODYES_MELEE"] = "e";
luapad._sG["ACT_OBJ_ASSEMBLING"] = "e";
luapad._sG["ACT_IDLE_SMG1_STIMULATED"] = "e";
luapad._sG["ACT_VM_UNDEPLOY"] = "e";
luapad._sG["ACT_MP_JUMP_START_BUILDING"] = "e";
luapad._sG["FORCE_NUMBER"] = "e";
luapad._sG["ACT_MP_RELOAD_SWIM_PRIMARY"] = "e";
luapad._sG["ACT_DOD_RELOAD_GREASEGUN"] = "e";
luapad._sG["ACT_VM_HITLEFT2"] = "e";
luapad._sG["ACT_HL2MP_IDLE_CROUCH"] = "e";
luapad._sG["ACT_FLINCH_PHYSICS"] = "e";
luapad._sG["SF_NPC_NO_PLAYER_PUSHAWAY"] = "e";
luapad._sG["ACT_RANGE_ATTACK_HMG1"] = "e";
luapad._sG["IN_SPEED"] = "e";
luapad._sG["PLAYER_LEAVE_AIMING"] = "e";
luapad._sG["KEY_Z"] = "e";
luapad._sG["SCHED_PRE_FAIL_ESTABLISH_LINE_OF_FIRE"] = "e";
luapad._sG["ACT_HL2MP_RUN_PASSIVE"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_AIM_SPADE"] = "e";
luapad._sG["ACT_HL2MP_WALK_CROSSBOW"] = "e";
luapad._sG["MOUSE_RIGHT"] = "e";
luapad._sG["ACT_MP_STAND_BUILDING"] = "e";
luapad._sG["SURF_BUMPLIGHT"] = "e";
luapad._sG["RD"] = "e";
luapad._sG["ACT_BUSY_LEAN_LEFT_ENTRY"] = "e";
luapad._sG["ACT_DOD_CROUCH_AIM_BOLT"] = "e";
luapad._sG["TYPE_NORMAL"] = "e";
luapad._sG["ACT_HL2MP_IDLE_CROUCH_SLAM"] = "e";
luapad._sG["ACT_MP_ATTACK_CROUCH_PRIMARYFIRE_DEPLOYED"] = "e";
luapad._sG["ACT_GESTURE_TURN_LEFT45_FLAT"] = "e";
luapad._sG["ACT_DOD_CROUCH_AIM_KNIFE"] = "e";
luapad._sG["ACT_DOD_WALK_AIM_GREN_FRAG"] = "e";
luapad._sG["ACT_BUSY_LEAN_LEFT_EXIT"] = "e";
luapad._sG["DIR_NONE"] = "e";
luapad._sG["DIR_BACKWARD"] = "e";
luapad._sG["SCHED_IDLE_WALK"] = "e";
luapad._sG["ACT_VM_RELOAD_IDLE"] = "e";
luapad._sG["ACT_RUN_CROUCH_AIM"] = "e";
luapad._sG["ACT_MP_ATTACK_AIRWALK_GRENADE_PRIMARY"] = "e";
luapad._sG["ACT_VM_ATTACH_SILENCER"] = "e";
luapad._sG["ACT_DOD_PRONEWALK_IDLE_C96"] = "e";
luapad._sG["HUD_PRINTTALK"] = "e";
luapad._sG["FCVAR_DONTRECORD"] = "e";
luapad._sG["ACT_MP_ATTACK_CROUCH_PREFIRE"] = "e";
luapad._sG["ACT_RUN_RELAXED"] = "e";
luapad._sG["GAMEMODE_NAME"] = "e";
luapad._sG["ACT_CROUCHING_SHIELD_ATTACK"] = "e";
luapad._sG["ACT_RUN_STIMULATED"] = "e";
luapad._sG["ACT_GESTURE_BIG_FLINCH"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_ZOOM_BAZOOKA"] = "e";
luapad._sG["ACT_RANGE_ATTACK_SNIPER_RIFLE"] = "e";
luapad._sG["ACT_HL2MP_JUMP"] = "e";
luapad._sG["ACT_DOD_WALK_IDLE_PISTOL"] = "e";
luapad._sG["ACT_VM_DEPLOY_6"] = "e";
luapad._sG["ACT_HL2MP_WALK_PISTOL"] = "e";
luapad._sG["ACT_DIE_CHESTSHOT"] = "e";
luapad._sG["ACT_DOD_RELOAD_MP44"] = "e";
luapad._sG["ACT_MP_ATTACK_AIRWALK_GRENADE_MELEE"] = "e";
luapad._sG["ACT_GESTURE_FLINCH_RIGHTLEG"] = "e";
luapad._sG["ACT_MP_ATTACK_SWIM_GRENADE"] = "e";
luapad._sG["COLLISION_GROUP_PROJECTILE"] = "e";
luapad._sG["MOUSE_WHEEL_DOWN"] = "e";
luapad._sG["COLLISION_GROUP_PLAYER"] = "e";
luapad._sG["KEY_PAD_6"] = "e";
luapad._sG["E2_MAX_ARRAY_SIZE"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_PISTOL"] = "e";
luapad._sG["ACT_DOD_WALK_AIM_GREASE"] = "e";
luapad._sG["KEY_FIRST"] = "e";
luapad._sG["ACT_DOD_PRONEWALK_IDLE_BAR"] = "e";
luapad._sG["ACT_DOD_WALK_AIM_PISTOL"] = "e";
luapad._sG["ACT_SMG2_TOBURST"] = "e";
luapad._sG["CAP_SKIP_NAV_GROUND_CHECK"] = "e";
luapad._sG["ACT_DOD_RUN_ZOOM_BAZOOKA"] = "e";
luapad._sG["ACT_HANDGRENADE_THROW1"] = "e";
luapad._sG["ACT_SLAM_STICKWALL_ND_IDLE"] = "e";
luapad._sG["ACT_MP_ATTACK_STAND_PREFIRE"] = "e";
luapad._sG["SCHED_MOVE_AWAY"] = "e";
luapad._sG["ACT_WALK_RIFLE_STIMULATED"] = "e";
luapad._sG["ACT_SLAM_THROW_DETONATE"] = "e";
luapad._sG["ACT_MP_RELOAD_CROUCH_SECONDARY_END"] = "e";
luapad._sG["ACT_BUSY_LEAN_BACK"] = "e";
luapad._sG["ACT_DOD_PRONE_DEPLOY_RIFLE"] = "e";
luapad._sG["KEY_XBUTTON_DOWN"] = "e";
luapad._sG["CAP_INNATE_RANGE_ATTACK1"] = "e";
luapad._sG["ACT_IDLE_MELEE"] = "e";
luapad._sG["CONTENTS_CURRENT_180"] = "e";
luapad._sG["CLASS_COMBINE_HUNTER"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_RIFLE"] = "e";
luapad._sG["COLLISION_GROUP_INTERACTIVE_DEBRIS"] = "e";
luapad._sG["ACT_VM_MISSLEFT2"] = "e";
luapad._sG["ACT_VM_PICKUP"] = "e";
luapad._sG["ACT_DOD_SECONDARYATTACK_PRONE_BOLT"] = "e";
luapad._sG["ACT_DOD_WALK_ZOOM_BOLT"] = "e";
luapad._sG["ACT_MP_ATTACK_AIRWALK_SECONDARY"] = "e";
luapad._sG["NUM_HULLS"] = "e";
luapad._sG["MASK_PLAYERSOLID_BRUSHONLY"] = "e";
luapad._sG["ACT_SIGNAL_HALT"] = "e";
luapad._sG["ACT_MP_ATTACK_AIRWALK_GRENADE"] = "e";
luapad._sG["CAP_MOVE_JUMP"] = "e";
luapad._sG["ACT_DOD_PRONE_AIM_KNIFE"] = "e";
luapad._sG["MOVETYPE_PUSH"] = "e";
luapad._sG["ACT_DOD_RELOAD_CROUCH_M1CARBINE"] = "e";
luapad._sG["OBS_MODE_NONE"] = "e";
luapad._sG["PLAYER_START_AIMING"] = "e";
luapad._sG["ACT_TURN"] = "e";
luapad._sG["ACT_MP_ATTACK_SWIM_POSTFIRE"] = "e";
luapad._sG["KEY_0"] = "e";
luapad._sG["IN_RELOAD"] = "e";
luapad._sG["CLASS_CITIZEN_REBEL"] = "e";
luapad._sG["BLOOD_COLOR_ANTLION"] = "e";
luapad._sG["ACT_DOD_RUN_IDLE_TOMMY"] = "e";
luapad._sG["PATTACH_WORLDORIGIN"] = "e";
luapad._sG["ACT_STEP_BACK"] = "e";
luapad._sG["ACT_RUN_AIM_AGITATED"] = "e";
luapad._sG["OBS_MODE_ROAMING"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_C96"] = "e";
luapad._sG["HITGROUP_HEAD"] = "e";
luapad._sG["SCHED_FAIL_TAKE_COVER"] = "e";
luapad._sG["ACT_DOD_CROUCH_IDLE_PSCHRECK"] = "e";
luapad._sG["ACT_GESTURE_MELEE_ATTACK2"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK_DEPLOYED_5"] = "e";
luapad._sG["ACT_DOD_PRONE_AIM_GREN_FRAG"] = "e";
luapad._sG["SCHED_ESTABLISH_LINE_OF_FIRE"] = "e";
luapad._sG["ACT_DOD_WALK_AIM_BAR"] = "e";
luapad._sG["ACT_SLAM_TRIPMINE_TO_THROW_ND"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RELOAD_FIST"] = "e";
luapad._sG["ACT_DOD_HS_IDLE"] = "e";
luapad._sG["ACT_MP_ATTACK_STAND_POSTFIRE"] = "e";
luapad._sG["CLASS_STALKER"] = "e";
luapad._sG["ACT_VM_DEPLOY_1"] = "e";
luapad._sG["CAP_DUCK"] = "e";
luapad._sG["ACT_GESTURE_TURN_LEFT90_FLAT"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_FG42"] = "e";
luapad._sG["KEY_EQUAL"] = "e";
luapad._sG["ACT_HL2MP_IDLE_MELEE"] = "e";
luapad._sG["ACT_DOD_WALK_AIM_30CAL"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_CROUCH_GREN_STICK"] = "e";
luapad._sG["MAT_BLOODYFLESH"] = "e";
luapad._sG["SF_CITIZEN_IGNORE_SEMAPHORE"] = "e";
luapad._sG["KEY_9"] = "e";
luapad._sG["ACT_MP_SECONDARY_GRENADE1_ATTACK"] = "e";
luapad._sG["ACT_DOD_RUN_IDLE_MP40"] = "e";
luapad._sG["ACT_DOD_HS_CROUCH_30CAL"] = "e";
luapad._sG["ACT_DOD_PRONE_AIM_RIFLE"] = "e";
luapad._sG["HITGROUP_GEAR"] = "e";
luapad._sG["ACT_MP_CROUCH_PRIMARY"] = "e";
luapad._sG["ACT_RUN_AIM_STEALTH"] = "e";
luapad._sG["ACT_MP_JUMP_FLOAT"] = "e";
luapad._sG["ACT_PHYSCANNON_ANIMATE_POST"] = "e";
luapad._sG["ACT_DISARM"] = "e";
luapad._sG["ACT_MP_RELOAD_STAND_PRIMARY_LOOP"] = "e";
luapad._sG["COMP_TEXT_AND_CHARS"] = "e";
luapad._sG["SCHED_ESTABLISH_LINE_OF_FIRE_FALLBACK"] = "e";
luapad._sG["ACT_MP_SECONDARY_GRENADE1_DRAW"] = "e";
luapad._sG["ACT_DOD_RUN_IDLE_PISTOL"] = "e";
luapad._sG["ACT_VM_RELOAD"] = "e";
luapad._sG["ACT_DI_ALYX_ZOMBIE_SHOTGUN26"] = "e";
luapad._sG["KEY_RALT"] = "e";
luapad._sG["ACT_DOD_CROUCH_AIM_GREN_FRAG"] = "e";
luapad._sG["ACT_DOD_DEPLOY_MG"] = "e";
luapad._sG["ACT_MP_CROUCH_DEPLOYED"] = "e";
luapad._sG["CAP_AUTO_DOORS"] = "e";
luapad._sG["SCHED_MELEE_ATTACK1"] = "e";
luapad._sG["ACT_GESTURE_RANGE_ATTACK_SMG1"] = "e";
luapad._sG["ACT_DOD_PRONE_ZOOM_FORWARD_BAZOOKA"] = "e";
luapad._sG["ACT_POLICE_HARASS1"] = "e";
luapad._sG["ACT_STRAFE_LEFT"] = "e";
luapad._sG["KEY_ESCAPE"] = "e";
luapad._sG["ACT_DOD_RELOAD_DEPLOYED"] = "e";
luapad._sG["ACT_DOD_SECONDARYATTACK_PRONE_MP40"] = "e";
luapad._sG["MASK_BLOCKLOS"] = "e";
luapad._sG["ACT_MP_SECONDARY_GRENADE2_DRAW"] = "e";
luapad._sG["RENDERMODE_NORMAL"] = "e";
luapad._sG["ACT_CROUCHING_GRENADEREADY"] = "e";
luapad._sG["ACT_GESTURE_RANGE_ATTACK_AR1"] = "e";
luapad._sG["KEY_XBUTTON_UP"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_DEPLOYED_RIFLE"] = "e";
luapad._sG["ACT_MP_GESTURE_FLINCH_CHEST"] = "e";
luapad._sG["SCHED_NPC_FREEZE"] = "e";
luapad._sG["COLLISION_GROUP_INTERACTIVE"] = "e";
luapad._sG["SF_PHYSBOX_MOTIONDISABLED"] = "e";
luapad._sG["ACT_UNDEPLOY"] = "e";
luapad._sG["ACT_VM_SWINGMISS"] = "e";
luapad._sG["JOYSTICK_FIRST_BUTTON"] = "e";
luapad._sG["RENDERMODE_ENVIROMENTAL"] = "e";
luapad._sG["ACT_MP_ATTACK_SWIM_GRENADE_MELEE"] = "e";
luapad._sG["ACT_WALK_STIMULATED"] = "e";
luapad._sG["IN_GRENADE1"] = "e";
luapad._sG["MASK_NPCSOLID_BRUSHONLY"] = "e";
luapad._sG["ACT_GMOD_IN_CHAT"] = "e";
luapad._sG["CONTENTS_HITBOX"] = "e";
luapad._sG["ACT_SLAM_THROW_TO_STICKWALL_ND"] = "e";
luapad._sG["ACT_HL2MP_IDLE_CROUCH_PHYSGUN"] = "e";
luapad._sG["FCVAR_CLIENTCMD_CAN_EXECUTE"] = "e";
luapad._sG["FCVAR_CHEAT"] = "e";
luapad._sG["ACT_DEEPIDLE4"] = "e";
luapad._sG["CONTENTS_TEAM4"] = "e";
luapad._sG["IN_MOVELEFT"] = "e";
luapad._sG["ACT_COVER_PISTOL_LOW"] = "e";
luapad._sG["SCHED_CHASE_ENEMY_FAILED"] = "e";
luapad._sG["DMG_DISSOLVE"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_DEPLOYED"] = "e";
luapad._sG["DMG_GENERIC"] = "e";
luapad._sG["CONTENTS_TEAM1"] = "e";
luapad._sG["ACT_DOD_HS_IDLE_MG42"] = "e";
luapad._sG["CAP_AIM_GUN"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_IDLE_30CAL"] = "e";
luapad._sG["ACT_DOD_PRONE_AIM_BAR"] = "e";
luapad._sG["ACT_CROUCHING_SHIELD_KNOCKBACK"] = "e";
luapad._sG["ACT_VM_SWINGHIT"] = "e";
luapad._sG["ACT_DOD_WALK_IDLE_MG"] = "e";
luapad._sG["ACT_DOD_RELOAD_CROUCH_PSCHRECK"] = "e";
luapad._sG["SF_CITIZEN_MEDIC"] = "e";
luapad._sG["ACT_DOD_RUN_AIM_SPADE"] = "e";
luapad._sG["CAP_MOVE_SWIM"] = "e";
luapad._sG["COLLISION_GROUP_DEBRIS"] = "e";
luapad._sG["ACT_SLAM_THROW_ND_IDLE"] = "e";
luapad._sG["ACT_RANGE_AIM_SMG1_LOW"] = "e";
luapad._sG["SOLID_VPHYSICS"] = "e";
luapad._sG["ACT_GESTURE_TURN_RIGHT90"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_PSCHRECK"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_KNIFE"] = "e";
luapad._sG["SCHED_RUN_FROM_ENEMY_FALLBACK"] = "e";
luapad._sG["MOVECOLLIDE_FLY_SLIDE"] = "e";
luapad._sG["MOUSE_5"] = "e";
luapad._sG["ACT_HL2MP_JUMP_PISTOL"] = "e";
luapad._sG["ACT_DOD_STAND_IDLE_BAR"] = "e";
luapad._sG["SCHED_IDLE_STAND"] = "e";
luapad._sG["KEY_XBUTTON_LTRIGGER"] = "e";
luapad._sG["ACT_DOD_HS_IDLE_PSCHRECK"] = "e";
luapad._sG["ACT_HL2MP_IDLE_CROUCH_PISTOL"] = "e";
luapad._sG["ACT_RELOAD_SMG1"] = "e";
luapad._sG["BUTTON_CODE_COUNT"] = "e";
luapad._sG["ACT_TURN_LEFT"] = "e";
luapad._sG["PATTACH_CUSTOMORIGIN"] = "e";
luapad._sG["KEY_XBUTTON_STICK1"] = "e";
luapad._sG["ACT_DOD_STAND_AIM_KNIFE"] = "e";
luapad._sG["CLASS_FLARE"] = "e";
luapad._sG["ACT_VM_SPRINT_ENTER"] = "e";
luapad._sG["ACT_MP_RELOAD_SWIM_SECONDARY"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RELOAD"] = "e";
luapad._sG["CONTENTS_IGNORE_NODRAW_OPAQUE"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_NODYES_SECONDARY"] = "e";
luapad._sG["RENDERMODE_TRANSCOLOR"] = "e";
luapad._sG["ACT_SLAM_STICKWALL_ND_DRAW"] = "e";
luapad._sG["IN_JUMP"] = "e";
luapad._sG["ACT_RUN_AGITATED"] = "e";
luapad._sG["ACT_DOD_HS_CROUCH_PISTOL"] = "e";
luapad._sG["COMP_NORMAL_CHARS"] = "e";
luapad._sG["KEY_F3"] = "e";
luapad._sG["T"] = "e";
luapad._sG["ACT_RELOAD"] = "e";
luapad._sG["PROG"] = "e";
luapad._sG["ACT_VM_IDLE_6"] = "e";
luapad._sG["JOYSTICK_LAST_AXIS_BUTTON"] = "e";
luapad._sG["ACT_OBJ_PLACING"] = "e";
luapad._sG["ACT_MP_JUMP_PDA"] = "e";
luapad._sG["ACT_DIE_RIGHTSIDE"] = "e";
luapad._sG["ACT_MP_AIRWALK"] = "e";
luapad._sG["COMP_TEXT_AND_NUMBERS"] = "e";
luapad._sG["COMP_SPECIAL_CHARS"] = "e";
luapad._sG["ACT_HL2MP_WALK_SMG1"] = "e";
luapad._sG["COMP_TEXT"] = "e";
luapad._sG["ACT_DOD_SECONDARYATTACK_PRONE"] = "e";
luapad._sG["ACT_DOD_STAND_AIM_C96"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_DEPLOYED_30CAL"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_RIFLE"] = "e";
luapad._sG["MASK_NPCWORLDSTATIC"] = "e";
luapad._sG["ACT_SHOTGUN_IDLE_DEEP"] = "e";
luapad._sG["ACT_DOD_WALK_IDLE"] = "e";
luapad._sG["ACT_MP_AIRWALK_MELEE"] = "e";
luapad._sG["DRV"] = "e";
luapad._sG["ACT_HL2MP_JUMP_FIST"] = "e";
luapad._sG["_VERSION"] = "e";
luapad._sG["ACT_RANGE_ATTACK_SMG1"] = "e";
luapad._sG["DMG_REMOVENORAGDOLL"] = "e";
luapad._sG["BUTTON_CODE_LAST"] = "e";
luapad._sG["FCVAR_ARCHIVE"] = "e";
luapad._sG["ACT_VM_DRYFIRE_SILENCED"] = "e";
luapad._sG["ACT_HL2MP_SIT_GRENADE"] = "e";
luapad._sG["ACT_CROUCHING_PRIMARYATTACK"] = "e";
luapad._sG["ACT_DOD_PRONE_AIM_MP40"] = "e";
luapad._sG["ACT_MP_ATTACK_CROUCH_POSTFIRE"] = "e";
luapad._sG["FCVAR_REPLICATED"] = "e";
luapad._sG["STNDRD"] = "e";
luapad._sG["LAST_SHARED_COLLISION_GROUP"] = "e";
luapad._sG["ACT_MP_RELOAD_STAND_PRIMARY_END"] = "e";
luapad._sG["ACT_SLAM_THROW_DRAW"] = "e";
luapad._sG["FORCE_BOOL"] = "e";
luapad._sG["ACT_WALK_CROUCH_AIM_RIFLE"] = "e";
luapad._sG["ACT_LEAP"] = "e";
luapad._sG["ACT_RUN_AIM"] = "e";
luapad._sG["ACT_COWER"] = "e";
luapad._sG["ACT_HL2MP_IDLE_CROUCH_GRENADE"] = "e";
luapad._sG["CONTENTS_CURRENT_0"] = "e";
luapad._sG["ACT_BUSY_STAND"] = "e";
luapad._sG["USE_TOGGLE"] = "e";
luapad._sG["USE_SET"] = "e";
luapad._sG["ACT_SMG2_DRYFIRE2"] = "e";
luapad._sG["ACT_MP_SECONDARY_GRENADE2_ATTACK"] = "e";
luapad._sG["TRANSMIT_NEVER"] = "e";
luapad._sG["TEXT_ALIGN_LEFT"] = "e";
luapad._sG["TEAM_SPECTATOR"] = "e";
luapad._sG["TEAM_UNASSIGNED"] = "e";
luapad._sG["TEAM_CONNECTING"] = "e";
luapad._sG["ACT_DOD_RELOAD_DEPLOYED_MG34"] = "e";
luapad._sG["KEY_LSHIFT"] = "e";
luapad._sG["SIM_LOCAL_ACCELERATION"] = "e";
luapad._sG["CAP_WEAPON_MELEE_ATTACK1"] = "e";
luapad._sG["SIM_NOTHING"] = "e";
luapad._sG["ACT_DRIVE_JEEP"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_TOMMY"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_NODNO_MELEE"] = "e";
luapad._sG["KEY_XBUTTON_Y"] = "e";
luapad._sG["RENDERMODE_WORLDGLOW"] = "e";
luapad._sG["RENDERMODE_TRANSADDFRAMEBLEND"] = "e";
luapad._sG["RENDERMODE_TRANSADD"] = "e";
luapad._sG["RENDERMODE_TRANSALPHA"] = "e";
luapad._sG["RENDERMODE_TRANSTEXTURE"] = "e";
luapad._sG["ACT_DOD_STAND_IDLE_PISTOL"] = "e";
luapad._sG["MAT_ALIENFLESH"] = "e";
luapad._sG["MAT_CLIP"] = "e";
luapad._sG["ACT_MP_SWIM_DEPLOYED_PRIMARY"] = "e";
luapad._sG["MAT_FLESH"] = "e";
luapad._sG["ACT_DOD_RELOAD_CROUCH_TOMMY"] = "e";
luapad._sG["DMG_NERVEGAS"] = "e";
luapad._sG["ACT_VM_IDLE_DEPLOYED_3"] = "e";
luapad._sG["ACT_DOD_PRONEWALK_IDLE_GREASE"] = "e";
luapad._sG["ACT_VM_DEPLOY_4"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_BAZOOKA"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_MP44"] = "e";
luapad._sG["NULL"] = "e";
luapad._sG["ACT_DIESIMPLE"] = "e";
luapad._sG["ACT_MP_RELOAD_CROUCH_END"] = "e";
luapad._sG["ACT_MP_CROUCHWALK_BUILDING"] = "e";
luapad._sG["KEY_LWIN"] = "e";
luapad._sG["ACT_CROUCHIDLE_STIMULATED"] = "e";
luapad._sG["MASK_CURRENT"] = "e";
luapad._sG["ACT_WALK_SUITCASE"] = "e";
luapad._sG["COLLISION_GROUP_DISSOLVING"] = "e";
luapad._sG["ACT_DOD_CROUCH_ZOOM_PSCHRECK"] = "e";
luapad._sG["ACT_DOD_WALK_AIM_BOLT"] = "e";
luapad._sG["BLOOD_COLOR_RED"] = "e";
luapad._sG["ACT_ITEM_GIVE"] = "e";
luapad._sG["ACT_VM_IDLE_5"] = "e";
luapad._sG["ACT_FIRE_END"] = "e";
luapad._sG["ACT_MP_GESTURE_FLINCH"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_MP40"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_CROUCH_SPADE"] = "e";
luapad._sG["FCVAR_DEMO"] = "e";
luapad._sG["ACT_MP_RUN"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_AIM_MP44"] = "e";
luapad._sG["ACT_VM_MISSRIGHT2"] = "e";
luapad._sG["IN_CANCEL"] = "e";
luapad._sG["HULL_LARGE"] = "e";
luapad._sG["VERSION"] = "e";
luapad._sG["KEY_BREAK"] = "e";
luapad._sG["BLOOD_COLOR_ANTLION_WORKER"] = "e";
luapad._sG["ACT_WALK_CARRY"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RELOAD_PISTOL"] = "e";
luapad._sG["COLLISION_GROUP_PASSABLE_DOOR"] = "e";
luapad._sG["ACT_DOD_SPRINT_AIM_GREN_STICK"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_AIM"] = "e";
luapad._sG["ACT_RANGE_ATTACK1_LOW"] = "e";
luapad._sG["ACT_DOD_STAND_AIM_BAZOOKA"] = "e";
luapad._sG["ACT_VM_HITCENTER"] = "e";
luapad._sG["ACT_DOD_STAND_IDLE_BOLT"] = "e";
luapad._sG["ACT_DOD_PRONE_AIM_30CAL"] = "e";
luapad._sG["ACT_FLINCH_RIGHTARM"] = "e";
luapad._sG["ACT_SLAM_STICKWALL_TO_TRIPMINE_ND"] = "e";
luapad._sG["SOLID_CUSTOM"] = "e";
luapad._sG["FVPHYSICS_DMG_SLICE"] = "e";
luapad._sG["ACT_DOD_STAND_IDLE_BAZOOKA"] = "e";
luapad._sG["ACT_HL2MP_JUMP_GRENADE"] = "e";
luapad._sG["SCHED_MOVE_AWAY_FROM_ENEMY"] = "e";
luapad._sG["KEY_XBUTTON_RIGHT_SHOULDER"] = "e";
luapad._sG["ACT_HL2MP_RUN"] = "e";
luapad._sG["ACT_MP_GRENADE2_DRAW"] = "e";
luapad._sG["CONTENTS_SLIME"] = "e";
luapad._sG["ACT_DOD_CROUCH_ZOOM_RIFLE"] = "e";
luapad._sG["ACT_IDLE_AIM_STIMULATED"] = "e";
luapad._sG["CAP_ANIMATEDFACE"] = "e";
luapad._sG["ACT_DOD_PRONE_ZOOM_BAZOOKA"] = "e";
luapad._sG["ACT_HL2MP_WALK_PASSIVE"] = "e";
luapad._sG["SCHED_BIG_FLINCH"] = "e";
luapad._sG["ACT_DOD_WALK_IDLE_C96"] = "e";
luapad._sG["ACT_DOD_WALK_IDLE_BOLT"] = "e";
luapad._sG["ACT_HL2MP_RUN_AR2"] = "e";
luapad._sG["ACT_MP_VCD"] = "e";
luapad._sG["BOX_BOTTOM"] = "e";
luapad._sG["COLLISION_GROUP_NPC_SCRIPTED"] = "e";
luapad._sG["ACT_DOD_PLANT_TNT"] = "e";
luapad._sG["ACT_HL2MP_IDLE_CROUCH_CROSSBOW"] = "e";
luapad._sG["ACT_POLICE_HARASS2"] = "e";
luapad._sG["ACT_180_RIGHT"] = "e";
luapad._sG["ACT_PICKUP_RACK"] = "e";
luapad._sG["SOLID_BSP"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_30CAL"] = "e";
luapad._sG["ACT_PRONE_IDLE"] = "e";
luapad._sG["ACT_HL2MP_SIT_PHYSGUN"] = "e";
luapad._sG["ACT_DOD_RUN_AIM_BOLT"] = "e";
luapad._sG["ACT_VM_DEPLOY_7"] = "e";
luapad._sG["ACT_PRONE_FORWARD"] = "e";
luapad._sG["RENDERMODE_NONE"] = "e";
luapad._sG["CONTENTS_CURRENT_90"] = "e";
luapad._sG["ACT_OVERLAY_SHIELD_DOWN"] = "e";
luapad._sG["ACT_WALK_AIM_RELAXED"] = "e";
luapad._sG["CLASS_ANTLION"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_DEPLOYED"] = "e";
luapad._sG["ACT_MP_JUMP_FLOAT_MELEE"] = "e";
luapad._sG["ACT_MP_GESTURE_FLINCH_MELEE"] = "e";
luapad._sG["ACT_DOD_WALK_AIM_MP44"] = "e";
luapad._sG["BLOOD_COLOR_MECH"] = "e";
luapad._sG["SCHED_MOVE_AWAY_FAIL"] = "e";
luapad._sG["ACT_IDLE_AIM_AGITATED"] = "e";
luapad._sG["DONT_BLEED"] = "e";
luapad._sG["PATTACH_POINT_FOLLOW"] = "e";
luapad._sG["ACT_DOD_RUN_AIM_TOMMY"] = "e";
luapad._sG["SCHED_NEW_WEAPON"] = "e";
luapad._sG["MOVECOLLIDE_COUNT"] = "e";
luapad._sG["PATTACH_POINT"] = "e";
luapad._sG["ACT_MP_ATTACK_AIRWALK_PRIMARYFIRE"] = "e";
luapad._sG["ACT_DOD_STAND_AIM_PISTOL"] = "e";
luapad._sG["PATTACH_ABSORIGIN_FOLLOW"] = "e";
luapad._sG["LAST_SHARED_ACTIVITY"] = "e";
luapad._sG["ACT_MP_RELOAD_STAND_END"] = "e";
luapad._sG["STEPSOUNDTIME_WATER_FOOT"] = "e";
luapad._sG["ACT_DOD_STAND_AIM_TOMMY"] = "e";
luapad._sG["KEY_Y"] = "e";
luapad._sG["ACT_VM_IDLE_LOWERED"] = "e";
luapad._sG["STEPSOUNDTIME_WATER_KNEE"] = "e";
luapad._sG["ACT_BUSY_SIT_GROUND_ENTRY"] = "e";
luapad._sG["STEPSOUNDTIME_NORMAL"] = "e";
luapad._sG["SF_FLOOR_TURRET_CITIZEN"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_IDLE_MP40"] = "e";
luapad._sG["ACT_DOD_RUN_ZOOM_RIFLE"] = "e";
luapad._sG["ACT_PLAYER_IDLE_FIRE"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_NODYES_PRIMARY"] = "e";
luapad._sG["SF_NPC_TEMPLATE"] = "e";
luapad._sG["ACT_RESET"] = "e";
luapad._sG["ACT_MP_ATTACK_SWIM_PREFIRE"] = "e";
luapad._sG["ACT_WALK_ANGRY"] = "e";
luapad._sG["SF_NPC_LONG_RANGE"] = "e";
luapad._sG["ACT_RUN_AIM_STEALTH_PISTOL"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK_4"] = "e";
luapad._sG["ACT_DOD_STAND_IDLE_TOMMY"] = "e";
luapad._sG["SF_NPC_START_EFFICIENT"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_AIM_TOMMY"] = "e";
luapad._sG["ACT_VM_HOLSTER"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_FINGERPOINT_PRIMARY"] = "e";
luapad._sG["MOVETYPE_FLY"] = "e";
luapad._sG["ACT_MP_RUN_PDA"] = "e";
luapad._sG["ACT_DOD_PRONE_AIM_C96"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK_SILENCED"] = "e";
luapad._sG["ACT_SIGNAL_LEFT"] = "e";
luapad._sG["ACT_RUN_HURT"] = "e";
luapad._sG["ACT_DOD_ZOOMLOAD_PRONE_BAZOOKA"] = "e";
luapad._sG["CT_REBEL"] = "e";
luapad._sG["ACT_MP_RUN_BUILDING"] = "e";
luapad._sG["ACT_FLINCH_STOMACH"] = "e";
luapad._sG["CT_REFUGEE"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_IDLE"] = "e";
luapad._sG["ACT_WALK_RPG_RELAXED"] = "e";
luapad._sG["ACT_RELOAD_SHOTGUN"] = "e";
luapad._sG["ACT_DOD_HS_CROUCH_MP44"] = "e";
luapad._sG["SF_CITIZEN_USE_RENDER_BOUNDS"] = "e";
luapad._sG["ACT_HL2MP_JUMP_SHOTGUN"] = "e";
luapad._sG["SF_CITIZEN_RANDOM_HEAD_MALE"] = "e";
luapad._sG["HITGROUP_RIGHTLEG"] = "e";
luapad._sG["ACT_SMG2_FIRE2"] = "e";
luapad._sG["ACT_MP_GESTURE_FLINCH_RIGHTLEG"] = "e";
luapad._sG["CLASS_EARTH_FAUNA"] = "e";
luapad._sG["SF_CITIZEN_AMMORESUPPLIER"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_FINGERPOINT"] = "e";
luapad._sG["ACT_90_RIGHT"] = "e";
luapad._sG["ACT_WALK_ON_FIRE"] = "e";
luapad._sG["SF_CITIZEN_FOLLOW"] = "e";
luapad._sG["D_LI"] = "e";
luapad._sG["ACT_VM_IDLE_EMPTY"] = "e";
luapad._sG["ACT_DOD_RUN_AIM_MG"] = "e";
luapad._sG["D_FR"] = "e";
luapad._sG["ACT_SIGNAL_FORWARD"] = "e";
luapad._sG["ACT_SLAM_THROW_TO_TRIPMINE_ND"] = "e";
luapad._sG["ACT_DOD_PRONEWALK_IDLE_TOMMY"] = "e";
luapad._sG["ACT_GLOCK_SHOOTEMPTY"] = "e";
luapad._sG["KEY_S"] = "e";
luapad._sG["MASK_DEADSOLID"] = "e";
luapad._sG["D_ER"] = "e";
luapad._sG["ACT_DOD_WALK_AIM_C96"] = "e";
luapad._sG["COLLISION_GROUP_VEHICLE_CLIP"] = "e";
luapad._sG["ACT_GESTURE_RANGE_ATTACK2"] = "e";
luapad._sG["ACT_CLIMB_DISMOUNT"] = "e";
luapad._sG["ACT_DOD_PRONE_AIM_SPADE"] = "e";
luapad._sG["NPC_STATE_ALERT"] = "e";
luapad._sG["KEY_END"] = "e";
luapad._sG["ACT_WALK_CROUCH"] = "e";
luapad._sG["ACT_DOD_RUN_IDLE_GREASE"] = "e";
luapad._sG["ACT_IDLE_PACKAGE"] = "e";
luapad._sG["ACT_RANGE_ATTACK_ML"] = "e";
luapad._sG["ACT_WALK_RPG"] = "e";
luapad._sG["ACT_RUN_AIM_RIFLE_STIMULATED"] = "e";
luapad._sG["ACT_DOD_WALK_AIM"] = "e";
luapad._sG["ACT_GESTURE_RANGE_ATTACK_SLAM"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_ZOOM_PSCHRECK"] = "e";
luapad._sG["FVPHYSICS_NO_NPC_IMPACT_DMG"] = "e";
luapad._sG["SURF_HINT"] = "e";
luapad._sG["ACT_DOD_SECONDARYATTACK_CROUCH_TOMMY"] = "e";
luapad._sG["CLASS_MANHACK"] = "e";
luapad._sG["ACT_HL2MP_IDLE_CROUCH_SHOTGUN"] = "e";
luapad._sG["CLASS_COMBINE_GUNSHIP"] = "e";
luapad._sG["CLASS_COMBINE"] = "e";
luapad._sG["ACT_READINESS_PISTOL_RELAXED_TO_STIMULATED_WALK"] = "e";
luapad._sG["CLASS_CITIZEN_PASSIVE"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_AIM_MP40"] = "e";
luapad._sG["CLASS_BARNACLE"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_GREN_STICK"] = "e";
luapad._sG["CLASS_PLAYER_ALLY_VITAL"] = "e";
luapad._sG["CLASS_PLAYER"] = "e";
luapad._sG["SCHED_HIDE_AND_RELOAD"] = "e";
luapad._sG["HULL_LARGE_CENTERED"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_MP40"] = "e";
luapad._sG["CONTENTS_OPAQUE"] = "e";
luapad._sG["HULL_TINY_CENTERED"] = "e";
luapad._sG["HULL_MEDIUM"] = "e";
luapad._sG["ACT_DOD_PRONE_ZOOM_BOLT"] = "e";
luapad._sG["ACT_CLIMB_UP"] = "e";
luapad._sG["ACT_BUSY_LEAN_BACK_EXIT"] = "e";
luapad._sG["ACT_BUSY_SIT_GROUND_EXIT"] = "e";
luapad._sG["ACT_WALK_AGITATED"] = "e";
luapad._sG["SF_CITIZEN_NOT_COMMANDABLE"] = "e";
luapad._sG["ACT_GESTURE_MELEE_ATTACK_SWING"] = "e";
luapad._sG["ACT_IDLE_ANGRY"] = "e";
luapad._sG["DMG_ENERGYBEAM"] = "e";
luapad._sG["KEY_PAD_PLUS"] = "e";
luapad._sG["CAP_NO_HIT_SQUADMATES"] = "e";
luapad._sG["CAP_SQUAD"] = "e";
luapad._sG["ACT_VM_IDLE_8"] = "e";
luapad._sG["ACT_DOD_WALK_IDLE_RIFLE"] = "e";
luapad._sG["CAP_USE_WEAPONS"] = "e";
luapad._sG["ACT_GESTURE_SMALL_FLINCH"] = "e";
luapad._sG["ACT_PLAYER_CROUCH_WALK_FIRE"] = "e";
luapad._sG["DMG_DROWNRECOVER"] = "e";
luapad._sG["ACT_WALK_AIM_STIMULATED"] = "e";
luapad._sG["ACT_STEP_LEFT"] = "e";
luapad._sG["CAP_WEAPON_RANGE_ATTACK2"] = "e";
luapad._sG["CAP_WEAPON_RANGE_ATTACK1"] = "e";
luapad._sG["ACT_MP_ATTACK_AIRWALK_SECONDARYFIRE"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_IDLE_MG"] = "e";
luapad._sG["KEY_E"] = "e";
luapad._sG["CAP_TURN_HEAD"] = "e";
luapad._sG["ACT_READINESS_RELAXED_TO_STIMULATED"] = "e";
luapad._sG["ACT_CROSSBOW_FIDGET_UNLOADED"] = "e";
luapad._sG["ACT_MP_CROUCH_PDA"] = "e";
luapad._sG["ACT_GESTURE_RELOAD_SMG1"] = "e";
luapad._sG["ACT_MP_RELOAD_AIRWALK_PRIMARY_END"] = "e";
luapad._sG["ACT_GESTURE_RANGE_ATTACK2_LOW"] = "e";
luapad._sG["ACT_RANGE_ATTACK_THROW"] = "e";
luapad._sG["SCHED_DUCK_DODGE"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK_6"] = "e";
luapad._sG["ACT_MP_ATTACK_STAND_GRENADE_BUILDING"] = "e";
luapad._sG["KEY_PAD_4"] = "e";
luapad._sG["SURF_NOSHADOWS"] = "e";
luapad._sG["SURF_NODRAW"] = "e";
luapad._sG["KEY_SCROLLLOCK"] = "e";
luapad._sG["KEY_PAD_1"] = "e";
luapad._sG["ACT_DIE_BACKSIDE"] = "e";
luapad._sG["ACT_DOD_RUN_AIM_KNIFE"] = "e";
luapad._sG["CAP_MOVE_CLIMB"] = "e";
luapad._sG["CAP_MOVE_FLY"] = "e";
luapad._sG["ACT_HL2MP_IDLE_GRENADE"] = "e";
luapad._sG["ACT_DOD_SPRINT_IDLE_TOMMY"] = "e";
luapad._sG["ACT_HL2MP_IDLE"] = "e";
luapad._sG["KEY_C"] = "e";
luapad._sG["ACT_RELOAD_START"] = "e";
luapad._sG["ACT_DEEPIDLE3"] = "e";
luapad._sG["CONTENTS_WINDOW"] = "e";
luapad._sG["SCHED_SLEEP"] = "e";
luapad._sG["NPC_STATE_PLAYDEAD"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RELOAD_SHOTGUN"] = "e";
luapad._sG["DMG_ALWAYSGIB"] = "e";
luapad._sG["ACT_SIGNAL_TAKECOVER"] = "e";
luapad._sG["CLASS_METROPOLICE"] = "e";
luapad._sG["DMG_SHOCK"] = "e";
luapad._sG["ACT_HL2MP_WALK_CROUCH_MELEE"] = "e";
luapad._sG["ACT_MP_ATTACK_SWIM_PDA"] = "e";
luapad._sG["MOUSE_LAST"] = "e";
luapad._sG["ACT_IDLE_SMG1"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK_1"] = "e";
luapad._sG["ACT_VM_HITRIGHT"] = "e";
luapad._sG["ACT_DIEBACKWARD"] = "e";
luapad._sG["DMG_SLASH"] = "e";
luapad._sG["ACT_VM_MISSCENTER2"] = "e";
luapad._sG["SCHED_SCRIPTED_WALK"] = "e";
luapad._sG["ACT_MP_ATTACK_STAND_SECONDARYFIRE"] = "e";
luapad._sG["SCHED_FALL_TO_GROUND"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RELOAD_MELEE2"] = "e";
luapad._sG["ACT_DOD_STAND_AIM_RIFLE"] = "e";
luapad._sG["DMG_BLAST"] = "e";
luapad._sG["ACT_ROLL_LEFT"] = "e";
luapad._sG["SCHED_FORCED_GO"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_BOLT"] = "e";
luapad._sG["SCHED_MOVE_AWAY_END"] = "e";
luapad._sG["ACT_PLAYER_RUN_FIRE"] = "e";
luapad._sG["ACT_VM_UNDEPLOY_EMPTY"] = "e";
luapad._sG["ACT_MELEE_ATTACK_SWING"] = "e";
luapad._sG["ACT_SLAM_THROW_THROW"] = "e";
luapad._sG["ACT_READINESS_PISTOL_AGITATED_TO_STIMULATED"] = "e";
luapad._sG["ACT_DOD_STAND_AIM_GREASE"] = "e";
luapad._sG["SCHED_WAIT_FOR_SPEAK_FINISH"] = "e";
luapad._sG["_E"] = "e";
luapad._sG["ACT_WALK_AIM_RIFLE_STIMULATED"] = "e";
luapad._sG["FCVAR_UNLOGGED"] = "e";
luapad._sG["SCHED_SWITCH_TO_PENDING_WEAPON"] = "e";
luapad._sG["SCHED_SCRIPTED_WAIT"] = "e";
luapad._sG["ACT_DOD_HS_CROUCH_PSCHRECK"] = "e";
luapad._sG["SCHED_SCRIPTED_CUSTOM_MOVE"] = "e";
luapad._sG["SCHED_SCRIPTED_RUN"] = "e";
luapad._sG["KEY_PAD_MINUS"] = "e";
luapad._sG["SCHED_FLINCH_PHYSICS"] = "e";
luapad._sG["ACT_SLAM_STICKWALL_ND_ATTACH"] = "e";
luapad._sG["SCHED_WAIT_FOR_SCRIPT"] = "e";
luapad._sG["SCHED_DIE_RAGDOLL"] = "e";
luapad._sG["ACT_RANGE_ATTACK_SMG1_LOW"] = "e";
luapad._sG["ACT_WALK_RIFLE"] = "e";
luapad._sG["ACT_RELOAD_SMG1_LOW"] = "e";
luapad._sG["ACT_COVER_SMG1_LOW"] = "e";
luapad._sG["CONTENTS_MONSTER"] = "e";
luapad._sG["ACT_DOD_STAND_AIM_PSCHRECK"] = "e";
luapad._sG["SCHED_ARM_WEAPON"] = "e";
luapad._sG["ACT_RANGE_ATTACK_AR2_LOW"] = "e";
luapad._sG["ACT_DOD_PRONEWALK_AIM_GREN_FRAG"] = "e";
luapad._sG["ACT_DOD_PRONE_AIM_TOMMY"] = "e";
luapad._sG["ACT_VM_IDLE_1"] = "e";
luapad._sG["ACT_SLAM_THROW_DETONATOR_HOLSTER"] = "e";
luapad._sG["SCHED_STANDOFF"] = "e";
luapad._sG["ACT_USE"] = "e";
luapad._sG["SCHED_SPECIAL_ATTACK2"] = "e";
luapad._sG["ACT_WALK_AIM_AGITATED"] = "e";
luapad._sG["SCHED_RANGE_ATTACK1"] = "e";
luapad._sG["SCHED_SHOOT_ENEMY_COVER"] = "e";
luapad._sG["MASK_SHOT_HULL"] = "e";
luapad._sG["ACT_HL2MP_SIT_FIST"] = "e";
luapad._sG["ACT_GLIDE"] = "e";
luapad._sG["ACT_MP_RELOAD_SWIM"] = "e";
luapad._sG["ACT_WALK_CROUCH_AIM"] = "e";
luapad._sG["KEY_RSHIFT"] = "e";
luapad._sG["ACT_RANGE_ATTACK_SLAM"] = "e";
luapad._sG["ACT_DOD_PRONEWALK_AIM_GREN_STICK"] = "e";
luapad._sG["KEY_RWIN"] = "e";
luapad._sG["SCHED_TAKE_COVER_FROM_BEST_SOUND"] = "e";
luapad._sG["ACT_RUN_STEALTH_PISTOL"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK_5"] = "e";
luapad._sG["ACT_DOD_HS_CROUCH_TOMMY"] = "e";
luapad._sG["ACT_HL2MP_JUMP_PHYSGUN"] = "e";
luapad._sG["IN_BACK"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_BAR"] = "e";
luapad._sG["ACT_VM_DEPLOY_8"] = "e";
luapad._sG["SURF_LIGHT"] = "e";
luapad._sG["SCHED_SMALL_FLINCH"] = "e";
luapad._sG["SCHED_TARGET_CHASE"] = "e";
luapad._sG["KEY_F11"] = "e";
luapad._sG["SCHED_CHASE_ENEMY"] = "e";
luapad._sG["CT_UNIQUE"] = "e";
luapad._sG["SCHED_FEAR_FACE"] = "e";
luapad._sG["SURF_SKIP"] = "e";
luapad._sG["BUTTON_CODE_NONE"] = "e";
luapad._sG["SCHED_INVESTIGATE_SOUND"] = "e";
luapad._sG["SCHED_ALERT_SCAN"] = "e";
luapad._sG["SCHED_ALERT_REACT_TO_COMBAT_SOUND"] = "e";
luapad._sG["COLLISION_GROUP_WEAPON"] = "e";
luapad._sG["KEY_F12"] = "e";
luapad._sG["KEY_F5"] = "e";
luapad._sG["SCHED_ALERT_FACE_BESTSOUND"] = "e";
luapad._sG["NUM_AI_CLASSES"] = "e";
luapad._sG["SCHED_IDLE_WANDER"] = "e";
luapad._sG["BLOOD_COLOR_GREEN"] = "e";
luapad._sG["ACT_HOP"] = "e";
luapad._sG["SCHED_MELEE_ATTACK2"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK_DEPLOYED_8"] = "e";
luapad._sG["KEY_NONE"] = "e";
luapad._sG["NPC_STATE_COMBAT"] = "e";
luapad._sG["SCHED_DIE"] = "e";
luapad._sG["ACT_DOD_DEPLOY_30CAL"] = "e";
luapad._sG["NPC_STATE_NONE"] = "e";
luapad._sG["COMP_ALGEBRA"] = "e";
luapad._sG["KEY_F10"] = "e";
luapad._sG["FVPHYSICS_NO_SELF_COLLISIONS"] = "e";
luapad._sG["SF_NPC_WAIT_FOR_SCRIPT"] = "e";
luapad._sG["ACT_WALK_AIM_STEALTH"] = "e";
luapad._sG["KEY_2"] = "e";
luapad._sG["FVPHYSICS_NO_PLAYER_PICKUP"] = "e";
luapad._sG["DMG_PREVENT_PHYSICS_FORCE"] = "e";
luapad._sG["FVPHYSICS_PART_OF_RAGDOLL"] = "e";
luapad._sG["ACT_DI_ALYX_HEADCRAB_MELEE"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_FISTPUMP_BUILDING"] = "e";
luapad._sG["ACT_HL2MP_WALK_CROUCH_MELEE2"] = "e";
luapad._sG["CONTENTS_LADDER"] = "e";
luapad._sG["ACT_IDLE_STIMULATED"] = "e";
luapad._sG["JOYSTICK_LAST"] = "e";
luapad._sG["ACT_DOD_SECONDARYATTACK_MP40"] = "e";
luapad._sG["ACT_VICTORY_DANCE"] = "e";
luapad._sG["ACT_HL2MP_WALK_MELEE2"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RELOAD_PASSIVE"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RANGE_ATTACK_PASSIVE"] = "e";
luapad._sG["CT_DOWNTRODDEN"] = "e";
luapad._sG["ACT_VM_DRAW"] = "e";
luapad._sG["ACT_MP_PRIMARY_GRENADE2_ATTACK"] = "e";
luapad._sG["MAT_GLASS"] = "e";
luapad._sG["DMG_BUCKSHOT"] = "e";
luapad._sG["ACT_WALK_PACKAGE"] = "e";
luapad._sG["ACT_HL2MP_IDLE_PASSIVE"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE"] = "e";
luapad._sG["ACT_GESTURE_TURN_RIGHT45"] = "e";
luapad._sG["FCVAR_UNREGISTERED"] = "e";
luapad._sG["ACT_BARNACLE_CHOMP"] = "e";
luapad._sG["ACT_HL2MP_WALK_CROUCH_FIST"] = "e";
luapad._sG["ACT_RANGE_ATTACK_PISTOL"] = "e";
luapad._sG["ACT_RAPPEL_LOOP"] = "e";
luapad._sG["ACT_HL2MP_RUN_FIST"] = "e";
luapad._sG["ACT_DOD_HS_IDLE_STICKGRENADE"] = "e";
luapad._sG["ACT_HL2MP_SIT_SLAM"] = "e";
luapad._sG["ACT_DOD_HS_IDLE_30CAL"] = "e";
luapad._sG["ACT_BUSY_SIT_CHAIR_ENTRY"] = "e";
luapad._sG["ACT_DOD_ZOOMLOAD_BAZOOKA"] = "e";
luapad._sG["ACT_HL2MP_SIT_MELEE"] = "e";
luapad._sG["ACT_RUN_CROUCH_AIM_RIFLE"] = "e";
luapad._sG["MASK_SOLID_BRUSHONLY"] = "e";
luapad._sG["ACT_180_LEFT"] = "e";
luapad._sG["ACT_HL2MP_SIT_SHOTGUN"] = "e";
luapad._sG["ACT_HL2MP_SIT_PISTOL"] = "e";
luapad._sG["ACT_DOD_PRONE_AIM_GREASE"] = "e";
luapad._sG["ACT_ITEM_DROP"] = "e";
luapad._sG["KEY_BACKSLASH"] = "e";
luapad._sG["ACT_GESTURE_FLINCH_LEFTARM"] = "e";
luapad._sG["ACT_RANGE_ATTACK_SHOTGUN_LOW"] = "e";
luapad._sG["ACT_IDLE"] = "e";
luapad._sG["ACT_VM_IDLE_DEPLOYED_6"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK_DEPLOYED_3"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_HANDMOUTH_PDA"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_NODYES_BUILDING"] = "e";
luapad._sG["LAST_VISIBLE_CONTENTS"] = "e";
luapad._sG["CONTENTS_DEBRIS"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_HANDMOUTH_MELEE"] = "e";
luapad._sG["JOYSTICK_FIRST_AXIS_BUTTON"] = "e";
luapad._sG["ACT_OVERLAY_SHIELD_UP_IDLE"] = "e";
luapad._sG["ACT_GESTURE_RANGE_ATTACK1_LOW"] = "e";
luapad._sG["ACT_CROUCHING_SHIELD_UP_IDLE"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_THUMBSUP_SECONDARY"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_FISTPUMP_SECONDARY"] = "e";
luapad._sG["COLLISION_GROUP_NPC_ACTOR"] = "e";
luapad._sG["CAP_MOVE_GROUND"] = "e";
luapad._sG["ACT_RUN_RPG"] = "e";
luapad._sG["ACT_WALK_RIFLE_RELAXED"] = "e";
luapad._sG["ACT_DOD_HS_IDLE_KNIFE"] = "e";
luapad._sG["MOVETYPE_CUSTOM"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_BAZOOKA"] = "e";
luapad._sG["ACT_MP_ATTACK_STAND_PDA"] = "e";
luapad._sG["ACT_GESTURE_FLINCH_BLAST"] = "e";
luapad._sG["ACT_MP_JUMP_START"] = "e";
luapad._sG["ACT_MP_SWIM_PDA"] = "e";
luapad._sG["ACT_DOD_RELOAD_DEPLOYED_BAR"] = "e";
luapad._sG["ACT_MP_CROUCH_DEPLOYED_IDLE"] = "e";
luapad._sG["CAP_USE"] = "e";
luapad._sG["ACT_TRIPMINE_GROUND"] = "e";
luapad._sG["KEY_F1"] = "e";
luapad._sG["KEY_XSTICK1_RIGHT"] = "e";
luapad._sG["SCHED_ALERT_STAND"] = "e";
luapad._sG["ACT_RUN_CROUCH_RIFLE"] = "e";
luapad._sG["IN_ZOOM"] = "e";
luapad._sG["LAST_SHARED_SCHEDULE"] = "e";
luapad._sG["ACT_MP_ATTACK_CROUCH_GRENADE_BUILDING"] = "e";
luapad._sG["ACT_MP_ATTACK_CROUCH_BUILDING"] = "e";
luapad._sG["ACT_DOD_HS_IDLE_PISTOL"] = "e";
luapad._sG["ACT_MP_ATTACK_STAND_BUILDING"] = "e";
luapad._sG["MAT_DIRT"] = "e";
luapad._sG["SIM_LOCAL_FORCE"] = "e";
luapad._sG["COLLISION_GROUP_PUSHAWAY"] = "e";
luapad._sG["ACT_WALK_AIM_SHOTGUN"] = "e";
luapad._sG["MOVETYPE_VPHYSICS"] = "e";
luapad._sG["ACT_MP_AIRWALK_BUILDING"] = "e";
luapad._sG["ACT_MP_WALK_BUILDING"] = "e";
luapad._sG["ACT_MP_MELEE_GRENADE2_ATTACK"] = "e";
luapad._sG["ACT_DOD_PRONE_ZOOMED"] = "e";
luapad._sG["ACT_SLAM_STICKWALL_DETONATOR_HOLSTER"] = "e";
luapad._sG["ACT_GESTURE_FLINCH_BLAST_DAMAGED"] = "e";
luapad._sG["DIRECTIONAL_USE"] = "e";
luapad._sG["HITGROUP_STOMACH"] = "e";
luapad._sG["KEY_NUMLOCKTOGGLE"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_THUMBSUP_MELEE"] = "e";
luapad._sG["ACT_LOOKBACK_LEFT"] = "e";
luapad._sG["STEPSOUNDTIME_ON_LADDER"] = "e";
luapad._sG["KEY_Q"] = "e";
luapad._sG["DMG_AIRBOAT"] = "e";
luapad._sG["KEY_R"] = "e";
luapad._sG["ACT_DIE_FRONTSIDE"] = "e";
luapad._sG["ACT_MP_SWIM_PRIMARY"] = "e";
luapad._sG["ACT_WALK_AIM_STEALTH_PISTOL"] = "e";
luapad._sG["ACT_MP_GESTURE_FLINCH_LEFTLEG"] = "e";
luapad._sG["ACT_SLAM_STICKWALL_DETONATE"] = "e";
luapad._sG["ACT_MP_GESTURE_FLINCH_RIGHTARM"] = "e";
luapad._sG["ACT_DOD_WALK_AIM_MG"] = "e";
luapad._sG["ACT_VM_RELOAD_DEPLOYED"] = "e";
luapad._sG["ACT_MP_GESTURE_FLINCH_PRIMARY"] = "e";
luapad._sG["ACT_DOD_WALK_AIM_RIFLE"] = "e";
luapad._sG["ACT_DOD_PRONE_AIM_MG"] = "e";
luapad._sG["ACT_MP_ATTACK_STAND_MELEE_SECONDARY"] = "e";
luapad._sG["ACT_DOD_RELOAD_CROUCH_MP40"] = "e";
luapad._sG["KEY_F2"] = "e";
luapad._sG["ACT_MP_CROUCHWALK_MELEE"] = "e";
luapad._sG["ACT_MP_CROUCH_MELEE"] = "e";
luapad._sG["ACT_MP_GESTURE_VC_FINGERPOINT_SECONDARY"] = "e";
luapad._sG["ACT_MP_STAND_MELEE"] = "e";
luapad._sG["ACT_DOD_SPRINT_IDLE_30CAL"] = "e";
luapad._sG["ACT_DOD_STAND_IDLE_RIFLE"] = "e";
luapad._sG["USE_OFF"] = "e";
luapad._sG["MAT_PLASTIC"] = "e";
luapad._sG["ACT_VM_IDLE_DEPLOYED_8"] = "e";
luapad._sG["ACT_TURNLEFT45"] = "e";
luapad._sG["ACT_SLAM_STICKWALL_ATTACH2"] = "e";
luapad._sG["ACT_DOD_WALK_IDLE_30CAL"] = "e";
luapad._sG["ACT_MP_RELOAD_STAND_SECONDARY_END"] = "e";
luapad._sG["ACT_VM_FIZZLE"] = "e";
luapad._sG["ACT_MP_RELOAD_SWIM_PRIMARY_END"] = "e";
luapad._sG["ACT_SPRINT"] = "e";
luapad._sG["COLLISION_GROUP_BREAKABLE_GLASS"] = "e";
luapad._sG["ACT_VM_SWINGHARD"] = "e";
luapad._sG["ACT_MP_ATTACK_AIRWALK_PRIMARY"] = "e";
luapad._sG["ACT_DOD_RUN_AIM_GREN_FRAG"] = "e";
luapad._sG["KEY_PAD_2"] = "e";
luapad._sG["DMG_CLUB"] = "e";
luapad._sG["KEY_COUNT"] = "e";
luapad._sG["SCHED_WAKE_ANGRY"] = "e";
luapad._sG["IN_GRENADE2"] = "e";
luapad._sG["SOLID_OBB"] = "e";
luapad._sG["ACT_MP_ATTACK_CROUCH_PRIMARYFIRE"] = "e";
luapad._sG["ACT_CROUCHIDLE"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_DEPLOYED_30CAL"] = "e";
luapad._sG["ACT_HL2MP_SIT_CROSSBOW"] = "e";
luapad._sG["KEY_XBUTTON_BACK"] = "e";
luapad._sG["ACT_MP_CROUCHWALK_PRIMARY"] = "e";
luapad._sG["SOLID_BBOX"] = "e";
luapad._sG["ACT_DOD_STAND_AIM_MP44"] = "e";
luapad._sG["KEY_XSTICK2_LEFT"] = "e";
luapad._sG["ACT_HL2MP_SIT"] = "e";
luapad._sG["ACT_DOD_WALK_ZOOM_BAZOOKA"] = "e";
luapad._sG["MOVETYPE_STEP"] = "e";
luapad._sG["ACT_MP_GESTURE_FLINCH_HEAD"] = "e";
luapad._sG["DMG_SONIC"] = "e";
luapad._sG["ACT_VM_FIDGET"] = "e";
luapad._sG["ACT_MP_RELOAD_CROUCH_LOOP"] = "e";
luapad._sG["ACT_MP_RELOAD_STAND_LOOP"] = "e";
luapad._sG["ACT_DOD_RUN_AIM_PISTOL"] = "e";
luapad._sG["ACT_MP_JUMP_FLOAT_SECONDARY"] = "e";
luapad._sG["ACT_FLINCH_LEFTARM"] = "e";
luapad._sG["ACT_MP_GRENADE1_ATTACK"] = "e";
luapad._sG["ACT_MP_DEPLOYED"] = "e";
luapad._sG["FCVAR_NEVER_AS_STRING"] = "e";
luapad._sG["ACT_VM_USABLE_TO_UNUSABLE"] = "e";
luapad._sG["ACT_DOD_WALK_IDLE_BAZOOKA"] = "e";
luapad._sG["ACT_VM_HITCENTER2"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK_3"] = "e";
luapad._sG["FCVAR_CLIENTDLL"] = "e";
luapad._sG["ACT_JUMP"] = "e";
luapad._sG["KEY_XSTICK2_UP"] = "e";
luapad._sG["ACT_RUN_RPG_RELAXED"] = "e";
luapad._sG["ACT_HL2MP_RUN_MELEE2"] = "e";
luapad._sG["ACT_SLAM_THROW_THROW2"] = "e";
luapad._sG["BOX_LEFT"] = "e";
luapad._sG["IN_FORWARD"] = "e";
luapad._sG["ACT_GESTURE_BARNACLE_STRANGLE"] = "e";
luapad._sG["CONTENTS_CURRENT_UP"] = "e";
luapad._sG["CONTENTS_CURRENT_DOWN"] = "e";
luapad._sG["ACT_HOVER"] = "e";
luapad._sG["ACT_HL2MP_JUMP_MELEE"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_DEPLOYED_BAR"] = "e";
luapad._sG["ACT_HL2MP_RUN_MELEE"] = "e";
luapad._sG["ACT_HL2MP_JUMP_CROSSBOW"] = "e";
luapad._sG["KEY_APP"] = "e";
luapad._sG["ACT_DOD_CROUCH_IDLE_PISTOL"] = "e";
luapad._sG["CAP_OPEN_DOORS"] = "e";
luapad._sG["ACT_RUN_AIM_PISTOL"] = "e";
luapad._sG["MAT_COMPUTER"] = "e";
luapad._sG["ACT_HL2MP_IDLE_PHYSGUN"] = "e";
luapad._sG["ACT_HL2MP_IDLE_SLAM"] = "e";
luapad._sG["ACT_HL2MP_RUN_GRENADE"] = "e";
luapad._sG["ACT_RUN_RIFLE_STIMULATED"] = "e";
luapad._sG["CLASS_NONE"] = "e";
luapad._sG["CONTENTS_AUX"] = "e";
luapad._sG["ACT_MP_GESTURE_FLINCH_LEFTARM"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_PRONE_C96"] = "e";
luapad._sG["ACT_HL2MP_WALK_CROUCH_SHOTGUN"] = "e";
luapad._sG["ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2"] = "e";
luapad._sG["ACT_GESTURE_RANGE_ATTACK_THROW"] = "e";
luapad._sG["ACT_DEPLOY_IDLE"] = "e";
luapad._sG["ACT_GESTURE_FLINCH_BLAST_SHOTGUN"] = "e";
luapad._sG["KEY_XBUTTON_RTRIGGER"] = "e";
luapad._sG["SCHED_FORCED_GO_RUN"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_MP40"] = "e";
luapad._sG["ACT_SLAM_THROW_IDLE"] = "e";
luapad._sG["ACT_IDLE_RPG_RELAXED"] = "e";
luapad._sG["ACT_DOD_HS_CROUCH_MG42"] = "e";
luapad._sG["ACT_SLAM_DETONATOR_STICKWALL_DRAW"] = "e";
luapad._sG["ACT_HL2MP_IDLE_FIST"] = "e";
luapad._sG["ACT_DOD_CROUCH_IDLE_GREASE"] = "e";
luapad._sG["ACT_DOD_WALK_IDLE_BAR"] = "e";
luapad._sG["ACT_DOD_SECONDARYATTACK_CROUCH"] = "e";
luapad._sG["ACT_DOD_CROUCH_IDLE_RIFLE"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_GREASEGUN"] = "e";
luapad._sG["SIM_GLOBAL_ACCELERATION"] = "e";
luapad._sG["ACT_HL2MP_WALK_CROUCH_KNIFE"] = "e";
luapad._sG["ACT_GESTURE_RANGE_ATTACK_AR2"] = "e";
luapad._sG["ACT_PHYSCANNON_ANIMATE"] = "e";
luapad._sG["ACT_DOD_RUN_AIM_PSCHRECK"] = "e";
luapad._sG["KEY_F8"] = "e";
luapad._sG["ACT_GESTURE_TURN_LEFT"] = "e";
luapad._sG["ACT_VM_IDLE_DEPLOYED_1"] = "e";
luapad._sG["ACT_BUSY_LEAN_LEFT"] = "e";
luapad._sG["MASK_WATER"] = "e";
luapad._sG["ACT_DOD_PRIMARYATTACK_TOMMY"] = "e";
luapad._sG["DMG_POISON"] = "e";
luapad._sG["ACT_DOD_PRONE_ZOOM_RIFLE"] = "e";
luapad._sG["SF_ROLLERMINE_FRIENDLY"] = "e";
luapad._sG["ACT_MP_JUMP_FLOAT_BUILDING"] = "e";
luapad._sG["KEY_DOWN"] = "e";
luapad._sG["KEY_LAST"] = "e";
luapad._sG["HITGROUP_GENERIC"] = "e";
luapad._sG["ACT_DOD_CROUCH_AIM_SPADE"] = "e";
luapad._sG["ACT_DOD_WALK_AIM_KNIFE"] = "e";
luapad._sG["ACT_RUN_SCARED"] = "e";
luapad._sG["ACT_DOD_STAND_AIM_GREN_STICK"] = "e";
luapad._sG["DIR_FORWARD"] = "e";
luapad._sG["ACT_SLAM_STICKWALL_TO_THROW"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_AIM_30CAL"] = "e";
luapad._sG["SOLID_OBB_YAW"] = "e";
luapad._sG["ACT_GESTURE_TURN_RIGHT90_FLAT"] = "e";
luapad._sG["ACT_DOD_CROUCH_AIM_MG"] = "e";
luapad._sG["ACT_RANGE_ATTACK2_LOW"] = "e";
luapad._sG["ACT_WALK_AIM_PISTOL"] = "e";
luapad._sG["ACT_DOD_RUN_AIM_GREASE"] = "e";
luapad._sG["ACT_DOD_PRONEWALK_IDLE_MP44"] = "e";
luapad._sG["ACT_SLAM_STICKWALL_IDLE"] = "e";
luapad._sG["ACT_DOD_WALK_IDLE_MP40"] = "e";
luapad._sG["CONTENTS_ORIGIN"] = "e";
luapad._sG["ACT_VM_RECOIL1"] = "e";
luapad._sG["ACT_DOD_CROUCH_IDLE_BOLT"] = "e";
luapad._sG["ACT_DOD_CROUCH_AIM_30CAL"] = "e";
luapad._sG["ACT_DOD_STAND_AIM_BOLT"] = "e";
luapad._sG["ACT_DOD_CROUCHWALK_IDLE_RIFLE"] = "e";
luapad._sG["ACT_SLAM_STICKWALL_ATTACH"] = "e";
luapad._sG["KEY_SCROLLLOCKTOGGLE"] = "e";
luapad._sG["ACT_RUN_AIM_RELAXED"] = "e";
luapad._sG["ACT_IDLE_SHOTGUN_STIMULATED"] = "e";
luapad._sG["ACT_DOD_RUN_IDLE_C96"] = "e";
luapad._sG["ACT_DOD_RELOAD_PRONE_GARAND"] = "e";
luapad._sG["ACT_DOD_RUN_AIM_C96"] = "e";
luapad._sG["ACT_MP_RELOAD_AIRWALK_PRIMARY"] = "e";
luapad._sG["ACT_DOD_PRONE_AIM_PISTOL"] = "e";
luapad._sG["JOYSTICK_FIRST_POV_BUTTON"] = "e";
luapad._sG["CLASS_HACKED_ROLLERMINE"] = "e";
luapad._sG["KEY_PAD_5"] = "e";
luapad._sG["ACT_VM_RELOAD_SILENCED"] = "e";
luapad._sG["ACT_FIRE_LOOP"] = "e";
luapad._sG["ACT_FLINCH_LEFTLEG"] = "e";
luapad._sG["ACT_WALK_STEALTH"] = "e";
luapad._sG["ACT_VM_HITLEFT"] = "e";
luapad._sG["ACT_VM_PRIMARYATTACK_DEPLOYED_6"] = "e";
luapad._sG["ACT_MP_JUMP_LAND_BUILDING"] = "e";
luapad._sG["KEY_3"] = "e";
luapad._sG["ACT_GRENADE_ROLL"] = "e";
luapad._sG["CONTENTS_EMPTY"] = "e";
luapad._sG["ACT_RUN_CROUCH_RPG"] = "e";
luapad._sG["SCHED_GET_HEALTHKIT"] = "e";
luapad._sG["KEY_1"] = "e";


-- Meta-tables

luapad._sG["Finished"] = "m";
luapad._sG["GetBuffer"] = "m";
luapad._sG["DownloadSize"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["Download"] = "m";
luapad._sG["GetPathTimeToGoal"] = "m";
luapad._sG["SetMovementSequence"] = "m";
luapad._sG["LostEnemySound"] = "m";
luapad._sG["NavSetRandomGoal"] = "m";
luapad._sG["__tostring"] = "m";
luapad._sG["SetNPCState"] = "m";
luapad._sG["GetAimVector"] = "m";
luapad._sG["SetExpression"] = "m";
luapad._sG["IsCurrentSchedule"] = "m";
luapad._sG["HasCondition"] = "m";
luapad._sG["TaskComplete"] = "m";
luapad._sG["GetNPCState"] = "m";
luapad._sG["IdleSound"] = "m";
luapad._sG["SetTarget"] = "m";
luapad._sG["GetExpression"] = "m";
luapad._sG["ClearSchedule"] = "m";
luapad._sG["GetTarget"] = "m";
luapad._sG["UseActBusyBehavior"] = "m";
luapad._sG["ConditionName"] = "m";
luapad._sG["ClearExpression"] = "m";
luapad._sG["SetHullSizeNormal"] = "m";
luapad._sG["GetHullType"] = "m";
luapad._sG["SetLastPosition"] = "m";
luapad._sG["SetArrivalActivity"] = "m";
luapad._sG["GetArrivalActivity"] = "m";
luapad._sG["GetEnemy"] = "m";
luapad._sG["PlayScene"] = "m";
luapad._sG["SetHullType"] = "m";
luapad._sG["CapabilitiesGet"] = "m";
luapad._sG["SetArrivalDirection"] = "m";
luapad._sG["ExitScriptedSequence"] = "m";
luapad._sG["SetSchedule"] = "m";
luapad._sG["AddRelationship"] = "m";
luapad._sG["GetActiveWeapon"] = "m";
luapad._sG["StartEngineTask"] = "m";
luapad._sG["IsNPC"] = "m";
luapad._sG["UseAssaultBehavior"] = "m";
luapad._sG["NavSetWanderGoal"] = "m";
luapad._sG["SentenceStop"] = "m";
luapad._sG["__newindex"] = "m";
luapad._sG["MaintainActivity"] = "m";
luapad._sG["TaskFail"] = "m";
luapad._sG["AddEntityRelationship"] = "m";
luapad._sG["PlaySentence"] = "m";
luapad._sG["SetMaxRouteRebuildTime"] = "m";
luapad._sG["CapabilitiesAdd"] = "m";
luapad._sG["GetPathDistanceToGoal"] = "m";
luapad._sG["IsRunningBehavior"] = "m";
luapad._sG["GetArrivalSequence"] = "m";
luapad._sG["UseLeadBehavior"] = "m";
luapad._sG["UpdateEnemyMemory"] = "m";
luapad._sG["SetArrivalSpeed"] = "m";
luapad._sG["SetEnemy"] = "m";
luapad._sG["UseFuncTankBehavior"] = "m";
luapad._sG["ClearGoal"] = "m";
luapad._sG["AlertSound"] = "m";
luapad._sG["CapabilitiesClear"] = "m";
luapad._sG["Give"] = "m";
luapad._sG["GetBlockingEntity"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["UseNoBehavior"] = "m";
luapad._sG["GetMovementActivity"] = "m";
luapad._sG["ClearCondition"] = "m";
luapad._sG["NavSetGoal"] = "m";
luapad._sG["SetArrivalDistance"] = "m";
luapad._sG["UseFollowBehavior"] = "m";
luapad._sG["RemoveMemory"] = "m";
luapad._sG["__index"] = "m";
luapad._sG["MarkEnemyAsEluded"] = "m";
luapad._sG["MoveOrder"] = "m";
luapad._sG["SetArrivalSequence"] = "m";
luapad._sG["GetShootPos"] = "m";
luapad._sG["SetCondition"] = "m";
luapad._sG["CapabilitiesRemove"] = "m";
luapad._sG["SetMovementActivity"] = "m";
luapad._sG["StopMoving"] = "m";
luapad._sG["ClearEnemyMemory"] = "m";
luapad._sG["FearSound"] = "m";
luapad._sG["TargetOrder"] = "m";
luapad._sG["RunEngineTask"] = "m";
luapad._sG["FoundEnemySound"] = "m";
luapad._sG["NavSetGoalTarget"] = "m";
luapad._sG["GetMovementSequence"] = "m";
luapad._sG["Classify"] = "m";
luapad._sG["Quaternion"] = "m";
luapad._sG["__eq"] = "m";
luapad._sG["Right"] = "m";
luapad._sG["__mul"] = "m";
luapad._sG["__index"] = "m";
luapad._sG["RotateAroundAxis"] = "m";
luapad._sG["ToDeg"] = "m";
luapad._sG["Up"] = "m";
luapad._sG["__add"] = "m";
luapad._sG["__tostring"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["__newindex"] = "m";
luapad._sG["Forward"] = "m";
luapad._sG["__sub"] = "m";
luapad._sG["ToRad"] = "m";
luapad._sG["GetName"] = "m";
luapad._sG["GetFloat"] = "m";
luapad._sG["GetInt"] = "m";
luapad._sG["GetBool"] = "m";
luapad._sG["GetString"] = "m";
luapad._sG["GetDefault"] = "m";
luapad._sG["GetHelpText"] = "m";
luapad._sG["GetModel"] = "m";
luapad._sG["SetDerive"] = "m";
luapad._sG["SetMaxHealth"] = "m";
luapad._sG["SetNetworkedBeamFloat"] = "m";
luapad._sG["GetMaxHealth"] = "m";
luapad._sG["GetNetworkedBeamFloat"] = "m";
luapad._sG["StopLoopingSound"] = "m";
luapad._sG["LookupBone"] = "m";
luapad._sG["GetParent"] = "m";
luapad._sG["SetLocalVelocity"] = "m";
luapad._sG["SetParent"] = "m";
luapad._sG["Disposition"] = "m";
luapad._sG["SetNetworkedBool"] = "m";
luapad._sG["StartMotionController"] = "m";
luapad._sG["HasSpawnFlags"] = "m";
luapad._sG["GetPhysicsObjectNum"] = "m";
luapad._sG["SetModel"] = "m";
luapad._sG["WorldToLocalAngles"] = "m";
luapad._sG["GetNetworkedBool"] = "m";
luapad._sG["SetEyeTarget"] = "m";
luapad._sG["SetFlexWeight"] = "m";
luapad._sG["GetVar"] = "m";
luapad._sG["SetNWVector"] = "m";
luapad._sG["GetFlexNum"] = "m";
luapad._sG["PhysWake"] = "m";
luapad._sG["AlignAngles"] = "m";
luapad._sG["SetVar"] = "m";
luapad._sG["GetNWVector"] = "m";
luapad._sG["RemoveCallOnRemove"] = "m";
luapad._sG["GetName"] = "m";
luapad._sG["IsWeapon"] = "m";
luapad._sG["SetUnFreezable"] = "m";
luapad._sG["SetNotSolid"] = "m";
luapad._sG["WorldToLocal"] = "m";
luapad._sG["GetRight"] = "m";
luapad._sG["GetNetworkedVector"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["Remove"] = "m";
luapad._sG["ResetSequence"] = "m";
luapad._sG["GetUnFreezable"] = "m";
luapad._sG["__index"] = "m";
luapad._sG["SetNetworkedVector"] = "m";
luapad._sG["SetGravity"] = "m";
luapad._sG["GetDerive"] = "m";
luapad._sG["DispatchTraceAttack"] = "m";
luapad._sG["StopParticles"] = "m";
luapad._sG["EyeAngles"] = "m";
luapad._sG["SetCollisionBoundsWS"] = "m";
luapad._sG["SetMaterial"] = "m";
luapad._sG["__SetColor"] = "m";
luapad._sG["TakeDamage"] = "m";
luapad._sG["GetNWAngle"] = "m";
luapad._sG["IsPlayer"] = "m";
luapad._sG["NextThink"] = "m";
luapad._sG["GetMaterial"] = "m";
luapad._sG["EmitSound"] = "m";
luapad._sG["NearestPoint"] = "m";
luapad._sG["OBBMaxs"] = "m";
luapad._sG["OBBMins"] = "m";
luapad._sG["SetLocalPos"] = "m";
luapad._sG["StopSound"] = "m";
luapad._sG["__SetMaterial"] = "m";
luapad._sG["SetKeyValue"] = "m";
luapad._sG["SetNetworkedAngle"] = "m";
luapad._sG["SetAnimation"] = "m";
luapad._sG["SetNetworkedFloat"] = "m";
luapad._sG["IsOnFire"] = "m";
luapad._sG["IsInWorld"] = "m";
luapad._sG["PointAtEntity"] = "m";
luapad._sG["StartLoopingSound"] = "m";
luapad._sG["__SetKeyValue"] = "m";
luapad._sG["EyePos"] = "m";
luapad._sG["GetNWEntity"] = "m";
luapad._sG["GetNetworkedAngle"] = "m";
luapad._sG["GetNetworkedFloat"] = "m";
luapad._sG["SetNetworkedBeamEntity"] = "m";
luapad._sG["Activate"] = "m";
luapad._sG["SetPhysConstraintObjects"] = "m";
luapad._sG["GetUp"] = "m";
luapad._sG["SetNWInt"] = "m";
luapad._sG["GetFlexScale"] = "m";
luapad._sG["SetSolid"] = "m";
luapad._sG["SetTable"] = "m";
luapad._sG["SetPhysicsAttacker"] = "m";
luapad._sG["SetFlexScale"] = "m";
luapad._sG["DeleteOnRemove"] = "m";
luapad._sG["EntIndex"] = "m";
luapad._sG["SetCollisionBounds"] = "m";
luapad._sG["GetSolid"] = "m";
luapad._sG["GetTable"] = "m";
luapad._sG["GetMoveType"] = "m";
luapad._sG["ClearPoseParameters"] = "m";
luapad._sG["WorldSpaceAABB"] = "m";
luapad._sG["__eq"] = "m";
luapad._sG["GetPhysicsObjectCount"] = "m";
luapad._sG["GetPoseParameter"] = "m";
luapad._sG["GetLocalPos"] = "m";
luapad._sG["SetPos"] = "m";
luapad._sG["SetUseType"] = "m";
luapad._sG["GibBreakClient"] = "m";
luapad._sG["SetNWBString"] = "m";
luapad._sG["PhysicsInitBox"] = "m";
luapad._sG["DropToFloor"] = "m";
luapad._sG["IsWorld"] = "m";
luapad._sG["SetNWAngle"] = "m";
luapad._sG["GibBreakServer"] = "m";
luapad._sG["ResetSequenceInfo"] = "m";
luapad._sG["SetMoveParent"] = "m";
luapad._sG["SetLocalAngles"] = "m";
luapad._sG["GetNWBInt"] = "m";
luapad._sG["VisibleVec"] = "m";
luapad._sG["__tostring"] = "m";
luapad._sG["GetColor"] = "m";
luapad._sG["GetNetworkedEntity"] = "m";
luapad._sG["SkinCount"] = "m";
luapad._sG["GetCollisionGroup"] = "m";
luapad._sG["SetBloodColor"] = "m";
luapad._sG["SetParentPhysNum"] = "m";
luapad._sG["SetModelName"] = "m";
luapad._sG["SetNetworkedEntity"] = "m";
luapad._sG["BoundingRadius"] = "m";
luapad._sG["SetCollisionGroup"] = "m";
luapad._sG["StopMotionController"] = "m";
luapad._sG["GetPhysicsObject"] = "m";
luapad._sG["GetGroundEntity"] = "m";
luapad._sG["LocalToWorldAngles"] = "m";
luapad._sG["GetAngles"] = "m";
luapad._sG["MakePhysicsObjectAShadow"] = "m";
luapad._sG["SetElasticity"] = "m";
luapad._sG["LookupAttachment"] = "m";
luapad._sG["SetShouldDrawInViewMode"] = "m";
luapad._sG["Weapon_SetActivity"] = "m";
luapad._sG["GetPhysicsAttacker"] = "m";
luapad._sG["FireBullets"] = "m";
luapad._sG["PhysicsInit"] = "m";
luapad._sG["SetNWBAngle"] = "m";
luapad._sG["SetAngles"] = "m";
luapad._sG["GetClass"] = "m";
luapad._sG["SetColor"] = "m";
luapad._sG["CallOnRemove"] = "m";
luapad._sG["SetNetworkedVarProxy"] = "m";
luapad._sG["DrawShadow"] = "m";
luapad._sG["SetNetworkedString"] = "m";
luapad._sG["GetNetworkedVar"] = "m";
luapad._sG["Respawn"] = "m";
luapad._sG["DontDeleteOnRemove"] = "m";
luapad._sG["SetAttachment"] = "m";
luapad._sG["MuzzleFlash"] = "m";
luapad._sG["GetNetworkedString"] = "m";
luapad._sG["SetBoneMatrix"] = "m";
luapad._sG["GetBloodColor"] = "m";
luapad._sG["LookupSequence"] = "m";
luapad._sG["SetNetworkedInt"] = "m";
luapad._sG["GetFlexName"] = "m";
luapad._sG["IsOnGround"] = "m";
luapad._sG["OnGround"] = "m";
luapad._sG["GetLocalAngles"] = "m";
luapad._sG["PrecacheGibs"] = "m";
luapad._sG["SetNWBInt"] = "m";
luapad._sG["GetNetworkedInt"] = "m";
luapad._sG["Visible"] = "m";
luapad._sG["IsVehicle"] = "m";
luapad._sG["SetSequence"] = "m";
luapad._sG["GetNWFloat"] = "m";
luapad._sG["SetNWFloat"] = "m";
luapad._sG["GetSequence"] = "m";
luapad._sG["SetNetworkedNumber"] = "m";
luapad._sG["GetMoveCollide"] = "m";
luapad._sG["SetNetworkedBeamVector"] = "m";
luapad._sG["SetMoveCollide"] = "m";
luapad._sG["SetTrigger"] = "m";
luapad._sG["LocalToWorld"] = "m";
luapad._sG["GetAttachment"] = "m";
luapad._sG["GetNWBString"] = "m";
luapad._sG["GetNetworkedBeamString"] = "m";
luapad._sG["SetNWBVector"] = "m";
luapad._sG["SetSolidMask"] = "m";
luapad._sG["SetHealth"] = "m";
luapad._sG["PhysicsFromMesh"] = "m";
luapad._sG["SetCycle"] = "m";
luapad._sG["SetFriction"] = "m";
luapad._sG["__concat"] = "m";
luapad._sG["SetNetworkedBeamString"] = "m";
luapad._sG["SetNWBool"] = "m";
luapad._sG["SetSkin"] = "m";
luapad._sG["GetMoveParent"] = "m";
luapad._sG["GetNetworkedBeamBool"] = "m";
luapad._sG["GetNWBVector"] = "m";
luapad._sG["GetSkin"] = "m";
luapad._sG["Extinguish"] = "m";
luapad._sG["__Fire"] = "m";
luapad._sG["IsPlayerHolding"] = "m";
luapad._sG["GetFlexWeight"] = "m";
luapad._sG["IsNPC"] = "m";
luapad._sG["SetNetworkedBeamBool"] = "m";
luapad._sG["SetPlaybackRate"] = "m";
luapad._sG["GetOwner"] = "m";
luapad._sG["GetNWBEntity"] = "m";
luapad._sG["GetNetworkedBeamEntity"] = "m";
luapad._sG["PhysicsInitShadow"] = "m";
luapad._sG["SetNWBFloat"] = "m";
luapad._sG["SetNWBEntity"] = "m";
luapad._sG["SetRenderMode"] = "m";
luapad._sG["GetParentPhysNum"] = "m";
luapad._sG["RestartGesture"] = "m";
luapad._sG["GetNWBAngle"] = "m";
luapad._sG["__newindex"] = "m";
luapad._sG["SetOwner"] = "m";
luapad._sG["TranslatePhysBoneToBone"] = "m";
luapad._sG["SetNWString"] = "m";
luapad._sG["IsValid"] = "m";
luapad._sG["GetNWBFloat"] = "m";
luapad._sG["GetNetworkedBeamAngle"] = "m";
luapad._sG["SetNWEntity"] = "m";
luapad._sG["SetGroundEntity"] = "m";
luapad._sG["Weapon_TranslateActivity"] = "m";
luapad._sG["GetBoneMatrix"] = "m";
luapad._sG["SetBodygroup"] = "m";
luapad._sG["SetNetworkedVar"] = "m";
luapad._sG["SetNoDraw"] = "m";
luapad._sG["Input"] = "m";
luapad._sG["Fire"] = "m";
luapad._sG["SelectWeightedSequence"] = "m";
luapad._sG["__SetNoDraw"] = "m";
luapad._sG["SequenceDuration"] = "m";
luapad._sG["GetDerived"] = "m";
luapad._sG["Health"] = "m";
luapad._sG["IsConstrained"] = "m";
luapad._sG["GetNWBBool"] = "m";
luapad._sG["SetNetworkedBeamAngle"] = "m";
luapad._sG["GetPos"] = "m";
luapad._sG["PhysicsInitSphere"] = "m";
luapad._sG["SetNWBBool"] = "m";
luapad._sG["GetNetworkedBeamVector"] = "m";
luapad._sG["GetActivity"] = "m";
luapad._sG["SetName"] = "m";
luapad._sG["WaterLevel"] = "m";
luapad._sG["TakePhysicsDamage"] = "m";
luapad._sG["GetNWString"] = "m";
luapad._sG["OBBCenter"] = "m";
luapad._sG["GetNWBool"] = "m";
luapad._sG["SetVelocity"] = "m";
luapad._sG["GetNWInt"] = "m";
luapad._sG["SetNetworkedBeamInt"] = "m";
luapad._sG["Ignite"] = "m";
luapad._sG["GetKeyValues"] = "m";
luapad._sG["SetEntity"] = "m";
luapad._sG["GetBonePosition"] = "m";
luapad._sG["GetBodygroup"] = "m";
luapad._sG["SetMoveType"] = "m";
luapad._sG["SetPoseParameter"] = "m";
luapad._sG["GetForward"] = "m";
luapad._sG["Spawn"] = "m";
luapad._sG["GetVelocity"] = "m";
luapad._sG["GetFlexBounds"] = "m";
luapad._sG["GetNetworkedBeamInt"] = "m";
luapad._sG["Scale"] = "m";
luapad._sG["__mul"] = "m";
luapad._sG["GetAngle"] = "m";
luapad._sG["GetTranslation"] = "m";
luapad._sG["Rotate"] = "m";
luapad._sG["Translate"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["SetTranslation"] = "m";
luapad._sG["ScaleTranslation"] = "m";
luapad._sG["GetMaxSpeed"] = "m";
luapad._sG["SetUpSpeed"] = "m";
luapad._sG["GetSideSpeed"] = "m";
luapad._sG["GetConstraintRadius"] = "m";
luapad._sG["SetForwardSpeed"] = "m";
luapad._sG["GetMoveAngles"] = "m";
luapad._sG["SetOrigin"] = "m";
luapad._sG["SetMoveAngles"] = "m";
luapad._sG["SetMaxClientSpeed"] = "m";
luapad._sG["GetUpSpeed"] = "m";
luapad._sG["SetSideSpeed"] = "m";
luapad._sG["GetForwardSpeed"] = "m";
luapad._sG["SetVelocity"] = "m";
luapad._sG["GetOrigin"] = "m";
luapad._sG["SetConstraintRadius"] = "m";
luapad._sG["GetVelocity"] = "m";
luapad._sG["SetMaxSpeed"] = "m";
luapad._sG["GetMaxClientSpeed"] = "m";
luapad._sG["GetSideMove"] = "m";
luapad._sG["KeyDown"] = "m";
luapad._sG["SetUpMove"] = "m";
luapad._sG["SetViewAngles"] = "m";
luapad._sG["SetSideMove"] = "m";
luapad._sG["SetMouseY"] = "m";
luapad._sG["GetViewAngles"] = "m";
luapad._sG["GetMouseY"] = "m";
luapad._sG["GetForwardMove"] = "m";
luapad._sG["GetMouseX"] = "m";
luapad._sG["SetForwardMove"] = "m";
luapad._sG["GetUpMove"] = "m";
luapad._sG["SetMouseX"] = "m";
luapad._sG["OnConVarChanged"] = "m";
luapad._sG["AddChangeCallback"] = "m";
luapad._sG["GetConVarCallbacks"] = "m";
luapad._sG["GetSurfaceProp"] = "m";
luapad._sG["GetAngle"] = "m";
luapad._sG["GetScale"] = "m";
luapad._sG["SetMagnitude"] = "m";
luapad._sG["GetStart"] = "m";
luapad._sG["GetNormal"] = "m";
luapad._sG["SetOrigin"] = "m";
luapad._sG["SetScale"] = "m";
luapad._sG["GetRadius"] = "m";
luapad._sG["SetStart"] = "m";
luapad._sG["GetEntity"] = "m";
luapad._sG["SetEntity"] = "m";
luapad._sG["SetAngle"] = "m";
luapad._sG["SetNormal"] = "m";
luapad._sG["GetMagnitude"] = "m";
luapad._sG["GetOrigin"] = "m";
luapad._sG["SetSurfaceProp"] = "m";
luapad._sG["SetAttachment"] = "m";
luapad._sG["SetRadius"] = "m";
luapad._sG["GetAttachment"] = "m";
luapad._sG["IsExplosionDamage"] = "m";
luapad._sG["GetReportedPosition"] = "m";
luapad._sG["GetDamageForce"] = "m";
luapad._sG["GetMaxDamage"] = "m";
luapad._sG["GetAttacker"] = "m";
luapad._sG["GetDamage"] = "m";
luapad._sG["SetDamageForce"] = "m";
luapad._sG["IsBulletDamage"] = "m";
luapad._sG["IsFallDamage"] = "m";
luapad._sG["AddDamage"] = "m";
luapad._sG["GetDamagePosition"] = "m";
luapad._sG["SetInflictor"] = "m";
luapad._sG["IsDamageType"] = "m";
luapad._sG["SetAttacker"] = "m";
luapad._sG["GetInflictor"] = "m";
luapad._sG["SetDamage"] = "m";
luapad._sG["ScaleDamage"] = "m";
luapad._sG["GetBaseDamage"] = "m";
luapad._sG["GetAmmoType"] = "m";
luapad._sG["SubtractDamage"] = "m";
luapad._sG["Sleep"] = "m";
luapad._sG["GetVolume"] = "m";
luapad._sG["GetRotDamping"] = "m";
luapad._sG["CalculateForceOffset"] = "m";
luapad._sG["GetAngle"] = "m";
luapad._sG["GetSpeedDamping"] = "m";
luapad._sG["GetEntity"] = "m";
luapad._sG["CalculateVelocityOffset"] = "m";
luapad._sG["SetAngleDragCoefficient"] = "m";
luapad._sG["AddVelocity"] = "m";
luapad._sG["GetInvInertia"] = "m";
luapad._sG["UpdateShadow"] = "m";
luapad._sG["GetInertia"] = "m";
luapad._sG["RotateAroundAxis"] = "m";
luapad._sG["GetAABB"] = "m";
luapad._sG["AlignAngles"] = "m";
luapad._sG["SetInertia"] = "m";
luapad._sG["ClearGameFlag"] = "m";
luapad._sG["AddGameFlag"] = "m";
luapad._sG["GetPos"] = "m";
luapad._sG["HasGameFlag"] = "m";
luapad._sG["GetMassCenter"] = "m";
luapad._sG["SetAngle"] = "m";
luapad._sG["ApplyForceOffset"] = "m";
luapad._sG["SetMaterial"] = "m";
luapad._sG["SetMass"] = "m";
luapad._sG["GetInvMass"] = "m";
luapad._sG["WorldToLocal"] = "m";
luapad._sG["SetBuoyancyRatio"] = "m";
luapad._sG["GetEnergy"] = "m";
luapad._sG["SetDragCoefficient"] = "m";
luapad._sG["ComputeShadowControl"] = "m";
luapad._sG["__eq"] = "m";
luapad._sG["GetMass"] = "m";
luapad._sG["AddAngleVelocity"] = "m";
luapad._sG["LocalToWorld"] = "m";
luapad._sG["GetAngles"] = "m";
luapad._sG["WorldToLocalVector"] = "m";
luapad._sG["SetPos"] = "m";
luapad._sG["__tostring"] = "m";
luapad._sG["IsPenetrating"] = "m";
luapad._sG["SetVelocity"] = "m";
luapad._sG["GetDamping"] = "m";
luapad._sG["SetVelocityInstantaneous"] = "m";
luapad._sG["ApplyForceCenter"] = "m";
luapad._sG["IsValid"] = "m";
luapad._sG["SetDamping"] = "m";
luapad._sG["IsAsleep"] = "m";
luapad._sG["EnableCollisions"] = "m";
luapad._sG["LocalToWorldVector"] = "m";
luapad._sG["Wake"] = "m";
luapad._sG["GetAngleVelocity"] = "m";
luapad._sG["IsMoveable"] = "m";
luapad._sG["GetMaterial"] = "m";
luapad._sG["OutputDebugInfo"] = "m";
luapad._sG["EnableMotion"] = "m";
luapad._sG["GetVelocity"] = "m";
luapad._sG["EnableDrag"] = "m";
luapad._sG["EnableGravity"] = "m";
luapad._sG["GetScriptedVehicle"] = "m";
luapad._sG["GetViewOffsetDucked"] = "m";
luapad._sG["CheckLimit"] = "m";
luapad._sG["__tostring"] = "m";
luapad._sG["GetAimVector"] = "m";
luapad._sG["SendHint"] = "m";
luapad._sG["CrosshairEnable"] = "m";
luapad._sG["EquipSuit"] = "m";
luapad._sG["GetEyeTraceNoCursor"] = "m";
luapad._sG["ChatPrint"] = "m";
luapad._sG["DetonateTripmines"] = "m";
luapad._sG["TraceHullAttack"] = "m";
luapad._sG["ViewPunch"] = "m";
luapad._sG["StripWeapons"] = "m";
luapad._sG["ShouldDropWeapon"] = "m";
luapad._sG["GetAmmoCount"] = "m";
luapad._sG["SendLua"] = "m";
luapad._sG["PacketLoss"] = "m";
luapad._sG["Spectate"] = "m";
luapad._sG["SetUserGroup"] = "m";
luapad._sG["DropWeapon"] = "m";
luapad._sG["Lock"] = "m";
luapad._sG["GetInfo"] = "m";
luapad._sG["PrintMessage"] = "m";
luapad._sG["SprintDisable"] = "m";
luapad._sG["SetNoTarget"] = "m";
luapad._sG["KeyPressed"] = "m";
luapad._sG["UniqueIDTable"] = "m";
luapad._sG["UniqueID"] = "m";
luapad._sG["GodDisable"] = "m";
luapad._sG["IsSuperAdmin"] = "m";
luapad._sG["SelectWeapon"] = "m";
luapad._sG["SetCanZoom"] = "m";
luapad._sG["GetName"] = "m";
luapad._sG["IsWeapon"] = "m";
luapad._sG["KeyDownLast"] = "m";
luapad._sG["IsUserGroup"] = "m";
luapad._sG["Nick"] = "m";
luapad._sG["Kill"] = "m";
luapad._sG["SprintEnable"] = "m";
luapad._sG["AllowImmediateDecalPainting"] = "m";
luapad._sG["UserID"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["GetXFire"] = "m";
luapad._sG["Team"] = "m";
luapad._sG["SetDeaths"] = "m";
luapad._sG["KeyReleased"] = "m";
luapad._sG["SetClientsideVehicle"] = "m";
luapad._sG["GetFOV"] = "m";
luapad._sG["GetShootPos"] = "m";
luapad._sG["IPAddress"] = "m";
luapad._sG["SetViewOffsetDucked"] = "m";
luapad._sG["AddDeaths"] = "m";
luapad._sG["GetAllowFullRotation"] = "m";
luapad._sG["GetCount"] = "m";
luapad._sG["GetClientsideVehicle"] = "m";
luapad._sG["Kick"] = "m";
luapad._sG["GetMaxSpeed"] = "m";
luapad._sG["IsVehicle"] = "m";
luapad._sG["SpectateEntity"] = "m";
luapad._sG["Flashlight"] = "m";
luapad._sG["SetTeam"] = "m";
luapad._sG["SuppressHint"] = "m";
luapad._sG["GetTool"] = "m";
luapad._sG["UnLock"] = "m";
luapad._sG["SetMaxSpeed"] = "m";
luapad._sG["TargetFinderUnlock"] = "m";
luapad._sG["Freeze"] = "m";
luapad._sG["IsPlayer"] = "m";
luapad._sG["GetEyeTrace"] = "m";
luapad._sG["AddCleanup"] = "m";
luapad._sG["GetCursorAimVector"] = "m";
luapad._sG["AddCount"] = "m";
luapad._sG["IsAdmin"] = "m";
luapad._sG["GetRagdollEntity"] = "m";
luapad._sG["GetAIM"] = "m";
luapad._sG["TimeConnected"] = "m";
luapad._sG["GetMSN"] = "m";
luapad._sG["GetEmail"] = "m";
luapad._sG["GetLocation"] = "m";
luapad._sG["PhysgunUnfreeze"] = "m";
luapad._sG["Alive"] = "m";
luapad._sG["SetHullDuck"] = "m";
luapad._sG["LagCompensation"] = "m";
luapad._sG["SetEyeAngles"] = "m";
luapad._sG["IsBot"] = "m";
luapad._sG["TargetFinderLock"] = "m";
luapad._sG["ResetHull"] = "m";
luapad._sG["SetViewOffset"] = "m";
luapad._sG["CreateSharedTable"] = "m";
luapad._sG["DrawWorldModel"] = "m";
luapad._sG["SendData"] = "m";
luapad._sG["SetSuppressPickupNotices"] = "m";
luapad._sG["DropNamedWeapon"] = "m";
luapad._sG["SetDuckSpeed"] = "m";
luapad._sG["SetRunSpeed"] = "m";
luapad._sG["SetAllowFullRotation"] = "m";
luapad._sG["StripWeapon"] = "m";
luapad._sG["KeyDown"] = "m";
luapad._sG["Ping"] = "m";
luapad._sG["GetCanZoom"] = "m";
luapad._sG["SetCrouchedWalkSpeed"] = "m";
luapad._sG["EnterVehicle"] = "m";
luapad._sG["GetWeapon"] = "m";
luapad._sG["SteamID"] = "m";
luapad._sG["GetViewModel"] = "m";
luapad._sG["AddFrozenPhysicsObject"] = "m";
luapad._sG["SetScriptedVehicle"] = "m";
luapad._sG["SetFrags"] = "m";
luapad._sG["SetDSP"] = "m";
luapad._sG["GiveAmmo"] = "m";
luapad._sG["GetObserverTarget"] = "m";
luapad._sG["GetGTalk"] = "m";
luapad._sG["SetPData"] = "m";
luapad._sG["GetPData"] = "m";
luapad._sG["IsNPC"] = "m";
luapad._sG["GetVehicle"] = "m";
luapad._sG["ConCommand"] = "m";
luapad._sG["GetSharedTable"] = "m";
luapad._sG["GetViewOffset"] = "m";
luapad._sG["GetNoCollideWithTeammates"] = "m";
luapad._sG["GetCurrentCommand"] = "m";
luapad._sG["GetJumpPower"] = "m";
luapad._sG["__newindex"] = "m";
luapad._sG["SetCanWalk"] = "m";
luapad._sG["GetCanWalk"] = "m";
luapad._sG["Name"] = "m";
luapad._sG["FlashlightIsOn"] = "m";
luapad._sG["RemoveAmmo"] = "m";
luapad._sG["Crouching"] = "m";
luapad._sG["DebugInfo"] = "m";
luapad._sG["Deaths"] = "m";
luapad._sG["DrawViewModel"] = "m";
luapad._sG["StopZooming"] = "m";
luapad._sG["HasWeapon"] = "m";
luapad._sG["AddFrags"] = "m";
luapad._sG["GetInfoNum"] = "m";
luapad._sG["__index"] = "m";
luapad._sG["Frags"] = "m";
luapad._sG["SetAmmo"] = "m";
luapad._sG["GetWebsite"] = "m";
luapad._sG["SetWalkSpeed"] = "m";
luapad._sG["GetAvoidPlayers"] = "m";
luapad._sG["StripAmmo"] = "m";
luapad._sG["SetJumpPower"] = "m";
luapad._sG["SetAvoidPlayers"] = "m";
luapad._sG["SetNoCollideWithTeammates"] = "m";
luapad._sG["CrosshairDisable"] = "m";
luapad._sG["KillSilent"] = "m";
luapad._sG["SetViewEntity"] = "m";
luapad._sG["SetArmor"] = "m";
luapad._sG["PlayStepSound"] = "m";
luapad._sG["Ban"] = "m";
luapad._sG["IsListenServerHost"] = "m";
luapad._sG["LimitHit"] = "m";
luapad._sG["SetUnDuckSpeed"] = "m";
luapad._sG["Give"] = "m";
luapad._sG["InVehicle"] = "m";
luapad._sG["Armor"] = "m";
luapad._sG["GetStepSize"] = "m";
luapad._sG["SetHull"] = "m";
luapad._sG["RemoveAllAmmo"] = "m";
luapad._sG["IsFrozen"] = "m";
luapad._sG["SetStepSize"] = "m";
luapad._sG["LastHitGroup"] = "m";
luapad._sG["ExitVehicle"] = "m";
luapad._sG["UnfreezePhysicsObjects"] = "m";
luapad._sG["IsLockedOnto"] = "m";
luapad._sG["GetWeapons"] = "m";
luapad._sG["GetViewEntity"] = "m";
luapad._sG["GodEnable"] = "m";
luapad._sG["GetActiveWeapon"] = "m";
luapad._sG["SetFOV"] = "m";
luapad._sG["IsConnected"] = "m";
luapad._sG["UnSpectate"] = "m";
luapad._sG["SnapEyeAngles"] = "m";
luapad._sG["GetObserverMode"] = "m";
luapad._sG["CreateRagdoll"] = "m";
luapad._sG["OnConVarChanged"] = "m";
luapad._sG["AddChangeCallback"] = "m";
luapad._sG["GetConVarCallbacks"] = "m";
luapad._sG["AddAllPlayers"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["AddPVS"] = "m";
luapad._sG["RemovePlayer"] = "m";
luapad._sG["AddPlayer"] = "m";
luapad._sG["RemovePVS"] = "m";
luapad._sG["RemoveAllPlayers"] = "m";
luapad._sG["WriteVector"] = "m";
luapad._sG["StartBlock"] = "m";
luapad._sG["WriteInt"] = "m";
luapad._sG["WriteAngle"] = "m";
luapad._sG["WriteEntity"] = "m";
luapad._sG["EndBlock"] = "m";
luapad._sG["WriteFloat"] = "m";
luapad._sG["WriteBool"] = "m";
luapad._sG["WriteString"] = "m";
luapad._sG["ReadString"] = "m";
luapad._sG["ReadInt"] = "m";
luapad._sG["ReadEntity"] = "m";
luapad._sG["ReadVector"] = "m";
luapad._sG["ReadAngle"] = "m";
luapad._sG["EndBlock"] = "m";
luapad._sG["ReadFloat"] = "m";
luapad._sG["StartBlock"] = "m";
luapad._sG["ReadBool"] = "m";
luapad._sG["SetPos"] = "m";
luapad._sG["__newindex"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["__index"] = "m";
luapad._sG["ChangeVolume"] = "m";
luapad._sG["ChangePitch"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["SetSoundLevel"] = "m";
luapad._sG["Stop"] = "m";
luapad._sG["Play"] = "m";
luapad._sG["IsPlaying"] = "m";
luapad._sG["PlayEx"] = "m";
luapad._sG["FadeOut"] = "m";
luapad._sG["OnConVarChanged"] = "m";
luapad._sG["AddChangeCallback"] = "m";
luapad._sG["GetConVarCallbacks"] = "m";
luapad._sG["__eq"] = "m";
luapad._sG["__tostring"] = "m";
luapad._sG["Normalize"] = "m";
luapad._sG["Dot"] = "m";
luapad._sG["Length"] = "m";
luapad._sG["__index"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["Sub"] = "m";
luapad._sG["Angle"] = "m";
luapad._sG["DotProduct"] = "m";
luapad._sG["Distance"] = "m";
luapad._sG["__mul"] = "m";
luapad._sG["GetNormalized"] = "m";
luapad._sG["GetNormal"] = "m";
luapad._sG["__add"] = "m";
luapad._sG["Mul"] = "m";
luapad._sG["__div"] = "m";
luapad._sG["Cross"] = "m";
luapad._sG["__newindex"] = "m";
luapad._sG["Rotate"] = "m";
luapad._sG["__sub"] = "m";
luapad._sG["Add"] = "m";
luapad._sG["GetPassenger"] = "m";
luapad._sG["GetDriver"] = "m";
luapad._sG["__tostring"] = "m";
luapad._sG["__newindex"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["__index"] = "m";
luapad._sG["IsVehicle"] = "m";
luapad._sG["IsNPC"] = "m";
luapad._sG["SendWeaponAnim"] = "m";
luapad._sG["Clip2"] = "m";
luapad._sG["SetClip1"] = "m";
luapad._sG["GetSecondaryAmmoType"] = "m";
luapad._sG["__newindex"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["__index"] = "m";
luapad._sG["IsWeaponVisible"] = "m";
luapad._sG["IsPlayer"] = "m";
luapad._sG["CallOnClient"] = "m";
luapad._sG["LastShootTime"] = "m";
luapad._sG["__tostring"] = "m";
luapad._sG["IsVehicle"] = "m";
luapad._sG["GetActivity"] = "m";
luapad._sG["SetNextPrimaryFire"] = "m";
luapad._sG["Clip1"] = "m";
luapad._sG["SetNextSecondaryFire"] = "m";
luapad._sG["IsWeapon"] = "m";
luapad._sG["DefaultReload"] = "m";
luapad._sG["GetPrimaryAmmoType"] = "m";
luapad._sG["SetClip2"] = "m";
luapad._sG["OnConVarChanged"] = "m";
luapad._sG["AddChangeCallback"] = "m";
luapad._sG["GetConVarCallbacks"] = "m";
luapad._sG["OnConVarChanged"] = "m";
luapad._sG["AddChangeCallback"] = "m";
luapad._sG["GetConVarCallbacks"] = "m";
luapad._sG["OnConVarChanged"] = "m";
luapad._sG["AddChangeCallback"] = "m";
luapad._sG["GetConVarCallbacks"] = "m";
luapad._sG["Call"] = "m";
luapad._sG["Register"] = "m";
luapad._sG["Get"] = "m";
luapad._sG["OnConVarChanged"] = "m";
luapad._sG["AddChangeCallback"] = "m";
luapad._sG["GetConVarCallbacks"] = "m";
luapad._sG["OnConVarChanged"] = "m";
luapad._sG["AddChangeCallback"] = "m";
luapad._sG["GetConVarCallbacks"] = "m";
luapad._sG["ShouldDropOnDie"] = "m";
luapad._sG["SetWeaponHoldType"] = "m";
luapad._sG["GetNPCMinRest"] = "m";
luapad._sG["AcceptInput"] = "m";
luapad._sG["Deploy"] = "m";
luapad._sG["SetNPCMaxBurst"] = "m";
luapad._sG["Ammo1"] = "m";
luapad._sG["CanSecondaryAttack"] = "m";
luapad._sG["GetNPCMinBurst"] = "m";
luapad._sG["TakeSecondaryAmmo"] = "m";
luapad._sG["TakePrimaryAmmo"] = "m";
luapad._sG["OnRemove"] = "m";
luapad._sG["ShootEffects"] = "m";
luapad._sG["SecondaryAttack"] = "m";
luapad._sG["Reload"] = "m";
luapad._sG["OnDrop"] = "m";
luapad._sG["Precache"] = "m";
luapad._sG["Equip"] = "m";
luapad._sG["NPCShoot_Secondary"] = "m";
luapad._sG["Holster"] = "m";
luapad._sG["OwnerChanged"] = "m";
luapad._sG["GetCapabilities"] = "m";
luapad._sG["Ammo2"] = "m";
luapad._sG["SetNPCMinBurst"] = "m";
luapad._sG["KeyValue"] = "m";
luapad._sG["DoRotateThink"] = "m";
luapad._sG["DoZoomThink"] = "m";
luapad._sG["SetNPCFireRate"] = "m";
luapad._sG["PrimaryAttack"] = "m";
luapad._sG["SetDeploySpeed"] = "m";
luapad._sG["Think"] = "m";
luapad._sG["CanPrimaryAttack"] = "m";
luapad._sG["SetNPCMaxRest"] = "m";
luapad._sG["GetNPCMaxRest"] = "m";
luapad._sG["NPCShoot_Primary"] = "m";
luapad._sG["TranslateActivity"] = "m";
luapad._sG["Initialize"] = "m";
luapad._sG["EquipAmmo"] = "m";
luapad._sG["SetNPCMinRest"] = "m";
luapad._sG["CheckReload"] = "m";
luapad._sG["GetNPCMaxBurst"] = "m";
luapad._sG["SetupWeaponHoldTypeForAI"] = "m";
luapad._sG["OnRestore"] = "m";
luapad._sG["ShootBullet"] = "m";
luapad._sG["ContextScreenClick"] = "m";
luapad._sG["GetNPCFireRate"] = "m";
luapad._sG["DoShootEffect"] = "m";
luapad._sG["OnConVarChanged"] = "m";
luapad._sG["AddChangeCallback"] = "m";
luapad._sG["GetConVarCallbacks"] = "m";
luapad._sG["OnConVarChanged"] = "m";
luapad._sG["AddChangeCallback"] = "m";
luapad._sG["GetConVarCallbacks"] = "m";
luapad._sG["OnConVarChanged"] = "m";
luapad._sG["AddChangeCallback"] = "m";
luapad._sG["GetConVarCallbacks"] = "m";
luapad._sG["OnConVarChanged"] = "m";
luapad._sG["AddChangeCallback"] = "m";
luapad._sG["GetConVarCallbacks"] = "m";
luapad._sG["PlayerTraceAttack"] = "m";
luapad._sG["CanPlayerUnfreeze"] = "m";
luapad._sG["PlayerSpawnedRagdoll"] = "m";
luapad._sG["PlayerUnfrozeObject"] = "m";
luapad._sG["PlayerFootstep"] = "m";
luapad._sG["PlayerSpawnVehicle"] = "m";
luapad._sG["KeyRelease"] = "m";
luapad._sG["PlayerAuthed"] = "m";
luapad._sG["EntityTakeDamage"] = "m";
luapad._sG["PlayerInitialSpawn"] = "m";
luapad._sG["PlayerSetModel"] = "m";
luapad._sG["PlayerCanJoinTeam"] = "m";
luapad._sG["Restored"] = "m";
luapad._sG["OnPhysgunReload"] = "m";
luapad._sG["PlayerSwitchFlashlight"] = "m";
luapad._sG["CreateTeams"] = "m";
luapad._sG["PlayerSpawnedEffect"] = "m";
luapad._sG["ContextScreenClick"] = "m";
luapad._sG["Saved"] = "m";
luapad._sG["PlayerSpawnRagdoll"] = "m";
luapad._sG["CanTool"] = "m";
luapad._sG["SetPlayerAnimation"] = "m";
luapad._sG["PlayerSelectTeamSpawn"] = "m";
luapad._sG["PlayerFrozeObject"] = "m";
luapad._sG["PlayerHurt"] = "m";
luapad._sG["PlayerLoadout"] = "m";
luapad._sG["WeaponEquip"] = "m";
luapad._sG["PlayerSpawnEffect"] = "m";
luapad._sG["PlayerSpawnProp"] = "m";
luapad._sG["PlayerSpawn"] = "m";
luapad._sG["CanRender"] = "m";
luapad._sG["GravGunOnDropped"] = "m";
luapad._sG["PlayerNoClip"] = "m";
luapad._sG["PlayerDeathThink"] = "m";
luapad._sG["PlayerSpawnAsSpectator"] = "m";
luapad._sG["Move"] = "m";
luapad._sG["FinishMove"] = "m";
luapad._sG["CanPlayerEnterVehicle"] = "m";
luapad._sG["CanPlayerSuicide"] = "m";
luapad._sG["PlayerStepSoundTime"] = "m";
luapad._sG["PlayerCanHearPlayersVoice"] = "m";
luapad._sG["SetupMove"] = "m";
luapad._sG["PlayerConnect"] = "m";
luapad._sG["IsSpawnpointSuitable"] = "m";
luapad._sG["OnPlayerChat"] = "m";
luapad._sG["InitPostEntity"] = "m";
luapad._sG["PlayerDeath"] = "m";
luapad._sG["PlayerSpawnSWEP"] = "m";
luapad._sG["PlayerSelectSpawn"] = "m";
luapad._sG["PhysgunPickup"] = "m";
luapad._sG["ShouldCollide"] = "m";
luapad._sG["PlayerSay"] = "m";
luapad._sG["PlayerCanPickupWeapon"] = "m";
luapad._sG["UpdateAnimation"] = "m";
luapad._sG["PlayerEnteredVehicle"] = "m";
luapad._sG["OnDamagedByExplosion"] = "m";
luapad._sG["EntityRemoved"] = "m";
luapad._sG["PlayerSpawnedSENT"] = "m";
luapad._sG["KeyPress"] = "m";
luapad._sG["ShutDown"] = "m";
luapad._sG["GravGunPickupAllowed"] = "m";
luapad._sG["GravGunOnPickedUp"] = "m";
luapad._sG["PlayerSpawnedProp"] = "m";
luapad._sG["SetupPlayerVisibility"] = "m";
luapad._sG["OnPlayerChangedTeam"] = "m";
luapad._sG["PlayerDisconnected"] = "m";
luapad._sG["DoPlayerDeath"] = "m";
luapad._sG["OnPhysgunFreeze"] = "m";
luapad._sG["OnPlayerHitGround"] = "m";
luapad._sG["PlayerGiveSWEP"] = "m";
luapad._sG["PlayerSpawnSENT"] = "m";
luapad._sG["CanExitVehicle"] = "m";
luapad._sG["Initialize"] = "m";
luapad._sG["PlayerUse"] = "m";
luapad._sG["ScalePlayerDamage"] = "m";
luapad._sG["OnEntityCreated"] = "m";
luapad._sG["PlayerLeaveVehicle"] = "m";
luapad._sG["CanPose"] = "m";
luapad._sG["PlayerSpray"] = "m";
luapad._sG["PlayerJoinTeam"] = "m";
luapad._sG["PlayerCanSeePlayersChat"] = "m";
luapad._sG["GetGameDescription"] = "m";
luapad._sG["OnNPCKilled"] = "m";
luapad._sG["ScaleNPCDamage"] = "m";
luapad._sG["ShowTeam"] = "m";
luapad._sG["CreateEntityRagdoll"] = "m";
luapad._sG["Think"] = "m";
luapad._sG["Tick"] = "m";
luapad._sG["PlayerSilentDeath"] = "m";
luapad._sG["PropBreak"] = "m";
luapad._sG["CanConstruct"] = "m";
luapad._sG["EntityKeyValue"] = "m";
luapad._sG["SetPlayerSpeed"] = "m";
luapad._sG["PlayerRequestTeam"] = "m";
luapad._sG["PlayerShouldTakeDamage"] = "m";
luapad._sG["PlayerSpawnObject"] = "m";
luapad._sG["ShowHelp"] = "m";
luapad._sG["CanConstrain"] = "m";
luapad._sG["PlayerDeathSound"] = "m";
luapad._sG["GetFallDamage"] = "m";
luapad._sG["PhysgunDrop"] = "m";
luapad._sG["PlayerSpawnNPC"] = "m";
luapad._sG["GravGunPunt"] = "m";
luapad._sG["PlayerSpawnedNPC"] = "m";
luapad._sG["PlayerSpawnedVehicle"] = "m";
luapad._sG["Call"] = "m";
luapad._sG["Remove"] = "m";
luapad._sG["GetTable"] = "m";
luapad._sG["Add"] = "m";
luapad._sG["OnConVarChanged"] = "m";
luapad._sG["AddChangeCallback"] = "m";
luapad._sG["GetConVarCallbacks"] = "m";
luapad._sG["OnConVarChanged"] = "m";
luapad._sG["AddChangeCallback"] = "m";
luapad._sG["GetConVarCallbacks"] = "m";
luapad._sG["OnConVarChanged"] = "m";
luapad._sG["AddChangeCallback"] = "m";
luapad._sG["GetConVarCallbacks"] = "m";
luapad._sG["OnConVarChanged"] = "m";
luapad._sG["AddChangeCallback"] = "m";
luapad._sG["GetConVarCallbacks"] = "m";
luapad._sG["OnConVarChanged"] = "m";
luapad._sG["AddChangeCallback"] = "m";
luapad._sG["GetConVarCallbacks"] = "m";
luapad._sG["ShouldDropOnDie"] = "m";
luapad._sG["CheckLimit"] = "m";
luapad._sG["SetWeaponHoldType"] = "m";
luapad._sG["GetNPCMinRest"] = "m";
luapad._sG["AcceptInput"] = "m";
luapad._sG["Deploy"] = "m";
luapad._sG["SetNPCMaxBurst"] = "m";
luapad._sG["Ammo1"] = "m";
luapad._sG["CanSecondaryAttack"] = "m";
luapad._sG["GetNPCMinBurst"] = "m";
luapad._sG["DoShootEffect"] = "m";
luapad._sG["TakePrimaryAmmo"] = "m";
luapad._sG["OnRemove"] = "m";
luapad._sG["ShootEffects"] = "m";
luapad._sG["SecondaryAttack"] = "m";
luapad._sG["Reload"] = "m";
luapad._sG["OnDrop"] = "m";
luapad._sG["InitializeTools"] = "m";
luapad._sG["Precache"] = "m";
luapad._sG["Equip"] = "m";
luapad._sG["NPCShoot_Secondary"] = "m";
luapad._sG["Holster"] = "m";
luapad._sG["OwnerChanged"] = "m";
luapad._sG["GetCapabilities"] = "m";
luapad._sG["Ammo2"] = "m";
luapad._sG["SetNPCMinBurst"] = "m";
luapad._sG["KeyValue"] = "m";
luapad._sG["SetDeploySpeed"] = "m";
luapad._sG["GetToolObject"] = "m";
luapad._sG["OnRestore"] = "m";
luapad._sG["SetNPCMaxRest"] = "m";
luapad._sG["Think"] = "m";
luapad._sG["CanPrimaryAttack"] = "m";
luapad._sG["GetNPCMaxRest"] = "m";
luapad._sG["NPCShoot_Primary"] = "m";
luapad._sG["TranslateActivity"] = "m";
luapad._sG["SetNPCMinRest"] = "m";
luapad._sG["CheckReload"] = "m";
luapad._sG["GetNPCMaxBurst"] = "m";
luapad._sG["SetupWeaponHoldTypeForAI"] = "m";
luapad._sG["ShootBullet"] = "m";
luapad._sG["SetNPCFireRate"] = "m";
luapad._sG["EquipAmmo"] = "m";
luapad._sG["Initialize"] = "m";
luapad._sG["GetMode"] = "m";
luapad._sG["GetNPCFireRate"] = "m";
luapad._sG["PrimaryAttack"] = "m";
luapad._sG["TakeSecondaryAmmo"] = "m";
luapad._sG["ContextScreenClick"] = "m";
luapad._sG["OnConVarChanged"] = "m";
luapad._sG["AddChangeCallback"] = "m";
luapad._sG["GetConVarCallbacks"] = "m";
luapad._sG["Sleep"] = "m";
luapad._sG["GetVolume"] = "m";
luapad._sG["GetRotDamping"] = "m";
luapad._sG["CalculateForceOffset"] = "m";
luapad._sG["GetAngle"] = "m";
luapad._sG["GetSpeedDamping"] = "m";
luapad._sG["GetEntity"] = "m";
luapad._sG["CalculateVelocityOffset"] = "m";
luapad._sG["SetAngleDragCoefficient"] = "m";
luapad._sG["AddVelocity"] = "m";
luapad._sG["GetInvInertia"] = "m";
luapad._sG["UpdateShadow"] = "m";
luapad._sG["GetInertia"] = "m";
luapad._sG["RotateAroundAxis"] = "m";
luapad._sG["GetAABB"] = "m";
luapad._sG["AlignAngles"] = "m";
luapad._sG["SetInertia"] = "m";
luapad._sG["ClearGameFlag"] = "m";
luapad._sG["AddGameFlag"] = "m";
luapad._sG["GetPos"] = "m";
luapad._sG["HasGameFlag"] = "m";
luapad._sG["GetMassCenter"] = "m";
luapad._sG["SetAngle"] = "m";
luapad._sG["ApplyForceOffset"] = "m";
luapad._sG["SetMaterial"] = "m";
luapad._sG["SetMass"] = "m";
luapad._sG["GetInvMass"] = "m";
luapad._sG["WorldToLocal"] = "m";
luapad._sG["SetBuoyancyRatio"] = "m";
luapad._sG["GetEnergy"] = "m";
luapad._sG["SetDragCoefficient"] = "m";
luapad._sG["ComputeShadowControl"] = "m";
luapad._sG["__eq"] = "m";
luapad._sG["GetMass"] = "m";
luapad._sG["AddAngleVelocity"] = "m";
luapad._sG["LocalToWorld"] = "m";
luapad._sG["GetAngles"] = "m";
luapad._sG["WorldToLocalVector"] = "m";
luapad._sG["SetPos"] = "m";
luapad._sG["__tostring"] = "m";
luapad._sG["IsPenetrating"] = "m";
luapad._sG["SetVelocity"] = "m";
luapad._sG["GetDamping"] = "m";
luapad._sG["SetVelocityInstantaneous"] = "m";
luapad._sG["ApplyForceCenter"] = "m";
luapad._sG["IsValid"] = "m";
luapad._sG["SetDamping"] = "m";
luapad._sG["IsAsleep"] = "m";
luapad._sG["EnableCollisions"] = "m";
luapad._sG["LocalToWorldVector"] = "m";
luapad._sG["Wake"] = "m";
luapad._sG["GetAngleVelocity"] = "m";
luapad._sG["IsMoveable"] = "m";
luapad._sG["GetMaterial"] = "m";
luapad._sG["OutputDebugInfo"] = "m";
luapad._sG["EnableMotion"] = "m";
luapad._sG["GetVelocity"] = "m";
luapad._sG["EnableDrag"] = "m";
luapad._sG["EnableGravity"] = "m";
luapad._sG["WriteVector"] = "m";
luapad._sG["StartBlock"] = "m";
luapad._sG["WriteInt"] = "m";
luapad._sG["WriteAngle"] = "m";
luapad._sG["WriteEntity"] = "m";
luapad._sG["EndBlock"] = "m";
luapad._sG["WriteFloat"] = "m";
luapad._sG["WriteBool"] = "m";
luapad._sG["WriteString"] = "m";
luapad._sG["ReadString"] = "m";
luapad._sG["ReadInt"] = "m";
luapad._sG["ReadEntity"] = "m";
luapad._sG["ReadVector"] = "m";
luapad._sG["ReadAngle"] = "m";
luapad._sG["EndBlock"] = "m";
luapad._sG["ReadFloat"] = "m";
luapad._sG["StartBlock"] = "m";
luapad._sG["ReadBool"] = "m";
luapad._sG["GetModel"] = "m";
luapad._sG["SetDerive"] = "m";
luapad._sG["SetMaxHealth"] = "m";
luapad._sG["SetNetworkedBeamFloat"] = "m";
luapad._sG["GetMaxHealth"] = "m";
luapad._sG["GetNetworkedBeamFloat"] = "m";
luapad._sG["StopLoopingSound"] = "m";
luapad._sG["LookupBone"] = "m";
luapad._sG["GetParent"] = "m";
luapad._sG["SetLocalVelocity"] = "m";
luapad._sG["SetParent"] = "m";
luapad._sG["Disposition"] = "m";
luapad._sG["SetNetworkedBool"] = "m";
luapad._sG["StartMotionController"] = "m";
luapad._sG["HasSpawnFlags"] = "m";
luapad._sG["GetPhysicsObjectNum"] = "m";
luapad._sG["SetModel"] = "m";
luapad._sG["WorldToLocalAngles"] = "m";
luapad._sG["GetNetworkedBool"] = "m";
luapad._sG["SetEyeTarget"] = "m";
luapad._sG["SetFlexWeight"] = "m";
luapad._sG["GetVar"] = "m";
luapad._sG["SetNWVector"] = "m";
luapad._sG["GetFlexNum"] = "m";
luapad._sG["PhysWake"] = "m";
luapad._sG["AlignAngles"] = "m";
luapad._sG["SetVar"] = "m";
luapad._sG["GetNWVector"] = "m";
luapad._sG["RemoveCallOnRemove"] = "m";
luapad._sG["GetName"] = "m";
luapad._sG["IsWeapon"] = "m";
luapad._sG["SetUnFreezable"] = "m";
luapad._sG["SetNotSolid"] = "m";
luapad._sG["WorldToLocal"] = "m";
luapad._sG["GetRight"] = "m";
luapad._sG["GetNetworkedVector"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["Remove"] = "m";
luapad._sG["ResetSequence"] = "m";
luapad._sG["GetUnFreezable"] = "m";
luapad._sG["__index"] = "m";
luapad._sG["SetNetworkedVector"] = "m";
luapad._sG["SetGravity"] = "m";
luapad._sG["GetDerive"] = "m";
luapad._sG["DispatchTraceAttack"] = "m";
luapad._sG["StopParticles"] = "m";
luapad._sG["EyeAngles"] = "m";
luapad._sG["SetCollisionBoundsWS"] = "m";
luapad._sG["SetMaterial"] = "m";
luapad._sG["__SetColor"] = "m";
luapad._sG["TakeDamage"] = "m";
luapad._sG["GetNWAngle"] = "m";
luapad._sG["IsPlayer"] = "m";
luapad._sG["NextThink"] = "m";
luapad._sG["GetMaterial"] = "m";
luapad._sG["EmitSound"] = "m";
luapad._sG["NearestPoint"] = "m";
luapad._sG["OBBMaxs"] = "m";
luapad._sG["OBBMins"] = "m";
luapad._sG["SetLocalPos"] = "m";
luapad._sG["StopSound"] = "m";
luapad._sG["__SetMaterial"] = "m";
luapad._sG["SetKeyValue"] = "m";
luapad._sG["SetNetworkedAngle"] = "m";
luapad._sG["SetAnimation"] = "m";
luapad._sG["SetNetworkedFloat"] = "m";
luapad._sG["IsOnFire"] = "m";
luapad._sG["IsInWorld"] = "m";
luapad._sG["PointAtEntity"] = "m";
luapad._sG["StartLoopingSound"] = "m";
luapad._sG["__SetKeyValue"] = "m";
luapad._sG["EyePos"] = "m";
luapad._sG["GetNWEntity"] = "m";
luapad._sG["GetNetworkedAngle"] = "m";
luapad._sG["GetNetworkedFloat"] = "m";
luapad._sG["SetNetworkedBeamEntity"] = "m";
luapad._sG["Activate"] = "m";
luapad._sG["SetPhysConstraintObjects"] = "m";
luapad._sG["GetUp"] = "m";
luapad._sG["SetNWInt"] = "m";
luapad._sG["GetFlexScale"] = "m";
luapad._sG["SetSolid"] = "m";
luapad._sG["SetTable"] = "m";
luapad._sG["SetPhysicsAttacker"] = "m";
luapad._sG["SetFlexScale"] = "m";
luapad._sG["DeleteOnRemove"] = "m";
luapad._sG["EntIndex"] = "m";
luapad._sG["SetCollisionBounds"] = "m";
luapad._sG["GetSolid"] = "m";
luapad._sG["GetTable"] = "m";
luapad._sG["GetMoveType"] = "m";
luapad._sG["ClearPoseParameters"] = "m";
luapad._sG["WorldSpaceAABB"] = "m";
luapad._sG["__eq"] = "m";
luapad._sG["GetPhysicsObjectCount"] = "m";
luapad._sG["GetPoseParameter"] = "m";
luapad._sG["GetLocalPos"] = "m";
luapad._sG["SetPos"] = "m";
luapad._sG["SetUseType"] = "m";
luapad._sG["GibBreakClient"] = "m";
luapad._sG["SetNWBString"] = "m";
luapad._sG["PhysicsInitBox"] = "m";
luapad._sG["DropToFloor"] = "m";
luapad._sG["IsWorld"] = "m";
luapad._sG["SetNWAngle"] = "m";
luapad._sG["GibBreakServer"] = "m";
luapad._sG["ResetSequenceInfo"] = "m";
luapad._sG["SetMoveParent"] = "m";
luapad._sG["SetLocalAngles"] = "m";
luapad._sG["GetNWBInt"] = "m";
luapad._sG["VisibleVec"] = "m";
luapad._sG["__tostring"] = "m";
luapad._sG["GetColor"] = "m";
luapad._sG["GetNetworkedEntity"] = "m";
luapad._sG["SkinCount"] = "m";
luapad._sG["GetCollisionGroup"] = "m";
luapad._sG["SetBloodColor"] = "m";
luapad._sG["SetParentPhysNum"] = "m";
luapad._sG["SetModelName"] = "m";
luapad._sG["SetNetworkedEntity"] = "m";
luapad._sG["BoundingRadius"] = "m";
luapad._sG["SetCollisionGroup"] = "m";
luapad._sG["StopMotionController"] = "m";
luapad._sG["GetPhysicsObject"] = "m";
luapad._sG["GetGroundEntity"] = "m";
luapad._sG["LocalToWorldAngles"] = "m";
luapad._sG["GetAngles"] = "m";
luapad._sG["MakePhysicsObjectAShadow"] = "m";
luapad._sG["SetElasticity"] = "m";
luapad._sG["LookupAttachment"] = "m";
luapad._sG["SetShouldDrawInViewMode"] = "m";
luapad._sG["Weapon_SetActivity"] = "m";
luapad._sG["GetPhysicsAttacker"] = "m";
luapad._sG["FireBullets"] = "m";
luapad._sG["PhysicsInit"] = "m";
luapad._sG["SetNWBAngle"] = "m";
luapad._sG["SetAngles"] = "m";
luapad._sG["GetClass"] = "m";
luapad._sG["SetColor"] = "m";
luapad._sG["CallOnRemove"] = "m";
luapad._sG["SetNetworkedVarProxy"] = "m";
luapad._sG["DrawShadow"] = "m";
luapad._sG["SetNetworkedString"] = "m";
luapad._sG["GetNetworkedVar"] = "m";
luapad._sG["Respawn"] = "m";
luapad._sG["DontDeleteOnRemove"] = "m";
luapad._sG["SetAttachment"] = "m";
luapad._sG["MuzzleFlash"] = "m";
luapad._sG["GetNetworkedString"] = "m";
luapad._sG["SetBoneMatrix"] = "m";
luapad._sG["GetBloodColor"] = "m";
luapad._sG["LookupSequence"] = "m";
luapad._sG["SetNetworkedInt"] = "m";
luapad._sG["GetFlexName"] = "m";
luapad._sG["IsOnGround"] = "m";
luapad._sG["OnGround"] = "m";
luapad._sG["GetLocalAngles"] = "m";
luapad._sG["PrecacheGibs"] = "m";
luapad._sG["SetNWBInt"] = "m";
luapad._sG["GetNetworkedInt"] = "m";
luapad._sG["Visible"] = "m";
luapad._sG["IsVehicle"] = "m";
luapad._sG["SetSequence"] = "m";
luapad._sG["GetNWFloat"] = "m";
luapad._sG["SetNWFloat"] = "m";
luapad._sG["GetSequence"] = "m";
luapad._sG["SetNetworkedNumber"] = "m";
luapad._sG["GetMoveCollide"] = "m";
luapad._sG["SetNetworkedBeamVector"] = "m";
luapad._sG["SetMoveCollide"] = "m";
luapad._sG["SetTrigger"] = "m";
luapad._sG["LocalToWorld"] = "m";
luapad._sG["GetAttachment"] = "m";
luapad._sG["GetNWBString"] = "m";
luapad._sG["GetNetworkedBeamString"] = "m";
luapad._sG["SetNWBVector"] = "m";
luapad._sG["SetSolidMask"] = "m";
luapad._sG["SetHealth"] = "m";
luapad._sG["PhysicsFromMesh"] = "m";
luapad._sG["SetCycle"] = "m";
luapad._sG["SetFriction"] = "m";
luapad._sG["__concat"] = "m";
luapad._sG["SetNetworkedBeamString"] = "m";
luapad._sG["SetNWBool"] = "m";
luapad._sG["SetSkin"] = "m";
luapad._sG["GetMoveParent"] = "m";
luapad._sG["GetNetworkedBeamBool"] = "m";
luapad._sG["GetNWBVector"] = "m";
luapad._sG["GetSkin"] = "m";
luapad._sG["Extinguish"] = "m";
luapad._sG["__Fire"] = "m";
luapad._sG["IsPlayerHolding"] = "m";
luapad._sG["GetFlexWeight"] = "m";
luapad._sG["IsNPC"] = "m";
luapad._sG["SetNetworkedBeamBool"] = "m";
luapad._sG["SetPlaybackRate"] = "m";
luapad._sG["GetOwner"] = "m";
luapad._sG["GetNWBEntity"] = "m";
luapad._sG["GetNetworkedBeamEntity"] = "m";
luapad._sG["PhysicsInitShadow"] = "m";
luapad._sG["SetNWBFloat"] = "m";
luapad._sG["SetNWBEntity"] = "m";
luapad._sG["SetRenderMode"] = "m";
luapad._sG["GetParentPhysNum"] = "m";
luapad._sG["RestartGesture"] = "m";
luapad._sG["GetNWBAngle"] = "m";
luapad._sG["__newindex"] = "m";
luapad._sG["SetOwner"] = "m";
luapad._sG["TranslatePhysBoneToBone"] = "m";
luapad._sG["SetNWString"] = "m";
luapad._sG["IsValid"] = "m";
luapad._sG["GetNWBFloat"] = "m";
luapad._sG["GetNetworkedBeamAngle"] = "m";
luapad._sG["SetNWEntity"] = "m";
luapad._sG["SetGroundEntity"] = "m";
luapad._sG["Weapon_TranslateActivity"] = "m";
luapad._sG["GetBoneMatrix"] = "m";
luapad._sG["SetBodygroup"] = "m";
luapad._sG["SetNetworkedVar"] = "m";
luapad._sG["SetNoDraw"] = "m";
luapad._sG["Input"] = "m";
luapad._sG["Fire"] = "m";
luapad._sG["SelectWeightedSequence"] = "m";
luapad._sG["__SetNoDraw"] = "m";
luapad._sG["SequenceDuration"] = "m";
luapad._sG["GetDerived"] = "m";
luapad._sG["Health"] = "m";
luapad._sG["IsConstrained"] = "m";
luapad._sG["GetNWBBool"] = "m";
luapad._sG["SetNetworkedBeamAngle"] = "m";
luapad._sG["GetPos"] = "m";
luapad._sG["PhysicsInitSphere"] = "m";
luapad._sG["SetNWBBool"] = "m";
luapad._sG["GetNetworkedBeamVector"] = "m";
luapad._sG["GetActivity"] = "m";
luapad._sG["SetName"] = "m";
luapad._sG["WaterLevel"] = "m";
luapad._sG["TakePhysicsDamage"] = "m";
luapad._sG["GetNWString"] = "m";
luapad._sG["OBBCenter"] = "m";
luapad._sG["GetNWBool"] = "m";
luapad._sG["SetVelocity"] = "m";
luapad._sG["GetNWInt"] = "m";
luapad._sG["SetNetworkedBeamInt"] = "m";
luapad._sG["Ignite"] = "m";
luapad._sG["GetKeyValues"] = "m";
luapad._sG["SetEntity"] = "m";
luapad._sG["GetBonePosition"] = "m";
luapad._sG["GetBodygroup"] = "m";
luapad._sG["SetMoveType"] = "m";
luapad._sG["SetPoseParameter"] = "m";
luapad._sG["GetForward"] = "m";
luapad._sG["Spawn"] = "m";
luapad._sG["GetVelocity"] = "m";
luapad._sG["GetFlexBounds"] = "m";
luapad._sG["GetNetworkedBeamInt"] = "m";
luapad._sG["Quaternion"] = "m";
luapad._sG["__eq"] = "m";
luapad._sG["Right"] = "m";
luapad._sG["__mul"] = "m";
luapad._sG["__index"] = "m";
luapad._sG["RotateAroundAxis"] = "m";
luapad._sG["ToDeg"] = "m";
luapad._sG["Up"] = "m";
luapad._sG["__add"] = "m";
luapad._sG["__tostring"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["__newindex"] = "m";
luapad._sG["Forward"] = "m";
luapad._sG["__sub"] = "m";
luapad._sG["ToRad"] = "m";
luapad._sG["AddAllPlayers"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["AddPVS"] = "m";
luapad._sG["RemovePlayer"] = "m";
luapad._sG["AddPlayer"] = "m";
luapad._sG["RemovePVS"] = "m";
luapad._sG["RemoveAllPlayers"] = "m";
luapad._sG["ChangeVolume"] = "m";
luapad._sG["ChangePitch"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["SetSoundLevel"] = "m";
luapad._sG["Stop"] = "m";
luapad._sG["Play"] = "m";
luapad._sG["IsPlaying"] = "m";
luapad._sG["PlayEx"] = "m";
luapad._sG["FadeOut"] = "m";
luapad._sG["__newindex"] = "m";
luapad._sG["__index"] = "m";
luapad._sG["__call"] = "m";
luapad._sG["GetSurfaceProp"] = "m";
luapad._sG["GetAngle"] = "m";
luapad._sG["GetScale"] = "m";
luapad._sG["SetMagnitude"] = "m";
luapad._sG["GetStart"] = "m";
luapad._sG["GetNormal"] = "m";
luapad._sG["SetOrigin"] = "m";
luapad._sG["SetScale"] = "m";
luapad._sG["GetRadius"] = "m";
luapad._sG["SetStart"] = "m";
luapad._sG["GetEntity"] = "m";
luapad._sG["SetEntity"] = "m";
luapad._sG["SetAngle"] = "m";
luapad._sG["SetNormal"] = "m";
luapad._sG["GetMagnitude"] = "m";
luapad._sG["GetOrigin"] = "m";
luapad._sG["SetSurfaceProp"] = "m";
luapad._sG["SetAttachment"] = "m";
luapad._sG["SetRadius"] = "m";
luapad._sG["GetAttachment"] = "m";
luapad._sG["GetSideMove"] = "m";
luapad._sG["KeyDown"] = "m";
luapad._sG["SetUpMove"] = "m";
luapad._sG["SetViewAngles"] = "m";
luapad._sG["SetSideMove"] = "m";
luapad._sG["SetMouseY"] = "m";
luapad._sG["GetViewAngles"] = "m";
luapad._sG["GetMouseY"] = "m";
luapad._sG["GetForwardMove"] = "m";
luapad._sG["GetMouseX"] = "m";
luapad._sG["SetForwardMove"] = "m";
luapad._sG["GetUpMove"] = "m";
luapad._sG["SetMouseX"] = "m";
luapad._sG["IsExplosionDamage"] = "m";
luapad._sG["GetReportedPosition"] = "m";
luapad._sG["GetDamageForce"] = "m";
luapad._sG["GetMaxDamage"] = "m";
luapad._sG["GetAttacker"] = "m";
luapad._sG["GetDamage"] = "m";
luapad._sG["SetDamageForce"] = "m";
luapad._sG["IsBulletDamage"] = "m";
luapad._sG["IsFallDamage"] = "m";
luapad._sG["AddDamage"] = "m";
luapad._sG["GetDamagePosition"] = "m";
luapad._sG["SetInflictor"] = "m";
luapad._sG["IsDamageType"] = "m";
luapad._sG["SetAttacker"] = "m";
luapad._sG["GetInflictor"] = "m";
luapad._sG["SetDamage"] = "m";
luapad._sG["ScaleDamage"] = "m";
luapad._sG["GetBaseDamage"] = "m";
luapad._sG["GetAmmoType"] = "m";
luapad._sG["SubtractDamage"] = "m";
luapad._sG["__eq"] = "m";
luapad._sG["__tostring"] = "m";
luapad._sG["Normalize"] = "m";
luapad._sG["Dot"] = "m";
luapad._sG["Length"] = "m";
luapad._sG["__index"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["Sub"] = "m";
luapad._sG["Angle"] = "m";
luapad._sG["DotProduct"] = "m";
luapad._sG["Distance"] = "m";
luapad._sG["__mul"] = "m";
luapad._sG["GetNormalized"] = "m";
luapad._sG["GetNormal"] = "m";
luapad._sG["__add"] = "m";
luapad._sG["Mul"] = "m";
luapad._sG["__div"] = "m";
luapad._sG["Cross"] = "m";
luapad._sG["__newindex"] = "m";
luapad._sG["Rotate"] = "m";
luapad._sG["__sub"] = "m";
luapad._sG["Add"] = "m";
luapad._sG["Finished"] = "m";
luapad._sG["GetBuffer"] = "m";
luapad._sG["DownloadSize"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["Download"] = "m";
luapad._sG["SetPos"] = "m";
luapad._sG["__newindex"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["__index"] = "m";
luapad._sG["GetMaxSpeed"] = "m";
luapad._sG["SetUpSpeed"] = "m";
luapad._sG["GetSideSpeed"] = "m";
luapad._sG["GetConstraintRadius"] = "m";
luapad._sG["SetForwardSpeed"] = "m";
luapad._sG["GetMoveAngles"] = "m";
luapad._sG["SetOrigin"] = "m";
luapad._sG["SetMoveAngles"] = "m";
luapad._sG["SetMaxClientSpeed"] = "m";
luapad._sG["GetUpSpeed"] = "m";
luapad._sG["SetSideSpeed"] = "m";
luapad._sG["GetForwardSpeed"] = "m";
luapad._sG["SetVelocity"] = "m";
luapad._sG["GetOrigin"] = "m";
luapad._sG["SetConstraintRadius"] = "m";
luapad._sG["GetVelocity"] = "m";
luapad._sG["SetMaxSpeed"] = "m";
luapad._sG["GetMaxClientSpeed"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["Scale"] = "m";
luapad._sG["__mul"] = "m";
luapad._sG["GetAngle"] = "m";
luapad._sG["GetTranslation"] = "m";
luapad._sG["Rotate"] = "m";
luapad._sG["Translate"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["SetTranslation"] = "m";
luapad._sG["ScaleTranslation"] = "m";
luapad._sG["GetPassenger"] = "m";
luapad._sG["GetDriver"] = "m";
luapad._sG["__tostring"] = "m";
luapad._sG["__newindex"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["__index"] = "m";
luapad._sG["IsVehicle"] = "m";
luapad._sG["GetPathTimeToGoal"] = "m";
luapad._sG["SetMovementSequence"] = "m";
luapad._sG["LostEnemySound"] = "m";
luapad._sG["NavSetRandomGoal"] = "m";
luapad._sG["__tostring"] = "m";
luapad._sG["SetNPCState"] = "m";
luapad._sG["GetAimVector"] = "m";
luapad._sG["SetExpression"] = "m";
luapad._sG["IsCurrentSchedule"] = "m";
luapad._sG["HasCondition"] = "m";
luapad._sG["TaskComplete"] = "m";
luapad._sG["GetNPCState"] = "m";
luapad._sG["IdleSound"] = "m";
luapad._sG["SetTarget"] = "m";
luapad._sG["GetExpression"] = "m";
luapad._sG["ClearSchedule"] = "m";
luapad._sG["GetTarget"] = "m";
luapad._sG["UseActBusyBehavior"] = "m";
luapad._sG["ConditionName"] = "m";
luapad._sG["ClearExpression"] = "m";
luapad._sG["SetHullSizeNormal"] = "m";
luapad._sG["GetHullType"] = "m";
luapad._sG["SetLastPosition"] = "m";
luapad._sG["SetArrivalActivity"] = "m";
luapad._sG["GetArrivalActivity"] = "m";
luapad._sG["GetEnemy"] = "m";
luapad._sG["PlayScene"] = "m";
luapad._sG["SetHullType"] = "m";
luapad._sG["CapabilitiesGet"] = "m";
luapad._sG["SetArrivalDirection"] = "m";
luapad._sG["ExitScriptedSequence"] = "m";
luapad._sG["SetSchedule"] = "m";
luapad._sG["AddRelationship"] = "m";
luapad._sG["GetActiveWeapon"] = "m";
luapad._sG["StartEngineTask"] = "m";
luapad._sG["IsNPC"] = "m";
luapad._sG["UseAssaultBehavior"] = "m";
luapad._sG["NavSetWanderGoal"] = "m";
luapad._sG["SentenceStop"] = "m";
luapad._sG["__newindex"] = "m";
luapad._sG["MaintainActivity"] = "m";
luapad._sG["TaskFail"] = "m";
luapad._sG["AddEntityRelationship"] = "m";
luapad._sG["PlaySentence"] = "m";
luapad._sG["SetMaxRouteRebuildTime"] = "m";
luapad._sG["CapabilitiesAdd"] = "m";
luapad._sG["GetPathDistanceToGoal"] = "m";
luapad._sG["IsRunningBehavior"] = "m";
luapad._sG["GetArrivalSequence"] = "m";
luapad._sG["UseLeadBehavior"] = "m";
luapad._sG["UpdateEnemyMemory"] = "m";
luapad._sG["SetArrivalSpeed"] = "m";
luapad._sG["SetEnemy"] = "m";
luapad._sG["UseFuncTankBehavior"] = "m";
luapad._sG["ClearGoal"] = "m";
luapad._sG["AlertSound"] = "m";
luapad._sG["CapabilitiesClear"] = "m";
luapad._sG["Give"] = "m";
luapad._sG["GetBlockingEntity"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["UseNoBehavior"] = "m";
luapad._sG["GetMovementActivity"] = "m";
luapad._sG["ClearCondition"] = "m";
luapad._sG["NavSetGoal"] = "m";
luapad._sG["SetArrivalDistance"] = "m";
luapad._sG["UseFollowBehavior"] = "m";
luapad._sG["RemoveMemory"] = "m";
luapad._sG["__index"] = "m";
luapad._sG["MarkEnemyAsEluded"] = "m";
luapad._sG["MoveOrder"] = "m";
luapad._sG["SetArrivalSequence"] = "m";
luapad._sG["GetShootPos"] = "m";
luapad._sG["SetCondition"] = "m";
luapad._sG["CapabilitiesRemove"] = "m";
luapad._sG["SetMovementActivity"] = "m";
luapad._sG["StopMoving"] = "m";
luapad._sG["ClearEnemyMemory"] = "m";
luapad._sG["FearSound"] = "m";
luapad._sG["TargetOrder"] = "m";
luapad._sG["RunEngineTask"] = "m";
luapad._sG["FoundEnemySound"] = "m";
luapad._sG["NavSetGoalTarget"] = "m";
luapad._sG["GetMovementSequence"] = "m";
luapad._sG["Classify"] = "m";
luapad._sG["GetScriptedVehicle"] = "m";
luapad._sG["GetViewOffsetDucked"] = "m";
luapad._sG["CheckLimit"] = "m";
luapad._sG["__tostring"] = "m";
luapad._sG["GetAimVector"] = "m";
luapad._sG["SendHint"] = "m";
luapad._sG["CrosshairEnable"] = "m";
luapad._sG["EquipSuit"] = "m";
luapad._sG["GetEyeTraceNoCursor"] = "m";
luapad._sG["ChatPrint"] = "m";
luapad._sG["DetonateTripmines"] = "m";
luapad._sG["TraceHullAttack"] = "m";
luapad._sG["ViewPunch"] = "m";
luapad._sG["StripWeapons"] = "m";
luapad._sG["ShouldDropWeapon"] = "m";
luapad._sG["GetAmmoCount"] = "m";
luapad._sG["SendLua"] = "m";
luapad._sG["PacketLoss"] = "m";
luapad._sG["Spectate"] = "m";
luapad._sG["SetUserGroup"] = "m";
luapad._sG["DropWeapon"] = "m";
luapad._sG["Lock"] = "m";
luapad._sG["GetInfo"] = "m";
luapad._sG["PrintMessage"] = "m";
luapad._sG["SprintDisable"] = "m";
luapad._sG["SetNoTarget"] = "m";
luapad._sG["KeyPressed"] = "m";
luapad._sG["UniqueIDTable"] = "m";
luapad._sG["UniqueID"] = "m";
luapad._sG["GodDisable"] = "m";
luapad._sG["IsSuperAdmin"] = "m";
luapad._sG["SelectWeapon"] = "m";
luapad._sG["SetCanZoom"] = "m";
luapad._sG["GetName"] = "m";
luapad._sG["IsWeapon"] = "m";
luapad._sG["KeyDownLast"] = "m";
luapad._sG["IsUserGroup"] = "m";
luapad._sG["Nick"] = "m";
luapad._sG["Kill"] = "m";
luapad._sG["SprintEnable"] = "m";
luapad._sG["AllowImmediateDecalPainting"] = "m";
luapad._sG["UserID"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["GetXFire"] = "m";
luapad._sG["Team"] = "m";
luapad._sG["SetDeaths"] = "m";
luapad._sG["KeyReleased"] = "m";
luapad._sG["SetClientsideVehicle"] = "m";
luapad._sG["GetFOV"] = "m";
luapad._sG["GetShootPos"] = "m";
luapad._sG["IPAddress"] = "m";
luapad._sG["SetViewOffsetDucked"] = "m";
luapad._sG["AddDeaths"] = "m";
luapad._sG["GetAllowFullRotation"] = "m";
luapad._sG["GetCount"] = "m";
luapad._sG["GetClientsideVehicle"] = "m";
luapad._sG["Kick"] = "m";
luapad._sG["GetMaxSpeed"] = "m";
luapad._sG["IsVehicle"] = "m";
luapad._sG["SpectateEntity"] = "m";
luapad._sG["Flashlight"] = "m";
luapad._sG["SetTeam"] = "m";
luapad._sG["SuppressHint"] = "m";
luapad._sG["GetTool"] = "m";
luapad._sG["UnLock"] = "m";
luapad._sG["SetMaxSpeed"] = "m";
luapad._sG["TargetFinderUnlock"] = "m";
luapad._sG["Freeze"] = "m";
luapad._sG["IsPlayer"] = "m";
luapad._sG["GetEyeTrace"] = "m";
luapad._sG["AddCleanup"] = "m";
luapad._sG["GetCursorAimVector"] = "m";
luapad._sG["AddCount"] = "m";
luapad._sG["IsAdmin"] = "m";
luapad._sG["GetRagdollEntity"] = "m";
luapad._sG["GetAIM"] = "m";
luapad._sG["TimeConnected"] = "m";
luapad._sG["GetMSN"] = "m";
luapad._sG["GetEmail"] = "m";
luapad._sG["GetLocation"] = "m";
luapad._sG["PhysgunUnfreeze"] = "m";
luapad._sG["Alive"] = "m";
luapad._sG["SetHullDuck"] = "m";
luapad._sG["LagCompensation"] = "m";
luapad._sG["SetEyeAngles"] = "m";
luapad._sG["IsBot"] = "m";
luapad._sG["TargetFinderLock"] = "m";
luapad._sG["ResetHull"] = "m";
luapad._sG["SetViewOffset"] = "m";
luapad._sG["CreateSharedTable"] = "m";
luapad._sG["DrawWorldModel"] = "m";
luapad._sG["SendData"] = "m";
luapad._sG["SetSuppressPickupNotices"] = "m";
luapad._sG["DropNamedWeapon"] = "m";
luapad._sG["SetDuckSpeed"] = "m";
luapad._sG["SetRunSpeed"] = "m";
luapad._sG["SetAllowFullRotation"] = "m";
luapad._sG["StripWeapon"] = "m";
luapad._sG["KeyDown"] = "m";
luapad._sG["Ping"] = "m";
luapad._sG["GetCanZoom"] = "m";
luapad._sG["SetCrouchedWalkSpeed"] = "m";
luapad._sG["EnterVehicle"] = "m";
luapad._sG["GetWeapon"] = "m";
luapad._sG["SteamID"] = "m";
luapad._sG["GetViewModel"] = "m";
luapad._sG["AddFrozenPhysicsObject"] = "m";
luapad._sG["SetScriptedVehicle"] = "m";
luapad._sG["SetFrags"] = "m";
luapad._sG["SetDSP"] = "m";
luapad._sG["GiveAmmo"] = "m";
luapad._sG["GetObserverTarget"] = "m";
luapad._sG["GetGTalk"] = "m";
luapad._sG["SetPData"] = "m";
luapad._sG["GetPData"] = "m";
luapad._sG["IsNPC"] = "m";
luapad._sG["GetVehicle"] = "m";
luapad._sG["ConCommand"] = "m";
luapad._sG["GetSharedTable"] = "m";
luapad._sG["GetViewOffset"] = "m";
luapad._sG["GetNoCollideWithTeammates"] = "m";
luapad._sG["GetCurrentCommand"] = "m";
luapad._sG["GetJumpPower"] = "m";
luapad._sG["__newindex"] = "m";
luapad._sG["SetCanWalk"] = "m";
luapad._sG["GetCanWalk"] = "m";
luapad._sG["Name"] = "m";
luapad._sG["FlashlightIsOn"] = "m";
luapad._sG["RemoveAmmo"] = "m";
luapad._sG["Crouching"] = "m";
luapad._sG["DebugInfo"] = "m";
luapad._sG["Deaths"] = "m";
luapad._sG["DrawViewModel"] = "m";
luapad._sG["StopZooming"] = "m";
luapad._sG["HasWeapon"] = "m";
luapad._sG["AddFrags"] = "m";
luapad._sG["GetInfoNum"] = "m";
luapad._sG["__index"] = "m";
luapad._sG["Frags"] = "m";
luapad._sG["SetAmmo"] = "m";
luapad._sG["GetWebsite"] = "m";
luapad._sG["SetWalkSpeed"] = "m";
luapad._sG["GetAvoidPlayers"] = "m";
luapad._sG["StripAmmo"] = "m";
luapad._sG["SetJumpPower"] = "m";
luapad._sG["SetAvoidPlayers"] = "m";
luapad._sG["SetNoCollideWithTeammates"] = "m";
luapad._sG["CrosshairDisable"] = "m";
luapad._sG["KillSilent"] = "m";
luapad._sG["SetViewEntity"] = "m";
luapad._sG["SetArmor"] = "m";
luapad._sG["PlayStepSound"] = "m";
luapad._sG["Ban"] = "m";
luapad._sG["IsListenServerHost"] = "m";
luapad._sG["LimitHit"] = "m";
luapad._sG["SetUnDuckSpeed"] = "m";
luapad._sG["Give"] = "m";
luapad._sG["InVehicle"] = "m";
luapad._sG["Armor"] = "m";
luapad._sG["GetStepSize"] = "m";
luapad._sG["SetHull"] = "m";
luapad._sG["RemoveAllAmmo"] = "m";
luapad._sG["IsFrozen"] = "m";
luapad._sG["SetStepSize"] = "m";
luapad._sG["LastHitGroup"] = "m";
luapad._sG["ExitVehicle"] = "m";
luapad._sG["UnfreezePhysicsObjects"] = "m";
luapad._sG["IsLockedOnto"] = "m";
luapad._sG["GetWeapons"] = "m";
luapad._sG["GetViewEntity"] = "m";
luapad._sG["GodEnable"] = "m";
luapad._sG["GetActiveWeapon"] = "m";
luapad._sG["SetFOV"] = "m";
luapad._sG["IsConnected"] = "m";
luapad._sG["UnSpectate"] = "m";
luapad._sG["SnapEyeAngles"] = "m";
luapad._sG["GetObserverMode"] = "m";
luapad._sG["CreateRagdoll"] = "m";
luapad._sG["IsNPC"] = "m";
luapad._sG["SendWeaponAnim"] = "m";
luapad._sG["Clip2"] = "m";
luapad._sG["SetClip1"] = "m";
luapad._sG["GetSecondaryAmmoType"] = "m";
luapad._sG["__newindex"] = "m";
luapad._sG["__gc"] = "m";
luapad._sG["__index"] = "m";
luapad._sG["IsWeaponVisible"] = "m";
luapad._sG["IsPlayer"] = "m";
luapad._sG["CallOnClient"] = "m";
luapad._sG["LastShootTime"] = "m";
luapad._sG["__tostring"] = "m";
luapad._sG["IsVehicle"] = "m";
luapad._sG["GetActivity"] = "m";
luapad._sG["SetNextPrimaryFire"] = "m";
luapad._sG["Clip1"] = "m";
luapad._sG["SetNextSecondaryFire"] = "m";
luapad._sG["IsWeapon"] = "m";
luapad._sG["DefaultReload"] = "m";
luapad._sG["GetPrimaryAmmoType"] = "m";
luapad._sG["SetClip2"] = "m";
luapad._sG["GetName"] = "m";
luapad._sG["GetFloat"] = "m";
luapad._sG["GetInt"] = "m";
luapad._sG["GetBool"] = "m";
luapad._sG["GetString"] = "m";
luapad._sG["GetDefault"] = "m";
luapad._sG["GetHelpText"] = "m";