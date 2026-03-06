#!/usr/bin/env node
const { luaFiles, run } = require("./lua-tools");

const check = process.argv.includes("--check") ? "--check " : "";
run(`stylua ${check}${luaFiles}`);
