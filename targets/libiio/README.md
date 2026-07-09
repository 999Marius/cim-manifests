# libiio CIM Manifest

Build [libiio](https://github.com/analogdevicesinc/libiio) from source on Linux, macOS, and Windows using CIM (Code in Motion).

## Quick Start

```bash
cim init --target libiio-unix
cd dsdk-libiio-unix
cim install os-deps
cim makefile
make sdk-build
```

**Prerequisites:**
- **Linux**: No additional setup required
- **macOS**: Homebrew must be installed
- **Windows**: Visual Studio 2019/2022/2026 with C++ workload must be installed manually. After `cim install os-deps`, add GnuWin32 to PATH:
  ```cmd
  set PATH=%PATH%;C:\Program Files (x86)\GnuWin32\bin
  ```

## Build Output

After a successful build, artifacts are installed inside the workspace:

**Linux:**
- `install/bin/` — utilities (iio_info, iio_attr, iiod, etc.)
- `install/lib/` — libiio shared library
- `install/include/` — C/C++ headers

**macOS:**
- `install/Frameworks/iio.framework/` — framework bundle (library + headers)
- `install/Frameworks/iio.framework/Tools/` — utilities
- `install/lib/pkgconfig/` — pkg-config file

**Windows:**
- `install\bin\` — utilities and runtime DLLs
- `install\lib\` — libiio import library
- `install\include\` — C/C++ headers

**Linux/macOS:**
- `install/venv/` — Python virtual environment with pylibiio

## Build Options

Override defaults with `make VAR=value sdk-build`:

| Variable | Default | Description |
|----------|---------|-------------|
| LIBIIO_BUILD_TYPE | RelWithDebInfo | CMake build type |
| LIBIIO_UTILS | ON | Build utility programs |
| LIBIIO_IIOD | ON | Build IIO daemon |
| LIBIIO_COMPAT | ON | v0.x compatibility layer |
| LIBIIO_USB | ON | USB backend |
| LIBIIO_NETWORK | ON | Network backend |
| LIBIIO_LOCAL | ON | Local backend |
| LIBIIO_SERIAL | OFF | Serial backend |
| LIBIIO_EMU | OFF | Emulation backend |
| LIBIIO_PYTHON | OFF | Python bindings |
| LIBIIO_CPP | OFF | C++ bindings |
| LIBIIO_CSHARP | OFF | C# bindings |

## Other Targets

```bash
make sdk-test      # Build and run tests
make sdk-clean     # Remove build artifacts
make sdk-envsetup  # Print current build options
```

## Supported Platforms

- **Linux**: Ubuntu 22.04, 24.04, 26.04 and Fedora 42, 43 on x86_64 and aarch64
- **macOS**: Any recent version with Homebrew
- **Windows**: Windows 10/11 with Visual Studio 2019, 2022, or 2026
