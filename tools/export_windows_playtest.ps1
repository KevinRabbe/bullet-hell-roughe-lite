param(
    [string]$GodotExe = $env:GODOT_EXE
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($GodotExe)) {
    $GodotExe = "godot"
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$buildRoot = Join-Path $projectRoot "build"
$windowsRoot = Join-Path $buildRoot "windows"
$exePath = Join-Path $windowsRoot "HellshotFrontier.exe"
$pckPath = Join-Path $windowsRoot "HellshotFrontier.pck"

$godotCommand = Get-Command $GodotExe -ErrorAction SilentlyContinue
if ($null -eq $godotCommand) {
    throw "Godot editor executable '$GodotExe' was not found. Put Godot 4.5 on PATH or set GODOT_EXE to the editor executable path."
}

Write-Host "Validating Hellshot Frontier imports/scripts with Godot: $($godotCommand.Source)"
& $godotCommand.Source --headless --path $projectRoot --import
if ($LASTEXITCODE -ne 0) {
    throw "Godot project validation/import failed with exit code $LASTEXITCODE. Fix project errors before creating a tester package."
}

if (Test-Path $windowsRoot) {
    Remove-Item $windowsRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $windowsRoot -Force | Out-Null

Write-Host "Exporting Hellshot Frontier release build..."
& $godotCommand.Source --headless --path $projectRoot --export-release "Windows Playtest" $exePath
if ($LASTEXITCODE -ne 0) {
    throw "Godot release export failed with exit code $LASTEXITCODE. Confirm matching Godot 4.5 export templates are installed."
}
if (-not (Test-Path $exePath)) {
    throw "Godot reported success but '$exePath' was not created."
}
if (-not (Test-Path $pckPath)) {
    throw "Godot reported success but '$pckPath' was not created. The Windows Playtest preset must export a separate PCK beside the executable."
}

$commitSha = "unknown"
try {
    $resolvedSha = (& git -C $projectRoot rev-parse HEAD 2>$null).Trim()
    if (-not [string]::IsNullOrWhiteSpace($resolvedSha)) {
        $commitSha = $resolvedSha
    }
} catch {
    # Git metadata is useful but must never prevent packaging an otherwise valid build.
}

$shortSha = if ($commitSha.Length -ge 10) { $commitSha.Substring(0, 10) } else { $commitSha }
$metadataPath = Join-Path $windowsRoot "PLAYTEST_BUILD.txt"
@"
Hellshot Frontier — V3 External Playtest Build
Commit: $commitSha
Export preset: Windows Playtest
Architecture: Windows x86_64
Built UTC: $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ"))

IMPORTANT: Extract the entire ZIP to a normal folder before launching HellshotFrontier.exe. Keep HellshotFrontier.exe and HellshotFrontier.pck together in the same folder.

When reporting a run, include a screenshot of the Run Results screen so the run seed, hunter, arsenal, wave, level, and gold can be reproduced.
"@ | Set-Content -Path $metadataPath -Encoding UTF8

New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null
$zipPath = Join-Path $buildRoot "HellshotFrontier-v3-playtest-$shortSha-win64.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}
Compress-Archive -Path (Join-Path $windowsRoot "*") -DestinationPath $zipPath -CompressionLevel Optimal

Write-Host ""
Write-Host "Playtest package ready:"
Write-Host "  $zipPath"
