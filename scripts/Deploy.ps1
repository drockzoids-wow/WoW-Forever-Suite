param([string]$GamePath = 'C:\Games\World of Warcraft\_classic_beta_')
$ErrorActionPreference = 'Stop'
$workspacePath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$sourcePath = Join-Path $workspacePath 'src\WoWForeverSuite'
$addonRoot = [System.IO.Path]::GetFullPath((Join-Path $GamePath 'Interface\AddOns'))
$targetPath = Join-Path $addonRoot 'WoWForeverSuite'
if (-not (Test-Path -LiteralPath (Join-Path $sourcePath 'WoWForeverSuite_Camelot.toc'))) { throw 'Addon source is missing.' }
if (-not (Test-Path -LiteralPath $addonRoot)) { throw "Addon directory not found: $addonRoot" }
if (Test-Path -LiteralPath $targetPath) {
    $existing = Get-Item -LiteralPath $targetPath -Force
    $existingTarget = $existing.Target | Select-Object -First 1
    if ($existing.LinkType -eq 'Junction' -and $existingTarget -and [System.IO.Path]::GetFullPath($existingTarget) -eq $sourcePath) {
        Write-Output "Already linked: $targetPath"
        return
    }
    throw "An existing addon occupies $targetPath. Nothing was overwritten."
}
New-Item -ItemType Junction -Path $targetPath -Target $sourcePath | Out-Null
Write-Output "Linked addon: $targetPath"
