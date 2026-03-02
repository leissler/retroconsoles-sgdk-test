#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXT_SRC_DIR="${PROJECT_ROOT}/rescomp_ext/src"
EXT_BUILD_DIR="${PROJECT_ROOT}/.cache/rescomp_ext"
EXT_CLASSES_DIR="${EXT_BUILD_DIR}/classes"
EXT_JAR_OUT="${PROJECT_ROOT}/res/rescomp_ext.jar"

if [[ ! -d "${EXT_SRC_DIR}" ]]; then
  exit 0
fi

gdk_path="${1:-${SGDK:-${GDK:-}}}"
if [[ -z "${gdk_path}" && -f "${PROJECT_ROOT}/.sgdk-path" ]]; then
  gdk_path="$(<"${PROJECT_ROOT}/.sgdk-path")"
fi
if [[ -z "${gdk_path}" && -f "${PROJECT_ROOT}/.tools/sgdk/makefile.gen" ]]; then
  gdk_path="${PROJECT_ROOT}/.tools/sgdk"
fi

if [[ -z "${gdk_path}" || ! -f "${gdk_path}/bin/rescomp.jar" ]]; then
  echo "Cannot build rescomp extension: SGDK path or rescomp.jar not found." >&2
  exit 1
fi

if ! command -v javac >/dev/null 2>&1 || ! command -v jar >/dev/null 2>&1; then
  echo "Cannot build rescomp extension: javac/jar command not found." >&2
  exit 1
fi

java_sources=()
while IFS= read -r source_file; do
  java_sources+=("${source_file}")
done < <(find "${EXT_SRC_DIR}" -type f -name '*.java' | sort)
if [[ ${#java_sources[@]} -eq 0 ]]; then
  echo "No Java source found for rescomp extension in ${EXT_SRC_DIR}" >&2
  exit 1
fi

mkdir -p "${EXT_CLASSES_DIR}" "$(dirname "${EXT_JAR_OUT}")"
rm -rf "${EXT_CLASSES_DIR}"
mkdir -p "${EXT_CLASSES_DIR}"

echo "Building rescomp extension jar: ${EXT_JAR_OUT}"
javac -cp "${gdk_path}/bin/rescomp.jar" -d "${EXT_CLASSES_DIR}" "${java_sources[@]}"
jar --create --file "${EXT_JAR_OUT}" -C "${EXT_CLASSES_DIR}" .
