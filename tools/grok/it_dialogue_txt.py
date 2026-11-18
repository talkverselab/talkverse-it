#!/usr/bin/env python3
"""회화 편 JSON ↔ Grok 재작성용 편별 글(2026-11-19, 포르투갈어앱 pt_dialogue_txt.py 를 옮김).
  python3 tools/grok/it_dialogue_txt.py export            편 전부 → data/review/grok/skel/<id>.txt(대사·한국어·note 칸을 비운 뼈대)
  python3 tools/grok/it_dialogue_txt.py import [id ...]   data/review/grok/out/<id>.md → 편 JSON 에 대사·뜻·note·감정만 바꿔 넣음
대사는 Grok 이 쓰고 그대로 넣는다(사용자 지시 11-18 — Claude 는 형식·독음·감정·레마·검사기만). 뼈대에 초안 대사를 넣지 않는다(uk 11-19: 대사째 주면 「빠른」이 베낌).
턴 줄 = `A | 이탈리아어 | 한국어 | note | emotion=x(+y…) | tags=a,b`. 감정이 둘 이상이면 // 조각마다 하나 → segs.
학습자 성별 표시 `{o|a}`(앞 = 남성판, 뒤 = 여성판) → it / it_f, 한국어도 같음. 줄 수·화자 순서가 다르면 그 편은 넣지 않고 알린다.
채팅 칸(ui·at·read)·편 id·턴 번호는 그대로 둔다(turn_lock)."""
import glob
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = sorted(glob.glob(str(ROOT / 'assets/data/dialogues/R[0-5]/*/*.json')))
SKEL = ROOT / 'data/review/grok/skel'
OUT = ROOT / 'data/review/grok/out'
EMO = set('neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle'.split())
SENT = re.compile(r'(?<=[.!?…])\s+(?=\S)')
ALT = re.compile(r'\{([^{}|]*)\|([^{}|]*)\}')  # {o|a} — {name} 같은 변수는 | 가 없어 건드리지 않음

STEP = {
    'R1': '1 관사+명사 성 · 2 essere·avere 현재 · 3 -are 동사 현재 · 4 결합 전치사 al·alla·del·della·nel · 5 근과거 avere · 6 근과거 essere(과거분사 성 일치) · 7 직접목적 대명사 lo·la·ti·mi · 8 mi piace/ti piace · 9 불규칙 동사(andare·fare·stare·venire·volere·potere·dovere·sapere·dire·uscire·bere) · 10 미래·조건 씨앗(farò·vorrei)',
    'R2': '1 첫 인사 · 2 사진 · 3 약속 · 4 늦음 · 5 사과 · 6 취소 · 7 농담 · 8 오해 · 9 화해 · 10 다음 약속',
    'R4': '1 접속법 현재 · 2 접속법 과거 · 3 조건법 과거 · 4 가정문 se+접속법 반과거+조건법 · 5 반과거 vs 근과거 · 6 대과거 · 7 결합 대명사 glielo·me lo·ce ne · 8 ne·ci · 9 재귀 근과거 · 10 관계사 cui·il quale·chi',
    'R5': '1 집 · 2 일 · 3 건강 · 4 감정 · 5 날씨·계절 · 6 여행·이동 · 7 돈 · 8 가족 행사 · 9 갈등 · 10 미래',
}
STEP['R3'] = STEP['R1'] + ' — 레벨 3 은 같은 것을 복수·Lei 로'
REG = {'casual': '반말 tu(친구·연인·룸메이트)', 'chat': '채팅 반말', 'polite': '존댓말 Lei(가게·처음 보는 사이·일)', 'mixed': 'Lei 와 tu 가 섞임'}
WHO = {'Giulia': '여, 20대 중반 로마 토박이 — 다정하지만 장난스럽게 놀림', 'Chiara': '여, 20대 초 미대생 — 수다·큰 손짓·젤라토 마니아',
       'Marco': '남, 20대 후반 동네 카페 바리스타 — 말수 적은데 한마디가 웃김', 'Luca': '남, 20대 중반 룸메이트 — 축구·스쿠터, 직진형'}
MALE = {'Marco', 'Luca', 'Nonno Bruno', 'Signor Bassi', 'Signor Ferri', 'Dottor Bruni'}


def sentences(tl):
    out = []
    for s in SENT.split(tl):
        if out and not re.search(r'[^\W\d_]', s):  # 이모지·기호만 남은 조각은 앞 문장에 붙인다
            out[-1] += ' ' + s
        elif s.strip():
            out.append(s)
    return out


def export():
    SKEL.mkdir(parents=True, exist_ok=True)
    for f in SRC:
        ep = json.load(open(f, encoding='utf-8'))
        cast = ', '.join(f"{k}: {v}({WHO.get(v) or ('남' if v in MALE else '여')})" for k, v in ep['speakers'].items() if k != 'A')
        L = [f"=== {ep['id']}", f"level: {ep['region']}", f"kind: {ep['kind']}", f"title: {ep['title']}", f"emoji: {ep['emoji']}",
             f"scene: {ep['scene']}", f"cast: A: {{name}}(학습자, 한국인 20대, 남녀 모두) / {cast}", f"register: {REG.get(ep['register'], ep['register'])}",
             f"twist: {ep['twist']} {ep['twist_type']}", f"goal: {ep['goal']}", f"expressions: {'; '.join(ep['expressions'])}"]
        if ep['region'] in STEP:
            L.append(f"steps(tags 의 step:N): {STEP[ep['region']]}")
        for t in ep['turns']:
            emo = '+'.join(s[0] for s in t['segs']) if t.get('segs') else t.get('emotion', 'neutral')
            extra = (f" | at={t['at']}" if t.get('at') else '') + (" | read=false" if t.get('read') is False else '')
            tags = list(t.get('tags', [])) + (['twist'] if t['num'] == ep['twist'] else [])
            L.append(f"{t['speaker']} | ___ | ___ | ___ | emotion={emo} | tags={','.join(tags)}{extra}")
        (SKEL / f"{ep['id']}.txt").write_text('\n'.join(L) + '\n', encoding='utf-8')
    print(f'{len(SRC)}편 → {SKEL}')


def parse(text):
    m = re.search(r'```[a-z]*\n(.*?)```', text, re.S)
    body = m.group(1) if m else text
    head, turns = {}, []
    for line in body.splitlines():
        line = line.strip()
        if not line or line.startswith('==='):
            continue
        if re.match(r'^[A-D]\s*\|', line):
            c = [x.strip() for x in re.split(r'(?<=\s)\|(?=\s)', line)]  # {o|a} 의 | 는 공백이 없어 칸 구분이 아님
            if len(c) < 5:
                raise ValueError('칸 부족: ' + line)
            kv = {}
            for x in c[4:]:
                if '=' in x:
                    k, v = x.split('=', 1)
                    kv[k.strip()] = v.strip()
            turns.append({'speaker': c[0], 'tl': c[1], 'ko': c[2], 'note': c[3], 'emo': kv.get('emotion', '')})
        elif ':' in line:
            k, v = line.split(':', 1)
            head[k.strip()] = v.strip()
    return head, turns


def pick(s, i):
    s = re.sub(r'([oaie])\{\1\|', r'{\1|', s)  # spostato{o|a} → spostat{o|a}(어미를 두 번 씀 — 형식만)
    return ALT.sub(lambda m: m.group(1 + i), s)


def segs_of(tl, emos):
    parts = [x.strip() for x in tl.split('//')]
    if len(parts) == 1 and len(emos) > 1:  # 감정 x+y 를 한 조각으로 썼다 → 문장 수가 같으면 문장 경계로, 아니면 첫 감정
        ss = sentences(parts[0])
        parts, emos = (ss, emos) if len(ss) == len(emos) else (parts, emos[:1])
    if len(emos) == 1 and len(parts) > 1:  # 감정 하나에 // 조각 여럿 → 한 조각으로 잇는다(형식만)
        parts = [' '.join(parts)]
    if len(parts) != len(emos):
        return None
    return list(zip(emos, parts))


def apply(ep, head, turns):
    old = ep['turns']
    if [t['speaker'] for t in turns] != [t['speaker'] for t in old]:
        return f"줄 수·화자 순서 다름({len(turns)}줄 / 원본 {len(old)}줄)"
    for t in turns:
        if '___' in t['tl'] or not t['tl']:
            return '빈 칸 남음'
    for k in ('title', 'scene', 'emoji'):
        if head.get(k):
            ep[k] = head[k]
    for o, t in zip(old, turns):
        emos = [e.strip() for e in t['emo'].split('+') if e.strip()]
        if not emos or any(e not in EMO for e in emos):
            return f"감정 값 이상 「{t['emo']}」"
        sg = segs_of(t['tl'], emos)
        if sg is None:
            return f"감정 {len(emos)}개 ↔ // 조각 수 다름 「{t['tl']}」"
        for k in ('it', 'it_f', 'ko', 'ko_f', 'rd', 'rd_f', 'segs', 'segs_f', 'emotion', 'rd_manual'):
            o.pop(k, None)
        gendered = bool(ALT.search(t['tl']) or ALT.search(t['ko']))
        for i, suf in ((0, ''), (1, '_f')) if gendered else ((0, ''),):
            seg = [(e, pick(x, i)) for e, x in sg]
            o['it' + suf] = ' '.join(x for _, x in seg)
            o['ko' + suf] = pick(re.sub(r'\s*//\s*', ' ', t['ko']), i)
            o['rd' + suf] = ''
            if len(seg) > 1:
                o['segs' + suf] = [[e, (' ' if k else '') + x] for k, (e, x) in enumerate(seg)]
        if len(sg) == 1:
            o['emotion'] = sg[0][0]
        elif gendered and o.get('segs_f') == [[e, s] for e, s in o['segs']]:
            o.pop('segs_f')
        if gendered and o['it_f'] == o['it']:
            for k in ('it_f', 'ko_f', 'rd_f', 'segs_f'):
                o.pop(k, None)
        o['note'] = re.sub(r'\s*//\s*', ' ', t['note'])
        o['lemmas'], o['new'] = [], []
        o['grok'] = True
    ep.pop('draft', None)
    return None


def write(f, ep):
    Path(f).write_text(json.dumps(ep, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')


def do_import(ids):
    done = []
    for f in SRC:
        ep = json.load(open(f, encoding='utf-8'))
        p = OUT / f"{ep['id']}.md"
        if (ids and ep['id'] not in ids) or not p.exists():
            continue
        try:
            head, turns = parse(p.read_text(encoding='utf-8'))
            err = apply(ep, head, turns)
        except Exception as e:  # noqa: BLE001
            err = str(e)
        if err:
            print(f"✗ {ep['id']}: {err}")
        else:
            write(f, ep)
            done.append(ep['id'])
    print(f'넣음 {len(done)}편: {" ".join(done)}')


if __name__ == '__main__':
    if sys.argv[1:2] == ['export']:
        export()
    elif sys.argv[1:2] == ['import']:
        do_import(set(sys.argv[2:]))
    else:
        print(__doc__)
