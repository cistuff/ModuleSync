local ModuleSync = require(game.ReplicatedStorage.ModuleSync)

-- print(require(game.ReplicatedStorage.Shared)) -- Example of how to access data

ModuleSync.OnChange(
	game.ReplicatedStorage.Shared,
	{ "Set" },
	{},
	function(data, value, path, params, isAdd) -- example hook function
		print("Example Hook Function:\n", data, value, path, params, isAdd)
	end
)

task.wait(2) -- for testing so modifications occur after player has loaded in
ModuleSync.Set(game.ReplicatedStorage.Shared, { "Set" }, nil)
ModuleSync.Set(game.ReplicatedStorage.Shared, { "Modify" }, -1)
ModuleSync.Set(game.ReplicatedStorage.Shared, { "Insert" }, {})
ModuleSync.Set(game.ReplicatedStorage.Shared, { "Remove" }, { false })
ModuleSync.Set(game.ReplicatedStorage.Shared, { "Not" }, false)
ModuleSync.Set(game.ReplicatedStorage.Shared, { "Concat" }, "Concat")

ModuleSync.Set(game.ReplicatedStorage.Shared, { "Set" }, true)
ModuleSync.Modify(game.ReplicatedStorage.Shared, { "Modify" }, 2, "+")
ModuleSync.Insert(game.ReplicatedStorage.Shared, { "Insert" }, true)
ModuleSync.Remove(game.ReplicatedStorage.Shared, { "Remove" }, 1)
ModuleSync.Not(game.ReplicatedStorage.Shared, { "Not" })
ModuleSync.Concat(game.ReplicatedStorage.Shared, { "Concat" }, " works")

while task.wait(1) do
	print(require(game.ReplicatedStorage.Shared))
end
