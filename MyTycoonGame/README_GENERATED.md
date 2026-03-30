
# MyTycoon

This Roblox project was generated automatically with the `tycoon` template.

## What is included

- Rojo project config: `default.project.json`
- Shared config module: `shared/Config.lua`
- Optional creator group metadata in `shared/Config.lua`
- Server bootstrap: `server/MainServer.lua`
- Client bootstrap: `client/MainClient.lua`
- Test model folder: `test/`
- Synced Studio model gallery: `test/SyncedModels/*.model.json`
- Studio helper scripts: `studio/`
- Install/use guide: `INSTALL_AND_USAGE.md`
- Template-specific helper modules

## How to use

1. Install Rojo: https://rojo.space
2. Open a terminal in this folder.
3. Run:
   ```powershell
   rojo serve --project default.project.json
   ```
4. In Roblox Studio, connect to the Rojo server.
5. Browse `ServerStorage/TestWorldModels/SyncedModels` for the static sample assets that sync immediately.
6. Run the experience once if you also want the runtime-built `ServerStorage/TestWorldModels/GeneratedModels` folder.
7. Use `studio/SpawnTestModels.plugin.lua` or `studio/SpawnTestModels.command.lua` to preview the synced gallery and sky-island hub in `Workspace`.

## Template

Tycoon-style sky island hub with money, leaderstats, island bridges, and shop-to-RNG travel lanes.

## Notes

- The generated code is a starting point; customize it in Roblox Studio.
- The `test/` folder contains both synced `.model.json` assets and simple original runtime model builders.
- The `studio/` folder contains local Studio helpers and is not synced into the live game by Rojo.
- Avoid Blender imports unless you need custom meshes.
- Use Roblox Toolbox assets and `StarterGui` for rapid iteration.
