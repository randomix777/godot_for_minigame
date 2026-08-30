# P0 License Audit

## Summary

| Item | Status | Detail |
|------|--------|--------|
| Plugin license | MIT | `LICENSE` copyright 2025 godot_tt contributors |
| Fork permission | ✅ Explicit | MIT permits fork, modify, distribute, sublicense, and sell |
| Commercial use | ✅ Allowed | MIT permits commercial use and closed-source extensions |
| Attribution requirement | ✅ Standard | Only the copyright notice must be preserved in copies |
| Bundled Godot engine | Separate | Godot Engine MIT license; see `GODOT_COPYRIGHT.txt` |
| Third-party notices | ✅ Present | `THIRD_PARTY_NOTICES.md` + `GODOT_COPYRIGHT.txt` bundled in engine dir |

## Detailed Analysis

### 1. Plugin License (MIT)

The `LICENSE` file is a standard MIT license with:
- **Copyright**: "2025 godot_tt contributors"
- **Permissions**: Use, copy, modify, merge, publish, distribute, sublicense, sell
- **Conditions**: Retain copyright notice and license text in copies
- **Warranty**: Provided "AS IS", no warranty

**Implications for fork/commercialization:**
- Forking AnranS/godot_for_minigame: **fully permitted**
- Creating a closed-source derivative: **permitted** (only need to include MIT notice)
- Selling a commercial version: **permitted**
- Adding proprietary features (Pro/Enterprise): **permitted**
- No copyleft or viral requirements

### 2. Bundled Godot Engine

The precompiled WASM engine (`engine/godot.js`, `engine/godot.wasm.br`) is built from Godot Engine source (MIT licensed). The plugin includes:
- `GODOT_COPYRIGHT.txt` — full Godot copyright text from the exact source version
- `THIRD_PARTY_NOTICES.md` — explains provenance and license obligation

**Key boundary**: The Godot Engine license only requires preserving the copyright notice. There is no obligation to share modifications to the *engine binary* (though the Godot *source* itself is MIT and thus open).

### 3. Emscripten Toolchain

Emscripten is Apache 2.0 licensed. The build script (`build_wasm_template.sh`) compiles from source and packages the output. No Emscripten runtime code is distributed — only the compiled output.

### 4. SDK JavaScript Bridge

`templates/common/js/libs/sdk.js` is authored by the plugin contributors. No external SDK code is bundled. The JS bridge uses `JavaScriptBridge.create_callback()` from Godot's own Web platform.

### 5. Commercial Boundary Recommendations

For the proposed Community/Pro/Enterprise tier design (P7):

| Tier | License Compatibility | Requirement |
|------|----------------------|-------------|
| Community (free) | MIT | Include LICENSE + GODOT_COPYRIGHT.txt |
| Pro (paid) | MIT allows closed-source | Include LICENSE + GODOT_COPYRIGHT.txt in binary distribution |
| Enterprise (custom) | MIT allows closed-source | Include LICENSE + GODOT_COPYRIGHT.txt in binary distribution |

**No additional licensing restrictions are imposed by MIT.** The differentiation must come from value-add (features, support, certification), not from license restrictions.

### 6. Risks

1. **No `NOTICE` file**: Some jurisdictions interpret Apache 2.0 "NOTICE file" requirements for Emscripten. Since Emscripten is only a build tool (not distributed), this is low risk but could be addressed by adding a build-tool notice.
2. **godothub/godot-minigame reference**: The read-only reference repo's license should be verified before any code is copied. (P0 task 6 — marked read-only, no copying.)
3. **Third-party asset references**: `templates/common/audio/demo-tone.wav` and `templates/common/images/logo.png` — license status should be confirmed (likely custom/CC0, but not documented).
