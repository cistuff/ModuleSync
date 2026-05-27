local ModuleSync = require(game.ReplicatedStorage.ModuleSync)

-- this doesnt print because the value is updated before the function runs so it doesnt detect the change

while task.wait(1) do
	print(require(game.ReplicatedStorage.Shared))
end
