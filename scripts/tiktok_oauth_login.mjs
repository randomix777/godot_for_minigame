#!/usr/bin/env node
/**
 * TikTok Mini Game OAuth Login Script
 *
 * Starts a local HTTP server, opens TikTok developer portal in browser,
 * captures the session cookie after user logs in, and stores it in ~/.ttmgrc.
 *
 * Usage:
 *   node scripts/tiktok_oauth_login.mjs [--port 37769]
 *
 * This avoids storing email/password in plaintext — the user authenticates
 * directly in the browser via TikTok's official login page.
 */

import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { execSync } from "node:child_process";

const CONFIG_PATH = process.env.TTMGRC_PATH || path.join(os.homedir(), ".ttmgrc");
const PORT = parseInt(process.argv.find((_, i, a) => a[i - 1] === "--port") || "37769", 10);
const TIKTOK_DEV_PORTAL = "https://developers.tiktok.com";
const REDIRECT_PATH = "/callback";

// ── Helpers ───────────────────────────────────────────────────────

function log(msg) {
  console.log(`\x1b[36m[tiktok-oauth]\x1b[0m ${msg}`);
}

function warn(msg) {
  console.log(`\x1b[33m[tiktok-oauth]\x1b[0m ${msg}`);
}

function success(msg) {
  console.log(`\x1b[32m[tiktok-oauth]\x1b[0m ${msg}`);
}

function error(msg) {
  console.log(`\x1b[31m[tiktok-oauth]\x1b[0m ${msg}`);
}

function openUrl(url) {
  const platform = process.platform;
  const cmd =
    platform === "win32" ? `start "" "${url}"` :
    platform === "darwin" ? `open "${url}"` :
    `xdg-open "${url}"`;
  try {
    execSync(cmd, { stdio: "ignore" });
  } catch {
    warn(`请手动打开浏览器访问: ${url}`);
  }
}

function readConfig() {
  try {
    if (fs.existsSync(CONFIG_PATH)) {
      return JSON.parse(fs.readFileSync(CONFIG_PATH, "utf8"));
    }
  } catch {}
  return {};
}

function writeConfig(config) {
  const existing = readConfig();
  const merged = { ...existing, ...config };
  fs.writeFileSync(CONFIG_PATH, JSON.stringify(merged, null, 2));
  log(`配置已保存到 ${CONFIG_PATH}`);
}

// ── Capture Cookie from TikTok DevTools ───────────────────────────

function parseCookies(cookieHeader) {
  const cookies = {};
  if (!cookieHeader) return cookies;
  for (const pair of cookieHeader.split(";")) {
    const [key, ...rest] = pair.trim().split("=");
    if (key) cookies[key.trim()] = rest.join("=").trim();
  }
  return cookies;
}

// ── Main Server ───────────────────────────────────────────────────

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);

  // Serve a simple page that posts cookie info back
  if (url.pathname === "/") {
    res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    res.end(`
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>TikTok Mini Game Login</title>
<style>
  body { font-family: -apple-system, sans-serif; max-width: 640px; margin: 40px auto; padding: 20px; background: #fafafa; }
  .card { background: #fff; border-radius: 12px; padding: 24px; margin: 16px 0; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
  .step { margin: 10px 0; padding: 10px 12px; background: #f9f9f9; border-radius: 8px; }
  .step-num { font-weight: bold; color: #fe2c55; }
  button { background: #fe2c55; color: white; border: none; padding: 12px 24px; border-radius: 8px;
           font-size: 15px; cursor: pointer; margin: 8px 4px; }
  button:hover { background: #e0264c; }
  button.secondary { background: #6c757d; }
  input, textarea { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px;
                    font-family: monospace; font-size: 13px; box-sizing: border-box; margin: 6px 0; }
  textarea { height: 80px; resize: vertical; }
  #status { margin-top: 12px; padding: 12px; border-radius: 8px; display: none; }
  .ok { background: #d4edda; color: #155724; }
  .err { background: #f8d7da; color: #721c24; }
  .info { background: #d1ecf1; color: #0c5460; }
</style>
</head>
<body>
  <h1>TikTok Mini Game Login</h1>

  <div class="card">
    <h3>Method 1: Session ID (Recommended)</h3>
    <div class="step"><span class="step-num">1.</span> Open <a href="${TIKTOK_DEV_PORTAL}" target="_blank">TikTok Developers</a> and login</div>
    <div class="step"><span class="step-num">2.</span> Press F12 -> Application -> Cookies -> copy <code>sessionid</code> value</div>
    <div class="step"><span class="step-num">3.</span> Paste below and click Login</div>
    <textarea id="cookieInput" placeholder="Paste sessionid cookie value here..."></textarea>
    <button onclick="loginWithCookie()">Login with Session ID</button>
  </div>

  <div class="card">
    <h3>Method 2: Full Cookie String</h3>
    <div class="step">Copy all cookies from developers.tiktok.com (F12 -> Network -> any request -> Cookie header)</div>
    <textarea id="fullCookieInput" placeholder="Paste full cookie string here..."></textarea>
    <button onclick="loginWithFullCookie()" class="secondary">Login with Cookie String</button>
  </div>

  <div id="status"></div>

  <script>
    function showStatus(msg, cls) {
      const s = document.getElementById("status");
      s.style.display = "block";
      s.textContent = msg;
      s.className = cls;
    }
    async function loginWithCookie() {
      const val = document.getElementById("cookieInput").value.trim();
      if (!val) { showStatus("Please paste your sessionid cookie value", "err"); return; }
      showStatus("Saving...", "info");
      const resp = await fetch("/save", {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({ session_id: val })
      });
      const data = await resp.json();
      showStatus(data.ok ? "Login OK! Token saved to ~/.ttmgrc" : data.message, data.ok ? "ok" : "err");
    }
    async function loginWithFullCookie() {
      const val = document.getElementById("fullCookieInput").value.trim();
      if (!val) { showStatus("Please paste your cookie string", "err"); return; }
      showStatus("Saving...", "info");
      const resp = await fetch("/save", {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({ cookie: val })
      });
      const data = await resp.json();
      showStatus(data.ok ? "Login OK! Token saved to ~/.ttmgrc" : data.message, data.ok ? "ok" : "err");
    }
  </script>
</body>
</html>`);
    return;
  }

  // Save session/cookie to config
  if (url.pathname === "/save" && req.method === "POST") {
    res.writeHead(200, { "Content-Type": "application/json" });
    let body = "";
    req.on("data", (chunk) => { body += chunk; });
    req.on("end", () => {
      try {
        const data = JSON.parse(body);
        if (data.session_id) {
          writeConfig({
            session_id: data.session_id,
            clientKey: data.client_key || "",
            login_method: "session_id",
          });
          res.end(JSON.stringify({ ok: true }));
          success("session_id 已保存");
        } else if (data.cookie) {
          // Parse full cookie string into key-value pairs
          const cookies = {};
          for (const pair of data.cookie.split(";")) {
            const [key, ...rest] = pair.trim().split("=");
            if (key) cookies[key.trim()] = rest.join("=").trim();
          }
          writeConfig({
            cookies,
            session_id: cookies.session_id || cookies.sessionid || "",
            clientKey: cookies.tt_webid || "",
            login_method: "cookie",
          });
          res.end(JSON.stringify({ ok: true }));
          success("Cookies 已保存");
        } else {
          res.end(JSON.stringify({ ok: false, message: "No session_id or cookie provided" }));
        }
      } catch (e) {
        res.end(JSON.stringify({ ok: false, message: e.message }));
      }
    });
    return;
  }

  // OAuth callback endpoint
  if (url.pathname === REDIRECT_PATH) {
    const code = url.searchParams.get("code");
    const state = url.searchParams.get("state");

    if (code) {
      log(`收到授权码: ${code.substring(0, 10)}...`);

      // Exchange code for token
      try {
        const tokenResp = await fetch("https://open.tiktokapis.com/v2/oauth/token/", {
          method: "POST",
          headers: { "Content-Type": "application/x-www-form-urlencoded" },
          body: new URLSearchParams({
            client_key: process.env.TIKTOK_CLIENT_KEY || "",
            client_secret: process.env.TIKTOK_CLIENT_SECRET || "",
            code,
            grant_type: "authorization_code",
          }),
        });
        const tokenData = await tokenResp.json();

        if (tokenData.data && tokenData.data.access_token) {
          writeConfig({
            access_token: tokenData.data.access_token,
            refresh_token: tokenData.data.refresh_token,
            open_id: tokenData.data.open_id,
            expires_in: tokenData.data.expires_in,
            token_type: tokenData.data.token_type,
            scope: tokenData.data.scope,
          });

          res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
          res.end(`
<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>登录成功</title></head>
<body style="font-family:sans-serif;text-align:center;padding:40px">
  <h1>✅ 登录成功！</h1>
  <p>TikTok OAuth token 已保存到 <code>${CONFIG_PATH}</code></p>
  <p>可以关闭此页面了。</p>
  <script>setTimeout(() => window.close(), 3000);</script>
</body></html>`);
          success("OAuth 登录成功！Token 已保存。");
        } else {
          throw new Error(JSON.stringify(tokenData));
        }
      } catch (e) {
        res.writeHead(500, { "Content-Type": "text/html; charset=utf-8" });
        res.end(`<h1>❌ Token 交换失败</h1><pre>${e.message}</pre>`);
        error(`Token 交换失败: ${e.message}`);
      }
    } else {
      res.writeHead(400, { "Content-Type": "text/html; charset=utf-8" });
      res.end("<h1>❌ 未收到授权码</h1>");
    }

    // Shutdown after callback
    setTimeout(() => { server.close(); process.exit(0); }, 1000);
    return;
  }

  // 404
  res.writeHead(404);
  res.end("Not Found");
});

// ── Session ID login (shortcut) ───────────────────────────────────
if (process.argv.includes("--session-id")) {
  const idx = process.argv.indexOf("--session-id");
  const sessionId = process.argv[idx + 1];
  if (!sessionId) {
    error("请提供 session_id 值");
    process.exit(1);
  }
  writeConfig({ session_id: sessionId, login_method: "cookie" });
  success(`session_id 已保存到 ${CONFIG_PATH}`);
  process.exit(0);
}

// ── Start ─────────────────────────────────────────────────────────

server.listen(PORT, () => {
  log(`本地服务器已启动: http://localhost:${PORT}`);

  const callbackUrl = `http://localhost:${PORT}${REDIRECT_PATH}`;
  log(`OAuth 回调地址: ${callbackUrl}`);

  const oauthUrl = `https://www.tiktok.com/v2/auth/authorize/` +
    `?client_key=${process.env.TIKTOK_CLIENT_KEY || "YOUR_CLIENT_KEY"}` +
    `&response_type=code` +
    `&scope=user.info.basic` +
    `&redirect_uri=${encodeURIComponent(callbackUrl)}` +
    `&state=tiktok_minigame_${Date.now()}`;

  console.log("");
  console.log("╔══════════════════════════════════════════════════╗");
  console.log("║       TikTok Mini Game OAuth 登录               ║");
  console.log("╠══════════════════════════════════════════════════╣");
  console.log("║                                                  ║");
  console.log("║  方式 1: OAuth 浏览器跳转（推荐）                ║");
  console.log("║    1. 设置环境变量 TIKTOK_CLIENT_KEY            ║");
  console.log("║    2. 浏览器会自动打开授权页面                   ║");
  console.log("║    3. 授权后自动回调保存 token                   ║");
  console.log("║                                                  ║");
  console.log("║  方式 2: Session ID 登录                        ║");
  console.log("║    node scripts/tiktok_oauth_login.mjs \\        ║");
  console.log("║      --session-id YOUR_SESSION_ID               ║");
  console.log("║                                                  ║");
  console.log("║  方式 3: ttmg login（邮箱密码）                 ║");
  console.log("║    ttmg login                                   ║");
  console.log("║                                                  ║");
  console.log("╚══════════════════════════════════════════════════╝");
  console.log("");

  if (process.env.TIKTOK_CLIENT_KEY && process.env.TIKTOK_CLIENT_KEY !== "YOUR_CLIENT_KEY") {
    log("检测到 TIKTOK_CLIENT_KEY，正在打开 OAuth 授权页面...");
    openUrl(oauthUrl);
  } else {
    warn("未设置 TIKTOK_CLIENT_KEY 环境变量");
    log("请在 TikTok Developers (https://developers.tiktok.com) 注册应用获取 client_key");
    log("然后运行: set TIKTOK_CLIENT_KEY=your_key && node scripts/tiktok_oauth_login.mjs");
    log("");
    log("或者使用交互式登录页面: http://localhost:" + PORT);
    openUrl(`http://localhost:${PORT}`);
  }
});
