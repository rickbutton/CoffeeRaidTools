// Run the busted test suite.
//
// Ensures Ace3 libraries are checked out into .release/CoffeeRaidTools/Libs
// (which happens as part of `pnpm run build:full`) before running busted,
// since the spec harness loads them from that path.

const fs = require("fs");
const path = require("path");
const child = require("child_process");

const LIBS_DIR = path.join(".release", "CoffeeRaidTools", "Libs");

if (!fs.existsSync(LIBS_DIR)) {
    console.log("Libraries not found; running `pnpm run build:full` first...");
    child.execSync("node scripts/build.js full", { stdio: "inherit" });
}

const args = process.argv.slice(2);
const cmd = ["busted", "--lua=lua5.1", ...args].join(" ");
try {
    child.execSync(cmd, { stdio: "inherit" });
} catch (e) {
    process.exit(e.status || 1);
}
