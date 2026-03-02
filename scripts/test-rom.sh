#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROM_PATH="${PROJECT_ROOT}/out/rom.bin"

if [[ ! -s "${ROM_PATH}" ]]; then
  echo "Missing ROM output: ${ROM_PATH}" >&2
  exit 1
fi

sega_tag="$(dd if="${ROM_PATH}" bs=1 skip=256 count=4 status=none 2>/dev/null || true)"
if [[ "${sega_tag}" != "SEGA" ]]; then
  echo "ROM header check failed at 0x100: expected 'SEGA', got '${sega_tag}'" >&2
  exit 1
fi

rom_size="$(wc -c < "${ROM_PATH}" | tr -d '[:space:]')"
if (( rom_size < 131072 )); then
  echo "ROM size is too small (${rom_size} bytes). Expected at least 131072 bytes." >&2
  exit 1
fi

echo "ROM smoke test passed: ${ROM_PATH} (${rom_size} bytes)"
