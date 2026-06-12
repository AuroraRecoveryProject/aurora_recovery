#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
  cat <<EOF
用法:
  $SCRIPT_NAME IMAGE

输出:
  ext4
  erofs
  sparse
  bootimg
  unknown
EOF
}

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

read_hex() {
  local file_path="$1"
  local offset="$2"
  local length="$3"

  xxd -p -s "$offset" -l "$length" "$file_path" 2>/dev/null | tr -d '\n'
}

IMAGE_PATH="${1:-}"

if [[ $# -eq 0 ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

[[ -f "$IMAGE_PATH" ]] || fail "文件不存在: $IMAGE_PATH"

FILE_HEADER="$(read_hex "$IMAGE_PATH" 0 4)"
BOOT_MAGIC="$(read_hex "$IMAGE_PATH" 0 8)"
EROFS_MAGIC="$(read_hex "$IMAGE_PATH" 1024 4)"
EXT4_MAGIC="$(read_hex "$IMAGE_PATH" 1080 2)"

case "$BOOT_MAGIC" in
  414e44524f494421)
    printf 'bootimg\n'
    exit 0
    ;;
esac

case "$FILE_HEADER" in
  3aff26ed)
    printf 'sparse\n'
    exit 0
    ;;
esac

case "$EROFS_MAGIC" in
  e2e1f5e0)
    printf 'erofs\n'
    exit 0
    ;;
esac

case "$EXT4_MAGIC" in
  53ef)
    printf 'ext4\n'
    exit 0
    ;;
esac

printf 'unknown\n'