#!/usr/bin/env node
// Validate SHA256SUMS file format and integrity.
// Usage: node test/sha256sums_test.mjs

import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createHash } from "node:crypto";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, "..");

function read(filePath) {
  return fs.readFileSync(path.join(projectRoot, filePath), "utf8");
}

function sha256(filePath) {
  const data = fs.readFileSync(path.join(projectRoot, filePath));
  return createHash("sha256").update(data).digest("hex");
}

function main() {
  console.log("=== SHA256SUMS Validation ===");

  // Read the file
  const content = read("SHA256SUMS");

  // Check no BOM
  const bytes = fs.readFileSync(path.join(projectRoot, "SHA256SUMS"));
  assert.ok(
    !(bytes[0] === 0xEF && bytes[1] === 0xBB && bytes[2] === 0xBF),
    "SHA256SUMS must not have UTF-8 BOM",
  );

  // Check line endings
  assert.ok(
    !content.includes("\r\n"),
    "SHA256SUMS must use LF line endings (no CRLF)",
  );

  // Parse entries
  const lines = content.split("\n").filter((l) => l.trim().length > 0);
  assert.ok(lines.length >= 40, `SHA256SUMS should have at least 40 entries (got ${lines.length})`);

  // Validate format and hashes
  const expectedPaths = new Set();
  for (const line of lines) {
    // Format: <64 hex chars>  <path>
    const match = line.match(/^([0-9a-f]{64})  (.+)$/);
    assert.ok(match, `Invalid format: ${line.substring(0, 50)}...`);

    const expectedHash = match[1];
    const filePath = match[2];

    // Check path is relative (no leading /)
    assert.ok(
      !filePath.startsWith("/"),
      `Path should be relative: ${filePath}`,
    );

    expectedPaths.add(filePath);

    // Verify hash
    const fullPath = path.join(projectRoot, filePath);
    assert.ok(fs.existsSync(fullPath), `File missing: ${filePath}`);

    const actualHash = sha256(filePath);
    assert.equal(actualHash, expectedHash, `Hash mismatch for ${filePath}`);
  }

  // Check determinism: sorting should be stable
  const sortedLines = [...lines].sort((a, b) => {
    const pathA = a.substring(a.indexOf("  ") + 2);
    const pathB = b.substring(b.indexOf("  ") + 2);
    return pathA.localeCompare(pathB);
  });
  assert.deepEqual(lines, sortedLines, "SHA256SUMS entries must be sorted by path");

  console.log(`✓ SHA256SUMS valid: ${lines.length} entries`);
  console.log("sha256sums_test.mjs: ok");
}

main();
