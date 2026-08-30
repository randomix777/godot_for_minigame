# Version Support Policy

## Plugin Versioning

Godot Mini Game follows [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH[-PRERELEASE]
```

- **MAJOR**: Breaking changes to export output, SDK API, or template schema
- **MINOR**: New features, platforms, or SDK methods (backward compatible)
- **PATCH**: Bug fixes, documentation, CI improvements

### Current Version: 0.3.1

## Compatibility Contracts

### Bridge ABI Version

The Bridge ABI defines the contract between GDScript `MiniGameSDK` and JavaScript `sdk.js`.

| ABI Version | Status | Compatibility |
|-------------|--------|---------------|
| 1 | Current | GDScript ↔ JS handshake requires exact match |

**Policy**: ABI version increments on breaking changes to the bridge protocol. GDScript and JS sides must use the same ABI version.

### Template Schema Version

The template schema defines the `template.json` format.

| Schema Version | Status | Compatibility |
|----------------|--------|---------------|
| 1 | Current | Exact match required |

**Policy**: Schema version increments on structural changes to `template.json`. Older schemas are rejected.

### Output Manifest Schema Version

The output manifest defines `.godot-mini-game-export.json`.

| Schema Version | Status | Compatibility |
|----------------|--------|---------------|
| 1 | Current | Exact match required |

**Policy**: Schema version increments on structural changes to the export manifest.

### Godot Version Support

| Godot Version | Status | Template Source |
|---------------|--------|-----------------|
| 4.6.1.stable | ✅ Certified | Bundled |
| 4.7.1.stable | 🔜 Planned | Release download (not yet available) |
| 4.7.2.stable | 🔜 Planned | Release download (not yet available) |

**Policy**:
- Only exact Godot versions are supported (e.g., `4.6.1.stable`, not `4.6` or `4.6.1`)
- New Godot versions are added after certification testing
- Old versions receive security fixes only

### Emscripten Version Support

| Emscripten | Godot | Status |
|------------|-------|--------|
| 4.0.3 | 4.6.1.stable | ✅ Certified |

**Policy**: Emscripten version is pinned per Godot version. Changes require full rebuild and re-certification.

### Platform Support

| Platform | API Namespace | Status |
|----------|--------------|--------|
| WeChat | `wx` | ✅ Stable |
| Douyin | `tt` | ✅ Stable |
| TikTok | `TTMinis.game` | ⚠️ Beta |
| Alipay | `my` | 🔬 Experimental |
| Baidu | `swan` | 🔬 Experimental |
| QQ | `qq` | 🔬 Experimental |
| Kuaishou | `ks` | 🔬 Experimental |

**Policy**:
- Platform support follows the platform's own stability
- Beta platforms may change without notice
- Stable platforms require deprecation notice before breaking changes
- Experimental platforms require DevTools verification before promotion to beta

## Upgrade Guide

### From 0.2.x to 0.3.x

1. Replace the `addons/godot_mini_game/` directory
2. Re-export your project (output format may have changed)
3. Update any custom `MiniGameSDK` calls if SDK API changed
4. Test on target platforms

### Template Updates

When upgrading to a new Godot version:
1. The plugin will automatically download the new template (if configured)
2. Or import the new template ZIP manually
3. Re-export your project
4. Test on all target platforms

## Deprecation Policy

- **Breaking changes**: Announced 2 minor versions in advance
- **Deprecated features**: Marked with `@deprecated` in code and docs
- **Removed features**: Documented in CHANGELOG.md

## Long-Term Support

- Current major version receives full support
- Previous major version receives security fixes for 1 year
- Older versions are end-of-life
