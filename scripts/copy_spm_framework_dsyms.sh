#!/bin/bash
# アーカイブ時に SPM / 埋め込みフレームワークの dSYM をアーカイブの dSYMs フォルダへ集める（Google Mobile Ads 等）。
# Organizer の「シンボルのアップロード失敗」を減らす目的。ARCHIVE_PATH が無い通常ビルドでは何もしない。
set -euo pipefail
if [[ -z "${ARCHIVE_PATH:-}" ]]; then
  exit 0
fi
DEST="${ARCHIVE_PATH}/dSYMs"
mkdir -p "${DEST}"
copy_dsyms_from() {
  local root="$1"
  [[ -d "${root}" ]] || return 0
  while IFS= read -r -d '' dsym; do
    base="$(basename "${dsym}")"
    cp -R "${dsym}" "${DEST}/${base}" 2>/dev/null || true
  done < <(find "${root}" -name "*.dSYM" -print0 2>/dev/null || true)
}
# ビルド成果物一式（フレームワーク同梱の dSYM）
copy_dsyms_from "${BUILT_PRODUCTS_DIR}"
copy_dsyms_from "${BUILD_DIR}"
# アーカイブ内 Products（埋め込み Watch 等）
copy_dsyms_from "${ARCHIVE_PATH}/Products"
# SPM（GoogleMobileAds / UserMessagingPlatform のバイナリに付随する場合）
SPM_ROOT="${BUILD_DIR%Build/*}"
for cand in \
  "${SPM_ROOT}SourcePackages/checkouts" \
  "${SPM_ROOT}SourcePackages/artifacts" \
  "${SPM_ROOT}SourcePackages/build"; do
  copy_dsyms_from "${cand}"
done
exit 0
