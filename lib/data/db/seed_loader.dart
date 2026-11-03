import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_database.dart';

class SeedLoader {
  /// 번들 `assets/data/version.json` 의 `db`(업데이트 번호)와 저장된 번호가 다르면 DB(단어·동사·회화 턴)를 전부 다시 채운다
  /// (일본어앱 2026-11-04 와 같음). 데이터를 바꿀 때는 이 번호만 올린다 — 옛 `db_seeded_v2` 키는 폐지(있으면 저장 번호 0 으로 보고 한 번 다시 채움).
  static const _kDbVersion = 'db_version';
  static const _kOldSeededKey = 'db_seeded_v2';

  final AppDatabase db;
  SeedLoader(this.db);

  Future<void> seedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final bundled = await bundledVersion();
    final stored = prefs.getInt(_kDbVersion) ?? 0; // 옛 키만 있던 설치 = 0 → 한 번 다시 채움
    if (stored == bundled) return;

    await db.delete(db.words).go();
    await _seedWords();
    await db.delete(db.verbs).go();
    await _seedVerbs();
    await _seedTurns();

    await prefs.setInt(_kDbVersion, bundled);
    if (prefs.containsKey(_kOldSeededKey)) await prefs.remove(_kOldSeededKey);
  }

  /// 번들 DB 업데이트 번호(`assets/data/version.json` → `db`). 읽기 실패면 0.
  static Future<int> bundledVersion() async {
    try {
      final j = json.decode(await rootBundle.loadString('assets/data/version.json')) as Map<String, dynamic>;
      return (j['db'] as num).toInt();
    } catch (_) {
      return 0;
    }
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
            rd: Value(m['rd'] as String?),
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
