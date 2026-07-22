#!/usr/bin/env bash
# Downloads a pinned, checksum-verified actionlint release and runs it
# against every workflow file in .github/workflows/.
set -euo pipefail

VERSION="1.7.12"
BASE_URL="https://github.com/rhysd/actionlint/releases/download/v${VERSION}"

os="$(uname -s)"
arch="$(uname -m)"

case "$os" in
  Linux) platform_os="linux" ;;
  Darwin) platform_os="darwin" ;;
  *)
    echo "actionlint.sh: unsupported OS '${os}' — refusing to run unverified" >&2
    exit 1
    ;;
esac

case "$arch" in
  x86_64|amd64) platform_arch="amd64" ;;
  arm64|aarch64) platform_arch="arm64" ;;
  *)
    echo "actionlint.sh: unsupported architecture '${arch}' — refusing to run unverified" >&2
    exit 1
    ;;
esac

platform="${platform_os}_${platform_arch}"
ARCHIVE="actionlint_${VERSION}_${platform}.tar.gz"

# Pinned per-platform sha256 checksums, from the official
# actionlint_${VERSION}_checksums.txt release asset.
declare -A SHA256=(
  ["linux_amd64"]="8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8"
  ["linux_arm64"]="325e971b6ba9bfa504672e29be93c24981eeb1c07576d730e9f7c8805afff0c6"
  ["darwin_amd64"]="5b44c3bc2255115c9b69e30efc0fecdf498fdb63c5d58e17084fd5f16324c644"
  ["darwin_arm64"]="aba9ced2dee8d27fecca3dc7feb1a7f9a52caefa1eb46f3271ea66b6e0e6953f"
)

sha256="${SHA256[$platform]:-}"
if [ -z "$sha256" ]; then
  echo "actionlint.sh: no pinned checksum for platform '${platform}' — refusing to run unverified" >&2
  exit 1
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

curl -fsSL -o "${workdir}/${ARCHIVE}" "${BASE_URL}/${ARCHIVE}"
echo "${sha256}  ${workdir}/${ARCHIVE}" | sha256sum -c -

tar -xzf "${workdir}/${ARCHIVE}" -C "$workdir" actionlint

echo "== actionlint: .github/workflows =="
"${workdir}/actionlint" -color
