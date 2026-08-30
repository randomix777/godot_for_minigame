#!/usr/bin/env node
// Generate SHA256SUMS file for the repository.
// Output: UTF-8 without BOM, LF line endings, deterministic order.
// Format: <64-char-hex>  <relative-path>\n

import { createHash } from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, "..");

// Files to include in SHA256SUMS (relative to project root)
const FILES = [
  ".gitattributes",
  "addons/godot_mini_game/core/output_guard.gd",
  "addons/godot_mini_game/core/template_bundle.gd",
  "addons/godot_mini_game/core/version_manager.gd",
  "addons/godot_mini_game/engine/godot.js",
  "addons/godot_mini_game/engine/godot.wasm.br",
  "addons/godot_mini_game/engine/template.json",
  "addons/godot_mini_game/engine/version.txt",
  "addons/godot_mini_game/export_dock.gd",
  "addons/godot_mini_game/exporter.gd",
  "addons/godot_mini_game/MiniGameSDK.gd",
  "addons/godot_mini_game/plugin.cfg",
  "addons/godot_mini_game/plugin.gd",
  "addons/godot_mini_game/templates/alipay/game.js",
  "addons/godot_mini_game/templates/alipay/game.json.template",
  "addons/godot_mini_game/templates/alipay/project.config.json.template",
  "addons/godot_mini_game/templates/baidu/game.js",
  "addons/godot_mini_game/templates/baidu/game.json.template",
  "addons/godot_mini_game/templates/baidu/project.config.json.template",
  "addons/godot_mini_game/templates/common/adapter.js",
  "addons/godot_mini_game/templates/common/fetch.js",
  "addons/godot_mini_game/templates/common/js/image_loader.js",
  "addons/godot_mini_game/templates/common/js/loader.js",
  "addons/godot_mini_game/templates/common/js/libs/sdk.js",
  "addons/godot_mini_game/templates/common/js/platform_runtime.js",
  "addons/godot_mini_game/templates/douyin/game.js",
  "addons/godot_mini_game/templates/douyin/game.json.template",
  "addons/godot_mini_game/templates/douyin/project.config.json.template",
  "addons/godot_mini_game/templates/kuaishou/game.js",
  "addons/godot_mini_game/templates/kuaishou/game.json.template",
  "addons/godot_mini_game/templates/kuaishou/project.config.json.template",
  "addons/godot_mini_game/templates/qq/game.js",
  "addons/godot_mini_game/templates/qq/game.json.template",
  "addons/godot_mini_game/templates/qq/project.config.json.template",
  "addons/godot_mini_game/templates/qq/project.private.config.json.template",
  "addons/godot_mini_game/templates/tiktok/game.js",
  "addons/godot_mini_game/templates/tiktok/game.json.template",
  "addons/godot_mini_game/templates/tiktok/project.config.json.template",
  "addons/godot_mini_game/templates/wechat/game.js",
  "addons/godot_mini_game/templates/wechat/game.json.template",
  "addons/godot_mini_game/templates/wechat/project.config.json.template",
  "addons/godot_mini_game/templates/wechat/project.private.config.json.template",
  "CHANGELOG.md",
  "CONTRIBUTING.md",
  "LICENSE",
  "README.md",
  "README_zh.md",
  "SECURITY.md",
  "support-matrix.json",
  "templates/versions.json",
  "test/_template_helpers.mjs",
  "test/adapter_layout.test.mjs",
  "test/entry_platform.test.mjs",
  "test/exporter_smoke_test.gd",
  "test/fetch_headers.test.mjs",
  "test/loader_image_loader.test.mjs",
  "test/loader_runtime.test.mjs",
  "test/package_reproducibility.test.mjs",
  "test/platform_runtime.test.mjs",
  "test/readme_homepage.test.mjs",
  "test/release_contract.test.mjs",
  "test/sdk_bridge.test.mjs",
  "test/tt_platform_smoke.test.mjs",
  "toolchain.lock.json",
];

function sha256(filePath) {
  const data = fs.readFileSync(filePath);
  return createHash("sha256").update(data).digest("hex");
}

function main() {
  const lines = [];
  const errors = [];

  for (const relPath of FILES) {
    const fullPath = path.join(projectRoot, relPath);
    if (!fs.existsSync(fullPath)) {
      errors.push(`Missing file: ${relPath}`);
      continue;
    }
    const hash = sha256(fullPath);
    lines.push(`${hash}  ${relPath}`);
  }

  // Sort by path for deterministic output
  lines.sort((a, b) => {
    const pathA = a.substring(a.indexOf("  ") + 2);
    const pathB = b.substring(b.indexOf("  ") + 2);
    return pathA.localeCompare(pathB);
  });

  // Join with LF and add trailing newline
  const content = lines.join("\n") + "\n";

  // Write with UTF-8 no BOM
  const encoding = new TextEncoder();
  fs.writeFileSync(path.join(projectRoot, "SHA256SUMS"), encoding.encode(content));

  if (errors.length > 0) {
    console.error("Errors:");
    errors.forEach((e) => console.error(`  ${e}`));
    process.exit(1);
  }

  console.log(`Generated SHA256SUMS: ${lines.length} entries`);
}

main();
