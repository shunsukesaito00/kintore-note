#!/usr/bin/env bash
# Xcode の PIF / dependency graph エラー対策用（ビルドサービス停止 + 任意で DerivedData 削除）
# 使う前に Xcode は終了（⌘Q）してください。

set -euo pipefail

echo "==> Stopping XCBBuildService (if running)..."
killall XCBBuildService 2>/dev/null || true
echo "    Done."

if [[ "${1:-}" == "--with-derived-data" ]]; then
  echo "==> Removing Kintore DerivedData folders..."
  DD_ROOT="${HOME}/Library/Developer/Xcode/DerivedData"
  if [[ -d "$DD_ROOT" ]]; then
    shopt -s nullglob
    for d in "$DD_ROOT"/Kintore-*; do
      [[ -d "$d" ]] || continue
      echo "    rm -rf $d"
      rm -rf "$d"
    done
    shopt -u nullglob
  fi
  echo "    Done. Reopen Xcode and build again."
else
  echo ""
  echo "Optional: also delete this project's DerivedData cache (Xcode must be quit):"
  echo "  $0 --with-derived-data"
fi
