--[[



	---------------------------------------------------------------------------------------------------
	---------------------------------------- ＭｏｄｕｌｅＳｙｎｃ ｂｙ Ｍａｘ ----------------------------------------
	---------------------------------------------------------------------------------------------------

	ModuleSync in short:
	    ModuleSync allows you to reflect changes made to modules on the server to clients
	    You can also create hook functions to respond to changes and exclude specific modules and paths from replication

	Core Features:
	    • .Set()       - Set a value at a given path in a module.                         (=)
	    • .Modify()    - Perform arithmetic operations on numeric values in a module.     (+=, -=, *=, /=, %=)
	    • .Insert()    - Insert a value into a table at a specified path.                 (table.insert)
	    • .Remove()    - Remove a value from a table at a specified path.                 (table.remove)
	    • .Move()      - Move/append all elements from one table into a table at a path.  (table.move)
	    • .Not()       - Toggle a boolean value at a specified path.                      (x = not x)
	    • .Concat()    - Concatenate a string to an existing string at a path.            (string.concat)
	    • .OnChange()  - Register hook functions that run when a path is updated.

	---------------------------------------------------------------------
	Settings:
	    ModuleSync.Excluded[module] = {...} 
	        • Excludes a module or specific paths from replicating to clients.
	        • Examples:
	            table.insert(ModuleSync.Excluded[game.ReplicatedStorage.Shared], {"Path","To","Index"})
	            ModuleSync.Excluded[game.ReplicatedStorage.Shared] = {}     -- exclude entire module
	            ModuleSync.Excluded[game.ReplicatedStorage.Shared] = nil    -- remove exclusion

	---------------------------------------------------------------------
	How to Set Data:
	    ModuleSync.Set(ModuleScript, path, value, params)
	        • ModuleScript: The ModuleScript you want to modify.
	        • path: Table of keys specifying the location in the module. {} modifies the entire module.
	        • value: The value to assign.
	        • params: Optional table for arguments to hook functions.
	        • Example:
	            ModuleSync.Set(DataModule, {player.Name}, 5)
	            ModuleSync.Set(DataModule, {"Name"}, {true,false,true})
	            ModuleSync.Set(DataModule, {"A","B","C"}, "Hello World")
	            ModuleSync.Set(DataModule, {}, {true,false,true})  -- replaces entire module

	---------------------------------------------------------------------
	How to Modify Data:
	    ModuleSync.Modify(ModuleScript, path, value, operation, params)
	        • Modify numeric values using operations: '+', '-', '*', '/', '%'.
	        • operation: Can be '+', '-', '*', '/', '%', or their shorthand variants ('+=', '-=', '*=', '/=', '%=').
	        • params: Optional table for arguments to hook functions.
	        • Example:
	            ModuleSync.Modify(DataModule, {"Stats","Coins"}, 5, "+")         -- adds 5 to Coins
	            ModuleSync.Modify(DataModule, {"Stats","Multiplier"}, 1.2, "*")  -- multiplies value by 1.2

	---------------------------------------------------------------------
	Table Manipulation:
	    ModuleSync.Insert(ModuleScript, path, value, params)
	        • Inserts a value into a table at the specified path.
	    ModuleSync.Remove(ModuleScript, path, index, params)
	        • Removes a value from a table at the specified path by numeric index.
	    ModuleSync.Move(ModuleScript, path, value, params)
	        • Moves/appends all elements from `value` (a table) into the table at the given path.
	        • `value` must be a table.
	        • Example:
	            ModuleSync.Move(DataModule, {"Inventory"}, {100,101,102})

	Boolean and String Utilities:
	    ModuleSync.Not(ModuleScript, path, params)             -- toggles a boolean value
	    ModuleSync.Concat(ModuleScript, path, value, params)   -- concatenates a string to existing string at path

	---------------------------------------------------------------------
	Hook Functions:
	    ModuleSync.OnChange(ModuleScript, path, params, func)
	        • Register a function to run when a path changes.
	        • ModuleScript: The module to watch.
	        • path: Table specifying the module path to watch.
	        • params: Optional table, e.g., {'Exact Match'}.
	            - 'Exact Match' ensures the hook triggers only when the path exactly matches.
	            - nil or {} triggers for nested paths as well.
	        • func(value, changedValue, path, params): Callback receiving
	            - `value`: the current value at the watched path
	            - `changedValue`: the value that was set/modified
	            - `path`: the full path that changed
	            - `params`: parameters passed through ModuleSync function
	        • Example:
	            ModuleSync.OnChange(DataModule, {'Stats','Coins'}, {'Exact Match'}, function(currentValue, changedValue, pathToChangedValue, customParametersSetByYou, isAddedToTable)
	                print("Coins updated to", changedValue)
	            end)
	            isAddedToTable will return true for .Insert() and .Move()
	            false for .Remove()
	            nil for all others as they directly set a value

	---------------------------------------------------------------------
	Accessing Data:
	    Access the data you set on the server just as you would access a ModuleScript normally.
	    Example:
	        ModuleSync.Set(Path.To.Module, {"Test"}, true)
	        print(require(Path.To.Module)["Test"])  -- true

	---------------------------------------------------------------------
	Setup Instructions:
	    1. Set the DataModule to your desired ModuleScript accessible by both server and client.
	    2. Require ModuleSync on the client.
	    3. Require ModuleSync on the server.
	    4. Use ModuleSync functions on the server to synchronize data.

	---------------------------------------------------------------------
	Important Notes:
	    • Data is only synchronized when using ModuleSync functions on the server.
	    • Directly setting values in the ModuleScript or using ModuleSync.Set() on the client will cause desynchronization.
	    • Hook functions run on both client and server when triggered by .Set() or other modifying functions.
	    • Hook functions will not run on the client when the server makes a change to an excluded module or path.

	---------------------------------------------------------------------------------------------------



]]

local ModuleSync = {}
if game:GetService("RunService"):IsServer() then
	-- Exclude modules in this "Excluded" table
	-- To exclude modules during runtime modify ModuleSync.Excluded from the server
	local Excluded = {
		[game.ServerScriptService.ModuleScript] = {},
	}

	ModuleSync.Excluded = Excluded
end

---------------------------------------- Settings/Docs End ----------------------------------------

-- services
local RunService = game:GetService("RunService")

-- variables
local edited = {} -- stores edited modules to send to reflect changes made to modules before a player was in the server

---------------------------------------- Init server & client ----------------------------------------

if RunService:IsServer() then -- Server: create remotes & send plr module data
	local remote = Instance.new("RemoteEvent")
	remote.Parent = script
	remote.Name = "Set"

	local remote = Instance.new("RemoteEvent")
	remote.Parent = script
	remote.Name = "Loaded"

	-- when player tells server they are ready: send them all edited data
	script.Loaded.OnServerEvent:Connect(function(player)
		for module, contents in edited do
			script.Set:FireClient(player, module, {}, contents)
		end
	end)
elseif RunService:IsClient() then -- Client: tell player they are ready for data when they load
	script:WaitForChild("Set").OnClientEvent:Connect(function(ModuleScript, path, value)
		ModuleSync.Set(ModuleScript, path, value)
	end)
	script:WaitForChild("Loaded"):FireServer()
end

---------------------------------------- Hook Functions ----------------------------------------

local hooks = {}
function ModuleSync.OnChange(
	ModuleScript: ModuleScript,
	path: "Path",
	params: "Custom parameters set on change",
	func: "Function to run on change"
)
	table.insert(hooks, { ModuleScript = ModuleScript, Path = path, Function = func, Params = params })
end

---------------------------------------- Utility Functions ----------------------------------------

-------------------- Shallow Copy --------------------

local function shallowCopy(toModify, t)
	-- Remove all previous entries
	table.clear(toModify)

	-- Assign new entries
	for i, v in t do
		toModify[i] = v
	end
	return toModify
end

-------------------- Get Path --------------------

local function getPath(current, path, subtract)
	for i = 1, #path - subtract do
		local name = path[i]
		if not current[name] then
			current[name] = {}
		end
		current = current[name]
	end

	return current
end

-------------------- Get Module Contents --------------------

local function getModuleContents(ModuleScript)
	if not ModuleScript then
		warn("📜 Could not find module:\n" .. debug.traceback())
		return
	end

	local success, result = pcall(function()
		return require(ModuleScript)
	end)

	if success then
		return result
	else
		warn("📜 Failed to require module:\n" .. debug.traceback(result))
		return
	end
end

-------------------- Run hook functions & send change to client --------------------

local function logic(ModuleScript, path, data, value, params, isAdd)
	local module = getModuleContents(ModuleScript)
	if not module then
		return
	end

	-- Hook functions
	for i, current in hooks do
		local match = true
		local send = data
		if current.ModuleScript ~= ModuleScript then
			continue
		end
		if current.Params and table.find(current.Params, "Exact Match") then
			for i = 1, math.max(#current.Path, #path) do
				if current.Path[i] ~= path[i] then
					match = false
					break
				end
			end
		else
			for i, v in current.Path do
				if v ~= path[i] then
					match = false
					break
				end
			end
			if not match then
				continue
			end
			send = module
			for i, v in current.Path do
				send = send[v]
			end
		end
		if not match then
			continue
		end
		current.Function(send, value, path, params, isAdd)
	end

	-- Server stuff
	if RunService:IsServer() then
		-- Check for excluded modules and paths
		local match = false
		if ModuleSync.Excluded[ModuleScript] then
			if #ModuleSync.Excluded[ModuleScript] == 0 then
				match = true
			else
				for i, excluded in ModuleSync.Excluded[ModuleScript] do
					if #excluded == 0 then
						match = true
						break
					end
					for i = 1, #excluded do
						if path[i] ~= excluded[i] then
							match = true
							break
						end
					end
					if match then
						break
					end
				end
			end
		end

		-- If path is not in excluded path: update client & mark module as edited
		if not match then
			if ModuleScript:IsDescendantOf(game.ServerScriptService) then
				return
			end
			script.Set:FireAllClients(ModuleScript, path, value)
			edited[ModuleScript] = module
		end
	end
end

---------------------------------------- Set ----------------------------------------

function ModuleSync.Set(
	ModuleScript: ModuleScript,
	path: "Path",
	value: "Value",
	params: "Arguments for Hook Function(s)"
)
	local module = getModuleContents(ModuleScript)
	if not module then
		return
	end

	local current = module
	if #path == 0 then
		shallowCopy(module, value)
	else
		current = getPath(module, path, 1)
		current[path[#path]] = value
	end

	-- Module functions
	logic(ModuleScript, path, current[path[#path]], value, params)
end

---------------------------------------- Modify ----------------------------------------

function ModuleSync.Modify(
	ModuleScript: ModuleScript,
	path: "Path",
	value: number,
	operation: "Operation",
	params: "Arguments for Hook Function(s)"
)
	local module = getModuleContents(ModuleScript)
	if not module then
		return
	end

	-- Set value at index
	local current = getPath(module, path, 1)
	if operation == ("+" or "+=") then
		current[path[#path]] += value
	elseif operation == ("-" or "-=") then
		current[path[#path]] -= value
	elseif operation == ("*" or "*=") then
		current[path[#path]] *= value
	elseif operation == ("/" or "/=") then
		current[path[#path]] /= value
	elseif operation == ("%" or "%=") then
		current[path[#path]] %= value
	end

	-- Module functions
	logic(ModuleScript, path, current[path[#path]], current[path[#path]], params)
end

---------------------------------------- Insert ----------------------------------------

function ModuleSync.Insert(
	ModuleScript: ModuleScript,
	path: "Path",
	value: "Value",
	params: "Arguments for Hook Function(s)"
)
	local module = getModuleContents(ModuleScript)
	if not module then
		return
	end

	-- Set value at index
	local current = getPath(module, path, 0)
	table.insert(current, value)

	-- Get last index and update path
	local last = 0
	for i in current do
		if type(i) == "number" and i > last then
			last = i
		end
	end
	table.insert(path, last)

	-- Module functions
	logic(ModuleScript, path, current, value, params, true)
end

---------------------------------------- Remove ----------------------------------------

function ModuleSync.Remove(
	ModuleScript: ModuleScript,
	path: "Path",
	index: "Index in Table",
	params: "Arguments for Hook Function(s)"
)
	local module = getModuleContents(ModuleScript)
	if not module then
		return
	end

	-- Set value at index
	local current = getPath(module, path, 0)
	local removed = current[index]
	table.remove(current, index)

	-- Update path
	table.insert(path, index)

	-- Module functions
	logic(ModuleScript, path, current, removed, params, false)
end

---------------------------------------- Move ----------------------------------------

function ModuleSync.Move(
	ModuleScript: ModuleScript,
	path: "Path",
	value: "Value",
	params: "Arguments for Hook Function(s)"
)
	local module = getModuleContents(ModuleScript)
	if not module then
		return
	end

	-- Set value at index
	local current = getPath(module, path, 0)
	table.move(value, 1, #value, #current + 1, current)

	-- Module functions
	logic(ModuleScript, path, current, value, params, true)
end

---------------------------------------- Not ----------------------------------------

function ModuleSync.Not(ModuleScript: ModuleScript, path: "Path", params: "Arguments for Hook Function(s)")
	local module = getModuleContents(ModuleScript)
	if not module then
		return
	end

	-- Set value at index
	local current = getPath(module, path, 1)
	current[path[#path]] = not current[path[#path]]

	-- Module functions
	logic(ModuleScript, path, current[path[#path]], current[path[#path]], params)
end

---------------------------------------- Concat ----------------------------------------

function ModuleSync.Concat(
	ModuleScript: ModuleScript,
	path: "Path",
	value: "Value",
	params: "Arguments for Hook Function(s)"
)
	local module = getModuleContents(ModuleScript)
	if not module then
		return
	end

	-- Set value at index
	local current = getPath(module, path, 1)
	current[path[#path]] = current[path[#path]] .. value

	-- Module functions
	logic(ModuleScript, path, current[path[#path]], value, params)
end

return ModuleSync
