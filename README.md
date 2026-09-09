# catimg for Windows (PowerShell)

A PowerShell wrapper around the original [`catimg`](https://github.com/posva/catimg)
C program, with a Windows (MinGW/GCC) build and PowerShell tooling.

The C source, build system, and rendering logic are the original `catimg` project
by Eduardo San Martin Morote. This repository only adds Windows support, a
PowerShell module wrapper, a build script, and a PowerShell argument completer.

## Features

- Renders JPEG, PNG, GIF, BMP, TGA, PSD, HDR, and PIC images in the terminal.
- True color (24-bit) output, with a 256-color fallback (`-t`).
- GIF animation support (`-l` loops).
- No external runtime dependencies (the `stb_image` decoder is vendored).

## Installation

### Prerequisites

- [MSYS2](https://www.msys2.org/) with MinGW-w64 GCC (the build was verified
  against GCC 16.1.0 in `D:\msys64\mingw64\bin`).
- CMake >= 3.10 and a Ninja generator.

### Building

```powershell
# From the repository root
.\scripts\build.ps1
```

Or manually:

```powershell
cmake -G Ninja .
cmake --build .
```

The binary is placed at `bin\catimg.exe` regardless of the build directory.

## Usage

### As a module

Import the wrapper to get a `catimg` function that forwards all arguments to
the binary. Pipeline input is passed through byte-exact, so image data is not
mangled the way `Get-Content` would.

```powershell
Import-Module .\catimg.ps1

catimg -h
catimg -r 1 test-images\mewtwo-front.png

# stdin piping (binary-safe)
[IO.File]::ReadAllBytes("test-images\mewtwo-front.png") | catimg -r 1 -t
```

### Directly

```powershell
bin\catimg.exe -r 1 test-images\mewtwo-front.png
```

### Options

| Option | Description |
|--------|-------------|
| `-h` | Display a help message |
| `-H` | Specify the height of the displayed image |
| `-w` | Specify the width of the displayed image |
| `-l` | Specify the number of loops for GIF animation |
| `-r` | Force the resolution of the image |
| `-c` | Convert colors to a restricted palette |
| `-t` | Disable true color and use 256 color instead |

## Completion

```powershell
. .\completion\_catimg.ps1
```

To load it for every PowerShell session, add that line to your `$PROFILE`.

## Testing

Test images are in `test-images/` (`mewtwo-front.png`, `mewtwo-back.png`,
`google.ico`, `catchem.gif`).

```powershell
Import-Module .\catimg.ps1
catimg -r 1 test-images\mewtwo-front.png
catimg -l 1 test-images\catchem.gif
```

## License

See the original project: https://github.com/posva/catimg