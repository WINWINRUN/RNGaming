# Roblox Studio Bridge

This workspace now has a working local bridge into Roblox Studio.

What is installed:
- `rbx-studio-mcp.exe` in this folder: the official Roblox open-source MCP server fallback.
- `MCPStudioPlugin.rbxm` in `C:\Users\Mikey\AppData\Local\Roblox\Plugins`: the Studio plugin side.
- `studio-bridge.js` and `studio-bridge.cmd`: simple terminal wrappers for calling Studio tools.

Important:
- Open a real place in Roblox Studio before using the bridge.
- The Studio start page by itself does not fully load the user plugin.
- When the place-backed Studio session is ready, Studio output includes:
  `The MCP Studio plugin is ready for prompts.`

Examples:

```powershell
.\studio-bridge.cmd tools
.\studio-bridge.cmd mode
.\studio-bridge.cmd run-code "print('hello from codex', game.Name)"
.\studio-bridge.cmd run-code-file .\some-script.luau
.\studio-bridge.cmd console
.\studio-bridge.cmd play start_play
.\studio-bridge.cmd play stop
.\studio-bridge.cmd call run_code "{\"command\":\"print(#workspace:GetChildren())\"}"
```

If you want JSON back instead of plain text:

```powershell
.\studio-bridge.cmd tools --json
.\studio-bridge.cmd mode --json
```

If the bridge says no tools are available:
1. Make sure a place is actually open in Studio.
2. Wait a few seconds for the plugin to initialize.
3. Check Studio output for `The MCP Studio plugin is ready for prompts.`
