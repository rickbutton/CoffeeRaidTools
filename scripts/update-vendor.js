// Clones vendor reference repos (or pulls latest if they already exist).
// These repos are read-only references — never modify code in vendor/.

const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const VENDOR_DIR = path.join(__dirname, "..", "vendor");

const repos = [
  {
    name: "wow-ui-source",
    url: "https://github.com/Gethe/wow-ui-source.git",
    cloneArgs: ["--filter=blob:none"],
  },
  {
    name: "BigWigs",
    url: "https://github.com/BigWigsMods/BigWigs",
  },
  {
    name: "NorthernSkyRaidTools",
    url: "https://github.com/Reloe/NorthernSkyRaidTools",
  },
];

function run(cmd, cwd) {
  execSync(cmd, { stdio: "inherit", cwd, shell: "bash" });
}

fs.mkdirSync(VENDOR_DIR, { recursive: true });

for (const repo of repos) {
  const dir = path.join(VENDOR_DIR, repo.name);
  if (fs.existsSync(path.join(dir, ".git"))) {
    console.log(`Updating ${repo.name}...`);
    run("git pull --ff-only", dir);
  } else {
    console.log(`Cloning ${repo.name}...`);
    const args = (repo.cloneArgs || []).join(" ");
    run(`git clone ${args} ${repo.url} ${dir}`);
  }
}

console.log("Done — vendor repos are up to date.");
