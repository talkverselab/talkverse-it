#!/usr/bin/env python3
"""편 JSON → 장면 컷 그림 요청문(중국어앱 tools/scene_prompts.py 를 이탈리아어용으로). A·B 대화 한 쌍(연속 두 턴) = 컷 1장, 말풍선·글자 없음.
  python3 tools/scene_prompts.py <편.json> [--female]   → data/review/art/<편id>[_f]/cut<n>_req.md, 컷 수 출력
컷은 tools/grok_image.py 로 한 장씩(첨부 = 인물 기준 그림 chars_it_v2.jpg + 화면 톤 sian_it_01.jpg) 받아 같은 폴더 cut<n>.jpg 로 저장.
"""
import json, os, re, sys
e = json.load(open(sys.argv[1], encoding='utf-8'))
FEMALE = '--female' in sys.argv
out = f"data/review/art/{e['id']}{'_f' if FEMALE else ''}"; os.makedirs(out, exist_ok=True)
# 고정 인물 = CHARACTERS.md(2026-11-03 통과, 기준 그림 data/review/art/chars_it_v2.jpg)
CHAR = {
    'Giulia': '줄리아(Giulia, 20대 중반 로마 여성 — 갸름한 얼굴, 짙은 눈썹, 웨이브 짙은 갈색 반묶음, 테라코타 린넨 셔츠 + 크림 와이드 팬츠, 갈색 크로스백, 머리 위 선글라스)',
    'Chiara': '키아라(Chiara, 20대 초 여성 미대생 — 둥근 얼굴·주근깨, 밝은 밤색 앞머리 단발, 노란 줄무늬 티 + 데님 멜빵 원피스, 흰 스니커즈)',
    'Marco': '마르코(Marco, 20대 후반 남성 바리스타 — 짧은 흑발·짧은 수염, 소매 걷은 흰 셔츠 + 짙은 초록 앞치마, 갈색 바지)',
    'Luca': '루카(Luca, 20대 중반 남성 룸메이트, 가장 큼 — 각진 턱, 갈색 곱슬머리(옆 짧게), 하늘색 셔츠 + 네이비 재킷·슬림 치노, 갈색 로퍼)',
    'Signora Conti': '콘티 대표(50대 여성 — 은발 단발, 회색 정장 재킷, 단정한 표정)',
    'Signor Ferri': '페리 씨(50대 남성 중개인 — 대머리에 콧수염, 베이지 재킷, 서류철)',
    'Nonno Bruno': '브루노 할아버지(70대 남성 — 흰 머리, 흰 셔츠에 짙은 초록 조끼, 은퇴한 바리스타)',
    'Signora Moretti': '모레티 부인(줄리아의 어머니, 50대 — 짙은 갈색 올림머리, 와인색 원피스, 진주 귀걸이)',
    'Signor Bassi': '바시 차장(40대 남성 기차 차장 — 짙은 남색 제복·모자, 글자 없는 배지)',
    'Signora Rinaldi': '리날디 사장(40대 여성 카페 사장 — 짧은 흑발, 검은 블라우스 + 초록 앞치마)',
    'Nonna Rosa': '로사 할머니(90세 여성 — 흰 곱슬머리, 꽃무늬 원피스 + 연보라 카디건, 안경)',
}
LEARNER = '학습자(20대, 국적 중립 — 첨부 기준 그림의 {g} 학습자 그대로: 남성 = 둥근 안경·**짧고 곧은 흑발(곱슬 아님)**·올리브 그린 후드티·연청 청바지·갈색 백팩 / 여성 = 검은 단발 보브·남색 재킷·올리브 그린 티·검은 와이드 슬랙스)'
gender = '여성' if FEMALE else '남성'


def who(k):
    n = e['speakers'].get(k, k)
    return LEARNER.format(g=gender) if n == '{name}' else CHAR.get(n, f'{n}(조연 — 컷마다 같은 얼굴·옷)')


EMO = {'neutral': '담담', 'polite': '공손', 'stiff': '긴장해 굳은', 'cheerful': '밝게 웃는', 'amused': '재밌어 웃는', 'teasing': '장난스럽게 놀리는',
       'excited': '신나서 들뜬', 'surprised': '깜짝 놀란', 'shout': '버럭 외치는', 'tsukkomi': '어이없어 받아치는', 'annoyed': '짜증 난',
       'sad': '시무룩한', 'worried': '걱정스러운', 'flustered': '당황해 허둥대는', 'shy': '수줍어 얼굴 붉힌', 'gentle': '다정하고 부드러운'}


def emo(t):
    segs = (t.get('segs_f') if FEMALE and t.get('segs_f') else None) or t.get('segs')
    names = [s[0] for s in segs] if segs else [t.get('emotion', 'neutral')]
    return ' → '.join(dict.fromkeys(EMO.get(x, x) for x in names))


def line(t):
    txt = t.get('ko_f') if FEMALE and t.get('ko_f') else t['ko']
    return f"[표정: {emo(t)}] " + f"{'학습자' if e['speakers'].get(t['speaker']) == '{name}' else e['speakers'].get(t['speaker'], t['speaker'])}: 「{re.sub(r'\(.*?\)', '', txt).strip()}」"


turns = e['turns']; cuts = [turns[i:i + 2] for i in range(0, len(turns), 2)]
people = ' / '.join(who(k) for k in e['speakers'])
CHAT = ('\n**채팅 편**: 두 사람은 서로 다른 장소에 있다 — 각자 자기 자리에서 폰을 보는 모습, 화면을 세로로 반 나눠 왼쪽/오른쪽에 한 사람씩. 같은 방에 두지 말 것.'
        if e.get('kind') == 'chat' else '')
for k, pair in enumerate(cuts, 1):
    txt = f"""[IT-{e['id']}{'_f' if FEMALE else ''}-{k}] 회화 장면 컷 {k}/{len(cuts)} — 편 「{e['title']}」. 첨부 1번 = 인물 기준 그림(얼굴·머리·옷을 그대로 유지), 첨부 2번 = 앱 화면 톤(UI 는 그리지 말고 색감·질감만 참고).
스타일: 부드러운 3D 점토/펠트 인형, 둥근 얼굴, 파스텔, 이탈리아 생활 공간(로마 골목·바·셰어하우스 부엌·광장 등, **글자 없는 간판**), 밝고 따뜻한 조명(밤 장면도 가로등 불빛으로 밝게), 부드러운 그림자. 가로 16:9. 같은 편의 컷끼리 장소·옷·조명이 이어진다.
장면: {e['scene']}
등장: {people}{CHAT}
이 컷의 순간(그림에 글자로 넣지 말 것 — 표정·몸짓·소품으로): {' → '.join(line(t) for t in pair)}
[표정] 은 그 대사를 말할 때의 감정(회화 음성과 같은 감정) — 말하는 사람의 얼굴·몸짓에 그대로 드러나게. 카오스·웃음·심쿵이 표정·몸짓·소품으로 확실히 보이게(놀라 커진 눈, 당황한 손짓, 수줍은 미소와 눈 마주침).
반드시: **말풍선·글자·간판 글씨·자막·숫자·로고 없음**(대사는 앱이 얹는다 — 인물 머리 위 여백). 두 인물 모두 보이게, 말하는 사람이 조금 더 앞에. 실존 인물·브랜드 금지.
출력: 그림 1장만. 설명 없이.
"""
    open(f"{out}/cut{k}_req.md", 'w', encoding='utf-8').write(txt)
print(len(cuts))
