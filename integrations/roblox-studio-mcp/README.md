# Roblox Studio MCP Bridge

This folder vendors the Roblox Studio CLI bridge code used in this project.

Included here:
- `studio-bridge.js`
- `studio-bridge.cmd`
- `studio-bridge.ps1`
- `LOCAL_BRIDGE_README.md`
- `studio-rust-mcp-server/`

What this gives you:
- a local CLI wrapper that talks to Roblox Studio through MCP
- the Rust MCP server source used by the bridge
- the Luau Studio plugin source under `studio-rust-mcp-server/plugin/`

What is not vendored here:
- the installed Studio plugin binary in `C:\Users\<you>\AppData\Local\Roblox\Plugins`
- the compiled `rbx-studio-mcp.exe` binary

To use the bridge after cloning:
1. Install or build `rbx-studio-mcp.exe`.
2. Install the Studio plugin side.
3. Either place the executable next to `studio-bridge.js`, or set `RBX_MCP_SERVER` to its path.
4. Open a real place in Roblox Studio.
5. Run bridge commands such as:

```powershell
.\integrations\roblox-studio-mcp\studio-bridge.cmd tools
.\integrations\roblox-studio-mcp\studio-bridge.cmd mode
.\integrations\roblox-studio-mcp\studio-bridge.cmd run-code "print(game.Name)"
```

The vendored upstream reference source is in:
- [studio-rust-mcp-server/README.md](/c:/Users/Mikey/roblox%20tycoon/integrations/roblox-studio-mcp/studio-rust-mcp-server/README.md)
