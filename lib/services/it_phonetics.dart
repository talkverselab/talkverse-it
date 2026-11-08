/// 이탈리아어 알파벳과 발음 — 「알파벳과 발음」 화면 데이터(일본어앱 「50음도와 발음」 구조, 2026-11-08).
///
/// 칸 하나 = 소리 단위 하나. `say` 는 TTS 가 읽을 글(낱자는 이름으로 읽혀서 예시 낱말을 붙인다).
/// 한국어 비교는 한국어 화자 기준 — 비슷한 소리와 다른 점을 한 줄씩.
class ItSound {
  final String label; // 칸에 크게 쓰는 글자(a, ci, gn …)
  final String rd; // 한글 보조 표기
  final String ipa;
  final String say; // TTS 로 읽을 글
  final String example; // 예시 낱말
  final String exampleKo;
  final String place; // 소리 나는 곳·입 모양
  final String korSim; // 한국어에서 비슷한 소리
  final String korDiff; // 다른 점
  final bool consonant; // 조음 위치 그림을 보일지
  const ItSound(this.label, this.rd, this.ipa, this.say, this.example, this.exampleKo, this.place, this.korSim, this.korDiff,
      {this.consonant = true});
}

class ItSoundGroup {
  final String name; // 칩 이름(한국어)
  final String hint; // 묶음 한 줄 설명
  final List<ItSound> sounds;
  const ItSoundGroup(this.name, this.hint, this.sounds);
}

const kItSoundGroups = <ItSoundGroup>[
  ItSoundGroup('모음 7', '쓰는 글자는 5개, 소리는 7개 — e·o 는 닫힌 소리와 열린 소리가 있다', [
    ItSound('a', '아', 'a', 'a, casa', 'casa', '집', '입을 크게 벌리고 혀를 낮게. 한국어 「아」와 거의 같다.', '아', '같다. 길게 끌지 말고 또렷하게.', consonant: false),
    ItSound('e', '에', 'e', 'e, sera', 'sera', '저녁', '닫힌 e — 입을 덜 벌리고 혀를 조금 높게.', '에', '한국어 「에」보다 살짝 좁다.', consonant: false),
    ItSound('è', '애', 'ɛ', 'è, caffè', 'caffè', '커피', '열린 e — 입을 더 벌린다. 끝 강세 è 로 자주 보인다.', '애', '한국어 「애」에 가깝다. 「에」와 「애」를 구별하면 뜻이 갈리기도 한다(è = ~이다).', consonant: false),
    ItSound('i', '이', 'i', 'i, vino', 'vino', '와인', '입술을 옆으로, 혀를 높게.', '이', '같다.', consonant: false),
    ItSound('o', '오', 'o', 'o, sole', 'sole', '해', '닫힌 o — 입술을 동그랗게 모은다.', '오', '같다.', consonant: false),
    ItSound('ò', '어(오)', 'ɔ', 'ò, però', 'però', '하지만', '열린 o — 입을 더 벌린 「오」.', '오와 어 사이', '한국어 「오」보다 입이 크게 열린다. 「어」로 들릴 만큼 벌리지는 않는다.', consonant: false),
    ItSound('u', '우', 'u', 'u, luna', 'luna', '달', '입술을 동그랗게 앞으로 내민다.', '우', '같다. 「으」로 흐리지 않는다.', consonant: false),
  ]),
  ItSoundGroup('자음', '대부분 글자대로 읽는다 — 된소리처럼 힘을 주지 않고 숨도 세게 내지 않는다', [
    ItSound('b', 'ㅂ', 'b', 'bene', 'bene', '좋아', '두 입술. 목청이 울리는 소리.', 'ㅂ(모음 사이)', '첫소리에서도 목청을 울린다 — 「뻬」가 아니라 부드러운 「베」.'),
    ItSound('d', 'ㄷ', 'd', 'dove', 'dove', '어디', '혀끝을 윗니 뒤에.', 'ㄷ(모음 사이)', '첫소리도 목청을 울린다.'),
    ItSound('f', 'ㅍ(f)', 'f', 'fame', 'fame', '배고픔', '윗니를 아랫입술에 대고 바람.', '없음', '한국어 ㅍ 과 다르다 — 입술이 닿지 않고 이와 입술 사이로 바람.'),
    ItSound('h', '(소리 없음)', '∅', 'ho, hai', 'ho', '나는 가지고 있다', '소리 없음 — ch·gh 에서 c·g 를 단단하게 만드는 표시.', '없음', 'h 는 읽지 않는다. ho = 「오」.'),
    ItSound('l', 'ㄹ(l)', 'l', 'luna', 'luna', '달', '혀끝을 윗잇몸에 대고 옆으로 소리.', '「알라」의 ㄹㄹ', '첫소리에서도 혀를 붙인다 — 「루나」보다 「(을)루나」.'),
    ItSound('m', 'ㅁ', 'm', 'mamma', 'mamma', '엄마', '두 입술을 닫고 코로.', 'ㅁ', '같다.'),
    ItSound('n', 'ㄴ', 'n', 'notte', 'notte', '밤', '혀끝을 윗잇몸에, 코로.', 'ㄴ', '같다.'),
    ItSound('p', 'ㅃ', 'p', 'pane', 'pane', '빵', '두 입술. 숨을 세게 내지 않는다.', 'ㅃ', '「파네」처럼 숨을 내뿜지 않는다 — 「빠네」에 가깝다.'),
    ItSound('q', 'ㄲ(+u)', 'kw', 'quando', 'quando', '언제', '늘 qu 로 쓰고 「꽈·꿰·뀌」로 읽는다.', '꽈·꿰', 'ㅋ 처럼 숨을 내지 않는다.'),
    ItSound('r', 'ㄹ(굴림)', 'r', 'Roma', 'Roma', '로마', '혀끝을 윗잇몸에서 떨게 한다(굴림). 모음 사이에선 한 번 튕긴다.', '「다리」의 ㄹ(한 번 튕김)', '첫소리·겹 rr 은 혀를 여러 번 떤다. 한국어 ㄹ 보다 또렷하다.'),
    ItSound('t', 'ㄸ', 't', 'tutto', 'tutto', '전부', '혀끝을 윗니 뒤에. 숨을 세게 내지 않는다.', 'ㄸ', '「투또」가 아니라 「뚜또」.'),
    ItSound('v', 'ㅂ(v)', 'v', 'vino', 'vino', '와인', '윗니를 아랫입술에 대고 목청을 울린다.', '없음', '한국어 ㅂ 과 다르다 — 입술을 붙이지 않는다.'),
  ]),
  ItSoundGroup('c·g 연음', 'c·g 는 e·i 앞에서 부드러워진다 — h 를 넣으면 다시 단단', [
    ItSound('ca co cu', '까 꼬 꾸', 'ka ko ku', 'casa, come, cuore', 'casa', '집', '혀 뒤쪽을 입천장 뒤에 붙였다 뗀다.', 'ㄲ', '숨을 내지 않는 ㄲ.'),
    ItSound('ce ci', '체 치', 'tʃe tʃi', 'cena, ciao', 'cena', '저녁 식사', '혀 앞쪽을 입천장에 대고 「ㅊ」.', 'ㅊ', '한국어 ㅊ 보다 입술을 조금 내민다.'),
    ItSound('cia cio ciu', '챠 쵸 츄', 'tʃa tʃo tʃu', 'ciao, cioccolato', 'ciao', '안녕', 'i 는 소리 내지 않고 ㅊ 을 a·o·u 와 붙이는 표시.', '챠·쵸', '「치아오」가 아니라 「챠오」.'),
    ItSound('che chi', '께 끼', 'ke ki', 'che, chi', 'chi', '누구', 'h 가 있으면 다시 단단한 ㄲ.', '께·끼', '「체·치」로 읽지 않는다.'),
    ItSound('ga go gu', '가 고 구', 'ɡa ɡo ɡu', 'gatto, gusto', 'gatto', '고양이', '혀 뒤쪽, 목청을 울린다.', 'ㄱ(모음 사이)', '첫소리도 목청을 울린다.'),
    ItSound('ge gi', '제 지', 'dʒe dʒi', 'gelato, giro', 'gelato', '젤라토', '혀 앞쪽을 입천장에 대고 목청을 울린다.', 'ㅈ', '한국어 ㅈ 보다 울림이 크다.'),
    ItSound('gia gio giu', '쟈 조 주', 'dʒa dʒo dʒu', 'già, giorno', 'giorno', '날', 'i 는 소리 내지 않는다.', '쟈·조', '「지오르노」가 아니라 「조르노」.'),
    ItSound('ghe ghi', '게 기', 'ɡe ɡi', 'spaghetti', 'spaghetti', '스파게티', 'h 가 있으면 다시 단단한 g.', '게·기', '「제·지」로 읽지 않는다.'),
  ]),
  ItSoundGroup('gn · gl · sc', '두세 글자가 한 소리', [
    ItSound('gn', '냐 녜 니 뇨 뉴', 'ɲ', 'bagno, signore', 'bagno', '욕실', '혀 가운데를 입천장에 넓게 붙이고 코로.', '「냐·뇨」의 ㄴ', '앞 모음에 ㄴ 받침을 따로 넣지 않는다 — 「반뇨」보다 「바뇨」(살짝 길게).'),
    ItSound('gli', '리', 'ʎ', 'figlio, famiglia', 'figlio', '아들', '혀 가운데를 입천장에 넓게 붙이고 옆으로 「ㄹ」.', '「달리아」의 ㄹㄹ', 'g 는 읽지 않는다. 「글리」가 아니다.'),
    ItSound('sca sco scu', '스까 스꼬 스꾸', 'ska sko sku', 'scusa, scuola', 'scusa', '미안', 's 뒤에 단단한 ㄲ.', '스+ㄲ', '「스」의 「으」를 짧게.'),
    ItSound('sce sci', '셰 시', 'ʃe ʃi', 'pesce, scienza', 'pesce', '생선', '입술을 내밀고 「쉬」 하는 소리.', '「쉬」의 ㅅ', '「스체」가 아니라 「셰」.'),
    ItSound('scia scio sciu', '샤 쇼 슈', 'ʃa ʃo ʃu', 'lascia, sciopero', 'lascia', '놔둬', 'i 는 소리 내지 않는다.', '샤·쇼', '「스치아」가 아니라 「샤」.'),
    ItSound('schi sche', '스끼 스께', 'ski ske', 'schifo, scherzo', 'scherzo', '농담', 'h 가 있으면 다시 단단한 ㄲ.', '스끼', '「셰」로 읽지 않는다.'),
  ]),
  ItSoundGroup('s · z', 's 는 맑게·흐리게, z 는 「ㅉ」 또는 「ㅈ」', [
    ItSound('s', 'ㅆ', 's', 'sole, sera', 'sole', '해', '첫소리·자음 앞에선 맑은 「ㅆ」.', 'ㅆ', '「소레」가 아니라 「쏠레」.'),
    ItSound('s (모음 사이)', 'ㅈ(z)', 'z', 'casa, rosa', 'rosa', '장미', '모음 사이에서는 흔히 울리는 [z](북부 발음).', '없음', '한국어에 없는 울리는 ㅅ — 「ㅈ」로 적지만 혀가 닿지 않는다.'),
    ItSound('z', 'ㅉ', 'ts', 'pizza, grazie', 'pizza', '피자', '혀끝을 윗니 뒤에 대고 「ㅉ」.', 'ㅉ', '「피자」가 아니라 「삐짜」.'),
    ItSound('z (울림)', 'ㅈ(dz)', 'dz', 'zero, zaino', 'zero', '영(0)', '「ㅉ」를 목청을 울려서.', 'ㅈ', '낱말마다 정해져 있다 — 들으며 익힌다.'),
  ]),
  ItSoundGroup('겹자음', '같은 자음 두 개 = 조금 멈췄다가 길게. 뜻이 바뀐다', [
    ItSound('pala · palla', '빨라 · 빨ㄹ라', 'pala · palla', 'pala, palla', 'palla', '공', 'l 을 길게 끈다.', '「알라」의 ㄹㄹ', '한 개면 삽(pala), 두 개면 공(palla).'),
    ItSound('fato · fatto', '파또 · 팟또', 'fato · fatto', 'fato, fatto', 'fatto', '했다', 't 앞에서 잠깐 멈춘다(받침 ㅅ 느낌).', '「팟또」의 받침', '한 개면 운명(fato), 두 개면 했다(fatto).'),
    ItSound('caro · carro', '까로 · 까ㄹ로', 'caro · carro', 'caro, carro', 'carro', '수레', 'rr 은 혀를 여러 번 떤다.', '없음', '한 개면 비싼·소중한(caro), 두 개면 수레(carro).'),
    ItSound('sono · sonno', '쏘노 · 쏜노', 'sono · sonno', 'sono, sonno', 'sonno', '졸음', 'n 을 길게.', '「쏜노」의 받침 ㄴ', '한 개면 ~이다(sono), 두 개면 졸음(sonno).'),
    ItSound('papa · pappa', '빠빠 · 빱빠', 'papa · pappa', 'papa, pappa', 'pappa', '죽(아기 밥)', 'p 앞에서 멈춘다.', '「빱빠」의 받침', '한 개면 교황(papa), 두 개면 아기 밥(pappa).'),
    ItSound('nono · nonno', '노노 · 논노', 'nono · nonno', 'nono, nonno', 'nonno', '할아버지', 'n 을 길게.', '받침 ㄴ', '한 개면 아홉 번째(nono), 두 개면 할아버지(nonno).'),
  ]),
];

/// 낱말을 넣으면 그 소리의 칸을 찾는다(테스트·회화 연결용).
ItSound? itSoundOf(String label) {
  for (final g in kItSoundGroups) {
    for (final s in g.sounds) {
      if (s.label == label) return s;
    }
  }
  return null;
}
