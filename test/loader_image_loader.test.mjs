import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";

const projectRoot = path.resolve(import.meta.dirname, "..");
const helperPath = path.join(projectRoot, "addons/godot_mini_game/templates/common/js/image_loader.js");
const helperSource = fs.readFileSync(helperPath, "utf8");
// image_loader.js no longer has ES module exports — execute it and read globals
vm.runInThisContext(`(function(){${helperSource}})()`, { filename: "image_loader.js" });
const waitForImage = globalThis.__waitForImage;

async function testAlreadyCompletedImageResolvesImmediately() {
  const image = { complete: true };
  await waitForImage(image);
  assert.equal(image.onload, undefined);
  assert.equal(image.onerror, undefined);
}

async function testPendingImageResolvesOnLoad() {
  const image = { complete: false };
  let resolved = false;
  const pending = waitForImage(image).then(() => { resolved = true; });

  await Promise.resolve();
  assert.equal(resolved, false);
  assert.equal(typeof image.onload, "function");
  assert.equal(typeof image.onerror, "function");

  image.onload();
  await pending;
  assert.equal(resolved, true);
}

async function testMissingImageIsSafe() {
  await waitForImage(null);
}

await testAlreadyCompletedImageResolvesImmediately();
await testPendingImageResolvesOnLoad();
await testMissingImageIsSafe();

console.log("loader_image_loader.test.mjs: ok");
