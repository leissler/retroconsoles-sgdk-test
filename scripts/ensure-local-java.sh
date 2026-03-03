#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JAVA_VERSION="${JAVA_VERSION:-17}"
JAVA_ROOT="${PROJECT_ROOT}/.tools/java"
JAVA_HOME_DIR="${JAVA_ROOT}/current"

if [[ -x "${JAVA_HOME_DIR}/bin/java" && -x "${JAVA_HOME_DIR}/bin/javac" && -x "${JAVA_HOME_DIR}/bin/jar" ]]; then
  echo "${JAVA_HOME_DIR}"
  exit 0
fi

OS_NAME="$(uname -s 2>/dev/null || true)"
ARCH_NAME="$(uname -m 2>/dev/null || true)"

case "${OS_NAME}" in
  Darwin) platform="mac" ;;
  Linux) platform="linux" ;;
  *) echo "Unsupported OS for local Java bootstrap: ${OS_NAME}" >&2; exit 1 ;;
esac

case "${ARCH_NAME}" in
  x86_64|amd64) arch="x64" ;;
  arm64|aarch64) arch="aarch64" ;;
  *) echo "Unsupported CPU architecture for local Java bootstrap: ${ARCH_NAME}" >&2; exit 1 ;;
esac

download_url="https://api.adoptium.net/v3/binary/latest/${JAVA_VERSION}/ga/${platform}/${arch}/jdk/hotspot/normal/eclipse?project=jdk"
tmp_dir="$(mktemp -d)"
archive_file="${tmp_dir}/jdk.tar.gz"

cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

echo "Downloading local JDK ${JAVA_VERSION} (${platform}/${arch})..." >&2
if command -v curl >/dev/null 2>&1; then
  curl -fL -o "${archive_file}" "${download_url}"
elif command -v wget >/dev/null 2>&1; then
  wget -O "${archive_file}" "${download_url}"
else
  echo "Need curl or wget to download local JDK." >&2
  exit 1
fi

extract_dir="${tmp_dir}/extract"
mkdir -p "${extract_dir}"
tar -xzf "${archive_file}" -C "${extract_dir}"

source_root="$(find "${extract_dir}" -type d -maxdepth 3 -mindepth 1 | while read -r d; do
  if [[ -x "${d}/bin/java" && -x "${d}/bin/javac" ]]; then
    echo "${d}"
    break
  fi
done)"

if [[ -z "${source_root}" ]]; then
  echo "Could not locate extracted JDK home." >&2
  exit 1
fi

mkdir -p "${JAVA_ROOT}"
rm -rf "${JAVA_HOME_DIR}"
mv "${source_root}" "${JAVA_HOME_DIR}"

echo "${JAVA_HOME_DIR}"
