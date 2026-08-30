# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.3.x | ✅ Active development |
| 0.2.x | ⚠️ Security fixes only |
| < 0.2 | ❌ No support |

## Reporting a Vulnerability

If you discover a security vulnerability in Godot Mini Game, please report it responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

Instead, please email: [maintainer email]

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

## Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial assessment**: Within 1 week
- **Fix or mitigation**: Within 2 weeks for critical issues

## Security Considerations

### What This Plugin Does
- Exports Godot projects to WeChat, Douyin, and TikTok Mini Game formats
- Provides a GDScript SDK for platform API access
- Manages engine template bundles with SHA-256 verification

### What This Plugin Does NOT Do
- Collect or transmit user data
- Handle payments or financial transactions
- Manage authentication credentials (AppIDs are user-provided)
- Execute remote code

### Template Integrity
- All engine templates are SHA-256 verified at import and export time
- Template identity includes exact Godot version, commit, Emscripten version, and build profile
- No fuzzy matching — exact identity required

### Export Security
- Output directories are validated for path safety
- Ownership manifests prevent overwriting unmanaged files
- Transactional publish with rollback on failure
- No private keys, secrets, or credentials are bundled

### Known Limitations
- The plugin runs in the Godot editor context with full file system access
- Exported mini-game packages run in the platform's JavaScript sandbox
- User-provided AppIDs and Client Keys are stored in project configuration
