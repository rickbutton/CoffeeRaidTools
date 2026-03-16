require("dotenv").config();

const child = require("child_process");
const fs = require("fs");
const { S3 } = require("@aws-sdk/client-s3");

const {
    BUCKET_ENDPOINT,
    BUCKET_REGION,
    BUCKET_NAME,
    BUCKET_ACCESS_KEY_ID,
    BUCKET_SECRET_ACCESS_KEY,
} = process.env;

const s3Client = new S3({
    forcePathStyle: false,
    endpoint: `https://${BUCKET_ENDPOINT}`,
    region: BUCKET_REGION,
    credentials: {
        accessKeyId: BUCKET_ACCESS_KEY_ID,
        secretAccessKey: BUCKET_SECRET_ACCESS_KEY,
    }
});

async function getString(name) {
    try {
        const data = await s3Client.getObject({
            Bucket: BUCKET_NAME,
            Key: name,
        });

        return data.Body.transformToString();
    } catch (e) {
        console.error("Error getting string", name, e);
        return false;
    }
}

async function uploadString(name, str) {
    const uploadResult = await s3Client.putObject({
        ACL: "public-read",
        Bucket: BUCKET_NAME,
        Key: name,
        Body: Buffer.from(str, "utf-8"),
        ContentType: "plain/text",
    });
    console.log("string upload result:", uploadResult);
}

async function uploadFile(path, destPath, contentType) {
    const fileStream = fs.createReadStream(path);
    const uploadResult = await s3Client.putObject({
        ACL: "public-read",
        Bucket: BUCKET_NAME,
        Key: destPath,
        Body: fileStream,
        ContentType: contentType,
    });
    console.log("file upload result:", uploadResult);
}

async function main() {
    const projectName = "CoffeeRaidTools";

    console.log(`fetching latest release tag for ${projectName}...`);
    const latestTag = child.execSync("gh release list -L 1 --json tagName -q \".[].tagName\"").toString().replace(/^\s+|\s+$/g, "");
    console.log(`latest release tag for ${projectName}:`, latestTag);

    const releaseName = `${projectName}-${latestTag}.zip`;
    const localDownloadPath = `release/${releaseName}`;
    if (fs.existsSync(localDownloadPath)) {
        console.log("found existing release zip, skipping download");
    } else {
        console.log("downloading latest release...");
        child.execSync(`gh release download ${latestTag} -D release --clobber -p "*.zip"`, { stdio: "inherit" });
    }

    const remotePath = `addons/${releaseName}`;
    console.log(`uploading release zip to S3: '${localDownloadPath}' -> '${remotePath}'`);
    await uploadFile(localDownloadPath, remotePath, "application/zip");

    const currentManifestString = await getString("manifest.json");
    console.log("current manifest:", currentManifestString);

    const manifest = JSON.parse(currentManifestString);
    let found = false;
    for (const addon of manifest.AddOns) {
        if (addon.Name === projectName) {
            console.log(`updating version for ${projectName} in manifest from ${addon.Version} to ${latestTag}`);
            addon.Version = latestTag;
            found = true;
        }
    }
    
     if (!found) {
        console.log("didn't find addon in manifest, adding it");
        manifest.AddOns.push({
            Name: projectName,
            Version: latestTag,
        });
     }

    const newManifestString = JSON.stringify(manifest, null, 2);
    console.log("new manifest:", newManifestString);

    if (currentManifestString === newManifestString) {
        console.log("manifest is already up to date, skipping upload");
    } else {
        console.log("updating manifest.json with latest versions");
        await uploadString("manifest.json", newManifestString);
    }

    const projectUrl = `https://${BUCKET_NAME}.${BUCKET_ENDPOINT}/${remotePath}`;
    console.log(`${projectName} URL`, projectUrl);
}

main();
