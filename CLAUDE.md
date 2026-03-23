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
3. `Core/` — Shared infrastructure (Util, Nicknames, Versions)
4. `Features/` — Self-contained feature modules (ForceAddonSettings, ReadyCheck, Break, GearWarnings)
5. `Interface/Minimap.lua` — Minimap button
6. `Interface/Frame.lua` — Main frame controller (closes on ESC)
7. `Interface/Tabs/` — Local, Raid, Settings
8. `Tests/TestRunner.lua` + `Tests/*.lua` — WoWUnit test suites

### Key Patterns
- Private namespace via `select(2, ...)` — use `Private` for all internal state
- Public API only on the `CoffeeRaidTools` global
- Blizzard API wrappers live on `Private.Blizz` — never call WoW globals directly from feature code
- Files that need Blizzard APIs should define `local Blizz = Private.Blizz` near the top (with `---@type Blizz` annotation)
- Tab registration via `Private:RegisterTab()`
- Chat commands: `/crt` (open frame), `/crt debug` (toggle debug mode)

### Saved Variables
- `CoffeeRaidToolsSaved` — per-account, loaded before scripts execute (`LoadSavedVariablesFirst: 1`)
- Initialize with defaults in main addon file; modifications persist automatically

## Type Definitions

WoW API and library type annotations come from the `ketho.wow-api` VS Code extension (`~/.vscode/extensions/ketho.wow-api-*/Annotations/`). LuaLS is configured via `.luarc.json` which references the extension's annotation paths.

Key annotation directories:
- `Core/Blizzard_APIDocumentationGenerated/` — WoW C_ API docs
- `Core/Data/` — Enums and global data types
- `Core/Widget/` — Raw WoW widget types (prefer Ace3GUI wrappers)
- `Core/Libraries/` — Only use types for libraries in `.pkgmeta` (Ace3, LibDeflate, LibSerialize, CallbackHandler)

## Diagnostics

`.luarc.json` and `.luacheckrc` are gitignored and generated — do not edit by hand. WoW globals are defined in `scripts/wow-globals.js`.

```bash
pnpm run check            # Generate .luarc.json + run LuaLS type diagnostics (matches VS Code)
pnpm run lint             # Generate .luacheckrc + run luacheck (unused vars, style)
pnpm run format           # Format with StyLua
pnpm run format:check     # Check formatting without modifying
```

## Vendor References

`vendor/` contains read-only checkouts of addons we interop with. **Never modify code in `vendor/`** — these are for reading source only.

- `vendor/wow-ui-source` — Blizzard UI source (blobless clone)
- `vendor/BigWigs` — BigWigs boss mod
- `vendor/NorthernSkyRaidTools` — NSRT raid tool

Run `pnpm run vendor` to clone or update all vendor repos. Do this before implementing features that interop with BigWigs or NSRT to ensure you're referencing the latest code.

## Code Style

### Lua (5.1)
- Always use `local` unless it must be global
- Use LuaLS annotations for table shapes, parameters, and complex return types
- Annotate `AceGUI:Create()` with specific widget type (e.g., `---@type AceGUILabel`)
- Prefer Ace3 over direct WoW API; check Ace3 library annotations for public methods before accessing private widget fields
- Only comment genuinely complex logic

### Testing
- `Replace` in tests should only target tables we own (`Private`, `Blizz`, `CoffeeRaidTools`)
- Never use `Replace` on Blizzard-provided objects or global scope (`_G`) directly
- If code under test calls a Blizzard API, the API should be wrapped in `Private.Blizz` and replaced on `Blizz` in the test
- If a Blizzard API is not yet wrapped, add it to `Private.Blizz` in `CoffeeRaidTools.lua` rather than replacing on `_G`

### General
- Never create duplicate/versioned files — edit in place
- Ask clarifying questions if requirements are ambiguous
