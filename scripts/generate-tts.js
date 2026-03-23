require("dotenv").config();

const fs = require("fs");
const path = require("path");
const https = require("https");

const VOICE_NAME = "en-US-GuyNeural";

function httpsRequest(options, body) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      const chunks = [];
      res.on("data", (chunk) => chunks.push(chunk));
      res.on("end", () => {
        if (res.statusCode >= 400) {
          reject(
            new Error(
              `HTTP ${res.statusCode}: ${Buffer.concat(chunks).toString()}`
            )
          );
        } else {
          resolve(Buffer.concat(chunks));
        }
      });
    });
    req.on("error", reject);
    if (body) req.write(body);
    req.end();
  });
}

/**
 * Generate TTS audio files.
 * Each entry maps a filename (without extension) to the phrase to speak.
 * Skips files that already exist in outputDir.
 * @param {string} outputDir - Absolute path to the output directory
 * @param {Record<string, string>} entries - { filename: phrase } mapping
 * @returns {Promise<void>}
 */
async function generateTTS(outputDir, entries) {
  const { AZURE_SPEECH_KEY, AZURE_SPEECH_REGION } = process.env;

  fs.mkdirSync(outputDir, { recursive: true });

  const needed = Object.entries(entries).filter(([filename]) => {
    return !fs.existsSync(path.join(outputDir, `${filename}.mp3`));
  });

  const total = Object.keys(entries).length;
  if (needed.length === 0) {
    console.log(`All ${total} TTS files already exist, nothing to generate.`);
    return;
  }

  console.log(
    `Generating ${needed.length} TTS files (${total - needed.length} already exist)...`
  );

  if (!AZURE_SPEECH_KEY || !AZURE_SPEECH_REGION) {
    throw new Error(
      "AZURE_SPEECH_KEY and AZURE_SPEECH_REGION must be set in .env to generate TTS"
    );
  }

  for (const [filename, phrase] of needed) {
    const outputFile = path.join(outputDir, `${filename}.mp3`);
    const ssml = `<speak version="1.0" xml:lang="en-us"><voice name="${VOICE_NAME}">${phrase}</voice></speak>`;

    const data = await httpsRequest(
      {
        hostname: `${AZURE_SPEECH_REGION}.tts.speech.microsoft.com`,
        path: "/cognitiveservices/v1",
        method: "POST",
        headers: {
          "Ocp-Apim-Subscription-Key": AZURE_SPEECH_KEY,
          "Content-Type": "application/ssml+xml",
          "X-Microsoft-OutputFormat": "audio-16khz-128kbitrate-mono-mp3",
          "User-Agent": "CoffeeRaidTools",
        },
      },
      ssml
    );

    fs.writeFileSync(outputFile, data);
    console.log(`  Generated: ${filename}.mp3`);
  }

  console.log("TTS generation complete!");
}

module.exports = { generateTTS };

// Run directly: node scripts/generate-tts.js <outputDir> <filename:phrase> ...
if (require.main === module) {
  const args = process.argv.slice(2);
  if (args.length < 2) {
    console.error(
      "Usage: node scripts/generate-tts.js <outputDir> <filename:phrase> ..."
    );
    process.exit(1);
  }
  const outputDir = path.resolve(args[0]);
  const entries = {};
  for (const arg of args.slice(1)) {
    const sep = arg.indexOf(":");
    if (sep === -1) {
      entries[arg] = arg;
    } else {
      entries[arg.slice(0, sep)] = arg.slice(sep + 1);
    }
  }
  generateTTS(outputDir, entries).catch((err) => {
    console.error("TTS generation failed:", err.message);
    process.exit(1);
  });
}
