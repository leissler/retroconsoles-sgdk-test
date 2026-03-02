# SGDK Mega Drive Starter

Small SGDK starter project with a hello-screen ROM for Sega Mega Drive / Genesis.

## Requirements

- macOS with Homebrew
- Java
- CMake
- Native `m68k-elf` GCC toolchain
- SGDK source tree (project-local or external)

## Commands

- `make setup`: Install native toolchain, clone SGDK locally, build host tools, and rebuild SGDK libs for your compiler
- `make` or `make build`: Build `out/rom.bin`
- `make debug`: Build debug ROM
- `make clean`: Clean output
- `make test`: Build and run a ROM smoke test
- `make run`: Build and launch `out/rom.bin` in emulator

## Build Backend

`scripts/sgdk-make.sh` chooses SGDK path in this order:

1. `SGDK` env var
2. `GDK` env var
3. `.sgdk-path` file in this project (contains SGDK path)
4. `.tools/sgdk` in this project

No Docker is used.

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
