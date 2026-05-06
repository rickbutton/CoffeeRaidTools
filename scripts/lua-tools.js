const fs = require("fs");
const path = require("path");
const os = require("os");
const { execSync } = require("child_process");

const projectRoot = path.join(__dirname, "..");

const luaFiles = "*.lua Core/*.lua Features/*.lua Interface/*.lua Interface/Tabs/*.lua";

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
  "BNGetInfo", "C_AddOns", "C_QuestLog", "C_Secrets", "C_Spell", "C_SpellBook", "C_Timer", "C_UnitAuras", "C_VoiceChat", "CreateFrame",
  "GetGuildInfo", "GetGuildInfoText", "GetInstanceInfo", "GetNormalizedRealmName", "GetNumGroupMembers", "GetNumSubgroupMembers",
  "GetSpecialization", "GetSpecializationInfo",
  "GetTime", "IsInGroup", "IsInRaid", "ReloadUI", "SendChatMessage",
  "StaticPopup_Hide", "StaticPopup_Show", "StaticPopup_Visible",
  "InCombatLockdown", "PixelUtil", "PlaySoundFile",
  "CopyTable",
  "UnitClass", "UnitClassBase", "UnitExists", "UnitFullName", "UnitGroupRolesAssigned", "UnitGUID", "UnitIsGroupLeader", "UnitIsUnit", "UnitIsVisible", "UnitName", "UnitNameUnmodified",
  "issecretvalue", "canaccessvalue", "issecrettable", "canaccesstable",
  "Enum", "hooksecurefunc", "ItemInteractionFrame", "WeeklyRewardsFrame",
  "GameTooltip", "UIParent", "UISpecialFrames",
  "GameFontHighlightSmall", "GameFontNormal", "GameFontNormalLarge", "GameFontNormalSmall",
  "STANDARD_TEXT_FONT",
  "LE_PARTY_CATEGORY_INSTANCE", "LE_PARTY_CATEGORY_HOME", "RAID_CLASS_COLORS",
  "LibStub",
  "BigWigs", "BigWigsLoader",
];

// Writable globals (addon globals, saved variables, third-party addons)
const writableGlobals = [
  "CoffeeRaidTools", "CoffeeRaidToolsSaved", "StaticPopupDialogs",
  "NSAPI", "NSRT",
  "WeakAuras",
];

module.exports = { projectRoot, luaFiles, run, readOnlyGlobals, writableGlobals, mergeGlobals };
