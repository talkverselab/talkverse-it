import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../core/prefs.dart';

import 'dialogue_service.dart';

/// 성과 기록·집계 — 일본어앱 `achievement_service.dart`(시안 02 §5)를 옮김, 2026-11-03.
///
/// **센다**: 편 완주(「모든 문장 듣기」 끝까지) · 그림 카드 맞음. (라이트너 단계·빈도 커버율·동사 활용 맞힘은 그 엔진·데이터가 생긴 뒤.)
/// **안 센다**: 앱 오픈·스트릭·포인트·순위. 저장은 SharedPreferences `achievements_v1`(JSON 하나).
class AchievementService {
  AchievementService._();
  static final AchievementService instance = AchievementService._();
  static const _key = 'achievements_v1';

  final Map<String, String> _episodes = {}; // 편 id → 처음 완주한 날(yyyy-mm-dd)
  final Map<String, List<int>> _cards = {}; // 편 id → [맞음, 전체] (마지막 세션)
  final Map<String, Map<String, int>> _daily = {}; // 날짜 → {episodes, cards}
  final ValueNotifier<int> changes = ValueNotifier(0);
  bool _loaded = false;

  String get today => _ymd(DateTime.now());
  static String _ymd(DateTime t) => '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = (await Prefs.getInstance()).getString(_key);
      if (raw != null) {
        final j = json.decode(raw) as Map<String, dynamic>;
        (j['episodes'] as Map<String, dynamic>? ?? {}).forEach((k, v) => _episodes[k] = v.toString());
        (j['cards'] as Map<String, dynamic>? ?? {}).forEach((k, v) => _cards[k] = (v as List).cast<int>());
        (j['daily'] as Map<String, dynamic>? ?? {}).forEach((k, v) => _daily[k] = (v as Map).map((a, b) => MapEntry(a.toString(), (b as num).toInt())));
      }
    } catch (e) {
      debugPrint('Achievement: load 실패 $e');
    }
    _loaded = true;
  }

  Future<void> _save() async {
    changes.value++;
    final data = json.encode({'episodes': _episodes, 'cards': _cards, 'daily': _daily});
    (await Prefs.getInstance()).setString(_key, data);
  }

  /// 학습 기록 초기화(프로필 → 기록).
  Future<void> reset() async {
    _episodes.clear();
    _cards.clear();
    _daily.clear();
    await _save();
  }

  void _bump(String what, [int n = 1]) {
    final d = _daily.putIfAbsent(today, () => {});
    d[what] = (d[what] ?? 0) + n;
  }

  /// 편을 끝까지 들었다. 처음 완주한 날만 기록(반복 횟수는 세지 않는다).
  Future<bool> markEpisodeDone(String id) async {
    await load();
    final first = !_episodes.containsKey(id);
    if (first) {
      _episodes[id] = today;
      _bump('episodes');
      await _save();
    }
    return first;
  }

  /// 그림 카드 세션 결과(편별 마지막 세션).
  Future<void> markCards(String episodeId, int right, int total) async {
    await load();
    _cards[episodeId] = [right, total];
    _bump('cards', right);
    await _save();
  }

  bool isDone(String id) => _episodes.containsKey(id);
  int get episodesDone => _episodes.length;
  List<int>? cardsOf(String id) => _cards[id];

  (int, int) progress({required String island, required String region}) {
    final all = DialogueService.instance.list(region: region, island: island);
    final done = all.where((d) => _episodes.containsKey(d.id)).length;
    return (done, all.length);
  }

  /// 최근 7일(오늘 포함, 오래된 날부터) 완주 편 수.
  List<(String, int)> week() {
    final now = DateTime.now();
    return [for (var i = 6; i >= 0; i--) (_ymd(now.subtract(Duration(days: i))), _daily[_ymd(now.subtract(Duration(days: i)))]?['episodes'] ?? 0)];
  }

  Map<String, int> get thisWeek {
    final out = {'episodes': 0, 'cards': 0};
    for (final (d, _) in week()) {
      final m = _daily[d];
      if (m == null) continue;
      for (final k in out.keys) {
        out[k] = out[k]! + (m[k] ?? 0);
      }
    }
    return out;
  }

  /// 이번 주 가장 많이 완주한 주제(없으면 빈 문자열).
  String weekSentence() {
    final counts = <String, int>{};
    for (final (d, _) in week()) {
      for (final e in _episodes.entries) {
        if (e.value != d) continue;
        final dlg = DialogueService.instance.byId(e.key);
        if (dlg != null) counts[dlg.island] = (counts[dlg.island] ?? 0) + 1;
      }
    }
    String best = '';
    var n = 0;
    counts.forEach((k, v) {
      if (v > n) {
        n = v;
        best = k;
      }
    });
    return best;
  }
}
