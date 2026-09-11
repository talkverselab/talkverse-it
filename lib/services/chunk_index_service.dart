import '../main.dart';
import '../screens/episode_screen.dart';
import '../screens/grammar_lesson_screen.dart';
import 'speak_match.dart';

/// 검색 대상 문장 — 회화 턴 + 문법 예문.
class IndexedSentence {
  final String tl; // 대상어
  final String rd; // 한글 독음
  final String ko; // 뜻
  final String source; // '회화 · 제목' | '문법 · 강의'
  final String gender; // TTS 음성
  const IndexedSentence(this.tl, this.rd, this.ko, this.source, this.gender);
}

/// 청크 = 단어 1개 또는 이어진 단어 2~3개. 검색어가 들어간 청크별로 문장을 모은다.
class ChunkHit {
  final String chunk;
  final List<IndexedSentence> sentences;
  const ChunkHit(this.chunk, this.sentences);
}

/// 전 문장 청크 역인덱스 (언어 중립 — 띄어쓰기 단위).
class ChunkIndexService {
  ChunkIndexService._();
  static final ChunkIndexService instance = ChunkIndexService._();

  final List<IndexedSentence> _all = [];
  final Map<String, Set<int>> _index = {}; // 정규화 청크 → 문장 번호
  final Map<String, Map<String, int>> _surface = {}; // 정규화 청크 → 원형 빈도
  bool _loaded = false;

  List<IndexedSentence> get all => _all;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await EpisodeCatalog.instance.ensureLoaded();
    final titles = {
      for (final m in EpisodeCatalog.instance.all) '${m.level}/${m.id}': m.title,
    };
    final turns = await appDb.select(appDb.turns).get();
    for (final t in turns) {
      _add(IndexedSentence(
        t.es,
        t.rd ?? '',
        t.ko ?? '',
        '회화 · ${titles['${t.level}/${t.episodeId}'] ?? t.level}',
        EpisodeCatalog.instance.speaker(t.level, t.speaker).gender,
      ));
    }
    for (final l in await GrammarLesson.loadAll()) {
      for (final p in l.patterns) {
        for (final ex in (p['examples'] as List? ?? const []).whereType<Map>()) {
          final tl = '${ex['tl'] ?? ''}';
          if (tl.isEmpty) continue;
          _add(IndexedSentence(tl, '${ex['rd'] ?? ''}', '${ex['ko'] ?? ''}',
              '문법 · ${l.title}', 'female'));
        }
      }
    }
    _loaded = true;
  }

  static final _wordRe = RegExp(r"[\p{L}\p{M}\p{N}'’-]+", unicode: true);

  void _add(IndexedSentence s) {
    final idx = _all.length;
    _all.add(s);
    final raw = _wordRe.allMatches(s.tl).map((m) => m.group(0)!).toList();
    for (var n = 1; n <= 3; n++) {
      for (var i = 0; i + n <= raw.length; i++) {
        final surface = raw.sublist(i, i + n).join(' ');
        final key = _norm(surface);
        if (key.isEmpty) continue;
        _index.putIfAbsent(key, () => {}).add(idx);
        final sf = _surface.putIfAbsent(key, () => {});
        sf[surface] = (sf[surface] ?? 0) + 1;
      }
    }
  }

  static String _norm(String s) => SpeakMatch.words(s).join(' ');

  static bool _hasHangul(String s) => RegExp(r'[가-힣]').hasMatch(s);

  String _display(String key) {
    final sf = _surface[key];
    if (sf == null || sf.isEmpty) return key;
    return (sf.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
  }

  /// 자주 나오는 단어 (검색 전 추천 칩).
  List<String> topWords(int n) {
    final singles = _index.entries.where((e) => !e.key.contains(' ') && e.key.length > 1).toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    return [for (final e in singles.take(n)) _display(e.key)];
  }

  List<ChunkHit> search(String query) {
    final q = query.trim();
    if (q.isEmpty) return const [];
    // 한글 → 뜻·독음에서 찾는다.
    if (_hasHangul(q)) {
      final hits = [
        for (final s in _all)
          if (s.ko.contains(q) || s.rd.contains(q)) s,
      ];
      return hits.isEmpty ? const [] : [ChunkHit(q, hits)];
    }
    final nq = _norm(q);
    if (nq.isEmpty) return const [];
    final keys = _index.keys.where((k) => k.contains(nq)).toList()
      ..sort((a, b) {
        final ea = a == nq ? 0 : (a.startsWith(nq) ? 1 : 2);
        final eb = b == nq ? 0 : (b.startsWith(nq) ? 1 : 2);
        if (ea != eb) return ea.compareTo(eb);
        final c = _index[b]!.length.compareTo(_index[a]!.length);
        return c != 0 ? c : a.length.compareTo(b.length);
      });
    return [
      for (final k in keys.take(40))
        ChunkHit(_display(k), [for (final i in _index[k]!) _all[i]]),
    ];
  }
}
