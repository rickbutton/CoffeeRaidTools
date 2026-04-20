#!/usr/bin/env node
const { luaFiles, run } = require("./lua-tools");

const check = process.argv.includes("--check") ? "--check " : "";
// --respect-ignores makes stylua consult .styluaignore when files are passed
// directly, rather than only when recursing into a directory.
run(`stylua --respect-ignores ${check}${luaFiles}`);
