#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROM_PATH="${PROJECT_ROOT}/out/rom.bin"
DRY_RUN=0
LOCAL_EMULATOR_FILE="${PROJECT_ROOT}/.megadrive-emulator.local"
SHARED_EMULATOR_FILE="${PROJECT_ROOT}/.megadrive-emulator"

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
  shift
fi

if [[ $# -gt 0 ]]; then
  ROM_PATH="$1"
fi

if [[ ! -f "${ROM_PATH}" ]]; then
  echo "ROM not found: ${ROM_PATH}" >&2
  echo "Run 'make' first." >&2
  exit 1
fi

run_or_print() {
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    printf 'DRY RUN:'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

read_emulator_from_file() {
  local file="$1"
  local line

  while IFS= read -r line; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "${line}" ]] && continue
    [[ "${line}" == \#* ]] && continue
    printf '%s\n' "${line}"
    return 0
  done < "${file}"
}

configured_emulator="${MEGADRIVE_EMULATOR:-}"
if [[ -z "${configured_emulator}" && -f "${LOCAL_EMULATOR_FILE}" ]]; then
  configured_emulator="$(read_emulator_from_file "${LOCAL_EMULATOR_FILE}" || true)"
fi
if [[ -z "${configured_emulator}" && -f "${SHARED_EMULATOR_FILE}" ]]; then
  configured_emulator="$(read_emulator_from_file "${SHARED_EMULATOR_FILE}" || true)"
fi

if [[ -n "${configured_emulator}" ]]; then
  if [[ "${configured_emulator}" == *"{rom}"* ]]; then
    cmd="${configured_emulator//\{rom\}/\"${ROM_PATH}\"}"
  else
    cmd="${configured_emulator} \"${ROM_PATH}\""
  fi
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "DRY RUN: ${cmd}"
    exit 0
  fi
  eval "${cmd}"
  exit 0
fi

# Preferred default for SGDK iteration when available.
if command -v blastem >/dev/null 2>&1; then
  run_or_print blastem "${ROM_PATH}"
  exit 0
fi

if [[ -x "/opt/homebrew/bin/blastem" ]]; then
  run_or_print /opt/homebrew/bin/blastem "${ROM_PATH}"
  exit 0
fi

for blastem_bin in \
  "/Applications/blastem/blastem" \
  "/Applications/blastem-osx-0.6.2/blastem" \
  "${HOME}/Applications/blastem/blastem" \
  "${HOME}/Applications/blastem-osx-0.6.2/blastem"; do
  if [[ -x "${blastem_bin}" ]]; then
    run_or_print "${blastem_bin}" "${ROM_PATH}"
    exit 0
  fi
done

for app_root in "/Applications" "${HOME}/Applications"; do
  if [[ -d "${app_root}" ]]; then
    found_blastem="$(find "${app_root}" -maxdepth 4 -type f -name blastem -perm -111 2>/dev/null | head -n 1 || true)"
    if [[ -n "${found_blastem}" ]]; then
      run_or_print "${found_blastem}" "${ROM_PATH}"
      exit 0
    fi
  fi
done

if [[ -d "/Applications/OpenEmu.app" ]]; then
  run_or_print open -a OpenEmu "${ROM_PATH}"
  exit 0
fi

if [[ -d "${HOME}/Applications/OpenEmu.app" ]]; then
  run_or_print open -a OpenEmu "${ROM_PATH}"
  exit 0
fi

cat >&2 <<EOF
No supported emulator found.
Install BlastEm (preferred) or OpenEmu, or configure one of:
- env var: MEGADRIVE_EMULATOR='command {rom}'
- ${LOCAL_EMULATOR_FILE}
- ${SHARED_EMULATOR_FILE}
EOF
exit 1
