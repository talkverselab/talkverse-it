# 스토어 상품·차별화 — 이탈리아어 유니버스 (2026-11-09)

출시는 **Talkverse 통합 앱 하나**(com.talkverse.app)로 한다(uk 공지). 이 앱은 통합 앱 안의 이탈리아어 패키지이자, 개발·시험용 단독 앱(Zealot·TestFlight)이다. 가격 = `~/talkverse/PRICING.md`(사용자 확정 2026-11-09) 의 앱 정가 / 앱 할인가. **등록은 사용자가** App Store Connect·Google Play Console 에서 한다.

## 1. 상품

| 상품 ID | 이름(한국어 표시) | 종류 | 기간 | 앱 정가 | 스토어 판매가(할인가) |
|---|---|---|---|---|---|
| `lang_it_1m` | 이탈리아어 1개월 | 자동 갱신 구독 | 1개월 | 5,500 | **3,900** |
| `lang_it_3m` | 이탈리아어 3개월 | 자동 갱신 구독 | 3개월 | 12,900 | **9,000** |
| `lang_it_1y` | 이탈리아어 1년 | 자동 갱신 구독 | 1년 | 28,500 | **19,900** |
| `lang_it_life` | 이탈리아어 평생 이용권(서비스 운영 기간 동안) | 비소모성 | — | 69,900 | **49,000** |
| `all_1y` | 종합 패키지 1년 — 모든 언어 | 자동 갱신 구독 | 1년 | 112,900 | **79,000** |
| `all_life` | 종합 패키지 평생 — 모든 언어(서비스 운영 기간 동안) | 비소모성 | — | 469,000 | **329,000** |

- 앱 결제 시트는 정가를 취소선으로, 스토어 가격을 크게 보여 준다(`lib/main.dart`·`lib/embed.dart` 의 `Purchase.configure`, `lib/screens/paywall_screen.dart`). 앱 안에서 사이트 가격을 안내·유도하지 않는다.
- 옛 평생 상품 `com.talkverse.italianUniverse.lifetime`·`lang_it` 은 판매 중지, 앱은 복원 때 `lang_it_life` 로 인정한다.
- 약관 https://talkverse.uk/terms/ · 개인정보처리방침 https://talkverse.uk/talkverse/it/privacy/
- 통합 앱에서는 공용 결제가 스토어 스트림을 듣고 이 언어 상품을 패키지로 넘긴다(EMBED_GUIDE 5단계). `all_*` 의 등록·인정 방식은 uk 가 정한다.
- **아직 잠근 기능이 없다** — 무엇을 유료로 할지 사용자 결정 대기(굴절어 전략 A10: 무료 = 레벨 0 + 매핑표 + 코어 + 라임 + 레벨 1 묶음 1~2, 페이월 = 라임 직후).

## 2. 차별화(애플 지침 4.3 대비, `~/talkverse/STORE_DIFFERENTIATION.md`)

### 스토어 설명 첫 줄(안)
> 겹자음 하나로 뜻이 바뀌고(pala 삽 · palla 공), 관사가 전치사와 붙는 말(del·nella·sul) — 이탈리아어를 한국어 소리와 1:1 로 견주며, 자주 쓰는 순서대로 배웁니다.

### 이탈리아어 전용 학습 도구(지금 앱에 있는 것만)
1. **알파벳과 발음** — 모음 7(닫힌·열린 e·o 구별), 자음, c·g 연음(ce·ci·chi), gn·gl·sc, s·z, 겹자음 짝(pala/palla·sono/sonno 등 6쌍). 칸을 누르면 1초 뒤 예시 낱말 재생, IPA, 입 모양, 조음 위치 그림, 한국어 소리와 비교.
2. **절벽 단어** — 이탈리아에서 만든 영화·드라마 대사를 레마로 센 순위: 61단어로 55%, 91단어 60%, 211단어 70%, 661단어 80%. 20어 단원 타일, 회화에 나온 단어 포함 보기.
3. **회화 리더** — 문장 속 낱말을 누르면 기본형(동사 원형·남성 단수)으로 단어창이 열린다(활용형 → 원형 연결). 한글 독음은 기본 꺼짐.
4. **문법 강의·테스트 / 동사 활용** — 이탈리아어 문법 패턴과 예문.

### 출시 전에 채울 것(지금은 없음 — 설명에 쓰지 않는다)
- 회화 35편(굴절어 전략 레벨 0~5, 성별판·굴절 반복)은 Claude 초안 단계 — Grok 재작성·사용자 통과 뒤 앱 연결. 지금 앱 회화는 9월 초안 5편.
- 회화 음성(남녀 학습자판) 없음, 장면 컷 없음.
- 관사 결합 전치사·과거분사 일치를 보여 주는 「성·수·인칭 자막」 장치는 설계만(`docs/APP_STRATEGY_it.md`).
- 「성·수」 메뉴는 준비중 화면 — 출시 전에 채우거나 뺀다(지침 2.1).

### 실측 숫자(출시 때 다시 확인)
- 절벽: R1 61 · R2 91 · R3 211 · R4 661 레마, 2,000위 누적 약 86.9%(추정).
- 회화: 앱 5편 / 초안 35편·321턴(출시 전 숫자로 바꿀 것). 음성 줄: 0.

### 심사 메모 문단(영문, 숫자는 출시 판 기준으로 채움)
> This app is one of a family of language-specific apps by Universal Talking Lab (Talkverse). Each app is built from scratch for one target language for Korean speakers and is NOT a re-skin: the Italian app has its own alphabet & pronunciation module (7 vowels with open/closed e and o, soft c/g, gn·gl·sc, and minimal pairs of double consonants such as pala/palla), its own grammar tools (articulated prepositions, gender/number agreement, verb conjugation), [N] original conversation episodes with recorded audio written for this language, and a vocabulary list measured from an Italian conversation corpus (61 / 91 / 211 / 661 lemmas cover 55 / 60 / 70 / 80 %). Content, curriculum and UI flows differ between apps; we keep them separate because learners search for and buy one language at a time.

### 스크린샷 순서(고유 화면 먼저)
1. 알파벳과 발음 — 겹자음 묶음 격자(pala·palla) + 발음 시트(IPA·한국어 비교)
2. 회화 리더 — 낱말 탭 단어창(활용형 → 원형)
3. 절벽 단어 — 61/91/211/661 표와 20어 단원 타일
4. 문법 강의 또는 동사 활용
5. 결제 시트(정가 취소선·할인가) — 마지막. 홈·프로필로 시작하지 않는다.
