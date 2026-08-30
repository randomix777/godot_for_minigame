#!/usr/bin/env pwsh
# Cross-platform plugin packaging script (Windows equivalent of package_plugin.sh)
# Output: dist/godot_mini_game_v{VERSION}.zip

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

# Read version from plugin.cfg
$pluginCfg = Get-Content "$ProjectDir/addons/godot_mini_game/plugin.cfg" -Raw
if ($pluginCfg -match 'version="([^"]+)"') {
    $Version = $Matches[1]
} else {
    Write-Error "Invalid or missing plugin version in plugin.cfg"
    exit 1
}

$OutputName = "godot_mini_game_v$Version"
$OutputZip = "$ProjectDir/dist/$OutputName.zip"

Write-Output "Packaging Godot Mini Game Plugin v$Version"
Write-Output "============================================"

# Create temp directory
$TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    # Create directory structure
    $AddonDir = "$TempDir/addons/godot_mini_game"
    New-Item -ItemType Directory -Path "$TempDir/addons" -Force | Out-Null
    Copy-Item -Path "$ProjectDir/addons/godot_mini_game" -Destination "$TempDir/addons/" -Recurse
    Copy-Item -Path "$ProjectDir/LICENSE" -Destination "$AddonDir/LICENSE"

    # Validate required files
    $required = @(
        "$AddonDir/LICENSE",
        "$AddonDir/GODOT_COPYRIGHT.txt",
        "$AddonDir/THIRD_PARTY_NOTICES.md",
        "$AddonDir/engine/template.json",
        "$AddonDir/plugin.cfg"
    )
    foreach ($f in $required) {
        if (-not (Test-Path $f) -or (Get-Item $f).Length -eq 0) {
            Write-Error "Required package file is missing or empty: $f"
            exit 1
        }
    }

    # Remove editor-generated files
    Get-ChildItem -Path $TempDir -Recurse -Filter "*.uid" | Remove-Item -Force
    Get-ChildItem -Path $TempDir -Recurse -Filter ".DS_Store" | Remove-Item -Force
    Get-ChildItem -Path $TempDir -Recurse -Filter "*.import" | Remove-Item -Force

    # Show contents
    Write-Output ""
    Write-Output "Contents:"
    Get-ChildItem -Path "$TempDir/addons" -Recurse -File | Sort-Object FullName | ForEach-Object {
        $rel = $_.FullName.Substring("$TempDir/".Length)
        $size = if ($_.Length -gt 1MB) { "{0:N1} MB" -f ($_.Length / 1MB) } else { "{0:N0} KB" -f ($_.Length / 1KB) }
        Write-Output ("  {0,-60} {1}" -f $rel, $size)
    }

    # Create zip using .NET (deterministic)
    New-Item -ItemType Directory -Path "$ProjectDir/dist" -Force | Out-Null
    if (Test-Path $OutputZip) { Remove-Item $OutputZip -Force }
    if (Test-Path "$OutputZip.sha256") { Remove-Item "$OutputZip.sha256" -Force }

    Compress-Archive -Path "$TempDir/addons" -DestinationPath $OutputZip -Force

    # Compute SHA-256
    $hash = (Get-FileHash -Path $OutputZip -Algorithm SHA256).Hash.ToLower()
    $archiveName = Split-Path -Leaf $OutputZip
    "$hash  $archiveName" | Set-Content -Path "$OutputZip.sha256" -NoNewline

    $size = (Get-Item $OutputZip).Length
    $sizeStr = if ($size -gt 1MB) { "{0:N1} MB" -f ($size / 1MB) } else { "{0:N0} KB" -f ($size / 1KB) }
    Write-Output ""
    Write-Output "============================================"
    Write-Output "Done: $OutputZip"
    Write-Output "Size: $sizeStr"
    Write-Output "SHA-256: $hash"

} finally {
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
