# Build libiio with MSVC after dependencies are built
# Requires: Visual Studio, cmake, dependencies built via windows_build_deps.cmd
#
# Optional environment variables:
#   LIBIIO_BUILD_TYPE  - cmake build type (default: RelWithDebInfo)
#
# Visual Studio version is auto-detected via vswhere.

$ErrorActionPreference = "Stop"
$ErrorView = "NormalView"

if (-not $Env:LIBIIO_BUILD_TYPE) { $Env:LIBIIO_BUILD_TYPE = "RelWithDebInfo" }

$workspace = Split-Path -Parent $PSScriptRoot
$depsDir   = "$workspace\deps"
$installDir = "$workspace\install"

# Auto-detect latest installed Visual Studio
$vswhere = "${Env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vsVersion = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationVersion
$vsMajor = ($vsVersion -split '\.')[0]

switch ($vsMajor) {
    "16" { $compiler = "Visual Studio 16 2019"; $usbVsVersion = "VS2019" }
    "17" { $compiler = "Visual Studio 17 2022"; $usbVsVersion = "VS2022" }
    "18" { $compiler = "Visual Studio 18 2026"; $usbVsVersion = "VS2022" }
    default { throw "Could not detect Visual Studio. Install VS2019, VS2022, or VS2026 with C++ workload." }
}

Write-Host "Detected: $compiler"
Write-Host "Build type: $Env:LIBIIO_BUILD_TYPE"

New-Item -ItemType Directory -Force -Path "$workspace\build-msvc" | Out-Null
Copy-Item "$workspace\libiio\libiio.iss.cmakein" "$workspace\build-msvc"

cmake -G "$compiler" `
-DCMAKE_BUILD_TYPE="$Env:LIBIIO_BUILD_TYPE" `
-DCMAKE_INSTALL_PREFIX="$installDir" `
-DCOMPILE_WARNING_AS_ERROR=ON -DENABLE_IPV6=ON `
-DWITH_USB_BACKEND=ON -DWITH_SERIAL_BACKEND=ON -DWITH_EMU_BACKEND=ON `
-DCPP_BINDINGS=ON -DCSHARP_BINDINGS:BOOL=ON -DWITH_EXAMPLES=ON `
-DLIBXML2_LIBRARIES="$depsDir\libxml2-install\lib\libxml2.lib" `
-DLIBXML2_INCLUDE_DIR="$depsDir\libxml2-install\include\libxml2" `
-DLIBUSB_LIBRARIES="$depsDir\libusb\$usbVsVersion\MS64\dll\libusb-1.0.lib" `
-DLIBUSB_INCLUDE_DIR="$depsDir\libusb\include" `
-DLIBSERIALPORT_LIBRARIES="$depsDir\libserialport\x64\Release\libserialport.lib" `
-DLIBSERIALPORT_INCLUDE_DIR="$depsDir\libserialport" `
-DLIBZSTD_LIBRARIES="$depsDir\zstd-install\lib\zstd.lib" `
-DLIBZSTD_INCLUDE_DIR="$depsDir\zstd-install\include" `
-S "$workspace\libiio" -B "$workspace\build-msvc"

cmake --build "$workspace\build-msvc" --config $Env:LIBIIO_BUILD_TYPE
if ($LASTEXITCODE -ne 0) { throw "cmake build failed" }

cmake --install "$workspace\build-msvc" --config $Env:LIBIIO_BUILD_TYPE

# Copy runtime DLLs next to the installed binaries
Copy-Item "$depsDir\zstd-install\bin\zstd.dll"                    "$installDir\bin\" -Force
Copy-Item "$depsDir\libxml2-install\bin\libxml2.dll"               "$installDir\bin\" -Force
Copy-Item "$depsDir\libserialport\x64\Release\libserialport.dll"   "$installDir\bin\" -Force
Copy-Item "$depsDir\libusb\$usbVsVersion\MS64\dll\libusb-1.0.dll" "$installDir\bin\" -Force
