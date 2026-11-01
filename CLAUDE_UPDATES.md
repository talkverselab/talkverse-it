# Claude 업데이트 메모 — italian_universe (it)

> 기준 앱: chinese_universe(zh). 이식 세부 규격은 `zh/docs/PORTING_GUIDE_2026-09.md` 참고.
> 작성: 2026-09-05 (Claude Code 세션). 이후 변경은 git log 참고.

## 변경 이력
- `ba05678` (2026-09-02) 초기 앱 — es 템플릿
- `29e166a` (2026-09-04) 고유 런처 아이콘 (`È` · verde/rosso)

## 앱 생성 방식
- spanish_universe(es) 복사·치환 (`ItalianUniverseApp`, 메뉴 sub 이탈리아어, verb persons io/tu/lui·lei/noi/voi/loro). 스페인어 콘텐츠는 구조만 남기고 비움.
- 팔레트: rojo=008C45(verde) gualda=CD212A(rosso). TTS `it-IT`.

## 콘텐츠 — 주제별 단어·표현 (2026-11-02 비움)
- 처음 넣었던 주제별 단어·표현은 외부 자료에서 뽑은 것이라 2026-11-02 사용자 결정으로 앱에서 뺐다(파서도 삭제).
- `travel_words.json`·`travel_expressions.json` 은 빈 목록 — 빈도표(R1~R3) 기반 자체 제작 단어·표현으로 다시 채운다. 화면은 비어 있으면 「아직 단어가 없습니다.」.

## 포함 기능
- es와 동일: 주제별 단어 타일 / 표현 목록 / 외우기 모드(이탈리아어가림) / 외움 체크 / 독음 토글.

## 미완료 / 참고
- 회화·문법·단어 카드는 공용 키트 초안(`_update_kit/content/it.py`), 동사 데이터는 비어 있음. CI 는 `release.yml`(CLAUDE.md §2).
- DB 스키마 칼럼명 `es`, variety 기본값 `es_ES`는 식별자로 남아 있음(데이터는 `it_IT`).
