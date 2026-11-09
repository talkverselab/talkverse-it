import '../core/embed_env.dart';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import '../core/prefs.dart';

import 'art_service.dart';
import 'learner_prefs.dart';

/// 회화 리더(일본어앱 시안 02 「만화책 읽기형」)용 회화 모델 — 2026-11-03, 일본어앱 `dialogue_service.dart` 를 옮김.
///
/// 지금 데이터는 옛 `assets/data/dialogues/L1.json`(5편 × 8턴, DB `turns` 시드와 같은 파일) 하나뿐이라 그것을 그대로 읽어 이 모양으로 바꾼다.
/// 회화 콘텐츠는 바꾸지 않는다(회화 작성은 사용자 지시가 있을 때만) — 새 구조(R0~R4·주제별 편 파일)는 회화 작업이 풀리면.
/// 칸: tl = 이탈리아어(옛 칸 이름 `es`), gloss = 없음(빈 값), rd = 한글 독음, ko = 한국어, note = 한 줄 설명.
/// 문장 내용어 한 개: 표면형(문장 속)·기본형(사전형)·읽기(이탈리아어는 빈 값) — `tools/add_lemmas.py` 가 채운다(2026-11-04).
class Lemma {
  final String surface, base, reading;
  const Lemma(this.surface, this.base, this.reading);
}

class DialogueTurn {
  final int num;
  final String speaker; // A·B
  final String tl;
  final String gloss;
  final String rd;
  final String ko;
  final String note;
  final List<String> tags;
  final String? art; // 장면 그림 URL(나중에 채움)
  final List<Lemma> lemmas; // 문장 내용어(표면형·기본형·읽기) — 단어장 연결(2026-11-04)
  const DialogueTurn({
    required this.num,
    required this.speaker,
    required this.tl,
    required this.gloss,
    required this.rd,
    required this.ko,
    required this.note,
    required this.tags,
    this.art,
    this.lemmas = const [],
  });

  factory DialogueTurn.fromL1(Map<String, dynamic> j) => DialogueTurn(
        num: j['num'] as int? ?? 0,
        speaker: j['speaker'] as String? ?? 'A',
        tl: (j['tl'] ?? j['it'] ?? j['es']) as String? ?? '',
        gloss: j['gloss'] as String? ?? '',
        rd: j['rd'] as String? ?? '',
        ko: j['ko'] as String? ?? '',
        note: j['note'] as String? ?? '',
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        art: j['art'] as String?,
        lemmas: [for (final l in (j['lemmas'] as List? ?? const [])) if (l is List && l.length >= 2) Lemma('${l[0]}', '${l[1]}', l.length > 2 ? '${l[2]}' : '')],
      );

  /// 그림 조회용 핵심 단어 후보 — 옛 L1 에는 단어 표시가 없어 비어 있다(문장 낱말 맞추기 `ArtService.urlInText` 가 대신).
  List<String> get pictureWords => const [];

  /// 문장의 낱말(소문자) — 동사 표·성·수 점 같은 낱말 단위 칸이 쓴다.
  Set<String> get words => ArtService.wordsOf(tl);
}

class Dialogue {
  final String id;
  final String region; // 지금은 옛 레벨 이름(L1) 그대로 — R 재태그는 회화 작업 때
  final String island; // 주제
  final String title;
  final String emoji;
  final String scene;
  final Map<String, String> speakers;
  final Map<String, String> genders;
  final List<String> expressions;
  final List<DialogueTurn> turns;
  final String? art;
  const Dialogue({
    required this.id,
    required this.region,
    required this.island,
    required this.title,
    required this.emoji,
    required this.scene,
    required this.speakers,
    required this.genders,
    required this.expressions,
    required this.turns,
    this.art,
  });

  /// 화자 A = 학습자(옛 이야기의 한국인 화자). 표시 이름은 프로필 이름, 없으면 「나」.
  static const learner = 'A';

  /// 화자 표시 이름. A(학습자)·`{name}` 자리는 학습자 이름(없으면 「나」).
  String speakerName(String sp) {
    final raw = speakers[sp] ?? sp;
    if (sp == learner || raw.contains('{name}')) {
      return LearnerPrefs.name.value.isNotEmpty ? LearnerPrefs.name.value : '나';
    }
    return raw.replaceAll(RegExp(r'[{}]'), '');
  }

  /// 목소리 성별 — A(학습자)는 프로필 성별, 그 밖의 화자(B Giulia 여)는 데이터의 성별.
  String voiceGender(String sp) => sp == learner ? LearnerPrefs.gender.value : (genders[sp] ?? LearnerPrefs.voiceGender(sp));
}

class DialogueService {
  DialogueService._();
  static final DialogueService instance = DialogueService._();

  static const islands = ['survival', 'friends', 'love', 'life', 'travel', 'culture', 'work', 'study'];
  static const islandKo = {
    'survival': '서바이벌',
    'friends': '친구',
    'love': '사랑',
    'life': '생활',
    'travel': '여행',
    'culture': '문화',
    'work': '직장',
    'study': '학업',
  };
  static const islandEmoji = {
    'survival': '🆘',
    'friends': '🤝',
    'love': '💘',
    'life': '🏠',
    'travel': '✈️',
    'culture': '🎬',
    'work': '💼',
    'study': '🎓',
  };
  static const levelKo = {'L1': '이야기', 'R0': '왕초보', 'R1': '초보', 'R2': '중급', 'R3': '고급', 'R4': '최상급'};
  static const _prefLast = 'dialogue_last';

  final List<Dialogue> _all = [];
  String? _lastOpened;
  String? get lastOpenedId => _lastOpened;
  Future<void> setLastOpened(String id) async {
    _lastOpened = id;
    (await Prefs.getInstance()).setString(_prefLast, id);
  }

  /// 여러 화면이 동시에 불러도 한 번만 읽는다(넓은 화면에서 홈·회화 홈이 함께 떠 편이 두 번 채워지던 문제).
  Future<void> ensureLoaded() => _loading ??= _load();
  Future<void>? _loading;

  Future<void> _load() async {
    _lastOpened = (await Prefs.getInstance()).getString(_prefLast);
    for (final file in const ['L1', 'L2', 'L3']) {
      try {
        final j = json.decode(await rootBundle.loadString(assetPath('assets/data/dialogues/$file.json'))) as Map<String, dynamic>;
        final chars = (j['characters'] as Map<String, dynamic>? ?? const {});
        final names = chars.map((k, v) => MapEntry(k, ((v as Map)['name'] ?? k).toString()));
        final genders = chars.map((k, v) => MapEntry(k, ((v as Map)['gender'] ?? 'female').toString()));
        final level = j['level'] as String? ?? file;
        for (final e in ((j['episodes'] ?? j['dialogues']) as List? ?? const [])) {
          final m = e as Map<String, dynamic>;
          final turns = ((m['turns'] as List?) ?? const []).map((t) => DialogueTurn.fromL1(t as Map<String, dynamic>)).toList();
          if (turns.isEmpty) continue;
          _all.add(Dialogue(
            id: '${level}_${m['id']}',
            region: level,
            island: 'love', // 옛 L1 = 언어교환 앱에서 시작하는 두 사람 이야기(원칙: 기존 연애 서사는 love 주제)
            title: m['title'] as String? ?? m['id'] as String,
            emoji: m['emoji'] as String? ?? '💬',
            scene: m['scenario'] as String? ?? '',
            speakers: names,
            genders: genders,
            expressions: const [],
            turns: turns,
          ));
        }
      } catch (_) {
        // 그 레벨 파일이 없으면 건너뛴다(지금은 L1 만 있다)
      }
    }
  }

  Dialogue? byId(String id) => _all.where((d) => d.id == id).firstOrNull;
  List<Dialogue> get all => List.unmodifiable(_all);
  List<String> get regions => _all.map((d) => d.region).toSet().toList();

  List<Dialogue> list({String? region, String? island}) =>
      _all.where((d) => (region == null || d.region == region) && (island == null || d.island == island)).toList();

  List<String> islandsOf(String region) {
    final has = _all.where((d) => d.region == region).map((d) => d.island).toSet();
    return islands.where(has.contains).toList();
  }

  int count(String region) => _all.where((d) => d.region == region).length;
}
