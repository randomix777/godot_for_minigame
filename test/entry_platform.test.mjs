import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";

const projectRoot = path.resolve(import.meta.dirname, "..");
const templateRoot = path.join(projectRoot, "addons/godot_mini_game/templates");

function read(relativePath) {
  return fs.readFileSync(path.join(templateRoot, relativePath), "utf8");
}

async function importEntrypoint(entryPlatform, availablePlatform) {
  delete globalThis.wx;
  delete globalThis.tt;
  delete globalThis.TTMinis;
  delete globalThis.my;
  delete globalThis.swan;
  delete globalThis.qq;
  delete globalThis.ks;
  delete globalThis.__godotMiniGamePlatformRuntime;
  delete globalThis.PlatformRuntime;
  delete globalThis.__GodotLoader;
  globalThis.GameGlobal = {};
  if (availablePlatform === "wechat") globalThis.wx = {};
  if (availablePlatform === "douyin") globalThis.tt = {};
  if (availablePlatform === "tiktok") globalThis.TTMinis = { game: {} };
  if (availablePlatform === "alipay") globalThis.my = {};
  if (availablePlatform === "baidu") globalThis.swan = {};
  if (availablePlatform === "qq") globalThis.qq = {};
  if (availablePlatform === "kuaishou") globalThis.ks = {};
  globalThis.__entryLoaderCalls = 0;

  // Execute platform_runtime.js to set PlatformRuntime global
  vm.runInThisContext(`(function(){${read("common/js/platform_runtime.js")}})()`, { filename: "platform_runtime.js" });

  // Provide a mock require for game.js dependencies
  globalThis.require = (id) => {
    if (id === "./js/loader") {
      // Set up a stub Loader on GameGlobal
      globalThis.GameGlobal.__GodotLoader = class {
        constructor() { globalThis.__entryLoaderCalls += 1; }
        load() { return Promise.resolve(); }
      };
    }
    // adapter, fetch, sdk, image_loader, godot — no-ops (globals already set)
  };

  try {
    let source = read(`${entryPlatform}/game.js`);
    vm.runInThisContext(`(function(){${source}})()`, { filename: `${entryPlatform}/game.js` });
  } finally {
    delete globalThis.require;
  }
}

for (const platform of ["wechat", "douyin", "tiktok", "alipay", "baidu", "qq", "kuaishou"]) {
  await importEntrypoint(platform, platform);
  assert.equal(globalThis.__entryLoaderCalls, 1, `${platform} should boot on its own provider`);
}

await assert.rejects(
  importEntrypoint("wechat", "douyin"),
  /WeChat entrypoint requires wechat, but detected douyin/,
);
assert.equal(globalThis.__entryLoaderCalls, 0);

await assert.rejects(
  importEntrypoint("douyin", "wechat"),
  /Douyin entrypoint requires douyin, but detected wechat/,
);
assert.equal(globalThis.__entryLoaderCalls, 0);

await assert.rejects(
  importEntrypoint("tiktok", "douyin"),
  /TikTok entrypoint requires tiktok, but detected douyin/,
);
assert.equal(globalThis.__entryLoaderCalls, 0);

await assert.rejects(
  importEntrypoint("douyin", "tiktok"),
  /Douyin entrypoint requires douyin, but detected tiktok/,
);
assert.equal(globalThis.__entryLoaderCalls, 0);

// Test new platform mismatches
await assert.rejects(
  importEntrypoint("alipay", "wechat"),
  /Alipay entrypoint requires alipay, but detected wechat/,
);
assert.equal(globalThis.__entryLoaderCalls, 0);

await assert.rejects(
  importEntrypoint("baidu", "douyin"),
  /Baidu entrypoint requires baidu, but detected douyin/,
);
assert.equal(globalThis.__entryLoaderCalls, 0);

await assert.rejects(
  importEntrypoint("qq", "alipay"),
  /QQ entrypoint requires qq, but detected alipay/,
);
assert.equal(globalThis.__entryLoaderCalls, 0);

await assert.rejects(
  importEntrypoint("kuaishou", "baidu"),
  /Kuaishou entrypoint requires kuaishou, but detected baidu/,
);
assert.equal(globalThis.__entryLoaderCalls, 0);

console.log("entry_platform.test.mjs: ok");
