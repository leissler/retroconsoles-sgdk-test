# SGDK Mega Drive Starter

Small SGDK starter project for Sega Mega Drive / Genesis with:

- D-pad controlled sprite
- Tile background with waterfall
- Custom `rescomp` extension (`PALANIM`) driving palette animation

## Requirements

- Java
- Git (optional, only if you want git-based SGDK bootstrap; ZIP fallback works without Git)

Notes:

- Java Runtime (JRE) is enough to build and run with the prebuilt `res/rescomp_ext.jar`.
- Java Development Kit (JDK) is required only when you want to modify/rebuild `rescomp_ext` sources.

Platform notes:

- macOS/Linux (native GCC toolchain flow): CMake + native `m68k-elf` GCC toolchain
- Windows: SGDK binaries are downloaded into `.tools/sgdk` automatically (or you can point to an existing SGDK install)

Windows support is included via PowerShell scripts:

- `scripts/setup-windows-sgdk.ps1`
- `scripts/sgdk-make.ps1`
- `scripts/build-rescomp-ext.ps1`
- `scripts/run-rom.ps1`
- `scripts/test-rom.ps1`

## Commands

- `make setup`: Install native toolchain, clone SGDK locally, build host tools, and rebuild SGDK libs for your compiler
- `make` or `make build`: Build `out/rom.bin`
- `make debug`: Build debug ROM
- `make clean`: Clean output
- `make test`: Build and run a ROM smoke test
- `make run`: Build and launch `out/rom.bin` in emulator

Windows PowerShell equivalents:

- `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup-windows-sgdk.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\sgdk-make.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-rom.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-rom.ps1`

## Windows Quick Start (After Clone)

1. Install Java (if not already installed) and ensure `java` works in PowerShell.
2. Build (this auto-downloads SGDK into `.tools/sgdk` if missing):
   `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\sgdk-make.ps1`
3. Test:
   `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-rom.ps1`
4. Configure emulator once (optional but recommended):
   Create `.megadrive-emulator.local` and add one line like:
   `C:\Emulators\BlastEm\blastem.exe {rom}`
5. Run:
   `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-rom.ps1`

VS Code alternative:

- `Terminal -> Run Task -> Setup SGDK (Windows)`
- then `Build ROM`, `Test ROM`, `Run ROM`

## Build Backend

`scripts/sgdk-make.sh` chooses SGDK path in this order:

1. `SGDK` env var
2. `GDK` env var
3. `.sgdk-path` file in this project (contains SGDK path)
4. `.tools/sgdk` in this project

No Docker is used.

Automatic bootstrap:

- `scripts/sgdk-make.sh` (macOS) runs native bootstrap (`scripts/setup-native-sgdk.sh`) when SGDK is missing.
- `scripts/sgdk-make.ps1` (Windows) runs `scripts/setup-windows-sgdk.ps1` and auto-downloads SGDK into `.tools/sgdk` when needed.

## Custom ResComp Extension

The project includes a template extension in `rescomp_ext/` and auto-builds it on `make`:

- extension source: `rescomp_ext/src/dev/retro/template/*.java`
- generated extension jar: `res/rescomp_ext.jar`
- extension resource usage: `res/resources.res`
- animation data file: `res/palanim/waterfall.panim`

`scripts/sgdk-make.sh` calls `scripts/build-rescomp-ext.sh` before invoking SGDK makefile.

### PALANIM Syntax

In `.res` file:

`PALANIM name file palette firstColor colorCount [frameDelay]`

Data file format (`.panim`):

- One frame per line
- Exactly `colorCount` hexadecimal Genesis colors (`0x0BGR` or `0BGR`) per line
- `#` comments supported

Example:

`0200 0400 0640 08A0`

## VS Code Run Setup

This project includes ready-to-use VS Code configuration:

- `.vscode/tasks.json` with `Build ROM`, `Run ROM`, and `Test ROM`
- `.vscode/launch.json` with `Run Mega Drive ROM` in **Run and Debug**

The launcher in `scripts/run-rom.sh` picks emulator in this order:

1. `MEGADRIVE_EMULATOR` env var (if set)
2. `.megadrive-emulator.local` (git-ignored, per-developer)
3. `.megadrive-emulator` (optional shared project setting)
4. `blastem` on `PATH`
5. `/opt/homebrew/bin/blastem`
6. BlastEm binary discovered under `/Applications` or `~/Applications`
7. `OpenEmu.app`

Use `.megadrive-emulator.example` as template for local/shared emulator commands.

On Windows, VS Code tasks automatically call `scripts/run-rom.ps1` and prefer:

1. `MEGADRIVE_EMULATOR`
2. `.megadrive-emulator.local`
3. `.megadrive-emulator`
4. `blastem` / `blastem.exe` on `PATH`
5. common BlastEm install folders in `Program Files`
