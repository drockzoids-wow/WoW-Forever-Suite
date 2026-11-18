$ErrorActionPreference = 'Stop'
$workspacePath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$sourcePath = Join-Path $workspacePath 'src\WoWForeverSuite'
& node (Join-Path $PSScriptRoot 'check-release.cjs')
if ($LASTEXITCODE -ne 0) { throw 'Release guard failed. Remove test diagnostics before packaging.' }
$destinationDirectory = Join-Path $workspacePath 'dist'
New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
$versionLine = Get-Content -LiteralPath (Join-Path $sourcePath 'WoWForeverSuite_Camelot.toc') | Where-Object { $_ -match '^## Version:' }
$version = ($versionLine -replace '^## Version:\s*', '').Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'Invalid addon version.' }
$destinationPath = Join-Path $destinationDirectory ("WoWForeverSuite-$version.zip")
Compress-Archive -LiteralPath $sourcePath -DestinationPath $destinationPath -Force
Write-Output $destinationPath
