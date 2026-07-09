:: Build libiio dependencies for Windows (libusb, libxml2, libzstd, libserialport)
:: Requires: cmake, git, 7zip, curl, Visual Studio
::
:: Variables (optional overrides):
::   LIBIIO_ARCH  - target architecture, e.g. x64 (default: x64)
::
:: Visual Studio version is auto-detected via vswhere.

@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

SET vswhere="%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
IF "%LIBIIO_ARCH%"=="" SET LIBIIO_ARCH=x64

:: Auto-detect latest installed Visual Studio
FOR /F "USEBACKQ TOKENS=*" %%F IN (`%vswhere% -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationVersion`) DO SET vs_version=%%F
FOR /F "USEBACKQ TOKENS=1 delims=." %%M IN (`echo !vs_version!`) DO SET vs_major=%%M

IF "!vs_major!"=="16" (
    SET LIBIIO_COMPILER=Visual Studio 16 2019
    SET LIBIIO_TOOLSET=v142
)
IF "!vs_major!"=="17" (
    SET LIBIIO_COMPILER=Visual Studio 17 2022
    SET LIBIIO_TOOLSET=v143
)
IF "!vs_major!"=="18" (
    SET LIBIIO_COMPILER=Visual Studio 18 2026
    SET LIBIIO_TOOLSET=v145
)

IF "!LIBIIO_COMPILER!"=="" (
    echo ERROR: Could not detect Visual Studio installation. Install VS2019, VS2022, or VS2026 with C++ workload.
    exit /b 1
)

echo Detected: !LIBIIO_COMPILER! ^(toolset !LIBIIO_TOOLSET!^)

:: Find MSBuild
FOR /F "USEBACKQ TOKENS=*" %%F IN (`%vswhere% -latest -products * -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe`) DO (
    SET msbuild="%%F"
)

:: Create and enter deps directory relative to this script's location
IF not exist "%~dp0..\deps" mkdir "%~dp0..\deps"
cd "%~dp0..\deps"

:: Clone/download dependencies (skip if already present)
IF not exist "zstd" git clone --branch v1.5.6 https://github.com/facebook/zstd.git
IF not exist "libserialport" git clone --branch libserialport-0.1.2 https://github.com/sigrokproject/libserialport.git
IF not exist "libusb" (
    curl --ssl-no-revoke -L -o libusb-1.0.27.7z https://github.com/libusb/libusb/releases/download/v1.0.27/libusb-1.0.27.7z
    7z x -y .\libusb-1.0.27.7z -o".\libusb"
    del .\libusb-1.0.27.7z
)
IF not exist "libxml2-2.9.14" (
    curl --ssl-no-revoke -L -o libxml2-2.9.14.tar.xz https://download.gnome.org/sources/libxml2/2.9/libxml2-2.9.14.tar.xz
    7z x -y .\libxml2-2.9.14.tar.xz
    7z x -y .\libxml2-2.9.14.tar -o"."
    del .\libxml2-2.9.14.tar.xz
    del .\libxml2-2.9.14.tar
)

:: Build libzstd (skip if already installed)
IF not exist "zstd-install" (
    echo Building libzstd...
    cmake -G "!LIBIIO_COMPILER!" -A %LIBIIO_ARCH% -DCMAKE_INSTALL_PREFIX=zstd-install -DZSTD_BUILD_PROGRAMS=OFF -DZSTD_BUILD_TESTS=OFF -S .\zstd\build\cmake -B zstd-build
    if %ERRORLEVEL% neq 0 (echo libzstd configure failed && exit /b %ERRORLEVEL%)
    cmake --build zstd-build --config Release --target install
    if %ERRORLEVEL% neq 0 (echo libzstd build failed && exit /b %ERRORLEVEL%)
) ELSE (echo libzstd already built, skipping)

:: Build libserialport (skip if already built)
IF not exist "libserialport\x64\Release\libserialport.lib" (
    echo Building libserialport...
    %msbuild% .\libserialport\libserialport.vcxproj /p:Platform=%LIBIIO_ARCH% /p:Configuration=Release /p:PlatformToolset=!LIBIIO_TOOLSET!
    if %ERRORLEVEL% neq 0 (echo libserialport build failed && exit /b %ERRORLEVEL%)
) ELSE (echo libserialport already built, skipping)

:: Build libxml2 (skip if already installed)
IF not exist "libxml2-install" (
    echo Building libxml2...
    cmake -G "!LIBIIO_COMPILER!" -A %LIBIIO_ARCH% -DCMAKE_INSTALL_PREFIX=libxml2-install -DLIBXML2_WITH_ICONV=OFF -DLIBXML2_WITH_LZMA=OFF -DLIBXML2_WITH_PYTHON=OFF -DLIBXML2_WITH_ZLIB=OFF -S .\libxml2-2.9.14\ -B libxml2-build
    if %ERRORLEVEL% neq 0 (echo libxml2 configure failed && exit /b %ERRORLEVEL%)
    cmake --build libxml2-build --config Release --target install
    if %ERRORLEVEL% neq 0 (echo libxml2 build failed && exit /b %ERRORLEVEL%)
) ELSE (echo libxml2 already built, skipping)