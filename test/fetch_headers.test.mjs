import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";

const projectRoot = path.resolve(import.meta.dirname, "..");
const commonRoot = path.join(projectRoot, "addons/godot_mini_game/templates/common");

async function loadFetchFixture() {
  delete globalThis.wx;
  delete globalThis.tt;
  delete globalThis.TTMinis;
  delete globalThis.__godotMiniGamePlatformRuntime;
  delete globalThis.PlatformRuntime;

  const calls = [];
  globalThis.GameGlobal = { __platform: "wechat" };
  globalThis.wx = {
    getFileSystemManager() { return {}; },
    request(options) {
      calls.push(options);
      options.success({
        data: new Uint8Array([1, 2, 3]).buffer,
        statusCode: 200,
        errMsg: "request:ok",
        header: [["Content-Type", "application/octet-stream"]],
      });
    },
  };

  const runtimeSource = fs.readFileSync(path.join(commonRoot, "js/platform_runtime.js"), "utf8");
  const fetchSource = fs.readFileSync(path.join(commonRoot, "fetch.js"), "utf8");
  // Execute platform_runtime first (sets PlatformRuntime global)
  vm.runInThisContext(`(function(){${runtimeSource}})()`, { filename: "platform_runtime.js" });
  // Then execute fetch.js (reads PlatformRuntime from globals)
  vm.runInThisContext(`(function(){${fetchSource}})()`, { filename: "fetch.js" });
  return { calls, ...globalThis.GameGlobal };
}

async function testTupleHeadersPreserveCredentialsAndBinaryNegotiation() {
  const fixture = await loadFetchFixture();
  const headers = new fixture.Headers([
    ["Authorization", "Bearer token"],
    ["Accept", "application/octet-stream"],
  ]);

  assert.deepEqual([...headers], [
    ["Authorization", "Bearer token"],
    ["Accept", "application/octet-stream"],
  ]);
  assert.equal(headers.get("authorization"), "Bearer token");
  assert.equal(headers.get("ACCEPT"), "application/octet-stream");

  const response = await fixture.fetch("https://api.example.com/data.bin", { headers });
  assert.equal(fixture.calls.length, 1);
  assert.deepEqual(fixture.calls[0].header, {
    Authorization: "Bearer token",
    Accept: "application/octet-stream",
  });
  assert.equal(fixture.calls[0].responseType, "arraybuffer");
  assert.deepEqual([...new Uint8Array(await response.arrayBuffer())], [1, 2, 3]);
}

async function testNativeHeadersAndExplicitArrayBufferAreAccepted() {
  const nativeHeaders = typeof globalThis.Headers === "function"
    ? new globalThis.Headers({ Authorization: "Basic abc", Accept: "text/plain" })
    : {
        forEach(callback) {
          callback("Basic abc", "authorization");
          callback("text/plain", "accept");
        },
      };
  const fixture = await loadFetchFixture();

  await fixture.fetch("https://api.example.com/explicit.bin", {
    headers: nativeHeaders,
    responseType: "arraybuffer",
  });

  assert.equal(fixture.calls[0].header.authorization, "Basic abc");
  assert.equal(fixture.calls[0].header.accept, "text/plain");
  assert.equal(fixture.calls[0].responseType, "arraybuffer");
}

async function testStreamErrorsAndZeroStatusRemainObservable() {
  const fixture = await loadFetchFixture();
  const failure = new Error("stream failed");
  const stream = new fixture.ReadableStream({
    start(controller) { controller.error(failure); },
  });
  await assert.rejects(stream.getReader().read(), (error) => error === failure);

  const response = new fixture.Response(null, { status: 0 });
  assert.equal(response.status, 0);
  assert.equal(response.ok, false);
}

await testTupleHeadersPreserveCredentialsAndBinaryNegotiation();
await testNativeHeadersAndExplicitArrayBufferAreAccepted();
await testStreamErrorsAndZeroStatusRemainObservable();

console.log("fetch_headers.test.mjs: ok");
