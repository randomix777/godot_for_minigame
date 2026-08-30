# v0.3.0 Release Gates

## Automated Verification

| Test Suite | Result | Details |
|-----------|--------|---------|
| Node.js tests (13) | ✅ PASS | 13/13 on Node.js v24.18.0 (incl. sha256sums_test.mjs) |
| Godot 4.6.1 headless import | ⚠️ N/A | Exit code 1 with no error output (expected for headless import) |
| Godot 4.6.1 smoke tests (13) | ✅ PASS | 13/13 — all test/*_test.gd |
| Export smoke (6 enabled platforms) | ✅ PASS | wechat, douyin, alipay, baidu, qq, kuaishou |
| Package reproducibility | ✅ PASS | Identical SHA-256 across runs |
| Plugin packaging | ✅ PASS | Deterministic ZIP via scripts/package_plugin.mjs |
| Website build | ✅ PASS | vinext build succeeds |
| Website tests (3) | ✅ PASS | 3/3 rendered HTML tests |
| Website lint | ✅ PASS | 0 errors, 15 warnings (img element — acceptable) |
| SHA256SUMS validation | ✅ PASS | 64 entries, UTF-8 no BOM, LF line endings, sorted |

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
| sha256sums_test.mjs | ✅ |

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
| 抖音小游戏 (Douyin) | `tt` | ✅ Automated | ✅ Manual (2026-08-29) | ✅ Manual (2026-08-29) | Certified |
| TikTok Mini Game | `TTMinis.game` | ⛔ Disabled | N/A | N/A | Disabled for v0.3.0 |
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

### ✅ PASSED: Douyin Real Device Test

**What**: Run the exported project on a physical device with Douyin installed.
**Result**: ✅ PASSED — 2026-08-29
**Evidence**: User confirmed that the game loads and runs correctly on the physical device.

### ⛔ DISABLED: TikTok Mini Game

TikTok export is intentionally unavailable in v0.3.0. The implementation and
templates remain in the repository for future work, but the Dock hides the
target and the exporter rejects direct TikTok export requests. Its previous
`ttmg` and real-device gates are therefore not release blockers for v0.3.0.

---

## Git Status

| Item | Status |
|------|--------|
| Working tree | 🔴 Dirty (20 modified files, awaiting commit) |
| Current HEAD | `1eed628` |
| origin/main | 4 commits behind HEAD |
| fork/main | ✅ Synced with HEAD |
| upstream/main | 31 commits ahead of HEAD (unrelated history) |

**Note**: After committing the pending changes, HEAD will be 5 commits ahead of origin/main (AnranS/godot_for_minigame) because this is a fork. The fork (`randomix777/godot_for_minigame`) is synced with HEAD.

---

## Manual Gates Still Required

No manual device gate remains for the enabled v0.3.0 targets. Experimental
targets remain automated-smoke-only and are not certified until their own
DevTools and device evidence is recorded.

---

## Environment Requirements

| Platform | Tool | Version | Status |
|----------|------|---------|--------|
| WeChat | 微信开发者工具 | v2.01.2510290 | ✅ Verified |
| WeChat | WeChat client | 8.0+ | ✅ Verified |
| Douyin | 抖音开发者工具 | v4.5.5 | ✅ Verified |
| Douyin | Douyin client | Latest | ✅ Verified |
| TikTok | ttmg | N/A | ⛔ Disabled for v0.3.0 |
| TikTok | TikTok client | N/A | ⛔ Disabled for v0.3.0 |
| Alipay | 支付宝开发者工具 | Latest | 🔴 Not verified |
| Baidu | 百度开发者工具 | Latest | 🔴 Not verified |
| QQ | QQ开发者工具 | Latest | 🔴 Not verified |
| Kuaishou | 快手开发者工具 | Latest | 🔴 Not verified |

---

## Release Checklist

- [x] All Node.js automated tests pass (13/13)
- [x] All Godot automated tests pass (13/13 on 4.6.1)
- [x] Export smoke test passes (6 enabled platforms)
- [x] Plugin packages correctly (deterministic ZIP)
- [x] Version metadata consistent (0.3.0 everywhere)
- [x] Website build/test/lint pass on Windows
- [ ] **Git working tree clean** — PENDING (after commit)
- [x] **WeChat DevTools compilation** — ✅ PASSED 2026-08-29
- [x] **WeChat real device test** — ✅ PASSED 2026-08-29
- [x] **Douyin DevTools compilation** — ✅ PASSED 2026-08-29
- [x] **Douyin real device test** — ✅ PASSED 2026-08-29
- [x] **TikTok export disabled for v0.3.0**

---

## What NOT to Do

- Do NOT claim manual gates are "passed" without evidence
- Do NOT create or push a git tag until all blockers are cleared
- Do NOT mark Godot 4.7.1 as certified (template asset not available)
- Do NOT mark experimental platforms (alipay/baidu/qq/kuaishou) as certified without DevTools verification
- Do NOT re-enable TikTok without pinned DevTool compilation and real-device evidence
