# P0 Version Consistency Audit

## Current State

| Source | Version | Status |
|--------|---------|--------|
| `plugin.cfg` | `0.3.0` | ✅ Matches README |
| `support-matrix.json` → `pluginVersion` | `0.3.0` | ✅ Matches plugin.cfg |
| `README.md` badge | `v0.3.0` | ✅ Matches |
| Git tags | `v0.1.0`, `v0.1.1`, `v0.2.0`, `v0.2.1` | ⚠️ **No v0.3.0 tag** |
| GitHub Releases | Last tagged: `v0.2.1` | ⚠️ **v0.3.0 not released** |
| Main branch HEAD | `2b6cb70` (9 commits ahead of v0.2.1) | ⚠️ Unreleased |

## Findings

### 1. v0.3.0 is NOT yet tagged or released

The `plugin.cfg` and `support-matrix.json` declare version `0.3.0`, but:
- No git tag `v0.3.0` exists
- No GitHub Release `v0.3.0` exists
- The main branch is 9 commits ahead of `v0.2.1`

**Commits since v0.2.1:**
```
2b6cb70 fix: sharpen TikTok rendering and update site
253ece4 fix: make TikTok smoke check Linux-safe
6990a30 feat: add TikTok Mini Game support
6b6f965 docs: redraw responsive architecture diagrams
879e794 fix: refresh corrected dark banner asset
ac0ee0d fix: remove dark banner corner artifacts
bf915f9 docs: replace platform marks with imagegen artwork
1361e83 docs: redesign README visuals and architecture
c807e76 docs: redesign GitHub project homepage
```

The most significant change is `feat: add TikTok Mini Game support` which adds a third first-class platform.

### 2. Bundle template identity is consistent

| Field | Value | Consistent |
|-------|-------|-----------|
| `template.json` → `godot.version` | `4.6.1.stable` | ✅ |
| `template.json` → `godot.commit` | `14d19694e0c88a3f9e82d899a0400f27a24c176e` | ✅ |
| `template.json` → `emscriptenVersion` | `4.0.3` | ✅ |
| `template.json` → `bridgeAbi` | `1` | ✅ |
| `template.json` → `revision` | `1` | ✅ |
| `support-matrix.json` → `certified[0]` | Same values | ✅ |
| `version.txt` | `4.6.1.stable` | ✅ |

### 3. CI workflow version validation

The `release-plugin.yml` workflow validates:
```bash
tag_version != version → exit 1
version != matrix_version → exit 1
```

This means a v0.3.0 release would fail if `plugin.cfg`, `support-matrix.json`, and the git tag don't all agree. The current state (v0.3.0 in config, no tag) is a pre-release state.

### 4. Template build revision

The bundled template is revision 1 (`"revision": 1` in template.json). The `build-template.yml` workflow defaults to revision 2. This means:
- The bundled r1 template was built separately (not via the CI workflow)
- Future template builds via CI would produce r2+

## Recommendations

1. **Before P1**: Create the `v0.3.0` tag after confirming all tests pass
2. **Document the release process**: The `scripts/release_plugin.sh` script handles tagging
3. **Consider template revision**: If the bundled r1 template needs updating, bump revision in both `template.json` and `support-matrix.json`
