#!/usr/bin/env python3
"""Grok 장면 컷 — 프롬프트 최소화판(사용자 지시 2026-11-09 "프롬프터 최소화, 그록이 알아서 통일성").
규칙·인물은 data/review/art/scene_rules_it.md 한 파일, 편마다 컷 목록 data/review/art/<편id>/scenes.md 한 파일.
방(편)마다 첫 메시지에 두 파일 + 인물 기준 그림 + 화면 톤을 첨부하고 「cut1」, 그다음은 「cut2」 처럼 한 줄만 보낸다(tools/scene_run.sh).
  python3 tools/scene_doc.py <편.json> [--female]
"""
import json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import scene_prompts as P  # noqa: E402  (CHAR·EMO·LEARNER 재사용 — import 시 요청문도 다시 쓴다)

e, FEMALE = P.e, P.FEMALE
rules = 'data/review/art/scene_rules_it.md'
if not os.path.exists(rules):
    open(rules, 'w', encoding='utf-8').write("""# 이탈리아어 회화 장면 컷 규칙 (한 번만 읽고 모든 컷에 적용)
- 첨부 그림 1 = 인물 기준 그림(얼굴·머리·옷을 그대로). 첨부 그림 2 = 앱 화면 톤(UI 는 그리지 말고 색감·질감만).
- 스타일: 부드러운 3D 점토/펠트 인형, 둥근 얼굴, 파스텔, 이탈리아 생활 공간(로마 골목·바·셰어하우스·광장, 글자 없는 간판), 밝고 따뜻한 조명, 가로 16:9.
- 같은 편의 컷끼리 장소·옷·조명이 이어진다. 그림이 처음과 달라지면 이 방의 첫 그림을 기준으로 맞춘다.
- [표정] = 그 대사를 말할 때의 감정(회화 음성과 같은 감정) — 말하는 사람의 얼굴·몸짓에 그대로. 카오스·웃음·심쿵이 표정·몸짓·소품으로 보이게.
- 반드시: 말풍선·글자·간판 글씨·자막·숫자·로고 없음(대사는 앱이 얹는다 — 머리 위 여백). 두 인물 모두 보이게, 말하는 사람이 조금 앞에. 실존 인물·브랜드 금지.
- 「cutN」 한 줄을 받으면 컷 목록 파일의 그 컷을 그림 1장으로만 답한다. 설명 없이.
""")
lines = [f"# 컷 목록 — {e['id']}{'_f' if FEMALE else ''} 「{e['title']}」", '', f"장면: {e['scene']}", f"등장: {P.people}{P.CHAT}", '']
for k, pair in enumerate(P.cuts, 1):
    lines.append(f"cut{k}: " + ' → '.join(P.line(t) for t in pair))
out = f"data/review/art/{e['id']}{'_f' if FEMALE else ''}/scenes.md"
open(out, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
print(out, len(P.cuts))
