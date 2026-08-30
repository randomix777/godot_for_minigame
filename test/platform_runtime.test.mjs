import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";

const projectRoot = path.resolve(import.meta.dirname, "..");
const runtimePath = path.join(
  projectRoot,
  "addons/godot_mini_game/templates/common/js/platform_runtime.js",
);

async function loadRuntime({
  wxApi,
  ttApi,
  tiktokApi,
  myApi,
  swanApi,
  qqApi,
  ksApi,
  gameGlobalTiktokApi,
  explicitPlatform,
  cachedRuntime,
  wxWebAssembly,
  ttWebAssembly,
  gameGlobalTtWebAssembly,
} = {}) {
  delete globalThis.wx;
  delete globalThis.tt;
  delete globalThis.TTMinis;
  delete globalThis.my;
  delete globalThis.swan;
  delete globalThis.qq;
  delete globalThis.ks;
  delete globalThis.WXWebAssembly;
  delete globalThis.TTWebAssembly;
  delete globalThis.__godotMiniGamePlatformRuntime;
  delete globalThis.PlatformRuntime;
  globalThis.GameGlobal = explicitPlatform ? { __platform: explicitPlatform } : {};
  if (cachedRuntime) {
    globalThis.__godotMiniGamePlatformRuntime = cachedRuntime;
    globalThis.GameGlobal.__godotMiniGamePlatformRuntime = cachedRuntime;
  }
  if (wxApi) globalThis.wx = wxApi;
  if (ttApi) globalThis.tt = ttApi;
  if (tiktokApi) globalThis.TTMinis = { game: tiktokApi };
  if (myApi) globalThis.my = myApi;
  if (swanApi) globalThis.swan = swanApi;
  if (qqApi) globalThis.qq = qqApi;
  if (ksApi) globalThis.ks = ksApi;
  if (gameGlobalTiktokApi) globalThis.GameGlobal.TTMinis = { game: gameGlobalTiktokApi };
  if (wxWebAssembly) globalThis.WXWebAssembly = wxWebAssembly;
  if (ttWebAssembly) globalThis.TTWebAssembly = ttWebAssembly;
  if (gameGlobalTtWebAssembly) globalThis.GameGlobal.TTWebAssembly = gameGlobalTtWebAssembly;

  const source = fs.readFileSync(runtimePath, "utf8");
  // Wrap in IIFE to isolate const/let declarations across multiple calls
  vm.runInThisContext(`(function(){${source}})()`, { filename: "platform_runtime.js" });
  // platform_runtime.js sets globals — return a compat object for destructuring
  return { PlatformRuntime: globalThis.__godotMiniGamePlatformRuntime || globalThis.PlatformRuntime };
}

function makeApi() {
  return {
    createCanvas() { return {}; },
    request() {},
    getStorageSync() { return null; },
    setStorageSync() {},
  };
}

async function testWxOnlyDetection() {
  const wxApi = makeApi();
  const { PlatformRuntime } = await loadRuntime({ wxApi });

  assert.equal(PlatformRuntime.platform, "wechat");
  assert.equal(PlatformRuntime.apiPrefix, "wx");
  assert.equal(PlatformRuntime.requireApi("test"), wxApi);
  assert.equal(PlatformRuntime.capabilities.canvas, true);
  assert.equal(PlatformRuntime.capabilities.request, true);
  assert.equal(PlatformRuntime.brand, "godot-mini-game-platform-runtime");
  assert.equal(PlatformRuntime.schemaVersion, 1);
  assert.equal(PlatformRuntime.abiVersion, 1);
  assert.equal(PlatformRuntime.requirePlatform("wechat", "test"), wxApi);
  assert.equal(PlatformRuntime.requireCapabilities(["canvas", "request"], "test"), wxApi);
  assert.equal(globalThis.GameGlobal.PlatformRuntime, PlatformRuntime);
  assert.equal(globalThis.__godotMiniGamePlatformRuntime, PlatformRuntime);
}

async function testTtOnlyDetection() {
  const ttApi = makeApi();
  const { PlatformRuntime } = await loadRuntime({ ttApi });

  assert.equal(PlatformRuntime.platform, "douyin");
  assert.equal(PlatformRuntime.apiPrefix, "tt");
  assert.equal(PlatformRuntime.requireApi("test"), ttApi);
  assert.equal(PlatformRuntime.getBridgeInfo().abiVersion, 1);
  assert.equal(PlatformRuntime.getBridgeInfo().platform, "douyin");
  assert.throws(
    () => PlatformRuntime.requirePlatform("wechat", "WeChat entrypoint"),
    /requires wechat, but detected douyin/,
  );
}

async function testTiktokOnlyDetection() {
  const tiktokApi = {
    ...makeApi(),
    onShow() {},
    onHide() {},
  };
  const ttWebAssembly = { instantiate() {} };
  const { PlatformRuntime } = await loadRuntime({ tiktokApi, ttWebAssembly });

  assert.equal(PlatformRuntime.platform, "tiktok");
  assert.equal(PlatformRuntime.apiPrefix, "TTMinis.game");
  assert.equal(PlatformRuntime.requireApi("test"), tiktokApi);
  assert.equal(PlatformRuntime.requirePlatform("tiktok", "TikTok entrypoint"), tiktokApi);
  assert.deepEqual(PlatformRuntime.getNativeWebAssemblyApis(), [ttWebAssembly]);
  assert.equal(PlatformRuntime.capabilities.lifecycle, true);
  assert.equal(PlatformRuntime.capabilities.runtimeError, false);
}

async function testGameGlobalTiktokDetection() {
  const gameGlobalTiktokApi = makeApi();
  const wxApi = makeApi();
  const ttApi = makeApi();
  const { PlatformRuntime } = await loadRuntime({
    wxApi,
    ttApi,
    gameGlobalTiktokApi,
  });

  assert.equal(globalThis.TTMinis, undefined);
  assert.equal(PlatformRuntime.platform, "tiktok");
  assert.equal(PlatformRuntime.apiPrefix, "TTMinis.game");
  assert.equal(PlatformRuntime.api, gameGlobalTiktokApi);
  assert.notEqual(PlatformRuntime.api, wxApi);
  assert.notEqual(PlatformRuntime.api, ttApi);
}

async function testNeitherProviderHasADescriptiveFailure() {
  const { PlatformRuntime } = await loadRuntime();

  assert.equal(PlatformRuntime.available, false);
  assert.equal(PlatformRuntime.platform, "unknown");
  assert.equal(PlatformRuntime.apiPrefix, "platform");
  assert.equal(PlatformRuntime.capabilities.canvas, false);
  assert.throws(
    () => PlatformRuntime.requireApi("adapter"),
    (error) => error instanceof Error
      && !(error instanceof ReferenceError)
      && error.message.includes("TTMinis.game"),
  );
}

async function testExplicitPlatformBreaksATwoProviderTie() {
  const wxApi = makeApi();
  const ttApi = makeApi();
  const { PlatformRuntime } = await loadRuntime({
    wxApi,
    ttApi,
    explicitPlatform: "douyin",
  });

  assert.equal(PlatformRuntime.platform, "douyin");
  assert.equal(PlatformRuntime.api, ttApi);
}

async function testMixedProvidersHaveStablePrecedence() {
  const wxApi = makeApi();
  const ttApi = makeApi();
  const tiktokApi = makeApi();

  const automatic = await loadRuntime({ wxApi, ttApi, tiktokApi });
  assert.equal(automatic.PlatformRuntime.platform, "tiktok");
  assert.equal(automatic.PlatformRuntime.api, tiktokApi);

  const byteDanceOnly = await loadRuntime({ ttApi, tiktokApi });
  assert.equal(byteDanceOnly.PlatformRuntime.platform, "tiktok");
  assert.equal(byteDanceOnly.PlatformRuntime.api, tiktokApi);

  const explicit = await loadRuntime({
    wxApi,
    ttApi,
    tiktokApi,
    explicitPlatform: "tiktok",
  });
  assert.equal(explicit.PlatformRuntime.platform, "tiktok");
  assert.equal(explicit.PlatformRuntime.api, tiktokApi);
}

async function testExplicitPlatformDoesNotFallBackToTheWrongApi() {
  const { PlatformRuntime } = await loadRuntime({
    wxApi: makeApi(),
    explicitPlatform: "douyin",
  });

  assert.equal(PlatformRuntime.platform, "douyin");
  assert.equal(PlatformRuntime.available, false);
  assert.throws(() => PlatformRuntime.requireApi("test"), /TTMinis\.game/);

  const explicitTiktok = await loadRuntime({
    ttApi: makeApi(),
    explicitPlatform: "tiktok",
  });
  assert.equal(explicitTiktok.PlatformRuntime.platform, "tiktok");
  assert.equal(explicitTiktok.PlatformRuntime.available, false);
  assert.throws(() => explicitTiktok.PlatformRuntime.requireApi("test"), /TTMinis\.game/);
}

async function testNativeWebAssemblySelectionSupportsBothByteDanceIdentities() {
  const ttWebAssembly = { instantiate() {} };
  const douyin = await loadRuntime({ ttApi: makeApi(), ttWebAssembly });
  assert.deepEqual(douyin.PlatformRuntime.getNativeWebAssemblyApis(), [ttWebAssembly]);

  const tiktok = await loadRuntime({ tiktokApi: makeApi(), ttWebAssembly });
  assert.deepEqual(tiktok.PlatformRuntime.getNativeWebAssemblyApis(), [ttWebAssembly]);

  const gameGlobalTtWebAssembly = { instantiate() {} };
  const nested = await loadRuntime({ tiktokApi: makeApi(), gameGlobalTtWebAssembly });
  assert.deepEqual(nested.PlatformRuntime.getNativeWebAssemblyApis(), [gameGlobalTtWebAssembly]);
}

async function testCapabilityFailureListsEveryMissingRequirement() {
  const { PlatformRuntime } = await loadRuntime({ wxApi: {} });

  assert.throws(
    () => PlatformRuntime.requireCapabilities(["canvas", "fileSystem", "touch"], "adapter"),
    /adapter is missing required capabilities: canvas, fileSystem, touch/,
  );
}

async function testSystemInfoSupportsEitherPlatformApi() {
  const modern = await loadRuntime({
    wxApi: { getWindowInfo() { return { windowWidth: 320, pixelRatio: 2 }; } },
  });
  assert.equal(modern.PlatformRuntime.capabilities.windowInfo, true);
  assert.deepEqual(modern.PlatformRuntime.getSystemInfo(), { windowWidth: 320, pixelRatio: 2 });

  const legacy = await loadRuntime({
    ttApi: { getSystemInfoSync() { return { platform: "devtools", windowHeight: 700 }; } },
  });
  assert.equal(legacy.PlatformRuntime.capabilities.windowInfo, true);
  assert.deepEqual(legacy.PlatformRuntime.getSystemInfo(), {
    platform: "devtools",
    windowHeight: 700,
  });
}

async function testForeignCachedRuntimeIsRejected() {
  const staleRuntime = {
    getBridgeInfo() { return { abiVersion: 0 }; },
  };
  const { PlatformRuntime } = await loadRuntime({
    wxApi: makeApi(),
    cachedRuntime: staleRuntime,
  });

  assert.notEqual(PlatformRuntime, staleRuntime);
  assert.equal(PlatformRuntime.abiVersion, 1);
  assert.equal(globalThis.__godotMiniGamePlatformRuntime, PlatformRuntime);
}

await testWxOnlyDetection();
await testTtOnlyDetection();
await testTiktokOnlyDetection();
await testAlipayOnlyDetection();
await testBaiduOnlyDetection();
await testQqOnlyDetection();
await testKuaishouOnlyDetection();
await testGameGlobalTiktokDetection();
await testNeitherProviderHasADescriptiveFailure();
await testExplicitPlatformBreaksATwoProviderTie();
await testMixedProvidersHaveStablePrecedence();
await testExplicitPlatformDoesNotFallBackToTheWrongApi();
await testNativeWebAssemblySelectionSupportsBothByteDanceIdentities();
await testCapabilityFailureListsEveryMissingRequirement();
await testSystemInfoSupportsEitherPlatformApi();
await testForeignCachedRuntimeIsRejected();

async function testAlipayOnlyDetection() {
  const myApi = makeApi();
  const { PlatformRuntime } = await loadRuntime({ myApi: myApi });

  assert.equal(PlatformRuntime.platform, "alipay");
  assert.equal(PlatformRuntime.apiPrefix, "my");
  assert.equal(PlatformRuntime.requireApi("test"), myApi);
  assert.equal(PlatformRuntime.capabilities.canvas, true);
  assert.equal(PlatformRuntime.requirePlatform("alipay", "test"), myApi);
  assert.throws(
    () => PlatformRuntime.requirePlatform("wechat", "WeChat entrypoint"),
    /requires wechat, but detected alipay/,
  );
}

async function testBaiduOnlyDetection() {
  const swanApi = makeApi();
  const { PlatformRuntime } = await loadRuntime({ swanApi: swanApi });

  assert.equal(PlatformRuntime.platform, "baidu");
  assert.equal(PlatformRuntime.apiPrefix, "swan");
  assert.equal(PlatformRuntime.requireApi("test"), swanApi);
  assert.equal(PlatformRuntime.capabilities.canvas, true);
  assert.equal(PlatformRuntime.requirePlatform("baidu", "test"), swanApi);
  assert.throws(
    () => PlatformRuntime.requirePlatform("wechat", "WeChat entrypoint"),
    /requires wechat, but detected baidu/,
  );
}

async function testQqOnlyDetection() {
  const qqApi = makeApi();
  const { PlatformRuntime } = await loadRuntime({ qqApi: qqApi });

  assert.equal(PlatformRuntime.platform, "qq");
  assert.equal(PlatformRuntime.apiPrefix, "qq");
  assert.equal(PlatformRuntime.requireApi("test"), qqApi);
  assert.equal(PlatformRuntime.capabilities.canvas, true);
  assert.equal(PlatformRuntime.requirePlatform("qq", "test"), qqApi);
  assert.throws(
    () => PlatformRuntime.requirePlatform("wechat", "WeChat entrypoint"),
    /requires wechat, but detected qq/,
  );
}

async function testKuaishouOnlyDetection() {
  const ksApi = makeApi();
  const { PlatformRuntime } = await loadRuntime({ ksApi: ksApi });

  assert.equal(PlatformRuntime.platform, "kuaishou");
  assert.equal(PlatformRuntime.apiPrefix, "ks");
  assert.equal(PlatformRuntime.requireApi("test"), ksApi);
  assert.equal(PlatformRuntime.capabilities.canvas, true);
  assert.equal(PlatformRuntime.requirePlatform("kuaishou", "test"), ksApi);
  assert.throws(
    () => PlatformRuntime.requirePlatform("wechat", "WeChat entrypoint"),
    /requires wechat, but detected kuaishou/,
  );
}

console.log("platform_runtime.test.mjs: ok");
