import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../embed.dart';
import 'embed_env.dart';

/// 내용이 있을 때만 메뉴를 보인다(2026-11-22 심사 정리 — 빈 화면·「준비 중」 자리표시는 미완성 앱으로 보인다).
/// 지금 단어장(`words`)·주제별 단어·표현은 비어 있다(§11) → 「절벽 단어」「단어」「표현」「단어 카드」가 숨는다. 데이터가 생기면 저절로 보인다.
class ContentReady {
  ContentReady._();
  static const wordsAsset = 'assets/data/vocab/travel_words.json';
  static const exprAsset = 'assets/data/vocab/travel_expressions.json';

  /// 단어장 DB 에 낱말이 있음 → 「절벽 단어」.
  static final ValueNotifier<bool> cliffWords = ValueNotifier(false);

  /// 주제별 단어 → 「단어」·「단어 카드」.
  static final ValueNotifier<bool> topicWords = ValueNotifier(false);

  /// 주제별 표현 → 「표현」.
  static final ValueNotifier<bool> topicExpr = ValueNotifier(false);

  static Future<void>? _checking;
  static Future<void> check() => _checking ??= _check();

  static Future<void> _check() async {
    topicWords.value = await _hasThemes(wordsAsset);
    topicExpr.value = await _hasThemes(exprAsset);
    try {
      cliffWords.value = (await (appDb.select(appDb.words)..limit(1)).get()).isNotEmpty;
    } catch (_) {}
  }

  static Future<bool> _hasThemes(String asset) async {
    try {
      final d = json.decode(await rootBundle.loadString(assetPath(asset))) as Map<String, dynamic>;
      return ((d['themes'] as List?) ?? const []).isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
