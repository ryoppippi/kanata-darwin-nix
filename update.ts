#!/usr/bin/env bun

/**
 * Update script for kanata package.
 *
 * Fetches the latest version from GitHub releases and retrieves
 * platform-specific checksums from sha256sums file.
 */

import { $ } from "bun";
import { join } from "node:path";

const REPO = "jtroo/kanata";

const platforms = {
  "x86_64-linux": "kanata-linux-binaries-VERSION-x64.zip",
  "x86_64-darwin": "kanata-macos-binaries-x64-VERSION.zip",
  "aarch64-darwin": "kanata-macos-binaries-arm64-VERSION.zip",
} as const;

type NixPlatform = keyof typeof platforms;

interface SourcesJSON {
  version: string;
  platforms: Record<NixPlatform, { url: string; hash: string }>;
}

async function fetchLatestVersion(): Promise<string> {
  const url = `https://api.github.com/repos/${REPO}/releases/latest`;
  const response = await fetch(url, {
    headers: {
      Accept: "application/vnd.github.v3+json",
      "User-Agent": "kanata-overlay-update-script",
    },
  });
  const json = (await response.json()) as { tag_name: string };
  return json.tag_name.replace(/^v/, "");
}

async function fetchSha256sums(version: string): Promise<Map<string, string>> {
  const url = `https://github.com/${REPO}/releases/download/v${version}/sha256sums`;
  const response = await fetch(url);
  const text = await response.text();

  const checksums = new Map<string, string>();
  for (const line of text.trim().split("\n")) {
    const [hash, filename] = line.trim().split(/\s+/);
    if (hash && filename) {
      checksums.set(filename, hash);
    }
  }
  return checksums;
}

async function sha256ToSri(sha256Hex: string): Promise<string> {
  const result = await $`nix hash convert --hash-algo sha256 ${sha256Hex}`.text();
  return result.trim();
}

async function getCurrentVersion(): Promise<string | null> {
  const sourcesPath = join(import.meta.dir, "sources.json");
  const sources: SourcesJSON = await Bun.file(sourcesPath).json();
  return sources.version;
}

async function updateSourcesJSON(
  version: string,
  hashes: Record<NixPlatform, string>
): Promise<void> {
  const sourcesPath = join(import.meta.dir, "sources.json");

  const platformsData: Record<
    NixPlatform,
    { url: string; hash: string }
  > = {} as Record<NixPlatform, { url: string; hash: string }>;

  for (const nixPlatform of Object.keys(platforms) as NixPlatform[]) {
    const filename = platforms[nixPlatform].replace("VERSION", `v${version}`);
    const url = `https://github.com/${REPO}/releases/download/v${version}/${filename}`;
    platformsData[nixPlatform] = {
      url,
      hash: hashes[nixPlatform],
    };
  }

  const sourcesData: SourcesJSON = {
    version,
    platforms: platformsData,
  };

  await Bun.write(sourcesPath, JSON.stringify(sourcesData, null, 2) + "\n");
}

const currentVersion = await getCurrentVersion();
const latestVersion = await fetchLatestVersion();

console.log(`Current version: ${currentVersion}`);
console.log(`Latest version: ${latestVersion}`);

if (currentVersion === latestVersion) {
  console.log("Already up to date!");
  process.exit(0);
}

console.log(`Updating kanata from ${currentVersion} to ${latestVersion}`);

console.log("Fetching sha256sums...");
const checksums = await fetchSha256sums(latestVersion);
const hashes: Record<NixPlatform, string> = {} as Record<NixPlatform, string>;

for (const nixPlatform of Object.keys(platforms) as NixPlatform[]) {
  const filename = platforms[nixPlatform].replace(
    "VERSION",
    `v${latestVersion}`
  );
  const checksum = checksums.get(filename);
  if (!checksum) {
    console.error(`Checksum not found for ${filename}`);
    process.exit(1);
  }
  const sriHash = await sha256ToSri(checksum);
  hashes[nixPlatform] = sriHash;
  console.log(`  ${nixPlatform}: ${sriHash}`);
}

console.log();

await updateSourcesJSON(latestVersion, hashes);
console.log(`Updated kanata to version ${latestVersion}`);

console.log("Done!");
