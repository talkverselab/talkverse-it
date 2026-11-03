#!/usr/bin/env python3
"""편 JSON 의 턴마다 `lemmas`(내용어 [표면형, 기본형, 읽기]) 를 채운다 — 문장 레마 ↔ 단어장 연결(일본어앱 2026-11-04 와 같은 구조).
이탈리아어는 읽기 칸이 없어 "" 로 둔다. 형태소 분석기 = spaCy `it_core_news_md`(없으면 `_sm`) + 아래 수정표(문장 첫머리 대문자 동사 등
작은 모델이 틀리는 것). 내용어 = NOUN·VERB·AUX·ADJ·ADV·PROPN(등장인물 이름 제외), 기본형은 소문자.
단어장(assets/data/freq/*.csv 의 word 칸 + vocab/*.json 의 tx + grammar/verbs_core.json 의 inf)에 없는 레마는
data/review/write/missing_lemmas.csv(lemma,count 빈도순) 로 — uk 세션에 넘겨 단어·그림 제작.
  <venv>/bin/python tools/add_lemmas.py        # venv 에 spacy + it_core_news_md
"""
import csv, glob, json, re, sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VAR = re.compile(r'\{[a-z_]+\}')
KEEP = {'NOUN', 'VERB', 'AUX', 'ADJ', 'ADV', 'PROPN', 'INTJ'}
# (표면형 소문자) → 기본형 — 모델이 틀리는 것만. 새 회화가 들어오면 여기에 덧붙인다.
FIX = {
    'chiamo': 'chiamare', 'abiti': 'abitare', 'prendo': 'prendere', 'offro': 'offrire', 'pago': 'pagare',
    'scusi': 'scusare', 'vai': 'andare', 'vieni': 'venire', 'scrivimi': 'scrivere', 'aperto': 'aperto',
    'preferita': 'preferito', 'stazione': 'stazione', 'termini': 'termini', 'dritto': 'dritto', 'ciao': 'ciao',
    'grazie': 'grazie', 'buonanotte': 'buonanotte',
}
SKIP = {'no', 'sì', 'si', 'e', 'a', 'o'}  # 기능어·대답말


def load_nlp():
    import spacy
    for name in ('it_core_news_md', 'it_core_news_sm'):
        try:
            return spacy.load(name)
        except OSError:
            continue
    sys.exit('spaCy 이탈리아어 모델이 없습니다: python -m spacy download it_core_news_md')


def word_list():
    db = set()
    for f in glob.glob(str(ROOT / 'assets/data/freq/*.csv')):
        with open(f, encoding='utf-8') as fo:
            for row in csv.DictReader(fo):
                w = (row.get('word') or '').strip().lower()
                if w:
                    db.add(w)
    for f in glob.glob(str(ROOT / 'assets/data/vocab/*.json')):
        j = json.load(open(f, encoding='utf-8'))
        for th in j.get('themes', []) if isinstance(j, dict) else []:
            for it in th.get('items', th.get('words', [])):
                tx = (it.get('tx') or it.get('it') or '').strip().lower()
                if tx:
                    db.add(tx)
    try:
        for v in json.load(open(ROOT / 'assets/data/grammar/verbs_core.json', encoding='utf-8')).get('verbs', []):
            if v.get('inf'):
                db.add(v['inf'].strip().lower())
    except FileNotFoundError:
        pass
    return db


def main():
    nlp = load_nlp()
    db = word_list()
    miss = Counter()
    tot = hit = turns = 0
    for f in sorted(glob.glob(str(ROOT / 'assets/data/dialogues/L*.json'))):
        d = json.load(open(f, encoding='utf-8'))
        names = {str(c.get('name', '')).lower() for c in (d.get('characters') or {}).values()} - {''}
        changed = False
        for ep in d.get('episodes') or d.get('dialogues') or []:
            for t in ep.get('turns', []):
                text = t.get('tl') or t.get('it') or t.get('es') or ''
                out = []
                for tok in nlp(VAR.sub(' ', text).lower()):
                    if tok.pos_ not in KEEP or not re.search(r'[a-zàèéìòóù]', tok.text):
                        continue
                    surf = tok.text.strip("'")
                    if not surf or surf in names or surf in SKIP:
                        continue
                    base = FIX.get(surf, tok.lemma_).lower().strip("'")
                    if not base or base in names or base in SKIP or ' ' in base:
                        continue
                    out.append([surf, base, ''])
                    tot += 1
                    if base in db:
                        hit += 1
                    else:
                        miss[base] += 1
                if t.get('lemmas') != out:
                    t['lemmas'] = out
                    changed = True
                turns += 1
        if changed:
            with open(f, 'w', encoding='utf-8') as fo:
                json.dump(d, fo, ensure_ascii=False, indent=1)
                fo.write('\n')
    out_csv = ROOT / 'data/review/write/missing_lemmas.csv'
    out_csv.parent.mkdir(parents=True, exist_ok=True)
    with open(out_csv, 'w', encoding='utf-8', newline='') as fo:
        w = csv.writer(fo)
        w.writerow(['lemma', 'count'])
        for b, n in sorted(miss.items(), key=lambda x: (-x[1], x[0])):
            w.writerow([b, n])
    print(f'턴 {turns} · 내용어 {tot} · 단어장 있음 {hit} · 없는 레마 {len(miss)} → {out_csv.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
