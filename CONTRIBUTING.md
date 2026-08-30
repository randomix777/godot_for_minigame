# Contributing to Godot Mini Game

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Getting Started

1. Fork the repository
2. Clone your fork
3. Create a feature branch from `main`
4. Make your changes
5. Submit a pull request

## Development Setup

### Prerequisites
- Godot 4.6.1.stable (for testing)
- Node.js (for JavaScript tests)
- Git

### Project Structure
```
addons/godot_mini_game/
├── plugin.cfg              # Plugin metadata
├── plugin.gd               # EditorPlugin entry
├── export_dock.gd          # UI dock
├── exporter.gd             # Core export logic
├── MiniGameSDK.gd          # Runtime SDK
├── core/
│   ├── template_bundle.gd  # Template validation
│   └── output_guard.gd     # Output path safety
├── engine/                 # Bundled WASM template
└── templates/              # Platform templates
```

### Running Tests
```bash
# JavaScript tests
for test_file in test/*.test.mjs; do node "$test_file"; done

# GDScript tests
for test_file in test/*_test.gd; do
    godot --headless --path . --script "res://$test_file"
done
```

## Branch Strategy

- `main` — Stable release branch
- `develop` — Integration branch for next release
- `upstream-sync` — Automated upstream merge branch
- `feature/*` — Feature development branches
- `release/*` — Release preparation branches

## Code Guidelines

### GDScript
- Use `@tool` for editor scripts
- Type all variables and function parameters
- Use signals for async communication
- Handle errors explicitly (no silent failures)

### JavaScript
- Use strict mode
- Handle platform detection gracefully
- No remote script loading
- Compatible with WeChat/Douyin/TikTok runtimes

### Testing
- Every export feature must have a test
- Tests must pass on both WeChat and Douyin
- No real AppIDs or credentials in tests

## Pull Request Process

1. Update documentation if needed
2. Add tests for new features
3. Ensure all tests pass
4. Request review from maintainers
5. Squash and merge after approval

## Reporting Issues

- Use GitHub Issues for bug reports
- Include Godot version, OS, and reproduction steps
- For security issues, see SECURITY.md

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
