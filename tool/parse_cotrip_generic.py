# -*- coding: utf-8 -*-
"""co-Trip 여행 표현집 MD → 주제별 단어/표현 JSON (범용).
사용: py parse_cotrip_generic.py <src.md> <out_words.json> <out_expressions.json> <책이름>
- 테마: 섹션 제목 키워드 매칭 + 직전 테마 승계(carry)
- 단어/표현 분류: 제목 규칙(WORDISH) 우선, 아니면 문장부호 비율<30% AND 평균 토큰수<=3
- 아이콘: 한국어 뜻 키워드 → 이모지 (+ 섹션 내 중복 시 변형 풀)
"""
import json, re, sys

SRC, OUTW, OUTE, BOOK = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

THEME_RULES = [  # (정규식, id, 제목, 이모지) — 첫 매치 우선
 (r'맛집|레스토랑|식당|식사|디저트|타파스|카페|치즈|올리브|빠에야|파에야|테이크아웃|간식|과일|와인|음료|조리법|조미료|향토|바에서|요리|음식|먹|메뉴 단어장|젤라또|돌체|파스티체리아', 'food','맛집·음식','🍽️'),
 (r'쇼핑|패션|상점|가게 안|물건|사이즈|구두|가방|화장품|잡화|시장|슈퍼|편의점|기념품|무늬|소재', 'shopping','쇼핑','🛍️'),
 (r'뷰티|마사지|스파|미용|네일|에스테', 'beauty','뷰티·마사지','💆'),
 (r'관광|길거리를 거닐|미술|투어|문화유산|가우디|이슬람|산책|건축|극장|박물관|성당|명소', 'sightsee','관광','🏛️'),
 (r'엔터|플라멩코|축구|공연|경기|클럽|나이트|쇼|콘서트|오페라', 'enter','엔터테인먼트','🎭'),
 (r'호텔|숙소|체크인|체크아웃|룸서비스', 'hotel','호텔','🏨'),
 (r'교통|공항|기차|버스|택시|지하철|입국|출국|비행|열차|렌터카|티켓', 'transport','교통·공항','✈️'),
 (r'우체국|은행|전화|인터넷|환전|편지|소포', 'life','생활 편의','📮'),
 (r'긴급|병원|약국|도난|분실|건강|아파|트러블|경찰|사고', 'trouble','긴급·건강','🚨'),
 (r'한국 소개|한국을|한국 이야기', 'korea','한국 소개','🇰🇷'),
 (r'기본 단어|월.계절|요일|시간$|숫자', 'basicwords','기본 단어','🔢'),
 (r'대표적인 지명|지명|지역', 'places','지역·지명','🗺️'),
 (r'자주 쓰이는 문구|인사부터|편리한 문장|말해 봅시다|HOW TO|현지인에게|기본 회화|의문사|기본 문장|필수', 'basics','인사·기본 표현','👋'),
]
WORDISH = re.compile(r'LOOK|단어|단어장|지명|WORD|메뉴|사이즈|숫자|요일|계절|신체|색|무늬|재료|종류|리스트')
# 권말 ㄱㄴㄷ/A-Z 사전 부록은 테마에서 제외 (zh와 동일 정책)
DICT_SEC = re.compile(r'^단어장\s*(\(|—|:|[ㄱ-ㅎ]|Korean|Spanish|Italiano|[A-Z]\b)')
SENT_PUNCT = re.compile(r'[.!?¿¡。！？]\s*$|[?!]')

ICONS = [  # ko 키워드 → 이모지 (앞선 것 우선)
 ('커피','☕'),('홍차','🫖'),('차 ','🍵'),('맥주','🍺'),('와인','🍷'),('물','💧'),('주스','🧃'),('우유','🥛'),
 ('빵','🥖'),('치즈','🧀'),('소시지','🌭'),('햄','🥓'),('소고기','🥩'),('돼지','🍖'),('닭','🍗'),('고기','🥩'),
 ('생선','🐟'),('새우','🦐'),('게','🦀'),('오징어','🦑'),('문어','🐙'),('조개','🦪'),('달걀','🥚'),('계란','🥚'),
 ('쌀','🍚'),('밥','🍚'),('면','🍜'),('수프','🥣'),('샐러드','🥗'),('사과','🍎'),('오렌지','🍊'),('과일','🍎'),
 ('포도','🍇'),('딸기','🍓'),('레몬','🍋'),('바나나','🍌'),('토마토','🍅'),('감자','🥔'),('양파','🧅'),('마늘','🧄'),
 ('디저트','🍰'),('케이크','🍰'),('아이스크림','🍦'),('초콜릿','🍫'),('설탕','🍬'),('소금','🧂'),
 ('올리브','🫒'),('버섯','🍄'),('야채','🥬'),('채소','🥬'),('돈','💶'),('카드','💳'),('지갑','👛'),('가격','🏷️'),
 ('셔츠','👔'),('원피스','👗'),('치마','👗'),('바지','👖'),('신발','👟'),('구두','👠'),('가방','👜'),('옷','👕'),
 ('모자','🧢'),('안경','👓'),('시계','⌚'),('반지','💍'),('목걸이','📿'),('향수','🌸'),('립스틱','💄'),('화장','💄'),
 ('호텔','🏨'),('침대','🛏️'),('방 ','🛏️'),('열쇠','🔑'),('수건','🧻'),('샤워','🚿'),('욕실','🛁'),
 ('공항','✈️'),('비행기','✈️'),('기차','🚆'),('버스','🚌'),('택시','🚕'),('지하철','🚇'),('배 ','⛴️'),('자전거','🚲'),
 ('티켓','🎫'),('표 ','🎫'),('여권','🛂'),('짐','🧳'),('지도','🗺️'),('길','🛣️'),('역 ','🚉'),
 ('병원','🏥'),('약','💊'),('의사','🩺'),('경찰','🚓'),('배 아','🤢'),('열 ','🤒'),
 ('전화','📞'),('우체국','📮'),('편지','✉️'),('은행','🏦'),('인터넷','🌐'),('사진','📷'),('카메라','📷'),
 ('교회','⛪'),('성당','⛪'),('박물관','🏛️'),('미술','🖼️'),('공원','🌳'),('바다','🌊'),('산 ','⛰️'),('광장','⛲'),
 ('음악','🎵'),('춤','💃'),('축구','⚽'),('영화','🎬'),('책','📖'),('꽃','💐'),('선물','🎁'),
 ('아침','🌅'),('점심','🌞'),('저녁','🌆'),('밤','🌙'),('오늘','📅'),('내일','📅'),('어제','📅'),('시간','⏰'),
]
POOL = {'🍚':['🍚','🍛','🥘'],'🍰':['🍰','🧁','🍮','🍦'],'🥩':['🥩','🍖','🥓'],'👗':['👗','👚','🧥'],
        '📅':['📅','🗓️','📆'],'🥬':['🥬','🥦','🥒'],'🍎':['🍎','🍏','🍑','🍐'],'💄':['💄','🧴','🧼'],
        '🏛️':['🏛️','🏰','🗿'],'🎫':['🎫','🎟️'],'⛪':['⛪','🕍','🏰']}

lines = open(SRC, encoding='utf-8').read().split('\n')
# 1) 섹션 시퀀스 수집
sections = []
cur = None
for ln in lines:
    s = ln.strip()
    if s.startswith('## '):
        title = re.sub(r'^\(이어짐\)\s*', '', s[3:].strip())
        cur = {'title': title, 'words': []}
        sections.append(cur)
    elif s.startswith('|') and cur is not None:
        cells = [c.strip() for c in s.strip('|').split('|')]
        if len(cells) < 3:
            continue
        ko, tx, rd = cells[0], cells[1], cells[2]
        if ko in ('한국어','---') or set(ko) <= set('-: ') or not tx or set(tx) <= set('-: '):
            continue
        cur['words'].append({'ko': ko, 'tx': tx, 'rd': rd})

# 2) 테마 배정 (키워드 + carry)
theme_defs = {tid: (title, emoji) for _, tid, title, emoji in THEME_RULES}
order = []
themes = {}
current_tid = 'basics'
for sec in sections:
    if not sec['words'] or DICT_SEC.search(sec['title']):
        continue
    for pat, tid, _, _ in THEME_RULES:
        if re.search(pat, sec['title']):
            current_tid = tid
            break
    tid = current_tid
    if tid not in themes:
        title, emoji = theme_defs[tid]
        themes[tid] = {'id': tid, 'title': title, 'emoji': emoji, 'sections': []}
        order.append(tid)
    themes[tid]['sections'].append(sec)

# 3) 단어/표현 분류 + 아이콘
def is_word_sec(sec):
    if WORDISH.search(sec['title']):
        return True
    ws = sec['words']
    n = len(ws)
    punct = sum(1 for w in ws if SENT_PUNCT.search(w['tx']))
    avg_tok = sum(len(w['tx'].split()) for w in ws) / n
    return (punct / n) < 0.3 and avg_tok <= 3

def assign_icons(sec, fallback):
    used = set()
    for w in sec['words']:
        ic = None
        for kw, em in ICONS:
            if kw in w['ko']:
                ic = em
                break
        ic = ic or fallback
        if ic in used:
            for alt in POOL.get(ic, [ic]):
                if alt not in used:
                    ic = alt
                    break
        w['ic'] = ic
        used.add(ic)

def build(kind):
    out = []
    for tid in order:
        t = themes[tid]
        secs = []
        for s in t['sections']:
            if is_word_sec(s) != (kind == 'w'):
                continue
            copy = {'title': s['title'], 'words': [dict(w) for w in s['words']]}
            if kind == 'w':
                assign_icons(copy, t['emoji'])
            else:
                for w in copy['words']:
                    w.pop('ic', None)
            secs.append(copy)
        if secs:
            tt = dict(t)
            tt['sections'] = secs
            if kind == 'e' and tid == 'basics':
                tt['title'] = '필수 표현'
                tt['emoji'] = '💬'
            out.append(tt)
    return out

for kind, path, label in (('w', OUTW, '단어'), ('e', OUTE, '표현')):
    ths = build(kind)
    json.dump({'_meta': BOOK + ' — 주제별 ' + label, 'themes': ths},
              open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    tot = sum(len(s['words']) for t in ths for s in t['sections'])
    print('--- ' + label + ': ' + str(len(ths)) + '테마 ' + str(tot) + '항목 ---')
    for t in ths:
        n = sum(len(s['words']) for s in t['sections'])
        print('  ' + t['emoji'] + ' ' + t['title'] + ': ' + str(n))
