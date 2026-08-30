# v0.3.0 Release Gates

> ⚠️ **IMPORTANT**: v0.3.0 was tagged and pushed but remote CI failed. See [Remote CI Failures](#remote-ci-failures-v030) for details. This release should NOT be considered a passing-gate stable release. v0.3.1 fixes these issues.

## Automated Verification (Local)

| Test Suite | Result | Details |
|-----------|--------|---------|
| Node.js tests (13) | ✅ PASS | 13/13 on Node.js v24.18.0 (incl. sha256sums_test.mjs) |
| Godot 4.6.1 headless import | ⚠️ N/A | Exit code 1 with no error output (expected for headless import) |
| Godot 4.6.1 smoke tests (13) | ✅ PASS | 13/13 — all test/*_test.gd |
| Export smoke (6 enabled platforms) | ✅ PASS | wechat, douyin, alipay, baidu, qq, kuaishou |
| Package reproducibility | ✅ PASS | Identical SHA-256 across runs |
| Plugin packaging | ✅ PASS | Deterministic ZIP via scripts/package_plugin.sh |
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

## Remote CI Failures (v0.3.0)

The following remote CI failures occurred on the fork repository (`randomix777/godot_for_minigame`):

### 1. Release Plugin / Smoke Test Export — GDScript Test Failure

**Symptom**: `exporter_output_transaction_test.gd` fails on Linux CI for alipay, baidu, qq, kuaishou platforms.

**Root Cause**: `output_guard.gd` `PLATFORM_CONTRACTS` dictionary only contained `wechat`, `douyin`, `tiktok`. The test iterates over all `SUPPORTED_PLATFORMS` (7 platforms) and expects `OutputGuard.inspect()` to succeed for each, but platforms not in `PLATFORM_CONTRACTS` are rejected as "Unknown platform contract".

**Fix**: Added `alipay`, `baidu`, `qq`, `kuaishou` entries to `PLATFORM_CONTRACTS` in `output_guard.gd`. Also added `alipay|baidu|qq|kuaishou` case to the platform contract verification step in `smoke-test-export.yml`.

### 2. Windows CI — Godot Installation Failure

**Symptom**: `mv: cannot move '/tmp/godot/Godot_v4.6.1-stable_win64.exe' to '/usr/local/bin/godot.exe': No such file or directory`

**Root Cause**: On Windows Git Bash, `/tmp` does not resolve to a reliable location. The `unzip` extracts to `/tmp/godot/` but `mv` cannot find the file there. Also, the ZIP contains two files (`Godot_v4.6.1-stable_win64.exe` and `Godot_v4.6.1-stable_win64_console.exe`) and the script assumed a single file name.

**Fix**: Use `$RUNNER_TEMP` instead of `/tmp` for reliable Windows temp paths. Use `find` to locate the correct exe (excluding console variant) instead of hardcoding the filename.

### 3. GitHub Pages — Deployment Failure

**Symptom**: `Error: Failed to create deployment (status: 404)` with message `Ensure GitHub Pages has been enabled: https://github.com/randomix777/godot_for_minigame/settings/pages`

**Root Cause**: GitHub Pages is not enabled in the fork repository settings. The workflow correctly requests `pages: write` and `id-token: write` permissions, but the repository-level Pages setting must be enabled in the GitHub UI.

**Fix Required (Manual)**: Repository owner must enable GitHub Pages in repository Settings → Pages → Source: GitHub Actions.

### 4. Release Asset — Missing Checksum

**Symptom**: v0.3.0 Release only had `godot_mini_game_v0.3.0.zip`, missing `.sha256` file.

**Root Cause**: The `package` job was skipped because `smoke` tests failed (GDScript test failure). The release was created manually or by a different process that didn't run the packaging step.

**Fix**: The release workflow now correctly gates packaging behind smoke test success. The `package` job generates and uploads both `.zip` and `.zip.sha256` files.

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
| Working tree | ✅ Clean |
| Current HEAD | `ae36e77` (v0.3.0 tag) |
| origin/main (AnranS/godot_for_minigame) | 6 commits behind HEAD |
| fork/main (randomix777/godot_for_minigame) | Same as HEAD |
| upstream/main (godothub/godot-minigame) | Unrelated history |

**Note**: The 6 commits ahead of origin/main represent the v0.3.0 release preparation work.

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
- [x] Website build/test/lint pass
- [x] **Git working tree clean** — ✅ Completed (ae36e77)
- [x] **WeChat DevTools compilation** — ✅ PASSED 2026-08-29
- [x] **WeChat real device test** — ✅ PASSED 2026-08-29
- [x] **Douyin DevTools compilation** — ✅ PASSED 2026-08-29
- [x] **Douyin real device test** — ✅ PASSED 2026-08-29
- [x] **TikTok export disabled for v0.3.0**
- [ ] **Remote CI green** — ❌ FAILED (GDScript tests, Windows install, GitHub Pages)
- [x] **v0.3.0 tag created** — ✅ Created (ae36e77)
- [ ] **GitHub Release published** — ❌ INCOMPLETE (missing .sha256 asset)

---

## What NOT to Do

- Do NOT claim manual gates are "passed" without evidence
- Do NOT create or push a git tag until all blockers are cleared
- Do NOT mark Godot 4.7.1 as certified (template asset not available)
- Do NOT mark experimental platforms (alipay/baidu/qq/kuaishou) as certified without DevTools verification
- Do NOT re-enable TikTok without pinned DevTool compilation and real-device evidence
- Do NOT modify or delete the v0.3.0 tag
- Do NOT overwrite the existing v0.3.0 GitHub Release assets

---

## Required Manual Actions (GitHub UI)

1. **Enable GitHub Pages** on the fork repository:
   - Go to `https://github.com/randomix777/godot_for_minigame/settings/pages`
   - Set Source to "GitHub Actions"
   - This is required for the Deploy Website workflow to succeed

2. **Repository Actions Permissions** (if not already set):
   - Go to `https://github.com/randomix777/godot_for_minigame/settings/actions`
   - Ensure "Read and write permissions" is selected under "Workflow permissions"
   - Ensure "Allow GitHub Actions to create and approve pull requests" is checked
