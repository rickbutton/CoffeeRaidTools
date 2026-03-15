const fs = require("fs");
const path = require("path");
const child = require("child_process");
const chokidar = require("chokidar");

const ADDON_NAME = "CoffeeRaidTools";
const RELEASE_DIR = ".release";
const ADDON_DIR = path.join(RELEASE_DIR, ADDON_NAME);
const LIBS_DIR = path.join(ADDON_DIR, "Libs");

const isWindows = process.platform === "win32";
const libsAlreadyCheckedOut = fs.existsSync(LIBS_DIR);

const mode = process.argv[2] || "default";

if (!["default", "full", "watch"].includes(mode)) {
    console.error("usage: build.js [default|full|watch]");
    process.exit(2);
}

let command = ["-z", "-o"];
if (libsAlreadyCheckedOut && mode != "full") {
    console.log("not checking out externals");
    command.push("-e");
}
if (isWindows) {
    const scriptPath = path.join(__dirname, "release.bat");
    command = ["cmd.exe", "/c", scriptPath, ...command];
} else {
    const scriptPath = path.join(__dirname, "release.sh");
    command = [scriptPath, ...command];
}

function doBuild() {
    child.execSync(command.join(" "), {
        stdio: "inherit",
    });
}

if (mode === "watch") {
    const watcher = chokidar.watch(".", {
        ignored: (p) => {
            if (p === ".") return false;

            if (p.startsWith(".luaTypes")) return true;
            if (p.startsWith("node_modules")) return true;
            if (p.startsWith(".git")) return true;
            if (p.startsWith(".claude")) return true;
            if (p.startsWith(".release")) return true;
            if (p.startsWith(".vscode")) return true;
            if (p.startsWith("scripts")) return true;

            if (p.startsWith("vendor")) return true;

            if (p === ".luacheckrc") return true;
            if (p === ".luarc.json") return true;
            if (p === ".stylua.toml") return true;
            if (p === ".editorconfig") return true;
            if (p === "package.json") return true;
            if (p === "pnpm-lock.yaml") return true;
            if (p === "TODO") return true;
            if (p.endsWith(".md")) return true;

            if (p.endsWith(".lua")) return false;
            if (p.startsWith("Media")) return false;
            if (p === ".pkgmeta") return false;
            if (p === "CoffeeRaidTools.toc") return false;
            if (p === "externals.xml") return false;
            if (fs.lstatSync(p).isDirectory()) return false;

            console.warn(`unexpected file detected by watcher: ${p}.`);
            return true;
        },
        awaitWriteFinish: true,
    });

    let ready = false;
    watcher.on("ready", () => {
        ready = true;
        console.log("watching source for changes, running initial build");
        doBuild();
    });
    watcher.on("all", (event, path) => {
        if (ready) {
            console.log(`watcher detected ${event} event for ${path}, running build`);
            doBuild();
        }
    });
} else {
    doBuild();
}
