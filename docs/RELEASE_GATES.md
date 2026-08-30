# v0.3.0 Release Gates

## Automated Verification

| Test Suite | Result | Details |
|-----------|--------|---------|
| Node.js tests (12) | ✅ PASS | 12/12 on Node.js v24.18.0 |
| Godot 4.6.1 headless import | ⚠️ N/A | Exit code 1 with no error output (expected for headless import) |
| Godot 4.6.1 smoke tests (13) | ✅ PASS | 13/13 — all test/*_test.gd |
| Export smoke (7 platforms) | ✅ PASS | wechat, douyin, tiktok, alipay, baidu, qq, kuaishou |
| Package reproducibility | ✅ PASS | Identical SHA-256 across runs |
| Plugin packaging | ✅ PASS | Deterministic ZIP via scripts/package_plugin.mjs |
| Website build | ✅ PASS | vinext build succeeds |
| Website tests (3) | ✅ PASS | 3/3 rendered HTML tests |
| Website lint | ✅ PASS | 0 errors, 18 warnings (img element — acceptable) |

### Node.js Test Files (test/*.test.mjs)

| Test | Status |
|------|--------|
| adapter_layout.test.mjs | ✅ |
| entry_platform.test.mjs | ✅ |
| fetch_headers.test.mjs | ✅ |
| loader_image_loader.test.mjs | ✅ |
| loader_runtime.test.mjs | ✅ |
| loader_sdk_global.test.mjs | ✅ |
| package_reproducibility.test.mjs | ✅ |
| platform_runtime.test.mjs | ✅ |
| readme_homepage.test.mjs | ✅ |
| release_contract.test.mjs | ✅ |
| sdk_bridge.test.mjs | ✅ |
| tt_platform_smoke.test.mjs | ✅ |

### Godot Test Files (test/*_test.gd) — Godot 4.6.1

| Test | Status |
|------|--------|
| demo_audio_test.gd | ✅ |
| demo_layout_test.gd | ✅ |
| exporter_output_transaction_test.gd | ✅ |
| exporter_platform_contract_test.gd | ✅ |
| exporter_smoke_test.gd | ✅ |
| exporter_template_bundle_test.gd | ✅ |
| exporter_version_test.gd | ✅ |
| minigame_sdk_mock_test.gd | ✅ |
| minigame_sdk_test.gd | ✅ |
| package_startup_perf_test.gd | ✅ |
| productization_test.gd | ✅ |
| release_candidate_test.gd | ✅ |
| version_manager_test.gd | ✅ |

---

## Platform Support (v0.3.0)

### Supported Platforms

| Platform | API | Export Smoke | DevTools Compilation | Real Device | Status |
|----------|-----|-------------|---------------------|-------------|--------|
| 微信小游戏 (WeChat) | `wx` | ✅ Automated | ✅ Manual (2026-08-29) | ✅ Manual (2026-08-29) | Certified |
| 抖音小游戏 (Douyin) | `tt` | ✅ Automated | ✅ Manual (2026-08-29) | 🔴 Pending | Certified (real device pending) |
| TikTok Mini Game | `TTMinis.game` | ✅ Automated | 🟡 Partial (ttmg v0.4.5) | 🔴 Pending | Beta |
| 支付宝小游戏 (Alipay) | `my` | ✅ Automated | 🔴 Not verified | 🔴 Not verified | Experimental |
| 百度小游戏 (Baidu) | `swan` | ✅ Automated | 🔴 Not verified | 🔴 Not verified | Experimental |
| QQ小游戏 (QQ) | `qq` | ✅ Automated | 🔴 Not verified | 🔴 Not verified | Experimental |
| 快手小游戏 (Kuaishou) | `ks` | ✅ Automated | 🔴 Not verified | 🔴 Not verified | Experimental |

---

## Manual Verification Evidence

### ✅ PASSED: WeChat DevTools Compilation

**What**: Export to WeChat, open in WeChat DevTools, verify compilation succeeds.
**Result**: ✅ PASSED — 2026-08-29
**Tool**: WeChat DevTools v2.01.2510290, base library 3.17.2
**Evidence**: Simulator displays game canvas without compilation errors.
**Fix applied**: Converted all template JS files from ES module to CommonJS.

### ✅ PASSED: WeChat Real Device Test

**What**: Scan QR code on a real device, verify game loads and runs.
**Result**: ✅ PASSED — 2026-08-29
**Tool**: WeChat client 8.0+
**Evidence**: Game loads and runs correctly on real device.

### ✅ PASSED: Douyin DevTools Compilation

**What**: Export to Douyin, open in Douyin DevTools, verify compilation.
**Result**: ✅ PASSED — 2026-08-29
**Tool**: 抖音开发者工具 v4.5.5
**Evidence**: Console shows `[Loader] ✓ 加载完成，游戏已启动`. No errors.
**Fix applied**: Added `GameGlobal.__platform = "douyin"` before platform_runtime load.

---

## Manual Gates Still Required

### 🔴 BLOCKING: Douyin Real Device Test

**What**: Test on a real device with Douyin installed.
**Why**: Required to validate runtime behavior beyond DevTools compilation.
**Evidence needed**: Screenshot of game running + console output
**Steps**:
1. Export probe project to Douyin
2. Open in Douyin DevTools
3. Scan QR code with Douyin app on phone
4. Verify game loads and runs
**Blocking**: Yes — required for release

### 🔴 BLOCKING: TikTok Compilation with ttmg v0.4.1-beta.wasm1

**What**: Export to TikTok, compile with ttmg v0.4.1-beta.wasm1 (not v0.4.5).
**Why**: support-matrix.json specifies ttmg v0.4.1-beta.wasm1 for TikTok.
**Evidence needed**: ttmg compilation log + success output
**Steps**:
1. Export probe project to TikTok directory
2. Install ttmg v0.4.1-beta.wasm1: `npm install -g @ttmg/cli@0.4.1-beta.wasm1`
3. Run `ttmg dev --client-key <key>` in export directory
4. Verify compilation succeeds
**Blocking**: Yes — required for release

### 🔴 BLOCKING: TikTok Real Device Test

**What**: Test on device with TikTok v43.4.0+ installed.
**Why**: TikTok runtime is beta — real device verification is mandatory.
**Evidence needed**: Screenshot of game running on TikTok
**Steps**:
1. After ttmg compilation succeeds
2. Scan QR code with TikTok v43.4.0+ on phone
3. Verify game loads and runs
**Blocking**: Yes — required for release

---

## Environment Requirements

| Platform | Tool | Version | Status |
|----------|------|---------|--------|
| WeChat | 微信开发者工具 | v2.01.2510290 | ✅ Verified |
| WeChat | WeChat client | 8.0+ | ✅ Verified |
| Douyin | 抖音开发者工具 | v4.5.5 | ✅ Verified |
| Douyin | Douyin client | Latest | 🔴 Pending |
| TikTok | ttmg | v0.4.1-beta.wasm1 | 🟡 v0.4.5 tested, need v0.4.1-beta.wasm1 |
| TikTok | TikTok client | 43.4.0+ | 🔴 Pending |
| Alipay | 支付宝开发者工具 | Latest | 🔴 Not verified |
| Baidu | 百度开发者工具 | Latest | 🔴 Not verified |
| QQ | QQ开发者工具 | Latest | 🔴 Not verified |
| Kuaishou | 快手开发者工具 | Latest | 🔴 Not verified |

---

## Release Checklist

- [x] All Node.js automated tests pass (12/12)
- [x] All Godot automated tests pass (13/13 on 4.6.1)
- [x] Export smoke test passes (7 platforms)
- [x] Plugin packages correctly (deterministic ZIP)
- [x] Version metadata consistent (0.3.0 everywhere)
- [x] Website build/test/lint pass on Windows
- [ ] **Git working tree clean** — NOT YET (uncommitted changes)
- [x] **WeChat DevTools compilation** — ✅ PASSED 2026-08-29
- [x] **WeChat real device test** — ✅ PASSED 2026-08-29
- [x] **Douyin DevTools compilation** — ✅ PASSED 2026-08-29
- [ ] **Douyin real device test** — BLOCKING
- [ ] **TikTok compilation (ttmg v0.4.1-beta.wasm1)** — BLOCKING
- [ ] **TikTok real device test** — BLOCKING

---

## What NOT to Do

- Do NOT claim manual gates are "passed" without evidence
- Do NOT create or push a git tag until all blockers are cleared
- Do NOT mark Godot 4.7.1 as certified (template asset not available)
- Do NOT mark experimental platforms (alipay/baidu/qq/kuaishou) as certified without DevTools verification
