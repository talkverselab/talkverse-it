import 'package:drift/drift.dart';

import '../main.dart';

/// 단어장 조회 — 문장 레마 칩(`LemmaChips`)이 기본형으로 단어장 항목을 찾는 데 쓴다(일본어앱 `WordService.byLemmas` 를 옮김, 2026-11-04).
///
/// 이 앱의 단어장 = DB `words`(빈도표 시드, `assets/data/freq/`) + `verbs`(핵심 동사). 2026-11-04 현재 둘 다 비어 있어(§11 외부 유래 단어 제거)
/// 칩은 전부 회색으로 나온다 — 단어장이 채워지면(빈도표 기반 자체 제작) 그대로 연결된다. 단어장에 없는 레마 목록은 `data/review/write/missing_lemmas.csv`.
class WordEntry {
  final String word;
  final String? gloss;
  final String? pos;
  final String? gender;
  final int? rank;
  const WordEntry({required this.word, this.gloss, this.pos, this.gender, this.rank});
}

class WordService {
  WordService._();
  static final WordService instance = WordService._();

  /// 기본형(소문자) → 단어장 항목. 없는 기본형은 결과에 들어가지 않는다. DB 가 비어 있거나 실패하면 빈 맵(화면은 회색 칩).
  Future<Map<String, WordEntry>> byLemmas(Iterable<String> bases) async {
    final keys = bases.map((b) => b.trim().toLowerCase()).where((b) => b.isNotEmpty).toSet().toList();
    if (keys.isEmpty) return const {};
    final out = <String, WordEntry>{};
    try {
      final rows = await (appDb.select(appDb.words)..where((w) => w.word.lower().isIn(keys))).get();
      for (final r in rows) {
        final k = r.word.toLowerCase();
        final prev = out[k];
        if (prev == null || (prev.rank ?? 1 << 30) > r.rank) {
          out[k] = WordEntry(word: r.word, gloss: r.meaningKo, pos: r.pos, gender: r.gender, rank: r.rank);
        }
      }
      final verbs = await (appDb.select(appDb.verbs)..where((v) => v.infinitive.lower().isIn(keys))).get();
      for (final v in verbs) {
        out.putIfAbsent(v.infinitive.toLowerCase(), () => WordEntry(word: v.infinitive, gloss: v.meaningKo, pos: 'verb', rank: v.rank));
      }
    } catch (_) {
      // DB 가 아직 없거나(테스트) 표가 비어 있으면 빈 결과
    }
    return out;
  }
}
