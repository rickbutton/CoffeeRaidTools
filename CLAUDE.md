# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CoffeeRaidTools is a World of Warcraft addon that provides raid management utilities. It's built using the Ace3 framework.

## Build Commands

```bash
# Install dependencies
pnpm install

# Build addon (copies to .release/CoffeeRaidTools/)
pnpm run build

# Full build with external library checkout
pnpm run build:full

# Watch mode for development
pnpm run build:watch
```

The build process uses `scripts/release.sh` (Unix) or `scripts/release.bat` (Windows) to package the addon into `.release/CoffeeRaidTools/`.

## Architecture

### Core Structure
- **Main addon**: `CoffeeRaidTools.lua` - Entry point using Ace3 framework (AceAddon, AceConsole, AceComm)
- **Interface system**: Tab-based UI with registration pattern
  - Frame controller: `Interface/Frame.lua`
  - Tab modules: `Interface/Tabs/` (Self, Raid, Guild, Settings)
- **Version tracking**: `Versions.lua` - Handles version snapshots and comparisons

### Key Patterns
- Uses private namespace pattern (`select(2, ...)`) for internal state
- Tab registration system via `Private:RegisterTab()`
- Chat command: `/crt` opens the main frame
- Dependencies loaded via `externals.xml`

### Saved Variables (Persistent State)
- **Configuration**: `CoffeeRaidToolsSaved` is saved per-account (defined in TOC)
- **Early Loading**: Uses `LoadSavedVariablesFirst: 1` directive
  - Saved variables are loaded BEFORE addon scripts execute
  - No need to wait for `ADDON_LOADED` event - variables available immediately
- **Data Limitations**: Only strings, booleans, numbers, and tables can be saved
  - Cannot save functions, userdata, or coroutines
  - Tables can contain nested tables and supported types
- **Best Practices**: Initialize variables directly in main addon file
  - Check if `CoffeeRaidToolsSaved` exists and provide defaults if nil
  - Modifications persist automatically between sessions

## File Loading Order
Defined in `CoffeeRaidTools.toc`:
1. External libraries (`externals.xml`)
2. Main addon file
3. Version system
4. Interface components (Frame → Tabs)

## Type Definitions (.luaTypes)

The `.luaTypes` directory contains LuaLS (Lua Language Server) type annotations for WoW APIs and libraries. These provide IDE support for autocomplete, type checking, and documentation.

### Directory Structure

#### Core/
- **Blizzard_APIDocumentationGenerated/**: Auto-generated docs for C_ namespaced APIs (C_AuctionHouse, C_Achievement, etc.)
- **Data/**: Various WoW global data types and Enums - useful when APIs require specific enum values
- **FrameXML/**: Implementation types for FrameXML features
- **Libraries/**: Type definitions for common addon libraries
  - **IMPORTANT**: Only libraries listed in `.pkgmeta` are available (Ace3 components, LibDeflate, LibSerialize, CallbackHandler)
  - Other library types are present but should not be referenced unless adding them as dependencies
- **Lua/**: Standard Lua 5.1 library types
- **Type/**: Core WoW type definitions consumed by APIs
- **Widget/**: Raw WoW widget types (Frame, Button, EditBox, etc.)
  - Ace3GUI wraps these - prefer Ace3GUI unless you need direct widget access

#### FrameXML/
- **Annotations/**: Frame templates and mixin definitions from NumyAddon/FramexmlAnnotations
- **AddOns/**: Full source of WoW's built-in UI (implemented as privileged addons)
  - Useful when interacting with existing game UI
  - Not needed when creating new UI - use Core APIs instead

### Usage Guidelines

- Type definitions are automatically loaded by LuaLS via `.vscode/settings.json`
- When using WoW APIs, reference the types in `Core/Blizzard_APIDocumentationGenerated/`
- For enum values, check `Core/Data/` for the appropriate Enum definitions
- Only use library types for libraries we actually have (check `.pkgmeta`)
- Prefer Ace3 abstractions over raw widgets unless absolutely necessary

## Development Guidelines

### Communication Style
- Keep responses brief and direct
- No personality or unnecessary elaboration
- Focus on technical accuracy

### Before Making Changes
- Ask clarifying questions if there's any ambiguity
- Never create "new" versions of existing files - always edit in place
- Understand the intent fully before implementing

### Code Style

#### Comments
- Only add comments for genuinely complex logic
- Write self-documenting code that doesn't need comments
- Clean, understandable code > commented code

#### Lua Conventions (5.1)
- **Always use local** for variables and functions unless they must be global
- **Type annotations**: Use LuaLS annotations for all table shapes, function parameters, and complex return types
- **AceGUI type annotations**: Always annotate `AceGUI:Create()` calls with the specific widget type (e.g., `---@type AceGUILabel`)
- **Error handling**: Return `(result, error)` tuples only when errors are recoverable/reportable. Otherwise let errors propagate naturally
- **No premature optimization**: Don't cache globals for performance

#### Table and String Operations
- **Tables**: Prefer literal construction. Use incremental only when necessary or cleaner
- **String concat**: Use `..` for simple joins, `string.format` for complex formatting, `table.concat` for lists
- **Loops**: Choose based on readability, not micro-optimization

#### WoW Integration
- **Always prefer Ace3** over direct WoW API calls when available
- **Check Ace3 API first**: Before accessing private fields (e.g., `widget.frame`), search `.luaTypes/Libraries/Ace3` for public methods
- **Global namespace**: Only add to `CoffeeRaidTools` global for public API
- **Internal code**: Use `Private` namespace for all internal state and functions

### Anti-patterns to Avoid
- Creating duplicate/versioned files
- Unnecessary global pollution
- Manual string concatenation in loops (use `table.concat`)
- Direct WoW API usage when Ace3 provides an abstraction
- Adding methods to `CoffeeRaidTools` that aren't public API
