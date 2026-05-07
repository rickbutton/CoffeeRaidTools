# CLAUDE.md

## Project Overview

CoffeeRaidTools is a World of Warcraft addon for raid management, built on Ace3.

## Build

```bash
pnpm install           # Install dependencies
pnpm run build         # Build to .release/CoffeeRaidTools/
pnpm run build:full    # Full build with external library checkout
pnpm run build:watch   # Watch mode
pnpm test              # Run busted unit tests (requires lua5.1 + busted on PATH)
```

## Architecture

### File Structure (loading order from TOC)
1. `externals.xml` — Ace3 and other libraries
2. `CoffeeRaidTools.lua` — Entry point (AceAddon, AceConsole, AceComm)
3. `Core/` — Shared infrastructure (Util, Nicknames, Versions, UnitMap, Note)
4. `Features/` — Self-contained feature modules (ForceAddonSettings, ReadyCheck, Break, GearWarnings)
5. `EncounterTools/` — Boss-specific modules (note parsing + widgets tightly coupled to one encounter)
6. `Interface/Minimap.lua` — Minimap button
7. `Interface/Frame.lua` — Main frame controller (closes on ESC)
8. `Interface/Tabs/` — Local, Raid, Settings

Unit tests live in `spec/` and run via [busted](https://lunarmodules.github.io/busted/); see the "Testing" section below.

### Key Patterns
- Private namespace via `select(2, ...)` — use `Private` for all internal state
- Public API only on the `CoffeeRaidTools` global
- Call WoW APIs directly (`IsInRaid()`, `C_AddOns.IsAddOnLoaded()`, etc.) — tests mock them on `_G` / the `C_*` namespace tables
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
- Unit tests use [busted](https://lunarmodules.github.io/busted/) and live in `spec/*_spec.lua`. Run with `pnpm test` (invokes `busted --lua=lua5.1`).
- Test harness: `.busted` points busted at `spec/setup.lua`, which loads `spec/helpers/wow_mocks.lua` (WoW global stubs), then `spec/helpers/addon_loader.lua` (Ace3 libs from `.release/CoffeeRaidTools/Libs/` + every addon `.lua` file), then `spec/helpers/mocks.lua` (the `Replace`/`Restore` mocking helpers). The first `pnpm test` run shells out to `pnpm run build:full` to populate `Libs/`.
- Spec files get `Private`, `CoffeeRaidTools`, `Replace`, and `Restore` as globals. Call `after_each(Restore)` to unwind `Replace` calls between tests.
- Mock WoW APIs wherever the addon calls them: `Replace("IsInRaid", fn)` for plain globals (two-arg form sets `_G.IsInRaid`), `Replace(C_AddOns, "IsAddOnLoaded", fn)` for namespaced APIs.
- When adding a new WoW API call to the addon: if Ace3 or the addon needs it at load time (not just in a test), add a stub to `spec/helpers/wow_mocks.lua` so the addon loads cleanly under busted.

### General
- Never create duplicate/versioned files — edit in place
- Ask clarifying questions if requirements are ambiguous

## NSRT Watch — `@claude` Responder Policy

A nightly Claude Code routine watches `Reloe/NorthernSkyRaidTools` and opens
GitHub issues labeled `nsrt-watch` (plus one of `nsrt-sounds`, `nsrt-settings`,
`nsrt-timers`) when upstream changes something we might want to replicate or
respond to. Run state lives in a pinned issue labeled `nsrt-watch-state`.

When invoked via `@claude` on an issue labeled `nsrt-watch`, follow these rules.

### When to act
Only respond if the comment is from the repo owner AND either:
- mentions `@claude` directly, OR
- starts a line with a directive keyword: `implement:`, `investigate:`,
  `draft:`, `skip:`, `explain:`

If neither applies, do nothing.

### Per directive
- `implement: <instruction>` — open a PR making the code change on branch
  `claude/nsrt-watch-<issue-number>-<slug>`. PR body links the issue and
  states what changed. Do NOT close the issue.
- `investigate: <question>` — post a comment with file+line references from
  both this repo and `vendor/NorthernSkyRaidTools`. No code changes.
- `draft: <instruction>` — post a comment with a proposed patch as a fenced
  diff block. Do not open a PR unless a later `implement:` comment arrives.
- `skip: <reason>` — post a brief acknowledgment. Do nothing else.
- `explain: <question>` — same as `investigate:` but for conceptual questions.
- `@claude` with no directive keyword — treat as `investigate:` for the
  natural-language request.

### Hard rules
- Never close `nsrt-watch` issues. The user decides when they're resolved.
- Never edit the `nsrt-watch-state` issue — it belongs to the nightly routine.
- If a `skip:` is followed by a later owner comment, the latest comment wins.
- Scope code changes to the issue's original category (sounds/settings/timers).
  If `implement:` asks for something outside that scope, refuse in a comment
  and ask for a fresh issue.
- When linking to NSRT code, pin to a specific commit SHA, not a branch.
- Run `pnpm run vendor` before investigating — `vendor/NorthernSkyRaidTools`
  must be present and current.

### Context for investigations
Our NSRT interop surfaces (useful for answering `investigate:` / `explain:`):
- `Features/ForceAddonSettings.lua` — enforces `NSRT.ReadyCheckSettings.*`,
  `NSRT.EncounterAlerts[id].enabled` (IDs 3176–3183, 3306), `NSRT.QoL.*`,
  `NSRT.ReminderSettings.*`, and `NSRT.Settings.*` nickname keys. On
  profile-capable NSRT (i.e. when `type(NSRT.Profiles) == "table"`) the
  enforcement is applied to a dedicated `NSRT.Profiles["Coffee"]` profile
  seeded from the user's active profile, with the flat `NSRT.*` tables
  populated via a mirror of `NSI:LoadProfile`'s copy loop — keep
  `PROFILE_IGNORED_KEYS` and `CopyProfileIntoActive` in sync with
  `vendor/NorthernSkyRaidTools/Profiles.lua`. Users who switch away from
  the Coffee profile are left alone (visible deviation only). On
  pre-profile NSRT the legacy direct-mutation path runs instead.
- `scripts/private-aura-sounds.json` — source of truth for our private aura
  sound overrides; compiled into `Features/PrivateAuraSoundsData.lua`.
- `Features/BigWigsOverrides.lua` — disables BigWigs' built-in private aura
  sounds for spellIDs we handle.
- `Core/Versions.lua` — hashes `NSAPI:GetReminderString()` output and
  broadcasts it as `NSRTHASH`; also broadcasts `NSRT.CurrentProfile` as
  `NSRTPROFILE` so the Raid tab flags users off the `Coffee` profile. We
  do not override NSRT timers.
