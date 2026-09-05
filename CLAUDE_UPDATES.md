# Claude 업데이트 메모 — italian_universe (it)

> 기준 앱: chinese_universe(zh). 이식 세부 규격은 `zh/docs/PORTING_GUIDE_2026-09.md` 참고.
> 작성: 2026-09-05 (Claude Code 세션). 이후 변경은 git log 참고.

## 변경 이력
- `ba05678` (2026-09-02) 초기 앱 — es 템플릿 + co-Trip 여행 이탈리아어
- `29e166a` (2026-09-04) 고유 런처 아이콘 (`È` · verde/rosso)

## 앱 생성 방식
- spanish_universe(es) 복사·치환 (`ItalianUniverseApp`, 메뉴 sub 이탈리아어, verb persons io/tu/lui·lei/noi/voi/loro). 스페인어 콘텐츠는 구조만 남기고 비움.
- 팔레트: rojo=008C45(verde) gualda=CD212A(rosso). TTS `it-IT`.

## 콘텐츠 — co-Trip 여행 이탈리아어
- 원본 `OneDrive\전자책\01.06_로망스어계열(그리스어포함)\01.06.04.이탈리아어\co-Trip 여행 이탈리아어.md`
- `tool/parse_cotrip_generic.py` → `travel_words.json`(11테마 1,269) · `travel_expressions.json`(11테마 842).
- 파서 보강: DICT_SEC에 `:`·`Italiano` 추가(권말 사전 `단어장: ㄴ` 형식), food 규칙에 `메뉴 단어장|젤라또|돌체|파스티체리아`.

## 포함 기능
- es와 동일: 주제별 단어 타일 / 표현 목록 / 외우기 모드(이탈리아어가림) / 외움 체크 / 독음 토글.

## 미완료 / 참고
- 회화·동사 데이터 비어 있음. CI 없음.
- DB 스키마 칼럼명 `es`, variety 기본값 `es_ES`는 식별자로 남아 있음(데이터는 `it_IT`).
- 지역·지명 테마 3항목뿐(원서 분량 적음).
