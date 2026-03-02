#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SGDK_DIR="${SGDK_DIR:-${PROJECT_ROOT}/.tools/sgdk}"
SGDK_TAG="${SGDK_TAG:-v2.11}"
SGDK_REPO="${SGDK_REPO:-https://github.com/Stephane-D/SGDK}"

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required to install native m68k-elf tools on macOS." >&2
  exit 1
fi

if ! command -v java >/dev/null 2>&1; then
  echo "Java is required by SGDK tools. Install Java and run setup again." >&2
  exit 1
fi

missing_formulae=()
for formula in m68k-elf-binutils m68k-elf-gcc; do
  if ! brew list --formula "${formula}" >/dev/null 2>&1; then
    missing_formulae+=("${formula}")
  fi
done

if ((${#missing_formulae[@]} > 0)); then
  echo "Installing native toolchain: ${missing_formulae[*]}"
  brew install "${missing_formulae[@]}"
else
  echo "Native toolchain already installed."
fi

if [[ ! -f "${SGDK_DIR}/makefile.gen" ]]; then
  echo "Cloning SGDK ${SGDK_TAG} into ${SGDK_DIR}"
  mkdir -p "$(dirname "${SGDK_DIR}")"
  git clone --depth 1 --branch "${SGDK_TAG}" "${SGDK_REPO}" "${SGDK_DIR}"
else
  echo "SGDK already present at ${SGDK_DIR}"
fi

if ! command -v cmake >/dev/null 2>&1; then
  echo "cmake is required to build SGDK host tools. Install cmake and run setup again." >&2
  exit 1
fi

echo "Building SGDK host tools"
make -C "${SGDK_DIR}/tools/convsym" convsym
cp "${SGDK_DIR}/tools/convsym/build/convsym" "${SGDK_DIR}/bin/convsym"

make -C "${SGDK_DIR}/tools/sjasm/src"
cp "${SGDK_DIR}/tools/sjasm/src/sjasm" "${SGDK_DIR}/bin/sjasm"

cmake -S "${SGDK_DIR}/tools/bintos/src" -B "${SGDK_DIR}/tools/bintos/build" -DCMAKE_BUILD_TYPE=Release
cmake --build "${SGDK_DIR}/tools/bintos/build" -j
cp "${SGDK_DIR}/tools/bintos/build/bintos" "${SGDK_DIR}/bin/bintos"

if [[ -f "${SGDK_DIR}/tools/xgmtool/src/CMakeLists.txt" ]]; then
  cmake -S "${SGDK_DIR}/tools/xgmtool/src" -B "${SGDK_DIR}/tools/xgmtool/build" -DCMAKE_BUILD_TYPE=Release
  cmake --build "${SGDK_DIR}/tools/xgmtool/build" -j
  cp "${SGDK_DIR}/tools/xgmtool/build/xgmtool" "${SGDK_DIR}/bin/xgmtool"
fi

# SGDK 2.11 source currently expects pre-C23 bool behavior.
extra_flags="${EXTRA_FLAGS:-}"
if [[ "${extra_flags}" != *"-std="* ]]; then
  extra_flags="${extra_flags} -std=gnu11"
fi

echo "Rebuilding SGDK libraries with local m68k-elf-gcc"
env PATH="${SGDK_DIR}/bin:${PATH}" GDK="${SGDK_DIR}" EXTRA_FLAGS="${extra_flags}" make -f "${SGDK_DIR}/makelib.gen" cleanrelease
env PATH="${SGDK_DIR}/bin:${PATH}" GDK="${SGDK_DIR}" EXTRA_FLAGS="${extra_flags}" make -f "${SGDK_DIR}/makelib.gen" release
env PATH="${SGDK_DIR}/bin:${PATH}" GDK="${SGDK_DIR}" EXTRA_FLAGS="${extra_flags}" make -f "${SGDK_DIR}/makelib.gen" cleandebug
env PATH="${SGDK_DIR}/bin:${PATH}" GDK="${SGDK_DIR}" EXTRA_FLAGS="${extra_flags}" make -f "${SGDK_DIR}/makelib.gen" debug

printf '%s\n' "${SGDK_DIR}" > "${PROJECT_ROOT}/.sgdk-path"
echo "Wrote ${PROJECT_ROOT}/.sgdk-path"
echo "Setup complete. Run: make"
