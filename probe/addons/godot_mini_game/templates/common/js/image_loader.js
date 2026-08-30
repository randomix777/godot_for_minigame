function waitForImage(image) {
  if (!image) return Promise.resolve();
  if (image.complete) return Promise.resolve();

  return new Promise((resolve) => {
    image.onload = resolve;
    image.onerror = resolve;
  });
}

// Expose as global for loader.js
var _ilGlobal = (typeof GameGlobal !== "undefined") ? GameGlobal : globalThis;
_ilGlobal.__waitForImage = waitForImage;
