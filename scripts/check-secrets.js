#!/usr/bin/env node
// Usage: node scripts/check-secrets.js <FunctionName> [FunctionName2 ...]
// Searches Blizzard API documentation for secret metadata on WoW API functions.

const fs = require("fs");
const path = require("path");

const docsDir = path.join(
  __dirname,
  "..",
  "vendor",
  "wow-ui-source",
  "Interface",
  "AddOns",
  "Blizzard_APIDocumentationGenerated"
);

const names = process.argv.slice(2);
if (names.length === 0) {
  console.error("Usage: node scripts/check-secrets.js <FunctionName> [...]");
  process.exit(1);
}

const files = fs.readdirSync(docsDir).filter((f) => f.endsWith(".lua"));

for (const name of names) {
  const pattern = new RegExp(`Name\\s*=\\s*"${name}"`, "m");
  let found = false;

  for (const file of files) {
    const content = fs.readFileSync(path.join(docsDir, file), "utf8");
    const lines = content.split("\n");

    for (let i = 0; i < lines.length; i++) {
      if (!pattern.test(lines[i])) continue;
      if (!lines[i].includes("Type") || lines[i].includes('"Function"')) {
        // Could be a function definition line or a line without Type
      }

      // Walk backwards to find if this is inside a function block
      // Walk forwards to find the end of the block and collect secret metadata
      // Find the start of the enclosing { block
      let braceDepth = 0;
      let blockStart = i;
      for (let j = i; j >= 0; j--) {
        const opens = (lines[j].match(/\{/g) || []).length;
        const closes = (lines[j].match(/\}/g) || []).length;
        braceDepth += closes - opens;
        if (braceDepth < 0) {
          blockStart = j;
          break;
        }
      }

      // Check if this block contains Type = "Function"
      let isFunction = false;
      for (let j = blockStart; j <= Math.min(i + 2, lines.length - 1); j++) {
        if (lines[j].includes('Type = "Function"')) {
          isFunction = true;
          break;
        }
      }
      if (!isFunction) continue;

      // Find the end of this function block
      braceDepth = 0;
      let blockEnd = i;
      for (let j = blockStart; j < lines.length; j++) {
        const opens = (lines[j].match(/\{/g) || []).length;
        const closes = (lines[j].match(/\}/g) || []).length;
        braceDepth += opens - closes;
        if (braceDepth <= 0 && j > blockStart) {
          blockEnd = j;
          break;
        }
      }

      const block = lines.slice(blockStart, blockEnd + 1).join("\n");

      // Extract function-level secret annotations
      const secretAnnotations = [];
      const secretPattern =
        /\b(Secret\w+|ConditionalSecret|NeverSecret)\s*=\s*("(?:[^"\\]|\\.)*"|[^,}\s]+)/g;
      let match;
      while ((match = secretPattern.exec(block)) !== null) {
        secretAnnotations.push(`${match[1]} = ${match[2]}`);
      }

      if (secretAnnotations.length > 0) {
        found = true;
        console.log(`${name} (${file}):`);
        for (const ann of secretAnnotations) {
          console.log(`  ${ann}`);
        }
        console.log();
      } else {
        found = true;
        console.log(`${name} (${file}): no secret annotations`);
        console.log();
      }
      break; // Only first match per file
    }
  }

  if (!found) {
    console.log(`${name}: NOT FOUND in API docs`);
    console.log();
  }
}
