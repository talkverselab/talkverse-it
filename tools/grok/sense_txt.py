#!/usr/bin/env python3
"""언어감각 과정 외울 대화(sense_course.json 의 kind=memorize 10과) ↔ Grok 재작성용 뼈대(2026-11-22, uk 전달 사용자 지시 「막힌거 각자 판단대로 일단 완료」 — 감각 과정도 Grok 을 거침).
  python3 tools/grok/sense_txt.py export          → data/review/grok/sense_skel/<id>.txt(화자만 남기고 대사·한국어 칸 비움)
  python3 tools/grok/sense_txt.py import [id ...] data/review/grok/sense_out/<id>.md → it·ko 를 Grok 그대로, rd 는 rd_it.py
대사는 Grok 이 쓴 그대로(사용자 지시 11-18). 강조 표시 {낱말|번호} 는 이탈리아어·한국어 칸에 같은 번호로."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from rd_it import to_rd  # noqa: E402

SRC = ROOT / 'assets/data/grammar/sense_course.json'
SKEL = ROOT / 'data/review/grok/sense_skel'
OUT = ROOT / 'data/review/grok/sense_out'
MARK = re.compile(r'\{([^|}]+)\|(\d+)\}')


def lessons(d):
    for L in d['levels']:
        for s in L['lessons']:
            if s['kind'] == 'memorize':
                yield s


def export():
    SKEL.mkdir(parents=True, exist_ok=True)
    d = json.load(open(SRC, encoding='utf-8'))
    for s in lessons(d):
        marks = {}
        for x in s['sentences']:
            for w, n in MARK.findall(x['it']):
                marks.setdefault(int(n), [])
                if w.lower() not in [v.lower() for v in marks[int(n)]]:
                    marks[int(n)].append(w)
        L = [f"=== {s['id']}", f"title: {s['title']}", f"note: {s['note']}", 'footnotes: ' + ' / '.join(s.get('footnotes', [])),
             'marks: ' + ' · '.join(f"{n} = {', '.join(v)} 무리" for n, v in sorted(marks.items()))]
        L += [f"{x['who']} | ___ | ___" for x in s['sentences']]
        (SKEL / f"{s['id']}.txt").write_text('\n'.join(L) + '\n', encoding='utf-8')
    print('뼈대 →', SKEL)


def parse(text):
    m = re.search(r'```[a-z]*\n(.*?)```', text, re.S)
    rows = []
    for line in (m.group(1) if m else text).splitlines():
        c = [x.strip() for x in line.split(' | ')]
        if len(c) >= 3 and not line.startswith(('===', 'title', 'note', 'footnotes', 'marks')):
            rows.append({'who': c[0], 'it': c[1], 'ko': c[2]})
    return rows


def do_import(ids):
    d = json.load(open(SRC, encoding='utf-8'))
    done = []
    for s in lessons(d):
        p = OUT / f"{s['id']}.md"
        if (ids and s['id'] not in ids) or not p.exists():
            continue
        rows = parse(p.read_text(encoding='utf-8'))
        err = None
        if [r['who'] for r in rows] != [x['who'] for x in s['sentences']]:
            err = f'줄 수·화자 다름 {len(rows)}/{len(s["sentences"])}'
        elif any('___' in r['it'] or not r['it'] or not r['ko'] for r in rows):
            err = '빈 칸'
        elif any(sorted(set(n for _, n in MARK.findall(r['it']))) != sorted(set(n for _, n in MARK.findall(r['ko']))) for r in rows):
            err = '이탈리아어·한국어 표시 번호가 다른 줄 있음'
        if err:
            print('✗', s['id'], err)
            continue
        for x, r in zip(s['sentences'], rows):
            x['it'], x['ko'] = r['it'], r['ko']
            x['rd'] = to_rd(MARK.sub(r'\1', r['it']))
            x['grok'] = True
        done.append(s['id'])
    SRC.write_text(json.dumps(d, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    print('넣음', len(done), ' '.join(done))


if __name__ == '__main__':
    if sys.argv[1:2] == ['export']:
        export()
    elif sys.argv[1:2] == ['import']:
        do_import(set(sys.argv[2:]))
    else:
        print(__doc__)
