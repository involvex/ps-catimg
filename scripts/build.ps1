# scripts/build.ps1
#
# Build the Windows version of catimg (MinGW/GCC backend via CMake + Ninja).
#
# Usage:
#   .\scripts\build.ps1            # configure + build in-tree
#   .\scripts\build.ps1 -Clean    # remove generated build files first
#   .\scripts\build.ps1 -Install # also run `cmake --install .`
#
# Requirements:
#   - CMake >= 3.10
#   - MinGW-w64 GCC (on PATH) or Visual Studio Build Tools
#   - Ninja (on PATH when CMake picks the Ninja generator)

[CmdletBinding()]
param(
    [switch]$Clean,
    [switch]$Install
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$BuildDir   = Join-Path $ProjectRoot "build"
$BinDir     = Join-Path $ProjectRoot "bin"

function Write-Step { param([string]$Msg); Write-Host "==> $Msg" -ForegroundColor Cyan }

if ($Clean) {
    Write-Step "Cleaning generated build artifacts"
    Remove-Item -Recurse $BuildDir -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $ProjectRoot "CMakeCache.txt") -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $ProjectRoot "CMakeFiles") -Recurse -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $ProjectRoot "build.ninja") -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $ProjectRoot "cmake_install.cmake") -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $ProjectRoot ".ninja_deps") -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $ProjectRoot ".ninja_log") -ErrorAction SilentlyContinue
}

if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    throw "cmake not found on PATH. Install CMake >= 3.10."
}

# In-tree Ninja build (matches the project's CMakeLists.txt default generator).
Write-Step "Configuring (Ninja)"
& cmake -S $ProjectRoot -B $BuildDir -G "Ninja" -DCMAKE_BUILD_TYPE=Release
if ($LASTEXITCODE -ne 0) { throw "cmake configure failed" }

Write-Step "Building"
& cmake --build $BuildDir --config Release
if ($LASTEXITCODE -ne 0) { throw "build failed" }

# CMakeLists.txt sets EXECUTABLE_OUTPUT_PATH to bin/ (relative to the source
# tree), so the built binary lands at <repo>\bin\catimg.exe regardless of the
# build directory. No copy step is needed.
if (-not (Test-Path (Join-Path $BinDir "catimg.exe"))) {
    throw "Build succeeded but bin\catimg.exe was not produced."
}
Write-Step "Binary ready at $BinDir\catimg.exe"

if ($Install) {
    Write-Step "Installing (cmake --install)"
    & cmake --install $BuildDir --config Release
    if ($LASTEXITCODE -ne 0) { throw "cmake install failed" }
}

Write-Host "Done. Try: bin\catimg.exe -h" -ForegroundColor Green