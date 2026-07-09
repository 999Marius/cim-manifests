# Windows build entry point — called by make sdk-build via CIM
# Builds dependencies then builds libiio with MSVC

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Building Windows dependencies..."
& cmd /c "`"$ScriptDir\windows_build_deps.cmd`""
if ($LASTEXITCODE -ne 0) {
    throw "windows_build_deps.cmd failed with exit code $LASTEXITCODE"
}

Write-Host "Building libiio..."
& "$ScriptDir\build_win_msvc.ps1"
