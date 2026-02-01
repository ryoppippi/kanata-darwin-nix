#!/usr/bin/env nix
/*
#! nix shell --inputs-from . nixpkgs#bun nixpkgs#oxfmt -c bun
*/

/**
 * Update script for kanata-darwin-nix packages.
 *
 * Updates:
 * - kanata: from jtroo/kanata releases (macOS only)
 * - kanata-vk-agent: from devsunb/kanata-vk-agent releases
 * - karabiner-driverkit: from pqrs-org/Karabiner-DriverKit-VirtualHIDDevice releases
 */

import { $ } from "bun";
import { join } from "node:path";

async function sha256ToSri(sha256Hex: string): Promise<string> {
  const result = await $`nix hash convert --hash-algo sha256 ${sha256Hex}`.text();
  return result.trim();
}

async function fetchLatestRelease(
  repo: string,
): Promise<{ tag: string; assets: { name: string; url: string }[] }> {
  const url = `https://api.github.com/repos/${repo}/releases/latest`;
  const response = await fetch(url, {
    headers: {
      Accept: "application/vnd.github.v3+json",
      "User-Agent": "kanata-overlay-update-script",
    },
  });
  const json = (await response.json()) as {
    tag_name: string;
    assets: { name: string; browser_download_url: string }[];
  };
  return {
    tag: json.tag_name.replace(/^v/, ""),
    assets: json.assets.map((a) => ({ name: a.name, url: a.browser_download_url })),
  };
}

async function prefetchUrl(url: string): Promise<string> {
  const result = await $`nix-prefetch-url --type sha256 ${url}`.text();
  return sha256ToSri(result.trim());
}

async function prefetchUrlUnpack(url: string): Promise<string> {
  const result = await $`nix-prefetch-url --unpack --type sha256 ${url}`.text();
  return sha256ToSri(result.trim());
}

// ============== Kanata ==============
async function updateKanata() {
  const REPO = "jtroo/kanata";
  const platforms = {
    "x86_64-darwin": "kanata-macos-binaries-x64-VERSION.zip",
    "aarch64-darwin": "kanata-macos-binaries-arm64-VERSION.zip",
  } as const;

  type NixPlatform = keyof typeof platforms;

  interface SourcesJSON {
    version: string;
    platforms: Record<NixPlatform, { url: string; hash: string }>;
  }

  const sourcesPath = join(import.meta.dir, "packages/kanata/sources.json");
  const current: SourcesJSON = await Bun.file(sourcesPath).json();

  const release = await fetchLatestRelease(REPO);
  const latestVersion = release.tag;

  console.log(`[kanata] Current: ${current.version}, Latest: ${latestVersion}`);

  if (current.version === latestVersion) {
    console.log("[kanata] Already up to date!");
    return;
  }

  console.log(`[kanata] Updating to ${latestVersion}...`);

  const platformsData: Record<NixPlatform, { url: string; hash: string }> = {} as Record<
    NixPlatform,
    { url: string; hash: string }
  >;

  for (const nixPlatform of Object.keys(platforms) as NixPlatform[]) {
    const filename = platforms[nixPlatform].replace("VERSION", `v${latestVersion}`);
    const url = `https://github.com/${REPO}/releases/download/v${latestVersion}/${filename}`;
    const hash = await prefetchUrlUnpack(url);
    platformsData[nixPlatform] = { url, hash };
    console.log(`  ${nixPlatform}: ${hash}`);
  }

  const sourcesData: SourcesJSON = { version: latestVersion, platforms: platformsData };
  await Bun.write(sourcesPath, JSON.stringify(sourcesData, null, 2) + "\n");
  console.log(`[kanata] Updated to ${latestVersion}`);
}

// ============== Kanata VK Agent ==============
async function updateKanataVkAgent() {
  const REPO = "devsunb/kanata-vk-agent";
  const platforms = {
    "x86_64-darwin": "kanata-vk-agent_x86_64.tar.gz",
    "aarch64-darwin": "kanata-vk-agent_aarch64.tar.gz",
  } as const;

  type NixPlatform = keyof typeof platforms;

  interface SourcesJSON {
    version: string;
    platforms: Record<NixPlatform, { url: string; hash: string }>;
  }

  const sourcesPath = join(import.meta.dir, "packages/kanata-vk-agent/sources.json");
  const current: SourcesJSON = await Bun.file(sourcesPath).json();

  const release = await fetchLatestRelease(REPO);
  const latestVersion = release.tag;

  console.log(`[kanata-vk-agent] Current: ${current.version}, Latest: ${latestVersion}`);

  if (current.version === latestVersion) {
    console.log("[kanata-vk-agent] Already up to date!");
    return;
  }

  console.log(`[kanata-vk-agent] Updating to ${latestVersion}...`);

  const platformsData: Record<NixPlatform, { url: string; hash: string }> = {} as Record<
    NixPlatform,
    { url: string; hash: string }
  >;

  for (const nixPlatform of Object.keys(platforms) as NixPlatform[]) {
    const filename = platforms[nixPlatform];
    const url = `https://github.com/${REPO}/releases/download/v${latestVersion}/${filename}`;
    const hash = await prefetchUrlUnpack(url);
    platformsData[nixPlatform] = { url, hash };
    console.log(`  ${nixPlatform}: ${hash}`);
  }

  const sourcesData: SourcesJSON = { version: latestVersion, platforms: platformsData };
  await Bun.write(sourcesPath, JSON.stringify(sourcesData, null, 2) + "\n");
  console.log(`[kanata-vk-agent] Updated to ${latestVersion}`);
}

// ============== Karabiner DriverKit ==============
async function updateKarabinerDriverKit() {
  const REPO = "pqrs-org/Karabiner-DriverKit-VirtualHIDDevice";

  interface SourcesJSON {
    version: string;
    url: string;
    hash: string;
  }

  const sourcesPath = join(import.meta.dir, "packages/karabiner-driverkit/sources.json");
  const current: SourcesJSON = await Bun.file(sourcesPath).json();

  const release = await fetchLatestRelease(REPO);
  const latestVersion = release.tag;

  console.log(`[karabiner-driverkit] Current: ${current.version}, Latest: ${latestVersion}`);

  if (current.version === latestVersion) {
    console.log("[karabiner-driverkit] Already up to date!");
    return;
  }

  console.log(`[karabiner-driverkit] Updating to ${latestVersion}...`);

  const pkgAsset = release.assets.find((a) => a.name.endsWith(".pkg"));
  if (!pkgAsset) {
    console.error("[karabiner-driverkit] No .pkg asset found");
    process.exit(1);
  }

  const hash = await prefetchUrl(pkgAsset.url);
  console.log(`  hash: ${hash}`);

  const sourcesData: SourcesJSON = {
    version: latestVersion,
    url: pkgAsset.url,
    hash,
  };
  await Bun.write(sourcesPath, JSON.stringify(sourcesData, null, 2) + "\n");
  console.log(`[karabiner-driverkit] Updated to ${latestVersion}`);
}

// ============== Main ==============
console.log("Updating kanata-darwin-nix packages...\n");

await updateKanata();
console.log();

await updateKanataVkAgent();
console.log();

await updateKarabinerDriverKit();
console.log();

console.log("Formatting with oxfmt...");
await $`oxfmt packages/kanata/sources.json packages/kanata-vk-agent/sources.json packages/karabiner-driverkit/sources.json`.quiet();

console.log("Done!");
