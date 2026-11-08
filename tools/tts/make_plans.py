#!/usr/bin/env python3
"""회화 파일의 emotion·segs → 감정 계획 data/tts/plan/<편id>.json 자동 생성(손으로 적지 않는다).
  python3 tools/tts/make_plans.py [편id...]     없으면 회화 전부. emotion·segs 가 빠진 턴이 있으면 그 편은 만들지 않고 알린다.
턴 칸: emotion = 턴 전체 감정, segs = [[감정, 본문(, 읽기)], ...] (한 턴에서 감정이 바뀔 때), m·f = 성별판(있으면 그대로).
목소리: 화자 이름 → voices.json 의 cast. A(학습자)는 자동이라 넣지 않는다."""
import json, os, sys
import ttslib as L


def plan(ep):
    d = json.load(open(L.EP[ep], encoding='utf-8'))
    cast, errs, T = {}, [], {}
    for k, name in d['speakers'].items():
        if k == 'A':
            continue
        if name in L.V['cast']:
            cast[k] = L.V['cast'][name]
        else:
            errs.append(f'목소리 없음 {name} (voices.json cast)')
    for t in d['turns']:
        if t.get('segs'):
            row = {'segs': t['segs']}
        elif t.get('emotion'):
            row = {'segs': [[t['emotion'], t['it']]]}
        else:
            errs.append(f"턴 {t['num']} emotion 없음"); continue
        for g in 'mf':
            if t.get(g):
                row[g] = t[g]
        if t.get('it_f'):   # 성별판(A9): 여성 학습자판 본문
            row['f'] = {'text': t['it_f'], 'rd': t.get('rd_f', ''), 'ko': t.get('ko_f', ''),
                        'segs': t.get('segs_f') or [[t.get('emotion') or (t.get('segs') or [['neutral']])[0][0], t['it_f']]]}
        T[str(t['num'])] = row
    return {'ep': ep, 'cast': cast, 'turns': T}, errs


def main():
    ids = sys.argv[1:] or sorted(L.EP)
    os.makedirs(f'{L.R}/data/tts/plan', exist_ok=True)
    bad = 0
    for ep in ids:
        P, errs = plan(ep)
        if errs:
            bad += 1; print(ep, *errs[:6], sep='\n  '); continue
        json.dump(P, open(f'{L.R}/data/tts/plan/{ep}.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('계획', len(ids) - bad, '문제', bad)
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
