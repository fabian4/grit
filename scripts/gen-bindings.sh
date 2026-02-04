#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

OUT_DIR="$ROOT_DIR/app/Sources/Services/Generated"
UDL_FILE="$ROOT_DIR/crates/core/src/interface.udl"
CONFIG_FILE="$ROOT_DIR/crates/core/uniffi.toml"

mkdir -p "$OUT_DIR"

pushd "$ROOT_DIR/crates/core" >/dev/null
cargo run --quiet --bin uniffi_gen -- "$UDL_FILE" "$OUT_DIR"
popd >/dev/null
