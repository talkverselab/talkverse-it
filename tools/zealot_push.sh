#!/bin/bash
# 가장 최근 release APK 를 Zealot(https://apps.talkverse.uk)에 올린다. 빌드는 하지 않는다.
#   bash tools/zealot_push.sh ["변경 내용 한 줄"]     (없으면 최근 커밋 제목)
# 덮어 설치 조건: 서명 SHA-1 이 아래 값과 같고, 빌드 번호가 폰에 깔린 것보다 커야 한다(CLAUDE.md §1·§8).
set -euo pipefail
APP_NAME="이탈리아어유니버스"
SIGN_SHA1="9cc4bc932638be43a3982df20b71c4750288476b"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

APK="$(ls -t "$ROOT"/build/app/outputs/flutter-apk/*release*.apk 2>/dev/null | head -1 || true)"
[ -n "$APK" ] || { echo "release APK 없음: build/app/outputs/flutter-apk/ (먼저 flutter build apk --release --build-number=<번호>)" >&2; exit 1; }

# 서명이 다르면 폰에서 덮어 설치가 안 된다 → 올리지 않는다
SIGNER="$(command -v apksigner || ls -t "${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"/build-tools/*/apksigner 2>/dev/null | head -1 || true)"
if [ -n "$SIGNER" ]; then
  GOT="$("$SIGNER" verify --print-certs "$APK" | grep -i 'SHA-1' | head -1 | awk '{print $NF}')"
  [ "$GOT" = "$SIGN_SHA1" ] || { echo "서명 불일치: $GOT (기대 $SIGN_SHA1) — 올리지 않음. CLAUDE.md §1 참조" >&2; exit 1; }
else
  echo "apksigner 를 찾지 못해 서명 확인을 건너뜀" >&2
fi

NOTE="${1:-$(git -C "$ROOT" log -1 --pretty=%s)}"
echo "올림: $APK"
~/bin/zealot-upload "$APK" "$APP_NAME" -c "$NOTE"
