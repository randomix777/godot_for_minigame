# P3 Probe Test Matrix

## Overview

The `probe/` directory contains a universal platform capability probe that tests
WeChat, Douyin, TikTok, and desktop environments. All probes return **PASS**,
**FAIL**, or **UNSUPPORTED**.

## Architecture

```
probe/
├── project.godot                    # Probe project (links to main addon)
├── scenes/
│   ├── probe_main.tscn              # Visual probe scene
│   └── probe_main.gd                # Scene logic
├── scripts/
│   ├── probe_runner.gd              # Headless CI runner (JSON output)
│   ├── providers/
│   │   ├── platform_provider.gd     # Base class (Status enum, result format)
│   │   ├── mock_provider.gd         # Desktop mock (no-op/UNSUPPORTED)
│   │   ├── wechat_provider.gd       # WeChat real provider
│   │   └── douyin_provider.gd       # Douyin real provider
│   └── probes/                      # (reserved for future per-category probes)
└── assets/                          # (reserved for probe-specific assets)
```

## Platform Sharing Model

| Component | WeChat | Douyin | TikTok | Desktop |
|-----------|--------|--------|--------|---------|
| Godot scenes | Shared | Shared | Shared | Shared |
| Probe logic | Shared | Shared | Shared | Shared |
| Provider | `WeChatProvider` | `DouyinProvider` | `DouyinProvider` (same API) | `MockProvider` |
| API namespace | `wx` | `tt` | `TTMinis.game` | N/A |

**Key principle**: wx/tt share the same Godot scenes. Platform differences are
isolated in provider classes. Desktop uses a mock/no-op provider.

## Test Categories

### 1. Display (Orientation)
| Test | WeChat | Douyin | TikTok | Desktop |
|------|--------|--------|--------|---------|
| Portrait mode | PASS | PASS | PASS | UNSUPPORTED |
| Landscape mode | PASS | PASS | PASS | UNSUPPORTED |
| DPR scaling | PASS | PASS | PASS | UNSUPPORTED |

### 2. Input (Touch)
| Test | WeChat | Douyin | TikTok | Desktop |
|------|--------|--------|--------|---------|
| Single tap | PASS | PASS | PASS | UNSUPPORTED |
| Drag/swipe | PASS | PASS | PASS | UNSUPPORTED |
| Multi-touch | PASS | PASS | PASS | UNSUPPORTED |

### 3. Rendering (WebGL)
| Test | WeChat | Douyin | TikTok | Desktop |
|------|--------|--------|--------|---------|
| WebGL context | PASS | PASS | PASS | PASS |
| Canvas fallback | PASS | PASS | PASS | PASS |

### 4. Audio
| Test | WeChat | Douyin | TikTok | Desktop |
|------|--------|--------|--------|---------|
| Audio playback | PASS | PASS | PASS | PASS |
| Audio resume | PASS | PASS | PASS | PASS |

### 5. Storage
| Test | WeChat | Douyin | TikTok | Desktop |
|------|--------|--------|--------|---------|
| Local storage | PASS | PASS | PASS | PASS |
| Storage quota | PASS | PASS | PASS | PASS |

### 6. Network
| Test | WeChat | Douyin | TikTok | Desktop |
|------|--------|--------|--------|---------|
| HTTP request | PASS | PASS | PASS | PASS |
| HTTPS request | PASS | PASS | PASS | PASS |

### 7. Lifecycle
| Test | WeChat | Douyin | TikTok | Desktop |
|------|--------|--------|--------|---------|
| Foreground/background | PASS | PASS | PASS | UNSUPPORTED |
| onShow/onHide | PASS | PASS | PASS | UNSUPPORTED |

### 8. Vibration
| Test | WeChat | Douyin | TikTok | Desktop |
|------|--------|--------|--------|---------|
| Short vibration | PASS | PASS | PASS | UNSUPPORTED |
| Long vibration | PASS | PASS | PASS | UNSUPPORTED |

### 9. Safe Area
| Test | WeChat | Douyin | TikTok | Desktop |
|------|--------|--------|--------|---------|
| Safe area inset | PASS | PASS | PASS | UNSUPPORTED |

### 10. Memory
| Test | WeChat | Douyin | TikTok | Desktop |
|------|--------|--------|--------|---------|
| Memory warning | PASS | PASS | PASS | UNSUPPORTED |

### 11. Capability Detection
| Test | WeChat | Douyin | TikTok | Desktop |
|------|--------|--------|--------|---------|
| PlatformRuntime query | PASS | PASS | PASS | PASS |

### 12. Structured Logging
| Test | WeChat | Douyin | TikTok | Desktop |
|------|--------|--------|--------|---------|
| Console logging | PASS | PASS | PASS | PASS |

### 13. Font Rendering
| Test | WeChat | Douyin | TikTok | Desktop |
|------|--------|--------|--------|---------|
| Chinese characters | PASS | PASS | PASS | PASS |

### 14. Image Loading
| Test | WeChat | Douyin | TikTok | Desktop |
|------|--------|--------|--------|---------|
| PNG loading | PASS | PASS | PASS | PASS |

### Structural Probes
| Test | Status |
|------|--------|
| Addon file structure | PASS |
| Template identity | PASS |
| SDK completeness | PASS |

## Running the Probe

### Headless (CI)
```bash
godot --headless --path probe/ --script res://scripts/probe_runner.gd
```
Output: `probe_report.json` + stdout summary

### Visual (Editor)
```bash
godot --path probe/
```
Opens the probe scene with real-time results.

### Export to Platform
1. Enable the `Godot Mini Game Export` plugin in `probe/project.godot`
2. Export to WeChat/Douyin using the normal export flow
3. Run in the platform's developer tools
4. Check console for `[probe]` output

## Blocking Probes

The following probes are **blocking** — a FAIL means the platform cannot run
Godot mini-games:

| Category | Test | Reason |
|----------|------|--------|
| Display | orientation | Mini-games must set orientation |
| Input | touch | Touch is the primary input method |
| Render | webgl | Rendering requires WebGL |
| Audio | playback | Audio is expected to work |
| Storage | local | Save/load requires storage |
| Lifecycle | foreground | Background handling is required |

## Device Report Template

See `docs/P3_DEVICE_REPORT_TEMPLATE.md` for the template used when reporting
real device test results.
