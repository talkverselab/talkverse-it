/// 말하기 판정 — 인식 결과와 목표 문장을 단어 단위로 견준다 (언어 중립).
///
/// - 소문자화 · 문장부호 제거 · 라틴 문자 악센트 제거(é→e, ß→ss, ı→i …)
/// - 단어 단위 LCS 비율 ≥ [threshold] 이면 통과. 3단어 이하 문장은 전부 맞아야 통과.
/// - 라틴 문자가 아닌 언어(힌디어·페르시아어)는 악센트 제거 없이 단어로 견준다.
class SpeakMatch {
  SpeakMatch._();

  static const double threshold = 0.7;

  static const Map<String, String> _fold = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
    'ç': 'c', 'č': 'c',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ı': 'i', 'İ': 'i',
    'ñ': 'n',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ő': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ű': 'u',
    'ğ': 'g', 'ş': 's', 'ß': 'ss', 'œ': 'oe', 'æ': 'ae',
  };

  /// 비교용 단어 목록.
  static List<String> words(String s) {
    var t = s.toLowerCase();
    final b = StringBuffer();
    for (final ch in t.split('')) {
      b.write(_fold[ch] ?? ch);
    }
    t = b.toString();
    // 문장부호·기호 → 공백 (글자·숫자·결합 부호는 남긴다)
    t = t.replaceAll(
        RegExp(r"[^\p{L}\p{M}\p{N}\s]", unicode: true), ' ');
    return t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }

  /// 0~1. 목표 단어 중 순서대로 맞힌 비율.
  static double score(String target, String heard) {
    final a = words(target);
    final b = words(heard);
    if (a.isEmpty) return 0;
    if (b.isEmpty) return 0;
    return _lcs(a, b) / a.length;
  }

  static bool pass(String target, String heard) {
    final a = words(target);
    final s = score(target, heard);
    if (a.length <= 3) return s >= 0.999;
    return s >= threshold;
  }

  static int _lcs(List<String> a, List<String> b) {
    final dp = List.generate(a.length + 1, (_) => List<int>.filled(b.length + 1, 0));
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        dp[i][j] = a[i - 1] == b[j - 1]
            ? dp[i - 1][j - 1] + 1
            : (dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1]);
      }
    }
    return dp[a.length][b.length];
  }
}
