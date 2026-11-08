#!/usr/bin/env python3
"""편 JSON → Grok 재작성 요청문(tools/prompts/rewrite_grok.md 틀).
  python3 tools/rewrite_request.py <편.json>...   → data/review/grok/<편id>_prompt.md
레벨마다 문법 제약(굴절어 전략 A3·A4)과 한 턴 단어 수를 넣는다. 여성판(it_f)이 있는 턴은 `번호F` 줄로 함께 보여 준다."""
import json, re, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
tpl = re.search(r'```\n(.*?)```', (ROOT / 'tools/prompts/rewrite_grok.md').read_text(encoding='utf-8'), re.S).group(1)
REG = {'casual': '친구·연인·룸메이트 사이 반말(tu)', 'chat': 'WhatsApp·DM 채팅(반말·줄임말·이모지)', 'polite': '처음 보는 사이·가게·일(존댓말 Lei)', 'mixed': '관계에 따라 Lei 와 tu 가 섞임'}
LEVEL = {
    'R0': ('왕초보 첫걸음(아주 쉬운 단어, 한 턴 한 문장)', 6, '현재형 단수(io·tu·lui/lei)만, 반말만 — 복수 인칭(noi·voi·loro)·Lei 금지. 반과거는 era·eri·c\'era 정도만'),
    'R1': ('초보(관사·성·활용 골격 — 쉬운 단어, 한 턴 1~2문장)', 9, '단수 인칭(io·tu·lui/lei)만 — 복수 인칭(noi·voi·loro) 금지. 친구 사이는 반말, 가게·처음 보는 사람은 Lei. 근과거·직접목적 대명사·piacere·미래/조건 한마디는 좋다. 반과거는 era·eri·c\'era 정도만, 결합 전치사는 단수형(al·del·nel·sul)만'),
    'R2': ('초보 채팅(쉬운 단어 + 채팅 줄임말)', 9, '단수 인칭만 — 복수 인칭(noi·voi·loro) 금지. 채팅은 반말. non ce l\'ho·me lo dai? 같은 굳은 말은 좋다. 반과거는 era·eri·c\'era 정도만, 결합 전치사는 단수형만'),
    'R3': ('초중급(복수·존댓말 연습 — 새 단어는 넣지 말 것)', 10, '복수 인칭(noi·voi·loro)·명사·형용사 복수·복수 결합 전치사(ai·dei·negli)를 일부러 많이 — 초안에 없는 새 단어는 넣지 않는다'),
    'R4': ('중급(어려운 문법)', 14, '초안의 문법 포인트(접속법·조건법·가정문·반과거/근과거·결합 대명사·ne·ci·관계사)를 줄이지 말고 살릴 것'),
    'R5': ('중상급(어휘 확장)', 14, '초안의 생활 어휘(집·일·건강·날씨·여행·돈·가족 행사 등)를 살릴 것'),
}
for p in sys.argv[1:]:
    e = json.load(open(p, encoding='utf-8'))
    roles = ' / '.join(f"{k} = {'학습자(한국인 20대, 이름 {name}, 남녀 모두)' if v == '{name}' else v}" for k, v in e['speakers'].items())
    rows = []
    for t in e['turns']:
        rows.append(f"{t['num']} {t['speaker']}: {t['it']} / {t['ko']}")
        if t.get('it_f'):
            rows.append(f"{t['num']}F {t['speaker']}: {t['it_f']} / {t.get('ko_f') or t['ko']}")
    lv = LEVEL[e['region']]
    txt = (tpl.replace('{code}', f"IT-{e['id']}").replace('{roles}', roles).replace('{scene}', e['scene'])
           .replace('{register}', REG.get(e.get('register'), e.get('register', ''))).replace('{twist}', str(e.get('twist')))
           .replace('{n}', str(len(e['turns']))).replace('{level}', lv[0]).replace('{words}', str(lv[1])).replace('{grammar}', lv[2])
           .replace('{lines}', '\n'.join(rows)))
    if e.get('kind') == 'chat':
        txt = txt.replace('초안:\n', '채팅 편: 줄마다 메시지 한 개, 이모지 1~2개 정도, 읽씹 턴은 그대로 둔다.\n초안:\n')
    out = ROOT / f"data/review/grok/{e['id']}_prompt.md"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(txt, encoding='utf-8'); print(out)
