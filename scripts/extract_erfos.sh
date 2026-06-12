#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DETECT_SCRIPT="$SCRIPT_DIR/detect_img_format.sh"
EXTRACT_EROFS="$ROOT_DIR/rom_extract/tools/extract.erofs"
SCRIPT_NAME="$(basename "$0")"

usage() {
  cat <<EOF
用法:
  $SCRIPT_NAME IMAGE

示例:
  $SCRIPT_NAME /path/to/vendor.img

脚本行为:
  1. 检查 IMAGE 是否为 erofs
  2. 输出目录自动使用镜像同级、去掉 .img 后缀后的目录名
  3. 例如 vendor.img -> vendor/
EOF
}

fail() {
  printf '[extract_erofs] %s\n' "$*" >&2
  exit 1
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
[[ -x "$DETECT_SCRIPT" ]] || fail "检测脚本不存在或不可执行: $DETECT_SCRIPT"
[[ -x "$EXTRACT_EROFS" ]] || fail "extract.erofs 不存在或不可执行: $EXTRACT_EROFS"

FORMAT="$("$DETECT_SCRIPT" "$IMAGE_PATH")"
[[ "$FORMAT" == "erofs" ]] || fail "镜像格式不是 erofs，当前检测结果: $FORMAT"

IMAGE_DIR="$(cd "$(dirname "$IMAGE_PATH")" && pwd)"
IMAGE_NAME="$(basename "$IMAGE_PATH")"
OUTPUT_NAME="${IMAGE_NAME%.img}"
OUTPUT_DIR="$IMAGE_DIR/$OUTPUT_NAME"

if [[ "$OUTPUT_DIR" == "$IMAGE_PATH" ]]; then
  fail "无法推导输出目录: $IMAGE_PATH"
fi

if [[ -e "$OUTPUT_DIR" ]]; then
  fail "输出目录已存在: $OUTPUT_DIR"
fi

printf '[extract_erofs] image: %s\n' "$IMAGE_PATH"
printf '[extract_erofs] out:   %s\n' "$OUTPUT_DIR"
printf '[extract_erofs] cmd:   %s -i %s -x -o %s\n' "$EXTRACT_EROFS" "$IMAGE_PATH" "$OUTPUT_DIR"

"$EXTRACT_EROFS" -i "$IMAGE_PATH" -x -o "$OUTPUT_DIR"