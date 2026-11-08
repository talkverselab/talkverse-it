# CLAUDE.md — talkverselab/talkverse-it

이 폴더에서 작업하는 모든 세션이 먼저 읽는 규칙. **빌드·배포를 건드리기 전에 반드시 확인할 것.**

## 1. 서명 (가장 자주 사고 나는 곳)

이 앱은 GitHub 릴리스로 **앱 안에서 스스로 업데이트**한다.
폰에 이미 깔린 앱과 **서명 키가 같아야만** 덮어쓰기 설치가 된다.

### 쓰는 키 — 새로 만들지 말 것

- 폰에 깔린 앱과 같은 키: 로컬 `~/.android/debug.keystore`
  (alias `androiddebugkey`, store/key 비밀번호 `android`)
- SHA-1 `9C:C4:BC:93:26:38:BE:43:A3:98:2D:F2:0B:71:C4:75:02:88:47:6B`
- 같은 키가 리포 시크릿 **`ANDROID_DEBUG_KEYSTORE_BASE64`** 에 base64로 들어 있고, CI가 이걸 복원해 서명한다.
- 로컬에서 릴리스 빌드할 때도 같은 키를 쓴다. `android/key.properties`가 없으면 이렇게 만든다:

```bash
cp ~/.android/debug.keystore android/app/signing-key.jks
printf 'storePassword=android\nkeyPassword=android\nkeyAlias=androiddebugkey\nstoreFile=signing-key.jks\n' > android/key.properties
```

### 절대 하지 말 것

- **새 키스토어를 만들지 말 것.** 서명이 바뀌면 폰에서 앱을 지웠다 다시 깔아야 하고, **학습 기록이 전부 사라진다.**
- CI의 `Restore signing key` 단계를 지우거나, `build.gradle.kts`의 release 서명을
  `signingConfigs.getByName("debug")` 로 되돌리지 말 것.
  GitHub 러너는 빌드할 때마다 debug 키를 **새로 만들어** 서명이 매번 달라진다.
  (2026-09-10에 실제로 겪은 문제 — 17개 앱 설치가 전부 `INSTALL_FAILED_UPDATE_INCOMPATIBLE`로 실패했다.)
- `android/key.properties`, `android/app/signing-key.jks`를 커밋하지 말 것 (`.gitignore`에 있음).

### 설치가 실패하면

```
INSTALL_FAILED_UPDATE_INCOMPATIBLE: signatures do not match
```

→ 앱을 지우지 말고 **서명부터 확인**한다:

```bash
apksigner verify --print-certs <apk> | grep SHA-1   # 9cc4bc932638be43a3982df20b71c4750288476b 여야 한다
```

## 폰에 설치할 때 (PC에서 케이블로)

폰에 **듀얼 메신저 프로필(user 95)** 과 보안 폴더(user 150)가 있다. `adb install` 은 프로필을 지정하지 않으면
**모든 프로필에 설치**해서 앱 아이콘이 두 개(파란 말풍선 배지 달린 복제본)가 생긴다. 반드시 기본 프로필만 지정한다:

```bash
adb -s R3CY20HDN2K install --user 0 -r <apk>
```

(2026-09-11에 24개 앱이 전부 두 개씩 깔려 있던 것을 정리함. 앱 안의 「앱 업데이트」로 설치하면 이 문제는 생기지 않는다.)

## 2. 배포 흐름

- `master`(또는 기본 브랜치) 푸시 → GitHub Actions(`.github/workflows/release.yml`)가
  서명된 APK와 `latest.json`을 `latest` 릴리스에 올린다.
- **빌드 번호 = 워크플로 실행 번호**(`--build-number=${{ github.run_number }}`).
  앱은 자기 빌드 번호와 `latest.json`의 `build`를 견주어 새 빌드를 판단한다.
  로컬 `flutter build apk`로 만든 APK는 pubspec의 작은 번호를 써서 앱이 늘 "새 빌드 있음"으로 보인다 — 정상.
- `**.md`만 고친 푸시는 빌드하지 않는다(`paths-ignore`). 헛된 업데이트 알림 방지.
- **폰 업데이트**: Zealot(apps.talkverse.uk)에서 받는다. 프로필의 「앱 업데이트」 타일은 2026-11-07 메뉴 개편으로 뺐다(§14) — `update_screen.dart` 코드와 CI 의 `latest.json` 은 남아 있다.

관련 파일: `lib/services/update_service.dart`, `lib/screens/update_screen.dart`,
`android/app/src/main/kotlin/**/MainActivity.kt`(설치 메서드 채널),
`android/app/src/main/res/xml/file_paths.xml`, `.github/workflows/release.yml`

구현 안내서: https://github.com/talkverselab/talkverse-th/blob/master/docs/in-app-update-via-github.md

## 3. 리포

- 이름은 **`talkverselab/talkverse-<언어코드>`** 로 통일(2026-09-10). 옛 이름(`it-universe` 등)은 리다이렉트되지만
  remote는 새 이름으로 바꿔 둘 것: `git remote set-url origin https://github.com/talkverselab/talkverse-it.git`
- **공개(PUBLIC) 저장소**다. 앱이 토큰 없이 APK를 받으려면 공개여야 한다.
- 다운로드 허브: https://github.com/talkverselab/talkverse-releases

## 4. 공개 저장소라서 지킬 것

- **출처를 드러내지 말 것.** 자막·말뭉치 제공처 이름(스트리밍 서비스, 공개 자막 데이터셋 등), 책 이름·쪽수,
  드라마·영화 제목을 코드·에셋·문서·파일명·화면 문구 어디에도 남기지 않는다.
- 저작권 있는 원문(자막 대본, 원서 전사)을 리포에 넣지 않는다. 단어·빈도 통계만 쓰고 문장은 자체 제작한다.
- 새 파일을 추가할 때 위 두 가지를 먼저 확인할 것. 한 번 공개 커밋되면 히스토리에 남는다.

## 화면 구성 (2026-09-11 — zh 기준 이식)

홈 메뉴: 회화 · **문법** · **문장 카드** · **말하기** · **청크 검색** · 동사 활용 · 단어 · 표현 · 빈도 단어 · 성·수(준비중) · 발음(준비중) · **단어 카드**

새로 들어온 6개는 `talkverse/_update_kit/port6/` 의 공용 키트에서 왔다. **8개 앱(de·es·fa·fr·hi·hu·it·pt·tr)이 같은 코드**를 쓰므로,
고칠 일이 있으면 키트를 고치고 `port6_apply.py` 로 다시 배포하는 편이 낫다(개별 수정은 다음 배포에서 덮인다).

| 화면 | 파일 | 데이터 |
|---|---|---|
| 문법 강의·테스트 | `grammar_lesson_screen.dart` / `grammar_test_screen.dart` | `assets/data/grammar/lesson*.json` (`patterns[].examples[] = {tl, rd, ko}`) |
| 문장 카드 | `sentence_flashcard_screen.dart` | DB `turns` + `user_progress` |
| 말하기 연습 | `speaking_practice_screen.dart`, `services/speech_service.dart`, `services/speak_match.dart` | DB `turns`, 판정은 단어 단위 LCS ≥ 0.7 |
| 청크 검색 | `chunk_search_screen.dart`, `services/chunk_index_service.dart` | 회화 턴 + 문법 예문에서 1~3단어 청크 색인 |
| 단어 카드 | `word_flashcard_screen.dart` | `assets/data/vocab/travel_words.json` (`{ko, tx, rd, ic}`) — 2026-11-02 비움(아래) |

- **대화 턴에 한글 독음 `rd` 칸**이 있다(DB 스키마 v2, 시드 키 `db_seeded_v2`). 대화·문법·단어 모두 독음을 넣고,
  화면에서는 `KoReadingText` 로 전역 독음 토글에 연동한다.
- 대상어 문장 칸 이름은 템플릿 그대로 `es` 다(스페인어 앱에서 복제된 흔적). 언어와 무관하게 "대상어"로 읽으면 된다.
- **콘텐츠는 초안**이다 — 회화 5편 × 8턴, 문법 10패턴 × 예문 3, 단어 40개. 자체 제작이며 원문·출처를 쓰지 않는다.
  내용을 늘리려면 `_update_kit/content/<언어코드>.py` 를 고치고 `build_content.py` 로 다시 만든다.
- 말하기 연습은 `RECORD_AUDIO` 권한과 기기의 음성 인식(Google 앱)이 필요하다. 인식 언어는 `TtsService.locale` 을 따른다.

## 5. 표시 언어 (한국어 / English / 日本語 / 中文) — 2026-09-12

- 프로필 · 설정 → 「언어 / Language」 를 탭할 때마다 한국어 → English → 日本語 → 中文 순으로 바뀐다.
  `AppLangPrefs`(`lib/core/l10n.dart`)가 값을 들고 있고, 바뀌면 `main.dart` 의 `MaterialApp` key 가 바뀌어
  앱 전체가 새로 그려진다(홈으로 돌아감).
- **UI 문구는 `tr('한국어')` / `trf('{0}개', [n])` 로 감싼다.** 번역은 `lib/core/l10n_dict.dart` 의
  `kDictEn` / `kDictJa` / `kDictZh` 에서 찾고, 없으면 한국어가 그대로 나온다.
  새 문구를 추가하면 세 사전에 한 줄씩 넣을 것. 키는 코드의 한국어 문자열 그대로(보간은 `{0},{1}` 템플릿).
- `tr()` 은 const 가 아니다 — `const Text(tr(...))` 처럼 쓰면 컴파일 오류. 그 위젯의 `const` 를 뺀다.
  enum 생성자·`static const`·`case` 패턴에는 못 쓴다(한국어를 두고 getter 에서 `tr()`).
- **회화·단어·문법 콘텐츠(뜻·번역·설명)는 번역 대상이 아니다** — 화면 문구(메뉴·버튼·안내)만 바뀐다.
- 사전은 12개 언어 앱이 공용(`_update_kit/l10n/l10n_dict.dart` 원본). 다른 앱에서 고친 번역이 있으면 원본도 같이 고칠 것.

## 6. 갤럭시·아이폰 공용 인터페이스 — 2026-09-12

- 플랫폼 판단은 `lib/core/platform.dart` 의 `isIOS` / `isAndroid` 만 쓴다(`dart:io` Platform 직접 호출 금지 — 웹·테스트에서 깨짐).
- **화면 아래 고정 버튼·목록 바닥 여백은 `bottomInset(context)` 를 더한다**
  (`EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset(context))`). 아이폰 홈 인디케이터(34pt)·갤럭시 제스처 바에 가려지지 않게.
  새 화면을 만들 때도 같은 규칙.
- 글자 확대 상한 1.2배(`main.dart` builder) — 아이폰 Dynamic Type 로 타일이 깨지는 것 방지.
- iOS 오디오: `TtsService` 와 `AudioService` 가 iOS 에서 재생 카테고리(playback)를 잡는다 — 무음 스위치에서도 소리가 난다. 지우지 말 것.
- 「앱 업데이트」 타일은 Android 전용(APK 설치 채널). iOS 는 TestFlight 안내 타일이 대신 나온다. `UpdateService.install` 은 Android 에서만 호출.

## 7. iOS 빌드 — 초안 (2026-09-12)

- `.github/workflows/ios-build.yml`: 푸시마다 GitHub macOS 러너가 **서명 없는** IPA 를 아티팩트로 올린다(동작 확인용).
- `.github/workflows/ios-testflight.yml`: 리포 Variables `IOS_TESTFLIGHT_ENABLED=true` 일 때만 돈다.
  Apple Developer Program(유료) 활성화 → App Store Connect API 키 → `tools/ios/make_ios_cert.py` 로 인증서·시크릿 생성 → 시크릿 등록.
  절차: `docs/ios-build-and-testflight.md`.
- `ios/Runner/Info.plist` 에 마이크·음성 인식 권한 문구가 있다(말하기 연습). 지우면 iOS 에서 크래시.
- `release.yml`(Android) 은 `ios/**`·`docs/**`·`tools/**` 만 바뀐 푸시는 건너뛴다.

## 8. Zealot 무선 설치 (apps.talkverse.uk) — 2026-10-11

- **Zealot 앱이름: 이탈리아어유니버스** (앱 표시 이름 그대로. 그전에 Zealot 에 올린 적 없음. 바꾸면 Zealot 에 다른 앱이 새로 생긴다.)
- 올리기: `bash tools/zealot_push.sh ["변경 내용 한 줄"]` — `build/app/outputs/flutter-apk/` 의 가장 최근 release APK 를
  `~/bin/zealot-upload` 로 올린다(빌드는 하지 않음. 변경 내용을 안 주면 최근 커밋 제목). 서명 SHA-1 이 §1 값과 다르면 올리지 않는다.
- **덮어 설치 상태(2026-10-11 확인)**: 서명 = `android/key.properties` + `android/app/signing-key.jks` 가 이미 있고 SHA-1 `9C:C4:…:47:6B`(§1 과 같은 키) —
  단 **맥미니의 `~/.android/debug.keystore` 는 다른 키(`BE:B3:…:0B:81`)** 라서 §1 의 `cp ~/.android/debug.keystore …` 를 맥미니에서 다시 실행하면 안 된다.
  버전 코드 = `pubspec.yaml` `0.1.0+1` 인데 CI 릴리스는 빌드 5(`latest.json`) → 로컬 빌드는 `--build-number` 를 폰에 깔린 번호보다 크게 줘야 덮어 설치된다.
- **2026-10-26 첫 업로드(빌드 6)는 CI 가 만든 APK 를 그대로 올렸다** — `gh release download latest -R talkverselab/talkverse-it -p '*.apk'` → `apksigner` 로 SHA-1 확인 → `~/bin/zealot-upload`. 빌드 번호가 앱 안 업데이트(`latest.json`)와 같아 번호가 꼬이지 않으므로 이 방법을 기본으로 쓴다. 설치 페이지 https://apps.talkverse.uk/1mTtN/137
  M6 의 `apksigner` = `~/Library/Android/sdk/build-tools/36.0.0/apksigner`, M6 의 `~/.android/debug.keystore` 도 §1 과 다른 키 — 여기서도 §1 의 `cp` 를 하지 말 것.
- 서명 키는 새로 만들지 않았다(release 키가 이미 있음 — 폰·CI 와 같은 §1 키). 백업: Doppler `keys/prd` 의 `SIGNKEY_*`(`SIGNKEY_INDEX` 참조) + PC `D:\backup\signing_keys\talkverse-it\`. APK 백업 PC `D:\OneDrive\app project\talkverse-it\talkverse-it-latest.apk`.

## 9. 화면 톤·아이콘 — talkverse.uk (2026-10-26)

- 기준 `~/talkverse/branding/TONE.md`. 아이콘 = `make_icon.py` 로 만든 메시 바탕 남색 **È**(HelveticaNeue Medium, 강조선 하늘색 → 인디고). `flutter_launcher_icons` 쓰지 말 것.
- `lib/core/theme.dart` 는 색 이름(rojo·gualda·cal…)을 두고 값만 사이트 토큰. 이탈리아어 카드색 `AppColors.italia` `#3fa05a`(IT 배지·빈도 단어 배지).

## 10. iOS TestFlight (맥미니 직접 업로드) — 2026-11-01

- `bash tools/ios_release.sh [--no-build]` — 아카이브 → 자동 서명 export → PC `D:\OneDrive\app project\italian_universe\ios\` 백업 → App Store Connect 업로드. 번들 ID `com.talkverse.italianUniverse`, 팀 `QP8QRMA9CC`, 빌드 번호 = KST `yymmddHHMM`.
- 2026-11-01 첫 시도는 앱 레코드가 없어 missingApp. **2026-11-03 빌드 2611030208 TestFlight 업로드 성공**(아이패드 두 화면·리더·로그인 포함, UIDeviceFamily 1·2).
- 새 플러그인을 넣은 뒤 iOS 아카이브가 `Module '…' not found` 로 실패하면 `flutter clean && flutter pub get && (cd ios && pod install)` 뒤 다시.
- **Sign in with Apple**: 개발자 포털 App ID `com.talkverse.italianUniverse` 에 capability 를 켜야 IPA 에 `applesignin` 이 들어간다(2611030208 에는 없음 — 켠 뒤 다시 빌드).

## 11. 외부 자료 유래 데이터 제거 — 2026-11-02 (사용자 결정 "여행책에서 뽑은 단어는 안 됩니다")

- 주제별 단어·표현(`assets/data/vocab/travel_words.json`·`travel_expressions.json`)과 그 파서를 앱에서 뺐다. 두 파일은 빈 `themes` — 화면(단어·표현·단어 카드)은 「아직 단어가 없습니다.」.
- 다시 채울 때는 **빈도표(R1~R3) 기반 자체 제작**만. 외부 책·자막에서 뽑은 단어·문장은 넣지 않는다(§4).
- 2026-11-03 사용자 지시("git 에도 절대 안 남게")로 이력 재작성·강제 push 완료 — 모든 커밋에서 그 파일들과 출처 이름을 지움(master `1f66241`, 태그 `latest` `4f8009d`). GitHub 가 옛 커밋 번호로는 한동안 보여 줄 수 있어 완전 삭제는 GitHub 지원팀 캐시 삭제 요청이 필요하다. 이력 재작성은 사용자 지시 없이 하지 말 것.

## 12. 아이패드 두 화면·만화책 읽기형 리더 — 2026-11-03

- 일본어앱 구조 이식(`~/talkverse/LANG_APP_REPLICATE_PROMPT.md`): 탭 배우기·복습·탐색·나, 넓은 화면(≥720) 레일 + 왼쪽 칸 + 오른쪽 칸, 회화 리더 = 시안 it-01(`data/review/uxui/sian_it_01.md`).
- 회화 데이터는 바꾸지 않고 `lib/services/dialogue_service.dart` 가 `assets/data/dialogues/L1.json` 을 읽어 변환. A = 학습자(프로필 이름·성별), B = Giulia. 고정 인물 `CHARACTERS.md`.
- 동사 표·성·수 점·발음 표시는 데이터가 생기면 켜진다(지금 숨김). 단어 그림 `art/it`, 장면 컷은 아직 없음.
- 안드로이드 빌드 9 Zealot https://apps.talkverse.uk/1mTtN/218. 마지막 커밋에 `[skip ci]` 가 있으면 push 전체가 빌드를 건너뛴다 → `gh workflow run release.yml`.
- 스크린샷: `python3 tools/pane_shots.py <꺼진 iPad UDID> <스크래치> integration_test/dialogue_pane_test.dart`, 끝나면 `xcrun simctl shutdown`.

## 13. 절벽 구간 — 레마 기준(2026-11-03 사용자 지시)

- **R1 61 · R2 91 · R3 211 · R4 661**(55·60·70·80%), 상위 2,500 레마 88.0%. 이탈리아에서 만든 영화·드라마 5,513편 자막, 31,934,455 토큰을 레마로 센 값(러시아어앱 세션의 자국 작품 분석). 옛 웹·문어 혼합 표면형 값(225·329·761·2,069)은 폐기.
- 절차(스페인어·독일어앱과 같음): 활용형·동사+대명사 결합·여성/복수형을 원형으로 합산, 사전에 없는 가짜 원형·자막 표기·외국어 제외, 분모는 전체 토큰. 수정표는 세션 스크래치에만 있었다 — 다시 낼 때는 같은 원칙으로.
- 그림용 단어 리스트 talkversehanja `talkverse_art/words/it.csv`(`2dc8579`) = 이 순위 2,500개(R5 = 절벽 밖), `it_food.csv` 50개. 앱 「빈도 단어」를 이 기준으로 바꾸는 것은 콘텐츠 작업이 풀린 뒤.

## 14. 단어·메뉴 개편 — 2026-11-07(일본어앱 `docs/MENU_WORDS_2026-11-07.md` 구조)

- 앱을 고치면 Zealot·TestFlight 를 항상 함께 올린다(사용자 지시 2026-11-07).
- 절벽 값 한 곳 `lib/core/cliff.dart` — R5 는 2,000위에서 끊음. 2,000위 누적 **약 86.9%** 는 2,500위 88.0% 에서 2,001~2,500위 레마 몫을 뺀 추정값(수정표가 없어 정확값이 아님, 화면에 「약」 표시).
- 「절벽 단어」 `word_freq_screen.dart` — 20어 단원·네모 타일·「회화 단어 포함」. 회화 레마는 파일 없이 `DialogueService` 에서 화면이 바로 모은다. 단어장(`words`)이 비어 있으면 「아직 단어가 없습니다.」.
- 「앱 소개」 `about_screen.dart` — 레일 맨 아래 + 프로필 → 정보. 탭 「나」 → 「프로필」(`ProfileSections`). 메뉴 순서 기초 → 문법 → 회화 → 단어 → 참고, 「회화 노트」·「진행」 메뉴 뺌, 「말하기」 → 「문장 말하기」.
- 회화 문장은 `LemmaText` — 레마를 누르면 단어창, 단어장에 있는 말은 밑줄. 동사·성·수 데이터가 생기면 캡션은 `HintText` 가 그린다.
- 한글 독음 전역 토글 `KoReadingPrefs` 기본 미표시(키 `show_ko_reading_v2`), 켤 때 스낵바 한 번.

## 15. 회화 초안 — 2026-11-08

- 굴절어 전략(`~/talkverse/INFLECTED_LANG_STRATEGY.md`) 레벨 = 문법 단계 R0~R5. **Claude 초안 35편**(`assets/data/dialogues/R<레벨>/<주제>/<편id>.json`, `draft: true`), 작성 원칙 `tools/prompts/dialogue_it.md`, 이탈리아어 적용값 `docs/DIALOGUE_RULES_it.md`, 문법 요소 배치(사용자 결정) `docs/GRAMMAR_PLACEMENT_it.md`, 앱 전략 `docs/APP_STRATEGY_it.md`, 레벨 1 어휘표 `data/vocab/r1_vocab_it.csv`.
- 하위 폴더는 `pubspec.yaml` 에 없어 앱에 들어가지 않는다 — Grok 재작성·사용자 통과 뒤 연결. 읽기용 `data/review/write/dialogue_samples_it.md`, 리뷰 페이지 `tools/review_it.sh` → uk 「REVIEW_it 갱신」.
- 독음 `tools/rd_it.py`(gn=뇨·chi=끼아·bl=블), 검사기 `tools/check_dialogues.py --fix-rd`(굴절 반복·Lei·복수 경고). 턴 칸 `it·rd·ko·note·lemmas·emotion|segs`, 여성 학습자판 `it_f·rd_f·ko_f`(성별 어미는 피하지 말고 두 판).
- 감정 계획 `data/tts/plan/` 은 `tools/tts/make_plans.py` 가 회화 파일에서 만든다(손으로 고치지 않음). 새 인물 목소리는 `voices.json` 의 `cast`.
- 음성: `tools/tts/run_trial.py <작업폴더> <편id>...`(venv `~/tts_work/it/venv`). PC 는 uk 세션의 「지금 시작」 뒤에만, 끝나면 「GPU 끝」. 초안은 R2 만 올리고 D1 에 넣지 않는다.
- 여성 학습자판에서도 연애 상대는 Giulia 그대로(사용자 결정 2026-11-08). `{country}` 는 관사 문제로 전치사 뒤에 쓰지 않는다.
- Grok 재작성 요청문 `python3 tools/rewrite_request.py <편.json>...` → `data/review/grok/<편id>_prompt.md`. Grok 재개 2026-11-09 13:30(사용자 지시), 샘플 1~2편 → 사용자 통과 → 본작업.
