const fs = require("fs");
const path = require("path");
const os = require("os");
const { execSync } = require("child_process");

const projectRoot = path.join(__dirname, "..");

const luaFiles = "*.lua Interface/*.lua Interface/Tabs/*.lua Tests/*.lua";

function run(cmd) {
  try {
    execSync(cmd, { stdio: "inherit", cwd: projectRoot, shell: "bash" });
  } catch (e) {
    process.exit(e.status || 1);
  }
}

// Read VS Code settings to get ketho extension's auto-added globals
function readVSCodeGlobals() {
  try {
    const content = fs.readFileSync(path.join(projectRoot, ".vscode", "settings.json"), "utf-8");
    const cleaned = content.replace(/,(\s*[}\]])/g, "$1");
    return JSON.parse(cleaned)["Lua.diagnostics.globals"] || [];
  } catch {
    return [];
  }
}

function mergeGlobals(base) {
  const seen = new Set(base);
  for (const g of readVSCodeGlobals()) {
    if (!seen.has(g)) {
      base.push(g);
      seen.add(g);
    }
  }
  return base;
}

// Read-only WoW API globals (luacheck needs these explicitly; LuaLS gets them from annotations)
const readOnlyGlobals = [
  "tinsert", "wipe",
  "BNGetInfo", "C_AddOns", "C_Secrets", "C_Timer", "CreateFrame",
  "GetGuildInfo", "GetGuildInfoText", "GetNormalizedRealmName", "GetNumGroupMembers", "GetNumSubgroupMembers",
  "GetTime", "IsInGroup", "IsInRaid", "ReloadUI",
  "StaticPopup_Hide", "StaticPopup_Show", "StaticPopup_Visible",
  "InCombatLockdown",
  "UnitClassBase", "UnitExists", "UnitGUID", "UnitIsUnit", "UnitNameUnmodified",
  "issecretvalue", "canaccessvalue", "issecrettable", "canaccesstable",
  "GameTooltip", "UIParent", "UISpecialFrames",
  "GameFontHighlightSmall", "GameFontNormal", "GameFontNormalLarge", "GameFontNormalSmall",
  "LE_PARTY_CATEGORY_INSTANCE", "LE_PARTY_CATEGORY_HOME", "RAID_CLASS_COLORS",
  "LibStub",
];

// Writable globals (addon globals, saved variables, third-party addons)
const writableGlobals = [
  "CoffeeRaidTools", "CoffeeRaidToolsSaved", "StaticPopupDialogs",
  "LiquidRemindersSaved", "NSRT", "TimelineReminders", "VMRT",
];

module.exports = { projectRoot, luaFiles, run, readOnlyGlobals, writableGlobals, mergeGlobals };
