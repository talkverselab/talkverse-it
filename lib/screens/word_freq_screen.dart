import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../core/cliff.dart';
import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../main.dart';
import '../services/art_service.dart';
import '../services/content_sync.dart';
import '../services/dialogue_service.dart';
import '../services/tts_service.dart';
import '../services/word_service.dart';

/// 절벽 단어 — 빈도 1~2,000위를 절벽구간(R1~R5)별 **20어 단원**으로, 단어는 **네모 타일**로 보여 준다(일본어앱 2026-11-07 구조).
/// 위 버튼 「절벽구간 단어만 / 회화 단어 포함」 — 포함이면 회화 레마 중 2,000위 밖이면서 단어장에 있는 말이 「회화」 구간으로 뒤에 붙는다.
/// DB 는 합치지 않고 화면에서만 합친다. 단어장(`words`)이 비어 있으면 「아직 단어가 없습니다.」.
class WordFreqScreen extends StatefulWidget {
  const WordFreqScreen({super.key});

  @override
  State<WordFreqScreen> createState() => _WordFreqScreenState();
}

class _Word {
  final int rank;
  final String word;
  final String region; // R1~R5 · C(회화 단어)
  final String ko;
  final String? gender;
  const _Word({required this.rank, required this.word, required this.region, this.ko = '', this.gender});
}

class _Region {
  final String label;
  final Color color;
  const _Region(this.label, this.color);
}

class _WordFreqScreenState extends State<WordFreqScreen> {
  List<_Word> _words = const [];
  List<_Word> _conv = const [];
  bool _loading = true;
  bool _withConv = false;
  String _filter = 'ALL';

  static Map<String, _Region> get _regions {
    const c = kWordCliffs;
    return {
      'ALL': _Region(tr('전체'), AppColors.sumi),
      'R1': _Region('R1 · 1-${c[0]}', AppColors.beni),
      'R2': _Region('R2 · ${c[0] + 1}-${c[1]}', AppColors.kinDeep),
      'R3': _Region('R3 · ${c[1] + 1}-${c[2]}', AppColors.italia),
      'R4': _Region('R4 · ${c[2] + 1}-${c[3]}', AppColors.matcha),
      'R5': _Region('R5 · ${c[3] + 1}-$kWordCap', AppColors.muted),
      'C': _Region(tr('회화'), AppColors.ai),
    };
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await (appDb.select(appDb.words)
          ..where((w) => w.rank.isBetweenValues(1, kWordCap))
          ..orderBy([(w) => OrderingTerm.asc(w.rank)]))
        .get();
    final words = [
      for (final r in rows)
        _Word(rank: r.rank, word: r.word, region: regionOfRank(r.rank) ?? 'R5', ko: r.meaningKo ?? '', gender: r.gender),
    ];
    var conv = const <_Word>[];
    try {
      conv = await _convWords(words.map((w) => w.word.toLowerCase()).toSet());
    } catch (_) {
      // 회화를 못 읽어도 절벽 단어는 보여 준다
    }
    if (!mounted) return;
    setState(() {
      _words = words;
      _conv = conv;
      _loading = false;
    });
  }

  /// 회화 전 편의 레마를 등장 횟수순으로 — 2,000위 안의 말과 단어장에 없는 말은 뺀다.
  Future<List<_Word>> _convWords(Set<String> top) async {
    await DialogueService.instance.ensureLoaded();
    final counts = <String, int>{};
    for (final d in DialogueService.instance.all) {
      for (final t in d.turns) {
        for (final l in t.lemmas) {
          final k = l.base.toLowerCase();
          if (!top.contains(k)) counts[k] = (counts[k] ?? 0) + 1;
        }
      }
    }
    final found = await WordService.instance.byLemmas(counts.keys);
    final keys = found.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return [
      for (var i = 0; i < keys.length; i++)
        _Word(rank: i + 1, word: found[keys[i]]!.word, region: 'C', ko: found[keys[i]]!.gloss ?? '', gender: found[keys[i]]!.gender),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pool = _withConv ? [..._words, ..._conv] : _words;
    final filtered = _filter == 'ALL' ? pool : pool.where((w) => w.region == _filter).toList();
    final units = <List<_Word>>[];
    for (var i = 0; i < filtered.length; i += kWordUnit) {
      units.add(filtered.sublist(i, (i + kWordUnit).clamp(0, filtered.length)));
    }
    final regions = _regions;
    final chips = regions.entries.where((e) => e.key != 'C' || _withConv).toList();

    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('절벽 단어'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(trf('빈도 {0}위 · {1}어 단원 · 탭하면 발음', ['2,000', kWordUnit]),
                style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 1)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.beni))
          : Column(
              children: [
                Container(
                  color: AppColors.washiDeep,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _ModeButton(
                            label: tr('절벽구간 단어만'),
                            selected: !_withConv,
                            onTap: () => setState(() {
                              _withConv = false;
                              if (_filter == 'C') _filter = 'ALL';
                            }),
                          ),
                          const SizedBox(width: 8),
                          _ModeButton(
                            label: trf('회화 단어 포함 (+{0})', [_conv.length]),
                            selected: _withConv,
                            onTap: () => setState(() => _withConv = true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final e in chips)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => setState(() => _filter = e.key),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _filter == e.key ? e.value.color : AppColors.washi,
                                      border: Border.all(color: e.value.color, width: _filter == e.key ? 1.5 : 0.8),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(e.value.label,
                                        style: TextStyle(color: _filter == e.key ? AppColors.washi : e.value.color, fontWeight: FontWeight.w700, fontSize: 12)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: units.isEmpty
                      ? Center(child: Text(tr('아직 단어가 없습니다.'), style: const TextStyle(color: AppColors.muted)))
                      : LayoutBuilder(
                          builder: (context, c) => ListView.builder(
                            padding: EdgeInsets.fromLTRB(12, 8, 12, 16 + bottomInset(context)),
                            itemCount: units.length,
                            itemBuilder: (context, i) => _UnitBlock(
                              index: i + 1,
                              words: units[i],
                              regions: regions,
                              cols: (c.maxWidth / 112).floor().clamp(3, 8),
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.sumi : AppColors.washi,
              border: Border.all(color: selected ? AppColors.sumi : AppColors.line),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label, style: TextStyle(color: selected ? AppColors.washi : AppColors.sumi, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ),
      );
}

/// 한 단원 = 20어. 머리줄(단원 번호·순위 범위·구간) + 네모 타일 격자.
class _UnitBlock extends StatelessWidget {
  final int index;
  final List<_Word> words;
  final Map<String, _Region> regions;
  final int cols;
  const _UnitBlock({required this.index, required this.words, required this.regions, required this.cols});

  @override
  Widget build(BuildContext context) {
    final first = words.first;
    final region = regions[first.region];
    final conv = first.region == 'C';
    final range = conv ? trf('회화 {0}-{1}', [first.rank, words.last.rank]) : '#${first.rank}-${words.last.rank}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
            child: Row(
              children: [
                Text(trf('{0}단원', [index]), style: const TextStyle(color: AppColors.sumi, fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                Text(range, style: const TextStyle(color: AppColors.sumiLight, fontSize: 11)),
                const Spacer(),
                if (region != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: region.color, borderRadius: BorderRadius.circular(2)),
                    child: Text(conv ? tr('회화') : first.region, style: const TextStyle(color: AppColors.washi, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 6, crossAxisSpacing: 6),
            itemCount: words.length,
            itemBuilder: (context, i) => _WordTile(w: words[i], color: region?.color ?? AppColors.sumi),
          ),
        ],
      ),
    );
  }
}

/// 네모 타일 — 순위 · 그림(있으면) · 단어 · 뜻 한 줄. 탭하면 발음.
class _WordTile extends StatelessWidget {
  final _Word w;
  final Color color;
  const _WordTile({required this.w, required this.color});

  @override
  Widget build(BuildContext context) {
    final conv = w.region == 'C';
    return InkWell(
      onTap: () => TtsService.instance.speak(w.word),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.washi,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(8),
          boxShadow: kCardShadow,
        ),
        padding: const EdgeInsets.all(6),
        child: LayoutBuilder(
          builder: (context, c) {
            final art = (c.maxHeight * 0.42).clamp(24.0, 72.0);
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(conv ? tr('회화') : '#${w.rank}', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w800)),
                ),
                Expanded(child: Center(child: _Thumb(word: w.word, rank: conv ? null : w.rank, size: art))),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(w.word, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.sumi)),
                ),
                if (w.ko.isNotEmpty)
                  Text(w.ko, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.sumiLight)),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 단어 그림(있으면). 없으면 빈 자리.
class _Thumb extends StatefulWidget {
  final String word;
  final int? rank;
  final double size;
  const _Thumb({required this.word, required this.rank, required this.size});

  @override
  State<_Thumb> createState() => _ThumbState();
}

class _ThumbState extends State<_Thumb> {
  late final Future<String?> _url = ArtService.instance.urlFor(widget.word, rank: widget.rank);

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
        future: _url,
        builder: (context, snap) {
          final u = snap.data;
          if (u == null) return const SizedBox.shrink();
          return Image(image: artProvider(u), width: widget.size, height: widget.size, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink());
        },
      );
}
