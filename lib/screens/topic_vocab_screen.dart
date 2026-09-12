import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../services/ko_reading.dart';
import '../services/memorized_store.dart';
import '../services/tts_service.dart';
import '../core/platform.dart';
import '../core/l10n.dart';

/// co-Trip 여행 이탈리아어 — 주제별 단어·표현 (chinese-universe 포팅).
class VocabWord {
  final String ko;
  final String tx; // 이탈리아어
  final String rd; // 한글 독음
  final String? ic; // 아이콘 이모지
  VocabWord(this.ko, this.tx, this.rd, {this.ic});
}

class VocabSection {
  final String title;
  final List<VocabWord> words;
  VocabSection(this.title, this.words);
}

class VocabTheme {
  final String id;
  final String title;
  final String emoji;
  final List<VocabSection> sections;
  VocabTheme(this.id, this.title, this.emoji, this.sections);

  int get wordCount => sections.fold(0, (s, x) => s + x.words.length);
}

class VocabCatalog {
  VocabCatalog._();
  static final VocabCatalog instance = VocabCatalog._();

  final Map<String, List<VocabTheme>> _byAsset = {};

  List<VocabTheme> themesFor(String asset) => _byAsset[asset] ?? const [];

  Future<void> ensureLoaded(String asset) async {
    if (_byAsset.containsKey(asset)) return;
    final raw = await rootBundle.loadString(asset);
    final data = json.decode(raw) as Map<String, dynamic>;
    _byAsset[asset] = [
      for (final t in (data['themes'] as List).whereType<Map>())
        VocabTheme(
          t['id'] as String,
          t['title'] as String,
          t['emoji'] as String? ?? '📚',
          [
            for (final s in (t['sections'] as List).whereType<Map>())
              VocabSection(
                s['title'] as String,
                [
                  for (final w in (s['words'] as List).whereType<Map>())
                    VocabWord(
                      w['ko'] as String? ?? '',
                      w['tx'] as String? ?? '',
                      w['rd'] as String? ?? '',
                      ic: w['ic'] as String?,
                    ),
                ],
              ),
          ],
        ),
    ];
  }
}

/// 주제 목록 화면 — 단어(words)·표현(expressions) 겸용.
class TopicVocabScreen extends StatefulWidget {
  final String title;
  final String asset;

  const TopicVocabScreen({
    super.key,
    this.title = '주제별 단어',
    this.asset = 'assets/data/vocab/travel_words.json',
  });

  @override
  State<TopicVocabScreen> createState() => _TopicVocabScreenState();
}

class _TopicVocabScreenState extends State<TopicVocabScreen> {
  bool _loading = true;
  List<VocabTheme> _themes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await VocabCatalog.instance.ensureLoaded(widget.asset);
    if (!mounted) return;
    setState(() {
      _themes = VocabCatalog.instance.themesFor(widget.asset);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themes = _themes;
    final total = themes.fold(0, (s, t) => s + t.wordCount);
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(
        backgroundColor: AppColors.cal,
        foregroundColor: AppColors.tinta,
        elevation: 0,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr(widget.title),
                style: const TextStyle(
                    color: AppColors.tinta,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(trf('여행 이탈리아어 · {0}항목', [total]),
                style: const TextStyle(
                    color: AppColors.tintaLight,
                    fontSize: 10,
                    letterSpacing: 2)),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.rojo))
          : GridView.builder(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
              ),
              itemCount: themes.length,
              itemBuilder: (context, i) {
                final t = themes[i];
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => _ThemeDetailScreen(
                            theme: t,
                            gridMode:
                                widget.asset.contains('travel_words'))),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cal,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.rojo.withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(t.emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 6),
                        Text(
                          t.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.tinta,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trf('{0}편 · {1}항목', [t.sections.length, t.wordCount]),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.tintaLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// 주제 상세 — 단어는 1×1 아이콘 그리드, 표현은 목록. 외우기 모드 지원.
class _ThemeDetailScreen extends StatefulWidget {
  final VocabTheme theme;
  final bool gridMode;
  const _ThemeDetailScreen({required this.theme, this.gridMode = false});

  @override
  State<_ThemeDetailScreen> createState() => _ThemeDetailScreenState();
}

class _ThemeDetailScreenState extends State<_ThemeDetailScreen> {
  StudyMode _mode = StudyMode.all;

  @override
  void initState() {
    super.initState();
    MemorizedStore.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _cycleMode() {
    setState(() {
      _mode = StudyMode.values[(_mode.index + 1) % StudyMode.values.length];
    });
  }

  String get _modeLabel => switch (_mode) {
        StudyMode.all => tr('전체'),
        StudyMode.hideTx => tr('이탈리아어가림'),
        StudyMode.hideKo => tr('뜻가림'),
      };

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final words = [for (final s in t.sections) ...s.words];
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(
        backgroundColor: AppColors.cal,
        foregroundColor: AppColors.tinta,
        elevation: 0,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${t.emoji} ${t.title}',
                style: const TextStyle(
                    color: AppColors.tinta,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            ValueListenableBuilder<int>(
              valueListenable: MemorizedStore.version,
              builder: (context, _, _) {
                final done =
                    words.where((w) => MemorizedStore.contains(w.tx)).length;
                return Text(
                  trf('{0}항목 · 외움 {1}', [t.wordCount, done]),
                  style: const TextStyle(
                      color: AppColors.tintaLight,
                      fontSize: 10,
                      letterSpacing: 2),
                );
              },
            ),
          ],
        ),
        actions: [
          const KoReadingToggleAction(),
          IconButton(
            tooltip: trf('외우기 모드: {0} (탭하여 전환)', [_modeLabel]),
            onPressed: _cycleMode,
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _mode == StudyMode.all
                      ? AppColors.tintaLight
                      : AppColors.rojo,
                ),
                borderRadius: BorderRadius.circular(6),
                color: _mode == StudyMode.all
                    ? null
                    : AppColors.rojo.withValues(alpha: 0.08),
              ),
              child: Text(
                _modeLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: _mode == StudyMode.all
                      ? AppColors.tintaLight
                      : AppColors.rojo,
                ),
              ),
            ),
          ),
        ],
      ),
      body: !widget.gridMode
          ? ListView.builder(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 24 + bottomInset(context)),
              itemCount: words.length,
              itemBuilder: (context, i) => _WordRow(
                key: ValueKey('${_mode.name}_${words[i].tx}_$i'),
                word: words[i],
                mode: _mode,
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.fromLTRB(14, 10, 14, 24 + bottomInset(context)),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 9,
                crossAxisSpacing: 9,
                childAspectRatio: 0.82,
              ),
              itemCount: words.length,
              itemBuilder: (context, i) => _WordTile(
                key: ValueKey('${_mode.name}_${words[i].tx}_$i'),
                word: words[i],
                fallbackEmoji: t.emoji,
                mode: _mode,
              ),
            ),
    );
  }
}

/// 1×1 단어 타일 — 아이콘 + 이탈리아어 + 독음 + 뜻. 외우기 모드 지원.
class _WordTile extends StatefulWidget {
  final VocabWord word;
  final String fallbackEmoji;
  final StudyMode mode;
  const _WordTile({
    super.key,
    required this.word,
    required this.fallbackEmoji,
    this.mode = StudyMode.all,
  });

  @override
  State<_WordTile> createState() => _WordTileState();
}

class _WordTileState extends State<_WordTile> {
  bool _revealed = false;

  void _openSheet(BuildContext context) {
    final word = widget.word;
    TtsService.instance.speak(word.tx);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cal,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (_) => _WordDetailSheet(
        word: word,
        emoji: word.ic ?? widget.fallbackEmoji,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.word;
    final study = widget.mode != StudyMode.all;
    final hideTx = widget.mode == StudyMode.hideTx && !_revealed;
    final hideKo = widget.mode == StudyMode.hideKo && !_revealed;

    return ValueListenableBuilder<int>(
      valueListenable: MemorizedStore.version,
      builder: (context, _, _) {
        final memorized = MemorizedStore.contains(word.tx);
        return InkWell(
          onTap: () {
            if (study && !_revealed) {
              setState(() => _revealed = true);
              TtsService.instance.speak(word.tx);
            } else {
              _openSheet(context);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: memorized && study
                  ? AppColors.gualda.withValues(alpha: 0.10)
                  : AppColors.cal,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: memorized && study
                    ? AppColors.rojo.withValues(alpha: 0.7)
                    : AppColors.gualda.withValues(alpha: 0.8),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(word.ic ?? widget.fallbackEmoji,
                          style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          hideTx ? '???' : word.tx,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: hideTx
                                ? AppColors.tintaLight
                                : AppColors.tinta,
                          ),
                        ),
                      ),
                      if (word.rd.isNotEmpty && !hideTx)
                        KoReadingText(
                          word.rd,
                          style: const TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: AppColors.gualdaDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (word.ko.isNotEmpty)
                        Text(
                          hideKo ? '???' : word.ko,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: hideKo
                                ? AppColors.tintaLight
                                : AppColors.tinta,
                          ),
                        ),
                    ],
                  ),
                ),
                if (study || memorized)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 30, minHeight: 30),
                      tooltip: memorized ? tr('외움 해제') : tr('외웠어요'),
                      onPressed: () => MemorizedStore.toggle(word.tx),
                      icon: Icon(
                        memorized
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: memorized
                            ? AppColors.rojo
                            : AppColors.tintaLight.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 단어 상세 시트 — 큰 이탈리아어 + 독음 + 뜻 + TTS.
class _WordDetailSheet extends StatelessWidget {
  final VocabWord word;
  final String emoji;
  const _WordDetailSheet({required this.word, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 26 + bottomInset(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            Text(
              word.tx,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.tinta,
                height: 1.3,
              ),
            ),
            if (word.rd.isNotEmpty) ...[
              const SizedBox(height: 6),
              KoReadingText(
                word.rd,
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gualdaDeep,
                ),
              ),
            ],
            if (word.ko.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                word.ko,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tinta,
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.rojo,
                foregroundColor: AppColors.cal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
              ),
              onPressed: () => TtsService.instance.speak(word.tx),
              icon: const Icon(Icons.volume_up),
              label: Text(tr('다시 듣기'),
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 표현 목록 행 — 외우기 모드 지원.
class _WordRow extends StatefulWidget {
  final VocabWord word;
  final StudyMode mode;
  const _WordRow({super.key, required this.word, this.mode = StudyMode.all});

  @override
  State<_WordRow> createState() => _WordRowState();
}

class _WordRowState extends State<_WordRow> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final word = widget.word;
    final study = widget.mode != StudyMode.all;
    final hideTx = widget.mode == StudyMode.hideTx && !_revealed;
    final hideKo = widget.mode == StudyMode.hideKo && !_revealed;

    return ValueListenableBuilder<int>(
      valueListenable: MemorizedStore.version,
      builder: (context, _, _) {
        final memorized = MemorizedStore.contains(word.tx);
        return InkWell(
          onTap: study && !_revealed
              ? () {
                  setState(() => _revealed = true);
                  TtsService.instance.speak(word.tx);
                }
              : null,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            decoration: BoxDecoration(
              color: memorized && study
                  ? AppColors.gualda.withValues(alpha: 0.08)
                  : null,
              border: Border(
                top: BorderSide(
                    color: AppColors.gualda.withValues(alpha: 0.35)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hideTx ? '???' : word.tx,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color:
                              hideTx ? AppColors.tintaLight : AppColors.tinta,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (word.rd.isNotEmpty && !hideTx)
                        KoReadingText(
                          word.rd,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.gualdaDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (word.ko.isNotEmpty)
                        Text(
                          hideKo ? '???' : word.ko,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: hideKo
                                ? AppColors.tintaLight
                                : AppColors.tinta,
                          ),
                        ),
                    ],
                  ),
                ),
                if (study || memorized)
                  IconButton(
                    tooltip: memorized ? tr('외움 해제') : tr('외웠어요'),
                    icon: Icon(
                      memorized
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: memorized
                          ? AppColors.rojo
                          : AppColors.tintaLight.withValues(alpha: 0.6),
                    ),
                    onPressed: () => MemorizedStore.toggle(word.tx),
                  ),
                IconButton(
                  icon: const Icon(Icons.volume_up,
                      size: 20, color: AppColors.rojo),
                  onPressed: () => TtsService.instance.speak(word.tx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
