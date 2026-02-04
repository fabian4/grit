#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

OUT_DIR="$ROOT_DIR/app/Sources/Services/Generated"
UDL_FILE="$ROOT_DIR/crates/core/src/interface.udl"
CONFIG_FILE="$ROOT_DIR/crates/core/uniffi.toml"

mkdir -p "$OUT_DIR"

if ! command -v uniffi-bindgen >/dev/null 2>&1; then
  cargo install uniffi_bindgen
fi

uniffi-bindgen generate "$UDL_FILE" --language swift --out-dir "$OUT_DIR" --config "$CONFIG_FILE"
