# SGDK Mega Drive Starter

Small SGDK starter project for Sega Mega Drive / Genesis with:

- D-pad controlled sprite
- Tile background with waterfall
- Custom `rescomp` extension (`PALANIM`) driving palette animation

## Requirements

- Internet connection on first build (downloads SGDK and local JDK into `.tools/`)

Platform notes:

- macOS/Linux (native GCC toolchain flow): Homebrew + CMake + native `m68k-elf` GCC toolchain
- Windows: SGDK binaries are downloaded into `.tools/sgdk` automatically (or you can point to an existing SGDK install)

Windows support is included via PowerShell scripts:

- `scripts/ensure-local-java.ps1`
- `scripts/setup-windows-sgdk.ps1`
- `scripts/sgdk-make.ps1`
- `scripts/build-rescomp-ext.ps1`
- `scripts/run-rom.ps1`
- `scripts/test-rom.ps1`
- `sgdk.ps1` (short command wrapper)
- `sgdk.cmd` (policy-safe wrapper for PowerShell-restricted systems)

## Commands

- `make setup`: Install native toolchain, clone SGDK locally, build host tools, and rebuild SGDK libs for your compiler
- `make` or `make build`: Build `out/rom.bin`
- `make debug`: Build debug ROM
- `make clean`: Clean output
- `make test`: Build and run a ROM smoke test
- `make run`: Build and launch `out/rom.bin` in emulator

Windows PowerShell equivalents:

- `.\sgdk.cmd setup`
- `.\sgdk.cmd build`
- `.\sgdk.cmd debug`
- `.\sgdk.cmd clean`
- `.\sgdk.cmd test`
- `.\sgdk.cmd run`

## Windows Quick Start (After Clone)

1. Setup/build (auto-downloads SGDK + local JDK into `.tools/` if missing):
   `.\sgdk.cmd setup`
   or directly:
   `.\sgdk.cmd build`
2. Test:
   `.\sgdk.cmd test`
3. Configure emulator once (optional but recommended):
   Create `.megadrive-emulator.local` and add one line like:
   `C:\Emulators\BlastEm\blastem.exe {rom}`
4. Run:
   `.\sgdk.cmd run`

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

- `scripts/ensure-local-java.sh` / `scripts/ensure-local-java.ps1` download a local JDK into `.tools/java/current` (no system Java install required).
- `scripts/sgdk-make.sh` (macOS) runs native bootstrap (`scripts/setup-native-sgdk.sh`) when SGDK is missing.
- `scripts/sgdk-make.ps1` (Windows) runs `scripts/setup-windows-sgdk.ps1` and auto-downloads SGDK into `.tools/sgdk` when needed.

## Custom ResComp Extension

The project includes a template extension in `rescomp_ext/` and auto-builds it on `make`:

- extension source: `rescomp_ext/src/dev/retro/template/*.java`
- generated extension jar: `res/rescomp_ext.jar`
- extension resource usage: `res/resources.res`
- animation data file: `res/palanim/waterfall.panim`

`scripts/sgdk-make.sh` calls `scripts/build-rescomp-ext.sh` before invoking SGDK makefile.
Build scripts compile the extension jar using the local JDK from `.tools/java/current`.

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
