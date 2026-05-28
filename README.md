# ModuleSync

**ModuleSync** is a Roblox Luau utility that synchronizes ModuleScript data from the server to all clients in real time. Set values once on the server and have them automatically reflected on every connected client — with support for hook functions, path-based exclusions, and a full suite of table and primitive manipulation methods.
Created 9/21/2025

---

## Features

| Method | Description | Equivalent |
|---|---|---|
| `.Set()` | Set a value at a path | `=` |
| `.Modify()` | Arithmetic on numeric values | `+=` `-=` `*=` `/=` `%=` |
| `.Insert()` | Insert into a table | `table.insert` |
| `.Remove()` | Remove from a table by index | `table.remove` |
| `.Move()` | Append all elements from one table into another | `table.move` |
| `.Not()` | Toggle a boolean | `x = not x` |
| `.Concat()` | Append to a string | `..` |
| `.OnChange()` | Register a hook that fires when a path changes | — |

---

## Setup

1. Place the `ModuleSync` ModuleScript somewhere accessible by **both** the server and client (e.g. `ReplicatedStorage`).
2. Place your data ModuleScript(s) somewhere accessible by both sides as well.
3. `require` ModuleSync on the **server** (in a `Script`).
4. `require` ModuleSync on the **client** (in a `LocalScript`).
5. Use ModuleSync functions **only on the server** to synchronize data.

```lua
-- Server
local ModuleSync = require(game.ReplicatedStorage.ModuleSync)
local DataModule = game.ReplicatedStorage.DataModule

ModuleSync.Set(DataModule, {"Coins"}, 100)
```

```lua
-- Client
local ModuleSync = require(game.ReplicatedStorage.ModuleSync)
-- Changes made on the server will automatically be reflected here.
```

> **Important:** Only use ModuleSync functions on the **server**. Setting values directly in a ModuleScript, or calling ModuleSync functions on the client, will cause desynchronization.

---

## API Reference

### `ModuleSync.Set(ModuleScript, path, value, params?)`

Sets a value at the given path inside a module.

- `path` — Array of keys describing where to write. Pass `{}` to replace the entire module table.
- `params` — Optional table passed to any triggered hook functions.

```lua
ModuleSync.Set(DataModule, {"Name"}, "Max")
ModuleSync.Set(DataModule, {"Stats", "Level"}, 42)
ModuleSync.Set(DataModule, {}, {Coins = 0, Level = 1})  -- replace entire module
```

---

### `ModuleSync.Modify(ModuleScript, path, value, operation, params?)`

Performs an arithmetic operation on a numeric value at the given path.

- `operation` — One of `"+"`, `"-"`, `"*"`, `"/"`, `"%"` (or their `=` variants).

```lua
ModuleSync.Modify(DataModule, {"Stats", "Coins"}, 50, "+")     -- Coins += 50
ModuleSync.Modify(DataModule, {"Stats", "HP"}, 10, "-")        -- HP -= 10
ModuleSync.Modify(DataModule, {"Stats", "Multiplier"}, 2, "*") -- Multiplier *= 2
```

---

### `ModuleSync.Insert(ModuleScript, path, value, params?)`

Inserts `value` into the table at `path` (equivalent to `table.insert`).

```lua
ModuleSync.Insert(DataModule, {"Inventory"}, "Iron Sword")
```

---

### `ModuleSync.Remove(ModuleScript, path, index, params?)`

Removes the entry at numeric `index` from the table at `path` (equivalent to `table.remove`).

```lua
ModuleSync.Remove(DataModule, {"Inventory"}, 1)  -- remove first item
```

---

### `ModuleSync.Move(ModuleScript, path, value, params?)`

Appends all elements from `value` (a table) into the table at `path`.

```lua
ModuleSync.Move(DataModule, {"Inventory"}, {101, 102, 103})
```

---

### `ModuleSync.Not(ModuleScript, path, params?)`

Toggles the boolean value at `path`.

```lua
ModuleSync.Not(DataModule, {"Settings", "MusicEnabled"})
```

---

### `ModuleSync.Concat(ModuleScript, path, value, params?)`

Appends `value` to the string at `path`.

```lua
ModuleSync.Concat(DataModule, {"Profile", "Bio"}, " (Veteran)")
```

---

### `ModuleSync.OnChange(ModuleScript, path, params?, func)`

Registers a hook function that fires whenever the specified path (or a child of it) changes.

**Callback signature:**
```lua
function(currentValue, changedValue, fullPath, customParams, isAddedToTable)
```

| Argument | Description |
|---|---|
| `currentValue` | The value currently at the watched path |
| `changedValue` | The value that was set or modified |
| `fullPath` | The full path that changed |
| `customParams` | The `params` passed to the triggering ModuleSync call |
| `isAddedToTable` | `true` for `.Insert`/`.Move`, `false` for `.Remove`, `nil` for all others |

**Params options:**

- `{'Exact Match'}` — Hook only fires when the path matches exactly, not for nested changes.
- `nil` or `{}` — Hook fires for the path and any nested paths beneath it.

```lua
-- Fires whenever Coins changes exactly
ModuleSync.OnChange(DataModule, {"Stats", "Coins"}, {"Exact Match"}, function(current, changed, path, params)
    print("Coins changed to", changed)
end)

-- Fires whenever anything inside Stats changes
ModuleSync.OnChange(DataModule, {"Stats"}, {}, function(current, changed, path, params)
    print("Stats updated at", table.concat(path, "."))
end)
```

> Hook functions run on **both server and client** when triggered from the server. They do **not** run on the client for excluded paths.

---

## Excluding Modules and Paths

Use `ModuleSync.Excluded` on the server to prevent certain modules or specific paths from replicating to clients.

```lua
-- Exclude an entire module (no data from this module is sent to clients)
ModuleSync.Excluded[game.ServerScriptService.SecretData] = {}

-- Exclude a specific path within a module
table.insert(ModuleSync.Excluded[game.ReplicatedStorage.DataModule], {"Internal", "AdminFlag"})

-- Remove an exclusion
ModuleSync.Excluded[game.ReplicatedStorage.DataModule] = nil
```

> Modules inside `ServerScriptService` are never replicated to clients regardless of exclusion settings.

---

## Accessing Data

Since ModuleSync writes directly into the required module table, you can read data the normal way:

```lua
local data = require(game.ReplicatedStorage.DataModule)

ModuleSync.Set(DataModule, {"Coins"}, 500)
print(data.Coins)  -- 500
```

---

## How It Works

1. On server start, a `RemoteEvent` is created inside the ModuleSync script.
2. When a client loads, it fires a `Loaded` event to the server.
3. The server responds by sending the full current state of all previously edited modules to that client.
4. From that point on, any ModuleSync call on the server automatically fires the corresponding change to all clients via `FireAllClients`.
5. The client receives the change and calls `ModuleSync.Set` locally to mirror it — keeping the required module table in sync.

---

## Notes

- ModuleSync functions must be called **from the server** to trigger replication.
- Calling ModuleSync functions on the client or setting module values directly will **not** replicate and will cause the server and client to fall out of sync.
- Late-joining players automatically receive the full current state of all edited modules.
