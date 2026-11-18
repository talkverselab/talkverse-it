import '../core/embed_env.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import '../core/prefs.dart';

import 'art_service.dart';
import 'learner_prefs.dart';
import 'script_sync.dart';

/// 회화(R0~R5, 주제별 JSON) 로더 — 2026-11-18 일본어앱 `dialogue_service.dart`(빌드 113·114) 구조로 바꿈.
///
/// 파일: `assets/data/dialogues/R<레벨>/<주제>/<편id>.json`(작성 원칙 `tools/prompts/dialogue_it.md`).
/// 각 파일은 서버에 더 새 판이 있으면 그것을 읽는다([ScriptSync], 규격 = 일본어앱 `docs/CONTENT_SYNC.md` §6).
/// 칸: `it`(이탈리아어)·`rd`(한글 독음)·`ko`·`note`·`lemmas`·`emotion`, 여성 학습자판 `it_f`·`rd_f`·`ko_f`(있으면 학습자 성별로 고름).
/// 옛 `L1.json`(5편)은 DB `turns` 시드로만 남고 회화 리더에는 나오지 않는다.
/// 문장 내용어 한 개: 표면형(문장 속)·기본형(사전형)·읽기(이탈리아어는 빈 값).
class Lemma {
  final String surface, base, reading;
  const Lemma(this.surface, this.base, this.reading);
}

class DialogueTurn {
  final int num;
  final String speaker; // A(학습자)·B·C·D
  final String tlM, rdM, koM; // 남성 학습자판(기본)
  final String tlF, rdF, koF; // 여성 학습자판(없으면 빈 값 → 기본판)
  final String gloss;
  final String note;
  final String emotion;
  final List<String> tags;
  final List<String> newWords;
  final String? art; // 장면 그림 URL(나중에 채움)
  final List<Lemma> lemmas; // 문장 내용어(표면형·기본형·읽기) — 단어장 연결(2026-11-04)
  const DialogueTurn({
    required this.num,
    required this.speaker,
    required String tl,
    required this.gloss,
    required String rd,
    required String ko,
    required this.note,
    required this.tags,
    this.tlF = '',
    this.rdF = '',
    this.koF = '',
    this.emotion = '',
    this.newWords = const [],
    this.art,
    this.lemmas = const [],
  })  : tlM = tl,
        rdM = rd,
        koM = ko;

  factory DialogueTurn.fromJson(Map<String, dynamic> j) => DialogueTurn(
        num: j['num'] as int? ?? 0,
        speaker: j['speaker'] as String? ?? 'A',
        tl: (j['it'] ?? j['tl'] ?? j['es']) as String? ?? '',
        tlF: j['it_f'] as String? ?? '',
        gloss: j['gloss'] as String? ?? '',
        rd: j['rd'] as String? ?? '',
        rdF: j['rd_f'] as String? ?? '',
        ko: j['ko'] as String? ?? '',
        koF: j['ko_f'] as String? ?? '',
        note: j['note'] as String? ?? '',
        emotion: j['emotion'] as String? ?? '',
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        newWords: (j['new'] as List?)?.cast<String>() ?? const [],
        art: j['art'] as String?,
        lemmas: [for (final l in (j['lemmas'] as List? ?? const [])) if (l is List && l.length >= 2) Lemma('${l[0]}', '${l[1]}', l.length > 2 ? '${l[2]}' : '')],
      );

  bool get _f => LearnerPrefs.isFemale && tlF.isNotEmpty;

  /// 화면·음성에 쓰는 본문 — 학습자가 여성이고 여성판이 있으면 그것.
  String get tl => _f ? tlF : tlM;
  String get rd => _f && rdF.isNotEmpty ? rdF : rdM;
  String get ko => _f && koF.isNotEmpty ? koF : koM;

  /// 그림 조회용 핵심 단어 후보: new 칸 → 없음(문장 낱말 맞추기 `ArtService.urlInText` 가 대신).
  List<String> get pictureWords => newWords;

  /// 문장의 낱말(소문자) — 동사 표·성·수 점 같은 낱말 단위 칸이 쓴다.
  Set<String> get words => ArtService.wordsOf(tl);
}

class Dialogue {
  final String id;
  final String region; // R0..R5
  final String island; // 주제
  final String kind;
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
    this.kind = 'short',
    required this.title,
    required this.emoji,
    required this.scene,
    required this.speakers,
    required this.genders,
    required this.expressions,
    required this.turns,
    this.art,
  });

  /// 남자 인물(목소리 성별) — 고정 인물 `CHARACTERS.md`. 그 밖은 여자.
  static const _male = {'Marco', 'Luca', 'Nonno Bruno', 'Signor Bassi', 'Signor Ferri', 'Dottor Bruni'};

  factory Dialogue.fromJson(Map<String, dynamic> j) {
    final speakers = ((j['speakers'] as Map?) ?? const {}).map((k, v) => MapEntry(k.toString(), v.toString()));
    return Dialogue(
      id: j['id'] as String,
      region: j['region'] as String? ?? 'R1',
      island: j['island'] as String? ?? '',
      kind: j['kind'] as String? ?? 'short',
      title: j['title'] as String? ?? '',
      emoji: j['emoji'] as String? ?? '💬',
      scene: j['scene'] as String? ?? '',
      speakers: speakers,
      genders: {for (final e in speakers.entries) if (e.key != learner) e.key: _male.contains(e.value) ? 'male' : 'female'},
      expressions: (j['expressions'] as List?)?.cast<String>() ?? const [],
      turns: ((j['turns'] as List?) ?? const []).map((t) => DialogueTurn.fromJson(t as Map<String, dynamic>)).toList(),
      art: j['art'] as String?,
    );
  }

  /// 화자 A = 학습자. 표시 이름은 프로필 이름, 없으면 「나」.
  static const learner = 'A';

  /// 화자 표시 이름. A(학습자)·`{name}` 자리는 학습자 이름(없으면 「나」).
  String speakerName(String sp) {
    final raw = speakers[sp] ?? sp;
    if (sp == learner || raw.contains('{name}')) {
      return LearnerPrefs.name.value.isNotEmpty ? LearnerPrefs.name.value : '나';
    }
    return raw.replaceAll(RegExp(r'[{}]'), '');
  }

  /// 화면에 보일 장면 설명 — 원고의 「A」(학습자)를 이름(없으면 「나」)으로(일본어앱 빌드 111).
  String get sceneShown => scene.replaceAllMapped(RegExp(r'(?<![A-Za-z])A(?![A-Za-z]) ?(?=[가-힣])'), (_) => speakerName('A'));

  /// 목소리 성별 — A(학습자)는 프로필 성별, 그 밖의 화자는 인물 성별.
  String voiceGender(String sp) => sp == learner ? LearnerPrefs.gender.value : (genders[sp] ?? LearnerPrefs.voiceGender(sp));

  /// 편 순서 키: survival → a → b → c, 번호 순.
  String get orderKey {
    final m = RegExp(r'_([abcs])(\d+)$').firstMatch(id);
    if (m == null) return id;
    const o = {'s': 0, 'a': 1, 'b': 2, 'c': 3};
    return '${o[m.group(1)]}${m.group(2)!.padLeft(2, '0')}';
  }
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
  static const levels = ['R0', 'R1', 'R2', 'R3', 'R4', 'R5'];
  /// 회화 레벨 = 문법 단계 0~5(`docs/DIALOGUE_RULES_it.md`) — 단어 메뉴의 절벽 R1~R5 와 번호가 다르다.
  static const levelKo = {'R0': '레벨 0 · 첫걸음', 'R1': '레벨 1 · 뼈대', 'R2': '레벨 2 · 채팅', 'R3': '레벨 3 · 복수·존댓말', 'R4': '레벨 4 · 어려운 문법', 'R5': '레벨 5 · 어휘 완성'};
  static const _prefLast = 'dialogue_last';

  final Map<String, Dialogue> _byId = {};
  String? _lastOpened;
  String? get lastOpenedId => _lastOpened;
  Future<void> setLastOpened(String id) async {
    _lastOpened = id;
    (await Prefs.getInstance()).setString(_prefLast, id);
  }

  /// 원고가 서버 판으로 바뀌어 다시 읽힐 때마다 오른다.
  final ValueNotifier<int> revision = ValueNotifier(0);

  /// 여러 화면이 동시에 불러도 한 번만 읽는다.
  Future<void> ensureLoaded() => _loading ??= _load();
  Future<void>? _loading;

  Future<void> _load() async {
    _lastOpened = (await Prefs.getInstance()).getString(_prefLast);
    await _readAll();
    // 서버에 더 새 원고가 있으면 뒤에서 받아 다시 읽는다(없거나 실패하면 그대로)
    ScriptSync.instance.refresh().then((changed) async {
      if (!changed) return;
      await _readAll();
      revision.value++;
    });
  }

  /// 앱 안 편 + 서버에서 받은 새 편을 읽는다. 각 파일은 덮어쓴 판이 있으면 그것.
  Future<void> _readAll() async {
    final sync = ScriptSync.instance;
    await sync.init();
    final pat = RegExp(r'^assets/data/dialogues/R[0-5]/[^/]+/[^/]+\.json$');
    final rels = <String>{};
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      // 통합 앱이면 키에 packages/italian_universe/ 가 붙어 있다 — 접두를 떼고 견준다
      rels.addAll([for (final p in manifest.listAssets().map(stripAssetPrefix).where(pat.hasMatch)) p.substring('assets/data/'.length)]);
    } catch (_) {}
    rels
      ..addAll(sync.added.where((p) => pat.hasMatch('assets/data/$p')))
      ..removeAll(sync.removed);
    final next = <String, Dialogue>{};
    for (final rel in rels) {
      try {
        final d = Dialogue.fromJson(json.decode(await sync.load(rel)) as Map<String, dynamic>);
        if (d.turns.isNotEmpty) next[d.id] = d;
      } catch (_) {}
    }
    _byId
      ..clear()
      ..addAll(next);
  }

  Dialogue? byId(String id) => _byId[id];
  List<Dialogue> get all => _byId.values.toList();

  /// 편이 있는 레벨(R0 → R5 순).
  List<String> get regions => levels.where((r) => _byId.values.any((d) => d.region == r)).toList();

  List<Dialogue> list({String? region, String? island}) {
    final out = _byId.values.where((d) => (region == null || d.region == region) && (island == null || d.island == island)).toList();
    out.sort((a, b) => a.orderKey.compareTo(b.orderKey));
    return out;
  }

  List<String> islandsOf(String region) {
    final has = _byId.values.where((d) => d.region == region).map((d) => d.island).toSet();
    return islands.where(has.contains).toList();
  }

  int count(String region) => _byId.values.where((d) => d.region == region).length;
}
