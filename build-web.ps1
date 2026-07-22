param(
    [string]$Godot = "godot"
)

$ErrorActionPreference = "Stop"
$repoRoot = $PSScriptRoot
$projectDir = Join-Path $repoRoot "gmtk-26"
$buildDir = Join-Path $repoRoot "build\web"
$zipPath = Join-Path $repoRoot "build\GMTK26-web.zip"

if (-not (Get-Command $Godot -ErrorAction SilentlyContinue)) {
    throw "Godot was not found. Pass its path, for example: .\build-web.ps1 -Godot 'C:\path\Godot_v4.7-stable_win64.exe'"
}

New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
& $Godot --headless --path $projectDir --export-release "Web (itch.io)" (Join-Path $buildDir "index.html")
if ($LASTEXITCODE -ne 0) {
    throw "Godot Web export failed with exit code $LASTEXITCODE."
}

if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}
Compress-Archive -Path (Join-Path $buildDir "*") -DestinationPath $zipPath -CompressionLevel Optimal
Write-Host "itch.io upload ready: $zipPath"
