#!/usr/bin/env python3
"""이탈리아어 회화(편 JSON) 검사기. 일본어앱 검사기의 규칙을 줄여 옮긴 것(형태소 분석 대신 턴의 lemmas 를 쓴다).

  python3 tools/check_dialogues.py [--fix-rd] [파일 ...]

오류: 턴 수·메타·반전·표현 노출(≥2)·독음·lemmas. 경고: 구간 밖 단어·학습자 성별이 드러나는 말·독음 불일치.
구간 밖 판정은 저장소 밖 순위표(words/it.csv)가 있을 때만.
"""
import csv, glob, json, re, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import rd_it  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
RANK_CSV = Path.home() / 'talkverse/vi-art/talkverse_art/words/it.csv'
# 회화 레벨 = 문법 단계(굴절어 전략 A1, 2026-11-08): 0 도구획득 · 1 관사·성·활용 골격 · 2 챗 실전 · 3 그래머2 · 4 어려운 문법 · 5 어휘 완주
TURNS = {'R0': (4, 8), 'R1': (6, 8), 'R2': (6, 10), 'R3': (6, 8), 'R4': (10, 16), 'R5': (10, 16)}
CEIL = {'R0': 211, 'R1': 211, 'R2': 211, 'R3': 211, 'R4': 661, 'R5': 2000}  # 어휘 상한(절벽 R1 61위는 대화가 안 되어 레벨 0~3 은 211위)
CASUAL = {'R0'}  # 존댓말 Lei 는 R1 가게 장면부터(사용자 결정 2026-11-08, 전략 A4 와 다름)
PLURAL_OK = {'R3', 'R4', 'R5'}  # A3: 복수 인칭 어미는 레벨 3 부터
TWIST = {'chaos', 'slip', 'reveal', 'emotion', 'ignore'}
GENDERED = re.compile(r"\b(sono|sei|sembri|stai)\s+(\w+[oa])\b", re.I)
NOT_ADJ = {'una', 'la', 'lo', 'io', 'qua', 'ora', 'solo', 'quello', 'questo', 'quella', 'questa', 'proprio', 'sempre', 'ancora', 'molto', 'troppo', 'tutto', 'qui'}


def ranks():
    if not RANK_CSV.exists():
        return {}
    return {r['word']: int(r['rank']) for r in csv.DictReader(open(RANK_CSV, encoding='utf-8'))}


def check(path, rk, fix):
    ep = json.load(open(path, encoding='utf-8'))
    eid, reg, turns = ep.get('id', path), ep.get('region'), ep.get('turns', [])
    err, warn = [], []
    lo, hi = TURNS[reg]
    if not lo <= len(turns) <= hi:
        err.append(f'턴 수 {len(turns)} (허용 {lo}~{hi})')
    for k in ('island', 'kind', 'title', 'scene', 'speakers', 'register', 'expressions'):
        if not ep.get(k):
            err.append(f'메타 {k} 없음')
    if not 1 <= ep.get('twist', 0) <= len(turns):
        err.append('twist 범위 밖')
    if ep.get('twist_type') not in TWIST:
        err.append('twist_type 값')
    text = ' '.join(t['it'] for t in turns).lower()
    if sum(e.lower() in text for e in ep.get('expressions', [])) < 2:
        err.append('표현 노출 < 2')
    outside = set()
    for t in turns:
        n = t['num']
        for k in ('it', 'ko', 'note'):
            if not t.get(k):
                err.append(f'턴 {n}: {k} 없음')
        auto = rd_it.to_rd(t['it'])
        if fix and not t.get('rd_manual'):
            t['rd'] = auto
        if t.get('it_f'):
            if fix and not t.get('rd_manual'):
                t['rd_f'] = rd_it.to_rd(t['it_f'])
            if not t.get('ko_f') or not t.get('rd_f'):
                err.append(f'턴 {n}: it_f 가 있는데 rd_f·ko_f 없음')
        if reg in CASUAL and re.search(r"\b(Lei|La|Le|scusi|senta|mi dica|si accomodi|prego, si)\b", t['it'], re.I) and re.search(r'\b(scusi|può|vuole|desidera|Lei|mi dica|si accomodi|senta)\b', t['it']):
            warn.append(f'턴 {n}: 존댓말(Lei) — R0 은 반말만')
        NOT_PL = {'sono', 'telefono', 'chiamo', 'piano', 'buono', 'bisogno', 'mano', 'nuovo', 'uomo', 'tono', 'vino', 'domani', 'strano', 'lontano', 'forno', 'giorno', 'ritorno', 'nonno', 'sete', 'parete', 'estate', 'carino', 'ciao', 'pomodoro'}
        if reg in ('R0', 'R1', 'R2') and re.search(r'\b(ai|agli|dei|degli|delle|nei|negli|nelle|sui|sugli|sulle|dagli|dalle)\b', t['it']):
            warn.append(f'턴 {n}: 복수 결합 전치사 — R3 부터')
        if reg not in PLURAL_OK and any(w.lower() not in NOT_PL for w in re.findall(r'\b\w+(?:iamo|ete|ate|ite|ano|ono)\b', t['it'])):
            warn.append(f'턴 {n}: 복수 인칭 어미? — 레벨 0~2 는 단수 우선(A3)')
        if not t.get('rd'):
            err.append(f'턴 {n}: rd 없음')
        elif not t.get('rd_manual') and t['rd'] != auto:
            warn.append(f'턴 {n}: rd 불일치 {auto}')
        if not t.get('emotion') and not t.get('segs'):
            warn.append(f'턴 {n}: emotion 없음')
        if not t.get('lemmas'):
            err.append(f'턴 {n}: lemmas 없음')
        for s, b, *_ in t.get('lemmas', []):
            if s.lower() not in t['it'].lower():
                err.append(f'턴 {n}: 표면형 "{s}" 이 문장에 없음')
            if rk and rk.get(b, 10**6) > CEIL[reg]:
                outside.add(b)
        for m in GENDERED.finditer(t['it']):
            if m.group(2).lower() not in NOT_ADJ and ((t['speaker'] == 'A') == (m.group(1).lower() == 'sono')):
                warn.append(f'턴 {n}: 학습자 성별? {m.group(0)}')
    forms = {}
    for t in turns:
        for x in t.get('lemmas', []):
            forms.setdefault(x[1], set()).add(x[0].lower())
    multi = [b for b, v in forms.items() if len(v) >= 2]
    if len(multi) < 3:
        warn.append(f'굴절 반복 {len(multi)}개 < 3 (같은 기본형이 두 형태 이상으로 나오는 단어) {multi}')
    if outside:
        warn.append(f'구간 밖 단어 {len(outside)}: {sorted(outside)}')
    if fix:
        json.dump(ep, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    return eid, err, warn


def main():
    a = sys.argv[1:]
    fix = '--fix-rd' in a
    files = [p for p in a if not p.startswith('--')] or sorted(glob.glob(str(ROOT / 'assets/data/dialogues/R*/**/*.json'), recursive=True))
    rk, total = ranks(), 0
    for f in files:
        eid, err, warn = check(f, rk, fix)
        for w in warn:
            print('  warn', eid, w)
        for e in err:
            print('  ERR ', eid, e)
        total += len(err)
        print(f'{eid}: 오류 {len(err)} 경고 {len(warn)}')
    print('총 오류', total)
    sys.exit(1 if total else 0)


if __name__ == '__main__':
    main()
