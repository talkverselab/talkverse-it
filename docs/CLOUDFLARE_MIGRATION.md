# Supabase → Cloudflare 이관 — 이탈리아어앱

**Supabase 사용 없음 — 확인 2026-10-26.** 아무것도 만들거나 지우지 않았다(D1·R2·Worker 생성, 코드 변경 없음).

- `lib/`·`pubspec.yaml`·`android/`·`ios/`·`tool/`·`tools/`·CI 워크플로에 Supabase 주소·키·패키지(`supabase_flutter`)·딥링크가 없다(git 기록에도 없음).
  표·저장소 버킷·RPC·로그인(Auth) 모두 쓰지 않는다.
- 앱이 바깥으로 부르는 곳은 「앱 업데이트」의 GitHub 릴리스(`latest.json`·APK)뿐이다(`lib/services/update_service.dart`).
- 콘텐츠(회화·문법·단어)는 앱에 번들된 `assets/data/**` 와 기기 안 SQLite(drift·sqflite), 학습 기록은 기기에만 저장한다.

## 공용 Supabase 안의 이탈리아어 행 (SELECT 만, 2026-10-26)

| 표 | `it` 행 |
|---|---|
| `public.items` (`language_code='it'`) | 0 |
| `tv_course_answers` · `tv_course_progress` · `tv_dev_notes` (`app_lang='it'`) | 0 · 0 · 0 |
| 저장소 버킷 (`it/` 경로) | 0 |

→ 옮길 데이터·지울 데이터 없음.

## 앞으로
- 콘텐츠를 서버로 옮기거나 로그인을 붙일 때는 공용 규칙을 따른다: 학습 데이터 → `talkverse-db`(`lang='it'`),
  계정 → `talkverse-accounts` + `talkverse-auth`, 파일(음성 등) → R2.
- 지금 할 일·대기 항목 없음.
