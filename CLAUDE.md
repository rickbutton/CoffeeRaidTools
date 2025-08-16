# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CoffeeRaidTools is a World of Warcraft addon that provides raid management utilities. It's built using the Ace3 framework and integrates with WeakAuras.

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

### WeakAuras Integration
- `scripts/compiler/` contains WeakAuras string encoding/decoding tools
- Uses LibDeflate and LibSerialize for compression
- Aura templates stored in `scripts/compiler/auras/`

## File Loading Order
Defined in `CoffeeRaidTools.toc`:
1. External libraries (`externals.xml`)
2. Main addon file
3. Version system
4. Interface components (Frame → Tabs)

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
- **Error handling**: Return `(result, error)` tuples only when errors are recoverable/reportable. Otherwise let errors propagate naturally
- **No premature optimization**: Don't cache globals for performance

#### Table and String Operations
- **Tables**: Prefer literal construction. Use incremental only when necessary or cleaner
- **String concat**: Use `..` for simple joins, `string.format` for complex formatting, `table.concat` for lists
- **Loops**: Choose based on readability, not micro-optimization

#### WoW Integration
- **Always prefer Ace3** over direct WoW API calls when available
- **Global namespace**: Only add to `CoffeeRaidTools` global for public API
- **Internal code**: Use `Private` namespace for all internal state and functions

### Anti-patterns to Avoid
- Creating duplicate/versioned files
- Unnecessary global pollution
- Manual string concatenation in loops (use `table.concat`)
- Direct WoW API usage when Ace3 provides an abstraction
- Adding methods to `CoffeeRaidTools` that aren't public API