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

$godotVersion = (& $godotCommand.Source --version).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($godotVersion)) {
    throw "Could not determine the Godot editor version from '$($godotCommand.Source)'."
}
if ($godotVersion -notmatch '^4\.5') {
    throw "Windows playtest packaging is pinned to Godot 4.5, but '$godotVersion' is active. Point GODOT_EXE at a Godot 4.5 editor build."
}

$commitSha = "unknown"
$gitCommand = Get-Command "git" -ErrorAction SilentlyContinue
if ($null -ne $gitCommand) {
    $dirtyLines = @(& $gitCommand.Source -C $projectRoot status --porcelain --untracked-files=normal 2>$null)
    if ($LASTEXITCODE -eq 0 -and $dirtyLines.Count -gt 0) {
        throw "Refusing to package a dirty Git worktree. Commit, stash, or remove local changes so PLAYTEST_BUILD.txt identifies the exact source bytes."
    }
    $resolvedSha = (& $gitCommand.Source -C $projectRoot rev-parse HEAD 2>$null).Trim()
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($resolvedSha)) {
        $commitSha = $resolvedSha
    }
}

Write-Host "Validating Hellshot Frontier imports/scripts with Godot $godotVersion"
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

Write-Host "Smoke-launching the packaged release headlessly..."
& $exePath --headless --quit-after 5
if ($LASTEXITCODE -ne 0) {
    throw "The packaged HellshotFrontier.exe failed its headless startup smoke check with exit code $LASTEXITCODE."
}

$shortSha = if ($commitSha.Length -ge 10) { $commitSha.Substring(0, 10) } else { $commitSha }
$metadataPath = Join-Path $windowsRoot "PLAYTEST_BUILD.txt"
@"
Hellshot Frontier — V3 External Playtest Build
Commit: $commitSha
Godot: $godotVersion
Export preset: Windows Playtest
Architecture: Windows x86_64
Build smoke: packaged executable started headlessly
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
