import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../main.dart';
import '../services/tts_service.dart';
import '../widgets/spanish_decor.dart';

/// 에피소드/다이얼로그 메타 (Learn 탭·회화 허브·홈 공용).
class EpisodeMeta {
  final String level; // 'L1' | 'L2' | 'L3'
  final String id;
  final String title;
  final String emoji;
  const EpisodeMeta(this.level, this.id, this.title, this.emoji);
}

/// 화자 메타 (이름·성별) — TTS 보이스 선택용.
class SpeakerMeta {
  final String name;
  final String gender; // 'male' | 'female'
  const SpeakerMeta(this.name, this.gender);
}

/// L1~L3 JSON에서 에피소드 목록을 1회 로드해 공유.
class EpisodeCatalog {
  EpisodeCatalog._();
  static final EpisodeCatalog instance = EpisodeCatalog._();

  final Map<String, List<EpisodeMeta>> _byLevel = {};
  final Map<String, Map<String, SpeakerMeta>> _speakers = {};
  bool _loaded = false;

  static const List<String> levels = ['L1', 'L2', 'L3'];

  static const Map<String, String> levelLabels = {
    'L1': 'L1 스토리 — 첫 만남',
    'L2': 'L2 일상 챗',
    'L3': 'L3 내러티브',
  };

  List<EpisodeMeta> forLevel(String level) => _byLevel[level] ?? const [];
  List<EpisodeMeta> get all => levels.expand(forLevel).toList(growable: false);

  SpeakerMeta speaker(String level, String key) =>
      _speakers[level]?[key] ??
      SpeakerMeta(key, key == 'A' ? 'male' : 'female');

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    for (final level in levels) {
      try {
        final raw = await rootBundle.loadString('assets/data/dialogues/$level.json');
        final data = json.decode(raw) as Map<String, dynamic>;
        final units = (data['episodes'] as List?) ?? (data['dialogues'] as List?) ?? [];
        _byLevel[level] = [
          for (final e in units.whereType<Map>())
            if ((e['turns'] as List?)?.isNotEmpty ?? false)
              EpisodeMeta(
                level,
                e['id'] as String,
                e['title'] as String? ?? e['id'] as String,
                e['emoji'] as String? ?? '💬',
              ),
        ];
        final chars = (data['characters'] as Map?) ?? {};
        _speakers[level] = {
          for (final entry in chars.entries)
            '${entry.key}': SpeakerMeta(
              (entry.value as Map)['name'] as String? ?? '${entry.key}',
              (entry.value as Map)['gender'] as String? ?? 'female',
            ),
        };
      } catch (_) {
        _byLevel[level] = const [];
      }
    }
    _loaded = true;
  }
}

/// 에피소드 학습 화면 — 채팅 버블 + TTS + 턴별 학습 체크.
class EpisodeScreen extends StatefulWidget {
  final EpisodeMeta meta;
  const EpisodeScreen({super.key, required this.meta});

  @override
  State<EpisodeScreen> createState() => _EpisodeScreenState();
}

class _EpisodeScreenState extends State<EpisodeScreen> {
  List<TurnRow> _turns = const [];
  Set<int> _learned = {};
  bool _showKo = true;
  String? _speakingEs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _load() async {
    final turns = await (appDb.select(appDb.turns)
          ..where((t) => t.level.equals(widget.meta.level) & t.episodeId.equals(widget.meta.id))
          ..orderBy([(t) => OrderingTerm.asc(t.num)]))
        .get();
    final ids = turns.map((t) => t.id).toList();
    final progress = await (appDb.select(appDb.userProgress)
          ..where((p) => p.turnId.isIn(ids)))
        .get();
    if (!mounted) return;
    setState(() {
      _turns = turns;
      _learned = progress.where((p) => p.learned).map((p) => p.turnId).toSet();
    });
  }

  Future<void> _toggleLearned(TurnRow t) async {
    final now = !_learned.contains(t.id);
    await appDb.into(appDb.userProgress).insertOnConflictUpdate(
          UserProgressCompanion(
            turnId: Value(t.id),
            learned: Value(now),
            lastReviewed: Value(DateTime.now()),
          ),
        );
    setState(() {
      if (now) {
        _learned.add(t.id);
      } else {
        _learned.remove(t.id);
      }
    });
  }

  Future<void> _speak(TurnRow t) async {
    final sp = EpisodeCatalog.instance.speaker(t.level, t.speaker);
    setState(() => _speakingEs = t.es);
    await TtsService.instance.speakAs(t.es, gender: sp.gender);
    if (mounted) setState(() => _speakingEs = null);
  }

  @override
  Widget build(BuildContext context) {
    final total = _turns.length;
    final done = _turns.where((t) => _learned.contains(t.id)).length;
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(
        title: Text('${widget.meta.level} · ${widget.meta.title}'),
        actions: [
          IconButton(
            tooltip: '한국어 번역 토글',
            icon: Icon(_showKo ? Icons.translate : Icons.translate_outlined),
            onPressed: () => setState(() => _showKo = !_showKo),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            backgroundColor: AppColors.rojoDeep,
            color: AppColors.gualda,
            minHeight: 4,
          ),
        ),
      ),
      body: _turns.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: _turns.length,
              itemBuilder: (context, i) {
                final t = _turns[i];
                return _EpisodeBubble(
                  turn: t,
                  speaker: EpisodeCatalog.instance.speaker(t.level, t.speaker),
                  showKo: _showKo,
                  learned: _learned.contains(t.id),
                  speaking: _speakingEs == t.es,
                  onSpeak: () => _speak(t),
                  onToggleLearned: () => _toggleLearned(t),
                );
              },
            ),
    );
  }
}

class _EpisodeBubble extends StatelessWidget {
  final TurnRow turn;
  final SpeakerMeta speaker;
  final bool showKo;
  final bool learned;
  final bool speaking;
  final VoidCallback onSpeak;
  final VoidCallback onToggleLearned;

  const _EpisodeBubble({
    required this.turn,
    required this.speaker,
    required this.showKo,
    required this.learned,
    required this.speaking,
    required this.onSpeak,
    required this.onToggleLearned,
  });

  @override
  Widget build(BuildContext context) {
    final isA = turn.speaker == 'A';
    final color = isA ? AppColors.mar : AppColors.rojo;
    final tags = turn.tagsJson == null
        ? const <String>[]
        : (json.decode(turn.tagsJson!) as List).map((e) => '$e').toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isA ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isA) ...[
            TileBadge(text: speaker.name.substring(0, 1), size: 32, color: color),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onTap: onSpeak,
              onLongPress: onToggleLearned,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                decoration: BoxDecoration(
                  color: learned ? AppColors.calDeep : Colors.white,
                  border: Border.all(
                    color: speaking ? AppColors.gualda : color.withValues(alpha: 0.4),
                    width: speaking ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isA ? 2 : 14),
                    bottomRight: Radius.circular(isA ? 14 : 2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${turn.num}. ${speaker.name}',
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          speaking ? Icons.volume_up : Icons.volume_up_outlined,
                          size: 14,
                          color: speaking ? AppColors.gualdaDeep : AppColors.tintaLight,
                        ),
                        if (learned) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check_circle, size: 14, color: AppColors.oliva),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      turn.es,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tinta,
                        height: 1.35,
                      ),
                    ),
                    if (showKo && turn.ko != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        turn.ko!,
                        style: const TextStyle(fontSize: 13, color: AppColors.tintaLight),
                      ),
                    ],
                    if (turn.note != null && turn.note!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.gualda.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '✎ ${turn.note}',
                          style: const TextStyle(fontSize: 11, color: AppColors.tinta),
                        ),
                      ),
                    ],
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          for (final tag in tags)
                            Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 10,
                                color: color.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (!isA) ...[
            const SizedBox(width: 8),
            TileBadge(text: speaker.name.substring(0, 1), size: 32, color: color),
          ],
        ],
      ),
    );
  }
}
