# P0 Supply Chain Audit

## Summary

| Source | Type | Version | Integrity | Reproducible |
|--------|------|---------|-----------|--------------|
| Godot Engine (bundled WASM) | Precompiled binary | 4.6.1.stable / commit `14d19694e0c8` | SHA-256 in template.json | ✅ Yes — build script |
| Emscripten SDK | Build toolchain | 4.0.3 | Version pinned | ✅ Yes — emsdk install |
| GDScript plugin source | Source code | v0.3.0 | Git tag | N/A (source) |
| JS bridge (sdk.js) | Source code | In-tree | Git tracked | N/A (source) |
| platform_runtime.js | Source code | In-tree | Git tracked | N/A (source) |
| Templates (game.js, game.json) | Source code | In-tree | Git tracked | N/A (source) |
| Static assets (demo-tone.wav, logo.png) | Binary assets | In-tree | Git tracked | N/A (source) |
| Placeholder images | Generated | Runtime | PNG from code | ✅ Deterministic |

## Certified Template Identity

From `addons/godot_mini_game/engine/template.json`:

```json
{
  "schema": 1,
  "godot": {
    "version": "4.6.1.stable",
    "commit": "14d19694e0c88a3f9e82d899a0400f27a24c176e"
  },
  "emscriptenVersion": "4.0.3",
  "profile": "2d_full",
  "target": "release",
  "revision": 1,
  "bridgeAbi": 1,
  "features": {
    "simd": false,
    "threads": false,
    "wasmExceptions": false
  },
  "artifacts": {
    "godot.js": {
      "sha256": "fd8265eed945d669189eb6960f9ebca40863a7d00e87c5d9bdd5868e55b1203b"
    },
    "godot.wasm.br": {
      "sha256": "f81067a1d30125b161c26097bf4976c20064a1543d2c56b1c7cdcce10ae764cd"
    }
  }
}
```

## Template Resolution Priority

```
1. addon/          — project-local override (priority 2000000000)
2. store/          — imported versioned bundles (priority 1000000+revision)
3. bundled/        — engine/ directory inside the addon (priority 500000)
4. store_legacy/   — old flat template dirs (priority 400000, read-only)
```

## Versioned Store Directory Schema

```
{Godot config dir}/godot_mini_game/templates/v1/
└── {godot_version}/           # e.g. 4.6.1.stable
    └── {40-char commit}/      # exact Godot source commit
        └── emsdk-{version}/   # e.g. emsdk-4.0.3
            └── {profile}/     # e.g. 2d_full
                └── {target}/  # e.g. release
                    └── abi-{N}/
                        └── r{N}/
                            ├── template.json
                            ├── version.txt
                            ├── godot.js
                            ├── godot.wasm.br
                            └── GODOT_COPYRIGHT.txt
```

**Key design decisions:**
- Directory-encoded identity prevents silent version confusion
- `template.json` + `version.txt` must agree
- SHA-256 verified at import time and at export time
- No fuzzy matching: `4.6` ≠ `4.6.1` ≠ `4.6.1.stable`

## Build Provenance Chain

### Bundled Template (r1)
```
Godot 4.6.1-stable source (commit 14d19694e0c8)
  → scons platform=web target=template_release arch=wasm32
  → Emscripten 4.0.3
  → godot.js + godot.wasm
  → brotli --quality=11 → godot.wasm.br
  → template.json (SHA-256 for both artifacts)
  → Bundled into addons/godot_mini_game/engine/
```

### Template Build Script
`scripts/build_wasm_template.sh`:
1. Validates exact Godot tag, Emscripten version, revision
2. Clones Godot source at exact tag
3. Verifies source identity (tag + clean working tree)
4. Applies longjmp patch if needed (detect.py: `SUPPORT_LONGJMP='wasm'` → `'emscripten'`)
5. Builds with scons: `wasm_simd=no, threads=no, dlink_enabled=no, javascript_eval=no`
6. Brotli-compresses WASM
7. Generates template.json with SHA-256 hashes
8. Normalizes timestamps and file permissions for reproducibility
9. Creates ZIP with fixed member order
10. Validates with `verify_wasm_template.sh`

### Release Process
1. `scripts/release_plugin.sh <version>`:
   - Validates plugin.cfg version == support-matrix.json version
   - Runs `package_plugin.sh`
   - Creates git tag `v{version}`
   - Pushes tag → triggers GitHub Actions
2. GitHub Actions (`release-plugin.yml`):
   - Runs smoke-test-export (unit tests + export tests)
   - Packages plugin ZIP with SHA-256
   - Creates GitHub Release with ZIP + checksum

### Template Release Process
1. `build-template.yml` (manual dispatch):
   - Inputs: Godot tag, Emscripten version, revision
   - Builds template from Godot source
   - Validates with `verify_wasm_template.sh`
   - Creates template release tag: `template-{godot}-emsdk-{emsdk}-2d-full-release-abi-{abi}-r{rev}`
   - Publishes ZIP + SHA-256 as GitHub Release asset

## Generated File Sources

| Category | Files | Source |
|----------|-------|--------|
| **Static copy (no modification)** | adapter.js, fetch.js, sdk.js, loader.js, image_loader.js, platform_runtime.js, position_reporting.js, demo-tone.wav, logo.png, game.js (per-platform) | In-tree templates |
| **Patched copy** | godot.js (→ js/libs/godot.js) | Engine template + preamble/postamble |
| **Verified copy** | godot.wasm.br (→ engine/godot.wasm.br) | Engine template (SHA-256 verified) |
| **Runtime generated** | godot.zip (→ engine/godot.zip) | Godot headless --export-pack |
| **Template substituted** | game.json, project.config.json, project.private.config.json | .template files with variable replacement |
| **Code generated** | engine/game.js, subpacks/game.js, images/background.png, .godot-mini-game-export.json | Generated by exporter.gd |

## Non-Reproducible Assets

1. **engine/godot.zip (PCK)**: Generated by Godot headless `--export-pack`. Output depends on Godot version and project content. Not deterministic across Godot builds, but deterministic for same project + same Godot binary.
2. **Placeholder images** (background.png): Generated as solid-color PNG by code. Deterministic for same platform/orientation.
3. **game.json / project.config.json**: Template-substituted; deterministic for same inputs (platform, appid, orientation).

## Integrity Verification Points

| Stage | What | How |
|-------|------|-----|
| Template import | SHA-256 of godot.js + godot.wasm.br | `TemplateBundle.load_from_directory()` |
| Template import | template.json ↔ version.txt version | `import_template_zip()` |
| Template selection | Directory path ↔ manifest identity | `TemplateBundle.select()` — refuses mismatched paths |
| Export: engine copy | SHA-256 of copied files | `_obtain_engine_files()` — checks after copy |
| Export: output manifest | All artifact hashes | `_write_output_manifest()` + `_validate_output_manifest()` |
| Export: ownership guard | Full tree audit | `OutputGuard.inspect()` + `_validate_ownership_manifest()` |
| Release: ZIP | SHA-256 of archive | `package_plugin.sh` writes `.sha256` file |
| Release: template ZIP | SHA-256 + structural validation | `verify_wasm_template.sh` |
| CI: export smoke | Platform contract, eval check, package limits | `smoke-test-export.yml` |

## Risks

1. **Bundled WASM is opaque**: The precompiled `godot.wasm.br` cannot be visually inspected. Integrity relies entirely on SHA-256 verification against the build record.
2. **Godot source patch**: The `SUPPORT_LONGJMP` patch is documented and tracked, but any future Godot version may change this detection.
3. **Third-party assets**: `demo-tone.wav` and `logo.png` have no documented license. They appear to be custom assets, but should be confirmed.
4. **No npm/node dependency at runtime**: JS bridge code is self-contained. No package.json or node_modules in the exported output.
