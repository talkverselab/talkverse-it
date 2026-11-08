# 이탈리아어 회화 초안 작성 프롬프트 (Claude 초안, 2026-11-08)

흐름: **Claude 초안(이 파일) → Grok 이 초안을 참고해 문장을 완전히 다시 씀 → 리뷰 → DB 반영**. 지금은 초안까지.
근거: `~/talkverse/INFLECTED_LANG_STRATEGY.md`(굴절어 전략, 사용자 결정 A1~A12·원칙 B1~B15), `docs/DIALOGUE_RULES_it.md`(이탈리아어 적용값), `CHARACTERS.md`(고정 인물).

## 레벨 = 문법 단계 (폴더 `assets/data/dialogues/R<레벨>/<주제>/<편id>.json`)

| 레벨 | 이름 | 어휘 상한(lemma 순위) | 말투 | 인칭 | 핵심 문장 |
|---|---|---|---|---|---|
| R0 | 도구획득 | 211 | 반말만 | 단수만 | 짧은 회화 4편 × 4~6턴 |
| R1 | 관사·성·활용 골격 | 211 | 반말 + 가게·낯선 사람은 Lei | 단수만 | 50 = 골격 10단계 × 5, 회화 7편 × 7~8턴 |
| R2 | 챗 실전 | 211 (+채팅 표현) | 반말(채팅) + 가게는 Lei | 단수만 | 50 = 챗 상황 10개 × 5, 채팅 편 7편 × 6~8턴 |
| R3 | 그래머2 | 211, **새 단어 0** | voi·loro 해금 | 복수 해금 | R1 핵심을 복수·존댓말로 갈아끼운 같은 문장 |
| R4 | 어려운 문법 | 661 | 자유 | 자유 | 50 = 문법 10항목 × 5, 4편 × 12~14턴 |
| R5 | 어휘 완주 | 2,000 | 자유 | 자유 | 50 = 주제 10개 × 5, 4편 × 12~14턴 |

순위표: `~/talkverse/vi-art/talkverse_art/words/it.csv`(rank,word…; 저장소 밖, 사람 이름 줄이 섞여 있으니 쓰지 말 것). 상한 밖 단어는 편당 1~2개까지, note 에 뜻을 적고 `new` 에 기본형.

### R1 골격 10단계 (턴 `tags` 에 `step:N`)
1 관사+명사 성·수(il/la/un/una) · 2 essere·avere 현재(단수) · 3 -are 동사 현재(단수) · 4 관사 결합 전치사(al·alla·del·della·nel) · 5 근과거 avere · 6 근과거 essere(과거분사 성 일치 → 성별판) · 7 직접목적 대명사 lo·la·ti·mi · 8 piacere(mi piace/ti piace) · 9 불규칙 동사 통문장(andare·fare·stare·dare·venire·volere·potere·dovere·sapere·dire·uscire·bere) · 10 미래·조건 씨앗(farò·vorrei).

### R4 문법 10항목 (`step:N`)
1 접속법 현재(penso che, spero che) · 2 접속법 과거(credo che sia andato) · 3 조건법 과거(avrei voluto) · 4 가정문 se + 반과거 접속법 + 조건법 · 5 반과거 vs 근과거 · 6 대과거 · 7 결합 대명사(glielo, me lo, ce ne) · 8 ne·ci · 9 재귀 근과거(mi sono svegliato/a) · 10 관계사 cui·il quale·chi.

### R5 주제 10개 (`step:N`)
집 · 일 · 건강 · 감정 · 날씨·계절 · 여행·이동 · 돈 · 가족 행사 · 갈등 · 미래.

### R2 챗 상황 10개 (`step:N`)
첫 인사 · 사진 · 약속 · 늦음 · 사과 · 취소 · 농담 · 오해 · 화해 · 다음 약속.

## 문법 요소 배치(사용자 결정 2026-11-08, `docs/GRAMMAR_PLACEMENT_it.md`)
- 반과거: R0 부터 era·eri·c'era 만 굳은 말로, 반과거 체계(반과거 vs 근과거)는 R4.
- 결합 대명사: R2 채팅에 non ce l'ho·me lo dai? 같은 몇 개만 통문장, 체계는 R4.
- 관사 결합 전치사: R1 은 단수 al·alla·del·della·nel·sul, 복수형(ai·dei·negli…)은 R3.
- 존댓말 Lei: R1 부터 가게·처음 보는 사람 장면에 허용(R0 은 반말만).

## 쓰기 원칙(B1~B12 요점)

0. **굴절에 익숙해지게(사용자 지시 2026-11-08)**: 같은 단어가 한 편 안에서 여러 인칭·성·수로 되풀이되게 쓴다 — 묻고 답하며 인칭이 바뀌는 흐름(Sei stanco? → Stanchissimo. Tu? / Ti piace? → Mi piace un sacco. A te?), 남녀 인물이 같은 형용사를 성만 바꿔 받기(pronto/pronta), 레벨 3 은 단수 ↔ 복수 맞바꾸기. 편마다 **같은 기본형이 두 가지 이상 형태로 나오는 단어 3개 이상**(검사기 경고). 어휘는 절벽 구간(많이 쓰이는 단어)을 먼저 고르되 절대 기준은 아니다 — 재미와 자연스러움이 먼저.

1. **최우선 = 이탈리아 사람이 정말 자주 쓰는 짧은 구어 표현**: 편마다 2개 이상(Dai · Boh · Ma dai · Magari · Figurati · Infatti · Tipo · Cioè · Vabbè · Ci sta · Che palle(수위 주의, flags profanity_mild) · Mamma mia · Non ci credo · Ma va · Esatto · Certo · Allora · Senti · Guarda · Ecco · Meno male · Che figata · Davvero? · Bella! · Ci vediamo · Tranquillo/a · Scherzi? · Ce la fai · Lascia stare · Fammi vedere). 편 메타 `expressions[]` 에 쓴 것을 적는다(검사기는 2개 이상 문장에 나오는지 본다).
2. 장면: SNS·DM·데이팅앱·단톡방 채팅을 많이. 채팅 편 턴은 `"ui":"bubble"`, `"at":"21:03"`, 읽씹 `"read": false`, 이모지 1~2개.
3. 톤: 편마다 외우고 싶은 한 줄, 코믹한 킥 1회, 연애는 설렘·여백(말끝 흐리기·「…」·침묵). **여성이 먼저 다가가는 편을 더 많이**. 금지: 교과서체·번역투·설명하는 대사·다짐/감사 마무리·정리된 AI 말투.
4. 반전 1회/편: `twist`(턴 번호) + `twist_type` = chaos·slip·reveal·emotion·ignore. **레벨마다 chaos 30% 이상**. 심쿵 한 줄은 연애 편마다, 다른 주제에도 자주(킥과 다른 턴).
5. 인물: A = 학습자, 이름·국적 고정 금지(`{name}`·`{city}`·`{lang}` 만; `{country}` 는 관사 문제로 전치사 뒤에 쓰지 말 것). B·C = `CHARACTERS.md` 고정 인물 Giulia(다정하지만 놀림, 로마 토박이)·Chiara(수다·손짓·젤라토)·Marco(말수 적은데 한마디가 웃김, 카페 바리스타)·Luca(룸메이트, 축구·스쿠터, 직진). R0 은 친구·연인·룸메이트만, R1 부터는 가게·낯선 사람 장면도 된다(Lei). 레벨 4·5 조연은 이름 있는 새 인물을 쓰면 편 메타 `speakers` 에 쓰고 보고할 것.
6. 수위 iOS 12+. 술·질투·가벼운 욕은 드물게 `flags[]`(alcohol·profanity_mild·jealousy·haggle·romance).
7. **성별판(A9)**: 학습자(A) 본인을 말하거나 학습자를 가리키는 성별 어미가 들어가면 그 턴에 여성판 `it_f`·`ko_f` 를 쓴다(`it` = 남성 학습자판). 피하지 말고 자연스러우면 쓴다(sono stanco/stanca, sei pronto/pronta, sono arrivato/arrivata). rd_f 는 검사기가 채운다. 감정이 다르면 `segs_f`.
8. **감정 열(B11)**: 턴마다 `emotion`(neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle). 한 턴에서 감정이 바뀌면 `emotion` 대신 `segs` = [[감정, 본문 조각], …](조각을 이으면 `it` 과 같아야 함, 네 글자 미만 조각 금지 — 짧은 첫 말은 뒷문장과 한 조각). neutral 만 쓰지 말 것.
9. 턴은 1~2문장. R1·R3 한 턴 2~9낱말(R1 1낱말 단답 금지, 채팅 제외).
10. 출처·작품명·실존 인물·브랜드 금지, 전부 자체 작문.

## 편 JSON

```json
{"id":"r1_friends_a1","region":"R1","island":"friends","kind":"short","draft":true,
 "purpose":["friends"],"domain":["friends"],"title":"한국어 제목","emoji":"☕","scene":"한국어 장면 한 줄",
 "speakers":{"A":"{name}","B":"Giulia"},"register":"casual","twist":6,"twist_type":"chaos","flags":[],
 "goal":"목표: 단계 3 -are 현재 단수 · 표현 Dai·Boh","expressions":["Dai","Boh"],
 "turns":[{"num":1,"speaker":"B","it":"Ciao! Mangi qui?","rd":"","ko":"안녕! 여기서 먹어?","note":"mangi = 너 먹다(mangiare)",
   "tags":["step:3"],"new":[],"emotion":"cheerful","lemmas":[["mangi","mangiare",""],["qui","qui",""]]}]}
```

- `lemmas` = 그 턴의 내용어 [표면형, 기본형, ""] — 표면형은 문장에 그대로 있어야 한다(대소문자 무관). 관사·전치사·접속사는 빼도 된다.
- `ko` 는 직역 말고 한국 사람이 실제로 하는 말, 말투도 같게(반말이면 반말).
- `note` = 그 턴의 핵심 하나 "X = 뜻".
- `rd` 는 비워 두고 `python3 tools/check_dialogues.py --fix-rd <파일>` 로 채운다. 변환이 틀린 곳(고유명사·외래어)은 손으로 고치고 `rd_manual: true`.
- 편 id: `r<레벨>_<주제>_<a|b|c><번호>`(a 짧은·b 긴·c 채팅). R3 은 R1 편 id 의 `r1_` 을 `r3_` 로.

## 쓴 뒤

`python3 tools/check_dialogues.py --fix-rd assets/data/dialogues/R<레벨>/*/*.json` 오류 0. 경고 중 존댓말(A4)·복수 어미(A3)는 레벨 0~2 에서 실제로 해당하면 고친다(오탐이면 둔다). 구간 밖 단어 경고는 편당 1~2개 안으로.
