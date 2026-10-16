$ErrorActionPreference = 'Stop'
$workspacePath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$runtimeRoot = Join-Path $workspacePath '.cache\lua-tools'
New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null
$packages = @(
    @{ Name = 'luaparse'; Version = '0.3.1'; Directory = 'luaparse' },
    @{ Name = 'fengari'; Version = '0.1.4'; Directory = 'fengari' },
    @{ Name = 'sprintf-js'; Version = '1.1.3'; Directory = 'fengari\node_modules\sprintf-js' },
    @{ Name = 'readline-sync'; Version = '1.4.10'; Directory = 'fengari\node_modules\readline-sync' },
    @{ Name = 'tmp'; Version = '0.0.33'; Directory = 'fengari\node_modules\tmp' },
    @{ Name = 'os-tmpdir'; Version = '1.0.2'; Directory = 'fengari\node_modules\os-tmpdir' }
)
foreach ($package in $packages) {
    $archivePath = Join-Path $runtimeRoot ($package.Name + '.tgz')
    Invoke-WebRequest -Uri ('https://registry.npmjs.org/' + $package.Name + '/-/' + $package.Name + '-' + $package.Version + '.tgz') -OutFile $archivePath -TimeoutSec 30
    $entries = tar -tf $archivePath
    if ($LASTEXITCODE -ne 0 -or ($entries | Where-Object { $_ -notmatch '^package/' -or $_ -match '(^|/)\.\.(/|$)' })) { throw 'Invalid runtime archive.' }
    $destinationPath = Join-Path $runtimeRoot $package.Directory
    New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
    tar -xf $archivePath -C $destinationPath --strip-components 1
    if ($LASTEXITCODE -ne 0) { throw 'Runtime extraction failed.' }
}
Write-Output 'Check dependencies are ready. No package install scripts were run.'
