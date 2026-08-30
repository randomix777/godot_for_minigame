/**
 * Shared helpers for tests that execute CommonJS template files.
 *
 * Templates were converted from ES modules to CommonJS (require + globals).
 * Tests now use vm.runInThisContext() instead of import() to execute them,
 * then read globals instead of destructuring ES module exports.
 */

import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";

const projectRoot = path.resolve(import.meta.dirname, "..");
const templateRoot = path.join(projectRoot, "addons/godot_mini_game/templates");

/** Read a template file from disk. */
export function readTemplate(relativePath) {
  return fs.readFileSync(path.join(templateRoot, relativePath), "utf8");
}

/** Execute source in the current V8 context (no custom require). */
export function execSource(source, filename = "<template>") {
  if (!globalThis.GameGlobal) globalThis.GameGlobal = {};
  vm.runInThisContext(source, { filename });
}

/**
 * Execute source with a mock require that resolves template paths.
 * requireMap keys are the specifier strings (e.g. "./js/platform_runtime").
 * Values are functions that execute the dependency and return its "module" value.
 */
export function execWithMockRequire(source, filename, requireMap) {
  if (!globalThis.GameGlobal) globalThis.GameGlobal = {};
  globalThis.require = (id) => {
    if (id in requireMap) return requireMap[id]();
    throw new Error(`Unmapped require('${id}') in ${filename}`);
  };
  try {
    vm.runInThisContext(source, { filename });
  } finally {
    delete globalThis.require;
  }
}

/**
 * Reset all globals that template code may set.
 */
export function cleanTemplateGlobals() {
  for (const key of [
    "wx", "tt", "TTMinis", "WXWebAssembly", "TTWebAssembly",
    "__godotMiniGamePlatformRuntime", "PlatformRuntime",
    "godotSdk", "godotMiniGameBridgeV1",
    "__adapter", "__GodotLoader", "__waitForImage",
    "GameGlobal",
  ]) {
    delete globalThis[key];
  }
}
