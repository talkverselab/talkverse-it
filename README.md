# italian_universe

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 배포 · 앱 업데이트 (2026-09-10 통일)

- **리포 이름**: `talkverselab/talkverse-it` (이전 `italian-universe` — GitHub 리다이렉트되지만 remote를 새 이름으로 바꿔 두세요)
  ```
  git remote set-url origin https://github.com/talkverselab/talkverse-it.git
  ```
- **푸시하면 자동 배포**: master 푸시 → GitHub Actions가 서명된 APK와 `latest.json`을 `latest` 릴리스에 올립니다.
  `**.md`만 바꾼 푸시는 빌드하지 않습니다.
- **폰에서 업데이트**: 앱의 설정(프로필) 화면 → **「앱 업데이트」** → 최신 빌드 확인 → 내려받아 설치.
  케이블·adb 없이 갱신됩니다. 첫 설치 때 한 번 「출처를 알 수 없는 앱 설치」 허용이 필요합니다.
- **빌드 번호**는 CI 실행 번호(`--build-number`)입니다. 로컬 `flutter build apk`로 만든 APK는
  pubspec의 작은 번호를 쓰므로 앱이 늘 "새 빌드 있음"으로 표시합니다 — 정상입니다.
- 관련 파일: `lib/services/update_service.dart`, `lib/screens/update_screen.dart`,
  `android/app/src/main/kotlin/**/MainActivity.kt`, `android/app/src/main/res/xml/file_paths.xml`,
  `.github/workflows/release.yml`
- 구현 안내서: https://github.com/talkverselab/talkverse-th/blob/master/docs/in-app-update-via-github.md
