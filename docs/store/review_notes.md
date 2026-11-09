# 심사 메모(App Review Notes) · 개인정보 답 · 방침 추가 문안 — 2026-11-02

> 4.3 대비 문단·스크린샷 순서는 `docs/STORE_PRODUCTS.md` §2. 한자 앱 `docs/store/review_notes.md`·`data_safety.md` 를 이 앱에 맞게 옮김. 로그인(Talkverse ID, 선택) + 인앱 구입(평생 이용권) 이 들어간 판부터 쓴다.
> **아직 유료로 잠근 기능이 없다** — 평생 이용권은 프로필 → 계정 → 평생 이용권에서 살 수 있지만 지금은 모든 기능이 무료(무엇을 잠글지는 사용자 결정 대기). 잠금이 생기면 아래 [인앱 구입] 문안을 고칠 것.

## App Store Connect "심사 정보 → 메모"

```
[로그인] 로그인은 선택입니다. 모든 학습 기능은 로그인 없이 사용할 수 있고, 로그인은 구매 복원과 기기 간 이용권 공유에만 쓰입니다.
- 로그인 화면: 홈 → 프로필·설정 → 계정 → 로그인. Apple로 로그인 + 이메일 로그인(심사·테스트용).
- 데모 계정(이메일 로그인): review@talkverse.uk / 비밀번호: <Doppler keys/prd TALKVERSE_REVIEW_ACCOUNT 에서 복사해 여기 입력>
- 계정 삭제: 프로필·설정 → 계정 → 계정 삭제(확인 창) → 서버에서 개인정보가 삭제되고 모든 기기에서 로그아웃됩니다.
[인앱 구입] 자동 갱신 구독 lang_it_1m·lang_it_3m·lang_it_1y·all_1y, 비소모성 lang_it_life·all_life(평생 = 서비스 운영 기간 동안). 프로필·설정 → 계정 → 이용권 → 상품 선택, [구매 복원]. 결제 시트에 자동 갱신·해지 방법, 이용약관·개인정보처리방침 링크가 있습니다. Sandbox 계정으로 시험할 수 있고, 로그인 없이도 구매·복원이 됩니다.

[Sign-in] Optional. Every learning feature works without an account; sign-in is only for restoring purchases across devices.
- Where: Home → Profile & Settings → Account → Sign in (Sign in with Apple, or email sign-in for review/testing).
- Demo account (email sign-in): review@talkverse.uk / password: <paste from Doppler>
- Account deletion: Profile & Settings → Account → Delete account (confirmation) → personal data is deleted server-side and all sessions are revoked.
[IAP] Auto-renewable subscriptions lang_it_1m / lang_it_3m / lang_it_1y / all_1y and non-consumables lang_it_life / all_life ("lifetime" = for as long as the service operates). Profile & Settings → Account → Pass → choose a plan, [Restore purchases]. The sheet shows auto-renewal and cancellation terms with Terms of Use and Privacy Policy links. Works with a Sandbox account; sign-in is not required to buy or restore.
```

## App Store "앱 개인정보 보호" 답
- 데이터 수집: **예**. 수집 항목(사용자와 연결됨, 추적 아님):
  - 연락처 정보 → 이메일 주소(계정 로그인·관리) — 로그인한 사용자만
  - 연락처 정보 → 이름(로그인 제공자가 주는 이름; 선택) — 로그인한 사용자만
  - 식별자 → 사용자 ID(Talkverse 계정 ID) — 로그인한 사용자만
  - 구매 → 구매 내역(이용권 복원) — 구매한 사용자만
- 수집하지 않음: 위치·건강·금융(카드 정보는 Apple/Google 이 처리)·사용 데이터·진단·검색 기록. 추적(ATT) 없음.
- 마이크·음성 인식(말하기 연습)은 기기 안에서 판정에만 쓰고 서버로 보내지 않는다. 학습 기록·설정은 기기 안에만.

## Google Play 데이터 보안 답
- 수집: 예 — 이메일 주소·이름(계정 관리, 선택), 사용자 ID, 구매 내역. 전송 암호화 예. 사용자가 삭제 요청 가능: 예 — 앱 안 "계정 삭제" + https://talkverse.uk/account/delete
- 공유: 없음(결제 처리는 Google Play). 광고 없음.

## 개인정보처리방침에 추가할 문안 (이 앱 방침 페이지 — talkverse.uk 세션 반영)
```
계정(선택)
이탈리아어유니버스는 로그인 없이 쓸 수 있습니다. Talkverse 계정으로 로그인하면 다음을 처리합니다.
- 수집 항목: 이메일 주소, 이름(Apple·Google 등 로그인 제공자가 전달하는 범위), 계정 ID, 로그인 시각·기기 식별 토큰.
- 목적: 로그인 유지, 구매(평생 이용권) 복원과 기기 간 공유, 고객 문의 응대.
- 보관: 계정 삭제 시 즉시 삭제(구매·주문 기록은 관계 법령에 따라 회계 목적으로 사용자 ID 만 남깁니다).
- 삭제 방법: 앱 → 프로필·설정 → 계정 → 계정 삭제. 또는 talkverse.lab@gmail.com 으로 요청.
- 처리 위탁·국외 이전: 계정 서버는 Cloudflare(미국 등 글로벌 리전)에서 운영됩니다.

결제
평생 이용권 결제는 Apple App Store 또는 Google Play 가 처리하며, 앱은 카드 정보를 받지 않습니다. 앱은 구매 영수증(거래 번호·상품 ID)만 확인해 이용권을 적용합니다.
```
