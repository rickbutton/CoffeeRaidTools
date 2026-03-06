# CLAUDE.md

## Project Overview

CoffeeRaidTools is a World of Warcraft addon for raid management, built on Ace3.

## Build

```bash
pnpm install           # Install dependencies
pnpm run build         # Build to .release/CoffeeRaidTools/
pnpm run build:full    # Full build with external library checkout
pnpm run build:watch   # Watch mode
```

## Architecture

### File Structure (loading order from TOC)
1. `externals.xml` — Ace3 and other libraries
2. `CoffeeRaidTools.lua` — Entry point (AceAddon, AceConsole, AceComm)
3. `Util.lua` — Shared utilities
4. `Nicknames.lua` — Player nickname mappings
5. `Versions.lua` — Version tracking and comparisons
6. `ForceAddonSettings.lua` — Automatic addon settings enforcement (NSRT, TimelineReminders)
7. `Interface/Minimap.lua` — Minimap button
8. `Interface/Frame.lua` — Main frame controller (closes on ESC)
9. `Interface/Tabs/` — Local, Raid, Settings
10. `ReadyCheck.lua` — Ready check tracking
11. `Tests/TestRunner.lua` + `Tests/*.lua` — WoWUnit test suites

### Key Patterns
- Private namespace via `select(2, ...)` — use `Private` for all internal state
- Public API only on the `CoffeeRaidTools` global
- Tab registration via `Private:RegisterTab()`
- Chat commands: `/crt` (open frame), `/crt debug` (toggle debug mode)

### Saved Variables
- `CoffeeRaidToolsSaved` — per-account, loaded before scripts execute (`LoadSavedVariablesFirst: 1`)
- Initialize with defaults in main addon file; modifications persist automatically

## Type Definitions

WoW API and library type annotations come from the `ketho.wow-api` VS Code extension. To find annotation files:

```
~/.vscode/extensions/ketho.wow-api-*/Annotations/
```

Key directories under `Annotations/`:
- `Core/Blizzard_APIDocumentationGenerated/` — WoW C_ API docs
- `Core/Data/` — Enums and global data types
- `Core/Widget/` — Raw WoW widget types (prefer Ace3GUI wrappers)
- `Core/Libraries/` — Only use types for libraries in `.pkgmeta` (Ace3, LibDeflate, LibSerialize, CallbackHandler)

## Code Style

### Lua (5.1)
- Always use `local` unless it must be global
- Use LuaLS annotations for table shapes, parameters, and complex return types
- Annotate `AceGUI:Create()` with specific widget type (e.g., `---@type AceGUILabel`)
- Prefer Ace3 over direct WoW API; check `.luaTypes/Libraries/Ace3` for public methods before accessing private widget fields
- Only comment genuinely complex logic

### General
- Never create duplicate/versioned files — edit in place
- Ask clarifying questions if requirements are ambiguous
