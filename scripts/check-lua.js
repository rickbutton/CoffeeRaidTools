#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const os = require("os");
const { projectRoot, run, writableGlobals, mergeGlobals } = require("./lua-tools");

// Find ketho.wow-api extension annotations path
const extDir = path.join(os.homedir(), ".vscode", "extensions");
const kethoDir = fs.readdirSync(extDir).find((d) => d.startsWith("ketho.wow-api-"));
if (!kethoDir) {
  console.error("Error: ketho.wow-api extension not found in", extDir);
  process.exit(1);
}
const annotationsPath = path
  .join(os.homedir(), ".vscode", "extensions", kethoDir, "Annotations")
  .replace(/\\/g, "/");

// Generate .luarc.json — LuaLS gets most globals from annotations, so only list extras
const globals = mergeGlobals([
  ...writableGlobals,
  "AuraUpdater", "INT", "RAID", "PARTY", "INSTANCE_CHAT", "CLOSE",
  "LE_PARTY_CATEGORY_INSTANCE", "LE_PARTY_CATEGORY_HOME",
]);

const luarc = {
  $schema: "https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json",
  runtime: {
    version: "Lua 5.1",
    builtin: {
      basic: "disable", debug: "disable", io: "disable", math: "disable",
      os: "disable", package: "disable", string: "disable", table: "disable",
      utf8: "disable",
    },
  },
  workspace: {
    library: [annotationsPath + "/Core", annotationsPath + "/FrameXML"],
    checkThirdParty: false,
  },
  diagnostics: { globals, disable: ["assign-type-mismatch"] },
  type: { weakUnionCheck: true },
};

fs.writeFileSync(path.join(projectRoot, ".luarc.json"), JSON.stringify(luarc, null, 4) + "\n");
console.log(`Generated .luarc.json with ${globals.length} globals`);

run("lua-language-server --check . --configpath .luarc.json");
