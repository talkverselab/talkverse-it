import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_database.dart';

class SeedLoader {
  // v1: 초기 시드 (L1 샘플 대화 + 빈도 단어 + 핵심 동사)
  static const _kSeededKey = 'db_seeded_v1';

  final AppDatabase db;
  SeedLoader(this.db);

  Future<void> seedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kSeededKey) == true) return;

    await _seedWords();
    await _seedVerbs();
    await _seedTurns();

    await prefs.setBool(_kSeededKey, true);
  }

  static String? _s(dynamic v) {
    final t = '$v'.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _seedWords() async {
    final String raw;
    try {
      raw = await rootBundle.loadString('assets/data/freq/lang_es_top.csv');
    } catch (_) {
      return;
    }
    final rows = const CsvToListConverter(eol: '\n').convert(raw);
    final batch = <Insertable<WordRow>>[];
    // header: rank,word,pos,gender,ko,freq,cum_pct,region,cefr
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 9) continue;
      batch.add(WordsCompanion.insert(
        rank: Value(int.tryParse('${row[0]}') ?? 0),
        word: '${row[1]}',
        pos: Value(_s(row[2])),
        gender: Value(_s(row[3])),
        meaningKo: Value(_s(row[4])),
        freq: Value(double.tryParse('${row[5]}')),
        cumPct: Value(double.tryParse('${row[6]}')),
        region: Value(_s(row[7])),
        cefr: Value(_s(row[8])),
      ));
    }
    await db.batch((b) => b.insertAllOnConflictUpdate(db.words, batch));
  }

  Future<void> _seedVerbs() async {
    final Map<String, dynamic> data;
    try {
      final raw = await rootBundle.loadString('assets/data/grammar/verbs_core.json');
      data = json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final verbs = (data['verbs'] as List?) ?? [];
    final batch = <Insertable<VerbRow>>[];
    for (final v in verbs.whereType<Map>()) {
      batch.add(VerbsCompanion.insert(
        infinitive: v['inf'] as String,
        group: v['group'] as String,
        meaningKo: Value(v['ko'] as String?),
        rank: Value(v['rank'] as int?),
        presentJson: Value(v['present'] != null ? json.encode(v['present']) : null),
        preteriteJson: Value(v['preterite'] != null ? json.encode(v['preterite']) : null),
      ));
    }
    await db.batch((b) => b.insertAllOnConflictUpdate(db.verbs, batch));
  }

  /// L1~L3 전체 턴 시딩. 'episodes' 또는 'dialogues' 키 사용.
  Future<void> _seedTurns() async {
    final batch = <Insertable<TurnRow>>[];
    for (final level in ['L1', 'L2', 'L3']) {
      final Map<String, dynamic> data;
      try {
        final raw = await rootBundle.loadString('assets/data/dialogues/$level.json');
        data = json.decode(raw) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      final variety = (data['variety'] as String?) ?? 'es_ES';
      final units = (data['episodes'] as List?) ?? (data['dialogues'] as List?) ?? [];
      for (final ep in units) {
        final epMap = ep as Map<String, dynamic>;
        final epId = epMap['id'] as String?;
        final turns = (epMap['turns'] as List?) ?? [];
        for (final t in turns) {
          final m = t as Map<String, dynamic>;
          batch.add(TurnsCompanion.insert(
            level: level,
            variety: Value(variety),
            episodeId: Value(epId),
            num: m['num'] as int,
            speaker: m['speaker'] as String,
            es: m['es'] as String,
            ko: Value(m['ko'] as String?),
            note: Value(m['note'] as String?),
            tagsJson: Value(m['tags'] != null ? json.encode(m['tags']) : null),
          ));
        }
      }
    }
    if (batch.isNotEmpty) {
      // 재시딩: 이전 버전 턴·진행 기록 제거 후 삽입 (turnId 재발급)
      await db.delete(db.userProgress).go();
      await db.delete(db.turns).go();
      await db.batch((b) => b.insertAll(db.turns, batch));
    }
  }

  Future<int> turnCount() => db.turns.count().getSingle();
  Future<int> verbCount() => db.verbs.count().getSingle();
  Future<int> wordCount() => db.words.count().getSingle();
}
