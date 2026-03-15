#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const { projectRoot, luaFiles, run, readOnlyGlobals, writableGlobals } = require("./lua-tools");

// Generate .luacheckrc
const luaList = (arr) => arr.map((g) => `    "${g}",`).join("\n");
const luacheckrc = `std = "lua51"
self = false
unused_args = false
max_line_length = false
ignore = {"211/Private"}

read_globals = {
${luaList(readOnlyGlobals)}
}

globals = {
${luaList(writableGlobals)}
}
`;

fs.writeFileSync(path.join(projectRoot, ".luacheckrc"), luacheckrc);
console.log(`Generated .luacheckrc with ${readOnlyGlobals.length + writableGlobals.length} globals`);

const luacheck = process.platform === "win32" ? "./scripts/luacheck.exe" : "luacheck";
run(`${luacheck} ${luaFiles}`);
