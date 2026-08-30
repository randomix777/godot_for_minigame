# Build Godot 4.7.2 WASM template on Windows
# Usage: .\scripts\build_template_win.ps1 [godot_tag] [emsdk_version]

param(
    [string]$GodotTag = "4.7.2-stable",
    [string]$EmsdkVersion = "4.0.3",
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$BuildRoot = if ($env:GODOT_MINIGAME_BUILD_DIR) { $env:GODOT_MINIGAME_BUILD_DIR } else { Join-Path $ProjectDir "build_wasm" }
$SourceDir = Join-Path $BuildRoot "godot-$GodotTag"
$EmsdkDir = Join-Path $BuildRoot "emsdk"
$SupportMatrix = Join-Path $ProjectDir "support-matrix.json"

Write-Output "========================================"
Write-Output "Godot WASM Template Builder (Windows)"
Write-Output "========================================"
Write-Output ""
Write-Output "Godot tag: $GodotTag"
Write-Output "Emsdk version: $EmsdkVersion"
Write-Output "Build root: $BuildRoot"
Write-Output ""

# Read bridge_abi from support matrix
$matrix = Get-Content $SupportMatrix | ConvertFrom-Json
$bridgeAbi = $matrix.bridgeAbi
$templateSchema = $matrix.templateSchema
$templateRevision = if ($env:TEMPLATE_REVISION) { [int]$env:TEMPLATE_REVISION } else { 2 }

# Set output dir
if (-not $OutputDir) {
    $OutputDir = Join-Path $BuildRoot "output"
}
$OutputDir = Join-Path $OutputDir "$GodotTag\emsdk-$EmsdkVersion\2d_full\release\abi-$bridgeAbi\r$templateRevision"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Write-Output "[1/6] Checking tools..."
$tools = @("git", "python", "scons", "brotli", "jq", "node", "zip", "unzip", "wasm-validate")
foreach ($tool in $tools) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Output "  ERROR: Missing tool: $tool"
        exit 1
    }
    Write-Output "  $tool : OK"
}

# Activate EMSDK
Write-Output ""
Write-Output "[2/6] Activating EMSDK..."
& "$EmsdkDir\emsdk.bat" activate $EmsdkVersion 2>&1 | Out-Null
& "$EmsdkDir\emsdk_env.bat" 2>&1 | Out-Null

# Clone Godot source if not exists
Write-Output ""
Write-Output "[3/6] Checking Godot source..."
if (-not (Test-Path (Join-Path $SourceDir ".git"))) {
    Write-Output "  Cloning Godot $GodotTag..."
    git clone --depth 1 --branch $GodotTag "https://github.com/godotengine/godot.git" $SourceDir
}

# Verify source tag
$actualTag = git -C $SourceDir describe --tags --exact-match 2>$null
if ($actualTag -ne $GodotTag) {
    Write-Output "  WARNING: Source tag mismatch: $actualTag vs $GodotTag"
}
$godotCommit = git -C $SourceDir rev-parse HEAD
Write-Output "  Commit: $godotCommit"

# Patch detect.py for emscripten longjmp mode
Write-Output ""
Write-Output "[4/6] Patching detect.py..."
$detectPy = Join-Path $SourceDir "platform\web\detect.py"
$detectContent = Get-Content $detectPy -Raw
if ($detectContent -match "SUPPORT_LONGJMP='wasm'") {
    Write-Output "  Patching wasm -> emscripten"
    $patchedContent = $detectContent -replace "SUPPORT_LONGJMP='wasm'", "SUPPORT_LONGJMP='emscripten'"
    Set-Content $detectPy -Value $patchedContent -NoNewline
} elseif ($detectContent -match "SUPPORT_LONGJMP='emscripten'") {
    Write-Output "  Already patched"
} else {
    Write-Output "  ERROR: Unknown SUPPORT_LONGJMP configuration"
    exit 1
}

# Build Godot
Write-Output ""
Write-Output "[5/6] Building Godot..."
$cpuCount = [Environment]::ProcessorCount
cd $SourceDir
$sconsArgs = @(
    "platform=web",
    "target=template_release",
    "arch=wasm32",
    "optimize=size",
    "wasm_simd=no",
    "threads=no",
    "dlink_enabled=no",
    "javascript_eval=no",
    "module_webrtc_enabled=no",
    "module_webxr_enabled=no",
    "module_openxr_enabled=no",
    "-j$cpuCount"
)
& scons @sconsArgs 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Output "  ERROR: Build failed with exit code $LASTEXITCODE"
    exit 1
}
cd $ProjectDir

# Find artifacts
Write-Output ""
Write-Output "[6/6] Packaging template..."
$jsFiles = Get-ChildItem (Join-Path $SourceDir "bin") -Filter "godot.web.template_release.wasm32*.js" -ErrorAction SilentlyContinue
$mjsFiles = Get-ChildItem (Join-Path $SourceDir "bin") -Filter "godot.web.template_release.wasm32*.mjs" -ErrorAction SilentlyContinue
$wasmFiles = Get-ChildItem (Join-Path $SourceDir "bin") -Filter "godot.web.template_release.wasm32*.wasm" -ErrorAction SilentlyContinue

if ($jsFiles.Count -eq 0 -and $mjsFiles.Count -eq 0) {
    Write-Output "  ERROR: No JavaScript artifact found"
    exit 1
}
if ($wasmFiles.Count -eq 0) {
    Write-Output "  ERROR: No WASM artifact found"
    exit 1
}

$jsFile = if ($jsFiles.Count -gt 0) { $jsFiles[0] } else { $mjsFiles[0] }
$wasmFile = $wasmFiles[0]

Write-Output "  JS: $($jsFile.Name)"
Write-Output "  WASM: $($wasmFile.Name)"

# Create package directory
$packageDir = Join-Path $BuildRoot "template-package-$GodotTag"
New-Item -ItemType Directory -Force -Path $packageDir | Out-Null

# Copy files
Copy-Item $jsFile.FullName (Join-Path $packageDir "godot.js")
Copy-Item "$SourceDir\COPYRIGHT.txt" (Join-Path $packageDir "GODOT_COPYRIGHT.txt")
Brotli -f -q 11 -o (Join-Path $packageDir "godot.wasm.br") $wasmFile.FullName
"{$GodotTag.Replace('-', '.')}`n" | Out-File -FilePath (Join-Path $packageDir "version.txt") -Encoding ascii -NoNewline

# Calculate SHA-256
function Get-SHA256 {
    param([string]$Path)
    $hash = Get-FileHash $Path -Algorithm SHA256
    return $hash.Hash.ToLower()
}

$jsSha = Get-SHA256 (Join-Path $packageDir "godot.js")
$wasmSha = Get-SHA256 (Join-Path $packageDir "godot.wasm.br")

# Create template.json
$templateJson = @{
    schema = $templateSchema
    godot = @{
        version = $GodotTag.Replace('-', '.')
        commit = $godotCommit
    }
    emscriptenVersion = $EmsdkVersion
    profile = "2d_full"
    target = "release"
    revision = $templateRevision
    bridgeAbi = $bridgeAbi
    features = @{
        simd = $false
        threads = $false
        wasmExceptions = $false
    }
    artifacts = @{
        "godot.js" = @{ sha256 = $jsSha }
        "godot.wasm.br" = @{ sha256 = $wasmSha }
    }
}
$templateJson | ConvertTo-Json -Depth 10 | Out-File (Join-Path $packageDir "template.json") -Encoding utf8

# Create ZIP bundle
$bundleName = "godot_minigame_template_${GodotTag}_emsdk-${EmsdkVersion}_2d-full_release_abi-${bridgeAbi}_r${templateRevision}.zip"
$bundlePath = Join-Path $OutputDir $bundleName
Remove-Item $bundlePath -ErrorAction SilentlyContinue
Remove-Item "$bundlePath.sha256" -ErrorAction SilentlyContinue

Set-Location $packageDir
& zip -X -9 $bundlePath godot.js godot.wasm.br version.txt template.json GODOT_COPYRIGHT.txt
Set-Location $ProjectDir

# Calculate bundle SHA
$bundleSha = Get-SHA256 $bundlePath
"$bundleSha  $bundleName`n" | Out-File (Join-Path $OutputDir "$bundleName.sha256") -Encoding ascii -NoNewline

Write-Output ""
Write-Output "========================================"
Write-Output "SUCCESS"
Write-Output "========================================"
Write-Output "Bundle: $bundlePath"
Write-Output "Size: $([Math]::Round((Get-Item $bundlePath).Length / 1MB, 1)) MB"
Write-Output "SHA-256: $bundleSha"
Write-Output ""
Write-Output "Godot version: $($GodotTag.Replace('-', '.'))"
Write-Output "Godot commit: $godotCommit"
Write-Output "Emscripten: $EmsdkVersion"
