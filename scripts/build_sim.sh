#!/usr/bin/env bash
# Kintore を iOS Simulator 向けにビルドする（シミュレータ名に依存しない）。
# 使い方: ./scripts/build_sim.sh   または   ./scripts/build_sim.sh clean build
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEST="${DESTINATION:-generic/platform=iOS Simulator}"
echo "xcodebuild destination: $DEST" >&2

exec xcodebuild \
  -project Kintore.xcodeproj \
  -scheme Kintore \
  -destination "$DEST" \
  -derivedDataPath "${DERIVED_DATA_PATH:-$ROOT/build/DerivedData}" \
  CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-YES}" \
  "$@"
