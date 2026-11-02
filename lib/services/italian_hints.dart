import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 시안 it-01 의 이탈리아어 칸 두 개(동사 활용 표 · 성·수 색 점)를 위한 자리 — 2026-11-03.
///
/// **데이터가 들어오기 전에는 칸과 칩을 숨긴다**(시안 §6). 지금 `verbs_core.json` 의 `verbs` 는 비어 있고,
/// 빈도표 CSV 의 `gender` 칸도 비어 있어 [hasVerbs]·[hasGender] 가 false 다 — 그래서 화면에는 아무것도 나오지 않는다.
/// 데이터가 채워지면(콘텐츠 작업 때) 코드를 고치지 않아도 리더에서 저절로 켜진다.
/// - 동사: `verbs_core.json` `verbs[{inf, ko, present:[io, tu, lui/lei, noi, voi, loro]}]`
/// - 성·수: 빈도표 `gender` = m | f | mp | fp (남성 단수·여성 단수·남성 복수·여성 복수)
class ItalianHints {
  ItalianHints._();
  static final ItalianHints instance = ItalianHints._();

  static const persons = ['io', 'tu', 'lui/lei', 'noi', 'voi', 'loro'];

  final Map<String, VerbForms> _byForm = {}; // 활용형(소문자) → 동사
  final Map<String, String> _gender = {}; // 낱말(소문자) → m|f|mp|fp

  bool get hasVerbs => _byForm.isNotEmpty;
  bool get hasGender => _gender.isNotEmpty;

  Future<void> ensureLoaded() => _loading ??= _load();
  Future<void>? _loading;

  Future<void> _load() async {
    try {
      final j = json.decode(await rootBundle.loadString('assets/data/grammar/verbs_core.json')) as Map<String, dynamic>;
      for (final v in (j['verbs'] as List? ?? const []).whereType<Map>()) {
        final present = (v['present'] as List?)?.map((e) => '$e').toList() ?? const <String>[];
        if (present.length != persons.length) continue;
        final f = VerbForms('${v['inf']}', '${v['ko'] ?? ''}', present);
        for (final p in present) {
          _byForm[p.toLowerCase()] = f;
        }
      }
    } catch (_) {}
    try {
      final raw = await rootBundle.loadString('assets/data/freq/lang_es_top.csv');
      final rows = const CsvToListConverter(eol: '\n').convert(raw);
      for (var i = 1; i < rows.length; i++) {
        final r = rows[i];
        if (r.length < 4) continue;
        final g = '${r[3]}'.trim();
        if (const {'m', 'f', 'mp', 'fp'}.contains(g)) _gender['${r[1]}'.toLowerCase()] = g;
      }
    } catch (_) {}
  }

  /// 이 낱말이 동사 활용형이면 그 동사와 인칭 번호(0~5).
  (VerbForms, int)? verbOf(String word) {
    final f = _byForm[word.toLowerCase()];
    if (f == null) return null;
    return (f, f.present.indexWhere((p) => p.toLowerCase() == word.toLowerCase()));
  }

  /// 낱말의 성·수(m|f|mp|fp), 없으면 null.
  String? genderOf(String word) => _gender[word.toLowerCase()];
}

class VerbForms {
  final String infinitive;
  final String ko;
  final List<String> present;
  const VerbForms(this.infinitive, this.ko, this.present);
}
