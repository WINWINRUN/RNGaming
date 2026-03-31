# Changelog

## 2026-03-30

- Rebuilt the repo from a model-first scaffold into a terrain-first Roblox generator.
- Added deterministic terrain profiles for `TemperateFrontier`, `DesertCanyon`, and `SkyArchipelago`.
- Added Studio helpers for edit-time terrain generation and safe managed-region clearing.
- Added terrain review and preview tooling driven by the same profile manifest.
- Kept experience isolation through project-folder separation and `AllowedPlaceIds`.
- Vendored the Roblox Studio MCP bridge code and source used for Studio CLI access under `integrations/roblox-studio-mcp`.
