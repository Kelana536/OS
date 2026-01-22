#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${ROOT_DIR}/builds"
DISK_IMAGE="${BUILD_DIR}/virtual_disk"
BOCHS_CFG="${BUILD_DIR}/bochsrc.bxrc"

find_bochs_file() {
  local var_name="$1"
  shift
  local candidate
  for candidate in "$@"; do
    if [[ -f "${candidate}" ]]; then
      echo "${candidate}"
      return 0
    fi
  done
  echo ""
  return 1
}

BOCHS_BIOS="${BOCHS_BIOS:-}"
BOCHS_VGABIOS="${BOCHS_VGABIOS:-}"

if [[ -z "${BOCHS_BIOS}" ]]; then
  BOCHS_BIOS="$(find_bochs_file BOCHS_BIOS \
    /usr/share/bochs/BIOS-bochs-latest \
    /usr/local/share/bochs/BIOS-bochs-latest \
    /opt/homebrew/share/bochs/BIOS-bochs-latest)"
fi

if [[ -z "${BOCHS_VGABIOS}" ]]; then
  BOCHS_VGABIOS="$(find_bochs_file BOCHS_VGABIOS \
    /usr/share/bochs/VGABIOS-lgpl-latest \
    /usr/local/share/bochs/VGABIOS-lgpl-latest \
    /opt/homebrew/share/bochs/VGABIOS-lgpl-latest)"
fi

if [[ -z "${BOCHS_BIOS}" || -z "${BOCHS_VGABIOS}" ]]; then
  echo "Bochs BIOS files not found."
  echo "Set BOCHS_BIOS and BOCHS_VGABIOS env vars to the correct paths."
  exit 1
fi

mkdir -p "${BUILD_DIR}"

if [[ ! -f "${DISK_IMAGE}" ]]; then
  bximage -hd -mode=flat -size=60 -q "${DISK_IMAGE}"
fi

if [[ -f "${DISK_IMAGE}.lock" ]]; then
  rm -f "${DISK_IMAGE}.lock"
fi

cat > "${BOCHS_CFG}" <<EOF
megs: 32
romimage: file="${BOCHS_BIOS}"
vgaromimage: file="${BOCHS_VGABIOS}"
ata0-master: type=disk, path="${DISK_IMAGE}", mode=flat, cylinders=121, heads=16, spt=63
boot: disk
log: builds/bochsout.txt
mouse: enabled=0
keyboard: keymap="x11-pc-us.map"
EOF

make -C "${ROOT_DIR}"

BOCHS_CMD="${BOCHS_CMD:-bochs}"
exec "${BOCHS_CMD}" -f "${BOCHS_CFG}"
