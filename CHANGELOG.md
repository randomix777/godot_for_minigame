# Changelog

All notable changes to Godot Mini Game will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- None

## [0.3.1] - 2026-08-30

### Fixed
- **GDScript test failure**: Added missing platform contracts (alipay, baidu, qq, kuaishou) to `output_guard.gd` PLATFORM_CONTRACTS dictionary, fixing "Unknown platform contract" errors in CI GDScript tests
- **Windows Godot installation**: Fixed unreliable `/tmp` path usage on Windows; now uses `$RUNNER_TEMP` and finds executable via `find` to handle ZIP file naming variations
- **Smoke test export**: Extended platform contract verification to handle alipay, baidu, qq, and kuaishou experimental platforms with appropriate assertions
- **Release workflow**: Updated release body to reflect all supported platforms including TikTok disabled notice
- **GitHub Pages**: Documented required repository settings configuration (Pages must be enabled in Settings → Pages)

## [0.3.0] - 2026-08-29

### Added
- TikTok Mini Game platform support (beta)
- Alipay Mini Game platform support (experimental)
- Baidu Mini Game platform support (experimental)
- QQ Mini Game platform support (experimental)
- Kuaishou Mini Game platform support (experimental)
- `.gitattributes` to prevent CRLF line endings in engine binaries
- P0 and P1 audit documentation
- P2 export transaction pipeline (7-stage)
- P3 independent platform probe with test matrix
- P4 unified SDK with 322 methods, 83 signals
- P5 template version management for Godot 4.6.1 + 4.7.1
- P6 package size and performance baseline
- P7 productization design (Community/Pro/Enterprise)
- P8 release candidate verification
- Windows CI workflow (`ci-windows.yml`)
- Version manager for template download/cache/verify
- Cross-platform deterministic packaging script (`package_plugin.mjs`)

### Fixed
- `godot.js` CRLF line ending issue causing "缺少 WebAssembly wrapper 补丁锚点" error
- Template SHA-256 verification now passes after line ending normalization
- Windows test compatibility (cross-platform env vars, packaging)
- All template JS files converted from ES module to CommonJS (WeChat/Douyin/TikTok/Alipay/Baidu/QQ/Kuaishou DevTools compatibility)

### Changed
- Plugin version bumped to 0.3.1
- Support matrix expanded with Godot 4.7.1 planned entry (template asset not yet available)
- Platform detection now supports 7 platforms: WeChat, Douyin, TikTok, Alipay, Baidu, QQ, Kuaishou
- Export smoke tests now cover all 7 platforms
- Description updated to include all supported platforms

## [0.2.1]

### Fixed
- Minor bug fixes

## [0.2.0]

### Added
- Transactional export with ownership manifests
- Versioned template store with exact identity matching
- Export output guard with path safety checks
- MiniGameSDK with 224 methods and 83 signals

### Changed
- Improved template bundle validation

## [0.1.1]

### Fixed
- Bug fixes

## [0.1.0]

### Added
- Initial release
- WeChat and Douyin mini-game export
- GDScript SDK for platform APIs
- Editor dock UI

[Unreleased]: https://github.com/AnranS/godot_for_minigame/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/AnranS/godot_for_minigame/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/AnranS/godot_for_minigame/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/AnranS/godot_for_minigame/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/AnranS/godot_for_minigame/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/AnranS/godot_for_minigame/releases/tag/v0.1.0
