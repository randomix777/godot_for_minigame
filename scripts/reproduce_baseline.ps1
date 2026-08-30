#Requires -Version 5.1
<#
.SYNOPSIS
    P1 Baseline Reproduction Script for Godot Mini Game Plugin v0.3.0 (Windows)
.DESCRIPTION
    Reproduces the certified baseline: exports a demo project to WeChat and Douyin
    mini-game formats using Godot 4.6.1.stable with the bundled engine template.

    Prerequisites:
    - Godot 4.6.1.stable installed and in PATH (or set GODOT_PATH below)
    - Node.js (for JavaScript tests)
    - brotli CLI (for WASM validation): choco install brotli
    - jq (for JSON validation): choco install jq
    - wabt (for wasm-validate): https://github.com/WebAssembly/wabt/releases

    Usage:
    .\scripts\reproduce_baseline.ps1
    .\scripts\reproduce_baseline.ps1 -GodotPath "C:\path\to\Godot_v4.6.1-stable_win64.exe"
#>

param(
    [string]$GodotPath = "godot",
    [string]$OutputRoot = "$PSScriptRoot\..\repro_output",
    [switch]$SkipExport,
    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path "$PSScriptRoot\.."
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Godot Mini Game P1 Baseline Reproduction" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Project root: $ProjectRoot"
Write-Host "Godot path:   $GodotPath"
Write-Host "Output root:  $OutputRoot"
Write-Host "Timestamp:    $Timestamp"
Write-Host ""

# ─── Step 0: Verify tool versions ─────────────────────────────────
Write-Host "[Step 0] Verifying tool versions..." -ForegroundColor Yellow

try {
    $godotVersion = & $GodotPath --version 2>&1
    Write-Host "  Godot: $godotVersion" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Cannot run Godot at '$GodotPath'" -ForegroundColor Red
    Write-Host "  Install Godot 4.6.1.stable from https://godotengine.org/download/windows/" -ForegroundColor Red
    exit 1
}

try {
    $nodeVersion = node --version 2>&1
    Write-Host "  Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: Node.js not found (JavaScript tests will be skipped)" -ForegroundColor Yellow
}

# ─── Step 1: Verify repository state ──────────────────────────────
Write-Host ""
Write-Host "[Step 1] Verifying repository state..." -ForegroundColor Yellow

$commit = git -C $ProjectRoot rev-parse HEAD
$tag = git -C $ProjectRoot describe --tags --always
Write-Host "  Commit: $commit"
Write-Host "  Tag:    $tag"

# Verify plugin.cfg version
$pluginCfg = Get-Content "$ProjectRoot\addons\godot_mini_game\plugin.cfg" -Raw
if ($pluginCfg -match 'version="([^"]+)"') {
    $pluginVersion = $Matches[1]
    Write-Host "  Plugin version: $pluginVersion"
} else {
    Write-Host "  ERROR: Cannot read plugin version" -ForegroundColor Red
    exit 1
}

# Verify support-matrix.json version
$matrix = Get-Content "$ProjectRoot\support-matrix.json" -Raw | ConvertFrom-Json
$matrixVersion = $matrix.pluginVersion
Write-Host "  Matrix version: $matrixVersion"

if ($pluginVersion -ne $matrixVersion) {
    Write-Host "  ERROR: Version mismatch between plugin.cfg and support-matrix.json" -ForegroundColor Red
    exit 1
}

# ─── Step 2: Verify template integrity ────────────────────────────
Write-Host ""
Write-Host "[Step 2] Verifying template integrity..." -ForegroundColor Yellow

$templateJson = Get-Content "$ProjectRoot\addons\godot_mini_game\engine\template.json" -Raw | ConvertFrom-Json
$jsPath = "$ProjectRoot\addons\godot_mini_game\engine\godot.js"
$wasmPath = "$ProjectRoot\addons\godot_mini_game\engine\godot.wasm.br"

$jsActual = (Get-FileHash $jsPath -Algorithm SHA256).Hash.ToLower()
$jsExpected = $templateJson.artifacts.'godot.js'.sha256
$jsMatch = $jsActual -eq $jsExpected

$wasmActual = (Get-FileHash $wasmPath -Algorithm SHA256).Hash.ToLower()
$wasmExpected = $templateJson.artifacts.'godot.wasm.br'.sha256
$wasmMatch = $wasmActual -eq $wasmExpected

Write-Host "  Godot version: $($templateJson.godot.version)"
Write-Host "  Godot commit:  $($templateJson.godot.commit)"
Write-Host "  Emscripten:    $($templateJson.emscriptenVersion)"
Write-Host "  Bridge ABI:    $($templateJson.bridgeAbi)"
Write-Host "  Revision:      $($templateJson.revision)"

if ($jsMatch) {
    Write-Host "  godot.js SHA-256:   MATCH ($jsActual)" -ForegroundColor Green
} else {
    Write-Host "  godot.js SHA-256:   MISMATCH!" -ForegroundColor Red
    Write-Host "    Actual:   $jsActual" -ForegroundColor Red
    Write-Host "    Expected: $jsExpected" -ForegroundColor Red
    Write-Host "  WARNING: Bundled template has a known hash mismatch." -ForegroundColor Yellow
    Write-Host "  Export may fail or use a fallback template." -ForegroundColor Yellow
}

if ($wasmMatch) {
    Write-Host "  godot.wasm.br SHA-256: MATCH ($wasmActual)" -ForegroundColor Green
} else {
    Write-Host "  godot.wasm.br SHA-256: MISMATCH!" -ForegroundColor Red
    Write-Host "    Actual:   $wasmActual" -ForegroundColor Red
    Write-Host "    Expected: $wasmExpected" -ForegroundColor Red
}

# ─── Step 3: Run JavaScript unit tests ────────────────────────────
if (-not $SkipTests) {
    Write-Host ""
    Write-Host "[Step 3] Running JavaScript unit tests..." -ForegroundColor Yellow

    $testFiles = Get-ChildItem "$ProjectRoot\test\*.test.mjs"
    $passed = 0
    $failed = 0

    foreach ($testFile in $testFiles) {
        Write-Host "  Running $($testFile.Name)..." -NoNewline
        try {
            $output = node $testFile.FullName 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host " PASS" -ForegroundColor Green
                $passed++
            } else {
                Write-Host " FAIL" -ForegroundColor Red
                Write-Host "    $output" -ForegroundColor Gray
                $failed++
            }
        } catch {
            Write-Host " ERROR" -ForegroundColor Red
            $failed++
        }
    }

    Write-Host "  JS tests: $passed passed, $failed failed"
}

# ─── Step 4: Import project in Godot ──────────────────────────────
Write-Host ""
Write-Host "[Step 4] Importing project in Godot..." -ForegroundColor Yellow

$importLog = "$OutputRoot\godot-import-$Timestamp.log"
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

Write-Host "  Importing (headless)..."
& $GodotPath --headless --log-file $importLog --import --quit 2>&1 | Out-Null

if (Test-Path $importLog) {
    $errors = Select-String -Path $importLog -Pattern "ERROR" -CaseSensitive
    if ($errors) {
        Write-Host "  Import completed with errors:" -ForegroundColor Yellow
        $errors | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    } else {
        Write-Host "  Import completed successfully" -ForegroundColor Green
    }
}

# ─── Step 5: Export to WeChat ─────────────────────────────────────
if (-not $SkipExport) {
    Write-Host ""
    Write-Host "[Step 5] Exporting to WeChat..." -ForegroundColor Yellow

    $wechatOutput = "$OutputRoot\wechat-$Timestamp"
    $exportScript = @"
extends SceneTree
func _init() -> void:
    var Exporter := load("res://addons/godot_mini_game/exporter.gd")
    var exporter = Exporter.new()
    exporter.log_callback = func(message: String) -> void: print("[export] ", message)
    var error = await exporter.export_mini_game(
        "wechat",
        "wxtest123",
        "portrait",
        "Web",
        "$($wechatOutput.Replace('\', '/'))"
    )
    quit(0 if error == OK else 1)
"@

    $scriptPath = "$OutputRoot\run_export_wechat.gd"
    Set-Content -Path $scriptPath -Value $exportScript

    Write-Host "  Running export..."
    & $GodotPath --headless --log-file "$OutputRoot\godot-export-wechat-$Timestamp.log" --path $ProjectRoot --script $scriptPath 2>&1 | Out-Null

    if (Test-Path "$wechatOutput\.godot-mini-game-export.json") {
        Write-Host "  WeChat export: SUCCESS" -ForegroundColor Green
        $manifest = Get-Content "$wechatOutput\.godot-mini-game-export.json" -Raw | ConvertFrom-Json
        Write-Host "    Platform: $($manifest.platform)"
        Write-Host "    Template: $($manifest.template.godot_version)"
        Write-Host "    Commit:   $($manifest.template.godot_commit)"

        # Verify output structure
        $requiredFiles = @(
            "adapter.js", "fetch.js", "game.js", "game.json",
            "project.config.json", "project.private.config.json",
            "engine\godot.wasm.br", "engine\godot.zip",
            "js\libs\godot.js", "js\libs\sdk.js",
            "js\loader.js", "js\platform_runtime.js"
        )
        foreach ($file in $requiredFiles) {
            $fullPath = "$wechatOutput\$file"
            if (Test-Path $fullPath) {
                $size = (Get-Item $fullPath).Length
                Write-Host "    OK: $file ($size bytes)" -ForegroundColor Gray
            } else {
                Write-Host "    MISSING: $file" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  WeChat export: FAILED" -ForegroundColor Red
        if (Test-Path "$OutputRoot\godot-export-wechat-$Timestamp.log") {
            Write-Host "  Check log: $OutputRoot\godot-export-wechat-$Timestamp.log" -ForegroundColor Yellow
        }
    }
}

# ─── Step 6: Export to Douyin ─────────────────────────────────────
if (-not $SkipExport) {
    Write-Host ""
    Write-Host "[Step 6] Exporting to Douyin..." -ForegroundColor Yellow

    $douyinOutput = "$OutputRoot\douyin-$Timestamp"
    $exportScriptDouyin = @"
extends SceneTree
func _init() -> void:
    var Exporter := load("res://addons/godot_mini_game/exporter.gd")
    var exporter = Exporter.new()
    exporter.log_callback = func(message: String) -> void: print("[export] ", message)
    var error = await exporter.export_mini_game(
        "douyin",
        "tttest123",
        "portrait",
        "Web",
        "$($douyinOutput.Replace('\', '/'))"
    )
    quit(0 if error == OK else 1)
"@

    $scriptPathDouyin = "$OutputRoot\run_export_douyin.gd"
    Set-Content -Path $scriptPathDouyin -Value $exportScriptDouyin

    Write-Host "  Running export..."
    & $GodotPath --headless --log-file "$OutputRoot\godot-export-douyin-$Timestamp.log" --path $ProjectRoot --script $scriptPathDouyin 2>&1 | Out-Null

    if (Test-Path "$douyinOutput\.godot-mini-game-export.json") {
        Write-Host "  Douyin export: SUCCESS" -ForegroundColor Green
        $manifest = Get-Content "$douyinOutput\.godot-mini-game-export.json" -Raw | ConvertFrom-Json
        Write-Host "    Platform: $($manifest.platform)"
        Write-Host "    Subpackage field: $($manifest.platform_contract.subpackage_field)"
    } else {
        Write-Host "  Douyin export: FAILED" -ForegroundColor Red
        if (Test-Path "$OutputRoot\godot-export-douyin-$Timestamp.log") {
            Write-Host "  Check log: $OutputRoot\godot-export-douyin-$Timestamp.log" -ForegroundColor Yellow
        }
    }
}

# ─── Step 7: Generate checksums ───────────────────────────────────
Write-Host ""
Write-Host "[Step 7] Generating checksums..." -ForegroundColor Yellow

$checksums = @()
$files = Get-ChildItem "$ProjectRoot\addons" -Recurse -File
foreach ($file in $files) {
    if ($file.Extension -in @('.gd', '.js', '.json', '.template', '.cfg', '.txt', '.md', '.wav', '.png')) {
        $hash = (Get-FileHash $file.FullName -Algorithm SHA256).Hash.ToLower()
        $relative = $file.FullName.Substring($ProjectRoot.Length + 1).Replace('\', '/')
        $checksums += "$hash  $($file.Length)  $relative"
    }
}

$checksums | Sort-Object | Set-Content "$OutputRoot\SHA256SUMS-$Timestamp.txt"
Write-Host "  Checksums written to $OutputRoot\SHA256SUMS-$Timestamp.txt" -ForegroundColor Green

# ─── Summary ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Reproduction Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Repository:  $commit ($tag)"
Write-Host "Plugin:      v$pluginVersion"
Write-Host "Godot:       $($templateJson.godot.version)"
Write-Host "Template:    $($templateJson.godot.commit.Substring(0, 10)) r$($templateJson.revision)"
Write-Host "Output:      $OutputRoot"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Open WeChat DevTools and import the wechat output directory"
Write-Host "  2. Open Douyin DevTools and import the douyin output directory"
Write-Host "  3. Verify both compile and start without errors"
Write-Host "  4. Run the export again to verify reproducibility"
Write-Host "  5. Compare SHA256SUMS between runs"
