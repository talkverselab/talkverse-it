/// 절벽 구간 한 곳(CLAUDE.md §13, 레마 기준). 화면은 이 값만 쓴다.
/// R1~R4 끝 = 누적 55·60·70·80% 에 처음 닿는 순위. R5 는 2,000위에서 끊는다(사용자 지시 2026-11-07).
const List<int> kWordCliffs = [61, 91, 211, 661];
const int kWordCap = 2000;

/// 2,000위 누적 %. 2,500위 88.0% 에서 2,001~2,500위 레마 몫(약 1.05%)을 뺀 추정값이라 화면에는 「약」을 붙인다.
const double kWordCapPct = 86.9;

/// 한 단원 = 20어.
const int kWordUnit = 20;

/// 순위 → 구간(R1~R5). 2,000위 밖이면 null.
String? regionOfRank(int rank) {
  if (rank < 1 || rank > kWordCap) return null;
  for (var i = 0; i < kWordCliffs.length; i++) {
    if (rank <= kWordCliffs[i]) return 'R${i + 1}';
  }
  return 'R5';
}
