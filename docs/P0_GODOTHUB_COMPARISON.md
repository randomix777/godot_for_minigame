# P0 Comparison: AnranS vs godothub Design

## Overview

| Aspect | AnranS/godot_for_minigame | godothub/godot-minigame |
|--------|--------------------------|------------------------|
| **Language** | GDScript (pure, no compilation) | C++ GDExtension (requires compilation per platform) |
| **Godot version** | 4.6.1.stable (certified) | 4.3.0 – 4.7.0 (multi-version) |
| **Template format** | ZIP with `template.json` + SHA-256 | `.tpz` (Godot Template Package) |
| **Distribution** | Bundled + versioned store | Remote GitHub Release |
| **Version matching** | Strict exact match | Fuzzy (exact → same major → latest) |
| **SDK** | 224 methods, 83 signals (GDScript + JS bridge) | In-template (SDK bundled in `.tpz`) |
| **Platform support** | WeChat, Douyin, TikTok (first-class) | WeChat, Douyin (platform details in template) |
| **Build system** | SCons (WASM template build script) | SCons + C++ (per-platform editor plugin) |
| **CI** | GitHub Actions (export smoke, template build) | Not publicly documented |

## Template Distribution

### AnranS Approach
```
Bundled: addons/godot_mini_game/engine/{godot.js, godot.wasm.br, template.json}
Store:   {config}/godot_mini_game/templates/v1/{version}/{commit}/emsdk-{ver}/{profile}/{target}/abi-{N}/r{N}/
```
- Templates can be bundled in the plugin or imported from ZIP
- Versioned store supports multiple Godot versions simultaneously
- Each template has exact identity: version + commit + emscripten + profile + target + ABI + revision
- SHA-256 verified at import and export time

### godothub Approach
```
Release tag: 4.7/
Assets: versions.yaml + minigame4.7.0.5.tpz
```
- `versions.yaml` maps Godot version → template file
- Plugin fetches from GitHub/Gitee Releases
- First download, then local cache
- `.tpz` files contain the template (exact contents not publicly documented)

### Key Differences
1. **Exactness**: AnranS requires exact commit match; godothub allows same-major-version fallback
2. **Offline**: AnranS works offline with bundled template; godothub requires initial download
3. **Verification**: AnranS has SHA-256 + structural validation; godothub's verification is internal to the C++ plugin
4. **Multi-version**: Both support multiple Godot versions, but through different mechanisms

## Version Index Design

### AnranS
- No separate index file; version is encoded in directory structure
- `template.json` is the single source of truth per template
- `support-matrix.json` declares certified versions for CI/release

### godothub
- `versions.yaml` in each Release tag lists all supported Godot versions
- Format: `godot4: {version}: {tag: ..., file: ...}`
- Simple, human-readable, but no hash verification visible

## Cache Strategy

### AnranS
- Bundled template: always available (inside addon ZIP)
- Imported templates: stored in `{config}/godot_mini_game/templates/v1/`
- No remote download mechanism built into the plugin
- Template import is manual (UI button or CLI)

### godothub
- Templates downloaded from GitHub/Gitee Releases on first use
- Cached locally after download
- Automatic version matching selects the right template

## Export Transaction

### AnranS
- 7-stage export with staging directory
- Ownership manifest (`.godot-mini-game-export.json`) with full hash tree
- Transactional publish with lock, backup, and rollback
- Output guard prevents overwriting unmanaged files

### godothub
- Export details not publicly documented (C++ implementation)
- Likely uses Godot's built-in export mechanism with template substitution

## SDK Integration

### AnranS
- `MiniGameSDK.gd` as autoload singleton (224 methods, 83 signals)
- JS bridge (`sdk.js`) connects platform APIs to GDScript
- Bridge ABI versioning with validation handshake
- Capability detection per platform
- Safe fallback outside mini-game runtime

### godothub
- SDK details not publicly documented
- Likely bundled inside `.tpz` template files

## What We Can Learn from godothub

1. **Multi-version support**: Their `versions.yaml` approach is simpler but less verifiable
2. **Remote distribution**: Useful for keeping the plugin small; AnranS bundles the template
3. **Fuzzy matching**: More forgiving for users but less deterministic
4. **C++ plugin**: Better performance but harder to maintain and modify

## What AnranS Does Better

1. **Exact identity enforcement**: Prevents silent version mismatches
2. **SHA-256 verification**: Full supply chain integrity
3. **Transactional export**: Crash-safe publish with rollback
4. **SDK completeness**: 224 methods vs unknown
5. **Platform contracts**: Explicit per-platform behavior documented
6. **Build reproducibility**: Full build scripts for WASM template
7. **GDScript**: Easier to modify, debug, and extend

## Risks of godothub Approach for Our Fork

1. **Fuzzy matching can cause silent failures**: Using wrong template version
2. **No SHA-256 verification visible**: Supply chain integrity unclear
3. **C++ dependency**: Harder for community contributors
4. **Remote-only distribution**: Requires internet for first setup
