// Load dependencies in explicit order (no ES module imports)
var _g = (typeof GameGlobal !== "undefined") ? GameGlobal : globalThis;
// TikTok DevTools may expose wx/tt compat aliases — force platform before detection
_g.__platform = "tiktok";
require("./js/platform_runtime");   // 1. Platform detection → sets PlatformRuntime global
require("./adapter");               // 2. DOM/window/canvas polyfills (needs PlatformRuntime)
require("./fetch");                 // 3. Fetch polyfill (needs PlatformRuntime)
require("./js/libs/sdk");           // 4. GodotSDK bridge (needs PlatformRuntime)
require("./js/image_loader");       // 5. Image loading helper
require("./js/libs/godot");         // 6. WebAssembly shim
require("./js/loader");             // 7. Engine loader (needs all above)

var PlatformRuntime = _g.PlatformRuntime;
var Loader = _g.__GodotLoader;
var _api = PlatformRuntime.requirePlatform("tiktok", "TikTok entrypoint");

function checkUpdate() {
  try {
    if (typeof _api.getUpdateManager !== "function") return;
    const updater = _api.getUpdateManager();
    if (!updater) return;
    if (typeof updater.onCheckForUpdate === "function") updater.onCheckForUpdate(() => {});
    if (typeof updater.onUpdateReady === "function") updater.onUpdateReady(() => {
      if (typeof _api.showModal !== "function") return;
      _api.showModal({
        title: "Update available",
        content: "A new version is ready. Restart now?",
        success(res) {
          if (res.confirm && typeof updater.applyUpdate === "function") updater.applyUpdate();
        },
      });
    });
    if (typeof updater.onUpdateFailed === "function") updater.onUpdateFailed(() => {});
  } catch {}
}

checkUpdate();
const loader = new Loader();
loader.load().catch((error) => console.error("[Game] TikTok startup failed:", error));
