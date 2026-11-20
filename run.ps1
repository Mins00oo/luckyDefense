param([switch]$Editor, [switch]$Test, [switch]$WindowsTest, [switch]$Balance)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$engine = Join-Path $PSScriptRoot '.tools/Godot_v4.4.1-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $engine)) {
    $command = Get-Command godot -ErrorAction SilentlyContinue
    if (-not $command) { throw 'Godot 4.4+ is required. Import project.godot in Godot, or put godot on PATH.' }
    $engine = $command.Source
}
# Keep test/editor data local when running within a restricted workspace.
$env:APPDATA = Join-Path $PSScriptRoot '.tools/userdata'
$env:LOCALAPPDATA = Join-Path $PSScriptRoot '.tools/localdata'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
New-Item -ItemType Directory -Force $env:LOCALAPPDATA | Out-Null
if ($Test) {
    & $engine --headless --path $PSScriptRoot --editor --import --quit
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $engine --headless --path $PSScriptRoot --script tests/test_loop.gd
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $engine --headless --path $PSScriptRoot --script tests/test_input.gd
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $engine --headless --path $PSScriptRoot --script tests/test_phase2.gd
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $engine --headless --path $PSScriptRoot --script tests/test_phase3.gd
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $engine --headless --path $PSScriptRoot --fixed-fps 60 --script tests/test_simulation.gd
    exit $LASTEXITCODE
} elseif ($WindowsTest) {
    & $engine --path $PSScriptRoot --script tests/test_phase2_windows.gd
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $engine --path $PSScriptRoot --script tests/test_phase3_windows.gd
    exit $LASTEXITCODE
} elseif ($Balance) {
    & $engine --headless --path $PSScriptRoot --fixed-fps 60 --script tests/balance_simulation.gd -- --runs=100
    exit $LASTEXITCODE
} elseif ($Editor) {
    & $engine --path $PSScriptRoot --editor
} else {
    & $engine --path $PSScriptRoot
}
