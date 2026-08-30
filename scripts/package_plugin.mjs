#!/usr/bin/env node
// Cross-platform, deterministic plugin packaging script.
// Output: dist/godot_mini_game_v{VERSION}.zip
// Produces byte-identical ZIPs across Windows/macOS/Linux.

import { execSync } from "node:child_process";
import { createHash } from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { Buffer } from "node:buffer";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, "..");

// --- Read version from plugin.cfg ---
const pluginCfg = fs.readFileSync(
  path.join(projectRoot, "addons/godot_mini_game/plugin.cfg"),
  "utf8",
);
const version = pluginCfg.match(/^version="([^"]+)"$/m)?.[1];
if (!version || !/^[0-9]+\.[0-9]+\.[0-9]+/.test(version)) {
  console.error(`Invalid or missing plugin version: ${version ?? "<empty>"}`);
  process.exit(1);
}

const archiveName = `godot_mini_game_v${version}.zip`;
const outputDir = path.join(projectRoot, "dist");
const outputPath = path.join(outputDir, archiveName);
const checksumPath = `${outputPath}.sha256`;

// --- Collect files (deterministic order) ---
const addonDir = path.join(projectRoot, "addons", "godot_mini_game");
const licenseSrc = path.join(projectRoot, "LICENSE");

function walkDir(dir, base) {
  const results = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
    if (entry.name === ".godot" || entry.name === ".DS_Store" || entry.name === "Thumbs.db") continue;
    if (entry.name.endsWith(".uid") || entry.name.endsWith(".import")) continue;
    const fullPath = path.join(dir, entry.name);
    const relPath = path.join(base, entry.name).replace(/\\/g, "/");
    if (entry.isDirectory()) {
      results.push(...walkDir(fullPath, relPath));
    } else {
      const stat = fs.statSync(fullPath);
      if (stat.size > 0 || entry.name === ".gdignore") {
        results.push({ fullPath, relPath, size: stat.size });
      }
    }
  }
  return results;
}

// Collect addon files
const files = walkDir(addonDir, "addons/godot_mini_game");
// Add LICENSE at addon root
if (fs.existsSync(licenseSrc)) {
  files.push({
    fullPath: licenseSrc,
    relPath: "addons/godot_mini_game/LICENSE",
    size: fs.statSync(licenseSrc).size,
  });
}

// Sort by relPath for deterministic ordering
files.sort((a, b) => a.relPath.localeCompare(b.relPath));

// --- Write to zip using Node.js zlib (stored, no compression — deterministic) ---
// We use the ZIP format directly for full control over determinism.

function crc32(buf) {
  let crc = 0xffffffff;
  const table = new Uint32Array(256);
  for (let i = 0; i < 256; i++) {
    let c = i;
    for (let j = 0; j < 8; j++) c = (c & 1) ? (0xedb88320 ^ (c >>> 1)) : (c >>> 1);
    table[i] = c;
  }
  for (let i = 0; i < buf.length; i++) {
    crc = table[(crc ^ buf[i]) & 0xff] ^ (crc >>> 8);
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function uint16(n) {
  const b = Buffer.alloc(2);
  b.writeUInt16LE(n, 0);
  return b;
}

function uint32(n) {
  const b = Buffer.alloc(4);
  b.writeUInt32LE(n, 0);
  return b;
}

const DOS_EPOCH = new Date("1980-01-01T00:00:00Z");

function dosTimestamp(date) {
  const d = date || DOS_EPOCH;
  const time = (d.getUTCSeconds() >> 1) | (d.getUTCMinutes() << 5) | (d.getUTCHours() << 11);
  const dateVal = d.getUTCDate() | ((d.getUTCMonth() + 1) << 5) | ((d.getUTCFullYear() - 1980) << 9);
  return { time, date: dateVal };
}

const centralDir = [];
const localHeaders = [];
let offset = 0;

for (const file of files) {
  const data = fs.readFileSync(file.fullPath);
  const nameBuffer = Buffer.from(file.relPath, "utf8");
  const crc = crc32(data);
  const { time, date } = dosTimestamp(DOS_EPOCH);

  // Local file header
  const localHeader = Buffer.concat([
    Buffer.from("PK\x03\x04"), // signature
    uint16(20), // version needed
    uint16(0), // flags
    uint16(0), // compression: stored
    uint16(time), // mod time
    uint16(date), // mod date
    uint32(crc), // crc32
    uint32(data.length), // compressed size
    uint32(data.length), // uncompressed size
    uint16(nameBuffer.length), // name length
    uint16(0), // extra length
    nameBuffer,
  ]);

  localHeaders.push(Buffer.concat([localHeader, data]));

  // Central directory entry
  const centralEntry = Buffer.concat([
    Buffer.from("PK\x01\x02"), // signature
    uint16(20), // version made by
    uint16(20), // version needed
    uint16(0), // flags
    uint16(0), // compression
    uint16(time), // mod time
    uint16(date), // mod date
    uint32(crc), // crc32
    uint32(data.length), // compressed size
    uint32(data.length), // uncompressed size
    uint16(nameBuffer.length), // name length
    uint16(0), // extra length
    uint16(0), // comment length
    uint16(0), // disk number start
    uint16(0), // internal attributes
    uint32(0), // external attributes
    uint32(offset), // local header offset
    nameBuffer,
  ]);

  centralDir.push(centralEntry);
  offset += localHeader.length + data.length;
}

// End of central directory
const centralDirOffset = offset;
const centralDirSize = centralDir.reduce((sum, e) => sum + e.length, 0);
const endRecord = Buffer.concat([
  Buffer.from("PK\x05\x06"), // signature
  uint16(0), // disk number
  uint16(0), // disk with central dir
  uint16(files.length), // entries on disk
  uint16(files.length), // total entries
  uint32(centralDirSize), // central dir size
  uint32(centralDirOffset), // central dir offset
  uint16(0), // comment length
]);

// Write zip
fs.mkdirSync(outputDir, { recursive: true });
fs.writeFileSync(outputPath, Buffer.concat([...localHeaders, ...centralDir, endRecord]));

// Compute SHA-256
const zipData = fs.readFileSync(outputPath);
const hash = createHash("sha256").update(zipData).digest("hex");
fs.writeFileSync(checksumPath, `${hash}  ${archiveName}\n`, "utf8");

const sizeMB = (zipData.length / (1024 * 1024)).toFixed(1);
console.log(`Packaging Godot Mini Game Plugin v${version}`);
console.log(`Files: ${files.length}`);
console.log(`Size:  ${sizeMB} MB`);
console.log(`SHA-256: ${hash}`);
console.log(`Output: ${outputPath}`);
