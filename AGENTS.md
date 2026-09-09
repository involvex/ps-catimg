# AGENTS.md

This file provides guidance to AI agents (and human contributors) working on the `catimg` codebase. It covers project context, build commands, technologies, and development guidelines.

---

## Project Overview

`catimg` is a small C program that renders images directly in the terminal. It supports JPEG, PNG, GIF, BMP, TGA, PSD, HDR, and PIC formats through the [stb_image](https://github.com/nothings/stb) library. There are no external runtime dependencies.

- **Language:** C (C99)
- **Build System:** CMake >= 3.10
- **License:** MIT
- **Author:** Eduardo San Martin Morote

---

## Useful Commands

### Building

```sh
# Configure the project (from the project root)
cmake .

# Build the executable
make

# Install the binary and man page (may require elevated privileges)
make install
```

### Cleaning

```powershell
# Remove build artifacts
make clean

# Remove all generated files including CMake cache
Remove-Item -Recurse bin, CMakeFiles, CMakeCache.txt, cmake_install.cmake, Makefile
```

### Running

```sh
# Run after building
bin\catimg path/to/image.png

# Read image from stdin
some-command | bin\catimg -
```

### Documentation

```sh
# Generate API docs with Doxygen (if installed)
cmake .
make doc
```

---

## Technologies

| Component | Details |
|-----------|---------|
| **Language** | C (C99, `-std=c99`) |
| **Build System** | CMake 3.10+ |
| **Image Loading** | [stb_image.h](https://github.com/nothings/stb) (single-header library, vendored in `src/`) |
| **Standard Libraries** | `stdio.h`, `stdlib.h`, `string.h`, `unistd.h`, `signal.h`, `sys/ioctl.h` |
| **Math Library** | `-lm` (linked for color conversion math) |
| **Terminal Output** | ANSI escape sequences for true color / 256-color rendering, Unicode block characters (▀ ▄ █) |

### Source Modules

| File | Purpose |
|------|---------|
| `src/catimg.c` | Main entry point, argument parsing, terminal rendering loop, GIF animation |
| `src/sh_image.c` / `.h` | Image loading (via stb_image), resizing, pixel access |
| `src/sh_color.c` / `.h` | Color types (RGB, YUV), palette conversion, distance metrics, color hash table |
| `src/sh_utils.c` / `.h` | Terminal size detection, stdin reading, utility macros |
| `src/stb_image.h` | Vendored single-header image decoding library |
| `src/khash.h` | Vendored hash table implementation for color caching |

---

## Best Practices and Guidelines

### Code Style

- **C Standard:** Strict C99. Do not use C11 or later features unless absolutely necessary.
- **Compiler Warnings:** Build with `-Wall -Wextra`. Fix warnings rather than suppressing them.
- **Header Guards:** All `.h` files use `#ifndef __SH_*_H__` style include guards.
- **Naming:** Use `snake_case` for functions, types, and variables (e.g., `img_free`, `terminal_columns`, `color_t`).
- **Macros:** Utility macros (`SQUARED`, `RGB2X`, etc.) are `ALL_CAPS`.
- **Documentation:** Public APIs in headers use Doxygen-style `@brief` and `@param` annotations.

### Build & Compilation

- The CMake build sets `CMAKE_BUILD_TYPE Release` with `-Wall -Wextra -Os -std=c99`.
- Executables are output to `bin/` relative to the project root.
- The math library (`-lm`) is linked automatically via `target_link_libraries(catimg m)`.
- Do not introduce new external dependencies. Prefer vendored single-header libraries if a dependency is truly needed.

### Memory & Resource Management

- Every `img_create` / `img_load_from_*` must be paired with `img_free`.
- `init_hash_colors` and `free_hash_colors` bracket the program lifecycle.
- Signal handlers (`SIGINT`) are used for graceful GIF animation interruption; do not remove or weaken this behavior.

### Terminal Rendering

- Support both true color (24-bit) and 256-color fallback modes (`-t` flag).
- Use Unicode block characters (`▀`, `▄`, `█`) for higher-resolution rendering when UTF-8 is detected.
- Do not leave the terminal in a corrupted state (alternate screen, hidden cursor, etc.) on abnormal exit.

### Testing

- Test images are stored in `test-images/` (`mewtwo-front.png`, `mewtwo-back.png`, `google.ico`, `catchem.gif`).
- Before submitting changes, verify the build succeeds and the binary runs correctly on at least one test image.
- If adding new features, consider adding a test image and a simple validation script.

### Contributing

- Follow the project's [CONTRIBUTING.md](.github/CONTRIBUTING.md).
- One logical change per pull request.
- Update `README.md` if user-facing behavior changes.
- Keep commits focused and with meaningful messages.

### Repository Hygiene

- Build artifacts (`bin/`, `CMakeFiles/`, `CMakeCache.txt`, `Makefile`, `cmake_install.cmake`) are gitignored.
- Do not commit vendored library modifications unless absolutely necessary and documented.
- Man page source is at `man/catimg.1`.

---

## Environment Notes

- This project targets Unix-like systems (Linux, macOS) for development and deployment.
- The `catimg` binary outputs ANSI escape codes and requires a terminal that supports them.
- Windows builds are theoretically possible but not actively tested or maintained.