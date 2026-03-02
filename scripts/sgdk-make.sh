#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

gdk_path="${SGDK:-${GDK:-}}"

if [[ -z "${gdk_path}" && -f "${PROJECT_ROOT}/.sgdk-path" ]]; then
  gdk_path="$(<"${PROJECT_ROOT}/.sgdk-path")"
fi

if [[ -z "${gdk_path}" && -f "${PROJECT_ROOT}/.tools/sgdk/makefile.gen" ]]; then
  gdk_path="${PROJECT_ROOT}/.tools/sgdk"
fi

if [[ -z "${gdk_path}" ]]; then
  cat >&2 <<EOF
No local SGDK installation configured.
Run 'make setup' to install native dependencies and SGDK in this project.
Or set SGDK/GDK to your SGDK root path.
EOF
  exit 1
fi

if [[ -n "${gdk_path}" ]]; then
  if [[ ! -f "${gdk_path}/makefile.gen" ]]; then
    echo "SGDK path is set but makefile.gen was not found at: ${gdk_path}" >&2
    exit 1
  fi

  if ! command -v m68k-elf-gcc >/dev/null 2>&1; then
    cat >&2 <<EOF
Native toolchain not found: m68k-elf-gcc
Run 'make setup' to install native build dependencies.
EOF
    exit 1
  fi

  extra_path=("${gdk_path}/bin")
  if [[ -x "${gdk_path}/tools/convsym/build/convsym" ]]; then
    extra_path+=("${gdk_path}/tools/convsym/build")
  fi

  # SGDK 2.11 is not C23-clean yet; force pre-C23 mode unless caller set a standard.
  extra_flags="${EXTRA_FLAGS:-}"
  if [[ "${extra_flags}" != *"-std="* ]]; then
    extra_flags="${extra_flags} -std=gnu11"
  fi

  echo "Using local SGDK at ${gdk_path}"
  exec env PATH="$(IFS=:; echo "${extra_path[*]}"):${PATH}" GDK="${gdk_path}" EXTRA_FLAGS="${extra_flags}" make -f "${gdk_path}/makefile.gen" "$@"
fi
